# Changelog

## [4.0.0]

### Added
- Added sound in game.
- Added Unified Settings Menu: Sound, Text Size, and other settings under a dedicated Settings sub-menu, simplifying and cleaning up the Main Menu list.
- Added five new settings options:
  - Sound: On/Off
  - Gameplay Animation Speed: Choose between Normal, Fast, or Instant tile sliding speeds.
  - Screen Transitions: Toggle screen transition animations on/off.
  - Undo Limit: Set undo limits to 1-Move, Unlimited, or Disabled for Classic or Huge Mode.
  - Time Attack Max Limit: Set the Time Attack max limit to 30s, 60s or 90s.
  - Vibration: Toggle haptic rumble feedback on supported devices.
- Full Undo History Stack: Refactored the gameplay engine to support unlimited undos up to 100 moves.
- Added smooth sliding visual highlight transitions for card selection highlights on the game mode select menus, with bilinear color morphing and proximity-based icon/text blending.

### Changed
- Relocated Toast Notifications: Toast messages now pop up at the top of the screen instead of the bottom to prevent covering footer controls.

### Fixed
- Fixed a bug where closing the selection menu while on Page 1 / Arcade modes and reopening it played transition animations from the previous closed state; selection states now initialize and snap instantly to defaults (Classic on Page 0, Time Attack on Page 1) without sliding or page transition animations.

## [3.0.2]
- Canvas alpha blending overlapping fixed

## [3.0.1]
- Achivement section is now perfectly readable

## [3.0.0]

### Added
- Game Selection Mode: A newly designed, beautifully animated carousel menu screen for seamlessly selecting between Classic, Plus, and Arcade modes.
- Arcade Modes: Introduced a brand-new arcade mode with different game modes to play.
  - Time Attack Mode: A fast-paced new mode where you race against a 60-second countdown clock. Merge larger tiles (32+) to earn crucial time extensions.
  - Huge Mode (5x5): A spacious new board layout featuring a 5x5 grid for a more relaxed play style.
  - No Mercy Mode: A high-tension hardcore challenge where undos and power-ups are disabled, and two new tiles spawn after every single move.
  - Goose Mode: A chaotic fun mode where a silly animated Goose tile waddles around the grid, blocking a random empty cell and walking after every turn. Undos and power-ups are disabled.
- Arcade Achievements & Themes: Each arcade mode now has a dedicated achievement that unlocks an exclusive premium theme with dynamic animated backgrounds.
- Dynamic Backgrounds: Premium themes (Aurora, Nebula, Inferno, Honk, Matrix, Glitch) feature layered, animated background effects like aurora curtains, twinkling starfields, rising embers, water ripples, falling green digital rain, and cyberpunk glitch effects.
- Smooth Screen Transitions: Added crossfade transitions when navigating between screens.

### Changed
- Rebranded and renamed the game to "2048 Plus" across configuration files, launcher scripts, package layouts, and system headings.
- Redesigned and aligned the stacked "2048 PLUS" main menu and gameplay header logos.
- Plus Mode Balancing: Reduced the rate at which power-ups are awarded to make the gameplay significantly more strategic and challenging.
- Demolition Expert Achievement: Reduced the required bomb usage count from 10 to 4 in Plus Mode.

### Fixed
- UI & Stability: Implemented minor user interface enhancements and general bug fixes for a smoother, more polished experience.

## [2.0.2]

### Added
- Main menu heading logo: Re-balanced the main menu layout to include a beautifully styled, dynamically themed 2048 tile logo.
- Version tracking: The version number is now displayed on the About screen.

### Fixed
- Endless Mode layout: Fixed horizontal text overlap with the SCORE box in Large Text mode by dynamically scaling and shifting the label safely.

## [2.0.1]

### Added
- Tactile button animations: Buttons now physically press down when changing menus or unpausing for satisfying retro click feedback.
- Complete help footers: Rebuilt the bottom helper bars on all screens to show a complete list of every available control.
- Added new option to select theme

### Changed
- Spacious score boxes: Increased the SCORE and BEST box sizes in Large Text mode to give numbers plenty of breathing room.

## [2.0.0]

### Added
- Plus Mode: A brand new game mode featuring powerful power-ups like Swap and Bomb to help you get out of tricky situations.
- Achievements System: Added a comprehensive achievements system. Track your progress & view your completed achievements in the new dedicated Achievements menu.
- Themes System & Unlockables: Introduced a massive collection of 18 beautiful themes! Themes are unlocked progressively as you reach higher tiles.
- Dynamic Theme Transitions: Switching themes now features a gorgeous, buttery-smooth circular ripple animation.
- Tutorial: Added a step-by-step tutorial to help new players learn the ropes of both Classic and Plus modes.
- Text Size Options: You can now toggle between Normal and Large text sizes from the main menu for better readability on different screens.
- About Section: Added an About section in the main menu.
- ???: Perhaps a well-known secret sequence of buttons might reveal something special...?

### Changed
- The main menu has been fully restructured to seamlessly accommodate all the new features, modes, and settings.
- UI elements, message boxes, and overlays now perfectly scale and adapt depending on your selected text size.
- Improved rendering precision for the board grid to ensure perfectly symmetrical margins.

---

## [1.0.2]
- Dark Mode Support: Added a beautifully designed dark theme. You can now instantly toggle between the classic Light theme and the new Dark theme at any time by pressing the Y button.
- Interactive Pause Menu: Replacing the old confirmation prompt, pressing Start or Select now brings up a dedicated Pause Menu overlay. This allows you to easily Restart a fresh game, Resume, or cleanly Quit to the OS.

## [1.0.1]
- Added an "Endless Mode" indicator right beneath the 2048 title when you decide to keep playing after reaching the 2048 target tile. This matches the behavior of the original mobile version.

## [1.0.0]
- Initial Release
