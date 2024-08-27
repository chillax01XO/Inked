import SwiftUI
import Foundation
import Firebase
import FirebaseFirestore

struct Transaction: Identifiable {
    var id: String // Используем строковый идентификатор от Firebase
    var type: String // Доход или расход
    var amount: Double
    var title: String
    var date: Date
}

struct Money: View {
    @State private var transactions: [Transaction] = []
    @State private var isAddingTransaction = false
    @State private var selectedDay: Date = Date()
    @State private var isDatePickerVisible = false
    @State private var selectedDate = Date()
    @State private var hasFetchedTransactions = false // Флаг, чтобы избежать повторной загрузки данных
    
    var currentMonth: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: selectedDay)
    }
    
    var totalIncome: Double {
        transactions.filter { $0.type == "Доход" && Calendar.current.isDate($0.date, equalTo: selectedDay, toGranularity: .month) }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        transactions.filter { $0.type == "Расход" && Calendar.current.isDate($0.date, equalTo: selectedDay, toGranularity: .month) }.reduce(0) { $0 + $1.amount }
    }
    
    var totalBalance: Double {
        totalIncome - totalExpense
    }
    
    struct MonthYearPicker: View {
        @Binding var selectedDate: Date
        
        var body: some View {
            VStack {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(WheelDatePickerStyle())
                    .onChange(of: selectedDate) { _ in
                        // Ограничиваем выбор только года и месяца
                        let components = Calendar.current.dateComponents([.year, .month], from: selectedDate)
                        selectedDate = Calendar.current.date(from: components) ?? Date()
                    }
            }
        }
    }
    
    func fetchTransactions() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let components = Calendar.current.dateComponents([.year, .month], from: selectedDay)
        
        db.collection("transactions")
            .whereField("userId", isEqualTo: user.uid)
            .whereField("year", isEqualTo: components.year!)
            .whereField("month", isEqualTo: components.month!)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting transactions: \(error)")
                } else {
                    self.transactions = querySnapshot!.documents.compactMap { document in
                        let data = document.data()
                        let title = data["title"] as? String ?? ""
                        let type = data["type"] as? String ?? ""
                        let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                        let amount = data["amount"] as? Double ?? 0.0
                        
                        return Transaction(id: document.documentID, type: type, amount: amount, title: title, date: date)
                    }
                }
            }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text(currentMonth)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                    .onTapGesture {
                        isDatePickerVisible = true
                    }
                
                if isDatePickerVisible {
                    MonthYearPicker(selectedDate: $selectedDay)
                        .padding()
                        .onDisappear {
                            isDatePickerVisible = false
                            fetchTransactions()
                        }
                        .onTapGesture {
                            isDatePickerVisible = false
                        }
                }
                
                HStack {
                    if totalIncome + totalExpense > 0 {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red)
                            .frame(width: CGFloat(totalExpense / (totalIncome + totalExpense)) * 300, height: 10)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green)
                            .frame(width: CGFloat(totalIncome / (totalIncome + totalExpense)) * 300, height: 10)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray)
                            .frame(width: 300, height: 10)
                    }
                }
                .padding(.vertical, 10)
                
                HStack {
                    Text("Доход:")
                    Text("\(String(format: "%.1f", totalIncome))₽")
                        .foregroundColor(.green)
                    
                    Text("Расход:")
                    Text("\(String(format: "%.1f", totalExpense))₽")
                        .foregroundColor(.red)
                    
                    Text("Баланс:")
                    Text("\(String(format: "%.1f", totalBalance))₽")
                        .foregroundColor(totalBalance > 0 ? .green : totalBalance < 0 ? .red : .black)
                }
                
                List {
                    ForEach(transactions.sorted(by: { $0.date > $1.date }), id: \.id) { transaction in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(transaction.title)")
                                    .foregroundColor(transaction.type == "Расход" ? .red : .green)
                                Text("\(transaction.date, formatter: DateFormatter.shortDateFormatter)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(String(format: "%.1f₽", transaction.amount))
                            Button(action: {
                                deleteTransaction(transaction)
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle()) // добавляем стиль кнопки для корректного распознавания
                        }
                    }
                }
                .onAppear {
                    if !hasFetchedTransactions {
                        fetchTransactions()
                        hasFetchedTransactions = true
                    }
                }
                
                Spacer()
            }
            .navigationBarTitle("Финансы")
            .navigationBarItems(trailing:
                                    Button(action: {
                isAddingTransaction = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
            }
            .scaleEffect(0.67)
            )
            .sheet(isPresented: $isAddingTransaction) {
                AddTransactionView(isPresented: $isAddingTransaction, transactions: $transactions)
            }
            .onTapGesture { // Скрыть меню выбора даты при нажатии на любое место экрана
                isDatePickerVisible = false
            }
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        let db = Firestore.firestore()
        db.collection("transactions").document(transaction.id).delete { error in
            if let error = error {
                print("Error removing document: \(error)")
            } else {
                print("Document successfully removed")
                transactions.removeAll { $0.id == transaction.id }
            }
        }
    }
}

struct AddTransactionView: View {
    @Binding var isPresented: Bool
    @Binding var transactions: [Transaction]
    
    @State private var transactionType = "Доход"
    @State private var amount = ""
    @State private var title = ""
    @State private var date = Date()
    
    var body: some View {
        VStack {
            Text("Добавить")
                .fontWeight(.heavy)
                .font(.largeTitle)
                .padding([.top, .bottom], 20)
            
            Picker("Тип транзакции", selection: $transactionType) {
                Text("Доход").tag("Доход")
                Text("Расход").tag("Расход")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(5.0)
            .padding(.bottom, 20)
            
            TextField("Сумма", text: $amount)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            TextField("Название", text: $title)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            DatePicker("Дата", selection: $date, displayedComponents: .date)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            Button(action: {
                if let amount = Double(amount) {
                    guard let user = Auth.auth().currentUser else { return }
                    let db = Firestore.firestore()
                    var ref: DocumentReference? = nil
                    ref = db.collection("transactions").addDocument(data: [
                        "userId": user.uid,
                        "type": transactionType,
                        "amount": amount,
                        "title": title,
                        "date": date,
                        "year": Calendar.current.component(.year, from: date),
                        "month": Calendar.current.component(.month, from: date)
                    ]) { err in
                        if let err = err {
                            print("Error adding document: \(err)")
                        } else {
                            print("Document added with ID: \(ref!.documentID)")
                            let newTransaction = Transaction(id: ref!.documentID, type: transactionType, amount: amount, title: title, date: date)
                            transactions.append(newTransaction)
                            isPresented = false
                        }
                    }
                }
            }) {
                Text("Сохранить")
                        .foregroundColor(.white)
                        .frame(width: UIScreen.main.bounds.width - 120)
                        .padding()
                }
                .background(Color.black)
                .clipShape(Capsule())
                .padding(.top, 45)
            }
            .padding()
            
        }
    }

