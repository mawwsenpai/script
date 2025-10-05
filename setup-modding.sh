#!/bin/bash

# ============================================================================
#             SETUP-MODDING.SH v2.0 - Edisi Stabil
#     Satu script untuk menginstal semua kebutuhan modding APK,
#              termasuk setup environment yang akurat.
# ============================================================================

# --- Palet Warna & Konfigurasi ---
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; BLUE='\033[1;34m'; NC='\033[0m'
CYAN='\033[1;36m'; LPURPLE='\033[1;35m'

# --- Konfigurasi Path ---
TOOLS_DIR="$HOME/tools"
TERMUX_BIN_PATH="/data/data/com.termux/files/usr/bin"

# Pastikan folder tools ada
mkdir -p "$TOOLS_DIR"

# =================================================
#                 FUNGSI-FUNGSI UTAMA
# =================================================

# --- Fungsi Instalasi Java (JDK) ---
func_install_java() {
    echo -e "\n${LPURPLE}»»» Memulai Instalasi Java (OpenJDK-17)...${NC}"
    if command -v java &> /dev/null; then
        echo -e "${GREEN}✅ Java sudah terinstal. Skip.${NC}"
        return
    fi
    if pkg install openjdk-17 -y; then
        echo -e "${GREEN}✅ SUKSES! Java (OpenJDK-17) berhasil diinstal.${NC}"
    else
        echo -e "${RED}❌ GAGAL instal Java. Coba ganti mirror repo dari menu utama.${NC}"
    fi
}

# --- Fungsi Download Cerdas dari GitHub ---
func_github_download() {
    local REPO_URL="$1"
    local JAR_NAME="$2"
    local WRAPPER_NAME="$3"
    local JAR_PATH="$TOOLS_DIR/$JAR_NAME"

    echo -e "\n${LPURPLE}»»» Memulai Instalasi $WRAPPER_NAME...${NC}"
    if [ -f "$TERMUX_BIN_PATH/$WRAPPER_NAME" ]; then
        echo -e "${GREEN}✅ Perintah '$WRAPPER_NAME' sudah ada. Skip.${NC}"
        return
    fi

    echo -e "${YELLOW}🔎 Mencari versi terbaru dari $WRAPPER_NAME...${NC}"
    LATEST_URL=$(wget -qO- "https://api.github.com/repos/$REPO_URL/releases/latest" | grep "browser_download_url" | grep -v ".asc" | cut -d '"' -f 4 | head -n 1)

    if [ -z "$LATEST_URL" ]; then
        echo -e "${RED}❌ Gagal mendapatkan link download $WRAPPER_NAME dari API GitHub.${NC}"
        return
    fi

    echo -e "${GREEN}✅ Ditemukan! Mengunduh dari: $LATEST_URL${NC}"
    if wget -O "$JAR_PATH" "$LATEST_URL"; then
        echo -e "${GREEN}✅ SUKSES! $JAR_NAME berhasil diunduh.${NC}"
        echo -e "${YELLOW}🔧 Membuat perintah '$WRAPPER_NAME'...${NC}"
        echo "#!/bin/bash" > "$TERMUX_BIN_PATH/$WRAPPER_NAME"
        echo "java -jar \"$JAR_PATH\" \"\$@\"" >> "$TERMUX_BIN_PATH/$WRAPPER_NAME"
        chmod +x "$TERMUX_BIN_PATH/$WRAPPER_NAME"
        echo -e "${GREEN}✅ SUKSES! Perintah '$WRAPPER_NAME' siap digunakan.${NC}"
    else
        echo -e "${RED}❌ GAGAL mengunduh $JAR_NAME. Cek koneksi internet.${NC}"
        rm -f "$JAR_PATH"
    fi
}

# --- Fungsi Instalasi Alat Bantu (DIPERBARUI) ---
func_install_helpers() {
    echo -e "\n${LPURPLE}»»» Memulai Instalasi Alat Bantu (mc, micro, zip, unzip)...${NC}"
    if pkg install mc micro zip unzip wget -y; then
        echo -e "${GREEN}✅ SUKSES! Alat bantu, termasuk 'unzip', berhasil diinstal.${NC}"
    else
        echo -e "${RED}❌ GAGAL instal alat bantu.${NC}"
    fi
}

# --- Fungsi Setup ANDROID_HOME (BARU) ---
func_setup_android_home() {
    echo -e "\n${LPURPLE}»»» Memulai Konfigurasi ANDROID_HOME...${NC}"
    echo -e "${YELLOW}Ini akan mengatur lokasi Android SDK lo secara permanen di Termux.${NC}"
    
    # Cari file profile shell yang ada
    PROFILE_FILE=""
    if [ -f "$HOME/.zshrc" ]; then
        PROFILE_FILE="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        PROFILE_FILE="$HOME/.bashrc"
    else
        echo -e "${RED}❌ Tidak ditemukan file .zshrc atau .bashrc. Tidak bisa melanjutkan.${NC}"
        return
    fi
    
    if grep -q "ANDROID_HOME" "$PROFILE_FILE"; then
        echo -e "${GREEN}✅ ANDROID_HOME sudah dikonfigurasi di $PROFILE_FILE. Skip.${NC}"
        return
    fi

    echo -e "${CYAN}Contoh path: /data/data/com.termux/files/home/BUILD-APK/sdk-tools${NC}"
    read -p ">> Masukkan path LENGKAP ke folder Android SDK lo: " SDK_PATH

    if [ -z "$SDK_PATH" ] || [ ! -d "$SDK_PATH" ]; then
        echo -e "${RED}❌ Path tidak valid atau folder tidak ada. Operasi dibatalkan.${NC}"
        return
    fi

    echo -e "\n${YELLOW}🔧 Menulis konfigurasi ke $PROFILE_FILE...${NC}"
    # Menambahkan baris kosong untuk kerapian
    echo "" >> "$PROFILE_FILE"
    echo "# Konfigurasi Android SDK oleh Script Installer v2.0" >> "$PROFILE_FILE"
    echo "export ANDROID_HOME=\"$SDK_PATH\"" >> "$PROFILE_FILE"
    # Menambahkan path tools ke PATH utama sistem
    echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >> "$PROFILE_FILE"
    # Menambahkan build-tools versi terbaru secara dinamis
    LATEST_BUILD_TOOLS=$(ls "$SDK_PATH/build-tools" | sort -V | tail -n 1)
    if [ -n "$LATEST_BUILD_TOOLS" ]; then
        echo "export PATH=\"\$PATH:\$ANDROID_HOME/build-tools/$LATEST_BUILD_TOOLS\"" >> "$PROFILE_FILE"
    fi
    
    echo -e "${GREEN}✅ SUKSES! Konfigurasi ANDROID_HOME berhasil disimpan.${NC}"
    echo -e "${YELLOW}🔥 PENTING: Tutup dan BUKA LAGI sesi Termux lo agar perubahan aktif! 🔥${NC}"
    # Memuat ulang konfigurasi untuk sesi saat ini
    source "$PROFILE_FILE"
}

# --- Fungsi Ganti Mirror Repo ---
func_change_repo() {
    echo -e "\n${BLUE}Mengalihkan ke menu pengaturan repositori Termux...${NC}"
    sleep 1; termux-change-repo
    echo -e "\n${YELLOW}⚙️  Menjalankan update setelah ganti mirror...${NC}"; pkg update -y
}

# =================================================
#                 PROGRAM UTAMA
# =================================================

while true; do
    # Cek status instalasi setiap kali menu ditampilkan
    [ -f "$TERMUX_BIN_PATH/apktool" ] && APKTOOL_STATUS="${GREEN}[✔ Terinstal]${NC}" || APKTOOL_STATUS="${RED}[✘ Belum]${NC}"
    [ -f "$TERMUX_BIN_PATH/uber-apk-signer" ] && SIGNER_STATUS="${GREEN}[✔ Terinstal]${NC}" || SIGNER_STATUS="${RED}[✘ Belum]${NC}"
    command -v java &> /dev/null && JAVA_STATUS="${GREEN}[✔ Terinstal]${NC}" || JAVA_STATUS="${RED}[✘ Belum]${NC}"
    command -v unzip &> /dev/null && HELPERS_STATUS="${GREEN}[✔ Terinstal]${NC}" || HELPERS_STATUS="${RED}[✘ Belum]${NC}"
    [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME" ] && ANDROID_STATUS="${GREEN}[✔ Tersetting]${NC}" || ANDROID_STATUS="${RED}[✘ Belum]${NC}"

    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║   🚀 MODDING TOOLKIT INSTALLER v2.0 by Maww 🚀    ║"
    echo "║               - EDISI STABIL & AKURAT -              ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}Pilih amunisi yang mau diinstal, cuy!${NC}"
    echo "----------------------------------------------------"
    echo -e " 1. Install Java (OpenJDK-17)          $JAVA_STATUS"
    echo -e " 2. Install Apktool (De/Recompile)       $APKTOOL_STATUS"
    echo -e " 3. Install Uber APK Signer (Sign)     $SIGNER_STATUS"
    echo -e " 4. Install Alat Bantu (zip, unzip, dll) $HELPERS_STATUS"
    echo "----------------------------------------------------"
    echo -e " 6. ${LPURPLE}Setup ANDROID_HOME (PENTING!)       $ANDROID_STATUS${NC}"
    echo "----------------------------------------------------"
    echo -e " A. ${GREEN}INSTAL & SETUP SEMUA! (Rekomendasi) ${NC}"
    echo -e " R. Ganti Mirror Repositori (Jika Gagal Instal)"
    echo -e " Q. Keluar"
    echo "----------------------------------------------------"
    
    read -p ">> Masukkan Pilihan: " choice

    case "$choice" in
        1) func_install_java ;;
        2) func_github_download "iBotPeaches/Apktool" "apktool.jar" "apktool" ;;
        3) func_github_download "patrickfav/uber-apk-signer" "uber-apk-signer.jar" "uber-apk-signer" ;;
        4) func_install_helpers ;;
        6) func_setup_android_home ;;
        [Aa])
            echo -e "\n${GREEN}🚀 Gaskeun, instal semua dari awal sampai akhir! 🚀${NC}"
            func_install_java
            func_install_helpers
            func_github_download "iBotPeaches/Apktool" "apktool.jar" "apktool"
            func_github_download "patrickfav/uber-apk-signer" "uber-apk-signer.jar" "uber-apk-signer"
            func_setup_android_home
            echo -e "\n${GREEN}🎉 SEMUA SELESAI! Toolkit modding lo siap tempur! 🎉${NC}"
            ;;
        [Rr]) func_change_repo ;;
        [Qq]) echo -e "\n${BLUE}Oke, cabut dulu. Semangat ngoprek!${NC}"; exit 0 ;;
        *) echo -e "\n${RED}❌ Pilihan ngaco, cuy! Coba lagi.${NC}" ;;
    esac

    echo -e "\n${YELLOW}Tekan [Enter] untuk kembali ke menu...${NC}"
    read -r
done
