//
//  AuthenticationViewModel.swift
//  FirebaseBasic
//
//  Created by Jungjin Park on 2024-04-29.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

extension UIApplication {
    static var currentRootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .map({ $0 as? UIWindowScene })
        // 값이 존재할 때. nil 이면 drop
            .compactMap({ $0 })
            .first?.windows
            .filter({ $0.isKeyWindow })
            .first?
            .rootViewController
    }
}
@Observable
final class AuthenticationViewModel {
    enum State {
        case busy
        case signedIn
        case signedOut
    }
    
    var state: State = .busy
    private var authResult: AuthDataResult? = nil
    var username: String { authResult?.user.displayName ?? "" }
    var email: String { authResult?.user.email ?? "" }
    var photoURL: URL? { authResult?.user.photoURL }
    
    func logout() {
        
    }
    
    func restorePreviousSignIn() {
        
    }
    // Google 에 갔다 오는 것
    func login() {
        state = .busy
        guard let clientID = FirebaseApp.app()?.options.clientID,
              let rootViewController = UIApplication.currentRootViewController else {
            return
        }
        let configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = configuration
        // 화면 앞에 있는 컨트롤러랑 작업을 할 거야
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil) { result, error in
            if let error { print("Error: \(error.localizedDescription)")}
            Task {
                await self.signIn(user: result?.user)
            }
        }
    }
    // Firebase 정보를 가져오는 것
    private func signIn(user: GIDGoogleUser?) async {
        guard let user, let idToken = user.idToken else {
            state = .signedOut
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: user.accessToken.tokenString)
        
        do {
            authResult = try await Auth.auth().signIn(with: credential)
            state = .signedIn
        } catch {
            state = .signedOut
            print("Error: \(error.localizedDescription)")
        }
    }
}
