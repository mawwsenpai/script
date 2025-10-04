#!/bin/bash

# ===================================================================================
#               MOD-APK.SH v3.0 - The Professional Workflow Engine
#
#   Script ini adalah sebuah lingkungan kerja modding APK yang lengkap dan cerdas.
#   Fitur:
#   - Lingkungan kerja terisolasi di ~/apk_projects
#   - Pengecekan semua dependensi di awal
#   - Validasi XML otomatis (Pre-flight Check) sebelum rebuild untuk mencegah error
#   - Logging otomatis untuk setiap proses bongkar/pasang
#   - Penanganan interupsi (Ctrl+C) untuk bersih-bersih
#
#                                  Crafted for Mawwsenpai
# ===================================================================================

# --- [1] KONFIGURASI & VARIABEL GLOBAL ---
# Palet Warna & Style
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD=$(tput bold); NORMAL=$(tput sgr0)

# Path Penting (Bisa disesuaikan jika perlu)
APKTOOL_JAR="$HOME/script/apktool.jar"
SIGN_SCRIPT="$HOME/script/sign-apk.sh"
WORKSPACE_DIR="$HOME/apk_projects"
LOG_DIR="$WORKSPACE_DIR/logs"

# Variabel untuk nama file log dinamis
LOG_FILE=""

# --- [2] FUNGSI-FUNGSI HELPER (ASISTEN SCRIPT) ---

# Fungsi bersih-bersih jika script dihentikan paksa (Ctrl+C)
cleanup_on_exit() {
    echo -e "\n\n${RED}⚠️  Proses dihentikan paksa. Menjalankan bersih-bersih...${NC}"
    # Hapus file-file temporary Apktool jika ada
    rm -rf "$HOME/.local/share/apktool/framework/"*
    echo -e "${GREEN}✅ Bersih-bersih selesai.${NC}"
    exit 1
}
trap cleanup_on_exit INT TERM

# Fungsi untuk menyiapkan lingkungan kerja
setup_lingkungan() {
    mkdir -p "$WORKSPACE_DIR"
    mkdir -p "$LOG_DIR"
}

# Fungsi untuk menampilkan header
tampilkan_header() {
    clear
    echo -e "${BLUE}${BOLD}===================================================================${NC}"
    echo -e "${GREEN}${BOLD}         🔧 MOD-APK.SH v3.0 - Pro Workflow Engine 🔧${NC}"
    echo -e "${BLUE}${BOLD}===================================================================${NC}"
    echo -e "${YELLOW}Lingkungan Kerja: $WORKSPACE_DIR${NC}\n"
}

# Fungsi pengecekan semua dependensi di awal
cek_dependensi() {
    echo -e "${YELLOW}🔍 Mengecek kesiapan sistem dan semua alat tempur...${NC}"
    local ALL_OK=1
    # Cek Java
    if ! command -v java &>/dev/null; then echo -e "${RED}  ❌ Java (JDK): Tidak ditemukan! Install dengan './install-java.sh'${NC}"; ALL_OK=0; fi
    # Cek Apktool
    if [ ! -f "$APKTOOL_JAR" ]; then echo -e "${RED}  ❌ Apktool: '$APKTOOL_JAR' tidak ditemukan! Install dengan './install-apktool.sh'${NC}"; ALL_OK=0; fi
    # Cek Script Sign
    if [ ! -f "$SIGN_SCRIPT" ]; then echo -e "${RED}  ❌ Sign Script: '$SIGN_SCRIPT' tidak ditemukan!${NC}"; ALL_OK=0; fi
    # Cek xmllint
    if ! command -v xmllint &>/dev/null; then echo -e "${RED}  ❌ XML Validator: 'xmllint' tidak ditemukan! Install dengan 'pkg install libxml2-utils'${NC}"; ALL_OK=0; fi

    if [ $ALL_OK -eq 1 ]; then
        echo -e "${GREEN}✅ Semua alat tempur siap di posisinya masing-masing!${NC}\n"
    else
        echo -e "\n${RED}🔥 Sistem belum siap! Mohon install semua kebutuhan di atas.${NC}"
        exit 1
    fi
}

# --- [3] FUNGSI-FUNGSI INTI (MESIN UTAMA) ---

# Fungsi Validasi XML (Pre-flight Check)
validasi_xml() {
    local PROJECT_DIR=$1
    echo -e "\n${YELLOW}🔬 [Pre-flight Check] Memeriksa 'kesehatan' file XML sebelum rebuild...${NC}"
    
    for xml_file in $(find "$PROJECT_DIR/res" -type f -name "*.xml"); do
        if ! xmllint --noout "$xml_file" >/dev/null 2>&1; then
            echo -e "\n${RED}==================== ERROR SINTAKS DITEMUKAN ====================${NC}"
            echo -e "${RED}❌ Validasi GAGAL! Ditemukan error pada file XML.${NC}"
            echo -e "${YELLOW}   File Bermasalah: $xml_file${NC}"
            echo -e "${BLUE}   Laporan dari Dokter XML (xmllint):${NC}"
            xmllint --noout "$xml_file" # Tampilkan error spesifik
            echo -e "${RED}===============================================================${NC}"
            echo -e "${YELLOW}>> Rebuild dibatalkan. Silakan perbaiki file di atas lalu coba lagi.${NC}"
            return 1 # Mengembalikan status gagal
        fi
    done

    echo -e "${GREEN}✅ [Pre-flight Check] Semua file XML terlihat sehat! Melanjutkan rebuild...${NC}"
    return 0 # Mengembalikan status sukses
}

# Fungsi untuk menandatangani APK
tanda_tangan_apk() {
    local REBUILT_APK=$1
    echo -e "\n${YELLOW}✍️  Memanggil script '$SIGN_SCRIPT' untuk proses signing...${NC}"
    if ! "$SIGN_SCRIPT" "$REBUILT_APK"; then
        echo -e "\n${RED}❌ Proses signing gagal! Cek output dari '$SIGN_SCRIPT'.${NC}"
        return 1
    fi
}

# Fungsi untuk merakit (rebuild) APK
pasang_apk() {
    local PROJECT_DIR=$1
    local APK_NAME=$(basename "$PROJECT_DIR" -MODIF)
    local REBUILT_APK="$PROJECT_DIR-REBUILT.apk"
    LOG_FILE="$LOG_DIR/${APK_NAME}_rebuild_$(date +%F_%H-%M-%S).log"
    
    echo -e "\n${BLUE}🔧 Merakit ulang (Rebuild) folder '$PROJECT_DIR'...${NC}"
    echo -e "${YELLOW}   (Log lengkap disimpan di: $LOG_FILE)${NC}"
    
    # Menjalankan rebuild dan menyimpan output ke log DAN menampilkannya di layar
    if java -jar "$APKTOOL_JAR" b "$PROJECT_DIR" -f -o "$REBUILT_APK" | tee "$LOG_FILE"; then
        echo -e "\n${GREEN}🎉 SUKSES REBUILD! File sementara: ${YELLOW}$REBUILT_APK${NC}"
        tanda_tangan_apk "$REBUILT_APK"
    else
        echo -e "\n${RED}❌ GAGAL Rebuild APK! Cek log error di atas dan di file log untuk detail.${NC}"
        return 1
    fi
}

# Fungsi untuk membongkar APK
bongkar_apk() {
    tampilkan_header
    read -p ">> Masukkan NAMA FILE APK (Contoh: Pou.apk): " APK_FILE
    if [ -z "$APK_FILE" ]; then echo -e "${RED}ERROR: Nama file jangan kosong!${NC}"; return; fi

    local INPUT_PATH="" # Cari file di lokasi-lokasi umum
    if [ -f "$APK_FILE" ]; then INPUT_PATH="$APK_FILE";
    elif [ -f "$HOME/storage/downloads/$APK_FILE" ]; then INPUT_PATH="$HOME/storage/downloads/$APK_FILE";
    elif [ -f "$HOME/storage/shared/$APK_FILE" ]; then INPUT_PATH="$HOME/storage/shared/$APK_FILE";
    else echo -e "${RED}❌ ERROR: File '$APK_FILE' tidak ditemukan!${NC}"; return; fi
    echo -e "${GREEN}✅ File ditemukan di: $INPUT_PATH${NC}"

    local APK_NAME=$(basename "$APK_FILE" .apk)
    local PROJECT_DIR="$WORKSPACE_DIR/${APK_NAME}-MODIF"
    LOG_FILE="$LOG_DIR/${APK_NAME}_decompile_$(date +%F_%H-%M-%S).log"
    
    echo -e "\n${BLUE}🔨 Membongkar $APK_FILE ke '$PROJECT_DIR'...${NC}"
    echo -e "${YELLOW}   (Log lengkap disimpan di: $LOG_FILE)${NC}"

    if java -jar "$APKTOOL_JAR" d "$INPUT_PATH" -f -o "$PROJECT_DIR" | tee "$LOG_FILE"; then
        echo -e "\n${GREEN}🎉 SUKSES BONGKAR! Proyek siap diobrak-abrik di:${NC}"
        echo -e "${YELLOW}$PROJECT_DIR${NC}"
        echo -e "\n${BLUE}Silakan edit file-file di dalam folder tersebut. Setelah selesai...${NC}"
        read -p ">> Tekan [ENTER] untuk memulai validasi dan proses rebuild..."

        if validasi_xml "$PROJECT_DIR"; then
            pasang_apk "$PROJECT_DIR"
        fi
    else
        echo -e "\n${RED}❌ GAGAL Membongkar APK! Cek log error di atas dan di file log untuk detail.${NC}"
        return
    fi
}


# --- [4] BLOK EKSEKUSI UTAMA (MANAJER) ---

# Persiapan awal
setup_lingkungan
tampilkan_header
cek_dependensi

# Loop menu utama
while true; do
    echo -e "\n${GREEN}${BOLD}--- MENU UTAMA ---${NC}"
    echo "1. Bongkar, Edit, dan Pasang APK (Alur Lengkap)"
    echo "2. Pasang Ulang dari Folder Proyek yang Ada"
    echo "9. Keluar"
    read -p ">> Masukkan pilihan: " choice

    case $choice in
        1)
            bongkar_apk
            ;;
        2)
            # Logika untuk rebuild dari folder yang sudah ada (bisa ditambahkan di sini)
            tampilkan_header
            read -p ">> Masukkan path folder proyek di '$WORKSPACE_DIR': " FOLDER_PROYEK
            if [ -d "$FOLDER_PROYEK" ]; then
                if validasi_xml "$FOLDER_PROYEK"; then
                    pasang_apk "$FOLDER_PROYEK"
                fi
            else
                echo -e "${RED}❌ Folder tidak ditemukan!${NC}"
            fi
            ;;
        9)
            echo -e "\n${BLUE}Terima kasih telah menggunakan Pro Workflow Engine! Sampai jumpa lagi!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Pilihan tidak valid, cuy! Coba lagi.${NC}"
            ;;
    esac
    echo -e "\n${YELLOW}Tekan [ENTER] untuk kembali ke menu utama...${NC}"; read -p ""
    tampilkan_header
done
