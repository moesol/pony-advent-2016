use "collections"
use "debug"
use "time"

class ErrorInfo
  var message: String = ""
  var source: SourceLoc = __loc

  fun ref throw(message': String, source': SourceLoc = __loc) ? =>
    message = message'
    source = source'
    error

  fun string(): String val =>
    recover
      String.append("** ").append(message).append(":")
        .append(source.file()).append(",").append(source.method())
        .append("@").append(source.line().string())
    end

actor Main
  let env: Env
  let err: ErrorInfo = ErrorInfo
  let pending: Array[State] = Array[State]
  var lastReport: I64 = 0

  new create(env': Env) =>
    env = env'

    let seenStates = Set[String]
    // let state = State(seenStates, 0, Elevator(0), puzzle())
    let state = State(seenStates, 0, Elevator(0), puzzle_part2())
    // let state = State(seenStates, 0, Elevator(3), puzzle_part2a())

    // 48 is too low
    // based on partial 57 (each extra pair on floor 1 is +12?)
    // 59 is too high

    pending.push(state)
    search_pending()

  be search_pending() =>
    try
      let state' = pending.shift()
      if (state'.is_win()) then
        env.out.print("win:" + state'.string() + "moves:" + state'.moves.string())
      end
      // Debug.out("from@" + state'.moves.string() + ":" + state'.string())
      let next: Array[State] = state'.compute_next()
      pending.concat(next.values())

      let nowSecs = Time.seconds()
      if (lastReport + 10) <= nowSecs then
        lastReport = nowSecs
        env.out.print("from@" + state'.moves.string() + ":" + state'.string())
        env.out.print("pending: " + pending.size().string())
      end
      search_pending()
    else
      env.out.print("exhausted all")
    end

  fun bad_ones(): Array[Floor] =>
    [
      Floor(0).m("H").g("P"),
      Floor(1).g("H").m("Z"),
      Floor(2).g("L"),
      Floor(3)
    ]

  fun sample(): Array[Floor box] =>
    [
      recover box Floor(0).m("H").m("L") end,
      recover box Floor(1).g("H") end,
      recover box Floor(2).g("L") end,
      recover box Floor(3) end
    ]

  /* Assumes we need to pull down all the M's to starte
   * and that the G's must be moved up first
   */
  fun puzzle_learn(): Array[Floor box] =>
    [
      // The first floor contains a promethium generator and a promethium-compatible microchip.
      recover box Floor(0).build() end,
      // The second floor contains a cobalt generator,
      // a curium generator,
      // a ruthenium generator, and
      // a plutonium generator.
      recover box Floor(1).g("promethium").g("cobalt").g("curium").g("ruthenium").g("plutonium").build() end,
      // The third floor contains a cobalt-compatible microchip,
      // a curium-compatible microchip,
      // a ruthenium-compatible microchip, and
      // a plutonium-compatible microchip.
      recover box Floor(2).m("promethium").m("cobalt").m("curium").m("ruthenium").m("plutonium").build() end,
      // Empty
      recover box Floor(3).build() end
    ]

  fun puzzle(): Array[Floor box] =>
    [
// The first floor contains a promethium generator and a promethium-compatible microchip.
      recover box Floor(0).g("promethium").m("promethium").build() end,
// The second floor contains a cobalt generator,
// a curium generator,
// a ruthenium generator, and
// a plutonium generator.
      recover box Floor(1).g("cobalt").g("curium").g("ruthenium").g("plutonium").build() end,
// The third floor contains a cobalt-compatible microchip,
// a curium-compatible microchip,
// a ruthenium-compatible microchip, and
// a plutonium-compatible microchip.
      recover box Floor(2).m("cobalt").m("curium").m("ruthenium").m("plutonium").build() end,
// Empty
      recover box Floor(3).build() end
    ]

  fun puzzle_part2(): Array[Floor box] =>
    [
// The first floor contains a promethium generator and a promethium-compatible microchip.
      recover box Floor(0)
        .g("promethium").m("promethium")
        .g("elerium").m("elerium")
        .g("dilithium").m("dilithium")
        .build()
      end,
// The second floor contains a cobalt generator,
// a curium generator,
// a ruthenium generator, and
// a plutonium generator.
      recover box Floor(1).g("cobalt").g("curium").g("ruthenium").g("plutonium").build() end,
// The third floor contains a cobalt-compatible microchip,
// a curium-compatible microchip,
// a ruthenium-compatible microchip, and
// a plutonium-compatible microchip.
      recover box Floor(2).m("cobalt").m("curium").m("ruthenium").m("plutonium").build() end,
// Empty
      recover box Floor(3).build() end
    ]

/*
Sub-problem
E4 GM GM
........
........
........GM GM
*/
  fun puzzle_part2a(): Array[Floor box] =>
    [
// The first floor contains a promethium generator and a promethium-compatible microchip.
      recover box Floor(0)
        .g("elerium").m("elerium")
        .g("dilithium").m("dilithium")
        .build()
      end,
// The second floor contains a cobalt generator,
// a curium generator,
// a ruthenium generator, and
// a plutonium generator.
      recover box Floor(1).build() end,
// The third floor contains a cobalt-compatible microchip,
// a curium-compatible microchip,
// a ruthenium-compatible microchip, and
// a plutonium-compatible microchip.
      recover box Floor(2).build() end,
// Empty
      recover box Floor(3)
        .g("ruthenium").g("plutonium")
        .m("ruthenium").m("plutonium")
        .build() end
    ]
