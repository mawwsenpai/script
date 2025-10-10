import os
import sys
import shutil
import subprocess
import time
import importlib.util

# --- Konfigurasi Awal ---
OBB_SOURCE_DIR = "/sdcard/Android/obb/"
OUTPUT_DIR = "/sdcard/MawwScript/obb-modding/" # <-- DIUBAH ke /sdcard/
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
    os.system('cls' if os.name == 'nt' else 'clear')

def tampilkan_header():
    header = f"""
{Warna.BOLD}{Warna.BIRU}
    __  ___  __  __  __  __  __  __  ____  ____ 
   (  )/ __)(  \/  )(  )(  )(  \/  )(_  _)(_  _)
    )( \__ \ )    (  )(__)(  )    (  _)(_  _)(_ 
   (__)(___/(_/\/\_)(______)(_/\/\_)(____)(____)
                     {Warna.HIJAU}V1.5 - Auto Installer{Warna.ENDC}
{Warna.ENDC}
    """
    print(header)

# --- FUNGSI BARU UNTUK INSTALASI OTOMATIS ---
def jalankan_perintah(perintah, pesan_awal, pesan_sukses):
    """Menjalankan perintah shell dan menampilkan status."""
    print(f"{Warna.BIRU}[*] {pesan_awal}...{Warna.ENDC}")
    try:
        # Menggunakan shell=True untuk perintah kompleks seperti curl | bash
        if isinstance(perintah, str):
            result = subprocess.run(perintah, shell=True, check=True, capture_output=True, text=True)
        else:
            result = subprocess.run(perintah, check=True, capture_output=True, text=True)
        print(f"{Warna.HIJAU}[✔] {pesan_sukses}{Warna.ENDC}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"{Warna.MERAH}[✖] Gagal! Error: {e.stderr.strip()}{Warna.ENDC}")
        return False
    except FileNotFoundError:
        print(f"{Warna.MERAH}[✖] Perintah tidak ditemukan. Pastikan kamu di Termux.{Warna.ENDC}")
        return False

def cek_dan_install_kebutuhan():
    """Mengecek dan menginstall semua kebutuhan secara otomatis di Termux."""
    print(f"{Warna.KUNING}--- Mengecek Kebutuhan Script ---{Warna.ENDC}")
    
    # Cek apakah ini Termux
    if not os.path.isdir('/data/data/com.termux/files/usr'):
        print(f"{Warna.MERAH}Peringatan: Instalasi otomatis hanya didukung di Termux.{Warna.ENDC}")
        # Cek manual untuk obbtool jika bukan termux
        if shutil.which(OBBTOOL_NAME):
            print(f"{Warna.HIJAU}[✔] {OBBTOOL_NAME} sudah terinstall.{Warna.ENDC}")
            return True
        else:
            print(f"{Warna.MERAH}[✖] {OBBTOOL_NAME} tidak ditemukan. Silakan install manual.{Warna.ENDC}")
            return False

    # Jika di Termux, lanjutkan pengecekan otomatis
    paket_dasar = ['coreutils', 'gnupg', 'curl']
    semua_aman = True

    # Update daftar paket dulu
    if not jalankan_perintah(['pkg', 'update', '-y'], "Memperbarui daftar paket", "Daftar paket sudah fresh"):
        return False

    for pkg in paket_dasar:
        if not shutil.which(pkg):
            if not jalankan_perintah(['pkg', 'install', pkg, '-y'], f"Menginstall {pkg}", f"{pkg} berhasil diinstall"):
                semua_aman = False
                break
        else:
            print(f"{Warna.HIJAU}[✔] {pkg} sudah terinstall.{Warna.ENDC}")
    
    if not semua_aman:
        return False

    # Pengecekan khusus untuk obbtool
    if not shutil.which(OBBTOOL_NAME):
        print(f"{Warna.KUNING}[!] {OBBTOOL_NAME} tidak ditemukan. Memulai instalasi...{Warna.ENDC}")
        
        repo_script = "setup-pointless-repo.sh"
        perintah_curl = f"curl -LO https://its-pointless.github.io/{repo_script}"
        perintah_bash = f"bash {repo_script}"

        if (jalankan_perintah(perintah_curl, "Mengunduh script repository", "Script repository berhasil diunduh") and
            jalankan_perintah(perintah_bash, "Menambahkan repository its-pointless", "Repository berhasil ditambahkan") and
            jalankan_perintah(['pkg', 'update', '-y'], "Memperbarui daftar paket lagi", "Daftar paket berhasil diupdate") and
            jalankan_perintah(['pkg', 'install', OBBTOOL_NAME, '-y'], f"Menginstall {OBBTOOL_NAME}", f"{OBBTOOL_NAME} berhasil diinstall")):
            
            # Verifikasi sekali lagi
            if not shutil.which(OBBTOOL_NAME):
                print(f"{Warna.MERAH}[✖] Instalasi {OBBTOOL_NAME} gagal meski proses berjalan.{Warna.ENDC}")
                return False
        else:
            print(f"{Warna.MERAH}[✖] Gagal dalam proses instalasi {OBBTOOL_NAME}.{Warna.ENDC}")
            return False
    else:
        print(f"{Warna.HIJAU}[✔] {OBBTOOL_NAME} sudah terinstall.{Warna.ENDC}")

    print(f"\n{Warna.HIJAU}Semua kebutuhan sudah terpenuhi! Mantap!{Warna.ENDC}")
    time.sleep(2)
    return True

# --- Sisa scriptnya sama seperti sebelumnya ---
# (Tidak perlu diubah, tapi saya sertakan lagi biar lengkap)

def tampilkan_status():
    """Menampilkan status file/tool yang dibutuhkan."""
    print(f"{Warna.KUNING}--- Status Awal ---{Warna.ENDC}")
    status_obbtool = f"{Warna.HIJAU}Tersedia{Warna.ENDC}"
    print(f"[*] {OBBTOOL_NAME}: {status_obbtool}")
    
    for folder in [os.path.dirname(OUTPUT_DIR), os.path.dirname(CONFIG_FILE_PATH)]:
        if not os.path.exists(folder):
            os.makedirs(folder)
            
    if not os.path.exists(CONFIG_FILE_PATH):
        with open(CONFIG_FILE_PATH, 'w') as f:
            f.write("# --- Tempat Konfigurasi Mod Kamu ---\n\n")
            f.write("def unlock_skin(path_ekstrak):\n")
            f.write("    print('  -> Menerapkan mod Unlock Skin...')\n")
            f.write("MODS = {'Unlock All Skin ✨': unlock_skin}\n")
        print(f"[*] File config '{CONFIG_FILE_PATH}' dibuatkan.")

    print(f"{Warna.KUNING}------------------{Warna.ENDC}\n")

def pilih_obb():
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
    print(f"\n{Warna.BIRU}Mempersiapkan ekstraksi...{Warna.ENDC}")
    if os.path.exists(TEMP_DIR):
        shutil.rmtree(TEMP_DIR)
    os.makedirs(TEMP_DIR)
    
    print(f"{Warna.HIJAU}Mengekstrak '{os.path.basename(file_obb)}' ke '{TEMP_DIR}'...{Warna.ENDC}")
    perintah = [OBBTOOL_NAME, 'x', '-o', TEMP_DIR, file_obb]
    
    return jalankan_perintah(perintah, "Proses ekstraksi", "Ekstraksi berhasil!")

def terapkan_mod(config_mods):
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
                if pilihan == 0: return
                nama_terpilih, fungsi_mod = mod_list[pilihan-1]
                print(f"\n{Warna.BIRU}Menerapkan '{nama_terpilih}'...{Warna.ENDC}")
                fungsi_mod(TEMP_DIR)
                return
            else:
                print(f"{Warna.MERAH}Pilihan tidak valid!{Warna.ENDC}")
        except ValueError:
            print(f"{Warna.MERAH}Input harus berupa angka!{Warna.ENDC}")

def kemas_ulang_obb(nama_original):
    nama_baru = f"modded-{os.path.basename(nama_original)}"
    path_output_penuh = os.path.join(OUTPUT_DIR, nama_baru)
    
    print(f"\n{Warna.BIRU}Mengemas ulang file dari '{TEMP_DIR}'...{Warna.ENDC}")
    print(f"{Warna.HIJAU}Output akan disimpan sebagai: '{path_output_penuh}'{Warna.ENDC}")
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    perintah = [OBBTOOL_NAME, 'c', '-o', path_output_penuh, TEMP_DIR]
    
    if jalankan_perintah(perintah, "Proses pengemasan", f"BERHASIL! OBB tersimpan di {OUTPUT_DIR}"):
        shutil.rmtree(TEMP_DIR)
        print(f"[*] Folder temporer '{TEMP_DIR}' telah dibersihkan.")
        return True
    return False

def menu_config():
    obb_terpilih = None
    sudah_diekstrak = False

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
        print(f"  {Warna.KUNING}[0]{Warna.ENDC} Keluar")

        pilihan = input(f"\n{Warna.BIRU}Pilihan: {Warna.ENDC}")

        if pilihan == '1':
            file_pilihan = pilih_obb()
            if file_pilihan and ekstrak_obb(file_pilihan):
                obb_terpilih, sudah_diekstrak = file_pilihan, True
            input("\nTekan Enter untuk melanjutkan...")
        elif pilihan == '2' and sudah_diekstrak:
            terapkan_mod(vars(config_mods))
            input("\nTekan Enter untuk melanjutkan...")
        elif pilihan == '3' and sudah_diekstrak:
            if kemas_ulang_obb(obb_terpilih):
                obb_terpilih, sudah_diekstrak = None, False
            input("\nTekan Enter untuk melanjutkan...")
        elif pilihan == '0':
            return

def main():
    bersihkan_layar()
    tampilkan_header()
    # --- BAGIAN INI DIUBAH TOTAL ---
    if not cek_dan_install_kebutuhan():
        sys.exit(f"\n{Warna.MERAH}Gagal menyiapkan kebutuhan script. Program berhenti.{Warna.ENDC}")
    
    tampilkan_status()

    while True:
        bersihkan_layar()
        tampilkan_header()
        print(f"{Warna.HIJAU}Selamat datang! Semua kebutuhan siap.{Warna.ENDC}\n")
        print(f"  {Warna.KUNING}[1]{Warna.ENDC} Mulai Modding")
        print(f"  {Warna.KUNING}[2]{Warna.ENDC} Keluar")
        
        pilihan = input(f"\n{Warna.BIRU}Pilihan: {Warna.ENDC}")
        if pilihan == '1':
            menu_config()
        elif pilihan == '2':
            print(f"{Warna.KUNING}Terima kasih telah menggunakan MawwScript! Sampai jumpa!{Warna.ENDC}")
            sys.exit(0)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Warna.MERAH}Program dihentikan oleh pengguna. Bye!{Warna.ENDC}")
        sys.exit(0)
