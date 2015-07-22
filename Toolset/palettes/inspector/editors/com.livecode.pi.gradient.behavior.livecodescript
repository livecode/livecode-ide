script "com.livecode.pi.gradient.behavior"
local sPopupDefaults

on editorInitialize
   set the editorMinWidth of me to 25
   set the editorMaxWidth of me to 0
   
   local tPopupData, tDefaultStore
   put editorPropertyGet("popup") into tPopupData
   repeat for each element tGroup in tPopupData
      repeat for each element tProp in tGroup["proplist"]
         put tProp["default"] into sPopupDefaults[tProp["property_name"]]
         put tProp["default"] into tDefaultStore[char 9 to -1 of tProp["property_name"]]
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
      put the storedValue of me into tValue
   end if
   
   local tPopupData
   put tValue["type"] into tPopupData["Type"]["gradientType"]["value"]
   put tValue["repeat"] into tPopupData["Repeat"]["gradientRepeat"]["value"]
   put tValue["mirror"] into tPopupData["Mirror"]["gradientMirror"]["value"]
   put tValue["wrap"] into tPopupData["Wrap"]["gradientWrap"]["value"]
   put tValue["ramp"] into tPopupData["Ramp"]["gradientRamp"]["value"]
   put tValue["quality"] into tPopupData["Quality"]["gradientQuality"]["value"]
   
   set the editorPopupData of me to tPopupData
   
   local tFillData
   put tValue["type"] into tFillData["type"]
   if tValue["type"] is not "linear" then
      put the loc of graphic 1 of me into tFillData["from"]
      put the right of graphic 1 of me,item 2 of the loc of graphic 1 of me into tFillData["to"]
      put item 1 of the loc of graphic 1 of me,the bottom of graphic 1 of me into tFillData["via"]
   else
      put the topleft of graphic 1 of me into tFillData["from"]
      put the topright of graphic 1 of me into tFillData["to"]
      put the bottomleft of graphic 1 of me into tFillData["via"]
   end if
   put tValue["repeat"] into tFillData["repeat"]
   put tValue["mirror"] into tFillData["mirror"]
   put tValue["wrap"] into tFillData["wrap"]
   put tValue["ramp"] into tFillData["ramp"]
   put tValue["quality"] into tFillData["quality"]
   
   lock messages
   set the fillgradient of graphic 1 of me to tFillData
   unlock messages 
   
   unlock screen
end editorUpdate

on editorResize
   lock screen
   lock messages
   
   local tRect
   put the rect of me into tRect
   set the rect of graphic 1 of me to the rect of me
   unlock messages
   unlock screen
end editorResize

on mouseUp
   editorPopup the mouseloc
end mouseUp

on valueChanged pProperty, pValue
   local tValue
   put the editorValue of me into tValue
   if tValue is empty then
      put the storedValue of me into tValue
   end if
   
   # A gradient must have a ramp
   if tValue["ramp"] is "" then
      put defaultramp() into tValue["ramp"]
   end if
   put pValue into tValue[char 9 to -1 of pProperty]
   set the editorValue of me to tValue
   
   updateProperty
end valueChanged

private function defaultramp
   return "0,255,255,255" & return & "1,0,0,0"
end defaultramp
