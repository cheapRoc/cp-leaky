#!/bin/sh

_log() {
    echo "$(date -u '+%Y-%m-%d %H:%M:%S') cp-leaky: $@"
}

while true; do
    OUT=$(head /dev/urandom | base64 - | head -c 128; echo '')
    _log "-- Begin"
    echo $OUT
    _log "-- End"
    sleep 10
done
