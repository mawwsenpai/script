PROJECT_DIR=$1
TARGET_FILE="$PROJECT_DIR/smali_classes2/H4/a.smali"

# Logika yang kita cari di file yang belum di-mod
LOGIC_ASLI='if-nez v0, :label_not_enough_coins'

# Logika yang seharusnya ada setelah file berhasil di-mod
LOGIC_PATCHED='#if-nez v0, :label_not_enough_coins'

# --- [2] FASE ANALISIS ---
echo -e "\n\033[0;33m🔬 [Patcher] Menganalisis file target: $(basename $TARGET_FILE)...\033[0m"
sleep 1

# Cek dulu file targetnya ada atau enggak
if [ ! -f "$TARGET_FILE" ]; then
    echo -e "\033[0;31m❌ [Patcher] GAGAL! File target '$TARGET_FILE' tidak ditemukan.\033[0m"
    exit 1 # Keluar dengan status error
fi

# Cek apakah file SUDAH pernah di-patch sebelumnya
# Opsi -q (quiet) membuat grep tidak menampilkan output, hanya mengembalikan status
if grep -q "$LOGIC_PATCHED" "$TARGET_FILE"; then
    echo -e "\033[0;32m✅ [Patcher] File ini sepertinya SUDAH pernah di-patch sebelumnya. Tidak ada tindakan yang diperlukan.\033[0m"
    exit 0 # Keluar dengan status sukses

# JIKA BELUM, cek apakah logika aslinya ada dan siap untuk di-patch
elif grep -q "$LOGIC_ASLI" "$TARGET_FILE"; then
    echo -e "\033[0;32m✅ [Patcher] Logika target ditemukan. Siap untuk menyuntikkan patch...\033[0m"
    
    # --- [3] FASE EKSEKUSI ---
    sed -i "s/$LOGIC_ASLI/$LOGIC_PATCHED/g" "$TARGET_FILE"
    
    # Cek ulang untuk memastikan sed berhasil
    if grep -q "$LOGIC_PATCHED" "$TARGET_FILE"; then
        echo -e "\033[0;32m💉 [Patcher] Suntikan berhasil! Logika pengecekan koin telah dilumpuhkan.\033[0m"
        exit 0 # Keluar dengan status sukses
    else
        echo -e "\033[0;31m❌ [Patcher] GAGAL! Perintah 'sed' gagal mengubah file.${NC}"
        exit 1 # Keluar dengan status error
    fi

# JIKA TIDAK ADA KEDUANYA, berarti game sudah berubah total
else
    echo -e "\033[0;31m🔥 [Patcher] PERINGATAN KRITIS! 🔥${NC}"
    echo -e "\033[0;31mLogika target ('$LOGIC_ASLI') TIDAK DITEMUKAN di dalam file.${NC}"
    echo -e "\033[0;33mKemungkinan besar game Pou sudah di-update dan developernya mengubah struktur kodenya.${NC}"
    echo -e "\033[0;33mPatcher ini tidak bisa dilanjutkan. Anda perlu melakukan investigasi ulang.${NC}"
    exit 1 # Keluar dengan status error
fi
