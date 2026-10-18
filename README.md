# Tango and layout roulette

Tango comparing a benchmark with **identical source** reads a steady,
"significant" difference when the two sides are separately linked binaries
(bazhenov/tango#52, #65). This repository reproduces it:

    git clone https://github.com/devonjonte/tango-layout-roulette
    cd tango-layout-roulette
    ./layout-roulette.sh 4 5

The script builds `bencha` 4 times from the same source, each linked with a
different random function order (seeded, so every run of the script draws
the same layouts), and runs `tango compare`:

1. each build against an exact copy of itself: level;
2. build 0 against each other build, 5 runs a pair: some pairs read a steady
   difference whose sign flips with the roles, from link order alone.

On an i7-12700K (Linux, Rust 1.98, lld 18), build 1 read +8.6% to +10.4%
slower than build 0 in every run, and −8.5% to −9.4% with the roles swapped;
each build against its own copy stayed within a few percent of level.

Needs Rust and python3; Linux needs lld (`apt install lld`); macOS uses its
own linker (`-order_file`). Linux pins runs to CPUs 2 and 4 (`CPU=LIST` to change): Tango 0.8+ runs each side in its own process, and one shared CPU doubles the time.

## Threads: Tango's two sides are not alike

    BENCH=benchthreads ./layout-roulette.sh 3 3

`benchthreads` is @zooko's thread benchmark: the same work on the calling
thread, or on one thread spawned and joined per call. With **an exact copy
of the same binary on both sides**, the spawning variant reads about 5%
slower on the candidate's side, marked significant, in every run (i7-12700K:
+3.6% to +6.1%, 9 of 9). The work on the caller reads level.

The cause: Tango loads the baseline into the candidate's process as a
library, so the process holds two copies of Rust's standard library. Only
the candidate's, the main executable's, ran Rust's start-up, which gives
each spawned thread an alternate signal stack for stack-overflow reports.
Under `strace -f -c`, exactly half the threads created (5,640 of 11,306)
called `mmap`, `munmap` and three `sigaltstack`: the candidate's threads.

## Fixed in Tango 0.8 and later

Tango 0.8 runs each side in its own process. With 0.9 (this repository's
pin since October 18), `benchthreads` against an exact copy of itself reads
-0.5% to +0.5% over six runs (pinned to two CPUs), both signs, none marked
significant, where 0.6 read about +5% on the candidate's side in every run.

## License

You may use this repository under the terms of any of these four Free and Open Source Software licences:

* MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)
* Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
* Transitive Grace Period Public License 1.0 ([LICENSE-TGPPL](LICENSE-TGPPL) or https://spdx.org/licenses/TGPPL-1.0.html)
* Bootstrap Open Source License v1.0 ([LICENSE-BOSL.txt](LICENSE-BOSL.txt))
