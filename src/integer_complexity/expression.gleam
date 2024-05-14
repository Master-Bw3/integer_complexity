import gleam/bool
import gleam/list
import gleam/option.{type Option}
import gleam/order
import gleam/result
import gleam/string

pub type Expression {
  Add(lhs: Expression, rhs: Expression)
  Multiply(lhs: Expression, rhs: Expression)
  One
}

pub type RepresentationOptions {
  RepresentationOptions(
    padding: Int,
    padding_string: String,
    addition_sign: String,
    multiplication_sign: String,
    left_parenthesis: String,
    right_parenthesis: String,
    digits: List(String),
  )
}

const default_options = RepresentationOptions(1, " ", "+", "*", "(", ")", ["1"])

pub fn represent_expression(
  expression: Expression,
  options: Option(RepresentationOptions),
) -> String {
  represent_expression_rec(
    expression,
    option.unwrap(options, default_options),
    False,
  )
}

fn represent_expression_rec(
  expression: Expression,
  options: RepresentationOptions,
  wrap_with_parens: Bool,
) -> String {
  case expression {
    One -> result.unwrap(list.first(options.digits), "")
    Add(lhs, rhs) ->
      represent_add(expression, lhs, rhs, options, wrap_with_parens)

    Multiply(lhs, rhs) -> represent_multiply(expression, lhs, rhs, options)
  }
}

fn represent_add(
  this: Expression,
  lhs: Expression,
  rhs: Expression,
  options: RepresentationOptions,
  wrap_with_parens: Bool,
) -> String {
  let base = list.length(options.digits)
  let eval_result = evaluate_expression(this)

  use <- bool.lazy_guard(eval_result <= base, fn() {
    result.unwrap(list.at(options.digits, eval_result - 1), "")
  })

  let str =
    represent_expression_rec(lhs, options, False)
    <> apply_padding(
      options.padding,
      options.padding_string,
      options.addition_sign,
    )
    <> represent_expression_rec(rhs, options, False)

  case wrap_with_parens {
    True -> options.left_parenthesis <> str <> options.right_parenthesis
    False -> str
  }
}

fn represent_multiply(
  this: Expression,
  lhs: Expression,
  rhs: Expression,
  options: RepresentationOptions,
) -> String {
  let lhs_representation = case compare_precidence(this, lhs) {
    order.Gt -> represent_expression_rec(lhs, options, True)
    _ -> represent_expression_rec(lhs, options, False)
  }
  let rhs_representation = case compare_precidence(this, rhs) {
    order.Gt -> represent_expression_rec(rhs, options, True)
    _ -> represent_expression_rec(rhs, options, False)
  }

  lhs_representation
  <> apply_padding(
    options.padding,
    options.padding_string,
    options.multiplication_sign,
  )
  <> rhs_representation
}

@internal
pub fn evaluate_expression(expression: Expression) -> Int {
  case expression {
    One -> 1
    Add(lhs, rhs) -> evaluate_expression(lhs) + evaluate_expression(rhs)
    Multiply(lhs, rhs) -> evaluate_expression(lhs) * evaluate_expression(rhs)
  }
}

fn compare_precidence(lhs: Expression, rhs: Expression) {
  case lhs, rhs {
    Add(_, _), Multiply(_, _) -> order.Lt
    Multiply(_, _), Add(_, _) -> order.Gt
    _, _ -> order.Eq
  }
}

fn apply_padding(ammount: Int, padding_string: String, str: String) -> String {
  str
  |> string.pad_left(ammount + string.length(str), padding_string)
  |> string.pad_right(ammount * 2 + string.length(str), padding_string)
}
