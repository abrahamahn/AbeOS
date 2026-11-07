// src-tauri/src/lib.rs
mod commands;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .invoke_handler(tauri::generate_handler![
            commands::system::get_system_info,
            commands::system::get_power_mode,
            commands::scripts::discover_scripts,
            commands::scripts::get_script_content,
            commands::security::get_dns_config,
            commands::theme::get_theme_status,
            commands::audio::get_audio_info,
            commands::maintenance::get_scheduled_tasks,
            commands::maintenance::get_log_entries,
            commands::hardware::get_hardware_health,
        ])
        .run(tauri::generate_context!())
        .expect("error while running AbeOS Control Center");
}
