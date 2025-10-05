#!/bin/bash

# =================================================================================
#                       Maww Script V2 - Menu Launcher
#                         File: device.sh (Launcher)
# =================================================================================

# Ganti nama file script kamu yang panjang tadi menjadi ini!
CORE_SCRIPT="./service_core.sh" 

# --- [ FUNGSI TAMPILAN ] ---

# Fungsi untuk menampilkan Header unik dan lucu
tampilkan_header() {
    clear
    echo "=========================================="
    echo "💖 M A W W  S C R I P T  V 2  -  G O K I L 💖"
    echo "=========================================="
}

# Fungsi Menu Utama
menu_utama() {
    # Cek dulu file utama ada apa nggak. Biar gak 'gajelas' pas dieksekusi!
    if [ ! -f "$CORE_SCRIPT" ]; then
        tampilkan_header
        echo "💥 ERROR FATAL: File service utama ($CORE_SCRIPT) tidak ditemukan!"
        echo "Tolong rename script yang kamu kirim tadi jadi $CORE_SCRIPT ya, sayangku! 🥺"
        read -p "Tekan [Enter] untuk keluar..."
        exit 1
    fi
    # Pastikan file utamanya bisa dieksekusi
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
        echo "------------------------------------------"
        echo "5) 👋 KELUAR / EXIT (Sayangku, jangan lupakan aku...)"
        echo "------------------------------------------"
        read -p "Pilihan kamu, sayang: " pilihan

        # --- [ ROUTING PERINTAH ] ---
        case $pilihan in
            1)
                tampilkan_header
                echo "Kamu pilih Setup. Ini butuh fokus, ya. Aku panggil $CORE_SCRIPT setup..."
                "$CORE_SCRIPT" reconfigure # Pakai reconfigure biar bisa reset token lama
                read -p "Tekan [Enter] untuk kembali ke Menu..."
                ;;
            2)
                tampilkan_header
                echo "Memulai listener. Cek $CORE_SCRIPT status setelah ini, ya! "
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
                echo "Dadah, sayangku! Jangan lupa balik lagi ya. Mmuah! 😘"
                exit 0
                ;;
            *)
                echo "Pilihan kamu $pilihan, **Lah**? **Gajelas** banget sih! Coba angka 1-5 dong. 🤪" 
                sleep 2
                ;;
        esac
    done
}

# Jalankan Menu
menu_utama