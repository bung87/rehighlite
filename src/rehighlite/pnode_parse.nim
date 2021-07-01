# import compiler/[parser, llstream, idents, options, pathutils # , astalgo
# ]
# import compiler/[ast, lineinfos]
import ./mimport
from os import nil
mImport(os.joinPath( "compiler" , "parser.nim"))
mImport(os.joinPath( "compiler" , "llstream.nim"))
mImport(os.joinPath( "compiler" , "idents.nim"))
mImport(os.joinPath( "compiler" , "options.nim"))
mImport(os.joinPath( "compiler" , "pathutils.nim"))
mImport(os.joinPath( "compiler" , "lineinfos.nim"))
mImport(os.joinPath( "compiler" , "ast.nim"))
export ast
type ParseError = ref object of CatchableError

proc parsePNodeStr*(str: string): PNode =
  let cache: IdentCache = newIdentCache()
  let config: ConfigRef = newConfigRef()
  var pars: Parser

  config.verbosity = 0
  config.options.excl optHints
  when defined(nimpretty):
    config.outDir = toAbsoluteDir(os.parentDir currentSourcePath())
    config.outFile = RelativeFile("fake")
  openParser(
    p = pars,
    filename = AbsoluteFile(currentSourcePath()),
    inputStream = llStreamOpen(str),
    cache = cache,
    config = config
  )
  # parseString(str,cache,config)

  pars.lex.errorHandler =
    proc(conf: ConfigRef; info: TLineInfo; msg: TMsgKind; arg: string) =
      if msg notin {hintLineTooLong}:
        raise ParseError(msg: arg)

  try:
    result = parseAll(pars)
    closeParser(pars)

  except ParseError:
    return nil
