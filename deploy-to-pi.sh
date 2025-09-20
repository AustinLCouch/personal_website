#!/bin/bash

# deploy-to-pi.sh - Complete deployment script for Raspberry Pi 5
# This script handles the entire deployment process including Docker setup,
# SSL certificates, and service management.

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration - EDIT THESE VALUES
PI_HOST="fillory.local"      # Your Pi's hostname or IP
PI_USER="syzygy"             # SSH user on the Pi
DOMAIN="your-domain.com"     # Your domain name (you'll need to set this)
EMAIL="your-email@example.com"  # Email for Let's Encrypt
PROJECT_NAME="personal_website"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if we're in the right directory
check_project_directory() {
    if [[ ! -f "Cargo.toml" ]] || [[ ! -f "Dockerfile" ]]; then
        log_error "Must run from project root directory with Cargo.toml and Dockerfile"
        exit 1
    fi
}

# Test SSH connection to Pi
test_ssh_connection() {
    log_info "Testing SSH connection to ${PI_USER}@${PI_HOST}..."
    if ssh -o ConnectTimeout=5 "${PI_USER}@${PI_HOST}" "echo 'SSH connection successful'" > /dev/null 2>&1; then
        log_success "SSH connection established"
    else
        log_error "Cannot connect to ${PI_USER}@${PI_HOST}"
        log_error "Please ensure:"
        log_error "1. Your Pi is powered on and connected to network"
        log_error "2. SSH is enabled on the Pi"
        log_error "3. You can SSH manually: ssh ${PI_USER}@${PI_HOST}"
        exit 1
    fi
}

# Update domain in configuration files
update_configuration() {
    log_info "Updating configuration files with domain: ${DOMAIN}"
    
    # Update nginx configuration
    sed -i.bak "s/your-domain\\.com/${DOMAIN}/g" nginx/conf.d/website.conf
    
    # Update docker-compose.yml
    sed -i.bak "s/your-email@example\\.com/${EMAIL}/g" docker-compose.yml
    sed -i.bak "s/your-domain\\.com/${DOMAIN}/g" docker-compose.yml
    
    log_success "Configuration files updated"
}

# Install Docker on Raspberry Pi if not present
install_docker_on_pi() {
    log_info "Checking Docker installation on Pi..."
    
    if ssh "${PI_USER}@${PI_HOST}" "command -v docker > /dev/null 2>&1"; then
        log_success "Docker already installed"
        return
    fi
    
    log_info "Installing Docker on Raspberry Pi..."
    
    ssh "${PI_USER}@${PI_HOST}" bash << 'EOF'
        # Update system
        sudo apt update
        sudo apt upgrade -y
        
        # Install Docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        
        # Add pi user to docker group
        sudo usermod -aG docker $USER
        
        # Install Docker Compose
        sudo apt install -y python3-pip
        sudo pip3 install docker-compose
        
        # Clean up
        rm get-docker.sh
        
        echo "Docker installation completed"
EOF
    
    log_success "Docker installed. You may need to logout and back in on the Pi."
}

# Create necessary directories on Pi
setup_pi_directories() {
    log_info "Setting up directories on Pi..."
    
    ssh "${PI_USER}@${PI_HOST}" bash << EOF
        # Create application directories
        sudo mkdir -p /var/lib/${PROJECT_NAME}/data
        sudo mkdir -p /etc/letsencrypt
        sudo mkdir -p /var/log/nginx
        
        # Set proper ownership
        sudo chown -R ${PI_USER}:${PI_USER} /var/lib/${PROJECT_NAME}
        
        # Create project directory
        mkdir -p ~/${PROJECT_NAME}
        
        echo "Directories created successfully"
EOF
    
    log_success "Pi directories configured"
}

# Copy project files to Pi
copy_project_files() {
    log_info "Copying project files to Pi..."
    
    # Create tar archive excluding unnecessary files
    tar --exclude='.git' \
        --exclude='target' \
        --exclude='*.db*' \
        --exclude='node_modules' \
        --exclude='*.log' \
        -czf "${PROJECT_NAME}.tar.gz" .
    
    # Copy to Pi
    scp "${PROJECT_NAME}.tar.gz" "${PI_USER}@${PI_HOST}:~/"
    
    # Extract on Pi
    ssh "${PI_USER}@${PI_HOST}" bash << EOF
        cd ~
        rm -rf ${PROJECT_NAME}
        mkdir ${PROJECT_NAME}
        tar -xzf ${PROJECT_NAME}.tar.gz -C ${PROJECT_NAME}
        rm ${PROJECT_NAME}.tar.gz
        
        echo "Project files extracted"
EOF
    
    # Clean up local tar file
    rm "${PROJECT_NAME}.tar.gz"
    
    log_success "Project files copied to Pi"
}

# Run database migrations on Pi
run_migrations() {
    log_info "Running database migrations..."
    
    ssh "${PI_USER}@${PI_HOST}" bash << EOF
        cd ~/${PROJECT_NAME}
        
        # Install sqlx-cli if not present
        if ! command -v sqlx &> /dev/null; then
            cargo install sqlx-cli --features sqlite
        fi
        
        # Set database URL
        export DATABASE_URL="sqlite:/var/lib/${PROJECT_NAME}/data/portfolio.db"
        
        # Create database and run migrations
        sqlx database create
        sqlx migrate run
        
        echo "Database migrations completed"
EOF
    
    log_success "Database migrations completed"
}

# Build and start services on Pi
start_services() {
    log_info "Building and starting services on Pi..."
    
    ssh "${PI_USER}@${PI_HOST}" bash << EOF
        cd ~/${PROJECT_NAME}
        
        # Build the images
        docker-compose build --no-cache
        
        # Start the services (without SSL first)
        docker-compose up -d website nginx
        
        # Wait for services to be ready
        sleep 30
        
        # Check if services are running
        if docker-compose ps | grep -q "Up"; then
            echo "Services started successfully"
        else
            echo "Error: Services failed to start"
            docker-compose logs
            exit 1
        fi
EOF
    
    log_success "Services are running"
}

# Obtain SSL certificate
setup_ssl() {
    log_info "Setting up SSL certificate for ${DOMAIN}..."
    
    ssh "${PI_USER}@${PI_HOST}" bash << EOF
        cd ~/${PROJECT_NAME}
        
        # Run certbot to get certificate
        docker-compose --profile ssl-init run --rm certbot \
            certonly --webroot --webroot-path=/var/www/certbot \
            --email ${EMAIL} --agree-tos --no-eff-email \
            --force-renewal -d ${DOMAIN}
        
        # Restart nginx to use the new certificate
        docker-compose restart nginx
        
        echo "SSL certificate obtained and nginx restarted"
EOF
    
    log_success "SSL certificate configured"
}

# Set up automatic certificate renewal
setup_cert_renewal() {
    log_info "Setting up automatic certificate renewal..."
    
    ssh "${PI_USER}@${PI_HOST}" bash << 'EOF'
        # Create renewal script
        cat > ~/renew-certs.sh << 'RENEWAL_SCRIPT'
#!/bin/bash
cd ~/personal_website
docker-compose --profile ssl-renew run --rm certbot renew
docker-compose restart nginx
RENEWAL_SCRIPT
        
        chmod +x ~/renew-certs.sh
        
        # Add to crontab (runs twice daily)
        (crontab -l 2>/dev/null; echo "0 12 * * * /home/pi/renew-certs.sh >> /var/log/letsencrypt/renew.log 2>&1") | crontab -
        (crontab -l 2>/dev/null; echo "0 0 * * * /home/pi/renew-certs.sh >> /var/log/letsencrypt/renew.log 2>&1") | crontab -
        
        echo "Certificate renewal scheduled"
EOF
    
    log_success "Automatic certificate renewal configured"
}

# Enable services to start on boot
setup_autostart() {
    log_info "Setting up services to start on boot..."
    
    ssh "${PI_USER}@${PI_HOST}" bash << EOF
        # Create systemd service for docker-compose
        sudo tee /etc/systemd/system/${PROJECT_NAME}.service > /dev/null << 'SERVICE_FILE'
[Unit]
Description=${PROJECT_NAME} Docker Compose Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/${PI_USER}/${PROJECT_NAME}
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SERVICE_FILE
        
        # Enable and start the service
        sudo systemctl daemon-reload
        sudo systemctl enable ${PROJECT_NAME}.service
        
        echo "Autostart configured"
EOF
    
    log_success "Services will start automatically on boot"
}

# Display final instructions
show_final_instructions() {
    log_success "Deployment completed successfully!"
    echo
    log_info "Your website should now be accessible at:"
    log_info "  HTTP:  http://${DOMAIN} (redirects to HTTPS)"
    log_info "  HTTPS: https://${DOMAIN}"
    echo
    log_info "Useful commands on your Pi:"
    log_info "  Check service status: docker-compose ps"
    log_info "  View logs: docker-compose logs -f"
    log_info "  Restart services: docker-compose restart"
    log_info "  Stop services: docker-compose down"
    log_info "  Update and restart: ./deploy-to-pi.sh"
    echo
    log_warning "Don't forget to:"
    log_warning "1. Configure port forwarding (80, 443) on your router"
    log_warning "2. Point your domain to your public IP address"
    log_warning "3. Test your website from outside your network"
}

# Main deployment process
main() {
    log_info "Starting deployment to Raspberry Pi 5"
    log_info "Target: ${PI_USER}@${PI_HOST}"
    log_info "Domain: ${DOMAIN}"
    echo
    
    check_project_directory
    test_ssh_connection
    update_configuration
    install_docker_on_pi
    setup_pi_directories
    copy_project_files
    run_migrations
    start_services
    setup_ssl
    setup_cert_renewal
    setup_autostart
    show_final_instructions
}

# Parse command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "update")
        log_info "Updating existing deployment..."
        check_project_directory
        test_ssh_connection
        copy_project_files
        run_migrations
        ssh "${PI_USER}@${PI_HOST}" "cd ${PROJECT_NAME} && docker-compose up -d --build"
        log_success "Update completed"
        ;;
    "logs")
        ssh "${PI_USER}@${PI_HOST}" "cd ${PROJECT_NAME} && docker-compose logs -f"
        ;;
    "status")
        ssh "${PI_USER}@${PI_HOST}" "cd ${PROJECT_NAME} && docker-compose ps"
        ;;
    "stop")
        ssh "${PI_USER}@${PI_HOST}" "cd ${PROJECT_NAME} && docker-compose down"
        log_success "Services stopped"
        ;;
    "start")
        ssh "${PI_USER}@${PI_HOST}" "cd ${PROJECT_NAME} && docker-compose up -d"
        log_success "Services started"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  deploy  - Full deployment (default)"
        echo "  update  - Update existing deployment"
        echo "  logs    - Show service logs"
        echo "  status  - Show service status"
        echo "  start   - Start services"
        echo "  stop    - Stop services"
        echo "  help    - Show this help"
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Use '$0 help' for available commands"
        exit 1
        ;;
esac