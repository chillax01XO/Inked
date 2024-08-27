import SwiftUI
import LocalAuthentication

struct PasswordSecurityView: View {
    @State private var isPasswordSet: Bool = UserDefaults.standard.bool(forKey: "isPasswordSet")
    @State private var showSetPasswordView = false
    @State private var showChangePasswordView = false
    @State private var pendingPasswordSet: Bool = false
    @AppStorage("lockTime") private var lockTime = "Всегда"
    let lockTimes = ["Всегда", "Через минуту", "Через 2 минуты", "Через 5 минут", "Через 15 минут"]
    @EnvironmentObject var appState: AppState // добавьте это

    var body: some View {
        VStack {
            Toggle("Включить пароль", isOn: $isPasswordSet)
                .onChange(of: isPasswordSet) { value in
                    if value {
                        pendingPasswordSet = true
                        showSetPasswordView = true
                    } else {
                        UserDefaults.standard.removeObject(forKey: "appPassword")
                        UserDefaults.standard.set(false, forKey: "isPasswordSet")
                        appState.isLocked = false // добавьте это
                    }
                }
                .padding()
            
            if isPasswordSet {
                HStack(alignment: .center) {
                    Text("Время блокировки")
                    
                    Spacer()
                    
                    Picker(selection: $lockTime, label: Text(lockTime)) {
                        ForEach(lockTimes, id: \.self) { time in
                            HStack {
                                Text(time)
                                Spacer()
                                if time == lockTime {
                                    // This spacer and checkmark alignment can be added if needed for visual indication
                                }
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding()
                
                Button(action: {
                    showChangePasswordView = true
                }) {
                    Text("Изменить пароль")
                        .foregroundColor(.blue)
                }
                .padding()
            }
        }
        .navigationBarTitle("Пароль и безопасность", displayMode: .inline)
        .sheet(isPresented: $showSetPasswordView, onDismiss: {
            if pendingPasswordSet && !UserDefaults.standard.bool(forKey: "isPasswordSet") {
                isPasswordSet = false
            }
        }) {
            SetPasswordView {
                pendingPasswordSet = false
            }
        }
        .sheet(isPresented: $showChangePasswordView) {
            ChangePasswordView()
        }
    }
}
