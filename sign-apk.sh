#!/bin/bash

# ============================================================================
#               SIGN-APK.SH v3.0 - The Professional Finisher
#      Script cerdas untuk menandatangani dan mengoptimalkan APK
#          dengan mode interaktif, zipalign, dan proteksi.
# ============================================================================

# --- [1] KONFIGURASI ---
# Path disesuaikan agar konsisten dengan ekosistem script kita
readonly TOOLS_DIR="$HOME/tools"
readonly SIGNER_JAR="$TOOLS_DIR/uber-apk-signer.jar"

# Direktori output utama
readonly BUILT_DIR="$HOME/storage/shared/MawwScript/built"
readonly MODED_DIR="$HOME/storage/shared/MawwScript/mod"

# --- [2] UI & UTILITY ---
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'
CYAN='\033[1;36m'; BOLD=$(tput bold); NORMAL=$(tput sgr0)

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║      ✍️  SIGN-APK v3.0 - The Professional Finisher ✍️   ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_step() { echo -e "\n${BLUE}${BOLD}--- [LANGKAH $1] $2 ---${NC}"; }
log_info() { echo -e "  ${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "  ${GREEN}✔  $1${NC}"; }
log_error() { echo -e "  ${RED}✖  $1${NC}"; }

# --- [3] FUNGSI INTI ---

# Memeriksa semua kebutuhan sistem sebelum mulai
check_dependencies() {
    log_step 1 "Memeriksa Kebutuhan Sistem"
    if ! command -v java &> /dev/null; then
        log_error "Java (JDK) tidak ditemukan. Proses tidak bisa dilanjutkan."
        exit 1
    fi
    if [ ! -f "$SIGNER_JAR" ]; then
        log_error "Uber APK Signer tidak ditemukan di '$SIGNER_JAR'."
        log_info "Jalankan 'setup-modding.sh' untuk menginstalnya."
        exit 1
    fi
    log_success "Java dan APK Signer siap digunakan."
}

# Mode interaktif jika tidak ada argumen file
interactive_mode() {
    log_step 2 "Memilih APK Secara Interaktif"
    log_info "Mencari file .apk di folder '$BUILT_DIR' dan '$MODED_DIR'..."
    
    # Mencari semua file APK dan menyimpannya dalam array
    local apks=()
    while IFS= read -r -d $'\0'; do
        apks+=("$REPLY")
    done < <(find "$BUILT_DIR" "$MODED_DIR" -maxdepth 1 -type f -name "*.apk" -print0)

    if [ ${#apks[@]} -eq 0 ]; then
        log_error "Tidak ada file .apk yang ditemukan di direktori output."
        return 1
    fi

    echo "Silakan pilih file APK yang ingin di-sign:"
    select apk_path in "${apks[@]}"; do
        if [ -n "$apk_path" ]; then
            INPUT_APK="$apk_path"
            log_success "Anda memilih: $(basename "$INPUT_APK")"
            return 0
        else
            log_error "Pilihan tidak valid."
            return 1
        fi
    done
}

# Fungsi utama untuk memproses dan menandatangani APK
process_and_sign() {
    local input_apk="$1"
    
    log_step 3 "Analisis & Konfigurasi Output"
    # Membuat nama file output yang bersih
    local clean_name=$(basename "$input_apk" | sed -E 's/(-unsigned|-built|-REBUILT)?\.apk$//i')
    local final_filename="${clean_name}-Signed-$(date +%F).apk"
    local final_path="$MODED_DIR/$final_filename"
    
    log_info "File Input: $(basename "$input_apk")"
    log_info "File Output: $final_filename"
    
    # Fitur proteksi timpa file
    if [ -f "$final_path" ]; then
        read -p ">> File '$final_filename' sudah ada. Timpa file? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "Proses dibatalkan oleh pengguna."
            return
        fi
    fi

    log_step 4 "Eksekusi Zipalign & Sign"
    log_info "Proses signing akan menyertakan 'zipalign' untuk optimasi RAM."
    
    # Menjalankan perintah signer dengan zipalign
    if java -jar "$SIGNER_JAR" --zipalign --allowResign --in "$input_apk" --out "$final_path"; then
        echo -e "\n${GREEN}=================================================="
        echo "🎉 MANTAP JIWA! APK BERHASIL DI-SIGN & DIOPTIMASI! 🎉"
        echo "=================================================="
        log_success "File final Anda siap di:"
        echo -e "${YELLOW}$final_path${NC}"
        echo -e "\n${BLUE}Silakan install file tersebut. Peringatan Play Protect wajar untuk APK modifan.${NC}"
    else
        echo -e "\n${RED}=================================================="
        echo " 😫 GAGAL TOTAL! Proses signing error, cuy! 😫"
        echo "=================================================="
        log_error "Cek pesan error di atas. Mungkin ada masalah dengan file APK-nya."
    fi
}

# =================================================
#               PROGRAM UTAMA
# =================================================

main() {
    print_header
    check_dependencies
    
    # Membuat folder output jika belum ada
    mkdir -p "$BUILT_DIR" "$MODED_DIR"

    local INPUT_APK=""
    if [ -z "$1" ]; then
        # Jika tidak ada argumen, masuk mode interaktif
        interactive_mode || return
    else
        # Jika ada argumen, validasi file
        log_step 2 "Validasi Input"
        if [ ! -f "$1" ]; then
            log_error "File '$1' tidak ditemukan!"
            return
        fi
        INPUT_APK="$1"
        log_success "File input valid: $(basename "$INPUT_APK")"
    fi

    # Lanjutkan ke proses sign jika file sudah ditentukan
    if [ -n "$INPUT_APK" ]; then
        process_and_sign "$INPUT_APK"
    fi
}

# Jalankan fungsi utama
main "$@"
