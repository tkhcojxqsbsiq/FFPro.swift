
import SwiftUI
import NetworkExtension

// MARK: - APP ENTRY
@main
struct FFProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - STATE
class AppState: ObservableObject {
    @Published var aimlock = false
    @Published var aimbot = false
    @Published var autoFire = false
    @Published var fakeGPS = false
    @Published var bulletStraight = false
    @Published var antiBan = true
    @Published var sensitivity: Double = 2.0
    @Published var fov: Double = 130.0
    @Published var bone = 0
    @Published var fakeLat = "10.8231"
    @Published var fakeLon = "106.6297"
    @Published var vpnStatus = "Chưa kết nối"
    
    let suite = UserDefaults(suiteName: "group.com.tenban.FFPro")
    
    func save() {
        suite?.set([
            "lock":aimlock, "bot":aimbot, "fire":autoFire,
            "gps":fakeGPS, "bullet":bulletStraight, "ban":antiBan,
            "sens":sensitivity, "fov":fov, "bone":bone,
            "lat":fakeLat, "lon":fakeLon
        ], forKey: "cfg")
    }
    func load() {
        guard let d = suite?.dictionary(forKey: "cfg") else { return }
        aimlock = d["lock"] as? Bool ?? false
        aimbot = d["bot"] as? Bool ?? false
        autoFire = d["fire"] as? Bool ?? false
        fakeGPS = d["gps"] as? Bool ?? false
        bulletStraight = d["bullet"] as? Bool ?? false
        antiBan = d["ban"] as? Bool ?? true
        sensitivity = d["sens"] as? Double ?? 2.0
        fov = d["fov"] as? Double ?? 130.0
        bone = d["bone"] as? Int ?? 0
        fakeLat = d["lat"] as? String ?? "10.8231"
        fakeLon = d["lon"] as? String ?? "106.6297"
    }
}

// MARK: - VIEW
struct ContentView: View {
    @StateObject var s = AppState()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    Text("🔥 FF PRO MENU")
                        .font(.system(size: 26, weight: .black))
                        .foregroundColor(.red)
                    Text("OB54 • Mở là chơi • Không key")
                        .font(.caption).foregroundColor(.gray)
                    
                    Card("🔒 AIMLOCK") {
                        Toggle("Bật Aimlock", isOn: $s.aimlock).tint(.red)
                        HStack { Text("Nhạy:").foregroundColor(.gray); Slider(value: $s.sensitivity, in: 0.5...5).tint(.red) }
                        HStack { Text("FOV:").foregroundColor(.gray); Slider(value: $s.fov, in: 30...360).tint(.red) }
                        Picker("Xương", selection: $s.bone) {
                            Text("Đầu").tag(0); Text("Ngực").tag(1); Text("Cổ").tag(2)
                        }.pickerStyle(.segmented)
                    }
                    
                    Card("🎯 AIMBOT") {
                        Toggle("Bật Aimbot", isOn: $s.aimbot).tint(.red)
                        Toggle("Tự động bắn", isOn: $s.autoFire).tint(.orange)
                    }
                    
                    Card("💥 ĐẠN THẲNG") {
                        Toggle("Bật Đạn Thẳng", isOn: $s.bulletStraight).tint(.yellow)
                        Text("Đạn bay thẳng, không tản").font(.caption).foregroundColor(.gray)
                    }
                    
                    Card("📍 GPS GIẢ") {
                        Toggle("Bật GPS giả", isOn: $s.fakeGPS).tint(.blue)
                        HStack { Text("Lat:").foregroundColor(.gray); TextField("10.8231", text: $s.fakeLat).keyboardType(.decimalPad) }
                        HStack { Text("Lon:").foregroundColor(.gray); TextField("106.6297", text: $s.fakeLon).keyboardType(.decimalPad) }
                    }
                    
                    Card("🛡️ ANTI-BAN") {
                        Toggle("Bật Anti-Ban", isOn: $s.antiBan).tint(.green)
                    }
                    
                    Button(s.vpnStatus == "Đã kết nối" ? "🔴 NGẮT VPN" : "🟢 KẾT NỐI VPN") {
                        if s.vpnStatus == "Đã kết nối" { stopVPN() } else { startVPN() }
                    }.buttonStyle(.borderedProminent).tint(s.vpnStatus == "Đã kết nối" ? .red : .green)
                    
                    Text(s.vpnStatus).font(.caption).foregroundColor(.gray)
                    
                    Button("💾 LƯU CẤU HÌNH") { s.save() }.buttonStyle(.borderedProminent).tint(.blue)
                }.padding()
            }
        }.onAppear { s.load() }
    }
    
    func startVPN() {
        let m = NETunnelProviderManager()
        m.loadFromPreferences { _ in
            let p = NETunnelProviderProtocol()
            p.providerBundleIdentifier = "com.tenban.FFPro.FFTunnel"
            p.serverAddress = "FF"
            m.protocolConfiguration = p; m.isEnabled = true
            m.saveToPreferences { e in
                if e == nil { try? m.connection.startVPNTunnel(); s.vpnStatus = "Đã kết nối" }
            }
        }
    }
    func stopVPN() {
        NETunnelProviderManager.loadAllFromPreferences { mgrs, _ in
            mgrs?.first?.connection.stopVPNTunnel(); s.vpnStatus = "Chưa kết nối"
        }
    }
}

struct Card<Content: View>: View {
    let title: String; @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 😎 {
            Text(title).font(.headline).foregroundColor(.white)
            content()
        }.padding().background(Color.white.opacity(0.05)).cornerRadius(14)
    }
}

// MARK: - VPN EXTENSION (AIMBOT + AIMLOCK + GPS + BULLET STRAIGHT)
class PacketTunnelProvider: NEPacketTunnelProvider {
    var cfg: [String:Any] {
        UserDefaults(suiteName: "group.com.tenban.FFPro")?.dictionary(forKey: "cfg") ?? [:]
    }
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let s = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.9.0.1")
        s.mtu = 1400
        let ip = NEIPv4Settings(addresses: ["10.9.0.2"], subnetMasks: ["255.255.255.0"])
        ip.includedRoutes = [NEIPv4Route.default()]
        s.ipv4Settings = ip
        setTunnelNetworkSettings(s) { e in
            if let e = e { completionHandler(e); return }
            self.loop(); completionHandler(nil)
        }
    }
    
    func loop() {
        packetFlow.readPackets { [weak self] pkts, protos in
            guard let s = self else { return }
            s.packetFlow.writePackets(s.process(pkts), withProtocols: protos)
            s.loop()
        }
    }
    
    func process(_ packets: [Data]) -> [Data] {
        let lock = cfg["lock"] as? Bool ?? false
        let bot = cfg["bot"] as? Bool ?? false
        let gps = cfg["gps"] as? Bool ?? false
        let bullet = cfg["bullet"] as? Bool ?? false
        let ban = cfg["ban"] as? Bool ?? true
        let sens = cfg["sens"] as? Double ?? 2.0
        let bone = cfg["bone"] as? Int ?? 0
        let lat = Double(cfg["lat"] as? String ?? "10.8231") ?? 10.8231
        let lon = Double(cfg["lon"] as? String ?? "106.6297") ?? 106.6297
        
        let boneY: Float = bone == 0 ? -26 : (bone == 2 ? -18 : -5)
        let factor = Float(1.0 / sens)
        
        return packets.map { p in
            guard p.count > 40 else { return p }
            var b = [UInt8](p)
            
            // AIMLOCK + AIMBOT
            if lock || bot {
                for i in 0..<(b.count - 28) {
                    if b[i] == 0xAB && b[i+1] == 0xCD {
                        var pos = i + 2
                        if pos + 4 > b.count { break }
                        let cnt = min(Int(b[pos])|(Int(b[pos+1])<<8)|(Int(b[pos+2])<<16)|(Int(b[pos+3])<<24), 15)
                        pos += 4
                        for _ in 0..<cnt {
                            if pos + 22 > b.count { break }
                            if b[pos+17] == 0 && b[pos+16] > 0 && b[pos+16] <= 100 {
                                let n: Float = ban ? Float.random(in: -0.02...0.02) : 0
                                for off in [4, 8, 12] {
                                    var v: Float = 0
                                    _ = withUnsafeMutableBytes(&v) { $0.copyBytes(from: b[(pos+off)..<(pos+off+4)]) }
                                    if off == 8 { v += boneY }
                                    v = v * factor + n * v
                                    withUnsafeBytes(of: &v) { ptr in
                                        for j in 0..<4 { if pos+off+j < b.count { b[pos+off+j] = ptr[j] } }
                                    }
                                }
                            }
                            pos += 22
                        }
                        break
                    }
                }
            }
            
            // ĐẠN THẲNG
            if bullet {
                for i in 0..<(b.count - 16) {
                    if b[i] == 0x42 && b[i+1] == 0x55 && b[i+2] == 0x4C { // "BUL"
                        for off in [4, 8, 12] {
                            var v: Float = 0
                            _ = withUnsafeMutableBytes(&v) { $0.copyBytes(from: b[(i+off)..<(i+off+4)]) }
                            v = 0 // Zero out bullet spread
                            withUnsafeBytes(of: &v) { ptr in
                                for j in 0..<4 { if i+off+j < b.count { b[i+off+j] = ptr[j] } }
                            }
                        }
                        break
                    }
                }
            }
            
            // GPS GIẢ
            if gps {
                let latB = withUnsafeBytes(of: Float(lat)) { Array($0) }
                let lonB = withUnsafeBytes(of: Float(lon)) { Array($0) }
                for i in 0..<(b.count - 😎 {
                    if b[i] == 0x47 && b[i+1] == 0x50 && b[i+2] == 0x53 {
                        for j in 0..<4 {
                            if i+4+j < b.count { b[i+4+j] = latB[j] }
                            if i+8+j < b.count { b[i+8+j] = lonB[j] }
                        }
                        break
                    }
                }
            }
            
            return Data(b)
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}