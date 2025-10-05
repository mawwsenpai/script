#!/bin/bash

# =================================================================================
#               Maww-Toolkit v7.0 - Edisi Profesional Definitif
#                  Powered by Maww-Core Engine v1.0
#
#     Toolkit modular dengan UI profesional, manajemen versi dinamis,
#          dan set alat lengkap untuk modding & analisis aplikasi.
# =================================================================================

# --- [1] KONFIGURASI GLOBAL & WARNA ---
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_BLUE='\033[1;34m';
C_PURPLE='\033[1;35m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'

TOOLS_DIR="$HOME/tools"; BIN_DIR="/data/data/com.termux/files/usr/bin"
SDK_ROOT="$HOME/tools/android-sdk"
mkdir -p "$TOOLS_DIR"
export PATH="$HOME/.local/bin:$PATH"

# --- [2] DATABASE TOOLS ---
# Format: "NAMA|TIPE|PAKET/REPO|FILE_JAR/BIN|VERSI_REKOMENDASI|DESKRIPSI"
TOOLS_DB=(
    "Java (OpenJDK 17)|pkg|openjdk-17|||Pondasi utama untuk semua tools"
    "Android SDK|sdk||||Perkakas resmi untuk membangun & analisis Android"
    "Apktool|github|iBotPeaches/Apktool|apktool.jar|2.9.3|Bongkar & rakit ulang file APK"
    "JADX|github|skylot/jadx|jadx|1.5.0|Decompiler DEX ke kode Java"
    "Uber APK Signer|github|patrickfav/uber-apk-signer|uber-apk-signer.jar|1.3.0|Menandatangani APK agar bisa diinstal"
    "Frida Tools|pip|frida-tools|||Framework analisis & injeksi dinamis"
    "mitmproxy|pip|mitmproxy|||Analisis & sadap lalu lintas jaringan (HTTP/S)"
    "Radare2|pkg|radare2|||Framework reverse engineering tingkat dewa"
    "Gradle|pkg|gradle|||Build automation tool untuk proyek Android"
    "mc|pkg|mc|||File manager TUI (Two-Panel)"
    "micro|pkg|micro|||Editor teks modern di terminal"
)

# --- [3] MAWW-CORE ENGINE: FUNGSI UI ---
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

print_header() {
    clear
    local width=$(tput cols)
    local title=" Maww-Toolkit v7.0 - Edisi Profesional Definitif "
    printf "${C_CYAN}╔%0.s═╗${C_NC}\n" $(seq 1 $((width - 2)))
    printf "${C_CYAN}║%*s${C_CYAN}║\n" $(( (width - 2 + ${#title}) / 2 )) "$title"
    printf "${C_CYAN}╚%0.s═╝${C_NC}\n" $(seq 1 $((width - 2)))
}

print_status_line() {
    local id="$1"; local name="$2"; local version="$3"; local desc="$4"
    if [ -n "$version" ]; then
        status="${C_GREEN}[✔ ${version}]${C_NC}"
    else
        status="${C_RED}[✘]${C_NC}"
    fi
    printf " [%.2s] %-20s %-18s %s\n" "$id" "$name" "$status" "$desc"
}

# --- [4] MAWW-CORE ENGINE: FUNGSI HELPER ---
check_dependencies() {
    if ! command -v jq &>/dev/null || ! command -v wget &>/dev/null; then
        echo -e "${C_YELLOW}Memasang dependensi inti (jq, wget)...${C_NC}"
        pkg install jq wget -y &>/dev/null
    fi
}

get_version() {
    local type="$1"; local pkg_name="$2"; local bin_name="$3"
    case "$type" in
        pkg) pkg show "$pkg_name" 2>/dev/null | grep 'Version:' | awk '{print $2}' ;;
        pip) pip show "$pkg_name" 2>/dev/null | grep 'Version:' | awk '{print $2}' ;;
        github)
            local version_file="$TOOLS_DIR/${bin_name,,}.version"
            if [ -f "$version_file" ]; then cat "$version_file"; fi ;;
        sdk) if [ -d "$SDK_ROOT/build-tools" ]; then echo "Terinstal"; fi ;;
        java) java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' ;;
    esac
}

# --- [5] MAWW-CORE ENGINE: MANAJER INSTALASI ---
manage_github_tool() {
    local NAME="$1" REPO="$2" FILENAME_PATTERN="$3" BIN_NAME="$4" RECOMMENDED_VERSION="$5"
    RELEASES_JSON=$(wget -qO- "https://api.github.com/repos/$REPO/releases")
    LATEST_VERSION=$(echo "$RELEASES_JSON" | jq -r '.[0].tag_name' | sed 's/v//')
    CURRENT_VERSION=$(get_version "github" "" "$BIN_NAME")

    print_header; echo -e "${C_CYAN}---[ Manajer untuk: $NAME ]---${C_NC}"
    echo -e "Versi Terinstal    : ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC}"
    echo -e "Versi Rekomendasi  : ${C_YELLOW}$RECOMMENDED_VERSION (Stabil)${C_NC}"
    echo -e "Versi Terbaru      : ${C_BLUE}$LATEST_VERSION${C_NC}"
    echo -e "\n [${C_YELLOW}R${C_NC}] Instal Rekomendasi | [${C_BLUE}L${C_NC}] Instal Terbaru | [${C_CYAN}M${C_NC}] Manual | [${C_RED}H${C_NC}] Hapus | [${C_PURPLE}B${C_NC}] Batal"
    read -p ">> Pilihan: " choice

    local VERSION_TO_INSTALL=""
    case "$choice" in
        [Rr]) VERSION_TO_INSTALL="$RECOMMENDED_VERSION" ;; [Ll]) VERSION_TO_INSTALL="$LATEST_VERSION" ;;
        [Mm]) read -p ">> Masukkan nomor versi: " VERSION_TO_INSTALL ;;
        [Hh]) rm -f "$BIN_DIR/$BIN_NAME" "$TOOLS_DIR/$FILENAME_PATTERN" "$TOOLS_DIR/${BIN_NAME,,}.version"; echo -e "${C_GREEN}✅ Dihapus.${C_NC}"; return ;;
        *) return ;;
    esac
    
    if [ -z "$VERSION_TO_INSTALL" ]; then echo -e "${C_RED}❌ Versi tidak valid.${C_NC}"; return; fi
    rm -f "$BIN_DIR/$BIN_NAME" "$TOOLS_DIR/$FILENAME_PATTERN" "$TOOLS_DIR/${BIN_NAME,,}.version"
    
    # Untuk JADX, nama file zip berbeda
    if [[ "$FILENAME_PATTERN" == "jadx" ]]; then
        DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r ".[] | select(.tag_name | contains(\"$VERSION_TO_INSTALL\")) | .assets[] | select(.name | contains(\"jadx-gui\") and contains(\"no-jre.zip\")) | .browser_download_url")
        echo -e "${C_YELLOW}Mengunduh $NAME v$VERSION_TO_INSTALL...${C_NC}"; (wget -qO "$TOOLS_DIR/jadx.zip" "$DOWNLOAD_URL") & spinner
        unzip -qo "$TOOLS_DIR/jadx.zip" -d "$TOOLS_DIR/" && mv "$TOOLS_DIR"/jadx-*-no-jre "$TOOLS_DIR/jadx-engine" && rm "$TOOLS_DIR/jadx.zip"
        ln -sfr "$TOOLS_DIR/jadx-engine/bin/jadx-gui" "$BIN_DIR/jadx"
    else # Untuk file .jar
        DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r ".[] | select(.tag_name | contains(\"$VERSION_TO_INSTALL\")) | .assets[] | select(.name | contains(\"$FILENAME_PATTERN\")) | .browser_download_url")
        echo -e "${C_YELLOW}Mengunduh $NAME v$VERSION_TO_INSTALL...${C_NC}"; (wget -qO "$TOOLS_DIR/$FILENAME_PATTERN" "$DOWNLOAD_URL") & spinner
        echo "#!/bin/bash\njava -jar \"$TOOLS_DIR/$FILENAME_PATTERN\" \"\$@\"" >"$BIN_DIR/$BIN_NAME"; chmod +x "$BIN_DIR/$BIN_NAME"
    fi
    echo "$VERSION_TO_INSTALL" > "$TOOLS_DIR/${BIN_NAME,,}.version"; echo -e "${C_GREEN}✅ SUKSES! $NAME v$VERSION_TO_INSTALL siap.${C_NC}"
}

manage_pkg_tool() {
    local NAME="$1" PKG_NAME="$2"
    CURRENT_VERSION=$(get_version "pkg" "$PKG_NAME")
    print_header; echo -e "${C_CYAN}---[ Manajer untuk: $NAME ]---${C_NC}"
    echo -e "Status: ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC}\n"
    echo -e " [${C_GREEN}I${C_NC}] Instal/Update | [${C_RED}H${C_NC}] Hapus | [${C_PURPLE}B${C_NC}] Batal"
    read -p ">> Pilihan: " choice
    case "$choice" in
        [Ii]) echo -e "${C_YELLOW}Menginstal/Update $NAME...${C_NC}"; (pkg install "$PKG_NAME" -y) & spinner; echo "Selesai.";;
        [Hh]) (pkg uninstall "$PKG_NAME" -y) & spinner; echo "Selesai.";;
        *) return ;;
    esac
}

manage_pip_tool() {
    local NAME="$1" PKG_NAME="$2"
    CURRENT_VERSION=$(get_version "pip" "$PKG_NAME")
    print_header; echo -e "${C_CYAN}---[ Manajer untuk: $NAME ]---${C_NC}"
    echo -e "Status: ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC}\n"
    echo -e " [${C_GREEN}I${C_NC}] Instal/Update | [${C_RED}H${C_NC}] Hapus | [${C_PURPLE}B${C_NC}] Batal"
    read -p ">> Pilihan: " choice
    case "$choice" in
        [Ii]) echo -e "${C_YELLOW}Menginstal/Update $NAME...${C_NC}"; (pip install --upgrade "$PKG_NAME") & spinner; echo "Selesai.";;
        [Hh]) (pip uninstall "$PKG_NAME" -y) & spinner; echo "Selesai.";;
        *) return ;;
    esac
}

manage_sdk() {
    (func_configure_sdk_core) & spinner
    echo -e "${C_GREEN}✅ Proses Pengecekan & Instalasi SDK Selesai.${C_NC}"
}
func_configure_sdk_core(){ # Fungsi inti sdk tanpa spinner agar bisa di background
    PROFILE_FILE=""
    if [ -f "$HOME/.zshrc" ]; then PROFILE_FILE="$HOME/.zshrc"; elif [ -f "$HOME/.bashrc" ]; then PROFILE_FILE="$HOME/.bashrc"; fi
    if grep -q "ANDROID_HOME=\"$SDK_ROOT\"" "$PROFILE_FILE" &>/dev/null && [ -d "$SDK_ROOT/build-tools" ]; then return; fi
    SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    SDK_PACKAGES="platform-tools build-tools;34.0.0 platforms;android-34"
    if [ ! -d "$SDK_ROOT/cmdline-tools" ]; then
        SDK_ZIP_TEMP="$TOOLS_DIR/sdk-tools-temp.zip"
        wget -qO "$SDK_ZIP_TEMP" "$SDK_URL"
        mkdir -p "$SDK_ROOT/cmdline-tools"; unzip -qo "$SDK_ZIP_TEMP" -d "$SDK_ROOT/cmdline-tools"
        mv "$SDK_ROOT/cmdline-tools/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"; rm "$SDK_ZIP_TEMP"
        SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
        yes | "$SDKMANAGER" --licenses &>/dev/null
        "$SDKMANAGER" --install "$SDK_PACKAGES" &>/dev/null
    fi
    echo -e "\n# Konfigurasi Android SDK oleh Maww-Toolkit\nexport ANDROID_HOME=\"$SDK_ROOT\"" >>"$PROFILE_FILE"
    LATEST_BUILD_TOOLS=$(ls "$SDK_ROOT/build-tools" | sort -V | tail -n 1)
    echo "export PATH=\"\$PATH:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/$LATEST_BUILD_TOOLS\"" >>"$PROFILE_FILE"
    source "$PROFILE_FILE"
}

# --- [6] PROGRAM UTAMA ---
check_dependencies
while true; do
    print_header
    echo -e " STATUS TOOLKIT PROFESIONAL ANDA:\n"
    id=0
    for tool_data in "${TOOLS_DB[@]}"; do
        IFS='|' read -r name type pkg_repo file_bin rec_ver desc <<< "$tool_data"
        id=$((id + 1))
        version=$(get_version "$type" "$pkg_repo" "$file_bin")
        print_status_line "$id" "$name" "$version" "$desc"
    done
    echo
    echo -e " [${C_GREEN}AUTO${C_NC}] Instalasi Wajib (Java, SDK, Apktool, JADX, Signer)"
    echo -e " [${C_RED}Q${C_NC}]     Keluar dari Toolkit"
    echo
    read -p ">> Masukkan nomor tool untuk membuka manajer, atau pilih opsi lain: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#TOOLS_DB[@]} ]; then
        tool_index=$((choice - 1))
        IFS='|' read -r name type pkg_repo file_bin rec_ver desc <<< "${TOOLS_DB[$tool_index]}"
        case "$type" in
            github) manage_github_tool "$name" "$pkg_repo" "$file_bin" "$file_bin" "$rec_ver" ;;
            pkg) manage_pkg_tool "$name" "$pkg_repo" ;;
            pip) manage_pip_tool "$name" "$pkg_repo" ;;
            sdk) manage_sdk ;;
            java) manage_pkg_tool "$name" "$pkg_repo" ;;
        esac
    else
        case "$choice" in
            [Aa][Uu][Tt][Oo])
                echo -e "${C_YELLOW}Memulai instalasi wajib...${C_NC}"
                (pkg install openjdk-17 -y) & spinner; echo "Java OK."
                manage_sdk;
                manage_github_tool "Apktool" "iBotPeaches/Apktool" "apktool.jar" "apktool" "2.9.3"
                manage_github_tool "JADX" "skylot/jadx" "jadx" "jadx" "1.5.0"
                manage_github_tool "Uber APK Signer" "patrickfav/uber-apk-signer" "uber-apk-signer.jar" "uber-apk-signer" "1.3.0"
                echo -e "${C_GREEN}✅ Instalasi Wajib Selesai!${C_NC}"
                ;;
            [Qq]) echo -e "\n${C_BLUE}Terima kasih telah menggunakan Maww-Toolkit!${C_NC}"; exit 0 ;;
            *) echo -e "\n${C_RED}❌ Pilihan tidak valid.${C_NC}" ;;
        esac
    fi
    echo -e "\n${C_YELLOW}Tekan [Enter] untuk kembali...${C_NC}"; read -r
done