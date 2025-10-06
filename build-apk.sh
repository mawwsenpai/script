#!/bin/bash

# =================================================================================
#      🚀 BUILD-APK Edisi PRO - The Intelligent Build & Analysis Suite 🚀
# =================================================================================
# Deskripsi:
# Rombakan total dengan UI profesional, analisis proyek mendalam, laporan
# kompatibilitas sistem, dan alur kerja build yang cerdas dan stabil.
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
readonly OUTPUT_DIR="$HOME/apk_builds/finished"
readonly LOG_DIR="$HOME/apk_builds/logs"
# Folder temp unik, akan dihapus otomatis oleh 'trap'
BUILD_DIR="$HOME/build_temp_$(date +%s)"

# --- [3] FUNGSI UTILITY & UI ---
cleanup() {
  echo
  log_msg INFO "Membersihkan lingkungan build sementara..."
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

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
    echo -e "${BLUE}${BOLD}"
    echo '  █▀▄ █░░ █ ATC █▀▄  ▄▀█ █▀▄ █▄█  █▀█ █▀█ █▀'
    echo '  █▀▄ █▄▄ █ ▄▄█ █▄▀  █▀█ █▄▀ ░█░  █▀▀ █▄█ ▄█'
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo -e "${BOLD}${WHITE}  The Intelligent Build & Analysis Suite${NC}"
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo
}

# Fungsi cerdas untuk mengambil nilai dari file gradle
get_gradle_value() {
    local key="$1"
    local file="$2"
    # Pola ini menangani spasi, =, "", dan ''
    grep -m 1 "$key" "$file" | sed -E "s/.*[ =] ?['\"]?([^'\"]+)['\"]?.*/\1/"
}

# --- [4] FUNGSI INTI ---
check_system_deps() {
    log_msg STEP "Memeriksa Kesiapan Sistem"
    local all_ok=true
    # Memeriksa command-line tools
    for cmd in java gradle unzip uber-apk-signer; do
        if ! command -v $cmd &> /dev/null; then
            log_msg ERROR "Perintah '$cmd' tidak ditemukan! Pastikan sudah terinstal dan ada di PATH."
            all_ok=false
        fi
    done
    # Memeriksa ANDROID_HOME
    if [ -z "$ANDROID_HOME" ] || [ ! -d "$ANDROID_HOME" ]; then
        log_msg ERROR "Variabel ANDROID_HOME tidak diset atau tidak valid!"
        all_ok=false
    fi

    if $all_ok; then
        log_msg SUCCESS "Semua kebutuhan sistem terpenuhi."
    else
        exit 1
    fi
}

get_zip_input() {
    log_msg STEP "Input & Ekstraksi Proyek"
    local zip_file
    if [ -n "$1" ]; then
        log_msg INFO "File ZIP terdeteksi dari argumen: $1"
        zip_file="$1"
    else
        read -rp ">> Masukkan NAMA FILE ZIP (Contoh: MyGame.zip): " zip_file
    fi
    [ -z "$zip_file" ] && { log_msg ERROR "Nama file tidak boleh kosong!"; exit 1; }

    ZIP_PATH=""
    for dir in "." "$HOME/storage/downloads" "$HOME/storage/shared" "$HOME/downloads"; do
        [ -f "$dir/$zip_file" ] && { ZIP_PATH="$dir/$zip_file"; break; }
    done

    [ -z "$ZIP_PATH" ] && { log_msg ERROR "File '$zip_file' tidak ditemukan!"; exit 1; }
    log_msg SUCCESS "File ditemukan: ${GRAY}$ZIP_PATH${NC}"
}

laporan_analisis() {
    log_msg STEP "Analisis Proyek & Laporan Kompatibilitas"
    
    # Ekstraksi informasi dari build.gradle
    APP_ID=$(get_gradle_value "applicationId" "$BUILD_GRADLE_FILE")
    VERSION_CODE=$(get_gradle_value "versionCode" "$BUILD_GRADLE_FILE")
    VERSION_NAME=$(get_gradle_value "versionName" "$BUILD_GRADLE_FILE")
    MIN_SDK=$(get_gradle_value "minSdk" "$BUILD_GRADLE_FILE")
    TARGET_SDK=$(get_gradle_value "targetSdk" "$BUILD_GRADLE_FILE")
    COMPILE_SDK=$(get_gradle_value "compileSdk" "$BUILD_GRADLE_FILE")

    # Tampilkan laporan
    echo -e "  ${PURPLE}╔═════════════════════════════════════════════════════╗"
    echo -e "  ${PURPLE}║${NC} ${BOLD}${WHITE}         LAPORAN ANALISIS PROYEK ANDROID         ${PURPLE}║"
    echo -e "  ${PURPLE}╚═════════════════════════════════════════════════════╝${NC}"
    printf "  ${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "Application ID" "$APP_ID"
    printf "  ${CYAN}%-20s${NC} : ${WHITE}%s (v%s)${NC}\n" "Version" "$VERSION_NAME" "$VERSION_CODE"
    echo -e "  ${PURPLE}-----------------------------------------------------------${NC}"
    
    local all_sdk_ok=true
    # Cek Compile SDK
    if [ -d "$ANDROID_HOME/platforms/android-$COMPILE_SDK" ]; then
        printf "  ${CYAN}%-20s${NC} : ${WHITE}%s ${GREEN}[✓ TERINSTAL]${NC}\n" "Compile SDK" "$COMPILE_SDK"
    else
        printf "  ${CYAN}%-20s${NC} : ${WHITE}%s ${RED}[✘ TIDAK ADA]${NC}\n" "Compile SDK" "$COMPILE_SDK"
        all_sdk_ok=false
    fi
    # Cek Target SDK
    if [ -d "$ANDROID_HOME/platforms/android-$TARGET_SDK" ]; then
        printf "  ${CYAN}%-20s${NC} : ${WHITE}%s ${GREEN}[✓ TERINSTAL]${NC}\n" "Target SDK" "$TARGET_SDK"
    else
        printf "  ${CYAN}%-20s${NC} : ${WHITE}%s ${RED}[✘ TIDAK ADA]${NC}\n" "Target SDK" "$TARGET_SDK"
        all_sdk_ok=false
    fi
    printf "  ${CYAN}%-20s${NC} : ${WHITE}%s${NC}\n" "Min SDK" "$MIN_SDK"
    echo -e "  ${PURPLE}-----------------------------------------------------------${NC}"

    if ! $all_sdk_ok; then
        log_msg ERROR "Sistem tidak kompatibel. Install SDK Platform yang dibutuhkan via Android Studio atau sdkmanager."
        exit 1
    else
        log_msg SUCCESS "Sistem kompatibel dengan kebutuhan proyek."
    fi
}

# --- [5] PROGRAM UTAMA ---
main() {
    print_header
    check_system_deps
    
    get_zip_input "$1"
    mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$LOG_DIR"
    log_msg INFO "Mengekstrak source code..."
    unzip -q "$ZIP_PATH" -d "$BUILD_DIR" || { log_msg ERROR "Gagal ekstrak ZIP! File mungkin rusak."; exit 1; }

    PROJECT_ROOT=$(find "$BUILD_DIR" -name "gradlew" -type f -exec dirname {} \; | head -n 1)
    [ -z "$PROJECT_ROOT" ] && { log_msg ERROR "Ini bukan proyek Android (tidak ditemukan 'gradlew')."; exit 1; }
    
    BUILD_GRADLE_FILE=$(find "$PROJECT_ROOT/app" -name "build.gradle" -o -name "build.gradle.kts" | head -n 1)
    [ ! -f "$BUILD_GRADLE_FILE" ] && { log_msg ERROR "Tidak dapat menemukan file 'build.gradle' atau 'build.gradle.kts' di dalam folder 'app'."; exit 1; }
    
    # Panggil Laporan Analisis
    laporan_analisis

    log_msg STEP "Konfigurasi Build"
    echo "Pilih jenis build yang diinginkan:"
    select BUILD_CHOICE in "Release (Direkomendasikan)" "Debug" "Clean dan Release"; do
        case $BUILD_CHOICE in
            "Release (Direkomendasikan)" ) BUILD_TASK="assembleRelease"; BUILD_TYPE="release"; break;;
            "Debug" ) BUILD_TASK="assembleDebug"; BUILD_TYPE="debug"; break;;
            "Clean dan Release" ) BUILD_TASK="clean assembleRelease"; BUILD_TYPE="release"; break;;
            * ) echo "Pilihan tidak valid.";;
        esac
    done

    log_msg STEP "Memulai Proses Build & Logging"
    cd "$PROJECT_ROOT" || exit
    chmod +x gradlew
    
    LOG_FILE="$LOG_DIR/$(basename "$ZIP_PATH" .zip)_build_$(date +%F-%H%M).log"
    log_msg INFO "Memulai build '$BUILD_TASK'... Proses ini bisa sangat lama."
    log_msg INFO "Log lengkap disimpan di: ${GRAY}$LOG_FILE${NC}"
    
    if ./gradlew $BUILD_TASK > "$LOG_FILE" 2>&1; then
        log_msg SUCCESS "BUILD BERHASIL!"
    else
        log_msg ERROR "BUILD GAGAL TOTAL!"
        log_msg INFO "Silakan periksa detail error di file log."
        echo -e "${RED}"; tail -n 20 "$LOG_FILE"; echo -e "${NC}"
        exit 1
    fi

    log_msg STEP "Finalisasi & Signing"
    # Cari APK hasil build
    BUILT_APK_DIR="$PROJECT_ROOT/app/build/outputs/apk/$BUILD_TYPE"
    UNSIGNED_APK=$(find "$BUILT_APK_DIR" -name "app-${BUILD_TYPE}-unsigned.apk" | head -n 1)

    if [ -z "$UNSIGNED_APK" ]; then
        # Jika tidak ada -unsigned.apk (mungkin sudah disign oleh gradle), cari apk biasa
        UNSIGNED_APK=$(find "$BUILT_APK_DIR" -name "app-${BUILD_TYPE}.apk" | head -n 1)
        [ -z "$UNSIGNED_APK" ] && { log_msg ERROR "Build sukses tapi file APK tidak ditemukan!"; exit 1; }
        log_msg WARN "Tidak ditemukan APK '-unsigned', APK mungkin sudah ditandatangani oleh Gradle."
    fi

    # Menentukan nama file final yang profesional
    FINAL_APK_NAME="${APP_ID}-v${VERSION_NAME}-${BUILD_TYPE}.apk"
    FINAL_APK_PATH="$OUTPUT_DIR/$FINAL_APK_NAME"

    log_msg INFO "Menjalankan Uber APK Signer untuk memastikan APK final tertandatangani..."
    if uber-apk-signer --apks "$UNSIGNED_APK" --out "$OUTPUT_DIR" --overwrite &>> "$LOG_FILE"; then
        # uber-apk-signer menghasilkan file dengan nama asli + akhiran. Kita rename ke nama profesional kita.
        SIGNED_APK_FROM_UBER=$(find "$OUTPUT_DIR" -name "app-${BUILD_TYPE}-aligned-signed.apk" | head -n 1)
        mv "$SIGNED_APK_FROM_UBER" "$FINAL_APK_PATH"
        log_msg SUCCESS "APK berhasil ditandatangani!"
    else
        log_msg ERROR "Proses signing gagal! Cek log untuk detail."
        exit 1
    fi

    log_msg STEP "SEMUA PROSES BERHASIL!"
    echo -e "\n${GREEN}${BOLD}File final Anda siap di:${NC}\n${YELLOW}$FINAL_APK_PATH${NC}\n"
}

# Jalankan program utama dengan semua argumen yang diberikan
main "$@"
