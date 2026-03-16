import { clsx } from "clsx";

type BadgeVariant = "idle" | "pending" | "allocated" | "stale" | "active";

const variantMap: Record<BadgeVariant, string> = {
  idle:      "bg-gray-700 text-gray-300",
  pending:   "bg-yellow-500/20 text-yellow-300 animate-pulse",
  allocated: "bg-green-500/20 text-green-300",
  stale:     "bg-red-500/20 text-red-300",
  active:    "bg-purple-500/20 text-purple-300",
};

const VAULT_STATE_LABELS: Record<number, { label: string; variant: BadgeVariant }> = {
  0: { label: "Idle",             variant: "idle"      },
  1: { label: "Outbound Pending", variant: "pending"   },
  2: { label: "Allocated",        variant: "allocated" },
};

export function VaultStateBadge({ state }: { state: number }) {
  const { label, variant } = VAULT_STATE_LABELS[state] ?? { label: "Unknown", variant: "idle" };
  return (
    <span className={clsx("text-xs font-medium px-2.5 py-1 rounded-full", variantMap[variant])}>
      {label}
    </span>
  );
}

export function Badge({ label, variant }: { label: string; variant: BadgeVariant }) {
  return (
    <span className={clsx("text-xs font-medium px-2.5 py-1 rounded-full", variantMap[variant])}>
      {label}
    </span>
  );
}
