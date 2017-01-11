#include "MinTest"
#include "CommandPanel"

//==============================================================================
// Interface
//==============================================================================

static Function Setup_Interface()
	kill_all_CommandPanel()
	
	CommandPanel_SetLine("")
	CommandPanel_SetBuffer(cast($""))
End

static Function Teardown_Interface()
	kill_all_CommandPanel()
End

static Function swap_data_folder()

End

static Function kill_all_CommandPanel()
	String wins=WinList("CommandPanel*",";","WIN:64")
	Variable i,N = ItemsInList(wins)
	for(i=0;i<N;i+=1)
		KillWindow $StringFromList(i,wins)
	endfor
End

Function TestCommandPanel_Interface()
	Setup_Interface()
	
	CommandPanel_New()
	eq_str(WinList("CommandPanel*",";","WIN:64"),"CommandPanel;")	
	eq_text(CommandPanel_GetBuffer(), $"")
	eq_str(CommandPanel_GetLine(), "")
	
	CommandPanel_SetLine("test")
	eq_str(CommandPanel_GetLine(), "test")
	CommandPanel_SetLine("test2")
	eq_str(CommandPanel_GetLine(), "test2")


	CommandPanel_SetBuffer( cast({"test"}) )
	eq_text(CommandPanel_GetBuffer(), {"test"})
	
	Teardown_Interface()
End

//==============================================================================
// Utilities
//==============================================================================

static Function/WAVE cast(w)
	WAVE/T w
	if(WaveExists(w))
		Make/FREE/T/N=0 w
	endif
	return w
End
