#!/usr/bin/env bash
# ==============================================================================
#                 MAWW SCRIPT V23 - PROFESSIONAL & SECURE+
# ==============================================================================
# Deskripsi:
#   Versi yang disederhanakan dan lebih aman. Menghilangkan kebutuhan
#   Google Apps Script dan menggunakan alur redirect ke halaman statis.
#   Tampilan UI dirombak total untuk pengalaman yang lebih baik.
#
# Dibuat oleh: Maww Senpai (dengan bantuan Gemini)
# Versi: 23.0
# ==============================================================================

# --- [ KONFIGURASI GLOBAL & FILE ] ---
set -o pipefail
readonly G_CREDS_FILE="credentials.json"
readonly G_TOKEN_FILE="token.json"
readonly CONFIG_FILE="config.json" # [DIHAPUS] Tidak lagi dibutuhkan untuk client_id
readonly PY_HELPER_TOKEN="handle_token.py"
readonly PY_LISTENER="gmail_listener.py"
readonly CONFIG_DEVICE="device.conf"
readonly PID_FILE="listener.pid"
readonly LOG_FILE="listener.log"
readonly PATCH_FLAG=".patch_installed"
readonly DOWNLOAD_DIR="$HOME/storage/shared/Download"
# [PERUBAHAN] Hardcode redirect URI untuk menghilangkan kebutuhan input Apps Script URL
readonly REDIRECT_URI="https://mawwscript.github.io/script/device/index.html"

# --- [ PALET WARNA & TAMPILAN ] ---
readonly C_RESET='\033[0m'; readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m'; readonly C_PURPLE='\033[0;35m';
readonly C_CYAN='\033[0;36m'; readonly C_WHITE='\033[1;37m'; readonly C_BOLD='\033[1m';
readonly C_DIM='\033[2m';

# --- [ FUNGSI LOGGING & UI HELPER ] ---
function _log_box_header() { echo -e "${C_PURPLE}╔══════════════════════════════════════════════════════╗${C_RESET}"; echo -e "${C_PURPLE}║${C_RESET} ${C_BOLD}${C_WHITE}$@${C_RESET}"; }
function _log_box_footer() { echo -e "${C_PURPLE}╚══════════════════════════════════════════════════════╝${C_RESET}"; }
function _log_box_line() { echo -e "${C_PURPLE}║${C_RESET} ${C_CYAN}$@${C_RESET}"; }
function _log_box_ok() { echo -e "${C_PURPLE}║${C_RESET} ${C_GREEN}✔ $@${C_RESET}"; }
function _log_box_warn() { echo -e "${C_PURPLE}║${C_RESET} ${C_YELLOW}⚠ $@${C_RESET}"; }
function _log_box_error() { echo -e "${C_PURPLE}║${C_RESET} ${C_RED}✖ $@${C_RESET}"; }
function _log_box_separator() { echo -e "${C_PURPLE}╟──────────────────────────────────────────────────────╢${C_RESET}";}

# --- GENERATOR SCRIPT PYTHON ---
function _generate_py_scripts() {
source "$CONFIG_DEVICE"
# [PERUBAHAN] Menggunakan redirect_uri statis yang sudah ditentukan
cat << EOF > "$PY_HELPER_TOKEN"
import sys,os;from google_auth_oauthlib.flow import Flow
if len(sys.argv)<2:print("Penggunaan: python handle_token.py <auth_code>",file=sys.stderr);sys.exit(1)
auth_code=sys.argv[1];creds_file="$G_CREDS_FILE";token_file="$G_TOKEN_FILE";scopes=['https://www.googleapis.com/auth/gmail.modify']
# [PERUBAHAN] Redirect URI di-hardcode di sini, tidak lagi diambil dari config
redirect_uri="$REDIRECT_URI"
if not os.path.exists(creds_file):print(f"FATAL: File '{creds_file}' tidak ditemukan!",file=sys.stderr);sys.exit(1)
try:
    flow=Flow.from_client_secrets_file(creds_file,scopes,redirect_uri=redirect_uri);flow.fetch_token(code=auth_code)
    with open(token_file,'w') as token:token.write(flow.credentials.to_json())
    print(f"SUKSES: File '{token_file}' berhasil dibuat.")
except Exception as e:print(f"ERROR: Gagal menukar kode. Pastikan URI di Google Console benar. Detail: {e}",file=sys.stderr);sys.exit(1)
EOF
# Skrip listener utama (tidak ada perubahan)
cat << EOF > "$PY_LISTENER"
import os,sys,subprocess,logging,base64,time;from google.oauth2.credentials import Credentials;from googleapiclient.discovery import build;from google.auth.transport.requests import Request;from email.mime.multipart import MIMEMultipart;from email.mime.text import MIMEText;from email.mime.base import MIMEBase;from email import encoders
SCOPES=['https://www.googleapis.com/auth/gmail.modify'];TOKEN_FILE='$G_TOKEN_FILE';MY_EMAIL='$MY_EMAIL';CMD_SUBJECT='$CMD_SUBJECT';LOG_FILE='$LOG_FILE';POLL_INTERVAL=180
logging.basicConfig(level=logging.INFO,filename=LOG_FILE,filemode='a',format='%(asctime)s - %(message)s')
def send_reply(service,original_message,body_text,attachment_path=None):
    try:
        headers=original_message['payload']['headers'];to_email=next(h['value'] for h in headers if h['name'].lower()=='from');subject="Re: "+next(h['value'] for h in headers if h['name'].lower()=='subject');message=MIMEMultipart();message['to']=to_email;message['subject']=subject;message.attach(MIMEText(body_text,'plain'))
        if attachment_path and os.path.exists(attachment_path):
            with open(attachment_path,'rb') as f:part=MIMEBase('application','octet-stream');part.set_payload(f.read())
            encoders.encode_base64(part);part.add_header('Content-Disposition',f'attachment; filename="{os.path.basename(attachment_path)}"');message.attach(part)
        raw_message=base64.urlsafe_b64encode(message.as_bytes()).decode();service.users().messages().send(userId='me',body={'raw':raw_message}).execute();logging.info(f"Berhasil mengirim balasan ke {to_email}")
    except Exception as e:logging.error(f"Gagal mengirim balasan: {e}")
def execute_command(service,msg_obj,full_command):
    try:
        command=full_command.split(':')[1].strip().lower();logging.info(f"Mengeksekusi perintah: '{command}'");output_file,reply_body=None,f"Perintah '{command}' telah selesai dieksekusi."
        if command=='ss':output_file,reply_body=os.path.expanduser("~/screenshot.png"),"Screenshot terlampir.";subprocess.run(["termux-screenshot",output_file],timeout=20,check=True)
        elif command=='foto':output_file,reply_body=os.path.expanduser("~/photo.jpg"),"Foto terlampir.";subprocess.run(["termux-camera-photo","-c","0",output_file],timeout=25,check=True)
        elif command=='lokasi':result=subprocess.run(["termux-location"],capture_output=True,text=True,timeout=30,check=True);reply_body=f"Hasil perintah 'lokasi':\n\n{result.stdout or 'Tidak ada output.'}"
        elif command=='info':result=subprocess.run(["termux-device-info"],capture_output=True,text=True,timeout=15,check=True);reply_body=f"Info Perangkat:\n\n{result.stdout or 'Tidak ada output.'}"
        elif command=='exit-listener':reply_body="Perintah 'exit-listener' diterima. Listener akan berhenti.";send_reply(service,msg_obj,reply_body);logging.info("Listener dihentikan.");sys.exit(0)
        else:reply_body=f"Perintah '{command}' tidak dikenali."
        send_reply(service,msg_obj,reply_body,output_file)
    except Exception as e:logging.error(f"Error saat eksekusi: {e}");send_reply(service,msg_obj,f"GAGAL: Terjadi error. Cek log.")
    finally:
        if output_file and os.path.exists(output_file):os.remove(output_file)
def main_loop():
    creds=Credentials.from_authorized_user_file(TOKEN_FILE,SCOPES);service=build('gmail','v1',credentials=creds);logging.info("Listener service dimulai.");print("Listener kini berjalan di background...")
    while True:
        try:
            if not creds.valid:
                if creds.expired and creds.refresh_token:creds.refresh(Request())
                else:logging.error("Token tidak valid. Jalankan ulang setup.");sys.exit(1)
            q=f"from:{MY_EMAIL} is:unread subject:'{CMD_SUBJECT}'";results=service.users().messages().list(userId='me',labelIds=['INBOX'],q=q).execute();messages=results.get('messages',[])
            for message_info in messages:
                msg_id=message_info['id'];msg_obj=service.users().messages().get(userId='me',id=msg_id).execute()
                if msg_obj:execute_command(service,msg_obj,msg_obj['snippet'])
                service.users().messages().modify(userId='me',id=msg_id,body={'removeLabelIds':['UNREAD']}).execute()
            time.sleep(POLL_INTERVAL)
        except Exception as e:logging.error(f"Error pada loop utama: {e}");time.sleep(POLL_INTERVAL*2)
if __name__=='__main__':main_loop()
EOF
}

# --- LOGIKA INTI ---
function setup() {
    clear; display_header
    _log_box_header "Memulai Proses Setup (Jalur GitHub Pages)"
    rm -f "$G_TOKEN_FILE"
    if [ ! -f "$CONFIG_DEVICE" ]; then
        _log_box_line "File '$CONFIG_DEVICE' tidak ditemukan, membuat baru..."
        read -p "   - Masukkan Alamat Email Gmail Anda: " email_input
        read -p "   - Masukkan Subjek Perintah Rahasia: " subject_input
        # [PERUBAHAN] Tidak lagi meminta URL Apps Script
        echo "MY_EMAIL=\"$email_input\"" > "$CONFIG_DEVICE"
        echo "CMD_SUBJECT=\"$subject_input\"" >> "$CONFIG_DEVICE"
        _log_box_ok "Konfigurasi dasar berhasil disimpan."
    fi
    source "$CONFIG_DEVICE"

    _log_box_line "Memeriksa file kredensial '$G_CREDS_FILE'..."
    if [ ! -f "$G_CREDS_FILE" ]; then
        if ! cp "$DOWNLOAD_DIR/$G_CREDS_FILE" .; then
            _log_box_error "GAGAL: '$G_CREDS_FILE' tidak ada di folder Download."
            _log_box_footer; return
        fi
        _log_box_ok "Berhasil disalin dari folder Download."
    fi
    
    _log_box_line "Membuat helper script Python..."
    _generate_py_scripts
    
    # [PERUBAHAN] Client ID dibaca langsung dari credentials.json, tidak perlu config.json
    local client_id=$(grep -o '"client_id": *"[^"]*"' "$G_CREDS_FILE" | grep -o '"[^"]*"$' | tr -d '"')
    if [ -z "$client_id" ]; then
        _log_box_error "GAGAL: Tidak bisa membaca client_id dari '$G_CREDS_FILE'."
        _log_box_footer; return
    fi
    _log_box_ok "Client ID berhasil dibaca."
    
    local scope="https://www.googleapis.com/auth/gmail.modify"
    # [PERUBAHAN] Menggunakan variabel REDIRECT_URI
    local auth_url="https://accounts.google.com/o/oauth2/v2/auth?scope=${scope}&redirect_uri=${REDIRECT_URI}&response_type=code&client_id=${client_id}&access_type=offline&prompt=consent"
    
    _log_box_line "Membuka browser untuk otentikasi..."
    am start -a android.intent.action.VIEW -d "$auth_url"
    
    _log_box_separator
    _log_box_warn "               INSTRUKSI MANUAL"
    _log_box_warn "1. Selesaikan login & berikan izin di browser."
    _log_box_warn "2. Anda akan diarahkan ke halaman GitHub Pages."
    _log_box_warn "3. Salin kode yang ditampilkan di halaman itu."
    _log_box_separator
    
    while true; do
        read -p "   - Paste kode di sini (atau 'q' untuk keluar): " manual_code
        if [[ "$manual_code" == "q" ]]; then _log_box_line "Setup dibatalkan."; _log_box_footer; return; fi
        if python "$PY_HELPER_TOKEN" "$manual_code"; then break
        else _log_box_error "Kode salah atau tidak valid. Coba lagi."; fi
    done
    
    if [ -f "$G_TOKEN_FILE" ]; then
        _log_box_ok "🎉 SETUP SELESAI! Otorisasi berhasil."
    else
        _log_box_error "SETUP GAGAL. Coba periksa kembali semua langkah."
    fi
    _log_box_footer
}

function start() { clear;display_header;_log_box_header "Memulai Listener"; if [ ! -f "$CONFIG_DEVICE" ]||[ ! -f "$G_TOKEN_FILE" ];then _log_box_error "Konfigurasi/token tidak ditemukan. Jalankan Setup!";_log_box_footer;return;fi;if [ -f "$PID_FILE" ]&&ps -p "$(cat "$PID_FILE")" >/dev/null;then _log_box_warn "Listener sudah berjalan.";_log_box_footer;return;fi;_generate_py_scripts;nohup python "$PY_LISTENER" >/dev/null 2>&1 & echo $! > "$PID_FILE";_log_box_ok "Listener dimulai (PID: $(cat "$PID_FILE")). Cek log di '$LOG_FILE'." ;_log_box_footer;}
function stop() { clear;display_header;_log_box_header "Menghentikan Listener"; if [ ! -f "$PID_FILE" ];then _log_box_warn "Listener tidak sedang berjalan.";_log_box_footer;return;fi;local pid=$(cat "$PID_FILE");if ps -p "$pid" >/dev/null;then kill "$pid";rm -f "$PID_FILE";_log_box_ok "Listener (PID: $pid) telah dihentikan.";else _log_box_warn "Proses (PID: $pid) tidak ditemukan. File PID dihapus.";rm -f "$PID_FILE";fi;_log_box_footer;}
function logs() { clear;display_header;_log_box_header "Melihat Log Realtime";if [ ! -f "$LOG_FILE" ];then _log_box_warn "File log belum ada.";_log_box_footer;return;fi;_log_box_line "Menampilkan log... Tekan ${C_BOLD}Ctrl+C${C_RESET}${C_CYAN} untuk keluar.";_log_box_footer; echo; tail -f "$LOG_FILE" ;}
function cleanup() { clear;display_header;_log_box_header "Pembersihan Total";_log_box_warn "Ini akan menghapus SEMUA file konfigurasi & token.";read -p "   Anda yakin ingin melanjutkan? (y/n): " confirm;if [[ "$confirm" =~ ^[Yy]$ ]];then stop >/dev/null 2>&1||true;_log_box_line "Menghapus file...";rm -f "$CONFIG_DEVICE" "$G_TOKEN_FILE" "$G_CREDS_FILE" "$PY_HELPER_TOKEN" "$PY_LISTENER" ".patch_installed" "$LOG_FILE" "$PID_FILE";_log_box_ok "Pembersihan selesai.";else _log_box_line "Pembersihan dibatalkan.";fi;_log_box_footer;}
function run_patcher() { set -e;clear;display_header;_log_box_header "Persiapan Lingkungan Otomatis";readonly PKS=("python" "termux-api" "coreutils");readonly PYR=("google-api-python-client" "google-auth-httplib2" "google-auth-oauthlib");_log_box_line "${C_BOLD}Langkah 1/3:${C_RESET}${C_CYAN} Memeriksa paket sistem...";pkg update -y >/dev/null 2>&1;for p in "${PKS[@]}";do if ! dpkg -s "$p">/dev/null 2>&1;then _log_box_warn "Menginstal '$p'...";pkg install -y "$p";fi;done;_log_box_ok "Paket sistem siap.";_log_box_line "${C_BOLD}Langkah 2/3:${C_RESET}${C_CYAN} Memeriksa library Python...";for r in "${PYR[@]}";do if ! pip show "$r">/dev/null 2>&1;then _log_box_warn "Menginstal '$r'...";pip install --no-cache-dir "$r";fi;done;_log_box_ok "Library Python siap.";_log_box_line "${C_BOLD}Langkah 3/3:${C_RESET}${C_CYAN} Izin penyimpanan...";if [ ! -d "$HOME/storage/shared" ];then termux-setup-storage;_log_box_warn "Izin diminta, mohon konfirmasi...";sleep 5;fi;_log_box_ok "Izin penyimpanan siap.";echo;_log_box_ok "✅ LINGKUNGAN SUDAH SIAP! ✅";set +e;_log_box_footer;}

# --- [ FUNGSI TAMPILAN UTAMA ] ---
function display_header() {
    local status_text; local status_color; local pid_text=""
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" >/dev/null; then
        status_text="A K T I F"; status_color="$C_GREEN"
        pid_text="(PID: $(cat "$PID_FILE"))"
    else
        status_text="TIDAK AKTIF"; status_color="$C_RED"
    fi
    echo -e "${C_PURPLE}"
    echo '  ╔══════════════════════════════════════════════════════════════════╗'
    echo -e "  ║         ${C_BOLD}${C_WHITE}Ⓜ Ⓐ Ⓦ Ⓦ  -  Ⓢ Ⓒ Ⓡ Ⓘ Ⓟ Ⓣ   v23 (Secure+)${C_RESET}${C_PURPLE}            ║"
    echo '  ╟──────────────────────────────────────────────────────────────────╢'
    printf "  ║ %-10s %-20s %-28s ║\n" "${C_WHITE}Status:" "${status_color}${status_text}${C_RESET}" "${C_YELLOW}${pid_text}${C_RESET}"
    echo '  ╚══════════════════════════════════════════════════════════════════╝'
    echo -e "${C_RESET}"
}
function display_menu() {
    echo -e "${C_CYAN}  ╔═════════════════════════[ Pilihan Menu ]═════════════════════════╗${C_RESET}"
    echo -e "${C_CYAN}  ║                                                                  ║${C_RESET}"
    echo -e "${C_CYAN}  ║   ${C_GREEN}1) 🚀  Mulai Listener${C_RESET}                       ${C_YELLOW}3) ⚙️   Setup / Konfigurasi Ulang${C_RESET}      ║${C_RESET}"
    echo -e "${C_CYAN}  ║   ${C_RED}2) 🛑  Hentikan Listener${C_RESET}                  ${C_PURPLE}4) 📜  Lihat Log Realtime${C_RESET}             ║${C_RESET}"
    echo -e "${C_CYAN}  ║                                                                  ║${C_RESET}"
    echo -e "${C_CYAN}  ╟──────────────────────────────────────────────────────────────────╢${C_RESET}"
    echo -e "${C_CYAN}  ║   ${C_BLUE}5) 🔧  Perbaiki Lingkungan${C_RESET}                ${C_RED}6) 🗑️   Hapus Semua Konfigurasi${C_RESET}        ║${C_RESET}"
    echo -e "${C_CYAN}  ║   ${C_WHITE}7) 🚪  Keluar${C_RESET}                                                           ║${C_RESET}"
    echo -e "${C_CYAN}  ║                                                                  ║${C_RESET}"
    echo -e "${C_CYAN}  ╚══════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo -en "\n${C_BOLD}${C_WHITE}  Pilih Opsi [1-7] ❯ ${C_RESET}"
    read -n 1 choice
    echo
    case $choice in
        '1') start;;
        '2') stop;;
        '3') setup;;
        '4') logs;;
        '5') run_patcher; touch .patch_installed ;;
        '6') cleanup;;
        '7') echo -e "\n${C_PURPLE}Sampai jumpa lagi, Senpai!${C_RESET}"; exit 0;;
        *) echo -e "\n${C_RED}Pilihan tidak valid.${C_RESET}";;
    esac
    echo -e "\n${C_DIM}Tekan [Enter] untuk kembali ke menu...${C_RESET}"
    read -r
}

function main() {
    if [ ! -f ".patch_installed" ]; then
        clear; display_header
        _log_box_header "Selamat Datang di Maww Script!"
        _log_box_line "Ini adalah eksekusi pertama, skrip akan menyiapkan lingkungan."
        _log_box_warn "Pastikan 'credentials.json' (tipe Web App) ada di folder Download."
        _log_box_footer
        read -p "   Tekan [Enter] untuk memulai persiapan..."
        run_patcher
        _log_box_line "Membuat file penanda penyelesaian..."
        touch .patch_installed
        _log_box_ok "Penanda '.patch_installed' berhasil dibuat."
        read -p "   Tekan [Enter] untuk lanjut ke menu utama..."
    fi
    while true; do
        clear
        display_header
        display_menu
    done
}

# --- [ MULAI EKSEKUSI ] ---
main
