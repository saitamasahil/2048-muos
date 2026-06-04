# 2048 for muOS

<p align="center">
  <img src="screenshot.png" alt="2048 Gameplay Screenshot" width="250" />
</p>

A feature-packed port of the classic puzzle game 2048 for muOS, built using the LÖVE framework.

This project is a direct port of the popular open-source [2048 Android](https://github.com/tpcstld/2048) application by tpcstld, which itself is based on the original web game by Gabriele Cirulli.

## Features

- **Classic & Plus Modes**: Enjoy the original 2048 puzzle experience, or switch to the new Plus Mode which introduces strategic powerups!
- **Plus Mode Powerups**: In Plus Mode, earn Bomb, Swap, and Undo powerups by reaching new tile milestones (128, 256, 512, etc.). Use them to destroy unwanted tiles, swap adjacent tiles, or revert mistakes.
- **Arcade Modes**: Choose from 4 unique game modes — each with its own rules, challenges, and exclusive unlockable themes:
  - **Time Attack**: Race against a 90-second countdown clock. Merge larger tiles (32+) to earn time extensions.
  - **Huge Mode (5x5)**: A spacious 5×5 grid for a more relaxed play style.
  - **No Mercy**: Hardcore mode — no undos, no powerups, two tiles spawn every move.
  - **Goose Mode**: A chaotic mode where a silly Goose tile waddles around the board, blocking random cells.
- **Achievements & Unlockable Themes**: Track your progress by unlocking 22 unique achievements, ranging from reaching high tiles to mastering arcade modes. Completing achievements rewards you with beautifully crafted custom themes — 24 themes total!
- **Dynamic Animated Backgrounds**: Premium themes (Aurora, Nebula, Inferno, Honk) feature layered, animated background effects like aurora curtains, twinkling starfields, rising embers, and water ripples.
- **Themes**: Instantly toggle between unlocked themes with a beautifully animated reveal. Your theme preference is saved automatically!
- **Smooth Screen Transitions**: Enjoy polished crossfade transitions when navigating between screens.
- **Auto-Save & Resume**: Your progress, board state, and score are saved automatically after every move. Close the game anytime and pick up right where you left off.
- **Interactive Pause Menu**: A built-in pause overlay makes it easy to safely quit the app or restart a new game cleanly.
- **Undo System**: Made a mistake? Press `B` to undo your previous move (unlimited in Classic Mode, consumes a powerup in Plus Mode).
- **High Scores**: Automatically tracks and preserves your best score.
- **Accurate Aesthetics**: Uses the exact color palette, typography, and smooth slide/merge animations from the beloved Android version, complete with an elegant glowing win animation.
- **Standalone Package**: Bundled as a standard `.muxapp` package for effortless installation on muOS with dynamic UI scaling for different resolutions.

*Note: Perhaps a well-known secret sequence of buttons might reveal something special...?*

## Installation on muOS

1. Download the latest `.muxapp` file from the [Releases](https://github.com/saitamasahil/2048-muos/releases) page.
2. Move the downloaded file to the `/mnt/mmc/MUOS/ARCHIVE` folder on your SD card.
3. Open Archive Manager on your device and select the file to install.
4. After installation, you'll find an entry called "2048" in the Applications section.

## Controls

**General & Navigation**
- **D-Pad**: Swipe tiles Up, Down, Left, or Right
- **Y**: Cycle through unlocked themes
- **B**: Undo previous move
- **A**: Confirm / Continue
- **Start / Select**: Open Pause Menu to Restart or Quit
- **Menu + Start**: Exit the game safely

**Plus Mode Exclusive Controls**
- **L1**: Activate **Swap** (Use D-Pad to aim, press A to select two adjacent tiles and swap them)
- **R1**: Activate **Bomb** (Use D-Pad to aim, press A to destroy the targeted tile)
- **B**: Activate **Undo** (Consumes an Undo powerup to revert your last move)

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

- Original Web Game: [Gabriele Cirulli](https://github.com/gabrielecirulli/2048)
- Android Port Reference: [tpcstld - 2048](https://github.com/tpcstld/2048)
- Built using the [LÖVE Framework](https://love2d.org/).
