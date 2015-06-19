script "com.livecode.pi.colorList.behavior"
constant COLOR_SPACE = 30

local sColorList
on editorInitialize
   set the editorMinWidth of me to the number of lines of sColorList * COLOR_SPACE
   set the editorMaxWidth of me to 0
end editorInitialize


on editorGenerate
   lock messages
   lock screen
   repeat while the number of graphics of me > 0
      delete graphic 1 of me
   end repeat
   
   set the width of the templategraphic to 21
   set the height of the templategraphic to 21
   set the opaque of the templategraphic to true
   
   repeat with x = 1 to the number of lines of sColorList
      local tColor
      put item 1 to 3 of line x of sColorList into tColor
      set the name of the templategraphic to x
      set the backgroundcolor of the templategraphic to tColor
      create graphic ("color" & x) in me
   end repeat
   
   reset the templategraphic
   unlock screen
   unlock messages
end editorGenerate

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into sColorList
   editorGenerate
   editorResize
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   
   local tLeft, tTop
   put the left of me into tLeft
   put the top of me into tTop
   
   repeat with x = 1 to the number of graphics of me
      set the left of graphic x of me to tLeft
      set the top of graphic x of me to tTop
      add COLOR_SPACE to tLeft
   end repeat
   
   unlock messages
   unlock screen
end editorResize

on mouseUp
   local tTarget
   put the short name of the target into tTarget
   if tTarget begins with "color" then
      answer color with the backgroundcolor of the target
      
      if the result is "cancel" then exit mouseUp
      local tNewColor
      put it into tNewColor
      if tNewColor is not empty then 
         replace "color" with empty in tTarget
         put tNewColor into line tTarget of sColorList
         valueChanged
      end if
   end if
end mouseUp

on valueChanged
   set the editorValue of me to sColorList
   updateProperty
end valueChanged
