#!/usr/bin/env bash

# ==============================================================================
#                 MAWW SCRIPT V4 - PROFESSIONAL CORE ENGINE
# ==============================================================================
# Deskripsi:
#   Skrip ini berisi semua logika inti (setup, start, stop, dll.).
#   Tidak untuk dijalankan langsung, tetapi dipanggil oleh 'main.sh'.
#
# Dibuat oleh: Gemini @ Google
# Versi: 4.0 (Professional Refactor)
# ==============================================================================

# --- [ KONFIGURASI SCRIPT & GLOBAL ] ---
set -e
set -o pipefail

# Konfigurasi nama file dan direktori
readonly CONFIG_FILE="device.conf"
readonly PYTHON_SCRIPT="gmail_listener.py"
readonly PID_FILE="listener.pid"
readonly LOG_FILE="listener.log"
readonly TOKEN_FILE="token.json"
readonly CREDS_FILENAME="credentials.json"
readonly CREDS_DEST_DIR="$HOME/storage/shared/Automatic"
readonly CREDS_FILE_PATH="$CREDS_DEST_DIR/$CREDS_FILENAME"
readonly POLL_INTERVAL=300 # Detik

# --- [ KODE WARNA ANSI & FUNGSI LOGGING ] ---
readonly C_RESET='\033[0m'
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_BLUE='\033[0;34m'

# Fungsi logging untuk output yang konsisten
function _log()     { local color="$1"; shift; echo -e "${color}[*] $@${C_RESET}"; }
function _log_info()  { _log "$C_BLUE" "$@"; }
function _log_ok()    { _log "$C_GREEN" "$@"; }
function _log_warn()  { _log "$C_YELLOW" "$@"; }
function _log_error() { _log "$C_RED" "$@"; }


# --- [ FUNGSI-FUNGSI LOGIKA INTI ] ---

# Memeriksa dan menginstal semua dependensi yang diperlukan
function check_dependencies() {
    _log_info "Memulai pengecekan dependensi sistem..."
    local pkg_needed=0
    
    # 1. Dependensi Termux
    _log_info "1. Memeriksa paket Termux..."
    for pkg in python termux-api coreutils dos2unix; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            _log_warn "   - Paket '$pkg' tidak ditemukan."
            pkg_needed=1
        fi
    done
    if [ $pkg_needed -eq 1 ]; then
        _log_info "Menginstal paket Termux yang dibutuhkan..."
        pkg install -y python termux-api coreutils dos2unix || { _log_error "Gagal menginstal paket Termux."; exit 1; }
    fi
    _log_ok "   Semua paket Termux sudah terinstal."

    # 2. Dependensi Python (pip)
    _log_info "2. Memeriksa library Python..."
    if ! pip show google-api-python-client > /dev/null 2>&1; then
        _log_warn "   - Library Google API tidak ditemukan."
        _log_info "Menginstal library Python... (membutuhkan koneksi internet)"
        pip install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib || { _log_error "Gagal menginstal library Python."; exit 1; }
    fi
    _log_ok "   Semua library Python sudah terinstal."
    
    # 3. Izin Penyimpanan
    _log_info "3. Memeriksa izin penyimpanan..."
    if [ ! -d "$HOME/storage/shared" ]; then
        _log_warn "   - Izin penyimpanan belum diberikan."
        _log_info "Meminta izin penyimpanan Termux..."
        termux-setup-storage
    fi
    _log_ok "   Izin penyimpanan sudah dikonfigurasi."
    _log_ok "Pengecekan dependensi selesai."
}

# Proses setup dan konfigurasi awal yang cerdas
function setup() {
    clear
    _log_info "--- Memulai Proses Setup & Konfigurasi ---"
    
    # Hentikan proses yang mungkin masih berjalan dan hapus token lama
    stop >/dev/null 2>&1 || true # Hentikan, abaikan jika gagal
    rm -f "$TOKEN_FILE"

    # Langkah 1: Kumpulkan informasi dari pengguna
    _log_info "Langkah 1/3: Mengumpulkan Detail Akun..."
    read -p "   - Masukkan Alamat Email Gmail Anda : " email_input
    read -p "   - Masukkan Subjek Perintah Rahasia : " subject_input
    if [[ -z "$email_input" || -z "$subject_input" ]]; then
        _log_error "Email dan Subjek tidak boleh kosong. Setup dibatalkan."
        exit 1
    fi
    echo "MY_EMAIL=\"$email_input\"" > "$CONFIG_FILE"
    echo "CMD_SUBJECT=\"$subject_input\"" >> "$CONFIG_FILE"
    _log_ok "   Detail akun berhasil disimpan di '$CONFIG_FILE'."

    # Langkah 2: Otomatis mencari dan menyiapkan file kredensial
    _log_info "Langkah 2/3: Mencari & Menyiapkan File Kredensial..."
    mkdir -p "$CREDS_DEST_DIR"
    
    if [ ! -f "$CREDS_FILE_PATH" ]; then
        _log_warn "   File '$CREDS_FILENAME' tidak ditemukan di lokasi default."
        _log_info "   Mencari file di seluruh penyimpanan internal... Mohon tunggu..."
        
        local search_results
        readarray -t search_results < <(find "$HOME/storage/shared" -iname "$CREDS_FILENAME" 2>/dev/null)
        
        if [ ${#search_results[@]} -eq 0 ]; then
            _log_error "PENCARIAN GAGAL: File '$CREDS_FILENAME' tidak ditemukan."
            _log_error "Pastikan Anda sudah men-download file dari Google Cloud dan menyimpannya di HP Anda."
            exit 1
        fi
        
        local target_file="${search_results[0]}"
        cp "$target_file" "$CREDS_FILE_PATH"
        _log_ok "   File ditemukan di '$target_file' dan otomatis disalin ke tujuan."
    else
        _log_ok "   File '$CREDS_FILENAME' sudah ada di lokasi yang benar."
    fi

    # Langkah 3: Otorisasi akun melalui Google
    _log_info "Langkah 3/3: Otorisasi Akun Google..."
    _generate_python_script
    _log_info "Ikuti instruksi di bawah untuk memberikan izin:"
    echo -e "   1. ${C_YELLOW}SALIN${C_RESET} link yang akan muncul di bawah."
    echo -e "   2. ${C_YELLOW}BUKA${C_RESET} link tersebut di browser."
    echo -e "   3. Login dan berikan izin (Allow)."
    echo -e "   4. Google akan memberikan sebuah KODE."
    echo -e "   5. ${C_YELLOW}SALIN${C_RESET} kode tersebut dan ${C_YELLOW}TEMPEL (PASTE)${C_RESET} kembali ke sini."
    
    # Jalankan otorisasi
    if python "$PYTHON_SCRIPT"; then
        if [ -f "$TOKEN_FILE" ]; then
            _log_ok "🎉 SETUP SELESAI! Otorisasi berhasil. Anda siap memulai listener."
        else
            # Kondisi ini seharusnya tidak terjadi jika python exit dengan sukses, tapi sebagai pengaman
            _log_error "SETUP GAGAL. Token otorisasi tidak berhasil dibuat."
            exit 1
        fi
    else
        _log_error "SETUP GAGAL. Proses otorisasi Python gagal. Pastikan Anda memasukkan kode dengan benar."
        exit 1
    fi
}

# Memulai listener di background
function start() {
    _log_info "Mencoba memulai listener..."
    if [ ! -f "$CONFIG_FILE" ] || [ ! -f "$TOKEN_FILE" ]; then
        _log_error "Konfigurasi atau token otorisasi tidak ditemukan."
        _log_warn "Silakan jalankan 'Setup' (pilihan 3) terlebih dahulu."
        return 1
    fi

    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        _log_warn "Listener sudah dalam keadaan berjalan (PID: $(cat "$PID_FILE"))."
        return 0
    fi
    
    _generate_python_script
    nohup python "$PYTHON_SCRIPT" >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    _log_ok "Listener berhasil dimulai di background (PID: $(cat "$PID_FILE"))."
}

# Menghentikan listener yang sedang berjalan
function stop() {
    _log_info "Mencoba menghentikan listener..."
    if [ ! -f "$PID_FILE" ]; then
        _log_warn "Listener memang tidak sedang berjalan."; return 0
    fi
    
    local pid_to_kill
    pid_to_kill=$(cat "$PID_FILE")
    # Cek apakah proses benar-benar ada sebelum mencoba kill
    if ps -p "$pid_to_kill" > /dev/null; then
        kill "$pid_to_kill"
        rm -f "$PID_FILE"
        _log_ok "Listener (PID: $pid_to_kill) telah dihentikan."
    else
        _log_warn "File PID ditemukan, tetapi prosesnya tidak berjalan. Membersihkan file PID."
        rm -f "$PID_FILE"
    fi
}

# Menampilkan log secara realtime
function logs() {
    if [ ! -f "$LOG_FILE" ]; then
        _log_warn "File log belum ada. Coba jalankan listener terlebih dahulu."
        return 1
    fi
    _log_info "Menampilkan log (Tekan Ctrl+C untuk keluar)..."
    tail -f "$LOG_FILE"
}

# Menghapus semua file konfigurasi yang dihasilkan skrip
function cleanup() {
    _log_warn "--- PEMBERSIHAN TOTAL ---"
    read -p "Anda YAKIN ingin menghapus semua file konfigurasi? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        stop >/dev/null 2>&1 || true
        _log_info "Menghapus file: $CONFIG_FILE, $LOG_FILE, $PYTHON_SCRIPT, $TOKEN_FILE, $PID_FILE"
        rm -f "$CONFIG_FILE" "$LOG_FILE" "$PYTHON_SCRIPT" "$TOKEN_FILE" "$PID_FILE"
        _log_ok "Pembersihan selesai."
        _log_warn "File '$CREDS_FILENAME' di folder 'Automatic' tidak dihapus."
    else
        _log_info "Pembersihan dibatalkan."
    fi
}

# Fungsi internal untuk menghasilkan skrip Python dari template
function _generate_python_script() {
    # Pastikan file konfigurasi ada sebelum mencoba membacanya
    if [ ! -f "$CONFIG_FILE" ]; then
        _log_error "File konfigurasi '$CONFIG_FILE' tidak ditemukan. Jalankan setup terlebih dahulu."
        exit 1
    fi
    source "$CONFIG_FILE"

    # Template skrip Python (Heredoc)
    cat << EOF > "$PYTHON_SCRIPT"
# -*- coding: utf-8 -*-
# Dibuat otomatis oleh core.sh - JANGAN EDIT MANUAL
import os, subprocess, time, logging, sys, base64
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# --- KONFIGURASI ---
SCOPES = ['https://www.googleapis.com/auth/gmail.modify']
MY_EMAIL = "$MY_EMAIL"
CMD_SUBJECT = "$CMD_SUBJECT"
TOKEN_FILE = "$TOKEN_FILE"
CREDS_FILE = "$CREDS_FILE_PATH"
LOG_FILE = "$LOG_FILE"
POLL_INTERVAL = $POLL_INTERVAL

# Konfigurasi logging
logging.basicConfig(level=logging.INFO, filename=LOG_FILE, filemode='a', 
                    format='%(asctime)s - %(levelname)s - %(message)s')

def get_gmail_service():
    """Mengautentikasi dan mengembalikan objek service Gmail."""
    creds = None
    try:
        if os.path.exists(TOKEN_FILE):
            creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                if not os.path.exists(CREDS_FILE):
                    logging.error(f"FATAL: File kredensial tidak ditemukan di '{CREDS_FILE}'!")
                    sys.exit(1)
                flow = InstalledAppFlow.from_client_secrets_file(CREDS_FILE, SCOPES)
                creds = flow.run_console()
            with open(TOKEN_FILE, 'w') as token:
                token.write(creds.to_json())
        return build('gmail', 'v1', credentials=creds)
    except Exception as e:
        logging.critical(f"Gagal mendapatkan service Gmail: {e}")
        print(f"ERROR: Gagal otorisasi. Detail: {e}", file=sys.stderr)
        sys.exit(1)

def send_reply(service, original_message, body_text, attachment_path=None):
    """Mengirim email balasan."""
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
    """Mengeksekusi perintah yang diterima dari email."""
    try:
        command = full_command.split(':')[1].strip().lower()
        logging.info(f"Mengeksekusi perintah: '{command}'")
        output_file, reply_body = None, f"Perintah '{command}' telah selesai dieksekusi."
        
        # Daftar Perintah
        if command == 'ss':
            output_file, reply_body = os.path.expanduser("~/screenshot.png"), "Screenshot terlampir."
            subprocess.run(["termux-screenshot", output_file], timeout=20, check=True)
        elif command == 'foto':
            output_file, reply_body = os.path.expanduser("~/photo.jpg"), "Foto terlampir."
            subprocess.run(["termux-camera-photo", "-c", "0", output_file], timeout=25, check=True)
        elif command == 'lokasi':
            result = subprocess.run(["termux-location"], capture_output=True, text=True, timeout=30, check=True)
            reply_body = f"Hasil perintah 'lokasi':\n\n{result.stdout or 'Tidak ada output.'}"
        elif command == 'info':
            result = subprocess.run(["termux-device-info"], capture_output=True, text=True, timeout=15, check=True)
            reply_body = f"Info Perangkat:\n\n{result.stdout or 'Tidak ada output.'}"
        elif command == 'exit-listener':
            reply_body = "Perintah 'exit-listener' diterima. Listener akan berhenti."
            send_reply(service, msg_obj, reply_body)
            logging.info("Listener dihentikan melalui perintah remote 'exit-listener'.")
            sys.exit(0)
        else:
            reply_body = f"Perintah '{command}' tidak dikenali."
        
        send_reply(service, msg_obj, reply_body, output_file)
    except subprocess.TimeoutExpired:
        logging.error(f"Perintah '{command}' timeout.")
        send_reply(service, msg_obj, f"GAGAL: Perintah '{command}' memakan waktu terlalu lama (timeout).")
    except subprocess.CalledProcessError as e:
        logging.error(f"Perintah '{command}' gagal dengan error: {e.stderr}")
        send_reply(service, msg_obj, f"GAGAL: Perintah '{command}' menghasilkan error.\n\n{e.stderr}")
    except Exception as e:
        logging.error(f"Error tidak terduga saat eksekusi: {e}")
        send_reply(service, msg_obj, f"GAGAL: Terjadi error tidak terduga. Cek log untuk detail.")
    finally:
        if output_file and os.path.exists(output_file):
            os.remove(output_file)

def main_loop():
    """Loop utama untuk memeriksa perintah baru."""
    logging.info("Listener service dimulai.")
    print("Otorisasi berhasil. Listener kini berjalan di background.")
    print(f"Anda bisa memantau aktivitas melalui log di: {LOG_FILE}")
    
    service = get_gmail_service()
    
    while True:
        try:
            q = f"from:{MY_EMAIL} is:unread subject:'{CMD_SUBJECT}'"
            results = service.users().messages().list(userId='me', labelIds=['INBOX'], q=q).execute()
            messages = results.get('messages', [])
            
            for message_info in messages:
                msg_id = message_info['id']
                msg_obj = service.users().messages().get(userId='me', id=msg_id).execute()
                if msg_obj:
                    execute_command(service, msg_obj, msg_obj['snippet'])
                    service.users().messages().modify(userId='me', id=msg_id, body={'removeLabelIds': ['UNREAD']}).execute()
            
            time.sleep(POLL_INTERVAL)
        except HttpError as e:
            if e.resp.status == 401:
                logging.error("Otorisasi Gagal (401). Mencoba refresh token...")
                service = get_gmail_service() # Coba re-autentikasi
            else:
                logging.error(f"HttpError: {e}")
                time.sleep(POLL_INTERVAL * 2) # Tunggu lebih lama jika ada error lain
        except Exception as e:
            logging.error(f"Terjadi error pada loop utama: {e}")
            time.sleep(POLL_INTERVAL * 2)

if __name__ == '__main__':
    # Cek jika dipanggil untuk otorisasi saja
    if not os.path.exists(TOKEN_FILE):
        print("Memulai otorisasi awal...")
        get_gmail_service()
    else: # Jika tidak, jalankan loop utama
        main_loop()

EOF
}


# --- [ ROUTER PERINTAH ] ---
# Titik masuk utama skrip. Membaca argumen pertama ($1) dari main.sh
# dan menjalankan fungsi yang sesuai.

# Pastikan ada argumen yang diberikan
if [ -z "$1" ]; then
    _log_error "Skrip ini tidak untuk dijalankan langsung."
    _log_warn "Silakan jalankan melalui './main.sh'."
    exit 1
fi

# Jalankan fungsi berdasarkan argumen
case "$1" in
    check_dependencies) check_dependencies ;;
    setup) setup ;;
    start) start ;;
    stop) stop ;;
    logs) logs ;;
    cleanup) cleanup ;;
    *)
        _log_error "Perintah tidak dikenal: '$1'"
        exit 1
        ;;
esac