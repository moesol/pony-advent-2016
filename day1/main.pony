actor Main
  let env: Env

  new create(env': Env) =>
    env = env'
    env.out.print("hello")
    let city: CityMap = CityMap(env)
    env.out.print("city: " + city.string())
    let i1 = Instruction(RIGHT, 1)
    city.apply_move(i1)
    env.out.print("city: " + city.string())

    test_parse()
    test_example1()
    test_example2()
    test_example3()

    print_result_of("""
      R3, L2, L2, R4, L1, R2, R3, R4, L2, R4, L2, L5, L1, R5, R2, R2, L1, R4, R1, L5, L3, R4, R3, R1, L1, L5, L4, L2, R5, L3, L4, R3, R1, L3, R1, L3, R3, L4, R2, R5, L190, R2, L3, R47, R4, L3, R78, L1, R3, R190, R4, L3, R4, R2, R5, R3, R4, R3, L1, L4, R3, L4, R1, L4, L5, R3, L3, L4, R1, R2, L4, L3, R3, R3, L2, L5, R1, L4, L1, R5, L5, R1, R5, L4, R2, L2, R1, L5, L4, R4, R4, R3, R2, R3, L1, R4, R5, L2, L5, L4, L1, R4, L4, R4, L4, R1, R5, L1, R1, L5, R5, R1, R1, L3, L1, R4, L1, L4, L4, L3, R1, R4, R1, R1, R2, L5, L2, R4, L1, R3, L5, L2, R5, L4, R5, L5, R3, R4, L3, L3, L2, R2, L5, L5, R3, R4, R3, R4, R3, R1
      """, "puzzle input: ")

    test_part_two()

  fun print_result_of(input: String, msg: String) =>
    let parser: Parser ref = Parser
    try
      let instructions = parser.parse(input)
      let city: CityMap ref = CityMap(env)
      city.apply_moves(instructions)
      env.out.print(msg + city.string())
      // for h in city.history.values() do
      //   env.out.write("  (")
      //     .write(h._1.string()).write(",")
      //     .write(h._2.string()).print(")")
      // end
    else
      print_parser_error(parser)
    end

  fun print_parser_error(parser: Parser) =>
    env.out.print("test_parse failed at "
      + parser.loc.line().string())
    env.out.print("test_parse messsage "
      + parser.err)

  fun test_parse() =>
    let parser: Parser ref = Parser
    try
      let instructions = parser.parse("R2, L3")
      for i in instructions.values() do
        env.out.print("i: " + i.string())
      end
    else
      print_parser_error(parser)
    end

  fun test_example1() =>
    print_result_of("R2, L3", "example1: ")

  fun test_example2() =>
    print_result_of("R2, R2, R2", "example2: ")

  fun test_example3() =>
    print_result_of("R5, L5, R5, R3", "example3: ")

  fun test_part_two() =>
    print_result_of("R8, R4, R4, R8", "part two: ")

type TURN is (LEFT|RIGHT)
type FACING is (NORTH|EAST|SOUTH|WEST)

class Tuples
  fun string(t: (I64, I64)): String val =>
    String.append("(")
      .append(t._1.string()).append(",")
      .append(t._2.string()).append(")").clone()

primitive RIGHT
  fun string(): String => "R"
primitive LEFT
  fun string(): String => "L"

primitive NORTH
  fun string(): String => "N"
  fun turn(direction: TURN): FACING ? =>
    match direction
    | LEFT => WEST
    | RIGHT => EAST
    else
      error
    end
  fun compute_offset(instruction: Instruction): (I64, I64) =>
    (0, instruction.distance)
  fun increment(): (I64, I64) =>
    (0, 1)

primitive EAST
  fun string(): String => "E"
  fun turn(direction: TURN): FACING ? =>
    match direction
    | LEFT => NORTH
    | RIGHT => SOUTH
    else
      error
    end
  fun compute_offset(instruction: Instruction): (I64, I64) =>
    (instruction.distance, 0)
  fun increment(): (I64, I64) =>
    (1, 0)

primitive SOUTH
  fun string(): String => "S"
  fun turn(direction: TURN): FACING ? =>
    match direction
    | LEFT => EAST
    | RIGHT => WEST
    else
      error
    end
  fun compute_offset(instruction: Instruction): (I64, I64) =>
    (0, -instruction.distance)
  fun increment(): (I64, I64) =>
    (0, -1)

primitive WEST
  fun string(): String => "W"
  fun turn(direction: TURN): FACING ? =>
    match direction
    | LEFT => SOUTH
    | RIGHT => NORTH
    else
      error
    end
  fun compute_offset(instruction: Instruction): (I64, I64) =>
    (-instruction.distance, 0)
  fun increment(): (I64, I64) =>
    (-1, 0)

class Instruction
  let direction: TURN
  let distance: I64
  new create(direction': TURN, distance': I64) =>
    direction = direction'
    distance = distance'
  fun string(): String =>
    direction.string() + distance.string()

class CityMap
  let env: Env
  let tuples: Tuples = Tuples
  var facing: FACING = NORTH
  // (x, y)
  var location: (I64, I64) = (0, 0)
  let history: Array[(I64, I64)] = Array[(I64, I64)]
  var firstRevisit: (None|(I64, I64)) = None

  new create(env': Env) =>
    env = env'

  fun ref apply_moves(instructions: Array[Instruction]) =>
    for i in instructions.values() do
      apply_move(i)
    end

  fun ref apply_move(instruction: Instruction) =>
    try
      facing = facing.turn(instruction.direction)
      let offset: (I64, I64) = facing.compute_offset(instruction)
      let increment: (I64, I64) = facing.increment()
      let target = (location._1 + offset._1, location._2 + offset._2)
      while (location._1 != target._1) or (location._2 != target._2) do
        location = (location._1 + increment._1, location._2 + increment._2)
        match firstRevisit
        | None =>
          check_revisit()
          history.push(location)
        end
      end
    end

  fun ref check_revisit() =>
    if (history.contains(location,
      { (l:(I64,I64), r:(I64, I64)): Bool =>
        (l._1 == r._1) and (l._2 == r._2) }))
    then
      firstRevisit = location
    end

  fun blocks_away(): U64 =>
    location._1.abs() + location._2.abs()

  fun revisit_blocks_away(): U64 =>
    match firstRevisit
    | (let t1: I64, let t2: I64) =>
      t1.abs() + t2.abs()
    else
      0
    end

  fun revisit(): String =>
    match firstRevisit
    | (let t1:I64, let t2:I64) =>
      "(" + t1.string() + "," + t2.string() + ")"
    else "None"
    end
  fun string(): String =>
    "city: facing: " + facing.string()
      + " E: " + location._1.string()
      + " N: " + location._2.string()
      + " blocks away: " + blocks_away().string()
      + " revisit: " + revisit()
      + " revisit blocks away: " + revisit_blocks_away().string()

class Parser
  var err: String = ""
  var loc: SourceLoc = __loc

  fun ref parse(input: String val): Array[Instruction] ? =>
    let parts: Array[String] = input.split(",")
    let r: Array[Instruction] = Array[Instruction]
    for str in parts.values() do
      r.push(parse_entry(str))
    end
    r

  fun ref parse_entry(str: String): Instruction ? =>
    let str' = str.clone().strip()
    let dir': String val = str'.substring(0, 1)
    let direction: TURN = match dir'
    | "R" => RIGHT
    | "L" => LEFT
    else
      err = "Unknown direction: \"" + str' + "\"(" + dir' + ")"
      loc = __loc
      error
    end
    try
      let distance: I64 = str'.read_int[I64](1)._1
      Instruction(direction, distance)
    else
      err = "read_int failed: " + str'
      loc = __loc
      error
    end
