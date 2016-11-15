#include "writer.test"
#include "::CommandPanel"
#pragma ModuleName=cpTest

Function test_expand()
	// Strong Line Split
	eq_texts(CommandPanel#StrongLineSplit(""), {""})
	eq_texts(CommandPanel#StrongLineSplit("a"), {"a"})
	eq_texts(CommandPanel#StrongLineSplit("a;b;c"), {"a;b;c"})
	eq_texts(CommandPanel#StrongLineSplit("aaa;bbb;ccc"), {"aaa;bbb;ccc"})
	eq_texts(CommandPanel#StrongLineSplit("a;;b;;c"), {"a","b","c"})	
	eq_texts(CommandPanel#StrongLineSplit("a;;b;;c;;"), {"a","b","c",""})	
	eq_texts(CommandPanel#StrongLineSplit("aaa;;bbb;;ccc"), {"aaa","bbb","ccc"})
	eq_texts(CommandPanel#StrongLineSplit(" a ;; b ;; c "), {" a "," b "," c "})	

	eq_texts(CommandPanel#StrongLineSplit("a;;b//;;c"), {"a","b//;;c"})
	eq_texts(CommandPanel#StrongLineSplit("a;;\"b;;c\""), {"a","b//;;c"})
	eq_texts(CommandPanel#StrongLineSplit("a;;\\\"b;;c\\\""), {"a","\\\"b","c\\\""})
	
	// Weak Line Split 
	eq_texts(CommandPanel#WeakLineSplit(""), {""})
	eq_texts(CommandPanel#WeakLineSplit("a;b;c"), {"a","b","c"})
	eq_texts(CommandPanel#WeakLineSplit("aaa;bbb;ccc"), {"aaa","bbb","ccc"})
	eq_texts(CommandPanel#WeakLineSplit(" a ; b ; c "), {" a "," b "," c "})
	eq_texts(CommandPanel#WeakLineSplit("a;b;c;"), {"a","b","c",""})

	eq_texts(CommandPanel#WeakLineSplit("a;b//;c"), {"a","b//;c"})
	eq_texts(CommandPanel#WeakLineSplit("a;\"b;c\""), {"a","\"b;c\""})
	
	// Expand Alias
	String alias_wave="root:Packages:CommandPanel:alias"
	if(WaveExists($alias_wave))
		Duplicate/T/FREE $alias_wave, backup
		Make/O/T/N=0 $alias_wave
	endif
	
//	eq_texts(CommandPanel#Alias(""), $"")
//	eq_texts(CommandPanel#Alias("a = alias"), $"")
//	eq_texts(CommandPanel#Alias(""), {"a=alias"})
//	eq_texts(CommandPanel#Alias("a2= a"), $"")
//	eq_texts(CommandPanel#Alias(""), {"a2=a","a=alias"})
//	eq_texts(CommandPanel#Alias("t = test"), $"")
	
//	eq_texts(CommandPanel#ExpandAlias(""), {""})
//	eq_texts(CommandPanel#ExpandAlias("a"), {"alias"})
//	eq_texts(CommandPanel#ExpandAlias("a2"), {"alias"})
//	eq_texts(CommandPanel#ExpandAlias("a;a"), {"alias;alias"})
//	eq_texts(CommandPanel#ExpandAlias("aa"), {"aa"})

		
	if(WaveExists(backup))
		Duplicate/O/T backup, $alias_wave
	endif

	// Expand Brace
	eq_texts(CommandPanel#ExpandBrace(""), {""})
	eq_texts(CommandPanel#ExpandBrace("test"), {"test"})
	eq_texts(CommandPanel#ExpandBrace("{test1,test2,test3}"), {"test1","test2","test3"})
	eq_texts(CommandPanel#ExpandBrace("{}"), {"{}"})
	eq_texts(CommandPanel#ExpandBrace("{test}"), {"{test}"})
	
	eq_texts(CommandPanel#ExpandBrace("{a,b,c}"), {"a","b","c"})
	eq_texts(CommandPanel#ExpandBrace("{1..10}"), {"1","2","3","4","5","6","7","8","9","10"})	
	eq_texts(CommandPanel#ExpandBrace("{6..10}"), {"6","7","8","9","10"})	
	eq_texts(CommandPanel#ExpandBrace("{5..1}" ), {"5","4","3","2","1"})	
	eq_texts(CommandPanel#ExpandBrace("{A..Z}" ), {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"})	
	eq_texts(CommandPanel#ExpandBrace("{a..z}" ), {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"})	
	eq_texts(CommandPanel#ExpandBrace("{Z..A}" ), {"Z","Y","X","W","V","U","T","S","R","Q","P","O","N","M","L","K","J","I","H","G","F","E","D","C","B","A"})	
	eq_texts(CommandPanel#ExpandBrace("{z..a}" ), {"z","y","x","w","v","u","t","s","r","q","p","o","n","m","l","k","j","i","h","g","f","e","d","c","b","a"})
	eq_texts(CommandPanel#ExpandBrace("{1..10..2}"), {"1","3","5","7","9"})
	eq_texts(CommandPanel#ExpandBrace("a{m,n}"), {"am","an"})
	eq_texts(CommandPanel#ExpandBrace("{m,n}a"), {"ma","na"})
	eq_texts(CommandPanel#ExpandBrace("a{m,n}b"), {"amb","anb"})
	eq_texts(CommandPanel#ExpandBrace("{a,b}{m,n}"), {"am","an","bm","bn"})
	eq_texts(CommandPanel#ExpandBrace("a{,m,n}"), {"a","am","an"})
	eq_texts(CommandPanel#ExpandBrace("a{m,n,}"), {"am","an","a"})
	eq_texts(CommandPanel#ExpandBrace("a{m,,n}"), {"am","a","an"})
	eq_texts(CommandPanel#ExpandBrace("a{,,,}"), {"a","a","a","a"})
	eq_texts(CommandPanel#ExpandBrace("a{b,{c,}}"), {"ab","ac","a"})

	eq_texts(CommandPanel#ExpandBrace("\"{a,b,c}\""), {"\"{a,b,c}\""})
	eq_texts(CommandPanel#ExpandBrace("//{a,b,c}"), {"//{a,b,c}"})
	eq_texts(CommandPanel#ExpandBrace("{a,b//,c}"), {"{a,b//,c}"})	
	eq_texts(CommandPanel#ExpandBrace("\\{a,b,c}"), {"{a,b,c}"})
	eq_texts(CommandPanel#ExpandBrace("{a,b,c\\}"), {"{a,b,c}"})
	eq_texts(CommandPanel#ExpandBrace("{a\\,b,c}"), {"a,b","c"})
	
	eq_texts(CommandPanel#ExpandBrace("{4,{10..40..10},{50..300..50}} K"), {"4 K","10 K","20 K","30 K","40 K","50 K","100 K","150 K","200 K","250 K","300 K"})
	
	// Complete Parenthesis
	eq_texts(CommandPanel#CompleteParen(""),{""})
	eq_texts(CommandPanel#CompleteParen(" test_expand "),{" test_expand() "})
	eq_texts(CommandPanel#CompleteParen(" test_expand () "),{" test_expand () "})
	eq_texts(CommandPanel#CompleteParen("test_expand a, b, c // comment"),{"test_expand(a, b, c) // comment"})
	eq_texts(CommandPanel#CompleteParen("test_expand //"),{"test_expand() //"})
	eq_texts(CommandPanel#CompleteParen("test_expand \" // \" "),{"test_expand(\" // \") "})
	eq_texts(CommandPanel#CompleteParen(" test_strfunc "),{" test_strfunc(\"\") "})
	eq_texts(CommandPanel#CompleteParen("test_strfunc test "),{"test_strfunc(\"test\") "})
	eq_texts(CommandPanel#CompleteParen("cpTest#test_func "),{"cpTest#test_func(\"\") "})
	
End

static Function test_func(s)
	String s
End
Function test_strfunc(s)
	String s
End