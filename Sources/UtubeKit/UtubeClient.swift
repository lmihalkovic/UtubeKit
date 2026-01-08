//
//  UtubeClient.swift
//  UtubeKit
//
//  Created by Laurent M
//


import Foundation
import GoogleSignIn



struct Req {
  let url: String
  let fields: [URLQueryItem]
}

let baseUrl: String =   "https://content-youtube.googleapis.com"

let PlaylistR: Req = Req(
//    url: "https://content-youtube.googleapis.com/youtube/v3/playlists?maxResults=25&mine=true&part=snippet%2CcontentDetails",
//  url: "https://content-youtube.googleapis.com/youtube/v3/playlists?maxResults=25&part=snippet%2CcontentDetails",
    url: "https://content-youtube.googleapis.com/youtube/v3/playlists",
    fields: [
      URLQueryItem(name: "mine",        value: "true"),
      URLQueryItem(name: "maxResults",  value: "25"),
      URLQueryItem(name: "part",        value: "snippet"),
      URLQueryItem(name: "part",        value: "contentDetails"),
    ]
)

let PlayListItemsR: Req = Req(
  url: "https://content-youtube.googleapis.com/youtube/v3/playlistItems",
  fields: [
    URLQueryItem(name: "maxResults",  value: "50"),
    URLQueryItem(name: "part",        value: "snippet"),
    URLQueryItem(name: "part",        value: "contentDetails"),
  ]
)

public struct UtubeClient  {

  // Scopes to request
  public static let SCOPES = [
    "https://www.googleapis.com/auth/youtube",
    "https://www.googleapis.com/auth/youtube.readonly",
   
//    // Used for user identification
//    "https://www.googleapis.com/auth/userinfo.profile",
//    "https://www.googleapis.com/auth/userinfo.email",
//    "openid"
  ]
  
  public var token: String?
  private let etagCache = ETagCache()
  private let session: GoogleSession
  
  public init(session: GoogleSession) {
    self.session = session
  }

  public func fetchPlaylists(completion: @escaping (Result<[Playlist], Swift.Error>) -> Void) {
    // delegate to the new paginated fetch - default: no limits
    fetchAllPlaylists(maxPages: nil, maxItems: nil, perPage: nil) { result in
      completion(result)
    }
  }
  
  public func fetchPlaylistItems(for playlistId: String,
                                 completion: @escaping (Result<[PlaylistItem], Swift.Error>) -> Void) {
    // delegate to the new paginated fetch - default: no limits
    fetchAllPlaylistItems(for: playlistId, maxItems: nil, perPage: nil) { result in
      completion(result)
    }
  }

  // Build a URLRequest with optional extra query items (like pageToken)
  private func newRequest(from req: Req, extraQueryItems: [URLQueryItem]? = nil) -> URLRequest? {
    var comps = URLComponents(string: req.url)
    var items = req.fields
    if let extra = extraQueryItems {
      items.append(contentsOf: extra)
    }
    comps?.queryItems = items

    guard let components = comps, let url = components.url else {
      return nil
    }
    return URLRequest(url: url)
  }

  // Fetch a single page of playlists (returns PlaylistListResponse so callers can inspect nextPageToken)
  public func fetchPlaylistsPage(pageToken: String?, completion: @escaping (Result<PlaylistListResponse, Swift.Error>) -> Void) {
    var extra: [URLQueryItem]? = nil
    if let token = pageToken {
      extra = [URLQueryItem(name: "pageToken", value: token)]
    }

    guard let req = newRequest(from: PlaylistR, extraQueryItems: extra) else {
      completion(.failure(UtubeClientError.noRequest))
      return
    }

    // Use async doGet to leverage ETag caching and rate-limit handling
    Task {
      do {
        let (data, _) = try await doGet(request: req)
        let decoder = JSONDecoder()
        let resp = try decoder.decode(PlaylistListResponse.self, from: data)
        completion(.success(resp))
      } catch {
        completion(.failure(error))
      }
    }
  }

  // Aggregator that follows nextPageToken until exhausted or until optional limits are reached.
  // - maxPages: optional limit on number of pages to fetch (useful to avoid extremely large collections)
  // - maxItems: optional limit on total items to fetch
  // - perPage: optional callback invoked for each page's items (useful for streaming UI updates)
  public func fetchAllPlaylists(maxPages: Int? = nil,
                         maxItems: Int? = nil,
                         perPage: (([Playlist]) -> Void)? = nil,
                         completion: @escaping (Result<[Playlist], Swift.Error>) -> Void) {

    var allItems: [Playlist] = []
    var pageToken: String? = nil
    var pagesFetched = 0

    func fetchNext() {
      
      // stop if we've hit maxPages
      if let maxP = maxPages, pagesFetched >= maxP {
        completion(.success(allItems))
        return
      }
      
      fetchPlaylistsPage(pageToken: pageToken) { result in
        switch result {
        case .success(let resp):
          let items = resp.items
          allItems.append(contentsOf: items)
          pagesFetched += 1

          // call perPage for streaming
          if let cb = perPage {
            cb(items)
          }

          // stop if we've hit maxItems
          if let maxI = maxItems, allItems.count >= maxI {
            if allItems.count > maxI {
              allItems = Array(allItems.prefix(maxI))
            }
            completion(.success(allItems))
            return
          }

          // continue if there's a next page token
          if let next = resp.nextPageToken, !next.isEmpty {
            pageToken = next
            fetchNext()
            return
          }

          // no more pages
          completion(.success(allItems))

        case .failure(let error):
          completion(.failure(error))
        }
      }
    }

    // start fetching
    fetchNext()
  }
  
  public func fetchAllPlaylistItems(for playlistId: String,
                                  maxItems: Int? = nil,
                                  perPage: (([PlaylistItem]) -> Void)? = nil,
                                  completion: @escaping (Result<[PlaylistItem], Swift.Error>) -> Void) {
    
    var allItems: [PlaylistItem] = []
    var pageToken: String? = nil
    var itemsFetched = 0
    
//    , completion: @escaping (Result<PlaylistListResponse, Swift.Error>) -> Void
    
    
    func _fetchNext() {
      
      _fetchItems(pageToken: nil) { result in
        switch result {
        case .success(let resp):
          let items = resp.items
          allItems.append(contentsOf: items)
          itemsFetched += items.count
          
          // continue if there's a next page token
          if let next = resp.nextPageToken, !next.isEmpty {
            pageToken = next
            _fetchNext()
            return
          }
          
          // no more pages
          completion(.success(allItems))

        case .failure(let error):
          completion(.failure(error))
        }
      }
      
    }
    
    func _fetchItems(pageToken: String?, completion: @escaping (Result<PlaylistItemListResponse, Swift.Error>) -> Void) {
      var extra: [URLQueryItem]? = [URLQueryItem(name: "playlistId", value: playlistId)]
      if let token = pageToken {
        extra?.append(URLQueryItem(name: "pageToken", value: token))
      }
      
      guard let req = newRequest(from: PlayListItemsR, extraQueryItems: extra) else {
        completion(.failure(UtubeClientError.noRequest))
        return
      }

      // Use async doGet to leverage ETag caching and rate-limit handling
      Task {
        do {
          let (data, _) = try await doGet(request: req)
          let decoder = JSONDecoder()
          let resp = try decoder.decode(PlaylistItemListResponse.self, from: data)
          
//          let xxx = decoder.decode
          
          completion(.success(resp))
        } catch {
          completion(.failure(error))
        }
      }
    }

    _fetchNext()
  }
  
  private func doGet(request: URLRequest, allowedStatuses: Set<Int> = [200, 304]) async throws -> (Data, HTTPURLResponse) {
    // Ensure we have a URL to key the cache
    guard let url = request.url else {
      throw UtubeClientError.noRequest
    }

    // Respect a global rate-limit if the cache says we're currently rate-limited
    if let until = await etagCache.rateLimitUntil() {
      throw UtubeClientError.rateLimited(until: until)
    }

    // Prepare a mutable request so we can add conditional headers
    var req = request

    // If we have a cached ETag for the URL, add If-None-Match to avoid consuming quota when not necessary
    if let cached = await etagCache.cached(for: url) {
      req.setValue(cached.etag, forHTTPHeaderField: "If-None-Match")
    }

    // Obtain a URLSession configured with a fresh token from GoogleSession
    let urlSession: URLSession
    do {
      urlSession = try await session.sessionWithFreshToken()
    } catch {
      throw UtubeClientError.noSession
    }

    // Perform request
    let (data, response) = try await urlSession.data(for: req)
    guard let httpResp = response as? HTTPURLResponse else {
      throw UtubeClientError.noValidResponse
    }

    let status = httpResp.statusCode

    // Header helper (case-insensitive)
    func header(_ name: String) -> String? {
      return httpResp.value(forHTTPHeaderField: name)
    }

    // Handle rate-limit responses (Retry-After / 429 / 503)
    if status == 429 || status == 503 {
      if let retryVal = header("Retry-After") {
        // Retry-After can be delta-seconds or an HTTP-date
        if let secs = TimeInterval(retryVal.trimmingCharacters(in: .whitespaces)), secs > 0 {
          let until = Date().addingTimeInterval(secs)
          await etagCache.setRateLimitReset(date: until)
          throw UtubeClientError.rateLimited(until: until)
        } else {
          // Try parsing as HTTP date (RFC1123)
          let df = DateFormatter()
          df.locale = Locale(identifier: "en_US_POSIX")
          df.timeZone = TimeZone(secondsFromGMT: 0)
          df.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
          if let date = df.date(from: retryVal) {
            await etagCache.setRateLimitReset(date: date)
            throw UtubeClientError.rateLimited(until: date)
          }
        }
      }
      // No Retry-After header: set a conservative default
      let defaultUntil = Date().addingTimeInterval(60)
      await etagCache.setRateLimitReset(date: defaultUntil)
      throw UtubeClientError.rateLimited(until: defaultUntil)
    }

    // 304 Not Modified -> return cached data if available
    if status == 304 {
      if let cached = await etagCache.cached(for: url) {
        return (cached.data, httpResp)
      } else {
        throw UtubeClientError.noData
      }
    }

    // 200 OK -> save ETag (if present) and data, then return
    if status == 200 {
      if let etag = header("ETag") {
        await etagCache.save(url: url, etag: etag, data: data)
      }
      return (data, httpResp)
    }

    // If the response status is in allowedStatuses but wasn't 200/304, pass through
    if allowedStatuses.contains(status) {
      return (data, httpResp)
    }

    // Otherwise treat it as an invalid response
    throw UtubeClientError.noValidResponse
  }
}


extension UtubeClient {
  enum UtubeClientError: Swift.Error {
    case noRequest
    case noData
    case noJSON
    case jsonDataCannotCastToString

    case noPlaylists
    case noVideos
    case noNextPageToken

    case noValidResponse
    case rateLimited(until: Date)
//    case couldNotRefreshToken
    case noSession
  }
}
