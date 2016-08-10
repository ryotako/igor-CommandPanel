#include "CommandPanel_Interface"
#include "CommandPanel_Expand"
#pragma CommandPanelExecute

// history options
constant CommandPanel_HistEraseDups = 0
constant CommandPanel_HistIgnoreDups = 0
constant CommandPanel_HistIgnoreSpace = 0
strconstant CommandPanel_HistIgnore = ";"

// Public Functions {{{1
Function CommandPanel_Execute()
	String input    = CommandPanel#GetLine()
	CommandPanel#SetLine("")
	CommandPanel#GetBuffer() // reset flag
	
	// Prepare
	WAVE/T history=CommandPanel#GetTextWave("history")
	if(strlen(input)==0)
		CommandPanel#SetBuffer(history)
		return NaN
	endif

	// Execute
	WAVE/T commands = CommandPanel_Expand(input)
	if(DimSize(commands,0)==0)
		Make/FREE/T commands = {input}
	endif
	Variable ref,i,N=DimSize(commands,0); String output="",error=""
	for(i=0;i<N;i+=1)
		print num2char(cmpstr(IgorInfo(2),"Macintosh") ? 42 : -91)+commands[i]+"\r"
		ref = CaptureHistoryStart()
		Execute/Z commands[i]
		error = GetErrMessage(V_Flag)
		print error
		output += CaptureHistory(ref,ref)
		if(strlen(error))
			break
		endif
	endfor

	// Add History
	if(strlen(error))
		CommandPanel#SetBuffer(history)
		CommandPanel#SetLine(input)
	else
		AddHistory(ReplaceString("\\",input,"\\\\"))
	endif
		
	if(strlen(output))
		Make/FREE/T/N=(ItemsInList(output,"\r")) f=StringFromList(p,output,"\r")
		CommandPanel#SetBuffer(f)
	endif

	if(!CommandPanel#BufferModified())
		CommandPanel#SetBuffer(history)		
	endif
End


static Function/WAVE AddHistory(command)
	String command
	WAVE/T history=CommandPanel#GetTextWave("history")
	// Remove Duplications
	if(CommandPanel_HistEraseDups)
		Extract/T/O history,history,cmpstr(history,command)
	elseif(CommandPanel_HistIgnoreDups && cmpstr(command,history[0]) == 0)
		DeletePoints 0,1,history
	endif
	// Add History
	InsertPoints 0,1,history; history[0]=command
	// Ignore History
	if(CommandPanel_HistIgnoreSpace && StringMatch(history[0]," *"))
		DeletePoints 0,1,history
	elseif(ItemsInList(CommandPanel_HistIgnore) && strlen(command))
		Variable i,N=ItemsInList(CommandPanel_HistIgnore)
		for(i=0;i<N;i+=1)
			if(StringMatch(history[0],StringFromList(i,CommandPanel_HistIgnore)))
				DeletePoints 0,1,history
				break		
			endif
		endfor
	endif
	return history
End

