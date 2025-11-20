# AbeOS Security Module - Content Filtering

Comprehensive content filtering and parental controls to block harmful websites.

## 🎯 Goal

Block:
- ✅ Pornography and adult content
- ✅ Gambling websites
- ✅ NSFW content
- ✅ Malicious and phishing sites
- ✅ Malware distribution sites
- ✅ Known harmful websites

## 📜 Scripts

### 1. Set-SafeDNS.ps1
Configure family-safe DNS servers on all network adapters.

**Usage:**
```powershell
# Auto-select fastest DNS provider
.\Set-SafeDNS.ps1 -Provider Auto

# Use specific provider
.\Set-SafeDNS.ps1 -Provider Cloudflare
.\Set-SafeDNS.ps1 -Provider OpenDNS
.\Set-SafeDNS.ps1 -Provider CleanBrowsing

# Include IPv6
.\Set-SafeDNS.ps1 -Provider Cloudflare -SetIPv6

# Test without applying
.\Set-SafeDNS.ps1 -WhatIf
```

**DNS Providers:**
- **Cloudflare Family** (1.1.1.3) - Blocks malware + adult content
- **OpenDNS FamilyShield** (208.67.222.123) - Comprehensive filtering
- **CleanBrowsing Family** (185.228.168.168) - Family-focused filtering
- **Quad9** (9.9.9.9) - Malware blocking
- **AdGuard DNS Family** (94.140.14.15) - Ad + adult blocking

### 2. Install-AdGuardHome.ps1
Install AdGuard Home for advanced local DNS filtering.

**Usage:**
```powershell
# Standard installation
.\Install-AdGuardHome.ps1

# Custom install path
.\Install-AdGuardHome.ps1 -InstallPath "D:\AdGuardHome"

# Custom ports
.\Install-AdGuardHome.ps1 -WebPort 8080 -DNSPort 5353

# Skip Windows Service installation
.\Install-AdGuardHome.ps1 -SkipServiceInstall
```

**Features:**
- 🔒 Runs locally (127.0.0.1)
- 📊 Web dashboard at http://localhost:3000
- 📋 Pre-configured with 5 comprehensive blocklists
- 🛡️ Parental controls enabled by default
- 🔍 SafeSearch enforced
- ⚡ Fast, efficient filtering

**After Installation:**
1. Open http://localhost:3000
2. Complete setup wizard
3. Set admin password
4. Run: `Set-SafeDNS.ps1` to point system to 127.0.0.1

### 3. Test-ContentFilter.ps1
Test if content filtering is working properly.

**Usage:**
```powershell
# Basic test
.\Test-ContentFilter.ps1

# Detailed output
.\Test-ContentFilter.ps1 -Detailed
```

**Tests:**
- Current DNS configuration
- Malware domain blocking
- Adult content filtering (safe test domains)
- Protection score (0-100%)
- AdGuard Home status
- SafeSearch status
- Windows SmartScreen status

## 🚀 Quick Setup

### Recommended: Multi-Layer Protection

**Step 1: DNS-Level (Primary Protection)**
```powershell
# Run as Administrator
cd C:\AbeOS\modules\security
.\Set-SafeDNS.ps1 -Provider Auto
```

**Step 2: Local Filtering (Advanced Protection)**
```powershell
# Run as Administrator
.\Install-AdGuardHome.ps1
# Complete web setup at http://localhost:3000
# Then point DNS to AdGuard Home:
.\Set-SafeDNS.ps1  # (Will detect AdGuard Home running)
```

**Step 3: Verify**
```powershell
.\Test-ContentFilter.ps1
```

## 📊 Protection Layers

### Layer 1: DNS-Level (Set-SafeDNS.ps1)
**Pros:**
- ✅ System-wide protection
- ✅ Works for all apps and browsers
- ✅ No software installation needed
- ✅ Fast and lightweight

**Cons:**
- ⚠️ Can be bypassed with VPN or custom DNS
- ⚠️ Less granular control

### Layer 2: Local DNS (AdGuard Home)
**Pros:**
- ✅ Advanced filtering with custom rules
- ✅ Detailed logging and statistics
- ✅ Granular control per device/client
- ✅ Custom blocklists
- ✅ Web dashboard for management

**Cons:**
- ⚠️ Requires installation
- ⚠️ Uses some system resources

### Layer 3: Browser Extensions (Manual)
**Recommended:**
- uBlock Origin (with adult content filters)
- WebFilter Pro
- Enforced SafeSearch

### Layer 4: Router-Level (Manual)
Configure your ASUS ROG router:
1. Log into router admin
2. Set DNS servers (same as Layer 1)
3. Enable parental controls
4. Provides network-wide backup protection

## 🔧 Advanced Configuration

### Custom Blocklists for AdGuard Home

Add these lists via the web UI (http://localhost:3000):

```
# Comprehensive
https://big.oisd.nl/

# Gambling
https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/gambling.txt

# Adult Content
https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts

# Malware
https://urlhaus.abuse.ch/downloads/hostfile/

# Energized Ultimate
https://block.energized.pro/ultimate/formats/hosts.txt

# Phishing
https://phishing.army/download/phishing_army_blocklist_extended.txt
```

### Whitelist Safe Sites

If a safe site is blocked, add to whitelist:
```powershell
# Via AdGuard Home web UI: Filters > Custom filtering rules
# Add:
@@||example.com^
```

### Lock DNS Settings (Prevent Changes)

```powershell
# Disable DNS adapter settings in network connections
# This prevents manual DNS changes
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "DisableDynamicUpdate" -Value 1
```

## 📈 Monitoring

### View Blocked Requests
```powershell
# AdGuard Home Dashboard
Start-Process "http://localhost:3000"

# Shows:
# - Total queries
# - Blocked by filters
# - Top blocked domains
# - Query log
# - Statistics
```

### Check Service Status
```powershell
Get-Service AdGuardHome
```

### View Logs
```powershell
# AdGuard Home logs
Get-Content "C:\Program Files\AdGuardHome\AdGuardHome.log" -Tail 50
```

## 🛠️ Troubleshooting

### DNS Not Working
```powershell
# Reset DNS cache
Clear-DnsClientCache

# Reset to auto DNS
Get-NetAdapter | Set-DnsClientServerAddress -ResetServerAddresses

# Reapply safe DNS
.\Set-SafeDNS.ps1 -Provider Cloudflare
```

### AdGuard Home Not Starting
```powershell
# Check service
Get-Service AdGuardHome

# Restart service
Restart-Service AdGuardHome

# Check if port 53 is in use
Get-NetTCPConnection -LocalPort 53
Get-NetUDPEndpoint -LocalPort 53

# If Windows DNS Client is using port 53:
Stop-Service "Dnscache"
Set-Service "Dnscache" -StartupType Disabled
```

### Legitimate Site Blocked
1. Open AdGuard Home: http://localhost:3000
2. Go to: Filters → Custom filtering rules
3. Add whitelist: `@@||domain.com^`
4. Save

### Test Specific Domain
```powershell
Resolve-DnsName -Name "example.com" -Server 127.0.0.1
```

## 🔐 Security Best Practices

1. **Use multiple layers** (DNS + Local filtering)
2. **Enable SafeSearch** in browsers
3. **Keep blocklists updated** (AdGuard does this automatically)
4. **Monitor logs regularly** for bypass attempts
5. **Configure router DNS** as backup
6. **Use HTTPS DNS** (DNS-over-HTTPS) if possible
7. **Enable Windows Defender SmartScreen**

## 🔄 Maintenance

### Update AdGuard Home
```powershell
# Check for updates in web UI
# Or reinstall:
.\Install-AdGuardHome.ps1
```

### Update Blocklists
```powershell
# Automatic (default every 24 hours)
# Or manual via web UI: Filters → Update filters
```

### Weekly Check
```powershell
.\Test-ContentFilter.ps1
```

## ⚙️ Uninstall

### Remove AdGuard Home
```powershell
Stop-Service AdGuardHome
& "C:\Program Files\AdGuardHome\AdGuardHome.exe" -s uninstall
Remove-Item "C:\Program Files\AdGuardHome" -Recurse -Force
```

### Reset DNS
```powershell
Get-NetAdapter | Set-DnsClientServerAddress -ResetServerAddresses
```

## 📚 Resources

- [Cloudflare for Families](https://1.1.1.1/family/)
- [OpenDNS FamilyShield](https://www.opendns.com/setupguide/#familyshield)
- [AdGuard Home Documentation](https://github.com/AdguardTeam/AdGuardHome/wiki)
- [Steven Black's Hosts](https://github.com/StevenBlack/hosts)

---

**Status:** ✅ Production Ready
**Version:** 1.0.0
**Last Updated:** 2025-01-15
