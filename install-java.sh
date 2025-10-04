#!/bin/bash

# =======================================================
#               INSTALL-JAVA.SH - AUTO-DETECT STABIL
# Script ini secara otomatis mencari dan menginstal versi JDK
# yang paling stabil dan tersedia di Termux.
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Daftar paket Java (JDK) yang paling sering tersedia, diurutkan dari baru ke lama/stabil
JDK_PACKAGES=("openjdk-17" "openjdk-11" "openjdk-8" "openjdk")
WGET_PACKAGE="wget"

echo -e "${YELLOW}⚙️  [CEK] Memastikan Sistem dan Repositori Stabil...${NC}"
pkg update -y && pkg upgrade -y

# Pengecekan apakah Java sudah terinstal
if command -v java &> /dev/null
then
    echo -e "${GREEN}✅ SUKSES! Java sudah terinstal stabil. Skip instalasi.${NC}"
    exit 0
fi

echo -e "\n${YELLOW}🛠️  [AUTO-DETECT] Mencari versi JDK yang cocok untuk Termux kamu...${NC}"

INSTALLED=false
for JDK_NAME in "${JDK_PACKAGES[@]}"; do
    echo -e "${BLUE}>> Mencoba instalasi: $JDK_NAME...${NC}"
    
    # Mencoba instalasi paket JDK dan WGET
    if pkg install "$JDK_NAME" "$WGET_PACKAGE" -y; then
        echo -e "${GREEN}✅ SUKSES! $JDK_NAME berhasil diinstal.${NC}"
        INSTALLED=true
        break # Berhasil, hentikan pencarian!
    else
        echo -e "${RED}❌ $JDK_NAME gagal ditemukan atau diinstal. Mencoba versi lain...${NC}"
    fi
done

# Pengecekan Final
if [ "$INSTALLED" = true ]; then
    echo -e "\n${GREEN}✅ SUKSES! JDK dan Wget siap! ${NC}"
else
    echo -e "\n${RED}❌ ERROR KRITIS: Semua upaya instalasi Java GAGAL.${NC}"
    echo -e ">> Solusi: Repository kamu mungkin bermasalah. Coba ganti mirror: 'termux-change-repo'."
    exit 1
fi

echo -e "\n${BLUE}=================================================="
echo "Instalasi Java Selesai. Lanjut instal Apktool!"
echo "==================================================${NC}"
