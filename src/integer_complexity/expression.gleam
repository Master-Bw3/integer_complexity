import gleam/order

pub type Expression {
  Add(lhs: Expression, rhs: Expression)
  Multiply(lhs: Expression, rhs: Expression)
  One
}

pub fn represent_expression(expression: Expression) -> String {
  case expression {
    One -> "1"
    Add(lhs, rhs) ->
      represent_expression(lhs) <> " + " <> represent_expression(rhs)
    Multiply(lhs, rhs) -> {
      represent_multiply(expression, lhs, rhs)
    }
  }
}

fn represent_multiply(this, lhs: Expression, rhs: Expression) -> String {
  let lhs_representation = case compare_precidence(this, lhs) {
    order.Gt -> "(" <> represent_expression(lhs) <> ")"
    _ -> represent_expression(lhs)
  }
  let rhs_representation = case compare_precidence(this, rhs) {
    order.Gt -> "(" <> represent_expression(rhs) <> ")"
    _ -> represent_expression(rhs)
  }

  lhs_representation <> " * " <> rhs_representation
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
