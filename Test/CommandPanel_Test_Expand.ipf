#ifndef INCLUDED_COMMAND_PANEL_EXP_TEST
#define INCLUDED_COMMAND_PANEL_EXP_TEST
#pragma ModuleName=CommandPanelExpTest

Menu "Test"
	"CommandPanel_Expand",CommandPanelExpTest#test()
End

static Function test()
	String sls="CommandPanelExp#StrongLineSplit"
	Ts($sls, "test",{"test"})
	Ts($sls, "a;;b;;c",{"a","b","c"})
	Ts($sls, "aa`;;bb;;`cc",{"aa`;;bb;;`cc"})
	Ts($sls, "aa\";;bb;;\"cc",{"aa\";;bb;;\"cc"})
	Ts($sls, "11\\;;22",{"11\\","22"})


End


static Function Ts(f,s_src,w_ans)
	FUNCREF CommandPanelExpTest_ProtoType f
	String s_src
	WAVE/T w_ans
	WAVE/T expanded = f(s_src)
	if(DimSize(w_ans,0) == DimSize(expanded,0))
		Make/FREE/N=(DimSize(w_ans,0)) w=abs(cmpstr(w_ans,expanded))
		if(WaveMax(w)==0)
			return NaN
		endif
	endif
	print "=============================="
	print "INPUT"
	print s_src
	print "EXPANDED"
	print expanded
	print "EXPACTED"
	print w_ans
	print "=============================="
End
Function/WAVE CommandPanelExpTest_ProtoType(s)
	String s
	Make/FREE/T/N=0 f; return f
End
