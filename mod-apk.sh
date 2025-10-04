RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD=$(tput bold); NORMAL=$(tput sgrun)

APKTOOL_JAR="$HOME/script/apktool.jar"
SIGN_SCRIPT="$HOME/script/sign-apk.sh"
WORKSPACE_DIR="$HOME/apk_projects"
LOG_DIR="$WORKSPACE_DIR/logs"
PATCHER_DIR="$HOME/script/game"

LOG_FILE=""
trap 'echo -e "\n\n${RED}⚠️  Proses dihentikan paksa. Script berhenti.${NC}"; exit 1' INT TERM

# --- [2] FUNGSI-FUNGSI UTILITY (HELPER) ---

setup_lingkungan() { mkdir -p "$WORKSPACE_DIR" "$LOG_DIR" "$PATCHER_DIR"; }

tampilkan_header() {
    clear
    echo -e "${BLUE}${BOLD}===================================================================${NC}"
    echo -e "${GREEN}${BOLD}            🔧 MOD-APK.SH v7.0 - The Suite 🔧${NC}"
    echo -e "${BLUE}${BOLD}===================================================================${NC}"
    echo -e "${YELLOW}Lingkungan Kerja: $WORKSPACE_DIR${NC}\n"
}

cek_dependensi() {
    echo -e "${YELLOW}🔍 Mengecek kesiapan sistem dan semua alat tempur...${NC}"
    local ALL_OK=1
    if ! command -v java &>/dev/null; then echo -e "${RED}  ❌ Java (JDK): Tidak ditemukan!${NC}"; ALL_OK=0; fi
    if [ ! -f "$APKTOOL_JAR" ]; then echo -e "${RED}  ❌ Apktool JAR: Tidak ditemukan!${NC}"; ALL_OK=0; fi
    if [ ! -f "$SIGN_SCRIPT" ]; then echo -e "${RED}  ❌ Sign Script: Tidak ditemukan!${NC}"; ALL_OK=0; fi
    if ! command -v xmllint &>/dev/null; then echo -e "${RED}  ❌ XML Validator (xmllint): Tidak ditemukan! (pkg install libxml2-utils)${NC}"; ALL_OK=0; fi
    if [ $ALL_OK -eq 1 ]; then echo -e "${GREEN}✅ Semua alat tempur siap!${NC}\n"; else echo -e "\n${RED}🔥 Sistem belum siap! Mohon install kebutuhan di atas.${NC}"; exit 1; fi
}

# --- [3] FUNGSI-FUNGSI INTI (WORKFLOW) ---

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
        echo "1. Edit File (nano)"
        echo "2. Cari Kata Kunci (grep)"
        echo "3. Buka Terminal di Folder Proyek"
        echo -e "${GREEN}4. Selesai Editing (Lanjut Rebuild)${NC}"
        read -p ">> Pilihan Anda: " edit_choice
        case $edit_choice in
            1) read -p ">> Masukkan path file dari dalam proyek: " file_to_edit
               if [ -f "$PROJECT_DIR/$file_to_edit" ]; then nano "$PROJECT_DIR/$file_to_edit"; else echo -e "${RED}❌ File tidak ditemukan!${NC}"; sleep 2; fi ;;
            2) read -p ">> Masukkan kata kunci yang ingin dicari: " search_term
               echo -e "${YELLOW}🔍 Mencari '$search_term'...${NC}"; grep -rni "$search_term" "$PROJECT_DIR"; read -p $'\nTekan [ENTER] untuk kembali...';;
            3) echo -e "${YELLOW}Membuka sub-shell. Ketik 'exit' untuk kembali.${NC}"; sleep 2; (cd "$PROJECT_DIR" && bash) ;;
            4) echo -e "${GREEN}✅ Selesai editing...${NC}"; break ;;
            *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
        esac
    done
}

pasang_apk() {
    local PROJECT_DIR=$1
    local APK_NAME=$(basename "$PROJECT_DIR" -MODIF)
    echo ""
    read -p ">> Masukkan nama file APK keluaran (tanpa .apk) [Default: ${APK_NAME}-Mod]: " CUSTOM_NAME
    local REBUILT_APK="${WORKSPACE_DIR}/${CUSTOM_NAME:-${APK_NAME}-Mod}.apk"
    
    LOG_FILE="$LOG_DIR/${APK_NAME}_rebuild_$(date +%F_%H-%M-%S).log"
    echo -e "\n${BLUE}🔧 Merakit ulang menjadi '$(basename "$REBUILT_APK")'...${NC}"
    echo -e "${YELLOW}   (Log lengkap disimpan di: $LOG_FILE)${NC}"
    
    if java -jar "$APKTOOL_JAR" b "$PROJECT_DIR" -f -o "$REBUILT_APK" | tee "$LOG_FILE"; then
        echo -e "\n${GREEN}🎉 SUKSES REBUILD!${NC}"
        echo -e "${YELLOW}🧹 Membersihkan folder proyek untuk menghemat ruang...${NC}"
        rm -rf "$PROJECT_DIR"
        tanda_tangan_apk "$REBUILT_APK"
    else
        echo -e "\n${RED}❌ GAGAL Rebuild APK! Cek log error di atas.${NC}"; return 1
    fi
}

bongkar_apk() {
    local PRESET_APK_PATH=$1; local INPUT_PATH=""
    if [ -n "$PRESET_APK_PATH" ]; then
        INPUT_PATH="$PRESET_APK_PATH"
        tampilkan_header
        echo -e "${GREEN}✅ Menggunakan file APK hasil ekstraksi: $(basename $INPUT_PATH)${NC}"
    else
        tampilkan_header
        read -p ">> Masukkan NAMA FILE APK: " APK_FILE
        if [ -z "$APK_FILE" ]; then echo -e "${RED}ERROR: Nama file jangan kosong!${NC}"; return; fi
        if [ -f "$APK_FILE" ]; then INPUT_PATH="$APK_FILE"; elif [ -f "$HOME/storage/downloads/$APK_FILE" ]; then INPUT_PATH="$HOME/storage/downloads/$APK_FILE"; elif [ -f "$HOME/storage/shared/$APK_FILE" ]; then INPUT_PATH="$HOME/storage/shared/$APK_FILE"; else echo -e "${RED}❌ ERROR: File '$APK_FILE' tidak ditemukan!${NC}"; return; fi
        echo -e "${GREEN}✅ File ditemukan di: $INPUT_PATH${NC}"
    fi

    local APK_NAME=$(basename "$INPUT_PATH" .apk)
    local PROJECT_DIR="$WORKSPACE_DIR/${APK_NAME}-MODIF"
    LOG_FILE="$LOG_DIR/${APK_NAME}_decompile_$(date +%F_%H-%M-%S).log"
    
    echo -e "\n${BLUE}🔨 Membongkar $APK_NAME.apk ke '$PROJECT_DIR'...${NC}"
    echo -e "${YELLOW}   (Log lengkap disimpan di: $LOG_FILE)${NC}"
    if java -jar "$APKTOOL_JAR" d "$INPUT_PATH" -f -o "$PROJECT_DIR" | tee "$LOG_FILE"; then
        echo -e "\n${GREEN}🎉 SUKSES BONGKAR! Proyek siap dioperasikan.${NC}"
        
        while true; do
            echo -e "\n${BLUE}${BOLD}--- TINDAKAN SELANJUTNYA ---${NC}"
            echo "1. Edit Manual (Masuk Ruang Operasi)"
            echo "2. Terapkan Patch Otomatis"
            read -p ">> Pilihan Anda [1/2]: " action_choice
            case $action_choice in
                1) menu_editing "$PROJECT_DIR"; break ;;
                2) if [ ! -d "$PATCHER_DIR" ] || [ -z "$(ls -A $PATCHER_DIR)" ]; then echo -e "${RED}❌ Folder patcher '$PATCHER_DIR' kosong!${NC}"; sleep 3; continue; fi
                   echo -e "\n${BLUE}Patcher yang tersedia:${NC}"; ls -1 "$PATCHER_DIR"
                   read -p ">> Masukkan nama patcher: " patcher_script
                   if [ -f "$PATCHER_DIR/$patcher_script" ]; then
                       if bash "$PATCHER_DIR/$patcher_script" "$PROJECT_DIR"; then echo -e "${GREEN}✅ Patcher selesai. Melanjutkan...${NC}"; sleep 2; break;
                       else echo -e "${RED}❌ Patcher gagal. Proses dibatalkan.${NC}"; sleep 4; return; fi
                   else echo -e "${RED}❌ Script patcher tidak ditemukan!${NC}"; sleep 2; fi ;;
                *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
            esac
        done

        if validasi_xml "$PROJECT_DIR"; then pasang_apk "$PROJECT_DIR"; fi
    else
        echo -e "\n${RED}❌ GAGAL Membongkar APK! Cek log error di atas.${NC}"
    fi
}

ekstrak_apk_terpasang() {
    tampilkan_header; echo -e "${GREEN}${BOLD}--- MENU: Ekstrak APK Terpasang ---${NC}"
    if ! command -v su &>/dev/null; then echo -e "\n${RED}❌ FITUR INI MEMBUTUHKAN AKSES ROOT!${NC}"; sleep 4; return; fi
    echo -e "\n${BLUE}Memuat daftar aplikasi terpasang...${NC}"; pm list packages -3 | cut -d ':' -f 2 | sort
    echo -e "\n${YELLOW}Salin nama paket aplikasi dari daftar di atas.${NC}"; read -p ">> Masukkan nama paket target: " PKG_NAME
    if [ -z "$PKG_NAME" ]; then echo -e "${RED}Nama paket kosong!${NC}"; return; fi
    local APK_PATH=$(pm path "$PKG_NAME" | sed 's/package://'); if [ -z "$APK_PATH" ]; then echo -e "${RED}❌ GAGAL! Paket tidak ditemukan.${NC}"; return; fi
    local DEST_PATH="$WORKSPACE_DIR/${PKG_NAME}.apk"
    echo -e "\n${YELLOW}🚛 Mengekstrak APK menggunakan akses root...${NC}"
    if su -c "cp '$APK_PATH' '$DEST_PATH' && chmod 666 '$DEST_PATH'"; then
        echo -e "${GREEN}🎉 SUKSES! APK berhasil diekstrak.${NC}"; sleep 2
        bongkar_apk "$DEST_PATH"
    else
        echo -e "${RED}❌ GAGAL! Gagal menyalin file. Pastikan izin root diberikan.${NC}"; return
    fi
}

# --- [4] BLOK EKSEKUSI UTAMA ---
setup_lingkungan
tampilkan_header
cek_dependensi

while true; do
    echo -e "\n${GREEN}${BOLD}--- MENU UTAMA ---${NC}"
    echo "1. Mod APK dari File (.apk)"
    echo "2. Ekstrak & Mod APK Terpasang ${RED}(Butuh Root)${NC}"
    echo "3. Pasang Ulang dari Folder Proyek"
    echo "9. Keluar"
    read -p ">> Masukkan pilihan: " choice
    case $choice in
        1) bongkar_apk ;;
        2) ekstrak_apk_terpasang ;;
        3) tampilkan_header; read -p ">> Masukkan path lengkap folder proyek di '$WORKSPACE_DIR': " FOLDER_PROYEK
           if [ -d "$FOLDER_PROYEK" ]; then if validasi_xml "$FOLDER_PROYEK"; then pasang_apk "$FOLDER_PROYEK"; fi
           else echo -e "${RED}❌ Folder tidak ditemukan!${NC}"; fi ;;
        9) echo -e "\n${BLUE}Sampai jumpa lagi!${NC}"; exit 0 ;;
        *) echo -e "\n${RED}Pilihan tidak valid!${NC}" ;;
    esac
    echo -e "\n${YELLOW}Tekan [ENTER] untuk kembali ke menu utama...${NC}"; read -p ""
    tampilkan_header
done
