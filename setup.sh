#!/bin/bash

# Muzly Quick Setup Script
# Use this if you already have the repository cloned

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "========================================"
echo "   Muzly Quick Setup"
echo "========================================"
echo ""

# Check if .env exists
if [ -f ".env" ]; then
    log_warning ".env file already exists"
    read -p "Do you want to overwrite it? (y/N): " OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        log_info "Keeping existing .env file"
    fi
fi

# Prompt for configuration
read -p "Enter your domain (e.g., muzly.example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    log_error "Domain cannot be empty"
    exit 1
fi

read -p "Enter admin username (default: admin): " ADMIN_USERNAME
ADMIN_USERNAME=${ADMIN_USERNAME:-admin}

read -sp "Enter admin password: " ADMIN_PASSWORD
echo ""
if [ -z "$ADMIN_PASSWORD" ]; then
    log_error "Password cannot be empty"
    exit 1
fi

read -sp "Confirm admin password: " ADMIN_PASSWORD_CONFIRM
echo ""
if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
    log_error "Passwords do not match"
    exit 1
fi

echo ""
log_info "Choose database type:"
echo "1) SQLite (simple, single-user)"
echo "2) PostgreSQL (recommended for production)"
read -p "Select [1-2]: " DB_CHOICE

if [ "$DB_CHOICE" = "2" ]; then
    USE_POSTGRES=true
    read -p "Enter PostgreSQL password (default: random): " POSTGRES_PASSWORD
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-$(openssl rand -hex 16)}
else
    USE_POSTGRES=false
fi

# Generate JWT secret
JWT_SECRET=$(openssl rand -hex 32)

# Generate .env
log_info "Generating .env file..."

if [ "$USE_POSTGRES" = true ]; then
    cat > .env << EOF
# Database Configuration
DATABASE_URL=postgresql+asyncpg://postgres:${POSTGRES_PASSWORD}@postgres:5432/muzly
POSTGRES_DB=muzly
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# Backend Configuration
PORT=8080

# JWT Settings
JWT_SECRET=${JWT_SECRET}
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=60

# Admin credentials
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# CORS Configuration
CORS_ORIGINS=https://${DOMAIN},http://localhost,http://localhost:3000

# File Upload Configuration
MAX_UPLOAD_SIZE=104857600

# Media Storage
MEDIA_ROOT=./media
COVERS_ROOT=./covers
IMPORT_DROP=./import_drop
EOF
else
    cat > .env << EOF
# Database Configuration
DATABASE_URL=sqlite+aiosqlite:///./muzly.db

# Backend Configuration
PORT=8080

# JWT Settings
JWT_SECRET=${JWT_SECRET}
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=60

# Admin credentials
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# CORS Configuration
CORS_ORIGINS=https://${DOMAIN},http://localhost,http://localhost:3000

# File Upload Configuration
MAX_UPLOAD_SIZE=104857600

# Media Storage
MEDIA_ROOT=./media
COVERS_ROOT=./covers
IMPORT_DROP=./import_drop
EOF
fi

# Update nginx config (HTTP only for initial cert)
cat > nginx/templates/muzly.conf.template << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    client_max_body_size 100m;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        proxy_pass http://backend:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

log_success "Configuration generated"

# Create directories
log_info "Creating directories..."
mkdir -p nginx/certbot/www nginx/certbot/conf
mkdir -p backend/media backend/uploads backend/public backend/import_drop backend/covers backend/data

# Start services
log_info "Starting Docker containers..."
if [ "$USE_POSTGRES" = true ]; then
    docker compose up -d postgres backend nginx certbot
else
    docker compose up -d backend nginx certbot
fi

log_info "Waiting for services to be ready..."
sleep 10

# Get SSL certificate
log_info "Obtaining SSL certificate..."
docker compose run --rm --entrypoint certbot certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "admin@${DOMAIN}" \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d "${DOMAIN}"

# Restart nginx
log_info "Restarting nginx..."
cat > nginx/templates/muzly.conf.template << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    client_max_body_size 100m;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name ${DOMAIN};
    client_max_body_size 100m;

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    location / {
        proxy_pass http://backend:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
docker compose restart nginx

echo ""
echo "========================================"
log_success "Setup completed!"
echo "========================================"
echo ""
echo "Access Muzly at: https://${DOMAIN}"
echo "Username: ${ADMIN_USERNAME}"
echo "Password: ${ADMIN_PASSWORD}"
echo ""
