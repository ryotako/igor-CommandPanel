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
	Duplicate/FREE/T GetTxtWave("buffer") w
	w = ReplaceString("\\\\", w, "\\")
	return w
End

Function CommandPanel_SetBuffer(w [, word, line, buffer])
	WAVE/T/Z w, word, line, buffer

	if(WaveExists(w))
		SetTxtWave("line", w)
		SetTxtWave("word", w)
		
		Make/FREE/T/N=(DimSize(w, 0)) w_buf = ReplaceString("\\", w, "\\\\")
		SetTxtWave("buffer", w_buf)
	endif
	if(!ParamIsDefault(word))
		SetTxtWave("word", word)	
	endif
	if(!ParamIsDefault(line))
		SetTxtWave("line", line)	
	endif
	if(!ParamIsDefault(buffer))
		buffer = ReplaceString("\\", buffer, "\\\\")
		SetTxtWave("buffer", buffer)
	endif
	SetVar("BufferChanged", 1)

	Make/FREE/D/N=(DimSize(CommandPanel_GetBuffer(), 0)) select
	SetNumWave("select", select)
	CommandPanel_SelectRow(0)
End

Function CommandPanel_SelectedRow()
	WAVE select = GetNumWave("select")
	Variable n = WaveMin(CommandPanel_SelectedRows())
	return n == n ? n : 0
End

Function/WAVE CommandPanel_SelectedRows()
	WAVE select = GetNumWave("select")
	Make/FREE/N=(DimSize(select, 0)) buf = p
	Extract/O buf, buf, select
	return buf
End

Function CommandPanel_SelectRow(n)
	Variable n
	
	CommandPanel_SelectRows({n})
	
	String win = StringFromList(0, WinList("CommandPanel*", ";", "WIN:64"))
	if(strlen(win))
		ListBox CPBuffer, win = $win, row = n
	endif
End

Function CommandPanel_SelectRows(w)
	WAVE/Z w
	
	Make/FREE/N=(DimSize(GetNumWave("select"), 0)) select = 0	
	Variable i, N = DimSize(w, 0)
	for(i = 0; i < N; i += 1)
		select[w[i]] = 1
	endfor

	SetNumWave("select" ,select)
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
	SetVariable CPLine, title = " "
	SetVariable CPLine, value = $PackagePath()+"S_CommandLine"


	GetTxtWave("buffer")
	GetNumWave("select")
	ListBox CPBuffer, mode = 9
	ListBox CPBuffer, listWave = $PackagePath()+"W_buffer"
	ListBox CPBuffer, selWave = $PackagePath()+"W_select"

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

#if Exists("PanelResolution") != 3
Static Function PanelResolution(wName) // For compatibility between Igor 6 & 7
	String wName
	return 72 // that is, "pixels"
End
#endif

// Resize
static Function ResizeControls(win)
	String win

	if( PanelResolution(win) == 72 )
		GetWindow $win wsizeDC		// the new window size in pixels (the Igor 6 way)
	else
		GetWindow $win wsize		// the new window size in points (the Igor 7 way, sometimes)
	endif

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
static Function LineAction(s)
	STRUCT WMSetVariableAction &s
	
	DoWindow/T $s.win, WinTitle()

	if(s.eventCode == 2) // key input
		Variable key = s.eventMod
		
		if(CommandPanel_KeySwap)
			key = (key == 0) ? 2 : ( key == 2 ) ? 0 : key
		endif
		
		switch(key)
			case 0: // Enter
				CommandPanel_Execute#ExecuteLine()
				if(IgorVersion()<7)
					SetVariable CPLine, win=$s.win, activate
				endif
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
		SetVariable CPLine, win=$s.win, activate
	endif
End

static Function BufferAction(s)
	STRUCT WMListboxAction &s
	PauseUpdate
	if(s.eventCode == 1)
		if(s.eventMod > 15)
			CommandPanel_SelectRows(GetNumWave("selectedRows"))
			DoUpdate
			PopupContextualMenu "execute"
			
			WAVE/T buf = CommandPanel_GetBuffer()
			WAVE sel = CommandPanel_SelectedRows()
			Variable i, N = DimSize(sel, 0)

			strSwitch(S_selection)
				case "execute":
					String cmd = ""
					for(i = 0; i < N; i += 1)
						cmd += buf[sel[i]] + ";; "
					endfor
					cmd = RemoveEnding(cmd, ";; ")
									
					// Execute selected rows
					CommandPanel_SetLine(cmd)
					CommandPanel_Execute#ExecuteLine()
					break
			endSwitch
		endif
	endif

	SetNumWave("selectedRows", CommandPanel_SelectedRows())
	
	if(s.eventCode == 3) // double click
		WAVE/T w = GetTxtWave("line")
		CommandPanel_SetLine(CommandPanel_GetLine() + w[s.row])
	endif
	
	if(s.eventCode > 0) // except for closing 
		DoWindow/T $s.win, WinTitle()
		SetVariable CPLine, win=$s.win, activate
	endif
End

////////////////////////////////////////////////////////////////////////////////
// Accessor for package parameters /////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static Function/S PackagePath()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:CommandPanel
	return "root:Packages:CommandPanel:"
End 

static Function/WAVE GetNumWave(name)
	String name
	
	String path = PackagePath() + "W_" + name
	WAVE/Z w = $path
	if( !WaveExists(w) )
		Make/O/N=0 $path/WAVE=w
	endif

	return w
End

static Function SetNumWave(name,w)
	String name; WAVE w
	
	String path = PackagePath() + "W_" + name	
	if( !WaveRefsEqual(w, $path) )
		Duplicate/O w $path
	endif
End

static Function/WAVE GetTxtWave(name)
	String name
	
	String path = PackagePath() + "W_" + name
	WAVE/T/Z w = $path
	if( !WaveExists(w) )
		Make/O/T/N=0 $path/WAVE=w
	endif

	return w
End

static Function SetTxtWave(name,w)
	String name; WAVE/T w
	
	String path = PackagePath() + "W_" + name	
	if( !WaveRefsEqual(w, $path) )
		Duplicate/T/O w $path
	endif
End

static Function GetVar(name)
	String name
	
	String path = PackagePath() + "V_" + name
	NVAR/Z v = $path
	if( !NVAR_Exists(v) )
		Variable/G $path
		NVAR v = $path
	endif
	return v
End

static Function SetVar(name, v)
	String name; Variable v

	String path = PackagePath() + "V_" + name
	NVAR/Z target = $path
	if( !NVAR_Exists(target) )
		Variable/G $path
		NVAR target = $path
	endif
	target = v
End

static Function/S GetStr(name)
	String name
	
	String path = PackagePath() + "S_" + name
	SVAR/Z s = $path
	if( !SVAR_Exists(s) )
		String/G $path
		SVAR s = $path
	endif
	return s
End

static Function SetStr(name, s)
	String name, s
	
	String path = PackagePath() + "S_" + name
	SVAR/Z target = $path
	if( !SVAR_Exists(target) )
		String/G $path
		SVAR target = $path
	endif
	target = s
End


