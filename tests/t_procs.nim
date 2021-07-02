import rehighlite
import os
const mockDir = currentSourcePath.parentDir / "mock"
for t in parseTokens(readFile(mockDir / "m_procs.nim")):
  echo t
