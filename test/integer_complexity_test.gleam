import gleam/int
import gleam/io
import gleam/list
import gleeunit
import gleeunit/should
import integer_complexity

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

pub fn complexity_test() {
  let cache = integer_complexity.new_cache()
  integer_complexity.get_complexities_up_to(cache, 79).1
  |> should.equal(complexities)
}

pub fn get_complexity_test() {
  let result =
    integer_complexity.get_complexity(integer_complexity.new_cache(), 79).1

  should.equal(result, 14)
}

// gleeunit test functions end in `_test`
pub fn is_prime_test() {
  integer_complexity.is_prime(1)
  |> should.be_false()

  integer_complexity.is_prime(25)
  |> should.be_false()

  integer_complexity.is_prime(2)
  |> should.be_true()

  integer_complexity.is_prime(3)
  |> should.be_true()

  integer_complexity.is_prime(71)
  |> should.be_true()
}

pub fn a000792_test() {
  list.range(0, list.length(a000792) - 1)
  |> list.map(integer_complexity.a000792)
  |> should.equal(a000792)
}
