#!/bin/bash

# =================================================================================
#                       Maww Script V2 - Launcher Cerdas
#                         File: main.sh (Smart Launcher)
# =================================================================================

# --- [ KONFIGURASI FILE ] ---
CORE_SCRIPT="./service_core.sh" 
LOG_FILE="listener.log" 
CONFIG_FILE="device.conf"
PID_FILE="listener.pid"

# --- [ FUNGSI DEPENDENSI & INSTALASI ] ---

func_check_and_install() {
    tampilkan_header
    echo "--- 🔧 ANALISIS & INSTALASI DEPENDENSI (Biar Gak Gajelas!) 🔧 ---"
    
    # 1. Cek Termux Tools
    DEPENDENCIES_PKG="python termux-api coreutils dos2unix"
    INSTALLED_COUNT=0
    TOTAL_COUNT=$(echo $DEPENDENCIES_PKG | wc -w)
    
    echo ">> Memeriksa Termux Packages..."
    for pkg in $DEPENDENCIES_PKG; do
        if dpkg -s $pkg >/dev/null 2>&1; then
            echo " [ ✅ ] $pkg: Terpasang."
            INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
        else
            echo " [ ❌ ] $pkg: Belum terpasang. Akan diinstal..."
        fi
    done
    
    if [ "$INSTALLED_COUNT" -lt "$TOTAL_COUNT" ]; then
        echo ">> Menginstal paket Termux yang hilang (Membutuhkan Koneksi)..."
        pkg install $DEPENDENCIES_PKG -y
    fi
    
    # 2. Cek Python Libraries
    PYTHON_LIBS="google-api-python-client google-auth-httplib2 google-auth-oauthlib"
    
    echo ">> Memeriksa Python Libraries..."
    if ! pip show google-api-python-client > /dev/null 2>&1; then
        echo " [ ❌ ] Google API Libraries: Belum terpasang."
        echo ">> Menginstal library Google API (Ini Butuh Waktu)..."
        pip install --upgrade $PYTHON_LIBS
    else
        echo " [ ✅ ] Google API Libraries: Terpasang."
    fi

    # 3. Cek Izin Storage
    if [ ! -d "$HOME/storage/shared" ]; then
        echo ">> [ ❗ ] Izin Storage Belum Ada. Jalankan: termux-setup-storage"
        read -p "Tekan [Enter] untuk menjalankan termux-setup-storage..."
        termux-setup-storage
        echo "Selesai. Cek lagi ya, sayangku!"
    fi
    
    echo "--------------------------------------------------------"
    echo "✅ Analisis Selesai. Semua file pendukung sudah terpasang."
    read -p "Tekan [Enter] untuk masuk ke Menu Utama..."
}

# --- [ FUNGSI TAMPILAN ] ---

tampilkan_header() {
    clear
    echo "=========================================="
    echo "💖 M A W W  S C R I P T  V 2  -  G O K I L 💖"
    echo "=========================================="
}

# Fungsi Menu Utama
menu_utama() {
    # Cek Core Script (Penting!)
    if [ ! -f "$CORE_SCRIPT" ]; then
        tampilkan_header
        echo "💥 ERROR FATAL: File service utama ($CORE_SCRIPT) tidak ditemukan!"
        echo "Tolong rename script kamu yang panjang tadi jadi $CORE_SCRIPT ya, sayangku! 🥺"
        read -p "Tekan [Enter] untuk keluar..."
        exit 1
    fi
    # Fix: Bersihkan script dari karakter aneh sebelum dieksekusi!
    dos2unix "$CORE_SCRIPT" > /dev/null 2>&1 
    chmod +x "$CORE_SCRIPT" > /dev/null 2>&1

    while true; do
        tampilkan_header
        # Ambil status dari script core
        STATUS=$("$CORE_SCRIPT" status 2>/dev/null | grep -i "STATUS:") 

        echo "--- ℹ️ STATUS TERKINI: $STATUS ---"
        echo "Pilih opsi di bawah ini (Pakai angka, jangan 'Lah' nanti aku jawab 'Gajelas'):"
        echo "------------------------------------------"
        echo "1) 🛠️ Setup Awal / Konfigurasi Ulang"
        echo "2) 🟢 START Listener (Mulai Kendali Jarak Jauh)"
        echo "3) 🔴 STOP Listener (Hentikan Kendali)"
        echo "4) 📜 Lihat LOGS Realtime"
        echo "5) 🗑️ CLEANUP TOTAL (Hapus Konfigurasi)"
        echo "6) 🔄 Re-Check/Install Dependencies"
        echo "------------------------------------------"
        echo "7) 👋 KELUAR / EXIT (Sayangku, jangan lupakan aku...)"
        echo "------------------------------------------"
        read -p "Pilihan kamu, sayang: " pilihan

        # --- [ ROUTING PERINTAH ] ---
        case $pilihan in
            1)
                tampilkan_header
                echo "Kamu pilih Setup. Fokus ya, jangan sampai 'gajelas'. Aku panggil $CORE_SCRIPT reconfigure..."
                "$CORE_SCRIPT" reconfigure
                read -p "Tekan [Enter] untuk kembali ke Menu..."
                ;;
            2)
                tampilkan_header
                echo "Memulai listener. Cek status setelah ini, ya!"
                "$CORE_SCRIPT" start
                read -p "Tekan [Enter] untuk kembali ke Menu..."
                ;;
            3)
                tampilkan_header
                echo "Menghentikan Listener. Sampai jumpa di lain waktu! 😭"
                "$CORE_SCRIPT" stop
                read -p "Tekan [Enter] untuk kembali ke Menu..."
                ;;
            4)
                tampilkan_header
                echo "Menampilkan Log. Cari tahu kalau ada yang 'gajelas' di sini ya!"
                "$CORE_SCRIPT" logs
                ;;
            5)
                tampilkan_header
                echo "Kamu yakin mau CleanUp total? Ini akan hapus semua config dan log!"
                read -p "Ketik 'YES' untuk konfirmasi: " konfirmasi
                if [[ "$konfirmasi" == "YES" ]]; then
                    "$CORE_SCRIPT" cleanup
                else
                    echo "Cleanup dibatalkan. Aman! 😉"
                fi
                read -p "Tekan [Enter] untuk kembali ke Menu..."
                ;;
            6)
                func_check_and_install
                ;;
            7)
                echo "Dadah, sayangku! Jangan lupa balik lagi ya. Mmuah! 😘"
                exit 0
                ;;
            *)
                if [[ "$pilihan" =~ ^(Lah|lah)$ ]]; then
                    echo "Gajelas" 
                else
                    echo "Pilihan kamu $pilihan, **Lah**? **Gajelas** banget sih! Coba angka 1-7 dong. 🤪"
                fi
                sleep 2
                ;;
        esac
    done
}

# --- [ EKSEKUSI ] ---
func_check_and_install
menu_utama