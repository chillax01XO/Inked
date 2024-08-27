import SwiftUI
import Firebase

struct Client: Identifiable {
    var id = UUID().uuidString
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var date: Date
    var userId: String
}

struct ClientView: View {
    @State private var clients: [Client] = []
    @State private var selectedDate = Date()

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Дата", selection: $selectedDate, displayedComponents: [.date])
                    .padding()

                List {
                    ForEach(sortedClientsForSelectedDate) { client in
                        NavigationLink(destination: EditClientView(client: client, clients: self.$clients)) {
                            VStack(alignment: .leading) {
                                Text("Имя: \(client.firstName)")
                                Text("Фамилия: \(client.lastName)")
                                Text("Номер телефона: \(client.phoneNumber)")
                                Text("Дата: \(client.date, formatter: dateFormatter)")
                            }
                        }
                    }
                    .onDelete(perform: deleteClient)
                }
            }
            .navigationBarTitle("Клиенты")
            .navigationBarItems(trailing:
                NavigationLink(destination: AddClientView(clients: $clients)) {
                Image(systemName: "plus.circle.fill")
                
                }
            )
            .onAppear {
                fetchClientsFromFirebase()
            }
        }
    }

    var sortedClientsForSelectedDate: [Client] {
        clients
            .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date < $1.date }
    }

    func deleteClient(at offsets: IndexSet) {
        let client = clients[offsets.first!]
        deleteClientFromFirebase(client)
        clients.remove(atOffsets: offsets)
    }

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()

    func fetchClientsFromFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("clients").whereField("userId", isEqualTo: userId).getDocuments { querySnapshot, error in
            if let error = error {
                print("Ошибка при получении клиентов: \(error.localizedDescription)")
            } else {
                clients = querySnapshot?.documents.compactMap { document in
                    let data = document.data()
                    let id = document.documentID
                    let firstName = data["firstName"] as? String ?? ""
                    let lastName = data["lastName"] as? String ?? ""
                    let phoneNumber = data["phoneNumber"] as? String ?? ""
                    let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                    let userId = data["userId"] as? String ?? ""
                    return Client(id: id, firstName: firstName, lastName: lastName, phoneNumber: phoneNumber, date: date, userId: userId)
                } ?? []
            }
        }
    }

    func deleteClientFromFirebase(_ client: Client) {
        let db = Firestore.firestore()
        db.collection("clients").document(client.id).delete { error in
            if let error = error {
                print("Ошибка при удалении клиента из базы данных: \(error.localizedDescription)")
            } else {
                print("Клиент успешно удален из базы данных")
            }
        }
    }
}

struct EditClientView: View {
    @State private var editedClient: Client
    @Binding var clients: [Client]
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode

    init(client: Client, clients: Binding<[Client]>) {
        self._editedClient = State(initialValue: client)
        self._clients = clients
    }

    var body: some View {
        VStack {
            Text("Редактирование данных")
                .fontWeight(.heavy)
                .font(.largeTitle)
                .padding([.top, .bottom], 20)
            
            TextField("Имя", text: $editedClient.firstName)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            TextField("Фамилия", text: $editedClient.lastName)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            
            
            TextField("Номер телефона", text: $editedClient.phoneNumber)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            DatePicker("Дата и время", selection: $editedClient.date, displayedComponents: [.date, .hourAndMinute])
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            Button(action: updateClientInFirebase) {
                Text("Сохранить изменения")
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 120)
                    .padding()
            }
            .background(Color.black)
            .clipShape(Capsule())
            .padding(.top, 45)
        }
        .padding()
        
        .alert(isPresented: $showAlert) {
                    Alert(title: Text("Успешно!"), message: Text(alertMessage), dismissButton: .default(Text("Ок")))
                }
            }
    func updateClientInFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("clients").document(editedClient.id).setData([
            "firstName": editedClient.firstName,
            "lastName": editedClient.lastName,
            "phoneNumber": editedClient.phoneNumber,
            "date": editedClient.date,
            "userId": userId
        ], merge: true) { error in
            if let error = error {
                alertMessage = "Ошибка при обновлении клиента в базе данных: \(error.localizedDescription)"
                showAlert = true
                print(alertMessage)
            } else {
                alertMessage = "Клиент успешно обновлен в базе данных"
                showAlert = true
                print(alertMessage)
                // Обновляем данные в массиве клиентов
                if let index = clients.firstIndex(where: { $0.id == editedClient.id }) {
                    clients[index] = editedClient
                }
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct AddClientView: View {
    @Binding var clients: [Client]
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var date = Date()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Новый клиент")
                .fontWeight(.heavy)
                .font(.largeTitle)
                .padding([.top, .bottom], 20)
            
            TextField("Имя", text: $firstName)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            TextField("Фамилия", text: $lastName)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            TextField("Номер телефона", text: $phoneNumber)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            DatePicker("Дата и время", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            Button(action: addClientToFirebase) {
                Text("Добавить клиента")
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 120)
                    .padding()
            }
            .background(Color.black)
            .clipShape(Capsule())
            .padding(.top, 45)
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("Ок")))
        }
    }

    func addClientToFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let newClientRef = db.collection("clients").document()
        let newClient = Client(id: newClientRef.documentID, firstName: firstName, lastName: lastName, phoneNumber: phoneNumber, date: date, userId: userId)

        newClientRef.setData([
            "firstName": newClient.firstName,
            "lastName": newClient.lastName,
            "phoneNumber": newClient.phoneNumber,
            "date": newClient.date,
            "userId": userId
        ]) { error in
            if let error = error {
                self.alertMessage = "Ошибка при добавлении клиента в базу данных: \(error.localizedDescription)"
                self.showAlert = true
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

