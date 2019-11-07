script "revIDEProjectBrowserLibraryRowBehavior"
on FillInData pDataA, pRow
   # Map pDataA values to physical controls...
   set the cIndent of me to pDataA["level"] -1
   set the cObjectLongID of me to pDataA["long id"]
   set the cLevelConnectors of me to pDataA["levels"]
   set the cType of me to pDataA["type"]
   put pDataA["type"] & ":" into field "type" of me
   put pDataA["name"] into field "name" of me
   
   if pDataA["script lines"] is 0 or pDataA["script lines"] is empty then
      put 0 into field "scriptLines" of me
   else
      put pDataA["script lines"] into field "scriptLines" of me
   end if 
end FillInData

on LayoutControl pControlRect
   # Resize controls/row
   local tLevelConnectors, tTextSize
   
   put the effective textSize of me into tTextSize
   put the cLevelConnectors of me into tLevelConnectors
   set the rect of graphic "background" of me to pControlRect   
   set the width of graphic "bottom_border" of me to (item 3 of pControlRect - item 1 of pControlRect)
   set the bottomLeft of graphic "bottom_border" of me to the left of graphic "background" of me, the bottom of graphic "background" of me
   
   set the width of field "type" of me to the formattedWidth of field "type" of me
   set the width of field "name" of me to the formattedWidth of field "name" of me
   
   set the fixedLineHeight of field "type" of me to false
   set the height of field "type" of me to the formattedHeight of field "type" of me
   if tTextSize <= 14 then
      set the top of field "name" of me to the top of me + 2
   else
      set the top of field "name" of me to the top of me
   end if
   set the top of field "type" of me to the top of field "name" of me
   
   set the fixedLineHeight of field "name" of me to false
   set the height of field "name" of me to the formattedHeight of field "name" of me
   set the top of field "name" of me to the top of field "type" of me
   set the top of field "type" of me to the top of field "name" of me
   
   set the fixedLineHeight of field "scriptLines" of me to true
   set the textSize of field "scriptLines" of me to empty
   if tTextSize <=12 then
      set the textHeight of field "scriptLines" of me to (tTextSize + (tTextSize/2))
   else
      set the textHeight of field "scriptLines" of me to (tTextSize + (tTextSize/3))
   end if
   set the height of field "scriptLines" of me to the viewProp["row height"] of the owner of the owner of the owner of me - 6
   set the loc of field "scriptLines" of me to the loc of me 
   
   set the loc of button "typeIcon" of me to the loc of me 
   
   repeat with x = 1 to 2
      show group ("connector" & x) of me
      connectorResize ("connector" & x)
      if tLevelConnectors[x] is not empty then
         setConnectorIcon the long id of group ("connector" & x) of me, tLevelConnectors[x]
         set the left of group ("connector" & x) of me to item 1 of pControlRect + (x-1)*20
      else
         setConnectorIcon the long id of group ("connector" & x) of me,empty
         set the left of group ("connector" & x) of me to item 1 of pControlRect + (x-1)*20
      end if
   end repeat
   
   set the left of group "connector1" of me to item 1 of pControlRect
   set the left of group "connector2" of me to the right of group "connector1" of me
   
   local tNameFieldLeft
   if revIDEGetPreference("pb_indicator") is "text" then
      show field "type" of me
      hide button "typeIcon" of me
      set the left of field "type" of me to the right of  group "connector2" of me
      put the right of field "type" of me -5 into tNameFieldLeft
   else
      hide field "type" of me
      show button "typeIcon" of me
      set the icon of button "typeIcon" of me to the id of image (the cType of me) of card "templates" of this stack
      set the left of button "typeIcon" of me to the right of  group "connector2" of me
      put the right of button "typeIcon" of me into tNameFieldLeft
   end if
   set the width of field "scriptLines" of me to the formattedWidth of field "scriptLines" of me
   set the right of field "scriptLines" of me to item 3 of pControlRect - the palettePadding of me
   
   ## Check the width of  the "name" field so it doesn't overrun the space
   local tNameWidth
   put the left of field "scriptLines" of me - tNameFieldLeft - the palettePadding of me into tNameWidth
   
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
      set the backgroundColor of field "scriptLines" of me to  revIDEColor("dataView_TextHiliteColor")
      set the colorOverlay["color"] of button "typeIcon" of me to revIDEColor("dataView_TextHiliteColor")
      set the foregroundColor of me to revIDEColor("dataView_disclosureIconHiliteColor")
   else
      set the foregroundColor of field "type" of me to revIDEColor("text_2")
      set the foregroundColor of field "name" of me to revIDEColor("text_1")
      set the foregroundColor of field "scriptLines" of me to  revIDEColor("text_3")
      set the backgroundColor of field "scriptLines" of me to revIDEColor("dataView_hiliteColor")
      set the foregroundColor of me to revIDEColor("dataView_disclosureIconColor")
      set the colorOverlay of button "typeIcon" of me to empty
   end if
end dvHilite

on mouseUp
   switch the short name of the target
      case "scriptLines"
         edit the script of the cObjectLongID of me
         break
      case "icon"
      case "disclosure"
         if the cState of the owner of the target is "contracted" then
            toggleGroup the cRowNumber of the owner of the owner of the target,true
         else if the cState of the owner of the target is"expanded" then
            toggleGroup  the cRowNumber of  the owner of the owner of the target,false
         end if
         break
   end switch
end mouseUp

getProp dvAcceptsDrop
   local theA
   put false into theA["above"]
   put false into theA["below"]
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
   
   local tTextSize, tWidgetSize
   put the effective textsize of me into tTextSize
   switch 
      case tTextSize >= 8 and tTextSize < 12
         put 11 into tWidgetSize
         break
      case tTextSize >= 12 and tTextSize < 14
         put 13 into tWidgetSize
         break
      case tTextSize >= 14 and tTextSize < 18
         put 15 into tWidgetSize
         break
      case tTextSize >= 18
         put 17 into tWidgetSize
         break
      default
         put 13 into tWidgetSize
   end switch
   
   set the width of widget "icon" of group pControl of me to tWidgetSize
   set the height of widget "icon" of group pControl of me to the width of widget "icon" of group pControl of me
   set the loc of widget "icon" of group pControl  of me to the loc of group pControl of me
end connectorResize
