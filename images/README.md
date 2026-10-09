# images/

If a file is missing, the script skips it and still compiles.

| File                    | Used for                          | Size / format       |
|-------------------------|-----------------------------------|---------------------|
| `WizardImage0.bmp`      | Large image of the wizard         | 164 x 314 px, BMP   |
| `WizardSmallImage0.bmp` | Small image (top right corner)    | 55 x 55 px, BMP     |
| `music.mp3`             | Background music in the installer | MP3                 |

## Music tips

If music does not play, try re-encoding it without metadata:

```
ffmpeg -i original.mp3 -vn -map_metadata -1 -c:a libmp3lame -b:a 128k -ar 44100 music.mp3
```
