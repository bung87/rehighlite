include compiler/sempass2
import ../minclude
from os import nil
minclude(os.joinPath( "compiler" , "sempass2.nim"))

const
  semTrackEffects* = track
  semInitEffects* = initEffects
  semTrackCall* = trackCall

type TSemEffects* = TEffects
