use "collections"
use "regex"
use "debug"
use "time"

class val State
  let moves: USize
  let location: (USize, USize)
  let maze: String
  new val create(moves': USize, location': (USize, USize), maze': String) =>
    moves = moves'
    location = location'
    maze = maze'
  fun location_string(): String =>
    "(" + location._1.string() + "," + location._2.string() + ")"
  fun string(): String =>
    "@" + moves.string() + location_string()

class val Lookup
  let width: USize
  new val create(width': USize) =>
    width = width'
  fun _index(loc: (USize, USize)): USize =>
    (let x, let y) = loc
    (y * (width + 1)) + x

actor Router
  let env: Env
  let collector: Collector
  let start: (USize, USize)
  let visited: String ref
  let workers: Array[Worker] = Array[Worker]
  var n: USize = 0
  let lookup: Lookup
  let limit: USize
  var win: Bool = false
  var moves: USize = 0

  new create(env': Env, maze: String,
    collector': Collector,
    start': (USize, USize),
    width': USize, limit': USize = 100)
  =>
    env = env'
    collector = collector'
    start = start'
    visited = maze.clone()
    lookup = Lookup(width')
    limit = limit'

    for i in Range(0, 6) do
      workers.push(Worker(this, lookup))
    end

  be sum_reached() =>
    var sum: USize = 0
    for c in visited.values() do
      if c == '0' then
        sum = sum + 1
      end
    end
    // env.out.print("Sum reached:" + sum.string())

  fun location_string(l: (USize, USize)): String =>
    "(" + l._1.string() + "," + l._2.string() + ")"

  be search(from: State, goal: (USize, USize)) =>
    if from.moves > limit then
      sum_reached()
      return
    end
    if been_there(from.location) then
      return
    end
    try
      visited(lookup._index(from.location)) = '0'
      if (from.location._1 == goal._1) and (from.location._2 == goal._2) then
        moves = moves.min(from.moves)
        if not win then
          // env.out.print("win: " + from.moves.string() + " "
          //   + location_string(start) + "=>" + from.location_string()
          // )
          collector.record(from.moves, start, from.location)
        end
        win = true
        // env.out.print("path: " + visited)
        return
      end
    else
      Debug.err("** Err 57")
    end

    // Debug.out("--searching:" + from.string())
    try
      workers(n % workers.size()).search(from, goal)
    end

  fun been_there(loc: (USize, USize)): Bool =>
    try
      visited(lookup._index(loc)) == '0'
    else
      Debug.err("** Err 72")
      true
    end

actor Worker
  let router: Router
  let lookup: Lookup
  new create(router': Router, lookup': Lookup) =>
    router = router'
    lookup = lookup'

  be search(from: State, goal: (USize, USize)) =>
    _search(from, goal, -1, 0) // left
    _search(from, goal, 0, -1) // up
    _search(from, goal, 1, 0) // right
    _search(from, goal, 0, 1) // down

  fun _search(from: State, goal: (USize, USize), dx: ISize, dy: ISize) =>
    let nx: USize = (from.location._1.isize() + dx).usize()
    let ny: USize = (from.location._2.isize() + dy).usize()
    let next = (nx, ny)
    if available(from, next) then
      router.search(make_state(from, next), goal)
    end

  fun available(from: State, loc: (USize, USize)): Bool =>
    try
      from.maze(lookup._index(loc)) == '.'
    else
      false
    end

  fun make_state(from: State, next: (USize, USize)): State =>
    State(from.moves + 1, next, from.maze)

class val Pair
  let dist: USize
  let src: (USize, USize)
  let dst: (USize, USize)
  new val create(dist': USize, src': (USize, USize), dst': (USize, USize)) =>
    dist = dist'
    src = src'
    dst = dst'

actor Collector
  let env: Env
  var count: USize = USize.max_value()
  var goals: Array[Goal] val = recover val Array[Goal] end
  let pairs: Array[Pair] = Array[Pair]
  var best: USize = USize.max_value()
  let distances: Map[String, USize] = Map[String, USize]
  var searched: USize = 0

  new create(env': Env) =>
    env = env'
  be record(dist: USize, src: (USize, USize), dst: (USize, USize)) =>
    Debug.out("got: " + tupple(src) + "=>" + tupple(dst) + " dist " + dist.string())
    pairs.push(Pair(dist, src, dst))
    distances(encode(src, dst)) = dist
    distances(encode(dst, src)) = dist

    if pairs.size() >= count then
      find_shortest()
    end

  fun encode(src: (USize, USize), dst: (USize, USize)): String =>
    tupple(src) + "=>" + tupple(dst)

  fun tupple(l: (USize, USize)): String =>
    "("+ l._1.string() + "," + l._2.string() + ")"
  be set_count(count': USize) =>
    count = count'
    if pairs.size() >= count then
      find_shortest()
    end
  be set_goals(goals': Array[Goal] val) =>
    goals = goals'
  fun ref find_shortest() =>
    Debug.out("ready --" + goals.size().string())
    try
      _find_shortest(0, goals, 0)
      // for i in Range(0, goals.size()) do
      //   _find_shortest(i, goals, 0)
      // end
      env.out.print("best: " + best.string() + " searched: " + searched.string())
    else
      Debug.err("** Grr")
    end
    Debug.out("done --")

  fun ref _find_shortest(at: USize, remain: Array[Goal] val, traveled: USize) ? =>
    let src = remain(at)
    let r' = recover val
      remain.clone().remove(at, 1)
    end
    if r'.size() == 0 then
      // Debug.out("done dist=" + traveled.string())
      // now add the distance from here to 0
      // let final = traveled + compute_dist(src, goals(0))
      // Debug.out("zero: " + goals(0).string())
      // best = best.min(final)
      best = best.min(traveled)
      return
    end

    for i in Range(0, r'.size()) do
      let dst = r'(i)
      _find_shortest(i, r', traveled + compute_dist(src, dst))
    end

  fun ref compute_dist(from: Goal, to: Goal): USize ? =>
    try
      searched = searched + 1
      let r = distances(encode(from.location, to.location))
      // Debug.out(encode(from.location, to.location) + " is " + r.string())
      r
    else
      Debug.err("** missing: " + encode(from.location, to.location))
      error
    end

class Maze
  let maze: String ref = String
  new create(width: USize, height: USize, c: USize) =>
    for y in Range(0, height) do
      for x in Range(0, width) do
        maze.push(if is_odd(count_one_bits(compute_for(x, y, c))) then '#' else '.' end)
      end
      maze.push('\n')
    end

  fun count_one_bits(v: USize): USize =>
    var c: USize = 0
    for i in Range(0, USize.bitwidth()) do
      let mask = 1 << i
      let check = v and mask
      if check > 0 then
        c = c + 1
      end
    end
    c

  fun is_odd(v: USize): Bool =>
    (v % 2) == 1

  fun compute_for(x: USize, y: USize, c: USize): USize =>
    (x*x) + (3*x) + ((2*x)*y) + y + (y*y) + c

class SearchMaze
  fun apply(env: Env, maze: String,
    start: (USize, USize), goal: (USize,USize),
    collector: Collector)
  =>
    let dims = learn_dimensions(maze)
    // Debug.out("width: " + dims._1.string() + "," + "height: " + dims._2.string())
    let state = State(0, start, maze.clone())
    let router = Router(env, maze.clone(),
      collector, start, dims._1, 500)
    router.search(state, goal)

  fun learn_dimensions(maze: String): (USize, USize) =>
    let lines = maze.split("\n")
    try
      (lines(0).size(), lines.size())
    else
      Debug.err("** Error")
      (0, 0)
    end
