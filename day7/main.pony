use "collections"

primitive OUTSIDE
primitive INSIDE

type LexState is (OUTSIDE|INSIDE)

primitive EOL

actor Main
  let env: Env
  new create(env': Env) =>
    env = env'

    count_types(INPUT.sample().split("\n"))
    count_types(INPUT.sample2().split("\n"))
    count_types(INPUT.sample3().split("\n"))
    count_types(INPUT.puzzle().split("\n"))

  fun count_types(lines: Array[String] box) =>
    env.out.print("lines: " + lines.size().string())
    var count: USize = 0
    var count': USize = 0
    for line in lines.values() do
      let res = is_tls_or_ssl(line)
      if res._1 then
        // env.out.write("supports TLS:").print(line)
        count = count + 1
      end
      if res._2 then
        // env.out.write("supports SSL:").print(line)
        count' = count' + 1
      end
    end
    env.out.print("count: " + count.string())
    env.out.print("count': " + count'.string())

  fun char_or_eol(line: String, index: USize): (EOL|U8) ? =>
    if index >= line.size() then
      EOL
    else
      line(index)
    end

  fun is_tls_or_ssl(line: String): (Bool,Bool) =>
    var abba_outside: USize = 0
    var abba_inside: USize = 0
    var collecting: String ref = String
    var state: LexState = OUTSIDE
    let abaSet = Set[String]
    let babSet = Set[String]

    for i in Range(0, line.size() + 1) do // +  gets us EOL
      try
        let char = char_or_eol(line, i)
        state = match state
        | OUTSIDE =>
          match char
          | '[' =>
            abba_outside = abba_outside + is_abba(collecting.clone())
            add_to_aba_set(abaSet, collecting.clone())
            collecting = String
            INSIDE
          | EOL =>
            abba_outside = abba_outside + is_abba(collecting.clone())
            add_to_aba_set(abaSet, collecting.clone())
            OUTSIDE
          else
            collecting.push(char as U8)
            OUTSIDE
          end
        | INSIDE =>
          match char
          | ']' =>
            abba_inside = abba_inside + is_abba(collecting.clone())
            add_to_bab_set(babSet, collecting.clone())
            collecting = String
            OUTSIDE
          | EOL =>
            abba_outside = abba_outside + is_abba(collecting.clone())
            add_to_bab_set(babSet, collecting.clone())
            OUTSIDE
          else
            collecting.push(char as U8)
            INSIDE
          end
        else
          env.out.print("** error 1")
          error
        end
      end
    end
    let tls: Bool = if abba_inside > 0 then
      false
    else
      abba_outside > 0
    end
    let both = abaSet and babSet
    let ssl: Bool = if both.size() > 0 then
      true
    else
      false
    end
    (tls, ssl)

  fun print_set(msg: String, set: Set[String]) =>
    env.out.print("{" + msg)
    for v in set.values() do
      env.out.print("--" + v)
    end

  fun add_to_aba_set(set: Set[String], token: String) =>
    try
      var window: String ref = String
      for i in Range(0, 2) do
        window.push(token(i))
      end

      for i in Range(2, token.size()) do
        window.push(token(i))
        if is_window_aba(window) then
          set.set(window.clone())
        end
        window.shift()
      end
    else
      env.out.print("** error 2")
    end

  fun add_to_bab_set(set: Set[String], token: String) =>
    try
      var window: String ref = String
      for i in Range(0, 2) do
        window.push(token(i))
      end

      for i in Range(2, token.size()) do
        window.push(token(i))
        if is_window_aba(window) then
          set.set(invert_aba(window))
        end
        window.shift()
      end
    else
      env.out.print("** error 2")
    end

  fun invert_aba(window: String box): String =>
    let result: String ref = String
    try
      result.push(window(1))
      result.push(window(0))
      result.push(window(1))
    else
      env.out.print("** window broken")
    end
    result.clone()

  fun is_window_aba(window: String box): Bool ? =>
    (window(0) == window(2))
      and
    (window(0) != window(1))

  fun is_abba(token: String): USize =>
    try
      var window: String ref = String
      for i in Range(0, 3) do
        window.push(token(i))
      end

      for i in Range(3, token.size()) do
        window.push(token(i))
        if is_window_abba(window) then
          return 1
        end
        window.shift()
      end
    else
      env.out.print("** error 2")
    end
    0

  fun is_window_abba(window: String box): Bool ? =>
    // env.out.print("window: " + window)
    if window(0) == window(1) then
      return false
    end
    if (window(0) == window(3)) and (window(1) == window(2)) then
      return true
    end
    false
