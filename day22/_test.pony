use "ponytest"
use "collections"
use "regex"
use "debug"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestParse)
    test(_TestCountViablePairs)

class Node
  let x: USize
  let y: USize
  let size: USize
  let used: USize

  new create(x': USize, y': USize, size': USize, used': USize) =>
    x = x'
    y = y'
    size = size'
    used = used'

  fun avail(): USize =>
    size - used

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

class iso _TestCountViablePairs is UnitTest
  fun name(): String => "count viable"
  fun apply(h: TestHelper) =>
    let grid: Grid ref = Grid
    let r = grid.parse(INPUT.puzzle().split("\n"))
    let viable = grid.count_viable_pairs(r)
    h.assert_eq[USize](1024, viable)
