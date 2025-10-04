#!/bin/bash

# =====================================================================
#                SIGN-APK.SH v2.0 - Finisher APK Cerdas
#   Script ini menandatangani APK dan menyimpannya ke direktori
#        custom dengan format nama file yang sudah ditentukan.
# =====================================================================

# --- Palet Warna & Style ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Konfigurasi (BISA DISESUAIKAN) ---
# Lokasi alat signer (WAJIB DOWNLOAD DULU!)
SIGNER_JAR="$HOME/script/uber-apk-signer.jar"

# Folder tujuan untuk menyimpan hasil akhir APK yang sudah di-mod
OUTPUT_DIR="$HOME/storage/shared/MawwScript/mod"

# =================================================
#                 PROGRAM UTAMA
# =================================================

clear
echo -e "${BLUE}--- Proses Tanda Tangan (Signing) APK ---${NC}"

# 1. Validasi Input
# Cek apakah pengguna memberikan nama file APK sebagai argumen
if [ -z "$1" ]; then
    echo -e "\n${RED}❌ ERROR: Perintah salah, cuy!${NC}"
    echo -e "${YELLOW}>> Cara Pakai: ./sign-apk.sh [nama_file_apk_yang_mau_disign]${NC}"
    exit 1
fi

INPUT_APK="$1"

# Cek apakah file APK yang diberikan benar-benar ada
if [ ! -f "$INPUT_APK" ]; then
    echo -e "\n${RED}❌ ERROR: File '$INPUT_APK' kaga ketemu!${NC}"
    echo -e "${YELLOW}>> Pastikan nama filenya bener dan filenya ada.${NC}"
    exit 1
fi

# 2. Persiapan Sebelum Eksekusi
echo -e "\n${YELLOW}⚙️  [PERSIAPAN] Mengecek alat dan folder...${NC}"

# Cek apakah uber-apk-signer.jar ada
if [ ! -f "$SIGNER_JAR" ]; then
    echo -e "\n${RED}❌ ERROR: Alat signer '$SIGNER_JAR' tidak ditemukan!${NC}"
    echo -e "${YELLOW}>> Solusi: Download 'uber-apk-signer.jar' dari GitHub dan taruh di folder 'script'.${NC}"
    exit 1
fi

# Buat folder output jika belum ada
mkdir -p "$OUTPUT_DIR"
echo -e "${GREEN}✅ Alat signer dan folder output SIAP!${NC}"

# 3. Logika Penamaan File (Bagian Paling Keren!)
# Ambil nama file saja, tanpa path folder
BASENAME=$(basename "$INPUT_APK")

# Buang embel-embel '-REBUILT.apk' atau '.apk' dari nama file
# Contoh: 'Pou-REBUILT.apk' -> 'Pou'
CLEAN_NAME=$(echo "$BASENAME" | sed -e 's/-REBUILT\.apk$//' -e 's/\.apk$//')

# Buat nama file akhir sesuai format yang diinginkan
FINAL_FILENAME="${CLEAN_NAME}-moded.apk"

# Gabungkan path folder output dengan nama file akhir
FINAL_PATH="$OUTPUT_DIR/$FINAL_FILENAME"

echo -e "\n${BLUE}>> File Input: $BASENAME"
echo -e "${GREEN}>> File Output Akan Disimpan di: $FINAL_PATH${NC}"

# 4. Eksekusi Perintah Sign
echo -e "\n${YELLOW}✍️  Memulai proses penandatanganan... Sabar ya, cuy...${NC}"

# Perintah untuk menjalankan uber-apk-signer
# --allowResign: Izinkan menimpa signature lama
# --in: File input
# --out: File output (lengkap dengan path)
java -jar "$SIGNER_JAR" --allowResign --in "$INPUT_APK" --out "$FINAL_PATH"

# 5. Cek Hasil Eksekusi
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}=================================================="
    echo "🎉 MANTAP JIWA! APK BERHASIL DI-SIGN! 🎉"
    echo "=================================================="
    echo -e "✅ File final lo udah siap di:"
    echo -e "${YELLOW}$FINAL_PATH${NC}"
    echo -e "\n${BLUE}Silakan install file itu di HP lo. Hati-hati kalo ada peringatan Play Protect, itu wajar buat APK modifan.${NC}"
else
    echo -e "\n${RED}=================================================="
    echo " GAGAL TOTAL! Proses signing error, cuy! "
    echo "=================================================="
    echo -e "Coba cek lagi pesan error di atas, mungkin ada yang salah sama file APK hasil rebuild-nya.${NC}"
    exit 1
fi

