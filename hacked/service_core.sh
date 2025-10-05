#!/bin/bash

# =================================================================================
#            💖 M A W W  S C R I P T  V 3 - Mesin Inti (Core Engine) 💖
# =================================================================================
# File ini berisi semua logika inti: setup, start, stop, dll.
# Dipanggil oleh main.sh.
# =================================================================================

# --- [ KONFIGURASI FILE & DIREKTORI ] ---
CONFIG_FILE="device.conf"
PYTHON_SCRIPT="gmail_listener.py"
PID_FILE="listener.pid"
LOG_FILE="listener.log"
TOKEN_FILE="token.json"
CREDS_FILENAME="credentials.json"
# Folder tujuan untuk kredensial, akan dibuat otomatis
CREDS_DEST_DIR="$HOME/storage/shared/Automatic"
CREDS_FILE_PATH="$CREDS_DEST_DIR/$CREDS_FILENAME"
POLL_INTERVAL=300 # Waktu tunggu antar cek email (dalam detik)

# --- [ WARNA UNTUK LOGGING ] ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_WHITE='\033[1;37m'
C_NC='\033[0m'

# --- [ FUNGSI-FUNGSI UTAMA ] ---

# Fungsi untuk memeriksa dan menginstal dependensi yang dibutuhkan
func_check_dependencies() {
    echo -e "${C_CYAN}--- 🔧 Memeriksa Kebutuhan Sistem 🔧 ---${C_NC}"
    local needs_install=0
    
    # Dependensi Termux
    local termux_pkgs="python termux-api coreutils dos2unix"
    echo -e "\n${C_WHITE}1. Memeriksa paket Termux...${C_NC}"
    for pkg in $termux_pkgs; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            echo -e "   [${C_GREEN}OK${C_NC}] $pkg"
        else
            echo -e "   [${C_RED}MISSING${C_NC}] $pkg"
            needs_install=1
        fi
    done
    if [ $needs_install -eq 1 ]; then
        echo -e "${C_YELLOW}Menginstal paket yang kurang...${C_NC}"
        pkg install -y $termux_pkgs
    fi

    # Dependensi Python
    local python_libs="google-api-python-client google-auth-httplib2 google-auth-oauthlib"
    echo -e "\n${C_WHITE}2. Memeriksa library Python...${C_NC}"
    if ! pip show google-api-python-client > /dev/null 2>&1; then
        echo -e "   [${C_RED}MISSING${C_NC}] Google API Libraries"
        echo -e "${C_YELLOW}Menginstal library Python... (butuh koneksi internet)${C_NC}"
        pip install --upgrade $python_libs
    else
        echo -e "   [${C_GREEN}OK${C_NC}] Google API Libraries"
    fi

    # Izin Penyimpanan
    echo -e "\n${C_WHITE}3. Memeriksa izin penyimpanan...${C_NC}"
    if [ ! -d "$HOME/storage/shared" ]; then
        echo -e "   [${C_RED}MISSING${C_NC}] Izin penyimpanan belum diberikan."
        echo -e "${C_YELLOW}Meminta izin penyimpanan...${C_NC}"
        termux-setup-storage
    else
        echo -e "   [${C_GREEN}OK${C_NC}] Izin penyimpanan sudah ada."
    fi
    echo -e "\n${C_GREEN}Pengecekan dependensi selesai.${C_NC}"
}

# Fungsi setup yang lebih cerdas dan otomatis
func_setup() {
    clear
    echo -e "${C_CYAN}--- 🛠️ Setup & Konfigurasi Awal 🛠️ ---${C_NC}"
    
    # Hentikan listener jika sedang berjalan
    func_stop >/dev/null 2>&1
    # Hapus token lama untuk otorisasi ulang
    rm -f "$TOKEN_FILE"

    # LANGKAH 1: Input Pengguna
    echo -e "\n${C_WHITE}1. Masukkan Detail Akun Gmail${C_NC}"
    read -p "   - Alamat Email Anda: " email_input
    read -p "   - Subjek Perintah Rahasia: " subject_input
    if [[ -z "$email_input" || -z "$subject_input" ]]; then
        echo -e "${C_RED}ERROR: Email dan Subjek tidak boleh kosong. Setup dibatalkan.${C_NC}"; return 1
    fi
    echo "MY_EMAIL=\"$email_input\"" > "$CONFIG_FILE"
    echo "CMD_SUBJECT=\"$subject_input\"" >> "$CONFIG_FILE"

    # LANGKAH 2: Mencari dan Menyiapkan Kredensial (Otomatis)
    echo -e "\n${C_WHITE}2. Menyiapkan File Kredensial API${C_NC}"
    mkdir -p "$CREDS_DEST_DIR" # Buat folder tujuan jika belum ada
    
    if [ ! -f "$CREDS_FILE_PATH" ]; then
        echo -e "${C_YELLOW}   File '${CREDS_FILENAME}' tidak ditemukan di lokasi default.${C_NC}"
        echo -e "${C_CYAN}   Mencari file di seluruh penyimpanan... Mohon tunggu...${C_NC}"
        
        local search_results
        readarray -t search_results < <(find "$HOME/storage/shared" -iname "$CREDS_FILENAME" 2>/dev/null)
        
        if [ ${#search_results[@]} -eq 0 ]; then
            echo -e "${C_RED}   GAGAL: File '${CREDS_FILENAME}' tidak ditemukan di manapun!${C_NC}"
            echo "   Pastikan Anda sudah men-download file tersebut dan letakkan di memori internal."
            return 1
        else
            local target_file="${search_results[0]}"
            echo -e "${C_GREEN}   SUKSES: File ditemukan di:${C_NC} $target_file"
            cp "$target_file" "$CREDS_FILE_PATH"
            echo -e "${C_GREEN}   File telah otomatis disalin ke lokasi yang benar.${C_NC}"
        fi
    else
        echo -e "${C_GREEN}   File '${CREDS_FILENAME}' sudah ada di lokasi yang benar.${C_NC}"
    fi

    # LANGKAH 3: Otorisasi Akun
    echo -e "\n${C_WHITE}3. Otorisasi Akun Google (Satu Kali)${C_NC}"
    func_generate_python_script
    echo "   Sebuah link akan muncul. Salin, buka di browser, lalu berikan izin."
    python "$PYTHON_SCRIPT"

    if [ -f "$TOKEN_FILE" ]; then
        echo -e "\n${C_GREEN}🎉 SETUP SELESAI! Otorisasi berhasil. Anda siap memulai listener.${C_NC}"
    else
        echo -e "\n${C_RED}😭 SETUP GAGAL. Pastikan Anda memberikan izin dengan benar di browser.${C_NC}"
    fi
}

# Fungsi untuk memulai listener di background
func_start() {
    echo -e "${C_CYAN}--- ▶️ Memulai Listener ---${C_NC}"
    if [ ! -f "$CONFIG_FILE" ] || [ ! -f "$TOKEN_FILE" ]; then
        echo -e "${C_RED}Konfigurasi atau token otorisasi tidak ditemukan.${C_NC}"
        echo -e "${C_YELLOW}Silakan jalankan 'Setup' terlebih dahulu.${C_NC}"; return 1
    fi
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        echo -e "${C_YELLOW}Listener sudah berjalan.${C_NC}"; return 0
    fi
    
    func_generate_python_script
    nohup python "$PYTHON_SCRIPT" >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    echo -e "${C_GREEN}Listener berhasil dimulai di background (PID: $(cat "$PID_FILE")).${C_NC}"
}

# Fungsi untuk menghentikan listener
func_stop() {
    echo -e "${C_CYAN}--- ⏹️ Menghentikan Listener ---${C_NC}"
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${C_YELLOW}Listener memang tidak sedang berjalan.${C_NC}"; return 0
    fi
    
    local pid_to_kill=$(cat "$PID_FILE")
    kill "$pid_to_kill" >/dev/null 2>&1
    rm -f "$PID_FILE"
    echo -e "${C_GREEN}Listener (PID: $pid_to_kill) telah dihentikan.${C_NC}"
}

# Fungsi untuk menampilkan log secara realtime
func_logs() {
    echo -e "${C_CYAN}--- 📜 Menampilkan Log (Tekan Ctrl+C untuk keluar) 📜 ---${C_NC}"
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        echo -e "${C_YELLOW}File log belum ada. Coba jalankan listener terlebih dahulu.${C_NC}"
    fi
}

# Fungsi untuk membersihkan semua file konfigurasi
func_cleanup() {
    echo -e "${C_RED}--- 🗑️ PEMBERSIHAN TOTAL 🗑️ ---${C_NC}"
    read -p "Anda YAKIN ingin menghapus semua konfigurasi? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        func_stop >/dev/null 2>&1
        rm -f "$CONFIG_FILE" "$LOG_FILE" "$PYTHON_SCRIPT" "$TOKEN_FILE" "$PID_FILE"
        echo -e "${C_GREEN}Semua file konfigurasi telah dihapus.${C_NC}"
        echo -e "${C_YELLOW}File '${CREDS_FILENAME}' di folder 'Automatic' tidak dihapus.${C_NC}"
    else
        echo -e "${C_GREEN}Pembersihan dibatalkan.${C_NC}"
    fi
}


# Fungsi untuk menghasilkan skrip Python (tidak perlu diubah)
func_generate_python_script() {
    source "$CONFIG_FILE"
    cat << EOF > "$PYTHON_SCRIPT"
# -*- coding: utf-8 -*-
import os, subprocess, time, logging, base64
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = ['https://www.googleapis.com/auth/gmail.modify']
MY_EMAIL = "$MY_EMAIL"
CMD_SUBJECT = "$CMD_SUBJECT"
TOKEN_FILE = "$TOKEN_FILE"
CREDS_FILE = "$CREDS_FILE_PATH"

logging.basicConfig(level=logging.INFO, filename='$LOG_FILE', filemode='a', format='%(asctime)s - %(levelname)s - %(message)s')

def get_gmail_service():
    creds = None
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not os.path.exists(CREDS_FILE):
                logging.error(f"FATAL: File kredensial tidak ditemukan di '{CREDS_FILE}'!")
                exit(1)
            flow = InstalledAppFlow.from_client_secrets_file(CREDS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())
    return build('gmail', 'v1', credentials=creds)

def send_reply(service, original_message, body_text, attachment_path=None):
    try:
        headers = original_message['payload']['headers']
        to_email = next(h['value'] for h in headers if h['name'] == 'From')
        subject = "Re: " + next(h['value'] for h in headers if h['name'] == 'Subject')
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
        logging.info(f"Mengeksekusi perintah: {command}")
        output_file, reply_body = None, f"Perintah '{command}' telah dieksekusi."
        
        if command == 'ss':
            output_file, reply_body = os.path.expanduser("~/screenshot.png"), "Screenshot terlampir."
            subprocess.run(["termux-screenshot", output_file], timeout=15, check=True)
        elif command == 'foto':
            output_file, reply_body = os.path.expanduser("~/photo.jpg"), "Foto terlampir."
            subprocess.run(["termux-camera-photo", "-c", "0", output_file], timeout=20, check=True)
        elif command == 'lokasi':
            result = subprocess.run(["termux-location"], capture_output=True, text=True, timeout=30, check=True)
            reply_body = f"Hasil perintah 'lokasi':\n\n{result.stdout}"
        elif command == 'info':
            result = subprocess.run(["termux-device-info"], capture_output=True, text=True, timeout=10, check=True)
            reply_body = f"Info Perangkat:\n\n{result.stdout}"
        elif command == 'exit-termux':
            reply_body = "Perintah 'exit-termux' diterima. Listener akan berhenti."
            send_reply(service, msg_obj, reply_body)
            logging.info("Listener dihentikan melalui perintah 'exit-termux'.")
            os._exit(0)
        else:
            reply_body = f"Perintah '{command}' tidak dikenali."
        
        send_reply(service, msg_obj, reply_body, output_file)
        if output_file and os.path.exists(output_file):
            os.remove(output_file)
    except subprocess.TimeoutExpired:
        logging.error(f"Perintah '{command}' timeout.")
        send_reply(service, msg_obj, f"Gagal: Perintah '{command}' memakan waktu terlalu lama (timeout).")
    except Exception as e:
        logging.error(f"Error saat eksekusi: {e}")
        send_reply(service, msg_obj, f"Gagal mengeksekusi perintah. Error: {e}")

def check_for_commands(service):
    try:
        q = f"from:{MY_EMAIL} is:unread subject:'{CMD_SUBJECT}'"
        results = service.users().messages().list(userId='me', labelIds=['INBOX'], q=q).execute()
        messages = results.get('messages', [])
        for message_info in messages:
            msg_id = message_info['id']
            msg_obj = service.users().messages().get(userId='me', id=msg_id).execute()
            execute_command(service, msg_obj, msg_obj['snippet'])
            service.users().messages().modify(userId='me', id=msg_id, body={'removeLabelIds': ['UNREAD']}).execute()
    except Exception as e:
        logging.error(f"Gagal memeriksa email: {e}")

if __name__ == '__main__':
    logging.info("Listener dimulai.")
    print("Listener dimulai. Cek log di $LOG_FILE")
    try:
        service = get_gmail_service()
        while True:
            check_for_commands(service)
            time.sleep($POLL_INTERVAL)
    except Exception as e:
        logging.critical(f"Listener CRASH! Error: {e}")
        print(f"Listener CRASH! Error: {e}")
EOF
}

# --- [ ROUTER PERINTAH ] ---
# Bagian ini akan membaca argumen dari main.sh dan menjalankan fungsi yang sesuai

case "$1" in
    check_dependencies) func_check_dependencies ;;
    setup) func_setup ;;
    start) func_start ;;
    stop) func_stop ;;
    logs) func_logs ;;
    cleanup) func_cleanup ;;
    *) echo -e "${C_RED}Perintah tidak dikenal. Jalankan melalui main.sh.${C_NC}" ;;
esac