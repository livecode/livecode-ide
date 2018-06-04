script "revMessageBoxSingleLineMessageBehavior"
local lHistory, lHistoryIndex, lNumInHistory, lMatchingHistory, lNumMatching, lMatchingIndex

on returnInField
   ideMessageBoxExecuteScript(the text of me)
   if the result is not empty then
      put the result into me
      dispatch "revSEColorizeField" to stack "revSEUtilities" with the long id of me
      revIDEConsoleHistoryAdd(the text of me)
   end if
   revInitialise
   
   # It's possible to close the message box or change the card while 
   # the above is executing, so ensure the field is still open before 
   # selecting its text
   if revIDEObjectIsOpen(the long id of me) then
      select the text of me
   end if
end returnInField

on enterInField
   returnInField
end enterInField

local sColorizeMsg

on textChanged
   cancel sColorizeMsg
   get the long id of me
   send "revSEColorizeField it" to stack "revSEUtilities" in 100 milliseconds
   put the result into sColorizeMsg
   revDisplayAutoComplete(the text of me)
end textChanged

on arrowKey pKey
   if pKey is "up" then 
      revNextLine
   else if pKey is "down" then 
      revPrevLine
   else if pKey is "right" and field "auto complete" is not empty  then 
      revIDEAcceptAutoComplete
   else 
      pass arrowKey
   end if
end arrowKey

on commandKeyDown pKey
   if pKey is "P" and the platform is not "MacOS" then revPrevLine
   if pKey is "N" and the platform is not "MacOS" then revNextLine
   if pKey is "U" then 
      put empty into me
      put empty into field "auto complete"
      exit commandKeyDown
   end if
   if pKey is "V" then
      put clipboardData["text"] into the selectedChunk
      revDisplayAutoComplete clipboardData["text"]
      dispatch "revSEColorizeField" to stack "revSEUtilities" with the long id of me
   else
      pass commandKeyDown
   end if
end commandKeyDown

command revInitialise
   set the textStyle of me to empty
   
   local tLine, tInHistory
   
   put revIDEGetPreference("IDESingleLineMessageHistory") into lHistory
   put number of lines of lHistory into lNumInHistory
   if the text of me is not empty then
      repeat for each line tLine in lHistory
         if tLine is the text of me then 
            put "yes" into tInHistory
            exit repeat
         end if 
      end repeat
      if tInHistory is "yes"
      then put 1 into lHistoryIndex
      else put 0 into lHistoryIndex
   else
      put 0 into lHistoryIndex
   end if
end revInitialise

local sColorizeAutocompleteMsg

command revDisplayAutoComplete pString
   lock screen
   local tString
   put revIDEAutoComplete(pString) into tString
   
   if tString is not empty then 
      put tString into lMatchingHistory
      put the number of lines in lMatchingHistory into lNumMatching
      put 1 into lMatchingIndex
      get field "message" & char (the number of chars of field "message" +1) to (the number of chars of line 1 of lMatchingHistory) of  line 1 of lMatchingHistory
      if it is the text of field "auto complete" then
         unlock screen
         return empty
      end if
      put it into field "auto complete"
      set the hscroll of field "auto complete" to the hscroll of field "message"
   else 
      put empty into field "auto complete"
   end if
   cancel sColorizeAutocompleteMsg
   send "__ColorizeAutocomplete" to me in 100 milliseconds
   put the result into sColorizeAutocompleteMsg
   unlock screen
end revDisplayAutoComplete

on __ColorizeAutocomplete
   dispatch "revSEColorizeField" to stack "revSEUtilities" with the long id of field "auto complete"
   set the textColor of char 1 to -1 of field "auto complete" to "gray70"
end __ColorizeAutocomplete

command revNextLine
   lock messages
   if field "auto complete" is empty then
      add 1 to lHistoryIndex
      if lHistoryIndex > lNumInHistory then put 1 into lHistoryIndex
      put line lHistoryIndex of lHistory into field "message"
   else
      add 1 to lMatchingIndex
      if lMatchingIndex > lNumMatching then put 1 into lMatchingIndex
      put field "message" & char (the number of chars of field "message" + 1) to (the number of chars of line lMatchingIndex of lMatchingHistory) of line lMatchingIndex of lMatchingHistory into field "auto complete"
   end if
   select after field "message" 
    _internal script colorize char 1 to (the number of chars of me) of me
   unlock messages
end revNextLine

command revPrevLine
   lock messages
   if field "auto complete" is empty then
      add -1 to lHistoryIndex
      if lHistoryIndex < 1 then put lNumInHistory into lHistoryIndex
      put line lHistoryIndex of lHistory into field "message"
   else
      add -1 to lMatchingIndex
      if lMatchingIndex < 1 then put lNumMatching into lMatchingIndex
      put field "message" & char (the number of chars of field "message" + 1) to (the number of chars of line lMatchingIndex of lMatchingHistory) of line lMatchingIndex of lMatchingHistory into field "auto complete"
   end if
   select after field "message" 
    _internal script colorize char 1 to (the number of chars of me) of me
   unlock messages
end revPrevLine

on closeField
   put empty into field "auto complete"
end closeField

on exitField
   put empty into field "auto complete"
end exitField
