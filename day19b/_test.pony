use "ponytest"
use "collections"
use "debug"
use "time"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    // test(_TestSample)
    // test(_TestPuzzle)
    test(_TestSample2)
    test(_TestPuzzle2)

class Elf
  let name: USize
  var gifts: USize = 1
  new create(name': USize) =>
    name = name'
  fun string(): String =>
    name.string() + "/" + gifts.string()

class WhiteEl
  let env: Env
  new create(env': Env) =>
    env = env'

  fun make_circle(n: USize): List[Elf] =>
    let circle = List[Elf]
    for i in Range(1, n + 1) do
      circle.push(Elf(i))
    end
    circle

  fun print_circle(circle: List[Elf]) =>
    env.out.print("--------------------")
    for v in circle.values() do
      env.out.print("Elf:" + v.string())
    end

  fun next(circle: List[Elf], here: ListNode[Elf]): ListNode[Elf] ? =>
    match here.next()
    | let n': ListNode[Elf] => n'
    else circle.head() end

  fun forward(circle: List[Elf], from: ListNode[Elf], dist: USize): ListNode[Elf] ? =>
    var result = from
    for i in Range(0, dist) do
      result = next(circle, result)
    end
    result

  fun take(circle: List[Elf], target: USize) =>
    try
      var n = circle.head()

      while n().gifts < target do
        let here = n
        n = next(circle, here)

        here().gifts = here().gifts + n().gifts
        let dead = n
        n = next(circle, dead)
        dead.remove()
      end
    else
      Debug.err("** Oops")
    end

  /*
  26583 is too low
  */
  fun take2(circle: List[Elf], target: USize) =>
    try
      let elves = Array[Elf]
      for i in Range(0, target) do
        elves.push(Elf(i + 1))
      end

      var lastReport: I64 = 0
      var cur: USize = 0
      while elves.size() > 1 do
        let nowSecs = Time.seconds()
        if (lastReport + 10) <= nowSecs then
          lastReport = nowSecs
          env.out.print("remain: " + elves.size().string())
        end

        let nxt = (cur + 1) % elves.size()
        let across = ((elves.size() / 2) + cur) % elves.size()
        Debug.out("dead: " + elves(across).string())
        elves.remove(across, 1)
        cur = nxt
      end

      env.out.print("win:" + elves(0).string())
    else
      Debug.err("** Oops")
    end

class iso _TestSample is UnitTest
  fun name(): String => "sample"
  fun apply(h: TestHelper) =>
    let white: WhiteEl ref = WhiteEl(h.env)
    let circle = white.make_circle(5)
    white.print_circle(circle)
    white.take(circle, 5)
    white.print_circle(circle)

class iso _TestSample2 is UnitTest
  fun name(): String => "sample2"
  fun apply(h: TestHelper) =>
    let white: WhiteEl ref = WhiteEl(h.env)
    let circle = white.make_circle(5)
    white.take2(circle, 5)

class iso _TestPuzzle is UnitTest
  fun name(): String => "puzzle"
  fun apply(h: TestHelper) =>
    let white: WhiteEl ref = WhiteEl(h.env)
    let size: USize = 3017957
    let circle = white.make_circle(size)
    white.take(circle, size)
    white.print_circle(circle)

class iso _TestPuzzle2 is UnitTest
  fun name(): String => "puzzle"
  fun apply(h: TestHelper) =>
    let white: WhiteEl ref = WhiteEl(h.env)
    let size: USize = 3017957
    let circle = white.make_circle(size)
    white.take2(circle, size)
