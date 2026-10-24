#!/usr/bin/env bash
# Runs cava on Firefox's audio ONLY (not the whole system).
#   usage: firefox-cava.sh <cava-config-template> <name>
# parec captures Firefox's own playback stream into a fifo; cava reads the fifo.
# Started/stopped by shell.qml — no need to run it by hand.

TEMPLATE="$1"
NAME="$2"
APP_BINARY="firefox"                 # application.process.binary to follow
FIFO="/tmp/qs-cava-$NAME.fifo"
CONF="/tmp/qs-cava-$NAME.conf"

[[ -p "$FIFO" ]] || { rm -f "$FIFO"; mkfifo "$FIFO"; }
sed "s|@FIFO@|$FIFO|" "$TEMPLATE" > "$CONF"

# index of the first un-paused sink input that belongs to $APP_BINARY
find_stream() {
    pactl list sink-inputs 2>/dev/null | awk -v app="$APP_BINARY" '
        function check() {
            if (idx != "" && corked == "no" && bin == app && !found) { print idx; found = 1 }
        }
        /^Sink Input #/ { check(); idx = substr($3, 2); corked = ""; bin = ""; next }
        /^[[:space:]]+Corked:/ { corked = $2 }
        /application.process.binary =/ { b = $0; sub(/.*= "/, "", b); sub(/".*/, "", b); bin = b }
        END { check() }
    '
}

# attach parec to Firefox's stream, re-attach when it changes; exits when the wrapper is gone
feed() {
    local parent="$1" current="" pid="" idx
    trap '[[ -n "$pid" ]] && kill "$pid" 2>/dev/null; exit 0' TERM INT HUP
    while kill -0 "$parent" 2>/dev/null; do
        if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then pid=""; current=""; fi
        idx="$(find_stream)"
        if [[ -n "$idx" && "$idx" != "$current" ]]; then
            [[ -n "$pid" ]] && kill "$pid" 2>/dev/null
            parec --monitor-stream="$idx" --format=s16le --rate=44100 --channels=2 --latency-msec=30 > "$FIFO" 2>/dev/null &
            pid=$!
            current="$idx"
        elif [[ -z "$idx" && -n "$pid" ]]; then
            kill "$pid" 2>/dev/null
            pid=""; current=""
        fi
        sleep 2 & wait $!            # interruptible sleep so shutdown is instant
    done
    [[ -n "$pid" ]] && kill "$pid" 2>/dev/null
}

feed $$ &
FEEDER=$!

cava -p "$CONF" &
CAVA=$!

cleanup() { kill "$FEEDER" "$CAVA" 2>/dev/null; }
trap 'cleanup; exit 0' TERM INT HUP
trap cleanup EXIT

wait "$CAVA"
