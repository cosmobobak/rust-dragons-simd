#import "@preview/touying:0.7.1": *
#import themes.metropolis: *

#import "@preview/numbly:0.1.0": numbly
#import "@preview/cetz:0.3.4": canvas, draw
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
#show raw: set text(font: ("Berkeley Mono", "TX-02"))

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

= What is SIMD?
_A miserable little pile of bits_

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
_Computers haven’t got faster since 2006._

---

For a long time, computers became faster by increasing clock frequency,
thereby executing more instructions in the same time.

This was achievable in virtue of #smallcaps[dennard scaling] – the observation that shrinking transistors did not affect their power density#footnote[That is, power
  per unit area.], allowing components to run at lower power and higher frequency.

Around #text(number-type: "old-style")[2006], Dennard scaling broke down, and shrinking
transistors no longer reduced their power consumption proportionally.

Highly recommended: Cantrill’s #link("https://www.infoq.com/presentations/moore-law-expiring/")[_No Moore Left to Give: Enterprise Computing after Moore's Law_]

---

#figure(
  alternatives[
    #image("assets/50-years-processor-trend.svg", width: 85%)
  ][
    #image("assets/50-years-processor-trend-fits.svg", width: 85%)
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
_In which LLVM completely rewrites the program._

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

The compiler cannot always perform autovectorisation, and even when it succeeds, it may produce very suboptimal vectorised code.

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

#text(size: 40pt)[
  → #link("https://www.felixcloutier.com/x86/cvttps2dq")[
    CVT·T·PS·2·DQ
  ]]
#linebreak()
_Convert With Truncation Packed Single Precision Floating-Point Values
#linebreak()
to Packed Signed Doubleword Integer Values_

#quote(attribution: [Intel® 64 and IA-32 Architectures Software Developer’s Manual])[
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

== Benchmark: CVTTPS2DQ vs. naïve implementation

#figure(
  image("assets/cvttps2dq-speedup.svg", width: 65%),
  numbering: none,
) <screlu>

= Accelerating neural networks
_A million chess positions solved per second._

---

Here is an activation function used in the best chess engines:

$ "SCReLU"(x) = "clamp"(x, 0, 1)^2 "       “Squared Clipped ReLU”" $

---

#figure(
  image("assets/screlu.png", width: 100%),
  numbering: none,
) <screlu>

---

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

= Parsing JSON at incredible speed
_We are thus motivated to make JSON parsing as fast as possible._

---

#link("https://arxiv.org/abs/1902.08318")[#smallcaps[Langdale & Lemire (2019)]]
present a SIMD algorithm for parsing JSON, the first to process gigabytes of
data per second on a single core.

A subproblem in their algorithm is the classification of
#smallcaps[structural characters] – ‘`[`’, ‘`]`’, ‘`{`’, ‘`}`’, ‘`:`’, and ‘`,`’ – those
characters that delimit the locations of objects and arrays.

---

#figure(
  grid(
    columns: (1fr, 1.2fr),
    column-gutter: 1em,
    align: horizon,

    ```json
    {
      "width": 800,
      "height": 600,
      "title": "myhouse",
      "url": "http://ex.com/img.png",
      "private": false,
      "thumbnail": {
        "url": "http://ex.com/th.png",
        "height": 125,
        "width": 100
      },
      "tags": [ 116, 943, 234 ],
      "owner": null
    }
    ```,

    canvas(length: 1cm, {
      import draw: *

      let indent = 0.5
      let row-h = 0.85

      let node(level, row, body, name) = content(
        (level * indent, -row * row-h),
        box(
          stroke: 0.8pt + black,
          inset: (x: 5pt, y: 3.7pt),
          fill: white,
          body,
        ),
        anchor: "west",
        name: name,
      )

      let spine(parent, children) = on-layer(-1, {
        let last = children.last()
        // single continuous vertical from parent's center down to the last child's row
        line(parent + ".west", (parent + ".west", "|-", last + ".west"))
        // a horizontal tick into each child
        for c in children {
          line((parent + ".west", "|-", c + ".west"), c + ".west")
        }
      })

      node(0, 0, [`root`], "root")
      node(1, 1, raw("\"width\": 800", lang: "json"), "a")
      node(1, 2, raw("\"height\": 600", lang: "json"), "b")
      node(1, 3, raw("\"title\": \"myhouse\"", lang: "json"), "c")
      node(1, 4, raw("\"url\": \"http://ex.com/img.png\"", lang: "json"), "d")
      node(1, 5, raw("\"private\": false", lang: "json"), "e")
      node(1, 6, raw("\"thumbnail\"", lang: "json"), "thumb")
      node(2, 7, raw("\"url\": \"http://ex.com/th.png\"", lang: "json"), "t1")
      node(2, 8, raw("\"height\": 125", lang: "json"), "t2")
      node(2, 9, raw("\"width\": 100", lang: "json"), "t3")
      node(1, 10, raw("\"tags\"", lang: "json"), "arr")
      node(2, 11, raw("116", lang: "json"), "ar1")
      node(2, 12, raw("943", lang: "json"), "ar2")
      node(2, 13, raw("234", lang: "json"), "ar3")
      node(1, 14, raw("\"owner\": null", lang: "json"), "owner")

      spine("root", ("a", "b", "c", "d", "e", "thumb", "arr", "owner"))
      spine("thumb", ("t1", "t2", "t3"))
      spine("arr", ("ar1", "ar2", "ar3"))
    }),
  ),
) <fig:jsonexample>

---

#text()[
  #show raw.where(lang: "sjson"): r => {
    let c = gradient.linear(red, blue, space: oklch).sample(15%)
    let c2 = gradient.linear(red, blue, space: oklch).sample(85%)
    show ",": set text(c)
    show "}": set text(c)
    show "{": set text(c)
    show "]": set text(c)
    show "[": set text(c)
    show ":": set text(c)

    r
  }
  ```sjson
  {
    "width": 800,
    "height": 600,
    "title": "myhouse",
    "url": "http://ex.com/img.png",
    "private": false,
    "thumbnail": {
      "url": "http://ex.com/th.png",
      "height": 125,
      "width": 100
    },
    "tags": [ 116, 943, 234 ],
    "owner": null
  }
  ```
]

#pause

Goal: Efficiently extract the indices of these structural characters.

---

#text(font: ("Berkeley Mono", "TX-02"))[
  #set par(justify: false)
  #let rb(content) = {
    set text(fill: gradient.linear(red, blue, space: oklch))
    box(content)
  }
  #let br(content) = {
    set text(fill: gradient.linear(blue, red, space: oklch))
    box(content)
  }
  #show raw.where(lang: "sjson"): r => {
    let c = gradient.linear(red, blue, space: oklch).sample(15%)
    show ",": set text(c)
    show "}": set text(c)
    show "{": set text(c)
    show "]": set text(c)
    show "[": set text(c)
    show ":": set text(c)

    r
  }
  #show raw.where(lang: "bits"): r => {
    let c = gradient.linear(red, blue, space: oklch).sample(15%)
    show "1": set text(c)
    show "0": set text(gray)

    r
  }
  #align(center)[
    ```sjson
     “{  "width": 800,  "height": 600,  "title": "myhouse",  "url": "http://e…”
    ```
    ```bits
    b10000000001000010000000000100001000000000100000000001000000010000001000…
    ```
  ]
]

== Naïve solution

```rust
fn find_structural_characters(json: &str, bitmask: &mut [u64]) {
  for (i, c) in json.as_bytes().iter().enumerate() {
    if STRUCTURAL.contains(c) {
      bitmask[i / 64] |= 1 << (i % 64);
    }
  }
}
```

== Efficiently extracting structural indices

#grid(
  columns: (1fr, 1.2fr),
  column-gutter: 3em,
  align: top,
  [
    #text(size: 40pt)[
      → #link("https://www.felixcloutier.com/x86/pcmpeqb:pcmpeqw:pcmpeqd")[
        P·CMP·EQ·B
      ]]
    #linebreak()
    _Compare Packed Data for Equal_

    “Performs a SIMD compare for equality of the packed bytes.

    If equal, the corresponding lane in the destination
    is set to all 1s; otherwise, it is set to all 0s.”
  ],
  [
    #text(size: 40pt)[
      → #link("https://www.felixcloutier.com/x86/pmovmskb")[
        P·MOV·MSK·B
      ]]
    #linebreak()
    _Move Byte Mask_

    “Creates a mask made up of the most significant bit of each byte of
    the source operand and stores the result in the low byte or word of
    the destination.”
  ],
)

#align(
  right,
)[
  — Intel® 64 and IA-32 Architectures Software Developer’s Manual
  #footnote()[Quotes edited for clarity & concision.
  ]]

---

#align(center)[\~ under construction \~]

To be written:

- slide highlighting all structural characters in the previous JSON document
- slide explaining cmp-eq → or → tzcnt → blsr
- code listing

---

= A really weird instruction
_Galois Field Affine Transformation_

---

#text(size: 40pt)[
  → #link("https://www.felixcloutier.com/x86/gf2p8affineqb")[
    GF2P8·AFFINE·Q·B
  ]]
#linebreak()
_Galois Field Affine Transformation_

#quote(attribution: "Intel® 64 and IA-32 Architectures Software Developer’s Manual")[
  The AFFINEB instruction computes an affine transformation in the Galois Field 2#super[8].
]

#quote(attribution: link(
  "https://gist.github.com/animetosho/d3ca95da2131b5813e16b5bb1b137ca0",
)[Anime Tosho, Unexpected Uses for the Galois Field Affine Transformation Instruction])[
  I suspect GFNI was aimed at accelerating SM4 encryption, however, one of the instructions can be used for many other purposes. […] of particular interest here is the Affine Transformation (GF2P8AFFINEQB), aka bit-matrix multiply, instruction.
]

---

== Within-byte bit reversal

Imagine: you have a black-and-white display, like an E-ink screen or a thermal receipt printer.

In memory, images for these are stored as 1-bit-per-pixel, so a single byte holds 8 pixels.

How might you efficiently implement _mirroring_?

#pause

Problem: You must mirror not just *bytes*, but the *bits within each byte*.

\

#text(size: 20pt, font: ("Berkeley Mono", "TX-02"))[
  #set par(justify: false)
  #show raw.where(block: false): set text(1em / 0.8)
  #let rb(content) = {
    set text(fill: gradient.linear(red, blue, space: oklch))
    box(content)
  }
  #let br(content) = {
    set text(fill: gradient.linear(blue, red, space: oklch))
    box(content)
  }
  #align(center)[
    0b #rb[11110000] #rb[10101010] #rb[10110100] #rb[10100100] #rb[01111100] #rb[10101001] …
    #linebreak()
    `     ↘  ↙     ↘  ↙     ↘  ↙     ↘  ↙     ↘  ↙     ↘  ↙    `
    #linebreak()
    0b #br[00001111] #br[01010101] #br[00101101] #br[00100101] #br[00111110] #br[10010101] …
  ]
]

== Vector-matrix multiplication refresher

Multiplying a vector by an anti-diagonal matrix _reverses_ it.

#text(size: 40pt)[
  #set math.mat(delim: "[")
  #set math.vec(delim: "[")
  #let grad = gradient.linear(red, blue, space: oklch)
  #let lo = 20%
  #let hi = 80%
  #let c1 = grad.sample(lo + (hi - lo) * 0 / 3)
  #let c2 = grad.sample(lo + (hi - lo) * 1 / 3)
  #let c3 = grad.sample(lo + (hi - lo) * 2 / 3)
  #let c4 = grad.sample(lo + (hi - lo) * 3 / 3)
  $
    mat(
      0, 0, 0, #text(c1)[1] ;
      0, 0, #text(c2)[1], 0;
      0, #text(c3)[1], 0, 0;
      #text(c4)[1], 0, 0, 0;
    ) dot
    vec(
      #text(c4)[a],
      #text(c3)[b],
      #text(c2)[c],
      #text(c1)[d],
    ) = vec(
      #text(c1)[d],
      #text(c2)[c],
      #text(c3)[b],
      #text(c4)[a],
    )
  $
]

== How do we use GF2P8AFFINEQB to do it?

#text[
  #set rect(
    inset: 0pt,
    width: 100%,
    stroke: none,
  )

  #grid(
    columns: (3fr, 2fr),
    rows: auto,
    rect[
      GF2P8AFFINEQB computes $(A · x) ⊕ b$ in $"GF"(2^8)$.
      #linebreak()
      With the anti-diagonal matrix $A$, within each byte,
      #linebreak()
      output bit k = input bit (7 – k).

      #pause

      ```rust
      fn bit_reverse(x: [u8; 64]) -> [u8; 64] {
          let m = _mm512_set1_epi64(ANTI_DIAG);
          _mm512_gf2p8affine_epi64_epi8(x, m, 0)
      }
      ```

      #h(1fr) ↓ #h(2fr)

      ```asm
      vgf2p8affineqb zmm0, zmm0,
        qword ptr [rip + .ANTI_DIAG]{1to8}, 0
      ```
    ],
    rect[
      #figure(
        image("assets/matrix.svg", width: 100%),
        numbering: none,
      ) <registers>
    ],
  )
]

= Advice for the working programmer
_Please make your data more boring._

---

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
// When showing instructions, consider highlighting them as you mention them?
// Or add an extra diagram showing it operating on the numbers?
// Slide 17 - consider add an exmaple number to demonstrate the clamping and squaring
// Note: we can see you cursor but it's small
