use "ponytest"
use "debug"
use "collections"
use "crypto"
use "time"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None

fun tag tests(test: PonyTest) =>
  test(_TestCollector1)
  test(_TestGenerator)
  test(_TestStretch)
  // test(_TestSample)
  // test(_TestSampleActors)
  // test(_TestPuzzleActors)
  test(_TestPuzzle2Actors)
  // test(_TestPuzzle2)

class iso _TestStretch is UnitTest
  fun name(): String => "stretch"
  fun apply(h: TestHelper) =>
    h.assert_eq[String]("577571be4de9dcce85a041ba0410f29f", Generator("abc").apply(0))
    h.assert_eq[String]("a107ff634856bb300138cac6568c0f24", Generator("abc").stretch(0))

class iso _TestPuzzle2 is UnitTest
  fun name(): String => "puzzle2/iter"
  fun apply(h: TestHelper) =>
    let seed = "zpqevtbw"
    let col = CollectorActor(h.env)
    let gen = Generator(seed)
    for i in Range(0, 10_000_000) do
      col.collect(i, gen.stretch(i))
    end

class iso _TestPuzzle2Actors is UnitTest
  fun name(): String => "puzzle2/actors"

  fun apply(h: TestHelper) =>
    let seed = "zpqevtbw"
    let col = CollectorActor(h.env)
    let gens = Array[GeneratorActor]
    for i in Range(0, 1) do
      gens.push(GeneratorActor(seed))
    end
    for i in Range(0, 10_000_000) do
      try
        // Debug.out("i " + i.string())
        let t = i % gens.size()
        gens(t).stretch(i, col)
      end
    end

class iso _TestPuzzleActors is UnitTest
  fun name(): String => "sample/actors"

  fun apply(h: TestHelper) =>
    let seed = "zpqevtbw"
    let col = CollectorActor(h.env)
    let gens = Array[GeneratorActor]
    for i in Range(0, 8) do
      gens.push(GeneratorActor(seed))
    end
    for i in Range(0, 10_000_000) do
      try
        // Debug.out("i " + i.string())
        let t = i % gens.size()
        gens(t).generate(i, col)
      end
    end

class iso _TestSampleActors is UnitTest
  fun name(): String => "sample/actors"

  fun apply(h: TestHelper) =>
    let seed = "abc"
    let col = CollectorActor(h.env)
    let gens = Array[GeneratorActor]
    for i in Range(0, 8) do
      gens.push(GeneratorActor(seed))
    end
    for i in Range(0, 23728) do
      try
        // Debug.out("i " + i.string())
        let t = i % gens.size()
        gens(t).generate(i, col)
      end
    end

class iso _TestSample is UnitTest
  fun name(): String => "sample"

  fun apply(h: TestHelper) =>
    let col = Collector(h.env)
    let gen = Generator("abc")
    for i in Range(0, 1040) do
      col._collect(i, gen(i))
    end
    h.assert_eq[USize](1, col.keys_found)
    h.assert_eq[USize](39, col.max_key)

    for i in Range(817, 23728) do
      col._collect(i, gen(i))
    end
    h.assert_eq[USize](64, col.keys_found)
    h.assert_eq[USize](22728, col.max_key)

class iso _TestGenerator is UnitTest
  fun name(): String => "generator"
  fun apply(h: TestHelper) =>
    h.assert_eq[String]("0034e0923cc38887a57bd7b1d4f953df", Generator("abc")(18))

class iso _TestCollector1 is UnitTest
  fun name(): String => "collector1"

  fun apply(h: TestHelper) =>
    let col = Collector(h.env)

    col._collect(0, "no")
    h.assert_eq[USize](1, col.want)

    col._collect(5, "fffff")
    h.assert_eq[USize](1, col.want)

    col._collect(1, "abfffc")
    h.assert_eq[USize](1, col.want)
    h.assert_eq[USize](0, col.keys_found)
    h.assert_eq[USize](0, col.max_key)

    col._collect(2, "xx")
    col._collect(3, "yyy")
    col._collect(4, "zz")
    h.assert_eq[USize](3, col.want)
    h.assert_eq[USize](1, col.keys_found)
    h.assert_eq[USize](1, col.max_key)

    col._collect(6, "asdfyyyyy134")
    h.assert_eq[USize](5, col.want)
    h.assert_eq[USize](2, col.keys_found)
    h.assert_eq[USize](3, col.max_key)

actor GeneratorActor
  let gen: Generator

  new create(seed': String) =>
    gen = Generator(seed')
  be generate(index: USize, col: CollectorActor) =>
    col.collect(index, gen(index))
  be stretch(index: USize, col: CollectorActor) =>
    col.collect(index, gen.stretch(index))

actor CollectorActor
  let col: Collector

  new create(env': Env) =>
    col = Collector(env')

  be collect(index: USize, hash: String) =>
    col._collect(index, hash)

class Generator
  let seed: String
  new create(seed': String) =>
    seed = seed'

  fun apply(index: USize): String =>
    let attempt = seed + index.string()
    _compute(attempt)

  fun _compute(attempt: String): String =>
    let md5 = Digest.md5()
    try
      md5.append(attempt)
      let sum = md5.final()
      ToHexString(sum)
    else
      Debug.err("**")
      "ERROR"
    end

  fun stretch(index: USize): String =>
    let attempt = seed + index.string()
    _stretch(_compute(attempt))

  fun _stretch(old: String): String =>
    var cur = old
    for i in Range(0, 2016) do
      cur = _compute(cur)
    end
    cur

class Collector
  let env: Env
  let results: Array[(None|String)] = Array[(None|String)].init(None, 10_000_000)
  var want: USize = 0
  var keys_found: USize = 0
  var max_key: USize = 0
  var lastReport: I64 = 0

  new create(env': Env) =>
    env = env'

  fun ref _collect(index: USize, hash: String) =>
    try

      let nowSecs = Time.seconds()
      if (lastReport + 10) <= nowSecs then
        lastReport = nowSecs
        env.out.print("want: " + want.string())
        env.out.print("size: " + index.string())
      end

      results(index) = hash
      while search_for_key() do
        results(want) = None
        want = want + 1
        if keys_found == 64 then
          env.out.print("--64--" + max_key.string())
        end
      end
    end

  fun ref search_for_key():Bool =>
    try
      match results(want)
      | let h: String =>
        return search_for_three(h)
      end
    end
    false

  fun ref search_for_three(h: String): Bool =>
    for i in Range(2, h.size()) do
      try
        let a = h(i - 2)
        let b = h(i - 1)
        let c = h(i)

        if (a == b) and (b == c) then
          // Debug.out("3 was " + h + "@" + want.string())
          return search_for_five(a)
        end
      else
        Debug.err("**")
      end
    end
    true // skip on

  fun ref search_for_five(char: U8): Bool =>
    for i in Range(want + 1, want + 1 + 1000) do
      try
        match results(i)
        | let h: String =>
          if is_key(char, h) then
            keys_found = keys_found + 1
            max_key = max_key.max(want)
            env.out.print("5 was " + h + "#" + keys_found.string())
            // Debug.out("5 was " + h + "@" + i.string())
            return true
          end
        else
          return false // still waiting for some hashes
        end
      end
    end
    true // no key found

  fun ref is_key(char: U8, h: String): Bool =>
    for i in Range(4, h.size()) do
      try
        let a = h(i - 4)
        let b = h(i - 3)
        let c = h(i - 2)
        let d = h(i - 1)
        let e = h(i)
        match (a, b, c, d, e)
        | (char, char, char, char, char) =>
          return true
        end
      end
    end
    false
