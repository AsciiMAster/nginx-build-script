#!/bin/bash
# This script installs Nginx from source.
# It downloads the specified version, compiles it, and installs it.
# You need to specif version of nginx
# Make sure to run this script as root (or via sudo).

set -e  # Exit immediately if a command exits with a non-zero status.

# Check if running as root.
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo." >&2
  exit 1
fi

# Specify the Nginx version to install.
NGINX_VERSION="1.27.4"  # Change this to your desired version.
NGINX_TARBALL="nginx-${NGINX_VERSION}.tar.gz"
NGINX_DOWNLOAD_URL="http://nginx.org/download/${NGINX_TARBALL}"

# Define a working directory for building Nginx.
WORKDIR="/usr/local/src/nginx_install"

# Install necessary build dependencies.
echo "Installing dependencies..."
apt-get update
apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev wget

# Create and move into the working directory.
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Download the Nginx source tarball.
echo "Downloading Nginx version ${NGINX_VERSION}..."
wget "${NGINX_DOWNLOAD_URL}" -O "${NGINX_TARBALL}"

# Extract the tarball.
echo "Extracting ${NGINX_TARBALL}..."
tar -xzvf "${NGINX_TARBALL}"

# Change into the Nginx source directory.
cd "nginx-${NGINX_VERSION}"

# Configure Nginx with some common options.
# Adjust the configuration options as needed.
echo "Configuring Nginx..."
./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/bin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --with-pcre \
  --pid-path=/var/run/nginx.pid \
  --with-http_ssl_module \
  --with-http_v2_module

# Build Nginx.
echo "Building Nginx..."
make

# Install Nginx.
echo "Installing Nginx..."
make install

echo "Nginx installation completed!"
echo "You can now configure /etc/nginx/nginx.conf and start Nginx with:"
echo "    sudo /usr/sbin/nginx"

echo "Setting up systemd unit file at /lib/systemd/system/nginx.service..."
cat << 'EOF' > /lib/systemd/system/nginx.service
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF


# Reload systemd and Enable Nginx Service
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling Nginx to start at boot..."
systemctl enable nginx

echo "Starting Nginx..."
systemctl start nginx

echo "Nginx installation and service setup completed!"
echo "You can check the status with: systemctl status nginx"