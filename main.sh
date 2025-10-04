#!/bin/bash

# =====================================================================
#                 ZONA-TOOL V3 - Smart APK Modding Hub
#       Script ini bertindak sebagai pusat komando yang cerdas,
#         memastikan semua tools siap sebelum menampilkan menu.
# =====================================================================

# --- Palet Warna & Style ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

# --- Konfigurasi Path ---
APKTOOL_JAR="$HOME/script/apktool.jar"
# Pastikan folder script ada di PATH untuk memanggil script lain
export PATH="$HOME/script:$PATH"

# =================================================
#               KUMPULAN FUNGSI
# =================================================

# Fungsi Helper: Jalankan Script dan tahan layar
run_and_hold() {
    local SCRIPT_NAME=$1
    if [ ! -f "./$SCRIPT_NAME" ]; then
        echo -e "${RED}❌ ERROR: Script './$SCRIPT_NAME' tidak ditemukan!${NC}"
        sleep 3
        return
    fi
    
    ./"$SCRIPT_NAME"
    
    echo -e "\n${BLUE}=================================================="
    read -p ">> Tekan [ENTER] untuk kembali ke Menu Utama..."
    echo -e "==================================================${NC}"
}

# Fungsi untuk menampilkan status tool di menu
display_tool_status() {
    if command -v java &> /dev/null; then
        STATUS_JAVA="${GREEN}[STABIL] JDK Ditemukan"
    else
        STATUS_JAVA="${RED}[GAJELAS] JDK Belum Ada"
    fi
    
    if [ -f "$APKTOOL_JAR" ]; then
        STATUS_APKTOOL="${GREEN}[STABIL] Apktool JAR Ada"
    else
        STATUS_APKTOOL="${RED}[GAJELAS] Apktool JAR Hilang"
    fi
}

# Fungsi Koordinator Instalasi
# DIHAPUS 'exit 0' DI AKHIR AGAR TIDAK KELUAR SCRIPT
install_all_tools() {
    clear
    echo -e "\n${YELLOW}⚙️  [START INSTALASI OTOMATIS]${NC}"
    echo "Beberapa tool wajib belum terpasang. Menjalankan instalasi..."
    sleep 2
    
    # Instalasi Berurutan, jika satu gagal, seluruh proses berhenti
    ./install-java.sh || { echo -e "${RED}Instalasi Java gagal! Proses dihentikan.${NC}"; exit 1; }
    # ./install-gradle.sh || { echo -e "${RED}Instalasi Gradle gagal! Proses dihentikan.${NC}"; exit 1; } # Uncomment jika ada
    ./install-apktool.sh || { echo -e "${RED}Instalasi Apktool gagal! Proses dihentikan.${NC}"; exit 1; }
    
    echo -e "\n${GREEN}=================================================="
    echo "✅ SEMUA INSTALASI SELESAI!"
    echo -e "${BLUE}Melanjutkan ke menu utama...${NC}"
    echo "=================================================="
    sleep 3
}

# FUNGSI BARU: Gerbang Pengecekan sebelum masuk menu utama
initial_setup_check() {
    # Cek apakah Java ATAU Apktool.jar tidak ada
    if ! command -v java &> /dev/null || [ ! -f "$APKTOOL_JAR" ]; then
        install_all_tools
    else
        echo -e "${GREEN}✅ Semua tool wajib sudah terpasang. Selamat datang!${NC}"
        sleep 2
    fi
}

# Fungsi Validasi Izin, dijalankan sekali di awal
validate_permissions() {
    clear
    echo -e "=================================================="
    echo -e "${YELLOW}🔑 PERMISSION-CHECK | Memvalidasi Akses Sistem ${NC}"
    echo -e "=================================================="
    
    if [ ! -d "$HOME/storage/shared" ]; then
        echo -e "${YELLOW}>> Mengaktifkan akses storage Termux...${NC}"
        termux-setup-storage
        echo -e "${GREEN}✅ Izin storage diminta. Silakan 'Izinkan' jika muncul pop-up.${NC}"
        sleep 3
    else
        echo -e "${GREEN}✅ [STORAGE] Akses /sdcard STABIL!${NC}"
    fi
}

# Fungsi Tampilan Menu Utama
show_main_menu() {
    clear
    display_tool_status 
    
    echo -e "${RED}${BOLD}"
    echo "  ╔═════════════════════════════════════════╗"
    echo "  ║      █▀▀ █▀█ █▄░█ ▄▀█ █░░ ▀█▀ █░█       ║"
    echo "  ║      █▄▄ █▄█ █░▀█ █▀█ █▄▄ ░█░ █▄█ V3    ║"
    echo "  ╚═════════════════════════════════════════╝"
    echo -e "${NC}${YELLOW}TERMINAL STABIL BY MAWWSENPAI | ${GREEN}Semua Tool Siap!${NC}"
    echo -e "${RED}------------------------------------------------${NC}"
    
    echo -e "\n${BLUE}${BOLD}STATUS TOOL SAAT INI:${NC}${NORMAL}"
    echo -e "  Java/JDK: $STATUS_JAVA"
    echo -e "  Apktool:  $STATUS_APKTOOL"
    echo -e "------------------------------------------------"
    
    echo -e "\n${GREEN}Menu Utama (Pilih Nomer):${NC}"
    echo "1. Mod APK         (Bongkar & Edit Game Offline)"
    echo "2. Build APK       (Buat APK dari Source Code)"
    echo "3. Cek Status Tool (Tampilkan ulang status)"
    echo "4. Organizer       (Atur folder cheat)"
    echo "---"
    echo "0. Re-instal/Update Semua Tool"
    echo "9. Keluar"
    
    read -p $'\n>> Masukkan pilihan [0-4, 9]: ' choice

    case $choice in
        1) run_and_hold mod-apk.sh ;;
        2) run_and_hold build-apk.sh ;;
        3) 
            echo -e "\n${YELLOW}Mengecek ulang status tool...${NC}"
            sleep 2
            # Cukup panggil continue untuk loop ulang dan refresh tampilan
            continue
            ;;
        4) run_and_hold organizer.sh ;;
        0) install_all_tools ;;
        9) 
            echo -e "\n${GREEN}Sampai jumpa lagi, cuyy!${NC}"
            exit 0
            ;;
        *) 
            echo -e "\n${RED}Pilihan gajelas, cuyy! Coba lagi.${NC}"
            sleep 2
            ;;
    esac
}

validate_permissions

initial_setup_check

while true; do
    show_main_menu
done
