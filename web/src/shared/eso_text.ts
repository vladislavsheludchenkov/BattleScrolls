// ESO's link payload is metadata, never HTML or a URL to navigate to.
const LINK = /\|H\d+:([^|]+)\|h([^|]*)\|h/g;

export function linkedItemIds(text: string): number[] {
  return [...new Set([...text.matchAll(LINK)].flatMap((match) => {
    const [kind, rawId] = match[1]!.split(":");
    const id = Number(rawId);
    return kind === "item" && Number.isInteger(id) && id > 0 ? [id] : [];
  }))];
}

export function plainEsoText(text: string, itemNames: Readonly<Record<number, string>> = {}): string {
  return text.replace(LINK, (_match, payload: string, label: string) => {
    const [kind, id] = payload.split(":");
    return label || (kind === "item" ? itemNames[Number(id)] : undefined) || `#${id}`;
  }).replace(/\|c[\da-f]{6}|\|r/gi, "");
}
