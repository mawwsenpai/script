RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
PURPLE=$(tput setaf 5)
CYAN=$(tput setaf 6)
NC=$(tput sgr0) 
BOLD=$(tput bold)
UNDERLINE=$(tput smul)

# --- Konfigurasi Tools & Script ---
# Nama-nama script eksternal yang akan dipanggil
SETUP_SCRIPT="setup-modding.sh"
MOD_SCRIPT="mod-apk.sh"
BUILD_SCRIPT="build-apk.sh"

# --- Variabel Global untuk Status ---
declare -A TOOL_STATUS
ALL_TOOLS_READY=false

# =================================================
#               KUMPULAN FUNGSI
# =================================================

# Fungsi: Animasi spinner untuk proses yang butuh waktu
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n "  "
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Fungsi: Menjalankan script eksternal dengan jeda
run_script() {
    local SCRIPT_NAME="$1"
    local SCRIPT_TITLE="$2"
    
    if [ ! -f "$SCRIPT_NAME" ]; then
        clear
        echo -e "${RED}${BOLD}❌ KESALAHAN KRITIS ❌${NC}"
        echo -e "Script ${YELLOW}'$SCRIPT_NAME'${NC} tidak ditemukan di folder yang sama."
        echo "Pastikan semua file script lengkap."
        read -p "Tekan [Enter] untuk kembali..."
        return
    fi
    
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${BOLD}               MEMBUKA MODUL: $SCRIPT_TITLE        ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    sleep 1
    
    # Menjalankan script
    bash "$SCRIPT_NAME"
    
    echo -e "\n${CYAN}====================================================${NC}"
    read -p ">> Tekan [Enter] untuk kembali ke Hub Komando..."
}

# Fungsi: Analisis Kesiapan Sistem (Lebih Akurat)
check_system_readiness() {
    echo -e "${YELLOW}Menganalisis kesiapan sistem, mohon tunggu...${NC}"
    (sleep 2) & spinner $! # Simulasi loading untuk UX

    local missing_tools=0
    # Cek setiap tool dengan 'command -v' yang lebih akurat
    if command -v java &> /dev/null; then TOOL_STATUS["Java"]=" ${GREEN}[✔] Siap${NC}"; else TOOL_STATUS["Java"]=" ${RED}[✘] Hilang${NC}"; ((missing_tools++)); fi
    if command -v apktool &> /dev/null; then TOOL_STATUS["Apktool"]=" ${GREEN}[✔] Siap${NC}"; else TOOL_STATUS["Apktool"]=" ${RED}[✘] Hilang${NC}"; ((missing_tools++)); fi
    if command -v uber-apk-signer &> /dev/null; then TOOL_STATUS["Signer"]=" ${GREEN}[✔] Siap${NC}"; else TOOL_STATUS["Signer"]=" ${RED}[✘] Hilang${NC}"; ((missing_tools++)); fi
    if command -v jadx &> /dev/null; then TOOL_STATUS["JADX"]=" ${GREEN}[✔] Siap${NC}"; else TOOL_STATUS["JADX"]=" ${RED}[✘] Hilang${NC}"; ((missing_tools++)); fi

    if [ "$missing_tools" -eq 0 ]; then
        ALL_TOOLS_READY=true
    else
        ALL_TOOLS_READY=false
    fi
}

# Fungsi: Menampilkan Header Dinamis
show_header() {
    clear
    if $ALL_TOOLS_READY; then
        echo -e "${GREEN}${BOLD}"
        echo "    ╔════════════════════════════════════════════════╗"
        echo "    ║         SISTEM SIAP TEMPUR - SEMUA STABIL        ║"
        echo "    ╚════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${YELLOW}${BOLD}"
        echo "    ╔════════════════════════════════════════════════╗"
        echo "    ║       SISTEM BUTUH PERHATIAN - CEK STATUS        ║"
        echo "    ╚════════════════════════════════════════════════╝${NC}"
    fi
    
    echo -e "${PURPLE}${BOLD}"
    echo "  ▄▀▀ █▀█ █▄░█ ▀█▀   █▀▄ █▀▀ █▀▀ █   █▀▀ █▀▀"
    echo "  ▄██ █▄█ █░▀█ ░█░   █▄▀ █▄▄ █▄▄ █   ██▄ ▄██ V4"
    echo -e "${NC}"
    echo -e "${CYAN}                 Hub Komando Modding Profesional${NC}"
    echo -e "${RED}----------------------------------------------------${NC}"
}

# Fungsi: Gerbang Setup jika tools belum lengkap
setup_gate() {
    if ! $ALL_TOOLS_READY; then
        show_header
        echo -e "${YELLOW}${BOLD}PERINGATAN: Beberapa komponen modding inti belum terinstal!${NC}"
        echo
        echo -e "Status Saat Ini:"
        echo -e "  - Java (JDK)       :${TOOL_STATUS[Java]}"
        echo -e "  - Apktool          :${TOOL_STATUS[Apktool]}"
        echo -e "  - Uber APK Signer  :${TOOL_STATUS[Signer]}"
        echo -e "  - JADX             :${TOOL_STATUS[JADX]}"
        echo
        echo -e "Menu utama tidak dapat ditampilkan sebelum sistem siap."
        echo -e "Sangat disarankan untuk menjalankan installer sekarang."
        echo
        
        if [ ! -f "$SETUP_SCRIPT" ]; then
            echo -e "${RED}❌ FATAL: Script installer '${SETUP_SCRIPT}' tidak ditemukan!${NC}"
            echo "Download script tersebut dan letakkan di folder yang sama."
            exit 1
        fi

        read -p ">> Jalankan '${SETUP_SCRIPT}' sekarang? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            bash "$SETUP_SCRIPT"
            echo -e "\n${GREEN}Setup selesai. Menganalisis ulang sistem...${NC}"
            check_system_readiness # Cek ulang setelah instalasi
            if ! $ALL_TOOLS_READY; then
                echo -e "${RED}Masih ada tools yang belum terinstal. Script akan keluar.${NC}"
                exit 1
            fi
        else
            echo -e "${YELLOW}Setup dibatalkan. Script tidak dapat melanjutkan.${NC}"
            exit 0
        fi
    fi
}


# =================================================
#               ALUR EKSEKUSI UTAMA
# =================================================

# Langkah 1: Analisis awal sistem
check_system_readiness

# Langkah 2: Gerbang Pengecekan, memaksa setup jika perlu
setup_gate

# Langkah 3: Jika semua siap, masuk ke Menu Utama
while true; do
    show_header
    
    echo -e "${BOLD}Selamat datang kembali, ${PURPLE}$(whoami)${NC}! Sistem dalam kondisi optimal."
    echo
    echo -e "${UNDERLINE}STATUS SISTEM DETAIL:${NC}"
    echo -e "  [1] Java (JDK)       :${TOOL_STATUS[Java]}"
    echo -e "  [2] Apktool          :${TOOL_STATUS[Apktool]}"
    echo -e "  [3] Uber APK Signer  :${TOOL_STATUS[Signer]}"
    echo -e "  [4] JADX             :${TOOL_STATUS[JADX]}"
    echo -e "${RED}----------------------------------------------------${NC}"
    
    echo -e "${BOLD}${BLUE}PILIH AKSI:${NC}"
    echo "  1. Bongkar / Rakit Ulang APK   (Apktool)"
    echo "  2. Buat APK dari Source Code   (Gradle Wrapper)"
    echo "  3. Tanda Tangani APK           (Uber APK Signer)"
    echo "  4. Analisis Source Code Java   (JADX)"
    echo
    echo -e "${BOLD}${YELLOW}MANAJEMEN:${NC}"
    echo "  S. Setup / Update Tools        (Jalankan Ulang Installer)"
    echo "  Q. Keluar dari Hub"
    
    read -p $'\n>> Masukkan pilihan: ' choice

    case "$choice" in
        1) run_script "$MOD_SCRIPT" "MODIFIKASI APK" ;;
        2) run_script "$BUILD_SCRIPT" "BUILD APK" ;;
        3) run_script "sign-apk.sh" "SIGNER APK" ;; # Asumsi ada script sign-apk.sh
        4) run_script "analyze-java.sh" "ANALISIS JAVA" ;; # Asumsi ada script analyze-java.sh
        [Ss]) 
            clear
            echo -e "${YELLOW}Menjalankan ulang installer untuk setup/update...${NC}"
            sleep 1
            bash "$SETUP_SCRIPT"
            echo -e "\n${GREEN}Proses selesai. Menganalisis ulang sistem...${NC}"
            check_system_readiness
            read -p "Tekan [Enter] untuk kembali ke menu..."
            ;;
        [Qq]) 
            echo -e "\n${CYAN}Terima kasih telah menggunakan ZONA-TOOL. Sampai jumpa!${NC}"
            exit 0
            ;;
        *) 
            echo -e "\n${RED}Pilihan tidak valid, cuy! Coba lagi.${NC}"
            sleep 2
            ;;
    esac
done
