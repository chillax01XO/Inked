import SwiftUI
import Firebase

struct Material: Identifiable {
    var id: String = UUID().uuidString
    var type: String
    var name: String
    var color: String?
    var size: String?
    var quantity: String
    var unit: String?
}

struct MaterialsView: View {
    @State private var materials: [Material] = []
    @State private var showingAddMaterial = false
    @State private var showingEditMaterial: Material?
    @State private var showingOnlyLowStock = false

    var filteredMaterials: [Material] {
        showingOnlyLowStock ? materials.filter { Int($0.quantity) ?? 0 < 10 } : materials
    }

    func fetchMaterials() {
        let db = Firestore.firestore()
        db.collection("materials").getDocuments { (querySnapshot, error) in
            if let querySnapshot = querySnapshot {
                self.materials = querySnapshot.documents.map {
                    Material(
                        id: $0.documentID,
                        type: $0["type"] as? String ?? "",
                        name: $0["name"] as? String ?? "",
                        color: $0["color"] as? String,
                        size: $0["size"] as? String,
                        quantity: $0["quantity"] as? String ?? "",
                        unit: $0["unit"] as? String
                    )
                }
            }
        }
    }

    func deleteMaterial(at offsets: IndexSet) {
        let db = Firestore.firestore()
        offsets.forEach { index in
            let matId = materials[index].id
            materials.remove(at: index)
            db.collection("materials").document(matId).delete { error in
                if let error = error {
                    print("Error removing document: \(error)")
                    // Если нужно восстановить удаленный элемент из-за ошибки, это можно сделать здесь.
                } else {
                    print("Document successfully removed!")
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Категория", selection: $showingOnlyLowStock) {
                    Text("Все").tag(false)
                    Text("Заканчивается").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                List {
                    ForEach(["Иглы", "Краска", "Другое"], id: \.self) { category in
                        Section(header: Text(category)) {
                            ForEach(filteredMaterials.filter { $0.type == category }) { material in
                                MaterialRow(material: material)
                                    .onTapGesture {
                                        showingEditMaterial = material
                                    }
                            }
                            .onDelete(perform: deleteMaterial)
                        }
                    }
                }
                .sheet(item: $showingEditMaterial) { material in
                    AddMaterialView(materials: $materials, existingMaterial: material, fetchMaterials: fetchMaterials)
                }
            }
            .navigationBarTitle("Материалы", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                showingAddMaterial.toggle()
            }) {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
            })
            .sheet(isPresented: $showingAddMaterial) {
                AddMaterialView(materials: $materials, fetchMaterials: fetchMaterials)
            }
            .onAppear(perform: fetchMaterials)
        }
    }
}

struct MaterialRow: View {
    var material: Material

    var body: some View {
        HStack {
            Group {
                Text(material.name)
                Spacer()
                if let size = material.size {
                    Text(size)
                }
                if material.type == "Краска", let color = material.color {
                    Text(color)
                }
                Text(material.quantity)
                if let unit = material.unit {
                    Text(unit)
                }
            }
            .foregroundColor(Int(material.quantity) ?? 0 < 10 ? .red : .primary)
        }
    }
}

struct AddMaterialView: View {
    @Binding var materials: [Material]
    @Environment(\.dismiss) var dismiss
    var fetchMaterials: () -> Void
    @State private var selectedType: String
    @State private var name: String
    @State private var color: String
    @State private var size: String
    @State private var quantity: String
    @State private var unit: String = "мл"  // Default unit for paint
    @State private var existingMaterial: Material?

    
    init(materials: Binding<[Material]>, existingMaterial: Material? = nil, fetchMaterials: @escaping () -> Void) {
        _materials = materials
        self.fetchMaterials = fetchMaterials
        _existingMaterial = State(initialValue: existingMaterial)
        _selectedType = State(initialValue: existingMaterial?.type ?? "Иглы")
        _name = State(initialValue: existingMaterial?.name ?? "")
        _color = State(initialValue: existingMaterial?.color ?? "")
        _size = State(initialValue: existingMaterial?.size ?? "")
        _quantity = State(initialValue: existingMaterial?.quantity ?? "")
        _unit = State(initialValue: existingMaterial?.unit ?? "шт")
    }

    var body: some View {
        VStack {
            Text(existingMaterial != nil ? "Редактировать" : "Добавить")
                .fontWeight(.heavy)
                .font(.largeTitle)
                .padding([.top, .bottom], 20)

            Picker("Тип", selection: $selectedType) {
                Text("Иглы").tag("Иглы")
                Text("Краска").tag("Краска")
                Text("Другое").tag("Другое")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(5.0)
            .padding(.bottom, 20)

            TextField("Название", text: $name)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            if selectedType != "Иглы" {
                TextField("Цвет", text: $color)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
            }
            if selectedType != "Краска" {
                TextField("Размер", text: $size)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
            }
            
            TextField("Количество", text: $quantity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
                
            if selectedType == "Краска" {
                Text("мл")
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
            } else if selectedType == "Другое" {
                TextField("Единицы измерения (мл, шт, гр)", text: $unit)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
            }

            Button(action: saveMaterial) {
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

  

    func saveMaterial() {
        let db = Firestore.firestore()
        if selectedType == "Краска" {
            unit = "мл"  // Ensure unit is always "мл" for paint
        }
        let data = [
            "type": selectedType,
            "name": name,
            "color": color,
            "size": size,
            "quantity": quantity,
            "unit": unit
        ]

        if let existingMaterial = existingMaterial {
            db.collection("materials").document(existingMaterial.id).updateData(data) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("Document successfully updated")
                    fetchMaterials()
                    dismiss()
                }
            }
        } else {
            db.collection("materials").addDocument(data: data) { error in
                if let error = error {
                    print("Error adding document: \(error)")
                } else {
                    print("Document successfully added")
                    fetchMaterials()
                    dismiss()
                }
            }
        }
    }
}
