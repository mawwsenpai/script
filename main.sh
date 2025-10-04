#!/bin/bash

# =======================================================
#               MAIN.SH - Antarmuka Zona Tool V2 Pro
# Koordinator utama yang mengecek status tool dan menampilkan menu.
# Didesain agar stabil, profesional, dan tidak langsung menghilang.
# =======================================================

# 1. Variabel Warna & Status
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD=$(tput bold); NORMAL=$(tput sgr0)
APKTOOL_JAR="$HOME/script/apktool.jar"
export PATH="$HOME/script:$PATH" # Tambahkan folder script ke PATH

# 2. Fungsi Helper: Jalankan Script dan Tahan Layar
run_and_hold() {
    local SCRIPT_NAME=$1
    
    # Jalankan script yang dituju
    ./$SCRIPT_NAME
    
    # Cek apakah Termux sedang berada di sesi interaktif (agar tidak crash saat background process)
    if [ -t 0 ]; then
        echo -e "\n${BLUE}=================================================="
        read -p ">> Tekan [ENTER] untuk kembali ke Menu Utama..."
        echo -e "==================================================${NC}"
    else
        # Jika bukan sesi interaktif, beri waktu 5 detik sebelum kembali
        sleep 5
    fi
}


# 3. Cek Ketersediaan Tools
check_tool_status() {
    # Cek Java
    if command -v java &> /dev/null; then
        STATUS_JAVA="${GREEN}[STABIL] JDK Ditemukan"
        STATUS_INSTALASI="${GREEN}Tool Sudah Siap!"
    else
        STATUS_JAVA="${RED}[GAJELAS] JDK Belum Ada"
        STATUS_INSTALASI="${RED}Instalasi Wajib!"
    fi
    
    # Cek Apktool.jar
    if [ -f "$APKTOOL_JAR" ]; then
        STATUS_APKTOOL="${GREEN}[STABIL] Apktool JAR Ada"
    else
        STATUS_APKTOOL="${RED}[GAJELAS] Apktool JAR Hilang"
    fi
}

# 4. Fungsi Koordinator Instalasi (Menu 0)
install_all_tools() {
    echo -e "\n${YELLOW}⚙️  [START INSTALASI OTOMATIS]${NC}"
    
    # Jalankan instalasi secara berurutan
    ./install-java.sh || return 1
    ./install-gradle.sh || return 1
    ./install-apktool.sh || return 1
    
    # RESTART WAJIB setelah instalasi Apktool/JDK
    echo -e "\n${BLUE}=================================================="
    echo "💡 PERHATIAN! Instalasi Selesai."
    echo -e "${YELLOW}Mohon TUTUP (exit) dan BUKA KEMBALI Termux Anda untuk mengaktifkan ALIAS 'apktool' !${NC}"
    echo "==================================================${NC}"
    exit 0
}

# 5. Fungsi Tampilan Menu Utama (Zona Tool V2)
show_main_menu() {
    clear
    check_tool_status 

    # BANNER ZONA TOOL V2 (ASCII Stabil)
    echo -e "${RED}${BOLD}"
    echo "  ╔═════════════════════════════════════════╗"
    echo "  ║      █▀▀ █▀█ █▄░█ ▄▀█ █░░ ▀█▀ █░█       ║"
    echo "  ║      █▄▄ █▄█ █░▀█ █▀█ █▄▄ ░█░ █▄█ V2    ║"
    echo "  ╚═════════════════════════════════════════╝"
    echo -e "${NC}${YELLOW}TERMINAL STABIL BY MAWWSENPAI | ${STATUS_INSTALASI} ${NC}"
    echo -e "${RED}------------------------------------------------${NC}"
    
    echo -e "\n${BLUE}${BOLD}STATUS TOOL (Harus STABIL):${NC}${NORMAL}"
    echo -e "  Java/JDK: $STATUS_JAVA"
    echo -e "  Apktool: $STATUS_APKTOOL"
    echo -e "  Project: ${GREEN}[PROFESIONAL] di $HOME/script${NC}"
    echo -e "------------------------------------------------"
    
    echo -e "\n${GREEN}Menu Utama (Pilih Nomer):${NC}"
    echo "1. Mod APK         (Bongkar & Edit Game Offline)"
    echo "2. Build APK       (Buat APK dari Source Code ZIP)"
    echo "3. Moded Plus APK  (Hilangkan iklan/premium - Riset Lanjutan)"
    echo "---"
    echo "0. Instalasi Tool  (${RED}WAJIB DULU!${NC})"
    echo "9. Keluar Terminal"
    
    read -p $'\n>> Masukkan pilihan [0-3, 9]: ' choice

    case $choice in
        1) 
            run_and_hold mod-apk.sh # Jalankan dan tahan
            ;;
        2) 
            run_and_hold build-apk.sh # Jalankan dan tahan
            ;;
        3) 
            echo -e "\n${YELLOW}Fitur Moded Plus APK masih dalam pengembangan, cuyy! Masih perlu riset jaringan.${NC}"
            sleep 3
            ;;
        0) 
            install_all_tools
            ;;
        9) 
            echo -e "\n${GREEN}Sampai jumpa lagi, cuyy! Jangan lupa di-git push!${NC}"
            exit 0
            ;;
        *) 
            echo -e "\n${RED}Pilihan gajelas, cuyy! Coba lagi.${NC}"
            sleep 1
            ;;
    esac
}

# 6. Loop Utama
while true; do
    show_main_menu
done
