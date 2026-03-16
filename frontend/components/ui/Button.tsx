import { clsx } from "clsx";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "danger";
  loading?: boolean;
}

const variantMap = {
  primary:   "bg-purple-600 hover:bg-purple-500 text-white",
  secondary: "bg-gray-700 hover:bg-gray-600 text-gray-100",
  danger:    "bg-red-700 hover:bg-red-600 text-white",
};

export function Button({ variant = "primary", loading, children, className, disabled, ...props }: ButtonProps) {
  return (
    <button
      className={clsx(
        "px-4 py-2 rounded-lg text-sm font-medium transition-colors",
        "disabled:opacity-50 disabled:cursor-not-allowed",
        variantMap[variant],
        className
      )}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? (
        <span className="flex items-center gap-2">
          <span className="w-3 h-3 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          Processing...
        </span>
      ) : children}
    </button>
  );
}
