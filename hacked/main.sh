#!/bin/bash

# =================================================================================
#                 💖 M A W W  S C R I P T  V 3 - Launcher Cerdas 💖
# =================================================================================
# File ini adalah pintu utama untuk menjalankan semua fitur.
# Didesain ulang untuk kemudahan maksimal.
# =================================================================================

# --- [ KONFIGURASI GLOBAL ] ---
CORE_SCRIPT="./service_core.sh"
PID_FILE="listener.pid"

# --- [ WARNA UNTUK UI ] ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_CYAN='\033[0;36m'
C_WHITE='\033[1;37m'
C_NC='\033[0m' # No Color

# --- [ FUNGSI UTAMA ] ---

# Fungsi untuk menampilkan header dan status utama
tampilkan_header() {
    clear
    local status_text
    local pid_text=""
    
    # Cek status listener berdasarkan file PID
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        status_text="${C_GREEN}AKTIF${C_NC}"
        pid_text="(PID: $(cat "$PID_FILE"))"
    else
        status_text="${C_RED}TIDAK AKTIF${C_NC}"
    fi

    echo -e "${C_PURPLE}╭───────────────────────────────────────────────────╮${C_NC}"
    echo -e "${C_PURPLE}│${C_WHITE}    💖 M A W W  S C R I P T  V 3 - G O K I L 💖   ${C_PURPLE}│${C_NC}"
    echo -e "${C_PURPLE}├───────────────────────────────────────────────────┤${C_NC}"
    echo -e "${C_PURPLE}│ ${C_CYAN}Status Listener: ${status_text} ${pid_text}${C_NC}                      ${C_PURPLE}│${C_NC}"
    echo -e "${C_PURPLE}╰───────────────────────────────────────────────────╯${C_NC}"
}

# Fungsi untuk menampilkan menu utama
tampilkan_menu() {
    echo -e "\n${C_WHITE}Pilih salah satu opsi di bawah ini:${C_NC}"
    echo -e "${C_CYAN}┌───────────────────────────────────────────────────┐${C_NC}"
    echo -e "${C_CYAN}│  ${C_GREEN}--- KONTROL LISTENER ---${C_NC}                      │${C_NC}"
    echo -e "${C_CYAN}│  ${C_WHITE}1) Mulai Listener${C_NC}                             │${C_NC}"
    echo -e "${C_CYAN}│  ${C_WHITE}2) Hentikan Listener${C_NC}                          │${C_NC}"
    echo -e "${C_CYAN}│                                                   │${C_NC}"
    echo -e "${C_CYAN}│  ${C_YELLOW}--- MANAJEMEN & DEBUG ---${C_NC}                   │${C_NC}"
    echo -e "${C_CYAN}│  ${C_WHITE}3) Setup / Konfigurasi Ulang${C_NC}                  │${C_NC}"
    echo -e "${C_CYAN}│  ${C_WHITE}4) Lihat Log Realtime${C_NC}                         │${C_NC}"
    echo -e "${C_CYAN}│  ${C_WHITE}5) Periksa Ulang Dependensi${C_NC}                   │${C_NC}"
    echo -e "${C_CYAN}│                                                   │${C_NC}"
    echo -e "${C_CYAN}│  ${C_RED}--- OPSI BAHAYA ---${C_NC}                         │${C_NC}"
    echo -e "${C_CYAN}│  ${C_WHITE}6) Hapus Semua Konfigurasi (Cleanup)${C_NC}          │${C_NC}"
    echo -e "${C_CYAN}├───────────────────────────────────────────────────┤${C_NC}"
    echo -e "${C_CYAN}│  ${C_WHITE}7) Keluar${C_NC}                                     │${C_NC}"
    echo -e "${C_CYAN}└───────────────────────────────────────────────────┘${C_NC}"
    read -p "   Pilihanmu: " pilihan
}

# --- [ EKSEKUSI SKRIP ] ---

# Pastikan core script ada dan bisa dieksekusi
if [ ! -f "$CORE_SCRIPT" ]; then
    echo -e "${C_RED}FATAL ERROR: File inti '${CORE_SCRIPT}' tidak ditemukan!${C_NC}"
    echo "Pastikan kedua file skrip berada dalam folder yang sama."
    exit 1
fi
chmod +x "$CORE_SCRIPT"

# Jalankan pengecekan dependensi sekali saat pertama kali dijalankan
if [ ! -f ".dependencies_checked" ]; then
    "$CORE_SCRIPT" check_dependencies
    touch ".dependencies_checked"
fi

# Loop menu utama
while true; do
    tampilkan_header
    tampilkan_menu

    case $pilihan in
        1) "$CORE_SCRIPT" start ;;
        2) "$CORE_SCRIPT" stop ;;
        3) "$CORE_SCRIPT" setup ;;
        4) "$CORE_SCRIPT" logs ;;
        5) "$CORE_SCRIPT" check_dependencies ;;
        6) "$CORE_SCRIPT" cleanup ;;
        7) echo -e "${C_PURPLE}Sampai jumpa lagi, cuy! Mmuah! 😘${C_NC}"; exit 0 ;;
        *) echo -e "${C_RED}Pilihan tidak valid. Coba lagi.${C_NC}";;
    esac

    echo -e "\n${C_YELLOW}Tekan [Enter] untuk kembali ke menu...${C_NC}"
    read -n 1
done