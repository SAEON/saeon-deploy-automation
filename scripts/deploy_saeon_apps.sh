#!/bin/bash
REPO_BASE="https://github.com/SAEON"


# Check for app name and environment
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <env> <app-name>"
  echo " Example: $0 dev agri-census "
  exit 1
fi

ENV="$1"
APP_NAME="$2"

BASE_DIR="/opt/apps/saeon/$ENV"
LOG_DIR="/opt/apps/saeon/$ENV/logs"

APP_DIR="$BASE_DIR/$APP_NAME"
REPO="$REPO_BASE/$APP_NAME.git"


# Step 1: Validate app directory exists
if [ ! -d "$APP_DIR" ]; then
  echo "App directory $APP_DIR does not exist."
  exit 1
fi

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/deploy-${APP_NAME}-$(date +%Y%m%d-%H%M%S).log"

echo " Starting deployment for '$APP_NAME' on $ENV..." | tee -a "$LOG_FILE"


# Step 2: Clone if not already a Git repo
if [ ! -d "$APP_DIR/.git" ]; then
  echo "Cloning repository for '$APP_NAME'..." | tee -a "$LOG_FILE"
  git clone "$REPO" "$APP_DIR" >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    echo "Failed to clone repository $REPO" | tee -a "$LOG_FILE"
    exit 1
  fi
elif [ -d "$APP_DIR/.git" ]; then
  echo " Existing repository detected. Will pull latest changes." | tee -a "$LOG_FILE"
  cd "$APP_DIR" || exit 1
  git pull >> "$LOG_FILE" 2>&1
else
  echo " Warning: '$APP_NAME' is not a Git repository. Skipping git pull." | tee -a "$LOG_FILE"
fi

# Step 3: Rebuild and restart Docker container
echo "  Rebuilding Docker image..." | tee -a "$LOG_FILE"
TAG="$(date +%Y%m%d-%H%M)-$(git rev-parse --short HEAD)"
export TAG

echo " Using image tag: $TAG" | tee -a "$LOG_FILE"

if [ ! -f "docker-compose.yml" ]; then
  echo "docker-compose.yml not found in $APP_DIR. Cannot proceed with deployment." | tee -a "$LOG_FILE"
  exit 1
fi

# Step 4: Check if .env file exists
echo "checking .env file..." | tee -a "$LOG_FILE"
cd "$APP_DIR" || exit 1
if [ ! -f ".env" ]; then
  echo "Warning:  .env file missing in $APP_DIR. Double check if the app is configured correctly." | tee -a "$LOG_FILE"
fi


# Step 5: Stop existing container, then rebuild and start new one
docker compose down >> "$LOG_FILE" 2>&1
docker compose up --build -d >> "$LOG_FILE" 2>&1


# Step 6: Reload NGINX
echo "Reloading NGINX..." | tee -a "$LOG_FILE"
sudo nginx -t && sudo systemctl reload nginx >> "$LOG_FILE" 2>&1

echo "Deployment for '$APP_NAME' complete in $ENV environment." | tee -a "$LOG_FILE"

