script "revSEPanesBehavior"
local sActivePane
local sLastPaneSize

# Description
#   Sent by the parent when the rect of this group may have changed. Updates all con.trols inside
#   the group to reflect the group's current rect.
command resize
   # Only resize the panes if the paneHeight has changed since last time we knew about it
   # this prevents a slow resizing pane from affecting the left bar resizing or the script editor stack resizing.
   local tNewPaneSize
   put the width of me, the height of me, the bottom of me into tNewPaneSize
   if sLastPaneSize = tNewPaneSize then
      exit resize
   else
      put tNewPaneSize into sLastPaneSize 
   end if
   
   lock screen
   if there is a group sActivePane of me then
      set the rect of group sActivePane of me to the rect of me
      call "paneResizeControl" to group sActivePane of me
   end if
   unlock screen
end resize

# Parameters
#   pPane : the name of the pane to show.
# Description
#   Shows the specified pane, bringing it to the front.
#   If the specified pane is not available, does nothing.
command showPane pPane
  if pPane is not among the items of seAvailablePanes() then
    exit showPane
 end if
  
  lock screen
  repeat for each item tPane in seAvailablePanes()
    if tPane is pPane then
      set the rect of group tPane of me to the rect of me
      call "paneResizeControl" to group tPane of me
      
      # Don't update the pane here, if that is required, refreshCurrentPane should be used instead.
      # send "update" to group tPane of me
      put tPane into sActivePane
    else
      set the right of group tPane of me to the left of me -1000
    end if
  end repeat
  unlock screen
end showPane

# Description
#   Updates the current pane. If there is no current pane, i.e. there are no panes
#   in use, does nothing.
command refreshCurrentPane
   local tCurrentPane
   call "getCurrentTab" to group "Pane Tabs" of this card of the long owner of me
   put the result into tCurrentPane
   
   if tCurrentPane is empty then
      exit refreshCurrentPane
   end if
   
   lock screen
   call "update" to group tCurrentPane of me
   unlock screen
end refreshCurrentPane

# OK-2010-02-26: Added to get around the large delay caused when adding / removing breakpoints
command refreshCurrentPaneIfItsBreakpoints
   local tCurrentPane
   call "getCurrentTab" to group "Pane Tabs" of this card of the long owner of me
   put the result into tCurrentPane
   
   if tCurrentPane is empty then
      exit refreshCurrentPaneIfItsBreakpoints
   end if
   
   # The screen is not locked here because this command is currently only called by the Gutter group,
   # which has already locked the screen in all cases it calls this.
   if tCurrentPane is "Breakpoints" then
      call "update" to group tCurrentPane of me
   end if
end refreshCurrentPaneIfItsBreakpoints

# Description
#   Expands the current pane to its minimum viewable size. This is called to make a pane jump to the user's
#   attention for example if they have search performed a search to show the results, or have encountered
#   errors when attempting to compile a script.
command expandCurrentPane
   local tHeight
   switch sActivePane
      case "Errors"
         put 60 into tHeight
      break
      default
         put "150" into tHeight
      break
   end switch
   
   if sePrefGet("paneHeight") < tHeight then
      sePrefSet "paneHeight", tHeight
      lock screen
      actionResizeStack
      unlock screen
   end if
end expandCurrentPane
