# 1. Variabel Warna & Status
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD=$(tput bold); NORMAL=$(tput sgr0)
APKTOOL_JAR="$HOME/script/apktool.jar"
export PATH="$HOME/script:$PATH" # Tambahkan folder script ke PATH

# 2. Cek Ketersediaan Tools untuk Display
check_tool_status() {
    # Cek Java
    if command -v java &> /dev/null; then
        STATUS_JAVA="${GREEN}[STABIL] JDK Ditemukan"
        STATUS_INSTALASI="${GREEN}Tool Sudah Siap!"
    else
        STATUS_JAVA="${RED}[GAJELAS] JDK Belum Ada"
        STATUS_INSTALASI="${RED}Instalasi Wajib!"
    fi
    
    # Cek Apktool.jar
    if [ -f "$APKTOOL_JAR" ]; then
        STATUS_APKTOOL="${GREEN}[STABIL] Apktool.jar Ada"
    else
        STATUS_APKTOOL="${RED}[GAJELAS] Apktool.jar Hilang"
    fi
}

# 3. Fungsi Koordinator Instalasi (Dipanggil oleh Menu 0)
install_all_tools() {
    echo -e "\n${YELLOW}⚙️  [START INSTALASI OTOMATIS]${NC}"
    
    # 1. Jalankan Instalasi Java (Sekarang ada Menu Pilihan JDK)
    ./install-java.sh
    if [ $? -ne 0 ]; then return 1; fi # Cek error
    
    # 2. Jalankan Instalasi Gradle/Build Tools (AAPT, UNZIP)
    ./install-gradle.sh
    if [ $? -ne 0 ]; then return 1; fi # Cek error
    
    # 3. Jalankan Instalasi Apktool (Download JAR & Setup Alias)
    ./install-apktool.sh
    if [ $? -ne 0 ]; then return 1; fi # Cek error
    
    # RESTART WAJIB setelah instalasi Apktool/JDK
    echo -e "\n${BLUE}=================================================="
    echo "💡 PERHATIAN! Instalasi Selesai."
    echo -e "${YELLOW}Mohon TUTUP (exit) dan BUKA KEMBALI Termux Anda untuk mengaktifkan ALIAS 'apktool' !${NC}"
    echo "=================================================="
    exit 0
}

# 4. Fungsi Tampilan Menu Utama (Unik & Bersih)
show_main_menu() {
    clear
    check_tool_status # Update status sebelum menampilkan

    # Halaman Depan Keren
    echo -e "${RED}${BOLD}"
    echo "█▀█ ▄▀█ █░█ █░█ █▀█ █▀▀ ▄▀█ █▀▀ █▀█ █▀█"
    echo "█▀▄ █▀█ █▀█ ▀▄▀ █▀▄ █▄▄ █▀█ █▄▄ █▀▄ █▄█"
    echo -e "------------------------------------------------"
    echo -e "${NC}${YELLOW}TERMINAL STABIL BY MAWWSENPAI | ${STATUS_INSTALASI} ${NC}"
    echo -e "${RED}------------------------------------------------${NC}"
    
    echo -e "\n${BLUE}${BOLD}STATUS TOOL (Harus STABIL):${NC}${NORMAL}"
    echo -e "  Java/JDK: $STATUS_JAVA"
    echo -e "  Apktool: $STATUS_APKTOOL"
    echo -e "  Project: ${GREEN}[RAPIH] di $HOME/script${NC}"
    echo -e "------------------------------------------------"
    
    echo -e "\n${GREEN}Menu Utama (Pilih Nomer):${NC}"
    echo "1. Mod APK         (Bongkar & Edit Game Offline)"
    echo "2. Build APK       (Buat APK dari Source Code ZIP)"
    echo "3. Moded Plus APK  (Hilangkan iklan/premium - Riset Lanjutan)"
    echo "---"
    echo "0. Instalasi Tool  (${RED}WAJIB DULU!${NC})"
    echo "9. Keluar Terminal"
    
    read -p $'\n>> Masukkan pilihan [0-3, 9]: ' choice

    case $choice in
        1) 
            ./mod-apk.sh # Panggil modul Modifikasi APK
            ;;
        2) 
            ./build-apk.sh # Panggil modul Build APK
            ;;
        3) 
            echo -e "\n${YELLOW}Fitur Moded Plus APK masih dalam pengembangan, cuyy! Masih perlu riset jaringan.${NC}"
            sleep 3
            show_main_menu
            ;;
        0) 
            install_all_tools
            ;;
        9) 
            echo -e "\n${GREEN}Sampai jumpa lagi, cuyy! Jangan lupa di-git push!${NC}"
            exit 0
            ;;
        *) 
            echo -e "\n${RED}Pilihan gajelas, cuyy! Coba lagi.${NC}"
            sleep 1
            show_main_menu
            ;;
    esac
}

# 5. Loop Utama
while true; do
    show_main_menu
done
