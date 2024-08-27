import SwiftUI
import Firebase

struct ProfileImageSelectionView: View {
    var email: String
    @Binding var show: Bool
    @State private var selectedImage: String? = nil
    
    let images = (1...10).map { "Image \($0)" }
    
    var body: some View {
        VStack {
            Text("Выберите изображение профиля").fontWeight(.heavy).font(.largeTitle).padding([.top, .bottom], 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(images, id: \.self) { imageName in
                        Image(imageName)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding(5)
                            .onTapGesture {
                                selectedImage = imageName
                            }
                            .overlay(
                                Circle().stroke(selectedImage == imageName ? Color.blue : Color.clear, lineWidth: 4)
                            )
                    }
                }
            }
            
            Button(action: saveProfileImage) {
                Text("Сохранить изображение").foregroundColor(.white).frame(width: UIScreen.main.bounds.width - 120).padding()
            }
            .background(Color.black)
            .clipShape(Capsule())
            .padding(.top, 45)
            
            Button(action: skipProfileImage) {
                Text("Пропустить").foregroundColor(.black).frame(width: UIScreen.main.bounds.width - 120).padding()
            }
            .background(Color.gray)
            .clipShape(Capsule())
            .padding(.top, 15)
        }
        .padding()
    }
    
    private func saveProfileImage() {
        let imageNameToSave = selectedImage ?? "none" // Если иконка не выбрана, записываем "none"
        let db = Firestore.firestore()
        db.collection("users").document(email).updateData(["profileImage": imageNameToSave]) { error in
            if let error = error {
                print("Error saving profile image: \(error.localizedDescription)")
            } else {
                self.show = false
                UserDefaults.standard.set(true, forKey: "status")
                NotificationCenter.default.post(name: NSNotification.Name("statusChange"), object: nil)
            }
        }
    }
    
    private func skipProfileImage() {
        let db = Firestore.firestore()
        db.collection("users").document(email).updateData(["profileImage": "none"]) { error in
            if let error = error {
                print("Error skipping profile image: \(error.localizedDescription)")
            } else {
                self.show = false
                UserDefaults.standard.set(true, forKey: "status")
                NotificationCenter.default.post(name: NSNotification.Name("statusChange"), object: nil)
            }
        }
    }
}
