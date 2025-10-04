RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Daftar paket Java dan versi yang tersedia
declare -A JDK_OPTIONS
JDK_OPTIONS[1]="openjdk-21"
JDK_OPTIONS[2]="openjdk-17"
JDK_OPTIONS[3]="openjdk-11"
JDK_OPTIONS[4]="openjdk-8"
JDK_OPTIONS[5]="openjdk" # Versi generik

# 1. Pengecekan Awal
echo -e "${YELLOW}⚙️  [CEK] Memastikan Sistem dan Repositori Stabil...${NC}"
pkg update -y && pkg upgrade -y

if command -v java &> /dev/null
then
    echo -e "${GREEN}✅ SUKSES! Java sudah terinstal stabil. Skip instalasi.${NC}"
    exit 0
fi

# 2. Tampilkan Menu Pilihan JDK
while true; do
    clear
    echo -e "=================================================="
    echo -e "${BLUE}💡 PILIH VERSI JDK STABIL (Untuk Apktool/Gradle) ${NC}"
    echo -e "=================================================="
    echo -e "${YELLOW}PILIH DENGAN TELITI, CUYY! (Pilih yang PALING kamu yakini cocok)${NC}"

    for key in "${!JDK_OPTIONS[@]}"; do
        echo -e "  ${GREEN}$key.${NC} ${JDK_OPTIONS[$key]} "
    done
    
    echo -e "\n${RED}9. Ganti Mirror Repositori Termux (Jika instalasi gagal terus)${NC}"
    
    read -p $'\n>> Masukkan Pilihan Nomer: ' choice

    if [[ ${JDK_OPTIONS[$choice]} ]]; then
        SELECTED_JDK=${JDK_OPTIONS[$choice]}
        break
    elif [ "$choice" == "9" ]; then
        echo -e "\n${BLUE}Mengalihkan ke pengaturan repositori...${NC}"
        termux-change-repo
        # Setelah ganti repo, lanjutkan pengecekan instalasi
    else
        echo -e "\n${RED}❌ Pilihan gajelas, cuyy! Coba lagi.${NC}"
        sleep 2
    fi
done

# 3. Instalasi Final
echo -e "\n${YELLOW}🛠️  Instalasi Final: $SELECTED_JDK dan Wget...${NC}"

if pkg install "$SELECTED_JDK" wget -y; then
    echo -e "\n${GREEN}✅ SUKSES! $SELECTED_JDK berhasil diinstal.${NC}"
    echo -e "\n${BLUE}=================================================="
    echo "Instalasi Java Selesai. Lanjut instal Apktool!"
    echo "==================================================${NC}"
    exit 0
else
    echo -e "\n${RED}❌ ERROR KRITIS: $SELECTED_JDK GAGAL diinstal. ${NC}"
    echo ">> Coba lagi, dan pilih opsi 'Ganti Mirror Repositori' (Nomer 9)!"
    exit 1
fi
