use "collections"

actor Main
  new create(env: Env) =>
    env.out.print("hi")
    let keyPad = KeyPad.make1(env)
    try
      keyPad(demo_input())
    else
      env.err.print("Bad input")
    end
    env.out.print("--")
    // env.out.print("input: " + puzzle_input())
    let real = KeyPad.make1(env)
    try
      real(puzzle_input())
    else
      env.err.print("Bad input2")
    end
    env.out.print("--")

    part2a(env)
    part2b(env)

  fun part2a(env: Env) =>
    let pad = KeyPad.make2(env)
    try
      pad(demo_input())
    else
      env.err.print("Bad input 3")
    end
    env.out.print("--")

  fun part2b(env: Env) =>
    let pad = KeyPad.make2(env)
    try
      pad(puzzle_input())
    else
      env.err.print("Bad input 4")
    end
    env.out.print("--")

  fun demo_input(): String =>
"""ULL
RRDDD
LURDL
UUUUD
"""

  fun puzzle_input(): String =>
    """LDUDDRUDRRURRRRDRUUDULDLULRRLLLUDDULRDLDDLRULLDDLRUURRLDUDDDDLUULUUDDDDLLLLLULLRURDRLRLRLLURDLLDDUULUUUUDLULLRLUUDDLRDRRURRLURRLLLRRDLRUDURRLRRRLULRDLUDRDRLUDDUUULDDDDDURLDULLRDDRRUDDDDRRURRULUDDLLRRDRURDLLLLLUUUDLULURLULLDRLRRDDLUDURUDRLRURURLRRDDLDUULURULRRLLLDRURDULRDUURRRLDLDUDDRLURRDRDRRLDLRRRLRURDRLDRUDLURRUURDLDRULULURRLDLLLUURRULUDDDRLDDUDDDRRLRDUDRUUDDULRDDULDDURULUDLUDRUDDDLRRRRRDLULDRLRRRRUULDUUDRRLURDLLUUDUDDDLUUURDRUULRURULRLLDDLLUDLURRLDRLDDDLULULLURLULRDLDRDDDLRDUDUURUUULDLLRDRUDRDURUUDDLRRRRLLLUULURRURLLDDLDDD
DRURURLLUURRRULURRLRULLLURDULRLRRRLRUURRLRRURRRRUURRRLUDRDUDLUUDULURRLDLULURRLDURLUUDLDUDRUURDDRDLLLDDRDDLUUDRDUDDRRDLDUDRLDDDRLLDDLUDRULRLLURLDLURRDRUDUDLDLULLLRDLLRRDULLDRURRDLDRURDURDULUUURURDLUDRRURLRRLDULRRDURRDRDDULLDRRRLDRRURRRRUURDRLLLRRULLUDUDRRDDRURLULLUUDDRLDRRDUDLULUUDRDDDDLRLRULRLRLLDLLRRDDLDRDURRULLRLRRLULRULDDDRDRULDRUUDURDLLRDRURDRLRDDUDLLRUDLURURRULLUDRDRDURLLLDDDRDRURRDDRLRRRDLLDDLDURUULURULRLULRLLURLUDULDRRDDLRDLRRLRLLULLDDDRDRU
URUUDUDRDDRDRRRDLLUDRUDRUUUURDRRDUDUULDUDLLUDRRUDLLRDLLULULDRRDDULDRLDLDDULLDDRDDDLRLLDLLRDUUDUURLUDURDRRRRLRRLDRRUULLDLDLRDURULRURULRRDRRDDUUURDURLLDDUUDLRLDURULURRRDRRUUUDRDDLRLRRLLULUDDRRLRRRRLRDRUDDUULULRRURUURURRLRUDLRRUUURUULLULULRRDDULDRRLLLDLUDRRRLLRDLLRLDUDDRRULULUDLURLDRDRRLULLRRDRDLUURLDDURRLDRLURULDLDRDLURRDRLUUDRUULLDRDURLLDLRUDDULLLLDLDDDLURDDUDUDDRLRDDUDDURURLULLRLUDRDDUDDLDRUURLDLUUURDUULRULLDDDURULDDLLD
LRRLLRURUURRDLURRULDDDLURDUURLLDLRRRRULUUDDLULLDLLRDLUDUULLUDRLLDRULDDURURDUUULRUDRLLRDDDURLRDRRURDDRUDDRRULULLLDLRLULLDLLDRLLLUDLRURLDULRDDRDLDRRDLUUDDLURDLURLUDLRDLDUURLRRUULDLURULUURULLURLDDURRURDRLUULLRRLLLDDDURLURUURLLLLDLLLUDLDLRDULUULRRLUUUUDLURRURRULULULRURDDRRRRDRUDRURDUDDDDUDLURURRDRRDRUDRLDLDDDLURRRURRUDLDURDRLDLDLDDUDURLUDUUDRULLRLLUUDDUURRRUDURDRRUURLUDRRUDLUDDRUUDLULDLLDLRUUDUULLDULRRLDRUDRRDRLUUDDRUDDLLULRLULLDLDUULLDRUUDDUDLLLLDLDDLDLURLDLRUUDDUULLUDUUDRUDLRDDRDLDRUUDUDLLDUURRRLLLLRLLRLLRLUUDULLRLURDLLRUUDRULLULRDRDRRULRDLUDDURRRRURLLRDRLLDRUUULDUDDLRDRD
DDLRRULRDURDURULLLLRLDDRDDRLLURLRDLULUDURRLUDLDUDRDULDDULURDRURLLDRRLDURRLUULLRUUDUUDLDDLRUUDRRDDRLURDRUDRRRDRUUDDRLLUURLURUDLLRRDRDLUUDLUDURUUDDUULUURLUDLLDDULLUURDDRDLLDRLLDDDRRDLDULLURRLDLRRRLRRURUUDRLURURUULDURUDRRLUDUDLRUDDUDDRLLLULUDULRURDRLUURRRRDLLRDRURRRUURULRUDULDULULUULULLURDUDUDRLDULDRDDULRULDLURLRLDDDDDDULDRURRRRDLLRUDDRDDLUUDUDDRLLRLDLUDRUDULDDDRLLLLURURLDLUUULRRRUDLLULUUULLDLRLDLLRLRDLDULLRLUDDDRDRDDLULUUR
"""

interface HasMove
  fun move(old: (USize, USize)): (USize, USize)

type Moves is (MoveU|MoveD|MoveL|MoveR|ENDOFLINE)
primitive MoveU is HasMove
  fun move(old: (USize, USize)): (USize, USize) =>
    (old._1 - 1, old._2)
primitive MoveD is HasMove
  fun move(old: (USize, USize)): (USize, USize) =>
    (old._1 + 1, old._2)
primitive MoveL is HasMove
  fun move(old: (USize, USize)): (USize, USize) =>
    (old._1, old._2 - 1)
primitive MoveR is HasMove
  fun move(old: (USize, USize)): (USize, USize) =>
    (old._1, old._2 + 1)

primitive ENDOFLINE

class KeyPadKey
  let label: String
  let row: USize
  let col: USize

  new create(label': String, row': USize, col': USize) =>
    label = label'
    row = row'
    col = col'
  fun string(): String =>
    label

class KeyPad
  let env: Env
  let rows: Array[String] = Array[String]
  var location: (USize, USize)

  new make1(env': Env) =>
    env = env'
    rows.push("     ")
    rows.push(" 123 ")
    rows.push(" 456 ")
    rows.push(" 789 ")
    rows.push("     ")
    location = (2, 2)

  new make2(env': Env) =>
    env = env'
    rows.push("       ")
    rows.push("   1   ")
    rows.push("  234  ")
    rows.push(" 56789 ")
    rows.push("  ABC  ")
    rows.push("   D   ")
    rows.push("       ")
    location = (3, 1)

  fun ref loc(): String =>
    try
      rows(location._1).substring(location._2.isize(), location._2.isize() + 1)
    else
      "err"
    end

  fun ref parse(input: String): Array[Moves] ? =>
    let result = Array[Moves]
    for r in input.runes() do
      result.push(
        match r
        | 'U' => MoveU
        | 'D' => MoveD
        | 'L' => MoveL
        | 'R' => MoveR
        | '\n' => ENDOFLINE
        else
          error
        end
      )
    end
    result

  fun ref apply(moves: String) ? =>
    _apply(parse(moves))

  fun ref _apply(moves: Array[Moves]) =>
    for m in moves.values() do
      // env.out.write("at-").print(at.string())
      move(m)
    end

  fun peek(at: (USize, USize)): String =>
    try
      rows(at._1).substring(at._2.isize(), at._2.isize() + 1)
    else
      "error"
    end

  fun ref move(m: Moves): KeyPad =>
    match m
    | let mover: HasMove val if peek(mover.move(location)) != " " =>
      location = mover.move(location)
    | ENDOFLINE => env.out.write(loc())
    end
    // env.out.write("->").print(loc())
    this
