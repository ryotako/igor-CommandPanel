#include "MinTest"

static Function setup()
	DuplicateDataFolder root:Packages:CommandPanel root:Packages:TestCommandPanel
	KillDataFolder root:Packages:CommandPanel
	
	String wins=WinList("CommandPanel*",";","WIN:64")
	Variable i,N = ItemsInList(wins)
	for(i=0;i<N;i+=1)
		KillWindow $StringFromList(i,wins)
		print StringFromList(i,wins)
	endfor
End

static Function teardown()
	KillDataFolder root:Packages:TestCommandPanel
//	DuplicateDataFolder root:Packages:CommandPanel root:Packages:TestCommandPanel

End

static Function/WAVE null()
	Make/FREE/T/N=0 w; return w
End

Function TestCommandPanel_New()
	setup()
	CommandPanel_New()
	eq_str(WinList("CommandPanel0",";",""),"CommandPanel0;")
	
	eq_text(root:Packages:buffer, null())
	
	teardown()
End