#!/usr/bin/env python3
import http.server
import os
import socketserver
import sys


class COOP_COEP_Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()


if __name__ == "__main__":
    PORT = 8000
    DIRECTORY = sys.argv[1] if len(sys.argv) > 1 else "."

    os.chdir(DIRECTORY)

    with socketserver.TCPServer(("", PORT), COOP_COEP_Handler) as httpd:
        print(
            f"Serving at http://localhost:{PORT} (COOP/COEP enabled for Godot/Threads)"
        )
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")
            sys.exit(0)
