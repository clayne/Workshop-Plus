; ---------------------------------------------
; WorkshopPlus:MainQuest.psc - by kinggath
; ---------------------------------------------
; Reusage Rights ------------------------------
; You are free to use this script or portions of it in your own mods, provided you give me credit in your description and maintain this section of comments in any released source code (which includes the IMPORTED SCRIPT CREDIT section to give credit to anyone in the associated Import scripts below.
; 
; Warning !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Do not directly recompile this script for redistribution without first renaming it to avoid compatibility issues issues with the mod this came from.
; 
; IMPORTED SCRIPT CREDIT
; N/A
; ---------------------------------------------

Scriptname WorkshopPlus:MainQuest extends WorkshopFramework:Library:MasterQuest
{ Primarily using this for the FrameworkStartQuests so we aren't launching all of our quests immediately }

import WorkshopFramework:Library:UtilityFunctions

; ---------------------------------------------
; Consts
; ---------------------------------------------

Float fFallDamagePreventionTime = 10.0 Const
Float fFrozenTimeScale = 0.1 Const
Float fDefaultTimeScale = 20.0 Const

Int DelayedFallDamageTimerID = 100 Const
Int WorkshopModeAutoSaveTimerID = 101 Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopParentScript Property WorkshopParent Auto Const Mandatory
EndGroup

Group Assets
	Race Property FloatingRace Auto Const Mandatory
	Race Property HumanRace Auto Const Mandatory
	Spell Property InvisibilitySpell Auto Const Mandatory
	Spell[] Property SpeedSpells Auto Const
	Perk Property UndetectablePerk Auto Const Mandatory
	Perk Property ModFallingDamage Auto Const Mandatory
	{ Autofill }
	Form Property XMarkerForm Auto Const Mandatory
	MagicEffect Property ArmorFallingEffect Auto Const Mandatory
	GlobalVariable Property TimeScale Auto Const Mandatory
	Spell Property BoostCarryWeightSpell Auto Const Mandatory
	Spell Property FreezeTimeSpell Auto Const Mandatory
	Keyword Property JetpackKeyword Auto Const Mandatory
EndGroup

Group ActorValues
	ActorValue Property FallingDamageMod Auto Const Mandatory
	{ Autofill }
EndGroup

Group Messages
	Message Property MustBeInWorkshopModeToUseHotkeys Auto Const Mandatory
	Message Property CouldNotAutoSave Auto Const Mandatory
EndGroup

Group Settings
	GlobalVariable Property Setting_PreventFallDamageInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_MoveSpeedInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_FlyInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_InvisibleInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_InvulnerableInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_AutoSaveTimer Auto Const Mandatory
	GlobalVariable Property Setting_AutoSaveReturnToWorkshopModeDelay Auto Const Mandatory
	GlobalVariable Property Setting_FreezeTimeInWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_BoostCarryWeightInWorkshopMode Auto Const Mandatory
EndGroup


; ---------------------------------------------
; Properties
; ---------------------------------------------

Bool Property IsGameSaving = false Auto Hidden


Bool Property PreventFallDamageInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_PreventFallDamageInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_PreventFallDamageInWorkshopMode.SetValue(1.0)
		else
			Setting_PreventFallDamageInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty
	

Bool Property FreezeTimeInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_FreezeTimeInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_FreezeTimeInWorkshopMode.SetValue(1.0)
		else
			Setting_FreezeTimeInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty

Bool Property BoostCarryWeightInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_BoostCarryWeightInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_BoostCarryWeightInWorkshopMode.SetValue(1.0)
		else
			Setting_BoostCarryWeightInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty

Bool Property FlyInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_FlyInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_FlyInWorkshopMode.SetValue(1.0)
		else
			Setting_FlyInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty

Bool Property InvisibleInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_InvisibleInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_InvisibleInWorkshopMode.SetValue(1.0)
		else
			Setting_InvisibleInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty


Bool Property InvulnerableInWorkshopMode Hidden
	Bool Function Get()
		return (Setting_InvulnerableInWorkshopMode.GetValueInt() == 1)
	EndFunction
	
	Function Set(Bool value)
		if(value)
			Setting_InvulnerableInWorkshopMode.SetValue(1.0)
		else
			Setting_InvulnerableInWorkshopMode.SetValue(0.0)
		endif
	EndFunction
EndProperty


; Setting this up a little differently so that we can give the player just one setting, but still control the speed and wether or not it's turned on independently via a hotkey to toggle the buff on or off
Bool bIncreaseSpeedInWorkshopMode = true
Bool Property IncreaseSpeedInWorkshopMode Hidden
	Bool Function Get()
		if( ! bIncreaseSpeedInWorkshopMode || Setting_MoveSpeedInWorkshopMode.GetValue() <= 0)
			return false
		else
			return true
		endif
	EndFunction
	
	Function Set(Bool value)
		bIncreaseSpeedInWorkshopMode = value
	EndFunction
EndProperty


Int iSpeedSpellIndex = 1
Int Property SpeedSpellIndex Hidden
	Int Function Get()
		Float fSpeedSetting = Setting_MoveSpeedInWorkshopMode.GetValue()
		
		if(fSpeedSetting == 0)
			iSpeedSpellIndex = -1
		elseif(fSpeedSetting == 1)
			iSpeedSpellIndex = 0
		elseif(fSpeedSetting == 2)
			iSpeedSpellIndex = 1
		else
			iSpeedSpellIndex = 2
		endif
		
		return iSpeedSpellIndex
	EndFunction
EndProperty

; ---------------------------------------------
; Vars
; ---------------------------------------------

InputEnableLayer controlLayer
Bool bSpeedBuffApplied = false
Bool bInvisibilityBuffApplied = false
Bool bFirstTimeEnteringEver = true
Race LastKnownRace = None
Float fFallDamageModdedBy = 0.0
Bool bBoostCarryWeightBuffApplied = false
Float fPreviousTimeScale = 0.0
Bool bTimeFrozen = false

; ---------------------------------------------
; Events
; --------------------------------------------- 

Event OnTimer(Int aiTimerID)
	Parent.OnTimer(aiTimerID)
	
	if(aiTimerID == DelayedFallDamageTimerID)
		if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
			AllowFallDamage()
		endif
	elseif(aiTimerID == WorkshopModeAutoSaveTimerID)
		if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
			ExitWorkshopModeAndSave()			
		endif
		
		Float fAutoSaveTime = Setting_AutoSaveTimer.GetValue() * 60
		
		if(fAutoSaveTime > 0)
			StartTimer(fAutoSaveTime, WorkshopModeAutoSaveTimerID)
		endif
	endif
EndEvent

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if(asMenuName== "WorkshopMenu")
		if( ! abOpening) ; Leaving workshop menu
			if(IsGameSaving)
				Utility.Wait(1.0) ; Give other quests a chance to react to the IsGameSaving state
				IsGameSaving = false
			else
				Bool bWasFlying = (PlayerRef.GetRace() == FloatingRace)
				DecreaseSpeed()
				DisableFlight()
				DisableInvisibility()
				DisableCarryWeightBoost()
				UnfreezeTime()
				PlayerRef.SetGhost(false)
				StartTimer(fFallDamagePreventionTime, DelayedFallDamageTimerID)		

				if(bWasFlying)
					; Give time for race swap to complete
					Utility.Wait(3.5)
				endif
				
				controlLayer.Delete()
				controlLayer = None
				
				CancelTimer(WorkshopModeAutoSaveTimerID)
			endif
		else ; Player entered workshop mode
			if( ! IsGameSaving)
				Float fAutoSaveTime = Setting_AutoSaveTimer.GetValue() * 60
			
				if(fAutoSaveTime > 0)
					StartTimer(fAutoSaveTime, WorkshopModeAutoSaveTimerID)
				endif
			
				controlLayer = InputEnableLayer.Create()
				controlLayer.EnableCamSwitch(false)
				controlLayer.EnableMenu(false)
		
				if(PreventFallDamageInWorkshopMode)
					PreventFallDamage()
				endif
				
				if(FlyInWorkshopMode)
					EnableFlight()
				endif
				
				if(InvisibleInWorkshopMode)
					EnableInvisibility()
				endif
				
				if(BoostCarryWeightInWorkshopMode)
					EnableCarryWeightBoost()
				endif
				
				if(FreezeTimeInWorkshopMode)
					FreezeTime()
				endif
				
				if(IncreaseSpeedInWorkshopMode)
					IncreaseSpeed()
				endif
				
				if(InvulnerableInWorkshopMode)
					PlayerRef.SetGhost(true)
				endif
			endif
		endif
	endif	
EndEvent

; ---------------------------------------------
; Functions
; --------------------------------------------- 

Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	RegisterForMenuOpenCloseEvent("WorkshopMenu")
EndFunction


Function ToggleFlight()
	if(PlayerRef.GetRace() == FloatingRace)
		FlyInWorkshopMode = false
		DisableFlight()
	else
		FlyInWorkshopMode = true
		EnableFlight()
	endif
EndFunction


Function ToggleSpeed()
	if(bSpeedBuffApplied)
		IncreaseSpeedInWorkshopMode = false
		DecreaseSpeed()
	else
		IncreaseSpeedInWorkshopMode = true
		IncreaseSpeed()
	endif
EndFunction


Function ToggleInvisible()
	if(bInvisibilityBuffApplied)
		InvisibleInWorkshopMode = false
		DisableInvisibility()
	else
		InvisibleInWorkshopMode = true
		EnableInvisibility()
	endif
EndFunction


Function ToggleInvulnerable()
	if(PlayerRef.IsGhost())
		InvulnerableInWorkshopMode = false
		PlayerRef.SetGhost(false)
	else
		InvulnerableInWorkshopMode = true
		PlayerRef.SetGhost(true)
	endif
EndFunction


Function ToggleFreezeTime()
	if(bTimeFrozen)
		FreezeTimeInWorkshopMode = false
		UnfreezeTime()
	else
		FreezeTimeInWorkshopMode = true
		FreezeTime()
	endif
EndFunction


Function FreezeTime()
	if(fPreviousTimeScale == 0.0 || fFrozenTimeScale != fPreviousTimeScale)
		fPreviousTimeScale = TimeScale.GetValue()
	endif
	
	TimeScale.SetValue(fFrozenTimeScale)
	
	FreezeTimeSpell.Cast(PlayerRef)
	
	bTimeFrozen = true
EndFunction


Function UnfreezeTime()
	if(fPreviousTimeScale > 0.0)
		if(fFrozenTimeScale == fPreviousTimeScale)
			TimeScale.SetValue(fDefaultTimeScale)
		else
			TimeScale.SetValue(fPreviousTimeScale)
		endif
	endif
	
	PlayerRef.DispelSpell(FreezeTimeSpell)
	
	bTimeFrozen = false
EndFunction


Function EnableFlight()
	if(PlayerRef.WornHasKeyword(JetpackKeyword))
		; Jetpacks are incompatible with the race swap 
		return
	endif
	
	if(PlayerRef.GetRace() != FloatingRace)
		LastKnownRace = PlayerRef.GetRace()
	endif
	
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode() && PlayerRef.GetRace() == LastKnownRace)
		Game.ForceFirstPerson()
		PlayerRef.SetRace(FloatingRace)
		
		if(bFirstTimeEnteringEver && ! PlayerRef.IsInInterior())
			; For new users, let's show them you can fly
			ObjectReference kTemp = PlayerRef.PlaceAtMe(XMarkerForm)
			bFirstTimeEnteringEver = false
			PlayerRef.TranslateTo(PlayerRef.X, PlayerRef.Y, PlayerRef.Z + 512.0, PlayerRef.GetAngleX(), PlayerRef.GetAngleY(), PlayerRef.GetAngleZ(), 300.0) 
			
			Game.StartDialogueCameraOrCenterOnTarget(kTemp)
			
			kTemp.Disable()
			kTemp.Delete()
		endif
	endif
EndFunction

Function DisableFlight()
	if(PlayerRef.GetRace() == FloatingRace)
		if(LastKnownRace)
			PlayerRef.SetRace(LastKnownRace)
			LastKnownRace = None
		else
			PlayerRef.SetRace(HumanRace)
		endif
	endif		
EndFunction


Function EnableInvisibility()
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		InvisibilitySpell.Cast(PlayerRef)
		PlayerRef.AddPerk(UndetectablePerk)
		
		bInvisibilityBuffApplied = true
	endif
EndFunction

Function DisableInvisibility()
	PlayerRef.DispelSpell(InvisibilitySpell)
	PlayerRef.RemovePerk(UndetectablePerk)
	
	bInvisibilityBuffApplied = false
EndFunction


Function EnableCarryWeightBoost()
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		BoostCarryWeightSpell.Cast(PlayerRef)
		
		bBoostCarryWeightBuffApplied = true
	endif
EndFunction

Function DisableCarryWeightBoost()
	PlayerRef.DispelSpell(BoostCarryWeightSpell)
	
	bBoostCarryWeightBuffApplied = false
EndFunction


Function IncreaseSpeed()
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		if(SpeedSpellIndex >= 0 && SpeedSpells.Length > SpeedSpellIndex)
			SpeedSpells[SpeedSpellIndex].Cast(PlayerRef)
		endif
		
		bSpeedBuffApplied = true
	endif
EndFunction

Function DecreaseSpeed()
	int i = 0
	while(i < SpeedSpells.Length)
		PlayerRef.DispelSpell(SpeedSpells[i])
		
		i += 1
	endWhile
	
	bSpeedBuffApplied = false
EndFunction


Function PreventFallDamage()
	if( ! PlayerRef.HasMagicEffect(ArmorFallingEffect))
		PlayerRef.AddPerk(ModFallingDamage)
		Float fBaseValue = PlayerRef.GetBaseValue(FallingDamageMod)
		
		if(fBaseValue < 100) ; Need to make sure we push this AV's Max up to at least 100
			PlayerRef.SetValue(FallingDamageMod, 100.0 - fBaseValue) 
		else
			; We'll just mod up by 100 to make sure the actual value, and not just base value is high
			PlayerRef.ModValue(FallingDamageMod, 100.0) 
		endif
	endif
EndFunction



Function AllowFallDamage()
	if( ! PlayerRef.HasMagicEffect(ArmorFallingEffect))
		Float fFDMod = PlayerRef.GetValue(FallingDamageMod)
				
		if(fFDMod < 0)
			fFDMod = 0
		endif
		
		PlayerRef.ModValue(FallingDamageMod, (-1 * (fFDMod)))
	endif
EndFunction


Function ExitWorkshopModeAndSave(Bool abAutoSave = true)
	WorkshopScript thisWorkshop
	if(WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		thisWorkshop = WorkshopParent.CurrentWorkshop.GetRef() as WorkshopScript
		
		if( ! thisWorkshop)
			; Warn user since they are expecting a save
			CouldNotAutoSave.Show()
			
			return
		endif
		
		IsGameSaving = true
		thisWorkshop.StartWorkshop(false)
	endif
	
	Game.RequestSave()
	
	Debug.Notification("Requesting game save.")
	
	if(thisWorkshop != None)
		Utility.Wait(Setting_AutoSaveReturnToWorkshopModeDelay.GetValue()) ; Give it a short time to finish saving
		thisWorkshop.StartWorkshop(true)
	endif
EndFunction


; ---------------------------------------------
; MCM Functions - Easiest to avoid parameters for use with MCM's CallFunction, also we only want these hotkeys to work in WS mode
; ---------------------------------------------

Function Hotkey_ToggleFlight()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	ToggleFlight()
EndFunction


Function Hotkey_ToggleSpeed()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	ToggleSpeed()
EndFunction


Function Hotkey_ToggleFreezeTime()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		MustBeInWorkshopModeToUseHotkeys.Show()
		return
	endif
	
	ToggleFreezeTime()
EndFunction


Function Hotkey_ExitWorkshopModeAndSave()
	ExitWorkshopModeAndSave()
EndFunction