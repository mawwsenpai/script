#!/bin/bash

# =================================================================================
#               Device Remote Control via Gmail - V3.1 (ULTIMATE CORE - CLEANED)
#                         File: service_core.sh (Core Logic)
# =================================================================================

# --- [ NAMA FILE & KONFIGURASI DASAR ] ---
CONFIG_FILE="device.conf"
PYTHON_SCRIPT="gmail_listener.py"
PID_FILE="listener.pid"
LOG_FILE="listener.log"
TOKEN_FILE="token.json"
CREDS_FILENAME="credentials.json"
CREDS_FILE="$HOME/storage/Automatic/$CREDS_FILENAME" 
POLL_INTERVAL=300

# --- [ FUNGSI UTAMA (SHARED) ] ---

func_load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        return 0
    else
        return 1
    fi
}

# --- [ FUNGSI SETUP ] ---

func_setup() {
    clear
    echo "---[ SETUP & KONFIGURASI AWAL ]---"
    
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

    func_load_config
    
    echo ""
    echo "[ LANGKAH 2: Dapatkan File Kredensial Google Cloud ]"
    echo "---------------------------------------------------------"
    echo "⚠️ FILE KREDEKSIAL HARUS DITARUH DI PATH INI:"
    echo ">> $CREDS_FILE"
    echo "---------------------------------------------------------"

    if [ ! -f "$CREDS_FILE" ]; then
        echo "File '$CREDS_FILENAME' belum ditemukan. Ikuti langkah:"
        echo "1. Ikuti langkah di Google Cloud untuk mendapatkan '$CREDS_FILENAME' (tipe Desktop app)."
        echo "2. Pindahkan file yang sudah di-rename ke folder: '$HOME/storage/Automatic/'"
        read -p "Tekan [Enter] jika file sudah siap di tempatnya..."
    fi

    if [ ! -f "$CREDS_FILE" ]; then
        echo "ERROR: File '$CREDS_FILENAME' tidak ditemukan di path: '$CREDS_FILE'. Setup dibatalkan. *Gajelas* sih kalau nggak ada file-nya. 🤪"
        exit 1
    fi
    
    echo ""
    echo "[ LANGKAH 3: Otorisasi Akun (Satu Kali Saja) ]"
    func_generate_python_script
    echo "Menjalankan otorisasi untuk akun '$MY_EMAIL'. Sebuah link akan muncul di browser HP."
    echo "Login dan berikan izin."
    python "$PYTHON_SCRIPT"
    if [ -f "$TOKEN_FILE" ]; then
        echo -e "\nSETUP SELESAI! Otorisasi berhasil. Kamu bisa jalankan './main.sh start' sekarang!"
    else
        echo -e "\nSETUP GAGAL. Pastikan kamu memberikan izin di browser, sayangku! 🥺"
    fi
}

func_generate_python_script() {
    func_load_config
    cat << EOF > "$PYTHON_SCRIPT"
# -*- coding: utf-8 -*-
# Script ini dibuat secara otomatis oleh service_core.sh
import os, subprocess, time, logging, base64
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

# Konfigurasi dimuat dari service_core.sh
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
            subprocess.run(["termux-camera-photo", "-c", "0", output_file], timeout=20)
        elif command == 'lokasi':
            result = subprocess.run(["termux-location"], capture_output=True, text=True, timeout=30)
            reply_body = f"Hasil perintah 'lokasi':\n\n{result.stdout}"
        elif command == 'info':
            result = subprocess.run(["termux-device-info"], capture_output=True, text=True, timeout=10)
            reply_body = f"Info Perangkat:\n\n{result.stdout}"
        elif command == 'exit-termux':
            reply_body = "Perintah 'exit-termux' diterima. Termux akan ditutup."
            send_reply(service, msg_obj, reply_body)
            os._exit(0)
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

# --- [ MANAJEMEN SERVICE (ROBUST) ] ---

func_start() {
    if ! func_load_config; then
        echo "ERROR: Konfigurasi tidak ditemukan. Jalankan './main.sh setup' terlebih dahulu."
        return 1
    fi

    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ! ps -p $PID > /dev/null; then
            echo ">> Ditemukan file PID usang. Menghapusnya..."
            rm "$PID_FILE"
        fi
    fi

    if [ -f "$PID_FILE" ]; then
        echo "Listener sudah berjalan (PID: $(cat $PID_FILE))."
    else
        echo "Memulai listener di background... Semoga nggak 'gajelas' di tengah jalan. 🙏"
        func_generate_python_script
        
        nohup python "$PYTHON_SCRIPT" > /dev/null 2>&1 &
        echo $! > "$PID_FILE"
        echo "Listener berhasil dimulai dengan PID: $(cat $PID_FILE)."
    fi
}

func_stop() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        echo "Menghentikan listener (PID: $PID)..."
        kill "$PID" > /dev/null 2>&1
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
            echo "STATUS: BERHENTI (Ditemukan file PID tidak valid, mungkin CRASH. Hapus dengan stop)"
        fi
    else
        echo "STATUS: BERHENTI"
    fi
}

func_logs() {
    echo "Menampilkan log (Tekan Ctrl+C untuk keluar)..."
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        echo "LOG FILE belum ditemukan, mungkin listener belum pernah dijalankan."
    fi
}

func_cleanup() {
    func_stop > /dev/null 2>&1

    echo "---[ CLEANUP TOTAL (Pembersihan) ]---"
    echo "Menghapus file konfigurasi dan log..."

    rm -f "$CONFIG_FILE" "$LOG_FILE" "$PYTHON_SCRIPT" "$TOKEN_FILE" 

    echo "✅ Konfigurasi (.conf, .log, .py, .token) telah dihapus."
    echo "⚠️ CATATAN: File '$CREDS_FILENAME' (kredensial API) TIDAK dihapus dari '$HOME/storage/Automatic/'."
    echo "Kamu harus menghapusnya manual kalau mau reset total. Done!"
}


# --- [ ROUTING PERINTAH ] ---
case "$1" in
    setup)
        func_setup
        ;;
    reconfigure)
        echo "Memulai proses konfigurasi ulang..."
        func_stop > /dev/null 2>&1 
        rm -f "$TOKEN_FILE" 
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
    cleanup)
        func_cleanup
        ;;
    *)
        :
        ;;
esac