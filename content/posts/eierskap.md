---
title: "Eierskap: Ikke bare en \"Rust-greie\""
date: 2023-12-29T18:01:35+0100
draft: false
toc: false
images:
tags:
  - rust
  - systemprogrammering
---

Jeg kom nylig over et artig eksempel av erierskap i praksis.

```c
#include <stdio.h>

char* example() {
	return "Hello world!";
}

int main() {
	printf("%s\n", example());
	return 0;
}
```

Her har har vi funksjonen `example` som returnerer `"Hello world!"`. Denne
verdien printes i funksjonen `main`.

```bash
$ clang -O3 example.c
$ ./a.out
Hello world!
```

Kult! Programmet printer "Hello world!" :) Hva om vi gjør en liten
modifikasjon?

```c
#include <stdio.h>
#include <string.h>

char* example() {
	char out[13] = "Hello ";
	return strcat(out, "world!");
}

int main() {
	printf("%s\n", example());
	return 1;
}
```

Her har vi bare erstattet `"Hello world!"` med `strcat("Hello ", "world!")`.
Det burde vel ikke gjøre noen forskjell.

```bash
$ clang -O3 example.c
$ ./a.out
d␃Z
```

Hv..a? Programmet printer bare masse rare tegn?!

## Hva skjedde?
Som mange andre rare observasjoner innen programmering, er årsaken til dette
resultatet hvordan programmet håndterer minne. I C er en
[streng](https://en.wikipedia.org/wiki/String_(computer_science)) en
[tabell](https://en.wikipedia.org/wiki/Array_(data_structure)) med bokstaver
som avsluttes med en [nullbyte](https://en.wikipedia.org/wiki/Null_character).
Om en streng tilordnes en variabel, er verdien til varabelen en
[peker](https://en.wikipedia.org/wiki/Pointer_(computer_programming)) til den
første bokstaven i strengen.

Okay, så hva er det som skjer? Når man oppretter en ny variabel, lagres
variabelverdien øverst i den nåværende
[kallstakken](https://en.wikipedia.org/wiki/Call_stack). Denne verdien kan
enten være hele verdien som lagres (hvis verdien f.eks. er en int), eller en
peker til hvor i minnet verdien til variabelen faktisk ligger.

Hvis man oppretter en tabell inni en funksjon, opprettes minnet som er
nødvendig for denne tabellen øverst i den nåværende kallstakken. Verdien til
pekeren er minneadressen til det første elementet av tabellen. Hvis man
returnerer fra denne funksjonen, deallokeres tabellen sammen med resten av
kallstakken. Hvis man returnerer en peker til en tabell som er lagret i
stakken, peker denne pekeren nå på udefinert minne. Det er dette som skjer i
eksempel nummer 2.

Okay, men hva er da greia med det første eksempelet? Hvorfor fungerer dette som
forventet? Vi kan få et lite hint om vi printer ut adressene til de ulike
variablene :)

```c
#include <stdio.h>

int main() {
	char string[13] = "Hello world!";
	printf("Streng-addresse: %p\n", string);
	printf("Peker-addresse:  %p\n", &string);
	return 0;
}

// Resultat:
// Streng-addresse: 0x7ffc98bf8730
// Peker-addresse:  0x7ffc98bf8730
```

Pekeren og strengen er på samme adresse. Strengen ble allokert i stakken.

```c
#include <stdio.h>

int main() {
	char* string = "Hello world!";
	printf("Streng-addresse: %p\n", string);
	printf("Peker-addresse:  %p\n", &string);
	return 0;
}

// Resultat
// Streng-addresse: 0x595c41bd1004
// Peker-addresse:  0x7ffeed215580
```

Pekeren og strengen er på helt forskjellige steder i minnet! I dette tilfellet
er det en illusjon at strengen opprettes i stakken. Selv om strengen først
tilordnes i funksjonen, allokeres strengen ved programstart i en minnesegmentet
[data](https://en.wikipedia.org/wiki/Data_segment). Minnet forblir tilgjengelig
til programmet avsluttes.

## Hva har dette med eierskap å gjøre?
[Eierskap](https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html) er et
konsept i [Rust](https://www.rust-lang.org/) som baserer seg på at alle verdier
kun har én eier. Eieren er ansvarlig for frigjøringen av minnet. Eierskapet kan
overføres eller lånes bort. Om eierskapet lånes bort, beholder den opprinnelige
eieren pliktene som kommer med eierskapet etter at utlånet er omme. Om
eierskapet gis bort, overføres eierpliktene til den nye eieren. Til gjengjeld
kan den opprinnelige eieren ikke lenger akksessere verdien. Verdier kan
nemmelig kun aksesseres dersom man enten eier verdien eller om verdien er lånt
bort til deg. På denne måten unngår man mulighetene for vanlige minnefeil som
[minnelekasjer](https://en.wikipedia.org/wiki/Memory_leak), [hengende
pekere](https://en.wikipedia.org/wiki/Dangling_pointer) og
[dataløp](https://en.wikipedia.org/wiki/Race_condition).

Eksempelet vi så på i stad, var et eksempel på en hengende peker. Vi prøver å
lese fra en minneadresse som ikke lenger er gyldig. La oss prøve å gjennskape
det første eksempelet i Rust.

```rust
fn example() -> &str {
    return "Hello world!";
}

fn main() {
    println!("{}", example());
}
```

Funksjonen example returnerer nå en referanse til en streng. Hvis vi prøver å
kompilere dette får vi derimot en feilmelding.

```rust
error[E0106]: missing lifetime specifier
 --> src/main.rs:1:17
  |
1 | fn example() -> &str {
  |                 ^ expected named lifetime parameter
  |
  = help: this function's return type contains a borrowed value, but there is no value for it to be borrowed from
help: consider using the `'static` lifetime
  |
1 | fn example() -> &'static str {
  |                  +++++++

For more information about this error, try `rustc --explain E0106`.
```

Rust gir oss faktisk en gangske forståelig feilmelding! Referanser er navnet på
de lånte verdiene jeg snakket om tidligere. Disse trenger et såkalt "lifetime".
Dette er en verdi som forteller kompilatoren hvor lenge en referanse maksimalt
kan "leve", altså hvor lenge eieren til variabelen har tenkt å holde på den.
Lifetimes er i de aller fleste tilfeller definert implisitt, men noen ganger må
vi spesifisere dem selv. På denne måten kan man unngå situasjoner der man har
en referanse til en verdi som ikke lenger finnes, eller på andre ord: At
variabellånet varer lengre enn det orginale eierskapet av variabelen.

Om du husker tilbake på eksempelet vi prøver å gjenskape, var strengen lagret i
datasegmentet av minnet. Dette er en statisk minneregion som allokeres ved
programstart og deallokeres ved programslutt. Referanser til denne
minneregionen kan markeres med lifetimen `static`.

```rust
fn example() -> &'static str {
    return "Hello world!";
}

fn main() {
    println!("{}", example());
}
```

Dette programet kompilerer og kjører uten problemer! Det printer det samme som
det første eksempelet vårt!

```bash
$ cargo run --release
   Compiling stack-string v0.1.0 (/home/kaholaz/code/rust/stack-string)
    Finished release [optimized] target(s) in 0.18s
     Running `target/release/stack-string`
Hello world!
```

La oss prøve oss på eksempel nummer to!

```rust
fn example() -> &'static str {
    return "Hello " + "world!";
}

fn main() {
    println!("{}", example());
}
```

Å nei :( Vi får igjen en feilmelding når vi prøver å kompilere...

```rust
error[E0369]: cannot add `&str` to `&str`
 --> src/main.rs:2:21
  |
2 |     return "Hello " + "world!";
  |            -------- ^ -------- &str
  |            |        |
  |            |        `+` cannot be used to concatenate two `&str` strings
  |            &str
  |
  = note: string concatenation requires an owned `String` on the left
help: create an owned `String` from a string reference
  |
2 |     return "Hello ".to_owned() + "world!";
  |                    +++++++++++

For more information about this error, try `rustc --explain E0369`.
```

I Rust finnes det flere typer som representerer strenger. Vi har vært innom
`&str`, men nå støter vi på en ny en: `String`. Mens `&str` representerer en streng
som vi låner, representerer `String` en streng vi eier. Det betyr at vi nå har
ansvaret for minnet strengen opptar, og at minnet automatisk blir deallokert
for oss når vi returnerer fra den nåværende funksjonen. For at det ikke skal
skje, må vi overføre eierskapet. En måte å gjøre dette på, er ved å returnere
verdien. Når vi har implementert forslaget fra kompilatoren og endret
returtypen ser programmet vårt slikt ut:

```rust
fn example() -> String {
    return "Hello ".to_owned() + "world!";
}

fn main() {
    println!("{}", example());
}
```

Dette kompilerer og kjører uten problemer!

## Kan dette overføres til C?
Vi har sett at man kan unngå å gjøre enkle feil når det kommer til
minnebehandling ved å tenkte på eierskap i Rust. Hvordan kan vi bruke dette til
å fikse feilen vi hadde i C programmet vårt?

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char* example() {
	char* out = malloc(13);
	strcpy(out, "Hello ");
	return strcat(out, "world!");
}

int main() {
	char* ex = example();
	printf("%s\n", ex);

	free(ex);
	return 0;
}
```

Her må vi fohåndsallokere plassen til strengen i
[heapen](https://en.wikipedia.org/wiki/Manual_memory_management), samt passe på
at vi frigjør minnet etter at vi er ferdig med det. Legg merke til at selv om
ikke må tenke på eierskap, oppstår de samme problemene som Rust-kompilatoren
advarte oss om. Hvis man returnerer en peker til en verdi som kanskje
forsvinner før pekeren gjør det, kan man få en hengende peker. Hvis man ikke
tenker på hvem som har ansvaret for å deallokere minnet til verdier, kan man få
minnelekasjer.

I motsetning til i Rust, gjør ikke C noen forskjell på pekere som vi låner og
pekere vi eier. Det betyr at det kan være uklarheter når det kommer til om det
er vårt ansvar å frigjøre minnet pekeren peker til.

## Konklusjon
Selv om C ikke har et innebygd system for eierskap og livstider som Rust, betyr
det ikke at konseptet ikke har noen verdi når det kommer til utvikling av
programmer skrevet i C. C gir deg frihet til å programmere på lavt nivå. Til
gjengjeld krever det at man gjør en bevisst innsats for å unngå vanlige feil
ved håndtering av minne. Personlig har min forståelese og bevisthet knyttet til
minne blitt bedre etter at jeg nå har vasset litt rundt i Rustverdenen. Jeg
håper derfor at du (om du allerede ikke har gjort det) tar sjansen og dupper
tåa di nedi du også! Kanskje det lønner seg for deg og?
