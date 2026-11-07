// src/lib/constants.ts

/** AbeOS filesystem paths used throughout the app. */
export const ABEOS_ROOT = "C:\\AbeOS";
export const ABEOS_CONFIGS = `${ABEOS_ROOT}\\configs`;
export const ABEOS_MODULES = `${ABEOS_ROOT}\\modules`;
export const ABEOS_SCRIPTS = `${ABEOS_ROOT}\\scripts`;
export const ABEOS_LOGS = `${ABEOS_ROOT}\\logs`;

/** Script paths for control-center actions. */
export const SCRIPTS = {
  healthReport: `${ABEOS_MODULES}\\automation\\Health-Report.ps1`,
  dailyMaintenance: `${ABEOS_MODULES}\\automation\\Daily-Maintenance.ps1`,
  resetAudio: `${ABEOS_MODULES}\\security\\Reset-Audio.ps1`,
  applyTheme: `${ABEOS_MODULES}\\theme\\Apply-AbeOS-Theme.ps1`,
  monitorDns: `${ABEOS_MODULES}\\security\\Monitor-SafeDNS.ps1`,
  setSafeDns: `${ABEOS_SCRIPTS}\\security\\Set-SafeDNS.ps1`,
  systemAudit: `${ABEOS_SCRIPTS}\\audit\\SystemDeepAudit.ps1`,
  registryAudit: `${ABEOS_SCRIPTS}\\audit\\RegistryDeepAudit.ps1`,
  pluginAudit: `${ABEOS_SCRIPTS}\\audit\\PluginsDeepAudit.ps1`,
  setPowerPlan: `${ABEOS_SCRIPTS}\\power-plan\\Set-PowerPlan.ps1`,
  installDevEnv: `${ABEOS_SCRIPTS}\\dev-env\\Install-DevEnvironment.ps1`,
  backupDevSettings: `${ABEOS_SCRIPTS}\\dev-env\\Backup-DevSettings.ps1`,
} as const;

/** Navigation items for the sidebar. */
export const NAV_ITEMS = [
  { path: "/", label: "Dashboard", icon: "LayoutDashboard" },
  { path: "/system", label: "System", icon: "Cpu" },
  { path: "/security", label: "Security", icon: "Shield" },
  { path: "/theme", label: "Theme", icon: "Palette" },
  { path: "/dev", label: "Dev", icon: "Code" },
  { path: "/audio", label: "Audio", icon: "Music" },
  { path: "/maintenance", label: "Maintenance", icon: "Wrench" },
] as const;
