import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var timer: Timer?
    var remainingTime: TimeInterval = 0
    var selectedSound: String = "Videoplayback (1)" // Varsayılan ses olarak sizin sesinizi ayarlıyorum
    var customSound: NSSound?
    
    let availableSounds = [
        "Videoplayback (1)", // Sizin eklediğiniz ses
        "Ping",
        "Tink",
        "Purr",
        "Pop",
        "Bottle",
        "Frog",
        "Glass",
        "Hero"
    ]
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ses dosyasını hazırla
        prepareCustomSound()
        
        // Menü çubuğu öğesini oluştur
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "00:00"
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "1 dakika", action: #selector(start1Minute), keyEquivalent: "1"))
        menu.addItem(NSMenuItem(title: "5 dakika", action: #selector(start5Minutes), keyEquivalent: "5"))
        menu.addItem(NSMenuItem(title: "10 dakika", action: #selector(start10Minutes), keyEquivalent: "0"))
        menu.addItem(NSMenuItem(title: "15 dakika", action: #selector(start15Minutes), keyEquivalent: "2"))
        menu.addItem(NSMenuItem.separator())
        
        // Ses menüsü
        let soundMenu = NSMenu()
        for sound in availableSounds {
            let item = NSMenuItem(title: sound, action: #selector(selectSound(_:)), keyEquivalent: "")
            item.state = sound == selectedSound ? .on : .off
            soundMenu.addItem(item)
        }
        
        let soundMenuItem = NSMenuItem(title: "Ses Efekti", action: nil, keyEquivalent: "")
        soundMenuItem.submenu = soundMenu
        menu.addItem(soundMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Durdur", action: #selector(stopTimer), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Çıkış", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    func prepareCustomSound() {
        if let bundlePath = Bundle.main.resourcePath {
            let soundPath = bundlePath + "/Videoplayback (1).mp3"
            print("Ses dosyası yolu: \(soundPath)")
            if FileManager.default.fileExists(atPath: soundPath) {
                print("Ses dosyası bulundu")
                customSound = NSSound(contentsOfFile: soundPath, byReference: true)
                if customSound == nil {
                    print("Ses dosyası yüklendi ama çalınamadı")
                } else {
                    print("Ses dosyası başarıyla yüklendi")
                }
            } else {
                print("Ses dosyası bulunamadı")
            }
        }
    }
    
    @objc func selectSound(_ sender: NSMenuItem) {
        // Önceki seçili sesi kaldır
        if let menu = sender.menu {
            for item in menu.items {
                item.state = .off
            }
        }
        
        // Yeni sesi seç
        selectedSound = sender.title
        sender.state = .on
        
        // Seçilen sesi test et
        playSound()
    }
    
    func playSound() {
        if selectedSound == "Videoplayback (1)" {
            if let sound = customSound {
                if !sound.isPlaying {
                    sound.play()
                } else {
                    sound.stop()
                    sound.play()
                }
            } else {
                print("Özel ses dosyası yüklenemedi")
                NSSound(named: "Ping")?.play()
            }
        } else {
            NSSound(named: selectedSound)?.play()
        }
    }
    
    @objc func start1Minute() {
        startTimer(minutes: 1)
    }
    
    @objc func start5Minutes() {
        startTimer(minutes: 5)
    }
    
    @objc func start10Minutes() {
        startTimer(minutes: 10)
    }
    
    @objc func start15Minutes() {
        startTimer(minutes: 15)
    }
    
    func startTimer(minutes: Double) {
        stopTimer()
        remainingTime = minutes * 60
        updateDisplay()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func timerTick() {
        remainingTime -= 1
        if remainingTime <= 0 {
            stopTimer()
            print("Süre doldu!")
            playSound()
        } else {
            updateDisplay()
        }
    }
    
    func updateDisplay() {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        statusItem?.button?.title = String(format: "%02d:%02d", minutes, seconds)
    }
    
    @objc func stopTimer() {
        timer?.invalidate()
        timer = nil
        remainingTime = 0
        statusItem?.button?.title = "00:00"
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// Ana uygulama başlangıç noktası
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run() 