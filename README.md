# Panchang

Daily Hindu panchang for your city: tithi, nakshatra, muhurat and a monthly calendar, offline.

**[Website](https://panchang.itsash.in)** · **[Download APK](https://github.com/its-ash/panchang/releases/latest/download/panchang.apk)** · Get it in **[Ash Store](https://store.itsash.in)**

## Features

- **Daily panchang** for any date: vaar, tithi (with paksha and end time),
  nakshatra, yoga and karana with their end times, moon sign and sun sign,
  Hindu month (amanta or purnimanta), Vikram and Shaka samvat, ritu and ayana.
- **Sun and Moon**: sunrise, sunset, moonrise and moonset for your city.
- **Muhurat**: Rahu Kaal, Yamaganda, Gulika Kaal, Abhijit, Brahma Muhurat,
  Dur Muhurat, and the day and night choghadiya with the current one marked.
- **Month calendar** with the tithi of every day and Purnima, Amavasya and
  Ekadashi marked. Swipe between months, tap a day for its details.
- **Your city**: pick from a built-in list of about 340 cities (with summer
  time rules for Europe, North America, Australia and New Zealand), or let GPS
  choose the nearest one once.
- **English and Hindi**, switchable in Settings.
- **Offline and private**: everything is calculated on your phone. The only
  network call is the update check in Settings.

## Install

- **Ash Store**: install [Ash Store](https://store.itsash.in) once, then install and update Panchang from it.
- **APK**: download the [latest APK](https://github.com/its-ash/panchang/releases/latest/download/panchang.apk) on your phone and open it. Allow your browser to install unknown apps if Android asks.

Requires Android 8.0 (API 26) or later.

## Accuracy

Times come from the Sun and Moon series of Jean Meeus, *Astronomical
Algorithms*, with the Lahiri ayanamsa. Checked against Drik Panchang (New
Delhi) on 13 dates: sunrise, sunset, moonrise and moonset within 1 minute;
tithi, nakshatra and yoga end times within about 2 minutes. Rise and set
times ignore the height of your place above sea level. Panchang traditions
differ between regions, so a printed almanac may differ slightly.

## Develop

Needs Flutter ≥ 3.44 and the shared theme package at `../theme`.

```bash
make run      # run on a connected device
make test     # flutter analyze + flutter test
make build    # release APK
make deploy   # bump version, build, tag, push, GitHub release (see store.mk)
```

## Release

`make deploy` follows the Ash Store kit (`store.mk`, `store.json`): it bumps the
version in `pubspec.yaml`, builds, commits, tags `vX.Y.Z`, pushes, and publishes
a GitHub release with `panchang.apk`. Ash Store and the website pick up the new
version from that release.

## Project layout

```
lib/
├── main.dart                  # UiApp + AppScope
├── engine/                    # pure Dart astronomy and calendar (no Flutter)
│   ├── astro.dart             # Sun, Moon, ayanamsa, sidereal time, delta T
│   ├── sky.dart               # elongation, root finder, sunrise/moonrise
│   ├── panchang.dart          # tithi, nakshatra, yoga, karana, months
│   ├── muhurat.dart           # Rahu Kaal, Abhijit, choghadiya, ...
│   └── place.dart             # place, time zone and summer time
├── data/
│   ├── names.dart             # English and Hindi names
│   └── places.dart            # offline city list, search, nearest city
├── app/app_model.dart         # settings, selected date, cache
└── ui/                        # pages: today, calendar, muhurat, settings, location
assets/geo/cities.json         # offline cities
```

See `CLAUDE.md` for details.

## License

No license file is included yet.

Built by [itsash.in](https://itsash.in).
