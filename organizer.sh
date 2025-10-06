#!/bin/bash

# =================================================================================
#      🗂️  ORGANIZER Edisi PRO - The Intelligent Workspace Manager 🗂️
# =================================================================================
# Deskripsi:
# Rombakan total menjadi sebuah workspace manager cerdas. Tidak hanya membuat
# struktur folder, tapi juga memberikan laporan status dan menawarkan
# opsi pembersihan (cleanup) untuk menjaga lingkungan modding tetap efisien.
# =================================================================================

# --- [1] KONFIGURASI TAMPILAN & WARNA (tput) ---
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
PURPLE=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
GRAY=$(tput setaf 8)
NC=$(tput sgr0)
BOLD=$(tput bold)

# --- [2] KONFIGURASI GLOBAL ---
# Direktori root untuk semua aktivitas modding, agar terpusat.
readonly WORKSPACE_ROOT="$HOME/Maww-Workspace"
readonly PROJECTS_DIR="$WORKSPACE_ROOT/apk_projects"
readonly BUILDS_DIR="$WORKSPACE_ROOT/apk_builds"
readonly BUILDS_FINISHED_DIR="$BUILDS_DIR/finished"
readonly BUILDS_LOGS_DIR="$BUILDS_DIR/logs"
readonly SIGNED_DIR="$WORKSPACE_ROOT/apk_signed"
readonly MOD_LOGS_DIR="$PROJECTS_DIR/logs" # Log dari MOD-APK.sh

# --- [3] FUNGSI UTILITY & UI ---
log_msg() {
    local type="$1" color="$NC" prefix=""
    case "$type" in
        INFO)    prefix="[i] INFO"    ; color="$CYAN"   ;;
        SUCCESS) prefix="[✓] SUKSES"  ; color="$GREEN"  ;;
        WARN)    prefix="[!] PERINGATAN"; color="$YELLOW" ;;
        ERROR)   prefix="[✘] ERROR"   ; color="$RED"    ;;
        STEP)    prefix="[»] LANGKAH" ; color="$BLUE"   ;;
    esac
    echo -e "${BOLD}${color}${prefix}${NC} : $2"
}

print_header() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo '  █▀█ █▀█ █▀▀ ▄▀█ █▄░█ █ ATC █▀▄ █▀'
    echo '  █▀▄ █▄█ ██▄ █▀█ █░▀█ █ ▄▄█ █▄▀ ▄█'
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo -e "${BOLD}${WHITE}  The Intelligent Workspace Manager${NC}"
    echo -e "${RED}-----------------------------------------------------------${NC}"
    echo
}

# --- [4] FUNGSI INTI ---

# Membuat struktur direktori yang dibutuhkan oleh semua skrip PRO Series
create_structure() {
    log_msg STEP "Membuat & Memverifikasi Struktur Workspace"
    
    local dirs_to_create=(
        "$PROJECTS_DIR"
        "$BUILDS_FINISHED_DIR"
        "$BUILDS_LOGS_DIR"
        "$SIGNED_DIR"
        "$MOD_LOGS_DIR"
    )

    for dir in "${dirs_to_create[@]}"; do
        mkdir -p "$dir"
    done
    
    log_msg SUCCESS "Struktur direktori di '${GRAY}$WORKSPACE_ROOT${NC}' sudah siap."
}

# Memberikan laporan status workspace
generate_report() {
    log_msg STEP "Menganalisis & Membuat Laporan Status Workspace"
    
    # Menghitung item
    local project_count=$(find "$PROJECTS_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    local built_apk_count=$(find "$BUILDS_FINISHED_DIR" -type f -name "*.apk" 2>/dev/null | wc -l)
    local signed_apk_count=$(find "$SIGNED_DIR" -type f -name "*.apk" 2>/dev/null | wc -l)
    local total_logs_count=$(find "$BUILDS_LOGS_DIR" "$MOD_LOGS_DIR" -type f -name "*.log" 2>/dev/null | wc -l)
    local workspace_size=$(du -sh "$WORKSPACE_ROOT" 2>/dev/null | awk '{print $1}')

    # Menampilkan laporan dalam tabel
    echo -e "  ${BLUE}╔═════════════════════════════════════════════════════╗"
    echo -e "  ${BLUE}║${NC} ${BOLD}${WHITE}             LAPORAN STATUS WORKSPACE              ${BLUE}║"
    echo -e "  ${BLUE}╚═════════════════════════════════════════════════════╝${NC}"
    printf "  ${CYAN}%-25s${NC} : ${WHITE}%s Proyek${NC}\n" "Proyek Modding Aktif" "$project_count"
    printf "  ${CYAN}%-25s${NC} : ${WHITE}%s APK${NC}\n" "APK Hasil Build" "$built_apk_count"
    printf "  ${CYAN}%-25s${NC} : ${WHITE}%s APK${NC}\n" "APK Final (Signed)" "$signed_apk_count"
    printf "  ${CYAN}%-25s${NC} : ${WHITE}%s File Log${NC}\n" "Total File Log Tersimpan" "$total_logs_count"
    echo -e "  ${BLUE}-----------------------------------------------------------${NC}"
    printf "  ${CYAN}%-25s${NC} : ${YELLOW}%s${NC}\n" "Total Ukuran Workspace" "$workspace_size"
    echo
}

# Menawarkan opsi pembersihan
perform_cleanup() {
    log_msg STEP "Opsi Pembersihan Workspace"
    read -rp ">> Apakah Anda ingin melakukan pembersihan? (y/n): " choice
    if [[ "$choice" != "y" ]]; then
        log_msg INFO "Pembersihan dilewati."
        return
    fi
    
    echo "Pilih item yang ingin dibersihkan:"
    select action in "Hapus SEMUA file log" "Hapus folder build temporer" "BATAL"; do
        case $action in
            "Hapus SEMUA file log")
                read -rp ">> ${RED}YAKIN ingin menghapus ${total_logs_count} file log? (y/n):${NC} " confirm
                if [[ "$confirm" == "y" ]]; then
                    log_msg INFO "Menghapus file log..."
                    find "$BUILDS_LOGS_DIR" "$MOD_LOGS_DIR" -type f -name "*.log" -delete
                    log_msg SUCCESS "Semua file log telah dibersihkan."
                else
                    log_msg INFO "Dibatalkan."
                fi
                break
                ;;
            "Hapus folder build temporer")
                log_msg INFO "Mencari folder 'build_temp_*' di $HOME..."
                find "$HOME" -maxdepth 1 -type d -name "build_temp_*" -exec rm -rf {} +
                log_msg SUCCESS "Folder build temporer telah dibersihkan."
                break
                ;;
            "BATAL")
                log_msg INFO "Pembersihan dibatalkan."
                break
                ;;
            *)
                log_msg WARN "Pilihan tidak valid."
                ;;
        esac
    done
}

# =================================================
#                 PROGRAM UTAMA
# =================================================
main() {
    print_header

    if [ ! -d "$HOME/storage/shared" ]; then
        log_msg ERROR "Akses storage belum ada. Jalankan 'termux-setup-storage' dulu."
        exit 1
    fi
    
    create_structure
    echo
    generate_report
    echo
    perform_cleanup
    
    echo
    log_msg SUCCESS "Organizer PRO selesai menjalankan tugas!"
}

main
