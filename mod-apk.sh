RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
APKTOOL_JAR="$HOME/script/apktool.jar"

echo -e "=================================================="
echo -e "${GREEN}💰 MOD-APK.SH | Bongkar dan Obrak-Abrik APK ${NC}"
echo -e "=================================================="

# 1. Cek Kesiapan Tool
if ! command -v java &> /dev/null || [ ! -f "$APKTOOL_JAR" ]; then
    echo -e "${RED}❌ ERROR: Tool belum lengkap. Jalankan Option 0 di main.sh dulu!${NC}"
    exit 1
fi

# 2. Pembongkaran (Disassemble)
echo -e "\n${YELLOW}🚀 Tool Sudah SIAP STABIL. Lanjut ke Pembongkaran!${NC}"
read -p ">> Masukkan NAMA FILE APK (Contoh: Pou.apk): " APK_FILE

if [ -z "$APK_FILE" ]; then
    echo -e "${RED}❌ ERROR: Nama file tidak boleh kosong!${NC}"
    exit 1
fi

if [ ! -f "$APK_FILE" ]; then
    echo -e "${RED}❌ ERROR: File '$APK_FILE' tidak ditemukan di folder ini!${NC}"
    exit 1
fi

OUTPUT_FOLDER="${APK_FILE%.apk}-MODIF"
echo -e "\n${BLUE}🔨 Membongkar $APK_FILE ke folder '$OUTPUT_FOLDER'..."
java -jar $APKTOOL_JAR d "$APK_FILE" -o "$OUTPUT_FOLDER"

if [ $? -ne 0 ]; then
    echo -e "\n${RED}❌ GAGAL Membongkar APK. Kemungkinan terproteksi atau Java bermasalah!${NC}"
    exit 1
fi

# 3. Panduan Modifikasi & Perintah Rebuild/Sign
echo -e "\n${GREEN}🎉 SUKSES BONGKAR! Kode Smali siap diobrak-abrik di: ${YELLOW}$OUTPUT_FOLDER${NC}"
echo -e "\n${BLUE}💡 LANGKAH SELANJUTNYA (WAJIB MANUAL):${NC}"
echo "1. Edit kode Smali di folder '$OUTPUT_FOLDER' (Gunakan Nano)."
echo "2. Setelah selesai, jalankan Rebuild dan Sign."
echo -e "--------------------------------------------------"
echo -e "${YELLOW}PERINTAH REBUILD & SIGN (Setelah Edit Kode):${NC}"
echo -e "   1. Rebuild: ${GREEN}apktool b $OUTPUT_FOLDER -o $OUTPUT_FOLDER.apk${NC}"
echo -e "   2. Sign: ${GREEN}./sign-apk.sh $OUTPUT_FOLDER.apk${NC}"

