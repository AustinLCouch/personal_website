#!/bin/bash

# backup.sh - Simple backup script for database and certificates
# This script creates local backups with retention policy

set -euo pipefail

# Configuration
BACKUP_DIR="/var/backups/personal_website"
DB_PATH="/var/lib/personal_website/data/portfolio.db"
CERTS_PATH="/etc/letsencrypt"
RETENTION_DAYS=30

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory
create_backup_dir() {
    if ! sudo mkdir -p "$BACKUP_DIR"; then
        log_error "Failed to create backup directory: $BACKUP_DIR"
        exit 1
    fi
    log_info "Backup directory ready: $BACKUP_DIR"
}

# Backup database
backup_database() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/portfolio_${timestamp}.db"
    
    if [[ -f "$DB_PATH" ]]; then
        log_info "Backing up database..."
        if sudo sqlite3 "$DB_PATH" ".backup $backup_file"; then
            sudo chown syzygy:syzygy "$backup_file"
            log_info "Database backed up to: $backup_file"
        else
            log_error "Database backup failed"
            return 1
        fi
    else
        log_warning "Database file not found: $DB_PATH"
    fi
}

# Backup certificates (if they exist)
backup_certificates() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/letsencrypt_${timestamp}.tar.gz"
    
    if [[ -d "$CERTS_PATH" ]]; then
        log_info "Backing up SSL certificates..."
        if sudo tar -czf "$backup_file" -C "$(dirname "$CERTS_PATH")" "$(basename "$CERTS_PATH")"; then
            sudo chown syzygy:syzygy "$backup_file"
            log_info "Certificates backed up to: $backup_file"
        else
            log_error "Certificate backup failed"
            return 1
        fi
    else
        log_warning "Certificates directory not found: $CERTS_PATH"
    fi
}

# Clean old backups
cleanup_old_backups() {
    log_info "Cleaning up backups older than ${RETENTION_DAYS} days..."
    
    # Clean database backups
    if command -v find >/dev/null; then
        local deleted_count=0
        while IFS= read -r -d '' file; do
            sudo rm "$file" && ((deleted_count++))
        done < <(sudo find "$BACKUP_DIR" -name "portfolio_*.db" -mtime +${RETENTION_DAYS} -print0 2>/dev/null || true)
        
        while IFS= read -r -d '' file; do
            sudo rm "$file" && ((deleted_count++))
        done < <(sudo find "$BACKUP_DIR" -name "letsencrypt_*.tar.gz" -mtime +${RETENTION_DAYS} -print0 2>/dev/null || true)
        
        if [[ $deleted_count -gt 0 ]]; then
            log_info "Removed $deleted_count old backup files"
        fi
    fi
}

# Show backup status
show_backup_status() {
    log_info "Current backups in $BACKUP_DIR:"
    if sudo ls -la "$BACKUP_DIR" 2>/dev/null; then
        local count=$(sudo ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l || echo "0")
        log_info "Total backup files: $count"
        
        # Show disk usage
        if command -v du >/dev/null; then
            local size=$(sudo du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1 || echo "unknown")
            log_info "Total backup size: $size"
        fi
    else
        log_warning "No backups found"
    fi
}

# Main backup function
main() {
    log_info "Starting backup process..."
    
    create_backup_dir
    backup_database
    backup_certificates
    cleanup_old_backups
    show_backup_status
    
    log_info "Backup process completed successfully!"
}

# Parse command line arguments
case "${1:-backup}" in
    "backup")
        main
        ;;
    "status")
        show_backup_status
        ;;
    "cleanup")
        log_info "Manual cleanup requested"
        create_backup_dir
        cleanup_old_backups
        ;;
    "help"|"-h"|"--help")
        echo "Personal Website Backup Script"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  backup  - Create backups (default)"
        echo "  status  - Show backup status"
        echo "  cleanup - Clean up old backups"
        echo "  help    - Show this help"
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Use '$0 help' for available commands"
        exit 1
        ;;
esac