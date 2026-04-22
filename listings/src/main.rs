use std::arch::x86_64::*;

fn listing01() {
    use std::arch::x86_64::{__m128i, _mm_add_epi32};
    use std::mem::transmute;

    let a: [i32; 4] = [1, 2, 3, 4];
    let b: [i32; 4] = [5, 6, 7, 8];
    let c: [i32; 4] = unsafe {
        let a_vec: __m128i = transmute(a);
        let b_vec: __m128i = transmute(b);
        let c_vec = _mm_add_epi32(a_vec, b_vec);
        transmute(c_vec)
    };
    println!("{:?}", c); // [6, 8, 10, 12]
}

#[inline(never)]
#[unsafe(no_mangle)]
fn listing01_asm(a: [i32; 4], b: [i32; 4]) -> [i32; 4] {
    use std::arch::x86_64::{__m128i, _mm_add_epi32};
    use std::mem::transmute;

    let c: [i32; 4] = unsafe {
        let a_vec: __m128i = transmute(a);
        let b_vec: __m128i = transmute(b);
        let c_vec: __m128i = _mm_add_epi32(a_vec, b_vec);
        transmute(c_vec)
    };

    c
}

#[inline(never)]
#[unsafe(no_mangle)]
fn listing02_auto(a: &[i32; 1024], b: &[i32; 1024], c: &mut [i32; 1024]) {
    for ((a, b), c) in a.iter().zip(b).zip(c) {
        *c = a + b;
    }
}

// #[inline(never)]
// #[unsafe(no_mangle)]
// fn listing02_manual(a: &[i32; 1024], b: &[i32; 1024], c: &mut [i32; 1024]) {
//     use std::arch::x86_64::{__m128i, _mm_add_epi32};
//     use std::mem::transmute;

//     todo!();
// }

const L1: usize = 1024;

#[inline(never)]
#[unsafe(no_mangle)]
fn listing03_act_dot_autovec(x: &[i16; L1], w: &[i16; L1]) -> i32 {
    let mut sum = 0;
    for (x, w) in x.iter().zip(w) {
        let a = i32::from(*x).clamp(0, 255);
        sum += a * a * i32::from(*w);
    }
    sum
}

#[inline(never)]
unsafe fn horizontal_reduce(a: __m512i) -> i32 {
    unsafe {
        let high_256 = std::arch::x86_64::_mm512_extracti64x4_epi64::<1>(a);
        let low_256 = std::arch::x86_64::_mm512_castsi512_si256(a);
        let sum_256 = std::arch::x86_64::_mm256_add_epi32(low_256, high_256);
        let upper_128 = std::arch::x86_64::_mm256_extracti128_si256::<1>(sum_256);
        let lower_128 = std::arch::x86_64::_mm256_castsi256_si128(sum_256);
        let sum_128 = std::arch::x86_64::_mm_add_epi32(upper_128, lower_128);
        let upper_64 = std::arch::x86_64::_mm_unpackhi_epi64(sum_128, sum_128);
        let sum_64 = std::arch::x86_64::_mm_add_epi32(upper_64, sum_128);
        let upper_32 = std::arch::x86_64::_mm_shuffle_epi32::<0b00_00_00_01>(sum_64);
        let sum_32 = std::arch::x86_64::_mm_add_epi32(upper_32, sum_64);

        std::arch::x86_64::_mm_cvtsi128_si32(sum_32)
    }
}

#[unsafe(no_mangle)]
fn forward3(x: &[i16; L1], w: &[i16; L1]) -> i32 {
    const _: () = assert!(L1.is_multiple_of(32));
    unsafe {
        let lo = _mm512_setzero_si512();
        let hi = _mm512_set1_epi16(255);
        let mut sum = _mm512_setzero_si512();
        for (xc, wc) in x.chunks_exact(32).zip(w.chunks_exact(32)) {
            let xv = _mm512_loadu_epi16(xc.as_ptr());
            let wv = _mm512_loadu_epi16(wc.as_ptr());
            let a = _mm512_max_epi16(_mm512_min_epi16(xv, hi), lo);
            let v = _mm512_mullo_epi16(a, wv);
            let v = _mm512_madd_epi16(a, v);
            sum = _mm512_add_epi32(sum, v);
        }
        horizontal_reduce(sum)
    }
}

fn main() {
    listing01();
}
