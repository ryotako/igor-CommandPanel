#pragma ModuleName=CmdPnlCompleteTest
#include "MinTest"
#include "CommandPanel_Complete"


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

Function TestCompletePathname()
	setup()
	
	CommandPanel_SetLine("cd :")
	CommandPanel_Complete#CompletePathname()
	eq_text( CommandPanel_GetBuffer(), {"cd :folder1","cd :folder2","cd :folder3"})

	cd :folder1

	CommandPanel_SetLine("cd :")
	CommandPanel_Complete#CompletePathname()
	eq_text( CommandPanel_GetBuffer(), {"cd :sub1","cd :sub2","cd :sub3"})

	CommandPanel_SetLine("cd ::")
	CommandPanel_Complete#CompletePathname()
	eq_text( CommandPanel_GetBuffer(), {"cd ::folder1","cd ::folder2","cd ::folder3"})
	
	teardown()
End