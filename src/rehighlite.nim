
import strutils
import ./rehighlite/hnimast
import ./rehighlite/hnimast/compiler_aux
import ./rehighlite/ hnimast/obj_field_macros
# import hpprint
import packages/docutils/highlite except GeneralTokenizer,TokenClass

type
  TokenClass* = enum
    gtEof, gtNone, gtWhitespace, gtDecNumber, gtBinNumber, gtHexNumber,
    gtOctNumber, gtFloatNumber, gtIdentifier, gtKeyword, gtStringLit,
    gtLongStringLit, gtCharLit, gtEscapeSequence, # escape sequence like \xff
    gtOperator, gtPunctuation, gtComment, gtLongComment, gtRegularExpression,
    gtTagStart, gtTagEnd, gtKey, gtValue, gtRawData, gtAssembler,
    gtPreprocessor, gtDirective, gtCommand, gtRule, gtHyperlink, gtLabel,
    gtReference, gtOther, gtBoolean, gtSpecialVar, gtBuiltin

type GeneralTokenizer* = object of RootObj
    kind*: TokenClass
    start*, length*: int
    buf: cstring
    pos: int
    state: TokenClass
    lang: SourceLanguage

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
    # of gtBoolean: EditorColorPair.boolean # nimBooleans = ["true", "false"]
    # of gtSpecialVar: EditorColorPair.specialVar # nimSpecialVars = ["result"]
    # of gtBuiltin: EditorColorPair.builtin # # Builtin types, objects, and exceptions
    of gtStringLit: EditorColorPair.stringLit
    of gtDecNumber: EditorColorPair.decNumber
    of gtComment: EditorColorPair.comment
    of gtLongComment: EditorColorPair.longComment
    of gtPreprocessor: EditorColorPair.preprocessor
    of gtWhitespace, gtPunctuation: EditorColorPair.defaultChar
    else:
      if isProcName: EditorColorPair.functionName
      else: EditorColorPair.defaultChar

when isMainModule:
  const ex = """
import strformat

type
  Person = object
    name: string
    age: Natural # Ensures the age is positive

let people = [
  Person(name: "John", age: 45),
  Person(name: "Kate", age: 30)
]

for person in people:
  # Type-safe string interpolation,
  # evaluated at compile time.
  echo(fmt"{person.name} is {person.age} years old")


# Thanks to Nim's 'iterator' and 'yield' constructs,
# iterators are as easy to write as ordinary
# functions. They are compiled to inline loops.
iterator oddNumbers[Idx, T](a: array[Idx, T]): T =
  for x in a:
    if x mod 2 == 1:
      yield x

for odd in oddNumbers([3, 6, 9, 12, 15, 18]):
  echo odd


# Use Nim's macro system to transform a dense
# data-centric description of x86 instructions
# into lookup tables that are used by
# assemblers and JITs.
import macros, strutils

macro toLookupTable(data: static[string]): untyped =
  result = newTree(nnkBracket)
  for w in data.split(';'):
    result.add newLit(w)

const
  data = "mov;btc;cli;xor"
  opcodes = toLookupTable(data)

for o in opcodes:
  echo o
"""
  # type ColorSegment* = object
  #   firstRow*, firstColumn*, lastRow*, lastColumn*: int
  #   color*: EditorColorPair

  # type Highlight* = object
  #   colorSegments*: seq[ColorSegment]
  # GeneralTokenizer = object of RootObj
  #   kind*: TokenClass
  #   start*, length*: int
  #   buf: cstring
  #   pos: int
  #   state: TokenClass
  
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
  var tokens = newSeq[GeneralTokenizer]()
  let node = parsePNodeStr(ex)
  const CallNodes = {nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand,
             nkCallStrLit, nkHiddenCallConv}
  proc flatNode(par:PNode,outNodes:var seq[PNode]) = 
    outNodes.add par
    for n in par:
      case n.kind
      of nkEmpty:
        continue
      of CallNodes:
        echo n.kind
        echo repr n.sons
      else:
        discard
      outNodes.add n
      flatNode(n,outNodes)
  var outNodes = newSeq[PNode]()
  flatNode(node, outNodes)
  # TokenClass* = enum
  #   gtEof, gtNone, gtWhitespace, gtDecNumber, gtBinNumber, gtHexNumber,
  #   gtOctNumber, gtFloatNumber, gtIdentifier, gtKeyword, gtStringLit,
  #   gtLongStringLit, gtCharLit, gtEscapeSequence, # escape sequence like \xff
  #   gtOperator, gtPunctuation, gtComment, gtLongComment, gtRegularExpression,
  #   gtTagStart, gtTagEnd, gtKey, gtValue, gtRawData, gtAssembler,
  #   gtPreprocessor, gtDirective, gtCommand, gtRule, gtHyperlink, gtLabel,
  #   gtReference, gtPrompt, gtProgramOutput, gtProgram, gtOption, gtOther

  # of gtKeyword: EditorColorPair.keyword
  #   of gtBoolean: EditorColorPair.boolean
  #   of gtSpecialVar: EditorColorPair.specialVar
  #   of gtBuiltin: EditorColorPair.builtin
  #   of gtStringLit: EditorColorPair.stringLit
  #   of gtDecNumber: EditorColorPair.decNumber
  #   of gtComment: EditorColorPair.comment
  #   of gtLongComment: EditorColorPair.longComment
  #   of gtPreprocessor: EditorColorPair.preprocessor
  #   of gtWhitespace, gtPunctuation: EditorColorPair.defaultChar
  #   else:
  #     if isProcName: EditorColorPair.functionName
  #     else: EditorColorPair.defaultChar
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
  proc initNimToken( kind: TokenClass;start, length: int):GeneralTokenizer = 
    result = GeneralTokenizer(kind:kind, start:start,length:length,lang:SourceLanguage.langNim)
  # nkLiterals* = {nkCharLit..nkTripleStrLit}
  # nkFloatLiterals* = {nkFloatLit..nkFloat128Lit}
  # nkLambdaKinds* = {nkLambda, nkDo}
  # declarativeDefs* = {nkProcDef, nkFuncDef, nkMethodDef, nkIteratorDef, nkConverterDef}
  # routineDefs* = declarativeDefs + {nkMacroDef, nkTemplateDef}
  # procDefs* = nkLambdaKinds + declarativeDefs
  # callableDefs* = nkLambdaKinds + routineDefs
  var inCall = false
  for n in outNodes:
    case  n.kind
    of nkEmpty:
      continue
    # of 
    of nkIntLit..nkUInt64Lit:
      tokens.add initNimToken(TokenClass.gtOctNumber,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
    of nkFloatLit..nkFloat128Lit:
      # floatVal*: BiggestFloat
      tokens.add initNimToken(TokenClass.gtDecNumber,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
    of nkCharLit,nkStrLit..nkTripleStrLit:
      # strVal*: string
      tokens.add initNimToken(TokenClass.gtStringLit,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
    # of nkSym:
    #   # sym*: PSym
    #   case n.sym.kind
    #     of skResult:
    #       tokens.add initNimToken(TokenClass.gtSpecialVar,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
          
    #       # skProcKinds* = {skProc, skFunc, skTemplate, skMacro, skIterator,
    #       #         skMethod, skConverter}
    #       # routineKinds* = {skProc, skFunc, skMethod, skIterator,
    #       #          skConverter, skMacro, skTemplate}
    #     of skProcKinds: # https://github.com/nim-lang/Nim/blob/97fc95012d2725b625c492b6b72336a89c501076/compiler/ast.nim#L609
    #       tokens.add initNimToken(TokenClass.gtOperator,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
    #     else: 
    #       echo "sym:",n.sym.kind
    #       tokens.add initNimToken(TokenClass.gtKeyword,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
    of nkIdentKinds:
      # ident*: PIdent
      if n.ident.s == "result":
        tokens.add initNimToken(TokenClass.gtSpecialVar,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
      else:
        # echo (n.kind,n.typ,n.ident.s)
        tokens.add initNimToken(TokenClass.gtIdentifier,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
    of nkCallKinds - {nkInfix}:
      tokens.add initNimToken(TokenClass.gtSpecialVar,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
    of nkInfix:
      tokens.add initNimToken(TokenClass.gtOperator,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)
    else:
      tokens.add initNimToken(TokenClass.gtNone,n.info.offsetA,n.info.offsetB - n.info.offsetA + 1)

  for t in tokens:
    echo t.kind
    echo ex[t.start ..< t.start + t.length ]
  
  # skProcKinds