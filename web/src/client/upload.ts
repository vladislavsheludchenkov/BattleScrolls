// Landing page for in-game share hand-offs: takes the payload out of the URL
// fragment, posts it to /api/chunk and shows the resulting share link + QR.
//
// The strings here are deliberately NOT the viewer's strings.ts: this page must
// render before any bundle-sized dictionary would be worth loading, and it
// follows the browser/game language with no picker.
import qrcode from "qrcode-generator";
import { privacyLink } from "./privacy-link";
import { iconCredit } from "./icon-credit";

const AUTO_CLOSE_DELAY_SECONDS = 10;

/** Every key the landing copy uses; English lives in the tr() fallbacks below. */
type UploadStringKey =
  | "app_name" | "receiving" | "hold" | "ready" | "parts" | "scan" | "open"
  | "incomplete_t" | "incomplete" | "retry" | "failed_t" | "failed"
  | "part_recv_t" | "part_recv" | "next" | "noserver" | "checknet"
  | "idle" | "idle_hint" | "unlisted" | "save"
  | "missing_t" | "missing" | "resend_hint" | "auto_close" | "close_hint";

/** One language's copy. Gaps fall back to the inline English default. */
type UploadDict = Partial<Record<UploadStringKey, string>>;

/** What /api/chunk answers with (untrusted: every field is optional here). */
interface ChunkResponse {
  error?: string;
  complete?: boolean;
  shareId?: string;
  received?: number;
  total?: number;
  missing?: number[];
}

interface ChunkPayload {
  session: string;
  index: number;
  count: number;
  data: string;
}

/**
 * The last outcome this tab rendered, kept in sessionStorage. The console
 * browser (Edge) puts background tabs to sleep and reloads them on focus;
 * by then the fragment has been stripped, so without this the tab would
 * wake up on the generic idle screen — losing the share link if it was the
 * final tab. Per-tab, survives reloads, gone when the tab closes.
 */
interface PersistedOutcome {
  kind: "complete" | "part" | "missing";
  lang: string;
  url?: string;
  index?: number;
  count?: number;
  overdue?: number[];
  received?: number | string;
  total?: number | string;
}

(function () {
  // Landing strings follow the browser language (no picker on this page)
  const EN: UploadDict = {};
  const L10N: Record<string, UploadDict | undefined> = {
    en: EN,
    de: { app_name: "Battle Scrolls", receiving: "Kampfdaten werden aus dem Spiel empfangen", hold: "Einen Moment…", ready: "Dein Freigabe-Link ist bereit",
      parts: "Alle Teile ({0}) sind angekommen — der Kampf ist über den Link unten abrufbar.", scan: "Scannen, um auf einem anderen Gerät zu öffnen",
      open: "Öffnen", incomplete_t: "Etwas fehlt", incomplete: "Der Übergabe-Link aus dem Spiel ist unvollständig.",
      retry: "Versuche es erneut aus dem Spiel.", failed_t: "Etwas ist schiefgelaufen", failed: "Die Kampfdaten konnten nicht verarbeitet werden.",
      part_recv_t: "Teil erfolgreich empfangen",
      part_recv: "Teil {0} von {1} empfangen.", next: "Kehre ins Spiel zurück und drücke Senden für den nächsten Teil. Sobald alle Teile angekommen sind, zeigt eine Seite wie diese den Link zum Ansehen des Kampfes.",
      auto_close: "Dieser Tab schließt sich in {0} Sekunden automatisch.", close_hint: "Du kannst diesen Tab schließen und ins Spiel zurückkehren.",
      noserver: "Server nicht erreichbar.", checknet: "Prüfe deine Verbindung und sende diesen Teil erneut.",
      idle: "Diese Seite empfängt geteilte Kampfdaten aus der Erweiterung Battle Scrolls.", idle_hint: "Nutze die Teilen-Taste im Journal im Spiel.",
      unlisted: "Freigaben sind ungelistet — nur wer den Link hat, kann sie sehen",
      save: "Scanne den QR-Code oder speichere den Link unten — die Freigabe ist ungelistet, nur über diesen Link erreichbar.",
      missing_t: "Es fehlen Teile", missing: "Teil(e) {0} sind nicht angekommen — {1} von {2} empfangen.",
      resend_hint: "Wähle im Teilen-Bildschirm im Spiel jeden fehlenden Teil aus und drücke Senden, um ihn erneut zu schicken. Diese Seite kann offen bleiben."
      },
    es: { app_name: "Pergaminos de Batalla", receiving: "Recibiendo datos de combate del juego", hold: "Un momento…", ready: "Tu enlace está listo",
      parts: "Han llegado todas las partes ({0}): el combate ya se puede ver en el enlace de abajo.", scan: "Escanea para abrir en otro dispositivo",
      open: "Abrir", incomplete_t: "Falta algo", incomplete: "El enlace enviado desde el juego está incompleto.",
      retry: "Envíalo de nuevo desde el juego.", failed_t: "Algo salió mal", failed: "No se pudieron procesar los datos de combate.",
      part_recv_t: "Parte recibida correctamente",
      part_recv: "Parte {0} de {1} recibida.", next: "Vuelve al juego y pulsa Enviar para la siguiente parte. Cuando lleguen todas las partes, una página como esta mostrará el enlace para ver el combate.",
      auto_close: "Esta pestaña se cerrará automáticamente en {0} segundos.", close_hint: "Puedes cerrar esta pestaña y volver al juego.",
      noserver: "No se pudo contactar el servidor.", checknet: "Comprueba tu conexión y envía esta parte de nuevo.",
      idle: "Esta página recibe combates compartidos desde el complemento Pergaminos de Batalla.", idle_hint: "Usa la tecla de compartir del diario en el juego.",
      unlisted: "Los enlaces no están listados — solo quien tenga el enlace puede verlos",
      save: "Escanea el código QR o guarda el enlace de abajo — el enlace no está listado y es la única forma de abrirlo.",
      missing_t: "Faltan partes", missing: "La(s) parte(s) {0} no llegaron — {1} de {2} recibidas.",
      resend_hint: "En la pantalla de compartir del juego, selecciona cada parte que falta y pulsa Enviar para reenviarla. Esta página puede quedarse abierta."
      },
    fr: { app_name: "Parchemins de Bataille", receiving: "Réception des données de combat depuis le jeu", hold: "Un instant…", ready: "Votre lien de partage est prêt",
      parts: "Toutes les parties ({0}) sont arrivées — le combat est consultable via le lien ci-dessous.", scan: "Scannez pour ouvrir sur un autre appareil",
      open: "Ouvrir", incomplete_t: "Il manque quelque chose", incomplete: "Le lien transmis depuis le jeu est incomplet.",
      retry: "Renvoyez-le depuis le jeu.", failed_t: "Un problème est survenu", failed: "Les données de combat n'ont pas pu être traitées.",
      part_recv_t: "Partie reçue avec succès",
      part_recv: "Partie {0} sur {1} reçue.", next: "Revenez en jeu et appuyez sur Envoyer pour la partie suivante. Quand toutes les parties seront arrivées, une page comme celle-ci affichera le lien pour consulter le combat.",
      auto_close: "Cet onglet se fermera automatiquement dans {0} secondes.", close_hint: "Vous pouvez fermer cet onglet et revenir en jeu.",
      noserver: "Serveur injoignable.", checknet: "Vérifiez votre connexion et renvoyez cette partie.",
      idle: "Cette page reçoit les combats partagés depuis l’extension Parchemins de Bataille.", idle_hint: "Utilisez la touche de partage du journal en jeu.",
      unlisted: "Les partages sont non répertoriés — seuls ceux qui ont le lien peuvent les voir",
      save: "Scannez le code QR ou enregistrez le lien ci-dessous — le partage est non répertorié, ce lien est le seul moyen d'y accéder.",
      missing_t: "Des parties manquent", missing: "La ou les parties {0} ne sont pas arrivées — {1} sur {2} reçues.",
      resend_hint: "Dans l'écran de partage du jeu, sélectionnez chaque partie manquante et appuyez sur Envoyer pour la renvoyer. Cette page peut rester ouverte."
      },
    ja: { app_name: "Battle Scrolls", receiving: "ゲームから戦闘データを受信中", hold: "少々お待ちください…", ready: "共有リンクの準備ができました",
      parts: "全{0}パートを受信しました。下のリンクから戦闘を閲覧できます。", scan: "スキャンして別のデバイスで開く",
      open: "開く", incomplete_t: "何かが足りません", incomplete: "ゲームから渡されたリンクが不完全です。",
      retry: "ゲームからもう一度送信してください。", failed_t: "問題が発生しました", failed: "戦闘データを処理できませんでした。",
      part_recv_t: "パートを正常に受信しました",
      part_recv: "パート{0}/{1}を受信しました。", next: "ゲームに戻り、次のパートを「送信」してください。すべてのパートが届くと、このようなページに戦闘を閲覧するリンクが表示されます。",
      auto_close: "このタブは{0}秒後に自動で閉じます。", close_hint: "このタブを閉じてゲームに戻れます。",
      noserver: "サーバーに接続できません。", checknet: "接続を確認してこのパートを再送してください。",
      idle: "このページはBattle Scrollsアドオンからの戦闘共有を受信します。", idle_hint: "ゲーム内ジャーナルの共有キーを使用してください。",
      unlisted: "共有は非公開です — リンクを知っている人だけが見られます",
      save: "QRコードをスキャンするか、下のリンクを保存してください — 共有は非公開で、このリンクが唯一のアクセス方法です。",
      missing_t: "足りないパートがあります", missing: "パート{0}が届いていません — {1}/{2}を受信済み。",
      resend_hint: "ゲームの共有画面で足りないパートを選択し、「送信」を押して再送してください。このページは開いたままで構いません。"
      },
    ru: { app_name: "Боевые Свитки", receiving: "Принимаем боевые данные из игры", hold: "Секунду…", ready: "Ссылка на ваш бой готова",
      parts: "Получены все части ({0}) — бой можно смотреть по ссылке ниже.", scan: "Отсканируйте, чтобы открыть на другом устройстве",
      open: "Открыть", incomplete_t: "Чего-то не хватает", incomplete: "Переданные из игры данные неполные.",
      retry: "Отправьте их из игры ещё раз.", failed_t: "Что-то пошло не так", failed: "Не удалось обработать боевые данные.",
      part_recv_t: "Часть успешно получена",
      part_recv: "Часть {0} из {1} получена.", next: "Вернитесь в игру и нажмите «Отправить» для следующей части. Когда придут все части, такая же страница покажет ссылку для просмотра боя.",
      auto_close: "Эта вкладка автоматически закроется через {0} секунд.", close_hint: "Можно закрыть эту вкладку и вернуться в игру.",
      noserver: "Сервер недоступен.", checknet: "Проверьте соединение и отправьте эту часть снова.",
      idle: "Эта страница принимает боевые данные из модификации «Боевые Свитки».", idle_hint: "Используйте клавишу «Поделиться» в журнале в игре.",
      unlisted: "Ссылки не публикуются — бой увидят только те, у кого есть ссылка",
      save: "Отсканируйте QR-код или сохраните ссылку ниже — она не публикуется, и открыть бой можно только по ней.",
      missing_t: "Не хватает частей", missing: "Часть(и) {0} не дошли — получено {1} из {2}.",
      resend_hint: "На экране отправки в игре выберите недостающую часть и нажмите «Отправить», чтобы отправить её снова. Эту страницу можно не закрывать."
      },
    zh: { app_name: "Battle Scrolls", receiving: "正在从游戏接收战斗数据", hold: "请稍候…", ready: "你的分享链接已就绪",
      parts: "已收到全部 {0} 个部分——可通过下方链接查看战斗。", scan: "扫码在其他设备上打开",
      open: "打开", incomplete_t: "缺少内容", incomplete: "游戏传来的数据不完整。",
      retry: "请从游戏中重新发送。", failed_t: "出了点问题", failed: "无法处理战斗数据。",
      part_recv_t: "此部分已成功接收",
      part_recv: "已接收第 {0}/{1} 部分。", next: "返回游戏并按“发送”继续下一部分。所有部分送达后，将有这样一个页面显示查看战斗的链接。",
      auto_close: "此标签页将在 {0} 秒后自动关闭。", close_hint: "你可以关闭此标签页并返回游戏。",
      noserver: "无法连接服务器。", checknet: "请检查网络并重新发送此部分。",
      idle: "此页面接收 Battle Scrolls 插件的战斗分享。", idle_hint: "请使用游戏内日志的分享按键。",
      unlisted: "分享不公开 — 只有拥有链接的人才能查看",
      save: "扫描二维码或保存下方链接 — 分享不公开，此链接是唯一的访问方式。",
      missing_t: "缺少部分", missing: "第 {0} 部分未送达 — 已接收 {1}/{2}。",
      resend_hint: "在游戏的分享界面中选中缺失的部分并按“发送”重新发送。此页面可以保持打开。"
      },
  };
  // The game's language rides in the fragment (l=); it beats the browser
  // locale
  const fragParams: Record<string, string | undefined> = {};
  location.hash.slice(1).split("&").forEach(function (kv) {
    const eq = kv.indexOf("=");
    if (eq > 0) fragParams[kv.slice(0, eq)] = kv.slice(eq + 1);
  });

  const OUTCOME_KEY = "bsUploadOutcome";
  function saveOutcome(outcome: PersistedOutcome): void {
    try { sessionStorage.setItem(OUTCOME_KEY, JSON.stringify(outcome)); } catch (e) {}
  }
  function loadOutcome(): PersistedOutcome | null {
    try {
      const raw = sessionStorage.getItem(OUTCOME_KEY);
      return raw ? (JSON.parse(raw) as PersistedOutcome) : null;
    } catch (e) { return null; }
  }
  const restored = location.hash.slice(1) ? null : loadOutcome();

  const GAME_TO_DICT: Record<string, string | undefined> = { jp: "ja" };
  const gameLang = fragParams.l || (restored && restored.lang) || "";
  const lang = GAME_TO_DICT[gameLang] || gameLang || (navigator.language || "en").slice(0, 2);
  const T: UploadDict = L10N[lang] || EN;
  function tr(key: UploadStringKey, fallback: string, ...args: (string | number)[]): string {
    let s = T[key] || fallback;
    for (let i = 0; i < args.length; i++) {
      s = s.split("{" + i + "}").join(String(args[i]));
    }
    return s;
  }
  const appName = tr("app_name", "Battle Scrolls");
  document.title = appName;
  document.getElementById("brand-name")!.textContent = appName;
  document.getElementById("privacy-link")!.innerHTML = privacyLink(lang);
  document.getElementById("icon-credit")!.innerHTML = iconCredit(lang);
  const unlistedSpan = document.querySelector<HTMLElement>("footer > span");
  if (unlistedSpan) unlistedSpan.textContent = tr("unlisted", unlistedSpan.textContent ?? "");
  const titleEl = document.getElementById("title")!;
  const statusEl = document.getElementById("status")!;
  const hintEl = document.getElementById("hint")!;
  const spinner = document.getElementById("spinner")!;

  function show(title: string, message: string, hint: string, isError?: boolean): void {
    titleEl.textContent = title;
    statusEl.textContent = message || "";
    statusEl.className = isError ? "error" : "";
    hintEl.textContent = hint || "";
    spinner.style.display = isError ? "none" : "";
  }

  function scheduleClose(): void {
    const notice = document.getElementById("auto-close")!;
    notice.textContent = tr("auto_close", "This tab will close automatically in {0} seconds.", AUTO_CLOSE_DELAY_SECONDS);
    notice.hidden = false;
    setTimeout(function () {
      // Closing can be refused by the browser; leave useful instructions
      // instead of an expired auto-close notice if the tab stays open.
      notice.textContent = tr("close_hint", "You can close this tab and return to the game.");
      try { window.close(); } catch (e) {}
    }, AUTO_CLOSE_DELAY_SECONDS * 1000);
  }

  function renderComplete(url: string, count: number): void {
    show(tr("ready", "Your share link is ready"),
      tr("parts", "All parts received ({0}) — the fight is ready to view at the link below.", count),
      tr("save", "Scan the QR code or save the link below — the share is unlisted, and this link is the only way to open it."));
    spinner.style.display = "none";
    try {
      const qr = qrcode(0, "M");
      qr.addData(url);
      qr.make();
      const card = document.getElementById("qr")!;
      card.innerHTML = qr.createSvgTag({ cellSize: 5, margin: 0 });
      card.style.display = "block";
      document.getElementById("qr-label")!.style.display = "block";
    } catch (e) {}
    document.getElementById("ready")!.innerHTML =
      '<a class="share-link" href="' + url + '">' + url.replace(/^https?:\/\//, "") + "</a><br>" +
      '<a class="open-btn" href="' + url + '">' + tr("open", "Open") + '</a>';
  }

  function renderPart(index: number, count: number): void {
    show(tr("part_recv_t", "Part received successfully"),
      tr("part_recv", "Part {0} of {1} received.", index, count),
      tr("next", "Return to the game and press Send for the next part. Once every part arrives, a page like this one will show the link to view the fight."));
    spinner.style.display = "none";
    // Schedule here so tabs restored without a fragment close too.
    scheduleClose();
  }

  function renderMissing(overdue: number[], received: number | string, total: number | string): void {
    show(tr("missing_t", "Some parts are missing"),
      tr("missing", "Part(s) {0} never arrived — {1} of {2} received.",
        overdue.join(", "), received, total),
      tr("resend_hint", "In the game's sharing screen, select each missing part and press Send to resend it. This page can stay open."), true);
  }

  titleEl.textContent = tr("receiving", "Receiving combat data from the game");
  statusEl.textContent = tr("hold", "Hold tight…");
  document.getElementById("qr-label")!.textContent = tr("scan", "Scan to open on another device");

  const hash = location.hash.slice(1);
  if (!hash) {
    // No payload: either a cold visit, or the console browser put this tab
    // to sleep and reloaded it after the fragment was stripped. Re-render
    // the tab's last outcome so a sleeping final tab keeps its share link.
    if (restored) {
      if (restored.kind === "complete" && restored.url) {
        renderComplete(restored.url, restored.count ?? 0);
      } else if (restored.kind === "missing") {
        renderMissing(restored.overdue || [], restored.received ?? "?", restored.total ?? "?");
      } else {
        renderPart(restored.index ?? 0, restored.count ?? 0);
      }
      return;
    }
    show(appName, tr("idle", "This page receives combat shares from the Battle Scrolls add-on."),
      tr("idle_hint", "Use the Share keybind in the in-game journal to send one here."));
    spinner.style.display = "none";
    scheduleClose();
    return;
  }

  const params = fragParams;

  const payload: ChunkPayload = {
    session: params.s || "",
    index: parseInt(params.i || "1", 10),
    count: parseInt(params.n || "1", 10),
    data: params.d || "",
  };
  if (!payload.data) {
    show(tr("incomplete_t", "Something is missing"), tr("incomplete", "The hand-off link from the game is incomplete."), tr("retry", "Try sending it again from the game."), true);
    return;
  }

  // Strip the data from the address bar immediately: the payload has done its
  // job, and console browsers keep URL history.
  try { history.replaceState(null, "", location.pathname); } catch (e) {}

  fetch("/api/chunk", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(payload),
  }).then(function (res) { return res.json(); }).then(function (result: ChunkResponse) {
    if (result.error) {
      show(tr("failed_t", "Something went wrong"), tr("failed", "The combat data could not be processed."), result.error, true);
    } else if (result.complete) {
      const url = location.origin + "/s/" + result.shareId
        + (gameLang ? "?l=" + encodeURIComponent(gameLang) : "");
      saveOutcome({ kind: "complete", lang: gameLang, url: url, count: payload.count });
      renderComplete(url, payload.count);
    } else {
      // Parts numbered below the one that just arrived should already be
      // here; their absence means a hand-off died (a crashed browser tab
      // never posts its chunk). Later missing parts are just the normal
      // not-sent-yet tail and stay silent.
      const missing = result.missing || [];
      const overdue = missing.filter(function (i) { return i < payload.index; });
      if (overdue.length) {
        saveOutcome({ kind: "missing", lang: gameLang, overdue: overdue,
          received: result.received ?? "?", total: result.total ?? payload.count });
        renderMissing(overdue, result.received ?? "?", result.total ?? payload.count);
      } else {
        saveOutcome({ kind: "part", lang: gameLang, index: payload.index, count: payload.count });
        renderPart(payload.index, payload.count);
      }
    }
  }).catch(function () {
    show(tr("receiving", "Receiving combat data from the game"), tr("noserver", "Could not reach the server."),
      tr("checknet", "Check your connection and send this part again."), true);
  });
})();
