# Planificateur de Déplacements : Base Martienne (OCaml)

## Présentation du projet
Ce projet consiste à concevoir un système de planification de déplacements au sein d'une base martienne. La base est modélisée comme un graphe non orienté et pondéré où les modules sont des sommets et les tunnels de transit sont des arêtes.

L'originalité du projet réside dans sa thématique logistique spatiale : la colonie martienne impose des contraintes de transit strictes où chaque tunnel ne peut être emprunté que par une seule personne à la fois.

## Phase 1 : Optimisation du trajet individuel
La première phase se concentre sur la sécurité et l'efficacité d'un individu unique devant se déplacer entre deux modules en minimisant le temps total de parcours.

### Points clés de l'implémentation

* **Algorithme de Dijkstra** : Recherche du chemin optimal via une implémentation fonctionnelle de l'algorithme de Dijkstra.

* **Modularité et Abstraction** : Utilisation intensive des signatures OCaml (`ABase`, `Priority`) et des foncteurs pour séparer la logique de la base martienne des structures de données sous-jacentes.
  
* **Structures de Données** :
    * Utilisation des modules `Map` et `Set` d'OCaml pour une gestion efficace des relations entre modules et tunnels.
    * Implémentation d'un système de normalisation des clés pour garantir la cohérence des tunnels non orientés (tri lexicographique des sommets).


## Implémentation Technique
Le code est structuré de manière modulaire pour faciliter l'évolution vers les phases suivantes :

* **`Base`** : Définit le type `base` et les opérations sur le graphe. Le foncteur permet une gestion générique des modules.
* **`Priority`** : Fournit une abstraction pour les files de priorité nécessaires à Dijkstra.
    * **`MakeList`** : Implémentation basée sur des listes triées.
    * **`MakeHeap`** : Implémentation basée sur des tas (Heaps) pour optimiser la complexité temporelle.
* **`Analyse`** : Module de parsing gérant la lecture des plans de base et des requêtes de trajet à partir de fichiers texte.


## Manuel Utilisateur (Phase 1)

### Format du plan de base
Le fichier d'entrée doit respecter la structure suivante :

- Un entier n représentant le nombre de tunnels.
- n lignes décrivant les liaisons : `<Module_A> <Module_B> <Durée>`.
- Une ligne décrivant le trajet souhaité : `<Départ> <Arrivée>`.
  
### Compilation
Le projet inclut un `Makefile` pour automatiser la compilation des différents modules OCaml : 
    make

### Exécution
Au lancement, le programme demande à l'utilisateur de fournir le chemin vers le plan de la base à analyser : 
    ./base
    *#Entrez le chemin : ./test/base_ex1*
  
### Tests
Une suite de tests est disponible dans le répertoire `test/` (fichiers base_ex1 à base_ex10). Ces fichiers couvrent diverses configurations de graphes pour valider la robustesse de l'algorithme de recherche de chemin.



## Phase 2 : Ordonnancement Multi-individus
La seconde phase introduit la gestion simultanée de plusieurs explorateurs ayant des itinéraires pré-définis. Le système doit réguler les départs pour éviter toute collision dans les tunnels.

### Points clés de l'implémentation
* **Table de Réservation** : Mise en place d'une structure de données permettant de marquer l'occupation d'un tunnel (arête) sur un intervalle de temps donné `[t_départ, t_arrivée]`.
* **Stratégie Gloutonne (Heuristique)** : Pour minimiser le temps total, le système traite les explorateurs par ordre de priorité. L'heuristique choisie donne la priorité aux **chemins les plus longs** pour fluidifier le trafic global.
* **Résolution des Conflits** : Si un tunnel est déjà réservé, le système calcule le prochain créneau disponible, retardant ainsi le départ de l'explorateur de module en module.

## Architecture Technique
Le projet utilise la puissance du typage d'OCaml pour garantir la sûreté des algorithmes :

* **`Base`** : Contient le cœur de la logique, notamment la fonction `compute_paths` qui gère l'ordonnancement global et la table de réservation.
* **`Priority`** : Fournit une abstraction pour les files de priorité (Tas ou Listes triées) utilisées par Dijkstra en Phase 1.
* **`Analyse`** : Module de parsing étendu pour lire plusieurs trajets et formater les solutions complexes (séquences de nœuds avec temps de passage).

## Manuel Utilisateur (Phase 2)

### Format du plan de base

- Un entier n (nombre de tunnels).
- n lignes : `<Module_A> <Module_B> <Durée>`.
- Un entier m (nombre d'explorateurs).
- m lignes : `<Module_départ> -> <Module_arrivée> ... -> <Module_final>`.

### Compilation
Comme pour la phase 1

### Exécution
Le programme demande le chemin vers le plan de la base contenant les tunnels et la liste des trajets des explorateurs.
    ./base
    *# Entrez le chemin : ./test/base_ex1*
  
### Tests
Comme pour la phase 1