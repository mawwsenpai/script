RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
export PATH="$HOME/script:$PATH" # Pastikan script dan tools diakses

echo -e "=================================================="
echo -e "${BLUE}🏗️  BUILD-APK.SH | Membuat APK dari Source Code ZIP ${NC}"
echo -e "=================================================="

# 1. Cek Kesiapan Tool Wajib
if ! command -v java &> /dev/null; then
    echo -e "${RED}❌ ERROR: Java (JDK) belum terinstal. Silakan instalasi Java dulu!${NC}"
    exit 1
fi
# Asumsi Build Tools (unzip, aapt) sudah diinstal di main.sh

# 2. Pengecekan Lokasi File ZIP
if [ ! -d "$HOME/storage/downloads" ]; then
    echo -e "${RED}❌ ERROR: Akses storage belum ada. Jalankan 'termux-setup-storage'.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Contoh lokasi file ZIP: ${BLUE}~/storage/downloads/MyApp.zip${NC}"
read -p ">> Masukkan PATH LENGKAP FILE ZIP: " ZIP_PATH

if [ ! -f "$ZIP_PATH" ]; then
    echo -e "${RED}❌ ERROR: File ZIP tidak ditemukan di '$ZIP_PATH'!${NC}"
    exit 1
fi

# 3. Ekstraksi dan Persiapan Build
PROJECT_NAME=$(basename "$ZIP_PATH" .zip)
PROJECT_DIR="$HOME/script/build-projects/$PROJECT_NAME"

echo -e "\n${YELLOW}🛠️  Ekstraksi $ZIP_PATH ke $PROJECT_DIR...${NC}"
mkdir -p "$PROJECT_DIR"
unzip -q "$ZIP_PATH" -d "$PROJECT_DIR"

# Pindah ke direktori project untuk menjalankan gradle
cd "$PROJECT_DIR" 
if [ ! -f "gradlew" ]; then
    echo -e "\n${RED}❌ ERROR: File 'gradlew' (Gradle Wrapper) tidak ditemukan di dalam ZIP!${NC}"
    echo ">> Build GAGAL. Project ZIP Anda harus menyertakan Gradle Wrapper."
    exit 1
fi

# 4. Proses Build menggunakan Gradle Wrapper
echo -e "\n${BLUE}🔨 Memulai proses Build menggunakan Gradle Wrapper...${NC}"
chmod +x gradlew 
./gradlew assembleDebug 

if [ $? -eq 0 ]; then
    # 5. Finishing dan Pindahkan Hasil
    FIND_APK=$(find "$PROJECT_DIR" -name "*.apk" -print -quit)
    if [ -n "$FIND_APK" ]; then
        echo -e "\n${GREEN}🎉 SUKSES! APK berhasil dibuat: $(basename "$FIND_APK")${NC}"
        
        # Pindahkan APK ke folder Moded/Stable (Membutuhkan organizer.sh)
        # Asumsi organizer.sh sudah di-chmod +x
        ./organizer.sh # Pastikan folder organizer dibuat
        
        cp "$FIND_APK" "$HOME/storage/FileMod/Moded/$(basename "$FIND_APK")"
        echo -e "${GREEN}>> APK dipindahkan ke Internal/FileMod/Moded/${NC}"
    else
        echo -e "${RED}❌ GAGAL: Gradle Build Sukses, tapi file APK tidak ditemukan!${NC}"
    fi
else
    echo -e "\n${RED}❌ GAGAL: Gradle Build gagal. Periksa log error Gradle di atas!${NC}"
fi
