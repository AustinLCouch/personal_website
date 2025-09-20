#!/bin/bash

# DuckDNS Dynamic DNS Updater
# This script updates your DuckDNS domain with your current public IP
# Copy this to your Raspberry Pi and set up as a cron job

# Configuration - EDIT THESE VALUES
DOMAIN="your-subdomain"        # Your DuckDNS subdomain (without .duckdns.org)
TOKEN="your-token-here"        # Your DuckDNS token from account page
LOG_FILE="$HOME/duckdns/duck.log"

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Colors for output (optional, works in terminal)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging function
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Also print to stdout if running interactively
    if [[ -t 1 ]]; then
        case $level in
            "ERROR")
                echo -e "${RED}[$level]${NC} $message"
                ;;
            "SUCCESS")
                echo -e "${GREEN}[$level]${NC} $message"
                ;;
            "WARNING")
                echo -e "${YELLOW}[$level]${NC} $message"
                ;;
            *)
                echo "[$level] $message"
                ;;
        esac
    fi
}

# Check if configuration is set
check_configuration() {
    if [[ "$DOMAIN" == "your-subdomain" ]] || [[ "$TOKEN" == "your-token-here" ]]; then
        log_message "ERROR" "Configuration not set. Please edit this script with your DuckDNS domain and token."
        exit 1
    fi
}

# Get current public IP
get_public_ip() {
    local ip
    
    # Try multiple services in case one is down
    local services=(
        "http://checkip.amazonaws.com/"
        "http://ipv4.icanhazip.com/"
        "http://ifconfig.me/ip"
        "http://api.ipify.org/"
    )
    
    for service in "${services[@]}"; do
        ip=$(curl -s --max-time 10 "$service" | tr -d '\n')
        
        # Validate IP format
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    return 1
}

# Get last known IP from log
get_last_ip() {
    if [[ -f "$LOG_FILE" ]]; then
        grep "IP updated successfully" "$LOG_FILE" | tail -1 | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
    fi
}

# Update DuckDNS record
update_duckdns() {
    local ip=$1
    local url="https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip=${ip}"
    
    local response=$(curl -s --max-time 30 "$url")
    
    if [[ "$response" == "OK" ]]; then
        log_message "SUCCESS" "IP updated successfully to $ip for ${DOMAIN}.duckdns.org"
        return 0
    else
        log_message "ERROR" "Failed to update DuckDNS. Response: $response"
        return 1
    fi
}

# Main function
main() {
    log_message "INFO" "Starting DuckDNS update check"
    
    check_configuration
    
    # Get current public IP
    local current_ip
    current_ip=$(get_public_ip)
    
    if [[ -z "$current_ip" ]]; then
        log_message "ERROR" "Could not determine public IP address"
        exit 1
    fi
    
    log_message "INFO" "Current public IP: $current_ip"
    
    # Get last known IP
    local last_ip
    last_ip=$(get_last_ip)
    
    if [[ "$current_ip" == "$last_ip" ]]; then
        log_message "INFO" "IP address unchanged ($current_ip). No update needed."
        exit 0
    fi
    
    log_message "INFO" "IP address changed from '$last_ip' to '$current_ip'. Updating DuckDNS..."
    
    # Update DuckDNS
    if update_duckdns "$current_ip"; then
        log_message "SUCCESS" "DuckDNS update completed successfully"
        
        # Optional: Test if the DNS update worked
        sleep 5
        local resolved_ip=$(nslookup "${DOMAIN}.duckdns.org" | grep -A1 "Name:" | tail -1 | awk '{print $2}')
        if [[ "$resolved_ip" == "$current_ip" ]]; then
            log_message "SUCCESS" "DNS resolution confirmed: ${DOMAIN}.duckdns.org -> $resolved_ip"
        else
            log_message "WARNING" "DNS update may still be propagating. Resolved IP: $resolved_ip, Expected: $current_ip"
        fi
    else
        log_message "ERROR" "DuckDNS update failed"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-update}" in
    "update")
        main
        ;;
    "test")
        check_configuration
        echo "Configuration test passed"
        echo "Domain: ${DOMAIN}.duckdns.org"
        echo "Token: ${TOKEN:0:8}***${TOKEN: -4}"
        
        current_ip=$(get_public_ip)
        if [[ -n "$current_ip" ]]; then
            echo "Current public IP: $current_ip"
        else
            echo "ERROR: Could not determine public IP"
            exit 1
        fi
        ;;
    "status")
        if [[ -f "$LOG_FILE" ]]; then
            echo "Last 10 log entries:"
            tail -10 "$LOG_FILE"
            echo
            echo "Last successful update:"
            grep "IP updated successfully" "$LOG_FILE" | tail -1
        else
            echo "No log file found at $LOG_FILE"
        fi
        ;;
    "setup")
        echo "Setting up DuckDNS updater..."
        echo
        echo "1. Edit this script with your domain and token:"
        echo "   nano $0"
        echo
        echo "2. Test the configuration:"
        echo "   $0 test"
        echo
        echo "3. Add to crontab for automatic updates:"
        echo "   crontab -e"
        echo "   Add line: */5 * * * * $PWD/$(basename $0) update"
        echo
        echo "4. Check status anytime:"
        echo "   $0 status"
        ;;
    "help"|"-h"|"--help")
        echo "DuckDNS Dynamic DNS Updater"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  update  - Update DuckDNS with current IP (default)"
        echo "  test    - Test configuration and show current IP"
        echo "  status  - Show recent log entries"
        echo "  setup   - Show setup instructions"
        echo "  help    - Show this help"
        echo
        echo "Configuration:"
        echo "  Edit DOMAIN and TOKEN variables at the top of this script"
        echo
        echo "Automatic Updates:"
        echo "  Add to crontab: */5 * * * * /path/to/this/script update"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for available commands"
        exit 1
        ;;
esac