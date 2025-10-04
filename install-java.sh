#!/bin/bash

# =======================================================
#               INSTALL-JAVA.SH - Fix Stabil JDK
# Script ini mengatasi masalah 'openjdk-17' dengan menginstal
# versi Java yang paling stabil di Termux (OpenJDK 11).
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo -e "${YELLOW}⚙️  [CEK] Memastikan Sistem dan Repositori Stabil...${NC}"
pkg update -y && pkg upgrade -y

# Pengecekan dan Instalasi Java/JDK
if ! command -v java &> /dev/null
then
    echo -e "${YELLOW}🛠️  Instalasi OpenJDK 11 dan Wget (Wajib untuk Apktool)...${NC}"
    # FIX KRITIS: openjdk-17 diganti ke openjdk-11
    pkg install openjdk-11 wget -y
fi

if command -v java &> /dev/null
then
    echo -e "${GREEN}✅ SUKSES! Java (OpenJDK 11) dan Wget siap!${NC}"
else
    echo -e "${RED}❌ ERROR KRITIS: Java GAGAL diinstal. Perlu cek koneksi atau repository.${NC}"
    exit 1
fi

echo -e "\n${BLUE}=================================================="
echo "Instalasi Java Selesai. Lanjut instal Apktool!"
echo "==================================================${NC}"
