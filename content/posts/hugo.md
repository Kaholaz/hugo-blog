---
title: "Hugo"
date: 2023-12-26T16:16:07+01:00
draft: false
toc: false
images:
tags:
  - web
  - privat
---

Nå er bloggen gjennoppstått! Denne gangen med hjelp av [Hugo](https://gohugo.io/) :)

## Hva er Hugo?
Hugo er en statisk side generator. Du skriver innlegg i markdown, også rendres
disse til HTML. Når du har HTML-en, kan du egentlig gjøre det du vil med den:
Servere den fra en webserver, redigere den i VScode, eller sende den til
kompisen din og si at du kan lage nettsider.

## Motivasjon
Den forrige bloggen min var laget med [Wordpress](https://wordpress.com/), en
grafisk nettsidebygger som er laget med PHP og MySQL. Programmet kan brukes til
å lage alt fra blogger til nettbutikker. For mitt bruk, fungerte det egentlig
ganske greit, men det var et par punkter gjorde at det ikke var helt optimalt.

En ting jeg ikke likte med Wordpress, var fokuset på utseende. Programmet er
designet slik at man lett skal kunne plassere ulike elementer i et
brukerdefinert layout. Det kan være kjekt om man:

1. Ønsker å definere layout selv
1. Ikke kan HTML

For meg gjelder ingen av delene. Jeg ønsker først og fremst å skrive tekster,
og i de tilfellene jeg bry meg om layout, klarer jeg fint å skrive litt HTML.

Det at at Wordpress er designet for å gjøre det lett å endre layout, gjør det
krunglete å skrive innlegg. Hvis jeg for eksempel skal skrive et innlegg med to
overskrifter, er det 4 elementer som må opprettes (et for hver overskrift og
hver tekst). Dette tar vekk fokuset fra skrivingen.

Med Hugo derimot, er fokuset rettet mot skrivingen. Når man skal lage et nytt
innlegg, kan man få Hugo til å generere en ny markdownfil for deg.
```bash
hugo new content posts/hugo
```
Nå har jeg en fil ny fil (`content/posts/hugo.md`). Denne kan man fint begynne
å skrive i og endre på med ditt yndlingstekstredigeringsprogram. Personlig
bruker jeg [Neovim](https://neovim.io/). Det at jeg nå kan klare meg uten
datamusa når jeg lager et nytt innlegg, ser jeg på som en veldig positiv ting.

En annen fordel med at alle innleggene mine er markdown filer, er at det er
ekstremt kjekt å jobbe med tekstfiler! Om jeg skal endre på innholdet, kan jeg
bruke Neovim. Om jeg skal finne ut av når jeg skrev om en spesifikk ting, kan
jeg bruke [ripgrep](https://github.com/BurntSushi/ripgrep). Om jeg har lyst til
å slutte å bruke Hugo kan jeg også det, fordi det kun er tekst!

## Fremgangsmåte
Det å sette opp bloggen var egentlig veldig lett! Slik var fremgangsmåten:

### Sett opp Hugo
1. Installer Hugo.
	```bash
	sudo snap install hugo
	```
1. Start et nytt prosjekt.
	```bash
	hugo new site blog
	cd blog
	git init
	```
1. Last ned et tema.
	```bash
	git add submodule https://github.com/rhazdon/hugo-theme-hello-friend-ng themes/hello-friend-ng
	```
1. Fiks `hugo.toml` i henhold til [dokumentasjonen](https://github.com/rhazdon/hugo-theme-hello-friend-ng).
1. Enjoy!

### Deployment
Jeg er så heldig å ha tilgang til en server der jeg kan servere hva enn jeg
måtte ønske! Det gjør jobben veldig lett :) På serveren har jeg en mappe
(`/var/www/kaholaz.net/`), der jeg putter ferdiggenerert HTML. Får å gjøre
denne forflytningen lettvint, har jeg laget et kort skript for å generere HTML
og flytte det over til serveren.
```sh
hugo || exit
rsync public/ vsbugge@navi.samfundet.no:/var/www/kaholaz.net/ -r --delete -P
```

Når dette er på plass, trenger vi bare et søtt lite Apache-config for å gjøre
susen.
```xml
<VirtualHost *:80>
	ServerName kaholaz.net
	DocumentRoot /var/www/kaholaz.net/
	<Location />
		Options -Indexes
	</Location>

	ErrorDocument 404 /404.html
</VirtualHost>
```

## Konklusjon
Jeg tror dette er en veldig flott løsning for en personlig blogg. Jeg kommer
til å tilgjegeliggjøre kildekoden på [min
GitHub](git@github.com:Kaholaz/hugo-blog.git), og fortsette å oppdatere bloggen
gjenvlig. Det er en del ting å fikse, slik som tagger og innleggstyper. Alt i
alt vil jeg anbefale Hugo om man ønsker en no-nonsense måte å skrive en blogg
på!
