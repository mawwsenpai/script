#!/bin/bash

# =======================================================
#               ORGANIZER.SH - Perapih File Cheat
# Script ini membuat struktur folder cheat di Internal Storage.
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

# Folder Tujuan di Internal Storage (Sesuai maumu, cuyy!)
BASE_DIR="/sdcard/FileMod"
MODED_DIR="$BASE_DIR/Moded"
FILES_DIR="$BASE_DIR/File"

echo -e "=========================================="
echo -e "${BLUE}📁 ORGANIZER.SH | Membuat Struktur Folder ${NC}"
echo -e "=========================================="

# 1. Cek Akses Storage (Wajib Stabil)
if [ ! -d "/sdcard" ]; then
    echo -e "${RED}❌ ERROR: Akses /sdcard belum ada. Jalankan 'termux-setup-storage'.${NC}"
    exit 1
fi

# 2. Membuat Struktur Folder
echo -e "${YELLOW}⚙️  Membuat folder utama '$BASE_DIR'..."
mkdir -p "$MODED_DIR"
mkdir -p "$FILES_DIR"

if [ -d "$MODED_DIR" ] && [ -d "$FILES_DIR" ]; then
    echo -e "${GREEN}✅ SUKSES! Struktur folder cheat sudah rapi dibuat!${NC}"
else
    echo -e "${RED}❌ GAGAL: Tidak bisa membuat folder di Internal Storage. Cek izin Termux!${NC}"
    exit 1
fi

# 3. Panduan Penggunaan
echo -e "\n${BLUE}💡 Panduan Penggunaan Organizer:${NC}"
echo -e ">> File APK MODIFIKASI (hasil 'sign-apk.sh') simpan di:"
echo -e "   ${YELLOW}Internal/FileMod/Moded/ ${NC}"
echo -e ">> File yang mau kamu obrak-abrik (misal: 'Pou.apk') simpan di:"
echo -e "   ${YELLOW}Internal/FileMod/File/ ${NC}"

echo -e "\n${YELLOW}Sekarang, file APK yang mau kamu bongkar harus ada di folder Files!${NC}"
echo "=========================================="
