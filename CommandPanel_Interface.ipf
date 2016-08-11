#pragma ModuleName=CommandPanel
#include "CommandPanel_Expand"

// Options {{{1
// Appearance
strconstant CommandPanel_Font       = "Arial"
constant    CommandPanel_Fontsize   = 12
constant    CommandPanel_WinHeight  = 300
constant    CommandPanel_WinWidth   = 300
strconstant CommandPanel_WinTitle   = "\"[\"+IgorInfo(1)+\"] \"+GetDataFolder(1)"
// Behavior
constant    CommandPanel_KeySwap    = 0
constant    CommandPanel_IgnoreCase = 1
strconstant CommandPanel_Complete   = "CommandPanel_Complete()" // -> CommandPanel_Complete.ipf
strconstant CommandPanel_Execute    = "CommandPanel_Execute()"  // -> CommandPanel_Execute.ipf
constant    CommandPanel_ClickSelect   = 0
constant    CommandPanel_DClickSelect  = 1
constant    CommandPanel_DClickExecute = 0


// Constants {{{1
static strconstant CommandPanel_WinName = "CommandPanel"

// Static Functios {{{1
// Panel {{{2
Function CommandPanel_New()
	PauseUpdate; Silent 1 // building window
	// make panel
	Variable width  = CommandPanel_WinWidth
	Variable height = CommandPanel_WinHeight
	String   name   = UniqueName(CommandPanel_WinName,9,0)
	NewPanel/K=1/W=(0,0,width,height)/N=$CommandPanel#NewName()
	// make controls
	SetControls(); CommandPanel_SetLine("")
	CommandPanel_SetBuffer( CommandPanel_GetBuffer() )
	DoUpdate; ActivateLine()
	// init alias
	if(DimSize(CommandPanel_Alias(""),0)==0)
		CommandPanel_Alias("alias=CommandPanel_Alias")
	endif
End
static Function/S NewName()
	String wins=WinList(CommandPanel_WinName+"*",";","WIN:64")
	Make/FREE/T/N=(ItemsInList(wins)+1) f=CommandPanel_WinName+Num2Str(p)
	Extract/FREE/T f,f,WhichListItem(f,wins)<0
	return f[0]
End
static Function/S Target([N])
	Variable N
	N = NumType(N) || N<0 ? 0 : N
	return StringFromList(N,WinList(CommandPanel_WinName+"*",";","WIN:64"))
End

static Function SetControls()
	String win=Target()
	// Title
	NVAR flag = :V_Flag
	if(NVAR_Exists(flag))
		Variable tmp=flag
		Execute/Z/Q "DoWindow/T "+win+", "+CommandPanel_WinTitle+""
		flag=tmp
	else
		Execute/Z/Q "DoWindow/T "+win+", "+CommandPanel_WinTitle+""
		KillVariables/Z V_Flag	
	endif
	// Set Control Actions
 	SetVariable CPLine,win=$win,proc=CommandPanel#LineAction
	ListBox   CPBuffer,win=$win,proc=CommandPanel#BufferAction
	// Size
	GetWindow $win, wsizeDC ;Variable width=V_Right-V_Left, height=V_Bottom-V_Top
	ControlInfo/W=$win CPLine ;Variable height_in=V_height, height_out=height-height_in
	SetVariable CPLine,win=$win,pos={0,0},size={width,height_in}
	ListBox   CPBuffer,win=$win,pos={0,height_in},size={width,height_out}
	// Font
	if(FindListItem(CommandPanel_Font,FontList(";"))>0)
		SetVariable CPLine, win=$win, font =$CommandPanel_Font
		ListBox   CPBuffer, win=$win, font =$CommandPanel_Font
	endif
	SetVariable CPLine, win=$win, fSize= CommandPanel_FontSize
	ListBox   CPBuffer, win=$win, fSize= CommandPanel_FontSize
	// Other Settings
	ListBox CPBuffer, win=$win, mode=2,listWave=CommandPanel_GetBuffer()
End

// Command Line {{{2
Function/S CommandPanel_GetLine()
	ControlInfo/W=$Target() CPLine
	return SelectString(strlen(S_Value)>0,"",S_Value)
End
Function CommandPanel_SetLine(str)
	String str
 	SetVariable CPLine,win=$Target(),value= _STR:str
End

static Function/S ActivateLine()
	SetVariable CPLine,win=$Target(),activate
End

static Function LineAction(line)
	STRUCT WMSetVariableAction &line
	if(line.eventCode>0)
		CommandPanel#SetControls()
	endif
		if(line.eventCode==2)
	Variable key=line.eventMod
		if(CommandPanel_KeySwap)
			key= key==0 ? 2 : ( key == 2 ? 0 : key)
		endif
		switch(key)
		case 0: // Enter
			Execute/Z/Q CommandPanel_Execute
			SetVariable CPLine,win=$line.win,activate
			break
		case 2: // Shift + Enter
			if(!PossiblyScrollBuffer(1))
				if(GrepString(line.sval,"^ "))
					NarrowBuffer()
				else
					Execute/Z/Q CommandPanel_Complete
					SetVariable CPLine,win=$line.win,activate
				endif
			endif
			break
		case 4: // Alt + Enter
			PossiblyScrollBuffer(-1)
			break
		endswitch
	endif
	CommandPanel#ActivateLine()
End

// Buffer {{{2
static strconstant bufflg=root:Packages:CommandPanel:V_BufferModified
Function/WAVE CommandPanel_GetBuffer()
	NVAR flag=$bufflg
	if(NVAR_Exists(flag))
		flag=0
	endif
	return GetTextWave("buffer")
End
Function CommandPanel_SetBuffer(w)
	WAVE/T w
	SetTextWave("buffer",w)
	Variable/G $bufflg=1
	ListBox CPBuffer, win=$Target(), row=0, selrow=0
End

static Function BufferAction(buffer)
	STRUCT WMListboxAction &buffer
	if(buffer.eventCode>0) //Redraw at any event except for closing. 
		SetControls()
		ActivateLine()
		endif
	if(buffer.eventCode==1)//Send a selected string by a click. 
		if(CommandPanel_ClickSelect)
			CommandPanel_SetLine(buffer.listWave[buffer.row])
		endif
		ActivateLine()
	endif
	if(buffer.eventCode==3)//Send a selected string by double clicks. 
		if(CommandPanel_DClickExecute)
			Execute/Z/Q CommandPanel_Execute
		elseif(CommandPanel_DClickSelect)
			CommandPanel_SetLine(buffer.listWave[buffer.row])
		endif
		ActivateLine()	
	endif
End

static Function PossiblyScrollBuffer(step)
	Variable step
	String line=CommandPanel_GetLine(), win=Target()
	line=ReplaceString("\\",line,"\\\\")
	WAVE/T buffer=CommandPanel_GetBuffer()
	ControlInfo/W=$win CPBuffer; Variable row=V_Value
	if(strlen(line)==0 || cmpstr(line,buffer[row])==0)
		if(step>0)
			row = row+step>=DimSize(buffer,0) ? 0 : row+(strlen(line)>0)*step
		else
			row = row+step<0 ? DimSize(buffer,0)-1 : row+step			
		endif
		ListBox CPBuffer, win=$win, row=row, selrow=row
		if(DimSize(buffer,0))
			CommandPanel_SetLine(ReplaceString("\\\\",buffer[row],"\\"))
		endif
		return 1		
	else
		return 0
	endif
End

static Function NarrowBuffer()
	WAVE/T buffer=CommandPanel_GetBuffer()
	String expr=RemoveFromList("",CommandPanel_GetLine()," ")
	Make/FREE/T/N=(ItemsInList(expr," ")) exprs=StringFromList(p,expr," ")
	if(CommandPanel_IgnoreCase)
		exprs="(?i)"+exprs
	endif
	Variable i
	for(i=0;i<DimSize(exprs,0) && DimSize(buffer,0);i+=1)
		Extract/T/FREE buffer,buffer,GrepString(buffer,exprs[i])
	endfor
	CommandPanel_SetBuffer(buffer)
	if(DimSize(buffer,0))
		CommandPanel_SetLine(buffer[0])
	endif
	if(GetRTError(0)==1233)
		Variable dummy=GetRTError(1)
	endif
End

static Function BufferModified()
	NVAR flag=root:Packages:CommandPanel:V_BufferModified
	if(NVAR_Exists(flag))
		return flag
	endif
End

// Ancillary Functions {{{2

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
