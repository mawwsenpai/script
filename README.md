# Moding Script by mawwsenpai_

Kumpulan script `bash` yang dirancang untuk mempermudah alur kerja _reverse engineering_ dan modifikasi aplikasi Android, langsung dari kenyamanan terminal Termux.

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Termux%20%7C%20Linux-brightgreen.svg)

---

## 🌟 Tentang Proyek Ini

Proyek ini lahir dari kebutuhan untuk mengotomatiskan tugas-tugas yang berulang dalam proses modding APK. Daripada mengetik perintah yang sama berulang kali, _toolkit_ ini menyediakan serangkaian script yang saling melengkapi untuk mempercepat proses dari awal hingga akhir.

## ✨ Fitur Unggulan

* **Alur Kerja Lengkap**: Dari dekompilasi, modifikasi, rebuild, hingga signing.
* **Asisten AI Lokal**: Fitur cerdas berbasis pola untuk membantu menemukan dan mem-patch logika umum seperti iklan atau status premium.
* **Integrasi Gemini (Opsional)**: Kemampuan untuk "berkonsultasi" dengan Google Gemini API untuk mendapatkan penjelasan mendalam tentang kode Smali yang rumit.
* **Modular & Terorganisir**: Setiap script memiliki fungsi spesifik, membuatnya mudah untuk dipahami dan dimodifikasi.
* **Pencarian Cerdas**: Script utama dapat secara otomatis menemukan file APK di direktori umum.

## ⚙️ Prasyarat

Sebelum menggunakan _toolkit_ ini, pastikan Termux Anda sudah dilengkapi dengan:
* `java` (OpenJDK 17 direkomendasikan)
* `git`
* `xmllint` (`pkg install libxml2-utils`)
* `jq` (Dibutuhkan untuk fitur AI Gemini)
* **Akses Root** (Dibutuhkan untuk `cheat.sh`)

## 🚀 Instalasi & Setup

1.  **Clone repository ini:**
    ```bash
    git clone [https://github.com/Mawwsenpai/script.git](https://github.com/Mawwsenpai/script.git)
    ```
2.  **Masuk ke direktori:**
    ```bash
    cd script
    ```
3.  **Beri izin eksekusi ke semua script:**
    ```bash
    chmod +x *.sh
    ```
4.  **Jalankan script setup (jika perlu):**
    ```bash
    bash install-java.sh
    bash install-apktool.sh
    ```

---

## 📜 Deskripsi Script

Berikut adalah penjelasan untuk setiap script di dalam _toolkit_ ini:

### 🚀 main.sh
- **Fungsi**: Script utama atau "launcher" untuk mengakses semua fitur. Ini adalah titik awal dari semua operasi.
- **Cara Pakai**: Jalankan `bash main.sh` untuk memulai.

### 🔧 mod-apk.sh
- **Fungsi**: Inti dari _toolkit_ ini. Menyediakan alur kerja lengkap untuk membongkar, memodifikasi, dan merakit kembali APK. Dilengkapi dengan berbagai menu bantuan, termasuk Asisten AI.
- **Cara Pakai**: Bisa dijalankan langsung dengan `bash mod-apk.sh` atau melalui `main.sh`.

### ✍️ sign-apk.sh
- **Fungsi**: Script khusus untuk menandatangani (signing) file APK yang sudah berhasil di-rebuild. Tanpa ini, APK modifikasi tidak akan bisa di-install.
- **Cara Pakai**: Biasanya dipanggil secara otomatis oleh `mod-apk.sh`, tapi bisa juga digunakan manual: `bash sign-apk.sh namafile.apk`.

### 🔨 build-apk.sh
- **Fungsi**: Jalan pintas untuk merakit kembali (rebuild) sebuah folder proyek yang sudah dimodifikasi menjadi file `.apk`.
- **Cara Pakai**: `bash build-apk.sh /path/ke/folder/proyek`.

### 🕹️ cheat.sh
- **Fungsi**: Konsep dasar buat nge-cheat game offline di Android dengan cara ngoprek memori.
- **Peringatan**: BUTUH AKSES ROOT! Jangan ngeyel kalo gagal.
- **Cara Pakai**: Jalankan `bash cheat.sh`. Baca kode script-nya biar lebih detail!

### 📂 organizer.sh
- **Fungsi**: Script utilitas untuk membantu merapikan file-file kerja atau hasil modifikasi di dalam direktori proyek.
- **Cara Pakai**: `bash organizer.sh`.

### 🛠️ install-java.sh & install-apktool.sh
- **Fungsi**: Script pembantu untuk mengunduh dan meng-install dependensi utama seperti Java (OpenJDK) dan `apktool.jar` terbaru.
- **Cara Pakai**: Jalankan di awal setup jika Anda belum memiliki dependensi tersebut.

### ✅ permission-check.sh
- **Fungsi**: Script sederhana untuk memeriksa dan memperbaiki izin (permission) file di dalam direktori kerja, memastikan semua script bisa dieksekusi.
- **Cara Pakai**: `bash permission-check.sh`.

### 📄 LICENSE
- **Fungsi**: File lisensi (MIT License). Memberitahu orang lain bahwa mereka bebas menggunakan, memodifikasi, dan mendistribusikan ulang script ini.

---

## ⚠️ Peringatan & Penafian

* **Gunakan dengan Risiko Anda Sendiri**: Script ini adalah alat yang kuat. Kerusakan pada aplikasi atau perangkat Anda bukan tanggung jawab pengembang.
* **Tujuan Edukasi**: _Toolkit_ ini dibuat untuk tujuan pembelajaran dan riset keamanan.
* **Patuhi Hukum**: Jangan menggunakan alat ini untuk membajak, merusak, atau melakukan aktivitas ilegal lainnya yang melanggar hak cipta dan persyaratan layanan aplikasi.

