# SkinViewer
Simple Minecraft skin-viewer made with LÖVE, and g3d (https://github.com/groverburger/g3d)

![Preview Image, steve](/img0.png)

### Features
- Vanilla lighting and models
- Automatically refresh skin file when focusing the window
- Toggleable head and walk animations
- Slim and Wide skin types

## Automatic Refresh
You can toggle refreshing the skin file by pressing `r`, when on the program will search and reload the `skin.png` file at the root folder of the exe.

![Preview Image, editing of an armor texture](/img1.png)

If you use the `.love` package you will need to use the `--fused` argument, the `skin.png` will be searched within the folder the `.love` package is in.
