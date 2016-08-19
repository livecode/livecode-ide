script "revIDEProjectBrowserContainerRowBehavior"
on FillInData pDataA, pRow
   # Map pDataA values to physical controls...
   
   set the cRowNumber of me to pRow
   set the cIndent of me to pDataA["level"] -1
   set the cObjectLongID of me to pDataA["long id"]
   set the cBehaviorLongID of me to pDataA["behavior"]
   set the cLevelConnectors of me to pDataA["levels"]
   set the cType of me to pDataA["type"]
   
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
   
   if pDataA["type"] is "stack" then
      hide group "connector1" of me
      if pDataA["childCount"] is empty or pDataA["childCount"] is 0  then 
         set the cState of group "disclosure" of me to "cantExpand"
         set the cIcon of group "disclosure" of me to "cantExpand"
         disable button "disclosure" of me 
      else
         if pDataA["expanded"] is true then
            set the cState of group "disclosure" of me to "expanded"
            set the cIcon of group "disclosure" of me to "stackExpanded"
         else
            set the cState of group "disclosure" of me to "contracted"
            set the cIcon of group "disclosure" of me to "stackContracted"
         end if
         enable group "disclosure" of me 
      end if
   else      
      if pDataA["childCount"] is empty or pDataA["childCount"] is 0  then 
         set the cState of group "disclosure" of me to "cantExpand"
         set the cIcon of group "disclosure" of me to "cantExpand"
         disable group "disclosure" of me 
      else
         if pDataA["expanded"] is true then
            set the cState of group "disclosure" of me to "expanded"
            set the cIcon of group "disclosure" of me to "childExpanded"
         else
            set the cState of group "disclosure" of me to "contracted"
            set the cIcon of group "disclosure" of me to "childContracted"
         end if
         enable group "disclosure" of me 
      end if
   end if 
   
   if revIDEGetPreference("pb_indicator") is "text" then
      show field "type" of me
      hide button "typeIcon" of me
   else
      hide field "type" of me
      if pDataA["type"] is "stack" then
         set the icon of button "typeIcon" of me to the id of image "stack.png" of card "templates" of this stack
         show button "typeIcon" of me
      else if pDataA["type"] is "substack" then
         set the icon of button "typeIcon" of me to the id of image "substack.png" of card "templates" of this stack
         show button "typeIcon" of me
      else if pDataA["type"] is "card" then
         set the icon of button "typeIcon" of me to the id of image "card.png" of card "templates" of this stack
         show button "typeIcon" of me
      end if
   end if
end FillInData

on LayoutControl pControlRect
   # Resize controls/row   
   local tLevelConnectors, tConnectorCount, tLoc, tTextSize
   
   put the effective textSize of me into tTextSize
   put item 1 of the loc of me & comma & item 2 of the loc me -1 into tLoc
   put the cLevelConnectors of me into tLevelConnectors
   put the number of lines in the keys of tLevelConnectors into tConnectorCount
   
   set the rect of graphic "background" of me to pControlRect
   
   set the width of graphic "bottom_border" of me to (item 3 of pControlRect - item 1 of pControlRect)+2
   set the bottomLeft of graphic "bottom_border" of me to item 1 of pControlRect-1, item 4 of pControlRect
   
   ## Set the formatted height of all the fields
   set the fixedLineHeight of field "type" of me to false
   set the fixedLineHeight of field "name" of me to false
   set the height of field "type" of me to the formattedHeight of field "type" of me
   set the height of field "name" of me to the formattedHeight of field "name" of me
   
   set the fixedLineHeight of field "scriptLines" of me to true
   set the textSize of field "scriptLines" of me to empty
   if tTextSize <=12 then
      set the textHeight of field "scriptLines" of me to (tTextSize + (tTextSize/2))
   else
      set the textHeight of field "scriptLines" of me to (tTextSize + (tTextSize/3))
   end if
   set the height of field "scriptLines" of me to the viewProp["row height"] of the owner of the owner of the owner of me - 6
   
   set the fixedLineHeight of field "behaviorScriptLines" of me to true
   set the textSize of field "behaviorScriptLines" of me to empty
   set the textHeight of field "behaviorScriptLines" of me to the textHeight of field "scriptLines" of me
   set the height of field "behaviorScriptLines" of me to the viewProp["row height"] of the owner of the owner of the owner of me - 6
   
   set the loc of field "type" of me to tLoc
   set the loc of field "name" of me to tLoc
   set the loc of button "typeIcon" of me to tLoc
   set the loc of field "scriptLines" of me to tLoc
   set the loc of field "behaviorScriptLines" of me to tLoc
   
   ## Set the vertical location of the name and text fields
   if tTextSize <= 14 then
      set the top of field "name" of me to the top of me + 2
   else
      set the top of field "name" of me to the top of me
   end if
   set the top of field "type" of me to the top of field "name" of me
   
   set the width of field "scriptLines" of me to the formattedWidth of field "scriptLines" of me
   set the width of field "behaviorScriptLines" of me to the formattedWidth of field "behaviorScriptLines" of me
   set the width of field "name" of me to the formattedWidth of field "name" of me
   
   connectorResize "disclosure"
   setConnectorIcon the long id of group "disclosure" of me, the cIcon of group "disclosure" of me
   repeat with x = 1 to 2
      if x > tConnectorCount then
         hide group ("connector" & x) of me
      else
         connectorResize ("connector" & x)
         show group ("connector" & x) of me
         if tLevelConnectors[x] is not empty then
            setConnectorIcon the long id of group ("connector" & x) of me, tLevelConnectors[x] 
            set the left of group ("connector" & x) of me to item 1 of pControlRect + (x-1)*20
         else
            setConnectorIcon the long id of group ("connector" & x) of me, empty
            set the left of group ("connector" & x) of me to item 1 of pControlRect + (x-1)*20
         end if
      end if
   end repeat
   
   if tConnectorCount = 0 then
      set the left of group "disclosure" of me to item 1 of pControlRect + (10 * (the cIndent of me))
   else
      set the left of group "disclosure" of me to the right of group ("connector" & tConnectorCount) of me
   end if
   
   local tNameFieldLeft
   if revIDEGetPreference("pb_indicator") is "text" then     
      set the width of field "type" of me to the formattedWidth of field "type" of me
      set the left of field "type" of me to the right of group "disclosure" of me
      put the right of field "type" of me - 5 into tNameFieldLeft
   else
      set the left of button "typeIcon" of me to the right of group "disclosure" of me
      put the right of button "typeIcon" of me into tNameFieldLeft
   end if
   
   set the right of field "scriptLines" of me to item 3 of pControlRect - the palettePadding of me
   set the right of field "behaviorScriptLines" of me to the left of field "scriptLines" of me - 2
   
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
   
   if pBoolean then
      set the foregroundColor of field "type" of me to revIDEColor("dataView_TextHiliteColor")
      set the foregroundColor of field "name" of me to  revIDEColor("dataView_TextHiliteColor")
      set the foregroundColor of field "scriptLines" of me to  revIDEColor("text_1")
      set the foregroundColor of field "behaviorScriptLines" of me to  revIDEColor("text_1")
      set the backgroundColor of field "scriptLines" of me to  revIDEColor("dataView_TextHiliteColor")
      set the backgroundColor of field "behaviorScriptLines" of me to  revIDEColor("dataView_TextHiliteColor")
      set the colorOverlay["color"] of button "typeIcon" of me to revIDEColor("dataView_TextHiliteColor")
      set the foregroundColor of me to revIDEColor("dataView_disclosureIconHiliteColor")
      set the foregroundColor of widget "icon" of group "disclosure" of me to revIDEColor("dataView_disclosureIconHiliteColor")
   else
      set the foregroundColor of field "type" of me to revIDEColor("text_2")
      set the foregroundColor of field "name" of me to revIDEColor("text_1")
      set the foregroundColor of field "scriptLines" of me to  revIDEColor("text_3")
      set the foregroundColor of field "behaviorScriptLines" of me to  revIDEColor("text_3")
      
      if exists(the cObjectLongID of me) and the scriptStatus of the cObjectLongID of me is "error" then
         set the backgroundColor of field "scriptLines" of me to revIDEColor("dataView_scriptErrorBackgroundColor")
      else
         set the backgroundColor of field "scriptLines" of me to revIDEColor("dataView_hiliteColor")
      end if
      
      if exists(the cBehaviorLongID of me) and the scriptStatus of the cBehaviorLongID of me is "error" then
         set the backgroundColor of field "behaviorScriptLines" of me to revIDEColor("dataView_scriptErrorBackgroundColor")
      else
         set the backgroundColor of field "behaviorScriptLines" of me to revIDEColor("dataView_hiliteColor")
      end if
      
      set the colorOverlay of button "typeIcon" of me to empty
      set the foregroundColor of me to revIDEColor("dataView_disclosureIconColor")
      set the foregroundColor of widget "icon" of group "disclosure" of me to revIDEColor("dataView_disclosureIconColor")
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
      case "icon"
      case "disclosure"
         if the cState of the owner of the target is "contracted" then
            toggleGroup the cRowNumber of the owner of the owner of the target,true
         else if the cState of the owner of the target is"expanded" then
            toggleGroup  the cRowNumber of  the owner of the owner of the target,false
         end if
         break
      default
         pass mouseUp
      default
         pass mouseUp
   end switch
end mouseUp

on mouseDoubleUp 
   goToObject the cObjectLongID of me
end mouseDoubleUp

on CloseFieldEditor pFieldEditor, pRow, pKey, pClosingTriggeredBy
   # The text the user entered is different than the current value of the target field.
   set the textColor of field "name" of me to revIDEColor("text_3")
   set the text of field "name" of me to the text of pFieldEditor
   updateProperty the cObjectLongID of me, "name", the text of pFieldEditor
end CloseFieldEditor

on ExitFieldEditor pFieldEditor, pRow, pKey, pClosingTriggeredBy
   set the textColor of field "name" of me to revIDEColor("text_3")
   # The text the user entered is the same as the current value of the target field.
end ExitFieldEditor

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

getProp dvAcceptsDrop
   local theA, tRow, tDraggedRow, tDraggedType, tDraggedStyle
   local tDroppedType, tNextRow, tNextType, tAbsoluteRow
   put the dvRow of me into tRow
   
   put getAbsoluteRow(tRow) into tAbsoluteRow
   put getRowType(tAbsoluteRow) into tDroppedType
   
   put line 1 of the dragData["private"] into tDraggedRow
   put line 2 of the dragData["private"] into tDraggedStyle
   put line 3 of the dragData["private"] into tDraggedType
   
   if tRow is tDraggedRow then
      put true into theA["above"]
      put true into theA["below"]
   else if tDraggedStyle is "control" and tDroppedType is "card" then
      put false into theA["above"]
      put true into theA["below"]
   else if tDraggedStyle is "control" and tDroppedType is "stack" then
      put false into theA["above"]
      put true into theA["below"]
   else if tDraggedStyle is "group" and tDroppedType is "card" then
      put false into theA["above"]
      put true into theA["below"]
   else if tDraggedType is "card" and tDroppedType is "card" then
      put true into theA["above"]
      put true into theA["below"]
   else if tDraggedType is "card" and tDroppedType is "stack" then
      put false into theA["above"]
      put false into theA["below"]
   else if tDraggedType is "substack" and tDroppedType is "substack" then
      put true into theA["above"]
      put true into theA["below"]
   else if tDraggedType is "substack" and tDroppedType is "stack" then
      put false into theA["above"]
      put false into theA["below"]
   else if tDraggedType is "substack" and tDroppedType is "card" then
      put getNextVisibleRow(tRow) into tNextRow  
      put getRowType(tNextRow) into tNextType              
      if tNextRow is 0 or tNextRow is empty then
         put false into theA["above"]
         put true into theA["below"]
      else
         if tNextType is "substack" or tNextType is "stack" then
            put false into theA["above"]
            put true into theA["below"]
         else
            put false into theA["above"]
            put false into theA["below"]
         end if
      end if
   else
      ## Default is false
      put false into theA["above"]
      put false into theA["below"]
   end if
   return theA
end dvAcceptsDrop

command connectorResize pControl
   set the borderWidth of group pControl of me to 0
   set the showBorder of group pControl of me to false
   set the threeD of group pControl of me to false
   
   set the lockLoc of group pControl of me to true
   set the height of group pControl of me to the height of me
   set the width of group pControl of me to 20
   set the top of group pControl of me to the top of me
   
   set the width of widget "icon" of group pControl of me to 12
   set the height of widget "icon" of group pControl of me to the width of widget "icon" of group pControl of me
   set the loc of widget "icon" of group pControl  of me to the loc of group pControl of me
end connectorResize
