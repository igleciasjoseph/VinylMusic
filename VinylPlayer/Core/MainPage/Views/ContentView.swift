//
//  ContentView.swift
//  VinylPlayer
//
//  Created by Joseph Iglecias on 12/9/24.
//

import SwiftUI
import MusicKit

struct ContentView: View {
    var body: some View {
        VStack {
            VinylPlayerView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.cream.ignoresSafeArea(.all)
        )
    }
}

#Preview {
    ContentView()
}
