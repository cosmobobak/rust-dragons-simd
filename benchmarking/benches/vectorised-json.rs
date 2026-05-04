use criterion::{BatchSize, Criterion, Throughput, criterion_group, criterion_main};

#[cfg(target_arch = "x86_64")]
use std::arch::x86_64::*;

use std::hint::black_box;

fn find_structural_characters(json: &str, bitmask: &mut [u64]) {
    const STRUCTURAL: &[u8] = b"{}[]:,";

    for (i, c) in json.as_bytes().iter().enumerate() {
        if STRUCTURAL.contains(c) {
            bitmask[i / 64] |= 1 << (i as u64 % 64);
        }
    }
}

#[cfg(target_arch = "x86_64")]
#[target_feature(enable = "avx512f,avx512bw")]
fn vfind_structural_characters(json: &str, bitmask: &mut [u64]) {
    const STRUCTURAL: [u8; 6] = *b"{}[]:,";

    unsafe {
        let (json_head, json_tail) = json.as_bytes().as_chunks::<64>();
        let (mask_head, mask_tail) = bitmask.split_at_mut(json_head.len());

        let tests = STRUCTURAL.map(|b| _mm512_set1_epi8(b as _));

        for (block, out) in json_head.iter().zip(mask_head) {
            let bytes = _mm512_loadu_epi8(block.as_ptr().cast());
            let mut mask = 0u64;
            for test in tests {
                mask |= _mm512_cmpeq_epu8_mask(bytes, test);
            }
            *out = mask;
        }

        for (i, c) in json_tail.iter().enumerate() {
            if STRUCTURAL.contains(c) {
                mask_tail[i / 64] |= 1 << (i as u64 % 64);
            }
        }
    }
}

fn generate_large_json(target_megabytes: usize) -> String {
    const DUMMY_OBJECT: &str = r#"{
        "id": 123456789,
        "name": "Benchmark Test User",
        "is_active": true,
        "roles": ["admin", "superuser", "moderator"],
        "metadata": {
          "created_at": "2026-05-04T15:27:04Z",
          "score": 98.76
        }
    }"#;

    let repeats = (target_megabytes * 1024 * 1024) / DUMMY_OBJECT.len();
    let mut json = String::with_capacity(repeats * DUMMY_OBJECT.len() + 2);

    json.push('[');
    for _ in 0..repeats {
        json.push_str(DUMMY_OBJECT);
        json.push(',');
    }
    json.pop();
    json.push(']');

    json
}

fn bench_structural_parsing(c: &mut Criterion) {
    let mut group = c.benchmark_group("JSON Structural Characters");

    let json_payload = generate_large_json(10);
    let bitmask_len = json_payload.len().div_ceil(64);

    // Report throughput in bytes per second
    group.throughput(Throughput::Bytes(json_payload.len() as u64));

    group.bench_function("Scalar", |b| {
        b.iter_batched(
            || vec![0u64; bitmask_len],
            |mut bitmask| {
                find_structural_characters(black_box(&json_payload), black_box(&mut bitmask));
                black_box(bitmask);
            },
            BatchSize::LargeInput,
        )
    });

    #[cfg(target_arch = "x86_64")]
    group.bench_function("AVX-512", |b| {
        b.iter_batched(
            || vec![0u64; bitmask_len],
            |mut bitmask| {
                // SAFETY: We must assume the CPU running the benchmark supports AVX-512.
                unsafe {
                    vfind_structural_characters(black_box(&json_payload), black_box(&mut bitmask));
                }
                black_box(bitmask);
            },
            BatchSize::LargeInput,
        )
    });

    group.finish();
}

criterion_group!(benches, bench_structural_parsing);
criterion_main!(benches);
