script "com.livecode.pi.textcontents.behavior"
local sTextType
on editorInitialize
   put the editorLabel of me into field "rowlabel" of me
   set the rowShowLabel of me to false
   
   set the editorMinWidth of me to 25
   set the editorMaxWidth of me to 0
   
   set the itemdelimiter to "."
   put item -1 of the editorProperty["editor"] of me into sTextType
   
   set the toolTip of button "wrap text" of me to "wrap text"
   set the toolTip of button "show grid" of me to "show grid"
   set the toolTip of button "import" of me to "import file"
   
   set the editorExpandVertical of me to true
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled, tProp
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   lock messages
   if sTextType is "styledText" then
      set the styledText of field "htmltext" of me to tValue
   else
      put tValue into field "htmltext" of me
   end if
   set the enabled of field "htmltext" of me to tEnabled
   if tEffective is true then
      set the textcolor of field "htmltext" of me to "150,150,150"
   else
      set the textcolor of field "htmltext" of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

constant kControlGap = 6
constant kMaxHeight = 800
on editorResize
   lock screen
   lock messages
   local tManualHeight, tManualGroupHeight
   put getManualHeight() into tManualHeight
   if tManualHeight is not empty then
      put tManualHeight - the height of group "controls" of me - kControlGap - 1 - the height of group "background" into tManualGroupHeight
      set the height of me to tManualGroupHeight
      set the height of the owner of me to tManualGroupHeight
   end if

   set the topleft of field "rowlabel" of me to the topleft of me
   set the topright of group "controls" of me to the topright of me
   local tRect
   put the effective rect of me into tRect
   put item 2 of tRect + the height of group "controls" of me + kControlGap into item 2 of tRect
   
   local tHeight
   if tManualHeight is not empty then
      put tManualGroupHeight - kControlGap  into tHeight
   else
      put the formattedHeight of field "htmltext" of me into tHeight
      put max(tHeight, item 4 of tRect - item 2 of tRect) into tHeight
   end if
   
   put min(tHeight, kMaxHeight) into tHeight
   put item 2 of tRect + tHeight into item 4 of tRect
   set the rect of field "htmltext" of me to tRect
   
   unlock messages
   set the editorHeight of me to tHeight + kControlGap + the height of group "controls" of me
   
   set the editorExpandVertical of me to (the height of me < kMaxHeight)
   unlock screen
end editorResize

on valueChanged
   if sTextType is "styledText" then
      set the editorValue of me to the styledText of field "htmltext" of me
   else
      set the editorValue of me to field "htmltext" of me
   end if
   
   updateProperty
end valueChanged

on enterInField
   valueChanged
end enterInField

on returnInField
   if (the controlKey is down) then 
      enterInField
   else
      pass returnInField
   end if
end returnInField

on closeField
   valueChanged
end closeField

on mouseUp
   switch the short name of the target
      case "wrap text"
         local tWrap
         put not the hilite of the target into tWrap
         set the hilite of the target to tWrap
         set the dontWrap of fld "HtmlText" to not tWrap
         set the hScrollbar of fld "HtmlText" to not tWrap
         break
      case "show grid"
         local tGrid
         put not the hilite of the target into tGrid
         set the hilite of the target to tGrid
         set the hGrid of fld "HtmlText" to tGrid
         set the vGrid of fld "HtmlText" to tGrid
         if tGrid then
            set the tabStops of fld "HtmlText" to 150
            set the dontWrap of fld "HtmlText" to tGrid
            set the hScrollbar of fld "HtmlText" to tGrid
         else
            set the tabStops of fld "HtmlText" to 75
            set the dontWrap of fld "HtmlText" to not the hilite of button "wrap text"
            set the hScrollbar of fld "HtmlText" to not the hilite of button "wrap text"
         end if
         break
      case "import"
         local tFile
         revIDEAnswerFileWithTypes "text,all"
         put the result into tFile
         
         if tFile is not "cancel" then
            put textDecode(URL ("binfile:" & tFile), "utf-8") into field 1 of me
            valueChanged
         end if
         break
   end switch
end mouseUp
