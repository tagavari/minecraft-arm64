//
//  os.swift
//  Minecraft arm64
//
//  Created by Cole Feuer on 2021-12-26.
//

import Foundation

///The ID of the current operating system, as used by Minecraft Launcher
#if os(macOS)
let launcherOSID = "osx"
#elseif os(Linux)
let launcherOSID = "linux"
#elseif os(Windows)
let launcherOSID = "windows"
#endif

///The ID of the current operating system, as used by LWJGL
#if os(macOS)
let lwjglOSID = "macos"
#elseif os(Linux)
let lwjglOSID = "linux"
#elseif os(Windows)
let lwjglOSID = "windows"
#endif
