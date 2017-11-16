script "com.livecode.pi.geometry.behavior"
on editorInitialize
   set the editorMinWidth of me to 220
   put the editorLabel of me into field "rowlabel" of me
   set the rowShowLabel of me to false
   
   set the cMode of me to "scaling"
   
   if the platform is "MacOS" then 
      set the icon of btn "Window" to 202854
      set the top of btn "window" to 106
   else 
      set the icon of btn "Window" to 202855
      set the top of btn "Window" to 102
   end if
end editorInitialize

local sMode
setProp cMode pValue
   put pValue into sMode
   set the hilitedbuttonname of group "scaleorpos" to pValue
   if sMode is "scaling" then
      put "Width" into field "LimitX" of group "minmax" of group "Geometry Options" of me
      put "Height" into field "LimitY" of group "minmax" of group "Geometry Options" of me
      show graphic "Top" of group "content" of group "Diagram" of me
      show group "Top Object" of group "content" of group "Diagram" of me
      show graphic "Left" of group "content" of group "Diagram" of me
      show group "Left Object" of group "content" of group "Diagram" of me
   else
      put "Left" into field "LimitX" of group "minmax" of group "Geometry Options" of me
      put "Top" into field "LimitY" of group "minmax" of group "Geometry Options" of me
      hide graphic "Top" group "Diagram" of me
      hide group "Top Object" of group "content" of group "Diagram" of me
      hide graphic "Left" group "Diagram" of me
      hide group "Left Object" of group "content" of group "Diagram" of me
   end if
   editorUpdate
end cMode

/*
value array
For each of the following tElement in "moveH, moveV, scaleBottom, scaleTop, scaleLeft, scaleRight"

tValue[tElement] - { true | false }
tValue[tElement & "ObjectRef"] - { "card" | <objectID> }
tValue[tElement & "Absolute"] - { true | false }

Plus:

tValue["dontClipText"] - { true | false }
tValue["showHScroll"] - { true | false }
tValue["showVScroll"] - { true | false }

tValue["minLeft"] - <number>
tValue["maxRight"] - <number>
tValue["minTop"] - <number>
tValue["maxBottom"] - <number>

tValue["minHeight"] - <number>
tValue["maxHeight"] - <number>
tValue["minWidth"] - <number>
tValue["maxWidth"] - <number>

*/

function buttonNameToKey pButtonName
   local tPosition
   put word 1 of pButtonName into tPosition
   
   local tKey
   if sMode is "scaling" then
      put "scale" & tPosition into tKey
   else
      if tPosition is "Right" then
         put "moveH" into tKey
      else
         put "moveV" into tKey
      end if
   end if
   return tKey
end buttonNameToKey

on editorUpdate
   lock screen
   local tValue
   put the editorValue["geometry"] of me into tValue
   
   lock messages
   local tObjectId, tObjectName
   
   local tPositions
   if sMode is "scaling" then
      put "Bottom,Left,Top,Right" into tPositions
   else
      put "Bottom, Right" into tPositions
   end if
   
   local tKey, tPosition
   repeat for each item tPosition in "Bottom,Left,Top,Right"
      local tCardRelGraphic, tObjRelGraphic
      put the long id of graphic tPosition of group "content" of group "Diagram" of me into tCardRelGraphic
      put the long id of graphic (tPosition && "object") of group (tPosition && "Object") of group "content" of group "Diagram" of me into tObjRelGraphic
      
      put buttonNameToKey(tPosition) into tKey
      
      if tValue[tKey] is true then
         set the backPattern of tObjRelGraphic to the cNoSize of tObjRelGraphic
         
         local tTargetGraphic
         if tValue[tKey &"ObjectRef"] is "card" then
            put tCardRelGraphic into tTargetGraphic
         else
            put tObjRelGraphic into tTargetGraphic
         end if
         
         if tValue[tKey & "Absolute"] then 
            set the backPattern of tTargetGraphic to the cFixed of tTargetGraphic
         else 
            set the backPattern of tTargetGraphic to the cProportional of tTargetGraphic
         end if
         
         if tValue[tKey &"ObjectRef"] is not "card" then
            put tValue[tKey & "ObjectRef"] into tObjectId
            put revUniqueIDToName(tObjectId) into tObjectName
            set the cSelectedObject of button (tPosition && "Object") of group (tPosition && "Object") of group "content" of group "Diagram" of me to tObjectName
         end if
      else
         set the backPattern of tCardRelGraphic to the cNoSize of tCardRelGraphic
         set the backPattern of tObjRelGraphic to the cNoSize of tObjRelGraphic
      end if
   end repeat
   
   set the hilite of button "prevent object clipping text" of group "Geometry Options" of me to (tValue["dontClipText"] is true)
   set the enabled of group "Clipping" of group "Geometry Options" of me to (tValue["dontClipText"] is true)
   set the hilite of button "horizontal scrollbar" of group "Clipping" of group "Geometry Options" of me to (tValue["showHScroll"] is true)
   set the hilite of button "vertical scrollbar" of group "Clipping" of group "Geometry Options" of me to (tValue["showVScroll"] is true)
   
   if sMode is "scaling" then
      put tValue["minWidth"] into fld "minWidth" of group "minmax" of group "Geometry Options" of me
      put tValue["maxWidth"] into fld "maxWidth" of group "minmax" of group "Geometry Options" of me
      put tValue["minHeight"] into fld "minHeight" of group "minmax" of group "Geometry Options" of me
      put tValue["maxHeight"] into fld "maxHeight" of group "minmax" of group "Geometry Options" of me
   else
      put tValue["minLeft"] into fld "minWidth" of group "minmax" of group "Geometry Options" of me
      put tValue["maxRight"] into fld "maxWidth" of group "minmax" of group "Geometry Options" of me
      put tValue["minTop"] into fld "minHeight" of group "minmax" of group "Geometry Options" of me
      put tValue["maxBottom"] into fld "maxHeight" of group "minmax" of group "Geometry Options" of me
   end if
   
   repeat for each item tItem in "minWidth,maxWidth,minHeight,maxHeight"
      if fld tItem of group "minmax" of group "Geometry Options" of me is not empty then
         put true into tValue["limit"]
         exit repeat
      end if
   end repeat
   
   set the hilite of button "limitsize" of group "Geometry Options" of me to (tValue["limit"] is true)
   set the enabled of grp "minMax" of group "Geometry Options" of me to (tValue["limit"] is true)
   unlock messages
   unlock screen
end editorUpdate

constant kControlGap = 5
on editorResize
   set the rect of group "Diagram" of me to the effective rect of group "Diagram" of me
   set the loc of group "Diagram" of me to the loc of me
   
   set the left of field "rowLabel" of me to the left of me
   set the top of field "rowLabel" of me to the top of me
   
   set the left of group "scaleorpos" of me to the left of group "DIagram" of me + kControlGap
   set the top of group "scaleorpos" of me to the bottom of field "rowLabel" of me + kControlGap
   
   set the top of group "Diagram" of me to the bottom of group "scaleorpos" of me + kControlGap
   set the loc of group "content" of group "Diagram" of me to the loc of group "Diagram" of me
   set the bottom of group "content" of group "Diagram" of me to the bottom of group "Diagram" of me
   
   set the loc of group "Geometry Options" of me to the loc of me
   set the top of group "Geometry Options" of me to the bottom of group "DIagram" of me + kControlGap
end editorResize

on mouseUp pButton
   local tTarget
   put the short name of the target into tTarget
   
   local tValue
   put the editorValue["geometry"] of me into tValue
   
   switch tTarget
      case "scaling"
      case "positioning"
         set the cMode of me to tTarget
         break
      case "Prevent object clipping text"
         set the disabled of grp "Clipping" of group "Geometry Options" of me to not the hilite of the target
         put the hilite of the target into tValue["dontClipText"]
         setValue tValue
         break
      case "Horizontal Scrollbar"
         put the hilite of the target into tValue["showHScroll"]
         setValue tValue
         break
      case "Vertical Scrollbar"
         put the hilite of the target into tValue["showVScroll"]
         setValue tValue
         break
      case "limitsize"
         set the disabled of grp "minMax" of group "Geometry Options" of me to not the hilite of the target
         put the hilite of the target into tValue["limit"]
         if the disabled of group "minMax" of group "Geometry Options" then
            local tNames
            put "minWidth,maxWidth,minHeight,maxHeight" into tNames
            repeat for each item tField in tNames
               put empty into fld tField of group "minMax" of group "Geometry Options" of me 
               send "closeField" to fld tField of group "minMax" of group "Geometry Options" of me 
            end repeat
         end if
         break
      case "Remove All"
         answer warning "Really remove all Geometry from the selected object?" with "No" or "Yes"
         if it is "Yes" then
            put empty into tValue
            setValue tValue, "all"
         end if
         break
      default
         editorUpdate
         exit mouseUp
   end switch
end mouseUp

on mouseDown pButton
   local tTarget, tValue
   put the editorValue["geometry"] of me into tValue
   put the short name of the target into tTarget
   
   if word 1 of the target is "button" then
      switch tTarget
         case "Top Object"
         case "Left Object"
         case "Bottom Object"
         case "Right Object"
            set the cSide of me to word 1 of tTarget
            set the cCurrentButton of me to the long id of the target
            revRefreshContentsOfMenu
            popup btn "Object name" at the clickLoc   
            break
         default
            break
      end switch
   else if word 1 of the target is "graphic" then
      if pButton is 3 then
         set the cScaleName of me to the long id of the target
         popup btn "Squiggle type" at the clickLoc
      else
         local tSide
         put word 1 of the short name of the target into tSide
         
         local tKey
         put buttonNameToKey(tSide) into tKey
         
         local tGraphicID, tObjectRef
         switch tTarget
            case "Top Object"
            case "Left Object"
            case "Bottom Object"
            case "Right Object"
               put tValue[tKey & "ObjectRef"] into tObjectRef
               if the backPattern of the target is the cNoSize of the target then
                  if tObjectRef is among the items of ",card" then
                     exit mouseDown
                  end if
               end if
               
               switch the backPattern of the target
                  case the cNoSize of the target
                     set the backPattern of the target to the cFixed of the target
                     if tObjectRef is not empty then
                        put true into tValue[tKey & "Absolute"]
                        put true into tValue[tKey]
                     end if
                     break
                  case the cFixed of the target
                     set the backPattern of the target to the cProportional of the target
                     if tObjectRef is not empty then
                        put false into tValue[tKey & "Absolute"]
                     end if
                     break
                  case the cProportional of the target
                     set the backPattern of the target to the cNoSize of the target
                     if tObjectRef is not empty then
                        put false into tValue[tKey]
                     end if
                     break
               end switch
               # Cancel any card-relative geometry on the given side
               put the long id of graphic tSide of group "content" of group "Diagram" of me into tGraphicID
               set the backPattern of tGraphicID to the cNoSize of tGraphicID
               break
            case "Top"
            case "Left"
            case "Right"
            case "Bottom"
               switch the backPattern of the target
                  case the cNoSize of the target
                     set the backPattern of the target to the cFixed of the target
                     put true into tValue[tKey]
                     put true into tValue[tKey & "Absolute"]
                     put tSide into tValue[tKey &"ObjectSide"]
                     put "card" into tValue[tKey & "ObjectRef"]
                     break
                  case the cFixed of the target
                     if tSide is "Top" or tSide is "Left" then
                        set the backPattern of the target to the cNoSize of the target
                        put false into tValue[tKey]
                        setValue tValue
                        exit mouseDown
                     end if
                     set the backPattern of the target to the cProportional of the target
                     put true into tValue[tKey]
                     put false into tValue[tKey & "Absolute"]
                     put tSide into tValue[tKey &"ObjectSide"]
                     put "card" into tValue[tKey & "ObjectRef"]
                     break
                  case the cProportional of the target
                     set the backPattern of the target to the cNoSize of the target
                     put false into tValue[tKey]
                     break
               end switch
               # Cancel any object-relative geometry on the given side
               put the long id of graphic (tSide && "object") of group (tSide && "object") of group "content" of group "Diagram" of me into tGraphicID
               set the backPattern of tGraphicID to the cNoSize of tGraphicID
               break
            default 
               break
         end switch
         setValue tValue, tKey
      end if  
   end if
end mouseDown

on revRefreshContentsOfMenu
   local tCurrentButton, tSelectedObject, tControl, tObject, tStack, tList
   put the editorValue["object"] of me into tObject
   put revIDEStackOfObject(tObject) into tStack
   
   local tDefaultStack
   put the defaultStack into tDefaultStack
   set the defaultStack to tStack
   
   repeat with i = 1 to the number of controls
      put the cCurrentButton of me into tCurrentButton       
      if the long id of control i is not tObject then 
         local tMenuItem
         if the name of control i is the cSelectedObject of tCurrentButton then
            put "!r" & the name of control i into tMenuItem
         else
            put "!u" & the name of control i into tMenuItem
         end if
         
         if tList is empty then
            put tMenuItem into tList
         else
            put return & tMenuItem after tList
         end if
      end if
   end repeat
   
   set the defaultStack to tDefaultStack
   
   set the text of button "Object name" of me to tList
end revRefreshContentsOfMenu

on menuPick pWhich
   if the short name of the target is "Object Name" then
      local tSide
      put the cSide of me into tSide
      
      local tGraphicLongID
      put the long id of graphic (tSide && "object") of group (tSide && "object") of group "content" of group "Diagram" of me into tGraphicLongID
      
      
      if the backPattern of tGraphicLongID is the cNoSize of tGraphicLongID then
         set the backPattern of tGraphicLongID to the cFixed of tGraphicLongID
      end if   
      set the backPattern of grc tSide of group "content" of group "Diagram" of me to the cNoSize of grc tSide of group "content" of group "Diagram" of me
      
      local tKey
      put buttonNameToKey(tSide) into tKey
      
      local tTrue
      put the backPattern of tGraphicLongID is the cFixed of tGraphicLongID into tTrue
      
      local tValue
      put the editorValue["geometry"] of me into tValue
      put true into tValue[tKey]
      
      if tTrue then
         --fixed scaling
         put true into tValue[tKey & "Absolute"]
      else
         --proportional scaling
         put false into tValue[tKey & "Absolute"]
      end if
      put oppositeSide(tSide) into tValue[tKey & "ObjectSide"] 
      put pWhich into tValue[tKey & "ObjectRef"]
      
      # Adjust menu text
      local tMenuText
      repeat with x = 1 to the number of lines of the text of button "Object name" of me
         if pWhich is line x of button "Object name" of me then
            put "!r" & line x of button "Object name" of me into line x of tMenuText
         else
            put "!u" & line x of button "Object name" of me into line x of tMenuText 
         end if
      end repeat
      
      local tButtonTemp
      put the cCurrentButton of me into tButtonTemp
      set the cObjectList of tButtonTemp to tMenuText
      
      setValue tValue, tKey
   else if the short name of the target is "Squiggle Type" then
      lock screen
      local tScale
      put the cScaleName of me into tScale
      switch pWhich
         case "No Scaling"
            set the backPattern of tScale to the cProportional of tScale
            break
         case "Fixed Scaling"
            set the backPattern of tScale to the cNoSize of tScale
            break
         case "Proportional Scaling"
            set the backPattern of tScale to the cFixed of tScale
            break
      end switch
      send "mouseDown" to tScale
      unlock screen
   end if
end menuPick

on setValue pValue, pKey
   --if move is set, it takes precidence over scale
   --need to be sure opposite set is not enabled
   local tTurnOffGeometries
   switch pKey
      case "scaleLeft"
      case "scaleRight"
         put "moveH" into tTurnOffGeometries
         break
      case "scaleTop"
      case "scaleBottom"
         put "moveV" into tTurnOffGeometries
         break
      case "moveH"
         put "scaleLeft,scaleRight" into tTurnOffGeometries
         break
      case "moveV"
         put "scaleTop,scaleBottom" into tTurnOffGeometries
         break
      case "all"
         put "moveH,moveV,scaleLeft,scaleRight,scaleTop,scaleBottom" into tTurnOffGeometries
         break
   end switch
   repeat for each item tItem in tTurnOffGeometries
      put false into pValue[tItem]
   end repeat

   local tValue
   put the editorValue["geometry"] of me into tValue
   union pValue with tValue recursively
   set the editorValue["geometry"] of me to pValue
   updateProperty
end setValue

on closeField
   local tFieldValue
   put the text of the target into tFieldValue
   
   local tValue
   put the editorValue["geometry"] of me into tValue
   
   switch the short name of the target
      case "minWidth"
         if sMode is "scaling" then
            put tFieldValue into tValue["minWidth"]
         else
            put tFieldValue into tValue["minLeft"]
         end if
         break
      case "maxWidth"
         if sMode is "scaling" then
            put tFieldValue into tValue["maxWidth"]
         else
            put tFieldValue into tValue["maxRight"]
         end if
         break
      case "minHeight"
         if sMode is "scaling" then
            put tFieldValue into tValue["minHeight"]
         else
            put tFieldValue into tValue["minTop"]
         end if
         break
      case "maxHeight"
         if sMode is "scaling" then
            put tFieldValue into tValue["maxHeight"]
         else
            put tFieldValue into tValue["maxBottom"]
         end if
         break
   end switch
   
   setValue tValue
end closeField

function oppositeSide pSide
   switch pSide
      case "Top"
         return "Bottom"
         break
      case "Bottom"
         return "Top"
         break
      case "Right"
         return "Left"
         break
      case "Left"
      default
         return "Right"
         break
   end switch
end oppositeSide
