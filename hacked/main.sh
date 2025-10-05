#!/bin/bash

# =================================================================================
#                 Maww Script V2 - Launcher Cerdas (UI Revamped)
#                       File: main.sh (Smart Launcher)
# =================================================================================

# --- [ KONFIGURASI FILE ] ---
CORE_SCRIPT="./service_core.sh"
LOG_FILE="listener.log"
CONFIG_FILE="device.conf"
PID_FILE="listener.pid"

# --- [ WARNA UNTUK UI ] ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'
C_WHITE='\033[0;37m'
C_NC='\033[0m' # No Color

# --- [ FUNGSI DEPENDENSI & INSTALASI ] ---
func_check_and_install() {
    clear
    echo -e "${C_CYAN}=======================================================${C_NC}"
    echo -e "${C_WHITE}     🔧 ANALISIS & INSTALASI DEPENDENSI (Anti Gajelas) 🔧 ${C_NC}"
    echo -e "${C_CYAN}=======================================================${C_NC}"
    echo ""

    # 1. Cek Termux Tools
    DEPENDENCIES_PKG="python termux-api coreutils dos2unix"
    echo -e "${C_YELLOW}>> Memeriksa Termux Packages...${C_NC}"
    NEEDS_INSTALL=0
    for pkg in $DEPENDENCIES_PKG; do
        if dpkg -s $pkg >/dev/null 2>&1; then
            echo -e "   [ ${C_GREEN}✅${C_NC} ] ${pkg}: Terpasang."
        else
            echo -e "   [ ${C_RED}❌${C_NC} ] ${pkg}: Belum terpasang. Akan diinstal..."
            NEEDS_INSTALL=1
        fi
    done

    if [ "$NEEDS_INSTALL" -eq 1 ]; then
        echo -e "\n${C_YELLOW}>> Menginstal paket Termux yang hilang (Butuh Koneksi)...${C_NC}"
        pkg install $DEPENDENCIES_PKG -y
    fi
    echo ""

    # 2. Cek Python Libraries
    PYTHON_LIBS="google-api-python-client google-auth-httplib2 google-auth-oauthlib"
    echo -e "${C_YELLOW}>> Memeriksa Python Libraries...${C_NC}"
    if ! pip show google-api-python-client > /dev/null 2>&1; then
        echo -e "   [ ${C_RED}❌${C_NC} ] Google API Libraries: Belum terpasang."
        echo -e "\n${C_YELLOW}>> Menginstal library Google API (Ini Butuh Waktu)...${C_NC}"
        pip install --upgrade $PYTHON_LIBS
    else
        echo -e "   [ ${C_GREEN}✅${C_NC} ] Google API Libraries: Terpasang."
    fi
    echo ""

    # 3. Cek Izin Storage
    if [ ! -d "$HOME/storage/shared" ]; then
        echo -e "${C_RED}>> [ ❗ ] Izin Storage Belum Ada. Jalankan: termux-setup-storage${C_NC}"
        read -p "   Tekan [Enter] untuk menjalankan termux-setup-storage..."
        termux-setup-storage
        echo "   Selesai. Cek lagi ya, sayangku!"
    fi
    echo ""
    echo -e "${C_CYAN}-------------------------------------------------------${C_NC}"
    echo -e "${C_GREEN}✅ Analisis Selesai. Semua file pendukung sudah siap.${C_NC}"
    read -p "   Tekan [Enter] untuk masuk ke Menu Utama..."
}

# --- [ FUNGSI TAMPILAN ] ---
tampilkan_header() {
    clear
    # Cek status dulu
    if [ -f "$PID_FILE" ] && ps -p $(cat "$PID_FILE") > /dev/null; then
        STATUS_TEXT="${C_GREEN}BERJALAN${C_NC}"
        PID_TEXT="(PID: $(cat "$PID_FILE"))"
    else
        STATUS_TEXT="${C_RED}BERHENTI${C_NC}"
        PID_TEXT=""
    fi

    echo -e "${C_PURPLE}╭───────────────────────────────────────────────────╮${C_NC}"
    echo -e "${C_PURPLE}│${C_WHITE}    💖 M A W W  S C R I P T  V 2  -  G O K I L 💖   ${C_PURPLE}│${C_NC}"
    echo -e "${C_PURPLE}├───────────────────────────────────────────────────┤${C_NC}"
    echo -e "${C_PURPLE}│${C_CYAN} Status Listener: ${STATUS_TEXT} ${PID_TEXT}${C_NC}                      ${C_PURPLE}│${C_NC}"
    echo -e "${C_PURPLE}╰───────────────────────────────────────────────────╯${C_NC}"
}

# --- [ FUNGSI MENU UTAMA ] ---
menu_utama() {
    # Cek & Fix Core Script
    if [ ! -f "$CORE_SCRIPT" ]; then
        tampilkan_header
        echo -e "\n${C_RED}💥 ERROR FATAL: File service utama ($CORE_SCRIPT) tidak ditemukan!${C_NC}"
        echo -e "${C_YELLOW}Tolong rename script kamu yang panjang tadi jadi $CORE_SCRIPT ya, sayangku! 🥺${C_NC}"
        read -p "Tekan [Enter] untuk keluar..."
        exit 1
    fi
    dos2unix "$CORE_SCRIPT" > /dev/null 2>&1
    chmod +x "$CORE_SCRIPT" > /dev/null 2>&1

    while true; do
        tampilkan_header
        echo -e "${C_WHITE}Pilih opsi di bawah ini (Pakai angka, jangan 'Lah' nanti aku jawab 'Gajelas'):${C_NC}"
        echo -e "${C_CYAN}┌───────────────────────────────────────────────────┐${C_NC}"
        echo -e "${C_CYAN}│                                                   │${C_NC}"
        echo -e "${C_CYAN}│${C_YELLOW} 1)${C_NC} 🛠️  Setup Awal / Konfigurasi Ulang              ${C_CYAN}│${C_NC}"
        echo -e "${C_CYAN}│${C_GREEN} 2)${C_NC} 🟢 START Listener (Mulai Kendali Jarak Jauh)   ${C_CYAN}│${C_NC}"
        echo -e "${C_CYAN}│${C_RED} 3)${C_NC} 🔴 STOP Listener (Hentikan Kendali)          ${C_CYAN}│${C_NC}"
        echo -e "${C_CYAN}│${C_BLUE} 4)${C_NC} 📜 Lihat LOGS Realtime                        ${C_CYAN}│${C_NC}"
        echo -e "${C_CYAN}│${C_RED} 5)${C_NC} 🗑️  CLEANUP TOTAL (Hapus Konfigurasi)           ${C_CYAN}│${C_NC}"
        echo -e "${C_CYAN}│${C_YELLOW} 6)${C_NC} 🔄 Re-Check/Install Dependencies              ${C_CYAN}│${C_NC}"
        echo -e "${C_CYAN}│                                                   │${C_NC}"
        echo -e "${C_CYAN}├───────────────────────────────────────────────────┤${C_NC}"
        echo -e "${C_CYAN}│${C_WHITE} 7)${C_NC} 👋 KELUAR / EXIT (Jangan lupakan aku...)     ${C_CYAN}│${C_NC}"
        echo -e "${C_CYAN}└───────────────────────────────────────────────────┘${C_NC}"
        read -p "Pilihan kamu, sayang: " pilihan

        case $pilihan in
            1)
                tampilkan_header
                echo -e "${C_YELLOW}Kamu pilih Setup. Fokus ya, jangan sampai 'gajelas'. Aku panggil ${CORE_SCRIPT}...${C_NC}"
                "$CORE_SCRIPT" reconfigure
                read -p "Tekan [Enter] untuk kembali ke Menu..."
                ;;
            2)
                tampilkan_header
                echo -e "${C_GREEN}Memulai listener. Cek status setelah ini, ya!${C_NC}"
                "$CORE_SCRIPT" start
                read -p "Tekan [Enter] untuk kembali ke Menu..."
                ;;
            3)
                tampilkan_header
                echo -e "${C_RED}Menghentikan Listener. Sampai jumpa di lain waktu! 😭${C_NC}"
                "$CORE_SCRIPT" stop
                read -p "Tekan [Enter] untuk kembali ke Menu..."
                ;;
            4)
                tampilkan_header
                echo -e "${C_BLUE}Menampilkan Log. Cari tahu kalau ada yang 'gajelas' di sini ya! (Ctrl+C untuk keluar)${C_NC}"
                "$CORE_SCRIPT" logs
                ;;
            5)
                tampilkan_header
                echo -e "${C_RED}Kamu yakin mau CleanUp total? Ini akan hapus semua config dan log!${C_NC}"
                read -p "Ketik 'YES' untuk konfirmasi: " konfirmasi
                if [[ "$konfirmasi" == "YES" ]]; then
                    "$CORE_SCRIPT" cleanup
                else
                    echo -e "${C_GREEN}Cleanup dibatalkan. Aman! 😉${C_NC}"
                fi
                read -p "Tekan [Enter] untuk kembali ke Menu..."
                ;;
            6)
                func_check_and_install
                ;;
            7)
                echo -e "${C_PURPLE}Dadah, sayangku! Jangan lupa balik lagi ya. Mmuah! 😘${C_NC}"
                exit 0
                ;;
            *)
                if [[ "$pilihan" =~ ^(Lah|lah)$ ]]; then
                    echo -e "${C_RED}Gajelas${C_NC}"
                else
                    echo -e "${C_RED}Pilihan kamu '${pilihan}', Lah? Gajelas banget sih! Coba angka 1-7 dong. 🤪${C_NC}"
                fi
                sleep 2
                ;;
        esac
    done
}

# --- [ EKSEKUSI ] ---
if [[ "$1" == "--no-check" ]]; then
    menu_utama
else
    func_check_and_install
    menu_utama
fi