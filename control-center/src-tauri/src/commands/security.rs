// src-tauri/src/commands/security.rs
use serde::Serialize;

/// Current DNS configuration per network adapter.
#[derive(Serialize)]
pub struct DnsConfig {
    pub adapters: Vec<AdapterDns>,
    pub safesearch_google: bool,
    pub safesearch_bing: bool,
    pub smartscreen_enabled: bool,
    pub hosts_blocked_count: u32,
}

/// DNS servers configured on a single adapter.
#[derive(Serialize)]
pub struct AdapterDns {
    pub name: String,
    pub dns_servers: Vec<String>,
}

/// Reads current DNS configuration, SafeSearch status, and hosts file entry count.
#[tauri::command]
pub fn get_dns_config() -> DnsConfig {
    let adapters = read_dns_adapters();
    let safesearch_google = read_registry_dword(
        r"HKLM\SOFTWARE\Policies\Google\Chrome",
        "ForceGoogleSafeSearch",
    ) == 1;
    let safesearch_bing = read_registry_dword(
        r"HKLM\SOFTWARE\Policies\Microsoft\Edge",
        "ForceBingSafeSearch",
    ) >= 1;
    let smartscreen_enabled = read_registry_dword(
        r"HKLM\SOFTWARE\Policies\Microsoft\Windows\System",
        "EnableSmartScreen",
    ) == 1;
    let hosts_blocked_count = count_hosts_entries();

    DnsConfig {
        adapters,
        safesearch_google,
        safesearch_bing,
        smartscreen_enabled,
        hosts_blocked_count,
    }
}

/// Queries DNS servers from all active network adapters via PowerShell.
fn read_dns_adapters() -> Vec<AdapterDns> {
    let output = std::process::Command::new("powershell.exe")
        .args([
            "-NoProfile",
            "-Command",
            "Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 } | Select-Object InterfaceAlias, @{N='DNS';E={$_.ServerAddresses -join ','}} | ConvertTo-Json -Compress",
        ])
        .output();

    match output {
        Ok(o) => {
            let text = String::from_utf8_lossy(&o.stdout);
            // Parse JSON array or single object
            if let Ok(arr) = serde_json::from_str::<Vec<serde_json::Value>>(&text) {
                arr.iter()
                    .filter_map(|v| {
                        let name = v.get("InterfaceAlias")?.as_str()?.to_string();
                        let dns = v.get("DNS")?.as_str()?.to_string();
                        Some(AdapterDns {
                            name,
                            dns_servers: dns.split(',').map(|s| s.trim().to_string()).collect(),
                        })
                    })
                    .collect()
            } else if let Ok(v) = serde_json::from_str::<serde_json::Value>(&text) {
                let name = v.get("InterfaceAlias").and_then(|v| v.as_str()).unwrap_or("Unknown").to_string();
                let dns = v.get("DNS").and_then(|v| v.as_str()).unwrap_or("").to_string();
                vec![AdapterDns {
                    name,
                    dns_servers: dns.split(',').map(|s| s.trim().to_string()).collect(),
                }]
            } else {
                Vec::new()
            }
        }
        Err(_) => Vec::new(),
    }
}

/// Reads a DWORD from the Windows registry via `reg query`.
fn read_registry_dword(key: &str, value: &str) -> u32 {
    let output = std::process::Command::new("reg.exe")
        .args(["query", key, "/v", value])
        .output();

    match output {
        Ok(o) => {
            let text = String::from_utf8_lossy(&o.stdout);
            // Parse "0x1" or "0x0" from reg query output
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

/// Counts non-comment, non-empty lines in the Windows hosts file.
fn count_hosts_entries() -> u32 {
    let hosts_path = r"C:\Windows\System32\drivers\etc\hosts";
    std::fs::read_to_string(hosts_path)
        .unwrap_or_default()
        .lines()
        .filter(|line| {
            let trimmed = line.trim();
            !trimmed.is_empty() && !trimmed.starts_with('#')
        })
        .count() as u32
}
