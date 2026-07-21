# Changelog

## [5.0.2]
- Reordered achievements list by category
- Completely overhauled and polished all dynamic background themes for a premium visual experience
- Added dedicated Arcade Modes slide to Tutorial
- Improved line spacing and paragraph layout in Tutorial cards
- Fixed uneven outline border width around 2048 logo in Matrix theme
- Added animated theme name logo morph reveal in header when switching themes

## [5.0.1]
- Offline BGM Integration: Music tracks are now bundled directly in the game package.
- BGM Downloader Removed: Removed the download and delete option from settings.
- BGM Default State: Enabled background music by default.
- Tactician Achievement: Increased requirement to 5 Undos and 5 Swaps in a single Plus Mode game.

## [5.0.0]

### Added
- Background Music: lo-fi background tracks from multiple artists.
- Now Playing Footer Notification: A cross-fade track info reveal in the footer showing current track title, artist, and animated visualizer bars when a song starts playing.
- Pause Menu Integration: Skip music tracks directly by pressing L1 or R1 during pause state.
- High-Tier Achievements: Added 5 new challenge achievements.
- Premium Dynamic Themes: Introduced 5 new themes.

### Changed
- Unified Audio & Haptics settings: Grouped Sound Effects, Background Music, and Haptic Vibration together under a single "Audio & Haptics" settings sub-menu.
- Tutorial Navigation: Simplified footer button actions to B Exit and Y Switch Theme, mapping page navigation exclusively to D-Pad.

### Fixed
- Outline Clipping: Added rendering canvas padding to prevent menu selection pills and footer button outlines from getting cut off at certain resolutions.

## [4.0.4]

### Added
- Continue last played game: Added an option to directly continue the last active game session from the main menu.

### Changed
- Game selection overlay: Widened the game selection overlay to fully cover and hide the main menu footer element when open.

### Fixed
- muOS overlays: Properly initialize the stage overlay system and register the active foreground process to show volume and brightness indicators on muOS.

## [4.0.3]

### Fixed
- Menu Highlights: Corrected the vertical alignment and height of the selection highlight pill to perfectly center the option text and wrap descenders cleanly.
- Footer Controls: Added the missing D-Pad Navigate icon and label to the Arcade Mode selection screen footer.
- Key Badges: Resolved rendering conflict where key badges (DPAD, A, B) were drawn incorrectly as "Y" due to active scissor coordinates clipping canvas drawing operations.

### Updated
- Glyph icon

## [4.0.2]

### Added
- Smooth Edges: Made the splash screen logo, main menu logo, menu highlights, and all footer buttons look clean and smooth on handheld screens.

### Changed
- Controls Help: Updated the footer on the Achievements screen to show that you can switch tabs using the D-Pad.

### Fixed
- Button Centering: Fixed the alignment so that letters (like A, B, and X) sit perfectly inside their button circles.
- Menu Spacing: Adjusted the menu selection bar to have a cleaner height and perfectly balanced gaps above and below.

## [4.0.1]

### Added
- Dynamic particle burst effects for achievement toasts
- Force exit on quit to bypass deadlock

### Updated
- Demolition Expert achievement, Now it requires 10 Bombs to unlock

### Fixed
- Minor gameplay lag during first vibration

## [4.0.0]

### Added
- Added sound in game.
- Added Unified Settings Menu: Sound, Text Size, and other settings under a dedicated Settings sub-menu, simplifying and cleaning up the Main Menu list.
- Added new settings options:
  - Sound: On/Off
  - Gameplay Animation Speed: Choose between Slow, Normal, Fast, or Instant tile sliding speeds.
  - Screen Transitions: Toggle screen transition animations on/off.
  - Undo Limit: Set undo limits to 1-Move, Unlimited, or Disabled for Classic or Huge Mode.
  - Time Attack Max Limit: Set the Time Attack max limit to 30s, 60s or 90s.
  - Vibration: Toggle haptic rumble feedback on supported devices.
  - CRT Shader: Toggle retro curved screen curvature, scanline, and phosphor mask post-processing filters.
- Full Undo History Stack: Refactored the gameplay engine to support unlimited undos up to 100 moves.
- Added smooth sliding visual highlight transitions for card selection highlights on the game mode select menus, with bilinear color morphing and proximity-based icon/text blending.
- Unified Achievements & Statistics: Merged both screens into a single, clean tabbed dashboard with fluid slide transitions, tracking real-time player profile metrics (highest score, highest tile, total time played, games started per mode, moves, merges, power-ups, and undos) persistently.

### Changed
- Relocated Toast Notifications: Toast messages now pop up at the top of the screen instead of the bottom to prevent covering footer controls.

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
