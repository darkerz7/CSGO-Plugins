In order to add new commands to the menu open configs/helpmenu.cfg
Key - FakeCommand for client
Value - Any unique character set for helpmenu_multilang.phrases

In order to correct the rules and messages open helpmenu_multilang.phrases
Help Text Main - Text for Main HelpMenu(Can Use Tags)
Help Text Rules - Text for Rules HelpMenu(Can Use Tags)
Help Text Info - Text for Server Info HelpMenu(Can Use Tags)

If you added new commands then the corresponding translation should be added to helpmenu_multilang.phrases
ex.
configs/helpmenu.cfg
"say !music" "Translate Command MUSIC"

helpmenu_multilang.phrases
"Translate Command MUSIC"
{
	"en"			"Use !music for disable music on map"
}

List of Tags:
Server Name: {SERVERNAME}
IP Server: {IP}
Port Server: {PORT}
Tickrate: {TIC}
Current Players: {PL}
Max Players: {PLMAX}
Current Map: {MAP}
Next Map: {NEXTMAP}
Date: {DATE}
Time: {TIME}
Remaining time: {TIMELEFT}