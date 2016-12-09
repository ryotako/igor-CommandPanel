//------------------------------------------------------------------------------
// This procedure file is packaged by igmodule
// Fri,09 Dec 2016
//------------------------------------------------------------------------------
#pragma ModuleName=CommandPanel

//------------------------------------------------------------------------------
// original file: CommandPanel_Main.ipf 
//------------------------------------------------------------------------------
#if !ItemsInList(WinList("CommandPanel_Main.ipf",";",""))

//#include ":CommandPanel_Menu"
//#include ":CommandPanel_Interface"
//#include ":CommandPanel_Complete"
//#include ":CommandPanel_Execute"
//#include ":CommandPanel_Expand"

#endif

//------------------------------------------------------------------------------
// original file: CommandPanel_Menu.ipf 
//------------------------------------------------------------------------------
#if !ItemsInList(WinList("CommandPanel_Menu.ipf",";",""))

//#pragma ModuleName=CommandPanel_Menu
//#include ":CommandPanel_Interface"

override strconstant CommandPanel_Menu = "CommandPanel"

Menu StringFromList(0,CommandPanel_Menu), dynamic
	RemoveListItem(0,CommandPanel_Menu)
	"New Command Panel",/Q,CommandPanel#CommandPanel_New()
	CommandPanel#MenuItem(0),  /Q, CommandPanel#MenuCommand(0)
	CommandPanel#MenuItem(1),  /Q, CommandPanel#MenuCommand(1)
	CommandPanel#MenuItem(2),  /Q, CommandPanel#MenuCommand(2)
	CommandPanel#MenuItem(3),  /Q, CommandPanel#MenuCommand(3)
	CommandPanel#MenuItem(4),  /Q, CommandPanel#MenuCommand(4)
	CommandPanel#MenuItem(5),  /Q, CommandPanel#MenuCommand(5)
	CommandPanel#MenuItem(6),  /Q, CommandPanel#MenuCommand(6)
	CommandPanel#MenuItem(7),  /Q, CommandPanel#MenuCommand(7)
	CommandPanel#MenuItem(8),  /Q, CommandPanel#MenuCommand(8)
	CommandPanel#MenuItem(9),  /Q, CommandPanel#MenuCommand(9)
	CommandPanel#MenuItem(10), /Q, CommandPanel#MenuCommand(10)
	CommandPanel#MenuItem(11), /Q, CommandPanel#MenuCommand(11)
	CommandPanel#MenuItem(12), /Q, CommandPanel#MenuCommand(12)
	CommandPanel#MenuItem(13), /Q, CommandPanel#MenuCommand(13)
	CommandPanel#MenuItem(14), /Q, CommandPanel#MenuCommand(14)
	CommandPanel#MenuItem(15), /Q, CommandPanel#MenuCommand(15)
	CommandPanel#MenuItem(16), /Q, CommandPanel#MenuCommand(16)
	CommandPanel#MenuItem(17), /Q, CommandPanel#MenuCommand(17)
	CommandPanel#MenuItem(18), /Q, CommandPanel#MenuCommand(18)
	CommandPanel#MenuItem(19), /Q, CommandPanel#MenuCommand(19)
End

static Function/S MenuItem(i)
	Variable i
	String win=StringFromList(i,WinList("CommandPanel*",";","WIN:64"))
	GetWindow/Z $win,wtitle
	return SelectString(strlen(win),"","\M0"+win+" ("+S_Value+")")
End
static Function MenuCommand(i)
	Variable i
	DoWindow/F $StringFromList(i,WinList("CommandPanel*",";","WIN:64"))
End


#endif

//------------------------------------------------------------------------------
// original file: CommandPanel_Interface.ipf 
//------------------------------------------------------------------------------
#if !ItemsInList(WinList("CommandPanel_Interface.ipf",";",""))

//#pragma ModuleName=CommandPanel_Interface
//#include ":CommandPanel_Complete"
//#include ":CommandPanel_Execute"
//#include ":CommandPanel_Expand"
//#include "Writer"

/////////////////////////////////////////////////////////////////////////////////
// Options //////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

override strconstant CommandPanel_Font       = ""
override constant    CommandPanel_Fontsize   = 14
override constant    CommandPanel_WinHeight  = 300
override constant    CommandPanel_WinWidth   = 300
override strconstant CommandPanel_WinTitle   = "'['+IgorInfo(1)+'] '+GetDataFolder(1)"

override constant    CommandPanel_KeySwap    = 0

/////////////////////////////////////////////////////////////////////////////////
// Public Functions /////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////

override Function CommandPanel_New()
	MakePanel()
End

override Function/S CommandPanel_GetLine()
	return GetStr("CommandLine")
End

override Function CommandPanel_SetLine(str)
	String str

	SetStr("CommandLine",str)
	SetVar("LineChanged",1)
End

override Function/WAVE CommandPanel_GetBuffer()
	Duplicate/FREE/T GetTextWave("buffer") w
	w = ReplaceString("\\\\",w,"\\")
	return w
End

override Function CommandPanel_SetBuffer(w [word,line,buffer])
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

override Function CommandPanel_SelectedRow()
	Variable n

	String win = StringFromList(0, WinList("CommandPanel*",";","WIN:64"))
	if(strlen(win))
		ControlInfo/W=$win CPBuffer
		return V_Value
	endif
End

override Function CommandPanel_SelectRow(n)
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
	SetWindow $win, hook(base) = CommandPanel#WinProc

	// Controls & their values
	GetStr("CommandLine")
	GetTextWave("buffer")
	SetVariable CPLine, title = " ", value = $PackageFolderPath()+"S_CommandLine"
	ListBox   CPBuffer, mode = 2, listWave = $PackageFolderPath()+"W_buffer"
	ResizeControls(win)

	// Control actions
 	SetVariable CPLine, proc=CommandPanel#LineAction
	ListBox   CPBuffer, proc=CommandPanel#BufferAction

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
	String expr = CommandPanel#gsub(CommandPanel_WinTitle,"\\\\|\\\'|\'","",proc=WinTitleSpecialChar)
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
	
	if(line.eventCode == 2) // key input
		Variable key = line.eventMod
		
		if(CommandPanel_KeySwap)
			key = (key == 0) ? 2 : ( key == 2 ) ? 0 : key
		endif
		
		switch(key)
			case 0: // Enter
				CommandPanel#ExecuteLine()
				//DoWindow/F $line.win
				break
			case 2: // Shift + Enter
				CommandPanel#Complete()
				break
			case 4: // Alt + Enter
				CommandPanel#AltComplete()
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



#endif

//------------------------------------------------------------------------------
// original file: CommandPanel_Complete.ipf 
//------------------------------------------------------------------------------
#if !ItemsInList(WinList("CommandPanel_Complete.ipf",";",""))

//#include ":CommandPanel_Interface"
//#include ":CommandPanel_Expand"
//#pragma ModuleName=CommandPanel_Complete

override constant CommandPanel_IgnoreCase = 1

static Function Complete()
	String input = CommandPanel_GetLine(), selrow=""
	WAVE/T line = CommandPanel#GetTextWave("line")

	if(DimSize(line, 0) > 0)
		selrow = line[CommandPanel_SelectedRow()]
	endif

	if(cmpstr(input, selrow, 1) == 0) // same as the selected buffer row 
		ScrollBuffer(1)

	elseif(strlen(input) == 0) // empty string
		ScrollBuffer(0)

	elseif(GrepString(input, "^ ")) // beginning with whitespace
		FilterBuffer()

	elseif(GrepString(input, "^(\\\\\\\\|\\\\\\\"|[^\"])*(\"(?1)*\"(?1)*)*\"(?1)*$")) // string literal
		// do nothing

	elseif(GrepString(input, "((?<!\\w)root)?:(([a-zA-Z_]\\w*|\'[^;:\"\']+\'):)*([a-zA-Z_]\\w*|\'[^;:\"\']*)?$")) // pathname
		CompletePathname()

	elseif(GrepString(input, "^(.*;)? *([A-Za-z]\\w*)$")) // the first word
		CompleteOperationName()

	elseif(GrepString(input, "((?<!\\w)[A-Za-z]\\w*)$")) // the second and any later word
		CompleteFunctionName()

	endif
End

static Function AltComplete()
	ScrollBuffer(-1)	
End


// for an empty string
// for the same string as the selected buffer row
static Function ScrollBuffer(n)
	Variable n
	
	WAVE/T line = CommandPanel#GetTextWave("line")
	Variable size = DimSize(line, 0)
	if(size)
		Variable num = mod(CommandPanel_SelectedRow() + size + n, size)
		CommandPanel_SelectRow(num)
		CommandPanel_SetLine(line[num])
	endif
End

// for a string beginning with whitespace 
static Function FilterBuffer()
	WAVE/T word = CommandPanel#GetTextWave("word")
	Duplicate/FREE/T CommandPanel#GetTextWave("line") line
	Duplicate/FREE/T CommandPanel#GetTextWave("buffer") buf

	if(DimSize(buf, 0) > 0)
		String patterns = RemoveFromList("", CommandPanel_GetLine(), " ")
		Variable i, N=ItemsInList(patterns, " ")
		for(i = 0; i < N; i += 1)
			String pattern = StringFromList(i, patterns, " ")
			if(CommandPanel_IgnoreCase)
				pattern="(?i)" + pattern
			endif
			Extract/FREE/T buf,  buf,  GrepString(word, pattern)
			Extract/FREE/T line, line, GrepString(word, pattern)
			Extract/FREE/T word, word, GrepString(word, pattern)
		endfor
		CommandPanel_SetBuffer($"", buffer = buf, line = line, word = word)
		if(DimSize(buf, 0) > 0)
			CommandPanel_SetLine(line[0])
		endif
	endif
End

// for a pathname
static Function CompletePathname()
	String line=CommandPanel_GetLine(), cmd, path, name, s
	SplitString/E="^(.*?)(((?<!\w)root)?:(([a-zA-Z_]\w*)?:)*)([a-zA-Z_]\w*|\'[^;:\"\']*)?$" line,cmd,path,s,s,s,name
	if(DataFolderExists(path))
		Make/FREE/T/N=(CountObjects(path, 1)) wav = PossiblyQuoteName(GetIndexedObjName(path, 1, p))		
		Make/FREE/T/N=(CountObjects(path, 2)) var = PossiblyQuoteName(GetIndexedObjName(path, 2, p))		
		Make/FREE/T/N=(CountObjects(path, 3)) str = PossiblyQuoteName(GetIndexedObjName(path, 3, p))		
		Make/FREE/T/N=(CountObjects(path, 4)) fld = PossiblyQuoteName(GetIndexedObjName(path, 4, p))
		Make/FREE/T/N=0 obj
		Concatenate/T/NP {wav, var, str, fld}, obj
		Extract/T/FREE obj,obj,StringMatch(obj, name + "*")
		Make/T/FREE/N=(DimSize(obj, 0)) buf = cmd + path + obj
		if(DimSize(buf, 0))
			CommandPanel_SetBuffer(buf)
			CommandPanel_SetLine(buf[0])
		endif
	endif
End

// for the first word
// TODO: alias completion
override Function CompleteOperationName()
	String line = CommandPanel_GetLine(), pre, word
	SplitString/E="(.*;)? *([A-Za-z]\\w*)$" line, pre, word
	
	String list = FunctionList(word + "*", ";", "KIND:2") + OperationList(word + "*", ";", "all")
	Make/FREE/T/N=(ItemsInList(list)) oprs = StringFromList(p, list)

	Make/FREE/T/N=0 buf
	Concatenate/T/NP {CommandPanel#GetAliasNames(), oprs}, buf
	
	Extract/T/FREE buf, buf, StringMatch(buf, word + "*")
	buf = pre + buf
	if(DimSize(buf, 0))
		CommandPanel_SetBuffer(buf)
		CommandPanel_SetLine(buf[0])	
	endif
End

// for the second or any later word
override Function CompleteFunctionName()
	String line=CommandPanel_GetLine(), prefnc, fnc
	SplitString/E="^(.*?)((?<!\\w)[A-Za-z]\\w*)$" line, prefnc, fnc
	String list = FunctionList(fnc + "*", ";", "KIND:3")
	Make/FREE/T/N=(ItemsInList(list)) fncs = StringFromList(p, list)
	Extract/T/FREE fncs, fncs, StringMatch(fncs, fnc + "*")
	Make/T/FREE/N=(DimSize(fncs, 0)) buf = prefnc + fncs
	if(DimSize(buf, 0))
		CommandPanel_SetBuffer(buf)
		CommandPanel_SetLine(buf[0])	
	endif
End

#endif

//------------------------------------------------------------------------------
// original file: CommandPanel_Expand.ipf 
//------------------------------------------------------------------------------
#if !ItemsInList(WinList("CommandPanel_Expand.ipf",";",""))

//#include "writer"
//#include ":CommandPanel_Interface"
//#pragma ModuleName=CommandPanel_Expand


static Function/WAVE Expand(input)
	String input

	// 1. strong line splitting
	WAVE/T w1 = StrongLineSplit(input)

	// 2. alias expansion
	w1 = ExpandAlias(w1)

	// 3. brace expansion
	WAVE/T w2 = CommandPanel#concatMap(ExpandBrace, w1)
	w2 = UnescapeBraces(w2)
	
	// 4. pathname expansion
	WAVE/T w3 = CommandPanel#concatMap(ExpandPath, w2)
	
	// 5. weak line splitting
	WAVE/T w4 = CommandPanel#concatMap(WeakLineSplit,w3)

	// 6. parenthesis completion
	w4 = UnescapeBackquotes(CompleteParen(w4))

	return w4
End


// Utils
static Function/WAVE SplitAs(s,w)
	String s; WAVE/T w
	Variable i,j,N = DimSize(w,0)
	Make/FREE/T/N=(N) buf
	for(i = 0, j = 0; i < N; j += strlen(w[i]), i += 1)
		buf[i] = s[j,j+strlen(w[i])-1]
	endfor
	return buf
End
static Function/WAVE PartitionWithMask(s,expr)
	String s,expr
	return SplitAs(s,CommandPanel#partition(mask(s),expr))
End
static Function/S trim(s)
	String s
	return ReplaceString(" ",s,"")
End
static Function/WAVE product(w1,w2) //{"a","b"},{"1","2"} -> {"a1","a2","b1","b2"}
	WAVE/T w1,w2
	Variable n1 = DimSize(w1, 0), n2 = DimSize(w2, 0)
	if(n1 * n2)
		Make/FREE/T/N=(n1*n2) w = w1[floor(p / n2)] + w2[mod(p, n2)]
	else
		Make/FREE/T/N=0 w
	endif
	return w
End


// 0. Escape Sequence {{{1
// mask
static strconstant M ="|" // one character for masking
static Function/S Mask(input)
	String input
	
	// mask comment
	input=CommandPanel#gsub(input,"//.*$","",proc=Mask_)
	// mask with ``
	input=CommandPanel#gsub(input,"\\\\\\\\|\\\\`|`(\\\\\\\\|\\\\`|[^\\`])*`","",proc=Mask_)
	// mask with ""
	input=CommandPanel#gsub(input,"\\\\\\\\|\\\\\"|\"(\\\\\\\\|\\\\\"|[^\\\"])*\"","",proc=Mask_)
	// mask with \
	input=CommandPanel#gsub(input,"\\\\\\\\|\\\\{|\\\\}|\\\\,","",proc=Mask_)

	return input
End
static Function/S Mask_(s)
	String s
	Variable i; String buf=""
	for(i=0;i<strlen(s);i+=1)
		buf+=M
	endfor
	return buf
End

// unascape
static Function/S UnescapeBraces(input)
	String input
	String ignore = "//.*$|\\\\\\\\|\\\\`|`(\\\\\\\\|\\\\`|[^\\`])*`|\\\\\"|\"(\\\\\\\\|\\\\\"|[^\\\"])*\""
	String pattern = "\\\\{|\\\\}\\\\,"
	return CommandPanel#gsub(input,ignore+"|"+pattern,"",proc=UnescapeBrace)
End
static Function/S UnescapeBrace(s)
	String s
	return SelectString(GrepString(s,"^\\\\[^\\\\`]$"),s,s[1])
End

static Function/S UnescapeBackquotes(input)
	String input
	return CommandPanel#gsub(input,"//.*$|\\\\\\\\|\\\\`|`","",proc=UnescapeBackquote)
End
static Function/S UnescapeBackquote(s)
	String s
	return SelectString(StringMatch(s,"`"),s,"")
End


// 1,5. Line Split
static Function/WAVE LineSplitBy(delim,input,masked)
	String delim,input ,masked
	Variable pos = strsearch(masked,delim,0)
	if(pos<0)
		return CommandPanel#cast({input})
	endif
	Variable pos2 = pos + strlen(delim)
	return CommandPanel#cons(input[0,pos-1],LineSplitBy(delim,input[pos2,inf],masked[pos2,inf]))
End
static Function/WAVE StrongLineSplit(input)
	String input
	return LineSplitBy(";;",input,mask(input))
End
static Function/WAVE WeakLineSplit(input)
	String input
	return LineSplitBy(";",input,mask(input))
End


// 2. Alias Expansion
static Function/S ExpandAlias(input)
	String input
	WAVE/T w=PartitionWithMask(input,";")// line, ;, lines
	if(strlen(w[1])==0)
		return ExpandAlias_(input)
	endif
	return ExpandAlias_(w[0]+w[1]) + ExpandAlias(w[2])
End
static Function/S ExpandAlias_(input) // one line
	String input
	WAVE/T w=CommandPanel#partition(input,"^\\s*(\\w*)") //space,alias,args
	if(strlen(w[1])==0)
		return input
	endif
	Duplicate/FREE/T GetAlias(),als
	Extract/FREE/T als,als,StringMatch(als,w[1]+"=*")
	if(CommandPanel#null(als))
		return input
	else
		String cmd=(CommandPanel#head(als))[strlen(w[1])+1,inf]
		return w[0]+ExpandAlias_(cmd)+w[2]
	endif
End

static Function SetAlias(input)
	String input
	WAVE/T w=PartitionWithMask(input,"^(\\s*\\w+\\s*=\\s*)") //blank,alias=,string
	if(strlen(w[1]))
		Duplicate/T/FREE GetAlias() alias
		Extract/FREE/T alias,alias,!StringMatch(alias,trim(w[1])+"*")
		InsertPoints 0,1,alias; alias[0] = trim(w[1])+w[2]
		CommandPanel#SetTextWave("alias",alias)
	endif
End
static Function/WAVE GetAlias()
	return CommandPanel#GetTextWave("alias")
End
static Function/WAVE GetAliasNames()
	return CommandPanel#map(GetAliasName,GetAlias())
End
static Function/S GetAliasName(s)
	String s
	String name
	SplitString/E="^(\\w+)=" s,name
	return name
End

// 3. Brace Expansion
static Function/WAVE ExpandBrace(input)
	String input
	return ExpandSeries(ExpandCharacterSeries(ExpandNumberSeries(input)))
End

static Function/WAVE ExpandSeries(input)
	String input
	WAVE/T w=SplitAs(input,CommandPanel#partition(mask(input),trim("( { ([^{}] | {[^{}]*} | (?1))* , (?2)* } )")))
	if(strlen(w[1])==0)
		return CommandPanel#cast({input})
	endif
	WAVE/T body = ExpandSeries_((w[1])[1,strlen(w[1])-2])
	body = w[0] + body + w[2]
	return CommandPanel#concatMap(ExpandSeries,body)
End

static Function/WAVE ExpandSeries_(body) // expand inside of {} once
	String body
	if(strlen(body)==0)
		return CommandPanel#cast({""})
	elseif(StringMatch(body[0],","))
		return CommandPanel#cons("",ExpandSeries_(body[1,inf]))
	elseif(!GrepString(body,"{|}|\\\\"))
		Variable size = ItemsInList(body, ",") + StringMatch(body[strlen(body)-1], ",")
		Make/FREE/T/N=(size) w = StringFromList(p, body, ",")
		return w
	endif
	WAVE/T w=PartitionWithMask(body,trim("^( ( [^{},] | ( { ([^{}]*|(?3)) } ) )* )"))
	if(strlen(w[2]))
		return CommandPanel#cons(w[1],ExpandSeries_( (w[2])[1,inf] ))
	else
		return CommandPanel#cast({w[1]})
	endif
End

static Function/S ExpandNumberSeries(input)
	String input
	WAVE/T w=CommandPanel#partition(input,trim("( { ([+-]?\\d+) \.\. (?2) (\.\. (?2))? } )"))
	if(strlen(w[1])==0)
		return input
	endif
	String fst,lst,stp; SplitString/E="{([+-]?\\d+)\.\.((?1))(\.\.((?1)))?}" w[1],fst,lst,stp,stp
	Variable v1=Str2Num(fst), v2=Str2Num(lst), vd = abs(Str2Num(stp)); vd = NumType(vd) || vd==0 ? 1 : vd
	Variable i,N=floor(abs(v1-v2)/vd+1); String s=""
	for(i=0;i<N;i+=1)
		s+=Num2Str(v1+i*vd*sign(v2-v1))+","
	endfor
	s=RemoveEnding(s,",")
	return SelectString(N<2,w[0]+"{"+s+"}",w[0]+s)+ExpandNumberSeries(w[2])
End

static Function/S ExpandCharacterSeries(input)
	String input
	WAVE/T w=CommandPanel#partition(input,trim("( { ([a-zA-Z]) \.\. (?2) (\.\. ([+-]?\\d+))? } )"))
	if(strlen(w[1])==0)
		return input
	endif
	String fst,lst,stp; SplitString/E="{([a-zA-Z])\.\.((?1))(\.\.([+-]?\\d+))?}" w[1],fst,lst,stp,stp
	Variable v1=Char2Num(fst), v2=Char2Num(lst), vd = abs(Char2Num(stp)); vd = NumType(vd) || vd==0 ? 1 : vd
	Variable i,N=floor(abs(v1-v2)/vd+1); String s=""
	for(i=0;i<N;i+=1)
		s+=Num2Char(v1+i*vd*sign(v2-v1))+","
	endfor
	s=RemoveEnding(s,",")
	return SelectString(N<2,w[0]+"{"+s+"}",w[0]+s)+ExpandCharacterSeries(w[2])
End


// 4. Path Expansion
static Function/WAVE ExpandPath(input)
	String input
	WAVE/T w = PartitionWithMask(input,trim("(?<!\\w)(root)?(:[a-zA-Z\\*][\\w\\*]* | :'[^:;'\"]+')+ :?"))
	if(strlen(w[1])==0)
		return CommandPanel#cast({input})
	endif
	return product( CommandPanel#cast({w[0]}), product(ExpandPathImpl(w[1]), ExpandPath(w[2])))
End
static Function/WAVE ExpandPathImpl(path) // implement of path expansion
	String path
	WAVE/T token = SplitAs(path,CommandPanel#scan(mask(path),":|[^:]+:?"))
	WAVE/T buf   = ExpandPathImpl_(CommandPanel#head(token),CommandPanel#tail(token))
	if(CommandPanel#null(buf))
		return CommandPanel#cast({path})		
	endif
	return buf
End
static Function/WAVE ExpandPathImpl_(path,token)
	String path; WAVE/T token
	if(CommandPanel#null(token))
		return CommandPanel#cast({path})
	elseif(CommandPanel#length(token)==1)
		if(cmpstr(CommandPanel#head(token),"**:")==0)
			WAVE/T fld = GlobFolders(path)
			fld=path+fld+":"
			return fld
		elseif(GrepString(CommandPanel#head(token),":$")) // *: -> {fld1:, fld2:}
			WAVE/T w = Folders(path)
			Extract/T/FREE w,fld,PathMatch(w,RemoveEnding(CommandPanel#head(token),":"))
			fld=path+fld+":"
			return fld
		else // * -> {wave, var, str, fld} 
			WAVE/T w = Objects(path)
			Extract/T/FREE w,obj,PathMatch(w,RemoveEnding(CommandPanel#head(token),":"))
			obj=path+obj
			return obj		
		endif
	else
		if(cmpstr(CommandPanel#head(token),"**:")==0)
			WAVE/T fld = GlobFolders(path)
			InsertPoints 0,1,fld
			fld=path+fld+":"
			fld[0]=RemoveEnding(fld[0],":")
		else
			WAVE/T w = Folders(path)
			Extract/T/FREE w,fld,PathMatch(w,RemoveEnding(CommandPanel#head(token),":"))
			fld=path+fld+":"
		endif
		Variable i,N=CommandPanel#length(fld); Make/FREE/T/N=0 buf
		for(i=0;i<N;i+=1)
			Concatenate/NP/T {ExpandPathImpl_(fld[i],CommandPanel#tail(token))},buf
		endfor
		return buf
	endif
End

static Function PathMatch(path,expr) // now, the matcher is StringMatch
	String path,expr
	return StringMatch(path,expr)
End

static Function/WAVE Folders(path)
	String path
	Make/T/FREE/N=(CountObj(path,4)) w = PossiblyQuoteName(GetIndexedObjName(path,4,p))
	return w
End
static Function/WAVE Objects(path)
	String path
	Make/T/FREE/N=(CountObj(path,1)) wav = PossiblyQuoteName(GetIndexedObjName(path,1,p))		
	Make/T/FREE/N=(CountObj(path,2)) var = PossiblyQuoteName(GetIndexedObjName(path,2,p))		
	Make/T/FREE/N=(CountObj(path,3)) str = PossiblyQuoteName(GetIndexedObjName(path,3,p))		
	Make/T/FREE/N=(CountObj(path,4)) fld = PossiblyQuoteName(GetIndexedObjName(path,4,p))
	Make/FREE/T/N=0 f; Concatenate/T/NP {fld,wav,var,str},f
	return f
End

static Function/WAVE GlobFolders(path)
	String path
	WAVE/T w = GlobFolders_(path)
	if(!CommandPanel#null(w))
		w=RemoveEnding(RemoveBeginning(w,path),":")
	endif
	return w
End
static Function/WAVE GlobFolders_(path)
	String path
	WAVE/T fld=Folders(path); fld=path+fld+":"
	Variable i,N=CommandPanel#length(fld); Make/FREE/T/N=0 buf
	for(i=0;i<N;i+=1)
		Concatenate/T/NP {CommandPanel#cast({fld[i]}), GlobFolders_(fld[i])},buf
	endfor
	return buf
End
static Function CountObj(path,type)
	String path; Variable type
	Variable v=CountObjects(path,type)
	return numtype(v) ? 0 : v
End
static Function/S RemoveBeginning(s,beginning)
	String s,beginning
	if(strlen(beginning) && cmpstr(s[0,strlen(beginning)-1],beginning)==0)
		return s[strlen(beginning),inf]
	endif
	return s
End


// 6. Complete Parenthesis
static Function/S CompleteParen(input)
	String input
	String ref = CommandPanel#gsub(CommandPanel#gsub(input,"(\\\\\")","",proc=Mask_),"(\"[^\"]*\")","",proc=Mask_)
	WAVE/T w=SplitAs(input,CommandPanel#partition(ref,"\\s(//.*)?$")) // command, comment, ""
	WAVE/T f=CommandPanel#partition(w[0],"^\\s*[a-zA-Z]\\w*(#[a-zA-Z]\\w*)?\\s*") // "", function, args
	String info=FunctionInfo(trim(f[1]))
	if(strlen(info)==0 || GrepString(f[2],"^\\("))
		return input
	elseif(NumberByKey("N_PARAMS",info)==1 && NumberByKey("PARAM_0_TYPE",info)==8192 && !GrepString(f[2],"^ *\".*\" *$"))
		f[2]="\""+f[2]+"\""
	endif
	return CommandPanel#sub(f[1]," *$","")+"("+f[2]+")"+w[1]
End

#endif

//------------------------------------------------------------------------------
// original file: writer.ipf 
//------------------------------------------------------------------------------
#if !ItemsInList(WinList("writer.ipf",";",""))

//------------------------------------------------------------------------------
// This procedure file is packaged by igmodule
// Fri,09 Dec 2016
//------------------------------------------------------------------------------
//#pragma ModuleName=writer

//------------------------------------------------------------------------------
// original file: writer_main.ipf 
//------------------------------------------------------------------------------
#if !ItemsInList(WinList("writer_main.ipf",";",""))

//#include ":writer_string"
//#include ":writer_list"

#endif

//------------------------------------------------------------------------------
// original file: writer_string.ipf 
//------------------------------------------------------------------------------
#if !ItemsInList(WinList("writer_string.ipf",";",""))

// ruby-like string function
//#pragma ModuleName=wString

override Function/S Writer_ProtoTypeSub(s)
	String s
	return s
End


// Ruby: s.partition(/expr/)
static Function/WAVE partition(s,expr)
	String s,expr
	expr=IncreaseSubpatternNumber(2,expr)
	String pre,pst
	if(GrepString(expr,"^\\^")) // ^...(...) -> ^()...(...)
		expr="^()("+expr[1,inf]+")"
	elseif(GrepString(expr,"^\\(+\\^")) // ((^...)) -> ^(.*)((...))
		SplitString/E="^(\\(+)\\^(.*)" expr,pre,pst
		expr = "^(.*?)"+"("+pre+pst+")"
	else
		expr = "(.*?)("+expr+")"
	endif
	String head,body,tail
	SplitString/E=expr s,head,body
	tail=s[strlen(head+body),inf]
	if(!strlen(body))
		Make/FREE/T w={s,"",""}
	else
		Make/FREE/T w={head,body,tail}
	endif
	return w
End

// Ruby: s.scan(/expr/)
static Function/WAVE scan(s,expr)
	String s,expr
	WAVE/T w=SubPatterns( s, "("+IncreaseSubpatternNumber(1,expr)+")")
	Variable num=DimSize(w,0)
	if(num>1 || strlen(expr)==0)
		DeletePoints 0,1,w
	endif
	if(DimSize(w,0)==0 || hasCaret(expr) )
		return w
	else
		WAVE/T part=partition(s,expr)
		if(num>1)
			WAVE/T buf=scan(part[2],expr)
			Variable Nw=DimSize(w,0), Nb=DimSize(buf,0)
			if(Nb>0 && Nb>Nw)
				InsertPoints Nw,Nb-Nw,w 
			elseif(Nb>0)
				InsertPoints Nb,Nw-Nb,buf 			
			endif
			Concatenate/T {buf},w
		else
			Concatenate/T/NP {scan(part[2],expr)},w
		endif
		return w
	endif
End

// Ruby: s.split(/expr/)
static Function/WAVE split(s,expr)
	String s,expr
	if(empty(expr) && strlen(s))
		Make/FREE/T/N=(strlen(s)) w=s[p]; return w
	endif
	WAVE/T w = partition(s,expr)
	if(empty(w[1]))
		Make/FREE/T w={s}; return w
	endif
	Make/FREE/T buf={w[0]}
	if(hasCaret(expr))
		Concatenate/NP/T {SubPatterns(s,expr)},buf
		InsertPoints DimSize(buf,0),1,buf; buf[inf]=w[2]	
	else
		Concatenate/NP/T {SubPatterns(s,expr) ,split(w[2],expr) },buf
	endif
	return buf
End

// Ruby: s.sub(/expr/,"alt")
//    or s.sub(/expr/){proc}
static Function/S sub(s,expr,alt [proc])
	String s,expr,alt; FUNCREF Writer_ProtoTypeSub proc
	WAVE/T w=partition(s,expr)
	if(empty(w[1]))
		return s
	endif
	if(!ParamIsDefault(proc))
		return w[0]+proc(w[1])+w[2]
	endif
	WAVE/T a=split(alt,"(\\\\\\d|\\\\&|\\\\`|\\\\'|\\\\+)")
	Variable i,N=DimSize(a,0); alt=""
	for(i=0;i<N;i+=1)
		if(GrepString(a[i],"\\\\0|\\\\&"))
			alt+=w[1]
		elseif(GrepString(a[i],"\\\\`"))
			alt+=w[0]
		elseif(GrepString(a[i],"\\\\'"))
			alt+=w[2]
		elseif(GrepString(a[i],"\\\\\\d"))
			Variable num=Str2Num((a[i])[1])
			WAVE/T sub=SubPatterns(s,expr)
			if(DimSize(sub,0)+1>num)
				alt+=sub[num-1]
			endif
		else
			alt+=a[i]
		endif
	endfor
	return w[0]+alt+w[2]
End

// Ruby: s.gsub(/expr/,"alt")
static Function/S gsub(s,expr,alt [proc])
	String s,expr,alt; FUNCREF Writer_ProtoTypeSub proc
	WAVE/T w=partition(s,expr)
	if(empty(w[1]))
		return s
	elseif(hasCaret(expr) || hasDollar(expr))
		if(ParamIsDefault(proc))
			return sub(s,expr,alt)
		else
			return sub(s,expr,alt,proc=proc)		
		endif
	else
		if(ParamIsDefault(proc))
			return sub(w[0]+w[1],expr,alt)+gsub(w[2],expr,alt)		
		else
			return sub(w[0]+w[1],expr,alt,proc=proc)+gsub(w[2],expr,alt,proc=proc)
		endif
	endif	
End

static Function empty(s)
	String s
	return !strlen(s)
End
static Function hasCaret(expr)
	String expr
	return GrepString(expr,"^\\(*\\^")
End
static Function hasDollar(expr)
	String expr
	return GrepString(expr,"\\$\\)*$")
End

static Function/S IncreaseSubpatternNumber(n,s)
	Variable n; String s
	String head,body,tail
	SplitString/E="(.*?)(\\(\\?(\\d+\\)))(.*)" s,head,body,body,tail
	if(empty(body))
		return s
	endif
	return head+"(?"+Num2Str(Str2Num(body)+n)+")"+IncreaseSubpatternNumber(n,tail)
End

static Function/WAVE SubPatterns(s,expr)
	String s,expr
	DFREF here=GetDataFolderDFR(); SetDataFolder NewFreeDataFolder()
	String s_   =ReplaceString("\"",ReplaceString("\\",s   ,"\\\\"),"\\\"")
	String expr_=ReplaceString("\"",ReplaceString("\\",expr,"\\\\"),"\\\"")
	String cmd="SplitString/E=\""+expr_+ "\" \""+s_+"\""
	SplitString/E=expr s
	Make/FREE/T/N=(V_Flag) w; Variable i, N=V_Flag
	for(i=0;i<N;i+=1)
		Execute/Z "String/G s"+Num2Str(i)
		cmd+=",s"+Num2Str(i)
	endfor
	Execute/Z cmd
	for(i=0;i<N;i+=1)
		SVAR sv=$"s"+Num2Str(i)
		w[i]=sv
	endfor
	SetDataFolder here
	return w
End

#endif

//------------------------------------------------------------------------------
// original file: writer_list.ipf 
//------------------------------------------------------------------------------
#if !ItemsInList(WinList("writer_list.ipf",";",""))

// haskell-like wave function
//#pragma ModuleName=wList

// Prototype Functions
override Function/S Writer_ProtoTypeId(s)
	String s
	return s
End
override Function/S Writer_ProtoTypeAdd(s1,s2)
	String s1,s2
	return s1+s2
End
override Function/WAVE Writer_ProtoTypeSplit(s)
	String s
	Make/FREE/T/N=(ItemsInList(s)) w=StringFromList(p,s); return w
End
override Function Writer_ProtoTypeLength(s)
	String s
	return strlen(s)
End

// cast a textwave into a 1D textwave
static Function/WAVE cast(w)
	WAVE/T w
	if(WaveExists(w))
		Make/FREE/T/N=(DimSize(w,0)) f=w
	else
		Make/FREE/T/N=0 f
	endif
	return f
End

////////////////////////////////////////
// Basic ///////////////////////////////
////////////////////////////////////////
static Function/WAVE cons(s,w) // (:)
	String s; WAVE/T w
	if(null(w))
		return cast({s})
	endif
	Duplicate/FREE/T cast(w),f
	InsertPoints 0,1,f
	f[0]=s
	return f
End
static Function/WAVE extend(w1,w2) // (++)
	WAVE/T w1,w2
	Make/FREE/T/N=0 f
	Concatenate/NP/T {cast(w1),cast(w2)},f
	return f
End

static Function/S head(w)
	WAVE/T w
	if(null(w))
		return ""
	endif
	return w[0]
End
static Function/WAVE tail(w)
	WAVE/T w
	if(null(w))
		return cast($"")
	endif
	WAVE/T f=cast(w)
	DeletePoints 0,1,f
	return f
End

static Function/S last(w)
	WAVE/T w
	if(null(w))
		return ""
	endif
	return w[inf]
End
static Function/WAVE init(w)
	WAVE/T w
	if(null(w))
		return cast($"")
	endif
	WAVE/T f=cast(w)
	DeletePoints length(f)-1,1,f
	return f	
End

static Function length(w)
	WAVE/T w
	return numpnts(cast(w))
End
static Function null(w)
	WAVE/T w
	return !length(w)
End

////////////////////////////////////////
// Construction ////////////////////////
////////////////////////////////////////

static Function/WAVE map(f,w)
	FUNCREF Writer_ProtoTypeId f; WAVE/T w
	WAVE/T buf=cast(w)
	if(length(buf))
		buf=f(w)
	endif
	return buf
End

static Function/S foldl(f,s,w)
	FUNCREF Writer_ProtoTypeAdd f; String s; WAVE/T w
	if(null(w))
		return s
	endif
	return foldl(f, f(s,head(w)), tail(w)) 
End
static Function/S foldl1(f,w)
	FUNCREF Writer_ProtoTypeAdd f; WAVE/T w
	return foldl(f,head(w),tail(w))
End

static Function/S foldr(f,s,w)
	FUNCREF Writer_ProtoTypeAdd f; String s; WAVE/T w
	if(null(w))
		return s
	endif
	return foldr(f, f(last(w),s), init(w)) 
End
static Function/S foldr1(f,w)
	FUNCREF Writer_ProtoTypeAdd f; WAVE/T w
	return foldl(f,last(w),init(w))
End

static Function/WAVE concatMap(f,w)
	FUNCREF Writer_ProtoTypeSplit f; WAVE/T w
	Make/FREE/T/N=0 buf
	Variable i,N = DimSize(w, 0)
	for(i = 0; i < N; i += 1)
			Concatenate/T/NP {f(w[i])}, buf
	endfor
	return buf
End

static Function any(f,w)
	FUNCREF Writer_ProtoTypeLength f; WAVE/T w
	if(null(w))
		return 0
	endif
	return f(head(w)) || any(f,tail(w))
End
static Function all(f,w)
	FUNCREF Writer_ProtoTypeLength f; WAVE/T w
	if(null(w))
		return 1
	endif
	return f(head(w)) && all(f,tail(w))
End

static Function/WAVE take(n,w)
	Variable n; WAVE/T w
	if(null(w) || n<1 || n!=n)
		return cast($"")
	endif
	return cons(head(w),take(n-1,tail(w)))
End
static Function/WAVE drop(n,w)
	Variable n; WAVE/T w
	if(null(w) || n<1 || n!=n)
		return cast(w)
	endif
	return drop(n-1,tail(w))
End

#endif


#endif

//------------------------------------------------------------------------------
// original file: CommandPanel_Execute.ipf 
//------------------------------------------------------------------------------
#if !ItemsInList(WinList("CommandPanel_Execute.ipf",";",""))

//#include ":CommandPanel_Interface"
//#include ":CommandPanel_Expand"
//#include "writer"
//#pragma ModuleName=CommandPanel_Execute

// history options
override constant CommandPanel_HistEraseDups = 0
override constant CommandPanel_HistIgnoreDups = 0
override constant CommandPanel_HistIgnoreSpace = 0
override strconstant CommandPanel_HistIgnore = ";"

override Function CommandPanel_Execute(s)
	String s
	if(strlen(s))
		Variable error; String out
		ExpandAndExecute(s,out,error)
		return error
	else
		return 0
	endif
End

static Function ExecuteLine()
	// initialize
	InitAlias()
	
	CommandPanel#SetVar("LineChanged",0)
	CommandPanel#SetVar("BufferChanged",0)

	// get command
	String input=CommandPanel_GetLine()
	if(strlen(input)==0)
		ShowHistory()
		return NaN
	endif

	// expand & execute command
	Variable error
	String output=""
	ExpandAndExecute(input,output,error)
	
	// history
	if(!error)
		AddHistory(input)
		if( ! CommandPanel#GetVar("LineChanged") )
			CommandPanel_SetLine("")
		endif
	endif
	
	// output
	if( CommandPanel#GetVar("BufferChanged") )
		return NaN
	elseif( strlen(output) )
		CommandPanel_SetBuffer(CommandPanel#init(CommandPanel#split(output,"\r")))
	else		
		ShowHistory()
	endif
	
//	DoWindow/F $CommandPanel#GetWinName()
End

// expand input and execute
// return output and error code with string and variable references
static Function ExpandAndExecute(input,output,error)
	String input,&output; Variable &error
	WAVE/T cmds =CommandPanel#Expand(input)
	if(DimSize(commands,0)==0)
		Make/FREE/T cmds = {input}
	endif
	Variable i,N=DimSize(cmds,0)
	for(i=0;i<N;i+=1)
		PrintCommand(cmds[i])
		Variable ref = CaptureHistoryStart()
		Execute/Z cmds[i]
		error = V_Flag
		print GetErrMessage(error)
		output += CaptureHistory(ref,ref)
		if(error) // when an error occurs, stop execution 
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
		return CommandPanel#SetAlias(s)		
	endif
	CommandPanel_SetBuffer( CommandPanel#GetTextWave("alias") )
End 
static Function InitAlias()
	WAVE/T w=CommandPanel#GetAlias()
	if(DimSize(w,0)==0)
		CommandPanel#SetAlias("alias=CommandPanel#Alias")
	endif
End

// History
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

static Function ShowHistory()
	CommandPanel_SetBuffer( CommandPanel#GetTextWave("history") )
End

#endif

