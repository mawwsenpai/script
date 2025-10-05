#!/usr/bin/env bash
set -e
set -o pipefail
readonly CORE_SCRIPT="./core.sh"
readonly PID_FILE="listener.pid"
readonly C_RESET='\033[0m'; readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_PURPLE='\033[0;35m'; readonly C_CYAN='\033[0;36m';
readonly C_WHITE='\033[1;37m';

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
    echo -e "${C_PURPLE}│${C_WHITE}      MAWW SCRIPT V7 - WEB AUTH EDITION        ${C_PURPLE}│${C_RESET}"
    echo -e "${C_PURPLE}├───────────────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_PURPLE}│ ${C_CYAN}Status   :${C_RESET} ${status_text} ${pid_text}                   ${C_PURPLE}│${C_RESET}"
    echo -e "${C_PURPLE}╰───────────────────────────────────────────────────╯${C_RESET}"
}
function display_menu() {
    echo -e "\n${C_WHITE}Pilih salah satu opsi di bawah ini:${C_RESET}"
    echo -e "${C_CYAN}┌─ KONTROL ─────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}1) Mulai Listener${C_RESET}                             │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}2) Hentikan Listener${C_RESET}                          │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}3) Setup / Konfigurasi Ulang${C_RESET}                  │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}4) Lihat Log${C_RESET}                                  │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}5) Hapus Konfigurasi${C_RESET}                          │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}6) Keluar${C_RESET}                                     │${C_RESET}"
    echo -e "${C_CYAN}└───────────────────────────────────────────────────┘${C_RESET}"
}
function main() {
    if [ ! -f "$CORE_SCRIPT" ]; then
        echo -e "${C_RED}FATAL: File '${CORE_SCRIPT}' tidak ditemukan!${C_RESET}"; exit 1
    fi
    chmod +x "$CORE_SCRIPT"
    while true; do
        display_header
        display_menu
        read -p "   Pilihanmu: " choice
        case $choice in
            1) "$CORE_SCRIPT" start ;;
            2) "$CORE_SCRIPT" stop ;;
            3) "$CORE_SCRIPT" setup ;;
            4) "$CORE_SCRIPT" logs ;;
            5) "$CORE_SCRIPT" cleanup ;;
            6) echo -e "\n${C_PURPLE}Sampai jumpa!${C_RESET}"; exit 0 ;;
            *) echo -e "\n${C_RED}Pilihan tidak valid.${C_RESET}";;
        esac
        echo -e "\n${C_YELLOW}Tekan [Enter] untuk kembali...${C_RESET}"; read -n 1
    done
}
main