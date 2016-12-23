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
    // test(_TestSample)
    test(_TestPuzzle)

class CpyInst
  let x: (String|I64)
  let y: String
  new create(x': (String|I64), y': String) =>
    x = x'
    y = y'
  fun apply(bunny: Assembly) ? =>
    match x
    | let reg: String => bunny.registers(y) = bunny.registers(reg)
    | let int: I64 => bunny.registers(y) = int
    end
    bunny.ip = bunny.ip + 1
  fun string(): String =>
    "cpy " + x.string() + " " + y

class IncInst
  let x: String
  new create(x': String) =>
    x = x'
  fun apply(bunny: Assembly) ? =>
    bunny.registers(x) = bunny.registers(x) + 1
    bunny.ip = bunny.ip + 1
  fun string(): String =>
    "inc " + x

class DecInst
  let x: String
  new create(x': String) =>
    x = x'
  fun apply(bunny: Assembly) ? =>
    bunny.registers(x) = bunny.registers(x) - 1
    bunny.ip = bunny.ip + 1
  fun string(): String =>
    "dec " + x

class JnzInst
  let x: (String|I64)
  let y: I64
  new create(x': (String|I64), y': I64) =>
    x = x'
    y = y'
  fun apply(bunny: Assembly) ? =>
    let int: I64 = match x
    | let reg: String => bunny.registers(reg)
    | let v: I64 => v
    else 0 end

    if int != 0 then
      // Debug.out("jumping by " + y.string())
      bunny.ip = (bunny.ip.i64() + y).usize()
    else
      bunny.ip = bunny.ip + 1
    end
  fun string(): String =>
    "jnz " + x.string() + " " + y.string()

type Inst is (CpyInst|IncInst|DecInst|JnzInst)

class Assembly
  let registers: Map[String, I64] = Map[String, I64]
  var ip: USize = 0

  new create() =>
    registers("a") = 0
    registers("b") = 0
    registers("c") = 0
    registers("d") = 0

  fun ref exec(instructions: Array[Inst]) =>
    while ip < instructions.size() do
      try
        // Debug.out("ip: " + ip.string() + "|" + instructions(ip).string())
        instructions(ip).apply(this)
      else
        Debug.err("*** failed")
      end
    end
    try
      Debug.out("a = " + registers("a").string())
    end

  fun parse(lines: Array[String]): Array[Inst] =>
    let instructions = Array[Inst]
    try
      let cpy = Regex("cpy ([a-d]) ([a-d])")
      let cpy' = Regex("cpy (-?\\d+) ([a-d])")
      let inc = Regex("inc ([a-d])")
      let dec = Regex("dec ([a-d])")
      let jnz = Regex("jnz ([a-d]) (-?\\d+)")
      let jnz' = Regex("jnz (-?\\d+) (-?\\d+)")

      for line in lines.values() do
        if cpy == line then
          let matched = cpy(line)
          instructions.push(CpyInst(matched(1), matched(2)))
        elseif cpy' == line then
          let matched = cpy'(line)
          instructions.push(CpyInst(matched(1).read_int[I64]()._1, matched(2)))
        elseif inc == line then
          let matched = inc(line)
          instructions.push(IncInst(matched(1)))
        elseif dec == line then
          let matched = dec(line)
          instructions.push(DecInst(matched(1)))
        elseif jnz == line then
          let matched = jnz(line)
          instructions.push(JnzInst(matched(1), matched(2).read_int[I64]()._1))
        elseif jnz' == line then
          let matched = jnz'(line)
          instructions.push(JnzInst(matched(1).read_int[I64]()._1, matched(2).read_int[I64]()._1))
        else
          Debug.err(" ** No match for " + line)
        end
      end
    else
      Debug.err("** Parse")
    end
    instructions

class iso _TestParse is UnitTest
  fun name(): String => "parse"
  fun apply(h: TestHelper) ? =>
    let bunny: Assembly ref = Assembly
    let r: Array[Inst] = bunny.parse(INPUT.sample().split("\n"))
    match r(0)
    | let cpy: CpyInst =>
      h.assert_eq[I64](41, cpy.x as I64)
      h.assert_eq[String]("a", cpy.y)
    else
      h.fail("not a cpy")
    end
    match r(1)
    | let inc: IncInst =>
      h.assert_eq[String]("a", inc.x)
    else
      h.fail("not inc")
    end
    match r(2)
    | let inc: IncInst =>
      h.assert_eq[String]("a", inc.x)
    else
      h.fail("not inc")
    end
    match r(3)
    | let dec: DecInst =>
      h.assert_eq[String]("a", dec.x)
    else
      h.fail("not dec")
    end
    match r(4)
    | let jnz: JnzInst =>
      h.assert_eq[String]("a", jnz.x as String)
      h.assert_eq[I64](2, jnz.y)
    else
      h.fail("not jnz")
    end
    match r(5)
    | let dec: DecInst =>
      h.assert_eq[String]("a", dec.x)
    else
      h.fail("not dec")
    end

class iso _TestSample is UnitTest
  fun name(): String => "sample"
  fun apply(h: TestHelper) =>
    let bunny: Assembly ref = Assembly
    let r: Array[Inst] = bunny.parse(INPUT.sample().split("\n"))
    bunny.exec(r)

class iso _TestPuzzle is UnitTest
  fun name(): String => "puzzle"
  fun apply(h: TestHelper) =>
    let bunny: Assembly ref = Assembly
    let r: Array[Inst] = bunny.parse(INPUT.puzzle().split("\n"))
    for i in r.values() do
      Debug.out(i.string())
    end
    bunny.exec(r)
