use "ponytest"
use "collections"
use "regex"
use "debug"
use "time"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestFindGoals)
    test(_TestFindDists)

class val Goal is (Hashable & Equatable[Goal])
  let name: U8
  let location: (USize, USize)
  new val create(name': U8, location': (USize, USize)) =>
    name = name'
    location = location'
  fun string(): String =>
    let l = location
    let v: U8 = name - '0'
    "@" + v.string() + "(" + l._1.string() + "," + l._2.string() + ")"
  fun eq(other: Goal): Bool =>
    name == other.name
  fun hash(): U64 =>
    name.hash()

class FindGoals
  fun search(maze: String): Array[Goal] =>
    let lines = maze.split("\n")
    let result = Array[Goal]
    try
      for y in Range(0, lines.size()) do
        let line = lines(y)
        for x in Range(0, line.size()) do
          let c = line(x)
          if ('0' <= c) and (c <= '9') then
            result.push( Goal(c, (x, y)) )
          end
        end
      end
    end
    result

  fun remove_goals(maze: String): String =>
    let result: String ref = maze.clone()
    try
      for i in Range(0, maze.size()) do
        let c = maze(i)
        if ('0' <= c) and (c <= '9') then
          result(i) = '.'
        end
      end
      result
    else
      Debug.err("**: Err")
    end
    result.clone()

  fun tuple_eq(l: (USize, USize), r: (USize, USize)): Bool =>
    (l._1 == r._1) and (l._2 == r._2)

  fun tuple_string(l: (USize, USize)): String =>
    "(" + l._1.string() + "," + l._2.string() + ")"

class iso _TestFindGoals is UnitTest
  fun name(): String => "find"
  fun apply(h: TestHelper) =>
    let find: FindGoals val = FindGoals
    let goals = find.search(INPUT.sample())
    for g in goals.values() do
      Debug.out("g: " + g.string())
    end
    Debug.out("--------------------------")
    let goals' = find.search(INPUT.puzzle())
    for g in goals'.values() do
      Debug.out("g: " + g.string())
    end

class Solver
  fun solve(env: Env, input: String) =>
    try
      let collector = Collector(env)
      let find: FindGoals val = FindGoals
      let goals = find.search(input)
      let maze = find.remove_goals(input)
      Debug.out(maze)
      var count: USize = 0
      let goals': Array[Goal] trn = recover trn Array[Goal] end
      for goal in goals.values() do
        goals'.push(goal)
      end
      collector.set_goals(consume goals')

      for i in Range(0, goals.size()) do
        for j in Range(i + 1, goals.size()) do
          let src = goals(i)
          let dst = goals(j)
          if src == dst then
            continue
          end
          // Debug.out("src:" + src.string() + " dst:" + dst.string())

          let search = SearchMaze
          search(env, maze, src.location, dst.location, collector)
          count = count + 1
        end
      end
      Debug.out("There are " + count.string() + " pairs")
      collector.set_count(count)
    else
      Debug.err("** Err")
    end

class iso _TestFindDists is UnitTest
  fun name(): String => "dists"
  fun apply(h: TestHelper) =>
    // Solver.solve(h.env, INPUT.sample())
    Solver.solve(h.env, INPUT.puzzle())
    // 470 is too high
    // got it with 428

    // 470 is too low to return to 0
