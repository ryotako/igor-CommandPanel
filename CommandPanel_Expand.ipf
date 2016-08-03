#ifndef INCLUDED_COMMAND_PANEL_EXP
#define INCLUDED_COMMAND_PANEL_EXP
#pragma ModuleName=CommandPanelExp
#include ":CommandPanel_Interface"

// Public Functions
Function/WAVE CommandPanel_Expand(input)
	String input
	return Expand(input)
End
Function CommandPanel_Alias(input)
	String input
	return Alias(input)
End

// Protoyype Functions
Function/S CommandPanel_ExpandProtoType1(input)
	String input
	return input
End
Function/WAVE CommandPanel_ExpandProtoType2(input)
	String input
	Make/FREE/T f={input}; return f
End

// Functions
static Function/WAVE Expand(input)
	String input
	InitAlias()
	bind(return(input),StrongLineSplit)
//	WAVE/T w1 = StrongLineSplit(input)             // 1. Line Split (strong)
//	WAVE/T w2 = ExpandString(ExpandAlias      ,w1) // 2. Alias Expansion
//	WAVE/T w3 = ExpandWave  (ExpandBrace      ,w2) // 3. Brace Expansion (& Remove ¥ from ¥{ ¥, ¥})
//	WAVE/T w4 = ExpandWave  (ExpandPath       ,w3) // 4. Path Expansion
//	WAVE/T w5 = ExpandWave  (WeakLineSplit    ,w4) // 5. Line Split (weak)
//	WAVE/T w6 = ExpandString(CompleteParen    ,w5) // 6. Complete Parenthesis
//	WAVE/T w7 = ExpandString(RemoveEscapeWhole,w6) // 7. Remove Escape Char ¥
//	Extract/T/FREE w7,w8,strlen(w7) // 8. Remove Blank Lines
//	return w8
End


static Function length(w)
	WAVE/T w
	return WaveExists(w) ? DimSize(w,0) : 0
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
static Function/WAVE cons(s,w)
	String s; WAVE/T w
	if(null(w))
		return return(s)
	endif
	Duplicate/FREE/T w,ww; InsertPoints 0,1,ww; ww[0]=s; return ww
End

static Function/WAVE void()
	Make/FREE/T/N=0 w; return w
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
static Function/WAVE split(s,expr)
	String s,expr
	String buf; SplitString/E=expr s,buf
	Variable pos = strsearch(s,buf,0), len=strlen(buf)
	if(strlen(buf)==0)
		return void()
	endif
	return cons(s[0,pos-1],cons(buf,cons(s[pos+len,inf],void())))
End
static Function/WAVE SplitAs(s,w)
	String s; WAVE/T w
	if(null(w))
		return void()
	endif
	Variable len=strlen(head(w))
	return cons(s[0,len-1],SplitAs(s[len,inf],tail(w)))
End

static Function/WAVE bind(w,f)
	WAVE/T w; FUNCREF CommandPanel_Expand f
	if(null(w))
		return void()
	endif
	return concat(f(head(w)),bind(tail(w),f))
End
static Function/WAVE return(s)
	String s
	Make/FREE/T w={s}; return w
End


// 0,7 Escape Sequence {{{1
static strconstant M ="|" // one character for masking
static Function/S Mask(input)
	String input
	input = ReplaceString("\\\\",input,M+M) // \ itself
	input = MaskBetween("`" ,ReplaceString("\\`"  ,input,M+M)) // ``
	input = MaskBetween("\"",ReplaceString("\\\"" ,input,M+M)) // ""
	input = MaskAfter("//",input) // //
	input = ReplaceString("\\{" ,input,M+M) // {
	input = ReplaceString("\\}" ,input,M+M) // }
	input = ReplaceString("\\," ,input,M+M) // ,
	return input
End
static Function/S MaskBetween(str,input)
	String str,input
	Variable pos1=0,pos2=0
	do
		pos1=strsearch(input,str,pos2)
		pos2=strsearch(input,str,pos1+1)
		if(pos2>0)
			Variable i, N=pos2+strlen(str)-pos1; String mask=""
			for(i=0;i<N;i+=1)
				mask += M[0]
			endfor
			input=input[0,pos1-1]+mask+input[pos2+1,inf]
			pos2=pos2+1
		endif
	while(pos2>0)
	return input
End
static Function/S MaskAfter(str,input)
	String str,input
	Variable pos=strsearch(input,"//",0)
	if(pos>=0)
		Variable i,N=strlen(input)-pos; String mask=""
		for(i=0;i<N;i+=1)
			mask += M[0]
		endfor
		return input[0,pos-1]+mask
	else
		return input	
	endif
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
static Function Alias(expr)
	String expr
	Duplicate/T/FREE CommandPanel#GetTextWave("alias") alias
	String lhs="",rhs=""
	if(GrepString(expr,"^ *$"))
		Variable i,N=DimSize(alias,0); Duplicate/FREE/T alias f
		for(i=0;i<N;i+=1)
			SplitString/E="^([a-zA-Z][a-zA-Z_0-9]*): *(.*)$" alias[i],lhs,rhs
			f[i] = "alias "+lhs+"="+rhs
		endfor
		CommandPanel_SetBuffer(f)
	else
		SplitString/E="([a-zA-Z][a-zA-Z0-9_]*) *= *([^ ].*)?" expr,lhs,rhs
		Extract/T/FREE alias,f,!StringMatch(alias,lhs+":*")
		if(strlen(rhs))
			InsertPoints 0,1,f; f[0]=lhs+":"+rhs
		endif
		Sort f,f
		CommandPanel#SetTextWave("alias",f)
	endif
End
static Function InitAlias()
	WAVE/T w=CommandPanel#GetTextWave("alias")
	if(DimSize(w,0)<1)
		Alias("alias=CommandPanelExp#Alias")
	endif
End
static Function/WAVE ExpandAlias(input)
	String input
	String ref = mask(input)
	

//	WAVE/T alias=CommandPanel#GetTextWave("alias")
//	Variable i,N=ItemsInList(ref,";"); String out=""
//	for(i=0;i<N;i+=1)
//		Variable pos=FindListItem(StringFromList(i,ref,";"),ref,";")
//		Variable len=strlen(StringFromList(i,ref,";"))
//		String line=input[pos,pos+len-1],space,head,tail
//		SplitString/E="( *)([A-Za-z][A-Za-z0-9_]*)(.*)" line,space,head,tail
//		Extract/FREE/T alias,f,strlen(StringByKey(head,alias))
//		if(null(f))
//			out += line+";"
//		else
//			head=ExpandAlias(StringByKey(head,f[0]))
//			out += space+head+tail + ";"
//		else
//		endif
//	endfor
//	return RemoveEnding(out,";")
End

// 3. Brace Expansion
static Function/WAVE ExpandBrace(input)
	String input
	return bind(bind(bind(bind(return(input),ExpandNumberSeries),ExpandCharacterSeries),ExpandSeries),RemoveEscapeSeqBrace)
End

static Function/WAVE ExpandSeries(input)
	String input
	WAVE/T w=SplitAs(input,split(mask(input),"({([^{}]|(?1))*,(?2)*})"))
	if(null(w))
		return return(input)
	endif
	WAVE/T ww=ExpandSeries_((w[1])[1,strlen(w[1])-2]); ww=w[0]+ww+w[2]
	return bind(ww,ExpandSeries)
End
static FUnction/WAVE ExpandSeries_(body) // expand inside of {} once
	String body
	WAVE/T w=SplitAs(body,split(mask(body),"^(([^{},]|({([^{}]*|(?3))}))*)"))
	if(null(w))
		return void()
	elseif(StringMatch(w[2],","))
		return cons(body[0,strlen(w[1])-1],return(""))
	endif
	return cons(body[0,strlen(w[1])-1] , ExpandSeries_(body[strlen(w[1]+","),inf]))
End
static Function/WAVE ExpandNumberSeries(input)
	String input
	WAVE/T w=split(input,"({([+-]?\\d+)\.\.(?2)(\.\.(?2))?})")
	if(null(w))
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
	WAVE/T w=split(input,"({([a-zA-Z])\.\.(?2)(\.\.([+-]?\\d+))?})")
	if(null(w))
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
static Function/S CompleteParen(input)
	String input
	String space,head,tail,s,comment
	SplitString/E="^( *)(([a-zA-Z][a-zA-Z_0-9]*)(#(?3))?)(.*?)( *(//.*)*)$" input,space,head,s,s,tail,comment
	String info=FunctionInfo(head)
	if(strlen(info) && !GrepString(tail,"^ *\(.*\) *$"))
		SplitString/E="^ *(.*?) *$" tail,tail
		if(NumberByKey("N_PARAMS",info)==1 && NumberByKey("PARAM_0_TYPE",info)==8192 && !GrepString(tail,"^ *\".*\" *$"))
			tail="(\""+tail+"\")"
		else
			tail="("+tail+")"	
		endif
	endif
	String output = space+head+tail+comment
	return SelectString(strlen(output),input,output)
End
