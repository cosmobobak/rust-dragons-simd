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

fn main() {
    listing01();
}
