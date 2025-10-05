# --- [1] KONFIGURASI ---
readonly TOOLS_DIR="$HOME/script"
readonly APKTOOL_JAR="$TOOLS_DIR/apktool.jar"
readonly SIGN_SCRIPT="$TOOLS_DIR/sign-apk.sh"
readonly WORKSPACE_DIR="$HOME/apk_projects"
readonly LOG_DIR="$WORKSPACE_DIR/logs"
readonly GEMINI_API_KEY="" # <-- PASTE API KEY ANDA DI SINI

# --- [2] VARIABEL KONTEKS GLOBAL ---
# Variabel ini akan menyimpan status proyek yang sedang aktif
CURRENT_PROJECT_DIR=""
CURRENT_PROJECT_NAME=""

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
    echo -e "\033[0;32m       🔧 MOD-APK.SH v13.0 \"Phoenix\" - Smart Suite 🔧\033[0m"
    echo -e "\033[0;34m==================================================================\033[0m"
    if [ -n "$CURRENT_PROJECT_NAME" ]; then
        echo -e "\033[0;33m🚀 Proyek Aktif: $CURRENT_PROJECT_NAME\033[0m\n"
    else
        echo -e "\033[0;33m👻 Belum ada proyek aktif. Pilih dari menu di bawah.\033[0m\n"
    fi
}

check_deps() {
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
    local file_name="$1"
    for dir in "." "$HOME/storage/downloads" "$HOME/storage/shared" "$HOME/downloads"; do
        [ -f "$dir/$file_name" ] && { echo "$dir/$file_name"; return 0; }
    done
    return 1
}

# --- [4] FUNGSI MANAJEMEN PROYEK ---
select_or_create_project() {
    print_header
    log_msg STEP "Pilih Proyek atau Bongkar APK Baru"
    echo "Daftar proyek yang ada di workspace:"
    local projects=("$WORKSPACE_DIR"/*/)
    if [ ${#projects[@]} -eq 1 ] && [[ "${projects[0]}" == "$WORKSPACE_DIR/*/" ]]; then
        echo "  (Workspace masih kosong)"
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
    # Jika workspace kosong, langsung ke decompile
    [[ "${projects[0]}" == "$WORKSPACE_DIR/*/" ]] && decompile_new_apk
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

    if [ -d "$project_dir" ]; then
        log_msg WARN "Folder proyek '$project_dir' sudah ada. Proses dibatalkan."
        return
    fi

    log_msg INFO "Membongkar '$apk_name.apk' ke '$project_dir'..."
    if java -jar "$APKTOOL_JAR" d "$input_path" -f -o "$project_dir" &> "$log_file"; then
        CURRENT_PROJECT_DIR="$project_dir"
        CURRENT_PROJECT_NAME=$(basename "$project_dir")
        log_msg SUCCESS "SUKSES BONGKAR! Proyek '$CURRENT_PROJECT_NAME' sekarang aktif."
    else
        log_msg ERROR "GAGAL BONGKAR! Cek log: $log_file"
        tail -n 10 "$log_file"
    fi
}

delete_project() {
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

# --- [5] FUNGSI REBUILD & PERBAIKAN OTOMATIS ---
pre_rebuild_check() {
    local project_dir="$1"
    log_msg STEP "Memulai Pre-flight Check untuk '$CURRENT_PROJECT_NAME'"
    local check_ok=1

    # 1. Validasi & Perbaikan XML
    log_msg INFO "[1/3] Memeriksa & memperbaiki kesehatan file XML..."
    find "$project_dir/res" -type f -name "*.xml" -print0 | while IFS= read -r -d '' xml_file; do
        # Auto-fix common issues like unescaped ampersands
        sed -i 's/&(?![a-zA-Z0-9#]*;)/&amp;/g' "$xml_file"
        if ! xmllint --noout "$xml_file" >/dev/null 2>&1; then
            log_msg ERROR "File XML korup ditemukan: $xml_file"
            check_ok=0
        fi
    done
    [ $check_ok -eq 1 ] && log_msg SUCCESS "File XML sehat!"

    # 2. Membersihkan Framework
    log_msg INFO "[2/3] Membersihkan direktori framework untuk stabilitas..."
    if ! java -jar "$APKTOOL_JAR" empty-framework-dir --force >/dev/null 2>&1; then
        log_msg WARN "Gagal membersihkan framework, mungkin tidak masalah."
    else
        log_msg SUCCESS "Framework dibersihkan."
    fi
    
    # 3. Validasi akhir
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
        
        log_msg STEP "Merakit ulang '$CURRENT_PROJECT_NAME'..."
        if java -jar "$APKTOOL_JAR" b "$CURRENT_PROJECT_DIR" -f -o "$rebuilt_apk"; then
            log_msg SUCCESS "SUKSES REBUILD!"
            log_msg STEP "Menandatangani APK..."
            if "$SIGN_SCRIPT" "$rebuilt_apk"; then
                log_msg SUCCESS "APK SIAP! Tersimpan di: $rebuilt_apk"
            else
                log_msg ERROR "Signing gagal!"
            fi
        else
            log_msg ERROR "GAGAL REBUILD! Error terjadi saat perakitan."
        fi
    fi
}

# --- [6] FUNGSI MENU MODDING (RUANG OPERASI) ---
# Fungsi modding_menu dan semua sub-menunya (AI Lokal, Edit Manual, dll)
# dapat disalin dari script v12.0 Anda dan ditempelkan di sini.
# Perubahan kecil: ganti 'break' dengan 'return' untuk keluar dari menu.
# Contoh:
modding_menu() {
    local project_dir="$1"
    while true; do
        print_header
        log_msg INFO "Anda di 'Ruang Operasi' untuk: \033[0;33m$(basename "$project_dir")\033[0m"
        echo -e "\n\033[0;34m--- RUANG OPERASI ---\033[0m"
        echo "1. 🤖 Asisten AI (Lokal)       - Cari patch otomatis (Iklan, Premium, Koin)"
        echo "2. ✍️  Edit Manual              - Buka file/folder dengan nano/grep"
        echo "3. 🧠 Konsultasi AI Gemini (Online) - Minta AI menjelaskan atau membuat patch"
        echo "4. ✅ Keluar dari Ruang Operasi"
        read -p ">> Pilihan Anda [1-4]: " action
        case $action in
            1) echo "Fungsi AI Lokal dipanggil..." && sleep 1 ;; # Ganti dengan fungsi asli
            2) echo "Fungsi Edit Manual dipanggil..." && sleep 1 ;; # Ganti dengan fungsi asli
            3) echo "Fungsi AI Gemini dipanggil..." && sleep 1 ;; # Ganti dengan fungsi asli
            4) return ;;
            *) log_msg WARN "Pilihan tidak valid!" ;;
        esac
    done
}


# --- [7] EKSEKUSI UTAMA ---
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
        echo "9. Keluar"
        read -p ">> Masukkan pilihan: " choice
        case $choice in
            1) select_or_create_project ;;
            2) [ -n "$CURRENT_PROJECT_DIR" ] && modding_menu "$CURRENT_PROJECT_DIR" || log_msg ERROR "Pilih proyek dulu!" ;;
            3) rebuild_project ;;
            4) delete_project ;;
            9) log_msg INFO "Sampai jumpa lagi!"; exit 0 ;;
            *) log_msg WARN "Pilihan tidak valid!" ;;
        esac
        echo -e "\n\033[0;33mTekan [ENTER] untuk kembali ke dasbor...\033[0m"
        read -r
    done
}

main
