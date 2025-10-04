RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_dependencies() {
    echo -e "${YELLOW}⚙️  [CEK] Memastikan Git dan Android-Tools (ADB) Terinstal...${NC}"
    pkg update -y
    
    if ! command -v adb &> /dev/null
    then
        echo -e "${YELLOW}🛠️  Instalasi Android-Tools (ADB)... Tunggu sebentar ya cuyy! ${NC}"
        pkg install android-tools -y
    fi
    echo -e "${GREEN}✅ OK: ADB siap jadi 'senpai' kamu.${NC}"
}

start_shizuku_guide() {
    clear
    echo -e "=================================================="
    echo -e "${GREEN}🔐 SENPAI.SH | PANDUAN AKSES SISTEM TANPA ROOT ${NC}"
    echo -e "=================================================="
    
    echo -e "\n${BLUE}STEP 1: Instal Aplikasi Shizuku.${NC}"
    echo ">> Download dan instal aplikasi 'Shizuku' dari Play Store."
    echo ">> JALANKAN Shizuku dan aktifkan melalui metode 'Pairing' (Pasangkan) atau 'ADB Wireless' di Pengaturan Developer HP kamu."
    echo ">> Pastikan status Shizuku di aplikasinya: ${GREEN}'Shizuku is running'${NC}"

    echo -e "\n${BLUE}STEP 2: Aktifkan Jembatan ADB.${NC}"
    echo ">> Shizuku yang aktif akan 'membuka pintu' ke Termux."
    echo ">> Di Termux, jalankan perintah ini (HANYA SEKALI per booting HP):"
    echo -e "${YELLOW}    adb shell sh /sdcard/Android/data/moe.shizuku.privileged.api/start.sh${NC}"
    
    echo -e "\n${BLUE}STEP 3: Tes Akses Data Terlarang!${NC}"
    echo ">> Kalau berhasil, kamu sekarang bisa masuk ke folder data game! 🥳"
    echo ">> Coba masukkan perintah ini. Kalau nggak ada error, berarti ${GREEN}BERHASIL!${NC}"
    echo -e "${YELLOW}    adb shell \"ls /sdcard/Android/data\"${NC}"

    echo -e "\n${BLUE}STEP 4: Mulai Obrak-Abrik!${NC}"
    echo ">> Sekarang kamu bisa pakai *script* ${YELLOW}cheat.sh${NC} kamu, atau langsung masuk ke shell ADB:"
    echo -e "${GREEN}    adb shell${NC}"
    echo ">> Di dalam shell ADB, kamu bisa akses: ${YELLOW}cd /sdcard/Android/data/NAMAPAKETMU/files${NC}"
    
    echo -e "\n${YELLOW}=================================================="
    echo "Berhasil cuyy! Kamu udah jadi Senpai di sistem Android!"
    echo "Sekarang kamu bisa bikin ${GREEN}cheat.sh${NC} jalan stabil!"
    echo "==================================================${NC}"
}

# 4. Eksekusi
check_dependencies
start_shizuku_guide
