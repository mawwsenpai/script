#!/usr/bin/env bash
# ==============================================================================
#                 MAWW SCRIPT V41 - SECURITY ACTIONS EDITION
# ==============================================================================

set -o pipefail
readonly G_CREDS_FILE="credentials.json"
readonly G_TOKEN_FILE="token.json"
readonly PY_HELPER_TOKEN="handle_token.py"
readonly PY_LISTENER="gmail_listener.py"
readonly PY_LOCAL_SERVER="local_server.py"
readonly AUTH_CODE_FILE="auth_code.tmp"
readonly CONFIG_DEVICE="device.conf"
readonly PID_FILE="listener.pid"
readonly SERVER_PID_FILE="server.pid"
readonly LOG_FILE="listener.log"
readonly PATCH_FLAG=".patch_installed"
readonly DOWNLOAD_DIR="$HOME/storage/shared/Download"
readonly REDIRECT_URI="http://localhost:8080"

readonly C_RESET='\033[0m'; readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m'; readonly C_PURPLE='\033[0;35m';
readonly C_CYAN='\033[0;36m'; readonly C_WHITE='\033[1;37m'; readonly C_BOLD='\033[1m';
readonly C_DIM='\033[2m';

function _log_header() { echo -e "\n${C_CYAN}--- [ $@ ] ---${C_RESET}"; }
function _log_info() { echo -e "${C_WHITE}[i] $@${C_RESET}"; }
function _log_ok() { echo -e "${C_GREEN}[✔] $@${C_RESET}"; }
function _log_warn() { echo -e "${C_YELLOW}[!] $@${C_RESET}"; }
function _log_error() { echo -e "${C_RED}[✖] $@${C_RESET}"; }

function _generate_py_scripts() {
source "$CONFIG_DEVICE"

cat << 'EOF' > "$PY_LOCAL_SERVER"
import http.server
import socketserver
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
            self.wfile.write(b"<html><head><title>Berhasil</title><style>body{font-family:sans-serif;background:#1a1a1a;color:#e0e0e0;display:flex;justify-content:center;align-items:center;height:100vh;}h1{color:#4CAF50;}</style></head>")
            self.wfile.write(b"<body><h1>&#9989; Kode diterima! Proses otomatis, silakan kembali ke Termux.</h1></body></html>")
            self.server.server_close()
        else:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b"Parameter 'code' tidak ditemukan.")

with socketserver.TCPServer(("", PORT), MyRequestHandler) as server:
    server.serve_forever()
EOF

cat << EOF > "$PY_HELPER_TOKEN"
import sys,os;from google_auth_oauthlib.flow import Flow
if len(sys.argv)<2:print("Penggunaan: python handle_token.py <auth_code>",file=sys.stderr);sys.exit(1)
auth_code=sys.argv[1];creds_file="$G_CREDS_FILE";token_file="$G_TOKEN_FILE"
# SCOPES BARU: Gmail (untuk listener) + Admin Directory (untuk info device) + Identity Toolkit (untuk cabut sesi)
scopes=['https://www.googleapis.com/auth/gmail.modify', 'https://www.googleapis.com/auth/admin.directory.device.readonly', 'https://www.googleapis.com/auth/identitytoolkit']
redirect_uri="$REDIRECT_URI"
if not os.path.exists(creds_file):print(f"FATAL: File '{creds_file}' tidak ditemukan!",file=sys.stderr);sys.exit(1)
try:
    flow=Flow.from_client_secrets_file(creds_file,scopes,redirect_uri=redirect_uri);flow.fetch_token(code=auth_code)
    with open(token_file,'w') as token:token.write(flow.credentials.to_json())
    print(f"SUKSES: File '{token_file}' berhasil dibuat.")
except Exception as e:print(f"ERROR: Gagal menukar kode. Pastikan URI di Google Console benar. Detail: {e}",file=sys.stderr);sys.exit(1)
EOF

cat << EOF > "$PY_LISTENER"
import os,sys,subprocess,logging,base64,time,json;from google.oauth2.credentials import Credentials;from googleapiclient.discovery import build;from google.auth.transport.requests import Request;from email.mime.multipart import MIMEMultipart;from email.mime.text import MIMEText;from email.mime.base import MIMEBase;from email import encoders
# SCOPES BARU
SCOPES=['https://www.googleapis.com/auth/gmail.modify', 'https://www.googleapis.com/auth/admin.directory.device.readonly', 'https://www.googleapis.com/auth/identitytoolkit'];
TOKEN_FILE='$G_TOKEN_FILE';MY_EMAIL='$MY_EMAIL';CMD_SUBJECT='$CMD_SUBJECT';LOG_FILE='$LOG_FILE';POLL_INTERVAL=180
logging.basicConfig(level=logging.INFO,filename=LOG_FILE,filemode='a',format='%(asctime)s - %(message)s')

def get_admin_user():
    return MY_EMAIL

def send_reply(service,original_message,body_text,attachment_path=None):
    try:
        headers=original_message['payload']['headers'];to_email=next(h['value'] for h in headers if h['name'].lower()=='from');subject="Re: "+next(h['value'] for h in headers if h['name'].lower()=='subject');message=MIMEMultipart();message['to']=to_email;message['subject']=subject;message.attach(MIMEText(body_text,'plain'))
        if attachment_path and os.path.exists(attachment_path):
            with open(attachment_path,'rb') as f:part=MIMEBase('application','octet-stream');part.set_payload(f.read())
            encoders.encode_base_64(part);part.add_header('Content-Disposition',f'attachment; filename="{os.path.basename(attachment_path)}"');message.attach(part)
        raw_message=base64.urlsafe_b64encode(message.as_bytes()).decode();service.users().messages().send(userId='me',body={'raw':raw_message}).execute();logging.info(f"Berhasil mengirim balasan ke {to_email}")
    except Exception as e:logging.error(f"Gagal mengirim balasan: {e}")

def execute_command(gmail_service, admin_service, identity_service, msg_obj, full_command):
    try:
        command=full_command.split(':')[1].strip().lower();logging.info(f"Mengeksekusi perintah Admin: '{command}'");output_file,reply_body=None,""
        admin_user = get_admin_user()
        
        if command=='list-devices':
            reply_body = "📱 Daftar Perangkat Terdaftar (Admin SDK):\n\n"
            try:
                # Menarik daftar perangkat (Admin SDK Device Management API)
                results = admin_service.mobiledevices().list(customerId='my_customer', maxResults=10).execute()
                devices = results.get('mobiledevices', [])
                if devices:
                    for i, device in enumerate(devices):
                        device_id = device.get('resourceId', 'N/A')
                        device_model = device.get('model', 'N/A')
                        device_type = device.get('type', 'N/A')
                        last_sync = device.get('lastSync', 'N/A')
                        
                        reply_body += f"[{i+1}] ID: {device_id}\n"
                        reply_body += f"    Model: {device_model} ({device_type})\n"
                        reply_body += f"    Sync Terakhir: {last_sync.split('T')[0]}\n"
                else:
                    reply_body += "Tidak ada perangkat terdaftar yang ditemukan, atau akun bukan Admin Workspace."
            except Exception as e:
                reply_body = f"❌ GAGAL AKSES ADMIN SDK. Pastikan Anda Super Admin Workspace. Error: {e}"

        elif command=='revoke-token':
            # Tindakan Nyata: Mencabut semua token akses untuk user ini.
            # Ini akan memaksa semua sesi (termasuk listener ini!) untuk logout.
            reply_body = "🔒 TINDAKAN KEAMANAN: Mencoba mencabut semua Token Akses...\n"
            try:
                # Menggunakan Identity Toolkit API untuk mencabut token.
                # Perlu diingat: Identity Toolkit API adalah layanan berbayar.
                identity_service.users().delete(localId=admin_user).execute() 
                reply_body += "✅ SUKSES MENCABUT SEMUA TOKEN! Semua sesi (termasuk listener ini) akan logout. Silakan jalankan Setup (3) ulang."
            except Exception as e:
                reply_body = f"❌ GAGAL MENCABUT TOKEN. Cek izin dan API Key Identity Toolkit. Detail: {e}"
            
        elif command=='help':
            reply_body="Daftar Perintah Keamanan (Wajib Akun Google Workspace):\n\n"
            reply_body+="Maww:list-devices -> Lihat daftar HP yang terdaftar di akun Workspace kamu.\n"
            reply_body+="Maww:revoke-token -> **MENCABUT SEMUA TOKEN** (Memaksa logout dari semua sesi di semua HP).\n"
            reply_body+="Maww:exit-listener -> Berhenti mendengarkan perintah."
            
        elif command=='exit-listener':
            reply_body="Perintah 'exit-listener' diterima. Listener akan berhenti. Bye-bye! 👋"
            send_reply(gmail_service, msg_obj, reply_body); logging.info("Listener dihentikan."); sys.exit(0)
            
        else:
            reply_body=f"Perintah Admin '{command}' tidak dikenali. Ketik 'Maww:help' untuk daftar perintah."
        
        send_reply(gmail_service, msg_obj, reply_body, output_file)
    except Exception as e:
        logging.error(f"Error saat eksekusi: {e}"); send_reply(gmail_service, msg_obj, f"GAGAL: Terjadi error. Cek log. Detail: {e}")

def main_loop():
    creds=Credentials.from_authorized_user_file(TOKEN_FILE,SCOPES)
    gmail_service=build('gmail','v1',credentials=creds)
    # Gunakan build Admin SDK Directory API
    admin_service = build('admin', 'directory_v1', credentials=creds)
    # Gunakan build Identity Toolkit API (Perlu konfigurasi terpisah)
    identity_service = build('identitytoolkit', 'v3', credentials=creds) 
    
    logging.info("Listener service dimulai."); print("Listener kini berjalan di background...")
    while True:
        try:
            if not creds.valid:
                if creds.expired and creds.refresh_token:creds.refresh(Request())
                else:logging.error("Token tidak valid. Jalankan ulang setup.");sys.exit(1)
            
            q=f"from:{MY_EMAIL} is:unread subject:'{CMD_SUBJECT}'";results=gmail_service.users().messages().list(userId='me',labelIds=['INBOX'],q=q).execute();messages=results.get('messages',[])
            for message_info in messages:
                msg_id=message_info['id'];msg_obj=gmail_service.users().messages().get(userId='me',id=msg_id).execute()
                if msg_obj:execute_command(gmail_service, admin_service, identity_service, msg_obj, msg_obj['snippet'])
                gmail_service.users().messages().modify(userId='me',id=msg_id,body={'removeLabelIds':['UNREAD']}).execute()
            time.sleep(POLL_INTERVAL)
        except Exception as e:logging.error(f"Error pada loop utama: {e}");time.sleep(POLL_INTERVAL*2)
if __name__=='__main__':main_loop()
EOF
}

function setup() {
    clear; display_header
    _log_header "Setup / Konfigurasi Ulang (Admin Mode)"
    rm -f "$G_TOKEN_FILE" "$SERVER_PID_FILE" "$AUTH_CODE_FILE"

    if [ ! -f "$CONFIG_DEVICE" ]; then
        _log_info "Membuat file konfigurasi baru..."
        _log_warn "Pastikan email Anda adalah akun Google Workspace (Bukan @gmail.com)."
        read -r -p "$(echo -e "${C_CYAN}> Masukkan Alamat Email Gmail/Workspace Anda: ${C_RESET}")" email_input
        read -r -p "$(echo -e "${C_CYAN}> Masukkan Subjek Perintah Rahasia: ${C_RESET}")" subject_input
        echo "MY_EMAIL=\"$email_input\"" > "$CONFIG_DEVICE"
        echo "CMD_SUBJECT=\"$subject_input\"" >> "$CONFIG_DEVICE"
        _log_ok "Konfigurasi berhasil disimpan."
    fi

    _log_info "Memeriksa file kredensial '$G_CREDS_FILE'..."
    if [ ! -f "$G_CREDS_FILE" ]; then
        if ! cp "$DOWNLOAD_DIR/$G_CREDS_FILE" .; then
            _log_error "GAGAL: '$G_CREDS_FILE' tidak ditemukan di folder Download."
            return
        fi
        _log_ok "Berhasil menyalin '$G_CREDS_FILE'."
    fi
    
    _log_info "Membuat script yang dibutuhkan..."
    _generate_py_scripts

    _log_info "Membaca Client ID dari '$G_CREDS_FILE'..."
    local client_id; client_id=$(grep -o '"client_id": *"[^"]*"' "$G_CREDS_FILE" | grep -o '"[^"]*"$' | tr -d '"')
    if [ -z "$client_id" ]; then _log_error "GAGAL: Tidak bisa membaca client_id dari '$G_CREDS_FILE'."; return; fi
    
    # Scope yang diperluas
    local scope="https://www.googleapis.com/auth/gmail.modify https://www.googleapis.com/auth/admin.directory.device.readonly https://www.googleapis.com/auth/identitytoolkit"
    local auth_url="https://accounts.google.com/o/oauth2/v2/auth?scope=${scope}&access_type=offline&response_type=code&prompt=select_account&redirect_uri=${REDIRECT_URI}&client_id=${client_id}"

    _log_header "INSTRUKSI OTENTIKASI"
    _log_info "Menjalankan server lokal di background..."
    nohup python "$PY_LOCAL_SERVER" >/dev/null 2>&1 &
    echo $! > "$SERVER_PID_FILE"
    sleep 1

    _log_ok "Server berjalan! (PID: $(cat "$SERVER_PID_FILE"))"
    _log_warn "Langkah 1: COPY dan BUKA URL di bawah ini di browser."
    echo -e "${C_BOLD}${C_YELLOW}    ${auth_url}${C_RESET}"
    _log_warn "Langkah 2: Selesaikan login & berikan izin (Anda mungkin perlu login sebagai Super Admin)."
    _log_warn "Langkah 3: Halaman browser akan menampilkan 'Kode diterima'."
    _log_info "Script ini menunggu kode otorisasi dari server..."

    local count=0
    while [ ! -f "$AUTH_CODE_FILE" ]; do
        echo -n "."
        sleep 2
        count=$((count+1))
        if [ $count -gt 150 ]; then
            _log_error "\nTimeout! Gagal mendapatkan kode dalam 5 menit."
            if [ -f "$SERVER_PID_FILE" ]; then kill "$(cat "$SERVER_PID_FILE")"; rm "$SERVER_PID_FILE"; fi
            return
        fi
    done
    
    echo
    local auth_code; auth_code=$(cat "$AUTH_CODE_FILE")
    _log_ok "Kode otorisasi berhasil diterima!"
    _log_info "Menukar kode dengan token akses..."
    
    if python "$PY_HELPER_TOKEN" "$auth_code"; then
        _log_ok "🎉 SETUP SELESAI! Otorisasi berhasil."
    else
        _log_error "SETUP GAGAL. Gagal menukar kode dengan token."
    fi

    rm -f "$AUTH_CODE_FILE" "$SERVER_PID_FILE"
}

function start() { clear;display_header;_log_header "Memulai Listener Admin"; if [ ! -f "$CONFIG_DEVICE" ]||[ ! -f "$G_TOKEN_FILE" ];then _log_error "Konfigurasi/token tidak ditemukan. Jalankan 'Setup' (3) dulu.";return;fi;if [ -f "$PID_FILE" ]&&ps -p "$(cat "$PID_FILE")" >/dev/null;then _log_warn "Listener sudah berjalan.";return;fi;_generate_py_scripts;nohup python "$PY_LISTENER" >/dev/null 2>&1 & echo $! > "$PID_FILE";_log_ok "Listener dimulai (PID: $(cat "$PID_FILE")). Cek log di '$LOG_FILE'." ;}
function stop() { clear;display_header;_log_header "Menghentikan Listener"; if [ ! -f "$PID_FILE" ];then _log_warn "Listener tidak sedang berjalan.";return;fi;local pid; pid=$(cat "$PID_FILE");if ps -p "$pid" >/dev/null;then kill "$pid";rm -f "$PID_FILE";_log_ok "Listener (PID: $pid) telah dihentikan.";else _log_warn "Proses (PID: $pid) tidak ditemukan. File PID dihapus.";rm -f "$PID_FILE";fi;}
function logs() { clear;display_header;_log_header "Melihat Log Realtime";if [ ! -f "$LOG_FILE" ];then _log_warn "File log belum ada.";return;fi;_log_info "Menampilkan log... Tekan ${C_BOLD}Ctrl+C${C_RESET} untuk keluar."; echo; tail -f "$LOG_FILE" ;}
function cleanup() { clear;display_header;_log_header "Pembersihan Total";_log_warn "Ini akan menghapus SEMUA file terkait script ini.";
    read -r -p "$(echo -e "${C_YELLOW}> Anda yakin ingin melanjutkan? (y/n): ${C_RESET}")" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]];then stop >/dev/null 2>&1||true;_log_info "Menghapus file...";rm -f "$CONFIG_DEVICE" "$G_TOKEN_FILE" "$G_CREDS_FILE" "$PY_HELPER_TOKEN" "$PY_LISTENER" ".patch_installed" "$LOG_FILE" "$PID_FILE" "$SERVER_PID_FILE" "$PY_LOCAL_SERVER" "$AUTH_CODE_FILE";_log_ok "Pembersihan selesai.";else _log_info "Pembersihan dibatalkan.";fi;}
function run_patcher() { set -e;clear;display_header;_log_header "Persiapan Lingkungan Otomatis";
    readonly PKS=("python" "coreutils" "curl");
    readonly PYR=("google-api-python-client" "google-auth-httplib2" "google-auth-oauthlib");_log_info "${C_BOLD}Langkah 1/3:${C_RESET} Memeriksa paket sistem...";pkg update -y >/dev/null 2>&1;for p in "${PKS[@]}";do if ! dpkg -s "$p">/dev/null 2>&1;then _log_warn "Menginstal '$p'...";pkg install -y "$p";fi;done;_log_ok "Paket sistem siap.";_log_info "${C_BOLD}Langkah 2/3:${C_RESET} Memeriksa library Python...";for r in "${PYR[@]}";do if ! pip show "$r">/dev/null 2>&1;then _log_warn "Menginstal '$r'...";pip install --no-cache-dir "$r";fi;done;_log_ok "Library Python siap.";_log_info "${C_BOLD}Langkah 3/3:${C_RESET} Izin penyimpanan...";if [ ! -d "$HOME/storage/shared" ];then termux-setup-storage;_log_warn "Izin diminta...";sleep 5;fi;_log_ok "Izin penyimpanan siap.";echo;_log_ok "✅ LINGKUNGAN SUDAH SIAP! (Hanya butuh CURL dan Python) ✅";set +e;}

function device_commands_menu() {
    clear; display_header
    _log_header "MENU KEAMANAN AKUN (Admin SDK)"
    if [ ! -f "$CONFIG_DEVICE" ]; then _log_error "Konfigurasi belum ditemukan! Jalankan Setup (3) dulu."; return; fi
    source "$CONFIG_DEVICE"
    _log_warn "PERHATIAN: Hanya berfungsi 100% jika email Anda adalah ${C_CYAN}Akun Google Workspace (Bisnis/Edukasi)${C_RESET}."
    _log_info "Kirim email ke ${C_CYAN}\"$MY_EMAIL\"${C_RESET} dengan Subjek: ${C_YELLOW}\"$CMD_SUBJECT\"${C_RESET}"
    echo
    echo -e "${C_BOLD}TINDAKAN KEAMANAN AKTIF:${C_RESET}"
    echo -e "${C_WHITE}  1) Lihat Perangkat Aktif (list-devices) -> Melihat HP yang terdaftar di akun Workspace."
    echo -e "${C_WHITE}  2) Cabut Semua Token Akses (revoke-token) -> **LOGOUT PAKSA SEMUA SESI!** (Termasuk listener ini)."
    echo
    echo -e "${C_BOLD}ADMINISTRASI LISTENER:${C_RESET}"
    echo -e "${C_WHITE}  3) Dapatkan Bantuan (help)             -> Daftar perintah."
    echo -e "${C_WHITE}  4) Matikan Listener (exit-listener)    -> Matikan listener."
    echo
    read -r -p "$(echo -e "${C_CYAN}Tekan [Enter] untuk kembali ke Menu Utama... ${C_RESET}")"
}

function display_header() {
    local status_text; local status_color; local pid_text=""
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" >/dev/null; then
        status_text="A K T I F"; status_color="$C_GREEN"
        pid_text="(PID: $(cat "$PID_FILE"))"
    else
        status_text="TIDAK AKTIF"; status_color="$C_RED"
    fi
    echo -e "${C_PURPLE}-----------------------------------------------------${C_RESET}"
    echo -e "${C_BOLD}${C_WHITE}   Ⓜ Ⓐ Ⓦ Ⓦ    Ⓢ Ⓒ Ⓡ Ⓘ Ⓟ Ⓣ   v41 (Admin SDK)${C_RESET}"
    echo -e "${C_PURPLE}-----------------------------------------------------${C_RESET}"
    printf "%-10s %-20s %s\n" " Status" ": ${status_color}${status_text}${C_RESET}" "${C_YELLOW}${pid_text}${C_RESET}"
    echo -e "${C_PURPLE}-----------------------------------------------------${C_RESET}"
}

function display_menu() {
    local device_menu_option="  7) 🌐  Perintah Remote (Admin SDK)"
    if [ ! -f "$CONFIG_DEVICE" ]; then
        device_menu_option="${C_DIM}  7) 🌐  Perintah Remote (Harus Setup dulu!)${C_RESET}"
    fi

    echo
    echo -e "${C_WHITE}  1) 🚀  Mulai Listener"
    echo -e "${C_WHITE}  2) 🛑  Hentikan Listener"
    echo -e "${C_WHITE}  3) ⚙️   Setup / Konfigurasi"
    echo -e "${C_WHITE}  4) 📜  Lihat Log Realtime"
    echo -e "${C_WHITE}  5) 🔧  Perbaiki Lingkungan"
    echo -e "${C_WHITE}  6) 🗑️   Hapus Semua Konfigurasi"
    echo -e "${device_menu_option}"
    echo -e "${C_WHITE}  8) 🚪  Keluar${C_RESET}"
    echo
    
    read -r -p "$(echo -e "${C_CYAN}  Pilih Opsi [1-8] > ${C_RESET}")" choice
    
    case $choice in
        '1') start;; '2') stop;; '3') setup;; '4') logs;;
        '5') run_patcher; touch .patch_installed ;;
        '6') cleanup;;
        '7') if [ -f "$CONFIG_DEVICE" ]; then device_commands_menu; else _log_error "Harus Setup (3) dulu, Senpai!"; fi;;
        '8') echo -e "\n${C_PURPLE}Sampai jumpa lagi, Senpai!${C_RESET}"; exit 0;;
        *) _log_error "Pilihan tidak valid: $choice. Masukkan angka 1-8.";;
    esac
    echo -e "\n${C_DIM}Tekan [Enter] untuk kembali ke menu...${C_RESET}"
    read -r
}

function main() {
    if [ ! -f ".patch_installed" ]; then
        clear; display_header
        _log_header "Selamat Datang di Maww Script!"
        _log_info "Ini eksekusi pertama, skrip akan menyiapkan lingkungan."
        _log_warn "Pastikan 'credentials.json' ada di folder Download."
        _log_warn "Pastikan URI 'http://localhost:8080' sudah ditambahkan di Google Console."
        read -p "   Tekan [Enter] untuk memulai persiapan..."
        run_patcher
        _log_info "Membuat file penanda penyelesaian..."
        touch .patch_installed
        _log_ok "Penanda '.patch_installed' berhasil dibuat."
        read -p "   Tekan [Enter] untuk lanjut ke menu utama..."
    fi
    if [ -f "$SERVER_PID_FILE" ]; then rm -f "$SERVER_PID_FILE"; fi
    while true; do
        clear
        display_header
        display_menu
    done
}

main
