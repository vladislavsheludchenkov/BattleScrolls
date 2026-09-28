/** A recipe keeps script order: Focus, Signature, Affix. Class 0 is shared. */
export interface ScribedRecipe {
  craftedAbilityId: number;
  scriptIds: [number, number, number];
  classId: number;
}

export interface ScribedAbility {
  name: string;
  icon?: string;
  tooltip?: string;
}

export function scribingKey(recipe: ScribedRecipe): string {
  return [recipe.craftedAbilityId, ...recipe.scriptIds, recipe.classId].join(":");
}

export function isScribedRecipe(value: unknown): value is ScribedRecipe {
  if (!value || typeof value !== "object") return false;
  const r = value as Partial<ScribedRecipe>;
  const id = (v: unknown): v is number => typeof v === "number" && Number.isSafeInteger(v) && v > 0 && v <= 1_000_000;
  return id(r.craftedAbilityId) && Array.isArray(r.scriptIds) && r.scriptIds.length === 3
    // Class IDs are not consecutive: Arcanist is 117. The build wire uses 8 bits.
    && r.scriptIds.every(id) && Number.isInteger(r.classId) && r.classId! >= 0 && r.classId! <= 255;
}
