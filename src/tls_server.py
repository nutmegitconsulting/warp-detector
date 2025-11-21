import ssl
import http.server
import os

# --- Configuration ---
HOST_IP = '0.0.0.0'
PORT = 443
CERT_DIR = '/certs'
CERT_FILE = os.path.join(CERT_DIR, 'homelan.pem')
KEY_FILE = os.path.join(CERT_DIR, 'homelan.key')

class SimpleHTTPRequestHandler(http.server.BaseHTTPRequestHandler):
    """Simple request handler that responds with 'OK'."""
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'OK')
        return

def run_server():
    """Sets up and runs the HTTPS server."""
    if not all([os.path.exists(f) for f in [CERT_FILE, KEY_FILE]]):
        print(f"Error: Certificate or key file not found in {CERT_DIR}")
        print("Please ensure the volume is mounted correctly and setup has been run.")
        return

    try:
        # Create a server instance
        httpd = http.server.HTTPServer((HOST_IP, PORT), SimpleHTTPRequestHandler)

        # Create an SSL context
        ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
        ssl_context.load_cert_chain(certfile=CERT_FILE, keyfile=KEY_FILE)

        # Wrap the server socket with SSL
        httpd.socket = ssl_context.wrap_socket(httpd.socket, server_side=True)
        
        print(f"Server starting on https://{HOST_IP}:{PORT}")
        httpd.serve_forever()

    except Exception as e:
        print(f"Failed to start server: {e}")

if __name__ == "__main__":
    run_server()
