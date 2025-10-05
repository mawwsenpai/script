#!/bin/bash
# ===================================================================
#           🔧 MOD-APK.SH v10.1 - The Definitive Suite 🔧
#
#   Perbaikan: Mengembalikan dan meningkatkan fitur pencarian APK
#   otomatis di berbagai direktori umum.
# ===================================================================

# --- [1] KONFIGURASI ---
readonly APKTOOL_JAR="$HOME/script/apktool.jar"
readonly SIGN_SCRIPT="$HOME/script/sign-apk.sh"
readonly WORKSPACE_DIR="$HOME/apk_projects"
readonly LOG_DIR="$WORKSPACE_DIR/logs"
readonly PATCHER_DIR="$HOME/script/game"
readonly GEMINI_API_KEY="" # <--- PASTE API KEY ANDA DI SINI

# --- [2] FUNGSI UTILITY & UI ---

# Fungsi logging terpusat
log_msg() {
    local type="$1" color_code="\033[0m" prefix=""
    case "$type" in
        INFO)    prefix="[INFO]"    color_code="\033[0;36m" ;;
        SUCCESS) prefix="[SUCCESS]" color_code="\033[0;32m" ;;
        WARN)    prefix="[WARN]"    color_code="\033[0;33m" ;;
        ERROR)   prefix="[ERROR]"   color_code="\033[0;31m" ;;
        AI)      prefix="[AI-BOT]"  color_code="\033[0;35m" ;;
    esac
    echo -e "$(date '+%H:%M:%S') ${color_code}${prefix}\033[0m $2"
}

# Menampilkan header script
print_header() {
    clear
    echo -e "\033[0;34m==================================================================\033[0m"
    echo -e "\033[0;32m       🔧 MOD-APK.SH v10.1 - The Definitive Suite 🔧\033[0m"
    echo -e "\033[0;34m==================================================================\033[0m"
    echo -e "\033[0;33mWorkspace: $WORKSPACE_DIR\033[0m\n"
}

# Memeriksa semua dependensi
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
}

# ==========================================================
# FUNGSI BARU: PENCARIAN APK OTOMATIS
# ==========================================================
find_apk_path() {
    local file_name="$1"
    
    # Daftar direktori yang akan diperiksa, urut dari yang paling umum
    local search_dirs=(
        "."                             # Direktori saat ini (folder /script)
        "$HOME/storage/downloads"       # Folder Download utama
        "$HOME/storage/shared"          # Penyimpanan Internal
        "$HOME/downloads"               # Folder Download Termux
        ".."                            # Satu folder di atasnya
    )

    log_msg INFO "Mencari '$file_name'..."
    for dir in "${search_dirs[@]}"; do
        if [ -f "$dir/$file_name" ]; then
            echo "$dir/$file_name" # Cetak path lengkap jika ketemu
            return 0 # Keluar dengan status sukses
        fi
    done
    
    return 1 # Keluar dengan status gagal jika tidak ditemukan
}
# ==========================================================


# --- [3] FUNGSI ALUR KERJA UTAMA ---

main_workflow() {
    print_header
    read -p ">> Masukkan nama file APK (contoh: game.apk): " apk_file
    [ -z "$apk_file" ] && { log_msg ERROR "Nama file jangan kosong!"; return; }
    
    # ==========================================================
    # BAGIAN YANG DIPERBARUI: MENGGUNAKAN FUNGSI PENCARIAN
    # ==========================================================
    local input_path
    input_path=$(find_apk_path "$apk_file") # Panggil fungsi detektif

    if [ $? -ne 0 ]; then # Cek apakah fungsi detektif berhasil atau gagal
        log_msg ERROR "File '$apk_file' tidak ditemukan di lokasi mana pun!"
        return
    fi
    
    log_msg SUCCESS "File ditemukan di: $input_path"
    # ==========================================================

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
    local project_dir="$1"
    print_header
    log_msg AI "Asisten AI diaktifkan! Saya akan mencari pola kode umum."
    echo -e "\033[0;36mContoh tujuan: 'hapus iklan', 'buat premium'\033[0m"
    read -p ">> Apa tujuan modding Anda? " objective

    case "$objective" in
        *'iklan'*)
            log_msg AI "Oke, target: Iklan. Mencari metode umum seperti 'loadAd'..."
            local target_files=$(grep -rlwE "loadAd|showAd|loadInterstitial" "$project_dir/smali*")
            if [ -z "$target_files" ]; then
                log_msg WARN "AI: Tidak ditemukan metode iklan umum. Coba cari manual."
                return
            fi
            
            echo "$target_files" | while read -r file; do
                log_msg AI "Menganalisis potensi target di: \033[0;33m$file\033[0m"
                # Cari baris method dan tambahkan 'return-void' setelahnya
                local line_num=$(grep -nE "^\.method.*(loadAd|showAd|loadInterstitial)" "$file" | cut -d: -f1)
                if [ -n "$line_num" ]; then
                    log_msg SUCCESS "AI: Menemukan metode target di baris $line_num."
                    echo -e "\033[0;31m- Kode iklan akan dieksekusi\033[0m"
                    echo -e "\033[0;32m+ Menambahkan 'return-void' untuk melumpuhkan metode\033[0m"
                    read -p ">> Terapkan patch ini? (y/n): " confirm
                    if [[ "$confirm" == "y" ]]; then
                        sed -i.bak "$((line_num+1)) a\ \n    return-void" "$file"
                        log_msg SUCCESS "AI: Patch berhasil diterapkan! (File asli disimpan sebagai .bak)"
                    fi
                fi
            done
            ;;
        *'premium'*)
            log_msg AI "Oke, target: Premium. Mencari metode pengecekan seperti 'isPremium()Z'..."
            # Cari metode yang mengembalikan boolean (Z) dan namanya 'isPremium' atau 'isPro'
            local target_files=$(grep -rlwE "isPremium\(\)Z|isPro\(\)Z" "$project_dir/smali*")
            if [ -z "$target_files" ]; then
                log_msg WARN "AI: Tidak ditemukan metode premium umum. Coba cari manual."
                return
            fi

            echo "$target_files" | while read -r file; do
                log_msg AI "Menganalisis potensi target di: \033[0;33m$file\033[0m"
                local method_start=$(grep -nE "^\.method.*(isPremium|isPro)\(\)Z" "$file" | cut -d: -f1)
                
                if [ -n "$method_start" ]; then
                    local method_end=$(awk "NR >= $method_start && /\\.end method/ {print NR; exit}" "$file")
                    log_msg SUCCESS "AI: Menemukan metode target di baris $method_start."
                    echo -e "\033[0;31m- Kode asli akan mengembalikan status premium saat ini.\033[0m"
                    echo -e "\033[0;32m+ Memaksa metode untuk SELALU mengembalikan 'true'.\033[0m"
                    read -p ">> Terapkan patch ini? (y/n): " confirm
                    if [[ "$confirm" == "y" ]]; then
                        local signature=$(sed -n "${method_start}p" "$file")
                        # Hapus semua isi method dan ganti dengan kode baru
                        sed -i.bak "${method_start},${method_end}d" "$file"
                        echo -e "$signature\n    .locals 1\n\n    const/4 v0, 0x1\n\n    return v0\n.end method" >> "$file"
                        log_msg SUCCESS "AI: Patch berhasil diterapkan! (File asli disimpan sebagai .bak)"
                    fi
                fi
            done
            ;;
        *)
            log_msg WARN "AI: Maaf, saya belum dilatih untuk tujuan '$objective'. Coba gunakan mode manual."
            ;;
    esac
    read -p "Tekan [ENTER] untuk melanjutkan..."
}

# Menu untuk Edit Manual (Grep & Nano)
manual_editing_menu() {
    local project_dir="$1"
    while true; do
        print_header
        log_msg INFO "Anda di 'Ruang Operasi' untuk: \033[0;33m$(basename "$project_dir")\033[0m"
        echo -e "\n\033[0;34m--- MENU EDIT MANUAL ---\033[0m"
        echo "1. Cari Kata Kunci (grep)"
        echo "2. Edit File (nano)"
        echo "3. Kembali ke Menu Modding"
        read -p ">> Pilihan Anda: " choice
        case $choice in
            1)
                read -p ">> Masukkan kata kunci yang ingin dicari: " search_term
                log_msg INFO "Mencari '$search_term'..."
                grep -rni "$search_term" "$project_dir"
                read -p $'\nTekan [ENTER] untuk kembali...'
                ;;
            2)
                read -p ">> Masukkan path file dari dalam proyek: " file_to_edit
                if [ -f "$project_dir/$file_to_edit" ]; then
                    nano "$project_dir/$file_to_edit"
                else
                    log_msg ERROR "File tidak ditemukan!"
                    sleep 2
                fi
                ;;
            3) break ;;
            *) log_msg WARN "Pilihan tidak valid!" ;;
        esac
    done
}

# Menu untuk Auto Patcher
auto_patcher_menu() {
    local project_dir="$1"
    print_header
    log_msg INFO "Menerapkan patch otomatis dari '$PATCHER_DIR'..."
    if [ ! -d "$PATCHER_DIR" ] || [ -z "$(ls -A "$PATCHER_DIR")" ]; then
        log_msg ERROR "Folder patcher '$PATCHER_DIR' kosong atau tidak ditemukan!"
        sleep 3
        return
    fi
    
    log_msg INFO "Patcher yang tersedia:"
    ls -1 "$PATCHER_DIR"
    read -p ">> Masukkan nama patcher yang ingin dijalankan: " patch_script
    local full_patch_path="$PATCHER_DIR/$patch_script"

    if [ -f "$full_patch_path" ]; then
        log_msg INFO "Menjalankan patcher '$patch_script'..."
        if bash "$full_patch_path" "$project_dir"; then
            log_msg SUCCESS "Patcher berhasil dijalankan."
        else
            log_msg ERROR "Patcher selesai dengan error."
        fi
    else
        log_msg ERROR "Script patcher tidak ditemukan!"
    fi
    read -p "Tekan [ENTER] untuk kembali..."
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
    response=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${GEMINI_API_KEY}" -H "Content-Type: application/json" -d "$json_payload")
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
    check_deps
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
