#!/usr/bin/env bash

# ==============================================================================
#                 MAWW SCRIPT V5 - PROFESSIONAL LAUNCHER
# ==============================================================================
# Deskripsi:
#   Launcher utama yang berfungsi sebagai User Interface (UI) untuk
#   mengelola service listener. Semua logika inti berada di 'core.sh'.
# ==============================================================================

# --- [ KONFIGURASI ] ---
set -e
set -o pipefail
readonly CORE_SCRIPT="./core.sh"
readonly PID_FILE="listener.pid"

# --- [ KODE WARNA ANSI ] ---
readonly C_RESET='\033[0m'; readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m'; readonly C_PURPLE='\033[0;35m';
readonly C_CYAN='\033[0;36m'; readonly C_WHITE='\033[1;37m';

# --- [ FUNGSI TAMPILAN (UI) ] ---

function display_header() {
    clear
    local status_text; local pid_text=""
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        status_text="${C_GREEN}AKTIF${C_RESET}"
        pid_text="(PID: $(cat "$PID_FILE"))"
    else
        status_text="${C_RED}TIDAK AKTIF${C_RESET}"
    fi
    echo -e "${C_PURPLE}╭───────────────────────────────────────────────────╮${C_RESET}"
    echo -e "${C_PURPLE}│${C_WHITE}      MAWW SCRIPT V5 - PROFESSIONAL EDITION      ${C_PURPLE}│${C_RESET}"
    echo -e "${C_PURPLE}├───────────────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_PURPLE}│ ${C_CYAN}Status   :${C_RESET} ${status_text} ${pid_text}                   ${C_PURPLE}│${C_RESET}"
    echo -e "${C_PURPLE}╰───────────────────────────────────────────────────╯${C_RESET}"
}
function display_menu() {
    echo -e "\n${C_WHITE}Pilih salah satu opsi di bawah ini:${C_RESET}"
    echo -e "${C_CYAN}┌─ KONTROL LISTENER ──────────────────────────────┐${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}1) Mulai Listener${C_RESET}                             │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}2) Hentikan Listener${C_RESET}                          │${C_RESET}"
    echo -e "${C_CYAN}└───────────────────────────────────────────────────┘${C_RESET}"
    echo -e "${C_YELLOW}┌─ MANAJEMEN & DEBUG ───────────────────────────┐${C_RESET}"
    echo -e "${C_YELLOW}│  ${C_WHITE}3) Setup / Konfigurasi Ulang${C_RESET}                  │${C_RESET}"
    echo -e "${C_YELLOW}│  ${C_WHITE}4) Lihat Log Realtime${C_RESET}                         │${C_RESET}"
    echo -e "${C_YELLOW}│  ${C_WHITE}5) Analisis & Perbaiki Dependensi${C_RESET}             │${C_RESET}"
    echo -e "${C_YELLOW}└───────────────────────────────────────────────────┘${C_RESET}"
    echo -e "${C_RED}┌─ OPSI BAHAYA ───────────────────────────────────┐${C_RESET}"
    echo -e "${C_RED}│  ${C_WHITE}6) Hapus Semua Konfigurasi (Cleanup)${C_RESET}          │${C_RESET}"
    echo -e "${C_RED}└───────────────────────────────────────────────────┘${C_RESET}"
    echo -e "${C_PURPLE}┌─ KELUAR ────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_PURPLE}│  ${C_WHITE}7) Keluar${C_RESET}                                     │${C_RESET}"
    echo -e "${C_PURPLE}└───────────────────────────────────────────────────┘${C_RESET}"
}
function prompt_user() {
    local choice
    read -p "   Pilihanmu: " choice
    case $choice in
        1) "$CORE_SCRIPT" start ;;
        2) "$CORE_SCRIPT" stop ;;
        3) "$CORE_SCRIPT" setup ;;
        4) "$CORE_SCRIPT" logs ;;
        5) "$CORE_SCRIPT" check_dependencies ;;
        6) "$CORE_SCRIPT" cleanup ;;
        7) echo -e "\n${C_PURPLE}Terima kasih telah menggunakan skrip ini. Sampai jumpa!${C_RESET}"; exit 0 ;;
        *) echo -e "\n${C_RED}Pilihan tidak valid. Silakan coba lagi.${C_RESET}";;
    esac
    echo -e "\n${C_YELLOW}Tekan [Enter] untuk kembali ke menu...${C_RESET}"
    read -n 1
}

# --- [ FUNGSI UTAMA (MAIN) ] ---

function main() {
    if [ ! -f "$CORE_SCRIPT" ]; then
        echo -e "${C_RED}FATAL ERROR: File inti '${CORE_SCRIPT}' tidak ditemukan!${C_RESET}"
        echo "Pastikan 'main.sh' dan 'core.sh' berada dalam direktori yang sama."
        exit 1
    fi
    chmod +x "$CORE_SCRIPT"

    # Saat pertama kali dijalankan, otomatis lakukan analisis dependensi
    if [ ! -f ".dependencies_checked" ]; then
        clear
        echo -e "${C_YELLOW}Selamat datang! Ini adalah eksekusi pertama.${C_RESET}"
        echo "Skrip akan menganalisis dan menginstal semua file yang dibutuhkan secara otomatis."
        echo "Proses ini mungkin memakan waktu dan membutuhkan koneksi internet."
        echo -e "${C_YELLOW}Tekan [Enter] untuk memulai...${C_RESET}"
        read -n 1
        clear
        "$CORE_SCRIPT" check_dependencies
        touch ".dependencies_checked"
        echo -e "\n${C_GREEN}Semua kebutuhan skrip telah terpenuhi.${C_RESET}"
        echo -e "${C_YELLOW}Tekan [Enter] untuk melanjutkan ke menu utama...${C_RESET}"
        read -n 1
    fi

    while true; do
        display_header
        display_menu
        prompt_user
    done
}

# Panggil fungsi utama untuk memulai program
main