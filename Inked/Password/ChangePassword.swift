import SwiftUI
import LocalAuthentication

struct ChangePasswordView: View {
    @State private var oldPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    @State private var showPasswordMismatchAlert: Bool = false
    @State private var passwordChangedSuccessfully: Bool = false
    @State private var showSuccessMessage: Bool = false
    @State private var showInvalidPasswordAlert: Bool = false
    @State private var showOldPasswordIncorrectAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Старый пароль")
                            .font(.headline)

                        SecureField("Введите старый пароль", text: $oldPassword)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        Text("Новый пароль")
                            .font(.headline)

                        SecureField("Введите новый пароль", text: $newPassword)
                            .keyboardType(.numberPad)
                            .onReceive(newPassword.publisher.collect()) {
                                self.newPassword = String($0.prefix(6))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        Text("Подтверждение нового пароля")
                            .font(.headline)

                        SecureField("Подтвердите новый пароль", text: $confirmNewPassword)
                            .keyboardType(.numberPad)
                            .onReceive(confirmNewPassword.publisher.collect()) {
                                self.confirmNewPassword = String($0.prefix(6))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding()

                    Button(action: {
                        let savedPassword = UserDefaults.standard.string(forKey: "appPassword") ?? ""
                        if oldPassword != savedPassword {
                            showOldPasswordIncorrectAlert = true
                        } else if newPassword.count < 4 || newPassword.count > 6 {
                            showInvalidPasswordAlert = true
                        } else if newPassword == confirmNewPassword && !newPassword.isEmpty {
                            UserDefaults.standard.set(newPassword, forKey: "appPassword")
                            withAnimation {
                                passwordChangedSuccessfully = true
                                showSuccessMessage = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            showPasswordMismatchAlert = true
                        }
                    }) {
                        Text("Изменить пароль")
                            .foregroundColor(.white)
                            .frame(width: UIScreen.main.bounds.width - 120)
                            .padding()
                            .background(Color.black)
                            .clipShape(Capsule())
                            .padding(.top, 45)
                    }
                    .padding()
                    .alert(isPresented: $showPasswordMismatchAlert) {
                        Alert(title: Text("Ошибка"), message: Text("Пароли не совпадают"), dismissButton: .default(Text("ОК")))
                    }
                    .alert(isPresented: $showInvalidPasswordAlert) {
                        Alert(title: Text("Ошибка"), message: Text("Пароль должен содержать от 4 до 6 цифр"), dismissButton: .default(Text("ОК")))
                    }
                    .alert(isPresented: $showOldPasswordIncorrectAlert) {
                        Alert(title: Text("Ошибка"), message: Text("Неверный старый пароль"), dismissButton: .default(Text("ОК")))
                    }
                }
                .navigationBarTitle("Смена пароля", displayMode: .inline)
            }

            // Уведомление об успешной смене пароля
            if showSuccessMessage {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.black)
                            Text("Пароль изменён!")
                                .foregroundColor(.black)
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        Spacer()
                    }
                    Spacer()
                }
                .transition(.scale)
                .animation(.easeInOut(duration: 1.0))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            showSuccessMessage = false
                        }
                    }
                }
            }
        }
    }
}
