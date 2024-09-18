#pragma semicolon 1

#include <sourcemod>
#include <vip_core>
#include <multicolors>
#include <utilshelper>

#undef REQUIRE_PLUGIN
#tryinclude <ccc>
#tryinclude <sourcebanspp>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define VIP_FEATURE_NAME	"VIP"

ConVar g_cvVIPGroupName;
ConVar g_cvVIPGroupImmunity;

bool g_bClientLoaded[MAXPLAYERS + 1] = { false, ... };
bool g_bSbppClientsLoaded = false;
bool g_bReloadVips = false;
bool g_bLibraryCCC = false;

public Plugin myinfo =
{
	name = "[VIP] Sourcemod Flags",
	author = "R1KO & inGame & maxime1907",
	description = "Sets the sourcemod flags related to VIP features",
	version = "3.2.3"
};

public void OnAllPluginsLoaded()
{
	if (LibraryExists("ccc"))
		g_bLibraryCCC = true;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "ccc", false))
		g_bLibraryCCC = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "ccc", false))
		g_bLibraryCCC = false;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	g_cvVIPGroupName = CreateConVar("sm_vip_group_name", "VIP", "Group name of vip users");
	g_cvVIPGroupImmunity = CreateConVar("sm_vip_group_immunity", "5", "Immunity level of vip users", 0, true, 0.0, true, 100.0);

	RegAdminCmd("sm_reloadvips", Command_ReloadVips, ADMFLAG_BAN);
	RegAdminCmd("sm_adminimmunity", Command_GetImmunityLevel, ADMFLAG_BAN);

	AutoExecConfig(true);
}

public void OnMapEnd()
{
	g_bSbppClientsLoaded = false;
	g_bReloadVips = false;
	for (int i = 0; i <= MaxClients; i++)
		g_bClientLoaded[i] = false;
}

public Action Command_ReloadVips(int client, int args)
{
	ReloadVIPs();
	return Plugin_Handled;
}

public Action Command_GetImmunityLevel(int client, int args)
{
	if (!IsValidClient(client, false, false, true))
		return Plugin_Handled;

	if (args < 1)
	{
		CPrintToChat(client, "{green}[SM] {white}Usage: sm_adminimmunity <#userid|name>");
		return Plugin_Handled;
	}

	int iTargetCount;
	int iTargets[MAXPLAYERS+1];
	char sTargetName[MAX_TARGET_LENGTH];
	char argTarget[255];
	bool bIsML;
	GetCmdArg(1, argTarget, sizeof(argTarget));

	if((iTargetCount = ProcessTargetString(argTarget, client, iTargets, MAXPLAYERS, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < iTargetCount; i++)
	{
		AdminId aid = GetUserAdmin(iTargets[i]);
		int iImmunityLevel = GetAdminImmunityLevel(aid);
		CPrintToChat(client, "{green}[SM] {white}Immunity level of player %N is %d", iTargets[i], iImmunityLevel);
	}

	return Plugin_Handled;
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	// Only do something if admins are being rebuild
	if (part != AdminCache_Admins)
		return;

	if (g_bSbppClientsLoaded)
	{
		g_bSbppClientsLoaded = false;
		g_bReloadVips = true;
	}
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	g_bClientLoaded[client] = false;
	return true;
}

public void OnClientDisconnect(int client)
{
	g_bClientLoaded[client] = false;
}

public Action OnClientPreAdminCheck(int client)
{
	return g_bSbppClientsLoaded && g_bClientLoaded[client] ? Plugin_Continue : Plugin_Handled;
}

#if defined _sourcebanspp_included
public bool SBPP_OnClientPreAdminCheck(AdminCachePart part)
{
	if (part == AdminCache_Admins)
		g_bSbppClientsLoaded = true;

	for (int client = 1; client <= MaxClients; client++)
		CheckLoadAdmin(client);

	if (part == AdminCache_Admins)
	{
		if (g_bReloadVips)
			ReloadVIPs();
		g_bReloadVips = false;
	}

	return false;
}
#endif

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(VIP_FEATURE_NAME, STRING, HIDE);
}

public void VIP_OnClientLoaded(int client, bool isVip)
{
	LoadVIPClient(client);
}

public void VIP_OnVIPClientAdded(int client, int iAdmin)
{
	LoadVIPClient(client);
}

public void VIP_OnVIPClientRemoved(int client, const char[] szReason, int iAdmin)
{
	UnloadVIPClient(client);
}

stock void UnloadVIPClient(int client)
{
	RemoveClient(client);

#if defined _ccc_included
	if (g_bLibraryCCC && GetFeatureStatus(FeatureType_Native, "CCC_UnLoadClient") == FeatureStatus_Available)
		CCC_UnLoadClient(client);
#endif

	ServerCommand("sm_reloadadmins");
}

stock void LoadVIPClient(int client)
{
	if (!client)
		return;

	LoadClient(client);

#if defined _ccc_included
	if (g_bLibraryCCC && GetFeatureStatus(FeatureType_Native, "CCC_LoadClient") == FeatureStatus_Available)
		CCC_LoadClient(client);
#endif
}

stock void RemoveClient(int client)
{
	char sAuthType[] = "steam";
	char sAuth[32];
	GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));

	AdminId curAdm = INVALID_ADMIN_ID;
	// find and delete the admin using that identity
	if ((curAdm = FindAdminByIdentity(sAuthType, sAuth)) != INVALID_ADMIN_ID)
	{
		RemoveAdmin(curAdm);
	}

	g_bClientLoaded[client] = true;

	CheckLoadAdmin(client);
}

stock void LoadClient(int client)
{
	ArrayList Groups = new ArrayList(ByteCountToCells(32));
	char sVIPGroupName[64];

	if (VIP_IsClientVIP(client))
	{
		if (!VIP_GetClientVIPGroup(client, sVIPGroupName, sizeof(sVIPGroupName)))
			g_cvVIPGroupName.GetString(sVIPGroupName, sizeof(sVIPGroupName));

		Groups.PushString(sVIPGroupName);
	}

	if (Groups.Length)
	{
		char sAuthType[] = "steam";
		char sAuth[32];
		GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));

		AdminId curAdm = INVALID_ADMIN_ID;
		// find or create the admin using that identity
		if ((curAdm = FindAdminByIdentity(sAuthType, sAuth)) == INVALID_ADMIN_ID)
		{
			char sName[254];
			GetClientName(client, sName, sizeof(sName));
			curAdm = CreateAdmin(sName);
			// That should never happen!
			if (!curAdm.BindIdentity(sAuthType, sAuth))
			{
				RemoveAdmin(curAdm);
				delete Groups;
				return;
			}
		}

		for (int i = 0; i < Groups.Length; i++)
		{
			char sGroup[32];
			Groups.GetString(i, sGroup, sizeof(sGroup));

			GroupId grp;
			if((grp = FindAdmGroup(sGroup)) == INVALID_GROUP_ID)
			{
				grp = CreateAdmGroup(sGroup);
				if (StrEqual(sGroup, sVIPGroupName))
				{
					SetAdmGroupAddFlag(grp, Admin_Custom1, true);
					SetAdmGroupAddFlag(grp, Admin_Custom2, true);
					SetAdmGroupImmunityLevel(grp, g_cvVIPGroupImmunity.IntValue);
				}
			}

			AdminInheritGroup(curAdm, grp);
		}
	}

	delete Groups;

	g_bClientLoaded[client] = true;

	CheckLoadAdmin(client);
}

stock void CheckLoadAdmin(int client)
{
	if (IsClientInGame(client) && IsClientAuthorized(client))
	{
		RunAdminCacheChecks(client);

		if (g_bSbppClientsLoaded && g_bClientLoaded[client])
			NotifyPostAdminCheck(client);
	}
}

stock void ReloadVIPs()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			LoadVIPClient(i);
		}
	}
}
