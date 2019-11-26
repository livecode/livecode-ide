script "revbackscriptlibrary"

on extensionInitialize
   if the target is me then
      insert the script of me into back
      revIDESubscribe "ideMouseMove"
   end if
end extensionInitialize

on extensionFinalize
   if the target is me then
      remove the script of me from back
      revIDEUnsubscribeAll
   end if
end extensionFinalize

global gREVSuppressMessages

local lUpdateDimensionsTimerID, lUpdateAOControlsTimerID, lLastTopStack

on revEditImage pWhichImage
   revIDEEditImage pWhichImage
end revEditImage

function revImageType pImageNo
   --take the numbered image and return a three character file extension for it
   local tHeader
   put char 1 to 100 of image pImageNo into tHeader
   --PNG
   if charToNum(char 1 of tHeader) is 137 and char 2 to 4 of tHeader is "PNG" then return ".png"
   --JPEG
   if charToNum(char 1 of tHeader) is among the items of "255,216" and "JFIF" is in tHeader then return ".jpg"
   --GIF
   if "GIF" is in tHeader then return ".gif"
   --PICT
   --can't get the code to detect this right, use internal format
   --default
   --edited in mc or recompressed by MC (imported BMP, XWD etc.)
   return ".ppm"
end revImageType

function revIsPICT pWhatPath
   --takes a valid file path and returns if PICT or not
   if not (there is a file pWhatPath) then return "error"
   
   local tData
   put char 1 to 600 of url ("binfile:"&pWhatPath) into tData
   
   local tPICT
   repeat with i = 1 to 7
      if charToNum(char i of tData) is 0 then
         put true into tPICT
      else
         put false into tPict
         exit repeat
      end if
   end repeat
   if tPict then
      if charToNum(char 523 of tData) is 0 and charToNum(char 524 of tData) is 17 and charToNum(char 525 of tData) is 2 and charToNum(char 526 of tData) is 255 then
         put true into tPict
      else
         put false into tPict
      end if
      
      local tFinal
      if tPict then
         put true into tFinal
      else
         put false into tFinal
      end if
   else
      put false into tFinal
   end if
   return tFinal
end revIsPICT

on revCheckQuit
   global gREVShutDownList, gREVShutDown
   
   local tMainStacks
   put the mainStacks into tMainStacks
   
   local tListOfStacks
   put empty into tListOfStacks
   repeat for each line l in tMainStacks
      if the substacks of stack l is empty
      then put l & cr after tListOfStacks
      else put l & cr & the substacks of stack l & cr after tListOfStacks
   end repeat
   delete last char of tListOfStacks
   
   local tEditors, tFinalList
   repeat for each line l in tListOfStacks -- script editors first
      if word 1 of l is "revScriptEditor" then
         put l & cr after tEditors
      else
         put l & cr after tFinalList
      end if
   end repeat
   delete last char of tFinalList
   if the number of lines in tEditors is not 0 then
      delete last char of tEditors
      put tEditors & cr before tFinalList
   end if
   put tFinalList into tListOfStacks
   
   local tCheck
   repeat for each line l in tListOfStacks
      set the defaultStack to l
      put revSaveCheck(l,false) into tCheck
      if tCheck is false then return false -- exit appleEvent handler too
   end repeat
   set the cSelectGrouped of stack "revPreferences" to the selectGroupedControls
   
   local tMode
   repeat for each line l in gREVShutdownlist
      lock messages
      put the cREVLoadInfo["mode"] of stack l into tMode
      unlock messages
      if tMode is "invisible" then go inv stack l
      else do "go stack" && quote & l & quote && "as" && tMode
   end repeat
   
   global gREVMessageDispatch
   repeat for each line l in gREVMessageDispatch["revShutDown"]
      send "revShutDown" to this cd of stack l
   end repeat
   
   local tPalettes
   put the openStacks into tPalettes
   filter tPalettes with "revPropertyPalette*"
   
   local tOpenTabPositions
   put empty into tOpenTabPositions
   lock screen
   lock error dialogs --close the properties palettes with the errors locked in case they're giving the quit errors
   repeat for each line l in tPalettes
      if the cREVLinked of stack l is empty
      then put the cREVCurrentTabs of stack l & tab & the topLeft of stack l & cr after tOpenTabPositions
      close stack l
   end repeat
   unlock error dialogs
   
   -- closes any active database connections
   local tActiveDatabase, tWorkaround
   try
      put revdb_connections() into tActiveDatabase
      if tActiveDatabase is not empty then
         repeat for each item i in tActiveDatabase
            get revdb_disconnect(i)
         end repeat
      end if
   catch tJunk
      put empty into tWorkAround -- workaround engine bug
   end try
   
   delete last char of tOpenTabPositions
   set the cREVOpenTabPositions of stack "revPreferences" to tOpenTabPositions
   
   set the cREVScriptFont of stack "revPreferences" to the scriptTextFont
   set the cREVScriptSize of stack "revPreferences" to the scriptTextSize
   
   if not the secureMode then
      revInternal__savePreferences
   end if
   put true into gREVShutDown
   
   return "quit"
end revCheckQuit


on shutDownRequest
   revCheckQuit
   if the result is "quit" then pass shutDownRequest
end shutDownRequest

on revSendDimensionsUpdate
   if lUpdateDimensionsTimerID is not empty then cancel lUpdateDimensionsTimerID
   send "revUpdateSizeandPosition line 1 of the selobj" to me in 500 milliseconds
   put the result into lUpdateDimensionsTimerID
end revSendDimensionsUpdate

on revUpdateSizeandPosition pTarget
   if "development" is not in the environment
   then exit revUpdateSizeandPosition
   
   local tPalettes
   put revPropertyPalettes(pTarget) into tPalettes
   repeat for each line l in tPalettes
      if the short name of this cd of stack l is "revSize&Position" 
      then send "revUpdatePalette" to this cd of stack l
   end repeat
end revUpdateSizeandPosition

function revCheckEdit pTarget
   # MW-2010-10-13: [[ Bug 8940 ]] Check the 'cantSelect' of the target object before deciding whether it is editable
   if the tool is "browse tool" then
      return false
   end if
   
   if (pTarget is not empty and the effective cantSelect of pTarget) or \
         (pTarget is empty and the effective cantSelect of the target) then
      return false
   end if
   
   if the mode of stack revTargetstack(pTarget) is not 1 then
      return false
   end if
   
   return true
end revCheckEdit

on revUpdatePalette
end revUpdatePalette

function revPaletteObjects
   return revIDESelectedObjects()
end revPaletteObjects

on revStandardUpdate
   global gREVLanguageNames
   
   if the mode of stack "revIconChooser" is not 0 then close stack "revIconChooser"
   
   local tObjects
   put revPaletteObjects() into tObjects
   
   --check the real/vs. language property names
   if the cLanguageNames of this cd is not gREVLanguageNames then
      if gREVLanguageNames then
         set the cLanguageNames of this cd to true
         
         -- custom prop arrays where we don't want to set the control name to the name of the array
         repeat for each line tControl in the cREVCustomPropertiesInUse of this cd
            if the cRevLabel of control tControl is not empty then set the label of control tControl to the cRevLabel of control tControl
            if the cRevToolTip of control tControl is not empty then set the toolTip of control tControl to the cRevToolTip of control tControl
            if the cRevText of control tControl is not empty then set the text of control tControl to the cRevText of control tControl
         end repeat
         
         
         repeat for each line l in the cREVPropertiesInUse of this cd
            if there is a control l then
               if word 1 of the name of control l is "button" and the style of control l is not "menu" then
                  set the cEnglishName of control l to the label of control l
                  set the label of control l to the short name of control l
                  set the toolTip of control l to item 1 of the cEnglishName of control l
               end if
               if (word 1 of the name of control l is "field" or (word 1 of the name of control l is "button" and the style of control l is "menu")) and there is a field ("revlabel" && l) then
                  set the cEnglishname of control l to the text of fld ("revLabel" && l)
                  set the text of fld ("revLabel" && l) to the short name of control l
                  set the toolTip of fld ("revLabel" && l) to the cEnglishName of control l
                  set the toolTip of control l to the cEnglishName of control l
               end if
            end if
         end repeat
      else
         set the cLanguageNames of this cd to false
         
         -- custom prop arrays where we don't want to set the control name to the name of the array
         repeat for each line tControl in the cREVCustomPropertiesInUse of this cd
            if the cEnglishLabel of control tControl is not empty then set the label of control tControl to the cEnglishLabel of control tControl
            if the cEnglishToolTip of control tControl is not empty then set the toolTip of control tControl to the cEnglishToolTip of control tControl
            if the cEnglishText of control tControl is not empty then set the text of control tControl to the cEnglishText of control tControl
         end repeat
         
         
         repeat for each line l in the cREVPropertiesInUse of this cd
            if there is a control l then 
               if word 1 of the name of control l is "button" and the style of control l is not "menu" then
                  set the toolTip of control l to item 1 of the label of control l
                  set the label of control l to the cEnglishName of control l
               end if
               if (word 1 of the name of control l is "field" or (word 1 of the name of control l is "button" and the style of control l is "menu")) and there is a field ("revlabel" && l) then
                  set the toolTip of fld ("revlabel" && l) to the text of fld ("revLabel" && l)
                  set the toolTip of control l to the text of fld ("revlabel" && l)
                  set the text of fld ("revLabel" && l) to the cEnglishName of control l
               end if
            end if
         end repeat
      end if
   end if
   
   --update the objects
   local tObject
   put line 1 of tObjects into tObject
   
   repeat for each line l in the cREVPropertiesInUse of this cd
      if l is empty then next repeat
      try
         local tProperty
         put the l of tObject into tProperty
         
         local tObjectCondition
         put empty into tObjectCondition
         set the caseSensitive to true
         repeat for each line tCurrent in tObjects
            if the l of tCurrent is not tProperty then
               put "multiple" into tObjectCondition
               exit repeat
            end if
         end repeat
         set the caseSensitive to false
         if tObjectCondition is not "multiple" then
            
            # LG-2008-03-07
            # Special case for "dashes" property. The control is a checkbox but the actual property
            # is a pair of integers.
            if l is "dashes" then
               if tProperty is empty then
                  put false into tObjectCondition
               else
                  put true into tObjectCondition
               end if
            else
               put tProperty into tObjectCondition
            end if
         end if
      catch someError
         if word 1 of the name of control l is "field" then put empty into control l
         else if word 1 of the name of control l is "button" then set the hilite of control l to false
         disable control l
         set the backPattern of control l to empty
         next repeat
      end try
      
      if l is "unicodeLabel" then
         enable control "label"
      else if l is "unicodeText" then
         enable control "text"
      else
         enable control l
      end if
      
      switch tObjectCondition
         case "multiple"
            if word 1 of the name of control l is "button" then
               set the hilite of btn l to false
               set the backPattern of btn l to 200921
            else if word 1 of the name of control l is "field" then
               put empty into fld l
               set the backPattern of fld l to 200921
            end if
            break
         case "true"
         case "false"
            if word 1 of the name of control l is "button" then
               set the hilite of btn l to tObjectCondition
               set the backPattern of btn l to empty
            else
               put tObjectCondition into control l
            end if   
            break
         default            
            if l is "unicodeLabel" then
               set the unicodeText of field "label" to tObjectCondition
            else if l is "unicodeText" then
               set the unicodeText of control "text" to tObjectCondition
            else if l is "scaleFactor" then
               if tObjectCondition is empty then set the label of control "scalefactor" to 1
               else set the label of control "scalefactor" to tObjectCondition
            else
               if word 1 of the name of control l is "button" and the style of control l is "menu" then
                  -- MM-2011-11-25: Allow the captilisation of property values (used by layerMode e.g. static appears as Static in menu).
                  if the cCapitalisePropertyValue of control l then
                     put the upper of char 1 of tObjectCondition into char 1 of tObjectCondition
                  end if
                  set the label of control l to tObjectCondition
               else 
                  put tObjectCondition into control l
               end if
            end if
            
            if l is "unicodeLabel" then
               set the backPattern of field "label" to empty
            else if l is "unicodeText" then
               set the backPattern of control "text" to empty
            else
               set the backPattern of control l to empty
            end if
      end switch
   end repeat
   
   --check to disabled objects if a multi selection
   if the number of lines in tObjects > 1 then
      repeat for each line l in the cREVMultipleDisabled of this cd
         disable control l
         set the backPattern of control l to empty
         if word 1 of the name of control l is "field" then put empty into control l
         else if word 1 of the name of control l is "button" then set the hilite of control l to false
      end repeat
   end if
end revStandardUpdate


setProp revDisabled pBoolean
   if word 1 of the target is "group" then
      repeat with i = 1 to the number of controls in the target
         set the disabled of control i of the target to pBoolean
      end repeat
   else
      set the disabled of the target to pBoolean
   end if
end revDisabled

on revBuildPalette
   --this handler builds list of which objects to enable and disable and set properties on in each palette
   --based on name and class of each object
   local tControlsList
   --start with the controls that disable when there are multiple objects selected
   set the defaultStack to the target
   if the revAllowMultipleList of this cd is empty then
      repeat with i = 1 to the number of controls
         if the revAllowMultiple of control i is false then put the name of control i & cr after tControlsList
      end repeat
      delete last char of tControlsList
      set the revAllowMultipleList of this cd to tControlsList
      answer "Palette" && the short name of the target && "rebuilt.  Save?" with "No" or "Yes"
      if it is "Yes" then save this stack
   end if
end revBuildPalette

on revMovePalettesForSheet
   -- removes palette windows that may get in the way of a sheet dialog
   local tStacksList
   put the openStacks into tStacksList
   
   local tStackRect
   put the rect of stack "answer dialog" into tStackRect
   
   local tMoveDistance
   repeat for each line l in tStacksList
      if the mode of stack l is 4 then
         if the topLeft of stack l is within tStackRect then
            put item 4 of tStackRect + 20 - item 2 of the topLeft of stack l into tMoveDistance
            move stack l relative 0,tMoveDistance
         end if
      end if
   end repeat
end revMovePalettesForSheet

function revSaveCheck pStack, pNoWarning
   if the secureMode then return true
   put the short name of stack pStack into pStack
   if revIDEStackIsEdited(pStack) and the short name of stack \ 
         (the mainstack of stack pStack) is not the short name of revScriptEditorMain() then
      toplevel stack pStack
      
      local tStackPath
      put the effective fileName of stack pStack into tStackPath
      set the itemDel to "/"
      put item -1 of tStackPath into tStackPath
      set the itemDel to comma
      
      local tWarning
      if tStackPath is empty then
         put "<p><b>Do you want to save changes to stack" && quote & pStack & quote & "</b>" & "<b> before closing?</b><font size=" & quote & "11" & quote & "></p></font>" & cr & "<p><font size=" & quote & "11" & quote & "> </font></p>" & cr & "<p><font size=" & quote & "11" & quote & ">If you don't save, your changes will be lost.</p>" into tWarning
      else
         put "<p><b>Do you want to save changes to stack" && quote & pStack & quote && "and all other stacks in the file" && quote & tStackPath & quote && "before closing?</b><font size=" & quote & "11" & quote & "></p></font>" & cr & "<p> </p>" & cr & "<p><font size=" & quote & "11" & quote & ">If you don't save, your changes will be lost.</p>" into tWarning
      end if
      
      local tHideStack
      if not the visible of stack pStack then
         put true into tHideStack
         show stack pStack
      else
         put false into tHideStack
      end if
      if the mode of stack pStack is 0 or not the visible of stack pStack then -- no sheet
         if pNoWarning then
            answer warning tWarning with "Don't Save" or "Save"
         else 
            answer warning tWarning with "Don't Save" or "Cancel" or "Save"
         end if
      else
         send "revMovePalettesForSheet" to me in 50 milliseconds
         if pNoWarning then 
            answer warning tWarning with "Don't Save" or "Save" as sheet
         else 
            answer warning tWarning with "Don't Save" or "Cancel" or "Save" as sheet
         end if
      end if
      if tHideStack then hide stack pStack
      switch it
         case "Save"
            if the effective filename of stack pStack is not empty then 
               revSave pStack
               if the result is not empty then 
                  return false
               end if
            else 
               # OK-2007-09-26 : Bug 5434. It is possible that the user may change their mind after the save dialog appears. In this case
               # revSaveAs has been modified to return a value in the result, which we check for here.
               revSaveAs pStack
               if the result is not empty then
                  return false
               end if
            end if
            break
         case "Don't Save"
            revIDESetUnedited pStack
            break
         case "Cancel"
            return false
            break
      end switch
   else if word 1 of pStack is "revScriptEditor" and the mode of stack pStack is not 0 then
      -- this will exit to top on cancel
      lock messages
      close stack pStack
      unlock messages
   end if
   return true
end revSaveCheck

on appleEvent p1, p2, p3
   if p1&p2 is "aevtodoc" then
      --appleEvent sent when stack is opened from the finder
      local tData
      request AppleEvent data
      put it into tData
      
      local tExists
      local tCanonical
      repeat for each line l in tData
         lock messages
         put utilityCanonicalizePath(l) into tCanonical
         put (there is a stack tCanonical) into tExists
         unlock messages
         // AL-2014-10-27: [[ Bug 12558 ]] Stack opened in apple event should report correct error
         if not tExists then 
            answer error "Unable to open stack:" && the result
         else 
            go stack tCanonical
            ideMessageSend "ideOpenStack", the long id of stack tCanonical
         end if
      end repeat
      
      exit appleEvent
   end if
   pass appleEvent
end appleEvent

# OK-2007-11-27 : Tidied up
on revSave pWhichStack
   revIDESaveStack the long ID of stack pWhichStack
end revSave

# OK-2007-09-26 : Modified to return a value in the result if the stack is not saved
on revSaveAs pShortName, pSubstackOnly
   revIDEActionSaveStackAs the long id of stack pShortName, pSubstackOnly
end revSaveAs

function revStackFileVersion pStackFile
   return revIDEStackFileVersion(pStackFile)
end revStackFileVersion

on revRemoveRevOnlineKey pKey, pStack
   local tCustomKeys
   put the customKeys["cREVOnline"] of stack pStack into tCustomKeys
   
   local tOffset
   put lineOffset(pKey,tCustomKeys) into tOffset
   if tOffset is not 0 then
      delete line tOffset of tCustomKeys
      set the customKeys["cREVOnline"] of stack pStack to tCustomKeys
   end if
end revRemoveRevOnlineKey

function revFixPath pPath
   local tReturnPath
   put pPath into tReturnPath
   
   local tRemoveChars
   if the platform is "MacOS" then
      put ":" & tab into tRemoveChars
   else if the platform is "Win32" then
      put "\/:*?<>|" & quote & tab into tRemoveChars
   else
      put ":?*<>/\()[]{}|'`" & quote & tab into tRemoveChars
      -- SN-2015-03-09: [[ Bug 14712 ]] Do not put the lower case version
      -- of the name
      -- put tolower(pPath) into tReturnPath
   end if
   if revExtensionShow() then
      if not (tReturnPath ends with ".rev" or tReturnPath ends with ".livecode") then
         put ".livecode" after tReturnPath
      end if
   end if
   repeat for each char c in tRemoveChars
      replace c with "_" in tReturnPath
   end repeat
   return tReturnPath
end revFixPath

on newGroup
   selectedObjectChanged
   set the cREVGeneral["revUniqueID"] of the target to the milliseconds
   
   //Bug 10669
   repeat with x = 1 to the number of controls of the target
      set the cREVGeneral["revUniqueID"] of control x of the target to the milliseconds
   end repeat
   
   revUpdateAOControls
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass newGroup
end newGroup


on newButton
   revNewButton the long id of the target
   revUpdateAOControls
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass newButton
end newButton

on revNewButton pTarget
   if exists(pTarget) is false then exit revNewButton
   if the width of pTarget < 9 and the height of pTarget < 9 then
      if the style of pTarget is "menu" then
         if the menuMode of pTarget is "tabbed" then
            set the width of pTarget to the cTabButtonWidth of stack "revPreferences"
            set the height of pTarget to the cTabButtonHeight of stack "revPreferences"
         else
            set the width of pTarget to the cMenuWidth of stack "revPreferences"
            set the height of pTarget to the cMenuHeight of stack "revPreferences"
         end if
      else
         set the width of pTarget to the cButtonWidth of stack "revPreferences"
         set the height of pTarget to the cButtonHeight of  stack "revPreferences"
      end if
   end if
   set the defaultStack to revTargetStack(pTarget)
   
   local tName
   if the cREVGeneral["viewerobject"] of pTarget is true then
      put the short name of pTarget into tName
      replace "Button" with "Report" in tName
      
      local tCheck
      repeat
         put "btn" && quote & tName & quote into tCheck
         if not exists(tCheck) then exit repeat
         add 1 to word -1 of tName
      end repeat
      set the name of pTarget to tName
      set the cREVReport["viewername"] of pTarget to tName
   end if
   set the cREVGeneral["revUniqueID"] of pTarget to the milliseconds
   
   // PM-2015-09-17: [[ Bug 15918 ]] Allow the new btn to appear offscreen
end revNewButton

on newField
   if the width of the target < 9 and the height of the target < 9 then
      if the text target is "label text" then
         set the width of the target to the cLabelFieldWidth of stack "revPreferences"
         set the height of the target to the cLabelFieldHeight of stack "revPreferences"
      else
         set the width of the target to the cFieldWidth of stack "revPreferences"
         set the height of the target to the cFieldHeight of stack "revPreferences"
      end if
   end if
   set the cREVGeneral["revUniqueID"] of the target to the milliseconds
   // PM-2015-09-17: [[ Bug 13826 ]] Allow a new field to appear offscreen
   revUpdateAOControls
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass newField
end newField

on newScrollbar
   if the width of the target < 9 and the height of the target < 9 then
      if the platform is "MacOS" then
         if the style of the target is not "progress" then
            set the width of the target to the cMacOSScrollbarWidth of stack "revPreferences"
            set the height of the target to the cMacOSScrollbarHeight of stack "revPreferences"
         else
            set the width of the target to the cMacOSProgressScrollbarWidth of stack "revPreferences"
            set the height of the target to the cMacOSProgressScrollbarHeight of stack "revPreferences"
         end if
      else
         set the width of the target to the cScrollbarwidth of stack "revPreferences"
         set the height of the target to the cScrollbarHeight of stack "revPreferences"
      end if
   end if
   set the cREVGeneral["revUniqueID"] of the target to the milliseconds
   // PM-2015-09-17: [[ Bug 13826 ]] Allow a new scrollbar to appear offscreen
   revUpdateAOControls
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass newScrollbar
end newScrollbar

on newImage
   if the width of the target < 9 and the height of the target < 9 then
      set the width of the target to the cREVImageWidth of stack "revPreferences"
      set the height of the target to the cREVImageHeight of stack "revPreferences"
   end if
   set the cREVGeneral["revUniqueID"] of the target to the milliseconds
   // PM-2015-09-17: [[ Bug 13826 ]] Allow a new image to appear offscreen
   revUpdateAOControls
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass newImage
end newImage

on newEPS
   
   local tStack
   put revTargetStack(the long id of the target) into tStack
   lock screen
   set the width of the target to (the width of stack tStack / 2)
   set the height of the target to (the height of stack tStack / 2)
   unlock screen
   set the cREVGeneral["revUniqueID"] of the target to the milliseconds
   // PM-2015-09-17: [[ Bug 13826 ]] Allow a new EPS to appear offscreen
   revUpdateAOControls
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass newEPS
end newEPS



on newGraphic
   set the cREVGeneral["revUniqueID"] of the target to the milliseconds
   // PM-2015-09-17: [[ Bug 13826 ]] Allow a new graphic to appear offscreen
   revUpdateAOControls
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass newGraphic
end newGraphic

on newPlayer
   if the width of the target < 9 and the height of the target < 9 then
      set the width of the target to the cREVPlayerWidth of stack "revPreferences"
      set the height of the target to the cREVPlayerHeight of stack "revPreferences"
   end if
   set the cREVGeneral["revUniqueID"] of the target to the milliseconds
   // PM-2015-09-17: [[ Bug 13826 ]] Allow a new player to appear offscreen
   revUpdateAOControls
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass newPlayer
end newPlayer

on newCard
   if there is a stack "revApplicationOverview" then
      if the mode of stack "revApplicationOverview" is not 0
      then send "revUpdateCards revTargetStack(the long id of the target)" to stack "revApplicationOverview"
      if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass newCard
   end if
end newCard

on newStack
   lock screen
   lock messages
   
   local tName
   put the short name of the target into tName
   set the name of the target to tName && "1"
   if there is a stack tName then
      repeat
         if word -1 of tName is a number then add 1 to word -1 of tName
         else put " 1" after tName
         if not (there is a stack tName) then
            set the name of the target to tName
            show stack tName
            exit repeat
         end if
      end repeat
   else
      set the name of the target to tName
   end if
   send "revUpdatePaletteStack" to me in 100 milliseconds
   if there is a stack "revApplicationOverview" then
      if the mode of stack "revApplicationOverview" is not 0
      then send "revNewStack the short name of the target" to stack "revApplicationOverview"
   end if
   unlock screen
   unlock messages
   pass newStack
end newStack

# Parameters
#   pObject : reference to the object about to be deleted
# Description
#   Updates the property inspector, application browser and script editor
#   in response to pObject being deleted.
command revIDEHandleObjectDeleted pObject
   -- Need to pass the object as the target may have changed.
   revDeleteLinkedObject pObject
   revUpdateAOControls
   revIDEUpdateScriptEditorOnObjectDeletion pObject
end revIDEHandleObjectDeleted

# Parameters
#   pObject : reference to the object about to be deleted
# Description
#   Updates the script editor in response to pObject being deleted.
private command revIDEUpdateScriptEditorOnObjectDeletion pObject
   send "revSEObjectDeleted pObject" to revScriptEditorMain()
end revIDEUpdateScriptEditorOnObjectDeletion

on deleteButton
   revIDEHandleObjectDeleted the long id of the target
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass deleteButton
   end if
end deleteButton

on deleteField
   revIDEHandleObjectDeleted the long id of the target
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass deleteField
   end if
end deleteField

on deleteGroup
   revIDEHandleObjectDeleted the long id of the target
   
   if the mode of stack "revMenuManager" is not 0 and there is a stack (the cREVDefaultStack of stack "revMenuManager") and (there is a background id (the cREVMenuID of stack "revMenuManager") of stack (the cREVDefaultStack of stack "revMenuManager")) and the long id of the target is the long id of background id (the cREVMenuID of stack "revMenuManager") of stack (the cREVDefaultStack of stack "revMenuManager") then 
      send "revDeleteMenuManagerGroup" to card 1 of stack "revMenuManager"
   end if
   
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass deleteGroup
   end if
end deleteGroup

on deleteGraphic
   revIDEHandleObjectDeleted the long id of the target
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass deleteGraphic
   end if
end deleteGraphic

on deletePlayer
   revIDEHandleObjectDeleted the long id of the target
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass deletePlayer
   end if
end deletePlayer

on deleteScrollbar
   revIDEHandleObjectDeleted the long id of the target
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass deleteScrollbar
   end if
end deleteScrollbar

on deleteImage
   revIDEHandleObjectDeleted the long id of the target
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass deleteImage
   end if
end deleteImage

on deleteCard
   revDeleteLinkedObject
   if there is a stack "revApplicationOverview" then
      if the mode of stack "revApplicationOverview" is not 0 then
         send "revUpdateCards revTargetStack(the long id of the target)" to stack "revApplicationOverview" in 500 milliseconds
      end if
   end if
   revIDEUpdateScriptEditorOnObjectDeletion the long id of the target
   
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass deleteCard
   end if
end deleteCard

on deleteStack
   # OK-2008-07-29 : Bug 6796 - The deletestack message is sent to the card not the stack
   revIDEHandleObjectDeleted the long id of the long owner of the target
   
   # BB-2014-07-25 : Bug 9598 - Catch an error being thrown when LiveCode IDE is shutting down
   # Fix courtesy of Mark Wieder
   try
      revSetActiveStacks
   catch e
   end try
   
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then
      pass deleteStack
   end if
end deleteStack

on newTool
   global gREVMessageDispatch
   repeat for each line l in gREVMessageDispatch["revNewTool"]
      send "revNewTool" to this cd of stack l
   end repeat
   
   if "revShortCutsLibrary" is in revInternal__ListLoadedLibraries() then	
      send "revNewTool" to stack "revShortCutsLibrary"
   end if
   
   if the tool is "browse tool" then
      set the defaultStack to the topStack
      if the editBg then set the editBg to false
      if there is a stack "revApplicationOverview" then
         if the mode of stack "revApplicationOverview" is not 0 \
               and the short name of this cd of stack "revApplicationOverview" is "Cards and Controls" then
            send "revRefreshControls true, true" to stack "revApplicationOverview"
         end if
      end if
   end if
   
   if "revReshapeLibrary" is in revInternal__ListLoadedLibraries() then
      send "revNewTool" to stack "revReshapeLibrary"
   end if	
   
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass newTool
end newTool

function revCheckGroupDelete
   if the selectedField is not empty then return true
   repeat for each line l in the selectedObjects
      if word 1 of l is "group" and the number of lines in the cardNames of l > 1 then
         answer warning "This group is placed on multiple cards," & cr & "really delete it?" with "Yes" or "No"
         if it is "No" then return false
      end if
      if word 1 of l is "group" and the dgProps["control type"] of l is "Data Grid" then
         answer warning "Would you like to delete the record template associated with this data grid? This action cannot be undone." with "Yes" or "No"
         if it is "Yes" then 
            local tTemplate
            put the dgProps["row template"] of l into tTemplate
            
            local tCardWord
            put wordoffset("card",tTemplate) into tCardWord
            
            local tTemplateCard
            put word tCardWord to -1 of tTemplate into tTemplateCard
            
            local tStackWord
            put wordoffset("stack",tTemplate) into tStackWord
            
            local tTemplateStack
            put word tStackWord to -1 of tTemplate into tTemplateStack
            if the number of cards in stack tTemplateStack is 2 then delete stack tTemplateStack
            else 
               delete tTemplateCard
            end if
         end if
      end if
   end repeat
   return true
end revCheckGroupDelete

function revLookUpPackage pPath
   local tPath
   put pPath into tPath
   if char -4 to -1 of tPath is ".app" then
      put "/Contents/MacOS" after tPath
      
      local tReturn
      put the directory into tReturn
      set the directory to tPath
      
      local tFiles
      put the files into tFiles
      set the directory to tReturn
      --answer tPath & "/" & line 1 of tFiles
      return tPath & "/" & line 1 of tFiles
   end if
   return tPath
end revLookUpPackage

on reloadStack pStackName, pFileName
   if the filename of stack pStackName is pFileName then
      toplevel pStackName
   else
      set the defaultStack to pStackName
      
      local tFilePath
      put the effective fileName of stack pStackName into tFilePath
      if the number of words in tFilePath > 0 then put comma && pStackName & "?" after tFilePath else put pStackName & "?" into tFilepath
      answer warning "A stack with the same name as the one you are trying to load is already open." & cr & "Before loading" && pFileName & ", what do you want to do with stack:" & cr & tFilePath with "Save" or "Purge" or "Cancel"
      if it is "Cancel" then exit reloadStack
      if gREVSuppressMessages then
         lock messages
         send "revInsertMessageBlock" to me in 100 milliseconds
         revInternal__UnloadLibrary "revNoMessagesLibrary"
      end if
      
      local tLockMessages
      put the lockMessages into tLockMessages
      if it is "Purge" then
         revAOUpdateForDeleteStack pStackName
         lock messages
         delete stack pStackName
         set the lockMessages to tLockMessages
         go stack pFileName
      else
         if the filename of stack pStackName is empty then
            revSaveAs pStackName
         else
            revSave pStackName
         end if
         revAOUpdateForDeleteStack pStackName
         lock messages
         delete stack pStackName
         set the lockMessages to tLockMessages
         go to stack pFileName
      end if
      
      revAOUpdateForDeleteStack pStackName
      lock messages
      delete stack pStackName
      set the lockMessages to tLockMessages
      go to stack pFileName
   end if
   
   if there is a stack "revApplicationOverview" then
      send "revNewStack the short name of stack pFileName" to stack "revApplicationOverview"
   end if
end reloadStack

on revAOUpdateForDeleteStack pStackName
   if there is a stack "revApplicationOverview" then
      if the mode of stack "revApplicationOverview" is not 0 then
         local tStacks
         put pStackName into tStacks
         if the substacks of stack pStackName is not empty
         then put cr & the substacks of stack pStackName after tStacks
         send "revAODeleteStack pStackName, tStacks" to stack "revApplicationOverview"
      end if
   end if
end revAOUpdateForDeleteStack

on revInsertMessageBlock
   revInternal__LoadLibrary "revNoMessagesLibrary"
end revInsertMessageBlock

function revExtensionShow
   --returns true if windows is hiding file extensions for files registered, otherwise returns false
   if the platform is "MacOS" then
      return the cREVExtension of stack "revPreferences"
   else if the platform is "Win32" then
      return queryRegistry("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\HideFileExt") is not the cREVGeneral["cREVHideFileTypes"] of stack "Home"
   end if
   return true
end revExtensionShow

---------------------------------------- Rulers ----------------------------------------

on revCalculateRulers
   lock messages
   hide stack "revRulersH"
   hide stack "revRulersV"
   switch the cREVRulerMeasurement of stack "revPreferences"
      case "centimeters"
         set the icon of btn 1 of stack "revRulersH" to 200708
         set the icon of btn 1 of stack "revRulersV" to 200711
         break
      case "inches"
         set the icon of btn 1 of stack "revRulersH" to 200709
         set the icon of btn 1 of stack "revRulersV" to 200712
         break
      case "pixels"
         set the icon of btn 1 of stack "revRulersH" to 200705
         set the icon of btn 1 of stack "revRulersV" to 200713
         break
   end switch
   if the platform is "MacOS" then
      set the width of stack "revRulersH" to the width of the topStack+26
      set the left of btn 1 of stack "revRulersV" to -1
      set the height of stack "revRulersV" to the height of the topStack+3
      set the top of btn 1 of stack "revRulersV" to -31
      set the left of btn 1 of stack "revRulersH" to -2
      set the top of btn 1 of stack "revRulersH" to -1
      set the topLeft of stack "revRulersV" to item 1 of the topLeft of the topStack - 20,item 2 of the topLeft of the topStack + 5
   else
      set the top of btn 1 of stack "revRulersH" to 0
      set the width of stack "revRulersH" to the width of the topStack+24
      set the left of btn 1 of stack "revRulersV" to 0
      set the height of stack "revRulersV" to the height of the topStack+3
      set the top of btn 1 of stack "revRulersV" to -30
      set the left of btn 1 of stack "revRulersH" to -1
      set the topLeft of stack "revRulersV" to item 1 of the topLeft of the topStack - 20,item 2 of the topLeft of the topStack + 1
   end if
   set the topLeft of stack "revRulersH" to item 1 of the bottomLeft of the topStack - 20, item 2 of the bottomLeft of the topStack+3
   set the cREVHSubtract of stack "revRulersH" to item 1 of the topLeft of the topStack - item 1 of the topLeft of stack "revRulersH"
   set the cREVVSubtract of stack "revRulersH" to item 2 of the topLeft of the topStack - item 2 of the topLeft of stack "revRulersH"
   set the cREVHSubtract of stack "revRulersV" to item 1 of the topLeft of the topStack - item 1 of the topLeft of stack "revRulersV"
   set the cREVVSubtract of stack "revRulersV" to item 2 of the topLeft of the topStack - item 2 of the topLeft of stack "revRulersV"
   set the cREVCurrentStack of stack "revRulersH" to the short name of the topStack
   set the right of grc "end marker" of stack "revRulersH" to the width of the topStack + 27
   revInternal__LoadLibrary "revRulersScriptLibrary"
   show stack "revRulersH"
   show stack "revRulersV"
   unlock messages
end revCalculateRulers

on revPartCalculateRulers
   -- lock/unlock screen to prevent flickering when moving the stack and rulers are enabled
   lock screen
   lock messages
   --this can be done with flicker by altering the width first, then the topLeft
   
   local tRect
   put the rect of stack "revRulersH" into tRect
   put item 1 of the bottomLeft of the topStack-20 into item 1 of tRect
   put item 2 of the bottomLeft of the topStack+3 into item 2 of tRect
   if the platform is "MacOS" then add 4 to item 2 of tRect
   put item 2 of tRect + 16 into item 4 of tRect
   if the platform is "MacOS" then subtract 2 from item 4 of tRect
   put item 1 of tRect + the width of the topStack + 24 into item 3 of tRect -- set width
   if the platform is "MacOS" then add 2 to item 3 of tRect
   set the rect of stack "revRulersH" to tRect
   --now the V ruler
   put the rect of stack "revRulersV" into tRect
   put item 1 of the topLeft of the topStack - 20 into item 1 of tRect
   put item 1 of tRect + 16 into item 3 of tRect
   if the platform is "MacOS" then subtract 2 from item 3 of tRect
   put item 2 of the topLeft of the topStack into item 2 of tRect
   if the platform is "MacOS" then add 1 to item 2 of tRect
   put item 2 of tRect + the height of the topStack + 3 into item 4 of tRect -- set height
   if the platform is "MacOS" then add 2 to item 4 of tRect
   set the rect of stack "revRulersV" to tRect
   
   local tRight
   if the platform is not "MacOS" then put 3 into tRight else put 4 into tRight
   set the right of grc "end marker" of stack "revRulersH" to the right of cd 1 of stack "revRulersH" +tRight
   set the cREVHSubtract of stack "revRulersH" to item 1 of the topLeft of the topStack - item 1 of the topLeft of stack "revRulersH"
   set the cREVVSubtract of stack "revRulersH" to item 2 of the topLeft of the topStack - item 2 of the topLeft of stack "revRulersH"
   set the cREVHSubtract of stack "revRulersV" to item 1 of the topLeft of the topStack - item 1 of the topLeft of stack "revRulersV"
   set the cREVVSubtract of stack "revRulersV" to item 2 of the topLeft of the topStack - item 2 of the topLeft of stack "revRulersV"
   set the cREVCurrentStack of stack "revRulersH" to the short name of the topStack
   unlock messages
   unlock screen
end revPartCalculateRulers

---------------------------------------- end of Rulers ----------------------------------------
local lTimerID

on selectedObjectChanged
   if "updateForSelectedObjectChanged" is in the pendingMessages then cancel lTimerID
   send "updateForSelectedObjectChanged" to me in 200 milliseconds
   put the result into lTimerID
end selectedObjectChanged

# OK-2008-03-20 : Moved variable declaration as it was being used before declaration
local sHiddenPalettes

on updateForSelectedObjectChanged
   global gREVStopUpdates, gREVStacksList, gREVSelectionDescription
   global gREVMessageDispatch
   
   if gREVStopUpdates then exit updateForSelectedObjectChanged
   
   --check palettes are on screen, workaround for stacks in float about all move that are toplevel
   
   if sHiddenPalettes is an array then
      revSEShowPalettes
   end if   
   
   --make sure plugins are still sent legacy messages
   repeat for each line l in gREVMessageDispatch["revSelectedObjectChanged"]
      send "revSelectedObjectChanged" to this cd of stack l
   end repeat
   
   ideMessageSend "ideSelectedObjectChanged"
end updateForSelectedObjectChanged

on preOpenStack
   lock screen
   local tTargetStack
   put revIDEStackOfObject(the long id of the target) into tTargetStack
   
   if revIDEStackIsIDEStack(tTargetStack) then   
      # AL-2015-09-15: [[ Bug 15745 ]] Ensure palettes don't get placed off screen
      revIDEEnsureOnScreen the short name of tTargetStack
   end if
   unlock screen
   
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass preOpenStack
end preOpenStack

function revStyle pWhichString
   constant kObjectTypes="button,field,graphic,group,scrollbar,image,player,eps"
   switch
      case word 1 of pWhichString is "card" and word 2 of pWhichString is among the items of kObjectTypes
         --hcAddressing special case
         return word 2 of pWhichString
         break
      case word 1 of pWhichString is "the"
         --templateObject
         return char 9 to -1 of word 2 of pWhichString
         break
      default
         return word 1 of pWhichString
         break
   end switch
end revStyle

on undoChanged
   global gREVUndoList
   put empty into gREVUndoList
end undoChanged

local lSelectionTimerID, lSelectionObject


on selectionChanged
   
end selectionChanged



on openField
   put (the target) into lSelectionObject
   if "revUpdateSelectionChanged" is not in the pendingMessages then
      send "revUpdateSelectionChanged" to me in 400 milliseconds
      put the result into lSelectionTimerID
   else
      cancel lSelectionTimerID
      send "revUpdateSelectionChanged" to me in 400 milliseconds
      put the result into lSelectionTimerID
   end if
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass openField
end openField


on revUpdateSelectionChanged
   
end revUpdateSelectionChanged

on exitField
   selectionChanged
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass exitField
end exitField

on closeField
   selectionChanged
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass closeField
end closeField

on libraryStack
   if the mode of stack "Message Box" is not 0 \
         and the short name of this cd of stack "Message Box" is "stacksInUse"
   then send "revUpdateLibraryStacks" to this cd of stack "Message Box"
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass libraryStack
end libraryStack

on releaseStack
   if the mode of stack "Message Box" is not 0 \
         and the short name of this cd of stack "Message Box" is "stacksInUse"
   then send "revUpdateLibraryStacks" to this cd of stack "Message Box"
   if not gREVSuppressMessages or (gREVSuppressMessages and revOKTarget()) then pass releaseStack
end releaseStack

on keyDown pWhich
   if word 1 of the target is "card" and \
         the mode of stack "Message Box" is not 0 \
         and the short name of this cd of stack "Message Box" is among the items of "Single Line,Multiple Lines" then
      dispatch "revIDEFocusOnMessageBox" to stack "Message Box" with pWhich
   end if
   pass keyDown
end keyDown

on mainStackChanged
   if there is a stack "revApplicationOverview" then
      if the mode of stack "revApplicationOverview" is not 0
      then send "revMainStackChanged the long id of the target" to stack "revApplicationOverview" 
   end if
end mainStackChanged

function revReturnSpaces pString
   local tSpaces
   put empty into tSpaces
   repeat for each char c in pString
      if c is not space then exit repeat
      put space after tSpaces
   end repeat
   return tSpaces
end revReturnSpaces

on revDeleteLinkedObject pTarget
   lock screen
   if pTarget is empty then put the long id of the target into pTarget
   local tLinkedPalettesList
   put revLinkedSubControlPalettes(pTarget) into tLinkedPalettesList
   repeat for each line l in tLinkedPalettesList
      close stack l
   end repeat
   unlock screen
end revDeleteLinkedObject

on revKillRedundantPalettes
   lock screen
   local tPalettes
   put revPalettesList() into tPalettes
   repeat for each line l in tPalettes
      repeat for each line m in the cREVLinked of stack l
         if (there is not a m) then 
            close stack l
            exit repeat
         end if
      end repeat
   end repeat
   unlock screen
end revKillRedundantPalettes

on revKillAllLinkedPalettes
   lock screen
   
   local tPalettes
   put revPalettesList() into tPalettes
   repeat for each line l in tPalettes
      if the cREVLinked of stack l is not empty
      then close stack l
   end repeat
   unlock screen
end revKillAllLinkedPalettes

on revKill
   lock messages;quit;
end revKill

function revScriptEditors pStackPath
   return _revScriptEditorsNew(pStackPath)
end revScriptEditors

# Change this for now to prevent the ide interfering with the new script editor
constant kScriptEditorPrefix = "revNewScriptEditor "

private function _revScriptEditorsNew pStack
   local tStacks
   put the mainStack of pStack into tStacks
   put return & the substacks of pStack after tStacks
   
   local tScriptEditors
   put the openStacks into tScriptEditors
   filter tScriptEditors with kScriptEditorPrefix & "*"
   
   local tFoundEditors
   repeat for each line tEditor in tScriptEditors
      local tTargetObjects
      send "revSEGetTargetObjects" to tEditor
      put the result into tTargetObjects
      
      repeat for each line tTargetObject in tTargetObjects
         if revTargetStack(tTargetObject) is among the lines of tStacks then
            put tEditor & return after tFoundEditors
         end if
      end repeat
   end repeat
   delete last char of tFoundEditors
   return tFoundEditors
end _revScriptEditorsNew

# Parameters
#   pObject : reference to the object to edit the script of
# Description
#   Creates a new script editor for the specified object and opens it.
command revEditScriptInNewWindow pObject, pSpecial
   # OK-2009-03-16 : Bug 6620 - The script editor can be broken if a user has gREVDevelopment true
   # and aborts a repeat loop that is opening script editors...
   local tOldAllowInterrupts
   put the allowInterrupts into tOldAllowInterrupts
   set the allowInterrupts to false
   
   lock cursor
   set the cursor to watch
   
   local tEditorCount
   put the number of lines of revListScriptEditors() into tEditorCount
   
   local tNewEditorName
   put kScriptEditorPrefix & tEditorCount + 1 into tNewEditorName
   
   # OK-2008-12-03 : Bug 6926 and 7032 - Always ensure that any old script editors have been fully purged,
   # as some users may lock messages and close the script editor from the message box, preventing it from running
   # code needed to finalize itself.
   if there is a stack tNewEditorName then
      delete stack tNewEditorName
   end if
   
   local tTemplateVisibility, tTemplateRect
   put the visible of revScriptEditorTemplate() into tTemplateVisibility
   set the visible of revScriptEditorTemplate() to false
   set the _ideoverride of revScriptEditorTemplate() to true
   
   local tEditor
   lock messages
   
   # MW-2012-02-21: If 'special' is set then we make sure the editor's stack script is set
   #    rather than using a behavior - this allows that editor to edit the template stack script.
   
   
   ## EJB 2013-12-05: Bug 11546
   ## Reset the template group before cloning the stack so any properties set elsewhere are not inherited by the editor group
   reset the templateGroup
   if pSpecial then
      clone invisible revScriptEditorTemplate() as "revTempScriptEditor"
      set the behavior of stack "revTempScriptEditor" to empty
      set the script of stack "revTempScriptEditor" to the script of stack revIDEScriptEditorBehavior("stack")
      clone invisible stack "revTempScriptEditor" as tNewEditorName
      delete stack "revTempScriptEditor"
   else
      clone invisible revScriptEditorTemplate() as tNewEditorName
      set the behavior of stack tNewEditorName to the long id of stack revIDEScriptEditorBehavior("stack")
   end if
   
   set the cIDETransient of it to true
   
   put the long id of it into tEditor
   send "setBehaviors" to tEditor
   
   if tTemplateVisibility then
      set the visible of revScriptEditorTemplate() to true
   end if
   
   unlock messages
   
   set the mainstack of tEditor to the short name of revScriptEditorMain()
   set the destroyStack of tEditor to true
   set the destroyWindow of tEditor to true
   set the label of tEditor to the short name of tEditor
   
   set the cMutable of tEditor to true
   set the _ideoverride of tEditor to true
   
   # OK-2008-07-24 : Note the use of call instead of send here. This is important because
   # it prevents the defaultStack changing when debugging, which can potentially break
   # user code in the debugger which would have run fine otherwise.
   call "revSEInitialize true" to tEditor
   call "revSEAddTargetObject pObject" to tEditor
   send "revGoScriptEditor tEditor, true" to me in 0 milliseconds
   
   # OK-2008-06-29 : Bug 6661 - This is sent last because setting the script editor's current object
   # also focuses and selects the correct point in the script field, this needs to be done after the script
   # editor window has been opened otherwise doing the select command will throw an error and result
   # in char 1 to 0 being selected instead of what the user wants.
   send "revSESetCurrentObject pObject" to tEditor in 0 milliseconds
   unlock cursor
   
   set the allowInterrupts to tOldAllowInterrupts
end revEditScriptInNewWindow


# Returns
#   A list of the currently open script editors, ordered with topmost first.
function revListScriptEditors
   local tStacks
   put the openStacks into tStacks
   filter tStacks with kScriptEditorPrefix & "*"
   
   local tFullStacks
   repeat for each line tStack in tStacks
      put the long id of stack tStack & return after tFullStacks
   end repeat
   delete the last char of tFullStacks
   
   return tFullStacks
end revListScriptEditors

# Returns
#   The long id of the topmost script editor, or empty if there is no script editor open.
function revTopMostScriptEditor pMode
   local tEditors
   put revListScriptEditors() into tEditors
   
   if pMode is empty then
      return line 1 of tEditors
   end if
   
   repeat for each line tEditor in tEditors
      dispatch "revSEGetMode" to tEditor
      if the result is pMode then
         return tEditor
      end if
   end repeat
   
   return empty
end revTopMostScriptEditor

function revScriptEditorTemplate
   # For now instead of adding the stack properly, we just ensure it is in memory when asked for
   get revScriptEditorMain()
   
   # The script editor template is a substack of the main script editor stack.
   return the long id of stack "revSETemplate"
end revScriptEditorTemplate

function revScriptEditorMain
   --return the long id of stack (revEnvironmentToolsetPath() & slash & "revscripteditor.rev")
   # OK-2008-11-04 : Cannot refer to the script editor by path because it has no path in Media.
   return the long id of stack "revNewScriptEditor"
end revScriptEditorMain
   
command revGoScriptEditor pEditor, pPosition
   lock screen
   lock messages
   toplevel pEditor
   unlock messages
   # AL-2015-10-01: [[ Bug 16016 ]] Ensure the palette rect is set after the go command
   #  as otherwise the engine closes and reopens the stack, resulting in it being bound 
   #  to the windowBoundingRect (due to some very specific properties of the script editor)
   if pPosition then
      revIDEPositionPalette the short name of pEditor
   end if
   set the visible of pEditor to true
   unlock screen 
   
   # OK-2008-08-18 : Bug 6935 - The script editor should be un-iconified here.
   if the iconic of pEditor then
      set the iconic of pEditor to false
   end if
   
   # OK-2008-06-24 : Bug 6603 - Palettes not hidden when script editor first opens
   revSEHidePalettes
end revGoScriptEditor

function revIsMenuBarGroup pGroupID
   local tOwnerStack
   put word wordOffset("stack",pGroupID)+1 of pGroupID into tOwnerStack
   put char 2 to -2 of tOwnerStack into tOwnerStack
   if the short name of pGroupID is the menubar of the stack tOwnerStack or the long name of pGroupID is the defaultMenuBar
   then return true
   else return false
end revIsMenuBarGroup

function revMenuManagerGroup pGroups
   if the mode of stack "revMenuManager" is 0 then return false
   
   local tMenuManagerBG
   if there is not a bg id (the cREVMenuID of stack "revMenuManager") \
         of stack (the cREVDefaultStack of stack "revMenuManager") then return false
   put the long id of bg id (the cREVMenuID of stack "revMenuManager") \
         of stack (the cREVDefaultStack of stack "revMenuManager") into tMenuManagerBG
   repeat for each line l in pGroups
      if l is tMenuManagerBG then return true
   end repeat
   return false
end revMenuManagerGroup

on errorDialog pWhatError, pWhatError2
   if revTestEnvironment() then
      pass errorDialog
   end if
   
   ######################
   close printing
   global gREVSuppressErrors, gREVDevelopment
   if gREVDevelopment then write the params & cr & the long time & cr & "--------" & cr & cr to stdOut
   if gREVSuppressErrors then exit errorDialog
   filter pWhatError without "*,0,0"
   if (item 1 of pWhatError is not a number or item 2 of pWhatError is not a number) and the number of words in pWhatError is not 0 then
      answer "The following user thrown error was generated and not handled, so it was intercepted by LiveCode:" & cr & cr & the params
      exit errorDialog
   end if
   if the number of lines in pWhatError is 0 then exit errorDialog -- bogus error
   revIDEErrorDialog pWhatError, pWhatError2
end errorDialog


----------------------------------function to list all the groups (including nested ones) in a stack

function revBackgroundNames pStack
   local tBackgroundIDS
   put revBackgroundIDS(pStack) into tBackgroundIDS
   
   local tBackgroundNames
   put empty into tBackgroundNames
   repeat for each line l in tBackgroundIDS
      if quote is in the name of bg id l of stack pStack
      then put the short name of bg id l of stack pStack &cr after tBackgroundNames
      else put the name of bg id l of stack pStack & cr after tBackgroundNames
   end repeat
   return tBackgroundNames
end revBackgroundNames

function revBackgroundIDs pStack
   local tBackgrounds
   put empty into tBackgrounds
   
   local tNumBgs
   put the num of bgs in stack pStack into tNumBgs
   repeat with i = 1 to tNumBgs
      if the id of bg i of stack pStack is not among the lines of tBackgrounds
      then put the id of bg i of stack pStack & cr after tBackgrounds
      repeat with j = 1 to the num of grps in bg i of stack pStack
         if the id of grp j of bg i of stack pStack is not among the lines of tBackgrounds
         then put the id of grp j of bg i of stack pStack & cr after tBackgrounds
      end repeat
   end repeat
   delete last char of tBackgrounds
   return tBackgrounds
end revBackgroundIDs

----------------------------------

--------------------------------------------------------------------------
Property Palette Functions
--------------------------------------------------------------------------

function revLinkedPalettesList pLinkedObjects
   local tOpenStacks
   put the openStacks into tOpenStacks
   filter tOpenStacks with "revPropertyPalette*"
   
   local tLinkedPalettes
   put empty into tLinkedPalettes
   repeat for each line l in pLinkedObjects
      repeat for each line m in tOpenStacks
         if l is among the lines of the cREVLinked of stack m and m is not among the lines of tLinkedPalettes 
         then put m & cr after tLinkedPalettes
      end repeat
   end repeat
   delete last char of tLinkedPalettes
   return tLinkedPalettes
end revLinkedPalettesList

function revLinkedSubControlPalettes pObjects
   local tOpenStacks
   put the openStacks into tOpenStacks
   filter tOpenStacks with "revPropertyPalette*"
   
   local tLinkedPalettes
   put empty into tLinkedPalettes
   repeat for each line l in pObjects
      repeat for each line m in tOpenStacks
         if l is in the cREVLinked of stack m and m is not among the lines of tLinkedPalettes 
         then put m & cr after tLinkedPalettes
      end repeat
   end repeat
   delete last char of tLinkedPalettes
   return tLinkedPalettes
end revLinkedSubControlPalettes

function revLinkedAppearancePalettesList pLinkedObjects
   local tOpenStacks
   put the openStacks into tOpenStacks
   filter tOpenStacks with "revAppearance*"
   
   local tLinkedPalettes
   put empty into tLinkedPalettes
   repeat for each line l in pLinkedObjects
      repeat for each line m in tOpenStacks
         if l is among the lines of the cREVLinked of stack m and m is not among the lines of tLinkedPalettes 
         then put m & cr after tLinkedPalettes
      end repeat
   end repeat
   delete last char of tLinkedPalettes
   return tLinkedPalettes
end revLinkedAppearancePalettesList

function revPalettesList
   local tPalettes
   put the openStacks into tPalettes
   filter tPalettes with "revPropertyPalette*"
   return tPalettes
end revPalettesList

function revPropertyPalettes pObjects
   --returns a list of all palettes affected by given objects
   local tOpenStacks
   put the openStacks into tOpenStacks
   filter tOpenStacks with "revPropertyPalette*"
   
   local tObjects
   put the selobj into tObjects
   if tObjects is empty then put the long id of the topStack into tObjects
   
   local tPalettes
   put empty into tPalettes
   repeat for each line l in pObjects
      repeat for each line m in tOpenStacks
         --check if stack is linked to object or is the active palette and the object is in the selection
         if (l is among the lines of the cREVLinked of stack m \
               or (the cREVLinked of stack m is empty and l is among the lines of tObjects)) \
               and m is not among the lines of tPalettes
         then put m & cr after tPalettes
      end repeat
   end repeat
   delete last char of tPalettes
   return tPalettes
end revPropertyPalettes

function revPaletteTitle pObjects
   if pObjects is empty then return "Inspector"
   if the num of lines in pObjects is 1 then
      if word 1 of pObjects is "the" then return pObjects
      return the name of pObjects, " ID" && the id of pObjects
   else
      local tAllSameInfo
      put revAllSameType2(pObjects) into tAllSameInfo
      if (line 1 of tAllSameInfo)
      then return "Multiple" && (line 2 of tAllSameInfo) & "s"
      else return "Multiple objects"
   end if
end revPaletteTitle

function revAllSameType2 pObjects
   --first line true or false
   --second line the object type
   
   local tAllSame
   put true into tAllSame
   
   local tFirstObject
   put line 1 of pObjects into tFirstObject
   
   local tFirstObjectType
   put revDiscernObjectType(tFirstObject) into tFirstObjectType
   
   repeat for each line l in pObjects
      if revDiscernObjectType(l) is not tFirstObjectType then
         put false into tAllSame
         exit repeat
      end if
   end repeat
   
   return tAllSame & cr & tFirstObjectType
end revAllSameType2

function revDiscernObjectType pObject
   if (the cREVGeneral["viewerobject"] of pObject) \
         or (the cREVGeneral["viewercreator"] of pObject) then return "report"
   if word 1 of pObject is not "group" and the cRevGeneral["databasequeryobject"] of pObject 
   then return "databasequery"
   
   local tObject
   put word 1 of pObject into tObject
   switch tObject
      case "button"
         local tTheObject
         if the style of pObject is "menu" then
            if the menuMode of pObject is "tabbed" then 
               put "tab" into tTheObject
            else
               put "menu" into tTheObject
            end if
         else
            put "button" into tTheObject
         end if
         break
      case "graphic"
         switch the style of pObject
            case "rectangle"
            case "text" -- OK-2010-03-08: Bug 8651 - Returns "text" with showName & lineSize of 0
               put "rectangle" into tTheObject
               break
            case "roundrect"
               put "roundedrectangle" into tTheObject
               break
            case "curve"
               put "freehandcurve" into tTheObject
               break
            case "regular"
               put "regularpolygon" into tTheObject
               break
            default
               put the style of pObject into tTheObject
               break
         end switch
         break
      case "scrollbar"
         switch the style of pObject
            case "scale"
               put "slider" into tTheObject
               break
            case "progress"
               put "progressbar" into tTheObject
               break
            default
               if the height of pObject < 29 and the width of pObject < 17 
               then put "littlearrows" into tTheObject
               else put "scrollbar" into tTheObject
               break
         end switch
         break
      case "the"
         --templateObject selected
         put char 9 to -1 of word 2 of pObject into tTheObject
         replace "bkgnd" with "group" in tTheObject
         break
      case "bkgnd"
         --change wording from "bkgnd" to "group" for compatibility with tab name
         put "group" into tTheObject
         break
      case "group"
         if the dgProps["control type"] of pObject is "Data Grid" then
            put "DataGrid" into tTheObject
         else
            put "group" into tTheObject
         end if
         break
      default
         put word 1 of pObject into tTheObject
         break
   end switch
   return tTheObject
end revDiscernObjectType


----------------------------------------------

on revReloadBreakpoints
   exit revReloadBreakpoints
   
   local tStacksList
   put the mainStacks into tStacksList
   repeat for each line l in tStacksList
      if not (there is a stack l) then next repeat -- stack saved on another machine with file path wrong
      local tList
      put the cREVGeneral["debugObjects"] of stack l into tList
      if the number of lines in tList > 250 then
         answer error "It appears your breakPoint information has been corrupted.  Fixing this will remove all breakPoints from this stack.  If you don't fix this, LiveCode may not work correctly.  Please file a bug report as this problem should not occur." with "Don't fix" or "Fix"
         if it is "fix" then
            set the cREVGeneral["debugObjects"] of stack l to empty
            put empty into tList
         end if
      end if
      repeat for each line x in tList
         if not exists(x) then next repeat
         set the cREVGeneral["breakPoints"] of x to the cREVGeneral["breakPoints"] of x
      end repeat
   end repeat
end revReloadBreakpoints

on revClearAllBreakPoints
   # OK-2008-02-21 : Removed to prevent interference with new debugger
   exit revClearAllBreakpoints
   
   local tStacksList
   put the mainStacks into tStacksList
   put revFilterStacksList(tStacksList) into tStacksList
   
   local tList
   repeat for each line l in tStacksList
      put the cREVGeneral["debugObjects"] of stack l into tList
      repeat for each line x in tList
         set the cREVGeneral["breakPoints"] of x to empty
      end repeat
   end repeat
end revClearAllBreakPoints

function revAllSameType pObjects
   --first line true or false
   --second line the object type
   local tAllSame
   put true into tAllSame
   
   local tFirstObjectType
   put revDiscernObjectType(line 1 of pObjects) into tFirstObjectType
   repeat for each line l in pObjects
      if revDiscernObjectType(l) is not tFirstObjectType then
         put false into tAllSame
         exit repeat
      end if
   end repeat
   return tAllSame & cr & tFirstObjectType
end revAllSameType

function revObjectTabs pObjects
   --returns object tabs for given object
   --some objects have multiple object specific tabs
   --will correspond to text of btn "Tabs"
   local tAllSameInfo
   put revAllSameType(pObjects) into tAllSameInfo
   
   if (line 1 of tAllSameInfo) then
      local tTabs
      switch (line 2 of tAllSameInfo)
         case "button"
            put "Button"&cr&"Menu"&cr&"Report" into tTabs
            break
         case "field"
            put "Field"&cr&"Behavior"&cr&"Database"&cr&"Table" into tTabs
            break
         case "player"
            put "Player"&cr&"Interaction" into tTabs
            break
         case "stack"
            put "Stack"&cr&"General" into tTabs
            break
         default
            put line 2 of tAllSameInfo into tTabs
            put toUpper(char 1 of tTabs) into char 1 of tTabs
            break
      end switch
      return "Basic"&cr&tTabs&cr&"Custom"
   else
      --multiple different types of object
      return "Basic"&cr&"Custom"
   end if
end revObjectTabs

function revReturnSelectionDescription pObjects
   --first line of result is the label of the selection description btn
   --second line of result is the cREVLabelID of btn "Selection Description"
   
   if line 1 of revAllSameType(pObjects) then
      switch
         case word 1 of pObjects is "the" --template object selected
            local tSelectionDescription
            put line 1 of pObjects into line 1 of tSelectionDescription
            put line 1 of tSelectionDescription into line 2 of tSelectionDescription
            set the cREVLabelID of btn "Selection Description" of bg "revBackdrop" to tSelectionDescription
            break
         case the num of lines in pObjects > 1 
            # OK-2008-03-20 : This appears to have been ommited
            local tFirstObjectType
            put revDiscernObjectType(line 1 of pObjects) into tFirstObjectType
            
            put "multiple" && tFirstObjectType & "s" into line 1 of tSelectionDescription
            put line 1 of tSelectionDescription into line 2 of tSelectionDescription
            break
         default
            put the name of pObjects into line 1 of tSelectionDescription
            put pObjects into line 2 of tSelectionDescription
            break
      end switch
   else
      --multiple object types
      put "multiple object types" into line 1 of tSelectionDescription
      put line 1 of tSelectionDescription into line 2 of tSelectionDescription
   end if
   return tSelectionDescription
end revReturnSelectionDescription

------------------------------------------
# Script Editor functions
------------------------------------------

function revScriptEditor pObject
   if exists(pObject) then
      return _revScriptEditorNew(the long id of pObject)
   end if
   return empty
end revScriptEditor

# Parameters
#   pObject : reference to the object to edit the script of
# Returns
#   The long id of the script editor that is currently editing pObject
#   or empty if none is.
private function _revScriptEditorNew pObject
   local tEditors
   put revListScriptEditors() into tEditors
   
   local tFoundEditor
   repeat for each line tEditor in tEditors
      local tTargetObjects
      send "revSEGetTargetObjects" to tEditor
      put the result into tTargetObjects
      
      if revRuggedId(pObject) is among the lines of tTargetObjects then
         put the short name of tEditor into tFoundEditor
         exit repeat
      end if
   end repeat
   
   return tFoundEditor
end _revScriptEditorNew

on revUpdatePaletteStack
   global gREVStacksList
   
   local tSelObj
   put the selobj into tSelobj
   if word 1 of tSelobj is "stack" then
      if the mode of tSelobj is 1 then
         select empty
      end if
   end if
   if (the selobj) is empty and the short name of the topStack is not lLastTopStack then
      lock screen
      repeat for each line l in gREVStacksList
         if word 1 of l is "revPropertyPalette" then
            send "revUpdateTabs" to stack l
            send "revUpdatePalette" to this cd of stack l
         end if
      end repeat
      unlock screen
   end if
   put the short name of the topStack into lLastTopStack
end revUpdatePaletteStack

function revBrowserTopStack
   local tOpenStacks
   put the openStacks into tOpenStacks
   
   local tNotOpenOffset
   put the num of lines in tOpenStacks + 1 into tNotOpenOffset
   
   local tLoadedStacks
   put revLoadedStacks("preference") into tLoadedStacks
   set the wholeMatches to true
   
   local tStacksList
   put empty into tStacksList
   
   local tMode
   repeat for each line l in tLoadedStacks
      put the mode of stack l into tMode
      if tMode is 0 then put 13 into tMode
      
      local tLineOffset
      put lineOffset(l,tOpenStacks) into tLineOffset
      if tLineOffset is 0 then put tNotOpenOffset into tLineOffset
      put tLineOffset,tMode,l & cr after tStacksList
   end repeat
   sort lines of tStacksList numeric ascending by item 1 of each
   sort lines of tStacksList numeric ascending by item 2 of each
   return item 3 of line 1 of tStacksList
end revBrowserTopStack

------------------------------------
-- Script Editor hide/show palettes
------------------------------------
local sPalettesMsgID

constant kDontHide = "revMenuBar,revErrorDisplay,revVariableWatcher,revMessageWatcher,revDocsLanguageQuickref,com.livecode.palette.autocomplete.completions"

# OK-2008-05-12 : Added to fix problem with script editor dialogs not being recognized as part of the script editor
# and palettes consequently being reshown when they are invoked.
# Parameters
#   pStackname : the short name of a stack
# Returns
#   Whether or not the stack pStackname is part of the script editor.
private function revSEStackIsScriptEditor pStackname
   # The script editor mainstack is just a container for the script editor's components,
   # if this stack is open it means we're editing the script editor, so effectively the stack
   # is not part of the script editor.
   if pStackname is the short name of revScriptEditorMain() then
      return false
   end if
   
   # All substacks of the script editor are included at the moment. This includes dialogs and script editor instances
   if the owner of stack pStackname is not empty and the short name of the owner of stack pStackname is the short name of revScriptEditorMain() then
      return true
   end if
   
   return false
end revSEStackIsScriptEditor

on revSEHidePalettes
   cancel sPalettesMsgID
   send "revSEDelayTogglePalettes false" to me in 200 milliseconds
   put the result into sPalettesMsgID
end revSEHidePalettes

on revSEShowPalettes
   cancel sPalettesMsgID
   send "revSEDelayTogglePalettes true" to me in 200 milliseconds
   put the result into sPalettesMsgID
end revSEShowPalettes

on revSEDelayTogglePalettes pShow
   lock screen
   
   local tOldLock
   put the lockMessages into tOldLock
   lock messages
   
   if pShow then
      if the iconic of stack revIDEPaletteToStackName("menubar") then exit revSEDelayTogglePalettes
      
      local tObject
      put the focusedObject into tObject
      if tObject is not empty then
         local tStack
         put revTargetStack(tObject) into tStack
         if tStack is "Answer dialog" or "revVariableWatcher" is in tStack or \
               "revMessageWatcher" is in tStack or revSEStackIsScriptEditor(tStack) then
            exit revSEDelayTogglePalettes
         end if
      end if
      
      local tHiddenStack
      repeat for each key tHiddenStack in sHiddenPalettes
         # OK-2009-10-08 : Its possible that the stack could be been removed between showing and hiding the palettes,
         # this is due to extra mutable windows added with the new script editor. Check this first or it will keep throwing
         # errors.
         if there is no stack tHiddenStack then
            next repeat
         end if
         show stack tHiddenStack
         if the mode of stack tHiddenStack is 0 then--Unix Window Managers 
            if word 1 of tHiddenStack is "revPropertyPalette" then 
               send "revUpdateTabs" to stack tHiddenStack
            end if
         end if
      end repeat
      
      delete variable sHiddenPalettes
   else
      if the mode of stack "revErrorDisplay" is not 0 and revIDEGetPreference("cSEHideErrors") then
         hide stack "revErrorDisplay"
         put empty into sHiddenPalettes["revErrorDisplay"]
      end if
      
      if the cSEHidePalettes of stack "revPreferences" then
         local tOpenStacks
         put the openStacks into tOpenStacks
         repeat for each line tStackName in tOpenStacks
            if not revIDEStackNameIsIDEStack(tStackName) then
               next repeat
            end if
            
            if not the visible of stack tStackName then
               next repeat
            end if
            
            if (tStackName is not among the items of kDontHide) and the mode of stack tStackName is 4 then
               # OK-2008-06-24 : Bug 6621 : Prevent palettes being hidden if they are owned by the script editor
               if the mainstack of stack tStackName is the short name of revScriptEditorMain() then
                  next repeat
               end if
               
               # OK-2009-12-22: Bug 8497 : Also keep separate variable viewer panes open
               if tStackName begins with "revVariableVisualizer" then
                  next repeat
               end if
               
               hide stack tStackName
               put empty into sHiddenPalettes[tStackName]
            end if
         end repeat
      end if
      -- must be after the others
      if the mode of stack "Message Box" is not 0 and revIDEGetPreference("cSEHideMessageBox") then
         hide stack "Message Box"
         put empty into sHiddenPalettes["Message Box"]
      end if
   end if
   
   set the lockMessages to tOldLock
   unlock screen
end revSEDelayTogglePalettes

# OK-2007-11-29 : Bug 5562
# Parameters
#   pStack : refererence to stack to import image into.
# Description
#   Prompts the user to select images, if some images are selected then
#   imports these into pStack. If pStack is not given then imports into the defaultStack
on revImportImageFile pStack
   local tDefaultStack
   put the defaultStack into tDefaultStack
   
   local tStack
   if pStack is empty then
      put the long id of the defaultStack into tStack
   else
      put pStack into tStack
   end if
   
   try
      local tFilePaths
      put revAnswerFiles("image", "Select an image file to import:") into tFilePaths
      if tFilePaths is empty then
         exit revImportImageFile
      end if
      
      repeat for each line tFilePath in tFilePaths
         local tConvertPICT
         put false into tConvertPICT 
         
         if the platform is "MacOS" then
            if revIsPICT(tFilePath) then
               put true into tConvertPICT
               if not (the cNOPICTWarning of stack "revPreferences") then
                  answer warning "This file is in Macintosh PICT format, which can only be displayed on Mac OS systems.  " & \
                  "LiveCode can convert the imported image to PNG format, which can be displayed cross platform. " & \
                  "Would you like LiveCode to convert the imported image to PNG format?" \
                        with "Don't Show Again" or "Cancel" or "Don't Convert" or "Convert to PNG Format"
                  
                  if it is "Cancel" then
                     exit revImportImageFile
                  end if
                  if it is "Don't Show Again" then
                     set the cNOPICTWarning of stack "revPreferences" to true
                  end if
                  if it is "Don't Convert" then
                     put false into tConvertPICT
                  end if
               end if
            end if
            if tFilePath is not empty then
               lock screen
               
               # OK-2007-11-23 : Bug 5562
               set the defaultStack to the short name of tStack
               
               import paint from file tFilePath
               if tConvertPICT then
                  import snapshot from last image
                  set the name of last image to the short name of image (the number of images -1)
                  delete image (the number of images -1)
               end if
               set the loc of last image to the loc of this card
               
               set the defaultStack to tDefaultStack
               
               unlock screen
            end if
         else
            # Windows and Unix
            if revIsPICT(tFilePath) then
               put true into tConvertPICT
               if not (the cNOPICTWarning of stack "revPreferences") then
                  answer warning "This file is in Macintosh PICT format.  This format can only be displayed on Mac OS systems." with "Don't Show Again" or "Cancel" or "Continue"
                  if it is "Cancel" then
                     exit revImportImageFile
                  end if
                  if it is "Don't Show Again" then
                     set the cNOPICTWarning of stack "revPreferences" to true
                  end if
                  if it is "No" then
                     put false into tConvertPICT
                  end if
               end if
            end if
            if tFilePath is not empty then
               # OK-2007-11-23 : Bug 5562
               set the defaultStack to the short name of tStack
               
               import paint from file tFilePath
               set the loc of last image to the loc of this card
               
               set the defaultStack to tDefaultStack
            end if
         end if
      end repeat
   catch someError
      answer "An error occurred when trying to import the image file:" & cr & tFilePath & cr & someError
   end try
end revImportImageFile

on revUpdateAOControls pTarget
   global gREVStackName
   
   local tTargetStack
   put revTargetStack(pTarget) into tTargetStack
   
   local tHCAddressing
   put the hcAddressing of stack tTargetStack into tHCAddressing
   set the hcAddressing of stack tTargetStack to false
   if pTarget is empty then put the long id of the target into pTarget
   else put the long id of pTarget into pTarget -- id with HCAddressing false
   if there is a stack "revApplicationOverview" then
      send "revClearControlCache pTarget" to stack "revApplicationOverview"
      if the mode of stack "revApplicationOverview" is not 0 \
            and revTargetStack(pTarget) is gREVStackName \
            and the short name of this cd of stack "revApplicationOverview" is "Cards and Controls" then
         
         if lUpdateAOControlsTimerID is not empty then cancel lUpdateAOControlsTimerID
         send "revRefreshControls true, false" to cd "Cards and Controls" of stack "revApplicationOverview" in 1 second
         put the result into lUpdateAOControlsTimerID
      end if
   end if
   set the hcAddressing of stack tTargetStack to tHCAddressing
end revUpdateAOControls

function revExternalVersion pExternal
   local tExternalVersion
   put empty into tExternalVersion
   
   local tExternalList
   put empty into tExternalList
   -- Win,OSX and Unix
   local tCheckExternals
   put the externals of stack "home" into tCheckExternals
   
   local tExternals
   repeat for each line i in tCheckExternals
      repeat for each item j in "revdb,revxml,revvideograbber,revspeech"
         if i contains j then
            put j & "," after tExternals
         end if
      end repeat
   end repeat
   if the last char of tExternals is comma then delete the last char of tExternals
   repeat for each item k in tExternals
      switch k
         case "revxml"
            local tXML
            put "2.1RC1-1" into tXML
            put k & ":" && tXML & cr after tExternalVersion
            break
         case "revdb"
            local tDB
            put "2.1RC1-1" into tDB
            put k & ":" && tDB & cr after tExternalVersion
            break
         case "revvideograbber"
            local tVideoGrabber
            put "2.1RC1-1" into tVideoGrabber
            put k & ":" && tVideoGrabber & cr after tExternalVersion
            break
         case "revspeech"
            local tSpeech
            put "2.1RC1-1" into tSpeech
            put k & ":" && tSpeech & cr after tExternalVersion
            break
      end switch
      put k & "," after tExternalList
   end repeat
   if the last char of tExternalList is comma then delete the last char of tExternalList
   if pExternal is not "all" then
      if pExternal is among the items of tExternalList then
         local tNumber
         put itemoffset(pExternal,tExternalList) into tNumber
         
         local tLineVersion
         put line tNumber of tExternalVersion into tLineVersion
         set the itemDelimiter to ":"
         
         local tVersion
         put char 2 to -1 of item 2 of tLineVersion into tVersion
         return tVersion
      end if
   else
      return tExternalVersion
   end if
end revExternalVersion

on revUpdateAB
   if there is a stack "revApplicationOverview" then
      if the mode of stack "revApplicationOverview" is not 0 then
         lock screen
         send "revRetainStacks" to stack "revApplicationOverview"
         send "revInitAppBrowser" to stack "revApplicationOverview"
         unlock screen
      end if
   end if
end revUpdateAB

constant kDriverListFile = "Database Drivers.txt"

-- MW-2013-06-13: [[ CloneAndRun ]] Construct the list of dbdrivers manually
function revDatabaseDriverBuildList
   if revEnvironmentIsInstalled() then
      pass revDatabaseDriverBuildList
   end if
   
   local tList
   put empty into tList
   // AL-2015-02-17: [[ SB Inclusions ]] Ensure mysql module name is standard (was dbmysql)
   repeat for each item tExternal in revIDEDatabaseDriversMapping()
      get lineOffset(word 1 of tExternal, the externals of stack "Home")
      if it is not 0 then
         set the itemDelimiter to slash
         put word 2 to -1 of tExternal, the last item of line it of the externals of stack "Home" & return after tList
         set the itemDelimiter to comma
      end if
   end repeat
   delete the last char of tList
   return tList
end revDatabaseDriverBuildList

function revDatabaseDriverList
   local tEnvironmentList
   local tDrivers
   
   -- MW-2013-06-13: [[ CloneAndRun ]] Special-case when not an installation.
   if revEnvironmentIsInstalled() then
      # OK-2007-09-24 : Legacy driver support. Unfortunately the legacy driver support also includes a legacy revDB external,
      # which does not support the revGetDatabaseDriverPath function. So if legacy drivers are to be used, we need to revert to the old
      # way of listing the drivers. Because the setting does not take place until LiveCode is restarted, we can't just check it 
      # directly, so instead we simply attempt to call the function revGetDatabaseDriverPath and assume if its not there that legacy drivers
      # are in use.
      local tDriverPaths
      try
         put revGetDatabaseDriverPath() into tDriverPaths
      catch tError
         put revEnvironmentExternalsPath() & "/Legacy/Database Drivers" into tDriverPaths
         put return & revEnvironmentUserExternalsPath() & "/Legacy/Database Drivers" after tDriverPaths
      end try
      
      local tEnvironmentFile
      put line 1 of tDriverPaths & slash & kDriverListFile into tEnvironmentFile
      
      local tUserFile
      put line 2 of tDriverPaths & slash & kDriverListFile into tUserFile
      
      # OK-2007-09-24 : Legacy driver support. If legacy drivers are in use, we ignore the environment list
      # as things might get confused if we use a mixture of new and legacy drivers.
      if the cREVUseLegacyDrivers of stack "revPreferences" then
         put empty into tEnvironmentList
      else
         put url ("file:" & tEnvironmentFile) into tEnvironmentList
      end if
      
      local tUserList
      put url ("file:" & tUserFile) into tUserList
      
      # OK-2007-09-14 : Bug 5394 : On linux the engine does not convert the line endings
      # correctly resulting in only the first line of the drivers list being returned. We 
      # work around this for now until the bug is fixed in the engine.
      if the platform is "Linux" then
         # Windows line endings
         replace (numToChar(10) & numToChar(13)) with numToChar(10) in tUserList
         replace (numToChar(10) & numToChar(13)) with numToChar(10) in tEnvironmentList
         
         # Mac line endings
         replace numToChar(13) with numToChar(10) in tUserList
         replace numToChar(13) with numToChar(10) in tEnvironmentList
      end if
      
      repeat for each line tDriver in tUserList
         put item 1 of tDriver & return after tDrivers
      end repeat
   else
      put revDatabaseDriverBuildList() into tEnvironmentList
   end if
   
   repeat for each line tDriver in tEnvironmentList
      if item 1 of tDriver is not among the lines of tDrivers then
         put item 1 of tDriver & return after tDrivers
      end if
   end repeat
   delete the last char of tDrivers
   
   return tDrivers
end revDatabaseDriverList

-- MW-2013-06-13: [[ CloneAndRun ]] If we aren't installed, then generate the externals
--   list by hand.
private function revExternalsBuildList 
   local tList
   put empty into tList
   repeat for each item tExternal in revIDEExternalsMapping()
      get lineOffset(word 1 of tExternal, the externals of stack "Home")
      if it is not 0 then
         set the itemDelimiter to slash
         put word 2 to -1 of tExternal, the last item of line it of the externals of stack "Home" & return after tList
         set the itemDelimiter to comma
      end if
   end repeat
   delete the last char of tList
   return tList
end revExternalsBuildList

function revExternalsList
   local tPath,tSave,tDrivers
   
   -- MW-2013-06-13: [[ CloneAndRun ]] Special-case when not an installation.
   local tEnvironmentFile
   if revEnvironmentIsInstalled() then
      
      put revEnvironmentExternalsPath() & "/Externals.txt" into tEnvironmentFile
      
      local tUserFile
      put revEnvironmentUserExternalsPath() & "/Externals.txt" into tUserFile
      
      local tUserDrivers
      put url ("file:"&tUserFile) into tUserDrivers
      
      local tEnvironmentDrivers
      put url ("file:"&tEnvironmentFile) into tEnvironmentDrivers
      
      repeat for each line l in tUserDrivers
         put item 1 of l & cr after tDrivers
      end repeat
   else
      put revExternalsBuildList() into tEnvironmentDrivers
   end if
   
   repeat for each line l in tEnvironmentDrivers
      if item 1 of l is not among the lines of tDrivers then put item 1 of l & cr after tDrivers
   end repeat
   delete last char of tDrivers
   return tDrivers
end revExternalsList

constant kDriverIndexName = "Database Drivers.txt"
constant kDriverIndexSubFolder = "Database Drivers"

function revDBDriverPath pDriver, pPlatform, pArchitecture
   -- MW-2013-06-13: [[ CloneAndRun ]] If we are not installed, special-case the request.
   if not revEnvironmentIsInstalled() then
      if pPlatform contains "MacOSX" and the platform is not "macos" or \
            pPlatform is "Linux" and the platform is not "linux" or \
            pPlatform is "Windows" and the platform is not "win32" then
         return empty
      end if
      
      repeat for each line tLine in revDatabaseDriverBuildList()
         if item 1 of tLine is pDriver then
            return revEnvironmentBinariesPath() & slash & item 2 of tLine
         end if
      end repeat
      
      return empty
   end if
   
   -- returns path to database driver from runtime or user runtime folder
   -- will be a folder on Mac OS X, a list of files on Windows
   
   local tPlatform, tEnvironmentFolder, tUserFolder
   put pPlatform into tPlatform
   if tPlatform is "MacOSX" then
      put "Mac OS X" into tPlatform
      if pArchitecture is empty then
         put "Universal" into pArchitecture
      end if
   end if
   
   put revEnvironmentRuntimePath() & "/" & tPlatform & "/" & pArchitecture & "/Externals" into tEnvironmentFolder
   put revEnvironmentUserRuntimePath() & "/" & tPlatform & "/" & pArchitecture & "/Externals" into tUserFolder
   
   local tEnvironmentFile, tUserFile, tLegacyFile
   put tEnvironmentFolder & slash & kDriverIndexSubFolder & slash & kDriverIndexName into tEnvironmentFile
   put tUserFolder & slash & kDriverIndexSubFolder & slash & kDriverIndexName into tUserFile
   put tUserFolder & "/Legacy/" & kDriverIndexSubFolder & slash & kDriverIndexName into tLegacyFile
   
   local tUserDrivers
   put url ("file:"&tUserFile) into tUserDrivers
   
   local tEnvironmentDrivers
   put url ("file:" & tEnvironmentFile) into tEnvironmentDrivers
   
   # OK-2009-02-03 : Bug 7433 - If using legacy drivers, this is where the index will be. Otherwise the variable
   # will simply be empty and we fall back to using the normal driver.
   local tLegacyDrivers
   if the cREVUseLegacyDrivers of stack "revPreferences" and pPlatform is not "Linux" then 
      put url ("file:" & tLegacyFile) into tLegacyDrivers
   end if
   
   # Attempt to locate a legacy driver if we are meant to use them, otherwise just search for the drivers as normal
   local tLineNo, tBasePath
   if the cREVUseLegacyDrivers of stack "revPreferences" and pPlatform is not "Linux" then
      put lineOffset(pDriver & comma, tLegacyDrivers) into tLineNo
      if tLineNo <> 0 then
         put line tLineNo of tLegacyDrivers into tLine
         put tLegacyFile into tBasePath
      end if
   end if
   
   if tLineNo is empty or tLineNo = 0 then
      put lineOffset(pDriver & comma,tUserDrivers) into tLineNo
      
      if tLineNo is not 0 then 
         put line tLineNo of tUserDrivers into tLine
         put tUserFile into tBasePath
      else
         put lineOffset(pDriver & comma,tEnvironmentDrivers) into tLineNo
         if tLineNo is not 0 then 
            put line tLineNo of tEnvironmentDrivers into tLine
            put tEnvironmentFile into tBasePath
         end if
      end if
   end if
   
   set the itemDel to slash
   delete item -1 of tBasePath
   set the itemDel to comma
   
   local tReturn
   repeat with i = 2 to the number of items in tLine
      put tBasePath & slash & item i of tLine & cr after tReturn
   end repeat
   delete last char of tReturn
   return tReturn
end revDBDriverPath

function revExternalPath pDriver, pPlatform, pArchitecture
   -- returns path to external from runtime or user runtime folder
   -- will be a folder on Mac OS X, a list of files on Windows
   
   -- MW-2013-06-13: [[ CloneAndRun ]] If we aren't an installed environment then compute
   --    relative to the build folder.
   if not revEnvironmentIsInstalled() then
      if pPlatform contains "MacOSX" and the platform is not "macos" or \
            pPlatform is "Linux" and the platform is not "linux" or \
            pPlatform is "Windows" and the platform is not "win32" then
         return empty
      end if
      
      repeat for each line tLine in revExternalsBuildList()
         if item 1 of tLine is pDriver then
            return revEnvironmentBinariesPath() & slash & item 2 of tLine
         end if
      end repeat
      
      return empty
   end if
   
   # OK-2009-01-31 : Bug 7433 - Added support for legacy externals.
   local tEnvironmentfile, tUserFile, tLegacyFile
   switch pPlatform
      case "MacOSX"
         if pArchitecture is empty then
            put "Universal" into pArchitecture
         end if
         put revEnvironmentRuntimePath() & "/Mac OS X/" & pArchitecture & "/Externals/Externals.txt" into tEnvironmentFile
         put revEnvironmentUserRuntimePath() & "/Mac OS X/" & pArchitecture & "/Externals/Externals.txt" into tUserFile
         put revEnvironmentUserRuntimePath() & "/Mac OS X/" & pArchitecture & "/Externals/Legacy/Externals.txt" into tLegacyFile
         break
      case "Windows"
         put revEnvironmentRuntimePath() & "/Windows/" & pArchitecture & "/Externals/Externals.txt" into tEnvironmentFile
         put revEnvironmentUserRuntimePath() & "/Windows/" & pArchitecture & "/Externals/Externals.txt" into tUserFile
         put revEnvironmentUserRuntimePath() & "/Windows/" & pArchitecture & "/Externals/Legacy/Externals.txt" into tLegacyFile
         break
         # OK-2007-08-14 : Linux support reinstated
      case "Linux"
         put revEnvironmentRuntimePath() & "/Linux/" & pArchitecture & "/Externals/Externals.txt" into tEnvironmentFile
         put revEnvironmentUserRuntimePath() & "/Linux/" & pArchitecture & "/Externals/Externals.txt" into tUserFile
         put revEnvironmentUserRuntimePath() & "/Linux/" & pArchitecture & "/Externals/Legacy/Externals.txt" into tLegacyFile
         break
   end switch
   
   local tUserDrivers
   put url ("file:" & tUserFile) into tUserDrivers
   
   local tEnvironmentDrivers
   put url ("file:" & tEnvironmentFile) into tEnvironmentDrivers
   
   # OK-2009-01-31 : Bug 7433
   local tLegacyDrivers
   if the cREVUseLegacyDrivers of stack "revPreferences" then
      put url ("file:" & tLegacyFile) into tLegacyDrivers
   end if
   
   # OK-2009-01-31 : Bug 7433 - If we're set to use legacy drivers, check them first,
   # if no legacy driver was found for the required libray, then we just default to the normal one.
   local tLineNo, tBasePath
   if the cREVUseLegacyDrivers of stack "revPreferences" then
      
      put lineOffset(pDriver & comma, tLegacyDrivers) into tLineNo
      if tLineNo <> 0 then
         put line tLineNo of tLegacyDrivers into tLine
         put tLegacyFile into tBasePath
      end if
   end if
   
   if tLineNo is empty or tLineNo is 0 then
      put lineOffset(pDriver & comma, tUserDrivers) into tLineNo
      
      if tLineNo is not 0 then 
         put line tLineNo of tUserDrivers into tLine
         put tUserFile into tBasePath
      else
         put lineOffset(pDriver & comma, tEnvironmentDrivers) into tLineNo
         if tLineNo is not 0 then 
            put line tLineNo of tEnvironmentDrivers into tLine
            put tEnvironmentFile into tBasePath
         end if
      end if
   end if
   
   set the itemDelimiter to slash
   delete item -1 of tBasePath
   set the itemDelimiter to comma
   
   local tReturn
   repeat with i = 2 to the number of items in tLine
      put tBasePath & slash & item i of tLine & return after tReturn
   end repeat
   delete last char of tReturn
   return tReturn
end revExternalPath




--

private function revDirectoryWalking pFolder
   if there is not a folder pFolder then
      if there is a file pFolder then
         return pFolder
      else
         return empty
      end if
   else
      set the defaultFolder to pFolder
      local tList
      put the detailed files into tList
      local tFilesList
      repeat for each line i in tList
         put pFolder & "/" & i & cr after tFilesList
      end repeat
      
      local tDirList
      put the folders into tDirList
      repeat with i = 2 to the number of lines of tDirList
         put revDirectoryWalking (pFolder & "/" & (line i of tDirList)) after tFilesList
      end repeat
      return tFilesList
   end if
end revDirectoryWalking

function revDirWalker pFolder
   revIDEPushDefaultFolder
   
   local tList
   put revDirectoryWalking(pFolder) into tList
   revIDEPopDefaultFolder
   return tList
end revDirWalker

on revCompress pFolder, pSavePath, pName
   local tFileType
   put the fileType into tFileType
   if the paramcount is 0 then
      return "No parameters entered"
      exit revCompress
   end if
   set the itemDelimiter to "/"
   
   local tFolderName
   put item -1 of pFolder into tFolderName
   
   local tDetailedFileList
   put revdirWalker(pFolder) into tDetailedFileList
   if tDetailedFileList is empty then exit revCompress
   set the itemDelimiter to comma
   repeat for each line i in tDetailedFileList
      local tFileList
      put URLDecode( item 1 of i) & cr after tFileList
   end repeat
   set the itemDelimiter to "/"
   
   local tOffset, tList
   repeat for each line i in tFileList
      put itemOffset(tFolderName,i) into tOffset
      put item tOffset to -1 of i & cr after tList
   end repeat
   
   local tStackName
   if (the paramcount is 1) or (the paramcount is 2) then
      put tFolderName & ".dir" into tStackName
   else
      put pName & ".dir" into tStackName
   end if
   
   create stack tStackName
   set the cSourcePlatform of stack tStackName to the platform
   set the cSourceFolderName of stack tStackName to tFolderName
   set the cSourceFilesList of stack tStackName to tFileList
   set the cFilesList of stack tStackName to tList
   repeat with i = 1 to the number of lines in tFileList
      set the cBinFile[line i of tList] of stack tStackName to URL ("binfile:" & line i of tFileList)
      set the cResFile[line i of tList] of stack tStackName to URL ("resfile:" & line i of tFileList)
      if the platform is "MacOS" then
         set the itemDelimiter to comma
         local tType
         put item 11 of line i of tDetailedFileList into tType
         if tType is empty then
            set the cFileType[line i of tList] of stack tStackName to "        "
         else
            set the cFileType[line i of tList] of stack tStackName to tType
         end if
         set the itemDelimiter to "/"
      end if
   end repeat
   
   local tSavePath
   if the paramcount is 1 then
      put the defaultFolder & "/" & tStackName into tSavePath
   else
      if the last char of pSavePath is "/" then delete the last char of pSavePath
      put pSavePath & "/" & tStackName into tSavePath
   end if
   save stack tStackName as tSavePath
   put compress(URL ("binfile:" & tSavePath)) into URL ("binfile:" & tSavePath & ".gz") 
   delete file tSavePath
   close stack tStackName
   delete stack tStackName
   set the fileType to tFileType
   return empty
end revCompress

on revDecompress pFile, pFolder
   local tFileType
   put the fileType into tFileType
   
   local tFile
   put pFile into tFile
   if char -7 to -1 of tFile is ".dir.gz" then
      delete char -3 to -1 of tFile
   else
      exit revDecompress
   end if
   try
      put decompress(URL ("binfile:" & pFile)) into URL ("binfile:" & tFile)
      if the result is not empty then throw the result
   catch tError
      return "Invalid file type"
      exit revDecompress
   end try
   if the last char of pFolder is "/" then delete the last char of pFolder
   
   open stack tFile
   
   local tName, tFilesList, tFolderName
   put the short name of this stack into tName
   put the cFilesList of stack tName into tFilesList
   put the cSourceFolderName of stack tName into tFolderName
   
   local tPlatform
   put the cSourcePlatform of stack tName into tPlatform
   if the paramcount is 1 then
      put the defaultFolder into pFolder
   end if
   
   local tDirPath, tFolderPath, tOffset, tItems, tCreateFolder
   repeat for each line i in tFilesList
      put i into tDirPath
      set the itemDelimiter to "/"
      delete the last item of tDirPath
      put pFolder & "/" & tDirPath into tFolderPath
      put itemOffset(tFolderName,tFolderPath) into tOffset
      put the number of items in tFolderPath into tItems
      repeat with j = tOffset to tItems
         put item 1 to j of tFolderPath into tCreateFolder
         if there is not a folder tCreateFolder then create folder tCreateFolder
      end repeat
      if tPlatform is "MacOS" then
         set the fileType to the cFileType[i] of stack tName
      end if
      put the cBinFile[i] of stack tName into URL ("binfile:" & pFolder & "/" & i)
      put the cResFile[i] of stack tName into URL ("resfile:" & pFolder & "/" & i)
   end repeat
   delete file tFile
   close stack tName
   delete stack tName
   set the fileType to tFileType
   return empty
end revDecompress

on revSaveLayout -- save current object layer and rect for undo
   global gREVUndoList
   put empty into gREVUndoList
   
   local tSavedList
   put the selectedObjects into tSavedList
   repeat for each line l in tSavedList
      put l,the rect of l & cr after gREVUndoList
   end repeat
   put "rect" after gREVUndoList
end revSaveLayout

##### mf 03/08/2005 Functions to check whether a stack can be removed from memory 
##### without causing problems (Bug 2475).
function revBeforeRemovingStackFromMemory pStack
   local tStack, tStacksList, tInstructions, tCheckScriptEditors
   
   put the mainStack of stack pStack into tStack
   if the substacks of stack tStack is empty
   then put tStack into tStacksList
   else put tStack & cr & the substacks of stack tStack into tStacksList
   put revCheckLockedInspectors(tStacksList) into tInstructions
   put revCheckScriptEditors(tStacksList) into tCheckScriptEditors
   if tCheckScriptEditors is not empty then put cr & tCheckScriptEditors after tInstructions
   
   if the mode of stack "revMenuManager" is not 0 and \
         the cREVDefaultStack of stack "revMenuManager" is among the lines of tStacksList
   then put cr & "Close the Menu Builder." after tInstructions
   
   if the mode of stack "revSearch" is not 0
   then put cr & "Close the Find and Replace dialog." after tInstructions
   
   # AL-2015-05-21: [[ Bug 14873 ]] revDBQuerySetup stack is no longer supported
   if there is a stack "revDBQuerySetup" and \
         the mode of stack "revDBQuerySetup" is not 0 and \
         the short name of the topStack is among the lines of tStacksList
   then put cr & "Close the Database Query Builder." after tInstructions
   
   if the mode of stack "revStandaloneSettings" is not 0 and \
         the cREVTargetStack of stack "revStandaloneSettings" is among the lines of tStacksList
   then put cr & "Close the Standalone Application Settings dialog." after tInstructions
   
   if (the cREVLockedtoStack of stack "Message Box") and \
         the cREVLinkedStack of stack "Message Box" is among the lines of tStacksList
   then put cr & "Unlock the Message Box." after tInstructions
   
   if char 1 of tInstructions is cr then delete char 1 of tInstructions
   return tInstructions
end revBeforeRemovingStackFromMemory

function revCheckLockedInspectors pStacksList
  local tOpenStacks, l, m
  put the openStacks into tOpenStacks
  repeat for each line l in tOpenStacks
    if word 1 of l is "revPropertyPalette" then
      repeat for each line m in the cREVLinked of stack l
        if revTargetStack(m) is among the lines of pStacksList
        then return "Close any Object Inspectors locked to objects in this stack or its substacks."
      end repeat
    end if
  end repeat
  return empty
end revCheckLockedInspectors

function revCheckScriptEditors pStacksList
  local tOpenStacks, l, tStack
  put the openStacks into tOpenStacks
  repeat for each line l in tOpenStacks
    if word 1 of l is "revScriptEditor" then
      put revTargetStack(the cTargetObject of this cd of stack l) into tStack
      if tStack is among the lines of pStacksList
      then return "Close any open Script Editors for any objects in this stack or its substacks."
    end if
  end repeat
  return empty      
end revCheckScriptEditors
#####mf 03/08/2005 End of functions to check whether a stack can be removed from memory 
##### without causing problems (Bug 2475)


-- prevent plug-in errors if messages not handled

on revCloseStack
  
end revCloseStack

on revEditScript
  
end revEditScript

on revIDChanged
  
end revIDChanged

on revMouseMove
  
end revMouseMove

on revMoveControl
  
end revMoveControl

on revNameChanged
  
end revNameChanged

on revNewTool
  
end revNewTool

on revPreOpenCard
  
end revPreOpenCard

on revPreOpenStack
  
end revPreOpenStack

on revResizeStack
  
end revResizeStack

on revResumeStack
  
end revResumeStack

on revSaveStackRequest
  
end revSaveStackRequest

on revSelectedObjectChanged
  
end revSelectedObjectChanged

on revSelectionChanged
  
end revSelectionChanged

on revShutDown
  
end revShutDown

function revCalculateRelativePath pRoot, pFile
  local tResult, tCount
  set the itemDel to "/"
  put 1 into tCount
  local tIsFolder
  put there is a folder pFile into tIsFolder
  repeat for each item tNode in pRoot
    if item 1 to tCount of pRoot is item 1 to tCount of pFile then
    else
      put "../" before tResult
      if item tCount of pFile is not empty then
        put item tCount of pFile & "/" after tResult
      end if
    end if
    add 1 to tCount
  end repeat
  put "./" before tResult
  put item tCount to -1 of pFile after tResult
  
  if char -1 of tResult is "/" then
    delete char -1 of tResult
  end if
  
  return tResult
end revCalculateRelativePath

# OK-2008-03-31 : Bug 6280
local sBlockMouseUp
local sPopupMenuUp

command revClearMouseUpBlock
  put false into sBlockMouseUp
end revClearMouseUpBlock

# OK-2008-03-27 : Bug where right-click context menus won't work with messages suppressed
# Added ability to explicity specify a target.

# Parameters
#   pWhich : the button number pressed (1, 2 or 3)
#   pTarget : reference to the object that was clicked on
# Returns
#   Either empty if the caller should decide whether to pass the message, or one of the following:
#   "exit", "exit to top", "pass".
command revIDEHandleMouseUp pWhich, pTarget
  global gREVPassMouseUp, gREVPopups
  
  local tTarget
  put the long id of pTarget into tTarget
  
  if sBlockMouseUp then 
    put false into sBlockMouseUp
    return "exit to top"
  end if
  
  if gREVPassMouseUp then
    put false into gREVPassMouseUp
    return "pass"
  end if
  
  if sPopupMenuUp then
    put false into sPopupMenuUp
    return "exit"
  end if
  
  if the cREVGetsUpdate of stack revTargetStack(tTarget) is not empty and the backPattern of tTarget is 200921 then
    set the backPattern of tTarget to empty
  end if
   

 // SN-2014-09-18: [[ Bug 13475 ]] Follow the same rule as revIDEHandleMouseDown, to avoid duplicates
  if pWhich is an integer and revCheckEdit(tTarget) then
    return "exit"
  end if
end revIDEHandleMouseUp

# TH-2008-06-18 : Bug 6217, this code has been copied from revFrontscript which now simply calls this 
# handler.  This prevents the accidental closing of unsaved new stacks when messages are suppressed
# Parameters
#   pTarget : reference to the current card of the stack that is being closed
# Returns
#   Either empty if the caller should decide whether to pass the message, or one of the following:
#   "exit", "exit to top", "pass".
command revIDEHandleCloseStackRequest   pTarget
   local tFocusedObject
   put the focusedObject into tFocusedObject
   if word 1 of tFocusedObject is "field" and word 1 of revTargetStack(tFocusedObject) is "revPropertyPalette" then
      send "closeField" to tFocusedObject
   end if
   
   # OK-2008-02-27 : Bug 5915
   if revSaveCheck(revTargetStack(pTarget)) then
      if gREVSuppressMessages and not (gREVSuppressMessages and revOKTarget()) then
         lock messages
         close stack revTargetStack(pTarget)
         unlock messages
      else
         return "pass"
      end if
   end if
   
   return empty
end revIDEHandleCloseStackRequest


# OK-2008-03-27 : Bug where right-click context menus wouldn't work with messages suppressed.
# Refactored to allow a target to be passed.

# Parameters
#   pWhich : the mouse button number clicked (1, 2 or 3) (Or empty if the mouseDown is the result of a keyboard shortcut)
#   pTarget : reference to the target object of the mouse click.
# Returns
#   Empty if the caller should decide whether to pass the mouseDown message. "exit" if the caller
#   should exit the mouseDown. "Exit to top" if the caller should exit to top.
command revIDEHandleMouseDown pWhich, pTarget
   local tTarget
   put the long id of pTarget into tTarget
   
   global gREVPopups, gREVScriptShortcut, gREVUIScriptShortcut, gREVPaintImage
   if the commandKey is down and the shiftKey is down and pWhich is 3 and (not revOKTarget(tTarget) or (revOKTarget(tTarget) and gREVPopups)) then
      put true into sPopupMenuUp
      revIDEPopupContextualMenu tTarget
      return "exit"
   end if
   
   # OK-2008-03-20: Bug 6153. If the mouseDown was sent because of menu accelerators instead
   # of an actual mouseDown, the button number will be empty, so check this before editing script.
   if the commandKey is down and the optionKey is down and gREVScriptShortcut is true and pWhich is not empty then
      if not revOKTarget(tTarget) or gREVUIScriptShortcut then
         put true into sBlockMouseUp
         send "revClearMouseUpBlock" to me in 1 second
         edit script of tTarget
      end if
      # OK-2008-07-30 - Don't exit to top here because doing so prevents the script editor initializing itself.
      --return "exit to top"
      return "exit"
   end if
   
   # MW-2008-03-20: [[ Bug 6160 ]] If the mouseDown is synthetic (from a non-engine source) then
   # we should pass the message, since there's no nice way to tell where a message was sent from
   # at the moment, we assume that non-engine sources don't pass an integer parameter
   if pWhich is a integer and revCheckEdit(tTarget) then
      if pWhich is 3 then
         if the shiftKey is down then
            set the selected of tTarget to true
         else
            select tTarget
         end if
         if not revOKTarget(tTarget) or (revOKTarget(tTarget) and gREVPopups) then 
            revIDEPopupContextualMenu the selectedObjects
         end if
         send "selectedObjectChanged" to me
      end if
      revIDESetEdited the short name of revIDEStackOfObject(tTarget)
      
      return "exit to top"
   end if
end revIDEHandleMouseDown

# OK-2008-03-27 : Bug 6229. When a stack is opened with messages suppressed, this message
# is sent by revNoMessages to this script to update the IDE. The reason for this is that we 
# need to know the name of the newly opened stack, which is originally in the target, but is
# lost when the message is sent.

# Parameters
#   pTarget : the target of the message, i.e. current card of the stack that was opened
# Description
#   Updates the IDE in response to a stack being opened.
command revIDEHandleNewStack pTarget
   global gREVStacksList, gREVTargetStack, gREVTempDont, gREVMessageDispatch, gREVScriptEdit, gREVShowStacks
   
   local tParse
   put the long id of pTarget into tParse
   
   local tStackName
   get wordOffset("stack", tParse)
   put word (it) to (it + 1) of tParse into tStackName
   
   revCheckStackCollision tStackName
   
   put true into gREVScriptEdit
   
   put the name of tStackName into gREVTargetStack
   put empty into gREVStacksList
   
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
   
   revUpdateRecentFiles the short name of gREVTargetStack
   
   revSetActiveStacks
   
   local tStack
   if there is a stack "revApplicationOverview" then
      if the mode of stack "revApplicationOverview" is not 0 then
         put revTargetStack(the long id of stack tStackName) into tStack
         send "revNewStack tStack" to stack "revApplicationOverview"
      end if
   end if
   
   repeat for each line l in gREVMessageDispatch["revPreOpenStack"]
      send "revPreOpenStack" to this cd of stack l
   end repeat
end revIDEHandleNewStack


command revOpenStacks
   local filterstring
   if the systemFileSelector then
      switch the platform
         case "Win32"
            put "LiveCode Stacks" & cr & "*.rev" & cr & "MetaCard Stacks" & cr & "*.mc" & cr & "All Files" & cr & "*.*" into filterstring
         break
         case "MacOS"
            put "MSTKSTAKTEXTRSTK" into filterstring
         break
         default
            put "*.rev" into filterstring
      end switch
   else put "*.rev" into filterstring
   get revAnswerFiles("stack","Open stack:")
   if it is not empty then
      local tStacksToOpen
      put it into tStacksToOpen
      repeat for each line tStackToOpen in tStacksToOpen
         revOpenStack tStackToOpen
      end repeat
   end if
   return tStacksToOpen
end revOpenStacks

on revOpenStack pStackName
   revIDEOpenStack pStackName
end revOpenStack

# Returns the *actual* path of the file specified by pPath. Returns empty if the file doesnt exist
private function utilityCanonicalizePath pPath
   set the itemDelimiter to slash
   
   local tFolder, tFilename
   put item 1 to -2 of pPath into tFolder
   put item -1 of pPath into tFilename
   
   revIDEPushDefaultFolder tFolder
   
   set the caseSensitive to utilityPathIsCaseSensitive(pPath)
   
   local tFiles
   put the files into tFiles
   
   local tLineNumber
   set the wholeMatches to true
   put lineOffset(tFilename, tFiles) into tLineNumber
   
   local tExists
   if tLineNumber = 0 then
      put false into tExists
   else
      put true into tExists
   end if
   
   local tCanonicalFolder
   put the defaultFolder into tCanonicalFolder
   revIDEPopDefaultFolder
   
   if tExists then
      return tCanonicalFolder & slash & line tLineNumber of tFiles
   else
      return empty
   end if
end utilityCanonicalizePath

# Returns whether the path pPath is case sensitive. pPath must point to a file.
private function utilityPathIsCaseSensitive pPath
  local tFolder
  
  local tOriginalFolder
  put the folder into tOriginalFolder
  
  set the itemDelimiter to slash
  put item 1 to -2 of pPath into tFolder
  
  local tIsCaseSensitive
  put false into tIsCaseSensitive
  
  set the folder to tolower(tFolder)
  if the result is not empty then
    put true into tIsCaseSensitive
  end if
  
  set the folder to toupper(tFolder)
  if the result is not empty then
    put true into tIsCaseSensitive
  end if
  
  set the folder to tOriginalFolder
  
  return tIsCaseSensitive
end utilityPathIsCaseSensitive

/*

Subscribe to ideMouseMove in order to set the cursor to the appropriate 
resize cursor when the mouse is over a selection handle.

*/

constant kHandleSize = 5

on ideMouseMove pX, pY, pTarget
   if the tool is not "pointer tool" then exit ideMouseMove
   
   if pTarget is among the lines of the selectedObjects then
      local tRect
      put the rect of pTarget into tRect
      local tLeft = false
      local tTop = false
      local tRight = false
      local tBottom = false
      local tCenterY = false
      local tCenterX = false
      local tHandleOffset
      
      if pX < item 1 of tRect + kHandleSize then
         put true into tLeft
      else if pX > item 3 of tRect - kHandleSize then
         put true into tRight
      else
         put (the width of pTarget - kHandleSize) / 2 into tHandleOffset
         if pX >= item 1 of tRect + tHandleOffset \
               and pX <= item 3 of tRect - tHandleOffset then
            put true into tCenterX
         end if
      end if
      
      if pY < item 2 of tRect + kHandleSize then
         put true into tTop
      else if pY > item 4 of tRect - kHandleSize then
         put true into tBottom
      else
         put (the height of pTarget - kHandleSize) / 2 into tHandleOffset
         if pY >= item 2 of tRect + tHandleOffset \
               and pY <= item 4 of tRect - tHandleOffset then
            put true into tCenterY
         end if
      end if
      
      lock cursor
      if (tLeft and tTop) or (tRight and tBottom) then
         -- resize topLeft to bottomRight cursor
         set the cursor to 83
      else if (tLeft and tBottom) or (tRight and tTop) then
         -- resize bottomLeft to topRight cursor
         set the cursor to 84
      else if (tLeft and tCenterY) or (tRight and tCenterY) then
         -- horizontal resize cursor
         set the cursor to 31
      else if (tTop and tCenterX) or (tBottom and tCenterX) then
         -- vertical resize cursor
         set the cursor to 30
      else
         unlock cursor
      end if
   else
      unlock cursor
   end if
end ideMouseMove

on msgChanged pHandler, pLine
   global gRevDevelopment
   if gRevDevelopment then
      pass msgChanged
   end if
end msgChanged
