# Parameter format

The parameters in the Atrox map editor come in three groups: unit stats, upgrades, and special abilities. The MAPDATA you get by decompressing the LHA part of a map file ([spm-format.md](spm-format.md)) holds them for all eight players, one after another.

All integers are little endian and strings are CP949.


## Position

The structure of the map data before the parameters has not been fully worked out yet. So instead of a fixed offset, Parameter Packer searches for the name string of the Engineer, the first unit of player 1, and takes the position 8 bytes before it as the start. This is because two 4-byte fields (default settings, default name) come before the name.

```gml
para_pos = file_bin_position(data_file)-string_length(find_string)-8
```

In one map saved with the map editor, the parameters started at `0x1297DC` and ended at `0x15DF8C` of a 1,473,311-byte MAPDATA.


## Overall layout

```
Player 1 unit stats         0xC2 x 123 = 0x5D36 bytes
Player 1 upgrades           0x20 x 58  = 0x740 bytes
Player 1 special abilities  0x24 x 32  = 0x480 bytes
Player 2 unit stats
...
Player 8 special abilities
```

One player takes `0x68F6` (26,870) bytes and eight players `0x347B0` bytes. There is no gap between players.


## Unit stats (0xC2 bytes)

The item names are the labels Parameter Packer writes, in Korean, with an English gloss.

| Offset | Size | Item | Format |
|---|---|---|---|
| `+0x00` | 4 | 기본설정 (default settings) | Integer |
| `+0x04` | 4 | 기본이름 (default name) | Integer |
| `+0x08` | 100 | 이름 (name) | String, padded with 0 |
| `+0x6C` | 4 | 체력 (HP) | Integer |
| `+0x70` | 4 | 장갑 (armor) | Integer |
| `+0x74` | 4 | 방어력 (defense) | Integer |
| `+0x78` | 2 | 시간 (time) | Integer |
| `+0x7A` | 2 | 뮤온 (muon) | Integer |
| `+0x7C` | 2 | 쿼크 (quark) | Integer |
| `+0x7E` | 20 | 대지공격 (ground attack type) | String (`일반` normal, `충격` impact, `관통` piercing, `폭발` explosive) |
| `+0x92` | 4 | 대지기본 (ground base) | Integer |
| `+0x96` | 4 | 대지추가 (ground bonus) | Integer |
| `+0x9A` | 4 | 대지히트 (ground hits) | Integer |
| `+0x9E` | 20 | 대공공격 (air attack type) | String |
| `+0xB2` | 4 | 대공기본 (air base) | Integer |
| `+0xB6` | 4 | 대공추가 (air bonus) | Integer |
| `+0xBA` | 4 | 대공히트 (air hits) | Integer |
| `+0xBE` | 4 | 맵에등장 (appears on map) | Integer |

Default settings is 1 to use the Atrox default stats and 0 to use the values written in the map. Default name decides the name the same way. Appears on map is 1 if the unit appears and 0 if it does not.

The first unit of player 1 in the map above looks like this.

| Item | Value |
|---|---|
| Default settings / default name | 1 / 1 |
| Name | 엔지니어 (Engineer) |
| HP / armor / defense | 50 / 50 / 0 |
| Time / muon / quark | 20 / 50 / 0 |
| Ground attack type / base / bonus / hits | 충격 / 0 / 0 / 1 |
| Air attack type / base / bonus / hits | 충격 / 7 / 0 / 1 |
| Appears on map | 1 |


## Upgrades (0x20 bytes)

Eight 4-byte integers.

| Offset | Item |
|---|---|
| `+0x00` | Use default settings (0 / 1) |
| `+0x04` | Time base |
| `+0x08` | Time bonus |
| `+0x0C` | Muon base |
| `+0x10` | Muon bonus |
| `+0x14` | Quark base |
| `+0x18` | Quark bonus |
| `+0x1C` | Can be researched (0 / 1) |


## Special abilities (0x24 bytes)

Nine 4-byte values. The seventh and eighth are 32-bit floats that allow fractions.

| Offset | Item | Format |
|---|---|---|
| `+0x00` | Use default settings (0 / 1) | Integer |
| `+0x04` | Energy cost | Integer |
| `+0x08` | Effect / damage / speed | Integer |
| `+0x0C` | Increment | Integer |
| `+0x10` | Range | Integer |
| `+0x14` | Area of effect | Integer |
| `+0x18` | Duration | float |
| `+0x1C` | Step time | float |
| `+0x20` | Enabled (0 / 1) | Integer |

In the map above, the duration slot holds values such as `0x41F00000` (30.0) and `0x3F333333` (0.7), and the step time slot holds values such as `0x3F000000` (0.5) and `0x3E99999A` (0.3).


## Text format of Parameter Packer

Parameter Packer writes one file per player, from `<MAPDATA name>_parameter1.txt` to `_parameter8.txt`. Each file is laid out in this order.

1. 123 units. For each unit, 18 lines of the form `label    value` in the order of the table above, then one empty line.
2. 58 upgrade lines. Each line has eight values separated by four spaces.
3. One empty line.
4. 32 special ability lines. Each line has nine values.

```
기본설정    1
기본이름    1
이름        엔지니어
체력        50
...
맵에등장    1

1    60    0    100    0    100    0    1
...
```

Every 4-byte value is read and written as an integer, so the two float slots of the special abilities come out as integers with the same bits. 30.0 is `1106247680` and 0.7 is `1060320051`. When you edit them, you also have to convert floats to integers the same way.

When the values are put back, the value on each line is whatever follows the first space, minus any leading spaces. So labels must not contain spaces, while spaces inside the name value are kept. In upgrade and special ability lines, each run of four spaces is replaced with one space and the line is then split on single spaces.
