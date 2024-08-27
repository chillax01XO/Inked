import Foundation
import FirebaseFirestoreSwift
import FirebaseAuth

struct Message: Codable, Identifiable {
    @DocumentID var id: String?
    var text: String
    var senderId: String
    var timestamp: Date

    var isCurrentUser: Bool {
        return senderId == Auth.auth().currentUser?.uid
    }
}
