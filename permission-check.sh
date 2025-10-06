#!/bin/bash

# =================================================================================
#      🔑 PERMISSION PRO - The Ultimate Termux Permissions Grandmaster 🔑
# =================================================================================
# Deskripsi:
# Rombakan total menjadi asisten perizinan cerdas. Memeriksa dan memandu
# pengguna untuk mengaktifkan semua izin krusial, termasuk "Akses Semua File"
# untuk menembus batasan Android modern.
# =================================================================================

# --- [1] KONFIGURASI TAMPILAN & WARNA (tput) ---
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
PURPLE=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
GRAY=$(tput setaf 8)
NC=$(tput sgr0)
BOLD=$(tput bold)

# --- [2] VARIABEL STATUS ---
declare -A STATUS_CHECKS

# --- [3] FUNGSI UTILITY & UI ---
log_msg() {
    local type="$1" color="$NC" prefix=""
    case "$type" in
        INFO)    prefix="[i] INFO"    ; color="$CYAN"   ;;
        SUCCESS) prefix="[✓] SUKSES"  ; color="$GREEN"  ;;
        WARN)    prefix="[!] PENTING" ; color="$YELLOW" ;;
        ERROR)   prefix="[✘] MASALAH" ; color="$RED"    ;;
        STEP)    prefix="[»] LANGKAH" ; color="$BLUE"   ;;
    esac
    echo -e "${BOLD}${color}${prefix}${NC} : $2"
}

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo '  █▀█ █▀▀ █▀█ █▀▄▀█ █─█ █▀─ █▀█ █─█  █▀█ █▀█ █▀'
    echo '  █▀▄ ██▄ █▀▄ █░▀░█ █▀█ ██▄ █▄█ █▀▄  █▀▀ █▄█ ▄█'
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo -e "${BOLD}${WHITE}  The Ultimate Termux Permissions Grandmaster${NC}"
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo
}

# --- [4] FUNGSI PEMERIKSAAN & PERBAIKAN ---

# Izin 1: Storage Dasar
check_storage_basic() {
    log_msg STEP "Memeriksa Izin Storage Dasar (/sdcard)"
    if [ -d "$HOME/storage/shared" ]; then
        log_msg SUCCESS "Akses storage dasar sudah aktif."
        STATUS_CHECKS["Storage Dasar"]="${GREEN}✔ SIAP${NC}"
    else
        log_msg ERROR "Akses storage dasar belum aktif."
        read -rp ">> Boleh saya jalankan 'termux-setup-storage' untuk meminta izin? (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            termux-setup-storage
            log_msg WARN "Silakan 'IZINKAN' pada pop-up yang muncul. Menunggu 5 detik..."
            sleep 5
            if [ -d "$HOME/storage/shared" ]; then
                log_msg SUCCESS "Izin storage berhasil diaktifkan!"
                STATUS_CHECKS["Storage Dasar"]="${GREEN}✔ SIAP${NC}"
            else
                log_msg ERROR "Izin masih belum aktif. Coba cek Pengaturan Aplikasi Android."
                STATUS_CHECKS["Storage Dasar"]="${RED}✘ GAGAL${NC}"
            fi
        else
            log_msg WARN "Dilewati. Banyak skrip mungkin tidak akan berfungsi."
            STATUS_CHECKS["Storage Dasar"]="${YELLOW}⚠ DILEWATI${NC}"
        fi
    fi
}

# Izin 2: Akses Semua File (Sangat Penting)
check_storage_all_files() {
    log_msg STEP "Memeriksa Izin 'Akses Semua File' (untuk /Android/data)"
    log_msg INFO "Izin ini krusial di Android 11+ untuk akses penuh."
    if ls /sdcard/Android/data >/dev/null 2>&1; then
        log_msg SUCCESS "Akses ke /Android/data tampaknya terbuka. Mantap!"
        STATUS_CHECKS["Akses Semua File"]="${GREEN}✔ SIAP${NC}"
    else
        log_msg ERROR "Akses ke /Android/data dibatasi."
        read -rp ">> Buka halaman pengaturan 'Akses Semua File' untuk Termux? (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            log_msg INFO "Membuka Pengaturan Aplikasi..."
            am start --user 0 -a android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION -d package:com.termux
            log_msg WARN "Pada halaman yang terbuka, cari dan AKTIFKAN saklar untuk Termux."
            STATUS_CHECKS["Akses Semua File"]="${YELLOW}⚠ PERIKSA MANUAL${NC}"
        else
            log_msg WARN "Dilewati. Akses ke folder data game akan gagal."
            STATUS_CHECKS["Akses Semua File"]="${YELLOW}⚠ DILEWATI${NC}"
        fi
    fi
}

# Izin 3: Instalasi APK
check_install_apps() {
    log_msg STEP "Memeriksa Izin 'Instal Aplikasi Tidak Dikenal'"
    log_msg INFO "Dibutuhkan untuk menginstal APK hasil modding/build langsung dari Termux."
    read -rp ">> Buka halaman pengaturan 'Instal Aplikasi' untuk Termux? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        log_msg INFO "Membuka Pengaturan Aplikasi..."
        am start --user 0 -a android.settings.MANAGE_UNKNOWN_APP_SOURCES -d package:com.termux
        log_msg WARN "Pada halaman yang terbuka, AKTIFKAN saklar 'Izinkan dari sumber ini'."
        STATUS_CHECKS["Instalasi APK"]="${YELLOW}⚠ PERIKSA MANUAL${NC}"
    else
        log_msg WARN "Dilewati. Anda harus menginstal APK secara manual."
        STATUS_CHECKS["Instalasi APK"]="${YELLOW}⚠ DILEWATI${NC}"
    fi
}

# Izin 4: Akses Root
check_root() {
    log_msg STEP "Memeriksa Akses Root (Metode Akurat)"
    if su -c "echo" >/dev/null 2>&1; then
        log_msg SUCCESS "Akses root fungsional terdeteksi. Kekuatan tak terbatas!"
        STATUS_CHECKS["Akses Root"]="${GREEN}✔ SIAP${NC}"
    else
        log_msg INFO "Tidak ada akses root. Ini normal untuk HP non-root."
        STATUS_CHECKS["Akses Root"]="${GRAY}ℹ️ TIDAK ADA (NORMAL)${NC}"
    fi
}

# --- [5] PROGRAM UTAMA ---
main() {
    print_header
    
    check_storage_basic
    echo
    check_storage_all_files
    echo
    check_install_apps
    echo
    check_root
    
    # Laporan Status Akhir
    echo
    echo -e "  ${PURPLE}╔═════════════════════════════════════════════════════╗"
    echo -e "  ${PURPLE}║${NC} ${BOLD}${WHITE}               LAPORAN STATUS AKHIR                ${PURPLE}║"
    echo -e "  ${PURPLE}╚═════════════════════════════════════════════════════╝${NC}"
    printf "  ${CYAN}%-25s${NC} : %s\n" "Storage Dasar" "${STATUS_CHECKS['Storage Dasar']}"
    printf "  ${CYAN}%-25s${NC} : %s\n" "Akses Semua File" "${STATUS_CHECKS['Akses Semua File']}"
    printf "  ${CYAN}%-25s${NC} : %s\n" "Instalasi APK" "${STATUS_CHECKS['Instalasi APK']}"
    printf "  ${CYAN}%-25s${NC} : %s\n" "Akses Root" "${STATUS_CHECKS['Akses Root']}"
    echo
    log_msg SUCCESS "Pemeriksaan selesai. Sistem Anda sekarang lebih siap!"
    echo
}

main
