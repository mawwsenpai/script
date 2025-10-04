#!/bin/bash

# =======================================================
#               MAIN.SH - Koordinator Instalasi Stabil
# Script ini menjalankan proses instalasi dan eksekusi secara
# berurutan, memastikan semua tool siap sebelum modifikasi.
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Fungsi untuk menjalankan script dan mengecek status
run_step() {
    local SCRIPT_NAME=$1
    echo -e "\n=================================================="
    echo -e "${YELLOW}⚙️  [START] Menjalankan $SCRIPT_NAME...${NC}"
    echo -e "=================================================="
    
    # Jalankan script
    ./$SCRIPT_NAME
    
    # Cek status keluaran (exit status) dari script yang barusan dijalankan
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}❌ ERROR KRITIS: $SCRIPT_NAME GAGAL dieksekusi.${NC}"
        echo -e "${BLUE}Silakan periksa pesan error di atas dan coba lagi!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ SUKSES: $SCRIPT_NAME selesai secara stabil.${NC}"
}

# 1. Pastikan script-script lain executable
chmod +x install-java.sh install-apktool.sh mod-apk.sh

# 2. Jalankan Instalasi Java (Fix JDK 11)
run_step "install-java.sh"

# 3. Jalankan Instalasi Apktool (Download JAR & Setup Alias)
run_step "install-apktool.sh"

# ==========================================================
# CATATAN PENTING: RESTART TERMUX
# Alias 'apktool' baru akan dikenali setelah Termux di-restart.
# Kita ingatkan user untuk restart dulu sebelum MOD.
# ==========================================================

if grep -q "alias apktool=" ~/.bashrc; then
    echo -e "\n${BLUE}=================================================="
    echo -e "💡 PERHATIAN! Instalasi selesai!${NC}"
    echo -e "${YELLOW}Alias 'apktool' baru akan diaktifkan setelah Termux di-RESTART.${NC}"
    echo -e "Mohon tutup (exit) dan buka kembali Termux Anda."
    echo -e "Setelah restart, jalankan lagi ${GREEN}./main.sh${NC} untuk ke tahap Modifikasi (mod-apk.sh)!"
    echo -e "=================================================="
    exit 0
else
    # 4. Jika Termux sudah di-restart (atau alias sudah ada)
    echo -e "\n${GREEN}Semua Tool Sudah Siap! Lanjut ke tahap Modifikasi (Mod-APK)...${NC}"
    run_step "mod-apk.sh"
fi

