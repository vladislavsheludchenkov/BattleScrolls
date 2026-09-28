# Battle Scrolls

Combat reports for The Elder Scrolls Online, built around the gamepad UI on Xbox and PlayStation. Watch your damage and healing during a fight, then open the Journal to see what happened. With v6, you can also open a fight or a whole run in your browser and share its link.

## Get started

Install **Battle Scrolls** through ESO's in-game add-on browser. The required libraries are **LibGroupBroadcast** and **LibAsync**.

Open **Journal → Battle Scrolls** to complete the initial setup and enable recording. Return there to browse your recorded visits and encounters, or change recording, storage, effect tracking, and meter settings.

Development and in-game testing happen on PC with gamepad mode enabled. See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions.

## What you can see

- **Live meters:** personal and group DPS/HPS, with several designs, positioning and scale controls, and a custom color for your Bars meter.
- **Damage and healing:** breakdowns by ability and target or source, boss damage, critical hits, damage over time, raw and effective healing, and overheal.
- **Effects:** buff and debuff uptimes on yourself, group members, and bosses.
- **Builds and group reports:** recorded equipment and abilities, plus combat summaries and builds exchanged with other Battle Scrolls users through LibGroupBroadcast.
- **Activity:** light attack weaving, cast delays and downtime, Ultimate generation and spending, Arcanist Crux usage, Z'en DoT stacking, and resurrections.
- **Aggregate:** compare and summarize multiple recorded encounters using your chosen dimensions and metrics.

The **Group Damage** tab includes damage your client observes from other players, even if they do not use Battle Scrolls. ESO does not identify those sources individually, so that damage appears in a single **Others** pool. Named group reports rely on data shared by other Battle Scrolls users.

## Share a fight or run

1. Select a recorded fight or run in the Journal and choose its sharing action.
2. Follow the prompts to send each part through the browser opened by ESO. Return to the game for the next part until the upload is complete.
3. The browser page shows the finished report's link and QR code. Scan the QR code on your TV to open it on your phone, then explore it yourself or share the link.

The [web viewer](https://bs.sheludchenkov.com) presents the recorded combat and build data, with CSV and JSON downloads for further analysis. Anyone with a report link can view, download, or reshare it without an account. Reports can include player names and builds; read the [privacy notice](https://bs.sheludchenkov.com/privacy) before uploading. Browser sharing is optional; recording and reviewing fights in the addon works without it.

## Updating to v6

Existing combat history upgrades automatically to a more compact format in the background after login. Each fight is checked against its original before replacement. Brief stutters can occur during this one-time upgrade, and ESO's Add-On Memory gauge may need a UI reload to reflect the space freed.

Read the [v6 release notes](release-notes/v6.0.0.txt), or open **What's New** in the Journal for the release history in your language.

## Languages

English, German, Spanish, French, Japanese, Russian, and Simplified Chinese are supported. English and Russian have native-speaker review; the other translations are primarily AI-generated. Corrections are welcome, especially for game terminology. [GLOSSARY.md](GLOSSARY.md) records the terms used across the addon and viewer.

## Source and contributions

This repository includes the addon in `BattleScrolls/`, the Cloudflare web app in `web/`, Lua tests in `tests/`, web tests in `web/tests/`, and development tools. Release ZIPs contain only the addon and its license; the web app is deployed separately.

**The tests are mostly AI-maintained and receive less human review than the rest of the codebase.** They help catch regressions, but passing tests do not replace code review or testing in ESO. See [CONTRIBUTING.md](CONTRIBUTING.md) for commands, limitations, and the release process.

Report bugs and suggest changes through [GitHub issues](https://github.com/vladislavsheludchenkov/BattleScrolls/issues). Include your platform, ESO and addon versions, steps to reproduce, and any error text. For private reports, contact **v@sheludchenkov.com**. You can also find **@Semigroup1329** on Xbox EU.

## License and author

Battle Scrolls is maintained by **Semigroup1329** and released under the [MIT License](LICENSE).

## Acknowledgements

- **[UESP](https://en.uesp.net/wiki/Online:Online)** - ESO icons used by the web viewer are sourced from UESP's [icon mirror](https://esoicons.uesp.net/)
- **Hodor Reflexes** by @andy.s and @m00nyONE - the "Hodor" group meter design is closely based on their work
- **Hodor Restyle** by Hyperioxes - the "Bars" group meter design is loosely inspired by this
- **LibCombat** by Solinur - ideas for solving some combat tracking edge cases (vSS/vCR portal handling)
- **Area Damage** [ability list](https://github.com/Shienar/AreaDamage) by Shienar - used for AoE vs ST breakdown
- **PotionMaker** by votan - alchemy trait translations sourced from [PotionMaker lang files](https://github.com/votan73/ESO/tree/master/Addons/PotionMaker/lang)
- **Dolgubon's Lazy Writ Crafter** by Dolgubon - alchemy effect ID mapping referenced from [Alchemy.lua](https://github.com/Dolgubon/DolgubonsLazyWritCreator)

---

*This Add-on is not created by, affiliated with, or sponsored by ZeniMax Media Inc. or its affiliates. The Elder Scrolls® and related logos are registered trademarks or trademarks of ZeniMax Media Inc. in the United States and/or other countries.*
