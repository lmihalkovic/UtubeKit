//
//  UtubeService.swift
//  UtubeKit
//
//  Created by Laurent M
//

import Foundation
import GoogleSignIn


public class UtubeService: ObservableObject {
  
  @Published public var playlists: [Playlist] = []
  @Published public var isLoading = false
  @Published public var lastError: String?
  
  
  private var session: GoogleSession!
  private var apiClient: UtubeClient!
  @Published public var isSignedIn: Bool = false

  public init() {
    self.session = GoogleSession()
    self.apiClient = UtubeClient(session: session)

    // Try to silently restore a previous sign-in (GoogleSignIn stores credentials in the keychain)
    Task { [weak self] in
      guard let self = self else { return }
      let restored = await self.session.restorePreviousSignIn()
      await MainActor.run {
        self.isSignedIn = restored
      }

      // If we successfully restored credentials, prefetch playlists so UI is ready without requiring sign-in
      if restored {
        await self.fetchPlaylists()
      }
    }
  }

  public func signOut() async {
    session.signOut()
    await MainActor.run {
      isSignedIn = false
    }
  }
  
  public func signIn(clientID: String, presenting viewController: UIViewController) async {
    let res = await session.signIn(clientID: clientID, rootViewController: viewController, scopes: UtubeClient.SCOPES)
    
    await MainActor.run {
      isSignedIn = res
    }
  }
  
  public func fetchPlaylistItems(for playlistID: String) async -> Result<[PlaylistItem], Error> {
    return await withCheckedContinuation { continuation in
      apiClient.fetchPlaylistItems(for: playlistID) { result in
        Task { @MainActor in
          switch result {
          case .success(let items):
            self.lastError = nil
            print("Fetched \(items.count) items for playlist \(playlistID)")
            continuation.resume(returning: .success(items))
          case .failure(let error):
            self.lastError = error.localizedDescription
            continuation.resume(returning: .failure(error))
          }
        }
      }
    }
  }
  
  public func playlist(withID id: String) throws -> Playlist? {
    guard let playlist = playlists.first(where: { $0.id == id }) else {
      throw UtubeServiceError.playlistNotFound(id: id)
    }
    return playlist
  }
  
  // Protocol-compatible fetch used by ManagedListProtocol consumers
  public func fetchPlaylists() async {
    await MainActor.run { self.isLoading = true }
    apiClient.fetchPlaylists { result in
        Task { @MainActor in
            switch result {
            case .success(let playlists):
              self.playlists = playlists
              self.lastError = nil
            case .failure(let error):
              self.lastError = error.localizedDescription
            }
            self.isLoading = false
        }
    }
  }
}

extension UtubeService {
  enum UtubeServiceError: Swift.Error {
    case communicationError(Error)

    case playlistNotFound(id: String)

  }
}
