#!/bin/bash

# =======================================================
#               BUILD-APK.SH - Modul Build dari Source Code
# Didesain profesional untuk membangun APK dari ZIP Project Gradle.
# Sekarang dengan Multi-Path File Check.
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
export PATH="$HOME/script:$PATH" 
BUILD_ROOT="$HOME/script/build-projects"
DOWNLOAD_PATH="$HOME/storage/downloads"
STORAGE_PATH="$HOME/storage/shared"

echo -e "=================================================="
echo -e "${BLUE}🏗️  BUILD-APK.SH | Membuat APK dari Source Code ZIP ${NC}"
echo -e "=================================================="

# 1. Cek Kesiapan Tool Wajib
if ! command -v java &> /dev/null; then
    echo -e "${RED}❌ ERROR: Java (JDK) belum terinstal. Jalankan Menu 0 dulu!${NC}"
    exit 1
fi
# Asumsi paket build tools (unzip, aapt, dx) sudah diinstal di main.sh

# 2. Pengecekan Lokasi File ZIP (Multi-Path Check Stabil)
echo -e "\n${YELLOW}Contoh: Cukup ketik nama file, misal: ${BLUE}Project.zip${NC}"
read -p ">> Masukkan NAMA FILE ZIP (Contoh: RevisiPro.zip): " ZIP_FILE

if [ -z "$ZIP_FILE" ]; then
    echo -e "${RED}❌ ERROR: Nama file ZIP tidak boleh kosong!${NC}"
    exit 1
fi

# Cek file di 3 lokasi stabil
if [ -f "$ZIP_FILE" ]; then
    ZIP_PATH="$ZIP_FILE"
    echo -e "${GREEN}✅ Ditemukan di: Folder Proyek (${ZIP_PATH})${NC}"
elif [ -f "$DOWNLOAD_PATH/$ZIP_FILE" ]; then
    ZIP_PATH="$DOWNLOAD_PATH/$ZIP_FILE"
    echo -e "${GREEN}✅ Ditemukan di: Folder Download (${DOWNLOAD_PATH}/...)${NC}"
elif [ -f "$STORAGE_PATH/$ZIP_FILE" ]; then
    ZIP_PATH="$STORAGE_PATH/$ZIP_FILE"
    echo -e "${GREEN}✅ Ditemukan di: Folder Internal Utama (${STORAGE_PATH}/...)${NC}"
else
    echo -e "${RED}❌ ERROR: File ZIP '$ZIP_FILE' tidak ditemukan di 3 lokasi wajib!${NC}"
    echo -e ">> Pastikan file ada di folder ini: ${YELLOW}$HOME/script/${NC} atau di folder ${YELLOW}Download${NC} HP kamu!"
    exit 1
fi

# 3. Ekstraksi dan Persiapan Build
PROJECT_NAME=$(basename "$ZIP_FILE" .zip)
PROJECT_DIR="$BUILD_ROOT/$PROJECT_NAME"

# Hapus folder lama (Clean up profesional)
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}🛠️  Menghapus folder proyek lama untuk *clean build*...${NC}"
    rm -rf "$PROJECT_DIR"
fi
mkdir -p "$PROJECT_DIR"

echo -e "\n${YELLOW}🛠️  Ekstraksi $ZIP_PATH ke $PROJECT_DIR...${NC}"
unzip -q "$ZIP_PATH" -d "$PROJECT_DIR"

# Pindah ke direktori project untuk menjalankan gradle
cd "$PROJECT_DIR" 
if [ ! -f "gradlew" ]; then
    echo -e "\n${RED}❌ ERROR KRITIS: File 'gradlew' (Gradle Wrapper) tidak ditemukan di dalam ZIP!${NC}"
    echo ">> Build GAGAL. Source code wajib menyertakan gradlew dan build.gradle."
    exit 1
fi

# 4. Proses Build menggunakan Gradle Wrapper
echo -e "\n${BLUE}🔨 Memulai proses Build menggunakan Gradle Wrapper...${NC}"
chmod +x gradlew 

# Jalankan Gradle dan simpan log error
./gradlew assembleDebug 2> build_error.log

if [ $? -eq 0 ]; then
    # 5. Finishing dan Pindahkan Hasil
    FIND_APK=$(find "$PROJECT_DIR" -name "*debug.apk" -print -quit)
    if [ -n "$FIND_APK" ]; then
        echo -e "\n${GREEN}🎉 SUKSES! APK berhasil dibuat: $(basename "$FIND_APK")${NC}"
        
        # Pindahkan APK ke folder Moded/Stable
        ./organizer.sh # Pastikan folder organizer dibuat
        
        cp "$FIND_APK" "$HOME/storage/FileMod/Moded/$(basename "$FIND_APK")"
        echo -e "${GREEN}>> APK dipindahkan ke Internal/FileMod/Moded/${NC}"
    else
        echo -e "${RED}❌ GAGAL: Gradle Build Sukses, tapi file APK tidak ditemukan!${NC}"
    fi
else
    echo -e "\n${RED}❌ GAGAL TOTAL: Gradle Build gagal. Menampilkan log error...${NC}"
    echo -e "=================================================="
    cat build_error.log
    echo -e "=================================================="
    echo -e "${YELLOW}>> Solusi: Cek error di atas. Mungkin masalah di file build.gradle.${NC}"
fi

echo -e "\n${BLUE}=================================================="
