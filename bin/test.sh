#!/bin/bash

now=$(date +%s)

run-with-config() {
    name=$1
    docker run -d \
           --name "$name" \
           -v "$(pwd):/minimal" \
           --link containerpilot_consul:consul \
           leaky \
           /minimal/containerpilot -config "/minimal/${name}.json5"
}

do-pmap() {
    name=$1
    pid=$(docker exec -it "$name" pgrep containerpilot | tail -1 | tr -d '[:space:]')
    docker exec -it "$name" pmap -x "$pid" > "pmaps/${name}-$now"
}

do-profile() {
    name=$1
    docker exec -it "$name" \
           curl -so "/minimal/profiles/heap-${name}-${now}" \
           "http://localhost:6060/debug/pprof/heap?debug=1"
}

do-goroutine() {
    name=$1
    docker exec -it "$name" \
           curl -so "/minimal/profiles/goroutine-${name}-${now}" \
           "http://localhost:6060/debug/pprof/goroutine?debug=1"
}

run() {
    docker rm -f containerpilot_consul > /dev/null 2>&1 || true
    docker run -d -m 256m -p 8500:8500 --name containerpilot_consul \
           consul:latest agent -dev -client 0.0.0.0 -bind=0.0.0.0
    # run-with-config do-nothing
    run-with-config job-only
    run-with-config job-that-logs
    run-with-config job-with-health-check
    run-with-config job-with-service
    run-with-config watch-only
    run-with-config watch-trigger-job
}

profiles() {
    mkdir -p profiles
    mkdir -p pmaps
    while true; do
        now=$(date +%s)

        # do-profile do-nothing
        do-profile job-only
        do-profile job-that-logs
        do-profile job-with-health-check
        do-profile job-with-service
        do-profile watch-only
        do-profile watch-trigger-job

        # do-goroutine do-nothing
        do-goroutine job-only
        do-goroutine job-that-logs
        do-goroutine job-with-health-check
        do-goroutine job-with-service
        do-goroutine watch-only
        do-goroutine watch-trigger-job

        # do-pmap do-nothing
        do-pmap job-only
        do-pmap job-that-logs
        do-pmap job-with-health-check
        do-pmap job-with-service
        do-pmap watch-only
        do-pmap watch-trigger-job
        sleep 300
    done
}

cmd=$1
shift
$cmd "$@"
