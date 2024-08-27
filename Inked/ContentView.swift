import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth
import LocalAuthentication

class AppState: ObservableObject {
    @Published var status: Bool = UserDefaults.standard.value(forKey: "status") as? Bool ?? false
    @Published var isLocked: Bool = UserDefaults.standard.bool(forKey: "isPasswordSet")
    @Published var backgroundTime: Date?
    @Published var isBlurred: Bool = false
}

struct ContentView: View {
    @StateObject private var appState = AppState()
    @AppStorage("lockTime") private var lockTime = "Всегда"

    var body: some View {
        VStack {
            if appState.status {
                if appState.isLocked {
                    UnlockView(isLocked: $appState.isLocked)
                } else {
                    TabBar()
                }
            } else {
                SignIn()
            }
        }
        .animation(.spring())
        .overlay(
            BlurView(style: .systemMaterial)
                .opacity(appState.isBlurred ? 1 : 0)
                .animation(.easeInOut, value: appState.isBlurred)
        )
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("statusChange"), object: nil, queue: .main) { (_) in
                appState.status = UserDefaults.standard.value(forKey: "status") as? Bool ?? false
            }
            NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
                appState.backgroundTime = Date()
                appState.isBlurred = true
            }
            NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
                if let backgroundTime = appState.backgroundTime {
                    let elapsed = Date().timeIntervalSince(backgroundTime)
                    if shouldLock(elapsedTime: elapsed) {
                        appState.isLocked = UserDefaults.standard.bool(forKey: "isPasswordSet") // добавьте это
                    }
                }
                appState.isBlurred = false
            }
        }
    }

    private func shouldLock(elapsedTime: TimeInterval) -> Bool {
        switch lockTime {
        case "Всегда":
            return true
        case "Через минуту":
            return elapsedTime > 60
        case "Через 2 минуты":
            return elapsedTime > 120
        case "Через 5 минут":
            return elapsedTime > 300
        case "Через 15 минут":
            return elapsedTime > 900
        default:
            return false
        }
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        return blurView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct UnlockView: View {
    @Binding var isLocked: Bool
    @State private var password: String = ""
    @State private var wrongPassword: Bool = false
    @State private var failedBiometricAttempts = 0
    @State private var showPasswordPrompt = false

    var body: some View {
        VStack {
            if showPasswordPrompt || failedBiometricAttempts >= 3 {
                SecureField("Введите пароль", text: $password)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.bottom, 20)
                
                Button(action: {
                    if checkPassword(password) {
                        isLocked = false
                    } else {
                        wrongPassword = true
                    }
                }) {
                    Text("Разблокировать")
                        .foregroundColor(.white)
                        .frame(width: UIScreen.main.bounds.width - 120)
                        .padding()
                        .background(Color.black)
                        .clipShape(Capsule())
                        
                }
                .alert(isPresented: $wrongPassword) {
                    Alert(title: Text("Ошибка"), message: Text("Неверный пароль"), dismissButton: .default(Text("ОК")))
                }
                
                Button(action: {
                    failedBiometricAttempts = 0
                    showPasswordPrompt = false
                    authenticate()
                }) {
                    HStack {
                        Image(systemName: "faceid")
                        Text("Использовать FaceID")
                    }
                    .foregroundColor(.blue)
                }
                .padding(.top, 10)
            } else {
                Text("Идет попытка аутентификации...")
                    .onAppear(perform: authenticate)
            }
        }
        .padding()
    }
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        let reason = "Идентифицируйте себя, чтобы разблокировать приложение."

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        isLocked = false
                    } else {
                        failedBiometricAttempts += 1
                        
                        if authenticationError != nil && (authenticationError! as NSError).code == LAError.userCancel.rawValue {
                            showPasswordPrompt = true
                        } else if failedBiometricAttempts < 3 {
                            authenticate()
                        } else {
                            showPasswordPrompt = true
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                showPasswordPrompt = true
            }
        }
    }
}

func checkPassword(_ inputPassword: String) -> Bool {
    let savedPassword = UserDefaults.standard.string(forKey: "appPassword") ?? ""
    return inputPassword == savedPassword
}
