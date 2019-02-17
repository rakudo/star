#! /usr/bin/swift

import Darwin
import Cocoa

func die(_ msg: String) {
    fputs("\(msg)\n", stderr)
    exit(1)
}

let name = CommandLine.arguments[0]

/*
 * We don't do anything with the 'set' at the moment; it's just there to
 * reserve a space for a subcommand to allow for future expansion without
 * changing the interface.
 */
if CommandLine.argc == 4 && CommandLine.arguments[1] == "set" {
    let target_file = CommandLine.arguments[2]
    let icon_file_name = CommandLine.arguments[3]

    if let icon = Cocoa.NSImage.init(contentsOfFile: icon_file_name) {
        if !NSWorkspace.shared.setIcon(icon, forFile: target_file) {
            die("Failed to set icon for '\(target_file)'")
        }
    }
    else {
        die("Failed to read icon file '\(icon_file_name)'")
    }
}
else {
    die("Usage: \(name) set FILE ICON_FILE")
}
