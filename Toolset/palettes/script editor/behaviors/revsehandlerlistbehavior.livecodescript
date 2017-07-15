script "revSEHandlerListBehavior"
command initialize
   lock screen
   update
   
   focus on field "Handlers" of me

   local tLineNumber
   put 1 into tLineNumber
   
   local tMatchingLineNumber
   repeat for each line tHandler in the cHandlers of field "Handlers" of me
      if word 2 of tHandler is the cSelectedHandler of me then
         put tLineNumber into tMatchingLineNumber
         exit repeat
      end if
      add 1 to tLineNumber
   end repeat
      
   if tMatchingLineNumber is empty then
      select line 1 of field "Handlers" of me
   else
      select line tMatchingLineNumber of field "Handlers" of me
   end if
   unlock screen
end initialize

command initializeWithoutGrabbingFocus
   update
   updateSelectedHandler
end initializeWithoutGrabbingFocus

command updateSelectedHandler
   if the cSelectedHandler of me is empty then
      set the hilitedLines of field "Handlers" of me to empty
      exit updateSelectedHandler
   end if
   
   local tLineNumber
   put 1 into tLineNumber
   
   local tMatchingLineNumber
   repeat for each line tHandler in the cHandlers of field "Handlers" of me
      if word 2 of tHandler is the cSelectedHandler of me then
         put tLineNumber into tMatchingLineNumber
         exit repeat
      end if
      add 1 to tLineNumber
   end repeat
   
   if tMatchingLineNumber is empty then
      set the hilitedLines of field "Handlers" of me to empty
   else
      set the hilitedLines of field "Handlers" of me to tMatchingLineNumber
   end if
end updateSelectedHandler

# Parameters
#   pTag : A single letter tag that refers to certain property of a handler
#   Possible values:
#     C - command
#     M - message
#     F - function
#     G - getProp
#     S - setprop
#     B - before
#     A - after
#   pIsPrivate : whether or not the handler is private (commands and functions only)
# Returns
#   The id of a suitable image to represent the property pTag of a handler. Note: this function
#   may return empty if no image is required to represent this.
private function getIcon pTag, pIsPrivate
   local tTag
   put "handler" into tTag
   
   if pIsPrivate then
      put "Private" after tTag
   end if
   
   switch pTag
      case "C"
         put "Command" after tTag
         break
      case "M"
         put "Message" after tTag
         break
      case "F"
         put "Function" after tTag
         break
      case "G"
         put "Getprop" after tTag
         break
      case "S"
         put "Setprop" after tTag
         break
      case "B"
         put "Before" after tTag
         break
      case "A"
         put "After" after tTag
         break
   end switch
   
   return seGetIcon(tTag)
end getIcon

function handlerTypeSortCallback pItem
   switch pItem
      case "F"
         return 1
         break
      case "PF"
         return 2
         break
      case "M"
         return 3
         break
      case "PM"
         return 4
         break
      case "G"
         return 5
         break
      case "S"
         return 6
         break
      default 
         return 7
   end switch
end handlerTypeSortCallback

constant kDefaultHandlerTextColor = "#777777"

# Description
#   Called when the group might need to be updated. Updates the handler list. Also resizes the group.
command update
   lock screen
   local tHandlers
   call "revSEGetHandlerList" to the cCaller of me
   put the result into tHandlers
   
   local tDefaultHandlers, tIndex
   if sePrefGet("editor,showDefaultHandlers") then
      put revSEDefaultHandlers() into tDefaultHandlers
   end if
   set the wholematches to false
   
   local tCanAdd
   repeat for each line tLine in tDefaultHandlers
      if lineOffset(tLine, tHandlers) is not 0 then
         next repeat
      end if
      if tCanAdd is empty then
         put tLine into tCanAdd
      else
         put return & tLine after tCanAdd
      end if
   end repeat
   
   filterHandlerNames tHandlers
   
   if sePrefGet("editor,sortHandlerList") is "alphabetical" then
      sort tHandlers by word 2 of each
   else if sePrefGet("editor,sortHandlerList") is "order-of-appearence" then
      # OK-2008-07-21 : Bug 6805 - Sort the handlers by their line number
      sort tHandlers numeric by word 3 of each
   else
      # OK-2009-03-03 : Bug 7690 - We could change this in the engine, but considering that in the default
      # settings we sort alphabetically anyway, it probably doesn't make much difference to just sort here.
      # This will produce an ordering F, G, H, PF, PH, S, which may need to be adjusted using a custom search
      # function here.
      sort tHandlers by handlerTypeSortCallback(word 1 of each) & word 2 of each
   end if
   
   if tHandlers is not empty then
      put return & return & return after tHandlers
   end if
   put tCanAdd after tHandlers
   
   # Populate the handlers field with the formatted list of handlers
   local tText, tIcon
   repeat for each line tHandler in tHandlers
      local tParseHandler, tHandlerExists
      put true into tHandlerExists
      put word 1 to 2 of tHandler into tParseHandler
      
      if the number of words in tHandler is 1 then
         put false into tHandlerExists
         -- Existing handler names have a space after the icon
         put " " before tParseHandler
      end if
      
      put "<p>" after tText
      
      local tIsPrivate
      put false into tIsPrivate
      if tHandlerExists and char 1 of tParseHandler is "P" then
         put true into tIsPrivate
         delete char 1 of tParseHandler
      end if
      
      if tHandlerExists then
         put getIcon(char 1 of tParseHandler, tIsPrivate) into tIcon
         if tIcon is not empty then
            delete char 1 of tParseHandler
         end if
      else
         put the id of image "icon-add.png" of stack "revIcons" into tIcon
      end if
      
      if tIcon is not empty then
         put merge("<sup shift=2><img src=[[tICon]]></img></sup>") after tText
      end if
      
      if not tHandlerExists then
         put merge("<font color='[[kDefaultHandlerTextColor]]'>[[tParseHandler]]</font>") \
               into tParseHandler
      end if
      
      put tParseHandler & "</p>" after tText
   end repeat
   
   if tText is empty then
      put "<p></p>" into tText
   end if
   
   # OK-2008-08-18: Bug 6936 - The handler list object should take its text size from the main script editor preference.
   set the textSize of field "Handlers" of me to sePrefGet("editor,fontsize")
   set the textFont of field "Handlers" of me to sePrefGet("editor,font")
   
   set the htmlText of field "Handlers" of me to tText
   set the cHandlers of field "Handlers" of me to tHandlers
   
   # Shrink or grow the stack if the handlers list doesn't fit, but don't let it become bigger than its maxHeight or maxWidth.
   if the formattedHeight of field "Handlers" of me > the cMaxHeight of me then
      set the height of field "Handlers" of me to the cMaxHeight of me
   else if the formattedHeight of field "Handlers" of me < the cMinHeight of me then
      set the height of field "Handlers" of me to the cMinHeight of me
   else
      set the height of field "Handlers" of me to the formattedHeight of field "Handlers" of me
   end if
   
   if the formattedWidth of field "Handlers" of me > the cMaxWidth of me then
      set the width of field "Handlers" of me to the cMaxWidth of me
   else if the formattedWidth of field "Handlers" of me < the cMinWidth of me then
      set the width of field "Handlers" of me to the cMinWidth of me
   else
      set the width of field "Handlers" of me to the formattedWidth of field "Handlers" of me
   end if
   
   # The topLeft of the group will be set by whatever invokes it, so we have to restore this after
   # we have changed the width and height.
   local tOldTopRight
   put the topRight of me into tOldTopRight
   
   set the vScrollbar of field "Handlers" of me to (the formattedHeight of field "Handlers" of me > the height of field "Handlers" of me)
   set the width of me to the width of field "Handlers" of me
   set the height of me to the height of field "Handlers" of me
   set the topLeft of field "Handlers" of me to the topLeft of me
   set the topRight of me to tOldTopRight
   unlock screen
end update

# Description
#   Called when the group is being resized after already being initialized
command resize
   lock screen
   set the rect of field "Handlers" of me to the rect of me
   unlock screen
end resize

command jumpToHandler pHandler, pAdded
   local tLineNumber
   put word 3 of pHandler into tLineNumber
   
   # OK-2009-03-03: Bug 7450 - Also return the handler type, this will allow us to detect 
   # if the handler line number is wrong (due to uncompiling script). 
   set the cChoice of me to tLineNumber & comma & word 2 of pHandler & comma & word 1 of pHandler
   
   if the cCallback of me is not empty then
      send the cCallback of me && pAdded to the cCallbackTarget of me
   end if
   
   hideGroup
end jumpToHandler

command handlerPicked pHandler
   local tAdded
   put false into tAdded
   if the number of words in pHandler is 1 then
      put true into tAdded
      -- Adding a default handler
      revSEAddDefaultHandler pHandler
      update
      set the wholematches to false
      local tLine
      put lineOffset(pHandler, the cHandlers of field "Handlers" of me) into tLine
      select line tLine of field "Handlers" of me
      put line tLine of the cHandlers of field "Handlers" of me into pHandler
   end if
   
   -- Select the (now) extant handler
   jumpToHandler pHandler, tAdded
end handlerPicked

command closeAccept
   lock screen
   local tHandler
   put line (the hilitedLine of field "Handlers" of me) of the cHandlers of field "Handlers" of me into tHandler
   handlerPicked tHandler
   unlock screen
end closeAccept

command closeReject
   lock screen
   set the cChoice of me to empty
   if the cCallback of me is not empty then
      send the cCallback of me to the cCallbackTarget of me
   end if
   
   hideGroup
   unlock screen
end closeReject

private command hideGroup
   seHideHandlerList
end hideGroup

on mouseMove
   local tLineNumber
   put word 2 of the mouseLine into tLineNumber
   
   local tVisibleWidth
   if the vScrollbar of field "Handlers" of me then
      put the width of field "Handlers" of me - the scrollbarWidth of field "Handlers" of me into tVisibleWidth
   else
      put the width of field "Handlers" of me into tVisibleWidth
   end if
   subtract the leftMargin of field "Handlers" of me from tVisibleWidth
   subtract the rightMargin of field "Handlers" of me from tVisibleWidth
   
   if the formattedWidth of line tLineNumber of field "Handlers" of me >= tVisibleWidth then
      set the toolTip of field "Handlers" of me to line (word 2 of the mouseLine) of the text of field "Handlers" of me
   else
      set the toolTip of field "Handlers" of me to empty
   end if
end mouseMove

----------------------------------------------------------------
-- Handler filtering support
----------------------------------------------------------------

/*
The list of handlers can be filtered by a string, stored in the custom
property cFilterText.  If cFilterText is non-empty, only handlers that
match *all* the words of cFilterText are shown.

The filterChanged handler updates the cFilterText custom property, and
updates the display if necessary.
*/

-- This is called to update the filter text
on filterChanged pFilterText
   if pFilterText is not the cFilterText of me then
      set the cFilterText of me to pFilterText
      send "filterUpdate" to me in 0 millisecs
   end if
end filterChanged

-- Update the handler list due to a change in the handler list filter
-- string.  Make sure that the currently selected handler gets reselected,
-- if it's not excluded by the filter.
command filterUpdate
   send "update" to me
   send "updateSelectedHandler" to me
end filterUpdate

-- Process a list of handler information lines, replacing it with a list
-- containing only the handlers where the name matches the current filter.
private command filterHandlerNames @xHandlers
   if the cFilterText of me is empty then
      exit filterHandlerNames
   end if

   local tNewHandlers, tHandler, tName, tWord, tMatch

   repeat for each line tHandler in xHandlers
      put true into tMatch

      -- The first word of each line of the handler list is a tag that
      -- describes the type of handler (e.g. "PH" for private handler,
      -- etc.)  The second word is the handler's name.
      put word 2 of tHandler into tName

      -- The handler name needs to match *all* of the words in the
      -- filter text
      repeat for each word tWord in the cFilterText of me
         if not (tName contains tWord) then
            put false into tMatch
            exit repeat
         end if
      end repeat

      if tMatch then
         put tHandler & return after tNewHandlers
      end if
   end repeat

   put tNewHandlers into xHandlers
end filterHandlerNames
