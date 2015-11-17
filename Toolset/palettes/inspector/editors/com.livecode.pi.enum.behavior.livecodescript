script "com.livecode.pi.enum.behavior"
constant kEffectiveTextColor = "100,100,100"

on editorInitialize
   set the editorMinWidth of me to 40
   set the editorMaxWidth of me to 0
   
   local tText, tOptions
   put the editorOptions of me into tOptions
   set the itemdelimiter to "|"
   repeat for each line tLine in tOptions
      if tText is empty then
         put item 1 of tLine into tText
      else
         put return & item 1 of tLine after tText
      end if
   end repeat
   set the text of button "pulldown" of me to tText
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   if tValue is empty then
      set the label of button "pulldown" of me to " "
   else
      set the label of button "pulldown" of me to tValue
   end if
   set the enabled of me to tEnabled
   if tEffective is true then
      set the textcolor of button "pulldown" of me to kEffectiveTextColor
      set the textstyle["italic"] of button "pulldown" of me to true
   else
      set the textcolor of button "pulldown" of me to empty
      set the textstyle of button "pulldown" of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the rect of button "pulldown" of me to the rect of me
   unlock messages
   unlock screen
end editorResize

on valueChanged
   local tOptions
   put the editorOptions of me into tOptions
   set the wholematches to false
   set the itemdelimiter to "|"
   repeat for each line tLine in tOptions
      if item 1 of tLine is the label of button "pulldown" of me then
         if the number of items of tLine is 2 then
            set the editorValue of me to item 2 of tLine
         else
            set the editorValue of me to item 1 of tLine
         end if
         exit repeat
      end if
   end repeat
   updateProperty
end valueChanged
