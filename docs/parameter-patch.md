# Bytes changed by Parameter Patch

Atrox Parameter Patch overwrites seven spots in the chosen executable. It forces the game type value to 4, adjusts two branches that split on type 4 and two blocks that open maps inside `atrox.pak`, and so makes a normal game read the parameters and unit placement of the map file.

The bytes are in `source/parameter-patch/split/Objects/obj_patch.events/Alarm 0.xml` in decimal.

```gml
file_bin_seek(atrox, 500538)
file_bin_write_byte(atrox, 190)
file_bin_write_byte(atrox, 4)
file_bin_write_byte(atrox, 0)
file_bin_write_byte(atrox, 0)
file_bin_write_byte(atrox, 0)
file_bin_write_byte(atrox, 144)
...
```


## Target

| Item | Value |
|---|---|
| Game | Atrox v1.10 build 1 |
| File | UPX-unpacked `atrox.exe` (2,965,504 bytes) |
| md5 | `b4c64c06c2afd830995ef497478718be` |

The retail `atrox.exe` (md5 `01d0c56a04f61ffa40d219eb0378154c`) is packed with UPX and is smaller than these offsets. The patch has to be applied to the file unpacked with `upx -d`.

The image base is `0x400000`, and every change is inside the `.text` section (virtual address `0x401000`, file offset `0x1000`). So **file offset = virtual address - 0x400000**.


## Changed bytes

| Virtual address | File offset | Original bytes | New bytes | Meaning | Decimal offset in source |
|---|---|---|---|---|---|
| `0x0047A33A` | `0x7A33A` | `8B B0 38 04 00 00` | `BE 04 00 00 00 90` | Set game type to 4 | 500538 |
| `0x00484571` | `0x84571` | `8B 74 24 35 81 E6 FF 00 00 00` | `BE 04 00 00 00 90 90 90 90 90` | Set game type to 4 | 542065 |
| `0x004854CD` | `0x854CD` | `8B 74 24 55 81 E1 FF FF 00 00 81 E6 FF 00 00 00` | `81 E1 FF FF 00 00 BE 04 00 00 00 90 90 90 90 90` | Set game type to 4 | 545997 |
| `0x004D882C` | `0xD882C` | `0F 84 30 01 00 00` | `E9 31 01 00 00 90` | Always skip the pak map block | 886828 |
| `0x004D917E` | `0xD917E` | `0F 85 58 01 00 00` | `E9 59 01 00 00 90` | Always skip the type 4 player setup block | 889214 |
| `0x004D9776` | `0xD9776` | `0F 84 18 01 00 00` | `E9 19 01 00 00 90` | Always skip the pak map block | 890742 |
| `0x004DA0FE` | `0xDA0FE` | `83 B8 08 01 00 00 04 0F 84 5D 03 00 00` | 13 x `90` | Run the starting building block in type 4 too | 893182 |


## Setting the game type to 4

The game type is stored at `+0x108` of the global object `0x00B1E4C0` returned by `0x004078AB`. The patch changes the three spots that load a value with `mov esi, ...` and then write it with `mov [eax+0x108], esi`. The load was replaced with `mov esi, 4`, so 4 goes in whichever type is chosen. Other code such as `0x004D9177` and `0x004DA0FE` below compares `[eax+0x108]` with 4 and branches, and 4 looks like the value of the use map type, which reads the parameters and unit placement of the map.

```
; 0x0047A33A
0047A33A  8B B0 38 04 00 00     mov  esi, [eax+0x438]   ; original
0047A33A  BE 04 00 00 00 90     mov  esi, 4 ; nop        ; patched
0047A340  E8 66 D5 F8 FF        call 0x004078AB
0047A345  89 B0 08 01 00 00     mov  [eax+0x108], esi

; 0x00484571
00484571  8B 74 24 35           mov  esi, [esp+0x35]     ; original
00484575  81 E6 FF 00 00 00     and  esi, 0xFF
00484571  BE 04 00 00 00        mov  esi, 4              ; patched (five nops follow)
0048457B  E8 2B 33 F8 FF        call 0x004078AB
00484580  89 B0 08 01 00 00     mov  [eax+0x108], esi

; 0x004854CD
004854CD  8B 74 24 55           mov  esi, [esp+0x55]     ; original
004854D1  81 E1 FF FF 00 00     and  ecx, 0xFFFF
004854D7  81 E6 FF 00 00 00     and  esi, 0xFF
004854CD  81 E1 FF FF 00 00     and  ecx, 0xFFFF         ; patched
004854D3  BE 04 00 00 00        mov  esi, 4              ; (five nops follow)
004854DD  89 0D 90 4E C6 00     mov  [0x00C64E90], ecx
004854E3  E8 C3 23 F8 FF        call 0x004078AB
004854E8  89 B0 08 01 00 00     mov  [eax+0x108], esi
```

The third spot has an `and` on `ecx` in the middle, so that instruction was moved up and `mov esi, 4` placed after it.


## Skipping the pak map block

`0x004D882C` and `0x004D9776` sit in two functions of the same shape. When a value on the stack is nonzero, they build a `Maps\%s` path with `wsprintfA`, read that map from the game data object (`0x00C70720`), copy it into a temporary file made with `GetTempPathA` / `GetTempFileNameA` (or `C:\Dump.tmp` if that fails), and open it. This looks like the path that opens maps inside the bundled `atrox.pak`. The conditional jump was turned into an unconditional one, so the code always takes the next path (the one that opens the map file directly).

```
004D881E  8B 84 24 54 2E 00 00  mov  eax, [esp+0x2E54]
...
004D8828  85 C0                 test eax, eax
004D882A  F3 A4                 rep movsb
004D882C  0F 84 30 01 00 00     je   0x004D8962         ; original
004D882C  E9 31 01 00 00 90     jmp  0x004D8962         ; patched
004D8832  53                    push ebx
004D8833  8D 8C 24 B0 01 00 00  lea  ecx, [esp+0x1B0]
004D883A  68 88 8F 62 00        push 0x00628F88         ; "Maps\%s"
004D883F  51                    push ecx
004D8840  FF D5                 call ebp                ; wsprintfA (loaded at 0x004D87CF)
```

`0x004D9776` has the same form (`je 0x004D9894` → `jmp 0x004D9894`).


## Skipping the type 4 player setup

Just before `0x004D917E`, 96 bytes (12 bytes x 8 players) are read from the map file with `ReadFile`, and only when the game type is 4 are they used to fill fields of the eight players (`+0x110`, `+0x634`, `+0x638`, `+0x63C`). After the patch the type is always 4, so the `JNZ` became a `JMP` that always skips this block.

```
004D9168  6A 60                 push 0x60               ; 96 bytes
004D916A  8D 4C 24 50           lea  ecx, [esp+0x50]
004D916E  51                    push ecx
004D916F  57                    push edi
004D9170  FF D3                 call ebx                ; ReadFile (loaded at 0x004D89B4)
004D9172  E8 34 E7 F2 FF        call 0x004078AB
004D9177  83 B8 08 01 00 00 04  cmp  dword [eax+0x108], 4
004D917E  0F 85 58 01 00 00     jnz  0x004D92DC         ; original
004D917E  E9 59 01 00 00 90     jmp  0x004D92DC         ; patched
```


## Creating the starting building in type 4 too

The compare and conditional jump at `0x004DA0FE` skip the following block when the game type is 4. That block picks one of `0x2B`, `0x3A`, and `0x49` by the race value (`[esi+0x130C4]`), creates a building, and casts it to `CGERBuilding` (RTTI). It looks like the code that creates the starting building of a normal game. The 13 bytes of the compare and jump became `NOP`s so the block runs in type 4 as well.

```
004DA0F9  E8 AD D7 F2 FF        call 0x004078AB
004DA0FE  83 B8 08 01 00 00 04  cmp  dword [eax+0x108], 4   ; NOP in the patch
004DA105  0F 84 5D 03 00 00     je   0x004DA468             ; NOP in the patch
004DA10B  8B 86 C4 30 01 00     mov  eax, [esi+0x130C4]
004DA111  6A 00                 push 0
004DA113  68 D8 B8 62 00        push 0x0062B8D8             ; CGERBuilding type descriptor
004DA118  C7 84 24 AC 00 00 00 2B 00 00 00  mov [esp+0xAC], 0x2B
004DA123  C7 84 24 B0 00 00 00 3A 00 00 00  mov [esp+0xB0], 0x3A
004DA12E  C7 84 24 B4 00 00 00 49 00 00 00  mov [esp+0xB4], 0x49
004DA139  C7 84 24 B8 00 00 00 00 00 00 00  mov [esp+0xB8], 0
004DA144  8B 94 84 AC 00 00 00  mov  edx, [esp+eax*4+0xAC]
```

What the three blocks actually create and read (the meaning of each field, the building type numbers) is left for further investigation.


## Behavior after the patch

- Whatever game type is chosen in the room, the game runs as type 4, so types such as fusion and survival (퓨전, 서바이벌) play like a normal game.
- The block that opens maps inside `atrox.pak` is skipped, so maps are used as `.spm` files in the maps folder. The scenario maps that come with the game are opened with an unpatched executable.
- The server and clients must use the same map and the same patch.
