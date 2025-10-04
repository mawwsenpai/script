
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Konfigurasi Awal (Bisa disesuaikan) ---
APKTOOL_JAR="$HOME/script/apktool.jar"
SIGN_SCRIPT="./sign-apk.sh"
DOWNLOAD_PATH="$HOME/storage/downloads"
STORAGE_PATH="$HOME/storage/shared"

# Fungsi buat nampilin header biar keren
tampilkan_header() {
    clear
    echo -e "=================================================="
    echo -e "${GREEN}💰 MOD-APK.SH v2.0 | Studio Oprek APK Otomatis ${NC}"
    echo -e "=================================================="
}

# Fungsi buat ngecek alat tempur (Java & Apktool)
cek_alat_tempur() {
    echo -e "${YELLOW}>> Mengecek kesiapan alat tempur...${NC}"
    local error=0
    if ! command -v java &> /dev/null; then
        echo -e "${RED}   - Status Java: TIDAK ADA${NC}"
        error=1
    else
        echo -e "${GREEN}   + Status Java: Ada${NC}"
    fi

    if [ ! -f "$APKTOOL_JAR" ]; then
        echo -e "${RED}   - Status Apktool JAR: TIDAK ADA di '$APKTOOL_JAR'${NC}"
        error=1
    else
        echo -e "${GREEN}   + Status Apktool JAR: Ada${NC}"
    fi

    if [ $error -eq 1 ]; then
        echo -e "\n${RED}❌ ERROR KRITIS: Tool belum lengkap!${NC}"
        echo -e ">> Solusi: Pastikan Java terinstall dan jalankan ${YELLOW}Menu 0${NC} di main.sh!"
        exit 1
    fi
    echo -e "${GREEN}>> Alat tempur SIAP STABIL!${NC}\n"
}

# Fungsi buat bongkar APK
bongkar_apk() {
    tampilkan_header
    echo -e "${BLUE}--- MENU 1: BONGKAR APK ---${NC}"
    read -p ">> Masukkan NAMA FILE APK (Contoh: Pou.apk): " APK_FILE

    if [ -z "$APK_FILE" ]; then
        echo -e "${RED}❌ ERROR: Nama file jangan dikosongin dong!${NC}"
        return 1
    fi

    local INPUT_PATH=""
    # Cek file di 3 lokasi stabil
    if [ -f "$APK_FILE" ]; then
        INPUT_PATH="$APK_FILE"
        echo -e "${GREEN}✅ Ditemukan di: Folder Proyek${NC}"
    elif [ -f "$DOWNLOAD_PATH/$APK_FILE" ]; then
        INPUT_PATH="$DOWNLOAD_PATH/$APK_FILE"
        echo -e "${GREEN}✅ Ditemukan di: Folder Download${NC}"
    elif [ -f "$STORAGE_PATH/$APK_FILE" ]; then
        INPUT_PATH="$STORAGE_PATH/$APK_FILE"
        echo -e "${GREEN}✅ Ditemukan di: Folder Internal Utama${NC}"
    else
        echo -e "${RED}❌ ERROR: File '$APK_FILE' kaga ketemu di 3 lokasi wajib!${NC}"
        echo -e ">> Pastikan file ada di folder skrip, Download, atau Internal utama HP lu!${NC}"
        return 1
    fi

    local OUTPUT_FOLDER="${APK_FILE%.apk}-MODIF"
    echo -e "\n${BLUE}🔨 Membongkar $APK_FILE ke folder '$OUTPUT_FOLDER'...${NC}"
    java -jar "$APKTOOL_JAR" d "$INPUT_PATH" -f -o "$OUTPUT_FOLDER"

    if [ $? -ne 0 ]; then
        echo -e "\n${RED}❌ GAGAL Membongkar APK! Kayaknya APK-nya pake proteksi tingkat dewa!${NC}"
        return 1
    fi

    echo -e "\n${GREEN}🎉 SUKSES BONGKAR! Kode Smali siap diobrak-abrik di: ${YELLOW}$OUTPUT_FOLDER${NC}"
    echo -e "=================================================="
    echo -e "\n${BLUE}💡 PANDUAN OPREK SINGKAT (Contoh Cheat Koin):${NC}"
    echo "1. Buka folder ${YELLOW}$OUTPUT_FOLDER${NC} dan edit file smali yang relevan."
    echo "2. Cari baris kode mencurigakan, contoh: ${RED}const/4 vX, 0x0${NC}"
    echo "3. Ubah nilainya jadi gede banget buat sultan mode."
    echo -e "\n${YELLOW}Kalo udah selesai ngedit, pencet [ENTER] buat lanjut ke proses PASANG & SIGN...${NC}"
    read -p ""

    pasang_apk "$OUTPUT_FOLDER"
}

# Fungsi buat pasang/rebuild APK dari folder
pasang_apk() {
    local FOLDER_MODIF="$1"
    if [ -z "$FOLDER_MODIF" ]; then
        tampilkan_header
        echo -e "${BLUE}--- MENU 2: PASANG/REBUILD APK ---${NC}"
        read -p ">> Masukkan NAMA FOLDER hasil bongkaran: " FOLDER_MODIF
        if [ ! -d "$FOLDER_MODIF" ]; then
            echo -e "${RED}❌ ERROR: Folder '$FOLDER_MODIF' tidak ada!${NC}"
            return 1
        fi
    fi

    local APK_HASIL="${FOLDER_MODIF}-REBUILT.apk"
    echo -e "\n${BLUE}🔧 Merakit ulang (Rebuild) folder '$FOLDER_MODIF' menjadi '$APK_HASIL'...${NC}"
    java -jar "$APKTOOL_JAR" b "$FOLDER_MODIF" -o "$APK_HASIL"

    if [ $? -ne 0 ]; then
        echo -e "\n${RED}❌ GAGAL Rebuild APK! Coba cek log error di atas.${NC}"
        return 1
    fi

    echo -e "\n${GREEN}🎉 SUKSES REBUILD! Filenya adalah: ${YELLOW}$APK_HASIL${NC}"
    
    # Otomatis lanjut ke proses Tanda Tangan (Sign)
    tanda_tangan_apk "$APK_HASIL"
}

# Fungsi buat tanda tangan (sign) APK
tanda_tangan_apk() {
    local APK_TARGET="$1"
    echo -e "\n${YELLOW}✍️ Lanjut proses tanda tangan (Sign) untuk '$APK_TARGET'...${NC}"

    if [ ! -f "$SIGN_SCRIPT" ]; then
        echo -e "${RED}❌ ERROR: Script '$SIGN_SCRIPT' gak ketemu!${NC}"
        echo -e ">> Pastikan '$SIGN_SCRIPT' ada di folder yang sama dan bisa dieksekusi.${NC}"
        return 1
    fi

    # Memberi izin eksekusi jika belum ada
    chmod +x "$SIGN_SCRIPT"
    
    "$SIGN_SCRIPT" "$APK_TARGET"

    if [ $? -eq 0 ]; then
        local SIGNED_APK="${APK_TARGET%.apk}-SIGNED.apk"
        echo -e "\n${GREEN}✅ MANTAP JIWA! APK sudah di-sign dan siap install: ${YELLOW}$SIGNED_APK${NC}"
    else
        echo -e "\n${RED}❌ GAGAL Menandatangani APK! Cek error dari script sign.${NC}"
    fi
}


# =================================================
#                 PROGRAM UTAMA
# =================================================

# Cek dulu alatnya sekali di awal
cek_alat_tempur

# Looping menu utama
while true; do
    tampilkan_header
    echo -e "Pilih mau ngapain, bos:"
    echo -e " ${GREEN}1.${NC} Bongkar APK (Decompile)"
    echo -e " ${GREEN}2.${NC} Pasang APK dari Folder (Rebuild & Sign)"
    echo -e " ${RED}0.${NC} Keluar"
    echo "--------------------------------------------------"
    read -p "Pilihanmu: " PILIHAN

    case $PILIHAN in
        1)
            bongkar_apk
            ;;
        2)
            pasang_apk
            ;;
        0)
            echo -e "\n${BLUE}Oke, cabut dulu. Makasih udah mampir!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Pilihan ngaco! Cuma ada 1, 2, atau 0.${NC}"
            ;;
    esac

    echo -e "\n${YELLOW}Tekan [ENTER] untuk kembali ke menu utama...${NC}"
    read -p ""
done
