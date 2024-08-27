import SwiftUI
import LocalAuthentication

struct Face: View {
    @State private var isUnlocked = false

    var body: some View {
        if isUnlocked {
            TabBar()
        } else {
            VStack {
                Spacer()
                Button(action: {
                    authenticateWithFaceID()
                }) {
                    Text("Разблокировать")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black)
                        .clipShape(Capsule())
                        
                }
                Spacer()
            }
        }
    }

    func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Пожалуйста, подтвердите вашу личность"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        isUnlocked = true
                    } else {
                        // Обработка ошибки аутентификации
                    }
                }
            }
        } else {
            // Устройство не поддерживает Face ID
        }
    }
}





