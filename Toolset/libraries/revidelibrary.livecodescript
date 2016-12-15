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
