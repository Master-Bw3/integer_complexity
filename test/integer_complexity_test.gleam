import gleam/io
import gleam/list
import gleam/result
import gleeunit
import gleeunit/should
import integer_complexity
import integer_complexity/expression.{type Expression, Add, Multiply, One}

pub fn main() {
  gleeunit.main()
}

const complexities = [
  1, 2, 3, 4, 5, 5, 6, 6, 6, 7, 8, 7, 8, 8, 8, 8, 9, 8, 9, 9, 9, 10, 11, 9, 10,
  10, 9, 10, 11, 10, 11, 10, 11, 11, 11, 10, 11, 11, 11, 11, 12, 11, 12, 12, 11,
  12, 13, 11, 12, 12, 12, 12, 13, 11, 12, 12, 12, 13, 14, 12, 13, 13, 12, 12, 13,
  13, 14, 13, 14, 13, 14, 12, 13, 13, 13, 13, 14, 13, 14,
]

const a000792 = [
  1, 1, 2, 3, 4, 6, 9, 12, 18, 27, 36, 54, 81, 108, 162, 243, 324, 486, 729, 972,
  1458, 2187, 2916, 4374, 6561, 8748, 13_122, 19_683, 26_244, 39_366, 59_049,
  78_732, 118_098, 177_147, 236_196, 354_294, 531_441, 708_588, 1_062_882,
  1_594_323, 2_125_764, 3_188_646, 4_782_969, 6_377_292,
]

pub fn complexities_up_to_test() {
  let cache = integer_complexity.new_cache()
  let assert Ok(#(_, result)) =
    integer_complexity.get_complexities_up_to(cache, list.length(complexities))

  should.equal(result, complexities)

  //negative input
  let result =
    integer_complexity.get_complexities_up_to(
      integer_complexity.new_cache(),
      -1,
    )

  should.be_error(result)

  //zero input
  let result =
    integer_complexity.get_complexities_up_to(integer_complexity.new_cache(), 0)

  should.be_error(result)
}

pub fn complexity_cache_test() {
  let cache = integer_complexity.new_cache()
  let n_max = list.length(complexities)

  let assert Ok(#(_, result)) =
    integer_complexity.get_complexities_up_to(cache, n_max / 2)
    |> result.then(fn(x) {
      integer_complexity.get_complexities_up_to(x.0, n_max)
    })

  should.equal(result, complexities)
}

pub fn get_complexity_test() {
  let result =
    integer_complexity.get_complexity(
      integer_complexity.new_cache(),
      list.length(complexities),
    ).1

  should.equal(Ok(result), list.last(complexities))

  //negative input
  let result =
    integer_complexity.get_complexity(integer_complexity.new_cache(), -1).1

  should.equal(result, 1)
}

pub fn a000792_test() {
  list.range(0, list.length(a000792) - 1)
  |> list.map(integer_complexity.a000792)
  |> should.equal(a000792)
}

pub fn evaluate_expression_test() {
  let expression = Multiply(Add(One, One), Add(One, Add(One, One)))

  expression.evaluate_expression(expression)
  |> should.equal(6)
}

pub fn expression_string_test() {
  let expression = Multiply(Add(One, One), Add(One, Add(One, One)))

  expression.to_string(expression, expression.default_format_options())
  |> should.equal("(1 + 1) * (1 + 1 + 1)")
}

pub fn expression_string_base_five_test() {
  let expression =
    Multiply(
      Add(One, Add(One, One)),
      Add(Multiply(Add(One, One), Add(One, One)), One),
    )

  expression.evaluate_expression(expression)
  |> io.debug()

  let options =
    expression.default_format_options()
    |> expression.with_digits(["1", "2", "3", "4", "5"])

  expression.to_string(expression, options)
  |> should.equal("3 * 5")
}

pub fn expression_test() {
  let assert Ok(#(_, expressions)) =
    integer_complexity.get_expressions_up_to(
      integer_complexity.new_cache(),
      1000,
    )

  //test that expression evaluates to n
  list.index_map(expressions, fn(x, i) { #(i + 1, x) })
  |> list.all(fn(item) { item.0 == expression.evaluate_expression(item.1) })
  |> should.be_true()

  //test for correct number of ones
  list.take(expressions, list.length(complexities))
  |> list.map(count_ones)
  |> should.equal(complexities)
}

fn count_ones(expression: Expression) -> Int {
  case expression {
    One -> 1
    Add(lhs, rhs) | Multiply(lhs, rhs) -> count_ones(lhs) + count_ones(rhs)
  }
}
