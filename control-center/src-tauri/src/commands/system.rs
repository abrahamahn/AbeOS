// src-tauri/src/commands/system.rs
use serde::Serialize;
use sysinfo::System;

use super::win_utils::ps_query;

/// Real-time system metrics returned to the frontend dashboard.
#[derive(Serialize)]
pub struct SystemInfo {
    pub cpu_usage: f32,
    pub cpu_name: String,
    pub cpu_cores: usize,
    pub memory_total_gb: f64,
    pub memory_used_gb: f64,
    pub memory_percent: f64,
    pub disks: Vec<DiskInfo>,
    pub hostname: String,
    pub os_version: String,
    pub uptime_hours: f64,
}

/// Per-disk usage info.
#[derive(Serialize)]
pub struct DiskInfo {
    pub name: String,
    pub mount: String,
    pub total_gb: f64,
    pub used_gb: f64,
    pub percent: f64,
}

/// Collects CPU, RAM, disk, and OS metadata via the `sysinfo` crate.
#[tauri::command]
pub fn get_system_info() -> SystemInfo {
    let mut sys = System::new_all();
    sys.refresh_all();

    let cpu_usage = sys.global_cpu_usage();
    let cpu_name = sys
        .cpus()
        .first()
        .map(|c| c.brand().to_string())
        .unwrap_or_default();
    let cpu_cores = sys.cpus().len();

    let memory_total = sys.total_memory() as f64;
    let memory_used = sys.used_memory() as f64;
    let bytes_to_gb = 1_073_741_824.0;

    let disks: Vec<DiskInfo> = sysinfo::Disks::new_with_refreshed_list()
        .iter()
        .map(|d| {
            let total = d.total_space() as f64;
            let available = d.available_space() as f64;
            let used = total - available;
            DiskInfo {
                name: d.name().to_string_lossy().to_string(),
                mount: d.mount_point().to_string_lossy().to_string(),
                total_gb: (total / bytes_to_gb * 10.0).round() / 10.0,
                used_gb: (used / bytes_to_gb * 10.0).round() / 10.0,
                percent: if total > 0.0 {
                    (used / total * 100.0).round()
                } else {
                    0.0
                },
            }
        })
        .collect();

    SystemInfo {
        cpu_usage,
        cpu_name,
        cpu_cores,
        memory_total_gb: (memory_total / bytes_to_gb * 10.0).round() / 10.0,
        memory_used_gb: (memory_used / bytes_to_gb * 10.0).round() / 10.0,
        memory_percent: if memory_total > 0.0 {
            (memory_used / memory_total * 100.0).round()
        } else {
            0.0
        },
        disks,
        hostname: System::host_name().unwrap_or_default(),
        os_version: System::os_version().unwrap_or_default(),
        uptime_hours: (System::uptime() as f64 / 3600.0 * 10.0).round() / 10.0,
    }
}

/// Returns the currently active ASUS ROG BIOS performance profile via ACPI WMI.
#[tauri::command]
pub fn get_power_mode() -> String {
    let result = ps_query(
        r#"try { $a = Get-WmiObject -Namespace root\WMI -Class AsusAtkWmi_WMNB -ErrorAction Stop; $r = $a.DSTS([uint32]0x00120075); $v = $r.Data -band 0xFF; switch ($v) { 0 { 'Balanced' } 1 { 'Turbo' } 2 { 'Silent' } default { "Unknown ($v)" } } } catch { 'Unknown' }"#,
    );
    if result.is_empty() {
        "Unknown".to_string()
    } else {
        result
    }
}
