#pragma ModuleName = CommandPanel

////////////////////////////////////////////////////////////////////////////////
// 2016-Dec-31                                                                //
//   Revisions by Jim Prouty, Igorian Chant Software                          //
//   Works with NVAR SVAR WAVE checking turned on (added /Z to NVAR and SVAR).//
//   Works with Igor 7.                                                       //
//                                                                            //
// 2016-Dec-17                                                                //
//   The first version by Ryota Kobayashi, Tohoku Univ.                       //
////////////////////////////////////////////////////////////////////////////////

//==============================================================================
// Public functions
//==============================================================================

Function CreateCommandPanel()	
	//
	// Make a CommandPanel window (singleton)
	//
	if(strlen(WinList("CommandPanel", ";", "WIN:64")))
		KillWindow CommandPanel
	endif
	
	WAVE panelRect = GetNumWave("CommandPanel")
	if(DimSize(panelRect, 0) != 4)
		GetWindow kwCmdHist wsizeOuter
		Make/FREE/N=4 panelRect = {V_left, V_top, V_right, V_bottom}
	endif
	
	NewPanel/K=1/N=CommandPanel/W=(panelRect[0], panelRect[1], panelRect[2], panelRect[3])
	
	String panelName = S_Name
	ModifyPanel/W=$panelName noEdit=1
	SetWindow $panelName, hook(base) = CommandPanel#WinProc

	//
	// Make controls on CommandPanel
	//
	String cmd = "", font = "Arial"

	GetStr("CommandLine")
	SetVariable CPLine, title = " "
	SetVariable CPLine, value = $PackagePath()+"S_commandLine"
	SetVariable CPLine, proc = CommandPanel#LineAction
	sprintf cmd, "SetVariable CPLine, font = $\"%s\", fsize = %d", font, 14
	Execute cmd

	GetTxtWave("buffer")
	GetNumWave("select")
	ListBox CPBuffer, listWave = GetNumWave("buffer")
	ListBox CPBuffer, selWave = GetNumWave("select")
	ListBox CPBuffer, mode = 9
	ListBox CPBuffer, proc = CommandPanel#BufferAction
	sprintf cmd, "ListBox CPBuffer, font = $\"%s\", fsize = %d", font, 14
	Execute cmd
	
	// Resize
	ResizeControls(panelName)

	// Activate
	sprintf cmd, "SetVariable/Z CPLine, win=$\"%s\", activate", panelName
	Execute/P/Q cmd
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
	SetVar("bufferChanged", 1)

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

#if IgorVersion() < 7 && defined(WINDOWS)
// When I uses /Z flag in Windows version Igor Pro 6, buffer scrolling does not work 
Function CommandPanel_SelectRows(w)
	WAVE w
	CommandPanel_SelectRows_(w)
End
#else
Function CommandPanel_SelectRows(w)
	WAVE/Z w
	CommandPanel_SelectRows_(w)
End
#endif

Function CommandPanel_SelectRows_(w)
	WAVE w
	Make/FREE/N=(DimSize(GetNumWave("select"), 0)) select = 0	
	Variable i, N = DimSize(w, 0)
	for(i = 0; i < N; i += 1)
		Variable num = w[i]
		select[num] = 1
	endfor
	SetNumWave("select" ,select)
End

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

//==============================================================================
//	Menu
//==============================================================================

Menu "Misc"
	"CommandPanel", /Q, CreateCommandPanel()
End

//==============================================================================
// Interface
//==============================================================================

//------------------------------------------------------------------------------
// Panel building
//------------------------------------------------------------------------------

static Function UpdateTitle(win)
	String win
	DoWindow/T $win, GetDataFolder(1)
End

// Resize
static Function ResizeControls(win)
	String win

	if( PanelResolution(win) == 72 )
		GetWindow $win wsizeDC		// the new window size in pixels (the Igor 6 way)
	else
		GetWindow $win wsize		// the new window size in points (the Igor 7 way, sometimes)
	endif
	Variable panelWidth  = V_Right  - V_Left
	Variable panelHeight = V_Bottom - V_Top

	ControlInfo/W=$win CPLine
	Variable lineHeight = V_height

	SetVariable CPLine, win=$win, pos={0, 0},          size={panelWidth, lineHeight}
	ListBox   CPBuffer, win=$win, pos={0, lineHeight}, size={panelWidth, panelHeight - lineHeight}
End

#if Exists("PanelResolution") != 3
static Function PanelResolution(wName) // For compatibility between Igor 6 & 7
	String wName
	return 72 // that is, "pixels"
End
#endif

//------------------------------------------------------------------------------
// hook functions & control actions
//------------------------------------------------------------------.------------

// Window hook
static Function WinProc(s)
	STRUCT WMWinHookStruct &s
	
	// CommandPanel window is a singleton:
	// Window-copying is disable 
	if(!StringMatch(s.winName, "CommandPanel"))
		KillWindow $s.winName
		return NaN
	endif
	
	
	switch(s.eventCode)
		case 0: // activate
		case 6: // resize
			UpdateTitle(s.winName)
			ResizeControls(s.winName)	
			break

		case 2: // kill
			GetWindow $s.winName wsizeOuter
			SetNumWave("panelRect", {V_left, V_top, V_right, V_bottom})
			break
			
	endSwitch
End

// Control actions
static Function LineAction(s)
	STRUCT WMSetVariableAction &s
	
	if(s.eventCode == 2) // key input
		Variable key = s.eventMod
		
		switch(key)
			case 0: // Enter
				ExecuteLine(s.win)
				if(IgorVersion() < 7)
					SetVariable/Z CPLine, win=$s.win, activate
				endif
				break
			case 2: // Shift + Enter
				Complete()
				break
			case 4: // Alt + Enter
				AltComplete()
				break
		endswitch
	endif
	
	if(IgorVersion() < 7)
		UpdateTitle(s.win)
		SetVariable/Z CPLine, win=$s.win, activate
	endif
End

static Function BufferAction(s)
	STRUCT WMListboxAction &s

	if(s.eventCode == 1) // mouse down
		if(s.eventMod > 15) // contextual menu click
			CommandPanel_SelectRows(GetNumWave("selectedRows"))
			DoUpdate // necessary for multiple line selection
			
			PopupContextualMenu "execute;" // other contextual menu items are unimplemented
			
			WAVE/T line = GetTxtWave("line")
			WAVE sel = CommandPanel_SelectedRows()
			Variable i, N = DimSize(sel, 0)

			strSwitch(S_selection)
				case "execute":
					String cmd = ""
					for(i = 0; i < N; i += 1)
						cmd += line[sel[i]] + ";; "
					endfor
					cmd = RemoveEnding(cmd, ";; ")
									
					// Execute selected rows
					CommandPanel_SetLine(cmd)
					ExecuteLine(s.win)
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
		UpdateTitle(s.win)
		SetVariable CPLine, win=$s.win, activate
	endif
End

//==============================================================================
// Execution
//==============================================================================

//------------------------------------------------------------------------------
// Execution
//------------------------------------------------------------------------------

static Function ExecuteLine(win)
	String win

	if(null(GetAlias("")))
		Alias("alias=CommandPanel#Alias")
	endif
		
	SetVar("lineChanged",0)
	SetVar("bufferChanged",0)

	// get command
	String input=CommandPanel_GetLine()
	if(strlen(input)==0)
		History()
		return NaN
	endif

	// expand & execute command
	Variable error
	String output=""
	ExpandAndExecute(input,output,error)
	
	// history
	if(!error)
		SetHistory(input)
		if( ! GetVar("lineChanged") )
			CommandPanel_SetLine("")
		endif
	endif
	
	if( StringMatch(GetConfig("refocus", "No"), "Yes") )
		DoWindow/F $win
	endif
	
	// output
	if( GetVar("bufferChanged") )
		return NaN
	elseif( strlen(output) )
		CommandPanel_SetBuffer(init(split(output,"\r")))
	else		
		History()
	endif
	
End

static Function ExpandAndExecute(input, output, error)
	String input, &output; Variable &error
	
	WAVE/T cmds = Expand(input)
	if(DimSize(commands,0) == 0)
		Make/FREE/T cmds = {input}
	endif
	Variable i,N=DimSize(cmds,0)
	for(i=0;i<N;i+=1)
		print num2char(cmpstr(IgorInfo(2),"Macintosh") ? 42 : -91) + cmds[i] + "\r"
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

//------------------------------------------------------------------------------
// History
//------------------------------------------------------------------------------

static FUnction SetHistory(cmd)
	String cmd
	
	WAVE/T w = GetTxtWave("history")
	
	// histEraseDups option
	if( StringMatch(GetConfig("histEraseDups", "No"), "Yes") )
		Extract/T/O w, w, cmpstr(w, cmd)
	endif

	InsertPoints 0, 1, w
	w[0] = cmd
	
	// histIgnoreDups option
	if( StringMatch(GetConfig("histIgnoreDups", "No"), "Yes") )
		if( DimSize(w, 0) > 1 && cmpstr(w[0], w[1]) == 0 )
			DeletePoints 0, 1, w
		endif
	endif
	
	// histIgnoreSpace option
	if( StringMatch(GetConfig("histIgnoreSpace", "No"), "Yes") )
		if(StringMatch(w[0]," *"))
			DeletePoints 0, 1, w
		endif
	endif

	// histIgnore option
	String ignore = GetConfig("histIgnore", ";")	
	Variable i, N = ItemsInList(ignore)
	for(i = 0; i < N; i += 1)
		if(StringMatch(w[0], StringFromList(i, ignore)))
			DeletePoints 0, 1, w
			break		
		endif
	endfor
	
	// histSize option
	Extract/T/O w, w, p < Str2Num(GetConfig("histSize", "inf")) 

	SetTxtWave("history", w)
End

static Function/WAVE GetHistory()
	return GetTxtWave("history")
End

static Function History()
	CommandPanel_SetBuffer( GetHistory() )
End

//==============================================================================
// Expansion
//==============================================================================

static Function/WAVE Expand(input)
	String input

	// 1. strong line splitting
	WAVE/T w1 = StrongLineSplit(input)

	// 2. alias expansion
	w1 = ExpandAlias(w1)

	// 3. brace expansion
	WAVE/T w2 = concatMap(ExpandBrace, w1)
	w2 = UnescapeBraces(w2)
	
	// 4. pathname expansion
	WAVE/T w3 = concatMap(ExpandPath, w2)
	
	// 5. weak line splitting
	WAVE/T w4 = concatMap(WeakLineSplit,w3)

	// 6. parenthesis completion
	w4 = UnescapeBackquotes(CompleteParen(w4))

	return w4
End

//------------------------------------------------------------------------------
// Utilities to expand expressions
//------------------------------------------------------------------------------

// s = "123456", w = {"a", "bc", "def"},
// SplitAs(s,w) -> {"1", "23", "456"}.
static Function/WAVE SplitAs(s,w)
	String s; WAVE/T w
	Variable i, j, N = DimSize(w, 0)
	Make/FREE/T/N=(N) buf
	for(i = 0, j = 0; i < N; j += strlen(w[i]), i += 1)
		buf[i] = s[j, j+strlen(w[i])-1]
	endfor
	return buf
End

// Alias of SplitAs(s, partition(mask(s), expr))
static Function/WAVE PartitionWithMask(s,expr)
	String s,expr
	return SplitAs(s, partition(mask(s), expr))
End

// Remove " "
// This is used to write regular expressions clearly
static Function/S trim(s)
	String s
	return ReplaceString(" ",s,"")
End

// w1 = {"a", "b"}, w2 = {"1", "2"}
// product(w1, w2) -> {"a1", "a2", "b1", "b2"}
static Function/WAVE product(w1,w2)
	WAVE/T w1,w2
	Variable n1 = DimSize(w1, 0), n2 = DimSize(w2, 0)
	if(n1 * n2)
		Make/FREE/T/N=(n1*n2) w = w1[floor(p / n2)] + w2[mod(p, n2)]
	else
		Make/FREE/T/N=0 w
	endif
	return w
End

//------------------------------------------------------------------------------
// 0. Escape Sequence 
//------------------------------------------------------------------------------
static strconstant M ="|" // a meaningless character for masking

static Function/S Mask(s)
	String s
	
	// mask comment
	s = gsub(s, "//.*$", "", proc = Mask_)
	// mask `.*`
	s = gsub(s, "\\\\\\\\|\\\\`|`(\\\\\\\\|\\\\`|[^\\`])*`","",proc = Mask_)
	// mask ".*"
	s = gsub(s, "\\\\\\\\|\\\\\"|\"(\\\\\\\\|\\\\\"|[^\\\"])*\"","",proc = Mask_)
	// mask \.
	s = gsub(s, "\\\\\\\\|\\\\{|\\\\}|\\\\,","",proc = Mask_)

	return s
End

static Function/S Mask_(s)
	String s

	Variable i; String buf=""
	for(i = 0; i < strlen(s); i += 1)
		buf += M
	endfor
	return buf
End

// Unescape
static Function/S UnescapeBraces(s)
	String s

	String ignore = "//.*$|\\\\\\\\|\\\\`|`(\\\\\\\\|\\\\`|[^\\`])*`|\\\\\"|\"(\\\\\\\\|\\\\\"|[^\\\"])*\""
	String pattern = "\\\\{|\\\\}\\\\,"
	return gsub(s ,ignore+"|"+pattern, "", proc = UnescapeBrace)
End

static Function/S UnescapeBrace(s)
	String s

	return SelectString(GrepString(s, "^\\\\[^\\\\`]$"), s, s[1])
End

static Function/S UnescapeBackquotes(input)
	String input

	return gsub(input, "//.*$|\\\\\\\\|\\\\`|`", "", proc = UnescapeBackquote)
End

static Function/S UnescapeBackquote(s)
	String s
	return SelectString(StringMatch(s,"`"),s,"")
End

//------------------------------------------------------------------------------
// 1, 5. Line Splitting 
//------------------------------------------------------------------------------

static Function/WAVE StrongLineSplit(input)
	String input

	return LineSplitBy(";;", input, mask(input))
End

static Function/WAVE WeakLineSplit(input)
	String input

	return LineSplitBy(";", input, mask(input))
End

static Function/WAVE LineSplitBy(delim, input, masked)
	String delim, input ,masked

	Variable pos = strsearch(masked, delim, 0)
	if(pos < 0)
		return cast({input})
	endif
	Variable pos2 = pos + strlen(delim)
	return cons(input[0, pos-1], LineSplitBy(delim, input[pos2, inf], masked[pos2, inf]))
End

//------------------------------------------------------------------------------
// 2. Line Splitting 
//------------------------------------------------------------------------------

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

	WAVE/T w=partition(input,"^\\s*(\\w*)") //space,alias,args
	if(strlen(w[1])==0)
		return input
	endif
	Duplicate/FREE/T GetAlias(""), als
	Extract/FREE/T als,als,StringMatch(als,w[1]+"=*")
	if(null(als))
		return input
	else
		String cmd=(head(als))[strlen(w[1])+1,inf]
		return w[0]+ExpandAlias_(cmd)+w[2]
	endif
End

static Function SetAlias(name, str)
	String name, str
	
	WAVE/T w = GetTxtWave("alias")
	Extract/T/FREE w, buf, cmpstr( (w)[0, strlen(name)] ,name+"=") != 0
	if(strlen(str))
		InsertPoints 0, 1, buf
		buf[0] = name + "=" + str
	endif
	SetTxtWave("alias", buf)
End

static Function/WAVE GetAlias(name)
	String name
	
	Duplicate/FREE/T GetTxtWave("alias") w
	if(strlen(name))
		Extract/T/O w, w, cmpstr( (w)[0, strlen(name)] ,name+"=") == 0
		if(DimSize(w, 0))
			w = StringByKey(name, w[0], "=")
		endif
	endif
	return w	
End

static Function Alias(expr)
	String expr

	if(GrepString(expr, "=")) // alias("a=alias") -> SetAlias("a", "alias")
		String name = StringFromList(0, expr, "=")
		String str = expr[strlen(name)+1, inf]
		SetAlias(name, str)
	else

		if(strlen(expr)) // alias("a") shows the alias represented by "a"
			WAVE/T w = GetAlias(expr)
			Make/FREE/T/N=(DimSize(w, 0)) word = expr + "=" + w
		else
			WAVE/T w = GetAlias("") // alias("") shows all aliases
			Make/FREE/T/N=(DimSize(w, 0)) word = w
		endif
		
		Make/FREE/T/N=(DimSize(w, 0)) buffer, line
		buffer = "[alias] " + w
		line = "CommandPanel#Alias(\"" + w + "\")"
		
		sort word, word, buffer, line
		CommandPanel_SetBuffer(word, buffer = buffer, line = line)
	endif
End

//------------------------------------------------------------------------------
// 3. Brace Expansion
//------------------------------------------------------------------------------

static Function/WAVE ExpandBrace(input)
	String input

	return ExpandSeries(ExpandCharacterSeries(ExpandNumberSeries(input)))
End

static Function/WAVE ExpandSeries(input)
	String input

	WAVE/T w=SplitAs(input,partition(mask(input),trim("( { ([^{}] | {[^{}]*} | (?1))* , (?2)* } )")))
	if(strlen(w[1])==0)
		return cast({input})
	endif
	WAVE/T body = ExpandSeries_((w[1])[1,strlen(w[1])-2])
	body = w[0] + body + w[2]
	return concatMap(ExpandSeries,body)
End

static Function/WAVE ExpandSeries_(body) // expand inside of {} once
	String body

	if(strlen(body) == 0)
		return cast({""})
	elseif(StringMatch(body[0], ","))
		return cons("", ExpandSeries_(body[1,inf]))
	elseif(!GrepString(body,"{|}|\\\\"))
		Variable size = ItemsInList(body, ",") + StringMatch(body[strlen(body)-1], ",")
		Make/FREE/T/N=(size) w = StringFromList(p, body, ",")
		return w
	endif
	WAVE/T w=PartitionWithMask(body,trim("^( ( [^{},] | ( { ([^{}]*|(?3)) } ) )* )"))
	if(strlen(w[2]))
		return cons(w[1],ExpandSeries_( (w[2])[1,inf] ))
	else
		return cast({w[1]})
	endif
End

static Function/S ExpandNumberSeries(input)
	String input

	WAVE/T w=partition(input,trim("( { ([+-]?\\d+) \.\. (?2) (\.\. (?2))? } )"))
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

	WAVE/T w=partition(input,trim("( { ([a-zA-Z]) \.\. (?2) (\.\. ([+-]?\\d+))? } )"))
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

//------------------------------------------------------------------------------
// 4. Path Expansion
//------------------------------------------------------------------------------

static Function/WAVE ExpandPath(input)
	String input
	WAVE/T w = PartitionWithMask(input,trim("(?<!\\w)(root)?(:[a-zA-Z\\*][\\w\\*]* | :'[^:;'\"]+')+ :?"))
	if(strlen(w[1])==0)
		return cast({input})
	endif
	return product( cast({w[0]}), product(ExpandPathImpl(w[1]), ExpandPath(w[2])))
End

static Function/WAVE ExpandPathImpl(path) // implement of path expansion
	String path
	WAVE/T token = SplitAs(path,scan(mask(path),":|[^:]+:?"))
	WAVE/T buf   = ExpandPathImpl_(head(token),tail(token))
	if(null(buf))
		return cast({path})		
	endif
	return buf
End

static Function/WAVE ExpandPathImpl_(path,token)
	String path; WAVE/T token
	if(null(token))
		return cast({path})
	elseif(length(token)==1)
		if(cmpstr(head(token),"**:")==0)
			WAVE/T fld = GlobFolders(path)
			fld=path+fld+":"
			return fld
		elseif(GrepString(head(token),":$")) // *: -> {fld1:, fld2:}
			WAVE/T w = Folders(path)
			Extract/T/FREE w,fld,PathMatch(w,RemoveEnding(head(token),":"))
			fld=path+fld+":"
			return fld
		else // * -> {wave, var, str, fld} 
			WAVE/T w = Objects(path)
			Extract/T/FREE w,obj,PathMatch(w,RemoveEnding(head(token),":"))
			obj=path+obj
			return obj		
		endif
	else
		if(cmpstr(head(token),"**:")==0)
			WAVE/T fld = GlobFolders(path)
			InsertPoints 0,1,fld
			fld=path+fld+":"
			fld[0]=RemoveEnding(fld[0],":")
		else
			WAVE/T w = Folders(path)
			Extract/T/FREE w,fld,PathMatch(w,RemoveEnding(head(token),":"))
			fld=path+fld+":"
		endif
		Variable i,N=length(fld); Make/FREE/T/N=0 buf
		for(i=0;i<N;i+=1)
			Concatenate/NP/T {ExpandPathImpl_(fld[i],tail(token))},buf
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
	if(!null(w))
		w=RemoveEnding(RemoveBeginning(w,path),":")
	endif
	return w
End

static Function/WAVE GlobFolders_(path)
	String path
	WAVE/T fld=Folders(path); fld=path+fld+":"
	Variable i,N=length(fld); Make/FREE/T/N=0 buf
	for(i=0;i<N;i+=1)
		Concatenate/T/NP {cast({fld[i]}), GlobFolders_(fld[i])},buf
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

//------------------------------------------------------------------------------
// 6. Complete Parenthesis
//------------------------------------------------------------------------------

static Function/S CompleteParen(input)
	String input
	String ref = gsub(gsub(input, "(\\\\\")", "", proc=Mask_), "(\"[^\"]*\")", "", proc=Mask_)
	WAVE/T w = SplitAs(input, partition(ref, "\\s(//.*)?$")) // command, comment, ""
	WAVE/T f = partition(w[0], "^\\s*[a-zA-Z]\\w*(#[a-zA-Z]\\w*)?\\s*") // "", function, args
	String info = FunctionInfo(trim(f[1]))
	if(strlen(info) == 0 || GrepString(f[2], "^\\("))
		return input
	elseif(NumberByKey("N_PARAMS", info) == 1 && NumberByKey("PARAM_0_TYPE", info) == 8192 && ! GrepString(f[2], "^ *\".*\" *$"))
		f[2] = "\"" + f[2] + "\""
	endif
	return sub(f[1], " *$", "") + "(" + f[2] + ")" + w[1]
End


//==============================================================================
// Completion
//==============================================================================

static Function Complete()
	String input = CommandPanel_GetLine(), selrow=""
	WAVE/T line = GetTxtWave("line")

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
	
	WAVE/T line = GetTxtWave("line")
	Variable size = DimSize(line, 0)
	if(size)
		Variable num = mod(CommandPanel_SelectedRow() + size + n, size)
		CommandPanel_SelectRow(num)
		CommandPanel_SetLine(line[num])
	endif
End

// for a string beginning with whitespace 
static Function FilterBuffer()
	WAVE/T word = GetTxtWave("word")
	Duplicate/FREE/T GetTxtWave("line") line
	Duplicate/FREE/T GetTxtWave("buffer") buf

	if(DimSize(buf, 0) > 0)
		String patterns = RemoveFromList("", CommandPanel_GetLine(), " ")
		Variable i, N=ItemsInList(patterns, " ")
		for(i = 0; i < N; i += 1)
			String pattern = StringFromList(i, patterns, " ")
			if( StringMatch(GetConfig("ignoreCase", "Yes"), "Yes") )
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
static Function CompleteOperationName()
	String line = CommandPanel_GetLine(), pre, word
	SplitString/E="(.*;)? *([A-Za-z]\\w*)$" line, pre, word
	
	String list = FunctionList(word + "*", ";", "KIND:2") + OperationList(word + "*", ";", "all")
	Make/FREE/T/N=(ItemsInList(list)) oprs = StringFromList(p, list)

	Duplicate/FREE/T GetAlias("") als
	als = StringFromList(0, als, "=")
	
	Make/FREE/T/N=0 buf
	Concatenate/T/NP {als, oprs}, buf
	
	Extract/T/FREE buf, buf, StringMatch(buf, word + "*")
	buf = pre + buf
	if(DimSize(buf, 0))
		CommandPanel_SetBuffer(buf)
		CommandPanel_SetLine(buf[0])	
	endif
End

// for the second or any later word
static Function CompleteFunctionName()
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

//==============================================================================
// Utilities
//==============================================================================

//------------------------------------------------------------------------------
// Package utilities
//------------------------------------------------------------------------------

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

//------------------------------------------------------------------------------
// Strings utilities
//------------------------------------------------------------------------------

// Corresponding to Ruby's s.partition(/expr/)
static Function/WAVE partition(s, expr)
	String s, expr

	expr = IncreaseSubpatternNumber(2, expr)
	String pre, pst
	if(GrepString(expr, "^\\^")) // ^...(...) -> ^()...(...)
		expr = "^()(" + expr[1, inf] + ")"
	elseif(GrepString(expr, "^\\(+\\^")) // ((^...)) -> ^(.*)((...))
		SplitString/E="^(\\(+)\\^(.*)" expr, pre, pst
		expr = "^(.*?)" + "(" + pre + pst + ")"
	else
		expr = "(.*?)(" + expr + ")"
	endif
	String head, body, tail
	SplitString/E=expr s, head, body
	tail = s[strlen(head + body), inf]
	if(strlen(body) == 0)
		Make/FREE/T w={s, "", ""}
	else
		Make/FREE/T w={head, body, tail}
	endif
	return w
End

// Corresponding to Ruby's s.scan(/expr/)
static Function/WAVE scan(s, expr)
	String s, expr

	WAVE/T w = SubPatterns(s, "(" + IncreaseSubpatternNumber(1, expr) + ")")
	Variable num = DimSize(w, 0)
	if(num > 1 || strlen(expr) == 0)
		DeletePoints 0, 1, w
	endif
	if(DimSize(w, 0)==0 || hasCaret(expr) )
		return w
	else
		WAVE/T part = partition(s, expr)
		if(num > 1)
			WAVE/T buf = scan(part[2], expr)
			Variable Nw = DimSize(w, 0), Nb = DimSize(buf, 0)
			if(Nb > 0 && Nb > Nw)
				InsertPoints Nw, Nb - Nw, w 
			elseif(Nb > 0)
				InsertPoints Nb, Nw - Nb, buf 			
			endif
			Concatenate/T {buf}, w
		else
			Concatenate/T/NP {scan(part[2], expr)}, w
		endif
		return w
	endif
End

// Corresponding to Ruby's s.split(/expr/)
static Function/WAVE split(s,expr)
	String s,expr

	if(strlen(expr) == 0 && strlen(s))
		Make/FREE/T/N=(strlen(s)) w=s[p]; return w
	endif
	WAVE/T w = partition(s,expr)
	if(strlen(w[1]) == 0)
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

// Corresponding to Ruby's s.sub(/expr/, "alt") or s.sub(/expr/){proc}
static Function/S sub(s, expr, alt [, proc])
	String s, expr, alt; FUNCREF CommandPanelProtoType_Sub proc

	WAVE/T w = partition(s, expr)
	if(strlen(w[1]) == 0)
		return s
	endif
	if(!ParamIsDefault(proc))
		return w[0] + proc(w[1]) + w[2]
	endif
	WAVE/T a = split(alt, "(\\\\\\d|\\\\&|\\\\`|\\\\'|\\\\+)")
	Variable i, N = DimSize(a, 0)
	alt=""
	for(i = 0; i < N; i += 1)
		if(GrepString(a[i], "\\\\0|\\\\&"))
			alt += w[1]
		elseif(GrepString(a[i], "\\\\`"))
			alt += w[0]
		elseif(GrepString(a[i], "\\\\'"))
			alt += w[2]
		elseif(GrepString(a[i], "\\\\\\d"))
			Variable num=Str2Num((a[i])[1])
			WAVE/T sub = SubPatterns(s, expr)
			if(DimSize(sub, 0) +1 > num)
				alt += sub[num -1]
			endif
		else
			alt += a[i]
		endif
	endfor
	return w[0] + alt + w[2]
End

// Corresponding to Ruby's s.gsub(/expr/, "alt") or s.gsub(/expr/){proc}
static Function/S gsub(s, expr, alt [, proc])
	String s, expr, alt; FUNCREF CommandPanelProtoType_Sub proc
	WAVE/T w = partition(s, expr)
	if(strlen(w[1]) == 0)
		return s
	elseif(hasCaret(expr) || hasDollar(expr))
		if(ParamIsDefault(proc))
			return sub(s, expr, alt)
		else
			return sub(s, expr, alt, proc=proc)		
		endif
	else
		if(ParamIsDefault(proc))
			return sub(w[0] + w[1],expr,alt)+gsub(w[2],expr,alt)		
		else
			String buf = sub(w[0] + w[1], expr, alt, proc = proc)
			return buf + gsub(w[2], expr, alt, proc = proc)
		endif
	endif	
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
	if(strlen(body) == 0)
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

Function/S CommandPanelProtoType_Sub(s)
	String s
	return s
End

//------------------------------------------------------------------------------
// Text waves utilities
//------------------------------------------------------------------------------

static Function/WAVE cast(w)
	WAVE/T w
	if(WaveExists(w))
		Make/FREE/T/N=(DimSize(w,0)) f=w
	else
		Make/FREE/T/N=0 f
	endif
	return f
End

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

static Function null(w)
	WAVE/T w
	return !length(w)
End

static Function length(w)
	WAVE/T w
	return numpnts(cast(w))
End

static Function/WAVE map(f,w)
	FUNCREF CommandPanelProtoType_Id f; WAVE/T w
	WAVE/T buf=cast(w)
	if(length(buf))
		buf=f(w)
	endif
	return buf
End

static Function/WAVE concatMap(f,w)
	FUNCREF CommandPanelProtoType_Split f; WAVE/T w
	Make/FREE/T/N=0 buf
	Variable i,N = DimSize(w, 0)
	for(i = 0; i < N; i += 1)
			Concatenate/T/NP {f(w[i])}, buf
	endfor
	return buf
End

override Function/S CommandPanelProtoType_Id(s)
	String s

	return s
End

override Function/WAVE CommandPanelProtoType_Split(s)
	String s

	Make/FREE/T/N=(ItemsInList(s)) w = StringFromList(p,s)
	return w
End
