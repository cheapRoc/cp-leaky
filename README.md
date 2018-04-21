# cp-leaky

`cp-leaky` is a lab environment designed to test and measure ContainerPilot
heap/memory profiles and goroutine leaks.

## Background

The project provides a Vagrant machine that includes a few simple ContainerPilot
configurations. Each configuration is run inside it's own container with
scripting that periodically saves heap profiles, pmap output, and goroutine
traces.

Metrics can then be harvested from each of the profiles and fed into graphs or
other third party tools for measurement and observation.

This setup was modeled after a successful debugging exercise done by
ContainerPilot's original maintainer and core contributor, Tim Gross. Read
through [joyent/containerpilot#464](https://github.com/joyent/containerpilot/issues/464) for more information.

## Usage

You'll need a version of ContainerPilot compiled for Linux available at the root
of this project. Ensure that the version of ContainerPilot you want to profile
has `net/http/pprof` loaded within it's `main.go` file. Scripts in this project
poll the pprof endpoint at `http://localhost:6060`.

You can also apply the following patch to `main.go`.

```diff
diff --git a/main.go b/main.go
index 6df594e..b57e237 100644
--- a/main.go
+++ b/main.go
@@ -7,6 +7,9 @@ import (
        "os"
        "runtime"

+       "net/http"
+       _ "net/http/pprof"
+
        "github.com/joyent/containerpilot/core"
        "github.com/joyent/containerpilot/sup"
        log "github.com/sirupsen/logrus"
@@ -14,6 +17,13 @@ import (

 // Main executes the containerpilot CLI
 func main() {
+       // Provide a way to enable profiling of any future ContainerPilot build.
+       if _, ok := os.LookupEnv("CP_PROFILING"); ok {
+               go func() {
+                       log.Println(http.ListenAndServe("0.0.0.0:6060", nil))
+               }()
+       }
+
        // make sure we use only a single CPU so as not to cause
        // contention on the main application
        runtime.GOMAXPROCS(1)
```

Running `vagrant up` should be enough to begin the tests on a local development
machine. If you have a Linux Docker host you can also take this entire project
and run `bin/test.sh start` to begin each of the configuration
containers. Running `bin/test.sh profile` will begin storing profiles every 5
minutes.

All profiles and stack traces are left within `profiles/`, `pmaps/`, and
`goroutines/` for evaluation.

A Python script (`bin/heaper.py`) is provided for turning these heap profiles
into easy to graph tabular data.

## Tests

Several different types of ContainerPilot configurations are run by this project
in order to exercise specific features in isolation. Test configurations
include...

- `job-only.json5` configures just a job, excluding any other interactions.
- `job-that-logs.json5` configures a job that outputs through ContainerPilot's
  logging facility.
- `job-with-health-check.json5` configures a job with a simple health check.
- `job-with-service.json5` configures a job that is a service within Consul.
- `watch-only.json5` configures and registers a Consul watch.
- `watch-trigger-job.json5` configures a job that triggers from a Consul watch.

Each of these configurations are run within a separate container by the
`bin/test.sh` script. Performance samples are made every 5 minutes which include
memory profile, goroutine stack trace, and pmap output.

You should run these tests over an extended period of time to ensure that any
variations are easy to observe.

## Future

Add jobs that exercise telemetry and metrics endpoints.

- `telemetry.json5` configures the telemetry endpoint, excluding custom metrics.
- `telemetry-metric.json5` configures a custom metric that can be harvested
  through the telemetry endpoint.
- `telemetry-metric-job.json5` configures a job that posts to a custom metric.
