# Game 1: Maze Dungeon

## Plan

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

## TODO prototype

- [x] create maze
- [x] add entrance/exit/enemy/item/trap locations
- [x] spawn player(s) at entrance
- [x] player cannot walk outside path
- [x] enemies
  - [x] kills player on contact
- items
  - [x] spawn at random tiles
  - [x] collide to pick up
  - [x] sword
    - [x] press `primary` to swing
      - [x] 0 sec: start animation
      - [x] 0.5 sec: create hitbox
      - [x] 0.6 sec: remove hitbox
      - [x] 1 sec: swing off cooldown
    - [x] deals 5 dmg
- [x] aim with mouse

- [ ] levels
  - each level has increased elevation
  - actors can fall off edges of level
  - actors die if they fall below lowest level
  - actors can land on ground of lower level

- [ ] reach exit to go to next floor
  - [ ] add new maze layout
  - [ ] enemies, items, traps
- lighting
- enemy ai
  - chase player
    - know player tile index for X sec (chase timer)
    - having line of sight refreshes duration
    - when within same tile, use tile_path instead of map_path
- traps
  - poison gas
    - triggered by pressure plate
    - fills tile quickly
    - fills neighboring tile
    - up to X times

## After prototyping

- player cannot die, but get knocked off stage and fall to lower floor (or off map and die)

- enemies
- traps
- puzzles
