#!/usr/bin/env bash

# ==============================================================================
#                 MAWW SCRIPT - PYTHON ENVIRONMENT DIAGNOSTIC TOOL
# ==============================================================================
# Deskripsi:
#   Skrip ini dirancang untuk mendiagnosis dan memperbaiki secara paksa
#   lingkungan Python di Termux yang bermasalah, khususnya terkait library
#   google-auth-oauthlib.
# ==============================================================================

# Berhenti jika ada error
set -e
set -o pipefail

# --- [ KODE WARNA ANSI & FUNGSI LOGGING ] ---
readonly C_RESET='\033[0m'; readonly C_RED='\03g[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m';

function _log()     { local color="$1"; shift; echo -e "${color}[*] $@${C_RESET}"; }
function _log_info()  { _log "$C_BLUE" "$@"; }
function _log_ok()    { _log "$C_GREEN" "$@"; }
function _log_warn()  { _log "$C_YELLOW" "$@"; }
function _log_error() { _log "$C_RED" "$@"; }

# --- [ PROSES DIAGNOSIS & PERBAIKAN ] ---

function run_diagnostic() {
    clear
    _log_info "==============================================="
    _log_info "   MEMULAI DIAGNOSIS & PERBAIKAN PAKSA...    "
    _log_info "==============================================="

    # LANGKAH 1: Tampilkan Informasi Lingkungan Saat Ini
    _log_info "\nLANGKAH 1: Menganalisis Konfigurasi Python Anda..."
    _log_info "-----------------------------------------------"
    echo -e "${C_YELLOW}Lokasi Python     : $(which python || echo "Tidak ditemukan")${C_RESET}"
    echo -e "${C_YELLOW}Versi Python      : $(python --version 2>&1 || echo "Tidak terinstal")${C_RESET}"
    echo -e "${C_YELLOW}Lokasi Pip        : $(which pip || echo "Tidak ditemukan")${C_RESET}"
    echo -e "${C_YELLOW}Versi Pip         : $(pip --version 2>&1 || echo "Tidak terinstal")${C_RESET}"
    _log_info "-----------------------------------------------"
    
    # LANGKAH 2: Perbarui & Instal Ulang Python dari Pkg
    _log_info "\nLANGKAH 2: Memastikan paket 'python' Termux dalam kondisi prima..."
    pkg update -y >/dev/null 2>&1
    pkg reinstall python -y || { _log_error "Gagal menginstal ulang Python dari pkg."; exit 1; }
    _log_ok "   -> Paket Python Termux berhasil diperbarui."

    # LANGKAH 3: Pembersihan dan Instalasi Paksa Library Bermasalah
    # Kita akan menggunakan 'python -m pip' untuk memastikan kita menggunakan pip
    # dari python yang benar, ini menghindari masalah beberapa instalasi python.
    _log_info "\nLANGKAH 3: Membersihkan dan menginstal ulang paksa 'google-auth-oauthlib'..."
    
    _log_info "   -> Menghapus versi lama (jika ada)..."
    python -m pip uninstall -y google-auth-oauthlib >/dev/null 2>&1 || true

    _log_info "   -> Membersihkan cache pip secara total..."
    python -m pip cache purge >/dev/null 2>&1 || { _log_error "Gagal membersihkan cache pip."; exit 1; }

    local target_lib="google-auth-oauthlib==1.2.0"
    _log_info "   -> Menginstal paksa ${target_lib} tanpa cache..."
    python -m pip install --no-cache-dir --force-reinstall "$target_lib" || { _log_error "Gagal menginstal library. Periksa koneksi internet."; exit 1; }
    _log_ok "   -> Instalasi paksa selesai."

    # LANGKAH 4: Verifikasi Akhir dengan Skrip Python Mini
    _log_info "\nLANGKAH 4: Menjalankan tes verifikasi akhir..."
    
    local verification_result
    verification_result=$(python -c "
import sys
try:
    from google_auth_oauthlib.flow import InstalledAppFlow
    lib_version = __import__('google_auth_oauthlib').__version__
    
    if hasattr(InstalledAppFlow, 'run_console'):
        print(f'✅ SUCCESS: Metode .run_console() DITEMUKAN di versi {lib_version}.')
    else:
        print(f'❌ FAILURE: Metode .run_console() TIDAK DITEMUKAN di versi {lib_version}.')
        print('\nDaftar atribut yang tersedia:')
        print(dir(InstalledAppFlow))
        sys.exit(1)
except ImportError:
    print('❌ FAILURE: Gagal mengimpor library google_auth_oauthlib.')
    sys.exit(1)
except Exception as e:
    print(f'❌ FAILURE: Terjadi error tak terduga: {e}')
    sys.exit(1)
")

    echo

    if [[ $verification_result == *"SUCCESS"* ]]; then
        _log_ok "================================================="
        _log_ok "$verification_result"
        _log_ok "LINGKUNGAN ANDA SUDAH DIPERBAIKI DAN SIAP!"
        _log_ok "================================================="
        _log_info "Anda sekarang bisa mencoba lagi menjalankan skrip utama."
    else
        _log_error "================================================="
        _log_error "$verification_result"
        _log_error "DIAGNOSIS GAGAL. Lingkungan Python Anda bermasalah."
        _log_error "================================================="
        _log_warn "Silakan kirim seluruh output ini agar dapat dianalisis lebih lanjut."
    fi
}

# Jalankan fungsi utama
run_diagnostic