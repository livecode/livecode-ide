script "com.livecode.scripteditor.behavior.editorcommon"
local sObjectId

# The following variables store information used for the undo / redo system.
local sTextOperationOffsets
local sTextOperationNewTexts
local sTextOperationOldTexts
local sTextOperationIndex

local sTextOperationTop

local sTextGroupLabels
local sTextGroupLengths
local sTextGroupIndex
local sTextGroupTop
local sTextFormatKeywordMap

local sTextMark
local sLastSelectedChunk
local sLastNonEmptySelection

# Stores an array of cached object scripts for switching back to objects with unsaved changes
local sScriptCache

# OK-2009-01-17 : Bug 7169 - Store whether scripts are "dirty" or not, i.e whether the user has actually
# modified them, as opposed to they were modified by the script editor. (This can happen in the case of template scripts)
local sDirty

# Stores requests to update the script editor in reponse to a selection changed
local sSelectionUpdateRequest

# Stores requests to update the script editor panes
local sPaneUpdateRequest

# Stores the id of the last request to update the gutter, if there is one pending.
local sGutterUpdateRequest

# We also need to store whether the last update request involved text changing and 
# whether it required the compilation errors to be updated. This is because it may be
# cancelled by a subsequent request that didn't require these things, resulting in the update
# being lost.
local sGutterUpdateRequestDetails

# Stores that an arrowKey is pressed from rawKeyDown
local sArrowKeyPressed

local sPlaceholders
local sEditChunks
local sEditPlaceholder

constant kPlaceholderDefaultSearchLines = 20
constant kPlaceholderDefaultBackgroundColor = "240,240,240"

# 2017-08-01 bhall2001 previous vScroll position of the Editor field
local sVScroll

# 2017-08-01 bhall2001 Toggles between true/false on each up arrow key pressed
# Note: up arrow key sends 2 scrollBarDrag messages. Used as flag
# to process only 1 of the messages.
local sSkipUpArrow = false

# OK-2009-01-17 : Bug 7169
command setDirty pObject, pValue
   put pValue into sDirty[pObject]
end setDirty

command getDirty pObject
   return sDirty[pObject]
end getDirty

command setObjectID pObjectID
   if pObjectID is not empty then
      local tRuggedID
      put revRuggedId(pObjectID) into tRuggedID
      if tRuggedID is not sObjectID then
         put tRuggedID into sObjectID
         if exists(sObjectId) and \
               revEnvironmentEditionProperty("autocomplete") then
            ideAutocompleteIntrospectMessagePath sObjectId
         end if
      end if
   else
      put empty into sObjectID
   end if
   delete variable sPlaceholders
   delete variable sEditChunks
   delete variable sEditPlaceholder
end setObjectID

function getObjectID
   return sObjectID
end getObjectID

command updateObjectID pOldObjectID, pNewObjectID
   # If there was a previous object and we are changing its id, then we have to update all the script locals
   # that may contain references to the old object. This is rather ugly, but it allows things like undo to work
   # even when objects are moved.
   
   # Script cache, stores unapplied scripts when tabs are changed
   updateArrayKey sScriptCache, pOldObjectID, pNewObjectID
   
   # Undo stuff
   updateMultiItemArrayKey sTextOperationOffsets, pOldObjectID, pNewObjectID, 44, 1
   updateMultiItemArrayKey sTextOperationOldTexts, pOldObjectID, pNewObjectID, 44, 1
   updateMultiItemArrayKey sTextOperationNewTexts, pOldObjectID, pNewObjectID, 44, 1
   updateArrayKey sTextOperationTop, pOldObjectID, pNewObjectID
   updateArrayKey sTextOperationIndex, pOldObjectID, pNewObjectID
   
   updateMultiItemArrayKey sTextGroupLabels, pOldObjectID, pNewObjectID, 44, 1
   updateMultiItemArrayKey sTextGroupLengths, pOldObjectID, pNewObjectID, 44, 1
   updateArrayKey sTextGroupIndex, pOldObjectID, pNewObjectID
   updateArrayKey sTextGroupTop, pOldObjectID, pNewObjectID
   updateArrayKey sTextMark, pOldObjectID, pNewObjectID
end updateObjectID

# Parameters
#   pObjectId : reference to the object to set the script to. Must be one of the target objects of the script editor.
# Description
#   Clears the script cache for the specified object. This should be called when the object is being closed. The cache also
#   includes selection information.
command clearCache pObject, pDontCheckId
   local tObject
   if pDontCheckId then
      put pObject into tObject
   else
      put revRuggedId(pObject) into tObject
   end if
   delete variable sScriptCache[tObject]

   if revEnvironmentEditionProperty("autocomplete") then
      ideAutocompleteClearObjectCache tObject
   end if
end clearCache

# Parameters
#   pArray : reference to an array. This gets modified
#   pOldKey : one of the array keys
#   pNewKey : the new key to replace pOldKey with
# Description
#   Removes the element pOldKey from the array, and creates
#   a new element pNewKey with the same data. Essentially renaming the key.
#   If the element is empty, does nothing.
private command updateArrayKey @pArray, pOldKey, pNewKey
   local tData
   if pArray[pOldKey] is not empty then
      put pArray[pOldKey] into tData
      delete variable pArray[pOldKey]
      put tData into pArray[pNewKey]
   end if
end updateArrayKey

# Parameters
#   pArray : reference to an array. This gets modified
#   pOldKey : one of the array keys
#   pNewKey : the new key to replace pOldKey with
#   pDelimiter : an ascii char code that delimits dimensions in the array's key. If empty, comma is assumed.
#   pItemNumer : which item number of the key needs to match pOldKey
# Description
#   Removes all keys with the specified dimension matching pOldKey from the array
#   and replaces them with equivalent keys matching pNewKey.
private command updateMultiItemArrayKey @pArray, pOldKey, pNewKey, pDelimiter, pItemNumber
   local tData
   
   if pDelimiter is not empty then
      set the itemDelimiter to numToChar(pDelimiter)
   end if
   
   # Create a list of keys that need to be modified
   local tKeys
   repeat for each line tKey in the keys of pArray
      if item pItemNumber of tKey is pOldKey then
         put tKey & return after tKeys
      end if
   end repeat
   delete the last char of tKeys
   
   if tKeys is empty then
      exit updateMultiItemArrayKey
   end if
   
   # Apply the modification to the keys
   repeat for each line tKey in tKeys
      local tNewKey
      put tKey into tNewKey
      put pNewKey into item pItemNumber of tNewKey
      put pArray[tKey] into pArray[tNewKey]
      delete variable pArray[tKey]
   end repeat
end updateMultiItemArrayKey

command textInitialize
   put empty into sTextOperationOffsets
   put empty into sTextOperationNewTexts
   put empty into sTextOperationOldTexts
   put 0 into sTextOperationIndex
   put 0 into sTextOperationTop
   
   put empty into sTextGroupLabels
   put empty into sTextGroupLengths
   put 0 into sTextGroupIndex
   put 0 into sTextGroupTop
   
   put empty into sTextMark
   
   textFormatInitialize
   
   textMark "Insert"
end textInitialize   

command getLastSelection
   return slastNonEmptySelection
end getLastSelection

command setLastSelectedChunk pSelection
   put pSelection into sLastSelectedChunk
end setLastSelectedChunk

command getLastSelectedChunk
   return sLastSelectedChunk
end getLastSelectedChunk

command getLastSelectedWord
   local tFrom, tTo
   put item 1 of sLastSelectedChunk into tFrom
   put item 2 of sLastSelectedChunk into tTo
   
   # If there is a non empty selection, just return that.
   if tTo > tFrom then
      return char tFrom to tTo of the text of getScriptField()
   end if
   
   # If the selection is in the middle of a word, then return that.
   # First loop back from the selected character to find the first part of the word. Keep going until we find a character
   # that is either whitespace, or a bracket.
   local tWordDivider
   put merge("^[\[[quote]]|\[|\]\(|\)|\s]$") into tWordDivider
   
   local tBefore
   repeat with x = tTo down to 1
      get char x of the text of getScriptField()
      if matchText(it, tWordDivider) then
         exit repeat
      end if
      put it before tBefore
   end repeat
   
   local tAfter
   repeat with x = tTo + 1 to the number of chars of the text of getScriptField()
      get char x of the text of getScriptField()
      if matchText(it, tWordDivider) then
         exit repeat
      end if
      put it after tAfter
   end repeat
   
   local tWord
   put tBefore & tAfter into tWord
   return tWord
end getLastSelectedWord

# Description
#   Returns whether or not undo is available in the current object. I.e. the script has been edited since it was opened in this
#   instance of the script editor.
command undoAvailable
   if sTextGroupIndex[sObjectId] is 0 then
      return false
   else
      return true
   end if
end undoAvailable

# Description
#   Returns whether or not redo is available in the current object. I.e. something has been undone since it was opened in
#   this instance of the script editor.
command redoAvailable
   if sTextGroupIndex[sObjectId] is sTextGroupTop[sObjectId] then
      return false
   else
      return true
   end if
end redoAvailable

on textMark pLabel
   put pLabel into sTextMark[sObjectId]
end textMark

on textBeginGroup pLabel, pObject
   local tObject
   if pObject is empty then
      put sObjectId into tObject
   else
      put pObject into tObject
   end if
   
   add 1 to sTextGroupIndex[tObject]
   
   put pLabel into sTextGroupLabels[tObject,sTextGroupIndex[tObject]]
   put 0 into sTextGroupLengths[tObject,sTextGroupIndex[tObject]]
   
   repeat with tIndex = sTextGroupIndex[tObject] + 1 to sTextGroupTop[tObject]
      delete variable sTextGroupLabels[tObject,tIndex]
      delete variable sTextGroupLengths[tObject,tIndex]
   end repeat
   
   repeat with tIndex = sTextOperationIndex[tObject] + 1 to sTextOperationTop[tObject]
      delete variable sTextOperationOffsets[tObject,tIndex]
      delete variable sTextOperationNewTexts[tObject,tIndex]
      delete variable sTextOperationOldTexts[tObject,tIndex]
   end repeat
   
   put sTextOperationIndex[sObjectId] into sTextOperationTop[tObject]
   put sTextGroupIndex[sObjectId] into sTextGroupTop[tObject]
   
   put empty into sTextMark[tObject]
end textBeginGroup

on textEndGroup
   if sTextGroupLengths[sObjectId,sTextGroupIndex[sObjectId]] = 0 then
      throw "empty_text_group_inserted"
   end if
   textMark "Insert"
end textEndGroup

private function __GetPreference pPreference, pDefault
   try
      dispatch function "sePrefGet" to stack "revNewScriptEditor" with pPreference
      if the result is not empty then
         return the result
      end if
   end try
   
   return pDefault
end __GetPreference

-- Text Formatting Code
command textFormatInitialize
   -- permit use in environment with no dependencies
   local tTabDepth
   put __GetPreference("editor,tabdepth", 3) into tTabDepth
   
   put "0," & tTabDepth into sTextFormatKeywordMap["try"]
   put "0," & tTabDepth into sTextFormatKeywordMap["switch"]
   put "0," & tTabDepth into sTextFormatKeywordMap["if"]
   put -tTabDepth & ",0" into sTextFormatKeywordMap["endif"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["elseif"]
   put "0," & tTabDepth into sTextFormatKeywordMap["repeat"]
   
   put "0," & tTabDepth into sTextFormatKeywordMap["on"]
   put "0," & tTabDepth into sTextFormatKeywordMap["function"]
   put "0," & tTabDepth into sTextFormatKeywordMap["setprop"]
   put "0," & tTabDepth into sTextFormatKeywordMap["getprop"]
   put "0," & tTabDepth into sTextFormatKeywordMap["command"]
   put "0," & tTabDepth into sTextFormatKeywordMap["private"]
   put "0," & tTabDepth into sTextFormatKeywordMap["before"]
   put "0," & tTabDepth into sTextFormatKeywordMap["after"]
   
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["else"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["case"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["default"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["catch"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["finally"]
   put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["catch"]
   --put -tTabDepth & comma & tTabDepth into sTextFormatKeywordMap["break"]
   put 0 & comma & 0 into sTextFormatKeywordMap["break"]
   
   put -tTabDepth & ",0" into sTextFormatKeywordMap["end"]
end textFormatInitialize

private function textFormatIndentLineAdds pLine
   local tToken
   put token 1 of pLine into tToken
   if tToken is "if" then
      if "else" is among the words of pLine then
         return 0
      else if token -1 of pLine is not "then" then
         return 0
      else
         return item 2 of sTextFormatKeywordMap["if"]
      end if
      
   else if tToken is "else" then
      if token 2 of pLine is "if" then
         if "else" is among the words of word 3 to -1 of pLine then
            return 0
         else if token -1 of pLine is not "then" then
            return 0
         else
            return item 2 of sTextFormatKeywordMap["elseif"]
         end if
      else if token 2 of pLine is not empty then
         return 0
      else
         return item 2 of sTextFormatKeywordMap["else"]
      end if
      
   else if token 1 of pLine is empty then
      return 0
      
   else if token 1 of pLine is "then" and "else" is among the tokens of pline then
      return 0
      
      ## Bug 10467 - else in a comment was causing incorrect indentation
      ## Check for "else" in line without comments
      --else if token 1 of pLine is not "else" and "else" is among the words of pLine then
   else if token 1 of pLine is not "else" and "else" is among the words of lineStripComments(pLine) then
      -- permit use in environment witn no dependencies
      local tTabDepth
      put __GetPreference("editor,tabdepth", 3) into tTabDepth
      return -tTabDepth
   else if token -1 of pLine is "then" then
      # Either a weirdly formatted if structure, or the condition of the if contained a line continuation character.
      # In this case, behave as though pLine is a normal if.
      return item 2 of sTextFormatKeywordMap["if"]
   else
      return item 2 of sTextFormatKeywordMap[tToken]
   end if
   return 0
end textFormatIndentLineAdds


private function textFormatIndentLineRemoves pPreviousLine, pLine
   local tToken
   put token 1 of pLine into tToken
   if tToken is "else" then
      if token 2 of pLine is "if" then
         if "then" is among the words of pPreviousLine and token -1 of pPreviousLine is not "then" then
            return 0
         else
            return item 1 of sTextFormatKeywordMap["elseif"]
         end if
         
      else
      
         if "then" is among the words of pPreviousLine and token -1 of pPreviousLine is not "then" \
               and "else" is among the tokens of pPreviousLine and token 1 of pPreviousLine is "if" and token -1 of pLine is "else" then
            return item 1 of sTextFormatKeywordMap["else"]
         end if
         
         if "then" is among the words of pPreviousLine and token -1 of pPreviousLine is not "then" \
               and token 1 of pPreviousLine is "if" and token -1 of pLine is "else" then
            return 0
         end if
         
         if "then" is among the words of pPreviousLine and token -1 of pPreviousLine is not "then" then
            return 0
         else
            return item 1 of sTextFormatKeywordMap["else"]
         end if
      end if
   else if tToken is empty then
      # Comments and empty lines do not remove any formatting
      return 0
   else if tToken is "end" and token 2 of pLine is "switch" and token 1 of pPreviousLine is not "switch" then
      # Special case for end switch if there is a preceeding "break", "default" or other statement, we need to remove
      # double the normal indent.
      return (2 * item 1 of sTextFormatKeywordMap["end"])
   else if tToken is "case" then
      # A case statement removes indent from the previous line in all cases except if the
      # previous line was the beginning of the parent switch structure.
      if token 1 of pPreviousLine is "switch"  then
         return 0
      else
         return item 1 of sTextFormatKeywordMap["case"]
      end if
      # OK-2009-04-28 : Bug 8016 - Special case required for "default" to make switches format correctly.
   else if tToken is "default" then
      if token 1 of pPreviousLine is "switch" then
         return 0
      else
         return item 1 of sTextFormatKeywordMap["default"]
      end if
   else if tToken is "end" and token 2 of pLine is not among the words of "if switch repeat try" and not lineIsContinued(pLine) then
      # Handler ends always remove all indentation as they can't be nested
      # OK-2009-02-16 : Bug 7707 - We can't assume the previous line was correctly formatted or script may be deleted.
      # Instead we simplify this by simply chopping off whatever indentation it did have.
      --return min(-(the number of chars of textFormatGetLineIndent(pPreviousLine)), item 1 of sTextFormatKeywordMap[tToken])
      return item 1 of sTextFormatKeywordMap["end"]
   else
      # We can't assume that the previous line was correctly indented
      # because the script might have been edited from outside this script editor. Therefore
      # we have to ensure that a line doesnt try to remove more formating than the previous
      # line actually had. Otherwise non-whitespace chars may be deleted.
      if the number of chars of textFormatGetLineIndent(pPreviousLine) + the number of chars of textFormatGetLineIndent(pLine) + textFormatIndentLineAdds(pPreviousLine) < abs(item 1 of sTextFormatKeywordMap[tToken]) then
         return -(the number of chars of textFormatGetLineIndent(pPreviousLine))
      else
         return item 1 of sTextFormatKeywordMap[tToken]
      end if
   end if
end textFormatIndentLineRemoves

private function textFormatGetLineIndent pLine
   local tResult
   repeat for each char tChar in pLine
      if tChar is space then
         put space after tResult
      else
         return tResult
      end if
   end repeat
   return tResult
end textFormatGetLineIndent

-- all chars after a continuation are treated as a comment
-- this will work fine until someone uses format with multiple
-- \"\" but there's not much getting around that
private function lineIsContinued pLine
   put lineStripComments(pLine) into pLine
   split pLine by quote
   repeat with tIndex = 1 to the number of elements of pLine step 2
      if pLine[tIndex] contains "\" then
         return true
      end if
   end repeat
   return false
end lineIsContinued

private function textFormatGetContinuationIndent pLastLineNumber
   # In order to calculate the indentation we need to loop back until we find the start of the continuation,
   # constructing a string which is the equivalent of the continued line in a single line. We then use this to calculate
   # the indent of the last line 
end textFormatGetContinuationIndent

private function combineContinuedLine pLastLineNumber, @pTextLines
   local tContinuation
   put lineStripComments(pTextLines[pLastLineNumber]) into tContinuation
   
   local tIndex
   repeat with tIndex = (pLastLineNumber - 1) down to 1
      if not lineIsContinued( pTextLines[tIndex]) then
         exit repeat
      end if
      
      put lineStripComments(pTextLines[tIndex]) before tContinuation
   end repeat
   replace "\" with empty in tContinuation
   return tContinuation
end combineContinuedLine

constant kContinuationIndent = 6

private function textFormatLine pLine, pTextLines, @xPreviousLine
   local tResult
   
   # OK-2009-01-30 : Bug 7051 - Deal better with continuation characters.
   local tCurrentLineIsContinued
   local tPreviousLineWasContinued
   local tPreviousPreviousLineWasContinued
   
   # Continuations can only happen with consecutive lines, there can't be comments or empty lines in between,
   # so we simply use the two previous lines to work out if they are continued or not. If these lines are empty
   # or are comments, then the result will be that they are not continuations anyway which is correct.
   put lineIsContinued(pTextLines[pLine - 1]) into tPreviousLineWasContinued
   put lineIsContinued(pTextLines[pLine - 2]) into tPreviousPreviousLineWasContinued
   
   put lineIsContinued(pTextLines[pLine]) into tCurrentLineIsContinued
   
   # Get the previous non-empty line
   if xPreviousLine is 0 and pLine > 1 then
      put pLine into xPreviousLine
      repeat while xPreviousLine > 1
         subtract 1 from xPreviousLine
         if token 1 of pTextLines[xPreviousLine] is not empty then
            exit repeat
         end if 
      end repeat
   end if
   
   local tPreviousLine
   local tPreviousLineWasCombined = false
   if xPreviousLine > 0 then
      # This is the case where we have reached the end of a continued line. Here, we treat the continued line
      # as a single entity in order to calculate its indentation properties correctly for the line after it.
      if lineIsContinued(pTextLines[xPreviousLine - 1]) then
         put true into tPreviousLineWasCombined
         put combineContinuedLine(xPreviousLine, pTextLines) into tPreviousLine
      else
         put pTextLines[xPreviousLine] into tPreviousLine
      end if
      
      # Get the current indent of the previous line
      local tPreviousLineIndent
      put textFormatGetLineIndent(tPreviousLine) into tPreviousLineIndent
   end if
   
   # Get the current indent of the line
   local tCurrentLineIndent
   put textFormatGetLineIndent(pTextLines[pLine]) into tCurrentLineIndent
   
   # Work out how much indentation the current line should remove from the previous line
   local tIndentCurrentLineRemoves
   if tPreviousLineWasContinued then
      put 0 into tIndentCurrentLineRemoves
   else
      put textFormatIndentLineRemoves(tPreviousLine, pTextLines[pLine]) into tIndentCurrentLineRemoves
   end if
   
   # Work out how much indentation the previous line should add to the current line.
   local tIndentPreviousLineAdds
   if xPreviousLine is 0 then
      put 0 into tIndentPreviousLineAdds
   else if tPreviousLineWasContinued then
      # we always add the continuation indent because we combined the continued lines
      put kContinuationIndent into tIndentPreviousLineAdds
   else
      put textFormatIndentLineAdds(tPreviousLine) into tIndentPreviousLineAdds
   end if
   
   local tCurrentIndent
   repeat (the number of chars of tPreviousLineIndent + tIndentCurrentLineRemoves + tIndentPreviousLineAdds)
      put space after tCurrentIndent
   end repeat
   
   put ((the number of chars of tPreviousLineIndent + tIndentCurrentLineRemoves + tIndentPreviousLineAdds) - the number of chars of tCurrentLineIndent) into tResult
   
   -- Finally, calculate the expected next indent.
   local tNewIndent
   put tCurrentIndent into tNewIndent
   
   local tIndentCurrentLineAdds
   if tCurrentLineIsContinued and tPreviousLineWasContinued then
      put 0 into tIndentCurrentLineAdds
   else if tCurrentLineIsContinued and (not tPreviousLineWasContinued) then
      put kContinuationIndent into tIndentCurrentLineAdds
   else if (not tCurrentLineIsContinued) and tPreviousLineWasContinued then
      put -kContinuationIndent into tIndentCurrentLineAdds
   else
      put textFormatIndentLineAdds(pTextLines[pLine]) into tIndentCurrentLineAdds
   end if
   
   if tPreviousLineWasContinued then
      local tCombinedLine
      put tPreviousLine && pTextLines[pLine] into tCombinedLine
      replace "\" with empty in tCombinedLine
      add textFormatIndentLineAdds(tCombinedLine) to tIndentCurrentLineAdds
   end if
   
   if tIndentCurrentLineAdds < 0 then
      repeat -tIndentCurrentLineAdds times
         delete char 1 of tNewIndent
      end repeat
   else
      repeat tIndentCurrentLineAdds times
         put space after tNewIndent
      end repeat
   end if
   
   put comma & tNewIndent after tResult
   
   if token 1 of pTextLines[pLine] is not empty then
      put pLine into xPreviousLine
   end if
   return tResult
end textFormatLine

# Returns
#   The chunk of pLine from the beginning of the first word to the end.
private function firstWordToEnd pLine
   local tOffset
   put offset(word 1 of pLine, pLine) into tOffset
   return char tOffset to -1 of pLine
end firstWordToEnd

# Formats the specified script snippet.
command scriptFormatSnippet pScript
   textFormatInitialize
   local tNewScript
   put textFormatSelection(pScript) into tNewScript
   return tNewScript
end scriptFormatSnippet

# Parameters
#   pText : the text to format
private function textFormatSelection pText
   local tResult
   local tPreviousLine = 0
   local tTextLines
   put pText into tTextLines
   split tTextLines by return
   
   get textFormatLine(1, tTextLines, tPreviousLine)
   put firstWordToEnd(tTextLines[1]) into tTextLines[1]
   put tTextLines[1] into tResult
   local tIndex
   repeat with tIndex = 2 to the number of elements of tTextLines
      put item 2 of it & firstWordToEnd(tTextLines[tIndex]) into tTextLines[tIndex]
      get textFormatLine(tIndex, tTextLines, tPreviousLine)
      
      if item 1 of it < 0 then
         repeat -(item 1 of it) times
            if char 1 of line -1 of tTextLines[tIndex] is space then
               delete char 1 of tTextLines[tIndex]
            end if
         end repeat
      else if item 1 of it > 0 then
         repeat item 1 of it times
            put space before tTextLines[tIndex]
         end repeat
      end if
      
      put return & tTextLines[tIndex] after tResult
   end repeat
   
   if line -1 of pText = "" then put cr after tResult
   
   return tResult
end textFormatSelection

private function handlerTypes
   return "command,on,function,setprop,getprop,before,after"
end handlerTypes

private function textFormat pLineNumber, pLineCount, pText
   -- Find the range to format.
   -- 1. Search down until we find a handler (a) or the end of one (b).
   -- 2. Based on 1, in case a, search up until we find the end of any other handler, or the beginning of the script.
   --    In case b we need to search for the start of that handler.
   local tEnd
   
   local tText
   put pText into tText
   split tText by return
   put pLineNumber into tEnd
   
   # Search down to find what the handler name is and whether pLineNumber is the first line of the handler.
   local tHandler
   local tFirstLine
   put true into tFirstLine
   
   local tContinuation, tCurrentLineContinues
   put lineIsContinued(tText[pLineNumber-1]) into tContinuation
   
   local tLineIndex
   repeat with tLineIndex = pLineNumber to the number of elements of tText
      put lineIsContinued(tText[tLineIndex]) into tCurrentLineContinues
      if token 1 of tText[tLineIndex] is "end" and token 2 of tText[tLineIndex] is not among the items of "if,repeat,switch,try" and not tContinuation and not tCurrentLineContinues then
         put true into tHandler[token 2 of tText[tLineIndex]]
         if pLineCount < 0 then
            exit repeat
         end if
      else if token 1 of tText[tLineIndex] is among the items of handlerTypes() and not tFirstLine then
         if pLineCount < 0 then
            exit repeat
         end if
         exit repeat
      else if token 1 of tText[tLineIndex] is "private" and token 2 of tText[tLineIndex] is among the items of handlerTypes() and not tFirstLine then
         if pLineCount < 0 then
            exit repeat
         end if
         exit repeat
      else
         put tCurrentLineContinues into tContinuation
      end if
      if tFirstLine then put false into tFirstLine
      subtract 1 from pLineCount
      add 1 to tEnd
   end repeat
   
   # Search up to find the beginning of the handler, or the beginning of the script if not found.
   local tStart
   repeat with tLineIndex = pLineNumber down to 1
      put tLineIndex into tStart
      if tHandler is an array then
         if token 1 of tText[tLineIndex] is among the items of  handlerTypes() and tHandler[token 2 of tText[tLineIndex]] then
            exit repeat
         else if token 1 of tText[tLineIndex] is "private" and token 2 of tText[tLineIndex] is among the items of handlerTypes() and tHandler[token 3 of tText[tLineIndex]] then
            exit repeat
         end if
      else if token 1 of tText[tLineIndex] is "end" and token 2 of tText[tLineIndex] is not among the items of "if,repeat,switch,catch" then
         exit repeat
      end if
   end repeat
   
   if tHandler is not an array and tStart is not 1 then
      add 1 to tStart
   end if
   if tEnd > the number of elements of tText then
      put the number of elements of tText into tEnd
   end if
   
   -- Now format lines tStart to tEnd of pText, and return the result.
   local tStartChar
   if tStart is 1 then
      put 1 into tStartChar
   else
      put the number of chars of line 1 to (tStart - 1) of pText into tStartChar
      add 2 to tStartChar
   end if
   
   local tOldText
   put line tStart to tEnd of pText into tOldText
   
   local tResult
   put tStartChar into tResult["startchar"]
   put tOldText into tResult["oldtext"]
   put textFormatSelection(tOldText) into tResult["newtext"]
   
   return tResult
end textFormat

function textGetScript
   return the text of field "Script" of me
end textGetScript

function getScriptField
   return the long id of field "Script" of me
end getScriptField

on textSetSelection pAfterChar
   select after char pAfterChar of field "Script" of me
end textSetSelection

# Parameters
#   pOldText : the text replaced in an operation
#   pNewText : the replacing text in an operation
# Returns
#   Whether or not a new undo group is needed for the specified
#   operation.
private function textReplaceNewGroupNeeded pOldText, pNewText
   # If the invoker of the replacement operation has specified that an undo group
   # is needed, always create one
   if sTextMark[sObjectId] is not empty then
      return true
   end if
   
   # If the number of chars of either the string replaced or replacing string is above one
   # this means it must be a deletion of a selection or a cut or paste. This should always
   # require a new group
   if the number of chars of pOldText > 1 or the number of chars of pNewText > 1 then
      return true
   end if
   
   # If either the text being replaced or the replacing text contain return chars, new group
   if pOldText contains return or pNewText contains return then
      return true
   end if
   
   return false
end textReplaceNewGroupNeeded

# Parameters
#   pOffset : the char number of where the replacement should start
#   pOldText : the text that is being replaced
#   pNewText : the text that is being inserted
#   pObject : the long id of the object to replace in. If not given, the current object is assumed.
# Description
#   This is the point through which all standard editing operations on scripts are sent through.
#   Any change made via this function will be added to the undo system. This is called when the
#   user types keys, formats text, cuts, pastes etc.
command textReplace pOffset, pOldText, pNewText, pObject, pDontGroup, pDontSelect
   lock screen
   
   local tObject
   if pObject is empty then
      put sObjectId into tObject
   else
      put pObject into tObject
   end if
   
   local tBracketCompletionType
   __BracketCompletion  pOffset, pOldText, pNewText
   put it into tBracketCompletionType
   
   local tSelection
   if tBracketCompletionType is "wrap" then
      put the selectedChunk into tSelection
      add 1 to word 2 of tSelection
      add 1 to word 4 of tSelection
   end if
   
   if pDontGroup is not true and textReplaceNewGroupNeeded(pOldText, pNewText) then
      textBeginGroup sTextMark[tObject], tObject
   end if
   
   add 1 to sTextOperationIndex[tObject]
   add 1 to sTextGroupLengths[tObject,sTextGroupIndex[tObject]]
   
   local tEditPlaceholder
   put sEditChunks is an array and sEditPlaceholder is not empty and \
         pOffset >= sEditChunks[1]["start"] and \
         pOffset + length(pOldText) - 1 <= sEditChunks[1]["end"] and \
         return is not in pNewText into tEditPlaceholder
   
   if tEditPlaceholder and \
         sPlaceholders[sEditPlaceholder]["classes"][1] is "identifier" then
      put comma is not in pNewText and \
            ";" is not in pNewText and \
            space is not in pNewText and \
            quote is not in pNewText into tEditPlaceholder
   end if
   
   if not tEditPlaceholder then
      put pOffset into sTextOperationOffsets[tObject,sTextOperationIndex[tObject]]
      put pOldText into sTextOperationOldTexts[tObject,sTextOperationIndex[tObject]]
      put pNewText into sTextOperationNewTexts[tObject,sTextOperationIndex[tObject]]
      if sEditPlaceholder is not empty then
         __ClearCurrentPlaceholder true
      end if
   end if
   
   # When the script has been edited, the breakpoints should be suspended until it is applied again.
   # Because this command is called as the user types, we could a send in time for this, as its not that urgent.
   try
      revDebuggerSuspendBreakpoints tObject
   end try
   
   # If the specified object to replace in is the current object being edited, we perform the replace
   # directly on the script editing field using textReplaceRaw. Otherwise we perform it on the
   # script cache stored for the object.
   if tObject is empty or revRuggedId(tObject) is sObjectId then
      local tSelectedLength, tNewLength
      put length(pOldText) into tSelectedLength
      put length(pNewText) into tNewLength
      
      if tEditPlaceholder then
         local tFirstCharOffset, tLastCharOffset
         
         put pOffset-sEditChunks[1]["start"] into tFirstCharOffset
         put sEditChunks[1]["end"]-pOffset + tSelectedLength into tLastCharOffset
         
         local tToAdd = 0
         local tIndex
         repeat with tIndex = 1 to the number of elements of sEditChunks
            add tToAdd to sEditChunks[tIndex]["start"]
            add tToAdd to sEditChunks[tIndex]["end"]
            
            textReplaceRaw sEditChunks[tIndex]["start"]+tFirstCharOffset, pOldText, pNewText
            
            add tNewLength - tSelectedLength to tToAdd
            add tNewLength - tSelectedLength to sEditChunks[tIndex]["end"]
            set the metadata of char sEditChunks[tIndex]["start"] to sEditChunks[tIndex]["end"] of field "script" of me to sEditPlaceholder
            if tIndex is 1 then
               set the backgroundColor of char sEditChunks[tIndex]["start"] to sEditChunks[tIndex]["end"] of field "script" of me to empty
            else
               set the backgroundColor of char sEditChunks[tIndex]["start"] to sEditChunks[tIndex]["end"] of field "script" of me to \
                     the effective hiliteColor of field "script" of me
            end if
            put sEditChunks[tIndex]["start"]+tFirstCharOffset into sTextOperationOffsets[tObject,sTextOperationIndex[tObject]]
            put pOldText into sTextOperationOldTexts[tObject,sTextOperationIndex[tObject]]
            put pNewText into sTextOperationNewTexts[tObject,sTextOperationIndex[tObject]]
            
            add 1 to sTextOperationIndex[tObject]
            add 1 to sTextGroupLengths[tObject,sTextGroupIndex[tObject]]
         end repeat
         put true into sPlaceholders[sEditPlaceholder]["edited"]
         
         if not pDontSelect then
            if tSelection is not empty then
               select tSelection
            else if pNewText is empty then
               select char pOffset to pOffset-1 of field "script" of me
            else if the length of pNewText is 1 then
               select char pOffset+1 to pOffset of field "script" of me
            else if tBracketCompletionType is "pair" then
               select after char pOffset of field "script" of me
            end if
         end if
      else
         -- clear highlighted bracket background color
         __ClearHighlights
         textReplaceRaw pOffset, pOldText, pNewText
         if not pDontSelect then
            if tSelection is not empty then
               select tSelection
            else if tBracketCompletionType is "pair" then
               select after char pOffset of field "script" of me
            end if
         end if
      end if
      
      if not pDontSelect then
         selectionUpdateRequest
      end if
      
      -- when formatting or pasting we don't want autocomplete to pop up
      if the number of lines of pNewText <= 1 then
         __UpdateAutoCompleteList sEditPlaceholder
      end if
   else
      local tCache
      put sScriptCache[revRuggedId(tObject)] into tCache
      if tCache is empty then
         put the script of tObject into tCache
      end if
      textReplaceRawInVariable tCache, pOffset, pOldText, pNewText
      put tCache into sScriptCache[revRuggedId(tObject)]
   end if
   
   set the caseSensitive to true
   if pOldText is not pNewText then
      # OK-2009-01-17 : Bug 7169 - Flag the object as dirty when it is modifed by this method only.
      # The textReplaceRaw etc functions should not do this as they do not represent a user modifying
      # the script.
      setDirty tObject, true
   end if
   unlock screen
end textReplace

# Parameters
#   pOffset : the char number to begin the replacement at
#   @rScript : the text to perform the replacement in, gets mutated
#   @pOldText : the text that is to be replaced. This is not mutated, its a reference for efficiency reasons
#   @pNewText : the text to be inserted. This is not mutated, its a reference for efficiency reasons
# Description
#   Performs a raw replace exactly as textReplaceRaw, except in a variable instead of directly in the editing field.
#   This is used by replace-all, because it may need to replace text in the script of objects which are not open.
command textReplaceRawInVariable @rScript, pOffset, @pOldText, @pNewText
   local tOldLength
   put the length of pOldText into tOldLength
   put pNewText into char pOffset to pOffset + tOldLength - 1 of rScript
end textReplaceRawInVariable

# Parameters
#   pOffset : the char number to begin the replacement at
#   @pOldText : the text that is to be replaced. This is not mutated, its a reference for efficiency reasons
#   @pNewText : the text to be inserted. This is not mutated, its a reference for efficiency reasons
#   pDontUpdateBreakpoints : optional, defaults to false. If this is true, breakpoints in the gutter are not moved.
# Description
#   This is the raw replacement operation that performs a mutation on the script field without
#   saving any undo information. This should be called only from inside textReplace, when doing an undo or a redo
#   and when setting the script when a new object is loaded.
private command textReplaceRaw pOffset, @pOldText, @pNewText, pDontUpdateBreakpoints, pUpdateBreakpointsNow
   lock screen
   lock messages
   
   local tSelectedLine
   put word 2 of the selectedLine into tSelectedLine
   
   local tEndOffset
   put max(0, pOffset + the length of pOldText - 1) into tEndOffset

   _internal script replace char pOffset to tEndOffset of field "Script" of me with pNewText
   
   --Do some work to update the gutter.
   local tOldLines, tNewLines
   put the number of lines of pOldText into tOldLines
   if pOldText is not return and (char -1 of pOldText is return or pOldText is empty) then
      add 1 to tOldLines
   end if
   if pNewText is empty and pOldText is return then
      put 0 into tNewLines
   else
      put the number of lines of pNewText into tNewLines
      if char -1 of pNewText is return or pNewText is return or pNewText is empty then
         add 1 to tNewLines
      end if
   end if
   unlock messages
   
   if pDontUpdateBreakpoints then
      updateGutterRequest empty, empty, tOldLines, tNewLines, false, false, false, pUpdateBreakpointsNow
   else
      updateGutterRequest pOffset, tSelectedLine, tOldLines, tNewLines, true, false, false, pUpdateBreakpointsNow
   end if
   
   # OK-2008-09-10 : Bug 7132 - Update the panes  and handler list everytime the text of the field is changed.
   # OK-2009-01-19 : Don't do this here as it slows down the script editor on OS X. Instead do it in the individual
   # cases where it may be needed, cut, paste, return, delete, backspace, undo and redo
   --selectionUpdateRequest
   
   unlock screen
end textReplaceRaw

-- Sets the contents of the fields to pScript WITHOUT touching the undo queue. This should be done before any editing.
on textSetScriptRaw pScript
   --put empty into field "Script" of me
   local tOldText
   put the text of field "Script" of me into tOldText
   if tOldText is not pScript then
      textReplaceRaw 1, tOldText, pScript, true
   end if
end textSetScriptRaw

-- Sets the script within the undo queue.
on textSetScript pScript
   textReplace 1, the text of field "Script" of me, pScript
end textSetScript

# Description
#   Performs an undo operation on the current script
on textUndo
   undoAvailable
   if not the result then
      exit textUndo
   end if
   
   local tOperations
   put sTextGroupLengths[sObjectId,sTextGroupIndex[sObjectId]] into tOperations
   
   lock screen
   repeat with tIndex = sTextOperationIndex[sObjectId] down to sTextOperationIndex[sObjectId] - tOperations + 1
      local tNewText, tOldText
      put sTextOperationNewTexts[sObjectId,tIndex] into tNewText
      put sTextOperationOldTexts[sObjectId,tIndex] into tOldText
      textReplaceRaw sTextOperationOffsets[sObjectId,tIndex], tNewText, tOldText, false, true
   end repeat
   unlock screen
   
   subtract tOperations from sTextOperationIndex[sObjectId]
   subtract 1 from sTextGroupIndex[sObjectId]
   
   if there is a sObjectId then
      revDebuggerSuspendBreakpoints sObjectId
      seSetObjectState sObjectId, "edited"
   end if
   
   textMark "Insert"
end textUndo

# Description
#   Performs a redo operation on the current script
on textRedo
   redoAvailable
   if not the result then
      exit textRedo
   end if
   
   add 1 to sTextGroupIndex[sObjectId]
   
   local tOperations
   put sTextGroupLengths[sObjectId,sTextGroupIndex[sObjectId]] into tOperations
   lock screen
   repeat with tIndex = sTextOperationIndex[sObjectId] + 1 to sTextOperationIndex[sObjectId] + tOperations
      local tNewText, tOldText
      put sTextOperationOldTexts[sObjectId,tIndex] into tOldText
      put sTextOperationNewTexts[sObjectId,tIndex] into tNewText
      textReplaceRaw sTextOperationOffsets[sObjectId,tIndex], tOldText, tNewText, false, true
   end repeat
   unlock screen
   
   add tOperations to sTextOperationIndex[sObjectId]
   if there is a sObjectId then
      revDebuggerSuspendBreakpoints sObjectId
      seSetObjectState sObjectId, "edited"
   end if
   textMark "Insert"
end textRedo

# Description
#   This is a debugging command used to print the status of the undo queue when investigating
#   problems. It should not be called anywhere in the code.
on textPrint
   lock screen
   
   local tOperation
   put 1 into tOperation
   repeat with x = 1 to sTextGroupTop[sObjectId]
      
      put "Group(" & x & "):" && sTextGroupLabels[sObjectId,x] & return after message
      repeat sTextGroupLengths[sObjectId,x] times
         
         local tOldText, tNewText
         put sTextOperationOldTexts[sObjectId,tOperation] into tOldText
         put sTextOperationNewTexts[sObjectId,tOperation] into tNewText
         replace return with "\n" in tOldText
         replace return with "\n" in tNewText
         
         put tab & "[" & tOperation & "]:" && sTextOperationOffsets[tOperation], tOldText, tNewText & return after message
         
         if tOperation is sTextOperationIndex[sObjectId] then
            put tab & "--------" & return after message
         end if
         
         add 1 to tOperation
      end repeat
      
      if x is sTextGroupIndex[sObjectId] then
         put "--------" & return after message
      end if
   end repeat
   
   unlock screen
end textPrint

command cancelPendingMessages
   if sGutterUpdateRequest is not empty then
      cancel sGutterUpdateRequest
   end if
   
   if sSelectionUpdateRequest is not empty then
      cancel sSelectionUpdateRequest
   end if
   
   if sPaneUpdateRequest is not empty then
      cancel sPaneUpdateRequest
   end if
end cancelPendingMessages


private command updateGutterMergeRequestDetails pOffset, pSelectedLine, pOldLines, pNewLines, pTextChanged, pUpdateCompilationErrors, pForceBreakpointRedraw
   # The offset and selected line are just overwritten providing they are not empty
   if pOffset is not empty then
      put pOffset into sGutterUpdateRequestDetails["offset"]
   end if
   
   if pSelectedLine is not empty then
      put pSelectedLine into sGutterUpdateRequestDetails["selectedLine"]
   end if
   
   # The old number of lines is not changed, however if its empty, we put the new value in
   if sGutterUpdateRequestDetails["oldLines"] is empty then
      put pOldLines into sGutterUpdateRequestDetails["oldLines"]
   end if
   
   # The new number of lines overwrites the previous setting, again providing that its not empty
   if pNewLines is not empty then
      put pNewLines into sGutterUpdateRequestDetails["newLines"]
   end if
   
   # The new text changed value is the logical OR of the new and old values
   # The same is done for the update compilation errors and the force breakpoint redraw 
   put (pTextChanged or sGutterUpdateRequestDetails["textChanged"]) into sGutterUpdateRequestDetails["textChanged"]
   put (pUpdateCompilationErrors or sGutterUpdateRequestDetails["updateCompilationErrors"]) into sGutterUpdateRequestDetails["updateCompilationErrors"]
   put (pForceBreakpointRedraw or sGutterUpdateRequestDetails["forceBreakpointRedraw"]) into sGutterUpdateRequestDetails["forceBreakpointRedraw"]
end updateGutterMergeRequestDetails

command deleteUpdateGutterRequestDetails
   delete variable sGutterUpdateRequestDetails
end deleteUpdateGutterRequestDetails

function getUpdateGutterRequestDetails 
   return sGutterUpdateRequestDetails
end getUpdateGutterRequestDetails

# Parameters
#   pOffset : the offset of the last text change
#   pSelectedLine : the selected line at the point of the last text change
#   pOldLines : the old number of lines in the script field at the point of the last text change
#   pNewLines : the new number of liens in the script field after the last text change
#   pTextChanged : whether text was changed or not since the last gutter update. If this is false, all the previous parameters are ignored.
#   pUpdateCompilationErrors : whether to update the gutter's compilation errors
# Description
#   Sends a request to update the gutter. This is called whenever the current script is edited, or the field
#   is scrolled etc. 
#  The gutter's scroll is updated immediately. Also a message is sent to the gutter to hide its
#  mutable objects (the breakpoint / compilation error images). These are show again when the update is
#  actually carried out.
command updateGutterRequest pOffset, pSelectedLine, pOldLines, pNewLines, pTextChanged, pUpdateCompilationErrors, pForceBreakpointRedraw, pNow
   if sGutterUpdateRequestDetails["offset"] is not empty and \
         pOffset is not sGutterUpdateRequestDetails["offset"] then
      -- if the offset is different we can't merge
      updateGutterDo
   end if
   
   updateGutterMergeRequestDetails pOffset, pSelectedLine, pOldLines, pNewLines, pTextChanged, pUpdateCompilationErrors, pForceBreakpointRedraw
   if sGutterUpdateRequest is not empty then
      cancel sGutterUpdateRequest
   end if
   
   # BUGFIX-20140
   # 2017-JUL-28 bhall2001
   # We always update the gutter's scroll immediately, as otherwise it looks bad.   
   # For best scroll performance, we set the Gutter scroll directly.
   if exists(field "Numbers" of group "Gutter") then
      set the vScroll of field "Numbers" of group "Gutter" to the vScroll of field "Script" of me
   end if
   
   if pNow or (pOldLines is not 1 or pNewLines is not 1) then
      updateGutterDo
   else
      send "updateGutterDo" to me in 200 milliseconds
      put the result into sGutterUpdateRequest
   end if
end updateGutterRequest

# update gutter stubs
on updateGutterDo
end updateGutterDo

# Description
#   Sends a request to the script editor to update the panes. Requests are sent
#   only after a period of inactivity to prevent bombardment.
command paneUpdateRequest
   if sPaneUpdateRequest is not empty then
      cancel sPaneUpdateRequest
   end if
   
   -- allow environment with no dependencies
   local tDelay
   put __GetPreference("editor,paneupdatedelay", 500) into tDelay
   send "paneUpdate" to me in tDelay milliseconds
   put the result into sPaneUpdateRequest
end paneUpdateRequest

# pane update stubs
command paneUpdate
end paneUpdate

-- This is sent by the engine
on selectionChanged
   if not handleEvent("selectionChanged", the long id of the target) then
      pass selectionChanged
   end if
   if not (sArrowKeyPressed) then
      handleSelectionChanged
   end if
   -- Unmark found results when clicking on the SE
   selectionUpdateRequest
end selectionChanged

on selectionChangedByArrowKey pArrowKey
   saveLastSelections
   put false into sArrowKeyPressed
   
   -- [[ Bug 18595 ]] We need this here otherwise the "it" var in the if block below is empty
   get the selectedChunk
   
   local tAt
   if word 2 of it > word 4 of it then
      put word 4 of it into tAt
   else
      -- It is a multiple selection, so we need to exit this.
      exit selectionChangedByArrowKey
   end if
   
   -- Single selection in the process of making a larger selection, so exit if shift is down.
   if the shiftKey is "down" then
      exit selectionChangedByArrowKey
   end if
   
   local tLine
   put word 2 of the selectedLine into tLine
   
   local tField
   put the long id of the selectedField into tField
   
   local tScript
   put the text of tField into tScript
   
   local tLineStart
   switch pArrowKey
      case "left"
         put the number of chars of line 1 to (tLine - 1) of tScript + 1 into tLineStart
         # OK-2008-03-03 : Only add offset of return if we are not on the first line of the script
         if tLine is not 1 then
            add 1 to tLineStart
         end if
         put caretPositionLeft(tLineStart, tAt + 1, tScript) into tAt
         
         lock messages
         select after char tAt of tField
         unlock messages
         break
      case "right"
         caretUpdate tField, tScript
         break
         if char (tAt + 1) of tScript is return then
            add 1 to tLine
         end if
         put the number of chars of line 1 to (tLine - 1) of tScript + 2 into tLineStart
         get line tLine of tScript
         put caretPositionRight(tLineStart, tAt + 1, it) into tAt
         break
      case "up"
      case "down"
         caretUpdate tField, tScript
         break
      case "empty"
      default
         caretUpdate tField, tScript
         break
   end switch
   
   textMark "Insert"
   selectionUpdateRequest
end selectionChangedByArrowKey

-- PM-2016-09-22: [[ Bug 15887 ]] Distinguish between "selectionChanged" sent by the engine and \
      -- "selectionChangedByArrowKey pArrowKey"
on handleSelectionChanged
   caretUpdate
end handleSelectionChanged

private command saveLastSelections
   if the selectedText of field "Script" of me is not empty then
      put the selectedText of field "Script" of me into sLastNonEmptySelection
   end if
   
   -- [[ Bug 18528 ]] We need this here otherwise the "it" var in the if block below is empty
   get the selectedChunk
   
   # OK-2008-10-22 : Bug 7343 - Must save the last selection point as its lost
   # when the user begins typing into the search field.
   if the long id of the focusedObject is the long id of field "Script" of me then
      put word 2 of it & comma & word 4 of it into sLastSelectedChunk
   end if
end saveLastSelections

private command selectionUpdateRequest
   if sSelectionUpdateRequest is not empty then
      cancel sSelectionUpdateRequest
   end if
   
   -- handled by child behavior
   send "selectionUpdate" to me in 200 milliseconds
   put the result into sSelectionUpdateRequest
end selectionUpdateRequest

#selection update stubs
on selectionUpdate
   lock screen
   __CheckHighlights
   __ClearCurrentPlaceholder
   saveLastSelections
   unlock screen
end selectionUpdate

on mouseMove
   if revEnvironmentEditionProperty("autocomplete") then
      ideAutocompleteCancelFind the long id of me
   end if
   pass mouseMove
end mouseMove

on closeField
   if revEnvironmentEditionProperty("autocomplete") then
      ideAutocompleteCancelFind the long id of me
   end if
   pass closeField
end closeField

on exitField
   if revEnvironmentEditionProperty("autocomplete") then
      ideAutocompleteCancelFind the long id of me
   end if
   pass exitField
end exitField

on escapeKey
   if revEnvironmentEditionProperty("autocomplete") then
      ideAutocompleteCancelFind the long id of me
   end if
   pass escapeKey
end escapeKey

on help
   if revEnvironmentEditionProperty("autocomplete") then
      ideAutocompleteHandleHelp the long id of me, sObjectId
      if the result then
         pass help
      end if
   else
      pass help
   end if
end help

-- This calculates the position of the caret based on pPosition where the caret is (hypothetically).
private function caretPositionRight pLineStartChar, pProposedPosition, pLine
   local tFirstPosition
   put pLineStartChar - 1 into tFirstPosition
   repeat for each char tChar in pLine
      if tChar is space then
         add 1 to tFirstPosition
      else
         exit repeat
      end if
   end repeat
   
   return max(tFirstPosition, pProposedPosition)
end caretPositionRight

-- On moving the caret/backspace left, this returns the correct char position.
private function caretPositionLeft pLineStartChar, pCurrentPosition, pScript
   repeat with x = pCurrentPosition down to pLineStartChar
      if char x of pScript is not space then
         return (pCurrentPosition-1)
         break
      end if
   end repeat
   return pLineStartChar - 2
end caretPositionLeft

private command caretUpdate pField, pScript
   lock screen
   local tChunk
   put the selectedChunk into tChunk
   
   local tLine
   put word 2 of the selectedLine into tLine
   
   local tSearchLines
   put __GetPreference("editor,placeholdersearchlines", kPlaceholderDefaultSearchLines) into tSearchLines
   
   if tChunk is not empty and exists(tChunk) then
      get the metadata of tChunk
      if it is not empty then
         __ClearCurrentPlaceholder true
         __SelectPlaceholder \
               it, \
               tLine, \
               tLine + tSearchLines
         unlock screen
         exit caretUpdate
      end if
   end if
   
   -- a text selection
   if word 2 of tChunk <= word 4 of tChunk then
      exit caretUpdate
   end if
   
   local tField
   if pField is empty then
      put the long id of the selectedField into tField
   else
      put pField into tField
   end if
   
   local tScript
   if pScript is empty then
      put the text of the selectedField into tScript
   else
      put pScript into tScript
   end if
   
   # The current line is the first then its first char is char 1, otherwise it is the number of
   # chars of all previous lines + 1 char for the return char and 1 for the first char of the line.
   local tLineStart
   if tLine is 1 then
      put 1 into tLineStart
   else
      put the number of chars of line 1 to (tLine - 1) of tScript + 2 into tLineStart
   end if
   
   lock messages -- dont cause selectionChanged loop
   
   select after char caretPositionRight(tLineStart, word 4 of the selectedChunk, line tLine of tScript) of tField
   
   unlock messages
   unlock screen
end caretUpdate


# Offset between a field's top margin and the start of the text
constant kFudge = "-4"

# Parameters
#   pLineNumber : a line number in the script of the current object
# Returns
#   The vertical location of that line in the gutter or 0 if the line is not visible
function lineNumberToVerticalLoc pLineNumber
   local tField
   put getScriptField() into tField
   
   local tHeight
   put (pLineNumber - 1) * the effective textHeight of getScriptField() into tHeight
   
   # If the breakpoint is on a line earlier than the first one in the visible area then don't render it
   if tHeight < the vScroll of getScriptField() then
      return 0
   end if
   
   # If the breakpoint is on a line after the last one in the visible area the don't render it
   if tHeight > (the vScroll of getScriptField() + the height of getScriptField()) then
      return 0
   end if
   
   # Adjust the height to take the vScroll into account
   local tLoc
   put tHeight - the vScroll of getScriptField() into tLoc
   
   # Adjust the height so its relative to the start of the gutter
   add the top of me to tLoc
   
   # Adjust the the height to take the field's margins into account. This requires a little fudge...
   if the number of items of the margins of getScriptField() = 4 then
      add item 2 of the margins of getScriptField() + kFudge to tLoc
   else
      add the margins of getScriptField() + kFudge to tLoc
   end if
   
   # Adjust to the middle of the line
   add round(0.5 * the effective textHeight of getScriptField()) to tLoc
   
   return tLoc
end lineNumberToVerticalLoc

# Parameters
#   pVerticalLoc : a vertical location within the gutter's area
# Returns
#   The line number in the current script that is associated with the specified location.
#   If the location is beyond any lines in the script, or the line cannot have a breakpoint
#   on it, then 0 is returned.
function verticalLocToLineNumber pVerticalLoc
   # Add the vScroll of the script field so that the location is relative to the start of the text
   local tHeight
   put the vScroll of getScriptField() + pVerticalLoc into tHeight
   
   # Make it relative to 0 rather than the top of the gutter
   subtract the top of me from tHeight
   
   # Adjust the the height to take the field's margins into account. This requires a little fudge...
   if the number of items of the margins of getScriptField() = 4 then
      subtract item 2 of the margins of getScriptField() + kFudge from tHeight
   else
      subtract the margins of getScriptField() + kFudge from tHeight
   end if
   
   # Divide to calculate which line number it falls nearest. Always round up.
   local tLineNumber
   put (tHeight div the effective textHeight of getScriptField()) + 1 into tLineNumber
   return tLineNumber
end verticalLocToLineNumber

# Returns
#   Whether or not the script is locked
function scriptLocked
   return the lockText of field "Script" of me
end scriptLocked

on returnInField
   if the commandKey is "down" then
      # Pass to prevent conflict with command + return keyboard shortcut
      pass returnInField
   end if
   
   if not handleEvent("returnInField", the long id of the target) then
      pass returnInField
   end if
   
   if scriptLocked() then
      exit returnInField
   end if
   
   if revEnvironmentEditionProperty("autocomplete") then
      ideAutocompleteCancelFind the long id of me
   end if
   
   local tFrom, tTo
   get the selectedChunk
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   local tLine
   put word 2 of the selectedLine into tLine
   
   # Option+Return places a continuation char on the current line before the return.
   local tContinuationRequired
   put (optionKey() is "down") into tContinuationRequired
   
   local tAt, tLength, tReturn
   calculateReturnFormatting tTo, tFrom, tLine, tContinuationRequired, tAt, tLength, tReturn
   
   local tCaretOffset
   put tAt + the length of tReturn - 1 into tCaretOffset
   
   local tLineEnd
   put the number of chars of line 1 to tLine of textGetScript() + 1 into tLineEnd
   
   local tFollowingChars
   put char tAt to tLineEnd of textGetScript() into tFollowingChars
   
   local tWhitespaceAfter
   put matchText(tFollowingChars, "^\s*$") into tWhitespaceAfter
   
   -- allow environment with no dependencies
   local tAutoComplete
   put __GetPreference("editor,autocomplete", true) into tAutoComplete
   
   if tAutoComplete and tWhitespaceAfter then
      autoComplete tLine, tReturn
   end if
   
   # The return character should be grouped separately from the line that was entered before it (if there was one)
   # This copies the behavior of MS Visual Studio.
   if sTextGroupIndex[sObjectId] is not 0 then
      # OK-2008-07-29 : Bug 6825
      --textEndGroup
      textMark "Insert"
   end if
   
   textReplace tAt, char tAt to tAt + tLength - 1 of field "Script" of me, tReturn
   select after char tCaretOffset of field "Script" of me
   textEndGroup
   
   # OK-2009-01-19 : Update the handler list
   selectionUpdateRequest
end returnInField

# Parameters
# Description
#   Returns the specification of replace operation that represents the inserting of a
#   return character at the specified location in the current script. Includes formatting.
#   This command will also remove indentation from the previous line.
private command calculateReturnFormatting pTo, pFrom, pLine, pContinuationRequired, @rAt, @rLength, @rString
   local tReturnString
   if pContinuationRequired then
      put " \" & return into tReturnString
   else
      put return into tReturnString
   end if
   
   # If there is a non-empty selection, the inserted return char will replace this
   # and for now, no formatting is done.
   if pFrom <= pTo then
      put pFrom into rAt
      put pTo - pFrom + (the length of tReturnString) into rLength
      put tReturnString into rString
      exit calculateReturnFormatting
   end if
   
   # If the preference is not to use formatting, just return the specification of the basic 
   # insertion of a return character.
   -- allow environment with no dependencies
   local tAutoFormat
   put __GetPreference("editor,autoformat", true) into tAutoFormat
   
   if not tAutoFormat then
      put pFrom into rAt
      put 0 into rLength
      put tReturnString into rString
      exit calculateReturnFormatting
   end if
   
   local tScript
   put textGetScript() into tScript
   
   local tPreviousChars
   repeat with x = pFrom - 1 down to 1
      if char x of tScript is empty or char x of tScript is return then
         exit repeat
      end if
      put char x of tScript after tPreviousChars
   end repeat
   
   local tWhitespaceBefore
   put matchText(tPreviousChars, "^\s*$") into tWhitespaceBefore
   
   if tWhitespaceBefore then
      local tIndent
      put textFormatGetLineIndent(line pLine of tScript) into tIndent
      
      # If the caret has somehow been placed in the middle of the indentation string we need to allow
      # for this by subtracting from tIndent
      local tCurrentChar
      put pFrom into tCurrentChar
      repeat until (char tCurrentChar of tScript is not space) or the number of chars of tIndent = 0
         delete char 1 of tIndent
         add 1 to tCurrentChar
      end repeat
      
      local tLength
      put 0 into tLength
      
      local tAt
      put pFrom into tAt
      
      local tReturn
      put return & tIndent into tReturn
   else
      local tFormatting
      local tPreviousLine = 0
      local tTextLines
      put tScript into tTextLines
      split tTextLines by return
      
      put textFormatLine(pLine, tTextLines, tPreviousLine) into tFormatting
      
      put (the number of chars of line 1 to (pLine - 1) of tScript) + 1 into tAt 
      if pLine <> 1 then 
         add 1 to tAt 
      end if
      
      if item 1 of tFormatting > 0 then
         repeat item 1 of tFormatting times
            put space after tIndent
         end repeat
         textReplace tAt, empty, tIndent
      else if item 1 of tFormatting < 0 then
         textReplace tAt, char tAt to (tAt - item 1 of tFormatting - 1) of tScript, empty
      end if
      
      put 0 into tLength
      put pFrom into tAt
      add item 1 of tFormatting to tAt
      put tReturnString & item 2 of tFormatting into tReturn
   end if
   
   put tAt into rAt
   put tLength into rLength
   put tReturn into rString
end calculateReturnFormatting

# Parameters
#   pLine : the line number we are inserting at (i.e word 2 of the selectedLine at the point which the return was pressed which triggered the autocomplete)
#   xString : the string to put the completion after. This is the string that is about to be appended to the script as a result of pressing return
# Description
#   Calculates the correct completion according to what is already on line pLine, including formatting, and places it after xString,
#   which can then be inserted into the script field.
private command autoComplete pLine, @xString
   local tScript
   put textGetScript() into tScript
   
   local tCurrentLine
   put line pLine of tScript into tCurrentLine
   
   # From the text in the current line, calculate what kind of structure the user is typing the start of (if any)
   local tStructureType, tStructureName
   get autoCompleteGetStructure(tCurrentLine)
   put line 1 of it into tStructureType
   put line 2 of it into tStructureName
   
   # Once we know what the structure is, lookup what the correct completion is for that structure.
   local tCompletion
   put autoCompleteGetCompletion(tStructureType, tStructureName) into tCompletion
   if tCompletion is empty then
      exit autoComplete
   end if
   
   if tCompletion is empty then
      exit autoComplete
   end if
   
   # Look down the script and work out if we actually need to complete this structure, i.e. find out if its
   # already been completed or not.
   if not autoCompleteCompletionRequired(pLine, tStructureType, tStructureName, tCompletion) then
      exit autoComplete
   end if
   
   # Format the completion, this is easy because the indentation of the complete will always match
   # that of pLine.
   local tIndent
   put textFormatGetLineIndent(tCurrentLine) before tCompletion
   put return & tCompletion after xString
end autoComplete

private function autoCompleteSearchContext @pScript, pLineNumber, pStructureType, pStructureName, pCompletion
   if pStructureName is not empty then
      return 1
   end if
   
   -- case can't be nested except within another switch so return 0
   if pStructureType is "case" then
      return 1
   end if
   
   local tDepth
   put 0 into tDepth
   repeat with x = pLineNumber down to 1
      local tLine
      put line x of pScript into tLine
      
      if token 1 of tLine is "private" and token 2 of tLine is among the items of autoCompleteNamedStructures() then
         exit repeat
      else if token 1 of tLine is among the items of autoCompleteNamedStructures() then
         exit repeat
      end if
      
      if token 1 of tLine is pStructureType then
         add 1 to tDepth
      else if token 1 of tLine is "end" and token 2 of tLine is pStructureType then
         subtract 1 from tDepth
      end if
   end repeat
   
   return tDepth
end autoCompleteSearchContext

# Parameters
#   pLineNumber : the line that the structure to be completed starts on
#   pStructureType : the type of the structure to be completed this is either one of autoCompleteNamedStructures() or autoCompleteUnnamedStructures()
#   pStructureName : the name of the structure. (May be empty, not all structures have names, basically only handlers do)
#   pCompletion : what the completion of the structure would be (this is needed in order to see if its already there).
# Returns
#   True if a completion is required for this specification, false otherwise.
function autoCompleteCompletionRequired pLineNumber, pStructureType, pStructureName, pCompletion
   local tScript
   put textGetScript() into tScript
   
   put autoCompleteInSlashCommentOrOutOfHandler(tScript, pLineNumber) into tOutOfBounds
   if tOutOfBounds then
      return false
   end if

   if pStructureType is "if" then
      local tRequired
      put autoCompleteIFsAreBalanced(pLineNumber, tScript) into tRequired
      return tRequired
   end if
   
   local tInitialDepth
   put autoCompleteSearchContext(tScript, pLineNumber, pStructureType, pStructureName, pCompletion) into tInitialDepth
   put line pLineNumber + 1 to -1 of tScript into tScript
   
   # The nesting depth starts at 1 as we have just entered a structure
   local tNestingDepth
   put tInitialDepth into tNestingDepth
   repeat for each line tLine in tScript
      if token 1 of tLine is token 1 of pCompletion and token 2 of tLine is token 2 of pCompletion then
         subtract 1 from tNestingDepth
         if tNestingDepth = 0 then
            # The structure is already completed
            return false
         end if
      else if pStructureType is "case" then
         # special case `case` so it behaves sensibly
         if (token 1 of tLine is "end" and token 2 of tLine is "switch") or \
               token 1 of tLine is "case" or \
               token 1 of tLine is "default" then
            # if the switch structure ends then we need a break
            return true
         else if token 1 of tLine is not empty then
            # if there's existing code within the case then we
            # can reasonably assume that they don't want to put a break
            # above it
            return false
         end if
      else if token 1 of tLine is "end" and token 2 of tLine is not among the items of autoCompleteUnnamedStructures() and token 2 of tLine is not "if" then
         # If a named structure is ending, but it doesn't match the structure we are looking for
         # then if the structure we're looking for is un-named, we return true
         if pStructureName is empty then
            return true
         end if
         
         # Else if we are looking for a named structure, then don't do the completion, because
         # its possible that the user is renaming a handler and we should be conservative here.
         if pStructureName is not empty then
            return false
         end if
      else
         get autoCompleteGetStructure(tLine)
         
         # If we have a matching structure being opened, increment the nesting depth
         if line 1 of it is pStructureType and line 2 of it is pStructureName then
            add 1 to tNestingDepth
         end if
         
         # If a new handler has started and we are completing an any structure then
         # we should return true now.
         if line 2 of it is not empty then
            return true
         end if
      end if
   end repeat
   
   return true
end autoCompleteCompletionRequired

function autoCompleteInSlashCommentOrOutOfHandler @pScript, pLineNumber
   local tScript, tSlashStart, tSlashEnd, tNumItems, tNumLines, tSelChar

   put slash & "*" into tSlashStart
   put "*" & slash into tSlashEnd

   put word 2 of the selectedChunk into tSelChar
   if tSelChar is empty then
      return empty
   end if

   set the lineDelimiter to tSlashStart
   set the itemDelimiter to tSlashEnd

   put the number of lines of char 1 to tSelChar of pScript into tNumLines
   put the number of items of char 1 to tSelChar of pScript into tNumItems

   set the lineDelimiter to return
   set the itemDelimiter to comma

   if tNumLines is not tNumItems then
      return true
   end if

   local tLine, tHandlerStartsA, tUnNamedStructures

   put "on,function,command,setProp,getProp,after,before,private" into tHandlerStartsA
   split tHandlerStartsA by comma as set

   put "if,repeat,try,switch,case" into tUnNamedStructures

   put line pLineNumber of pScript into tLine
   if tHandlerStartsA[token 1 of tLine] then return false

   local tLineOffsetEnd, tLineOffsetEndSkip, tOffsetStartNameLine, tOffsetStartSkip, tLookFor, tHandlerName
   put "end" into tLookFor
   put empty into tHandlerName
   put 0 into tOffsetStartSkip

   put pLineNumber into tLineOffsetEndSkip

   repeat
      put lineOffset(tLookFor, pScript, tLineOffsetEndSkip) into tLineOffsetEnd
      if tLineOffsetEnd = 0 then exit repeat
      add tLineOffsetEnd to tLineOffsetEndSkip

      put line tLineOffsetEndSkip of pScript into tLine
      if token 1 of tLine is not tLookFor then next repeat
      if token 2 of tLine is among the items of tUnNamedStructures then
         next repeat
      else
         put token 2 of tLine into tHandlerName
         exit repeat
      end if
   end repeat

   if tHandlerName is empty then return true

   repeat
      put lineOffset(tHandlerName, pScript, tOffsetStartSkip) into tOffsetStartNameLine
      if tOffsetStartNameLine = 0 then exit repeat
      add tOffsetStartNameLine to tOffsetStartSkip

      put line tOffsetStartSkip of pScript into tLine
      if tHandlerStartsA[token 1 of tLine] then
         if token 1 of tLine is "private" then
            if token 3 of tLine is tHandlerName then
               exit repeat
            else
               next repeat
            end if
         else
            if token 2 of tLine is tHandlerName then
               exit repeat
            else
               next repeat
            end if
         end if
      end if
   end repeat

   if tOffsetStartSkip < pLineNumber then return false

   return true
end autoCompleteInSlashCommentOrOutOfHandler

function autoCompleteIFsAreBalanced pLineNumber, pScript
   local tHandlerStarts, tHandlerName

   put "on,function,command,setProp,getProp,after,before,private" into tHandlerStarts

   --put textGetScript() into tScript

   repeat with i = pLineNumber down to 1
      if token 1 of line i of pScript is among the items of tHandlerStarts then
         exit repeat
      end if
   end repeat

   delete line 1 to i - 1 of pScript

   if token 1 of line 1 of pScript is "private" then
      put token 3 of line 1 of pScript into tHandlerName
   else
      put token 2 of line 1 of pScript into tHandlerName
   end if

   local tCounter
   repeat for each line aLine in pScript
      add 1 to tCounter
      if token 1 of aLine is "end" and token 2 of aLine is tHandlerName then
         exit repeat
      end if
   end repeat

   put line 1 to tCounter of pScript into pScript

   -- remove slash asterisk comments
   local tBeginAsterix, tEndAsterix, tCharBegin, tCharEnd
   put slash & "*" into tBeginAsterix
   put "*" & slash into tEndAsterix

   repeat
      put offset(tBeginAsterix, pScript) into tCharBegin
      if tCharBegin is 0 then exit repeat
      put offset(tEndAsterix, pScript) into tCharEnd
      delete char tCharBegin to tCharEnd of pScript
   end repeat

   -- remove comments after backslash
   -- and remove line-continuation
   local tBackSlashStart, tReturnStart
   put 0 into tBackSlashStart
   repeat
      put offset(backslash, pScript, tBackSlashStart) into tBackSlashStart
      if tBackSlashStart is 0 then exit repeat
      put offset(return, pScript, tBackSlashStart) into tReturnStart
      delete char tBackSlashStart to tBackSlashStart + tReturnStart  of pScript
      put 0 into tBackSlashStart
   end repeat

   replace ";" with return in pScript -- remove ";"

   local tDepth, tToken1, tElse, tIf_Then_CodeFlag, tElse_IFFlag
   put "e" & "lse" into tElse -- avoid "tokenization"
   put false into tIf_Then_CodeFlag
   put false into tElse_IFFlag
   put 0 into tDepth

   repeat for each line aLine in pScript
      put token 1 of aLine into tToken1
      if tToken1 is empty then next repeat

      ######### get rid of one-liners
      --   if foo() then code else code
      if tToken1 is "if" and token -1 of aLine is not "then" and tElse is among the tokens of aLine then
         next repeat
      end if

      --   if foo()
      --   then code else code
      if tToken1 is "then" and token -1 of aLine is not "then" and tElse is among the tokens of aLine then
         next repeat
      end if
      ######### end get rid of one-liners

      ######### special case of if-then-code
      --   if bar() then code <-- can go on with else or end here
      --   else
      --      code
      --   end if
      -- or
      --   if bar() then code <-- can end with else_code
      -- -- optionally some lines else-if-then
      --   else code

      if tIf_Then_CodeFlag then
         if tToken1 is tElse then

            if the number of tokens of aLine = 1 then
               put false into tIf_Then_CodeFlag
               add 1 to tDepth
               next repeat
            end if

            if token 2 of aLine is "if" and token -1 of aLine is "then" then
               put false into tIf_Then_CodeFlag
               add 1 to tDepth
               next repeat
            end if

            if token 2 of aLine is "if" and token -1 of aLine is not "then" then
               next repeat
            end if

            if token 2 of aLine is not "if" and the number of tokens of aLine > 1 then
               put false into tIf_Then_CodeFlag
               next repeat
            end if

         else
            put false into tIf_Then_CodeFlag
         end if
      end if

      -- condition of entering special case if-then-code
      if tToken1 is "if" and "then" is among the tokens of aLine and  \
            token -1 of aLine is not "then" and tElse is not among the tokens of aLine then
         put true into tIf_Then_CodeFlag
         next repeat
      end if

      if tToken1 is "then" and  \
            token -1 of aLine is not "then" and tElse is not among the tokens of aLine then
         put true into tIf_Then_CodeFlag
         next repeat
      end if
      ######### end special case: if-then-code

      if tToken1 is "if" and token -1 of aLine is "then" then
         add 1 to tDepth
      end if

      if tToken1 is "then" and token -1 of aLine is "then" then
         add 1 to tDepth
      end if

      ####################
      --   if foo() then
      --      code else code <--
      if tElse is among the tokens of aLine and  \
            (tToken1 is not tElse) and  \
            (token -1 of aLine is not tElse) and \
            (tToken1 is not "then" and tToken1 is not "if") then
         subtract 1 from tDepth
      end if
      ####################

      ####################
      --      if foo() then
      --         code
      --      else code <--
      if tToken1 is tElse and token -1 of aLine is not tElse and "if" is not among the tokens of aLine then
         subtract 1 from tDepth
      end if
      ####################

      ####################
      -- special case else-if-code
      --   if foo() then
      --      code
      --   else if bar() then code <-- can end here
      -- or
      --   if foo() then
      --      code
      --   else if bar() then code
      --   else <-- or go on with else
      --   code

      if tElse_IFFlag then
         if tToken1 is tElse then

            if token 2 of aLine is "if" and token -1 of aLine is not "then" then
               next repeat
            end if

            put false into tElse_IFFlag
            next repeat

         else
            put false into tElse_IFFlag
            subtract 1 from tDepth
         end if
      end if

      -- special case else-if-code
      -- also tests else-if without "then", "then" is in this case on following line
      if tToken1 is tElse and token 2 of aLine is "if" and token -1 of aLine is not "then" then
         put true into tElse_IFFlag
         next repeat
      end if
      -- end special case else-if-code
      ####################

      if tToken1 is "end" and token 2 of aLine is "if" then
         subtract 1 from tDepth
      end if

   end repeat

   if tDepth is 0 then
      return false
   else
      return true
   end if

end autoCompleteIFsAreBalanced

# Returns
#   A comma separated list of the autocompleteable structures that have names. This is currently just handlers.
private function autoCompleteNamedStructures
   return handlerTypes()
end autoCompleteNamedStructures

# Returns
#   A comma separated list of the autocompleteable structures without names. Note that we only complete IF statements when the last token is then
#   because there are too many possibilities, (else, else if, end if) and its better to not complete than risk forcing the user to delete stuff.
private function autoCompleteUnnamedStructures
   return "repeat,try,switch,case"
end autoCompleteUnnamedStructures

# Parameters
#   pLine : a line number in the current script
# Returns
#   A string describing the structure whose beginning is found on pLine. This is in the following format:
#     Line 1 : The structure's type, e.g. command, repeat, try
#     Line 2 : The structure's name if it has one, e.g. mouseUp
#   If pLine does not represent the beginning of a completable structure then the structure type will be empty.
private function autoCompleteGetStructure pLine
   local tLine
   put pLine into tLine
   
   # Disregard "private" if first token
   if token 1 of tLine is "private" then
      put token 2 to -1 of tLine into tLine
   end if
   
   local tStructureType, tStructureName
   
   # Establish what the structure type and name (if appropriate) are. We autocomplete handler declarations,
   # repeats, trys and switches, but not ifs (because they have too many different forms, might annoy the user).
   if token 1 of tLine is among the items of autoCompleteNamedStructures() then
      put token 1 of tLine into tStructureType
      put token 2 of tLine into tStructureName
   else if token 1 of tLine is among the items of autoCompleteUnnamedStructures() then
      put token 1 of tLine into tStructureType
      put empty into tStructureName
   else if token 1 of tLine is "if" and the last token of tLine is "then" then
      put "if" into tStructureType
      put empty into tStructureName
   end if
   
   return tStructuretype & return & tStructureName
end autoCompleteGetStructure

# Parameters
#   pStructureType : the type of a completeable structure
#   pStructureName : the name of a compleatable structure (may be empty)
# Returns
#   The completion of the stucture if one is known. E.g if pStructureType is "on" and pStuctureName is "mouseUp",
#   will return "end mouseUp"
private function autoCompleteGetCompletion pStructureType, pStructureName
   # Make sure we have something valid that can be completed
   if pStructureType is empty then
      return empty
   end if
   
   # Work out the completion
   local tCompletion
   if pStructureType is among the items of handlerTypes() then
      if pStructureName is not empty then
         put "end " & pStructureName into tCompletion
      end if
   else if pStructureType is "case" then
      local tTabDepth
      put __GetPreference("editor,tabdepth", 3) into tTabDepth
      
      repeat for tTabDepth
         put space after tCompletion
      end repeat
      put "break" after tCompletion
   else
      put "end " & pStructureType into tCompletion
   end if
   
   return tCompletion
end autoCompleteGetCompletion

private function getSelectedText
   local tFrom, tTo
   get the selectedChunk
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   local tText
   if tTo < tFrom then
      getCaretToken
      put the result into tText
   else
      put char tFrom to tTo of textGetScript() into tText
   end if
   
   return tText
end getSelectedText

# OK-2009-01-22 : Bug 7278 - Use the clickText instead of the selectedText for the context menu
# Also modified getCaretToken by adding optional pUseClick parameter.
function getClickText
   --   local tFrom, tTo
   --   get the clickChunk
   --   put word 2 of it into tFrom
   --   put word 4 of it into tTo
   
   local tText
   --   if tTo < tFrom then
   getCaretToken true
   put the result into tText
   --else
   --   put char tFrom to tTo of textGetScript() into tText
   --end if
   
   return tText
end getClickText

private function handleEvent pEvent, pTarget
   if the long id of pTarget is the long id of field "Script" of me then
      return true
   else
      return false
   end if
end handleEvent

# OK-2009-03-02 : Bug 7773
on optionKeyDown pKey
   if not handleEvent("optionKey", the long id of the target) then
      pass optionKeyDown
   end if
   
   if pKey is not an integer or pKey <= 9 then
      __DoKeyDown pKey
   end if
end optionKeyDown


on scrollBarDrag
   if the short name of the target is "Gutter" or the short name of the owner of the target is "Gutter" then
      exit scrollBarDrag
   end if

   local tVScroll
   
   # 2017-JUL-28 bhall2001
   # update only when vScroll changes. Mouse wheel scrolling sends
   # vScrolls that don't change. Up arrow causes 2 scrollBarDrag message
   # so we skip the message when up arrow flag is set.
   put the vScroll of the target into tVScroll
   if (tVScroll = sVScroll) or sSkipUpArrow then exit scrollBarDrag
   
   lock screen
   put tVScroll into sVScroll
   
   updateGutterRequest empty, empty, empty, empty, false, true, false, true
   unlock screen
end scrollBarDrag

on keyDown pChar
   if not handleEvent("keydown", the long id of the target) then
      pass keyDown
   end if
   
   if scriptLocked() then
      exit keyDown
   end if
   
   __DoKeyDown pChar
end keyDown

private command __DoKeyDown pChar
   get the selectedChunk
   
   local tFrom, tTo
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   local tAt, tLength
   if tFrom > tTo then -- the caret is at the end
      put 0 into tLength
      put tFrom into tAt
   else
      put tFrom into tAt
      put tTo - tFrom + 1 into tLength
   end if
   textReplace tAt, char tAt to tAt + tLength - 1 of field "Script" of me, pChar
end __DoKeyDown

on backspaceKey
   if not handleEvent("backspaceKey", the long id of the target) then
      pass backspaceKey
   end if
   
   if scriptLocked() then
      exit backspaceKey
   end if
   
   get the selectedChunk
   
   local tFrom, tTo
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   local tAt, tLength
   if tFrom > tTo then
      -- Caret handling, for now, is only done for an "empty" selection.
      local tLine
      put word 2 of the selectedLine into tLine
      
      local tScript
      put the text of the selectedField into tScript
      
      local tLineStart
      put the number of chars of line 1 to (tLine - 1) of tScript + 1 into tLineStart
      -- Only add offset of return if we are not on the first line of the script
      if tLine is not 1 then
         add 1 to tLineStart
      end if
      
      # OK-2008-08-28 : Bug 6515 - Delete whole word with commandKey
      if the commandKey is "down" then
         local tWordFound
         put false into tWordFound
         repeat with x = tTo down to 1
            if not matchText(char x of tScript, "\s") then
               put true into tWordFound
            else
               if tWordFound then
                  exit repeat
               end if
            end if
         end repeat
         
         if x <> 1 then
            put x + 1 into tAt
         else
            put x into tAt
         end if
         
         put tTo - tAt + 1 into tLength
      else
         # OK-2008-08-05 : Bug 6867 - If autoformatting is turned off, simply delete the last selected character
         -- allow environment with no dependencies
         local tAutoFormat
         put __GetPreference("editor,autoformat", true) into tAutoFormat
         
         if tAutoFormat then
            put caretPositionLeft(tLineStart, tTo, tScript) + 1 into tAt
         else
            put tTo into tAt
         end if
         put tTo - tAt + 1 into tLength
      end if
   else
      put tTo - tFrom + 1 into tLength
      put tFrom into tAt
   end if
   
   textReplace tAt, char tAt to tAt + tLength - 1 of field "Script" of me, empty
   
   # If the user has deleted a selection of text rather than a single character, they will
   # expect this to be a single undoable operation. So we close the current group straight
   # after the deletion. in this case.
   if tTo > tFrom then
      textEndGroup
   end if
end backspaceKey

on deleteKey
   if not handleEvent("deleteKey", the long id of the target) then
      pass deleteKey
   end if
   
   if scriptLocked() then
      exit deleteKey
   end if
   
   get the selectedChunk
   
   local tFrom, tTo
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   local tAt, tLength
   if tFrom > tTo then
      put tFrom into tAt
      put 1 into tLength
   else
      put tFrom into tAt
      put tTo - tFrom + 1 into tLength
   end if
   
   textReplace tAt, char tAt to tAt + tLength - 1 of field "Script" of me, empty
   
   # If the user has deleted a selection of text rather than a single character, they will
   # expect this to be a single undoable operation. So we close the current group straight
   # after the deletion. in this case.
   if tTo > tFrom then
      textEndGroup
   end if
end deleteKey

on tabKey
   if not handleEvent("tabKey", the long id of the target) then
      pass tabKey
   end if
   
   # To prevent interference with the command+tab shortcut to cycle between tabs
   if the commandKey is "down" then
      pass tabKey
   end if
   
   # bhall2001-2017-07-18: Bug 18366 On MacOS, to prevent interference
   # with the use of control+tab to cycle between tabs
   if (the platform is "MacOS") and (the controlKey is "down") then
      pass tabKey
   end if 

   if scriptLocked() then
      exit tabKey
   end if
   
   -- allow environment with no dependencies
   local tAutoFormat
   put __GetPreference("editor,autoformat", true) into tAutoFormat
   
   local tProviderCompletion
   put __GetPreference("editor,providercompletion", true) into tProviderCompletion
   
   local tDoTab = true
   
   if tProviderCompletion and \
         revEnvironmentEditionProperty("autocomplete") then
      ideAutocompleteHandleTab the long id of me, sObjectId, sPlaceholders, sEditPlaceholder, sEditChunks
      put the result into tDoTab
   end if
   
   if tDoTab then
      if tAutoFormat then
         if the shiftKey is "down" then
            scriptFormat "script"
         else
            scriptFormat "handler"
         end if
      else
         get the selectedChunk
         
         local tFrom, tTo
         put word 2 of it into tFrom
         put word 4 of it into tTo
         
         local tAt, tLength
         if tFrom > tTo then
            put tFrom into tAt
            put 0 into tLength
         else
            put tFrom into tAt
            put tTo - tFrom into tLength
         end if
         
         textReplace tAt, char tAt to tAt + tLength - 1 of field "Script" of me, tab
      end if
   end if
end tabKey

# Key identifiers for a few important keys...
constant kKeyHome = "65360"
constant kKeyEnd = "65367"
constant kKeyLeftArrow = "65361"
constant kKeyRightArrow = "65363"
constant kKeyUpArrow = "65362"
constant kKeyDownArrow = "65364"
constant kKeyF1 = "65470"
constant kKeyF2 = "65471"
constant kKeyF3 = "65472"
constant kKeyF4 = "65473"
constant kKeyF5 = "65474"
constant kKeyF6 = "65475"
constant kKeyF7 = "65476"
constant kKeyF8 = "65477"
constant kKeyF9 = "65478"
constant kKeyF10 = "65479"
constant kKeyF11 = "65480"
constant kKeyF12 = "65481"
constant kKeyF13 = "65482"
constant kKeyNumLock = "65407"
constant kKeyPageUp = "65365"
constant kKeyPageDown = "65366"
# constant kKeyMenu = "80"

private command selectFromCurrentToLineStart
   local tAt
   put word 4 of the selectedChunk into tAt
   
   local tLineNumber
   put word 2 of the selectedLine into tLineNumber
   
   local tLineStart
   put the number of chars of line 1 to (tLineNumber - 1) of the text of getScriptField() + 1 into tLineStart
   # Only add offset of return if we are not on the first line of the script
   if tLineNumber is not 1 then
      add 1 to tLineStart
   end if
   
   select char tLineStart to tAt of field (the short name of getScriptField()) of me
end selectFromCurrentToLineStart

private command selectFromCurrentToLineEnd
   local tAt
   put word 4 of the selectedChunk into tAt
   
   local tLineNumber
   put word 2 of the selectedLine into tLineNumber
   
   local tLineEnd
   put the number of chars of line 1 to tLineNumber of the text of getScriptField() into tLineEnd
   
   select char (tAt + 1) to tLineEnd of field (the short name of getScriptField()) of me
end selectFromCurrentToLineEnd

-- Description
--   Implements a basic page up functionality for OS X, as this is not default field behavior.
private command pageUp
   local tLineNumber
   put word 2 of the selectedLine into tLineNumber
   
   -- Work out the number of lines in one "page" of the script editor field.
   local tLineCount
   put the height of getScriptField() div the textHeight of getScriptField() into tLineCount
   
   -- Work out which line number we need to scroll up to
   local tNewLineNumber
   put max(tLineNumber - tLineCount, 1) into tNewLineNumber
   
   -- Calculate the char that we need to reach to do the page up
   local tStartChar
   put the number of chars of line 1 to tNewLineNumber of the text of getScriptField() into tStartChar
   
   local tAt
   put word 4 of the selectedChunk into tAt
   
   if shiftKey() is "down" then
      select char tStartChar to tAt of field (the short name of getScriptField()) of me
   else
      select after char tStartChar of field (the short name of getScriptField()) of me
   end if
end pageUp

-- Description
--   Implements a basic page down functionality for OS X, as this is not default field behavior.
private command pageDown
   local tMultiSelection, tAt
   get the selectedChunk
   if word 4 of it > word 2 of it then
      put true into tMultiSelection
      put word 4 of it into tAt
   else
      put false into tMultiSelection
      put word 2 of it into tAt
   end if
   
   local tLineNumber
   if tMultiSelection then
      put word 4 of the selectedLine into tLineNumber
   else
      put word 2 of the selectedLine into tLineNumber
   end if
   
   -- Work out the number of lines in one "page" of the script editor field.
   local tLineCount
   put the height of getScriptField() div the textHeight of getScriptField() into tLineCount
   
   -- Work out which line number we need to scroll down to
   local tNewLineNumber
   put min(tLineNumber + tLineCount, the number of lines of the text of getScriptField()) into tNewLineNumber
   
   -- Calculate the char that we need to reach to do the page down
   local tEndChar
   put the number of chars of line 1 to tNewLineNumber of the text of getScriptField() into tEndChar
   
   if shiftKey() is "down" then
      select char tAt to tEndChar of field (the short name of getScriptField()) of me
   else
      select after char tEndChar of field (the short name of getScriptField()) of me
   end if
end pageDown

# Description
#   RawKeyDown is handled mainly because of the home and end keys. These need to be manually implemented on OS X
#   and both platforms after pressing the home key we have to ensure the caret ends up in the right place.
#   Other keys may be blocked here to prevent weird chars getting inserted into the script.
on rawKeyDown pKey
   if not handleEvent("rawKeyDown", the long id of the target) then
      pass rawKeyDown
   end if
   
   # For the beginning of line/paragraph action (there is no distinction in the S/E)
   # make sure we update the caret position after the field has had its go.
   
   if the platform is not "macos" then
      # For Windows: Home (Windows / Linux)
      if pKey is kKeyHome then
         put true into sArrowKeyPressed
         send "selectionChangedByArrowKey" to me in 0 milliseconds
         pass rawKeyDown
      end if
   else
      # For Mac: Ctrl-Left / Cmd-Left / Ctrl-A (Mac)
      if (pKey is kKeyLeftArrow and \
            (the eventCommandKey is down or \
            the eventControlKey is down) and \
            the eventShiftKey is up and \
            the eventOptionkey is up) or \
            (pKey is 65 and \
            the eventCommandKey is up and \
            the eventControlKey is down and \
            the eventShiftKey is up and \
            the eventOptionkey is up) then
         put true into sArrowKeyPressed
         send "selectionChangedByArrowKey" to me in 0 milliseconds
         pass rawKeyDown
      end if
      
      # For actions where we need to skip back, we need to ensure the caret is at the
      # start of the line if it is in the white-space prefix.
      
      # For Mac: Alt-Down
      if (pKey is kKeyUpArrow) and \
            the eventCommandKey is up and \
            the eventControlKey is up and \
            the eventShiftKey is up and \
            the eventOptionkey is down then
         local tScript
         put the text of the selectedField into tScript
         
         local tCaretChar
         get the selectedChunk
         put word 2 of it into tCaretChar
         try
            repeat while tCaretChar > 1 and (char (tCaretChar - 1) of tScript is space)
               subtract 1 from tCaretChar
            end repeat
         catch tError
            put tError
         end try
         if tCaretChar is not 1 and char tCaretChar - 1 of tScript is return then
            lock messages
            select before char tCaretChar of the selectedField
            unlock messages
         end if
      end if
      
   end if
   
   # optionKey is down
   local tKeyName
   if (pKey is kKeyLeftArrow or pKey is kKeyRightArrow) and \
         the eventCommandKey is up and \
         the eventShiftKey is up and \
         the eventOptionkey is down and \
         the eventControlKey is up then
      put true into sArrowKeyPressed
      if pKey is kkeyRightArrow then
         send "selectionChangedByArrowKey" to me in 0 milliseconds
      else
         put "left" into tKeyName
         send "selectionChangedByArrowKey tKeyName" to me in 0 milliseconds
      end if
      pass rawKeyDown
   end if
   
   if pKey is not among the items of kKeyLeftArrow,kKeyRightArrow,kKeyUpArrow,kKeyDownArrow then
      pass rawKeyDown
   end if
   
   # for simple arrowKeys
   
   #  [[ Bug 18595 ]] "cursor should move to begin of text if click is left of text"
   # moved handling of arrowKey from rawKeyUp here to flag arrowKey in sArrowKeyPressed
   # before "selectionChanged" message is fired 
   
   switch pKey
      case kKeyLeftArrow
         put "left" into tKeyName
         break
      case kKeyRightArrow
         put "right" into tKeyName
         break
      case kKeyUpArrow
         # 2017-JUL-28 bhall2001
         # when scrolling on up arrow, scrollBarDrag is sent twice. Set
         # flag to update on every other up arrow message
         put not sSkipUpArrow into sSkipUpArrow
         put "up" into tKeyName
         break
      case kKeyDownArrow
         put "down" into tKeyName
         break
   end switch
   
   local tPass = true
   if revEnvironmentEditionProperty("autocomplete") then
      ideAutocompleteHandleArrow the long id of me, tKeyName, sObjectId, sPlaceholders, sEditPlaceholder, sEditChunks
      put the result into tPass
   end if
   
   if not scriptLocked() and tPass then
      textMark "Insert"
      put true into sArrowKeyPressed
      send "selectionChangedByArrowKey tKeyName" to me in 0 milliseconds
   end if
   
   if tPass then
      pass rawKeyDown
   end if
end rawKeyDown

-- Drag Drop Management
local sDragMode

on dragDrop
   if not handleEvent("dragDrop", the long id of the target) then
      pass dragDrop
   end if
   
   if scriptLocked() then
      exit dragDrop
   end if
   
   lock screen
   textBeginGroup "Drag"
   
   local tDropAt
   get the dropChunk
   put word 2 of it into tDropAt
   
   local tSelectFrom, tSelectTo
   get the selectedChunk
   put word 2 of it into tSelectFrom
   put word 4 of it into tSelectTo
   
   if tDropAt >= tSelectFrom and tDropAt <= tSelectTo then
      exit dragDrop
   end if
   
   if sDragMode is "cut" then
      -- Remove the selection. This will never happen on a drag that started outside the ScriptEditorPane.
      
      -- in this case, we cannot have tFrom > tTo
      textReplace tSelectFrom, char tSelectFrom to tSelectTo of control "Script" of me, empty
      
      if tDropAt > tSelectTo then
         subtract tSelectTo - tSelectFrom + 1 from tDropAt
      end if
   end if
   
   
   local tDroppedText
   put dragData["text"] into tDroppedText
   -- There is an issue with the very last return character, for now it seams sufficient to remove this.
   #  if char -1 of tDroppedText is return then
   #    delete char -1 of tDroppedText
   #  end if
   
   textReplace tDropAt, empty, tDroppedText
   
   textEndGroup
   unlock screen
end dragDrop

on dragStart
   if not handleEvent("dragStart", the long id of the target) then
      pass dragStart
   end if
   
   # OK-2008-08-01 : Bug 6709 - On Macs, the option key should result in a copying drag.
   if the platform is not "MacOS" then
      if the controlKey is "down" then
         put "copy" into sDragMode
      else
         put "cut" into sDragMode
      end if
   else
      if the optionKey is "down" then
         put "copy" into sDragMode
      else
         put "cut" into sDragMode
      end if
   end if
   
   pass dragStart
end dragStart

on dragEnd
end dragEnd

# Description
## Returns a line stripped of comments at the end of the line
## and inline comments ( /* ... */ )
private function lineStripComments pLine
   local tLine, tInComment
   split pLine by quote
   
   put false into tInComment
   repeat with tIndex = 1 to the number of elements of pLine step 2
      put __StripComment(pLine[tIndex], tInComment) after tLine
      if tInComment then exit repeat
      if tIndex is not the number of elements of pLine then
         put quote & pLine[tIndex+1] & quote after tLine
      end if
   end repeat
   
   return tLine
end lineStripComments

private function __StripComment pLine, @xInComment
   local tOffset
   repeat for each word tComment in "# -- //"
      put offset(tComment, pLine) into tOffset
      if tOffset is not 0 then
         delete char tOffset to -1 of pLine
         put true into xInComment
      end if
   end repeat

   put __StripBlockComment(pLine, xInComment) into pLine
   
   return pLine
end __StripComment

private function __StripBlockComment pline, @xInComment
   local tOffset, tOffsetEnd
   put offset("/*", pLine) into tOffset
   if tOffset is not 0 then
      put offset("*/", pLine, tOffset) into tOffsetEnd
      if tOffsetEnd is not 0 then
         delete char tOffset to tOffset + tOffsetEnd of pLine
         put __StripBlockComment(pLine, xInComment) into pLine
      else
         delete char tOffset to -1 of pLine
         put true into xInComment
      end if
   end if

   return pLine
end __StripBlockComment

################################################################################

command actionCopy
   copy
end actionCopy

command actionCut
   if scriptLocked() then
      exit actionCut
   end if
   
   get the selectedChunk
   
   local tFrom, tTo
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   if tFrom <= tTo then -- something is selected
      textBeginGroup "Cut"
      copy -- set the clipboard (dont cut as we do not allow field modification here)
      textReplace tFrom, char tFrom to tTo of field "Script" of me, empty
      textEndGroup
   end if
end actionCut

command actionPaste
   if scriptLocked() then
      exit actionPaste
   end if
   
   get the selectedChunk
   
   local tFrom, tTo
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   lock screen
   textBeginGroup "Paste"
   textReplace tFrom, char tFrom to tTo of field "Script" of me, the clipboardData["text"]
   -- allow environment with no dependencies
   local tAutoFormat
   put __GetPreference("editor,autoformat", true) into tAutoFormat
   
   if tAutoFormat then
      scriptFormat "handler", true
   end if
   textEndGroup
   unlock screen
end actionPaste

command actionUndo
   if scriptLocked() then
      exit actionUndo
   end if
   textUndo
end actionUndo

command actionRedo
   if scriptLocked() then
      exit actionRedo
   end if
   textRedo
end actionRedo

command actionDeselectAll
   lock messages
   select empty
   unlock messages
end actionDeselectAll

command actionSelectAll
   lock messages
   
   if word 1 of the name of the focusedObject is "field" then
      select char 1 to -1 of the focusedObject
   end if
   unlock messages
end actionSelectAll

# Parameters
#   rStartLine : receives the line number that the current selection begins on
#   rEndLine : receices the line number that the current selection ends on
#   rStartChar : receives the char that the curent selection starts on
#   rText : receives the block of text that will be commented or uncommented.
# Description
#   This command obtains the details required to comment / uncomment a block of code
#   it is used by the scriptComment and scriptUncomment commands.
private command commentGetDetails @rStartLine, @rEndLine, @rStartChar, @rText
   # Calculate the chunk of text that the commenting will be applied to
   local tStartLine, tEndLine
   get the selectedLine
   put word 2 of it into tStartLine
   if word 3 of it is "to" then
      put word 4 of it into tEndLine
   end if
   
   # Adjust the chunk so that we have only complete lines by searching from the beginning
   # backwards to the next return char. Don't bother doing this for the end as this doesn't matter.
   get the selectedChunk
   local tCurrentStart
   put word 2 of it into tCurrentStart
   
   local tStartChar
   
   if tStartLine = 1 then
      put 1 into tStartChar
   else
      local tPreviousChars
      put char 1 to (tCurrentStart - 1) of field "Script" of me into tPreviousChars
      
      local tOffset
      put 0 into tOffset
      repeat with x = the number of chars of tPreviousChars down to 1
         if char x of tPreviousChars is return then
            exit repeat
         end if
         add 1 to tOffset
      end repeat
      #subtract 1 from tOffset
      
      put tCurrentStart - tOffset into tStartChar
   end if
   
   # Get the text and add in the comments
   local tText
   if tEndLine is empty then
      put line tStartLine of field "Script" of me into tText
   else
      put line tStartLine to tEndLine of field "Script" of me into tText
   end if
   
   put tStartChar into rStartChar
   put tStartLine into rStartLine
   put tEndLine into rEndLine
   put tText into rText
end commentGetDetails

# Description
#  Returns the last known token that the caret was placed into. This is not done properly
#  at the moment as it depends on the syntax, for now we just return something sensible.
command getCaretToken pUseClick
   local tScript
   put the text of getScriptField() into tScript
   
   # Don't return tokens in comments. For now we determine if the user is typing
   # in a comment by simple means, using proper tokenization is not yet possible.
   # This means that multi-line comments will break this.
   local tLine
   if pUseClick then
      put word 2 of the clickLine into tLine
   else
      put word 2 of the selectedLine of getScriptField() into tLine
   end if
   if token 1 of line tLine of tScript is empty then
      return empty
   end if
   
   local tSelectedText
   if pUseClick then
      put the clickText into tSelectedText
   else
      put the selectedText of getScriptField() into tSelectedText
      # OK-2008-06-22 : Bug 8054 - pUseClick is only set if we are building a context menu, so in this case
      # do the expansion anyway to try and get a whole token.
      if tSelectedText is not empty then
         return tSelectedText
      end if
   end if
   
   # This is expanded to include tokens that the caret was placed immediately before or after,
   # the reason for this is that it allows us to begin searching for tokens while the user is typing.
   local tFrom, tTo
   if pUseClick then
      get the clickChunk
   else
      get the selectedChunk
   end if
   put word 2 of it into tFrom
   put word 4 of it into tTo
   
   # We can't perfectly match tokens at the moment, so we just make a reasonable guess with a regular expression
   # to match any char that delimits a token.
   ## AL-2014-01-15: [[ Bug 11094 ]] Added # to the list of script editor token delimiters
   local tExpression 
   put "\s|[\%\^\&\*\(\)\-\+\=\]\]\;\,\\@\\\/\<\>\#]" into tExpression
   
   # Try looking backwards first
   local tText, tChar
   repeat with x = (tFrom - 1) down to 1
      put char x of tScript into tChar
      if matchText(tChar, tExpression) then
         exit repeat
      end if
      put tChar before tText
   end repeat
   
   # Try looking forwards
   repeat with x = tFrom to the number of chars of tScript
      put char x of tScript into tChar
      if matchText(tChar, tExpression) then
         exit repeat
      end if
      put tChar after tText
   end repeat
   
   return tText
end getCaretToken

# Description
#   Comments out the selected text
command scriptComment
   local tStartLine, tEndLine, tStartChar, tText
   commentGetDetails tStartLine, tEndLine, tStartChar, tText
   if tStartLine is empty then
      exit scriptComment
   end if
   
   lock screen
   
   -- allow environment with no dependencies
   local tCommentChar
   put __GetPreference("editor,commentchar", "--") into tCommentChar

   local tCommentedText
   repeat for each line tLine in tText
      # Don't comment out empty lines as it looks messy
      if not matchText(tLine, "^\s*$") then
         put tCommentChar before tLine
      end if
      put tLine & return after tCommentedText
   end repeat
   delete the last char of tCommentedText
   
   # Apply the mutation to the field
   textBeginGroup "Comment"
   textReplace tStartChar, tText, tCommentedText
   
   # Restore the selection
   select char tStartChar to tStartChar + length(tCommentedText)  of field "Script"
   
   # OK-2009-03-03 : Bug 7537 - Reformat the handler after commenting, this may be flawed,
   # but the proper solution is rather time-consuming.
   -- allow environment with no dependencies
   local tAutoFormat
   put __GetPreference("editor,autoformat", true) into tAutoFormat
   
   if tAutoFormat then
      scriptFormat "handler", true
   end if
   textEndGroup
   
   unlock screen
end scriptComment

# Desription
#   Uncomments the selected text
command scriptUncomment
   local tStartLine, tEndLine, tStartChar, tText
   commentGetDetails tStartLine, tEndLine, tStartChar, tText
   if tStartLine is empty then
      exit scriptUncomment
   end if
   
   lock screen
   -- allow environment with no dependencies
   local tCommentChar
   put __GetPreference("editor,commentchar", "--") into tCommentChar
   
   local tUncommentedText
   
   local tCommentCharLength
   put the length of tCommentChar  into tCommentCharLength
   
   repeat for each line tLine in tText
      # Remove the first comment char that appears on the line
      local tOffset
      put offset(tCommentChar, tLine) into tOffset
      if tOffset is 0 then
         put tLine & return after tUncommentedText
         next repeat
      end if
      
      # Only remove the comment char if there is nothing significant before it
      # MM-2012-09-28: [[ Bug 10162 ]] Make sure we include lines with chars before the comment in the uncommented text.
      local tPreviousChars
      put char 1 to (tOffset - 1) of tLine into tPreviousChars
      if matchText(tPreviousChars, "^\s*$") then
         if char tOffset + tCommentCharLength of tLine is space then
            delete char tOffset + tCommentCharLength of tLine
         end if
         put char 1 to (tOffset - 1) of tLine & char (tOffset + tCommentCharLength) to -1 of tLine & return after tUncommentedText
      else
         put tLine & return after tUncommentedText
      end if
   end repeat
   delete the last char of tUncommentedText
   
   # Apply the mutation to the field
   textBeginGroup "Uncomment"
   textReplace tStartChar, tText, tUncommentedText
   
   # Restore the selection
   select char tStartChar to tStartChar + length(tUncommentedText)  of field "Script"
   
   # OK-2009-03-03 : Bug 7537 - Reformat the handler after commenting, this may be flawed,
   # but the proper solution is rather time-consuming.
   -- allow environment with no dependencies
   local tAutoFormat
   put __GetPreference("editor,autoformat", true) into tAutoFormat
   
   if tAutoFormat then
      scriptFormat "handler", true
   end if
   textEndGroup
   
   unlock screen
end scriptUncomment

# Parameters
#   pOption : one of three possible strings, see below for details.
#   pValue : depends on pOption, details below.
# Description
#   Colorizes the current script. pOption is one of the following options.
#     "script" - colorize the whole script (default). pValue is ignored.
#     "line" - colorize a particular line, pValue is the line number
#     "handler" - colorize a particular handler, pValue is the handler name. Currently not implemented.
command scriptColorize pOption, pValue
   if pOption is "script" then
      _internal script colorize char 1 to (the number of chars of field "Script" of me) of field "Script" of me
   else if pOption is "line" then
      _internal script colorize line pValue to pValue of field "Script" of me
   end if
end scriptColorize

# Parameters
#   pScope : either "script" or "handler"
# Description
#   Formats the current script according to the pScope parameter. If pScope is "script", then
#   entire script is formatted. If pScope is handler, then the current handler is formatted.
#   Note, formatting the whole script could be quite slow.
command scriptFormat pScope, pDontGroup
   lock screen
   local tScroll
   put the vScroll of field "Script" of me into tScroll
   
   local tStart, tEnd
   get the selectedChunk
   put word 2 of it into tStart
   put word 4 of it into tEnd
   
   if pScope is "script" then
      local tStartChar
      put 1 into tStartChar
      
      local tOldText
      put the text of field "Script" of me into tOldText
      
      local tFirstLine, tLastLine, tCharsAboveFirstLineOld, tCharsAboveLastLineOld
      get the selectedLine
      put word 2 of it into tFirstLine
      if word 4 of it is a number then put word 4 of it into tLastLine else put tFirstLine into tLastLine
      
      put the number of chars of line 1 to tFirstLine of tOldText into tCharsAboveFirstLineOld
      if tFirstLine is tLastLine then
         put tCharsAboveFirstLineOld into tCharsAboveLastLineOld
      else
         put the number of chars of line 1 to tLastLine of tOldText into tCharsAboveLastLineOld
      end if
      
      local tNewText
      put textFormatSelection(tOldText) into tNewText
      
      local tCharsAboveFirstLineNew, tCharsAboveLastLineNew, tDiffFirstLine, tDiffLastLine
      put the number of chars of line 1 to tFirstLine of tNewText into tCharsAboveFirstLineNew
      if tFirstLine is tLastLine then
         put tCharsAboveFirstLineNew into tCharsAboveLastLineNew
      else
         put the number of chars of line 1 to tLastLine of tNewText into tCharsAboveLastLineNew
      end if
      
      put tCharsAboveFirstLineOld - tCharsAboveFirstLineNew into tDiffFirstLine
      put tCharsAboveLastLineOld - tCharsAboveLastLineNew into tDiffLastLine
      
      local tFirstLineChar
      put (the number of chars of line 1 to tFirstLine - 1 of tNewText) + 1 into tFirstLineChar
      
      textReplace tStartChar, tOldText, tNewText, empty, pDontGroup
      
      if tStart is not empty then
         subtract tDiffFirstLine from tStart
         put max(tStart, tFirstLineChar) into tStart # dont let selection go into previous line
         subtract tDiffLastLine from tEnd
         select char tStart to tEnd of field "Script" of me
      end if
      
   else # handler only
      local tLine
      put word 2 of the selectedLine into tLine
      
      local tScript
      put the text of the selectedField into tScript
      
      local tSelectionLineCount
      put the number of lines of char tStart to tEnd of tScript into tSelectionLineCount
      
      # Before doing the formatting, save the indent of the first and last line of the selection.
      # Once the formatting is done, we can compare this with the new indents in order to adjust the selection.
      local tOldFirstIndent
      put textFormatGetLineIndent(line tLine of tScript) into tOldFirstIndent
      
      local tOldLastIndent
      if tStart > tEnd then
         put tOldFirstIndent into tOldLastIndent
      else
         put textFormatGetLineIndent(line (tLine + tSelectionLineCount - 1) of tScript) into tOldLastIndent
      end if
      
      local tCode
      put textFormat(tLine, tSelectionLineCount, tScript) into tCode
      textReplace tCode["startchar"], tCode["oldtext"], tCode["newtext"], empty, pDontGroup
      
      local tNewScript
      put the text of field "Script" of me into tNewScript
      
      # We know that formatting cannot change the number of lines of the field, so we can assume that
      # tLine will still be corrrect. (tStart and tEnd now no longer point to meaningful chars in the new script.)
      local tNewFirstIndent
      put textFormatGetLineIndent(line tLine of tNewScript) into tNewFirstIndent
      
      local tNewLastIndent
      if tStart > tEnd then
         put tNewFirstIndent into tNewLastIndent
      else
         # Note that we use the line count from the original selection, as we know this is correct, rather than calculating
         # it again for the new selection.
         put textFormatGetLineIndent(line (tLine + tSelectionLineCount) of tNewScript) into tNewLastIndent
      end if
      
      # The selection offsets are composed of two parts, the difference in the indent of the line that the selection started / ended on
      # and the difference in the number of chars before that line.
      local tFirstSelectionOffset
      put (the number of chars of line 1 to tLine of tNewScript - the number of chars of line 1 to tLine of tScript) into tFirstSelectionOffset      
      
      put (the number of chars of line 1 to tLine - 1 of tNewScript) + 2 into tFirstLineChar
      if tLine is 1 then subtract 1 from tFirstLineChar
      
      local tLastSelectionOffset
      if tStart > tEnd then
         put tFirstSelectionOffset into tLastSelectionOffset
      else
         put(the number of chars of line 1 to (tLine + (tSelectionLineCount - 1)) of tNewScript - the number of chars of line 1 to (tLine + (tSelectionLineCount - 1)) of tScript) into tLastSelectionOffset      end if
      
      if tStart is not empty then
         if tStart > tEnd then
            select char (tStart + tFirstSelectionOffset ) to (tEnd + tFirstSelectionOffset ) of field "Script" of me
         else
            put tStart + tFirstSelectionOffset into tStart
            if tStart < tFirstLineChar + (the number of chars of tNewFirstIndent) then 
               put tFirstLineChar + (the number of chars of tNewFirstIndent) into tStart
            end if
            select char (tStart) to (tEnd + tLastSelectionOffset) of field "Script" of me
         end if
      end if
   end if
   
   set the vScroll of field "Script" of me to tScroll
   unlock screen
end scriptFormat

# Description
#   Returns the number of the selected line in the current script
command getSelectedLine
   return word 2 of the selectedLine
end getSelectedLine


# Parameters
#   pObject : the object to get the script of. Must be one of the current target objects
# Description
#   If pObject is not specified then returns the current script in the editor group,
#   otherwise returns the script of the specified object in the state it was last left in
#   by the user. I.e. if the script is not applied, the edited one is returned.
command scriptGet pObject
   if pObject is empty or revRuggedId(pObject) is revRuggedId(sObjectID) then
      return textGetScript()
   end if
   
   # If not the current script, we need to retrieve the script from a cache, as it
   # is no longer in the field.
   local tCachedScript
   put sScriptCache[revRuggedId(pObject)] into tCachedScript
   if tCachedScript is empty and exists(pObject) then
      return the script of pObject
   else
      return tCachedScript
   end if
end scriptGet

command scriptGetCache pObject
   return sScriptCache[revRuggedId(pObject)]
end scriptGetCache

command cacheScript pObject, pScript
   if exists(pObject) then
      put pScript into sScriptCache[revRuggedId(pObject)]
   end if
end cacheScript

# Description
#   Returns the number of lines of the current script
command scriptGetLineCount
   return the number of lines of field "Script" of me
end scriptGetLineCount

# Description
#   This command returns the current script as *real* html. The result of this command
#   is suitable for displaying in a browser, not in Revolution fields as htmlText. This command
#   requires the colorization scheme "Revolution Classic" to be used as it contains hard-coded 
#   replacements. For html suitable for printing or displaying in a Revolution field see scriptGetHtmlText.
command scriptGetAsHtml
   local tOldScript
   put the text of field "Script" of me into tOldScript
   
   # First wrap the script to the required width, this is a total hack as doing it properly would take quite a while.
   local tScript
   put tOldScript into tScript
   
   local tMaxCharCount
   put "65" into tMaxCharCount
   
   local tWrappedScript
   repeat for each line tLine in tScript
      # Ignore lines that don't need to be wrapped
      if the number of chars of tLine <= tMaxCharCount then
         put tLine & return after tWrappedScript
         next repeat
      end if
      
      # Find the word offset to wrap from. Only whole words can be wrapped
      local tWordOffset
      put (the number of words of char 1 to tMaxCharCount of tLine)  -1 into tWordOffset
      
      # The line could be a comment, in which case we need to find which comment char its using
      # wrap the line, and put the comment char in front of the wrapped part. This won't work with
      # multi-line comments etc.
      local tCommentChar
      if token 1 of tLine is empty then
         local tOffset
         put offset("#", tLine) into tOffset
         if tOffset = 0 then
            put offset("--", tLine) into tOffset
            put "--" into tCommentChar
         else
            put "#" into tCommentChar
         end if
         
         if tCommentChar is empty then
            put word 1 to tWordOffset of tLine & return & word tWordOffset + 1 to -1 of tLine & return after tWrappedScript
         else
            put word 1 to tWordOffset of tLine & return & tCommentChar & space & word tWordOffset + 1 to -1 of tLine & return after tWrappedScript
         end if
         next repeat
      end if
      
      # The line was not a comment. In this case we just wrap it with a continuation char
      # This of course may have issues if the line already has a continuation char, is inside a nested comment etc.
      if token 1 of tLine is not empty then
         put word 1 to tWordOffset of tLine & " \" & return & word tWordOffset + 1 to -1 of tLine & return after tWrappedScript
         next repeat
      end if
   end repeat
   delete the last char of tWrappedScript
   
   textReplace 1, tOldScript, tWrappedScript
   scriptFormat "script"
   
   local tHtml
   put the htmlText of field "Script" of me into tHtml
   
   local tNewHtml
   put "<div class=" & quote & "code" & quote & ">" & return into tNewHtml
   put "<pre>" & return after tNewHtml
   
   local tBody
   put tHtml into tBody
   replace "<p>" with empty in tBody
   replace "</p>" with empty in tBody
   
   replace "<font color=" & quote & "#000000" & quote & ">" with "<span class=" & quote & "normal" & quote & ">" in tBody
   replace "<font color=" & quote & "#0000FF" & quote & ">" with "<span class=" & quote & "command" & quote & ">" in tBody
   replace "<font color=" & quote & "#FF0000" & quote & ">" with "<span class=" & quote & "property" & quote & ">" in tBody
   replace "<font color=" & quote & "#68228B" & quote & ">" with "<span class=" & quote & "comment" & quote & ">" in tBody
   replace "<font color=" & quote & "#F88017" & quote & ">" with "<span class=" & quote & "function" & quote & ">" in tBody
   replace "<font color=" & quote & "#980517" & quote & ">" with "<span class=" & quote & "keyword" & quote & ">" in tBody
   replace "</font>" with "</span>" in tBody
   put tBody & return after tNewHtml
   
   put "</pre>" & return after tNewHtml
   put "</div>" after tNewHtml
   
   
   # Restore the original script
   textReplace 1, the text of field "Script" of me, tOldScript
   
   return tNewHtml
end scriptGetAsHtml

# Description
#   Returns the htmlText of the script field. This is suitable for printing, or displaying
#   in another Revolution field, not for putting on the net. For real html, see scriptGetAsHtml.
command scriptGetHtmlText
   return the htmlText of field "Script" of me
end scriptGetHtmlText

# Description
#   Returns the long id of the script field. This is required by the Revolution printing library,
#   the field ID is used to determine the properties require to make the printout look correct.
#   Please *do not* use this command to directly access the script field, doing so will break the 
#   script editor completely.
command scriptGetField
   return the long id of field "Script" of me
end scriptGetField

# Description
#   Returns the name of the current handler. This is the handler that the caret
#   is inside in edit mode, or that the current statement to execute is in in
#   debug mode.
command scriptGetCurrentHandler
   # Waiting for engine support for this function...
end scriptGetCurrentHandler


private command __BracketCompletion pOffset, @xOldText, @xNewText
   local tBracketCompletion
   put __GetPreference("editor,bracketcompletion", true) into tBracketCompletion
   if tBracketCompletion is not true then
      return empty for value
   end if
   
   if the length of xNewText is not 1 then
      return empty for value
   end if
   
   local tNextChar
   put char pOffset of field "script" of me into tNextChar
   
   local tCompletionChar
   switch xNewText
      case quote
         if tNextChar is not quote then
            put quote into tCompletionChar
         end if
         break
      case "["
         put "]" into tCompletionChar
         break
      case "("
         put ")" into tCompletionChar
         break
   end switch
   
   if tCompletionChar is not empty then
      if xOldText is empty then
         put tCompletionChar after xNewText
         return "pair" for value
      else
         put xOldText & tCompletionChar after xNewText
         return "wrap" for value
      end if
   else if xOldText is empty then
      if xNewText is in quote & "])" and \
            xNewText is tNextChar then
         put xNewText into xOldText
      end if
   end if
   return empty for value
end __BracketCompletion

local sHighlightedBrackets

private command __ClearHighlights
   if sHighlightedBrackets["open"] is not empty then
      set the backgroundColor of char sHighlightedBrackets["open"] of field "script" of me to empty
      set the backgroundColor of char sHighlightedBrackets["close"] of field "script" of me to empty
      delete variable sHighlightedBrackets
   end if
end __ClearHighlights

private command __CheckHighlights
   lock screen
   __ClearHighlights
   
   local tBracketHighlighting
   put __GetPreference("editor,brackethighlighting", true) into tBracketHighlighting
   
   if not tBracketHighlighting then
      exit __CheckHighlights
   end if
   
   local tChunk
   put the selectedChunk into tChunk
   if word 4 of tChunk < word 2 of tChunk then
      local tChar, tCharNum
      put word 2 of tChunk into tCharNum
      put char tCharNum of field "script" of me into tChar
      if tChar is in "([])" then
         __HighlightBrackets tCharNum, tChar
      else
         put word 4 of tChunk into tCharNum
         put char tCharNum of field "script" of me into tChar
         if tChar is in "([])" then
            __HighlightBrackets tCharNum, tChar
         end if
      end if
   end if
   
   unlock screen
end __CheckHighlights

private command __HighlightBrackets pCharNum, pChar
   local tMatchedCharNum
   put pCharNum into tMatchedCharNum
   switch pChar
      case "["
         __LookForPair "]", "[", 1, tMatchedCharNum
         break
      case "("
         __LookForPair  ")", "(", 1, tMatchedCharNum
         break
      case "]"
         __LookForPair "[", "]", -1, tMatchedCharNum
         break
      case ")"
         __LookForPair "(",")", -1, tMatchedCharNum
         break
   end switch
   
   if it and pCharNum is not tMatchedCharNum then
      local tColor
      put __GetPreference("editor,brackethighlightcolor", "255,200,200") into tColor
      
      put pCharNum into sHighlightedBrackets["open"]
      set the backgroundColor of char pCharNum of field "script" of me to tColor
      put tMatchedCharNum into sHighlightedBrackets["close"]
      set the backgroundColor of char tMatchedCharNum of field "script" of me to tColor
   end if
end __HighlightBrackets

private command __LookForPair pChar, pPairChar, pStep, @xCharNum
   local tBracketCount = 0
   local tEndCondition
   
   local tScript
   local tScriptLine
   local tCharNum
   local tIndex
   if pStep < 0 then
      put 1 into tEndCondition
      put char 1 to xCharNum of field "script" of me into tScript
      split tScript by return
      put tScript[the number of elements of tScript] into tScriptLine
      
      repeat with tIndex = the number of elements in tScript-1 down to 1
         if lineIsContinued(tScript[tIndex]) then
            put tScript[tIndex] & return before tScriptLine
         else
            exit repeat
         end if
      end repeat
      
      put the length of tScriptLine into tCharNum
   else
      put char xCharNum+1 to -1 of field "script" of me into tScript
      split tScript by return
      put tScript[1] into tScriptLine
      
      repeat with tIndex = 1 to the number of elements in tScript
         if lineIsContinued(tScript[tIndex]) then
            put return & tScript[tIndex+1] after tScriptLine
         else
            exit repeat
         end if
      end repeat
      
      put the length of tScriptLine into tEndCondition
      put 0 into tCharNum
   end if
   
   if tScriptLine is empty or tCharNum is tEndCondition then
      return false for value
   end if
   
   repeat
      add pStep to tCharNum
      add pStep to xCharNum
      local tChar
      put codepoint tCharNum of tScriptLine into tChar
      switch
         case tChar is pChar and tBracketCount is 0
            return true for value
            break
         case tChar is pPairChar
            add 1 to tBracketCount
            break
         case tChar is pChar
            subtract 1 from tBracketCount
            break
      end switch
      
      if tCharNum is tEndCondition then
         return false for value
      end if
   end repeat
end __LookForPair


-- autocompletion

private command __UpdateAutoCompleteList pUUID
   local tProviderCompletion
   put __GetPreference("editor,providercompletion", true) into tProviderCompletion
   if tProviderCompletion and revEnvironmentEditionProperty("autocomplete") then
      ideAutocompleteUpdate the long id of me, sObjectID, sPlaceholders[pUUID]["classes"]
   end if
end __UpdateAutoCompleteList

-- placeholders

private command __ClearCurrentPlaceholder pForce
   if not pForce then
      if the selectedField is empty or \
            the long id of the selectedField is not the long id of field "script" of me then
         exit __ClearCurrentPlaceholder
      end if
      local tChunk
      put the selectedChunk into tChunk
      if exists(tChunk) then
         local tUUID
         put the metadata of tChunk into tUUID
         if tUUID is sEditPlaceholder then
            exit __ClearCurrentPlaceholder
         end if
      end if
   end if
   
   delete variable sPlaceholders[sEditPlaceholder]
   
   if the number of elements of sEditChunks > 0 then
      repeat for each element tChunk in sEditChunks
         set the metadata of char tChunk["start"] to tChunk["end"] of field "script" of me to empty
         set the backgroundColor of char tChunk["start"] to tChunk["end"] of field "script" of me to empty
      end repeat
      delete variable sEditChunks
   end if
   delete variable sEditPlaceholder
end __ClearCurrentPlaceholder

private command __SelectPlaceholder pUUID, pFromParagraph, pToParagraph, pStyledText
   if pFromParagraph is empty then
      put 1 into pFromParagraph
   end if
   
   if pToParagraph is empty then
      put -1 into pToParagraph
   end if
   
   local tUUID, tChunk
   put the selectedChunk into tChunk
   if exists(tChunk) then
      put the metadata of tChunk into tUUID
   end if
   
   local tOffset
   put the number of chars of line 1 to pFromParagraph-1 of field "script" of me into tOffset
   if pFromParagraph is not 1 then
      add 1 to tOffset
   end if
   
   if pStyledText is empty then
      put the styledText of line pFromParagraph to pToParagraph of field "script" of me into pStyledText
   end if
   
   local tScroll
   put the vScroll of field "script" of me into tScroll["v"]
   put the hScroll of field "script" of me into tScroll["h"]
   lock screen
   
   delete variable sEditChunks
   put pUUID into sEditPlaceholder
   
   local tColor
   put __GetPreference("editor,placeholdercolor", kPlaceholderDefaultBackgroundColor) into tColor
  
   local tParagraphIndex
   repeat with tParagraphIndex = 1 to the number of elements of pStyledText
      local tRunIndex
      repeat with tRunIndex = 1 to the number of elements of pStyledText[tParagraphIndex]["runs"]
         if pUUID is pStyledText[tParagraphIndex]["runs"][tRunIndex]["metadata"]  then
            put the effective hiliteColor of field "Script" of me \
                  into pStyledText[tParagraphIndex]["runs"][tRunIndex]["style"]["backgroundColor"]
            local tPlaceholderNum
            put the number of elements of sEditChunks + 1 into tPlaceholderNum
            put tOffset+1 into sEditChunks[tPlaceholderNum]["start"]
            put tOffset+the length of pStyledText[tParagraphIndex]["runs"][tRunIndex]["text"] into sEditChunks[tPlaceholderNum]["end"]
         else if pStyledText[tParagraphIndex]["runs"][tRunIndex]["metadata"] is not empty then
            if pStyledText[tParagraphIndex]["runs"][tRunIndex]["text"] is space or \
                  pStyledText[tParagraphIndex]["runs"][tRunIndex]["metadata"] is tUUID then
               delete variable sPlaceholders[pStyledText[tParagraphIndex]["runs"][tRunIndex]["metadata"]]
               delete variable pStyledText[tParagraphIndex]["runs"][tRunIndex]["metadata"]
               delete variable pStyledText[tParagraphIndex]["runs"][tRunIndex]["style"]["backgroundColor"]
            else
               put tColor into pStyledText[tParagraphIndex]["runs"][tRunIndex]["style"]["backgroundColor"]
            end if
         end if
         add the length of pStyledText[tParagraphIndex]["runs"][tRunIndex]["text"] to tOffset
      end repeat
      add 1 to tOffset
   end repeat
   
   set the styledText of line pFromParagraph to pToParagraph of field "script" of me to pStyledText
   set the vScroll of field "script" of me to tScroll["v"]
   set the hScroll of field "script" of me to tScroll["h"]
   
   if the number of elements of sEditChunks > 0 then
      -- select the first chunk
      select char sEditChunks[1]["start"] to sEditChunks[1]["end"] of field "script" of me
   else if exists(tChunk) then
      select tChunk
   end if
end __SelectPlaceholder

command SelectNextPlaceholder pChar, pFromParagraph, pToParagraph
   local tStyle
   
   local tPlaceholdersToDelete
   
   put the styledText of line pFromParagraph to pToParagraph of field "script" of me into tStyle
   local tParagraphIndex
   repeat with tParagraphIndex = 1 to the number of elements of tStyle
      local tRunOffset
      put 0 into tRunOffset
      local tRunIndex
      repeat with tRunIndex = 1 to the number of elements of tStyle[tParagraphIndex]["runs"]
         if tParagraphIndex > 1 or (tParagraphIndex is 1 and (tRunOffset + 1) >= pChar) then
            if tStyle[tParagraphIndex]["runs"][tRunIndex]["metadata"] is not empty and \
                  tStyle[tParagraphIndex]["runs"][tRunIndex]["metadata"] is not sEditPlaceholder then
               if tStyle[tParagraphIndex]["runs"][tRunIndex]["text"] is not space then
                  __SelectPlaceholder \
                        tStyle[tParagraphIndex]["runs"][tRunIndex]["metadata"], \
                        pFromParagraph, \
                        pToParagraph, \
                        tStyle
                  selectionUpdate
                  return true
               else
                  get the number of elements of tPlaceholdersToDelete
                  put tRunOffset + 1,pFromParagraph + tParagraphIndex - 1 into \
                        tPlaceholdersToDelete[it + 1]
               end if
            end if
         end if
         add the length of tStyle[tParagraphIndex]["runs"][tRunIndex]["text"] to tRunOffset
      end repeat
   end repeat
   
   repeat for each key tUUID in tPlaceholdersToDelete
      repeat for each element tRange in tPlaceholdersToDelete[tUUID]
         set the metadata of char (item 1 of tRange) of line (item 2 of tRange) of field "script" of me to empty
         set the backgroundColor of char (item 1 of tRange) of line (item 2 of tRange) of field "script" of me to empty
      end repeat
      delete variable sPlaceholders[tUUID]
   end repeat
   
   -- if we get here we thought there were placeholders and there weren't
   -- so select after the line and clear the placeholder variable
   select after line pFromParagraph of field "script" of me
   selectionUpdate
   
   return false
end SelectNextPlaceholder
