#include "writer"
#include ":CommandPanel_Interface"
#pragma ModuleName=CommandPanel_Expand


static Function/WAVE Expand(input)
	String input

	WAVE/T w1=writer#concatMap(StrongLineSplit,{input})
	WAVE/T w2=writer#concatMap(ExpandAlias        ,w1 )
	WAVE/T w3=writer#concatMap(ExpandBrace        ,w2 )
	w3 = UnescapeBraces(w3)
	WAVE/T w4=writer#concatMap(ExpandPath         ,w3 )
	WAVE/T w5=writer#concatMap(WeakLineSplit      ,w4 )
	WAVE/T w6=writer#concatMap(CompleteParen      ,w5 )
	w6 = UnescapeBackquotes(w6)

	return w6
End


// Utils
static Function/WAVE SplitAs(s,w)
	String s; WAVE/T w
	if(writer#null(w))
		return writer#cast($"")
	endif
	Variable len=strlen(writer#head(w))
	return writer#cons(s[0,len-1],SplitAs(s[len,inf],writer#tail(w)))
End
static Function/WAVE PartitionWithMask(s,expr)
	String s,expr
	return SplitAs(s,writer#partition(mask(s),expr))
End
static Function/S trim(s)
	String s
	return ReplaceString(" ",s,"")
End
static Function/S join(w)
	WAVE/T w
	if(writer#null(w))
		return ""
	endif
	return writer#head(w)+join(writer#tail(w))
End
static Function/WAVE product(w1,w2) //{"a","b"},{"1","2"} -> {"a1","a2","b1","b2"}
	WAVE/T w1,w2
	if(writer#null(w1))
		return writer#cast($"")
	endif
	Make/FREE/T/N=(DimSize(w2,0)) f=writer#head(w1)+w2
	return writer#extend(f,product(writer#tail(w1),w2))
End


// 0. Escape Sequence {{{1
// mask
static strconstant M ="|" // one character for masking
static Function/S Mask(input)
	String input
	// mask comment
	input=writer#gsub(input,"//.*$","",proc=MaskAll)
	// mask with ``
	input=writer#gsub(input,"\\\\\\\\|\\\\`|`(\\\\\\\\|\\\\`|[^\\`])*`","",proc=MaskAll)
	// mask with ""
	input=writer#gsub(input,"\\\\\\\\|\\\\\"|\"(\\\\\\\\|\\\\\"|[^\\\"])*\"","",proc=MaskAll)
	// mask with \
	input=writer#gsub(input,"\\\\\\\\|\\\\{|\\\\}|\\\\,","",proc=MaskAll)
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
	input=writer#gsub(input,ignore+"\\\\{","",proc=UnescapeBrace)
	input=writer#gsub(input,ignore+"\\\\}","",proc=UnescapeBrace)
	input=writer#gsub(input,ignore+"\\\\,","",proc=UnescapeBrace)
	return input
End
static Function/S UnescapeBrace(s)
	String s
	return SelectString(GrepString(s,"^\\\\[^\\\\`]$"),s,s[1])
End

static Function/S UnescapeBackquotes(input)
	String input
	return writer#gsub(input,"//.*$|\\\\\\\\|\\\\`|`","",proc=UnescapeBackquote)
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
		return writer#cast({input})
	endif
	Variable pos2 = pos + strlen(delim)
	return writer#cons(input[0,pos-1],LineSplitBy(delim,input[pos2,inf],masked[pos2,inf]))
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
static Function/WAVE ExpandAlias(input)
	String input
	WAVE/T w=PartitionWithMask(input,";")// line, ;, lines
	if(strlen(w[1])==0)
		return ExpandAlias_(input)
	endif
	return writer#cast({join(writer#extend(ExpandAlias_(w[0]+w[1]),ExpandAlias(w[2])))})
End
static Function/WAVE ExpandAlias_(input) // one line
	String input
	WAVE/T w=writer#partition(input,"^\\s*(\\w*)") //space,alias,args
	if(strlen(w[1])==0)
		return writer#cast({input})
	endif
	Duplicate/FREE/T GetAlias(),als
	Extract/FREE/T als,als,StringMatch(als,w[1]+"=*")
	if(writer#null(als))
		return writer#cast({input})
	else
		String cmd=(writer#head(als))[strlen(w[1])+1,inf]
		return writer#cast({w[0]+writer#head(ExpandAlias_(cmd))+w[2]})
	endif
End

static Function SetAlias(input)
	String input
	WAVE/T w=PartitionWithMask(input,"^(\\s*\\w+\\s*=\\s*)") //blank,alias=,string
	if(strlen(w[1]))
		Duplicate/T/FREE GetAlias() alias
		Extract/FREE/T alias,alias,!StringMatch(alias,trim(w[1])+"*")
		InsertPoints 0,1,alias; alias[0] = trim(w[1])+w[2]
		CommandPanel_Interface#SetTextWave("alias",alias)
	endif
End
static Function/WAVE GetAlias()
	return CommandPanel_Interface#GetTextWave("alias")
End
static Function/WAVE GetAliasNames()
	return writer#map(GetAliasName,GetAlias())
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
	WAVE/T w=SplitAs(input,writer#partition(mask(input),trim("( { ([^{}] | {[^{}]*} | (?1))* , (?2)* } )")))
	if(strlen(w[1])==0)
		return writer#cast({input})
	endif
	WAVE/T body = ExpandSeries_((w[1])[1,strlen(w[1])-2])
	body = w[0] + body + w[2]
	return writer#concatMap(ExpandSeries,body)
End

static Function/WAVE ExpandSeries_(body) // expand inside of {} once
	String body
	if(strlen(body)==0)
		return writer#cast({""})
	elseif(StringMatch(body[0],","))
		return writer#cons("",ExpandSeries_(body[1,inf]))
	elseif(!GrepString(body,"{|}|\\\\"))
		Variable size = ItemsInList(body, ",") + StringMatch(body[strlen(body)-1], ",")
		Make/FREE/T/N=(size) w = StringFromList(p, body, ",")
		return w
	endif
	WAVE/T w=PartitionWithMask(body,trim("^( ( [^{},] | ( { ([^{}]*|(?3)) } ) )* )"))
	if(strlen(w[2]))
		return writer#cons(w[1],ExpandSeries_( (w[2])[1,inf] ))
	else
		return writer#cast({w[1]})
	endif
End

static Function/S ExpandNumberSeries(input)
	String input
	WAVE/T w=writer#partition(input,trim("( { ([+-]?\\d+) \.\. (?2) (\.\. (?2))? } )"))
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
	WAVE/T w=writer#partition(input,trim("( { ([a-zA-Z]) \.\. (?2) (\.\. ([+-]?\\d+))? } )"))
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
		return writer#cast({input})
	endif
	return product( writer#cast({w[0]}), product(ExpandPathImpl(w[1]), ExpandPath(w[2])))
End
static Function/WAVE ExpandPathImpl(path) // implement of path expansion
	String path
	WAVE/T token = SplitAs(path,writer#scan(mask(path),":|[^:]+:?"))
	WAVE/T buf   = ExpandPathImpl_(writer#head(token),writer#tail(token))
	if(writer#null(buf))
		return writer#cast({path})		
	endif
	return buf
End
static Function/WAVE ExpandPathImpl_(path,token)
	String path; WAVE/T token
	if(writer#null(token))
		return writer#cast({path})
	elseif(writer#length(token)==1)
		if(cmpstr(writer#head(token),"**:")==0)
			WAVE/T fld = GlobFolders(path)
			fld=path+fld+":"
			return fld
		elseif(GrepString(writer#head(token),":$")) // *: -> {fld1:, fld2:}
			WAVE/T w = Folders(path)
			Extract/T/FREE w,fld,PathMatch(w,RemoveEnding(writer#head(token),":"))
			fld=path+fld+":"
			return fld
		else // * -> {wave, var, str, fld} 
			WAVE/T w = Objects(path)
			Extract/T/FREE w,obj,PathMatch(w,RemoveEnding(writer#head(token),":"))
			obj=path+obj
			return obj		
		endif
	else
		if(cmpstr(writer#head(token),"**:")==0)
			WAVE/T fld = GlobFolders(path)
			InsertPoints 0,1,fld
			fld=path+fld+":"
			fld[0]=RemoveEnding(fld[0],":")
		else
			WAVE/T w = Folders(path)
			Extract/T/FREE w,fld,PathMatch(w,RemoveEnding(writer#head(token),":"))
			fld=path+fld+":"
		endif
		Variable i,N=writer#length(fld); Make/FREE/T/N=0 buf
		for(i=0;i<N;i+=1)
			Concatenate/NP/T {ExpandPathImpl_(fld[i],writer#tail(token))},buf
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
	if(!writer#null(w))
		w=RemoveEnding(RemoveBeginning(w,path),":")
	endif
	return w
End
static Function/WAVE GlobFolders_(path)
	String path
	WAVE/T fld=Folders(path); fld=path+fld+":"
	Variable i,N=writer#length(fld); Make/FREE/T/N=0 buf
	for(i=0;i<N;i+=1)
		Concatenate/T/NP {writer#cast({fld[i]}), GlobFolders_(fld[i])},buf
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
	String ref = writer#gsub(writer#gsub(input,"(\\\\\")","",proc=MaskAll),"(\"[^\"]*\")","",proc=MaskAll)
	WAVE/T w=SplitAs(input,writer#partition(ref,"\\s(//.*)?$")) // command, comment, ""
	WAVE/T f=writer#partition(w[0],"^\\s*[a-zA-Z]\\w*(#[a-zA-Z]\\w*)?\\s*") // "", function, args
	String info=FunctionInfo(trim(f[1]))
	if(strlen(info)==0 || GrepString(f[2],"^\\("))
		return writer#cast({input})
	elseif(NumberByKey("N_PARAMS",info)==1 && NumberByKey("PARAM_0_TYPE",info)==8192 && !GrepString(f[2],"^ *\".*\" *$"))
		f[2]="\""+f[2]+"\""
	endif
	return writer#cast({writer#sub(f[1]," *$","")+"("+f[2]+")"+w[1]})
End
