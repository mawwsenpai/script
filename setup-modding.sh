#!/bin/bash
# ==============================================================================
# Maww-Toolkit
# Manajer Tool Modding & Analisis APK untuk Termux
# Versi: v10.0 (Perbaikan Komunitas & Fitur Penuh)
# ==============================================================================

# --- [1] KONFIGURASI GLOBAL & WARNA ---
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[0;90m'
C_NC='\033[0m'

TOOLKIT_VERSION="v10.0 (Lengkap)"
TOOLS_DIR="$HOME/tools"
BIN_DIR="$PREFIX/bin" # Menggunakan variabel standar Termux
SDK_ROOT="$TOOLS_DIR/android-sdk"

# Membuat direktori yang diperlukan
mkdir -p "$TOOLS_DIR" 2>/dev/null
mkdir -p "$BIN_DIR" 2>/dev/null

# Ekspor variabel lingkungan agar dapat diakses oleh shell & tools lain
export ANDROID_HOME="$SDK_ROOT"
export ANDROID_SDK_ROOT="$SDK_ROOT"
export PATH="$HOME/.local/bin:$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools:$PATH"

# --- [2] DATABASE TOOLS ---
# Format: "KODE|Nama Lengkap|Tipe|Repo/Paket|Pola Aset|Nama Biner|Versi Rekomendasi"
TOOLS_DB=(
    "JDK|Java (OpenJDK 17)|pkg|openjdk-17||java|"
    "SDK|Android SDK|sdk||||"
    "APKTOOL|Apktool|github|iBotPeaches/Apktool|apktool_{version}.jar|apktool|2.9.3"
    "JADX|JADX|github|skylot/jadx|jadx-{version}.zip|jadx|1.5.1"
    "SIGNER|Uber APK Signer|github|patrickfav/uber-apk-signer|uber-apk-signer-{version}.jar|uber-apk-signer|1.3.0"
    "FRIDA|Frida Tools|pip|frida-tools||frida|"
    "MITMPROXY|mitmproxy|pip|mitmproxy||mitmproxy|"
    "RADARE2|Radare2|pkg|radare2||r2|"
    "GRADLE|Gradle|pkg|gradle||gradle|"
    "MC|Midnight Commander|pkg|mc||mc|"
    "MICRO|Micro Editor|pkg|micro||micro|"
)

# --- [3] FUNGSI HELPER & UI INTI ---
spinner() {
    local pid=$!
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    printf " ${C_CYAN}"
    while ps -p $pid > /dev/null; do
        for (( i=0; i<${#spinstr}; i++ )); do
            printf "\b%c" "${spinstr:$i:1}"
            sleep 0.1
        done
    done
    printf "\b ${C_NC}"
}

print_header() {
    clear
    echo -e "${C_CYAN}╭──────────────────────────────────────────────────────────────╮${C_NC}"
    echo -e "${C_CYAN}│${C_NC} ${C_WHITE}Maww-Toolkit ${TOOLKIT_VERSION}${C_NC}                                    ${C_CYAN}│${C_NC}"
    echo -e "${C_CYAN}│${C_NC} ${C_GRAY}Manajer Tool Modding & Analisis APK untuk Termux${C_NC}             ${C_CYAN}│${C_NC}"
    echo -e "${C_CYAN}╰──────────────────────────────────────────────────────────────╯${C_NC}"
}

print_main_menu() {
    print_header
    echo
    echo -e " ${C_WHITE}STATUS PERANGKAT LUNAK${C_NC}"
    echo -e " ${C_GRAY}──────────────────────────${C_NC}"
    printf " ${C_BLUE}%-10s %-25s %-22s${C_NC}\n" "KODE" "NAMA TOOL" "VERSI TERPASANG"
    printf " ${C_GRAY}%-10s %-25s %-22s${C_NC}\n" "----------" "-------------------------" "----------------------"
    for tool_data in "${TOOLS_DB[@]}"; do
        IFS='|' read -r code name type pkg_repo _ bin_name _ <<< "$tool_data"
        version=$(get_version "$type" "$pkg_repo" "$bin_name")
        if [ -n "$version" ]; then
            status_color="${C_GREEN}"
            # Memotong teks versi jika terlalu panjang
            version_display="✓ ${version:0:20}"
        else
            status_color="${C_RED}"
            version_display="✗ Tidak Ada"
        fi
        printf " ${C_WHITE}%-10s${C_NC} %-25s ${status_color}%-22s${C_NC}\n" "$code" "$name" "$version_display"
    done
    echo
    echo -e " ${C_WHITE}MENU UTAMA${C_NC}"
    echo -e " ${C_GRAY}────────────${C_NC}"
    echo -e " ${C_YELLOW}A${C_NC}  - ${C_WHITE}Instalasi Wajib (5 Tools Rekomendasi)${C_NC}"
    echo -e " ${C_GRAY}... atau masukkan ${C_BLUE}KODE TOOL${C_GRAY} untuk mengelola tool individual.${C_NC}"
    echo -e " ${C_RED}Q${C_NC}  - ${C_WHITE}Keluar dari Toolkit${C_NC}"
    echo
}

get_version() {
    local type="$1" pkg_name="$2" bin_name="$3"
    case "$type" in
        pkg) pkg show "$pkg_name" 2>/dev/null | grep 'Version:' | awk '{print $2}' ;;
        pip) pip show "$pkg_name" 2>/dev/null | grep 'Version:' | awk '{print $2}' ;;
        github)
            local version_file="$TOOLS_DIR/${bin_name,,}.version"
            if [ -f "$version_file" ]; then cat "$version_file"; fi ;;
        sdk)
            if [ -d "$SDK_ROOT/build-tools" ] && [ "$(ls -A $SDK_ROOT/build-tools)" ]; then
                local bt_ver=$(ls "$SDK_ROOT/build-tools" | sort -r | head -n 1)
                local pt_ver=$(ls "$SDK_ROOT/platforms" | sort -r | head -n 1 | sed 's/android-//')
                echo "Build: $bt_ver, Platform: $pt_ver"
            fi
            ;;
        java) java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' ;;
    esac
}

get_latest_github_version() {
    local repo="$1"
    wget -qO- "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null | \
        jq -r '.tag_name' 2>/dev/null | sed 's/v//'
}

check_dependencies() {
    local missing_deps=()
    for dep in jq wget unzip; do
        if ! command -v "$dep" &>/dev/null; then
            missing_deps+=("$dep")
        fi
    done
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${C_YELLOW}Beberapa dependensi inti tidak ditemukan: ${missing_deps[*]}.${C_NC}"
        echo -e "${C_YELLOW}Mencoba memasang secara otomatis...${C_NC}"
        (pkg install "${missing_deps[@]}" -y) >/dev/null 2>&1 & spinner
        echo -e "${C_GREEN}✓ Dependensi selesai dipasang.${C_NC}\n"
    fi
}

# --- [4] FUNGSI MANAJEMEN TOOLS ---

install_sdk_base() {
    # Versi stabil yang direkomendasikan
    local CMDLINE_TOOLS_VER="11076708" # Stabil per awal 2024
    local BUILD_TOOLS_VER="34.0.0"
    local PLATFORM_VER="34"

    local CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VER}_latest.zip"
    local CMDLINE_TOOLS_ZIP="$TOOLS_DIR/cmdline-tools.zip"

    echo -e "\n${C_YELLOW}[1/4] Mengunduh Android Command Line Tools...${C_NC}"
    wget -q --show-progress -O "$CMDLINE_TOOLS_ZIP" "$CMDLINE_TOOLS_URL"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}✗ GAGAL: Unduhan Command Line Tools terhenti!${C_NC}"; rm -f "$CMDLINE_TOOLS_ZIP"; return 1
    fi
    echo -e "${C_GREEN}✓ Unduhan Selesai.${C_NC}"

    echo -e "${C_YELLOW}[2/4] Mengekstrak dan mengatur Command Line Tools...${C_NC}"
    rm -rf "$SDK_ROOT" # Membersihkan instalasi lama
    mkdir -p "$SDK_ROOT/cmdline-tools"
    unzip -qo "$CMDLINE_TOOLS_ZIP" -d "$TOOLS_DIR"
    mv "$TOOLS_DIR/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
    rm "$CMDLINE_TOOLS_ZIP"
    echo -e "${C_GREEN}✓ Ekstraksi Selesai.${C_NC}"

    local SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
    if [ ! -f "$SDKMANAGER" ]; then
        echo -e "\n${C_RED}✗ GAGAL: sdkmanager tidak ditemukan setelah ekstraksi!${C_NC}"; return 1
    fi

    echo -e "${C_YELLOW}[3/4] Menerima lisensi SDK...${C_NC}"
    (yes | "$SDKMANAGER" --sdk_root="$SDK_ROOT" --licenses) >/dev/null 2>&1 & spinner
    echo -e "${C_GREEN}✓ Lisensi diterima.${C_NC}"

    echo -e "${C_YELLOW}[4/4] Menginstal paket SDK dasar (platform-tools, build-tools, platforms)...${C_NC}"
    echo -e "${C_GRAY}Ini mungkin memakan waktu lama, tergantung koneksi internet Anda.${C_NC}"
    (yes | "$SDKMANAGER" --sdk_root="$SDK_ROOT" "platform-tools" "build-tools;$BUILD_TOOLS_VER" "platforms;android-$PLATFORM_VER") >/dev/null 2>&1 & spinner

    if [ -d "$SDK_ROOT/platform-tools" ]; then
        echo -e "${C_GREEN}🎉 SUKSES! Android SDK siap digunakan.${C_NC}"
        echo -e "${C_GRAY}Harap tutup dan buka kembali Termux agar variabel PATH diperbarui.${C_NC}"
    else
        echo -e "${C_RED}✗ GAGAL: Terjadi kesalahan saat menginstal paket SDK dasar!${C_NC}"; return 1
    fi
    return 0
}

manage_sdk() {
    print_header
    echo -e "\n${C_CYAN}╭─ Manajer: ${C_WHITE}Android SDK${C_NC} ${C_CYAN}──────────────────────────╮${C_NC}"
    echo -e "${C_CYAN}│${C_NC}"
    local version_info=$(get_version "sdk")
    echo -e "${C_CYAN}│${C_NC} ${C_WHITE}Status Terpasang :${C_NC} ${C_GREEN}${version_info:-'✗ Belum Terinstal'}${C_NC}"
    echo -e "${C_CYAN}│${C_NC} ${C_WHITE}Lokasi Instalasi :${C_NC} ${C_GRAY}$SDK_ROOT${C_NC}"
    echo -e "${C_CYAN}│${C_NC}"
    echo -e "${C_CYAN}│${C_NC} ${C_GREEN}I${C_NC} - Instal/Reinstal SDK Dasar"
    echo -e "${C_CYAN}│${C_NC} ${C_BLUE}U${C_NC} - Update semua paket SDK yang terpasang"
    echo -e "${C_CYAN}│${C_NC} ${C_YELLOW}L${C_NC} - Lihat & instal paket SDK lainnya"
    echo -e "${C_CYAN}│${C_NC} ${C_RED}H${C_NC} - Hapus SDK sepenuhnya"
    echo -e "${C_CYAN}│${C_NC} ${C_GRAY}B${C_NC} - Kembali ke Menu Utama"
    echo -e "${C_CYAN}│${C_NC}"
    echo -e "${C_CYAN}╰──────────────────────────────────────────────────╯${C_NC}"
    read -rp " [?] Pilihan Anda: " choice

    local SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
    case "${choice^^}" in
        I) install_sdk_base ;;
        U)
            if [ ! -f "$SDKMANAGER" ]; then echo -e "\n${C_RED}✗ SDK tidak ditemukan. Silakan instal terlebih dahulu.${C_NC}"; return; fi
            echo -e "\n${C_YELLOW}Memeriksa pembaruan...${C_NC}"
            yes | "$SDKMANAGER" --sdk_root="$SDK_ROOT" --update
            echo -e "\n${C_GREEN}✓ Proses update selesai.${C_NC}"
            ;;
        L)
            if [ ! -f "$SDKMANAGER" ]; then echo -e "\n${C_RED}✗ SDK tidak ditemukan. Silakan instal terlebih dahulu.${C_NC}"; return; fi
            echo -e "\n${C_YELLOW}Menampilkan daftar paket yang tersedia... (Ini mungkin memakan waktu)${C_NC}"
            "$SDKMANAGER" --sdk_root="$SDK_ROOT" --list
            echo -e "\n${C_CYAN}Salin nama paket yang ingin diinstal (contoh: 'platforms;android-33').${C_NC}"
            read -rp " [?] Masukkan nama paket (atau biarkan kosong untuk kembali): " pkg_to_install
            if [ -n "$pkg_to_install" ]; then
                echo -e "\n${C_YELLOW}Menginstal paket: $pkg_to_install...${C_NC}"
                (yes | "$SDKMANAGER" --sdk_root="$SDK_ROOT" "$pkg_to_install") >/dev/null 2>&1 & spinner
                echo -e "\n${C_GREEN}✓ Instalasi paket selesai.${C_NC}"
            fi
            ;;
        H)
            read -rp "$(echo -e "\n${C_RED}ANDA YAKIN ingin menghapus SDK di $SDK_ROOT? [ketik 'YA']: ${C_NC}")" confirm
            if [[ "$confirm" == "YA" ]]; then
                echo -e "${C_RED}Menghapus SDK...${C_NC}"; (rm -rf "$SDK_ROOT") >/dev/null 2>&1 & spinner; echo -e "${C_GREEN}✓ SDK berhasil dihapus.${C_NC}"
            else
                echo -e "${C_YELLOW}Penghapusan dibatalkan.${C_NC}"
            fi
            ;;
        *) return ;;
    esac
}

manage_github_tool() {
    local name="$1" repo="$2" asset_pattern="$3" bin_name="$4" rec_ver="$5"
    print_header
    echo -e "\n${C_CYAN}╭─ Manajer: ${C_WHITE}$name${C_NC} ${C_CYAN}─────────────────────────╮${C_NC}"
    echo -e "${C_CYAN}│${C_NC}"
    echo -e "${C_CYAN}│${C_NC} ${C_YELLOW}Menganalisis versi...${C_NC}"
    LATEST_VERSION=$(get_latest_github_version "$repo")
    CURRENT_VERSION=$(get_version "github" "" "$bin_name")
    echo -e "${C_CYAN}│${C_NC} ${C_WHITE}Status Terpasang :${C_NC} ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC}"
    echo -e "${C_CYAN}│${C_NC} ${C_WHITE}Versi Stabil     :${C_NC} ${C_YELLOW}$rec_ver${C_NC}"
    echo -e "${C_CYAN}│${C_NC} ${C_WHITE}Versi Terbaru    :${C_NC} ${C_BLUE}${LATEST_VERSION:-'N/A'}${C_NC}"
    echo -e "${C_CYAN}│${C_NC}"
    echo -e "${C_CYAN}│${C_NC} ${C_YELLOW}S${C_NC} - Instal/Update ke versi Stabil ($rec_ver)"
    echo -e "${C_CYAN}│${C_NC} ${C_BLUE}L${C_NC} - Instal/Update ke versi Terbaru ($LATEST_VERSION)"
    echo -e "${C_CYAN}│${C_NC} ${C_RED}H${C_NC} - Hapus Instalasi"
    echo -e "${C_CYAN}│${C_NC} ${C_GRAY}B${C_NC} - Kembali ke Menu Utama"
    echo -e "${C_CYAN}│${C_NC}"
    echo -e "${C_CYAN}╰──────────────────────────────────────────────────╯${C_NC}"
    read -rp " [?] Pilihan Anda: " choice

    local version_to_install=""
    case "${choice^^}" in
        S) version_to_install="$rec_ver" ;;
        L) version_to_install="$LATEST_VERSION" ;;
        H)
            echo -e "\n${C_RED}Menghapus $name...${C_NC}"
            rm -f "$BIN_DIR/$bin_name" "$TOOLS_DIR/$bin_name.jar" "$TOOLS_DIR/${bin_name,,}.version" 2>/dev/null
            if [[ "$bin_name" == "jadx" ]]; then rm -rf "$TOOLS_DIR/jadx-engine"; fi
            echo -e "${C_GREEN}✓ $name berhasil dihapus.${C_NC}"; return ;;
        *) return ;;
    esac

    if [ -z "$version_to_install" ] || [[ "$version_to_install" == "null" ]]; then
        echo -e "\n${C_RED}✗ Versi tidak valid atau tidak ditemukan. Cek koneksi internet.${C_NC}"; return
    fi

    echo -e "\n${C_YELLOW}[1/3] Mencari link unduhan untuk $name v$version_to_install...${C_NC}"
    local asset_name_final="${asset_pattern/\{version\}/$version_to_install}"
    local RELEASES_JSON=$(wget -qO- "https://api.github.com/repos/$repo/releases")

    # Metode 1: Mencari rilis dengan tag yang sama persis, lalu mencari aset. Paling akurat.
    DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r --arg tag "v$version_to_install" --arg tag_no_v "$version_to_install" --arg asset "$asset_name_final" \
        '.[] | select(.tag_name == $tag or .tag_name == $tag_no_v) | .assets[] | select(.name == $asset) | .browser_download_url' | head -n 1)

    # Metode 2: Fallback, mencari di semua rilis untuk aset yang namanya mengandung versi.
    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${C_YELLOW}Pencarian presisi gagal, mencoba pencarian yang lebih luas...${C_NC}"
        DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r --arg ver "$version_to_install" \
            '.[] | .assets[] | select(.name | test($ver)) | .browser_download_url' | grep -i "$bin_name" | head -n 1)
    fi

    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${C_RED}✗ GAGAL: Link unduhan untuk versi $version_to_install tidak ditemukan!${C_NC}"; return
    fi

    local filename_from_url=$(basename "$DOWNLOAD_URL")
    local local_filename_temp="$TOOLS_DIR/$filename_from_url"
    echo -e "${C_GREEN}✓ Link ditemukan: ${C_GRAY}$filename_from_url${C_NC}"
    echo -e "${C_YELLOW}[2/3] Mengunduh $name v$version_to_install...${C_NC}"
    wget -q --show-progress -O "$local_filename_temp" "$DOWNLOAD_URL"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}✗ GAGAL: Proses unduhan terhenti!${C_NC}"; rm -f "$local_filename_temp"; return
    fi

    echo -e "${C_GREEN}✓ Unduhan Selesai.${C_NC}"
    echo -e "${C_YELLOW}[3/3] Mengkonfigurasi dan membuat executable...${C_NC}"
    local FINAL_INSTALL_PATH=""

    if [[ "$filename_from_url" == *.zip ]]; then # Kasus JADX
        rm -rf "$TOOLS_DIR/jadx-engine" 2>/dev/null
        unzip -qo "$local_filename_temp" -d "$TOOLS_DIR/"
        # Ganti nama direktori hasil ekstrak yang namanya dinamis
        mv "$TOOLS_DIR"/jadx* "$TOOLS_DIR/jadx-engine" 2>/dev/null
        ln -sfr "$TOOLS_DIR/jadx-engine/bin/jadx" "$BIN_DIR/jadx"
        rm "$local_filename_temp"
        FINAL_INSTALL_PATH="$BIN_DIR/jadx"
    else # Kasus .jar
        local final_jar_path="$TOOLS_DIR/$bin_name.jar"
        mv "$local_filename_temp" "$final_jar_path"
        # Membuat wrapper script yang lebih baik
        echo -e "#!/bin/bash\n# Wrapper untuk $name oleh Maww-Toolkit\n\nif ! command -v java &> /dev/null; then\n    echo -e \"${C_RED}Error: Java (JDK) tidak ditemukan.${C_NC}\"\n    echo \"Silakan instal melalui menu JDK di dalam toolkit ini.\"\n    exit 1\nfi\n\njava -jar \"$final_jar_path\" \"\$@\"" > "$BIN_DIR/$bin_name"
        chmod +x "$BIN_DIR/$bin_name"
        FINAL_INSTALL_PATH="$BIN_DIR/$bin_name"
    fi

    if [ -e "$FINAL_INSTALL_PATH" ]; then
        echo "$version_to_install" > "$TOOLS_DIR/${bin_name,,}.version"
        echo -e "${C_GREEN}🎉 SUKSES! $name v$version_to_install siap digunakan (ketik: $bin_name)${C_NC}"
    else
        echo -e "${C_RED}✗ GAGAL: Terjadi kesalahan saat instalasi akhir!${C_NC}"
    fi
}

manage_repo_tool() {
    local type="$1" name="$2" pkg_name="$3"
    print_header
    echo -e "\n${C_CYAN}╭─ Manajer: ${C_WHITE}$name (via $type)${C_NC} ${C_CYAN}────────────────╮${C_NC}"
    CURRENT_VERSION=$(get_version "$type" "$pkg_name")
    echo -e "${C_CYAN}│${C_NC} ${C_WHITE}Status Terpasang:${C_NC} ${C_GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${C_NC}"
    echo -e "${C_CYAN}│${C_NC}"
    echo -e "${C_CYAN}│${C_NC} ${C_GREEN}I${C_NC} - Instal / Update"
    echo -e "${C_CYAN}│${C_NC} ${C_RED}H${C_NC} - Hapus"
    echo -e "${C_CYAN}│${C_NC} ${C_GRAY}B${C_NC} - Kembali"
    echo -e "${C_CYAN}╰─────────────────────────────────────────────╯${C_NC}"
    read -rp " [?] Pilihan Anda: " choice
    case "${choice^^}" in
        I)
            echo -e "\n${C_YELLOW}Memproses instalasi/update $name...${C_NC}"
            if [[ "$type" == "pkg" ]]; then (pkg install "$pkg_name" -y) >/dev/null 2>&1 & spinner; else (pip install --upgrade "$pkg_name") >/dev/null 2>&1 & spinner; fi
            echo -e "${C_GREEN}✓ Selesai.${C_NC}" ;;
        H)
            echo -e "\n${C_RED}Memproses penghapusan $name...${C_NC}"
            if [[ "$type" == "pkg" ]]; then (pkg uninstall "$pkg_name" -y) >/dev/null 2>&1 & spinner; else (pip uninstall "$pkg_name" -y) >/dev/null 2>&1 & spinner; fi
            echo -e "${C_GREEN}✓ Selesai.${C_NC}" ;;
        *) return ;;
    esac
}

install_tool_auto() {
    local code="$1" name="$2" type="$3" pkg_repo="$4" asset_pattern="$5" bin_name="$6" rec_ver="$7"

    local current_version=$(get_version "$type" "$pkg_repo" "$bin_name")
    if [ -n "$current_version" ]; then
        echo -e "${C_GREEN}✓ $name sudah terinstal. Dilewati.${C_NC}"
        return
    fi

    echo -e "${C_YELLOW}Menginstal $name...${C_NC}"
    case "$type" in
        pkg) (pkg install "$pkg_repo" -y) >/dev/null 2>&1 & spinner ;;
        sdk) install_sdk_base; return ;; # Sudah memiliki pesan sukses/gagal sendiri
        github) manage_github_tool "$name" "$pkg_repo" "$asset_pattern" "$bin_name" "$rec_ver" ;; # Cukup panggil manajer standar
        *) echo -e "${C_RED}Tipe tool tidak dikenal: $type${C_NC}" ;;
    esac
    
    # Cek ulang setelah instalasi
    if [ -n "$(get_version "$type" "$pkg_repo" "$bin_name")" ]; then
        echo -e "${C_GREEN}✓ $name berhasil diinstal.${C_NC}"
    else
        # SDK sudah ditangani, jadi ini untuk yang lain
        if [[ "$type" != "sdk" ]]; then
            echo -e "${C_RED}✗ GAGAL: Instalasi $name sepertinya gagal.${C_NC}"
        fi
    fi
}

# --- [5] PROGRAM UTAMA ---
check_dependencies
while true; do
    print_main_menu
    read -rp " [?] Masukkan Kode Tool atau Opsi Menu: " choice
    choice_upper="${choice^^}"
    TOOL_FOUND=0

    if [[ "$choice_upper" == "Q" ]]; then
        echo -e "\n${C_BLUE}Terima kasih telah menggunakan Maww-Toolkit! Sampai jumpa lagi 👋${C_NC}"
        exit 0
    elif [[ "$choice_upper" == "A" ]]; then
        print_header
        echo -e "\n${C_YELLOW}🔥 Memulai Instalasi Wajib (5 Tools Rekomendasi)...${C_NC}"
        echo -e "${C_GRAY}Tool yang sudah terinstal akan dilewati secara otomatis.${C_NC}"
        REQUIRED_TOOLS=("JDK" "SDK" "APKTOOL" "JADX" "SIGNER")
        for i in "${!REQUIRED_TOOLS[@]}"; do
            tool_code="${REQUIRED_TOOLS[$i]}"
            echo -e "\n${C_CYAN}--- [$(($i+1))/${#REQUIRED_TOOLS[@]}] Memproses $tool_code ---${C_NC}"
            for tool_data in "${TOOLS_DB[@]}"; do
                IFS='|' read -r code name type pkg_repo asset_pattern bin_name rec_ver <<< "$tool_data"
                if [[ "$tool_code" == "$code" ]]; then
                    # Untuk mode otomatis, kita tidak ingin menu interaktif, jadi kita panggil fungsi instalasi langsung
                    case "$type" in
                        sdk) install_tool_auto "$code" "$name" "$type" "$pkg_repo" "$asset_pattern" "$bin_name" "$rec_ver" ;;
                        github) # Untuk github, panggil manajer tetapi dengan 'S' sebagai pilihan default
                                printf 'S\n' | manage_github_tool "$name" "$pkg_repo" "$asset_pattern" "$bin_name" "$rec_ver" ;;
                        pkg) install_tool_auto "$code" "$name" "$type" "$pkg_repo" "$asset_pattern" "$bin_name" "$rec_ver" ;;
                    esac
                    break
                fi
            done
        done
        echo -e "\n${C_GREEN}🎉 INSTALASI WAJIB SELESAI! Silakan periksa status di menu utama.${C_NC}"
        TOOL_FOUND=1
    else
        for tool_data in "${TOOLS_DB[@]}"; do
            IFS='|' read -r code name type pkg_repo asset_pattern bin_name rec_ver <<< "$tool_data"
            if [[ "$choice_upper" == "$code" ]]; then
                TOOL_FOUND=1
                case "$type" in
                    github) manage_github_tool "$name" "$pkg_repo" "$asset_pattern" "$bin_name" "$rec_ver" ;;
                    pkg) manage_repo_tool "pkg" "$name" "$pkg_repo" ;;
                    pip) manage_repo_tool "pip" "$name" "$pkg_repo" ;;
                    sdk) manage_sdk ;;
                esac
                break
            fi
        done
    fi

    if [ $TOOL_FOUND -eq 0 ]; then
        echo -e "\n${C_RED}✗ Pilihan tidak valid. Gunakan Kode Tool dari tabel (misal: JDK) atau opsi menu (A/Q).${C_NC}"
    fi

    echo
    read -rp " [Tekan Enter untuk kembali ke Menu Utama...]"
done
