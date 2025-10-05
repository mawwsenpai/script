#!/bin/bash

# ============================================================================
#             SETUP-MODDING.SH v3.0 - Edisi Mandiri
#     Script cerdas yang menginstal semua kebutuhan modding APK,
#         termasuk mengunduh dan mengonfigurasi Android SDK
#                        sepenuhnya otomatis.
# ============================================================================

# --- Palet Warna & Konfigurasi ---
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'
CYAN='\033[1;36m'; LPURPLE='\033[1;35m'

# --- Konfigurasi Path & Variabel Global ---
TOOLS_DIR="$HOME/tools"
TERMUX_BIN_PATH="/data/data/com.termux/files/usr/bin"
# Lokasi standar untuk instalasi Android SDK
SDK_ROOT="$HOME/tools/android-sdk"
# URL download command line tools (versi ini stabil dan teruji)
SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
# Paket SDK yang wajib diinstal
SDK_PACKAGES="platform-tools build-tools;34.0.0 platforms;android-34"

# Pastikan folder tools ada
mkdir -p "$TOOLS_DIR"

# =================================================
#                 FUNGSI-FUNGSI UTAMA
# =================================================

# --- Fungsi Instalasi Java (JDK) ---
func_install_java() {
    echo -e "\n${LPURPLE}»»» Memeriksa Java (OpenJDK-17)...${NC}"
    if command -v java &> /dev/null; then echo -e "${GREEN}✅ Java sudah ada. Skip.${NC}"; return; fi
    echo -e "${YELLOW}Menginstal Java...${NC}"
    if pkg install openjdk-17 -y; then echo -e "${GREEN}✅ SUKSES! Java berhasil diinstal.${NC}"; else echo -e "${RED}❌ GAGAL instal Java.${NC}"; fi
}

# --- Fungsi Download Cerdas dari GitHub ---
func_github_download() {
    local REPO_URL="$1"; local JAR_NAME="$2"; local WRAPPER_NAME="$3"; local JAR_PATH="$TOOLS_DIR/$JAR_NAME"
    echo -e "\n${LPURPLE}»»» Memeriksa $WRAPPER_NAME...${NC}"
    if [ -f "$TERMUX_BIN_PATH/$WRAPPER_NAME" ]; then echo -e "${GREEN}✅ '$WRAPPER_NAME' sudah ada. Skip.${NC}"; return; fi
    echo -e "${YELLOW}🔎 Mencari versi terbaru $WRAPPER_NAME...${NC}"
    LATEST_URL=$(wget -qO- "https://api.github.com/repos/$REPO_URL/releases/latest" | grep "browser_download_url" | grep -v ".asc" | cut -d '"' -f 4 | head -n 1)
    if [ -z "$LATEST_URL" ]; then echo -e "${RED}❌ Gagal mendapatkan link download $WRAPPER_NAME.${NC}"; return; fi
    echo -e "${GREEN}✅ Ditemukan! Mengunduh $WRAPPER_NAME...${NC}"
    if wget -q --show-progress -O "$JAR_PATH" "$LATEST_URL"; then
        echo -e "${GREEN}✅ SUKSES! $JAR_NAME diunduh.${NC}"
        echo -e "${YELLOW}🔧 Membuat perintah '$WRAPPER_NAME'...${NC}"
        echo "#!/bin/bash" > "$TERMUX_BIN_PATH/$WRAPPER_NAME"; echo "java -jar \"$JAR_PATH\" \"\$@\"" >> "$TERMUX_BIN_PATH/$WRAPPER_NAME"
        chmod +x "$TERMUX_BIN_PATH/$WRAPPER_NAME"; echo -e "${GREEN}✅ SUKSES! Perintah '$WRAPPER_NAME' siap.${NC}"
    else echo -e "${RED}❌ GAGAL mengunduh $JAR_NAME.${NC}"; rm -f "$JAR_PATH"; fi
}

# --- Fungsi Instalasi Alat Bantu ---
func_install_helpers() {
    echo -e "\n${LPURPLE}»»» Memeriksa Alat Bantu (unzip, wget, dll)...${NC}"
    if command -v unzip &> /dev/null; then echo -e "${GREEN}✅ Alat bantu sudah lengkap. Skip.${NC}"; return; fi
    echo -e "${YELLOW}Menginstal alat bantu...${NC}"
    if pkg install mc micro zip unzip wget -y; then echo -e "${GREEN}✅ SUKSES! Alat bantu diinstal.${NC}"; else echo -e "${RED}❌ GAGAL instal alat bantu.${NC}"; fi
}

# --- Fungsi Instalasi Android SDK Otomatis (BARU) ---
func_install_sdk() {
    echo -e "\n${LPURPLE}»»» Memulai Instalasi Android SDK Otomatis...${NC}"
    if [ -d "$SDK_ROOT" ]; then echo -e "${GREEN}✅ Folder Android SDK sudah ada. Skip instalasi.${NC}"; return 0; fi

    echo -e "${YELLOW}Downloading Android Command Line Tools... Ini mungkin butuh waktu.${NC}"
    SDK_ZIP_TEMP="$TOOLS_DIR/sdk-tools-temp.zip"
    if ! wget -q --show-progress -O "$SDK_ZIP_TEMP" "$SDK_URL"; then
        echo -e "${RED}❌ GAGAL mengunduh SDK. Cek koneksi internet.${NC}"; rm -f "$SDK_ZIP_TEMP"; return 1;
    fi

    echo -e "${YELLOW}Mengekstrak SDK...${NC}"
    # Struktur zip dari Google butuh perlakuan khusus
    mkdir -p "$SDK_ROOT/cmdline-tools"
    unzip -q "$SDK_ZIP_TEMP" -d "$SDK_ROOT/cmdline-tools"
    # Pindahkan dari folder 'cmdline-tools' ke 'latest' agar dikenali sdkmanager
    mv "$SDK_ROOT/cmdline-tools/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
    rm "$SDK_ZIP_TEMP"
    echo -e "${GREEN}✅ SDK diekstrak ke $SDK_ROOT${NC}"

    SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
    if [ ! -f "$SDKMANAGER" ]; then echo -e "${RED}❌ sdkmanager tidak ditemukan! Instalasi gagal.${NC}"; return 1; fi

    echo -e "${YELLOW}Menyetujui lisensi SDK secara otomatis...${NC}"
    yes | "$SDKMANAGER" --licenses > /dev/null 2>&1
    
    echo -e "${YELLOW}Menginstal paket SDK inti: $SDK_PACKAGES... (PROSES INI LAMA, SABAR YA CUY!) ${NC}"
    if ! "$SDKMANAGER" --install "$SDK_PACKAGES"; then
        echo -e "${RED}❌ GAGAL menginstal paket SDK. Coba ganti mirror Termux atau cek koneksi.${NC}"; return 1;
    fi

    echo -e "${GREEN}✅ SUKSES! Android SDK dan komponennya berhasil diinstal.${NC}"
    return 0
}

# --- Fungsi Konfigurasi Android SDK Cerdas (DIPERBARUI) ---
func_configure_sdk() {
    echo -e "\n${LPURPLE}»»» Memulai Konfigurasi Environment Android SDK...${NC}"
    
    # Cek & instal SDK jika belum ada
    if ! [ -d "$SDK_ROOT" ]; then
        echo -e "${YELLOW}Folder SDK tidak ditemukan. Menjalankan instalasi otomatis...${NC}"
        if ! func_install_sdk; then
            echo -e "${RED}❌ Instalasi SDK gagal, konfigurasi dibatalkan.${NC}"; return;
        fi
    fi
    
    # Cari file profile shell
    PROFILE_FILE=""
    if [ -f "$HOME/.zshrc" ]; then PROFILE_FILE="$HOME/.zshrc"; elif [ -f "$HOME/.bashrc" ]; then PROFILE_FILE="$HOME/.bashrc"; fi
    if [ -z "$PROFILE_FILE" ]; then echo -e "${RED}❌ .zshrc atau .bashrc tidak ditemukan.${NC}"; return; fi
    
    # Cek apakah sudah dikonfigurasi
    if grep -q "ANDROID_HOME=\"$SDK_ROOT\"" "$PROFILE_FILE"; then
        echo -e "${GREEN}✅ Android SDK sudah dikonfigurasi di $PROFILE_FILE. Skip.${NC}"; return;
    fi

    echo -e "${YELLOW}🔧 Menulis konfigurasi permanen ke $PROFILE_FILE...${NC}"
    echo "" >> "$PROFILE_FILE"
    echo "# Konfigurasi Android SDK oleh Script Installer v3.0" >> "$PROFILE_FILE"
    echo "export ANDROID_HOME=\"$SDK_ROOT\"" >> "$PROFILE_FILE"
    LATEST_BUILD_TOOLS=$(ls "$SDK_ROOT/build-tools" | sort -V | tail -n 1)
    echo "export PATH=\"\$PATH:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/$LATEST_BUILD_TOOLS\"" >> "$PROFILE_FILE"
    
    echo -e "${GREEN}✅ SUKSES! Konfigurasi disimpan.${NC}"
    echo -e "${YELLOW}🔥 PENTING: Tutup dan BUKA LAGI sesi Termux lo agar perubahan aktif! 🔥${NC}"
    # Memuat ulang konfigurasi untuk sesi saat ini agar status di menu terupdate
    source "$PROFILE_FILE"
}

# =================================================
#                 PROGRAM UTAMA
# =================================================

while true; do
    # Cek status instalasi setiap kali menu ditampilkan
    command -v java &> /dev/null && JAVA_STATUS="${GREEN}[✔]${NC}" || JAVA_STATUS="${RED}[✘]${NC}"
    command -v apktool &> /dev/null && APKTOOL_STATUS="${GREEN}[✔]${NC}" || APKTOOL_STATUS="${RED}[✘]${NC}"
    command -v uber-apk-signer &> /dev/null && SIGNER_STATUS="${GREEN}[✔]${NC}" || SIGNER_STATUS="${RED}[✘]${NC}"
    command -v unzip &> /dev/null && HELPERS_STATUS="${GREEN}[✔]${NC}" || HELPERS_STATUS="${RED}[✘]${NC}"
    [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ] && ANDROID_STATUS="${GREEN}[✔]${NC}" || ANDROID_STATUS="${RED}[✘]${NC}"

    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║   🚀 MODDING TOOLKIT INSTALLER v3.0 by Maww 🚀    ║"
    echo "║                - EDISI MANDIRI -                   ║"
    echo "╚══════════════════════════════════════════════════════╝${NC}"
    echo "--------------------------------------------------------"
    echo -e " 1. Install Java (OpenJDK-17) ............... $JAVA_STATUS"
    echo -e " 2. Install Apktool ......................... $APKTOOL_STATUS"
    echo -e " 3. Install Uber APK Signer ................. $SIGNER_STATUS"
    echo -e " 4. Install Alat Bantu (unzip, dll) ......... $HELPERS_STATUS"
    echo "--------------------------------------------------------"
    echo -e " 6. ${LPURPLE}Install & Configure Android SDK (Otomatis)${NC} $ANDROID_STATUS"
    echo "--------------------------------------------------------"
    echo -e " A. ${GREEN}INSTAL & SETUP SEMUA! (Rekomendasi) ${NC}"
    echo -e " Q. Keluar"
    echo "--------------------------------------------------------"
    
    read -p ">> Masukkan Pilihan: " choice

    case "$choice" in
        1) func_install_java ;;
        2) func_github_download "iBotPeaches/Apktool" "apktool.jar" "apktool" ;;
        3) func_github_download "patrickfav/uber-apk-signer" "uber-apk-signer.jar" "uber-apk-signer" ;;
        4) func_install_helpers ;;
        6) func_configure_sdk ;;
        [Aa])
            echo -e "\n${GREEN}🚀 Gaskeun, instal semua dari awal sampai akhir! 🚀${NC}"
            func_install_java
            func_install_helpers
            func_github_download "iBotPeaches/Apktool" "apktool.jar" "apktool"
            func_github_download "patrickfav/uber-apk-signer" "uber-apk-signer.jar" "uber-apk-signer"
            func_configure_sdk
            echo -e "\n${GREEN}🎉 SEMUA SELESAI! Toolkit modding lo siap tempur! 🎉${NC}"
            ;;
        [Qq]) echo -e "\n${BLUE}Oke, cabut dulu. Semangat ngoprek!${NC}"; exit 0 ;;
        *) echo -e "\n${RED}❌ Pilihan ngaco, cuy! Coba lagi.${NC}" ;;
    esac

    echo -e "\n${YELLOW}Tekan [Enter] untuk kembali ke menu...${NC}"
    read -r
done
