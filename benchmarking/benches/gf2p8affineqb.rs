use criterion::{BatchSize, Criterion, Throughput, criterion_group, criterion_main};
use rand::RngExt;

use std::hint::black_box;

fn reverse_bitstream(x: &mut [u8]) {
    x.reverse();
    for byte in x {
        // without the calls to `black_box`,
        // the compiler emits exactly the calls
        // to `gf2p8affineqb` that we want to benchmark.
        let mut acc = std::hint::black_box(0);
        for i in 0..8 {
            acc |= ((*byte >> i) & 1) << (7 - i);
        }
        *byte = std::hint::black_box(acc);
    }
}

unsafe fn vector_reverse_bitstream(x: &mut [u8]) {
    x.reverse();
    let (head, tail) = x.as_chunks_mut::<64>();
    for chunk in head {
        for byte in chunk {
            *byte = byte.reverse_bits();
        }
    }
    for byte in tail {
        let mut acc = 0;
        for i in 0..8 {
            acc |= ((*byte >> i) & 1) << (7 - i);
        }
        *byte = acc;
    }
}

fn generate_bitstream(target_megabytes: usize) -> Vec<u8> {
    let repeats = target_megabytes * 1024 * 1024;
    let mut data = Vec::with_capacity(repeats);

    let mut rng = rand::rng();

    for _ in 0..repeats {
        data.push(rng.random());
    }

    data
}

fn bench_structural_parsing(c: &mut Criterion) {
    let mut group = c.benchmark_group("Bitstream reversal");

    let mut data = generate_bitstream(10);

    group.throughput(Throughput::Elements(data.len() as u64));

    group.bench_function("naïve", |b| {
        b.iter_batched(
            || (),
            |_| {
                reverse_bitstream(black_box(&mut data));
                black_box(&mut data);
            },
            BatchSize::LargeInput,
        )
    });

    #[cfg(target_arch = "x86_64")]
    group.bench_function("gf2p8affineqb", |b| {
        b.iter_batched(
            || (),
            |_| {
                unsafe {
                    vector_reverse_bitstream(black_box(&mut data));
                }
                black_box(&mut data);
            },
            BatchSize::LargeInput,
        )
    });

    group.finish();
}

criterion_group!(benches, bench_structural_parsing);
criterion_main!(benches);
