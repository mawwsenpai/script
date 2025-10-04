#!/bin/bash

# =======================================================
#               MOD-APK.SH - Eksekusi Bongkar APK
# Script ini menjalankan proses pembongkaran setelah tool diinstal.
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo -e "=================================================="
echo -e "${GREEN}⚙️  MOD-APK.SH | Cek & Eksekusi Tool Bongkar ${NC}"
echo -e "=================================================="

# 1. Cek Kesiapan Tool
if ! command -v java &> /dev/null || [ ! -f "$HOME/script/apktool.jar" ]; then
    echo -e "${RED}❌ ERROR: Tool belum lengkap. Jalankan: ${YELLOW}./install-java.sh${RED} dan ${YELLOW}./install-apktool.sh${NC}"
    exit 1
fi

# 2. Lanjut ke Pembongkaran (Disassemble)
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

OUTPUT_FOLDER="${APK_FILE%.apk}-CHEAT"
echo -e "\n${BLUE}🔨 Membongkar $APK_FILE ke folder '$OUTPUT_FOLDER'..."
apktool d "$APK_FILE" -o "$OUTPUT_FOLDER"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}🎉 SUKSES! APK '$APK_FILE' berhasil dibongkar!${NC}"
    echo -e ">> Kode Smali siap diobrak-abrik di folder: ${YELLOW}$OUTPUT_FOLDER${NC}"
    echo "=================================================="
else
    echo -e "\n${RED}❌ GAGAL Membongkar APK. Kemungkinan terproteksi!${NC}"
fi
