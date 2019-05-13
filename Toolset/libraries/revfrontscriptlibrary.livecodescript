script "revfrontscriptlibrary"

on extensionInitialize
   if the target is not me then
      pass "extensionInitialize"
   end if	
   insert the script of me into front
end extensionInitialize

on extensionFinalize
	if the target is not me then
		pass "extensionFinalize"
	end if
   remove the script of me from front
end extensionFinalize

global gREVSuppressMessages
local lRefreshAOTimerID

on saveStackRequest

   global gREVMessageDispatch
   repeat for each line l in gREVMessageDispatch["revSaveStackRequest"]
      send "revSaveStackRequest" to this cd of stack l
   end repeat
   
   revIDESetUnedited the short name of revIDEStackOfObject(the long id of the target)

   if "revReshapeLibrary" is in revInternal__ListLoadedLibraries() then
      select empty
      send "revSetMarkers true" to stack "revReshapeLibrary"
      revInternal__UnloadLibrary "revReshapeLibrary"
   end if

   # OK-2008-03-14 : Bug 5890. Added global variable to work around the problem that
   # passing this message to metacard can prevent the revSave command finishing its
   # execution, leading to stacks not being saved and the save dialog lingering.
   global gREVAllowSaveStackRequest

   if (not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget())) or gREVAllowSaveStackRequest then
      pass saveStackRequest
   else
      pass saveStackRequest to metaCard
   end if
end saveStackRequest

on nameChanged pOldname, pNewName, pTarget
   global gREVMessageDispatch, gREVStackName
   
   if revTargetStack(the target) is "answer dialog" then pass nameChanged
   
   local tTarget
   lock screen
   if pTarget is not empty then put pTarget into tTarget
   else put the long id of the target into tTarget
   if word 1 of tTarget is "stack"
   then replace comma with "_" in pNewName--engine seems to do this
   
   local tPalettes
   put revPalettesList() into tPalettes
   set the wholeMatches to true
   
   local tLinkedObjects
   repeat for each line l in tPalettes
      if word 1 of tTarget is "stack" and the cREVLinked of stack l is not empty then
         put empty into tLinkedObjects
         local tObject, tSkip
         repeat for each line m in the cREVLinked of stack l
            put m into tObject
            put 0 into tSkip
            local tWordOffset, tStackOffset, tStackName
            repeat 2 times
               put wordOffset("stack", tObject, tSkip) into tWordOffset
               if tWordOffset = 0 then exit repeat
               add tSkip to tWordOffset
               add tWordOffset to tSkip
               put tWordOffset + 1 into tStackOffset
               put char 2 to -2 of word tStackOffset of tObject into tStackName
               if tStackName is pOldName then
                  put quote&pNewName&quote into word tStackOffset of tObject
                  exit repeat
               end if
            end repeat
            put tObject & cr after tLinkedObjects
         end repeat
         delete last char of tLinkedObjects
         set the cREVLinked of stack l to tLinkedObjects
      end if
      
      local tObjects
      if the cREVLinked of stack l is not empty
      then put the cREVLinked of stack l into tObjects
      else put (the selobj) into tObjects
      
      # LG-2008-03-17
      # Bug 6092
      # It is possible that the object tObjects refers to may have been
      # deleted if messages are locked.
      if tObjects is empty or there is a tObjects then                  # LG 2008-08-13, Bug 6694
         set the title of stack l to revPaletteTitle(tObjects)
         send "revUpdatePalette" to this cd of stack l
      end if
   end repeat
   
   # OK-2008-03-11 : Update the script editor so that the object's new name is displayed.
   put the long id of the target into tTarget
   send "revSEObjectNameChanged tTarget, pOldName, pNewName" to revScriptEditorMain()
   
   if pNewName is empty and word 1 of tTarget is "stack" then
      lock messages
      set the name of tTarget to pOldName
      put pOldName into pNewName
      unlock messages
   end if
   
   repeat for each line l in gREVMessageDispatch["revNameChanged"]
      send "revNameChanged pNewName, pOldName" to this cd of stack l
   end repeat
   
   --if name is empty need to match id
   if pOldName is empty
   then put word 1 to 3 of tTarget into pOldName
   
   --update Application Overview global variables/custom properties with new name
   if word 1 of tTarget is "stack" and pOldName is gREVStackName then
      --stack name has changed
      put pNewName into gREVStackName
   end if
   
   local tTargetStack
   put revTargetStack(tTarget) into tTargetStack
   
   local tHCAddressing
   put the hcAddressing of stack tTargetStack into tHCAddressing
   set the hcAddressing of stack tTargetStack to false
   
   if there is a stack "revApplicationOverview" then
      send "revNameChanged the long id of tTarget, pOldName, pNewName" to stack "revApplicationOverview"
   end if
   
   set the hcAddressing of stack tTargetStack to tHCAddressing
   
   revSetActiveStacks
   unlock screen
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass nameChanged
end nameChanged

on idChanged pOldId, pNewId
   global gREVMessageDispatch
   repeat for each line l in gREVMessageDispatch["revIdChanged"]
      send "revIdChanged pOldId, pNewId" to this cd of stack l
   end repeat

   local tObject
   put the long id of the target into tObject
   send "revSEObjectIdChanged tObject, pOldId, pNewId" to revScriptEditorMain()

   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass idChanged
   end if
end idChanged

# OK-2008-04-11 : New script editor changes
on mainstackChanged pOldStackName, pNewStackName
   local tStack
   put the long id of the target into tStack

   send "revSEMainstackChanged tStack, pOldStackName, pNewStackName" to revScriptEditorMain()
   pass mainstackChanged
end mainstackChanged

// PM-2015-10-02: [[ Bug 13588 ]] Make sure the insertion point is the correct one
on setCursorAtLoc pAt, pEditor
   if pAt is not empty then
      local tLine, tCol, tCard
      put item 1 of pAt into tLine
      put item 2 of pAt into tCol
      put the currentCard of stack pEditor into tCard
      select after char tCol of line tLine of fld "Script" of group "Editor" of card tCard of stack pEditor
   end if
end setCursorAtLoc


on editScript pObject, pAt
   local tResult
   revIDEEditScriptOfObject pObject
   put the result into tResult
   if tResult is "pass" then
      pass editScript
   end if
   
   local tEditor
   put revScriptEditor(pObject)  into tEditor
   send "setCursorAtLoc pAt, tEditor" to me in 0 seconds
end editScript

on resumeStack
   global gREVScriptEdit
   put true into gREVScriptEdit

   revSetActiveStacks

   global gREVMessageDispatch
   repeat for each line l in gREVMessageDispatch["revResumeStack"]
      send "revResumeStack" to this cd of stack l
   end repeat

   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass resumeStack
end resumeStack

on suspendStack
   global gREVScriptEdit, gREVBuildingPaletteExemption
   --suspendStack sent during the palette building process
   --it doesn't count then for selecting the background
   if not gREVBuildingPaletteExemption then put false into gREVScriptEdit
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass suspendStack
   end if
end suspendStack

on newStack
   revSetActiveStacks
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass newStack
   end if
end newStack

on revSetActiveStacks
   ideMessageSend "ideActiveStacksChanged"
end revSetActiveStacks


# OK-2008-03-27 : Bug 6229. Refactored to allow a target to be passed to the
# handler that deals with the opening of new stacks.
on preOpenStack
   revIDEHandleNewStack the long id of the target
   
   local tScaleFactor
   put the cREVGeneral["scalefactor"] of this stack into tScaleFactor
   if tScaleFactor is a number and tScaleFactor is not 1 then
      set the scalefactor of this stack to tScaleFactor
   end if 
   
   local tTarget
   put the long id of the target into tTarget
   
   local tStack
   put revTargetStack(tTarget) into tStack
   
   if revIDEObjectIsOnIDEStack(tTarget) then
      # IM-2016-03-01: [[ Bug 16244 ]] IDE stacks should always hide invisible objects
      set the showInvisibles of stack tStack to false
      set the _ideoverride of stack tStack to true
   end if
   
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass preOpenStack
end preOpenStack

on rawKeyUp pWhich
   if pWhich is 65386 then
      revIDEHelpKeyPressed
   end if
   pass rawKeyUp
end rawKeyUp

on openStack
   global gREVPalettes

   local tStackName
   if gREVPalettes is not empty then
      put revTargetStack() into tStackName

      if revIDEStackNameIsIDEStack(tStackName) and the mode of stack tStackName is 4 and the visible of stack tStackName is false then
         revIDETogglePaletteView
         
         local tScreenRect
         put revIDEStackScreenRect(tStackName, true) into tScreenRect
         if the bottom of stack tStackName > item 4 of tScreenRect or the right of stack tStackName > item 3 of tScreenRect then
            set the bottomRight of stack tStackName to item 3 to 4 of tScreenRect
         end if
      end if
   end if

   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass openStack
end openStack

local lNoRecurse

on preOpenCard
   global gREVStackName

   if lNoRecurse then
      put false into lNoRecurse
      pass preOpencard
   end if

   local tTarget
   put revTargetStack() into tTarget
   if not revIDEStackNameIsIDEStack(tTarget) and "cREVGeometryCache" is among the lines of the customPropertySets of the target \
          and (the cREVGeometryCache["order"] of this cd is empty \
          or the cREVGeometryCache["total"] of this cd is not the number of controls \
          or the number of words in the customKeys["cREVGeometryCacheIDs"] of this cd is 0) \
          then
      revCacheGeometry
   else if "cREVGeometryCache" is among the lines of the customPropertySets of stack revTargetStack() and the cREVGeometryCache["stackID"] of stack revTargetStack() is not the id of stack revTargetStack() then
      revCacheGeometry
      repeat with i = 1 to the number of cds
         set the cREVGeometryCache["order"] of cd i to empty
      end repeat
   end if
   if the cREVGeometry["preOpenCardUpdate"] of this cd of stack tTarget is true then revUpdateGeometry

   global gREVMessageDispatch
   repeat for each line l in gREVMessageDispatch["revPreOpenCard"]
      send "revPreOpenCard" to this cd of stack l
   end repeat




   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass preOpenCard
end preOpenCard

local lPrefsSaveTime

on closeStack
   global gREVTargetStack, gREVShowStacks, gREVShutDown

   put "stack" && quote & revTargetStack() & quote into gREVTargetStack

   send "revUpdateScriptEdit" to me in 10 milliseconds
   send "revCloseUpdate" to me in 100 milliSeconds

   local tStack
   put revTargetStack(the long id of the target) into tStack
   put the mainStack of stack tStack into tStack

   local tStacks
   put tStack into tStacks
   if the substacks of stack tStack is not empty
   then put cr & the substacks of stack tStack after tStacks
   send "revCheckStackOpen tStack,tStacks" to me in 1 second

   --update recent files
   local tTargetStack
   put revTargetStack(the long id of the target) into tTargetStack
   revUpdateRecentFiles tTargetStack

   # OK-2008-09-03 : Bug 7073 - This can cause property inspector dialogs to lock up for some reason,
   # this problem is avoided by moving this line to resumeStack in the start centre.
   --   send "updateRecentStacks" to stack "revStartCenter"

   # OK-2008-08-11 : If the destroyStack property of the stack being closed is true, then the
   # stack will be removed from memory, and any script editors affected by this must be closed.
   if the destroyStack of stack tTargetStack then
      revIDEHandleObjectDeleted the long id of stack tTargetStack
   end if

   if gREVTargetSTack is empty or (there is not a stack gREVTargetStack) then exit closeStack

   if word 1 of gREVTargetStack is not "stack" then
      put "stack" && quote before gREVTargetStack
      put quote after gREVTargetStack
   end if

   if the seconds - lPrefsSaveTime > 20 then -- save more frequently to keep data on unexpected exit
      -- MM-2011-03-13: [[ Bug 10073]] Make sure the stack file version is maintained at 2.7 for backwards compatability reasons
      revInternal__SavePreferences

      put the seconds into lPrefsSaveTime
   end if

   if not gREVShutDown then
      if there is a gREVTargetStack and not (the destroyStack of gREVTargetStack) and the short name of gREVTargetStack is among the lines of revFilterstacksList(the short name of gREVtargetStack) then
         local tStackslist
         if the cASKDestroy of stack "revPreferences" is among the items of "ask,remove" then
            put the mainStack of gREVTargetStack & cr & the substacks of stack (the mainStack of gREVTargetStack) into tStackslist

            local tAllClosed
            put true into tAllClosed
            repeat for each line l in tStacksList
               if l is empty then next repeat
               if quote & l & quote is word 2 of gREVTargetStack then next repeat
               if the mode of stack l is 0 then
                  put true into tAllClosed
               else
                  put false into tAllClosed
                  exit repeat
               end if
            end repeat

            local tStackName
            put revTargetStack() into tStackName

            local tFileName
            
            local tIsBuildingStandalone
            put (there is a stack "revStandaloneProgress" and \
                  the mode of stack "revStandaloneProgress" > 0) into tIsBuildingStandalone
            
            # OK-2008-08-05 : Bug 6562 - Bug where the user was being prompted to delete the home stack on startup,
            # caused by revIDEStack returning true/false instead of empty/non-empty.
            if not tIsBuildingStandalone and tAllClosed and not revIDEStackNameIsIDEStack(tStackName) then
               put the effective fileName of gREVTargetStack into tFileName

               # TH - 7689 improved wording of warning message
               if tFileName is empty and the cASKDestroy of stack "revPreferences" is "ask" then
                  answer question "You have closed the last stack in this file.  Since it has not yet been saved if you proceed you will be unable to recover it.  Do you want to remove all stacks in this file from memory?  (You can turn this warning off in Preferences under the Edit menu.)" with "No" or "Yes"
               else if the cASKDestroy of stack "revPreferences" is "ask" then
                  answer question "You have closed the last stack in file" && tFilename & ".  Do you want to remove all stacks in this file from memory?  (You can turn this warning off in Preferences under the Edit menu.)" with "No" or "Yes"
               end if

               if it is not "No" then
                  local tMainStack
                  # Bug 4192
                  put line 1 of tStacksList into tMainstack
                  send "revDeleteStack tMainStack" to me in 150 milliseconds
                  exit closeStack
               end if
            end if
         end if
      end if
   end if

   revSetActiveStacks

   global gREVMessageDispatch
   repeat for each line l in gREVMessageDispatch["revCloseStack"]
      send "revCloseStack" to this cd of stack l
   end repeat

   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass closeStack
end closeStack


on revDeleteStack pWhichStacks
   repeat for each line l in pWhichStacks
      delete stack l
   end repeat
end revDeleteStack

on revCheckStackOpen pStack, pStacks
   if there is a stack "revApplicationOverview" then
      if the mode of stack "revApplicationOverview" is not 0 and there is not a stack pStack
      then send "revAODeleteStack pStack, pStacks" to stack "revApplicationOverview"
   end if
end revCheckStackOpen

# TH-2008-06-18 : Bug 6217, This is now handled in revbackscript which prevents the accidental
# closing of unsaved new stacks when messages are suppressed
on closeStackRequest
   local tResult
   revIDEHandleCloseStackRequest the long id of the target
   put the result into tResult
   if tResult is "pass" then
      pass closeStackRequest
   end if

   if tResult is "exit to top" then
      exit to top
   end if
end closeStackRequest


on revCloseUpdate
   global gREVStacksList, gREVMessageDispatch
   if "revCloseUpdate" is in the pendingMessages then exit revCloseUpdate
   put empty into gREVStacksList
   put empty into gREVMessageDispatch

   local tOpenList
   put the openStacks into tOpenList
   repeat for each line l in tOpenList
      if revIDEStackNameIsIDEStack(l) then
         if the cREVGetsUpdate of stack l is true then
            put l & cr after gREVStacksList
         end if
      end if

      local tLoadArray
      if there is a stack l then
         put the customProperties["cREVLoadInfo"] of stack l into tLoadArray
      end if
      repeat for each line x in keys(tLoadArray)
         if tLoadArray[x] is true and l is not among the lines of gREVMessageDispatch[x] then put l into line (the number of lines in gREVMessageDispatch[x]+1) of gREVMessageDispatch[x]
      end repeat
   end repeat
   delete last char of gREVStacksList
end revCloseUpdate

-- **Bookmark Entry** Editing Handlers

on mouseDown pWhich
  local tResult
  revIDEHandleMouseDown pWhich, the long id of the target
  put the result into tResult

  switch tResult
  case "exit"
    exit mouseDown
    break
  case "exit to top"
    exit to top
    break
  default
    if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass mouseDown
    end if
  end switch
end mouseDown

on mouseUp pWhich
  local tTarget
  put the long id of the target into tTarget

  local tResult
  revIDEHandleMouseUp pWhich, tTarget
  put the result into tResult

  switch tResult
  case "pass"
    pass mouseUp
    break
  case "exit"
    exit mouseUp
    break
  case "exit to top"
    exit to top
  default
    if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass mouseUp
    end if
  end switch
end mouseUp

on mouseDoubleUp pButtonNo, pTarget
   if revCheckEdit(pTarget) then
      revIDEOpenInspectorForObjects revIDESelectedObjects()
   else if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass mouseDoubleUp
   end if
end mouseDoubleUp

on openField
   local tStack
   put revIDEStackOfObject(the long id of the target) into tStack
   if the mode of tStack is 1 then
      revIDESetEdited the short name of tStack
   end if
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass openField
end openField

on closeField
  if the cREVGetsUpdate of stack revTargetStack() is not empty then set the backPattern of the target to empty
  if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass closeField
end closeField

on scrollBarDrag
   if the cREVGeneral["inLineImages"&the number of this cd] of the target is true then
      local tGroupName
      put the short name of the target & "images"&the number of this cd into tGroupName
      set the scroll of group tGroupName to the scroll of the target
   end if
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass scrollBarDrag
end scrollBarDrag

on menuPick
  if the cREVGetsUpdate of stack revTargetStack() is true then set the backPattern of the target to empty
  if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass menuPick
end menuPick

# OK-2007-07-03: Bug 4768. If Messages are supressed we need to block the dragMove message here to fix the bug.
on dragMove
  if not gREVSuppressMessages then
    pass dragMove
  end if
end dragMove


function revCheckDelete
   if the selectedField is not empty then return true

   local tSelObj
   put the selobj into tSelObj
   filter tSelobj with "group*"
   repeat for each line l in tSelObj
      if word 1 of l is "group" and the number of lines in the cardNames of l > 1 then
         answer warning "This group is placed on multiple cards," & cr & "really delete it?" with "Yes" or "No"
         if it is "No" then return false
      end if

      if word 1 of l is "group" and the uProps["control type"] of l is "Data Grid" then
         answer warning "Would you like to delete the record template associated with this data grid? This action cannot be undone." with "Yes" or "No"
         if it is "Yes" then
            local tTemplate, tCardWord, tTemplateCard, tStackWord, tTemplateStack
            put the uProps["record template"] of l into tTemplate
            put wordoffset("card",tTemplate) into tCardWord
            put word tCardWord to -1 of tTemplate into tTemplateCard
            put wordoffset("stack",tTemplate) into tStackWord
            put word tStackWord to -1 of tTemplate into tTemplateStack
            if the number of cards in stack tTemplateStack is 2 then delete stack tTemplateStack
            else
               delete tTemplateCard
            end if
         end if
      end if

   end repeat

   local tMenuManagerBG
   if the mode of stack "revMenuManager" is not 0 and there is a bg id (the cREVMenuID of stack "revMenuManager") \
          of stack (the cREVDefaultStack of stack "revMenuManager") then
      put the long id of bg id (the cREVMenuID of stack "revMenuManager") \
             of stack (the cREVDefaultStack of stack "revMenuManager") into tMenuManagerBG
      repeat for each line l in tSelObj
         if l is tMenuManagerBG then
            answer warning "This group is being edited with the Menu Manager.  Really delete it?" with "Yes" or "No"
            if it is "No" then return false
         end if
      end repeat
   end if
   repeat for each line l in tSelobj
      if revIsMenuBarGroup(l) then
         answer warning "This group is the menubar on MacOS.  Really delete it?" with "Yes" or "No"
         if it is "No" then return false
      end if
   end repeat
   return true
end revCheckDelete

on backspaceKey
   lock screen
   if revCheckDelete() then 
      if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then 
         --PM-2015-10-30: [[ Bug 16304 ]] Balance lock screen
         unlock screen
         pass backspaceKey
      else 
         pass backSpaceKey to metaCard
      end if
   end if
   unlock screen
end backspaceKey

on deleteKey
   lock screen
   if revCheckDelete() then 
      if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then 
         unlock screen
         pass deleteKey
      else
         pass deleteKey to metaCard
      end if
   end if
   unlock screen
end deleteKey

local lSeenErrors, lEmptyFile

on revVerboseDebug pWhat
   global gREVVerboseDebug
   set the cVerboseDebug of stack "revPreferences" to pWhat

   -- setting this 'cause its going to crash, so save now
   -- MM-2011-03-13: [[ Bug 10073]] Make sure the stack file version is maintained at 2.7 for backwards compatability reasons
  revInternal__SavePreferences

   set the cVerboseDebug of stack "revPreferences" to pWhat
   set the messageMessages to pWhat
   put pWhat into gREVVerboseDebug
   if pWhat then
      delete file "verboseLog.txt"
      open file "verboseLog.txt" for text write
   end if
end revVerboseDebug

on messageHandled t, m
  global gREVVerboseDebug
  if lEmptyFile > 50000 then -- about 10MB
    close file "verboseLog.txt"
    delete file "verboseLog.txt"
    open file "verboseLog.txt" for text write
    put 1 into lEmptyFile
  end if
  if gREVVerboseDebug then
    write "messageHandled" && the long time && t, m, the long id of the target & cr to file "verboseLog.txt"
    add 1 to lEmptyFile
  end if
  send "recordMessage t, m, the long id of the target, true" to card 1 of stack "revMessageWatcher"
end messageHandled

on messageNotHandled t, m
  global gREVVerboseDebug
  if gREVVerboseDebug then
    write "messageNotHandled" && the long time && t, m, the long id of the target & cr to file "verboseLog.txt"
    add 1 to lEmptyFile
  end if
  send "recordMessage t, m, the long id of the target, false" to card 1 of stack "revMessageWatcher"
end messageNotHandled

on scriptParsingError pWhich
   global gREVSuppressErrors
   if gREVSuppressErrors then exit scriptParsingError

   local tDigest
   put MD5Digest(pWhich) into tDigest
   if tDigest is among the lines of lSeenErrors then exit scriptParsingError
   else put tDigest into line (the number of lines in lSeenErrors)+1 of lSeenErrors
	revIDEErrorDialog "", pWhich
end scriptParsingError

function revOKTarget pWhich
   local tTarget
   if pWhich is not empty then 
      put pWhich into tTarget
   else 
      put the long id of the target into tTarget
   end if
   
   return revIDEObjectIsOnIDEStack(tTarget)
end revOKTarget

function revGetProperties pObject
   --return list of properties for an object, excluding all custom properties
   --also works for global and local properties
   --includes synonyms
   set the customPropertySet of stack "revLibrary" to "cREVPropertiesList"

   local tProperties
   put the pObject of stack "revLibrary" into tProperties
   set the wholeMatches to true
   repeat for each item i in "customKeys,customProperties,customPropertySet,customPropertySets"
      delete line lineOffset(i,tProperties) of tProperties
   end repeat
   return tProperties
end revGetProperties

on revUpdateScriptEdit
  global gREVScriptEdit
  put true into gREVScriptEdit
end revUpdateScriptEdit

on propertyChanged pObject
	revIDEPropertyChanged pObject
end propertyChanged

# OK-2008-03-27 : Bug 6229. Added ability to specify a target
on revCheckStackCollision pStack
  local tTarget
  if pStack is empty then
    put the long id of the target into tTarget
  else
    put pStack into tTarget
  end if

  local tOffset
  put wordOffset("stack",tTarget) into tOffset

  local tLongStack
  put word tOffset to -1 of tTarget into tLongStack

  local tStacks
  put the short name of tLongStack into tStacks
  if the mainStack of tLongStack is not tStacks
  then exit revCheckStackCollision

  local tFilePath
  put the fileName of tLongStack into tFilePath
  if the substacks of tLongStack is not empty
  then put cr & the substacks of tLongStack after tStacks

  local tMainStacks
  put the mainStacks into tMainStacks

  local tFileInfo
  put empty into tFileInfo

  local tFilePath2, tStacks2
  repeat for each line l in tMainStacks
    put the fileName of stack l into tFilePath2
    if tFilePath2 is tFilePath then next repeat
    put l into tStacks2
    if the substacks of stack l is not empty
    then put cr & the substacks of stack l after tStacks2
    repeat for each line m in tStacks2
      if m is among the lines of tStacks then
        if tFilePath2 is not empty then put "in file" && tFilePath2 & space into tFileInfo
        answer warning "A stack" && quote & m & quote && tFileInfo & \
            "is already in memory.  The LiveCode UI does not distinguish stacks which have identical names, so editing these stack files while both are in memory could result in data loss."
            exit repeat
         end if
      end repeat
   end repeat
end revCheckStackCollision

private command log pMessage
  put pMessage & return after msg
end log
