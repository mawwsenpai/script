#!/bin/bash

# =================================================================================
#               Device Remote Control via Gmail - v2.0 (Stabil)
#                        File: device.sh (Launcher)
#
#        Script profesional dengan setup terpandu dan konfigurasi
#        terpisah untuk kendali jarak jauh yang stabil dan aman.
#
#   PERINGATAN: SANGAT EKSPERIMENTAL DAN BERISIKO TINGGI. HANYA UNTUK EDUKASI
#               DAN WAJIB DENGAN IZIN PEMILIK PERANGKAT.
# =================================================================================

# --- [ NAMA FILE & KONFIGURASI DASAR ] ---
CONFIG_FILE="device.conf"
PYTHON_SCRIPT="gmail_listener.py"
PID_FILE="listener.pid"
LOG_FILE="listener.log"
TOKEN_FILE="token.json"
CREDS_FILE="credentials.json"
POLL_INTERVAL=300 # Interval pengecekan email dalam detik (300 = 5 menit)

# --- [ FUNGSI UTAMA ] ---

# Fungsi untuk memuat konfigurasi dari device.conf
func_load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        return 0
    else
        return 1
    fi
}

# Setup terpandu untuk konfigurasi awal atau ulang
func_setup() {
    clear
    echo "---[ SETUP & KONFIGURASI AWAL ]---"
    echo "Anda akan dipandu untuk mengatur email dan kredensial."
    
    echo ""
    echo "[ LANGKAH 1: Masukkan Detail Akun ]"
    read -p "Masukkan alamat email Gmail Anda (pengirim & penerima perintah): " email_input
    read -p "Buat Subjek Perintah yang unik & rahasia (contoh: [CMD-RAHASIA-ALPHA]): " subject_input

    if [ -z "$email_input" ] || [ -z "$subject_input" ]; then
        echo "ERROR: Email dan Subjek tidak boleh kosong. Setup dibatalkan."
        exit 1
    fi

    echo "Menyimpan konfigurasi ke $CONFIG_FILE..."
    echo "MY_EMAIL=\"$email_input\"" > "$CONFIG_FILE"
    echo "CMD_SUBJECT=\"$subject_input\"" >> "$CONFIG_FILE"
    echo "Konfigurasi berhasil disimpan."

    echo ""
    echo "[ LANGKAH 2: Dapatkan File Kredensial Google Cloud ]"
    if [ ! -f "$CREDS_FILE" ]; then
        echo "File '$CREDS_FILE' belum ada. Ikuti langkah berikut:"
        echo "1. Buka link ini di browser: https://console.cloud.google.com/apis/credentials"
        echo "2. Buat/Pilih Proyek, lalu aktifkan 'Gmail API'."
        echo "3. Konfigurasi 'OAuth consent screen' (pilih 'External', isi data wajib saja)."
        echo "4. Kembali ke 'Credentials', klik '+ CREATE CREDENTIALS' -> 'OAuth client ID'."
        echo "5. Pilih 'Application type' -> 'Desktop app', beri nama, lalu klik 'CREATE'."
        echo "6. Klik ikon 'DOWNLOAD JSON'. Rename file yang terunduh menjadi '$CREDS_FILE' dan letakkan di folder ini."
        read -p "Tekan [Enter] jika file '$CREDS_FILE' sudah siap..."
    fi

    if [ ! -f "$CREDS_FILE" ]; then
        echo "ERROR: File '$CREDS_FILE' tidak ditemukan. Setup dibatalkan."
        exit 1
    fi
    
    echo ""
    echo "[ LANGKAH 3: Otorisasi Akun (Satu Kali Saja) ]"
    func_check_deps
    func_generate_python_script
    echo "Menjalankan otorisasi. Sebuah link akan muncul di browser HP."
    echo "Login dengan akun '$email_input' dan berikan izin."
    python "$PYTHON_SCRIPT"
    if [ -f "$TOKEN_FILE" ]; then
        echo -e "\nSETUP SELESAI! Otorisasi berhasil. Anda sekarang bisa menjalankan './device.sh start'"
    else
        echo -e "\nSETUP GAGAL. Pastikan Anda memberikan izin di browser."
    fi
}

# Memeriksa dan menginstal dependensi
func_check_deps() {
    echo ">> Memeriksa dependensi (python, termux-api)..."
    pkg install python termux-api -y > /dev/null 2>&1
    if ! pip show google-api-python-client > /dev/null 2>&1; then
        echo ">> Menginstal library Google API untuk Python (butuh beberapa saat)..."
        pip install --upgrade google-api-python-client google-auth-httplib2 google-auth-oauthlib > /dev/null 2>&1
    fi
}

# Membuat script Python secara dinamis dengan konfigurasi dari user
func_generate_python_script() {
    func_load_config
    cat << EOF > "$PYTHON_SCRIPT"
# -*- coding: utf-8 -*-
# Script ini dibuat secara otomatis oleh device.sh
import os, subprocess, time, logging, base64
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

# Konfigurasi dimuat dari device.sh
SCOPES = ['https://www.googleapis.com/auth/gmail.modify']
MY_EMAIL = "$MY_EMAIL"
CMD_SUBJECT = "$CMD_SUBJECT"
TOKEN_FILE = "$TOKEN_FILE"
CREDS_FILE = "$CREDS_FILE"

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
                logging.error(f"FATAL: File '{CREDS_FILE}' tidak ditemukan!")
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
        message['to'] = to_email; message['subject'] = subject
        message.attach(MIMEText(body_text, 'plain'))
        if attachment_path and os.path.exists(attachment_path):
            with open(attachment_path, 'rb') as f: part = MIMEBase('application', 'octet-stream'); part.set_payload(f.read())
            encoders.encode_base64(part); part.add_header('Content-Disposition', f'attachment; filename="{os.path.basename(attachment_path)}"'); message.attach(part)
        raw_message = base64.urlsafe_b64encode(message.as_bytes()).decode()
        service.users().messages().send(userId='me', body={'raw': raw_message}).execute()
        logging.info(f"Berhasil mengirim balasan ke {to_email}")
    except Exception as e: logging.error(f"Gagal mengirim balasan: {e}")

def execute_command(service, msg_obj, full_command):
    try:
        command = full_command.split(':')[1].strip().lower()
        logging.info(f"Mengeksekusi perintah: {command}")
        output_file, reply_body = None, f"Perintah '{command}' telah dieksekusi."
        if command == 'ss':
            output_file, reply_body = "/data/data/com.termux/files/home/screenshot.png", "Screenshot terlampir."
            subprocess.run(["termux-screenshot", output_file], timeout=15)
        elif command == 'foto':
            output_file, reply_body = "/data/data/com.termux/files/home/photo.jpg", "Foto terlampir."
            subprocess.run(["termux-camera-photo", "-c", "0", output_file], timeout=20) # -c 0 for back camera
        elif command == 'lokasi':
            result = subprocess.run(["termux-location"], capture_output=True, text=True, timeout=30)
            reply_body = f"Hasil perintah 'lokasi':\n\n{result.stdout}"
        elif command == 'info':
            result = subprocess.run(["termux-device-info"], capture_output=True, text=True, timeout=10)
            reply_body = f"Info Perangkat:\n\n{result.stdout}"
        else: reply_body = f"Perintah '{command}' tidak dikenali."
        send_reply(service, msg_obj, reply_body, output_file)
        if output_file and os.path.exists(output_file): os.remove(output_file)
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
    except Exception as e: logging.error(f"Gagal memeriksa email: {e}")

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
EOF
}


# --- [ MANAJEMEN SERVICE ] ---
func_start() {
    if ! func_load_config; then
        echo "ERROR: Konfigurasi tidak ditemukan. Jalankan './device.sh setup' terlebih dahulu."
        return 1
    fi
    if [ -f "$PID_FILE" ]; then
        echo "Listener sudah berjalan (PID: $(cat $PID_FILE))."
    else
        echo "Memulai listener di background..."
        func_generate_python_script # Pastikan script python terbaru
        nohup python "$PYTHON_SCRIPT" > /dev/null 2>&1 &
        echo $! > "$PID_FILE"
        echo "Listener berhasil dimulai dengan PID: $(cat $PID_FILE)."
    fi
}
func_stop() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        echo "Menghentikan listener (PID: $PID)..."
        kill "$PID"
        rm "$PID_FILE"
        echo "Listener berhasil dihentikan."
    else
        echo "Listener tidak sedang berjalan."
    fi
}
func_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null; then
            echo "STATUS: BERJALAN (PID: $PID)"
        else
            echo "STATUS: BERHENTI (Ditemukan file PID tidak valid, mungkin CRASH. Hapus dengan './device.sh stop')"
        fi
    else
        echo "STATUS: BERHENTI"
    fi
}
func_logs() {
    echo "Menampilkan log (Tekan Ctrl+C untuk keluar)..."
    tail -f "$LOG_FILE"
}

# --- [ ROUTING PERINTAH ] ---
case "$1" in
    setup)
        func_setup
        ;;
    reconfigure)
        echo "Memulai proses konfigurasi ulang..."
        func_stop > /dev/null 2>&1 # Hentikan proses lama jika ada
        rm -f "$TOKEN_FILE" # Hapus token lama
        func_setup
        ;;
    start)
        func_start
        ;;
    stop)
        func_stop
        ;;
    status)
        func_status
        ;;
    logs)
        func_logs
        ;;
    *)
        echo "Usage: ./device.sh {setup|reconfigure|start|stop|status|logs}"
        echo "  setup       : Konfigurasi awal (hanya perlu sekali)."
        echo "  reconfigure : Mengulang proses setup untuk ganti email/subjek."
        echo "  start       : Memulai listener di background."
        echo "  stop        : Menghentikan listener."
        echo "  status      : Melihat status listener saat ini."
        echo "  logs        : Melihat log aktivitas (untuk troubleshooting)."
        ;;
esac