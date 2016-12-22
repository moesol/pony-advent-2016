use "collections"
use "debug"

primitive Rule
  fun is_safe_floor(f: Floor box): Bool =>
    _is_safe(f.generators(), f.microchips())

  fun is_safe_state(s: State): Bool =>
    // Debug.out("  to@" + s.moves.string() + ":" + s.string())

    for f in s.floors.values() do
      if not is_safe_floor(f) then
        // Debug.out("--bad-floor--(" + f.string() + ")")
        return false
      end
    end

    if s.moves >= 59 then
      // Debug.out("limit reached")
      return false
    end

    // Don't let the M's get ahead of the G'
    // for t in INPUT.types().values() do
    //   let fOfG: U32 = s.floorOfG(t).u32()
    //   let fOfM: U32 = s.floorOfM(t).u32()
    //   if fOfM > fOfG then
    //     // Debug.out("bad-m-g@" + s.moves.string() + ":" + s.string())
    //     return false
    //   end
    // end
    // // Don't let elevator go to floor "1"
    // if s.elevator.floor == 0 then
    //   return false
    // end

    // TODO might need to do elevator
    // Debug.out("good@" + s.moves.string() + ":" + s.string())
    true

  fun _is_safe(generators: Set[String] box, microchips: Set[String] box): Bool =>
    if generators.size() == 0 then
      return true
    end

    let unpaired_microchips = microchips.without(generators)

    if unpaired_microchips.size() == 0 then
      return true
    end
    false
