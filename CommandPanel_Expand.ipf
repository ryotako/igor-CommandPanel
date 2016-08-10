#include ":igor-writer:writer.wave"
#include ":igor-writer:writer.string"
#include "CommandPanel_Interface"
#pragma ModuleName=CommandPanelExpand


// Public Functions
Function/WAVE CommandPanel_Expand(input)
	String input
	return Expand(input)
End
Function/WAVE CommandPanel_Alias(input)
	String input
	WAVE/T w=Alias(input)
	print w
	CommandPanel_SetBuffer(w)
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
