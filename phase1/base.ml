open Priority
open Analyse

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

module PairKeyG = struct
    type t = string * string
    (* Comparaison lexicographique de deux couples *)
    let compare (x1, y1) (x2, y2) =
        let c = String.compare x1 x2 in
        if c <> 0 then c else String.compare y1 y2
end

module StringMapG = Map.Make(String)

module WeightsMapG = Map.Make(PairKeyG)

module Base =
    struct

        type moduleS = string

        module ModuleSSet = Set.Make(String)

        module PairKey = PairKeyG

        module StringMap = StringMapG

        module WeightsMap = WeightsMapG

        type base = {
            tunnels : ModuleSSet.t StringMap.t;
            weights : int WeightsMap.t        
        }

        let empty = {
            tunnels = StringMap.empty;
            weights = WeightsMap.empty
        }

        let is_empty b = StringMap.is_empty b.tunnels && WeightsMap.is_empty b.weights

        let succs m b = try StringMap.find m (b.tunnels) with | Not_found -> ModuleSSet.empty

        let add_module m b = if StringMap.mem m b.tunnels then b else {tunnels = StringMap.add m (ModuleSSet.empty) (b.tunnels) ; weights = b.weights}

        let add_tunnel m1 m2 dist b = 
            let b = add_module m1 (add_module m2 b) in
            let current_succs_m1 = succs m1 b in
            let current_succs_m2 = succs m2 b in
            
            let tunnels_updated = 
                StringMap.add m2 (ModuleSSet.add m1 current_succs_m2) 
                    (StringMap.add m1 (ModuleSSet.add m2 current_succs_m1) b.tunnels) 
            in

            let key = if m1 < m2 then (m1, m2) else (m2, m1) in
            
            let weights_updated = 
                WeightsMap.add key dist b.weights
            in
            
            { tunnels = tunnels_updated; weights = weights_updated }

        let w m1 m2 bMap = 
            let key = if m1 < m2 then (m1, m2) else (m2, m1) in
            try WeightsMap.find key (bMap.weights) 
            with Not_found -> failwith ("Erreur : tunnel introuvable entre " ^ m1 ^ " et " ^ m2)
        
        (*Module pour la file de priorité utilisée dans shortest_path*)
        module PriorityQueue = Priority.MakeHeap
        
        (* Reconstruit le chemin en sortie de shortest_path
         @requires parentsMap contient le prédécesseur de chaque module visité. startModule et endModule doivent être connectés dans cette map.
         @ensures Renvoie la liste des modules formant le chemin de startModule à endModule.
         @raises Failure si la chaîne de parents est interrompue avant d'atteindre startModule.
        *)
        let build_path parentsMap startModule endModule = 
            let rec recur cur_mod path = 
                let path' = cur_mod :: path in
                if cur_mod = startModule then 
                    path'
                else
                    let parent = try StringMap.find cur_mod parentsMap 
                                 with Not_found -> failwith "Erreur : chemin interrompu lors de la reconstruction" 
                    in
                    recur parent path'
            in 
            recur endModule []
            
        
        let shortest_path mStart mEnd b = 
            let distanceMap = StringMap.add mStart 0 (StringMap.empty) in  
            let priorityQueue = PriorityQueue.add mStart 0 (PriorityQueue.empty) in
            let parentsMap = StringMap.empty in

            (* Cette fonction renvoie la distance accumulée dans distanceMap lors du parcours dans le graphe *)
            let get_dist m map = 
                match StringMap.find_opt m map with
                | Some d -> d
                | None -> max_int (* Infini *)
            in

            let rec dijkstra (dist_map, parent_map, pq) = 
                if PriorityQueue.is_empty pq then 
                    raise Not_found 
                else
                    let (u, cur_dist), pq_rest = PriorityQueue.pop pq in
                    
                    if u = mEnd then 
                        (cur_dist, build_path parent_map mStart mEnd)
                    else
                        let known_dist = get_dist u dist_map in
                        if cur_dist > known_dist then 
                            dijkstra (dist_map, parent_map, pq_rest)
                        else
                            (* Fold sur les voisins (next_m) de u *)
                            let (new_d_map, new_p_map, new_pq) = 
                                ModuleSSet.fold (fun next_m (dm, pm, q) -> 
                                    let weight_u_next = w u next_m b in
                                    let new_dist = cur_dist + weight_u_next in
                                    let current_known_dist = get_dist next_m dm in
                                    
                                    if new_dist < current_known_dist then 
                                        (StringMap.add next_m new_dist dm,
                                         StringMap.add next_m u pm,
                                         PriorityQueue.add next_m new_dist q)
                                    else
                                        (dm, pm, q)
                                ) (succs u b) (dist_map, parent_map, pq_rest)
                            in
                            dijkstra (new_d_map, new_p_map, new_pq)

            in dijkstra (distanceMap, parentsMap, priorityQueue)
    end

(* Pour construire la base à partir de la sortie de analyse_file_1
   @requires trans_list doit avoir été construite par la fonction analyse_file_1
   @ensures Renvoie une base b vérifiant le type du module Base, et décrivant une base fidèle 
   au plan fournit en entrée de analyse_file_1 (qui à renvoyé la liste qu'on traite dans cette fonction)
   @param une liste de triplets décrivant les transitions de la base
*)
let build_base trans_list = 
    let rec reccur l b = 
        match l with
        |[] -> b
        |(m1, m2, dist) :: q -> reccur q (Base.add_tunnel m1 m2 dist b)

    in reccur trans_list Base.empty

(* Gestion des interactions avec l'utilisateur *)
let _ = 
    Printf.printf "Entrez le chemin absolu du fichier à lire : %!"; 
    
    try 
        let path = read_line () in
        let trans, start_stop = analyse_file_1 path in
        let base = build_base trans in
        let start, stop = start_stop in 
        
        Printf.printf "Calcul du chemin de %s vers %s...\n%!" start stop;
        
        let dist, path_list = Base.shortest_path start stop base in
        output_sol_1 dist path_list

    with 
    | Sys_error msg -> 
        Printf.printf "Erreur : Impossible de lire le fichier (%s)\n" msg
    | Not_found -> 
        Printf.printf "Erreur : Aucun chemin trouvé ou module inconnu.\n"
    | End_of_file -> 
        Printf.printf "Erreur : Fichier incomplet ou vide.\n"
    | e -> 
        Printf.printf "Erreur inattendue : %s\n" (Printexc.to_string e)


