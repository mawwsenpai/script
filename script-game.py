import os
import sys
import shutil
import subprocess
import time
import importlib.util

# --- Konfigurasi Awal ---
# Pastikan path ini sesuai dengan struktur penyimpanan di perangkatmu
OBB_SOURCE_DIR = "/sdcard/Android/obb/"
OUTPUT_DIR = "/sdcard/MawwScript/obb-modding/"
TEMP_DIR = os.path.join(OUTPUT_DIR, "temp_extraction") # Direktori temp di dalam output
CONFIG_FILE_PATH = "game/config-freefire.py"
OBBTOOL_NAME = "obbtool"
TIMEOUT_DETIK = 300  # Batas waktu 5 menit untuk setiap perintah eksternal

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
                     {Warna.HIJAU}V2.0 - MawwSenpai_{Warna.ENDC}
{Warna.ENDC}
    """
    print(header)

def jalankan_perintah(perintah, pesan_awal, pesan_sukses):
    """
    Menjalankan perintah shell dengan lebih aman (timeout) dan menampilkan status.
    """
    print(f"{Warna.BIRU}[*] {pesan_awal}...{Warna.ENDC}")
    try:
        # PENJELASAN PERUBAHAN: Menambahkan timeout untuk mencegah script hang
        result = subprocess.run(
            perintah,
            shell=isinstance(perintah, str), # Shell=True hanya jika perintah adalah string tunggal
            check=True,
            capture_output=True,
            text=True,
            timeout=TIMEOUT_DETIK
        )
        print(f"{Warna.HIJAU}[✔] {pesan_sukses}{Warna.ENDC}")
        return True
    except FileNotFoundError:
        print(f"{Warna.MERAH}[✖] Perintah tidak ditemukan. Script ini paling cocok di Termux.{Warna.ENDC}")
        return False
    except subprocess.CalledProcessError as e:
        print(f"{Warna.MERAH}[✖] Gagal! Perintah mengembalikan error:{Warna.ENDC}")
        print(f"   {Warna.KUNING}{e.stderr.strip()}{Warna.ENDC}")
        return False
    except subprocess.TimeoutExpired:
        print(f"{Warna.MERAH}[✖] Gagal! Proses memakan waktu terlalu lama (lebih dari {TIMEOUT_DETIK} detik).{Warna.ENDC}")
        return False
    except Exception as e:
        print(f"{Warna.MERAH}[✖] Terjadi error tak terduga: {e}{Warna.ENDC}")
        return False

# --- Fungsi Pengecekan & Instalasi ---
def cek_izin_penyimpanan():
    """
    PENJELASAN PERUBAHAN: Fungsi baru yang sangat penting.
    Mengecek apakah direktori /sdcard ada. Jika tidak, Termux belum dapat izin.
    """
    if not os.path.isdir('/sdcard'):
        print(f"{Warna.MERAH}[✖] Akses ke penyimpanan ditolak!{Warna.ENDC}")
        print(f"{Warna.KUNING}   Jalankan perintah ini dulu di Termux:{Warna.ENDC}")
        print(f"   {Warna.BOLD}termux-setup-storage{Warna.ENDC}")
        print(f"{Warna.KUNING}   Lalu izinkan akses pada popup yang muncul.{Warna.ENDC}")
        return False
    print(f"{Warna.HIJAU}[✔] Akses penyimpanan sudah aman!{Warna.ENDC}")
    return True

def cek_dan_install_kebutuhan():
    """Mengecek dan menginstall semua kebutuhan secara otomatis di Termux."""
    print(f"{Warna.KUNING}--- Mengecek Kebutuhan Script ---{Warna.ENDC}")

    if not cek_izin_penyimpanan():
        return False

    if not os.path.isdir('/data/data/com.termux/files/usr'):
        print(f"{Warna.KUNING}Peringatan: Kamu tidak di Termux. Pastikan '{OBBTOOL_NAME}' sudah terinstall manual.{Warna.ENDC}")
        return shutil.which(OBBTOOL_NAME) is not None

    paket_dasar = ['coreutils', 'gnupg', 'curl']
    semua_aman = True

    if not jalankan_perintah(['pkg', 'update', '-y'], "Memperbarui daftar paket", "Daftar paket sudah fresh"):
        return False

    for pkg in paket_dasar:
        if not shutil.which(pkg):
            if not jalankan_perintah(['pkg', 'install', pkg, '-y'], f"Menginstall {pkg}", f"{pkg} berhasil diinstall"):
                return False
        else:
            print(f"{Warna.HIJAU}[✔] {pkg} sudah ada.{Warna.ENDC}")

    if not shutil.which(OBBTOOL_NAME):
        print(f"{Warna.KUNING}[!] {OBBTOOL_NAME} tidak ditemukan. Memulai instalasi...{Warna.ENDC}")
        repo_script_url = "https://its-pointless.github.io/setup-pointless-repo.sh"
        if (jalankan_perintah(f"curl -LO {repo_script_url}", "Mengunduh script repository", "Script berhasil diunduh") and
            jalankan_perintah("bash setup-pointless-repo.sh", "Menambahkan repository", "Repository berhasil ditambah") and
            jalankan_perintah(['pkg', 'install', OBBTOOL_NAME, '-y'], f"Menginstall {OBBTOOL_NAME}", f"{OBBTOOL_NAME} berhasil diinstall")):
            print(f"{Warna.HIJAU}[✔] {OBBTOOL_NAME} sukses diinstall!{Warna.ENDC}")
        else:
            print(f"{Warna.MERAH}[✖] Gagal menginstall {OBBTOOL_NAME}.{Warna.ENDC}")
            return False
    else:
        print(f"{Warna.HIJAU}[✔] {OBBTOOL_NAME} sudah ada.{Warna.ENDC}")

    print(f"\n{Warna.HIJAU}Semua kebutuhan sudah terpenuhi! Mantap!{Warna.ENDC}")
    time.sleep(2)
    return True

# --- Fungsi Inti Modding ---
def siapkan_lingkungan():
    """Membuat folder dan file konfigurasi yang dibutuhkan jika belum ada."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(CONFIG_FILE_PATH), exist_ok=True)

    if not os.path.exists(CONFIG_FILE_PATH):
        print(f"[*] File config '{CONFIG_FILE_PATH}' belum ada, sedang dibuatkan...")
        with open(CONFIG_FILE_PATH, 'w') as f:
            f.write("# --- Tempat Konfigurasi Mod Kamu ---\n\n")
            f.write('def unlock_skin(path_ekstrak):\n')
            f.write("    # Ganti bagian ini dengan logika mod kamu\n")
            f.write("    # Contoh: mengganti file, mengedit file, dll.\n")
            f.write("    print(f'  -> Menerapkan mod Unlock Skin pada folder: {path_ekstrak}')\n")
            f.write("    # shutil.copy('file_mod.txt', os.path.join(path_ekstrak, 'assets/file_target.txt'))\n")
            f.write("    print('  -> Contoh mod berhasil diterapkan!')\n\n")
            f.write("# Daftarkan semua fungsi mod kamu di sini\n")
            f.write("MODS = {\n")
            f.write("    'Unlock All Skin ✨': unlock_skin,\n")
            f.write("}\n")
        print(f"[*] File config '{CONFIG_FILE_PATH}' berhasil dibuat.")

def pilih_obb():
    print(f"\n{Warna.BIRU}Mencari file .obb di '{OBB_SOURCE_DIR}'...{Warna.ENDC}")
    try:
        # PENJELASAN PERUBAHAN: Mencari di semua subfolder dalam OBB_SOURCE_DIR
        obb_files = []
        for root, _, files in os.walk(OBB_SOURCE_DIR):
            for file in files:
                if file.endswith('.obb'):
                    obb_files.append(os.path.join(root, file))

        if not obb_files:
            print(f"{Warna.MERAH}[✖] Tidak ada file .obb ditemukan di '{OBB_SOURCE_DIR}' atau subfoldernya.{Warna.ENDC}")
            print(f"{Warna.KUNING}   Pastikan game sudah terinstall dan path-nya benar.{Warna.ENDC}")
            return None

        print(f"{Warna.HIJAU}Pilih file OBB yang mau di-mod:{Warna.ENDC}")
        for i, path_file in enumerate(obb_files):
            # Membuat nama relatif agar lebih pendek dan rapi
            nama_relatif = os.path.relpath(path_file, OBB_SOURCE_DIR)
            print(f"  {Warna.KUNING}[{i+1}]{Warna.ENDC} {nama_relatif}")

        while True:
            try:
                pilihan = int(input(f"\n{Warna.BIRU}Masukkan nomor: {Warna.ENDC}"))
                if 1 <= pilihan <= len(obb_files):
                    return obb_files[pilihan-1]
                else:
                    print(f"{Warna.MERAH}Pilihan tidak valid! Masukkan nomor antara 1 dan {len(obb_files)}.{Warna.ENDC}")
            except ValueError:
                print(f"{Warna.MERAH}Input harus berupa angka!{Warna.ENDC}")

    except FileNotFoundError:
        print(f"{Warna.MERAH}[✖] Direktori '{OBB_SOURCE_DIR}' tidak ditemukan!{Warna.ENDC}")
        print(f"{Warna.KUNING}   Cek kembali variabel OBB_SOURCE_DIR di atas.{Warna.ENDC}")
        return None

def ekstrak_obb(file_obb):
    print(f"\n{Warna.BIRU}Mempersiapkan ekstraksi...{Warna.ENDC}")
    if os.path.exists(TEMP_DIR):
        print(f"[*] Membersihkan folder temporer lama...")
        shutil.rmtree(TEMP_DIR)
    os.makedirs(TEMP_DIR)

    print(f"{Warna.HIJAU}Mengekstrak '{os.path.basename(file_obb)}' ke '{TEMP_DIR}'{Warna.ENDC}")
    perintah = [OBBTOOL_NAME, 'x', '-o', TEMP_DIR, file_obb]
    return jalankan_perintah(perintah, "Proses ekstraksi sedang berjalan", "Ekstraksi berhasil!")

def terapkan_mod(config_mods):
    mods = config_mods.get('MODS')
    if not mods:
        print(f"{Warna.MERAH}[✖] Tidak ada mod yang terdaftar di 'MODS' dalam file '{CONFIG_FILE_PATH}'!{Warna.ENDC}")
        return False

    print(f"\n{Warna.HIJAU}Pilih modifikasi yang ingin diterapkan:{Warna.ENDC}")
    mod_list = list(mods.items())
    for i, (nama_mod, _) in enumerate(mod_list):
        print(f"  {Warna.KUNING}[{i+1}]{Warna.ENDC} {nama_mod}")
    print(f"  {Warna.KUNING}[0]{Warna.ENDC} Kembali")

    while True:
        try:
            pilihan = int(input(f"\n{Warna.BIRU}Masukkan pilihan mod: {Warna.ENDC}"))
            if 0 <= pilihan <= len(mod_list):
                if pilihan == 0: return False
                nama_terpilih, fungsi_mod = mod_list[pilihan-1]
                print(f"\n{Warna.BIRU}Menerapkan '{nama_terpilih}'...{Warna.ENDC}")
                fungsi_mod(TEMP_DIR)
                print(f"{Warna.HIJAU}[✔] Mod '{nama_terpilih}' selesai diterapkan.{Warna.ENDC}")
                return True
            else:
                print(f"{Warna.MERAH}Pilihan tidak valid!{Warna.ENDC}")
        except ValueError:
            print(f"{Warna.MERAH}Input harus berupa angka!{Warna.ENDC}")
        except Exception as e:
            print(f"{Warna.MERAH}[✖] Terjadi error saat menerapkan mod: {e}{Warna.ENDC}")
            return False

def kemas_ulang_obb(nama_original):
    nama_baru = f"modded-{os.path.basename(nama_original)}"
    path_output_penuh = os.path.join(OUTPUT_DIR, nama_baru)

    print(f"\n{Warna.BIRU}Mengemas ulang file dari '{TEMP_DIR}'...{Warna.ENDC}")
    print(f"{Warna.HIJAU}Output akan disimpan sebagai: '{path_output_penuh}'{Warna.ENDC}")

    perintah = [OBBTOOL_NAME, 'c', '-o', path_output_penuh, TEMP_DIR]

    if jalankan_perintah(perintah, "Proses pengemasan berjalan", f"BERHASIL! OBB tersimpan di {OUTPUT_DIR}"):
        shutil.rmtree(TEMP_DIR)
        print(f"[*] Folder temporer '{TEMP_DIR}' telah dibersihkan.")
        return True
    return False

# --- Menu Utama ---
def menu_modding():
    obb_terpilih = None
    sudah_diekstrak = False

    # PENJELASAN PERUBAHAN: Konfigurasi mod di-load sekali saja saat masuk menu ini.
    try:
        spec = importlib.util.spec_from_file_location("config_mod", CONFIG_FILE_PATH)
        config_mods = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(config_mods)
        config_mods_vars = vars(config_mods)
    except FileNotFoundError:
        print(f"{Warna.MERAH}[✖] File Konfigurasi '{CONFIG_FILE_PATH}' tidak ditemukan!{Warna.ENDC}")
        return
    except Exception as e:
        print(f"{Warna.MERAH}[✖] Gagal memuat file konfigurasi mod: {e}{Warna.ENDC}")
        return

    while True:
        bersihkan_layar()
        tampilkan_header()
        print(f"{Warna.KUNING}--- Menu Modding ---{Warna.ENDC}")
        status_obb = os.path.basename(obb_terpilih) if obb_terpilih else f"{Warna.MERAH}Belum dipilih{Warna.ENDC}"
        status_ekstrak = f"{Warna.HIJAU}Siap dimodifikasi{Warna.ENDC}" if sudah_diekstrak else f"{Warna.MERAH}Belum diekstrak{Warna.ENDC}"
        print(f"[*] OBB Target : {status_obb}")
        print(f"[*] Status     : {status_ekstrak}\n")

        print(f"  {Warna.KUNING}[1]{Warna.ENDC} Bongkar OBB (Pilih & Ekstrak)")
        if sudah_diekstrak:
            print(f"  {Warna.KUNING}[2]{Warna.ENDC} Edit OBB (Terapkan Mod)")
            print(f"  {Warna.KUNING}[3]{Warna.ENDC} Kemas Ulang OBB")
        print(f"  {Warna.KUNING}[0]{Warna.ENDC} Kembali ke Menu Utama")

        pilihan = input(f"\n{Warna.BIRU}Pilihanmu: {Warna.ENDC}")

        if pilihan == '1':
            file_pilihan = pilih_obb()
            if file_pilihan:
                if ekstrak_obb(file_pilihan):
                    obb_terpilih, sudah_diekstrak = file_pilihan, True
                else:
                    print(f"{Warna.MERAH}Gagal mengekstrak, coba lagi.{Warna.ENDC}")
            input("\nTekan Enter untuk melanjutkan...")
        elif pilihan == '2' and sudah_diekstrak:
            terapkan_mod(config_mods_vars)
            input("\nTekan Enter untuk melanjutkan...")
        elif pilihan == '3' and sudah_diekstrak:
            if kemas_ulang_obb(obb_terpilih):
                obb_terpilih, sudah_diekstrak = None, False # Reset status setelah berhasil
            input("\nTekan Enter untuk melanjutkan...")
        elif pilihan == '0':
            if sudah_diekstrak:
                print(f"{Warna.KUNING}Peringatan: Ada file yang sudah diekstrak tapi belum dikemas ulang.{Warna.ENDC}")
                if input("Yakin mau keluar? (y/n): ").lower() != 'y':
                    continue
                shutil.rmtree(TEMP_DIR) # Bersihkan temp jika user tetap keluar
            return
        else:
            print(f"{Warna.MERAH}Pilihan tidak ada di menu!{Warna.ENDC}")
            time.sleep(1)

def main():
    bersihkan_layar()
    tampilkan_header()

    if not cek_dan_install_kebutuhan():
        sys.exit(f"\n{Warna.MERAH}Gagal menyiapkan kebutuhan script. Program berhenti.{Warna.ENDC}")

    siapkan_lingkungan()

    while True:
        bersihkan_layar()
        tampilkan_header()
        print(f"{Warna.HIJAU}Selamat datang! Semua kebutuhan sudah siap.{Warna.ENDC}\n")
        print(f"  {Warna.KUNING}[1]{Warna.ENDC} Mulai Modding")
        print(f"  {Warna.KUNING}[2]{Warna.ENDC} Keluar")

        pilihan = input(f"\n{Warna.BIRU}Pilihan: {Warna.ENDC}")
        if pilihan == '1':
            menu_modding()
        elif pilihan == '2':
            break
        else:
            print(f"{Warna.MERAH}Pilihan tidak ada di menu!{Warna.ENDC}")
            time.sleep(1)
            
    print(f"\n{Warna.KUNING}Terima kasih telah menggunakan MawwScript! Sampai jumpa!{Warna.ENDC}")
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        # PENJELASAN PERUBAHAN: Cek dan bersihkan folder temp jika ada saat keluar paksa
        if os.path.exists(TEMP_DIR):
            shutil.rmtree(TEMP_DIR)
        print(f"\n\n{Warna.MERAH}Program dihentikan paksa. Folder temp dibersihkan. Bye!{Warna.ENDC}")
        sys.exit(1)

