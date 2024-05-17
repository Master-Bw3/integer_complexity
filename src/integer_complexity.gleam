//// This module contains functions for computing the complexity of an integer, 
//// and a corrisponding mathematical expression that uses only ones, addition, and multiplication to reach that integer.
//// testing the products

import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam_community/maths/arithmetics
import integer_complexity/expression.{type Expression}
import integer_complexity/internal/memo

/// The complexity and a valid expression of an Integer.
@internal
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

  let target = complexity_rec(cache, n - 1).complexity
  let t = calc_t(target / 2, target, n)
  let k_max = a000792(t)

  //take lowest complexity from base_complexity, sum test, and divisor test
  base_complexity
  |> test_sums(cache, n, k_max)
  |> test_divisors(cache, n)
}

fn test_sums(
  current_complexity_data: ComplexityData,
  cache,
  n: Int,
  max: Int,
) -> ComplexityData {
  use <- bool.guard(max < 6, current_complexity_data)

  list.range(6, max)
  |> list.fold(current_complexity_data, fn(acc, m) {
    let complexity_m = complexity_rec(cache, m).complexity

    let complexity_n_m = complexity_rec(cache, n - m).complexity

    let sum_value = complexity_m + complexity_n_m

    case sum_value < acc.complexity {
      True -> ComplexityData(sum_value, DerivedAdd(Derived(m), Derived(n - m)))
      False -> acc
    }
  })
}

fn test_divisors(
  current_complexity_data: ComplexityData,
  cache,
  n: Int,
) -> ComplexityData {
  let divisors = arithmetics.divisors(n)
  let smaller_divisors =
    list.take(divisors, float.round(int.to_float(list.length(divisors)) /. 2.0))
    |> list.drop(1)

  let sum_complexity =
    list.fold(smaller_divisors, current_complexity_data, fn(acc, a) {
      let complexity_a = complexity_rec(cache, a).complexity

      let complexity_b = complexity_rec(cache, n / a).complexity

      let prod_complexity = complexity_a + complexity_b

      case prod_complexity < acc.complexity {
        True ->
          ComplexityData(
            prod_complexity,
            DerivedMultiply(Derived(a), Derived(n / a)),
          )

        False -> acc
      }
    })

  sum_complexity
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
