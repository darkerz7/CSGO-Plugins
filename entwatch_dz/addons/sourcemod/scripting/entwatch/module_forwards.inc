#define EW_MODULE_FORWARDS

Handle	g_hOnBanForward,
		g_hOnUnbanForward;

stock void EWM_Forwards_OnPluginStart()
{
	g_hOnBanForward = CreateGlobalForward("EntWatch_OnClientBanned", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_hOnUnbanForward = CreateGlobalForward("EntWatch_OnClientUnbanned", ET_Ignore, Param_Cell, Param_Cell, Param_String);
}