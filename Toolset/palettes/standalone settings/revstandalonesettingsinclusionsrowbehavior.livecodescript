script "revStandaloneSettingsInclusionsRowBehavior"
constant kPlatforms = "emscripten,android,ios,linux,windows,macosx"
on FillInData pDataA, pRow
   # Map pDataA values to physical controls...
   local tVersion
   
   set the cTypeID of me to pDataA["id"]
   
   local tLabel, tAuthor
   if pDataA["title"] is not empty then put pDataA["title"] into tLabel
   else if pDataA["label"] is not empty then put pDataA["label"] into tLabel
   if tLabel is empty then put "Extension Title" into tLabel
   
   set the cLabel of me to tLabel
   
   if pDataA["author"] is not empty then put pDataA["author"] into tAuthor
   if tAuthor is empty then put "Unknown Author" into tAuthor
   
   put tLabel into field "description" of me
   
   local tIconName, tIconPath
   revIDEExtensionIconFromType pDataA["type"], pDataA["id"], tIconName, tIconPath
   
   if tIconPath is not empty then
      set the iconPath of widget "icon" of me to tIconPath
   else
      set the iconPresetName of widget "icon" of me to tIconName
   end if
   
   repeat for each item tItem in kPlatforms
      if tItem is among the items of pDataA["platforms"] then
         show image tItem of me
      else
         hide image tItem of me
      end if
   end repeat
   
   if revIDEExtensionStandaloneSettingsInfo(pDataA["id"]) \
         is not empty then
      show widget "Settings" of me
   else
      hide widget "Settings" of me
   end if
   
   set the cRow of me to pRow
end FillInData

on LayoutControl pControlRect
   
   local tMargin, tPadding, tIconLoc
   
   # Resize controls/row
   put 6 into tMargin
   put 6 into tPadding
   
   set the rect of graphic "background" of me to pControlRect
   set the width of graphic "border" of me to (item 3 of pControlRect - item 1 of pControlRect)
   set the bottomLeft of graphic "border" of me to item 1 of pControlRect, item 4 of pControlRect
   put the loc of me into tIconLoc
   put item 1 of pControlRect + (17 + tMargin) into item 1 of tIconLoc
   set the loc of widget "icon" of me to tIconLoc  
   
   --set the width of field "description" of me to (item 3  of pControlRect - item 1 of pControlRect) - the width of image "icon" of me - the width of button "uninstall" of me
   set the width of field "description" of me to the formattedWidth of field "description" of me
   set the height of field "description" of me to the formattedHeight of field "description" of me
   set the loc of field "description" of me to the loc of me
   set the left of field "description" of me to the right of widget "icon" of me + tPadding
   
   set the textColor of line 1 of field "description" of me to revIDEColor("text_1")
   set the textColor of line 2 of field "description" of me to revIDEColor("text_2")
   
   local tRight
   put the right of me into tRight
   subtract tMargin from tRight
   set the loc of button "Check" of me to the loc of me
   set the right of button "Check" of me to tRight
   put the left of button "Check" of me into tRight
   subtract tPadding from tRight
   
   repeat for each item tItem in kPlatforms
      subtract tPadding from tRight
      set the loc of image tItem of me to the loc of me
      set the right of image tItem of me to tRight
      put the left of image tItem of me into tRight
   end repeat
   
   subtract 2*tPadding from tRight
   set the right of widget "Settings" of me to tRight
end LayoutControl

on mouseUp
   if the long id of the target is \
         the long id of widget "Settings" of me then
      popupExtensionStandaloneSettings the cTypeId of me, the mouseLoc
   else
      dispatch "rowClicked" to card "inclusions" of this stack with the cRow of me
   end if
end mouseUp

command popupExtensionStandaloneSettings pId, pClickLoc
   -- TODO: Fetch existing value!
   set the behavior of the long id of widget "Settings" of me \
         to the long id of stack revIDEPaletteResourcePath("behaviors/revinspectoreditorbehavior.livecodescript", the long ID of stack "revInspector")
   set the rowLabel of me to the cLabel of me && "Standalone Settings"
   local tPropertyInfo, tPropData, tStack
   dispatch function "getTargetStack" to me
   put the result into tStack
   put "Extension Standalone Settings" into tPropertyInfo["property_name"]
   put revIDEStandaloneSettingsInfoOfExtension(pId) \
         into tPropertyInfo["popup"]
   set the editorPropertyInfo of widget "Settings" of me to tPropertyInfo
   set the editorPopupData of widget "Settings" of me to \
         revIDEStandaloneSettingsOfExtension(tStack, pId)
   send "editorPopup pClickLoc" to widget "Settings" of me
end popupExtensionStandaloneSettings

on valueChanged pProp, pValue
   -- extension standalone settings don't get set directly
   -- they live in cRevStandaloneSettings[<ext id>][key]
   -- and get merged at build time
   local tSettings
   dispatch function "getSettings" to me
   put the result into tSettings
   put pValue into tSettings[the cTypeId of me][pProp]
   dispatch "setSettings" to me with tSettings
end valueChanged

on mouseDown
   
end mouseDown

getProp dvRowControl
   return the long id of me
end dvRowControl

setProp dvHilite[pHiliteColor] pBoolean
   set the hilite of button "check" of me to pBoolean
end dvHilite
