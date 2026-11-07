// src/components/PageHeader.tsx
import type { LucideIcon } from "lucide-react";

interface PageHeaderProps {
  /** Page title. */
  title: string;
  /** Brief description of the page. */
  description: string;
  /** Lucide icon for the header. */
  icon?: LucideIcon;
}

/**
 * Consistent header for each feature page with neon accent styling.
 *
 * @param props - Page header configuration.
 * @returns A page header component with neon underline and icon glow.
 */
export function PageHeader({ title, description, icon: Icon }: PageHeaderProps) {
  return (
    <div className="mb-9">
      <div className="flex items-center gap-3">
        {Icon ? (
          <Icon
            size={24}
            className="text-matrix-cyan"
            style={{ filter: "drop-shadow(0 0 6px rgba(0, 255, 255, 0.6))" }}
          />
        ) : null}
        <h2
          className="text-xl font-bold text-matrix-white"
          style={{ textShadow: "0 0 6px rgba(0, 255, 255, 0.3)" }}
        >
          {title}
        </h2>
      </div>
      <div className="mt-3 h-[2px] w-16 bg-gradient-to-r from-matrix-cyan to-transparent" />
      <p className="mt-4 text-sm text-matrix-text-dim">{description}</p>
    </div>
  );
}
