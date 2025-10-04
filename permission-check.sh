RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
CHECK_STATUS=0

echo -e "=================================================="
echo -e "${YELLOW}🔑 PERMISSION-CHECK | Memvalidasi Akses Stabil ${NC}"
echo -e "=================================================="

# 1. Cek Izin Storage (Wajib untuk /sdcard)
if [ ! -d "$HOME/storage/downloads" ]; then
    echo -e "${RED}❌ [STORAGE] Akses /sdcard TIDAK DITEMUKAN.${NC}"
    echo -e "${YELLOW}>> WAJIB: Jalankan 'termux-setup-storage' dan berikan izin!${NC}"
    termux-setup-storage
    CHECK_STATUS=1
fi

# 2. Cek Akses Root (Profesional Check)
if command -v su &> /dev/null || command -v tsu &> /dev/null; then
    echo -e "${GREEN}✅ [ROOT] Akses Root Ditemukan. Operasi akan stabil!${NC}"
else
    echo -e "${YELLOW}⚠️ [ROOT] Akses Root TIDAK DITEMUKAN.${NC}"
fi

# 3. Cek Akses Data Game (Izin Data / Shizuku)
if [ -d "/sdcard/Android/data" ]; then
    echo -e "${GREEN}✅ [DATA] Akses /Android/data Ditemukan. Stabil!${NC}"
else
    echo -e "${RED}❌ [DATA] Akses /Android/data DITOLAK oleh Android Scoped Storage.${NC}"
    echo -e "${BLUE}>> Solusi: Gunakan aplikasi Shizuku dan perintah ADB untuk membuka akses!${NC}"
fi

if [ $CHECK_STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ VALIDASI SELESAI: Lingkungan STABIL!${NC}"
else
    echo -e "${RED}⚠️ VALIDASI BERMASALAH: Mohon perbaiki error di atas!${NC}"
fi

# Kembalikan status check (0 jika OK, 1 jika ada peringatan/gagal)
return $CHECK_STATUS
