script "revSEScriptTabsBehavior"
# How much the selected tab should grow by
constant kSelectedTabGrowth = 2
constant kMaxTabWidth = 200

# Stores a mapping from tab number to full object id.
local sTabMap

# Stores a mapping from tab number to long id of control representing tab.
local sTabButtonMap

# Stores the number of the current selected tab. This may be empty if tabs have been
# added but none have been selected yet.
local sSelectedTab

# Stores a list of previously selected tabs.
local sHistory

# This will be set to true if tabs were clipped when resizing.
local sTabsClipped = "false"

command getTabOrdering
   return sTabMap
end getTabOrdering

command setTabOrdering pOrdering
   --put pOrdering into sTabMap
   
   # Rebuild the tab button map, as the buttons may no longer match up with their objects, causing the appearence of resizing.
   local tTabNumbers
   put the keys of sTabMap into tTabNumbers
   
   local tNewButtonMap, tObjectMap
   repeat for each line tTabNumber in tTabNumbers
      # Take the control id from the original tab button map 
      local tControl
      put sTabButtonMap[tTabNumber] into tControl
      
      local tObject
      put sTabMap[tTabNumber] into tObject
      put tControl into tObjectMap[tObject]
   end repeat
   
   repeat for each key tTabNumber in pOrdering
      put pOrdering[tTabNumber] into tObject
      put tObjectMap[tObject] into tNewButtonMap[tTabNumber]
   end repeat
   put tNewButtonMap into sTabButtonMap
   put pOrdering into sTabMap
   
   refreshTabStates
   --reorderTabs
   resize
end setTabOrdering

# Description
#   Sent by the parent when the object might have been resized. Resizes / moves all the controls
#   to fit the new rect.
command resize
   local tTabNumbers
   put the keys of sTabMap into tTabNumbers
   sort tTabNumbers numeric descending
   
   local tLeft, tBottom
   put the left of me into tLeft
   put the bottom of me into tBottom
   
   lock screen
   local tControl
   
   put false into sTabsClipped
   repeat for each line tTabNumber in tTabNumbers
      put sTabButtonMap[tTabNumber] into tControl
      
      # Remove the close button for now as it doesn't seem needed.
      set the bottom of button "Close" of me to the top of me - 500
      
      set the topRight of button "Toggle Toolbars" of me to the topRight of me
      set the topRight of button "History" of me to the topLeft of button "Toggle Toolbars" of me
      
      # Clip tabs that don't fit out of the top of the group.
      if tLeft + the width of tControl >= the left of button "Active Tabs" of me then
         set the cVisible of tControl to false
         set the bottom of tControl to the top of me - 10
         put true into sTabsClipped
      else
         set the cVisible of tControl to true
         set the bottom of tControl to tBottom
      end if
      set the left of tControl to tLeft
      
      # The active tabs button is only shown when tabs have been clipped.
      if sTabsClipped then
         set the topRight of button "Active Tabs" of me to the topLeft of button "History" of me
      else
         set the right of button "Active Tabs" of me to the left of button "History" of me
         set the top of button "Active Tabs" of me to the top of me - 500
      end if
      
      # Tabs should overlap by 1 pixel to prevent double borders.
      add the width of tControl - 1 to tLeft
      
      # In case the control is a group
      send "resize" to tControl
   end repeat
   
   unlock screen
end resize

# Returns
#   The long id of the object that is the currently selected tab
command getCurrentTab
   return sTabMap[sSelectedTab]
end getCurrentTab

# Parameters
#   pObject : new rugged id of the object whose id has changed
#   pOldRuggedId : old rugged id of the object.
# Description
#   Updates the stored reference to the object with the new id.
command updateObjectRuggedId pObject, pOldRuggedId
   # Update the value in sTabMap. This should be all that is required, however note that 
   # if the object had no name, its id will be displayed on its tab. This can be updated by
   # calling refreshTabStates.
   repeat for each key tKey in sTabMap
      if sTabMap[tKey] is pOldRuggedId then
         put pObject into sTabMap[tKey]
      end if
   end repeat
   
   # Replace the object's reference in the history
   historyReplace pOldRuggedId, pObject
end updateObjectRuggedId

# Parameters
#   pObject : reference to the object who's id needs updating
#   pOldId : the object's old id
#   pNewId : the object's new id
# Description
#   Sent when the id of an object has changed. Updates the group's internal storage
#   to contain a correct reference to the object so that the user can continue to edit
#   the script etc with no problems.
command updateObjectId pObject, pOldId, pNewId
   # As our old reference to the object will no longer be valid, we first
   # reconstruct the reference using pOldId, and find which tab number it is.
   # Note that this event is not appropriate to stacks or cards, so we don't bother 
   # supporting them. (In fact only images can have their IDs changed.)
   local tOldObject
   --put word 1 of the name of pObject & " id " & pOldId & " of stack " & quote & revTargetStack(pObject) & quote into tOldObject
   put "control id " & pOldId & " of stack " & quote & revTargetStack(pObject) & quote into tOldObject
   
   # Construct the new id in the normal way
   local tNewObject
   put ruggedId(pObject) into tNewObject
   
   # Update the value in sTabMap. This should be all that is required, however note that 
   # if the object had no name, its id will be displayed on its tab. This can be updated by
   # calling refreshTabStates.
   repeat for each key tKey in sTabMap
      if sTabMap[tKey] is tOldObject then
         put tNewObject into sTabMap[tKey]
      end if
   end repeat
end updateObjectId

private function listVisibleTabs
   local tControl, tVisibleTabs
   repeat for each key tKey in sTabMap
      put sTabButtonMap[tKey] into tControl
      if the cVisible of tControl then
         put tKey & return after tVisibleTabs
      end if
   end repeat
   delete the last char of tVisibleTabs
   sort tVisibleTabs numeric descending
   return tVisibleTabs
end listVisibleTabs

# Description
#   Cycles forward in the tabs list
command goNextTab
   local tTabs
   put listVisibleTabs() into tTabs
   
   # Because this is a user triggered action, we don't throw an error if there are no tabs
   # to cycle through, instead just do nothing
   if the number of lines of tTabs = 0 then
      exit goNextTab
   end if
   
   # Note that tabs are displayed in reverse order, but from the user's point of view
   # moving forward means left to right, so we actually move backwards here in terms of the keys
   local tTabNumber
   if sSelectedTab <= line -1 of tTabs or sSelectedTab is not among the lines of  tTabs then
      put line 1 of tTabs into tTabNumber
   else
      set the wholeMatches to true
      put line (lineOffset(sSelectedTab, tTabs) + 1) of tTabs into tTabNumber
      set the wholeMatches to false
   end if
   
   local tObject
   put sTabMap[tTabNumber] into tObject
   
   revSESetCurrentObject tObject
end goNextTab

# Description
#   Cycles backwards in the tabs list
command goPreviousTab
   local tTabs
   put listVisibleTabs() into tTabs
   
   # Because this is a user triggered action, we don't throw an error if there are no tabs
   # to cycle through, instead just do nothing
   if the number of lines of tTabs = 0 then
      exit goPreviousTab
   end if
   
   # Note that tabs are displayed in reverse order, but from the user's point of view
   # moving forward means left to right, so we actually move backwards here in terms of the keys
   local tTabNumber
   if sSelectedTab >= line 1 of tTabs or sSelectedTab is not among the lines of  tTabs then
      put line -1 of tTabs into tTabNumber
   else
      set the wholeMatches to true
      put line (lineOffset(sSelectedTab, tTabs) - 1) of tTabs into tTabNumber
      set the wholeMatches to false
   end if
   
   local tObject
   put sTabMap[tTabNumber] into tObject
   
   revSESetCurrentObject tObject
end goPreviousTab


# Parameters
#   pObject : reference to an object that is currently among the tabs of the script tabs group.
# Description
#   Sets the current tab to the specified object.
command setCurrentTab pObject
   local tObject
   put ruggedId(pObject) into tObject
   
   local tTabNumber
   repeat for each key tKey in sTabMap
      if sTabMap[tKey] is tObject then
         put tKey into tTabNumber
         exit repeat
      end if
   end repeat
   
   local tControl
   put sTabButtonMap[tTabNumber] into tControl
   put tTabNumber into sSelectedTab
   
   selectObject tControl
   historyAdd tObject
   
   if not the cVisible of tControl then
      reorderTabs
   end if
end setCurrentTab

# Description
#   Ensures the the currently selected tab is always visible by moving it to the front and reordering
#   other tabs as appropriate.
private command reorderTabs
   local tNewTabMap, tNewButtonMap
   repeat for each key tTabNumber in sTabMap
      if tTabNumber < sSelectedTab then
         put sTabMap[tTabNumber] into tNewTabMap[tTabNumber]
         put sTabButtonMap[tTabNumber] into tNewButtonMap[tTabNumber]
      else if tTabNumber >sSelectedTab then
         put sTabMap[tTabNumber] into tNewTabMap[tTabNumber - 1]
         put sTabButtonMap[tTabNumber] into tNewButtonMap[tTabNumber - 1]
      end if
   end repeat
   
   local tTabCount
   put the number of lines of the keys of sTabMap into tTabCount
   put sTabMap[sSelectedTab] into tNewTabMap[tTabCount]
   put sTabButtonMap[sSelectedTab] into tNewButtonMap[tTabCount]
   
   put tTabCount into sSelectedTab
   put tNewTabMap into sTabMap
   put tNewButtonMap into sTabButtonMap
   resize
end reorderTabs

# Parameters
#   pObject : reference to an object
# Description
#   Adds the specified object to the tabs list, at the back. Does not select the newly added
#   object, to do this use the setCurrentTab command.
command addTab pObject
   local tObject
   put ruggedId(pObject) into tObject
   
   put tObject into sTabMap[the number of lines of the keys of sTabMap + 1]
   
   local tFriendlyName
   put makeFriendly(tObject) into tFriendlyName
   
   lock screen
   local tControl
   clone getTabTemplate()
   
   # Lock messages here to prevent nameChanged being handled by revFrontScript, leading to the script
   # editor doing lots of stuff that isnt needed.
   lock messages
   set the name of it to "Tab " & the number of lines of the keys of sTabMap
   unlock messages
   
   put the long id of it into tControl
   put tControl into sTabButtonMap[the number of lines of the keys of sTabMap]
   set the cRawLabel of tControl to tFriendlyName
   set the visible of tControl to true
   set the cTooltip of tControl to revDebuggerObjectLongName(tObject)
   
   local tNewWidth
   put min(kMaxTabWidth, the cFormattedWidth of tControl + 5) into tNewWidth
   
   set the backgroundColor of tControl to tabColor("false", pObject)
   set the cIcon of tControl to tabImage("false", pObject, false)
   set the cOverIcon of tControl to tabImage("false", pObject, true)
   
   set the width of tControl to tNewWidth
   set the cTab of tControl to true
   send "resize" to tControl
   
   set the cLabel of tControl to tFriendlyName
   
   unlock screen
   
   resize
end addTab


private function tabImage pSelected, pObject, pRollover
   local tState
   put seGetObjectState(pObject) into tState
   
   local tTag
   put "tab" & tState into tTag
   if pSelected then
      put "Selected" after tTag
   else
      put "Normal" after tTag
   end if
   
   if pRollover then
      put "Over" after tTag
   end if
   
   local tId
   put seGetIcon(tTag) into tId
   return tId
end tabImage
     
# Parameters
#   pSelected : whether the tab is selected or not
#   pState : what the tab's state is ("applied", "edited" or "error")
# Returns
#   The color that the tab should be in the given state.
private function tabColor pSelected, pObject
   if pSelected then
      return "255,255,255"
   else
      return "251,251,252"
   end if
   
   # The following code implements the colored tabs and is left here for now in case we decide to use it.
   
   local tState
   put seGetObjectState(pObject) into tState
   
   if pSelected then
      switch tState
      case "applied"
         return "225,242,226"
      break
      case "edited"
         return "242,236,225"
      break
      case "error"
         return "241,226,226"
      break
      end switch
   end if
   
   if not pSelected then
      switch tState
      case "applied"
         return "224,234,231"
      break
      case "edited"
         return "233,231,230"
      break
      case "error"
         return "232,226,231"
      break
      end switch
   end if
   
   return empty
end tabColor

# Parameters
#   pObject : reference to an object that is currently among the tabs of the script tabs group
#   pDontCheckReference : if true, assumes that pObject is a valid rugged id and doesnt lookup the object.
# Description
#   Removes the specified tab from the tabs group. If the removed tab was the currently selected tab
#   then the previously selected tab becomes the new selected tab. If there was no previously
#   selected tab, then the first added tab is selected.
command removeTab pObject, pDontCheckReference
   local tObject
   if pDontCheckReference then
      put pObject into tObject
   else
      put ruggedId(pObject) into tObject
   end if
   
   local tTabNumber
   repeat for each key tKey in sTabMap
      if sTabMap[tKey] is tObject then
         put tKey into tTabNumber
         exit repeat
      end if
   end repeat
   
   local tControl
   put sTabButtonMap[tTabNumber] into tControl
   delete variable sTabMap[tTabNumber]
   delete variable sTabButtonMap[tTabNumber]
   updateTabMap
   
   local tCurrentTabDeleted
   put false into tCurrentTabDeleted
   if tTabNumber = sSelectedTab then
      put true into tCurrentTabDeleted
   else if tTabNumber < sSelectedTab then
      subtract 1 from sSelectedTab
   end if
   
   delete tControl
   
   historyRemove tObject
   
   # If we deleted the current tab and other tabs are present, choose one as the new current tab.
   if tCurrentTabDeleted and the number of lines of the keys of sTabMap is not 0 then
      # The first history item will be the previously selected tab now we have deleted the currently selected one.
      if historyGet(1) is not empty then
         setCurrentTab historyGet(1)
      else
         # No previously selected tab is available, so fall back to using the first added tab. This shouldn't ever happen,
         # but it doesn't seem sensible to throw an error.
         setCurrentTab sTabMap[line 1 of the keys of sTabMap]
      end if
   end if
   
   resize
end removeTab

# Description
#   Removes all tabs and clears the history.
command removeAllTabs
   local tText
   repeat for each key tKey in sTabMap
      delete variable sTabmap[tKey]
      delete variable sTabMap[tKey]
   end repeat
   
   local tControlsToDelete
   repeat with x = 1 to the number of controls of me
      if the cTab of control x of me then
         put the long id of control x of me & return after tControlsToDelete
      end if
   end repeat
   delete the last char of tControlsToDelete
   
   repeat for each line tControl in tControlsToDelete
      lock messages
      delete tControl
      unlock messages
   end repeat
   
   historyClear
end removeAllTabs

# Returns
#   A return-delimited list of object ids
# Description
#   Returns a list of the tabs
command listTabs
   local tList
   repeat for each key tKey in sTabMap
      put sTabMap[tKey] & return after tList
   end repeat
   delete the last char of tList
   return tList
end listTabs

# Description
#   Called by the parent when the tabs group should be initialized, i.e. when a new script edior is opened.
command initialize
   removeAllTabs
   set the icon of button "Close" of me to seGetIcon("tabClose")
   set the hoverIcon of button "Close" of me to seGetIcon("tabCloseOver")
   
   set the icon of button "History" of me to seGetIcon("tabHistory")
   set the hoverIcon of button "History" of me to seGetIcon("tabHistoryOver")
   
   set the icon of button "Active Tabs" of me to seGetIcon("tabActive")
   set the hoverIcon of button "Active Tabs" of me to seGetIcon("tabActiveOver")
   
   updateToggleIcon
end initialize

# Description
#   Called when one or more tabs might have changed their name or edited state
#   refreshes the tab states by updating the labels of the tab buttons
command refreshTabStates
   local tControl, tObject
   repeat for each key tTabNumber in sTabMap
      put sTabButtonMap[tTabNumber] into tControl
      put sTabMap[tTabNumber] into tObject
      set the cLabel of tControl to makeFriendly(tObject)
      set the cTooltip of tControl to the long name of tObject
      set the backgroundColor of tControl to tabColor((sSelectedTab = tTabNumber), tObject)
      set the cIcon of tControl to tabImage((sSelectedTab = tTabNumber), tObject, false)
      set the cOverIcon of tControl to tabImage((sSelectedTab = tTabNumber), tObject, true)
   end repeat
end refreshTabStates

# Parameters
#   pObject : the long id of an object
# Description
#   Returns a friendly form of the long id suitable for displaying on tabs.
private function makeFriendly pObject
   local tBase
   put seFriendlyObject(pObject) into tBase
   
   if seGetObjectState(pObject) is "edited" then
      return tBase
   else if seGetObjectState(pObject) is "error" then
      return tBase
   else
      return tBase
   end if
end makeFriendly

# Parameters
#   pObject : the rugged id of an object
# Description
#   Called when a tab is selected, adds the associated object to the front of a history stack.
#   if the object is already in the history stack, it is removed and put back at the front.
private command historyAdd pObject
   historyRemove pObject
   
   if sHistory is empty then
      put pObject into sHistory
   else
      put pObject & return before sHistory
   end if
end historyAdd

# Parameters
#   pObject : the rugged id of an object
# Description
#   Removes pObject from the history list. Does not change the order. If pObject is not in the list, does nothing.
private command historyRemove pObject
   local tLineNumber
   set the wholeMatches to true
   put lineOffset(pObject, sHistory) into tLineNumber
   set the wholeMatches to false
   if tLineNumber <> 0 then
      delete line tLineNumber of sHistory
   end if
end historyRemove

private command historyReplace pOldObject, pNewObject
   local tLineNumber
   set the wholeMatches to true
   put lineOffset(pOldObject, sHistory) into tLineNumber
   set the wholeMatches to false
   if tLineNumber = 0 then
      exit historyReplace
   end if
   
   put pNewObject into line tLineNumber of sHistory
end historyReplace

# Parameters
#   pIndex : history entry number to get, from 1 up to the number of history items
# Returns
#   The specified history object, or empty if not found.
private function historyGet pIndex
   return line pIndex of sHistory
end historyGet

# Returns
#   The number of history items available. This is a number between 0 and the number of tabs.
private function historyGetCount
   return the number of lines of sHistory
end historyGetCount

# Description
#   Clears the history
private command historyClear
   put empty into sHistory
end historyClear

# Description
#   Called when tabs are removed, updates the tab map so that the mapping
#   from menuHistory to object is preserved.
private command updateTabMap
   local tKeys
   put the keys of sTabMap into tKeys
   sort tKeys numeric
   
   local tNewTabMap, tNewTabButtonMap
   
   local tTabNumber
   put 1 into tTabNumber
   repeat for each line tKey in tKeys
      put sTabMap[tKey] into tNewTabMap[tTabNumber]
      
      local tControl
      put sTabButtonMap[tKey] into tControl
      set the name of tControl to "Tab " & tTabNumber
      put the long id of tControl into tNewTabButtonMap[tTabNumber]
    
      add 1 to tTabNumber
   end repeat
   
   put tNewTabMap into sTabMap
   put tNewTabButtonMap into sTabButtonMap
end updateTabMap

# Parameters
#   pObject : reference to the tab object to select. This is the long id of a control in this group, not a script editor object.
# Description
#   Selects the specified tab object by setting some of its properties, deselects all other tabs first.
private command selectObject pObject
   lock screen
   repeat for each key tTabNumber in sTabMap
      local tCurrentObject
      put sTabButtonMap[tTabNumber] into tCurrentObject
      
      local tEditorObject
      put sTabMap[tTabNumber] into tEditorObject
      
      local tBottom
      put the bottom of tCurrentObject into tBottom
      if tCurrentObject is the long id of pObject then
         
         set the height of tCurrentObject to the height of getTabTemplate() + kSelectedTabGrowth
         set the backgroundColor of tCurrentObject to tabColor(true, tEditorObject)
         set the cIcon of tCurrentObject to tabImage(true, tEditorObject)
         set the cOverIcon of tCurrentObject to tabImage(true, tEditorObject, true)
         set the bottom of tCurrentObject to tBottom
         set the textStyle of tCurrentObject to "bold"
      else
         set the height of tCurrentObject to the height of getTabTemplate()
         set the backgroundColor of tCurrentObject to tabColor(false, tEditorObject)
         set the cIcon of tCurrentObject to tabImage(false, tEditorObject)
         set the cOverIcon of tCurrentObject to tabImage(false, tEditorObject, true)
         set the bottom of tCurrentObject to tBottom
         set the textStyle of tCurrentObject to empty
      end if
      
      send "resize" to tCurrentObject
   end repeat
   unlock screen
end selectObject

# Returns
#   The long id of the control to use as a tab template
private function getTabTemplate
   return the long id of group "Template Tab" of me
end getTabTemplate

private command updateHistoryMenu
   local tText
   put "(Recent scripts" & return & "-" & return into tText
   
   local tHistory
   put seHistoryGet() into tHistory
   
   if tHistory is empty then
      put "(Nothing to display" after tText
   else
      repeat for each line tObject in tHistory
         put makeFriendly(the long id of tObject) & return after tText
      end repeat
      delete the last char of tText
   end if
   
   set the text of button "History Menu" of me to tText
   set the cFullItems of button "History Menu" of me to tHistory
end updateHistoryMenu

private command updateContextMenu pTabNumber
   set the cTabNumber of button "Tab Context Menu" of me to pTabNumber
   
   local tText
   put "Close tab" & return after tText
   
   if the number of lines of the keys of sTabMap > 1 then
      put "Move to new window" & return after tText
   else
      put "(Move to new window" & return after tText
   end if
   
   if the number of lines of the keys of sTabMap > 1 then
      put "Close other tabs" after tText
   else
      put "(Close other tabs" after tText
   end if
   set the text of button "Tab Context Menu" of me to tText
end updateContextMenu

command updateActiveTabsMenu
   local tText
   put "(Active tabs" & return & "-" & return into tText
   
   local tKeys
   put the keys of sTabMap into tKeys
   sort tKeys numeric descending
   
   local tFullItems
   repeat for each line tTabNumber in tKeys
      put makeFriendly(sTabMap[tTabNumber]) & return after tText
      put sTabMap[tTabNumber] & return after tFullItems
   end repeat
   delete the last char of tText
   
   set the text of button "Active Tabs Menu" of me to tText
   set the cFullItems of button "Active Tabs Menu" of me to tFullItems
end updateActiveTabsMenu

private command tabsMenuPick pItemName
   if pItemName is "Active Tabs" then
      exit tabsMenuPick
   end if
   
   local tObject
   put line (the menuHistory of button "Active Tabs Menu" of me - 2) of the cFullItems of button "Active Tabs Menu" of me into tObject
   if there is a tObject then
      revSESetCurrentObject tObject
   end if
end tabsMenuPick

private command contextMenuPick pItemName
   local tTabNumber
   put the cTabNumber of the target into tTabNumber
   
   switch pItemName
      case "Close tab"
         deleteTab tTabNumber
         break
         
      case "Close other tabs"
         local tObjectToKeep
         put sTabMap[tTabNumber] into tObjectToKeep
         local tObjectsToRemove
         repeat for each key tCurrentTabNumber in sTabMap
            local tObject
            put sTabMap[tCurrentTabNumber] into tObject
            if tObject is not tObjectToKeep then
               put tObject & return after tObjectsToRemove
            end if
         end repeat
         delete the last char of tObjectsToRemove
         
         # OK-2009-03-10 : Before issuing a warning, we need to check if the objects have actually
         # been modified.
         local tModifiedObjects
         revSEGetModifiedObjects
         put the result into tModifiedObjects
         
         local tModifiedRemovedObjects
         repeat for each line tObjectToRemove in tObjectsToRemove
            if tObjectToRemove is among the lines of tModifiedObjects then
               put tObjectToRemove & return after tModifiedRemovedObjects
            end if
         end repeat
         delete the last char of tModifiedRemovedObjects
         
         if tModifiedRemovedObjects is not empty then
            revSEWarnBeforeClosing tModifiedRemovedObjects
            if the result is "cancel" then
               exit contextMenuPick
            end if
         end if
         
         lock screen
         repeat for each line tObjectToRemove in tObjectsToRemove
            revSERemoveTargetObject tObjectToRemove, true
         end repeat
         unlock screen
         break
         
      case "Move to new window"
         lock screen
         local tObjectToMove
         put sTabMap[tTabNumber] into tObjectToMove
         deleteTab tTabNumber
         revEditScriptInNewWindow tObjectToMove
         break
         
   end switch
end contextMenuPick

private function targetResolve pTarget
   local tOwner
   put pTarget into tOwner
   repeat until word 1 of the name of tOwner is "card" or tOwner is empty
      if the cTab of tOwner then
         return the long id of tOwner
      end if
      put the owner of tOwner into tOwner
   end repeat
   return empty
end targetResolve

private command historyMenuPick pItemName
   local tObject
   put line (the menuHistory of button "History Menu" of me - 2) of the cFullItems of button "History Menu" of me into tObject
   if there is a tObject then
      revSEAddTargetObject tObject
      revSESetCurrentObject tObject
   end if
end historyMenuPick
  
on menuPick pItemName
   if the long id of the target is the long id of button "Tab Context Menu" of me then
      contextMenuPick pItemName
   else if the long id of the target is the long id of button "History Menu" of me then
      historyMenuPick pItemName
   else if the the long id of the target is the long id of button "Active Tabs Menu" of me then
      tabsMenuPick pItemName
   end if
end menuPick

on mouseDown pButtonNumber
   if the long id of the target is the long id of button "History" of me then
      updateHistoryMenu
      popup button "History Menu" of me
      exit mouseDown
   end if
   
   if the long id of the target is the long id of button "Active Tabs" of me then
      updateActiveTabsMenu
      popup button "Active Tabs Menu" of me
      exit mouseDown
   end if
   
   local tTarget
   put targetResolve(the long id of the target) into tTarget
   
   if pButtonNumber is 3 and tTarget is not empty and the cTab of tTarget then
      repeat for each key tTabNumber in sTabMap
         if sTabButtonMap[tTabNumber] is the long id of tTarget then
            updateContextMenu tTabNumber
            popup button "Tab Context Menu" of me
            exit repeat
         end if
      end repeat
   end if
end mouseDown

on mouseUp pButtonNumber
   if pButtonNumber is not 1 then
      pass mouseUp
   end if
   
   # OK-2008-07-07 : Bug 6718 - Clicking anywhere in the script tabs group should hide the handler list.
   seHideHandlerList
   
   if the long id of the target is the long id of button "Close" of me then
      lock screen
      deleteTab sSelectedTab
      unlock screen
      exit mouseUp
   end if
   
   if the long id of the target is the long id of button "Toggle Toolbars" of me then
      lock screen
      local tMode
      revSEGetMode
      put the result into tMode
      
      sePrefSet (tMode & "showToolbars"), (not sePrefGet(tMode & "showToolbars"))
      actionResizeStack
      updateToggleIcon
      unlock screen
      exit mouseUp
   end if
   
   local tTab
   put targetResolve(the long id of the the target) into tTab
   
   lock screen
   if tTab is not empty and the cTab of tTab then
      local tClickedTabNumber
      repeat for each key tTabNumber in sTabMap
         if sTabButtonMap[tTabNumber] is the long id of tTab then
            put tTabNumber into tClickedTabNumber
            exit repeat
         end if
      end repeat
      
      # The icon on the left of the tabs is a close button
      if the short name of the target is "Tab Icon" then
         deleteTab tClickedTabNumber
      else
         # Clicking anywhere else in the tab selects it

         -- It's necessary to reset the focus, because
         -- revSESetCurrentObject blocks the messages that would
         -- otherwise trigger focus-loss messages on fields (such as
         -- the handler filter field in the left bar of the script
         -- editor).
         focus on nothing

         revSESetCurrentObject sTabMap[tClickedTabNumber]
      end if
   end if
   unlock screen
end mouseUp

private command deleteTab pWhich
   send "revSERemoveTargetObject sTabMap[pWhich]" to me in 0 millisecs
end deleteTab

private command updateToggleIcon
   local tMode
   revSEGetMode
   put the result into tMode
   if sePrefGet(tMode & "showToolbars") then
      set the icon of button "Toggle Toolbars" of me to seGetIcon("tabToggleUpNormal")
      set the hoverIcon of button "Toggle Toolbars" of me to seGetIcon("tabToggleUpOver")
   else
      set the icon of button "Toggle Toolbars" of me to seGetIcon("tabToggleDownNormal")
      set the hoverIcon of button "Toggle Toolbars" of me to seGetIcon("tabToggleDownOver")
   end if
end updateToggleIcon

private function ruggedId pObject
  return seGetRuggedId(pObject)
end ruggedId
