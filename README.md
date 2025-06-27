# MyQuestSoundHistory

A World of Warcraft addon that announces sounds when questing and maintains quest history.

## Features

### Core Functionality:
- Sound notifications when accepting quests
- History of accepted quests with detailed information
- Display of quest rewards with icons and tooltips
- **NEW**: Display of quest objective items

### Quest Objective Items (New Feature)

The addon now automatically detects and displays items that need to be collected to complete quests. For example, if a quest has an objective "Collect bandanas: 0/12", then:

- The item will be added to the quest database
- In the quest history interface, objective items are displayed in the objectives section
- Each item is shown with an icon, name, and required quantity
- When hovering over an item, a tooltip with item information is displayed
- Items are displayed as icons instead of text descriptions

### Commands

- `/MQSH` - Open addon settings

### Interface

In the quest log, a "History" button appears that opens a window with:
- List of all accepted quests (left side)
- Detailed information about the selected quest (right side):
  - Quest description
  - Quest objectives (text + item icons)
  - Rewards (with icons)
  - **Objective items (with icons and quantities)**

## Installation

1. Copy the `MyQuestSoundHistory` folder to `World of Warcraft/Interface/AddOns/`
2. Restart the game
3. The addon will start working automatically

## Settings

Settings are available via the `/MQSH` command or through the interface menu:
- Enable/disable sound notifications
- Enable/disable quest history

## Version

Current version: 1.2

## Author

MottiDowerro