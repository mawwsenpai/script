#!/bin/bash

# =======================================================
#               MOD-APK.SH - FIX STABIL & RAPIH
# Instalasi Java dan Apktool di Termux.
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
APKTOOL_JAR="$HOME/script/apktool.jar"

# 1. Pengecekan Dependencies STABIL (OpenJDK 11)
check_tools() {
    echo -e "${YELLOW}⚙️  [CEK] Memastikan Paket Dasar (Java & Wget) Terinstal...${NC}"
    pkg update -y 
    # Coba instal OpenJDK 11 (Paling stabil di Termux)
    if ! command -v java &> /dev/null
    then
        echo -e "${YELLOW}🛠️  Instalasi OpenJDK 11 dan Wget...${NC}"
        pkg install openjdk-11 wget -y
    fi
    
    if command -v java &> /dev/null
    then
        echo -e "${GREEN}✅ OK: Java dan Wget siap!${NC}"
    else
        echo -e "${RED}❌ ERROR KRITIS: Java GAGAL diinstal. Cek Termux repository.${NC}"
        exit 1
    fi
}

# 2. Instalasi Apktool (Rapi di Folder Script)
install_apktool() {
    echo -e "\n${YELLOW}🚀 [INSTAL] Mengunduh dan Setup Apktool ke $HOME/script/...${NC}"
    
    # 2a. Mengunduh JAR file (File utama Apktool)
    wget -O $APKTOOL_JAR https://github.com/iBotPeaches/Apktool/releases/latest/download/apktool.jar
    
    # 2b. Membuat fungsi baru untuk menjalankan Apktool
    # Kita tidak bisa pakai alias di dalam script, jadi kita pakai wrapper simpel.
    
    echo -e "${GREEN}🎉 SUKSES! Apktool.jar sekarang ada di $HOME/script/${NC}"
    echo -e ">> Untuk menjalankan Apktool, gunakan: ${YELLOW}java -jar apktool.jar${NC}"
}

# 3. Eksekusi
check_tools
install_apktool

echo -e "\n${BLUE}==================================================${NC}"
echo -e "${GREEN}INSTALASI SELESAI!${NC}"
echo -e "Sekarang kita lanjut ke Project HOMEPAGE! Jangan di-restart dulu!"
echo -e "${BLUE}==================================================${NC}"
