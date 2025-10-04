#!/bin/bash

# =======================================================
#               MOD-APK.SH - Pembongkar Game Offline
# Script ini menginstal tool untuk Reverse Engineering APK (Smali).
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

# 1. Pengecekan Dependencies
check_tools() {
    echo -e "${YELLOW}⚙️  [CEK] Memastikan Java dan Wget Terinstal...${NC}"
    pkg update -y
    
    # Apktool butuh Java
    if ! command -v java &> /dev/null
    then
        echo -e "${YELLOW}🛠️  Instalasi Java (OpenJDK) dan Wget...${NC}"
        pkg install openjdk-17 wget -y
    fi
    echo -e "${GREEN}✅ OK: Java dan Wget siap!${NC}"
}

# 2. Instalasi Apktool (Versi Terbaru)
install_apktool() {
    APKTOOL_DIR="/data/data/com.termux/files/usr/bin"
    APKTOOL_JAR="apktool.jar"
    
    echo -e "\n${YELLOW}🚀 [INSTAL] Mengunduh dan Setup Apktool...${NC}"

    # Mengunduh script wrapper
    wget -O $APKTOOL_DIR/apktool https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool
    chmod +x $APKTOOL_DIR/apktool

    # Mengunduh JAR file
    wget -O $APKTOOL_DIR/$APKTOOL_JAR https://github.com/iBotPeaches/Apktool/releases/latest/download/apktool.jar
    
    echo -e "${GREEN}🎉 SUKSES! Apktool sekarang bisa dipakai dari mana saja!${NC}"
}

# 3. Panduan Penggunaan yang Jelas
usage_guide() {
    echo -e "\n=================================================="
    echo -e "${GREEN}📝 PANDUAN BONGKAR APK (Reverse Engineering)${NC}"
    echo -e "=================================================="
    
    echo -e "${BLUE}STEP 1: Pindahkan APK ke Termux${NC}"
    echo ">> Pindahkan file game.apk kamu ke folder ${YELLOW}~/script/${NC}"
    
    echo -e "${BLUE}STEP 2: Bongkar (Disassemble)${NC}"
    echo ">> Ini akan membongkar kode ke folder baru (Contoh: ${YELLOW}game-folder/${NC}):"
    echo -e "${YELLOW}    apktool d [nama_file_game].apk -o game-folder${NC}"

    echo -e "\n${BLUE}STEP 3: Obrak-Abrik Kode!${NC}"
    echo ">> Masuk ke ${YELLOW}game-folder/smali/com/.../${NC}"
    echo ">> Cari file yang mungkin menyimpan nilai (misal: HealthActivity.smali)."
    echo ">> Edit pakai Nano: ${YELLOW}nano game-folder/smali/....smali${NC}"

    echo -e "\n${BLUE}STEP 4: Satukan Lagi (Rebuild)${NC}"
    echo ">> Setelah diedit, satukan lagi menjadi APK baru (Contoh: ${YELLOW}new-game.apk${NC}):"
    echo -e "${YELLOW}    apktool b game-folder -o new-game.apk${NC}"
    
    echo -e "\n${YELLOW}=================================================="
    echo "Sekarang kamu bisa instal APK yang sudah kamu modifikasi!"
    echo "Ini lebih **detail** dan **stabil** daripada ngurus izin folder!"
    echo "==================================================${NC}"
}

# 4. Eksekusi
check_tools
install_apktool
usage_guide
