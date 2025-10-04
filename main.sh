RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
APKTOOL_JAR="$HOME/script/apktool.jar"
export PATH="$HOME/script:$PATH" 

check_tool_status() {
    # Cek Java
    if command -v java &> /dev/null; then
        STATUS_JAVA="${GREEN}[STABIL] Java (JDK)"
    else
        STATUS_JAVA="${RED}[GAJELAS] Java (JDK)"
    fi
    
    # Cek Apktool.jar
    if [ -f "$APKTOOL_JAR" ]; then
        STATUS_APKTOOL="${GREEN}[STABIL] Apktool JAR"
    else
        STATUS_APKTOOL="${RED}[GAJELAS] Apktool JAR"
    fi
}

install_all_tools() {
    echo -e "\n${YELLOW}⚙️  [START INSTALASI OTOMATIS]${NC}"
    ./install-java.sh
    if [ $? -ne 0 ]; then return 1; fi # Cek error
    ./install-apktool.sh
    if [ $? -ne 0 ]; then return 1; fi # Cek error
    
    echo -e "\n${BLUE}=================================================="
    echo "💡 PERHATIAN! Instalasi Selesai."
    echo "Mohon TUTUP (exit) dan BUKA KEMBALI Termux Anda untuk mengaktifkan alias 'apktool'!"
    echo "==================================================${NC}"
    exit 0
}

show_main_menu() {
    clear
    check_tool_status 
    
    echo -e "${RED}------------------------------------------------${NC}"
    echo -e "${YELLOW}🛠️  Option Apk Tool By MawwSenpai_${NC}"
    echo -e "${RED}------------------------------------------------${NC}"
    
    echo -e "\n${BLUE}STATUS TOOLS STABIL:${NC}"
    echo -e "  $STATUS_JAVA"
    echo -e "  $STATUS_APKTOOL"
    echo -e "------------------------------------------------"
    
    echo -e "\n${GREEN}Menu Utama (Pilih Nomer):${NC}"
    echo "1. Mod APK (Membuat game offline unlimited/kuat)"
    echo "2. Build APK (Membuat APK dari kode Smali yang sudah diedit)"
    echo "3. Moded Plus APK (Menghilangkan iklan/fitur premium - Lanjutan)"
    echo "---"
    echo "0. Instalasi/Perbaikan Tool (${STATUS_JAVA} | ${STATUS_APKTOOL})"
    echo "9. Keluar"
    
    read -p $'\n>> Masukkan pilihan [0-3, 9]: ' choice

    case $choice in
        1) 
            ./mod-apk.sh 
            ;;
        2) 
            ./mod-apk.sh rebuild 
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

while true; do
    show_main_menu
done
