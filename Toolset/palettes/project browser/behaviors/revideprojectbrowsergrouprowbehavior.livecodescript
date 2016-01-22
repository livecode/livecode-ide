script "revIDEProjectBrowserGroupRowBehavior"
on FillInData pDataA, pRow
   # Map pDataA values to physical controls...
   
   set the cRowNumber of me to pRow
   set the cIndent of me to pDataA["level"]-1
   set the cObjectLongID of me to pDataA["long id"]
   set the cBehaviorLongID of me to pDataA["behavior"]
   set the cLevelConnectors of me to pDataA["levels"]
   
   put pDataA["type"] & ":" into field "type" of me
   put pDataA["name"] into field "name" of me
   set the tooltip of field "name" of me to pDataA["long id"]
   
   set the backgroundColor of graphic "background" of me to empty
   
   if pDataA["scriptlines"] is 0 or pDataA["scriptlines"] is empty then
      put 0 into field "scriptLines" of me
   else
      put pDataA["scriptlines"] into field "scriptLines" of me
   end if 
   
   if pDataA["behavior scriptlines"] is empty then
      hide field "behaviorScriptLines" of me
      put "-" into field "behaviorScriptLines" of me
      set the tooltip of field "behaviorScriptLines" of me to "This control does not have an associated behavior"
   else
      show field "behaviorScriptLines" of me
      put pDataA["behavior scriptlines"] into field "behaviorScriptLines" of me
      set the tooltip of field "behaviorScriptLines" of me to pDataA["behavior"]
   end if 
   
   if pDataA["childCount"] is empty or pDataA["childCount"] is 0  then 
      set the disabledicon of button "disclosure" of me to the id of image "cantExpand" of card "templates" of this stack
      disable button "disclosure" of me 
   else
      if pDataA["expanded"] is true then
         set the icon of button "disclosure" of me to the id of image "childExpanded" of card "templates" of this stack
      else
         set the icon of button "disclosure" of me to the id of image "childContracted" of card "templates" of this stack
      end if
      enable button "disclosure" of me 
   end if
   
   ## Visibility
   if pDataA["visible"] is true then
      set the icon of button "visible" of me to the id of image "visible_on" of card "templates" of this stack
      set the tooltip of button "visible" of me to "Hide"
   else if pDataA["visible"] is false then
      set the icon of button "visible" of me to the id of image "visible_off" of card "templates" of this stack
      set the tooltip of button "visible" of me to "Show"
   end if  
   
   ## Can't select
   if pDataA["cantSelect"] is true then
      set the icon of button "cantSelect" of me to the id of image "cantSelect_on" of card "templates" of this stack
      set the tooltip of button "cantSelect" of me to "Hide"
   else if pDataA["cantSelect"] is false then
      set the icon of button "cantSelect" of me to the id of image "cantSelect_off" of card "templates" of this stack
      set the tooltip of button "cantSelect" of me to "Show"
   end if  
   
   if revIDEGetPreference("ideProjectBrowser_objectType") is "text" then
      show field "type" of me
      hide image "groupIcon" of me
   else
      hide field "type" of me
      show image "groupIcon" of me
   end if
end FillInData


on LayoutControl pControlRect
   local tLevelConnectors, tConnectorCount, tLoc
   
   put item 1 of the loc of me & comma & item 2 of the loc me -1 into tLoc
   put the cLevelConnectors of me into tLevelConnectors
   put the number of lines in the keys of tLevelConnectors into tConnectorCount
   # Resize controls/row   
   set the rect of graphic "background" of me to pControlRect
   set the width of graphic "bottom_border" of me to (item 3 of pControlRect - item 1 of pControlRect)+2
   set the bottomLeft of graphic "bottom_border" of me to item 1 of pControlRect-1, item 4 of pControlRect
   
   set the width of field "scriptLines" of me to the formattedWidth of field "scriptLines" of me 
   set the width of field "behaviorScriptLines" of me to the formattedWidth of field "behaviorScriptLines" of me 
   set the width of field "name" of me to the formattedWidth of field "name" of me
   
   set the loc of field "type" of me to tLoc
   set the loc of field "name" of me to tLoc
   set the loc of button "cantSelect" of me to tLoc
   set the loc of button "visible" of me to tLoc
   set the loc of field "scriptLines" of me to tLoc
   set the loc of field "behaviorScriptLines" of me to tLoc
   set the loc of image "groupIcon" of me to tLoc
   
   repeat with x = 1 to 9
      if x > tConnectorCount then
         hide button ("connector" & x) of me
      else
         show button ("connector" & x) of me
         if tLevelConnectors[x] is not empty then
            set the icon of button  ("connector" & x) of me to the id of image tLevelConnectors[x] of card "templates" of this stack
            set the left of button ("connector" & x) of me to item 1 of pControlRect + (x-1)*20
         else
            set the icon of button  ("connector" & x) of me to empty
            set the left of button ("connector" & x) of me to item 1 of pControlRect + (x-1)*20
         end if
      end if
   end repeat
   
   local tNameFieldLeft
   if revIDEGetPreference("ideProjectBrowser_objectType") is "text" then
      set the left of button "disclosure" of me to the right of button ("connector" & tConnectorCount) of me
      set the width of field "type" of me to the formattedWidth of field "type" of me
      set the left of field "type" of me to the right of button "disclosure" of me
      put the right of field "type" of me - 5 into tNameFieldLeft
   else
      set the left of button "disclosure" of me to the right of button ("connector" & tConnectorCount) of me
      set the left of image "groupIcon" of me to the right of button "disclosure" of me
      put the right of image "groupIcon" of me into tNameFieldLeft
   end if
   
   set the right of button "cantSelect" of me to the item 3 of pControlRect - the palettePadding of me   
   set the right of button "visible" of me to the left of button "cantSelect" of me - the palettePadding of me   
   set the right of field "scriptLines" of me to the left of button "visible" of me  - the palettePadding of me
   set the right of field "behaviorScriptLines" of me to the left of field "scriptLines" of me  - the palettePadding of me
   
   ## Check the width of  the "name" field so it doesn't overrun the space
   local tNameWidth
   if the visible of field "behaviorScriptLines" of me then
      put the left of field "behaviorScriptLines" of me - tNameFieldLeft - the palettePadding of me into tNameWidth
   else
      put the left of field "scriptLines" of me - tNameFieldLeft - the palettePadding of me into tNameWidth
   end if
   
   if the width of field "name" of me > tNameWidth then
      set the width of field "name" of me to tNameWidth
   end if
   set the left of field "name" of me to tNameFieldLeft
end LayoutControl


getProp dvRowControl
   return the long id of me
end dvRowControl

setProp dvHilite[pHiliteColor] pBoolean
   # Override basic hilite feature...
   --   if the cObjectLongID of me is among the lines of the cOwners of group "objectList" then
   --      set the backgroundColor of graphic "background" of me to "234,234,234"
   --   end if
   
   if pBoolean then
      --hide graphic "bottom_border" of me
      set the foregroundColor of field "type" of me to revIDEColor("dataView_TextHiliteColor")
      set the foregroundColor of field "name" of me to  revIDEColor("dataView_TextHiliteColor")
      set the foregroundColor of field "scriptLines" of me to  revIDEColor("text_1")
      set the foregroundColor of field "behaviorScriptLines" of me to  revIDEColor("text_1")
      set the backgroundColor of field "scriptLines" of me to  revIDEColor("dataView_TextHiliteColor")
      set the backgroundColor of field "behaviorScriptLines" of me to revIDEColor("dataView_TextHiliteColor")
      set the colorOverlay["color"] of image "groupIcon" of me to revIDEColor("dataView_TextHiliteColor")
   else
      --show graphic "bottom_border" of me
      set the foregroundColor of field "type" of me to revIDEColor("text_2")
      set the foregroundColor of field "name" of me to revIDEColor("text_1")
      set the foregroundColor of field "scriptLines" of me to  revIDEColor("text_3")
      set the foregroundColor of field "behaviorScriptLines" of me to  revIDEColor("text_3")
      set the backgroundColor of field "scriptLines" of me to revIDEColor("dataView_hiliteColor")
      set the backgroundColor of field "behaviorScriptLines" of me to revIDEColor("dataView_hiliteColor")
      set the colorOverlay of image "groupIcon" of me to empty
   end if
end dvHilite

on mouseUp
   switch the short name of the target
      case "scriptLines"
         edit the script of the cObjectLongID of me
         break
      case "behaviorScriptLines"
         edit the script of the cBehaviorLongID of me
         break
      default
         --selectObjects    
         pass mouseUp
   end switch
end mouseUp

on mouseDown pButton
   if pButton is 3 then       
      dispatch "pbRightClick" to stack "revIDEProjectBrowser" with the cObjectLongID of me
   else if the short name of the target is "name" and \
         the dvRow of me is the dvHilitedRow of the owner of me then
      set the textColor of field "name" of me to revIDEColor("text_1")
      CreateFieldEditorForField the long id of field "name" of me, "name"
   else
      pass mouseDown
   end if
end mouseDown

on toggleVisible
   if the icon of button "visible" of me is the id of image "visible_on" of card "templates" of this stack then
      set the icon of button "visible" of me to the id of image "visible_off" of card "templates" of this stack
      updateProperty the cObjectLongID of me, "visible", "false"
   else
      set the icon of button "visible" of me to the id of image "visible_on" of card "templates" of this stack
      updateProperty the cObjectLongID of me, "visible", "true"
   end if  
end toggleVisible

on toggleCantSelect
   if the icon of button "cantSelect" of me is the id of image "cantSelect_on" of card "templates" of this stack then
      set the icon of button "cantSelect" of me to the id of image "cantSelect_off" of card "templates" of this stack
      updateProperty the cObjectLongID of me, "cantSelect", "false"
   else
      set the icon of button "cantSelect" of me to the id of image "cantSelect_on" of card "templates" of this stack
      updateProperty the cObjectLongID of me, "cantSelect", "true"
   end if  
end toggleCantSelect

on mouseDoubleUp 
   if the short name of the target is "name" then
      set the textColor of field "name" of me to revIDEColor("text_1")
      CreateFieldEditorForField the long id of field "name" of me, "name"
   else 
      goToObject the cObjectLongID of me
   end if
end mouseDoubleUp

on CloseFieldEditor pFieldEditor, pRow, pKey, pClosingTriggeredBy
   # The text the user entered is different than the current value of the target field.
   set the textColor of field "name" of me to revIDEColor("text_3")
   set the text of field "name" of me to the text of pFieldEditor
   updateProperty the cObjectLongID of me, "name", the text of pFieldEditor
end CloseFieldEditor


on ExitFieldEditor pFieldEditor, pRow, pKey, pClosingTriggeredBy
   # The text the user entered is the same as the current value of the target field.
   set the textColor of field "name" of me to revIDEColor("text_3")
end ExitFieldEditor

getProp dvAcceptsDrop
   local theA, tRow, tDraggedRow, tDraggedStyle, tDraggedType
   local tNextRow, tTYpe
   put the dvRow of me into tRow
   
   put line 1 of the dragData["private"] into tDraggedRow
   put line 2 of the dragData["private"] into tDraggedStyle
   put line 3 of the dragData["private"] into tDraggedType
   
   if tRow is tDraggedRow then
      put true into theA["above"]
      put true into theA["below"]
   else if tDraggedStyle is "control" or tDraggedStyle is "group" then
      put true into theA["above"]
      put true into theA["below"]
   else if tDraggedType is "card" then
      put getNextVisibleRow(tRow) into tNextRow
      
      if tNextRow is 0 or tNextRow is empty then
         put false into theA["above"]
         put true into theA["below"]
      else
         put getRowType(tNextRow) into tType
         if tType is "card" or tType is "group" then
            put false into theA["above"]
            put true into theA["below"]
         else
            put false into theA["above"]
            put false into theA["below"]
         end if
      end if
   else
      put false into theA["above"]
      put false into theA["below"]
   end if
   return theA
end dvAcceptsDrop

