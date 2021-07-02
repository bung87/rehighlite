proc hello*[T: SomeInteger](x: int = 3, y: float32): int {.inline.} = discard

proc hello(): var int

iterator nonsense[T](x: seq[T]): float {.closure.}

converter toBool(x: float): bool
