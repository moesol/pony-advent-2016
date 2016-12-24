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
  fun make_circle(n: USize): List[Elf] =>
    let circle = List[Elf]
    for i in Range(1, n + 1) do
      circle.push(Elf(i))
    end
    circle

  fun print_circle(circle: List[Elf]) =>
    Debug.out("--------------------")
    for v in circle.values() do
      Debug.out("Elf:" + v.string())
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

  fun take2(circle: List[Elf], target: USize) =>
    try
      var lastReport: I64 = 0
      var n = circle.head()
      var remainingElves = target

      while n().gifts < target do
        let nowSecs = Time.seconds()
        if (lastReport + 10) <= nowSecs then
          lastReport = nowSecs
          Debug.out("n:" + n().string() + " size:" + remainingElves.string())
        end
        let here = n
        n = next(circle, here)

        let dloser = remainingElves / 2
        let nloser = forward(circle, here, dloser)

        here().gifts = here().gifts + nloser().gifts
        if n is nloser then
          n = next(circle, n)
        end
        nloser.remove()
        remainingElves = remainingElves - 1
      end
    else
      Debug.err("** Oops")
    end

class iso _TestSample is UnitTest
  fun name(): String => "sample"
  fun apply(h: TestHelper) =>
    let white: WhiteEl ref = WhiteEl
    let circle = white.make_circle(5)
    white.print_circle(circle)
    white.take(circle, 5)
    white.print_circle(circle)

class iso _TestSample2 is UnitTest
  fun name(): String => "sample2"
  fun apply(h: TestHelper) =>
    let white: WhiteEl ref = WhiteEl
    let circle = white.make_circle(5)
    white.print_circle(circle)
    white.take2(circle, 5)
    white.print_circle(circle)

class iso _TestPuzzle is UnitTest
  fun name(): String => "puzzle"
  fun apply(h: TestHelper) =>
    let white: WhiteEl ref = WhiteEl
    let size: USize = 3017957
    let circle = white.make_circle(size)
    white.take(circle, size)
    white.print_circle(circle)

class iso _TestPuzzle2 is UnitTest
  fun name(): String => "puzzle"
  fun apply(h: TestHelper) =>
    let white: WhiteEl ref = WhiteEl
    let size: USize = 3017957
    let circle = white.make_circle(size)
    white.take2(circle, size)
    white.print_circle(circle)
