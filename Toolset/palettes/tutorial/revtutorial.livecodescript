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
      case "toolbar"
         revTutorialParseSubexpression "highlight toolbar <token>", pTokens, tFirstToken, tData
         if the result is empty then
            put "toolbar" into rData["highlight type"]
            put tData[1] into rData["item"]
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
#                     STACK APPEARANCE
#
##############################################################################
local sIsInterlude
function revTutorialInterludeColor
   return "209,137,50"
end revTutorialInterludeColor

function revTutorialInterludeAltColor
   return "225,177,68"
end revTutorialInterludeAltColor

function revTutorialMessageColor
   return "55,165,196"
end revTutorialMessageColor

function revTutorialMessageAltColor
   return "75,196,216"
end revTutorialMessageAltColor

constant kMessageOriginOffset = 40
constant kMargin = 20
constant kMessageWidth = 200
constant kProgressHeight = 5

on revTutorialPositionStack pStack, pObject, pToSide, pWidthOverride
   lock screen
   lock messages
   if sIsInterlude then
      show button "Got It" of stack "revTutorial"
      put 460 into pWidthOverride
   else
      hide button "Got It" of stack "revTutorial"
   end if
   
   local tScreenRect
   put the screenrect into tScreenRect
   
   local tLeft, tRight, tTop, tBottom
   if pObject is not empty then
      local tRect
      if pStack is not empty then
         put revIDEAbsoluteRectOfObject(pStack, pObject) into tRect
      else
         put revIDERelativeRectToAbsolute(the rect of pObject, revIDEStackOfObject(pObject)) into tRect
      end if
      put item 1 of tRect into tLeft
      put item 2 of tRect into tTop
      put item 3 of tRect into tRight
      put item 4 of tRect into tBottom
      
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
   put max(100,tHeight) into tHeight
   set the height of field "Message" of stack "revTutorial" to tHeight - kMargin
   
   put the formattedWidth of field "Message" of stack "revTutorial" + kMargin * 2 into tWidth
   
   if sIsInterlude then
      put tHeight + the height of button "Got It" of stack "revTutorial" + kMargin into tHeight
   end if
   
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
   set the id of the last image to the id of stack "revIcons"
   put the long id of the last image into tWindowShape
   if sIsInterlude then
      set the backColor of stack "revTutorial" to revTutorialInterludeColor()
   else
      set the backColor of stack "revTutorial" to revTutorialMessageColor()
   end if
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
      if sIsInterlude then
         set the topleft of button "Got It" of stack "revTutorial" to tWidth - kMargin - the width of button "Got It" of stack "revTutorial", tHeight - kMargin - the height of button "Got It" of stack "revTutorial"
      end if
      
      set the rect of stack "revTutorial" to 0, 0, tWidth, tHeight
      set the topleft of field "Message" of stack "revTutorial" to kMargin, kMargin
      set the loc of stack "revTutorial" to item 3 of tScreenRect / 2, item 4 of tScreenRect / 2
   end if
   
   unlock messages
   unlock screen
end revTutorialPositionStack

##############################################################################
#
#                     MAIN FUNCTIONALITY
#
##############################################################################

local sSteps, sActionNumber, sStepName, sFirstStep, sStepNum, sNumSteps
local sWaiting
on revInitialiseTutorial pSteps
   lock screen
   lock messages
   put false into sWaiting
   put false into sIsInterlude
   put pSteps into sSteps
   
   local tStep, tNumSteps
   put pSteps["first step"] into tStep
   repeat until tStep is empty
      add 1 to tNumSteps
      put pSteps[tStep]["actions"]["go"]["step"] into tStep
   end repeat
   put tNumSteps into sNumSteps 
   
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
   set the margins of it to 0
   
   set the left of it to 20
   set the top of it to 60
   
   create button "Got It"
   set the width of it to 64
   set the height of it to 28
   set the backColor of it to revTutorialInterludeAltColor()
   set the label of it to "Got It"
   set the borderWidth of it to 0
   set the showFocusBorder of it to false
   set the autoHilite of it to false
   set the threeD of it to false
   set the visible of it to false
   
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
   
   remove script of stack "revTutorial" from front
   put empty into sSteps
   put empty into sActionNumber
   put empty into sStepName
   revIDEUnsubscribeAll
   unlock screen
end revFinaliseTutorial

on revTutorialStart pTutorialName
   local tTutorialFile
   put revIDEPaletteResourcePath("tutorials/" & pTutorialName & "/" & pTutorialName & ".txt") into tTutorialFile
   
   local tData
   put revTutorialParse(tTutorialFile) into tData
   
   revInitialiseTutorial tData
   put tData["first step"] into sFirstStep
   put 0 into sStepNum
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

function revTutorialDoneRatio
   return (sStepNum - 1) / sNumSteps
end revTutorialDoneRatio

on revTutorialPrologue
   if sSteps["prologue"] is not empty then
      revTutorialDoInterlude false
      revTutorialSetText "prologue"
   else
      send "revTutorialContinue" to stack "revTutorial" in 0 millisecs
   end if
end revTutorialPrologue

on revTutorialEpilogue
   if sSteps["epilogue"] is not empty then
      revTutorialDoInterlude true
      revTutorialSetText "epilogue"
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
      revIDEMessageSend "ideTutorialProgressChanged"
      // Skip step if wait condition satisfied
      if sSteps[sStepName]["actions"]["wait"] is not empty then
         if revTutorialCheckWaitCondition(sSteps[sStepName]["actions"]["wait"]) then
            next repeat
         end if
      end if
      // Do text, highlight and guide actions under lock screen, to remove 'flicker'
      lock screen
      // Interlude
      revTutorialExecuteAction sSteps[sStepName]["actions"]["interlude"]
      // Text
      revTutorialSetText sStepName
      // Guide
      revTutorialExecuteAction sSteps[sStepName]["actions"]["add guide"]
      // Highlight
      revTutorialExecuteAction sSteps[sStepName]["actions"]["highlight"]
      unlock screen
      show stack "revTutorial"
      // Capture
      revTutorialExecuteAction sSteps[sStepName]["actions"]["capture"]
      // Wait
      revTutorialExecuteAction sSteps[sStepName]["actions"]["wait"]
      
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
         revTutorialDoInterlude false
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
   revTutorialSetTextOfMessage  sSteps[pStep]["text"], sSteps[pStep]["script"]
end revTutorialSetText

on revTutorialSetTextOfMessage pText, pScript
   local tWidthOverride
   put 0 into tWidthOverride
   set the width of field "Message" of stack "revTutorial" to 1000
   put empty into field "Message" of stack "revTutorial"
   if pScript is not empty then
      put return & return & pScript into field "Message" of stack "revTutorial"
      put the formattedWidth of field "Message" of stack "revTutorial" into tWidthOverride
   end if
   put pText before field "Message" of stack "revTutorial"
   revTutorialPositionStack "", "", true, tWidthOverride, false
end revTutorialSetTextOfMessage

function revTutorialScriptRetry pCurrent
   local tText
   put "Your script is not quite right. You have:" & return & return after tText
   put pCurrent after tText
   put return & return after tText
   put "Set the script to the following and click the apply button:" after tText
   return tText
end revTutorialScriptRetry

##############################################################################
#
#                     ACTION IMPLEMENTATIONS
#
##############################################################################

on revTutorialDoGoToStep pStep
   put pStep into sStepName
   add 1 to sStepNum
   put 0 into sActionNumber
   revTutorialClearHighlights
   revTutorialClearGuides
   disableToolsPalette
   put false into sWaiting
   put false into sIsInterlude
end revTutorialDoGoToStep

local sCaptureData, sTaggedObjects

on revTutorialDoCapture pType, pTag
   put pTag into sCaptureData[pType]
end revTutorialDoCapture

on revTutorialDoInterlude pIsEpilogue
   put true into sIsInterlude
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
            revTutorialSnapObjectToGuide tObject, pActionData["guide"]
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
            # If the script hasn't changed then don't do anything.
            if revTutorialScriptIs(the script of tObject, sWait["current script"]) then
               break
            end if
            if revTutorialObjectPropertyIsValue(tObject, "script", pActionData["script"]) then
               return true
            else if sWait["current script"] is not empty then
               add 1 to sWait["incorrect attempts"]
               put the script of tObject into sWait["current script"]
               # Show the current script and the target script in the tip stack
               revTutorialSetTextOfMessage revTutorialScriptRetry(sWait["current script"]), pActionData["script"]
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
   put the script of pObject into sWait["current script"]
   put 0 into sWait["incorrect attempts"]
   revIDESubscribe "idePropertyChanged", pObject
end revTutorialWaitUntilObjectIsScripted

on revTutorialWaitUntilObjectIsClicked
   // Subscribe to mouseUp
end revTutorialWaitUntilObjectIsClicked

on revTutorialWaitUntilObjectIsFocused
   // Subscribe to control
end revTutorialWaitUntilObjectIsFocused

on revTutorialWaitForObject
   if sWait["object"]["type"] is "stack" then
      revIDESubscribe "ideNewStack"
   else
      revIDESubscribe "ideNewControl"
   end if
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
      revIDEHighlightObject "menubar", "standard"
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

local sHighlight
on revTutorialDoHighlight pActionData
   try
      switch pActionData["highlight type"]
         case "object"
            revTutorialHighlightObject pActionData["object"]["type"], pActionData["object"]["tag"]
            break
         case "menu"
            revTutorialHighlightMenuItem pActionData["menu"], pActionData["item"]
            break
         case "toolbar"
            revTutorialHighlightToolbarItem pActionData["item"]
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
   # Subscribe to the resumestack message so that we can respond when
   #  the wrong palette receives focus
   revIDESubscribe "ideResumeStack"
end revTutorialDoHighlight

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
   put "object" into sHighlight["type"]
   put tObject into sHighlight["object"]
   revIDESubscribe "ideMoveStack", revIDEStackOfObject(tObject)
   revIDESubscribe "idePropertyChanged", tObject
   revTutorialPositionStackForHighlight
end revTutorialHighlightObject

on revTutorialClearObjectHighlight
   /*
   repeat for each key tType in sObjectState
      repeat for each key tTag in sObjectState[tType]
         set the borderwidth of sTaggedObjects[tType][tTag] to sObjectState[tType][tTag]["borderwidth"]
         set the bordercolor of sTaggedObjects[tType][tTag] to sObjectState[tType][tTag]["bordercolor"]
      end repeat
   end repeat
   put empty into sObjectState
   */
end revTutorialClearObjectHighlight

on revTutorialHighlightTool pTool
   revIDEHighlightObject "tools", pTool
   revIDESubscribe "ideMoveStack", the name of stack revIDEPaletteToStackName("tools")
   put "tool" into sHighlight["type"]
   put pTool into sHighlight["tool"]
   revTutorialPositionStackForHighlight
end revTutorialHighlightTool

on revTutorialHighlightInspector pSection, pGroup
   local tObjectData
   put pSection into tObjectData["section"]
   put pGroup into tObjectData["group"]
   revIDEHighlightObject "inspector", tObjectData
   revIDESubscribe "ideMoveStack", the name of stack revIDEPaletteToStackName("inspector")
   put "property" into sHighlight["type"]
   put pGroup into sHighlight["group"]
   revTutorialPositionStackForHighlight
end revTutorialHighlightInspector

local sDisabled
on revTutorialHighlightMenuItem pMenu, pItem
   local tMenuHighlight
   put pItem into tMenuHighlight[pMenu]
   revIDEHighlightObject "menubar", tMenuHighlight
   revIDESubscribe "ideMoveStack", the name of stack revIDEPaletteToStackName("menubar")
   put "menu" into sHighlight["type"]
   put pMenu into sHighlight["menu"]
   revTutorialPositionStackForHighlight
end revTutorialHighlightMenuItem

on revTutorialHighlightToolbarItem pItem
   revIDEHighlightObject "menubar", pItem
   revIDESubscribe "ideMoveStack", the name of stack revIDEPaletteToStackName("menubar")
   put "toolbar" into sHighlight["type"]
   put pItem into sHighlight["item"]
   revTutorialPositionStackForHighlight
end revTutorialHighlightToolbarItem

on disableToolsPalette
   dispatch "disableTools" to stack "revTools"
end disableToolsPalette

on enableToolsPalette
   dispatch "enableTools" to stack "revTools"
end enableToolsPalette

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
   revIDESubscribe "ideMoveStack", revIDEStackOfObject(sGuides[pGuide])
   put "guide" into sHighlight["type"]
   put pGuide into sHighlight["guide"]
   revTutorialPositionStackForHighlight
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

on closeStackRequest
   local tStack
   put revIDEStackOfObject(the long id of the target) into tStack
   repeat for each element tMainstack in sTaggedObjects["stack"]
      if tMainstack is tStack then
         answer "Closing the stack will exit this tutorial. Are you sure?" with "Yes" or "No"
         if it is "No" then
            exit closeStackRequest
         end if
         send "revIDEStopTutorial" to stack "revIDELibrary" in 0 millisecs
      end if
   end repeat
   pass closeStackRequest
end closeStackRequest

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

on ideNewStack pStack
   if "stack" is among the keys of sCaptureData then
      put the long id of pStack into sTaggedObjects["stack"][sCaptureData["stack"]]
      delete variable sCaptureData["stack"]
   end if
   
   if sWait["wait condition"] is "there is an object" and sWait["object"]["type"] is "stack" and sWait["object"]["tag"] is among the keys of sTaggedObjects["stack"] then
      revTutorialWaitConditionSatisfied
   end if
end ideNewStack

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
   # If a highlighted object moved then reposition the tutorial step pointer
   if not pObject begins with "stack" and revTutorialObjectIsHighlighted(pObject) then
      revTutorialPositionStackForHighlight
   end if
   
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

on ideMoveStack pStack
   # If the highlighted stack is moved, then reposition the tutorial step pointer
   if revTutorialObjectIsHighlighted(pStack) then
      revTutorialPositionStackForHighlight
   end if
end ideMoveStack

on ideResumeStack
   local tStack
   put revIDEStackOfObject(the long id of the target) into tStack
   if not revTutorialObjectIsHighlighted(tStack) then
      # If the target stack is not highlighted then react accordingly
   else
      revTutorialPositionStackForHighlight
   end if
end ideResumeStack

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

function revTutorialObjectIsHighlighted pObject
   if sHighlight is empty then
      return false
   end if
   
   switch sHighlight["type"]
      case "guide"
         return pObject is revIDEStackOfObject(sGuides[sHighlight["guide"]])
      case "property"
         return pObject is the name of stack revIDEPaletteToStackName("inspector")
      case "menu"
         return pObject is the name of stack revIDEPaletteToStackName("menubar")
      case "tool"
         return pObject is the name of stack revIDEPaletteToStackName("tools")
      case "object"
         return pObject is sHighlight["object"] or pObject is revIDEStackOfObject(sHighlight["object"])
   end switch
   return false
end revTutorialObjectIsHighlighted

on revTutorialPositionStackForHighlight
   lock screen
   switch sHighlight["type"]
      case "guide"
         revTutorialPositionStack "", sGuides[sHighlight["guide"]], true
         break
      case "property"
         revTutorialPositionStack "inspector", sHighlight["group"], true
         break
      case "menu"
         revTutorialPositionStack "menubar", sHighlight["menu"], false
         break
      case "toolbar"
         revTutorialPositionStack "menubar", sHighlight["item"], false
         break
      case "tool"
         revTutorialPositionStack "tools", sHighlight["tool"], true
         break
      case "object"  
         revTutorialPositionStack "", sHighlight["object"], true
         break
   end switch
   unlock screen
end revTutorialPositionStackForHighlight

on revTutorialClearHighlights
   switch sHighlight["type"]
      case "tool"
         revIDEUnsubscribe "ideMoveStack", the name of stack revIDEPaletteToStackName("tools")
         break
      case "property"
         revIDEUnsubscribe "ideMoveStack", the name of stack revIDEPaletteToStackName("inspector")
         break
      case "menu"
         revIDEUnsubscribe "ideMoveStack", the name of stack revIDEPaletteToStackName("menubar")
         break
      case "object"
         revIDEUnsubscribe "idePropertyChanged", sHighlight["object"]
         revIDEUnsubscribe "ideMoveStack", revIDEStackOfObject(sHighlight["object"])
         break
      case "guide"
         revIDEUnsubscribe "ideMoveStack", revIDEStackOfObject(sGuides[sHighlight["guide"]])
         break
   end switch
   put empty into sHighlight
end revTutorialClearHighlights

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

on revTutorialSnapObjectToGuide pObject, pGuide
   local tRect
   put the rect of sGuides[pGuide] into tRect
   if pObject begins with "stack" then
      set the resizable of pObject to false
      set the width of pObject to item 3 of tRect + 1
      set the height of pObject to item 4 of tRect + 1
   else 
      set the rect of pObject to item 1 of tRect - 1, item 2 of tRect - 1, item 3 of tRect + 1, item 4 of tRect + 1
   end if
end revTutorialSnapObjectToGuide

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
