import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// Extension to store and retrieve the user's name from UserDefaults
extension UserDefaults {
    func setUserName(_ userName: String, forUID uid: String) {
        set(userName, forKey: "userName_\(uid)")
    }
    func userName(forUID uid: String) -> String? {
        return string(forKey: "userName_\(uid)")
    }
}

struct Settings: View {
    @AppStorage("selectedTheme") private var selectedTheme = "Светлая"
    let themes = ["Светлая", "Темная", "Системная"]
    @State private var userName: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var profileImage: String = "none"
    @State private var showPasswordSecurityView = false
    @State private var showImageOptions = false
    @State private var showImageSelection = false
    @State private var showNameChangeModal = false // State to track the name change modal

    var body: some View {
        NavigationView {
            VStack {
                // Display profile image or placeholder icon
                if profileImage == "none" {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .padding(.top, 20)
                        .onTapGesture {
                            showImageOptions = true
                        }
                } else {
                    Image(profileImage)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .padding(.top, 20)
                        .onTapGesture {
                            showImageOptions = true
                        }
                }

                Text("\(firstName) \(lastName)")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .onTapGesture {
                        showNameChangeModal = true // Show the modal when the name is tapped
                    }

                Text(Auth.auth().currentUser?.email ?? "")
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)

                Spacer()

                Picker("Выбор темы", selection: $selectedTheme) {
                    ForEach(themes, id: \.self) { theme in
                        Text(theme)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedTheme) { _ in
                    updateTheme()
                }

                NavigationLink(destination: PasswordSecurityView()) {
                    
                    Image(systemName: "lock")
                    Text("Пароль и безопасность")
                        .foregroundColor(.blue)
                }
                .padding()

                Button(action: {
                    // Remove password and flag from UserDefaults
                    UserDefaults.standard.removeObject(forKey: "appPassword")
                    UserDefaults.standard.set(false, forKey: "isPasswordSet")

                    // Sign out user
                    UserDefaults.standard.set(false, forKey: "status")
                    NotificationCenter.default.post(name: NSNotification.Name("statusChange"), object: nil)
                }) {
                    Text("Выйти из аккаунта")
                        .foregroundColor(.red)
                }
                .padding()
            }
            .onAppear {
                updateTheme()
                fetchUserData()
            }
            .sheet(isPresented: $showImageSelection) {
                ProfileImageSelectionView(email: Auth.auth().currentUser?.email ?? "", show: $showImageSelection)
            }
            .sheet(isPresented: $showNameChangeModal) {
                NameChangeView(firstName: $firstName, lastName: $lastName, show: $showNameChangeModal) {
                    fetchUserData() // Refresh data after name change
                }
            }
            .actionSheet(isPresented: $showImageOptions) {
                ActionSheet(
                    title: Text("Изменить изображение профиля"),
                    buttons: [
                        .default(Text("Изменить изображение")) {
                            showImageSelection = true
                        },
                        .destructive(Text("Удалить изображение")) {
                            deleteProfileImage()
                        },
                        .cancel()
                    ]
                )
            }
        }
    }

    private func updateTheme() {
        switch selectedTheme {
        case "Светлая":
            UIApplication.shared.windows.first?.rootViewController?.overrideUserInterfaceStyle = .light
        case "Темная":
            UIApplication.shared.windows.first?.rootViewController?.overrideUserInterfaceStyle = .dark
        default:
            UIApplication.shared.windows.first?.rootViewController?.overrideUserInterfaceStyle = .unspecified
        }
    }

    private func fetchUserData() {
        guard let user = Auth.auth().currentUser else {
            print("No user is signed in.")
            return
        }

        let email = user.email ?? ""
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(email)

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                self.firstName = data?["firstName"] as? String ?? ""
                self.lastName = data?["lastName"] as? String ?? ""
                self.userName = "\(self.firstName) \(self.lastName)"
                self.profileImage = data?["profileImage"] as? String ?? "none" // Load profile image
            } else {
                print("Document does not exist")
            }
        }
    }

    private func deleteProfileImage() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        let email = user.email ?? ""
        let db = Firestore.firestore()
        db.collection("users").document(email).updateData(["profileImage": "none"]) { error in
            if let error = error {
                print("Error deleting profile image: \(error.localizedDescription)")
            } else {
                self.profileImage = "none"
            }
        }
    }
}

struct NameChangeView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var show: Bool
    var onSave: () -> Void // Callback to refresh data after name change

    @State private var newFirstName: String = ""
    @State private var newLastName: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            Text("Изменить данные")
                .fontWeight(.heavy)
                .font(.largeTitle)
                .padding([.top, .bottom], 20)
            
            TextField("Имя", text: $newFirstName)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            TextField("Фамилия", text: $newLastName)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            Button(action: saveNameChanges) {
                Text("Сохранить")
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 120)
                    .padding()
            }
            .background(Color.black)
            .clipShape(Capsule())
            .padding(.top, 45)
            
            Spacer()
        }
        .padding()
        .onAppear {
            newFirstName = firstName
            newLastName = lastName
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("Ок")))
        }
    }

    private func saveNameChanges() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "Пользователь не авторизован."
            showAlert = true
            return
        }
        let email = user.email ?? ""
        let db = Firestore.firestore()
        db.collection("users").document(email).updateData([
            "firstName": newFirstName,
            "lastName": newLastName
        ]) { error in
            if let error = error {
                alertMessage = "Произошла ошибка: \(error.localizedDescription)"
                showAlert = true
            } else {
                firstName = newFirstName
                lastName = newLastName
                show = false
                onSave()
            }
        }
    }
}
