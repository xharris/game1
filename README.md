# Game 1: Maze Dungeon

**TODO**

- [x] create maze
- [x] add entrance/exit/enemy/item/trap locations
- [x] spawn player(s) at entrance
- [x] player cannot walk outside path
- enemies
  - kills player on contact
  - shoots killing projectile at player
- items
- traps
- exit win
- lighting
- enemy ai
  - chase player
    - know player tile index for X sec (chase timer)
    - having line of sight refreshes duration
    - when within same tile, use tile_path instead of map_path

**Goal** exit the maze

**Helpers**

- Items
  - Utility item
    - sonar (cd)
    - backpack (+1 item)
    - portal to random tile near exit
  - Offensive item
    - fireball (x3, cd)
  - Defensive item
    - dmg negate (x1)
    - invisible (timer)
    - hide in barrel
- Puzzle reward (1-2)
  - Exit direction hint
  - Item

**Hurters**

- Enemies
  - cone of vision
  - know player position for X sec
  - patrol last known position for X sec
  - give up and return to patrol spot after X sec
- Traps
  - Poison gas flood fill (temp, large)
  - Fire flash fill (periodic, small)
- Events
  - Water (pushes everything)

## Puzzles

- Key + Chest
