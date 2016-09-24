#include ":CommandPanel_Interface"
#pragma ModuleName=CommandPanelMenu

strconstant CommandPanelMenu = "CommandPanel"

Menu StringFromList(0,CommandPanelMenu)
	RemoveListItem(0,CommandPanelMenu)
	"New Command Panel",/Q,CommandPanel_New()
	CommandPanelMenu#MenuItem(0),  /Q, CommandPanelMenu#MenuCommand(0)
	CommandPanelMenu#MenuItem(1),  /Q, CommandPanelMenu#MenuCommand(1)
	CommandPanelMenu#MenuItem(2),  /Q, CommandPanelMenu#MenuCommand(2)
	CommandPanelMenu#MenuItem(3),  /Q, CommandPanelMenu#MenuCommand(3)
	CommandPanelMenu#MenuItem(4),  /Q, CommandPanelMenu#MenuCommand(4)
	CommandPanelMenu#MenuItem(5),  /Q, CommandPanelMenu#MenuCommand(5)
	CommandPanelMenu#MenuItem(6),  /Q, CommandPanelMenu#MenuCommand(6)
	CommandPanelMenu#MenuItem(7),  /Q, CommandPanelMenu#MenuCommand(7)
	CommandPanelMenu#MenuItem(8),  /Q, CommandPanelMenu#MenuCommand(8)
	CommandPanelMenu#MenuItem(9),  /Q, CommandPanelMenu#MenuCommand(9)
	CommandPanelMenu#MenuItem(10), /Q, CommandPanelMenu#MenuCommand(10)
	CommandPanelMenu#MenuItem(11), /Q, CommandPanelMenu#MenuCommand(11)
	CommandPanelMenu#MenuItem(12), /Q, CommandPanelMenu#MenuCommand(12)
	CommandPanelMenu#MenuItem(13), /Q, CommandPanelMenu#MenuCommand(13)
	CommandPanelMenu#MenuItem(14), /Q, CommandPanelMenu#MenuCommand(14)
	CommandPanelMenu#MenuItem(15), /Q, CommandPanelMenu#MenuCommand(15)
	CommandPanelMenu#MenuItem(16), /Q, CommandPanelMenu#MenuCommand(16)
	CommandPanelMenu#MenuItem(17), /Q, CommandPanelMenu#MenuCommand(17)
	CommandPanelMenu#MenuItem(18), /Q, CommandPanelMenu#MenuCommand(18)
	CommandPanelMenu#MenuItem(19), /Q, CommandPanelMenu#MenuCommand(19)
End

static Function/S MenuItem(i)
	Variable i
	String win=CommandPanel#Target(N=i)
	GetWindow/Z $win,wtitle
	if(strlen(win))
		return "\M0"+win+" ("+S_Value+")"
	else
		return ""
	endif
End
static Function MenuCommand(i)
	Variable i
	DoWindow/F $CommandPanel#Target(N=i)
End
