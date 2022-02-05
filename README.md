# Atari 6502 Mads Assembler Test

## Requirements:

 - Idea with 6502 plugin
 - MADS Assembler
 - Atari800 emulator

## Idea External tools configuration:

- Set working dir to $FileDir$


- Compile:

```
./local/bin/mads $FilePath$ -o:$FileNameWithoutExtension$.xex -p -t:$FileNameWithoutExtension$.lab -l:$FileNameWithoutExtension$.lst
```

- Run:

```
/usr/bin/xterm -iconic -e atari800 -run $FileNameWithoutExtension$.xex
```

