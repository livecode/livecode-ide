script "revCoreStackBehavior"
################################################################
# Reading object properties used to the project browser and application browser
# There are two variations. Each wants slightly different properties so for 
# optimisations sake we've implemented two functions
################################################################
function idePropertyInspectorReadProperties pList
   local tProps, tPropGetScript
   // Get the core properties
   repeat for each line tProp in pList
      if tProp is "allcustomproperties" then
         local tCustomPropertySets, tCustomProperties
         set the custompropertyset of the target to empty
         put the customproperties of the target into tCustomProperties["default"]
         
         put the custompropertysets of the target into tCustomPropertySets
         
         repeat for each line tCustomPropertySet in tCustomPropertySets
            put the customproperties[tCustomPropertySet] of the target into tCustomProperties[tCustomPropertySet]
         end repeat
         put tCustomProperties into tProps["allcustomproperties"]
      else if tProp contains "dgProp" then
         // This is a dataGrid property
         put "get the" && tProp && "of" && the target into tPropGetScript
         try
            do tPropGetScript
            put the result into tProps[tProp]
         end try
      else
         try
            put the tProp of the target into tProps[tProp]
         end try
      end if
   end repeat
   
   put the short name of the target into tProps["name"]
   
   return tProps
end idePropertyInspectorReadProperties

function ideProjectBrowserReadProperties pList
   local tProps, tScriptLines, tLabel, tTarget
   // Get the core properties
   local tLongID, tShortName, tCard
   
   put the long id of the target into tLongID
   put the short name of the target into tShortName
   put ideCoreCardOfControl(tLongID) into tCard
   
   repeat for each line tProp in pList
      if tProp is "type" then
         put word 1 of the name of the Target into tProps["type"]
      else if tProp is "script_lines" then
         try
            put the num of lines in the script of the Target into tScriptLines
         catch tError
            put "pwd" into tScriptLines
         end try
         put tScriptLines into tProps["script_lines"]
      else if tProp is "label" then
         if word 1 of the name of the Target is "button" then
            put the label of the Target into tLabel
            replace return with space in tLabel
         else
            put empty into tLabel
         end if 
         put tLabel into tProps["label"]
      else if tProp is "custom Control" then
         if the the cIDEProperties["cCustomControl"] of the Target is "true" then
            put "true" into tProps["custom Control"]
         else if the dgProp["control type"] of the target is "Data Grid" then
            put "true" into tProps["custom Control"]            
         else
            put "false" into tProps["custom Control"]
         end if
      else if tProp is "behavior_control" then
         if the behavior of the Target is not empty then
            put the behavior of the Target into tProps["behavior_control"]
         else
            put empty into tProps["behavior_control"]
         end if
      else if tProp is "behavior_script_lines" then
         if the behavior of the Target is not empty then
            if exists(the behavior of the Target) then
               try
                  put the num of lines in the script of the behavior of the Target into tProps["behavior_script_lines"]
               catch pError
                  put "pwd" into tProps["behavior_script_lines"]
               end try
            else
               put "object missing" into tProps["behavior_script_lines"]
            end if
         end if  
      else if tProp is "long id" then
         put the long id of the target into tProps["long id"]
      else if tProp is "owner" then
         put the long id of the owner of the target into tProps["owner"]
      else
         try
            put the tProp of the Target into tProps[tProp]
         end try
      end if
   end repeat
   
   put the short name of the Target into tProps["name"]   
   return tProps
end ideProjectBrowserReadProperties

function ideProjectBrowserReadStackProperties pList
   local tProps
   // Get the core properties   
   repeat for each line tProp in pList
      if tProp is "type" then
         if the mainStack of the target is the short name of the target then      
            put "mainstack" into tProps["type"]
         else
            put "substack" into tProps["type"]
         end if
      else if tProp is "script_lines" then
         try
            put the num of lines in the script of the target into tProps["script_lines"]
         catch tError
            put "pwd" into tProps["script_lines"]
         end try
      else if tProp is "behavior_script_lines" then
         if the behavior of the target is not empty then
            if there is a (the behavior of the target) then
               try
                  put the num of lines in the script of the behavior of the target into tProps["behavior_script_lines"]
               catch tError
                  put "pwd" into tProps["behavior_script_lines"]
               end try
            end if
         end if
      else if tProp is "behavior_control" then
         if the behavior of the target is not empty then
            if there is a (the behavior of the target) then
               try
                  put the behavior of the target into tProps["behavior_control"]
               catch tError
                  put "pwd" into tProps["behavior_control"]
               end try
            end if
         end if
      else
         try
            put the tProp of the Target into tProps[tProp]
         end try
      end if
   end repeat
   return tProps   
end ideProjectBrowserReadStackProperties

function ideProjectBrowserReadCardProperties pList
   local tProps
   // Get the core properties   
   repeat for each line tProp in pList
      if tProp is "name" then
         put the short name of the target into tProps["name"]
      else if tProp is "number" then
         put the number of the target into tProps["number"]
      else if tProp is "script_lines" then
         try
            put the num of lines in the script of the target into tProps["script_lines"]
         catch tError
            put "pwd" into tProps["script_lines"]
         end try
      else if tProp is "behavior_script_lines" then
         if the behavior of the target is not empty then
            if there is a (the behavior of the target) then
               try
                  put the num of lines in the script of the behavior of the target into tProps["behavior_script_lines"]
               catch tError
                  put "pwd" into tProps["behavior_script_lines"]
               end try
            end if
         end if
      else if tProp is "behavior control" then
         if the behavior of the target is not empty then
            if there is a (the behavior of the target) then
               try
                  put the behavior of the target into tProps["behavior_control"]
               catch tError
                  put "pwd" into tProps["behavior_control"]
               end try
            end if
         end if
      else
         try
            put the tProp of the Target into tProps[tProp]
         end try
      end if
   end repeat
   return tProps   
end ideProjectBrowserReadCardProperties

################################################################
# DEBUGGING AND PERFORMANCE LOGGING
################################################################
global gRevDevelopment
local sLog
on ideTimingLogStart pSource
   if gRevDevelopment is true then
      if pSource is empty then 
         put ideTimingLogSourceStackNameGet() into pSource
      end if
      
      put the milliseconds into sLog[pSource]["start"]
      put empty into sLog[pSource]["log"]
      put empty into sLog[pSource]["lasttime"]
      put empty into sLog[pSource]["logtime"]
   end if
end ideTimingLogStart

on ideTimingLogClearAll
   put empty into sLog
end ideTimingLogClearAll

on ideTimingLog pMessage, pSource
   if gRevDevelopment is true then
      if pSource is empty then 
         put ideTimingLogSourceStackNameGet() into pSource
      end if
      
      if sLog[pSource]["start"] is empty then ideTimingLogStart pSource
      
      put the milliseconds into sLog[pSource]["logtime"]
      
      local tTime
      put sLog[pSource]["logtime"] - sLog[pSource]["start"] into tTime
      put tTime &&  " ("&tTime-sLog[pSource]["lasttime"]&") |" && pMessage & return  after sLog[pSource]["log"]
      put tTime into sLog[pSource]["lasttime"]
   end if
end ideTimingLog

local sLastDisplayTime
on ideTimingLogDisplay 
   if gRevDevelopment is true then
      local tDisplay
      repeat for each key tKey in sLog
         put "#############" && tKey && "##############" & return after tDisplay
         put "Log shown at -" & the milliseconds && "milliseconds" & return after tDisplay
         put "TOTAL TIME - " && sLog[tKey]["logtime"] - sLog[tKey]["start"] & return after tDisplay
         put sLog[tKey]["log"] & return after tDisplay
      end repeat
      
      put tDisplay into msg
   end if
end ideTimingLogDisplay

function ideTimingLogSourceStackNameGet
   if gRevDevelopment is true then
      local tLongName, tExecutionContexts
      
      put the long name of me into tLongName
      put the executioncontexts into tExecutionContexts
      
      local tExecutionLine
      repeat with x = the number of lines of tExecutionContexts down to 1
         put line x of tExecutionContexts into tExecutionLine 
         put item 1 of tExecutionLine into tExecutionLine
         if tExecutionLine is not tLongName then
            delete the last char of tExecutionLine
            set the itemdel to "/"
            put the last item of tExecutionLine into tExecutionLine
            set the itemdel to ","
            exit repeat
         end if
      end repeat
      
      return tExecutionLine
   end if
end ideTimingLogSourceStackNameGet

################################################################
# GENERAL IDE COMMANDS AND FUNCTIONS
################################################################

// Returns the long ID of the card for a given long ID of an object
function ideCoreCardOfcontrol pLongID
   local tCardWord
   put wordOffset("card",pLongID) into tCardWord
   return word tCardWord to -1 of pLongID
end ideCoreCardOfcontrol

function ideCoreParentOfControl pLongID
   local tCardWord
   put wordOffset("card",pLongID) into tCardWord
   return word tCardWord to -1 of pLongID
end ideCoreParentOfControl

function ideCoreStackIsIDE pLongID
   return revIDEStackNameIsIDEStack(the filename of pLongID)
end ideCoreStackIsIDE

################################################################
# CONTROL ALIGNMENT COMMANDS AND FUNCTIONS
################################################################
command ideCoreAlignObjects pPosition, pObjectList
   local tPositionValue, tInitialObject, tSetLine, tCurrentLoc
   
   if pObjectList is empty then put the selectedObjects into pObjectList
   
   put line 1 of pObjectList into tInitialObject
   
   lock screen
   repeat with x = 1 to the number of lines in pObjectList
      get line x of pObjectList
      switch pPosition
         case "alignLeft"
            put value("the left of me",tInitialObject) into tPositionValue   
            set the left of it to tPositionValue
            break
         case "alignTop"
            put value("the top of me",tInitialObject) into tPositionValue   
            set the top of it to tPositionValue
            break
         case "alignRight"
            put value("the right of me",tInitialObject) into tPositionValue   
            set the right of it to tPositionValue
            break
         case "alignBottom"
            put value("the bottom of me",tInitialObject) into tPositionValue   
            set the bottom of it to tPositionValue
            break
         case "alignHorizontalCenter"
            put value("the loc of me",tInitialObject) into tPositionValue 
            delete item 2 of   tPositionValue
            put the loc of it into tCurrentLoc
            set the loc of it to tPositionValue,item 2 of tCurrentLoc
            break
         case "alignVerticalCenter"
            put value("the loc of me",tInitialObject) into tPositionValue 
            delete item 1 of   tPositionValue
            put the loc of it into tCurrentLoc
            set the loc of it to item 1 of tCurrentLoc,tPositionValue
            break
      end switch
      --put "set the" && pPosition && "of" && line x of pObjectList && "to" && tPositionValue into tSetLine
      --do tSetLine
   end repeat
   unlock screen
end ideCoreAlignObjects

command ideCoreEqualizeObjects pPosition, pObjectList
   local tPositionValue, tInitialObject, tSetLine, tCurrentLoc
   
   if pObjectList is empty then put the selectedObjects into pObjectList
   put line 1 of pObjectList into tInitialObject
   
   lock screen
   repeat with x = 1 to the number of lines in pObjectList
      get line x of pObjectList
      switch pPosition
         case "equalizeWidth"
            put value("the width of me",tInitialObject) into tPositionValue   
            set the width of it to tPositionValue
            break
         case "equalizeHeight"
            put value("the height of me",tInitialObject) into tPositionValue   
            set the height of it to tPositionValue
            break
         case "equalizeWidthHeight"
            put value("the width of me",tInitialObject) into tPositionValue   
            set the width of it to tPositionValue
            put value("the height of me",tInitialObject) into tPositionValue   
            set the height of it to tPositionValue
            break
      end switch
   end repeat
   unlock screen
end ideCoreEqualizeObjects

command ideCoreDistributeObjects pDirection, pDistribution, pObjectList
   local tStack, tLeft, tRight, tTop,tBottom, tTotalWidth, tTotalHeight, tSpacing
   local tAvailableWidth, tAvailableHeight
   local tOrderedObjectList
   
   if pObjectList is empty then put the selectedObjects into pObjectList
   
   put word -2 to -1 of line 1 of pObjectList into tStack
   put the width of tStack into tLeft
   put the height of tStack into tTop
   put 0 into tRight
   put 0 into tBottom
   repeat with x = 1 to the number of lines in pObjectList
      get line x of pObjectList
      if the left of it < tLeft then put the left of it into tLeft
      if the top of it < tTop then put the top of it into tTop
      if the right of it > tRight then put the right of it into tRight
      if the bottom of it > tBottom then put the bottom of it into tBottom
      add the width of it to tTotalWidth
      add the height of it to tTotalHeight
      
      put it & comma & the left of it & comma & the top of it & return after tOrderedObjectList
   end repeat
   
   if pDirection is "distributeHorizontal" then
      switch pDistribution
         case "First To Last selected"
            sort lines of tOrderedObjectList by item 2 of each
            put tRight-tLeft into tAvailableWidth
            put ((tAvailableWidth-tTotalWidth)/number of lines in pObjectList) div 1 into tSpacing
            break
         case "Edge To Edge"
            sort lines of tOrderedObjectList by item 2 of each
            put 0 into tSpacing
            break
         case "Across Card"
            sort lines of tOrderedObjectList by item 2 of each
            put the width of tStack into tAvailableWidth
            put ((tAvailableWidth-tTotalWidth)/(the number of lines in pObjectList+1)) div 1 into tSpacing
            put tSpacing into tLeft
            break
      end switch
      repeat with x = 1 to the number of lines in tOrderedObjectList
         get item 1 of line x of pObjectList
         set the left of it to tLeft
         add the width of it + tSpacing to tLeft
      end repeat      
   else if pDirection is "distributeVertical" then
      switch pDistribution
         case "First To Last selected"
            sort lines of tOrderedObjectList by item 3 of each
            put tBottom-tTop into tAvailableHeight
            put ((tAvailableHeight-tTotalHeight)/number of lines in pObjectList) div 1 into tSpacing
            break
         case "Edge To Edge"
            sort lines of tOrderedObjectList by item 3 of each
            put 0 into tSpacing
            break
         case "Across Card"
            sort lines of tOrderedObjectList by item 3 of each
            put the height of tStack into tAvailableHeight
            put ((tAvailableHeight-tTotalHeight)/(the number of lines in pObjectList+1)) div 1 into tSpacing
            put tSpacing into tTop
            break
      end switch
      repeat with x = 1 to the number of lines in tOrderedObjectList
         get item 1 of line x of pObjectList
         set the top of it to tTop
         add the height of it + tSpacing to tTop
      end repeat   
   end if
end ideCoreDistributeObjects

// Button display
command ideCoreSetHover pControl, pValue, pType
   if not the disabled of pControl then
      if pValue then
         if pType is "foreground" then
            set the colorOverlay["color"] of pControl to ideColorGet("state_hover")
         else
            set the opaque of pControl to true
            set the backgroundColor of pControl to ideColorGet("state_hover")
         end if
      else
         if pType is "foreground" then
            set the colorOverlay of pControl to empty
         else
            set the opaque of pControl to false
            set the backgroundColor of pControl to empty
         end if
      end if
   end if
end ideCoreSetHover

command ideCoreSetDisabled pControl, pValue
   set the disabled of pControl to pValue
   if pValue then
      set the colorOverlay["opacity"] of pControl to 200
      set the colorOverlay["color"] of pControl to ideColorGet("state_disabled")
   else
      set the colorOverlay of pControl to empty
   end if   
end ideCoreSetDisabled

function ideCoreButtonDefaultStateDataGet
   return "normal,foreground" & return & "hover,background" & return & "pressed,background" & return & "disabled,foreground" & return & "selected,background"
end ideCoreButtonDefaultStateDataGet

function ideCoreButtonForegroundStateDataGet
   return "normal,foreground" & return & "hover,foreground" & return & "pressed,foreground" & return & "disabled,foreground" & return & "selected,foreground" & return & "booleanTrue,foreground" & return & "booleanFalse,foreground" 
end ideCoreButtonForegroundStateDataGet

// Comparison functions
function ideCoreCompareValues pValue1, pValue2
   local tValue1Array, tValue2Array
   
   if the keys of pValue1 is empty then
      put false into tValue1Array
   else
      put true into tValue1Array
   end if
   
   if the keys of pValue2 is empty then
      put false into tValue2Array
   else
      put true into tValue2Array
   end if
   
   if not tValue1Array and not tValue2Array then
      if pValue1 is pValue2 then
         return true
      else
         return false
      end if
   else if tValue1Array and tValue2Array then
      // Compare the 2 arrays
      return ideCoreCompareArrays(pValue1, pValue2)
   else
      // 1 array, 1 non array
      return false
   end if
end ideCoreCompareValues

function ideCoreCompareArrays pArray1, pArray2
   if the keys of pArray1 is not the keys of pArray2 then
      return false
   else
      repeat for each key tKey in pArray1
         if pArray1[tKey] is not pArray2[tKey] then
            return false
         end if
      end repeat
      return true
   end if
end ideCoreCompareArrays

// Preferences
on ideTextSizeSet pSize
   if pSize is empty then
      set the cIDETextSize of stack "revPreferences" to empty
   else
      set the cIDETextSize of stack "revPreferences" to pSize
   end if
   ideCoreUpdateTextFontSize
end ideTextSizeSet

function ideTextSizeGet
   local tTextSize
   
   put  the cIDETextSize of stack "revPreferences" into tTextSize
   if tTextSize is empty then
      return empty
   else
      return  the cIDETextSize of stack "revPreferences"
   end if   
end ideTextSizeGet

on ideProjectBrowserThumbnailsHeightSet pSize
   if pSize is empty then
      set the cIDEThumbnailHeight of stack "revPreferences" to 50
   else
      set the cIDEThumbnailHeight of stack "revPreferences" to pSize
   end if
   send "ideRefresh" to stack "revIDEProjectBrowser"
end ideProjectBrowserThumbnailsHeightSet

function ideProjectBrowserThumbnailsHeightGet
   local tSize
   
   put  the cIDEThumbnailHeight of stack "revPreferences" into tSize
   if tSize is empty then
      return 50
   else
      return tSize
   end if
end ideProjectBrowserThumbnailsHeightGet

on ideProjectBrowserThumbnailsWidthSet pSize
   if pSize is empty then
      set the cIDEThumbnailWidth of stack "revPreferences" to 50
   else
      set the cIDEThumbnailWidth of stack "revPreferences" to pSize
   end if
   send "ideRefresh" to stack "revIDEProjectBrowser"
end ideProjectBrowserThumbnailsWidthSet

function ideProjectBrowserThumbnailsWidthGet
   local tSize
   
   put  the cIDEThumbnailWidth of stack "revPreferences" into tSize
   if tSize is empty then
      return 50
   else
      return tSize
   end if
end ideProjectBrowserThumbnailsWidthGet

on ideTextFontSet pFont
   if pFont is empty then
      set the cIDETextFont of stack "revPreferences" to empty
   else
      set the cIDETextFont of stack "revPreferences" to pFont
   end if
   ideCoreUpdateTextFontSize
end ideTextFontSet pFont

function ideTextFontGet
   local tTextFont
   
   put  the cIDETextFont of stack "revPreferences" into tTextFont
   if tTextFont is empty then
      return empty
   else
      return  the cIDETextFont of stack "revPreferences"
   end if
end ideTextFontGet

function ideTextFontOptions
   local tFonts
   put the fontNames into tFonts
   sort lines of tFonts
   put "empty" & return before tFonts
   return tFonts
end ideTextFontOptions

on ideCoreUpdateTextFontSize   
   // Temp
   lock messages
   lock screen
   
   set the textFont of stack "revIDEProjectBrowser" to ideTextFontGet()
   set the textSize of stack "revIDEProjectBrowser" to ideTextSizeGet()
   
   unlock messages
   unlock screen
end ideCoreUpdateTextFontSize

function  ideCoreTrim pText
   local tTrimmedText
   repeat with x = 1 to the number of characters of pText
      if char x of pText is not space and char x of pText is not ":" then
         put char x of pText after tTrimmedText
      end if
   end repeat
   return tTrimmedText
end ideCoreTrim

function ideColorGet pTag
   switch pTag
      case "state_disabled"
         return "208,208,208"
         break
      case "palette_background"
      case "toolbar_background"
         return "236,236,236"
         break
      case "palette_background_muted"
      case "state_normal_foreground"
      case "state_hover_foreground"
      case "state_pressed_foreground"
      case "state_selected_foreground"
      case "state_disabled_foreground"
      case "state_booleanTrue_foreground"
      case "state_booleanFalse_foreground"
      case "border_muted_hilite"
      case "pb_line_border_left_hilite"
      case "pb_script_lines_text"
      case "pb_script_lines_text_hover"
      case "pb_behavior_script_lines_text"
      case "pb_behavior_script_lines_text_hover"
      case "pb_edit_field_bg"
      case "border_hilite"
      case "pb_line_background"
         return "255,255,255"
         break
      case "state_normal"
      case "pb_disclosure_arrow"
         return "129,129,129"
         break
      case "state_hover"
      case "hilite_above"
      case "pb_script_lines_hover"
      case "pb_behavior_script_lines_hover"
      case "pb_drag_hilite_top"
         return "0,72,204"
         break
      case "state_pressed"
      case "hilite_below"
      case "pb_drag_hilite_bottom"
         return "192,0,204"
         break
      case "state_selected"
      case "pb_script_lines"
      case "pb_behavior_script_lines"
         return "0,195,255"
         break
      case "pb_no_script_lines"
         return "157,233,255"
         break
      case "state_booleanTrue"
         return "100,100,100"
         break
      case "state_booleanFalse"
         return "182,182,182"
         break
      case "state_muted_pressed"
         return "231,22,255"
         break
      case "state_muted_selected"
      case "pb_line_selected"
         return revEnvironmentEditionProperty("pb_line_selected_color")
         break
      case "state_muted_disabled"
      case "hilite_center"
      case "pb_drag_hilite_center"
      case "pb_line_selected_hover"
         return "255,211,211"
         break
      case "state_muted_selected_secondary"
      case "pb_line_selected_trail"
         return "244,244,244"
         break         
      case "border"
      case "pb_list_bottom_border"
      case "pb_edit_field_border"
      case "pb_line_border_left"
         return "225,225,225"
         break
      case "border_muted"
      case "pb_line_border_bottom"
         return "234,234,234"
         break        
      case "text"
         return "0,0,0"
         break
      case "text_muted"
         return "95,95,95"
         break
      case "pb_palette_background"
      case "pb_line_show_select_background"
         return "236,236,236"
         break
   end switch
end ideColorGet

## array printer
on revPutArray pArray
   
   if (the keys of pArray) is empty then
      put "not an array"
      exit revPutArray
   end if
   
   local pLevel, pCounter, pList
   
   put 0 into pLevel
   put 0 into pCounter
   put empty into pList
   
   put dumpArrayRecurse(pArray, pLevel, pCounter, pList) into pList
   
   put pList
end revPutArray

private function dumpArrayRecurse pArray, pLevel, @pCounter, @pList
   local tOrderedKeys
   put the keys of pArray into tOrderedKeys
   sort lines of tOrderedKeys numeric
   repeat for each line tKey in tOrderedKeys
      
      add 1 to pCounter
      
      repeat for pLevel
         put tab after line pCounter of pList
      end repeat
      put (tKey && "= ") after line pCounter of pList
      
      if (the keys of pArray[tKey]) is empty then
         put line 1 of pArray[tKey] after line pCounter of pList
      else
         put dumpArrayRecurse(pArray[tKey], (pLevel + 1), pCounter, pList) into pList
      end if
      
   end repeat
   
   return pList
   
end dumpArrayRecurse


function ideCoreFolderPath pFolder, pFileName
   local tPath
   put revEnvironmentEditionProperty("folder") & "/" & pFolder & "/" & pFileName into tPath
   if there is a file tPath or there is a folder tPath then
      return tPath
   end if
   
   put revEnvironmentToolsetPath() & "/resources/" & pFolder & "/" & pFileName into tPath
   if there is a file tPath or there is a folder tPath then
      return tPath
   end if
end ideCoreFolderPath

function ideCoreEditionHoverColour
   return "147,179,39"
end ideCoreEditionHoverColour

on ideCoreShowTip pStack,pCard,pName,pRect,pMessage, pLink
   //Copy the template group
   if there is a group pName of card pCard of stack pStack then
      delete group pName of card pCard of stack pStack
   end if
   copy group "tip_display_template" of card 1 of stack "revCore" to card pCard of stack pStack
   
   set the name of it to pName
   set the lockLoc of it to true   
   set the rect of it to pRect
   set the behavior of it to the long id of button "tip_display_behavior" of card 1 of stack "revCore"
   put pMessage into field "tip_message" of it
   set the cLink of it to pLink
   send "layoutTip" to it
end ideCoreShowTip
