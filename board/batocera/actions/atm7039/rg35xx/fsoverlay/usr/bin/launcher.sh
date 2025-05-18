#!/bin/sh

export SDL_NOMOUSE=1

echo "Launching $1 $2"

"$1" "$2" &

emu_pid=$!

while true; do
    sleep 2

    # Check if process is still running
    if ! kill -0 $emu_pid 2>/dev/null; then
        echo "Emulator ended, returning to simplermenu+"
        simplermenu_plus &
        exit
    fi
done

