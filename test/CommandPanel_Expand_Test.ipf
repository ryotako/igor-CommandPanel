#include "CommandPanel_Expand"
#include "MinTest"
#pragma ModuleName=CommandPanelTest_Expand

static Function setup()
	NewDataFolder/O/S root:Packages:TestCommandPanel

	NewDataFolder/O root:Packages:TestCommandPanel:folder1
	NewDataFolder/O root:Packages:TestCommandPanel:folder1:sub1
	NewDataFolder/O root:Packages:TestCommandPanel:folder1:sub2
	NewDataFolder/O root:Packages:TestCommandPanel:folder1:sub3

	NewDataFolder/O root:Packages:TestCommandPanel:folder2
	NewDataFolder/O root:Packages:TestCommandPanel:folder2:sub1
	NewDataFolder/O root:Packages:TestCommandPanel:folder2:sub2
	NewDataFolder/O root:Packages:TestCommandPanel:folder2:sub3

	NewDataFolder/O root:Packages:TestCommandPanel:folder3
	NewDataFolder/O root:Packages:TestCommandPanel:folder3:sub1
	NewDataFolder/O root:Packages:TestCommandPanel:folder3:sub2
	NewDataFolder/O root:Packages:TestCommandPanel:folder3:sub3
	
End

static Function teardown()
	KillDataFolder/Z root:Packages:TestCommandPanel
End


Function TestSplitLine()
	// Strong Line Split
	eq_text(CommandPanel_Expand#StrongLineSplit(""), {""})
	eq_text(CommandPanel_Expand#StrongLineSplit("a"), {"a"})
	eq_text(CommandPanel_Expand#StrongLineSplit("a;b;c"), {"a;b;c"})
	eq_text(CommandPanel_Expand#StrongLineSplit("aaa;bbb;ccc"), {"aaa;bbb;ccc"})
	eq_text(CommandPanel_Expand#StrongLineSplit("a;;b;;c"), {"a","b","c"})	
	eq_text(CommandPanel_Expand#StrongLineSplit("a;;b;;c;;"), {"a","b","c",""})	
	eq_text(CommandPanel_Expand#StrongLineSplit("aaa;;bbb;;ccc"), {"aaa","bbb","ccc"})
	eq_text(CommandPanel_Expand#StrongLineSplit(" a ;; b ;; c "), {" a "," b "," c "})	
	eq_text(CommandPanel_Expand#StrongLineSplit("a;;b//;;c"), {"a","b//;;c"})
	eq_text(CommandPanel_Expand#StrongLineSplit("a;;\"b;;c\""), {"a","\"b;;c\""})
	eq_text(CommandPanel_Expand#StrongLineSplit("a;;\\\"b;;c\\\""), {"a","\\\"b","c\\\""})
	
	// Weak Line Split 
	eq_text(CommandPanel_Expand#WeakLineSplit(""), {""})
	eq_text(CommandPanel_Expand#WeakLineSplit("a;b;c"), {"a","b","c"})
	eq_text(CommandPanel_Expand#WeakLineSplit("aaa;bbb;ccc"), {"aaa","bbb","ccc"})
	eq_text(CommandPanel_Expand#WeakLineSplit(" a ; b ; c "), {" a "," b "," c "})
	eq_text(CommandPanel_Expand#WeakLineSplit("a;b;c;"), {"a","b","c",""})
	eq_text(CommandPanel_Expand#WeakLineSplit("a;b//;c"), {"a","b//;c"})
	eq_text(CommandPanel_Expand#WeakLineSplit("a;\"b;c\""), {"a","\"b;c\""})
End

Function TestExpandAlias()
	// Expand Alias
	String path="root:Packages:CommandPanel:alias"
	if(WaveExists($path))
		Duplicate/T/FREE $path, backup
		Make/O/T/N=0 $path
	endif
	Make/FREE/T/N=0 empty
	CommandPanel_Interface#SetTxtWave("alias",empty)
	
	eq_text(Alias(""), $"")
	eq_text(Alias("a = alias"), {"a=alias"})
	eq_text(Alias("ts = test"), {"ts=test","a=alias"})

	eq_str(CommandPanel_Expand#ExpandAlias(""), "")
	eq_str(CommandPanel_Expand#ExpandAlias("a"), "alias")
	eq_str(CommandPanel_Expand#ExpandAlias("ts"), "test")
	eq_str(CommandPanel_Expand#ExpandAlias("a;a"), "alias;alias")
	eq_str(CommandPanel_Expand#ExpandAlias("aa"), "aa")


	if(WaveExists(backup))
		Duplicate/O/T backup, $path
	endif
End
static Function/WAVE Alias(expr)
	String expr
	CommandPanel_Execute#Alias(expr)
	return CommandPanel_Interface#GetTxtWave("alias")
End

Function TestExpandBrace()
	// Expand Brace
	eq_text(CommandPanel_Expand#ExpandBrace(""), {""})
	eq_text(CommandPanel_Expand#ExpandBrace("test"), {"test"})
	eq_text(CommandPanel_Expand#ExpandBrace("{test1,test2,test3}"), {"test1","test2","test3"})
	eq_text(CommandPanel_Expand#ExpandBrace("{}"), {"{}"})
	eq_text(CommandPanel_Expand#ExpandBrace("{test}"), {"{test}"})
	
	eq_text(CommandPanel_Expand#ExpandBrace("{a,b,c}"), {"a","b","c"})
	eq_text(CommandPanel_Expand#ExpandBrace("{1..10}"), {"1","2","3","4","5","6","7","8","9","10"})	
	eq_text(CommandPanel_Expand#ExpandBrace("{6..10}"), {"6","7","8","9","10"})	
	eq_text(CommandPanel_Expand#ExpandBrace("{5..1}" ), {"5","4","3","2","1"})	
	eq_text(CommandPanel_Expand#ExpandBrace("{A..Z}" ), {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"})	
	eq_text(CommandPanel_Expand#ExpandBrace("{a..z}" ), {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"})	
	eq_text(CommandPanel_Expand#ExpandBrace("{Z..A}" ), {"Z","Y","X","W","V","U","T","S","R","Q","P","O","N","M","L","K","J","I","H","G","F","E","D","C","B","A"})	
	eq_text(CommandPanel_Expand#ExpandBrace("{z..a}" ), {"z","y","x","w","v","u","t","s","r","q","p","o","n","m","l","k","j","i","h","g","f","e","d","c","b","a"})
	eq_text(CommandPanel_Expand#ExpandBrace("{1..10..2}"), {"1","3","5","7","9"})
	eq_text(CommandPanel_Expand#ExpandBrace("a{m,n}"), {"am","an"})
	eq_text(CommandPanel_Expand#ExpandBrace("{m,n}a"), {"ma","na"})
	eq_text(CommandPanel_Expand#ExpandBrace("a{m,n}b"), {"amb","anb"})
	eq_text(CommandPanel_Expand#ExpandBrace("{a,b}{m,n}"), {"am","an","bm","bn"})
	eq_text(CommandPanel_Expand#ExpandBrace("a{,m,n}"), {"a","am","an"})
	eq_text(CommandPanel_Expand#ExpandBrace("a{m,n,}"), {"am","an","a"})
	eq_text(CommandPanel_Expand#ExpandBrace("a{m,,n}"), {"am","a","an"})
	eq_text(CommandPanel_Expand#ExpandBrace("a{,,,}"), {"a","a","a","a"})
	eq_text(CommandPanel_Expand#ExpandBrace("a{b,{c,}}"), {"ab","ac","a"})

	eq_text(CommandPanel_Expand#ExpandBrace("\"{a,b,c}\""), {"\"{a,b,c}\""})
	eq_text(CommandPanel_Expand#ExpandBrace("//{a,b,c}"), {"//{a,b,c}"})
	eq_text(CommandPanel_Expand#ExpandBrace("{a,b//,c}"), {"{a,b//,c}"})	
	eq_text(CommandPanel_Expand#ExpandBrace("\\{a,b,c}"), {"\\{a,b,c}"})
	eq_text(CommandPanel_Expand#ExpandBrace("{a,b,c\\}"), {"{a,b,c\\}"})
	eq_text(CommandPanel_Expand#ExpandBrace("{a\\,b,c}"), {"a\\,b","c"})
	
	eq_text(CommandPanel_Expand#ExpandBrace("{4,{10..40..10},{50..300..50}} K"), {"4 K","10 K","20 K","30 K","40 K","50 K","100 K","150 K","200 K","250 K","300 K"})
End

Function TestExpandPath()
	setup()

	eq_text(CommandPanel_Expand#ExpandPath("cd :*"), {"cd :folder1", "cd :folder2", "cd :folder3"})
	eq_text(CommandPanel_Expand#ExpandPath("cd :**:"), {"cd :folder1:","cd :folder1:sub1:","cd :folder1:sub2:","cd :folder1:sub3:","cd :folder2:","cd :folder2:sub1:","cd :folder2:sub2:","cd :folder2:sub3:","cd :folder3:","cd :folder3:sub1:","cd :folder3:sub2:","cd :folder3:sub3:"})
	
	teardown()
End


Function TestExpandCompleteParen()
	// Complete Parenthesis
	eq_str(CommandPanel_Expand#CompleteParen(""),"")
	eq_str(CommandPanel_Expand#CompleteParen(" FunctionForTest ")," FunctionForTest() ")
	eq_str(CommandPanel_Expand#CompleteParen(" FunctionForTest () ")," FunctionForTest () ")
	eq_str(CommandPanel_Expand#CompleteParen("FunctionForTest a, b, c // comment"),"FunctionForTest(a, b, c) // comment")
	eq_str(CommandPanel_Expand#CompleteParen("FunctionForTest //"),"FunctionForTest() //")
	eq_str(CommandPanel_Expand#CompleteParen("FunctionForTest \" // \" "),"FunctionForTest(\" // \") ")
	eq_str(CommandPanel_Expand#CompleteParen(" StrFunctionForTest ")," StrFunctionForTest(\"\") ")
	eq_str(CommandPanel_Expand#CompleteParen("StrFunctionForTest test "),"StrFunctionForTest(\"test\") ")
End

Function FunctionForTest()
End
Function StrFunctionForTest(s)
	String s
End
