#!/bin/bash

# Define the path for the certificate key
CERT_KEY_PATH="/certs/homelan.key"

# Function to run the interactive setup
run_setup() {
    echo "--- First-Time Setup ---"
    echo "This script will generate a unique TLS certificate for your network."
    
    # Prompt for hostname
    read -p "Enter a hostname for this detector [warp-detector.homelan.local]: " HOSTNAME
    HOSTNAME=${HOSTNAME:-warp-detector.homelan.local}

    echo "Generating certificate for ${HOSTNAME}..."
    
    # Create the certificate and key in the /certs volume
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
        -keyout /certs/homelan.key -out /certs/homelan.pem \
        -subj "/CN=${HOSTNAME}" \
        -addext "subjectAltName=DNS:${HOSTNAME}"

    echo "Certificate generated successfully."
    echo ""
    echo "--- CONFIGURATION DETAILS ---"
    echo "Copy the following information to configure Cloudflare and your clients:"
    echo ""
    
    # Calculate and display the SHA-256 fingerprint without colons
    echo "1. SHA-256 Fingerprint (for Cloudflare Managed Network):"
    FINGERPRINT=$(openssl x509 -noout -fingerprint -sha256 -inform pem -in /certs/homelan.pem | cut -d '=' -f 2 | tr -d ':')
    echo "${FINGERPRINT}"
    echo "sha256 fingerprints usually display with : between every two characters, but CloudFlare requires these to be removed. We took that step for you"
    echo ""
    echo "Setup complete. Refer to documentation for the next run step."
}

# --- Main Logic ---

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
exec python3 /app/tls_server.py
