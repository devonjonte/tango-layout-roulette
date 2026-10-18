use tango_bench::{Bencher, ErasedSampler, benchmark_fn, tango_benchmarks, IntoBenchmarks};

use tangothreadmeasurements::help_test_dummy_func;

fn gen_st_bencher_dummyfunc() -> impl FnMut(Bencher<tango_bench::metrics::WallClock>) -> Box<dyn ErasedSampler> {
    move |b: Bencher<tango_bench::metrics::WallClock>| {
        b.iter(move || {
            help_test_dummy_func();
        })
    }
}

fn tangotb_benchmarks() -> impl IntoBenchmarks {
    [
        benchmark_fn("0-threads-1-iters",
                     gen_st_bencher_dummyfunc()
        ),
    ]
}

tango_benchmarks!(tangotb_benchmarks());
