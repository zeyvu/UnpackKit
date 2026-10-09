# tools/

The FreeArc / lolz builds are
third-party binaries and are **not** included in the repository: copy them here
yourself.

Tested on **FreeArc 0.67** and **lolz22c4b**

Github Repo with FreeArc 0.67: [xtool](https://github.com/Razor12911/xtool)
You can get lolz on archive.org: [lolz22c4b](https://web.archive.org/web/20231116133740/http://nishi.dreamhosters.com/prof/lolz22c4b.7z)

Expected layout:

```
tools/
|-- arc.exe          <- compressor build (used by compress.bat)
|-- ...              <- whatever else that build needs (DLLs, arc.ini)
`-- unpack/
    |-- arc.exe      <- decompressor build with lolz support
    `-- ...          <- whatever else that build needs (DLLs, arc.ini)
```

- `compress.bat` runs `tools\arc.exe`.
- `decompress.bat` runs `tools\unpack\arc.exe`.
- The installer bundles only `tools\unpack\*` and runs `arc.exe` from there.

`tools\unpack` must be self-contained: the installer copies that folder to a
temporary location and runs it from there.
