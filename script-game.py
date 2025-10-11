# -*- coding: utf-8 -*-

import os
import sys
import shutil
import subprocess
import time
from pathlib import Path

# ==============================================================================
# ||                       KONFIGURASI & EDIT MOD KAMU DI SINI                  ||
# ==============================================================================

# --- Path Dasar ---
# Semua hasil kerja akan disimpan di sini
BASE_DIR = Path("/sdcard/OprekOBB/")

# --- Logika Mod Kamu ---
# Buat fungsi-fungsi mod kamu di bawah ini.
# Setiap fungsi WAJIB menerima satu argumen, yaitu `path_ekstrak`.
# `path_ekstrak` adalah lokasi folder hasil bongkaran OBB.

def mod_unlock_skin(path_ekstrak: Path):
    """
    Contoh fungsi untuk mod skin.
    Logika modding-mu (copy file, ganti file, etc.) taruh di sini.
    """
    print(f"  -> Menjalankan mod 'Unlock All Skin'...")
    try:
        # Contoh: Membuat file penanda di dalam folder assets
        assets_dir = path_ekstrak / "assets"
        assets_dir.mkdir(exist_ok=True) # Buat folder assets kalo belum ada
        
        marker_file = assets_dir / "mod_terpasang.txt"
        marker_file.write_text("Skin Mod by MawwSenpai Was Here!")
        
        print(f"  -> Berhasil membuat file penanda di: {marker_file}")
        print("  -> (Ganti logika di fungsi ini dengan file mod-mu yang sebenarnya)")

    except Exception as e:
        print(f"  -> GAGAL menjalankan mod: {e}")

def mod_hapus_iklan(path_ekstrak: Path):
    """Contoh fungsi untuk menghapus file iklan."""
    print(f"  -> Menjalankan mod 'Hapus Iklan'... ")
    
    # Contoh: Mencari dan menghapus file/folder iklan
    folder_iklan = path_ekstrak / "assets" / "iklan"
    if folder_iklan.exists() and folder_iklan.is_dir():
        shutil.rmtree(folder_iklan)
        print(f"  -> Berhasil menghapus folder: {folder_iklan}")
    else:
        print("  -> Folder iklan tidak ditemukan, mungkin sudah bersih.")

# --- Daftar Mod yang Akan Muncul di Menu ---
# Format: 'Nama Keren di Menu': nama_fungsi_di_atas
MODS = {
    '✨ Unlock All Skin': mod_unlock_skin,
    '🚫 Hapus Iklan Game': mod_hapus_iklan,
}

# ==============================================================================
# ||                          BAGIAN INTI SCRIPT (JANGAN DIUBAH)                ||
# ==============================================================================

# --- Konfigurasi Sistem ---
OBB_SOURCE_DIR = Path("/sdcard/Android/obb/")
OUTPUT_DIR = BASE_DIR / "hasil-mod"
TEMP_DIR = BASE_DIR / "temp_extraction"
TIMEOUT_DETIK = 600  # Batas waktu 10 menit

# --- Kode Warna Biar Kece ---
class Warna:
    MERAH = '\033[91m'
    HIJAU = '\033[92m'
    KUNING = '\033[93m'
    BIRU = '\033[94m'
    HEADER = '\033[95m'
    BOLD = '\033[1m'
    ENDC = '\033[0m'

# --- Fungsi Bantuan ---
def bersihkan_layar():
    os.system('cls' if os.name == 'nt' else 'clear')

def tampilkan_header():
    header = f"""
{Warna.BOLD}{Warna.BIRU}
    ___  ____  ____  _  _  ____  ____  _  _
   / __)(_  _)(_  _)( \/ )(_  _)(_  _)( \/ )
  ( (__  _)(_  _)(_  \  /  _)(_  _)(_  \  /
   \___)(____)(____)  \/  (____)(____)  \/
    {Warna.HIJAU}---==[ Script OBB All-in-One Stabil ]==---{Warna.ENDC}
"""
    print(header)

def jalankan_perintah(perintah, pesan_awal):
    print(f"{Warna.BIRU}[*] {pesan_awal}...{Warna.ENDC}")
    try:
        # Jika perintah adalah string (untuk kasus `cd && zip`), gunakan shell=True
        is_shell = isinstance(perintah, str)
        result = subprocess.run(
            perintah,
            shell=is_shell,
            check=True,
            capture_output=True,
            text=True,
            timeout=TIMEOUT_DETIK
        )
        return True
    except FileNotFoundError:
        cmd = perintah.split()[0] if is_shell else perintah[0]
        print(f"{Warna.MERAH}[✖] Perintah '{cmd}' tidak ditemukan. Script ini butuh Termux!{Warna.ENDC}")
        return False
    except subprocess.CalledProcessError as e:
        print(f"{Warna.MERAH}[✖] Gagal! Perintah mengembalikan error:{Warna.ENDC}")
        print(f"   {Warna.KUNING}{e.stderr.strip()}{Warna.ENDC}")
        return False
    except subprocess.TimeoutExpired:
        print(f"{Warna.MERAH}[✖] Gagal! Proses kelamaan (lebih dari {TIMEOUT_DETIK / 60:.0f} menit).{Warna.ENDC}")
        return False
    except Exception as e:
        print(f"{Warna.MERAH}[✖] Terjadi error tak terduga: {e}{Warna.ENDC}")
        return False

# --- Fungsi Inti ---
def cek_dan_install_kebutuhan():
    """Mengecek dan menginstall semua kebutuhan secara otomatis."""
    print(f"{Warna.KUNING}--- Mengecek Kebutuhan Script ---{Warna.ENDC}")
    
    if not OBB_SOURCE_DIR.parent.exists():
        print(f"{Warna.MERAH}[✖] Akses ke /sdcard ditolak!{Warna.ENDC}")
        print(f"{Warna.KUNING}   => Jalankan perintah ini dulu di Termux: {Warna.BOLD}termux-setup-storage{Warna.ENDC}")
        return False
    print(f"{Warna.HIJAU}[✔] Akses penyimpanan aman.{Warna.ENDC}")

    kebutuhan = ['zip', 'unzip']
    paket_kurang = [pkg for pkg in kebutuhan if not shutil.which(pkg)]

    if paket_kurang:
        print(f"{Warna.KUNING}[!] Paket yang kurang: {', '.join(paket_kurang)}. Mencoba install...{Warna.ENDC}")
        perintah_install = ['pkg', 'install', '-y'] + paket_kurang
        if not jalankan_perintah(perintah_install, f"Menginstall {', '.join(paket_kurang)}"):
            return False
        print(f"{Warna.HIJAU}[✔] Semua kebutuhan berhasil diinstall.{Warna.ENDC}")
    else:
        print(f"{Warna.HIJAU}[✔] Semua kebutuhan (zip, unzip) sudah ada.{Warna.ENDC}")
    
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    return True

def pilih_obb():
    """Memilih file OBB yang akan dioprek."""
    print(f"\n{Warna.HEADER}Mencari file .obb di '{OBB_SOURCE_DIR}'...{Warna.ENDC}")
    try:
        obb_files = sorted(list(OBB_SOURCE_DIR.rglob('*.obb')))
        if not obb_files:
            print(f"{Warna.MERAH}[✖] Tidak ada file .obb ditemukan.{Warna.ENDC}")
            return None

        print(f"{Warna.HIJAU}Pilih file OBB target:{Warna.ENDC}")
        for i, path_file in enumerate(obb_files):
            print(f"  {Warna.KUNING}[{i+1}]{Warna.ENDC} {path_file.relative_to(OBB_SOURCE_DIR)}")
        
        while True:
            try:
                pilihan = int(input(f"\n{Warna.BIRU}Masukkan nomor (0 untuk batal): {Warna.ENDC}"))
                if pilihan == 0: return None
                if 1 <= pilihan <= len(obb_files): return obb_files[pilihan - 1]
                else: print(f"{Warna.MERAH}Nomor tidak valid!{Warna.ENDC}")
            except ValueError: print(f"{Warna.MERAH}Input harus angka!{Warna.ENDC}")
    except Exception as e:
        print(f"{Warna.MERAH}[✖] Gagal mencari file OBB: {e}{Warna.ENDC}")
        return None

def bongkar_obb(file_obb: Path):
    if TEMP_DIR.exists(): shutil.rmtree(TEMP_DIR)
    TEMP_DIR.mkdir()
    perintah = ['unzip', '-q', '-o', str(file_obb), '-d', str(TEMP_DIR)]
    return jalankan_perintah(perintah, f"Membongkar '{file_obb.name}'")

def terapkan_mod():
    print(f"\n{Warna.HEADER}Pilih mod yang ingin dipasang:{Warna.ENDC}")
    mod_list = list(MODS.items())
    for i, (nama_mod, _) in enumerate(mod_list):
        print(f"  {Warna.KUNING}[{i+1}]{Warna.ENDC} {nama_mod}")
    print(f"  {Warna.KUNING}[0]{Warna.ENDC} Kembali")

    while True:
        try:
            pilihan = int(input(f"\n{Warna.BIRU}Pilihan mod: {Warna.ENDC}"))
            if pilihan == 0: return False
            if 1 <= pilihan <= len(mod_list):
                nama_terpilih, fungsi_mod = mod_list[pilihan - 1]
                print(f"\n{Warna.BIRU}--- Menerapkan '{nama_terpilih}' ---{Warna.ENDC}")
                fungsi_mod(TEMP_DIR)
                print(f"{Warna.HIJAU}--- Selesai menerapkan '{nama_terpilih}' ---\n{Warna.ENDC}")
                return True
            else: print(f"{Warna.MERAH}Pilihan tidak valid!{Warna.ENDC}")
        except ValueError: print(f"{Warna.MERAH}Input harus angka!{Warna.ENDC}")

def kemas_ulang_obb(nama_original: Path):
    nama_baru = f"modded-{nama_original.name}"
    path_output_penuh = OUTPUT_DIR / nama_baru
    path_output_absolut = str(path_output_penuh.resolve())
    
    # Perintah ini harus dijalankan dengan shell=True untuk menangani `cd`
    perintah = f"cd '{str(TEMP_DIR)}' && zip -r -0 '{path_output_absolut}' ."
    
    if jalankan_perintah(perintah, f"Mengemas ulang menjadi '{nama_baru}'"):
        print(f"{Warna.HIJAU}{Warna.BOLD}[✔] BERHASIL! File tersimpan di:{Warna.ENDC}")
        print(f"   {Warna.KUNING}{path_output_penuh}{Warna.ENDC}")
        return True
    return False

# --- Loop Menu Utama ---
def main():
    try:
        bersihkan_layar()
        tampilkan_header()
        if not cek_dan_install_kebutuhan():
            sys.exit(f"\n{Warna.MERAH}Gagal menyiapkan kebutuhan script. Program berhenti.{Warna.ENDC}")
        
        obb_terpilih = None
        sudah_diekstrak = False

        while True:
            bersihkan_layar()
            tampilkan_header()
            print(f"{Warna.KUNING}--- Menu Utama ---{Warna.ENDC}")
            status_obb = obb_terpilih.name if obb_terpilih else f"{Warna.MERAH}Belum dipilih{Warna.ENDC}"
            status_ekstrak = f"{Warna.HIJAU}Siap dimodifikasi{Warna.ENDC}" if sudah_diekstrak else f"{Warna.MERAH}Belum dibongkar{Warna.ENDC}"
            print(f"[*] OBB Target : {status_obb}")
            print(f"[*] Status     : {status_ekstrak}\n")

            print(f"  [1] Bongkar OBB (Pilih & Ekstrak)")
            if sudah_diekstrak:
                print(f"  [2] Pasang Mod")
                print(f"  [3] Kemas Ulang OBB")
            print(f"  [0] Keluar")

            pilihan = input(f"\n{Warna.BIRU}Pilihanmu: {Warna.ENDC}")

            if pilihan == '1':
                file_pilihan = pilih_obb()
                if file_pilihan:
                    if bongkar_obb(file_pilihan):
                        obb_terpilih, sudah_diekstrak = file_pilihan, True
                    else:
                        sudah_diekstrak = False # Reset status jika gagal
                input("\nTekan Enter untuk lanjut...")
            
            elif pilihan == '2' and sudah_diekstrak:
                terapkan_mod()
                input("\nTekan Enter untuk lanjut...")

            elif pilihan == '3' and sudah_diekstrak:
                if kemas_ulang_obb(obb_terpilih):
                    obb_terpilih, sudah_diekstrak = None, False # Reset status
                input("\nTekan Enter untuk lanjut...")

            elif pilihan == '0':
                break
            
            else:
                print(f"{Warna.MERAH}Pilihan ngaco!{Warna.ENDC}")
                time.sleep(1)

    except KeyboardInterrupt:
        print(f"\n\n{Warna.MERAH}Program dihentikan paksa oleh user.{Warna.ENDC}")
    finally:
        # Bagian ini PASTI dijalankan, apapun yang terjadi. Kunci stabilitas!
        if TEMP_DIR.exists():
            print(f"{Warna.KUNING}[*] Membersihkan file sementara...{Warna.ENDC}")
            shutil.rmtree(TEMP_DIR)
            print(f"{Warna.HIJAU}[✔] Pembersihan selesai.{Warna.ENDC}")
        print(f"\n{Warna.HEADER}Sampai jumpa lagi!{Warna.ENDC}")

if __name__ == "__main__":
    main()
