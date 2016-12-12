use "collections"

class Elevator
  let floor: USize
  let generators: Set[String]
  let microchips: Set[String]

  new create(
    floor': USize = 0,
    generators': Set[String] = Set[String],
    microchips': Set[String] = Set[String]
  ) =>
    floor = floor'
    generators = generators'
    microchips = microchips'

  fun string(): String =>
    (1 + floor).string()
