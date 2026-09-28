// Hash router for the share viewer.
//
// The share id lives in the path (/s/:id) and is owned by the worker; the
// view state lives in the hash so refresh/back/forward/deep links restore it
// without any server involvement (the worker's /s/ regex never sees the hash).
//
// Grammar:
//   #/                       list view (encounter list)
//   #/{idx}                  nav menu for encounter {idx} (0-based wire index)
//   #/{idx}/{group}          tab view, group's remembered/default sub-tab
//   #/{idx}/{group}/{sub}    tab view, explicit sub-tab
//
// The router is deliberately dumb: it parses and formats routes but does not
// know which groups/subs exist. The app validates ids against NAV_GROUPS and
// re-navigates (replace) if the route is stale or malformed.

export interface RouteState {
    view: "list" | "menu" | "enc";
    /** Index into wire.encounters; meaningless for view "list". */
    encounterIdx: number;
    /** Nav group id for view "enc"; null otherwise. */
    groupId: string | null;
    /** Sub-tab id, only meaningful with a groupId; null = group default. */
    subId: string | null;
}

const LIST_ROUTE: RouteState = { view: "list", encounterIdx: 0, groupId: null, subId: null };

const ID_RE = /^[a-z0-9-]+$/;

export function parseRoute(hash: string): RouteState {
    // "#/3/damage/damage-taken" -> ["3", "damage", "damage-taken"]
    const parts = hash.replace(/^#\/?/, "").split("/").filter((p) => p !== "");
    const first = parts[0];
    if (first === undefined) return { ...LIST_ROUTE };
    const idx = /^\d+$/.test(first) ? parseInt(first, 10) : NaN;
    if (!Number.isFinite(idx)) return { ...LIST_ROUTE };
    const group = parts[1];
    if (group === undefined || !ID_RE.test(group)) {
        return { view: "menu", encounterIdx: idx, groupId: null, subId: null };
    }
    const sub = parts[2];
    return {
        view: "enc",
        encounterIdx: idx,
        groupId: group,
        subId: sub !== undefined && ID_RE.test(sub) ? sub : null,
    };
}

export function buildRoute(state: RouteState): string {
    if (state.view === "list") return "#/";
    if (state.view === "menu" || state.groupId === null) return `#/${state.encounterIdx}`;
    if (state.subId === null) return `#/${state.encounterIdx}/${state.groupId}`;
    return `#/${state.encounterIdx}/${state.groupId}/${state.subId}`;
}

/**
 * Navigate by mutating location.hash; the hashchange listener is the single
 * render path (covers back/forward, manual edits, and programmatic nav).
 * If the route is already current this is a no-op (no hashchange fires).
 * replace=true rewrites the current history entry instead of pushing —
 * used for normalizing invalid/stale routes so Back still works.
 */
export function navigate(state: RouteState, opts?: { replace?: boolean }): void {
    const target = buildRoute(state);
    if (currentHash() === target) return;
    if (opts?.replace) {
        const url = new URL(location.href);
        url.hash = target;
        location.replace(url.href);
    } else {
        location.hash = target;
    }
}

/** Current hash normalized so "" and "#" both mean the list route. */
export function currentHash(): string {
    const h = location.hash;
    return h === "" || h === "#" ? "#/" : h;
}

export function currentRoute(): RouteState {
    return parseRoute(currentHash());
}

/**
 * Subscribe to route changes. The handler also fires once immediately with
 * the current route (initial render), matching hashchange semantics after.
 */
export function onRouteChange(handler: (route: RouteState) => void): void {
    window.addEventListener("hashchange", () => handler(currentRoute()));
    handler(currentRoute());
}
