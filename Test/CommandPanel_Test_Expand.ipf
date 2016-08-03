#ifndef INCLUDED_COMMAND_PANEL_TEST_EXP
#define INCLUDED_COMMAND_PANEL_TEST_EXP
#pragma ModuleName=CommandPanelTestExp

Menu "Test"
	"CommandPanel_Expand",/Q,CommandPanelTestExp#test()
End

static Function test()
	String f
	f="CommandPanelExp#StrongLineSplit"
	testw($f,"1;2;3",{"1;2;3"})
	testl($f,"1;;2;;3","1;2;3")
	testw($f,"1;;\"2;;3\"",{"1","\"2;;3\""})

	f="CommandPanelExp#WeakLineSplit"
	testl($f,"1;2;3"  ,"1;2;3")
	testl($f,"1;;2;;3","1;;2;;3")


	f="CommandPanelExp#ExpandNumberSeries"
	tests($f,"{1..3}","{1,2,3}")
	tests($f,"{-1..3}","{-1,0,1,2,3}")
	tests($f,"{1..9..2}" ,"{1,3,5,7,9}")
	tests($f,"{1..9..+2}","{1,3,5,7,9}")
	tests($f,"{1..9..-2}","{1,3,5,7,9}")
	tests($f,"{1..3..0}","{1,2,3}")
	tests($f,"{3..1}","{3,2,1}")
	tests($f,"{3..-1}","{3,2,1,0,-1}")

	f="CommandPanelExp#ExpandCharacterSeries"
	tests($f,"{a..c}","{a,b,c}")


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
		if(WaveMax(w)==0)
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
