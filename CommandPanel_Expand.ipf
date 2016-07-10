#ifndef INCLUDED_COMMAND_PANEL_EXP
#define INCLUDED_COMMAND_PANEL_EXP
#pragma ModuleName=CommandPanelExp
#include "CommandPanel_Interface"

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
	WAVE/T w1 = StrongLineSplit(input)           // 1. Line Split (strong)
	WAVE/T w2 = ExpandString(ExpandAlias    ,w1) // 2. Alias Expansion
	WAVE/T w3 = ExpandWave  (ExpandBrace    ,w2) // 3. Brace Expansion
	WAVE/T w4 = ExpandWave  (ExpandPath     ,w3) // 4. Path Expansion
	WAVE/T w5 = ExpandWave  (WeakLineSplit  ,w4) // 5. Line Split (weak)
	WAVE/T w6 = ExpandString(CompleteParen  ,w5) // 6. Complete Parenthesis
	WAVE/T w7 = ExpandString(RemoveEscapeSeq,w6) // 7. Remove Escape Sequence
	Extract/T/FREE w7,w8,strlen(w7) // 8. Remove Blank Lines
	return w8
End
static Function/WAVE ExpandString(str2str,w)
	FUNCREF CommandPanel_ExpandProtoType1 str2str; WAVE/T w
	Duplicate/FREE/T w,f; f=str2str(w); return f
End
static Function/WAVE ExpandWave(str2wave,w)
	FUNCREF CommandPanel_ExpandProtoType2 str2wave; WAVE/T w
	Variable i,N=DimSize(w,0); Make/FREE/T/N=0 f
	for(i=0;i<N;i+=1)
		Concatenate/T/NP {str2wave(w[i])},f
	endfor
	return f
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
static Function/S RemoveEscapeSeq(input)
	String input
	String ref = input
	ref = ReplaceString("\\\\",input,M+M)
	ref = ReplaceString("\\`" ,input,M+M)
	input = ReplaceByRef("\\{",input,"{",ref)
	input = ReplaceByRef("\\}",input,"}",ref)
	input = ReplaceByRef("\\,",input,",",ref)
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
	Variable pos = 0
	Make/FREE/T/N=0 f
	do
		pos=strsearch(Mask(input),delim,0)
		if(pos>=0)
			InsertPoints DimSize(f,0),1,f; f[inf]=input[0,pos-1]
			input = input[pos+strlen(delim),inf]
		else
			InsertPoints DimSize(f,0),1,f; f[inf]=input		
			break
		endif
	while(1)
	return f
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
static Function/S ExpandAlias(input)
	String input
	String ref = mask(input)
	WAVE/T alias=CommandPanel#GetTextWave("alias")
	Variable i,N=ItemsInList(ref,";"); String out=""
	for(i=0;i<N;i+=1)
		Variable pos=FindListItem(StringFromList(i,ref,";"),ref,";")
		Variable len=strlen(StringFromList(i,ref,";"))
		String line=input[pos,pos+len-1],space,head,tail
		SplitString/E="( *)([A-Za-z][A-Za-z0-9_]*)(.*)" line,space,head,tail
		Extract/FREE/T alias,f,strlen(StringByKey(head,alias))
		if(DimSize(f,0))
			head=ExpandAlias(StringByKey(head,f[0]))
			out += space+head+tail + ";"
		else
			out += line+";"
		endif
	endfor
	return RemoveEnding(out,";")
End


// 3. Brace Expansion
static Function/WAVE ExpandBrace(input)
	String input
	input = ExpandNumberSeries(input)
	input = ExpandCharacterSeries(input)
	return ExpandSeries(input)
End

static Function/WAVE ExpandSeries(input)
	String input
	String head,body,tail,s
	SplitString/E="^(.*?)({([^{}]|(?2))*,(?3)*})(.*)$" mask(input),head,body,s,s,s,s,s,tail
	head=input[0,strlen(head)-1]
	body=input[strlen(head),strlen(head)+strlen(body)-1]
	tail=input[strlen(head)+strlen(body),inf]
//	print "=============================="
//	print "INPUT:"+input
//	print "HEAD :"+head
//	print "BODY :"+body
//	print "TAIL :"+tail
//	print "=============================="
	if(strlen(body))
		body = body[1,strlen(body)-2]
		String ref=mask(body)
		Make/FREE/T/N=0 f
		do
			String fst,rst
			SplitString/E="^(([^{},]|({([^{}]*|(?3))}))*)" ref,fst
			rst = body[strlen(fst)+1,inf]
			Variable len=strlen(fst)
			if(len)
				InsertPoints DimSize(f,0),1,f
				f[inf] = body[0,len-1]
				body=body[len+strlen(","),inf]
				ref =ref [len+strlen(","),inf]
			else
				break
			endif
		while(1)
		f = head+f+tail
		Variable j,Nj=DimSize(f,0)
		Make/FREE/T/N=0 buf
		for(j=0;j<Nj;j+=1)
			Concatenate/T/NP {ExpandSeries(f[j])},buf
		endfor
		return buf
	else
		Make/FREE/T f={input}
		return f
	endif
End
static strconstant NUM="([+-]?[0-9]+)"
static strconstant CHR="([a-zA-Z])"
static Function/S ExpandNumberSeries(input)
	String input
	String head,fst,lst,step,tail
	SplitString/E="^(.*?){"+NUM+"\.\."+NUM+"(\.\."+NUM+")?}(.*)$" input,head,fst,lst,step,step,tail
	if(strlen(fst))
		Variable v1=Str2Num(fst), v2=Str2Num(lst), delta = strlen(step) ? abs(Str2Num(step)) : 1
		delta = delta<1 ? 1  : delta
		Variable i,N=floor(abs(v1-v2)/delta+1); String buf=""
		for(i=0;i<N;i+=1)
			buf+=Num2Str(v1+i*delta*sign(v2-v1))+","
		endfor
		buf=RemoveEnding(buf,",")
		input = SelectString(N<2,head+"{"+buf+"}",head+buf)+ExpandNumberSeries(tail)
	endif
	return input
End
static Function/S ExpandCharacterSeries(input)
	String input
	String head,fst,lst,step,tail
	SplitString/E="^(.*?){"+CHR+"\.\."+CHR+"(\.\."+NUM+")?}(.*)$" input,head,fst,lst,step,step,tail
	if(strlen(fst))
		Variable v1=Char2Num(fst), v2=Char2Num(lst), delta = strlen(step) ? abs(Str2Num(step)) : 1
		delta = delta<1 ? 1  : delta
		Variable i,N=floor(abs(v1-v2)/delta+1); String buf=""
		for(i=0;i<N;i+=1)
			buf+=Num2Char(v1+i*delta*sign(v2-v1))+","
		endfor
		buf=RemoveEnding(buf,",")
		input = SelectString(N<2,head+"{"+buf+"}",head+buf)+ExpandCharacterSeries(tail)
	endif
	return input
End


// 4. Path Expansion
Function/WAVE ExpandPath(input)
	String input
	String ref = mask(input)
	String head,body,tail
	SplitString/E="^(.*?)((root)?(:([a-zA-Z\*][a-zA-Z_0-9\*]*|'[^\"':;]'))+:?)(.*)$" ref,head,body,tail
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
				if(cmpstr(expr,"**")==0) // Globstar
					WAVE/T f=GlobFolders(fixed); f = RemoveEnding((f)[strlen(fixed),inf],":")
				else
					Make/FREE/T/N=(CountObjects(fixed,4)) f=PossiblyQuoteName(GetIndexedObjName(fixed,4,p))
				endif
			else
				Make/T/FREE/N=(CountObjects(fixed,1)) waves    = PossiblyQuoteName(GetIndexedObjName(fixed,1,p))		
				Make/T/FREE/N=(CountObjects(fixed,2)) variables= PossiblyQuoteName(GetIndexedObjName(fixed,2,p))		
				Make/T/FREE/N=(CountObjects(fixed,3)) strings  = PossiblyQuoteName(GetIndexedObjName(fixed,3,p))		
				if(cmpstr(expr,"**")==0) // Globstar
					WAVE/T folders=GlobFolders(fixed); folders = RemoveEnding((folders)[strlen(fixed),inf],":")
				else
					Make/T/FREE/N=(CountObjects(fixed,4)) folders  = PossiblyQuoteName(GetIndexedObjName(fixed,4,p))
				endif
				Make/FREE/T/N=0 f; Concatenate/T/NP {folders,waves,variables,strings},f
			endif
			Extract/T/FREE f,f,StringMatch(f,expr)
			Variable i,N=DimSize(f,0)
			if(N)
				Make/FREE/T/N=0 buf
				for(i=0;i<N;i+=1)
					Concatenate/T/NP {ExpandPath(head+fixed+f[i]+unfixed+tail)},buf
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
		Concatenate/T/NP {base, GlobFolders(base)},f
	endfor
	return f
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
