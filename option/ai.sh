#!/bin/bash
# ===================================================================
#           🧠 AI Module (ai.sh) v1.0 🧠
#
#   Modul spesialis untuk berinteraksi dengan Google Gemini API.
#   Tugas: Menganalisis dan membuat patch kode Smali.
#   Membutuhkan: config.sh (untuk API Key) dan 'jq'.
# ===================================================================

# Fungsi untuk meminta AI menjelaskan sebuah potongan kode Smali.
# Argumen 1: Potongan kode Smali yang mau dianalisis.
ai_explain_smali_code() {
    local smali_code_to_analyze="$1"

    # Cek dulu API Key ada atau tidak.
    if [ -z "$GEMINI_API_KEY" ]; then
        log_msg ERROR "Variabel GEMINI_API_KEY belum diatur di config.sh!"
        return 1
    fi

    log_msg AI "Menghubungi server Gemini untuk menganalisis kode..."

    # Membuat "surat" atau prompt untuk AI.
    local prompt="Kamu adalah seorang ahli reverse engineering Android. Jelaskan apa fungsi dari metode Smali berikut ini dalam bahasa Indonesia yang mudah dimengerti. Fokus pada logikanya. Kode: \`\`\`smali\n${smali_code_to_analyze}\n\`\`\`"

    # Mengemas prompt ke dalam format JSON.
    local json_payload
    json_payload=$(jq -n \
                  --arg text "$prompt" \
                  '{contents: [{parts: [{text: $text}]}]}')

    # Mengirim permintaan ke API Gemini menggunakan cURL.
    local response
    response=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${GEMINI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$json_payload")

    # Mengekstrak teks jawaban dari respon JSON.
    local explanation
    explanation=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text')

    # Memeriksa dan menampilkan hasil.
    if [[ -z "$explanation" || "$explanation" == "null" ]]; then
        log_msg ERROR "Gagal mendapatkan respon. Cek API Key atau koneksi internet."
        log_msg ERROR "Respon mentah dari server: $response"
    else
        log_msg AI "Hasil Analisis Gemini:"
        echo -e "--------------------------------------------------\n$explanation\n--------------------------------------------------"
    fi
}

ai_generate_smali_patch() {
    local smali_code_to_patch="$1"
    local modification_request="$2"

    if [ -z "$GEMINI_API_KEY" ]; then
        log_msg ERROR "Variabel GEMINI_API_KEY belum diatur di config.sh!"
        return 1
    fi

    log_msg AI "Menghubungi server Gemini untuk membuatkan patch..."

    # Prompt diubah untuk menyuruh AI memodifikasi kode.
    local prompt="Kamu adalah seorang ahli modding Smali. Modifikasi total metode Smali berikut sesuai instruksi: \"${modification_request}\". HANYA KELUARKAN BLOK KODE SMALI LENGKAP YANG SUDAH JADI dari .method sampai .end method. Jangan ada penjelasan atau ```smali di awal dan akhir. Kode Asli: \`\`\`smali\n${smali_code_to_patch}\n\`\`\`"
    
    # Bagian JSON dan cURL sama persis seperti fungsi sebelumnya.
    local json_payload=$(jq -n --arg text "$prompt" '{contents: [{parts: [{text: $text}]}]}')
    local response=$(curl -s -X POST "[https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$](https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$){GEMINI_API_KEY}" -H "Content-Type: application/json" -d "$json_payload")
    local patched_code=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text')

    if [[ -z "$patched_code" || "$patched_code" == "null" ]]; then
        log_msg ERROR "Gagal membuat patch. Coba instruksi yang lebih jelas."
        log_msg ERROR "Respon mentah dari server: $response"
        return 1 # Mengembalikan status gagal
    else
        log_msg AI "Gemini telah membuatkan kode patch berikut:"
        echo -e "\033[0;32m$patched_code\033[0m"
        # Mengembalikan kode yang sudah di-patch lewat stdout untuk ditangkap script utama.
        echo "$patched_code"
        return 0 # Mengembalikan status sukses
    fi
}
