#!/usr/bin/env python3
"""
Cloud Proxy Server for E-Commerce Microservices Frontend
Serves static files and proxies API requests to cloud services
"""

import http.server
import socketserver
import urllib.request
import urllib.parse
import json
import os
import sys
from urllib.error import URLError, HTTPError

class CloudProxyHandler(http.server.SimpleHTTPRequestHandler):
    
    # Cloud service endpoints
    SERVICES = {
        'product': 'http://20.86.144.152:31309',
        'inventory': 'http://20.86.144.152:31081', 
        'order': 'http://20.86.144.152:31004'
    }
    
    def end_headers(self):
        # Enable CORS for all requests
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        super().end_headers()

    def do_OPTIONS(self):
        # Handle preflight requests
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        if self.path.startswith('/api/'):
            self.handle_api_request()
        else:
            # Serve static files
            super().do_GET()

    def do_POST(self):
        if self.path.startswith('/api/'):
            self.handle_api_request()
        else:
            self.send_error(405, 'Method Not Allowed')

    def handle_api_request(self):
        try:
            # Determine target service
            target_url = None
            if self.path.startswith('/api/product'):
                target_url = f"{self.SERVICES['product']}{self.path}"
            elif self.path.startswith('/api/inventory'):
                target_url = f"{self.SERVICES['inventory']}{self.path}"
            elif self.path.startswith('/api/order'):
                target_url = f"{self.SERVICES['order']}{self.path}"
            else:
                self.send_error(404, 'API endpoint not found')
                return

            print(f"🔄 Proxying {self.command} {self.path} → {target_url}")

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
            with urllib.request.urlopen(req, timeout=30) as response:
                response_data = response.read()
                
                self.send_response(response.status)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(response_data)
                
                print(f"✅ Success: {response.status} - {len(response_data)} bytes")

        except HTTPError as e:
            print(f"❌ HTTP Error: {e.code} - {e.reason}")
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            try:
                error_data = e.read()
                self.wfile.write(error_data)
            except:
                error_msg = json.dumps({'error': f'HTTP {e.code}: {e.reason}'})
                self.wfile.write(error_msg.encode())
                
        except URLError as e:
            print(f"❌ URL Error: {e.reason}")
            self.send_response(503)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_msg = json.dumps({'error': f'Service unavailable: {e.reason}'})
            self.wfile.write(error_msg.encode())
            
        except Exception as e:
            print(f"❌ Unexpected Error: {str(e)}")
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_msg = json.dumps({'error': f'Internal server error: {str(e)}'})
            self.wfile.write(error_msg.encode())

    def log_message(self, format, *args):
        # Custom log format
        print(f"[{self.log_date_time_string()}] {format % args}")

def run_server(port=8080):
    """Run the cloud proxy server"""
    
    # Change to the directory containing the frontend files
    frontend_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(frontend_dir)
    
    try:
        with socketserver.TCPServer(("0.0.0.0", port), CloudProxyHandler) as httpd:
            print("=" * 70)
            print("🚀 E-Commerce Cloud Proxy Server")
            print("=" * 70)
            print(f"📂 Serving static files from: {frontend_dir}")
            print(f"🌐 Frontend URL: http://localhost:{port}")
            print(f"📱 Open in browser: http://localhost:{port}")
            print("=" * 70)
            print("🔄 API Proxy Routes:")
            print(f"   • /api/product/*   → http://20.86.144.152:31309")
            print(f"   • /api/inventory/* → http://20.86.144.152:31081")
            print(f"   • /api/order/*     → http://20.86.144.152:31004")
            print("=" * 70)
            print("✨ Features:")
            print("   • ✅ CORS enabled for all origins")
            print("   • 📁 Static file serving")
            print("   • 🔄 API request proxying")
            print("   • 📊 Request logging")
            print("=" * 70)
            print("Press Ctrl+C to stop the server")
            print("=" * 70)
            
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except OSError as e:
        if e.errno == 48 or "already in use" in str(e).lower():
            print(f"❌ Error: Port {port} is already in use")
            print(f"💡 Try a different port: python cloud_proxy.py {port + 1}")
        else:
            print(f"❌ Error starting server: {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

if __name__ == "__main__":
    port = 8080
    
    # Allow custom port via command line argument
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print("❌ Invalid port number. Using default port 8080.")
            port = 8080
    
    run_server(port) 