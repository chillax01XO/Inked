import SwiftUI
import Security

struct PasswordSettingsView: View {
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        VStack {
            SecureField("Текущий пароль", text: $currentPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.bottom, 20)

            SecureField("Новый пароль", text: $newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.bottom, 20)

            SecureField("Подтвердите новый пароль", text: $confirmPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.bottom, 20)

            Button(action: {
                changePassword()
            }) {
                Text("Изменить пароль")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func changePassword() {
        guard !newPassword.isEmpty, newPassword == confirmPassword else {
            alertMessage = "Пароли не совпадают"
            showAlert = true
            return
        }

        if let currentStoredPassword = KeychainHelper.shared.retrievePassword() {
            if currentPassword == currentStoredPassword {
                KeychainHelper.shared.savePassword(newPassword)
                alertMessage = "Пароль успешно изменен"
            } else {
                alertMessage = "Текущий пароль неверен"
            }
        } else {
            KeychainHelper.shared.savePassword(newPassword)
            alertMessage = "Пароль успешно установлен"
        }
        showAlert = true
    }
}
