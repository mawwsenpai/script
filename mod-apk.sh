readonly APKTOOL_JAR="$HOME/script/apktool.jar"
readonly SIGN_SCRIPT="$HOME/script/sign-apk.sh"

# Direktori kerja (tempat menyimpan proyek hasil bongkaran)
readonly WORKSPACE_DIR="$HOME/apk_projects"
readonly LOG_DIR="$WORKSPACE_DIR/logs"

# Direktori untuk script patcher otomatis (contoh: patch-pou.sh)
readonly PATCHER_DIR="$HOME/script/game"

# [OPSIONAL] Konfigurasi untuk Integrasi AI Gemini
# 1. Dapatkan API Key Anda dari Google AI Studio.
# 2. Masukkan key tersebut di sini.
# 3. Jika dikosongkan, fitur AI Gemini akan dinonaktifkan.
readonly GEMINI_API_KEY="" # <--- PASTE API KEY ANDA DI SINI
# --------------------------------------------------------------------


# --- [2] FUNGSI UTILITY & UI ---

# Fungsi logging terpusat untuk output yang konsisten dan berwarna.
log_msg() {
    local type="$1" color_code="\033[0m" prefix=""
    case "$type" in
        INFO)    prefix="[INFO]"    color_code="\033[0;36m" ;; # Cyan
        SUCCESS) prefix="[SUCCESS]" color_code="\033[0;32m" ;; # Green
        WARN)    prefix="[WARN]"    color_code="\033[0;33m" ;; # Yellow
        ERROR)   prefix="[ERROR]"   color_code="\033[0;31m" ;; # Red
        AI)      prefix="[AI-BOT]"  color_code="\033[0;35m" ;; # Magenta
    esac
    echo -e "$(date '+%H:%M:%S') ${color_code}${prefix}\033[0m $2"
}

# Menampilkan header script.
print_header() {
    clear
    echo -e "\033[0;34m==================================================================\033[0m"
    echo -e "\033[0;32m       🔧 MOD-APK.SH v10.0 - The Definitive Suite 🔧\033[0m"
    echo -e "\033[0;34m==================================================================\033[0m"
    echo -e "\033[0;33mWorkspace: $WORKSPACE_DIR\033[0m\n"
}

# Memeriksa semua dependensi yang dibutuhkan sebelum script berjalan.
check_deps() {
    log_msg INFO "Memeriksa semua alat tempur..."
    local all_ok=1
    command -v java &>/dev/null || { log_msg ERROR "Java (JDK) tidak ditemukan!"; all_ok=0; }
    [ -f "$APKTOOL_JAR" ] || { log_msg ERROR "Apktool JAR tidak ditemukan di $APKTOOL_JAR"; all_ok=0; }
    [ -f "$SIGN_SCRIPT" ] || { log_msg ERROR "Sign Script tidak ditemukan di $SIGN_SCRIPT"; all_ok=0; }
    command -v xmllint &>/dev/null || { log_msg ERROR "xmllint tidak ditemukan! (pkg i libxml2-utils)"; all_ok=0; }
    
    if [ -n "$GEMINI_API_KEY" ]; then
      command -v jq &>/dev/null || { log_msg WARN "jq tidak ditemukan! (pkg i jq). Fitur AI Gemini butuh ini."; }
    fi

    [ $all_ok -eq 0 ] && { log_msg ERROR "Sistem belum siap! Install kebutuhan di atas."; exit 1; }
    log_msg SUCCESS "Sistem siap tempur!"
}


# --- [3] FUNGSI ALUR KERJA UTAMA ---

# Fungsi utama yang mengatur seluruh proses dari awal sampai akhir.
main_workflow() {
    print_header
    read -p ">> Masukkan nama file APK (contoh: game.apk): " apk_file
    [ -z "$apk_file" ] && { log_msg ERROR "Nama file jangan kosong!"; return; }
    
    local input_path="$apk_file"
    if [ ! -f "$input_path" ]; then
        log_msg ERROR "File '$apk_file' tidak ditemukan di direktori saat ini!"
        return
    fi

    local apk_name=$(basename "$input_path" .apk)
    local project_dir="$WORKSPACE_DIR/${apk_name}-MODIF"
    local log_file="$LOG_DIR/${apk_name}_decompile_$(date +%F_%H-%M-%S).log"

    log_msg INFO "Membongkar '$apk_name.apk' ke '$project_dir'..."
    log_msg WARN "Log lengkap disimpan di: $log_file"

    if java -jar "$APKTOOL_JAR" d "$input_path" -f -o "$project_dir" &> "$log_file"; then
        log_msg SUCCESS "SUKSES BONGKAR! Proyek siap dioperasikan."
        
        # Tampilkan menu modding setelah berhasil decompile
        modding_menu "$project_dir"

        # Proses rebuild setelah modding selesai
        if [ -d "$project_dir" ]; then # Cek apakah folder proyek masih ada (belum dihapus)
            log_msg INFO "Memulai proses rebuild untuk '$apk_name'..."
            if validate_xml "$project_dir"; then
                read -p ">> Masukkan nama file APK keluaran (tanpa .apk) [${apk_name}-Mod]: " custom_name
                local rebuilt_apk="${WORKSPACE_DIR}/${custom_name:-${apk_name}-Mod}.apk"
                log_msg INFO "Merakit ulang ke '$(basename "$rebuilt_apk")'..."
                if java -jar "$APKTOOL_JAR" b "$project_dir" -f -o "$rebuilt_apk"; then
                    log_msg SUCCESS "SUKSES REBUILD!"
                    log_msg INFO "Menandatangani APK..."
                    if ! "$SIGN_SCRIPT" "$rebuilt_apk"; then log_msg ERROR "Signing gagal!"; fi
                    log_msg INFO "Membersihkan folder proyek..."
                    rm -rf "$project_dir"
                else
                    log_msg ERROR "GAGAL REBUILD!"
                fi
            else
                log_msg ERROR "Rebuild dibatalkan karena ada error pada XML."
            fi
        fi
    else
        log_msg ERROR "GAGAL BONGKAR! Cek log untuk detail:"
        tail -n 10 "$log_file"
    fi
}

# Memvalidasi semua file XML di dalam proyek.
validate_xml() {
    log_msg INFO "Memeriksa kesehatan file XML..."
    while IFS= read -r -d '' xml_file; do
        if ! xmllint --noout "$xml_file" >/dev/null 2>&1; then
            log_msg ERROR "File XML korup ditemukan: $xml_file"
            xmllint --noout "$xml_file"
            return 1
        fi
    done < <(find "$1/res" -type f -name "*.xml" -print0)
    log_msg SUCCESS "Semua file XML sehat!"
    return 0
}


# --- [4] FUNGSI MENU MODDING & AI ---

# Menu utama setelah dekompilasi berhasil.
modding_menu() {
    local project_dir="$1"
    while true; do
        print_header
        log_msg INFO "Proyek aktif: \033[0;33m$(basename "$project_dir")\033[0m"
        echo -e "\n\033[0;34m--- MENU MODDING ---\033[0m"
        echo "1. 🤖 Asisten AI (Lokal)       - Cari patch otomatis (Iklan, Premium)"
        echo "2. ✍️  Edit Manual              - Buka file/folder dengan nano/grep"
        echo "3. 📂 Terapkan Patch Otomatis    - Jalankan script dari folder '$PATCHER_DIR'"
        echo "4. 🧠 Konsultasi AI Gemini (Online) - Minta AI menjelaskan kode Smali"
        echo "5. ✅ Selesai Modding & Lanjut Rebuild"
        read -p ">> Pilihan Anda [1-5]: " action
        case $action in
            1) ai_assistant_local "$project_dir" ;;
            2) manual_editing_menu "$project_dir" ;;
            3) auto_patcher_menu "$project_dir" ;;
            4) ai_gemini_explain "$project_dir" ;;
            5) break ;;
            *) log_msg WARN "Pilihan tidak valid!" ;;
        esac
    done
}

# Asisten AI Lokal: mencari pola kode umum secara offline.
ai_assistant_local() {
    # ... (Kode fungsi ai_assistant_local dari jawaban sebelumnya ada di sini) ...
    # ... Ini sama persis dengan yang sudah kita buat ...
    log_msg AI "Fitur Asisten AI Lokal belum diimplementasikan di template ini."
    log_msg AI "Silakan salin kode dari diskusi kita sebelumnya."
    sleep 2
}

# Menu untuk Edit Manual (Grep & Nano)
manual_editing_menu() {
    # ... (Kode fungsi manual_editing_menu dari jawaban sebelumnya) ...
    log_msg INFO "Fitur Edit Manual belum diimplementasikan di template ini."
    sleep 2
}

# Menu untuk Auto Patcher
auto_patcher_menu() {
    # ... (Kode fungsi auto_patcher_menu dari jawaban sebelumnya) ...
    log_msg INFO "Fitur Auto Patcher belum diimplementasikan di template ini."
    sleep 2
}

# Integrasi AI Gemini: meminta AI untuk menjelaskan kode Smali.
ai_gemini_explain() {
    local project_dir="$1"
    if [ -z "$GEMINI_API_KEY" ]; then
        log_msg ERROR "API Key Gemini belum diatur di bagian Konfigurasi script!"
        log_msg ERROR "Fitur ini tidak bisa digunakan."
        sleep 3
        return
    fi
    if ! command -v jq &>/dev/null; then
        log_msg ERROR "Perintah 'jq' tidak ditemukan. Fitur ini memerlukannya. (pkg i jq)"
        sleep 3
        return
    fi

    print_header
    log_msg AI "Konsultasi dengan AI Gemini untuk Analisis Kode."
    read -p ">> Masukkan path ke file Smali di dalam proyek: " smali_file_path
    local full_path="$project_dir/$smali_file_path"

    if [ ! -f "$full_path" ]; then
        log_msg ERROR "File tidak ditemukan: $full_path"
        sleep 2
        return
    fi

    read -p ">> Masukkan nama metode yang ingin dianalisis (contoh: isPremium): " method_name
    
    # Ekstrak seluruh blok metode dari file Smali
    local smali_code
    smali_code=$(awk "/\.method.*$method_name/,/\.end method/" "$full_path")

    if [ -z "$smali_code" ]; then
        log_msg ERROR "Metode '$method_name' tidak ditemukan di dalam file."
        sleep 2
        return
    fi

    log_msg AI "Mengirim kode ke Gemini untuk dianalisis..."
    local prompt="Kamu adalah seorang analis kode Smali profesional. Jelaskan apa fungsi dari metode Smali berikut ini dalam bahasa Indonesia yang mudah dimengerti. Fokus pada logikanya. Kode: \`\`\`smali\n${smali_code}\n\`\`\`"
    local json_payload
    json_payload=$(jq -n --arg text "$prompt" '{contents: [{parts: [{text: $text}]}]}')
    local response
    response=$(curl -s -X POST "https://generativanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${GEMINI_API_KEY}" -H "Content-Type: application/json" -d "$json_payload")
    local explanation
    explanation=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text')

    if [[ -z "$explanation" || "$explanation" == "null" ]]; then
        log_msg ERROR "Gagal mendapatkan respon dari AI. Cek API Key atau koneksi."
    else
        log_msg AI "Hasil Analisis Gemini:"
        echo -e "--------------------------------------------------\n$explanation\n--------------------------------------------------"
    fi
    read -p "Tekan [ENTER] untuk kembali..."
}


# --- [5] EKSEKUSI UTAMA ---
# Blok utama yang menjalankan script.
main() {
    setup_and_check_deps
    while true; do
        print_header
        echo -e "\n\033[0;32m--- MENU UTAMA ---\033[0m"
        echo "1. Bongkar, Modifikasi, dan Rakit Ulang APK"
        echo "9. Keluar"
        read -p ">> Masukkan pilihan: " choice
        case $choice in
            1) main_workflow ;;
            9) log_msg INFO "Sampai jumpa lagi!"; exit 0 ;;
            *) log_msg WARN "Pilihan tidak valid!" ;;
        esac
        echo -e "\n\033[0;33mTekan [ENTER] untuk kembali ke menu utama...\033[0m"
        read -r
    done
}

# Jalankan fungsi utama script.
main
