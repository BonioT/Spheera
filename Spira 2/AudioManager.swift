//
//  AudioManager.swift
//  Spheera
//
//  Created by Antonio Bonetti.
//

import Foundation
import AVFoundation

@MainActor
final class AudioManager {

    static let shared = AudioManager()

    private var cuePlayer: AVAudioPlayer?
    private var loopPlayer: AVAudioPlayer?

    private init() {}

    func playCue(fileName: String) {
        let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return }

        let name = parts[0]
        let ext = parts[1]

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }

        do {
            cuePlayer = try AVAudioPlayer(contentsOf: url)
            cuePlayer?.prepareToPlay()
            cuePlayer?.play()
        } catch {
            print("Cue playback failed: \(error)")
        }
    }

    func startLoop(fileName: String, volume: Float = 0.6) {
        stopLoop(fadeDuration: 0) // prevents overlap without fading

        let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return }

        let name = parts[0]
        let ext = parts[1]

        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            loopPlayer = try AVAudioPlayer(contentsOf: url)
            loopPlayer?.numberOfLoops = -1
            loopPlayer?.volume = volume
            loopPlayer?.prepareToPlay()
            loopPlayer?.play()
        } catch {
            print("Loop playback failed: \(error)")
        }
    }

    func stopLoop(fadeDuration: TimeInterval = 0.35) {
        guard let player = loopPlayer else { return }

        if fadeDuration <= 0 {
            player.stop()
            loopPlayer = nil
            return
        }

        player.setVolume(0.0, fadeDuration: fadeDuration)

        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) { [weak self] in
            guard let self else { return }
            player.stop()
            if self.loopPlayer === player {
                self.loopPlayer = nil
            }
        }
    }
}
