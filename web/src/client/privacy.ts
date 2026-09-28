import { PRIVACY_COPY, PRIVACY_EMAIL, PRIVACY_OPERATOR, PRIVACY_UPDATED } from "./privacy-copy";
import { privacyLabel, privacyLanguage } from "./privacy-link";
import { iconCredit } from "./icon-credit";

const requestedLanguage = new URLSearchParams(location.search).get("l") ?? navigator.language;
const language = privacyLanguage(requestedLanguage);
const copy = PRIVACY_COPY[language]!;
const title = privacyLabel(language);
document.documentElement.lang = language === "jp" ? "ja" : language;
document.title = `${title} · Battle Scrolls`;
document.getElementById("title")!.textContent = title;
document.getElementById("icon-credit")!.innerHTML = iconCredit(language);
document.getElementById("updated")!.textContent = `${copy.updated}: ${PRIVACY_UPDATED}`;
document.getElementById("operator-label")!.textContent = copy.contact;
document.getElementById("operator")!.textContent = `${PRIVACY_OPERATOR} · ${copy.location}`;
const contact = document.getElementById("contact") as HTMLAnchorElement;
contact.href = `mailto:${PRIVACY_EMAIL}`;
contact.textContent = PRIVACY_EMAIL;

const picker = document.getElementById("language") as HTMLSelectElement;
picker.value = language;
picker.addEventListener("change", () => { location.search = `?l=${privacyLanguage(picker.value)}`; });

const content = document.getElementById("content")!;
for (const { heading, body } of copy.sections) {
  const section = document.createElement("section");
  const h2 = document.createElement("h2");
  const p = document.createElement("p");
  h2.textContent = heading;
  for (const part of body) {
    if (typeof part === "string") {
      p.append(part);
    } else {
      const link = document.createElement("a");
      link.href = part.url;
      link.textContent = part.label;
      link.referrerPolicy = "no-referrer";
      p.append(link);
    }
  }
  section.append(h2, p);
  content.append(section);
}
