See [minecraft-silicon](https://github.com/tagavari/minecraft-silicon) for an easy-to-use GUI for patching Minecraft versions

# Minecraft arm64

This utility patches Minecraft versions to use lwjgl libraries compiled for arm64.

Usage:
```
minecraft-arm64 [version folder]
```

## Example to run Minecraft 1.18.1 on arm


Run this command to generate a version called 1.18.1-arm:
```
minecraft-arm64 "~/Library/Application Support/minecraft/versions/1.18.1"
```

Restart Minecraft Launcher, and create a new profile with this version. Be sure to also specify an arm64-compatible JDK.
