#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors_csgo>

#pragma semicolon 1
#pragma newdecls required

int Round = 0;
int g_BombsiteA = -1;
int g_BombsiteB = -1;

ConVar BombsiteInterval, BombsiteMessage, BombsitePrefix, BombsiteMinPlayers;

public Plugin myinfo = 
{
	name = "Bombsite Restric Rounds", 
	author = "Nocky", 
	description = "", 
	version = "1.0", 
	url = "https://github.com/NockyCZ"
};

public void OnPluginStart()
{
	BombsiteMinPlayers = CreateConVar("sm_bsr_minplayers", "4", "Minimum players to enable this plugin");
	BombsiteInterval = CreateConVar("sm_bsr_interval", "6", "Bombsite Restric Rounds interval");
	BombsiteMessage = CreateConVar("sm_bsr_message", "0", "Show information about restric plants | 1 = Both teams | 0 = Only Terrorist");
	BombsitePrefix = CreateConVar("sm_bsr_prefix", "{green}[Bombsite]{default}", "Prefix before chat messages");
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	AutoExecConfig(true, "Bombsite_Restric_Rounds");
	LoadTranslations("Bombsite_Restric_Rounds.phrases");
}

public void OnMapStart()
{
	Round = 0;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	GetBombsitesIndexes();
	if (Round == BombsiteInterval.IntValue)
	{
		AcceptEntityInput(g_BombsiteA, "Enable");
		AcceptEntityInput(g_BombsiteB, "Enable");
		Round = 0;
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Round++;
	int random = GetRandomInt(0, 1);
	int maxclients = GetClientCount(true);
	if (maxclients > BombsiteMinPlayers.IntValue)
	{
		if (Round == BombsiteInterval.IntValue)
		{
			RandomBombiste(random);
		}
	}
	//PrintToChatAll("%d", Round);
}

void RandomBombiste(int site)
{
	char PREFIX[256];
	BombsitePrefix.GetString(PREFIX, sizeof(PREFIX));
	GetBombsitesIndexes();
	
	switch (site)
	{
		case 0:
		{
			AcceptEntityInput(g_BombsiteA, "Disable");
			if (BombsiteMessage.BoolValue)
			{
				CPrintToChatAll("%s %t", PREFIX, "ASiteAllChat");
			}
			else
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
						continue;
					
					if (GetClientTeam(i) == CS_TEAM_T)
					{
						CPrintToChat(i, "%s %t", PREFIX, "ASiteChat");
					}
				}
			}
		}
		case 1:
		{
			AcceptEntityInput(g_BombsiteB, "Disable");
			if (BombsiteMessage.BoolValue)
			{
				CPrintToChatAll("%s %t", PREFIX, "BSiteAllChat");
			}
			else
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
						continue;
					if (GetClientTeam(i) == CS_TEAM_T)
					{
						CPrintToChat(i, "%s %t", PREFIX, "BSiteChat");
						
					}
				}
			}
		}
	}
}

// Thanks exvel for the GetBombsites function
// https://forums.alliedmods.net/showthread.php?t=136912&highlight=g_BombsiteA

void GetBombsitesIndexes()
{
	int index = -1;
	
	float vecBombsiteCenterA[3];
	float vecBombsiteCenterB[3];
	
	index = FindEntityByClassname(index, "cs_player_manager");
	if (index != -1)
	{
		GetEntPropVector(index, Prop_Send, "m_bombsiteCenterA", vecBombsiteCenterA);
		GetEntPropVector(index, Prop_Send, "m_bombsiteCenterB", vecBombsiteCenterB);
	}
	
	index = -1;
	while ((index = FindEntityByClassname(index, "func_bomb_target")) != -1)
	{
		float vecBombsiteMin[3];
		float vecBombsiteMax[3];
		
		GetEntPropVector(index, Prop_Send, "m_vecMins", vecBombsiteMin);
		GetEntPropVector(index, Prop_Send, "m_vecMaxs", vecBombsiteMax);
		
		if (IsVecBetween(vecBombsiteCenterA, vecBombsiteMin, vecBombsiteMax))
		{
			g_BombsiteA = index;
		}
		if (IsVecBetween(vecBombsiteCenterB, vecBombsiteMin, vecBombsiteMax))
		{
			g_BombsiteB = index;
		}
	}
}

bool IsVecBetween(const float vecVector[3], const float vecMin[3], const float vecMax[3])
{
	return ((vecMin[0] <= vecVector[0] <= vecMax[0]) && 
		(vecMin[1] <= vecVector[1] <= vecMax[1]) && 
		(vecMin[2] <= vecVector[2] <= vecMax[2]));
}

bool IsValidClient(int client, bool botz = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsClientConnected(client) || botz && IsFakeClient(client) || IsClientSourceTV(client))
		return false;
	
	return true;
} 
