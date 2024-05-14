import gleam/io
import gleam/list
import gleam/option.{type Option}
import gleam/order
import gleam/result
import gleam/string

pub fn main() {
  let expression = Multiply(Add(One, One), Add(One, Add(One, One)))

  represent_expression(
    expression,
    option.Some(RepresentationOptions(2, " ", "^", ".", "[", "]", ["8"])),
  )
  |> io.debug()
}

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
  represent_expression_rec(expression, option.unwrap(options, default_options))
}

fn represent_expression_rec(
  expression: Expression,
  options: RepresentationOptions,
) -> String {
  case expression {
    One -> result.unwrap(list.first(options.digits), "")
    Add(lhs, rhs) ->
      represent_expression_rec(lhs, options)
      <> apply_padding(
        options.padding,
        options.padding_string,
        options.addition_sign,
      )
      <> represent_expression_rec(rhs, options)
    Multiply(lhs, rhs) -> {
      represent_multiply(expression, lhs, rhs, options)
    }
  }
}

fn represent_multiply(
  this,
  lhs: Expression,
  rhs: Expression,
  options: RepresentationOptions,
) -> String {
  let lhs_representation = case compare_precidence(this, lhs) {
    order.Gt ->
      options.left_parenthesis
      <> represent_expression_rec(lhs, options)
      <> options.right_parenthesis
    _ -> represent_expression_rec(lhs, options)
  }
  let rhs_representation = case compare_precidence(this, rhs) {
    order.Gt ->
      options.left_parenthesis
      <> represent_expression_rec(rhs, options)
      <> options.right_parenthesis
    _ -> represent_expression_rec(rhs, options)
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
