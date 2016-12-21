use "ponytest"
use "collections"
use "regex"
use "debug"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestBlacklist)

class Blacklist
  let list: Array[(U32, U32)] = Array[(U32, U32)]

  new create(lines: Array[String]) =>
    try
      let r = Regex("(\\d+)-(\\d+)")
      for line in lines.values() do
        let matched = r(line)
        var t1 = matched(1).read_int[U32]()._1
        var t2 = matched(2).read_int[U32]()._1
        list.push((t1, t2))
      end
    else
      Debug.err("err1")
    end

  fun print() =>
    for e in list.values() do
      Debug.out(e._1.string() + "-" + e._2.string())
    end

  fun search(): U32 =>
    for i in Range(0, U32.max_value().usize()) do
      var blocked = false
      for p in list.values() do
        if (p._1 <= i.u32()) and (i.u32() <= p._2) then
          blocked = true
          break
        end
      end
      if not blocked then
        return i.u32()
      end
    end
    -1

class iso _TestBlacklist is UnitTest
  fun name(): String => "blacklist"

  fun apply(h: TestHelper) =>
    let blacklist = Blacklist(INPUT.sample().split("\n"))
    // blacklist.print()
    h.assert_eq[U32](3, blacklist.search())
    let b2 = Blacklist(INPUT.puzzle().split("\n"))
    // b2.print()
    h.assert_eq[U32](0, b2.search())
