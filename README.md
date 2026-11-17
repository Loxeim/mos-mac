# Marketing OS untuk Mac (v1.1)

Aplikasi Mac berjendela sendiri (WKWebView) yang langsung membuka MOS di PC IRFAN.
Dikompilasi di GitHub Actions, jadi di Mac tidak perlu Python, Command Line Tools, atau folder bersama.

## Cara build (sekali, ± 5 menit)
1. Buat repository baru di GitHub (boleh Private), mis. `mos-mac`.
2. Upload SEMUA isi folder ini (termasuk folder `.github` dan `aset`) → Commit changes.
   Tip: di halaman repo klik "uploading an existing file", seret semua file & folder.
   Kalau folder `.github` tidak ikut terseret (tersembunyi), buat manual:
   Add file → Create new file → nama `.github/workflows/build-mac.yml` → tempel isi file itu.
3. Buka tab **Actions** → "Build Marketing OS Mac" berjalan otomatis
   (atau klik **Run workflow**). Tunggu sampai centang hijau.
4. Klik run itu → bagian **Artifacts** → unduh `MarketingOS-Mac-1.1.x` (zip berisi .dmg).
5. Kirim .dmg ke Mac → buka → seret Marketing OS ke Applications → klik kanan → Open.

Alamat bawaan diatur di `aset/Info.plist` (kunci `MOSAlamat`). Bisa juga diganti di aplikasi:
menu Marketing OS → Alamat Server…
