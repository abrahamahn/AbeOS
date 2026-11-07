// src-tauri/src/commands/audio.rs
use serde::Serialize;

/// Audio subsystem overview.
#[derive(Serialize)]
pub struct AudioInfo {
    pub devices: Vec<AudioDevice>,
    pub vst2_count: u32,
    pub vst3_count: u32,
    pub audio_service_running: bool,
}

/// A single audio endpoint (playback or recording).
#[derive(Serialize)]
pub struct AudioDevice {
    pub name: String,
    pub device_type: String,
    pub status: String,
}

/// Queries audio devices, VST plugin counts, and audio service status.
#[tauri::command]
pub fn get_audio_info() -> AudioInfo {
    let devices = get_audio_devices();
    let vst2_count = count_vst_plugins(r"C:\Production\Library\VST2");
    let vst3_count = count_vst_plugins(r"C:\Program Files\Common Files\VST3");
    let audio_service_running = check_service_running("Audiosrv");

    AudioInfo {
        devices,
        vst2_count,
        vst3_count,
        audio_service_running,
    }
}

/// Lists audio devices via PowerShell Get-CimInstance.
fn get_audio_devices() -> Vec<AudioDevice> {
    let output = std::process::Command::new("powershell.exe")
        .args([
            "-NoProfile",
            "-Command",
            "Get-CimInstance Win32_SoundDevice | Select-Object Name, Status, Manufacturer | ConvertTo-Json -Compress",
        ])
        .output();

    match output {
        Ok(o) => {
            let text = String::from_utf8_lossy(&o.stdout);
            if let Ok(arr) = serde_json::from_str::<Vec<serde_json::Value>>(&text) {
                arr.iter()
                    .filter_map(|v| {
                        Some(AudioDevice {
                            name: v.get("Name")?.as_str()?.to_string(),
                            device_type: v
                                .get("Manufacturer")
                                .and_then(|m| m.as_str())
                                .unwrap_or("Unknown")
                                .to_string(),
                            status: v
                                .get("Status")
                                .and_then(|s| s.as_str())
                                .unwrap_or("Unknown")
                                .to_string(),
                        })
                    })
                    .collect()
            } else if let Ok(v) = serde_json::from_str::<serde_json::Value>(&text) {
                vec![AudioDevice {
                    name: v.get("Name").and_then(|n| n.as_str()).unwrap_or("Unknown").to_string(),
                    device_type: v.get("Manufacturer").and_then(|m| m.as_str()).unwrap_or("Unknown").to_string(),
                    status: v.get("Status").and_then(|s| s.as_str()).unwrap_or("Unknown").to_string(),
                }]
            } else {
                Vec::new()
            }
        }
        Err(_) => Vec::new(),
    }
}

/// Counts plugin files (`.dll` for VST2, `.vst3` for VST3) in a directory.
fn count_vst_plugins(dir: &str) -> u32 {
    let path = std::path::Path::new(dir);
    if !path.exists() {
        return 0;
    }
    walkdir::WalkDir::new(dir)
        .into_iter()
        .filter_map(|e| e.ok())
        .filter(|e| {
            let ext = e
                .path()
                .extension()
                .and_then(|x| x.to_str())
                .unwrap_or_default();
            ext == "dll" || ext == "vst3"
        })
        .count() as u32
}

/// Checks if a Windows service is running via `sc query`.
fn check_service_running(service: &str) -> bool {
    let output = std::process::Command::new("sc.exe")
        .args(["query", service])
        .output();

    match output {
        Ok(o) => {
            let text = String::from_utf8_lossy(&o.stdout);
            text.contains("RUNNING")
        }
        Err(_) => false,
    }
}
