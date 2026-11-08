// src-tauri/src/commands/scripts.rs
use serde::Serialize;
use std::fs;
use walkdir::WalkDir;

/// Metadata for a discovered AbeOS script file.
#[derive(Serialize)]
pub struct ScriptEntry {
    pub path: String,
    pub name: String,
    pub extension: String,
    pub category: String,
    pub description: String,
    pub size_bytes: u64,
}

/// Walks `C:\AbeOS` recursively to find all `.ps1` and `.sh` scripts.
/// Extracts the first comment line as a description.
#[tauri::command]
pub fn discover_scripts() -> Vec<ScriptEntry> {
    let abeos_root = r"C:\AbeOS";
    let mut scripts = Vec::new();

    for entry in WalkDir::new(abeos_root).into_iter().filter_map(|e| e.ok()) {
        let path = entry.path();
        let ext = path
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or_default();

        if ext != "ps1" && ext != "sh" {
            continue;
        }

        // Skip node_modules, .git, control-center build artifacts
        let path_str = path.to_string_lossy().to_string();
        if path_str.contains("node_modules")
            || path_str.contains(".git")
            || path_str.contains("control-center\\dist")
            || path_str.contains("control-center\\src-tauri\\target")
        {
            continue;
        }

        let name = path
            .file_name()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string();

        // Derive category from the parent directory relative to AbeOS root
        let category = path
            .parent()
            .map(|p| {
                p.strip_prefix(abeos_root)
                    .unwrap_or(p)
                    .to_string_lossy()
                    .replace('\\', "/")
            })
            .unwrap_or_default();

        // Read first comment line as description
        let description = fs::read_to_string(path)
            .ok()
            .and_then(|content| {
                content.lines().find_map(|line| {
                    let trimmed = line.trim();
                    if trimmed.starts_with('#')
                        && !trimmed.starts_with("#!")
                        && !trimmed.starts_with("#Requires")
                    {
                        Some(trimmed.trim_start_matches('#').trim().to_string())
                    } else {
                        None
                    }
                })
            })
            .unwrap_or_default();

        let size_bytes = entry.metadata().map(|m| m.len()).unwrap_or(0);

        scripts.push(ScriptEntry {
            path: path_str,
            name,
            extension: ext.to_string(),
            category,
            description,
            size_bytes,
        });
    }

    scripts.sort_by(|a, b| a.category.cmp(&b.category).then(a.name.cmp(&b.name)));
    scripts
}

/// Returns the full text content of a script file.
#[tauri::command]
pub fn get_script_content(path: String) -> Result<String, String> {
    // Security: only allow reading files under C:\AbeOS
    if !path.starts_with(r"C:\AbeOS") {
        return Err("Access denied: path must be under C:\\AbeOS".to_string());
    }
    fs::read_to_string(&path).map_err(|e| format!("Failed to read {}: {}", path, e))
}
