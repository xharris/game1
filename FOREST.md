# Forest level

## Ideas

- traps
  - poison gas
    - triggered by pressure plate
    - fills tile quickly
    - fills neighboring tile
    - up to X times
- hide in a barrel
- items
  - sonar: zooms out, shows stuff nearby
  - backpack: +1 inventory size
  - portal: teleport to random cell near exit
- [ ] tapping a direction quickly (joy)/pressing shift (kbm) gives short dash + decaying move speed

## Sequence

### Intro

- [x] player wakes up on ground sitting against tree
- [x] move to stand up

### Enter maze

- [x] player walks right to wood stairs
  - player sees a sign
  - walking up to the sign shows warnings
    - dont die
    - dont fall
- [x] walking into stairs teleports player to next level
- [x] player walks around maze

### Level tile: sword in ground

- [x] there is a sword at least a few blocks away
  - [ ] ...sticking out of the ground
  - [ ] change sword scale when not equipped (too small due to not being affected by player transform)
- [x] player walks into sword to pick it up
  - [x] freeze frame ~~with pose~~
  - [x] sword sound effect
  - [ ] sparkle at tip
  - [ ] masked line moving up sword (the sword is rly shiny)

### Enemy interactions

- [x] there is an enemy the near sword
  - [ ] slime has move_dir cooldown (move, stop, move, stop, etc)
- [x] nearby slime enemy can be attacked with sword
- getting hit
  - screen shake
  - knockback
  - short stun (add to `Shape`)
  - drop a random item
  - flies in random direction

### Sword item

- sword
  - attack to slash in aim_dir, dmgs enemies, knocks back, stuns 0.5, shakes screen
  - holding attack button charges, release for spin for 1s plus, higher mass (change move_dir slower)
    - pressing attack button while spinning increases duration by 1s and spin faster, reduce mass?
  - hitting something at the tip increases attack speed
    - larger charge spin circle?

#### polish

- equip animation
  - thick white line move up sword (masked by sword_shine_mask.png?)
  - expanding circle/shiny cross effect at tip
  - [ ] add smear to sword image to use in swing animation (https://images.squarespace-cdn.com/content/v1/551a19f8e4b0e8322a93850a/1560422875783-WQR4OR11DUMEXPRO9781/17-Sword_Attacks.gif)

### Level tile: sub-maze with holes and enemies

- player continues through maze
- player sees a room missing tiles (can fall through) and has to carefully avoid falling
- there are enemies spread throughout the tiles
  - slime
  - bat
- at the end there is an item...

### Shield item

- shield?
  - tanks one hit every X seconds
