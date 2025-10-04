
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD=$(tput bold); NORMAL=$(tput sgrun) # sgrun is more portable than sgr0
APKTOOL_JAR="$HOME/script/apktool.jar"
SIGN_SCRIPT="$HOME/script/sign-apk.sh"
WORKSPACE_DIR="$HOME/apk_projects"
LOG_DIR="$WORKSPACE_DIR/logs"
LOG_FILE=""
trap 'echo -e "\n\n${RED}⚠️ Proses dihentikan paksa.${NC}"; exit 1' INT TERM

setup_lingkungan() { mkdir -p "$WORKSPACE_DIR"; mkdir -p "$LOG_DIR"; }
tampilkan_header() { clear; echo -e "${BLUE}${BOLD}===================================================================${NC}"; echo -e "${GREEN}${BOLD}         🔧 MOD-APK.SH v4.0 - Integrated Modding Suite 🔧${NC}"; echo -e "${BLUE}${BOLD}===================================================================${NC}"; echo -e "${YELLOW}Lingkungan Kerja: $WORKSPACE_DIR${NC}\n"; }
cek_dependensi() {
    echo -e "${YELLOW}🔍 Mengecek kesiapan sistem...${NC}"; local ALL_OK=1
    if ! command -v java &>/dev/null; then echo -e "${RED}  ❌ Java (JDK): Tidak ditemukan!${NC}"; ALL_OK=0; fi
    if [ ! -f "$APKTOOL_JAR" ]; then echo -e "${RED}  ❌ Apktool: '$APKTOOL_JAR' tidak ditemukan!${NC}"; ALL_OK=0; fi
    if [ ! -f "$SIGN_SCRIPT" ]; then echo -e "${RED}  ❌ Sign Script: '$SIGN_SCRIPT' tidak ditemukan!${NC}"; ALL_OK=0; fi
    if ! command -v xmllint &>/dev/null; then echo -e "${RED}  ❌ XML Validator: 'xmllint' tidak ditemukan! (pkg install libxml2-utils)${NC}"; ALL_OK=0; fi
    if [ $ALL_OK -eq 1 ]; then echo -e "${GREEN}✅ Semua alat tempur siap!${NC}\n"; else echo -e "\n${RED}🔥 Sistem belum siap! Mohon install kebutuhan di atas.${NC}"; exit 1; fi
}
validasi_xml() {
    local PROJECT_DIR=$1; echo -e "\n${YELLOW}🔬 [Pre-flight Check] Memeriksa file XML...${NC}"
    for xml_file in $(find "$PROJECT_DIR/res" -type f -name "*.xml"); do
        if ! xmllint --noout "$xml_file" >/dev/null 2>&1; then
            echo -e "\n${RED}==================== ERROR SINTAKS DITEMUKAN ====================${NC}"
            echo -e "${RED}❌ Validasi GAGAL! File XML bermasalah.${NC}"; echo -e "${YELLOW}   File: $xml_file${NC}"
            echo -e "${BLUE}   Laporan:${NC}"; xmllint --noout "$xml_file"
            echo -e "${RED}===============================================================${NC}"
            echo -e "${YELLOW}>> Rebuild dibatalkan. Silakan perbaiki file di atas.${NC}"; return 1
        fi
    done
    echo -e "${GREEN}✅ [Pre-flight Check] Semua file XML sehat!${NC}"; return 0
}
tanda_tangan_apk() {
    local REBUILT_APK=$1; echo -e "\n${YELLOW}✍️  Memanggil script '$SIGN_SCRIPT' untuk signing...${NC}"
    if ! "$SIGN_SCRIPT" "$REBUILT_APK"; then echo -e "\n${RED}❌ Proses signing gagal!${NC}"; return 1; fi
}

menu_editing() {
    local PROJECT_DIR=$1
    while true; do
        tampilkan_header
        echo -e "${GREEN}Anda sekarang berada di 'Ruang Operasi' untuk proyek:${NC}"
        echo -e "${YELLOW}${PROJECT_DIR}${NC}"
        echo -e "\n${BLUE}${BOLD}--- MENU EDITING ---${NC}"
        echo "1. Edit File (Buka dengan nano)"
        echo "2. Cari Kata Kunci di Semua File (Grep)"
        echo "3. Buka Terminal di Folder Proyek (Akses Penuh)"
        echo "4. Lihat Struktur Folder (Tree view)"
        echo -e "${GREEN}5. Selesai Editing (Lanjut ke Proses Rebuild)${NC}"
        read -p ">> Pilihan Anda: " edit_choice

        case $edit_choice in
            1)
                read -p ">> Masukkan path file dari dalam proyek (misal: res/values/strings.xml): " file_to_edit
                if [ -f "$PROJECT_DIR/$file_to_edit" ]; then
                    nano "$PROJECT_DIR/$file_to_edit"
                else
                    echo -e "${RED}❌ File tidak ditemukan!${NC}"; sleep 2
                fi
                ;;
            2)
                read -p ">> Masukkan kata kunci yang ingin dicari: " search_term
                echo -e "${YELLOW}🔍 Mencari '$search_term' di semua file...${NC}"
                grep -rni "$search_term" "$PROJECT_DIR"
                read -p $'\nTekan [ENTER] untuk kembali...'
                ;;
            3)
                echo -e "${YELLOW}Membuka sub-shell. Ketik 'exit' untuk kembali ke menu editing.${NC}"
                sleep 2
                (cd "$PROJECT_DIR" && bash)
                ;;
            4)
                echo -e "${YELLOW}Menampilkan struktur folder (maksimal 3 level):${NC}"
                tree -L 3 "$PROJECT_DIR"
                read -p $'\nTekan [ENTER] untuk kembali...'
                ;;
            5)
                echo -e "${GREEN}✅ Selesai editing. Melanjutkan ke langkah selanjutnya...${NC}"
                break # Keluar dari loop editing
                ;;
            *)
                echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1
                ;;
        esac
    done
}

pasang_apk() {
    local PROJECT_DIR=$1
    local APK_NAME=$(basename "$PROJECT_DIR" -MODIF)
    
    # --- PERUBAHAN DI SINI ---
    echo ""
    read -p ">> Masukkan nama file APK keluaran (tanpa .apk): " CUSTOM_NAME
    if [ -z "$CUSTOM_NAME" ]; then
        # Jika kosong, gunakan nama default yang bersih
        REBUILT_APK="${WORKSPACE_DIR}/${APK_NAME}-Mod.apk"
        echo -e "${YELLOW}Nama kustom kosong, menggunakan nama default: $(basename $REBUILT_APK)${NC}"
    else
        REBUILT_APK="${WORKSPACE_DIR}/${CUSTOM_NAME}.apk"
        echo -e "${GREEN}Nama file diatur ke: $(basename $REBUILT_APK)${NC}"
    fi
    # --- AKHIR PERUBAHAN ---
    
    LOG_FILE="$LOG_DIR/${APK_NAME}_rebuild_$(date +%F_%H-%M-%S).log"
    
    echo -e "\n${BLUE}🔧 Merakit ulang (Rebuild) folder menjadi '$REBUILT_APK'...${NC}"
    echo -e "${YELLOW}   (Log lengkap disimpan di: $LOG_FILE)${NC}"
    
    if java -jar "$APKTOOL_JAR" b "$PROJECT_DIR" -f -o "$REBUILT_APK" | tee "$LOG_FILE"; then
        echo -e "\n${GREEN}🎉 SUKSES REBUILD! File sementara: ${YELLOW}$REBUILT_APK${NC}"
        # Hapus folder proyek setelah berhasil rebuild untuk menghemat ruang
        echo -e "${YELLOW}🧹 Membersihkan folder proyek...${NC}"
        rm -rf "$PROJECT_DIR"
        tanda_tangan_apk "$REBUILT_APK"
    else
        echo -e "\n${RED}❌ GAGAL Rebuild APK! Cek log error di atas.${NC}"
        return 1
    fi
}

# =================================================================
#           FUNGSI BONGKAR APK - SEKARANG TERINTEGRASI PENUH
# =================================================================
bongkar_apk() {
    tampilkan_header
    read -p ">> Masukkan NAMA FILE APK (Contoh: Pou.apk): " APK_FILE
    if [ -z "$APK_FILE" ]; then echo -e "${RED}ERROR: Nama file jangan kosong!${NC}"; return; fi

    # ... (logika pencarian file APK tetap sama) ...
    local INPUT_PATH="" 
    if [ -f "$APK_FILE" ]; then INPUT_PATH="$APK_FILE"; elif [ -f "$HOME/storage/downloads/$APK_FILE" ]; then INPUT_PATH="$HOME/storage/downloads/$APK_FILE"; elif [ -f "$HOME/storage/shared/$APK_FILE" ]; then INPUT_PATH="$HOME/storage/shared/$APK_FILE"; else echo -e "${RED}❌ ERROR: File '$APK_FILE' tidak ditemukan!${NC}"; return; fi
    echo -e "${GREEN}✅ File ditemukan di: $INPUT_PATH${NC}"

    local APK_NAME=$(basename "$APK_FILE" .apk)
    local PROJECT_DIR="$WORKSPACE_DIR/${APK_NAME}-MODIF"
    LOG_FILE="$LOG_DIR/${APK_NAME}_decompile_$(date +%F_%H-%M-%S).log"
    
    echo -e "\n${BLUE}🔨 Membongkar $APK_FILE ke '$PROJECT_DIR'...${NC}"
    echo -e "${YELLOW}   (Log lengkap disimpan di: $LOG_FILE)${NC}"

    if java -jar "$APKTOOL_JAR" d "$INPUT_PATH" -f -o "$PROJECT_DIR" | tee "$LOG_FILE"; then
        echo -e "\n${GREEN}🎉 SUKSES BONGKAR! Memasuki Ruang Operasi...${NC}"
        sleep 2
        
        # --- PERUBAHAN DI SINI: Panggil Menu Editing ---
        menu_editing "$PROJECT_DIR"

        # Setelah keluar dari menu editing, lanjutkan ke validasi dan pemasangan
        if validasi_xml "$PROJECT_DIR"; then
            pasang_apk "$PROJECT_DIR"
        fi
    else
        echo -e "\n${RED}❌ GAGAL Membongkar APK! Cek log error di atas.${NC}"
        return
    fi
}


# --- [4] BLOK EKSEKUSI UTAMA (MANAJER) ---
# (Blok eksekusi utama dan menu utama dari v3.0 tetap sama)
setup_lingkungan
tampilkan_header
cek_dependensi
while true; do
    echo -e "\n${GREEN}${BOLD}--- MENU UTAMA ---${NC}"
    echo "1. Bongkar, Edit, dan Pasang APK (Alur Lengkap)"
    echo "2. Pasang Ulang dari Folder Proyek (Jika ada sisa)"
    echo "9. Keluar"
    read -p ">> Masukkan pilihan: " choice
    case $choice in
        1) bongkar_apk ;;
        2) 
            tampilkan_header; read -p ">> Masukkan path folder proyek di '$WORKSPACE_DIR': " FOLDER_PROYEK
            if [ -d "$FOLDER_PROYEK" ]; then
                if validasi_xml "$FOLDER_PROYEK"; then pasang_apk "$FOLDER_PROYEK"; fi
            else echo -e "${RED}❌ Folder tidak ditemukan!${NC}"; fi ;;
        9) echo -e "\n${BLUE}Sampai jumpa lagi!${NC}"; exit 0 ;;
        *) echo -e "\n${RED}Pilihan tidak valid!${NC}" ;;
    esac
    echo -e "\n${YELLOW}Tekan [ENTER] untuk kembali ke menu utama...${NC}"; read -p ""
    tampilkan_header
done
