# FesterHead's Data Pack

[![Release](https://img.shields.io/github/v/release/FesterHead/FesterHeadsDataPack?label=release)](https://github.com/FesterHead/FesterHeadsDataPack/releases)
[![License](https://img.shields.io/github/license/FesterHead/FesterHeadsDataPack)](LICENSE)
[![CI](https://github.com/FesterHead/FesterHeadsDataPack/actions/workflows/release.yml/badge.svg)](https://github.com/FesterHead/FesterHeadsDataPack/actions)
[![Downloads](https://img.shields.io/github/downloads/FesterHead/FesterHeadsDataPack/total)](https://github.com/FesterHead/FesterHeadsDataPack/releases)
[![Last commit](https://img.shields.io/github/last-commit/FesterHead/FesterHeadsDataPack)](https://github.com/FesterHead/FesterHeadsDataPack/commits)
[![Minecraft](https://img.shields.io/badge/Minecraft-1.20.1-brightgreen)](#compatibility)

A collection of world generation tweaks, recipe conversions, and Minecolonies helpers for Minecraft Java Edition.

## Table of contents

- [Features](#features)
- [Install (player)](#install-player)
- [Build (developer)](#build-developer)
- [Release workflow](#release-workflow)
- [Contents of the ZIP](#contents-of-the-zip)
- [Compatibility](#compatibility)
- [Credits](#credits)
- [Contributing](#contributing)
- [License](#license)
- [Changelog](#changelog)

---

## Features

- Custom world generation: bigger/taller trees, no-caves, no grass, and larger ore veins.
- Recipe conversions and recycling (smelting-based) to recover resources.
- Minecolonies additions: expanded citizen names, flower-based recruitment items, only one rare disease, additional path blocks for road varieties, and removal of abandoned colonies.

## Install (player)

1. Download the latest release ZIP from the Releases page.
2. Place the ZIP (or its `data/` folder) into your world's `datapacks/` directory.
3. Start the world and run `/reload` if needed.

## Build (developer)

From the repository root (PowerShell on Windows):

```powershell
# Build with explicit version
.\zip-datapack.bat 1.0.18

# Build using the latest git tag (requires a tag to exist)
.\zip-datapack.bat
```

The artifact is written to `releases/<base>-<minecraft-version>-<version>.zip` (for example `releases/festerheads-datapack-1.20.1-1.0.18.zip`).

### Disable features / remove files

If you want to remove specific items or features from the datapack (for example you don't want the changed grass behavior), remove the corresponding files or folders from the unpacked datapack before installing. Typical options:

- Delete specific worldgen placed features: remove files under `data/minecraft/worldgen/placed_feature/`.
- Remove an entire feature set: delete the directory under `data/<namespace>/` for that feature (for example `data/festerhead/worldgen/` if you want to remove the festerhead worldgen additions).
- Edit or remove recipes under `data/festerhead/recipes/` to disable conversions.

After editing, re-zip the datapack and install into `world/datapacks/`, then reload the world or restart the server.

## Release workflow

- Tag-based: pushing `vX.Y.Z` creates a published release and uploads the ZIP.
- Test/draft flow: pushing `vdraft-X.Y.Z` creates a _draft_ release and also uploads the ZIP as a workflow artifact so testers can download it.
- The release body is populated automatically from the `changelog.md` entry matching the numeric version `X.Y.Z`.

## Contents of the ZIP

The generated ZIP contains the datapack at the root and includes documentation files so end users can read them without opening the repo. Example structure:

- pack.mcmeta
- pack.png
- data/
  - festerhead/
    - recipes/
    - worldgen/
    - ...
  - minecolonies
    - ...
  - minecraft
    - ...
- changelog.md
- LICENSE
- README.md

Including additional files at the root is intentional and will not break Minecraft's datapack format — Minecraft ignores extra files at the root as long as `pack.mcmeta` and the `data/` folder are present.

## Compatibility

- Tested with Minecraft Java Edition 1.20.1.
- Optional: Minecolonies for Minecraft Java Edition 1.20.1.

## Credits

### The trees

Tree generation heavily inspired by [Bigger Trees](https://www.curseforge.com/minecraft/mc-mods/bigger-trees) mod. Worldgen files pulled from jar, adjusted some for size, and included within my data pack. I especially like the taller oak trees from the plains seed [5467369947628262074](https://www.chunkbase.com/apps/seed-map#seed=5467369947628262074&platform=java_1_20&dimension=overworld&x=0&z=0&zoom=0.5) I've been using since 1.19.2 with the Minecolonies mod.

### No abandoned Minecolony colonies

From [Stop Minecolonies spawning abandoned colonies](https://www.curseforge.com/minecraft/texture-packs/stop-minecolonies-spawning-abandoned-colonies), thank you.

### No caves

From [No Caves Datapack for Minecraft](https://github.com/Quidvio/No-Caves-World-Generation), thank you.

### Larger ore veins

From [Larger Ore Veins: Deluxe](https://modrinth.com/datapack/larger-ore-veins-deluxe), thank you.

## Contributing

- Fork the repo, create a branch, and open a pull request.
- Update `changelog.md` (add a `## [X.Y.Z]` section) for any release entries.
- Use `zip-datapack.bat` to build artifacts locally for testing.

## License

This project is licensed under the terms in the `LICENSE` file.

## Changelog

See `changelog.md` for the full history.
