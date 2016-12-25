use "ponytest"
use "collections"
use "debug"
use "time"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(_TestSample)
    // test(_TestPuzzle)
    // test(_TestSample2)
    // test(_TestPuzzle2)

class Traps
  let rows: Array[String] = Array[String]
  new create(init: String, total_rows: USize) =>
    var prior: String ref = init.clone()
    rows.push(init)
    for i in Range(0, total_rows - 1) do
      prior = add_row(prior, init.size())
      rows.push(prior.clone())
    end

  fun print_floor() =>
    for r in rows.values() do
      Debug.out(r)
    end

  fun count_safe(): USize =>
    var n: USize = 0
    for r in rows.values() do
      for c in r.values() do
        if c == '.' then
          n = n + 1
        end
      end
    end
    n

  fun add_row(floor: String ref, width: USize): String ref =>
    let result: String ref = String
    for i in Range(0, width) do
      let left = try floor(i - 1) else '.' end
      let center = try floor(i) else '.' end
      let right = try floor(i + 1) else '.' end
      let tile: U8 = match (left, center, right)
      | ('^', '^', '.') => '^'
      | ('.', '^', '^') => '^'
      | ('^', '.', '.') => '^'
      | ('.', '.', '^') => '^'
      else
        '.'
      end
      result.push(tile)
    end
    result

class iso _TestSample is UnitTest
  fun name(): String => "sample"
  fun apply(h: TestHelper) =>
    let floor: String ref = String
    let traps: Traps ref = Traps(".", 1)
    floor.append("..^^.")
    Debug.out(floor)
    var r = floor
    for i in Range(0, 4) do
      r = traps.add_row(r, floor.size())
      Debug.out(r)
    end

    r = String.append(".^^.^.^^^^")
    Debug.out(r)
    for i in Range(0, 9) do
      r = traps.add_row(r, r.size())
      Debug.out(r)
    end

    Traps("..^^.", 3).print_floor()
    Debug.out("---------------")
    Traps(".^^.^.^^^^", 10).print_floor()

    h.assert_eq[USize](6, Traps("..^^.", 3).count_safe())
    h.assert_eq[USize](38, Traps(".^^.^.^^^^", 10).count_safe())

    h.assert_eq[USize](2016,
      Traps(
        "^..^^.^^^..^^.^...^^^^^....^.^..^^^.^.^.^^...^.^.^.^.^^.....^.^^.^.^.^.^.^.^^..^^^^^...^.....^....^.",
        40
      ).count_safe()
    )
    h.assert_eq[USize](19998750,
      Traps(
        "^..^^.^^^..^^.^...^^^^^....^.^..^^^.^.^.^^...^.^.^.^.^^.....^.^^.^.^.^.^.^.^^..^^^^^...^.....^....^.",
        400000
      ).count_safe()
    )

class iso _TestSample2 is UnitTest
  fun name(): String => "sample2"
  fun apply(h: TestHelper) =>
    None

class iso _TestPuzzle is UnitTest
  fun name(): String => "puzzle"
  fun apply(h: TestHelper) =>
    None

class iso _TestPuzzle2 is UnitTest
  fun name(): String => "puzzle"
  fun apply(h: TestHelper) =>
    None
