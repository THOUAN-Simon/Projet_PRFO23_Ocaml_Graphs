open Priority
open Analyse

(** Base

Ce module défini une structure pour les bases martiennes, 
qui seront des graphes non orientés et pondérés, avec 
une fonction suppplémentaire pour l'implémentation 
de la recherche de parcours (via l'algorithme de Dijkstra).

*)

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

        (*Module pour l'ensemble des éléments du graphe*)
        module ModuleSSet = Set.Make(String)

        module PairKey = PairKeyG

        (*Module pour les sucesseurs de chaque modules du graphe*)
        module StringMap = StringMapG

        (*Module pour les longueurs des tunnels*)
        module WeightsMap = WeightsMapG

        (* Module pour la table de réservation : (module_u, module_v) : Valeur (liste d'intervalles) *)
        module ReservationsMap = Map.Make(PairKeyG)

        type base = {
            tunnels : ModuleSSet.t StringMap.t;
            weights : int WeightsMap.t        
        }

        (*Valeur pour la base vide*)
        let empty = {
            tunnels = StringMap.empty;
            weights = WeightsMap.empty
        }

        (*Test de vacuité pour les bases
        @param ---
        @return ---*)
        let is_empty b = StringMap.is_empty b.tunnels && WeightsMap.is_empty b.weights

        (*Retourne un ensemble de modules de la base qui sont les modules accessibles depuis un seul tunnel depuis le module passé en argument, 
        dans la base en 2ème argument*)
        let succs m b = try StringMap.find m (b.tunnels) with | Not_found -> ModuleSSet.empty

        (*fonction indiquant le temps de parcours entre les deux modules passés en argument*)
        let w m1 m2 bMap = 
            let key = if m1 < m2 then (m1, m2) else (m2, m1) in
            try WeightsMap.find key (bMap.weights) 
            with Not_found -> failwith ("Erreur : tunnel introuvable entre " ^ m1 ^ " et " ^ m2)


        (*Ajoute le module en argument à la base passée en argument et retourne la base ainsi complétée*)
        let add_module m b = if StringMap.mem m b.tunnels then b else {tunnels = StringMap.add m (ModuleSSet.empty) (b.tunnels) ; weights = b.weights}

        (*Ajoute le tunnel en argument (on passe les deux modules qu'il relie ainsi que sa longueur) à la base passée en argument et
        retourne la base ainsi complétée*)
        let add_tunnel m1 m2 dist b = 
            let b = add_module m1 (add_module m2 b) in
            let current_succs_m1 = succs m1 b in
            let current_succs_m2 = succs m2 b in
            
            let tunnels_updated = 
                StringMap.add m2 (ModuleSSet.add m1 current_succs_m2) 
                    (StringMap.add m1 (ModuleSSet.add m2 current_succs_m1) b.tunnels) 
            in

            (* On ordonne la clé pour les poids *)
            let key = if m1 < m2 then (m1, m2) else (m2, m1) in
            
            let weights_updated = 
                WeightsMap.add key dist b.weights
            in
            
            { tunnels = tunnels_updated; weights = weights_updated }

        (* Pour s'assurer de l'ordre du couple décrivant les tunnels dans les maps le faisant intervenir comme clé
         @requires m1 et m2 sont deux identifiants de modules.
         @ensures Retourne une paire ordonnée (min, max) pour garantir que le tunnel (A, B) a la même clé que le tunnel (B, A) dans les Maps.
         @param m1 le module de départ du tunnel
         @param m2 le module d'arrivée du tunnel
        *)
        let get_tunnel_key m1 m2 = 
            if m1 < m2 then (m1, m2) else (m2, m1)
        
        (* path_length calcule le temps qu'un explorateur met pour parcourir le chemin "path" dans la base "b", temps qui servira
        à décider quel explorateur est prioritaire (celui ayant le chemin au temps le plus long sera priorisé,
        il naviguera dans les tunnels avant les autres, pour que les autres ne soient pas interrompus trop de fois au moment 
        de parcourir leur chemin, c'est une approche gloutonne)*)

        (* cf ci-dessus
         @requires path est une liste de modules valides connectés dans la base b.
         @ensures Retourne la somme des poids des tunnels empruntés par le chemin.
         @raises Not_found (via WeightsMap.find) si un tunnel du chemin n'existe pas dans la base.
         @param path une liste de modules
         @param b la base dans laquelle on veut appliquer l'opération
        *)
        let rec path_length path b = 
            match path with 
            |[] -> 0
            |[_] -> 0
            |t1 :: t2 :: q -> WeightsMap.find (get_tunnel_key t1 t2) b.weights + path_length (t2 :: q) b
            
        (*Structure de donnée spécifique pour les explorateurs de la base
        (pour se rappeller l'ordre d'entrée, le chemin qu'ils suivent et la longeur de ce chemin)*)
        type explorators = {
            index: int;
            path: moduleS list;
            prio: int      
        }

        (*Structure de donnée contenant les résultats de l'algorithme en conservant l'ordre initial des explorateurs*)
        type intermediate_sol = {
            id: int;
            algo_solution: moduleS list * int list
        }
        
        
        (* fonction de séparation pour les algorithmes de tri
         @requires Rien.
         @ensures Sépare la liste en deux sous-listes de tailles proches pour l'étape de division du tri fusion.
         @param expl_list une liste quelconque
        *)
        let rec separate expl_lst = 
            match expl_lst with
            |[] -> ([], [])
            |[x] -> ([x], [])
            | x :: y :: rest ->
                let (left, right) = separate rest in
                (x :: left, y :: right)

        
        (* fonction de fusion pour le tri des explorateurs
         @requires l1 et l2 sont triées par priorité décroissante.
         @ensures Fusionne l1 et l2 en une seule liste triée par priorité décroissante (l'explorateur
         parcourant la plus grande distance est mis en tête de la liste).
         @param l1 une liste d'explorateurs
         @param l2 une liste d'explorateurs
        *)
        let rec fusion_explorators l1 l2 =
            match (l1, l2) with
            | ([], _) -> l2             
            | (_, []) -> l1              
            | (t1 :: q1, t2 :: q2) ->    
                if t1.prio >= t2.prio then
                    t1 :: (fusion_explorators q1 l2)
                else
                    t2 :: (fusion_explorators l1 q2)

        (* fonction de fusion pour le tri des solutions intermédiaires
         @requires l1 et l2 sont triées par ID croissant.
         @ensures Fusionne l1 et l2 en une seule liste triée par ID croissant (pour remettre les résultats dans l'ordre initial).
         @param l1 une liste de intermediate_sol
         @param l2 une liste de intermediate_sol
        *)
        let rec fusion_intermediate_sol l1 l2 =
            match (l1, l2) with
            | ([], _) -> l2             
            | (_, []) -> l1              
            | (t1 :: q1, t2 :: q2) ->    
                if t1.id <= t2.id then
                    t1 :: (fusion_intermediate_sol q1 l2)
                else
                    t2 :: (fusion_intermediate_sol l1 q2)

        (* fonction de tri pour trier les explorateurs par ordre décroissant de temps de parcours de chemin
         @requires Rien.
         @ensures Retourne une liste triée des explorateurs selon leur champ 'prio' (longueur du chemin) de manière décroissante.
         @param lst une liste d'explorateurs
        *)
        let rec sort_explorators lst =
            match lst with
            | [] | [_] -> lst
            | _ ->
                let (left, right) = separate lst in
                let sort_left = sort_explorators left in
                let sort_right = sort_explorators right in
                fusion_explorators sort_left sort_right

        (* fonction de tri pour trier les solutions intermédiaires par ordre croissant d'id
         @requires Rien.
         @ensures Retourne une liste triée selon le champ 'id' de manière croissante (reconstruction de l'ordre d'entrée).
         @param lst une liste de solutions intermédiaires
        *)
        let rec sort_intermediate_sol lst =
            match lst with
            | [] | [_] -> lst
            | _ ->
                let (left, right) = separate lst in
                let sort_left = sort_intermediate_sol left in
                let sort_right = sort_intermediate_sol right in
                fusion_intermediate_sol sort_left sort_right

        let compute_paths b pathList = 
            let build_explorators b pathList = 
                let rec recur b pathList index = 
                    match pathList with
                    |[] -> []
                    |t :: q -> let path_length = path_length t b in 
                    {index = index; path = t; prio = path_length} :: recur b q (index + 1)
                in recur b pathList 0
            in
            let desc_sorted_explorators = sort_explorators (build_explorators b pathList) in 
            let final_result_tuple = 
            List.fold_left (fun (current_reservations, results_acc, max_global_time) el ->
                let rec process_path_rec path_rest current_time acc_times reservations = 
                    match path_rest with
                    | [] | [_] -> (List.rev acc_times, reservations, current_time)
                    |m_start :: m_end :: q -> 
                    let key = get_tunnel_key m_start m_end in
                    let travel_time = try 
                                        WeightsMap.find key b.weights
                                      with Not_found ->  failwith ("Erreur : tunnel introuvable entre " ^ m_start ^ " et " ^ m_end) in
                    let tunnel_ress = try ReservationsMap.find key reservations with Not_found -> [] in
                    (* Cherche récursivement le premier créneau temporel 't' où le tunnel est libre 
                       entre t et t + travel_time, en vérifiant les conflits avec 'tunnel_ress' *)
                    let rec find_slot t =
                        let wished_start = t in
                        let wished_end = t + travel_time in
                        let conflit = List.find_opt (fun (r_debut, r_fin) ->
                            not (wished_end <= r_debut || wished_start >= r_fin)
                        ) tunnel_ress in
                        match conflit with
                        |Some (_, r_fin) -> find_slot r_fin
                        |None -> t
                    in
                    let valid_start = find_slot current_time in
                    let new_res = (valid_start, valid_start + travel_time) in
                    let updated_tunnel_ress = List.sort compare (new_res :: tunnel_ress) in
                    let next_reservations = ReservationsMap.add key updated_tunnel_ress reservations in
                        
                    process_path_rec (m_end :: q) (valid_start + travel_time) (valid_start :: acc_times) next_reservations
                in

                let (times, new_reservations_state, arrival_time) = process_path_rec el.path 0 [] current_reservations in
                let solution = { id = el.index; algo_solution = (el.path, times) } in
                let new_max_time = max max_global_time arrival_time in

                (new_reservations_state, solution :: results_acc, new_max_time)




            ) (ReservationsMap.empty, [], 0) desc_sorted_explorators in

            let (_, unsorted_results, total_duration) = final_result_tuple in
            let asc_sorted_results = sort_intermediate_sol unsorted_results in
            (List.map (fun res -> res.algo_solution) asc_sorted_results, total_duration)
    end

(* Pour construire la base à partir de la sortie de analyse_file_2
   @requires trans_list doit avoir été construite par la fonction analyse_file_2
   @ensures Renvoie une base b vérifiant le type du module Base, et décrivant une base fidèle 
   au plan fournit en entrée de analyse_file_2 (qui à renvoyé entre autres la liste qu'on traite dans cette fonction)
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
        let base_map, path_list = analyse_file_2 path in
        let base = build_base base_map in
        let paths = Base.compute_paths base path_list in
        output_sol_2 paths

    with 
    | Sys_error msg -> 
        Printf.printf "Erreur : Impossible de lire le fichier (%s)\n" msg
    | Not_found -> 
        Printf.printf "Erreur : Aucun chemin trouvé ou module inconnu.\n"
    | End_of_file -> 
        Printf.printf "Erreur : Fichier incomplet ou vide.\n"
    | e -> 
        Printf.printf "Erreur inattendue : %s\n" (Printexc.to_string e)


