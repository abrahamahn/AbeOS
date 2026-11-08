// src-tauri/src/commands/maintenance.rs
use serde::Serialize;

/// A Windows scheduled task entry relevant to AbeOS.
#[derive(Serialize)]
pub struct ScheduledTask {
    pub name: String,
    pub status: String,
    pub next_run: String,
    pub last_run: String,
}

/// A log file entry from the AbeOS logs directory.
#[derive(Serialize)]
pub struct LogEntry {
    pub name: String,
    pub path: String,
    pub modified: String,
    pub size_kb: f64,
}

/// Queries AbeOS-related scheduled tasks from Windows Task Scheduler.
#[tauri::command]
pub fn get_scheduled_tasks() -> Vec<ScheduledTask> {
    let output = std::process::Command::new("schtasks.exe")
        .args(["/query", "/fo", "CSV", "/nh"])
        .output();

    match output {
        Ok(o) => {
            let text = String::from_utf8_lossy(&o.stdout);
            text.lines()
                .filter(|line| line.contains("AbeOS"))
                .filter_map(|line| {
                    let fields: Vec<&str> = line.split(',').map(|f| f.trim_matches('"')).collect();
                    if fields.len() >= 4 {
                        Some(ScheduledTask {
                            name: fields[0]
                                .trim_start_matches('\\')
                                .trim_start_matches("AbeOS\\")
                                .to_string(),
                            status: fields[2].to_string(),
                            next_run: fields[1].to_string(),
                            last_run: if fields.len() > 4 {
                                fields[4].to_string()
                            } else {
                                "N/A".to_string()
                            },
                        })
                    } else {
                        None
                    }
                })
                .collect()
        }
        Err(_) => Vec::new(),
    }
}

/// Lists log files and audit directories under `C:\AbeOS\logs`.
#[tauri::command]
pub fn get_log_entries() -> Vec<LogEntry> {
    let logs_dir = r"C:\AbeOS\logs";
    let path = std::path::Path::new(logs_dir);
    if !path.exists() {
        return Vec::new();
    }

    let mut entries = Vec::new();
    if let Ok(dir) = std::fs::read_dir(path) {
        for entry in dir.flatten() {
            let meta = entry.metadata().ok();
            let modified = meta
                .as_ref()
                .and_then(|m| m.modified().ok())
                .map(|t| {
                    let duration = t.duration_since(std::time::UNIX_EPOCH).unwrap_or_default();
                    format_timestamp(duration.as_secs())
                })
                .unwrap_or_default();
            let size_kb = meta
                .as_ref()
                .map(|m| m.len() as f64 / 1024.0)
                .unwrap_or(0.0);

            entries.push(LogEntry {
                name: entry.file_name().to_string_lossy().to_string(),
                path: entry.path().to_string_lossy().to_string(),
                modified,
                size_kb: (size_kb * 10.0).round() / 10.0,
            });
        }
    }

    entries.sort_by(|a, b| b.modified.cmp(&a.modified));
    entries
}

/// Formats a Unix timestamp into a `YYYY-MM-DD HH:MM` string.
fn format_timestamp(secs: u64) -> String {
    let days = secs / 86400;
    let remaining = secs % 86400;
    let hours = remaining / 3600;
    let minutes = (remaining % 3600) / 60;

    let is_leap_year =
        |y: u64| y.is_multiple_of(4) && (!y.is_multiple_of(100) || y.is_multiple_of(400));

    // Approximate date calculation (good enough for display)
    let mut year = 1970u64;
    let mut remaining_days = days;
    loop {
        let days_in_year = if is_leap_year(year) { 366 } else { 365 };
        if remaining_days < days_in_year {
            break;
        }
        remaining_days -= days_in_year;
        year += 1;
    }

    let days_in_months: [u64; 12] = if is_leap_year(year) {
        [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    } else {
        [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    };

    let mut month = 1u64;
    for &dim in &days_in_months {
        if remaining_days < dim {
            break;
        }
        remaining_days -= dim;
        month += 1;
    }
    let day = remaining_days + 1;

    format!(
        "{:04}-{:02}-{:02} {:02}:{:02}",
        year, month, day, hours, minutes
    )
}
