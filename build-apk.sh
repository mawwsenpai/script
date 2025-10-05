#!/bin/bash

# ============================================================================
#              BUILD-APK.SH v5.0 - The Complete Build Suite
#     Script lengkap yang menganalisis, membangun, dan menandatangani
#             proyek Android dari source code ZIP secara cerdas.
# ============================================================================

# --- [1] KONFIGURASI ---
# Sesuaikan path di bawah ini jika perlu
readonly OUTPUT_DIR="$HOME/storage/shared/MawwScript/built"
readonly LOG_DIR="$HOME/storage/shared/MawwScript/logs"
# Pastikan uber-apk-signer.jar ada di sini. Instal dengan setup-modding.sh
readonly SIGNER_JAR="$HOME/tools/uber-apk-signer.jar"

# --- [2] UI & UTILITY ---
# Palet Warna & Style
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'
CYAN='\033[1;36m'; BOLD=$(tput bold); NORMAL=$(tput sgr0)

# Folder temp unik, akan dihapus otomatis oleh 'trap'
BUILD_DIR="$HOME/build_temp_$(date +%s)"

cleanup() {
  echo -e "\n${YELLOW}🧹 Membersihkan lingkungan build sementara...${NC}"
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║       🚀  BUILD-APK v5.0 - The Complete Suite  🚀      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_step() { echo -e "\n${BLUE}${BOLD}--- [LANGKAH $1] $2 ---${NC}"; }
log_info() { echo -e "  ${CYAN}ℹ️  $1${NC}"; }
log_success() { echo -e "  ${GREEN}✔  $1${NC}"; }
log_error() { echo -e "  ${RED}✖  $1${NC}"; }

get_gradle_value() {
    grep -E "$1" "$2" | head -n 1 | sed -E "s/.*[ =] ?['\"]?([0-9A-Za-z\._-]+)['\"]?.*/\1/"
}

# --- [3] FUNGSI INTI ---

# Fungsi untuk memeriksa semua kebutuhan sistem
check_system_deps() {
    log_step 1 "Memeriksa Kesiapan Sistem"
    local all_ok=true
    if ! command -v java &> /dev/null || [ -z "$ANDROID_HOME" ] || ! command -v unzip &> /dev/null; then
        log_error "Kebutuhan dasar (Java, ANDROID_HOME, Unzip) tidak terpenuhi."
        all_ok=false
    else
        log_success "Kebutuhan dasar (Java, ANDROID_HOME, Unzip) OK."
    fi

    if [ ! -f "$SIGNER_JAR" ]; then
        log_error "Uber APK Signer tidak ditemukan di '$SIGNER_JAR'."
        log_info "Jalankan 'setup-modding.sh' untuk menginstalnya."
        all_ok=false
    else
        log_success "Uber APK Signer OK."
    fi

    ! $all_ok && exit 1
}

# Fungsi untuk mendapatkan path file ZIP dari argumen atau prompt
get_zip_input() {
    if [ -n "$1" ]; then
        log_info "File ZIP terdeteksi dari argumen: $1"
        ZIP_FILE="$1"
    else
        read -p ">> Masukkan NAMA FILE ZIP (Contoh: MyGame.zip): " ZIP_FILE
    fi

    [ -z "$ZIP_FILE" ] && { log_error "Nama file tidak boleh kosong!"; exit 1; }

    ZIP_PATH=""
    for dir in "." "$HOME/storage/downloads" "$HOME/storage/shared"; do
        [ -f "$dir/$ZIP_FILE" ] && { ZIP_PATH="$dir/$ZIP_FILE"; break; }
    done

    [ -z "$ZIP_PATH" ] && { log_error "File '$ZIP_FILE' tidak ditemukan!"; exit 1; }
    log_success "File ditemukan: $ZIP_PATH"
}

# --- [4] PROGRAM UTAMA ---

main() {
    print_header
    check_system_deps

    log_step 2 "Input & Ekstraksi Proyek"
    get_zip_input "$1"
    mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$LOG_DIR"
    log_info "Mengekstrak source code..."
    unzip -q "$ZIP_PATH" -d "$BUILD_DIR" || { log_error "Gagal ekstrak ZIP! File mungkin rusak."; exit 1; }

    PROJECT_ROOT=$(find "$BUILD_DIR" -name "gradlew" -type f -exec dirname {} \; | head -n 1)
    [ -z "$PROJECT_ROOT" ] && { log_error "Ini bukan proyek Android (tidak ditemukan 'gradlew')."; exit 1; }
    log_success "Proyek valid, memulai analisis..."

    # Analisis Proyek
    GRADLE_PROPS_FILE="$PROJECT_ROOT/gradle/wrapper/gradle-wrapper.properties"
    BUILD_GRADLE_FILE=$(find "$PROJECT_ROOT" -name "build.gradle" -o -name "build.gradle.kts" | grep "app/build.gradle" | head -n 1)
    REQ_GRADLE_VER=$(grep "distributionUrl" "$GRADLE_PROPS_FILE" | sed -n 's/.*gradle-\(.*\)-all.*/\1/p')
    REQ_COMPILE_SDK=$(get_gradle_value "compileSdk(Version)?" "$BUILD_GRADLE_FILE")
    
    # Menampilkan Laporan
    log_step 3 "Laporan Analisis Proyek"
    echo "---------------------------------------------------------------------"
    printf '%-25s %-25s %-20s\n' "${BOLD}Kebutuhan Proyek${NORMAL}" "${BOLD}Status Sistem Anda${NORMAL}" "${BOLD}Kecocokan${NORMAL}"
    echo "---------------------------------------------------------------------"
    printf '%-25s %-25s %-20s\n' "Versi Gradle: $REQ_GRADLE_VER" "(Diunduh Otomatis)" "${GREEN}[✔ OKE]${NC}"
    
    SDK_PATH="$ANDROID_HOME/platforms/android-$REQ_COMPILE_SDK"
    if [ -d "$SDK_PATH" ]; then
        printf '%-25s %-25s %-20s\n' "Compile SDK: $REQ_COMPILE_SDK" "Terinstal" "${GREEN}[✔ COCOK]${NC}"; SDK_OK=true
    else
        printf '%-25s %-25s %-20s\n' "Compile SDK: $REQ_COMPILE_SDK" "Tidak Ditemukan" "${RED}[✘ GAGAL]${NC}"; SDK_OK=false
    fi
    echo "---------------------------------------------------------------------"

    ! $SDK_OK && { log_error "Sistem tidak kompatibel. Install SDK Platform yang dibutuhkan."; exit 1; }
    
    log_step 4 "Konfigurasi Build"
    echo "Pilih jenis build yang diinginkan:"
    select BUILD_CHOICE in "Release" "Debug" "Clean dan Release"; do
        case $BUILD_CHOICE in
            "Release" ) BUILD_TASK="assembleRelease"; break;;
            "Debug" ) BUILD_TASK="assembleDebug"; break;;
            "Clean dan Release" ) BUILD_TASK="clean assembleRelease"; break;;
            * ) echo "Pilihan tidak valid.";;
        esac
    done

    # Proses Build
    log_step 5 "Proses Build & Logging"
    cd "$PROJECT_ROOT" || exit
    chmod +x gradlew
    
    LOG_FILE="$LOG_DIR/$(basename "$ZIP_FILE" .zip)_build_$(date +%F-%H%M).log"
    log_info "Memulai build '$BUILD_TASK'... Proses ini bisa lama."
    log_info "Log lengkap disimpan di: $LOG_FILE"
    
    if ./gradlew $BUILD_TASK > "$LOG_FILE" 2>&1; then
        log_success "BUILD BERHASIL!"
    else
        log_error "BUILD GAGAL TOTAL!"
        log_info "Silakan periksa detail error di file log:"
        echo -e "${YELLOW}$LOG_FILE${NC}"
        tail -n 20 "$LOG_FILE"
        exit 1
    fi

    # Finalisasi dan Signing
    log_step 6 "Finalisasi & Signing"
    APK_SUFFIX=$( [[ "$BUILD_TASK" == *"Debug"* ]] && echo "debug.apk" || echo "release-unsigned.apk" )
    BUILT_APK=$(find . -name "*-$APK_SUFFIX" | head -n 1)
    [ -z "$BUILT_APK" ] && { log_error "Build sukses tapi file APK tidak ditemukan!"; exit 1; }
    
    read -p ">> Build berhasil. Apakah Anda ingin menandatangani (sign) APK ini? (y/n): " confirm_sign
    if [[ "$confirm_sign" == "y" || "$confirm_sign" == "Y" ]]; then
        log_info "Menjalankan Uber APK Signer..."
        if java -jar "$SIGNER_JAR" -a "$BUILT_APK" --overwrite; then
            log_success "APK berhasil ditandatangani!"
            SIGNED_APK_PATH=$(echo "$BUILT_APK" | sed 's/-unsigned//g' | sed 's/\.apk/-signed.apk/g')
        else
            log_error "Proses signing gagal!"; exit 1
        fi
    else
        log_info "Proses signing dilewati."
        SIGNED_APK_PATH="$BUILT_APK"
    fi
    
    PROJECT_NAME=$(basename "$ZIP_FILE" .zip)
    FINAL_APK_PATH="$OUTPUT_DIR/${PROJECT_NAME}-$(date +%F).apk"
    mv "$SIGNED_APK_PATH" "$FINAL_APK_PATH"

    log_step 7 "SELESAI"
    log_success "SEMUA PROSES BERHASIL!"
    echo -e "\n${GREEN}${BOLD}File final Anda siap di:${NC}\n${YELLOW}$FINAL_APK_PATH${NC}\n"
}

# Jalankan program utama dengan semua argumen yang diberikan
main "$@"
