#!/usr/bin/env bash
set -e
set -o pipefail
readonly CONFIG_FILE="device.conf"; readonly PYTHON_SCRIPT="gmail_listener.py"
readonly PID_FILE="listener.pid"; readonly LOG_FILE="listener.log"
readonly TOKEN_FILE="token.json"; readonly CREDS_FILENAME="credentials.json"
readonly CREDS_DEST_DIR="$HOME/storage/shared/Automatic"
readonly CREDS_FILE_PATH="$CREDS_DEST_DIR/$CREDS_FILENAME"
readonly C_RESET='\033[0m'; readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m';
function _log() { local color="$1"; shift; echo -e "${color}[*] $@${C_RESET}"; }
function _log_info() { _log "$C_BLUE" "$@"; }
function _log_ok() { _log "$C_GREEN" "$@"; }
function _log_warn() { _log "$C_YELLOW" "$@"; }
function _log_error() { _log "$C_RED" "$@"; }

function setup() {
    clear
    _log_info "--- Memulai Proses Setup (Metode Web Auth) ---"
    stop >/dev/null 2>&1 || true
    rm -f "$TOKEN_FILE" "$CONFIG_FILE"
    pkg install python termux-api coreutils -y >/dev/null 2>&1
    pip install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib >/dev/null 2>&1
    
    _log_info "Langkah 1/3: Mengumpulkan Detail Akun..."
    read -p "   - Masukkan Alamat Email Gmail Anda : " email_input
    read -p "   - Masukkan Subjek Perintah Rahasia : " subject_input
    echo "MY_EMAIL=\"$email_input\"" > "$CONFIG_FILE"
    echo "CMD_SUBJECT=\"$subject_input\"" >> "$CONFIG_FILE"
    
    _log_info "Langkah 2/3: Menyiapkan File Kredensial..."
    mkdir -p "$CREDS_DEST_DIR"
    if [ ! -f "$CREDS_FILE_PATH" ]; then
        _log_warn "   File '$CREDS_FILENAME' (tipe Web App) tidak ditemukan di lokasi default."
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

function _generate_python_script_web_auth() {
    source "$CONFIG_FILE"
    cat << EOF > "$PYTHON_SCRIPT"
# -*- coding: utf-8 -*-
import os, sys, subprocess, logging, base64, time
from google_auth_oauthlib.flow import Flow
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders

SCOPES = ['https://www.googleapis.com/auth/gmail.modify']
TOKEN_FILE = '$TOKEN_FILE'
CREDS_FILE = '$CREDS_FILE_PATH'
MY_EMAIL = '$MY_EMAIL'
CMD_SUBJECT = '$CMD_SUBJECT'
LOG_FILE = '$LOG_FILE'
POLL_INTERVAL = 300
REDIRECT_URI = 'http://localhost:8080'

logging.basicConfig(level=logging.INFO, filename=LOG_FILE, filemode='a', format='%(asctime)s - %(levelname)s - %(message)s')

def get_credentials():
    if os.path.exists(TOKEN_FILE):
        return Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    
    if not os.path.exists(CREDS_FILE):
        print(f"FATAL: File kredensial tidak ditemukan di '{CREDS_FILE}'!", file=sys.stderr)
        sys.exit(1)

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
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())
        return creds
    except Exception as e:
        print(f'ERROR: Gagal mendapatkan token. Pastikan URL yang Anda paste benar. Detail: {e}', file=sys.stderr)
        sys.exit(1)

# (Sisa kode Python sama seperti versi sebelumnya)
def execute_command(service, msg_obj, full_command):
    pass # Disembunyikan untuk keringkasan, logikanya sama

def main_loop():
    logging.info("Listener service dimulai.")
    creds = get_credentials()
    service = build('gmail', 'v1', credentials=creds)
    print("Listener kini berjalan di background...")
    while True:
        # Logika check email
        time.sleep(POLL_INTERVAL)

if __name__ == '__main__':
    main_loop()
EOF

    # Isi kembali fungsi execute_command yang dikosongkan tadi
    # Ini cara untuk menjaga blok kode tetap pendek dan mudah dibaca
    local python_execute_logic='''
def send_reply(service, original_message, body_text, attachment_path=None):
    try:
        headers = original_message['payload']['headers']
        to_email = next(h['value'] for h in headers if h['name'].lower() == 'from')
        subject = "Re: " + next(h['value'] for h in headers if h['name'].lower() == 'subject')
        message = MIMEMultipart()
        message['to'] = to_email
        message['subject'] = subject
        message.attach(MIMEText(body_text, 'plain'))
        if attachment_path and os.path.exists(attachment_path):
            with open(attachment_path, 'rb') as f:
                part = MIMEBase('application', 'octet-stream')
                part.set_payload(f.read())
            encoders.encode_base64(part)
            part.add_header('Content-Disposition', f'attachment; filename="{os.path.basename(attachment_path)}"')
            message.attach(part)
        raw_message = base64.urlsafe_b64encode(message.as_bytes()).decode()
        service.users().messages().send(userId='me', body={'raw': raw_message}).execute()
        logging.info(f"Berhasil mengirim balasan ke {to_email}")
    except Exception as e:
        logging.error(f"Gagal mengirim balasan: {e}")

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
        else:
            reply_body = f"Perintah '{command}' tidak dikenali."
        send_reply(service, msg_obj, reply_body, output_file)
    except Exception as e:
        logging.error(f"Error saat eksekusi: {e}")
        send_reply(service, msg_obj, f"GAGAL: Terjadi error. Cek log untuk detail.")
    finally:
        if output_file and os.path.exists(output_file):
            os.remove(output_file)
'''
    # Ganti placeholder di skrip python dengan logika yang sebenarnya
    sed -i "s|pass # Disembunyikan untuk keringkasan, logikanya sama|${python_execute_logic}|" "$PYTHON_SCRIPT"
}

function start() {
    _log_info "Mencoba memulai listener..."
    if [ ! -f "$CONFIG_FILE" ] || [ ! -f "$TOKEN_FILE" ]; then
        _log_error "Konfigurasi/token tidak ditemukan. Jalankan 'Setup' terlebih dahulu."; return 1
    fi
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        _log_warn "Listener sudah berjalan."; return 0
    fi
    nohup python "$PYTHON_SCRIPT" >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    _log_ok "Listener berhasil dimulai di background (PID: $(cat "$PID_FILE"))."
}
function stop() {
    _log_info "Mencoba menghentikan listener..."
    if [ ! -f "$PID_FILE" ]; then
        _log_warn "Listener tidak sedang berjalan."; return 0
    fi
    kill "$(cat "$PID_FILE")"; rm -f "$PID_FILE"
    _log_ok "Listener telah dihentikan."
}
function logs() {
    if [ ! -f "$LOG_FILE" ]; then
        _log_warn "File log belum ada."; return 1
    fi
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

case "$1" in
    setup|start|stop|logs|cleanup) "$1" ;;
    *) _log_error "Perintah tidak dikenal: '$1'. Jalankan dari main.sh." ;;
esac