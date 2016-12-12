use "collections"
use "debug"

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
  new create(env': Env) =>
    env = env'

    let seenStates = Set[String]
    let state = State(seenStates, 0, Elevator, puzzle())

    search_from(state)

  fun search_from(state': State) =>
    if (state'.is_win()) then
      env.out.print("win:" + state'.string() + "moves:" + state'.moves.string())
    end
    Debug.out("from@" + state'.moves.string() + ":" + state'.string())
    let next: Array[State] = state'.compute_next()
    Debug.out("size: " + next.size().string())
    for ns in next.values() do
      search_from(ns)
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
