#include "MinTest"
#include "CommandPanel_Interface"

#pragma ModuleName=CmdPIT

static Function setup()
	KillDataFolder/Z root:Packages:TestCommandPanel
	DuplicateDataFolder root:Packages:CommandPanel root:Packages:TestCommandPanel
	KillDataFolder/Z root:Packages:CommandPanel
	kill_all_CommandPanel()
End

static Function teardown()
	KillDataFolder/Z root:Packages:CommandPanel
	DuplicateDataFolder root:Packages:TestCommandPanel root:Packages:CommandPanel
	KillDataFolder/Z root:Packages:TestCommandPanel
	kill_all_CommandPanel()
End

static Function kill_all_CommandPanel()
	String wins=WinList("CommandPanel*",";","WIN:64")
	Variable i,N = ItemsInList(wins)
	for(i=0;i<N;i+=1)
		KillWindow $StringFromList(i,wins)
	endfor
End

Function TestCommandPanel_New()
	setup()
	
	CommandPanel_New()
	eq_str(WinList("CommandPanel*",";","WIN:64"),"CommandPanel;")	
	eq_text(CommandPanel_GetBuffer(), $"")
	eq_str(CommandPanel_GetLine(), "")
	
	CommandPanel_SetLine("test")
	eq_str(CommandPanel_GetLine(), "test")
	CommandPanel_SetLine("test2")
	eq_str(CommandPanel_GetLine(), "test2")


	CommandPanel_SetBuffer({"test"})
	eq_text(CommandPanel_GetBuffer(), {"test"})
	
	Execute/P/Q "cmdpit#teardown()"
End