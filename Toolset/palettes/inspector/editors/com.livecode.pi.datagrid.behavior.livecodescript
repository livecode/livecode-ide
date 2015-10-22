script "com.livecode.pi.datagrid.behavior"
on editorInitialize
   put the rowLabel of me into field "rowlabel" of me
   set the rowShowLabel of me to false
   set the editorMinWidth of me to 200
   set the editorMaxWidth of me to 0
end editorInitialize

local sValue
on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   put tValue into sValue
   
   lock messages
   set the hilite of button "allow editing" of me to tValue["allow editing"] is true
   set the hilite of button "alternate row colors" of me to tValue["alternate row colors"] is true
   set the hilite of button "auto hilite" of me to tValue["auto hilite"] is true
   set the hilite of button "multiple lines" of me to tValue["multiple lines"] is true
   set the hilite of button "allow column resizing" of me to tValue["allow column resizing"] is true
   //set the hilite of button "fixed control height" of me to tValue["fixed control height"]
   set the hilite of button "cache controls" of me to tValue["cache controls"] is true
   set the hilite of button "persistent data" of me to tValue["persistent data"] is true
   put tValue["row height"] into field "row height" of me
   set the label of button "style" of me to tValue["style"]
   set the label of button "show hscrollbar" of me to tValue["show hscrollbar"]
   set the label of button "show vscrollbar" of me to tValue["show vscrollbar"]
   
   # Enable / disable options
   if tValue["style"] is "table" then
      disable group "row behavior" of me
      disable group "fixed control height" of me
      disable group "cache controls" of me
      
      enable group "show hscrollbar"
      enable group "allow column resizing"
   else
      enable group "row behavior" of me
      enable group "fixed control height" of me
      enable group "cache controls" of me
      
      disable group "show hscrollbar"
      disable group "allow column resizing"
   end if
   unlock messages
   unlock screen
end editorUpdate

constant kLabelFieldHeight = 21
on editorResize
   lock screen
   set the lockloc of me to true
   
   local tTop, tLeft,tRight,tWidth
   put the top of me into tTop
   put the left of me into tLeft
   put the width of me into tWidth
   
   set the width of field "rowlabel" of me  to the width of me
   set the left of field "rowlabel" of me to the left of me
   set the height of field "rowlabel" of me to kLabelFieldHeight
   add the height of field "rowlabel" of me + the palettePadding of stack "revInspector" to tTop
   repeat with x = 1 to the number of groups of me
      set the lockloc of group x of me to true 
      set the width of group x of me to tWidth
      set the topleft of  group x of me to tLeft,tTop
      send "subEditorResize" to group x of me
      add the formattedheight of group x of me + the palettePadding of stack "revInspector" to tTop
   end repeat
   
   set the lockloc of me to false
   unlock screen
end editorResize

on valueChanged
   lock screen
   local tValue
   if the label of button "style" is among the items of "form,table" then
      put the label of button "style" of me into tValue["style"]
   end if
   if the label of button "show hscrollbar" is among the items of "true,false,auto" then
      put the label of button "show hscrollbar" of me into tValue["show hscrollbar"]
   end if
    if the label of button "show vscrollbar" is among the items of "true,false,auto" then
      put the label of button "show vscrollbar" of me into tValue["show vscrollbar"]
   end if
   put the hilite of button "allow editing" of me into tValue["allow editing"]
   put the hilite of button "alternate row colors" of me into tValue["alternate row colors"]
   put the hilite of button "auto hilite" of me into tValue["auto hilite"]
   put the hilite of button "multiple lines" of me into tValue["multiple lines"]
   put the hilite of button "allow column resizing" of me into tValue["allow column resizing"]
   //put the hilite of button "fixed control height" of me into tValue["fixed control height"]
   put the hilite of button "cache controls" of me into tValue["cache controls"]
   put the hilite of button "persistent data" of me into tValue["persistent data"]
   put field "row height" of me into tValue["row height"]
   set the editorValue of me to tValue
   updateProperty
   unlock screen
end valueChanged

on dataGridRefresh
   dispatch "valueChanged"
end dataGridRefresh

on dataGridTemplateLoad
   local tCard
   set the itemdel to "card"
   put "card" && item 2 to -1 of sValue["row template"] into tCard
   
   if exists(tCard) then
      go tCard
   end if
end dataGridTemplateLoad

on dataGridBehaviorScript
   local tBehaviorObject
   set the itemdel to "card"
   put "button" && quote & "Behavior Script" & quote && "card" && item 2 to -1 of sValue["row template"] into tBehaviorObject
   
   if exists(tBehaviorObject) then
      edit the script of tBehaviorObject
   end if
end dataGridBehaviorScript
