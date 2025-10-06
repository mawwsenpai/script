#!/bin/bash

# =================================================================================
#      ✍️  SIGN-APK Edisi PRO - The Professional APK Finisher ✍️
# =================================================================================
# Deskripsi:
# Rombakan total dengan UI profesional, mode interaktif cerdas, penamaan
# file otomatis, dan alur kerja signing yang aman dan dapat dikonfigurasi.
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

# --- [2] KONFIGURASI GLOBAL ---
# Direktori output. APK yang sudah di-sign akan ditempatkan di sini.
readonly SIGNED_OUTPUT_DIR="$HOME/apk_signed"

# --- [3] FUNGSI UTILITY & UI ---
log_msg() {
    local type="$1" color="$NC" prefix=""
    case "$type" in
        INFO)    prefix="[i] INFO"    ; color="$CYAN"   ;;
        SUCCESS) prefix="[✓] SUKSES"  ; color="$GREEN"  ;;
        WARN)    prefix="[!] PERINGATAN"; color="$YELLOW" ;;
        ERROR)   prefix="[✘] ERROR"   ; color="$RED"    ;;
        STEP)    prefix="[»] LANGKAH" ; color="$BLUE"   ;;
    esac
    echo -e "${BOLD}${color}${prefix}${NC} : $2"
}

print_header() {
    clear
    echo -e "${GREEN}${BOLD}"
    echo '  █▀─ █─█ █▀▀ █─█  ▄▀█ █▀▄ █▄█  █▀█ █▀█ █▀'
    echo '  █▀▄ █▀█ ██▄ █▄█  █▀█ █▄▀ ░█░  █▀▀ █▄█ ▄█'
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo -e "${BOLD}${WHITE}  The Professional APK Finisher${NC}"
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo
}

# --- [4] FUNGSI INTI ---
check_dependencies() {
    log_msg STEP "Memeriksa Kesiapan Sistem"
    local all_ok=true
    for cmd in java uber-apk-signer; do
        if ! command -v $cmd &> /dev/null; then
            log_msg ERROR "Perintah '$cmd' tidak ditemukan! Pastikan sudah terinstal via Maww-Toolkit."
            all_ok=false
        fi
    done

    if $all_ok; then
        log_msg SUCCESS "Java dan Uber APK Signer siap digunakan."
    else
        exit 1
    fi
}

# Mode interaktif jika tidak ada argumen file
interactive_mode() {
    log_msg STEP "Memilih APK Secara Interaktif"
    log_msg INFO "Mencari file .apk di folder umum..."
    
    local search_dirs=("$HOME/apk_projects" "$HOME/apk_builds/finished" "$HOME/storage/downloads" "$HOME/storage/shared" "$HOME/downloads")
    local apks=()
    while IFS= read -r -d $'\0'; do
        apks+=("$REPLY")
    done < <(find "${search_dirs[@]}" -maxdepth 2 -type f -name "*.apk" ! -name "*-signed.apk" -print0 2>/dev/null)

    if [ ${#apks[@]} -eq 0 ]; then
        log_msg ERROR "Tidak ada file .apk yang belum di-sign ditemukan."
        return 1
    fi

    echo "Silakan pilih file APK yang ingin di-sign:"
    local options=()
    for apk in "${apks[@]}"; do
        options+=("$(basename "$apk") ${GRAY}(di: $(dirname "$apk"))${NC}")
    done
    options+=("${RED}--- BATAL ---${NC}")
    
    select choice in "${options[@]}"; do
        if [[ "$choice" == "${RED}--- BATAL ---${NC}" ]]; then
            return 1
        elif [ -n "$choice" ]; then
            # Ambil path asli dari pilihan
            local selected_index=$((REPLY - 1))
            INPUT_APK="${apks[$selected_index]}"
            log_msg SUCCESS "Anda memilih: $(basename "$INPUT_APK")"
            return 0
        else
            log_msg ERROR "Pilihan tidak valid."
            return 1
        fi
    done
}

# Fungsi utama untuk memproses dan menandatangani APK
process_and_sign() {
    local input_apk="$1"
    
    log_msg STEP "Konfigurasi Signing"
    
    # Membuat nama file output yang bersih dan cerdas
    local clean_name
    clean_name=$(basename "$input_apk" .apk | sed -E 's/(-unsigned|-mod|-rebuilt|-debug|-release)$//i')
    local suggested_filename="${clean_name}-signed.apk"
    
    read -rp ">> Nama file output [${suggested_filename}]: " custom_filename
    local final_filename="${custom_filename:-$suggested_filename}"
    local final_path="$SIGNED_OUTPUT_DIR/$final_filename"
    
    local use_zipalign="y"
    read -rp ">> Gunakan Zipalign untuk optimasi? (Y/n): " confirm_zipalign
    if [[ "$confirm_zipalign" == "n" || "$confirm_zipalign" == "N" ]]; then
        use_zipalign="n"
    fi
    
    log_msg INFO "File Input  : $(basename "$input_apk")"
    log_msg INFO "File Output : $final_filename"
    log_msg INFO "Zipalign    : $use_zipalign"
    
    if [ -f "$final_path" ]; then
        read -rp ">> ${YELLOW}File output sudah ada. Timpa file? (y/n):${NC} " confirm_overwrite
        if [[ "$confirm_overwrite" != "y" ]]; then
            log_msg INFO "Proses dibatalkan oleh pengguna."
            return
        fi
    fi

    log_msg STEP "Eksekusi Proses Signing"
    local signer_args=("--apks" "$input_apk" "--out" "$SIGNED_OUTPUT_DIR" "--overwrite")
    if [[ "$use_zipalign" == "y" ]]; then
        log_msg INFO "Proses signing akan menyertakan 'zipalign' untuk optimasi RAM."
    else
        signer_args+=("--zipalign" "SKIP")
    fi
    
    if uber-apk-signer "${signer_args[@]}"; then
        # Uber Signer akan membuat file dengan nama `[nama_asli]-aligned-signed.apk`. Kita rename ke nama pilihan kita.
        local signed_file_from_uber="$SIGNED_OUTPUT_DIR/$(basename "$input_apk" .apk)-aligned-signed.apk"
        mv "$signed_file_from_uber" "$final_path" 2>/dev/null
        
        echo
        log_msg SUCCESS "MANTAP JIWA! APK BERHASIL DI-SIGN & DIOPTIMASI!"
        echo -e "${GREEN}${BOLD}File final Anda siap di:${NC}\n${YELLOW}$final_path${NC}"
        echo -e "\n${BLUE}Silakan install file tersebut. Peringatan Play Protect wajar untuk APK modifan.${NC}"
    else
        echo
        log_msg ERROR "GAGAL TOTAL! Proses signing error, Cuy!"
        log_msg INFO "Cek pesan error di atas. Mungkin ada masalah dengan file APK-nya."
    fi
}

# =================================================
#                 PROGRAM UTAMA
# =================================================
main() {
    print_header
    check_dependencies
    mkdir -p "$SIGNED_OUTPUT_DIR"

    local INPUT_APK=""
    if [ -z "$1" ]; then
        interactive_mode || { log_msg INFO "Tidak ada file yang dipilih. Keluar."; exit 0; }
    else
        log_msg STEP "Validasi Input"
        if [ ! -f "$1" ]; then
            log_msg ERROR "File '$1' tidak ditemukan!"
            exit 1
        fi
        INPUT_APK="$1"
        log_msg SUCCESS "File input valid: $(basename "$INPUT_APK")"
    fi

    if [ -n "$INPUT_APK" ]; then
        process_and_sign "$INPUT_APK"
    fi
}

# Jalankan fungsi utama
main "$@"
