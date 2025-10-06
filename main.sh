#!/bin/bash

# =================================================================================
#      Maww-Toolkit Edisi PRO - Integrasi & Revamp UI
# =================================================================================
# Deskripsi:
# Rombakan total dengan fokus pada User Interface (UI) dan User Experience (UX).
# Mengadopsi tema dari 'setup-modding.sh' untuk menciptakan pengalaman
# yang konsisten dan profesional.
# =================================================================================

# --- [1] KONFIGURASI TAMPILAN & WARNA (tput) ---
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
PURPLE=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
GRAY=$(tput setaf 8)
NC=$(tput sgr0)
BOLD=$(tput bold)

# --- [2] KONFIGURASI GLOBAL ---
TOOLKIT_VERSION="Edisi PRO"
TOOLS_DIR="$HOME/tools"
BIN_DIR="/data/data/com.termux/files/usr/bin"
SDK_ROOT="$TOOLS_DIR/android-sdk"
mkdir -p "$TOOLS_DIR" 2>/dev/null
export PATH="$HOME/.local/bin:$PATH"

# --- [3] DATABASE TOOLS (TETAP SAMA, INI INTI MESINNYA) ---
TOOLS_DB=(
    "JDK|Java (OpenJDK 17)|java|openjdk-17||java|"
    "SDK|Android SDK|sdk||||"
    "APKTOOL|Apktool|github|iBotPeaches/Apktool|apktool_{version}.jar|apktool|2.9.3"
    "JADX|JADX|github|skylot/jadx|jadx-{version}.zip|jadx|1.5.3"
    "SIGNER|Uber APK Signer|github|patrickfav/uber-apk-signer|uber-apk-signer-{version}.jar|uber-apk-signer|1.3.0"
    "FRIDA|Frida Tools|pip|frida-tools||frida|"
    "MITMPROXY|mitmproxy|pip|mitmproxy||mitmproxy|"
    "RADARE2|Radare2|pkg|radare2||r2|"
    "GRADLE|Gradle|pkg|gradle||gradle|"
    "MC|Midnight Commander|pkg|mc||mc|"
    "MICRO|Micro Editor|pkg|micro||micro|"
)

# Variabel Global untuk Status
declare -A TOOL_VERSIONS
ALL_TOOLS_READY=false

# --- [4] FUNGSI HELPER & UI INTI ---

# Spinner yang lebih modern
spinner() {
    local pid=$!
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    printf " ${CYAN}"
    while ps -p $pid > /dev/null; do
        for (( i=0; i<${#spinstr}; i++ )); do
            printf "\b%c" "${spinstr:$i:1}"
            sleep 0.1
        done
    done
    printf "\b ${NC}"
}

# Header dengan gaya baru yang keren
print_header() {
    local title="$1"
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "  ▄▀▀ █▀█ █▄░█ ▀█▀  ▀█▀ █▀█ █▀█ █░█ ▄▀█ ▀█▀ ▀█▀"
    echo "  ▄██ █▄█ █░▀█ ░█░  ░█░ █▄█ █▀▄ ▀▄▀ █▀█ ░█░ ░█░ ${NC}${CYAN}PRO${NC}"
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo -e "${BOLD}${WHITE}  ${title}${NC}"
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo
}

# Fungsi untuk mendapatkan versi tool
get_version() {
    local type="$1" pkg_name="$2" bin_name="$3"
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

# Fungsi untuk mendapatkan tag rilis terbaru dari GitHub
get_latest_github_version() {
    local repo="$1"
    wget -qO- "https://api.github.com/repos/$repo/releases" 2>/dev/null | \
        jq -r '.[0].tag_name' 2>/dev/null | sed 's/v//'
}

# Memeriksa dependensi dasar
check_dependencies() {
    local missing_deps=()
    for dep in jq wget unzip; do
        if ! command -v "$dep" &>/dev/null; then missing_deps+=("$dep"); fi
    done
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_header "Setup Dependensi"
        echo -e "${YELLOW}Beberapa dependensi inti tidak ditemukan: ${missing_deps[*]}.${NC}"
        echo -e "${YELLOW}Mencoba memasang secara otomatis...${NC}"
        (pkg install "${missing_deps[@]}" -y) >/dev/null 2>&1 & spinner
        echo -e "${GREEN}✓ Dependensi selesai dipasang.${NC}"
        sleep 2
    fi
}

# Analisis Kesiapan Sistem
check_system_readiness() {
    local missing_count=0
    for tool_data in "${TOOLS_DB[@]}"; do
        IFS='|' read -r code name type pkg_repo asset_pattern bin_name rec_ver <<< "$tool_data"
        TOOL_VERSIONS["$code"]=$(get_version "$type" "$pkg_repo" "$bin_name")
        if [ -z "${TOOL_VERSIONS[$code]}" ]; then
            ((missing_count++))
        fi
    done

    if [ "$missing_count" -eq 0 ]; then
        ALL_TOOLS_READY=true
    else
        ALL_TOOLS_READY=false
    fi
}

# --- [5] FUNGSI MANAJEMEN & INSTALASI TOOLS ---

manage_github_tool() {
    local name="$1" repo="$2" asset_pattern="$3" bin_name="$4" rec_ver="$5"
    print_header "Manajer: $name"

    echo -e "${YELLOW}Menganalisis versi...${NC}"
    LATEST_VERSION=$(get_latest_github_version "$repo")
    CURRENT_VERSION=$(get_version "github" "" "$bin_name")

    echo -e "${BOLD}${WHITE}Status Terpasang :${NC} ${GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${NC}"
    echo -e "${BOLD}${WHITE}Versi Stabil     :${NC} ${YELLOW}$rec_ver${NC}"
    echo -e "${BOLD}${WHITE}Versi Terbaru    :${NC} ${BLUE}${LATEST_VERSION:-'N/A'}${NC}"
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo -e "${BOLD}${BLUE}PILIH AKSI:${NC}"
    echo "  ${YELLOW}S${NC} - Instal/Update ke versi ${BOLD}Stabil${NC} ($rec_ver)"
    echo "  ${BLUE}L${NC} - Instal/Update ke versi ${BOLD}Terbaru${NC} ($LATEST_VERSION)"
    echo "  ${RED}H${NC} - Hapus Instalasi"
    echo "  ${GRAY}B${NC} - Kembali ke Menu Utama"

    read -rp $'\n>> Masukkan pilihan: ' choice

    # (Logika instalasi dari v9.1 tetap dipertahankan karena sudah stabil)
    # ... sisanya sama persis seperti script v9.1 ...
    local version_to_install=""
    case "${choice^^}" in S) version_to_install="$rec_ver" ;; L) version_to_install="$LATEST_VERSION" ;; H) echo -e "\n${RED}Menghapus $name...${NC}"; rm -f "$BIN_DIR/$bin_name" "$TOOLS_DIR/$bin_name.jar" "$TOOLS_DIR/${bin_name,,}.version" 2>/dev/null; if [[ "$bin_name" == "jadx" ]]; then rm -rf "$TOOLS_DIR/jadx-engine"; fi; echo -e "${GREEN}✓ $name berhasil dihapus.${NC}"; return ;; *) return ;; esac
    if [ -z "$version_to_install" ] || [[ "$version_to_install" == "null" ]]; then echo -e "\n${RED}✗ Versi tidak valid atau tidak ditemukan.${NC}"; return; fi
    echo -e "\n${YELLOW}[1/3] Mencari link unduhan untuk $name v$version_to_install...${NC}"; RELEASES_JSON=$(wget -qO- "https://api.github.com/repos/$repo/releases"); DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r --arg bn "$bin_name" --arg ver "$version_to_install" '.[] | .assets[] | select(.name | test($bn; "i") and test($ver)) | .browser_download_url' | head -n 1); if [ -z "$DOWNLOAD_URL" ]; then local asset_name_final="${asset_pattern/\{version\}/$version_to_install}"; local asset_name_regex="${asset_name_final//./\\\\.}"; DOWNLOAD_URL=$(echo "$RELEASES_JSON" | jq -r ".[] | .assets[] | select(.name | test(\"$asset_name_regex\")) | .browser_download_url" | head -n 1); fi
    if [ -z "$DOWNLOAD_URL" ]; then echo -e "${RED}✗ GAGAL: Link unduhan tidak ditemukan!${NC}"; return; fi
    local filename_from_url=$(basename "$DOWNLOAD_URL"); local local_filename_temp="$TOOLS_DIR/$filename_from_url"; echo -e "${GREEN}✓ Link ditemukan: ${GRAY}$filename_from_url${NC}"; echo -e "${YELLOW}[2/3] Mengunduh...${NC}"; (wget -q --show-progress -O "$local_filename_temp" "$DOWNLOAD_URL"); if [ $? -ne 0 ]; then echo -e "\n${RED}✗ GAGAL: Unduhan terhenti!${NC}"; rm -f "$local_filename_temp"; return; fi
    echo -e "${GREEN}✓ Unduhan Selesai.${NC}"; echo -e "${YELLOW}[3/3] Mengkonfigurasi...${NC}"; if [[ "$filename_from_url" == *.zip ]]; then rm -rf "$TOOLS_DIR/jadx-engine" 2>/dev/null; unzip -qo "$local_filename_temp" -d "$TOOLS_DIR/"; mv "$TOOLS_DIR"/jadx-* "$TOOLS_DIR/jadx-engine" 2>/dev/null; ln -sfr "$TOOLS_DIR/jadx-engine/bin/jadx" "$BIN_DIR/jadx"; rm "$local_filename_temp"; FINAL_INSTALL_PATH="$BIN_DIR/jadx"; else final_jar_path="$TOOLS_DIR/$bin_name.jar"; mv "$local_filename_temp" "$final_jar_path"; echo -e "#!/bin/bash\njava -jar \"$final_jar_path\" \"\$@\"" > "$BIN_DIR/$bin_name"; chmod +x "$BIN_DIR/$bin_name"; FINAL_INSTALL_PATH="$BIN_DIR/$bin_name"; fi
    if [ -e "$FINAL_INSTALL_PATH" ]; then echo "$version_to_install" > "$TOOLS_DIR/${bin_name,,}.version"; echo -e "${GREEN}🎉 SUKSES! $name v$version_to_install siap digunakan.${NC}"; else echo -e "${RED}✗ GAGAL: Instalasi akhir gagal!${NC}"; fi
}

manage_repo_tool() {
    local type="$1" name="$2" pkg_name="$3"
    print_header "Manajer: $name (via $type)"
    CURRENT_VERSION=$(get_version "$type" "$pkg_name")

    echo -e "${BOLD}${WHITE}Status Terpasang:${NC} ${GREEN}${CURRENT_VERSION:-'Belum Terinstal'}${NC}"
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo -e "${BOLD}${BLUE}PILIH AKSI:${NC}"
    echo "  ${GREEN}I${NC} - Instal / Update"
    echo "  ${RED}H${NC} - Hapus"
    echo "  ${GRAY}B${NC} - Kembali"

    read -rp $'\n>> Masukkan pilihan: ' choice
    case "${choice^^}" in I) echo -e "\n${YELLOW}Memproses instalasi/update...${NC}"; if [[ "$type" == "pkg" ]]; then (pkg install "$pkg_name" -y) >/dev/null 2>&1 & spinner; else (pip install --upgrade "$pkg_name") >/dev/null 2>&1 & spinner; fi; echo -e "${GREEN}✓ Selesai.${NC}" ;; H) echo -e "\n${RED}Memproses penghapusan...${NC}"; if [[ "$type" == "pkg" ]]; then (pkg uninstall "$pkg_name" -y) >/dev/null 2>&1 & spinner; else (pip uninstall "$pkg_name" -y) >/dev/null 2>&1 & spinner; fi; echo -e "${GREEN}✓ Selesai.${NC}" ;; *) return ;; esac
}

# --- [6] PROGRAM UTAMA ---

# Langkah 1: Persiapan awal
check_dependencies
check_system_readiness

# Langkah 2: Loop utama program
while true; do
    print_header "Menu Utama"

    # Header dinamis berdasarkan status
    if $ALL_TOOLS_READY; then
        echo -e "  ${GREEN}╔═════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${GREEN}║${NC} ${BOLD}${WHITE} STATUS: SISTEM SIAP TEMPUR - SEMUA STABIL         ${GREEN}║${NC}"
        echo -e "  ${GREEN}╚═════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "  ${YELLOW}╔═════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${YELLOW}║${NC} ${BOLD}${WHITE} STATUS: SISTEM BUTUH PERHATIAN - CEK TOOL DI BAWAH${NC} ${YELLOW}║${NC}"
        echo -e "  ${YELLOW}╚═════════════════════════════════════════════════════╝${NC}"
    fi
    echo

    # Tampilan daftar tool dengan gaya tree
    echo -e "  ${BOLD}${BLUE}DAFTAR PERANGKAT LUNAK:${NC}"
    for tool_data in "${TOOLS_DB[@]}"; do
        IFS='|' read -r code name type pkg_repo asset_pattern bin_name rec_ver <<< "$tool_data"
        version=${TOOL_VERSIONS[$code]}
        if [ -n "$version" ]; then
            status_color="${GREEN}"
            status_char="✔"
            version_display="$version"
        else
            status_color="${RED}"
            status_char="✘"
            version_display="Tidak Ada"
        fi
        printf "  ${CYAN}├─ ${WHITE}[%s] %-20s ${status_color}: %s %-15s${NC}\n" "$code" "$name" "$status_char" "$version_display"
    done
    echo -e "  ${CYAN}└─ ${NC}"

    echo
    echo -e "  ${BOLD}${YELLOW}MANAJEMEN:${NC}"
    echo -e "  ${CYAN}A${NC} - ${BOLD}${WHITE}Instalasi Wajib (5 Tools Rekomendasi)${NC}"
    echo -e "  ${CYAN}Q${NC} - ${BOLD}${WHITE}Keluar dari Toolkit${NC}"

    read -rp $'\n>> Masukkan [Kode Tool] / [A/Q]: ' choice

    choice_upper="${choice^^}"
    TOOL_FOUND=0

    # Logika pemilihan (tetap sama, hanya UI yang diubah)
    case "$choice_upper" in
        A)
            print_header "Instalasi Wajib"
            echo -e "${YELLOW}🔥 Memulai Instalasi Wajib (5 Tools Rekomendasi)...${NC}"
            REQUIRED_TOOLS=("JDK" "SDK" "APKTOOL" "JADX" "SIGNER")
            for i in "${!REQUIRED_TOOLS[@]}"; do
                tool_code="${REQUIRED_TOOLS[$i]}"
                echo -e "\n${CYAN}--- [$(($i+1))/${#REQUIRED_TOOLS[@]}] Memproses ${BOLD}$tool_code${NC} ---"
                # Cari dan jalankan manajer untuk tool yang bersangkutan
                for tool_data in "${TOOLS_DB[@]}"; do
                    IFS='|' read -r code name type pkg_repo asset_pattern bin_name rec_ver <<< "$tool_data"
                    if [[ "$tool_code" == "$code" ]]; then
                        case "$type" in github) manage_github_tool "$name" "$pkg_repo" "$asset_pattern" "$bin_name" "$rec_ver" ;; pkg|java) manage_repo_tool "pkg" "$name" "$pkg_repo" ;; sdk) echo -e "${GRAY}Fitur SDK akan diimplementasikan di versi selanjutnya.${NC}" ;; esac
                        break
                    fi
                done
                if [[ $i -lt $((${#REQUIRED_TOOLS[@]}-1)) ]]; then read -rp "Tekan [Enter] untuk melanjutkan..."; fi
            done
            echo -e "\n${GREEN}🎉 INSTALASI WAJIB SELESAI! Menganalisis ulang sistem...${NC}"; sleep 2
            TOOL_FOUND=1
            ;;
        Q) echo -e "\n${CYAN}Terima kasih telah menggunakan Maww-Toolkit! Sampai jumpa!${NC}"; exit 0 ;;
        *)
            for tool_data in "${TOOLS_DB[@]}"; do
                IFS='|' read -r code name type pkg_repo asset_pattern bin_name rec_ver <<< "$tool_data"
                if [[ "$choice_upper" == "$code" ]]; then
                    TOOL_FOUND=1
                    case "$type" in github) manage_github_tool "$name" "$pkg_repo" "$asset_pattern" "$bin_name" "$rec_ver" ;; pkg|java) manage_repo_tool "pkg" "$name" "$pkg_repo" ;; pip) manage_repo_tool "pip" "$name" "$pkg_repo" ;; sdk) echo -e "\n${YELLOW}Manajer SDK belum tersedia.${NC}"; sleep 2 ;; esac
                    break
                fi
            done
            if [ $TOOL_FOUND -eq 0 ]; then echo -e "\n${RED}Pilihan tidak valid, Cuy!${NC}"; sleep 1; fi
            ;;
    esac

    # Cek ulang status sistem setelah ada perubahan
    check_system_readiness
    if [ $TOOL_FOUND -eq 1 ]; then
        read -rp $'\nTekan [Enter] untuk kembali ke Menu Utama...'
    fi
done
