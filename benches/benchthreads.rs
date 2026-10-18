// @zooko's thread benchmark from 75fb1b5 (bazhenov/tango#52, #65): the same
// work on the calling thread, or on one thread spawned and joined per call.
use std::hint::black_box;
use std::sync::Arc;
use std::thread;
use tango_bench::{Bencher, ErasedSampler, IntoBenchmarks, MeasurementSettings, benchmark_fn, tango_benchmarks, tango_main};

#[inline(never)]
pub fn dummy_func(maxi: u8, maxj: u8) -> u8 {
    let mut a = Arc::new(0);
    for i in 0..maxi {
        for j in 0..maxj {
            *Arc::make_mut(&mut a) ^= black_box(i.wrapping_mul(j));
        }
    }
    *a
}

fn work(iters: u64) {
    for _ in 0..iters {
        dummy_func(2, 3);
    }
}

fn on_caller(iters: u64) -> impl FnMut(Bencher) -> Box<dyn ErasedSampler> {
    move |b: Bencher| b.iter(move || work(iters))
}

fn on_spawned(threads: u64, iters: u64) -> impl FnMut(Bencher) -> Box<dyn ErasedSampler> {
    move |b: Bencher| {
        b.iter(move || {
            thread::scope(|scope| {
                for _ in 0..threads {
                    scope.spawn(move || work(iters));
                }
            })
        })
    }
}

fn benchmarks() -> impl IntoBenchmarks {
    [benchmark_fn("0-threads-1K-iters", on_caller(1000)), benchmark_fn("1-threads-1K-iters", on_spawned(1, 1000))]
}

tango_benchmarks!(benchmarks());
tango_main!(MeasurementSettings { ..Default::default() });
