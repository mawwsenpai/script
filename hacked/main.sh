#!/usr/bin/env bash

# ==============================================================================
#                 MAWW SCRIPT V6 - SMART LAUNCHER
# ==============================================================================
# Deskripsi:
#   Launcher ini akan secara otomatis memeriksa apakah lingkungan sudah siap.
#   Jika belum, ia akan menawarkan untuk menjalankan patch instalasi.
# ==============================================================================

# --- [ KONFIGURASI ] ---
set -e
set -o pipefail
readonly CORE_SCRIPT="./core.sh"
readonly PATCH_SCRIPT="./install-patch.sh"
readonly PID_FILE="listener.pid"
readonly PATCH_FLAG_FILE=".patch_installed"

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
    echo -e "${C_PURPLE}│${C_WHITE}      MAWW SCRIPT V6 - SMART EDITION           ${C_PURPLE}│${C_RESET}"
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
    echo -e "${C_YELLOW}│  ${C_WHITE}5) Jalankan Ulang Perbaikan (Patch)${C_RESET}          │${C_RESET}"
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
        5) bash "$PATCH_SCRIPT" ;; # Jalankan patch langsung
        6) "$CORE_SCRIPT" cleanup ;;
        7) echo -e "\n${C_PURPLE}Terima kasih telah menggunakan skrip ini. Sampai jumpa!${C_RESET}"; exit 0 ;;
        *) echo -e "\n${C_RED}Pilihan tidak valid. Silakan coba lagi.${C_RESET}";;
    esac
    echo -e "\n${C_YELLOW}Tekan [Enter] untuk kembali ke menu...${C_RESET}"
    read -n 1
}

# --- [ FUNGSI UTAMA (MAIN) ] ---

# PERUBAHAN DI SINI: Fungsi untuk memeriksa dan menjalankan patch
function check_and_run_patcher() {
    if [ -f "$PATCH_FLAG_FILE" ]; then
        # Jika file penanda ada, berarti patch sudah pernah sukses dijalankan.
        return 0
    fi

    clear
    echo -e "${C_YELLOW}=====================================================${C_RESET}"
    echo -e "${C_WHITE}     👋 Selamat Datang di Maww Script V6! 👋${C_RESET}"
    echo -e "${C_YELLOW}=====================================================${C_RESET}"
    echo
    echo -e "${C_CYAN}Skrip ini mendeteksi bahwa lingkungan Anda belum disiapkan.${C_RESET}"
    echo "Diperlukan proses instalasi dan perbaikan (patch) untuk memastikan"
    echo "semua file dan paket yang dibutuhkan terpasang dengan benar."
    echo
    echo "Proses ini akan:"
    echo "  - Memperbarui Termux Anda."
    echo "  - Menginstal paket-paket penting seperti Python."
    echo "  - Menginstal library Google dengan versi yang tepat."
    echo
    read -p "Apakah Anda ingin menjalankan patch instalasi sekarang? (y/n): " choice

    if [[ "$choice" =~ ^[Yy]$ ]]; then
        if [ ! -f "$PATCH_SCRIPT" ]; then
            echo -e "\n${C_RED}FATAL ERROR: File patch '${PATCH_SCRIPT}' tidak ditemukan!${C_RESET}"
            echo "Pastikan ketiga file (main.sh, core.sh, install-patch.sh) berada dalam folder yang sama."
            exit 1
        fi
        
        # Beri izin eksekusi dan jalankan patch
        chmod +x "$PATCH_SCRIPT"
        bash "$PATCH_SCRIPT"
        
        echo -e "${C_YELLOW}Tekan [Enter] untuk melanjutkan ke menu utama...${C_RESET}"
        read -n 1
    else
        echo -e "\n${C_RED}Instalasi dibatalkan. Skrip tidak dapat berjalan tanpa lingkungan yang siap.${C_RESET}"
        exit 0
    fi
}

function main() {
    # Validasi awal
    if [ ! -f "$CORE_SCRIPT" ]; then
        echo -e "${C_RED}FATAL ERROR: File inti '${CORE_SCRIPT}' tidak ditemukan!${C_RESET}"; exit 1
    fi
    chmod +x "$CORE_SCRIPT"

    # Jalankan pemeriksaan patch
    check_and_run_patcher

    # Loop utama program
    while true; do
        display_header
        display_menu
        prompt_user
    done
}

# Panggil fungsi utama untuk memulai program
main