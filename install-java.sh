
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

declare -A JDK_OPTIONS
JDK_OPTIONS[1]="openjdk-21"
JDK_OPTIONS[2]="openjdk-17" # Sering jadi standar buat proyek baru
JDK_OPTIONS[3]="openjdk-11"
JDK_OPTIONS[4]="openjdk-8"
JDK_OPTIONS[5]="openjdk"   # Versi generik default dari repo

tampilkan_menu() {
    clear
    echo -e "=================================================="
    echo -e "${BLUE}💡 PILIH VERSI JDK STABIL (Untuk Apktool/Gradle) ${NC}"
    echo -e "=================================================="
    echo -e "${YELLOW}PILIH DENGAN TELITI, CUYY! (Rekomendasi: 17 atau 21)${NC}"

    # Loop buat nampilin semua opsi dari array
    for key in "${!JDK_OPTIONS[@]}"; do
        echo -e "  ${GREEN}$key.${NC} ${JDK_OPTIONS[$key]}"
    done
    
    echo -e "\n${RED}9. Ganti Mirror Repositori (Jika instalasi sering gagal)${NC}"
}

# Fungsi buat ganti repo, biar fokus
ganti_repo() {
    echo -e "\n${BLUE}Mengalihkan ke menu pengaturan repositori Termux...${NC}"
    sleep 1
    termux-change-repo
    echo -e "\n${YELLOW}⚙️  [WAJIB] Menjalankan update setelah ganti mirror...${NC}"
    pkg update -y
    echo -e "\n${GREEN}✅ Mirror berhasil diganti. Silakan coba install lagi dari menu.${NC}"
    sleep 3
}

# Fungsi buat proses instalasi
install_paket() {
    local SELECTED_JDK="$1"
    echo -e "\n${YELLOW}🛠️  Instalasi Final: $SELECTED_JDK dan Wget...${NC}"
    # wget diinstal sekalian karena biasanya dibutuhin sama script install-apktool.sh
    
    if pkg install "$SELECTED_JDK" wget -y; then
        echo -e "\n${GREEN}✅ MANTAP! $SELECTED_JDK dan Wget berhasil diinstal.${NC}"
        echo -e "\n${BLUE}=================================================="
        echo "   Instalasi Java Selesai. Lanjut ke Apktool!"
        echo -e "==================================================${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ ERROR KRITIS: $SELECTED_JDK GAGAL diinstal! ${NC}"
        echo ">> Coba lagi, dan kalau gagal terus, pilih opsi 'Ganti Mirror Repositori' (Nomer 9)!"
        exit 1
    fi
}

# =================================================
#                 PROGRAM UTAMA
# =================================================

echo -e "${YELLOW}⚙️  [CEK] Memastikan Sistem dan Repositori Stabil...${NC}"
pkg update -y > /dev/null 2>&1 # Jalanin di background biar gak rame

# Cek dulu, siapa tau Java udah ada
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo -e "${GREEN}✅ SUKSES! Java udah terinstal stabil (Versi: $JAVA_VERSION). Skip instalasi.${NC}"
    exit 0
fi

# Looping menu utama
while true; do
    tampilkan_menu
    read -p $'\n>> Masukkan Pilihan Nomer: ' choice

    case "$choice" in
        [1-5]) # Cek pilihan dari 1 sampai 5
            SELECTED_JDK=${JDK_OPTIONS[$choice]}
            install_paket "$SELECTED_JDK"
            ;;
        9)
            ganti_repo
            continue # Balik lagi ke awal loop buat nampilin menu
            ;;
        *)
            echo -e "\n${RED}❌ Pilihan ngaco, cuyy! Coba lagi.${NC}"
            sleep 2
            ;;
    esac
done
