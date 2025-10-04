#!/bin/bash

# =======================================================
#               MOD-APK.SH - Versi SUPER STABIL
# FIX: Error openjdk-17 dan command not found pada Apktool.
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'
APKTOOL_BIN="/data/data/com.termux/files/usr/bin"
APKTOOL_JAR_NAME="apktool.jar"
APKTOOL_WRAPPER="apktool-wrapper" # Nama baru biar gak tabrakan

# 1. Pengecekan Dependencies STABIL (Ganti ke openjdk-11)
check_tools() {
    echo -e "${YELLOW}⚙️  [CEK] Memastikan Paket Dasar (Java & Wget) Terinstal...${NC}"
    pkg update -y 
    pkg upgrade -y # Wajib upgrade biar repository stabil

    # Coba instal OpenJDK 11 (Lebih stabil di Termux)
    if ! command -v java &> /dev/null
    then
        echo -e "${YELLOW}🛠️  Instalasi OpenJDK 11 dan Wget...${NC}"
        pkg install openjdk-11 wget -y
    fi
    
    if command -v java &> /dev/null
    then
        echo -e "${GREEN}✅ OK: Java dan Wget siap!${NC}"
    else
        echo -e "${RED}❌ ERROR KRITIS: Java GAGAL diinstal. Perlu cek koneksi atau repository.${NC}"
        exit 1
    fi
}

# 2. Instalasi Apktool (Fix Path)
install_apktool() {
    echo -e "\n${YELLOW}🚀 [INSTAL] Mengunduh dan Setup Apktool...${NC}"
    
    # 2a. Mengunduh JAR file (File utama Apktool)
    wget -O $APKTOOL_BIN/$APKTOOL_JAR_NAME https://github.com/iBotPeaches/Apktool/releases/latest/download/apktool.jar
    
    # 2b. Membuat script wrapper baru (untuk menjalankan JAR)
    echo '#!/data/data/com.termux/files/usr/bin/bash' > $APKTOOL_BIN/$APKTOOL_WRAPPER
    echo 'java -jar $PREFIX/bin/apktool.jar "$@"' >> $APKTOOL_BIN/$APKTOOL_WRAPPER
    
    # 2c. Beri izin eksekusi ke wrapper
    chmod +x $APKTOOL_BIN/$APKTOOL_WRAPPER

    # 2d. Buat alias agar bisa dipanggil dengan 'apktool'
    if ! grep -q "alias apktool" ~/.bashrc; then
        echo -e "\n# Alias untuk Apktool\nalias apktool='$APKTOOL_WRAPPER'" >> ~/.bashrc
    fi

    echo -e "${GREEN}🎉 SUKSES! Apktool sudah dipasang. Restart Termux untuk menggunakan 'apktool'.${NC}"
}

# 3. Eksekusi
check_tools
install_apktool
# usage_guide sengaja dihilangkan agar user fokus restart
echo -e "\n${BLUE}=================================================="
echo "SILAKAN RESTART TERMUX (Tutup dan Buka lagi)!"
echo "Lalu ketik 'apktool' untuk cek instalasi!"
echo "==================================================${NC}"
