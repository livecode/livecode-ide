script "revSEPaneTabsBehavior"
# Description
#   Sent by the parent when the rect of this group may have changed. Updates all controls in this group
#   to reflect the group's current rect.
command resize
   lock screen
   local tLeft, tBottom
   put the left of me into tLeft
   put the bottom of me into tBottom
   repeat for each item tPane in seAvailablePanes()
      if tPane is among the items of seVisiblePanes() then
         set the bottomLeft of button tPane of me to tLeft, tBottom
      else
         set the bottomLeft of button tPane of me to tLeft, the top of me - 10
      end if
      add the width of button tPane of me to tLeft
   end repeat
   unlock screen
end resize

local sSelectedTab

# Description
#   Sent by the parent when a preference or something else has changed that might affect this group.
#   Causes the group to refresh itself. At the moment this happens when the user wants to add or remove
#   one of the panes from the group.  The group resizes itself, which causes non-visible panes to be clipped.
#   If the selected pane was made non-visible then the first pane is set as the new selected pane.
command update
   resize
   
   # For now, don't keep a history of selected panes, just select the first one
   if sSelectedTab is not among the items of seVisiblePanes() then
      setCurrentTab item 1 of seVisiblePanes()
   end if
end update

on mouseUp
  if the cTab of the target then
    setCurrentTab (the short name of the target)
  end if
end mouseUp

# Parameters
#   pTab : the name of the tab to set as current
# Description
#   Sets the current (highlighted) tab to the specified tab
command setCurrentTab pTab
   lock screen
   
    put pTab into sSelectedTab
   
   call "showPane pTab" to group "Panes" of the long owner of me
   call "refreshCurrentPane" to group "Panes" of the long owner of me
   
   local tMode
   revSEGetMode
   put the result into tMode
   
   sePrefSet (tMode & ",lastSelectedPane"), pTab
   selectObject (the long id of button pTab of me)
end setCurrentTab

# Description
#   Returns the name of the currently selected tab
command getCurrentTab
  return sSelectedTab
end getCurrentTab

constant kSelectedTabGrowth = 2
constant kTabHeight = 21

# Parameters
#   pObject : reference to the tab object to select. This is the long id of a control in this group, not a script editor object.
# Description
#   Selects the specified tab object by setting some of its properties, deselects all other tabs first.
private command selectObject pObject
  lock screen
  repeat with x = 1 to the number of controls of me
    if not the cTab of control x of me then
      next repeat
    end if
     
    local tCurrentObject
    put the long id of control x of me into tCurrentObject
     
    local tBottom
    put the bottom of tCurrentObject into tBottom
    if tCurrentObject is the long id of pObject then
      set the height of tCurrentObject to kTabHeight + kSelectedTabGrowth
      set the backgroundColor of tCurrentObject to "255,255,255"
      set the bottom of tCurrentObject to tBottom
      set the textStyle of tCurrentObject to "bold"
    else
      set the height of tCurrentObject to kTabHeight
      set the backgroundColor of tCurrentObject to empty
      set the bottom of tCurrentObject to tBottom
      set the textStyle of tCurrentObject to empty
    end if
  end repeat
  unlock screen
end selectObject
