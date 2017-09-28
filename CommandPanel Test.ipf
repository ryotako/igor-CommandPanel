#include "MinTest"
#include "CommandPanel"

//==============================================================================
// Interface
//==============================================================================

static Function Setup_Interface()
	KillAllCommandPanel()
	
	CommandPanel_SetLine("")
	CommandPanel_SetBuffer(CommandPanel#cast($""))
End

static Function Teardown_Interface()
	KillAllCommandPanel()
End

static Function WaveUpdate()
	Execute/Z "Make _"
End


static Function KillAllCommandPanel()
	String wins=WinList("CommandPanel*",";","WIN:64")
	Variable i,N = ItemsInList(wins)
	for(i=0;i<N;i+=1)
		KillWindow $StringFromList(i,wins)
	endfor
End

Function TestCommandPanel_Interface()
	Setup_Interface()
	
	// New
	CreateCommandPanel()
	eq_str(WinList("CommandPanel*",";","WIN:64"),"CommandPanel;")	
	eq_text(CommandPanel_GetBuffer(), $""); WaveUpdate();
	eq_str(CommandPanel_GetLine(), "")
	
	// Set/GetLine
	CommandPanel_SetLine("test")
	eq_str(CommandPanel_GetLine(), "test")
	CommandPanel_SetLine("test2")
	eq_str(CommandPanel_GetLine(), "test2")
	
	// Set/GetBuffer
	CommandPanel_SetBuffer( CommandPanel#cast({"test"}) ); WaveUpdate();
	eq_text(CommandPanel_GetBuffer(), {"test"})
	
	Teardown_Interface()
End

//==============================================================================
// Expand
//==============================================================================

static Function Setup_Expand()
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

static Function Teardown_Expand()
	KillDataFolder/Z root:Packages:TestCommandPanel
End


Function TestCommandPanel_Expand()
	Setup_Expand()
	
	// Strong Line Split
	eq_text(CommandPanel#StrongLineSplit(""), {""})
	eq_text(CommandPanel#StrongLineSplit("a"), {"a"})
	eq_text(CommandPanel#StrongLineSplit("a;b;c"), {"a;b;c"})
	eq_text(CommandPanel#StrongLineSplit("aaa;bbb;ccc"), {"aaa;bbb;ccc"})
	eq_text(CommandPanel#StrongLineSplit("a;;b;;c"), {"a","b","c"})	
	eq_text(CommandPanel#StrongLineSplit("a;;b;;c;;"), {"a","b","c",""})	
	eq_text(CommandPanel#StrongLineSplit("aaa;;bbb;;ccc"), {"aaa","bbb","ccc"})
	eq_text(CommandPanel#StrongLineSplit(" a ;; b ;; c "), {" a "," b "," c "})	
	eq_text(CommandPanel#StrongLineSplit("a;;b//;;c"), {"a","b//;;c"})
	eq_text(CommandPanel#StrongLineSplit("a;;\"b;;c\""), {"a","\"b;;c\""})
	eq_text(CommandPanel#StrongLineSplit("a;;\\\"b;;c\\\""), {"a","\\\"b","c\\\""})
	
	// Weak Line Split 
	eq_text(CommandPanel#WeakLineSplit(""), {""})
	eq_text(CommandPanel#WeakLineSplit("a;b;c"), {"a","b","c"})
	eq_text(CommandPanel#WeakLineSplit("aaa;bbb;ccc"), {"aaa","bbb","ccc"})
	eq_text(CommandPanel#WeakLineSplit(" a ; b ; c "), {" a "," b "," c "})
	eq_text(CommandPanel#WeakLineSplit("a;b;c;"), {"a","b","c",""})
	eq_text(CommandPanel#WeakLineSplit("a;b//;c"), {"a","b//;c"})
	eq_text(CommandPanel#WeakLineSplit("a;\"b;c\""), {"a","\"b;c\""})

	// ExpandAlias
	Make/FREE/T/N=0 empty
	CommandPanel#SetTxtWave("alias",empty)
	CommandPanel#Alias("a=alias")
	CommandPanel#Alias("ts=test")

	eq_str(CommandPanel#ExpandAlias(""), "")
	eq_str(CommandPanel#ExpandAlias("a"), "alias")
	eq_str(CommandPanel#ExpandAlias("ts"), "test")
	eq_str(CommandPanel#ExpandAlias("a;a"), "alias;alias")
	eq_str(CommandPanel#ExpandAlias("aa"), "aa")

	// Expand Brace
	eq_text(CommandPanel#ExpandBrace(""), {""})
	eq_text(CommandPanel#ExpandBrace("test"), {"test"})
	eq_text(CommandPanel#ExpandBrace("{test1,test2,test3}"), {"test1","test2","test3"})
	eq_text(CommandPanel#ExpandBrace("{}"), {"{}"})
	eq_text(CommandPanel#ExpandBrace("{test}"), {"{test}"})
	
	eq_text(CommandPanel#ExpandBrace("{a,b,c}"), {"a","b","c"})
	eq_text(CommandPanel#ExpandBrace("{1..10}"), {"1","2","3","4","5","6","7","8","9","10"})	
	eq_text(CommandPanel#ExpandBrace("{6..10}"), {"6","7","8","9","10"})	
	eq_text(CommandPanel#ExpandBrace("{5..1}" ), {"5","4","3","2","1"})	
	eq_text(CommandPanel#ExpandBrace("{A..Z}" ), {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"})	
	eq_text(CommandPanel#ExpandBrace("{a..z}" ), {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"})	
	eq_text(CommandPanel#ExpandBrace("{Z..A}" ), {"Z","Y","X","W","V","U","T","S","R","Q","P","O","N","M","L","K","J","I","H","G","F","E","D","C","B","A"})	
	eq_text(CommandPanel#ExpandBrace("{z..a}" ), {"z","y","x","w","v","u","t","s","r","q","p","o","n","m","l","k","j","i","h","g","f","e","d","c","b","a"})
	eq_text(CommandPanel#ExpandBrace("{1..10..2}"), {"1","3","5","7","9"})
	eq_text(CommandPanel#ExpandBrace("a{m,n}"), {"am","an"})
	eq_text(CommandPanel#ExpandBrace("{m,n}a"), {"ma","na"})
	eq_text(CommandPanel#ExpandBrace("a{m,n}b"), {"amb","anb"})
	eq_text(CommandPanel#ExpandBrace("{a,b}{m,n}"), {"am","an","bm","bn"})
	eq_text(CommandPanel#ExpandBrace("a{,m,n}"), {"a","am","an"})
	eq_text(CommandPanel#ExpandBrace("a{m,n,}"), {"am","an","a"})
	eq_text(CommandPanel#ExpandBrace("a{m,,n}"), {"am","a","an"})
	eq_text(CommandPanel#ExpandBrace("a{,,,}"), {"a","a","a","a"})
	eq_text(CommandPanel#ExpandBrace("a{b,{c,}}"), {"ab","ac","a"})

	eq_text(CommandPanel#ExpandBrace("\"{a,b,c}\""), {"\"{a,b,c}\""})
	eq_text(CommandPanel#ExpandBrace("//{a,b,c}"), {"//{a,b,c}"})
	eq_text(CommandPanel#ExpandBrace("{a,b//,c}"), {"{a,b//,c}"})	
	eq_text(CommandPanel#ExpandBrace("\\{a,b,c}"), {"\\{a,b,c}"})
	eq_text(CommandPanel#ExpandBrace("{a,b,c\\}"), {"{a,b,c\\}"})
	eq_text(CommandPanel#ExpandBrace("{a\\,b,c}"), {"a\\,b","c"})
	
	eq_text(CommandPanel#ExpandBrace("{4,{10..40..10},{50..300..50}} K"), {"4 K","10 K","20 K","30 K","40 K","50 K","100 K","150 K","200 K","250 K","300 K"})

	// Expand Path
	eq_text(CommandPanel#ExpandPath("cd :*"), {"cd :folder1", "cd :folder2", "cd :folder3"})
	eq_text(CommandPanel#ExpandPath("cd :**:"), {"cd :folder1:","cd :folder1:sub1:","cd :folder1:sub2:","cd :folder1:sub3:","cd :folder2:","cd :folder2:sub1:","cd :folder2:sub2:","cd :folder2:sub3:","cd :folder3:","cd :folder3:sub1:","cd :folder3:sub2:","cd :folder3:sub3:"})

	// Complete Parenthesis
	eq_str(CommandPanel#CompleteParen(""),"")
	eq_str(CommandPanel#CompleteParen(" FunctionForTest ")," FunctionForTest() ")
	eq_str(CommandPanel#CompleteParen(" FunctionForTest () ")," FunctionForTest () ")
	eq_str(CommandPanel#CompleteParen("FunctionForTest a, b, c // comment"),"FunctionForTest(a, b, c) // comment")
	eq_str(CommandPanel#CompleteParen("FunctionForTest //"),"FunctionForTest() //")
	eq_str(CommandPanel#CompleteParen("FunctionForTest \" // \" "),"FunctionForTest(\" // \") ")
	eq_str(CommandPanel#CompleteParen(" StrFunctionForTest ")," StrFunctionForTest(\"\") ")
	eq_str(CommandPanel#CompleteParen("StrFunctionForTest test "),"StrFunctionForTest(\"test\") ")

	Teardown_Expand()
End

override Function FunctionForTest()

End

override Function StrFunctionForTest(s)
	String s
End


//==============================================================================
// Complete
//==============================================================================

static Function Setup_Complete()
	Setup_Expand()
End

static Function Teardown_Complete()
	Teardown_Expand()
End



Function TestCommandPanel_Complete()
	Setup_Complete()
	
	CommandPanel_SetLine("cd :")
	CommandPanel#Complete()
	eq_text( CommandPanel_GetBuffer(), {"cd :folder1","cd :folder2","cd :folder3"})

	cd :folder1

	CommandPanel_SetLine("cd :")
	CommandPanel#Complete()
	eq_text( CommandPanel_GetBuffer(), {"cd :sub1","cd :sub2","cd :sub3"})

	CommandPanel_SetLine("cd ::")
	CommandPanel#Complete()
	eq_text( CommandPanel_GetBuffer(), {"cd ::folder1","cd ::folder2","cd ::folder3"})
	
	Teardown_Complete()
End