#!/bin/bash

# =======================================================
#               MOD-APK.SH - Modul Modifikasi (Apktool LENGKAP)
# Script ini menjalankan proses Bongkar-Pasang APK, mengecek 3 lokasi file.
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
APKTOOL_JAR="$HOME/script/apktool.jar"
DOWNLOAD_PATH="$HOME/storage/downloads"
STORAGE_PATH="$HOME/storage/shared"

echo -e "=================================================="
echo -e "${GREEN}💰 MOD-APK.SH | Bongkar dan Obrak-Abrik APK ${NC}"
echo -e "=================================================="

# 1. Cek Kesiapan Tool Wajib
if ! command -v java &> /dev/null || [ ! -f "$APKTOOL_JAR" ]; then
    echo -e "${RED}❌ ERROR KRITIS: Tool belum lengkap!${NC}"
    echo -e ">> Status Java: $(command -v java &> /dev/null && echo 'Ada' || echo 'TIDAK ADA')"
    echo -e ">> Status Apktool JAR: $([ -f "$APKTOOL_JAR" ] && echo 'Ada' || echo 'TIDAK ADA')"
    echo -e ">> Solusi: Jalankan ${YELLOW}Menu 0${NC} di main.sh dulu!"
    exit 1
fi

# 2. Pengecekan Lokasi File APK (Paling Teliti!)
echo -e "\n${YELLOW}🚀 Tool Sudah SIAP STABIL. Lanjut ke Pembongkaran!${NC}"
read -p ">> Masukkan NAMA FILE APK (Contoh: Pou.apk): " APK_FILE

if [ -z "$APK_FILE" ]; then
    echo -e "${RED}❌ ERROR: Nama file tidak boleh kosong!${NC}"
    exit 1
fi

# Cek file di 3 lokasi stabil (Urutan dari yang paling rapi)
if [ -f "$APK_FILE" ]; then
    INPUT_PATH="$APK_FILE"
    echo -e "${GREEN}✅ Ditemukan di: Folder Proyek (${APK_FILE})${NC}"
elif [ -f "$DOWNLOAD_PATH/$APK_FILE" ]; then
    INPUT_PATH="$DOWNLOAD_PATH/$APK_FILE"
    echo -e "${GREEN}✅ Ditemukan di: Folder Download (${DOWNLOAD_PATH}/...)${NC}"
elif [ -f "$STORAGE_PATH/$APK_FILE" ]; then
    INPUT_PATH="$STORAGE_PATH/$APK_FILE"
    echo -e "${GREEN}✅ Ditemukan di: Folder Internal Utama (${STORAGE_PATH}/...)${NC}"
else
    echo -e "${RED}❌ ERROR: File '$APK_FILE' tidak ditemukan di 3 lokasi wajib!${NC}"
    echo -e ">> Pastikan file ada di folder ini: ${YELLOW}$HOME/script/${NC} atau di folder ${YELLOW}Download${NC} HP kamu!"
    exit 1
fi

# 3. Pembongkaran (Disassemble)
OUTPUT_FOLDER="${APK_FILE%.apk}-MODIF"
echo -e "\n${BLUE}🔨 Membongkar $APK_FILE ke folder '$OUTPUT_FOLDER'..."
java -jar $APKTOOL_JAR d "$INPUT_PATH" -o "$OUTPUT_FOLDER"

if [ $? -ne 0 ]; then
    echo -e "\n${RED}❌ GAGAL Membongkar APK! Kemungkinan APK terproteksi (MultiDex/Obfuscation)!${NC}"
    exit 1
fi

# 4. Panduan Modifikasi & Perintah Rebuild/Sign (Wajib Manual!)
echo -e "\n${GREEN}🎉 SUKSES BONGKAR! Kode Smali siap diobrak-abrik di: ${YELLOW}$OUTPUT_FOLDER${NC}"
echo -e "=================================================="

echo -e "\n${BLUE}💡 PANDUAN OBRAN-ABRIK (Kunci Cheat Koin Pou):${NC}"
echo "1. Gunakan 'nano' untuk mengedit file kode Smali."
echo "2. Biasanya koin/nyawa ada di file: ${YELLOW}smali/com/pou/game/a/a.smali${NC} (Atau cari di file .smali yang paling sering diakses)."
echo "3. Cari baris yang mirip: ${RED}const/4 vX, 0x0${NC} (Nilai Awal) atau ${RED}const vX, 0x....${NC} (Nilai Koin)."
echo "4. Ubah nilai Koin (angka setelah 0x) menjadi nilai yang sangat besar."

echo -e "\n${YELLOW}PERINTAH REBUILD & SIGN (Setelah Edit Kode):${NC}"
echo "   1. Rebuild APK: ${GREEN}apktool b $OUTPUT_FOLDER -o $OUTPUT_FOLDER.apk${NC}"
echo "   2. Sign Final:  ${GREEN}./sign-apk.sh $OUTPUT_FOLDER.apk${NC} (Ini akan menghasilkan file -SIGNED.apk)"
echo -e "--------------------------------------------------"
