use "ponytest"
use "collections"
use "regex"
use "debug"
use "time"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestLowest)

actor Router
  let env: Env
  let workers: Array[Worker]
  var next: USize = 0
  var count: USize = 0
  new create(env': Env, asm: String) =>
    env = env'
    workers = Array[Worker]
    for i in Range(0, 6) do
      workers.push(Worker(env', asm, this))
    end

  be begin() =>
    while count < 1000 do
      try
        workers(next % workers.size()).check(next.i64())
      end
      next = next + 1
      count = count + 1
    end

  be completed(win: Bool) =>
    if win then
      return
    end
    try
      if (next % 1000) == 0 then
        env.out.print("trying: " + next.string())
      end
      workers(next % workers.size()).check(next.i64())
    end
    next = next + 1

actor Worker
  let env: Env
  let bunny: Assembly
  let instructions: Array[Inst]
  let router: Router

  new create(env': Env, asm': String, router': Router) =>
    env = env'
    bunny = Assembly
    instructions = bunny.parse(asm'.split("\n"))
    router = router'

  be check(value: I64) =>
    bunny.reset()
    bunny.registers("a") = value
    bunny.exec(instructions)
    if bunny.success then
      env.out.print("win: " + value.string())
    end
    router.completed(bunny.success)

class iso _TestLowest is UnitTest
  fun name(): String => "lowest"
  fun apply(h: TestHelper) =>
    let router = Router(h.env, INPUT.puzzle())
    router.begin()
