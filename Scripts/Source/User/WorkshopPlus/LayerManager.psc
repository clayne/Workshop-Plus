; ---------------------------------------------
; WorkshopPlus:LayerManager.psc - by kinggath
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

Scriptname WorkshopPlus:LayerManager extends WorkshopFramework:Library:SlaveQuest Conditional
{ Handles layers }

import WorkshopFramework:Library:UtilityFunctions
import WorkshopFramework:Library:DataStructures
import WorkshopFramework:WorkshopFunctions

; ---------------------------------------------
; Consts 
; ---------------------------------------------


int iAutoUnhideLayersTimerID = 100 Const

WorkshopPlus:SettlementLayers CurrentSettlementLayers

String sLayerWidgetName = "WSPlus_Layers.swf" Const
int iLayerWidgetCommand_ShowWidget = 201 Const
int iLayerWidgetCommand_HideWidget = 202 Const
int iLayerWidgetCommand_UpdateLayer = 401 Const
int iLayerWidgetCommand_UpdateToggleIcons = 402 Const

Float fLayerWidgetDefault_PositionX = 1100.0 Const
Float fLayerWidgetDefault_PositionY = 150.0 Const
Float fLayerWidgetDefault_Scale = 0.5 Const

; ---------------------------------------------
; Editor Properties 
; ---------------------------------------------

Group Controllers
	WorkshopFramework:MainThreadManager Property ThreadManager Auto Const Mandatory
	WorkshopFramework:WorkshopResourceManager Property ResourceManager Auto Const Mandatory
	WorkshopFramework:PlaceObjectManager Property PlaceObjectManager Auto Const Mandatory
	WorkshopFramework:MainQuest Property WSFW_Main Auto Const Mandatory
	WorkshopPlus:MainQuest Property WSPlus_Main Auto Const Mandatory
	WorkshopPlus:ActionManager Property ActionManager Auto Const Mandatory
	WorkshopPlus:BlueprintManager Property BlueprintManager Auto Const Mandatory
	{ 1.0.3 - Support for blueprinting }
	WorkshopFramework:HUDFrameworkManager Property HUDFrameworkManager Auto Const Mandatory
	Form Property Thread_ScrapObject Auto Const Mandatory
	GlobalVariable Property gCurrentWorkshop Auto Const Mandatory
	{ Point to currentWorkshopId global controlled by WorkshopParent }
EndGroup


Group Aliases
	ReferenceAlias Property SafeSpawnPoint Auto Const Mandatory
	ReferenceAlias Property ActiveLayerRef Auto Const Mandatory
	{ Used for displaying the layer name in messages - not currently useful since we can't display ref names in Message Box selection, but perhaps F4SE can allow that in the future and we can introduce layer naming }
EndGroup


Group Assets
	Form Property SettlementLayersHolderForm Auto Const Mandatory
	Form Property WorkshopLayerForm Auto Const Mandatory
	Form Property PlaceableLayerHandleForm Auto Const Mandatory
	EffectShader Property ShaderActiveLayer Auto Const Mandatory
	EffectShader Property ShaderHighlightLayer Auto Const Mandatory
	EffectShader Property ShaderFlashLayer Auto Const Mandatory
	Sound Property HighlightLayerSound Auto Const Mandatory
	Sound Property UnhighlightLayerSound Auto Const Mandatory
	Sound Property ChangeActiveLayerSound Auto Const Mandatory
	Sound Property HideLayerSound Auto Const Mandatory
	Sound Property UnhideLayerSound Auto Const Mandatory
	Sound Property DisableLayerSound Auto Const Mandatory
	Sound Property HideMultipleLayersSound Auto Const Mandatory
	Sound Property UnhideMultipleLayersSound Auto Const Mandatory
EndGroup


Group ActorValues
	ActorValue Property LayerID Auto Const Mandatory
EndGroup


Group Globals
	GlobalVariable Property AllowLayerHandlingCancellation Auto Const Mandatory
	GlobalVariable Property CurrentActiveLayerIndex Auto Const Mandatory
	GlobalVariable Property CurrentLayerCount Auto Const Mandatory
	GlobalVariable[] Property gIncludeLayersInMenu Auto Const
	{ Global toggle for layer select entries, should be one for each layer (with the exception of default) }
EndGroup

Group Keyword
	Keyword Property WorkshopKeyword Auto Const Mandatory
	Keyword Property WorkshopItemKeyword Auto Const Mandatory
	Keyword Property LayerHolderLinkKeyword Auto Const Mandatory
	Keyword Property LayerItemLinkChainKeyword Auto Const Mandatory
	Keyword Property TemporarilyMoved Auto Const Mandatory
	Keyword Property AddedToLayerKeyword Auto Const Mandatory
	Keyword Property HandleLinkKeyword Auto Const Mandatory
	{ 1.0.2 - Link objects to the layer handle object, should be using WorkshopStackedItemParentKEYWORD }
	Keyword Property LayerHandleKeyword Auto Const Mandatory
	{ 1.0.2 - Keyword to identify an object as a layer handle }
	Keyword Property UndoHelperLinkKeyword Auto Const Mandatory
	{ 1.0.2 - Link mass duplicated objects to an undo helper }
	Keyword Property PreventAddingToLayersKeyword Auto Const Mandatory
	{ We'll use the vanilla keyword ActorPreventSubsegmentDamage so that any mod can exempt their items }
EndGroup

Group Messages
	Message Property CannotDeleteDefaultLayer Auto Const Mandatory
	Message Property MustBeInWorkshopModeToUseHotkeys Auto Const Mandatory
	Message Property NewLayerActivated Auto Const Mandatory
	Message Property DefaultLayerActivated Auto Const Mandatory
	Message Property NoOtherLayersToSwitchTo Auto Const Mandatory
	Message Property NoMoreLayersAllowed Auto Const Mandatory
	Message Property LayerSelect Auto Const Mandatory
	Message Property ScrapOrMoveItemsConfirmation Auto Const Mandatory
	Message Property RemoveAllLayersConfirmation Auto Const Mandatory
	Message Property AutoUnhidingLayers Auto Const Mandatory
	Message Property DuplicateActiveLayerInProgress Auto Const Mandatory
	Message Property DuplicateActiveLayerComplete Auto Const Mandatory
	Message Property DuplicatingLayer Auto Const Mandatory
	Message Property DuplicateActiveLayerConfirm Auto Const Mandatory
	Message Property NoItemsOnThisLayerToDuplicate Auto Const Mandatory
	Message Property DuplicateActiveLayerChooseTargetLayerConfirm Auto Const Mandatory
	Message Property LayerRelinkingStarted Auto Const Mandatory
	Message Property LayerRelinkingComplete Auto Const Mandatory
	Message Property LayerUnlinkingStarted Auto Const Mandatory
	Message Property LayerUnlinkingComplete Auto Const Mandatory
	Message Property LayerControlMenu Auto Const Mandatory
	Message Property LayerControlMenu_Advanced Auto Const Mandatory	
	Message Property CouldNotFindTheLayerYouSelectedUsingDefaultLayer Auto Const Mandatory
	{ 1.0.4 }
	Message Property NoLayerFoundToMoveItemsTo Auto Const Mandatory
	{ 1.0.4 }
	Message Property CouldNotFindSettlement Auto Const Mandatory
	{ 1.0.4 }
EndGroup


Group Settings
	GlobalVariable Property Setting_AutoChangeLayerOnMovedObjects Auto Const Mandatory
	GlobalVariable Property Setting_AutoUnhideLayersOnExitWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_AutoUnhideLayersDelay Auto Const Mandatory
	GlobalVariable Property Setting_UseLayerWidget Auto Const Mandatory
	GlobalVariable Property Setting_LayerWidgetNudgeScaleIncrement Auto Const Mandatory
	GlobalVariable Property Setting_LayerWidgetNudgeIncrement Auto Const Mandatory
	GlobalVariable Property Setting_PlayLayerSounds Auto Const Mandatory
	GlobalVariable Property Setting_UnlinkHiddenLayers Auto Const Mandatory
	GlobalVariable Property Setting_LayerHUDInWorkshopModeOnly Auto Const Mandatory
	GlobalVariable Property Setting_ClearLayerHighlightingOnExitWorkshopMode Auto Const Mandatory
	GlobalVariable Property Setting_HighlightItemsAddedToDefaultLayer Auto Const Mandatory
	{ 1.0.4 - Starting this off as it's very odd to see everything flash purple when you first enter a settlement }
	GlobalVariable Property Setting_HighlightItemsAddedToLayer Auto Const Mandatory
	{ 1.0.4 }
	GlobalVariable Property Settings_ShowHotkeyWarnings Auto Const Mandatory
	{ 1.0.4 }
EndGroup

; ---------------------------------------------
; Properties
; ---------------------------------------------

Int Property iNextLayerID = 0 Auto Hidden ; Starting at 0 so first call to NextLayerID = 1, we don't want to use 0 as a layer ID, because that's the default value of the AV.
Int Property NextLayerID
	Int Function Get()
		iNextLayerID += 1
		
		return iNextLayerID
	EndFunction
EndProperty


int Property iMaxLayers = 15 Auto Const ; We can expand this, but we'll need to edit the LayerSelect message in XEdit as we're at the max the CK will allow atm ; 1.0.2 - Made this a const property so we can access it in other quests and also expand it in the future


Float Property fLayersWidgetX = 1100.0 Auto Hidden Conditional
Float Property fLayersWidgetY = 150.0 Auto Hidden Conditional
Float Property fLayersWidgetScale = 0.5 Auto Hidden Conditional


; ---------------------------------------------
; Vars
; ---------------------------------------------

Bool bRegisterWorkshopsBlock = false
Bool bMultipleLayersExist = false
Bool bDuplicateLayerBlock = false

; ---------------------------------------------
; Events
; --------------------------------------------- 

Event OnTimer(Int aiTimerID)
	Parent.OnTimer(aiTimerID)
	
	if(aiTimerID == iAutoUnhideLayersTimerID)
		if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
			AutoUnhidingLayers.Show()
			ShowMultipleLayers_Lock()
		endif
	endif
EndEvent


Event ObjectReference.OnWorkshopObjectPlaced(ObjectReference akWorkshopRef, ObjectReference akReference)
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	WorkshopPlus:WorkshopLayer kLayerRef = CurrentSettlementLayers.ActiveLayer
	if(asWorkshop.GetWorkshopID() != gCurrentWorkshop.GetValueInt())
		WorkshopPlus:SettlementLayers kLayerHolder = asWorkshop.GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if(kLayerHolder)
			kLayerRef = kLayerHolder.ActiveLayer
		endif
	endif
	
	if(kLayerRef)
		AddItemToLayer_Lock(akReference, kLayerRef)
	endif
EndEvent


Event ObjectReference.OnWorkshopObjectMoved(ObjectReference akWorkshopRef, ObjectReference akReference)
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	; If option to auto shift moved object to active layer, then do so
	if(Setting_AutoChangeLayerOnMovedObjects.GetValue() == 1)		
		WorkshopPlus:WorkshopLayer kLayerRef = CurrentSettlementLayers.ActiveLayer
		
		if(asWorkshop.GetWorkshopID() != gCurrentWorkshop.GetValueInt())
			WorkshopPlus:SettlementLayers kLayerHolder = asWorkshop.GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
			
			if(kLayerHolder)
				kLayerRef = kLayerHolder.ActiveLayer
			endif
		endif
		
		if(kLayerRef)
			int iPreviousLayerID = akReference.GetValue(LayerID) as Int
			WorkshopPlus:WorkshopLayer PreviousLayer = GetLayerFromID(iPreviousLayerID, asWorkshop)
			if(PreviousLayer)
				if(PreviousLayer == kLayerRef) ; 1.0.2 - Already on the correct layer
					return
				endif
			
				RemoveItemFromLayer_Lock(akReference, PreviousLayer, kLayerRef)
			else
				; TODO - This is a temporary solution. It seems that items are being tagged as being part of a layer when they are built immediately before the player has setup any layers - but then the system is failing to find those layers with calls to GetLayerFromID. Likely the layer it's adding to is deleted, or perhaps the DefaultLayer does not return correctly from GetLayerFromID if an actual ID is found????
				akReference.RemoveKeyword(AddedToLayerKeyword)
			endif
			;/
			if( ! CanBeAddedToLayer(akReference))
				if(akReference.HasKeyword(PreventAddingToLayersKeyword))
					Debug.MessageBox("This object is specifically prevented from being added. Keyword PreventAddingToLayersKeyword found.")
				elseif(akReference.HasKeyword(AddedToLayerKeyword))
					Debug.MessageBox("This object is already on a layer. Keyword AddedToLayerKeyword found.")
				elseif(akReference.HasKeyword(LayerHandleKeyword))
					Debug.MessageBox("Item is a layer handle, can't be added to a layer.")
				elseif(akReference.HasKeyword(WorkshopKeyword))
					Debug.MessageBox("Item is a Workshop Workbench, can't be added to a layer.")
				elseif(akReference as Actor && ! (akReference as WorkshopObjectActorScript))
					Debug.MessageBox("Item is an NPC, can't be added to a layer.")
				endif
			endif
			/;
			
			AddItemToLayer_Lock(akReference, kLayerRef)
		endif
	else
		; 1.0.2 - If layer has a LayerHandle, relink it, because moving an item auto disconnects the WorkshopStackedItemParentKEYWORD link
		int iPreviousLayerID = akReference.GetValue(LayerID) as Int
		WorkshopPlus:WorkshopLayer CurrentItemLayer = GetLayerFromID(iPreviousLayerID, asWorkshop)
		
		if(CurrentItemLayer && CurrentItemLayer.LayerHandle && ActionManager.kGrabbedRef != CurrentItemLayer.LayerHandle)
			WorkshopPlus:ObjectReferences:LayerHandle asHandle = CurrentItemLayer.LayerHandle as WorkshopPlus:ObjectReferences:LayerHandle
			
			if(asHandle.fLinkRadius < 0 || akReference.GetDistance(asHandle) < asHandle.fLinkRadius)
				akReference.SetLinkedRef(CurrentItemLayer.LayerHandle, HandleLinkKeyword)
			endif
		endif
	endif
EndEvent


Event ObjectReference.OnWorkshopObjectDestroyed(ObjectReference akWorkshopRef, ObjectReference akReference)
	WorkshopScript asWorkshop = akWorkshopRef as WorkshopScript
	
	; Make sure we remove items from the layer they were on
	if(akReference.HasKeyword(AddedToLayerKeyword)) ; 1.0.2 - Not everything needs to be removed from layers
		; Move and enable temporarily so we can test AV (Always setposition while disabled, it's cheaper)
		Float fX = akReference.X
		Float fY = akReference.Y
		Float fZ = akReference.Z
		akReference.AddKeyword(TemporarilyMoved)
		akReference.SetPosition(fX, fY, fZ - 10000)
		akReference.Enable(false)
		Int iLayerID = akReference.GetValue(LayerID) as Int
		akReference.Disable(false)
		akReference.SetPosition(fX, fY, fZ)
		akReference.RemoveKeyword(TemporarilyMoved)
		
		if(iLayerID > 0)
			WorkshopPlus:SettlementLayers kLayerHolderRef = CurrentSettlementLayers
			if(asWorkshop.GetWorkshopID() != gCurrentWorkshop.GetValueInt())
				kLayerHolderRef = asWorkshop.GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
				
				if( ! kLayerHolderRef)
					return
				endif
			endif
			
			if(kLayerHolderRef.DefaultLayer.iLayerID == iLayerID)
				RemoveItemFromLayer_Lock(akReference, kLayerHolderRef.DefaultLayer)
			else
				int i = 0 
				bool bLayerFound = false
				while(i < kLayerHolderRef.Layers.Length && ! bLayerFound)
					if(kLayerHolderRef.Layers[i].iLayerID == iLayerID)
						RemoveItemFromLayer_Lock(akReference, kLayerHolderRef.Layers[i])
						bLayerFound = true
					endif
					
					i += 1
				endWhile
			endif
		endif
	endif
EndEvent




Event WorkshopFramework:MainQuest.PlayerEnteredSettlement(WorkshopFramework:MainQuest akQuestRef, Var[] akArgs)
	WorkshopScript kWorkshopRef = akArgs[0] as WorkshopScript
	Bool bPreviouslyUnloaded = akArgs[1] as Bool
	
	CurrentSettlementLayers = kWorkshopRef.GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
	
	if(CurrentSettlementLayers == None)
		CurrentSettlementLayers = SetupSettlementLayers_Lock(kWorkshopRef)		
	endif
	
	BreakInfiniteLinkedLayers()
	UpdateAllLayersOnHUD()
	UpdateLayerWidget(abShow = true)
EndEvent

Event WorkshopFramework:MainQuest.PlayerExitedSettlement(WorkshopFramework:MainQuest akQuestRef, Var[] akArgs)
	WorkshopScript kWorkshopRef = akArgs[0] as WorkshopScript
	Bool bStillLoaded = akArgs[1] as Bool
	
	UpdateLayerWidget(abShow = false)
EndEvent

Event WorkshopFramework:Library:ThreadRunner.OnThreadCompleted(WorkshopFramework:Library:ThreadRunner akThreadRunner, Var[] akargs)
	;/
	akargs[0] = sCustomCallCallbackID
	akargs[1] = iCallbackID
	akargs[2] = Result from called function
	/;
EndEvent


Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if(asMenuName== "WorkshopMenu")
		if( ! abOpening) ; Leaving workshop menu
			if( ! WSPlus_Main.IsGameSaving)
				; Player left WS Mode, clear the highlighting
				if(Setting_ClearLayerHighlightingOnExitWorkshopMode.GetValue() == 1.0)
					ClearAllHighlighting()
				endif
				
				if(Setting_LayerHUDInWorkshopModeOnly.GetValue() == 1.0)
					UpdateLayerWidget(abShow = false)
				endif
				
				if(Setting_AutoUnhideLayersOnExitWorkshopMode.GetValue() == 1.0)
					StartTimer(Setting_AutoUnhideLayersDelay.GetValue(), iAutoUnhideLayersTimerID)
				endif
			endif
		else ; Player entered workshop mode	
			; ShowHUDWidgetsInWorkshopMode call no longer needed - now done in WorkshopFramework 
			;	HUDFrameworkManager.ShowHUDWidgetsInWorkshopMode()
			UpdateLayerWidget(abShow = true)
		endif
	endif	
EndEvent


; ---------------------------------------------
; Functions
; --------------------------------------------- 

; 1.0.3 - Give lock longer than the default time, we're going to be hitting it frequently when the player does batch operations such as blueprints or layer cloning.
Int Function GetMaxLockWaitCount()
	; Override 
	return 200
EndFunction

Function HandleQuestInit()
	Parent.HandleQuestInit()
	
	; Init arrays
	DuplicateEventIDs = new Int[0]
	
	; Register for events
	RegisterForCustomEvent(WSFW_Main, "PlayerEnteredSettlement")
	RegisterForCustomEvent(WSFW_Main, "PlayerExitedSettlement")
	ThreadManager.RegisterForCallbackThreads(Self)
EndFunction


Function HandleGameLoaded()
	Parent.HandleGameLoaded()
	
	RegisterForMenuOpenCloseEvent("WorkshopMenu")
	
	; New workshops might have been added, so we need to register for those events
	RegisterForAllWorkshopEvents()
	
	; Register HUDFramework widget
	HUDFrameworkManager.RegisterWidget(Self as ScriptObject, sLayerWidgetName, fLayersWidgetX, fLayersWidgetY, false, false)
	
	WorkshopScript nearestWorkshop = WorkshopFramework:WSFW_API.GetNearestWorkshop(PlayerRef)
	; 1.0.3 - Sanity check to nearestWorkshop
	if(nearestWorkshop && PlayerRef.IsWithinBuildableArea(nearestWorkshop))
		UpdateLayerWidget(abShow = true)
		
		if(CurrentSettlementLayers == None) ; This could happen if player loaded game in a settlement the first time they installed this
			CurrentSettlementLayers = SetupSettlementLayers_Lock(nearestWorkshop)		
		endif
	endif
	
	if(DuplicateEventIDs == None)
		DuplicateEventIDs = new Int[0]
	endif
EndFunction


Function ClearDuplicateLayerBlock()
	; Emergency use only
	bDuplicateLayerBlock = false
	DuplicateEventIDs = new Int[0]
EndFunction

Function ResetLayerWidgetPositionAndScale()
	HUDFrameworkManager.SetWidgetPosition(sLayerWidgetName, fLayerWidgetDefault_PositionX, fLayerWidgetDefault_PositionY)
	HUDFrameworkManager.SetWidgetScale(sLayerWidgetName, fLayerWidgetDefault_Scale, fLayerWidgetDefault_Scale)
EndFunction

Function UpdateLayerWidget(Bool abShow = true, Bool abJustDoMultipleLayerCheck = false)
	; Check if we have multiple layers
	int i = 0
	Bool bPreviousMultipleLayersExisted = bMultipleLayersExist
	
	bMultipleLayersExist = false
	if(CurrentSettlementLayers) ; 1.0.2 - Skip this check if layers aren't setup yet
		while(i < CurrentSettlementLayers.Layers.Length && ! bMultipleLayersExist)
			if(CurrentSettlementLayers.Layers[i].bEnabled)
				bMultipleLayersExist = true
			endif
			
			i += 1
		endWhile
	endif
	
	if(bMultipleLayersExist == bPreviousMultipleLayersExisted && abJustDoMultipleLayerCheck)
		; Nothing changed
		return
	endif
	
	if(abShow && bMultipleLayersExist && Setting_UseLayerWidget.GetValue() == 1 && (Setting_LayerHUDInWorkshopModeOnly.GetValue() == 0 || WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode()))
		if( ! HUDFrameworkManager.IsWidgetLoaded(sLayerWidgetName))
			ModTrace("[WS Plus] Loading hud widget " + sLayerWidgetName + ".")
			HUDFrameworkManager.LoadWidget(sLayerWidgetName)
			Utility.Wait(1.0) ; Give it a moment to load
		endif
		
		HUDFrameworkManager.SendMessage(sLayerWidgetName, iLayerWidgetCommand_ShowWidget)
		HUDFrameworkManager.SetWidgetPosition(sLayerWidgetName, fLayersWidgetX, fLayersWidgetY)
		HUDFrameworkManager.SetWidgetScale(sLayerWidgetName, fLayersWidgetScale, fLayersWidgetScale)
		
		UpdateHUDToggleIcons()
		;Debug.MessageBox("Showing layer hud")
	else
		;/
		if( ! abShow)
			Debug.MessageBox("Hide layer HUD called")
		endif 
		
		if( ! bMultipleLayersExist)
			Debug.MessageBox("Only the default layer exists")
		endif
		
		if(Setting_UseLayerWidget.GetValue() != 1)
			Debug.MessageBox("Layer HUD is disabled in settings")
		endif
		
		if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
			Debug.MessageBox("Player is not in workshop mode")
		endif
		
		/;
		
		if(HUDFrameworkManager.IsWidgetLoaded(sLayerWidgetName))
			HUDFrameworkManager.SendMessage(sLayerWidgetName, iLayerWidgetCommand_HideWidget)
		endif
	endif
EndFunction


Function UpdateAllLayersOnHUD()
	; Default layer
	UpdateLayerOnHUD(CurrentSettlementLayers.DefaultLayer, abDelete = false)
	; Other layers
	int i = 0
	while(i < CurrentSettlementLayers.Layers.Length)
		UpdateLayerOnHUD(CurrentSettlementLayers.Layers[i], ! CurrentSettlementLayers.Layers[i].bEnabled)
		
		i += 1
	endWhile
EndFunction

Function UpdateLayerOnHUD(WorkshopPlus:WorkshopLayer akLayerRef, Bool abDelete = false)
	; 1.0.2 - If the player left the settlement we don't need to update it right now
	if( ! CurrentSettlementLayers || CurrentSettlementLayers != GetLayerHolderFromLayer(akLayerRef))
		return 
	endif
	
	int iShow = 0
	if( ! abDelete)
		iShow = 1
	endif
	
	
	int iActive = 0
	if(akLayerRef.bActive)
		iActive = 1
	endif
	
	int iItemsHidden = 0
	if( ! akLayerRef.bShown)
		iItemsHidden = 1
	endif
	
	int iLinked = 0
	if(akLayerRef.bLinked)
		iLinked = 1
	endif
	
	int iLayerIndex
	if(akLayerRef == CurrentSettlementLayers.DefaultLayer)
		iLayerIndex = -1
	else
		iLayerIndex = CurrentSettlementLayers.Layers.Find(akLayerRef)
		
		if(iLayerIndex < 0)
			return
		endif
	endif
	
	if(iLayerIndex >= -1)
		;ModTrace("[WSPlus] Updating hud layer, sending " + sLayerWidgetName + ", Command: " + iLayerWidgetCommand_UpdateLayer + ", Index: " + iLayerIndex + ", Show: " + iShow + ", Active: " + iActive + ", Hide: " + iItemsHidden + ", Linked: " + iLinked)
		
		if(iShow == 1)
			UpdateLayerWidget(abJustDoMultipleLayerCheck = true) ; Will unhide if previously hidden
		endif
		
		; Update widget
		HUDFrameworkManager.SendMessage(sLayerWidgetName, iLayerWidgetCommand_UpdateLayer, iLayerIndex, iShow, iActive, iItemsHidden, iLinked)
		
		if(iShow == 0)
			UpdateLayerWidget(abJustDoMultipleLayerCheck = true) ; Will autohide if all layers disabled
		endif	
	endif
EndFunction


; 1.0.3 - Added new section to the UI piece to display features that are enable/disabled
Function UpdateHUDToggleIcons()
	; TODO: Display additional toggles that are relevant
	int iAutoChangeLayerOnMove = Setting_AutoChangeLayerOnMovedObjects.GetValueInt()
	
	; Update widget
	HUDFrameworkManager.SendMessage(sLayerWidgetName, iLayerWidgetCommand_UpdateToggleIcons, iAutoChangeLayerOnMove)
EndFunction


; Called by HUDFramework
Function HUD_WidgetLoaded(string asWidgetName)
	if(asWidgetName == sLayerWidgetName)
		UpdateLayerOnHUD(CurrentSettlementLayers.DefaultLayer)
		UpdateAllLayersOnHUD()
		
		HUDFrameworkManager.SetWidgetPosition(sLayerWidgetName, fLayersWidgetX, fLayersWidgetY)
		HUDFrameworkManager.SetWidgetScale(sLayerWidgetName, fLayersWidgetScale, fLayersWidgetScale)
	endif
EndFunction


Function RegisterForAllWorkshopEvents()
	if(bRegisterWorkshopsBlock)
		return
	endif
	
	bRegisterWorkshopsBlock = true
	
	int i = 0
	WorkshopScript[] kWorkshops = ResourceManager.Workshops
	while(i < kWorkshops.Length)
		if(kWorkshops[i] && kWorkshops[i].IsBoundGameObjectAvailable())
			RegisterForRemoteEvent(kWorkshops[i], "OnWorkshopObjectPlaced")
			RegisterForRemoteEvent(kWorkshops[i], "OnWorkshopObjectMoved")
			RegisterForRemoteEvent(kWorkshops[i], "OnWorkshopObjectDestroyed")
		endif
		
		i += 1
	endWhile
	
	bRegisterWorkshopsBlock = false
	
	;Debug.Notification("[Workshop Plus] Finished registering for workshop events.")
EndFunction


WorkshopPlus:WorkshopLayer Function GetLayerFromID(Int aiLayerID, WorkshopScript akWorkshopRef)
	WorkshopPlus:SettlementLayers kLayerHolder = akWorkshopRef.GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
	
	if(kLayerHolder)
		if(kLayerHolder.DefaultLayer.iLayerID == aiLayerID)
			return kLayerHolder.DefaultLayer
		elseif(kLayerHolder.Layers.Length > 0)
			int i = 0
			while(i < kLayerHolder.Layers.Length)
				if(kLayerHolder.Layers[i].iLayerID == aiLayerID)
					return kLayerHolder.Layers[i]
				endif
				
				i += 1
			endWhile
		endif
	else
		return None
	endif
EndFunction


WorkshopPlus:SettlementLayers Function SetupSettlementLayers_Lock(WorkshopScript akWorkshopRef)
	ObjectReference kSpawnAt = SafeSpawnPoint.GetRef()
	
	if(kSpawnAt)
		int iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return None
		endif
		
		WorkshopPlus:SettlementLayers kLayerHolderRef = kSpawnAt.PlaceAtMe(SettlementLayersHolderForm, abDeleteWhenAble = false) as WorkshopPlus:SettlementLayers
		
		if(kLayerHolderRef)
			; New layer set, prepare it
			kLayerHolderRef.iWorkshopID = akWorkshopRef.GetWorkshopID()
			kLayerHolderRef.DefaultLayer = CreateLayer_Lock(false)
			kLayerHolderRef.ActiveLayer = kLayerHolderRef.DefaultLayer
			
			kLayerHolderRef.DefaultLayer.bShown = true
			kLayerHolderRef.DefaultLayer.bActive = true
			kLayerHolderRef.DefaultLayer.bEnabled = true
			kLayerHolderRef.DefaultLayer.iWorkshopID = kLayerHolderRef.iWorkshopID
			
			UpdateLayerOnHUD(kLayerHolderRef.DefaultLayer)
			
			; We only want one layer holder per settlement, so we'll link workshop to holder
			akWorkshopRef.SetLinkedRef(kLayerHolderRef, LayerHolderLinkKeyword)
			
			
			; 1.0.4 - Turning this into an optional tool to be run from the menus
			;/
			; Copy existing items onto the default layer
			ObjectReference[] kExistingObjects = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
			
			int i = 0
			while(i < kExistingObjects.Length)
				AddItemToLayer_Lock(kExistingObjects[i], kLayerHolderRef.DefaultLayer, abGetLock = false)
				
				i += 1
			endWhile
			/;
			; TODO Sim Settlements: Any items with the CitySpawned keyword should be moved to a separate layer
			
			ModTrace("[WSPlus] Successfully configured layer holder for " + akWorkshopRef + ".")
		else
			ModTrace("[WSPlus] Failed to setup layers for settlement " + akWorkshopRef + ".", 2)
		endif
		
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
		
		return kLayerHolderRef
	else
		ModTrace("[WSPlus] Unable to find spawn point to set up layers for settlement " + akWorkshopRef + ".", 2)
	endif
	
	return None
EndFunction


WorkshopPlus:WorkshopLayer Function CreateLayer_Lock(Bool abGetLock = true)
	int iLockKey 
	
	if(abGetLock)
		iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return None
		endif
	endif
			
	int iLayerID = NextLayerID
	
	ObjectReference kSpawnAt = SafeSpawnPoint.GetRef()
	WorkshopPlus:WorkshopLayer kLayerRef = None
	if(kSpawnAt)
		kLayerRef = kSpawnAt.PlaceAtMe(WorkshopLayerForm, abDeleteWhenAble = false) as WorkshopPlus:WorkshopLayer
		kLayerRef.iLayerID = iLayerID
	else
		ModTrace("[WSPlus] Unable to find spawn point to create layer " + iLayerID + " for settlement " + ResourceManager.Workshops[gCurrentWorkshop.GetValueInt()] + ".", 2)
	endif
	
	if(abGetLock)
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
	
	return kLayerRef
EndFunction


Function AddLayer(Bool abGetLock = true)
	int iCurrentWorkshopID = gCurrentWorkshop.GetValueInt()
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
		return
	endif
	
	if(CurrentSettlementLayers.iWorkshopID != iCurrentWorkshopID)
		CurrentSettlementLayers = ResourceManager.Workshops[iCurrentWorkshopID].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if( ! CurrentSettlementLayers)
			ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
			return
		endif
	endif
	
	; Get Edit Lock 
	int iLockKey
	if(abGetLock)
		iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
	endif
		
	
	if(CurrentSettlementLayers.Layers == None)
		CurrentSettlementLayers.Layers = new WorkshopPlus:WorkshopLayer[0]
	endif
	
	WorkshopPlus:WorkshopLayer kNewLayerRef = CreateLayer_Lock(false)
	
	if(kNewLayerRef)
		kNewLayerRef.bShown = true
		kNewLayerRef.bEnabled = true
		kNewLayerRef.iWorkshopID = CurrentSettlementLayers.iWorkshopID
		
		CurrentSettlementLayers.Layers.Add(kNewLayerRef)
		MakeActiveLayer(kNewLayerRef)		
	endif
		
	if(abGetLock)
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndFunction


Function MakeActiveLayer(WorkshopPlus:WorkshopLayer akLayerRef)
	ModTrace("[WS Plus] Setting active layer " + akLayerRef)
	if( ! akLayerRef)
		ModTrace("[WSPlus] Could not make layer " + akLayerRef + " active, the ref is missing or is not the correct type.")
		
		return
	endif
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[gCurrentWorkshop.GetValueInt()] + ".", 2)
		
		return
	endif
	
	; Make all other layers inactive
	; Default Layer
	CurrentSettlementLayers.DefaultLayer.bActive = false
	; Other Layers
	int i = 0
	while(i < CurrentSettlementLayers.Layers.Length)
		CurrentSettlementLayers.Layers[i].bActive = false
		
		i += 1
	endWhile
	
	WorkshopPlus:WorkshopLayer kPreviousActiveLayer = CurrentSettlementLayers.ActiveLayer
	
	if(kPreviousActiveLayer.CurrentHighlightShader == ShaderActiveLayer)
		HighlightLayerItems(kPreviousActiveLayer, None, true, abMultiHighlight = true)
		HighlightLayerItems(akLayerRef, ShaderActiveLayer, abMultiHighlight = true)
	endif
	
	CurrentSettlementLayers.ActiveLayer = akLayerRef
	akLayerRef.bActive = true
	
	ActiveLayerRef.ForceRefTo(akLayerRef)
	
	if(akLayerRef == CurrentSettlementLayers.DefaultLayer)
		DefaultLayerActivated.Show()
	else
		NewLayerActivated.Show(CurrentSettlementLayers.Layers.Find(akLayerRef))
	endif
	
	UpdateLayerOnHUD(akLayerRef)
	if(Setting_PlayLayerSounds.GetValue() == 1)
		ChangeActiveLayerSound.Play(PlayerRef)
	endif
EndFunction 


Function ToggleActiveLayer()
	if( ! CurrentSettlementLayers.ActiveLayer.bShown)
		ShowLayer_Lock(CurrentSettlementLayers.ActiveLayer)
	else
		HideLayer_Lock(CurrentSettlementLayers.ActiveLayer)
	endif
EndFunction


Function ToggleLayerLink()
	if( ! CurrentSettlementLayers.ActiveLayer.bLinked)
		RelinkLayer_Lock(CurrentSettlementLayers.ActiveLayer)
	else
		UnlinkLayer_Lock(CurrentSettlementLayers.ActiveLayer)
	endif
EndFunction

Function ToggleLayerHighlight()
	if(CurrentSettlementLayers.ActiveLayer.CurrentHighlightShader == None)
		HighlightActiveLayer(false)
	else
		ClearActiveLayerHighlight()
	endif
EndFunction


Function ShowLayer_Lock(WorkshopPlus:WorkshopLayer akLayerRef = None, Bool abGetLock = true, Bool abMultiShow = false)
	ModTrace("[WS Plus] Showing layer " + akLayerRef)
	if( ! akLayerRef)
		akLayerRef = CurrentSettlementLayers.ActiveLayer
		
		if( ! akLayerRef)
			ModTrace("[WSPlus] Could not show layer " + akLayerRef + ", the ref is missing or is not the correct type.")
		endif
		
		return
	endif
	
	; 1.0.2 - Prevent show all layers from revealing "deleted" layers
	if( ! akLayerRef.bEnabled)
		return
	endif
	
	if(Setting_UnlinkHiddenLayers.GetValue() == 1)
		akLayerRef.bLinked = true
	endif
	akLayerRef.bShown = true
	UpdateLayerOnHUD(akLayerRef)
	
	if( ! abMultiShow)
		if(Setting_PlayLayerSounds.GetValue() == 1)
			UnhideLayerSound.Play(PlayerRef)
		endif
	endif
	
	if(akLayerRef.kLastCreatedItem)
		; Get Edit Lock 
		int iLockKey
		if(abGetLock)
			iLockKey = GetLock()
			if(iLockKey <= GENERICLOCK_KEY_NONE)
				ModTrace("Unable to get lock!", 2)
				
				return
			endif
		endif
		
		
		akLayerRef.kLastCreatedItem.Enable(false)
		akLayerRef.kLastCreatedItem.EnableLinkChain(LayerItemLinkChainKeyword, false)
		
		SendChatterToLayer(akLayerRef, fChatter_ShowItem)
		
		if(akLayerRef.CurrentHighlightShader != None)
			; Re-highlight
			EffectShader TempShader = akLayerRef.CurrentHighlightShader
			akLayerRef.CurrentHighlightShader = None ; Need to set this to none or highlightLayerItems won't process the request
			HighlightLayerItems(akLayerRef, TempShader, abMultiHighlight = true)
		endif
		
		if(Setting_UnlinkHiddenLayers.GetValue() == 1)
			RelinkLayer_Lock(akLayerRef, false)
		endif
		
		if(abGetLock)
			; Release Edit Lock
			if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
				ModTrace("Failed to release lock " + iLockKey + "!", 2)
			endif
		endif			
	endif
EndFunction


Function RelinkLayer_Lock(WorkshopPlus:WorkshopLayer akLayerRef, Bool abGetLock = true)
	ModTrace("[WS Plus] Relinking layer " + akLayerRef)
	if( ! akLayerRef)
		akLayerRef = CurrentSettlementLayers.ActiveLayer
		
		if( ! akLayerRef)
			ModTrace("[WSPlus] Could not relink layer " + akLayerRef + ", the ref is missing or is not the correct type.")
		endif
		
		return
	endif
	
	if(akLayerRef.kLastCreatedItem)
		; Get Edit Lock 
		int iLockKey
		if(abGetLock)
			iLockKey = GetLock()
			
			if(iLockKey <= GENERICLOCK_KEY_NONE)
				ModTrace("Unable to get lock!", 2)
				
				return
			endif
		endif
		
		;LayerRelinkingStarted.Show()
		
		akLayerRef.bLinked = true
		
		ObjectReference kNextRef = akLayerRef.kLastCreatedItem
		WorkshopScript thisWorkshop = ResourceManager.Workshops[CurrentSettlementLayers.iWorkshopID]
		while(kNextRef)
			if(kNextRef.GetLinkedRef(WorkshopItemKeyword) == None)
				kNextRef.SetLinkedRef(thisWorkshop, WorkshopItemKeyword)
			endif
			
			kNextRef = kNextRef.GetLinkedRef(LayerItemLinkChainKeyword)				
		endWhile
		
		UpdateLayerOnHUD(akLayerRef)
		;LayerRelinkingComplete.Show()

		if(abGetLock)
			; Release Edit Lock
			if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
				ModTrace("Failed to release lock " + iLockKey + "!", 2)
			endif		
		endif
	endif
EndFunction


Function UnlinkLayer_Lock(WorkshopPlus:WorkshopLayer akLayerRef, Bool abGetLock = true)
	ModTrace("[WS Plus] Unlinking layer " + akLayerRef)
	if( ! akLayerRef)
		akLayerRef = CurrentSettlementLayers.ActiveLayer
		
		if( ! akLayerRef)
			ModTrace("[WSPlus] Could not relink layer " + akLayerRef + ", the ref is missing or is not the correct type.")
		endif
		
		return
	endif
	
	if(akLayerRef.kLastCreatedItem)
		; Get Edit Lock 
		int iLockKey 
		if(abGetLock)
			iLockKey = GetLock()
			if(iLockKey <= GENERICLOCK_KEY_NONE)
				ModTrace("Unable to get lock!", 2)
				
				return
			endif
		endif
		
		;LayerUnlinkingStarted.Show()
		
		akLayerRef.bLinked = false
		
		ObjectReference kNextRef = akLayerRef.kLastCreatedItem
		
		while(kNextRef)
			kNextRef.SetLinkedRef(None, WorkshopItemKeyword)
			
			kNextRef = kNextRef.GetLinkedRef(LayerItemLinkChainKeyword)				
		endWhile
		
		UpdateLayerOnHUD(akLayerRef)
		;LayerUnlinkingComplete.Show()
		
		if(abGetLock)
			; Release Edit Lock
			if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
				ModTrace("Failed to release lock " + iLockKey + "!", 2)
			endif	
		endif
	endif
EndFunction

Float fChatter_HideItem = 0.0 Const
Float fChatter_ShowItem = 1.0 Const
Function HideLayer_Lock(WorkshopPlus:WorkshopLayer akLayerRef = None, Bool abGetLock = true, Bool abMultiHide = false)
	ModTrace("[WS Plus] Hiding layer " + akLayerRef)
	if( ! akLayerRef)
		akLayerRef = CurrentSettlementLayers.ActiveLayer
		
		if( ! akLayerRef)
			ModTrace("[WSPlus] Could not hide layer " + akLayerRef + ", the ref is missing or is not the correct type.")
		
			return
		endif
	endif
	
	if(Setting_UnlinkHiddenLayers.GetValue() == 1)
		akLayerRef.bLinked = false
	endif
	
	akLayerRef.bShown = false
	UpdateLayerOnHUD(akLayerRef)	
	
	if( ! abMultiHide)
		if(Setting_PlayLayerSounds.GetValue() == 1)
			HideLayerSound.Play(PlayerRef)
		endif
	endif
		
	if(akLayerRef.kLastCreatedItem)
		; Get Edit Lock 
		int iLockKey
		if(abGetLock)
			iLockKey = GetLock()
			if(iLockKey <= GENERICLOCK_KEY_NONE)
				ModTrace("Unable to get lock!", 2)
				
				return
			endif
		endif
		
		akLayerRef.kLastCreatedItem.Disable(false)
		akLayerRef.kLastCreatedItem.DisableLinkChain(LayerItemLinkChainKeyword, false)
		
		SendChatterToLayer(akLayerRef, fChatter_HideItem)
		
		if(Setting_UnlinkHiddenLayers.GetValue() == 1)
			UnlinkLayer_Lock(akLayerRef, false)
		endif		
		
		if(abGetLock)
			; Release Edit Lock
			if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
				ModTrace("Failed to release lock " + iLockKey + "!", 2)
			endif
		endif
	endif
EndFunction


Function SendChatterToLayer(WorkshopPlus:WorkshopLayer akLayerRef, Float afChatterCode)
	if( ! akLayerRef || akLayerRef.kLastCreatedItem == None)
		return
	endif

	ObjectReference kLastCreatedItem = akLayerRef.kLastCreatedItem
	ObjectReference kNextRef = kLastCreatedItem
	while(kNextRef)
		kNextRef.OnHolotapeChatter("WorkshopPlus.esp", afChatterCode)
		
		kNextRef = kNextRef.GetLinkedRef(LayerItemLinkChainKeyword)
	endWhile
EndFunction



Function BreakInfiniteLinkedLayers(Bool abTriggeredManually = false)
	WorkshopPlus:SettlementLayers LocalLayers = GetCurrentSettlementLayers()
	
	if(abTriggeredManually)
		HUDFrameworkManager.CreateProgressBar(Self, "LayerRepair", "Repairing Layers")
	endif
	
	int i = 0
	while(i < LocalLayers.Layers.Length)
		ObjectReference kLastCreatedItem = LocalLayers.Layers[i].kLastCreatedItem
		BreakInfiniteLinks(kLastCreatedItem)
		
		if(abTriggeredManually)
			HUDFrameworkManager.UpdateProgressBarPercentage(Self, "LayerRepair", Math.Floor((i as Float/LocalLayers.Layers.Length as Float) * 100))
		endif
		
		i += 1
	endWhile
	
	if(abTriggeredManually)
		HUDFrameworkManager.CompleteProgressBar(Self, "LayerRepair")
	endif
EndFunction


Function BreakInfiniteLinks(ObjectReference akObjectToCheck)
	ObjectReference kNextRef = akObjectToCheck
	Float fHoldLayerID = kNextRef.GetValue(LayerID)
	
	while(kNextRef)
		ObjectReference kLinkedRef = kNextRef.GetLinkedRef(LayerItemLinkChainKeyword)
		if(kLinkedRef == kNextRef || kLinkedRef.GetValue(LayerID) == -999.0) ; Same ref, or linked to an item that was already linked earlier in the chain
			kNextRef.SetLinkedRef(None, LayerItemLinkChainKeyword)
			kNextRef.SetValue(LayerID, fHoldLayerID) ; Restore layer ID
			kNextRef = None
		else
			kNextRef.SetValue(LayerID, -999.0) ; Temporarily set layer ID so we know this item was already found linked in this layer
			kNextRef = kLinkedRef
		endif
	endWhile
	
	; Restore layer ID to all items
	kNextRef = akObjectToCheck
	while(kNextRef)
		kNextRef.SetValue(LayerID, fHoldLayerID)
		kNextRef = kNextRef.GetLinkedRef(LayerItemLinkChainKeyword)
	endWhile
EndFunction


WorkshopPlus:SettlementLayers Function GetCurrentSettlementLayers()
	if( ! CurrentSettlementLayers)
		CurrentSettlementLayers = ResourceManager.Workshops[gCurrentWorkshop.GetValueInt()].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
	endif
	
	return CurrentSettlementLayers
EndFunction

Bool Function CanBeAddedToLayer(ObjectReference akNewItem)
	; 1.0.2 - Short this if None sent
	if( ! akNewItem || akNewItem.HasKeyword(PreventAddingToLayersKeyword) || akNewItem.HasKeyword(AddedToLayerKeyword) || akNewItem.HasKeyword(LayerHandleKeyword) || akNewItem.HasKeyword(WorkshopKeyword) || (akNewItem as Actor && ! (akNewItem as WorkshopObjectActorScript)))
		return false
	endif
	
	return true
EndFunction


Function AddItemToLayer_Lock(ObjectReference akNewItem, WorkshopPlus:WorkshopLayer akLayerRef = None, Bool abGetLock = true)
	if( ! CanBeAddedToLayer(akNewItem))
		ModTrace("[WS Plus] Unable to add item " + akNewItem + " to layer " + akLayerRef + ", failed CanBeAddedToLayer check.")
		
		return
	endif
	
	WorkshopPlus:SettlementLayers localLayerHolder = GetLayerHolderFromLayer(akLayerRef)
	if( ! akLayerRef)
		akLayerRef = CurrentSettlementLayers.ActiveLayer
	elseif( ! akLayerRef.bEnabled) ; 1.0.1 - Make sure we don't add items to a disabled layer
		; This layer is disabled, add to that settlement's default layer
		if(localLayerHolder)
			akLayerRef = localLayerHolder.DefaultLayer
			
			if(akLayerRef == None || ! akLayerRef.bEnabled)
				ModTrace("[WS Plus] Unable to add item " + akNewItem + " to layer " + akLayerRef + ", layer missing or disabled.")
				return
			endif
		else
			ModTrace("[WS Plus] Unable to add item " + akNewItem + " to layer " + akLayerRef + ", could not find settlement layer holder reference.")
			return
		endif
	endif
	
	ModTrace("[WS Plus] Adding item " + akNewItem + " to layer " + akLayerRef)
	
	; Get Edit Lock 
	int iLockKey
	if(abGetLock)
		iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
	endif

	; 1.0.3 - adding counter
	akLayerRef.iItemCount += 1
	
	; Set AV to mark item with layer ID in case we need to rebuild the linked ref chain, or in the future, we might need to allow certain items to be pulled from the ref chain so they aren't disabled/enabled
	akNewItem.SetValue(LayerID, akLayerRef.iLayerID)

	; Tag item so it doesn't ever get added to multiple layers simultaneously
	akNewItem.AddKeyword(AddedToLayerKeyword)

	; Flash items as they are added to the layer
	if(Setting_HighlightItemsAddedToLayer.GetValue() == 1 && localLayerHolder && (akLayerRef != localLayerHolder.DefaultLayer || Setting_HighlightItemsAddedToDefaultLayer.GetValue() == 1))
		; 1.0.4 - Only do so if the player has turned on the highlight items added to default layer option
		ShaderFlashLayer.Play(akNewItem, 2.0)
	endif

	; Add item to end of linked ref chain
	ObjectReference kPreviousItem = akLayerRef.kLastCreatedItem
	akLayerRef.kLastCreatedItem = akNewItem
	
	if(kPreviousItem && akNewItem != kPreviousItem) ; Make sure items don't link to themselves
		akNewItem.SetLinkedRef(kPreviousItem, LayerItemLinkChainKeyword)
	endif
	
	; Handle linking
	if( ! akLayerRef.bLinked)
		akNewItem.SetLinkedRef(None, WorkshopItemKeyword)
	elseif(akNewItem.GetLinkedRef(WorkshopItemKeyword) == None)
		WorkshopScript thisWorkshop = ResourceManager.Workshops[CurrentSettlementLayers.iWorkshopID]
		if(thisWorkshop)
			akNewItem.SetLinkedRef(thisWorkshop, WorkshopItemKeyword)
		endif
	endif

	; 1.0.3 - When building copies of blueprints, we're temporarily using the blueprint controller as the handle, so we can't attach here
	if(akLayerRef != BlueprintManager.BuildingBlueprintOnLayerRef)
		; 1.0.2 - Support for layer handles
		if(akLayerRef.LayerHandle && ActionManager.kGrabbedRef != (akLayerRef.LayerHandle as WorkshopPlus:ObjectReferences:LayerHandle).kControlledRef)
			akNewItem.SetLinkedRef(akLayerRef.LayerHandle, HandleLinkKeyword)
		endif
	endif

	if( ! akLayerRef.bShown)
		akNewItem.Disable(false)
	elseif(akLayerRef.CurrentHighlightShader != None)
		akLayerRef.CurrentHighlightShader.Play(akNewItem, -1.0)
	endif
	
	; Release Edit Lock
	if(abGetLock)
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndFunction


Function RemoveItemFromLayer_Lock(ObjectReference akRemoveItemRef, WorkshopPlus:WorkshopLayer akRemoveFromLayerRef = None, WorkshopPlus:WorkshopLayer akNewLayerRef = None, Bool abGetLock = true)
	if( ! akRemoveFromLayerRef)
		akRemoveFromLayerRef = CurrentSettlementLayers.ActiveLayer
	endif
	
	ModTrace("[WS Plus] Removing item " + akRemoveItemRef + " from layer " + akRemoveFromLayerRef + ", moving to " + akNewLayerRef)
	
	; Get Edit Lock 
	int iLockKey 
	if(abGetLock)
		iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
	endif
	
	; 1.0.3 - adding counter
	akRemoveFromLayerRef.iItemCount -= 1
	
	; Untag item so it can be added to a new layer in the future
	akRemoveItemRef.RemoveKeyword(AddedToLayerKeyword)
	
	; Find item this is linked to in chain
	ObjectReference kChainParentRef = akRemoveItemRef.GetLinkedRef(LayerItemLinkChainKeyword)
	; Find child linked refs (should only be one)
	ObjectReference kChainChildRef = None
	ObjectReference[] kChainChildrenRefs = akRemoveItemRef.GetLinkedRefChildren(LayerItemLinkChainKeyword)
	if(kChainChildrenRefs.Length > 0)
		kChainChildRef = kChainChildrenRefs[0]
	endif
	
	; Clear link to parent
	akRemoveItemRef.SetLinkedRef(None, LayerItemLinkChainKeyword)
	
	; Attach parent to child so there is no gap in the chain
	if(kChainChildRef)
		; Link child to parent 
		kChainChildRef.SetLinkedRef(kChainParentRef, LayerItemLinkChainKeyword)
	endif
	
	; If this was the last created item, pass that throne on to the next item up the chain
	if(akRemoveItemRef == akRemoveFromLayerRef.kLastCreatedItem)
		akRemoveFromLayerRef.kLastCreatedItem = kChainParentRef
	endif
	
	; 1.0.2 - Support for layer handles
	akRemoveItemRef.SetLinkedRef(None, HandleLinkKeyword)
	
	if(akRemoveFromLayerRef.CurrentHighlightShader != None)
		akRemoveFromLayerRef.CurrentHighlightShader.Stop(akRemoveItemRef)
	endif
	
	if(akNewLayerRef)
		AddItemToLayer_Lock(akRemoveItemRef, akNewLayerRef, abGetLock = false)
	else
		akRemoveItemRef.SetValue(LayerID, 0.0)
	endif
	
	
	if(abGetLock)
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif
EndFunction


Function HideMultipleLayers_Lock(Bool bInactiveOnly = false)
	ModTrace("[WS Plus] HideMultipleLayers called... ")
	int iCurrentWorkshopID = gCurrentWorkshop.GetValueInt()
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
		return
	endif
	
	if(CurrentSettlementLayers.iWorkshopID != iCurrentWorkshopID)
		CurrentSettlementLayers = ResourceManager.Workshops[iCurrentWorkshopID].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if( ! CurrentSettlementLayers)
			ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
			return
		endif
	endif
	
	int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("Unable to get lock!", 2)
		
		return
	endif
	
	if(Setting_PlayLayerSounds.GetValue() == 1)
		HideMultipleLayersSound.Play(PlayerRef)
	endif
	
	; Default Layer
	if( ! bInactiveOnly || ! CurrentSettlementLayers.DefaultLayer.bActive)
		HideLayer_Lock(CurrentSettlementLayers.DefaultLayer, false, abMultiHide = true)
	endif
	
	; Other Layers
	int i = 0
	while(i < CurrentSettlementLayers.Layers.Length)
		if( ! bInactiveOnly || ! CurrentSettlementLayers.Layers[i].bActive)
			HideLayer_Lock(CurrentSettlementLayers.Layers[i], false, abMultiHide = true)
		endif
	
		i += 1
	endWhile	
	
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("Failed to release lock " + iLockKey + "!", 2)
	endif
EndFunction


Function ShowMultipleLayers_Lock()
	ModTrace("[WS Plus] ShowMultipleLayers called...")
	int iCurrentWorkshopID = gCurrentWorkshop.GetValueInt()
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
		return
	endif
	
	if(CurrentSettlementLayers.iWorkshopID != iCurrentWorkshopID)
		CurrentSettlementLayers = ResourceManager.Workshops[iCurrentWorkshopID].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if( ! CurrentSettlementLayers)
			ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
			return
		endif
	endif
	
	int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("Unable to get lock!", 2)
		
		return
	endif
	
	if(Setting_PlayLayerSounds.GetValue() == 1)
		UnhideMultipleLayersSound.Play(PlayerRef)
	endif
		
	; Default Layer
	ShowLayer_Lock(CurrentSettlementLayers.DefaultLayer, false, abMultiShow = true)
	
	; Other Layers
	int i = 0
	while(i < CurrentSettlementLayers.Layers.Length)
		ShowLayer_Lock(CurrentSettlementLayers.Layers[i], false, abMultiShow = true)
	
		i += 1
	endWhile	
	
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("Failed to release lock " + iLockKey + "!", 2)
	endif
EndFunction


Function HighlightActiveLayer(Bool abActiveShader = false)
	EffectShader ShaderToApply = ShaderHighlightLayer
	if(abActiveShader)
		ShaderToApply = ShaderActiveLayer
	endif
	
	HighlightLayerItems(CurrentSettlementLayers.ActiveLayer, ShaderToApply)
EndFunction

Function ClearActiveLayerHighlight()
	ModTrace("[WS Plus] ClearActiveLayerHighlight called...")
	HighlightLayerItems(CurrentSettlementLayers.ActiveLayer, None, true)
EndFunction

Function ClearAllHighlighting()
	ModTrace("[WS Plus] ClearAllHighlighting called...")
	
	if(Setting_PlayLayerSounds.GetValue() == 1)
		UnhighlightLayerSound.Play(PlayerRef)
	endif
	
	; Default Layer
	HighlightLayerItems(CurrentSettlementLayers.DefaultLayer, None, true, abMultiHighlight = true)
	
	; Other Layers
	int i = 0
	while(i < CurrentSettlementLayers.Layers.Length)
		HighlightLayerItems(CurrentSettlementLayers.Layers[i], None, true, abMultiHighlight = true)
	
		i += 1
	endWhile
EndFunction

Function HighlightLayerItems(WorkshopPlus:WorkshopLayer akLayerRef = None, EffectShader aShader = None, Bool abClearHighlights = false, Bool abMultiHighlight = false)
	ModTrace("[WS Plus] HighlightLayerItems called..." + akLayerRef + ", Shader: " + aShader + "; abClearHighlights: " + abClearHighlights)
	if( ! akLayerRef)
		akLayerRef = CurrentSettlementLayers.ActiveLayer
	endif
	
	if(abClearHighlights)
		if( ! abMultiHighlight)
			if(Setting_PlayLayerSounds.GetValue() == 1)
				UnhighlightLayerSound.Play(PlayerRef)
			endif
		endif
		
		if( ! aShader && akLayerRef.CurrentHighlightShader != None) ; 1.0.6 - Just grab the shader - if none found exit instead of iterating all items
			aShader = akLayerRef.CurrentHighlightShader
		endif
		
		if(aShader)
			ObjectReference kNextRef = akLayerRef.kLastCreatedItem
			while(kNextRef)
				aShader.Stop(kNextRef)
				
				kNextRef = kNextRef.GetLinkedRef(LayerItemLinkChainKeyword)
			endWhile
		endif
		
		akLayerRef.CurrentHighlightShader = None
	else
		if( ! aShader)
			aShader = ShaderHighlightLayer
		endif
			
		if(akLayerRef.CurrentHighlightShader != aShader)
			if(akLayerRef.CurrentHighlightShader != None)
				; First clear previous
				HighlightLayerItems(akLayerRef, None, true)
			endif
			
			if( ! abMultiHighlight)
				if(Setting_PlayLayerSounds.GetValue() == 1)
					HighlightLayerSound.Play(PlayerRef)
				endif
			endif
			
			ObjectReference kNextRef = akLayerRef.kLastCreatedItem
			while(kNextRef)
				aShader.Play(kNextRef, -1.0)
				
				kNextRef = kNextRef.GetLinkedRef(LayerItemLinkChainKeyword)
			endWhile
			
			akLayerRef.CurrentHighlightShader = aShader
		endif
	endif
EndFunction


Function SwitchToNextLayer()
	ModTrace("[WS Plus] SwitchToNextLayer called...")
	int iCurrentWorkshopID = gCurrentWorkshop.GetValueInt()
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
		return
	endif
	
	if(CurrentSettlementLayers.iWorkshopID != iCurrentWorkshopID)
		CurrentSettlementLayers = ResourceManager.Workshops[iCurrentWorkshopID].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if( ! CurrentSettlementLayers)
			ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
			return
		endif
	endif
	
	
	; If default, switch to first layer in Layers array
	if(CurrentSettlementLayers.ActiveLayer == CurrentSettlementLayers.DefaultLayer)
		if(CurrentSettlementLayers.Layers.Length > 0)
			int i = 0
			int iNextEnabledIndex = -1
			while(i < CurrentSettlementLayers.Layers.Length && iNextEnabledIndex < 0)
				if(CurrentSettlementLayers.Layers[i].bEnabled)
					iNextEnabledIndex = i
				endif
				
				i += 1
			endWhile
		
			if(iNextEnabledIndex >= 0)
				MakeActiveLayer(CurrentSettlementLayers.Layers[iNextEnabledIndex])
			else
				NoOtherLayersToSwitchTo.Show()
				return
			endif
		else
			NoOtherLayersToSwitchTo.Show()
		endif
	else
		if(CurrentSettlementLayers.Layers.Length > 0)
			int iIndex = CurrentSettlementLayers.Layers.Find(CurrentSettlementLayers.ActiveLayer)
			
			; 1.0.2 - Fixed some logic in this code
			int i = iIndex + 1
			int iNextEnabledIndex = -1
			while(i < CurrentSettlementLayers.Layers.Length && iNextEnabledIndex < 0)
				if(CurrentSettlementLayers.Layers[i].bEnabled)
					iNextEnabledIndex = i
				endif
				
				i += 1
			endWhile
		
			if(iNextEnabledIndex >= 0 && iNextEnabledIndex != iIndex)
				MakeActiveLayer(CurrentSettlementLayers.Layers[iNextEnabledIndex])
			else
				MakeActiveLayer(CurrentSettlementLayers.DefaultLayer)
			endif
		else
			NoOtherLayersToSwitchTo.Show()
		endif
	endif
EndFunction

Function CreateNewLayer()
	ModTrace("[WS Plus] CreateNewLayer called...")
	int iCurrentWorkshopID = gCurrentWorkshop.GetValueInt()
	
	if( ! CurrentSettlementLayers)
		ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
		return
	endif
	
	if(CurrentSettlementLayers.iWorkshopID != iCurrentWorkshopID)
		CurrentSettlementLayers = ResourceManager.Workshops[iCurrentWorkshopID].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
		
		if( ! CurrentSettlementLayers)
			ModTrace("[WSPlus] Missing layer holder for settlement " + ResourceManager.Workshops[iCurrentWorkshopID] + ".", 2)
		
			return
		endif
	endif
		
	; Confirm there are less than iMaxLayers layers in array
	if( ! TryToActivateDisabledLayer())
		if(CurrentSettlementLayers.Layers.Length >= iMaxLayers)
			NoMoreLayersAllowed.Show(iMaxLayers as Float)
		
			return			
		else
			AddLayer()
		endif
	endif
EndFunction


Bool Function TryToActivateDisabledLayer()
	int i = 0
	while(i < CurrentSettlementLayers.Layers.Length)
		if( ! CurrentSettlementLayers.Layers[i].bEnabled)
			CurrentSettlementLayers.Layers[i].bEnabled = true
			MakeActiveLayer(CurrentSettlementLayers.Layers[i])
			
			return true
		endif
		
		i += 1
	endWhile
	
	return false
EndFunction


Int Function DisplayLayerSelect(Bool abAllowCancel = true, Bool abExcludeCurrentLayer = true)
	int iActiveLayerIndex = -2
	
	if(abExcludeCurrentLayer)
		if(CurrentSettlementLayers.ActiveLayer == CurrentSettlementLayers.DefaultLayer)
			iActiveLayerIndex = -1
		else
			iActiveLayerIndex = CurrentSettlementLayers.Layers.Find(CurrentSettlementLayers.ActiveLayer)
		endif
	endif
	
	if(abAllowCancel)
		AllowLayerHandlingCancellation.SetValue(1)
	else
		; When the layer ref is deleted externally, we have no choice but to move or scrap the items
		AllowLayerHandlingCancellation.SetValue(0)
	endif
	
	CurrentActiveLayerIndex.SetValue(iActiveLayerIndex)
	CurrentLayerCount.SetValue(CurrentSettlementLayers.Layers.Length)
	
	; 1.0.4 - Changing layer select display to individual controls
	int i = 0
	while(i < iMaxLayers)
		if(CurrentSettlementLayers.Layers.Length > i)
			if( ! CurrentSettlementLayers.Layers[i].bEnabled || abExcludeCurrentLayer && i == iActiveLayerIndex)
				gIncludeLayersInMenu[i].SetValue(0.0)
			else
				gIncludeLayersInMenu[i].SetValue(1.0)
			endif
		else
			gIncludeLayersInMenu[i].SetValue(0.0)
		endif
		
		i += 1
	endWhile
	
	
	return LayerSelect.Show()
EndFunction


Function DisableActiveLayer()
	ModTrace("[WS Plus] DisableActiveLayer called...")
	DisableLayer_Lock(CurrentSettlementLayers.ActiveLayer)
EndFunction

Function DisableLayer_Lock(WorkshopPlus:WorkshopLayer akLayerRef)
	ModTrace("[WS Plus] DisableLayer called..." + akLayerRef)
	if(akLayerRef == CurrentSettlementLayers.DefaultLayer)
		CannotDeleteDefaultLayer.Show()
		
		LayerDeleted(akLayerRef, true)
	else
		Bool bPromptPlayer = true
		if(akLayerRef.kLastCreatedItem == None) ; No items to worry about, just remove the layer
			bPromptPlayer = false
		endif
		
		if(LayerDeleted(akLayerRef, abPromptPlayer = bPromptPlayer))
			UpdateLayerOnHUD(akLayerRef, abDelete = true)
			
			if(Setting_PlayLayerSounds.GetValue() == 1)
				DisableLayerSound.Play(PlayerRef)
			endif
	
			akLayerRef.bDeletedByManager = true ; Prevent infinite loop of LayerDeleted being called
			
			akLayerRef.bEnabled = false
			
			if( ! bPromptPlayer)
				SwitchToNextLayer()
			endif
		endif
	endif
EndFunction


Bool Function LayerDeleted(WorkshopPlus:WorkshopLayer akLayerRef, Bool abPromptPlayer = false, Bool abPlayerInitiatedDeletion = true)
	; Handle clearing out layer - separating this function from DeleteLayer and ClearLayer so that we can call it if the WorkshopLayer ref is disabled from an outside source
	WorkshopPlus:WorkshopLayer kMoveItemsToLayerRef = None
	if(abPromptPlayer)
		; Prompt player and ask them to choose a layer or scrap all of the items
		if(abPlayerInitiatedDeletion)
			AllowLayerHandlingCancellation.SetValue(1.0)
		else
			AllowLayerHandlingCancellation.SetValue(0.0)
			
			; This was deleted externally, create a new ref so we don't offset our array
			int iLayerIndex = CurrentSettlementLayers.Layers.Find(akLayerRef)
			WorkshopPlus:WorkshopLayer kNewLayerRef = CreateLayer_Lock()
			
			if(kNewLayerRef)
				; Leave layer disabled and just override previous object ref
				CurrentSettlementLayers.Layers[iLayerIndex] = kNewLayerRef
			endif
		endif
		
		int iConfirm = ScrapOrMoveItemsConfirmation.Show()
		
		; iConfirm == 0 ; Cancel 
		if(iConfirm == 0)
			return false
		elseif(iConfirm == 1) ; Move Items
			iConfirm = DisplayLayerSelect(abAllowCancel = abPlayerInitiatedDeletion)
			
			; Message Entries 0 = Cancel; 1 = Default Layer
			
			if(iConfirm == 0)
				return false; Canceled
			elseif(iConfirm == 1)
				kMoveItemsToLayerRef = CurrentSettlementLayers.DefaultLayer
			else
				kMoveItemsToLayerRef = CurrentSettlementLayers.Layers[(iConfirm - 2)]
				
				if(kMoveItemsToLayerRef == None)
					CouldNotFindTheLayerYouSelectedUsingDefaultLayer.Show()
					; We couldn't find the layer, so just move to default layer
					kMoveItemsToLayerRef = CurrentSettlementLayers.DefaultLayer
				endif
			endif
		else ; Scrap items
			kMoveItemsToLayerRef = None
		endif		
	endif
	
	if(akLayerRef.LayerHandle)
		; Scrap the handle
		WorkshopFramework:ObjectRefs:Thread_ScrapObject kThreadRef = ThreadManager.CreateThread(Thread_ScrapObject) as WorkshopFramework:ObjectRefs:Thread_ScrapObject
				
		if(kThreadRef)
			kThreadRef.kScrapMe = akLayerRef.LayerHandle
			akLayerRef.LayerHandle = None
			
			ThreadManager.QueueThread(kThreadRef)
		endif
	endif
	
	ClearLayer_Lock(akLayerRef, kMoveItemsToLayerRef)
	
	; Ensure we switch to a logical layer
	if(abPromptPlayer)
		if(kMoveItemsToLayerRef != None)
			MakeActiveLayer(kMoveItemsToLayerRef)
		else
			SwitchToNextLayer()
		endif
	endif
	
	
	return true
EndFunction


Function LayerHolderDeleted(WorkshopPlus:SettlementLayers akLayerHolderRef, Bool abIntentionalDeletion = true)
	if( ! abIntentionalDeletion)
		Debug.MessageBox("An important object required by Workshop Plus was destroyed by a third party mod. Workshop Plus will attempt to recover the data. If you see this message repeatedly, you likely have a conflicting mod.")
		; Try and create a new one and pass all the data over
		if(akLayerHolderRef.iWorkshopID > -1)
			WorkshopScript thisWorkshop = ResourceManager.Workshops[akLayerHolderRef.iWorkshopID]
			
			ObjectReference kSpawnAt = SafeSpawnPoint.GetRef()
	
			if(thisWorkshop && kSpawnAt)
				WorkshopPlus:SettlementLayers kNewLayerHolder = kSpawnAt.PlaceAtMe(SettlementLayersHolderForm, abDeleteWhenAble = false) as WorkshopPlus:SettlementLayers
				
				kNewLayerHolder.DefaultLayer = akLayerHolderRef.DefaultLayer
				kNewLayerHolder.ActiveLayer = akLayerHolderRef.ActiveLayer
				kNewLayerHolder.iWorkshopID = akLayerHolderRef.iWorkshopID
				kNewLayerHolder.Layers = new WorkshopPlus:WorkshopLayer[0]
				
				int i = 0
				while(i < akLayerHolderRef.Layers.Length)
					kNewLayerHolder.Layers.Add(akLayerHolderRef.Layers[i])
					
					i += 1
				endWhile
				
				thisWorkshop.SetLinkedRef(kNewLayerHolder, LayerHolderLinkKeyword)
			endif
		endif
	endif
EndFunction


Function DuplicateActiveLayer_Lock()
	ModTrace("[WS Plus] DuplicateActiveLayer called...")
	if(CurrentSettlementLayers.ActiveLayer.kLastCreatedItem == None)
		NoItemsOnThisLayerToDuplicate.Show()
		return
	endif

	
	WorkshopScript thisWorkshop = ResourceManager.Workshops[CurrentSettlementLayers.iWorkshopID]
	
	if( ! thisWorkshop)
		ModTrace("[WS Plus] Failed to find workshop. Could not run DuplicateActiveLayer.")
		
		return
	endif
	
	if(bDuplicateLayerBlock)
		DuplicateActiveLayerInProgress.Show()
		return
	endif
	
	bDuplicateLayerBlock = true ; Note: Do not set this to false until processing of creation events is complete
	
	Int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("Unable to get lock!", 2)
		bDuplicateLayerBlock = false
		return
	endif
	
	ObjectReference kCopyMe = CurrentSettlementLayers.ActiveLayer.kLastCreatedItem
	
	; Store our current layer for comparison
	WorkshopPlus:WorkshopLayer kCopyFromLayerRef = CurrentSettlementLayers.ActiveLayer
	; Get current layer index - we'll count not found as the default layer - in which case -1 will work for our purposes
	Int iActiveLayerIndex = CurrentSettlementLayers.Layers.Find(kCopyFromLayerRef)
	
	; Attempt to create a layer, if none available - offer to copy items to an existing layer
	; Add Layer
	if( ! TryToActivateDisabledLayer())
		AddLayer(abGetLock = false)
	endif
	; Now lets compare and make sure a layer was added
	WorkshopPlus:WorkshopLayer kCopyToLayerRef = CurrentSettlementLayers.ActiveLayer
	Int iTargetLayerIndex = CurrentSettlementLayers.Layers.Find(kCopyToLayerRef)
	
	if(kCopyFromLayerRef == kCopyToLayerRef)
		; Offer layer select
		CurrentActiveLayerIndex.SetValue(iActiveLayerIndex) ; Make sure the current layer isn't offered or it will create an infinite loop
		CurrentLayerCount.SetValue(CurrentSettlementLayers.Layers.Length)
		
		Int iSelect = DuplicateActiveLayerChooseTargetLayerConfirm.Show()
		
		if(iSelect == 0)
			; Canceled
			bDuplicateLayerBlock = false
		else
			iSelect = DisplayLayerSelect(true, false)
			
			if(iSelect <= 0)
				; Canceled layer select
				bDuplicateLayerBlock = false
			elseif(iSelect == 1)
				iTargetLayerIndex = 0
			else
				iTargetLayerIndex = iSelect - 1
			endif
		endif
	else
		; We need to reframe the index based on the fact that the RefCollections are indexed with 0 = Default Layer
		if(iTargetLayerIndex < 0)
			iTargetLayerIndex = 0
		else
			iTargetLayerIndex += 1
		endif
	endif
	
	if(bDuplicateLayerBlock && kCopyToLayerRef)
		; 1.0.2 - Threading the entire operation
		if(kCopyMe.GetLinkedRef(LayerItemLinkChainKeyword) != None)
			; At least two items, set up an UndoHelper - Note this will overwrite the last one for this layer, so if the player tries to spam this, they will have issues with items not ending up part of the undo block
			ActionManager.PrepareUndoHelper(CurrentSettlementLayers.iWorkshopID, iTargetLayerIndex)
			
			while(kCopyMe != None)
				ActionManager.CloneWorkshopObject_Threaded(kCopyMe, thisWorkshop, iTargetLayerIndex)
				
				kCopyMe = kCopyMe.GetLinkedRef(LayerItemLinkChainKeyword)
			endWhile	
		else
			; Single item, just use ActionManager's simple clone
			ActionManager.CloneWorkshopObject(kCopyMe, thisWorkshop)
		endif		
	endif	
	
	bDuplicateLayerBlock = false	
		
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("Failed to release lock " + iLockKey + "!", 2)
	endif
	
	DuplicateActiveLayerComplete.Show()
EndFunction



Function ClearActiveLayer()
	ModTrace("[WS Plus] ClearActiveLayer called...")
	WorkshopPlus:WorkshopLayer kMoveItemsToLayerRef = None
	
	; Prompt player and ask them to choose a layer or scrap all of the items
	AllowLayerHandlingCancellation.SetValue(1.0)
	
	int iConfirm = ScrapOrMoveItemsConfirmation.Show()
	
	; iConfirm == 0 ; Cancel 
	if(iConfirm == 0)
		return
	elseif(iConfirm == 1) ; Move Items
		iConfirm = DisplayLayerSelect(true)
		
		; Message Entries 0 = Cancel; 1 = Default Layer
		
		if(iConfirm == 0)
			return ; Canceled
		elseif(iConfirm == 1)
			kMoveItemsToLayerRef = CurrentSettlementLayers.DefaultLayer
		else
			kMoveItemsToLayerRef = CurrentSettlementLayers.Layers[(iConfirm - 2)]
			
			if( ! kMoveItemsToLayerRef)
				CouldNotFindTheLayerYouSelectedUsingDefaultLayer.Show()
				; We couldn't find the layer, so just move to default layer
				kMoveItemsToLayerRef = CurrentSettlementLayers.DefaultLayer
			endif
		endif
	else ; Scrap items
		kMoveItemsToLayerRef = None
	endif
	
	ClearLayer_Lock(CurrentSettlementLayers.ActiveLayer, kMoveItemsToLayerRef)
EndFunction


Function ClearLayer_Lock(WorkshopPlus:WorkshopLayer akLayerRef, WorkshopPlus:WorkshopLayer akMoveItemsToLayerRef = None)
	ModTrace("[WS Plus] ClearLayer: " + akLayerRef + ", Moving To: " + akMoveItemsToLayerRef)
	
	if(akLayerRef)
		int iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
	
		ObjectReference kNextRef = akLayerRef.kLastCreatedItem
		while(kNextRef)
			ObjectReference kThisRef = kNextRef
			kNextRef = kThisRef.GetLinkedRef(LayerItemLinkChainKeyword)
			
			kThisRef.SetLinkedRef(None, LayerItemLinkChainKeyword)
			kThisRef.RemoveKeyword(AddedToLayerKeyword)
			
			if(akMoveItemsToLayerRef != None)
				ModTrace("ClearLayer_Lock adding " + kThisRef + " to layer " + akMoveItemsToLayerRef)
				
				AddItemToLayer_Lock(kThisRef, akMoveItemsToLayerRef, abGetLock = false)
			else
				WorkshopFramework:ObjectRefs:Thread_ScrapObject kThreadRef = ThreadManager.CreateThread(Thread_ScrapObject) as WorkshopFramework:ObjectRefs:Thread_ScrapObject
				
				if(kThreadRef)
					kThreadRef.kScrapMe = kThisRef
					
					ThreadManager.QueueThread(kThreadRef)
				endif				
			endif			
		endWhile
		
		; All items removed from layer
		akLayerRef.kLastCreatedItem = None
		
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif	
EndFunction


Function RemoveAllLayers()
	int iConfirm = RemoveAllLayersConfirmation.Show()
	
	if(iConfirm == 1)
		; Show all items
		ShowMultipleLayers_Lock()
		
		; Move all items to default layer
		int i = 0
		while(i < CurrentSettlementLayers.Layers.Length)
			ClearLayer_Lock(CurrentSettlementLayers.Layers[i], CurrentSettlementLayers.DefaultLayer)
			
			i += 1
		endWhile
		
		; Clear all highlighting
		ClearAllHighlighting()
		
		; Disable all layers
		i = 0
		while(i < CurrentSettlementLayers.Layers.Length)
			DisableLayer_Lock(CurrentSettlementLayers.Layers[i])
			
			i += 1
		endWhile
	endif
EndFunction


Function PlaceLayerHandle(ObjectReference akPlaceAtRef)
	if( ! akPlaceAtRef)
		akPlaceAtRef = PlayerRef
	endif
	
	WorldObject thisWorldObject = new WorldObject
	
	thisWorldObject.ObjectForm = PlaceableLayerHandleForm
	
	if(akPlaceAtRef == PlayerRef)
		; Place in front of the player
		Float fDistanceInFrontOfPlayer = 256.0
		Float fPlayerAngle = PlayerRef.GetAngleZ()
		
		Float fPlayerPosX = PlayerRef.X
		Float fPlayerPosY = PlayerRef.Y
		Float fPlayerPosZ = PlayerRef.Z
		
		thisWorldObject.fPosX = fPlayerPosX + fDistanceInFrontOfPlayer*Math.Sin(fPlayerAngle)
		thisWorldObject.fPosY = fPlayerPosY + fDistanceInFrontOfPlayer*Math.Cos(fPlayerAngle)
		thisWorldObject.fPosZ = fPlayerPosZ
	else
		thisWorldObject.fPosX = akPlaceAtRef.X
		thisWorldObject.fPosY = akPlaceAtRef.Y
		thisWorldObject.fPosZ = akPlaceAtRef.Z
	endif
	
	PlaceObjectManager.CreateObjectImmediately(thisWorldObject, GetNearestWorkshop(PlayerRef))
EndFunction


; Added 1.0.4 - Will find all items not on a layer yet and add them to the selected layer. This is replacing the automatic system that had been running when players arrived at a settlement
Function AddPreviousItemsToLayer_Lock(WorkshopScript akWorkshopRef = None)
	if( ! akWorkshopRef)
		akWorkshopRef = GetNearestWorkshop(PlayerRef)
	endif
	
	if( ! akWorkshopRef)
		CouldNotFindSettlement.Show()
		
		return
	endif
	
	WorkshopPlus:WorkshopLayer kMoveItemsToLayerRef = None
	
	int iConfirm = DisplayLayerSelect(true, false)
	
	; Message Entries 0 = Cancel; 1 = Default Layer
	if(iConfirm == 0)
		return ; Canceled
	elseif(iConfirm == 1)
		kMoveItemsToLayerRef = CurrentSettlementLayers.DefaultLayer
	else
		kMoveItemsToLayerRef = CurrentSettlementLayers.Layers[(iConfirm - 2)]
		
		if( ! kMoveItemsToLayerRef)
			CouldNotFindTheLayerYouSelectedUsingDefaultLayer.Show()
			; We couldn't find the layer, so just move to default layer
			kMoveItemsToLayerRef = CurrentSettlementLayers.DefaultLayer
		endif
	endif
	
	if( ! kMoveItemsToLayerRef)
		NoLayerFoundToMoveItemsTo.Show()
		return
	endif
	
	int iLockKey = GetLock()
	if(iLockKey <= GENERICLOCK_KEY_NONE)
		ModTrace("Unable to get lock!", 2)
		
		return
	endif
	
	ObjectReference[] kExistingObjects = akWorkshopRef.GetLinkedRefChildren(WorkshopItemKeyword)
			
	int i = 0
	while(i < kExistingObjects.Length)
		if(kExistingObjects[i].GetValue(LayerID) == 0.0)
			AddItemToLayer_Lock(kExistingObjects[i], kMoveItemsToLayerRef, abGetLock = false)
		endif
		
		i += 1
	endWhile
	
	; Release Edit Lock
	if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
		ModTrace("Failed to release lock " + iLockKey + "!", 2)
	endif
EndFunction


Function ShowControlMenu()
	int iOption = LayerControlMenu.Show()
	
	if(iOption == 0)
		; Switch Active Layer
		SwitchToNextLayer()
	elseif(iOption == 1)
		; Create Layer
		CreateNewLayer()
	elseif(iOption == 2)
		; Show/Hide layer
		ToggleActiveLayer()
	elseif(iOption == 3)
		; Toggle Active Layer Highlighting
		if(CurrentSettlementLayers.ActiveLayer.CurrentHighlightShader == ShaderActiveLayer)
			ClearActiveLayerHighlight()
		else
			HighlightActiveLayer(true)
		endif
	elseif(iOption == 4)
		; Duplicate Layer
		int iConfirm = DuplicateActiveLayerConfirm.Show()
		if(iConfirm == 1)
			DuplicateActiveLayer_Lock()
		endif
	elseif(iOption == 5)
		; Clear Active Layer
		ClearActiveLayer()
	elseif(iOption == 6)
		; Show All Layers
		ShowMultipleLayers_Lock() ; Interfacing this in case we think up more use cases
	elseif(iOption == 7) ; Advanced
		iOption = LayerControlMenu_Advanced.Show()
		
		if(iOption == 0) ; Go Back
			ShowControlMenu()
		elseif(iOption == 1)
			; Highlight Layer
			HighlightActiveLayer(false)
		elseif(iOption == 2)
			; Clear highlighting
			ClearActiveLayerHighlight()
		elseif(iOption == 3)
			; Clear all highlighting
			ClearAllHighlighting()
		elseif(iOption == 4)
			; Hide inactive layers
			HideMultipleLayers_Lock(bInactiveOnly = true)
		elseif(iOption == 5)
			; Hide all layers
			HideMultipleLayers_Lock(bInactiveOnly = false)
		elseif(iOption == 6) ; Added 1.0.4
			; Add previous items to a layer
			AddPreviousItemsToLayer_Lock()
		elseif(iOption == 7)			
			; Unlink Layer
			UnlinkLayer_Lock(CurrentSettlementLayers.ActiveLayer)
		elseif(iOption == 8)			
			; Relink Layer
			RelinkLayer_Lock(CurrentSettlementLayers.ActiveLayer)
		elseif(iOption == 9)
			; Delete Layer
			DisableActiveLayer()
		elseif(iOption == 10) ; Exit
			return
		endif
	elseif(iOption == 8)
		return
	endif
EndFunction

; 1.0.1 - Provide means of looking up the layer holder
WorkshopPlus:SettlementLayers Function GetLayerHolderFromLayer(WorkshopPlus:WorkshopLayer akLayerRef)
	if(akLayerRef.iWorkshopID >= 0)
		return ResourceManager.Workshops[akLayerRef.iWorkshopID].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
	else
		; Search all holders
		int i = 0
		WorkshopScript[] kWorkshops = ResourceManager.Workshops
		
		while(i < kWorkshops.Length)
			WorkshopPlus:SettlementLayers thisLayerHolder = kWorkshops[i].GetLinkedRef(LayerHolderLinkKeyword) as WorkshopPlus:SettlementLayers
			
			; 1.0.2 - Fixing this if section
			if(thisLayerHolder && thisLayerHolder.DefaultLayer == akLayerRef)
				; Now that we have it, update our layer record 
				akLayerRef.iWorkshopID = thisLayerHolder.iWorkshopID
				
				return thisLayerHolder
			else
				int j = 0
				while(j < thisLayerHolder.Layers.Length)
					if(thisLayerHolder.Layers[j] == akLayerRef)
						; Now that we have it, update our layer record 
						akLayerRef.iWorkshopID = thisLayerHolder.iWorkshopID
						
						return thisLayerHolder
					endif
					
					j += 1
				endWhile
			endif
			
			i += 1
		endWhile
	endif
EndFunction

ObjectReference Function PreventLayerLinkChainLoop(ObjectReference akObjectA, ObjectReference akObjectLinkedToA)
	if(akObjectA == akObjectLinkedToA)
		
		return None
	endif
	
	return akObjectLinkedToA
EndFunction

; ---------------------------------------------
; MCM Functions - Easiest to avoid parameters for use with MCM's CallFunction, also we only want these hotkeys to work in WS mode
; ---------------------------------------------

Function Hotkey_ToggleActiveLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	ToggleActiveLayer()
EndFunction


Function Hotkey_ToggleLayerLink()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	ToggleLayerLink()
EndFunction


Function Hotkey_ToggleLayerHighlight()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	ToggleLayerHighlight()
EndFunction


; 1.0.3 - Add a hotkey to toggle this setting
Function Hotkey_ToggleAutoChangeLayersOnMove()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	if(Setting_AutoChangeLayerOnMovedObjects.GetValue() == 1.0)
		Setting_AutoChangeLayerOnMovedObjects.SetValue(0.0)
	else
		Setting_AutoChangeLayerOnMovedObjects.SetValue(1.0)
	endif
	
	UpdateHUDToggleIcons()
EndFunction


Function Hotkey_HideInactiveLayers()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	HideMultipleLayers_Lock(bInactiveOnly = true)
EndFunction


Function Hotkey_HideAllLayers()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	HideMultipleLayers_Lock(bInactiveOnly = false)
EndFunction

Function Hotkey_ShowAllLayers()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	ShowMultipleLayers_Lock() ; Interfacing this in case we think up more use cases
EndFunction


Function Hotkey_ToggleActiveLayerHighlighting()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	if(CurrentSettlementLayers.ActiveLayer.CurrentHighlightShader == ShaderActiveLayer)
		ClearActiveLayerHighlight()
	else
		HighlightActiveLayer(true)
	endif
EndFunction


Function Hotkey_HighlightActiveLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	HighlightActiveLayer(false)
EndFunction


Function Hotkey_ClearActiveLayerHighlight()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	ClearActiveLayerHighlight()
EndFunction

Function Hotkey_ClearAllHighlighting()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	ClearAllHighlighting()
EndFunction

Function Hotkey_SwitchToNextLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	SwitchToNextLayer()
EndFunction

Function Hotkey_CreateNewLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	CreateNewLayer()
EndFunction



Function Hotkey_DisableActiveLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	DisableActiveLayer()
EndFunction


Function Hotkey_ClearActiveLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	ClearActiveLayer()
EndFunction


Function Hotkey_DuplicateActiveLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	int iConfirm = DuplicateActiveLayerConfirm.Show()
	if(iConfirm == 1)
		DuplicateActiveLayer_Lock()
	endif
EndFunction


Function Hotkey_UnlinkActiveLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	UnlinkLayer_Lock(CurrentSettlementLayers.ActiveLayer)
EndFunction


Function Hotkey_RelinkActiveLayer()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	RelinkLayer_Lock(CurrentSettlementLayers.ActiveLayer)
EndFunction


Function Hotkey_RemoveAllLayers()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	RemoveAllLayers()
EndFunction


; 1.0.2 
Function Hotkey_PlaceLayerHandle()
	if( ! WorkshopFramework:WSFW_API.IsPlayerInWorkshopMode())
		ShowHotkeyWarning()
		return
	endif
	
	PlaceLayerHandle(ActionManager.kGrabbedRef)
EndFunction


Function Hotkey_NudgeWidgetUp()
	Float fIncrement = Setting_LayerWidgetNudgeIncrement.GetValue()
	HUDFrameworkManager.NudgeWidget(sLayerWidgetName, 0, fIncrement)
	fLayersWidgetY -= fIncrement
EndFunction


Function Hotkey_NudgeWidgetDown()
	Float fIncrement = Setting_LayerWidgetNudgeIncrement.GetValue()
	HUDFrameworkManager.NudgeWidget(sLayerWidgetName, 2, fIncrement)
	fLayersWidgetY += fIncrement
EndFunction


Function Hotkey_NudgeWidgetLeft()
	Float fIncrement = Setting_LayerWidgetNudgeIncrement.GetValue()
	HUDFrameworkManager.NudgeWidget(sLayerWidgetName, 3, fIncrement)
	fLayersWidgetX -= fIncrement
EndFunction


Function Hotkey_NudgeWidgetRight()
	Float fIncrement = Setting_LayerWidgetNudgeIncrement.GetValue()
	HUDFrameworkManager.NudgeWidget(sLayerWidgetName, 1, fIncrement)
	fLayersWidgetX += fIncrement
EndFunction


Function Hotkey_ScaleWidgetUp()
	Float fIncrement = Setting_LayerWidgetNudgeScaleIncrement.GetValue()
	HUDFrameworkManager.NudgeWidgetScale(sLayerWidgetName, fIncrement)
	fLayersWidgetScale += fIncrement
EndFunction


Function Hotkey_ScaleWidgetDown()
	Float fIncrement = Setting_LayerWidgetNudgeScaleIncrement.GetValue()
	HUDFrameworkManager.NudgeWidgetScale(sLayerWidgetName, -1 * fIncrement)
	fLayersWidgetScale -= fIncrement
EndFunction


Function MCM_BreakInfiniteLinkedLayers()
	BreakInfiniteLinkedLayers(true)
EndFunction


Function MCM_RemoveAllLayers()
	Utility.Wait(0.1)
	RemoveAllLayers()
EndFunction


Function MCM_ResetLayerWidgetPositionAndScale()
	ResetLayerWidgetPositionAndScale()
EndFunction


; Added 1.0.4
Function MCM_AddPreviousItemsToLayer()
	AddPreviousItemsToLayer_Lock()
EndFunction


; Added 1.0.4
Function ShowHotkeyWarning()
	if(Settings_ShowHotkeyWarnings.GetValue() == 1.0)
		ShowHotkeyWarning()
	endif
EndFunction


	; -----------------------------------
	; -----------------------------------
	; OBSOLETE - Functions deemed obsolete will be moved down here and will be set to call their replacements if possible. These will always be left functional, but you should not use them any longer if you're starting fresh.
	; -----------------------------------
	; -----------------------------------



; 1.0.2 - Obsolete, maintaining for backwards compatibility
Int[] DuplicateEventIDs
WorkshopPlus:WorkshopLayer ExpectingDuplicatesLayerRef

; Handle objects created by workshop framework
Event WorkshopFramework:PlaceObjectManager.ObjectBatchCreated(WorkshopFramework:PlaceObjectManager akPlaceObjectManagerQuest, Var[] akArgs)
	ActorValue BatchAV = akArgs[0] as ActorValue 
	Int iBatchID = akArgs[1] as Int
	Bool bAdditionalEvents = akArgs[2] as Bool
	
	if( ! ExpectingDuplicatesLayerRef)
		; No layer expecting, just use the default layer
		ExpectingDuplicatesLayerRef = CurrentSettlementLayers.DefaultLayer
	endif
	
	ModTrace("[WSPlus] Duplicate Layer: ObjectBatchCreated event received.")
	if(BatchAV == WorkshopFramework:WSFW_API.GetDefaultPlaceObjectsBatchAV())
		; This event is for us!
		int iLockKey = GetLock()
		if(iLockKey <= GENERICLOCK_KEY_NONE)
			ModTrace("Unable to get lock!", 2)
			
			return
		endif
		
		if(ExpectingDuplicatesLayerRef)
			ModTrace("[WS Plus] Adding batch created items to layer " + ExpectingDuplicatesLayerRef + ".")
			int i = 3
			while(i < akArgs.Length)
				ObjectReference kTemp = akArgs[i] as ObjectReference
				
				if(kTemp)
					AddItemToLayer_Lock(kTemp, ExpectingDuplicatesLayerRef, abGetLock = false)
				endif
				
				i += 1
			endWhile
		endif
		
		Int iDuplicateEventIndex = DuplicateEventIDs.Find(iBatchID)
		if(DuplicateEventIDs.Length > 1)
			DuplicateEventIDs.Remove(iDuplicateEventIndex)
		elseif(DuplicateEventIDs.Length == 1)
			; Finished processing a duplicate layer event
			DuplicateEventIDs = new Int[0]
			DuplicateActiveLayerComplete.Show()
		endif
		
		if(DuplicateEventIDs == None || DuplicateEventIDs.Length == 0)
			bDuplicateLayerBlock = false
		endif
		
		; Release Edit Lock
		if(ReleaseLock(iLockKey) < GENERICLOCK_KEY_NONE )
			ModTrace("Failed to release lock " + iLockKey + "!", 2)
		endif
	endif	
EndEvent