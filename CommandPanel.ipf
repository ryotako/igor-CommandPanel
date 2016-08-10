#pragma ModuleName=CommandPanelMenu

#include ":CommandPanel_Expand"
#include ":CommandPanel_Interface"
#include ":CommandPanel_Execute"
#include ":CommandPanel_Complete"
strconstant CommandPanel_Menu = "CommandPanel"

Menu CommandPanel_Menu
	"New Command Panel",/Q,CommandPanel#New()
	CommandPanelMenu#MenuItem(0),  /Q, DoWindow/F $CommandPanel#Target(N=0)
	CommandPanelMenu#MenuItem(1),  /Q, DoWindow/F $CommandPanel#Target(N=1)
	CommandPanelMenu#MenuItem(2),  /Q, DoWindow/F $CommandPanel#Target(N=2)
	CommandPanelMenu#MenuItem(3),  /Q, DoWindow/F $CommandPanel#Target(N=3)
	CommandPanelMenu#MenuItem(4),  /Q, DoWindow/F $CommandPanel#Target(N=4)
	CommandPanelMenu#MenuItem(5),  /Q, DoWindow/F $CommandPanel#Target(N=5)
	CommandPanelMenu#MenuItem(6),  /Q, DoWindow/F $CommandPanel#Target(N=6)
	CommandPanelMenu#MenuItem(7),  /Q, DoWindow/F $CommandPanel#Target(N=7)
	CommandPanelMenu#MenuItem(8),  /Q, DoWindow/F $CommandPanel#Target(N=8)
	CommandPanelMenu#MenuItem(9),  /Q, DoWindow/F $CommandPanel#Target(N=9)
	CommandPanelMenu#MenuItem(10), /Q, DoWindow/F $CommandPanel#Target(N=10)
	CommandPanelMenu#MenuItem(11), /Q, DoWindow/F $CommandPanel#Target(N=11)
	CommandPanelMenu#MenuItem(12), /Q, DoWindow/F $CommandPanel#Target(N=12)
	CommandPanelMenu#MenuItem(13), /Q, DoWindow/F $CommandPanel#Target(N=13)
	CommandPanelMenu#MenuItem(14), /Q, DoWindow/F $CommandPanel#Target(N=14)
	CommandPanelMenu#MenuItem(15), /Q, DoWindow/F $CommandPanel#Target(N=15)
	CommandPanelMenu#MenuItem(16), /Q, DoWindow/F $CommandPanel#Target(N=16)
	CommandPanelMenu#MenuItem(17), /Q, DoWindow/F $CommandPanel#Target(N=17)
	CommandPanelMenu#MenuItem(18), /Q, DoWindow/F $CommandPanel#Target(N=18)
	CommandPanelMenu#MenuItem(19), /Q, DoWindow/F $CommandPanel#Target(N=19)
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
