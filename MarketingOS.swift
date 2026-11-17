// Marketing OS untuk Mac ( v1.1 ) — aplikasi jendela sendiri ( WKWebView bawaan macOS ).
// Sudah dikompilasi di GitHub Actions → di Mac TIDAK perlu Python, Command Line Tools, atau folder bersama.
// Langsung membuka MOS di PC IRFAN ( alamat online ). Alamat bisa diganti: menu Marketing OS → Alamat Server…
import Cocoa
import WebKit

let argumen = CommandLine.arguments
if argumen.count > 1 && argumen[1] == "--cek" { print("ok"); exit(0) }
let alamatBawaan = (Bundle.main.object(forInfoDictionaryKey: "MOSAlamat") as? String) ?? "https://irfan.tail088aa1.ts.net/"
let kunciAlamat = "alamatServer"
func alamatTersimpan() -> URL {
    if argumen.count > 1, let u = URL(string: argumen[1]), u.scheme?.hasPrefix("http") == true { return u }
    let s = UserDefaults.standard.string(forKey: kunciAlamat) ?? alamatBawaan
    return URL(string: s) ?? URL(string: alamatBawaan)!
}
var alamatAwal = alamatTersimpan()

// window.print() tidak berjalan di WKWebView → dialihkan ke perintah cetak macOS
let skripCetak = "window.print = function () { try { window.webkit.messageHandlers.mosCetak.postMessage(1); } catch (e) {} };"

final class Aplikasi: NSObject, NSApplicationDelegate, NSWindowDelegate, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    var jendelaUtama: NSWindow!
    var webUtama: WKWebView!
    var jendelaLain: [NSWindow] = []
    var pengunduh: AnyObject?

    func applicationDidFinishLaunching(_ n: Notification) {
        // ikon Dock diambil langsung dari berkas ikon aplikasi ( tidak bergantung cache ikon macOS )
        let jalurIkon = Bundle.main.path(forResource: "AppIcon", ofType: "icns") ?? ""
        if !jalurIkon.isEmpty, let gambar = NSImage(contentsOfFile: jalurIkon) { NSApp.applicationIconImage = gambar }
        buatMenu()
        let conf = WKWebViewConfiguration()
        conf.websiteDataStore = WKWebsiteDataStore.default()
        conf.preferences.javaScriptCanOpenWindowsAutomatically = true
        conf.mediaTypesRequiringUserActionForPlayback = []          // alarm / suara MOS boleh langsung bunyi
        conf.userContentController.add(self, name: "mosCetak")
        conf.userContentController.add(self, name: "mosAlamat")
        conf.userContentController.addUserScript(WKUserScript(source: skripCetak, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        webUtama = buatWeb(conf)

        let layar = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let w = min(1440, layar.width * 0.92), h = min(940, layar.height * 0.92)
        jendelaUtama = NSWindow(contentRect: NSRect(x: layar.midX - w / 2, y: layar.midY - h / 2, width: w, height: h),
                                styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        jendelaUtama.title = "Marketing OS"
        jendelaUtama.minSize = NSSize(width: 380, height: 500)
        jendelaUtama.contentView = webUtama
        jendelaUtama.delegate = self
        jendelaUtama.setFrameAutosaveName("MarketingOSJendelaUtama")
        jendelaUtama.makeKeyAndOrderFront(nil)
        webUtama.load(URLRequest(url: alamatAwal))
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { return true }

    func windowWillClose(_ n: Notification) {
        if let j = n.object as? NSWindow, j !== jendelaUtama { jendelaLain.removeAll { $0 === j } }
    }

    func buatWeb(_ conf: WKWebViewConfiguration) -> WKWebView {
        let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 1200, height: 800), configuration: conf)
        web.uiDelegate = self
        web.navigationDelegate = self
        web.allowsMagnification = true
        if #available(macOS 13.3, *) { web.isInspectable = true }
        return web
    }

    // ---------- menu ( Salin / Tempel / Keluar / Muat ulang ) ----------
    func buatMenu() {
        let utama = NSMenu()
        func sub(_ judul: String, _ isi: [NSMenuItem]) {
            let item = NSMenuItem(title: judul, action: nil, keyEquivalent: "")
            let m = NSMenu(title: judul)
            isi.forEach { m.addItem($0) }
            item.submenu = m
            utama.addItem(item)
        }
        func i(_ t: String, _ a: Selector?, _ k: String, _ mod: NSEvent.ModifierFlags = [.command]) -> NSMenuItem {
            let x = NSMenuItem(title: t, action: a, keyEquivalent: k)
            x.keyEquivalentModifierMask = mod
            return x
        }
        let alamat = i("Alamat Server…", #selector(gantiAlamat), ","); alamat.target = self
        let browser = i("Buka di Browser", #selector(bukaDiBrowser), "b", [.command, .shift]); browser.target = self
        sub("Marketing OS", [
            alamat, browser, NSMenuItem.separator(),
            i("Sembunyikan Marketing OS", #selector(NSApplication.hide(_:)), "h"),
            NSMenuItem.separator(),
            i("Keluar dari Marketing OS", #selector(NSApplication.terminate(_:)), "q"),
        ])
        sub("Edit", [
            i("Urungkan", Selector(("undo:")), "z"),
            i("Ulangi", Selector(("redo:")), "z", [.command, .shift]),
            NSMenuItem.separator(),
            i("Potong", #selector(NSText.cut(_:)), "x"),
            i("Salin", #selector(NSText.copy(_:)), "c"),
            i("Tempel", #selector(NSText.paste(_:)), "v"),
            i("Pilih Semua", #selector(NSText.selectAll(_:)), "a"),
        ])
        let muat = i("Muat Ulang", #selector(muatUlang), "r"); muat.target = self
        let besar = i("Perbesar", #selector(perbesar), "+"); besar.target = self
        let besar2 = i("Perbesar", #selector(perbesar), "="); besar2.target = self; besar2.isHidden = true; besar2.allowsKeyEquivalentWhenHidden = true
        let kecil = i("Perkecil", #selector(perkecil), "-"); kecil.target = self
        let asli = i("Ukuran Asli", #selector(ukuranAsli), "0"); asli.target = self
        let cetak = i("Cetak…", #selector(cetakMenu), "p"); cetak.target = self
        sub("Tampilan", [muat, NSMenuItem.separator(), besar, besar2, kecil, asli, NSMenuItem.separator(), cetak])
        sub("Jendela", [
            i("Kecilkan", #selector(NSWindow.performMiniaturize(_:)), "m"),
            i("Tutup", #selector(NSWindow.performClose(_:)), "w"),
        ])
        NSApp.mainMenu = utama
    }

    var webAktif: WKWebView? { return (NSApp.keyWindow?.contentView as? WKWebView) ?? webUtama }
    @objc func muatUlang() { webAktif?.reload() }
    @objc func perbesar() { if let w = webAktif { w.magnification = min(3, w.magnification + 0.1) } }
    @objc func perkecil() { if let w = webAktif { w.magnification = max(0.5, w.magnification - 0.1) } }
    @objc func ukuranAsli() { webAktif?.magnification = 1 }
    @objc func cetakMenu() { if let w = webAktif { cetak(w) } }
    @objc func bukaDiBrowser() { NSWorkspace.shared.open(webAktif?.url ?? alamatAwal) }

    /** Ganti alamat server MOS ( mis. alamat LAN http://192.168.1.10:5181/ saat di kantor ). */
    @objc func gantiAlamat() {
        let a = NSAlert()
        a.messageText = "Alamat server Marketing OS"
        a.informativeText = "Bawaan: \(alamatBawaan)\nBisa diganti ke alamat lain, mis. http://192.168.1.10:5181/ di jaringan kantor. Kosongkan untuk kembali ke bawaan."
        a.addButton(withTitle: "Simpan & Buka"); a.addButton(withTitle: "Batal")
        let isian = NSTextField(frame: NSRect(x: 0, y: 0, width: 340, height: 24))
        isian.stringValue = alamatAwal.absoluteString
        a.accessoryView = isian
        a.window.initialFirstResponder = isian
        guard a.runModal() == .alertFirstButtonReturn else { return }
        var teks = isian.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if teks.isEmpty {
            UserDefaults.standard.removeObject(forKey: kunciAlamat)
            teks = alamatBawaan
        } else {
            if !teks.lowercased().hasPrefix("http") { teks = "http://" + teks }
            if !teks.hasSuffix("/") { teks += "/" }
            UserDefaults.standard.set(teks, forKey: kunciAlamat)
        }
        if let u = URL(string: teks) { alamatAwal = u; webUtama.load(URLRequest(url: u)) }
    }

    // ---------- cetak ----------
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        if m.name == "mosCetak", let w = m.webView { cetak(w) }
        if m.name == "mosAlamat" { gantiAlamat() }
    }

    func cetak(_ w: WKWebView) {
        guard #available(macOS 11.0, *) else { return }
        let info = NSPrintInfo.shared
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        info.isHorizontallyCentered = true
        info.isVerticallyCentered = false
        let op = w.printOperation(with: info)
        op.view?.frame = w.bounds
        if let j = w.window { op.runModal(for: j, delegate: nil, didRun: nil, contextInfo: nil) } else { op.run() }
    }

    // ---------- alert / confirm / prompt ----------
    func lembar(_ w: WKWebView) -> NSWindow? { return w.window ?? jendelaUtama }

    func webView(_ w: WKWebView, runJavaScriptAlertPanelWithMessage pesan: String, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let a = NSAlert(); a.messageText = "Marketing OS"; a.informativeText = pesan; a.addButton(withTitle: "OK")
        if let j = lembar(w) { a.beginSheetModal(for: j) { _ in completionHandler() } } else { a.runModal(); completionHandler() }
    }

    func webView(_ w: WKWebView, runJavaScriptConfirmPanelWithMessage pesan: String, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let a = NSAlert(); a.messageText = "Marketing OS"; a.informativeText = pesan
        a.addButton(withTitle: "OK"); a.addButton(withTitle: "Batal")
        if let j = lembar(w) { a.beginSheetModal(for: j) { r in completionHandler(r == .alertFirstButtonReturn) } } else { completionHandler(a.runModal() == .alertFirstButtonReturn) }
    }

    func webView(_ w: WKWebView, runJavaScriptTextInputPanelWithPrompt pesan: String, defaultText: String?, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let a = NSAlert(); a.messageText = "Marketing OS"; a.informativeText = pesan
        a.addButton(withTitle: "OK"); a.addButton(withTitle: "Batal")
        let isian = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24)); isian.stringValue = defaultText ?? ""
        a.accessoryView = isian
        if let j = lembar(w) {
            a.beginSheetModal(for: j) { r in completionHandler(r == .alertFirstButtonReturn ? isian.stringValue : nil) }
            a.window.initialFirstResponder = isian
        } else { completionHandler(a.runModal() == .alertFirstButtonReturn ? isian.stringValue : nil) }
    }

    // ---------- kamera / mikrofon ( scan barcode, rekam suara ) — izinkan untuk server MOS ----------
    @available(macOS 12.0, *)
    func webView(_ w: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame f: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(origin.host == alamatAwal.host ? .grant : .prompt)
    }

    // ---------- unggah berkas ( <input type=file> ) ----------
    func webView(_ w: WKWebView, runOpenPanelWith p: WKOpenPanelParameters, initiatedByFrame f: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let o = NSOpenPanel()
        o.allowsMultipleSelection = p.allowsMultipleSelection
        o.canChooseFiles = true
        if #available(macOS 10.13.4, *) { o.canChooseDirectories = p.allowsDirectories }
        if let j = lembar(w) { o.beginSheetModal(for: j) { r in completionHandler(r == .OK ? o.urls : nil) } } else { completionHandler(o.runModal() == .OK ? o.urls : nil) }
    }

    // ---------- jendela baru ( target=_blank / window.open ) ----------
    func webView(_ w: WKWebView, createWebViewWith conf: WKWebViewConfiguration, for aksi: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let u = aksi.request.url, let s = u.scheme?.lowercased(), (s == "http" || s == "https"), u.host != alamatAwal.host {
            NSWorkspace.shared.open(u)             // situs luar ( WhatsApp, Shopee, … ) → browser biasa
            return nil
        }
        let anak = buatWeb(conf)
        let j = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 760), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        j.title = "Marketing OS"
        j.contentView = anak
        j.delegate = self
        j.isReleasedWhenClosed = false
        j.cascadeTopLeft(from: NSPoint(x: jendelaUtama.frame.minX + 30, y: jendelaUtama.frame.maxY - 30))
        j.makeKeyAndOrderFront(nil)
        jendelaLain.append(j)
        return anak
    }

    func webViewDidClose(_ w: WKWebView) {
        if let j = w.window, j !== jendelaUtama { j.close() }
    }

    func webView(_ w: WKWebView, didFinish nav: WKNavigation!) {
        if let t = w.title, !t.isEmpty, let j = w.window, j !== jendelaUtama { j.title = t }
    }

    // ---------- tautan & unduhan ----------
    func webView(_ w: WKWebView, decidePolicyFor aksi: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if #available(macOS 11.3, *), aksi.shouldPerformDownload { decisionHandler(.download); return }
        if let u = aksi.request.url, let s = u.scheme?.lowercased() {
            if s == "mailto" || s == "tel" || s == "whatsapp" { NSWorkspace.shared.open(u); decisionHandler(.cancel); return }
            if (s == "http" || s == "https") && u.host != alamatAwal.host && aksi.targetFrame?.isMainFrame == true && aksi.navigationType == .linkActivated {
                NSWorkspace.shared.open(u); decisionHandler(.cancel); return
            }
        }
        decisionHandler(.allow)
    }

    func webView(_ w: WKWebView, decidePolicyFor resp: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if #available(macOS 11.3, *) {
            let lampiran = ((resp.response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Disposition") ?? "").lowercased().contains("attachment")
            if lampiran || !resp.canShowMIMEType { decisionHandler(.download); return }
        }
        decisionHandler(.allow)
    }

    @available(macOS 11.3, *)
    func webView(_ w: WKWebView, navigationAction: WKNavigationAction, didBecome d: WKDownload) { pasangUnduhan(d) }

    @available(macOS 11.3, *)
    func webView(_ w: WKWebView, navigationResponse: WKNavigationResponse, didBecome d: WKDownload) { pasangUnduhan(d) }

    @available(macOS 11.3, *)
    func pasangUnduhan(_ d: WKDownload) {
        let p = (pengunduh as? Pengunduh) ?? Pengunduh()
        pengunduh = p
        d.delegate = p
    }

    func webView(_ w: WKWebView, didFailProvisionalNavigation nav: WKNavigation!, withError e: Error) { halamanGagal(w, e) }

    func halamanGagal(_ w: WKWebView, _ e: Error) {
        let kode = (e as NSError).code
        if kode == NSURLErrorCancelled || kode == 102 { return }       // 102 = dialihkan ke unduhan
        guard w === webUtama else { return }
        let html = """
        <html><body style="font:15px -apple-system,sans-serif;display:flex;align-items:center;justify-content:center;height:90vh;background:#eef2ff">
        <div style="max-width:420px;background:#fff;padding:24px;border-radius:14px;box-shadow:0 10px 30px rgba(15,23,42,.12)">
        <b style="font-size:17px">Marketing OS belum bisa dibuka</b>
        <p style="color:#475569">Pastikan Mac tersambung internet dan PC IRFAN ( server MOS ) menyala.<br><small>Alamat: \(alamatAwal.absoluteString)<br>\(e.localizedDescription)</small></p>
        <button onclick="location.href='\(alamatAwal.absoluteString)'" style="width:100%;padding:12px;border:0;border-radius:10px;background:#2563eb;color:#fff;font-weight:700;font-size:15px">Coba lagi</button>
        <button onclick="window.webkit.messageHandlers.mosAlamat.postMessage(1)" style="width:100%;margin-top:8px;padding:10px;border:1px solid #cbd5e1;border-radius:10px;background:#fff;color:#0f172a;font-size:14px">Ganti alamat server…</button>
        </div></body></html>
        """
        w.loadHTMLString(html, baseURL: nil)
    }
}

@available(macOS 11.3, *)
final class Pengunduh: NSObject, WKDownloadDelegate {
    var tujuan: [ObjectIdentifier: URL] = [:]

    func download(_ d: WKDownload, decideDestinationUsing r: URLResponse, suggestedFilename nama: String, completionHandler: @escaping (URL?) -> Void) {
        let folder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory())
        let bersih = nama.isEmpty ? "unduhan" : nama.replacingOccurrences(of: "/", with: "-")
        var url = folder.appendingPathComponent(bersih)
        let dasar = url.deletingPathExtension().lastPathComponent, ext = url.pathExtension
        var n = 1
        while FileManager.default.fileExists(atPath: url.path) {
            url = folder.appendingPathComponent(ext.isEmpty ? "\(dasar) (\(n))" : "\(dasar) (\(n)).\(ext)")
            n += 1
        }
        tujuan[ObjectIdentifier(d)] = url
        completionHandler(url)
    }

    func downloadDidFinish(_ d: WKDownload) {
        if let u = tujuan.removeValue(forKey: ObjectIdentifier(d)) { NSWorkspace.shared.activateFileViewerSelecting([u]) }
    }

    func download(_ d: WKDownload, didFailWithError e: Error, resumeData: Data?) {
        tujuan.removeValue(forKey: ObjectIdentifier(d))
        let a = NSAlert(); a.messageText = "Unduhan gagal"; a.informativeText = e.localizedDescription; a.runModal()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let pengendali = Aplikasi()
app.delegate = pengendali
app.run()
