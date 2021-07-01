if cond1:
  stmt1
elif cond2:
  stmt2
elif cond3:
  stmt3
else:
  stmt4


case expr1
of expr2, expr3..expr4:
  stmt1
of expr5:
  stmt2
elif cond1:
  stmt3
else:
  stmt4


while expr1:
  stmt1

for ident1, ident2 in expr1:
  stmt1

try:
  stmt1
except e1, e2:
  stmt2
except e3:
  stmt3
except:
  stmt4
finally:
  stmt5

return expr1

continue

discard a

break otherLocation


block name:
  discard

asm """
  some asm
"""
