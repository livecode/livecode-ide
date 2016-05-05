script "com.livecode.pi.pattern.behavior"
on editorInitialize
   set the editorMinWidth of me to 24
   set the editorMaxWidth of me to 24
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   set the enabled of graphic 1 of me to tEnabled
   if tEffective then
      set the backgroundpattern of graphic 1 of me to empty
   else
      set the backgroundpattern of graphic 1 of me to tValue
   end if
   unlock messages
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the rect of graphic 1 of me to the rect of me
   unlock messages
   unlock screen
end editorResize

on valueChanged
   set the editorValue of me to the backgroundpattern of graphic 1 of me
   updateProperty
end valueChanged

on mouseUp pButton
   if pButton is not 1 then exit mouseUp
   --PM-2016-05-02: [[ Bug 17496 ]] Show the ID of the currently selected pattern
   put the backgroundpattern of graphic 1 of me into tIconID
   send "updateIDField tIconID" to card 1 of stack "revIconChooser"
   sheet "revIconChooser"
   if the cReturnValue of stack "revIconChooser" is not empty then
      set the backgroundpattern of graphic 1 of me to the cReturnValue of stack "revIconChooser"
      dispatch "valueChanged"
   end if
end mouseUp
