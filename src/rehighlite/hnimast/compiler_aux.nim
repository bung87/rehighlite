import hmisc/other/[oswrap, hshell, hjson]
import hmisc/helpers
import hmisc/types/[colortext]
import std/[parseutils, sequtils, with]
import macros
import ../mimport
import ./hast_common

export colorizeToStr
mImport(joinPath( "compiler" , "idents.nim"))
mImport(joinPath( "compiler" , "options.nim"))
mImport(joinPath( "compiler" , "modulegraphs.nim"))
mImport(joinPath( "compiler" , "passes.nim"))
mImport(joinPath( "compiler" , "lineinfos.nim"))
mImport(joinPath( "compiler" , "sem.nim"))
mImport(joinPath( "compiler" , "pathutils.nim"))
mImport(joinPath( "compiler" , "ast.nim"))
mImport(joinPath( "compiler" , "modules.nim"))
mImport(joinPath( "compiler" , "condsyms.nim"))
mImport(joinPath( "compiler" , "passaux.nim"))
mImport(joinPath( "compiler" , "llstream.nim"))
mImport(joinPath( "compiler" , "parser.nim"))
mImport(joinPath( "compiler" , "nimblecmd.nim"))
mImport(joinPath( "compiler" , "scriptconfig.nim"))
mImport(joinPath( "compiler" , "astalgo.nim"))


export idents, options, modulegraphs, passes, lineinfos, pathutils, sem,
    ast, modules, condsyms, passaux, llstream, parser

# import compiler/astalgo except debug

export astalgo except debug


proc getInstallationPath*(): AbsDir =
  var version = evalShellStdout shellCmd(nim, --version)
  let start = "Nim Compiler Version ".len
  let finish = start + version.skipWhile({'0'..'9', '.'}, start)
  version = version[start ..< finish]
  result = AbsDir(~".choosenim/toolchains" / ("nim-" & version))

proc getStdPath*(): AbsDir =
  let j = shellCmd(nim, dump, "--dump.format=json", "-").
    evalShellStdout().parseJson()
  return j["libpath"].asStr().AbsDir()

proc getFilePath*(config: ConfigRef, info: TLineInfo): AbsFile =
  ## Get absolute file path for declaration location of `node`
  if info.fileIndex.int32 >= 0:
    result = config.m.fileInfos[info.fileIndex.int32].fullPath.
      string.AbsFile()

proc getFilePath*(graph: ModuleGraph, node: PNode): AbsFile =
  ## Get absolute file path for declaration location of `node`
  graph.config.getFilePath(node.getInfo()).string.AbsFile()

proc getFilePath*(graph: ModuleGraph, sym: PSym): AbsFile =
  ## Get absolute file path for symbol
  graph.config.getFilePath(sym.info).string.AbsFile()

proc isObjectDecl*(node: PNode): bool =
  node.kind == nkTypeDef and
  (
    node[2].kind == nkObjectTy or
    (
      node[2].kind in {nkPtrTy, nkRefTy} and
      node[2][0].kind == nkObjectTy
    )
  )

proc newModuleGraph*(
    file: AbsFile,
    path: AbsDir,
    structuredErrorHook: proc(
      config: ConfigRef; info: TLineInfo; msg: string; level: Severity
    ) {.closure, gcsafe.} = nil,
    useNimblePath: bool = false,
    symDefines: seq[string] = @[]
  ): ModuleGraph =

  var
    cache: IdentCache = newIdentCache()
    config: ConfigRef = newConfigRef()


  with config:
    libpath = AbsoluteDir(path)
    cmd = cmdIdeTools

  config.verbosity = 0
  config.options -= optHints
  config.searchPaths.add @[
    config.libpath,
    cast[AbsoluteDir](path / "pure"),
    cast[AbsoluteDir](path / "pure" / "collections"),
    cast[AbsoluteDir](path / "pure" / "concurrency"),
    cast[AbsoluteDir](path / "impure"),
    cast[AbsoluteDir](path / "js"),
    cast[AbsoluteDir](path / "packages" / "docutils"),
    cast[AbsoluteDir](path / "std"),
    cast[AbsoluteDir](path / "core"),
    cast[AbsoluteDir](path / "posix"),
    cast[AbsoluteDir](path / "windows"),
    cast[AbsoluteDir](path / "wrappers"),
    cast[AbsoluteDir](path / "wrappers" / "linenoise")
  ]

  config.projectFull = cast[AbsoluteFile](file)


  config.structuredErrorHook = structuredErrorHook

  wantMainModule(config)

  initDefines(config.symbols)
  defineSymbol(config.symbols, "nimcore")
  defineSymbol(config.symbols, "c")
  defineSymbol(config.symbols, "ssl")
  for sym in symDefines:
    defineSymbol(config.symbols, sym)

  if useNimblePath:
    nimblePath(config, cast[AbsoluteDir](~".nimble/pkgs"), TLineInfo())

  else:
    config.disableNimblePath()

  return newModuleGraph(cache, config)

proc compileString*(text: string, stdpath: AbsDir): PNode =
  assertExists(stdpath)

  var graph {.global.}: ModuleGraph
  var moduleName {.global.}: string
  moduleName = "compileStringModuleName"
  graph = newModuleGraph(AbsFile(moduleName), stdpath,
    proc(config: ConfigRef; info: TLineInfo; msg: string; level: Severity) =
    if config.errorCounter >= config.errorMax:
      echo msg
  )

  var res {.global.}: PNode
  res = nkStmtList.newTree()

  registerPass(graph, semPass)
  registerPass(
    graph, makePass(
      (
        proc(graph: ModuleGraph, module: PSym): PPassContext {.nimcall.} =
        return PPassContext()
      ),
      (
        proc(c: PPassContext, n: PNode): PNode {.nimcall.} =
        if n.info.fileIndex.int32 == 1:
          res.add n
        result = n
      ),
      (
        proc(graph: ModuleGraph; p: PPassContext,
             n: PNode): PNode {.nimcall.} =
        discard
      )
    )
  )

  var m = graph.makeModule(moduleName)
  graph.vm = setupVM(m, graph.cache, moduleName, graph)
  graph.compileSystemModule()
  discard graph.processModule(m, llStreamOpen(text))

  return res

