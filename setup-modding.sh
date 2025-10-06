#!/bin/bash

# =================================================================================
#               Maww-Toolkit v7.1 - Edisi UI & Instalasi Superior
#                      Powered by Maww-Core Engine v1.1
#
#       Toolkit modular dengan UI terminal yang bersih, manajemen versi,
#       dan alur instalasi yang jelas untuk modding & analisis aplikasi.
# =================================================================================

# --- [1] KONFIGURASI GLOBAL & WARNA ---
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_BLUE='\033[1;34m';
C_PURPLE='\033[1;35m'; C_CYAN='\033[1;36m'; C_NC='\033[0m'
TOOLKIT_VERSION="v7.1"
TOOLS_DIR="$HOME/tools"; BIN_DIR="/data/data/com.termux/files/usr/bin"
SDK_ROOT="$HOME/tools/android-sdk"
mkdir -p "$TOOLS_DIR" 2>/dev/null
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

# --- [3] MAWW-CORE ENGINE: FUNGSI UI & HELPER ---
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${C_CYAN}[%c]${C_NC}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

print_header() {
    clear
    local title="Maww-Toolkit $TOOLKIT_VERSION - Edisi UI & Instalasi Superior"
    local line="================================================================"
    
    # Header yang lebih simple dan tidak bergantung pada tput
    echo -e "${C_CYAN}$line${C_NC}"
    echo -e "${C_CYAN}# ${C_NC}${C_YELLOW}$title${C_NC}"
    echo -e "${C_CYAN}# ${C_NC}Toolkit modular untuk Modding & Analisis Aplikasi"
    echo -e "${C_CYAN}$line${C_NC}"
    echo
}

print_status_line() {
    local id="$1"; local name="$2"; local version="$3"; local rec_ver="$4"; local desc="$5"
    local STATUS_TEXT=""
    local STATUS_COLOR=""

    if [ -n "$version" ] && [[ "$version" != "Belum Terinstal" ]]; then
        STATUS_TEXT="[✔ $version]"
        STATUS_COLOR="${C_GREEN}"
    elif [ -n "$rec_ver" ]; then
        STATUS_TEXT="[✘ Target: $rec_ver]"
        STATUS_COLOR="${C_RED}"
    else
        STATUS_TEXT="[✘ Belum Terinstal]"
        STATUS_COLOR="${C_RED}"
    fi

    printf " %s[%-2s]%s %-20s %s%-23s%s %s\n" "${C_CYAN}" "$id" "${C_NC}" "$name" "$STATUS_COLOR" "$STATUS_TEXT" "${C_NC}" "$desc"
}

check_dependencies() {
    local NEED_INSTALL=""
    # Pengecekan inti untuk operasi script
    for dep in jq wget unzip grep; do
        if ! command -v $dep &>/dev/null; then
            NEED_INSTALL+="$dep "
        fi
    done

    if [ -n "$NEED_INSTALL" ]; then
        echo -e "${C_YELLOW}Memasang dependensi inti ($NEED_INSTALL)...${C_NC}"
        pkg install $NEED_INSTALL -y &>/dev/null & spinner
        echo -e "${C_GREEN}✅ Dependensi inti selesai.${C_NC}"
    fi
}

get_version() {
    local type="$1"; local pkg_name="$2"; local file_bin="$3"
    case "$type" in
        pkg) pkg show "$pkg_name" 2>/dev/null | grep 'Version:' | awk '{print $2}' ;;
        pip) pip show "$pkg_name" 2>/dev/null | grep 'Version:' | awk '{print $2}' ;;
        github)
            local version_file="$TOOLS_DIR/${file_bin,,}.version"
            if [ -f "$version_file" ]; then cat "$version_file"; fi ;;
        sdk) if [ -d "$SDK_ROOT/build-tools" ]; then echo "Terinstal"; fi ;;
        java) java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' ;;
    esac
}

# --- [4] MAWW-CORE ENGINE: MANAJER INSTALASI ---
manage_github_tool() {
    local NAME="$1" REPO="$2" FILENAME_PATTERN="$3" BIN_NAME="$4" RECOMMENDED_VERSION="$5"
    print_header; echo -e "${C_CYAN}---[ Manajer untuk: $NAME ]---${C_NC}"
    
    echo -e "${C_YELLOW}Mengambil info rilis terbaru...${C_NC}"; (RELEASES_JSON=$(wget -qO- "https://api.github.com/repos/$REPO/releases")) & spinner
    
    LATEST_VERSION=$(echo "$RELEASES_JSON" | jq -r '.[0].tag_name' 2>/dev/null | sed 's/v//')
    CURRENT_VERSION=$(get_version "github" "" "$BIN_NAME")

    echo -e "Versi Terinstal    : ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC}"
    echo -e "Versi Rekomendasi  : ${C_YELLOW}$RECOMMENDED_VERSION (Stabil)${C_NC}"
    echo -e "Versi Terbaru      : ${C_BLUE}${LATEST_VERSION:-'Error'}${C_NC}"
    echo -e "\n [${C_YELLOW}R${C_NC}] Instal Rekomendasi | [${C_BLUE}L${C_NC}] Instal Terbaru | [${C_RED}H${C_NC}] Hapus | [${C_PURPLE}B${C_NC}] Batal"
    read -p ">> Pilihan: " choice

    local VERSION_TO_INSTALL=""
    case "$choice" in
        [Rr]) VERSION_TO_INSTALL="$RECOMMENDED_VERSION" ;; 
        [Ll]) VERSION_TO_INSTALL="$LATEST_VERSION" ;;
        [Hh]) rm -f "$BIN_DIR/$BIN_NAME" "$TOOLS_DIR/$FILENAME_PATTERN" "$TOOLS_DIR/${BIN_NAME,,}.version" "$TOOLS_DIR/jadx.zip"; echo -e "${C_GREEN}✅ $NAME Dihapus.${C_NC}"; return ;;
        *) return ;;
    esac
    
    if [ -z "$VERSION_TO_INSTALL" ] || [[ "$VERSION_TO_INSTALL" == "null" ]]; then echo -e "${C_RED}❌ Versi tidak ditemukan/invalid.${C_NC}"; return; fi
    
    echo -e "${C_YELLOW}Menghapus instalasi lama...${C_NC}"
    rm -f "$BIN_DIR/$BIN_NAME" "$TOOLS_DIR/$FILENAME_PATTERN" "$TOOLS_DIR/${BIN_NAME,,}.version" 2>/dev/null
    
    echo -e "${C_YELLOW}Mengunduh $NAME v$VERSION_TO_INSTALL...${C_NC}"
    if [[ "$FILENAME_PATTERN" == "jadx" ]]; then
        DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r ".[] | select(.tag_name | contains(\"$VERSION_TO_INSTALL\")) | .assets[] | select(.name | contains(\"jadx-gui\") and contains(\"no-jre.zip\")) | .browser_download_url")
        if [ -z "$DOWNLOAD_URL" ]; then echo -e "${C_RED}❌ Link download JADX v$VERSION_TO_INSTALL tidak ditemukan!${C_NC}"; return; fi
        (wget -qO "$TOOLS_DIR/jadx.zip" "$DOWNLOAD_URL") & spinner
        
        echo -e "${C_YELLOW}Mengekstrak dan konfigurasi JADX...${C_NC}"
        unzip -qo "$TOOLS_DIR/jadx.zip" -d "$TOOLS_DIR/" 
        mv "$TOOLS_DIR"/jadx-*-no-jre "$TOOLS_DIR/jadx-engine" 2>/dev/null
        ln -sfr "$TOOLS_DIR/jadx-engine/bin/jadx" "$BIN_DIR/jadx-cli" 2>/dev/null # Ubah nama bin agar tidak konflik
        ln -sfr "$TOOLS_DIR/jadx-engine/bin/jadx-gui" "$BIN_DIR/jadx" 2>/dev/null
        rm "$TOOLS_DIR/jadx.zip"
    else # Untuk file .jar (Apktool, Signer)
        DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r ".[] | select(.tag_name | contains(\"$VERSION_TO_INSTALL\")) | .assets[] | select(.name | contains(\"$FILENAME_PATTERN\")) | .browser_download_url")
        if [ -z "$DOWNLOAD_URL" ]; then echo -e "${C_RED}❌ Link download $NAME v$VERSION_TO_INSTALL tidak ditemukan!${C_NC}"; return; fi
        (wget -qO "$TOOLS_DIR/$FILENAME_PATTERN" "$DOWNLOAD_URL") & spinner
        
        echo -e "${C_YELLOW}Membuat symlink executable...${C_NC}"
        echo "#!/bin/bash\njava -jar \"$TOOLS_DIR/$FILENAME_PATTERN\" \"\$@\"" >"$BIN_DIR/$BIN_NAME"
        chmod +x "$BIN_DIR/$BIN_NAME"
    fi
    echo "$VERSION_TO_INSTALL" > "$TOOLS_DIR/${BIN_NAME,,}.version"
    echo -e "${C_GREEN}✅ SUKSES! $NAME v$VERSION_TO_INSTALL siap digunakan.${C_NC}"
}

manage_pkg_tool() {
    local NAME="$1" PKG_NAME="$2"
    CURRENT_VERSION=$(get_version "pkg" "$PKG_NAME")
    print_header; echo -e "${C_CYAN}---[ Manajer untuk: $NAME ]---${C_NC}"
    echo -e "Status Terinstal: ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC}\n"
    echo -e " [${C_GREEN}I${C_NC}] Instal/Update | [${C_RED}H${C_NC}] Hapus | [${C_PURPLE}B${C_NC}] Batal"
    read -p ">> Pilihan: " choice
    case "$choice" in
        [Ii]) echo -e "${C_YELLOW}Menginstal/Update $NAME ($PKG_NAME)...${C_NC}"; (pkg install "$PKG_NAME" -y) & spinner; echo -e "${C_GREEN}✅ Selesai.${C_NC}";;
        [Hh]) echo -e "${C_RED}Menghapus $NAME ($PKG_NAME)...${C_NC}"; (pkg uninstall "$PKG_NAME" -y) & spinner; echo -e "${C_GREEN}✅ Selesai.${C_NC}";;
        *) return ;;
    esac
}

manage_pip_tool() {
    local NAME="$1" PKG_NAME="$2"
    CURRENT_VERSION=$(get_version "pip" "$PKG_NAME")
    print_header; echo -e "${C_CYAN}---[ Manajer untuk: $NAME ]---${C_NC}"
    echo -e "Status Terinstal: ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC}\n"
    echo -e " [${C_GREEN}I${C_NC}] Instal/Update | [${C_RED}H${C_NC}] Hapus | [${C_PURPLE}B${C_NC}] Batal"
    read -p ">> Pilihan: " choice
    case "$choice" in
        [Ii]) echo -e "${C_YELLOW}Menginstal/Update $NAME ($PKG_NAME) via pip...${C_NC}"; (pip install --upgrade "$PKG_NAME") & spinner; echo -e "${C_GREEN}✅ Selesai.${C_NC}";;
        [Hh]) echo -e "${C_RED}Menghapus $NAME ($PKG_NAME) via pip...${C_NC}"; (pip uninstall "$PKG_NAME" -y) & spinner; echo -e "${C_GREEN}✅ Selesai.${C_NC}";;
        *) return ;;
    esac
}

manage_sdk() {
    print_header; echo -e "${C_CYAN}---[ Manajer untuk: Android SDK ]---${C_NC}"
    if [ -d "$SDK_ROOT/build-tools" ]; then
        LATEST_BUILD_TOOLS=$(ls "$SDK_ROOT/build-tools" | sort -V | tail -n 1)
        echo -e "Status Terinstal: ${C_GREEN}Terinstal (Build-Tools $LATEST_BUILD_TOOLS)${C_NC}\n"
        echo -e " [${C_YELLOW}U${C_NC}] Update | [${C_RED}H${C_NC}] Hapus | [${C_PURPLE}B${C_NC}] Batal"
        read -p ">> Pilihan: " choice
        case "$choice" in
            [Uu]) ;; # Lanjut ke proses update/install
            [Hh]) echo -e "${C_RED}Menghapus folder SDK...${C_NC}"; rm -rf "$SDK_ROOT"; echo -e "${C_GREEN}✅ Dihapus.${C_NC}"; return ;;
            *) return ;;
        esac
    fi

    echo -e "\n [${C_GREEN}I${C_NC}] Mulai Instalasi/Update SDK Manager & Tools (Otomatis)"
    read -p ">> Pilihan: " choice
    if [[ "$choice" =~ ^[Ii]$ ]]; then
        func_configure_sdk_core
        echo -e "${C_GREEN}✅ Proses Instalasi & Konfigurasi SDK Selesai!${C_NC}"
    fi
}

func_configure_sdk_core(){ 
    local PROFILE_FILE="$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then PROFILE_FILE="$HOME/.zshrc"; fi

    if grep -q "ANDROID_HOME=\"$SDK_ROOT\"" "$PROFILE_FILE" &>/dev/null && [ -d "$SDK_ROOT/build-tools" ]; then 
        echo -e "${C_YELLOW}SDK sudah terdeteksi di $SDK_ROOT.${C_NC}";
    fi
    
    local SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    local SDK_PACKAGES="platform-tools build-tools;34.0.0 platforms;android-34"
    local SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
    
    if [ ! -d "$SDK_ROOT/cmdline-tools/latest" ]; then
        echo -e "${C_YELLOW} [1/5] Mengunduh Android Command Line Tools...${C_NC}"; local SDK_ZIP_TEMP="$TOOLS_DIR/sdk-tools-temp.zip"
        (wget -qO "$SDK_ZIP_TEMP" "$SDK_URL") & spinner
        
        echo -e "${C_YELLOW} [2/5] Mengekstrak SDK Manager...${C_NC}"
        mkdir -p "$SDK_ROOT/cmdline-tools"
        unzip -qo "$SDK_ZIP_TEMP" -d "$SDK_ROOT/cmdline-tools"
        mv "$SDK_ROOT/cmdline-tools/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest" 2>/dev/null
        rm "$SDK_ZIP_TEMP"
    fi

    if [ -f "$SDKMANAGER" ]; then
        echo -e "${C_YELLOW} [3/5] Menyetujui Lisensi SDK...${C_NC}"
        yes | "$SDKMANAGER" --licenses &>/dev/null
        echo -e "${C_YELLOW} [4/5] Menginstal SDK Packages ($SDK_PACKAGES)...${C_NC}"
        ("$SDKMANAGER" --install "$SDK_PACKAGES" &>/dev/null) & spinner
    fi

    echo -e "${C_YELLOW} [5/5] Mengkonfigurasi PATH di $PROFILE_FILE...${C_NC}"
    grep -qF 'ANDROID_HOME' "$PROFILE_FILE" || echo -e "\n# Konfigurasi Android SDK oleh Maww-Toolkit\nexport ANDROID_HOME=\"$SDK_ROOT\"" >>"$PROFILE_FILE"
    
    LATEST_BUILD_TOOLS=$(ls "$SDK_ROOT/build-tools" 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$LATEST_BUILD_TOOLS" ]; then
        # Hapus PATH lama (jika ada) dan tambahkan yang baru
        sed -i '/ANDROID_HOME/d' "$PROFILE_FILE"
        sed -i '/platform-tools/d' "$PROFILE_FILE"
        echo -e "export ANDROID_HOME=\"$SDK_ROOT\"" >>"$PROFILE_FILE"
        echo "export PATH=\"\$PATH:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/$LATEST_BUILD_TOOLS\"" >>"$PROFILE_FILE"
    fi
    
    # Reload profile untuk memastikan PATH baru terpakai
    source "$PROFILE_FILE" 2>/dev/null
}

# --- [5] PROGRAM UTAMA ---
check_dependencies
while true; do
    print_header
    echo -e " ${C_CYAN}STATUS TOOLKIT PROFESIONAL ANDA:${C_NC}\n"
    id=0
    for tool_data in "${TOOLS_DB[@]}"; do
        IFS='|' read -r name type pkg_repo file_bin rec_ver desc <<< "$tool_data"
        id=$((id + 1))
        version=$(get_version "$type" "$pkg_repo" "$file_bin")
        print_status_line "$id" "$name" "$version" "$rec_ver" "$desc"
    done
    echo
    echo -e " ${C_GREEN}[AUTO]${C_NC} Instalasi Wajib (Java, SDK, Apktool, JADX, Signer)"
    echo -e " ${C_RED}[Q]${C_NC}    Keluar dari Toolkit"
    echo
    read -p ">> Masukkan nomor tool untuk manajer, atau pilih opsi: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#TOOLS_DB[@]} ]; then
        tool_index=$((choice - 1))
        IFS='|' read -r name type pkg_repo file_bin rec_ver desc <<< "${TOOLS_DB[$tool_index]}"
        case "$type" in
            github) manage_github_tool "$name" "$pkg_repo" "$file_bin" "$file_bin" "$rec_ver" ;;
            pkg) manage_pkg_tool "$name" "$pkg_repo" ;;
            pip) manage_pip_tool "$name" "$pkg_repo" ;;
            sdk) manage_sdk ;;
            java) manage_pkg_tool "$name" "$pkg_repo" ;; # Java di Termux/Linux paling mudah pakai pkg
        esac
    else
        case "$choice" in
            [Aa][Uu][Tt][Oo])
                print_header; echo -e "${C_YELLOW}Memulai instalasi wajib secara berurutan...${C_NC}"
                
                # 1. Java
                echo -e "\n${C_CYAN}--- [1/5] Java (OpenJDK 17) ---${C_NC}"
                manage_pkg_tool "Java (OpenJDK 17)" "openjdk-17"

                # 2. Android SDK
                echo -e "\n${C_CYAN}--- [2/5] Android SDK ---${C_NC}"
                func_configure_sdk_core
                echo -e "${C_GREEN}✅ Android SDK Selesai!${C_NC}"
                
                # 3. Apktool
                echo -e "\n${C_CYAN}--- [3/5] Apktool ---${C_NC}"
                manage_github_tool "Apktool" "iBotPeaches/Apktool" "apktool.jar" "apktool" "2.9.3"

                # 4. JADX
                echo -e "\n${C_CYAN}--- [4/5] JADX ---${C_NC}"
                manage_github_tool "JADX" "skylot/jadx" "jadx" "jadx" "1.5.0"

                # 5. Uber APK Signer
                echo -e "\n${C_CYAN}--- [5/5] Uber APK Signer ---${C_NC}"
                manage_github_tool "Uber APK Signer" "patrickfav/uber-apk-signer" "uber-apk-signer.jar" "uber-apk-signer" "1.3.0"

                echo -e "\n${C_GREEN}🔥 INSTALASI WAJIB LENGKAP! Silakan cek kembali status di menu utama.${C_NC}"
                ;;
            [Qq]) echo -e "\n${C_BLUE}Sayonara, Cuy! Semoga sukses modding-nya! 👋${C_NC}"; exit 0 ;;
            *) echo -e "\n${C_RED}❌ Pilihan tidak valid, Cek lagi deh!${C_NC}" ;;
        esac
    fi
    echo -e "\n${C_YELLOW}Tekan [Enter] buat lanjut...${C_NC}"; read -r
done