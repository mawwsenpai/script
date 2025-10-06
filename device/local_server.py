# file: local_server.py
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
