use "collections"
use "debug"
use "regex"

actor Main
  let env: Env
  new create(env': Env) =>
    env = env'

    simulate_instructions((5, 2), INPUT.sample().split("\n"))
    simulate_instructions((61, 17), INPUT.puzzle().split("\n"))

  fun simulate_instructions(watch: (U32, U32), lines: Array[String]) =>
    let router = Router(watch)
    for l in lines.values() do
      try
        let i = parse(l)
        match i
        | let take: Take =>
          router.route(take.bot, take)
        | let give: Give =>
          router.route(give.bot, give)
        else
          env.err.print("** Bad instruction:")
        end
      else
        env.err.print("** Failed: " + l)
      end
    end

  fun parse(line: String): Instruction ? =>
    let take =  Regex("value (\\d+) goes to bot (\\d+)")
    let gives = Regex("bot (\\d+) gives low to (bot|output) (\\d+) and high to (bot|output) (\\d+)")
    if take == line then
      let matched = take(line)
      let value = matched(1).read_int[U32]()._1
      let bot = matched(2).read_int[U32]()._1
      let r: Take val = Take(bot, value)
      return r
    end
    if gives == line then
      let matched = gives(line)
      let bot = matched(1).read_int[U32]()._1
      let lowTo: String val = matched(2)
      let lowValue = matched(3).read_int[U32]()._1
      let highTo: String val = matched(4)
      let highValue = matched(5).read_int[U32]()._1
      let r: Give val = Give(
        bot,
        lowTo, lowValue,
        highTo, highValue
      )
      return r
    end
    env.err.write("** No match: ").print(line)
    error

type Instruction is (Give | Take )

class val Give
  let bot: U32
  let lowTo: String
  let lowValue: U32
  let highTo: String
  let highValue: U32
  new val create(
    bot': U32,
    lowTo': String, lowValue': U32,
    highTo': String, highValue': U32
  ) =>
    bot = bot'
    lowTo = lowTo'
    lowValue = lowValue'
    highTo = highTo'
    highValue = highValue'
  fun val string(): String =>
    recover
      String.append("bot ").append(bot.string()).append(" gives low to ")
        .append(lowTo).append(" ").append(lowValue.string()).append(" and high to ")
        .append(highTo).append(" ").append(highValue.string())
    end

class val Take
  let bot: U32
  let value: U32
  new val create(bot': U32, value': U32) =>
    bot = bot'
    value = value'
  fun val string(): String =>
    recover
      String.append("value ").append(value.string())
        .append(" goes to bot ").append(bot.string())
    end

actor Router
  let bots: Map[U32, Bot tag]
  let watch: (U32, U32)
  new create(watch': (U32, U32)) =>
    watch = watch'
    bots = Map[U32, Bot tag]

  be route(bot: U32, instr: Instruction) =>
    try
      bots(bot).process(instr)
    else
      let b = Bot(bot, this, watch)
      bots(bot) = b
      b.process(instr)
    end

  be output(output': U32, value: U32) =>
    Debug.out(
      String
        .append("output(").append(output'.string())
        .append(")=").append(value.string())
    )

actor Bot
  let bot: U32
  let router: Router tag
  let watch: (U32, U32)
  let values: Array[U32] = Array[U32]
  var give: (Give|None) = None

  new create(bot': U32, router': Router tag, watch': (U32, U32)) =>
    bot = bot'
    router = router'
    watch = watch'

  be process(instr: Instruction) =>
    Debug.out(instr.string())
    match instr
    | let take: Take =>
      if values.size() == 2 then
        Debug.err("** Got three values before Give. Losing value!")
      end
      values.push(take.value)
      if values.size() == 2 then
        ready_to_give()
      end
    | let give': Give =>
      give = give'
      if values.size() == 2 then
        ready_to_give()
      end
    end

  fun ref ready_to_give() =>
    match give
    | let give': Give =>
      try
        let low = values(0).min(values(1))
        let hi = values(0).max(values(1))
        match watch
        | (low, hi) =>
          Debug.out("-- Bot: " + bot.string())
        | (hi, low) =>
          Debug.out("-- Bot: " + bot.string())
        end
        match (give'.lowTo, give'.highTo)
        | ("output", "output") =>
          router.output(give'.lowValue, low)
          router.output(give'.highValue, hi)
        | ("bot", "output") =>
          router.route(give'.lowValue, Take(give'.lowValue, low))
          router.output(give'.highValue, hi)
        | ("output", "bot") =>
          router.output(give'.lowValue, low)
          router.route(give'.highValue, Take(give'.highValue, hi))
        | ("bot", "bot") =>
          router.route(give'.lowValue, Take(give'.lowValue, low))
          router.route(give'.highValue, Take(give'.highValue, hi))
        end
        values.clear()
      end
    end
