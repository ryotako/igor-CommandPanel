#ifndef INCLUDED_COMMAND_PANEL_TEST_EXP
#define INCLUDED_COMMAND_PANEL_TEST_EXP
#pragma ModuleName=CommandPanelTestExp

Menu "Test"
	"CommandPanel_Expand",/Q,CommandPanelTestExp#test()
End

static Function test()
	String f
	print "test: start"

	KillWaves/Z root:Packages:CommandPanel:alias
	f="CommandPanelExp#Alias"
	testl($f,"","")
	testl($f,"a=alias","")
	testl($f,"t0=test0" ,"")
	testl($f,"t1=test1" ,"")


	f="CommandPanelExp#Expand"
	testl($f,"1;2;3"  ,"1;2;3")
	testl($f,"1;;2;;3","1;2;3")
	testw($f,"1;;\"2;;3\"",{"1","\"2;;3\""})

	tests($f,"`1;2;3`"  ,"1;2;3")


	testl($f,"a","alias")	
	testl($f,"a ; a","alias ; alias")
	testl($f,"a ; t0","alias ; test0()")
	testl($f,"t0 ; t0","test0() ; test0()")
	tests($f,"t0 //; t0","test0() //; t0")
	testl($f,"t1 ; t0","test1(\"\") ; test0()")
	testl($f,"t1 test ; t0","test1(\"test\") ; test0()")
	testl($f,"t0 a,b,c//d","test0(a,b,c)//d")


	testl($f,"{1..3}","1;2;3")
	testl($f,"{-1..3}","-1;0;1;2;3")
	testl($f,"{1..9..2}" ,"1;3;5;7;9")
	testl($f,"{1..9..+2}","1;3;5;7;9")
	testl($f,"{1..9..-2}","1;3;5;7;9")
	testl($f,"{1..3..0}","1;2;3")
	testl($f,"{3..1}","3;2;1")
	testl($f,"{3..-1}","3;2;1;0;-1")
	testl($f,"{a..c}","a;b;c")
	testl($f,"{a,b,{c}}","a;b;{c}")
	testl($f,"{aa,bb,cc}","aa;bb;cc")
	testl($f,"{a,b,c}","a;b;c")
	testl($f,"{a}","{a}")
	testl($f,"{}","{}")
	testl($f,"{a,b,{c,d}}","a;b;c;d")

	print "end"
End

override Function test0()
End 
override Function test1(s)
	String s
End 



static Function tests(f,s_src,s_ans)
	FUNCREF CommandPanelExpTest_ProtoType f
	String s_src,s_ans
	return testw(f,s_src,{s_ans})
End
static Function testl(f,s_src,s_ans)
	FUNCREF CommandPanelExpTest_ProtoType f
	String s_src,s_ans
	Make/FREE/T/N=(ItemsInList(s_ans)) w_ans=StringFromList(p,s_ans)
	return testw(f,s_src,w_ans)
ENd
static Function testw(f,s_src,w_ans)
	FUNCREF CommandPanelExpTest_ProtoType f
	String s_src; WAVE/T w_ans
	WAVE/T expanded = f(s_src)
	if(DimSize(w_ans,0) == DimSize(expanded,0))
		Make/FREE/N=(DimSize(w_ans,0)) w=abs(cmpstr(w_ans,expanded))
		if(WaveMax(w)==0 || DimSize(w_ans,0)==0)
			return NaN
		endif
	endif
	String s
	print "=============================="
	print StringByKey("NAME",FuncrefInfo(f))
	print "INPUT"
	print s_src
	print "EXPANDED"
	print expanded
	print "EXPECTED"
	print w_ans
	print "=============================="
End
Function/WAVE CommandPanelExpTest_ProtoType(s)
	String s
	Make/FREE/T/N=0 f; return f
End
