# SPM format

An Atrox map file (`.spm`) consists of a fixed-length header, a few length-prefixed strings, and the map body compressed with LHA. This repository calls the decompressed body MAPDATA (`.mapdata`). The name is not one the game uses.

All integers are little endian and strings are CP949.


## Fixed header (1130 bytes)

| Offset | Size | Contents |
|---|---|---|
| `0x000` | `0x17` | `Superion Map File 1.5` followed by `0D 0A` |
| `0x017` | `0x06` | Looks like a date (left for further investigation) |
| `0x01D` | `0x21` | Left for further investigation |
| `0x03E` | `0x20` | Map name, padded with 0 |
| `0x05E` | `0x400` | Map description, padded with 0 |
| `0x45E` | `0x08` | Left for further investigation |
| `0x466` | `0x04` | Looks like the background music type |

Together that is `0x46A` (1130) bytes. SPM Packer does not parse this part and simply skips 1130 bytes.


## Variable-length part

From `0x46A` on, length-prefixed strings follow. A string is a 4-byte length followed by that many bytes.

| Order | Format | Contents |
|---|---|---|
| 1 | String | Victory condition |
| 2 | String | Defeat condition |
| 3 | 4-byte integer | Number of briefings |
| 4 | Briefing x count | See the table below |

A briefing looks like this.

| Format | Contents |
|---|---|
| 2-byte integer | Briefing type (0 looks like dialogue, 1 like narration) |
| 4-byte integer | Number of items |
| Item x count | A 1-byte `n` followed by `n + 1` strings. For dialogue `n` is 1 and the two strings pair the speaker with the line. For narration `n` looks to be 0 |

SPM Packer follows this structure as it reads and skips.

```gml
//Static Size
file_bin_seek(spm_file, 1130)

//Win & Lose
length = file_bin_read_int(spm_file)
file_bin_seek(spm_file, file_bin_position(spm_file)+length) //Win
length = file_bin_read_int(spm_file)
file_bin_seek(spm_file, file_bin_position(spm_file)+length) //Lose

//Briefing
max_number = file_bin_read_int(spm_file)
repeat(max_number)
{
    type = file_bin_read_short(spm_file)
    number = file_bin_read_int(spm_file)
    repeat(number)
    {
        string_number = file_bin_read_byte(spm_file)
        repeat(string_number+1)
        {
            length = file_bin_read_int(spm_file)
            file_bin_seek(spm_file, file_bin_position(spm_file)+length)
        }
    }
}
```


## LHA part

From after the briefings to the end of the file is a single LHA archive. It uses header level 1 and the `-lh5-` method, and holds one file.

| From LHA start | Size | Contents |
|---|---|---|
| `+0` | 1 | Header size |
| `+1` | 1 | Header checksum |
| `+2` | 5 | Method `-lh5-` |
| `+7` | 4 | Compressed size |
| `+11` | 4 | Original size |
| `+15` | 4 | Time |
| `+19` | 1 | Attribute |
| `+20` | 1 | Header level (1) |
| `+21` | 1 | File name length |
| `+22` | | File name |

In a map saved with the map editor, the file name is the temporary file path used while saving, such as `C:\DOCUME~1\Owner\LOCALS~1\Temp\5D.tmp`. The MAPDATA of that map is 1,473,311 bytes and its compressed size is 49,355 bytes.

SPM Packer checks for `-lh5-` at `+2`, reads the file name using the length at `+21`, extracts the archive, and renames the file to `<map name>.mapdata`. To put it back, it compresses the MAPDATA with `lha a -1` (header level 1) and appends the new archive to the original map from the start up to just before the old archive.


## Uncompressed maps

The 15 maps in the game's `maps` folder have no LHA header after the briefings, and other data follows instead. They look like maps made with an old version of the map editor. SPM Packer reports `SPM Header Error!` for such maps. Opening one in the map editor and saving it under a new name stores it in the LHA compressed form.

The structure of the parameters inside MAPDATA is in [parameter-format.md](parameter-format.md).
