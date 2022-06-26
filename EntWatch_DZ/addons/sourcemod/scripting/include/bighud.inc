//Special include for 1024 symbols hud by DarkerZ[RUS]. Special thanks Kotya
#if defined _bighud_included
 #endinput
#endif
#define _bighud_included

enum struct class_BigHudSettings
{
	float	fPos[2];
	float	fHoldTime;
	
	int		iColor1[4];
	int		iColor2[4];
	
	int		iEffect;
	float	ffxTime;
	float	ffadeIn;
	float	ffadeOut;
	
	void SetHudParams(float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut)
	{
		this.fPos[0] = x;
		this.fPos[1] = y;
		this.fHoldTime = holdTime;
		this.iColor1[0] = r;
		this.iColor1[1] = g;
		this.iColor1[2] = b;
		this.iColor1[3] = a;
		this.iColor2[0] = r;
		this.iColor2[1] = g;
		this.iColor2[2] = b;
		this.iColor2[3] = a;
		this.iEffect = effect;
		this.ffxTime = fxTime;
		this.ffadeIn = fadeIn;
		this.ffadeOut = fadeOut;
	}
	
	void SetHudParamsEx(float x, float y, float holdTime, int color1[4], int color2[4], int effect, float fxTime, float fadeIn, float fadeOut)
	{
		this.fPos[0] = x;
		this.fPos[1] = y;
		this.fHoldTime = holdTime;
		this.iColor1[0] = color1[0];
		this.iColor1[1] = color1[1];
		this.iColor1[2] = color1[2];
		this.iColor1[3] = color1[3];
		this.iColor2[0] = color2[0];
		this.iColor2[1] = color2[1];
		this.iColor2[2] = color2[2];
		this.iColor2[3] = color2[3];
		this.iEffect = effect;
		this.ffxTime = fxTime;
		this.ffadeIn = fadeIn;
		this.ffadeOut = fadeOut;
	}
}

class_BigHudSettings g_cBigHudSettings;
bool g_bBigHudInit = false;

stock void BigHud_SetHudTextParams(float x = -1.0, float y = -1.0, float holdTime = 1.0,
						int r = 255, int g = 255, int b = 255, int a = 255,
						int effect = 0, float fxTime = 0.0, float fadeIn = 0.0, float fadeOut = 0.0)
{
	g_cBigHudSettings.SetHudParams(x, y, holdTime, r, g, b, a, effect, fxTime, fadeIn, fadeOut);
	g_bBigHudInit = true;
}

stock void BigHud_SetHudTextParamsEx(float x = -1.0, float y = -1.0, float holdTime = 1.0,
						int color1[4] = {255, 255, 255, 255}, int color2[4] = {255, 255, 255, 255},
						int effect = 0, float fxTime = 0.0, float fadeIn = 0.0, float fadeOut = 0.0)
{
	
	g_cBigHudSettings.SetHudParamsEx(x, y, holdTime, color1, color2, effect, fxTime, fadeIn, fadeOut);
	g_bBigHudInit = true;
}

stock int BigHud_ShowHudText(int client, int channel, const char[] message, any ...)
{
	if(!g_bBigHudInit)
	{
		BigHud_SetHudTextParamsEx();
		g_bBigHudInit = true;
	}
	Protobuf pb = view_as<Protobuf>(StartMessageOne("HudMsg", client, USERMSG_RELIABLE));
	if(pb)
	{
		pb.SetInt("channel", channel);
		pb.SetVector2D("pos", g_cBigHudSettings.fPos);
		pb.SetColor("clr1", g_cBigHudSettings.iColor1);
		pb.SetColor("clr2", g_cBigHudSettings.iColor2);
		pb.SetInt("effect", g_cBigHudSettings.iEffect);
		pb.SetFloat("fade_in_time", g_cBigHudSettings.ffadeIn);
		pb.SetFloat("fade_out_time", g_cBigHudSettings.ffadeOut);
		pb.SetFloat("hold_time", g_cBigHudSettings.fHoldTime);
		pb.SetFloat("fx_time", g_cBigHudSettings.ffxTime);
		int iLen = strlen(message) + 255;
		char[] szBuffer = new char[iLen];
		VFormat(szBuffer, iLen, message, 4);
		pb.SetString("text", szBuffer);
		EndMessage();
		return channel;
	}
	return -1;
}