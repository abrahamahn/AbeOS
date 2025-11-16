# AbeOS Utilities - Package Download Automation

This directory contains utilities for automating package downloads, checking availability, and managing installation files.

## Overview

The download automation system helps you:
- ✅ Check package availability across multiple sources (winget, choco, GitHub, direct URLs)
- ✅ Automatically download installers where possible
- ✅ Identify missing installers for drivers and audio plugins
- ✅ Generate reports on what needs manual download
- ✅ Batch download with retry logic and progress tracking

---

## Scripts

### 1. Check-AvailablePackages.ps1

**Purpose:** Check if packages are available for download across multiple sources

**Features:**
- Checks winget, Chocolatey, Scoop, GitHub releases
- Tests direct download URLs
- Caches results for faster subsequent checks
- Auto-downloads when possible

**Usage:**

```powershell
# Check availability only
.\Check-AvailablePackages.ps1 -CheckOnly

# Check and download all available packages
.\Check-AvailablePackages.ps1 -Download

# Update URLs in configuration
.\Check-AvailablePackages.ps1 -UpdateUrls
```

**Configuration:** `configs/installers/auto-download.json`

### 2. Scan-MissingInstallers.ps1

**Purpose:** Scan your existing config files for missing installation files

**Features:**
- Checks drivers.json for missing .exe/.msi files
- Scans audio-plugins.json for uninstalled plugins
- Generates detailed markdown reports
- Suggests download sources

**Usage:**

```powershell
# Scan all categories
.\Scan-MissingInstallers.ps1

# Scan only drivers
.\Scan-MissingInstallers.ps1 -Category Drivers

# Generate detailed report
.\Scan-MissingInstallers.ps1 -GenerateReport

# Scan audio plugins only
.\Scan-MissingInstallers.ps1 -Category AudioPlugins
```

**Outputs:**
- Console summary
- Markdown report in `docs/reports/`

### 3. Start-BatchDownload.ps1

**Purpose:** Batch download manager with queue system

**Features:**
- Queue-based downloads
- Retry logic with exponential backoff
- Progress tracking and resume capability
- Interactive mode for selective downloads
- Concurrent download support

**Usage:**

```powershell
# Download all items in queue
.\Start-BatchDownload.ps1

# Interactive mode - select what to download
.\Start-BatchDownload.ps1 -Interactive

# Resume failed downloads
.\Start-BatchDownload.ps1 -Resume

# Custom output directory
.\Start-BatchDownload.ps1 -OutputDirectory "D:\Downloads"

# Adjust retry settings
.\Start-BatchDownload.ps1 -MaxRetries 5 -MaxConcurrent 5
```

**Configuration:** `configs/cache/download-queue.json`

---

## Workflow Examples

### Example 1: Set Up Dev Environment Downloads

```powershell
# 1. Check what's available
cd C:\AbeOS\scripts\utilities
.\Check-AvailablePackages.ps1 -CheckOnly

# 2. Review the results
code C:\AbeOS\configs\cache\package-availability.json

# 3. Download available packages
.\Check-AvailablePackages.ps1 -Download

# 4. Downloads saved to:
explorer C:\AbeOS\downloads\installers
```

### Example 2: Find Missing Drivers

```powershell
# 1. Scan for missing driver files
.\Scan-MissingInstallers.ps1 -Category Drivers

# 2. Generate detailed report
.\Scan-MissingInstallers.ps1 -Category Drivers -GenerateReport

# 3. Review report
code C:\AbeOS\docs\reports\missing-installers-*.md

# 4. Download missing drivers manually from suggested URLs
```

### Example 3: Batch Download Audio Software

```powershell
# 1. Edit download queue
code C:\AbeOS\configs\cache\download-queue.json

# 2. Add your downloads (example):
{
  "downloads": [
    {
      "name": "Reaper DAW",
      "url": "https://www.reaper.fm/files/6.x/reaper682_x64-install.exe",
      "category": "audio",
      "priority": 1
    },
    {
      "name": "VLC Media Player",
      "url": "https://get.videolan.org/vlc/last/win64/vlc-3.0.20-win64.exe",
      "category": "media",
      "priority": 2
    }
  ]
}

# 3. Start batch download
.\Start-BatchDownload.ps1

# 4. If some fail, retry
.\Start-BatchDownload.ps1 -Resume
```

### Example 4: Interactive Download Selection

```powershell
# Run in interactive mode
.\Start-BatchDownload.ps1 -Interactive

# Terminal will show:
# Available downloads:
#   [1] Visual Studio Code - development
#   [2] Git for Windows - development
#   [3] 7-Zip - utility
#   [4] OBS Studio - streaming
#
# Enter numbers to download (comma-separated, or 'all'): 1,2,4

# Only selected items will download
```

---

## Configuration Files

### auto-download.json

Location: `configs/installers/auto-download.json`

Structure:
```json
{
  "packages": {
    "Package Name": {
      "description": "Description",
      "category": "development|audio|utility|driver",
      "winget": "Winget.PackageId",
      "choco": "choco-package-name",
      "github": "owner/repo",
      "assetPattern": "regex-pattern",
      "url": "https://direct-download-url.com/file.exe",
      "manual": false,
      "priority": "high|medium|low|critical",
      "notes": "Additional information"
    }
  }
}
```

### download-queue.json

Location: `configs/cache/download-queue.json`

Structure:
```json
{
  "downloads": [
    {
      "name": "Software Name",
      "url": "https://download-url.com/file.exe",
      "filename": "custom-filename.exe",
      "size": 52428800,
      "category": "development",
      "priority": 1
    }
  ]
}
```

**Priority levels:**
- 1 = Critical (download first)
- 2 = High
- 3 = Medium
- 4 = Low

---

## Download Sources

### Automated Sources

**1. Package Managers** (✅ Fully Automated)
- **winget**: Windows Package Manager
- **Chocolatey**: Community package repository
- **Scoop**: Command-line installer

**2. GitHub Releases** (✅ Automated)
- Latest release detection via API
- Asset pattern matching
- Version tracking

**3. Direct URLs** (✅ Automated)
- Direct download links
- Verified availability
- Size detection

### Manual Download Required

**4. Account-Required Software** (❌ Manual)
- FL Studio (requires Image-Line account)
- Ableton Live (requires Ableton account)
- Native Instruments (requires Native Access)
- Most commercial plugins

**5. Hardware-Specific Drivers** (❌ Manual)
- NVIDIA drivers (GPU model selection)
- AMD drivers (chipset/GPU selection)
- Manufacturer-specific utilities

**6. License-Required Software** (❌ Manual)
- Paid plugins (FabFilter, Serum, etc.)
- Commercial DAWs
- Professional audio tools

---

## Adding Custom Downloads

### Method 1: Edit auto-download.json

```json
{
  "packages": {
    "Your Software": {
      "description": "Description of software",
      "category": "development",
      "url": "https://example.com/download.exe",
      "priority": "high"
    }
  }
}
```

Then run:
```powershell
.\Check-AvailablePackages.ps1 -Download
```

### Method 2: Edit download-queue.json

```json
{
  "downloads": [
    {
      "name": "Your Software",
      "url": "https://example.com/download.exe",
      "category": "utility",
      "priority": 1
    }
  ]
}
```

Then run:
```powershell
.\Start-BatchDownload.ps1
```

### Method 3: GitHub Releases

For software with GitHub releases:

```json
{
  "Your Software": {
    "github": "owner/repository",
    "assetPattern": ".*\\.exe$",
    "description": "Auto-fetch latest release"
  }
}
```

The system will automatically find the latest release and matching asset.

---

## Troubleshooting

### Downloads fail with "Access Denied"

**Cause:** Some URLs require user agent headers or authentication

**Solution:**
1. Try downloading manually
2. Check if account/login required
3. Add package to "manual" category

### GitHub API rate limit

**Cause:** GitHub limits unauthenticated API requests to 60/hour

**Solution:**
- Wait for rate limit reset
- Add GitHub token (future feature)
- Download manually

### Package not found in any source

**Cause:** Software not in public repositories

**Solution:**
1. Add direct download URL to config
2. Mark as "manual" download
3. Check manufacturer website

### Download corrupted or incomplete

**Cause:** Network interruption

**Solution:**
```powershell
# Delete partial download
Remove-Item "C:\AbeOS\downloads\installers\file.exe"

# Retry with more attempts
.\Start-BatchDownload.ps1 -MaxRetries 5 -Resume
```

---

## Performance Tips

1. **Batch downloads** - Queue multiple downloads rather than running scripts repeatedly
2. **Concurrent downloads** - Increase `-MaxConcurrent` for faster downloads (default: 3)
3. **Caching** - Results are cached, so re-running checks is fast
4. **Priority ordering** - Set priority to download critical packages first

---

## Security Considerations

⚠️ **Important Security Notes:**

1. **Verify Sources** - Only add trusted download URLs
2. **Check Hashes** - Verify SHA256 checksums when provided
3. **Scan Downloads** - Run antivirus scans on downloaded files
4. **Official Sources** - Prefer official websites and package managers
5. **HTTPS Only** - Avoid HTTP download URLs

---

## Future Enhancements

- [ ] SHA256 checksum verification
- [ ] Parallel downloads with progress bars
- [ ] GitHub authentication for higher API limits
- [ ] Automatic version update detection
- [ ] Integration with drivers.json for auto-download
- [ ] Web scraping for manufacturer-specific drivers
- [ ] Installation automation after download
- [ ] Digital signature verification

---

## Related Documentation

- [Installation Guide](../../docs/manual/installation-guide.md)
- [Developer Environment Setup](../dev-environment/README.md)
- [Audio Plugins List](../../docs/manual/audio-plugins-list.md)
- [Driver Installation](../../stages/01_baseline/02_drivers_bios/README.md)

---

**Last Updated:** 2025-11-16
**Version:** 1.0.0
