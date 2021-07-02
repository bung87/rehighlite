
import strutils
import ./rehighlite/pnode_parse
from algorithm import binarySearch
import packages/docutils/highlite except GeneralTokenizer, TokenClass
include ./rehighlite/moe

type
  TokenClass* = enum
    gtEof, gtNone, gtWhitespace, gtDecNumber, gtBinNumber, gtHexNumber,
    gtOctNumber, gtFloatNumber, gtIdentifier, gtKeyword, gtStringLit,
    gtLongStringLit, gtCharLit, gtEscapeSequence, # escape sequence like \xff
    gtOperator, gtPunctuation, gtComment, gtLongComment, gtRegularExpression,
    gtTagStart, gtTagEnd, gtKey, gtValue, gtRawData, gtAssembler,
    gtPreprocessor, gtDirective, gtCommand, gtRule, gtHyperlink, gtLabel,
    gtReference, gtOther, gtBoolean, gtSpecialVar, gtBuiltin, gtFunctionName,gtTypeName

proc nimGetKeyword(id: string): TokenClass =
  for k in nimKeywords:
    if cmpIgnoreStyle(id, k) == 0: return gtKeyword
  if binarySearch(nimBooleans, id) > -1: return gtBoolean
  if binarySearch(nimSpecialVars, id) > -1: return gtSpecialVar
  if binarySearch(nimBuiltins, id) > -1: return gtBuiltin
  if id[0] in {'A' .. 'Z'}: return gtTypeName
  result = gtIdentifier

type GeneralTokenizer* = object of RootObj
  kind*: TokenClass
  tKind*: TNodeKind
  start*, length*: int
  buf: cstring
  # pos: int
  # state: TokenClass
  # lang: SourceLanguage



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

proc initNimToken(kind: TokenClass; start: int, buf: string, tKind: TNodeKind): GeneralTokenizer {.inline.} =
  result = GeneralTokenizer(kind: kind, start: start, length: buf.len, buf: buf.cstring,
      tKind: tKind)

proc initNimKeyword(start: int, buf: string, tKind: TNodeKind): GeneralTokenizer {.inline.} =
  result = GeneralTokenizer(kind: TokenClass.gtKeyword, start: start, length: buf.len, buf: buf.cstring,
      tKind: tKind)

proc initNimKeyword(n: PNode, buf: string, tKind: TNodeKind): GeneralTokenizer =
  let start = n.info.offsetA
  let length = if n.info.offsetB == n.info.offsetA: buf.len else: n.info.offsetB - n.info.offsetA + 1
  result = GeneralTokenizer(kind: TokenClass.gtKeyword, start: start, length: length, buf: buf.cstring,
      tKind: tKind) #, lang: SourceLanguage.langNim)

const CallNodes = {nkCall, nkInfix, nkPrefix, nkPostfix, nkCommand,
             nkCallStrLit, nkHiddenCallConv}

proc flatNode(par: PNode, outNodes: var seq[PNode]) =
  # outNodes.add par
  var d: PNode
  for n in par:
    d = n
    case n.kind
    of nkEmpty:
      continue
    of nkForStmt:
      for s in n.sons[^2 .. ^1]:
        flatNode(s, outNodes)
      outNodes.add d
      continue
    of nkProcDef:
      for s in n.sons[1 .. ^1]:
        flatNode(s, outNodes)
      d.sons.setLen(1)
      outNodes.add d
      continue
    of {nkCall, nkCommand}:
      d.sons.setLen(1)
      outNodes.add d
      for s in n.sons[1 .. ^1]:
        flatNode(s, outNodes)
      continue
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

proc basename*(a: PNode): PNode {.raises: [].} =
  ## Pull an identifier from prefix/postfix expressions.
  case a.kind
  of nkIdent: result = a
  of nkPostfix, nkPrefix:result = a[1]
  of nkPragmaExpr: result = basename(a[0])
  of nkExprColonExpr: result = a[0]
  else:
    discard

proc parseTokens*(source: string): seq[GeneralTokenizer] =
  let node = parsePNodeStr(source)
  var outNodes = newSeq[PNode]()
  flatNode(node, outNodes)

  for n in outNodes:
    case n.kind
    of nkObjConstr:
      result.add initNimToken(TokenClass.gtTypeName, n[0].info.offsetA, n[0].ident.s,
        tKind = n.kind)
    of nkEmpty, nkPar, nkBracket, nkAsgn, nkConstSection:
      continue
    of nkYieldStmt:
      result.add initNimKeyword(n, "yield",
       tKind = n.kind)
    of nkVarTy:
      result.add initNimKeyword(n, "var",
       tKind = n.kind)
    of nkPragma:
      result.add initNimKeyword(n[0], $n[0].basename(),
      tKind = n.kind)
    of nkProcDef:
      result.add initNimKeyword(n, "proc",
      tKind = n.kind)
      result.add initNimToken(TokenClass.gtFunctionName, n[0].info.offsetA, $ n[0].basename(),
        tKind = n.kind)
    of nkIncludeStmt:
      result.add initNimKeyword(n, "include",
       tKind = n.kind)
    of nkFromStmt:
      result.add initNimKeyword(n[0].info.offsetA, "from",
          tKind = n.kind)
    of nkImportExceptStmt:
      result.add initNimKeyword(n, "import",
        tKind = n.kind)
      let inStart = n[0].info.offsetB
      result.add initNimKeyword(inStart, "except",
        tKind = n.kind)
    of nkExportStmt:
      result.add initNimKeyword(n, "export",
        tKind = n.kind)
    of nkExportExceptStmt:
      result.add initNimKeyword(n, "export",
        tKind = n.kind)
    of nkConstDef:
      result.add initNimKeyword(n, "const",
        tKind = n.kind)
    of nkMacroDef:
      result.add initNimKeyword(n, "macro",
        tKind = n.kind)
    of nkVarSection:
      result.add initNimKeyword(n, "var",
        tKind = n.kind)
    of nkLetSection:
      result.add initNimKeyword(n, "let",
        tKind = n.kind)
    of nkIteratorDef:
      result.add initNimKeyword(n, "iterator",
       tKind = n.kind)
    of nkIfStmt:
      result.add initNimKeyword(n, "if",
        tKind = n.kind)
    of nkReturnStmt:
      result.add initNimKeyword(n, "return",
        tKind = n.kind)
    of nkBlockStmt:
      result.add initNimKeyword(n, "block",
        tKind = n.kind)
    of nkExceptBranch:
      result.add initNimKeyword(n, "except",
       tKind = n.kind)
    of nkWhileStmt:
      result.add initNimKeyword(n, "while",
        tKind = n.kind)
    of nkTryStmt:
      result.add initNimKeyword(n, "try",
        tKind = n.kind)
    of nkForStmt:
      let inStart = n[^2].info.offsetA - 3
      result.add initNimKeyword(n, "for",
        tKind = n.kind)
      result.add initNimKeyword(inStart, "in",
        tKind = nkIdent)
    of nkCaseStmt:
      result.add initNimKeyword(n, "case",
        tKind = n.kind)
    of nkContinueStmt:
      result.add initNimKeyword(n, "continue",
       tKind = n.kind)
    of nkAsmStmt:
      result.add initNimKeyword(n, "asm",
        tKind = n.kind)
    of nkDiscardStmt:
      result.add initNimKeyword(n, "discard",
        tKind = n.kind)
    of nkBreakStmt:
      result.add initNimKeyword(n, "break",
        tKind = n.kind)
    of nkElifBranch:
      result.add initNimKeyword(n, "elif",
        tKind = n.kind)
    of nkElse:
      result.add initNimKeyword(n, "else",
       tKind = n.kind)
    of nkOfBranch:
      result.add initNimKeyword(n, "of",
       tKind = n.kind)
    of nkCast:
      result.add initNimKeyword(n, "cast",
        tKind = n.kind)
    of nkMixinStmt:
      result.add initNimKeyword(n, "mixin",
          tKind = n.kind)
    of nkTemplateDef:
      result.add initNimKeyword(n, "template",
          tKind = n.kind)
    of nkImportStmt:
      result.add initNimKeyword(n, "import",
          tKind = n.kind)
    of nkNilLit:
      result.add initNimKeyword(n, "nil",
          tKind = n.kind)
    of nkCharLit:
      let val = $n.intVal.char
      result.add initNimToken(TokenClass.gtOctNumber, n.info.offsetA, val,
          tKind = n.kind)
    of nkIntLit .. nkUInt64Lit:
      # intVal
      let val = $n.getInt
      result.add initNimToken(TokenClass.gtOctNumber, n.info.offsetA, val,
          tKind = n.kind)
    of nkFloatLit..nkFloat128Lit:
      # floatVal*: BiggestFloat
      result.add initNimToken(TokenClass.gtDecNumber, n.info.offsetA, $n.floatVal,
          tKind = n.kind)
    of nkStrLit .. nkTripleStrLit:
      # strVal*: string
      result.add initNimToken(TokenClass.gtStringLit, n.info.offsetA, n.strVal,
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
    of nkDotExpr:
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
    of nkIdentKinds - {nkAccQuoted}:
      # ident*: PIdent
      result.add initNimToken(nimGetKeyword(n.ident.s), n.info.offsetA, n.ident.s,
          tKind = n.kind)
    of nkAccQuoted:
      discard
    of nkCallKinds - {nkInfix, nkPostfix, nkDotExpr}:
      let id = $n[0]
      let tok = initNimToken(TokenClass.gtFunctionName, n[0].info.offsetA,
          id, tKind = n.kind)
      if tok.buf.len > 0:
        result.add tok
    of nkInfix:
      if $n[0] == "as":
        result.add initNimKeyword(n[0].info.offsetA, "as",
          tKind = n.kind)
      else:
        result.add initNimToken(TokenClass.gtOperator, n[0].info.offsetA, $n,
          tKind = n.kind)
    of nkPostfix:
      result.add initNimToken(TokenClass.gtSpecialVar, n[0].info.offsetA, $n,
          tKind = n.kind)
    else:
      # source[ n.info.offsetA .. n.info.offsetB]
      let buf = $n
      result.add initNimToken(TokenClass.gtIdentifier, n.info.offsetA, buf,
          tKind = n.kind)

