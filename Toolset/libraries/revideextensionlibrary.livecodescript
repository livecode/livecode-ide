script "revideextensionlibrary"
local sExtensions, sExtensionProperties, sModuleVersion

constant kExtensionUtils = "com.livecode.library.extension-utils"
private function __PathToExtensionUtils
   set the itemdelimiter to "."
   return revIDESpecialFolderPath("extensions") & slash & \
      kExtensionUtils & slash & item -1 of kExtensionUtils & "." & \
      "livecodescript"
end __PathToExtensionUtils

on extensionInitialize
   if the target is not me then
      pass extensionInitialize
   end if
   
   insert script of me into back
   
   # Explicitly load extension utils first
   revInternal__LoadLibrary "extension-utils", __PathToExtensionUtils()

   if the result is not empty then
      throw the result
   end if

   # Load all the extensions ready for use
   __extensionsLoad
end extensionInitialize

on extensionFinalize
   if the target is me then
      remove script of me from back
   end if
end extensionFinalize

private function __ModuleVersion
   if sModuleVersion is empty then
      put extensionLCCompileVersion() into sModuleVersion
   end if
   return sModuleVersion
end __ModuleVersion

function revIDEExtensionBytecodeFilename pUseVersion
   if pUseVersion is empty then 
      put true into pUseVersion
   end if
   
   if pUseVersion then
      return "module." & __ModuleVersion() & ".lcm"
   else
      return "module.lcm"
   end if
end revIDEExtensionBytecodeFilename

# Called at startup. Loads all the extensions ready for use
on revIDEInitialiseExtensions
   # Load all the extensions ready for use
   __extensionsLoad
end revIDEInitialiseExtensions

command revIDEExtensionDownloadAndInstall pExtensionPath, pType, pCallbackObject, pCallbackMessage
   local tCacheIndex
   __extensionDownloadBegin pExtensionPath, pType, pCallbackObject, pCallbackMessage
   put it into tCacheIndex
   
   if the result is not empty then
      answer error the result
      exit revIDEExtensionDownloadAndInstall
   end if
   
   # Download the package and install
   __extensionPropertySet tCacheIndex, "package_url", pExtensionPath
   try
      __extensionDownload tCacheIndex
   catch tError
      answer error tError
   end try
   __extensionsChanged
end revIDEExtensionDownloadAndInstall

private function __extensionDependencyExists pExt
   return __extensionCacheID("name", pExt) is a number
end __extensionDependencyExists
   
private command __extensionInstallPackage pPackageLocation
   if there is not a file pPackageLocation then
      throw "No package found at" && pPackageLocation
   end if
   
   local tCacheIndex
   put __extensionCacheID("download_package_path", pPackageLocation) \
         into tCacheIndex
   if tCacheIndex is not a number then
      put the number of elements of sExtensions + 1 into tCacheIndex
      __extensionPropertySet tCacheIndex, "download_package_path", pPackageLocation
      __extensionUpdateUIWithPackage tCacheIndex, pPackageLocation
   end if
   __extensionPropertySet tCacheIndex, "status", "installing"
   
   local tVerifyResult, tName
   __extensionDownloadVerify tCacheIndex
   put the result into tVerifyResult
   if tVerifyResult is not empty then
      __extensionCacheRemove tCacheIndex
      throw "Error installing extension" && pPackageLocation & return & the result
   end if
   
   put __extensionPropertyGet(tCacheIndex, "name") into tName
   
   # Fetch the dependency list (minus builtin modules) and ensure all
   # are loaded
   local tDeps
   put revIDEExtensionsOrderByDependency(tName) into tDeps
   repeat for each line tExtension in tDeps
      # Skip the one we're installing
      if tExtension is tName then
         next repeat
      end if
      # Ensure dependency exists
      if not __extensionDependencyExists(tExtension) then
         throw "Dependency" && tExtension && "not available. Please install before proceeding"
      end if
   end repeat
   __extensionInstall tCacheIndex, pPackageLocation
end __extensionInstallPackage

command revIDEExtensionInstall pPackageLocation
   try
      __extensionInstallPackage pPackageLocation
   catch tError
      answer error tError
   end try
   __extensionsChanged
end revIDEExtensionInstall

# Uninstalls the extension
command revIDEExtensionUninstall pName 
   local tCacheIndex, tName
   # Start the uninstall process
   if pName is a number then
      put __extensionPropertyGet(pName, "name") into tName
      put pName into tCacheIndex
   else
      put __extensionCacheID("name", pName) into tCacheIndex
      put pName into tName
   end if
   
   # Get the path to the package file
   local tExtensionPackageFile, tInstallPath
   put __extensionPropertyGet(tCacheIndex, "download_package_path") into tExtensionPackageFile
   put __extensionPropertyGet(tCacheIndex, "install_path") into tInstallPath
   try
      __extensionUninstallCheckInUse tCacheIndex, 10
      __extensionUninstallDeleteFiles tCacheIndex, tName, tInstallPath, 25
      __extensionUninstallDeletePreferences tCacheIndex, tName, 50
      __extensionUnload tCacheIndex, tName, 80
      __extensionUninstallComplete tCacheIndex
   catch tError
      answer error tError
   end try
   __extensionsChanged
end revIDEExtensionUninstall

# Returns the extension data
function revIDEExtensions pType, pStatus, pWithoutInvisible
   # No type passed so return all extensions
   
   # Repeat over the extension array looking for elements with matching type
   local tExtensions, tExtension
   repeat for each key tCacheId in sExtensions
      put sExtensions[tCacheId] into tExtension
      if tExtension["name"] is empty then 
         __extensionCacheRemove tCacheId
         next repeat
      end if
      if pType is not empty and tExtension["type"] is not pType then 
         next repeat
      end if
      if pStatus is not empty then
         if tExtension["status"] is not pStatus then 
            next repeat
         end if
      end if
      
      if pWithoutInvisible and not tExtension["uservisible"] then
         next repeat
      end if
      
      put tExtension into tExtensions[tExtension["name"]]
   end repeat
   return tExtensions
end revIDEExtensions

# Returns the extension data
function revIDEExtensionProperties pTypeID
   return sExtensionProperties[pTypeID]
end revIDEExtensionProperties

# organise the property info into the structure that the inspectors 
# expect, namely [<section>]["grouplist"][<group>]["proplist"][<prop>]
private function __OrganiseInspectorMetadata pDataA
   local tExtensionPropsInfoA
   repeat for each key tProp in pDataA
      local tSection, tGroup, tOrder, tPropInfoA
      put pDataA[tProp] into tPropInfoA
      put pDataA[tProp]["order"] into tOrder
      put pDataA[tProp]["label"] into tGroup
      put pDataA[tProp]["section"] into tSection
      put tPropInfoA into tExtensionPropsInfoA[tSection]["grouplist"][tGroup]["proplist"][tProp]
      
      put true into tExtensionPropsInfoA[tSection]["grouplist"][tGroup]["widget_prop"]
      put tOrder into tExtensionPropsInfoA[tSection]["grouplist"][tGroup]["order"]
   end repeat
   return tExtensionPropsInfoA
end __OrganiseInspectorMetadata

function revIDEExtensionPropertiesInfo pTypeId, pOrganise
   local tPropsA, tExtensionPropsInfoA
   put revIDEExtensionProperties(pTypeId) into tPropsA
   
   if pOrganise then
      return __OrganiseInspectorMetadata(tPropsA)
   else
      return tPropsA
   end if
end revIDEExtensionPropertiesInfo

function revIDEExtensionProperty pKind, pProperty
   local tExtensionID
   put __extensionCacheID("name", pKind) into tExtensionID
   
   if pProperty is "api" then
      return __TypeToAPI(__extensionPropertyGet(tExtensionID, "type"))
   end if
   
   return __extensionPropertyGet(tExtensionID, pProperty)
end revIDEExtensionProperty

command revIDEExtensionToggleUserVisibility pKind
   local tCacheId
   put __extensionCacheID("name", pKind) into tCacheId
   
   local tUserVisible
   put __extensionPropertyGet(tCacheId, "uservisible") \
         into tUserVisible
   __extensionPropertySet tCacheId, "uservisible", not tUserVisible
   revIDESetPreferenceOfSet pKind, "uservisible", not tUserVisible
end revIDEExtensionToggleUserVisibility

command revIDEExtensionToggleLoadOnStartup pKind
   local tLoadOnStartup
   put revIDEGetPreferenceOfSet(pKind, "loadOnStartup") into tLoadOnStartup
   if tLoadOnStartup is empty then
      put true into tLoadOnStartup
   end if
   revIDEExtensionSetLoadOnStartup pKind, not tLoadOnStartup
end revIDEExtensionToggleLoadOnStartup

command revIDEExtensionSetLoadOnStartup pKind, pValue
   revIDESetPreferenceOfSet pKind, "loadOnStartup", pValue
end revIDEExtensionSetLoadOnStartup

function revIDEExtensionGetLoadOnStartup pKind
   return revIDEGetPreferenceOfSet(pKind, "loadOnStartup") is not false
end revIDEExtensionGetLoadOnStartup

function revIDEExtensionStandaloneSettings pID
   # Get the internal cache index
   local tCacheIndex
   put __extensionCacheID("name", pID) into tCacheIndex

   return __extensionPropertyGet(tCacheIndex, "standaloneSettings")
end revIDEExtensionStandaloneSettings

function revIDEExtensionStandaloneSettingsInfo pTypeId, pOrganise
   local tPropsA, tExtensionPropsInfoA
   put revIDEExtensionStandaloneSettings(pTypeId) into tPropsA
   
   if pOrganise then
      return __OrganiseInspectorMetadata(tPropsA)
   else
      return tPropsA
   end if
end revIDEExtensionStandaloneSettingsInfo

##############################
# PRIVATE INSTALLATION PROCESS
##############################

private command __extensionDownloadBegin pExtensionUrl, pType, pCallbackObject, pCallbackMessage
   if not (pExtensionUrl begins with "http") then
      # pExtensionPath is not a URL or file on disk
      return "Could not download extension. The extension must be a URL" && \
            "to a valid package:" && pExtensionUrl for error
   end if
   
   # Get the ID of the extension in the cache
   local tCacheIndex
   put __extensionCacheID("package_url",pExtensionUrl) into tCacheIndex
   
   if tCacheIndex is empty then
      put __extensionCacheID("download_package_path",pExtensionUrl) into tCacheIndex
   end if
   
   # If the extension cache ID couldn't be found, generate a new one
   if tCacheIndex is empty then 
      put the number of elements of sExtensions + 1 into tCacheIndex
   end if
   
   # Add callback data to cache
   __extensionPropertySet tCacheIndex, "callback_target", pCallbackObject
   __extensionPropertySet tCacheIndex, "callback_handler", pCallbackMessage
   __extensionPropertySet tCacheIndex, "name", "New Extension"
   
   # AL-2015-03-06: [[ Bug 14820 ]] Set the type so that the icon is correct while downloading
   __extensionPropertySet tCacheIndex, "type", pType
   return tCacheIndex for value
end __extensionDownloadBegin

private command __extensionUpdateUIWithPackage pCacheIndex, pPath
   # Get initial name from file
   set the itemdel to "."
   local tName
   put pPath into tName
   delete the last item of tName
   repeat while the last item of tName is a number
      delete the last item of tName
   end repeat
   __extensionPropertySet pCacheIndex, "name", tName
   
   # Send update to refresh UI with new package installation
   doExtensionsChanged
end __extensionUpdateUIWithPackage

# Download the extension
private command __extensionDownload pCacheIndex
   # Check the file extension is correct
   local tURL
   put __extensionPropertyGet(pCacheIndex,"package_url") into tURL
   
   set the itemdel to "."
   if the last item of tURL is not "lce" then 
      return __extensionError(pCacheIndex, \
            "The package must have the file extension 'lce':" && tURL)
   end if
   
   local tPackageFilePath
   set the itemdel to "/"
   put the last item of tURL into tPackageFilePath
   
   __extensionPropertySet pCacheIndex, "download_package_path", revIDESpecialFolderPath("downloading extensions") & slash & tPackageFilePath
   __extensionPropertySet pCacheIndex, "status", "downloading"
   __extensionPropertySet pCacheIndex, "progress_message", "Downloading"
   __extensionPropertySet pCacheIndex, "progress", 0
   __extensionPropertySet pCacheIndex, "label", tPackageFilePath
   __extensionPropertySet pCacheIndex, "downloaded_from_store", true
   
   __extensionUpdateUIWithPackage pCacheIndex, tPackageFilePath
   
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Downloading", 0
   
   # Download the extension to a file
   libURLDownloadToFile tURL, __extensionPropertyGet(pCacheIndex,"download_package_path"), "extensionDownloaded"
end __extensionDownload

on extensionDownloaded pURL, pDownloadStatus
   __extensionDownloaded pURL, pDownloadStatus
end extensionDownloaded

# Dowload complete
private command __extensionDownloaded pURL, pDownloadStatus
   # Get the index of the extension
   local tCacheIndex
   
   put __extensionCacheID("package_url", pURL) into tCacheIndex
   
   # Update progress
   __extensionSendProgressUpdate tCacheIndex, "Download Complete", 100
   
   local tPath
   put __extensionPropertyGet(tCacheIndex,"download_package_path") into tPath
   revIDEExtensionInstall tPath
end __extensionDownloaded

# Verify extension package is valid
private command __extensionDownloadVerify pCacheIndex
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Verifying extension", 0
   
   # Get the path to the extension
   local tExtensionPath
   put __extensionPropertyGet(pCacheIndex, "download_package_path") into tExtensionPath
   
   # Check the package exists
   if there is not a file tExtensionPath then 
      return __extensionError(pCacheIndex, \
            "Package does not exist: " && tExtensionPath)
   end if
   
   # Check the file extension is valid
   set the itemdel to "."
   if the last item of tExtensionPath is not "lce" then 
      return __extensionError(pCacheIndex, "The package extension '" & \
            the last item of tExtensionPath&"' is not valid." && \
            " Must be 'lce'.")
   end if
   
   # Ensure the zip contains the things we expect
   local tManifestDataA
   extensionValidateLCEPackage tExtensionPath, tManifestDataA
   if the result is not empty then
      return the result
   end if
   
   repeat for each key tKey in tManifestDataA
      __extensionPropertySet pCacheIndex, tKey, tManifestDataA[tKey]
   end repeat
   
   # Build the type ID from the name and version
   __extensionPropertySet pCacheIndex, "type_id", \
         tManifestDataA["name"] & "." & tManifestDataA["version"]
end __extensionDownloadVerify

private command __extensionInstall pCacheIndex, pPackage
   local tName, tTypeId, tInstallPath
   put __extensionPropertyGet(pCacheIndex, "name") into tName
   put __extensionPropertyGet(pCacheIndex, "type_id") into tTypeId
   put revIDESpecialFolderPath("user extensions") & slash & tTypeId into tInstallPath
   revIDEEnsurePath tInstallPath
   
   __extensionInstallRemoveOlderVersions pCacheIndex, tName, 15
   __extensionInstallExtract pCacheIndex, tInstallPath, tTypeID, pPackage, 30
   __extensionInstallCopyInterfaceFile pCacheIndex, tName, tInstallPath, 50
   __extensionInstallLoad pCacheIndex, tName, tInstallPath, 80
   __extensionInstallFinalise pCacheIndex, tTypeID
end __extensionInstall

on __extensionInstallRemoveOlderVersions pCacheIndex, pName, pProgress
   __extensionSendProgressUpdate pCacheIndex, "Removing older versions", pProgress
   
   repeat for each key tCacheIndex in sExtensions
      if tCacheIndex is pCacheIndex then next repeat
      if sExtensions[tCacheIndex]["name"] is pName then
         revIDEExtensionUninstall tCacheIndex
      end if
   end repeat
end __extensionInstallRemoveOlderVersions

private command __extensionPackageExtract pPackage, pTargetFolder
   # Extract the icon,docs and executable module into the folder
   revZipOpenArchive pPackage, "read"
   
   # Work out the root of the zip
   local tZipItems, tZipRoot
   put revZipEnumerateItems(pPackage) into tZipItems
   if the last char of line 1 of tZipItems is "/" then
      put line 1 of tZipItems into tZipRoot
   else
      put empty into tZipRoot
   end if
   
   # Extract all the files
   local tDirectory
   set the itemdel to slash
   repeat for each line tFile in tZipItems
      put pTargetFolder & slash & item 1 to -2 of tFile into tDirectory
      revIDEEnsurePath(tDirectory)
      revZipExtractItemToFile pPackage, tFile, pTargetFolder & slash & tFile
   end repeat 
   
   revZipCloseArchive pPackage
end __extensionPackageExtract

# Extract the extension files
private command __extensionInstallExtract pCacheIndex, pFinalPath, pTypeId, pPackage, pProgress
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Extracting extension", pProgress
   
   __extensionPropertySet pCacheIndex, "install_path", pFinalPath 
   
   # Extract into final directory
   __extensionPackageExtract pPackage, pFinalPath
end __extensionInstallExtract

private command __extensionInstallCopyInterfaceFile pCacheIndex, pName, pInstallFolder, pProgress
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Copying interface file", pProgress
   
   # AL-2015-03-15: [[ Bug 15008 ]] Move interface file to interface folder
   local tInterfaceFile, tInterfacePath
   put pName & ".lci" into tInterfaceFile
   put pInstallFolder & slash & tInterfaceFile into tInterfacePath
   
   if there is a file tInterfacePath then
      local tTargetFolder
      put revIDESpecialFolderPath("user extensions") & slash & \
            "interface" into tTargetFolder
      revIDEEnsurePath tTargetFolder
      revCopyFile tInterfacePath, tTargetFolder & slash & tInterfaceFile
   end if
end __extensionInstallCopyInterfaceFile

private command __extensionInstallLoad pCacheIndex, pName, pInstallFolder, pProgress
   local tFolderData
   extensionFindInFolder pInstallFolder, true, false, tFolderData
   if tFolderData is empty then
      throw "extension missing from" && pInstallFolder
   end if
   
   local tDataA
   put tFolderData[pName][pInstallFolder] into tDataA["copies"][1]
   
   -- add any previously cached info
   union tDataA["copies"][1] with sExtensions[pCacheIndex] recursively
   
   local tExisting
   repeat for each key tExtensionID in sExtensions
      if tExtensionID is pCacheIndex then next repeat
      if sExtensions[tExtensionID]["name"] is pName then
         put sExtensions[tExtensionID]["copies"] into tExisting
      end if
   end repeat
   
   repeat for each key tKey in tExisting
      put tExisting[tKey] into tDataA["copies"][tKey + 1]
   end repeat
   
   __extensionLoad pName, tDataA
end __extensionInstallLoad

# Delete installation files and original package
on __extensionInstallFinalise pCacheIndex, pTypeId
   # Delete temp package file
   if __extensionPropertyGet(pCacheIndex, "downloaded_from_store") then
      # Update progress
      __extensionSendProgressUpdate  pCacheIndex, "Removing temp files", 90
      local tTempInstallPackage
      put revIDESpecialFolderPath("downloading extensions") & slash & \
            pTypeId & ".lce" into tTempInstallPackage
      if there is a file tTempInstallPackage then
         revDeleteFile tTempInstallPackage
      end if
   end if
   
   # Update the cache
   __extensionSendProgressUpdate  pCacheIndex, "Complete", 100
   __extensionPropertySet pCacheIndex, "status", "installed"
   
   # Notify palettes
   __extensionsChanged
end __extensionInstallFinalise

##############################
# PRIVATE UNINSTALL
##############################

# Check if the widget to be uninstalled is in use
private command __extensionUninstallCheckInUse pCacheIndex, pProgress
   # Update progress
   if pCacheIndex is not a number then return __extensionError(pCacheIndex, "Could not remove extension '" & pCacheIndex & "' because it is not a valid index")
   
   __extensionSendProgressUpdate pCacheIndex, "Checking if extension is in use", pProgress
end __extensionUninstallCheckInUse

# Unload the extension
private command __extensionUninstallUnload pCacheIndex, pName, pProgress
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Unloading extension", pProgress
   
   revIDEExtensionUnload pName
end __extensionUninstallUnload

# Delete the files associated to the extension
private command __extensionUninstallDeleteFiles pCacheIndex, pName, pInstallPath, pProgress
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Deleting extension files", pProgress
   
   # Make sure the path contains the folder extension as a check before deleting a folder
   if pInstallPath begins with revIDESpecialFolderPath("user extensions") then
      revDeleteFolder pInstallPath
   end if
   
   # AL-2015-03-15: [[ Bug 15008 ]] Delete interface file from interface folder
   local tInterfaceFile
   put pName & ".lci" into tInterfaceFile
   if there is a file (revIDESpecialFolderPath("user extensions") & slash & "interface" & slash & tInterfaceFile) then
      revDeleteFile revIDESpecialFolderPath("user extensions") & slash & "interface" & slash & tInterfaceFile
   end if
end __extensionUninstallDeleteFiles

private command __extensionUninstallDeletePreferences pCacheIndex, pName, pProgress
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Deleting preferences", pProgress
   
   revIDEDeletePreferenceSet pName
end __extensionUninstallDeletePreferences

private command __extensionUnload pCacheIndex, pName, pProgress
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Unloading extension", pProgress
   
   revIDEExtensionUnload pName
end __extensionUnload

private command __extensionUninstallComplete pCacheIndex
   # Notify IDE uninstallation complete
   __extensionSendProgressUpdate pCacheIndex, "Complete", 100
   delete variable sExtensions[pCacheIndex]
end __extensionUninstallComplete

##############################
# PRIVATE SHARED
##############################
private command __ProcessInspectorMetadata @xMetadataA
   repeat for each key tKey in xMetadataA
      local tLabel, tSection
      if xMetadataA[tKey]["section"] is empty then
         put "Basic" into xMetadataA[tKey]["section"]
      end if
      
      if xMetadataA[tKey]["label"] is empty then
         put tKey into xMetadataA[tKey]["label"]
      end if
      
      # Process value options, default and delimiter
      replace comma with return in xMetadataA[tKey]["options"]
      replace "\n" with return in xMetadataA[tKey]["delimiter"]
      if xMetadataA[tKey]["default"] is not empty then
         replace "\n" with return in xMetadataA[tKey]["default"]
      end if
      
      if xMetadataA[tKey]["user_visible"] is empty then
         put true into xMetadataA[tKey]["user_visible"]
      end if
      
      if xMetadataA[tKey]["properties"] is not empty then
         -- If there is a 'properties' value, delete the key
         -- and replace it with that value
         local tInfo, tNewKey
         put xMetadataA[tKey] into tInfo
         put tInfo["properties"] into tNewKey
         delete variable xMetadataA[tKey]
         delete variable tInfo["properties"]
         put tInfo into xMetadataA[tNewKey]
      end if
   end repeat
end __ProcessInspectorMetadata

private function __extensionPropertyInfoFromManifest pId, pManifestPath
   if not there is a file pManifestPath then return empty
   # Create the XML tree
   local tXMLTree, tProperties, tExtensionData, tPropertyNodes
   put revXMLCreateTreeFromFile(pManifestPath,true,true,false) into tXMLTree
   
   put revXMLChildNames(tXMLTree,"package",return,"property",true) into tPropertyNodes
   
   local tCacheID
   put __extensionCacheID("name", pID) into tCacheId
   
   local tPropertyNames, tPropertyXMLData, tPropNameList, tMaxOrder
   repeat for each line tPropertyNode in tPropertyNodes      
      local tName
      put revXMLAttribute(tXMLTree,"package" & "/" & tPropertyNode,"name") into tName
      put __extensionPropertyGet(tCacheId, tName) into tPropertyXMLData[tName]["data"]
      put revXMLAttribute(tXMLTree,"package" & "/" & tPropertyNode,"set") into \
            tPropertyXMLData[tName]["set"]
      put revXMLAttribute(tXMLTree,"package" & "/" & tPropertyNode,"get") into \
            tPropertyXMLData[tName]["get"]
      put tName into tPropNameList[tPropertyNode]
      put max(tMaxOrder, tPropertyXMLData[tName]["data"]["order"]) into tMaxOrder
   end repeat
   
   -- Sort by ordered props, then by order of appearance
   repeat for each line tPropertyNode in tPropertyNodes
      if tPropertyXMLData[tPropNameList[tPropertyNode]]["data"]["order"] \
            is empty then
         add 1 to tMaxOrder 
         put tMaxOrder into tPropertyXMLData[tPropNameList[tPropertyNode]]["data"]["order"]
      end if
   end repeat
   
   put the keys of tPropertyXMLData into tPropertyNames
   sort tPropertyNames by tPropertyXMLData[each]["data"]["order"]
   
   local tPropertyDataA
   repeat for each line tProperty in tPropertyNames
      local tIDEPropertyInfo, tPropertyInfoA
      put tPropertyXMLData[tProperty]["data"] into tPropertyInfoA
      put revIDEPropertyInfo(tProperty) into tIDEPropertyInfo
      if tIDEPropertyInfo is not empty then
         union tPropertyInfoA with tIDEPropertyInfo
         put tPropertyInfoA into tPropertyDataA[tProperty]
      else
         put tPropertyInfoA into tPropertyDataA[tProperty]
      end if
      
      local tReadOnly, tSetter
      put tPropertyXMLData[tProperty]["set"] into tSetter
      if tSetter is empty or tSetter begins with "xmlerr" then
         put true into tReadOnly
      else
         put false into tReadOnly
      end if
      put tReadOnly into tPropertyDataA[tProperty]["read_only"]
      
      if tPropertyDataA[tProperty]["editor"] is empty then
         local tType
         put tPropertyXMLData[tProperty]["get"] into tType
         if tType is "Integer" or tType is "Real" then
            put "com.livecode.pi.number" into tPropertyDataA[tProperty]["editor"]
         else
            put "com.livecode.pi." & tolower(tType) into tPropertyDataA[tProperty]["editor"]
         end if
      end if
      # Tag the property as a widget property, so we can order them 
      # correctly after the built-in props for the given section
      put true into tPropertyDataA[tProperty]["widget_prop"]
   end repeat
   
   # Fetch property override metadata
   local tMetadataValue, tMetadataKey
   local tMetadataNodes, tMetadataA, tDataA
   put revXMLChildNames(tXMLTree, "package",return,"metadata",true) into tMetadataNodes
   repeat for each line tMetadata in tMetadataNodes
      put revXMLAttribute(tXMLTree,"package" & "/" & tMetadata,"key") into tMetadataKey
      put revXMLNodeContents(tXMLTree,"package" & "/" & tMetadata) into tMetadataValue
      if tMetadataValue is empty or tMetadataValue begins with "xmlerr" then
         put empty into tMetadataValue
      end if
      __SetMetadata tMetadataKey, tMetadataValue, tDataA
   end repeat
   
   repeat for each key tProperty in tDataA
      if tPropertyXMLData[tProperty] is not empty then
         next repeat
      end if
      local tIDEPropInfoA
      put revIDEPropertyInfo(tProperty) into tIDEPropInfoA
      if tIDEPropInfoA is not empty then
         # if this is a control property that we are overriding,
         # tData might be non-empty for the property even though
         # there was no property node in the XML
         union tPropertyDataA[tProperty] with tDataA[tProperty]
         
         # Now take any default property info that was not specified
         # in the manifest
         union tPropertyDataA[tProperty] with tIDEPropInfoA
      end if
   end repeat
   
   __ProcessInspectorMetadata tPropertyDataA
   
   revXMLDeleteTree tXMLTree
   return tPropertyDataA
end __extensionPropertyInfoFromManifest

command revIDEExtensionSetInfo pTypeID
   set the itemdelimiter to slash
   
   # Get the internal cache ID
   local tCacheIndex
   put __extensionCacheID("name", pTypeID) into tCacheIndex
   
   # Get the target folder
   local tFolder
   put __extensionPropertyGet(tCacheIndex, "install_path") into tFolder
   
   # Get information from the download package path if the manifest was not found
   if tFolder is empty then
      put item 1 to -2 of __extensionPropertyGet(tCacheIndex, "download_package_path") into tFolder
   end if
   
   local tManifest
   put tFolder & slash & "manifest.xml" into tManifest
   if there is not a file tManifest then 
      exit revIDEExtensionSetInfo
   end if
   
   __extensionSetExtensionInfoFromManifest tCacheIndex, tManifest
   __extensionSetPropertyInfoFromManifest pTypeID, tManifest
   
   # Set the default name
   local tTitle
   put __extensionPropertyGet(tCacheIndex, "title") into tTitle
   put tTitle into sExtensionProperties[pTypeID]["name"]["default"]
   
end revIDEExtensionSetInfo

private command __extensionSetExtensionInfoFromManifest pCacheIndex, pManifestPath
   local tDataA
   revIDEExtensionFetchMetadata pManifestPath, tDataA
   
   repeat for each key tKey in tDataA
      __extensionPropertySet pCacheIndex, tKey, tDataA[tKey]
   end repeat
end __extensionSetExtensionInfoFromManifest

private command __extensionSetPropertyInfoFromManifest pID, pManifest
   local tPropertyInfo
   put __extensionPropertyInfoFromManifest(pId, pManifest) into tPropertyInfo
   put tPropertyInfo into sExtensionProperties[pID]
end __extensionSetPropertyInfoFromManifest

private function __extensionError pCacheIndex, pErrorMessage
   __extensionSendProgressUpdate pCacheIndex, "Error:" && pErrorMessage, 100
   return pErrorMessage
end __extensionError

# Send notication that widget has been added/removed
on doExtensionsChanged
   ideMessageSend "ideExtensionsChanged"
end doExtensionsChanged

local sExtensionsChangedMsg
private command __extensionsChanged
   if sExtensionsChangedMsg is not empty then
      cancel sExtensionsChangedMsg
   end if
   send "doExtensionsChanged" to me in 10 millisecs
   put the result into sExtensionsChangedMsg
end __extensionsChanged

# Sent progress update on installation of widget
on __extensionSendProgressUpdate pCacheIndex, pMessage, pProgress
   # Get progress information for extension
   __extensionPropertySet pCacheIndex, "progress_message", pMessage
   __extensionPropertySet pCacheIndex, "progress", pProgress
   
   local tName
   put __extensionPropertyGet(pCacheIndex, "name") into tName
   ideMessageSend "ideExtensionStatusChanged", (tName & comma & pMessage & comma & pProgress)
end __extensionSendProgressUpdate

private function __fetchExtensionManifestData pFolder, pExtFile
   local tDataA
   revIDEExtensionFetchMetadata pFolder & slash & "manifest.xml", tDataA
   # If we couldn't fetch a type id, or there was no manifest then the result will not be empty
   if the result is not empty then
      put "Invalid manifest" into tDataA["error"]
      put "error" into tDataA["status"]
   end if
   return tDataA
end __fetchExtensionManifestData

private command __extensionAddDependenciesToRequiresArray \
         pExtension, @xRequiresA, @xExtensions

   local tDependentsA
   put revIDEExtensionProperty(pExtension, "requires") into tDependentsA

   repeat for each element tElement in tDependentsA
      if tElement is not among the keys of xRequiresA then
         __extensionAddDependenciesToRequiresArray \
               tElement, xRequiresA, xExtensions
      end if
      addToList tElement, xRequiresA[pExtension]
   end repeat

   put empty into xExtensions[pExtension]
end __extensionAddDependenciesToRequiresArray

function revIDEExtensionsOrderByDependency pExtensions
   # Accumulate an array of dependencies
   local tRequiresA, tExtensions
   repeat for each line tExtension in pExtensions
      __extensionAddDependenciesToRequiresArray \
            tExtension, tRequiresA, tExtensions
   end repeat
   
   return extensionOrderByDependency(the keys of tExtensions, tRequiresA)
end revIDEExtensionsOrderByDependency

private function isUserExtension pData
   if pData["ide"] then 
      return 1
   end if
   return 0
end isUserExtension

private command addToList pElement, @xArray
   put pElement into xArray[the number of elements in xArray + 1]
end addToList

on __extensionsLoad
   local tDataA   
   # Fetch all the available data about extensions in the search paths
   local tFoldersA, tExtensionFolder
   put revIDEExtensionFolders() into tFoldersA
   repeat for each key tKey in tFoldersA
      put tFoldersA[tKey] into tExtensionFolder
      repeat for each line tFolder in folders(tExtensionFolder)
         if tFolder begins with "." then next repeat
         if tFolder is among the items of "downloading,temp,uninstalled" then next repeat
         local tExtFolder
         put tExtensionFolder & slash & tFolder into tExtFolder
         extensionFindInFolder tExtFolder, tKey is "user", true, tDataA
      end repeat
   end repeat
   
   # Now loop through, checking the status of them
   local tExtensionsList, tExtensionsA, tExtensionCount, tExtensionCopyCount, tExtensionDataA
   put the keys of tDataA into tExtensionsList
   sort tExtensionsList
   
   local tToLoadA, tDependentsA, tRequiresA
   set the itemdel to ","
   put 1 into tExtensionCount
   repeat for each line tTypeID in tExtensionsList
      put 1 into tExtensionCopyCount
      local tCopyFolders
      put the keys of tDataA[tTypeID] into tCopyFolders
      -- give priority to user extensions. If there are multiple
      -- then further resolve by alphabetical order of full filename
      sort tCopyFolders
      sort tCopyFolders ascending numeric by isUserExtension(tDataA[tTypeID][each])
      repeat for each key tFolder in tDataA[tTypeID]
         put tDataA[tTypeID][tFolder] into tExtensionDataA["copies"][tExtensionCopyCount]
         put tFolder into tExtensionDataA["copies"][tExtensionCopyCount]["install_path"]
         add 1 to tExtensionCopyCount
      end repeat
      put tExtensionDataA into tToLoadA[tTypeID]
      
      put tExtensionDataA["copies"][1]["requires"] into tDependentsA
      repeat for each element tElement in tDependentsA
         addToList tElement, tRequiresA[tTypeId]
      end repeat
      put empty into tExtensionDataA
   end repeat
   
   local tLoadOrder
   put extensionOrderByDependency(tExtensionsList, tRequiresA) into \
         tLoadOrder
   
   repeat for each line tLine in tLoadOrder
      # Extension utils is explicitly loaded
      if tLine is kExtensionUtils then
         next repeat
      end if
      __extensionLoad tLine, tToLoadA[tLine]
   end repeat
end __extensionsLoad

# Calls Weservice and returns updates
function __extensionUpdates
end __extensionUpdates

# Returns the ID of the internal array given the extension typeID
private function __extensionCacheID pPropertyToSearch, pValue
   repeat for each key tExtensionID in sExtensions
      if sExtensions[tExtensionID][pPropertyToSearch] is pValue then
         return tExtensionID
      end if
   end repeat
end __extensionCacheID

private command __extensionCacheRemove pIndex
   delete variable sExtensions[pIndex]
end __extensionCacheRemove

# Gets a property from the internal extension cache
function __extensionPropertyGet pCacheIndex, pProperty
   return sExtensions[pCacheIndex][pProperty]
end __extensionPropertyGet

# Sets a property in the internal extension cache
on __extensionPropertySet pCacheIndex, pProperty, pValue
   put pValue into sExtensions[pCacheIndex][pProperty]
end __extensionPropertySet

# Loads an extension
private command __extensionLoad pID, pExtensionDataA
   local tLoadedDataA, tToLoadA
   # Only try to load the first copy in the load order
   put pExtensionDataA["copies"][1] into tToLoadA
   
   local tFolder, tVersion, tStatus, tError, tIDEExtension, tSourceFile, tSourceType
   put tToLoadA["install_path"] into tFolder
   put tToLoadA["version"] into tVersion
   put tToLoadA["status"] into tStatus
   put tToLoadA["error"] into tError
   put tToLoadA["ide"] into tIDEExtension
   put tToLoadA["source_file"] into tSourceFile
   put tToLoadA["source_type"] into tSourceType
   revIDEExtensionLoad tSourceType, pID, tFolder, tVersion, tStatus, \
         tError, tIDEExtension, tSourceFile, tToLoadA, true
end __extensionLoad

private command __MapCodeLibraryForIDE pFolder
   local tLibraries
   if revEnvironmentIsInstalled() and \
         pFolder begins with revEnvironmentToolsPath() and \
         the platform is "MacOS" then
      -- special case bundled extensions must load code from within MacOS dir
      -- the libs to load should be in Contents/MacOS/<extension>/
      local tExtension
      set the itemDelimiter to slash
      put item -2 of pFolder into tExtension
      
      put files(specialFolderPath("engine") & "/" & tExtension) & return & \
            folders(specialFolderPath("engine") & "/" & tExtension) into tLibraries
      filter tLibraries without ".*"
      
      if tLibraries is not empty then
         set the itemDelimiter to "."
         repeat for each line tLibrary in tLibraries
            -- remove extension
            delete the last item of tLibrary
            if tLibrary is not empty then
               set the revLibraryMapping[tLibrary] to "./" & tExtension & "/" & tLibrary
               return empty
            end if
         end repeat
      end if
   end if
   
   -- code folders should be platform ID triples however for the
   -- time being as we have no way to access the data required to 
   -- determine the options section of the platform ID so we filter only
   -- arch and platform and hope for the best. Ideally we would have
   -- access to a build options string and give a complete match precedence.
   local tCodeFolders
   put folders(pFolder) into tCodeFolders
   switch the platform
      case "MacOS"
         filter tCodeFolders with "*-mac*"
         break
      case "Win32"
         filter tCodeFolders with "*-win32*"
         break
      default
         filter tCodeFolders with "*-"& toLower(the platform) & "*"
         break
   end switch
   
   local tFilteredCodeFolders
   filter tCodeFolders with the processor & "-*" into tFilteredCodeFolders
   split tFilteredCodeFolders by return as set
   if the platform is "MacOS" then
      -- explicit processor should take precedence over universal builds but
      -- in the event multiple libraries are included and some are universal
      -- we must merge
      local tUniveralFilteredCodeFolders
      filter tCodeFolders with "universal-*" into tUniveralFilteredCodeFolders
      split tUniveralFilteredCodeFolders by return as set
      union tFilteredCodeFolders with tUniveralFilteredCodeFolders
   end if
   
   repeat for each key tFolder in tFilteredCodeFolders
      put files(pFolder & "/" & tFolder) & return & \
            folders(pFolder & "/" & tFolder) into tLibraries
      filter tLibraries without ".*"
      
      if tLibraries is not empty then
         set the itemDelimiter to "."
         repeat for each line tLibrary in tLibraries
            -- remove extension
            delete the last item of tLibrary
            if tLibrary is not empty then
               set the revLibraryMapping[tLibrary] to pFolder & "/" & tFolder & "/" & tLibrary
            end if
         end repeat
      end if
   end repeat
end __MapCodeLibraryForIDE

private command __LoadExtension pCacheIndex, pExtensionType, pSourceType, \
      pSourceFile, pFolder, pStatus, @xError
   revInternal__Log "Message", the params
   if xError is empty then
      local tFileToLoad
      if not __extensionNeedsLoad(pExtensionType) then
         put "installed" into pStatus
      else
         if pSourceType is "lcb" then
            local tResources, tModule, tCode
            put revIDEExtensionBytecodeFilename(true) into tFileToLoad
            put pFolder & slash & tFileToLoad into tModule
            if there is no file tModule then
               put revIDEExtensionBytecodeFilename(false) into tFileToLoad
               put pFolder & slash & tFileToLoad into tModule
            end if
            put pFolder & slash & "resources" into tResources
            put pFolder & slash & "code" into tCode
            # map code before loading extension
            if there is a folder tCode then
               __MapCodeLibraryForIDE tCode
            end if
            # If we have a resources folder then load with resource path
            if there is a folder tResources then
               load extension from file tModule with resource path tResources
            else
               load extension from file tModule
            end if
         else
            set the itemdelimiter to "."
            revInternal__LoadLibrary item 1 of pSourceFile, pFolder & slash & pSourceFile
            put pSourceFile into tFileToLoad
         end if
         if the result is not empty then
            put toUpper(char 1 of the result) & \
                  char 2 to -1 of the result into xError
            put "error" into pStatus
         else
            put "installed" into pStatus
         end if
      end if
   end if
   __extensionPropertySet pCacheIndex, "status", pStatus
   __extensionPropertySet pCacheIndex, "error", xError
   __extensionPropertySet pCacheIndex, "file", tFileToLoad
   __extensionsChanged
end __LoadExtension

private command __revIDELCBExtensionLoad pID, pFolder, pVersion, pStatus, \
      pError, pIsIDEExtension, pSourceFile, pAdditionalInfoA, pIsStartup
   # Find entry in the cache if it exists
   local tCacheIndex
   put __extensionCacheID("install_path", pFolder) into tCacheIndex
   
   # If no entry is in the cache, create one
   if tCacheIndex is not a number then
      put the number of elements of sExtensions + 1 into tCacheIndex
      __extensionPropertySet tCacheIndex, "install_path", pFolder
   end if
   
   local tSupportFiles
   put pAdditionalInfoA["support_files"] into tSupportFiles
   local tLoadOnStartup
   if pError is empty then
      put pAdditionalInfoA["_ide"] is true or \
            revIDEExtensionGetLoadOnStartup(pID) into tLoadOnStartup
   end if
   if not pIsStartup or tLoadOnStartup is not false then
      __LoadExtension tCacheIndex, pAdditionalInfoA["type"], "lcb", pSourceFile, \
         pFolder, pStatus, pError
      -- If we have an error loading, try to recompile the extension
      if pError is not empty then
         if not pIsIDEExtension and pSourceFile is not empty then
            revIDEExtensionCompile pFolder, pSourceFile, tSupportFiles, pFolder, \
                  revIDEExtensionBytecodeFilename(true)
            if the result is empty then
               local tNewError
               __LoadExtension tCacheIndex, pAdditionalInfoA["type"], "lcb", \
                  pSourceFile, pFolder, pStatus, tNewError
               put tNewError into pError
            end if
         end if
      end if
   else
      __extensionPropertySet tCacheIndex, "status", "unloaded" 
   end if
   
   # Update name, status, error, and whether the extension comes with the IDE
   __extensionPropertySet tCacheIndex, "name", pID
   __extensionPropertySet tCacheIndex, "type_id", pID  & "." & pVersion 
   __extensionPropertySet tCacheIndex, "ide", pIsIDEExtension
   __extensionPropertySet tCacheIndex, "source_file", pSourceFile
   __extensionPropertySet tCacheIndex, "source_type", "lcb"
   __extensionPropertySet tCacheIndex, "support_files", tSupportFiles
   
   # Check for sample stacks
   __extensionPropertySet tCacheIndex, "samples", __extensionSampleStacks(pID,pFolder)
   
   # Store the extension's metadata
   revIDEExtensionSetInfo pID
   
   local tUserVisiblePref
   put revIDEGetPreferenceOfSet(pID, "uservisible") into tUserVisiblePref
   if tUserVisiblePref is not empty then
      __extensionPropertySet tCacheIndex, "uservisible", tUserVisiblePref
   end if
   
   # Deal with the various icon possibilities
   if sExtensionProperties[pID]["svgicon"] is empty then
      local tIconPath
      put pFolder & "/support/icon.png" into tIconPath
      if there is a file tIconPath then
         __extensionPropertySet tCacheIndex, "icon", tIconPath
      end if
   end if
   
   # Load the default script if there is one
   local tDefaultScript
   put revIDEExtensionFetchDefaultScript(pFolder, pID, true) into tDefaultScript
   __extensionPropertySet tCacheIndex, "defaultScript", tDefaultScript
   
   # Generate extension API from source if there is not one present in the folder
   # Don't do in an installed IDE as we might not be able to generate the files in the appropriate location
   if not revEnvironmentIsInstalled() and not there is a file (pFolder & slash & "api.lcdoc") then
      revIDEExtensionUpdateAPI pFolder, pSourceFile
   end if
   
   return pError
end __revIDELCBExtensionLoad

private command addToStringList @xList, pValue, pDel
   if pDel is empty then put return into pDel
   if xList is empty then
      put pValue into xList
   else
      put pDel & pValue after xList
   end if
end addToStringList

private function __UseTypeToKey pUseType
   switch pUseType
      case "android permission"
         return "android.permissions"
      case "android feature"
         return "android.features"
   end switch
end __UseTypeToKey

private function __extensionHasID pType
   switch pType
      case "snippet"
         return false
      default
         return true
   end switch
end __extensionHasID

private function __extensionNeedsLoad pType
   switch pType
      case "snippet"
      case "sample"
         return false
      default
         return true
   end switch
end __extensionNeedsLoad

private command __revIDELCSExtensionLoad pFullPath, pFolder, pVersion, pStatus, \
      pError, pIsIDEExtension, pSourceFile, pAdditionalInfoA, pIsStartup
   
   # Find entry in the cache if it exists
   local tCacheIndex
   put __extensionCacheID("install_path", pFolder) into tCacheIndex
   
   # If no entry is in the cache, create one
   if tCacheIndex is not a number then
      put the number of elements of sExtensions + 1 into tCacheIndex
      __extensionPropertySet tCacheIndex, "install_path", pFolder
   end if
   
   if pAdditionalInfoA is empty then
      put __fetchExtensionManifestData(pFolder, pSourceFile) into pAdditionalInfoA
   end if
   
   local tType
   put pAdditionalInfoA["type"] into tType
   
   # Update name, status, error, and whether the extension comes with the IDE
   local tId
   if __extensionHasID(tType) then
   try
      put the short name of stack (pFolder & slash & pSourceFile) into tId
   catch pError
   end try
   else
      # The manifest should contain an id
      put pAdditionalInfoA["name"] into tId
   end if
   
   local tLoadOnStartup
   if pError is empty and __extensionNeedsLoad(tType) then
      put revIDEExtensionGetLoadOnStartup(tID) into tLoadOnStartup
   end if
   if not pIsStartup or (tLoadOnStartup is not false) then   
      __LoadExtension tCacheIndex, tType, "lcs", pSourceFile, pFolder, pStatus, pError
   else
      __extensionPropertySet tCacheIndex, "status", "unloaded" 
   end if
   
   __extensionPropertySet tCacheIndex, "name", tId
   __extensionPropertySet tCacheIndex, "type_id", tId  & "." & pVersion 
   
   __extensionPropertySet tCacheIndex, "author", pAdditionalInfoA["author"]
   __extensionPropertySet tCacheIndex, "title", pAdditionalInfoA["title"]
   __extensionPropertySet tCacheIndex, "svgicon", pAdditionalInfoA["svgicon"]
   __extensionPropertySet tCacheIndex, "version", pAdditionalInfoA["version"]
   
   repeat for each key tKey in pAdditionalInfoA["uses"]
      local tSettingString
      put empty into tSettingString
      -- store info about settings (android permissions etc)            
      repeat for each element tSetting in pAdditionalInfoA["uses"][tKey]
         addToStringList tSettingString, tSetting, ","
      end repeat
      __extensionPropertySet tCacheIndex, __UseTypeToKey(tKey), tSettingString
   end repeat
   
   __extensionPropertySet tCacheIndex, "source_file", pSourceFile
   __extensionPropertySet tCacheIndex, "ide", pIsIDEExtension
   __extensionPropertySet tCacheIndex, "source_type", "lcs"
   __extensionPropertySet tCacheIndex, "type", pAdditionalInfoA["type"]
   __extensionPropertySet tCacheIndex, "uservisible", true
   __extensionPropertySet tCacheIndex, "support_files", pAdditionalInfoA["support_files"]
   
   # Store the extension's property metadata
   --  revIDEExtensionSetInfo pID
   
   # Deal with the various icon possibilities
   if sExtensionProperties[tID]["svgicon"] is empty then
      local tIconPath
      put pFolder & "/support/icon.png" into tIconPath
      if there is a file tIconPath then
         __extensionPropertySet tCacheIndex, "icon", tIconPath
      end if
   end if
   
   # If this is not startup, then auto-launch snippet or sample stack
   if not pIsStartup then
      if tType is "snippet" then
         revIDEExtensionShowSnippet pFolder & slash & pSourceFile
      else if tType is "sample" then
         revIDEExtensionOpenSample pFolder & slash & pSourceFile
      end if
   end if
   return pError
end __revIDELCSExtensionLoad

command revIDEExtensionReload pTypeId
   local tCacheIndex
   put __extensionCacheID("name", pTypeID) into tCacheIndex
   if tCacheIndex is not a number then
      answer error "Can't reload" && pTypeID & ": restart required"
      exit revIDEExtensionReload
   end if
   local tError, tDataA
   put sExtensions[tCacheIndex] into tDataA
   __LoadExtension tCacheIndex, tDataA["type"], tDataA["source_type"], \
         tDataA["source_file"], tDataA["install_path"], \
         "", tError
   if tError is not empty then
      answer error tError 
   end if
end revIDEExtensionReload

command revIDEExtensionLoad pType, pID, pFolder, pVersion, pStatus, pError, \
      pIDEExtension, pSourceFile, pAdditionalInfoA, pIsStartup
   if pType is "lcb" then
      __revIDELCBExtensionLoad pID, pFolder, pVersion, pStatus, pError, \
            pIDEExtension, pSourceFile, pAdditionalInfoA, pIsStartup
   else if pType is "lcs" then
      __revIDELCSExtensionLoad pID, pFolder, pVersion, pStatus, pError, \
            pIDEExtension, pSourceFile, pAdditionalInfoA, pIsStartup
   end if
end revIDEExtensionLoad

function revIDEExtensionFetchDefaultScript pFolder, pCacheIndex, pValidate
   if there is a stack (pCacheIndex& ".__DefaultScript") then
      return the script of stack (pCacheIndex& ".__DefaultScript")
   end if
   
   local tDefaultScriptPath
   put pFolder & "/support/defaultscript.livecodescript" into tDefaultScriptPath
   
   if there is not a file tDefaultScriptPath then
      return empty
   end if
   
   lock messages
   try
      open stack tDefaultScriptPath
   catch tStackError
      return empty
   end try
   
   local tScript
   if tStackError is empty then
      if pValidate then
         if there is a stack (pCacheIndex& ".__DefaultScript") then
            put the script of stack (pCacheIndex & ".__DefaultScript") into tScript
         end if
      else
         put the script of stack tDefaultScriptPath into tScript
      end if
      delete stack tDefaultScriptPath
   end if
   unlock messages
   
   return tScript
end revIDEExtensionFetchDefaultScript

function __extensionSampleStacks pID, pFolder
   local tSampleFolder, tSamples, tSampleArray
   
   # Get the paths to sample satcks in the bundle
   put pFolder & slash & "samples" into tSampleFolder
   if there is a folder tSampleFolder then
      put files(tSampleFolder) into tSamples
      filter tSamples without ".*"
      repeat for each line tStack in tSamples
         put pFolder & slash & "samples/" & tStack into tSampleArray[tStack] 
      end repeat
   end if
   
   return tSampleArray
end __extensionSampleStacks

##############################
# CALLBACKS
##############################

on extensionUpdateDataReceived
end extensionUpdateDataReceived

-- At the moment, if the extension is of type module then assume
-- it provides an LCB API, and otherwise it provides an LCS API.
private function __TypeToAPI pType
   switch pType
      case "module"
         return "livecode_builder"
         break
      case "plugin"
         return "livecode_ide"
         break
      case "library"
      case "widget"
      default
         return "livecode_script"
         break
   end switch
end __TypeToAPI

function revIDEExtensionDocsData pForAPI
   local tExtensionsA
   put revIDEExtensions("", "installed", true) into tExtensionsA
   local tDataA, tCount
   repeat for each element tExtension in tExtensionsA
      if pForAPI is not empty and \
            __TypeToAPI(tExtension["type"]) is not pForAPI then
         next repeat
      end if
      add 1 to tCount
      put tExtension["install_path"] into tDataA[tCount]["folder"]
      put tExtension["title"] into tDataA[tCount]["title"]
      put tExtension["author"] into tDataA[tCount]["author"]
      put tExtension["source_file"] into tDataA[tCount]["source_file"]      
      put tExtension["source_type"] into tDataA[tCount]["source_type"]
      put tExtension["name"] into tDataA[tCount]["name"]
   end repeat
   return tDataA
end revIDEExtensionDocsData

on revIDEExtensionUpdateAPI pFolder, pExtensionSource
   if pExtensionSource is empty then
      local tFiles
      put files(pFolder) into tFiles
      filter tFiles with "*.lcb"
      if tFiles is empty then exit revIDEExtensionUpdateAPI
      put line 1 of tFiles into pExtensionSource
   end if
   
   # Check timestamps to see if API  is out of date.
   local tNeedUpdate, tError, tSource
   put pFolder & slash & pExtensionSource into tSource
   put revIDEIsFilesetStale(tSource, \
         pFolder & slash & "api.lcdoc", false, tError) into tNeedUpdate
   if tNeedUpdate is empty then put true into tNeedUpdate
   
   if tNeedUpdate then
      local tText
      if there is a stack tSource then
         put the long id of stack tSource into tSource
         put the script of stack tSource into tText
      else
         put textDecode(url("binfile:" & tSource), "utf-8") into tText
      end if
      
      local tAPI
      dispatch function "revDocsGenerateDocsFileFromText" to stack "revDocsParser" with tText, tSource
      put the result into tAPI 
      put textEncode(tAPI, "utf-8") into url ("binfile:" & pFolder & slash & "api.lcdoc")
      return "updated"
   end if
end revIDEExtensionUpdateAPI

command revIDEExtensionCompile pFolder, pFile, pSupportFiles, pTargetFolder, pOutputFilename
   // Make file paths full paths
   repeat with tLine = 1 to the number of lines in pSupportFiles
      put pFolder & slash before line tLine of pSupportFiles
   end repeat
   put pFolder & slash before pFile
   
   extensionCompile "", pFile, pSupportFiles, "", \
         revIDESpecialFolderPath("user extensions") & slash & \
         "interface", pTargetFolder, pOutputFilename
   
   if the result is not empty then
      return the result for error
   end if
   return it for value
end revIDEExtensionCompile

command revIDEExtensionMetadata pFolder, pFile, pType, @rDataA
   local tDataA, tResult
   revIDEExtensionFetchMetadata pFolder & slash & "manifest.xml", tDataA
   put the result into tResult
   
   put tDataA into rDataA
   return tResult
end revIDEExtensionMetadata

private command __SetMetadata pKey, pValue, @xArray
   split pKey by "."
   put pValue into xArray[pKey]
end __SetMetadata

private command revIDEExtensionFetchMetadata pManifestPath, @rDataA
   local tDataA
   put extensionFetchMetadata(pManifestPath) into tDataA
   if the result is not empty then
      return the result
   end if
   
   # Make sure 'inspector' style metadata is processed
   __ProcessInspectorMetadata tDataA["standaloneSettings"]
   
   put tDataA into rDataA
   return empty
end revIDEExtensionFetchMetadata

function revIDEExtensionFileData pID 
   # Get the internal cache index
   local tCacheIndex
   put __extensionCacheID("name", pID) into tCacheIndex
   
   local tSourceType, tFolder, tFile
   put __extensionPropertyGet(tCacheIndex, "install_path") into tFolder
   put __extensionPropertyGet(tCacheIndex, "source_type") into tSourceType
   put __extensionPropertyGet(tCacheIndex, "file") into tFile
   
   local tDataA
   put tSourceType into tDataA["type"]
   put tFolder & slash & tFile into tDataA["file"]
   return tDataA
end revIDEExtensionFileData

private command __UnloadExtension pCacheIndex, pSourceType, pSourceFile, pTypeId
   local tError, tStatus
   if pSourceType is "lcb" then
      unload extension pTypeId
   else
      set the itemdelimiter to "."
      revInternal__UnloadLibrary item 1 of pSourceFile
   end if
   if the result is not empty then
      put toUpper(char 1 of the result) & \
            char 2 to -1 of the result into tError
      put "error" into tStatus
   else
      put "unloaded" into tStatus
   end if
   
   __extensionPropertySet pCacheIndex, "status", tStatus
   __extensionPropertySet pCacheIndex, "error", tError
   __extensionsChanged
end __UnloadExtension

command revIDEExtensionUnload pKind
   local tCacheIndex
   put __extensionCacheID("name", pKind) into tCacheIndex
   
   local tDataA
   put sExtensions[tCacheIndex] into tDataA
   __UnloadExtension tCacheIndex, tDataA["source_type"], \
         tDataA["source_file"], pKind
end revIDEExtensionUnload

function revIDEExtensionLibraryHandlers pLibraryID
   local tCacheIndex
   put __extensionCacheID("name", pLibraryID) into tCacheIndex
   
   return __extensionPropertyGet(tCacheIndex, "handlers")
end revIDEExtensionLibraryHandlers

command revIDEExtensionIconFromType pType, pID, @rIconName, @rIconPath         
   put revIDEExtensionProperty(pID, "svgIcon") into rIconPath
   switch pType
      case "widget"
         put "wrench" into rIconName
         break
      case "library"
         put "book" into rIconName
         break
      case "external"
         put "external link" into rIconName
         break
      case "inclusion"
      case "resource"
         put "puzzle piece" into rIconName
         break
      case "database driver"
         put "database" into rIconName
         break
      case "script library"
         put "file text alt" into rIconName
         break
      default
         put "circle" into rIconName
         break
   end switch
end revIDEExtensionIconFromType

command revIDEExtensionShowSnippet pSourceFile
   local tSnippet
   put revIDEUTF8FileContents(pSourceFile) into tSnippet
   lock screen
   revIDEOpenPalette("snippet viewer")
   dispatch "revIDESnippetViewerSetSnippet" to stack \
      revIDEPaletteToStackName("snippet viewer") with tSnippet
   unlock screen
end revIDEExtensionShowSnippet

local sSampleFileName
local sOpenedStacksA
on ideOpenStack pCard
   local tStack
   put the long id of the owner of pCard into tStack
   if tStack is the long id of stack sSampleFileName then
      ## Clear the filename to force the user to choose save location if saving the stack
      put the short name of tStack into sOpenedStacksA[sSampleFileName]
      set the filename of tStack to empty
      put empty into sSampleFileName
      revIDEUnsubscribe "ideOpenStack"
   end if
end ideOpenStack

command revIDEExtensionLaunchSampleStack pSampleStack
    // Check if the sample stack has already been opened,
    // i.e. if its name is mapped in the array. If so, just
    // open it.
    if there is a stack (sOpenedStacksA[pSampleStack]) then
        open stack sOpenedStacksA[pSampleStack]
        exit revIDEExtensionLaunchSampleStack
    end if
    
    // Otherwise open the stack from the file. Wait until we
    // get the openStack message before emptying the filename
    // otherwise we will get a long id clash
    revIDESubscribe "ideOpenStack"
    put pSampleStack into sSampleFileName
    
    ## Open the sample stack
    open stack pSampleStack
end revIDEExtensionLaunchSampleStack
