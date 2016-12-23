use "ponytest"
use "collections"
use "regex"
use "debug"
use "time"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    // test(_TestParse)
    // test(_TestSample)
    // test(_TestToggle)
    // test(_TestPuzzle)
    test(_TestPuzzle2)

class CpyInst
  let x: (String|I64)
  let y: (String|I64)
  new create(x': (String|I64), y': (String|I64)) =>
    x = x'
    y = y'
  fun apply(bunny: Assembly) ? =>
    let v = match x
    | let reg: String => bunny.registers(reg)
    | let int: I64 => int
    else error end

    match y
    | let y': String => bunny.registers(y') = v
      // Invalid if its a number so we just skip it
    end
    bunny.ip = bunny.ip + 1

  fun string(): String =>
    "cpy " + x.string() + " " + y.string()

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
  let y: (String|I64)
  new create(x': (String|I64), y': (String|I64)) =>
    x = x'
    y = y'
  fun apply(bunny: Assembly) ? =>
    let int: I64 = match x
    | let reg: String => bunny.registers(reg)
    | let v: I64 => v
    else error end

    let jmp: I64 = match y
    | let reg: String => bunny.registers(reg)
    | let v: I64 => v
    else error end

    if int != 0 then
      // Debug.out("jumping by " + jmp.string())
      bunny.ip = (bunny.ip.i64() + jmp).usize()
    else
      bunny.ip = bunny.ip + 1
    end
  fun string(): String =>
    "jnz " + x.string() + " " + y.string()

class TglInst
  let x: String
  new create(x': String) =>
    x = x'
  fun apply(bunny: Assembly) =>
    try
      let off = bunny.registers(x)
      let tgt = bunny.instructions((bunny.ip.i64() + off).usize())
      // Debug.out("Target: " + tgt.string())
      let chg: Inst = match tgt
      | let inc: IncInst => DecInst(inc.x)
      | let dec: DecInst => IncInst(dec.x)
      | let tgl: TglInst => IncInst(tgl.x)
      | let cpy: CpyInst => JnzInst(cpy.x, cpy.y)
      | let jnz: JnzInst => CpyInst(jnz.x, jnz.y)
      else
        Debug.err("** No match!")
        error
      end
      bunny.instructions((bunny.ip.i64() + off).usize()) = chg
    then
      bunny.ip = bunny.ip + 1
    end

  fun string(): String =>
    "tgl " + x

type Inst is (CpyInst|IncInst|DecInst|JnzInst|TglInst)

class Assembly
  let registers: Map[String, I64] = Map[String, I64]
  var ip: USize = 0
  var instructions: Array[Inst] = Array[Inst]
  var lastReport: I64 = 0
  var i: ISize = 0

  new create() =>
    registers("a") = 0
    registers("b") = 0
    registers("c") = 0
    registers("d") = 0

  fun ref exec(instructions': Array[Inst]) =>
    instructions = instructions'
    while ip < instructions.size() do
      try
        let nowSecs = Time.seconds()
        if (lastReport + 10) <= nowSecs then
          lastReport = nowSecs
          // env.out.print("-- " + s.moves.string() + "\n" + gs)
          // Debug.out("ip: " + ip.string() + "|" + instructions(ip).string() + "\t" + regs_string())
        end
        if (i % 1000) == 0 then
          Debug.out("ip: " + ip.string() + "|" + instructions(ip).string() + "\t" + regs_string())
        end
        instructions(ip).apply(this)
      else
        Debug.err("*** failed")
      end
      i = i + 1
    end
    try
      Debug.out("a = " + registers("a").string())
    end

  fun ref step(): Bool =>
    """
    Returns true if we should keep going
    """
    if ip < instructions.size() then
      try
        let nowSecs = Time.seconds()
        if (lastReport + 10) <= nowSecs then
          lastReport = nowSecs
          // env.out.print("-- " + s.moves.string() + "\n" + gs)
          // Debug.out("ip: " + ip.string() + "|" + instructions(ip).string() + "\t" + regs_string())
        end
        // if (i % 10000) == 0 then
        //   Debug.out("ip: " + ip.string() + "|" + instructions(ip).string() + "\t" + regs_string())
        // end
        instructions(ip).apply(this)
      else
        Debug.err("*** failed")
      end
      i = i + 1
      true
    else
      try
        Debug.out("a = " + registers("a").string())
      end
      false
    end

  fun regs_string(): String =>
    try
      String
        .append("[a:").append(registers("a").string()).append("]")
        .append("[b:").append(registers("b").string()).append("]")
        .append("[c:").append(registers("c").string()).append("]")
        .append("[d:").append(registers("d").string()).append("]").clone()
    else
      "Error"
    end

  fun parse(lines: Array[String]): Array[Inst] =>
    let result = Array[Inst]
    try
      let cpy = Regex("cpy ([a-d]) ([a-d])")
      let cpy' = Regex("cpy (-?\\d+) ([a-d])")
      let inc = Regex("inc ([a-d])")
      let dec = Regex("dec ([a-d])")
      let jnz = Regex("jnz ([a-d]) (-?\\d+)")
      let jnz' = Regex("jnz (-?\\d+) (-?\\d+)")
      let jnz'' = Regex("jnz (-?\\d+) ([a-d])")
      let tgl = Regex("tgl ([a-d])")

      for line in lines.values() do
        if cpy == line then
          let matched = cpy(line)
          result.push(CpyInst(matched(1), matched(2)))
        elseif cpy' == line then
          let matched = cpy'(line)
          result.push(CpyInst(matched(1).read_int[I64]()._1, matched(2)))
        elseif inc == line then
          let matched = inc(line)
          result.push(IncInst(matched(1)))
        elseif dec == line then
          let matched = dec(line)
          result.push(DecInst(matched(1)))
        elseif jnz == line then
          let matched = jnz(line)
          result.push(JnzInst(matched(1), matched(2).read_int[I64]()._1))
        elseif jnz' == line then
          let matched = jnz'(line)
          result.push(JnzInst(matched(1).read_int[I64]()._1, matched(2).read_int[I64]()._1))
        elseif jnz'' == line then
          let matched = jnz''(line)
          result.push(JnzInst(matched(1).read_int[I64]()._1, matched(2)))
        elseif tgl == line then
          let matched = tgl(line)
          result.push(TglInst(matched(1)))
        else
          Debug.err(" ** No match for " + line)
        end
      end
    else
      Debug.err("** Parse")
    end
    result

class iso _TestParse is UnitTest
  fun name(): String => "parse"
  fun apply(h: TestHelper) ? =>
    let bunny: Assembly ref = Assembly
    let r: Array[Inst] = bunny.parse(INPUT.sample().split("\n"))
    match r(0)
    | let cpy: CpyInst =>
      h.assert_eq[I64](2, cpy.x as I64)
      h.assert_eq[String]("a", cpy.y.string())
    else
      h.fail("not a cpy")
    end
    match r(1)
    | let tgl: TglInst =>
      h.assert_eq[String]("a", tgl.x)
    else
      h.fail("not tgl")
    end
    match r(2)
    | let tgl: TglInst =>
      h.assert_eq[String]("a", tgl.x)
    else
      h.fail("not tgl")
    end
    match r(3)
    | let tgl: TglInst =>
      h.assert_eq[String]("a", tgl.x)
    else
      h.fail("not tgl")
    end
    match r(4)
    | let cpy: CpyInst =>
      h.assert_eq[I64](1, cpy.x as I64)
      h.assert_eq[String]("a", cpy.y.string())
    else
      h.fail("not cpy")
    end
    match r(5)
    | let dec: DecInst =>
      h.assert_eq[String]("a", dec.x)
    else
      h.fail("not dec")
    end
    match r(6)
    | let dec: DecInst =>
      h.assert_eq[String]("a", dec.x)
    else
      h.fail("not dec")
    end

/*
  -  For one-argument instructions, inc becomes dec, and all other one-argument instructions become inc.
  -  For two-argument instructions, jnz becomes cpy, and all other two-instructions become jnz.
  -  The arguments of a toggled instruction are not affected.
  -  If an attempt is made to toggle an instruction outside the program, nothing happens.
  - If toggling produces an invalid instruction (like cpy 1 2) and an attempt is
    later made to execute that instruction, skip it instead.
  - If tgl toggles itself (for example, if a is 0, tgl a would target itself and become inc a),
    the resulting instruction is not executed until the next time it is reached.
*/
class iso _TestToggle is UnitTest
  fun name(): String => "toggle"
  fun apply(h: TestHelper) ? =>
    let instructions = Array[Inst]
    instructions.push(TglInst("b"))
    instructions.push(IncInst("a"))
    instructions.push(DecInst("a"))
    instructions.push(TglInst("a"))
    instructions.push(CpyInst("a", "b"))
    instructions.push(JnzInst("a", 1))

    let bunny = Assembly
    bunny.registers("b") = 1
    bunny.instructions = instructions
    try
      instructions(0).apply(bunny)
    else
      h.fail("Apply threw")
    end
    match instructions(1)
    | let dec: DecInst =>
      h.assert_eq[String]("a", dec.x)
    else
      h.fail("not dec: " + instructions(1).string())
    end

    bunny.registers("b") = 2
    bunny.ip = 0
    instructions(0).apply(bunny)
    match instructions(2)
    | let inc: IncInst =>
      h.assert_eq[String]("a", inc.x)
    else
      h.fail("not inc: " + instructions(2).string())
    end

    bunny.registers("b") = 3
    bunny.ip = 0
    instructions(0).apply(bunny)
    match instructions(3)
    | let inc: IncInst =>
      h.assert_eq[String]("a", inc.x)
    else
      h.fail("not inc: " + instructions(3).string())
    end

    bunny.registers("b") = 4
    bunny.ip = 0
    instructions(0).apply(bunny)
    match instructions(4)
    | let jnz: JnzInst =>
      h.assert_eq[String]("a", jnz.x.string())
      h.assert_eq[String]("b", jnz.y.string())
    else
      h.fail("not jnz: " + instructions(3).string())
    end

    bunny.registers("b") = 5
    bunny.ip = 0
    instructions(0).apply(bunny)
    match instructions(5)
    | let jnz: CpyInst =>
      h.assert_eq[String]("a", jnz.x.string())
      h.assert_eq[I64](1, jnz.y as I64)
    else
      h.fail("not cpy: " + instructions(3).string())
    end
    // Verify bad instruction is skipped
    bunny.ip = 5
    instructions(5).apply(bunny)
    h.assert_eq[USize](6, bunny.ip)

    bunny.registers("b") = 100 // Out of bounds
    bunny.ip = 0
    instructions(0).apply(bunny)
    h.assert_eq[USize](1, bunny.ip)

    // Toggle self
    bunny.registers("b") = 0
    bunny.ip = 0
    instructions(0).apply(bunny)
    h.assert_eq[USize](1, bunny.ip)

class iso _TestSample is UnitTest
  fun name(): String => "sample"
  fun apply(h: TestHelper) ? =>
    let bunny: Assembly ref = Assembly
    let r: Array[Inst] = bunny.parse(INPUT.sample().split("\n"))
    bunny.exec(r)
    h.assert_eq[I64](3, bunny.registers("a"))

class iso _TestPuzzle is UnitTest
  fun name(): String => "puzzle"
  fun apply(h: TestHelper) ? =>
    let bunny: Assembly ref = Assembly
    let r: Array[Inst] = bunny.parse(INPUT.puzzle().split("\n"))
    for i in r.values() do
      Debug.out(i.string())
    end
    bunny.registers("a") = 7
    bunny.exec(r)
    h.assert_eq[I64](12748, bunny.registers("a"))

actor Runner
  let env: Env
  let bunny: Assembly = Assembly
  new create(env': Env) =>
    env = env'
    let r: Array[Inst] = bunny.parse(INPUT.puzzle().split("\n"))
    for i in r.values() do
      Debug.out(i.string())
    end
    bunny.instructions = r
    bunny.registers("a") = 12

  be step() =>
    if bunny.step() then
      this.step()
    else
      env.out.print(bunny.regs_string())
    end

class iso _TestPuzzle2 is UnitTest
  fun name(): String => "puzzle2"
  fun apply(h: TestHelper) =>
    let runner = Runner(h.env)
    runner.step()
