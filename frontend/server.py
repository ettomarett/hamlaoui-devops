#!/usr/bin/env python3
"""
Simple HTTP Server with CORS support for E-Commerce Microservices Frontend
"""

import http.server
import socketserver
import os
import sys
from http.server import SimpleHTTPRequestHandler

class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Enable CORS for all origins
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()

    def do_OPTIONS(self):
        # Handle preflight requests
        self.send_response(200)
        self.end_headers()

    def log_message(self, format, *args):
        # Custom log format
        print(f"[{self.log_date_time_string()}] {format % args}")

def run_server(port=8000):
    """Run the HTTP server with CORS support"""
    
    # Change to the directory containing the frontend files
    frontend_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(frontend_dir)
    
    # Create server
    handler = CORSRequestHandler
    
    try:
        with socketserver.TCPServer(("", port), handler) as httpd:
            print("=" * 60)
            print("🚀 E-Commerce Microservices Frontend Server")
            print("=" * 60)
            print(f"📂 Serving directory: {frontend_dir}")
            print(f"🌐 Server running at: http://localhost:{port}")
            print(f"📱 Open in browser: http://localhost:{port}")
            print("=" * 60)
            print("📊 Connected to Spring Boot Services:")
            print("   • Product Service:   http://20.86.144.152:31309")
            print("   • Inventory Service: http://20.86.144.152:31081")
            print("   • Order Service:     http://20.86.144.152:31004")
            print("=" * 60)
            print("Press Ctrl+C to stop the server")
            print("=" * 60)
            
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
    except OSError as e:
        if e.errno == 48:  # Port already in use
            print(f"❌ Error: Port {port} is already in use")
            print(f"💡 Try a different port: python server.py {port + 1}")
        else:
            print(f"❌ Error starting server: {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

if __name__ == "__main__":
    port = 8000
    
    # Allow custom port via command line argument
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print("❌ Invalid port number. Using default port 8000.")
            port = 8000
    
    run_server(port) 