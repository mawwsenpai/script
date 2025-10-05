l#!/usr/bin/env bash

# ==============================================================================
#                 MAWW SCRIPT V6 - ENVIRONMENT PATCHER
# ==============================================================================
# Deskripsi:
#   Memperbaiki dan menyiapkan lingkungan Termux. Setelah berhasil, skrip
#   ini akan membuat file '.patch_installed' sebagai tanda bahwa
#   lingkungan sudah siap.
# ==============================================================================

# Berhenti jika ada error
set -e
set -o pipefail

# --- [ KODE WARNA ANSI & FUNGSI LOGGING ] ---
readonly C_RESET='\033[0m'; readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m';

function _log()     { local color="$1"; shift; echo -e "${color}[*] $@${C_RESET}"; }
function _log_info()  { _log "$C_BLUE" "$@"; }
function _log_ok()    { _log "$C_GREEN" "$@"; }
function _log_warn()  { _log "$C_YELLOW" "$@"; }
function _log_error() { _log "$C_RED" "$@"; }

# --- [ DAFTAR DEPENDENSI YANG DIBUTUHKAN ] ---
readonly TERMUX_PACKAGES=( "python" "termux-api" "coreutils" "dos2unix" )
readonly PYTHON_REQUIREMENTS=(
    "google-api-python-client==2.100.0"
    "google-auth==2.23.0"
    "google-auth-httplib2==0.2.0"
    "google-auth-oauthlib==1.2.0"
)

# --- [ PROSES UTAMA PATCH ] ---

function run_patch() {
    clear
    _log_info "============================================="
    _log_info "   MEMULAI PROSES PERBAIKAN LINGKUNGAN...    "
    _log_info "============================================="
    
    _log_info "\nLANGKAH 1: Memperbarui daftar paket Termux (pkg update)..."
    pkg update -y || { _log_error "Gagal menjalankan 'pkg update'. Periksa koneksi internet Anda."; exit 1; }
    
    _log_info "\nLANGKAH 2: Meng-upgrade paket Termux yang sudah terinstal (pkg upgrade)..."
    pkg upgrade -y || { _log_error "Gagal menjalankan 'pkg upgrade'."; exit 1; }

    _log_info "\nLANGKAH 3: Menginstal ulang paksa paket sistem inti..."
    pkg reinstall -y "${TERMUX_PACKAGES[@]}" || { _log_error "Gagal menginstal ulang paket sistem."; exit 1; }
    _log_ok "   -> Paket sistem berhasil dikonfigurasi."

    _log_info "\nLANGKAH 4: Membersihkan lingkungan Python (pip)..."
    _log_info "   -> Menghapus instalasi lama (jika ada) untuk memulai dari awal..."
    for req in "${PYTHON_REQUIREMENTS[@]}"; do
        local pkg_name="${req%%==*}"
        pip uninstall -y "$pkg_name" >/dev/null 2>&1 || true
    done
    _log_info "   -> Membersihkan cache pip secara total..."
    pip cache purge || { _log_error "Gagal membersihkan cache pip."; exit 1; }
    _log_ok "   -> Lingkungan Python berhasil dibersihkan."

    _log_info "\nLANGKAH 5: Menginstal library Python dengan versi yang tepat..."
    pip install --no-cache-dir "${PYTHON_REQUIREMENTS[@]}" || { _log_error "Gagal menginstal library Python."; exit 1; }
    _log_ok "   -> Semua library Python berhasil diinstal."
    
    _log_info "\nLANGKAH 6: Mengonfigurasi izin penyimpanan..."
    if [ ! -d "$HOME/storage/shared" ]; then
        _log_warn "   -> Izin penyimpanan belum diberikan. Meminta izin..."
        termux-setup-storage
    fi
    _log_ok "   -> Izin penyimpanan siap."

    _log_info "\nLANGKAH 7: Melakukan verifikasi akhir..."
    local all_ok=1
    for req in "${PYTHON_REQUIREMENTS[@]}"; do
        local pkg_name="${req%%==*}"; local req_version="${req##*==}"
        local installed_version; installed_version=$(pip show "$pkg_name" 2>/dev/null | grep -i 'Version:' | awk '{print $2}')
        if [[ "$installed_version" != "$req_version" ]]; then
            _log_error "   -> VERIFIKASI GAGAL: '$pkg_name' seharusnya versi '$req_version' tapi terinstal '$installed_version'."
            all_ok=0
        fi
    done

    if [ $all_ok -ne 1 ]; then
        _log_error "Beberapa library gagal diverifikasi. Proses patch tidak sempurna."
        exit 1
    fi
    _log_ok "   -> Verifikasi semua library Python berhasil!"
    
    echo
    _log_ok "======================================================="
    _log_ok "  ✅  PROSES PERBAIKAN LINGKUNGAN SELESAI! ✅"
    _log_ok "======================================================="
    
    # PERUBAHAN DI SINI: Membuat file penanda bahwa patch berhasil
    touch .patch_installed
    _log_info "Sebuah file penanda '.patch_installed' telah dibuat."
    _log_info "\nLingkungan Anda sekarang sudah bersih dan siap."
    _log_info "Anda akan kembali ke menu utama secara otomatis."
    echo
}

run_patch