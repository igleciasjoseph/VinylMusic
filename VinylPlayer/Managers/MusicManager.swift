////
////  MusicManager.swift
////  VinylPlayer
////
////  Created by Joseph Iglecias on 12/9/24.
////
//
//import SwiftUI
//import MusicKit
//
//struct MusicSearchResult: Identifiable {
//    let id: String
//    let type: ResultType
//    let title: String
//    let subtitle: String
//    let artwork: URL?
//    
//    enum ResultType {
//        case song
//        case playlist
//        case artist
//    }
//}
//
//class MusicSearchManager: ObservableObject {
//    @Published var searchResults: [MusicSearchResult] = []
//    @Published var isAuthorized = false
//    @Published var isPlaying = false
//    
//    private var musicPlayer = MPMusicPlayerController.applicationMusicPlayer
//    
//    init() {
//        checkAuthorization()
//    }
//    
//    func checkAuthorization() {
//        Task {
//            do {
//                let status = try await MusicAuthorization.request()
//                await MainActor.run {
//                    self.isAuthorized = (status == .authorized)
//                }
//            } catch {
//                print("Authorization error: \(error)")
//            }
//        }
//    }
//    
//    func search(query: String) {
//        guard isAuthorized, !query.isEmpty else { return }
//        
//        Task {
//            do {
//                // Search for Songs
//                let songRequest = MusicCatalogSearchRequest(
//                    filter: MusicCatalogSearchRequest.Filter(rawValue: query),
//                    types: [Song.self]
//                )
//                let songResults = try await songRequest.fetch()
//                
//                // Search for Playlists
//                let playlistRequest = MusicCatalogSearchRequest(
//                    filter: MusicCatalogSearchRequest.Filter(rawValue: query),
//                    types: [Playlist.self]
//                )
//                let playlistResults = try await playlistRequest.fetch()
//                
//                // Search for Artists
//                let artistRequest = MusicCatalogSearchRequest(
//                    filter: MusicCatalogSearchRequest.Filter(rawValue: query),
//                    types: [Artist.self]
//                )
//                let artistResults = try await artistRequest.fetch()
//                
//                // Convert results to MusicSearchResult
//                await MainActor.run {
//                    self.searchResults = []
//                    
//                    // Add Songs
//                    self.searchResults += songResults.songs.map { song in
//                        MusicSearchResult(
//                            id: song.id.rawValue,
//                            type: .song,
//                            title: song.title,
//                            subtitle: song.artistName,
//                            artwork: song.artwork?.url(width: 100, height: 100)
//                        )
//                    }
//                    
//                    // Add Playlists
//                    self.searchResults += playlistResults.playlists.map { playlist in
//                        MusicSearchResult(
//                            id: playlist.id.rawValue,
//                            type: .playlist,
//                            title: playlist.name,
//                            subtitle: playlist.curatorName ?? "Playlist",
//                            artwork: playlist.artwork?.url(width: 100, height: 100)
//                        )
//                    }
//                    
//                    // Add Artists
//                    self.searchResults += artistResults.artists.map { artist in
//                        MusicSearchResult(
//                            id: artist.id.rawValue,
//                            type: .artist,
//                            title: artist.name,
//                            subtitle: "Artist",
//                            artwork: artist.artwork?.url(width: 100, height: 100)
//                        )
//                    }
//                }
//            } catch {
//                print("Search error: \(error)")
//            }
//        }
//    }
//    
//    func play(result: MusicSearchResult) {
//        Task {
//            do {
//                switch result.type {
//                case .song:
//                    let song = try await MusicCatalogResourceRequest<Song>().fetch().items.first
//                    if let song = song {
//                        try musicPlayer.setQueue(with: [song])
//                        musicPlayer.play()
//                    }
//                case .playlist:
//                    let playlist = try await MusicCatalogResourceRequest<Playlist>(identifiers: [result.id]).fetch().items.first
//                    if let playlist = playlist {
//                        try musicPlayer.setQueue(with: playlist)
//                        musicPlayer.play()
//                    }
//                case .artist:
//                    let artist = try await MusicCatalogResourceRequest<Artist>(identifiers: [result.id]).fetch().items.first
//                    if let artist = artist {
//                        // You might want to play top songs or create a station
//                        let topSongsRequest = artist.topSongsRequest
//                        let topSongs = try await topSongsRequest.fetch()
//                        try musicPlayer.setQueue(with: topSongs.items)
//                        musicPlayer.play()
//                    }
//                }
//                
//                await MainActor.run {
//                    self.isPlaying = true
//                }
//            } catch {
//                print("Playback error: \(error)")
//            }
//        }
//    }
//    
//    func pauseMusic() {
//        musicPlayer.pause()
//        isPlaying = false
//    }
//}
