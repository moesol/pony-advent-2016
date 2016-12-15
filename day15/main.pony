use "collections"

class Disk
  let start: USize
  let positions: USize
  new create(start': USize, positions': USize) =>
    start = start'
    positions = positions'

  fun at_time(t: USize): USize =>
    (start + t) % positions

  fun string(d: USize): String =>
    String()
      .append("Disc #").append(d.string())
      .append(" has ").append(positions.string()).append(" positions;")
      .append(" at time=0, it is at position ").append(start.string()).append(".")
      .clone()

actor Main
  let env: Env
  new create(env': Env) =>
    env = env'

    let z = Disk(4, 5).at_time(6)
    let x = Disk(1, 2).at_time(7)
    env.out.print("z: " + z.string())
    env.out.print("x: " + x.string())

    let disks = Array[Disk]
    disks.push(Disk(1, 13))
    disks.push(Disk(10, 19))
    disks.push(Disk(2, 3))
    disks.push(Disk(1, 7))
    disks.push(Disk(3, 5))
    disks.push(Disk(5, 17))

    try
      for i in Range(0, disks.size()) do
        env.out.print(disks(i).string(i + 1))
      end

      for time in Range(0, 1_000_000) do
        var bounce = false
        for d in Range(0, disks.size()) do
          let dt = time + d + 1
          let pt = disks(d).at_time(dt)
          if pt != 0 then
            bounce = true
            continue
          end
        end
        if bounce == false then
          env.out.print("win@" + time.string())
        end
      end
    end

/*
Disc #1 has 13 positions; at time=0, it is at position 1.
Disc #2 has 19 positions; at time=0, it is at position 10.
Disc #3 has 3 positions; at time=0, it is at position 2.
Disc #4 has 7 positions; at time=0, it is at position 1.
Disc #5 has 5 positions; at time=0, it is at position 3.
Disc #6 has 17 positions; at time=0, it is at position 5.
*/
