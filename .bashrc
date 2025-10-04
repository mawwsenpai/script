# =======================================================
#             CUSTOM HOMEPAGE TERMUX MAWWSENPAI
# =======================================================

# Warna dan Format
BLUE='\033[0;34m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

# 1. Menampilkan Banner Keren (Bisa diganti dengan FIGlet kalau kamu install)
echo -e "${RED}${BOLD}"
echo "------------------------------------------------"
echo "|        😎 WELCOME, SENPAI MAWW! 😎          |"
echo "------------------------------------------------"
echo -e "${NC}"

# 2. Status Tool Penting
echo -e "${YELLOW}⚙️  [STATUS TOOLS STABIL]${NC}"
echo -e "----------------------------------------"

# a. Status Akses Folder (Shizuku)
if [ -d "/sdcard/Android/data" ]; then
    echo -e "${GREEN}✅ Shizuku Access: STABIL${NC} (Akses /Android/data)"
else
    echo -e "${RED}❌ Shizuku Access: GAJELAS${NC} (Jalankan ulang 'adb shell sh /sdcard/Android/data/...') "
fi

# b. Status Apktool & Java
if [ -f "$HOME/script/apktool.jar" ]; then
    echo -e "${GREEN}✅ Apktool: RAPIH${NC} (Siap Bongkar APK)"
else
    echo -e "${RED}❌ Apktool: BELUM${NC} (Jalankan ./mod-apk.sh)"
fi

# 3. Panduan Cepat
echo -e "\n${BLUE}${BOLD}💡 PANDUAN CEPAT CUYY:${NC}${NORMAL}"
echo -e ">> ${YELLOW}cd script${NC}  : Masuk folder project"
echo -e ">> ${YELLOW}apktool${NC}    : Tidak bisa. Ganti dengan: ${GREEN}java -jar apktool.jar${NC}"
echo -e ">> ${YELLOW}./organizer.sh${NC}: Cek folder cheat kamu"

# 4. Prompt Termux (Membuat Tampilan Prompt lebih clean)
PS1='${GREEN}\u@\h${NC}:${BLUE}\w${NC}\$ '
