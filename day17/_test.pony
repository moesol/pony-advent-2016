use "ponytest"
use "collections"
use "debug"
use "crypto"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestPathSearch)

primitive INPUT
  fun room(): String =>
    """#########
#S| | | #
#-#-#-#-#
# | | | #
#-#-#-#-#
# | | | #
#-#-#-#-#
# | | |
####### V"""

class val State
  let location: (USize, USize)
  let path: String
  new val create(location': (USize, USize), path': String) =>
    location = location'
    path = path'
  fun string(): String  =>
    let l = location
    "("+ l._1.string() + "," + l._2.string() + ")" + path

actor Router
  let env: Env
  let seed: String
  let visited: Set[String] = Set[String]
  let height: USize = 4
  let width: USize = 4
  let workers: Array[Worker]
  var next: USize = 0
  var win: Bool = false

  new create(env': Env, seed': String) =>
    env = env'
    seed = seed'
    workers = Array[Worker]
    for i in Range(0, 6) do
      workers.push(Worker(env, this, width, height, seed))
    end

  be route(state: State) =>
    // if win then
    //   return
    // end
    if visited.contains(state.path) then
      return
    end
    visited.set(state.path)
    if (state.location._1 == 3) and (state.location._2 == 3) then
      env.out.print(
        "win: length: " + state.path.size().string() +
        " path: " + state.path)
      win = true
      return
    end
    // Debug.out("state: " + state.string())
    try
      workers(next % workers.size()).next_states(state)
    end

actor Worker
  let env: Env
  let router: Router
  let width: USize
  let height: USize
  let seed: String

  new create(env': Env, router': Router,
    width': USize, height': USize, seed': String)
  =>
    env = env'
    router = router'
    width = width'
    height = height'
    seed = seed'
  be next_states(state: State) =>
    if state.location._1 > 0 then
      maybe_route(state, "L")
    end
    if (state.location._1 + 1) < width then
      maybe_route(state, "R")
    end
    if state.location._2 > 0 then
      maybe_route(state, "U")
    end
    if (state.location._2 + 1) < height then
      maybe_route(state, "D")
    end

  fun maybe_route(cur: State, move: String) =>
    try
      let next = _next_state(cur, move)
      let k = seed + cur.path
      let h = _compute(k)
      // Debug.out("checking: " + k + "=" + h + " for " + move)
      let idx: USize = match move
      | "U" => 0
      | "D" => 1
      | "L" => 2
      | "R" => 3
      else
        env.err.print("** Bad move")
        error
      end
      let c = h(idx)
      let open: Bool = match c
      | 'b' => true
      | 'c' => true
      | 'd' => true
      | 'e' => true
      | 'f' => true
      else
        false
      end
      if open then
        router.route(next)
      end
    else
      env.err.print("** Error")
    end

  fun _next_state(state: State, move: String): State ? =>
    let location' = match move
    | "L" => (state.location._1 - 1, state.location._2)
    | "R" => (state.location._1 + 1, state.location._2)
    | "U" => (state.location._1, state.location._2 - 1)
    | "D" => (state.location._1, state.location._2 + 1)
    else
      Debug.err("** Bad move")
      error
    end
    State(location', state.path + move)

  fun _compute(attempt: String): String ? =>
    let md5 = Digest.md5()
    try
      md5.append(attempt)
      let sum = md5.final()
      ToHexString(sum)
    else
      Debug.err("** Digest")
      error
    end

class iso _TestPathSearch is UnitTest
  fun name(): String => "path"

  fun apply(h: TestHelper) =>
    let start = State((0,0), "")
    // let router = Router(h.env, "hijkl")
    // router.route(start)

    // let router = Router(h.env, "ihgpwlah")
    // router.route(start)

    // let router = Router(h.env, "kglvqrro")
    // router.route(start)

    // let router = Router(h.env, "ulqzkmiv")
    // router.route(start)

    let router = Router(h.env, "rrrbmfta")
    router.route(start)
