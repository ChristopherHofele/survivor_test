# survivor_test

A top-down survivor game built with Flutter + Flame (`flame`, `flame_tiled`, `flutter_soloud`, `shared_preferences`). Maps are made in Tiled (`assets/tiles/*.tmx`). Main target: Android phones in landscape.

## Working with the user

- The user is a beginner; this is their first real project. Explain changes in plain language (what changed, why, any new Dart/Flutter concept), and end with a short test checklist.
- Work step by step. For bigger features: discuss the design and ask the open questions first, propose defaults, then build in small steps the user can test and commit in between.
- When the user asks for ideas, a plan or research, don't change code until they say so.
- The user tests on their Android phone and commits themselves. Run `dart analyze lib` after every change.
- Files use CRLF line endings; keep them consistent when editing.

## Rules

- **Never edit `.tmx` or `.tsx` files.** The user edits maps in Tiled. When a feature needs map objects, tell them exactly what to add (layer name, object class, shape, roughly where). Reading the files to inspect them is fine.
- Objects in the `Collisions` layer whose class isn't handled in `Level._addCollisions` become solid walls, so new marker objects need their own `case` there (or go in another layer).
- Put tuning values in clearly named constants at the top of the class (the user tunes them).
- Mark temporary art or behaviour with `PLACEHOLDER` or `TODO` comments.

## Structure

- `lib/main.dart`: `GameApp` (a `MaterialApp` around the `GameWidget`, which dialogs need; restarting a run gives the `GameWidget` a new key), overlays, and an `AppLifecycleListener` that pauses all sounds when the app is hidden.
- `lib/survivor_test.dart`: the game (`SurvivorTest`): world loading, run stats, score, game over, testing switches.
- `lib/level.dart`: a room (`World`) built from a Tiled map: collisions, spawners, tree, statue, camera bounds.
- `lib/components/camera_follower.dart`: moves the camera itself (sets `viewfinder.position`; Flame's `follow`/`setBounds` are no longer used). Each `Level` adds its own and passes it the map limits.
- `lib/actors/`: player, basic enemies, boss, collision helpers and `spriteSheetAnimation` in `utils.dart`.
- `lib/components/`: items, trees, souls, statue, orb, zone, `Lob` (arc throw), `ScreenShake`, projectiles and attacks.
- `lib/overlays/`: HUD pieces and the Flutter menu screens.
- `lib/data/personal_bests.dart`: personal best list saved on the device.
- `lib/data/online_player.dart`, `leaderboard.dart`, `blocked_names.dart`: the global leaderboard (player ID and name, sending scores, loading the board, the name filter). `firestore.rules` holds the server rules, which the user pastes into the Firebase console.
- State that must survive changing rooms lives on the game or the player, because every door rebuilds the `Level`.

## Game design (built)

**Menus.** The start screen (`start_screen.dart`, overlay `StartScreen`) is the main menu: title, "Player: name ✎", Play, Leaderboard and Exit (Android/desktop only). Play opens `character_select_screen.dart` (overlay `CharacterSelect`), with Start and Back. It was split out because the menu overflowed the phone screen.

**Characters.** Fire Guy, Melee Lad, Dash Man and Mine Fellow, picked on the character selection screen (Start stays disabled until one is chosen). Sprites and frame counts come from the `characterSprites` table in `player.dart`, with idle and walking animations; all three levels use the same art for now. `player.level` holds the upgrade level and `current` holds the animation.

**Character unlocks** (done and tested). `lib/data/unlocks.dart` saves the unlocked characters, the enemy total across runs and the last character played on the device. The `milestones` table there (tuning constants at the top):
- Fire Guy: from the start.
- Melee Lad: defeat the boss.
- Dash Man: 500 enemies in total across all runs; the hint shows progress, e.g. "(213/500)".
- Mine Fellow: a **secret** milestone (hint "???"). Eat the same kind of fruit (apple, banana or cherry; not the strawberry) twice within one stretch of a run. A stretch runs from the start to the first boss, between two bosses, or after the last boss. Tracked in `game.fruitsSinceLastBoss` (filled by `game.fruitEaten`, cleared in `game.bossDefeated`) and `game.ateSameFruitTwice`.
- "Defeat the level 3 boss" is kept for a possible fifth character.

During the run, `game.checkUnlocks()` runs after every kill (`game.enemyKilled()`), boss defeat (`game.bossDefeated()`) and fruit (`game.fruitEaten()`). It uses the instant `Unlocks.newlyReached()`, saves right away with `Unlocks.unlock()`, remembers what was announced in `game.unlockedThisRun`, and shows an `UnlockBanner` (`lib/overlays/unlock_banner.dart`, top centre below the seeds, slides in, 3 s, one at a time from `_bannerQueue`). At game over, `Unlocks.finishRun()` checks once more and adds the run's kills to the total. The Game Over screen lists everything unlocked in the run ("New character unlocked: …!") before the Continue button. Test runs show unlocks with "(test run – not saved)" but don't save them or the kills. The character selection greys out locked characters (lock icon, hint underneath) and preselects the last character played (or Fire Guy).

**Seeds and fruit (upgrades).**
- Each upgrade room (Health, Stamina, Damage) has a special tree: a 32×32 `Tree` object in its `Collisions` layer.
- Enemies killed within a quarter of the room's width send a soul to the tree instead of dropping a cookie. 10 souls drop the room's seed (Apple, Banana or Cherry) at the room's `*_Shop` object.
- You can't leave a room without its seed, and a room's door stays closed while you carry its seed. You can carry one of each kind; they show on the HUD.
- Touching the lake in Level 1 (any `DropOff` rectangle in the `Statue` layer) plants all carried seeds. The statue throws the matching fruit to the `Gift` point. Fruit gives the upgrade and +5 money, and upgrades stack.
- The boss's strawberry resets only the attack cooldown (from cherries). Apples and bananas stay, which is intended.

**Statue key event.**
- Planting one seed of each kind activates the statue, and Level 1 is locked until the key is picked up.
- Every kill in Level 1 sends a soul to the statue (`soulsToCharge = 20`).
- When full, the statue throws an orb to one of four `ZoneSpot` points, creating a zone 192 px across.
- An enemy killed inside the zone revives as its charged version (purple tint placeholder):
  - radish: fast, 30 health
  - carrot: 1.5× size, 120 health
  - broccoli: 180 health, fires a burst of 3 quick re-aimed shots every 3 s
- The charged enemy drops the key. Every hit always costs exactly one heart.
- After throwing the orb, the statue needs one seed of each kind again.

**Boss levels.** The boss gets harder with every fight in a run (level = bosses defeated + 1, from 1 to a maximum of 4). The `levels` table and the `...FromLevel` constants are at the top of `boss_enemy.dart`.
- Level 2: fan shot, and sometimes throws a seed that grows into a carrot (at most 3).
- Level 3: two-armed spin, and seed carrots may be charged.
- Level 4: double charge.
- The volley never gets upgraded (16 directions was undodgeable). The charge stops when the body (`contactRadius`) hits a wall, and the screen shakes.
- The boss has a big hurtbox and a smaller `BossContactZone` that hurts the player.

**Sprint camera lag.** When a sprint starts, the camera is held back for `lagDuration` (0.4 s) and then catches up; walking is unchanged. The lag is computed from the camera target already clamped to the map limits, so nothing builds up at map edges. It's capped at a quarter of the screen height, and the camera snaps to the player on room changes and teleports. The user tested it on the phone and is happy with it. A zoom-out while sprinting was discussed but deliberately left out for now.

**Score and screens.**
- Score: +10 per kill, +1000 × boss level, +1 per second, −25 per hit, never below 0. The constants are on `SurvivorTest`.
- Game Over reveals the stats one by one, then shows "Continue".
- Personal Bests: the top 10 with score, character and date (day/month/year), with this run highlighted.
- Global Leaderboard: the real board (see step 6 below), also reachable from the main menu.

## Testing switches (in `SurvivorTest`, keep `false`/`0` when committing)

`debugStartWithAllSeeds`, `debugAllEnemyTypesInLevel1`, `debugBossLevel` (1–4, 0 = off), `debugClearPersonalBests`, `debugClearPlayerName` (handled in `main()`), `debugUnlockAllCharacters` (nothing saved), `debugResetUnlocks` (handled in `main()`). Runs with any of the first three on are test runs (`isTestRun`): not saved, not sent online. For faster statue tests, temporarily lower `soulsToCharge` in `lake_statue.dart`.

## Placeholders waiting for the user's art

- The statue planting effect (planned: eyes flash plus an orbiting orb in the fruit's colour); currently a white flash.
- The orb, the zone and the charged-enemy tint.
- The boss's carrot seed, which uses the Apple seed image.
- Mine Fellow's walking sheet (it uses his idle image) and the Broccoli's walking sheet.

## Next step: global leaderboard (setup done, building not started)

- The plan is Firebase: Firestore plus anonymous auth, on the free Spark plan.
- Ruled out:
  - Play Games/Game Center: mobile only, separate boards per platform, heavy setup.
  - Supabase: free projects pause after a week.
  - LootLocker: no Flutter SDK.

**Decided with the user:**
- Platforms: Android and iOS only, so configure just those in `flutterfire configure`. Building for iOS needs a Mac with Xcode; the user tests Android from Windows.
- One entry per player, holding their best score.
- The name is entered once (max ~12 characters) and saved on the device.

**The user's part is done** (on the Windows machine): Firebase project created, Firestore database created in production mode, Anonymous sign-in enabled, Node.js + Firebase CLI + `flutterfire_cli` installed (Pub cache `bin` added to the user PATH), and `firebase login` done. On another machine, the tools and the login would need to be set up again.

**Then build:**
1. Done: app ID changed to `com.hofele.vegetablesurvivors` (first `monstersurvivors`, renamed before the first store upload; Android `applicationId` and iOS bundle ID; the Android `namespace` stays `com.example.survivor_test`). `flutterfire configure` was run for Firebase project `survivor-test-cd43b` (Android + iOS), giving `lib/firebase_options.dart` and `android/app/google-services.json`. Added `firebase_core`, `firebase_auth` and `cloud_firestore`, and `Firebase.initializeApp` in `main()`. Kotlin was raised to 2.4.10 (firebase_auth needs it), with `jvmTarget` moved to the `kotlin { compilerOptions }` block; the iOS deployment target is now 15.0. The Android debug build works. iOS hasn't been built yet (needs the Mac; the Podfile is created on the first build there and may need `platform :ios, '15.0'`).
2. Done and tested: anonymous sign-in in the background via `OnlinePlayer` in `lib/data/online_player.dart` (`signIn()` is started unawaited in `main()`, and retried in `_onAppShown` when the app returns to the foreground while still signed out; use `ensureSignedIn()` before anything that needs `OnlinePlayer.id`). An account remembered on the device counts as signed in even offline; sign-in only needs the internet on the very first launch. The player's name (step 3) goes in this class too.
3. Done and tested: one-time name entry. `OnlinePlayer` has `name`, `loadName()` (awaited in `main()`), `saveName()`, `clearName()` and `nameProblem()` (3–12 characters, letters/digits/spaces/`-`/`_`). The window is in `lib/overlays/name_dialog.dart`; the start screen opens it on first launch (it can't be cancelled then) and via "Player: name ✎" (it can be cancelled there). Names don't have to be unique.
4. Done and tested: `OnlinePlayer.submitBest()` runs after the personal best is saved at game over and is passed the **top personal best** (so a record that couldn't be sent gets sent later). It reads the player's entry in `leaderboard/{uid}` first (falling back to the device cache offline) and only `set`s when the score is higher or there's no entry. The write isn't awaited, so Firestore's offline queue delivers it later. Fields: `name`, `score`, `character`, `date` (the run's date), `updatedAt` (server timestamp). `saveName()` also `update`s the entry's name (only if the name changed; `not-found` is ignored). There's no local "last score sent" on purpose: deleting entries in the console must not stop resubmission. The user will delete test entries in the console by hand (no testing switch until step 8). The first version of the rules is in `firestore.rules` (the user pastes it into the console): read when signed in, write only your own entry.
5. Done and tested: stricter rules in `firestore.rules`. Exactly the 5 fields; name regex matching `nameProblem`; integer score 0–1,000,000; one of the four character names; `date` no more than 1 day in the future; `updatedAt == request.time`. Updates only for a higher score or a name-only change (`diff().affectedKeys().hasOnly(['name','updatedAt'])`), and at most once every 10 s. No deletes. Tested with 44 cases in the local Firestore emulator (Java from Android Studio's `jbr`, `@firebase/rules-unit-testing`, run from a scratch folder, not the repo). Known trade-off: a name change within 10 s of a record is rejected (the name stays saved locally and goes online with the next record).
5b. Done and tested: a blocked-names list (English + German) in `lib/data/blocked_names.dart` (`BlockedNames.anywhere` / `wholeWordOnly`, plain Dart with no imports), checked in `nameProblem`. **The rules' `isBlockedName` is generated from it** by `dart run tool/update_blocked_names_rules.dart`, which rewrites the block between the `BEGIN/END BLOCKED NAMES` markers in `firestore.rules`; never edit that block by hand. Cleaning before the check: lowercase, accents removed, digits 0/1/3/4/5/7 → o/i/e/a/s/t; each letter in the patterns is `x+`, so repeated letters still match (RE2 in the rules has no backreferences). "Anywhere" words are checked on the name without spaces/`-`/`_`; whole words are checked per word and against the whole compacted name. Tested with 76 names (blocked and harmless) in both Dart and the emulator. The start screen asks again for a name if the saved one is no longer allowed. The user doesn't want existing names hidden on the board, and is fine seeing the list.
6. Done and tested: `lib/data/leaderboard.dart` (`Leaderboard.load()` → `LeaderboardResult` with `top`, `me`, `playerCount`). It reads the top 10 (`orderBy score desc, limit 10`, ties sorted by `date` on the device), the own entry, its place via `count()` of higher scores, and the total via `count()`. Equal scores share a place. `lib/overlays/global_leaderboard.dart` shows place, name, character and score (no date, as the user decided), highlights the own entry in amber, and adds it below "···" if it's outside the top 10. After a run the message line says "You're #N of M players!" (or "Not on the board yet"), with a "Main Menu" button. From the start screen's new "Leaderboard" button (overlay `GlobalLeaderboardFromMenu`) there's no message line and the button is "Back". The screen first awaits `game.leaderboardSubmission` (set in `_recordPersonalBest`) so a new record already shows. On errors it shows a simple "Couldn't load the leaderboard" (TODO for step 7).
7. Done and tested: `Leaderboard.load()` has an 8 s `timeLimit` and throws `NoConnection` on a timeout, a failed sign-in, Firestore `unavailable`/`deadline-exceeded`, or a result with `metadata.isFromCache` (offline, Firestore would otherwise quietly show only cached entries, e.g. just the player's own). `submitBest` returns a `SubmitResult` (`sent` / `notNeeded` / `couldNotSend`); the screen waits for it for at most 5 s. Offline the screen shows "No connection – leaderboard unavailable" (other errors: "Couldn't load the leaderboard. Please try again later.") with a "Try again" button; after a run it adds "Your new best will be sent once you're online" (`sent`) or "Your best will be sent after your next run with internet" (`couldNotSend`). The user decided not to show a cached "last known board".
8. Replaced by a simpler check (the user's choice): `SurvivorTest.isTestRun` is true while `debugStartWithAllSeeds`, `debugAllEnemyTypesInLevel1` or `debugBossLevel` is on. Such runs aren't saved as a personal best (`PersonalBests.add(..., save: false)`, so the screen still shows where they'd place) and aren't sent online; otherwise the catch-up would later send an inflated personal best. A new gameplay switch must be added to `isTestRun`. No separate test collection: the user will delete the `leaderboard` collection in the console before release (not the Authentication users, which would break the phone's sign-in until its app data is cleared).

## Google Play release (code prepared, not uploaded yet)

- The game's name is **Vegetable Survivors** (Android `android:label`, `MaterialApp.title`, main menu title, `pubspec.yaml` description). The package name `survivor_test` and the Android `namespace` `com.example.survivor_test` stay as they are (players never see them).
- `version: 1.0.0+1` in `pubspec.yaml`. The build number after `+` must go up with every upload.
- `INTERNET` permission in the main `AndroidManifest.xml` (it was only in debug/profile).
- App icon via `flutter_launcher_icons` (dev dependency, settings at the end of `pubspec.yaml`, Android only). `assets/icon/icon.png` is a PLACEHOLDER (green with an orange circle). Replace it and run `dart run flutter_launcher_icons`.
- Signing: `android/app/build.gradle.kts` reads `android/key.properties` (git-ignored: `storePassword`, `keyPassword`, `keyAlias=upload`, `storeFile`). Without that file, release builds fall back to the debug key. The user still has to create the upload key with `keytool` (from Android Studio's `jbr`), stored outside the repo and backed up.
- `flutter build appbundle` works (about 76 MB). The `e: ... incompatible version of Kotlin` lines come from the `lintVitalAnalyzeRelease` tasks (lint's older embedded Kotlin) and don't fail the build.
- `google-services.json` contains both the old (`monstersurvivors`) and the new Firebase Android app. The old Firebase apps can be removed in the Firebase console.
- The user decided against making release builds ignore testing switches, so check them before building for the store.
- Still to do outside the code: Play Console account ($25), closed test with 12+ testers for 14 days, store listing, content rating, data safety (anonymous ID, player name, scores), a privacy policy page, and deleting the `leaderboard` collection before launch.

## Other open ideas

- Feedback when walking into a closed door.
- Further changes to how the key works (the user mentioned more ideas).
- Cleanups from the first code review that haven't been done yet:
  - the 13 repeated collision blocks in `level.dart`
  - the hit-flash effect copied across the enemies
  - `Future.delayed` timers in the boss (use countdowns or `TimerComponent` instead)
