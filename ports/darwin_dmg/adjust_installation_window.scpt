tell application "Finder"
    tell disk "Rakudo_Star"
        open

        set top_left_X     to 100
        set top_left_Y     to 100
        set bottom_right_X to 600
        set bottom_right_Y to 500

        tell container window
            set current   view    to icon view
            set toolbar   visible to false
            set statusbar visible to false
            set bounds            to { top_left_X, top_left_Y, bottom_right_X, bottom_right_Y }
        end tell

        make new alias file at container window to POSIX file "/Applications" with properties { name:"Applications" }

        set  opts to the icon view options of container window
        tell opts
            set icon size   to 128
            set text size   to  16
            set arrangement to not arranged
        end tell

        set position of item "Rakudo_Star"        to {120,  74}
        set position of item "Applications"       to {360,  74}
        set position of item "HOW_TO_INSTALL.txt" to {120, 264}

        delay 5
        close
        delay 5
        open
        delay 5

    end tell
end tell
