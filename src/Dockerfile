# Use a lightweight, official Python image as the base
FROM python:3.13-slim

# Install OpenSSL for certificate generation
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

# Create a non-root user and group for running the application
RUN groupadd --system app && useradd --system --gid app app

# Set the working directory inside the container
WORKDIR /app

# Copy all the scripts and source code into the container
COPY . .

# Make the entrypoint script executable
RUN chmod +x /app/entrypoint.sh

# Change ownership of the app directory and its contents to the 'app' user.
RUN chown -R app:app /app

# Inform Docker that the container listens on port 4443
EXPOSE 443

# Set the entrypoint to our custom script.
ENTRYPOINT ["/app/entrypoint.sh"]
