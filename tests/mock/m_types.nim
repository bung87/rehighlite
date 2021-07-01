type A = int

type MyInt = distinct int

type A[T] = expr1

type IO = object of RootObj

type X = enum
  First

type Con = concept x, y, z
  (x & y & z) is string

type A[T: static[int]] = object

type MyProc[T] = proc(x: T)
