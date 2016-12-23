use "ponytest"
use "collections"
use "regex"
use "debug"
use "time"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestParse)
    test(_TestCountViablePairs)
    test(_TestMakeGridString)
    // test(_TestSampleSolve)
    test(_TestPuzzle2Solve)

class val Node
  let x: USize
  let y: USize
  let size: USize
  let used: USize
  let goal: Bool

  new val create(x': USize, y': USize, size': USize, used': USize, goal': Bool = false) =>
    x = x'
    y = y'
    size = size'
    used = used'
    goal = goal'

  new val make_goal(old: Node) =>
    x = old.x
    y = old.y
    size = old.size
    used = old.used
    goal = true

  fun move_to(to: Node): Node val =>
    Node(to.x, to.y, size, used, goal)

  fun avail(): USize =>
    size - used

  fun string(): String =>
    "x" + x.string() + " y" + y.string()

class val State
  let moves: USize
  let nodes: Array[Node] val
  new val create(moves': USize, nodes': Array[Node] val) =>
    moves = moves'
    nodes = nodes'

actor Router
  let env: Env
  var idx: USize = 0
  let workers: Array[Worker] = Array[Worker]
  let visited: Set[String] = Set[String]
  let grid: Grid = Grid
  var win: Bool = false
  var moves: USize = 0
  var lastReport: I64 = 0

  new create(env': Env) =>
    env = env'
    for i in Range(0, 4) do
      workers.push(Worker)
    end

  be route_work(s: State) =>
    let gs = grid.make_grid_string(s.nodes)
    if visited.contains(gs) then
      // Been here, done that
      return
    end
    visited.set(gs)
    Debug.out("route: " + s.moves.string() + "\n" + gs)

    let nowSecs = Time.seconds()
    if (lastReport + 10) <= nowSecs then
      lastReport = nowSecs
      env.out.print("-- " + s.moves.string() + "\n" + gs)
    end

    try
      if gs(0) == 'G' then
        win = true
        moves = s.moves
        env.out.print("!! win: " + s.moves.string())
      end
    end
    if win then
      return
    end

    // Prune states that move G down
    try
      var found = false
      for i in Range(0, gs.size()) do
        match gs(i)
        | '\n' => break
        | 'G' => found = true
        end
      end
      if not found then
        return
      end
    end

    try
      workers(idx % workers.size()).next_states(s, this)
    end

actor Worker
  be next_states(s: State, router: Router) =>
    if s.moves >= 300 then
      Debug.out("Killing off state")
      return
    end
    let pairs = Grid.find_viable_pairs(s.nodes)
    for pair in pairs.values() do
      (let a, let b) = pair
      let ax = a.x.isize()
      let ay = a.y.isize()
      let bx = b.x.isize()
      let by = b.y.isize()
      match ( (ax -bx).abs(), (ay - by).abs() )
      | (1, 0) => router.route_work(swap_pair(s, a, b))
      | (0, 1) => router.route_work(swap_pair(s, a, b))
      | (let dx: USize, let dy: USize) =>
        // Debug.out("*" + dx.string() + "," + dy.string())
        None
      end
    end

  fun swap_pair(s: State, a: Node, b: Node): State =>
    let a' = a.move_to(b)
    let b' = b.move_to(a)
    let nodes: Array[Node] iso = recover iso Array[Node] end
    for n in s.nodes.values() do
      if n is a then
        nodes.push(a')
      elseif n is b then
        nodes.push(b')
      else
        nodes.push(n)
      end
    end
    State(s.moves + 1, consume nodes)

class Grid
  fun parse(lines: Array[String]): Array[Node] =>
    let result = Array[Node]
    try
      let df = Regex("/dev/grid/node-x(\\d+)-y(\\d+)\\s+(\\d+)T\\s+(\\d+)T\\s+(\\d+)T\\s+(\\d+)%")

      for line in lines.values() do
        if df == line then
          let matched = df(line)
          let x: USize = matched(1).read_int[USize]()._1
          let y = matched(2).read_int[USize]()._1
          let size = matched(3).read_int[USize]()._1
          let used = matched(4).read_int[USize]()._1
          let avail = matched(5).read_int[USize]()._1
          let percent = matched(6).read_int[USize]()._1

          let node = Node(x, y, size, used)
          if avail != node.avail() then
            Debug.err("** Error2")
          end
          result.push(node)
        end
      end
    else
      Debug.err("** Error")
    end
    result

  fun set_goal(nodes: Array[Node] box): Array[Node] val =>
    let r: Array[Node] iso = recover iso Array[Node] end
    (let width, let height) = size_grid(nodes)
    for n in nodes.values() do
      match (n.x, n.y)
      | (width - 1, 0) => r.push(Node.make_goal(n))
      else r.push(n) end
    end
    r

  fun size_grid(nodes: Array[Node] box): (USize, USize) =>
    var max_x: USize = 0
    var max_y: USize = 0
    for n in nodes.values() do
      max_x = max_x.max(n.x)
      max_y = max_y.max(n.y)
    end
    let width = max_x + 1
    let height = max_y + 1
    (width, height)

  fun make_grid_string(nodes: Array[Node] box): String =>
    (let width, let height) = size_grid(nodes)
    _make_grid_string(nodes, width, height)

  fun _make_grid_string(nodes: Array[Node] box, width: USize, height: USize): String =>
    let result: String iso = recover iso String end
    for y in Range(0, height) do
      for x in Range(0, width) do
        result.push('#')
      end
      result.push('\n')
    end

    let viable = find_viable_pairs(nodes)
    for pair in viable.values() do
      (let a, let b) = pair
      try
        result(idx(a.x, a.y, width)) = '.'
      else
        Debug.err("** Err 197")
      end
    end
    for pair in viable.values() do
      (let a, let b) = pair
      try
        result(idx(b.x, b.y, width)) = '_'
      else
        Debug.err("** Err 205")
      end
    end
    for n in nodes.values() do
      if n.goal then
        try
          result(idx(n.x, n.y, width)) = 'G'
        end
        break
      end
    end
    result

  fun idx(x: USize, y: USize, width: USize): USize =>
    // width + 1 to handle \n
    (y * (width + 1)) + x

  fun find_viable_pairs(nodes: Array[Node] box): Array[(Node, Node)] =>
    let result = Array[(Node, Node)]
    for i in Range(0, nodes.size()) do
      for j in Range(0, nodes.size()) do
        try
          let a = nodes(i)
          let b = nodes(j)

          if a.used == 0 then
            // Node A is not empty (its Used is not zero).
            continue
          end
          if i == j then
            // Nodes A and B are not the same node.
            continue
          end
          if a.used > b.avail() then
            // The data on node A (its Used) would fit on node B (its Avail).
            continue
          end
          result.push((a, b))
        else
          Debug.err("** Out of bounds")
        end
      end
    end
    result

  fun count_viable_pairs(nodes: Array[Node]): USize =>
    var count: USize = 0
    for i in Range(0, nodes.size()) do
      for j in Range(0, nodes.size()) do
        try
          let a = nodes(i)
          let b = nodes(j)

          if a.used == 0 then
            // Node A is not empty (its Used is not zero).
            continue
          end
          if i == j then
            // Nodes A and B are not the same node.
            continue
          end
          if a.used > b.avail() then
            // The data on node A (its Used) would fit on node B (its Avail).
            continue
          end
          count = count + 1
        else
          Debug.err("** Out of bounds")
        end
      end
    end
    count

class iso _TestParse is UnitTest
  fun name(): String => "parse"
  fun apply(h: TestHelper) ? =>
    let grid: Grid ref = Grid
    let r = grid.parse(INPUT.puzzle().split("\n"))
    h.assert_eq[USize](1054, r.size())
    h.assert_eq[USize](91, r(0).size)
    h.assert_eq[USize](71, r(0).used)
    h.assert_eq[USize](20, r(0).avail())

    let r' = grid.parse(INPUT.sample().split("\n"))
    h.assert_eq[USize](9, r'.size())
    h.assert_eq[USize](10, r'(0).size)
    h.assert_eq[USize](8, r'(0).used)
    h.assert_eq[USize](2, r'(0).avail())

class iso _TestCountViablePairs is UnitTest
  fun name(): String => "count viable"
  fun apply(h: TestHelper) =>
    let grid: Grid ref = Grid
    let r = grid.parse(INPUT.puzzle().split("\n"))
    let viable = grid.count_viable_pairs(r)
    h.assert_eq[USize](1024, viable)

class iso _TestMakeGridString is UnitTest
  fun name(): String => "make grid string"
  fun apply(h: TestHelper) =>
    let grid: Grid ref = Grid
    let nodes = grid.parse(INPUT.sample().split("\n"))
    let gs = grid.make_grid_string(nodes)

class iso _TestSampleSolve is UnitTest
  fun name(): String => "sample solve"
  fun apply(h: TestHelper) =>
    let router = Router(h.env)
    let nodes = recover val Grid.parse(INPUT.sample().split("\n")) end
    let start = State(0, Grid.set_goal(nodes))
    router.route_work(start)

class iso _TestPuzzle2Solve is UnitTest
  fun name(): String => "puzzle part2"
  fun apply(h: TestHelper) =>
    let router = Router(h.env)
    let nodes = recover val Grid.parse(INPUT.puzzle().split("\n")) end
    let start = State(0, Grid.set_goal(nodes))
    router.route_work(start)
