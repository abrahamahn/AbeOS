// src-tauri/src/commands/hardware.rs
use serde::Serialize;

use super::win_utils::{ps_json, ps_json_array, ps_query};

/// Extended hardware health data beyond basic system info.
#[derive(Serialize)]
pub struct HardwareHealth {
    pub battery: Option<BatteryInfo>,
    pub gpu: Vec<GpuInfo>,
    pub network_adapters: Vec<NetworkAdapterInfo>,
    pub wifi: Option<WifiInfo>,
    pub bluetooth: Option<BluetoothInfo>,
    pub disk_health: Vec<DiskHealthInfo>,
    pub bios: BiosInfo,
}

/// Battery health and charge status.
#[derive(Serialize)]
pub struct BatteryInfo {
    pub design_capacity_mwh: u32,
    pub full_charge_capacity_mwh: u32,
    pub current_charge_percent: u32,
    pub health_percent: f64,
    pub cycle_count: u32,
    pub status: String,
}

/// GPU information.
#[derive(Serialize)]
pub struct GpuInfo {
    pub name: String,
    pub driver_version: String,
    pub vram_gb: f64,
    pub status: String,
}

/// Network adapter info.
#[derive(Serialize)]
pub struct NetworkAdapterInfo {
    pub name: String,
    pub adapter_type: String,
    pub mac_address: String,
    pub ip_address: String,
    pub link_speed: String,
    pub status: String,
}

/// WiFi connection details.
#[derive(Serialize)]
pub struct WifiInfo {
    pub ssid: String,
    pub signal_percent: u32,
    pub link_speed: String,
    pub auth_type: String,
}

/// Bluetooth adapter status.
#[derive(Serialize)]
pub struct BluetoothInfo {
    pub adapter_name: String,
    pub status: String,
    pub connected_devices: Vec<String>,
}

/// Physical disk health.
#[derive(Serialize)]
pub struct DiskHealthInfo {
    pub model: String,
    pub media_type: String,
    pub status: String,
    pub temperature_c: Option<f64>,
    pub size_gb: f64,
}

/// BIOS information.
#[derive(Serialize)]
pub struct BiosInfo {
    pub version: String,
    pub manufacturer: String,
    pub release_date: String,
}

/// Gathers extended hardware health from multiple PowerShell/WMI queries.
#[tauri::command]
pub fn get_hardware_health() -> HardwareHealth {
    HardwareHealth {
        battery: get_battery_info(),
        gpu: get_gpu_info(),
        network_adapters: get_network_adapters(),
        wifi: get_wifi_info(),
        bluetooth: get_bluetooth_info(),
        disk_health: get_disk_health(),
        bios: get_bios_info(),
    }
}

/// Queries battery info via WMI. Returns None on desktops without a battery.
fn get_battery_info() -> Option<BatteryInfo> {
    let json = ps_json(
        r#"
        $b = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
        if (-not $b) { exit }
        $design = 0; $full = 0; $cycles = 0
        try {
            $bs = Get-CimInstance -Namespace root\WMI -ClassName BatteryStaticData -ErrorAction Stop
            $design = $bs.DesignedCapacity
            $full = $bs.FullChargedCapacity
        } catch {}
        try {
            $bc = Get-CimInstance -Namespace root\WMI -ClassName BatteryCycleCount -ErrorAction Stop
            $cycles = $bc.CycleCount
        } catch {}
        @{
            DesignCapacity = $design
            FullChargeCapacity = $full
            ChargePercent = $b.EstimatedChargeRemaining
            CycleCount = $cycles
            Status = switch ($b.BatteryStatus) {
                1 { "Discharging" } 2 { "AC Power" } 3 { "Fully Charged" }
                4 { "Low" } 5 { "Critical" } 6 { "Charging" }
                7 { "Charging High" } 8 { "Charging Low" } 9 { "Charging Critical" }
                default { "Unknown" }
            }
        } | ConvertTo-Json -Compress
        "#,
    )?;

    let design = json.get("DesignCapacity")?.as_u64().unwrap_or(0) as u32;
    let full = json.get("FullChargeCapacity")?.as_u64().unwrap_or(0) as u32;
    let health = if design > 0 {
        (full as f64 / design as f64) * 100.0
    } else {
        0.0
    };

    Some(BatteryInfo {
        design_capacity_mwh: design,
        full_charge_capacity_mwh: full,
        current_charge_percent: json.get("ChargePercent")?.as_u64().unwrap_or(0) as u32,
        health_percent: (health * 10.0).round() / 10.0,
        cycle_count: json.get("CycleCount")?.as_u64().unwrap_or(0) as u32,
        status: json
            .get("Status")?
            .as_str()
            .unwrap_or("Unknown")
            .to_string(),
    })
}

/// Queries GPU info via Win32_VideoController.
fn get_gpu_info() -> Vec<GpuInfo> {
    let arr = ps_json_array(
        "Get-CimInstance -ClassName Win32_VideoController | Select-Object Name, DriverVersion, AdapterRAM, Status | ConvertTo-Json -Compress",
    );

    arr.iter()
        .filter_map(|v| {
            let ram_bytes = v.get("AdapterRAM")?.as_u64().unwrap_or(0);
            Some(GpuInfo {
                name: v.get("Name")?.as_str().unwrap_or("Unknown").to_string(),
                driver_version: v
                    .get("DriverVersion")
                    .and_then(|d| d.as_str())
                    .unwrap_or("Unknown")
                    .to_string(),
                vram_gb: (ram_bytes as f64 / 1_073_741_824.0 * 10.0).round() / 10.0,
                status: v
                    .get("Status")
                    .and_then(|s| s.as_str())
                    .unwrap_or("Unknown")
                    .to_string(),
            })
        })
        .collect()
}

/// Queries network adapters with IP addresses.
fn get_network_adapters() -> Vec<NetworkAdapterInfo> {
    let arr = ps_json_array(
        r#"
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'Virtual|Loopback' } |
            Select-Object Name, InterfaceDescription, MacAddress, Status, LinkSpeed, MediaType
        $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Select-Object InterfaceAlias, IPAddress
        $result = @()
        foreach ($a in $adapters) {
            $ip = ($ips | Where-Object { $_.InterfaceAlias -eq $a.Name }).IPAddress
            $result += @{
                Name = $a.Name
                Type = $(if ($a.Name -match 'Wi-Fi|Wireless') { 'Wi-Fi' } else { 'Ethernet' })
                Mac = $a.MacAddress
                IP = $(if ($ip) { $ip } else { '--' })
                Speed = $a.LinkSpeed
                Status = $a.Status
            }
        }
        $result | ConvertTo-Json -Compress
        "#,
    );

    arr.iter()
        .filter_map(|v| {
            Some(NetworkAdapterInfo {
                name: v.get("Name")?.as_str().unwrap_or("").to_string(),
                adapter_type: v.get("Type")?.as_str().unwrap_or("").to_string(),
                mac_address: v.get("Mac")?.as_str().unwrap_or("").to_string(),
                ip_address: v.get("IP")?.as_str().unwrap_or("--").to_string(),
                link_speed: v.get("Speed")?.as_str().unwrap_or("").to_string(),
                status: v.get("Status")?.as_str().unwrap_or("").to_string(),
            })
        })
        .collect()
}

/// Queries WiFi connection details via netsh.
fn get_wifi_info() -> Option<WifiInfo> {
    let text = ps_query("netsh wlan show interfaces");
    if text.is_empty() || text.contains("not running") {
        return None;
    }

    let get_field = |key: &str| -> String {
        text.lines()
            .find(|l| l.trim().starts_with(key))
            .map(|l| {
                l.split(':')
                    .skip(1)
                    .collect::<Vec<_>>()
                    .join(":")
                    .trim()
                    .to_string()
            })
            .unwrap_or_default()
    };

    let ssid = get_field("SSID");
    if ssid.is_empty() {
        return None;
    }

    let signal_str = get_field("Signal");
    let signal = signal_str.trim_end_matches('%').parse::<u32>().unwrap_or(0);

    Some(WifiInfo {
        ssid,
        signal_percent: signal,
        link_speed: format!(
            "{} / {}",
            get_field("Receive rate"),
            get_field("Transmit rate")
        ),
        auth_type: get_field("Authentication"),
    })
}

/// Queries Bluetooth devices via PnP.
fn get_bluetooth_info() -> Option<BluetoothInfo> {
    let json = ps_json(
        r#"
        $bt = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'OK' }
        if (-not $bt) { exit }
        $adapter = ($bt | Where-Object { $_.FriendlyName -match 'Radio|Adapter|Bluetooth' } | Select-Object -First 1).FriendlyName
        $devices = ($bt | Where-Object { $_.FriendlyName -notmatch 'Radio|Adapter|Enumerator|Microsoft' }).FriendlyName
        @{
            Adapter = $(if ($adapter) { $adapter } else { 'Bluetooth Adapter' })
            Devices = @($devices | Where-Object { $_ })
        } | ConvertTo-Json -Compress
        "#,
    )?;

    Some(BluetoothInfo {
        adapter_name: json
            .get("Adapter")?
            .as_str()
            .unwrap_or("Bluetooth")
            .to_string(),
        status: "OK".to_string(),
        connected_devices: json
            .get("Devices")
            .and_then(|d| d.as_array())
            .map(|arr| {
                arr.iter()
                    .filter_map(|v| v.as_str().map(|s| s.to_string()))
                    .collect()
            })
            .unwrap_or_default(),
    })
}

/// Queries physical disk health via Get-PhysicalDisk.
fn get_disk_health() -> Vec<DiskHealthInfo> {
    let arr = ps_json_array(
        r#"
        $disks = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, Size
        $temps = @{}
        try {
            Get-PhysicalDisk | Get-StorageReliabilityCounter -ErrorAction Stop | ForEach-Object {
                $temps[$_.DeviceId] = $_.Temperature
            }
        } catch {}
        $result = @()
        $i = 0
        foreach ($d in $disks) {
            $result += @{
                Model = $d.FriendlyName
                MediaType = "$($d.MediaType)"
                Status = "$($d.HealthStatus)"
                SizeGB = [math]::Round($d.Size / 1GB, 1)
                TempC = $temps["$i"]
            }
            $i++
        }
        $result | ConvertTo-Json -Compress
        "#,
    );

    arr.iter()
        .filter_map(|v| {
            Some(DiskHealthInfo {
                model: v.get("Model")?.as_str().unwrap_or("").to_string(),
                media_type: v.get("MediaType")?.as_str().unwrap_or("").to_string(),
                status: v.get("Status")?.as_str().unwrap_or("").to_string(),
                temperature_c: v.get("TempC").and_then(|t| t.as_f64()),
                size_gb: v.get("SizeGB")?.as_f64().unwrap_or(0.0),
            })
        })
        .collect()
}

/// Queries BIOS info via Win32_BIOS.
fn get_bios_info() -> BiosInfo {
    let json = ps_json(
        "Get-CimInstance -ClassName Win32_BIOS | Select-Object SMBIOSBIOSVersion, Manufacturer, @{N='ReleaseDate';E={$_.ReleaseDate.ToString('yyyy-MM-dd')}} | ConvertTo-Json -Compress",
    );

    match json {
        Some(v) => BiosInfo {
            version: v
                .get("SMBIOSBIOSVersion")
                .and_then(|s| s.as_str())
                .unwrap_or("Unknown")
                .to_string(),
            manufacturer: v
                .get("Manufacturer")
                .and_then(|s| s.as_str())
                .unwrap_or("Unknown")
                .to_string(),
            release_date: v
                .get("ReleaseDate")
                .and_then(|s| s.as_str())
                .unwrap_or("Unknown")
                .to_string(),
        },
        None => BiosInfo {
            version: "Unknown".to_string(),
            manufacturer: "Unknown".to_string(),
            release_date: "Unknown".to_string(),
        },
    }
}
