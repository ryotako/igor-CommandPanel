#ifndef LOADED_COMMAND_PANEL
#define LOADED_COMMAND_PANEL
#include "CommandPanel_Execute"
#include "CommandPanel_Complete"
#pragma ModuleName=CommandPanelMenu
strconstant COMMAND_PANEL_MENU = "CommandPanel"

Menu COMMAND_PANEL_MENU
	"New Command Panel",/Q,CommandPanel_New()
	CommandPanelMenu#Item(0),  /Q, DoWindow/F $CommandPanel#Target(N=0)
	CommandPanelMenu#Item(1),  /Q, DoWindow/F $CommandPanel#Target(N=1)
	CommandPanelMenu#Item(2),  /Q, DoWindow/F $CommandPanel#Target(N=2)
	CommandPanelMenu#Item(3),  /Q, DoWindow/F $CommandPanel#Target(N=3)
	CommandPanelMenu#Item(4),  /Q, DoWindow/F $CommandPanel#Target(N=4)
	CommandPanelMenu#Item(5),  /Q, DoWindow/F $CommandPanel#Target(N=5)
	CommandPanelMenu#Item(6),  /Q, DoWindow/F $CommandPanel#Target(N=6)
	CommandPanelMenu#Item(7),  /Q, DoWindow/F $CommandPanel#Target(N=7)
	CommandPanelMenu#Item(8),  /Q, DoWindow/F $CommandPanel#Target(N=8)
	CommandPanelMenu#Item(9),  /Q, DoWindow/F $CommandPanel#Target(N=9)
	CommandPanelMenu#Item(10), /Q, DoWindow/F $CommandPanel#Target(N=10)
	CommandPanelMenu#Item(11), /Q, DoWindow/F $CommandPanel#Target(N=11)
	CommandPanelMenu#Item(12), /Q, DoWindow/F $CommandPanel#Target(N=12)
	CommandPanelMenu#Item(13), /Q, DoWindow/F $CommandPanel#Target(N=13)
	CommandPanelMenu#Item(14), /Q, DoWindow/F $CommandPanel#Target(N=14)
	CommandPanelMenu#Item(15), /Q, DoWindow/F $CommandPanel#Target(N=15)
	CommandPanelMenu#Item(16), /Q, DoWindow/F $CommandPanel#Target(N=16)
	CommandPanelMenu#Item(17), /Q, DoWindow/F $CommandPanel#Target(N=17)
	CommandPanelMenu#Item(18), /Q, DoWindow/F $CommandPanel#Target(N=18)
	CommandPanelMenu#Item(19), /Q, DoWindow/F $CommandPanel#Target(N=19)
End

static Function/S Item(i)
	Variable i
	String win=CommandPanel#Target(N=i)
	GetWindow/Z $win,wtitle
	if(strlen(win))
		return "\M0"+win+" ("+S_Value+")"
	else
		return ""
	endif
End

#endif
