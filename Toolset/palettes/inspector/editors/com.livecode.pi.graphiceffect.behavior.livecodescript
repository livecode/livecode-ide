script "com.livecode.pi.graphiceffect.behavior"
local sPopupDefaults

on editorInitialize
   set the editorMinWidth of me to 25
   set the editorMaxWidth of me to 0
   
   local tPopupData, tDefaultStore
   put editorPropertyGet("popup") into tPopupData
   repeat for each element tGroup in tPopupData
      repeat for each element tProp in tGroup["proplist"]
         put tProp["default"] into sPopupDefaults[tProp["property_name"]]
         if tProp["property_name"] is "effectcolor" then
            put item 1 to 3 of tProp["default"] into tDefaultStore["color"]
            put item 4 of tProp["default"] into tDefaultStore["opacity"]
         else
            put tProp["default"] into tDefaultStore[char 7 to -1 of tProp["property_name"]]
         end if
      end repeat
   end repeat
   
   if the storedValue of me is empty then
      set the editorValue of me to tDefaultStore
      storeProperty
      set the editorValue of me to empty
   end if
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled, tProperty
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   if tValue is empty then
      set the hilite of button 1 of me to false
      put the storedValue of me into tValue
   else
      set the hilite of button 1 of me to true
   end if
   
   local tPopupData
   put tValue["color"] into tPopupData["Color"]["effectColor"]["value"]["popup"]
   put tValue["opacity"] into item 4 of tPopupData["Color"]["effectColor"]["value"]["popup"]
   
   put tValue["size"] into tPopupData["Size"]["effectSize"]["value"]["popup"]
   put tValue["spread"] into tPopupData["Spread"]["effectSpread"]["value"]["popup"]
   put tValue["distance"] into tPopupData["Distance"]["effectDistance"]["value"]["popup"]
   put tValue["blendMode"] into tPopupData["Blend Mode"]["effectBlendMode"]["value"]["popup"]
   put tValue["filter"] into tPopupData["Filter"]["effectFilter"]["value"]["popup"]
   put tValue["angle"] into tPopupData["Angle"]["effectAngle"]["value"]["popup"]
   set the editorPopupData of me to tPopupData
   
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
   set the rect of graphic 1 of me to the right of button 1 of me,  \
         the top of button 1 of me + 3, item 3 of tRect - 5,  \
         the bottom of button 1 of me - 3
   unlock messages
   unlock screen
end editorResize

on mouseUp
   if the long id of the target is the long id of graphic 1 of me then
      editorPopup the mouseloc
   else if the long id of the target is the long id of button 1 of me then
      toggleStore
   end if
end mouseUp

on valueChanged pProperty, pValue
   local tValue
   put the editorValue of me into tValue
   if tValue is empty then
      put the storedValue of me into tValue
   end if
   switch pProperty
      case "effectColor"
         local tColor, tOpacity, tNumItems
         put the number of items of pValue into tNumItems
         if tNumItems is 3 then
            put item 1 to 3 of pValue into tColor
            put 100 into tOpacity
         else if tNumItems is 4 then
            put item 1 to 3 of pValue into tColor
            put item 4 of pValue into tOpacity
         else if tNumItems is 2 then
            put item 2 of pValue into tOpacity
            put empty into tColor
         end if
         put tColor into tValue["color"]
         put tOpacity into tValue["opacity"]
         break
      case "effectSize"
      case "effectSpread"
      case "effectDistance"
      case "effectBlendMode"
      case "effectFilter"
      case "effectAngle"
         put pValue into tValue[char 7 to -1 of pProperty]
         break
   end switch
   set the editorValue of me to tValue
   editorUpdate
   if the hilite of button 1 of me then
      updateProperty
   else
      storeProperty
   end if
end valueChanged

on toggleStore
   if the hilite of button 1 of me then
      set the editorValue of me to the storedValue of me
   else
      storeProperty
      set the editorValue of me to empty
   end if
   editorUpdate
   updateProperty
end toggleStore
