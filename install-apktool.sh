#!/bin/bash

# =======================================================
#               INSTALL-APKTOOL.SH - Instalasi Rapi
# Script ini mengunduh Apktool.jar dan membuat alias.
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
APKTOOL_JAR="$HOME/script/apktool.jar"

if [ ! -f "$APKTOOL_JAR" ]; then
    echo -e "${YELLOW}🚀 [INSTAL] Mengunduh Apktool.jar ke $HOME/script/...${NC}"
    
    # Mengunduh JAR file (Wajib ada Wget dari install-java.sh)
    wget -O $APKTOOL_JAR https://github.com/iBotPeaches/Apktool/releases/latest/download/apktool.jar
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SUKSES! Apktool.jar sudah ada di folder script!${NC}"
    else
        echo -e "${RED}❌ GAGAL! Gagal mengunduh Apktool. Cek koneksi internet!${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Apktool.jar sudah ada. Skip download.${NC}"
fi

# 2. Membuat alias permanen di .bashrc
if ! grep -q "alias apktool=" ~/.bashrc; then
    echo -e "\n# Alias buat Apktool.sh\nalias apktool='java -jar $HOME/script/apktool.jar'" >> ~/.bashrc
    echo -e "${BLUE}💡 ALIAS ditambahkan ke .bashrc. SILAKAN RESTART TERMUX!${NC}"
else
    echo -e "${BLUE}💡 ALIAS 'apktool' sudah ada. Tidak ada perubahan.${NC}"
fi

echo -e "\n${BLUE}=================================================="
echo "Instalasi Apktool Selesai. Siap Bongkar Pou!"
echo "==================================================${NC}"
