#!/bin/bash

# =================================================================================
#               Setup-Modding v6.0 - Edisi Supremasi
#               By: Maww (dengan bantuan asisten AI)
#
#     Toolkit Installer terlengkap dan stabil untuk Modding, Development,
#                   dan Analisis Profesional di Termux.
# =================================================================================

# --- Konfigurasi Global & Palet Warna ---
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_BLUE='\033[1;34m';
C_PURPLE='\033[1;35m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

TOOLS_DIR="$HOME/tools"
BIN_DIR="/data/data/com.termux/files/usr/bin"
SDK_ROOT="$HOME/tools/android-sdk"
SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
SDK_PACKAGES="platform-tools build-tools;34.0.0 platforms;android-34"
mkdir -p "$TOOLS_DIR"

# =================================================
#        FUNGSI HELPER & MANAJEMEN VERSI
# =================================================

func_check_dependencies() {
    local missing_deps=()
    for dep in wget jq python git; do
        if ! command -v "$dep" &>/dev/null; then missing_deps+=("$dep"); fi
    done
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${C_YELLOW}Memasang dependensi dasar: ${missing_deps[*]}...${C_NC}"
        pkg install "${missing_deps[@]}" -y
    fi
}

func_get_version() {
    local tool="$1"
    case "$tool" in
        java) java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' ;;
        apktool|uber-signer)
            local version_file="$TOOLS_DIR/${tool,,}.version"
            if [ -f "$version_file" ]; then cat "$version_file"; else echo ""; fi ;;
        gradle) gradle -v | grep "Gradle" | awk '{print $2}' ;;
        frida) frida --version 2>/dev/null ;;
        radare2) r2 -v | head -n 1 | awk '{print $1}' ;;
        sdk) if [ -n "$ANDROID_HOME" ] && [ -d "$ANDROID_HOME/build-tools" ]; then echo "OK"; else echo ""; fi ;;
    esac
}

# =================================================
#            FUNGSI-FUNGSI INSTALASI
# =================================================

# --- Kategori 1: Lingkungan Dasar ---
func_install_java() {
    echo -e "\n${C_PURPLE}»»» Memeriksa Java (OpenJDK-17)...${C_NC}"
    if command -v java &>/dev/null; then echo -e "${C_GREEN}✅ Java sudah ada.${C_NC}"; return; fi
    pkg install openjdk-17 -y && echo -e "${C_GREEN}✅ Java berhasil diinstal.${C_NC}" || echo -e "${C_RED}❌ Gagal instal Java.${C_NC}"
}

func_configure_sdk() {
    echo -e "\n${C_PURPLE}»»» Memeriksa Konfigurasi Android SDK...${C_NC}"
    PROFILE_FILE=""
    if [ -f "$HOME/.zshrc" ]; then PROFILE_FILE="$HOME/.zshrc"; elif [ -f "$HOME/.bashrc" ]; then PROFILE_FILE="$HOME/.bashrc"; fi
    if grep -q "ANDROID_HOME=\"$SDK_ROOT\"" "$PROFILE_FILE" &>/dev/null; then echo -e "${C_GREEN}✅ Environment SDK sudah dikonfigurasi.${C_NC}"; return; fi
    
    echo -e "${C_YELLOW}SDK belum terkonfigurasi. Memulai instalasi & setup otomatis...${C_NC}"
    if [ ! -d "$SDK_ROOT" ]; then
        echo -e "${C_YELLOW}Mengunduh Android Command Line Tools... (Proses ini butuh waktu)${C_NC}"
        SDK_ZIP_TEMP="$TOOLS_DIR/sdk-tools-temp.zip"
        if ! wget -q --show-progress -O "$SDK_ZIP_TEMP" "$SDK_URL"; then echo -e "${C_RED}❌ Gagal unduh SDK.${C_NC}"; rm -f "$SDK_ZIP_TEMP"; return; fi
        echo -e "${C_YELLOW}Mengekstrak SDK...${C_NC}"; mkdir -p "$SDK_ROOT/cmdline-tools"; unzip -q "$SDK_ZIP_TEMP" -d "$SDK_ROOT/cmdline-tools"
        mv "$SDK_ROOT/cmdline-tools/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"; rm "$SDK_ZIP_TEMP"
        SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
        echo -e "${C_YELLOW}Menyetujui lisensi & menginstal paket inti... (SANGAT LAMA, HARAP SABAR)${C_NC}"
        yes | "$SDKMANAGER" --licenses >/dev/null 2>&1
        if ! "$SDKMANAGER" --install "$SDK_PACKAGES"; then echo -e "${C_RED}❌ Gagal instal paket SDK.${C_NC}"; return; fi
    fi

    echo -e "${C_YELLOW}🔧 Menulis konfigurasi permanen ke $PROFILE_FILE...${C_NC}"
    echo -e "\n# Konfigurasi Android SDK oleh Setup-Modding\nexport ANDROID_HOME=\"$SDK_ROOT\"" >>"$PROFILE_FILE"
    LATEST_BUILD_TOOLS=$(ls "$SDK_ROOT/build-tools" | sort -V | tail -n 1)
    echo "export PATH=\"\$PATH:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/$LATEST_BUILD_TOOLS\"" >>"$PROFILE_FILE"
    echo -e "${C_GREEN}✅ Konfigurasi selesai. Harap restart sesi Termux agar efeknya terasa.${C_NC}"; source "$PROFILE_FILE"
}

# --- Kategori 2 & 3: Modding & Development (Installer Dinamis) ---
func_installer_github() {
    local NAME="$1" REPO="$2" FILENAME_PATTERN="$3" BIN_NAME="$4" RECOMMENDED_VERSION="$5"
    RELEASES_JSON=$(wget -qO- "https://api.github.com/repos/$REPO/releases")
    LATEST_VERSION=$(echo "$RELEASES_JSON" | jq -r '.[0].tag_name' | sed 's/v//')
    CURRENT_VERSION=$(func_get_version "${NAME,,}")
    clear
    echo -e "${C_CYAN}---[ Manajer Instalasi untuk: $NAME ]---${C_NC}"
    echo -e "Versi Terinstal    : ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC}"
    echo -e "Versi Rekomendasi  : ${C_YELLOW}$RECOMMENDED_VERSION (Stabil)${C_NC}"
    echo -e "Versi Terbaru      : ${C_BLUE}$LATEST_VERSION${C_NC}"
    echo -e " [${C_YELLOW}R${C_NC}] Instal/Ganti ke versi Rekomendasi, [${C_BLUE}L${C_NC}] Terbaru, [${C_CYAN}M${C_NC}] Manual, [${C_RED}H${C_NC}] Hapus, [${C_PURPLE}B${C_NC}] Batal"
    read -p ">> Pilihan: " choice
    local VERSION_TO_INSTALL=""
    case "$choice" in
        [Rr]) VERSION_TO_INSTALL="$RECOMMENDED_VERSION" ;;
        [Ll]) VERSION_TO_INSTALL="$LATEST_VERSION" ;;
        [Mm]) read -p ">> Masukkan nomor versi: " VERSION_TO_INSTALL ;;
        [Hh]) rm -f "$BIN_DIR/$BIN_NAME" "$TOOLS_DIR/$FILENAME_PATTERN" "$TOOLS_DIR/${NAME,,}.version"; echo -e "${C_GREEN}✅ Dihapus.${C_NC}"; return ;;
        *) echo -e "${C_PURPLE}Dibatalkan.${C_NC}"; return ;;
    esac
    if [ -z "$VERSION_TO_INSTALL" ]; then echo -e "${C_RED}❌ Versi tidak valid. Batal.${C_NC}"; return; fi
    rm -f "$BIN_DIR/$BIN_NAME" "$TOOLS_DIR/$FILENAME_PATTERN" "$TOOLS_DIR/${NAME,,}.version"
    DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r ".[] | select(.tag_name | test(\"$VERSION_TO_INSTALL\")) | .assets[] | select(.name | test(\"$FILENAME_PATTERN\")) | .browser_download_url" | head -n 1)
    if [ -z "$DOWNLOAD_URL" ]; then echo -e "${C_RED}❌ Gagal menemukan aset download untuk versi $VERSION_TO_INSTALL.${C_NC}"; return; fi
    echo -e "${C_YELLOW}Mengunduh $NAME v$VERSION_TO_INSTALL...${C_NC}"
    if wget -q --show-progress -O "$TOOLS_DIR/$FILENAME_PATTERN" "$DOWNLOAD_URL"; then
        echo "#!/bin/bash\njava -jar \"$TOOLS_DIR/$FILENAME_PATTERN\" \"\$@\"" >"$BIN_DIR/$BIN_NAME"; chmod +x "$BIN_DIR/$BIN_NAME"
        echo "$VERSION_TO_INSTALL" > "$TOOLS_DIR/${NAME,,}.version"
        echo -e "${C_GREEN}✅ SUKSES! $NAME versi $VERSION_TO_INSTALL siap digunakan.${C_NC}"
    else echo -e "${C_RED}❌ GAGAL mengunduh.${C_NC}"; fi
}

func_install_pkg_tool() {
    local NAME="$1" PKG_NAME="$2"
    if ! command -v "$PKG_NAME" &>/dev/null; then
        echo -e "${C_YELLOW}Menginstal $NAME...${C_NC}"; pkg install "$PKG_NAME" -y
    else echo -e "${C_GREEN}✅ $NAME sudah terinstal.${C_NC}"; fi
}

func_install_pip_tool() {
    local NAME="$1" PIP_NAME="$2"
    if ! command -v "${PIP_NAME%%-*}" &>/dev/null; then
        echo -e "${C_YELLOW}Menginstal $NAME...${C_NC}"; pip install "$PIP_NAME"
    else echo -e "${C_GREEN}✅ $NAME sudah terinstal.${C_NC}"; fi
}


# =================================================
#                 UI & PROGRAM UTAMA
# =================================================

func_check_dependencies # Jalankan sekali di awal

while true; do
    # Ambil semua versi untuk ditampilkan di menu
    V_JAVA=$(func_get_version "java"); V_SDK=$(func_get_version "sdk")
    V_APKTOOL=$(func_get_version "apktool"); V_SIGNER=$(func_get_version "uber-signer")
    V_GRADLE=$(func_get_version "gradle"); V_FRIDA=$(func_get_version "frida"); V_R2=$(func_get_version "radare2")

    clear
    echo -e "${C_CYAN}╔═════════════════════════════════════════════════════════════════════════════╗"
    echo -e "║${C_YELLOW}                 Setup-Modding v6.0 - Edisi Supremasi                      ${C_CYAN}║"
    echo -e "║                          ${C_BLUE}By: Maww (Asisted by AI)${C_CYAN}                           ║"
    echo -e "╚═════════════════════════════════════════════════════════════════════════════╝${C_NC}"

    echo -e "${C_PURPLE}---[ A. Lingkungan Dasar ]-------------------------------------------------------${C_NC}"
    echo -e " 1. Instal Java (OpenJDK) ....................... ${C_GREEN}[${V_JAVA:-✘}]${C_NC}"
    echo -e " 2. Instal & Konfigurasi Android SDK ............ ${C_GREEN}[${V_SDK:-✘}]${C_NC}"
    
    echo -e "${C_PURPLE}---[ B. Modding & Reversing ]----------------------------------------------------${C_NC}"
    echo -e " 3. Manajer Apktool ............................. ${C_GREEN}[${V_APKTOOL:-✘}]${C_NC}"
    echo -e " 4. Manajer Uber APK Signer ..................... ${C_GREEN}[${V_SIGNER:-✘}]${C_NC}"
    
    echo -e "${C_PURPLE}---[ C. Development & Build ]----------------------------------------------------${C_NC}"
    echo -e " 5. Instal Gradle ............................... ${C_GREEN}[${V_GRADLE:-✘}]${C_NC}"

    echo -e "${C_PURPLE}---[ D. Analisis Lanjutan (Pro) ]----------------------------------------------${C_NC}"
    echo -e " 6. Instal Frida-Tools .......................... ${C_GREEN}[${V_FRIDA:-✘}]${C_NC}"
    echo -e " 7. Instal Radare2 .............................. ${C_GREEN}[${V_R2:-✘}]${C_NC}"
    
    echo -e "----------------------------------------------------------------------------------"
    echo -e " ${C_GREEN}AUTO. INSTALASI DASAR OTOMATIS (Java, SDK, Apktool, Signer)${C_NC}"
    echo -e " ${C_RED}Q. KELUAR${C_NC}"
    echo -e "----------------------------------------------------------------------------------"

    read -p ">> Masukkan Pilihan: " choice

    case "$choice" in
        1) func_install_java; press_enter ;;
        2) func_configure_sdk; press_enter ;;
        3) func_installer_github "Apktool" "iBotPeaches/Apktool" "apktool.jar" "apktool" "2.9.3" ;;
        4) func_installer_github "Uber-Signer" "patrickfav/uber-apk-signer" "uber-apk-signer" "uber-apk-signer" "1.3.0" ;;
        5) func_install_pkg_tool "Gradle" "gradle"; press_enter ;;
        6) func_install_pip_tool "Frida-Tools" "frida-tools"; press_enter ;;
        7) func_install_pkg_tool "Radare2" "radare2"; press_enter ;;
        [Aa][Uu][Tt][Oo])
            echo -e "\n${C_GREEN}🚀 Memulai Instalasi Dasar Otomatis... 🚀${C_NC}"
            func_install_java
            func_configure_sdk
            # Otomatis instal versi rekomendasi
            RECOMMENDED_APKTOOL="2.9.3"; CURRENT_APKTOOL=$(func_get_version "apktool")
            if [ "$CURRENT_APKTOOL" != "$RECOMMENDED_APKTOOL" ]; then
                echo -e "${C_YELLOW}Menginstal Apktool versi rekomendasi ($RECOMMENDED_APKTOOL)...${C_NC}"
                choice=r func_installer_github "Apktool" "iBotPeaches/Apktool" "apktool.jar" "apktool" "$RECOMMENDED_APKTOOL"
            else echo -e "${C_GREEN}✅ Apktool versi rekomendasi sudah terinstal.${C_NC}"; fi
            RECOMMENDED_SIGNER="1.3.0"; CURRENT_SIGNER=$(func_get_version "uber-signer")
            if [ "$CURRENT_SIGNER" != "$RECOMMENDED_SIGNER" ]; then
                 echo -e "${C_YELLOW}Menginstal Uber APK Signer versi rekomendasi ($RECOMMENDED_SIGNER)...${C_NC}"
                 choice=r func_installer_github "Uber-Signer" "patrickfav/uber-apk-signer" "uber-apk-signer" "uber-apk-signer" "$RECOMMENDED_SIGNER"
            else echo -e "${C_GREEN}✅ Uber APK Signer versi rekomendasi sudah terinstal.${C_NC}"; fi
            echo -e "\n${C_GREEN}🎉 Instalasi Dasar Selesai! Lingkungan modding Anda siap. 🎉${C_NC}"
            press_enter ;;
        [Qq]) echo -e "\n${C_BLUE}Sampai jumpa lagi, Senpai! Semangat ngoprek!${C_NC}"; exit 0 ;;
        *) echo -e "\n${C_RED}❌ Pilihan tidak valid.${C_NC}"; press_enter ;;
    esac
done

# Fungsi press_enter dipindahkan ke luar loop utama untuk efisiensi
press_enter() {
    echo -e "\n${C_YELLOW}Tekan [Enter] untuk kembali ke menu...${C_NC}"; read -r
}
