stock void Client_AddHealth(int iClient, int iAdditionalHeal, int iMaxOverHeal=0)
{
  int iMaxHealth = SDK_GetMaxHealth(iClient);
  int iHealth = GetEntProp(iClient, Prop_Send, "m_iHealth");
  int iTrueMaxHealth = iMaxHealth+iMaxOverHeal;
  
  float flHealingRate = 1.0;
  TF2_FindAttribute(iClient, ATTRIB_LESSHEALING, flHealingRate);
  
  if (iHealth < iTrueMaxHealth)
  {
    iHealth += RoundToNearest(float(iAdditionalHeal) * flHealingRate);
    if (iHealth > iTrueMaxHealth) iHealth = iTrueMaxHealth;
    SetEntProp(iClient, Prop_Send, "m_iHealth", iHealth);
  }
}

stock bool TF2_FindAttribute(int iEntity, int iAttrib, float &flVal)
{
  Address addAttrib = TF2Attrib_GetByDefIndex(iEntity, iAttrib);
  if (addAttrib != Address_Null)
  {
    flVal = TF2Attrib_GetValue(addAttrib);
    return true;
  }
  return false;
}

stock void CreateFade(int iClient, int iDuration = 2000, int iRed = 255, int iGreen = 255, int iBlue = 255, int iAlpha = 255)
{
  BfWrite bf = UserMessageToBfWrite(StartMessageOne("Fade", iClient));
  bf.WriteShort(iDuration);	//Fade duration
  bf.WriteShort(0);
  bf.WriteShort(0x0001);
  bf.WriteByte(iRed);			//Red
  bf.WriteByte(iGreen);		//Green
  bf.WriteByte(iBlue);		//Blue
  bf.WriteByte(iAlpha);		//Alpha
  EndMessage();
}


stock int TF2_CreateLightEntity(float flRadius, int iColor[4], int iBrightness)
{
  int iGlow = CreateEntityByName("light_dynamic");
  if (iGlow != -1)
  {			
    char sLigthColor[60];
    Format(sLigthColor, sizeof(sLigthColor), "%i %i %i", iColor[0], iColor[1], iColor[2]);
    DispatchKeyValue(iGlow, "rendercolor", sLigthColor);
    
    SetVariantFloat(flRadius);
    AcceptEntityInput(iGlow, "spotlight_radius");
    
    SetVariantFloat(flRadius);
    AcceptEntityInput(iGlow, "distance");
    
    SetVariantInt(iBrightness);
    AcceptEntityInput(iGlow, "brightness");
    
    SetVariantInt(1);
    AcceptEntityInput(iGlow, "cone");
    
    DispatchSpawn(iGlow);
    
    ActivateEntity(iGlow);
    AcceptEntityInput(iGlow, "TurnOn");
    SetEntityRenderFx(iGlow, RENDERFX_SOLID_SLOW);
    SetEntityRenderColor(iGlow, iColor[0], iColor[1], iColor[2], iColor[3]);
    
    int iFlags = GetEdictFlags(iGlow);
    if (!(iFlags & FL_EDICT_ALWAYS))
    {
      iFlags |= FL_EDICT_ALWAYS;
      SetEdictFlags(iGlow, iFlags);
    }
  }
  
  return iGlow;
}


stock int TF2_GetItemInSlot(int iClient, int iSlot)
{
  int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
  if (!IsValidEdict(iWeapon))
  {
    //If weapon not found in slot, check if it a wearable
    int iWearable = SDK_GetEquippedWearable(iClient, iSlot);
    if (IsValidEdict(iWearable))
      iWeapon = iWearable;
  }
  
  return iWeapon;
}

stock int TF2_SpawnParticle(char[] sParticle, float vecOrigin[3] = NULL_VECTOR, float vecAngles[3] = NULL_VECTOR, bool bActivate = true, int iEntity = 0, int iControlPoint = 0, const char[] sAttachment = "", const char[] sAttachmentOffset = "")
{
  int iParticle = CreateEntityByName("info_particle_system");
  TeleportEntity(iParticle, vecOrigin, vecAngles, NULL_VECTOR);
  DispatchKeyValue(iParticle, "effect_name", sParticle);
  DispatchSpawn(iParticle);
  
  if (0 < iEntity && IsValidEntity(iEntity))
  {
    SetVariantString("!activator");
    AcceptEntityInput(iParticle, "SetParent", iEntity);

    if (sAttachment[0])
    {
      SetVariantString(sAttachment);
      AcceptEntityInput(iParticle, "SetParentAttachment", iParticle);
    }
    
    if (sAttachmentOffset[0])
    {
      SetVariantString(sAttachmentOffset);
      AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle);
    }
  }
  
  if (0 < iControlPoint && IsValidEntity(iControlPoint))
  {
    //Array netprop, but really only need element 0 anyway
    SetEntPropEnt(iParticle, Prop_Send, "m_hControlPointEnts", iControlPoint, 0);
    SetEntProp(iParticle, Prop_Send, "m_iControlPointParents", iControlPoint, _, 0);
  }
  
  if (bActivate)
  {
    ActivateEntity(iParticle);
    AcceptEntityInput(iParticle, "Start");
  }
  
  //Return ref of entity
  return EntIndexToEntRef(iParticle);
}

stock bool TraceRay_HitWallOnly(int iEntity, int iMask, int iData)
{
  return false;
}

stock bool StrEmpty(char[] sBuffer)
{
  return sBuffer[0] == '\0';
}

stock void TF2_SetAmmo(int iClient, int iAmmoType, int iAmmo)
{
  SetEntProp(iClient, Prop_Send, "m_iAmmo", iAmmo, _, iAmmoType);
}

stock void TF2_RemoveItemInSlot(int client, int slot)
{
  TF2_RemoveWeaponSlot(client, slot);

  int iWearable = SDK_GetEquippedWearable(client, slot);
  if (iWearable > MaxClients)
  {
    SDK_RemoveWearable(client, iWearable);
    AcceptEntityInput(iWearable, "Kill");
  }
}

stock int TF2_GetAmmo(int iClient, int iAmmoType)
{
  return GetEntProp(iClient, Prop_Send, "m_iAmmo", _, iAmmoType);
}

stock bool TF2_WeaponFindAttribute(int iWeapon, int iAttrib, float &flVal)
{
  Address addAttrib = TF2Attrib_GetByDefIndex(iWeapon, iAttrib);
  if (addAttrib == Address_Null)
  {
    int iItemDefIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
    int iAttributes[16];
    float flAttribValues[16];

    int iMaxAttrib = TF2Attrib_GetStaticAttribs(iItemDefIndex, iAttributes, flAttribValues);
    for (int i = 0; i < iMaxAttrib; i++)
    {
      if (iAttributes[i] == iAttrib)
      {
        flVal = flAttribValues[i];
        return true;
      }
    }
    return false;
  }
  flVal = TF2Attrib_GetValue(addAttrib);
  return true;
}


stock int CreateViewModel(int iClient, int iModel)
{
  int iViewModel = CreateEntityByName("tf_wearable_vm");
  if (iViewModel <= MaxClients)
    return -1;
  
  SetEntProp(iViewModel, Prop_Send, "m_nModelIndex", iModel);
  SetEntProp(iViewModel, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
  SetEntProp(iViewModel, Prop_Send, "m_iTeamNum", GetClientTeam(iClient));
  SetEntProp(iViewModel, Prop_Send, "m_usSolidFlags", 4);
  SetEntProp(iViewModel, Prop_Send, "m_CollisionGroup", 11);
  
  DispatchSpawn(iViewModel);
  SetVariantString("!activator");
  ActivateEntity(iViewModel);
  
  SDK_EquipWearable(iClient, iViewModel);
  return iViewModel;
}


stock int TF2_GetItemSlot(int iIndex, TFClassType nClass)
{
  int iSlot = TF2Econ_GetItemLoadoutSlot(iIndex, nClass);
  if (iSlot >= 0)
  {
    // Econ reports wrong slots for Engineer and Spy
    switch (nClass)
    {
      case TFClass_Engineer:
      {
        switch (iSlot)
        {
          case 4: iSlot = WeaponSlot_BuilderEngie; // Toolbox
          case 5: iSlot = WeaponSlot_PDABuild; // Construction PDA
          case 6: iSlot = WeaponSlot_PDADestroy; // Destruction PDA
        }
      }
      case TFClass_Spy:
      {
        switch (iSlot)
        {
          case 1: iSlot = WeaponSlot_Primary; // Revolver
          case 4: iSlot = WeaponSlot_Secondary; // Sapper
          case 5: iSlot = WeaponSlot_PDADisguise; // Disguise Kit
          case 6: iSlot = WeaponSlot_InvisWatch; // Invis Watch
        }
      }
    }
  }
  
  return iSlot;
}


stock void TF2_SetBuildingTeam(int iBuilding, TFTeam nTeam, int iNewBuilder = -1)
{
  int iBuilder = TF2_GetBuildingOwner(iBuilding);
  
  //Remove the building from the original builder so it doesn't explode on team switch
  SDK_RemoveObject(iBuilder, iBuilding);
  
  //Set its team. If we were attempting to do this by changing its TeamNum ent prop, Sentries would act derpy by actively trying to shoot itself
  int iTeam = view_as<int>(nTeam);
  SetVariantInt(iTeam);
  AcceptEntityInput(iBuilding, "SetTeam");
  SetEntProp(iBuilding, Prop_Send, "m_nSkin", iTeam-2);
  
  //Set a new builder and give them the building, if specified
  TF2_SetBuildingOwner(iBuilding, iNewBuilder);
  
  switch (TF2_GetBuildingType(iBuilding))
  {
    case TFObject_Sentry:
    {
      //Mini-sentries use different skins, adjust accordingly
      if (GetEntProp(iBuilding, Prop_Send, "m_bMiniBuilding"))
        SetEntProp(iBuilding, Prop_Send, "m_nSkin", iTeam);
      
      //Reset wrangler shield and player-controlled status to change team colors
      //If the sentry is still being wrangled, the values will automatically adjust themselves next frame
      if (GetEntProp(iBuilding, Prop_Send, "m_nShieldLevel") > 0)
      {
        SetEntProp(iBuilding, Prop_Send, "m_bPlayerControlled", false);
        SetEntProp(iBuilding, Prop_Send, "m_nShieldLevel", 0);
      }
    }
    case TFObject_Dispenser:
    {
      //Disable the dispenser's screen, it's better than having it not change team color
      int iScreen = MaxClients+1;
      while ((iScreen = FindEntityByClassname(iScreen, "vgui_screen")) > MaxClients)
      {
        if (GetEntPropEnt(iScreen, Prop_Send, "m_hOwnerEntity") == iBuilding)
          AcceptEntityInput(iScreen, "Kill");
      }
    }
    case TFObject_Teleporter:
    {
      //Disable teleporters for a little bit to reset the effects' colors
      TF2_StunBuilding(iBuilding, 0.1);
    }
  }
}

stock int TF2_GetBuilding(int iClient, TFObjectType nType, TFObjectMode nMode = TFObjectMode_None)
{
  int iBuilding = MaxClients+1;
  while ((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) > MaxClients)
  {
    if (TF2_GetBuildingOwner(iBuilding) == iClient
      && TF2_GetBuildingType(iBuilding) == nType
      && TF2_GetBuildingMode(iBuilding) == nMode)
    {
      return iBuilding;
    }
  }
  
  return -1;
}

stock int TF2_GetBuildingOwner(int iBuilding)
{
  //There is the possibility that a map has buildings without ownership
  return GetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder");
}


stock void TF2_SetBuildingOwner(int iBuilding, int iClient)
{
  if (0 < iClient <= MaxClients && IsClientInGame(iClient))
  {
    SetEntPropEnt(iBuilding, Prop_Send, "m_hBuilder", iClient);
    SDK_AddObject(iClient, iBuilding);
  }
}


stock TFObjectType TF2_GetBuildingType(int iBuilding)
{
  if (iBuilding > MaxClients)
    return view_as<TFObjectType>(GetEntProp(iBuilding, Prop_Send, "m_iObjectType"));
    
  return TFObject_Invalid;
}

stock TFObjectMode TF2_GetBuildingMode(int iBuilding)
{
  if (iBuilding > MaxClients)
    return view_as<TFObjectMode>(GetEntProp(iBuilding, Prop_Send, "m_iObjectMode"));
    
  return TFObjectMode_Invalid;
}


stock ArrayList GetValidSummonableClients(bool bAllowBoss = false)
{
  ArrayList aClients = new ArrayList();

  for (int iClient = 1; iClient <= MaxClients; iClient++)
  {
    if (IsClientInGame(iClient)
      && TF2_GetClientTeam(iClient) > TFTeam_Spectator
      && !IsPlayerAlive(iClient)
			&& SaxtonHale_HasPreferences(iClient, VSHPreferences_Revival))
    {
      if (!bAllowBoss)
        if (SaxtonHale_IsValidBoss(iClient, false)) continue;
        
      aClients.Push(iClient);
    }
  }
  
  aClients.Sort(Sort_Random, Sort_Integer);
  
  return aClients;
}


stock void TF2_ForceTeamJoin(int iClient, TFTeam nTeam)
{
  TFClassType nClass = TF2_GetPlayerClass(iClient);
  if (nClass == TFClass_Unknown)
  {
    // Player hasn't chosen a class. Choose one for him.
    TF2_SetPlayerClass(iClient, view_as<TFClassType>(GetRandomInt(1, 9)), true, true);
  }
  
  bool bAlive = IsPlayerAlive(iClient);
  if (bAlive)
    SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Dead);
  
  TF2_ChangeClientTeam(iClient, nTeam);
  
  if (bAlive)
    SetEntProp(iClient, Prop_Send, "m_lifeState", LifeState_Alive);
  
  TF2_RespawnPlayer(iClient);
}


stock void TF2_TeleportToClient(int iClient, int iTarget)
{
  if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
    return;
  if (iTarget <= 0 || iTarget > MaxClients || !IsClientInGame(iTarget) || !IsPlayerAlive(iTarget))
    return;
  
  float vecTargetPos[3], vecTargetAng[3];
  GetClientAbsOrigin(iTarget, vecTargetPos);
  GetClientAbsAngles(iTarget, vecTargetAng);
  vecTargetAng[0] = 0.0;
  vecTargetAng[2] = 0.0;
  
  TeleportEntity(iClient, vecTargetPos, vecTargetAng, NULL_VECTOR);
  
  //Force whoever was teleported to crouch if its target was crouching, to prevent them from getting stuck
  if (GetEntProp(iTarget, Prop_Send, "m_bDucking") || GetEntProp(iTarget, Prop_Send, "m_bDucked"))
  {
    SetEntProp(iClient, Prop_Send, "m_bDucking", true);
    SetEntProp(iClient, Prop_Send, "m_bDucked", true);
    SetEntityFlags(iClient, GetEntityFlags(iClient)|FL_DUCKING);
  }
}


stock int TF2_CreateGlow(int iEnt, int iColor[4])
{
  char oldEntName[64];
  GetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName, sizeof(oldEntName));

  char strName[126], strClass[64];
  GetEntityClassname(iEnt, strClass, sizeof(strClass));
  Format(strName, sizeof(strName), "%s%i", strClass, iEnt);
  DispatchKeyValue(iEnt, "targetname", strName);

  int ent = CreateEntityByName("tf_glow");
  DispatchKeyValue(ent, "targetname", "entity_glow");
  DispatchKeyValue(ent, "target", strName);
  DispatchKeyValue(ent, "Mode", "0");
  DispatchSpawn(ent);

  AcceptEntityInput(ent, "Enable");
  SetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName);

  SetVariantColor(iColor);
  AcceptEntityInput(ent, "SetGlowColor");

  SetVariantString("!activator");
  AcceptEntityInput(ent, "SetParent", iEnt);

  return ent;
}

stock void TF2_ShowAnnotation(int[] iClients, int iCount, int iTarget, const char[] sMessage, float flDuration = 5.0, const char[] sSound = SOUND_NULL)
{
  //Create an annotation and show it to a specified array of clients
  Event event = CreateEvent("show_annotation");
  event.SetInt("id", iTarget);				//Make its ID match the target, just so it's assigned to something unique
  event.SetInt("follow_entindex", iTarget);
  event.SetFloat("lifetime", flDuration);
  event.SetString("text", sMessage);
  event.SetString("play_sound", sSound);		//If this is missing, it'll try to play a sound with an empty filepath
  
  for (int i = 0; i < iCount; i++)
  {
    //No point in showing the annotation to the target
    if (iClients[i] != iTarget)
      event.FireToClient(iClients[i]);
  }
  
  event.Cancel();
}

stock void TF2_ShowAnnotationToAll(int iTarget, const char[] sMessage, float flDuration = 5.0, const char[] sSound = SOUND_NULL)
{
  int[] iClients = new int[MaxClients];
  int iCount = 0;

  for (int iClient = 1; iClient <= MaxClients; iClient++)
  {
    if (IsClientInGame(iClient))
      iClients[iCount++] = iClient;
  }
  
  if (iCount <= 0)
    return;
  
  TF2_ShowAnnotation(iClients, iCount, iTarget, sMessage, flDuration, sSound);
}

stock void TF2_ShowAnnotationToClient(int iClient, int iTarget, const char[] sMessage, float flDuration = 5.0, const char[] sSound = SOUND_NULL)
{
  int iClients[1];
  iClients[0] = iClient;
  
  TF2_ShowAnnotation(iClients, 1, iTarget, sMessage, flDuration, sSound);
}


stock void TF2_Shake(float vecOrigin[3], float flAmplitude, float flRadius, float flDuration, float flFrequency)
{
  int iShake = CreateEntityByName("env_shake");
  if (iShake != -1)
  {
    DispatchKeyValueVector(iShake, "origin", vecOrigin);
    DispatchKeyValueFloat(iShake, "amplitude", flAmplitude);
    DispatchKeyValueFloat(iShake, "radius", flRadius);
    DispatchKeyValueFloat(iShake, "duration", flDuration);
    DispatchKeyValueFloat(iShake, "frequency", flFrequency);
    
    DispatchSpawn(iShake);
    AcceptEntityInput(iShake, "StartShake");
    RemoveEntity(iShake);
  }
}

stock void TF2_Explode(int iAttacker = -1, float flPos[3], float flDamage, float flRadius, const char[] strParticle, const char[] strSound)
{
  int iBomb = CreateEntityByName("tf_generic_bomb");
  DispatchKeyValueVector(iBomb, "origin", flPos);
  DispatchKeyValueFloat(iBomb, "damage", flDamage);
  DispatchKeyValueFloat(iBomb, "radius", flRadius);
  DispatchKeyValue(iBomb, "health", "1");
  DispatchKeyValue(iBomb, "explode_particle", strParticle);
  DispatchKeyValue(iBomb, "sound", strSound);
  DispatchSpawn(iBomb);

  if (iAttacker == -1)
    AcceptEntityInput(iBomb, "Detonate");
  else
    SDKHooks_TakeDamage(iBomb, 0, iAttacker, 9999.0);
}

stock bool TF2_SwitchToWeapon(int iClient, int iWeapon)
{
  char sClassname[256];
  GetEntityClassname(iWeapon, sClassname, sizeof(sClassname));
  FakeClientCommand(iClient, "use %s", sClassname);
  return GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon") == iWeapon;
}

stock void TF2_TeleportSwap(int iClient[2])
{
  float vecOrigin[2][3];
  float vecAngles[2][3];
  float vecVel[2][3];
  
  for (int i = 0; i <= 1; i++)
  {
    // Remove Sniper scope before teleporting, otherwise huge server hang can happen
    if (TF2_IsPlayerInCondition(iClient[i], TFCond_Zoomed)) TF2_RemoveCondition(iClient[i], TFCond_Zoomed);
    if (TF2_IsPlayerInCondition(iClient[i], TFCond_Slowed)) TF2_RemoveCondition(iClient[i], TFCond_Slowed);
    
    // Get its origin, angles and vel
    GetClientAbsOrigin(iClient[i], vecOrigin[i]);
    GetClientAbsAngles(iClient[i], vecAngles[i]);
    GetEntPropVector(iClient[i], Prop_Data, "m_vecVelocity", vecVel[i]);
    
    // Create particle
    CreateTimer(3.0, Timer_EntityCleanup, TF2_SpawnParticle(PARTICLE_GHOST, vecOrigin[i], vecAngles[i]));
    
    // Play a sound
    EmitGameSoundToAll("Halloween.spell_teleport", iClient[i]);
  }

  for (int i = 0; i <= 1; i++)
  {
    int j = ((i == 1) ? 0 : 1);
    
    TeleportEntity(iClient[j], vecOrigin[i], vecAngles[i], vecVel[i]);
    
    if (GetEntProp(iClient[i], Prop_Send, "m_bDucking") || GetEntProp(iClient[i], Prop_Send, "m_bDucked"))
    {
      SetEntProp(iClient[j], Prop_Send, "m_bDucking", true);
      SetEntProp(iClient[j], Prop_Send, "m_bDucked", true);
      SetEntityFlags(iClient[j], GetEntityFlags(iClient[j])|FL_DUCKING);
    }
  }  
}

stock void TF2_StunBuilding(int iBuilding, float flDuration)
{
  SetEntProp(iBuilding, Prop_Send, "m_bDisabled", true);
  CreateTimer(flDuration, Timer_EnableBuilding, EntIndexToEntRef(iBuilding));
}

public Action Timer_EnableBuilding(Handle timer, int iRef)
{
  int iBuilding = EntRefToEntIndex(iRef);
  if (iBuilding > MaxClients)
    SetEntProp(iBuilding, Prop_Send, "m_bDisabled", false);
  
  return Plugin_Continue;
}

stock bool TraceRay_HitEnemyPlayersAndObjects(int iEntity, int iMask, int iClient)
{
  if (0 < iEntity <= MaxClients)
    return GetClientTeam(iEntity) != GetClientTeam(iClient);
  
  char sClassname[256];
  GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
  return StrContains(sClassname, "obj_") == 0 && GetEntProp(iEntity, Prop_Send, "m_iTeamNum") != GetClientTeam(iClient);
}

stock bool IsPointsClear(const float vecPos1[3], const float vecPos2[3])
{
  TR_TraceRayFilter(vecPos1, vecPos2, MASK_PLAYERSOLID, RayType_EndPoint, TraceRay_DontHitPlayersAndObjects);
  return !TR_DidHit();
}


stock bool TraceRay_DontHitEntity(int iEntity, int iMask, int iData)
{
  return iEntity != iData;
}

stock bool TraceRay_DontHitPlayersAndObjects(int iEntity, int iMask, int iData)
{
  if (0 < iEntity <= MaxClients)
    return false;
  
  char sClassname[256];
  GetEntityClassname(iEntity, sClassname, sizeof(sClassname));
  return StrContains(sClassname, "obj_") != 0;
}


stock bool TF2_IsUbercharged(int iClient)
{
  return (TF2_IsPlayerInCondition(iClient, TFCond_Ubercharged) ||
    TF2_IsPlayerInCondition(iClient, TFCond_UberchargedHidden) ||
    TF2_IsPlayerInCondition(iClient, TFCond_UberchargedOnTakeDamage) ||
    TF2_IsPlayerInCondition(iClient, TFCond_UberchargedCanteen));
}

stock bool IsClientInRange(int iClient, float vecOrigin[3], float flRadius)
{
  float vecClientOrigin[3];
  GetClientAbsOrigin(iClient, vecClientOrigin);
  return GetVectorDistance(vecOrigin, vecClientOrigin) <= flRadius;
}


stock void ConstrainDistance(const float vecStart[3], float vecEnd[3], float flDistance, float flMaxDistance)
{
  if (flDistance <= flMaxDistance)
    return;
    
  float flFactor = flMaxDistance / flDistance;
  vecEnd[0] = ((vecEnd[0] - vecStart[0]) * flFactor) + vecStart[0];
  vecEnd[1] = ((vecEnd[1] - vecStart[1]) * flFactor) + vecStart[1];
  vecEnd[2] = ((vecEnd[2] - vecStart[2]) * flFactor) + vecStart[2];
}

stock void SetEntityModelScale(int iEntity, float flScale, int iActivator = -1, int iCaller = -1)
{
	// SetModelScale errors out when using a float instead of a string, so it looks odd
	char sScale[16];
	FloatToString(flScale, sScale, sizeof(sScale));
	
	SetVariantString(sScale);
	AcceptEntityInput(iEntity, "SetModelScale", iActivator, iCaller);
}

stock void DelayNextWeaponAttack(int iWeapon, float flDelay)
{
	float flNextAttack = GetGameTime() + flDelay;
	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", flNextAttack);
	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", flNextAttack);
}


// Helper functions.
stock bool CheckDownload(const char[] file)
{
	if (FileExists(file, true)) {
		AddFileToDownloadsTable(file);
		return true;
	}
	return false;
}

stock void DownloadMaterialList(const char[][] file_list, int size)
{
	char s[PLATFORM_MAX_PATH];
	for(int i; i < size; i++) {
		strcopy(s, sizeof(s), file_list[i]);
		CheckDownload(s);
	}
}

/// For custom models, do NOT omit .MDL extension
stock int PrepareModel(const char[] model_path, bool model_only=false)
{
	char extensions[][] = { ".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy" };
	char model_base[PLATFORM_MAX_PATH];
	char path[PLATFORM_MAX_PATH];
	
	strcopy(model_base, sizeof(model_base), model_path);
	SplitString(model_base, ".mdl", model_base, sizeof(model_base)); /// Kind of redundant, but eh.
	if( !model_only ) {
		for( int i; i<sizeof(extensions); i++ ) {
			Format(path, PLATFORM_MAX_PATH, "%s%s", model_base, extensions[i]);
			CheckDownload(path);
		}
	} else {
		CheckDownload(model_path);
	}
	return PrecacheModel(model_path, true);
}


stock void PrepareSound(const char[] sSoundPath)
{
  PrecacheSound(sSoundPath, true);
  char s[PLATFORM_MAX_PATH];
  Format(s, sizeof(s), "sound/%s", sSoundPath);
  AddFileToDownloadsTable(s);
}

stock void PrepareMusic(const char[] sSoundPath, bool bCustom = true)
{
  // Prefix the filepath with #, so it's considered as music by the engine, allowing people to adjust its volume through the music volume slider
  char s[PLATFORM_MAX_PATH];
  FormatEx(s, sizeof(s), "#%s", sSoundPath);
  PrecacheSound(s, true);
  
  if (!bCustom)
    return;
  
  if (ReplaceString(s, sizeof(s), "#", "sound/") != 1)
  {
    LogError("PrepareMusic could not prepare %s: filepath must not have any '#' characters.", sSoundPath);
    return;
  }
  
  AddFileToDownloadsTable(s);
}

stock int PrecacheParticleSystem(const char[] particleSystem)
{
  static int particleEffectNames = INVALID_STRING_TABLE;
  if (particleEffectNames == INVALID_STRING_TABLE)
  {
    if ((particleEffectNames = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE)
    {
      return INVALID_STRING_INDEX;
    }
  }

  int index = FindStringIndex2(particleEffectNames, particleSystem);
  if (index == INVALID_STRING_INDEX)
  {
    int numStrings = GetStringTableNumStrings(particleEffectNames);
    if (numStrings >= GetStringTableMaxStrings(particleEffectNames))
    {
      return INVALID_STRING_INDEX;
    }

    AddToStringTable(particleEffectNames, particleSystem);
    index = numStrings;
  }

  return index;
}

stock int FindStringIndex2(int tableidx, const char[] str)
{
  char buf[1024];
  int numStrings = GetStringTableNumStrings(tableidx);
  for (int i = 0; i < numStrings; i++)
  {
    ReadStringTable(tableidx, i, buf, sizeof(buf));
    if (StrEqual(buf, str))
    {
      return i;
    }
  }

  return INVALID_STRING_INDEX;
}