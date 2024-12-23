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
    @State private var isExpanded: Bool = false
    @State private var searchTerm = ""
    @State private var songSearchResults: MusicItemCollection<Song> = []
    @State private var personalPlaylistSearchResults: MusicItemCollection<Playlist> = []
    @State private var playlistSearchResults: MusicItemCollection<Playlist> = []
    
    @State private var isPresented: Bool = false
    @State private var isLoading: Bool = true
    @State private var isRotating = false
    
    @State private var playbackTime: TimeInterval = 0
    @State private var songDuration: TimeInterval = 1 // Placeholder to avoid division by zero
    @State private var isSliding: Bool = false
    
    @State private var selectedButton: String = "Songs"
    
    @State private var repeatedButtonName: String = "repeat"
    @State private var shuffledButtonName: String = "shuffle"
    
    // Computed property for formatted playback time
    var formattedPlaybackTime: String {
        playbackTime.stringFromTimeInterval()
    }
    
    // Computed property for countdown time
    var formattedCountdownTime: String {
        guard let totalDuration = currentSong?.duration else { return "00:00" }
        let remainingTime = max(totalDuration - playbackTime, 0) // Ensure it doesn't go negative
        return remainingTime.stringFromTimeInterval()
    }
    
    var body: some View {
        
        GeometryReader { proxy in
            VStack {
                ZStack {
                    // Expanded TextField
                    HStack {
                        
                        TextField("", text: $searchTerm, prompt: Text("Search...").foregroundStyle(.black))
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.35)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 8)
                            .foregroundStyle(.black)
                            .onSubmit {
                                Task {
                                    // Make sure we aren't calling the function multiple times
                                    if !searchTerm.isEmpty {
                                        if selectedButton == "Songs" {
                                            isPresented = true
                                            Task {
                                                await searchMusic()
                                                isLoading = false
                                            }
                                        } else {
                                            isPresented = true
                                            Task {
                                                await searchPlaylists()
                                                isLoading = false
                                            }
                                        }
                                    }
                                }
                            }
                        
                        if !searchTerm.isEmpty {
                            Button(action: {
                                searchTerm = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.black)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            selectedButton = "Songs"
                        } label: {
                            Text("Songs")
                                .padding(5)
                                .foregroundStyle(.black)
                                .background(selectedButton == "Songs" ? Color.white.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedButton == "Songs" ? Color.black : Color.clear, lineWidth: 1)
                                )
                        }
                        
                        // Playlists Button
                        Button {
                            selectedButton = "Playlists"
                        } label: {
                            Text("Playlists")
                                .padding(5)
                                .foregroundStyle(.black)
                                .background(selectedButton == "Playlists" ? Color.white.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedButton == "Playlists" ? Color.black : Color.clear, lineWidth: 1)
                                )
                        }
                    }
                    .padding()
                    .transition(.move(edge: .leading)) // Animation transition
                    .onTapGesture {
                        dismissKeyboard()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 50)
                .padding(.vertical)
                
                
                ZStack {
                    Group {
                        Image("vinylDisc")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .clipShape(Circle())
                            .rotationEffect(Angle(degrees: rotationAngle))
                        //                        .onChange(of: isPlaying) { newValue in
                        //                            withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                        //                                isRotating = true
                        //
                        //                                if newValue {
                        //                                    startRotation()
                        //                                } else {
                        //                                    stopRotation()
                        //                                }
                        //                            }
                        //                        }
                        
                        
                        if let currentSong = currentSong {
                            AsyncImage(url: currentSong.artwork?.url(width: 100, height: 100), transaction: Transaction(animation: Animation.easeInOut(duration: 3.0))) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                                        .onAppear {
                                            withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                                                isRotating = true
                                            }
                                        }
                                }
                            }
                        }
                    }
                    
                    Image("vinylDiscNeedle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .offset(x: 125)
                }
                .onChange(of: isPlaying) { newValue in
                    if newValue {
                        startRotation()
                    } else {
                        stopRotation()
                    }
                }
                
                VStack {
                    Text(currentSong?.title ?? "")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                    
                    Text(currentSong?.artistName ?? "")
                        .font(.body)
                        .foregroundStyle(.black)
                    
                    //                Text(currentSong?.duration?.stringFromTimeInterval() ?? "")
                    //                    .font(.body)
                    //                    .foregroundStyle(.black)
                }
                .padding(.top)
                .padding(.bottom, 50)
                
                Slider(
                    value: Binding(
                        get: { playbackTime },
                        set: { newValue in
                            playbackTime = newValue
                            if isSliding {
                                // Do not update playback time while sliding
                                return
                            }
                            updatePlaybackTime()
                        }
                    ),
                    in: 0...songDuration
                )
                .tint(.black)
                .onChange(of: isSliding) { sliding in
                    if !sliding {
                        updatePlaybackTime()
                    }
                }
                .onAppear {
                    configurePlayer()
                }
                .padding()
                
                HStack {
                    Text(isPlaying ? formattedPlaybackTime : "0:00")
                        .foregroundStyle(.black)
                    Spacer()
                    Text(formattedCountdownTime)
                        .foregroundStyle(.black)
                }
                .padding()
                
                Spacer()
                
                HStack(spacing: 50) {
                    
                    Button {
                        toggleRepeatMode()
                    } label: {
                        Image(systemName: repeatedButtonName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .tint(.black)
                    }
                    
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
                    
                    Button {
                        toggleShuffleMode()
                    } label: {
                        Image(systemName: shuffledButtonName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .tint(.black)
                    }
                }
                .padding()
            }
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
                        if selectedButton == "Songs" {
                            List(songSearchResults, id: \.id) { song in
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
                            .listRowSpacing(5)
                            .background(.cream)
                            .scrollContentBackground(.hidden)
                        } else {
                            List(personalPlaylistSearchResults, id: \.id) { playlist in
                                HStack {
                                    AsyncImage(url: playlist.artwork?.url(width: 50, height: 50)) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color.gray
                                    }
                                    .frame(width: 50, height: 50)
                                    
                                    VStack(alignment: .leading) {
                                        Text(playlist.name)
                                            .foregroundColor(.cream)
                                        Text(playlist.curatorName ?? "")
                                            .font(.caption)
                                            .foregroundColor(.cream)
                                    }
                                }
                                ForEach(playlistSearchResults) { playlist in
                                    HStack {
                                        AsyncImage(url: playlist.artwork?.url(width: 50, height: 50)) { image in
                                            image.resizable()
                                        } placeholder: {
                                            Color.gray
                                        }
                                        .frame(width: 50, height: 50)
                                        
                                        VStack(alignment: .leading) {
                                            Text(playlist.name)
                                                .foregroundColor(.cream)
                                            Text(playlist.curatorName ?? "")
                                                .font(.caption)
                                                .foregroundColor(.cream)
                                        }
                                    }
                                }
                                //                            .onTapGesture {
                                //                                playSong(song)
                                //                                isPresented = false
                                //                            }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .listRowSpacing(5)
                            .background(.cream)
                            .scrollContentBackground(.hidden)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    func toggleRepeatMode() {
        let player = musicPlayer.state

        // Define a dictionary for the repeat modes in sequential order
        let repeatModeSequence: [MusicPlayer.RepeatMode: MusicPlayer.RepeatMode] = [
            .none: .one,
            .one: .all,
            .all: .none
        ]

        let buttonNames: [MusicPlayer.RepeatMode: String] = [
            .none: "repeat",  // No repeat
            .one: "repeat.circle.fill",        // Repeat one
            .all: "repeat.1"           // Repeat all
        ]

        Task {
            do {
                // Get the current repeat mode
                let currentRepeatMode = player.repeatMode

                // Determine the next repeat mode based on the sequence
                let nextRepeatMode = repeatModeSequence[currentRepeatMode ?? .none]

                // Set the new repeat mode
                player.repeatMode = nextRepeatMode

                // Update the UI button name
                repeatedButtonName = buttonNames[nextRepeatMode ?? .none] ?? "repeat.circle"

                print("Repeat mode set to: \(nextRepeatMode)")
            } catch {
                print("Error toggling repeat mode: \(error)")
            }
        }
    }

    func toggleShuffleMode() {
        let player = musicPlayer.state

        // Define a dictionary for the shuffle modes (off and songs)
        let shuffleModeSequence: [MusicPlayer.ShuffleMode: MusicPlayer.ShuffleMode] = [
            .off: .songs,
            .songs: .off
        ]

        let buttonNames: [MusicPlayer.ShuffleMode: String] = [
            .off: "shuffle",           // Shuffle off
            .songs: "shuffle.circle"   // Shuffle songs
        ]

        Task {
            do {
                // Get the current shuffle mode
                let currentShuffleMode = player.shuffleMode

                // Determine the next shuffle mode based on the sequence
                let nextShuffleMode = shuffleModeSequence[currentShuffleMode ?? .off] ?? .off

                // Set the new shuffle mode
                player.shuffleMode = nextShuffleMode

                // Update the UI button name
                shuffledButtonName = buttonNames[nextShuffleMode ?? .off] ?? "shuffle"

                print("Shuffle mode set to: \(nextShuffleMode)")
            } catch {
                print("Error toggling shuffle mode: \(error)")
            }
        }
    }

    
    func secondsToHourMinFormat(time: TimeInterval) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: time / 10)
    }
    
    // Helper function to dismiss the keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func configurePlayer() {
        Task {
            while true {
                if !isSliding {
                    self.playbackTime = musicPlayer.playbackTime
                    self.songDuration = currentSong?.duration ?? 1
                }
                
                // Sleep for 0.5 seconds before updating again
                try await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
    
    func startRotation() {
        // Rotate the vinyl disc
        withAnimation(
            Animation.linear(duration: 3.0)
                .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
    
    func stopRotation() {
        // Stop the vinyl disc from rotating
        rotationAngle = 0
        isRotating = false // Ensure the rotating flag is false when paused
    }
    
    func updatePlaybackTime() {
        musicPlayer.playbackTime = playbackTime
    }
    
    func timeString(from time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func searchMusic() async {
        do {
            var request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
            request.limit = 25
            let response = try await request.response()
            songSearchResults = response.songs
            
            print(songSearchResults)
        } catch {
            print("Error searching music: \(error)")
        }
    }
    
    protocol Addable {
        static func +(lhs: Self, rhs: Self) -> Self
    }
    
    func add<T: Addable>(_ playlistOne: T, _ playlistTwo: T) -> T {
        return playlistOne + playlistTwo
    }
    
    func searchPlaylists() async {
        do {
            // Search in the Apple Music catalog
            var catalogRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Playlist.self])
            catalogRequest.limit = 25  // Limit the number of results
            
            let catalogResponse = try await catalogRequest.response()
            let catalogPlaylists = catalogResponse.playlists
            
            // Search in your personal library
            var libraryRequest = MusicLibrarySearchRequest(term: searchTerm, types: [Playlist.self])
            libraryRequest.limit = 25
            
            let libraryResponse = try await libraryRequest.response()
            let libraryPlaylists = libraryResponse.playlists
            
            personalPlaylistSearchResults = libraryPlaylists
            playlistSearchResults = catalogPlaylists
            
        } catch {
            print("Error searching playlists: \(error)")
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
