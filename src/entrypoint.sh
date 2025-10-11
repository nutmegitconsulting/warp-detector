#!/bin/bash
set -e

# This script runs as root to handle file permissions, then drops privileges
# before executing the final python server process.

# --- Function to run the interactive setup ---
run_setup() {
    echo "--- First-Time Setup ---"
    echo "This script will generate a unique TLS certificate for your network."
    
    local CERT_KEY="/certs/homelan.key"
    local CERT_PEM="/certs/homelan.pem"

    # Prompt for hostname
    read -p "Enter a hostname for this detector [warp-detector.homelan.local]: " HOSTNAME
    HOSTNAME=${HOSTNAME:-warp-detector.homelan.local}

    echo "Generating certificate for ${HOSTNAME}..."
    
    # Create the certificate and key in the /certs volume
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
        -keyout "$CERT_KEY" -out "$CERT_PEM" \
        -subj "/CN=${HOSTNAME}" \
        -addext "subjectAltName=DNS:${HOSTNAME}"

    # ---> FIX #1: Change ownership of the new certs to the 'app' user <---
    chown app:app "$CERT_KEY" "$CERT_PEM"

    echo "Certificate generated successfully."
    echo ""
    echo "--- CONFIGURATION DETAILS ---"
    echo "Copy the following information to configure Cloudflare and your clients:"
    echo ""
    
    # Calculate and display the SHA-256 fingerprint without colons
    echo "1. SHA-256 Fingerprint (for Cloudflare Managed Network):"
    FINGERPRINT=$(openssl x509 -noout -fingerprint -sha256 -inform pem -in "$CERT_PEM" | cut -d '=' -f 2 | tr -d ':')
    echo "${FINGERPRINT}"
    echo "sha256 fingerprints usually display with : between every two characters, but CloudFlare requires these to be removed. We took that step for you"
    echo ""
    echo "Setup complete. Refer to documentation for the next run step."
}

# --- Main Logic ---
CERT_KEY_PATH="/certs/homelan.key"

# Check if the setup command was passed
if [ "$1" = "setup" ]; then
    run_setup
    # Exit after setup for the interactive run
    exit 0
fi

# If not in setup mode, check if the certificate exists
if [ ! -f "$CERT_KEY_PATH" ]; then
    # If the cert doesn't exist in a persistent run, guide the user.
    echo "Error: Certificate not found at ${CERT_KEY_PATH}."
    echo "Please run the one-time interactive setup first:"
    echo "docker run -it --rm -v warp-certs:/certs warp-detector-server setup"
    exit 1
fi

# If certificate exists, start the server
echo "Certificate found. Starting TLS server..."
# ---> FIX #2: Drop privileges and execute the server as the 'app' user <---
exec su -s /bin/sh -c 'python3 /app/tls_server.py' app
