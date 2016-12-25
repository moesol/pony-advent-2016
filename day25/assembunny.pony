use "collections"
use "debug"
use "time"
use "regex"

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

class OutInst
  let x: (String|I64)
  new create(x': (String|I64)) =>
    x = x'
  fun apply(bunny: Assembly) ? =>
    match x
    | let reg: String => bunny.out(bunny.registers(reg))
    | let v: I64 => bunny.out(v)
    end
    bunny.ip = bunny.ip + 1
  fun string(): String =>
    "out " + x.string()

type Inst is (CpyInst|IncInst|DecInst|JnzInst|TglInst|OutInst)

class Assembly
  let registers: Map[String, I64] = Map[String, I64]
  var ip: USize = 0
  var instructions: Array[Inst] = Array[Inst]
  var lastReport: I64 = 0
  var i: ISize = 0
  var lastOut: I64 = -1
  var goodCount: USize = 0
  var fail: Bool = false
  var success: Bool = false

  new create() =>
    registers("a") = 0
    registers("b") = 0
    registers("c") = 0
    registers("d") = 0

  fun ref exec(instructions': Array[Inst]) =>
    instructions = instructions'
    while ip < instructions.size() do
      if fail then break end
      if success then break end
      try
        let nowSecs = Time.seconds()
        if (lastReport + 10) <= nowSecs then
          lastReport = nowSecs
          // env.out.print("-- " + s.moves.string() + "\n" + gs)
          // Debug.out("ip: " + ip.string() + "|" + instructions(ip).string() + "\t" + regs_string())
        end
        // if (i % 1000) == 0 then
        //   Debug.out("ip: " + ip.string() + "|" + instructions(ip).string() + "\t" + regs_string())
        // end
        instructions(ip).apply(this)
      else
        Debug.err("*** failed")
      end
      i = i + 1
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

// asmout
  fun ref reset() =>
    registers("a") = 0
    registers("b") = 0
    registers("c") = 0
    registers("d") = 0
    ip = 0
    lastOut = -1
    goodCount = 0
    fail = false
    success = false
  fun ref out(v: I64) =>
    if lastOut != v then
      lastOut = v
      goodCount = goodCount + 1
    else
      fail = true
    end
    if goodCount > 100 then
      success = true
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
      let out_regex = Regex("out ([a-d])")

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
        elseif out_regex == line then
          let matched = out_regex(line)
          result.push(OutInst(matched(1)))
        else
          Debug.err(" ** No match for " + line)
        end
      end
    else
      Debug.err("** Parse")
    end
    result
