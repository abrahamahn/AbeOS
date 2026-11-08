// src-tauri/src/commands/security.rs
use serde::Serialize;

use super::win_utils::{ps_json_array, read_reg_dword};

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
    let safesearch_google = read_reg_dword(
        r"HKLM\SOFTWARE\Policies\Google\Chrome",
        "ForceGoogleSafeSearch",
    ) == 1;
    let safesearch_bing = read_reg_dword(
        r"HKLM\SOFTWARE\Policies\Microsoft\Edge",
        "ForceBingSafeSearch",
    ) >= 1;
    let smartscreen_enabled = read_reg_dword(
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
    let arr = ps_json_array(
        "Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 } | Select-Object InterfaceAlias, @{N='DNS';E={$_.ServerAddresses -join ','}} | ConvertTo-Json -Compress",
    );

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
