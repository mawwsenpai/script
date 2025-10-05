#!/bin/bash

# =======================================================
#               ORGANIZER.SH - Perapih File Cheat
# Script ini membuat struktur folder cheat di Internal Storage.
# =======================================================

# --- Palet Warna ---
BLUE='\033[0;34m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# --- [PERUBAHAN DI SINI] ---
# Folder Tujuan di Internal Storage, sekarang lebih terorganisir
BASE_DIR="$HOME/storage/shared/MawwScript/File-Mod"
MODED_DIR="$BASE_DIR/Moded"
FILES_DIR="$BASE_DIR/File"

echo -e "=========================================="
echo -e "${BLUE}📁 ORGANIZER.SH | Membuat Struktur Folder ${NC}"
echo -e "=========================================="

# 1. Cek Akses Storage (Wajib Stabil)
if [ ! -d "$HOME/storage/shared" ]; then
    echo -e "${RED}❌ ERROR: Akses storage belum ada. Jalankan 'termux-setup-storage'.${NC}"
    exit 1
fi

# 2. Membuat Struktur Folder
echo -e "${YELLOW}⚙️  Membuat folder di lokasi baru: '$BASE_DIR'${NC}"
mkdir -p "$MODED_DIR"
mkdir -p "$FILES_DIR"

if [ -d "$MODED_DIR" ] && [ -d "$FILES_DIR" ]; then
    echo -e "${GREEN}✅ SUKSES! Struktur folder sudah rapi dibuat!${NC}"
else
    echo -e "${RED}❌ GAGAL: Tidak bisa membuat folder. Cek izin Termux!${NC}"
    exit 1
fi

# 3. Panduan Penggunaan (Path sudah otomatis update)
echo -e "\n${BLUE}💡 Panduan Penggunaan Organizer:${NC}"
echo -e ">> File APK MODIFIKASI (hasil build/sign) simpan di:"
echo -e "   ${YELLOW}$MODED_DIR${NC}"
echo -e ">> File APK mentah yang mau dioprek simpan di:"
echo -e "   ${YELLOW}$FILES_DIR${NC}"

echo -e "\n${YELLOW}Sekarang, file APK yang mau kamu bongkar harus ada di folder Files!${NC}"
echo "=========================================="
