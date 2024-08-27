import SwiftUI
import LocalAuthentication

struct SetPasswordView: View {
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPasswordMismatchAlert: Bool = false
    @State private var passwordSetSuccessfully: Bool = false
    @State private var showSuccessMessage: Bool = false
    @State private var showInvalidPasswordAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode
    var onPasswordSet: () -> Void

    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Новый пароль")
                            .font(.headline)

                        SecureField("Введите пароль", text: $password)
                            .keyboardType(.numberPad)
                            .onReceive(password.publisher.collect()) {
                                self.password = String($0.prefix(6))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        Text("Подтверждение пароля")
                            .font(.headline)

                        SecureField("Подтвердите пароль", text: $confirmPassword)
                            .keyboardType(.numberPad)
                            .onReceive(confirmPassword.publisher.collect()) {
                                self.confirmPassword = String($0.prefix(6))
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .padding()

                    Button(action: {
                        if password.count < 4 || password.count > 6 {
                            showInvalidPasswordAlert = true
                        } else if password == confirmPassword && !password.isEmpty {
                            UserDefaults.standard.set(password, forKey: "appPassword")
                            UserDefaults.standard.set(true, forKey: "isPasswordSet")
                            withAnimation {
                                passwordSetSuccessfully = true
                                showSuccessMessage = true
                                onPasswordSet()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        } else {
                            showPasswordMismatchAlert = true
                        }
                    }) {
                        Text("Установить пароль")
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
                }
                .navigationBarTitle("Установка пароля", displayMode: .inline)
            }

            // Уведомление об успешной установке пароля
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
                            Text("Пароль установлен!")
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
