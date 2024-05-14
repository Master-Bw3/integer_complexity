import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam_community/maths/elementary.{natural_logarithm}
import internal/array

pub fn main() {
  complexity(2_000_000)
  |> io.debug
}

///Calculate the integer complexity of a positive integer
pub fn complexity(n_max: Int) -> Result(List(Int), Nil) {
  //ensure positive integers only
  use <- bool.guard(n_max < 0, Error(Nil))

  let c_max =
    float.round(float.floor({ 3.0 *. log(int.to_float(n_max)) /. log(2.0) }))
    + 1

  let assert Ok(compl) =
    list.range(0, n_max)
    |> list.map(fn(_) { c_max })
    |> array.from_list(c_max)
    |> array.set(1, 1)

  Ok(complexity_rec(2, n_max, compl))
}

fn complexity_rec(n: Int, n_max: Int, compl: array.Array(Int)) -> List(Int) {
  use <- bool.lazy_guard(n > n_max, fn() { array.to_list(compl) })

  //usual best value
  let assert Ok(a) =
    array.get(compl, n - 1)
    |> result.map(fn(x) { x + 1 })

  let assert Ok(compl_n) = array.get(compl, n)
  let assert Ok(compl) = case a < compl_n {
    True -> array.set(compl, n, a)
    False -> Ok(compl)
  }

  // computing kMax 
  let assert Ok(target) = array.get(compl, n - 1)
  let t = calc_t(target / 2, target, n)

  let k_max = a000792(t)

  // testing the sums
  let compl = sums(6, k_max, n, compl)

  // testing the products
  let compl =
    products(
      2,
      float.round(
        float.floor(float.min(
          int.to_float(n),
          int.to_float(n_max) /. int.to_float(n),
        )),
      ),
      n,
      compl,
    )

  complexity_rec(n + 1, n_max, compl)
}

fn sums(m: Int, max: Int, n: Int, compl: array.Array(Int)) -> array.Array(Int) {
  use <- bool.guard(m > max, compl)

  let assert Ok(compl_m) = array.get(compl, m)
  let assert Ok(compl_n) = array.get(compl, n)
  let assert Ok(compl_n_m) = array.get(compl, n - m)

  let sum_value = compl_m + compl_n_m

  let assert Ok(updated_compl) = case sum_value < compl_n {
    True -> array.set(compl, n, sum_value)
    False -> Ok(compl)
  }

  sums(m + 1, max, n, updated_compl)
}

fn products(
  k: Int,
  max: Int,
  n: Int,
  compl: array.Array(Int),
) -> array.Array(Int) {
  use <- bool.guard(k > max, compl)

  let assert Ok(compl_k) = array.get(compl, k)
  let assert Ok(compl_n) = array.get(compl, n)
  let assert Ok(compl_k_n) = array.get(compl, k * n)

  let prod_value = compl_k + compl_n

  let assert Ok(updated_compl) = case prod_value < compl_k_n {
    True -> array.set(compl, k * n, prod_value)
    False -> Ok(compl)
  }

  products(k + 1, max, n, updated_compl)
}

fn calc_t(t: Int, target: Int, index: Int) -> Int {
  case a000792(t) + a000792(target - t) < index {
    True -> calc_t(t - 1, target, index)
    False -> t
  }
}

fn log(n: Float) -> Float {
  let assert Ok(result) = natural_logarithm(n)

  result
}

@internal
pub fn a000792(n: Int) -> Int {
  a000792_rec(n, 1)
}

fn a000792_rec(n: Int, result: Int) -> Int {
  case n >= 5 || n == 3 {
    True -> a000792_rec(n - 3, result * 3)
    False -> int.bitwise_shift_left(result, n / 2)
  }
}

@internal
pub fn is_prime(n: Int) -> Bool {
  use <- bool.guard(n == 2, True)
  use <- bool.guard(n <= 1, False)

  is_prime_rec(n, 2)
}

fn is_prime_rec(n: Int, divisor: Int) -> Bool {
  use <- bool.guard(divisor > n / 2, True)

  case n % divisor {
    0 -> False
    _ -> is_prime_rec(n, divisor + 1)
  }
}
