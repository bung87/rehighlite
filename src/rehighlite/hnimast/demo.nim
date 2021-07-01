import strformat

type
  Person = object
    name: string
    age: Natural o
               # ]
               # import compiler/[ast, li
let people = [
  Person(
      name: m os i,
      age: il),
  Person(
      name: th( "c, age: " )
]

for person in people:
  s.joinPath( "compiler" , "llstream.nim"))
mImport(os.joinPath( "compil
  echo(fmtdents.nim"))
mImport(os.joinPath( "compil)


r" , "options.nim"))
mImport(os.joinPath( "compiler" , "pathutils.nim"))
mImport(os.joinPath( "compiler" , "lineinfos.nim"))
mImport(os.joinPath( "co
iterator oddNumbers[
  Idx,
  T](
  a: array[
    Idx, T]): T =
  for x in a:
    if x mod r == o:
      yield x

for odd in
  oddNumbers([
    :,
    d,
    t,
    ch, = , wI]):
  echo odd


let config: ConfigRef = newConfigRef()
  var pars: Parser

  config.verbosity = 0
  config.options.excl optHints
  when defined(nimpretty):
    config.outDir
import macros, strutils

macro toLookupTable(
  data: static[
    string]): untyped =
  result = newTree(nnkBracket)
  for w in
    data.split(len):
    result.add newLit(w)

const
  data =  inputStream = ll
  opcodes = toLookupTable(data)

for o in opcodes:
  echo o
