import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class ProfileViewModel: ObservableObject {
    @Published var profileImage: String = "none"
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    
    func fetchUserData() {
        guard let user = Auth.auth().currentUser else {
            print("No user is signed in.")
            return
        }

        let email = user.email ?? ""
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(email)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                self.firstName = data?["firstName"] as? String ?? ""
                self.lastName = data?["lastName"] as? String ?? ""
                self.profileImage = data?["profileImage"] as? String ?? "none"
            } else {
                print("Document does not exist")
            }
        }
    }

    func deleteProfileImage() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        let email = user.email ?? ""
        let db = Firestore.firestore()
        db.collection("users").document(email).updateData(["profileImage": "none"]) { error in
            if let error = error {
                print("Error deleting profile image: \(error.localizedDescription)")
            } else {
                self.profileImage = "none"
            }
        }
    }
}
