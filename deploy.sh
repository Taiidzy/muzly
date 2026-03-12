#!/bin/bash

# Muzly Deployment Script
# This script sets up and deploys Muzly with SSL certificates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (sudo ./deploy.sh)"
        exit 1
    fi
}

# Check required tools
check_requirements() {
    log_info "Checking requirements..."
    
    local missing=()
    
    if ! command -v docker &> /dev/null; then
        missing+=("docker")
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        missing+=("docker-compose")
    fi
    
    if ! command -v certbot &> /dev/null; then
        missing+=("certbot")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        log_info "Install them with:"
        log_info "  Ubuntu/Debian: sudo apt install docker.io docker-compose certbot"
        log_info "  CentOS/RHEL: sudo yum install docker docker-compose certbot"
        exit 1
    fi
    
    log_success "All requirements met"
}

# Generate random JWT secret
generate_jwt_secret() {
    openssl rand -hex 32
}

# Prompt for configuration
prompt_configuration() {
    echo ""
    log_info "=== Muzly Configuration ==="
    echo ""
    
    # Domain
    read -p "Enter your domain (e.g., muzly.example.com): " DOMAIN
    if [ -z "$DOMAIN" ]; then
        log_error "Domain cannot be empty"
        exit 1
    fi
    
    # Admin username
    read -p "Enter admin username (default: admin): " ADMIN_USERNAME
    ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
    
    # Admin password
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
    
    # Database choice
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
        POSTGRES_PASSWORD=""
    fi
    
    echo ""
    log_success "Configuration complete!"
    echo ""
}

# Generate .env file
generate_env_file() {
    log_info "Generating .env file..."
    
    JWT_SECRET=$(generate_jwt_secret)
    
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
    
    # Create nginx config
    cat > nginx/templates/muzly.conf.template << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    client_max_body_size 50m;

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
    client_max_body_size 50m;

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
    
    log_success ".env and nginx config generated"
}

# Create required directories
create_directories() {
    log_info "Creating required directories..."
    
    mkdir -p nginx/certbot/www
    mkdir -p nginx/certbot/conf
    mkdir -p backend/media
    mkdir -p backend/uploads
    mkdir -p backend/public
    mkdir -p backend/import_drop
    mkdir -p backend/covers
    mkdir -p backend/data
    
    log_success "Directories created"
}

# Start Docker containers
start_docker() {
    log_info "Starting Docker containers..."
    
    if [ "$USE_POSTGRES" = true ]; then
        docker compose up -d --profile postgres backend nginx certbot
    else
        docker compose up -d backend nginx certbot
    fi
    
    log_success "Containers started"
}

# Get SSL certificate
get_ssl_certificate() {
    log_info "Obtaining SSL certificate..."
    
    # Run certbot to get initial certificate
    docker compose run --rm certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "admin@${DOMAIN}" \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d "${DOMAIN}"
    
    if [ $? -eq 0 ]; then
        log_success "SSL certificate obtained successfully"
    else
        log_error "Failed to obtain SSL certificate"
        log_info "Make sure your domain points to this server and port 80 is open"
        exit 1
    fi
}

# Restart nginx to apply SSL
restart_nginx() {
    log_info "Restarting nginx..."
    
    docker compose restart nginx
    
    log_success "Nginx restarted"
}

# Display summary
display_summary() {
    echo ""
    echo "========================================"
    log_success "Muzly deployment completed successfully!"
    echo "========================================"
    echo ""
    echo "Configuration:"
    echo "  Domain: https://${DOMAIN}"
    echo "  Username: ${ADMIN_USERNAME}"
    echo "  Password: ${ADMIN_PASSWORD}"
    if [ "$USE_POSTGRES" = true ]; then
        echo "  Database: PostgreSQL"
    else
        echo "  Database: SQLite"
    fi
    echo ""
    echo "Important files:"
    echo "  - .env (contains your credentials and secrets)"
    echo "  - nginx/templates/muzly.conf.template"
    echo ""
    echo "Useful commands:"
    echo "  docker compose ps                    # Check container status"
    echo "  docker compose logs -f backend       # View backend logs"
    echo "  docker compose logs -f nginx         # View nginx logs"
    echo "  docker compose down                  # Stop all containers"
    echo ""
    echo "Access your Muzly instance at: https://${DOMAIN}"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "========================================"
    echo "   Muzly Deployment Script"
    echo "========================================"
    echo ""
    
    # Check if we're in the project directory or need to clone
    if [ ! -f "docker-compose.yml" ]; then
        log_info "Muzly repository not found. Please clone it first:"
        echo "  git clone <repository-url> && cd muzly"
        echo ""
        read -p "Or enter the repository URL to clone: " REPO_URL
        if [ -n "$REPO_URL" ]; then
            git clone "$REPO_URL" muzly_temp
            cd muzly_temp
            mv ../.env.example .env 2>/dev/null || true
        else
            exit 1
        fi
    fi
    
    check_root
    check_requirements
    prompt_configuration
    create_directories
    generate_env_file
    start_docker
    
    log_info "Waiting for services to be ready..."
    sleep 10
    
    get_ssl_certificate
    restart_nginx
    display_summary
}

# Run main function
main
