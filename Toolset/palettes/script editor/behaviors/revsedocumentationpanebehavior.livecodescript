script "revSEDocumentationPaneBehavior"
# String representing the last searched for doc, this is what the cDoc was last set to
local sDoc = ""
local sTypesA, sLibsA
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
   local tRect
   put the rect of me into tRect
   split tRect by comma
   set the rect of field "View" of me to tRect[1], tRect[2], tRect[3], \
         tRect[4] - sMetrics["bottombarHeight"]
   set the bottomRight of button "FullMode" of me to \ 
         tRect[3] + sMetrics["toggleButtonMargin"], tRect[4]
   set the width of button "LaunchDocs" of me to \ 
         the formattedWidth of button "LaunchDocs" of me + \ 
         sMetrics["launchButtonPadding"]
   set the bottomLeft of button "LaunchDocs" of me to tRect[1] + \ 
         sMetrics["launchButtonMargin"], tRect[4] - 1
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
      renderDoc
   end if
end update

####################################################################

# Private functions, shouldnt need to call these from outside the control

####################################################################

private function renderDocDataShort pData, pIndex
   local tData
   put pData[pIndex] into tData
   
   local tName, tSyntax, tSummary, tType
   put tData["display name"] into tName
   put tData["syntax"] into tSyntax
   put tData["summary"] into tSummary
   if tSummary is empty then
      put tData["description"] into tSummary
   end if
   put tData["type"] into tType
   
   local tResult
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
end renderDocDataShort

# Returns
#   The id of the image to use in the dictionary to represent this platform
function revDocumentationPlatformImage pPlatform
   switch pPlatform
      case "mac"
         return "204117"
         break
      case "win"
         return "204121"
         break
      case "linux"
         return "204119"
         break
      case "ios"
         return "1095"
         break
      case "android"
         return "1094"
         break
      default
         return empty
         break
   end switch
end revDocumentationPlatformImage

private function fontTag
   return "<font size=" & quote & "25" & quote && "color=" & quote & "#606060" & quote & ">"
end fontTag

private function renderElement pKey, pData, pIndex
   local tData
   put pData[pIndex] into tData
   
   local tHtml, tTag, tContent
   put "<p><b>" & fontTag() into tTag
   put pKey & "</font></b>" & return after tTag
   switch pKey
      case "type"
         put removeAngleBrackets(tData[pKey]) after tContent
         if the number of elements in pData > 1 then
            put " (also " & renderDocAlternatives(pData, pIndex) & ")" after tContent
         end if
      case "os"
         repeat for each element tItem in tData[pKey]
            local tImageID
            put revDocumentationPlatformImage(tItem) into tImageID
            # Ignore invalid platform data
            if tImageID is not empty then
               put "<img src=" & quote & tImageID & quote & "></img>" after tContent
            end if
         end repeat
         break
      case "example"
      case "syntax"
         repeat for each element tElement in tData[pKey]
            put tTag after tContent
            repeat for each line tLine in tElement
               put "<p>" & return after tContent
               put removeAngleBrackets(tLine, pKey is "syntax") & return after tContent
               put "</p>" & return after tContent
            end repeat
            put "</p><p />" & return after tContent
         end repeat
         return tContent
      case "description"
         repeat for each line tLine in tData[pKey]
            put "<p>" & return after tContent
            put removeAngleBrackets(tLine, true) & return after tContent
            put "</p>" & return after tContent
         end repeat
      default
         put removeAngleBrackets(tData[pKey]) after tContent
         break
   end switch
   if tContent is not empty then
      put tTag before tContent
      put "</p><p />" & return after tContent
   end if
   return tContent
end renderElement

private function docsElementsFull
   return "display name,type,syntax,summary,example,os,description,references"
   -- synonyms, associations, introduced, platforms, security, params, value, tags, changes
end docsElementsFull

private function docsElementsShort
   return "display name,type,syntax,summary"
end docsElementsShort

private function renderDocData pData, pIndex, pFull
   if not pFull then
      return renderDocDataShort(pData, pIndex)
   end if
   
   local tHtml, tElements
   put docsElementsFull() into tElements

   repeat for each item tElement in tElements
      put renderElement(tElement, pData, pIndex) after tHTML
   end repeat
   return tHtml
end renderDocData

private command renderDoc pType, pLib
   if sLastFoundDoc is empty or sDoc is empty then
      renderEmpty
      exit renderDoc
   end if
   
   # Documentation library: Retrieve the summary from the docs database
   local tHTML
   put renderDocDictionary(sDoc, pType, pLib) into tHTML
   set the htmlText of field "View" of me to tHTML
   
   scrollbarCheck
end renderDoc

private function removeAngleBrackets pText, pIsSyntax
   local tRegex, tStart, tEnd
   put "\<([^\>]*)\>" into tRegex
   set the itemdelimiter to "|"
   local tNewText, tReplacement
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

# Returns HTML of that doc in the form required for this component
private function renderDocDictionary pTag, pType, pLib
   local tResult, tData
   
   # Get the required info from the doc
   put ideDocsFetchScriptData(pTag) into tData
   
   if pType is empty then
      put sTypesA[pTag] into pType
   end if
   if pLib is empty then
      put sLibsA[pTag] into pLib
   end if
   
   put pType into sTypesA[pTag]
   put pLib into sLibsA[pTag]
   
   repeat for each key tIndex in tData
      if pType is not empty and \
            tData[tIndex]["type"] is pType and \
            pLib is not empty and \
            tData[tIndex]["library"] is pLib then
         return renderDocEntry(tData, tIndex)
      end if
   end repeat
   
   put tData[1]["type"] into sTypesA[pTag]
   put tData[1]["library"] into sLibsA[pTag]
   return renderDocEntry(tData, 1)
end renderDocDictionary 

private function renderDocEntry pData, pIndex
   if prefGet("viewMode") is "Full" then
      return renderDocData(pData, pIndex, true)
   else
      return renderDocData(pData, pIndex, false)
   end if
end renderDocEntry

function renderDocAlternatives pAlternatives, pCurIndex
   local tFormattedAlternatives, tAlternative, tAlternativeIndices
   put the keys of pAlternatives into tAlternativeIndices
   sort tAlternativeIndices by pAlternatives[each]["type"]
   sort tAlternativeIndices by pAlternatives[each]["library"]
   repeat for each line tAlternativeIndex in tAlternativeIndices
      if tAlternativeIndex is pCurIndex then
         next repeat
      end if
      
      put "<a>" & pAlternatives[tAlternativeIndex]["library"] && \
            "-" && pAlternatives[tAlternativeIndex]["type"] & "</a>" \
            into tAlternative
      
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
   set the itemdelimiter to "-"
   renderDoc word 1 to -1 of item 2 of pLink, word 1 to -1 of item 1 of pLink
end linkClicked

function prefGet pTag
  if pTag is "viewMode" then
    if the hilite of button "FullMode" of me then return "Full"
    return "Short"
  end if
end prefGet

on mouseUp
   local tTag, tType
   switch the short name of the target
      case "FullMode"
         renderDoc
         break
         
      case "LaunchDocs"
         revIDEGoToLCSDictionaryEntry sDoc, sTypesA[sDoc], sLibsA[sDoc]
         break
   end switch
end mouseUp

private command metricsInit
   put "8,20,110,8" into sMetrics["viewFieldMargins"]
   put 96 into sMetrics["toggleButtonWidth"]
   put 24 into sMetrics["toggleButtonHeight"]
   put 24 into sMetrics["launchButtonHeight"]
   put 12 into sMetrics["launchButtonPadding"]
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
