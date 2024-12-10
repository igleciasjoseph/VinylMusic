//
//  VinylPlayerView.swift
//  VinylPlayer
//
//  Created by Joseph Iglecias on 12/9/24.
//

import SwiftUI
import MusicKit

struct VinylPlayerView: View {
    
    @State private var rotationAngle: Double = 0
    
    private var musicPlayer = ApplicationMusicPlayer.shared
    
    @State private var isPlaying = false
    @State private var currentSong: Song?
    @State private var searchTerm = ""
    @State private var searchResults: MusicItemCollection<Song> = []
    
    @State private var isPresented: Bool = false
    @State private var isLoading: Bool = true
    
    var body: some View {
        
        VStack {
            TextField("Search for a song", text: $searchTerm)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onSubmit {
                    Task {
                        isPresented = true
                        await searchMusic()
                        isLoading = false
                    }
                }
            
            ZStack {
                Group {
                    Image("vinylDisc")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .clipShape(Circle())
                        .rotationEffect(Angle(degrees: rotationAngle))
                        .onAppear {
                            withAnimation(
                                Animation.linear(duration: 3.0)
                                    .repeatForever(autoreverses: false)
                            ) {
                                rotationAngle = 360
                            }
                        }
                    
                    if let currentSong = currentSong {
                        AsyncImage(url: currentSong.artwork?.url(width: 100, height: 100)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .rotationEffect(.degrees(rotationAngle))
                            }
                        }
                        .animation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false), value: rotationAngle)
                    }
                }
                
                Image("vinylDiscNeedle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .offset(x: 125)
            }
            
            VStack {
                Text(currentSong?.title ?? "")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                
                Text(currentSong?.artistName ?? "")
                    .font(.body)
                    .foregroundStyle(.black)
                
                Text(currentSong?.duration?.stringFromTimeInterval() ?? "")
                    .font(.body)
                    .foregroundStyle(.black)
            }
            .padding(.top)
            .padding(.bottom, 50)
            
            Spacer()
            
            HStack(spacing: 50) {
                Button {
                    previousSong()
                } label: {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .tint(.black)
                }
                
                Button {
                    togglePlayPause()
                    print(currentSong)
                } label: {
                    Image(systemName: "playpause.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black)
                }
                
                Button {
                    nextSong()
                } label: {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .tint(.black)
                }
            }
            .padding()
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            Task {
                await MusicAuthorization.request()
            }
        }
        .sheet(isPresented: $isPresented) {
            ZStack {
                Color.cream.ignoresSafeArea()
                if isLoading {
                    // Show a ProgressView while data is loading
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .foregroundStyle(.black)
                } else {
                    List(searchResults, id: \.id) { song in
                        HStack {
                            AsyncImage(url: song.artwork?.url(width: 50, height: 50)) { image in
                                image.resizable()
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 50, height: 50)
                            
                            VStack(alignment: .leading) {
                                Text(song.title)
                                    .foregroundColor(.cream)
                                Text(song.artistName)
                                    .font(.caption)
                                    .foregroundColor(.cream)
                            }
                        }
                        .onTapGesture {
                            playSong(song)
                            isPresented = false
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.cream)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }
    
    func searchMusic() async {
        do {
            var request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
            request.limit = 25
            let response = try await request.response()
            searchResults = response.songs
            
            print(searchResults)
        } catch {
            print("Error searching music: \(error)")
        }
    }
    
    func playSong(_ song: Song) {
        Task {
            do {
                try await musicPlayer.queue = [song]
                try await musicPlayer.play()
                currentSong = song
                isPlaying = true
            } catch {
                print("Error playing song: \(error)")
            }
        }
    }
    
    func togglePlayPause() {
        Task {
            do {
                if isPlaying {
                    try await musicPlayer.pause()
                } else {
                    try await musicPlayer.play()
                }
                
                isPlaying.toggle()
            } catch {
                print("Error toggling play/pause: \(error)")
            }
        }
    }
    
    func nextSong() {
        Task {
            do {
                try await musicPlayer.skipToNextEntry()
                updateCurrentSong()
            } catch {
                print("Error skipping to next song: \(error)")
            }
        }
    }
    
    func previousSong() {
        Task {
            do {
                try await musicPlayer.skipToPreviousEntry()
                updateCurrentSong()
            } catch {
                print("Error going to previous song: \(error)")
            }
        }
    }
    
    func updateCurrentSong() {
        Task {
            do {
                if let nowPlayingItem = try await musicPlayer.queue.entries.first?.item as? Song {
                    currentSong = nowPlayingItem
                    isPlaying = musicPlayer.state.playbackStatus == .playing
                    //                        if isPlaying {
                    //                            startRotation()
                    //                        } else {
                    //                            stopRotation()
                    //                        }
                }
            } catch {
                print("Error updating current song: \(error)")
            }
        }
    }
}

extension TimeInterval {
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        
        return String(format: "%0.2d:%0.2d", minutes, seconds)
    }
}

#Preview {
    VinylPlayerView()
}
