import SwiftUI
import PhotosUI
import IMGLYPhotoEditor
import IMGLYEngine

struct JournalEntry: Codable, Identifiable {
    let id = UUID()
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
                    .onChange(of: photoItem) { newValue in
                        Task {
                            await handleImageSelection(newValue)
                        }
                    }
                
                if !journalEntries.isEmpty {
                    Text("Saved memories: \(journalEntries.count)")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showEditor) {
                NavigationView {
                    PhotoEditor(engineSettings)
                        .imgly.onCreate { engine in
                            currentEngine = engine
                            
                            if let url = tempURL {
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
    
    private func saveJournalEntry(engine: Engine) async {
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let entryID = UUID().uuidString
            
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
            
            let newEntry = JournalEntry(
                imagePath: imagePath,
                scenePath: scenePath,
                createdAt: Date(),
                title: "Memory from \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none))"
            )
            
            await MainActor.run {
                journalEntries.append(newEntry)
                saveJournalEntries()
            }
            
            print("Journal entry saved successfully!")
            
        } catch {
            print("Failed to save journal entry: \(error)")
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
                    showEditor = true
                }
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
