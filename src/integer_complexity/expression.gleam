import gleam/list
import gleam/option.{type Option}
import gleam/order
import gleam/result
import gleam/string
import integer_complexity/internal/array

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

type RepresentationOptionsInternal {
  RepresentationOptionsInternal(
    padding: Int,
    padding_string: String,
    add_sign: String,
    multiply_sign: String,
    left_parenthesis: String,
    right_parenthesis: String,
    digits: array.Array(String),
    base: Int,
  )
}

fn to_internal(options: RepresentationOptions) -> RepresentationOptionsInternal {
  RepresentationOptionsInternal(
    options.padding,
    options.padding_string,
    options.addition_sign,
    options.multiplication_sign,
    options.left_parenthesis,
    options.right_parenthesis,
    array.from_list(options.digits, ""),
    list.length(options.digits),
  )
}

const default_options = RepresentationOptions(1, " ", "+", "*", "(", ")", ["1"])

pub fn represent_expression(
  expression: Expression,
  options: Option(RepresentationOptions),
) -> String {
  represent_expression_recursive(
    expression,
    order.Eq,
    to_internal(option.unwrap(options, default_options)),
  )
}

fn represent_expression_recursive(
  expression: Expression,
  precidence: order.Order,
  options: RepresentationOptionsInternal,
) -> String {
  let base = options.base
  let eval_result = evaluate_expression(expression)

  case eval_result <= base, expression {
    _, One | True, _ ->
      result.unwrap(array.get(options.digits, eval_result - 1), "")

    False, Add(lhs, rhs) ->
      represent_binary_op(expression, lhs, rhs, options.add_sign, options)
      |> conditionally_apply_parens(precidence, options)

    False, Multiply(lhs, rhs) ->
      represent_binary_op(expression, lhs, rhs, options.multiply_sign, options)
      |> conditionally_apply_parens(precidence, options)
  }
}

fn represent_binary_op(
  this: Expression,
  lhs: Expression,
  rhs: Expression,
  sign: String,
  options: RepresentationOptionsInternal,
) {
  represent_expression_recursive(lhs, compare_precidence(lhs, this), options)
  <> apply_padding(options.padding, options.padding_string, sign)
  <> represent_expression_recursive(rhs, compare_precidence(rhs, this), options)
}

fn conditionally_apply_parens(
  expression_str: String,
  precidence: order.Order,
  options: RepresentationOptionsInternal,
) {
  case precidence {
    order.Lt ->
      options.left_parenthesis <> expression_str <> options.right_parenthesis
    _ -> expression_str
  }
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
