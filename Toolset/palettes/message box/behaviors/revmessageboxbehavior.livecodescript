script "revMessageBoxBehavior"
##GH created 12/11/2014
##GH last updated 31/12/2014

local lSelectedCard, lCardHistoryPref
constant kHistoryMax = 200
constant kHalfMessageFieldHeight = 12.5
constant kExternalErrorCode = 0

local sLastMsg

on setAsBehavior pTarget
   set the behavior of pTarget to the long id of this me
   setBehaviors
end setAsBehavior

on setBehaviors
   dispatch "setAsBehavior" to revIDEFrameBehavior() with the long id of this me
end setBehaviors

on openStack   
   lock screen
   lock messages
   --set the zoomBox of this stack to false
   unlock messages
   clearFrameData
   
   ##GH : the labels will need localising
   #Navigation
   --frame item: Name                     Location   Type            Label                       Icon      Icon     Callback Message  Callback Target   Parameter
   addFrameItem "single line",             "header",  "navigation",   "Single Line",             "minus",  "minus",  "showCard",            the long id of me,  "Single Line"
   addFrameItem "multiple lines",        "header",  "navigation",   "Multiple Lines",        "reorder",   "reorder",   "showCard",           the long id of me,  "Multiple Lines"
   addFrameItem "global properties",   "header",  "navigation",   "Global Properties",   "file powerpoint alt",   "file powerpoint alt",  "showCard",            the long id of me,  "Global Properties"
   addFrameItem "global variables",     "header",  "navigation",   "Global Variables",     "file excel alt",   "file excel alt",  "showCard",            the long id of me,  "Global Variables"
   addFrameItem "pending messages", "header",  "navigation",  "Pending Messages", "envelope alt",   "envelope alt",  "showCard",            the long id of me,  "Pending Messages"
   addFrameItem "front scripts",           "header",  "navigation",  "Front Scripts",          "file",   "file",  "showCard",            the long id of me,  "Front Scripts"
   addFrameItem "back scripts",           "header",  "navigation",  "Back Scripts",           "paste",    "paste",  "showCard",            the long id of me,  "Back Scripts"
   addFrameItem "stacks in use",          "header",  "navigation",  "Stacks in Use",         "files alt",    "files alt",  "showCard",            the long id of me,  "Stacks in Use"
   
   #Actions - footers
   --frame item: Name                        Location   Type          Label                                  Icon         Icon     Callback Message      Callback Target
   addFrameItem "outputSource",          "footer",     "action",      "Show last output source",    "bullseye",     "bullseye",    "showOutputSource",the long id of me
   addFrameItem "lockDefaultStack",     "footer",     "action",      "Lock the defaultStack",         "unlock alt",     "unlock alt",    "lockDefaultStack",    the long id of me
   addFrameItem "unlockDefaultStack", "footer",     "action",      "Unlock the defaultStack",     "lock",     "lock",    "unlockDefaultStack",the long id of me
   addFrameItem "removeSelected",       "footer",     "action",     "Remove selected variable",    "trash",    "trash",     "removeSelected",     the long id of me
   addFrameItem "removeAll",               "footer",     "action",      "Remove all",                         "trash",     "trash",    "removeAll",              the long id of me
   addFrameItem "newGlobalVariable",  "footer",     "action",      "New global variable",            "file alt",    "file alt",    "addGlobalVariable",  the long id of me
   addFrameItem "update",                    "footer",     "action",      "Update pending messages", "refresh",    "refresh",    "updateMessages",     the long id of me
   addFrameItem "cancelAll",                 "footer",     "action",      "Cancel all messages",           "remove",    "remove",    "cancelAllMessages",  the long id of me
   addFrameItem "addStack",                 "footer",     "action",      "Add library stack",                "plus",    "plus",    "addLibraryStack",      the long id of me
   
   --GH : hiding footers as every footer is not necessary on all cards; footers are shown on releveant cards
   hideFrameItem "lockDefaultStack"
   hideFrameItem "unlockDefaultStack" 
   hideFrameItem "outputSource"
   hideFrameItem "removeSelected"
   hideFrameItem "removeAll"
   hideFrameItem "newGlobalVariable"
   hideFrameItem "update"
   hideFrameItem "cancelAll"
   hideFrameItem "addStack"
   
   #Preferences
   --frame item: Name                                            Location  Type              Label                                           Value Type  Value                                         Callback Message      Callback Target
   addFrameItem "ideMessageBox_autoupdate",           "header",  "preference",  "Auto Update Pending Messages",  "boolean",     "true,false",                                  "preferenceChanged",  the long id of me
   addFrameItem "ideMessageBox_intelligenceobject", "header",  "preference",  "Select Intelligence Object",            "enum",         "selectedObject,mouseControl",   "preferenceChanged",  the long id of me
   
   hiliteFrameItem "single line"
   showCard "Single Line"
   
   --if there is a stack currently being debugged then the debug mode is true, if no stack is currently being debugged then the debug mode is false
   revIDESetActiveStack
   
   local tIntelligence
   put revIDEGetPreference("ideMessageBox_intelligenceobject") into tIntelligence
   if tIntelligence is empty then
      put "selectedObject" into tIntelligence
   end if
   revIDESetPreference "ideMessageBox_intelligenceobject", "selectedObject"
   revIDEUpdateIntelligenceObject
   
   revIDESubscribe "idePreferenceChanged:cShowRevolutionStacks"
   revIDESubscribe "idePreferenceChanged:revPaletteFrameSize"
   revIDESubscribe "idePreferenceChanged:cScriptEditor,editor,backgroundcolor"
   revIDESubscribe "idePreferenceChanged:cScriptEditor,editor,font"
   revIDESubscribe "idePreferenceChanged:cScriptEditor,editor,fontSize"
   
   revIDESubscribe "ideActiveStacksChanged"
   
   if revIDEGetPreference("revPaletteFrameSize") is empty then revIDESetPreference "revPaletteFrameSize", "small"
   
   local tMinHeight
   put 4*kHalfMessageFieldHeight + the headerHeight of me + the footerHeight of me into tMinHeight
   
   lock messages
   set the minHeight of me to tMinHeight
   moveMsgBoxStack
   
   __UpdateMessageColors
   __UpdateMessageFont
   unlock messages
   unlock screen
end openStack

on ideMsgChanged pTarget, pHandler, pLine, pMsg
   lock messages
   lock screen
   
   if the mode of me is 0 then
      go stack (the short name of me)
   end if
   
   local tField
   if the short name of this card of me is "Multiple Lines" then
      put the long id of field "results" of card "Multiple Lines" of me into tField
   else
      put the long id of field "results" of card "Single Line" of me into tField
   end if
   
   set the text of tField to pMsg
   
   -- PM-2015-06-26: [[ Bug 15478 ]] Make msg box to auto scroll
   local tLines, tHeight
   put the number of lines of the text of tField into tLines
   put the effective textHeight of tField into tHeight
   set the vScroll of tField to tLines * tHeight 
   
   put pTarget into sLastMsg["target"]
   put pHandler into sLastMsg["handler"]
   put pLine into sLastMsg["line"]
   
   unlock screen
   unlock messages
end ideMsgChanged


--PM-2016-04-29: [[ Bug 17534 ]] Make sure the correct handler is called
on moveMsgBoxStack
   --set the position of the stack as a custom property so when it is reopened/different card is selected it remains in the same location
   set the cREVLeft of me to the left of me
   set the cREVTop of me to the top of me
end moveMsgBoxStack

on closeStack
   moveMsgBoxStack
end closeStack

command setUpDataView
   --setting up a data view for cards "Pending Messages","Front Scripts", "Back Scripts" and "Pending Messages"
   
   lock screen
   local theStylesA
   
   set the behavior of group "objectList" of me to revIDEDataViewBehavior()
   send "ResetView" to group "objectList" of me
   
   put the long id of group "pendingMessagesRow" of card "templates" of me into theStylesA["pendingMessages"]
   put the long id of group "frontScriptsRow" of card "templates" of me into theStylesA["frontScripts"]
   put the long id of group "frontScriptsRow" of card "templates" of me into theStylesA["backScripts"]
   put the long id of group "stacksRow" of card "templates" of me into theStylesA["stacksInUse"]
   
   set the viewProp["row style templates"] of group "objectList" of me to theStylesA
   
   set the viewProp["hilite color"] of group "objectList" of me to revIDEColor("dataView_hiliteColor")
   set the viewProp["background color"] of group "objectList" to empty
   set the viewProp["row color"] of group "objectList" of me to revIDEColor("dataView_rowColor")
   set the viewProp["alternate row color"] of group "objectList" of me to revIDEColor("dataView_rowAlternateColor")
   
   set the viewProp["fixed row height"] of group "objectList" of me to "true"
   set the viewProp["row height"] of group "objectList" of me to 24
   set the viewProp["cache"] of group "objectList" of me to "none"
   unlock screen
end setUpDataView

command showCard pCard
   lock screen
   put pCard into lSelectedCard
   go to card lSelectedCard
   ##GH : will need localising
   --set the title of this stack to revIDELocalisedString("Message Box" && "(" & lSelectedCard & ")")
   set the title of me to "Message Box" && "(" & lSelectedCard & ")"
   
   --get message history for Single Line and Multiple Lines
    if pCard is among the items of "Single Line,Multiple Lines" then 
      replace space with "" in pCard
      put "IDE" & pCard & "MessageHistory" into lCardHistoryPref
   end if
   unlock screen
end showCard

command lockDefaultStack
   --locks the default stack to the stack selected in the "Open STacks" button
   lock screen
   local tActiveStack
   put revIDEGetPreference("IDEActiveStack") into tActiveStack
   revIDESetPreference "IDELockedToStack",true
   revIDESetPreference "IDELinkedToStack",tActiveStack
   hideFrameItem "lockDefaultStack"
   showFrameItem "unlockDefaultStack"
   revIDESetActiveStack
   unlock screen
end lockDefaultStack

command unlockDefaultStack
   --default stack is not locked
   lock screen
   revIDESetPreference "IDELockedToStack",false
   revIDESetPreference "IDELinkedToStack",empty
   hideFrameItem "unlockDefaultStack"
   showFrameItem "lockDefaultStack"
   revIDESetActiveStack
   positionOpenStacksButton
   unlock screen
end unlockDefaultStack

command showOutputSource
   --opens the script at the line that has put something into the message box
   global gRevDevelopment
   if not exists(sLastMsg["target"]) or \
         revIDEObjectIsOnIDEStack(sLastMsg["target"]) and not gRevDevelopment then
      exit showOutputSource
   end if
   
   edit script of sLastMsg["target"] at sLastMsg["line"]
end showOutputSource

on removeSelected
   if lSelectedCard is not "Global Variables" then exit removeSelected
   
   local tSelectedVar, tDoString
   put line (the hilitedLine of field "type" of card "Global Variables" of me) of field "type" of card "Global Variables" of me into tSelectedVar
   ##will need localising
   answer warning "Are you sure you want to delete the global variable" && tSelectedVar & "?" with "Yes" or "No"
   if it is "Yes" then
      lock screen
      put "global" && tSelectedVar & cr & "delete global" && quote & tSelectedVar & quote into tDoString
      do tDoString
      revIDEUpdateGlobalVariables
      disableFrameItem "removeSelected"
      unlock screen
   end if
end removeSelected
   
command removeAll
   lock screen
   switch lSelectedCard
      case "Front Scripts"
         --remove all front scripts from the front
         local tFrontScripts, tFrontScript
         put the cREVFrontScripts of me into tFrontScripts
         if revIDERequireWarning(tFrontScripts) is true then
            ##GH : will need localising
            --answer warning revIDELocalisedString("Are you sure you want to remove all front scripts? & cr & cr & "Some of the front scripts belong to the IDE and removing them could cause the IDE to become unstable") with \
               --revIDELocalisedString("Yes") or revIDELocalisedString("No")
            --if it is "No" then exit removeAll
            answer warning "Are you sure you wish to remove all front scripts?" & cr & cr & \
                  "Some of the front scripts belong to the IDE and removing them could cause the IDE to become unstable." with "Yes" or "No"
            if it is "No" then exit removeAll
         end if
         repeat for each line tFrontScript in tFrontScripts
            remove script of tFrontScript from front
         end repeat
         revIDEUpdateFrontScripts
         break
         
      case "Back Scripts"
         --remove all back scripts from the back
         local tBackScripts, tBackScript
         put the cREVBackScripts of me into tBackScripts
         if revIDERequireWarning(tBackScripts) is true then
            ##will need localising
            --answer warning revIDELocalisedString("Are you sure you wish to remove all back scripts?" & cr & cr & "Some of the back scripts belong to the IDE and removing them could cause the IDE to become unstable.") with \
               --revIDELocalisedString("Yes") or revIDELocalisedString("No")
            --if it is "No" then exit removeAll
            answer warning "Are you sure you wish to remove all back scripts?" & cr & cr & \
                  "Some of the back scripts belong to the IDE and removing them could cause the IDE to become unstable." with "Yes" or "No"
            if it is "No" then exit removeAll
         end if
         repeat for each line tBackScript in tBackScripts
            remove script of tBackScript from back
         end repeat
         revIDEUpdateBackScripts
         break
         
      case "Stacks in Use"
         --stop using all stacks in use
         local tStacksInUse, tStack
         put the stacksInUse into tStacksInUse
         repeat for each line tStack in tStacksInUse
            stop using stack tStack
         end repeat
         revIDEUpdateStacksInUse
         break
   end switch
   unlock screen
end removeAll

on revIDEFocusOnMessageBox pChar
   if lSelectedCard is among the items of "Single Line,Multiple Lines" then
      if there is a field "message" of card lSelectedCard then
         focus on field "message" of card lSelectedCard
      else
         focus on field "script" of card lSelectedCard
      end if
      put pChar into the selectedChunk
   end if
end revIDEFocusOnMessageBox

command scriptAction pID, pName
   switch the short name of the target
      case "scriptLines"
         edit the script of pID
         break
      case "behaviorScriptLines"
         edit the script of the behavior of pID
         break
      case "remove selected"
         switch lSelectedCard
            case "Front Scripts"
               if revIDERequireWarning(pID) is true then
                  ##GH : will need localising
                  --answer warning revIDELocalisedConstructedString("Are you sure you want to remove the selected front script [lineOfField]?" & return & "The selected script belongs to the IDE and removing it could make the IDE unstable.",pName) with revIDELocalisedString("Yes") and revIDELocalisedString("No")
                  answer warning "Are you sure you want to remove the selected front script" && pName & "?" & cr & cr & \
                        "The selected back script belongs to the IDE and removing it could cause the IDE to become unstable." with "Yes" or "No"
                  if it is "No" then break
               end if
               remove script of pID from front
               revIDEUpdateFrontScripts
               break
            case "Back Scripts"
               if revIDERequireWarning(pID) is true then
                  ##GH : will need localising
                  --answer warning revIDELocalisedConstructedString("Are you sure you want to remove the selected backscript [lineOfField]?" & return & "The selected script belongs to the IDE and removing it could make the IDE unstable.",pName) with revIDELocalisedString("Yes") and revIDELocalisedString("No")
                  answer warning "Are you sure you want to remove the selected back script" && pName & "?" & cr & cr & \
                        "The selected back script belongs to the IDE and removing it could cause the IDE to become unstable." with "Yes" or "No"
                  if it is "No" then break
               end if
               remove script of pID from back
               revIDEUpdateBackScripts
               break
         end switch
      default
         break
   end switch
end scriptAction

command addGlobalVariable
   local tNewVariable
   if lSelectedCard is not "Global Variables" then exit addGlobalVariable
   
   ##GH : will need localising
   --ask revIDELocalisedString("Enter the name of the new variable:")
   ask "Enter the name of the new variable:"
   put it into tNewVariable
   if the result is "cancel" then exit addGlobalVariable
   
   --the new variable must not be empty or contain more than one word
   if tNewVariable is empty then exit addGlobalVariable
   if the number of words in tNewVariable > 1 then 
      beep
      ##GH : will need localising
      --answer revIDELocalisedString("The name of the variable must be a single word only")
      answer "The name of the variable must be a single word only"
      addGlobalVariable "Global Variables"
   end if
   
   revIDEAddGlobal tNewVariable,"Global Variables"
end addGlobalVariable

command revIDEAddGlobal pNewGlobal, pCard
   local tDoString
   if pCard is not "Global Variables" then exit revIDEAddGlobal
   
   put "global" && pNewGlobal & return & "put empty into" && pNewGlobal into tDoString
   do tDoString
   lock messages
   set the hilitedLine of field "type" to lineOffset(pNewGlobal, field "type")
   unlock messages
   revIDEUpdateGlobalVariables
end revIDEAddGlobal

command updateMessages
   lock screen
   revIDEPendingMessagesRefresh
   unlock screen
end updateMessages

command cancelAllMessages
   local tPendingMessages, tMessage
   if lSelectedCard is not "Pending Messages" then exit cancelAllMessages
   
   put the cREVPendingMessages of me into tPendingMessages
   repeat for each line tMessage in tPendingMessages
      cancel item 1 of tMessage
   end repeat
   
   lock screen
   revIDEPendingMessagesRefresh
   disableFrameItem "cancelAll"
   unlock screen
end cancelAllMessages

command addLibraryStack
   local tNewLibStack
   modal stack "revAddLibraryStack"
   
   if the cREVResult of stack "revAddLibraryStack" is not "OK" then exit addLibraryStack
   put the cREVStack of stack "revAddLibraryStack" into tNewLibStack
   if tNewLibStack is among the lines of stacksInUse then
      beep
      ##GH : will need localising
      --answer error revIDELocalisedConsructedString("Stack [stack] has already been placed into the message path",tNewLibStack)
      answer error "Stack" && tNewLibStack && "has already been placed into the message path."
      exit addLibraryStack
   end if
   
   lock screen
   lock messages
   start using stack tNewLibStack
   go card "Stacks in Use"
   revIDEUpdateStacksInUse
   unlock messages
   unlock screen
end addLibraryStack

on preferenceChanged pPreference, pValue
   lock screen
   switch pPreference
      case "ideMessageBox_autoupdate"
         local tOldValue
         put revIDEGetPreference(pPreference) into tOldValue
         revIDESetPreference pPreference, not(tOldValue)
         revIDEPendingMessagesRefresh
         break
      case "ideMessageBox_intelligenceobject"
         revIDESetPreference pPreference, pValue
         revIDEUpdateIntelligenceObject
         break
   end switch
   unlock screen
end preferenceChanged 

on idePreferenceChanged pPreference, pValue
   lock screen
   switch pPreference
      case "cShowRevolutionStacks"
         switch lSelectedCard
            case "Global Variables"
               revIDEUpdateGlobalVariables
               break
            case "Pending Messages"
               revIDEPendingMessagesRefresh
               break
            case "Front Scripts"
               revIDEUpdateFrontScripts
               break
            case "Back Scripts"
               revIDEUpdateBackScripts
               break
         end switch
         break
      case "revPaletteFrameSize"
         send "resizeStack" to card lSelectedCard of me
         positionOpenStacksButton
         break
      case "cScriptEditor,editor,backgroundcolor"
         __UpdateMessageColors
         break
      case "cScriptEditor,editor,font"
      case "cScriptEditor,editor,fontSize"
         __UpdateMessageFont
         break
      default
         break
   end switch
   unlock screen
end idePreferenceChanged

private command __UpdateMessageFont
   local tFont, tSize
   put revIDEGetPreference("cScriptEditor,editor,font") into tFont
   put revIDEGetPreference("cScriptEditor,editor,fontSize") into tSize
   
   set the textFont of field "script" of card "Multiple Lines" of me to tFont
   set the textFont of field "message" of card "Single Line" of me to tFont
   set the textFont of field "auto complete" of card "Single Line" of me to tFont
   set the textSize of field "script" of card "Multiple Lines" of me to tSize
   set the textSize of field "message" of card "Single Line" of me to tSize
   set the textSize of field "auto complete" of card "Single Line" of me to tSize
   
   dispatch "layoutCard" to card "Single Line" of me
end __UpdateMessageFont

private command __UpdateMessageColors
   local tColor
   put revIDEGetPreference("cScriptEditor,editor,backgroundcolor") into tColor
   set the backgroundColor of field "auto complete" of card "Single Line" of me to tColor
   set the backgroundColor of field "script" of card "Multiple Lines" of me to tColor
end __UpdateMessageColors

command positionOpenStacksButton
   lock screen
   
   local tSize, tTextSize, tMargin, tLeft, tWidth, tBottom, tHeight, tXLoc, tYLoc, tPadding, tIcon
   
   put revIDEGetPreference("revPaletteFrameSize") into tSize
   switch tSize
      case "large"
         put 12 into tTextSize
         put 18 into tPadding
         put 172081 into tIcon
         break
      case "medium"
         put 11 into tTextSize
         put 16 into tPadding
         put 172080 into tIcon
         break
      case "small"
         put 10 into tTextSize
         put 14 into tPadding
         put 172079 into tIcon
         break
   end switch
   
   lock messages
   if there is a group "Stacks" of this card of me then
      set the showBorder of button "Open Stacks" of group "Stacks" of me to true
      set the opaque of button "Open Stacks" of group "Stacks" of me to false
      set the textsize of button "Open Stacks" of group "Stacks" of me to tTextSize
      set the icon of button "Open Stacks" of group "Stacks" of me to tIcon
      set the height of button "Open Stacks" to barHeight(tSize)
      set the width of button "Open Stacks" of group "Stacks" of me to (the formattedWidth of button "Open Stacks" of group "Stacks" of me) + tPadding
      put the formattedWidth of button "Open Stacks" of group "Stacks" of me into tWidth
      set the left of button "Open Stacks" to barRight(tSize) + 5
      set the bottom of button "Open Stacks" to barHeight(tSize)
      set the height of graphic "pipe" to barHeight(tSize)
      set the left of graphic "pipe" to barRight(tSize) + 5
      set the bottom of graphic "pipe" to barHeight(tSize)
   end if 
   
   try
      set the layer of group "background" of card 1 of me to bottom
   end try
   unlock messages
   
   unlock screen
end positionOpenStacksButton

function revIDEAutoComplete pSearchTerm
   local tMessageHistory, tNumChars, tLine, tMatchesList
   put revIDEGetPreference("IDESingleLineMessageHistory") into tMessageHistory
   put number of chars of pSearchTerm into tNumChars
   put empty into tMatchesList
   if tMessageHistory is not empty then
      repeat for each line tLine in tMessageHistory
         if char 1 to tNumChars of tLine is pSearchTerm then put tLine & return after tMatchesList
      end repeat
   end if
   return tMatchesList
end revIDEAutoComplete

command revIDEAcceptAutoComplete
   if lSelectedCard is not "Single Line" then exit revIDEAcceptAutoComplete
   if field "auto complete" is empty then exit revIDEAcceptAutoComplete
   
   lock screen
   lock messages
   put field "auto complete" into field "message" of card "Single Line" of me
   put empty into field "auto complete" of card "Single Line" of me
   select after field "message" of card "Single Line" of me
   dispatch "revSEColorizeField" to stack "revSEUtilities" with the long id of field "message" of card "Single Line" of me
   unlock messages
   unlock screen
end revIDEAcceptAutoComplete

command revIDEConsoleHistoryAdd pScript
   local tMessageHistory, tLine, tCount, tInHistory
   if pScript is empty then exit revIDEConsoleHistoryAdd
   
   put revIDEGetPreference(lCardHistoryPref) into tMessageHistory
   
   --check if pScript is already in the message history and remove it if it is
   put 0 into tCount
   repeat for each line tLine in tMessageHistory
      add 1 to tCount
      if tLine is pScript then 
         put true into tInHistory
         exit repeat
      end if
   end repeat
   if tInHistory is true then delete line tCount of tMessageHistory
   
   --add pScript to the top of the message history
   put pScript & return before tMessageHistory
   if the number of lines in tMessageHistory > kHistoryMax then delete line (kHistoryMax+1) to -1 of tMessageHistory
   revIDESetPreference lCardHistoryPref,tMessageHistory
end revIDEConsoleHistoryAdd

command ideMessageBoxExecuteScript pScript
   lock messages
   if exists(card lSelectedCard of me) then 
      put empty into field "results" of card lSelectedCard of me
   end if
   unlock messages
   
   if lSelectedCard is "Single Line" then put empty into field "auto complete" of card lSelectedCard of me
   if pScript is empty then exit ideMessageBoxExecuteScript
   
   local tDefaultStack
   put revIDEGetPreference("IDEActiveStack") into tDefaultStack
   
   local tIntelligencePref, tIntelligenceObject
   put the cREVIntelligenceObject of me into tIntelligencePref
   
   try
      do "put the long id of the" && tIntelligencePref && "into tIntelligenceObject"
   catch tError
      put the long id of stack tDefaultStack into tIntelligenceObject
   end try
   
   local tValidScript
   ideExecuteScript pScript, tIntelligenceObject, ideIsDebugging(), tValidScript
   if the result is not empty then
      put ideMessageBoxFormatErrorForDisplay(the result, "compile error") into field "results" of card lSelectedCard of me
   else if it is not empty then
      put ideMessageBoxFormatErrorForDisplay(it, "execution error") into field "results" of card lSelectedCard of me
   end if
   
   return tValidScript
end ideMessageBoxExecuteScript 
   
function ideMessageBoxFormatErrorForDisplay pErrorTrace, pErrorType
   --if there is an error, then this will be formatted and then displayed in the results field
   ##GH : will need localising
   local tError, tErrorDisplay, tLineNum
   put line 1 of pErrorTrace into tError
   if item 1 of tError is a number and item 1 of tError >= 0 then
      if pErrorType is "compile error" then
         put "Script compile error:" & cr & "Error description:" && revIDELookupError("compilation", pErrorTrace) into tErrorDisplay
      else
         put "Message execution error:" & cr & "Error description:" && revIDELookupError("execution", pErrorTrace)  & cr & \
               "Hint:" && item 4 to -1 of line 1 of tError into tErrorDisplay
      end if
   else
      put tError into tErrorDisplay
   end if 
   return tErrorDisplay
end ideMessageBoxFormatErrorForDisplay

private command __UpdateIntelligenceDisplay
   lock screen
   local tIntelligence
   put revIDEGetPreference("ideMessageBox_intelligenceobject") into tIntelligence
   lock messages
   try
      do "get the long id of the" && tIntelligence
   catch tError
   end try
   global gRevDevelopment
   if it is empty or it begins with "stack" or \
         (not gRevDevelopment and revIDEObjectIsOnIDEStack(it)) then
      local tCard
      put the short name of this card of me into tCard
      if tCard is "Single Line" or tCard is "Multiple Lines" then
         revIDESetActiveStack
      end if
   else
      local tControl
      put the name of it into tControl
      set the label of button "Open Stacks" of group "Stacks" of card "Single Line" of me to tIntelligence & ": " & tControl
      enable button "Open Stacks" of group "Stacks" of card "Single Line" of me
   end if
   positionOpenStacksButton
   unlock messages
   unlock screen
end __UpdateIntelligenceDisplay

on ideSelectedObjectChanged
   __UpdateIntelligenceDisplay
end ideSelectedObjectChanged

on ideMouseMove
   __UpdateIntelligenceDisplay
end ideMouseMove

command revIDEUpdateIntelligenceObject
   local tIntelligence
   put revIDEGetPreference("ideMessageBox_intelligenceobject") into tIntelligence
   
   if tIntelligence is "selectedObject" then 
      revIDESubscribe "ideSelectedObjectChanged"
      revIDEUnsubscribe "ideMouseMove"
   else if tIntelligence is "mouseControl" then
      revIDESubscribe "ideMouseMove"
      revIDEUnsubscribe "ideSelectedObjectChanged"
   end if
   
   set the cREVIntelligenceObject of me to tIntelligence
   __UpdateIntelligenceDisplay
end revIDEUpdateIntelligenceObject

on ideActiveStacksChanged
   __UpdateIntelligenceDisplay
end ideActiveStacksChanged

command revIDESetActiveStack
   local tMode, tTraceStack, tLock, tLink, tTopStack
   
   lock screen
   put revIDEGetPreference("IDEDebugMode") into tMode
   if tMode is true and the traceStack is not empty then
      put the short name of the traceStack into tTraceStack
      revIDESetPreference "IDEActiveStack",tTraceStack
      disableFrameItem "lockDefaultStack"
      disableFrameItem "unlockDefaultStack"
      lock messages
      set the label of button "Open Stacks" of group "Stacks" of me to tTraceStack
      disable button "Open Stacks" of group "Stacks" of me 
      unlock messages
   else
      put revIDEGetPreference("IDELockedToStack") into tLock
      put revIDEGetPreference("IDELinkedToStack") into tLink
      enableFrameItem "lockDefaultStack"
      enableFrameItem "unlockDefaultStack"
      
      if tLock is true and there is a stack tLink then 
         revIDESetPreference "IDEActiveStack",tLink
         lock messages
         set the label of button "Open Stacks" of group "Stacks" of me to tLink
         enable button "Open Stacks" of group "Stacks" of me
         unlock messages
      else
         put the short name of the topStack into tTopStack
         revIDESetPreference "IDEActiveStack",tTopStack
         preferenceChanged "ideMessageBox_lockdefaultstack", true
         lock messages
         set the label of button "Open Stacks" of group "Stacks" of me to tTopStack
         unlock messages
         enable button "Open Stacks" of group "Stacks" of me
      end if
   end if
   unlock screen
end revIDESetActiveStack 

command revUpdateActiveStack pOldName, pNewName
   if revIDEGetPreference("IDELockedToStack") is false then
      send "revSetActiveStacks" to stack "revfrontscriptlibrary"
      exit revUpdateActiveStack
   end if
   
   if revIDEGetPreference("IDELinkedToStack") is pOldName then
      lock screen
      local tDefaultStack
      lock messages
      put the defaultStack into tDefaultStack
      set the defaultStack to "message"
      unlock messages
      revIDESetPreference "IDELinkedToStack",pNewName
      revIDESetPreference "IDEActiveStack",pNewName
      lock messages
      set the label of button "Open Stacks" of group "Stacks" to pNewName
      set the defaultStack to tDefaultStack
      unlock messages
      unlock screen
   end if
end revUpdateActiveStack

command revIDEUpdateGlobalVariables
   local tVariableNames, tShow, tFilteredVariables
   
   put revIDEGlobalVariables() into tVariableNames
   replace comma with return in tVariableNames
   sort tVariableNames
   put revIDEGetPreference("cShowRevolutionStacks") into tShow
   
   if tShow is false then
      repeat for each line tLine in tVariableNames
         if char 1 to 4 of tLine is "gREV" then next repeat
         else put tLine & return after tFilteredVariables
      end repeat
      delete last char of tFilteredVariables
   else put tVariableNames into tFilteredVariables
   
   lock screen
   put tFilteredVariables into field "type" of card "Global Variables" of me
   put empty into field "contents" of card "Global Variables" of me
   set the cREVFullText of field "type" of card "Global Variables" of me to tFilteredVariables
   unlock screen
end revIDEUpdateGlobalVariables

command revIDEPendingMessagesRefresh
   lock screen
   send "getDataArray" to card "Pending Messages" of me
   send "renderView" to group "objectList" of card "Pending Messages" of me
   send "revAutoRefresh" to card "Pending Messages" of me
   unlock screen
end revIDEPendingMessagesRefresh

command revIDEUpdateFrontScripts
   lock screen
   send "getDataArray" to card "Front Scripts" of me
   send "renderView" to group "objectList" of card "Front Scripts" of me
   unlock screen
end revIDEUpdateFrontScripts

command revIDEUpdateBackScripts
   lock screen
   send "getDataArray" to card "Back Scripts" of me
   send "renderView" to group "objectList" of card "Back Scripts" of me
   unlock screen
end revIDEUpdateBackScripts

command revIDEUpdateStacksInUse
   lock screen
   send "getDataArray" to card "Stacks In Use" of me
   send "renderView" to group "objectList" of card "Stacks In Use" of me
   unlock screen
end revIDEUpdateStacksInUse

function revIDERequireWarning pObjects
   --returns true if the object is part of the IDE and false otherwise
   local tObject
   repeat for each line tObject in pObjects
      if char 1 to 3 of the short name of tObject is "rev" then
         return true
      end if
   end repeat
   return false
end revIDERequireWarning

on rawKeyDown pKey
   if word 1 of the target is not "field" then pass rawKeyDown
   if pKey is 65308 then scrollUp 
   else if pKey is 65309 then scrollDown
   else if pKey is 65310 then scrollLeft
   else if pKey is 65311 then scrollRight
   else 
      pass rawKeyDown
   end if
end rawKeyDown
