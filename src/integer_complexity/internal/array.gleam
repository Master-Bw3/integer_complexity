import gary
import gary/array
import gleam/dict
import gleam/int
import gleam/list
import gleam/result

@target(erlang)
type Array(a) =
  gary.ErlangArray(a)

@target(javascript)
type Array(a) =
  dict.Dict(Int, a)

//erlang

@target(erlang)
pub fn get(array: Array(a), index: Int) -> Result(a, Nil) {
  let default_value = array.get_default(array)
  case array.get(array, index) {
    Ok(value) if value != default_value -> Ok(value)
    _ -> Error(Nil)
  }
}

@target(erlang)
pub fn set(array: Array(a), index: Int, item: a) -> Result(Array(a), Nil) {
  array.set(array, index, item)
  |> result.nil_error()
}

@target(erlang)
pub fn from_list(list: List(a), default: a) -> Array(a) {
  array.from_list(list, default)
}

@target(erlang)
pub fn to_list(array: Array(a)) -> List(a) {
  array.to_list(array)
}

//javascript

@target(javascript)
pub fn get(array: Array(a), index: Int) -> Result(a, Nil) {
  dict.get(array, index)
  |> result.nil_error()
}

@target(javascript)
pub fn set(array: Array(a), index: Int, item: a) -> Result(Array(a), Nil) {
  Ok(dict.insert(array, index, item))
}

@target(javascript)
pub fn from_list(list: List(a), default: a) -> Array(a) {
  list.index_map(list, fn(x, i) { #(i, x) })
  |> dict.from_list()
}

@target(javascript)
pub fn to_list(array: Array(a)) -> List(a) {
  dict.to_list(array)
  |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
  |> list.map(fn(x) { x.1 })
}
