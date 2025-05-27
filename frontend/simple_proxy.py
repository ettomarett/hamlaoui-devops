#!/usr/bin/env python3
import http.server
import socketserver
import urllib.request
import urllib.parse
import json
import sys
from urllib.error import URLError, HTTPError

class SimpleProxyHandler(http.server.BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def do_GET(self):
        self.handle_request()

    def do_POST(self):
        self.handle_request()

    def handle_request(self):
        try:
            # Determine target service
            if self.path.startswith('/api/product'):
                target_url = f'http://localhost:31309{self.path}'
            elif self.path.startswith('/api/inventory'):
                target_url = f'http://localhost:31081{self.path}'
            elif self.path.startswith('/api/order'):
                target_url = f'http://localhost:31004{self.path}'
            else:
                self.send_error(404, 'API endpoint not found')
                return

            # Get request body for POST requests
            content_length = int(self.headers.get('Content-Length', 0))
            request_body = self.rfile.read(content_length) if content_length > 0 else None

            # Create the proxied request
            req = urllib.request.Request(target_url, data=request_body)
            
            # Copy headers
            if self.headers.get('Content-Type'):
                req.add_header('Content-Type', self.headers.get('Content-Type'))
            
            req.get_method = lambda: self.command

            # Make the request
            with urllib.request.urlopen(req, timeout=10) as response:
                response_data = response.read()
                
                self.send_response(200)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
                self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(response_data)

        except HTTPError as e:
            self.send_response(e.code)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            self.send_response(500)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_msg = json.dumps({'error': str(e)})
            self.wfile.write(error_msg.encode())

def run_server(port):
    with socketserver.TCPServer(("0.0.0.0", port), SimpleProxyHandler) as httpd:
        print(f"🚀 Simple Proxy Server running on port {port}")
        print(f"📊 Forwarding:")
        print(f"   • /api/product/* → http://localhost:31309")
        print(f"   • /api/inventory/* → http://localhost:31081")
        print(f"   • /api/order/* → http://localhost:31004")
        httpd.serve_forever()

if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    run_server(port) 