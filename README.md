# 2048 Plus for muOS

<p align="center">
  <img src="demo.webp" alt="Gameplay Animation" width="400" />
</p>

A feature-packed implementation of the classic puzzle game 2048 for muOS, built using the LÖVE framework.

This project is inspired by and references the popular open-source [2048 Android](https://github.com/tpcstld/2048) game by tpcstld, which itself is based on the original web game by Gabriele Cirulli. While taking visual and design references from the Android version, this codebase was written from the ground up in Lua for the LÖVE engine. In addition to the classic gameplay, I have introduced numerous new features, including multiple game modes, an achievement system, and a wide variety of themes to enhance the overall experience.

## Features

- **Game Modes**: Classic, Plus Mode (with Bomb, Swap, and Undo powerups), and 4 Arcade Modes (Time Attack, 5x5 Huge, No Mercy, Goose).
- **Achievements & Themes**: 28 unlockable achievements and total 35 custom themes, with select themes featuring dynamic animated backgrounds.
- **Audio & Visuals**: Embedded lo-fi BGM playlist with track info popups, procedural SFX, CRT shader, and smooth handheld-optimized animations.
- **Stats & Settings**: Comprehensive player statistics tracking, 100-move undo stack, and customizable gameplay speed and limits.
- **Quality of Life**: Auto-save & resume after every move, interactive pause menu, instant theme switching.

*Note: Perhaps a well-known secret sequence of buttons might reveal something special...?*

## Installation on muOS

1. Download the latest `.muxapp` file from the [Releases](https://github.com/saitamasahil/2048-muos/releases) page.
2. Move the downloaded file to the `/mnt/mmc/MUOS/ARCHIVE` folder on your SD card.
3. Open Archive Manager on your device and select the file to install.
4. After installation, you'll find an entry called "2048 Plus" in the Applications section.

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
|D-Pad / Left Stick|Swipe tiles (Move Up, Down, Left, or Right)|
|A|Confirm / Continue / Confirm Powerup Target|
|B|Undo previous move|
|Y|Cycle through unlocked themes|
|L1|Activate Swap Powerup (Plus Mode) / Skip BGM Track (Pause State)|
|R1|Activate Bomb Powerup (Plus Mode) / Skip BGM Track (Pause State)|
|Start / Select|Open Pause Menu (Restart / Quit / Resume)|
|Menu + Start|Exit the game safely (force quit)|

*Note: Your progress is automatically saved after every move. You can safely close the game and pick up exactly where you left off.*

## Building from Source

To build the package yourself, you should be on a Linux or macOS environment with `bash` and `zip` installed. 

1. Clone this repository:
   ```bash
   git clone https://github.com/saitamasahil/2048-muos.git
   cd 2048-muos
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
- Background Music tracks provided via [Chosic](https://www.chosic.com/) by authors: AudioCoffee, Ghostrifter Official, Purrple Cat, Roa, Sakura Girl, and Tokyo Music Walker.
