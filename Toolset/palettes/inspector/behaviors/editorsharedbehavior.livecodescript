script "editorSharedBehavior"
before mouseUp pButton
   put "test" after msg
   if pButton is not 3 then
      pass mouseUp
   end if
end mouseUp
