// src/features/security/SecurityPage.tsx
import { useState, useEffect } from "react";
import { Shield, CheckCircle, XCircle, Play } from "lucide-react";
import { PageHeader } from "../../components/PageHeader.tsx";
import { TerminalOutput } from "../../components/TerminalOutput.tsx";
import { api } from "../../lib/tauri.ts";
import type { DnsConfig } from "../../lib/types.ts";
import { useScript } from "../../hooks/useScript.ts";
import { SCRIPTS } from "../../lib/constants.ts";

const DNS_GAMING = [
  { provider: "Cloudflare", label: "Cloudflare", ips: "1.1.1.1 / 1.0.0.1" },
  { provider: "Google", label: "Google", ips: "8.8.8.8 / 8.8.4.4" },
] as const;

const DNS_SAFE = [
  {
    provider: "CloudflareFamily",
    label: "Cloudflare Family",
    ips: "1.1.1.3 / 1.0.0.3",
  },
  {
    provider: "OpenDNS",
    label: "OpenDNS FamilyShield",
    ips: "208.67.222.123 / 208.67.220.123",
  },
  {
    provider: "CleanBrowsing",
    label: "CleanBrowsing",
    ips: "185.228.168.168 / 185.228.169.168",
  },
  { provider: "Quad9", label: "Quad9", ips: "9.9.9.9 / 149.112.112.112" },
] as const;

/**
 * Security page: DNS configuration, content filtering, and safety settings.
 */
export function SecurityPage() {
  const [config, setConfig] = useState<DnsConfig | null>(null);
  const { output, running, execute, clear } = useScript();

  useEffect(() => {
    api.getDnsConfig().then(setConfig).catch(() => {});
  }, []);

  const handleSetDns = (provider: string) => {
    clear();
    void execute(SCRIPTS.setSafeDns, ["-Provider", provider]).then(() => {
      api.getDnsConfig().then(setConfig).catch(() => {});
    });
  };

  return (
    <div>
      <PageHeader
        title="Security"
        description="DNS filtering, SafeSearch, content blocking, and SmartScreen"
        icon={Shield}
      />

      {/* Status Grid */}
      <div className="mb-8 grid grid-cols-4 gap-3">
        <StatusBadge
          label="SafeSearch (Google)"
          active={config?.safesearch_google ?? false}
        />
        <StatusBadge
          label="SafeSearch (Bing)"
          active={config?.safesearch_bing ?? false}
        />
        <StatusBadge
          label="SmartScreen"
          active={config?.smartscreen_enabled ?? false}
        />
        <div className="rounded border border-matrix-border bg-matrix-surface p-4">
          <span className="text-xs text-matrix-text-dim">Hosts Blocked</span>
          <p className="mt-1 text-xl font-bold text-matrix-cyan">
            {config?.hosts_blocked_count ?? "--"}
          </p>
        </div>
      </div>

      {/* DNS Adapters */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          DNS Configuration
        </h3>
        <div className="space-y-2">
          {config?.adapters.map((adapter, i) => (
            <div
              key={i}
              className="flex items-center justify-between rounded border border-matrix-border bg-matrix-surface px-4 py-3"
            >
              <span className="text-sm text-matrix-text">{adapter.name}</span>
              <span className="text-xs text-matrix-cyan">
                {adapter.dns_servers.join(", ")}
              </span>
            </div>
          )) ?? (
            <p className="text-xs text-matrix-text-dim">Loading...</p>
          )}
        </div>
      </div>

      {/* DNS Provider Quick Switch */}
      <div className="mb-8">
        <h3 className="mb-3 text-sm font-semibold text-matrix-text-dim">
          Switch DNS Provider
        </h3>

        {/* Gaming - Lowest Latency */}
        <p className="mb-2 text-xs font-medium text-matrix-cyan">
          Gaming — Lowest Latency
        </p>
        <div className="mb-3 grid grid-cols-2 gap-3">
          {DNS_GAMING.map((dns) => (
            <button
              key={dns.provider}
              onClick={() => handleSetDns(dns.provider)}
              disabled={running}
              className="rounded border border-matrix-border bg-matrix-surface px-4 py-3 text-left transition-colors hover:border-matrix-cyan disabled:opacity-50"
            >
              <span className="text-sm font-semibold text-matrix-text">
                {dns.label}
              </span>
              <p className="mt-1 text-xs text-matrix-text-dim">{dns.ips}</p>
            </button>
          ))}
        </div>

        {/* Safe - Content Filtering */}
        <p className="mb-2 text-xs font-medium text-matrix-green">
          Safe — Content Filtering
        </p>
        <div className="grid grid-cols-2 gap-3">
          {DNS_SAFE.map((dns) => (
            <button
              key={dns.provider}
              onClick={() => handleSetDns(dns.provider)}
              disabled={running}
              className="rounded border border-matrix-border bg-matrix-surface px-4 py-3 text-left transition-colors hover:border-matrix-green disabled:opacity-50"
            >
              <span className="text-sm font-semibold text-matrix-text">
                {dns.label}
              </span>
              <p className="mt-1 text-xs text-matrix-text-dim">{dns.ips}</p>
            </button>
          ))}
        </div>
      </div>

      {/* Run DNS Monitor */}
      <div className="mb-8">
        <button
          onClick={() => {
            clear();
            void execute(SCRIPTS.monitorDns);
          }}
          disabled={running}
          className="flex items-center gap-2 rounded border border-matrix-border bg-matrix-surface px-4 py-2.5 text-sm text-matrix-text transition-colors hover:border-matrix-cyan hover:text-matrix-cyan disabled:opacity-50"
        >
          <Play size={14} />
          Check DNS Monitor
        </button>
      </div>

      {output.length > 0 ? (
        <TerminalOutput lines={output} running={running} maxHeight={200} />
      ) : null}
    </div>
  );
}

function StatusBadge({
  label,
  active,
}: {
  label: string;
  active: boolean;
}) {
  return (
    <div className="rounded border border-matrix-border bg-matrix-surface p-4">
      <span className="text-xs text-matrix-text-dim">{label}</span>
      <div className="mt-1 flex items-center gap-2">
        {active ? (
          <CheckCircle size={16} className="text-matrix-green" />
        ) : (
          <XCircle size={16} className="text-matrix-red" />
        )}
        <span
          className={`text-sm font-semibold ${active ? "text-matrix-green" : "text-matrix-red"}`}
        >
          {active ? "Enabled" : "Disabled"}
        </span>
      </div>
    </div>
  );
}
