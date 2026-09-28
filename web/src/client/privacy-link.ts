const labels: Record<string, string> = {
  en: "Privacy policy", de: "Datenschutzerklärung", es: "Política de privacidad",
  fr: "Politique de confidentialité", jp: "プライバシーポリシー", ru: "Политика конфиденциальности", zh: "隐私政策",
};

export function privacyLanguage(language: string): string {
  const code = language.toLowerCase().split("-")[0] ?? "en";
  return code === "ja" ? "jp" : Object.prototype.hasOwnProperty.call(labels, code) ? code : "en";
}

export function privacyLabel(language: string): string {
  return labels[privacyLanguage(language)]!;
}

export function privacyLink(language: string): string {
  return `<a href="/privacy?l=${privacyLanguage(language)}" target="_blank" rel="noopener">${privacyLabel(language)}</a>`;
}
