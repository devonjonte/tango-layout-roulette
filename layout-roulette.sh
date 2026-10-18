#!/usr/bin/env bash
# Layout roulette: the same source built K times, each linked with its own
# random function order, then compared with Tango.
#
#   ./layout-roulette.sh [K] [RUNS]   (default 4 builds, 5 runs a pair)
#
# 1. Each build against an exact copy of itself (same binary, same layout).
# 2. Pairs of builds of the same source with different layouts, each pair
#    compared RUNS times.
# If layout alone moves the measured function, (1) reads level and (2) reads a
# steady, "significant" difference whose sign and size depend on the pair.
#
# Linux needs lld (ld.lld or ld.lld-NN); macOS uses its own ld (-order_file).
# Linux pins the runs to CPU $CPU (default 2); macOS cannot pin.
set -eu
K=${1:-4}
RUNS=${2:-5}
CPU=${CPU:-2}
out=target/roulette
mkdir -p "$out/lld"
if [ "$(uname)" = Darwin ]; then
    pin() { "$@"; }
else
    pin() { taskset -c "$CPU" "$@"; }
    lld=$(command -v ld.lld || ls /usr/bin/ld.lld-* | sort -V | tail -1)
    ln -sf "$lld" "$out/lld/ld.lld"
fi
link_flags() {
    if [ "$(uname)" = Darwin ]; then
        echo "-C link-arg=-Wl,-order_file,$PWD/$1"
    else
        echo "-C link-arg=-fuse-ld=lld -C link-arg=-B$PWD/$out/lld -C link-arg=-Wl,--symbol-ordering-file=$PWD/$1 -C link-arg=-Wl,--no-warn-symbol-ordering"
    fi
}

# The bench binary's own functions, to shuffle.
cargo bench --bench=bencha --no-run -q 2>/dev/null
base=$(ls target/release/deps/bencha-* | grep -v '\.d$' | head -1)
nm "$base" | awk '$2 == "t" || $2 == "T" { print $3 }' | sort -u > "$out/symbols.txt"

for i in $(seq 0 $((K - 1))); do
    python3 -c "import random,sys; s=open(sys.argv[1]).read().split(); random.Random($i).shuffle(s); print('\n'.join(s))" "$out/symbols.txt" > "$out/order-$i.txt"
    RUSTFLAGS="$(link_flags "$out/order-$i.txt")" \
        cargo bench --bench=bencha --no-run -q --target-dir "$out/build-$i" 2>/dev/null
    cp "$(ls "$out"/build-$i/release/deps/bencha-* | grep -v '\.d$' | head -1)" "$out/layout-$i"
    cp "$out/layout-$i" "$out/layout-$i-copy"
done

echo "== 1. each layout against an exact copy of itself"
for i in $(seq 0 $((K - 1))); do
    printf "layout %s vs its copy: " "$i"
    pin "$out/layout-$i" compare "$out/layout-$i-copy" | tail -1 | sed 's/^[^[]*//'
done

echo "== 2. the same source, different layouts, each pair $RUNS times"
for i in $(seq 1 $((K - 1))); do
    printf "layout 0 vs layout %s:\n" "$i"
    for r in $(seq "$RUNS"); do
        pin "$out/layout-$i" compare "$out/layout-0" | tail -1 | sed 's/^[^[]*/    /'
    done
done
