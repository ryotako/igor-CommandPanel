#pragma ModuleName=CommandPanel

Function/S CommandPanel_PrototypeFunc1(s)
	String s
	return s
End
Function/WAVE CommandPanel_PrototypeFunc2(s)
	String s
	Make/FREE/T w={s}; return w
End
strconstant CommandPanel_Menu = "CommandPanel"

Menu StringFromList(0,CommandPanel_Menu)
	RemoveListItem(0,CommandPanel_Menu)
	"New Command Panel",/Q,CommandPanel_New()
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
	String win=CommandPanel#Target(N=i)
	GetWindow/Z $win,wtitle
	if(strlen(win))
		return "\M0"+win+" ("+S_Value+")"
	else
		return ""
	endif
End
static Function MenuCommand(i)
	Variable i
	DoWindow/F $CommandPanel#Target(N=i)
End

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

// history options
constant CommandPanel_HistEraseDups = 0
constant CommandPanel_HistIgnoreDups = 0
constant CommandPanel_HistIgnoreSpace = 0
strconstant CommandPanel_HistIgnore = ";"

// Public Functions {{{1
Function CommandPanel_Execute()
	String input    = CommandPanel_GetLine()
	CommandPanel_SetLine("")
	CommandPanel_GetBuffer() // reset flag
	
	// Prepare
	WAVE/T history=CommandPanel#GetTextWave("history")
	if(strlen(input)==0)
		CommandPanel_SetBuffer(history)
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
		CommandPanel_SetBuffer(history)
		CommandPanel_SetLine(input)
	else
		AddHistory(ReplaceString("\\",input,"\\\\"))
	endif
		
	if(strlen(output))
		Make/FREE/T/N=(ItemsInList(output,"\r")) f=StringFromList(p,output,"\r")
		CommandPanel_SetBuffer(f)
	endif

	if(!CommandPanel#BufferModified())
		CommandPanel_SetBuffer(history)		
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



// Public Functions
Function/WAVE CommandPanel_Expand(input)
	String input
	return Expand(input)
End
Function/WAVE CommandPanel_Alias(input)
	String input
	WAVE/T w=Alias(input)
	if(length(w))
		CommandPanel_SetBuffer(w)
	endif
	return w
End

// Functions
static Function/WAVE Expand(input)
	String input
	return bind(bind(bind(bind(bind(bind(bind(return(input),StrongLineSplit),ExpandAlias),ExpandBrace),ExpandPath),WeakLineSplit),CompleteParen),RemoveEscapeWhole)
End

// Utils
static Function/WAVE SplitAs(s,w)
	String s; WAVE/T w
	if(null(w))
		return void()
	endif
	Variable len=strlen(head(w))
	return cons(s[0,len-1],SplitAs(s[len,inf],tail(w)))
End
static Function/WAVE PartitionWithMask(s,expr)
	String s,expr
	return SplitAs(s,partition(mask(s),expr))
End
static Function/S trim(s)
	String s
	return ReplaceString(" ",s,"")
End
static Function/S join(w)
	WAVE/T w
	if(null(w))
		return ""
	endif
	return head(w)+join(tail(w))
End
static Function/WAVE product(w1,w2) //{"a","b"},{"1","2"} -> {"a1","a2","b1","b2"}
	WAVE/T w1,w2
	if(null(w1))
		return void()
	endif
	Make/FREE/T/N=(DimSize(w2,0)) f=head(w1)+w2
	return concat(f,product(tail(w1),w2))
End


// 0,7 Escape Sequence {{{1
static strconstant M ="|" // one character for masking
static Function/S Mask(input)
	String input
	input = MaskExpr(input,"(//.*)$") // //
	input = MaskExpr(input,"(\\\\\\\\)") // \
	input = MaskExpr(MaskExpr(input,"(\\\\`)" ),"(`[^`]*`)"   ) // `
	input = MaskExpr(MaskExpr(input,"(\\\\\")"),"(\"[^\"]*\")") // "
	input = MaskExpr(input,trim("(\\\\{ | \\\\} | \\\\,)")) // {},
	return input
End
static Function/S MaskExpr(s,expr)
	String s,expr
	WAVE/T w=partition(s,expr)
	if(strlen(w[1])==0)
		return s
	endif
	return w[0]+RepeatChar(M,strlen(w[1])) + MaskExpr(w[2],expr)
End
static Function/S RepeatChar(c,n)
	String c; Variable n
	if(NumType(n)||n<=0)
		return ""
	endif
	return c[0]+RepeatChar(c,n-1)
End

static Function/WAVE RemoveEscapeSeqBrace(input)
	String input
	String ref
	ref = input
	ref = ReplaceString("\\\\",ref,M+M)
	ref = ReplaceString("\\`" ,ref,M+M)
	input = ReplaceByRef("\\{",input,"{",ref)
	ref = input
	ref = ReplaceString("\\\\",ref,M+M)
	ref = ReplaceString("\\`" ,ref,M+M)
	input = ReplaceByRef("\\}",input,"}",ref)
	ref = input
	ref = ReplaceString("\\\\",ref,M+M)
	ref = ReplaceString("\\`" ,ref,M+M)
	input = ReplaceByRef("\\,",input,",",ref)
	return return(input)
End
static Function/WAVE RemoveEscapeWhole(input)
	String input
	String ref = input
	ref = ReplaceString("\\\\",input,M+M)
	ref = ReplaceString("\\`" ,input,M+M)
	input = ReplaceByRef("`",input,"",ref)	
	input = ReplaceString("\\`",input,"`")
	return return(input)
End
static Function/S ReplaceByRef(before,input,after,ref)
	String before,input,after,ref
	do
		Variable pos=strsearch(ref,before,inf,1)
		if(pos>=0)
			input = input[0,pos-1]+after+input[pos+strlen(before),inf]
			ref   = ref  [0,pos-1]+after+ref  [pos+strlen(before),inf]
		else
			break
		endif
	while(1)
	return input
End


// 1,5 Line Split {{{1
static Function/WAVE LineSplitBy(delim,input)
	String delim,input
	Variable pos = strsearch(mask(input),delim,0)
	if(pos<0)
		return return(input)
	endif
	return cons(input[0,pos-1],LineSplitBy(delim,input[pos+strlen(delim),inf]))
End
static Function/WAVE StrongLineSplit(input)
	String input
	return LineSplitBy(";;",input)
End
static Function/WAVE WeakLineSplit(input)
	String input
	return LineSplitBy(";",input)
End


// 2. Alias Expansion
static Function/WAVE ExpandAlias(input)
	String input
	// WAVE/T w=SplitAs(input,partition(mask(input),";"))// line, ;, lines
	WAVE/T w=PartitionWithMask(input,";")// line, ;, lines
	if(strlen(w[1])==0)
		return ExpandAlias_(input)
	endif
	return return( join(concat(ExpandAlias_(w[0]+w[1]),ExpandAlias(w[2]))) )
End
static Function/WAVE ExpandAlias_(input) // one line
	String input
	WAVE/T w=partition(input,"^\\s*(\\w*)") //space,alias,args
	if(strlen(w[1])==0)
		return return(input)
	endif
	Duplicate/FREE/T GetAliasWave(),als
	Extract/FREE/T als,als,StringMatch(als,w[1]+"=*")
	if(null(als))
		return return(input)
	else
		String cmd=(head(als))[strlen(w[1])+1,inf]
		return return(w[0]+head(ExpandAlias_(cmd))+w[2])
	endif
End

static Function/WAVE Alias(input)
	String input
	Duplicate/T/FREE GetAliasWave() alias
	if(strlen(trim(input))==0)
		return alias
	endif
	WAVE/T w=PartitionWithMask(input,"^(\\s*\\w+\\s*=\\s*)") //blank,alias=,string
	if(strlen(w[1]))
		Extract/FREE/T alias,alias,!StringMatch(alias,trim(w[1])+"*")
		InsertPoints 0,1,alias; alias[0] = trim(w[1])+w[2]
		SetAliasWave(alias)
	endif
	return void()
End

static Function/WAVE GetAliasWave()
	WAVE/T w=root:Packages:CommandPanel:alias
	if(WaveExists(w))
		return w
	endif
	return void()
End
static Function/WAVE SetAliasWave(w)
	WAVE/T w
	if(WaveExists(w) && !WaveRefsEqual(w,GetAliasWave()))
		NewDataFolder/O root:Packages
		NewDataFolder/O root:Packages:CommandPanel
		Duplicate/O/T w root:Packages:CommandPanel:alias
	endif
End

// 3. Brace Expansion
static Function/WAVE ExpandBrace(input)
	String input
	return bind(bind(bind(bind(return(input),ExpandNumberSeries),ExpandCharacterSeries),ExpandSeries),RemoveEscapeSeqBrace)
End

static Function/WAVE ExpandSeries(input)
	String input
	WAVE/T w=SplitAs(input,partition(mask(input),trim("( { ([^{}] | {[^{}]*} | (?1))* , (?2)* } )")))
	if(strlen(w[1])==0)
		return return(input)
	endif
	WAVE/T ww=ExpandSeries_((w[1])[1,strlen(w[1])-2]); ww=w[0]+ww+w[2]
	return bind(ww,ExpandSeries)
End
static FUnction/WAVE ExpandSeries_(body) // expand inside of {} once
	String body
	if(strlen(body)==0)
		return return("")
	elseif(StringMatch(body[0],","))
		return cons("",ExpandSeries_(body[1,inf]))
	endif
	// WAVE/T w=SplitAs(body,partition(mask(body),trim("^( ( [^{},] | ( { ([^{}]*|(?3)) } ) )* )")))
	WAVE/T w=PartitionWithMask(body,trim("^( ( [^{},] | ( { ([^{}]*|(?3)) } ) )* )"))
	if(strlen(w[2]))
		return cons(w[1],ExpandSeries_( (w[2])[1,inf] ))
	else
		return return(w[1])
	endif
End
static Function/WAVE ExpandNumberSeries(input)
	String input
	WAVE/T w=partition(input,trim("( { ([+-]?\\d+) \.\. (?2) (\.\. (?2))? } )"))
	if(strlen(w[1])==0)
		return return(input)
	endif
	String fst,lst,stp; SplitString/E="{([+-]?\\d+)\.\.((?1))(\.\.((?1)))?}" w[1],fst,lst,stp,stp
	Variable v1=Str2Num(fst), v2=Str2Num(lst), vd = abs(Str2Num(stp)); vd = NumType(vd) || vd==0 ? 1 : vd
	Variable i,N=floor(abs(v1-v2)/vd+1); String s=""
	for(i=0;i<N;i+=1)
		s+=Num2Str(v1+i*vd*sign(v2-v1))+","
	endfor
	s=RemoveEnding(s,",")
	return return(SelectString(N<2,w[0]+"{"+s+"}",w[0]+s)+head(ExpandNumberSeries(w[2])))
End
static Function/WAVE ExpandCharacterSeries(input)
	String input
	WAVE/T w=partition(input,trim("( { ([a-zA-Z]) \.\. (?2) (\.\. ([+-]?\\d+))? } )"))
	if(strlen(w[1])==0)
		return return(input)
	endif
	String fst,lst,stp; SplitString/E="{([a-zA-Z])\.\.((?1))(\.\.([+-]?\\d+))?}" w[1],fst,lst,stp,stp
	Variable v1=Char2Num(fst), v2=Char2Num(lst), vd = abs(Char2Num(stp)); vd = NumType(vd) || vd==0 ? 1 : vd
	Variable i,N=floor(abs(v1-v2)/vd+1); String s=""
	for(i=0;i<N;i+=1)
		s+=Num2Char(v1+i*vd*sign(v2-v1))+","
	endfor
	s=RemoveEnding(s,",")
	return return(SelectString(N<2,w[0]+"{"+s+"}",w[0]+s)+head(ExpandCharacterSeries(w[2])))
End


// 4. Path Expansion
static Function/WAVE ExpandPath(input)
	String input
	WAVE/T w = PartitionWithMask(input,trim("(?<!\\w)(root)?(:[a-zA-Z\\*][\\w\\*]* | :'[^:;'\"]+')+ :?"))
	if(strlen(w[1])==0)
		return return(input)
	endif
	return product( return(w[0]), product(ExpandPathImpl(w[1]), ExpandPath(w[2])))
End
static Function/WAVE ExpandPathImpl(path) // implement of path expansion
	String path
	WAVE/T token = SplitAs(path,scan(mask(path),":|[^:]+:?"))
	WAVE/T buf   = ExpandPathImpl_(head(token),tail(token))
	if(null(buf))
		return return(path)		
	endif
	return buf
End
static Function/WAVE ExpandPathImpl_(path,token)
	String path; WAVE/T token
	print ">>",path
	if(null(token))
		return return(path)
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
		Concatenate/T/NP {return(fld[i]), GlobFolders_(fld[i])},buf
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
static Function/WAVE CompleteParen(input)
	String input
	String ref = MaskExpr(MaskExpr(input,"(\\\\\")"),"(\"[^\"]*\")") // escape with ""
	WAVE/T w=SplitAs(input,partition(ref,"\\s(//.*)?$")) // command, comment, ""
	WAVE/T f=partition(w[0],"^\\s*[a-zA-Z]\\w*(#[a-zA-Z]\\w*)?\\s*") // "", function, args
	String info=FunctionInfo(trim(f[1]))
	if(strlen(info)==0 || GrepString(f[2],"\\(\\s*\\)"))
		return return(input)
	elseif(NumberByKey("N_PARAMS",info)==1 && NumberByKey("PARAM_0_TYPE",info)==8192 && !GrepString(f[2],"^ *\".*\" *$"))
		f[2]="\""+f[2]+"\""
	endif
	return return( RemoveEndings(f[1]," ")+"("+f[2]+")"+w[1] )
End
static Function/S RemoveEndings(s,ending)
	String s,ending
	String buf=RemoveEnding(s,ending)
	if(strlen(buf)==strlen(s))
		return buf
	endif
	return RemoveEndings(buf,ending)
End

Function CommandPanel_Complete()
	String input=CommandPanel_GetLine(),head="",tail="",list=""
	Make/FREE/T/N=0 f
	if(GrepString(input,"^[^\"]*(\"[^\"]*\"[^\"]*)*\"[^\"]*$"))
		// exception: string literal
	elseif(GrepString(input,"^(.*;)? *([A-Za-z]\\w*)$"))
		// operation / user function
		SplitString/E="(.*;)? *([A-Za-z]\\w*)$" input,head,tail
		list=FunctionList(tail+"*",";","KIND:2")+OperationList(tail+"*",";","all")
		Make/T/FREE/N=(ItemsInList(list)) func=head+StringFromList(p,list)
		// alias
		Duplicate/T/FREE CommandPanel#GetTextWave("alias") alias; alias=GetAlias(alias)
		Extract/O/T alias,alias,StringMatch(alias,tail+"*")		
		//Concatenate/T/NP {alias,func},f // Concatenate/T is unavailable for some reasone... 
		Variable Nf=DimSize(func,0), Na=DimSize(alias,0)
		Make/FREE/T/N=(Nf+Na) f = SelectString(p<Na,func[p-Na],alias[p]) 
	elseif(GrepString(input,"(.*?)(((?<!\\w)root)?:([a-zA-Z]\\w*:|'[^:;'\"]+':)*([a-zA-Z]\\w*|'[^:;'\"]*)?)$"))
		SplitString/E="(.*?)(((?<!\\w)root)?:([a-zA-Z]\\w*:|'[^:;'\"]+':)*([a-zA-Z]\\w*|'[^:;'\"]*)?)$" input,head,tail
		WAVE/T f=PathExpand(tail)
		f=head+f
	else
		// function
		SplitString/E="(.*?)((?<!#)[A-Za-z][A-Za-z0-9_]*)$" input,head,tail
		if(strlen(tail))
			list=FunctionList(tail+"*",";","KIND:2")+FunctionList(tail+"*",";","KIND:1")
			Make/T/FREE/N=(ItemsInList(list)) f=head+StringFromList(p,list)
		endif
	endif
	CommandPanel_SetBuffer(f)
	if(DimSize(f,0) && strlen(f[0]))
		CommandPanel_SetLine(f[0])
	endif
End

static Function/S GetAlias(expr)
	String expr
	if(strlen(expr))
		String alias
		SplitString/E=("^ *([a-zA-z][a-zA-z0-9_]*) *[:=]") expr,alias
		return alias
	endif
	return ""
End

static Function/WAVE PathExpand(path)
	String path
	String head="",tail="",s
	SplitString/E="(((?<!\\w)root)?:([a-zA-Z]\\w*:|'[^:;'\"]+':)*)([a-zA-Z]\\w*|'[^:;'\"]*)?$" path,head,s,s,tail
	if(DataFolderExists(head))
		Make/T/FREE/N=(CountObjects(head,1)) wav = PossiblyQuoteName(GetIndexedObjName(head,1,p))		
		Make/T/FREE/N=(CountObjects(head,2)) var = PossiblyQuoteName(GetIndexedObjName(head,2,p))		
		Make/T/FREE/N=(CountObjects(head,3)) str = PossiblyQuoteName(GetIndexedObjName(head,3,p))		
		Make/T/FREE/N=(CountObjects(head,4)) fld = PossiblyQuoteName(GetIndexedObjName(head,4,p))
		Make/FREE/T/N=0 f; Concatenate/T/NP {wav,var,str,fld},f
		Extract/T/FREE f,f,StringMatch(f,tail+"*"); f=head+f	
		return f
	else
		Make/FREE/T/N=0 f; return f
	endif
End
// ruby-like string function

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
static Function/S IncreaseSubpatternNumber(n,s)
	Variable n; String s
	String head,body,tail
	SplitString/E="(.*?)(\\(\\?(\\d+\\)))(.*)" s,head,body,body,tail
	if(strlen(body)<1)
		return s
	endif
	return head+"(?"+Num2Str(Str2Num(body)+n)+")"+IncreaseSubpatternNumber(n,tail)
End

// Ruby: s.scan(/expr/)
static Function/WAVE scan(s,expr)
	String s,expr
	WAVE/T w=SubPatterns( s, "("+IncreaseSubpatternNumber(1,expr)+")")
	Variable num=DimSize(w,0)
	if(num>1 || strlen(expr)==0)
		DeletePoints 0,1,w
	endif
	if(DimSize(w,0)==0 || GrepString(expr,"^\\(*\\^") || GrepString(expr,"\\)*\\$$"))
		return w
	else
		WAVE/T part=partition(s,expr)
		if(num>1)
			Concatenate/T {scan(part[2],expr)},w
			if(DimSize(w,1)==0)
				Make/FREE/T/N=(DimSize(w,0),1) f=w; WAVE/T w=f
			endif
		else
			Concatenate/T/NP {scan(part[2],expr)},w
		endif
		return w
	endif
End

static Function/WAVE SubPatterns(s,expr)
	String s,expr
	DFREF here=GetDataFolderDFR(); SetDataFolder NewFreeDataFolder()
	String s_   =ReplaceString("\"",ReplaceString("\\",s   ,"\\\\"),"\\\"")
	String expr_=ReplaceString("\"",ReplaceString("\\",expr,"\\\\"),"\\\"")
	String cmd; sprintf cmd,"SplitString/E=\"%s\" \"%s\"", expr_, s_
	SplitString/E=expr s
	Make/FREE/T/N=(V_Flag) w; Variable i, N=V_Flag
	for(i=0;i<N;i+=1)
		Execute/Z "String/G s"+Num2Str(i)
		sprintf cmd,"%s,s%d",cmd,i
	endfor
	Execute/Z cmd
	for(i=0;i<N;i+=1)
		SVAR sv=$"s"+Num2Str(i)
		w[i]=sv
	endfor
	SetDataFolder here
	return w
End

// Ruby: s.split(/expr/)
static Function/WAVE split(s,expr)
	String s,expr
	WAVE/T w = partition(s,expr)
	print w
	if(strlen(w[1])==0)
		Make/FREE/T w={s}; return w
	endif
	if(strlen(w[0]))
		Make/FREE/T buf={w[0]}
	else
		Make/FREE/T/N=0 buf	
	endif
	if(GrepString(expr,"^\\(*\\^"))
		Concatenate/NP/T {SubPatterns(s,expr)},buf
		InsertPoints DimSize(buf,0),1,buf; buf[inf]=w[2]		
	else
		Concatenate/NP/T {SubPatterns(s,expr) ,split(w[2],expr) },buf
		return buf
	endif
End// haskell-like wave function

static Function length(w)
	WAVE/T w
	Variable len=DimSize(w,0)
	return NumType(len) ? 0 : len
End
static Function null(w)
	WAVE/T w
	return !length(w)
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
		return void()
	endif
	Duplicate/FREE/T w,ww
	DeletePoints 0,1,ww
	return ww
End

static Function/WAVE void()
	Make/FREE/T/N=0 w; return w
End

// Construction
static Function/WAVE cons(s,w)
	String s; WAVE/T w
	if(null(w))
		return return(s)
	endif
	Duplicate/FREE/T w,ww; InsertPoints 0,1,ww; ww[0]=s; return ww
End
static Function/WAVE concat(w1,w2)
	WAVE/T w1,w2
	if(null(w1) && null(w2))
		return void()
	elseif(null(w1))
		return cons(head(w2),tail(w2))
	endif
	return cons(head(w1),concat(tail(w1),w2))
End

// Transformation
static Function/S id(s)
	String s
	return s
End
static Function/WAVE map(f,w)
	FUNCREF CommandPanel_ProtoTypeFunc1 f; WAVE/T w
	if(null(w))
		return void()
	endif
	return cons(f(head(w)),map(f,tail(w)))
End

// Lifting
static Function/WAVE bind(w,f)
	WAVE/T w; FUNCREF CommandPanel_ProtoTypeFunc2 f
	if(null(w))
		return void()
	endif
	return concat(f(head(w)),bind(tail(w),f))
End
static Function/WAVE return(s)
	String s
	Make/FREE/T w={s}; return w
End
