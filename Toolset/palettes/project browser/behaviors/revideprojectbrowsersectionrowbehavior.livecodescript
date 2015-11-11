script "revIDEProjectBrowserSectionRowBehavior"
on FillInData pDataA, pRow
   # Map pDataA values to physical controls...
   set the cRowNumber of me to pRow
   set the cLevelConnectors of me to pDataA["levels"]
   
   put pDataA["title"] into field "type" of me
   set the icon of button "typeIcon" of me to the id of image pDataA["title"] of card "templates" of this stack
   if pDataA["expanded"] is true then
      if the number of lines in the keys of pDataA["levels"] is 0 then
         set the icon of button "disclosure" of me to the id of image "stackExpanded" of card "templates" of this stack
      else
         set the icon of button "disclosure" of me to the id of image "childExpanded" of card "templates" of this stack
      end if
   else
      if the number of lines in the keys of pDataA["levels"] is 0 then
         set the icon of button "disclosure" of me to the id of image "stackContracted" of card "templates" of this stack
      else
         set the icon of button "disclosure" of me to the id of image "childContracted" of card "templates" of this stack
      end if
   end if 
end FillInData

on LayoutControl pControlRect
   local tLevelConnectors, tConnectorCount
   put the cLevelConnectors of me into tLevelConnectors
   put the number of lines in the keys of tLevelConnectors into tConnectorCount
   
   # Resize controls/row   
   set the rect of graphic "background" of me to pControlRect
   set the width of graphic "bottom_border" of me to (item 3 of pControlRect - item 1 of pControlRect)
   set the bottomLeft of graphic "bottom_border" of me to the bottomLeft of graphic "background" of me
   
   if tConnectorCount = 0 then
      hide button "connector1" of me
      set the left of button "disclosure" of me to item 1 of pControlRect
   else
      show button "connector1" of me
      set the icon of button  "connector1" of me to the id of image tLevelConnectors[1] of card "templates" of this stack
      set the left of button "connector1" of me to item 1 of pControlRect
      set the left of button "disclosure" of me to the right of button ("connector1") of me
   end if
   
   set the loc of field "type" of me to the loc of me 
   set the loc of button "typeIcon" of me to the loc of me 
   
   set the width of field "type" of me to (item 3 of pControlRect - item 1 of pControlRect) - 20
   set the left of button "typeIcon" of me to the right of button "disclosure" of me
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
   else
      set the foregroundColor of field "type" of me to revIDEColor("text_1")
      set the colorOverlay of button "typeIcon" of me to empty
   end if
end dvHilite
