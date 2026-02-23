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
- [x] levels
  - [x] each level has increased elevation
  - [x] actors can fall off edges of level
  - [x] actors can land on ground of lower level
  - [x] actors die if they fall below lowest level
- [x] reach exit to go to next floor
  - [x] add new maze layout
  - [x] enemies, items, traps
- [x] simple lighting

- [x] enemy ai
  - [x] vision radius -> chase
  - [x] chase player
    - [~] know player tile index for X sec (chase timer)
    - [~] having line of sight refreshes duration
- traps
  - poison gas
    - triggered by pressure plate
    - fills tile quickly
    - fills neighboring tile
    - up to X times

## Sequence

### Intro

- player wakes up on ground leaning against tree
- tapping a direction quickly (joy)/pressing shift (kbm) gives short dash + decaying move speed

### Enter maze

- player walks right to wood stairs
  - player sees a sign
  - walking up to the sign shows warnings
    - dont die
    - dont fall
- walking into stairs teleports player to next level
- player walks around maze

### Level tile: sword in ground

- there is a sword sticking in the ground at least a few blocks away
- player walks into sword to pick it up
  - freeze frame with pose
  - sword sound effect
  - thick white line move up sword (masked by sprite)
  - rotating circle cross effect at tip

### Enemy interactions

- nearby slime enemies can be attacked with sword
- getting hit makes you drop a random item
  - flies in random direction

### Sword item

- sword
  - attack to slash in aim_dir, dmgs enemies, knocks back, stuns 0.5, shakes screen
  - holding attack button charges, release for spin for 1s plus, higher mass (change move_dir slower)
    - pressing attack button while spinning increases duration by 1s and spin faster, reduce mass?
  - hitting something at the tip increases attack speed
    - larger charge spin circle?

### Level tile: sub-maze with holes and enemies

- player continues through maze
- player sees a room missing tiles (can fall through) and has the carefully avoid falling
- there are enemies spread throughout the tiles
  - slime
  - bat
- at the end there is an item...

### Shield item

- shield?
  - tanks one hit every X seconds

### TODO Traps

### TODO Boss every 3 levels

## After prototyping

### Goals

- smooth combat
  - clear hitboxes
  - animations
- intense bosses
- discover secrets
- well-themed areas (distinct, consistent)
  - forest
  - spooky forest
  - castle
  - corporation (business)
- no puzzles?

  > Instead, set up complex situations.
  > Set up situations where there are various things player want and don't want, but they can't get all the
  > things they want and prevent all the things they don't want. Then, they are put in a position where they
  > make choices about how to navigate the situation to get what they want most while also trying to prevent
  > what they want least.

- lighting/shaders
  - https://www.gamedev.net/tutorials/programming/graphics/dynamic-2d-soft-shadows-r3065/
  - https://frankforce.com/2d-light-mapping/
  - https://blog.frost.kiwi/dual-kawase/

- culling cause why not
