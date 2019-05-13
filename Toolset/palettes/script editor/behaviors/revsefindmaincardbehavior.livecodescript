script "revSEFindMainCardBehavior"
local sCancelled = "false"

# Returns
#   The long id of the stack to use as a regular expression builder
function regularExpressionBuilder
   local tPath
   put revEnvironmentPluginsPath() & slash & "RegExBuilder 1.6.rev" into tPath
   
   if there is no file tPath then
      return empty
   else
      return the long id of stack tPath
   end if
end regularExpressionBuilder

on preOpenCard
   send "revSEFindInitialize" to (getCaller())
   --historyLoad
   optionsHide
   
   --set the label of button "Toggle Options" of me to "+"
   send "resetIcon" to button "Toggle Options" of me
   statusSet empty
   update
   updateButtonStates
end preOpenCard

on menuPick
   updateButtonStates
   pass menuPick
end menuPick

on closeCard
   historySave
   local tCaller
   put getCaller() into tCaller
   if there is a stack tCaller then
      send "revSEFindFinalize" to tCaller
   end if
   pass closeCard
end closeCard

on escapeKey
   close this stack
end escapeKey

on commandKeyDown pKey
   if pKey is not "v" then
      pass commandKeyDown
   end if
   
   # There are two possible pasting targets here, the find and replace combo boxes. In both these cases we have
   # to ensure that multiple lines and formatted text cannot be pasted in.
   local tTextToPaste
   put line 1 of the clipboardData["text"] into tTextToPaste
   
   set the clipboardData["text"] to empty
   set the clipboardData["html"] to empty
   set the clipboardData["text"] to tTextToPaste
   pass commandKeyDown
end commandKeyDown

# Description
#   Sets the properties of all controls on the card to their correct values according to the current context
command update
   local tFindLabel
   put getFindLabel() into tFindLabel
   
   local tFindText
   put historyGet("find") into tFindText
   if tFindLabel is not empty and tFindLabel is not among the lines of tFindText then
      put tFindLabel & return & tFindText into tFindText
   end if
   
   set the text of button "Find" of me to tFindText
   set the label of button "Find" of me to "templabel"
   set the label of button "Find" of me to tFindLabel
   
   local tReplaceLabel
   put getReplaceLabel() into tReplaceLabel
   
   local tReplaceText
   put historyGet("replace") into tReplaceText
   if tReplaceLabel is not empty and tReplaceLabel is not among the lines of tReplaceText then
      put tReplaceLabel & return & tReplaceText into tReplaceText
   end if
   
   set the text of button "Replace" of me to tReplaceText
   set the label of button "Replace" of me to "templabel"
   set the label of button "Replace" of me to tReplaceLabel
   
   set the hilite of button "Case Sensitive Search" of me to sePrefGet("find,casesensitive")
   set the hilite of button "Match Whole Words" of me to sePrefGet("find,wholematches")
   set the hilite of button "regEx" of me to sePrefGet("find,regularexpressions")
   if sePrefGet("find,wildcards") is true then
      set the hilite of button "wildcards" of me to true
   else
      set the hilite of button "wildcards" of me to false
   end if
   
   if sePrefGet("find,plaintext") is true then
      set the hilite of button "plaintext" of me to true
   else
      set the hilite of button "plaintext" of me to false
   end if
   
   ## Default
   if the hilite of button "regEx" of me is false and the hilite of button "wildcards" of me is false and the hilite of button "plaintext" of me is false then
      set the hilite of button "plaintext" of me to true
      sePrefSet "find,plaintext", true
   end if
end update

# Updates the disabled state of the search action buttons according to the label of the target menu.
# This is needed because if searching all stacks, only replace all and find all are allowed.
command updateButtonStates
   # If we are searching within objects in the script editor, we can do everything, otherwise, only
   # find all and replace all are allowed. 
   if the label of button "Location" of me is "Current Tab" or the label of button "Location" of me is "All tabs" then
      enable button "Find Next" of me
      enable button "Replace one" of me
      enable button "Find all" of me
      enable button "Replace all" of me
      enable button "Replace" of me
   else
      enable button "Find all" of me
      
      # Disable this for now as this feature could cause data-loss if not used properly
      -- enable button "Replace all" of me
      disable button "Replace all" of me
      
      disable button "Find Next" of me
      disable button "Replace one" of me
      disable button "Replace" of me
   end if
end updateButtonStates

private function getCaller
   if there is a stack (the cCaller of the owner of me) then
      return the long id of the cCaller of the owner of me
   else
      return empty
   end if
end getCaller

# Returns
#   The label for the "Find" button. This is one of the following values if they exist, in order of preference:
#   1. The last selected text of the editor field in the script editor that called this stack
#   2. The last searched for term
#   3. empty
private function getFindLabel
   send "revSEGetLastSelectedWord" to (getCaller())
   if the result is not empty then
      return line 1 of the result
   end if
   
   local tLastSearch
   put line 1 of historyGet("find") into tLastSearch
   if tLastSearch is not empty then
      return tLastSearch
   end if
   
   return empty
end getFindLabel

# Returns
#   The label for the "Replace" button. This is one of the following values if they exist, in order of preference:
#   1. The last term used to replace something
#   2. empty
private function getReplaceLabel
   local tLastReplace
   put line 1 of historyGet("replace") into tLastReplace
   if tLastReplace is not empty then
      return tLastReplace
   end if
   
   return empty
end getReplaceLabel

local sFindHistory
local sReplaceHistory
constant kHistorySize = 20

# Parameters
#   pType : either "find" or "replace"
# Returns
#   The history of the specified action type, one per line with most recent coming first.
private function historyGet pType
   return seFindHistoryGet(pType)
end historyGet

# Parameters
#   pType : either "find" or "replace"
#   pTerm: the find / replace term to add
# Description
#   Adds the specified term to the history.
private command historyAdd pType, pTerm
   seFindHistoryAdd pType, pTerm
end historyAdd


# Description
#   Loads the history from the preferences
private command historyLoad
   seFindHistoryLoad
end historyLoad

# Description
#   Saves the history to the preferences
private command historySave
   seFindHistorySave
end historySave

# Description
#   Shows the find options
command optionsShow
   lock screen
   local tTop
   put the top of the owner of me into tTop
   set the height of the owner of me to the bottom of group "Options" of me + 5
   set the top of the owner of me to tTop
   unlock screen
end optionsShow

# Description
#   Hides the find options
command optionsHide
   lock screen
   local tTop
   put the top of the owner of me into tTop
   set the height of the owner of me to the bottom of button "Find all" of me + 5
   set the top of the owner of me to tTop
   unlock screen
end optionsHide

command statusSet pStatus
   set the text of field "Status" of me to pStatus
end statusSet

private command getSearchContext @rQuery, @rReplace, @rRegularExpression, @rWildcards, @rWholeMatches, @rIgnoreCase, @rTarget
   local tFindType
   
   put  the label of button "Find" of me into rQuery
   put the label of button "Replace" of me into rReplace
   
   put sePrefGet("find,regularexpressions") into rRegularExpression
   put sePrefGet("find,wildcards") into rWildcards
   
   --put true into rWildcards
   local tWholeMatches
   put sePrefGet("find,wholematches") into rWholeMatches
   put not sePrefGet("find,casesensitive") into rIgnoreCase
   
   switch the label of button "Location" of me
      case "All tabs"
         put "all" into rTarget
         break
      case "Current Tab"
         put "current" into rTarget
         break
      case "Card"
         put "card" into rTarget
         break
      case "Stack"
         put "stack" into rTarget
         break
      case "Stack File"
         put "stack file" into rTarget
         break
      case "All Stack Files"
         put "all stacks" into rTarget
         break
      case "Stack File and its stackFiles"
         put "stack file and stackfiles" into rTarget
         break
      case "All available stacks"
         put "all available stacks" into rTarget
         break
      default
         put "current" into rTarget
   end switch
end getSearchContext

local sLastQuery

# Parameters
#   pAction : either "findNext", "findAll", "replaceCurrent" or "replaceAll"
# Description
#   Performs the specified find action, using the current values of the controls 
#   on this card to obtain all the required parameters
private command findAction pAction
   statusSet empty
   put false into sCancelled
   
   local tQuery, tReplace, tRegularExpression, tWildcards, tWholeMatches, tIgnoreCase, tTarget
   getSearchContext tQuery, tReplace, tRegularExpression, tWildcards, tWholeMatches, tIgnoreCase, tTarget
   
   # Don't allow empty search requests to be sent to the script editor because it will
   # assume that the user pressed a keyboard shortcut and will show the interactive find
   # group.
   if tQuery is empty then
      exit findAction
   end if
   
   switch pAction
      case "findNext"
         send "revSEFindNext tQuery, tRegularExpression, tWildcards, tWholeMatches, tIgnoreCase, tTarget" to (getCaller())
         break
      case "findAll"
         local tCallback
         put "findAllCallback" into tCallback
         
         local tCallbackTarget
         put the long id of me into tCallbackTarget
         
         send "revSEFindAll tQuery, tRegularExpression, tWildcards, tWholeMatches, tIgnoreCase, tTarget, tCallback, tCallbackTarget" to (getCaller())
         
         statusSet empty
         break
      case "replaceCurrent"
         send "revSEReplaceCurrent tQuery, tReplace, tRegularExpression, tWildcards, tWholeMatches, tIgnoreCase, tTarget" to (getCaller())
         break
      case "replaceAll"
         put "replaceAllCallback" into tCallback
         put the long id of me into tCallbackTarget
         
         local tReplacementCount
         send "revSEReplaceAll tQuery, tReplace, tRegularExpression, tWildcards, tWholeMatches, tIgnoreCase, tTarget, tCallback, tCallbackTarget" to (getCaller())
         put the result into tReplacementCount
         statusSet (tReplacementCount & " occurrences replaced")
         break
   end switch
end findAction

# Description
#   Finds the next ocurrence of the specified term and highlights it in the target script editor
command findNext
   findAction "findNext"
end findNext

# Description
#   Replaces the currently highlighted ocurrence of the specified term with the contents of the replace button
#   in the target script editor.
command replaceCurrent
   findAction "replaceCurrent"
end replaceCurrent

# Description
#   Finds all matches for the specified term and displays them in the "Search Results" pane of the target script editor
command findAll
   findAction "findAll"
end findAll

# Description
#   Replaces all matches for the specified term with the contents of the replace button
command replaceAll
   findAction "replaceAll"
end replaceAll

command findAllCallback pMessage
   statusSet pMessage
   
   # This line allows any pending mouseUps on the cancel button to execute, 
   # allowing the search to be cancelled.
   wait 1 millisecond with messages
   
   if sCancelled then
      set the label of button "Find all" of me to empty
      unlock cursor
      put false into sCancelled
      return "cancel"
   else
      return empty
   end if
end findAllCallback

command replaceAllCallback pMessage
   statusSet pMessage
   
   # This line allows any pending mouseUps on the cancel button to execute, 
   # allowing the replace to be cancelled.
   wait 1 millisecond with messages
   
   if sCancelled then
      set the label of button "Replace all" of me to empty
      unlock cursor
      put false into sCancelled
      return "cancel"
   else
      return empty
   end if
end replaceAllCallback

command cancelOperation
   put true into sCancelled
end cancelOperation
