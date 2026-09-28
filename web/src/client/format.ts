// Formatting helpers ported from the journal's own conventions
// (BattleScrolls/ui/journal/utils.lua) so a number reads the same here as it
// does in game: same abbreviation thresholds, same decimals, same rounding
// direction. Where they used to differ the web read 4532 as "4532" and a
// 90.7s fight as "1:31" against the game's "4.5K" and "1:30".
import { currentLocale } from "./strings";

/**
 * utils.formatCompact: abbreviate from 1000 with one decimal, otherwise print
 * whole numbers bare and fractions to 1-2 places. The B tier is a web-only
 * extension - the addon stops at M, which no single encounter reaches, but
 * cross-encounter totals can.
 */
export function fmtNumber(n: number): string {
  n = n || 0;
  const abs = Math.abs(n);
  if (abs >= 1e9) return (n / 1e9).toFixed(1) + "B";
  if (abs >= 1e6) return (n / 1e6).toFixed(1) + "M";
  if (abs >= 1000) return (n / 1000).toFixed(1) + "K";
  if (Math.abs(n % 1) < 0.005) return n.toFixed(0);
  if (abs >= 1) return n.toFixed(1);
  return n.toFixed(2);
}

/**
 * utils.formatDPS: abbreviated from 1000, then progressively more precise as
 * the rate approaches zero. Also the right formatter for HPS and DTPS - the
 * group table runs all three through formatCompact/formatDPS the same way.
 */
export function fmtRate(rate: number): string {
  rate = rate || 0;
  if (rate >= 1000) return fmtNumber(rate);
  if (rate >= 10) return rate.toFixed(0);
  if (rate >= 1) return rate.toFixed(1);
  return rate.toFixed(2);
}

/** utils.formatNumber: ZO_CommaDelimitNumber(math.floor(n)) - floors, not rounds. */
export function fmtExact(n: number): string {
  return Math.floor(n || 0).toLocaleString(currentLocale());
}

export function fmtPercent(fraction: number, digits = 1): string {
  return ((fraction || 0) * 100).toFixed(digits) + "%";
}

/** utils.formatDuration: whole seconds, floored. */
export function fmtDuration(ms: number): string {
  const s = Math.floor((ms || 0) / 1000);
  const m = Math.floor(s / 60);
  return `${m}:${String(s % 60).padStart(2, "0")}`;
}

/** Date only, no time ("Aug 2, 2026"). */
export function fmtDay(timestampS: number | undefined): string {
  if (!timestampS) return "";
  return new Date(timestampS * 1000).toLocaleDateString(currentLocale(), { dateStyle: "medium" });
}

/** Time of day only ("7:41 PM"). */
export function fmtTime(timestampS: number | undefined): string {
  if (!timestampS) return "";
  return new Date(timestampS * 1000).toLocaleTimeString(currentLocale(), { timeStyle: "short" });
}

export function fmtDps(total: number, durationMs: number): string {
  const s = (durationMs || 0) / 1000;
  return s > 0 ? fmtRate(total / s) : "—";
}

/** Strips ESO grammar suffixes ("Canonreeve Oraneth^F" -> base name). */
export function cleanName(name: string | null | undefined): string {
  const s = String(name ?? "");
  const caret = s.indexOf("^");
  return caret > 0 ? s.slice(0, caret) : s;
}

/** The five characters the regex below matches; the fallback is unreachable. */
const HTML_ESCAPES: Record<string, string> = {
  "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
};

export function escapeHtml(s: string | number | null | undefined): string {
  return String(s ?? "").replace(/[&<>"']/g, (c) => HTML_ESCAPES[c] ?? c);
}

/** CSV syntax escaping and spreadsheet formula protection for untrusted text. */
export function csvCell(v: string | number): string {
  const s = String(v ?? "");
  // A tab inside the quoted field keeps formulas inert in Excel, including
  // after saving and reopening. Preserve numeric values (including negatives).
  // Also catch formula prefixes after whitespace/control characters and their
  // full-width forms used in some locales. JSON exports retain the raw text.
  const formula = typeof v === "string"
    && /^(?:[\s\u0000-\u001f]*[=+\-@＝＋－＠]|[\t\r\n])/u.test(s);
  const text = formula ? "\t" + s : s;
  return formula || /[",\r\n]/.test(text) ? '"' + text.replace(/"/g, '""') + '"' : text;
}

export function downloadFile(filename: string, mime: string, content: BlobPart): void {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 5000);
}
