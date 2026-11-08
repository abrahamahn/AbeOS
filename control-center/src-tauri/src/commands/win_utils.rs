// src-tauri/src/commands/win_utils.rs
use std::process::Command;

/// Runs a PowerShell command and returns stdout as a trimmed string.
pub fn ps_query(command: &str) -> String {
    let output = Command::new("powershell.exe")
        .args(["-NoProfile", "-Command", command])
        .output();
    match output {
        Ok(o) => String::from_utf8_lossy(&o.stdout).trim().to_string(),
        Err(_) => String::new(),
    }
}

/// Runs a PowerShell command and parses the JSON output.
pub fn ps_json(command: &str) -> Option<serde_json::Value> {
    let text = ps_query(command);
    if text.is_empty() {
        return None;
    }
    serde_json::from_str(&text).ok()
}

/// Runs a PowerShell command returning JSON and normalizes a single object or array into a Vec.
pub fn ps_json_array(command: &str) -> Vec<serde_json::Value> {
    match ps_json(command) {
        Some(serde_json::Value::Array(arr)) => arr,
        Some(obj @ serde_json::Value::Object(_)) => vec![obj],
        _ => Vec::new(),
    }
}

/// Reads a DWORD registry value via `reg.exe`.
pub fn read_reg_dword(key: &str, value: &str) -> u32 {
    let output = Command::new("reg.exe")
        .args(["query", key, "/v", value])
        .output();

    match output {
        Ok(o) => {
            let text = String::from_utf8_lossy(&o.stdout);
            text.lines()
                .find(|line| line.contains(value))
                .and_then(|line| {
                    line.split_whitespace()
                        .last()
                        .and_then(|v| u32::from_str_radix(v.trim_start_matches("0x"), 16).ok())
                })
                .unwrap_or(0)
        }
        Err(_) => 0,
    }
}

/// Reads a string (REG_SZ) registry value via `reg.exe`.
pub fn read_reg_string(key: &str, value: &str) -> String {
    let output = Command::new("reg.exe")
        .args(["query", key, "/v", value])
        .output();

    match output {
        Ok(o) => {
            let text = String::from_utf8_lossy(&o.stdout);
            text.lines()
                .find(|line| line.contains(value))
                .and_then(|line| {
                    let parts: Vec<&str> = line.split_whitespace().collect();
                    // Format: "    ValueName    REG_SZ    Data"
                    if parts.len() >= 3 {
                        Some(parts[2..].join(" "))
                    } else {
                        None
                    }
                })
                .unwrap_or_default()
        }
        Err(_) => String::new(),
    }
}

/// Checks if a Windows service is running via `sc.exe query`.
pub fn check_service_running(service: &str) -> bool {
    let output = Command::new("sc.exe").args(["query", service]).output();

    match output {
        Ok(o) => {
            let text = String::from_utf8_lossy(&o.stdout);
            text.contains("RUNNING")
        }
        Err(_) => false,
    }
}
