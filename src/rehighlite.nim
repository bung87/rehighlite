
import strutils
import ./rehighlite/pnode_parse
from algorithm import binarySearch
import packages/docutils/highlite except GeneralTokenizer, TokenClass

const
  # The following list comes from doc/keywords.txt, make sure it is
  # synchronized with this array by running the module itself as a test case.
  nimKeywords = ["addr", "and", "as", "asm", "bind", "block",
    "break", "case", "cast", "concept", "const", "continue", "converter",
    "defer", "discard", "distinct", "div", "do",
    "elif", "else", "end", "enum", "except", "export",
    "finally", "for", "from", "func",
    "if", "import", "in", "include",
    "interface", "is", "isnot", "iterator", "let", "macro", "method",
    "mixin", "mod", "nil", "not", "notin", "object", "of", "or", "out", "proc",
    "ptr", "raise", "ref", "return", "shl", "shr", "static",
    "template", "try", "tuple", "type", "using", "var", "when", "while",
    "xor", "yield"]
  nimBooleans = ["true", "false"]
  nimSpecialVars = ["result"]
  # Builtin types, objects, and exceptions
  nimBuiltins = ["AccessViolationError", "AlignType", "ArithmeticError",
    "AssertionError", "BiggestFloat", "BiggestInt", "Byte", "ByteAddress",
    "CloseFile", "CompileDate", "CompileTime", "Conversion", "DeadThreadError",
    "DivByZeroError", "EndOfFile", "Endianness", "Exception", "ExecIOEffect",
    "FieldError", "File", "FileHandle", "FileMode", "FileModeFileHandle",
    "FloatDivByZeroError", "FloatInexactError", "FloatInvalidOpError",
    "FloatOverflowError", "FloatUnderflowError", "FloatingPointError",
    "FlushFile", "GC_Strategy", "GC_disable", "GC_disableMarkAnd", "GC_enable",
    "GC_enableMarkAndSweep", "GC_fullCollect", "GC_getStatistics", "GC_ref",
    "GC_setStrategy", "GC_unref", "IOEffect", "IOError", "IndexError",
    "KeyError", "LibHandle", "LibraryError", "Msg", "Natural", "NimNode",
    "OSError", "ObjectAssignmentError", "ObjectConversionError", "OpenFile",
    "Ordinal", "OutOfMemError", "OverflowError", "PFloat32", "PFloat64",
    "PFrame", "PInt32", "PInt64", "Positive", "ProcAddr", "QuitFailure",
    "QuitSuccess", "RangeError", "ReadBytes", "ReadChars", "ReadIOEffect",
    "RefCount", "ReraiseError", "ResourceExhaustedError", "RootEffect",
    "RootObj", "RootObjRootRef", "Slice", "SomeInteger", "SomeNumber",
    "SomeOrdinal", "SomeReal", "SomeSignedInt", "SomeUnsignedInt",
    "StackOverflowError", "Sweep", "SystemError", "TFrame", "THINSTANCE",
    "TResult", "TaintedString", "TimeEffect", "Utf16Char", "ValueError",
    "WideCString", "WriteIOEffect", "abs", "add", "addQuitProc", "alloc",
    "alloc0", "array", "assert", "autoany", "bool", "byte", "card", "cchar",
    "cdouble", "cfloat", "char", "chr", "cint", "clong", "clongdouble",
    "clonglong", "copy", "copyMem", "countdown", "countup", "cpuEndian",
    "cschar", "cshort", "csize", "cstring", "cstringArray", "cuchar", "cuint",
    "culong", "culonglong", "cushort", "dbgLineHook", "dealloc", "dec",
    "defined", "echo", "equalMem", "equalmem", "excl", "expr", "fileHandle",
    "find", "float", "float32", "float64", "getCurrentException", "getFilePos",
    "getFileSize", "getFreeMem", "getOccupiedMem", "getRefcount", "getTotalMem",
    "guarded", "high", "hostCPU", "hostOS", "inc", "incl", "inf", "int", "int16",
    "int32", "int64", "int8", "isNil", "items", "len", "lines", "low", "max",
    "min", "moveMem", "movemem", "nan", "neginf", "new", "newSeq", "newString",
    "newseq", "newstring", "nimMajor", "nimMinor", "nimPatch", "nimVersion",
    "nimmajor", "nimminor", "nimpatch", "nimversion", "openArray", "openarray",
    "ord", "pointer", "pop", "pred", "ptr", "quit", "range", "readBuffer",
    "readChar", "readFile", "readLine", "readbuffer", "readfile", "readline",
    "realloc", "ref", "repr", "seq", "seqToPtr", "seqtoptr", "set",
    "setFilePos", "setLen", "setfilepos", "setlen", "shared", "sizeof",
    "stderr", "stdin", "stdout", "stmt", "string", "succ", "swap",
    "toBiggestFloat", "toBiggestInt", "toFloat", "toInt", "toU16", "toU32",
    "toU8", "tobiggestfloat", "tobiggestint", "tofloat", "toint", "tou16",
    "tou32", "tou8", "typed", "typedesc", "uint", "uint16", "uint32",
    "uint32uint64", "uint64", "uint8", "untyped", "varArgs", "void", "write",
    "writeBuffer", "writeBytes", "writeChars", "writeLine", "writeLn", "ze",
    "ze64", "zeroMem"]

type
  TokenClass* = enum
    gtEof, gtNone, gtWhitespace, gtDecNumber, gtBinNumber, gtHexNumber,
    gtOctNumber, gtFloatNumber, gtIdentifier, gtKeyword, gtStringLit,
    gtLongStringLit, gtCharLit, gtEscapeSequence, # escape sequence like \xff
    gtOperator, gtPunctuation, gtComment, gtLongComment, gtRegularExpression,
    gtTagStart, gtTagEnd, gtKey, gtValue, gtRawData, gtAssembler,
    gtPreprocessor, gtDirective, gtCommand, gtRule, gtHyperlink, gtLabel,
    gtReference, gtOther, gtBoolean, gtSpecialVar, gtBuiltin, gtFunctionName

proc nimGetKeyword(id: string): TokenClass =
  for k in nimKeywords:
    if cmpIgnoreStyle(id, k) == 0: return gtKeyword
  if binarySearch(nimBooleans, id) > -1: return gtBoolean
  if binarySearch(nimSpecialVars, id) > -1: return gtSpecialVar
  if binarySearch(nimBuiltins, id) > -1: return gtBuiltin
  result = gtIdentifier

type GeneralTokenizer* = object of RootObj
  kind*: TokenClass
  tKind*: TNodeKind
  start*, length*: int
  buf: cstring
  # pos: int
  # state: TokenClass
  # lang: SourceLanguage

type EditorColorPair* = enum
  lineNum = 1
  currentLineNum = 2
  # status line
  statusLineNormalMode = 3
  statusLineModeNormalMode = 4
  statusLineNormalModeInactive = 5
  statusLineInsertMode = 6
  statusLineModeInsertMode = 7
  statusLineInsertModeInactive = 8
  statusLineVisualMode = 9
  statusLineModeVisualMode = 10
  statusLineVisualModeInactive = 11
  statusLineReplaceMode = 12
  statusLineModeReplaceMode = 13
  statusLineReplaceModeInactive = 14
  statusLineFilerMode = 15
  statusLineModeFilerMode = 16
  statusLineFilerModeInactive = 17
  statusLineExMode = 18
  statusLineModeExMode = 19
  statusLineExModeInactive = 20
  statusLineGitBranch = 21
  # tab lnie
  tab = 22
  # tab line
  currentTab = 23
  # command bar
  commandBar = 24
  # error message
  errorMessage = 25
  # search result highlighting
  searchResult = 26
  # selected area in visual mode
  visualMode = 27

  # color scheme
  defaultChar = 28
  keyword = 29
  functionName = 30
  boolean = 31
  specialVar = 32
  builtin = 33
  stringLit = 34
  decNumber = 35
  comment = 36
  longComment = 37
  whitespace = 38
  preprocessor = 39

  # filer mode
  currentFile = 40
  file = 41
  dir = 42
  pcLink = 43
  # pop up window
  popUpWindow = 44
  popUpWinCurrentLine = 45
  # replace text highlighting
  replaceText = 46
  # pair of paren highlighting
  parenText = 47
  # highlight other uses current word
  currentWord = 48
  # highlight full width space
  highlightFullWidthSpace = 49
  # highlight trailing spaces
  highlightTrailingSpaces = 50
  # highlight reserved words
  reservedWord = 51
  # highlight history manager
  currentHistory = 52
  # highlight diff
  addedLine = 53
  deletedLine = 54
  # configuration mode
  currentSetting = 55

type ColorSegment* = object
  firstRow*, firstColumn*, lastRow*, lastColumn*: int
  color*: EditorColorPair

type Highlight* = object
  colorSegments*: seq[ColorSegment]

proc getEditorColorPairInNim(kind: TokenClass,
                             isProcName: bool): EditorColorPair =

  case kind:
    of gtKeyword: EditorColorPair.keyword
    of gtBoolean: EditorColorPair.boolean # nimBooleans = ["true", "false"]
    of gtSpecialVar: EditorColorPair.specialVar # nimSpecialVars = ["result"]
    of gtBuiltin: EditorColorPair.builtin # # Builtin types, objects, and exceptions
    of gtStringLit: EditorColorPair.stringLit
    of gtDecNumber: EditorColorPair.decNumber
    of gtComment: EditorColorPair.comment
    of gtLongComment: EditorColorPair.longComment
    of gtPreprocessor: EditorColorPair.preprocessor
    of gtWhitespace, gtPunctuation: EditorColorPair.defaultChar
    of gtFunctionName: EditorColorPair.functionName
    else:
      if isProcName: EditorColorPair.functionName
      else: EditorColorPair.defaultChar

proc initNimToken(kind: TokenClass; start, length: int, buf: string, tKind: TNodeKind): GeneralTokenizer =
  result = GeneralTokenizer(kind: kind, start: start, length: length, buf: buf.cstring, tKind: tKind) #, lang: SourceLanguage.langNim)

proc initNimKeyword(n: PNode, buf: string, tKind: TNodeKind): GeneralTokenizer =
  let start = n.info.offsetA
  let length = if n.info.offsetB == n.info.offsetA: buf.len else: n.info.offsetB - n.info.offsetA + 1
  result = GeneralTokenizer(kind: TokenClass.gtKeyword, start: start, length: length, buf: buf.cstring,
      tKind: tKind) #, lang: SourceLanguage.langNim)

const CallNodes = {nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand,
             nkCallStrLit, nkHiddenCallConv}

proc flatNode(par: PNode, outNodes: var seq[PNode]) =
  # outNodes.add par
  for n in par:
    case n.kind
    of nkEmpty:
      continue
    of CallNodes:
      discard
    else:
      discard
    outNodes.add n
    flatNode(n, outNodes)

proc `$`*(node: PNode): string =
  ## Get the string of an identifier node.
  case node.kind
  of nkPostfix, nkInfix:
    result = $node[0].ident.s
  of nkIdent:
    result = $node.ident.s
  of nkPrefix:
    result = $node.ident.s
  of nkStrLit..nkTripleStrLit, nkCommentStmt, nkSym:
    result = node.strVal
  # of nnkOpenSymChoice, nnkClosedSymChoice:
  #   result = $node[0]
  of nkAccQuoted:
    result = $node[0]
  else:
    discard

proc parseTokens*(source: string): seq[GeneralTokenizer] =

  # TNode*{.final, acyclic.} = object # on a 32bit machine, this takes 32 bytes
  #   when defined(useNodeIds):
  #     id*: int
  #   typ*: PType
  #   info*: TLineInfo
  #   flags*: TNodeFlags
  #   case kind*: TNodeKind
  #   of nkCharLit..nkUInt64Lit:
  #     intVal*: BiggestInt
  #   of nkFloatLit..nkFloat128Lit:
  #     floatVal*: BiggestFloat
  #   of nkStrLit..nkTripleStrLit:
  #     strVal*: string
  #   of nkSym:
  #     sym*: PSym
  # TSym* {.a
  # case kind*: TSymKind
  #   of routineKinds:
  #     #procInstCache*: seq[PInstantiation]
  #     gcUnsafetyReason*: PSym  # for better error messages wrt gcsafe
  #     transformedBody*: PNode  # cached body after transf pass
  #   of skLet, skVar, skField, skForVar:
  #     guard*: PSym
  #     bitsize*: int
  #     alignment*: int # for alignment
  # case kind*: TNodeKind
  #   of nkCharLit..nkUInt64Lit:
  #     intVal*: BiggestInt
  #   of nkFloatLit..nkFloat128Lit:
  #     floatVal*: BiggestFloat
  #   of nkStrLit..nkTripleStrLit:
  #     strVal*: string
  #   of nkSym:
  #     sym*: PSym
  #   of nkIdent:
  #     ident*: PIdent
  #
  # var result = newSeq[GeneralTokenizer]()
  let node = parsePNodeStr(source)


  var outNodes = newSeq[PNode]()
  flatNode(node, outNodes)

  # TLineInfo* = object          # This is designed to be as small as possible,
  #                              # because it is used
  #                              # in syntax nodes. We save space here by using
  #                              # two int16 and an int32.
  #                              # On 64 bit and on 32 bit systems this is
  #                              # only 8 bytes.
  #   line*: uint16
  #   col*: int16
  #   fileIndex*: FileIndex
  #   when defined(nimpretty):
  #     offsetA*, offsetB*: int
  #     commentOffsetA*, commentOffsetB*: int

  # nkLiterals* = {nkCharLit..nkTripleStrLit}
  # nkFloatLiterals* = {nkFloatLit..nkFloat128Lit}
  # nkLambdaKinds* = {nkLambda, nkDo}
  # declarativeDefs* = {nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef}
  # routineDefs* = declarativeDefs + {nkMacroDef, nkTemplateDef}
  # procDefs* = nkLambdaKinds + declarativeDefs
  # callableDefs* = nkLambdaKinds + routineDefs
  for n in outNodes:
    case n.kind
    of nkEmpty:
      continue
    of nkMixinStmt:
      result.add initNimKeyword(n, "mixin",
          tKind = n.kind)
    of nkImportStmt:
      result.add initNimKeyword(n, "import",
          tKind = n.kind)
    of nkNilLit:
      result.add initNimKeyword(n, "nil",
          tKind = n.kind)
    of nkCharLit .. nkUInt64Lit:
      # intVal
      let val = $n.intVal
      result.add initNimToken(TokenClass.gtOctNumber, n.info.offsetA, n.info.offsetB - n.info.offsetA + 1, val,
          tKind = n.kind)
    of nkFloatLit..nkFloat128Lit:
      # floatVal*: BiggestFloat
      result.add initNimToken(TokenClass.gtDecNumber, n.info.offsetA, n.info.offsetB - n.info.offsetA + 1, $n.floatVal,
          tKind = n.kind)
    of nkStrLit .. nkTripleStrLit:
      # strVal*: string
      result.add initNimToken(TokenClass.gtStringLit, n.info.offsetA, n.info.offsetB - n.info.offsetA + 1, n.strVal,
          tKind = n.kind)
    # of nkSym:
    #   # sym*: PSym
    #   case n.sym.kind
    #     of skResult:
    #       result.add initNimToken(TokenClass.gtSpecialVar,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)

    #       # skProcKinds* = {skProc, skFunc, skTemplate, skMacro, skIterator,
    #       #         skMethod, skConverter}
    #       # routineKinds* = {skProc, skFunc, skMethod, skIterator,
    #       #          skConverter, skMacro, skTemplate}
    #     of skProcKinds: # https://github.com/nim-lang/Nim/blob/97fc95012d2725b625c492b6b72336a89c501076/compiler/ast.nim#L609
    #       result.add initNimToken(TokenClass.gtOperator,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
    #     else:
    #       echo "sym:",n.sym.kind
    #       result.add initNimToken(TokenClass.gtKeyword,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
    of nkTypeSection:
      # let n = n[0]
      # echo repr n
      # result.add initNimKeyword(n,"type",
      #     tKind = n.kind)
      discard
    of nkGenericParams:
      discard
    of nkTypeClassTy:
      discard
    of nkBracketExpr:
      discard
    of nkFormalParams:
      discard
    of nkProcTy:
      result.add initNimKeyword(n, "proc",
          tKind = n.kind)
    of nkTypeDef:
      result.add initNimKeyword(n, "type",
          tKind = n.kind)
    of nkObjectTy:
      result.add initNimKeyword(n, "object",
          tKind = n.kind)
    of nkStmtList:
      discard
    of nkRecList:
      discard
    of nkIdentDefs:
      discard
    of nkExprColonExpr:
      discard
    of nkTableConstr:
      discard
    # of nkAccQuoted:
    #   continue
    #   let n = n[0]
    #   result.add initNimToken(nimGetKeyword(n.ident.s), n.info.offsetA, n.info.offsetB - n.info.offsetA + 1, n.ident.s,
    #         tKind = n.kind)
    of nkIdentKinds - {nkAccQuoted}:
      # ident*: PIdent
      result.add initNimToken(nimGetKeyword(n.ident.s), n.info.offsetA, n.info.offsetB - n.info.offsetA + 1, n.ident.s,
          tKind = n.kind)
    of nkCallKinds - {nkInfix, nkPostfix}:
      let id = $n[0]
      result.add initNimToken(TokenClass.gtFunctionName, n[0].info.offsetA, n[0].info.offsetB - n[0].info.offsetA + 1,
          id, tKind = n.kind)
    of nkInfix:
      result.add initNimToken(TokenClass.gtOperator, n[0].info.offsetA, n[0].info.offsetB - n[0].info.offsetA + 1, $n,
          tKind = n.kind)
    of nkPostfix:
      result.add initNimToken(TokenClass.gtSpecialVar, n[0].info.offsetA, n[0].info.offsetB - n[0].info.offsetA + 1, $n,
          tKind = n.kind)
    else:
      # source[ n.info.offsetA .. n.info.offsetB]
      let buf = $n
      result.add initNimToken(TokenClass.gtIdentifier, n.info.offsetA, n.info.offsetB - n.info.offsetA + 1, buf,
          tKind = n.kind)

