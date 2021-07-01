

import rehighlite
import os
const mockDir = currentSourcePath.parentDir / "mock"
discard parseTokens(readFile(mockDir / "simple.nim"))
