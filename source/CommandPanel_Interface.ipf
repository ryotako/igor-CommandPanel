#pragma ModuleName=CommandPanel_Interface
#include ":CommandPanel_Complete"
#include ":CommandPanel_Execute"
#include ":CommandPanel_Expand"
#include "Writer"

/////////////////////////////////////////////////////////////////////////////////
// Options //////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

strconstant CommandPanel_Font       = ""
constant    CommandPanel_Fontsize   = 14
constant    CommandPanel_WinHeight  = 300
constant    CommandPanel_WinWidth   = 300
strconstant CommandPanel_WinTitle   = "'['+IgorInfo(1)+'] '+GetDataFolder(1)"

constant    CommandPanel_KeySwap    = 0

/////////////////////////////////////////////////////////////////////////////////
// Public Functions /////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

Function CommandPanel_New()
	WAVE/T w=CommandPanel_GetBuffer()
	MakePanel()
	MakeControls()
	CommandPanel_SetLine("")
	CommandPanel_SetBuffer(w)
End

Function/S CommandPanel_GetLine()
	ControlInfo/W=$GetWinName() CPLine
	return SelectString(strlen(S_Value)>0,"",S_Value)
End

Function CommandPanel_SetLine(str)
	String str
	String win=GetWinName()
	if(strlen(win))
	 	SetVariable CPLine,win=$win,value= _STR:str
		SetFlag("LineChanged",1)
	endif
End

Function/WAVE CommandPanel_GetBuffer()
	Duplicate/FREE/T GetTextWave("buffer") w
	w = ReplaceString("\\\\",w,"\\")
	return w
End

Function CommandPanel_SetBuffer(w [word,line,buffer])
	WAVE/T w,word,line,buffer
	if(WaveExists(w))
		w = ReplaceString("\\",w,"\\\\")
		SetTextWave("buffer",w)
		SetTextWave("line",w)
		SetTextWave("word",w)
	endif
	if(!ParamIsDefault(word))
		SetTextWave("word",word)	
	endif
	if(!ParamIsDefault(line))
		SetTextWave("line",line)	
	endif
	if(!ParamIsDefault(buffer))
		buffer = ReplaceString("\\",buffer,"\\\\")
		SetTextWave("buffer",buffer)
	endif
	String win=GetWinName()
	if(strlen(win))
		ListBox CPBuffer, win=$win, row=0, selrow=0
		SetFlag("BufferChanged",1)
	endif
End

Function CommandPanel_SelectedRow()
	Variable n
	String win=GetWinName()
	if(strlen(win))
		ControlInfo/W=$win CPBuffer
		return V_Value
	else
		return NaN
	endif
End

Function CommandPanel_SelectRow(n)
	Variable n
	String win=GetWinName()
	if(strlen(win))
		ListBox CPBuffer, win=$win, row=n, selrow=n
	endif
End

/////////////////////////////////////////////////////////////////////////////////
// Static Functions /////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

// Window Name
//static Function/S SetWinName()
	String wins=WinList("CommandPanel"+"*",";","WIN:64")
	Make/FREE/T/N=(ItemsInList(wins)+1) f="CommandPanel"+Num2Str(p)
	Extract/FREE/T f,f,WhichListItem(f,wins)<0
	return f[0]
End

static Function/S GetWinName()
	return StringFromList(0,WinList("CommandPanel"+"*",";","WIN:64"))
End

// Make a panel and controls
static Function MakePanel()
	NewPanel/K=1/W=(0,0,CommandPanel_WinWidth,CommandPanel_WinHeight)/N=CommandPanel
	SetWindow $S_Name,hook(base)=CommandPanel_Interface#WinProc
End

static Function WinProc(s)
	STRUCT WMWinHookStruct &s
	if(  s.eventCode == 0 || s.eventCode == 6 ) // activate & resize
		GetWindow $s.winName, wsizeDC ;Variable width=V_Right-V_Left, height=V_Bottom-V_Top
		ControlInfo/W=$s.winName CPLine ;Variable height_in=V_height, height_out=height-height_in
		SetVariable CPLine, win=$s.winName, pos={0, 0},         size={width, height_in}
		ListBox   CPBuffer, win=$s.winName, pos={0, height_in}, size={width, height_out}
	endif
	
	if( s.eventCode == 11)
		print s.keycode
	endif
End 

static Function MakeControls()
	String win=GetWinName()
	// Title
	DoWindow/T $win, WinTitle()

	// Set Control Actions
 	SetVariable CPLine, win=$win, proc=CommandPanel_Interface#LineAction
	ListBox   CPBuffer, win=$win, proc=CommandPanel_Interface#BufferAction

	// Font
	String font
	if(FindListItem(CommandPanel_Font,FontList(";")) >= 0)
		font = CommandPanel_Font
	else
		font = GetDefaultFont("")
	endif
	Execute "SetVariable CPLine, win="+win+", font =$\""+font+"\""
	Execute "ListBox   CPBuffer, win="+win+", font =$\""+font+"\""
	
	SetVariable CPLine, win=$win, fSize= CommandPanel_FontSize
	ListBox   CPBuffer, win=$win, fSize= CommandPanel_FontSize

	// Other Settings
	ListBox CPBuffer,   win=$win, mode=2, listWave=root:Packages:CommandPanel:buffer
End

// Control Actions
static Function LineAction(line)
	STRUCT WMSetVariableAction &line
	
	if(line.eventCode == 2) // key input
		Variable key = line.eventMod
		
		if(CommandPanel_KeySwap)
			key = (key == 0) ? 2 : ( key == 2 ) ? 0 : key
		endif
		
		switch(key)
			case 0: // Enter
				CommandPanel_Execute#ExecuteWithLog()
				break
			case 2: // Shift + Enter
				CommandPanel_Complete#Complete()
				break
			case 4: // Alt + Enter
				CommandPanel_Complete#AltComplete()
				break
		endswitch
	endif
	
	if(IgorVersion()<7)
		SetVariable CPLine,win=$GetWinName(),activate
	endif
End

static Function BufferAction(buffer)
	STRUCT WMListboxAction &buffer
	
	if(buffer.eventCode == 3) // double click 
		CommandPanel_SetLine(CommandPanel_GetLine() + buffer.listWave[buffer.row])
	endif
	
	if(buffer.eventCode > 0) // except for closing 
		SetVariable CPLine, activate
	endif
End

// Util
static Function/WAVE GetTextWave(name)
	String name
	DFREF here=GetDataFolderDFR()
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S root:Packages:CommandPanel
	if(ItemsInList(WaveList(name,";","TEXT:1")))
		WAVE/T w=$name
	else
		Execute/Z/Q "KillWaves/Z "+name
		Make/O/T/N=0 $name/WAVE=w
	endif
	SetDataFolder here	
	return w
End

static Function SetTextWave(name,w)
	String name; WAVE/T w
	WAVE/T f=GetTextWave(name)
	if(!WaveRefsEqual(f,w))
		Duplicate/T/O w f
	endif
End

static Function GetFlag(name)
	String name
	NVAR v=$"root:Packages:CommandPanel:V_"+name
	return NVAR_Exists(v) && v!=0
End

static Function SetFlag(name,value)
	String name; Variable value
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:CommandPanel
	Variable/G $"root:Packages:CommandPanel:V_"+name = value
End

// WinTitle
static Function/S WinTitle()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:CommandPanel
	String expr = writer#gsub(CommandPanel_WinTitle,"\\\\|\\\'|\'","",proc=WinTitleSpecialChar)
	Execute "String/G root:Packages:CommandPanel:S_Title = " + expr
	SVAR s = root:Packages:CommandPanel:S_Title
	return s
End

static Function/S WinTitleSpecialChar(s)
	String s
	StrSwitch(s)
	case "\\\\":
		return s
	case "\\\'":
		return "\'"
	case "\'":
		return "\""
	default:
		return s
	EndSwitch
End
