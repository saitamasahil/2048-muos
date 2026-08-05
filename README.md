# 2048 Plus

<p align="center">
  <img src="demo.webp" alt="Gameplay Animation" width="400" />
</p>

A feature-packed implementation of the classic puzzle game 2048 for muOS and PortMaster, built using the LÖVE framework.

This project is inspired by and references the popular open-source [2048 Android](https://github.com/tpcstld/2048) game by tpcstld, which itself is based on the original web game by Gabriele Cirulli. While taking visual and design references from the Android version, this codebase was written from the ground up in Lua for the LÖVE engine. In addition to the classic gameplay, I have introduced numerous new features, including multiple game modes, store, an achievement system, and a wide variety of themes to enhance the overall experience.

## Features

- **Game Modes**: Classic, Plus Mode with Bomb, Swap, and Undo powerups, and 4 Arcade Modes - Time Attack, 5x5 Huge, No Mercy, Goose.
- **Store & Customization**: Integrated Store and 38 custom themes & items.
- **Achievements & Visuals**: 31 unlockable achievements, embedded lo-fi BGM playlist, procedural SFX, and CRT shader.
- **Stats & Settings**: Comprehensive player statistics tracking, 100-move undo stack, and customizable gameplay speed and limits.
- **Quality of Life**: Auto-save & resume after every move, interactive pause menu, instant theme switching.

*Note: Perhaps a well-known secret sequence of buttons might reveal something special...?*

## Installation on muOS

1. Download the latest `.muxapp` file from the [Releases](https://github.com/saitamasahil/2048plus/releases) page.
2. Move the downloaded file to the `/mnt/mmc/MUOS/ARCHIVE` folder on your SD card.
3. Open Archive Manager on your device and select the file to install.
4. After installation, you'll find an entry called "2048 Plus" in the Applications section.

## Installation on PortMaster

### Method 1: Direct Install via PortMaster
1. Launch the PortMaster application on your handheld.
2. Go to All Ports or Ready to Run and search for `2048 Plus`.
3. Select Install. The game will automatically download and install into your Ports menu.

### Method 2: Offline Autoinstall
1. Download the game's `.zip` release package on your PC from [PortMaster](https://portmaster.games/detail.html?name=2048plus).
2. Place the downloaded `.zip` file directly into the `autoinstall` folder on your SD card for your OS:
   - **muOS:** `/mnt/mmc/MUOS/PortMaster/autoinstall/`
   - **ArkOS:** `/roms/tools/PortMaster/autoinstall/`
   - **AmberELEC / ROCKNIX:** `/roms/ports/PortMaster/autoinstall/`
   - **Knulli:** `/userdata/system/.local/share/PortMaster/autoinstall/`
3. Reinsert the SD card into your device and launch the PortMaster app once.
4. PortMaster will automatically detect the `.zip` file and complete the installation.

## Visual Showcase

<details>
<summary><b>Splash Animation</b></summary>

<br>

<p align="center">
  <img src="splash.webp" alt="Splash Animation" width="500" />
</p>

<p align="center">
  Splash animation dynamically changes colors based on the selected theme.
</p>

</details>

<br>

<details>
<summary><b>Screenshots</b></summary>

<br>

<p align="center">
  <img src="screenshots/screenshot1.png" width="30%" />
  <img src="screenshots/screenshot2.png" width="30%" />
  <img src="screenshots/screenshot3.png" width="30%" />
</p>

<p align="center">
  <img src="screenshots/screenshot4.png" width="30%" />
  <img src="screenshots/screenshot5.png" width="30%" />
  <img src="screenshots/screenshot6.png" width="30%" />
</p>

<p align="center">
  <img src="screenshots/screenshot7.png" width="30%" />
  <img src="screenshots/screenshot8.png" width="30%" />
  <img src="screenshots/screenshot9.png" width="30%" />
</p>

<p align="center">
  <img src="screenshots/screenshot10.png" width="30%" />
  <img src="screenshots/screenshot11.png" width="30%" />
  <img src="screenshots/screenshot12.png" width="30%" />
</p>

</details>

## Controls

| Button | Action |
|--|--| 
| **D-Pad / Left Stick** | Swipe tiles / Navigate Menus / Seek Track (◄ -10s / ► +10s in Jukebox) |
| **A** | Confirm / Select Item / Confirm Powerup Target |
| **B** | Undo Move (Classic & Plus Mode) / Cancel Target / Go Back |
| **X** | Quit to Menu (Pause / Game Over / Victory) |
| **Y** | Cycle Unlocked Themes |
| **L1** | Activate Swap Powerup (Plus Mode) / Activate Shield (Game Over) / Open Jukebox |
| **R1** | Activate Bomb Powerup (Plus Mode) / Activate Shield (Game Over) / Open Store |
| **Select** | Show Coin Balance During Gameplay |
| **Start** | Open Pause Menu / Resume Gameplay |
| **Menu + Start** | Exit the game safely (force quit) |

*Note: Your progress is automatically saved after every move. You can safely close the game and pick up exactly where you left off.*

## Building from Source

To build the package yourself, you should be on a Linux or macOS environment with `bash` and `zip` installed.

*Note: Running `build.sh` will only generate the **muOS package (`.muxapp`)**. PortMaster packages are managed and distributed via the official PortMaster repository.*

1. Clone this repository:
   ```bash
   git clone https://github.com/saitamasahil/2048plus.git
   cd 2048plus
   ```

2. Make sure the build script is executable:
   ```bash
   chmod +x build.sh
   ```

3. Run the build script:
   ```bash
   ./build.sh
   ```

4. The script will bundle the Lua source, the embedded LÖVE runtime, and all assets into a new `.muxapp` file located in the `build/` directory.

## Credits & Acknowledgements

- Original Concept By: [Gabriele Cirulli](https://github.com/gabrielecirulli/2048)
- Android Port Reference: [tpcstld - 2048](https://github.com/tpcstld/2048)
- Built using the [LÖVE Framework](https://love2d.org/)
- Special Thanks: [Egggdoggo](https://github.com/Egggdoggo) & **d98jay** for early feedback, playtesting & incredible support!
- Background Music tracks provided via [Chosic](https://www.chosic.com/) by authors: AudioCoffee, Ghostrifter Official, Purrple Cat, Roa, Sakura Girl, and Tokyo Music Walker.
