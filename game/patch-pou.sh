#!/bin/bash

# ===================================================================================
#           HUNTER-KILLER SCRIPT v1.0 - Pou Free Shopping
#
#   Script ini secara otomatis melakukan seluruh proses investigasi:
#   1. Menemukan ID resource dari string "Not enough coins!".
#   2. Melacak ID tersebut ke dalam file Smali.
#   3. Menganalisis kode di sekitar ID untuk menemukan logika percabangan 'if-'.
#   4. Melumpuhkan logika tersebut secara otomatis.
#
#   DIRANCANG UNTUK POU (dan game sejenis dengan pola yang sama)
# ===================================================================================

# --- [1] KONFIGURASI ---
PROJECT_DIR=$1
CLUE_STRING="Not enough coins!" # Jejak awal yang kita cari

# --- [2] FUNGSI PEMBANTU ---
# Fungsi buat ngasih laporan ke pengguna
report() {
    local color=$1; local message=$2
    echo -e "${color}   -> $message${NC}"
}

# --- [3] ALUR KERJA ROBOT ---
echo -e "\n${BLUE}${BOLD}🤖 Misi 'Hunter-Killer' Dimulai... Target: Free Shopping.${NC}"
sleep 1

# --- LANGKAH 1: MENCARI JEJAK AWAL (RESOURCE NAME) ---
report $YELLOW "Mencari jejak teks '$CLUE_STRING' di kamus (strings.xml)..."
STRING_XML_PATH="$PROJECT_DIR/res/values/strings.xml"
if [ ! -f "$STRING_XML_PATH" ]; then
    report $RED "GAGAL! File '$STRING_XML_PATH' tidak ditemukan."
    exit 1
fi
# grep untuk baris yg mengandung clue, sed untuk mengekstrak nama resource-nya
RESOURCE_NAME=$(grep "$CLUE_STRING" "$STRING_XML_PATH" | sed -n 's/.*name="\([^"]*\)".*/\1/p')
if [ -z "$RESOURCE_NAME" ]; then
    report $RED "GAGAL! Tidak bisa menemukan nama resource untuk '$CLUE_STRING'."
    exit 1
fi
report $GREEN "Jejak ditemukan. Nama Resource: '$RESOURCE_NAME'"

# --- LANGKAH 2: MENCARI ID DIGITAL (RESOURCE ID) ---
report $YELLOW "Melacak Nama Resource ke ID Heksadesimal di public.xml..."
PUBLIC_XML_PATH="$PROJECT_DIR/res/values/public.xml"
if [ ! -f "$PUBLIC_XML_PATH" ]; then
    report $RED "GAGAL! File '$PUBLIC_XML_PATH' tidak ditemukan."
    exit 1
fi
# grep untuk baris yg mengandung nama resource, sed untuk mengekstrak ID-nya
RESOURCE_ID=$(grep "name=\"$RESOURCE_NAME\"" "$PUBLIC_XML_PATH" | sed -n 's/.*id="\([^"]*\)".*/\1/p')
if [ -z "$RESOURCE_ID" ]; then
    report $RED "GAGAL! Tidak bisa menemukan ID Heksadesimal untuk '$RESOURCE_NAME'."
    exit 1
fi
report $GREEN "ID Digital ditemukan: '$RESOURCE_ID'"

# --- LANGKAH 3: MENGENDUS FILE SMALI (TKP) ---
report $YELLOW "Menggunakan ID Digital untuk mengendus TKP di semua file Smali..."
# grep -l akan menampilkan nama filenya saja
TARGET_FILE=$(grep -rl "$RESOURCE_ID" "$PROJECT_DIR/smali*")
if [ -z "$TARGET_FILE" ] || [ $(echo "$TARGET_FILE" | wc -l) -ne 1 ]; then
    report $RED "GAGAL! Ditemukan 0 atau lebih dari 1 file Smali yang cocok. Analisis tidak bisa dilanjutkan."
    exit 1
fi
report $GREEN "TKP ditemukan! File: '$TARGET_FILE'"

# --- LANGKAH 4: MENGANALISIS MUNDUR & MENGUNCI TARGET ---
report $YELLOW "Menganalisis 15 baris ke atas dari TKP untuk mencari biang kerok ('if-')..."
# grep -B 15 -> ambil 15 baris SEBELUM target. lalu di-grep lagi untuk 'if-'
LOGIC_ASLI=$(grep -B 15 "$RESOURCE_ID" "$TARGET_FILE" | grep "if-")
if [ -z "$LOGIC_ASLI" ]; then
    report $RED "GAGAL! Tidak ditemukan logika 'if-' di sekitar TKP. Mungkin struktur kode berubah."
    exit 1
fi
# Bersihkan spasi di awal baris
LOGIC_ASLI=$(echo "$LOGIC_ASLI" | sed 's/^[ \t]*//')
LOGIC_PATCHED="#$LOGIC_ASLI"
report $GREEN "Target dikunci! Logika yang akan dilumpuhkan: '$LOGIC_ASLI'"

# --- LANGKAH 5: EKSEKUSI SENYAP (PATCHING) ---
report $YELLOW "Melumpuhkan target dengan 'sed'..."
# Cek dulu, jangan-jangan sudah pernah dipatch
if grep -q "$LOGIC_PATCHED" "$TARGET_FILE"; then
    report $GREEN "Target sudah dilumpuhkan sebelumnya. Tidak ada tindakan."
    exit 0
else
    sed -i "s/$LOGIC_ASLI/$LOGIC_PATCHED/g" "$TARGET_FILE"
    report $GREEN "Eksekusi berhasil. Target telah dilumpuhkan."
    echo -e "${BLUE}${BOLD}🤖 Misi 'Hunter-Killer' Selesai dengan Sukses!${NC}"
    exit 0
fi
