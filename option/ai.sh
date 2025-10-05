# options/ai.sh

# Fungsi ini memerlukan 'jq' untuk mem-parsing JSON.
# Pastikan sudah diinstall (pkg install jq)

# Fungsi untuk meminta AI menjelaskan sebuah potongan kode Smali.
# Dia butuh satu argumen: potongan kode Smali yang mau dianalisis.
ai_explain_smali_code() {
    local smali_code_to_analyze="$1"

    # Cek dulu API Key ada atau tidak, biar gak error
    if [ -z "$GEMINI_API_KEY" ]; then
        echo "ERROR: Variabel GEMINI_API_KEY belum diatur di config.sh!"
        return 1
    fi

    echo "🤖 [AI] Menghubungi server Gemini untuk menganalisis kode..."

    # Ini adalah "perintah" atau prompt yang akan kita kirim ke AI.
    # Kita minta dia jadi ahli dan menjelaskan kode.
    local prompt="Kamu adalah seorang ahli reverse engineering Android. Jelaskan apa fungsi dari metode Smali berikut ini dalam bahasa Indonesia yang mudah dimengerti. Fokus pada logikanya. Kode: \`\`\`smali\n${smali_code_to_analyze}\n\`\`\`"

    # Mengemas perintah kita ke dalam format JSON yang dimengerti oleh API
    local json_payload
    json_payload=$(jq -n \
                  --arg text "$prompt" \
                  '{contents: [{parts: [{text: $text}]}]}')

    # Mengirim data ke API Gemini menggunakan cURL dan menangkap responnya
    local response
    response=$(curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${GEMINI_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$json_payload")

    # Mengekstrak teks jawaban dari respon JSON yang kompleks
    local explanation
    explanation=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text')

    # Memeriksa apakah jawaban berhasil didapat atau tidak
    if [[ -z "$explanation" || "$explanation" == "null" ]]; then
        echo "❌ [AI] Gagal mendapatkan respon. Cek API Key atau koneksi internet."
        echo "   -> Respon mentah dari server: $response"
    else
        echo "✅ [AI] Hasil Analisis Gemini:"
        # Tampilkan hasil penjelasan dari AI dengan rapi
        echo -e "--------------------------------------------------\n$explanation\n--------------------------------------------------"
    fi
}
