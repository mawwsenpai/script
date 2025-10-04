#!/bin/bash

# =====================================================================
#                BUILD-APK.SH v2.0 - Smart Project Builder
#   Script ini mengotomatiskan proses build dari source code ZIP
#          menjadi file APK menggunakan Gradle Wrapper.
# =====================================================================

# --- Palet Warna & Konfigurasi ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Folder temporary untuk proses unzip dan build (akan dihapus setelah selesai)
BUILD_DIR="$HOME/build_temp"

# Folder tujuan untuk menyimpan hasil akhir APK yang sudah jadi
OUTPUT_DIR="$HOME/storage/shared/MawwScript/built"

# Lokasi pencarian file ZIP
DOWNLOAD_PATH="$HOME/storage/downloads"
STORAGE_PATH="$HOME/storage/shared"

# =================================================
#                 PROGRAM UTAMA
# =================================================

clear
echo -e "${BLUE}--- Build APK dari Source Code ZIP ---${NC}"

# 1. Cek Kebutuhan Dasar
if ! command -v java &> /dev/null || ! command -v unzip &> /dev/null; then
    echo -e "\n${RED}❌ ERROR: Kebutuhan dasar belum terpenuhi!${NC}"
    echo ">> Pastikan ${YELLOW}Java (openjdk)${NC} dan ${YELLOW}unzip${NC} sudah terinstal."
    echo ">> Jalankan: pkg install openjdk-17 unzip"
    exit 1
fi

# 2. Cari File ZIP (Dibuat Pinter Biar Gak Salah Path)
read -p ">> Masukkan NAMA FILE ZIP (Contoh: MyGame.zip): " ZIP_FILE
if [ -z "$ZIP_FILE" ]; then
    echo -e "${RED}❌ ERROR: Nama file jangan kosong!${NC}"; exit 1
fi

ZIP_PATH=""
if [ -f "$ZIP_FILE" ]; then
    ZIP_PATH="$ZIP_FILE"
    echo -e "${GREEN}✅ Ditemukan di: Folder Proyek${NC}"
elif [ -f "$DOWNLOAD_PATH/$ZIP_FILE" ]; then
    ZIP_PATH="$DOWNLOAD_PATH/$ZIP_FILE"
    echo -e "${GREEN}✅ Ditemukan di: Folder Download${NC}"
elif [ -f "$STORAGE_PATH/$ZIP_FILE" ]; then
    ZIP_PATH="$STORAGE_PATH/$ZIP_FILE"
    echo -e "${GREEN}✅ Ditemukan di: Folder Internal Utama${NC}"
else
    echo -e "${RED}❌ ERROR: File '$ZIP_FILE' kaga ketemu di mana-mana!${NC}"
    exit 1
fi

# 3. Persiapan Lingkungan Build
echo -e "\n${YELLOW}⚙️  Mempersiapkan lingkungan build yang bersih...${NC}"
# Hapus sisa build lama dan buat folder baru yang bersih
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"
echo -e "${GREEN}✅ Lingkungan build siap di '$BUILD_DIR'${NC}"

# 4. Unzip Proyek
echo -e "\n${YELLOW}📦 Mengekstrak file dari '$ZIP_FILE'...${NC}"
if ! unzip -q "$ZIP_PATH" -d "$BUILD_DIR"; then
    echo -e "${RED}❌ GAGAL Ekstrak! File ZIP mungkin rusak atau korup.${NC}"
    rm -rf "$BUILD_DIR" # Bersihkan sampah
    exit 1
fi
echo -e "${GREEN}✅ Proyek berhasil diekstrak.${NC}"

# 5. Cari Folder Proyek & Beri Izin (INI BAGIAN KRITISNYA)
# Pindah ke direktori build untuk mempermudah pencarian
cd "$BUILD_DIR"

# Cari di mana letak file 'gradlew' berada
PROJECT_ROOT=$(find . -name "gradlew" -type f -exec dirname {} \; | head -n 1)

if [ -z "$PROJECT_ROOT" ]; then
    echo -e "${RED}❌ GAGAL! Tidak ditemukan file 'gradlew' di dalam ZIP.${NC}"
    echo -e "${YELLOW}>> Pastikan file ZIP berisi source code proyek Android yang valid.${NC}"
    cd ..
    rm -rf "$BUILD_DIR"
    exit 1
fi

echo -e "\n${YELLOW}🔍 Folder proyek terdeteksi di: '$PROJECT_ROOT'${NC}"
# Pindah ke folder proyek yang sebenarnya
cd "$PROJECT_ROOT"

echo -e "${YELLOW}🔑 Memberikan izin eksekusi untuk 'gradlew'... (Perbaikan Kritis!)${NC}"
chmod +x gradlew
echo -e "${GREEN}✅ Izin diberikan.${NC}"

# 6. Proses Build dengan Gradle
echo -e "\n${BLUE}=================================================="
echo "🚀 MEMULAI PROSES BUILD DENGAN GRADLE 🚀"
echo "Proses ini bisa makan waktu LAMA dan butuh koneksi internet stabil."
echo "Sabar ya, cuy... Bikin kopi dulu aja."
echo -e "==================================================${NC}"

# Menjalankan perintah build untuk versi 'Release'
if ./gradlew assembleRelease; then
    echo -e "\n${GREEN}🎉 BUILD BERHASIL! 🎉${NC}"
else
    echo -e "\n${RED}=================================================="
    echo "❌ BUILD GAGAL TOTAL! ❌"
    echo "Penyebab umum: Masalah di source code, versi Gradle tidak cocok, atau koneksi internet putus."
    echo -e "==================================================${NC}"
    cd ..; cd ..
    rm -rf "$BUILD_DIR"
    exit 1
fi

# 7. Cari & Pindahkan APK Hasil Build
echo -e "\n${YELLOW}🔍 Mencari file APK hasil build...${NC}"
# APK release biasanya ada di app/build/outputs/apk/release/
BUILT_APK=$(find . -name "*-release.apk" | head -n 1)

if [ -z "$BUILT_APK" ]; then
    echo -e "${RED}❌ Aneh! Build sukses tapi file APK-nya gak ketemu.${NC}"
    cd ..; cd ..
    rm -rf "$BUILD_DIR"
    exit 1
fi

# Ambil nama proyek dari nama zip untuk penamaan file akhir
PROJECT_NAME=$(basename "$ZIP_FILE" .zip)
FINAL_APK_PATH="$OUTPUT_DIR/${PROJECT_NAME}-built.apk"

echo -e "${GREEN}✅ APK ditemukan di '$BUILT_APK'${NC}"
echo -e "${YELLOW}🚚 Memindahkan APK ke folder output...${NC}"
mv "$BUILT_APK" "$FINAL_APK_PATH"

# 8. Bersih-bersih & Laporan Akhir
echo -e "\n${YELLOW}🧹 Membersihkan file temporary...${NC}"
cd ..; cd .. # Balik ke direktori awal
rm -rf "$BUILD_DIR"

echo -e "\n${GREEN}=================================================="
echo "✅ SEMUA SELESAI! APK SUDAH JADI! ✅"
echo "=================================================="
echo -e "File final lo udah siap di:"
echo -e "${YELLOW}$FINAL_APK_PATH${NC}"
echo -e "\n${BLUE}Langkah selanjutnya: Jalankan 'sign-apk.sh' untuk menandatangani APK ini sebelum diinstal.${NC}"
