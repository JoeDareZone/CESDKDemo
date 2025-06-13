import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var photoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("📔 My Journal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                PhotosPicker("Add New Memory", selection: $photoItem, matching: .images)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .onChange(of: photoItem) { newValue in
                        // TODO: Handle image selection
                        print("Image selected: \(newValue)")
                    }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
