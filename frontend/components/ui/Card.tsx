import { clsx } from "clsx";

interface CardProps {
  title: string;
  children: React.ReactNode;
  className?: string;
  accent?: "purple" | "green" | "blue" | "orange";
}

const accentMap = {
  purple: "border-purple-500/30 bg-purple-500/5",
  green:  "border-green-500/30 bg-green-500/5",
  blue:   "border-blue-500/30 bg-blue-500/5",
  orange: "border-orange-500/30 bg-orange-500/5",
};

export function Card({ title, children, className, accent = "purple" }: CardProps) {
  return (
    <div className={clsx(
      "rounded-xl border p-5 backdrop-blur-sm",
      accentMap[accent],
      className
    )}>
      <h2 className="text-xs font-semibold uppercase tracking-widest text-gray-400 mb-4">
        {title}
      </h2>
      {children}
    </div>
  );
}
