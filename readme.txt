mount c: c:/
c:
cd tasm/bin

cycles=max

tasm /zi Hockey.asm

tlink /v Hockey.obj

Hockey