# Router Port Forwarding Guide

To make your Raspberry Pi website accessible from the internet, you need to configure port forwarding on your router.

## 🎯 Required Ports

Forward these ports from your router to your Pi's local IP address:

- **Port 80** (HTTP) → Pi's Local IP:80
- **Port 443** (HTTPS) → Pi's Local IP:443

## 📋 Step-by-Step Instructions

### Step 1: Find Your Pi's Local IP Address

On your Pi, run:
```bash
ip addr show | grep 192.168
```

You should see something like: `192.168.1.100` (your Pi's IP may be different)

### Step 2: Access Your Router's Admin Panel

1. **Find your router's IP**: Usually `192.168.1.1` or `192.168.0.1`
2. **Open in browser**: Go to `http://192.168.1.1`
3. **Login**: Use admin credentials (often on router label)

### Step 3: Configure Port Forwarding

Look for these menu sections (varies by router brand):
- **"Port Forwarding"**
- **"Virtual Servers"**
- **"Applications & Gaming"**
- **"Advanced" → "Port Forwarding"**
- **"Firewall" → "Port Forwarding"**

### Step 4: Add Port Forwarding Rules

Create **two rules**:

#### Rule 1: HTTP (Port 80)
- **Service Name**: `Personal_Website_HTTP`
- **External Port**: `80`
- **Internal Port**: `80`
- **Internal IP**: `192.168.1.XXX` (your Pi's IP)
- **Protocol**: `TCP`
- **Enable**: ✅

#### Rule 2: HTTPS (Port 443)
- **Service Name**: `Personal_Website_HTTPS`
- **External Port**: `443`
- **Internal Port**: `443`
- **Internal IP**: `192.168.1.XXX` (your Pi's IP)
- **Protocol**: `TCP`
- **Enable**: ✅

## 📱 Router-Specific Instructions

### Popular Router Brands

#### **Netgear**
1. Advanced → Dynamic DNS / Port Forwarding
2. Click "Add" for each rule
3. Apply settings

#### **Linksys**
1. Smart Wi-Fi Tools → Port Forwarding
2. Add new port forwarding rules
3. Save settings

#### **TP-Link**
1. Advanced → NAT Forwarding → Port Forwarding
2. Add rules for ports 80 and 443
3. Save configuration

#### **ASUS**
1. Adaptive QoS → Traditional QoS → Port Forwarding
2. Enable port forwarding and add rules
3. Apply settings

#### **D-Link**
1. Advanced → Port Forwarding
2. Add HTTP and HTTPS rules
3. Save settings

## 🔍 Testing Port Forwarding

### Test from Inside Your Network
```bash
# Test from your Mac to the Pi
curl -v http://192.168.1.XXX  # Replace with Pi's IP
```

### Test from Outside Your Network
Use a mobile hotspot or ask someone else to test:
```bash
# Replace with your public IP
curl -v http://YOUR.PUBLIC.IP.ADDRESS
```

### Find Your Public IP
Visit: https://whatismyipaddress.com/

## 🚨 Security Considerations

### Firewall Rules
Your Pi's firewall (UFW) is already configured to only allow:
- SSH (Port 22)
- HTTP (Port 80) 
- HTTPS (Port 443)

### Dynamic IP Issues
If your ISP changes your public IP frequently:
1. Set up Dynamic DNS (DuckDNS recommended)
2. Use our provided `duckdns-updater.sh` script
3. Point your domain to the dynamic DNS name

## 🔧 Troubleshooting

### Port Forwarding Not Working?

1. **Check Pi's local IP hasn't changed**:
   ```bash
   ip addr show | grep 192.168
   ```

2. **Verify router rules are saved and enabled**

3. **Test internal connectivity first**:
   ```bash
   # From your Mac, test Pi directly
   curl http://192.168.1.XXX
   ```

4. **Check router firewall settings**:
   - Disable "SPI Firewall" temporarily
   - Look for "Port Filtering" - ensure it's not blocking

5. **Restart router and Pi**:
   ```bash
   # On Pi
   sudo reboot
   ```

### Common Router Interface Terms
- **Port Forwarding** = **Virtual Servers** = **Port Mapping**
- **Internal IP** = **Server IP** = **Local IP**
- **External Port** = **Public Port** = **WAN Port**

## 📝 Alternative Solutions

### If Port Forwarding Doesn't Work

1. **Use UPnP** (if available):
   - Enable UPnP in router settings
   - Less secure but easier setup

2. **DMZ** (not recommended):
   - Places Pi directly on internet
   - Security risk - only use temporarily for testing

3. **VPN Solution**:
   - Use Tailscale, WireGuard, or similar
   - More secure but requires VPN client

## ✅ Verification Checklist

- [ ] Found Pi's local IP address
- [ ] Accessed router admin panel
- [ ] Created port forwarding rule for port 80
- [ ] Created port forwarding rule for port 443
- [ ] Saved/applied router settings
- [ ] Tested from inside network
- [ ] Tested from outside network (mobile hotspot)
- [ ] Set up dynamic DNS (if needed)

## 🆘 Need Help?

If you're stuck:
1. Check router manual for port forwarding instructions
2. Search "[Router Model] port forwarding setup"
3. Contact your ISP - some block residential port 80/443
4. Consider using non-standard ports (8080, 8443) as alternative

---

**Remember**: Your website will only be accessible when your Pi is powered on and connected to the internet!