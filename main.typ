#import "@preview/touying:0.7.1": *
#import themes.metropolis: *

#import "@preview/numbly:0.1.0": numbly

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-colors(
    primary: black,
  ),
  config-info(
    title: [Introduction to #smallcaps[simd] in Rust],
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

#show link: underline

#set heading(numbering: numbly("{1}.", default: "1.1"))

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

= What’s #smallcaps[simd]?

---

#smallcaps[Single instruction, multiple data] describes#footnote[
  #link("https://en.wikipedia.org/wiki/Flynn's_taxonomy")[Wikipedia / Flynn’s taxonomy]]
computers in which a single stream of instructions is applied
to multiple streams of data.

This is distinguished from:

#smallcaps[sisd] – “Normal programming”.#linebreak()
#smallcaps[misd] – Most typically fault-tolerant computing, e.g. the Space Shuttle flight computer.#linebreak()
#smallcaps[mimd] – Multi-core systems.

---

== What do people mean when they say “#smallcaps[simd]”?

Colloquially, #smallcaps[simd] refers specifically to a class of CPU instructions
that operate on #smallcaps[vectors] – small, fixed-size arrays composed of
#smallcaps[lanes].

These vectors are 128–512 bits (16–64 bytes) in size, and correspond to CPU registers.

#figure(
  image("assets/registers.svg", width: 60%),
  numbering: none,
) <registers>

---

== What does #smallcaps[simd] look like?

#smallcaps[simd instructions] allow us to operate on each lane of a vector uniformly & simultaneously.

#alternatives(stretch: true, position: left + top)[

][
  ```rust
  // core::arch::x86_64::
  pub fn _mm_add_epi32(a: m128i, b: m128i) → m128i
  // core::arch::aarch64::
  pub fn vaddq_s32(a: int32x4, b: int32x4) → int32x4
  // general form:
  pub fn simd_add_i32(a: i32×N, b: i32×N) → i32×N
  ```

  #quote[Add packed 32-bit integers in `a` and `b`.]

  Here, `N` is equal to the size of the hardware vector divided
  by the size of data-type – so for#linebreak() `i32`s on AVX2 hardware,
  it’s 256 / 32 = 8 integers per vector operation.
][
  ```rust
  let x: [i32; 4] = [1, 2, 3, 4];
  let y: [i32; 4] = [5, 6, 7, 8];
  let z: [i32; 4] = unsafe {
      let x_vec: __m128i = transmute(x);
      let y_vec: __m128i = transmute(y);
      let z_vec: __m128i = _mm_add_epi32(x_vec, y_vec);
      transmute(z_vec)
  };
  println!("{:?}", z); // → [6, 8, 10, 12]
  ```
]

---

= Why do we want #smallcaps[simd]?

---

For a long time, computers got faster by increasing clock
frequency – executing more instructions in the same amount of time.

This was achievable in virtue of #smallcaps[Dennard scaling] – the fact that shrinking
transistors did not affect their power density#footnote[That is, power per unit area.],
allowing components to run at lower power and higher frequency.

Around 2006, Dennard scaling broke down – shrinking transistors no longer reduced their
power consumption proportionally.

---

#figure(
  image("microprocessor-trend-data/50yrs/50-years-processor-trend.png", width: 85%),
  numbering: none,
  caption: [
    Original data up to the year 2010 collected and plotted by M. Horowitz, F. Labonte, O. Shacham, K. Olukotun, L. Hammond, and C. Batten.
    New plot and data collected for 2010-2021 by K. Rupp.
  ],
) <scaling>

---

#figure(
  image("microprocessor-trend-data/50yrs/50-years-processor-trend-fits.png", width: 85%),
  numbering: none,
  caption: [
    Original data up to the year 2010 collected and plotted by M. Horowitz, F. Labonte, O. Shacham, K. Olukotun, L. Hammond, and C. Batten.
    New plot and data collected for 2010-2021 by K. Rupp.
  ],
) <scaling-annotated>

---

To keep making programs faster, we now have to exploit *parallelism*, #linebreak()
and #smallcaps[simd] is an excellent place to start.

---

= Using #smallcaps[simd]

---

todo!()

== Autovectorisation

#smallcaps[Autovectorisation] is the procedure by which your compiler may write #smallcaps[simd]
on your behalf.

#pause

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

== Making code autovec-friendly

some code will fail to vectorise (example)

(e.g. to_int, bounds checks, &c)

contrast preämbles of

```rust
fn stencil(input: &[i32], output: &mut [i32], n: usize) {
    for i in 0..n {
        output[i] = input[i] + input[i + 1] + input[i + 2];
    }
}

fn stencil2(input: &[i32], output: &mut [i32], n: usize) {
    assert!(n + 2 <= input.len() && n <= output.len());
    for i in 0..n {
        output[i] = input[i] + input[i + 1] + input[i + 2];
    }
}
```

https://godbolt.org/z/57ezre9jd

== Intrinsics

- lizard screlu

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


