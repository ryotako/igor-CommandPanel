#include "CommandPanel_Interface"
#pragma ModuleName=CommandPanelComplete

Function CommandPanel_Complete()
	String input=CommandPanel_GetLine()
	WAVE/T buf=CommandPanel_GetBuffer()
	String selrow=buf[CommandPanel_SelectedRow()]
	if(strlen(input)==0) // empty string
		ReadSelectedRow()	
	elseif(cmpstr(input,selrow,1)==0) // same as the selected buffer row 
		ScrollDownBuffer()
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

// for an empty string
static Function ReadSelectedRow()
	WAVE/T buf=CommandPanel_GetBuffer()
	Variable num=CommandPanel_SelectedRow()
	CommandPanel_SelectRow(num)
	CommandPanel_SetLine(buf[num])
End

// for the same string as the selected buffer row
static Function ScrollDownBuffer()
	WAVE/T buf=CommandPanel_GetBuffer()
	Variable num=mod(CommandPanel_SelectedRow()+1,DimSize(buf,0))
	CommandPanel_SelectRow(num)
	CommandPanel_SetLine(buf[num])		
End

// for a string beginning with whitespace 
static Function FilterBuffer()
	Duplicate/FREE/T CommandPanel_GetBuffer() buf
	String patterns=RemoveFromList("",CommandPanel_GetLine()," ")
	Variable i,N=ItemsInList(patterns," ")
	for(i=0;i<N;i+=1)
		String pattern=StringFromList(i,patterns," ")
		Extract/FREE/T buf,buf,GrepString(buf,pattern)
	endfor
	CommandPanel_SetBuffer(buf)
	CommandPanel_SetLine("")
End

// for a string ending with ;
static Function JointSelectedRow()
	String line=CommandPanel_GetLine()
	WAVE/T buf=CommandPanel_GetBuffer()
	Variable num=CommandPanel_SelectedRow()
	CommandPanel_SetLine(line+buf[num+1])
	CommandPanel_SelectRow(num+1)
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
Function CompleteOperationName()
	String line=CommandPanel_GetLine(),preopr,opr
	SplitString/E="(.*;)? *([A-Za-z]\\w*)$" line,preopr,opr
	String list=FunctionList(opr+"*",";","KIND:2")+OperationList(opr+"*",";","all")
	Make/FREE/T/N=(ItemsInList(list)) oprs=StringFromList(p,list)
	Extract/T/FREE oprs,oprs,StringMatch(oprs,opr+"*")
	Make/T/FREE/N=(DimSize(oprs,0)) buf=preopr+oprs
	if(DimSize(buf,0))
		CommandPanel_SetBuffer(buf)
		CommandPanel_SetLine(buf[0])	
	endif
End

// for the second or any later word
Function CompleteFunctionName()
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
