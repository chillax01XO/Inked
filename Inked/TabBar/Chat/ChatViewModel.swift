import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import Firebase
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []

    private var db = Firestore.firestore()
    private var messagesListener: ListenerRegistration?

    func fetchMessages() {
        messagesListener?.remove()
        messagesListener = db.collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("No documents")
                    return
                }

                self.messages = documents.compactMap { doc -> Message? in
                    try? doc.data(as: Message.self)
                }
            }
    }

    func sendMessage(text: String) {
        guard let user = Auth.auth().currentUser else { return }
        let message = Message(id: UUID().uuidString, text: text, senderId: user.uid, timestamp: Date())
        do {
            try db.collection("messages").document(message.id!).setData(from: message)
        } catch {
            print("Error writing message to Firestore: \(error)")
        }
    }

    func deleteMessage(messageId: String) {
        db.collection("messages").document(messageId).delete { error in
            if let error = error {
                print("Error deleting message: \(error)")
            }
        }
    }
}
