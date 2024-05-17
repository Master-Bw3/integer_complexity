import gleam/javascript/map
import rememo/ets/memo

@target(erlang)
pub const create = memo.create

@target(javascript)
pub fn create(apply fun) {
  let map = map.new()

  let result = fun(map)
  result
}

@target(erlang)
pub const memoize = memo.memoize

@target(javascript)
pub fn memoize(
  with cache: map.Map(k, v),
  this key: k,
  apply fun: fn() -> v,
) -> v {
  case map.get(cache, key) {
    Ok(value) -> value
    Error(_) -> {
      let result = fun()
      map.set(cache, key, result)
      result
    }
  }
}
