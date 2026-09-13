# Installation Instructions


## Table of Contents
1. [Requirements](#requirements)
1. [LEKMOD Installation](#lekmod-installation)
    1. [Windows](#windows)
        1. [LEKMOD v33 and higher](#option-a-lekmod-v33-and-higher---with-custom-eui-and-standard-ui-support)
        1. [LEKMOD v32 and lower](#option-b-lekmod-v32-and-lower---no-specific-ui-support)
    1. [Linux](#linux)
        1. [LEKMOD v33 and higher - (Currently Unavailable)](#a-lekmod-v33-and-higher---eui-and-standard-ui-support---currently-unavailable)
        1. [LEKMOD v32 and lower](#b-lekmod-v32-and-lower---no-specific-ui-support)
    1. [macOS](#macos)
1. [Lekmap Installation](#lekmap-installation)

## Requirements
1. OS
    1. **Windows 7+** - Full Support
    1. **Linux** - Limited/Untested Support
    1. **macOS** - Aspyr 64-bit Steam build; Rosetta 2 required on Apple silicon. The binary targets Aspyr's 10.11.6 minimum, but current CI does not runtime-test that oldest OS.
1. Game: Sid Meier's Civilization V - All available DLC's except for map packs.
1. Standard UI or EUI (Enhanced User Interface) - LEKMOD v33 and higher support both UIs, Note EUI v 1.29 or higher is currently not supported.

## LEKMOD Installation 

### Windows
#### Option A. LEKMOD v33 and higher *- with Custom EUI and Standard UI support*
1. Download the version you wish to install
1. Extract the contents of the zip file
1. Copy the extracted files into your DLC folder, replacing any existing files
Usually under: `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization V\Assets\DLC` <br/> 
To find your game folder, right click Civilization V in your Steam library, select Properties, go to the Local Files tab, and click Browse Local Files. <br/> The final path should look like this:
`...\Sid Meier's Civilization V\Assets\DLC\LEKMODvXX_X\`
1. Open the folder and run ui_check.bat
This will copy the necessary UI files based on your current UI setup. (UI / EUI up to v1.28 supported)

1. Launch the game. You should see "LEKMOD" in your multiplayer lobby.


#### Option B. LEKMOD v32 and lower *- No specific UI support*
1. Download the version you wish to install
1. Extract the contents of the zip file
1. Copy the extracted files into your LEKMOD folder, replacing any existing files
Usually under: `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization V\Assets\DLC` <br/> 
To find your game folder, right click Civilization V in your Steam library, select Properties, go to the Local Files tab, and click Browse Local Files. <br/> The final path should look like this:
`...\Sid Meier's Civilization V\Assets\DLC\LEKMODvXX_X\`
1. Launch the game. You should see "LEKMOD" in your multiplayer lobby.

### Linux
#### A. LEKMOD v33 and higher - EUI and Standard UI support - (Currently Unavailable)
1. Ensure you have Proton enabled for Civilization V
For steam, right click Civilization V in your library, select Properties, go to the Compatibility tab, and check "Force the use of a specific Steam Play compatibility tool", then select the latest Proton version from the dropdown.
Suggested Proton version: Proton Experimental or Proton 10.0-3
1. Download the version you wish to install
1. Extract the contents of the zip file
    ```sh
    unzip LEKMODvXX_X.zip -d LEKMODvXX_X
    ```
1. Copy the extracted files into your DLC folder, replacing any existing files
Usually under: `~/.steam/steam/steamapps/common/Sid Meier's Civilization V/Assets/DLC`
To find your game folder, right click Civilization V in your Steam library, select Properties, go to the Local Files tab, and click Browse Local Files. <br/>The final path should look like this: <br/> `.../Sid Meier's Civilization V/Assets/DLC/LEKMODvXX_X/`
1. cd into the folder and run linux_ui_check.sh
This will copy the necessary UI files based on your current UI setup. (UI / EUI up to v1.28 supported)
1. Launch the game. You should see "LEKMOD" in your multiplayer lobby.

#### B. LEKMOD v32 and lower - No specific UI support
1. Ensure you have Proton enabled for Civilization V
For steam, right click Civilization V in your library, select Properties, go to the Compatibility tab, and check "Force the use of a specific Steam Play compatibility tool", then select the latest Proton version from the dropdown.
Suggested Proton version: Proton Experimental or Proton 10.0-3
1. Download the version you wish to install
1. Extract the contents of the zip file
    ```sh
    unzip LEKMODvXX_X.zip -d LEKMODvXX_X
    ```
1. Copy the extracted files into your DLC folder, replacing any existing files
Usually under: `~/.steam/steam/steamapps/common/Sid Meier's Civilization V/Assets/DLC`
To find your game folder, right click Civilization V in your Steam library, select Properties, go to the Local Files tab, and click Browse Local Files. <br/>The final path should look like this: <br/> `.../Sid Meier's Civilization V/Assets/DLC/LEKMODvXX_X/`
1. Launch the game. You should see "LEKMOD" in your multiplayer lobby.

### macOS

Native macOS installation, updates, switching between Lekmod and Vox Populi,
and stock restoration are owned by **Wir Schaffen DLC**.

Build a verified artifact from this repository with:

```sh
export CIV5_COMPAT_SOURCE=/path/to/civ5-macos-gamecore-compat
LEKMOD_DLL/macos/package-macos.sh /path/to/new-release.zip
```

Use the SHA-256 printed by packaging when installing with Wir Schaffen DLC:

```sh
wir-schaffen-dlc --gamecore lekmod --gamecore-package /path/to/release.zip --gamecore-sha256 SHA256
wir-schaffen-dlc --gamecore status
wir-schaffen-dlc --gamecore stock
```

Add `--dry-run` to inspect a planned install. Quit Civilization V before an
actual change. Use `--game-app` for a non-default Steam application location.
The installer verifies the artifact and known stock game, retains one stock
backup outside the application bundle, and updates the binary and DLC together.
Steam integrity restoration is detected by `--gamecore status`.

The old `install-macos.sh` entry point is retired. The shared repository and
new native artifacts have not yet been published; this workflow currently uses
local pinned checkouts and locally verified artifacts. See
[the native build documentation](../LEKMOD_DLL/macos/README.md).


## Lekmap Installation
1. Download Lekmap
1. Extract the contents of the zip file
1. Copy the extracted folder into your MAPS folder
    For Windows, usually under: `C:\Program Files (x86)\Steam\steamapps\common\Sid Meier's Civilization V\Assets\Maps` <br/>
    For macOS, use `Civilization V.app/Contents/Assets/Assets/Maps`.<br/>
    To find your game folder, right click Civilization V in your Steam library, select Properties, go to the Local Files tab, and click Browse Local Files.
    The final path should look like this: <br/>
    `...\Sid Meier's Civilization V\Assets\Maps\Lekmap vX_X\`
1. Launch the game. You should see one ore more Lekmap vX_X options in the additional maps selection options.
