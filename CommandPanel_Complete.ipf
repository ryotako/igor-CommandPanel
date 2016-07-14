#ifndef INCLUDED_COMMAND_PANEL_CMP
#define INCLUDED_COMMAND_PANEL_CMP
#pragma ModuleName=CommandPanelCmp
#include "CommandPanel_Interface"


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
		SplitString/E="(.*?)([A-Za-z][A-Za-z0-9_]*)$" input,head,tail
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
		Make/T/FREE/N=(CountObjects(head,1)) waves    = PossiblyQuoteName(GetIndexedObjName(head,1,p))		
		Make/T/FREE/N=(CountObjects(head,2)) variables= PossiblyQuoteName(GetIndexedObjName(head,2,p))		
		Make/T/FREE/N=(CountObjects(head,3)) strings  = PossiblyQuoteName(GetIndexedObjName(head,3,p))		
		Make/T/FREE/N=(CountObjects(head,4)) folders  = PossiblyQuoteName(GetIndexedObjName(head,4,p))
		Make/FREE/T/N=0 f; Concatenate/T/NP {waves,variables,strings,folders},f
		Extract/T/FREE f,f,StringMatch(f,tail+"*"); f=head+f	
		return f
	else
		Make/FREE/T/N=0 f; return f
	endif
End

#endif
