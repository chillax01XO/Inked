import SwiftUI
import Firebase

struct AddUserInfoView: View {
    var email: String
    @Binding var show: Bool
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showProfileImageSelection = false
    
    var body: some View {
        VStack {
            if showProfileImageSelection {
                ProfileImageSelectionView(email: email, show: $show)
            } else {
                Text("Дополнительные сведения").fontWeight(.heavy).font(.largeTitle).padding([.top, .bottom], 20)
                
                TextField("Имя", text: $firstName).padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                TextField("Фамилия", text: $lastName).padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                Button(action: saveUserInformation) {
                    Text("Сохранить").foregroundColor(.white).frame(width: UIScreen.main.bounds.width - 120).padding()
                }
                .background(Color.black)
                .clipShape(Capsule())
                .padding(.top, 45)
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("Ок")))
        }
    }
    
    private func saveUserInformation() {
        let db = Firestore.firestore()
        db.collection("users").document(email).setData(["firstName": firstName, "lastName": lastName, "email": email]) { error in
            if let error = error {
                self.alertMessage = "Произошла ошибка: \(error.localizedDescription)"
                self.showAlert = true
            } else {
                self.showProfileImageSelection = true
            }
        }
    }
}
