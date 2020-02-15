# suro

A tiny batch-file surrogate.

## What problem does it solve ?

In the absence of *hard links* on my windows box, I need something to allow me to create an alias for a command. Also I dislike being required to change my PATH variable for every new app, so it would be perfect to have one folder in the PATH containing all my aliases.

## How do you use it ?

Let's say you have downloaded some zip file with the latest version of some tool. You unzip it somewhere so that the binary is located in e.g. `C:\stuff\portable\tool-version-XYZ\tool.exe`. Now you copy `suro.exe` somewhere else and rename it `tool.exe`. Lastly you add a file to it called `tool.path` and put the path to the binary in it, so that in this example the first line would read `C:\stuff\portable\tool-version-XYZ\tool.exe`.

## Again, why bother ?

Without `suro` you would have to copy the tool's binary around, which wouldn't work if the binary relied on DLLs located in its exe's folder. You would have to copy the DLLs into your PATH somewhere, but now these DLLs could interfere with other programs, imposing precedence over DLLs lower in the PATH.

Another way would be to create a BAT or a symbolic LNK. But a `tool.bat` or a `tool.lnk` are not EXEs, and there are situations where you need them to be EXEs (e.g. command completion).
