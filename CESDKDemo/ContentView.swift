import SwiftUI
import PhotosUI
import IMGLYPhotoEditor
import IMGLYEngine

struct ContentView: View {
    @State private var photoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showEditor = false
    @State private var tempURL: URL?
    
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
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showEditor) {
                PhotoEditor(engineSettings)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showEditor = false
                            }
                        }
                    }
            }
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
