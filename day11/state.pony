use "collections"
use "debug"

class State
  // let seen: Map[String, State]
  let seen: Set[String]
  var moves: USize
  let elevator: Elevator
  let floors: Array[Floor box]

  new create(
    seen': Set[String],
    moves': USize,
    e: Elevator, f: Array[Floor box]
  ) =>
    seen = seen' // Must be breadth first search
    // seen = Set[String]
    moves = moves'
    elevator = e
    floors = f

  fun ref compute_next(): Array[State] =>
    match elevator.floor
    | 3 => down()
    | 2 => down().concat(up().values())
    | 1 => down().concat(up().values())
    | 0 => up()
    else
      Debug.err("** Fail")
      Array[State]
    end

  fun ref up(): Array[State] =>
    compute_move_to(elevator.floor + 1)

  fun ref down(): Array[State] =>
    compute_move_to(elevator.floor - 1)

  fun floorOfG(g: String): USize =>
    for f in floors.values() do
      if f.generators().contains(g) then
        // Debug.out("floorOfG:"+g+f.floor.string())
        return f.floor
      end
    end
    Debug.err("** error1")
    0

  fun floorOfM(m: String): USize =>
    for f in floors.values() do
      if f.microchips().contains(m) then
        // Debug.out("floorOfM:"+m+f.floor.string())
        return f.floor
      end
    end
    Debug.err("** error1")
    0

  fun ref compute_move_to(next: USize val): Array[State] =>
    let res = Array[State]
    let moves' = moves + 1
    try
      let cur = floors(elevator.floor)
      // generators
      for gi in cur.generators().values() do
        let state' = move_generator(moves', elevator.floor, next, gi)
        maybe_add_state(res, state')
        for gj in cur.generators().values() do
          maybe_add_state(res, state'.move_generator(moves', elevator.floor, next, gj))
        end
      end
      // microchips
      for mi in cur.microchips().values() do
        let state' = move_microchip(moves', elevator.floor, next, mi)
        maybe_add_state(res, state')
        for mj in cur.microchips().values() do
          maybe_add_state(res, state'.move_microchip(moves', elevator.floor, next, mj))
        end
      end
      // Cross product
      for gi in cur.generators().values() do
        for mj in cur.microchips().values() do
          maybe_add_state(res, move_both(moves', elevator.floor, next, gi, mj))
        end
      end
    end
    res

  fun ref move_generator(
    moves': USize, cur': USize, next': USize val, g: String
  ): State ? =>
    let cur_floor: Floor ref = floors(cur').clone()
    let next_floor: Floor ref = floors(next').clone()
    // Debug.out("b-" + cur_floor.gen_mic + cur_floor.generators().contains("promethium").string())
    cur_floor.rm_g(g)
    // Debug.out("a-" + cur_floor.gen_mic + cur_floor.generators().contains("promethium").string())
    next_floor.g(g)
    let floors' = floors.clone()
    try
      floors'(cur') = cur_floor.build()
      floors'(next') = next_floor.build()
    else
      Debug.err("** Fail")
    end
    State(seen, moves', Elevator(next'), floors')

  fun ref move_microchip(
    moves': USize, cur': USize, next': USize val, m: String
  ): State ? =>
    let cur_floor: Floor ref = floors(cur').clone()
    let next_floor: Floor ref = floors(next').clone()
    cur_floor.rm_m(m)
    next_floor.m(m)
    let floors' = floors.clone()
    try
      floors'(cur') = cur_floor
      floors'(next') = next_floor
    else
      Debug.err("** Fail")
    end
    State(seen, moves', Elevator(next'), floors')

  fun ref move_both(
    moves': USize, cur': USize, next': USize val, g: String, m: String
  ): State ? =>
    let state' = move_generator(moves', cur', next', g)
    state'.move_microchip(moves', cur', next', m)

  fun ref maybe_add_state(list: Array[State], state: State) =>
    if not seen.contains(state.string()) then
      seen.set(state.string())
      // if elevator.floor == 1 then
      //   Debug.out("from: " + string())
      //   Debug.out("try: " + state.string())
      // end
      if Rule.is_safe_state(state) then
        list.push(state)
      end
    end
    // else
    //   try
    //     let old = seen(state.string())
    //     if old.moves > state.moves then
    //       // Found a faster way to get here
    //       Debug.out("Found faster path to " + state.string())
    //       seen(state.string()) = state
    //       if Rule.is_safe_state(state) then
    //         list.push(state)
    //       end
    //     end
    //   end
    // end

  fun is_win(): Bool =>
    try
      for i in Range(0,3) do
        if not floors(i).is_empty() then
          return false
        end
      end
      true
    else
      false
    end

  fun string(): String =>
    let r: String ref = String
    r.append("E").append(elevator.string()).append("-")
    for f in floors.reverse().values() do
      r.append(f.string()).append("-")
    end
    r.clone()
