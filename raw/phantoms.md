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
  | Cm x -> Km (x *. 100000.0)
  | _ -> raise IllegalMeasureData

let km_to_cm = function 
  | Km x -> Cm (x /. 100000.0)
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

## Implémentation des types fantômes
Nous avons vu que les variants classiques ne permettent pas assez de
vérification pour distinguer des données au sein d'un même type à la
compilation (car oui, il serait possible de distinguer chaque unité de
mesure dans des types différents, de cette manière :

```ocaml
module Measure =
struct
  type km = Km of float
  type cm = Cm of float
end
```

Cependant ce n'est absolument pas confortable et ce n'est pas réellement
l'intérêt de cet article).
Donc avant de définir et de proposer une implémentation, nous allons
devoir (re)voir quelques outils en relation avec le langage OCaml.

### Les variants polymorphiques
Bien que très utiles dans le *design* d'application, les variants
possèdent des limitations. Par exemple, le fait qu'un type Somme ne
puisse être enrichi de constructeurs (ce qui n'est plus tout à fait
vrai depuis *OCaml 4.02.0*), mais aussi le fait qu'un constructeur ne
puisse appartenir qu'à un seul type.
Les variants polymorphes s'extraient de ces deux contraintes et peuvent
même être déclarés à la volées, sans appartenir à un type prédéfini. La
définition d'un constructeur polymorphe est identique à un constructeur
normal (il commence par une majuscule) mais est précédé du caractère
*`*.

```ocaml
# let a = `Truc 9;;
val a : [> `Truc of int ] = `Truc 9
# let b = `Truc "test";;
val b : [> `Truc of string ] = `Truc "test"
```

Comme vous pouvez le voir, je me suis servi deux fois du constructeur
*`Truc* en lui donnant des arguments à type différent et sans l'avoir
déclaré.

#### Borne superieur et inférieur
L'usage des variants polymorphes introduit une notation de retour
différente de celle des variants normaux. Par exemple :

```ocaml
let to_int = function 
  | `Integer x -> x 
  | `Float x -> int_of_float x;;

let to_int' = function 
  | `Integer x -> x 
  | `Float x -> int_of_float x
  | _ -> 0

# val to_int : [< `Float of float | `Integer of int ] -> int = <fun>
# val to_int' :[> `Float of float | `Integer of int ] -> int = <fun>
```

Ce que l'on remarque c'est que le chevron varie. Dans le cas où la
fonction n'évalue *que* les constructeurs *Integer* et *Float*, le
chevron est `<`. Si la fonction peut potentiellement évaluer autre
chose, le chevron est `>`.

*  `[< K]` indique que le type ne peut contenir que K
*  `[> K]` indique que le type peut contenir au moins K

Nous verrons que cette restriction sur les entrées permettra d'affiner
le typage de fonctions.

#### Restriction sur les variants polymorphes
Les variants polymorphes ne permettent tout de même pas de faire des
choses comme :

```ocaml
let truc = function
  | `A -> 0
  | `A x -> x 
```

Au sein d'une *même* fonction, on ne peut pas utiliser un *même* variant
avec des arguments différents. De mon point de vue, c'est plus logique
que limitant. Mais rien n'empêche de faire deux fonctions, qui elles
utilisent des variants polymorphes à arguments variables.

#### Nommer les variants polymorphes
Bien que l'on puisse les nommer à l'usage, il peut parfois être
confortable de spécifier des variants polymorphes dans un type nommé. (
Ne serait-ce que pour le confort de la réutilisation). Leur syntaxe (que
nous verrons un peu plus bas) est assez proche des déclaration de
variants classique, cependant, **on ne peut pas** spécifier la borne
dans la définition de type de variants polymorphes. Ce qui est
parfaitement logique car un type ouvert (donc borné) ne correspond pas
à un seul type mais à une collection de types.

A la différence des variants normaux, les variants polymorphes se
déclarent dans une liste dont les différentes énumérations sont séparés
par un pipe. Par exemple :

```ocaml
type poly_color = [`Red of int | `Green of int | `Blue of int]
```

Il est évidemment possible d'utiliser les variants polymorphes dans la
déclaration de variants normaux, par exemple :

```ocaml
type color_list =
| Empty
| Cons of ( [`Red of int | `Green of int | `Blue of int]  *  color_list)
```

Par contre, même si dans les définitions de types on ne peut pas
spécifier de borne, on peut le faire dans les contraintes de types des
fonctions. Et c'est grâce à cette autorisation que nous utiliserons les
types fantômes avec des variants polymorphes.

#### Conclusion sur les variants polymorphes
Les variants polymorphes permettent plus de flexibilité que les variants
classique. Cependant, ils ont aussi leurs petits soucis :

*  Ils entraînent des petites pertes d'efficacité (mais ça, c'est
superflu)
*  Ils diminuent le nombre de vérifications statiques
*  Ils introduisent des erreurs de typage très complexe

En conclusion, j'ai introduit les variants polymorphes car nous nous en
serviront pour les types fantômes, cependant, il est conseillé de ne
s'en servir qu'en cas de réel besoin.

### A l'assault des types fantômes
Après une très longue introduction et une légère mise en place des
pré-requis, nous allons expliquer ce que sont les types fantômes.
Ensuite, nous évoquerons quelques cas de figures.

> Concrètement, un type fantôme n'est rien de plus qu'un type abstrait
> paramétré dont au moins un des paramètres n'est présent que pour
> donner des informations sur comment utiliser ce type.

Concrètement, voici un exemple de type fantôme : `type 'a t = float`.
Si le type n'est pas abstrait, le type t sera identique à un flottant
normal. Par contre, si le type est abstrait (donc que son implémentation
est cachée), le compilateur le différenciera d'un type flottant.

Avec cette piètre définition on ne peut pas aller très loin. Voyons dans
les sections suivantes quelques cas de figures précis d'utilisation
des types fantômes.

## Distinguer des unités de mesure
Si cet article a été introduit via une erreur dûe à des unités de mesure,
ce n'est pas tout à fait innocent. Nous avions vu que via des variants
classiques, il n'était à priori pas possible (en gardant un confort
d'utilisation) de distinguer à la compilation des unités de mesures.
Nous allons voir qu'au moyen des types fantômes, c'est très simple.

Par soucis de lisibilité, j'utiliserai des sous-modules. Cependant, ce
n'est absolument pas obligatoire.

```ocaml
module Measure :
sig 
  type 'a t
  val km : float -> [`Km] t 
  val cm : float -> [`Cm] t
end = struct
  type 'a t = float
  let km f = f
  let cm f = f
end
```

Ce module produit offre des fonctions qui produisent des valeurs de type
`Measure.t`, mais ces données sont décorées. Les kilomètres et les
centimètres ont donc une différence structurelles.
Imaginons que nous enrichissions notre module d'une fonction addition,
dont le prototype serait : `'a t -> 'a t -> 'a t`, et le code ne serait
qu'un appel de `(+.)` (l'addition flottante) :


```ocaml
module Measure :
sig 
  type 'a t
  val km : float -> [`Km] t 
  val cm : float -> [`Cm] t
  val ( + ) : 'a t -> 'a t -> 'a t
end = struct
  type 'a t = float
  let km f = f
  let cm f = f
  let ( + ) =  ( +. )
end
```

Que se passe t-il si je fais l'addition de centimètres et de kilomètres
(créés au moyen des fonctions `km` et `cm`) ? Le code plantera à la compilation
car il est indiqué dans le prototype de la fonction que le paramètre
du type t (`'a`) doit impérativement être le même pour les deux membres
de l'addition. Nous avons donc une distinction, au niveau du typeur, d'unités
de mesure, pourtant représentée via des entiers.

Retournons à notre exemple de conversion, cette fois enrichissons notre module
des fonctions de conversions :

```ocaml
module Measure :
sig 
  type 'a t
  val km : float -> [`Km] t 
  val cm : float -> [`Cm] t
  val ( + ) : 'a t -> 'a t -> 'a t
  val km_of_cm : [`Cm] t -> [`Km] t  
  val cm_of_km : [`Km] t -> [`Cm] t
end = struct
  type 'a t = float
  let km f = f
  let cm f = f
  let ( + ) = ( +. )
  let km_of_cm f = f /. 10000.0
  let cm_of_km f = f *. 10000.0
end
```

Cette fois-ci, le typeur refusera formellement des conversions improbables.


