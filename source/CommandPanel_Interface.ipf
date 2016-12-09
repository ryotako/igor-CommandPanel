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
	MakePanel()
End

Function/S CommandPanel_GetLine()
	return GetStr("CommandLine")
End

Function CommandPanel_SetLine(str)
	String str

	SetStr("CommandLine",str)
	SetVar("LineChanged",1)
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
	CommandPanel_SelectRow(0)
	SetVar("BufferChanged",1)
End

Function CommandPanel_SelectedRow()
	Variable n

	String win = StringFromList(0, WinList("CommandPanel*",";","WIN:64"))
	if(strlen(win))
		ControlInfo/W=$win CPBuffer
		return V_Value
	endif
End

Function CommandPanel_SelectRow(n)
	Variable n

	String win = StringFromList(0, WinList("CommandPanel*",";","WIN:64"))
	if(strlen(win))
		ListBox CPBuffer, win=$win, row=n, selrow=n
	endif
End

/////////////////////////////////////////////////////////////////////////////////
// Panel Function ///////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

static Function MakePanel()
	Variable width = CommandPanel_WinWidth
	Variable height = CommandPanel_WinHeight
	NewPanel/K=1/W=(0, 0, width, height)/N = CommandPanel
	String win = S_Name
	
	// Title
	DoWindow/T $win, WinTitle()

	// Window hook
	SetWindow $win, hook(base) = CommandPanel_Interface#WinProc

	// Controls & their values
	GetStr("CommandLine")
	GetTextWave("buffer")
	SetVariable CPLine, title = " ", value = $PackageFolderPath()+"S_CommandLine"
	ListBox   CPBuffer, mode = 2, listWave = $PackageFolderPath()+"W_buffer"
	ResizeControls(win)

	// Control actions
 	SetVariable CPLine, proc=CommandPanel_Interface#LineAction
	ListBox   CPBuffer, proc=CommandPanel_Interface#BufferAction

	// Font
	String font
	if(FindListItem(CommandPanel_Font,FontList(";")) >= 0)
		font = CommandPanel_Font
	else
		font = GetDefaultFont("")
	endif
	Execute "SetVariable CPLine, font =$\"" + font + "\""
	Execute "ListBox   CPBuffer, font =$\"" + font + "\""
	
	SetVariable CPLine, fSize = CommandPanel_FontSize
	ListBox   CPBuffer, fSize = CommandPanel_FontSize

	// Activate
	Execute/P/Q "SetVariable CPLine, activate"
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

// Resize
static Function ResizeControls(win)
	String win
	
	GetWindow $win, wsizeDC
	Variable width=V_Right-V_Left, height=V_Bottom-V_Top
	ControlInfo/W=$win CPLine
	Variable height_in=V_height, height_out=height-height_in
	SetVariable CPLine, win=$win, pos={0, 0},         size={width, height_in}
	ListBox   CPBuffer, win=$win, pos={0, height_in}, size={width, height_out}
End

////////////////////////////////////////////////////////////////////////////////
// Window hook & control actions ///////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// Window hook
static Function WinProc(s)
	STRUCT WMWinHookStruct &s
	if(  s.eventCode == 0 || s.eventCode == 6 ) // activate & resize
		ResizeControls(s.winName)
	endif
End

// Control actions
static Function LineAction(line)
	STRUCT WMSetVariableAction &line
	
	DoWindow/T $line.win, WinTitle()

	if(line.eventCode == 2) // key input
		Variable key = line.eventMod
		
		if(CommandPanel_KeySwap)
			key = (key == 0) ? 2 : ( key == 2 ) ? 0 : key
		endif
		
		switch(key)
			case 0: // Enter
				CommandPanel_Execute#ExecuteLine()
				//DoWindow/F $line.win
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
		SetVariable CPLine, win=$line.win, activate
	endif
End

static Function BufferAction(buffer)
	STRUCT WMListboxAction &buffer
	
	if(buffer.eventCode == 3) // double click 
		CommandPanel_SetLine(CommandPanel_GetLine() + buffer.listWave[buffer.row])
	endif
	
	if(buffer.eventCode > 0) // except for closing 
		DoWindow/T $buffer.win, WinTitle()
		SetVariable CPLine, win=$buffer.win, activate
	endif
End

////////////////////////////////////////////////////////////////////////////////
// Accessor for package parameters /////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static Function/S PackageFolderPath()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:CommandPanel
	return "root:Packages:CommandPanel:"
End 

static Function/WAVE GetTextWave(name)
	String name
	
	String path = PackageFolderPath() + "W_" + name
	WAVE/T w = $path
	if( !WaveExists(w) )
		Make/O/T/N=0 $path/WAVE=w
	endif

	return w
End

static Function SetTextWave(name,w)
	String name; WAVE/T w
	
	String path = PackageFolderPath() + "W_" + name	
	if( !WaveRefsEqual(w, $path) )
		Duplicate/T/O w $path
	endif
End

static Function GetVar(name)
	String name
	
	String path = PackageFolderPath() + "V_" + name
	NVAR v = $path
	if( !NVAR_Exists(v) )
		Variable/G $path
		NVAR v = $path
	endif
	return v
End

static Function SetVar(name, v)
	String name; Variable v

	String path = PackageFolderPath() + "V_" + name
	NVAR target = $path
	if( !NVAR_Exists(target) )
		Variable/G $path
		NVAR target = $path
	endif
	target = v
End

static Function/S GetStr(name)
	String name
	
	String path = PackageFolderPath() + "S_" + name
	SVAR s = $path
	if( !SVAR_Exists(s) )
		String/G $path
		SVAR s = $path
	endif
	return s
End

static Function SetStr(name, s)
	String name, s
	
	String path = PackageFolderPath() + "S_" + name
	SVAR target = $path
	if( !SVAR_Exists(target) )
		String/G $path
		SVAR target = $path
	endif
	target = s
End


