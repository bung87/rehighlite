
import strutils
import ./rehighlite/pnode_parse

import packages/docutils/highlite except GeneralTokenizer, TokenClass

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

proc initNimToken(kind: TokenClass; start, length: int): GeneralTokenizer =
  result = GeneralTokenizer(kind: kind, start: start, length: length, lang: SourceLanguage.langNim)

const CallNodes = {nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand,
             nkCallStrLit, nkHiddenCallConv}

proc flatNode(par: PNode, outNodes: var seq[PNode]) =
  outNodes.add par
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
    of nkIntLit..nkUInt64Lit:
      result.add initNimToken(TokenClass.gtOctNumber, n.info.offsetA, n.info.offsetB - n.info.offsetA + 1)
    of nkFloatLit..nkFloat128Lit:
      # floatVal*: BiggestFloat
      result.add initNimToken(TokenClass.gtDecNumber, n.info.offsetA, n.info.offsetB - n.info.offsetA + 1)
    of nkCharLit, nkStrLit .. nkTripleStrLit:
      # strVal*: string
      result.add initNimToken(TokenClass.gtStringLit, n.info.offsetA, n.info.offsetB - n.info.offsetA + 1)
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
    of nkIdentKinds:
      # ident*: PIdent
      if n.ident.s == "result":
        result.add initNimToken(TokenClass.gtSpecialVar, n.info.offsetA, n.info.offsetB - n.info.offsetA + 1)
      else:
        # echo (n.kind,n.typ,n.ident.s)
        result.add initNimToken(TokenClass.gtIdentifier, n.info.offsetA, n.info.offsetB - n.info.offsetA + 1)
    of nkCallKinds - {nkInfix, nkPostfix}:
      result.add initNimToken(TokenClass.gtSpecialVar, n[0].info.offsetA, n[0].info.offsetB - n[0].info.offsetA + 1)
    of nkInfix:
      result.add initNimToken(TokenClass.gtOperator, n[0].info.offsetA, n[0].info.offsetB - n[0].info.offsetA + 1)
    of nkPostfix:
      result.add initNimToken(TokenClass.gtSpecialVar, n[0].info.offsetA, n[0].info.offsetB - n[0].info.offsetA + 1)
    else:
      result.add initNimToken(TokenClass.gtIdentifier, n.info.offsetA, n.info.offsetB - n.info.offsetA + 1)

  # for t in result:
  #   echo t.kind
  #   echo ex[t.start ..< t.start + t.length ]

  # skProcKinds
