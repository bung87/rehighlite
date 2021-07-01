import macros
import os 

const explicitSourcePath {.strdefine.} = os.parentDir(os.parentDir( os.getCurrentCompilerExe()))

macro mInclude*(path: static[string]): untyped =
  result = newNimNode(nnkStmtList)
  result.add(quote do:
    include `explicitSourcePath` /  `path`
  )