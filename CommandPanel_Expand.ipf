#ifndef INCLUDED_COMMAND_PANEL_EXP
#define INCLUDED_COMMAND_PANEL_EXP
#pragma ModuleName=CommandPanel
#include ":igor-writer:writer"

// Public Functions
Function/WAVE CommandPanel_Expand(input)
	String input
	return Expand(input)
End
Function CommandPanel_Alias(input)
	String input
	Alias(input)
End

// Functions
static Function/WAVE Expand(input)
	String input
	return bind(bind(bind(bind(bind(return(input),StrongLineSplit),ExpandAlias),ExpandBrace),WeakLineSplit),CompleteParen)
//	WAVE/T w1 = StrongLinepartition(input)             // 1. Line Split (strong)
//	WAVE/T w2 = ExpandString(ExpandAlias      ,w1) // 2. Alias Expansion
//	WAVE/T w3 = ExpandWave  (ExpandBrace      ,w2) // 3. Brace Expansion (& Remove \ from \{ \, \})
//	WAVE/T w4 = ExpandWave  (ExpandPath       ,w3) // 4. Path Expansion
//	WAVE/T w5 = ExpandWave  (WeakLineSplit    ,w4) // 5. Line Split (weak)
//	WAVE/T w6 = ExpandString(CompleteParen    ,w5) // 6. Complete Parenthesis
//	WAVE/T w7 = ExpandString(RemoveEscapeWhole,w6) // 7. Remove Escape Char \\
//	Extract/T/FREE w7,w8,strlen(w7) // 8. Remove Blank Lines
//	return w8
End



Function/WAVE SplitAs(s,w)
	String s; WAVE/T w
	if(null(w))
		return void()
	endif
	Variable len=strlen(head(w))
	return cons(s[0,len-1],SplitAs(s[len,inf],tail(w)))
End
Function/S join(w)
	WAVE/T w
	if(null(w))
		return ""
	endif
	return head(w)+join(tail(w))
End

// 0,7 Escape Sequence {{{1
static strconstant M ="|" // one character for masking
Function/S Mask(input)
	String input
	input = MaskExpr(input,"(//.*)$") // //
	input = MaskExpr(input,"(\\\\\\\\)") // \
	input = MaskExpr(MaskExpr(input,"(\\\\`)" ),"(`[^`]*`)"   ) // `
	input = MaskExpr(MaskExpr(input,"(\\\\\")"),"(\"[^\"]*\")") // "
	input = MaskExpr(input,trim("(\\\\{ | \\\\} | \\\\,)")) // {},
	return input
End
Function/S MaskExpr(s,expr)
	String s,expr
	WAVE/T w=partition(s,expr)
	if(strlen(w[1])==0)
		return s
	endif
	return w[0]+RepeatChar(M,strlen(w[1])) + MaskExpr(w[2],expr)
End
Function/S RepeatChar(c,n)
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
static Function/S RemoveEscapeWhole(input)
	String input
	String ref = input
	ref = ReplaceString("\\\\",input,M+M)
	ref = ReplaceString("\\`" ,input,M+M)
	input = ReplaceByRef("`",input,"",ref)	
	input = ReplaceString("\\`",input,"`")
	return input
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
	WAVE/T w=SplitAs(input,partition(mask(input),"(;)"))// line, ;, lines
	if(strlen(w[1]))
		return ExpandAlias_(input)
	endif
	return return( join(concat(ExpandAlias_(w[0]+w[1]),ExpandAlias(w[2]))) )
End
static Function/WAVE ExpandAlias_(input) // one line
	String input
	WAVE/T w=partition(input,"^\\s*([a-zA-Z]\\w*)") //space,alias,args
	if(strlen(w[1]))
		return return(input)
	endif
	Duplicate/FREE/T GetAliasWave(),alias
	Extract/FREE/T alias,alias,StringMatch(alias,w[1]+"=*")
	return return(w[0]+SelectString(null(alias),(head(alias))[strlen(w[1])+1,inf],w[1])+w[2])
End

Function/WAVE GetAliasWave()
	WAVE/T w=root:Packages:CommandPanel:alias
	if(WaveExists(w))
		return w
	endif
	return void()
End
Function/WAVE SetAliasWave(w)
	WAVE/T w
	if(WaveExists(w) && !WaveRefsEqual(w,GetAliasWave()))
		NewDataFolder/O root:Packages
		NewDataFolder/O root:Packages:CommandPanel
		Duplicate/O/T w root:Packages:CommandPanel:alias
	endif
End

static Function/WAVE Alias(expr)
	String expr
	Duplicate/T/FREE GetAliasWave() alias
	if(strlen(trim(expr))==0)
		return alias
	endif
	WAVE/T w=SplitAs(mask(expr),partition(expr,trim("^(\\s*\\w+\\s*=\\s*)") )) //blank,alias=,string
	if(strlen(w[1]))
		Extract/FREE/T alias,alias,!StringMatch(alias,trim(w[1])+"*")
		InsertPoints 0,1,alias; alias[0] = trim(w[0])+trim(w[2])
		SetAliasWave(alias)
	endif
	return void()
End


// 3. Brace Expansion
static Function/WAVE ExpandBrace(input)
	String input
	return bind(bind(bind(bind(return(input),ExpandNumberSeries),ExpandCharacterSeries),ExpandSeries),RemoveEscapeSeqBrace)
End

static Function/WAVE ExpandSeries(input)
	String input
	WAVE/T w=SplitAs(input,partition(mask(input),trim("( { ([^{}] | \{\} | {[^{}]} | (?1))* , (?2)* } )")))
	if(strlen(w[1]))
		return return(input)
	endif
	WAVE/T ww=ExpandSeries_((w[1])[1,strlen(w[1])-2]); ww=w[0]+ww+w[2]
	return bind(ww,ExpandSeries)
End
static FUnction/WAVE ExpandSeries_(body) // expand inside of {} once
	String body
	WAVE/T w=SplitAs(body,partition(mask(body),trim("^( ( [^{},] | ( { ([^{}]*|(?3)) } ) )+ )")))
	if(strlen(w[1]))
		return void()
	elseif(StringMatch(w[2],","))
		return cons(body[0,strlen(w[1])-1],return(""))
	endif
	return cons(body[0,strlen(w[1])-1] , ExpandSeries_(body[strlen(w[1]+","),inf]))
End
static Function/WAVE ExpandNumberSeries(input)
	String input
	WAVE/T w=partition(input,trim("( { ([+-]?\\d+) \.\. (?2) (\.\. (?2))? } )"))
	if(strlen(w[1]))
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
	if(strlen(w[1]))
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
Function/WAVE ExpandPath(input)
	String input
	WAVE/T w=SplitAs(input,partition(mask(input),trim("( ((?<!\\w)root)? (:[a-zA-Z\*][\\w\*]* | :'[^:;'\"]+')+:? )")))
	print w
	return void()


	String ref = mask(input)
	String head,body,tail,s
	
	SplitString/E="^(.*?)(((?<!\\w)root)?(:[a-zA-Z\*][\\w\*]*|:'[^:;'\"]+')+:?)(.*?)$" input,head,body,s,s,tail
	String ref_body=body
	head=input[0,strlen(head)-1]
	body=input[strlen(head),strlen(head)+strlen(body)-1]
	tail=input[strlen(head)+strlen(body),inf]
	if(strlen(body))
		body=SelectString(StringMatch(body,":"),body[0],GetDataFolder(1))+body[1,inf]
		String fixed,expr,unfixed
		SplitString/E="^(.*?:)([^:]*\*[^:]*)(.*)$" ref_body,fixed,expr,unfixed
		if(strlen(expr))
			if(strlen(unfixed))
				if(cmpstr(expr,"**")==0) // Globstar (folder)
					WAVE/T f=GlobFolders(fixed)
					f = RemoveEnding((f)[strlen(fixed),inf],":")
					if(cmpstr(unfixed,":"))
						InsertPoints DimSize(f,0),1,f
					endif
				else
					Make/FREE/T/N=(CountObj(fixed,4)) f=PossiblyQuoteName(GetIndexedObjName(fixed,4,p))
				endif
				String next
				SplitString/E="(:[^*]+)$" unfixed,next
				if(strlen(next))
					Extract/T/FREE f,f,ObjExists(fixed+f+next)
				endif
			else
				Make/T/FREE/N=(CountObj(fixed,1)) waves    = PossiblyQuoteName(GetIndexedObjName(fixed,1,p))		
				Make/T/FREE/N=(CountObj(fixed,2)) variables= PossiblyQuoteName(GetIndexedObjName(fixed,2,p))		
				Make/T/FREE/N=(CountObj(fixed,3)) strings  = PossiblyQuoteName(GetIndexedObjName(fixed,3,p))		
				if(cmpstr(expr,"**")==0) // Globstar (general)
					WAVE/T folders=GlobFolders(fixed); folders = RemoveEnding((folders)[strlen(fixed),inf],":")
				else
					Make/T/FREE/N=(CountObj(fixed,4)) folders  = PossiblyQuoteName(GetIndexedObjName(fixed,4,p))
				endif
				Make/FREE/T/N=0 f; Concatenate/T/NP {folders,waves,variables,strings},f
			endif
			Extract/T/FREE f,f,StringMatch(f,expr)||StringMatch(f,"'"+expr+"'")
			Variable i,N=DimSize(f,0)
			if(N)
				Make/FREE/T/N=0 buf
				for(i=0;i<N;i+=1)
					String arg = head+SelectString(strlen(f[i]),RemoveEnding(fixed,":"),fixed)+f[i]+unfixed+tail
					Concatenate/T/NP {ExpandPath(arg)},buf
				endfor
				return buf
			else
				Make/FREE/T f={""}
				return f
			endif
		else
			WAVE/T f=ExpandPath(tail)
			f=head+body+f
			return f
		endif
	else
		Make/FREE/T f={input}
		return f
	endif
End
Function/WAVE GlobFolders(path)
	String path
	Make/FREE/T/N=(CountObjects(path,4)) sub=path+PossiblyQuoteName(GetIndexedObjName(path,4,p))+":"
	Variable i,N=DimSize(sub,0); Make/FREE/T/N=0 f
	for(i=0;i<N;i+=1)
		Make/FREE/T base={sub[i]}
		Concatenate/T/NP {base, GlobFolders(base[0])},f
	endfor
	return f
End
Function CountObj(path,type)
	String path; Variable type
	Variable v=CountObjects(path,type)
	return numtype(v) ? 0 : v
End
Function ObjExists(path)
	String path
	WAVE w=$path; NVAR n=$path; SVAR s=$path
	return DataFolderExists(path) || WaveExists(w) || NVAR_Exists(n) || SVAR_Exists(s)
End


// 6. Complete Parenthesis
static Function/WAVE CompleteParen(input)
	String input
	WAVE/T w=partition(input,trim("^\\s* ( ([a-zA-Z]\\w*) (#(?3))? ) (.*?) (\\s* (//.*)*)")) // space, function, args
	if(strlen(w[1]) || strlen(FunctionInfo(w[1]))==0 || GrepString(w[2],"^ *\(.*\) *(//.*)?$"))
		return return(input)
	endif
	String info=FunctionInfo(w[1])
	WAVE/T arg=partition(w[2],"^\\s*(.*?)(\\s*(//.*)?)$")// space, args, comment
	if(NumberByKey("N_PARAMS",info)==1 && NumberByKey("PARAM_0_TYPE",info)==8192 && !GrepString(arg,"^ *\".*\" *$"))
		arg[1]="\""+arg[1]+"\""
	endif
	return return( w[0]+w[1]+"("+arg[1]+")"+arg[2] )
End
