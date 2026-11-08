// src/lib/types.ts

/** System info payload from the Rust backend. */
export interface SystemInfo {
  cpu_usage: number;
  cpu_name: string;
  cpu_cores: number;
  memory_total_gb: number;
  memory_used_gb: number;
  memory_percent: number;
  disks: DiskInfo[];
  hostname: string;
  os_version: string;
  uptime_hours: number;
}

export interface DiskInfo {
  name: string;
  mount: string;
  total_gb: number;
  used_gb: number;
  percent: number;
}

export interface DnsConfig {
  adapters: AdapterDns[];
  safesearch_google: boolean;
  safesearch_bing: boolean;
  smartscreen_enabled: boolean;
  hosts_blocked_count: number;
}

export interface AdapterDns {
  name: string;
  dns_servers: string[];
}

export interface ThemeStatus {
  dark_mode: boolean;
  accent_color: string;
  window_colorization: boolean;
  verbose_boot: boolean;
  cursor_type: number;
  search_hidden: boolean;
  copilot_hidden: boolean;
  task_view_hidden: boolean;
  widgets_hidden: boolean;
  game_bar_off: boolean;
  oem_manufacturer: string;
  oem_model: string;
}

export interface AudioInfo {
  devices: AudioDevice[];
  vst2_count: number;
  vst3_count: number;
  audio_service_running: boolean;
}

export interface AudioDevice {
  name: string;
  device_type: string;
  status: string;
}

export interface ScheduledTask {
  name: string;
  status: string;
  next_run: string;
  last_run: string;
}

export interface LogEntry {
  name: string;
  path: string;
  modified: string;
  size_kb: number;
}

/** Extended hardware health data. */
export interface HardwareHealth {
  battery: BatteryInfo | null;
  gpu: GpuInfo[];
  network_adapters: NetworkAdapterInfo[];
  wifi: WifiInfo | null;
  bluetooth: BluetoothInfo | null;
  disk_health: DiskHealthInfo[];
  bios: BiosInfo;
}

/** Battery health and charge status. */
export interface BatteryInfo {
  design_capacity_mwh: number;
  full_charge_capacity_mwh: number;
  current_charge_percent: number;
  health_percent: number;
  cycle_count: number;
  status: string;
}

/** GPU information. */
export interface GpuInfo {
  name: string;
  driver_version: string;
  vram_gb: number;
  status: string;
}

/** Network adapter info. */
export interface NetworkAdapterInfo {
  name: string;
  adapter_type: string;
  mac_address: string;
  ip_address: string;
  link_speed: string;
  status: string;
}

/** WiFi connection details. */
export interface WifiInfo {
  ssid: string;
  signal_percent: number;
  link_speed: string;
  auth_type: string;
}

/** Bluetooth adapter status. */
export interface BluetoothInfo {
  adapter_name: string;
  status: string;
  connected_devices: string[];
}

/** Physical disk health. */
export interface DiskHealthInfo {
  model: string;
  media_type: string;
  status: string;
  temperature_c: number | null;
  size_gb: number;
}

/** BIOS information. */
export interface BiosInfo {
  version: string;
  manufacturer: string;
  release_date: string;
}

/** Output line from a running script. */
export interface ScriptOutput {
  stream: "stdout" | "stderr";
  line: string;
}
