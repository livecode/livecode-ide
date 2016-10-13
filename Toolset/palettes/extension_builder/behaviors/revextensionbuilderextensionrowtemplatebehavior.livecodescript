script "revExtensionBuilderExtensionRowTemplateBehavior"
on FillInData pDataA, pRow
   # Map pDataA values to physical controls...
   local tVersion
   
   set the cTypeID of me to pDataA["name"]
   
   local tLabel, tAuthor
   put pDataA["displayname"] into tLabel
   
   if pDataA["author"] is not empty then put pDataA["author"] into tAuthor
   if tAuthor is empty then put "Unknown Author" into tAuthor
   
   local tFolder
   put pDataA["folder"] into tFolder
   set the itemDel to slash
   if tFolder begins with revIDESpecialFolderPath("user extensions") then
      put empty into char 1 to the length of revIDESpecialFolderPath("user extensions") + 1 of tFolder
   else if tFolder begins with specialFolderPath("home") then
      put "~" into char 1 to the length of specialFolderPath("home") of tFolder
   end if
   
   put tLabel & return & tAuthor & return & tFolder into field "description" of me
   set the sharedText of field "description" of me to true
   
   local tPath
   put pDataA["svgicon"] into tPath
   
   if tPath is empty then
      if pDataA["icon"] is not empty then
         set the filename of image "icon" of me to pDataA["icon"]
      else
         put revIDEDefaultExtensionIconPath(pDataA["type"]) into tPath
         if tPath is empty then
            set the filename of image "icon" of me to revIDEDefaultExtensionIcon(pDataA["type"])
         end if
      end if
   end if
   
   if tPath is not empty then
      set the iconPath of widget "svgicon" of me to tPath
   end if
   set the invisible of widget "svgicon" of me to tPath is empty
   set the visible of image "icon" of me to tPath is empty
end FillInData

on LayoutControl pControlRect
   
   local tMargin, tPadding, tIconLoc
   
   # Resize controls/row
   put the paletteMargin of me into tMargin
   put the palettePadding of me into tPadding
   
   set the rect of graphic "background" of me to pControlRect
   set the width of graphic "border" of me to (item 3 of pControlRect - item 1 of pControlRect)
   set the bottomLeft of graphic "border" of me to item 1 of pControlRect, item 4 of pControlRect
   put the loc of me into tIconLoc
   put item 1 of pControlRect + (17 + tMargin) into item 1 of tIconLoc
   set the loc of image "icon" of me to tIconLoc  
   set the loc of widget "svgicon" of me to tIconLoc  
   
   set the width of field "description" of me to (item 3  of pControlRect - item 1 of pControlRect) - (34 + tMargin * 2)
   set the textSize of line 2 of field "description" of me to 12
   set the textSize of line 3 of field "description" of me to 10
   set the height of field "description" of me to the formattedHeight of field "description" of me
   set the loc of field "description" of me to the loc of me
   set the left of field "description" of me to item 1 of pControlRect + 34 + tMargin
   
   set the textColor of line 1 of field "description" of me to revIDEColor("text_1")
   set the textColor of line 2 to 3 of field "description" of me to revIDEColor("text_2")
   repeat until the formattedWidth of line 3 of field "description" of me < the width of field "description" of me - tMargin
      put "…" into char 1 to 3 of line 3 of field "description" of me
   end repeat
end LayoutControl

on mouseUp
   pass mouseUp
end mouseUp

on mouseDoubleUp
   pass mouseDoubleUp
end mouseDoubleUp

getProp dvRowControl
   return the long id of me
end dvRowControl

setProp dvHilite[pHiliteColor] pBoolean
   # Override basic hilite feature...
end dvHilite
