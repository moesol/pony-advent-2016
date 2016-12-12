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

    if s.moves >= 50 then
      Debug.out("limit reached")
      return false
    end

    // for t in INPUT.types().values() do
    //   let fOfG: U32 = s.floorOfG(t).u32()
    //   let fOfM: U32 = s.floorOfM(t).u32()
    //   let max = fOfG.max(fOfM)
    //   let min = fOfG.min(fOfM)
    //   if (max - min) > 1 then
    //     // Debug.out("GRRR" + (max - min).string())
    //     return false
    //   end
    // end

    // TODO might need to do elevator
    // Debug.out("good@" + s.moves.string() + ":" + s.string())
    true

  fun _is_safe(generators: Set[String] box, microchips: Set[String] box): Bool =>
    let unpaired_microchips = microchips.without(generators)

    if generators.size() == 0 then
      return true
    end
    if unpaired_microchips.size() == 0 then
      return true
    end
    false
