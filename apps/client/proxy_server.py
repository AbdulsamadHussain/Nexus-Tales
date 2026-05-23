#!/usr/bin/env python3
"""
Combined Flutter web static server + Ollama CORS proxy for LAN play testing.

  Static files : http://0.0.0.0:5000/         → served from build/web/
  Ollama proxy : http://0.0.0.0:5000/ollama/  → forwarded to 127.0.0.1:11434

The Flutter app sets OLLAMA_URL=http://<LAN-IP>:5000/ollama in .env.
Requests arriving at /ollama/api/generate are forwarded to the local Ollama
instance, which never needs to be exposed to the network directly.

Supports both streaming (Transfer-Encoding: chunked) and regular responses.
"""

import http.server
import http.client
import json
import os
import sys

BUILD_DIR   = os.path.join(os.path.dirname(__file__), "build", "web")
OLLAMA_HOST = "127.0.0.1"
OLLAMA_PORT = 11434
LISTEN_PORT = 5000


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BUILD_DIR, **kwargs)

    # ── CORS pre-flight ──────────────────────────────────────────────
    def do_OPTIONS(self):
        self.send_response(200)
        self._add_cors()
        self.end_headers()

    # ── Ollama proxy ─────────────────────────────────────────────────
    def do_POST(self):
        if not self.path.startswith("/ollama"):
            self.send_response(405)
            self.end_headers()
            return

        # Strip /ollama prefix → forward to Ollama's actual path
        ollama_path = self.path[len("/ollama"):] or "/api/generate"

        length = int(self.headers.get("Content-Length", 0))
        body   = self.rfile.read(length)

        try:
            conn = http.client.HTTPConnection(OLLAMA_HOST, OLLAMA_PORT, timeout=120)
            conn.request(
                "POST",
                ollama_path,
                body,
                {"Content-Type": "application/json"},
            )
            resp = conn.getresponse()
            data = resp.read()

            self.send_response(resp.status)
            self._add_cors()
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        except OSError as exc:
            error = json.dumps({"error": f"Ollama unreachable: {exc}"}).encode()
            self.send_response(503)
            self._add_cors()
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(error)))
            self.end_headers()
            self.wfile.write(error)

    # ── Helpers ──────────────────────────────────────────────────────
    def _add_cors(self):
        self.send_header("Access-Control-Allow-Origin",  "*")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

    def log_message(self, fmt, *args):  # keep console clean
        print(f"  {self.address_string()}  {fmt % args}")


if __name__ == "__main__":
    if not os.path.isdir(BUILD_DIR):
        print(f"ERROR: build/web not found at {BUILD_DIR}")
        print("Run: flutter build web --release")
        sys.exit(1)

    server = http.server.HTTPServer(("0.0.0.0", LISTEN_PORT), Handler)
    print(f"Nexus-Tale LAN server running:")
    print(f"  Flutter app  →  http://0.0.0.0:{LISTEN_PORT}/")
    print(f"  Ollama proxy →  http://0.0.0.0:{LISTEN_PORT}/ollama/")
    print(f"Open on devices: http://192.168.2.22:{LISTEN_PORT}")
    server.serve_forever()
