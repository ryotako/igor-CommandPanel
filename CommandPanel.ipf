//------------------------------------------------------------------------------
// This procedure file is packaged by igmodule
// Sun,02 Oct 2016
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

override strconstant CommandPanel_Menu = "CommandPanel"

Menu StringFromList(0,CommandPanel_Menu)
	RemoveListItem(0,CommandPanel_Menu)
	"New Command Panel",/Q,Execute/Z "CommandPanel_New()"
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
	String win=StringFromList(i,WinList("CommandPanel_*",";","WIN:64"))
	GetWindow/Z $win,wtitle
	return SelectString(strlen(win),"","\M0"+win+" ("+S_Value+")")
End
static Function MenuCommand(i)
	Variable i
	DoWindow/F $StringFromList(i,WinList("CommandPanel_*",";","WIN:64"))
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

// Options
override strconstant CommandPanel_Font       = "Arial"
override constant    CommandPanel_Fontsize   = 12
override constant    CommandPanel_WinHeight  = 300
override constant    CommandPanel_WinWidth   = 300
override strconstant CommandPanel_WinTitle   = "'['+IgorInfo(1)+'] '+GetDataFolder(1)"

override constant    CommandPanel_KeySwap    = 0

// Public Functions

override Function CommandPanel_New()
	MakePanel()
	MakeControls()
	CommandPanel_SetLine("")
	CommandPanel_SetBuffer( CommandPanel_GetBuffer() )
End

override Function/S CommandPanel_GetLine()
	ControlInfo/W=$GetWinName() CPLine
	return SelectString(strlen(S_Value)>0,"",S_Value)
End

override Function CommandPanel_SetLine(str)
	String str
 	SetVariable CPLine,win=$GetWinName(),value= _STR:str
End

override Function/WAVE CommandPanel_GetBuffer()
	Duplicate/FREE/T GetTextWave("buffer") w
	w = ReplaceString("\\\\",w,"\\")
	return w
End

override Function CommandPanel_SetBuffer(w)
	WAVE/T w
	Duplicate/FREE/T w buf
	buf = ReplaceString("\\",w,"\\\\")
	SetTextWave("buffer",buf)
	ListBox CPBuffer, win=$GetWinName(), row=0, selrow=0
End

override Function CommandPanel_SelectedRow()
	ControlInfo/W=$GetWinName() CPBuffer
	return V_Value
End

override Function CommandPanel_SelectRow(n)
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
	NewPanel/K=1/W=(0,0,width,height)/N=$CommandPanel#SetWinName()
End

static Function MakeControls()
	String win=GetWinName()
	// Title
	DoWindow/T $win, WinTitle(CommandPanel_WinTitle)
	// Set Control Actions
 	SetVariable CPLine, win=$win, proc=CommandPanel#LineAction
	ListBox   CPBuffer, win=$win, proc=CommandPanel#BufferAction
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
			CommandPanel#Exec()
			break
		case 2: // Shift + Enter
			CommandPanel#Complete()
			break
		case 4: // Alt + Enter
			CommandPanel#AltComplete()
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
	String lhs,rhs=CommandPanel#gsub(s,"\\\\|\\\'|\'","",proc=WinTitleSpecialChar)
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
	String input=CommandPanel_GetLine(), selrow=""
	WAVE/T buf=CommandPanel_GetBuffer()
	if(DimSize(buf,0)>0)
		selrow=buf[CommandPanel_SelectedRow()]
	endif
	if(cmpstr(input,selrow,1)==0) // same as the selected buffer row 
		ScrollBuffer(1)
	elseif(strlen(input)==0) // empty string
		ScrollBuffer(0)
	elseif(GrepString(input,"^ ")) // beginning with whitespace
		FilterBuffer()
	elseif(GrepString(input,";$")) // ending with ;
		JointSelectedRow()
	elseif(GrepString(input,"^(\\\\\\\\|\\\\\\\"|[^\"])*(\"(?1)*\"(?1)*)*\"(?1)*$")) // string literal
		// do nothing
	elseif(GrepString(input,"((?<!\\w)root)?:(([a-zA-Z_]\\w*|\'[^;:\"\']+\'):)*([a-zA-Z_]\\w*|\'[^;:\"\']*)?$")) // pathname
		CompletePathname()
	elseif(GrepString(input,"^(.*;)? *([A-Za-z]\\w*)$")) // the first word
		CompleteOperationName()
	elseif(GrepString(input,"((?<!\\w)[A-Za-z]\\w*)$")) // the second and any later word
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
	WAVE/T buf=CommandPanel_GetBuffer()
	Variable size=DimSize(buf,0)
	if(size)
		Variable num=mod(CommandPanel_SelectedRow()+size+n,size)
		CommandPanel_SelectRow(num)
		CommandPanel_SetLine(buf[num])
	endif
End

// for a string beginning with whitespace 
static Function FilterBuffer()
	Duplicate/FREE/T CommandPanel_GetBuffer() buf
	if(DimSize(buf,0)>0)
		String patterns=RemoveFromList("",CommandPanel_GetLine()," ")
		Variable i,N=ItemsInList(patterns," ")
		for(i=0;i<N;i+=1)
			String pattern=StringFromList(i,patterns," ")
			if(CommandPanel_IgnoreCase)
				pattern="(?i)"+pattern
			endif
			Extract/FREE/T buf,buf,GrepString(buf,pattern)
		endfor
		CommandPanel_SetBuffer(buf)
		if(DimSize(buf,0)>0)
			CommandPanel_SetLine(buf[0])
		endif
	endif
End

// for a string ending with ;
static Function JointSelectedRow()
	String line=CommandPanel_GetLine()
	WAVE/T buf=CommandPanel_GetBuffer()
	Variable num=CommandPanel_SelectedRow()
	if(DimSize(buf,0))
		CommandPanel_SetLine(line+buf[num+1])
		CommandPanel_SelectRow(num+1)
	endif
End

// for a pathname
static Function CompletePathname()
	String line=CommandPanel_GetLine(),cmd,path,name,s
	SplitString/E="^(.*?)(((?<!\w)root)?:(([a-zA-Z_]\w*):)*)([a-zA-Z_]\w*|\'[^;:\"\']*)?$" line,cmd,path,s,s,s,name
	if(DataFolderExists(path))
		Make/FREE/T/N=(CountObjects(path,1)) wav = PossiblyQuoteName(GetIndexedObjName(path,1,p))		
		Make/FREE/T/N=(CountObjects(path,2)) var = PossiblyQuoteName(GetIndexedObjName(path,2,p))		
		Make/FREE/T/N=(CountObjects(path,3)) str = PossiblyQuoteName(GetIndexedObjName(path,3,p))		
		Make/FREE/T/N=(CountObjects(path,4)) fld = PossiblyQuoteName(GetIndexedObjName(path,4,p))
		Make/FREE/T/N=0 obj
		Concatenate/T/NP {wav,var,str,fld},obj
		Extract/T/FREE obj,obj,StringMatch(obj,name+"*")
		Make/T/FREE/N=(DimSize(obj,0)) buf=cmd+path+obj
		if(DimSize(buf,0))
			CommandPanel_SetBuffer(buf)
			CommandPanel_SetLine(buf[0])
		endif
	endif
End

// for the first word
// TODO: alias completion
override Function CompleteOperationName()
	String line=CommandPanel_GetLine(),pre,word
	SplitString/E="(.*;)? *([A-Za-z]\\w*)$" line,pre,word
	
	String list=FunctionList(word+"*",";","KIND:2")+OperationList(word+"*",";","all")
	Make/FREE/T/N=(ItemsInList(list)) oprs=StringFromList(p,list)
	
	Make/FREE/T/N=0 buf
	Concatenate/T {CommandPanel#GetAliasNames(),oprs},buf
	
	Extract/T/FREE buf,buf,StringMatch(buf,word+"*")
	buf=pre+buf
	if(DimSize(buf,0))
		CommandPanel_SetBuffer(buf)
		CommandPanel_SetLine(buf[0])	
	endif
End

// for the second or any later word
override Function CompleteFunctionName()
	String line=CommandPanel_GetLine(),prefnc,fnc
	SplitString/E="^(.*?)((?<!\\w)[A-Za-z]\\w*)$" line,prefnc,fnc
	String list=FunctionList(fnc+"*",";","KIND:3")
	Make/FREE/T/N=(ItemsInList(list)) fncs=StringFromList(p,list)
	Extract/T/FREE fncs,fncs,StringMatch(fncs,fnc+"*")
	Make/T/FREE/N=(DimSize(fncs,0)) buf=prefnc+fncs
	if(DimSize(buf,0))
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
	WAVE/T w1=CommandPanel#concatMap(StrongLineSplit,{input})
	WAVE/T w2=CommandPanel#concatMap(ExpandAlias        ,w1 )
	WAVE/T w3=CommandPanel#concatMap(ExpandBrace        ,w2 )
	w3 = UnescapeBraces(w3)
	WAVE/T w4=CommandPanel#concatMap(ExpandPath         ,w3 )
	WAVE/T w5=CommandPanel#concatMap(WeakLineSplit      ,w4 )
	WAVE/T w6=CommandPanel#concatMap(CompleteParen      ,w5 )
	w6 = UnescapeBackquotes(w6)

	return w6
End


// Utils
static Function/WAVE SplitAs(s,w)
	String s; WAVE/T w
	if(CommandPanel#null(w))
		return CommandPanel#cast($"")
	endif
	Variable len=strlen(CommandPanel#head(w))
	return CommandPanel#cons(s[0,len-1],SplitAs(s[len,inf],CommandPanel#tail(w)))
End
static Function/WAVE PartitionWithMask(s,expr)
	String s,expr
	return SplitAs(s,CommandPanel#partition(mask(s),expr))
End
static Function/S trim(s)
	String s
	return ReplaceString(" ",s,"")
End
static Function/S join(w)
	WAVE/T w
	if(CommandPanel#null(w))
		return ""
	endif
	return CommandPanel#head(w)+join(CommandPanel#tail(w))
End
static Function/WAVE product(w1,w2) //{"a","b"},{"1","2"} -> {"a1","a2","b1","b2"}
	WAVE/T w1,w2
	if(CommandPanel#null(w1))
		return CommandPanel#cast($"")
	endif
	Make/FREE/T/N=(DimSize(w2,0)) f=CommandPanel#head(w1)+w2
	return CommandPanel#extend(f,product(CommandPanel#tail(w1),w2))
End


// 0. Escape Sequence {{{1
// mask
static strconstant M ="|" // one character for masking
static Function/S Mask(input)
	String input
	// mask comment
	input=CommandPanel#gsub(input,"//.*$","",proc=MaskAll)
	// mask with ``
	input=CommandPanel#gsub(input,"\\\\\\\\|\\\\`|`(\\\\\\\\|\\\\`|[^\\`])*`","",proc=MaskAll)
	// mask with ""
	input=CommandPanel#gsub(input,"\\\\\\\\|\\\\\"|\"(\\\\\\\\|\\\\\"|[^\\\"])*\"","",proc=MaskAll)
	// mask with \
	input=CommandPanel#gsub(input,"\\\\\\\\|\\\\{|\\\\}|\\\\,","",proc=MaskAll)
	return input
End
static Function/S MaskAll(s)
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
	String ignore="//.*$|\\\\\\\\|\\\\`|`(\\\\\\\\|\\\\`|[^\\`])*`|\\\\\"|\"(\\\\\\\\|\\\\\"|[^\\\"])*\"|"
	input=CommandPanel#gsub(input,ignore+"\\\\{","",proc=UnescapeBrace)
	input=CommandPanel#gsub(input,ignore+"\\\\}","",proc=UnescapeBrace)
	input=CommandPanel#gsub(input,ignore+"\\\\,","",proc=UnescapeBrace)
	return input
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
static Function/WAVE LineSplitBy(delim,input)
	String delim,input
	Variable pos = strsearch(mask(input),delim,0)
	if(pos<0)
		return CommandPanel#cast({input})
	endif
	return CommandPanel#cons(input[0,pos-1],LineSplitBy(delim,input[pos+strlen(delim),inf]))
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
	WAVE/T w=PartitionWithMask(input,";")// line, ;, lines
	if(strlen(w[1])==0)
		return ExpandAlias_(input)
	endif
	return CommandPanel#cast({join(CommandPanel#extend(ExpandAlias_(w[0]+w[1]),ExpandAlias(w[2])))})
End
static Function/WAVE ExpandAlias_(input) // one line
	String input
	WAVE/T w=CommandPanel#partition(input,"^\\s*(\\w*)") //space,alias,args
	if(strlen(w[1])==0)
		return CommandPanel#cast({input})
	endif
	Duplicate/FREE/T GetAlias(),als
	Extract/FREE/T als,als,StringMatch(als,w[1]+"=*")
	if(CommandPanel#null(als))
		return CommandPanel#cast({input})
	else
		String cmd=(CommandPanel#head(als))[strlen(w[1])+1,inf]
		return CommandPanel#cast({w[0]+CommandPanel#head(ExpandAlias_(cmd))+w[2]})
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
	WAVE w1=CommandPanel#concatMap(ExpandNumberSeries,{input})
	WAVE w2=CommandPanel#concatMap(ExpandCharacterSeries, w1 )
	WAVE w3=CommandPanel#concatMap(ExpandSeries,          w2 )
	WAVE w4=CommandPanel#concatMap(ExpandSeries,          w3 )
	return w4
End

static Function/WAVE ExpandSeries(input)
	String input
	WAVE/T w=SplitAs(input,CommandPanel#partition(mask(input),trim("( { ([^{}] | {[^{}]*} | (?1))* , (?2)* } )")))
	if(strlen(w[1])==0)
		return CommandPanel#cast({input})
	endif
	WAVE/T ww=ExpandSeries_((w[1])[1,strlen(w[1])-2]); ww=w[0]+ww+w[2]
	return CommandPanel#concatMap(ExpandSeries,ww)
End
static FUnction/WAVE ExpandSeries_(body) // expand inside of {} once
	String body
	if(strlen(body)==0)
		return CommandPanel#cast({""})
	elseif(StringMatch(body[0],","))
		return CommandPanel#cons("",ExpandSeries_(body[1,inf]))
	endif
	WAVE/T w=PartitionWithMask(body,trim("^( ( [^{},] | ( { ([^{}]*|(?3)) } ) )* )"))
	if(strlen(w[2]))
		return CommandPanel#cons(w[1],ExpandSeries_( (w[2])[1,inf] ))
	else
		return CommandPanel#cast({w[1]})
	endif
End

static Function/WAVE ExpandNumberSeries(input)
	String input
	WAVE/T w=CommandPanel#partition(input,trim("( { ([+-]?\\d+) \.\. (?2) (\.\. (?2))? } )"))
	if(strlen(w[1])==0)
		return CommandPanel#cast({input})
	endif
	String fst,lst,stp; SplitString/E="{([+-]?\\d+)\.\.((?1))(\.\.((?1)))?}" w[1],fst,lst,stp,stp
	Variable v1=Str2Num(fst), v2=Str2Num(lst), vd = abs(Str2Num(stp)); vd = NumType(vd) || vd==0 ? 1 : vd
	Variable i,N=floor(abs(v1-v2)/vd+1); String s=""
	for(i=0;i<N;i+=1)
		s+=Num2Str(v1+i*vd*sign(v2-v1))+","
	endfor
	s=RemoveEnding(s,",")
	return CommandPanel#cast({SelectString(N<2,w[0]+"{"+s+"}",w[0]+s)+CommandPanel#head(ExpandNumberSeries(w[2]))})
End

static Function/WAVE ExpandCharacterSeries(input)
	String input
	WAVE/T w=CommandPanel#partition(input,trim("( { ([a-zA-Z]) \.\. (?2) (\.\. ([+-]?\\d+))? } )"))
	if(strlen(w[1])==0)
		return CommandPanel#cast({input})
	endif
	String fst,lst,stp; SplitString/E="{([a-zA-Z])\.\.((?1))(\.\.([+-]?\\d+))?}" w[1],fst,lst,stp,stp
	Variable v1=Char2Num(fst), v2=Char2Num(lst), vd = abs(Char2Num(stp)); vd = NumType(vd) || vd==0 ? 1 : vd
	Variable i,N=floor(abs(v1-v2)/vd+1); String s=""
	for(i=0;i<N;i+=1)
		s+=Num2Char(v1+i*vd*sign(v2-v1))+","
	endfor
	s=RemoveEnding(s,",")
	return CommandPanel#cast({SelectString(N<2,w[0]+"{"+s+"}",w[0]+s)+CommandPanel#head(ExpandCharacterSeries(w[2]))})
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
static Function/WAVE CompleteParen(input)
	String input
	String ref = CommandPanel#gsub(CommandPanel#gsub(input,"(\\\\\")","",proc=MaskAll),"(\"[^\"]*\")","",proc=MaskAll)
	WAVE/T w=SplitAs(input,CommandPanel#partition(ref,"\\s(//.*)?$")) // command, comment, ""
	WAVE/T f=CommandPanel#partition(w[0],"^\\s*[a-zA-Z]\\w*(#[a-zA-Z]\\w*)?\\s*") // "", function, args
	String info=FunctionInfo(trim(f[1]))
	if(strlen(info)==0 || GrepString(f[2],"^\\("))
		return CommandPanel#cast({input})
	elseif(NumberByKey("N_PARAMS",info)==1 && NumberByKey("PARAM_0_TYPE",info)==8192 && !GrepString(f[2],"^ *\".*\" *$"))
		f[2]="\""+f[2]+"\""
	endif
	return CommandPanel#cast({CommandPanel#sub(f[1]," *$","")+"("+f[2]+")"+w[1]})
End

#endif

//------------------------------------------------------------------------------
// original file: writer.ipf 
//------------------------------------------------------------------------------
#if !ItemsInList(WinList("writer.ipf",";",""))

//------------------------------------------------------------------------------
// This procedure file is packaged by igmodule
// Wed,28 Sep 2016
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

// cast textwave into 1D textwave
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
	if(null(w))
		return cast($"")
	endif
	return cons(f(head(w)),map(f,tail(w)))
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
	if(null(w))
		return cast($"")
	endif
	return extend(f(head(w)),concatMap(f,tail(w)))
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

// Public Functions {{{1
static Function Exec()
	// initialize
	InitAlias()
	CommandPanel_SetBuffer(CommandPanel#cast($""))

	// get command
	String input=CommandPanel_GetLine()
	if(strlen(input)==0)
		ShowHistory()
		return NaN
	endif

	// expand command
	WAVE/T cmds =CommandPanel#Expand(input)
	if(DimSize(commands,0)==0)
		Make/FREE/T cmds = {input}
	endif

	// execute command
	Variable ref,i,N=DimSize(cmds,0)
	String output="",error=""
	for(i=0;i<N;i+=1)
		PrintCommand(cmds[i])
		
		ref = CaptureHistoryStart()
		Execute/Z cmds[i]
		error = GetErrMessage(V_Flag)
		print error
		output += CaptureHistory(ref,ref)
		
		if(strlen(error)) // when an error occurs, stop execution 
			break
		endif
	endfor
	
	// history
	if(!strlen(error))
		AddHistory(input)
		CommandPanel_SetLine("")
	endif
	
	// output
	wAVE/T buf=CommandPanel_GetBuffer()
	WAVE/T out=CommandPanel#split(output,"\r")
	if(DimSize(buf,0)>0)
		return NaN
	elseif(DimSize(out,0)==1 && strlen(out[0])==0)
		ShowHistory()
	else
		CommandPanel_SetBuffer(out)
	endif
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

