use "collections"

class Plain
  let env: Env
  var _size: USize = 0
  let result: Array[State] ref
  var _data: String ref = String

  new create(env': Env, result': Array[State] ref) =>
    env = env'
    result = result'
  fun ref transition(char: U8): State =>
    match char
    | '(' =>
      result.push(this)
      Instruction(env, result)
    else
      _data.push(char)
      _size = _size + 1
      this
    end
  fun ref eof() =>
    result.push(this)
  fun size(): USize =>
    _size
  fun size2(): USize =>
    _size

class Instruction
  let env: Env
  let result: Array[State] ref
  let _instr: String ref = String

  new create(env': Env, result': Array[State] ref) =>
    env = env'
    result = result'
  fun ref transition(char: U8): State =>
    try
      match char
      | ')' =>
        let parts = _instr.split("x")
        let size' = parts(0).read_int[USize]()._1
        let times = parts(1).read_int[USize]()._1
        ReadingData(env, result, size', times)
      else
        _instr.push(char)
        this
      end
    else
      env.err.print("** Unparsable " + _instr)
      this
    end
  fun ref eof() =>
    env.err.print("** End of file: " + _instr)
  fun size(): USize => 0
  fun size2(): USize => 0

class ReadingData
  let env: Env
  let result: Array[State] ref
  let _size: USize
  let times: USize
  var _data: String ref = String

  new create(env': Env, result': Array[State] ref, size': USize, times': USize) =>
    env = env'
    result = result'
    _size = size'
    times = times'
  fun ref transition(char: U8): State =>
    _data.push(char)
    if _data.size() == _size then
      // for i in Range(0, times) do
      //   result.append(_data)
      // end
      result.push(this)
      Plain(env, result)
    else
      this
    end
  fun ref eof() =>
    if _data.size() == _size then
      result.push(this)
    else
      env.err.print("** End of file? ")
    end

  fun size(): USize =>
    _size * times
  fun size2(): USize =>
    var flag: Bool = _data == "A"
    var len: USize = 0
    let decompress = DECOMP.decompress(env, _data)
    for s in decompress.values() do
      if flag then
        match s
        | let s': ReadingData => env.out.print("data")
        | let s': Instruction => env.out.print("instruction")
        | let s': Plain => env.out.print("plain")
        end
      end
      len = len + s.size2()
    end
    if flag then
      env.out
        .write("nested: " + _data)
        .write(", len: " + len.string())
        .print(", d.size: " + decompress.size().string())
    end
    len * times

type State is (Plain|Instruction|ReadingData)

primitive DECOMP
  fun decompress(env: Env, input: String box): Array[State] ref =>
    let result: Array[State] ref = Array[State]
    var state: State ref = Plain(env, result)
    for rune in input.values() do
      state = match state
      | let s: Plain => s.transition(rune)
      | let s: Instruction => s.transition(rune)
      | let s: ReadingData => s.transition(rune)
      else
        state
      end
    end
    state.eof()
    result

actor Main
  let env: Env
  new create(env': Env) =>
    env = env'

    print_result(DECOMP.decompress(env, INPUT.sample()))
    print_result2(DECOMP.decompress(env, "(27x12)(20x12)(13x14)(7x10)(1x12)A"))
    print_result(DECOMP.decompress(env, INPUT.puzzle()))
    print_result2(DECOMP.decompress(env, INPUT.puzzle()))

  fun print_result(result: Array[State]) =>
    var len: USize = 0
    for s in result.values() do
      len = len + s.size()
    end
    env.out.print("length: " + len.string())

  fun print_result2(result: Array[State]) =>
    var len: USize = 0
    for s in result.values() do
      len = len + s.size2()
    end
    env.out.print("length2: " + len.string())
