#!/bin/bash

# =======================================================
#               SIGN-APK.SH - Pemberi Tanda Tangan Digital
# Script ini untuk menandatangani APK yang sudah dimodifikasi.
# Wajib agar Android mau menginstal APK hasil mod.
# =======================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}❌ ERROR: Masukkan nama file APK yang mau di-sign, cuyy!${NC}"
    echo "Contoh: ./sign-apk.sh pou-cheat.apk"
    exit 1
fi

APK_FILE="$1"
SIGNED_APK="${APK_FILE%.apk}-SIGNED.apk"

echo -e "${YELLOW}⚙️  [CEK] Memastikan Zipalign dan Apksigner Terinstal...${NC}"
pkg install zipalign apksigner -y

echo -e "\n${BLUE}🚀 [PROSES] Menandatangani $APK_FILE...${NC}"

# Menggunakan Apksigner untuk menandatangani APK dengan sertifikat debug
apksigner sign --debuggable --min-sdk-version 21 --out $SIGNED_APK $APK_FILE

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}🎉 SUKSES! APK berhasil ditandatangani!${NC}"
    echo ">> File hasil: ${YELLOW}$SIGNED_APK${NC}"
    echo ">> Sekarang kamu bisa pindahkan file ini ke HP kamu untuk diinstal!"
else
    echo -e "\n${RED}❌ GAGAL! Gagal menandatangani APK. Cek kembali instalasi Apksigner.${NC}"
fi
