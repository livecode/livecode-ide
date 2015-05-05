script "revTutorial"
##############################################################################
#
#                     DSL PARSING
#
##############################################################################

function revTutorialParse pFile
   local tTutorial
   put url("binfile:" & pFile) into tTutorial
   put textDecode(tTutorial, "utf-8") into tTutorial
   
   local tTutorialName, tCurStepName
   local tType, tSubType
   local tLineNum, tActionNum
   
   local tData, tStepData, tFirstStep
   
   put 0 into tLineNum
   put 0 into tActionNum
   repeat for each line tLine in tTutorial
      add 1 to tLineNum
      get token 1 of tLine
      
      if it is empty then 
         if tSubType is "text" then 
            put return & return after tData
         end if
         next repeat 
      end if
      
      // If we're in a type, then extract the data appropriately
      if tType is not empty then
         switch it
            case "end"
               // End the section
               if token 2 of tLine is tType then
                  if tData is not empty then
                     put tData into tStepData[tCurStepName][tSubType]
                     put empty into tData
                  end if
                  put empty into tType
                  put empty into tSubType
                  put 0 into tActionNum
               else
                  put tLine & CR after tData
               end if
               break
            case "action"
            case "script"
               // Begin a new subtype
               if tType is not "step" then
                  throw "action list not valid in" && tType && " on line" && tLineNum
               end if
               
               if tSubType is "action" then
                  throw "action list not valid in" && tType && " on line" && tLineNum
               end if
               
               if tData is not empty then
                  put tData into tStepData[tCurStepName][tSubType]
                  put empty into tData
               end if
               put it into tSubType
               next repeat
               break
            default
               // Get the data
               if tSubType is "text" then
                  if line -1 of tData is empty then
                     put word 1 to -1 of tLine after tData
                  else
                     put " " & word 1 to -1 of tLine after tData
                  end if
               else if tSubType is "script" then
                  put tLine & CR after tData
               else
                  add 1 to  tActionNum
                  put revTutorialParseAction(tLine, tLineNum) into tData
                  put tData into tStepData[tCurStepName]["actions"][tData["type"]]
                  if tData["type"] is "wait" and tData["wait condition"] is "state" and tData["state"] is "scripted" then
                     put tStepData[tCurStepName]["script"] into tStepData[tCurStepName]["actions"][tData["type"]]["script"]
                  else if tData["type"] is "interlude" then
                     put tStepData[tCurStepName]["text"] into tStepData[tCurStepName]["actions"][tData["type"]]["text"]
                  end if
                  put empty into tData
               end if 
               break
         end switch
         next repeat
      end if
      
      // Otherwise, start a new section
      switch it
         case empty
            next repeat
            break
         case "tutorial"
            put token 2 of tLine into tTutorialName
            break
         case "step"
            put token 2 of tLine into tCurStepName
            put it into tType
            put "text" into tSubType
            if tFirstStep is empty then
               put tCurStepName into tFirstStep
            end if
            break
         case "prologue"
         case "epilogue"
            put it into tType
            put it into tCurStepName
            put "text" into tSubType
            break
         default
            throw "invalid section" && it && " on line" && tLineNum
      end switch
   end repeat
   
   put tFirstStep into tStepData["first step"]
   return tStepData
end revTutorialParse

function revTutorialIsObjectType pType
   switch pType
      case "stack"
      case "graphic"
      case "button"
      case "field"
      case "image"
      case "widget"
      case "card"
         return true
   end switch
   return false
end revTutorialIsObjectType

function revTutorialIsToolType pType
   switch pType
      case "edit"
      case "run"
         return true
   end switch
   return false
end revTutorialIsToolType

function revTutorialIsStateType pType
   switch pType
      case "clicked"
      case "selected"
      case "scripted"
      case "focused"
      case "edited"
         return true
   end switch
   return false
end revTutorialIsStateType

on revTutorialParseObject pTokens, @xNextToken, @rObject
   local tObject
   if revTutorialIsObjectType(pTokens[xNextToken]) then
      put pTokens[xNextToken] into tObject["type"]
      add 1 to xNextToken
   else
      return pTokens[xNextToken] & "; expected: <object type>"
   end if
   
   if pTokens[xNextToken] is not empty then
      put pTokens[xNextToken] into tObject["tag"]
      add 1 to xNextToken
   else
      return "expected: <object tag>"
   end if
   
   put tObject into rObject
   return empty
end revTutorialParseObject

function revTutorialIsPaletteType pType
   switch pType
      case "script editor"
      case "property inspector"
         return true
   end switch
   return false
end revTutorialIsPaletteType

on revTutorialParsePalette pTokens, @xNextToken, @rPalette
   local tPalette, tName
   put pTokens[xNextToken] && pTokens[xNextToken + 1] into tName
   
   if revTutorialIsPaletteType(tName) then
      put tName into rPalette
      add 2 to xNextToken
   else
      return tName & "; expected: <palette type>"
   end if
   
   return empty
end revTutorialParsePalette

// currently is subexpression til end
on revTutorialParseSubexpression pExpected, pTokens, pStart, @rData
   local tTokenCount
   put 0 into tTokenCount
   
   local tNextToken, tNextWord
   put pStart into tNextToken
   put 1 into tNextWord
   
   local tData
   repeat forever
      switch word tNextWord of pExpected
         case  "<token>" 
            if pTokens[tNextToken] is empty then
               return "expected: <token>"
            end if
            
            add 1 to tTokenCount
            put pTokens[tNextToken] into tData[tTokenCount]
            add 1 to tNextWord
            add 1 to tNextToken
            next repeat
         case "<object>"
            local tObject
            revTutorialParseObject pTokens, tNextToken, tObject
            if the result is not empty then
               return the result
            end if
            add 1 to tTokenCount
            put tObject into tData[tTokenCount]
            add 1 to tNextWord
            next repeat
         case "<palette>"
            local tPalette
            revTutorialParsePalette pTokens, tNextToken, tPalette
            if the result is not empty then
               return the result
            end if
            add 1 to tTokenCount
            put tPalette into tData[tTokenCount]
            add 1 to tNextWord
            next repeat
         default
            break
      end switch
      
      if pTokens[tNextToken] is not word tNextWord of pExpected then
         if word tNextWord of pExpected is empty then
            return "invalid syntax:"  && pTokens[tNextToken]
         else
            return "expected:" && word tNextWord of pExpected
         end if
      else if word tNextWord of pExpected is empty then
         exit repeat
      end if
      add 1 to tNextWord
      add 1 to tNextToken
   end repeat
   put tData into rData
   return empty
end revTutorialParseSubexpression

on revTutorialParseLine pExpected, pTokens, @rData
   local tFirstToken
   put 1 into tFirstToken
   revTutorialParseSubexpression pExpected, pTokens, tFirstToken, rData
   return the result
end revTutorialParseLine

on revTutorialParseGo pTokens, @rData
   local tExpected, tData
   put "go to step <token>" into tExpected
   revTutorialParseLine tExpected, pTokens, tData
   if the result is not empty then
      return the result
   end if
   put "go" into rData["type"]
   put tData[1] into rData["step"]
   return empty
end revTutorialParseGo

on revTutorialParseInterlude pTokens, @rData
   if the number of elements of pTokens is not 1 then
      return "invalid syntax:"  && pTokens[5]
   end if
   put "interlude" into rData["type"]
   return empty
end revTutorialParseInterlude

on revTutorialParseCapture pTokens, @rData
   local tData
   revTutorialParseLine "capture the next new <token> of <object> as <token>", pTokens, tData
   if the result is empty then
      put "capture" into rData["type"]
      put tData[1] into rData["object type"]
      put tData[2] into rData["target stack"]
      put tData[3] into rData["tag"]
      return empty
   end if
   
   revTutorialParseLine "capture the next new stack as <token>", pTokens, tData
   if the result is not empty then
      return the result
   end if
   put "capture" into rData["type"]
   put "stack" into rData["object type"]
   put tData[1] into rData["tag"]
   return empty
end revTutorialParseCapture

on revTutorialParseHighlight pTokens, @rData
   local tData, tFirstToken
   put 1 into tFirstToken
   
   switch pTokens[2]
      case "menu"
         revTutorialParseSubexpression "highlight menu item <token> of menu <token>", pTokens, tFirstToken, tData
         if the result is empty then
            put "menu" into rData["highlight type"]
            put tData[1] into rData["item"]
            put tData[2] into rData["menu"]
         end if
         break
      case "tool"
         revTutorialParseSubexpression "highlight tool <token>", pTokens, tFirstToken, tData
         if the result is empty then
            put "tool" into rData["highlight type"]
            put tData[1] into rData["tool"]
         end if
         break
      case "property"
         revTutorialParseSubexpression "highlight property <token> of section <token>", pTokens, tFirstToken, tData
         if the result is empty then
            put "property" into rData["highlight type"]
            put tData[1] into rData["property"]
            put tData[2] into rData["section"]
         end if
         break
      case "guide"
         revTutorialParseSubexpression "highlight guide <token>", pTokens, tFirstToken, tData
         if the result is empty then
            put "guide" into rData["highlight type"]
            put tData[1] into rData["guide"]
         end if
         break
      default
         revTutorialParseSubexpression "highlight <object>", pTokens, tFirstToken, tData
         if the result is empty then
            put "object" into rData["highlight type"]
            put tData[1] into rData["object"]
         end if
         break
   end switch
   
   if the result is not empty then
      return the result
   end if
   put "highlight" into rData["type"]
   return empty
end revTutorialParseHighlight

on revTutorialParseAddGuide pTokens, @rData
   local tExpected, tData
   put "add guide <token> with rect <token> to <object>" into tExpected
   revTutorialParseLine tExpected, pTokens, tData
   if the result is not empty then
      return the result
   end if
   put "add guide" into rData["type"]
   put tData[1] into rData["guide"]
   put tData[2] into rData["rect"]
   put tData[3] into rData["object"]
   return empty
end revTutorialParseAddGuide

on revTutorialParseWait pTokens, @rData
   local tCondition, tType
   local tToken
   put 3 into tToken
   put "wait" into rData["type"]
   
   if pTokens[tToken] is "there" then
      
      revTutorialParseSubexpression "there is a <object>", pTokens, tToken, tCondition
      if the result is not empty then
         revTutorialParseSubexpression "there is an <object>", pTokens, tToken, tCondition
      end if
      
      if the result is empty then
         put "there is an object" into rData["wait condition"]
         put tCondition[1] into rData["object"]
         return empty
      end if
      
      revTutorialParseSubexpression "there is a <palette> for <object>", pTokens, tToken, tCondition
      
      if the result is empty then
         put "there is a palette" into rData["wait condition"]
         put tCondition[1] into rData["palette"]
         put tCondition[2] into rData["object"]
         return empty
      end if
      
      return the result
   end if
   
   if pTokens[tToken] is "the" then
      
      revTutorialParseSubexpression "the tool is <token>", pTokens, tToken, tCondition
      
      if the result is empty then
         if not revTutorialIsToolType(tCondition[1]) then
            return "invalid tool" && tCondition[1]
         end if
         put "tool" into rData["wait condition"]
         put tCondition[1] into rData["tool"]
         return empty
      end if
      
      revTutorialParseSubexpression "the <token> of <object> is <token>", pTokens, tToken, tCondition
      
      if the result is empty then
         put "property" into rData["wait condition"]
         put tCondition[1] into rData["property"]
         put tCondition[2] into rData["object"]
         put tCondition[3] into rData["value"]
      end if
      
      return the result
   end if
   
   if pTokens[tToken + 2] is "fits" then
      revTutorialParseSubexpression "<object> fits guide <token>", pTokens, tToken, tCondition
      if the result is empty then
         put "fits" into rData["wait condition"]
         put tCondition[1] into rData["object"]
         put tCondition[2] into rData["guide"]
         return empty
      end if
      
      revTutorialParseSubexpression "<object> fits guide <token> with tolerance <token>", pTokens, tToken, tCondition
      
      if the result is empty then
         put "fits" into rData["wait condition"]
         put tCondition[1] into rData["object"]
         put tCondition[2] into rData["guide"]
         put tCondition[3] into rData["tolerance"]
      end if
      return the result
   end if
   
   if pTokens[tToken + 2] is "pops" then
      revTutorialParseSubexpression "<object> pops up answer dialog", pTokens, tToken, tCondition
      if the result is empty then
         put "pops up" into rData["wait condition"]
         put tCondition[1] into rData["object"]
      end if
      return the result
   end if
   
   revTutorialParseSubexpression "<object> is <token>", pTokens, tToken, tCondition
   
   if the result is empty then
      if not revTutorialIsStateType(tCondition[2]) then
         return "invalid state" && tCondition[2] && "in wait condition"
      end if
      put "state" into rData["wait condition"]
      put tCondition[1] into rData["object"]
      put tCondition[2] into rData["state"]
      return empty
   end if
   
   if the result is not empty then
      return "invalid condition"
   end if
   
   return empty
end revTutorialParseWait

function revTutorialParseAction pLine, pLineNum
   local tTokens, tCount
   put 0 into tCount
   repeat for each token tToken in pLine
      add 1 to tCount
      put tToken into tTokens[tCount]
   end repeat
   
   local tActionData
   local tError
   switch tTokens[1]
      case "interlude"
         revTutorialParseInterlude tTokens, tActionData
         break
      case "go"
         revTutorialParseGo tTokens, tActionData
         break
      case "capture"
         revTutorialParseCapture tTokens, tActionData
         break
      case "highlight"
         revTutorialParseHighlight tTokens, tActionData
         break
      case "wait"
         revTutorialParseWait tTokens, tActionData
         break
      case "add"
         revTutorialParseAddGuide tTokens, tActionData
         break
      default
         throw "Invalid action on line" && pLineNum & "-" && the result
   end switch
   if the result is not empty then
      throw "Error in" && tTokens[1] && "action on line" && pLineNum & "-" && the result
   end if
   return tActionData
end revTutorialParseAction

##############################################################################
#
#                     MAIN FUNCTIONALITY
#
##############################################################################

constant kMessageOriginOffset = 40
constant kMargin = 10
constant kMessageWidth = 200

on revTutorialPositionStack pObject, pToSide, pIsMenu, pWidthOverride
   lock messages
   local tScreenRect
   put the screenrect into tScreenRect
   
   local tLeft, tRight, tTop, tBottom
   if pObject is not empty then
      if pIsMenu and the platform is "macos" then
         put the left of pObject + 140 into tLeft
         put the right of pObject + 140 into tRight
         put the top of pObject into tTop
         put the bottom of pObject into tBottom
      else
         local tStack
         put revIDEStackOfObject(pObject) into tStack
         
         put the left of pObject + the left of tStack into tLeft
         put the right of pObject + the left of tStack into tRight
         put the top of pObject + the top of tStack into tTop
         put the bottom of pObject + the top of tStack into tBottom
      end if
      
      local tPointerLeft, tPointerTop
      if tRight < (item 3 of tScreenRect / 2) then
         put true into tPointerLeft
      else
         put false into tPointerLeft
      end if
      
      if tTop > (item 4 of tScreenRect / 2) then
         put false into tPointerTop
      else
         put true into tPointerTop
      end if
   end if
   local tWidth, tHeight
   set the width of field "Message"of stack "revTutorial" to max(kMessageWidth, pWidthOverride)
   set the height of field "Message" of stack "revTutorial" to 1000
   put the formattedHeight of field "Message" of stack "revTutorial" + kMargin * 2 into tHeight
   put the formattedWidth of field "Message" of stack "revTutorial" + kMargin * 2 into tWidth
   
   put max(100,tHeight) into tHeight
   set the height of field "Message" of stack "revTutorial" to tHeight
   
   local tGraphic, tPointer, tGroup, tWindowShape
   set the lineSize of the templateGraphic to 0
   set the backColor of the templateGraphic to "black"
   set the opaque of the templateGraphic to true
   
   create group "Group"
   put it into tGroup
   
   create graphic "Shape" in tGroup
   put it into tGraphic
   set the style of it to "rectangle"
   set the width of it to tWidth 
   set the height of it to tHeight
   
   if pObject is not empty then
      create graphic "Pointer" in tGroup
      put it into tPointer
      set the style of tPointer to "regular"
      set the polysides of tPointer to 4
      
      local tX, tY, tStackTop, tStackLeft, tMiddle

      if pToSide is true then
         set the width of tPointer to 40
         set the height of tPointer to 30
         set the rect of stack "revTutorial" to 0, 0, tWidth + 20, tHeight
         
         put (tBottom + tTop) / 2 into tMiddle
         if tPointerTop then
            put the top of tGraphic + 40 into tY
            put tMiddle - 40 into tStackTop
         else
            put the bottom of tGraphic - 40 into tY
            put tMiddle - tHeight + 40 into tStackTop
         end if
         
         if tPointerLeft then
            put the left of tGraphic into tX
            put tRight + 5 into tStackLeft
         else
            put the right of tGraphic into tX
            put tLeft - tWidth - 25 into tStackLeft
         end if
      else
         set the width of tPointer to 30
         set the height of tPointer to 40
         set the rect of stack "revTutorial" to 0, 0, tWidth, tHeight + 20
         
         put (tRight + tLeft) / 2 into tMiddle
         if tPointerTop then
            put the top of tGraphic into tY
            put tBottom + 5 into tStackTop
         else
            put the bottom of tGraphic into tY
            put tTop - tHeight - 25 into tStackTop
         end if
         
         if tPointerLeft then
            put the left of tGraphic + 40 into tX
            put tLeft - 25 into tStackLeft
         else
            put the right of tGraphic - 40 into tX
            put tRight - tWidth - 25 into tStackLeft
         end if
      end if
      
      set the loc of tPointer to tX,tY
   end if
   reset the templateGraphic
   
   import snapshot from rect (the rect of tGroup) of tGroup
   put the long id of the last image into tWindowShape
   set the backColor of stack "revTutorial" to ideCoreEditionColour()
   delete tGroup
   
   set the windowshape of stack "revTutorial" to the id of tWindowShape
   delete tWindowShape
   
   if pObject is not empty then
      if pToSide and tPointerLeft then
         set the topleft of field "Message" of stack "revTutorial" to kMargin + 20, kMargin
      else if not pToSide and tPointerTop then
         set the topleft of field "Message" of stack "revTutorial" to kMargin, kMargin + 20
      else
         set the topleft of field "Message" of stack "revTutorial" to kMargin, kMargin
      end if
      set the topleft of stack "revTutorial" to tStackLeft, tStackTop
   else
      set the rect of stack "revTutorial" to 0, 0, tWidth, tHeight
      set the topleft of field "Message" of stack "revTutorial" to kMargin, kMargin
      set the loc of stack "revTutorial" to item 3 of tScreenRect / 2, item 4 of tScreenRect / 2
   end if
   unlock messages
end revTutorialPositionStack

local sSteps, sActionNumber, sStepName, sFirstStep
local sWaiting
on revInitialiseTutorial pSteps
   put false into sWaiting
   put pSteps into sSteps
   lock screen
   lock messages
   
   set the textStyle of stack "revTutorial" to "bold"
   set the textColor of stack "revTutorial" to "white"
   set the textsize of stack "revTutorial" to 15
   
   create field "Message"
   set the dontWrap of it to false
   set the lockText of it to true
   set the opaque of it to false
   set the showborder of it to false
   set the showFocusBorder of it to false
   set the width of it to 465
   set the cantSelect of it to true
   
   set the left of it to 20
   set the top of it to 60
   
   insert the script of stack "revTutorial" into front
   go invisible stack "revTutorial" as palette
   unlock messages
   unlock screen
end revInitialiseTutorial

on revFinaliseTutorial
   lock screen
   if there is a field "Message" then
      delete field "Message"
   end if
   if there is a button "Exit" then
      delete button "Exit"
   end if
   enableToolsPalette
   enableStack "revMenuBar"
   
   remove script of stack "revTutorial" from front
   put empty into sSteps
   put empty into sActionNumber
   put empty into sStepName
   
   unlock screen
end revFinaliseTutorial

on revTutorialStart pTutorialName
   local tTutorialFile
   put revIDEPaletteResourcePath("tutorials/" & pTutorialName & "/" & pTutorialName & ".txt") into tTutorialFile
   
   local tData
   put revTutorialParse(tTutorialFile) into tData
   
   revInitialiseTutorial tData
   put tData["first step"] into sFirstStep
   revTutorialPrologue
   show stack "revTutorial"
end revTutorialStart

on revTutorialFinish
   hide stack "revTutorial"
   lock screen
   revTutorialEpilogue
   unlock screen
   show stack "revTutorial"
end revTutorialFinish

on revTutorialPrologue
   if sSteps["prologue"] is not empty then
      revTutorialDoInterlude sSteps["prologue"]["text"], false
   else
      send "revTutorialContinue" to stack "revTutorial" in 0 millisecs
   end if
end revTutorialPrologue

on revTutorialEpilogue
   if sSteps["epilogue"] is not empty then
      revTutorialDoInterlude sSteps["epilogue"]["text"], true
   else
      send "revIDEStopTutorial" to stack "revIDELibrary" in 0 millisecs
   end if
end revTutorialEpilogue

on revTutorialContinue
   repeat forever
      hide stack "revTutorial"
      if sWaiting then
         exit repeat
      end if
      // Tutorial finished when there was no "go" step
      if sStepName is empty then
         revTutorialDoGoToStep sFirstStep
      else if sSteps[sStepName]["actions"]["go"] is empty then
         revTutorialFinish
         exit repeat
      else
         // Otherwise we're here after a wait, so go to the next step
         revTutorialExecuteAction sSteps[sStepName]["actions"]["go"]
      end if
      
      // Skip step if wait condition satisfied
      if sSteps[sStepName]["actions"]["wait"] is not empty then
         if revTutorialCheckWaitCondition(sSteps[sStepName]["actions"]["wait"]) then
            next repeat
         end if
      end if
      lock screen
      if sSteps[sStepName]["actions"]["interlude"] is empty then
         // Do text, highlight and guide actions under lock screen, to remove 'flicker'
         // Text
         revTutorialSetText sStepName
         // Guide
         revTutorialExecuteAction sSteps[sStepName]["actions"]["add guide"]
         // Highlight
         revTutorialExecuteAction sSteps[sStepName]["actions"]["highlight"]
         unlock screen
         show stack "revTutorial"
         revTutorialExecuteAction sSteps[sStepName]["actions"]["capture"]
         revTutorialExecuteAction sSteps[sStepName]["actions"]["wait"]
      else
         revTutorialExecuteAction sSteps[sStepName]["actions"]["interlude"]
         unlock screen
         show stack "revTutorial"
      end if
      if sWaiting then
         exit repeat
      end if
   end repeat
end revTutorialContinue

on revTutorialExecuteAction pActionData
   if pActionData is empty then 
      exit revTutorialExecuteAction
   end if
   
   switch pActionData["type"]
      case "highlight"
         revTutorialDoHighlight pActionData
         break
      case "capture"
         revTutorialDoCapture pActionData["object type"], pActionData["tag"]
         break
      case "interlude"
         revTutorialDoInterlude pActionData["text"], false
         break
      case "add guide"
         revTutorialDoAddGuide pActionData["guide"], pActionData["rect"], pActionData["object"]["type"], pActionData["object"]["tag"]
         break
      case "wait"
         revTutorialDoWait pActionData
         break
      case "go"
         revTutorialDoGoToStep pActionData["step"]
         break
   end switch
end revTutorialExecuteAction

on revTutorialSetText pStep
   local tWidthOverride
   put 0 into tWidthOverride
   set the width of field "Message" of stack "revTutorial" to 1000
   put empty into field "Message" of stack "revTutorial"
   if sSteps[pStep]["script"] is not empty then
      put return & return & sSteps[pStep]["script"] into field "Message" of stack "revTutorial"
      put the formattedWidth of field "Message" into tWidthOverride
   end if
   put sSteps[pStep]["text"] before field "Message" of stack "revTutorial"

   revTutorialPositionStack "", true, false, tWidthOverride
end revTutorialSetText

##############################################################################
#
#                     ACTION IMPLEMENTATIONS
#
##############################################################################

on revTutorialDoGoToStep pStep
   put pStep into sStepName
   put 0 into sActionNumber
   revTutorialClearHighlights
   revTutorialClearGuides
   if there is a button "Got It" of stack "revTutorial" then
      delete button "Got It" of stack "revTutorial"
   end if
   disableMenuBar
   disableToolsPalette
   buildMenus
   put false into sWaiting
end revTutorialDoGoToStep

local sCaptureData, sTaggedObjects

on revTutorialDoCapture pType, pTag
   put pTag into sCaptureData[pType]
end revTutorialDoCapture

on revTutorialDoInterlude pText, pIsEpilogue
   lock screen
   set the windowShape of stack "revTutorial" to 0
   lock messages
   put pText into field "Message" of stack "revTutorial"
   
   local tScreenRect
   put the screenrect into tScreenRect
   
   create button "Got It"
   set the width of it to 64
   set the height of it to 28
   set the backColor of it to "225,177,68"
   set the label of it to "Got It"
   set the borderWidth of it to 0
   set the showFocusBorder of it to false
   set the autoHilite of it to false
   set the threeD of it to false
   
   local tWidth, tHeight
   set the width of field "Message"of stack "revTutorial" to 460
   set the height of field "Message" of stack "revTutorial" to 1000
   put the formattedHeight of field "Message" of stack "revTutorial" into tHeight
   put the formattedWidth of field "Message" of stack "revTutorial" into tWidth
   
   put max(100,tHeight) into tHeight
   set the height of field "Message" of stack "revTutorial" to tHeight
   
   put tHeight + the height of button "Got It" of stack "revTutorial" + kMargin into tHeight
   
   local tGraphic, tWindowShape
   set the lineSize of the templateGraphic to 0
   set the backColor of the templateGraphic to "black"
   set the opaque of the templateGraphic to true
   
   create graphic "Shape"
   put it into tGraphic
   set the style of it to "rectangle"
   set the width of it to tWidth + kMargin * 2
   set the height of it to tHeight + kMargin * 2
   
   reset the templateGraphic
   
   import snapshot from rect (the rect of tGraphic) of tGraphic
   put the long id of the last image into tWindowShape
   set the backColor of stack "revTutorial" to "209,137,50"
   delete tGraphic
   
   set the windowshape of stack "revTutorial" to the id of tWindowShape
   delete tWindowShape
   
   set the rect of stack "revTutorial" to 0,0,tWidth + kMargin*2, tHeight + kMargin*2
   set the topleft of field "Message" of stack "revTutorial" to kMargin, kMargin
   set the loc of stack "revTutorial" to item 3 of tScreenRect / 2, item 4 of tScreenRect / 2
   set the loc of button "Got It" of stack "revTutorial" to tWidth - the width of button "Got It" of stack "revTutorial" / 2, tHeight - the height of button "Got It" of stack "revTutorial" / 2
   unlock messages
   unlock screen
   revTutorialWaitUntilInterludeIsDismissed pIsEpilogue
end revTutorialDoInterlude

##############################################################################
#
#                     WAIT CONDITION IMPLEMENTATIONS
#
##############################################################################

local sWait
on revTutorialReturnFromInterlude
   put false into sWaiting
   if sWait["epilogue"] is true then
      send "revIDEStopTutorial" to stack "revIDELibrary" in 0 millisecs
   else
      send "revTutorialContinue" to stack "revTutorial" in 0 millisecs
   end if
   put empty into sWait 
end revTutorialReturnFromInterlude

on revTutorialDoWait pActionData
   put empty into sWait
   // Check to see if wait condition is immediately satisfied
   if revTutorialCheckWaitCondition(pActionData) then
      exit revTutorialDoWait
   end if
   
   put pActionData into sWait
   put true into sWaiting
   
   switch pActionData["wait condition"]
      case "there is an object"
         revTutorialWaitForObject
         break
      case "there is a palette" 
         revTutorialWaitUntilThereIsAPaletteForObject pActionData["palette"]
         break
      case "tool"
         revTutorialWaitUntilTheToolIs
         break
      case "property"  
         revTutorialWaitUntilObjectPropertyHasValue sTaggedObjects[pActionData["object"]["type"]][pActionData["object"]["tag"]]
         break
      case "fits" 
         revTutorialWaitUntilObjectFitsGuide sTaggedObjects[pActionData["object"]["type"]][pActionData["object"]["tag"]]
         break
      case "pops up" 
         revTutorialWaitUntilAnswerDialogHasPoppedUp
         break
      case "state"
         switch pActionData["state"]
            case "clicked"
               revTutorialWaitUntilObjectIsClicked
               break
            case "scripted"
               revTutorialWaitUntilObjectIsScripted sTaggedObjects[pActionData["object"]["type"]][pActionData["object"]["tag"]]
               break
            case "focused"
               revTutorialWaitUntilObjectIsFocused
               break
            case "selected"
               revTutorialWaitUntilObjectIsSelected
               break
         end switch
         break
   end switch
end revTutorialDoWait

function revTutorialCheckWaitCondition pActionData
   if pActionData["wait condition"] is "tool" then
      return revTutorialToolIs(pActionData["tool"])
   end if
   
   local tObject
   put sTaggedObjects[pActionData["object"]["type"]][pActionData["object"]["tag"]] into tObject
   if tObject is empty then
      return false
   end if
   
   switch pActionData["wait condition"]
      case "property"
         if revTutorialObjectPropertyIsValue(tObject, pActionData["property"], pActionData["value"]) then
            return true
         end if
         break
      case "fits"
         if revTutorialObjectFitsGuide(tObject, pActionData["guide"], pActionData["tolerance"]) then
            return true
         end if
         break
      case "there is a palette"
         if revTutorialObjectHasPalette(pActionData["palette"], tObject) then
            return true
         end if
         break
      case "state"
         if pActionData["state"] is "selected" then
            if revTutorialObjectIsSelected(tObject) then
               return true
            end if
         else if pActionData["state"] is "scripted" then
            if revTutorialObjectPropertyIsValue(tObject, "script", pActionData["script"]) then
               return true
            end if
         end if
         break
   end switch
   return false
end revTutorialCheckWaitCondition

on revTutorialWaitUntilObjectIsSelected
   revIDESubscribe "ideSelectedObjectChanged"
end revTutorialWaitUntilObjectIsSelected

on revTutorialWaitUntilObjectIsScripted pObject
   revIDESubscribe "idePropertyChanged", pObject
end revTutorialWaitUntilObjectIsScripted

on revTutorialWaitUntilObjectIsClicked
   // Subscribe to mouseUp
end revTutorialWaitUntilObjectIsClicked

on revTutorialWaitUntilObjectIsFocused
   // Subscribe to control
end revTutorialWaitUntilObjectIsFocused

on revTutorialWaitForObject
   revIDESubscribe "ideNewControl"
end revTutorialWaitForObject

on revTutorialWaitUntilObjectFitsGuide pObject
   if sWait["tolerance"] is empty then
      put 1 into sWait["tolerance"]
   end if
   revIDESubscribe "idePropertyChanged", pObject
end revTutorialWaitUntilObjectFitsGuide

on revTutorialWaitUntilThereIsAPaletteForObject pPalette
   if pPalette is "property inspector" then
      revIDESubscribe "ideInspectObjects"
   else if pPalette is "script editor" then
      enable button "standard" of this card of stack "revMenuBar"
      revIDESubscribe "ideEditScript"
   end if
end revTutorialWaitUntilThereIsAPaletteForObject

on revTutorialWaitUntilTheToolIs
   // Subscribe to newTool
end revTutorialWaitUntilTheToolIs
  
on revTutorialWaitUntilObjectPropertyHasValue pObject
   revIDESubscribe "idePropertyChanged", pObject
end revTutorialWaitUntilObjectPropertyHasValue

on revTutorialWaitUntilAnswerDialogHasPoppedUp
   revIDESubscribe "ideAnswerDialogClosed"
end revTutorialWaitUntilAnswerDialogHasPoppedUp

on revTutorialWaitUntilInterludeIsDismissed pIsEpilogue
   put true into sWaiting
   put "interlude" into sWait["wait condition"]
   put pIsEpilogue into sWait["epilogue"]
end revTutorialWaitUntilInterludeIsDismissed

on revTutorialWaitConditionSatisfied
   put false into sWaiting
   put empty into sWait
   send "revTutorialContinue" to stack "revTutorial" in 0 milliseconds
end revTutorialWaitConditionSatisfied

##############################################################################
#
#                     HIGHLIGHTING IMPLEMENTATIONS
#
##############################################################################

on revTutorialDoHighlight pActionData
   try
      switch pActionData["highlight type"]
         case "object"
            revTutorialHighlightObject pActionData["object"]["type"], pActionData["object"]["tag"]
            break
         case "menu"
            revTutorialHighlightMenuItem pActionData["menu"], pActionData["item"]
            break
         case "property"
            revTutorialHighlightInspector pActionData["section"], pActionData["property"]
            break
         case "tool"
            revTutorialHighlightTool pActionData["tool"]
            break
         case "guide"
            revTutorialHighlightGuide pActionData["guide"]
            break
      end switch
   catch tError
      // Something was specified incorrectly in the tutorial file
   end try
end revTutorialDoHighlight

on revTutorialClearHighlights
   revTutorialClearMenuHighlight
   revTutorialClearObjectHighlight
end revTutorialClearHighlights

local sObjectState
on revTutorialHighlightObject pObjType, pTag
   
   local tObject
   put sTaggedObjects[pObjType][pTag] into tObject
   /*
   local tState 
   put the borderwidth of tObject into tState["borderwidth"]
   put the bordercolor of tObject into tState["bordercolor"]
   put tState into sObjectState
   set the borderwidth of tObject to 5
   set the bordercolor of tObject to "red"
   */
   revTutorialPositionStack tObject, true
end revTutorialHighlightObject

on revTutorialClearObjectHighlight
   repeat for each key tType in sObjectState
      repeat for each key tTag in sObjectState[tType]
         set the borderwidth of sTaggedObjects[tType][tTag] to sObjectState[tType][tTag]["borderwidth"]
         set the bordercolor of sTaggedObjects[tType][tTag] to sObjectState[tType][tTag]["bordercolor"]
      end repeat
   end repeat
   put empty into sObjectState
end revTutorialClearObjectHighlight

on revTutorialHighlightTool pTool
   local tTool
   switch pTool
      case "Run Mode"
         put "com.livecode.tool.Browse" into tTool
         break
      case "Edit Mode"
         put "com.livecode.tool.Pointer" into tTool
         break
      case "Create Data Grid"
         put "com.livecode.interface.classic.DataGrid" into tTool
         break
      case "Create Label Field"
         put "com.livecode.interface.classic.LabelField" into tTool
         break
      case "Create Button"
         put "com.livecode.interface.classic.Button" into tTool
         break
      case "Create Text Area"
         put "com.livecode.interface.classic.TextArea" into tTool
         break
      case "Create Field"
         put "com.livecode.interface.classic.Field" into tTool
         break
      case "Create Combo Box"
         put "com.livecode.interface.classic.ComboBox" into tTool
         break
      case "Create Option Menu"
         put "com.livecode.interface.classic.OptionMenu" into tTool
         break
      case "Create Popup Menu"
         put "com.livecode.interface.classic.Image" into tTool
         break
      case "Create Radio Button"
         put "com.livecode.interface.classic.RectangleGraphic" into tTool
         break
      case "Create Image"
         put "com.livecode.interface.classic.RectangleGraphic" into tTool
         break
      case "Create Rectangle Button"
         put "com.livecode.interface.classic.RectangleButton" into tTool
         break
      case "Create Slider"
         put "com.livecode.interface.classic.Slider" into tTool
         break
      case "Create Default Button"
         put "com.livecode.interface.classic.DefaultButton" into tTool
         break
      case "Create Scrollbar"
         put "com.livecode.interface.classic.Scrollbar" into tTool
         break
      case "Create Little Arrows"
         put "com.livecode.interface.classic.LittleArrows" into tTool
         break
      case "Create Tab Panel"
         put "com.livecode.interface.classic.TabPanel" into tTool
         break
      case "Create Checkbox"
         put "com.livecode.interface.classic.Checkbox" into tTool
         break
      case "Create Pulldown Menu"
         put "com.livecode.interface.classic.PulldownMenu" into tTool
         break
      case "Create Player"
         put "com.livecode.interface.classic.Player" into tTool
         break
      case "Create Table Field"
         put "com.livecode.interface.classic.TableField" into tTool
         break
      case "Create List Field"
         put "com.livecode.interface.classic.ListField" into tTool
         break
      case "Create Progress Bar"
         put "com.livecode.interface.classic.ProgressBar" into tTool
         break
      case "Create Regular Graphic"
         put "com.livecode.interface.classic.RegularGraphic" into tTool
         break
      case "Create Oval Graphic"
         put "com.livecode.interface.classic.OvalGraphic" into tTool
         break
      case "Create Round Rect Graphic"
         put "com.livecode.interface.classic.RoundRectGraphic" into tTool
         break
      case "Create Rectangle Graphic"
         put "com.livecode.interface.classic.RectangleGraphic" into tTool
         break
   end switch
   
   dispatch "isolateTool" to stack "revTools" with tTool
   revTutorialPositionStack the long id of button tTool of stack "revTools", true
end revTutorialHighlightTool

on revTutorialHighlightInspector pSection, pGroup
   dispatch "hiliteFrameItem" to stack "revInspector" with pSection
   dispatch "navSelected" to stack "revInspector" with pSection
   revTutorialPositionStack the long id of group pGroup of stack "revInspector", true
end revTutorialHighlightInspector

local sMenuHighlight
on revTutorialHighlightMenuItem pMenu, pItem
   revTutorialPositionStack the long id of menu pMenu, false, true
   local tMenuHighlight
   put pItem into tMenuHighlight[pMenu]
   put tMenuHighlight into sMenuHighlight
   buildMenus
end revTutorialHighlightMenuItem

on revTutorialClearMenuHighlight
   put empty into sMenuHighlight
end revTutorialClearMenuHighlight

on disableMenuBar
   disableStack "revMenuBar"
   enable menu "File"
end disableMenuBar

on disableToolsPalette
   dispatch "disableTools" to stack "revTools"
end disableToolsPalette

on enableToolsPalette
   dispatch "enableTools" to stack "revTools"
end enableToolsPalette

local sDisabled
on disableStack pStack
   repeat for each line tControl in the childControlIDs of this card of stack pStack
      if the enabled of control id tControl of this card of stack pStack then
         put true into sDisabled[pStack][tControl]
      end if
      disable control id tControl of this card of stack pStack
   end repeat
end disableStack

on enableStack pStack
   repeat for each key tControl in sDisabled[pStack]
      if sDisabled[pStack][tControl] is true then
         enable control id tControl of this card of stack pStack
      end if
      put false into sDisabled[pStack][tControl]
   end repeat
end enableStack

on buildMenus
   buildFileMenu
   buildEditMenu
end buildMenus

command buildFileMenu
   local tFile
   put "(&New Mainstack" & return after tFile
   
   put "(&New Substack" & return after tFile
   /*
   if sStep is not "stack" then
      put "(&New Substack of" && char 1 to 20 of the mainStack of the topStack & "/|New Substack" & return after tFile
   else
      put "(&New Substack" & return after tFile
   end if
   */
   put "(&Open Stack.../O" & return after tFile
   put "(Open Recent File" & return after tFile
   put revIDEGetRecentPathsAsMenu() & return after tFile
   put "(&Close/W" & return after tFile
   put "(Close and Remove From Memor&y" & return after tFile
   put "-" & return after tFile
   
   put "(Import As Control" & return after tFile
   put tab & "Image File.../>" & return after tFile
   put tab & "Audio File..." & return after tFile
   put tab & "Video File..." & return after tFile
   put tab & "Text File..." & return after tFile
   put tab & "Snapshot of Screen" & return after tFile
   put tab & "Snapshot of Selected Object" & return after tFile
   put tab & "-" & return after tFile
   put tab & "All Images in Folder..." & return after tFile
   put tab & "All Audio Files in Folder..." & return after tFile
   
   put "(New Referenced Control" & return after tFile
   put tab & "Image File..." & return after tFile
   put tab & "Quicktime-Supported File..." & return after tFile
   put tab & "-" & return after tFile
   put tab & "All Images in Folder..." & return after tFile
   put "-" & return after tFile
   
   put "(&Save/S" & return after tFile
   put "(Save &As..." & return after tFile
   put "(Move S&ubstack to File..." & return after tFile
   put "(&Revert to Saved..." & return after tFile
   put "-" & return after tFile
   
   put "(Share This Stack..." & return after tFile
   put "-" & return after tFile
   
   put"(Standalone Application Settings..." & return after tFile
   put "(Save as Standalone Application..." & return after tFile
   put "-" & return after tFile
   
   put "(P&age Setup..." & return after tFile
   put "(&Print Card.../P" & return after tFile
   put "(Print Field..." & return after tFile
   put "-" & return after tFile
   
   ## EJB 2014-08-26
   ## [[Bug 12880]]
   if the platform is "Linux" then
      put "&Quit" & return after tFile
   else
      put "E&xit" & return after tFile
   end if
   
   set the text of menu "File" to tFile
   
   if sMenuHighlight["File"] is not empty then
      set the wholematches to false
      get lineoffset(sMenuHighlight["File"], menu "File")
      enable line it of menu "File"
   end if
   enable menu "File"
end buildFileMenu

command buildEditMenu
   local tEdit
   
   local tObjectsLabel
   if word 1 of the selObj is "card" then
      put "Card" into tObjectsLabel
   else if word 1 of the selobj is not "stack" then
      put "Objects" into tObjectsLabel
   else
      put empty into tObjectsLabel
   end if
   
   local tSelectionLabel
   if the selectedImage is not empty then
      put "Image Selection" into tSelectionLabel
   else if false then
      put "Text" into tSelectionLabel
   else if true then
      put tObjectsLabel into tSelectionLabel
   else
      put empty into tSelectionLabel
   end if
   
   local tClipboardLabel
   switch the clipboard
      case "empty"
         put empty into tClipboardLabel
         break
         -- MW-2012-09-19: [[ Bug 9600 ]] Treat 'files' as 'text' clipboard type.
      case "text"
      case "files"
         if the selectedField is empty then
            put empty into tClipboardLabel
         else
            put "Text" into tClipboardLabel
         end if
         break
      case "objects"
         put "Objects" into tClipboardLabel
         break
      case "image"
         put "Image" into tClipboardLabel
         break
   end switch
   
   put "(&Undo/Z" & return after tEdit
   put "-" & return after tEdit
   put "(Cu&t" && tSelectionLabel & "/X|cut" & return after tEdit
   put "(&Copy" && tSelectionLabel & "/C|copy" & return after tEdit
   put "(&Paste"&& tClipboardLabel & "/V|paste" & return after tEdit
   put "(Paste &Unformatted/Cmd Shift Opt V" & return after tEdit
   put "(Clea&r" && tSelectionLabel & return after tEdit
   put "-" & return after tEdit
   put "(&Duplicate" && tObjectsLabel &"/D" & return after tEdit
   put "(&Replicate..." & return after tEdit
   put "-" & return after tEdit
   put "(Select All/A" & return after tEdit
   put "(Deselect All" & return after tEdit
   put "(In&vert Selection" & return after tEdit
   put "(Select Grouped Controls" & return after tEdit
   put "(Intersected Selections" & return after tEdit
   put "-" & return after tEdit
   put "(Find and Replace.../F" & return after tEdit
   put "-" & return after tEdit
   put "(Pre&ferences" after tEdit
   
   set the text of button "Edit" of stack "revMenuBar" to tEdit
   
   if sMenuHighlight["Edit"] is not empty then
      enable menu "Edit"
      set the wholematches to false
      get lineoffset(sMenuHighlight["Edit"], menu "Edit")
      enable line it of menu "Edit"
   end if
   
end buildEditMenu

##############################################################################
#
#                     GUIDE HANDLING
#
##############################################################################

local sGuides
on revTutorialDoAddGuide pTag, pRect, pObjType, pObjTag
   lock messages
   if sGuides[pTag] is empty then
      local tDefaultStack
      set the dashes of the templateGraphic to "8,3"
      set the lockloc of the templateGraphic to true
      set the cantSelect of the templateGraphic to true
      set the rect of the templateGraphic to pRect
      
      put the defaultStack into tDefaultStack
      set the defaultStack to sTaggedObjects[pObjType][pObjTag]
      create graphic // To object objtype/objtag
      put it into sGuides[pTag]
      set the defaultStack to tDefaultStack
      reset the templateGraphic
   end if
   unlock messages
end revTutorialDoAddGuide

on revTutorialHighlightGuide pGuide
   revTutorialPositionStack sGuides[pGuide], true
end revTutorialHighlightGuide

on revTutorialClearGuides
   repeat for each element tGraphic in sGuides
      delete tGraphic
   end repeat
   put empty into sGuides
end revTutorialClearGuides

##############################################################################
#
#                     MESSAGES HANDLED TO CHECK WAIT CONDITIONS
#
##############################################################################

on openField
   local tObject
   put the long id of the target into tObject
   if sWait["wait condition"] is "state" and sWait["state"] is "focused" then
      if revTutorialObjectIsTaggedObject(tObject, sWait["object"]["type"], sWait["object"]["tag"]) then
         revTutorialWaitConditionSatisfied
      end if
   end if
   pass openField
end openField

on focusIn
   local tObject
   put the long id of the target into tObject
   if sWait["wait condition"] is "state" and sWait["state"] is "focused" then
      if revTutorialObjectIsTaggedObject(tObject, sWait["object"]["type"], sWait["object"]["tag"]) then
         revTutorialWaitConditionSatisfied
      end if
   end if
   pass focusIn
end focusIn

on newStack
   if "stack" is among the keys of sCaptureData then
      put the long id of the target into sTaggedObjects["stack"][sCaptureData["stack"]]
      delete variable sCaptureData["stack"]
   end if
   
   if sWait["wait condition"] is "there is an object" and sWait["object"]["type"] is "stack" and sWait["object"]["tag"] is among the keys of sTaggedObjects["stack"] then
      revTutorialWaitConditionSatisfied
   end if
end newStack

on ideAnswerDialogClosed pObject
   if revTutorialObjectIsTaggedObject(pObject, sWait["object"]["type"], sWait["object"]["tag"]) then
      if sWait["wait condition"] is "pops up"  then
         revIDEUnsubscribe "ideAnswerDialogClosed"
         revTutorialWaitConditionSatisfied
      end if
   end if
   pass ideAnswerDialogClosed
end ideAnswerDialogClosed

on ideNewControl pObject
   local tObjType
   put word 1 of pObject into tObjType
   if tObjType is among the keys of sCaptureData then
      put the long id of pObject into sTaggedObjects[tObjType][sCaptureData[tObjType]]
      delete variable sCaptureData[tObjType]
   end if
   
   if sWait["wait condition"] is "there is an object" and sWait["object"]["type"] is tObjType and sWait["object"]["tag"] is among the keys of sTaggedObjects[tObjType] then
      revIDEUnsubscribe "ideNewControl"
      revTutorialWaitConditionSatisfied
   end if
   
end ideNewControl

on idePropertyChanged pObject
   if revTutorialObjectIsTaggedObject(pObject, sWait["object"]["type"], sWait["object"]["tag"]) then
      if sWait["wait condition"] is among the items of "property,fits" or (sWait["wait condition"] is "state" and sWait["state"] is "scripted") then
         if revTutorialCheckWaitCondition(sWait) then
            revIDEUnsubscribe "idePropertyChanged", "", sTaggedObjects[sWait["object"]["type"]][sWait["object"]["tag"]]
            revTutorialWaitConditionSatisfied
         end if
      end if
   end if
   pass idePropertyChanged
end idePropertyChanged

on mouseUp pWhich
   local tObject
   put the long id of the target into tObject
   if sWait["wait condition"] is "state" and sWait["state"] is "clicked" then
      if revTutorialObjectIsTaggedObject(tObject, sWait["object"]["type"], sWait["object"]["tag"]) then
         revTutorialWaitConditionSatisfied
      end if
   end if
   
   if sWait["wait condition"] is "interlude" then
      if tObject is the long id of button "Got It" of stack "revTutorial" then
         revTutorialReturnFromInterlude
      end if
   end if
   
   pass mouseUp
end mouseUp

on menuPick pWhich
   pass menuPick
end menuPick

on mouseDoubleUp pWhich
   if sWait["wait condition"] is "state" and sWait["state"] is "double clicked" then
      local tObject
      put the long id of the target into tObject
      if revTutorialObjectIsTaggedObject(tObject, sWait["object"]["type"], sWait["object"]["tag"]) then
         revTutorialWaitConditionSatisfied
      end if
   end if
   
   pass mouseDoubleUp
end mouseDoubleUp

on ideSelectedObjectChanged 
   if sWait["wait condition"] is "state" and sWait["state"] is "selected" then
      local tObject
      put revIDESelectedObjects() into tObject
      if revTutorialObjectIsTaggedObject(tObject, sWait["object"]["type"], sWait["object"]["tag"]) then
         revTutorialWaitConditionSatisfied
      end if
   end if
   pass ideSelectedObjectChanged
end ideSelectedObjectChanged

on ideInspectObjects pObjects
   if sWait["wait condition"] is "there is a palette" and sWait["palette"] is "property inspector" then
      if revTutorialObjectIsTaggedObject(pObjects, sWait["object"]["type"], sWait["object"]["tag"]) then
         revIDEUnsubscribe "ideInspectedObjectsChanged"
         revTutorialWaitConditionSatisfied
      end if
   end if
   pass ideInspectObjects
end ideInspectObjects

on ideEditScript pObject
   if sWait["wait condition"] is "there is a palette" and sWait["palette"] is "script editor" then
      if revTutorialObjectIsTaggedObject(the long id of pObject, sWait["object"]["type"], sWait["object"]["tag"]) then
         revIDEUnsubscribe "ideEditScript"
         revTutorialWaitConditionSatisfied
      end if
   end if
   pass ideEditScript
end ideEditScript

on newTool pTool
   if sWait["wait condition"] is "tool" then
      if revTutorialToolIs(sWait["tool"]) then
         revTutorialWaitConditionSatisfied
      end if
   end if
   pass newTool
end newTool

##############################################################################
#
#                     UTILITIES
#
##############################################################################

function revTutorialObjectIsSelected pLongID
   return pLongID is among the lines of revIDESelectedObjects()
end revTutorialObjectIsSelected

function revTutorialObjectIsTaggedObject pLongID, pType, pTag
   return sTaggedObjects[pType][pTag] is pLongID
end revTutorialObjectIsTaggedObject

function revTutorialToolIs pTool
   if pTool is "edit" and the tool is "pointer tool" then
      return true
   end if
   
   if pTool is "run" and the tool is "browse tool" then
      return true
   end if
   
   return false
end revTutorialToolIs

function revTutorialObjectPropertyIsValue pLongID, pProperty, pValue
   if pProperty ends with "color" then
      return revTutorialColorIs(the pProperty of pLongID, pValue)
   else if pProperty is "script" then
      return revTutorialScriptIs(the script of pLongID, pValue)
   else if pProperty is "name" then
      return the short name of pLongID is pValue
   end if
   
   if the pProperty of pLongID is pValue then
      return true
   end if
   return false
end revTutorialObjectPropertyIsValue

function revTutorialObjectHasPalette pPalette, pObject
   if pPalette is "property inspector" then
      return pObject is among the lines of revIDEInspectedObjects()
   end if
   
   if pPalette is "script editor" then
      return pObject is among the lines of revIDEScriptEditingObjects()
   end if
   
   return false
end revTutorialObjectHasPalette

function revTutorialObjectFitsGuide pObject, pGuide, pTolerance
   if sGuides[pGuide] is empty then
      return false
   end if
   
   local tRect
   if pObject begins with "stack" then
      put 0,0,the width of pObject, the height of pObject into tRect
   else
      put the rect of pObject into tRect
   end if
   return revTutorialRectsAreApproximatelyEqual(pTolerance, tRect, the rect of sGuides[pGuide])
end revTutorialObjectFitsGuide

// In the future we might want to add a bit more "approximity" to this.
function revTutorialScriptIs pObjScript, pTargetScript
   local tObjTokens, tTargetTokens
   repeat for each token tToken in pObjScript
      put tToken & " " after tObjTokens
   end repeat
   
   repeat for each token tToken in pTargetScript
      put tToken & " " after tTargetTokens
   end repeat
   
   return tObjTokens is tTargetTokens
end revTutorialScriptIs

constant kColorTolerance = 10
function revTutorialColorIs pColor, pTarget
   return revTutorialNumericItemsAreApproximatelyEqual(3, kColorTolerance, pColor, pTarget)
end revTutorialColorIs

function revTutorialRectsAreApproximatelyEqual pTolerance, pRect, pTarget
   return revTutorialNumericItemsAreApproximatelyEqual(4, pTolerance, pRect, pTarget)
end revTutorialRectsAreApproximatelyEqual

function revTutorialNumericItemsAreApproximatelyEqual pNumItems, pTolerance, pLeft, pRight
   local tItemNo
   repeat with tItemNo = 1 to pNumItems
      if abs(item tItemNo of pLeft - item tItemNo of pRight) > pTolerance then
         return false
      end if
   end repeat
   return true
end revTutorialNumericItemsAreApproximatelyEqual
