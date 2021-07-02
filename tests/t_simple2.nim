

import rehighlite
import os
const mockDir = currentSourcePath.parentDir / "mock"
for t in parseTokens(readFile(mockDir / "simple2.nim")):
  echo t
