use "regex"
use "collections"
use "debug"

class RECT
  let w: U32
  let h: U32
  new create(width: U32, height: U32) =>
    w = width
    h = height
  fun string(): String =>
    String.append("rect ").append(w.string()).append("x").append(h.string()).clone()

class RotateROW
  let y: U32
  let d: U32
  new create(y': U32, d': U32) =>
    y = y'
    d = d'
  fun string(): String =>
    "y = " + y.string() +" by " + d.string()

class RotateCOLUMN
  let x: U32
  let d: U32
  new create(x': U32, d': U32) =>
    x = x'
    d = d'
  fun string(): String =>
    "x = " + x.string() +" by " + d.string()

type Operation is (RECT|RotateROW|RotateCOLUMN)

class Screen
  let width: USize
  let height: USize
  let rows: Array[String ref] = Array[String ref]

  new create(width': USize, height': USize) =>
    width = width'
    height = height'
    for r in Range(0, height) do
      let str: String ref = String
      for c in Range(0, width) do
        str.push('.')
      end
      rows.push(str.clone())
    end
  fun print(env: Env) =>
    for r in rows.values() do
      env.out.print(r.clone())
    end
  fun ref apply(op: Operation) ? =>
    // Debug.out(op.string())
    match op
    | let rect: RECT =>
      for y in Range(0, rect.h.usize()) do
        for x in Range(0, rect.w.usize()) do
          rows(y)(x) = '#'
        end
      end
    | let rr: RotateROW =>
      let oldRow = rows(rr.y.usize()).clone()
      for c in Range(0, width) do
        let tc = (c + rr.d.usize()) % width
        rows(rr.y.usize())(tc) = oldRow(c)
      end
    | let rc: RotateCOLUMN =>
      let oldCol: String ref = String
      for r in Range(0, height) do
        oldCol.push(rows(r)(rc.x.usize()))
      end
      for r in Range(0, height) do
        let tr = (r + rc.d.usize()) % height
        rows(tr.usize())(rc.x.usize()) = oldCol(r)
      end
    end
  fun count(): USize =>
    var cnt: USize = 0
    for r in Range(0, height) do
      for c in Range(0, width) do
        try
          let char = rows(r)(c)
          if char == '#' then
            cnt = cnt + 1
          end
        end
      end
    end
    cnt

actor Main
  let env: Env
  new create(env': Env) =>
    env = env'

    do_sample()
    do_puzzle()

  fun do_sample() =>
    let ops = parse_input(INPUT.sample().split("\n"))
    let screen = Screen(7,3)
    for o in ops.values() do
      try
        screen(o)
      else
        env.err.print("** error 1")
      end
    end
    screen.print(env)
    env.out.write("n: ").print(screen.count().string())

  fun do_puzzle() =>
    let ops = parse_input(INPUT.puzzle().split("\n"))
    let screen = Screen(50, 6)
    for o in ops.values() do
      try
        screen(o)
      else
        env.err.print("** error 2")
      end
    end
    screen.print(env)
    env.out.write("n: ").print(screen.count().string())

  fun parse_input(lines: Array[String]): Array[Operation] =>
    let result = Array[Operation]
    for line in lines.values() do
      try
        result.push(parse_line(line))
      else
        env.err.print("** Failed on " + line)
      end
    end
    result

  fun parse_line(line: String): Operation ? =>
    let r = Regex("rect (\\d+)x(\\d+)")
    let cr = Regex("rotate (column|row) x=(\\d+) by (\\d+)")
    let rr = Regex("rotate (column|row) y=(\\d+) by (\\d+)")

    if r == line then
      let matched = r(line)
      return RECT(
        matched(1).read_int[U32]()._1,
        matched(2).read_int[U32]()._1)
    end
    if cr == line then
      let matched = cr(line)
      return RotateCOLUMN(
        matched(2).read_int[U32]()._1,
        matched(3).read_int[U32]()._1)
    end
    if rr == line then
      let matched = rr(line)
      return RotateROW(
        matched(2).read_int[U32]()._1,
        matched(3).read_int[U32]()._1)
    end
    env.err.write("** No match: ").print(line)
    error
