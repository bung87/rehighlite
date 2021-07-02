proc hello(): var int

# proc(a, b: int)

proc hello*(x: int = 3, y: float32): int {.inline.} = discard

proc hello*[T: SomeInteger](x: int = 3, y: float32): int {.inline.} = discard


iterator nonsense[T](x: seq[T]): float {.closure.}

converter toBool(x: float): bool
