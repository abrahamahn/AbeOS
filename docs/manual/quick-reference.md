# Quick Reference Card

## 🚀 Installation Order (Critical Path)

```
1. GHelper + RTL Utility              (5 min)
2. Equalizer APO + Peace              (10 min)
3. FlexASIO                           (5 min)
4. All Plugin Managers                (45 min)
5. DAW (Studio One 5)                 (20 min)
6. Essential Plugins                  (2 hours)
   → Serum 2, Vital, Diva
   → Pro-Q 3, Valhalla Room
   → OTT, ShaperBox 3
7. Remaining Plugins                  (4-6 hours)
8. Fonts + Cursors                    (10 min)
```

**Total Time**: 8-12 hours

---

## 📋 Phase Checklist (Minimal Setup)

### Must-Have (Can't work without)
- [ ] GHelper
- [ ] Equalizer APO + Peace
- [ ] Studio One 5
- [ ] Xfer Serum 2
- [ ] FabFilter Pro-Q 3
- [ ] Valhalla Room
- [ ] Caskaydia Cove Nerd Font

### Should-Have (90% of work uses these)
- [ ] Vital
- [ ] u-he Diva
- [ ] Gullfoss
- [ ] Soothe2
- [ ] OTT
- [ ] ShaperBox 3
- [ ] Soundtoys 5
- [ ] TAL-Reverb-4

### Nice-to-Have (Specific use cases)
- [ ] Omnisphere 2
- [ ] iZotope RX 7
- [ ] Portal
- [ ] All free plugins
- [ ] Cursor themes

---

## 🎹 Plugin Quick Find

### "I need a synth for..."

| Use Case | Plugin |
|----------|--------|
| Versatile workhorse | Serum 2 / Vital |
| Analog warmth | u-he Diva |
| Dark/atmospheric | u-he Hive |
| Pads/textures | Omnisphere 2 |
| Bass/leads | Spire |
| Retro sounds | TAL-U-NO-LX |
| Experimental | The Dark Zebra |

### "I need an effect for..."

| Use Case | Plugin |
|----------|--------|
| EQ | FabFilter Pro-Q 3 |
| Compression | Soundtoys Devil-Loc / Gullfoss |
| Reverb | Valhalla Room / Vintage Verb |
| Delay | Valhalla UberMod / Soundtoys EchoBoy |
| Saturation | Baby Audio TAIP / Soundtoys Decapitator |
| Widening | Polyverse Wider / Dimension Expander |
| Multiband | OTT / ShaperBox 3 |
| De-essing | Soothe2 |
| Transient | Baby Audio Beat Slammer |
| Pitch | Baby Audio Pitch Drift |
| Lo-fi | Baby Audio Super VHS / Cassette |
| Glitch | Portal / Stutter Edit |
| Limiting | Invisible Limiter / Frontier |

---

## 📁 Critical File Locations

### VST Paths (Default)
```
C:\Program Files\VSTPlugins
C:\Program Files\Common Files\VST3
C:\Program Files\Steinberg\VstPlugins
```

### License Files Location
```
assets\installations\plugins\Windows\
  ├── spire.lic
  ├── TAL-U-NO-LX_SerialKey.txt
  ├── Valhalla*.vkeyfile (4 files)
  ├── *_License.lic (HalfTime, ShaperBox3, Kickstart2)
  └── KICK - Nicky Romero.license
```

### Font Installation
```
C:\Windows\Fonts\
OR
Settings > Personalization > Fonts
```

---

## ⚡ PowerShell Commands

```powershell
# Interactive menu
.\manage-assets.ps1

# List specific category
.\manage-assets.ps1 -Action list -Category plugins

# Verify files exist
.\manage-assets.ps1 -Action verify

# Export manifest
.\manage-assets.ps1 -Action export

# Check installation log
Get-Content .\installation-log.txt -Tail 50
```

---

## 🔍 Search Commands

### Find a plugin in manifest
```powershell
$manifest = Get-Content .\asset-manifest.json | ConvertFrom-Json
$manifest.categories.plugins.subcategories.synthesizers.items | 
    Where-Object { $_.name -like "*Serum*" }
```

### Find all files matching pattern
```powershell
Get-ChildItem -Path .\assets\installations\plugins\Windows -Recurse -Filter "*Valhalla*"
```

### Count installers
```powershell
(Get-ChildItem -Path .\assets\installations\plugins\Windows -File).Count
```

---

## 🛠️ Troubleshooting Quick Fixes

### Plugin won't load
```
1. Check bit version (32/64)
2. Verify VST path in DAW
3. Rescan plugins
4. Install Visual C++ Redist 2015-2022
5. Check license activation
```

### Audio issues
```
1. Set buffer: 256-512 samples
2. Use ASIO driver (FlexASIO)
3. Disable audio enhancements in Windows
4. Update audio interface drivers
5. Restart audio engine in DAW
```

### Installation fails
```
1. Run as Administrator
2. Disable antivirus temporarily
3. Check disk space (need 20+ GB)
4. Uninstall old version first
5. Reboot and try again
```

---

## 📊 Asset Counts

| Category | Total |
|----------|-------|
| Synthesizers | ~30 |
| Effects | ~150 |
| Plugin Managers | 15 |
| Free Plugins | ~40 |
| Utilities | 5 |
| Fonts | 36 TTF |
| Cursor Themes | 9 |

**Grand Total**: 315+ items

---

## ⏱️ Time Estimates

| Task | Time |
|------|------|
| System utilities | 30 min |
| Audio foundation | 30 min |
| Plugin managers | 1 hour |
| Essential plugins | 2 hours |
| All plugins | 6-8 hours |
| Fonts + cursors | 15 min |
| Testing + config | 1-2 hours |
| **TOTAL** | **8-12 hours** |

---

## 🎯 Installation Priorities

### Priority 1 (Do First - 2 hours)
- GHelper, RTL Utility
- Equalizer APO, FlexASIO
- Plugin managers
- Studio One 5
- Serum 2, Vital
- Pro-Q 3, Valhalla Room
- Nerd Font

### Priority 2 (Essential Workflow - 2 hours)
- Diva, Hive, Spire
- Gullfoss, Soothe2
- Soundtoys Bundle
- OTT, ShaperBox 3
- All free plugins (TDR, Voxengo)

### Priority 3 (Nice to Have - 4+ hours)
- Omnisphere, Trilian
- iZotope Suite
- Baby Audio suite
- Denise Audio suite
- Remaining effects
- Cursor themes

---

## 🔐 License File Backup Checklist

- [ ] Copy all .lic files
- [ ] Copy all .vkeyfile files
- [ ] Copy all .license files
- [ ] Copy TAL serial key .txt
- [ ] Upload to Google Drive (encrypted folder)
- [ ] Create local backup on external drive
- [ ] Document activation limits

---

## 💾 Disk Space Requirements

| Phase | Space Needed |
|-------|--------------|
| System utilities | 500 MB |
| Plugin managers | 2 GB |
| Essential plugins | 5 GB |
| All plugins | 15-20 GB |
| Spectrasonics | 50+ GB |
| **Safe margin** | **25 GB total** |

---

## 📞 Quick Support Links

| Software | Support |
|----------|---------|
| Xfer | xferrecords.com/support |
| u-he | u-he.com/support |
| FabFilter | fabfilter.com/support |
| Valhalla | valhalladsp.com/support |
| Soundtoys | soundtoys.com/support |
| Plugin Alliance | plugin-alliance.com/support |
| iZotope | izotope.com/support |

---

## 🎨 Cursor Theme Quick Pick

**Best for High DPI**: XtraLarge variants  
**Best for Normal DPI**: Normal variants  
**With or without shadow**: Personal preference  
**Recommended**: Sierra+ No Shadow Normal

---

## 🚦 Status Indicators

After installation, verify:

✅ **Green Light**:
- All plugins load in DAW
- No error messages
- Licenses activated
- Presets accessible

⚠️ **Yellow Light**:
- Some plugins need rescan
- Update available
- Manual authorization needed

🔴 **Red Light**:
- Plugin missing dependencies
- License activation failed
- Installation corrupt
- Reinstall required

---

**Print this card and keep it handy during installation!**

Last Updated: 2025-11-16
