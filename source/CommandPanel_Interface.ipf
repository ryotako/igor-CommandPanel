#pragma ModuleName=CommandPanel_Interface
#include ":CommandPanel_Complete"
#include ":CommandPanel_Execute"
#include ":CommandPanel_Expand"
#include "Writer"

// Options
strconstant CommandPanel_Font       = "Arial"
constant    CommandPanel_Fontsize   = 12
constant    CommandPanel_WinHeight  = 300
constant    CommandPanel_WinWidth   = 300
strconstant CommandPanel_WinTitle   = "'['+IgorInfo(1)+'] '+GetDataFolder(0)"

constant    CommandPanel_KeySwap    = 0

// Public Functions

Function CommandPanel_New()
	MakePanel()
	MakeControls()
	CommandPanel_SetLine("")
	CommandPanel_SetBuffer( CommandPanel_GetBuffer() )
End

Function/S CommandPanel_GetLine()
	ControlInfo/W=$GetWinName() CPLine
	return SelectString(strlen(S_Value)>0,"",S_Value)
End

Function CommandPanel_SetLine(str)
	String str
 	SetVariable CPLine,win=$GetWinName(),value= _STR:str
End

Function/WAVE CommandPanel_GetBuffer()
	Duplicate/FREE/T GetTextWave("buffer") w
	w = ReplaceString("\\\\",w,"\\")
	return w
End

Function CommandPanel_SetBuffer(w)
	WAVE/T w
	Duplicate/FREE/T w buf
	buf = ReplaceString("\\",w,"\\\\")
	SetTextWave("buffer",buf)
	ListBox CPBuffer, win=$GetWinName(), row=0, selrow=0
End

Function CommandPanel_SelectedRow()
	ControlInfo/W=$GetWinName() CPBuffer
	return V_Value
End

Function CommandPanel_SelectRow(n)
	Variable n
	ListBox CPBuffer, win=$GetWinName(), row=n, selrow=n
End


// Static Functions
// Window Name
static Function/S SetWinName()
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
	Variable width  = CommandPanel_WinWidth
	Variable height = CommandPanel_WinHeight
	String   name   = UniqueName("CommandPanel",9,0)
	NewPanel/K=1/W=(0,0,width,height)/N=$CommandPanel_Interface#SetWinName()
End

static Function MakeControls()
	String win=GetWinName()
	// Title
	DoWindow/T $win, WinTitle(CommandPanel_WinTitle)
	// Set Control Actions
 	SetVariable CPLine, win=$win, proc=CommandPanel_Interface#LineAction
	ListBox   CPBuffer, win=$win, proc=CommandPanel_Interface#BufferAction
	// Size
	GetWindow $win, wsizeDC ;Variable width=V_Right-V_Left, height=V_Bottom-V_Top
	ControlInfo/W=$win CPLine ;Variable height_in=V_height, height_out=height-height_in
	SetVariable CPLine, win=$win, pos={0, 0},         size={width, height_in}
	ListBox   CPBuffer, win=$win, pos={0, height_in}, size={width, height_out}
	// Font
	if(FindListItem(CommandPanel_Font,FontList(";"))>0)
		SetVariable CPLine, win=$win, font =$CommandPanel_Font
		ListBox   CPBuffer, win=$win, font =$CommandPanel_Font
	endif
	SetVariable CPLine, win=$win, fSize= CommandPanel_FontSize
	ListBox   CPBuffer, win=$win, fSize= CommandPanel_FontSize
	// Other Settings
	ListBox CPBuffer, win=$win, mode=2, listWave=root:Packages:CommandPanel:buffer
End

// Control Actions
static Function LineAction(line)
	STRUCT WMSetVariableAction &line
	if(line.eventCode>0)
		MakeControls()
	endif
		if(line.eventCode==2)
	Variable key=line.eventMod
		if(CommandPanel_KeySwap)
			key= key==0 ? 2 : ( key == 2 ? 0 : key)
		endif
		switch(key)
		case 0: // Enter
			CommandPanel_Execute#Exec()
			break
		case 2: // Shift + Enter
			CommandPanel_Complete#Complete()
			break
		case 4: // Alt + Enter
			CommandPanel_Complete#AltComplete()
			break
		endswitch
	endif
	SetVariable CPLine,win=$GetWinName(),activate
End

static Function BufferAction(buffer)
	STRUCT WMListboxAction &buffer
	if(buffer.eventCode==3)//Send a selected string by double clicks. 
		CommandPanel_SetLine(buffer.listWave[buffer.row])
	endif
	if(buffer.eventCode>0) //Redraw at any event except for closing. 
		MakeControls()
		SetVariable CPLine,win=$GetWinName(),activate
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

// WinTitle
static Function/S WinTitle(s)
	String s
	String lhs,rhs=writer#gsub(s,"\\\\|\\\'|\'","",proc=WinTitleSpecialChar)
	SVAR S_Value
	if(SVAR_Exists(S_Value))
		String tmp=S_Value
		Execute "S_Value="+rhs
		lhs=S_Value
		S_Value=tmp
	else
		String/G S_Value	
		Execute "S_Value="+rhs
		lhs=S_Value
		KillStrings/Z S_Value
	endif
	return lhs
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
