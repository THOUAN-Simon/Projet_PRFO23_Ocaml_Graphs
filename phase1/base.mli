(** Base

Ce module défini une structure pour les bases martiennes, 
qui seront des graphes non orientés et pondérés, avec 
une fonction suppplémentaire pour l'implémentation 
de la recherche de parcours (via l'algorithme de Dijkstra).

*)

module type ABase = 
    sig
        (*Type des modules de la base*)
        type moduleS

        (*Module pour l'ensemble des modules*)
        module ModuleSSet : Set.S with type elt = moduleS

        (*Module pour la map contenant le plan de la base*)
        module StringMap : Map.S with type key = moduleS

        module PairKey : sig
            type t = moduleS * moduleS
            val compare : t -> t -> int
        end

        (*Module pour la map contenant les poids des tunnels de la base*)
        module WeightsMap : Map.S with type key = PairKey.t
        
        (*Type de la base *)
        type base

        (*Valeur pour la base vide*)
        val empty : base

        (* Test de vacuité
         @requires Rien.
         @ensures Renvoie true si la base ne contient aucun module ni tunnel, false sinon
         @param une base.
        *)
        val is_empty : base -> bool

        (* Ajout d'un module à la base passée en argument
         @requires Rien.
         @ensures Ajoute le module en argument à la base passée en argument et retourne la base ainsi complétée
         @param le module à ajouter à la base
         @param la base à modifier
        *)
        val add_module : moduleS -> base -> base

        (* Ajout d'un tunnel à la base passée en argument
         @requires La durée de parcours du tunnel doit être positive ou nulle
         @ensures Ajoute le tunnel en argument (on passe les deux modules qu'il 
         relie ainsi que sa longueur) à la base passée en argument et retourne la base ainsi complétée
         @param le module de départ du tunnel
         @param le module d'arrivée du tunnel
         @param la durée de parcours du tunnel
         @param la base à modifier
        *)
        val add_tunnel : moduleS -> moduleS -> int -> base -> base

        (* Renvoi les successeurs du module das la base donnée
         @requires Rien.
         @ensures Retourne un ensemble de modules de la base qui sont les modules 
         accessibles depuis un seul tunnel depuis le module passé en argument, 
         dans la base en 2ème argument
         @param le module dont on veut connaître les sucesseurs
         @param la base dans laquelle on réalise l'opération
        *)
        val succs : moduleS -> base -> ModuleSSet.t

        (* Indique le temps de parcours entre les deux modules passés en argument
         @requires Les deux modules doivent exister et être reliés directement par un tunnel.
         @ensures Renvoie le temps de parcours du tunnel reliant les deux modules.
         @raises Failure (via failwith) si aucun tunnel n'existe entre ces deux modules.
         @param le module de départ du tunnel dont on veut connaître le temps de parcours
         @param le module d'arrivée du tunnel dont on veut connaître le temps de parcours
         @param la base dans laquelle on réalise l'opération
        *)
        val w : moduleS -> moduleS -> base -> int

        (* trouve le plus court chemin depuis le premier module passé en argument, vers le deuxième module passé en argument, dans la base en 3ème argument.
        Un tel chemin est un couple formée d'une liste de modules décrivant le chemin, et d'un entier représentant la longueur du chemin retourné
         @requires Les poids des tunnels doivent être positifs.
         @requires Les modules de départ et d'arrivée doivent exister dans la base
         @ensures Renvoie un couple (distance totale, liste des modules) représentant le plus court chemin.
         @raises Not_found s'il n'existe aucun chemin entre les deux modules.
         @param le module de départ du chemin à rechercher
         @param le module d'arrivée du chemin à rechercher
         @param la base dans laquelle on effectue la recherche
        *)
        val shortest_path : moduleS -> moduleS -> base -> int * moduleS list
        
    end

module Base : ABase with type moduleS = string