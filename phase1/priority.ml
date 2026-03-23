module type Priority =
  sig
    type 'elt queue
    val empty : 'elt queue
    val is_empty : 'elt queue -> bool
    val add : 'elt -> int -> 'elt queue -> 'elt queue
    exception Empty
    val pop : 'elt queue -> ('elt * int)*'elt queue
  end


module MakeList =
  struct

    exception Empty

    type 'elt queue = ('elt*int) list

    let empty = []

    let is_empty q = q = []

    let rec add e p q = 
      match q with
      |[] -> [(e,p)]
      |(e',p') :: t -> if p' > p then (e,p) :: q else (e',p') :: add e p t
      
    let pop q = 
      match q with
      |[] -> raise Empty
      |h :: t -> (h,t)
  end


module MakeHeap =
  struct

  exception Empty

  type 'elt ne_queue = Node of ('elt * int * ('elt ne_queue list))

  type 'elt queue = |E |NE of 'elt ne_queue

  let empty = E

  let is_empty q = q = E

  let merge q1 q2 = 
    match q1, q2 with
    |E,E -> E
    |E,q | q,E -> q
    |NE(Node(e1, p1, l1) as q1'), NE(Node(e2, p2, l2) as q2') -> if p1 < p2 then NE(Node(e1, p1, q2' :: l1)) else NE(Node(e2, p2, q1' :: l2))

  let rec merge_pairs lq = 
    match lq with
    |[] -> E
    |[q] -> NE q
    |q1 :: q2 :: t -> 
      merge (merge (NE q1) (NE q2)) (merge_pairs t)

  let add e p q = 
    merge (NE(Node(e, p, []))) q
    
  let pop q = 
    match q with
    |E -> raise Empty
    |(NE(Node(e, p, l))) -> ((e, p), merge_pairs l)
  end
