#!/bin/bash

# =================================================================================
#      🔧 MOD-APK Edisi PRO - Workspace Modding Terintegrasi 🔧
# =================================================================================
# Deskripsi:
# Rombakan total dengan UI profesional yang serasi dengan Maww-Toolkit PRO.
# Dilengkapi "Ruang Operasi" dengan fitur modding esensial dan alur kerja
# yang lebih stabil serta intuitif.
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
readonly WORKSPACE_DIR="$HOME/apk_projects"
readonly LOG_DIR="$WORKSPACE_DIR/logs"

# --- [3] VARIABEL KONTEKS GLOBAL ---
CURRENT_PROJECT_DIR=""
CURRENT_PROJECT_NAME=""
LAST_LOG_FILE=""

# --- [4] FUNGSI UTILITY & UI ---
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
    local title="$1"
    clear
    echo -e "${CYAN}${BOLD}"
    echo '  █▀▄▀█ █▀█ █▀▄  ▄▀█ █▀▄ █▄█  █▀█ █▀█ █▀'
    echo '  █░▀░█ █▄█ █▄▀  █▀█ █▄▀ ░█░  █▀▀ █▄█ ▄█'
    echo -e "${RED}-----------------------------------------------------------${NC}"
    if [ -n "$CURRENT_PROJECT_NAME" ]; then
        echo -e "${BOLD}${WHITE}  ${title} ${GRAY}| ${YELLOW}🚀 Proyek Aktif: $CURRENT_PROJECT_NAME${NC}"
    else
        echo -e "${BOLD}${WHITE}  ${title} ${GRAY}| ${RED}👻 Belum ada proyek aktif${NC}"
    fi
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo
}

pause_for_user() {
    echo
    read -rp "${YELLOW}Tekan [ENTER] untuk kembali...${NC}"
}

check_deps() {
    print_header "Pengecekan Sistem"
    log_msg INFO "Memeriksa semua alat tempur..."
    local all_ok=1
    command -v java &>/dev/null || { log_msg ERROR "Java (JDK) tidak ditemukan!"; all_ok=0; }
    command -v apktool &>/dev/null || { log_msg ERROR "Apktool tidak ditemukan! Jalankan Toolkit."; all_ok=0; }
    command -v uber-apk-signer &>/dev/null || { log_msg ERROR "Uber APK Signer tidak ditemukan! Jalankan Toolkit."; all_ok=0; }
    command -v xmllint &>/dev/null || { log_msg ERROR "xmllint hilang! Coba 'pkg i libxml2-utils'"; all_ok=0; }
    
    if [ $all_ok -eq 0 ]; then
        log_msg ERROR "Sistem belum siap! Lengkapi kebutuhan di atas."
        exit 1
    fi
    log_msg SUCCESS "Semua alat tempur utama siap!"
    
    # Cek tools opsional untuk Ruang Operasi
    if ! command -v micro &>/dev/null && ! command -v mc &>/dev/null; then
        log_msg WARN "Editor 'micro' atau 'mc' tidak ditemukan. Fitur edit di Ruang Operasi terbatas."
    fi
    sleep 2
}

find_apk_path() {
    local file_name="$1"
    log_msg INFO "Mencari '$file_name' di direktori umum..."
    for dir in "." "$HOME/storage/downloads" "$HOME/storage/shared" "$HOME/downloads"; do
        if [ -f "$dir/$file_name" ]; then
            echo "$dir/$file_name"
            return 0
        fi
    done
    # Jika tidak ketemu, tanya user
    log_msg WARN "File tidak ditemukan di lokasi umum."
    read -rp ">> Masukkan path lengkap ke file APK: " manual_path
    if [ -f "$manual_path" ]; then
        echo "$manual_path"
        return 0
    fi
    return 1
}

# --- [5] FUNGSI MANAJEMEN PROYEK ---
select_or_create_project() {
    print_header "Manajer Proyek"
    echo -e "${BOLD}${BLUE}PILIH PROYEK YANG ADA ATAU BONGKAR BARU:${NC}"
    local projects=("$WORKSPACE_DIR"/*/)
    if [ ${#projects[@]} -eq 1 ] && [[ "${projects[0]}" == "$WORKSPACE_DIR/*/" ]]; then
        echo "  (Workspace masih kosong, mari kita bongkar APK baru!)"
        echo
        decompile_new_apk
    else
        local options=()
        for p in "${projects[@]}"; do
            options+=("$(basename "$p")")
        done
        options+=("${GREEN}--- BONGKAR APK BARU ---${NC}")
        options+=("${RED}--- BATAL ---${NC}")

        select project in "${options[@]}"; do
            case "$project" in
                "${GREEN}--- BONGKAR APK BARU ---${NC}")
                    decompile_new_apk
                    break ;;
                "${RED}--- BATAL ---${NC}")
                    break ;;
                *)
                    if [ -n "$project" ]; then
                        CURRENT_PROJECT_DIR="$WORKSPACE_DIR/$project"
                        CURRENT_PROJECT_NAME="$project"
                        log_msg SUCCESS "Proyek '$CURRENT_PROJECT_NAME' telah diaktifkan."
                        break
                    else
                        log_msg WARN "Pilihan tidak valid."
                    fi
                    ;;
            esac
        done
    fi
}

decompile_new_apk() {
    read -rp ">> Masukkan nama file APK (contoh: game.apk): " apk_file
    [ -z "$apk_file" ] && { log_msg ERROR "Nama file jangan kosong!"; return; }
    
    local input_path
    input_path=$(find_apk_path "$apk_file")
    if [ $? -ne 0 ]; then log_msg ERROR "File '$apk_file' tidak ditemukan!"; return; fi
    
    log_msg SUCCESS "File ditemukan di: ${GRAY}$input_path${NC}"
    local apk_name=$(basename "$input_path" .apk)
    local project_dir="$WORKSPACE_DIR/${apk_name}-MOD"
    local log_file="$LOG_DIR/${apk_name}_decompile.log"
    LAST_LOG_FILE="$log_file"

    if [ -d "$project_dir" ]; then
        log_msg WARN "Folder proyek '${apk_name}-MOD' sudah ada. Proses dibatalkan."
        return
    fi

    log_msg STEP "Membongkar '$apk_name.apk'. Ini bisa lama, sabar ya..."
    if apktool d "$input_path" -f -o "$project_dir" &> "$log_file"; then
        CURRENT_PROJECT_DIR="$project_dir"
        CURRENT_PROJECT_NAME=$(basename "$project_dir")
        log_msg SUCCESS "PROYEK '$CURRENT_PROJECT_NAME' BERHASIL DIBUAT & SEKARANG AKTIF!"
    else
        log_msg ERROR "GAGAL BONGKAR! Cek log untuk detail."
        echo -e "${RED}"
        tail -n 15 "$log_file"
        echo -e "${NC}"
        log_msg INFO "Log lengkap tersimpan di: ${GRAY}$log_file${NC}"
    fi
}

# --- [6] FUNGSI RUANG OPERASI (MODDING) ---
modding_menu() {
    while true; do
        print_header "Ruang Operasi"
        echo -e "${BOLD}${BLUE}PILIH ALAT BANTU MODDING:${NC}"
        echo "  ${CYAN}1${NC} - Buka di Editor Kode (micro / mc)"
        echo "  ${CYAN}2${NC} - Edit Cepat AndroidManifest.xml"
        echo "  ${CYAN}3${NC} - Cari Teks/String di Proyek"
        echo "  ${CYAN}4${NC} - Jelajahi Direktori 'res'"
        echo "  ${CYAN}9${NC} - ${RED}Kembali ke Dasbor Utama${NC}"

        read -rp $'\n>> Masukkan pilihan: ' choice
        
        case $choice in
            1)
                log_msg STEP "Mencoba membuka editor..."
                if command -v micro &>/dev/null; then micro "$CURRENT_PROJECT_DIR"; elif command -v mc &>/dev/null; then mc "$CURRENT_PROJECT_DIR"; else log_msg ERROR "Tidak ada editor (micro/mc) yang terinstal."; fi
                ;;
            2)
                local manifest_file="$CURRENT_PROJECT_DIR/AndroidManifest.xml"
                log_msg STEP "Membuka AndroidManifest.xml..."
                if [ -f "$manifest_file" ]; then if command -v micro &>/dev/null; then micro "$manifest_file"; elif command -v mc &>/dev/null; then nano "$manifest_file"; else log_msg ERROR "Tidak ada editor."; fi; else log_msg ERROR "File Manifest tidak ditemukan!"; fi
                ;;
            3)
                read -rp ">> Teks yang ingin dicari (case-sensitive): " search_term
                if [ -n "$search_term" ]; then
                    log_msg STEP "Mencari '$search_term' di file smali dan xml..."
                    echo -e "${GRAY}---------------- HASIL PENCARIAN ----------------${NC}"
                    grep -r --color=always "$search_term" "$CURRENT_PROJECT_DIR/smali" "$CURRENT_PROJECT_DIR/res"
                    echo -e "${GRAY}------------------- SELESAI -------------------${NC}"
                    pause_for_user
                fi
                ;;
            4)
                log_msg STEP "Menampilkan isi direktori 'res'..."
                ls -F "$CURRENT_PROJECT_DIR/res"
                pause_for_user
                ;;
            9) break ;;
            *) log_msg WARN "Pilihan tidak valid!" ;;
        esac
    done
}


# --- [7] FUNGSI REBUILD & SIGN ---
rebuild_project() {
    if [ -z "$CURRENT_PROJECT_DIR" ]; then log_msg ERROR "Tidak ada proyek aktif untuk dirakit."; return; fi
    
    # Pre-flight check
    log_msg STEP "Memulai Pre-flight Check untuk '$CURRENT_PROJECT_NAME'"
    find "$CURRENT_PROJECT_DIR/res" -type f -name "*.xml" -print0 | xargs -0 -I {} sed -i 's/&(?![a-zA-Z0-9#]*;)/&amp;/g' '{}'
    apktool empty-framework-dir --force >/dev/null 2>&1
    log_msg SUCCESS "Pre-flight Check LULUS! Siap merakit."

    read -rp ">> Nama file APK keluaran (tanpa .apk) [${CURRENT_PROJECT_NAME}-Rebuilt]: " custom_name
    local rebuilt_apk="${WORKSPACE_DIR}/${custom_name:-${CURRENT_PROJECT_NAME}-Rebuilt}.apk"
    local log_file="$LOG_DIR/$(basename "$rebuilt_apk" .apk)_rebuild.log"
    LAST_LOG_FILE="$log_file"
    
    log_msg STEP "Merakit ulang '$CURRENT_PROJECT_NAME'. Ini juga bisa lama..."
    if apktool b "$CURRENT_PROJECT_DIR" -f -o "$rebuilt_apk" &> "$log_file"; then
        log_msg SUCCESS "BERHASIL DIRAKIT! File mentah ada di: ${GRAY}$rebuilt_apk${NC}"
        log_msg STEP "Menandatangani APK dengan uber-apk-signer..."
        if uber-apk-signer --apks "$rebuilt_apk" &>> "$log_file"; then
            log_msg SUCCESS "APK FINAL SIAP! Proses Selesai Total. Cari file dengan akhiran '-aligned-signed.apk'."
        else
            log_msg ERROR "SIGNING GAGAL! Cek log untuk detail."
        fi
    else
        log_msg ERROR "GAGAL REBUILD! Cek log untuk detail."
        echo -e "${RED}"; tail -n 15 "$log_file"; echo -e "${NC}"
        log_msg INFO "Log lengkap tersimpan di: ${GRAY}$log_file${NC}"
    fi
}


# --- [8] EKSEKUSI UTAMA ---
main() {
    mkdir -p "$WORKSPACE_DIR" "$LOG_DIR"
    check_deps
    
    while true; do
        print_header "Dasbor Utama"
        echo -e "${BOLD}${BLUE}PILIH AKSI:${NC}"
        echo "  ${CYAN}1${NC} - Pilih Proyek / Bongkar APK Baru"
        echo "  ${CYAN}2${NC} - ${PURPLE}Masuk Ruang Operasi (Modding)${NC}"
        echo "  ${CYAN}3${NC} - ${GREEN}Cek & Rakit Ulang Proyek${NC}"
        echo
        echo "  ${CYAN}4${NC} - Lihat Log Gagal Terakhir"
        echo "  ${CYAN}5${NC} - ${RED}Hapus Proyek Aktif${NC}"
        echo "  ${CYAN}9${NC} - Keluar"
        
        read -rp $'\n>> Masukkan pilihan: ' choice
        
        case $choice in
            1) select_or_create_project; pause_for_user ;;
            2) 
                if [ -n "$CURRENT_PROJECT_DIR" ]; then
                    modding_menu
                else
                    log_msg ERROR "Pilih atau bongkar proyek dulu!"
                    pause_for_user
                fi
                ;;
            3) rebuild_project; pause_for_user ;;
            4) 
                if [ -f "$LAST_LOG_FILE" ]; then
                    log_msg INFO "Menampilkan log terakhir dari: ${GRAY}$LAST_LOG_FILE${NC}"
                    less "$LAST_LOG_FILE"
                else
                    log_msg WARN "Tidak ada log terakhir yang tercatat."
                    pause_for_user
                fi
                ;;
            5) 
                if [ -n "$CURRENT_PROJECT_DIR" ]; then
                    read -p ">> Yakin ingin menghapus proyek '$CURRENT_PROJECT_NAME' secara permanen? (y/n): " confirm
                    if [[ "$confirm" == "y" ]]; then
                        rm -rf "$CURRENT_PROJECT_DIR"
                        log_msg SUCCESS "Proyek '$CURRENT_PROJECT_NAME' telah dihapus."
                        CURRENT_PROJECT_DIR=""
                        CURRENT_PROJECT_NAME=""
                    else
                        log_msg INFO "Penghapusan dibatalkan."
                    fi
                else
                    log_msg ERROR "Tidak ada proyek yang aktif untuk dihapus."
                fi
                pause_for_user
                ;;
            9) log_msg INFO "Sampai jumpa lagi, Modder!"; exit 0 ;;
            *) log_msg WARN "Pilihan tidak valid!"; sleep 1 ;;
        esac
    done
}

main