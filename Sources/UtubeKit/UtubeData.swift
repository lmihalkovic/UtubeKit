//
//  UtubeData.swift
//  UtubeKit
//
//  Created by Laurent M
//


import Foundation

// MARK: - COMMUNICATION base

public class PageInfo: Codable {
  public var totalResults: Int   // 228,
  public var resultsPerPage: Int // 25
  
  public init(totalResults: Int, resultsPerPage: Int) {
    self.totalResults = totalResults
    self.resultsPerPage = resultsPerPage
  }
}

public enum ThumbnailName: String, CaseIterable, Codable {
  case `default`
  case medium
  case high
  case standard
  case maxres
}

public struct Thumbnail: Codable, Equatable {
  public let url: String
  public var width: Int
  public var height: Int
  
  public init(url: String, width: Int, height: Int) {
    self.url = url
    self.width = width
    self.height = height
  }
}

// -----------------------------------------------------------------------

// MARK: - COMMUNICATION responses

public struct PlaylistListResponse: Codable {
  public var kind: String            //"youtube#playlistListResponse"
  public var etag: String            //"lIoFip7KLPNcgnm0UuJCKmirf4s"
  public var nextPageToken: String?  //"CBkQAA"
  public var prevPageToken: String?  //"CBkQAA"
  public var pageInfo: PageInfo
  public let items: [Playlist]
  
  public init(kind: String, etag: String, nextPageToken: String?, prevPageToken: String?, pageInfo: PageInfo, items: [Playlist]) {
    self.kind = kind
    self.etag = etag
    self.nextPageToken = nextPageToken
    self.prevPageToken = prevPageToken
    self.pageInfo = pageInfo
    self.items = items
  }
}

public struct PlaylistItemListResponse: Codable {
  public var kind: String            //"youtube#playlistListResponse"
  public var etag: String            //"lIoFip7KLPNcgnm0UuJCKmirf4s"
  public var nextPageToken: String?  //"CBkQAA"
  public var prevPageToken: String?  //"CBkQAA"
  public var pageInfo: PageInfo
  public let items: [PlaylistItem]
  
  public init(kind: String, etag: String, nextPageToken: String?, prevPageToken: String?, pageInfo: PageInfo, items: [PlaylistItem]) {
    self.kind = kind
    self.etag = etag
    self.nextPageToken = nextPageToken
    self.prevPageToken = prevPageToken
    self.pageInfo = pageInfo
    self.items = items
  }
}

// -----------------------------------------------------------------------

// MARK: - DATA - Playlist

public struct Playlist: Codable, Identifiable, Equatable {
  public let id: String
  public let contentDetails: PlaylistDetails
  public let snippet: PlaylistSnippet
  
  public init(id: String, contentDetails: PlaylistDetails, snippet: PlaylistSnippet) {
    self.id = id
    self.contentDetails = contentDetails
    self.snippet = snippet
  }
}

public struct PlaylistDetails: Codable, Equatable {
  public let itemCount: Int
  
  public init(itemCount: Int) {
    self.itemCount = itemCount
  }
}

public struct PlaylistSnippet: Codable, Equatable {
  public let publishedAt: String
  public let title: String
  public let description: String
  public let thumbnails: [String: Thumbnail]?
  
  public init(publishedAt: String, title: String, description: String, thumbnails: [String: Thumbnail]?) {
    self.publishedAt = publishedAt
    self.title = title
    self.description = description
    self.thumbnails = thumbnails
  }
}

// MARK: - DATA - PlaylistIten

public struct PlaylistItem: Codable, Identifiable, Equatable {
  public let id: String
  public let contentDetails: PlaylistItemDetails
  public let snippet: PlaylistItemSnippet
  
  public init(id: String, contentDetails: PlaylistItemDetails, snippet: PlaylistItemSnippet) {
    self.id = id
    self.contentDetails = contentDetails
    self.snippet = snippet
  }
}

public struct PlaylistItemDetails: Codable, Equatable {
  public let videoId: String
  public let videoPublishedAt: String
  
  public init(videoId: String, videoPublishedAt: String) {
    self.videoId = videoId
    self.videoPublishedAt = videoPublishedAt
  }
}

public struct PlaylistItemSnippet: Codable, Equatable {
  public let channelId: String
  public let playlistId: String
  public let title: String
  public let description: String
  public let position: Int
  public let publishedAt: String
  public let thumbnails: [String: Thumbnail]?
  public let resourceId: ResourceId
  
  public let videoOwnerChannelId: String?
  public let videoOwnerChannelTitle: String?
    
  public init(channelId: String, playlistId: String, title: String, description: String, position: Int, publishedAt: String, thumbnails: [String: Thumbnail]?, resourceId: ResourceId, videoOwnerChannelId: String?, videoOwnerChannelTitle: String?) {
    self.channelId = channelId
    self.playlistId = playlistId
    self.title = title
    self.description = description
    self.position = position
    self.publishedAt = publishedAt
    self.thumbnails = thumbnails
    self.resourceId = resourceId
    self.videoOwnerChannelId = videoOwnerChannelId
    self.videoOwnerChannelTitle = videoOwnerChannelTitle
  }
}

public struct ResourceId: Codable, Equatable {
  public let kind: String            //"youtube#video",
  public let videoId: String
  
  public init(kind: String, videoId: String) {
    self.kind = kind
    self.videoId = videoId
  }
}
