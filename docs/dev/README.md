# Developer Documentation

Technical documentation for AbeOS development and debugging.

---

## 🛠️ Available Documents

### Debugging & Fixes
- **[debug-issues-resolved.md](./debug-issues-resolved.md)** - ✅ Comprehensive verification that all debug issues are fixed
- **[phase3-fixes.md](./phase3-fixes.md)** - Comprehensive Phase 3 fixes and learnings
- **[coverage-checklist.md](./coverage-checklist.md)** - Installation coverage tracking

### Project Documentation
- **[asset-management-system.md](./asset-management-system.md)** - Asset management system
- **[documentation-index.md](./documentation-index.md)** - Complete documentation index
- **[changelog.md](./changelog.md)** - Project changelog
- **[todo.md](./todo.md)** - Active TODO list
- **[PROJECT-CLEANUP-SUMMARY.md](./PROJECT-CLEANUP-SUMMARY.md)** - Project cleanup summary

---

## 🐛 Common Issues & Solutions

| Issue | Status | Solution |
|-------|--------|----------|
| WSL shows Windows paths in $PATH | ✅ Fixed | Configure-WSL.sh sets `appendWindowsPath=false` |
| npm global packages not found | ✅ Fixed | Install-Node-DevTools.sh sets npm global prefix |
| Claude CLI not in PATH | ✅ Fixed | Setup-PowerShell-Profile.ps1 adds to PATH |
| /etc/wsl.conf showing as SYSTEM.INI | ✅ Fixed | Configure-WSL.sh creates LF-only file + verification |
| Different PATH in VS Code vs Terminal | ✅ Fixed | Setup-PowerShell-Profile.ps1 unifies all profiles |

**All issues resolved!** See [debug-issues-resolved.md](./debug-issues-resolved.md) for complete verification.

---

## 📖 Key Learnings

From our debugging sessions:

1. **CRLF vs LF matters** - WSL ignores `/etc/wsl.conf` with CRLF line endings
2. **PATH contamination is real** - Windows paths in WSL cause npm to install globally to Windows
3. **Profile fragmentation** - Multiple PowerShell profiles need unification
4. **npm global prefix must be set** - Default behavior tries to use Windows paths
5. **System Node.js is problematic** - Always use NVM, never `apt install nodejs`

See [phase3-fixes.md](./phase3-fixes.md) for comprehensive details.

---

## 🔧 Development Workflow

### Making Changes

1. **Review debug-issues-resolved.md** to understand past issues and fixes
2. **Test in isolated environment** (VM or separate machine)
3. **Document changes** in changelog.md
4. **Update relevant docs** (manual/ and dev/)
5. **Commit with descriptive message**

### Debugging New Issues

1. **Check debug-issues-resolved.md** - All known issues are documented there
2. **Test the installation scripts** - Run Setup-DevEnvironment.ps1 to verify
3. **Document your findings** - Update debug-issues-resolved.md if new issues found
4. **Update phase fixes** - Add learnings to phase3-fixes.md

---

## 📊 Project Status

See [todo.md](./todo.md) for:
- Active development tasks
- Known issues
- Planned features
- Phase progression

---

## 🤝 Contributing

When contributing:

1. ✅ Follow existing code patterns
2. ✅ Document debugging steps
3. ✅ Update relevant docs
4. ✅ Add entries to changelog.md
5. ✅ Test on Zephyrus G14 if possible

---

**Debug Philosophy:** *"Document everything, assume nothing, verify always."*
