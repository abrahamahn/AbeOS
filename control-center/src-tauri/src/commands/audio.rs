// src-tauri/src/commands/audio.rs
use serde::Serialize;

use super::win_utils::{check_service_running, ps_json_array};

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
    let arr = ps_json_array(
        "Get-CimInstance Win32_SoundDevice | Select-Object Name, Status, Manufacturer | ConvertTo-Json -Compress",
    );

    arr.iter()
        .map(|v| AudioDevice {
            name: v
                .get("Name")
                .and_then(|n| n.as_str())
                .unwrap_or("Unknown")
                .to_string(),
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
        .collect()
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
