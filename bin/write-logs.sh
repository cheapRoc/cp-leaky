#!/bin/sh

_log() {
    echo "$(date -u '+%Y-%m-%d %H:%M:%S') cp-leaky: $@"
}

OUT=$(head /dev/random | base64 - | head -c 128; echo '')

_log "-- Begin"
echo $OUT
_log "-- End"
