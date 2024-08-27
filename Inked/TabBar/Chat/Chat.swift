import SwiftUI
import Firebase

struct User: Identifiable {
    var id: String
    var firstName: String
    var lastName: String
    var email: String
    var profileImage: String?
}

struct UserRow: View {
    var user: User
    
    var body: some View {
        HStack {
            if let profileImageName = user.profileImage, profileImageName != "none" {
                Image(profileImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct Chat: View {
    @State private var users: [User] = []

    var body: some View {
        NavigationView {
            List(users) { user in
                NavigationLink(destination: ChatView(receiver: user)) {
                    UserRow(user: user)
                }
            }
            .navigationBarTitle("Чаты")
            .onAppear(perform: fetchUsers)
        }
    }
    
    func fetchUsers() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting users: \(error)")
            } else {
                users = querySnapshot?.documents.compactMap { document in
                    let data = document.data()
                    
                    guard let email = data["email"] as? String else {
                        return nil
                    }
                    
                    let firstName = data["firstName"] as? String ?? ""
                    let lastName = data["lastName"] as? String ?? ""
                    let profileImage = data["profileImage"] as? String
                    
                    return User(id: document.documentID, firstName: firstName, lastName: lastName, email: email, profileImage: profileImage)
                } ?? []
            }
        }
    }
}
