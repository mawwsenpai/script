#!/usr/bin/env bash

# ==============================================================================
#                 MAWW SCRIPT V8 - ALL-IN-ONE EDITION
# ==============================================================================
# Deskripsi:
#   Versi final yang menggabungkan semua file (main, core, patch) menjadi
#   satu untuk menghilangkan error dan mempermudah penggunaan.
#
# Cara Pakai:
#   1. Simpan sebagai maww-script.sh
#   2. Jalankan dengan: bash maww-script.sh
# ==============================================================================

# --- [ KONFIGURASI SCRIPT & GLOBAL ] ---
set -e
set -o pipefail

# --- [ DAFTAR DEPENDENSI ] ---
readonly TERMUX_PACKAGES=( "python" "termux-api" "coreutils" "dos2unix" )
readonly PYTHON_REQUIREMENTS=(
    "google-api-python-client==2.100.0"
    "google-auth==2.23.0"
    "google-auth-httplib2==0.2.0"
    "google-auth-oauthlib==1.2.0"
)

# --- [ KONFIGURASI FILE & DIREKTORI ] ---
readonly CONFIG_FILE="device.conf"; readonly PYTHON_SCRIPT="gmail_listener.py"
readonly PID_FILE="listener.pid"; readonly LOG_FILE="listener.log"
readonly TOKEN_FILE="token.json"; readonly CREDS_FILENAME="credentials.json"
readonly CREDS_DEST_DIR="$HOME/storage/shared/Automatic"
readonly CREDS_FILE_PATH="$CREDS_DEST_DIR/$CREDS_FILENAME"
readonly PATCH_FLAG_FILE=".patch_installed"

# --- [ KODE WARNA ANSI & FUNGSI LOGGING ] ---
readonly C_RESET='\033[0m'; readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m'; readonly C_PURPLE='\033[0;35m';
readonly C_WHITE='\033[1;37m';

function _log()     { local color="$1"; shift; echo -e "${color}[*] $@${C_RESET}"; }
function _log_info()  { _log "$C_BLUE" "$@"; }
function _log_ok()    { _log "$C_GREEN" "$@"; }
function _log_warn()  { _log "$C_YELLOW" "$@"; }
function _log_error() { _log "$C_RED" "$@"; }


# ==============================================================================
#                       BAGIAN 1: LOGIKA PATCH & INSTALASI
# ==============================================================================

function run_patcher() {
    clear
    _log_info "============================================="
    _log_info "   MEMULAI PROSES PERSIAPAN LINGKUNGAN...    "
    _log_info "============================================="
    
    _log_info "\nLANGKAH 1: Memperbarui & menginstal paket sistem..."
    pkg update -y >/dev/null 2>&1
    pkg install -y "${TERMUX_PACKAGES[@]}" || { _log_error "Gagal menginstal paket sistem."; exit 1; }
    _log_ok "   -> Paket sistem berhasil dikonfigurasi."

    _log_info "\nLANGKAH 2: Membersihkan & menginstal library Python..."
    pip cache purge >/dev/null 2>&1
    pip install --no-cache-dir --force-reinstall "${PYTHON_REQUIREMENTS[@]}" || { _log_error "Gagal menginstal library Python."; exit 1; }
    _log_ok "   -> Semua library Python berhasil diinstal dengan versi yang tepat."

    _log_info "\nLANGKAH 3: Mengonfigurasi izin penyimpanan..."
    if [ ! -d "$HOME/storage/shared" ]; then termux-setup-storage; fi
    _log_ok "   -> Izin penyimpanan siap."
    
    echo
    _log_ok "======================================================="
    _log_ok "  ✅  PROSES PERSIAPAN LINGKUNGAN SELESAI! ✅"
    _log_ok "======================================================="
    touch "$PATCH_FLAG_FILE"
    _log_info "Lingkungan Anda sekarang sudah bersih dan siap."
}

# ==============================================================================
#                       BAGIAN 2: LOGIKA INTI (CORE)
# ==============================================================================

function setup() {
    clear
    _log_info "--- Memulai Proses Setup (Metode Web Auth) ---"
    stop >/dev/null 2>&1 || true
    rm -f "$TOKEN_FILE" "$CONFIG_FILE"
    
    _log_info "Langkah 1/3: Mengumpulkan Detail Akun..."
    read -p "   - Masukkan Alamat Email Gmail Anda : " email_input
    read -p "   - Masukkan Subjek Perintah Rahasia : " subject_input
    echo "MY_EMAIL=\"$email_input\"" > "$CONFIG_FILE"
    echo "CMD_SUBJECT=\"$subject_input\"" >> "$CONFIG_FILE"
    
    _log_info "Langkah 2/3: Menyiapkan File Kredensial (tipe Web App)..."
    mkdir -p "$CREDS_DEST_DIR"
    if [ ! -f "$CREDS_FILE_PATH" ]; then
        _log_warn "   File '$CREDS_FILENAME' tidak ditemukan di lokasi default."
        _log_info "   Mencari di folder Download..."
        local download_path="$HOME/storage/shared/Download/$CREDS_FILENAME"
        if [ -f "$download_path" ]; then
            cp "$download_path" "$CREDS_FILE_PATH"
            _log_ok "   File ditemukan di Download dan disalin ke tujuan."
        else
            _log_error "GAGAL: Pastikan Anda sudah membuat kredensial 'Aplikasi Web' dan menaruh '$CREDS_FILENAME' di folder Download."
            exit 1
        fi
    fi

    _log_info "Langkah 3/3: Otorisasi Akun Google..."
    _generate_python_script_web_auth
    
    if python "$PYTHON_SCRIPT"; then
        _log_ok "🎉 SETUP SELESAI! Otorisasi berhasil."
    else
        _log_error "SETUP GAGAL. Pastikan Anda mengikuti instruksi otorisasi dengan benar."
        exit 1
    fi
}

function start() {
    _log_info "Mencoba memulai listener..."
    if [ ! -f "$CONFIG_FILE" ] || [ ! -f "$TOKEN_FILE" ]; then
        _log_error "Konfigurasi/token tidak ditemukan. Jalankan 'Setup' terlebih dahulu."; return 1
    fi
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        _log_warn "Listener sudah berjalan."; return 0
    fi
    # Pastikan skrip python selalu versi terbaru sebelum dijalankan
    _generate_python_script_web_auth
    nohup python "$PYTHON_SCRIPT" >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    _log_ok "Listener berhasil dimulai di background (PID: $(cat "$PID_FILE"))."
}

function stop() {
    _log_info "Mencoba menghentikan listener..."
    if [ ! -f "$PID_FILE" ]; then _log_warn "Listener tidak sedang berjalan."; return 0; fi
    kill "$(cat "$PID_FILE")"; rm -f "$PID_FILE"
    _log_ok "Listener telah dihentikan."
}

function logs() {
    if [ ! -f "$LOG_FILE" ]; then _log_warn "File log belum ada."; return 1; fi
    _log_info "Menampilkan log (Ctrl+C untuk keluar)..."
    tail -f "$LOG_FILE"
}

function cleanup() {
    _log_warn "Anda YAKIN ingin menghapus semua konfigurasi?"; read -p "(y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        stop >/dev/null 2>&1 || true
        rm -f "$CONFIG_FILE" "$LOG_FILE" "$PYTHON_SCRIPT" "$TOKEN_FILE" "$PID_FILE"
        _log_ok "Pembersihan selesai."
    else
        _log_info "Dibatalkan."
    fi
}

function _generate_python_script_web_auth() {
    source "$CONFIG_FILE"
    cat << EOF > "$PYTHON_SCRIPT"
# -*- coding: utf-8 -*-
import os, sys, subprocess, logging, base64, time
from google_auth_oauthlib.flow import Flow
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders

SCOPES = ['https://www.googleapis.com/auth/gmail.modify']
TOKEN_FILE = '$TOKEN_FILE'; CREDS_FILE = '$CREDS_FILE_PATH'
MY_EMAIL = '$MY_EMAIL'; CMD_SUBJECT = '$CMD_SUBJECT'
LOG_FILE = '$LOG_FILE'; POLL_INTERVAL = 300
REDIRECT_URI = 'http://localhost:8080'
logging.basicConfig(level=logging.INFO, filename=LOG_FILE, filemode='a', format='%(asctime)s - %(levelname)s - %(message)s')

def get_credentials():
    if os.path.exists(TOKEN_FILE): return Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    if not os.path.exists(CREDS_FILE): sys.exit(f"FATAL: File kredensial tidak ditemukan di '{CREDS_FILE}'!")
    flow = Flow.from_client_secrets_file(CREDS_FILE, SCOPES, redirect_uri=REDIRECT_URI)
    auth_url, _ = flow.authorization_url(prompt='consent')
    print('--- PROSES OTORISASI MANUAL ---')
    print('1. Buka URL di bawah ini di browser Anda:')
    print(f'==> {auth_url}')
    print('\\n2. Login, berikan izin, lalu Anda akan diarahkan ke halaman error (ini normal).')
    print('3. SALIN SELURUH URL dari address bar browser Anda setelah diarahkan.')
    redirect_response = input('\\n4. PASTE URL lengkap tersebut di sini lalu tekan Enter:\\n')
    try:
        flow.fetch_token(authorization_response=redirect_response)
        creds = flow.credentials
        with open(TOKEN_FILE, 'w') as token: token.write(creds.to_json())
        return creds
    except Exception as e: sys.exit(f'ERROR: Gagal mendapatkan token. Pastikan URL yang Anda paste benar. Detail: {e}')

def send_reply(service, original_message, body_text, attachment_path=None):
    try:
        headers = original_message['payload']['headers']
        to_email = next(h['value'] for h in headers if h['name'].lower() == 'from')
        subject = "Re: " + next(h['value'] for h in headers if h['name'].lower() == 'subject')
        message = MIMEMultipart()
        message['to'] = to_email; message['subject'] = subject
        message.attach(MIMEText(body_text, 'plain'))
        if attachment_path and os.path.exists(attachment_path):
            with open(attachment_path, 'rb') as f:
                part = MIMEBase('application', 'octet-stream'); part.set_payload(f.read())
            encoders.encode_base64(part)
            part.add_header('Content-Disposition', f'attachment; filename="{os.path.basename(attachment_path)}"')
            message.attach(part)
        raw_message = base64.urlsafe_b64encode(message.as_bytes()).decode()
        service.users().messages().send(userId='me', body={'raw': raw_message}).execute()
        logging.info(f"Berhasil mengirim balasan ke {to_email}")
    except Exception as e: logging.error(f"Gagal mengirim balasan: {e}")

def execute_command(service, msg_obj, full_command):
    try:
        command = full_command.split(':')[1].strip().lower()
        logging.info(f"Mengeksekusi perintah: '{command}'")
        output_file, reply_body = None, f"Perintah '{command}' telah selesai dieksekusi."
        if command == 'ss':
            output_file, reply_body = os.path.expanduser("~/screenshot.png"), "Screenshot terlampir."
            subprocess.run(["termux-screenshot", output_file], timeout=20, check=True)
        elif command == 'foto':
            output_file, reply_body = os.path.expanduser("~/photo.jpg"), "Foto terlampir."
            subprocess.run(["termux-camera-photo", "-c", "0", output_file], timeout=25, check=True)
        elif command == 'lokasi':
            result = subprocess.run(["termux-location"], capture_output=True, text=True, timeout=30, check=True)
            reply_body = f"Hasil perintah 'lokasi':\\n\\n{result.stdout or 'Tidak ada output.'}"
        elif command == 'info':
            result = subprocess.run(["termux-device-info"], capture_output=True, text=True, timeout=15, check=True)
            reply_body = f"Info Perangkat:\\n\\n{result.stdout or 'Tidak ada output.'}"
        elif command == 'exit-listener':
            reply_body = "Perintah 'exit-listener' diterima. Listener akan berhenti."
            send_reply(service, msg_obj, reply_body)
            logging.info("Listener dihentikan melalui perintah remote.")
            sys.exit(0)
        else: reply_body = f"Perintah '{command}' tidak dikenali."
        send_reply(service, msg_obj, reply_body, output_file)
    except Exception as e:
        logging.error(f"Error saat eksekusi: {e}")
        send_reply(service, msg_obj, f"GAGAL: Terjadi error. Cek log untuk detail.")
    finally:
        if output_file and os.path.exists(output_file): os.remove(output_file)

def main_loop():
    creds = get_credentials()
    service = build('gmail', 'v1', credentials=creds)
    logging.info("Listener service dimulai.")
    print("Listener kini berjalan di background...")
    while True:
        try:
            q = f"from:{MY_EMAIL} is:unread subject:'{CMD_SUBJECT}'"
            results = service.users().messages().list(userId='me', labelIds=['INBOX'], q=q).execute()
            messages = results.get('messages', [])
            for message_info in messages:
                msg_id = message_info['id']
                msg_obj = service.users().messages().get(userId='me', id=msg_id).execute()
                if msg_obj: execute_command(service, msg_obj, msg_obj['snippet'])
                service.users().messages().modify(userId='me', id=msg_id, body={'removeLabelIds': ['UNREAD']}).execute()
            time.sleep(POLL_INTERVAL)
        except HttpError as e:
            if e.resp.status == 401: logging.error("Otorisasi Gagal (401). Mencoba refresh token..."); creds.refresh(Request())
            else: logging.error(f"HttpError: {e}"); time.sleep(POLL_INTERVAL * 2)
        except Exception as e: logging.error(f"Terjadi error pada loop utama: {e}"); time.sleep(POLL_INTERVAL * 2)

if __name__ == '__main__':
    # Jika token tidak ada, jalankan otorisasi dulu. Jika ada, langsung jalankan loop utama.
    if not os.path.exists(TOKEN_FILE): get_credentials()
    else: main_loop()
EOF
}


# ==============================================================================
#                         BAGIAN 3: TAMPILAN MENU (UI)
# ==============================================================================

function display_header() {
    clear
    local status_text; local pid_text=""
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        status_text="${C_GREEN}AKTIF${C_RESET}"
        pid_text="(PID: $(cat "$PID_FILE"))"
    else
        status_text="${C_RED}TIDAK AKTIF${C_RESET}"
    fi
    echo -e "${C_PURPLE}╭───────────────────────────────────────────────────╮${C_RESET}"
    echo -e "${C_PURPLE}│${C_WHITE}      MAWW SCRIPT V8 - ALL-IN-ONE EDITION        ${C_PURPLE}│${C_RESET}"
    echo -e "${C_PURPLE}├───────────────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_PURPLE}│ ${C_CYAN}Status   :${C_RESET} ${status_text} ${pid_text}                   ${C_PURPLE}│${C_RESET}"
    echo -e "${C_PURPLE}╰───────────────────────────────────────────────────╯${C_RESET}"
}

function display_menu_and_prompt() {
    echo -e "\n${C_WHITE}Pilih salah satu opsi di bawah ini:${C_RESET}"
    echo -e "${C_CYAN}┌─ KONTROL ─────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}1) Mulai Listener${C_RESET}                             │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}2) Hentikan Listener${C_RESET}                          │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}3) Setup / Konfigurasi Ulang${C_RESET}                  │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}4) Lihat Log${C_RESET}                                  │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}5) Hapus Konfigurasi${C_RESET}                          │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_WHITE}6) Keluar${C_RESET}                                     │${C_RESET}"
    echo -e "${C_CYAN}└───────────────────────────────────────────────────┘${C_RESET}"
    
    local choice
    read -p "   Pilihanmu: " choice
    case $choice in
        1) start ;;
        2) stop ;;
        3) setup ;;
        4) logs ;;
        5) cleanup ;;
        6) echo -e "\n${C_PURPLE}Sampai jumpa!${C_RESET}"; exit 0 ;;
        *) echo -e "\n${C_RED}Pilihan tidak valid.${C_RESET}";;
    esac
    echo -e "\n${C_YELLOW}Tekan [Enter] untuk kembali...${C_RESET}"; read -n 1
}


# ==============================================================================
#                         BAGIAN 4: FUNGSI UTAMA (MAIN)
# ==============================================================================

function main() {
    # Pertama kali dijalankan, otomatis lakukan persiapan lingkungan
    if [ ! -f "$PATCH_FLAG_FILE" ]; then
        clear
        echo -e "${C_YELLOW}Selamat datang! Ini adalah eksekusi pertama.${C_RESET}"
        echo "Skrip akan menganalisis dan menyiapkan lingkungan Anda secara otomatis."
        echo -e "${C_YELLOW}Tekan [Enter] untuk memulai...${C_RESET}"; read -n 1
        run_patcher
        echo -e "${C_YELLOW}Tekan [Enter] untuk melanjutkan ke menu utama...${C_RESET}"; read -n 1
    fi

    # Loop menu utama
    while true; do
        display_header
        display_menu_and_prompt
    done
}

# Panggil fungsi utama untuk memulai segalanya
main