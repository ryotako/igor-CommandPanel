#include "::CommandPanel"
#include "MinTest"
#pragma ModuleName=CommandPanelTest_Expand

static Function TestLineSplitting()
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
End

static Function TestAliasExpansion()
	// Expand Alias
	String path="root:Packages:CommandPanel:alias"
	if(WaveExists($path))
		Duplicate/T/FREE $path, backup
		Make/O/T/N=0 $path
	endif
	Make/FREE/T/N=0 EMPTY

	eq_text( Alias(""), EMPTY)
	eq_text( Alias("a = alias"), {"a=alias"})
	eq_text( Alias("ts = test"), {"ts=test","a=alias"})

	eq_text( CommandPanel#ExpandAlias(""), {""})
	eq_text( CommandPanel#ExpandAlias("a"), {"alias"})
	eq_text( CommandPanel#ExpandAlias("ts"), {"test"})
	eq_text( CommandPanel#ExpandAlias("a;a"), {"alias;alias"})
	eq_text( CommandPanel#ExpandAlias("aa"), {"aa"})


	if(WaveExists(backup))
		Duplicate/O/T backup, $path
	endif
End
static Function/WAVE Alias(expr)
	String expr
	CommandPanel#Alias(expr)
	WAVE/T w=root:Packages:CommandPanel:alias
	return w
End

static Function TestBraecExpansion()
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
End

static Function TestParenthesisComplesion()
	// Complete Parenthesis
	eq_text(CommandPanel#CompleteParen(""),{""})
	eq_text(CommandPanel#CompleteParen(" TestFunc_IGNORE "),{" TestFunc_IGNORE() "})
	eq_text(CommandPanel#CompleteParen(" TestFunc_IGNORE () "),{" TestFunc_IGNORE () "})
	eq_text(CommandPanel#CompleteParen("TestFunc_IGNORE a, b, c // comment"),{"TestFunc_IGNORE(a, b, c) // comment"})
	eq_text(CommandPanel#CompleteParen("TestFunc_IGNORE //"),{"TestFunc_IGNORE() //"})
	eq_text(CommandPanel#CompleteParen("TestFunc_IGNORE \" // \" "),{"TestFunc_IGNORE(\" // \") "})
	eq_text(CommandPanel#CompleteParen(" TestStrFunc_IGNORE "),{" TestStrFunc_IGNORE(\"\") "})
	eq_text(CommandPanel#CompleteParen("TestStrFunc_IGNORE test "),{"TestStrFunc_IGNORE(\"test\") "})
End

Function TestFunc_IGNORE()
End
Function TestStrFunc_IGNORE(s)
	String s
End
