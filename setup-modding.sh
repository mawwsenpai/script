#!/bin/bash

# =================================================================================
#               Maww-Toolkit v7.4.1 - Fix Syntax Error (esak -> esac)
#                      Powered by Maww-Core Engine v1.4
# =================================================================================

# --- [1] KONFIGURASI GLOBAL & WARNA ---
C_RED='\033[1;31m'; C_GREEN='\033[1;32m'; C_YELLOW='\033[1;33m'; C_BLUE='\033[1;34m';
C_CYAN='\033[1;36m'; C_NC='\033[0m'
TOOLKIT_VERSION="v7.4.1"
TOOLS_DIR="$HOME/tools"; BIN_DIR="/data/data/com.termux/files/usr/bin"
SDK_ROOT="$HOME/tools/android-sdk"
mkdir -p "$TOOLS_DIR" 2>/dev/null
export PATH="$HOME/.local/bin:$PATH"

# --- [2] DATABASE TOOLS ---
# Format: "NAMA|TIPE|PAKET/REPO|FILE_JAR/BIN|VERSI_REKOMENDASI|DESKRIPSI"
TOOLS_DB=(
    "Java (OpenJDK 17)|pkg|openjdk-17|||Pondasi utama"
    "Android SDK|sdk||||Perkakas resmi Android"
    "Apktool|github|iBotPeaches/Apktool|apktool.jar|2.9.2|Bongkar & rakit ulang APK"
    "JADX|github|skylot/jadx|jadx|1.5.3|Decompiler DEX ke Java"
    "Uber APK Signer|github|patrickfav/uber-apk-signer|uber-apk-signer.jar|1.3.0|Menandatangani APK"
    "Frida Tools|pip|frida-tools|||Framework injeksi dinamis"
    "mitmproxy|pip|mitmproxy|||Sadap lalu lintas jaringan"
    "Radare2|pkg|radare2|||Framework reverse engineering"
    "Gradle|pkg|gradle|||Build automation tool"
    "mc|pkg|mc|||File manager TUI"
    "micro|pkg|micro|||Editor teks terminal"
)

# --- [3] FUNGSI HELPER & UI INTI ---

spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${C_CYAN}[%c]${C_NC} " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

print_header() {
    clear
    echo -e "${C_CYAN}================================================================${C_NC}"
    echo -e "${C_CYAN}# ${C_NC}${C_YELLOW}Maww-Toolkit $TOOLKIT_VERSION: Simpel & Bulletproof${C_NC}"
    echo -e "${C_CYAN}# ${C_NC}Manajemen Tool Modding & Analisis Aplikasi"
    echo -e "${C_CYAN}================================================================${C_NC}"
    echo
}

get_latest_github_version() {
    local REPO="$1"
    # Mengambil versi terbaru dari rilis pertama yang ditemukan
    wget -qO- "https://api.github.com/repos/$REPO/releases" 2>/dev/null | \
        jq -r '.[0].tag_name' 2>/dev/null | sed 's/v//'
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

print_status_line() {
    local id="$1"; local name="$2"; local version="$3"; local rec_ver="$4"; local desc="$5"
    local STATUS_TEXT=""; local STATUS_COLOR=""

    if [ -n "$version" ] && [[ "$version" != "Terinstal" ]]; then
        STATUS_TEXT="[✔ $version]"; STATUS_COLOR="${C_GREEN}"
    elif [ -n "$version" ] && [[ "$version" == "Terinstal" ]]; then
        STATUS_TEXT="[✔ INSTAL]"; STATUS_COLOR="${C_GREEN}"
    elif [ -n "$rec_ver" ] && [[ "$rec_ver" != "||" ]]; then
        STATUS_TEXT="[✘ Target $rec_ver]"; STATUS_COLOR="${C_RED}"
    else
        STATUS_TEXT="[✘ BELUM ADA]"; STATUS_COLOR="${C_RED}"
    fi

    # Format ringkas dan rapi
    printf " %s[%-2s]%s %-18s %s%-15s%s %s\n" "${C_CYAN}" "$id" "${C_NC}" "$name" "$STATUS_COLOR" "$STATUS_TEXT" "${C_NC}" "$desc"
}

check_dependencies() {
    local NEED_INSTALL=""
    for dep in jq wget unzip grep; do
        if ! command -v $dep &>/dev/null; then NEED_INSTALL+="$dep "; fi
    done

    if [ -n "$NEED_INSTALL" ]; then
        echo -e "${C_YELLOW}Memasang dependensi inti ($NEED_INSTALL)...${C_NC}"
        pkg install $NEED_INSTALL -y &>/dev/null & spinner
        echo -e "${C_GREEN}✅ Dependensi inti selesai.${C_NC}"; read -r
    fi
}

# --- [4] FUNGSI INSTALASI SPESIFIK (INTI) ---

manage_github_tool() {
    local NAME="$1" REPO="$2" FILENAME_PATTERN="$3" BIN_NAME="$4" RECOMMENDED_VERSION="$5"
    
    echo -e "\n${C_CYAN}--- Manajer: $NAME ---${C_NC}"
    echo -e "${C_YELLOW}⚙️  Menganalisis versi...${C_NC}"; 
    LATEST_VERSION=$(get_latest_github_version "$REPO")
    CURRENT_VERSION=$(get_version "github" "" "$BIN_NAME")

    echo -e "Status: ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC} (Stabil: ${C_YELLOW}$RECOMMENDED_VERSION${C_NC} | Terbaru: ${C_BLUE}${LATEST_VERSION:-'N/A'}${C_NC})"
    
    echo -e "\n [${C_YELLOW}S${C_NC}] Instal Stabil | [${C_BLUE}L${C_NC}] Instal Terbaru | [${C_RED}H${C_NC}] Hapus | [${C_CYAN}B${C_NC}] Batal"
    read -p ">> Pilih opsi instalasi: " choice

    local VERSION_TO_INSTALL=""
    case "$choice" in
        [Ss]) VERSION_TO_INSTALL="$RECOMMENDED_VERSION" ;; 
        [Ll]) VERSION_TO_INSTALL="$LATEST_VERSION" ;;
        [Hh]) 
            rm -f "$BIN_DIR/$BIN_NAME" "$TOOLS_DIR/$FILENAME_PATTERN" "$TOOLS_DIR/${BIN_NAME,,}.version" "$TOOLS_DIR/jadx.zip" 2>/dev/null
            if [[ "$FILENAME_PATTERN" == "jadx" ]]; then rm -rf "$TOOLS_DIR/jadx-engine"; fi
            echo -e "${C_GREEN}✅ $NAME berhasil Dihapus.${C_NC}"; echo -e "${C_YELLOW}Tekan [Enter] untuk lanjut...${C_NC}"; read -r; return ;;
        *) return ;;
    esac
    
    if [ -z "$VERSION_TO_INSTALL" ] || [[ "$VERSION_TO_INSTALL" == "null" ]]; then echo -e "${C_RED}❌ Versi tidak ditemukan!${C_NC}"; echo -e "${C_YELLOW}Tekan [Enter] untuk lanjut...${C_NC}"; read -r; return; fi
    
    echo -e "${C_YELLOW}⏳ Memulai Unduhan $NAME v$VERSION_TO_INSTALL...${C_NC}"
    
    RELEASES_JSON=$(wget -qO- "https://api.github.com/repos/$REPO/releases" 2>/dev/null)
    DOWNLOAD_URL=""
    LOCAL_FILENAME="$TOOLS_DIR/$FILENAME_PATTERN" # Default filename

    if [[ "$FILENAME_PATTERN" == "jadx" ]]; then
        # JADX: Cari file ZIP yang paling general (jadx-VERSION.zip)
        DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r ".[] | select(.tag_name | contains(\"$VERSION_TO_INSTALL\")) | .assets[] | select(.name | test(\"jadx-$VERSION_TO_INSTALL\\.zip\")) | .browser_download_url" | head -n 1)
        LOCAL_FILENAME="$TOOLS_DIR/jadx-$VERSION_TO_INSTALL.zip"
    elif [[ "$FILENAME_PATTERN" == "apktool.jar" ]]; then
        # APKTOOL: Cari file JAR dengan pola 'apktool_VERSION.jar' atau 'apktool.jar'
        DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r ".[] | select(.tag_name | contains(\"$VERSION_TO_INSTALL\")) | .assets[] | select(.name | test(\"apktool.*jar\")) | .browser_download_url" | head -n 1)
        LOCAL_FILENAME="$TOOLS_DIR/apktool_latest.jar"
    else 
        # Uber Signer dan lainnya (cari nama file JAR)
        DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r ".[] | select(.tag_name | contains(\"$VERSION_TO_INSTALL\")) | .assets[] | select(.name | contains(\"$FILENAME_PATTERN\")) | .browser_download_url" | head -n 1)
    fi
    
    if [ -z "$DOWNLOAD_URL" ]; then echo -e "${C_RED}❌ Link unduhan $NAME v$VERSION_TO_INSTALL tidak ditemukan (API error/file not found)!${C_NC}"; echo -e "${C_YELLOW}Tekan [Enter] untuk lanjut...${C_NC}"; read -r; return; fi
    
    # Proses unduhan
    if ! (wget -qO "$LOCAL_FILENAME" "$DOWNLOAD_URL") & spinner; then
        echo -e "\n${C_RED}❌ GAGAL: Proses unduhan terhenti atau gagal!${C_NC}"; echo -e "${C_YELLOW}Tekan [Enter] untuk lanjut...${C_NC}"; read -r; return
    fi
    
    echo -e "\n${C_GREEN}✅ Unduhan Selesai.${C_NC}"

    if [[ "$FILENAME_PATTERN" == "jadx" ]]; then
        echo -e "${C_YELLOW}Mengekstrak dan Konfigurasi JADX...${C_NC}"
        rm -rf "$TOOLS_DIR/jadx-engine" 2>/dev/null
        unzip -qo "$LOCAL_FILENAME" -d "$TOOLS_DIR/" 
        mv "$TOOLS_DIR"/jadx-*-* "$TOOLS_DIR/jadx-engine" 2>/dev/null
        ln -sfr "$TOOLS_DIR/jadx-engine/bin/jadx" "$BIN_DIR/jadx" 2>/dev/null
        rm "$LOCAL_FILENAME"
    else # Untuk file .jar
        echo -e "${C_YELLOW}Membuat Symlink Executable...${C_NC}"
        # Pindahkan file yang baru diunduh ke nama yang diharapkan oleh script
        mv "$LOCAL_FILENAME" "$TOOLS_DIR/$FILENAME_PATTERN" 2>/dev/null
        echo "#!/bin/bash\njava -jar \"$TOOLS_DIR/$FILENAME_PATTERN\" \"\$@\"" >"$BIN_DIR/$BIN_NAME"
        chmod +x "$BIN_DIR/$BIN_NAME"
    fi
    
    echo "$VERSION_TO_INSTALL" > "$TOOLS_DIR/${BIN_NAME,,}.version"
    echo -e "${C_GREEN}🎉 SUKSES! $NAME v$VERSION_TO_INSTALL telah siap digunakan.${C_NC}"
    echo -e "${C_YELLOW}Tekan [Enter] untuk lanjut...${C_NC}"; read -r
}

# Fungsi Pkg, Pip, SDK (tetap ringkas dan diakhiri read -r)

manage_pkg_tool() {
    local NAME="$1" PKG_NAME="$2"
    CURRENT_VERSION=$(get_version "pkg" "$PKG_NAME")
    echo -e "\n${C_CYAN}--- Manajer: $NAME (via Pkg) ---${C_NC}"
    echo -e "Status: ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC}\n"
    echo -e " [${C_GREEN}I${C_NC}] Instal/Update | [${C_RED}H${C_NC}] Hapus | [${C_CYAN}B${C_NC}] Batal"
    read -p ">> Pilihan: " choice
    case "$choice" in
        [Ii]) echo -e "${C_YELLOW}Menginstal/Update $NAME...${C_NC}"; (pkg install "$PKG_NAME" -y) & spinner; echo -e "${C_GREEN}✅ Selesai.${C_NC}";;
        [Hh]) echo -e "${C_RED}Menghapus $NAME...${C_NC}"; (pkg uninstall "$PKG_NAME" -y) & spinner; echo -e "${C_GREEN}✅ Selesai.${C_NC}";;
        *) return ;;
    esac
    echo -e "${C_YELLOW}Tekan [Enter] untuk lanjut...${C_NC}"; read -r
}

manage_pip_tool() {
    local NAME="$1" PKG_NAME="$2"
    CURRENT_VERSION=$(get_version "pip" "$PKG_NAME")
    echo -e "\n${C_CYAN}--- Manajer: $NAME (via Pip) ---${C_NC}"
    echo -e "Status: ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC}\n"
    echo -e " [${C_GREEN}I${C_NC}] Instal/Update | [${C_RED}H${C_NC}] Hapus | [${C_CYAN}B${C_NC}] Batal"
    read -p ">> Pilihan: " choice
    case "$choice" in
        [Ii]) echo -e "${C_YELLOW}Menginstal/Update $NAME...${C_NC}"; (pip install --upgrade "$PKG_NAME") & spinner; echo -e "${C_GREEN}✅ Selesai.${C_NC}";;
        [Hh]) echo -e "${C_RED}Menghapus $NAME...${C_NC}"; (pip uninstall "$PKG_NAME" -y) & spinner; echo -e "${C_GREEN}✅ Selesai.${C_NC}";;
        *) return ;;
    esac
    echo -e "${C_YELLOW}Tekan [Enter] untuk lanjut...${C_NC}"; read -r
}

manage_sdk() {
    echo -e "\n${C_CYAN}--- Manajer: Android SDK ---${C_NC}"
    if [ -d "$SDK_ROOT/build-tools" ]; then
        LATEST_BUILD_TOOLS=$(ls "$SDK_ROOT/build-tools" | sort -V | tail -n 1)
        echo -e "Status: ${C_GREEN}Terinstal (Build-Tools $LATEST_BUILD_TOOLS)${C_NC}\n"
        echo -e " [${C_YELLOW}I${C_NC}] Update/Reinstall | [${C_RED}H${C_NC}] Hapus Total | [${C_CYAN}B${C_NC}] Batal"
    else
        echo -e "Status: ${C_RED}Belum Terinstal${C_NC}\n"
        echo -e " [${C_GREEN}I${C_NC}] Instal SDK Manager & Tools | [${C_CYAN}B${C_NC}] Batal"
    fi
    read -p ">> Pilihan: " choice

    case "$choice" in
        [Ii]) 
            func_configure_sdk_core
            echo -e "${C_GREEN}✅ Proses SDK Selesai!${C_NC}" 
            ;;
        [Hh]) 
            echo -e "${C_RED}Menghapus folder SDK total...${C_NC}"; rm -rf "$SDK_ROOT"; 
            local PROFILE_FILE="$HOME/.bashrc"; if [ -f "$HOME/.zshrc" ]; then PROFILE_FILE="$HOME/.zshrc"; fi
            sed -i '/# Konfigurasi Android SDK oleh Maww-Toolkit/,$d' "$PROFILE_FILE" 2>/dev/null
            echo -e "${C_GREEN}✅ Dihapus.${C_NC}";
            ;;
        *) return ;;
    esac # <--- Perbaikan syntax di sini (esak -> esac)
    echo -e "${C_YELLOW}Tekan [Enter] untuk lanjut...${C_NC}"; read -r
}

func_configure_sdk_core(){ 
    local PROFILE_FILE="$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ]; then PROFILE_FILE="$HOME/.zshrc"; fi
    
    local SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    local SDK_PACKAGES="platform-tools build-tools;34.0.0 platforms;android-34"
    local SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
    
    if [ ! -d "$SDK_ROOT/cmdline-tools/latest" ]; then
        echo -e "${C_YELLOW} [1/4] Mengunduh SDK Command Line Tools...${C_NC}"; local SDK_ZIP_TEMP="$TOOLS_DIR/sdk-tools-temp.zip"
        (wget -qO "$SDK_ZIP_TEMP" "$SDK_URL") & spinner
        
        echo -e "\n${C_YELLOW} [2/4] Mengekstrak SDK Manager...${C_NC}"
        mkdir -p "$SDK_ROOT/cmdline-tools"
        unzip -qo "$SDK_ZIP_TEMP" -d "$SDK_ROOT/cmdline-tools"
        mv "$SDK_ROOT/cmdline-tools/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest" 2>/dev/null
        rm "$SDK_ZIP_TEMP"
    fi

    if [ -f "$SDKMANAGER" ]; then
        echo -e "${C_YELLOW} [3/4] Menginstal Paket SDK Wajib...${C_NC}"
        yes | "$SDKMANAGER" --licenses &>/dev/null
        ("$SDKMANAGER" --install "$SDK_PACKAGES" &>/dev/null) & spinner
    fi

    echo -e "\n${C_YELLOW} [4/4] Mengkonfigurasi PATH di $PROFILE_FILE...${C_NC}"
    sed -i '/# Konfigurasi Android SDK oleh Maww-Toolkit/,$d' "$PROFILE_FILE" 2>/dev/null
    
    LATEST_BUILD_TOOLS=$(ls "$SDK_ROOT/build-tools" 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$LATEST_BUILD_TOOLS" ]; then
        echo -e "\n# Konfigurasi Android SDK oleh Maww-Toolkit" >>"$PROFILE_FILE"
        echo "export ANDROID_HOME=\"$SDK_ROOT\"" >>"$PROFILE_FILE"
        echo "export PATH=\"\$PATH:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/$LATEST_BUILD_TOOLS\"" >>"$PROFILE_FILE"
        source "$PROFILE_FILE" 2>/dev/null
    fi
}


# --- [5] PROGRAM UTAMA ---
check_dependencies
while true; do
    print_header
    echo -e " ${C_CYAN}STATUS TOOLKIT PROFESIONAL ANDA: ${C_NC}\n"
    
    id=0
    for tool_data in "${TOOLS_DB[@]}"; do
        IFS='|' read -r name type pkg_repo file_bin rec_ver desc <<< "$tool_data"
        id=$((id + 1))
        version=$(get_version "$type" "$pkg_repo" "$file_bin")
        print_status_line "$id" "$name" "$version" "$rec_ver" "$desc"
    done
    
    echo
    echo -e " ${C_GREEN}[A]${C_NC} Instalasi Wajib (5 Tools) - ${C_YELLOW}Disarankan!${C_NC}"
    echo -e " ${C_RED}[Q]${C_NC} Keluar"
    echo
    read -p ">> Masukkan [Nomor Tool] / [A/Q]: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#TOOLS_DB[@]} ]; then
        tool_index=$((choice - 1))
        IFS='|' read -r name type pkg_repo file_bin rec_ver desc <<< "${TOOLS_DB[$tool_index]}"
        
        case "$type" in
            github) manage_github_tool "$name" "$pkg_repo" "$file_bin" "$file_bin" "$rec_ver" ;;
            pkg|java) manage_pkg_tool "$name" "$pkg_repo" ;;
            pip) manage_pip_tool "$name" "$pkg_repo" ;;
            sdk) manage_sdk ;;
        esac
    else
        case "$choice" in
            [Aa])
                print_header; echo -e "${C_YELLOW}Memulai Instalasi Wajib (A)...${C_NC}"
                
                # 1. Java
                echo -e "\n${C_CYAN}--- [1/5] Java (OpenJDK 17) ---${C_NC}"
                manage_pkg_tool "Java (OpenJDK 17)" "openjdk-17"

                # 2. Android SDK
                echo -e "\n${C_CYAN}--- [2/5] Android SDK ---${C_NC}"
                func_configure_sdk_core
                echo -e "${C_GREEN}✅ Android SDK OK.${C_NC}"; echo -e "${C_YELLOW}Tekan [Enter] untuk lanjut...${C_NC}"; read -r
                
                # 3. Apktool
                echo -e "\n${C_CYAN}--- [3/5] Apktool (Stabil) ---${C_NC}"
                manage_github_tool "Apktool" "iBotPeaches/Apktool" "apktool.jar" "apktool" "2.9.2"

                # 4. JADX
                echo -e "\n${C_CYAN}--- [4/5] JADX (Stabil) ---${C_NC}"
                manage_github_tool "JADX" "skylot/jadx" "jadx" "jadx" "1.5.3"

                # 5. Uber APK Signer
                echo -e "\n${C_CYAN}--- [5/5] Uber APK Signer (Stabil) ---${C_NC}"
                manage_github_tool "Uber APK Signer" "patrickfav/uber-apk-signer" "uber-apk-signer.jar" "uber-apk-signer" "1.3.0"

                echo -e "\n${C_GREEN}🔥 INSTALASI WAJIB LENGKAP! Cek status di menu utama.${C_NC}"
                ;;
            [Qq]) echo -e "\n${C_BLUE}Terima kasih telah menggunakan Maww-Toolkit! 👋${C_NC}"; exit 0 ;;
            *) echo -e "\n${C_RED}❌ Pilihan tidak valid.${C_NC}" ;;
        esac
    fi
    echo -e "\n${C_YELLOW}Tekan [Enter] buat lanjut...${C_NC}"; read -r
done