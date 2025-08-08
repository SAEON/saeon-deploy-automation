#!/bin/bash

# Exit on error
set -e 

SERVER_ENV="$1"
BASE_DIR="/opt/apps/saeon/$SERVER_ENV"
LOG_DIR="/opt/apps/saeon/$SERVER_ENV/logs"


# Check for app name
if [ -z "$SERVER_ENV" ]; then
  echo "No server environment specified."
  echo "Example: $0 dev or $0 prod"
  exit 1
fi

echo "Starting setup for '$SERVER_ENV' environment..."


# --- System Update & Essentials ---
echo "Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y
echo "🔧  Installing essential packages..."

sudo apt-get install -y \
  git \
  curl \
  ca-certificates \
  gnupg \
  lsb-release \
  software-properties-common


echo "✅  System packages updated and essential packages installed."

# --- Installing docker ---
echo "Installing docker..."

sudo mkdir -p /etc/apt/keyrings 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg                                                                                                                    
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "✅  Docker installed successfully."

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER


#--- NGINX Installation ---
echo "Installing NGINX..."
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
echo "✅  NGINX installed and started successfully."


#--- Create app directory structure ---
if [ ! -d "$BASE_DIR" ]; then
  echo "Creating app directory structure at $BASE_DIR..."
  sudo mkdir -p "$BASE_DIR"
else
  echo "App directory already exists at $BASE_DIR."
fi

if [ ! -d "$LOG_DIR" ]; then
  echo "Creating log directory at $LOG_DIR..."
  sudo mkdir -p "$LOG_DIR"
else
  echo "Log directory already exists at $LOG_DIR."
fi


# --- Environment-Specific Notices ---
if [ "$SERVER_ENV" == "prod" ]; then
  echo " Production environment detected!"
  echo " Remember to configure your firewall and security settings."
elif [ "$SERVER_ENV" == "dev" ]; then
  echo " Development environment detected!"
  echo " Ensure you have the necessary debugging tools installed."
fi


echo "✅  Setup for '$SERVER_ENV' completed successfully."
