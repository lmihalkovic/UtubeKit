//
//  GoogleSession.swift
//  UtubeKit
//
//  Created by Laurent M
//

import Foundation
import GoogleSignIn

// =======================================================================

public class GoogleSession {
  
  static let shared = GoogleSession()

  public var token: String?
  public var userInfo: String?
  private var result: Result<URLSession, SessionError>?
  private var grantedScopes: [String]?
  
  
  public func signOut() {
    GIDSignIn.sharedInstance.signOut()
  }
  
  public func signIn(clientID: String, rootViewController: UIViewController, scopes: [String]) async -> Bool {
//    let config = GIDConfiguration(clientID: clientID)
//    GIDSignIn.sharedInstance.configuration = config
    
    let signedId = await withCheckedContinuation { continuation in
      
      GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: scopes) { [weak self] result, error in

        guard let self = self else {
          continuation.resume(returning: false)
          return
        }
        
        guard let result else {
          print("Error signing in: \(String(describing: error))")
          continuation.resume(returning: false)
          return
        }
        
        print("Successfully signed in user")
        self.userInfo = result.user.profile?.json ?? ""
        self.token = result.user.accessToken.tokenString
        self.grantedScopes = result.user.grantedScopes

        continuation.resume(returning: true)
        return
      }
    }
    
    return signedId
  }

  
  public func sessionWithFreshToken(completion: @escaping (Result<URLSession, SessionError>) -> Void) {
    GIDSignIn.sharedInstance.currentUser?.refreshTokensIfNeeded { user, error in
      // Prefer token from the refreshed user if available
      if let refreshed = user?.accessToken.tokenString {
        self.token = refreshed
      }
      
      guard let token = self.token else {
        self.result = .failure(.couldNotRefreshToken)
        completion(self.result!)
        return
      }
      
      let config = URLSessionConfiguration.default
      config.httpAdditionalHeaders = [
        "Authorization": "Bearer \(token)"
      ]
      let session = URLSession(configuration: config)
      self.result = .success(session)
      completion(self.result!)
    }
  }
  
  /// Async variant: return a URLSession configured with a fresh token, or throw if refresh fails.
  public func sessionWithFreshToken() async throws -> URLSession {
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URLSession, Error>) in
      self.sessionWithFreshToken { result in
        switch result {
        case .success(let session): continuation.resume(returning: session)
        case .failure(let err): continuation.resume(throwing: err)
        }
      }
    }
  }
  
  /// Attempt to silently restore a previous sign-in (if the user previously signed in and credentials are available).
  /// Returns true if a previous sign-in was successfully restored and internal tokens were populated.
  /// GoogleSignIn stores credentials in the Keychain; calling this avoids presenting the sign-in UI each launch.
  public func restorePreviousSignIn() async -> Bool {
    return await withCheckedContinuation { continuation in
      GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
        guard let user = user else {
          continuation.resume(returning: false)
          return
        }
        
        // Populate session state from restored user
        self.userInfo = user.profile?.json ?? ""
        self.token = user.accessToken.tokenString ?? ""
        self.grantedScopes = user.grantedScopes ?? []
        
        continuation.resume(returning: true)
      }
    }
  }
  
  /// Execute an action with a valid URLSession (throws if no session is available).
  public func executeWithSession(action: @escaping (URLSession) -> Void) throws {
    switch result! {
    case .success(let session):
      action(session)
    case .failure:
      fatalError("No session")
    }
  }
  
  public var hasSession: Bool {
    if let result = result {
      if case .success = result {
        return true
      }
    }
    return false
  }
}

public extension GoogleSession {
  enum SessionError: Swift.Error {
    case noRequest
    case noData
    case noJSON
    case jsonDataCannotCastToString
    case couldNotRefreshToken
  }
}

public extension GIDProfileData {
  var json: String {
    """
    success: {
      Given Name: \(self.givenName ?? "None")
      Family Name: \(self.familyName ?? "None")
      Name: \(self.name)
      Email: \(self.email)
      Profile Photo: \(self.imageURL(withDimension: 1)?.absoluteString ?? "None");
    }
    """
  }
}
