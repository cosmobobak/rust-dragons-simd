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
// #show math.equation: set text(font: "Fira Math")
#set strong(delta: 175)
#set par(justify: true)

#show link: smallcaps

#set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

= Outline <touying:hidden>

#outline(title: none, indent: 1em, depth: 1)

= What is SIMD?

---

For a long time, computers got faster by increasing clock
frequency – executing more instructions in the same amount of time.

This was achievable in virtue of #link("https://en.wikipedia.org/wiki/Dennard_scaling")[Dennard scaling],
a _scaling law_ stating that shrinking transistors does not affect their power density#footnote[That is, power per
  unit area.], allowing components of equal transistor count to be run at lower power and higher frequency.

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

= TODO

common applications
unsafe to_int for autovec
lizard screlu
general coding style (operate on batches)
→ cite casey, matklad.


















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
