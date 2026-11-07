// src/App.tsx
import { Routes, Route } from "react-router-dom";
import { Layout } from "./components/Layout.tsx";
import { Dashboard } from "./features/dashboard/Dashboard.tsx";
import { SystemPage } from "./features/system/SystemPage.tsx";
import { SecurityPage } from "./features/security/SecurityPage.tsx";
import { ThemePage } from "./features/theme/ThemePage.tsx";
import { DevPage } from "./features/dev/DevPage.tsx";
import { AudioPage } from "./features/audio/AudioPage.tsx";
import { MaintenancePage } from "./features/maintenance/MaintenancePage.tsx";

export function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/system" element={<SystemPage />} />
        <Route path="/security" element={<SecurityPage />} />
        <Route path="/theme" element={<ThemePage />} />
        <Route path="/dev" element={<DevPage />} />
        <Route path="/audio" element={<AudioPage />} />
        <Route path="/maintenance" element={<MaintenancePage />} />
      </Routes>
    </Layout>
  );
}
