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
