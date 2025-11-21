# **Cloudflare WARP Local Network Detector**

A simple, containerized TLS server designed to enable Cloudflare WARP's "Managed Network" feature for easy local network detection. This allows the WARP client to intelligently detect when it is on a trusted network and apply custom profiles, such as excluding local traffic from the tunnel. This container simplifies the process of setting up the [required TLS detection endpoint](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/managed-networks/).

## **Prerequisites**

Before you begin, ensure you have the following:

* A host machine (Linux, macOS, or Windows) with a static or DHCP-reserved IP address. A Linux host is recommended for easily running the service on system boot.  
* Docker Desktop installed.  
* A Cloudflare Zero Trust account.  
* Git installed on your host machine. (You can use a browser to download instead of launching Git, just [follow this link](https://github.com/nutmegitconsulting/warp-detector/archive/refs/heads/main.zip) to get the .zip file and unpack them all into a folder called warp-detector.)

## **Quick Start Guide**

This guide will walk you through building the container, generating your unique certificate, and starting the server.

**1\. Clone the Repository**

Open a terminal (or PowerShell) and clone the project files:

```
git clone https://github.com/nutmegitconsulting/warp-detector.git  
cd warp-detector
```

**2\. Build the Docker Image**

Build the local container image from the source code. This image will be named warp-detector-server.

```
sudo docker build -t warp-detector-server ./src
```

**3\. Run the One-Time Interactive Setup**

* This command starts the container in interactive mode (-it) and automatically removes it when finished (--rm). Its only purpose is to create your certificate files and display the information you need. The -v warp-certs:/certs part creates a persistent volume named warp-certs where your new certificate will be safely stored.

```
sudo docker run -it --rm -v warp-certs:/certs warp-detector-server setup
```
* Follow the On-Screen Prompts:  
   * The script will prompt you to enter a **hostname** (the default is warp-detector.homelan.local).  
   * It will then generate the certificate and print a summary of the critical information.
* Copy the Output: The script will display the SHA-256 Fingerprint. You will need this for the CloudFlare setup

**4\. Start the Container**

Run the container in detached mode to start the container in the background. It will automatically restart unless manually stopped.

```
sudo docker run -d --restart unless-stopped --name warp-detector -p 0.0.0.0:443:443 -v warp-certs:/certs --init warp-detector-server
```

**Note:** Note, this command serves the TLS certificate on every IP of the host machine. If you want to lock to a specific IP, replace 0.0.0.0 with the specific IP. If your host machine only ever has a single IP, you shouldn’t have to worry about this.


## **Configuration**

### **Part 1: Configure Cloudflare Zero Trust**

1. Log in to your Zero Trust dashboard and go to **Settings \> WARP Client**.  
2. Find the **Network locations** section and click **Add new**.  
3. Fill out the form with the following details:  
   * **Name:** A descriptive name, like Home LAN.  
   * **Host and Port:** The hostname you chose during setup followed by :443 (e.g., warp-detector.homelan.local:443).  
   * **TLS Cert SHA-256:** Paste the fingerprint you copied from the setup step.  
4. Click **Save**.

### **Part 2: Configure DNS**

For the WARP client to find your new container, you must make its hostname reachable. **Note:** If you used a static IP address instead of a hostname in Part 1 Step 3 Host and Port, then you don't have to do this step.

* Method 1 (Recommended): Local DNS Server  
  If you run a local DNS server, create a record that points the hostname to the internal IP address of the host running the Docker container.  
* Method 2: Edit hosts File  
  On each client device, manually edit the hosts file to add the entry provided by the setup script's output.  
  * **Windows:** C:\\Windows\\System\\drivers\\etc\\hosts  
  * **macOS / Linux:** /etc/hosts
 
### **Part 3: Confirm the setup**

A reliable test is to query the certificate fingerprint from a separate system on the same LAN. This validates that the container, the host firewall, and DNS resolution are working for your WARP clients successfully test for the presence of this TLS Endpoint.

Use one of the following commands to retrieve the SHA-256 fingerprint. It should match the fingerprint from the initial container setup and the Managed Network Location you built in Part 1: Configure Cloudflare Zero Trust.
* From Windows Powershell
  ```
  (openssl s_client -connect HOSTNAME_OR_IP:443 -servername HOSTNAME_OR_IP 2>$null <$null | openssl x509 -fingerprint -sha256 -noout).Split('=')[1].Replace(':','')
  ```
* From Linux Terminal
  ```
  openssl s_client -connect HOSTNAME_OR_IP:443 -servername HOSTNAME_OR_IP 2>/dev/null </dev/null | openssl x509 -fingerprint -sha256 -noout | cut -d'=' -f2 | tr -d ':'
  ```

### **Part 4: Create a Cloudflare Device Profile**

Create a new profile to apply custom rules when a device is on your managed network.

1. In the Zero Trust dashboard, navigate to **Settings \> WARP Client \> Device profiles**.  
2. Click **Create new profile** and give it a name (e.g., On-Prem LAN).  
3. Create an expression with the following:  
   * **Selector:** Managed network  
   * **Operator:** is  
   * **Value:** Select the network location you just created (Home LAN).  
4. Under **Split Tunnels**, click **Override** and add the IP address ranges of your local network to the **Exclude** list (e.g., 10.0.1.0/24).  
5. Save the profile and drag it to the top of the list to give it the highest priority.
6. For more details, refer to the [official CloudFlare documentation on Device Profiles](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/configure-warp/device-profiles/).

## **Making the Container Run on Startup**

For a reliable setup, the container should start automatically with the host machine.

* **On Linux:** The \--restart unless-stopped flag you already used is sufficient. Docker's systemd service will automatically start the container on boot. This is the recommended method for a headless container.  
* **On Windows / macOS:** Ensure that Docker Desktop is configured to launch on system startup ("Start Docker Desktop when you log in"). The \--restart policy will ensure your container starts whenever the Docker daemon is running.

## **Contributing**

Contributions are welcome\! Please feel free to submit a pull request or open an issue.

## **License**

This project is licensed under the MIT License.
