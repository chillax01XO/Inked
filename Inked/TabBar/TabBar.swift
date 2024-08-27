import SwiftUI

struct TabBar: View {
    
    @State private var selection: String = "home"
    @AppStorage("selectedTab") var selectedTab: String = "home" // Используем @AppStorage для хранения выбранного таба
    
    var body: some View {
        TabView(selection: $selection) {
            ClientView()
                .tabItem {
                    Image(systemName:"calendar.badge.clock")
                    Text("Запись")
                }
                .tag("calendar")
            
            Money()
                .tabItem {
                    Image(systemName:"rublesign.circle.fill")
                    Text("Финансы")
                }
                .tag("money")
            
            Chat()
                .tabItem {
                    Image(systemName:"paperplane.fill")
                    Text("Чат")
                }
                .tag("chat") // Указываем тег для каждого таба
            
            MaterialsView()
                .tabItem {
                    Image(systemName:"tray.2.fill")
                    Text("Расходники")
                }
                .tag("material")
            Settings()
                .tabItem {
                    Image(systemName:"gearshape.fill")
                    Text("Настройки")
                }
                .tag("settings")
           
        }
        .onAppear {
            selection = selectedTab // Восстанавливаем выбранный таб при запуске приложения
        }
        .onChange(of: selection) { value in
            selectedTab = value // Сохраняем выбранный таб при изменении
        }
    }
}


