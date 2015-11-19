script "revSEDocumentationPaneBehavior"
# String representing the last searched for doc, this is what the cDoc was last set to
local sDoc = ""
# String returned by the last Documentation search, this can be used to reload the last doc.
local sLastFoundDoc = ""

# Stores a list of other docs which also matched
local sAlternativeDocs

# Stores the styles for each doc
local sStyles
# Stores the metrics for this component
local sMetrics

####################################################################

# Interface

####################################################################

command paneOpenControl
   metricsInit
   
   # The default stack must be changed here because the create command will only create objects
   # in the default stack, even when the "create in me" form is used.
   local tOldDefaultStack
   put the defaultStack into tOldDefaultStack
   set the defaultStack to revTargetStack(the long id of me)
   
   lock messages
   # Main view Field
   reset the templateField
   set the name of the templateField to "View"
   set the lockText of the templateField to true
   set the traversalOn of the templateField to true
   set the backgroundColor of the templateField to "255,255,255"
   set the showBorder of the templateField to false
   set the lockLocation of the templateField to true
   set the margins of the templateField to sMetrics["viewFieldMargins"]
   create field in me
   reset the templateField
   set the cDocPaneObject of field "View" of me to true
   
   # Toggle button for viewing mode
   reset the templateButton
   set the name of the templateButton to "FullMode"
   set the style of the templateButton to "checkbox"
   set the label of the templateButton to "Full Document"
   set the lockLocation of the templateButton to true
   set the hilite of the templateButton to false
   set the traversalOn of the templateButton to false
   set the showFocusBorder of the templateButton to false
   set the threeD of the templateButton to false
   set the borderWidth of the templateButton to 0
   set the showBorder of the templateButton to false
   set the width of the templateButton to sMetrics["toggleButtonWidth"]
   set the height of the templateButton to sMetrics["toggleButtonHeight"]
   create button in me
   reset the templateButton
   set the cDocPaneObject of button "FullMode" of me to true
   
   # Button to launch docs
   reset the templateButton
   set the name of the templateButton to "LaunchDocs"
   set the label of the templateButton to "Launch Documentation"
   set the lockLocation of the templateButton to true
   set the width of the templateButton to sMetrics["launchButtonWidth"]
   set the height of the templateButton to sMetrics["launchButtonHeight"]
   create button in me
   reset the templateButton
   set the cDocPaneObject of button "LaunchDocs" of me to true
   
   unlock messages
   
   set the defaultStack to tOldDefaultStack
   
   # Resize the controls
   paneResizeControl
end paneOpenControl

command paneCloseControl
  repeat with x = the number of controls of me down to 1
    if the cDocPaneObject of control x of me then
      delete control x of me
    end if
  end repeat
end paneCloseControl

command paneResizeControl
   metricsInit
  set the rect of field "View" of me to (the left of me),(the top of me),(the right of me),(the bottom of me - sMetrics["bottombarHeight"])
  set the bottomRight of button "FullMode" of me to (item 1 of the bottomRight of me + sMetrics["toggleButtonMargin"]), (item 2 of the bottomRight of me)
  set the bottomLeft of button "LaunchDocs" of me to (item 1 of the bottomLeft of me + sMetrics["launchButtonMargin"]), (item 2 of the bottomLeft of me - 1)
  scrollbarCheck
end paneResizeControl

# Description
#   Sent by the parent when something might have changed that could affect the documentation viewer
#   Causes the documentation viewer to re-render whatever its last chosen document was. And resize itself.
command update
  paneResizeControl
  
  put sePrefGet("documentation,lastLoadedDoc") into sLastFoundDoc
  put sePrefGet("documentation,lastMatchingSearch") into sDoc
  put sePrefGet("documentation,lastLoadedAlternativeDocs") into sAlternativeDocs
  
  if sLastFoundDoc is empty then
    put empty into sDoc
    renderEmpty
 else
    if prefGet("viewMode") is "Full" then
      renderDocFull
    else
      renderDocShort
    end if
  end if
end update

####################################################################

# Private functions, shouldnt need to call these from outside the control

####################################################################

private command renderDocShort
   renderDoc
end renderDocShort

private command renderDoc pType
   if sLastFoundDoc is empty or sDoc is empty then
      renderEmpty
      exit renderDoc
   end if
   
   # Documentation library: Retrieve the summary from the docs database
   local tHTML
   put renderDocDictionary(sDoc, pType) into tHTML
   set the htmlText of field "View" of me to tHTML
   
   scrollbarCheck
end renderDoc

private function removeAngleBrackets pText, pIsSyntax
   local tRegex, tStart, tEnd
   put "\<([^\>]*)\>" into tRegex
   set the itemdelimiter to "|"
   local tNewText
   repeat while matchChunk(pText, tRegex, tStart, tEnd)
      put char 1 to tStart - 2 of pText after tNewText
      if pIsSyntax then
         put "<i>" after tNewText
      end if	
      put char tStart to tEnd of pText into tReplacement
      if item 2 of tReplacement is not empty then
         put item 2 of tReplacement into tReplacement
      end if	
      put tReplacement after tNewText
      if pIsSyntax then
         put "</i>" after tNewText
      end if
      delete char 1 to tEnd + 1 of pText
   end repeat
   put pText after tNewText
   return tNewText
end removeAngleBrackets

local sTypesA
# Returns HTML of that doc in the form required for this component
private function renderDocDictionary pTag, pType
   local tResult
   
   # Get the required info from the doc
   put ideDocsFetchData("livecode_script", pTag) into tData
   
   if pType is empty then
      put sTypesA[pTag] into pType
   end if
   
   put pType into sTypesA[pTag]
   
   if pType is not empty then
      repeat for each key tIndex in tData
         if tData[tIndex]["type"] is pType then
            return renderDocEntry(tData, tIndex)
         end if
      end repeat
   end if
   
   return renderDocEntry(tData, 1)
end renderDocDictionary 

private function renderDocEntry pData, pIndex
   local tData
   put pData[pIndex] into tData

   local tName, tSyntax, tSummary, tType
   put tData["display name"] into tName
   put tData["syntax"] into tSyntax
   put tData["summary"] into tSummary
   put tData["type"] into tType
   
   # Build the html to display it
   put "<p>" & return into tResult
   
   # Documentation library: returns html, eg a font tag
   put tType & return after tResult
   
   # Documentation library: returns html ending tags
   put "<b><font size=" & quote & "25" & quote && "color=" & quote & "#606060" & quote & ">" after tResult
   put tName & "</font></b>" & return after tResult
   
   if the number of elements in pData > 1 then
      put " (also " & renderDocAlternatives(pData, pIndex) & ")" after tResult
   end if
   
   put "</p><p />" & return after tResult
   
   put "<p>" & return after tResult
   put removeAngleBrackets(tSummary) & return after tResult
   put "</p><p />" & return after tResult
   
   repeat for each element tElement in tSyntax
      repeat for each line tLine in tElement
         put "<p>" & return after tResult
         put removeAngleBrackets(tLine, true) & return after tResult
         put "</p>" & return after tResult
      end repeat
   end repeat
   
   return tResult
end renderDocEntry

function renderDocAlternatives pAlternatives, pCurIndex
   local tFormattedAlternatives, tAlternative
   repeat for each key tAlternativeIndex in pAlternatives
      if tAlternativeIndex is pCurIndex then
         next repeat
      end if
      
      put "<a>" & pAlternatives[tAlternativeIndex]["type"] & "</a>" into tAlternative
      
      if tFormattedAlternatives is empty then
         put tAlternative into tFormattedAlternatives
      else
         put comma & space & tAlternative after tFormattedAlternatives
      end if
   end repeat
   return tFormattedAlternatives
end renderDocAlternatives

# What to display in the field when no doc is loaded
private command renderEmpty
  put empty into field "View" of me
end renderEmpty

private command scrollbarCheck
    set the vScrollbar of field "View" of me to (the formattedHeight of field "View" of me > the height of field "View" of me)
end scrollbarCheck

on linkClicked pLink
   renderDoc pLink
end linkClicked

function prefGet pTag
  if pTag is "viewMode" then
    if the hilite of button "FullMode" of me then return "Full"
    return "Short"
  end if
end prefGet

on mouseUp
   local tTag, tType, tCategory
   switch the short name of the target
      case "FullMode"
         if prefGet("viewMode") is "Full" then
            renderDocFull
         else
            renderDocShort
         end if
         break
         
      case "LaunchDocs"
         if sLastFoundDoc is not empty then
            put item 1 of sLastFoundDoc into tTag
            put item 2 of sLastFoundDoc into tCategory
            put item 3 of sLastFoundDoc into tType
            
            if tType is empty then
               put "dictionary" into tType
            end if
            
            send "entryGoto tTag,tCategory,tType" to revDocumentationDictionaryStack() in 0 milliseconds
         end if
         modeless revDocumentationDictionaryStack()
         
         break
   end switch
end mouseUp

private command metricsInit
   put "8,20,110,8" into sMetrics["viewFieldMargins"]
   put 96 into sMetrics["toggleButtonWidth"]
   put 24 into sMetrics["toggleButtonHeight"]
   put 124 into sMetrics["launchButtonWidth"]
   put 24 into sMetrics["launchButtonHeight"]
   put 26 into sMetrics["bottombarHeight"]
   put 1 into sMetrics["launchButtonMargin"]
   
   # OK-2008-06-29 : Bug 6566 - On Macs, the "Full Document" toggle button is overlapped by the stack resizer triangle,
   # add a platform specific margin setting to fix this.
   if seGetPlatform() is "MacOS" then
      put -30 into sMetrics["toggleButtonMargin"]
   else
      put 0 into sMetrics["toggleButtonMargin"]
   end if
end metricsInit
