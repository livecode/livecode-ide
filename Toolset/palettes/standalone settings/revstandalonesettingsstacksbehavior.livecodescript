script "revStandaloneSettingsStacksBehavior"
on preOpenCard
   lock messages
   
   local tEnabled, tPlatform
   put canIncludeStackFiles() into tEnabled
   set the enabled of group "Basic Options" to tEnabled
   set the enabled of group "Advanced Options" to tEnabled
   
   -- Disable the stack encryption options in Community edition
   put (tEnabled and revEnvironmentEditionProperty("password_protection")) into tEnabled
   set the enabled of button "encrypt" to tEnabled
   set the enabled of field "encrypt" to tEnabled
   
   local tStackFiles
   revSBRelativeStackFilesList the cRevTargetStack of this stack, tStackFiles
   put tStackFiles["relative"] into field "stackfiles"
   set the cStackPaths of field "stackfiles" to tStackFiles["full"]
   set the hilitedLines of field "stackfiles" to 1
   send "mouseUp" to field "stackfiles"
   unlock messages
   pass preOpenCard
end preOpenCard

on revIncludeStackFiles pIncludeList
   local tPrev, tStackFiles
   put the cStackPaths of field "stackfiles" into tPrev
   put updateIncludeStackFilesList(pIncludeList, tPrev) into tStackFiles
   put tStackFiles["relative"] into field "stackfiles"
   set the cStackPaths of field "stackfiles" to tStackFiles["full"]
   set the hilitedLines of field "stackfiles" to min(2,the number of lines of tStackFiles["relative"])
   send "mouseUp" to field "stackfiles"
   revSetEdit
end revIncludeStackFiles

local sStackFileList

on revRemoveStackFiles pRemoveList
   put "" into sStackFileList
   repeat for each line tStackFile in the cStackPaths of field "stackFiles"
      revRecursiveRemoveStackFiles tStackFile,pRemoveList,sStackFileList
   end repeat
   preOpenCard
end revRemoveStackFiles

-- Updates the controls on this card to reflect the values set on the target stack.
command updateCard
   local tSettings,tLines,tStackFiles,tHilitedFiles,tItem,tFirstStack
   put the hilitedStackFiles of field "stackfiles" of me into tHilitedFiles
   put the long id of stack line 1 of tHilitedFiles into tFirstStack
   put the cRevStandaloneSettings["moveSubstacks"] of tFirstStack into tSettings["moveSubstacks"]
   put the cRevStandaloneSettings["renameGeneric"] of tFirstStack into tSettings["renameGeneric"]
   put the cRevStandaloneSettings["substackFolder"] of tFirstStack into tSettings["substackFolder"]
   repeat for each line tLine in (line 2 to -1 of tHilitedFiles)
      if the cRevStandaloneSettings["moveSubstacks"] of stack tLine <> tSettings["moveSubstacks"] then 
         put false into tSettings["moveSubstacks"]
      end if
      if the cRevStandaloneSettings["renameGeneric"] of stack tLine <> tSettings["renameGeneric"] then 
         put false into tSettings["renameGeneric"]
      end if
      if the cRevStandaloneSettings["substackFolder"] of stack tLine <> tSettings["substackFolder"] then 
         put "" into tSettings["substackFolder"]
      end if
   end repeat
   if the number of lines in tHilitedFiles is not 1 then
      put empty into field "stacks"
      disable group "selectedStack"
   else
      local tStacks
      put the short name of tFirstStack &cr &the substacks of tFirstStack into tStacks
      if char -1 of tStacks is cr then delete char -1 of tStacks
      put tStacks into field "stacks"
      set the textStyle of line 1 of field "stacks" to "bold"
      enable group "selectedStack"
      set the hilitedLines of field "stacks" to 1
      send "mouseUp" to field "stacks"
   end if
   set the hilite of button "moveSubstacks" to (tSettings["moveSubstacks"] = true)
   set the hilite of button "renameFiles" to (tSettings["renameGeneric"] = true)
   set the hilite of button "Data stacks directory" to (tSettings["substackFolder"] <> "")
   put tSettings["substackFolder"] into field "substackFolder"
   set the enabled of group "moveSubstacks" to (tSettings["moveSubstacks"] = true)
end updateCard
