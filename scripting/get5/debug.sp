// TODO: Also try to write the original match config file.
// Also consider the last K lines from the most recent errors_* file?

public Action Command_DebugInfo(int client, int args) {
  char path[PLATFORM_MAX_PATH + 1];

  if (args == 0 || !GetCmdArg(1, path, sizeof(path))) {
    BuildPath(Path_SM, path, sizeof(path), "logs/get5_debuginfo.txt");
  }

  File f = OpenFile(path, "w");
  if (f == null) {
    LogError("Failed to open get5_debug.txt for writing");
    return Plugin_Handled;
  }

  AddVersionInfo(f);
  AddSpacing(f);
  AddGlobalStateInfo(f);
  AddSpacing(f);
  AddInterestingCvars(f);
  AddSpacing(f);
  AddLogLines(f, "errors_", 50);
  AddSpacing(f);
  AddLogLines(f, "get5_debug", 200);

  delete f;

  ReplyToCommand(client, "Wrote debug data to %s", path);
  return Plugin_Handled;
}

// Helper functions.

static void AddSpacing(File f) {
  for (int i = 0; i < 3; i++) {
    f.WriteLine("");
  }
}

static void WriteCvarString(File f, const char[] cvar) {
  char buffer[128];
  if (GetConVarStringSafe(cvar, buffer, sizeof(buffer))) {
    f.WriteLine("%s = %s", cvar, buffer);
  } else {
    f.WriteLine("%s = NULL CVAR", cvar);
  }
}

static void WriteArrayList(File f, const char[] name, ArrayList list) {
  if (list == null) {
    f.WriteLine("%s = null", name);
    return;
  }

  f.WriteLine("%s (length %d) = ", name, list.Length);
  char buffer[256];
  for (int i = 0; i < list.Length; i++) {
    list.GetString(i, buffer, sizeof(buffer));
    f.WriteLine("  [%d] -> %s", i, buffer);
  }
}

// Actual debug info.

static void AddVersionInfo(File f) {
  char time[128];
  FormatTime(time, sizeof(time), NULL_STRING, GetTime());
  f.WriteLine("Time: %s", time);
  f.WriteLine("Plugin version: %s", PLUGIN_VERSION);
  WriteCvarString(f, "sourcemod_version");
  WriteCvarString(f, "metamod_version");
}

static void AddGlobalStateInfo(File f) {
  f.WriteLine("Global state:");
  char buffer[256];
  GameStateString(g_GameState, buffer, sizeof(buffer));
  f.WriteLine("g_GameState = %d (%s)", g_GameState, buffer);

  f.WriteLine("g_MatchID = %s", g_MatchID);
  f.WriteLine("g_MapsToWin = %d", g_MapsToWin);
  f.WriteLine("g_BO2Match = %d", g_BO2Match);
  f.WriteLine("g_LastVetoTeam = %d", g_LastVetoTeam);
  WriteArrayList(f, "g_MapPoolList", g_MapPoolList);
  WriteArrayList(f, "g_MapsToPlay", g_MapsToPlay);
  WriteArrayList(f, "g_MapsLeftInVetoPool", g_MapsLeftInVetoPool);
  // TODO: write g_MapSides (it's not a string so WriteArrayList doesn't work).

  f.WriteLine("g_MatchTitle = %s", g_MatchTitle);
  f.WriteLine("g_PlayersPerTeam = %d", g_PlayersPerTeam);
  f.WriteLine("g_MinPlayersToReady = %d", g_MinPlayersToReady);
  f.WriteLine("g_MinSpectatorsToReady = %d", g_MinSpectatorsToReady);
  f.WriteLine("g_SkipVeto = %d", g_SkipVeto);
  f.WriteLine("g_MatchSideType = %d", g_MatchSideType);
  f.WriteLine("g_InScrimMode = %d", g_InScrimMode);
  f.WriteLine("g_HasKnifeRoundStarted = %d", g_HasKnifeRoundStarted);

  f.WriteLine("g_MapChangePending = %d", g_MapChangePending);
  f.WriteLine("g_PendingSideSwap = %d", g_PendingSideSwap);
  f.WriteLine("g_WaitingForRoundBackup = %d", g_WaitingForRoundBackup);
  f.WriteLine("g_SavedValveBackup = %d", g_SavedValveBackup);
  f.WriteLine("g_DoingBackupRestoreNow = %d", g_DoingBackupRestoreNow);

  LOOP_TEAMS(team) {
    GetTeamString(team, buffer, sizeof(buffer));
    f.WriteLine("Team info for team %s (%d):", buffer, team);
    f.WriteLine("g_TeamNames = %s", g_TeamNames[team]);
    WriteArrayList(f, "g_TeamAuths", g_TeamAuths[team]);
    f.WriteLine("g_TeamTags = %s", g_TeamTags[team]);
    f.WriteLine("g_FormattedTeamNames = %s", g_FormattedTeamNames[team]);
    f.WriteLine("g_TeamFlags = %s", g_TeamFlags[team]);
    f.WriteLine("g_TeamLogos = %s", g_TeamLogos[team]);
    f.WriteLine("g_TeamMatchTexts = %s", g_TeamMatchTexts[team]);

    CSTeamString(g_TeamSide[team], buffer, sizeof(buffer));
    f.WriteLine("g_TeamSide = %s (%d)", buffer, g_TeamSide[team]);
    f.WriteLine("g_TeamSeriesScores = %d", g_TeamSeriesScores[team]);
    f.WriteLine("g_TeamReadyOverride = %d", g_TeamReadyOverride[team]);
    f.WriteLine("g_TeamStartingSide = %d", g_TeamStartingSide[team]);
    f.WriteLine("g_TeamPauseTimeUsed = %d", g_TeamPauseTimeUsed[team]);
    f.WriteLine("g_TeamPausesUsed = %d", g_TeamPausesUsed[team]);
    f.WriteLine("g_ReadyTimeWaitingUsed = %d", g_ReadyTimeWaitingUsed[team]);
  }
}

static void AddInterestingCvars(File f) {
  f.WriteLine("Interesting cvars:");
  WriteCvarString(f, "get5_autoload_config");
  WriteCvarString(f, "get5_check_auths");
  WriteCvarString(f, "get5_fixed_pause_time");
  WriteCvarString(f, "get5_kick_when_no_match_loaded");
  WriteCvarString(f, "get5_live_cfg");
  WriteCvarString(f, "get5_max_pause_time");
  WriteCvarString(f, "get5_max_pauses");
  WriteCvarString(f, "get5_pausing_enabled");
  WriteCvarString(f, "get5_reset_pauses_each_half");
  WriteCvarString(f, "mp_freezetime");
  WriteCvarString(f, "mp_halftime");
  WriteCvarString(f, "mp_halftime_duration");
  WriteCvarString(f, "mp_halftime_pausetimer");
  WriteCvarString(f, "mp_match_end_restart");
  WriteCvarString(f, "mp_maxrounds");
  WriteCvarString(f, "mp_maxrounds");
  WriteCvarString(f, "mp_overtime_enable");
  WriteCvarString(f, "mp_overtime_halftime_pausetimer");
  WriteCvarString(f, "mp_overtime_maxrounds");
  WriteCvarString(f, "mp_round_restart_delay");
  WriteCvarString(f, "mp_timelimit");
  WriteCvarString(f, "mp_warmup_pausetimer");
  WriteCvarString(f, "mp_warmuptime_all_players_connected");
  WriteCvarString(f, "sv_coaching_enabled");
  WriteCvarString(f, "tv_delay");
  WriteCvarString(f, "tv_enable");

}

static void AddLogLines(File f, const char[] pattern, int maxLines) {
  char logsDir[PLATFORM_MAX_PATH];
  BuildPath(Path_SM, logsDir, sizeof(logsDir), "logs");
  DirectoryListing dir = OpenDirectory(logsDir);
  if (dir == null) {
    f.WriteLine("Can't open logs dir at %s", logsDir);
    return;
  }

  char filename[PLATFORM_MAX_PATH];
  FileType type;
  ArrayList logFilenames = new ArrayList(sizeof(filename));
  while (dir.GetNext(filename, sizeof(filename), type)) {
    if (type == FileType_File && StrContains(filename, pattern) >= 0) {
      char fullPath[PLATFORM_MAX_PATH];
      Format(fullPath, sizeof(fullPath), "%s/%s", logsDir, filename);
      logFilenames.PushString(fullPath);
    }
  }
  SortADTArray(logFilenames, Sort_Descending, Sort_String);
  if (logFilenames.Length > 0) {
    logFilenames.GetString(0, filename, sizeof(filename));
    File logFile = OpenFile(filename, "r");
    if (logFile != null) {
      f.WriteLine("Last log info from %s:", filename);
      int maxLineLength = 1024;
      ArrayList lines = new ArrayList(maxLineLength);
      char[] line = new char[maxLineLength];
      while (logFile.ReadLine(line, maxLineLength)) {
        lines.PushString(line);
      }

      for (int i = 0; i < maxLines; i++) {
        int idx = lines.Length - 1 - i;
        if (idx < 0 || idx >= lines.Length) {
          break;
        }
        lines.GetString(idx, line, maxLineLength);
        f.WriteString(line, true);
      }

      delete logFile;
    } else {
      f.WriteLine("Couldn't read log file %s", filename);
    }
  }

  delete dir;
}