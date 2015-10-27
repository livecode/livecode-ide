script "revMessageBoxSingleLineMessageBehavior"
local lHistory, lHistoryIndex, lNumInHistory, lMatchingHistory, lNumMatching, lMatchingIndex

on returnInField
   revIDEExecuteScript(the text of me)
   if the result is not empty then
      put the result into me
   end if
   
   revIDEConsoleHistoryAdd(the text of me)
   revInitialise
   
   select the text of me
end returnInField

on enterInField
   returnInField
end enterInField

on textChanged
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
   if pKey is "V" then get clipboardData["text"] 
   pass commandKeyDown
end commandKeyDown

command revInitialise
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

command revDisplayAutoComplete pString
   set the textColor of field "auto complete" to "gray70"
   if pString is not empty then 
      put  revIDEAutoComplete(pString) into lMatchingHistory
      put the number of lines in lMatchingHistory into lNumMatching
      put 1 into lMatchingIndex
      put field "message" & char (the number of chars of field "message" +1) to (the number of chars of line 1 of lMatchingHistory) of  line 1 of lMatchingHistory into field "auto complete"
      set the hscroll of field "auto complete" to the hscroll of field "message"
   else 
      put empty into field "auto complete"
   end if
end revDisplayAutoComplete

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
   unlock messages
end revPrevLine

on closeField
   put empty into field "auto complete"
end closeField

on exitField
   put empty into field "auto complete"
end exitField
