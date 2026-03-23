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


        
        (* calcule les suites de déplacements des personnes et la durée totales des déplacmeents à partir d'un plan de la base et de la liste de chemins des personnes
         @requires b est une base valide contenant tous les tunnels nécessaires. 
         Le deuxième argument est une liste de chemins (listes de modules). Chaque chemin doit être faisable dans la base (deux modules consécutifs sont reliés par un tunnel).
         @ensures Retourne un couple contenant :
           - Une liste de couples (chemin, liste des temps de départ pour chaque étape). L'ordre de cette liste correspond à l'ordre des explorateurs en entrée.
           - Un entier représentant le temps total de la simulation (moment où le dernier explorateur arrive).
           La fonction résout les conflits d'accès aux tunnels selon une stratégie gloutonne (priorité aux chemins les plus longs).
         @raises Failure si un tunnel entre deux modules consécutifs d'un chemin n'existe pas dans la base.
         @param la base dans laquelle on veut faire l'ordonancement
         @param la liste des chemins des différents explorateurs à ordonancer
        *)
        val compute_paths : base -> moduleS list list -> (moduleS list * int list) list * int
        
    end

module Base : ABase with type moduleS = string