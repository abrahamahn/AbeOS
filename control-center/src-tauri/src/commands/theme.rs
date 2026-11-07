// src-tauri/src/commands/theme.rs
use serde::Serialize;

/// Current state of AbeOS theme settings read from the Windows registry.
#[derive(Serialize)]
pub struct ThemeStatus {
    pub dark_mode: bool,
    pub accent_color: String,
    pub window_colorization: bool,
    pub verbose_boot: bool,
    pub cursor_type: u32,
    pub search_hidden: bool,
    pub copilot_hidden: bool,
    pub task_view_hidden: bool,
    pub widgets_hidden: bool,
    pub game_bar_off: bool,
    pub oem_manufacturer: String,
    pub oem_model: String,
}

/// Reads current theme-related registry values and returns them as a typed struct.
#[tauri::command]
pub fn get_theme_status() -> ThemeStatus {
    ThemeStatus {
        dark_mode: read_reg_dword(
            r"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize",
            "AppsUseLightTheme",
        ) == 0,
        accent_color: read_reg_string(
            r"HKCU\SOFTWARE\Microsoft\Windows\DWM",
            "AccentColor",
        ),
        window_colorization: read_reg_dword(
            r"HKCU\SOFTWARE\Microsoft\Windows\DWM",
            "EnableWindowColorization",
        ) == 1,
        verbose_boot: read_reg_dword(
            r"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System",
            "VerboseStatus",
        ) == 1,
        cursor_type: read_reg_dword(
            r"HKCU\SOFTWARE\Microsoft\Accessibility",
            "CursorType",
        ),
        search_hidden: read_reg_dword(
            r"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search",
            "SearchboxTaskbarMode",
        ) == 0,
        copilot_hidden: read_reg_dword(
            r"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
            "ShowCopilotButton",
        ) == 0,
        task_view_hidden: read_reg_dword(
            r"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
            "ShowTaskViewButton",
        ) == 0,
        widgets_hidden: read_reg_dword(
            r"HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced",
            "TaskbarDa",
        ) == 0,
        game_bar_off: read_reg_dword(
            r"HKCU\SOFTWARE\Microsoft\GameBar",
            "UseNexusForGameBarEnabled",
        ) == 0,
        oem_manufacturer: read_reg_string(
            r"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation",
            "Manufacturer",
        ),
        oem_model: read_reg_string(
            r"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation",
            "Model",
        ),
    }
}

/// Reads a DWORD registry value via `reg.exe`.
fn read_reg_dword(key: &str, value: &str) -> u32 {
    let output = std::process::Command::new("reg.exe")
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
fn read_reg_string(key: &str, value: &str) -> String {
    let output = std::process::Command::new("reg.exe")
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
