#include ":CommandPanel_Interface"
#include ":CommandPanel_Expand"
#include "writer"
#pragma ModuleName=CommandPanel_Execute

// history options
constant CommandPanel_HistEraseDups = 0
constant CommandPanel_HistIgnoreDups = 0
constant CommandPanel_HistIgnoreSpace = 0
strconstant CommandPanel_HistIgnore = ";"

Function CommandPanel_Execute(s)
	String s
	if(strlen(s))
		Variable error; String out
		ExpandAndExecute(s,out,error)
		return error
	else
		return 0
	endif
End

static Function ExecuteWithLog()
	// initialize
	InitAlias()
	CommandPanel_Interface#SetFlag("LineChanged",0)
	CommandPanel_Interface#SetFlag("BufferChanged",0)

	// get command
	String input=CommandPanel_GetLine()
	if(strlen(input)==0)
		ShowHistory()
		return NaN
	endif

	// expand command
	WAVE/T cmds =CommandPanel_Expand#Expand(input)
	if(DimSize(commands,0)==0)
		Make/FREE/T cmds = {input}
	endif

	// execute command
	Variable error
	String output=""
	ExpandAndExecute(input,output,error)
	
	// history
	if(!error)
		AddHistory(input)
		if( ! CommandPanel_Interface#GetFlag("LineChanged") )
			CommandPanel_SetLine("")
		endif
	endif
	
	// output
	if( CommandPanel_Interface#GetFlag("BufferChanged") )
		return NaN
	elseif( strlen(output) )
		CommandPanel_SetBuffer( writer#split(output,"\r") )
	else		
		ShowHistory()
	endif
	
	DoWindow/F $CommandPanel_interface#GetWinName()
End

// expand input and execute
// return output and error code with string and variable references
static Function ExpandAndExecute(input,output,error)
	String input,&output; Variable &error
	WAVE/T cmds =CommandPanel_Expand#Expand(input)
	if(DimSize(commands,0)==0)
		Make/FREE/T cmds = {input}
	endif
	Variable i,N=DimSize(cmds,0)
	for(i=0;i<N;i+=1)
		PrintCommand(cmds[i])
		Variable ref = CaptureHistoryStart()
		Execute/Z cmds[i]
		error = V_Flag
		output += CaptureHistory(ref,ref)
		if(error) // when an error occurs, stop execution 
			print GetErrMessage(error)
			break
		endif
	endfor
End

// Util
static Function PrintCommand(s)
	String s
	print num2char(cmpstr(IgorInfo(2),"Macintosh") ? 42 : -91)+s+"\r"
End

// Alias
static Function Alias(s)
	String s
	if(strlen(s))
		return CommandPanel_Expand#SetAlias(s)		
	endif
	CommandPanel_SetBuffer( CommandPanel_Interface#GetTextWave("alias") )
End 
static Function InitAlias()
	WAVE/T w=CommandPanel_Expand#GetAlias()
	if(DimSize(w,0)==0)
		CommandPanel_Expand#SetAlias("alias=CommandPanel_Execute#Alias")
	endif
End

// History
static Function/WAVE AddHistory(command)
	String command
	WAVE/T history=CommandPanel_Interface#GetTextWave("history")
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

static Function ShowHistory()
	CommandPanel_SetBuffer( CommandPanel_Interface#GetTextWave("history") )
End
