# Panchang (package: panchang / com.itsash.panchang)

Offline daily Hindu almanac for a chosen city, in English and Hindi. Today /
any date, month calendar, muhurat timings. No backend; INTERNET is used only
by the update check in Settings.

## Engine (`lib/engine/`, pure Dart)

- `astro.dart`: Sun (Meeus ch. 25, equation of centre + aberration), Moon
  (Meeus ch. 47: all 59 longitude terms, 30 latitude terms, main distance
  terms), mean Lahiri ayanamsa, GMST, ΔT (Espenak-Meeus, linear 2016-2050).
  Longitudes are mean equinox of date with no nutation: nutation cancels in
  elongation and in sidereal longitudes (true lon minus true ayanamsa = mean
  lon minus mean ayanamsa). Ayanamsa = 23.8635 deg at J2000 + precession,
  anchored on Drik's published 24.2288 (true) for 2026-02-15.
- `sky.dart`: `Sky.elongation / sunSidereal / moonSidereal / yogaAngle`
  (functions of UT Julian day), `Sky.crossing` (Newton root finder for an
  increasing angle), sunrise/sunset (upper limb, h0 = -0.8333 deg) and
  moonrise/moonset (disc centre on the horizon after parallax, which is what
  Drik Panchang does; it differs 4 min from the "upper limb + refraction"
  convention). Moonrise is looked up between two sunrises, as in printed
  almanacs.
- `panchang.dart`: `Elements.segments` splits sunrise..next sunrise into
  tithi (30), karana (60), nakshatra (27), yoga (27), moon/sun rashi (12)
  with exact start/end instants. `LunarMonth` = new moon to new moon; name =
  sun's sidereal rashi at the starting new moon + 1 (Meena -> Chaitra);
  adhika when the Sun stays in one rashi from one new moon to the next.
  Purnimanta: krishna paksha takes the label of the next lunation. Vikram
  Samvat is Chaitra-based (+57 from Chaitra, +56 before it); Shaka = VS - 135.
  Ritu by the Sun's sidereal rashi (Meena/Mesha = Vasanta ...), ayana by
  sidereal Makara..Mithuna = Uttarayana.
- `muhurat.dart`: weekday tables for Rahu Kaal / Yamaganda / Gulika (8th
  parts of daytime), Abhijit (8th of 15 day muhurtas, none on Wednesday),
  Brahma Muhurat (2 to 1 night-muhurtas before sunrise), Dur Muhurat (Drik
  table; Tuesday also has the 7th night muhurta), 8+8 choghadiyas.
- `place.dart`: `Place` with standard offset plus a DST rule derived from the
  country in the region string (EU, US/Canada, southern Australia, NZ). Not
  covered: Egypt, Chile, Iran etc. (the city list has standard offsets only).

### Accuracy (checked against Drik Panchang, New Delhi, 13 dates in
2025-2026; see `test/engine_test.dart`)

sunrise/sunset within 0.5 min, moonrise/moonset within 0.5 min, tithi,
nakshatra and yoga end times within 2.2 min (ours run about 1.3 min later on
average; cause not found, ΔT and the Sun's perturbations were ruled out),
all indices at sunrise and the month, adhika, samvat, rashi change times, the
muhurat tables and choghadiya order match. No elevation correction (Drik
uses 212 m for Delhi; effect under a minute).

## Code layout

- `lib/data/names.dart` English/Hindi names (`Bi`); `lib/data/places.dart`
  city list loader, search and nearest city (`assets/geo/cities.json`, copied
  from hastrekha).
- `lib/app/app_model.dart`: `AppModel` (ChangeNotifier: language, amanta /
  purnimanta, place, selected date, Panchang cache, `t(en, hi)`) and
  `AppScope`.
- `lib/ui/`: `home_screen.dart` (UiShell with Today / Calendar / Muhurat),
  `panchang_page.dart`, `calendar_page.dart` (PageView of months, tithi at
  sunrise per day), `muhurat_page.dart`, `location_screen.dart` (search + GPS
  once via geolocator), `settings_screen.dart` (ends with `UiUpdateSection`
  then `UiDeveloperSection`), `format.dart`.
- Tests: `test/engine_test.dart` (reference values), `calendar_test.dart`
  (muhurat, months, samvat, time zones), `app_test.dart` (city list, settings,
  widget smoke test).

## Commands

- `make run`, `make build` (release APK), `make test` (`flutter analyze` +
  `flutter test`), `make clean`.
- Icon: SVG sources in `assets/icon/` (`logo`, `logo_foreground`,
  `logo_background`) -> `rsvg-convert -w 1024 -h 1024` to `*-1024.png`, then
  `dart run flutter_launcher_icons`.

## Conventions

- minSdk 26. UI only from the shared `theme` package (`../theme`, read
  `../theme/COMPONENTS.md`); no hardcoded colors (the saffron accent is the
  `UiApp(accent:)` brand color). Bilingual strings go through
  `AppModel.t(en, hi)` or `Names`.
- No analytics or telemetry.

## Release (Ash Store)

- `store.json` (id `panchang`, repo its-ash/panchang), `store.mk`,
  `index.html` + `CNAME` (`panchang.itsash.in`). See
  `../ash-store/store-kit/STORE.md`.
- `make deploy` = bump version -> build -> commit, tag `vX.Y.Z`, push -> GitHub
  release with `panchang.apk` -> topics, homepage, Pages. Never create
  releases, tags or asset names by hand.
- Do not edit `store.mk` here. Edit `../ash-store/store-kit/store.mk`, then run
  `make store-sync` at the workspace root.
