script "com.livecode.pi.navbar.behavior"
on editorInitialize
   set the editMode of widget 1 of me to true
   set the editorMinWidth of me to 300
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   set the itemArray of widget 1 of me to tValue
   set the height of me to the desiredHeight of widget 1 of me
   set the height of widget 1 of me to the height of me
   unlock messages
   dispatch "inspectorLayout"
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the width of widget 1 of me to the width of me
   set the left of widget 1 of me to the left of me
   set the top of widget 1 of me to the top of me
   set the height of widget 1 of me to the height of me
   unlock messages
   set the editorHeight of me to the desiredHeight of widget 1 of me
   unlock screen
end editorResize

on valueChanged
   set the editorValue of me to the itemArray of widget 1 of me
   updateProperty
end valueChanged

on textEdited pValue, pNumber
   local tNames
   put the itemLabels of widget 1 of me into tNames
   put pValue into item pNumber of tNames
   set the itemLabels of widget 1 of me to tNames
   valueChanged
end textEdited

on dataChanged
   valueChanged
end dataChanged

on editField pRect, pNumber
   put revIDERelativeRectToAbsolute(pRect, the long id of widget 1 of me) into pRect
   # Work around some text alignment issues
   put item 1 of pRect - 7 into item 1 of pRect
   put item 2 of pRect + 3 into item 2 of pRect
   put item 2 of pRect + 21 into item 4 of pRect
   
   revIDECreateTransientTextField pRect, "textEdited", pNumber, item pNumber of the itemLabels of widget 1 of me
end editField

on dismissTransient
  revIDETransientTextChanged
end dismissTransient

