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
  # TLineInfo* = object
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
