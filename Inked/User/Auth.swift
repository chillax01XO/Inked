import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth

struct SignIn : View {
    
    @State var user = ""
    @State var pass = ""
    @State var message = ""
    @State var alert = false
    @State var show = false
    
    var body : some View {
        VStack {
            VStack {
                Text("Авторизация").fontWeight(.heavy).font(.largeTitle).padding([.top,.bottom], 20)
                
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("Email").font(.headline).fontWeight(.light).foregroundColor(Color.init(.label).opacity(0.75))
                        
                        HStack {
                            TextField("Введите адрес электронной почты", text: $user)
                            
                            if user != "" {
                                Image("check").foregroundColor(Color.init(.label))
                            }
                        }
                        
                        Divider()
                    }.padding(.bottom, 15)
                    
                    VStack(alignment: .leading) {
                        Text("Пароль").font(.headline).fontWeight(.light).foregroundColor(Color.init(.label).opacity(0.75))
                        
                        SecureField("Введите пароль", text: $pass)
                        
                        Divider()
                    }
                }.padding(.horizontal, 6)
                
                Button(action: {
                    signInWithEmail(email: self.user, password: self.pass) { (verified, status) in
                        if !verified {
                            self.message = status
                            self.alert.toggle()
                        } else {
                            UserDefaults.standard.set(true, forKey: "status")
                            NotificationCenter.default.post(name: NSNotification.Name("statusChange"), object: nil)
                        }
                    }
                }) {
                    Text("Войти").foregroundColor(.white).frame(width: UIScreen.main.bounds.width - 120).padding()
                }.background(Color.black)
                    .clipShape(Capsule())
                    .padding(.top, 45)
            }.padding()
                .alert(isPresented: $alert) {
                    Alert(title: Text("Ошибка"), message: Text("Проверьте правильность ввода данных"), dismissButton: .default(Text("Ок")))
            }
            VStack {
                HStack(spacing: 8) {
                    Text("Нет аккаунта?").foregroundColor(Color.gray.opacity(0.5))
                    
                    Button(action: {
                        self.show.toggle()
                    }) {
                        Text("Создать")
                    }.foregroundColor(.blue)
                }.padding(.top, 25)
            }.sheet(isPresented: $show) {
                SignUp(show: self.$show)
            }
        }
    }
}


func signInWithEmail(email: String,password : String,completion: @escaping (Bool,String)->Void){
    
    Auth.auth().signIn(withEmail: email, password: password) { (res, err) in
        
        if err != nil{
            
            completion(false,(err?.localizedDescription)!)
            return
        }
        
        completion(true,(res?.user.email)!)
    }
}
