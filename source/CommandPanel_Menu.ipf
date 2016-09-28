#include ":CommandPanel_Interface"
#pragma ModuleName=CommandPanel_Menu

strconstant CommandPanel_Menu = "CommandPanel"

Menu StringFromList(0,CommandPanel_Menu)
	RemoveListItem(0,CommandPanel_Menu)
	"New Command Panel",/Q,CommandPanel_New()
	CommandPanel_Menu#MenuItem(0),  /Q, CommandPanel_Menu#MenuCommand(0)
	CommandPanel_Menu#MenuItem(1),  /Q, CommandPanel_Menu#MenuCommand(1)
	CommandPanel_Menu#MenuItem(2),  /Q, CommandPanel_Menu#MenuCommand(2)
	CommandPanel_Menu#MenuItem(3),  /Q, CommandPanel_Menu#MenuCommand(3)
	CommandPanel_Menu#MenuItem(4),  /Q, CommandPanel_Menu#MenuCommand(4)
	CommandPanel_Menu#MenuItem(5),  /Q, CommandPanel_Menu#MenuCommand(5)
	CommandPanel_Menu#MenuItem(6),  /Q, CommandPanel_Menu#MenuCommand(6)
	CommandPanel_Menu#MenuItem(7),  /Q, CommandPanel_Menu#MenuCommand(7)
	CommandPanel_Menu#MenuItem(8),  /Q, CommandPanel_Menu#MenuCommand(8)
	CommandPanel_Menu#MenuItem(9),  /Q, CommandPanel_Menu#MenuCommand(9)
	CommandPanel_Menu#MenuItem(10), /Q, CommandPanel_Menu#MenuCommand(10)
	CommandPanel_Menu#MenuItem(11), /Q, CommandPanel_Menu#MenuCommand(11)
	CommandPanel_Menu#MenuItem(12), /Q, CommandPanel_Menu#MenuCommand(12)
	CommandPanel_Menu#MenuItem(13), /Q, CommandPanel_Menu#MenuCommand(13)
	CommandPanel_Menu#MenuItem(14), /Q, CommandPanel_Menu#MenuCommand(14)
	CommandPanel_Menu#MenuItem(15), /Q, CommandPanel_Menu#MenuCommand(15)
	CommandPanel_Menu#MenuItem(16), /Q, CommandPanel_Menu#MenuCommand(16)
	CommandPanel_Menu#MenuItem(17), /Q, CommandPanel_Menu#MenuCommand(17)
	CommandPanel_Menu#MenuItem(18), /Q, CommandPanel_Menu#MenuCommand(18)
	CommandPanel_Menu#MenuItem(19), /Q, CommandPanel_Menu#MenuCommand(19)
End

static Function/S MenuItem(i)
	Variable i
	String win=CommandPanel_Interface#Target(N=i)
	GetWindow/Z $win,wtitle
	if(strlen(win))
		return "\M0"+win+" ("+S_Value+")"
	else
		return ""
	endif
End
static Function MenuCommand(i)
	Variable i
	DoWindow/F $CommandPanel_Interface#Target(N=i)
End
