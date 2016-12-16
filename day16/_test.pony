use "ponytest"
use "collections"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestDragon1)
    test(_TestDragonCk1)
    test(_TestDragonFill)
    test(_TestPuzzle)

class DragonCurve
  fun apply(a: String): String =>
    let b = a.clone()
    let b' = b.reverse()
    try
      for i in Range(0, b'.size()) do
        match b'(i)
        | '0' => b'(i) = '1'
        | '1' => b'(i) = '0'
        end
      end
    end
    a + "0" + b'.clone()

  fun checksum(s: String, len: USize): String =>
    recover val
      let ck: String ref = String
      let w: String ref = (s.clone().truncate(len))
      for i in Range(0, w.size()/2) do
        try
          let l = w(i * 2)
          let r = w( (i * 2) + 1)
          match (l, r)
          | ('0', '0') => ck.append("1")
          | ('1', '1') => ck.append("1")
          | ('0', '1') => ck.append("0")
          | ('1', '0') => ck.append("0")
          end
        end
      end
      if (ck.size() % 2) == 0 then
        checksum(ck.clone(), len)
      else
        ck
      end
    end

  fun fill(seed: String, len: USize): String =>
    var f = seed
    while f.size() < len do
      f = apply(f)
    end
    checksum(f, len)

class iso _TestDragon1 is UnitTest
  fun name(): String => "dragon1"

  fun apply(h: TestHelper) =>
    let curve = DragonCurve

    h.assert_eq[String]("100", curve("1"))
    h.assert_eq[String]("001", curve("0"))
    h.assert_eq[String]("11111000000", curve("11111"))
    h.assert_eq[String]("1111000010100101011110000", curve("111100001010"))

class iso _TestDragonCk1 is UnitTest
  fun name(): String => "checksum"

  fun apply(h: TestHelper) =>
    let curve = DragonCurve

    h.assert_eq[String]("100", curve.checksum("110010110100", 12))

class iso _TestDragonFill is UnitTest
  fun name(): String => "fill"

  fun apply(h: TestHelper) =>
    let curve = DragonCurve

    h.assert_eq[String]("01100", curve.fill("10000", 20))

class iso _TestPuzzle is UnitTest
  fun name(): String => "puzzle"

  fun apply(h: TestHelper) =>
    let curve = DragonCurve

    h.env.out.print("--1--" + curve.fill("10001110011110000", 272))
    h.env.out.print("--2--" + curve.fill("10001110011110000", 35651584))
