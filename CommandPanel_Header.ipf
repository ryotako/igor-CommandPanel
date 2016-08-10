#pragma ModuleName=CommandPanel

Function/S CommandPanel_PrototypeFunc1(s)
	String s
	return s
End
Function/WAVE CommandPanel_PrototypeFunc2(s)
	String s
	Make/FREE/T w={s}; return w
End