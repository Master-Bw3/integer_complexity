import gleam/list
import gleam/order
import gleam/result
import integer_complexity/internal/array

pub opaque type FormatOptions(
  padding_defined,
  add_defined,
  multiply_defined,
  left_paren_defined,
  right_paren_defined,
  digits_defined,
) {
  FormatOptions(
    padding: String,
    add_sign: String,
    multiply_sign: String,
    left_bracket: String,
    right_bracket: String,
    digits: array.Array(String),
    base: Int,
  )
}

@internal
pub type PaddingDefined

@internal
pub type PaddingNotDefined

@internal
pub type AddSignDefined

@internal
pub type AddSignNotDefined

@internal
pub type MultiplySignDefined

@internal
pub type MultiplySignNotDefined

@internal
pub type LeftBracketDefined

@internal
pub type LeftBracketNotDefined

@internal
pub type RightBracketDefined

@internal
pub type RightBracketNotDefined

@internal
pub type DigitsDefined

@internal
pub type DigitsNotDefined

pub fn default_format_options() {
  FormatOptions(" ", "+", "*", "(", ")", array.from_list(["1"], ""), 1)
}

pub fn with_padding(
  options: FormatOptions(PaddingNotDefined, b, c, d, e, f),
  padding: String,
) -> FormatOptions(PaddingDefined, b, c, d, e, f) {
  FormatOptions(
    padding,
    options.add_sign,
    options.multiply_sign,
    options.left_bracket,
    options.right_bracket,
    options.digits,
    options.base,
  )
}

pub fn with_addition_sign(
  options: FormatOptions(a, AddSignNotDefined, c, d, e, f),
  sign: String,
) -> FormatOptions(a, AddSignDefined, c, d, e, f) {
  FormatOptions(
    options.padding,
    sign,
    options.multiply_sign,
    options.left_bracket,
    options.right_bracket,
    options.digits,
    options.base,
  )
}

pub fn with_multiplication_sign(
  options: FormatOptions(a, b, MultiplySignNotDefined, d, e, f),
  sign: String,
) -> FormatOptions(a, b, MultiplySignDefined, d, e, f) {
  FormatOptions(
    options.padding,
    options.add_sign,
    sign,
    options.left_bracket,
    options.right_bracket,
    options.digits,
    options.base,
  )
}

pub fn with_left_bracket(
  options: FormatOptions(a, b, c, LeftBracketNotDefined, e, f),
  left_bracket: String,
) -> FormatOptions(a, b, c, LeftBracketDefined, e, f) {
  FormatOptions(
    options.padding,
    options.add_sign,
    options.multiply_sign,
    left_bracket,
    options.right_bracket,
    options.digits,
    options.base,
  )
}

pub fn with_right_bracket(
  options: FormatOptions(a, b, c, d, RightBracketNotDefined, f),
  right_bracket: String,
) -> FormatOptions(a, b, c, d, RightBracketDefined, f) {
  FormatOptions(
    options.padding,
    options.add_sign,
    options.multiply_sign,
    options.left_bracket,
    right_bracket,
    options.digits,
    options.base,
  )
}

pub fn with_digits(
  options: FormatOptions(a, b, c, d, e, DigitsNotDefined),
  digits: List(String),
) -> FormatOptions(a, b, c, d, e, DigitsDefined) {
  FormatOptions(
    options.padding,
    options.add_sign,
    options.multiply_sign,
    options.right_bracket,
    options.left_bracket,
    array.from_list(digits, ""),
    list.length(digits),
  )
}

pub type Expression {
  Add(lhs: Expression, rhs: Expression)
  Multiply(lhs: Expression, rhs: Expression)
  One
}

pub fn to_string(
  expression: Expression,
  options: FormatOptions(_, _, _, _, _, _),
) -> String {
  represent_expression(expression, order.Eq, options)
}

fn represent_expression(
  expression: Expression,
  precidence: order.Order,
  options: FormatOptions(_, _, _, _, _, _),
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
  options: FormatOptions(_, _, _, _, _, _),
) {
  represent_expression(lhs, compare_precidence(lhs, this), options)
  <> apply_padding(options.padding, sign)
  <> represent_expression(rhs, compare_precidence(rhs, this), options)
}

fn conditionally_apply_parens(
  expression_str: String,
  precidence: order.Order,
  options: FormatOptions(_, _, _, _, _, _),
) {
  case precidence {
    order.Lt -> options.left_bracket <> expression_str <> options.right_bracket
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

fn apply_padding(padding: String, str: String) -> String {
  padding <> str <> padding
}
