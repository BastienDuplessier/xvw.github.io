% Les types fantômes
% Xavier Van de Woestyne
% Novembre 2014

# Les types fantômes

> Cet article n'a pas grand chose d'inédit. Il s'agit d'une occasion de
> présenter une utilisation amusante d'un système de type au
> travers du langage OCaml pour répondre à une problématique pouvant
> être très coûteuse. Il est important de noter que **cet article utilise au
> moins OCaml 4**.

## Avant-propos
Pour une bonne compréhension de cet article, il est pré-requis d'avoir
une connaissance sommaire du langage OCaml (connaître les types variants/
disjonctions, les modules et les types abstraits et, *évidemment*,
être à l'aise avec la syntaxe de OCaml).
Avant de nous lancer dans le *vif* du sujet, nous commencerons par
évoquer un cas pratique où les types fantômes auraient étés utiles.
Ensuite nous rapellerons quelques petites choses relatives à OCaml, et
nous définirons *enfin* ce que sont les types fantômes. En fin d'article
quelques cas pratiques seront présentés.

### Mars Climate Orbiter

Le 23 Mars 1999, la sonde "*Mars Climate Orbiter*" tente d'effectuer sa
manoeuvre d'insertion autour de l'orbite de Mars via une procédure entièrement
automatisée. Durant cette démarche, la radio devait impérativement
être coupée durant le temps où la sonde se trouverait derrière Mars.
Le lendemain, la sonde n'avait toujours pas émis de signaux radio. Elle
est considérée comme perdue.
oLa sonde avait suivi une trajectoire beaucoup trop basse (près de 140 km
de dessous de ce qui était prévu) par rapport à sa vitesse et s'est donc
probablement transformée en boule de feu.
Une commission d'enquête révelera vite la raison de cette erreur de
trajectoire, la sonde recevait la poussée de ses micro propulseurs en
**Livre-force.seconde** (une unité de mesure anglo-saxonnes) et le
logiciel interne de la sonde traitait ces données comme s'il s'agissait
de **Newton.seconde**. Cette non-concordance de données à entraînée des
corrections sur la trajectoire de la sonde, l'amenant à sa déstruction
et faisant perdre à la NASA près de 125 millions de dollars.

Cette erreur a des conséquences impressionnantes. Et même si l'on
pourrait s'interroger de comment la NASA a pu commettre une erreur aussi
grande, elle est extrêmement difficile à déceler car elle ne provoque
aucune erreur de compilation. Toutes les données étant traîtées de
manière uniforme, comme des flottants. L'enjeu de cet article est de
présenter une manière élégante de prévenir ce genre d'erreur à la compilation.

#### Limite des variants classiques

Limitons notre problème à la distinction des **centimètres** et des
**kilomètres**, et comme fonctionnalités, des conversions :

*    `cm_to_km`
*    `km_to_cm`

Naïvement, lorsque j'ai été amené à lire le problème de typage soulevé
par la sonde *Mars Climate Orbiter*, oet de manière plus générale à la
représentation d'unités de mesure, j'ai pensé à la définition d'une
disjonction séparant les kilomètres des centimètres. Avec, par exemple,
ceci comme implémentation :

```ocaml
exception IllegalMeasureData
type measure = 
| Cm of float 
| Km of float 

let cm x = Cm x
let km x = Km x

let cm_to_km = function 
  | Cm x -> Km (x *. 1000.0)
  | _ -> raise IllegalMeasureData

let km_to_cm = function 
  | Km x -> Cm (x /. 1000.0)
  | _ -> raise IllegalMeasureData
```

Cette manière de procéder semble correcte, et si par exemple je tente
une conversion sur une valeur invalide, par exemple
`let test = km_of_cm (cm 10.0)`, mon code renverra une erreur
`IllegalMeasureData`, et ce à la compilation. Cependant, si l'erreur se
déclenche, c'est uniquement parce que la variable *test* évalue
directement l'expression `km_of_cm (cm 10.0)`. Voyons ce qu'il se passe
si nous essayons de compiler notre code avec cette déclaration :
`let test () = km_of_cm (cm 10.0)`. Cette fois-ci, la compilation
fonctionne.

Ce qui prouve que les erreurs ne sont pas vérifiées à la compilation. Car
les fonction `km_to_cm` et `cm_to_km` ont le types `measure -> measure`.
Et donc une incohérence telle que passer un Kilomètres à la fonction
`cm_to_km` ne peut être détectée réellement à la compilation.
