import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import internal/array

const integer_limit = 2_147_483_647

const default_data = ComplexityData(complexity: 0, from: One)

pub fn main() {
  { get_complexity(new_cache(), 79).0 }.array
  |> array.get(78)
  |> io.debug

  Nil
}

pub opaque type ComplexitiesCache {
  ComplexitiesCache(array: array.Array(ComplexityData), highest_computed: Int)
}

pub fn new_cache() -> ComplexitiesCache {
  let array =
    [0, 1]
    |> list.map(ComplexityData(_, One))
    |> array.from_list(default_data)
  ComplexitiesCache(array, 0)
}

type ComplexityData {
  ComplexityData(complexity: Int, from: Expression)
}

type Expression {
  Add(lhs: Expression, rhs: Expression)
  Multiply(lhs: Expression, rhs: Expression)
  Derived(from_complexity: Int)
  One
}

//todo: make this actually efficient
pub fn get_complexities_up_to(
  cache: ComplexitiesCache,
  integer: Int,
) -> #(ComplexitiesCache, List(Int)) {
  case integer <= cache.highest_computed {
    True -> {
      let list =
        array.to_list(cache.array)
        |> list.drop(1)
        |> list.take(integer)
        |> list.map(fn(x) { x.complexity })

      #(cache, list)
    }

    False -> {
      let assert Ok(new_cache) = extend_complexity_list(integer, cache)
      get_complexities_up_to(ComplexitiesCache(new_cache, integer), integer)
    }
  }
}

pub fn get_complexity(
  cache cache: ComplexitiesCache,
  of integer: Int,
) -> #(ComplexitiesCache, Int) {
  case array.get(cache.array, integer) {
    Ok(ComplexityData(complexity, _)) if integer <= cache.highest_computed -> #(
      cache,
      complexity,
    )

    _ -> {
      let assert Ok(new_cache) = extend_complexity_list(integer, cache)

      get_complexity(ComplexitiesCache(new_cache, integer), integer)
    }
  }
}

///Calculate the integer complexity of a positive integer
fn extend_complexity_list(
  max_integer: Int,
  cache: ComplexitiesCache,
) -> Result(array.Array(ComplexityData), Nil) {
  //ensure positive integers only
  use <- bool.guard(max_integer < 0, Error(Nil))

  // let complexity_upper_bound = fn(_) { 2_147_483_647 }
  // fn(integer) {
  //   float.round(float.floor({ 3.0 *. log(int.to_float(integer)) /. log(2.0) }))
  //   + 1
  // }

  let extension_start = cache.highest_computed
  let complexity_array = cache.array

  Ok(complexity_rec(
    int.max(2, extension_start + 1),
    max_integer,
    complexity_array,
  ))
}

fn complexity_rec(
  n: Int,
  max_integer: Int,
  complexity_array: array.Array(ComplexityData),
) -> array.Array(ComplexityData) {
  use <- bool.lazy_guard(n > max_integer, fn() { complexity_array })

  //usual best value
  //1 + complexity of (current integer - 1)
  let usual_best_value =
    array.get(complexity_array, n - 1)
    |> result.map(fn(x) { x.complexity })
    |> result.unwrap(integer_limit)
    |> int.add(1)

  let complexity_n =
    array.get(complexity_array, n)
    |> result.map(fn(x) { x.complexity })
    |> result.unwrap(integer_limit)

  let assert Ok(complexity) = case usual_best_value < complexity_n {
    True ->
      array.set(
        complexity_array,
        n,
        ComplexityData(usual_best_value, Add(One, Derived(n - 1))),
      )
    False -> Ok(complexity_array)
  }

  // computing kMax 
  let assert target =
    array.get(complexity, n - 1)
    |> result.map(fn(x) { x.complexity })
    |> result.unwrap(integer_limit)

  let t = calc_t(target / 2, target, n)

  let k_max = a000792(t)

  // testing the sums
  let complexity = sums(6, k_max, n, complexity)

  // testing the products
  let complexity =
    products(
      2,
      // float.round(
      //   float.floor(float.min(
      //     int.to_float(n),
      //     int.to_float(max_integer) /. int.to_float(n),
      //   )),
      // ),
      n,
      n,
      complexity,
    )

  complexity_rec(n + 1, max_integer, complexity)
}

fn sums(
  m: Int,
  max: Int,
  n: Int,
  complexity: array.Array(ComplexityData),
) -> array.Array(ComplexityData) {
  use <- bool.guard(m > max, complexity)

  let complexity_m =
    array.get(complexity, m)
    |> result.map(fn(x) { x.complexity })
    |> result.unwrap(integer_limit)

  let complexity_n =
    array.get(complexity, n)
    |> result.map(fn(x) { x.complexity })
    |> result.unwrap(integer_limit)

  let assert complexity_n_m =
    array.get(complexity, n - m)
    |> result.map(fn(x) { x.complexity })
    |> result.unwrap(integer_limit)

  let sum_value = complexity_m + complexity_n_m

  let assert Ok(updated_complexity) = case sum_value < complexity_n {
    True ->
      array.set(
        complexity,
        n,
        ComplexityData(sum_value, Add(Derived(m), Derived(n - m))),
      )
    False -> Ok(complexity)
  }

  sums(m + 1, max, n, updated_complexity)
}

fn products(
  k: Int,
  max: Int,
  n: Int,
  complexity: array.Array(ComplexityData),
) -> array.Array(ComplexityData) {
  use <- bool.guard(k > max, complexity)

  let complexity_k =
    array.get(complexity, k)
    |> result.map(fn(x) { x.complexity })
    |> result.unwrap(integer_limit)

  let complexity_n =
    array.get(complexity, n)
    |> result.map(fn(x) { x.complexity })
    |> result.unwrap(integer_limit)

  let complexity_k_n = array.get(complexity, k * n)

  let prod_value = complexity_k + complexity_n

  let assert Ok(updated_complexity) = case complexity_k_n {
    Error(_) ->
      array.set(
        complexity,
        k * n,
        ComplexityData(prod_value, Multiply(Derived(k), Derived(n))),
      )
    Ok(ComplexityData(k_n_value, _)) if prod_value < k_n_value ->
      array.set(
        complexity,
        k * n,
        ComplexityData(prod_value, Multiply(Derived(k), Derived(n))),
      )
    _ -> Ok(complexity)
  }

  products(k + 1, max, n, updated_complexity)
}

fn calc_t(t: Int, target: Int, index: Int) -> Int {
  case a000792(t) + a000792(target - t) < index {
    True -> calc_t(t - 1, target, index)
    False -> t
  }
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
