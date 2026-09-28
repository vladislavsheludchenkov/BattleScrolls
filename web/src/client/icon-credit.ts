import { privacyLanguage } from "./privacy-link";

const labels: Record<string, string> = {
  en: "ESO icons sourced from {0}",
  de: "ESO-Symbole stammen von {0}",
  es: "Iconos de ESO obtenidos de {0}",
  fr: "Icônes d’ESO provenant de {0}",
  jp: "ESOアイコンの出典：{0}",
  ru: "Источник значков ESO — {0}",
  zh: "ESO 图标来源：{0}",
};

export function iconCredit(language: string): string {
  const link = '<a href="https://en.uesp.net/wiki/Online:Online" target="_blank" rel="noopener noreferrer">UESP</a>';
  return `<span>${labels[privacyLanguage(language)]!.replace("{0}", link)}</span>`;
}
