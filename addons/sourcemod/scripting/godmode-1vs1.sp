#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#define PLUGIN_VERSION "1.1"
#define LIMIT   2
#define RED 2
#define BLUE 3

// ConVar 
ConVar cvar_godmodeEnabled = null;

// Variables 
bool b_1v1Enabled = false;

public Plugin myinfo = {
    name        = "[TF2] Godmode 1vs1",
    author        = "Walgrim",
    description = "Enable godmode in 1vs1",
    version        = PLUGIN_VERSION,
    url            = "http://steamcommunity.com/id/walgrim/"
};

public void OnPluginStart() {
    // ConVars
    CreateConVar("tf2_godmode1vs1_version", PLUGIN_VERSION, "Godmode 1vs1 Version", FCVAR_SPONLY | FCVAR_UNLOGGED | FCVAR_DONTRECORD | FCVAR_REPLICATED | FCVAR_NOTIFY);
    cvar_godmodeEnabled = CreateConVar("tf2_godmode1vs1", "1", "Enable godmode 1vs1 on the server ?", _, true, 0.0, true, 1.0);
    for (int i = 1; i <= MaxClients; i++) {
        if (!IsThisAClient(i)) continue;
        SDKHook(i, SDKHook_OnTakeDamage, OnDamage);
    }
    // Hook Events
    if (cvar_godmodeEnabled.BoolValue) {
        HookEvent("player_team", OnChangeTeam, EventHookMode_PostNoCopy);
        HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
    }
    AutoExecConfig(true, "tf2_godmode1vs1");
}

/**
 * Hook player damage.
 */
public void OnClientPutInServer(int client) {
    if (cvar_godmodeEnabled.BoolValue && IsThisAClient(client)) {
        SDKHook(client, SDKHook_OnTakeDamage, OnDamage);
    }
}

/**
 * Check conditions.
 */
public void OnChangeTeam(Event event, const char[] name, bool dontBroadcast) {
    // 1 frame delay
    RequestFrame(DelayCheck);
}

/**
 * Check conditions.
 */
public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
    CheckGodmodeStatus();
}

public void OnClientDisconnect(int client) {
    CheckGodmodeStatus();
}

void DelayCheck() {
    CheckGodmodeStatus();
}

/**
 * Hook player damage.
 */
public Action OnDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3]) {
    if (!b_1v1Enabled || !IsThisAClient(victim)) {
        return Plugin_Continue;
    }
    damage = 0.0;
    SimulateDeath(victim, inflictor);
    return Plugin_Changed;
}

/**
 * Simulates death to call "on explode".
 * @param victim Victim id.
 * @param inflictor Entity id. 
 * @return void
 */
static void SimulateDeath(int victim, int inflictor) {    
    Event event = CreateEvent("player_death");
    if (event == null) {
        return;
    }
    event.SetInt("userid", GetClientUserId(victim));
    event.SetInt("inflictor_entindex", inflictor);
    event.Fire(true);
}

/**
 * 
 */
void CheckGodmodeStatus() {
    if (!cvar_godmodeEnabled.BoolValue) {
        return;
    }
    int players = GetTeamClientCount(RED) + GetTeamClientCount(BLUE);
    b_1v1Enabled = (players != LIMIT) ? false : true;
}

/* Stocks */

static stock bool IsThisAClient(int entity) {
    return (0 < entity <= MaxClients && IsClientInGame(entity));
}
