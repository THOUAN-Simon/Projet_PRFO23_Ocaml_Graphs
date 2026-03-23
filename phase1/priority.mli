(** Priority

Ce module défini une structure pour les files de priorité
utilisées dans l'algorithme de dijkstra
*)


module type Priority =
  sig

    (*type des éléments composant la file de priorité*)
    type 'elt queue

    (* la file de priorité vide *)
    val empty : 'elt queue

    (* Test de vacuité
     @requires Rien.
     @ensures Renvoie true si la file est vide, false sinon.
     @param une file de priorité
    *)
    val is_empty : 'elt queue -> bool

    (* Ajout d'un élément et sa priorité associée à la file de priorité passée en argument
     @requires Rien.
     @ensures Renvoie une nouvelle file contenant l'élément ajouté avec sa priorité associée.
     @param l'élément à ajouter
     @param l'entier correspondant à la priorité du nouvel élément (plus petit = plus prioritaire)
     @param la file de priorité à laquelle il faut ajouter le nouvel élément
    *)
    val add : 'elt -> int -> 'elt queue -> 'elt queue

    exception Empty

    (* Retrait d'un élément de la file de priorité
     @requires La file ne doit pas être vide.
     @ensures Renvoie un couple contenant l'élément de plus haute priorité et sa priorité, ainsi que le reste de la file.
     @raises Empty si la file est vide.
     @param la file de priorité à laquelle on veut enlever l'élément le plus prioritaire
    *)
    val pop : 'elt queue -> ('elt * int)*'elt queue
  end


module MakeList : Priority with type 'elt queue = ('elt*int) list
module MakeHeap : Priority 
