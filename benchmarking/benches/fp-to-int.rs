use criterion::{BatchSize, Criterion, Throughput, criterion_group, criterion_main};
use rand::RngExt;

use std::hint::black_box;

fn convert(xs: &[f32], out: &mut [i32]) {
    for (x, o) in xs.iter().zip(out) {
        *o = *x as i32;
    }
}

unsafe fn vector_convert(xs: &[f32], out: &mut [i32]) {
    for (x, o) in xs.iter().zip(out) {
        // *o = *x as i32;
        *o = unsafe { x.to_int_unchecked() };
    }
}

fn generate_floats(target_megabytes: usize) -> Vec<f32> {
    let repeats = (target_megabytes * 1024 * 1024) / 4;
    let mut data = Vec::with_capacity(repeats);

    let mut rng = rand::rng();

    for _ in 0..repeats {
        data.push(rng.random());
    }

    data
}

fn bench_structural_parsing(c: &mut Criterion) {
    let mut group = c.benchmark_group("Float-to-integer conversion");

    let floats = generate_floats(10);

    group.throughput(Throughput::Elements(floats.len() as u64));

    group.bench_function("naïve", |b| {
        b.iter_batched(
            || vec![0; floats.len()],
            |mut ints| {
                convert(black_box(&floats), black_box(&mut ints));
                black_box(ints);
            },
            BatchSize::LargeInput,
        )
    });

    #[cfg(target_arch = "x86_64")]
    group.bench_function("cvttps2dq", |b| {
        b.iter_batched(
            || vec![0; floats.len()],
            |mut ints| {
                unsafe {
                    vector_convert(black_box(&floats), black_box(&mut ints));
                }
                black_box(ints);
            },
            BatchSize::LargeInput,
        )
    });

    group.finish();
}

criterion_group!(benches, bench_structural_parsing);
criterion_main!(benches);
