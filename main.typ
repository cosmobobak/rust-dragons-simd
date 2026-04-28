#import "@preview/touying:0.7.1": *
#import themes.metropolis: *

#import "@preview/numbly:0.1.0": numbly

// #import "@preview/pinit:0.2.2": *

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-colors(
    primary: black,
  ),
  config-info(
    title: [Introduction to SIMD in Rust],
    subtitle: [Using more of your hardware for fun & profit],
    author: [Cosmo Bobak],
    date: datetime(year: 2026, month: 04, day: 22),
    // institution: [Esri],
    // contact: [cosmobobak\@gmail.com],
    // logo: emoji.city,
  ),
  config-common(
    // show-notes-on-second-screen: right,
  ),
)

#set text(font: "EB Garamond", weight: "light", size: 20pt)
#show raw: set text(font: "TX-02")

#set strong(delta: 175)
#set par(justify: true)

#show link: it => {
  if type(it.dest) == str {
    box[#it#h(0pt)#text(fill: rgb("#a00"), baseline: -0.15em)[°]]
  } else {
    it
  }
}

#set heading(numbering: numbly("{1}", default: "1.1"))

#show footnote.entry: set text(rgb(35, 55, 59))
// #show par: set text(number-type: "old-style")
// #show figure.caption: set text(number-type: "old-style")

#set quote(block: true, quotes: true)

#title-slide()

= Outline <touying:hidden>

#speaker-note[
  I’m going to tell you
  - what #smallcaps[simd] is
  - why you should care that it exists
  - how to use it
  - how that should change how you write code.
]

#outline(title: none, indent: 1em, depth: 1)

= What’s SIMD?

---

#smallcaps[Single instruction, multiple data] describes#footnote[
  #link("https://en.wikipedia.org/wiki/Flynn's_taxonomy")[Wikipedia / Flynn’s taxonomy]]
computers in which a single stream of instructions is applied
to multiple streams of data.

This is distinguished from:

#smallcaps[sisd] – “Normal programming”.
#linebreak()
#smallcaps[misd] – Fault-tolerant computing, e.g. the Space Shuttle flight computer.
#linebreak()
#smallcaps[mimd] – Multi-core systems.

---

== What do people mean when they say “SIMD”?

Colloquially, #smallcaps[simd] refers specifically to a class of CPU instructions
that operate on #smallcaps[vectors] – small, fixed-size arrays composed of
#smallcaps[lanes].

These vectors are 128–512 bits (16–64 bytes) in size, and correspond to CPU registers.

#figure(
  image("assets/registers.svg", width: 80%),
  numbering: none,
) <registers>

---

== What does SIMD look like?

#smallcaps[simd intrinsics] are built-in functions that will translate
to a particular #smallcaps[simd instruction].

```rust
// core::arch::x86_64::
pub fn _mm_add_epi32(a: m128i, b: m128i) → m128i
// core::arch::aarch64::
pub fn vaddq_s32(a: int32x4, b: int32x4) → int32x4
```

#quote(
  attribution: link(
    "https://doc.rust-lang.org/beta/core/arch/x86_64/fn._mm_add_epi32.html",
  )[doc.rust-lang.org/core/arch/x86_64/fn.\_mm\_add\_epi32],
)[
  Adds packed 32-bit integers in `a` and `b`.
]

// Here, `N` is equal to the size of the hardware vector divided
// by the size of data-type – so for `i32`s on#linebreak() AVX2 hardware,
// it’s 256 / 32 = 8 integers per vector operation.

---

#smallcaps[simd instructions] allow us to operate on each lane of a vector uniformly & simultaneously.

#figure(
  image("assets/simd-add.svg", width: 80%),
  numbering: none,
) <registers>

// ---
//
// ```rust
// let x: [i32; 4] = [1, 2, 3, 4];
// let y: [i32; 4] = [5, 6, 7, 8];
// let z: [i32; 4] = unsafe { _mm_add_epi32(x, y) };
// println!("{:?}", z); // → [6, 8, 10, 12]
// ```

---

= Why should you care?

---

For a long time, computers became faster by increasing clock frequency,
thereby executing more instructions in the same time.

This was achievable in virtue of #smallcaps[dennard scaling] – the observation that shrinking transistors did not affect their power density#footnote[That is, power
  per unit area.], allowing components to run at lower power and higher frequency.

Around #text(number-type: "old-style")[2006], Dennard scaling broke down, and shrinking
transistors no longer reduced their power consumption proportionally.

---

#figure(
  alternatives[
    #image("microprocessor-trend-data/50yrs/50-years-processor-trend.png", width: 85%)
  ][
    #image("microprocessor-trend-data/50yrs/50-years-processor-trend-fits.png", width: 85%)
  ],
  numbering: none,
  caption: text(size: .8em)[
    Original data up to the year #text(number-type: "old-style")[2010] collected
    and plotted by M. Horowitz, F. Labonte, O. Shacham, K. Olukotun, L. Hammond,
    and C. Batten.
    New plot and data collected for #text(number-type: "old-style")[2010-2021] by K. Rupp.
    Trendlines fit via log-linear regression.],
) <end-of-dennard-scaling>

---

To keep making programs faster, we now have to exploit *parallelism*, #linebreak()
and #smallcaps[simd] is an excellent place to start.

= Autovectorisation

---

#smallcaps[Autovectorisation] is the procedure by which your compiler may write
#smallcaps[simd] on your behalf.

#pause

#text[
  #set rect(
    inset: 8pt,
    width: 100%,
    stroke: none,
  )

  #grid(
    columns: (27fr, 1fr, 3fr, 50fr),
    rows: auto,
    rect[
      ```rust
      fn add_arrays(
        a :     &[i32; 1024],
        b :     &[i32; 1024],
        c : &mut [i32; 1024],
      ) {
        for ((a, b), c) in a
            .iter()
            .zip(b)
            .zip(c) {
          *c = *a + *b;
        }
      }
      ```
    ],
    rect[→],
    rect[],
    rect[
      ```asm
      add_arrays:
        xor     eax, eax
      .loop:
        ; SIMD load of b[i]
        vmovdqu ymm0, ymmword ptr [rsi + 4*rax]
        ; SIMD add + load of a[i]
        vpaddd  ymm0, ymm0, ymmword ptr [rdi + 4*rax]
        ; SIMD store to c[i]
        vmovdqu ymmword ptr [rdx + 4*rax], ymm0
        ; step loop by 8
        add     rax, 8
        cmp     rax, 1024
        jne     .loop
        vzeroupper
        ret
      ```
    ],
  )
]

---

The compiler cannot always perform #smallcaps[autovectorisation], and even when it succeeds, it may produce very suboptimal vectorised code.

#pause

Take float-to-integer conversion:

```rust
pub fn convert(xs: &[f32], out: &mut [i32]) {
    for (x, o) in xs.iter().zip(out) {
        *o = *x as i32;
    }
}
```

== Fast float-to-integer conversion

#text(size: 40pt)[→ `CVTTPS2DQ`]
#linebreak()
_Convert With Truncation Packed Single Precision Floating-Point Values to PackedSigned Doubleword Integer Values_

#quote(attribution: link(
  "https://www.felixcloutier.com/x86/cvttps2dq",
)[www.felixcloutier.com/x86/cvttps2dq])[
  Converts … sixteen packed single precision floating-point values
  #linebreak()
  in the source operand to … sixteen signed doubleword integers in
  #linebreak()
  the destination operand.

  If a converted result is larger than the maximum signed doubleword integer,
  #linebreak()
  the floating-point invalid exception is raised, and if this exception is masked,
  #linebreak()
  the indefinite integer value (0×80000000) is returned.
]

---

Unfortunately, Rust’s cast semantics are *too correct* for us!

#alternatives(stretch: true, position: left + horizon)[][
  #quote(attribution: "The Rust Reference [expr.as.numeric.int-as-float]", quotes: false)[
    #set list(marker: [--])
    Casting from a float to an integer will round the float towards zero.
    - NaN will return 0
    - Values larger than the maximum integer value, including `INFINITY`,
      #linebreak()
      will saturate to the maximum value of the integer type.
    - Values smaller than the minimum integer value, including `NEG_INFINITY`,
      #linebreak()
      will saturate to the minimum value of the integer type.
  ]
][
  ```asm
  vmovss     xmm2, [rdi + rbx + 4] ; load one f32
  vcvttss2si ebp , xmm2            ; scalar f32→i32 (0×80000000 on overflow/NaN)
  vucomiss   xmm2, xmm0            ; xmm0 = 0×4effffff = largest f32 < 2^31
  cmova      ebp , r11d            ; if above, ebp = INT_MAX  (+ve saturation)
  vucomiss   xmm2, xmm2            ; self-compare: unordered ⇔ NaN, sets PF
  cmovp      ebp , r8d             ; if NaN, ebp = 0           (NaN → 0)
  vpinsrd    xmm1, xmm1, ebp, 1    ; insert scalar result into lane 1 of an xmm
  ```

  Instead of converting eight floats using two instructions,
  we convert one float with seven!

  Naïvely speaking, this is 28× worse than we’d hoped.
]

---

How do we show the compiler what we want? Do we need to use instrinsics? #pause *No.*

#pause

```rust
// f32::
pub unsafe fn to_int_unchecked<Int>(self) -> Int
where
    f32: FloatToInt<Int>,
```

#quote(
  attribution: link("https://doc.rust-lang.org/std/primitive.f32.html#method.to_int_unchecked")[
    doc.rust-lang.org/std/primitive.f32.html\#method.to_int_unchecked
  ],
  quotes: false,
)[
  Rounds toward zero and converts to any primitive integer type, *assuming that the value is finite and fits in that type*.
]

---

```rust
pub fn convert(xs: &[f32], out: &mut [i32]) {
    for (x, o) in xs.iter().zip(out) {
        // *o = *x as i32;
        *o = unsafe { x.to_int_unchecked() };
    }
}
```

---

```asm
loop:
  vcvttps2dq  ymm0, ymmword ptr [rdi + r9] ; load + convert
  vmovups     ymmword ptr [rdx + r9], ymm0 ; store
  add         r9, 32                       ; advance by 32 / 4 = 8 floats
  cmp         r8, r9                       ; check if we’re at the end
  jne         .loop                        ; goto loop start
```

= Accelerating neural networks

---

Here is an activation function used in the best chess engines:

$ "SCReLU"(x) = "clamp"(x, 0, 1)^2 "       “Squared Clipped ReLU”" $

For a single output neuron, this is implemented like so:

```rust
fn forward(x: &[i16; L1], w: &[i16; L1]) -> i32 {
  let mut sum = 0;
  for (x, w) in x.iter().zip(w) {
    //      v--------- clip ----------v
    let a = i32::from(*x).clamp(0, 255);
    //     v---v square.           ^^^ value of unity
    sum += a * a * i32::from(*w);
  }
  sum
}
```

---

```rust
fn forward(x : &[i16; L1], w : &[i16; L1]) -> i32 {
    const { assert!(L1.is_multiple_of(32)); }
    unsafe {
        let lo = _mm512_setzero_si512();
        let hi = _mm512_set1_epi16(255);
        let mut sum = _mm512_setzero_si512();
        for (xc, wc) in x.chunks_exact(32).zip(w.chunks_exact(32)) {
            let xv = _mm512_loadu_epi16(xc.as_ptr());
            let wv = _mm512_loadu_epi16(wc.as_ptr());
            let a  = _mm512_max_epi16(_mm512_min_epi16(xv, hi), lo);
            let v  = _mm512_mullo_epi16(a, wv);
            let v  = _mm512_madd_epi16(a, v);
            sum    = _mm512_add_epi32(sum, v);
        }
        horizontal_reduce(sum)
    }
}
```

---

```rust
fn forward(x : &[i16; L1], w : &[i16; L1]) -> i32 {
    const { assert!(L1.is_multiple_of(32)); }
    unsafe {
        let lo = set_lanes_i16(0);
        let hi = set_lanes_i16(255);
        let mut sum = set_lanes_i16(0);
        for (xc, wc) in x.chunks_exact(32).zip(w.chunks_exact(32)) {
            let xv = load_i16(xc);
            let wv = load_i16(wc);
            let a  = max_i16(min_i16(xv, hi), lo);
            let v  = mul_truncating_i16(a, wv); // ← pay attention!
            let v  = mul_widening_i16(a, v);
            sum    = add_i32(sum, v);
        }
        horizontal_reduce(sum)
    }
}
```

= Finding a byte in a buffer

= GFNI

= Advice for the working programmer

- general coding style (operate on batches)
- → cite casey, matklad.

// A slide with equation:

// $ x_(n+1) = (x_n + a/x_n) / 2 $

// #focus-slide[
//   Wake up!
// ]

#show: appendix

= Appendix

---


// Thoughts
// Slides 9 and 10 are great - not too much to read and your voiceover is to explain the content is excellent
// When showing instructions, consider highlighting them as you mention them? Or add an extra diagram showing it operating on the numbers?
// Slide 17 - consider add an exmaple number to demonstrate the clamping and squaring
// Note: we can see you cursor but it's small
