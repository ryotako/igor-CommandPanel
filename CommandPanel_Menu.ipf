#include ":CommandPanel_Interface"

strconstant CommandPanel_Menu = "CommandPanel"

Menu StringFromList(0,CommandPanel_Menu)
	RemoveListItem(0,CommandPanel_Menu)
	"New Command Panel",/Q,CommandPanel_New()
	MenuItem(0),  /Q, MenuCommand(0)
	MenuItem(1),  /Q, MenuCommand(1)
	MenuItem(2),  /Q, MenuCommand(2)
	MenuItem(3),  /Q, MenuCommand(3)
	MenuItem(4),  /Q, MenuCommand(4)
	MenuItem(5),  /Q, MenuCommand(5)
	MenuItem(6),  /Q, MenuCommand(6)
	MenuItem(7),  /Q, MenuCommand(7)
	MenuItem(8),  /Q, MenuCommand(8)
	MenuItem(9),  /Q, MenuCommand(9)
	MenuItem(10), /Q, MenuCommand(10)
	MenuItem(11), /Q, MenuCommand(11)
	MenuItem(12), /Q, MenuCommand(12)
	MenuItem(13), /Q, MenuCommand(13)
	MenuItem(14), /Q, MenuCommand(14)
	MenuItem(15), /Q, MenuCommand(15)
	MenuItem(16), /Q, MenuCommand(16)
	MenuItem(17), /Q, MenuCommand(17)
	MenuItem(18), /Q, MenuCommand(18)
	MenuItem(19), /Q, MenuCommand(19)
End

Function/S MenuItem(i)
	Variable i
	String win=CommandPanel#Target(N=i)
	GetWindow/Z $win,wtitle
	if(strlen(win))
		return "\M0"+win+" ("+S_Value+")"
	else
		return ""
	endif
End
Function MenuCommand(i)
	Variable i
	DoWindow/F $CommandPanel#Target(N=i)
End
