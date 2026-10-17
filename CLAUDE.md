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

- `lib/main.dart`: `GameApp` (restarting a run gives the `GameWidget` a new key), overlays, and an `AppLifecycleListener` that pauses all sounds when the app is hidden.
- `lib/survivor_test.dart`: the game (`SurvivorTest`): world loading, run stats, score, game over, testing switches.
- `lib/level.dart`: a room (`World`) built from a Tiled map: collisions, spawners, tree, statue, camera bounds.
- `lib/components/camera_follower.dart`: moves the camera itself (sets `viewfinder.position`; Flame's `follow`/`setBounds` are no longer used). Each `Level` adds its own and passes it the map limits.
- `lib/actors/`: player, basic enemies, boss, collision helpers and `spriteSheetAnimation` in `utils.dart`.
- `lib/components/`: items, trees, souls, statue, orb, zone, `Lob` (arc throw), `ScreenShake`, projectiles and attacks.
- `lib/overlays/`: HUD pieces and the Flutter menu screens.
- `lib/data/personal_bests.dart`: personal best list saved on the device.
- State that must survive changing rooms lives on the game or the player, because every door rebuilds the `Level`.

## Game design (built)

**Characters.** Fire Guy, Melee Lad, Dash Man and Mine Fellow, picked on the start screen (Start stays disabled until one is chosen). Sprites and frame counts come from the `characterSprites` table in `player.dart`, with idle and walking animations; all three levels use the same art for now. `player.level` holds the upgrade level and `current` holds the animation.

**Seeds and fruit (upgrades).**
- Each upgrade room (Health, Stamina, Damage) has a special tree: a 32×32 `Tree` object in its `Collisions` layer.
- Enemies killed within a quarter of the room's width send a soul to the tree instead of dropping a cookie. 10 souls drop the room's seed (Apple, Banana or Cherry) at the room's `*_Shop` object.
- You can't leave a room without its seed, and a room's door stays closed while you carry its seed. You can carry one of each kind; they show on the HUD.
- Touching the lake in Level 1 (any `DropOff` rectangle in the `Statue` layer) plants all carried seeds. The statue throws the matching fruit to the `Gift` point. Fruit gives the upgrade and +5 money, and upgrades stack.

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
- Global Leaderboard: still a placeholder, with the "Main Menu" button.

## Testing switches (in `SurvivorTest`, keep `false`/`0` when committing)

`debugStartWithAllSeeds`, `debugAllEnemyTypesInLevel1`, `debugBossLevel` (1–4, 0 = off), `debugClearPersonalBests`. For faster statue tests, temporarily lower `soulsToCharge` in `lake_statue.dart`.

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
1. Done: app ID changed to `com.hofele.monstersurvivors` (Android `applicationId` and iOS bundle ID; the Android `namespace` stays `com.example.survivor_test`). `flutterfire configure` was run for Firebase project `survivor-test-cd43b` (Android + iOS), giving `lib/firebase_options.dart` and `android/app/google-services.json`. Added `firebase_core`, `firebase_auth` and `cloud_firestore`, and `Firebase.initializeApp` in `main()`. Kotlin was raised to 2.4.10 (firebase_auth needs it), with `jvmTarget` moved to the `kotlin { compilerOptions }` block; the iOS deployment target is now 15.0. The Android debug build works. iOS hasn't been built yet (needs the Mac; the Podfile is created on the first build there and may need `platform :ios, '15.0'`).
2. Anonymous sign-in in the background.
3. One-time name entry, saved on the device.
4. Submit the score at game over: one document per player, keyed by user ID, only updated when higher.
5. Security rules for the user to paste: only your own entry, plausible scores, limited name length.
6. The screen: top 10 plus your own rank, with your entry highlighted.
7. A clear message when offline.
8. A testing switch that writes to a separate test collection.

## Other open ideas

- Feedback when walking into a closed door.
- Further changes to how the key works (the user mentioned more ideas).
- Cleanups from the first code review that haven't been done yet:
  - the 13 repeated collision blocks in `level.dart`
  - the hit-flash effect copied across the enemies
  - `Future.delayed` timers in the boss (use countdowns or `TimerComponent` instead)
