# =======================================================
#               CHEAT.SH - STABIL
# Fokus: Pengecekan Izin & Validasi Input yang Teliti.
# =======================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DATA_PATH="/sdcard/Android/data"

check_storage_permission() {
    echo -e "${YELLOW}⚙️  [CEK] Memastikan Akses Storage Termux Stabil...${NC}"

    if [ ! -d "/sdcard" ]; then
        echo -e "${RED}❌ GAGAL: '/sdcard' belum terhubung.${NC}"
        echo "   Solusi: Jalankan 'termux-setup-storage' dan berikan izin."
        echo "   Menghentikan script demi kestabilan... ${RED}BYE!${NC}"
        exit 1
    fi

    if [ ! -d "$DATA_PATH" ]; then
        echo -e "${RED}❌ GAGAL: Folder '$DATA_PATH' TIDAK DITEMUKAN atau TIDAK BISA DIAKSES.${NC}"
        echo "   Ini bisa karena: 1) Android 11+ (Scoped Storage). 2) Izin belum penuh."
        echo "   Coba pastikan izin diberikan manual di Pengaturan HP kamu, **cuyy**!"
        exit 1
    fi
    echo -e "${GREEN}✅ OK: Akses Storage Stabil. Lanjut Obrak-Abrik!${NC}"
}

validate_input() {
    clear
    echo -e "============================================"
    echo -e "${GREEN}💰 OBRAL-ABRIK FILE GAME STABIL ${NC}"
    echo -e "============================================"
    
    echo -e "\n${YELLOW}🔎 [INFO] Daftar Folder Game (Pilih yang kamu mau oprek):${NC}"

    ls -l $DATA_PATH | grep 'com.' | awk '{print $NF}' | nl 

    echo -e "\n---"
    read -p ">> Masukkan NAMA PAKET GAME UTUH (Contoh: com.game.offline): " GAME_PACKAGE

    if [ -z "$GAME_PACKAGE" ]; then
        echo -e "\n${RED}❌ ERROR: Input nama paket nggak boleh kosong, **cuyy**!${NC}"
        exit 1
    fi

    TARGET_FOLDER="$DATA_PATH/$GAME_PACKAGE/files"
    
    if [ ! -d "$TARGET_FOLDER" ]; then
        echo -e "${YELLOW}⚠️ PERINGATAN: Folder '/files' nggak ketemu. Mencoba pindah ke folder utama paket...${NC}"
        TARGET_FOLDER="$DATA_PATH/$GAME_PACKAGE"
        
        if [ ! -d "$TARGET_FOLDER" ]; then
            echo -e "${RED}❌ ERROR: Folder untuk paket '$GAME_PACKAGE' nggak ada sama sekali di '$DATA_PATH'.${NC}"
            echo "   [KESIMPULAN STABIL]: Game ini nggak nyimpen data di situ, atau salah nama paket."
            exit 1
        fi
    fi
    
    echo -e "\n${BLUE}🚀 BERHASIL! Navigasi Stabil ke Folder Game...${NC}"
    echo "   [LOKASI]: ${YELLOW}$TARGET_FOLDER${NC}"
    
    cd "$TARGET_FOLDER"
    
    echo -e "\n${YELLOW}📁 [LIST FILE] Cari file save game (.xml, .json, .dat, .sav):${NC}"
    ls -lh 
    
    echo -e "\n${GREEN}💡 LANJUTKAN SENDIRI, **CUYY**! ${NC}"
    echo "   Gunakan 'nano [nama_file]' untuk mengedit data game-mu. **Jelas** kan?"
    echo "============================================"
}

check_storage_permission
validate_input
