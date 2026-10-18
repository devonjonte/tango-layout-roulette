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
own linker (`-order_file`). Linux pins runs to CPU 2 (`CPU=N` to change).
