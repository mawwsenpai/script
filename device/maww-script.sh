#!/usr/bin/env bash
# ==============================================================================
#                 MAWW SCRIPT V13 - FINAL COMPLETE EDITION
# ==============================================================================
# Deskripsi:
#   Versi final yang menggabungkan semua fitur: menu estetik, setup otomatis
#   dengan fallback manual, arsitektur konfigurasi yang bersih, dan semua
#   helper script dibuat secara dinamis.
#
# Dibuat oleh: Maww Senpai (dengan bantuan Gemini)
# Versi: 13.0
# ==============================================================================

# --- [ KONFIGURASI GLOBAL & FILE ] ---
set -e; set -o pipefail
readonly G_CREDS_FILE="credentials.json"
readonly G_TOKEN_FILE="token.json"
readonly CONFIG_FILE="config.json"
readonly PY_HELPER_TOKEN="handle_token.py"
readonly PY_LOCAL_SERVER="local_server.py"
readonly PY_LISTENER="gmail_listener.py"
readonly CONFIG_DEVICE="device.conf"
readonly PID_FILE="listener.pid"
readonly LOG_FILE="listener.log"
readonly PATCH_FLAG=".patch_installed"
readonly DOWNLOAD_DIR="$HOME/storage/shared/Download"

# --- [ PALET WARNA & TAMPILAN ] ---
readonly C_RESET='\033[0m'
readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m'
readonly C_PURPLE='\033[0;35m'; readonly C_CYAN='\033[0;36m'
readonly C_WHITE='\033[1;37m'; readonly C_BLACK='\033[0;30m'
readonly C_BG_PURPLE='\033[45m'; readonly C_BG_CYAN='\033[46m'

function _log() { local color="$1"; shift; echo -e "${color}│ $@${C_RESET}"; }
function _log_info() { _log "$C_CYAN" "$@"; }
function _log_ok() { _log "$C_GREEN" "$@"; }
function _log_warn() { _log "$C_YELLOW" "$@"; }
function _log_error() { _log "$C_RED" "$@"; }

# ==============================================================================
#                BAGIAN 1: GENERATOR SCRIPT PYTHON
# ==============================================================================

function _generate_local_server_py() {
cat << EOF > "$PY_LOCAL_SERVER"
import http.server, socketserver
from urllib.parse import urlparse, parse_qs

PORT = 8080
OUTPUT_FILE = "auth_code.tmp"

class MyRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        query_components = parse_qs(urlparse(self.path).query)
        if 'code' in query_components:
            auth_code = query_components["code"][0]
            with open(OUTPUT_FILE, "w") as f: f.write(auth_code)
            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(b"<html><head><title>Berhasil</title><style>body{font-family:sans-serif;background:#121212;color:#e0e0e0;display:flex;justify-content:center;align-items:center;height:100vh;}h1{color:#03DAC6;}</style></head>")
            self.wfile.write(b"<body><h1>&#9989; Kode diterima! Proses otomatis, silakan kembali ke Termux.</h1></body></html>")
            self.server.server_close()
        else:
            self.send_response(400); self.end_headers(); self.wfile.write(b"Parameter 'code' tidak ditemukan.")

with socketserver.TCPServer(("", PORT), MyRequestHandler) as server:
    server.serve_forever()
EOF
}

function _generate_handle_token_py() {
cat << EOF > "$PY_HELPER_TOKEN"
import sys, json, os
from google_auth_oauthlib.flow import InstalledAppFlow

if len(sys.argv) < 2:
    print("Penggunaan: python handle_token.py <auth_code>")
    sys.exit(1)

auth_code = sys.argv[1]
creds_file = "$G_CREDS_FILE"
token_file = "$G_TOKEN_FILE"
scopes = ['https://www.googleapis.com/auth/gmail.modify']

if not os.path.exists(creds_file):
    print(f"FATAL: File '{creds_file}' tidak ditemukan!")
    sys.exit(1)

try:
    flow = InstalledAppFlow.from_client_secrets_file(creds_file, scopes)
    flow.fetch_token(code=auth_code)
    
    credentials = flow.credentials
    with open(token_file, 'w') as token:
        token.write(credentials.to_json())
    
    print(f"SUKSES: File '{token_file}' berhasil dibuat.")
except Exception as e:
    print(f"ERROR: Gagal menukar kode dengan token. Detail: {e}")
    sys.exit(1)
EOF
}

function _generate_gmail_listener_py() {
source "$CONFIG_DEVICE"
cat << EOF > "$PY_LISTENER"
import os, sys, subprocess, logging, base64, time
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders

SCOPES = ['https://www.googleapis.com/auth/gmail.modify']
TOKEN_FILE = '$G_TOKEN_FILE'
MY_EMAIL = '$MY_EMAIL'
CMD_SUBJECT = '$CMD_SUBJECT'
LOG_FILE = '$LOG_FILE'
POLL_INTERVAL = 180

logging.basicConfig(level=logging.INFO, filename=LOG_FILE, filemode='a', format='%(asctime)s - %(levelname)s - %(message)s')

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
            reply_body = f"Hasil perintah 'lokasi':\n\n{result.stdout or 'Tidak ada output.'}"
        elif command == 'info':
            result = subprocess.run(["termux-device-info"], capture_output=True, text=True, timeout=15, check=True)
            reply_body = f"Info Perangkat:\n\n{result.stdout or 'Tidak ada output.'}"
        elif command == 'exit-listener':
            reply_body = "Perintah 'exit-listener' diterima. Listener akan berhenti."
            send_reply(service, msg_obj, reply_body); logging.info("Listener dihentikan melalui perintah remote."); sys.exit(0)
        else:
            reply_body = f"Perintah '{command}' tidak dikenali."
            
        send_reply(service, msg_obj, reply_body, output_file)
    except Exception as e:
        logging.error(f"Error saat eksekusi: {e}")
        send_reply(service, msg_obj, f"GAGAL: Terjadi error. Cek log di server.")
    finally:
        if output_file and os.path.exists(output_file):
            os.remove(output_file)

def main_loop():
    creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    service = build('gmail', 'v1', credentials=creds)
    logging.info("Listener service dimulai.")
    print("Listener kini berjalan di background...")
    while True:
        try:
            if not creds.valid:
                if creds.expired and creds.refresh_token:
                    from google.auth.transport.requests import Request
                    creds.refresh(Request())
                else:
                    logging.error("Token tidak valid dan tidak bisa di-refresh. Jalankan ulang setup."); sys.exit(1)

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
        except Exception as e:
            logging.error(f"Error pada loop utama: {e}")
            time.sleep(POLL_INTERVAL * 2)

if __name__ == '__main__':
    main_loop()
EOF
}

# ==============================================================================
#                      BAGIAN 2: LOGIKA INTI SKRIP
# ==============================================================================

function setup() {
    clear; display_header
    _log_warn "Memulai proses Setup..."
    stop >/dev/null 2>&1 || true
    rm -f "$G_TOKEN_FILE" "auth_code.tmp"
    
    # --- Kumpulkan Info User (device.conf) ---
    if [ ! -f "$CONFIG_DEVICE" ]; then
        _log_info "Konfigurasi perangkat tidak ditemukan. Membuat baru..."
        read -p "   - Masukkan Alamat Email Gmail Anda : " email_input
        read -p "   - Masukkan Subjek Perintah Rahasia : " subject_input
        echo "MY_EMAIL=\"$email_input\"" > "$CONFIG_DEVICE"
        echo "CMD_SUBJECT=\"$subject_input\"" >> "$CONFIG_DEVICE"
        _log_ok "   -> Konfigurasi disimpan di '$CONFIG_DEVICE'"
    else
        _log_ok "   -> Menggunakan konfigurasi perangkat yang ada."
    fi
    
    # --- Siapkan Kredensial & Konfigurasi (credentials.json & config.json) ---
    _log_info "Memeriksa file kredensial dan konfigurasi..."
    if [ ! -f "$G_CREDS_FILE" ]; then
        if [ -f "$DOWNLOAD_DIR/$G_CREDS_FILE" ]; then
            cp "$DOWNLOAD_DIR/$G_CREDS_FILE" .
            _log_ok "   -> '$G_CREDS_FILE' disalin dari folder Download."
        else
            _log_error "GAGAL: '$G_CREDS_FILE' tidak ditemukan di folder skrip atau Download."
            return 1
        fi
    fi

    # [PENINGKATAN] Otomatis buat config.json jika belum ada
    if [ ! -f "$CONFIG_FILE" ]; then
        _log_warn "   -> '$CONFIG_FILE' tidak ditemukan. Membuat secara otomatis..."
        local client_id_from_creds=$(grep -o '"client_id": *"[^"]*"' "$G_CREDS_FILE" | grep -o '"[^"]*"$' | tr -d '"')
        echo "{" > "$CONFIG_FILE"
        echo "    \"CLIENT_ID\": \"${client_id_from_creds}\"" >> "$CONFIG_FILE"
        echo "}" >> "$CONFIG_FILE"
        _log_ok "   -> '$CONFIG_FILE' berhasil dibuat dari '$G_CREDS_FILE'."
    fi

    # --- Proses Otentikasi Otomatis dengan Fallback ---
    _log_info "Membuat helper script..."
    _generate_local_server_py
    _generate_handle_token_py

    # [PERBAIKAN] Baca Client ID HANYA dari config.json
    local client_id=$(grep -o '"CLIENT_ID": *"[^"]*"' "$CONFIG_FILE" | grep -o '"[^"]*"$' | tr -d '"')
    if [ -z "$client_id" ]; then
        _log_error "GAGAL: CLIENT_ID tidak ditemukan di $CONFIG_FILE."
        return 1
    fi
    _log_ok "   -> Client ID berhasil dibaca dari $CONFIG_FILE."

    _log_info "Mencoba mode otentikasi otomatis..."
    python "$PY_LOCAL_SERVER" &
    local server_pid=$!
    
    local scope="https://www.googleapis.com/auth/gmail.modify"
    local redirect_uri="http://localhost:8080"
    local auth_url="https://accounts.google.com/o/oauth2/v2/auth?scope=${scope}&redirect_uri=${redirect_uri}&response_type=code&client_id=${client_id}&access_type=offline&prompt=consent"
    
    termux-open-url "$auth_url"
    _log_warn "Menunggu kode dari browser (maksimal 60 detik)..."
    timeout 60s wait $server_pid 2>/dev/null

    if [ -f "auth_code.tmp" ]; then
        _log_ok "Kode otorisasi diterima secara otomatis!"
        local auth_code=$(cat "auth_code.tmp")
        rm "auth_code.tmp"
        python "$PY_HELPER_TOKEN" "$auth_code"
    else
        kill $server_pid 2>/dev/null || true
        _log_error "Mode otomatis gagal atau timeout."
        _log_warn "Silakan otorisasi secara manual."
        python -m webbrowser -t "$auth_url"
        read -p "   - Salin kode dari browser dan paste di sini: " manual_code
        python "$PY_HELPER_TOKEN" "$manual_code"
    fi

    if [ -f "$G_TOKEN_FILE" ]; then
        _log_ok "🎉 SETUP SELESAI! Otorisasi berhasil."
    else
        _log_error "SETUP GAGAL. Token tidak berhasil dibuat."
    fi
}


function start() {
    clear; display_header
    _log_info "Mencoba memulai listener..."
    if [ ! -f "$CONFIG_DEVICE" ] || [ ! -f "$G_TOKEN_FILE" ]; then
        _log_error "Konfigurasi/token tidak ditemukan. Jalankan 'Setup' (⚙️) dulu."
        return 1
    fi
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        _log_warn "Listener sudah berjalan."
        return 0
    fi
    
    _generate_gmail_listener_py
    nohup python "$PY_LISTENER" >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    _log_ok "Listener dimulai (PID: $(cat "$PID_FILE")). Log disimpan di '$LOG_FILE'."
}

function stop() {
    clear; display_header
    _log_info "Mencoba menghentikan listener..."
    if [ ! -f "$PID_FILE" ]; then
        _log_warn "Listener tidak sedang berjalan (tidak ada PID file)."
        return 0
    fi
    local pid=$(cat "$PID_FILE")
    if ps -p "$pid" > /dev/null; then
        kill "$pid"
        rm -f "$PID_FILE"
        _log_ok "Listener (PID: $pid) telah dihentikan."
    else
        _log_warn "Proses listener (PID: $pid) tidak ditemukan. Menghapus PID file."
        rm -f "$PID_FILE"
    fi
}

function logs() {
    clear; display_header
    if [ ! -f "$LOG_FILE" ]; then
        _log_warn "File log belum ada. Coba jalankan listener dulu."
        return 1
    fi
    _log_info "Menampilkan log (tekan Ctrl+C untuk keluar)..."
    echo -e "${C_PURPLE}╭──────────────────────────────────────────────────╮${C_RESET}"
    tail -f "$LOG_FILE"
}

function cleanup() {
    clear; display_header
    _log_warn "PERINGATAN: Ini akan menghapus SEMUA file konfigurasi,"
    _log_warn "token, dan log yang dihasilkan oleh skrip ini."
    read -p "   Anda yakin ingin melanjutkan? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        stop >/dev/null 2>&1 || true
        _log_info "Menghapus file..."
        rm -f "$CONFIG_DEVICE" "$G_TOKEN_FILE" "$G_CREDS_FILE" "$CONFIG_FILE" \
              "$PY_HELPER_TOKEN" "$PY_LISTENER" "$PY_LOCAL_SERVER" \
              "$PID_FILE" "$LOG_FILE" "auth_code.tmp"
        _log_ok "Pembersihan selesai."
    else
        _log_info "Pembersihan dibatalkan."
    fi
}

function run_patcher() {
    clear; display_header
    _log_info "Memulai Proses Perbaikan & Persiapan Lingkungan..."
    
    readonly TERMUX_PACKAGES=( "python" "termux-api" "coreutils" )
    readonly PYTHON_REQUIREMENTS=( 
        "google-api-python-client==2.100.0" 
        "google-auth-httplib2==0.2.0" 
        "google-auth-oauthlib==1.2.0" 
    )
    
    _log_info "LANGKAH 1/3: Menginstal paket sistem Termux..."
    pkg update -y >/dev/null 2>&1
    pkg install -y "${TERMUX_PACKAGES[@]}" || { _log_error "Gagal menginstal paket sistem."; exit 1; }
    _log_ok "   -> Paket sistem berhasil dikonfigurasi."

    _log_info "LANGKAH 2/3: Menginstal library Python..."
    pip install --no-cache-dir --force-reinstall "${PYTHON_REQUIREMENTS[@]}" || { _log_error "Gagal menginstal library Python."; exit 1; }
    _log_ok "   -> Semua library Python berhasil diinstal."

    _log_info "LANGKAH 3/3: Mengonfigurasi izin penyimpanan..."
    if [ ! -d "$HOME/storage/shared" ]; then
        termux-setup-storage
        sleep 5 
    fi
    _log_ok "   -> Izin penyimpanan siap."
    
    echo
    _log_ok "✅ LINGKUNGAN SUDAH SIAP! ✅"
    touch "$PATCH_FLAG_FILE"
}

# ==============================================================================
#                      BAGIAN 3: TAMPILAN MENU & MAIN
# ==============================================================================

function display_header() {
    echo -e "${C_PURPLE}"
    echo '  ╭──────────────────────────────────────────────────╮'
    echo -e "  │ ${C_BG_PURPLE}${C_WHITE}    ⓂⒶⓌⓌ - ⓈⒸⓇⒾⓅⓉ  v13 (Final)         ${C_RESET}${C_PURPLE} │"
    echo '  ├──────────────────────────────────────────────────┤'
    local status_text; local status_color
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        status_text="    A K T I F    "
        status_color="$C_GREEN"
        pid_text="(PID: $(cat "$PID_FILE"))"
    else
        status_text="  TIDAK AKTIF  "
        status_color="$C_RED"
        pid_text=""
    fi
    echo -e "  │ ${C_WHITE}Status   :${C_RESET} ${status_color}${status_text}${C_RESET} ${C_YELLOW}${pid_text}${C_RESET}                     ${C_PURPLE}│"
    echo '  ╰──────────────────────────────────────────────────╯'
    echo -e "${C_RESET}"
}

function display_menu() {
    echo -e "${C_CYAN}  ╭─ Pilihan Menu ───────────────────────────────╮${C_RESET}"
    echo -e "${C_CYAN}  │                                              │${C_RESET}"
    echo -e "${C_CYAN}  │   ${C_GREEN}🚀  Mulai Listener${C_RESET}                         │${C_RESET}"
    echo -e "${C_CYAN}  │   ${C_RED}🛑  Hentikan Listener${C_RESET}                      │${C_RESET}"
    echo -e "${C_CYAN}  │                                              │${C_RESET}"
    echo -e "${C_CYAN}  │   ${C_YELLOW}⚙️   Setup / Konfigurasi Ulang${C_RESET}            │${C_RESET}"
    echo -e "${C_CYAN}  │   ${C_PURPLE}📜  Lihat Log Realtime${C_RESET}                     │${C_RESET}"
    echo -e "${C_CYAN}  │                                              │${C_RESET}"
    echo -e "${C_CYAN}  │   ${C_BLUE}🔧  Perbaiki Lingkungan${C_RESET}                  │${C_RESET}"
    echo -e "${C_CYAN}  │   ${C_RED}🗑️   Hapus Semua Konfigurasi${C_RESET}              │${C_RESET}"
    echo -e "${C_CYAN}  │                                              │${C_RESET}"
    echo -e "${C_CYAN}  │   ${C_WHITE}🚪  Keluar${C_RESET}                                 │${C_RESET}"
    echo -e "${C_CYAN}  │                                              │${C_RESET}"
    echo -e "${C_CYAN}  ╰──────────────────────────────────────────────╯${C_RESET}"

    echo -en "\n${C_BG_CYAN}${C_BLACK}  Pilih Opsi ❯ ${C_RESET} "; read -n 1 choice
    echo # Newline
    
    case $choice in
        '🚀') start;;
        '🛑') stop;;
        '⚙️') setup;;
        '📜') logs;;
        '🔧') run_patcher;;
        '🗑️') cleanup;;
        '🚪') echo -e "\n${C_PURPLE}Sampai jumpa lagi, Senpai!${C_RESET}"; exit 0;;
        *) echo -e "\n${C_RED}Pilihan tidak valid. Gunakan emoji di sebelah kiri.${C_RESET}";;
    esac
    echo -e "\n${C_YELLOW}Tekan [Enter] untuk kembali ke menu...${C_RESET}"; read -r
}

function main() {
    if [ ! -f "$PATCH_FLAG_FILE" ]; then
        clear; display_header
        _log_warn "Ini adalah eksekusi pertama kali."
        _log_info "Skrip akan menyiapkan lingkungan Anda secara otomatis."
        read -p "   Tekan [Enter] untuk memulai..."
        run_patcher
        _log_ok "Persiapan lingkungan selesai!"
        read -p "   Tekan [Enter] untuk melanjutkan ke menu utama..."
    fi

    while true; do
        clear
        display_header
        display_menu
    done
}

# --- [ MULAI EKSEKUSI ] ---
main
