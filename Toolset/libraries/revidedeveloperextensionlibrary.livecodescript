script "revIDEDeveloperExtensionLibrary"
local sExtensionDetailsA

private command __revIDEDeveloperExtensionSendWarning pWarning
   ideMessageSend "ideExtensionLog", "Warning:" && pWarning
end __revIDEDeveloperExtensionSendWarning

private command __revIDEDeveloperExtensionSendError pError
   ideMessageSend "ideExtensionLog", "Error:" && pError
end __revIDEDeveloperExtensionSendError

private command __revIDEDeveloperExtensionLog pLog
   ideMessageSend "ideExtensionLog", pLog
end __revIDEDeveloperExtensionLog

private command __revIDEDeveloperCompilationError pError, pFile
   local tLineNo, tChar, tEndChar, tLine
   # Parse out the error details to provide more meaningful feedback
   repeat for each line tErrLine in pError
      if matchText(tErrLine, ":([0-9]*):([0-9]*):", tLineNo, tChar) then
         put line tLineNo of url ("file:" & pFile) into tLine
         put tChar into tEndChar
         repeat while tChar is not 0 and char tChar - 1 of tLine is not " "
            subtract 1 from tChar
         end repeat
         ideMessageSend "ideExtensionLog", "Error: on line" && tLineNo && "(" & tLine & ")" & ":" && char tChar + 1 to tEndChar - 1 of tLine
      end if
   end repeat
   
   ideMessageSend "ideExtensionLog", "Error:" && pError
end __revIDEDeveloperCompilationError

private function __revIDEDeveloperExtensionShouldRecompile pFolder, pFile, pType
   # To avoid excessive recompilation, test to see if the compiled module exists and is up to date.
   local tCompileInputs, tCompileOutputs, tNeedUpdate, tError
   
   put pFolder & slash & pFile into tCompileInputs[1]
   
   put pFolder & slash & "manifest.xml" into tCompileOutputs[1]
   if pType is "lcb" then
      put pFolder & slash & revIDEExtensionBytecodeFilename(true) into tCompileOutputs[2]
   end if
   put revIDEIsFilesetStale(tCompileInputs, tCompileOutputs, false, tError) \
         into tNeedUpdate
   
   if pType is "lcb" and tNeedUpdate is false then
      put not extensionCheckModuleVersion("", tCompileInputs[1]) into tNeedUpdate
   end if
   
   return tNeedUpdate is not false
end __revIDEDeveloperExtensionShouldRecompile

private command __revIDEDeveloperExtensionRemoveFolder pFolder
   local tDeveloperExtensionsFolders
   put revIDEDeveloperExtensionsFolders() into tDeveloperExtensionsFolders
   
   set the itemdelimiter to slash
   local tRootFolder
   put item 1 to -2 of pFolder into tRootFolder
   
   local tLine
   put lineOffset(tRootFolder, tDeveloperExtensionsFolders) into tLine
   if tLine is not 0 then
      delete line tLine of tDeveloperExtensionsFolders
      revIDEDeveloperExtensionsSetFolders tDeveloperExtensionsFolders
   end if
end __revIDEDeveloperExtensionRemoveFolder

private command __revIDEDeveloperExtensionAddFolder pFolder
   local tDeveloperExtensionsFolders
   put revIDEDeveloperExtensionsFolders() into tDeveloperExtensionsFolders
   
   set the itemdelimiter to slash
   local tRootFolder
   put item 1 to -2 of pFolder into tRootFolder
   if tDeveloperExtensionsFolders is empty then
      put tRootFolder into tDeveloperExtensionsFolders
   else
      if tRootFolder is not among the lines of tDeveloperExtensionsFolders then
         put return & tRootFolder after tDeveloperExtensionsFolders
      end if
   end if
   
   revIDEDeveloperExtensionsSetFolders tDeveloperExtensionsFolders
end __revIDEDeveloperExtensionAddFolder

/*
Summary: Returns an array of details of the extensions found in user folders
Returns (array):
{ key: The path to the folder containing the extensions
value (array): The array of details pertaining to the extension
{ key: "name"
value: The extension ID
key: "title"
value: The title of the extension
key: "author"
value: The author of the extension
key: "api"
value: An array describing the documented elements of this extension
key: "guide"
value: The user guide
key: "icon"
value: The path to the icon of this extension
key: "retina_icon"
value: The path to the retina icon of this extension } } 
*/
function revIDEDeveloperExtensions
   local tExtensionDetailsA
   
   local tFolders
   if not revEnvironmentIsInstalled() then
      # Look for extension examples in git repo.
      put revEnvironmentRepositoryPath() & slash & "extensions" & slash & "widgets" into tFolders 
      put return & revEnvironmentRepositoryPath() & slash & "extensions" & slash & "libraries" after tFolders
   end if
   
   # Look for extension examples in previously selected user folders.
   local tUserFolders
   put revIDEDeveloperExtensionsActiveFolders() into tUserFolders
   repeat for each line tLine in tUserFolders
      if tLine is among the lines of tFolders then next repeat
      
      if tFolders is empty then
         put tLine into tFolders
      else
         put return & tLine after tFolders
      end if
   end repeat
   
   local tFolder, tExtensionFolders, tExtensionFolder, tFiles, tExtension
   
   local tFolderHasModule
   repeat for each line tFolder in tFolders
      put false into tFolderHasModule
      if tFolder is empty then
         next repeat
      end if
      put folders(tFolder) into tExtensionFolders
      repeat for each line tExtensionFolder in tExtensionFolders
         if tExtensionFolder is ".." then 
            next repeat
         end if
         local tExtensionA
         # On first run, don't compile.
         put revIDEDeveloperExtensionNoCompile(tFolder & slash & tExtensionFolder)  into tExtensionA
         if tExtensionA is not empty then
            put tExtensionA into tExtensionDetailsA[tFolder & slash & tExtensionFolder]
            put true into tFolderHasModule
         end if
      end repeat
      if tFolderHasModule is false then
         __revIDEDeveloperExtensionRemoveFolder tFolder
      end if
   end repeat
   
   return tExtensionDetailsA
end revIDEDeveloperExtensions

private command __revIDEDeveloperExtensionFetchExtensionSourceInFolder pFolder, @rFile, @rSupportFiles, @rType
   local tMainFile, tType, tSupportFiles
   extensionFetchSourceFromFolder pFolder, tMainFile, tSupportFiles, tType
   
   if the result is not empty then
      __revIDEDeveloperExtensionSendError the result
   end if
   
   put tMainFile into rFile
   put tSupportFiles into rSupportFiles
   put tType into rType
end __revIDEDeveloperExtensionFetchExtensionSourceInFolder

function revIDEDeveloperExtensionNoCompile pFolder
   return extensionFetchFolderDetails(pFolder, true)
end revIDEDeveloperExtensionNoCompile

function revIDEDeveloperExtensionsFolders
   return revIDEGetPreference("cDeveloperExtensionsFolders")
end revIDEDeveloperExtensionsFolders

command revIDEDeveloperExtensionsSetFolders pFolders
   revIDESetPreference "cDeveloperExtensionsFolders", pFolders
end revIDEDeveloperExtensionsSetFolders

function revIDEDeveloperExtensionsActiveFolders
   return revIDEGetPreference("cDeveloperExtensionsActiveFolders")
end revIDEDeveloperExtensionsActiveFolders

command revIDEDeveloperExtensionsActiveFolders pFolders
   revIDESetPreference "cDeveloperExtensionsActiveFolders", pFolders
end revIDEDeveloperExtensionsActiveFolders

function revIDEDeveloperExtension pFolder
   return __revIDEDeveloperExtensionCompileAndFetchDetails(pFolder, true)
end revIDEDeveloperExtension

private function __revIDEDeveloperExtensionCompileAndFetchDetails pFolder, \
      pForceReparseManifest
   local tSource, tSupport, tType
   extensionFetchSourceFromFolder pFolder, tSource, tSupport, tType
   
   revIDEExtensionUpdateAPI pFolder, tSource
   
   local tReparseManifest
   if __revIDEDeveloperExtensionShouldRecompile(pFolder, tSource, tType) then
      if tType is "lcb" then
         # The compiled module or manifest is not up to date, so compile.
         __revIDEDeveloperExtensionLog "Compiling module" && pFolder & slash & tSource
         __revIDEDeveloperCompileModule pFolder, tSource, tSupport, pFolder
         if the result is not empty then
            # This may be better as a warning, and try to parse info direct from the file.
            __revIDEDeveloperExtensionSendError the result
            put false into tReparseManifest
         else 
            put true into tReparseManifest
         end if
      else
         __revIDEDeveloperExtensionLog "Creating manifest for extension" && pFolder & slash & tSource
         extensionGenerateManifestForLCSExtension "revDocsParser", pFolder
         put true into tReparseManifest
      end if
   else
      __revIDEDeveloperExtensionLog "Skipping rebuild of" && \
            pFolder & slash & tSource && "- extension is up to date"
      put false into tReparseManifest
   end if
   
   put tReparseManifest or pForceReparseManifest into \
         tReparseManifest
   
   local tDetailsA
   put extensionFetchFolderDetails(pFolder, tReparseManifest) into tDetailsA
   union tDetailsA with sExtensionDetailsA[pFolder]
   put tDetailsA into sExtensionDetailsA[pFolder]
   return sExtensionDetailsA[pFolder]
end __revIDEDeveloperExtensionCompileAndFetchDetails

on revIDEDeveloperExtensionAddResourceFile pExtensionFolder, pResourcePath, pType
   if there is not a file pResourcePath then
      __revIDEDeveloperExtensionSendError the result
      exit revIDEDeveloperExtensionAddResourceFile
   end if
   
   local tResourceFolder
   put pExtensionFolder & slash & "resources" into tResourceFolder
   if there is not a folder tResourceFolder then
      create folder tResourceFolder
   end if
   
   set the itemdelimiter to slash
   switch pType
      case "icon"
         revCopyFile pResourcePath, pExtensionFolder & slash & "icon.png"
      case "retina_icon"
         revCopyFile pResourcePath, pExtensionFolder & slash & "icon@extra-high.png"
      case "api"
         revCopyFile pResourcePath, pExtensionFolder & slash & "api.lcdoc"
      case "guide"
         revCopyFile pResourcePath, pExtensionFolder & slash & "guide.md"
      default
         revCopyFile pResourcePath, tResourceFolder & slash & item -1 of pResourcePath
   end switch
   
   if the result is not empty then
      __revIDEDeveloperExtensionSendError "Failed to copy file:" && the result
   end if
end revIDEDeveloperExtensionAddResourceFile

on revIDEDeveloperExtensionAddResourceFolder pExtensionFolder, pResourceFolder
   if there is not a folder pResourceFolder then
      __revIDEDeveloperExtensionSendError "No such folder:" && pResourceFolder
      exit revIDEDeveloperExtensionAddResourceFolder
   end if
   
   local tResourceFolder
   put pExtensionFolder & slash & "resources" into tResourceFolder
   if there is not a folder tResourceFolder then
      create folder tResourceFolder
   end if
   
   revCopyFolder pResourceFolder, pExtensionFolder & slash & "resources"
   if the result is not empty then
      __revIDEDeveloperExtensionSendError "Failed to copy folder:" && the result
   end if
end revIDEDeveloperExtensionAddResourceFolder

local sLoadedExtension
function revIDEDeveloperExtensionCurrentlyTesting
   return sLoadedExtension is not empty
end revIDEDeveloperExtensionCurrentlyTesting

command revIDEDeveloperExtensionStopTesting
   __ClearTestExtension
end revIDEDeveloperExtensionStopTesting

command revIDEDeveloperExtensionTest pPath
   local tDetailsA
   put revIDEDeveloperExtension(pPath) into tDetailsA
   
   if tDetailsA["file"] is empty then
      __revIDEDeveloperExtensionSendError "No extension to test in" && pPath
      exit revIDEDeveloperExtensionTest
   end if
   
   # AL-2015-07-15: [[ Bug ]] If the details of the extension doesn't include an ID, then the compile failed
   if tDetailsA["name"] is empty then
      __revIDEDeveloperExtensionSendError "Could not compile module" && pPath
      exit revIDEDeveloperExtensionTest
   end if
   
   if tDetailsA["source_type"] is "lcb" \
         and there is not a file \
         (pPath & slash & revIDEExtensionBytecodeFilename(true)) then
      __revIDEDeveloperExtensionSendError "No compiled module in" && pPath
      exit revIDEDeveloperExtensionTest
   end if
   
   __ClearTestExtension
   
   revIDEExtensionLoad tDetailsA["source_type"], tDetailsA["name"], pPath, \
         tDetailsA["version"], "installed", "", false, tDetailsA["file"]
   
   local tResult
   put the result into tResult
   if tResult is not empty then
      __revIDEDeveloperExtensionSendError tResult
      exit revIDEDeveloperExtensionTest
   end if
   
   __LaunchTestExtension pPath, tDetailsA
end revIDEDeveloperExtensionTest

local sRectsA
private function __testStackRects
   local tDataA
   if there is a stack "LiveCode Extension Test Window" then
      put the rect of stack "LiveCode Extension Test Window" into tDataA["rect"]
      if there is a widget 1 of stack "LiveCode Extension Test Window" then
         put the rect of widget 1 of stack "LiveCode Extension Test Window" into tDataA["wrect"]
      end if
      return tDataA
   end if
   
   local tScreenRect
   put the working screenrect into tScreenRect
   
   local tX, tY
   if the left of this stack + 200 < (item 3 of tScreenRect) / 2 then
      put the right of this stack + 200 into tX
   else
      put the left of this stack - 200 into tX
   end if
   put item 2 of the loc of this stack into tY
   put tX & comma & tY into tDataA["loc"]
   return tDataA
end __testStackRects

private function __testStackScript
   local tScript
   put "on closeStackRequest;revIDEDeveloperExtensionClearTestStack;exit closeStackRequest;end closeStackRequest;on saveStackRequest;exit saveStackRequest;end saveStackRequest" into tScript
   replace ";" with return in tScript
   return tScript
end __testStackScript

private command __revIDEDeveloperExtensionLaunchTestStack pPath, pDetailsA
   revIDEDeveloperExtensionCreateTestStack pPath, sRectsA, pDetailsA
end __revIDEDeveloperExtensionLaunchTestStack

on revIDEDeveloperExtensionClearTestStack
   send "__revIDEDeveloperExtensionDoClearTestStack" to me in 0 millisecs
end revIDEDeveloperExtensionClearTestStack

on revIDEDeveloperExtensionCreateTestStack pPath, pRectsA, pDetailsA
      send "__revIDEDeveloperExtensionDoCreateTestStack pPath, pRectsA, pDetailsA" to me in 0 millisecs
end revIDEDeveloperExtensionCreateTestStack

on __revIDEDeveloperExtensionDoCreateTestStack pPath, tRectsA, pDetailsA
   __revIDEDeveloperExtensionLog "Launching in Test Window"
   if there is a stack (pPath & slash & "test.livecode") then
      go stack (pPath & slash & "test.livecode") 
   else
      lock screen
      lock messages
      create stack "LiveCode Extension Test Window"
      if tRectsA["rect"] is not empty then
         set the rect of stack "LiveCode Extension Test Window" to tRectsA["rect"]
      else if tRectsA["loc"] is not empty then
         set the loc of stack "LiveCode Extension Test Window" to tRectsA["loc"]
      end if
      set the destroyStack of stack "LiveCode Extension Test Window" to true
      set the title of it to pDetailsA["title"]
      set the script of it to __testStackScript()
      go stack "LiveCode Extension Test Window"
      revIDECreateObject pDetailsA["name"], the long id of the defaultStack, \
            (the width of the defaultStack / 2) & comma & (the height of the defaultStack / 2)
      unlock messages
   end if
   
   if there is not a widget 1 of stack "LiveCode Extension Test Window" then
      __revIDEDeveloperExtensionSendError "failed to create widget" && pDetailsA["name"]
      __revIDEDeveloperExtensionDoClearTestStack
      exit __revIDEDeveloperExtensionDoCreateTestStack
   end if
   
   if tRectsA["wrect"] is not empty then
      set the rect of widget 1 of stack "LiveCode Extension Test Window" to tRectsA["wrect"]
   end if
   
   unlock screen
end __revIDEDeveloperExtensionDoCreateTestStack

private command __LaunchTestExtension pPath, pDetailsA
   -- Only launch a test window if a widget
   if pDetailsA["type"] is "widget" then
      __revIDEDeveloperExtensionLaunchTestStack pPath, pDetailsA
   else
      __revIDEDeveloperExtensionLog "Loaded library" && sLoadedExtension
   end if
   put pDetailsA["name"] into sLoadedExtension
   ideMessageSend "ideExtensionStatusChanged"
end __LaunchTestExtension

private command __ClearTestExtension
   if there is a stack "LiveCode Extension Test Window" then
      put __testStackRects() into sRectsA
      __revIDEDeveloperExtensionDoClearTestStack
   else
      __UnloadTestExtension
   end if
   ideMessageSend "ideExtensionStatusChanged"
end __ClearTestExtension

private command __UnloadTestExtension
   if sLoadedExtension is not empty then
      __revIDEDeveloperExtensionUnload sLoadedExtension
      __revIDEDeveloperExtensionLog "Unloading" && sLoadedExtension
      put empty into sLoadedExtension
   end if
end __UnloadTestExtension

on __revIDEDeveloperExtensionDoClearTestStack
   repeat while there is a widget 1 of stack "LiveCode Extension Test Window" 
      delete widget 1 of stack "LiveCode Extension Test Window"
   end repeat
   delete stack "LiveCode Extension Test Window"
   __UnloadTestExtension
end __revIDEDeveloperExtensionDoClearTestStack

local sInstalledExtension
on __revIDEDeveloperExtensionUnload pExtension
   # Don't unload if we have installed
   if pExtension is not sInstalledExtension then
      revIDEExtensionUnload pExtension
   end if
end __revIDEDeveloperExtensionUnload

command revIDEDeveloperExtensionInstall pFolder
   local tPackage
   __revIDEDeveloperExtensionBuildPackage pFolder, "", tPackage
   if the result is not empty then
      exit revIDEDeveloperExtensionInstall
   end if
   revIDEExtensionInstall tPackage
   put pFolder & slash & revIDEExtensionBytecodeFilename(true) \
         into sInstalledExtension
end revIDEDeveloperExtensionInstall

command revIDEDeveloperExtensionUninstall pPath
   local tDetailsA
   put revIDEDeveloperExtension(pPath) into tDetailsA
   
   if tDetailsA["name"] is empty then
      __revIDEDeveloperExtensionSendError "Extension id lost from" && pPath & ": cannot uninstall"
      exit revIDEDeveloperExtensionUninstall
   end if
   
   revIDEExtensionUninstall tDetailsA["name"]
   
end revIDEDeveloperExtensionUninstall

on revIDEDeveloperExtensionEditScript pFolder
   local tFile, tSupportFiles, tType
   __revIDEDeveloperExtensionFetchExtensionSourceInFolder pFolder, tFile, tSupportFiles, tType
   if tType is "lcb" then
      __revIDEDeveloperExtensionEditLCBScript pFolder & slash & tFile
      repeat for each line tLine in tSupportFiles
         __revIDEDeveloperExtensionEditLCBScript pFolder & slash & tLine
      end repeat
   else 
      if there is a stack (pFolder & slash & tFile) then
         edit script of stack (pFolder & slash & tFile)
      end if
      repeat for each line tLine in tSupportFiles
         if there is a stack (pFolder & slash & tLine) then
            edit script of stack (pFolder & slash & tLine)
         end if
      end repeat
   end if
end revIDEDeveloperExtensionEditScript

private command __revIDEDeveloperExtensionEditLCBScript pFile
   # AL-2015-04-01: [[ Bug 15130 ]] First check to see if there is an existing association
   local tResult
   launch document pFile
   put the result into tResult
   if tResult is not empty then
      # AL-2015-04-01: [[ Bug 15130 ]] Check to see if the text editor preference is set
      local tEditor
      put revIDEGetPreference("LCB_textEditor") into tEditor
      if tEditor is not empty then
         launch pFile with tEditor
         put the result into tResult
      end if
   end if
   
   if tResult is "no association" or tResult is "request failed" \
         or tResult is "no such program" then
      answer file "Select text editor..."
      put it into tEditor
      if tEditor is not empty then
         launch pFile with tEditor
         put the result into tResult
         if tResult is empty then
            # AL-2015-04-01: [[ Bug 15130 ]] If the new text editor launch was successful, set the preference
            revIDESetPreference "LCB_textEditor", tEditor
         end if
      end if
   end if
   
   if tResult is not empty and tResult is not tEditor then
      __revIDEDeveloperExtensionSendError "Could not open" && pFile & ":" && tResult
   end if
end __revIDEDeveloperExtensionEditLCBScript

on revIDEDeveloperExtensionOpen pFolder
   local tFile, tType, tSupportFiles
   __revIDEDeveloperExtensionFetchExtensionSourceInFolder pFolder, tFile, tSupportFiles, tType
   if tFile is empty then
      exit revIDEDeveloperExtensionOpen
   end if
   
   __revIDEDeveloperExtensionAddFolder pFolder
   return revIDEDeveloperExtension(pFolder)
end revIDEDeveloperExtensionOpen

function __revIDEDeveloperExtensionFetchWidgetTemplateFile
   return url ("file:" & revIDESpecialFolderPath("Toolset") & slash & "widget_template.txt")
end __revIDEDeveloperExtensionFetchWidgetTemplateFile

function __revIDEDeveloperExtensionFetchTemplate pDataA
   local tTemplate
   if pDataA["type"] is "widget" then
      put __revIDEDeveloperExtensionFetchWidgetTemplateFile() into tTemplate
   else
      put __revIDEDeveloperExtensionFetchLibraryTemplateFile() into tTemplate
   end if
end __revIDEDeveloperExtensionFetchTemplate

on revIDEDeveloperExtensionNew pDataA
   local tTemplate
   put __revIDEDeveloperExtensionFetchTemplate(pDataA) into tTemplate
   if tTemplate is empty then
      return empty
   end if
   put merge(tTemplate) into url("file:" & pDataA["path"] & slash & pDataA["name"] & ".lcb")
end revIDEDeveloperExtensionNew


private function __fetchMetadatum pXmlId, pKey
   local tNode
   
   if pKey is among the items of "name,type,title,author,description,version,platforms,os" then
      -- Some metadata are placed into specifically-named top-level XML
      -- elements in the manifest.  This list must be kept up-to-date
      -- with the list of special-cased metadatum keys listed in the
      -- "GenerateManifestDefinitions" action in lc-compile's
      -- "generate.g"
      put "/package/" & pKey into tNode
      
   else
      -- Find a corresponding node for a generic metadatum
      put revXmlMatchingNode(pXmlId, "/package", "metadata", "key", pKey, 1) into tNode
      
   end if
   
   if tNode is empty or tNode begins with "xmlerr" then
      return tNode
   end if
   return textDecode(revXMLNodeContents(pXmlId, tNode), "utf-8")
end __fetchMetadatum

private command __revIDEDeveloperCompileModule pFolder, pFile, pSupportFiles, pTargetFolder
   revIDEExtensionCompile pFolder, pFile, pSupportFiles, pTargetFolder
   
   if the result is not empty then
      __revIDEDeveloperCompilationError the result
      return "failed to compile module"
   end if
   
   __revIDEDeveloperExtensionLog it
   
   if there is not a file \
         (pTargetFolder & slash & revIDEExtensionBytecodeFilename(true)) then
      return "failed to compile module"
   end if
   
   if there is not a file (pTargetFolder & slash & "manifest.xml") then
      return "failed to generate manifest"
   end if
   
   return empty
end __revIDEDeveloperCompileModule

on revIDEDeveloperExtensionBuildPackage pFolder
   local tBuiltLocation
   __revIDEDeveloperExtensionBuildPackage pFolder, "", tBuiltLocation
   # AL-2015-05-22: [[ Bug 14919 ]] Don't display success dialog when package building fails
   if the result is empty then
      answer "Package" && tBuiltLocation && "built successfully"
   end if
end revIDEDeveloperExtensionBuildPackage

private command __revIDEDeveloperExtensionBuildPackage pFolder, pTargetFolder, @rBuiltLocation
   extensionPackage pFolder, "", pTargetFolder, false
   if the result is not empty then
      __revIDEDeveloperExtensionSendError the result
      return the result
   end if
   
   put it into rBuiltLocation
   return empty
end __revIDEDeveloperExtensionBuildPackage

on revIDEDeveloperExtensionEditDefaultScript pFolder
   local tSupportFolder, tDefaultScript, tTargetStack
   put pFolder & "/support" into tSupportFolder
   put tSupportFolder & "/defaultscript.livecodescript" into tDefaultScript
   
   local tExpectedName
   put sExtensionDetailsA[pFolder]["name"] & ".__DefaultScript" into tExpectedName
   if there is a file tDefaultScript then
      try
         # If we have a valid stack, open it and edit the script
         open stack tDefaultScript
         put the long id of stack tDefaultScript into tTargetStack
         revIDEEditScriptOfObject tTargetStack
      catch tError
         # Otherwise, try to use the contents of the file as the script of a stack
         local tContents
         put textDecode(url( "binfile:" & tDefaultScript), "utf-8") into tContents
         revIDENewScriptOnlyStackWithScript tExpectedName, tContents
         if the result is empty then
            put it into tTargetStack
            set the filename of tTargetStack to tDefaultScript
         else
            answer error the result
         end if
      end try
   else
      # If there is no file, create a new one.
      revIDENewScriptOnlyStack tExpectedName
      if the result is empty then
         put it into tTargetStack
         if there is not a folder tSupportFolder then
            create folder tSupportFolder
         end if
         save stack tExpectedName as tDefaultScript
      else
         answer error the result
      end if
   end if
   return tTargetStack
end revIDEDeveloperExtensionEditDefaultScript

function revIDEDeveloperExtensionFetchDefaultScript pFolder
   return revIDEExtensionFetchDefaultScript(pFolder, sExtensionDetailsA[pFolder]["name"], false)
end revIDEDeveloperExtensionFetchDefaultScript
