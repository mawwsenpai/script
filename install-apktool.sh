
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Konfigurasi Path ---
SCRIPT_DIR="$HOME/script"
APKTOOL_JAR="$SCRIPT_DIR/apktool.jar"
TERMUX_BIN_PATH="/data/data/com.termux/files/usr/bin"
WRAPPER_SCRIPT="$TERMUX_BIN_PATH/apktool"

# =================================================
#                 PROGRAM UTAMA
# =================================================

# 1. Cek Kebutuhan Dasar (Java & Wget/Curl)
echo -e "${YELLOW}⚙️  [CEK] Memeriksa kebutuhan dasar...${NC}"
if ! command -v java &> /dev/null; then
    echo -e "${RED}❌ ERROR: Java belum terinstal! Jalankan dulu script 'install-java.sh'.${NC}"
    exit 1
fi
if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    echo -e "${RED}❌ ERROR: 'wget' atau 'curl' tidak ditemukan! Install dulu: pkg install wget${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Kebutuhan dasar (Java & Wget/Curl) terpenuhi.${NC}"

# Buat folder ~/script jika belum ada
mkdir -p "$SCRIPT_DIR"

# 2. Proses Download Apktool.jar
if [ -f "$APKTOOL_JAR" ]; then
    echo -e "${GREEN}✅ Apktool.jar sudah ada. Skip download.${NC}"
else
    echo -e "${YELLOW}🚀 [INSTAL] Mencari Apktool versi terbaru dari GitHub...${NC}"
    
    # Mencari URL download versi terbaru secara dinamis via GitHub API
    LATEST_URL=$(wget -qO- "https://api.github.com/repos/iBotPeaches/Apktool/releases/latest" | grep "browser_download_url.*\.jar" | cut -d '"' -f 4)
    
    # URL cadangan jika API gagal (misal kena rate limit)
    FALLBACK_URL="https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar"

    if [ -z "$LATEST_URL" ]; then
        echo -e "${YELLOW}⚠️ Gagal mendapatkan link terbaru dari API, mencoba link cadangan...${NC}"
        DOWNLOAD_URL="$FALLBACK_URL"
    else
        echo -e "${GREEN}✅ Versi terbaru ditemukan! Mengunduh dari: $LATEST_URL${NC}"
        DOWNLOAD_URL="$LATEST_URL"
    fi

    # Mengunduh JAR file dengan progress bar
    wget -O "$APKTOOL_JAR" "$DOWNLOAD_URL"
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}✅ SUKSES! Apktool.jar berhasil diunduh ke '$SCRIPT_DIR'${NC}"
    else
        echo -e "\n${RED}❌ GAGAL! Gagal mengunduh Apktool. Cek koneksi internet!${NC}"
        rm -f "$APKTOOL_JAR" # Hapus file korup jika download gagal
        exit 1
    fi
fi

# 3. Membuat Wrapper Script (Lebih Baik dari Alias)
if [ -f "$WRAPPER_SCRIPT" ]; then
    echo -e "${GREEN}✅ Perintah 'apktool' sudah terpasang. Tidak ada perubahan.${NC}"
else
    echo -e "${YELLOW}🔧 [SETUP] Membuat perintah 'apktool' bisa diakses dari mana saja...${NC}"
    
    # Menulis script kecil yang akan menjadi perintah 'apktool'
    echo "#!/bin/bash" > "$WRAPPER_SCRIPT"
    echo "# Wrapper script untuk menjalankan Apktool.jar" >> "$WRAPPER_SCRIPT"
    echo "java -jar \"$APKTOOL_JAR\" \"\$@\"" >> "$WRAPPER_SCRIPT"
    
    # Memberi izin eksekusi
    chmod +x "$WRAPPER_SCRIPT"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SUKSES! Perintah 'apktool' sekarang aktif di seluruh sistem.${NC}"
        echo -e "${BLUE}💡 TIDAK PERLU RESTART! Langsung ketik 'apktool' di mana saja.${NC}"
    else
        echo -e "${RED}❌ GAGAL membuat wrapper script! Cek izin folder.${NC}"
        exit 1
    fi
fi

echo -e "\n${BLUE}=================================================="
echo "   Instalasi Apktool Selesai. Siap Beraksi!"
echo -e "==================================================${NC}"

