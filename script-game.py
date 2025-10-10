import os
import sys
import shutil
import subprocess
import time
import importlib.util

# --- Konfigurasi Awal ---
# Kamu bisa ubah path ini jika perlu
OBB_SOURCE_DIR = "/sdcard/Android/obb/"
OUTPUT_DIR = "MawwScript/obb-modding/"
TEMP_DIR = "temp_extraction/"
CONFIG_FILE_PATH = "game/config-freefire.py"
OBBTOOL_NAME = "obbtool"

# --- Kode Warna Biar Kece ---
class Warna:
    HEADER = '\033[95m'
    BIRU = '\033[94m'
    HIJAU = '\033[92m'
    KUNING = '\033[93m'
    MERAH = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

# --- Fungsi Bantuan ---
def bersihkan_layar():
    """Membersihkan layar terminal."""
    os.system('cls' if os.name == 'nt' else 'clear')

def tampilkan_header():
    """Menampilkan header script yang estetik."""
    header = f"""
{Warna.BOLD}{Warna.BIRU}
    __  ___  __  __  __  __  __  __  ____  ____ 
   (  )/ __)(  \/  )(  )(  )(  \/  )(_  _)(_  _)
    )( \__ \ )    (  )(__)(  )    (  _)(_  _)(_ 
   (__)(___/(_/\/\_)(______)(_/\/\_)(____)(____)
                     {Warna.HIJAU}V1 - For My Dear User{Warna.ENDC}
{Warna.ENDC}
    """
    print(header)

def cek_kebutuhan():
    """Mengecek apakah obbtool terinstall."""
    return shutil.which(OBBTOOL_NAME) is not None

def tampilkan_status():
    """Menampilkan status file/tool yang dibutuhkan."""
    print(f"{Warna.KUNING}--- Status Kebutuhan ---{Warna.ENDC}")
    status_obbtool = f"{Warna.HIJAU}Tersedia{Warna.ENDC}" if cek_kebutuhan() else f"{Warna.MERAH}Tidak Ditemukan{Warna.ENDC}"
    print(f"[*] {OBBTOOL_NAME}: {status_obbtool}")
    
    # Cek folder-folder penting
    for folder in [OUTPUT_DIR, TEMP_DIR, os.path.dirname(CONFIG_FILE_PATH)]:
        if not os.path.exists(folder):
            os.makedirs(folder)
            print(f"[*] Folder '{folder}' dibuat.")
            
    # Cek file config
    if not os.path.exists(CONFIG_FILE_PATH):
        # Buat file config default jika tidak ada
        with open(CONFIG_FILE_PATH, 'w') as f:
            f.write("# --- Tempat Konfigurasi Mod Kamu ---\n\n")
            f.write("# Contoh:\n")
            f.write("def unlock_skin(path_ekstrak):\n")
            f.write("    print(f'  -> Menerapkan mod Unlock Skin di: {path_ekstrak}')\n")
            f.write("    # Di sini kamu tulis logika untuk modifikasi filenya\n")
            f.write("    # Misal: membuat file dummy\n")
            f.write("    with open(os.path.join(path_ekstrak, 'skin_unlocked.txt'), 'w') as dummy_file:\n")
            f.write("        dummy_file.write('all skins are unlocked by MawwScript')\n")
            f.write("    print('  -> Mod Unlock Skin Selesai!')\n\n")
            f.write("MODS = {\n")
            f.write("    'Unlock All Skin ✨': unlock_skin,\n")
            f.write("    # Tambahkan mod lain di sini\n")
            f.write("}\n")
        print(f"[*] File '{CONFIG_FILE_PATH}' dibuatkan.")

    print(f"{Warna.KUNING}------------------------{Warna.ENDC}\n")

# --- Fungsi Inti ---

def pilih_obb():
    """Memilih file OBB dari direktori sumber."""
    print(f"{Warna.BIRU}Mencari file .obb di '{OBB_SOURCE_DIR}'...{Warna.ENDC}")
    try:
        files_obb = [f for f in os.listdir(OBB_SOURCE_DIR) if f.endswith('.obb')]
        if not files_obb:
            print(f"{Warna.MERAH}Tidak ada file .obb ditemukan! Pastikan path benar.{Warna.ENDC}")
            return None
        
        print(f"{Warna.HIJAU}Pilih file OBB yang mau di-mod:{Warna.ENDC}")
        for i, nama_file in enumerate(files_obb):
            print(f"  {Warna.KUNING}[{i+1}]{Warna.ENDC} {nama_file}")
        
        while True:
            try:
                pilihan = int(input(f"\n{Warna.BIRU}Masukkan nomor: {Warna.ENDC}"))
                if 1 <= pilihan <= len(files_obb):
                    return os.path.join(OBB_SOURCE_DIR, files_obb[pilihan-1])
                else:
                    print(f"{Warna.MERAH}Pilihan tidak valid!{Warna.ENDC}")
            except ValueError:
                print(f"{Warna.MERAH}Input harus berupa angka!{Warna.ENDC}")
    except FileNotFoundError:
        print(f"{Warna.MERAH}Direktori '{OBB_SOURCE_DIR}' tidak ditemukan!{Warna.ENDC}")
        return None

def ekstrak_obb(file_obb):
    """Mengekstrak OBB ke folder temporer."""
    print(f"\n{Warna.BIRU}Mempersiapkan ekstraksi...{Warna.ENDC}")
    if os.path.exists(TEMP_DIR):
        shutil.rmtree(TEMP_DIR)
        print(f"[*] Membersihkan folder temporer lama.")
    os.makedirs(TEMP_DIR)
    
    print(f"{Warna.HIJAU}Mengekstrak '{os.path.basename(file_obb)}' ke '{TEMP_DIR}'...{Warna.ENDC}")
    perintah = [OBBTOOL_NAME, 'x', '-o', TEMP_DIR, file_obb]
    
    try:
        subprocess.run(perintah, check=True, capture_output=True, text=True)
        print(f"{Warna.HIJAU}Ekstraksi berhasil!{Warna.ENDC}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"{Warna.MERAH}Gagal mengekstrak OBB!{Warna.ENDC}")
        print(f"Error: {e.stderr}")
        return False
    except FileNotFoundError:
        print(f"{Warna.MERAH}Perintah '{OBBTOOL_NAME}' tidak ditemukan. Pastikan sudah terinstall.{Warna.ENDC}")
        return False

def terapkan_mod(config_mods):
    """Menampilkan menu dan menerapkan mod yang dipilih."""
    if not config_mods or not config_mods.get('MODS'):
        print(f"{Warna.MERAH}Tidak ada mod yang dikonfigurasi di '{CONFIG_FILE_PATH}'!{Warna.ENDC}")
        return

    mods = config_mods['MODS']
    print(f"\n{Warna.HIJAU}Pilih modifikasi yang ingin diterapkan:{Warna.ENDC}")
    
    mod_list = list(mods.items())
    for i, (nama_mod, _) in enumerate(mod_list):
        print(f"  {Warna.KUNING}[{i+1}]{Warna.ENDC} {nama_mod}")
    print(f"  {Warna.KUNING}[0]{Warna.ENDC} Kembali")

    while True:
        try:
            pilihan = int(input(f"\n{Warna.BIRU}Masukkan pilihan mod: {Warna.ENDC}"))
            if 0 <= pilihan <= len(mod_list):
                if pilihan == 0:
                    return
                nama_terpilih, fungsi_mod = mod_list[pilihan-1]
                print(f"\n{Warna.BIRU}Menerapkan '{nama_terpilih}'...{Warna.ENDC}")
                fungsi_mod(TEMP_DIR) # Memanggil fungsi mod dari file config
                return
            else:
                print(f"{Warna.MERAH}Pilihan tidak valid!{Warna.ENDC}")
        except ValueError:
            print(f"{Warna.MERAH}Input harus berupa angka!{Warna.ENDC}")

def kemas_ulang_obb(nama_original):
    """Mengemas ulang file dari folder temporer menjadi OBB baru."""
    nama_baru = f"modded-{os.path.basename(nama_original)}"
    path_output_penuh = os.path.join(OUTPUT_DIR, nama_baru)
    
    print(f"\n{Warna.BIRU}Mengemas ulang file dari '{TEMP_DIR}'...{Warna.ENDC}")
    print(f"{Warna.HIJAU}Output akan disimpan sebagai: '{path_output_penuh}'{Warna.ENDC}")
    
    perintah = [OBBTOOL_NAME, 'c', '-o', path_output_penuh, TEMP_DIR]
    
    try:
        subprocess.run(perintah, check=True, capture_output=True, text=True)
        print(f"\n{Warna.HIJAU}{Warna.BOLD}BERHASIL!{Warna.ENDC}{Warna.HIJAU} OBB yang sudah dimodifikasi tersimpan!{Warna.ENDC}")
        shutil.rmtree(TEMP_DIR)
        print(f"[*] Folder temporer '{TEMP_DIR}' telah dibersihkan.")
        return True
    except subprocess.CalledProcessError as e:
        print(f"{Warna.MERAH}Gagal mengemas ulang OBB!{Warna.ENDC}")
        print(f"Error: {e.stderr}")
        return False
    except FileNotFoundError:
        print(f"{Warna.MERAH}Perintah '{OBBTOOL_NAME}' tidak ditemukan.{Warna.ENDC}")
        return False


# --- Menu Navigasi ---

def menu_install():
    """Menu yang tampil jika kebutuhan tidak terpenuhi."""
    while True:
        bersihkan_layar()
        tampilkan_header()
        tampilkan_status()
        print(f"{Warna.MERAH}{Warna.BOLD}Peringatan: `obbtool` tidak ditemukan!{Warna.ENDC}")
        print("Script ini membutuhkan `obbtool` untuk bekerja.")
        print("Silakan install terlebih dahulu. Contoh di Termux:")
        print(f"  {Warna.KUNING}$ pkg install obbtool{Warna.ENDC}")
        print("\n" + "="*40)
        print(f"  {Warna.KUNING}[1]{Warna.ENDC} Coba cek lagi")
        print(f"  {Warna.KUNING}[2]{Warna.ENDC} Keluar")
        pilihan = input(f"\n{Warna.BIRU}Pilihan: {Warna.ENDC}")
        if pilihan == '1':
            if cek_kebutuhan():
                print(f"{Warna.HIJAU}Oke, `obbtool` sudah ditemukan! Memulai ulang...{Warna.ENDC}")
                time.sleep(2)
                return
        elif pilihan == '2':
            sys.exit(0)

def menu_config():
    """Menu utama setelah semua kebutuhan terpenuhi."""
    obb_terpilih = None
    sudah_diekstrak = False

    # Load module config secara dinamis
    spec = importlib.util.spec_from_file_location("config_mod", CONFIG_FILE_PATH)
    config_mods = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(config_mods)

    while True:
        bersihkan_layar()
        tampilkan_header()
        print(f"{Warna.KUNING}--- Config & Modding Menu ---{Warna.ENDC}")
        status_obb = os.path.basename(obb_terpilih) if obb_terpilih else f"{Warna.MERAH}Belum dipilih{Warna.ENDC}"
        status_ekstrak = f"{Warna.HIJAU}Siap dimodifikasi{Warna.ENDC}" if sudah_diekstrak else f"{Warna.MERAH}Belum diekstrak{Warna.ENDC}"
        print(f"[*] OBB Target : {status_obb}")
        print(f"[*] Status     : {status_ekstrak}\n")

        print(f"  {Warna.KUNING}[1]{Warna.ENDC} Pilih & Ekstrak OBB")
        if sudah_diekstrak:
            print(f"  {Warna.KUNING}[2]{Warna.ENDC} Terapkan Modifikasi")
            print(f"  {Warna.KUNING}[3]{Warna.ENDC} Kemas Ulang OBB")
        print(f"  {Warna.KUNING}[0]{Warna.ENDC} Keluar ke Menu Utama")

        pilihan = input(f"\n{Warna.BIRU}Pilihan: {Warna.ENDC}")

        if pilihan == '1':
            file_pilihan = pilih_obb()
            if file_pilihan:
                if ekstrak_obb(file_pilihan):
                    obb_terpilih = file_pilihan
                    sudah_diekstrak = True
            input("\nTekan Enter untuk melanjutkan...")
        elif pilihan == '2' and sudah_diekstrak:
            terapkan_mod(vars(config_mods))
            input("\nTekan Enter untuk melanjutkan...")
        elif pilihan == '3' and sudah_diekstrak:
            if kemas_ulang_obb(obb_terpilih):
                obb_terpilih = None
                sudah_diekstrak = False
            input("\nTekan Enter untuk melanjutkan...")
        elif pilihan == '0':
            return
        else:
            print(f"{Warna.MERAH}Pilihan tidak valid!{Warna.ENDC}")
            time.sleep(1)


def main():
    """Fungsi utama untuk menjalankan script."""
    if not cek_kebutuhan():
        menu_install()

    while True:
        bersihkan_layar()
        tampilkan_header()
        tampilkan_status()
        print(f"{Warna.HIJAU}Semua kebutuhan terpenuhi. Selamat datang!{Warna.ENDC}\n")
        print(f"  {Warna.KUNING}[1]{Warna.ENDC} Config & Modding")
        print(f"  {Warna.KUNING}[2]{Warna.ENDC} Keluar")
        
        pilihan = input(f"\n{Warna.BIRU}Pilihan: {Warna.ENDC}")
        if pilihan == '1':
            menu_config()
        elif pilihan == '2':
            print(f"{Warna.KUNING}Terima kasih telah menggunakan MawwScript V1! Sampai jumpa!{Warna.ENDC}")
            sys.exit(0)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Warna.MERAH}Program dihentikan oleh pengguna. Bye!{Warna.ENDC}")
        sys.exit(0)

