# --- Tempat Konfigurasi Mod Kamu ---
import os

# Setiap fungsi mod harus menerima satu argumen: path_ekstrak
# 'path_ekstrak' adalah lokasi folder temporer tempat file OBB diekstrak.

def unlock_skin(path_ekstrak):
    """
    CONTOH FUNGSI MOD.
    Tulis logikamu di sini untuk mengubah, menambah, atau menghapus file
    di dalam folder 'path_ekstrak'.
    """
    print(f"  -> {Warna.BIRU}Menerapkan mod 'Unlock All Skin' di dalam folder: {path_ekstrak}{Warna.ENDC}")
    
    # --- TULIS LOGIKA MOD KAMU DI SINI ---
    # Contoh: Membuat file penanda bahwa skin sudah di-unlock.
    # Kamu harus mengganti ini dengan logika mod yang sebenarnya.
    try:
        file_penanda_path = os.path.join(path_ekstrak, 'assets', 'bin', 'data', 'MawwScript_Skin_Unlock.txt')
        
        # Pastikan direktori ada
        os.makedirs(os.path.dirname(file_penanda_path), exist_ok=True)
        
        with open(file_penanda_path, 'w') as f:
            f.write('All skins are unlocked by MawwScript V1. Have fun!')
        
        print(f"  -> {Warna.HIJAU}Sukses! File penanda mod dibuat di: {file_penanda_path}{Warna.ENDC}")
        print(f"  -> {Warna.HIJAU}Mod 'Unlock All Skin' Selesai!{Warna.ENDC}")

    except Exception as e:
        print(f"  -> {Warna.MERAH}Oops, ada error: {e}{Warna.ENDC}")

# --- DAFTAR MOD YANG AKAN TAMPIL DI MENU ---
# Kunci (key) adalah teks yang akan tampil di menu.
# Nilai (value) adalah nama fungsi di atas yang akan dijalankan.
MODS = {
    'Unlock All Skin ✨': unlock_skin,
    # 'Mod Lainnya (Contoh)': fungsi_mod_lainnya,
}


# --- Jangan Hapus Ini ---
# Dibutuhkan agar warna bisa dipakai di sini juga.
class Warna:
    HEADER = '\033[95m'
    BIRU = '\033[94m'
    HIJAU = '\033[92m'
    KUNING = '\033[93m'
    MERAH = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
