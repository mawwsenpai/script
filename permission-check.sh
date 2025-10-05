#!/bin/bash

# ============================================================================
#            PERMISSION-MANAGER.SH - Validator & Helper Izin Termux
#       Script cerdas untuk memeriksa dan membantu mengelola semua
#          izin penting yang dibutuhkan untuk modding & building.
# ============================================================================

# --- Palet Warna & Style ---
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'
CYAN='\033[1;36m'; BOLD=$(tput bold); NORMAL=$(tput sgr0)

# --- Variabel Status ---
declare -A STATUS_CHECKS

# --- Fungsi UI ---
print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║      🔑  PERMISSION MANAGER - Validator Izin  🔑       ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_step() { echo -e "\n${BLUE}${BOLD}--- [LANGKAH $1] $2 ---${NC}"; }
log_check() { echo -e "  ${CYAN}↳  Status:${NC} $1"; }

# =================================================
#               PROGRAM UTAMA
# =================================================

print_header

# --- LANGKAH 1: Izin Storage Dasar ---
log_step 1 "Memeriksa Izin Storage Dasar (/sdcard)"
if [ -d "$HOME/storage/shared" ]; then
    log_check "${GREEN}[✔ SIAP]${NC} Akses storage dasar sudah aktif."
    STATUS_CHECKS["Storage Dasar"]="${GREEN}✔ SIAP${NC}"
else
    log_check "${RED}[✘ MASALAH]${NC} Akses storage dasar belum aktif."
    read -p ">> Boleh saya jalankan 'termux-setup-storage' untuk meminta izin? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        termux-setup-storage
        echo -e "${YELLOW}>> Silakan 'IZINKAN' pada pop-up yang muncul di HP Anda.${NC}"
        echo -e "${CYAN}   Menunggu 5 detik sebelum memeriksa ulang...${NC}"
        sleep 5
        if [ -d "$HOME/storage/shared" ]; then
            log_check "${GREEN}[✔ DIPERBAIKI]${NC} Izin storage berhasil diaktifkan!"
            STATUS_CHECKS["Storage Dasar"]="${GREEN}✔ SIAP${NC}"
        else
            log_check "${RED}[✘ GAGAL]${NC} Izin masih belum aktif. Coba cek Pengaturan Aplikasi Android."
            STATUS_CHECKS["Storage Dasar"]="${RED}✘ GAGAL${NC}"
        fi
    else
        log_check "${YELLOW}[⚠ DILEWATI]${NC} Pengguna membatalkan perbaikan."
        STATUS_CHECKS["Storage Dasar"]="${YELLOW}⚠ DILEWATI${NC}"
    fi
fi

# --- LANGKAH 2: Izin Scoped Storage ---
log_step 2 "Memeriksa Izin Scoped Storage (/Android/data)"
if ls -l /sdcard/Android/data >/dev/null 2>&1; then
    log_check "${GREEN}[✔ SIAP]${NC} Akses ke /Android/data tampaknya terbuka."
    STATUS_CHECKS["Android/data"]="${GREEN}✔ SIAP${NC}"
else
    log_check "${YELLOW}[⚠ TERBATAS]${NC} Akses ke /Android/data dibatasi oleh sistem (Scoped Storage)."
    echo -e "   ${CYAN}Ini normal di Android 11+. Untuk akses penuh, butuh metode lanjutan seperti Shizuku/LADB.${NC}"
    STATUS_CHECKS["Android/data"]="${YELLOW}⚠ TERBATAS${NC}"
fi

# --- LANGKAH 3: Izin Instalasi APK ---
log_step 3 "Memeriksa Izin Instalasi APK dari Sumber Tidak Dikenal"
log_check "${YELLOW}[ℹ️ INFO]${NC} Untuk menguji APK hasil build, Termux butuh izin 'Install unknown apps'."
read -p ">> Buka halaman pengaturan Termux untuk mengaktifkan izin ini? (y/n): " confirm_install
if [[ "$confirm_install" == "y" || "$confirm_install" == "Y" ]]; then
    echo -e "${CYAN}   Membuka Pengaturan Aplikasi untuk Termux...${NC}"
    am start --user 0 -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:com.termux
    echo -e "${YELLOW}>> Pada halaman yang terbuka, cari dan aktifkan opsi 'Install unknown apps' atau 'Pasang aplikasi yang tidak dikenal'.${NC}"
    STATUS_CHECKS["Instalasi APK"]="${YELLOW}⚠ PERIKSA MANUAL${NC}"
else
    STATUS_CHECKS["Instalasi APK"]="${YELLOW}⚠ DILEWATI${NC}"
fi

# --- LANGKAH 4: Akses Root ---
log_step 4 "Memeriksa Akses Root"
if command -v su &> /dev/null; then
    log_check "${GREEN}[✔ SIAP]${NC} Akses root (su) terdeteksi."
    STATUS_CHECKS["Akses Root"]="${GREEN}✔ SIAP${NC}"
else
    log_check "${YELLOW}[ℹ️ INFO]${NC} Akses root tidak terdeteksi. Ini tidak wajib untuk sebagian besar tugas."
    STATUS_CHECKS["Akses Root"]="${YELLOW}ℹ️ OPSIONAL${NC}"
fi

# --- LAPORAN STATUS AKHIR ---
echo -e "\n${BLUE}${BOLD}======================================================"
echo "              LAPORAN STATUS AKHIR Izin"
echo -e "======================================================${NC}"
printf '%-25s | %s\n' "Tipe Izin" "Status"
echo "------------------------------------------------------"
printf '%-25s | %s\n' "Storage Dasar (/sdcard)" "${STATUS_CHECKS['Storage Dasar']}"
printf '%-25s | %s\n' "Scoped Storage (/Android/data)" "${STATUS_CHECKS['Android/data']}"
printf '%-25s | %s\n' "Instalasi APK" "${STATUS_CHECKS['Instalasi APK']}"
printf '%-25s | %s\n' "Akses Root" "${STATUS_CHECKS['Akses Root']}"
echo "======================================================"

