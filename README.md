# Venera Lean

[![flutter](https://img.shields.io/badge/flutter-3.41.4-blue)](https://flutter.dev/)

Venera Lean is an independently maintained, slimmed-down fork of [Venera Prime](https://github.com/venera-app/venera-prime), which in turn derives from [Venera](https://github.com/venera-app/venera) (now archived).

It is a local comic reader that uses JavaScript scripts to access your personal comic collection, whether stored locally, on a NAS, or on other personal storage. Please do not use this software for illegal purposes.

Compared with upstream, this fork removes reading statistics, follow updates, the toolbox and reader page margins; keeps its own backup format and WebDAV prefix; and updates only from [this repository's releases](https://github.com/Arteiimis/venera-lean/releases). Only Windows and Android are built and released, so the other platform folders are intentionally absent.

## Features
- Read local comics
- Use javascript to create comic sources
- Read comics from network sources
- Manage favorite comics
- Download comics
- View comments, tags, and other information of comics if the source supports
- Login to comment, rate, and other operations if the source supports

## Downloads

Windows (portable zip) and Android (signed APKs) builds are published on the [releases page](https://github.com/Arteiimis/venera-lean/releases). The Windows zip is not code signed, so SmartScreen may warn about an unknown publisher on first launch.

## Contributing

Open an [issue](https://github.com/Arteiimis/venera-lean/issues) with a link to your fork, branch, or commits to propose a change.

## Build from source
1. Clone the repository
2. Install flutter, see [flutter.dev](https://flutter.dev/docs/get-started/install)
3. Install rust, see [rustup.rs](https://rustup.rs/)
4. Build for your platform: e.g. `flutter build apk`

## Create a new comic source
See [Comic Source](doc/comic_source.md)

## Thanks

### Tags Translation
[EhTagTranslation](https://github.com/EhTagTranslation/Database)

The Chinese translation of the manga tags is from this project.

## Headless Mode
See [Headless Doc](doc/headless_doc.md)

## License

GPL-3.0, inherited from [Venera Prime](https://github.com/venera-app/venera-prime) and [Venera](https://github.com/venera-app/venera). See [LICENSE](LICENSE).

