# Developer Documentation

Technical documentation for AbeOS development and debugging.

---

## 🛠️ Available Documents

### Debugging Guides
- **[debug-wsl-setup.md](./debug-wsl-setup.md)** - WSL configuration and PATH issues
- **[debug-powershell-profiles.md](./debug-powershell-profiles.md)** - PowerShell profile unification
- **[debug-root-cause-analysis.md](./debug-root-cause-analysis.md)** - Root cause analysis protocol
- **[debug-session-4.md](./debug-session-4.md)** - Additional debugging session

### Project Documentation
- **[phase3-fixes.md](./phase3-fixes.md)** - Comprehensive Phase 3 fixes and learnings
- **[asset-management-system.md](./asset-management-system.md)** - Asset management system
- **[documentation-index.md](./documentation-index.md)** - Complete documentation index
- **[changelog.md](./changelog.md)** - Project changelog
- **[todo.md](./todo.md)** - Active TODO list

---

## 🐛 Common Issues & Solutions

| Issue | Solution Document |
|-------|-------------------|
| WSL shows Windows paths in $PATH | [debug-wsl-setup.md](./debug-wsl-setup.md) |
| npm global packages not found | [debug-wsl-setup.md](./debug-wsl-setup.md) |
| Claude CLI not in PATH | [debug-powershell-profiles.md](./debug-powershell-profiles.md) |
| /etc/wsl.conf showing as SYSTEM.INI | [debug-wsl-setup.md](./debug-wsl-setup.md) |
| Different PATH in VS Code vs Terminal | [debug-powershell-profiles.md](./debug-powershell-profiles.md) |

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

1. **Read the relevant debug docs** to understand past issues
2. **Test in isolated environment** (VM or separate machine)
3. **Document changes** in changelog.md
4. **Update relevant docs** (manual/ and dev/)
5. **Commit with descriptive message**

### Debugging New Issues

1. **Check existing debug docs** - Issue may be documented
2. **Document your findings** - Create new debug-*.md if needed
3. **Root cause analysis** - Follow protocol in debug-root-cause-analysis.md
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
