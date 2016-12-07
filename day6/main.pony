use "collections"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    decode(MESSAGE.sample().split("\n"))
    decode(MESSAGE.input().split("\n"))

  fun decode(lines: Array[String] val) =>
    var last: USize = try lines(0).size() else 0 end
    let result: String ref = String
    let result': String ref = String
    for col in Range(0, last) do
      let freq = Array[USize].init(0, 26)
      try
        for line in lines.values() do
          let offset = (line(col) - 'a').usize()
          freq(offset) = freq(offset) + 1
        end
      else
        env.out.print("** error 1")
      end
      let char = find_max(freq) + 'a'
      result.push(char.u8())
      let char' = find_min(freq) + 'a'
      result'.push(char'.u8())
      // print_freq(freq)
    end
    env.out.print("result: " + result)
    env.out.print("result': " + result')

  fun print_freq(counts: Array[USize]) =>
    env.out.print("{")
    for i in Range(0, counts.size()) do
      let char: String ref = String
      char.push((i + 'a').u8())
      env.out.write(char.clone())
        .write("->").write(try counts(i).string() else "oops" end)
        .write(" ")
    end
    env.out.print("}")

  fun find_max(counts: Array[USize]): USize =>
    var maxIndex: USize = 0
    var maxValue: USize = 0
    for i in Range(0, counts.size()) do
      try
        if counts(i) > maxValue then
          maxIndex = i
          maxValue = counts(i)
        end
      else
        env.out.print("** error 4")
      end
    end
    maxIndex

  fun find_min(counts: Array[USize]): USize =>
    var minIndex: USize = 0
    var minValue: USize = USize.max_value()
    for i in Range(0, counts.size()) do
      try
        if (counts(i) > 0) and (counts(i) < minValue) then
          minIndex = i
          minValue = counts(i)
        end
      else
        env.out.print("** error 4")
      end
    end
    minIndex
