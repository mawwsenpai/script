# -*- coding: utf-8 -*-

import os
import sys
import shutil
import subprocess
import time
from pathlib import Path
import glob
import datetime

# ==============================================================================
# ||                       KONFIGURASI & EDIT MOD KAMU DI SINI                  ||
# ==============================================================================

BASE_DIR = Path(os.path.expanduser("~")) / "storage" / "shared" / "Documents" / "TitanOBB"
BACKUP_DIR = BASE_DIR / "backup"

def mod_unlock_skin(path_ekstrak: Path):
    print(f"  -> Menjalankan mod 'Unlock All Skin'...")
    try:
        (path_ekstrak / "assets").mkdir(exist_ok=True)
        (path_ekstrak / "assets" / "titan_mod.txt").write_text("Titan Mod Engine Activated!")
        print("  -> Mod 'Unlock Skin' berhasil diterapkan (contoh).")
    except Exception as e: print(f"  -> GAGAL: {e}")

MODS = {'✨ Unlock All Skin (Contoh)': mod_unlock_skin}

# ==============================================================================
# ||                          MESIN UTAMA SCRIPT (JANGAN DIUBAH)                ||
# ==============================================================================

# --- Konfigurasi Sistem ---
TEMP_DIR = BASE_DIR / "temp_extraction"
TIMEOUT_DETIK = 900  # 15 menit

class Warna:
    MERAH='\033[91m'; HIJAU='\033[92m'; KUNING='\033[93m'; BIRU='\033[94m'
    HEADER='\033[95m'; BOLD='\033[1m'; ENDC='\033[0m'

# --- Fungsi Bantuan Pintar ---
def bersihkan_layar(): os.system('cls' if os.name == 'nt' else 'clear')
def tampilkan_header(): print(f"""{Warna.BOLD}{Warna.HEADER}
 ████████╗██╗████████╗ █████╗ ███╗   ██╗     ___  ____  ____
 ╚══██╔══╝██║╚══██╔══╝██╔══██╗████╗  ██║    / __)(_  _)(_  _)
    ██║   ██║   ██║   ███████║██╔██╗ ██║   ( (__  _)(_  _)(_
    ██║   ██║   ██║   ██╔══██║██║╚██╗██║    \___)(____)(____)
    ██║   ██║   ██║   ██║  ██║██║ ╚████║ {Warna.HIJAU}Titan OBB Suite v4.0{Warna.ENDC}
    ╚═╝   ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝ {Warna.ENDC}""")

def format_ukuran_file(byte_size):
    if byte_size is None: return "N/A"
    power = 1024
    n = 0
    power_labels = {0: '', 1: 'KB', 2: 'MB', 3: 'GB', 4: 'TB'}
    while byte_size > power and n < len(power_labels):
        byte_size /= power
        n += 1
    return f"{byte_size:.2f} {power_labels[n]}"

def jalankan_perintah(perintah, pesan_awal):
    print(f"{Warna.BIRU}[*] {pesan_awal}...{Warna.ENDC}")
    try:
        is_shell = isinstance(perintah, str)
        subprocess.run(perintah, shell=is_shell, check=True, capture_output=True, text=True, timeout=TIMEOUT_DETIK)
        return True
    except Exception as e:
        error_msg = getattr(e, 'stderr', str(e))
        print(f"{Warna.MERAH}[✖] Gagal: {error_msg.strip()}{Warna.ENDC}")
        return False

# --- Fungsi Inti Cerdas ---
def cek_dan_siapkan_lingkungan():
    print(f"{Warna.KUNING}--- Inisialisasi Lingkungan Kerja Titan ---{Warna.ENDC}")
    try:
        BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    except Exception as e:
        print(f"{Warna.MERAH}[✖] Gagal membuat direktori kerja! Cek izin Termux: {e}{Warna.ENDC}")
        return False
    if any(not shutil.which(pkg) for pkg in ['zip', 'unzip']):
        print(f"{Warna.KUNING}[!] Kebutuhan 'zip' & 'unzip' belum ada. Mencoba install...{Warna.ENDC}")
        if not jalankan_perintah(['pkg', 'install', 'zip', 'unzip', '-y'], "Menginstall paket"): return False
    print(f"{Warna.HIJAU}[✔] Lingkungan kerja siap.{Warna.ENDC}")
    return True

def cek_ruang_penyimpanan(file_path):
    try:
        file_size = file_path.stat().st_size
        _, _, free_space = shutil.disk_usage(BASE_DIR)
        print(f"[*] Ukuran OBB: {format_ukuran_file(file_size)}")
        print(f"[*] Ruang Tersedia: {format_ukuran_file(free_space)}")
        # Butuh ruang minimal 2.5x ukuran OBB (1x untuk ekstrak, 1.5x buffer)
        if free_space < file_size * 2.5:
            print(f"{Warna.MERAH}[✖] PERINGATAN: Ruang penyimpanan mungkin tidak cukup!{Warna.ENDC}")
            return input(f"{Warna.KUNING}Yakin mau lanjut? (y/n): {Warna.ENDC}").lower() == 'y'
        return True
    except Exception:
        return True # Gagal cek, anggap saja cukup

def pilih_obb():
    print(f"\n{Warna.HEADER}Memindai file OBB di semua penyimpanan...{Warna.ENDC}")
    paths = glob.glob('/storage/*')
    lokasi_pencarian = [Path('/storage/emulated/0')] + [Path(p) for p in paths]
    obb_files = []
    unique_paths = set()
    for lokasi in lokasi_pencarian:
        for folder in ["Android/obb", "Download"]:
            cek_lokasi = lokasi / folder
            if cek_lokasi.exists():
                for file_path in cek_lokasi.rglob('*.obb'):
                    if file_path not in unique_paths:
                        obb_files.append(file_path)
                        unique_paths.add(file_path)
    if not obb_files:
        print(f"{Warna.MERAH}[✖] ZONK! Tidak ada file .obb ditemukan.{Warna.ENDC}")
        return None
    
    print(f"\n{Warna.HIJAU}Pilih file OBB target:{Warna.ENDC}")
    for i, path_file in enumerate(obb_files):
        ukuran = format_ukuran_file(path_file.stat().st_size)
        print(f"  {Warna.KUNING}[{i+1}]{Warna.ENDC} {path_file.name} {Warna.BIRU}({ukuran}){Warna.ENDC}")
    while True:
        try:
            pilihan = int(input(f"\n{Warna.BIRU}Masukkan nomor: {Warna.ENDC}"))
            if 1 <= pilihan <= len(obb_files): return obb_files[pilihan - 1]
        except ValueError: pass

# --- Fungsi Fitur Lengkap: Backup, Restore, Install ---
def buat_backup(obb_path):
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = BACKUP_DIR / f"{obb_path.name}.{timestamp}.bak"
    print(f"\n{Warna.KUNING}Membuat backup untuk '{obb_path.name}'...{Warna.ENDC}")
    try:
        shutil.copy(obb_path, backup_file)
        print(f"{Warna.HIJAU}[✔] Backup berhasil disimpan di:{Warna.ENDC} {backup_file}")
        return backup_file
    except Exception as e:
        print(f"{Warna.MERAH}[✖] Gagal membuat backup: {e}{Warna.ENDC}")
        return None

def pilih_backup_untuk_restore():
    backups = sorted(list(BACKUP_DIR.glob('*.bak')))
    if not backups:
        print(f"{Warna.MERAH}[✖] Tidak ada file backup ditemukan.{Warna.ENDC}")
        return None
    print(f"\n{Warna.HIJAU}Pilih file backup untuk di-restore:{Warna.ENDC}")
    for i, path in enumerate(backups):
        print(f"  {Warna.KUNING}[{i+1}]{Warna.ENDC} {path.name}")
    while True:
        try:
            pilihan = int(input(f"\n{Warna.BIRU}Masukkan nomor: {Warna.ENDC}"))
            if 1 <= pilihan <= len(backups): return backups[pilihan-1]
        except ValueError: pass

def install_modded_obb(modded_path, original_path):
    print(f"\n{Warna.MERAH}{Warna.BOLD}PERINGATAN BESAR!{Warna.ENDC}")
    print(f"{Warna.KUNING}Ini akan MENIMPA file OBB asli game di:\n{original_path}{Warna.ENDC}")
    if input(f"{Warna.KUNING}Yakin mau lanjut? (ketik 'yes' untuk konfirmasi): {Warna.ENDC}").lower() != 'yes':
        print(f"{Warna.BIRU}[*] Instalasi dibatalkan.{Warna.ENDC}")
        return False
    
    try:
        shutil.move(modded_path, original_path)
        print(f"{Warna.HIJAU}[✔] OBB modifan berhasil diinstall!{Warna.ENDC}")
        return True
    except Exception as e:
        print(f"{Warna.MERAH}[✖] Gagal menginstall OBB: {e}{Warna.ENDC}")
        print(f"{Warna.KUNING}   File modded OBB tetap aman di: {modded_path}{Warna.ENDC}")
        return False

# --- Loop Menu Utama Cerdas ---
def main():
    state = {'target':None, 'backup':None, 'unpacked':False, 'repacked':None}
    try:
        bersihkan_layar(); tampilkan_header()
        if not cek_dan_siapkan_lingkungan(): sys.exit(1)
        
        while True:
            bersihkan_layar(); tampilkan_header()
            print(f"{Warna.KUNING}--- Status Saat Ini ---{Warna.ENDC}")
            print(f"[*] Target OBB  : {Warna.HIJAU}{state['target'].name if state['target'] else 'Belum Dipilih'}{Warna.ENDC}")
            print(f"[*] Backup      : {Warna.HIJAU}{'Ada' if state['backup'] else 'Belum Dibuat'}{Warna.ENDC}")
            print(f"[*] Status      : {Warna.HIJAU}{'Sudah Dibongkar' if state['unpacked'] else ('Siap Dibongkar' if state['target'] else 'Idle')}{Warna.ENDC}")
            print(f"[*] OBB Modifan : {Warna.HIJAU}{state['repacked'].name if state['repacked'] else 'Belum Dibuat'}{Warna.ENDC}")
            print(f"{Warna.KUNING}-----------------------{Warna.ENDC}")

            # Menu Dinamis
            if not state['target']:
                print("  [1] Pilih OBB Target\n  [2] Restore OBB dari Backup\n  [0] Keluar")
            elif not state['unpacked']:
                print("  [1] Bongkar OBB\n  [2] Buat Backup\n  [8] Ganti OBB Target\n  [0] Keluar")
            elif not state['repacked']:
                print("  [1] Terapkan Mod\n  [2] Kemas Ulang OBB\n  [9] Batalkan & Bersihkan\n  [0] Keluar")
            else: # Sudah dikemas ulang
                print("  [1] Install OBB Modifan ke Folder Game\n  [8] Buang Hasil & Mulai Lagi\n  [0] Keluar")

            pilihan = input(f"\n{Warna.BIRU}Pilihanmu: {Warna.ENDC}")
            
            if not state['target']: # State Awal
                if pilihan == '1': state['target'] = pilih_obb()
                elif pilihan == '2':
                    backup_file = pilih_backup_untuk_restore()
                    if backup_file:
                        original_name = backup_file.name.split('.bak')[0]
                        target_dir = Path('/storage/emulated/0/Android/obb') / original_name.split('_')[0]
                        if not target_dir.exists(): target_dir = Path('/sdcard/Download')
                        install_modded_obb(backup_file, target_dir / original_name.split('.obb')[0] + '.obb')
                        input("\nTekan Enter...")
                elif pilihan == '0': break
            
            elif not state['unpacked']: # OBB Terpilih
                if pilihan == '1':
                    if cek_ruang_penyimpanan(state['target']):
                        if TEMP_DIR.exists(): shutil.rmtree(TEMP_DIR)
                        TEMP_DIR.mkdir()
                        if jalankan_perintah(['unzip', '-q', '-o', str(state['target']), '-d', str(TEMP_DIR)], f"Membongkar OBB"):
                            state['unpacked'] = True
                elif pilihan == '2': state['backup'] = buat_backup(state['target'])
                elif pilihan == '8': state = {'target':None, 'backup':None, 'unpacked':False, 'repacked':None} # Reset
                elif pilihan == '0': break
                
            elif not state['repacked']: # Sudah Dibongkar
                if pilihan == '1': # Terapkan Mod (Mirip V3)
                    mod_list = list(MODS.items())
                    for i, (nama, _) in enumerate(mod_list): print(f"  [{i+1}] {nama}")
                    try:
                        p_mod = int(input("Pilih mod: "))
                        if 1 <= p_mod <= len(mod_list): MODS[mod_list[p_mod-1][0]](TEMP_DIR)
                    except ValueError: pass
                elif pilihan == '2': # Kemas Ulang
                    nama_baru = f"modded-{state['target'].name}"
                    path_output = OUTPUT_DIR / nama_baru
                    perintah = f"cd '{str(TEMP_DIR)}' && zip -r -0 '{str(path_output.resolve())}' ."
                    if jalankan_perintah(perintah, "Mengemas ulang OBB"):
                        state['repacked'] = path_output
                elif pilihan == '9': state['unpacked'] = False # Kembali ke state sebelumnya
                elif pilihan == '0': break

            else: # Sudah Dikemas Ulang
                if pilihan == '1':
                    if install_modded_obb(state['repacked'], state['target']):
                        state = {'target':None, 'backup':None, 'unpacked':False, 'repacked':None} # Reset Total
                elif pilihan == '8': state = {'target':None, 'backup':None, 'unpacked':False, 'repacked':None} # Reset
                elif pilihan == '0': break
            
            if pilihan not in ['2', '8', '9', '0'] and state['target']: input("\nTekan Enter untuk lanjut...")

    except KeyboardInterrupt: print(f"\n\n{Warna.MERAH}Program dihentikan paksa.{Warna.ENDC}")
    finally:
        if TEMP_DIR.exists():
            print(f"{Warna.KUNING}[*] Membersihkan file sementara...{Warna.ENDC}")
            shutil.rmtree(TEMP_DIR)
        print(f"\n{Warna.HEADER}Sesi Titan OBB Suite berakhir.{Warna.ENDC}")

if __name__ == "__main__":
    main()
