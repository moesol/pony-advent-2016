use "ponytest"
use "collections"
use "regex"
use "debug"
use "time"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestBuild)
    test(_TestSample)
    test(_TestPuzzle)
    test(_TestPuzzle2)

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
  let visited: String ref
  let workers: Array[Worker] = Array[Worker]
  var n: USize = 0
  let lookup: Lookup
  let limit: USize

  new create(env': Env, maze: String, width': USize, limit': USize = 100) =>
    env = env'
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
    env.out.print("Sum reached:" + sum.string())

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
        env.out.print("win: " + from.moves.string())
        // env.out.print("path: " + visited)
        return
      end
    else
      Debug.err("** Err 57")
    end

    Debug.out("Searching:" + from.string())
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

class iso _TestBuild is UnitTest
  fun name(): String => "build"
  fun apply(h: TestHelper) =>
    let maze = Maze(10, 7, 10)
    h.assert_eq[USize](0, maze.count_one_bits(0))
    h.assert_eq[USize](1, maze.count_one_bits(1))
    h.assert_eq[USize](1, maze.count_one_bits(2))
    h.assert_eq[USize](2, maze.count_one_bits(3))
    h.assert_eq[USize](1, maze.count_one_bits(4))
    h.assert_eq[USize](3, maze.count_one_bits(7))
    h.assert_eq[USize](64, maze.count_one_bits(0xFFFFFFFFFFFFFFFF))
    h.assert_eq[USize](5, maze.count_one_bits(1364))

    let exp = """.#.####.##
..#..#...#
#....##...
###.#.###.
.##..#..#.
..##....#.
#...##.###
"""
    h.assert_eq[String](exp, maze.maze.clone())

    Debug.out(maze.maze)
    // Debug.out(Maze(62, 78, 1364).maze)

class iso _TestSample is UnitTest
  fun name(): String => "sample"
  fun apply(h: TestHelper) =>
    let maze = Maze(10, 7, 10)
    let start = State(0, (1, 1), maze.maze.clone())
    let router = Router(h.env, maze.maze.clone(), 10)
    router.search(start, (7, 4))

class iso _TestPuzzle is UnitTest
  fun name(): String => "puzzle"
  fun apply(h: TestHelper) =>
    let maze = Maze(62, 78, 1364)
    let start = State(0, (1, 1), maze.maze.clone())
    let router = Router(h.env, maze.maze.clone(), 62, 86)
    router.search(start, (31, 39))

class iso _TestPuzzle2 is UnitTest
  fun name(): String => "puzzle2"
  fun apply(h: TestHelper) =>
    let maze = Maze(62, 78, 1364)
    let start = State(0, (1, 1), maze.maze.clone())
    let router = Router(h.env, maze.maze.clone(), 62, 50)
    router.search(start, (31, 39))
