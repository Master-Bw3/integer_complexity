//// This module contains functions for computing the complexity of an integer, 
//// and a corrisponding mathematical expression that uses only ones, addition, and multiplication to reach that integer.
//// testing the products

import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam_community/maths/arithmetics
import gleam_community/maths/piecewise
import integer_complexity/expression.{type Expression}
import integer_complexity/internal/array
import rememo/ets/memo

/// A cache used to store already-computed integer complexities. See: `integer_complexity.new_cache()`.
pub opaque type ComplexitiesCache {
  ComplexitiesCache(array: array.Array(ComplexityData), highest_computed: Int)
}

/// The complexity and a valid expression of an Integer.
pub opaque type ComplexityData {
  ComplexityData(complexity: Int, from: DerivedExpression)
}

/// An expression that can point to other integer complexity expressions.
type DerivedExpression {
  DerivedAdd(lhs: DerivedExpression, rhs: DerivedExpression)
  DerivedMultiply(lhs: DerivedExpression, rhs: DerivedExpression)
  Derived(from_complexity: Int)
  DerivedOne
}

/// A big numner.
const integer_limit = 2_147_483_647

const default_data = ComplexityData(complexity: 0, from: DerivedOne)

/// Create a new cache used to store computed integer complexities.
pub const new_cache = memo.create

/// Returns a list of integer complexities from 1 up to the specified integer. 
/// Returns `Error(Nil)` if the specified integer is less than 1.
pub fn get_complexities_up_to(cache, integer: Int) -> Result(List(Int), Nil) {
  use <- bool.guard(integer <= 0, Error(Nil))

  list.map(get_complexity_data_up_to(cache, integer), fn(x) { x.complexity })
  |> Ok()
}

/// Returns a list of integer complexity expressins (one per integer) from 1 up to the specified integer.
/// Returns `Error(Nil)` if the specified integer is less than 1.
pub fn get_expressions_up_to(
  cache,
  integer: Int,
) -> Result(List(Expression), Nil) {
  use <- bool.guard(integer <= 0, Error(Nil))

  list.map(get_complexity_data_up_to(cache, integer), fn(x) {
    construct_expression(cache, x.from)
  })
  |> Ok()
}

/// Returns the complexity data from 1 up to the specified integer.
fn get_complexity_data_up_to(cache, integer: Int) -> List(ComplexityData) {
  // case integer <= cache.highest_computed {
  //   True -> {
  //     let list =
  //       array.to_list(cache.array)
  //       |> list.drop(1)
  //       |> list.take(integer)

  //     #(cache, list)
  //   }

  //   False -> {
  //     let assert Ok(new_cache) = extend_complexity_list(integer, cache)
  //     get_complexity_data_up_to(ComplexitiesCache(new_cache, integer), integer)
  //   }
  // }

  list.range(1, integer)
  |> list.map(complexity_rec(cache, _))
}

/// Returns the integer complexity of the (absoulte value of the) specified integer.
pub fn get_complexity(cache cache, of integer: Int) -> Int {
  use <- bool.guard(integer == 0, 0)

  get_complexity_data(cache, int.absolute_value(integer)).complexity
}

/// Returns a valid expression following the rules of integer complexity of the (absoulte value of the) specified integer.
/// Note that there can be multiple valid expressions for an integer, but this function only
/// generates a single expression. 
/// Returns `Error(Nil)` if the specified integer is `0`.
pub fn get_expression(cache cache, of integer: Int) -> Result(Expression, Nil) {
  use <- bool.guard(integer == 0, Error(Nil))

  get_complexity_data(cache, int.absolute_value(integer)).from
  |> construct_expression(cache, _)
  |> Ok()
}

/// Return the complexity data of the specified integer.
fn get_complexity_data(cache cache, of integer: Int) -> ComplexityData {
  complexity_rec(cache, integer)
}

/// Recursively calculate the complexity of an integer
fn complexity_rec(cache, n: Int) -> ComplexityData {
  use <- memo.memoize(cache, n)
  use <- bool.guard(n == 1, ComplexityData(n, DerivedOne))

  //usual best value
  //1 + complexity of [n - 1]
  let base_complexity =
    ComplexityData(
      complexity_rec(cache, n - 1).complexity + 1,
      DerivedAdd(Derived(n - 1), DerivedOne),
    )

  let assert target = complexity_rec(cache, n - 1).complexity
  let t = calc_t(target / 2, target, n)
  let k_max = a000792(t)

  let sum_test_result =
    sums(cache, n, k_max)
    |> option.unwrap(base_complexity)

  let divisor_test_result =
    divisors(cache, n)
    |> option.unwrap(base_complexity)

  let assert Ok(result) =
    piecewise.list_minimum(
      [base_complexity, sum_test_result, divisor_test_result],
      fn(a, b) { int.compare(a.complexity, b.complexity) },
    )

  result
}

fn sums(cache, n: Int, max: Int) -> Option(ComplexityData) {
  use <- bool.guard(max < 6, None)

  list.range(6, max)
  |> list.fold(None, fn(acc, m) {
    let complexity_m = complexity_rec(cache, m).complexity

    let complexity_n_m = complexity_rec(cache, n - m).complexity

    let sum_value = complexity_m + complexity_n_m

    case acc {
      Some(ComplexityData(complexity, _)) if sum_value < complexity ->
        Some(ComplexityData(sum_value, DerivedAdd(Derived(m), Derived(n - m))))

      None ->
        Some(ComplexityData(sum_value, DerivedAdd(Derived(m), Derived(n - m))))

      _ -> acc
    }
  })
}

fn divisors(cache, n: Int) -> Option(ComplexityData) {
  let divisors = arithmetics.divisors(n)
  let smaller_divisors =
    list.take(divisors, float.round(int.to_float(list.length(divisors)) /. 2.0))
    |> list.drop(1)

  let sum_complexity =
    list.fold(smaller_divisors, None, fn(acc, a) {
      let complexity_a = complexity_rec(cache, a).complexity

      let complexity_b = complexity_rec(cache, n / a).complexity

      let prod_complexity = complexity_a + complexity_b

      case acc {
        None ->
          Some(ComplexityData(
            prod_complexity,
            DerivedMultiply(Derived(a), Derived(n / a)),
          ))

        Some(ComplexityData(complexity, _)) if prod_complexity < complexity ->
          Some(ComplexityData(
            prod_complexity,
            DerivedMultiply(Derived(a), Derived(n / a)),
          ))

        _ -> acc
      }
    })

  sum_complexity
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
        ComplexityData(prod_value, DerivedMultiply(Derived(k), Derived(n))),
      )
    Ok(ComplexityData(k_n_value, _)) if prod_value < k_n_value ->
      array.set(
        complexity,
        k * n,
        ComplexityData(prod_value, DerivedMultiply(Derived(k), Derived(n))),
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

fn construct_expression(
  cache,
  derived_expression: DerivedExpression,
) -> Expression {
  case derived_expression {
    DerivedOne -> expression.One
    DerivedAdd(lhs, rhs) ->
      expression.Add(
        construct_expression(cache, lhs),
        construct_expression(cache, rhs),
      )
    DerivedMultiply(lhs, rhs) ->
      expression.Multiply(
        construct_expression(cache, lhs),
        construct_expression(cache, rhs),
      )
    Derived(n) -> {
      let data = complexity_rec(cache, n)
      construct_expression(cache, data.from)
    }
  }
}
