import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ChatView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var messageText = ""
    var receiver: User // Add this line to accept a User

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(chatViewModel.messages) { message in
                            MessageView(message: message)
                                .id(message.id!)
                        }
                    }
                    .onChange(of: chatViewModel.messages.count) { _ in
                        if let lastMessage = chatViewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id!, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            HStack {
                TextField("Введите сообщение", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: CGFloat(30))
                
                Button(action: {
                    chatViewModel.sendMessage(text: messageText)
                    messageText = ""
                }) {
                    Text("Отправить")
                }
            }
            .padding()
        }
        .onAppear {
            chatViewModel.fetchMessages()
        }
    }
}


struct MessageView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isCurrentUser {
                Spacer()
                VStack(alignment: .trailing) {
                    Text(message.text)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    Text(message.timestamp, style: .time)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading) {
                    Text(message.text)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(8)
                        .foregroundColor(.black)
                    Text(message.timestamp, style: .time)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
        .padding([.horizontal, .top])
    }
}
