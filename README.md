# integer_complexity

[![Package Version](https://img.shields.io/hexpm/v/integer_complexity)](https://hex.pm/packages/integer_complexity)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/integer_complexity/)

A library for computing the integer complexity (and the corrisponding representation) of integers

based on "Algorithms for determining integer complexity" by J. Arias de Reyna and J. van de Lune
https://arxiv.org/abs/1404.2183

## Installation

Add `integer_complexity` to your Gleam project.

```sh
gleam add integer_complexity
```

## Examples


```gleam
import integer_complexity

pub fn main(name: String) -> String {
  let #(cache, complexity_of_ten) =
    integer_complexity.get_complexity(integer_complexity.new_cache(), 10)
  //complexity_of_ten = 7

  let #(cache, complexity_expression_of_ten) =
    integer_complexity.get_expression(cache, 10)
  //complexity_expression_of_ten = 
  //  Multiply(Add(One, One), Add(Multiply(Add(One, One), Add(One, One)), One))

  let string =
    expression.to_string(expression, expression.default_format_options())
  //string = (1 + 1) * ((1 + 1) * (1 + 1) + 1)

  let base_five_options = 
    expression.default_format_options()
    |> expression.with_digits(["1", "2", "3", "4", "5"])


  let string_base_five =
    expression.to_string(expression, base_five_options)
  //string_base_five = 2 * 5
}
```

## Targets

integer_complexity supports Erlang and JavaScript.
