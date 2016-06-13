# SPM 포맷

아트록스의 맵 파일(`.spm`)은 고정 길이 헤더, 길이가 붙은 문자열 몇 개, 그리고 맵 본체를 LHA 로 압축한 부분으로 이루어진다. 압축을 푼 본체를 이 저장소에서는 MAPDATA(`.mapdata`)라고 부른다. 게임이 붙인 이름은 아니다.

정수는 전부 리틀 엔디언이고 문자열은 CP949 다.


## 고정 헤더 (1130바이트)

| 오프셋 | 크기 | 내용 |
|---|---|---|
| `0x000` | `0x17` | `Superion Map File 1.5` 와 `0D 0A` |
| `0x017` | `0x06` | 날짜로 보이는 값 (추가 확인 대상) |
| `0x01D` | `0x21` | 추가 확인 대상 |
| `0x03E` | `0x20` | 맵 이름. 남는 자리는 0 |
| `0x05E` | `0x400` | 맵 설명. 남는 자리는 0 |
| `0x45E` | `0x08` | 추가 확인 대상 |
| `0x466` | `0x04` | 배경음악 종류로 보이는 값 |

합치면 `0x46A`(1130)바이트다. SPM Packer 는 이 부분을 해석하지 않고 1130 으로 건너뛴다.


## 가변 길이 부분

`0x46A` 부터는 길이가 앞에 붙은 문자열이 이어진다. 문자열은 4바이트 길이 뒤에 그만큼의 바이트가 온다.

| 순서 | 형식 | 내용 |
|---|---|---|
| 1 | 문자열 | 승리 조건 |
| 2 | 문자열 | 패배 조건 |
| 3 | 4바이트 정수 | 브리핑 개수 |
| 4 | 브리핑 × 개수 | 아래 표 |

브리핑 하나는 이렇다.

| 형식 | 내용 |
|---|---|
| 2바이트 정수 | 브리핑 종류 (0 은 대화, 1 은 해설로 보인다) |
| 4바이트 정수 | 항목 개수 |
| 항목 × 개수 | 1바이트 `n` 뒤에 문자열 `n + 1` 개. 대화는 `n` 이 1 이라 말하는 사람과 말하는 내용 두 문자열이 짝을 이루고, 해설은 `n` 이 0 으로 보인다 |

SPM Packer 는 이 구조를 그대로 따라 읽으며 건너뛴다.

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


## LHA 압축 부분

브리핑 다음부터 파일 끝까지가 LHA 아카이브 하나다. 헤더 레벨 1, 압축 방식 `-lh5-` 이고 안에 파일이 하나 들어 있다.

| LHA 시작 기준 | 크기 | 내용 |
|---|---|---|
| `+0` | 1 | 헤더 크기 |
| `+1` | 1 | 헤더 체크섬 |
| `+2` | 5 | 압축 방식 `-lh5-` |
| `+7` | 4 | 압축된 크기 |
| `+11` | 4 | 원래 크기 |
| `+15` | 4 | 시각 |
| `+19` | 1 | 속성 |
| `+20` | 1 | 헤더 레벨 (1) |
| `+21` | 1 | 파일 이름 길이 |
| `+22` | | 파일 이름 |

맵 에디터로 저장한 맵을 보면 파일 이름이 `C:\DOCUME~1\Owner\LOCALS~1\Temp\5D.tmp` 처럼 저장할 때 쓴 임시 파일 경로다. 그 맵의 MAPDATA 는 1,473,311바이트이고 압축된 크기는 49,355바이트다.

SPM Packer 는 `+2` 에서 `-lh5-` 를 확인하고, `+21` 의 길이로 파일 이름을 읽어 압축을 푼 뒤 그 파일을 `<맵 이름>.mapdata` 로 바꾼다. 다시 넣을 때는 MAPDATA 를 `lha a -1` (헤더 레벨 1)로 압축하고, 원래 맵의 처음부터 LHA 시작 직전까지에 새 아카이브를 이어 붙인다.


## 압축되지 않은 맵

게임에 딸린 `maps` 폴더의 맵 15개는 브리핑 다음 자리에 LHA 헤더가 없고 다른 데이터가 이어진다. 옛 맵 에디터로 만든 맵으로 보인다. 이런 맵은 SPM Packer 가 `SPM Header Error!` 를 낸다. 맵 에디터로 열어 다른 이름으로 저장하면 LHA 로 압축된 형식으로 저장된다.

MAPDATA 안의 파라미터 구조는 [parameter-format.ko.md](parameter-format.ko.md) 에 있다.
