/**
 * Map vetoing functions
 */

#define CONFIRM_NEGATIVE_VALUE "_"

public void CreateVeto() {
  switch (MaxMapsToPlay(g_MapsToWin))
  {
    case 7:
    {
        VetoAction tmp_VetoActions[] = {Ban, Ban, Ban, Ban, Ban, Ban};
        MatchTeam tmp_VetoOrderTeams[] = {MatchTeam_Team1, MatchTeam_Team2, MatchTeam_Team1, MatchTeam_Team2, MatchTeam_Team1, MatchTeam_Team2};
        g_VetoActions = tmp_VetoActions;
        g_VetoOrderTeams = tmp_VetoOrderTeams;
    }
    case 5:
    {
        VetoAction tmp_VetoActions[] = {Ban, Ban, Ban, Ban, Ban, Ban};
        MatchTeam tmp_VetoOrderTeams[] = {MatchTeam_Team1, MatchTeam_Team2, MatchTeam_Team2, MatchTeam_Team1, MatchTeam_Team2, MatchTeam_Team1};
        g_VetoActions = tmp_VetoActions;
        g_VetoOrderTeams = tmp_VetoOrderTeams;
    }
    case 3:
    {
        VetoAction tmp_VetoActions[] = {Ban, Ban, Pick, Pick, Ban, Ban};
        MatchTeam tmp_VetoOrderTeams[] = {MatchTeam_Team1, MatchTeam_Team2, MatchTeam_Team1, MatchTeam_Team2, MatchTeam_Team1, MatchTeam_Team2};
        g_VetoActions = tmp_VetoActions;
        g_VetoOrderTeams = tmp_VetoOrderTeams;
    }
    case 2:
    {
        VetoAction tmp_VetoActions[] = {Ban, Ban, Ban, Ban, Pick, Pick};
        MatchTeam tmp_VetoOrderTeams[] = {MatchTeam_Team1, MatchTeam_Team2, MatchTeam_Team2, MatchTeam_Team1, MatchTeam_Team2, MatchTeam_Team1};
        g_VetoActions = tmp_VetoActions;
        g_VetoOrderTeams = tmp_VetoOrderTeams;
    }
    case 1:
    {
        VetoAction tmp_VetoActions[] = {Ban, Ban, Ban, Ban, Ban, Ban};
        MatchTeam tmp_VetoOrderTeams[] = {MatchTeam_Team1, MatchTeam_Team2, MatchTeam_Team1, MatchTeam_Team2, MatchTeam_Team1, MatchTeam_Team2};
        g_VetoActions = tmp_VetoActions;
        g_VetoOrderTeams = tmp_VetoOrderTeams;
    }
  }
  
  if (g_MapPoolList.Length % 2 == 0) {
    LogError(
        "Warning, the maplist is even number sized (%d maps), vetos may not function correctly!",
        g_MapPoolList.Length);
  }

  g_VetoCaptains[MatchTeam_Team1] = GetTeamCaptain(MatchTeam_Team1);
  g_VetoCaptains[MatchTeam_Team2] = GetTeamCaptain(MatchTeam_Team2);
  ResetReadyStatus();
  CreateTimer(1.0, Timer_VetoCountdown, _, TIMER_REPEAT);
}

public Action Timer_VetoCountdown(Handle timer) {
  static int warningsPrinted = 0;
  if (warningsPrinted >= g_VetoCountdownCvar.IntValue) {
    warningsPrinted = 0;
    VetoController();
    return Plugin_Stop;
  } else {
    warningsPrinted++;
    int secondsRemaining = g_VetoCountdownCvar.IntValue - warningsPrinted + 1;
    Get5_MessageToAll("%t", "VetoCountdown", secondsRemaining);
    return Plugin_Continue;
  }
}

static void AbortVeto() {
  Get5_MessageToAll("%t", "CaptainLeftOnVetoInfoMessage");
  Get5_MessageToAll("%t", "ReadyToResumeVetoInfoMessage");
  ChangeState(Get5State_PreVeto);
}

public void VetoFinished() {
  ChangeState(Get5State_Warmup);
  Get5_MessageToAll("%t", "MapDecidedInfoMessage");

  // Use total series score as starting point, to not print skipped maps
  int seriesScore = g_TeamSeriesScores[MatchTeam_Team1] + g_TeamSeriesScores[MatchTeam_Team2];
  for (int i = seriesScore; i < g_MapsToPlay.Length; i++) {
    char map[PLATFORM_MAX_PATH];
    g_MapsToPlay.GetString(i, map, sizeof(map));
    Get5_MessageToAll("%t", "MapIsInfoMessage", i + 1 - seriesScore, map);
  }

  g_MapChangePending = true;
  CreateTimer(10.0, Timer_NextMatchMap);
}

// Main Veto Controller
public void VetoController() {
  //pick side for last picked map
  if ( g_MapSides.Length < g_MapsToPlay.Length){
    int choosing_captain = GetNextTeamCaptain(g_VetoCaptains[g_LastVetoTeam]);

    if (g_MatchSideType == MatchSideType_Standard) {
      if(! g_BO2Match && g_MapsLeftInVetoPool.Length == 1){
        g_MapSides.Push(SideChoice_KnifeRound);
        VetoController();
      }else{
        GiveSidePickMenu(choosing_captain);
      }
    } else if (g_MatchSideType == MatchSideType_AlwaysKnife) {
      g_MapSides.Push(SideChoice_KnifeRound);
      VetoController();
    } else if (g_MatchSideType == MatchSideType_NeverKnife) {
      g_MapSides.Push(SideChoice_Team1CT);
      VetoController();
    }
  }else{
    int maxMaps = MaxMapsToPlay(g_MapsToWin);
    int seriesScore = g_TeamSeriesScores[MatchTeam_Team1] + g_TeamSeriesScores[MatchTeam_Team2];
    
    //all required picks were made we can end the veto even if maps are left in the pool
    if (g_MapsToPlay.Length >= maxMaps-seriesScore){
      //add maps to the front of the maplist to be skipped by the seriesScore
      if (seriesScore > 0){
        char mapName[PLATFORM_MAX_PATH];
        for (int i = 0; i < seriesScore; i++) {
          // Get the next map in the veto pool
          g_MapsLeftInVetoPool.GetString(0, mapName, sizeof(mapName));
          g_MapsLeftInVetoPool.Erase(0);

          // Add it to the front of the active maplist
          g_MapsToPlay.ShiftUp(0);
          g_MapsToPlay.SetString(0, mapName);

          // Add a side type to map sides too, so the sides don't come out of order
          g_MapSides.ShiftUp(0);
          g_MapSides.Set(0, SideChoice_KnifeRound);
        }
      }
      VetoFinished();
    // The remaining maps in the pool are played and thus added to the maplist
    }else if (g_MapsLeftInVetoPool.Length == maxMaps-seriesScore-g_MapsToPlay.Length){
      char mapName[PLATFORM_MAX_PATH];
      
      g_MapsLeftInVetoPool.GetString(0, mapName, sizeof(mapName));
      g_MapsLeftInVetoPool.Erase(0);
      g_MapsToPlay.PushString(mapName);

      //in a bo2 if there was a pick before the last action then the last map side has to be picked
      if(! (g_BO2Match && g_VetoActions[g_CurrentVetoRound-1] == Pick)){
        if (g_MatchSideType == MatchSideType_Standard) {
          g_MapSides.Push(SideChoice_KnifeRound);
        } else if (g_MatchSideType == MatchSideType_AlwaysKnife) {
          g_MapSides.Push(SideChoice_KnifeRound);
        } else if (g_MatchSideType == MatchSideType_NeverKnife) {
          g_MapSides.Push(SideChoice_Team1CT);
        }
      }
      EventLogger_MapPicked(MatchTeam_TeamNone, mapName, g_MapsToPlay.Length - 1);

      LogDebug("Calling Get5_OnMapPicked(team=%d, map=%s)", MatchTeam_TeamNone, mapName);
      Call_StartForward(g_OnMapPicked);
      Call_PushCell(MatchTeam_TeamNone);
      Call_PushString(mapName);
      Call_Finish();

      VetoController();

    }else{
      int current_captain = g_VetoCaptains[g_VetoOrderTeams[g_CurrentVetoRound]];
      if (!IsPlayer(current_captain) || GetClientMatchTeam(current_captain) == MatchTeam_TeamSpec) {
        AbortVeto();
      }

      //Pick
      if ( g_VetoActions[g_CurrentVetoRound] == Pick){
        g_CurrentVetoRound++;
        GiveMapPickMenu(current_captain);
      //Ban
      }else if (g_VetoActions[g_CurrentVetoRound] == Ban){
        g_CurrentVetoRound++;
        GiveMapVetoMenu(current_captain);
      }
    }
  }
}

// Confirmations

public void GiveConfirmationMenu(int client, MenuHandler handler, const char[] title,
                          const char[] confirmChoice) {
  // Figure out text for positive and negative values
  char positiveBuffer[1024], negativeBuffer[1024];
  Format(positiveBuffer, sizeof(positiveBuffer), "%T", "ConfirmPositiveOptionText", client);
  Format(negativeBuffer, sizeof(negativeBuffer), "%T", "ConfirmNegativeOptionText", client);

  // Create menu
  Menu menu = new Menu(handler);
  menu.SetTitle("%T", title, client, confirmChoice);
  menu.ExitButton = false;
  menu.Pagination = MENU_NO_PAGINATION;

  // Add rows of padding to move selection out of "danger zone"
  for (int i = 0; i < 7; i++) {
    menu.AddItem(CONFIRM_NEGATIVE_VALUE, "", ITEMDRAW_NOTEXT);
  }

  // Add actual choices
  menu.AddItem(confirmChoice, positiveBuffer);
  menu.AddItem(CONFIRM_NEGATIVE_VALUE, negativeBuffer);

  // Show menu and disable confirmations
  g_ActiveVetoMenu = menu;
  menu.Display(client, MENU_TIME_FOREVER);
  SetConfirmationTime(false);
}

static void SetConfirmationTime(bool enabled) {
  if (enabled) {
    g_VetoMenuTime = GetTickedTime();
  } else {
    // Set below 0 to signal that we don't want confirmation
    g_VetoMenuTime = -1.0;
  }
}

static bool ConfirmationNeeded() {
  // Don't give confirmations if it's been disabled
  if (g_VetoConfirmationTimeCvar.FloatValue <= 0.0) {
    return false;
  }
  // Don't give confirmation if the veto time is less than 0
  // (in case we're presenting a menu that doesn't need confirmation)
  if (g_VetoMenuTime < 0.0) {
    return false;
  }

  float diff = GetTickedTime() - g_VetoMenuTime;
  return diff <= g_VetoConfirmationTimeCvar.FloatValue;
}

static bool ConfirmationNegative(const char[] choice) {
  return StrEqual(choice, CONFIRM_NEGATIVE_VALUE);
}

// Map Vetos

public void GiveMapVetoMenu(int client) {
  Menu menu = new Menu(MapVetoMenuHandler);
  menu.SetTitle("%T", "MapVetoBanMenuText", client);
  menu.ExitButton = false;
  // Don't paginate the menu if we have 7 maps or less, as they will fit
  // on one page when we don't add the pagination options
  if (g_MapsLeftInVetoPool.Length <= 7) {
    menu.Pagination = MENU_NO_PAGINATION;
  }

  char mapName[PLATFORM_MAX_PATH];
  for (int i = 0; i < g_MapsLeftInVetoPool.Length; i++) {
    g_MapsLeftInVetoPool.GetString(i, mapName, sizeof(mapName));
    menu.AddItem(mapName, mapName);
  }
  g_ActiveVetoMenu = menu;
  menu.Display(client, MENU_TIME_FOREVER);
  SetConfirmationTime(true);
}

public int MapVetoMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
  if (action == MenuAction_Select) {
    int client = param1;
    MatchTeam team = GetClientMatchTeam(client);
    char mapName[PLATFORM_MAX_PATH];
    menu.GetItem(param2, mapName, sizeof(mapName));

    // Go back if we were called from a confirmation menu and client selected no
    if (ConfirmationNegative(mapName)) {
      GiveMapVetoMenu(client);
      return;
    }
    // Show a confirmation menu if needed
    if (ConfirmationNeeded()) {
      GiveConfirmationMenu(client, MapVetoMenuHandler, "MapVetoBanConfirmMenuText", mapName);
      return;
    }

    RemoveStringFromArray(g_MapsLeftInVetoPool, mapName);

    Get5_MessageToAll("%t", "TeamVetoedMapInfoMessage", g_FormattedTeamNames[team], mapName);

    EventLogger_MapVetoed(team, mapName);

    LogDebug("Calling Get5_OnMapVetoed(team=%d, map=%s)", team, mapName);
    Call_StartForward(g_OnMapVetoed);
    Call_PushCell(team);
    Call_PushString(mapName);
    Call_Finish();

    g_LastVetoTeam = team;
    VetoController();

  } else if (action == MenuAction_Cancel) {
    if (g_GameState == Get5State_Veto) {
      AbortVeto();
    }

  } else if (action == MenuAction_End) {
    delete menu;
  }
}

// Map Picks

public void GiveMapPickMenu(int client) {
  Menu menu = new Menu(MapPickMenuHandler);
  menu.SetTitle("%T", "MapVetoPickMenuText", client);
  menu.ExitButton = false;
  // Don't paginate the menu if we have 7 maps or less, as they will fit
  // on one page when we don't add the pagination options
  if (g_MapsLeftInVetoPool.Length <= 7) {
    menu.Pagination = MENU_NO_PAGINATION;
  }

  char mapName[PLATFORM_MAX_PATH];
  for (int i = 0; i < g_MapsLeftInVetoPool.Length; i++) {
    g_MapsLeftInVetoPool.GetString(i, mapName, sizeof(mapName));
    menu.AddItem(mapName, mapName);
  }
  g_ActiveVetoMenu = menu;
  menu.Display(client, MENU_TIME_FOREVER);
  SetConfirmationTime(true);
}

public int MapPickMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
  if (action == MenuAction_Select) {
    int client = param1;
    MatchTeam team = GetClientMatchTeam(client);
    char mapName[PLATFORM_MAX_PATH];
    menu.GetItem(param2, mapName, sizeof(mapName));

    // Go back if we were called from a confirmation menu and client selected no
    if (ConfirmationNegative(mapName)) {
      GiveMapPickMenu(client);
      return;
    }
    // Show a confirmation menu if needed
    if (ConfirmationNeeded()) {
      GiveConfirmationMenu(client, MapPickMenuHandler, "MapVetoPickConfirmMenuText", mapName);
      return;
    }

    g_MapsToPlay.PushString(mapName);
    RemoveStringFromArray(g_MapsLeftInVetoPool, mapName);

    Get5_MessageToAll("%t", "TeamPickedMapInfoMessage", g_FormattedTeamNames[team], mapName,
                      g_MapsToPlay.Length);
    

    EventLogger_MapPicked(team, mapName, g_MapsToPlay.Length - 1);

    LogDebug("Calling Get5_OnMapPicked(team=%d, map=%s)", team, mapName);
    Call_StartForward(g_OnMapPicked);
    Call_PushCell(team);
    Call_PushString(mapName);
    Call_Finish();
    
    g_LastVetoTeam = team;
    VetoController();

  } else if (action == MenuAction_Cancel) {
    if (g_GameState == Get5State_Veto) {
      AbortVeto();
    }

  } else if (action == MenuAction_End) {
    delete menu;
  }
}

// Side Picks

public void GiveSidePickMenu(int client) {
  Menu menu = new Menu(SidePickMenuHandler);
  menu.ExitButton = false;
  char mapName[PLATFORM_MAX_PATH];
  g_MapsToPlay.GetString(g_MapsToPlay.Length - 1, mapName, sizeof(mapName));
  menu.SetTitle("%T", "MapVetoSidePickMenuText", client, mapName);
  menu.AddItem("CT", "CT");
  menu.AddItem("T", "T");
  g_ActiveVetoMenu = menu;
  menu.Display(client, MENU_TIME_FOREVER);
  SetConfirmationTime(true);
}

public int SidePickMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
  if (action == MenuAction_Select) {
    int client = param1;
    MatchTeam team = GetClientMatchTeam(client);
    char choice[PLATFORM_MAX_PATH];
    menu.GetItem(param2, choice, sizeof(choice));

    // Go back if we were called from a confirmation menu and client selected no
    if (ConfirmationNegative(choice)) {
      GiveSidePickMenu(client);
      return;
    }
    // Show a confirmation menu if needed
    if (ConfirmationNeeded()) {
      GiveConfirmationMenu(client, SidePickMenuHandler, "MapVetoSidePickConfirmMenuText", choice);
      return;
    }

    int selectedSide;
    if (StrEqual(choice, "CT")) {
      selectedSide = CS_TEAM_CT;
      if (team == MatchTeam_Team1)
        g_MapSides.Push(SideChoice_Team1CT);
      else
        g_MapSides.Push(SideChoice_Team1T);
    } else {
      selectedSide = CS_TEAM_T;
      if (team == MatchTeam_Team1)
        g_MapSides.Push(SideChoice_Team1T);
      else
        g_MapSides.Push(SideChoice_Team1CT);
    }

    char mapName[PLATFORM_MAX_PATH];
    g_MapsToPlay.GetString(g_MapsToPlay.Length - 1, mapName, sizeof(mapName));

    Get5_MessageToAll("%t", "TeamSelectSideInfoMessage", g_FormattedTeamNames[team], choice,
                      mapName);

    EventLogger_SidePicked(team, mapName, g_MapsToPlay.Length - 1, selectedSide);

    LogDebug("Calling Get5_OnSidePicked(team=%d, map=%s, side=%d)", team, mapName, selectedSide);
    Call_StartForward(g_OnSidePicked);
    Call_PushCell(team);
    Call_PushString(mapName);
    Call_PushCell(selectedSide);
    Call_Finish();

    VetoController();

  } else if (action == MenuAction_Cancel) {
    if (g_GameState == Get5State_Veto) {
      AbortVeto();
    }

  } else if (action == MenuAction_End) {
    delete menu;
  }
}