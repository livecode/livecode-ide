script "revIDEProjectBrowserSectionRowBehavior"
on FillInData pDataA, pRow
   # Map pDataA values to physical controls...
   set the cRowNumber of me to pRow
   set the cLevelConnectors of me to pDataA["levels"]
   
   put pDataA["title"] into field "type" of me
   set the icon of button "typeIcon" of me to the id of image pDataA["title"] of card "templates" of this stack
   if pDataA["expanded"] is true then
      if the number of lines in the keys of pDataA["levels"] is 0 then
         set the cState of group "disclosure" of me to "expanded"
         set the cIcon of group "disclosure" of me to "stackExpanded"
      else
         set the cState of group "disclosure" of me to "expanded"
         set the cIcon of group "disclosure" of me to "childExpanded"
      end if
   else
      if the number of lines in the keys of pDataA["levels"] is 0 then
         set the cState of group "disclosure" of me to "contracted"
         set the cIcon of group "disclosure" of me to "stackContracted"
      else
         set the cState of group "disclosure" of me to "contracted"
         set the cIcon of group "disclosure" of me to "childContracted"
      end if
   end if 
end FillInData

on LayoutControl pControlRect
   local tLevelConnectors, tConnectorCount, tTextSize
   
   put the effective textSize of me into tTextSize
   put the cLevelConnectors of me into tLevelConnectors
   put the number of lines in the keys of tLevelConnectors into tConnectorCount
   
   # Resize controls/row   
   set the rect of graphic "background" of me to pControlRect
   set the width of graphic "bottom_border" of me to (item 3 of pControlRect - item 1 of pControlRect)
   set the bottomLeft of graphic "bottom_border" of me to the bottomLeft of graphic "background" of me
   
   show group "disclosure" of me
   connectorResize "disclosure"
   setConnectorIcon the long id of group "disclosure" of me, the cIcon of group "disclosure" of me
   if tConnectorCount = 0 then
      hide group "connector1" of me
      set the left of group "disclosure" of me to item 1 of pControlRect
   else
      show group "connector1" of me
      connectorResize "connector1"
      setConnectorIcon the long id of group "connector1" of me, tLevelConnectors[1]
      set the left of group "connector1" of me to item 1 of pControlRect
      set the left of group "disclosure" of me to the right of group ("connector1") of me
   end if
   
   set the fixedLineHeight of field "type" of me to false
   set the height of field "type" of me to the formattedHeight of field "type" of me
   ## Set the vertical location of the name and text fields
   if tTextSize <= 14 then
      set the top of field "type" of me to the top of me + 2
   else
      set the top of field "type" of me to the top of me
   end if
   
   set the loc of field "type" of me to the loc of me 
   set the loc of button "typeIcon" of me to the loc of me 
   
   set the width of field "type" of me to (item 3 of pControlRect - item 1 of pControlRect) - 20
   set the left of button "typeIcon" of me to the right of group "disclosure" of me
   set the left of field "type" of me to the right of button "typeIcon" of me
end LayoutControl

getProp dvRowControl
   return the long id of me
end dvRowControl

getProp dvAcceptsDrop
   local theA
   put false into theA["above"]
   put false into theA["below"]
   return theA
end dvAcceptsDrop

setProp dvHilite[pHiliteColor] pBoolean
   # Override basic hilite feature...
   if pBoolean then
      set the foregroundColor of field "type" of me to revIDEColor("dataView_TextHiliteColor")
      set the colorOverlay["color"] of button "typeIcon" of me to revIDEColor("dataView_TextHiliteColor")
      set the foregroundColor of me to revIDEColor("dataView_disclosureIconHiliteColor")
   else
      set the foregroundColor of field "type" of me to revIDEColor("text_1")
      set the colorOverlay of button "typeIcon" of me to empty
      set the foregroundColor of me to revIDEColor("dataView_disclosureIconColor")
   end if
end dvHilite

on mouseUp
   switch the short name of the target
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
   end switch
end mouseUp

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
