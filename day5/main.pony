use "crypto"
use "format"

actor Main
  let env: Env

  new create(env': Env) =>
    env = env'

    let input = "cxdnnyjw"

    crack("abc")
    crack(input)

  fun crack(input: String) =>
    var index: U64 = 0
    let result: String ref = String
    let result': String ref = "        ".clone()

    env.out.print("hashing: " + input)
    while (index < 100_000_000)
      and ((result.size() < 8) or (result'.contains(" ")))
    do
      let attempt = input + index.string()
      let md5 = Digest.md5()
      try
        md5.append(attempt)
        let sum = md5.final()
        match (sum(0), sum(1), sum(2))
        | (0, 0, let x: U8) if (x and 0xF0) == 0=>
          result.append(ToHexString(sum).substring(5, 6))
          update_crack(result', sum)
          env.out.print("result: " + result)
          env.out.print("result': " + result')
        end
      end
      index = index + 1
    end

  fun update_crack(result': String ref, sum: Array[U8] val) =>
    try
      let left = (sum(2) and 0xF).usize()
      if result'(left) == ' ' then
        result'(left) = ToHexString(sum).substring(6, 7)(0)
      else
        env.out.print("already filled: " + left.string())
      end
    end
