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

#[inline(never)]
#[unsafe(no_mangle)]
fn listing02_manual(a: &[i32; 1024], b: &[i32; 1024], c: &mut [i32; 1024]) {
    use std::arch::x86_64::{__m128i, _mm_add_epi32};
    use std::mem::transmute;

    todo!();
}

#[inline(never)]
#[unsafe(no_mangle)]
fn listing03_stencil(input: &[i32], output: &mut [i32], n: usize) {
    for i in 0..n {
        output[i] = input[i] + input[i + 1] + input[i + 2];
    }
}

#[inline(never)]
#[unsafe(no_mangle)]
fn listing03_stencil2(input: &[i32], output: &mut [i32], n: usize) {
    assert!(n + 2 <= input.len() && n <= output.len());
    for i in 0..n {
        output[i] = input[i] + input[i + 1] + input[i + 2];
    }
}

fn main() {
    listing01();
}
