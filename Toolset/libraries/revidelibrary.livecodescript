script "revoldidelibrary"

on revLoadLibrary
   if the target is me then
      insert the script of me into back
   end if
end revLoadLibrary

on revUnloadLibrary
   if the target is me then
      remove the script of me from back
   end if
end revUnloadLibrary

////////////////////////////////////////////////////////////////////////////////

command revIDESetScriptDebugMode pState
   local tOldLockMessages
   put the lockMessages into tOldLockMessages
   
   set the lockMessages to false
   set the cREVScriptDebugMode of stack "revPreferences" to pState
   
   set the lockMessages to tOldLockMessages
end revIDESetScriptDebugMode

# LG-2008-04-22
command revIDEStartCenterCheckOnStackClose pStackName
   --  Want to check if there are any user stacks open.  If there are not we want to display the
   --  start center.
   
   if revOkTarget(the long id of stack pStackName) or the cStartPageShow of stack "revPreferences" is false or the cReloadStartCenter of stack "revPreferences" is false then
      exit revIDEStartCenterCheckOnStackClose
   end if
   
   # LG-2008-06-20 - Bug 6600
   # The stack being closed may still be in the openStacks as revIDEStartCenterCheckOnStackClose is no longer sent in time.
   # Therefore the stack must be filtered out of the openStacks list.
   repeat for each line openStack in the openStacks
      -- Check is openStack is a user stack
      --if char 1 to 3 of openStack is not "rev" or openStack is not among the items of "Message Box,Home,answer dialog,ask dialog,script debugger,file selector,color chooser" then
      if ((not revOkTarget(the long id of stack openStack)) and (the short name of stack openStack is not pStackName)) then
         exit revIDEStartCenterCheckOnStackClose
      end if
      
      # OK-2009-01-20 : Additionally there are certain IDE stacks which we don't want the start centre to jump up over. These are 
      # basically most windows other than the tools palette, menubar and possibly message box and property inspector.
      if (the short name of stack openStack is not pStackName) and (openStack is not among the lines of revIDESideWindows()) then
         exit revIDEStartCenterCheckOnStackClose
      end if
   end repeat
   
   # LG-2008-06-20  - Bug 6600
   # Now sent in time so the start center will appear after the stack disappears.
   send "revIDEShowStartCenter" to me in 0 milliseconds
end revIDEStartCenterCheckOnStackClose

# Returns
#   A list of the short names of IDE stacks which are considered not to be "main windows", i.e they could be open most of the time
#   Even when the user is not actually using them. This may require some tweaking to get right...
function revIDESideWindows
   local tWindows
   put "revMenubar" & return & \
         "revTools" & return & \
         "message box" & return & \
         "revApplicationOverview" & return into tWindows
   
   # The property inspector needs a little more work to deal with...
   repeat for each line tStack in the mainstacks
      if word 1 of the short name of stack tStack is "revPropertyPalette" and word 2 of the short name of stack tStack is a number then
         put the short name of stack tStack & return after tWindows
      end if
   end repeat
   delete the last char of tWindows
   
   return tWindows
end revIDESideWindows

command revIDEShowSearchEngine
   revIDEOpenPalette "search engine"
end revIDEShowSearchEngine

# OK-2008-06-24: Bug 6575 - Message box command + m shortcut not working in script editor
# Description
#   Launches and shows the message box, the same as the Tools -> Message box menu item
command revIDEShowMessageBox
   # BB-2015-05-21 - This handler should ultimately be deleted. Calling into new IDE library
   # to open the message box.
   revIDEOpenPalette "message box"
   exit revIDEShowMessageBox
   
   set the cUserOpen of stack "Message Box" to true
   if the mode of stack "Message Box" is 0 then
      set the visible of stack "Message Box" to true
      go stack "Message Box"
   else if "Message Box" is not in the openStacks then
      if the selectedField is not "message" or the number of this card of stack "message box" is not 1 then
         lock screen
         go card 1 of stack "Message box"
         set the title of stack "Message box" to "Message Box (Single Line)"
         --set the hilitedButtonName of group "button tabs" of stack "message box" to "Single Line"
         # DW-2013-03-26
         # fixing message box not hiliting first line in 6.0rc3 due to objects being referenced by number rather than a unique name
         --focus on field 1 of stack "message box"
         --focus on field 2 of stack "message box"
         focus on field 3 of stack "message box"
         select text of field 3 of stack "message box"
      end if
   else
      set the cUserOpen of stack "Message Box" to false
      close stack "Message Box"
   end if
end revIDEShowMessageBox

--local sAddedObjects

# Parameters
#   pRootObject : the object to list the tree for, this is a reference to any LiveCode object
#   pIncludeSubstacks : if pRootObject is a mainstack, this determines whether or not its substacks are searched. Otherwise its ignored.
# Returns
#   Empty if all possible objects were returned, otherwise a warning string explaining why some / all were ommited.
# Description
#   rList will be set to the list of objects underneath the root object. This is inclusive, i.e. it includes pRootObject.
#   If pRootObject is a mainstack, the stack will be searched, followed by all mainstacks if pIncludeSubstacks is true.
#   If pRootObject is a stack, the object list is the stack, all its cards, and all objects on each card
#   If pRootObject is a card the list is the card and all objects on it
#   If pRootObject is any other control, the list is pRootObject.
function revIDEListSearchObjectTree pRootObject, pObeyDontSearch, pMarked, pIncludeSubstacks, pIgnorePasswordProtected, pScriptsOnly, @xList
   --delete variable sAddedObjects
   
   # Put the root object into the list first. If this is not possible because to dontSearch or card marking then
   # return an error and put empty into the list. What might also happen is that one of the child objects
   # as its dontSearch set to true. In this case, we'll return a partial list.
   if pObeyDontSearch and word 1 of the name of pRootObject is among the words of "field group card" then
      put empty into xList
      return "dontSearch of root object set"
   end if
   
   # Set the HCAddressing property of the owning stack of pRootObject to false, as this will mess
   # up everything otherwise.
   local tOldHCAddressing
   put the hcAddressing of stack revTargetStack(pRootObject) into tOldHCAddressing
   set the hcAddressing of stack revTargetStack(pRootObject) to false
   
   # If the root object is a mainstack, we add the stack itself, then all its substacks if applicable
   local tResult
   switch word 1 of pRootObject
      case "stack"
         if the mainstack of pRootObject is the short name of pRootObject and pIncludeSubstacks then
            addStack pRootObject, pObeyDontSearch, pMarked, pIgnorePasswordProtected, xList, pScriptsOnly
            put the result into tResult
            
            repeat for each line tSubstack in the substacks of pRootObject
               local tSubstackResult
               addStack the name of stack tSubstack, pObeyDontSearch, pMarked, pIgnorePasswordProtected, xList, pScriptsOnly
               put the result into tSubstackResult
               if tResult is empty then
                  put tSubstackResult into tResult
               end if
            end repeat
         else
            # If its not a mainstack, or we're not adding substacks, just add the stack
            addStack pRootObject, pObeyDontSearch, pMarked, pIgnorePasswordProtected, xList, pScriptsOnly
            put the result into tResult
         end if 
         break
      case "card"
         # If its a card then add the card and all its controls
         addCard pRootObject, pObeyDontSearch, pMarked, xList, pScriptsOnly
         put the result into tResult
         break
      case "group"
         # If its a group then add the group and all its control
         addGroup pRootObject, pObeyDontSearch, xList, pScriptsOnly
         put the result into tResult
         break
      default
         # All other objects, i.e non-containers, just add the single object to the list.
         addObject pRootObject, pObeyDontSearch, xList, pScriptsOnly
         put the result into tResult
         break
   end switch
   
   set the hcAddressing of stack revTargetStack(pRootObject) to tOldHCAddressing
   
   return tResult
end revIDEListSearchObjectTree

private command addObject pObject, pObeyDontSearch, @xList, pScriptsOnly
   if pObeyDontSearch and the dontSearch of pObject and word 1 of the name of pObject is among the words of "card group field" then
      return "dontSearch set on object"
   end if
   
   if not pScriptsOnly or the script of pObject is not empty then
      put empty into xList[the long id of pObject]
   end if
   return empty
end addObject

private command addCard pCard, pObeyDontSearch, pMarked, @xList, pScriptsOnly
   if pMarked is not empty and pMarked is not the mark of pCard then
      return "marked mismatch"
   end if
   
   # Add the card itself
   local tResult
   addObject pCard, pObeyDontSearch, xList, pScriptsOnly
   put the result into tResult
   
   # Add the non-grouped controls
   local tObjectResult
   local tControlID
   repeat for each line tControlID in the childControlIDs of pCard
      # Don't add groups
      if word 1 of the name of control id tControlID of pCard is among the words of "group bkgnd" then
         next repeat
      end if
      
      # Don't add grouped controls
      if the owner of control id tControlID of pCard is not empty and word 1 of the name of the owner of control id tControlID of pCard is among the words of "group bkgnd" then
         next repeat
      end if
      
      addObject the long id of control id tControlID of pCard, pObeyDontSearch, xList, pScriptsOnly
      put the result into tObjectResult
      
      if tResult is empty then
         put tObjectResult into tResult
      end if
   end repeat
   
   # Add any groups.
   local tGroup, tGroupResult
   local tID
   repeat for each line tId in the groupIds of pCard
      put the long id of group id tId of pCard into tGroup
      if the sharedBehavior of tGroup then
         next repeat
      end if
      
      # Note that if a group on the card does not have its backgroundBehavior set, but is placed on multiple cards,
      # it will be duplicated in the list. I'm not sure if this is correct or not...
      addGroup tGroup, pObeyDontSearch, xList, pScriptsOnly
      put the result into tGroupResult
      
      if tResult is empty then
         put tGroupResult into tResult
      end if
   end repeat
   
   return tResult
end addCard

private command addGroup pGroup, pObeyDontSearch, @xList, pScriptsOnly
   if pObeyDontSearch and the dontSearch of pGroup then
      return "dontSearch set on group"
   end if
   
   local tResult
   addObject pGroup, pObeyDontSearch, xList, pScriptsOnly
   put the result into tResult
   
   local tObjectResult
   local tControlID
   repeat for each line tControlID in the childControlIDs of pGroup
      addObject the long id of control id tControlID of pGroup, pObeyDontSearch, xList, pScriptsOnly
      put the result into tObjectResult
      
      if tResult is empty then
         put tObjectResult into tResult
      end if
   end repeat
   
   return tResult
end addGroup

private command addStack pStack, pObeyDontSearch, pMarked, pIgnorePasswordProtected, @xList, pScriptsOnly
   local tResult
   
   if pIgnorePasswordProtected then
      try
         get the script of pStack
      catch tError
         return "Stack password protected"
      end try
   end if
   
   # The stack itself
   addObject pStack, pObeyDontSearch, xList, pScriptsOnly
   put the result into tResult
   
   # All shared groups groups on the stack
   local tSharedGroupResult
   local tGroupID
   repeat for each line tGroupID in the sharedGroupIDs of pStack
      addGroup the long id of control id tGroupID of pStack, pObeyDontSearch, xList, pScriptsOnly
      put the result into tSharedGroupResult
      
      if tResult is empty then
         put tSharedGroupResult into tResult
      end if
   end repeat
   
   # All the cards on the stack
   local tCardResult
   local tCardID
   repeat for each line tCardID in the cardIDs of pStack
      addCard the long id of card id tCardID of pStack, pObeyDontSearch, pMarked, xList, pScriptsOnly
      put the result into tCardResult
      
      if tResult is empty then
         put tCardResult into tResult
      end if
   end repeat
   
   return tResult
end addStack

function revIDEImmediateOwner pObject, pType
   # Start with the object itself
   local tObject
   put revRuggedId(pObject) into tObject
   
   repeat
      # First check if the current object is of the type we want, if so, return it
      if pType is "card" then
         if word 1 of the name of tObject is "card" then
            return tObject
         else if word 1 of the name of tObject is "stack" then
            return tObject
         end if
      end if
      
      # If the object has no owner we can't continue, this can only happen if the caller requests the card that owns a stack,
      # so is a bug.
      if the owner of tObject is empty then
         exit repeat
      end if
      
      # This means the object was not of the type we wanted, but it does have an owner, so we check its owner.
      put the owner of tObject into tObject
   end repeat
   
   # Should never get here...
end revIDEImmediateOwner

# OK-2009-10-09 : The following stuff added for the auto update checker and related systems
command revIDELaunchUpsellLink pAction
   local tBaseUrl
   put "http://developer.runrev.com/redirect.irev?action=" into tBaseUrl
   
   local tUrl
   put tBaseUrl & pAction into tUrl
   
   if pAction is among the items of "buy_early_update_pack,buy_update_pack,buy_license" then
      put "&edition=" & revIDEGetProductEditionName() after tUrl
   end if
   
   launch url tUrl
end revIDELaunchUpsellLink

function revIDEGetProductEditionName
   switch line 4 of the revLicenseInfo
      case "Enterprise"
         return "revEnterprise"
         break
      case "Studio"
         return "revStudio"
         break
      case "Media"
         return "revMedia"
         break
      default
         return empty
   end switch
end revIDEGetProductEditionName

private function idePrefToPropertyName pPref
   return "c" & pPref
end idePrefToPropertyName

function revIDEPrefGet pPref
   local tPropname
   put idePrefToPropertyName(pPref) into tPropname
   return the tPropname of stack "revPreferences"
end revIDEPrefGet

command revIDEPrefSet pPref, pValue
   local tPropname
   put idePrefToPropertyName(pPref) into tPropname
   set the tPropname of stack "revPreferences" to pValue
end revIDEPrefSet

////////////////////////////////////////////////////////////////////////////////

# Parameters
#   pPath : The full path of a stack
# Description
#   Returns true if pPath is the path of an IDE stack, false otherwise.
function revIDEStack pPath
   # OK-2008-06-16 : There is of course one other IDE mainstack that is not a stackFile of stack "Home"....
   if pPath is the filename of stack "Home" then
      return true
   end if
   
   local tStackfilePath
   repeat for each line tStackfile in the stackfiles of stack "home"
      put item 2 to -1 of tStackfile into tStackfilePath
      if pPath is tStackfilePath then
         return true
      end if
   end repeat
   return false
end revIDEStack

# OK-2007-11-29 : Bug 5597
# Parameters
#   <none>
# Description
#   Sent when the user has requested to "Save" either by clicking in File -> Save As or by pressing ctrl-s.
#   This command attempts to save the topStack if appropriate. Note that if the shiftKey is down, the command 
#   exits, this was kept to preserve existing behavior. Sends "closeField" to the focused field of the property
#   inspector if it is open.
command revIDESaveRequest
  if the mode of the topStack is not 1 then
    exit revIDESaveRequest
  end if
  if the shiftKey is down then
    exit revIDESaveRequest
  end if
   
  if (the focusedObject) is not empty and word 1 of revTargetStack(the focusedObject) is "revPropertyPalette" and word 1 of (the focusedObject) is "field" then
    local tObject
    put the focusedObject into tObject
    send "closeField" to tObject
  end if
  
  if the effective filename of the topStack is not empty then
    revSave (the short name of the topStack)
  else
    revSaveAs (the short name of the topStack)
  end if
end revIDESaveRequest

# Returns whether the path pPath is case sensitive. pPath must point to a file.
private function utilityPathIsCaseSensitive pPath
  local tFolder
  
  local tOriginalFolder
  put the folder into tOriginalFolder
  
  set the itemDelimiter to slash
  put item 1 to -2 of pPath into tFolder
  
  local tIsCaseSensitive
  put false into tIsCaseSensitive
  
  set the folder to tolower(tFolder)
  if the result is not empty then
    put true into tIsCaseSensitive
  end if
  
  set the folder to toupper(tFolder)
  if the result is not empty then
    put true into tIsCaseSensitive
  end if
  
  set the folder to tOriginalFolder
  
  return tIsCaseSensitive
end utilityPathIsCaseSensitive

# Given two different paths where the filename is the same, returns a portion of pPath appropriate to differentiate
# it from pDuplicatePath. This is used for the recent file menu. This is slightly experimental in an attempt to 
# improve the existing way of doing this.
private function utilityDifferentialPath pPath, pDuplicatePath
  set the itemDelimiter to slash
  
  local tItemCount
  put the number of items of pPath into tItemCount
  
  if the number of items of pPath = 1 then
    return pPath
  end if
  
  # tDifferentialPath will be the path that we return. We always return at least the filename.
  local tDifferentialPath
  put item -1 of pPath into tDifferentialPath
  
  # Starting with the item before the filename, loop back through pPath, comparing each item with pDuplicatePath.
  # Once a difference is found, we make the different item the first item in our differential path. If the path is 
  # relative, add "../" at the start.
  repeat with tItem = -2 down to -(tItemCount)
    put item tItem of pPath & slash before tDifferentialPath
    if item tItem of pPath <> item tItem of pDuplicatePath then
      if tItem <> 1 then
        put "../" before tDifferentialPath
        exit repeat
      end if
    end if
  end repeat
  if the first char of tDifferentialPath is slash then
    delete the first char of tDifferentialPath
  end if
   
  return tDifferentialPath
end utilityDifferentialPath

# Wrapper round the platform to ease testing of platform specific code
private function utilityGetPlatform
  return the platform
end utilityGetPlatform

# Returns the *actual* path of the file specified by pPath. Returns empty if the file doesnt exist
private function utilityCanonicalizePath pPath
  local tDefaultFolder
  put the defaultFolder into tDefaultFolder
  
  set the itemDelimiter to slash
   
  local tFolder, tFilename
  put item 1 to -2 of pPath into tFolder
  put item -1 of pPath into tFilename
  
  set the defaultFolder to tFolder
   
  set the caseSensitive to utilityPathIsCaseSensitive(pPath)
   
  local tFiles
  put the files into tFiles
   
  local tLineNumber
  set the wholeMatches to true
  put lineOffset(tFilename, tFiles) into tLineNumber
  
  local tExists
  if tLineNumber = 0 then
    put false into tExists
  else
    put true into tExists
  end if
  
  local tCanonicalFolder
  put the defaultFolder into tCanonicalFolder
  set the defaultFolder to tDefaultFolder
  
  if tExists then
    return tCanonicalFolder & slash & line tLineNumber of tFiles
  else
    return empty
  end if
end utilityCanonicalizePath
