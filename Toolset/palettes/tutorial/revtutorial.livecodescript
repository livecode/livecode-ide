script "revTutorial"
##############################################################################
#
#                     DSL PARSING
#
##############################################################################

function revTutorialParseFile pFile
   local tData
   put url("binfile:" & pFile) into tData
   return revTutorialParseData(textDecode(tData, "utf-8"))
end revTutorialParseFile

private on parseError pError, pLineNum, @xErrors
   local tError
   put "Error on" && pLineNum & ":" && pError into tError
   if xErrors is empty then
      put tError into xErrors
   else
      put return & tError after xErrors
   end if
end parseError

function revTutorialParseData pData
   local tErrors
   local tTutorialName, tCurStepName
   local tType, tSubType
   local tLineNum, tActionNum
   
   local tData, tStepData, tFirstStep
   
   put 0 into tLineNum
   put 0 into tActionNum
   repeat for each line tLine in pData
      add 1 to tLineNum
      
      local tFirstToken, tNewType
      put token 1 of tLine into tFirstToken
      put tFirstToken into tNewType
      
      // If we're in a type, then extract the data appropriately
      if tType is not empty then
         # Don't interpret indented new lines of text elements as new sections
         if char 1 of tLine is tab then
            put empty into tNewType
         end if
         switch tNewType
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
            case "file"
            case "value"
            case "url"
               // None of the above is allowed in epilogue or prologue
               if tType is "epilogue" or tType is "prologue" then
                  parseError tNewType && "not valid in" && tType, tLineNum, tErrors
                  break
               end if
               // Fall through
            case "image"
               if tType is empty then
                  parseError tNewType && "not valid outside of step", tLineNum, tErrors
                  break
               end if
               
               // Begin a new subtype
               if tType is tSubType is "action" then
                  parseError "action list not valid in" && tType, tLineNum, tErrors
                  break
               end if
               
               if tData is not empty then
                  put tData into tStepData[tCurStepName][tSubType]
                  put empty into tData
               end if
               put tNewType into tSubType
               next repeat
               break
            default
               // Get the data
               switch tSubType
                  case "text"
                     local tTrimmedLine
                     put word 1 to -1 of tLine into tTrimmedLine
                     if tTrimmedLine is empty then
                        put return & return after tData
                     else if line -1 of tData is empty then
                        put tTrimmedLine after tData
                     else
                        put " " & tTrimmedLine after tData
                     end if
                     break
                  case "script"
                     put tLine & return after tData
                     break
                  case "file"
                  case "image"
                  case "url"
                     # File and image are single line 
                     put word 1 to -1 of tLine into tData
                     break
                  case "value"
                     # Accumulate multi-line value
                     if tData is empty then
                        put word 1 to -1 of tLine into tData
                     else
                        put return & word 1 to -1 of tLine after tData
                     end if
                     break
                  default
                     if tFirstToken is empty then
                        next repeat
                     end if
                     add 1 to  tActionNum
                     put revTutorialParseAction(tLine, tLineNum) into tData
                     if tData["type"] is "capture" then
                        # Allow multiple capture actions
                        get the number of elements of tStepData[tCurStepName]["actions"][tData["type"]]["captures"]
                        put tData into tStepData[tCurStepName]["actions"][tData["type"]]["captures"][it + 1]
                        put "capture" into tStepData[tCurStepName]["actions"][tData["type"]]["type"]
                     else
                        put tData into tStepData[tCurStepName]["actions"][tData["type"]]
                     end if
                     if tData["type"] is "wait" and tData["wait condition"] is "state" and tData["state"] is "scripted" then
                        put tStepData[tCurStepName]["script"] into tStepData[tCurStepName]["actions"][tData["type"]]["script"]
                     else if tData["type"] is "interlude" then
                        put tStepData[tCurStepName]["text"] into tStepData[tCurStepName]["actions"][tData["type"]]["text"]
                     end if
                     if tData["go"]["step"] is among the keys of tStepData then
                        parseError "circularity in step order" && it, tLineNum, tErrors
                     end if
                     put empty into tData
                     break
               end switch
               break
         end switch
         next repeat
      end if
      
      // Otherwise, start a new section
      switch tNewType
         case empty
            next repeat
            break
         case "tutorial"
            put token 2 of tLine into tTutorialName
            break
         case "step"
            put token 2 of tLine into tCurStepName
            if tCurStepName is among the keys of tStepData then
               parseError "duplicate step name" && tCurStepName, tLineNum, tErrors
            end if
            put tNewType into tType
            put "text" into tSubType
            if tFirstStep is empty then
               put tCurStepName into tFirstStep
            end if
            break
         case "prologue"
         case "epilogue"
            put tNewType into tType
            put tNewType into tCurStepName
            put "text" into tSubType
            break
         case "skip"
            if word 1 to -1 of tLine is not "skip point" then
               parseError "expected: skip point", tLineNum, tErrors
            end if
            put "true" into tStepData[tCurStepName]["skip point"]
            break
         default
            parseError "invalid section" && it, tLineNum, tErrors
            break
      end switch
   end repeat
   
   if tErrors is not empty then
      throw tErrors
      return empty
   end if
   put tFirstStep into tStepData["first step"]
   return tStepData
end revTutorialParseData

function revTutorialIsObjectType pType
   switch pType
      case "stack"
      case "graphic"
      case "button"
      case "field"
      case "image"
      case "widget"
      case "card"
      case "group"
         # Add a 'set' type for multi-tagging
      case "set"
         return true
   end switch
   return false
end revTutorialIsObjectType

function revTutorialIsToolType pType
   switch pType
      case "edit"
      case "run"
      case "graphic"
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
      case "grouped"
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
      case "tools"
      case "menubar"
      case "message box"
      case "dictionary"
      case "project browser"
      case "extension builder"
      case "preferences"
      case "standalone settings"
      case "start center"
         return true
   end switch
   return false
end revTutorialIsPaletteType

function revTutorialIsPaletteTypeForObject pType
   switch pType
      case "script editor"
      case "inspector"
         return true
   end switch
   return false
end revTutorialIsPaletteTypeForObject

on revTutorialParsePalette pNoObject, pTokens, @xNextToken, @rPalette
   local tPalette, tName, tCount
   put pTokens[xNextToken] into tName
   put 1 into tCount
   
   local tValidPalette
   repeat
      if pNoObject then
         put revTutorialIsPaletteType(tName) into tValidPalette
      else
         put revTutorialIsPaletteTypeForObject(tName) into tValidPalette
      end if
      if tValidPalette then
         add tCount to xNextToken
         put tName into rPalette
         return empty
      end if
      add 1 to xNextToken
      if pTokens[xNextToken] is empty then
         exit repeat
      end if
      put " " & pTokens[xNextToken] after tName
   end repeat
   
   return tName & "; expected: <palette type>"
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
      local tNext
      put segment tNextWord of pExpected into tNext
      switch tNext
         case "<token>" 
         case "<value>"
            if tNext is "<token>" and pTokens[tNextToken] is empty then
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
         case "<objpalette>"
            local tPalette
            revTutorialParsePalette tNext is "<palette>", pTokens, tNextToken, tPalette
            if the result is not empty then
               return the result
            end if
            add 1 to tTokenCount
            put tPalette into tData[tTokenCount]
            add 1 to tNextWord
            next repeat
         case "<objlist>"
            local tObj, tObjectsA, tResult
            repeat forever
               revTutorialParseObject pTokens, tNextToken, tObj
               put the result into tResult
               if tResult is not empty then
                  exit repeat
               end if
               get the number of elements in tObjectsA
               put tObj into tObjectsA[it + 1]
               if pTokens[tNextToken] is not "," then
                  exit repeat
               end if
               # Skip the comma
               add 1 to tNextToken
            end repeat
            if tObjectsA is empty then
               return tResult
            end if
            add 1 to tTokenCount
            put tObjectsA into tData[tTokenCount]
            add 1 to tNextWord
            break
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
   local tData
   revTutorialParseLine "go to lesson <token>", pTokens, tData
   if the result is empty then
      put "go to lesson" into rData["type"]
      put tData[1] into rData["step"]
      return empty
   end if
   
   revTutorialParseLine "go to step <token>", pTokens, tData
   if the result is empty then
      put "go" into rData["type"]
      put tData[1] into rData["step"]
      return empty
   end if
   return the result
end revTutorialParseGo

on revTutorialParseInterlude pTokens, @rData
   if the number of elements of pTokens is not 1 then
      return "invalid syntax:"  && pTokens[5]
   end if
   put "interlude" into rData["type"]
   return empty
end revTutorialParseInterlude

on revTutorialParseLoad pTokens, @rData
   local tData
   revTutorialParseLine "load lesson <token>", pTokens, tData
   if the result is empty then
      put "load" into rData["type"]
      put tData[1] into rData["lesson"]
      return empty
   end if
   
   revTutorialParseLine "load stack <token>", pTokens, tData
   if the result is empty then
      put "load" into rData["type"]
      put tData[1] into rData["stack"]
      return empty
   end if
   
   return the result
end revTutorialParseLoad

on revTutorialParseCapture pTokens, @rData
   local tData
   revTutorialParseLine "capture set <objlist> as <token>", pTokens, tData
   if the result is empty then
      put "set" into rData["type"]
      put tData[1] into rData["objects"]
      put tData[2] into rData["tag"]
      return empty
   end if
   
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

on revTutorialParseMenuHighlight pTokens, pStart, @rData
   local tMenuString, tSubMenuString
   put "menu <token>" into tMenuString
   put "menu item <token> of" into tSubMenuString
   
   local tMenuSegmentCount, tSubMenuSegmentCount
   put the number of segments in tSubmenuString into tSubMenuSegmentCount
   put the number of segments in tMenuString into tMenuSegmentCount
   
   local tSubMenuTry, tSubMenuExpressionTry, tExpressionTry
   put 0 into tSubMenuTry
   repeat while the number of elements in pTokens > \
         tMenuSegmentCount +  tSubMenuSegmentCount * tSubMenuTry
      put "highlight " into tExpressionTry
      if tSubMenuTry is not 0 then
         put tSubMenuExpressionTry after tExpressionTry
      end if
      put tMenuString after tExpressionTry
      revTutorialParseSubexpression tExpressionTry, pTokens, pStart, rData
      if the result is empty then
         return empty
      end if
      put tSubMenuString & " " after tSubMenuExpressionTry
      add 1 to tSubMenuTry
   end repeat
   
   return "Expected: highlight [menu item <token> of...] menu <token>"
end revTutorialParseMenuHighlight

on revTutorialParseHighlight pTokens, @rData
   local tData, tFirstToken
   put 1 into tFirstToken
   
   switch pTokens[2]
      case "menu"
         revTutorialParseMenuHighlight pTokens, tFirstToken, tData
         if the result is empty then
            put "menu" into rData["highlight type"]
            local tNumElements
            put the number of elements in tData into tNumElements
            repeat with x = 1 to tNumElements - 1
               put tData[x] into rData["item"][tNumElements - x]
            end repeat
            put tData[tNumElements] into rData["menu"]
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
      case "line"
         revTutorialParseSubexpression "highlight line <token> of script editor for <object>", pTokens, tFirstToken, tData
         if the result is empty then
            put "script line" into rData["highlight type"]
            put tData[1] into rData["line"]
            put tData[2] into rData["object"]
         end if
         break
      default
         revTutorialParseSubexpression "highlight <object>", pTokens, tFirstToken, tData
         if the result is empty then
            put "object" into rData["highlight type"]
            put tData[1] into rData["object"]
            break
         end if
         
         revTutorialParseSubexpression "highlight <token> of <objpalette> for <object>", pTokens, tFirstToken, tData
         if the result is empty then
            put "item of palette for object" into rData["highlight type"]
            put tData[1] into rData["item"]
            put tData[2] into rData["palette"]
            put tData[3] into rData["object"]
            break
         end if
         
         revTutorialParseSubexpression "highlight <token> of <palette>", pTokens, tFirstToken, tData
         if the result is empty then
            put "item of palette" into rData["highlight type"]
            put tData[1] into rData["item"]
            put tData[2] into rData["palette"]
            break
         end if
         
         revTutorialParseSubexpression "highlight <objpalette> for <object>", pTokens, tFirstToken, tData
         if the result is empty then
            put "palette for object" into rData["highlight type"]
            put tData[1] into rData["palette"]
            put tData[2] into rData["object"]
            break
         end if
         
         revTutorialParseSubexpression "highlight <palette>", pTokens, tFirstToken, tData
         if the result is empty then
            put "palette" into rData["highlight type"]
            put tData[1] into rData["palette"]            
         end if
         break
         
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
      
      revTutorialParseSubexpression "there is a <objpalette> for <object>", pTokens, tToken, tCondition
      if the result is not empty then
         revTutorialParseSubexpression "there is an <objpalette> for <object>", pTokens, tToken, tCondition
      end if
      
      if the result is empty then
         put "there is a palette for object" into rData["wait condition"]
         put tCondition[1] into rData["palette"]
         put tCondition[2] into rData["object"]
         return empty
      end if
      
      revTutorialParseSubexpression "there is a <palette>", pTokens, tToken, tCondition
      if the result is not empty then
         revTutorialParseSubexpression "there is an <palette>", pTokens, tToken, tCondition
      end if
      
      if the result is empty then
         put "there is a palette" into rData["wait condition"]
         put tCondition[1] into rData["palette"]
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
      
      revTutorialParseSubexpression "the <token> of <object> is changed with default <value>", pTokens, tToken, tCondition
      
      if the result is empty then
         put "property" into rData["wait condition"]
         put tCondition[1] into rData["property"]
         put tCondition[2] into rData["object"]
         put tCondition[3] into rData["default"]
         put true into rData["is not"]
         return empty
      end if
      
      revTutorialParseSubexpression "the <token> of <object> is <value>", pTokens, tToken, tCondition
      
      if the result is empty then
         put "property" into rData["wait condition"]
         put tCondition[1] into rData["property"]
         put tCondition[2] into rData["object"]
         put tCondition[3] into rData["value"]
         put false into rData["is not"]
         return empty
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
   
   if pTokens[tToken] is "this" then
      revTutorialParseSubexpression "this card is <token>", pTokens, tToken, tCondition
      if the result is empty then
         put "this card" into rData["wait condition"]
         put tCondition[1] into rData["card"]
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
      case "load"
         revTutorialParseLoad tTokens, tActionData
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

constant kMaxScriptHeight = 200

local sDontShow
local sLastShape
on revTutorialPositionStack pStack, pObject, pWidthOverride, pForceVertical, pTopLeftOverride
   if pTopLeftOverride is not empty then
      revTutorialSetTopLeftOverride true
   end if
   
   local tGotItButtonID, tCopyButtonID, tDoItButtonID
   local tMsgFieldID, tScriptFieldID, tImageID
   local tActionButton
   
   put the long id of button "Got It" of stack "revTutorial" into tGotItButtonID
   put the long id of button "Do It For Me" of stack "revTutorial" into tDoItButtonID
   put the long id of button "Copy Script" of stack "revTutorial" into tCopyButtonID
   put the long id of field "Message" of stack "revTutorial" into tMsgFieldID
   put the long id of field "Script" of stack "revTutorial" into tScriptFieldID
   put the long id of image "Image" of stack "revTutorial" into tImageID
   
   local tHasUrl, tUrlControlID
   if revIDEBrowserWidgetUnavailable() then
      put the long id of field "Url" of stack "revTutorial" into tUrlControlID
      put the text of tUrlControlID is not empty into tHasUrl
   else
      put the long id of widget "Browser" of stack "revTutorial" into tUrlControlID
      put the url of tUrlControlID is not empty into tHasUrl
   end if
   
   lock screen
   lock messages
   local tDefaultStack
   put the defaultStack into tDefaultStack
   set the defaultstack to "revTutorial"
   if sIsInterlude then
      put tGotItButtonID into tActionButton
      put max(pWidthOverride, 460) into pWidthOverride
   else
      hide tGotItButtonID
   end if
   
   local tHasScript
   if the text of tScriptFieldID is empty then
      put false into tHasScript
      hide tScriptFieldID
      hide tCopyButtonID
   else
      put true into tHasScript
      show tScriptFieldID
      put tCopyButtonID into tActionButton
   end if
   
   # If this is a non-script action step, show the 'Do It For Me' button
   if sIsInterlude or tHasScript or \
         revTutorialCanSkipStep() is not true then
      hide tDoItButtonID
   else
      put tDoItButtonID into tActionButton
   end if
   
   local tHasImage
   if the filename of tImageID is not empty then
      put true into tHasImage
      set the height of tImageID to the formattedHeight of tImageID
      set the width of tImageID to the formattedWidth of tImageID
      show tImageID
   else
      hide tImageID
   end if
   
   if tHasUrl then
      show tUrlControlID
   else
      hide tUrlControlID
   end if
   
   local tPointVertical
   put pStack is "menubar" or pForceVertical into tPointVertical
   
   local tRect, tHasPointer
   local tLeft, tRight, tTop, tBottom
   if pObject is not empty then
      if pStack is not empty then
         if there is a stack pStack then
            put revIDEAbsoluteRectOfObject(pStack, pObject) into tRect
         else
            put revIDEAbsoluteRectOfPaletteObject(pStack, pObject) into tRect
         end if
      else
         put revIDERelativeRectToAbsolute(the rect of pObject, revIDEStackOfObject(pObject)) into tRect
      end if
      put true into tHasPointer
   else if pStack is not empty then
      if there is not a stack pStack then
         put the long id of stack revIDEPaletteToStackName(pStack) into pStack
      end if
      put the rect of pStack into tRect
      put true into tHasPointer
   end if
   
   local tContentWidth, tContentHeight 
   local tMessageHeight, tMessageWidth
   if pWidthOverride is not empty then
      put max(kMessageWidth, pWidthOverride) into tMessageWidth
      set the width of tMsgFieldID to tMessageWidth
   end if
   
   set the height of tMsgFieldID to 1000
   put the formattedHeight of tMsgFieldID into tMessageHeight
   
   set the height of tMsgFieldID to tMessageHeight
   
   put tMessageHeight + kMargin * 2 into tContentHeight
   put the formattedWidth of tMsgFieldID + kMargin * 2 into tContentWidth
   
   if tHasScript then
      local tScriptHeight
      if pWidthOverride is not empty then
         set the width of tScriptFieldID to pWidthOverride
      end if
      set the height of tScriptFieldID to 1000
      
      put the formattedHeight of tScriptFieldID into tScriptHeight
      if tScriptHeight > kMaxScriptHeight then
         set the vscrollbar of tScriptFieldID to true
         put kMaxScriptHeight into tScriptHeight
      else
         set the vscrollbar of tScriptFieldID to false
      end if
      
      set the height of tScriptFieldID to tScriptHeight
      add tScriptHeight + kMargin * 2 to tContentHeight
      
      put max(tContentWidth, the width of tScriptFieldID + kMargin * 2) into tContentWidth
   end if
   
   if tHasUrl then
      add the height of tUrlControlID + kMargin * 2 to tContentHeight
      put max(tContentWidth, the width of tUrlControlID + kMargin * 2) into tContentWidth
   end if
   
   if tActionButton is not empty then
      set the height of tActionButton to the formattedHeight of tActionButton
      set the width of tActionButton to the formattedWidth of tActionButton
      show tActionButton
      add the height of tActionButton + kMargin to tContentHeight
   end if
   
   if tHasImage then
      add the formattedheight of tImageID + kMargin * 2 to tContentHeight
      put max(tContentWidth, the formattedwidth of tImageID + kMargin * 2) into tContentWidth
   end if
   
   # Work out what screen the tutorial stack should be on
   local tScreenRect
   if exists(pStack) then
      local tScreen
      put the screen of pStack into tScreen
      put line tScreen of the working screenrects into tScreenRect
   else
      put the working screenrect into tScreenRect
   end if
   
   local tPointer
   if tHasPointer then
      if not revTutorialIsDraggingWindow() then
         if pTopLeftOverride is empty then
            put revTutorialPointerCompute(tContentWidth, tContentHeight, tScreenRect, tRect, tPointVertical) \ 
                  into tPointer
         else
            put revTutorialPointerComputeForTopLeft(tContentWidth, tContentHeight, tRect, pTopLeftOverride) \ 
                  into tPointer
         end if
      else
         put revTutorialGetPointer() into tPointer
         revTutorialSetPointer empty
      end if
   end if
   
   if revTutorialPointerDifferent(tPointer) then
      if tPointer is not empty then
         // Create the windowshape for the stack and pointer
         revTutorialCreateStack tContentWidth, tContentHeight, tPointer
      else      
         set the windowshape of stack "revTutorial" to empty
         set the decorations of stack "revTutorial" to empty
      end if
   end if
   
   revTutorialSetPointer tPointer
   
   local tMessageLeft, tMessageTop
   put kMargin into tMessageLeft
   put kMargin into tMessageTop
   
   local tWidth, tHeight
   if tPointer is not empty then
      revTutorialPositionStackAndPointer tContentWidth, tContentHeight, tRect, tPointer, tWidth, tHeight
      add revTutorialPointerLeftOverhang(tPointer) to tMessageLeft
      add revTutorialPointerTopOverhang(tPointer) to tMessageTop
   else
      put tContentWidth into tWidth
      put tContentHeight into tHeight
      set the rect of stack "revTutorial" to 0, 0, tContentWidth, tContentHeight
      if pTopLeftOverride is empty then
         set the loc of stack "revTutorial" to item 3 of tScreenRect / 2, item 4 of tScreenRect / 2
      else
         set the topleft of stack "revTutorial" to pTopLeftOverride
      end if
      revTutorialSetEffectiveTopLeft the topleft of stack "revTutorial"
   end if
   
   if tActionButton is not empty then
      local tButtonBottom, tButtonRight
      put tWidth - kMargin into tButtonRight
      put tHeight - kMargin into tButtonBottom
      
      subtract revTutorialPointerRightOverhang(tPointer, tContentWidth) from tButtonRight
      subtract revTutorialPointerBottomOverhang(tPointer, tContentHeight) from tButtonBottom
      set the bottomright of tActionButton to tButtonRight,tButtonBottom
   end if
   
   if sIsInterlude then
      set the backColor of stack "revTutorial" to revTutorialInterludeColor()
   else
      set the backColor of stack "revTutorial" to revTutorialMessageColor()
   end if
   
   set the topleft of tMsgFieldID to tMessageLeft, tMessageTop
   local tOtherTop
   put kMargin + the bottom of tMsgFieldID into tOtherTop
   if tHasScript then
      set the topleft of tScriptFieldID to tMessageLeft, tOtherTop 
   else if tHasImage then
      set the loc of tImageID to the loc of this card of stack "revTutorial"
      set the top of tImageID to tOtherTop
   else if tHasUrl then
      set the loc of tUrlControlID to the loc of this card of stack "revTutorial"
      set the top of tUrlControlID to tOtherTop
   end if
   set the defaultstack to tDefaultStack
   unlock messages
   unlock screen
end revTutorialPositionStack

local sEffectiveTopLeft
private command revTutorialSetEffectiveTopLeft pStackTopLeft
   put pStackTopLeft into sEffectiveTopLeft
end revTutorialSetEffectiveTopLeft

private function revTutorialGetEffectiveTopLeft
   return sEffectiveTopLeft
end revTutorialGetEffectiveTopLeft

local sTopLeftOverride
private function revTutorialTopLeftOverride
   if sTopLeftOverride then
      return revTutorialGetEffectiveTopLeft()
   end if
   
   return empty
end revTutorialTopLeftOverride

private command revTutorialSetTopLeftOverride pValue
   put pValue into sTopLeftOverride
end revTutorialSetTopLeftOverride

command revTutorialPositionStackAndPointer pContentWidth, pContentHeight, pHighlightRect, pPointer, @rWidth, @rHeight
   local tStackLeft, tStackTop, tWidth, tHeight
   revTutorialPointerStackPosition pContentWidth, pContentHeight, pHighlightRect, pPointer, tStackLeft, tStackTop
   revTutorialPointerStackSize pContentWidth, pContentHeight, pPointer, tWidth, tHeight
   set the rect of stack "revTutorial" to 0, 0, tWidth, tHeight
   set the topleft of stack "revTutorial" to tStackLeft, tStackTop
   
   put tWidth into rWidth
   put tHeight into rHeight
end revTutorialPositionStackAndPointer   

command revTutorialCreateStack pContentWidth, pContentHeight, pPointer
   # Store templategraphic props (in case we have a graphic tool selected)
   local tProps
   put the properties of the templategraphic into tProps
   
   reset the templategraphic
   reset the templategroup
   
   local tGraphic, tPointer, tGroup, tWindowShape
   set the lineSize of the templateGraphic to 0
   set the backColor of the templateGraphic to "black"
   set the opaque of the templateGraphic to true
   
   # Ensure the window does not have a 1-bit mask
   set the blendlevel of the templateGraphic to 1
   
   create group "Group"
   put it into tGroup
   set the margins of it to 0
   
   create graphic "Shape" in tGroup
   put it into tGraphic
   set the style of it to "rectangle"
   set the width of it to pContentWidth
   set the height of it to pContentHeight
   set the topleft of it to 0,0
   
   create graphic "Pointer" in tGroup
   put it into tPointer
   
   revTutorialPointerSetGraphicProps tPointer, tGraphic, pPointer, pContentWidth, pContentHeight
   
   set the rect of stack "revTutorial" to the formattedRect of tGroup
   if revTutorialIsDraggingWindow() then
      set the visible of tPointer to false
   end if
   
   set the topleft of tGroup to 0,0
   
   reset the templateGraphic
   set the properties of the templategraphic to tProps
   
   import snapshot from rect (the rect of tGroup) of tGroup
   
   set the id of the last image to the id of stack "revIcons"
   put the long id of the last image into tWindowShape
   set the topleft of tWindowShape to 0,0
   delete tGroup
   
   set the windowshape of stack "revTutorial" to the id of tWindowShape
   delete tWindowShape
   
end revTutorialCreateStack

##############################################################################
#
#                     POINTER MANAGEMENT
#
##############################################################################

constant kPointerHeight = 30
constant kPointerWidth = 40
constant kPointerOffset = 40
constant kPointerPadding = 5
private command revTutorialPointerSetGraphicProps pPointerObj, pContentGraphic, pPointer, pContentWidth, pContentHeight
   local tSide, tPos, tSource
   put revTutorialPointerSide(pPointer) into tSide
   put revTutorialPointerPositionOnSide(pPointer) into tPos
   put revTutorialPointerSource(pPointer, pContentWidth, pContentHeight) into tSource
   
   if pPointer["style"] is "original" then
      set the style of pPointerObj to "regular"
      set the polysides of pPointerObj to 4
      
      if revTutorialPointerVertical(pPointer) then
         set the width of pPointerObj to kPointerHeight
         set the height of pPointerObj to kPointerWidth
      else
         set the width of pPointerObj to kPointerWidth
         set the height of pPointerObj to kPointerHeight
      end if
      
      set the loc of pPointerObj to \ 
            the left of pContentGraphic + item 1 of tSource, \
            the top of pContentGraphic + item 2 of tSource
   else
      set the style of pPointerObj to "line"
      set the lineSize of pPointerObj to 3
      
      local tTarget
      put pPointer["end"]["x"], pPointer["end"]["y"] into tTarget
      set the points of pPointerObj to tTarget & return & tSource
   end if
end revTutorialPointerSetGraphicProps

private function revTutorialPointerSide pPointer
   set the itemdelimiter to "-"
   return item 1 of pPointer["position"]
end revTutorialPointerSide

private function revTutorialPointerPositionOnSide pPointer
   set the itemdelimiter to "-"
   return item 2 of pPointer["position"]
end revTutorialPointerPositionOnSide

private function revTutorialPointerVertical pPointer
   local tSide
   put revTutorialPointerSide(pPointer) into tSide
   return tSide is "top" or tSide is "bottom"
end revTutorialPointerVertical

private function revTutorialPointerLeft pPointer
   return revTutorialPointerSide(pPointer) is "left" or  \
         revTutorialPointerPositionOnSide(pPointer) is "left"
end revTutorialPointerLeft

private function revTutorialPointerSource pPointer, pStackWidth, pStackHeight
   switch pPointer["position"]
      case "top-left"
         return kPointerOffset, 0
      case "top-right"
         return pStackWidth - kPointerOffset, 0
      case "right-top"
         return pStackWidth, kPointerOffset
      case "right-bottom"
         return pStackWidth, pStackHeight - kPointerOffset
      case "bottom-right"
         return pStackWidth - kPointerOffset, pStackHeight
      case "bottom-left"
         return kPointerOffset, pStackHeight
      case "left-bottom"
         return 0, pStackHeight - kPointerOffset
      case "left-top"
         return 0, kPointerOffset
   end switch
end revTutorialPointerSource

private command revTutorialPointerComputeTarget pContentWidth, pContentHeight, pHighlightRect, pStackTopLeft, @xPointer
   local tLeft, tTop, tRight, tBottom
   put item 1 of pHighlightRect into tLeft
   put item 2 of pHighlightRect into tTop
   put item 3 of pHighlightRect into tRight
   put item 4 of pHighlightRect into tBottom
   
   local tSide
   put revTutorialPointerSide(xPointer) into tSide
   
   local tSource
   put revTutorialPointerSource(xPointer, pContentWidth, pContentHeight) into tSource
   
   local tAbsoluteX, tAbsoluteY
   switch tSide
      case "top"
         put tBottom + kPointerPadding into tAbsoluteY
         put (tRight + tLeft) / 2 into tAbsoluteX
         break
      case "bottom"
         put tTop - kPointerPadding into tAbsoluteY
         put (tRight + tLeft) / 2 into tAbsoluteX
         break
      case "left"
         put tRight + kPointerPadding into tAbsoluteX
         put (tTop + tBottom) / 2 into tAbsoluteY
         break
      case "right"
         put tLeft - kPointerPadding into tAbsoluteX
         put (tTop + tBottom) / 2 into tAbsoluteY
         break
   end switch
   
   put tAbsoluteX - item 1 of pStackTopLeft into xPointer["end"]["x"]
   put tAbsoluteY - item 2 of pStackTopLeft into xPointer["end"]["y"]
   put pStackTopLeft into xPointer["stacktopleft"]
end revTutorialPointerComputeTarget

local sPointer
function revTutorialStackHasPointer
   return sPointer is not empty
end revTutorialStackHasPointer

private command revTutorialSetPointer pPointer
   put pPointer into sPointer
end revTutorialSetPointer

private function revTutorialGetPointer pPointer
  return sPointer
end revTutorialGetPointer

function revTutorialPointerDifferent pPointer
   return pPointer is not sPointer
end revTutorialPointerDifferent

function revTutorialPointerLeftOverhang pPointer
   if revTutorialIsDraggingWindow() then
      return 0
   end if
   
   if pPointer["style"] is "original" then
      if revTutorialPointerSide(pPointer) is "left" then
         return kPointerWidth / 2
      end if  
   else if pPointer["end"]["x"] < 0 then
      return -(pPointer["end"]["x"])
   end if
   
   return 0
end revTutorialPointerLeftOverhang

function revTutorialPointerTopOverhang pPointer
   if revTutorialIsDraggingWindow() then
      return 0
   end if
   
   if pPointer["style"] is "original" then
      if revTutorialPointerSide(pPointer) is "top" then
         return kPointerWidth / 2
      end if  
   else if pPointer["end"]["y"] < 0 then
      return -(pPointer["end"]["y"])
   end if
   
   return 0
end revTutorialPointerTopOverhang

function revTutorialPointerRightOverhang pPointer, pWidth
   if revTutorialIsDraggingWindow() then
      return 0
   end if
   
   if pPointer["style"] is "original" then
      if revTutorialPointerSide(pPointer) is "right" then
         return kPointerWidth / 2
      end if  
   else if pPointer["end"]["x"] > pWidth then
      return pPointer["end"]["x"] - pWidth
   end if
   
   return 0
end revTutorialPointerRightOverhang

function revTutorialPointerBottomOverhang pPointer, pHeight
   if revTutorialIsDraggingWindow() then
      return 0
   end if
   
   if pPointer["style"] is "original" then
      if revTutorialPointerSide(pPointer) is "bottom" then
         return kPointerWidth / 2
      end if  
   else if pPointer["end"]["y"] > pHeight then
      return pPointer["end"]["y"] - pHeight
   end if
   
   return 0
end revTutorialPointerBottomOverhang

private function revTutorialPointerPositionCompute pPointerVertical, pPointerLeft, pPointerTop
   local tTopBottom, tLeftRight
   if pPointerTop then
      put "top" into tTopBottom
   else
      put "bottom" into tTopBottom
   end if
   
   if pPointerLeft then
      put "left" into tLeftRight
   else
      put "right" into tLeftRight
   end if

   if pPointerVertical then
      return tTopBottom & "-" & tLeftRight
   else
      return tLeftRight & "-" & tTopBottom
   end if
end revTutorialPointerPositionCompute

private command revTutorialDecideSide pNear, pFar, @rNear, @rCanFit
   # If they are both zero then we can't fit
   if pNear < 0 and pFar < 0 then
      put false into rCanFit
      exit revTutorialDecideSide
   end if
   
   # Otherwise, choose the one with the most space
   put pFar > pNear into rNear
   put true into rCanFit
end revTutorialDecideSide

private command revTutorialTryToFitWithPointer pContentWidth, pContentHeight, pScreenRect, pHighlightRect, pPointerVertical, @rPointerLeft, @rPointerTop, @rCanFit
   # Work out how much space there is
   local tLeftSpace, tRightSpace, tTopSpace, tBottomSpace, tMiddle
   if pPointerVertical then
      # If the pointer is vertical, then we have horizontal space 
      # from the middle of the target object to the sides of the screen
      put (item 3 of pHighlightRect + item 1 of pHighlightRect) / 2 into tMiddle
      put tMiddle - item 1 of pScreenRect - pContentWidth + kPointerOffset into tLeftSpace
      put item 3 of pScreenRect - tMiddle - pContentWidth + kPointerOffset into tRightSpace
      put item 2 of pHighlightRect - item 2 of pScreenRect - pContentHeight into tTopSpace
      put item 4 of pScreenRect - item 4 of pHighlightRect - pContentHeight into tBottomSpace
      subtract kPointerWidth / 2 from tTopSpace
      subtract kPointerWidth / 2 from tBottomSpace
   else
      # If the pointer is horizontal, then we have vertical space 
      # from the middle of the target object to the top and bottom of the screen
      put (item 4 of pHighlightRect + item 2 of pHighlightRect) / 2 into tMiddle
      put tMiddle - item 2 of pScreenRect - pContentHeight + kPointerOffset into tTopSpace
      put item 4 of pScreenRect - tMiddle - pContentHeight + kPointerOffset into tBottomSpace
      put item 1 of pHighlightRect - item 1 of pScreenRect - pContentWidth into tLeftSpace
      put item 3 of pScreenRect - item 3 of pHighlightRect - pContentWidth into tRightSpace
      subtract kPointerWidth / 2 from tLeftSpace
      subtract kPointerWidth / 2 from tRightSpace
   end if
   
   local tPointerLeft, tPointerTop, tCanFit
   revTutorialDecideSide tLeftSpace, tRightSpace, tPointerLeft, tCanFit
   if not tCanFit then
      put false into rCanFit
      exit revTutorialTryToFitWithPointer
   end if
   
   revTutorialDecideSide tTopSpace, tBottomSpace, tPointerTop, tCanFit
   if not tCanFit then
      put false into rCanFit
      exit revTutorialTryToFitWithPointer
   end if
   
   put tPointerLeft into rPointerLeft
   put tPointerTop into rPointerTop
   put true into rCanFit
end revTutorialTryToFitWithPointer

private function revTutorialPointerComputeForTopLeft pWidth, pHeight, pTargetRect, pStackTopLeft
   # Determine where the target rect is wrt the new stack position
   local tStackLoc, tTargetLoc
   put item 1 of pStackTopLeft + pWidth / 2,  \ 
         item 2 of pStackTopLeft + pHeight / 2 into tStackLoc
   put (item 1 of pTargetRect + item 3 of pTargetRect) / 2, \
         (item 2 of pTargetRect + item 4 of pTargetRect) / 2 into tTargetLoc
   
   local tLeftOffset, tTopOffset
   put item 1 of tTargetLoc - item 1 of tStackLoc into tLeftOffset
   put item 2 of tTargetLoc - item 2 of tStackLoc into tTopOffset
   
   local tPointerVertical, tPointerLeft, tPointerTop
   if tLeftOffset <= 0 then
      put true into tPointerLeft
   end if
   if tTopOffset <= 0 then
      put true into tPointerTop
   end if
   put abs(tTopOffset) >= abs(tLeftOffset) into tPointerVertical
   
   local tPointer
   put revTutorialPointerPositionCompute(tPointerVertical, tPointerLeft, tPointerTop) \
         into tPointer["position"]
   revTutorialPointerComputeTarget pWidth, pHeight, pTargetRect, pStackTopLeft, tPointer
   put "override" into tPointer["style"]
   return tPointer
end revTutorialPointerComputeForTopLeft

private function revTutorialPointerCompute pContentWidth, pContentHeight, pScreenRect, pHighlightRect, pPointerVertical
   local tPointerVertical, tPointerLeft, tPointerTop, tCanFit
   put pPointerVertical into tPointerVertical
   
   # Try with the pre-existing preference of pointer vertical / horizontal
   revTutorialTryToFitWithPointer pContentWidth, pContentHeight, pScreenRect, pHighlightRect, tPointerVertical, tPointerLeft, tPointerTop, tCanFit
   
   # If it failed, try the other orientation
   if not tCanFit then
      put not tPointerVertical into tPointerVertical
      revTutorialTryToFitWithPointer pContentWidth, pContentHeight, pScreenRect, pHighlightRect, tPointerVertical, tPointerLeft, tPointerTop, tCanFit
   end if
   
   if not tCanFit then
      return empty
   end if
   local tPointer
   put revTutorialPointerPositionCompute(tPointerVertical, tPointerLeft, tPointerTop) \
         into tPointer["position"]
   put "original" into tPointer["style"]
   return tPointer
end revTutorialPointerCompute

private command revTutorialPointerStackPositionOriginal pContentWidth, pContentHeight, pHighlightRect, pPointer, @rStackLeft, @rStackTop
   local tLeft, tTop, tRight, tBottom
   put item 1 of pHighlightRect into tLeft
   put item 2 of pHighlightRect into tTop
   put item 3 of pHighlightRect into tRight
   put item 4 of pHighlightRect into tBottom
   
   local tSide
   put revTutorialPointerSide(pPointer) into tSide
   
   local tSource
   put revTutorialPointerSource(pPointer, pContentWidth, pContentHeight) into tSource
   
   local tStackTop, tStackLeft, tEffectiveTop, tEffectiveLeft
   switch tSide
      case "top"
         put tBottom + kPointerPadding into tStackTop
         put (tRight + tLeft) / 2 - item 1 of tSource into tStackLeft
         break
      case "bottom"
         put tTop - pContentHeight - kPointerPadding into tStackTop
         put (tRight + tLeft) / 2 - item 1 of tSource into tStackLeft
         break
      case "left"
         put tRight + kPointerPadding into tStackLeft
         put (tTop + tBottom) / 2 - item 2 of tSource into tStackTop
         break
      case "right"
         put tLeft - pContentWidth - kPointerPadding into tStackLeft
         put (tTop + tBottom) / 2 - item 2 of tSource into tStackTop
         break
   end switch
   
   put tStackLeft - revTutorialPointerLeftOverhang(pPointer) into tEffectiveLeft
   put tStackTop - revTutorialPointerTopOverhang(pPointer) into tEffectiveTop
   
   revTutorialSetEffectiveTopLeft (tEffectiveLeft, tEffectiveTop)
   put tStackTop into rStackTop
   put tStackLeft into rStackLeft
end revTutorialPointerStackPositionOriginal

private command revTutorialPointerStackPositionOverride pContentWidth, pContentHeight, pHighlightRect, pPointer, @rStackLeft, @rStackTop
   local tTopLeftOverride
   put pPointer["stacktopleft"] into tTopLeftOverride
   
   put item 1 of tTopLeftOverride - revTutorialPointerLeftOverhang(pPointer) into rStackLeft
   put item 2 of tTopLeftOverride - revTutorialPointerTopOverhang(pPointer) into rStackTop
   
   revTutorialSetEffectiveTopLeft tTopLeftOverride
end revTutorialPointerStackPositionOverride

private command revTutorialPointerStackPosition pContentWidth, pContentHeight, pHighlightRect, pPointer, @rStackLeft, @rStackTop
   if pPointer["style"] is "original" then
      revTutorialPointerStackPositionOriginal pContentWidth, pContentHeight, pHighlightRect, pPointer, rStackLeft, rStackTop
   else
      revTutorialPointerStackPositionOverride pContentWidth, pContentHeight, pHighlightRect, pPointer, rStackLeft, rStackTop
   end if
end revTutorialPointerStackPosition

command revTutorialPointerStackSize pContentWidth, pContentHeight, pPointer, @rWidth, @rHeight
   local tWidth, tHeight
   put pContentWidth into tWidth
   put pContentHeight into tHeight
   
   add revTutorialPointerLeftOverhang(pPointer) to tWidth
   add revTutorialPointerRightOverhang(pPointer, pContentWidth) to tWidth
   add revTutorialPointerTopOverhang(pPointer) to tHeight
   add revTutorialPointerBottomOverhang(pPointer, pContentHeight) to tHeight
   
   put tWidth into rWidth
   put tHeight into rHeight
end revTutorialPointerStackSize

##############################################################################
#
#                     MAIN FUNCTIONALITY
#
##############################################################################

local sSteps, sActionNumber, sStepName, sStepNum, sNumSteps
local sCaptureData, sTaggedObjects, sWaiting, sGuides
local sOldPrefs

on revTutorialSaveProgress
   revIDETutorialSave sTaggedObjects, sStepName
end revTutorialSaveProgress

on revTutorialResume pStacksToOpen, pTaggedObjects, pStepName
   repeat for each line tStack in pStacksToOpen
      show tStack
   end repeat
   revTutorialStartWithState pStepName, pTaggedObjects
end revTutorialResume

constant kPrefsToStore = "cScriptEditor,explicitvariables|cToolbarIcons|revTools_show|idePropertyInspector_labels"
constant kBrowserWidth = 600
constant kBrowserHeight = 450
on revInitialiseTutorial
   set the _ideoverride of stack "revTutorial" to true
   
   lock screen
   lock messages
   
   # Initialise all relevant static variables
   put empty into sSteps
   put 0 into sNumSteps 
   put empty into sStepName
   put empty into sTaggedObjects
   put empty into sGuides
   put empty into sCaptureData
   revTutorialInitialiseStep
   
   # Unsubscribe all messages
   revIDEUnsubscribeAll
   
   set the defaultStack to the name of stack "revTutorial"
   
   if there is a field "Message" of stack "revTutorial" then
      delete field "Message" of stack "revTutorial"
   end if
   
   if there is a field "Script" of stack "revTutorial" then
      delete field "Script" of stack "revTutorial"
   end if
   
   if there is a button "Got It" of stack "revTutorial" then
      delete button "Got It" of stack "revTutorial"
   end if
   
   if there is a button "Do It For Me" of stack "revTutorial" then
      delete button "Do It For Me" of stack "revTutorial"
   end if
   
   if there is a button "Copy Script" of stack "revTutorial" then
      delete button "Copy Script" of stack "revTutorial"
   end if
   
   if there is a widget "Browser" of stack "revTutorial" then
      delete widget "Browser" of stack "revTutorial"
   end if
   
   if there is a field "Url" of stack "revTutorial" then
      delete field "Url" of stack "revTutorial"
   end if
   
   if there is an image "Image" of stack "revTutorial" then
      delete image "Image" of stack "revTutorial"
   end if
   
   set the windowShape of stack "revTutorial" to empty
   set the decorations of stack "revTutorial" to empty
   
   set the textStyle of stack "revTutorial" to "bold"
   set the textColor of stack "revTutorial" to "white"
   if the platform is "win32" then
      set the textsize of stack "revTutorial" to 18
   else
      set the textsize of stack "revTutorial" to 16
   end if
   
   -- Create fields
   set the lockText of the templateField to true
   set the opaque of the templateField to false
   set the showborder of the templateField to false
   set the showFocusBorder of the templateField to false
   set the width of the templateField to 1000
   set the cantSelect of the templateField to true
   set the margins of the templateField to 4
   
   set the left of the templateField to 20
   set the top of the templateField to 60
   
   create field "Message"
   set the dontWrap of it to false
   
   create field "Script"
   set the dontWrap of it to true
   set the opaque of it to true
   set the backcolor of it to "white"
   
   if revIDEBrowserWidgetUnavailable() then
      create field "Url"
      set the dontWrap of it to true
   else
      create widget "Browser" as "com.livecode.widget.browser"
      set the height of it to kBrowserHeight
      set the width of it to kBrowserWidth
      set the left of it to 20
      set the top of it to 60
      set the visible of it to false
   end if
   
   reset the templateField
   
   -- Create buttons
   set the width of the templateButton to 1000
   set the borderWidth of the templateButton to 0
   set the showFocusBorder of the templateButton to false
   set the autoHilite of the templateButton to false
   set the threeD of the templateButton to false
   set the visible of the templateButton to false
   
   create button "Got It"
   set the backColor of it to revTutorialInterludeAltColor()
   set the label of it to "Got It"
   
   create button "Copy Script"
   set the backColor of it to revTutorialMessageAltColor()
   set the label of it to "Copy Script To Editor"
   
   create button "Do It For Me"
   set the backColor of it to revTutorialMessageAltColor()
   set the label of it to "Do It For Me"
   
   reset the templateButton
   
   create image "Image"
   set the borderWidth of it to 0
   
   revIDESetTool "pointer"
   set the selectGroupedControls to true
   
   unlock messages
   
   -- Store old prefs values
   set the itemdelimiter to "|"
   repeat for each item tPref in kPrefsToStore
      put revIDEGetPreference(tPref) into sOldPrefs[tPref]
   end repeat
   
   revIDESetPreference "revTools_show", "widget,classic,graphic,graphictools,paint"
   revIDESetPreference "cToolbarIcons", true
   revIDESetPreference "idePropertyInspector_labels", false
   
   -- Ensure we know when stack names change
   revIDESubscribe "ideNameChanged"
   
   unlock screen
end revInitialiseTutorial

on ideNameChanged pOldName, pNewName, pTarget
   if word 1 of pTarget is "stack" then
      -- Update all our long IDs if we're tracking this stack
      revTutorialStackNameChanged pOldName, pNewName
   end if
end ideNameChanged

on revTutorialInitialiseStep
   put false into sWaiting
   put false into sIsInterlude
   put 0 into sActionNumber
   revTutorialSetTopLeftOverride false
end revTutorialInitialiseStep

on revFinaliseTutorial
   lock screen
   revIDETutorialInfoSetEmpty
   enableToolsPalette
   revIDEUnsubscribeAll
   
   -- Restore old prefs values
   set the itemdelimiter to "|"
   repeat for each item tPref in kPrefsToStore
      revIDESetPreference tPref, sOldPrefs[tPref]
   end repeat
   
   -- Ensure currently open script editors are updated
   revTutorialSetSEPreference "explicitVariables", sOldPrefs["cScriptEditor,explicitvariables"]
   unlock screen
end revFinaliseTutorial

on revTutorialLoadData pInfo
   local tTutorialData, tCourse, tTutorial, tLesson, tLocation
   put pInfo["course"] into tCourse
   put pInfo["tutorial"] into tTutorial
   put pInfo["lesson"] into tLesson
   put pInfo["location"] into tLocation
   put revIDETutorialLessonContent(tCourse, tTutorial, tLesson, tLocation) \
         into tTutorialData
   
   try
      put revTutorialParseData(tTutorialData) into sSteps
   catch tError
   end try
   
   if tError is not empty then 
      throw ("Error parsing" && tCourse && "-" && tTutorial && "-" \ 
            && tLesson & return & tError)
      exit revTutorialLoadData
   end if
   put the number of elements in sSteps into sNumSteps
end revTutorialLoadData

on revTutorialUpdateProgress pStep
   local tStep, tNumSteps, tStepNum
   put 0 into tStepNum
   put sSteps["first step"] into tStep
   repeat until tStep is empty
      if tStep is pStep then
         put tNumSteps into tStepNum
      end if
      add 1 to tNumSteps
      put sSteps[tStep]["actions"]["go"]["step"] into tStep
   end repeat
   put tNumSteps into sNumSteps 
   
   if pStep is not empty then
      put pStep into sStepName
   end if
   put tStepNum into sStepNum
end revTutorialUpdateProgress

on revTutorialStartWithState pStep, pTaggedObjects
   revInitialiseTutorial 
   
   local tTutorialInfo
   put revIDETutorialInProgress() into tTutorialInfo
   
   try
      revTutorialLoadData tTutorialInfo
   catch tError
   end try
   
   if tError is empty and sSteps is empty then
      put "Selected tutorial is empty" into tError
   end if
   
   if tError is not empty then
      revIDETutorialInfoSetEmpty
      throw tError
      exit revTutorialStartWithState
   end if
   
   put pTaggedObjects into sTaggedObjects
   
   revTutorialUpdateProgress pStep
   
   lock screen
   lock messages
   go invisible stack "revTutorial" as palette
   unlock messages
   unlock screen
   
   revIDESubscribe "ideActiveStacksChanged"
   if pStep is "prologue" or pStep is empty then
      revTutorialPrologue
   else if pStep is "epilogue" then
      revTutorialEpilogue
   else if pStep is among the keys of sSteps then
      send "revTutorialContinue" to stack "revTutorial" in 0 millisecs
   else
      throw "No such step"
   end if
end revTutorialStartWithState

on revTutorialContinueFromStep pStep
   if pStep is empty then
      revTutorialEpilogue
      exit revTutorialContinueFromStep
   end if
   
   if pStep is among the keys of sSteps then
      put pStep into sStepName
      send "revTutorialContinue" to stack "revTutorial" in 0 millisecs
   else
      throw "No such step"
   end if
end revTutorialContinueFromStep

on revTutorialStartAtStep pCourse, pTutorial, pLesson, pLocation, pStepName
   revTutorialRunTutorial pCourse, pTutorial, pLesson, pLocation, "", pStepName
   revIDETutorialInfoSet pCourse, pTutorial, pLesson, pLocation
   revTutorialStartWithState pStepName, sTaggedObjects
end revTutorialStartAtStep

command revTutorialGoBackToSelectStep
   // At the moment it should be a safe assumption that the relevant
   // 'select' step is the previous one
   local tPreviousStep
   put revTutorialPreviousStep() into tPreviousStep
   if sSteps[tPreviousStep]["actions"]["wait"]["wait condition"] is "state" and \
         sSteps[tPreviousStep]["actions"]["wait"]["state"] is "selected" then
      revTutorialGoBackToPreviousStep
   end if
end revTutorialGoBackToSelectStep

command revTutorialSkipCurrentStep
   revTutorialSkipStep sStepName
end revTutorialSkipCurrentStep

on revTutorialSkip
   # Calculate the skip point
   local tSkipPoint
   put sStepName into tSkipPoint
   repeat while tSkipPoint is not empty and sSteps[tSkipPoint]["skip point"] is not true
      put sSteps[tSkipPoint]["actions"]["go"]["step"] into tSkipPoint
   end repeat
   
   revTutorialSkipStep tSkipPoint
end revTutorialSkip

command revTutorialSkipStep pStep
   local tTutorialInfo
   put revIDETutorialInProgress() into tTutorialInfo
   
   if tTutorialInfo is empty then
      exit revTutorialSkipStep
   end if
   
   # Run from the current step to the next skip point
   revTutorialRunTutorial tTutorialInfo["course"], tTutorialInfo["tutorial"], \ 
         tTutorialInfo["lesson"], tTutorialInfo["location"], sStepName, pStep
   
   revTutorialInitialiseStep
   
   # Due to how the run loop works, we need to continue from the step
   # *prior* to the next executed step
   revTutorialContinueFromStep pStep
end revTutorialSkipStep

on revTutorialStop
   revTutorialClearHighlights
   revTutorialClearGuides
   revTutorialClearAllPalettes
   revTutorialClearSets
   revTutorialSaveProgress
   revFinaliseTutorial
end revTutorialStop

on revTutorialStart
   revTutorialStartWithState
end revTutorialStart

on revTutorialFinish
   lock screen
   lock messages
   go invisible stack "revTutorial" as palette
   unlock messages
   add 1 to sStepNum
   revIDETutorialProgressChanged
   revTutorialEpilogue
   unlock screen
end revTutorialFinish

function revTutorialStepNumber
   return sStepNum
end revTutorialStepNumber

function revTutorialNumberOfSteps
   return sNumSteps
end revTutorialNumberOfSteps

function revTutorialDonePercentage
   if sNumSteps is 0 then
      return 0
   end if
   return 100 * (sStepNum - 1) / sNumSteps
end revTutorialDonePercentage

private command revTutorialShow
   show stack "revTutorial"
end revTutorialShow

on revTutorialPrologue
   if sSteps["prologue"] is not empty then
      revTutorialDoInterlude false
      revTutorialSetText "prologue"
      revTutorialShow
   else
      send "revTutorialContinue" to stack "revTutorial" in 0 millisecs
   end if
end revTutorialPrologue

on revTutorialEpilogue
   if sSteps["epilogue"] is not empty then
      revTutorialClearHighlights
      revTutorialDoInterlude true
      revTutorialSetText "epilogue"
      revTutorialShow
   else
      revIDEStopTutorial
   end if
end revTutorialEpilogue

# Keep an array of things to clean up. 
# Individual highlight actions can force a palette to be kept open.
local sDismissA
on revTutorialCleanUp
   repeat for each item tItem in revTutorialPalettesToClear()
      if sDismissA[tItem] is true then
         revTutorialClearPalette tItem
      end if
      put true into sDismissA[tItem]
   end repeat
end revTutorialCleanUp

function revTutorialPalettesToClear
   return "inspector,script editor"
end revTutorialPalettesToClear

on revTutorialClearAllPalettes
   repeat for each item tItem in revTutorialPalettesToClear()
      revTutorialClearPalette tItem
   end repeat
end revTutorialClearAllPalettes

on revTutorialContinue pBack
   repeat forever
      if sWaiting then
         exit repeat
      end if
      hide stack "revTutorial"
      // Tutorial finished when there was no "go" step
      if sStepName is empty then
         revTutorialDoGoToStep sSteps["first step"]
      else if sSteps[sStepName]["actions"]["go"] is empty then
         revTutorialFinish
         exit repeat
      else if not pBack then
         // Otherwise we're here after a wait, so go to the next step
         revTutorialExecuteAction sSteps[sStepName]["actions"]["go"]
      end if
      
      // Make sure the tutorial stack is not inadvertantly shown at any point during
      // execution of this handler
      put true into sDontShow
      
      // Make sure any of the step's extra contextual data is set
      revTutorialSetContextualStepData sSteps[sStepName]
      
      // Skip step if wait condition satisfied
      if sSteps[sStepName]["actions"]["wait"] is not empty then
         # Add guide in case wait is 'fits guide'
         revTutorialExecuteAction sSteps[sStepName]["actions"]["add guide"]
         if revTutorialCheckWaitCondition(sSteps[sStepName]["actions"]["wait"], true) then
            put false into sDontShow
            next repeat
         end if
      end if
      // Ensure any expected conditions of the step are satisfied
      revTutorialEnsureState sStepName
      // Do text, highlight and guide show actions under lock screen, to remove 'flicker'
      lock screen
      // Notify any objects that need to know the tutorial progress has changed
      revIDETutorialProgressChanged
      // Interlude
      revTutorialExecuteAction sSteps[sStepName]["actions"]["interlude"]
      // Load any stack needed for this step
      revTutorialExecuteAction sSteps[sStepName]["actions"]["load"]
      // Text
      revTutorialSetText sStepName
      // Create any sets
      revTutorialExecuteAction sSteps[sStepName]["actions"]["set"]
      // Guide
      revTutorialShowGuide sSteps[sStepName]["actions"]["add guide"]["guide"]
      // Highlight
      revTutorialExecuteAction sSteps[sStepName]["actions"]["highlight"]
      unlock screen
      
      revTutorialShow
      -- Work around windowShape issue on Windows
      set the backcolor of this card of stack "revTutorial" to the backcolor of this card of stack "revTutorial"
      
      // Capture
      revTutorialExecuteAction sSteps[sStepName]["actions"]["capture"]
      // Wait
      revTutorialExecuteAction sSteps[sStepName]["actions"]["wait"]
      // Remove any palettes not needed for this step
      revTutorialCleanUp
      // Now allow change in active stacks to trigger re-showing of tutorial stack
      put false into sDontShow
      
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
         # Multiple capture actions are allowed
         local tCapture
         repeat with x = 1 to the number of elements in pActionData["captures"]
            put pActionData["captures"][x] into tCapture
            revTutorialDoCapture tCapture["object type"], tCapture["tag"], tCapture["target stack"]
         end repeat
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
      case "set"
         revTutorialDoCreateSet pActionData["objects"], pActionData["tag"]
         break
      case "load"
         revTutorialDoLoad pActionData
         break
   end switch
end revTutorialExecuteAction

command revTutorialDoLoadLesson pLesson
   # Check to see if the stack from the specified lesson is complete
   local tTutorialInfo
   put revIDETutorialInProgress() into tTutorialInfo
   
   # Simply run the lesson that is to be loaded
   revTutorialRunTutorial tTutorialInfo["course"], tTutorialInfo["tutorial"], pLesson, tTutorialInfo["location"]
end revTutorialDoLoadLesson

command revTutorialDoLoadStackResource pFile
   local tFileName, tStackName
   put revIDETutorialInternalResource(pFile) into tFileName
   lock screen
   lock messages
   go stack tFileName
   put the name of stack tFileName into tStackName
   set the filename of stack tStackName to empty
   revIDETutorialUpdateAndRemoveTags tStackName, sTaggedObjects
   unlock messages
   unlock screen
end revTutorialDoLoadStackResource

on revTutorialDoLoad pActionData
   if pActionData["lesson"] is not empty then
      revTutorialDoLoadLesson pActionData["lesson"]
   else if pActionData["stack"] is not empty then
      revTutorialDoLoadStackResource pActionData["stack"]
   end if
end revTutorialDoLoad

on revTutorialSetText pStep, pTopLeft
   revTutorialConfigureMessage sSteps[pStep], pTopLeft
end revTutorialSetText

on revTutorialConfigureMessage pData, pTopLeft
   local tWidthOverride
   put kMessageWidth into tWidthOverride
   set the width of field "Message" of stack "revTutorial" to kMessageWidth
   
   if pData["value"] is not empty then
      replace "<value>" with pData["value"] in pData["text"]
   end if
   if pData["file"] is not empty then
      replace "<file>" with pData["file"] in pData["text"]
   end if
   
   put pData["text"] into field "Message" of stack "revTutorial"
   
   # Recalculate the formatted width after replacing value / file
   put the formattedwidth of field "Message" of stack "revTutorial" into tWidthOverride
   
   local tImageFile
   if pData["image"] is not empty then
      local tImageWidth
      put revTutorialImageForScreenSize(pData["image"]) into tImageFile
      set the filename of image "Image" of stack "revTutorial" to tImageFile
      put the formattedWidth of image "Image" of stack "revTutorial" + 2 * kMargin into tImageWidth
      put max(tWidthOverride, tImageWidth) into tWidthOverride
   else
      set the filename of image "Image" of stack "revTutorial" to empty
   end if
   
   put pData["script"] into field "Script" of stack "revTutorial"
   if pData["script"] is not empty then
      put return before field "Script" of stack "revTutorial"
      local tLength
      put the number of chars in field "Script" of stack "revTutorial" into tLength
      _internal script colorize char 1 to tLength of field "Script" of stack "revTutorial"
      local tScriptFieldWidth
      put the formattedWidth of field "Script" of stack "revTutorial" + 2 * kMargin into tScriptFieldWidth
      put max(tWidthOverride, tScriptFieldWidth) into tWidthOverride
   end if
   
   
   if revIDEBrowserWidgetUnavailable() then
      if pData["url"] is not empty then
         set the text of field "Url" of stack "revTutorial" to pData["url"]
      else
         set the text of field "Url" of stack "revTutorial" to empty
      end if
   else
      if pData["url"] is not empty then
         set the url of widget "Browser" of stack "revTutorial" to pData["url"]
         put max(tWidthOverride, kBrowserWidth) into tWidthOverride
      else
         set the url of widget "Browser" of stack "revTutorial" to empty
      end if
   end if
   
   revTutorialPositionStackForHighlight pTopLeft, tWidthOverride
end revTutorialConfigureMessage

function revTutorialImageForScreenSize pImage
   local tScreen, tScreenRect
   put the screen of stack "revTutorial" into tScreen
   put line tScreen of the the screenrects into tScreenRect
   if item 4 of tScreenRect - item 2 of tScreenRect <= 1080 then
      local tSmallImage, tFile
      put pImage into tSmallImage
      set the itemdelimiter to "."
      put "_small" after item -2 of tSmallImage
      put revIDETutorialInternalResource(tSmallImage) into tFile
      if there is a file tFile then
         return tFile
      end if
   end if
   return revIDETutorialInternalResource(pImage)
end revTutorialImageForScreenSize

function revTutorialScriptRetry pCurrent
   local tText
   put "Your script is not quite right. You have:" & return & return after tText
   put pCurrent after tText
   put return & return after tText
   put "Set the script to the following and click the apply button:" after tText
   return tText
end revTutorialScriptRetry

local sLastObjects
on revTutorialEnsurePaletteForObject pPalette, pTutorialObject
   local tObjectID
   put revTutorialResolveObjectToLongID(pTutorialObject) into tObjectID
   
   put tObjectID into sLastObjects[pPalette]
   if revTutorialObjectHasPalette(pPalette, tObjectID) then
      exit revTutorialEnsurePaletteForObject
   end if
   
   if pPalette is "inspector" then
      revIDEInspectObjects tObjectID
   else if pPalette is "script editor" then
      revIDEEditScriptOfObjects tObjectID
   end if
end revTutorialEnsurePaletteForObject

on revTutorialEnsurePalette pPalette
   local tStack
   put revIDEPaletteToStackName(pPalette) into tStack
   if the mode of stack tStack is 0 then
      revIDEOpenPalette(pPalette)
   end if
end revTutorialEnsurePalette

on revTutorialEnsureState pStep
   local tWaitDataA
   put sSteps[pStep]["actions"]["wait"] into tWaitDataA
   
   switch tWaitDataA["wait condition"]
      case "property"
         revTutorialEnsurePaletteForObject "inspector", tWaitDataA["object"]
         break
      case "state"
         switch tWaitDataA["state"]
            case "scripted"
               revTutorialEnsurePaletteForObject "script editor", tWaitDataA["object"]
               break
         end switch
   end switch
   
   local tHighlightDataA
   put sSteps[pStep]["actions"]["highlight"] into tHighlightDataA
   switch tHighlightDataA["highlight type"]
      case "item of palette for object"
      case "palette for object"
         revTutorialEnsurePaletteForObject tHighlightDataA["palette"], tHighlightDataA["object"]
         break
      case "script line"
         revTutorialEnsurePaletteForObject "script editor", tHighlightDataA["object"]
         break
      case "item of palette"
      case "palette"
         revTutorialEnsurePalette tHighlightDataA["palette"]
         break
   end switch
end revTutorialEnsureState

local sStepContextA
on revTutorialSetContextualStepData pStepDataA
   put pStepDataA["file"] into sStepContextA["file"]
   put pStepDataA["value"] into sStepContextA["value"]
   put pStepDataA["image"] into sStepContextA["image"]
   if pStepDataA["actions"]["wait"]["wait condition"] is "pops up" then
      put false into sStepContextA["can skip"]
   else
      put true into sStepContextA["can skip"]
   end if
end revTutorialSetContextualStepData

function revTutorialCanSkipStep
   return sStepContextA["can skip"]
end revTutorialCanSkipStep

##############################################################################
#
#                     ACTION IMPLEMENTATIONS
#
##############################################################################

local sPreviousStep
private function revTutorialPreviousStep
   return sPreviousStep
end revTutorialPreviousStep

command revTutorialGoBackToPreviousStep
   if sPreviousStep is empty then
      exit revTutorialGoBackToPreviousStep
   end if
   revTutorialDoGoToStep sPreviousStep, true
   send "revTutorialContinue true" to stack "revTutorial" in 0 millisecs
end revTutorialGoBackToPreviousStep

on revTutorialDoGoToStep pStep, pBack
   if not pBack then
      put sStepName into sPreviousStep
   end if
   revTutorialInitialiseStep
   revTutorialClearHighlights
   revTutorialClearGuides
   revTutorialClearSets
   disableToolsPalette
   revTutorialUpdateProgress pStep
end revTutorialDoGoToStep

on revTutorialDoCapture pType, pTag, pTargetStack
   get the number of elements of sCaptureData[pType]
   put pTag into sCaptureData[pType][it + 1]["tag"]
   put pTargetStack["tag"] into sCaptureData[pType][it + 1]["stack"]
   put false into sCaptureData[pType][it + 1]["captured"]
end revTutorialDoCapture

on revTutorialDoInterlude pIsEpilogue
   put true into sIsInterlude
   revTutorialWaitUntilInterludeIsDismissed pIsEpilogue
end revTutorialDoInterlude

# Tag a set of objects
on revTutorialDoCreateSet pObjects, pTag
   put pObjects into sTaggedObjects["set"][pTag]
end revTutorialDoCreateSet

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
   if revTutorialCheckWaitCondition(pActionData, true) then
      exit revTutorialDoWait
   end if
   
   put pActionData into sWait
   put true into sWaiting
   
   switch pActionData["wait condition"]
      case "there is an object"
         revTutorialWaitForObject
         break
      case "there is a palette for object" 
         revTutorialWaitUntilThereIsAPaletteForObject pActionData["palette"]
         break
      case "there is a palette"
         revTutorialWaitUntilThereIsAPalette pActionData["palette"]
         break
      case "tool"
         revTutorialWaitUntilTheToolIs
         break
      case "property"  
         revTutorialWaitUntilObjectPropertyHasValue pActionData["object"]
         break
      case "fits" 
         revTutorialWaitUntilObjectFitsGuide pActionData["object"]
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
               revTutorialWaitUntilObjectIsScripted pActionData["object"]
               break
            case "focused"
               revTutorialWaitUntilObjectIsFocused
               break
            case "selected"
               revTutorialWaitUntilObjectIsSelected
               break
            case "grouped"
               revTutorialWaitUntilObjectIsGrouped pActionData["object"]
               break
         end switch
         break
      case "this card"
         revTutorialWaitUntilThisCardIs pActionData["card"]
         break
   end switch
end revTutorialDoWait

function revTutorialCheckWaitCondition pActionData, pBeforeDisplay
   # Deal with non-object wait conditions
   switch pActionData["wait condition"]
      case "there is a palette"
         return revTutorialThereIsAPalette(pActionData["palette"]) 
      case "tool" 
         return revTutorialToolIs(pActionData["tool"])
   end switch
   
   local tObject
   put revTutorialResolveObjectToLongID(pActionData["object"]) into tObject
   if tObject is empty then
      return false
   end if
   
   switch pActionData["wait condition"]
      case "property"
         # If we are waiting for the property to be 'changed' then don't try and
         # shortcut the step
         if pBeforeDisplay and pActionData["is not"] then
            break
         end if
         
         local tValue
         # If the step specified a value then we want to compare with this instead
         # of the string "value"
         if pActionData["value"] is "value" and sStepContextA["value"] is not empty then
            put sStepContextA["value"] into tValue
         else
            put pActionData["value"] into tValue
         end if
         
         if revTutorialObjectPropertyIsValue(tObject, pActionData["property"], tValue, pActionData["is not"]) then
            return true
         end if
         break
      case "fits"
         if revTutorialObjectFitsGuide(tObject, pActionData["guide"], pActionData["tolerance"]) then
            revTutorialSnapObjectToGuide tObject, pActionData["guide"]
            return true
         end if
         break
      case "there is a palette for object"
         if revTutorialObjectHasPalette(pActionData["palette"], tObject) then
            return true
         end if
         break
      case "state"
         switch pActionData["state"]
            case "selected"
               if revTutorialObjectsAreSelected(tObject) then
                  return true
               end if
               break
            case "scripted"
               # Don't try and shortcut this step
               if pBeforeDisplay then
                  break
               end if
               
               # This code path is triggered by any propertyChanged message,
               # so if the script hasn't changed then don't do anything.
               local tScript
               put the script of tObject into tScript
               revTutorialCompareScript tScript, sWait["current script"]
               if the result is empty then
                  break
               end if
               local tMistake
               revTutorialCompareScript tScript, pActionData["script"]
               put the result into tMistake
               if tMistake is empty then
                  return true
               end if
               put tScript into sWait["current script"]
               add 1 to sWait["incorrect attempts"]
               # Show the current script and the target script in the tip stack
               local tData
               put revTutorialScriptRetry(tMistake) into tData["text"]
               put pActionData["script"] into tData["script"]
               revTutorialConfigureMessage tData, revTutorialGetEffectiveTopLeft()
               break
         end switch
         break
   end switch
   return false
end revTutorialCheckWaitCondition

on revTutorialWaitUntilObjectIsSelected
   revIDESubscribe "ideSelectedObjectChanged"
end revTutorialWaitUntilObjectIsSelected

on revTutorialWaitUntilObjectIsScripted pTaggedObject
   local tObjID
   put revTutorialResolveObjectToLongID(pTaggedObject) into tObjID
   put the script of tObjID into sWait["current script"]
   put 0 into sWait["incorrect attempts"]
   
   -- Set explicit vars to false when waiting for script
   revTutorialSetSEPreference "explicitVariables", false
   
   revIDESubscribe "idePropertyChanged", tObjID
   revIDESubscribe "ideScriptEdited"
end revTutorialWaitUntilObjectIsScripted

on revTutorialWaitUntilObjectIsClicked
   revIDESubscribe "ideMouseUp"
end revTutorialWaitUntilObjectIsClicked

on revTutorialWaitUntilObjectIsFocused
   // Subscribe to control
end revTutorialWaitUntilObjectIsFocused

on revTutorialWaitUntilObjectIsGrouped pObject
   put pObject into sWait["children"]
   revIDESubscribe "ideNewControl"
end revTutorialWaitUntilObjectIsGrouped

on revTutorialWaitForObject
   if sWait["object"]["type"] is "stack" then
      revIDESubscribe "ideNewStack"
   else if sWait["object"]["type"] is "card" then
      revIDESubscribe "ideNewStack"
      revIDESubscribe "ideNewCard"
   else
      revIDESubscribe "ideNewControl"
   end if
end revTutorialWaitForObject

on revTutorialWaitUntilObjectFitsGuide pTaggedObject
   local tObjID
   put revTutorialResolveObjectToLongID(pTaggedObject) into tObjID
   if sWait["tolerance"] is empty then
      put 1 into sWait["tolerance"]
   end if
   revIDESubscribe "idePropertyChanged", tObjID
end revTutorialWaitUntilObjectFitsGuide

on revTutorialWaitUntilThereIsAPalette pPalette
   revIDESubscribe "ideOpenPalette"
end revTutorialWaitUntilThereIsAPalette

on revTutorialWaitUntilThereIsAPaletteForObject pPalette
   if pPalette is "inspector" then
      revIDESubscribe "ideInspectObjects"
   else if pPalette is "script editor" then
      revIDEHighlightPaletteObject "menubar", "standard"
      revIDESubscribe "ideEditScript"
   end if
   revIDESubscribe "ideSelectedObjectChanged"
end revTutorialWaitUntilThereIsAPaletteForObject

on revTutorialWaitUntilTheToolIs
   revIDESubscribe "ideToolChanged"
end revTutorialWaitUntilTheToolIs

on revTutorialWaitUntilObjectPropertyHasValue pTaggedObject
   local tObjID
   put revTutorialResolveObjectToLongID(pTaggedObject) into tObjID
   if sWait["is not"] then
      put the sWait["property"] of tObjID into sWait["value"]
   end if
   revIDESubscribe "idePropertyChanged", tObjID
end revTutorialWaitUntilObjectPropertyHasValue

on revTutorialWaitUntilAnswerDialogHasPoppedUp
   revIDESubscribe "ideAnswerDialogClosed"
end revTutorialWaitUntilAnswerDialogHasPoppedUp

on revTutorialWaitUntilInterludeIsDismissed pIsEpilogue
   put true into sWaiting
   put "interlude" into sWait["wait condition"]
   put pIsEpilogue into sWait["epilogue"]
end revTutorialWaitUntilInterludeIsDismissed

on revTutorialWaitUntilThisCardIs pCard
   put true into sWaiting
   put "this card" into sWait["wait condition"]
   put pCard into sWait["card"]
   revIDESubscribe "ideOpenCard"
end revTutorialWaitUntilThisCardIs

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
         case "item of palette for object"
            revTutorialHighlightItemOfPaletteForObject pActionData["palette"], pActionData["item"], pActionData["object"]
            break
         case "item of palette"
            revTutorialHighlightItemOfPalette pActionData["palette"], pActionData["item"]
            break
         case "palette"
            revTutorialHighlightPalette pActionData["palette"]
            break
         case "palette for object"
            revTutorialHighlightPaletteForObject pActionData["palette"], pActionData["object"]
            break
         case "script line"
            revTutorialHighlightLineOfScriptEditorForObject pActionData["line"], pActionData["object"]
            break
      end switch
   catch tError
      // Something was specified incorrectly in the tutorial file
   end try
   # Subscribe to the resumestack message so that we can respond when
   #  the wrong palette receives focus
   revIDESubscribe "ideResumeStack"
end revTutorialDoHighlight

on revTutorialHighlightLineOfScriptEditorForObject pLine, pObject
   put pLine into sHighlight["line"]
   revTutorialHighlightItemOfPaletteForObject "script editor", sHighlight["line"], pObject
end revTutorialHighlightLineOfScriptEditorForObject

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
   revTutorialHighlightObjectByID tObject
end revTutorialHighlightObject

on revTutorialHighlightPalette pPaletteName
   put "stack" into sHighlight["type"]
   put pPaletteName into sHighlight["stack"]
   
   revIDESubscribe "ideStackMoved", the long id of stack revIDEPaletteToStackName(pPaletteName)
   revTutorialPositionStackForHighlight revTutorialTopLeftOverride()
end revTutorialHighlightPalette

function revTutorialPaletteForObject pPaletteName, pObject
   local tObject, tPaletteID
   put sTaggedObjects[pObject["type"]][pObject["tag"]] into tObject
   switch pPaletteName
      case "script editor"
         put the long id of stack revScriptEditor(tObject) into tPaletteID
         break
      case "inspector"
         put revIDEInspectorForObject(tObject) into tPaletteID
         break
   end switch
   
   return tPaletteID
end revTutorialPaletteForObject

on revTutorialHighlightPaletteForObject pPaletteName, pObject
   local tPaletteID
   put revTutorialPaletteForObject(pPaletteName, pObject) into tPaletteID
   if there is a tPaletteID then
      revTutorialHighlightObjectByID tPaletteID
   end if
   if pPaletteName is "inspector" then
      dispatch "lockInspector" to tPaletteID
   end if
   put false into sDismissA[pPaletteName]
end revTutorialHighlightPaletteForObject

on revTutorialHighlightObjectByID pObjID
   if word 1 of pObjID is "stack" then
      put "stack" into sHighlight["type"]
      put pObjID into sHighlight["stack"]
   else
      put "object" into sHighlight["type"]
      put pObjID into sHighlight["object"]
   end if
   revIDESubscribe "ideStackMoved", revIDEStackOfObject(pObjID)
   revIDESubscribe "idePropertyChanged", pObjID
   revTutorialPositionStackForHighlight revTutorialTopLeftOverride()
end revTutorialHighlightObjectByID

on revTutorialHighlightItemOfPaletteForObject pPalette, pItem, pObject
   local tPaletteID
   put revTutorialPaletteForObject(pPalette, pObject) into tPaletteID
   if there is a tPaletteID then
      revTutorialHighlightItemOfStack tPaletteID, pItem
   end if
   put false into sDismissA[pPalette]
end revTutorialHighlightItemOfPaletteForObject

on revTutorialHighlightItemOfPalette pPalette, pItem
   local tPaletteID
   put the long id of stack revIDEPaletteToStackName(pPalette) into tPaletteID
   revTutorialHighlightItemOfStack tPaletteID, pItem
end revTutorialHighlightItemOfPalette

on revTutorialHighlightItemOfStack pStackID, pItem
   local tObjectLongID
   revIDEHighlightObject pStackID, pItem
   put pStackID into sHighlight["stack"]
   put pItem into sHighlight["object"]
   put "object" into sHighlight["type"]
   revIDESubscribe "ideStackMoved", pStackID
   revTutorialPositionStackForHighlight revTutorialTopLeftOverride()
end revTutorialHighlightItemOfStack
   
   
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
   revIDEHighlightPaletteObject "tools", pTool
   revIDESubscribe "ideStackMoved", the long id of stack revIDEPaletteToStackName("tools")
   put "tool" into sHighlight["type"]
   put pTool into sHighlight["tool"]
   revTutorialPositionStackForHighlight revTutorialTopLeftOverride()
end revTutorialHighlightTool

function revTutorialHighlightedPalette pPalette
   if sLastObjects[pPalette] is empty then
      return empty
      end if
   local tStack
   switch pPalette
      case "inspector"
         put revIDEInspectorForObject(sLastObjects["inspector"]) into tStack
         break
      case "script editor"
         put revScriptEditor(sLastObjects["script editor"]) into tStack
   end switch
   if tStack is not empty then
      return the long name of stack tStack
   end if
   return empty
end revTutorialHighlightedPalette
      
on revTutorialHighlightInspector pSection, pGroup
   local tObjectData
   put pSection into tObjectData["section"]
   put pGroup into tObjectData["group"]
   put sLastObjects["inspector"] into tObjectData["object"]
   
   revIDEHighlightPaletteObject "inspector", tObjectData
   
   local tInspector
   put revTutorialHighlightedPalette("inspector") into tInspector
   
   revIDESubscribe "ideStackMoved", tInspector
   
   # Lock the inspector to prevent mishaps
   dispatch "lockInspector" to tInspector
   
   put "property" into sHighlight["type"]
   put pGroup into sHighlight["group"]
   put sLastObjects["inspector"] into sHighlight["object"]
   revTutorialPositionStackForHighlight revTutorialTopLeftOverride()
   put false into sDismissA["inspector"]
end revTutorialHighlightInspector

local sDisabled
on revTutorialHighlightMenuItem pMenu, pItem
   local tMenuHighlight
   put pItem into tMenuHighlight[pMenu]
   revIDEHighlightPaletteObject "menubar", tMenuHighlight
   revIDESubscribe "ideStackMoved", the long id of stack revIDEPaletteToStackName("menubar")
   put "menu" into sHighlight["type"]
   put pMenu into sHighlight["menu"]
   revTutorialPositionStackForHighlight revTutorialTopLeftOverride()
end revTutorialHighlightMenuItem

on revTutorialHighlightToolbarItem pItem
   revIDEHighlightPaletteObject "menubar", pItem
   revIDESubscribe "ideStackMoved", the long id of stack revIDEPaletteToStackName("menubar")
   put "toolbar" into sHighlight["type"]
   put pItem into sHighlight["item"]
   revTutorialPositionStackForHighlight revTutorialTopLeftOverride()
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
on revTutorialShowGuide pTag
   if pTag is not empty then
      show sGuides[pTag]
   end if
end revTutorialShowGuide

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
      create invisible graphic // To object objtype/objtag
      put it into sGuides[pTag]
      set the defaultStack to tDefaultStack
      reset the templateGraphic
   end if
   unlock messages
end revTutorialDoAddGuide

on revTutorialHighlightGuide pGuide
   revIDESubscribe "ideStackMoved", revIDEStackOfObject(sGuides[pGuide])
   put "guide" into sHighlight["type"]
   put pGuide into sHighlight["guide"]
   revTutorialPositionStackForHighlight revTutorialTopLeftOverride()
end revTutorialHighlightGuide

on revTutorialClearGuides
   repeat for each element tGraphic in sGuides
      delete tGraphic
   end repeat
   put empty into sGuides
end revTutorialClearGuides

on revTutorialClearPalette pPalette
   local tStack
   put revTutorialHighlightedPalette(pPalette) into tStack
   if tStack is not empty then
      close stack tStack
      put empty into sLastObjects[pPalette]
   end if
end revTutorialClearPalette

on revTutorialClearSets
   # For now, set captures are transient
   delete variable sTaggedObjects["set"]
end revTutorialClearSets
##############################################################################
#
#                     MESSAGES HANDLED TO CHECK WAIT CONDITIONS
#
##############################################################################

on revTutorialReShow
   -- Ensure tutorial stack is always visible if it should be
   if the visible of stack "revTutorial" and not sDontShow then
      palette stack "revTutorial"
      -- Work around windowShape issue on Windows
      set the backcolor of this card of stack "revTutorial" to the backcolor of this card of stack "revTutorial"
   end if
end revTutorialReShow

on ideActiveStacksChanged
   revTutorialReShow
   
   local tObject
   put revIDESelectedObjects() into tObject
   if sWait["wait condition"] is "there is a palette for object" then
      -- If the object became deselected, go back a step
      if not revTutorialObjectIsTaggedObject(tObject, sWait["object"]) then
         revTutorialGoBackToSelectStep
      end if
   else if sWait["wait condition"] is "state" and sWait["state"] is "selected" then
      if revTutorialObjectIsTaggedObject(tObject, sWait["object"]) then
         revIDEUnsubscribe "ideSelectedObjectChanged"
         revTutorialWaitConditionSatisfied
      end if
   end if
end ideActiveStacksChanged

on ideCloseStackRequest pStack
   answer "Closing the stack will exit this tutorial. Are you sure?" with "Yes" or "No"
   if it is "No" then
      exit ideCloseStackRequest
   end if
   send "revIDEStopTutorial" to stack "revIDELibrary" in 0 millisecs
end ideCloseStackRequest

on openField
   local tObject
   put the long id of the target into tObject
   if sWait["wait condition"] is "state" and sWait["state"] is "focused" then
      if revTutorialObjectIsTaggedObject(tObject, sWait["object"]) then
         revTutorialWaitConditionSatisfied
      end if
   end if
   pass openField
end openField

on focusIn
   local tObject
   put the long id of the target into tObject
   if sWait["wait condition"] is "state" and sWait["state"] is "focused" then
      if revTutorialObjectIsTaggedObject(tObject, sWait["object"]) then
         revTutorialWaitConditionSatisfied
      end if
   end if
   pass focusIn
end focusIn

private function __captureNumber pType, pObject
   if pType is not among the keys of sCaptureData then
      return 0
   end if
   
   local tCaptureNumber
   put 1 into tCaptureNumber
   repeat while sCaptureData[pType][tCaptureNumber]["captured"] is true or \
         (pObject is not empty and sTaggedObjects["stack"][sCaptureData[pType][tCaptureNumber]["stack"]] is not revIDEStackOfObject(pObject))
      add 1 to tCaptureNumber
   end repeat
   if sCaptureData[pType][tCaptureNumber] is not empty then
      return tCaptureNumber
   end if
   return 0
end __captureNumber

on ideNewStack pStack
   local tStackTag, tCaptureNumber
   
   put __captureNumber("stack") into tCaptureNumber
   if tCaptureNumber is not 0 then
      put the long id of pStack into sTaggedObjects["stack"][sCaptureData["stack"][tCaptureNumber]["tag"]]
      put sCaptureData["stack"][tCaptureNumber]["tag"] into tStackTag
      put true into sCaptureData["stack"][tCaptureNumber]["captured"]
   end if
   
   put __captureNumber("card", the long id of this card of pStack) into tCaptureNumber
   if tCaptureNumber is not 0 then
      put the long id of this card of pStack into sTaggedObjects["card"][sCaptureData["card"][tCaptureNumber]["tag"]]
      put true into sCaptureData["card"][tCaptureNumber]["captured"]
   end if
   
   if sWait["wait condition"] is "there is an object" then
      local tWaitSatisfied
      if sWait["object"]["type"] is "card" and sWait["object"]["tag"] is among the keys of sTaggedObjects["card"] then
         revIDEUnsubscribe "ideNewCard"
         put true into tWaitSatisfied
      else if sWait["object"]["type"] is "stack" and sWait["object"]["tag"] is among the keys of sTaggedObjects["stack"] then
         put true into tWaitSatisfied
         revIDESubscribe "ideCloseStackRequest", pStack
      end if
      
      if tWaitSatisfied then
         revIDEUnsubscribe "ideNewStack"
         revTutorialWaitConditionSatisfied
      end if
   end if
end ideNewStack

on ideAnswerDialogClosed
   if sWait["wait condition"] is "pops up"  then
      revIDEUnsubscribe "ideAnswerDialogClosed"
      revTutorialWaitConditionSatisfied
   end if
end ideAnswerDialogClosed

on ideNewControl pObject
   local tObjType, tCaptureNumber
   put word 1 of pObject into tObjType
   put __captureNumber(tObjType, the long id of pObject) into tCaptureNumber
   if tCaptureNumber is not 0 then
      put the long id of pObject into sTaggedObjects[tObjType][sCaptureData[tObjType][tCaptureNumber]["tag"]]
      put true into sCaptureData[tObjType][tCaptureNumber]["captured"]
   end if
   
   if sWait["wait condition"] is "there is an object" and sWait["object"]["type"] is tObjType and sWait["object"]["tag"] is among the keys of sTaggedObjects[tObjType] then
      revIDEUnsubscribe "ideNewControl"
      revTutorialWaitConditionSatisfied
   end if
   
   if sWait["wait condition"] is "state" and sWait["state"] is "grouped" and tObjType is "group" then
      local tChildren
      put revTutorialResolveObjectToLongID(sWait["children"], true) into tChildren
      
      if revTutorialGroupContainsObjects(pObject, tChildren) then
         revIDEUnsubscribe "ideNewControl"
         revTutorialWaitConditionSatisfied
      end if
   end if
end ideNewControl

on ideNewCard pCard
   local tCaptureNumber
   put __captureNumber("card", the long id of pCard) into tCaptureNumber
   if tCaptureNumber is not 0 then
      put the long id of pCard into sTaggedObjects["card"][sCaptureData["card"][tCaptureNumber]["tag"]]
      put true into sCaptureData["card"][tCaptureNumber]["captured"]
   end if
   
   if sWait["wait condition"] is "there is an object" and sWait["object"]["type"] is "card" and sWait["object"]["tag"] is among the keys of sTaggedObjects["card"] then
      revIDEUnsubscribe "ideNewCard"
      revIDEUnsubscribe "ideNewStack"
      revTutorialWaitConditionSatisfied
   end if
end ideNewCard

on idePropertyChanged pObject
   # If a highlighted object moved then reposition the tutorial step pointer
   if not pObject begins with "stack" and revTutorialObjectIsHighlighted(pObject) then
      revTutorialPositionStackForHighlight revTutorialTopLeftOverride()
   end if
   
   if revTutorialObjectIsTaggedObject(pObject, sWait["object"]) then
      if revTutorialIsWaitForProperty(sWait) then
         if revTutorialCheckWaitCondition(sWait) then
            revIDEUnsubscribe "idePropertyChanged", "", sTaggedObjects[sWait["object"]["type"]][sWait["object"]["tag"]]
            revTutorialWaitConditionSatisfied
            if sWait["state"] is "scripted" then
               -- Set explicit vars back to previous setting
               revTutorialSetSEPreference "explicitVariables", sOldPrefs["cScriptEditor,explicitvariables"]
            end if
         end if
      end if
   end if
end idePropertyChanged

local sScriptCheck
on revTutorialCheckScript pScript, pObject
   if revTutorialObjectIsTaggedObject(pObject, sWait["object"]) then
      if sWait["wait condition"] is "state" and \
            sWait["state"] is "scripted" then
         revTutorialCompareScript pScript, sWait["script"]
         lock screen
         if the result is empty and sWait["correct script"] is not true then
            -- If the currently typed script is correct, then
            -- remind about clicking Apply
            -- Remember the chosen location
            put revTutorialGetEffectiveTopLeft() into sScriptCheck["topleft"]
            put true into sScriptCheck["correct script"]
            put "Apply" into sHighlight["object"]
            put "object" into sHighlight["type"]
            local tData
            put "Click 'Apply' to apply the script" into tData["text"]
            revTutorialConfigureMessage tData
         else if sScriptCheck["correct script"] is true then
            -- Otherwise, the script has been changed from the correct one
            put false into sScriptCheck["correct script"]
            -- Reset the highlight
            put "stack" into sHighlight["type"]
            -- Reset the text
            revTutorialSetText sStepName, sScriptCheck["topleft"]
         end if
         unlock screen
      end if
   end if
end revTutorialCheckScript

local sCheckScriptMsg
constant kCheckBufferMS = 800
on ideScriptEdited pScript, pObject
   -- In order to mitigate against forgetting to press the
   -- apply button, we subscribe to ideScriptEdited and check
   -- to see if the script entered is correct. However, we 
   -- don't want to interrupt the flow of typing, so add a
   -- buffer
   if sCheckScriptMsg is not empty then
      cancel sCheckScriptMsg
   end if
   send "revTutorialCheckScript pScript, pObject" to me in kCheckBufferMS millisecs
   put the result into sCheckScriptMsg
end ideScriptEdited

on ideStackMoved pStack
   local tStack
   put revIDEStackOfObject(pStack) into tStack
   # If the highlighted stack is moved, then reposition the tutorial step pointer
   if revTutorialObjectIsHighlighted(tStack) then
      revTutorialPositionStackForHighlight revTutorialTopLeftOverride()
   end if
end ideStackMoved

on ideResumeStack pStack
   local tStack
   put revIDEStackOfObject(pStack) into tStack
   if not revTutorialObjectIsHighlighted(tStack) then
      # If the target stack is not highlighted then react accordingly
   else
      revTutorialPositionStackForHighlight revTutorialTopLeftOverride()
   end if
end ideResumeStack

on ideOpenPalette pPalette
   if sWait["wait condition"] is "there is a palette" and pPalette is sWait["palette"] then
      revIDEUnsubscribe "ideOpenPalette"
      revTutorialWaitConditionSatisfied
   end if
end ideOpenPalette

on ideMouseUp pWhich, pTarget
   if sWait["wait condition"] is "state" and sWait["state"] is "clicked" then
      if revTutorialObjectIsTaggedObject(pTarget, sWait["object"]) then
         revTutorialWaitConditionSatisfied
      end if
   end if
end ideMouseUp

on mouseDown
   local tObject
   put the long id of the target into tObject
   if word 1 of tObject is "button" then
      revTutorialSetPressedState tObject
   else
      revTutorialDragWindow
   end if
end mouseDown

on mouseRelease
   local tObject
   put the long id of the target into tObject
   if word 1 of tObject is "button" then
      revTutorialSetUnpressedState tObject
   end if
   
   revTutorialDragStop
end mouseRelease

on mouseUp pWhich
   local tObject
   put the long id of the target into tObject
   
   if sWait["wait condition"] is "interlude" then
      if tObject is the long id of button "Got It" of stack "revTutorial" then
         revTutorialReturnFromInterlude
      end if
   end if
   
   if tObject is the long id of button "Copy Script" of stack "revTutorial" then
      revTutorialCopyScriptToEditor
   end if
   
   if tObject is the long id of button "Do It For Me" of stack "revTutorial" then
      revTutorialSkipCurrentStep
   end if
   
   if word 1 of tObject is "button" then
      revTutorialSetUnpressedState tObject
   end if
   
   revTutorialDragStop
end mouseUp

on mouseMove
   if revTutorialIsDraggingWindow() then
      revTutorialTrackToMouse
   end if
end mouseMove

local sMouseLoc, sMoved
command revTutorialDragWindow
   if sMouseLoc is not empty or the mouse is not "down" then
      exit revTutorialDragWindow
   end if
   put the screenmouseloc into sMouseLoc
end revTutorialDragWindow

command revTutorialDragStart
   lock screen
   lock messages
   local tTopLeft
   put revTutorialGetEffectiveTopLeft() into tTopLeft
   revTutorialOverrideLocation tTopLeft
   unlock messages
   unlock screen
   
   put true into sMoved
end revTutorialDragStart

command revTutorialDragStop
   lock screen
   lock messages
   put empty into sMouseLoc
   if sMoved then
      revTutorialOverrideLocation the topleft of stack "revTutorial"
   end if
   put false into sMoved
   unlock messages
   unlock screen
end revTutorialDragStop

private function revTutorialIsDraggingWindow
   return sMouseLoc is not empty
end revTutorialIsDraggingWindow

private command revTutorialTrackToMouse
   if not sMoved then
      revTutorialDragStart
   end if
   local tNewLoc, tNewTopLeft
   put the screenmouseloc into tNewLoc
   
   local tTopLeft
   put revTutorialGetEffectiveTopLeft() into tTopLeft
   repeat with x = 1 to 2
      put item x of tTopLeft + (item x of tNewLoc - item x of sMouseLoc) \ 
            into item x of tNewTopLeft
   end repeat
   set the topleft of stack "revTutorial" to tNewTopLeft
end revTutorialTrackToMouse

on ideMouseDoubleUp pWhich, pTarget
   if sWait["wait condition"] is "state" and sWait["state"] is "double clicked" then
      if revTutorialObjectIsTaggedObject(pTarget, sWait["object"]) then
         revTutorialWaitConditionSatisfied
      end if
   end if
end ideMouseDoubleUp

on ideSelectedObjectChanged 
   local tObject
   put revIDESelectedObjects() into tObject
   if sWait["wait condition"] is "state" and sWait["state"] is "selected" then
      if revTutorialObjectIsTaggedObject(tObject, sWait["object"]) then
         revIDEUnsubscribe "ideSelectedObjectChanged"
         revTutorialWaitConditionSatisfied
      end if
   else if sWait["wait condition"] is "there is a palette for object" then
      -- If the object became deselected, go back a step
      if not revTutorialObjectIsTaggedObject(tObject, sWait["object"]) then
         revTutorialGoBackToSelectStep
      end if
   end if
end ideSelectedObjectChanged

on ideInspectObjects pObjects
   if sWait["wait condition"] is "there is a palette for object" and sWait["palette"] is "inspector" then
      if revTutorialObjectIsTaggedObject(pObjects, sWait["object"]) then
         revIDEUnsubscribe "ideInspectObjects"
         revIDEUnsubscribe "ideSelectedObjectChanged"
         put pObjects into sLastObjects[sWait["palette"]]
         revTutorialWaitConditionSatisfied
      end if
   end if
end ideInspectObjects

on ideEditScript pObject
   if sWait["wait condition"] is "there is a palette for object" and sWait["palette"] is "script editor" then
      if revTutorialObjectIsTaggedObject(the long id of pObject, sWait["object"]) then
         revIDEUnsubscribe "ideEditScript"
         revIDEUnsubscribe "ideSelectedObjectChanged"
         put pObject into sLastObjects[sWait["palette"]]
         revTutorialWaitConditionSatisfied
      end if
   end if
end ideEditScript

on ideToolChanged pTool
   if sWait["wait condition"] is "tool" then
      if revTutorialToolIs(sWait["tool"]) then
         revIDEUnsubscribe "ideToolChanged"
         revTutorialWaitConditionSatisfied
      end if
   end if
end ideToolChanged

on ideOpenCard pTarget
   if sWait["wait condition"] is "this card" then
      local tCard
      put sTaggedObjects["card"][sWait["card"]] into tCard
      if pTarget is tCard then
         revIDEUnsubscribe "ideOpenCard"
         revTutorialWaitConditionSatisfied
      end if
   end if
end ideOpenCard

##############################################################################
#
#                     UTILITIES
#
##############################################################################

command revTutorialSetSEPreference pProp, pValue
   revIDESetPreference "cScriptEditor," & pProp, pValue
   dispatch "revSEUpdateEditors" to revScriptEditorMain() with true
end revTutorialSetSEPreference

function revTutorialIsWaitForProperty pWait
   switch pWait["wait condition"]
      case "property"
      case "fits"
         return true
      case "state"
         switch pWait["state"]
            case "scripted"
               return true
         end switch
         break
   end switch
   return false
end revTutorialIsWaitForProperty

on revTutorialSetPressedState pButtonID
   set the coloroverlay["opacity"] of pButtonID to "50"
   set the coloroverlay["color"] of pButtonID to "0,0,0"
end revTutorialSetPressedState

on revTutorialSetUnpressedState pButtonID
   set the coloroverlay of pButtonID to empty
end revTutorialSetUnpressedState

on revTutorialCopyScriptToEditor pObject
   local tText, tCleanedScript
   put word 1 to -1 of field "Script" of stack "revTutorial" into tText
   repeat for each line tLine in tText
      if tCleanedScript is empty then
         put word 1 to -1 of tLine into tCleanedScript
      else
         put return & word 1 to -1 of tLine after tCleanedScript
      end if
   end repeat
   local tScriptEditor
   put revTutorialHighlightedPalette("script editor") into tScriptEditor
   dispatch "revSESetScript" to tScriptEditor with tCleanedScript
   dispatch "revSEIndentScript" to tScriptEditor
end revTutorialCopyScriptToEditor

function revTutorialObjectIsHighlighted pObject
   if sHighlight is empty then
      return false
   end if
   
   switch sHighlight["type"]
      case "guide"
         return pObject is revIDEStackOfObject(sGuides[sHighlight["guide"]])
      case "property"
         local tInspector
         put revTutorialHighlightedPalette("inspector") into tInspector
         return tInspector is not empty and pObject is the name of tInspector
      case "menu"
         return pObject is the long id of stack revIDEPaletteToStackName("menubar")
      case "tool"
         return pObject is the long id of stack revIDEPaletteToStackName("tools")
      case "object"
         if pObject is sHighlight["object"] or pObject is revIDEStackOfObject(sHighlight["object"]) then
            return true
         end if
         -- fall through and check if the stack is highlighted
      case "stack" 
         if pObject is sHighlight["stack"] then
            return true
         end if
         
         if sHighlight["stack"] is among the items of revIDEAvailablePalettes() then
            return pObject is the long id of stack revIDEPaletteToStackName(sHighlight["stack"])
         end if
   end switch
   return false
end revTutorialObjectIsHighlighted

on revTutorialPositionStackForHighlight pTopLeft, pWidthOverride
   lock screen
   switch sHighlight["type"]
      case "guide"
         revTutorialPositionStack "", sGuides[sHighlight["guide"]], pWidthOverride, "", pTopLeft
         break
      case "property"        
         revTutorialPositionStack "inspector", sHighlight, pWidthOverride, "", pTopLeft
         break
      case "menu"
         revTutorialPositionStack "menubar", sHighlight["menu"], pWidthOverride, "", pTopLeft
         break
      case "toolbar"
         revTutorialPositionStack "menubar", sHighlight["item"], pWidthOverride, "", pTopLeft
         break
      case "tool"
         revTutorialPositionStack "tools", sHighlight["tool"], pWidthOverride, "", pTopLeft
         break
      case "object"  
         revTutorialPositionStack sHighlight["stack"], sHighlight["object"], pWidthOverride, sHighlight["line"] is not empty, pTopLeft
         break
      case "stack"
         revTutorialPositionStack sHighlight["stack"], "", pWidthOverride, "", pTopLeft
         break
      default
         revTutorialPositionStack "", "", pWidthOverride, "", pTopLeft
         break
   end switch
   unlock screen
end revTutorialPositionStackForHighlight

on revTutorialOverrideLocation pTopLeft
      revTutorialPositionStackForHighlight pTopLeft
end revTutorialOverrideLocation

on revTutorialClearHighlights
   switch sHighlight["type"]
      case "tool"
         revIDEUnsubscribe "ideStackMoved", the long id of stack revIDEPaletteToStackName("tools")
         break
      case "property"
         revIDEUnsubscribe "ideStackMoved", the long id of stack revIDEPaletteToStackName("inspector")
         break
      case "menu"
         revIDEUnsubscribe "ideStackMoved", the long id of stack revIDEPaletteToStackName("menubar")
         break
      case "object"
         revIDEUnsubscribe "idePropertyChanged", sHighlight["object"]
         revIDEUnsubscribe "ideStackMoved", revIDEStackOfObject(sHighlight["object"])
         break
      case "stack"
         revIDEUnsubscribe "ideStackMoved", revIDEStackOfObject(sHighlight["stack"])
         break
      case "guide"
         revIDEUnsubscribe "ideStackMoved", revIDEStackOfObject(sGuides[sHighlight["guide"]])
         break
   end switch
   put empty into sHighlight
end revTutorialClearHighlights

function revTutorialObjectsAreSelected pObjects
   local tSelected
   put revIDESelectedObjects() into tSelected
   sort tSelected
   return tSelected is pObjects
end revTutorialObjectsAreSelected

function revTutorialReparentChild pObject
   if word 1 of pObject is "stack" then
      return pObject
   end if
   
   if word 1 of pObject is "card" then
      return pObject
   end if
   
   if word 1 of the owner of pObject is "card" then
      return pObject
   end if
   
   if the sharedBehavior of the owner of pObject is false then
      return pObject
   end if
   
   local tCardSegment
   put segmentOffset("card", pObject) into tCardSegment
   delete word tCardSegment to tCardSegment + 3 of pObject
   return the long id of pObject
end revTutorialReparentChild

command revTutorialStackNameChanged pOldName, pNewName
   -- Update the tagged objects
   repeat for each key tType in sTaggedObjects
      repeat for each key tTag in sTaggedObjects[tType]
         replace "stack" && quote & pOldName & quote \ 
               with  "stack" && quote & pNewName & quote \
               in sTaggedObjects[tType][tTag]
      end repeat
   end repeat
   
   -- Update any wait state if we are waiting. Now that the tagged objects 
   -- are updated just call DoWait again with the current wait state.The 
   -- type/tag in the sWait array will resolve to the updated long ID
   if sWait is not empty then
      -- if new condition is immediately satisified (i.e. if we are waiting for a
      -- stack name change) then sWaiting will still be false after revTutorialDoWait
      put false into sWaiting
      revTutorialDoWait sWait
      if not sWaiting then
         revTutorialWaitConditionSatisfied
      end if
   end if
end revTutorialStackNameChanged

# Take a tutorial tagged object (an array with 'type' and 'tag' keys)
# and return the corresponding long ID (or list of long IDs for 'set' types)
function revTutorialResolveObjectToLongID pTaggedObject, pUpdate
   local tType, tTag, tObj
   put pTaggedObject["type"] into tType
   put pTaggedObject["tag"] into tTag
   put sTaggedObjects[tType][tTag] into tObj
   
   if tObj is empty then
      return tObj
   end if
   
   if tType is not "set" then
      local tResolvedLongID, tIDChanged
      put revTutorialReparentChild(tObj) into tResolvedLongID
      if tResolvedLongID is not tObj then
         put true into tIDChanged
      end if
      if pUpdate or tIDChanged then
         put the long id of tObj into tObj
         put tObj into sTaggedObjects[tType][tTag]
      end if
      return tObj
   end if
   
   local tLongIDs, tLongID
   repeat for each element tElement in tObj
      put revTutorialResolveObjectToLongID(tElement, pUpdate) into tLongID
      if tLongIDs is empty then
         put tLongID into tLongIDs
      else
         put return & tLongID after tLongIDs
      end if
   end repeat
   sort tLongIDs
   return tLongIDs
end revTutorialResolveObjectToLongID

function revTutorialObjectIsTaggedObject pLongID, pTaggedObject
   local tObj
   put revTutorialResolveObjectToLongID(pTaggedObject) into tObj
   sort pLongID
   return tObj is pLongID
end revTutorialObjectIsTaggedObject

function revTutorialToolIs pTool
   if pTool is "edit" and the tool is "pointer tool" then
      return true
   end if
   
   if pTool is "run" and the tool is "browse tool" then
      return true
   end if
   
   if pTool is "graphic" and the tool is "graphic tool" then
      return true
   end if
   
   return false
end revTutorialToolIs

function revTutorialThereIsAPalette pPalette
   if there is a stack revIDEPaletteToStackName(pPalette) then
      return the mode of stack revIDEPaletteToStackName(pPalette) is not 0
   end if
   return false
end revTutorialThereIsAPalette

function revTutorialObjectPropertyIsValue pObjectIDs, pProperty, pValue, pIsNot
   repeat for each line tObject in pObjectIDs
      if pProperty ends with "color" then
         if revTutorialColorIs(the pProperty of tObject, pValue) is pIsNot then
            return false
         end if
      else if pProperty is "script" then
         revTutorialCompareScript the script of tObject, pValue
         if (the result is empty) is pIsNot then
            return false
         end if
      else if pProperty is "name" then
         if (the short name of tObject is pValue) is pIsNot then
            return false
         end if
      else 
         if (the pProperty of tObject is pValue) is pIsNot then
            return false
         end if
      end if
   end repeat
   return true
end revTutorialObjectPropertyIsValue

function revTutorialObjectHasPalette pPalette, pObjects
   local tPalette
   repeat for each line tObject in pObjects
      if pPalette is "inspector" then
         put revIDEInspectorForObject(tObject) into tPalette
      else if pPalette is "script editor" then
         put revScriptEditor(tObject) into tPalette
      end if
      if tPalette is empty then
         return false
      end if
   end repeat
   return true
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
   lock screen
   lock messages
   local tRect
   put the rect of sGuides[pGuide] into tRect
   if pObject begins with "stack" then
      set the resizable of pObject to false
      set the width of pObject to item 3 of tRect + 1
      set the height of pObject to item 4 of tRect + 1
   else 
      set the rect of pObject to item 1 of tRect - 1, item 2 of tRect - 1, item 3 of tRect + 1, item 4 of tRect + 1
   end if
   unlock messages
   unlock screen
end revTutorialSnapObjectToGuide

private function revTutorialGetMistake pObjScript, pTokenNum, pReadToken, pTargetToken
   lock messages
   local tDefaultStack
   put the defaultStack into tDefaultStack
   set the defaultStack to "revTutorial"
   create invisible field "script_tester"
   put pObjScript into field "script_tester"
   
   local tCharIndex, tLineIndex, tLineChars
   put the lineIndex of token pTokenNum of field "script_tester" into tLineIndex
   put the charIndex of token pTokenNum of field "script_tester" into tCharIndex
   put the number of chars in line 0 to tLineIndex - 1 \ 
         of field "script_tester" into tLineChars
   subtract tLineChars from tCharIndex
   
   local tMistake
   if pTargetToken is not empty then 
      put merge(quote & "[[pReadToken]]" & quote && \
            "instead of" && quote & "[[pTargetToken]]" & quote && \
            "at char [[tCharIndex]] of line [[tLineIndex]]") into tMistake
   else
      put merge("Unexpected additional script" && \
            quote & "[[pReadToken]]" & quote && \
            "at char [[tCharIndex]] of line [[tLineIndex]]") into tMistake
   end if
   delete field "script_tester"
   set the defaultStack to tDefaultStack
   unlock messages
   return tMistake
end revTutorialGetMistake

// In the future we might want to add a bit more "approximity" to this.
command revTutorialCompareScript pObjScript, pTargetScript
   local tTokenNum, tMistake, tToken
   repeat for each token tTargetToken in pTargetScript
      add 1 to tTokenNum
      put token tTokenNum of pObjScript into tToken
      if tTargetToken is not tToken then
         put revTutorialGetMistake(pObjScript, tTokenNum, tToken, tTargetToken) \
               into tMistake
         exit repeat
      end if
   end repeat
   
   if tMistake is empty then
      add 1 to tTokenNum
      put token tTokenNum of pObjScript into tToken
      if tToken is not empty then
         put revTutorialGetMistake(pObjScript, tTokenNum, tToken, empty) \
               into tMistake
      end if
   end if
   
   return tMistake
end revTutorialCompareScript

constant kColorTolerance = 10
function revTutorialColorIs pColor, pTarget
   if pColor is empty and pTarget is not empty then
      return false
   end if
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

function revTutorialGroupContainsObjects pGroupID, pObjects
   # Check the objects of the group are the target objects
   local tChildIDs, tChildID
   repeat for each line tId in the childControlIDs of pGroupID
      put the long id of control id tID of pGroupID into tChildID
      if tChildIDs is empty then
         put tChildID into tChildIDs
      else
         put return & tChildID after tChildIDs
      end if
   end repeat
   
   sort tChildIDs
   return tChildIDs is pObjects
end revTutorialGroupContainsObjects

##############################################################################
#
#                     AUTORUN
#
##############################################################################

local sRunningInfo
on revTutorialRunTutorial pCourse, pTutorial, pLesson, pLocation, pFromStep, pUntilStep
   local tTutorialData
   put revIDETutorialLessonContent(pCourse, pTutorial, pLesson, pLocation) into tTutorialData
   
   local tData
   put revTutorialParseData(tTutorialData) into tData
   
   put pCourse into sRunningInfo["course"]
   put pTutorial into sRunningInfo["tutorial"]
   put pLesson into sRunningInfo["lesson"]
   put pLocation into sRunningInfo["location"]
   
   if pFromStep is empty then
      put tData["first step"] into pFromStep
   end if
   
   revTutorialRunSteps tData, pFromStep, pUntilStep
end revTutorialRunTutorial

on revTutorialRunSteps pSteps, pFromStep, pUntilStep
   lock screen
   local tStep, tStepNum
   put pFromStep into tStep
   repeat until tStep is empty
      revTutorialSetContextualStepData pSteps[tStep]
      revTutorialRunStep pSteps[tStep]["actions"]
      if tStep is pUntilStep then
         exit repeat
      end if
      put pSteps[tStep]["actions"]["go"]["step"] into tStep
   end repeat
   unlock screen
end revTutorialRunSteps

on revTutorialRunStep pStepActions
   lock screen
   # Run any load actions
   revTutorialRunLoad pStepActions["load"]
   # Execute any set creation actions
   revTutorialExecuteAction pStepActions["set"]
   # Run action that satisfies wait condition
   revTutorialRunAction pStepActions
   unlock screen
end revTutorialRunStep

on revTutorialRunLoad pLoadAction
   if pLoadAction is empty then
      exit revTutorialRunLoad
   end if
   # Store currently running lesson in case there are further load actions
   local tRunningInfo
   put sRunningInfo into tRunningInfo
   revTutorialRunTutorial tRunningInfo["course"], tRunningInfo["tutorial"], \ 
         pLoadAction["lesson"], tRunningInfo["location"]
   put tRunningInfo into sRunningInfo
end revTutorialRunLoad

# We don't actually need to select objects, just keep track of what is supposed to be selected
local sSelected
on revTutorialRunAction pActionData
   lock screen
   lock messages
   local tWaitData
   put pActionData["wait"] into tWaitData
   switch tWaitData["wait condition"]
      case "there is an object"
         revTutorialCreateAndCaptureObjects tWaitData, pActionData["capture"], pActionData["highlight"]
         break
      case "property"  
         # Set the property of the objects
         revTutorialSetPropertyOfObjects revTutorialResolveObjectToLongID(tWaitData["object"]), tWaitData["property"], tWaitData["value"], tWaitData["is not"], tWaitData["default"]
         break
      case "fits" 
         # Set the rect of the objects
         if pActionData["add guide"] is empty then
            throw "no guide added in wait until object fits action"
         end if
         if tWaitData["object"]["type"] is "stack" then
            put revIDERelativeRectToAbsolute(pActionData["add guide"]["rect"], sTaggedObjects["stack"][tWaitData["object"]["tag"]]) into pActionData["add guide"]["rect"]
         end if
         revTutorialSetPropertyOfObjects revTutorialResolveObjectToLongID(tWaitData["object"]), "rect", pActionData["add guide"]["rect"]
         break
      case "state"
         switch tWaitData["state"]
            case "scripted"
               # See if the object has a script editor open
               local tPalette, tObject
               put revTutorialResolveObjectToLongID(tWaitData["object"]) into tObject
               put revScriptEditor(tObject) into tPalette
               if tPalette is not empty then
                  # If so, check the script. If correct, apply the script
                  if sScriptCheck["correct script"] then
                     dispatch "revSEApply" to stack tPalette with true
                  else
                     # Otherwise set the script
                     dispatch "revSESetScript" to stack tPalette with tWaitData["script"]
                  end if
               else
                  # If there is no SE, just set the script of the objects directly
                  revTutorialSetPropertyOfObjects tObject, "script", tWaitData["script"]
               end if
               break
            case "selected"
               put revTutorialResolveObjectToLongID(tWaitData["object"]) into sSelected
               revIDESelectObjects sSelected
               break
            case "grouped"
               revTutorialCreateAndCaptureObjects tWaitData, pActionData["capture"]
               break
            default
               # No other states require action
               break
         end switch
         break
      case "this card"
         revTutorialGoCard tWaitData["card"]
         break
      case "tool"
         local tTool
         if tWaitData["tool"] is "run" then
            put "browse" into tTool
         else
            put "pointer" into tTool
         end if
         revIDESetTool tTool
         break
         # No other waits require action
      default
         break
   end switch
   unlock messages
   unlock screen
end revTutorialRunAction

on revTutorialCreateAndCaptureObjects pWaitData, pCaptureData, pHighlightData
   if not (the environment begins with "development") then
      revTutorialCreateAndCaptureObjectsStandalone pWaitData, pCaptureData, pHighlightData
      exit revTutorialCreateAndCaptureObjects
   end if
   local tCapture, tType, tStacksCaptured
   # Create the object and tag it
   repeat with x = 1 to the number of elements in pCaptureData["captures"]
      put pCaptureData["captures"][x] into tCapture
      put tCapture["object type"] into tType
      if tType is "stack" then
         revIDEActionNewMainstack "default"
         put the result into sTaggedObjects["stack"][tCapture["tag"]]
         put true into tStacksCaptured[tCapture["tag"]]
      else if tType is "card" then
         local tCardID
         # if we already captured this card's stack then we don't need to create a new card
         if tStacksCaptured[tCapture["target stack"]["tag"]] then
            delete variable tStacksCaptured[tCapture["target stack"]["tag"]]
            put the long id of this card of stack sTaggedObjects["stack"][tCapture["target stack"]["tag"]] into tCardID
         else
            set the defaultStack to sTaggedObjects["stack"][tCapture["target stack"]["tag"]]
            revIDEActionNewCard
            put the result into tCardID
         end if
         put tCardID into sTaggedObjects["card"][tCapture["tag"]]
      else if tType is "group" then
         local tChildren
         put revTutorialResolveObjectToLongID(pWaitData["object"]) into tChildren
         revIDEGroupObjects tChildren
         if the result is empty and exists(it) then
            put it into sTaggedObjects["group"][tCapture["tag"]]
            -- force recompute the children long ids
            get revTutorialResolveObjectToLongID(pWaitData["object"], true)
         end if
      else
         if pHighlightData["tool"] is not empty then
            dispatch function "toolObjectName" to stack "revTools" with pHighlightData["tool"]
            revIDECreateObject the result, sTaggedObjects["stack"][tCapture["target stack"]["tag"]]
            put the result into sTaggedObjects[tType][tCapture["tag"]]
         else if pHighlightData["item"][1] contains "Import" then
            # Deal with 'import'
            if sStepContextA["file"] is empty then
               throw "No file specified for import"
            end if
            local tImportType
            switch tType
               case "image"
                  put "image" into tImportType
                  break
               case "audioClip"
                  put "audio" into tImportType
                  break
               case "videoClip"
                  put "video" into tImportType
                  break
               case "field"
                  put "text" into tImportType
                  break
               case "widget"
                  if pHighlightData["item"][2] contains "graph" then
                     put "graph" into tImportType
                     break
                  end if
               default
                  throw "invalid import type" && tType
            end switch
            revIDEImportControl tImportType, revIDETutorialResourcePath(sRunningInfo) & slash & sStepContextA["file"]
            put the result into sTaggedObjects[tType][tCapture["tag"]]
         else if pHighlightData["item"][1] contains "duplicate" then
            revIDESelectObjects sSelected
            revIDEActionDuplicate
            put the result into sTaggedObjects[tType][tCapture["tag"]]
         else
            do "create" && tType
            put it into sTaggedObjects[tType][tCapture["tag"]]
         end if
      end if
   end repeat
   local tObject
   put revTutorialResolveObjectToLongID(pWaitData["object"]) into tObject
   if tObject is empty then
      throw "No capture action for object wait" && pWaitData["object"]["type"] && pWaitData["object"]["tag"]
   end if
end revTutorialCreateAndCaptureObjects

on revTutorialSetPropertyOfObjects pObjects, pProp, pValue, pIsNot, pDefault
   # If the step specified a value then we set this instead of the string "value"
   if pValue is "value" and sStepContextA["value"] is not empty then
      put sStepContextA["value"] into pValue
   end if
   
   if pIsNot then
      put pDefault into pValue
   end if
   
   if the environment begins with "development" then
      revIDESetPropertyOfObject pObjects, pProp, pValue
   else
      repeat for each line tLine in pObjects
         set the pProp of tLine to pValue
      end repeat
   end if
end revTutorialSetPropertyOfObjects

on revTutorialCreateAndCaptureObjectsStandalone pWaitData, pCaptureData, pHighlightData
   local tCapture, tType, tStacksCaptured
   # Create the object and tag it
   repeat with x = 1 to the number of elements in pCaptureData["captures"]
      put pCaptureData["captures"][x] into tCapture
      put tCapture["object type"] into tType
      if tType is "stack" then
         create stack
         put it into sTaggedObjects["stack"][tCapture["tag"]]
         put true into tStacksCaptured[tCapture["tag"]]
      else 
         set the defaultStack to sTaggedObjects["stack"][tCapture["target stack"]["tag"]]
         if tType is "card" then
            local tCardID
            # if we already captured this card's stack then we don't need to create a new card
            if tStacksCaptured[tCapture["target stack"]["tag"]] then
               delete variable tStacksCaptured[tCapture["target stack"]["tag"]]
               put the long id of this card of stack sTaggedObjects["stack"][tCapture["target stack"]["tag"]] into tCardID
            else
               create card
               put it into tCardID
            end if
            put tCardID into sTaggedObjects["card"][tCapture["tag"]]
         else if tType is "widget" then
            local tKind
            put word 2 of pHighlightData["tool"] into tKind
            create widget as tKind
            put it into sTaggedObjects["widget"][tCapture["tag"]]
         else if tType is "group" then
            local tChildren
            put revTutorialResolveObjectToLongID(pWaitData["object"]) into tChildren
            revIDEGroupObjects tChildren
            if the result is empty and exists(it) then
               put it into sTaggedObjects["group"][tCapture["tag"]]
               -- force recompute the children long ids
               get revTutorialResolveObjectToLongID(pWaitData["object"], true)
            end if
         else
            if pHighlightData["item"][1] contains "Import" then
               # Deal with 'import'
               if sStepContextA["file"] is empty then
                  throw "No file specified for import"
               end if
               local tFile
               put revIDETutorialResourcePath(sRunningInfo) & slash & sStepContextA["file"] into tFile
               switch tType
                  case "image"
                     create image
                     set the filename of it to tFile
                     put it into sTaggedObjects[tType][tCapture["tag"]]
                     break
                  case "audioClip"
                     import videoClip from file tFile
                     put the long id of the last audioClip into sTaggedObjects[tType][tCapture["tag"]]
                     break
                  case "videoClip"
                     import videoClip from file tFile
                     put the long id of the last audioClip into sTaggedObjects[tType][tCapture["tag"]]
                     break
                  case "field"
                     create field
                     set the text of it to textDecode(url ("binfile:" & tFile), "utf-8")
                     put it into sTaggedObjects[tType][tCapture["tag"]]
                     break
                  case "widget"
                     if pHighlightData["item"][2] contains "graph" then
                        create widget as "com.livecode.widget.lineGraph"
                        set the graphData of it to textDecode(url ("binfile:" & tFile), "utf-8")
                        put it into sTaggedObjects[tType][tCapture["tag"]]
                        break
                     end if
                  default
                     throw "invalid import type" && tType
               end switch
            else if pHighlightData["item"][1] contains "duplicate" then
               revIDESelectObjects sSelected
               revIDEActionDuplicate
               put the result into sTaggedObjects[tType][tCapture["tag"]]
            else
               do "create" && tType
               put it into sTaggedObjects[tType][tCapture["tag"]]
            end if
         end if
      end if
   end repeat
   local tObject
   put revTutorialResolveObjectToLongID(pWaitData["object"]) into tObject
   if tObject is empty then
      throw "No capture action for object wait" && pWaitData["object"]["type"] && pWaitData["object"]["tag"]
   end if
end revTutorialCreateAndCaptureObjectsStandalone

on revTutorialGoCard pCard
   if pCard is not among the keys of sTaggedObjects["card"] then
      throw "unsatisfiable wait condition: wait until this card is" && pCard
      exit revTutorialGoCard
   end if
   go sTaggedObjects["card"][pCard]
end revTutorialGoCard
