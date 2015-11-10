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
   local tLevelConnectors
   
   put the cLevelConnectors of me into tLevelConnectors
   set the rect of graphic "background" of me to pControlRect   
   set the width of graphic "bottom_border" of me to (item 3 of pControlRect - item 1 of pControlRect)
   set the bottomLeft of graphic "bottom_border" of me to the left of graphic "background" of me, the bottom of graphic "background" of me
   
   set the width of field "type" of me to the formattedWidth of field "type" of me
   set the width of field "name" of me to the formattedWidth of field "name" of me
   
   set the loc of field "scriptLines" of me to the loc of me 
   set the loc of button "typeIcon" of me to the loc of me 
   
   repeat with x = 1 to 2
      show button ("connector" & x) of me
      if tLevelConnectors[x] is not empty then
         set the icon of button  ("connector" & x) of me to the id of image tLevelConnectors[x] of card "templates" of this stack
         set the left of button ("connector" & x) of me to item 1 of pControlRect + (x-1)*20
      else
         set the icon of button  ("connector" & x) of me to empty
         set the left of button ("connector" & x) of me to item 1 of pControlRect + (x-1)*20
      end if
   end repeat
   
   set the left of button "connector1" of me to item 1 of pControlRect
   set the left of button "connector2" of me to the right of button "connector1" of me
   
   if revIDEGetPreference("ideProjectBrowser_objectType") is "text" then
      show field "type" of me
      hide button "typeIcon" of me
      set the left of field "type" of me to the right of  button "connector2" of me
      set the left of field "name" of me to the right of field "type" of me -5
   else
      hide field "type" of me
      show button "typeIcon" of me
      set the icon of button "typeIcon" of me to the id of image (the cType of me) of card "templates" of this stack
      set the left of button "typeIcon" of me to the right of  button "connector2" of me
      set the left of field "name" of me to the right of button "typeIcon" of me
   end if
   set the width of field "scriptLines" of me to the formattedWidth of field "scriptLines" of me
   set the right of field "scriptLines" of me to item 3 of pControlRect - the palettePadding of me
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
      set the foregroundColor of field "type" of me to revIDEColor("dataView_TextHiliteColor")
      set the foregroundColor of field "name" of me to  revIDEColor("dataView_TextHiliteColor")
      set the foregroundColor of field "scriptLines" of me to  revIDEColor("text_1")
      set the backgroundColor of field "scriptLines" of me to  revIDEColor("dataView_TextHiliteColor")
      set the colorOverlay["color"] of button "typeIcon" of me to revIDEColor("dataView_TextHiliteColor")
   else
      set the foregroundColor of field "type" of me to revIDEColor("text_2")
      set the foregroundColor of field "name" of me to revIDEColor("text_1")
      set the foregroundColor of field "scriptLines" of me to  revIDEColor("text_3")
      set the backgroundColor of field "scriptLines" of me to revIDEColor("dataView_hiliteColor")
      set the colorOverlay of button "typeIcon" of me to empty
   end if
end dvHilite

on mouseUp
   switch the short name of the target
      case "scriptLines"
         edit the script of the cObjectLongID of me
         break
   end switch
end mouseUp

getProp dvAcceptsDrop
   local theA
   put false into theA["above"]
   put false into theA["below"]
   return theA
end dvAcceptsDrop
