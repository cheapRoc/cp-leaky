#!/bin/bash

now=$(date +%s)
tests=(
    job-only
    job-that-logs
    job-with-health-check
    job-with-service
    watch-only
    watch-trigger-job
)

run-with-config() {
    name=$1
    docker run -d \
           --name "$name" \
           -v "$(pwd):/minimal" \
           --link containerpilot_consul:consul \
           -e CP_PROFILING=1 \
           containerpilot_base \
           /minimal/containerpilot -config "/minimal/etc/${name}.json5"
}

do-pmap() {
    printf "\tSampling pmap for $name\n"
    name=$1
    pid=$(docker exec -it "$name" pgrep containerpilot | tail -1 | tr -d '[:space:]')
    docker exec -it "$name" pmap -x "$pid" > "pmaps/${name}_${now}.pmap"
}

do-profile() {
    printf "\tSampling pprof profile for $name\n"
    name=$1
    docker exec -it "$name" \
           curl -so "/minimal/profiles/${name}_${now}.heap" \
           "http://localhost:6060/debug/pprof/heap?debug=1"
}

do-goroutine() {
    printf "\tSampling goroutine stacks for $name\n"
    name=$1
    docker exec -it "$name" \
           curl -so "/minimal/goroutines/${name}_${now}.trace" \
           "http://localhost:6060/debug/pprof/goroutine?debug=1"
}

start() {
    stop
    docker build -t containerpilot_base .
    docker run -d -m 256m -p 8500:8500 --name containerpilot_consul \
           consul:latest agent -dev -client 0.0.0.0 -bind=0.0.0.0

    for name in "${tests[@]}"; do
        run-with-config $name
    done
}

stop() {
    for name in "${tests[@]}"; do
        echo "--> Stopping $name"
        docker rm -f $name > /dev/null 2>&1 || true
    done

    docker rm -f containerpilot_base > /dev/null 2>&1 || true
    docker rm -f containerpilot_consul > /dev/null 2>&1 || true
}

profile() {
    mkdir -p profiles
    mkdir -p pmaps
    mkdir -p goroutines
    while true; do
        now=$(date +%s)
        for name in "${tests[@]}"; do
            echo "--> Measuring $name"
            do-profile $name
            do-goroutine $name
            do-pmap $name
        done
        echo "--> Sleeping for 5 minutes"
        sleep 300
    done
}

cmd=$1
shift
$cmd "$@"
