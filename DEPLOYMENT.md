# Raspberry Pi 5 Deployment Guide

This guide will help you deploy your personal website to a Raspberry Pi 5 with HTTPS, automatic SSL renewal, and dynamic DNS support for when your Pi moves between locations.

## 🎯 Overview

Your deployment will include:
- **Dockerized Rust application** running on ARM64
- **Nginx reverse proxy** with SSL termination
- **Let's Encrypt certificates** with automatic renewal
- **Dynamic DNS** to handle changing IP addresses
- **Production security** hardening and monitoring
- **Auto-restart** services on boot and failure

## 📋 Prerequisites

### Your Local Machine (macOS)
- [x] Git and this project cloned
- [x] SSH access to your Raspberry Pi
- [ ] Domain name (see Domain Options below)

### Raspberry Pi 5
- [x] Raspberry Pi OS 64-bit installed
- [x] Connected to internet
- [x] SSH enabled (`sudo systemctl enable ssh`)
- [ ] Static IP assignment (recommended)
- [ ] SSH key authentication (recommended)

## 🌐 Domain Options

You need a domain name for HTTPS certificates. Choose one:

### Option 1: Free Dynamic DNS (Recommended)
- **DuckDNS** (free): `yourname.duckdns.org`
- **No-IP** (free tier): `yourname.ddns.net`
- **Cloudflare** (if you own a domain): Subdomain with dynamic updates

### Option 2: Purchase a Domain
- Namecheap, Google Domains, etc.
- Point A record to your public IP
- More professional but requires purchase

## 🚀 Quick Start (30-Minute Setup)

### Step 1: Configure Your Details

Edit the deployment script with your information:

```bash
nano deploy-to-pi.sh
```

Update these variables at the top of the file:
```bash
PI_HOST="raspberrypi.local"        # Your Pi's hostname or IP
PI_USER="pi"                       # SSH user on the Pi
DOMAIN="yourname.duckdns.org"      # Your domain name
EMAIL="your-email@example.com"     # Email for Let's Encrypt
```

### Step 2: Set Up SSH Key (Recommended)

If you haven't already, set up SSH key authentication:

```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your-email@example.com"

# Copy key to Pi
ssh-copy-id pi@raspberrypi.local
```

### Step 3: Deploy to Pi

Run the deployment script:

```bash
./deploy-to-pi.sh
```

This will:
1. ✅ Install Docker on your Pi
2. ✅ Build your Rust application 
3. ✅ Set up Nginx reverse proxy
4. ✅ Obtain SSL certificates
5. ✅ Configure automatic renewal
6. ✅ Set up services to start on boot

### Step 4: Configure Router Port Forwarding

Forward these ports from your router to your Pi's local IP:
- **Port 80** (HTTP) → Pi's IP:80
- **Port 443** (HTTPS) → Pi's IP:443

### Step 5: Set Up Dynamic DNS

Since your Pi will move locations, set up dynamic DNS:

#### For DuckDNS:
1. Register at [duckdns.org](https://www.duckdns.org)
2. Create your subdomain (e.g., `mysite.duckdns.org`)
3. Install the updater on your Pi:

```bash
# SSH to your Pi
ssh pi@raspberrypi.local

# Install DuckDNS updater
mkdir ~/duckdns
cd ~/duckdns
nano duck.sh
```

Add this content (replace YOUR_TOKEN and YOUR_DOMAIN):
```bash
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=YOUR_DOMAIN&token=YOUR_TOKEN&ip=" | curl -k -o ~/duckdns/duck.log -K -
```

Make it executable and schedule:
```bash
chmod 700 duck.sh
crontab -e
```

Add this line to run every 5 minutes:
```
*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1
```

## 📊 Management Commands

After deployment, you can manage your website with:

```bash
# Check status
./deploy-to-pi.sh status

# View logs
./deploy-to-pi.sh logs

# Update deployment (after code changes)
./deploy-to-pi.sh update

# Stop services
./deploy-to-pi.sh stop

# Start services
./deploy-to-pi.sh start
```

## 🔧 Troubleshooting

### Can't Connect to Pi
```bash
# Test connection
ping raspberrypi.local

# Try IP address instead
nmap -sn 192.168.1.0/24  # Find Pi's IP
```

### Docker Build Fails
```bash
# Check Pi architecture
ssh pi@raspberrypi.local "uname -m"  # Should show aarch64

# Check disk space
ssh pi@raspberrypi.local "df -h"
```

### SSL Certificate Issues
```bash
# Check certificate status
./deploy-to-pi.sh logs | grep certbot

# Manually renew
ssh pi@raspberrypi.local "cd personal_website && docker-compose --profile ssl-renew run --rm certbot renew"
```

### Website Not Accessible
1. Check services are running: `./deploy-to-pi.sh status`
2. Verify port forwarding in router
3. Check domain DNS resolution: `nslookup your-domain.com`
4. Test from different network

## 🔒 Security Features

Your deployment includes:

### Network Security
- **Firewall** rules (only SSH, HTTP, HTTPS open)
- **Fail2ban** protection against brute force
- **Rate limiting** in Nginx
- **DDoS protection** with connection limits

### SSL/TLS Security
- **TLS 1.2/1.3** only (A+ SSL Labs rating)
- **HSTS** headers for browser security
- **OCSP stapling** for certificate verification
- **Auto-renewal** every 60 days

### Application Security
- **Non-root containers** with minimal permissions
- **Security headers** (CSP, X-Frame-Options, etc.)
- **Input validation** and sanitization
- **Read-only file systems** where possible

## 📈 Monitoring

### Health Checks
Your deployment includes automatic health monitoring:
- **Container health checks** every 30 seconds
- **Service restart** on failure
- **Log rotation** to prevent disk filling

### Manual Monitoring
```bash
# Check system resources
ssh pi@raspberrypi.local "htop"

# Check disk usage
ssh pi@raspberrypi.local "df -h"

# Check service logs
./deploy-to-pi.sh logs

# Check SSL certificate expiry
ssh pi@raspberrypi.local "cd personal_website && docker-compose exec nginx openssl x509 -in /etc/letsencrypt/live/your-domain.com/cert.pem -noout -dates"
```

## 🔄 Moving Your Pi

When you move your Pi to a new location:

1. **Connect to new network**
2. **Update router port forwarding** (if needed)
3. **Wait for dynamic DNS** to update (5-10 minutes)
4. **Test connectivity**: `ping your-domain.com`

Your website will automatically come back online once the DNS updates!

## 🔐 Backup Strategy

### Database Backups
Create automated backups of your SQLite database:

```bash
# Create backup script on Pi
ssh pi@raspberrypi.local

cat > ~/backup-db.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
DB_PATH="/var/lib/personal_website/data/portfolio.db"
BACKUP_DIR="~/backups"
mkdir -p $BACKUP_DIR
sqlite3 $DB_PATH ".backup $BACKUP_DIR/portfolio_$DATE.db"
# Keep only last 30 days
find $BACKUP_DIR -name "portfolio_*.db" -mtime +30 -delete
EOF

chmod +x ~/backup-db.sh

# Schedule daily backups
crontab -e
# Add: 0 2 * * * ~/backup-db.sh
```

### Full System Backup
Consider backing up your entire Pi SD card periodically using disk imaging tools.

## 🎉 Success!

If everything is working:

- ✅ Visit `https://your-domain.com` and see your website
- ✅ HTTP automatically redirects to HTTPS
- ✅ SSL certificate shows as valid and trusted
- ✅ Website works from different networks
- ✅ Services restart after Pi reboot
- ✅ Dynamic DNS updates when IP changes

## 📞 Support

If you encounter issues:

1. **Check logs**: `./deploy-to-pi.sh logs`
2. **Verify services**: `./deploy-to-pi.sh status`  
3. **Test connectivity**: `ping your-domain.com`
4. **Check router settings**: Port forwarding for 80, 443
5. **Verify DNS**: `nslookup your-domain.com`

Remember: Your Pi needs to be on and connected to internet for your website to be accessible!

---

**🏠 Home Server, 🔒 Secure by Default, 📱 Mobile-Ready**