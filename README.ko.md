# 아트록스 파라미터 도구

아트록스(조이맥스) 맵에 저장된 파라미터(유닛 능력치, 업그레이드, 특수능력)를 텍스트로 꺼내 고치고, 고친 값을 일반 게임에서 쓰게 하는 도구 세 개다.

| 도구 | 하는 일 |
|---|---|
| SPM Packer | 맵 파일(`.spm`) 안의 LHA 압축된 맵 데이터를 `.mapdata` 파일로 꺼내고, 고친 것을 다시 넣는다 |
| Parameter Packer | `.mapdata` 의 파라미터를 플레이어별 txt 여덟 개로 꺼내고, 고친 txt 를 다시 넣는다 |
| Parameter Patch | 게임 실행파일을 고쳐 일반 게임에서도 맵의 파라미터와 유닛 배치를 읽게 한다 |

맵 파일 구조는 [docs/spm-format.ko.md](docs/spm-format.ko.md), 파라미터 구조는 [docs/parameter-format.ko.md](docs/parameter-format.ko.md), Parameter Patch 가 고치는 바이트는 [docs/parameter-patch.ko.md](docs/parameter-patch.ko.md) 에 있다.

**호환 버전**: 아트록스 v1.10 빌드 1

<p>
  <img src="docs/screenshots/screenshot-1.jpg" width="480" alt="파라미터를 고친 맵으로 시작한 일반 게임">
</p>
<p>
  <img src="docs/screenshots/screenshot-2.png" width="316" alt="SPM Packer">
  <img src="docs/screenshots/screenshot-3.png" width="316" alt="Parameter Packer">
</p>


## 사용 방법

Releases에서 받은 압축 파일 세 개에 도구가 하나씩 들어 있다. 순서대로 쓰면 된다.

**1. 맵 데이터 꺼내기 (SPM Packer)**

SPM Packer 는 LHA 압축을 GnuWin32 의 [LHa 1.14i](https://gnuwin32.sourceforge.net/packages/lha.htm) 로 처리한다. 거기서 받은 `lha.exe` 를 `lha.ex_` 로 이름을 바꿔 `spm-packer.exe` 옆에 둬야 실행된다.

| 키 | 동작 |
|---|---|
| U | `.spm` 을 고르면 같은 폴더에 `<파일 이름>.mapdata` 를 만든다 |
| P | `.mapdata` 와 `.spm` 을 차례로 고르면 `.spm` 의 압축 부분을 새로 압축한 `.mapdata` 로 바꾼다 |
| S | 아래 형식의 스크립트 txt 를 골라 여러 맵을 한꺼번에 처리한다 |

```
U|C:\maps\mymap.spm
P|C:\maps\mymap.mapdata|C:\maps\mymap.spm
```

게임에 딸린 맵처럼 맵 데이터가 압축되어 있지 않은 맵은 `SPM Header Error!` 가 뜬다. 맵 에디터로 열어 다른 이름으로 저장하면 압축된 형식이 되어 꺼낼 수 있다.

**2. 파라미터 고치기 (Parameter Packer)**

| 키 | 동작 |
|---|---|
| U | `.mapdata` 를 고르고 플레이어 1 엔지니어의 이름(기본값 `엔지니어`)을 넣으면 `<파일 이름>_parameter1.txt` 부터 `_parameter8.txt` 까지 여덟 개를 만든다 |
| P | `_parameter1.txt` 와 `.mapdata` 를 고르고 엔지니어 이름을 넣으면 여덟 개를 전부 써 넣는다 |
| S | 아래 형식의 스크립트 txt 로 여러 개를 한꺼번에 처리한다 |

```
U|C:\maps\mymap.mapdata|엔지니어
P|C:\maps\mymap_parameter1.txt|C:\maps\mymap.mapdata|엔지니어
```

엔지니어 이름은 파라미터 위치를 찾는 기준이라, 맵에서 이름을 바꿨다면 바꾼 이름을 넣는다. 넣을 때는 txt 여덟 개가 모두 있어야 한다. 모든 플레이어에 같은 값을 주려면 하나를 고친 뒤 복사해 번호만 바꾸면 된다.

맵 에디터에서 다시 열어 저장해도 값이 아트록스 기본값으로 돌아가지 않게 하려면 각 항목의 기본설정을 0 으로 둔다. 옛 맵 에디터로 만든 맵은 먼저 맵 에디터의 설정 > 파라미터 화면에서 확인을 눌러 저장한 뒤 쓴다. 특수능력의 유효 시간과 단계 적용 시간은 float 를 비트 그대로 정수로 적은 값이다(30.0 이면 `1106247680`).

다 고쳤으면 SPM Packer 의 P 로 `.mapdata` 를 맵에 다시 넣는다.

**3. 게임에 적용하기 (Parameter Patch)**

실행하면 파일 선택창이 뜬다. UPX 를 푼 `atrox.exe` 를 고르면 그 자리에서 고치고 `Success!` 를 띄운다. 백업 없이 바로 고치므로 미리 복사해 둔다. 정품 `atrox.exe` 는 UPX 로 압축되어 있어서 `upx -d` 로 푼 파일에 써야 한다.

패치한 게임은 방에서 어떤 게임 방식을 고르든 맵의 파라미터와 유닛 배치를 읽는 일반 게임으로 진행한다. 게임에 딸린 시나리오 맵은 패치하지 않은 실행파일로 연다. 멀티플레이는 모두가 같은 맵과 패치한 실행파일을 써야 한다.


## 구현 원리

**SPM Packer 는 헤더를 건너뛰고 LHA 부분만 다룬다.** 맵 파일은 1130바이트 고정 헤더 뒤에 승리 조건, 패배 조건, 브리핑 문자열이 길이와 함께 이어지고, 그다음부터 파일 끝까지가 `-lh5-` 방식 LHA 아카이브다. 문자열 길이를 따라 읽어 아카이브 시작을 찾고, 꺼낼 때는 그 뒤를 `.lzh` 로 떼어 `lha.ex_ x` 로 푼다. 넣을 때는 `lha.ex_ a -1` 로 새로 압축해 원래 맵의 아카이브 앞부분까지에 이어 붙인다.

```gml
lh5_start = file_bin_position(spm_file)
file_bin_seek(spm_file, lh5_start+2)
lh5 = file_bin_read_char(spm_file, 5)
if(lh5=="-lh5-")
{
    ...
    execute_program("lha.ex_", "x -i -w="+chr(34)+string_copy(extract_path, 1, string_length(extract_path)-1)+chr(34)+" "+chr(34)+lh5_path+chr(34), true)
```

**Parameter Packer 는 엔지니어 이름으로 위치를 찾는다.** 파라미터 앞의 맵 데이터 구조를 풀지 않고, MAPDATA 를 처음부터 한 바이트씩 읽으며 플레이어 1 엔지니어의 이름을 찾고 그 8바이트 앞을 시작으로 삼는다. 그 뒤는 플레이어마다 유닛 123개(0xC2바이트씩), 업그레이드 58개(0x20바이트씩), 특수능력 32개(0x24바이트씩)가 고정 크기로 이어지므로, 정해진 순서대로 정수, 짧은 정수, 고정 길이 문자열을 읽어 txt 로 쓰고 같은 순서로 다시 쓴다.

**Parameter Patch 는 실행파일 일곱 군데를 덮어쓴다.** 게임 방식을 정하는 세 자리를 `mov esi, 4` 로 바꿔 늘 유즈맵 방식 값(4)이 들어가게 하고, 이 방식에서 갈라지던 플레이어 설정 블록은 건너뛰고 시작 건물 블록은 돌게 했다. `atrox.pak` 안의 맵을 임시 파일로 꺼내 여는 블록 두 개도 늘 건너뛴다. 오프셋과 바이트는 소스에 10진수로 들어 있다.

```gml
file_bin_seek(atrox, 500538)
file_bin_write_byte(atrox, 190)
file_bin_write_byte(atrox, 4)
file_bin_write_byte(atrox, 0)
file_bin_write_byte(atrox, 0)
file_bin_write_byte(atrox, 0)
file_bin_write_byte(atrox, 144)
```

`0x7A33A`(500538)에 `BE 04 00 00 00 90`, 곧 `mov esi, 4` 와 `nop` 을 쓰는 부분이다.


## 파일

| 경로 | 내용 |
|---|---|
| `source/parameter-patch/parameter-patch.gmk` | Parameter Patch 원본 프로젝트 파일 |
| `source/spm-packer/spm-packer.gmk` | SPM Packer 원본 프로젝트 파일 |
| `source/parameter-packer/parameter-packer.gmk` | Parameter Packer 원본 프로젝트 파일 |
| `source/*/split/` | GmkSplitter로 분해한 텍스트 트리 |
| `docs/spm-format.ko.md` | 맵 파일(SPM) 구조 |
| `docs/parameter-format.ko.md` | 파라미터 구조와 txt 형식 |
| `docs/parameter-patch.ko.md` | Parameter Patch 가 고치는 바이트와 어셈블리 해석 |
| `docs/screenshots/` | 스크린샷 |
| Releases | 도구별 실행 파일과 사용 설명 |


## 크레딧

- SPM Packer 가 부르는 `lha.ex_` 는 GnuWin32 판 LHa 1.14i 의 `lha.exe` 다. LHa for UNIX 는 Masaru Oki 가 만들고 Nobutaka Watazaki, Tsugio Okamoto 가 고쳤으며, Koji Arai 가 autoconf 판으로 정리했다. LHa 라이선스는 소스 없이 실행파일만 배포하는 것을 허용하지 않으므로 GnuWin32 에서 직접 받아 쓴다.
- 메시지 창에 쓰는 GM Windows Dialogs 확장은 Mark Overmars 가 만들어 게임메이커 8 과 함께 배포한 것이다.


## 라이선스

zlib 라이선스다. 자세한 내용은 [LICENSE](LICENSE) 에 있다. 함께 들어 있는 것 중 다른 사람이 만든 라이브러리는 각자의 라이선스를 따른다.
