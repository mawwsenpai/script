#!/bin/bash

# ===================================================================
#          🔧 MOD-APK.SH v13.1 "Guardian" - Stable Suite 🔧
#
#       Perbaikan bug, alur kerja yang lebih stabil, dan laporan
#            error yang lebih jelas. Tidak ada lagi auto-return.
# ===================================================================

# --- [1] KONFIGURASI ---
readonly TOOLS_DIR="$HOME/tools" # Disesuaikan agar konsisten
readonly APKTOOL_JAR="$TOOLS_DIR/apktool.jar"
readonly SIGN_SCRIPT="$HOME/script/sign-apk.sh" # Asumsi masih di sini
readonly WORKSPACE_DIR="$HOME/apk_projects"
readonly LOG_DIR="$WORKSPACE_DIR/logs"
readonly GEMINI_API_KEY="" # <-- PASTE API KEY ANDA DI SINI

# --- [2] VARIABEL KONTEKS GLOBAL ---
CURRENT_PROJECT_DIR=""
CURRENT_PROJECT_NAME=""
LAST_LOG_FILE="" # Variabel baru untuk melacak log terakhir

# --- [3] FUNGSI UTILITY & UI ---
log_msg() {
    local type="$1" color_code="\033[0m" prefix=""
    case "$type" in
        INFO)    prefix="[INFO]"    color_code="\033[0;36m" ;;
        SUCCESS) prefix="[SUCCESS]" color_code="\033[0;32m" ;;
        WARN)    prefix="[WARN]"    color_code="\033[0;33m" ;;
        ERROR)   prefix="[ERROR]"   color_code="\033[0;31m" ;;
        AI)      prefix="[AI-BOT]"  color_code="\033[0;35m" ;;
        STEP)    prefix="[STEP]"    color_code="\033[1;34m" ;;
    esac
    echo -e "$(date '+%H:%M:%S') ${color_code}${prefix}\033[0m $2"
}

print_header() {
    clear
    echo -e "\033[0;34m==================================================================\033[0m"
    echo -e "\033[0;32m       🔧 MOD-APK.SH v13.1 \"Guardian\" - Stable Suite 🔧\033[0m"
    echo -e "\033[0;34m==================================================================\033[0m"
    if [ -n "$CURRENT_PROJECT_NAME" ]; then
        echo -e "\033[0;33m🚀 Proyek Aktif: $CURRENT_PROJECT_NAME\033[0m\n"
    else
        echo -e "\033[0;33m👻 Belum ada proyek aktif. Pilih dari menu di bawah.\033[0m\n"
    fi
}

# FUNGSI BARU: Jeda, menunggu input user sebelum lanjut
pause_for_user() {
    echo -e "\n\033[0;33mTekan [ENTER] untuk kembali ke dasbor...\033[0m"
    read -r
}

check_deps() {
    # ... (fungsi ini tidak perlu diubah, tetap sama)
    log_msg INFO "Memeriksa semua alat tempur..."
    local all_ok=1
    command -v java &>/dev/null || { log_msg ERROR "Java (JDK) tidak ditemukan!"; all_ok=0; }
    [ -f "$APKTOOL_JAR" ] || { log_msg ERROR "Apktool JAR tidak ditemukan!"; all_ok=0; }
    [ -f "$SIGN_SCRIPT" ] || { log_msg ERROR "Sign Script tidak ditemukan!"; all_ok=0; }
    command -v xmllint &>/dev/null || { log_msg ERROR "xmllint tidak ditemukan! (pkg i libxml2-utils)"; all_ok=0; }
    [ $all_ok -eq 0 ] && { log_msg ERROR "Sistem belum siap! Install kebutuhan di atas."; exit 1; }
    log_msg SUCCESS "Semua alat tempur siap!" && sleep 1
}

find_apk_path() {
    # ... (fungsi ini tidak perlu diubah, tetap sama)
    local file_name="$1"
    for dir in "." "$HOME/storage/downloads" "$HOME/storage/shared" "$HOME/downloads"; do
        [ -f "$dir/$file_name" ] && { echo "$dir/$file_name"; return 0; }
    done
    return 1
}


# --- [4] FUNGSI MANAJEMEN PROYEK (DENGAN PERBAIKAN) ---
select_or_create_project() {
    # ... (logika internal sama, hanya pemanggilan pause_for_user yang penting)
    print_header
    log_msg STEP "Pilih Proyek atau Bongkar APK Baru"
    echo "Daftar proyek yang ada di workspace:"
    local projects=("$WORKSPACE_DIR"/*/)
    if [ ${#projects[@]} -eq 1 ] && [[ "${projects[0]}" == "$WORKSPACE_DIR/*/" ]]; then
        echo "  (Workspace masih kosong)"
        decompile_new_apk
    else
        select project in "${projects[@]##*/}" "--- BONGKAR APK BARU ---"; do
            if [[ "$project" == "--- BONGKAR APK BARU ---" ]]; then
                decompile_new_apk
                break
            elif [ -n "$project" ]; then
                CURRENT_PROJECT_DIR="$WORKSPACE_DIR/$project"
                CURRENT_PROJECT_NAME="$project"
                log_msg SUCCESS "Proyek '$CURRENT_PROJECT_NAME' telah diaktifkan."
                break
            else
                log_msg WARN "Pilihan tidak valid."
            fi
        done
    fi
}

decompile_new_apk() {
    read -p ">> Masukkan nama file APK (contoh: game.apk): " apk_file
    [ -z "$apk_file" ] && { log_msg ERROR "Nama file jangan kosong!"; return; }
    
    local input_path=$(find_apk_path "$apk_file")
    if [ $? -ne 0 ]; then log_msg ERROR "File '$apk_file' tidak ditemukan!"; return; fi
    
    log_msg SUCCESS "File ditemukan di: $input_path"
    local apk_name=$(basename "$input_path" .apk)
    local project_dir="$WORKSPACE_DIR/${apk_name}-PHOENIX"
    local log_file="$LOG_DIR/${apk_name}_decompile.log"
    LAST_LOG_FILE="$log_file" # UPDATE LOG TERAKHIR

    if [ -d "$project_dir" ]; then
        log_msg WARN "Folder proyek '$project_dir' sudah ada. Proses dibatalkan."
        return
    fi

    log_msg INFO "Membongkar '$apk_name.apk'. Ini bisa lama..."
    if java -jar "$APKTOOL_JAR" d "$input_path" -f -o "$project_dir" &> "$log_file"; then
        CURRENT_PROJECT_DIR="$project_dir"
        CURRENT_PROJECT_NAME=$(basename "$project_dir")
        log_msg SUCCESS "SUKSES BONGKAR! Proyek '$CURRENT_PROJECT_NAME' sekarang aktif."
    else
        log_msg ERROR "GAGAL BONGKAR! Terjadi masalah saat dekompilasi."
        log_msg INFO "Berikut adalah bagian akhir dari log error untuk analisis:"
        echo -e "\033[0;31m"
        tail -n 15 "$log_file"
        echo -e "\033[0m"
        log_msg INFO "Log lengkap tersimpan di: $log_file"
    fi
}

delete_project() {
    # ... (fungsi ini tidak perlu diubah, tetap sama)
    if [ -z "$CURRENT_PROJECT_DIR" ]; then log_msg ERROR "Tidak ada proyek yang aktif untuk dihapus."; return; fi
    read -p ">> Yakin ingin menghapus proyek '$CURRENT_PROJECT_NAME' secara permanen? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm -rf "$CURRENT_PROJECT_DIR"
        log_msg SUCCESS "Proyek '$CURRENT_PROJECT_NAME' telah dihapus."
        CURRENT_PROJECT_DIR=""
        CURRENT_PROJECT_NAME=""
    else
        log_msg INFO "Penghapusan dibatalkan."
    fi
}


# --- [5] FUNGSI REBUILD (DENGAN PERBAIKAN LOG) ---
pre_rebuild_check() {
    # ... (fungsi ini tidak perlu diubah, tetap sama)
    local project_dir="$1"
    log_msg STEP "Memulai Pre-flight Check untuk '$CURRENT_PROJECT_NAME'"
    local check_ok=1

    # 1. Validasi & Perbaikan XML
    log_msg INFO "[1/3] Memeriksa & memperbaiki kesehatan file XML..."
    find "$project_dir/res" -type f -name "*.xml" -print0 | while IFS= read -r -d '' xml_file; do
        sed -i 's/&(?![a-zA-Z0-9#]*;)/&amp;/g' "$xml_file"
        if ! xmllint --noout "$xml_file" >/dev/null 2>&1; then
            log_msg ERROR "File XML korup ditemukan: $xml_file"
            xmllint --noout "$xml_file" # Tampilkan error spesifik
            check_ok=0
        fi
    done
    [ $check_ok -eq 1 ] && log_msg SUCCESS "File XML sehat!"

    # ... (sisa fungsi sama)
    log_msg INFO "[2/3] Membersihkan direktori framework untuk stabilitas..."
    java -jar "$APKTOOL_JAR" empty-framework-dir --force >/dev/null 2>&1
    log_msg SUCCESS "Framework dibersihkan."
    
    log_msg INFO "[3/3] Menjalankan validasi akhir..."
    [ $check_ok -eq 0 ] && { log_msg ERROR "Pre-flight Check GAGAL. Rebuild dibatalkan."; return 1; }
    
    log_msg SUCCESS "Pre-flight Check LULUS! Sistem siap untuk merakit ulang."
    return 0
}

rebuild_project() {
    if [ -z "$CURRENT_PROJECT_DIR" ]; then log_msg ERROR "Tidak ada proyek aktif untuk dirakit."; return; fi
    
    if pre_rebuild_check "$CURRENT_PROJECT_DIR"; then
        read -p ">> Nama file APK keluaran (tanpa .apk) [${CURRENT_PROJECT_NAME}-Mod]: " custom_name
        local rebuilt_apk="${WORKSPACE_DIR}/${custom_name:-${CURRENT_PROJECT_NAME}-Mod}.apk"
        local log_file="$LOG_DIR/$(basename "$rebuilt_apk" .apk)_rebuild.log"
        LAST_LOG_FILE="$log_file" # UPDATE LOG TERAKHIR
        
        log_msg STEP "Merakit ulang '$CURRENT_PROJECT_NAME'. Ini bisa lama..."
        if java -jar "$APKTOOL_JAR" b "$CURRENT_PROJECT_DIR" -f -o "$rebuilt_apk" &> "$log_file"; then
            log_msg SUCCESS "SUKSES REBUILD!"
            log_msg STEP "Menandatangani APK..."
            if "$SIGN_SCRIPT" "$rebuilt_apk"; then
                log_msg SUCCESS "APK SIAP! Proses Selesai."
            else
                log_msg ERROR "Signing gagal!"
            fi
        else
            log_msg ERROR "GAGAL REBUILD! Terjadi masalah saat perakitan."
            log_msg INFO "Berikut adalah bagian akhir dari log error untuk analisis:"
            echo -e "\033[0;31m"
            tail -n 15 "$log_file"
            echo -e "\033[0m"
            log_msg INFO "Log lengkap tersimpan di: $log_file"
        fi
    fi
}

# --- [6] FUNGSI MENU MODDING (RUANG OPERASI) ---
# Salin fungsi lengkap dari script v12.0 ke sini
modding_menu() {
    # ...
    # Pastikan di akhir fungsi ini tidak ada 'pause_for_user'
    # karena akan ditangani oleh main loop
    # ...
    return
}

# --- [7] EKSEKUSI UTAMA (DENGAN PERBAIKAN ALUR) ---
main() {
    mkdir -p "$WORKSPACE_DIR" "$LOG_DIR"
    check_deps
    
    while true; do
        print_header
        echo -e "\033[0;32m--- DASBOR UTAMA ---\033[0m"
        echo "1. Pilih Proyek / Bongkar APK Baru"
        echo "2. Masuk Ruang Operasi (Modding)"
        echo "3. Cek & Rakit Ulang Proyek (Rebuild)"
        echo "4. Hapus Proyek Aktif"
        echo "5. Lihat Log Terakhir (Jika Gagal)"
        echo "9. Keluar"
        read -p ">> Masukkan pilihan: " choice
        
        # Jalankan aksi berdasarkan pilihan
        case $choice in
            1) select_or_create_project ;;
            2) 
                if [ -n "$CURRENT_PROJECT_DIR" ]; then
                    modding_menu "$CURRENT_PROJECT_DIR"
                    continue # Langsung kembali ke menu tanpa jeda
                else
                    log_msg ERROR "Pilih proyek dulu!"
                fi
                ;;
            3) rebuild_project ;;
            4) delete_project ;;
            5) 
                if [ -n "$LAST_LOG_FILE" ] && [ -f "$LAST_LOG_FILE" ]; then
                    log_msg INFO "Menampilkan log terakhir dari: $LAST_LOG_FILE"
                    less "$LAST_LOG_FILE" # 'less' lebih baik dari 'cat' karena bisa di-scroll
                else
                    log_msg WARN "Tidak ada log terakhir yang tercatat."
                fi
                ;;
            9) log_msg INFO "Sampai jumpa lagi!"; exit 0 ;;
            *) log_msg WARN "Pilihan tidak valid!" ;;
        esac

        # INI PERBAIKAN UTAMANYA: Jeda hanya setelah aksi selesai
        pause_for_user
    done
}

main
