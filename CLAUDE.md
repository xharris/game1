- This project uses the following frameworks:
  - [Love2d 11.5](https://love2d.org/wiki/love)
- The goal and tasks of this project is outlined in `README.md`
- Logs are printed to `logs.txt`
- Do not implement `TODO` unless explicitly asked to
- Avoid using `goto`

## Coding Style

- `local fn = function()` instead of `function fn()`

## Project Structure

### Entry Point

`main.lua` — sets up globals (`vec2`, `game`, `log`, `lume`, `events`), initializes the window via `shove`, and drives the Love2D loop (`love.load` → `state.load`, `love.update`, `love.draw`). `api.update` and `api.draw` are called every frame.

### Key Files

| File                 | Purpose                                                                                                                                                          |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `game.lua`           | Global constants and mutable state: `TILE`, `LEVEL_ALT=50`, `LEVEL_CELL_SIZE`, `LEVEL_TILE_SIZE`, `game.actors[]`, `game.levels[]`, `LEVELS[]` (level templates) |
| `types.lua`          | LuaLS type annotations: `Actor`, `Level`, `LevelCell`, `Shape`, `Item`, `Ai`, etc.                                                                               |
| `api.lua`            | Core engine: actor management, bump physics world, level management, z-sort rendering                                                                            |
| `actors.lua`         | Actor factory functions: `player(n)`, `slime()`, `item()`, `sword()`                                                                                             |
| `events.lua`         | Simple pub/sub: `events.level.added`, `events.status_effect.applied/removed`                                                                                     |
| `animation.lua`      | Tween-based animation timeline system                                                                                                                            |
| `animations.lua`     | Named animation sequences (sit, stand, hand_idle, etc.)                                                                                                          |
| `status_effects.lua` | Status effect tick/apply/remove logic (e.g. `sleeping`, `stunned`)                                                                                               |
| `input.lua`          | Input abstraction (`input:get 'move'`, `input:down 'primary'`, etc.)                                                                                             |
| `hitbox.lua`         | Debug hitbox rendering                                                                                                                                           |
| `light.lua`          | Dynamic 2D lighting                                                                                                                                              |
| `camera.lua`         | Camera with position smoothing                                                                                                                                   |

### Directories

- `states/` — game states loaded by `game.STATE`; currently `states/play.lua` is active (`states/animation_test.lua` is alternate)
- `render/` — per-component renderers called by `draw_actor`: `sprite.lua`, `hands.lua`, `level_cell.lua`
- `items/` — item modules loaded by name; each exports `item()`, `sprite()`, and optionally `equip()`, `activate()`
- `assets/` — image files; paths declared in `assets.lua`
- `lib/` — third-party libs: `bump` (AABB physics), `tick` (timers/delays), `lume` (utilities), `vector` (vec2), `tween`, `lua-star` (A\* pathfinding), `shove` (viewport scaling)

### Actor System

- All actors live in `game.actors[]` (z-sorted each frame)
- `add_actor(a)` / `remove_actor(a)` manage `game.actors`, `actor_groups`, `actor_factions`, and the bump world
- Groups: `'level_cell'`, `'player'` — retrieved with `get_group(group)`
- Factions: `'human'`, `'wild_aggro'` — used for AI targeting
- Key actor fields: `pos` (vec2), `vel`, `alt` (elevation), `z` (draw order base), `y_sort` (use `pos.y` for z instead of `z`), `shape`, `sprite`, `group`, `faction`, `ai`, `inventory`, `status_effects`

### Level System

- Levels are added with `api.level.add(next_level)` and stored in `game.levels[]`
- Each level has `alt = level_idx * LEVEL_ALT` (50 per level); altitude increases upward visually (rendered as `pos.y - alt`)
- Level tiles (`group='level_cell'`) use `z = -100`, `y_sort = true`
- `TILE`: `none=0`, `ground=1`, `entrance=2`, `exit=3`
- `enter_level(level_idx, a)` places an actor at a level's entrance tile (first visit only) and sets `a.alt`
- The level exit actor (stairs sprite) is created in `add_level`; it triggers `enter_level` on collision
- `alt` should only be used as a visual offset

### Z-Sorting / Rendering

- `get_z(a)`: returns `a.pos.y` if `a.y_sort=true`, else `a.z`
- Actors are sorted ascending by `get_z` so higher-y (lower on screen) actors draw on top
- `draw_actor` renders via the `renderers` pipeline: level tile → back hands → sprite → front hands → hitbox
- Each actor is drawn at screen position `(pos.x, pos.y - alt)` to simulate elevation

### Globals (set in main.lua)

`vec2`, `game`, `log`, `lume`, `events` are available everywhere without `require`.
