script "com.livecode.pi.graphiceffect.behavior"
on editorInitialize
   set the editorMinWidth of me to 25
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled, tProperty
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   local tSize, tColor, tDistance, tOpacity, tSpread
   
   put tValue["color"] into tColor
   if the number of items of tColor is not 3 then
      put 0,0,0 into tColor
   end if
   
   put tValue["distance"] into tDistance
   if tDistance > 5 then
      put 5 into tDistance
   else if tDistance < 2 then
      put 2 into tDistance
   end if
   
   put tValue["opacity"] into tOpacity
   if tOpacity < 100 then 
      put 100 into tOpacity
   else if tOpacity > 255 then
      put 255 into tOpacity
   end if
   
   put 3 into tSize
   
   put 5 into tSpread
   
   put editorPropertyGet("property_name") into tProperty
   switch tProperty
      case "dropShadow"
         set the dropshadow["opacity"] of graphic 1 of me to tOpacity
         set the dropshadow["size"] of graphic 1 of me to tSize
         set the dropshadow["color"] of graphic 1 of me to tColor
         set the dropshadow["spread"] of graphic 1 of me to tSpread
         set the dropshadow["distance"] of graphic 1 of me to tDistance
         break
      case "outerglow"
         set the outerglow["opacity"] of graphic 1 of me to tOpacity
         set the outerglow["size"] of graphic 1 of me to 6
         set the outerglow["color"] of graphic 1 of me to tColor
         set the outerglow["spread"] of graphic 1 of me to tSpread
         break
      case "innerShadow"
         set the innerShadow["opacity"] of graphic 1 of me to tOpacity
         set the innerShadow["size"] of graphic 1 of me to tSize
         set the innerShadow["color"] of graphic 1 of me to tColor
         set the innerShadow["spread"] of graphic 1 of me to tSpread
         set the innerShadow["distance"] of graphic 1 of me to 4
         break
      case "innerGlow"
         set the innerGlow["opacity"] of graphic 1 of me to tOpacity
         set the innerGlow["size"] of graphic 1 of me to 14
         set the innerGlow["color"] of graphic 1 of me to tColor
         set the innerGlow["spread"] of graphic 1 of me to 0
         break
      case "colorOverlay"
         set the colorOverlay["opacity"] of graphic 1 of me to tOpacity
         set the colorOverlay["color"] of graphic 1 of me to tColor
         break
   end switch
   
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   set the topleft of button 1 of me to the topleft of me
   
   local tRect
   put the rect of me into tRect
   set the rect of graphic 1 of me to the right of button 1 of me, item 2 of tRect + 2, item 3 of tRect - 5, item 4 of tRect - 5
   unlock messages
   unlock screen
end editorResize

on valueChanged
end valueChanged
