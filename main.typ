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
    title: [Introduction to SIMD in Rust],
    subtitle: [Using more of your hardware for fun & profit],
    author: [Cosmo Bobak],
    date: datetime(year: 2026, month: 04, day: 22),
    // institution: [Esri],
    // contact: [cosmobobak\@gmail.com],
    // logo: emoji.city,
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

#outline(title: none, indent: 1em, depth: 1)

= What’s SIMD?

---

#smallcaps[Single instruction, multiple data] describes#footnote[
  #link("https://en.wikipedia.org/wiki/Flynn's_taxonomy")[Wikipedia / Flynn’s taxonomy]]
computers in which a single stream of instructions is applied
to multiple streams of data.

This is distinguished from:

- SISD – “Normal programming”.
- MISD – Most typically fault-tolerant computing, e.g. the Space Shuttle flight computer.
- MIMD – Multi-core systems.

---

Colloquially, “SIMD” refers specifically to a class of CPU instructions
that operate on #smallcaps[vectors] – small, fixed-size arrays composed of
#smallcaps[lanes].

These vectors are 128–512 bits (16–64 bytes) in size, and correspond to CPU registers.

#figure(
  image("assets/registers.svg", width: 60%),
  numbering: none,
) <registers>

---

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

= Why do we want SIMD?

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

To keep making programs faster, we now have to exploit *parallelism*.

---

There are a number of ways to achieve greater parallelism.

1. Execute multiple instruction-streams at the same time – “Multi-core”
2. Execute multiple instructions concurrently – “Out-of-order execution”
3. Execute each instruction on multiple pieces of data – “SIMD” – the subject of this talk.

---

= You are already using some SIMD

= Motivating example

= A more complex example

= Advice for the programmer

= Appendix

- common applications
- unsafe to_int for autovec
- lizard screlu
- general coding style (operate on batches)
- → cite casey, matklad.








== A long long long long long long long long long long long long long long long long long long long long long long long long Title

=== sdfsdf

A slide with equation:

$ x_(n+1) = (x_n + a/x_n) / 2 $

#lorem(200)

= Second Section

#focus-slide[
  Wake up!
]

== Simple Animation

We can use `#pause` to #pause display something later.

#meanwhile

Meanwhile, #pause we can also use `#meanwhile` to display other content synchronously.

#speaker-note[
  + This is a speaker note.
  + You won't see it unless you use `config-common(show-notes-on-second-screen: right)`
]

#show: appendix

= Appendix

---

Please pay attention to the current slide number.
