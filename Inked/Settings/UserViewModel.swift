import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class UserViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var profileImage: String = "none"
    
    private var email: String = ""
    
    init() {
        fetchUserData()
    }
    
    func fetchUserData() {
        guard let user = Auth.auth().currentUser else {
            print("No user is signed in.")
            return
        }

        self.email = user.email ?? ""
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(self.email)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                self.firstName = data?["firstName"] as? String ?? ""
                self.lastName = data?["lastName"] as? String ?? ""
                self.userName = "\(self.firstName) \(self.lastName)"
                self.profileImage = data?["profileImage"] as? String ?? "none" // Load profile image
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func updateProfileImage(_ imageName: String) {
        let db = Firestore.firestore()
        db.collection("users").document(email).updateData(["profileImage": imageName]) { error in
            if let error = error {
                print("Error saving profile image: \(error.localizedDescription)")
            } else {
                self.profileImage = imageName
            }
        }
    }
    
    func deleteProfileImage() {
        updateProfileImage("none")
    }
}
