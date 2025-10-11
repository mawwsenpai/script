# -*- coding: utf-8 -*-

import os
import sys
import shutil
import subprocess
import time
from pathlib import Path
import re

# ==============================================================================
# ||                       KONFIGURASI & EDIT MOD KAMU DI SINI                  ||
# ==============================================================================

# --- Path Dasar (Profesional, di dalam folder Documents)
BASE_DIR = Path(os.path.expanduser("~")) / "storage" / "shared" / "Documents" / "FF_Sniper"

# --- Logika Mod FF-Specific (Contoh)
def mod_ganti_config(path_ekstrak: Path):
    """Contoh mod untuk mengubah file konfigurasi di dalam OBB."""
    print("  -> Menjalankan mod 'Ganti Config Senjata' (Contoh)...")
    target_dir = path_ekstrak / "assets" / "bin" / "Data"
    target_file = target_dir / "config.ini" # Ini hanya contoh nama file
    try:
        if target_dir.exists() and target_file.is_file():
            print(f"  -> Menemukan file target: {target_file}")
            # Logika mod kamu di sini, misalnya menimpa file
            # shutil.copy('/sdcard/Download/config_baru.ini', target_file)
            print("  -> BERHASIL (Simulasi): File config telah dimodifikasi.")
        else:
            print(f"  -> GAGAL: File atau folder config tidak ditemukan di {target_dir}")
    except Exception as e:
        print(f"  -> GAGAL MOD: {e}")

# --- Daftar Mod yang Akan Muncul di Menu ---
MODS = {
    '🔧 Ganti Config Senjata (Contoh)': mod_ganti_config,
}

# ==============================================================================
# ||                          MESIN UTAMA SCRIPT (JANGAN DIUBAH)                ||
# ==============================================================================

# --- Konfigurasi Sistem ---
FF_PACKAGE_NAME = "com.dts.freefireth"
TEMP_DIR = BASE_DIR / "temp_extraction"
OUTPUT_DIR = BASE_DIR / "hasil-mod"

class Warna:
    MERAH='\033[91m'; HIJAU='\033[92m'; KUNING='\033[93m'; BIRU='\033[94m'
    HEADER='\033[95m'; BOLD='\033[1m'; ENDC='\033[0m'

# --- Fungsi Bantuan & Inti ---
def bersihkan_layar(): os.system('cls' if os.name == 'nt' else 'clear')
def tampilkan_header(): print(f"""{Warna.BOLD}{Warna.HEADER}
   ███████╗███████╗   ███████╗███╗   ██╗██╗██████╗ ███████╗██████╗
   ██╔════╝██╔════╝   ██╔════╝████╗  ██║██║██╔══██╗██╔════╝██╔══██╗
   █████╗  █████╗     ███████╗██╔██╗ ██║██║██████╔╝█████╗  ██████╔╝
   ██╔══╝  ██╔══╝     ╚════██║██║╚██╗██║██║██╔═══╝ ██╔══╝  ██╔══██╗
   ██║     ███████╗   ███████║██║ ╚████║██║██║     ███████╗██║  ██║
   ╚═╝     ╚══════╝   ╚══════╝╚═╝  ╚═══╝╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝
             {Warna.HIJAU}---==[ Auto-Pintar Script ]==---{Warna.ENDC}""")

def jalankan_perintah(perintah, pesan_awal):
    print(f"{Warna.BIRU}[*] {pesan_awal}...{Warna.ENDC}")
    try:
        subprocess.run(perintah, shell=isinstance(perintah, str), check=True, capture_output=True, text=True, timeout=900)
        return True
    except Exception as e:
        error_msg = getattr(e, 'stderr', str(e))
        print(f"{Warna.MERAH}[✖] Gagal: {error_msg.strip()}{Warna.ENDC}")
        return False

# --- OTAK UTAMA: FUNGSI ANALISIS GAME ---
def analisis_game_freefire():
    """Menganalisis instalasi game Free Fire secara profesional."""
    print(f"{Warna.KUNING}--- Menganalisis Instalasi Game Free Fire ---{Warna.ENDC}")
    laporan = {'main_obb': None, 'patch_obb': None, 'root_access': False, 'data_path': None}
    
    # 1. Analisis OBB
    obb_dir = Path(f"/storage/emulated/0/Android/obb/{FF_PACKAGE_NAME}")
    if obb_dir.exists():
        print(f"{Warna.HIJAU}[✔] Folder OBB ditemukan: {obb_dir}{Warna.ENDC}")
        main_files = list(obb_dir.glob('main.*.obb'))
        patch_files = list(obb_dir.glob('patch.*.obb'))
        
        if main_files: laporan['main_obb'] = main_files[0]
        
        # Logika pintar untuk memilih patch terbaru
        if patch_files:
            latest_patch = max(patch_files, key=lambda p: int(re.search(r'\d+', p.name).group()))
            laporan['patch_obb'] = latest_patch
    else:
        print(f"{Warna.MERAH}[✖] Folder OBB Free Fire tidak ditemukan!{Warna.ENDC}")

    # 2. Analisis Folder Data (Deteksi Root)
    data_dir = Path(f"/data/data/{FF_PACKAGE_NAME}")
    laporan['data_path'] = data_dir
    try:
        if data_dir.exists() and os.access(data_dir, os.R_OK):
            laporan['root_access'] = True
            print(f"{Warna.HIJAU}[✔] Akses ROOT terdeteksi! Folder data bisa diakses.{Warna.ENDC}")
        else:
            raise PermissionError
    except PermissionError:
        print(f"{Warna.KUNING}[!] Akses ROOT tidak terdeteksi atau ditolak.{Warna.ENDC}")
        print(f"{Warna.KUNING}   Modding akan terbatas pada file di dalam OBB saja.{Warna.ENDC}")
    
    return laporan

def bongkar_obb(obb_path, timpa=False):
    if not timpa and TEMP_DIR.exists(): shutil.rmtree(TEMP_DIR)
    if not TEMP_DIR.exists(): TEMP_DIR.mkdir()
    
    pesan = f"Membongkar '{obb_path.name}'"
    if timpa: pesan = f"Menimpa dengan file dari '{obb_path.name}'"
    
    return jalankan_perintah(['unzip', '-q', '-o', str(obb_path), '-d', str(TEMP_DIR)], pesan)

def kemas_ulang_obb(nama_original: Path):
    nama_baru = f"modded-{nama_original.name}"
    path_output_penuh = OUTPUT_DIR / nama_baru
    perintah = f"cd '{str(TEMP_DIR)}' && zip -r -0 '{str(path_output_penuh.resolve())}' ."
    if jalankan_perintah(perintah, f"Mengemas ulang menjadi '{nama_baru}'"):
        print(f"{Warna.HIJAU}{Warna.BOLD}[✔] BERHASIL! File tersimpan di:\n   {Warna.KUNING}{path_output_penuh}{Warna.ENDC}")
        return True
    return False
    
# --- Loop Menu Utama ---
def main():
    try:
        bersihkan_layar(); tampilkan_header()
        BASE_DIR.mkdir(parents=True, exist_ok=True)
        OUTPUT_DIR.mkdir(exist_ok=True)
        
        laporan_ff = analisis_game_freefire()
        input(f"\n{Warna.BIRU}Tekan Enter untuk lanjut ke menu utama...{Warna.ENDC}")

        sudah_dibongkar = False
        obb_sumber = None

        while True:
            bersihkan_layar(); tampilkan_header()
            print(f"{Warna.KUNING}--- Laporan Analisis Free Fire ---{Warna.ENDC}")
            print(f"[*] OBB Utama (main) : {Warna.HIJAU}{laporan_ff['main_obb'].name if laporan_ff['main_obb'] else 'Tidak Ditemukan'}{Warna.ENDC}")
            print(f"[*] OBB Update (patch): {Warna.HIJAU}{laporan_ff['patch_obb'].name if laporan_ff['patch_obb'] else 'Tidak Ditemukan'}{Warna.ENDC}")
            print(f"[*] Akses Root        : {Warna.HIJAU if laporan_ff['root_access'] else Warna.MERAH}{'YA' if laporan_ff['root_access'] else 'TIDAK'}{Warna.ENDC}")
            print(f"[*] Status            : {Warna.HIJAU}{'Siap Dimodifikasi' if sudah_dibongkar else 'Siap Dibongkar'}{Warna.ENDC}")
            print(f"{Warna.KUNING}----------------------------------{Warna.ENDC}")
            
            print("--- Opsi Bongkar & Edit ---")
            if laporan_ff['main_obb']: print("  [1] Bongkar OBB Utama (main)")
            if laporan_ff['patch_obb']: print("  [2] Bongkar OBB Update (patch) SAJA")
            if laporan_ff['main_obb'] and laporan_ff['patch_obb']: print("  [3] Bongkar OBB Utama + Timpa dengan Update (Direkomendasikan)")
            if sudah_dibongkar:
                print("  [4] Terapkan Mod")
                print("  [5] Kemas Ulang OBB")
            print("  [0] Keluar")

            pilihan = input(f"\n{Warna.BIRU}Pilihanmu: {Warna.ENDC}")

            if pilihan == '1' and laporan_ff['main_obb']:
                if bongkar_obb(laporan_ff['main_obb']):
                    sudah_dibongkar, obb_sumber = True, laporan_ff['main_obb']
            elif pilihan == '2' and laporan_ff['patch_obb']:
                if bongkar_obb(laporan_ff['patch_obb']):
                    sudah_dibongkar, obb_sumber = True, laporan_ff['patch_obb']
            elif pilihan == '3' and laporan_ff['main_obb'] and laporan_ff['patch_obb']:
                print("[*] Langkah 1 dari 2...")
                if bongkar_obb(laporan_ff['main_obb'], timpa=False):
                    print("[*] Langkah 2 dari 2...")
                    if bongkar_obb(laporan_ff['patch_obb'], timpa=True):
                        sudah_dibongkar, obb_sumber = True, laporan_ff['patch_obb'] # Sumber nama file dari patch
            elif pilihan == '4' and sudah_dibongkar:
                # Logika Terapkan Mod
                mod_list = list(MODS.items())
                for i, (nama, _) in enumerate(mod_list): print(f"  [{i+1}] {nama}")
                try:
                    p_mod = int(input("Pilih mod: "))
                    if 1 <= p_mod <= len(mod_list): MODS[mod_list[p_mod-1][0]](TEMP_DIR)
                except (ValueError, IndexError): print(f"{Warna.MERAH}Pilihan tidak valid!{Warna.ENDC}")
            elif pilihan == '5' and sudah_dibongkar:
                if kemas_ulang_obb(obb_sumber):
                    sudah_dibongkar, obb_sumber = False, None # Reset
            elif pilihan == '0':
                break
            else:
                print(f"{Warna.MERAH}Pilihan ngaco!{Warna.ENDC}")
            
            input("\nTekan Enter untuk kembali ke menu...")

    except KeyboardInterrupt: print(f"\n\n{Warna.MERAH}Program dihentikan paksa.{Warna.ENDC}")
    finally:
        if TEMP_DIR.exists():
            print(f"{Warna.KUNING}[*] Membersihkan file sementara...{Warna.ENDC}")
            shutil.rmtree(TEMP_DIR)
        print(f"\n{Warna.HEADER}Sesi FF Sniper berakhir.{Warna.ENDC}")

if __name__ == "__main__":
    main()
