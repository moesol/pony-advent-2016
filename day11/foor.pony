use "collections"
use "debug"

class Floor
  let floor: USize
  let _generators: Set[String]
  let _microchips: Set[String]
  let gen_mic: String ref

  new create(
    floor': USize = 0,
    generators': Set[String] = Set[String],
    microchips': Set[String] = Set[String]
  ) =>
    floor = floor'
    _generators = generators'
    _microchips = microchips'
    gen_mic = "..........".clone()
    build()

  fun ref build(): Floor =>
    gen_mic.clear().append("..........")
    try
      for g' in _generators.values() do
        let idx: USize = match g'
        | "promethium" => 0
        | "cobalt" => 1
        | "curium" => 2
        | "ruthenium" => 3
        else
          4
        end
        gen_mic(2 * idx) = 'G'
      end
      for m' in _microchips.values() do
        let idx: USize = match m'
        | "promethium" => 0
        | "cobalt" => 1
        | "curium" => 2
        | "ruthenium" => 3
        else
          4
        end
        gen_mic((2 * idx) + 1) = 'M'
      end
    else
      Debug.err("** Fatal")
    end
    this

  fun clone(): Floor =>
    Floor(floor, _generators.clone(), _microchips.clone())

  fun ref g(g': String): Floor =>
    _generators.set(g')
    build()
    this

  fun ref rm_g(g': String): Floor =>
    _generators.unset(g')
    build()
    this

  fun ref m(m': String): Floor =>
    _microchips.set(m')
    build()
    this

  fun generators(): Set[String] box =>
    _generators
  fun microchips(): Set[String] box =>
    _microchips

  fun ref rm_m(m': String): Floor =>
    _microchips.unset(m')
    build()
    this

  fun is_empty(): Bool =>
    (_generators.size() == 0) and (_microchips.size() == 0)

  fun string(): String =>
    let gm: String val = gen_mic.clone()
    recover val
      let r: String ref = String
      r.append("|").append((1+floor).string()).append("|").append(gm)
      r.clone()
    end
