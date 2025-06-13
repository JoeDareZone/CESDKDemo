import SwiftUI
import PhotosUI
import IMGLYPhotoEditor
import IMGLYEngine

struct JournalEntry: Codable, Identifiable {
    var id = UUID()
    let imagePath: String
    let scenePath: String
    let createdAt: Date
    let title: String
}

struct ContentView: View {
    @State private var photoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showEditor = false
    @State private var tempURL: URL?
    @State private var currentEngine: Engine?
    @State private var journalEntries: [JournalEntry] = []
    @State private var sceneToLoad: URL?
    @State private var currentEntry: JournalEntry?
    
    let engineSettings = EngineSettings(
        license: "BpLnq7K-IELfyH7VwXuepx6z7I7Z1ByVXWvOymVZ12Mfb2dOAGQQI7hbCnfQ4d4s",
        userID: "joewhocodes@gmail.com"
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("📔 My Journal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                }
                
                PhotosPicker("Add New Memory", selection: $photoItem, matching: .images)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .onChange(of: photoItem) {
                        Task {
                            await handleImageSelection(photoItem)
                        }
                    }
                
                Text("Your Memories")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                if journalEntries.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No memories yet")
                            .foregroundColor(.secondary)
                        Text("Tap 'Add New Memory' to get started!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            ForEach(journalEntries) { entry in
                                JournalEntryView(entry: entry) {
                                    openEntryForEditing(entry)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showEditor) {
                NavigationView {
                    PhotoEditor(engineSettings)
                        .imgly.onCreate { engine in
                            currentEngine = engine
                            
                            if let sceneURL = sceneToLoad {
                                let sceneString = try String(contentsOf: sceneURL, encoding: .utf8)
                                try await engine.scene.load(from: sceneString)
                                
                                try await engine.addDefaultAssetSources(baseURL: Engine.assetBaseURL)
                                try await engine.addDemoAssetSources(
                                    sceneMode: engine.scene.getMode(),
                                    withUploadAssetSources: true
                                )
                                try await engine.asset.addSource(TextAssetSource(engine: engine))
                                
                            } else if let url = tempURL {
                                try await engine.scene.create(fromImage: url)
                                
                                let page = try engine.scene.getPages().first!
                                try engine.block.setWidth(page, value: 1080)
                                try engine.block.setHeight(page, value: 1080)
                                
                                let image = try engine.block.find(byType: .graphic).first!
                                try engine.block.setFill(page, fill: engine.block.getFill(image))
                                try engine.block.destroy(image)
                                
                                try await engine.addDefaultAssetSources(baseURL: Engine.assetBaseURL)
                                try await engine.addDemoAssetSources(
                                    sceneMode: engine.scene.getMode(),
                                    withUploadAssetSources: true
                                )
                                try await engine.asset.addSource(TextAssetSource(engine: engine))
                            }
                        }
                        .imgly.onExport { engine, _ in
                            Task {
                                await saveJournalEntry(engine: engine)
                                showEditor = false
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Save to Journal") {
                                    Task {
                                        await saveJournalEntry(engine: currentEngine!)
                                        showEditor = false
                                    }
                                }
                            }
                        }
                }
            }
            .onAppear {
                loadJournalEntries()
            }
        }
    }
    
    private func openEntryForEditing(_ entry: JournalEntry) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sceneURL = documentsURL.appendingPathComponent(entry.scenePath)
        
        sceneToLoad = sceneURL
        currentEntry = entry
        tempURL = nil
        showEditor = true
    }
    
    private func saveJournalEntry(engine: Engine) async {
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let entryID = currentEntry?.id.uuidString ?? UUID().uuidString
            
            let scene = try engine.scene.get()!
            let imageData = try await engine.block.export(scene, mimeType: .jpeg)
            let imagePath = "journal_\(entryID).jpg"
            let imageURL = documentsURL.appendingPathComponent(imagePath)
            try imageData.write(to: imageURL)
            
            let sceneString = try await engine.scene.saveToString()
            let sceneData = sceneString.data(using: .utf8)!
            let scenePath = "scene_\(entryID).scene"
            let sceneURL = documentsURL.appendingPathComponent(scenePath)
            try sceneData.write(to: sceneURL)
            
            await MainActor.run {
                if let existingEntry = currentEntry {
                    if let index = journalEntries.firstIndex(where: { $0.id == existingEntry.id }) {
                        journalEntries[index] = JournalEntry(
                            imagePath: imagePath,
                            scenePath: scenePath,
                            createdAt: existingEntry.createdAt,
                            title: existingEntry.title
                        )
                    }
                } else {
                    let newEntry = JournalEntry(
                        imagePath: imagePath,
                        scenePath: scenePath,
                        createdAt: Date(),
                        title: "Memory from \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none))"
                    )
                    journalEntries.append(newEntry)
                }
                
                saveJournalEntries()
                sceneToLoad = nil
                currentEntry = nil
            }
            
            print("✅ Journal entry saved successfully!")
            
        } catch {
            print("❌ Failed to save journal entry: \(error)")
        }
    }
    
    private func loadJournalEntries() {
        if let data = UserDefaults.standard.data(forKey: "JournalEntries"),
           let entries = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            journalEntries = entries.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    private func saveJournalEntries() {
        if let data = try? JSONEncoder().encode(journalEntries) {
            UserDefaults.standard.set(data, forKey: "JournalEntries")
        }
    }
    
    private func handleImageSelection(_ photoItem: PhotosPickerItem?) async {
        guard let photoItem else { return }
        
        do {
            if let data = try await photoItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("jpg")
                try data.write(to: url, options: .atomic)
                
                await MainActor.run {
                    tempURL = url
                    selectedImage = uiImage
                    sceneToLoad = nil
                    currentEntry = nil
                    showEditor = true
                }
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}

struct JournalEntryView: View {
    let entry: JournalEntry
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: documentsURL.appendingPathComponent(entry.imagePath)) { image in
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        ProgressView()
                    )
            }
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(entry.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

#Preview {
    ContentView()
}
