script "revMessageBoxMultipleLinesMessageBehavior"
local lHistory, lHistoryIndex, lNumInHistory, lMatchingHistory, lNumMatching, lMatchingIndex

on enterInField
   ideMessageBoxExecuteScript(the text of me)
   if the result is not empty then
      put the result into me
      local tMessage
      put the text of me into tMessage
      replace return with "\n" in tMessage
      revIDEConsoleHistoryAdd(tMessage)
   end if
   revInitialise
   select the text of me
end enterInField

on returnInField
   if (the controlKey is down) then 
      enterInField
   else
      pass returnInField
   end if
end returnInField

on commandKeyDown pKey
   if pKey is "U" then 
      put empty into me
      exit commandKeyDown
   end if
   if pKey is "V" then 
      put clipboardData["text"] into the selectedChunk
      scriptFormat "script"
   else
      pass commandKeyDown
   end if
end commandKeyDown

on arrowKey which
  if the altKey is down then
    if which is "down" then revPrevLine
    if which is "up" then revNextLine
  end if
  pass arrowKey
end arrowKey

command revInitialise
   textInitialize
   
   local tInHistory, tLine
   
   put revIDEGetPreference("IDEMultipleLinesMessageHistory") into lHistory
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
   scriptFormat "script"
end revInitialise

command revNextLine
   local tMessage
   add 1 to lHistoryIndex
   if lHistoryIndex > lNumInHistory then put 1 into lHistoryIndex
   put line lHistoryIndex of lHistory into tMessage
   replace "\n" with return in tMessage
   set the text of me to tMessage
   scriptFormat "script"
end revNextLine

command revPrevLine
   local tMessage
   add -1 to lHistoryIndex
   if lHistoryIndex < 1 then put lNumInHistory into lHistoryIndex
   put line lHistoryIndex of lHistory into tMessage
   replace "\n" with return in tMessage
   set the text of me to tMessage
   scriptFormat "script"
end revPrevLine
