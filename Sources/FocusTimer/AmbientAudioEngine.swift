import AVFoundation
import Combine

// MARK: - Ambient Sound

enum AmbientSound: String, Identifiable {
    case white = "white"
    case rain  = "rain"
    case lofi  = "lofi"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .white: return "waveform"
        case .rain:  return "cloud.rain"
        case .lofi:  return "music.note"
        }
    }

    var locKey: String {
        switch self {
        case .white: return "ambient.white"
        case .rain:  return "ambient.rain"
        case .lofi:  return "ambient.lofi"
        }
    }

    static let all: [AmbientSound] = [.white, .rain, .lofi]
}

// MARK: - Engine

final class AmbientAudioEngine: ObservableObject {

    @Published private(set) var current: AmbientSound? {
        didSet {
            UserDefaults.standard.set(current?.rawValue, forKey: "ambientSound")
            transition(to: current)
        }
    }

    @Published var volume: Float {
        didSet {
            UserDefaults.standard.set(volume, forKey: "ambientVolume")
            mixer.outputVolume = volume
        }
    }

    private let engine = AVAudioEngine()
    private let mixer  = AVAudioMixerNode()
    private var node:   AVAudioSourceNode?

    init() {
        let savedRaw = UserDefaults.standard.string(forKey: "ambientSound")
        current = savedRaw.flatMap { AmbientSound(rawValue: $0) }

        let savedVol = UserDefaults.standard.float(forKey: "ambientVolume")
        volume = savedVol > 0 ? savedVol : 0.35

        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: nil)
        mixer.outputVolume = volume

        if let sound = current { transition(to: sound) }
    }

    /// Toggle: clicking the active sound turns it off.
    func select(_ sound: AmbientSound) {
        current = (current == sound) ? nil : sound
    }

    // MARK: - Private

    private func transition(to sound: AmbientSound?) {
        detachNode()
        guard let sound else {
            if engine.isRunning { engine.stop() }
            return
        }
        startEngineIfNeeded()
        let newNode = makeNode(for: sound)
        let format  = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        engine.attach(newNode)
        engine.connect(newNode, to: mixer, format: format)
        node = newNode
    }

    private func detachNode() {
        guard let n = node else { return }
        engine.detach(n)
        node = nil
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        try? engine.start()
    }

    // MARK: - Node Factories
    // Filter state is captured locally → no self capture, no data race.

    private func makeNode(for sound: AmbientSound) -> AVAudioSourceNode {
        switch sound {

        case .white:
            // Flat-spectrum white noise
            return AVAudioSourceNode { _, _, frameCount, audioBufferList in
                let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for i in 0..<Int(frameCount) {
                    let s = Float.random(in: -1...1) * 0.25
                    for buf in abl {
                        buf.mData?.assumingMemoryBound(to: Float.self)[i] = s
                    }
                }
                return noErr
            }

        case .rain:
            // Pink noise — Voss-McCartney 7-tap approximation
            var b = [Float](repeating: 0, count: 7)
            return AVAudioSourceNode { _, _, frameCount, audioBufferList in
                let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for i in 0..<Int(frameCount) {
                    let w  = Float.random(in: -1...1)
                    b[0]   = 0.99886 * b[0] + w * 0.0555179
                    b[1]   = 0.99332 * b[1] + w * 0.0750759
                    b[2]   = 0.96900 * b[2] + w * 0.1538520
                    b[3]   = 0.86650 * b[3] + w * 0.3104856
                    b[4]   = 0.55000 * b[4] + w * 0.5329522
                    b[5]   = -0.7616 * b[5] - w * 0.0168980
                    let pink = (b[0]+b[1]+b[2]+b[3]+b[4]+b[5]+b[6] + w * 0.5362) * 0.11
                    b[6]   = w * 0.115926
                    let s  = max(-0.5, min(0.5, pink * 0.8))
                    for buf in abl {
                        buf.mData?.assumingMemoryBound(to: Float.self)[i] = s
                    }
                }
                return noErr
            }

        case .lofi:
            // Brown noise — integrated white noise (warm, low-frequency rumble)
            var last: Float = 0
            return AVAudioSourceNode { _, _, frameCount, audioBufferList in
                let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for i in 0..<Int(frameCount) {
                    let w  = Float.random(in: -1...1)
                    last   = (last + 0.02 * w) / 1.02
                    let s  = max(-0.5, min(0.5, last * 3.5))
                    for buf in abl {
                        buf.mData?.assumingMemoryBound(to: Float.self)[i] = s
                    }
                }
                return noErr
            }
        }
    }
}
