#pragma IndependentModule=CommandPanel
//#ifndef LOADED_COMMAND_PANEL
//#define LOADED_COMMAND_PANEL

#include ":igor-writer:writer"
#include ":CommandPanel_Expand"
#include ":CommandPanel_Interface"
#include ":CommandPanel_Execute"
#include ":CommandPanel_Complete"

strconstant COMMAND_PANEL_MENU = "CommandPanel"

Menu COMMAND_PANEL_MENU
	"New Command Panel",/Q,CommandPanel_New()
	CommandPanel#MenuItem(0),  /Q, DoWindow/F $CommandPanel#Target(N=0)
	CommandPanel#MenuItem(1),  /Q, DoWindow/F $CommandPanel#Target(N=1)
	CommandPanel#MenuItem(2),  /Q, DoWindow/F $CommandPanel#Target(N=2)
	CommandPanel#MenuItem(3),  /Q, DoWindow/F $CommandPanel#Target(N=3)
	CommandPanel#MenuItem(4),  /Q, DoWindow/F $CommandPanel#Target(N=4)
	CommandPanel#MenuItem(5),  /Q, DoWindow/F $CommandPanel#Target(N=5)
	CommandPanel#MenuItem(6),  /Q, DoWindow/F $CommandPanel#Target(N=6)
	CommandPanel#MenuItem(7),  /Q, DoWindow/F $CommandPanel#Target(N=7)
	CommandPanel#MenuItem(8),  /Q, DoWindow/F $CommandPanel#Target(N=8)
	CommandPanel#MenuItem(9),  /Q, DoWindow/F $CommandPanel#Target(N=9)
	CommandPanel#MenuItem(10), /Q, DoWindow/F $CommandPanel#Target(N=10)
	CommandPanel#MenuItem(11), /Q, DoWindow/F $CommandPanel#Target(N=11)
	CommandPanel#MenuItem(12), /Q, DoWindow/F $CommandPanel#Target(N=12)
	CommandPanel#MenuItem(13), /Q, DoWindow/F $CommandPanel#Target(N=13)
	CommandPanel#MenuItem(14), /Q, DoWindow/F $CommandPanel#Target(N=14)
	CommandPanel#MenuItem(15), /Q, DoWindow/F $CommandPanel#Target(N=15)
	CommandPanel#MenuItem(16), /Q, DoWindow/F $CommandPanel#Target(N=16)
	CommandPanel#MenuItem(17), /Q, DoWindow/F $CommandPanel#Target(N=17)
	CommandPanel#MenuItem(18), /Q, DoWindow/F $CommandPanel#Target(N=18)
	CommandPanel#MenuItem(19), /Q, DoWindow/F $CommandPanel#Target(N=19)
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

//#endif
