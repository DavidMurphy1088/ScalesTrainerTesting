import SwiftUI
import AudioKit
import AudioKitUI
import AVFoundation

struct FFTContentView: View {
    @StateObject private var audioManager = AudioManager1()
    @State var fftView: SpectrogramFlatView?
    
//    func getView(node:Node) -> some View {
//        let v =  SpectrogramFlatView(node: node).padding()
//        let s = v.spectogram
//        return v
//    }
    
    var body: some View {
        VStack {
            Spacer()
            Button("Play", action: {
                audioManager.play()
            }).padding()
            
            Spacer()
            Button("Pause", action: {
                audioManager.engine.pause()
            }).padding()

            Spacer()
            Button("Resume", action: {
                do {
                    try audioManager.engine.start()
                }
                catch let e {
                    print(e.localizedDescription)
                }
            }).padding()

            Spacer()
            Button("Stop", action: {
                audioManager.stop()
            }).padding()
            Spacer()
            
            if let player = audioManager.player {
                //getView(node: player).padding()
                SpectrogramFlatView(node: player).padding()
            }

            Spacer()
        }
        .onAppear {
            audioManager.setupAudioSession()
        }
        .onDisappear {
            audioManager.stop()
            
        }
        .padding()
    }
}

class AudioManager1: ObservableObject {
    @Published var player: AudioPlayer?
    var engine = AudioEngine()

    func setupAudioSession() {
        // Ensure the file exists in your project and is part of the target's bundled resources
        //let f = "church_4_octave_Cmajor_RH"
        let f = "4_octave_fast"
        //2_oct_strt_72_medium
        guard let fileURL = Bundle.main.url(forResource: f, withExtension: "m4a") else {
            print("Audio file not found.")
            return
        }
        do {
            // Use AudioKit's AudioFile class to handle the audio file
            let audioFile = try AVAudioFile(forReading: fileURL)
            player = AudioPlayer(file: audioFile)
            engine.output = player
            try engine.start()
        } catch {
            print("Error setting up audio player with AudioKit: \(error)")
        }
    }

    func play() {
        player?.play()
    }

    func stop() {
        player?.stop()
        //if engine.isRunning {
            engine.stop()
        //}
    }
}
