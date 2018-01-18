script "revideextensionlibrary"
local sExtensions, sExtensionProperties

on extensionInitialize
   if the target is me then
      insert script of me into back 
   end if
end extensionInitialize

on extensionFinalize
   if the target is me then
      remove script of me from back
   end if
end extensionFinalize

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

command revIDEExtensionInstall pPackageLocation
   if there is not a file pPackageLocation then
      answer error "No package found at" && pPackageLocation
      exit revIDEExtensionInstall
   end if
   
   local tCacheIndex, tFromStore
   put __extensionCacheID("download_package_path", pPackageLocation) \
         into tCacheIndex
   if tCacheIndex is not a number then
      -- Direct install from package file
      put false into tFromStore
      put the number of elements of sExtensions + 1 into tCacheIndex
      __extensionPropertySet tCacheIndex, "download_package_path", pPackageLocation
   else
      put true into tFromStore
   end if
   
   try
      __extensionInstall tCacheIndex, pPackageLocation, tFromStore
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
   repeat for each key tExtensionKey in sExtensions
      put sExtensions[tExtensionKey] into tExtension
      if tExtension["name"] is empty then 
         delete variable sExtensions[tExtensionKey]
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
   if not pExtensionUrl begins with "http" then
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

# Download the extension
private command __extensionDownload pCacheIndex
   # Check the file extension is correct
   local tURL
   put __extensionPropertyGet(pCacheIndex,"package_url") into tURL
   
   set the itemdel to "."
   if the last item of tURL is not "lce" then return __extensionError(pCacheIndex,"Could not download extension. The package must have the file extension 'lce':" && tURL)
   
   local tPackageFilePath
   set the itemdel to "/"
   put the last item of tURL into tPackageFilePath
   
   __extensionPropertySet pCacheIndex, "download_package_path", revIDESpecialFolderPath("downloading extensions") & slash & tPackageFilePath
   __extensionPropertySet pCacheIndex, "status", "downloading"
   __extensionPropertySet pCacheIndex, "progress_message", "Downloading"
   __extensionPropertySet pCacheIndex, "progress", 0
   __extensionPropertySet pCacheIndex, "label", tPackageFilePath
   
   # Put is a first stab at the name
   set the itemdel to "."
   local tName
   put tPackageFilePath into tName
   delete the last item of tName
   repeat while the last item of tName is a number
      delete the last item of tName
   end repeat
   __extensionPropertySet pCacheIndex, "name", tName
   
   # Send update to refresh UI with new package installation
   __extensionsChanged
   
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
   if there is not a file tExtensionPath then return __extensionError(pCacheIndex,"Could not install extension. Package does not exists: " && tExtensionPath)
   
   # Check the file extension is valid
   set the itemdel to "."
   if the last item of tExtensionPath is not "lce" then return __extensionError(pCacheIndex,"Could not install extension. The package extension '"&the last item of tExtensionPath&"' Is not valid. Must be 'lce'.")
   
   # Get initial manifest data needed for loading
   local tManifestData, tManifestXMLTree
   put __extensionManifestData(pCacheIndex) into tManifestData
   put revXMLCreateTree(tManifestData,true,true,false) into tManifestXMLTree
   
   # Check the manifest contains a name
   local tExtensionName
   put __extensionManifestValueFromTree(tManifestXMLTree, "name") into tExtensionName
   if the result is not empty then
      return __extensionError(pCacheIndex,"Could not install extension. The package manifest must contain a valid name (com.livecode.extensions.<developer_ID>.<extension_name>)")
   end if
   __extensionPropertySet pCacheIndex, "name", tExtensionName
   
   # Check the manifest contains a version
   local tExtensionVersion
   put __extensionManifestValueFromTree(tManifestXMLTree, "version") into tExtensionVersion
   if the result is not empty then 
      return __extensionError(pCacheIndex,"Could not install extension. The package manifest must contain a valid version number (1.2.3 - major,minor,maintenance)")
   end if
   __extensionPropertySet pCacheIndex, "version", tExtensionVersion
   
   # Check the manifest contains an author
   local tExtensionAuthor
   put __extensionManifestValueFromTree(tManifestXMLTree, "author") into tExtensionAuthor
   if the result is not empty then 
      return __extensionError(pCacheIndex,"Could not install extension. The package manifest must contain an author")
   end if
   __extensionPropertySet pCacheIndex, "author", tExtensionAuthor
   
   # Check the manifest contains an type
   local tExtensionType
   put __extensionManifestValueFromTree(tManifestXMLTree, "type") into tExtensionType
   if the result is not empty then 
      return __extensionError(pCacheIndex,"Could not install extension. The package manifest must contain a type")
   end if
   __extensionPropertySet pCacheIndex, "type", tExtensionType
   
   # Check the manifest contains an title
   local tExtensionTitle
   put __extensionManifestValueFromTree(tManifestXMLTree, "title") into tExtensionTitle
   if the result is not empty then 
      return __extensionError(pCacheIndex,"Could not install extension. The package manifest must contain a title")
   end if
   __extensionPropertySet pCacheIndex, "title", tExtensionTitle
   
   revXMLDeleteTree tManifestXMLTree
   
   # Build the type ID from the name and version
   __extensionPropertySet pCacheIndex, "type_id", tExtensionName & "." & tExtensionVersion
end __extensionDownloadVerify

private command __extensionInstall pCacheIndex, pPackage, pFromStore
   __extensionDownloadVerify pCacheIndex
   
   local tName, tTypeId, tInstallPath
   put __extensionPropertyGet(pCacheIndex, "name") into tName
   put __extensionPropertyGet(pCacheIndex, "type_id") into tTypeId
   put revIDESpecialFolderPath("user extensions") & slash & tTypeId into tInstallPath
   revIDEEnsurePath tInstallPath
   
   __extensionInstallRemoveOlderVersions pCacheIndex, tName, 15
   __extensionInstallExtract pCacheIndex, tInstallPath, tTypeID, pPackage, 30
   __extensionInstallCopyInterfaceFile pCacheIndex, tName, tInstallPath, 50
   __extensionInstallLoad pCacheIndex, tName, tInstallPath, 80
   __extensionInstallFinalise pCacheIndex, tTypeID, pFromStore
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
   __FindExtensionsInFolderRecursive pInstallFolder, true, tFolderData
   
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
on __extensionInstallFinalise pCacheIndex, pTypeId, pDeletePackage
   # Delete temp package file
   if pDeletePackage then
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
   
   local tPropertyNames, tPropertyXMLData
   repeat for each line tPropertyNode in tPropertyNodes      
      local tName
      put revXMLAttribute(tXMLTree,"package" & "/" & tPropertyNode,"name") into tName
      put __extensionPropertyGet(tCacheId, tName) into tPropertyXMLData[tName]["data"]
      put revXMLAttribute(tXMLTree,"package" & "/" & tPropertyNode,"set") into \
            tPropertyXMLData[tName]["set"]
      put revXMLAttribute(tXMLTree,"package" & "/" & tPropertyNode,"get") into \
            tPropertyXMLData[tName]["get"]
   end repeat
   put the keys of tPropertyXMLData into tPropertyNames
   sort tPropertyNames by tPropertyXMLData[each]["data"]["order"]
   
   local tOrder, tPropertyDataA
   repeat for each line tProperty in tPropertyNames
      local tIDEPropertyInfo, tPropertyInfoA
      put tPropertyXMLData[tProperty]["data"] into tPropertyInfoA
      put revIDEPropertyInfo(tProperty) into tIDEPropertyInfo
      if tIDEPropertyInfo is not empty then
         add 1 to tOrder
         union tPropertyInfoA with tIDEPropertyInfo
         put tPropertyInfoA into tPropertyDataA[tProperty]
         put tOrder into tPropertyDataA[tProperty]["order"]
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
      put tOrder into tPropertyDataA[tProperty]["order"]
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
   
   repeat for each line tProperty in idePropertyNames()
      if tDataA[tProperty] is not empty then
         union tDataA[tProperty] with revIDEPropertyInfo(tProperty)
         put tDataA[tProperty] into tPropertyDataA[tProperty]
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

private command __extensionError pCacheIndex, pErrorMessage
   __extensionSendProgressUpdate pCacheIndex, "Error:" && pErrorMessage, 100
   throw pErrorMessage
   return empty
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

private function __fetchModuleData pFolder, pExtFile
   local tDataA
   revIDEExtensionFetchMetadata pFolder & slash & "manifest.xml", tDataA
   # If we couldn't fetch a type id, or there was no manifest then the result will not be empty
   if the result is not empty then
      put "Invalid manifest" into tDataA["error"]
      put "error" into tDataA["status"]
   end if
   return tDataA
end __fetchModuleData

private function __fetchScriptLibraryData pFolder, pExtFile
   local tDataA
   # Generate extension API from source if there is not one present in the folder
   # Don't do in an installed IDE as we might not be able to generate the files in the appropriate location
   if not revEnvironmentIsInstalled() or \
         not pFolder begins with revEnvironmentExtensionsPath() then
      revIDEExtensionUpdateAPI pFolder, pExtFile
   end if
   
   # Get library metadata from the docs, in lieu of a manifest
   local tDocA
   dispatch function "revDocsParseDocFileToLibraryArray" to stack "revDocsParser" \
         with (pFolder & slash & "api.lcdoc")
   put the result into tDocA 
   
   set the itemdelimiter to comma
   repeat for each item tKey in "title,author,version,name,type,display name,requires,uses,svgicon"
      put tDocA[tKey] into tDataA[tKey]
   end repeat
   if tDataA["title"] is empty then
      put tDataA["display name"] into tDataA["title"]
   end if
   return tDataA
end __fetchScriptLibraryData

private function __extensionIsBuiltin pID
   switch pID
      case "com.livecode.widget"
      case "com.livecode.engine"
      case "com.livecode.canvas"
      case "com.livecode.foreign"
      case "com.livecode.arithmetic"
      case "com.livecode.array"
      case "com.livecode.binary"
      case "com.livecode.bitwise"
      case "com.livecode.byte"
      case "com.livecode.char"
      case "com.livecode.codeunit"
      case "com.livecode.date"
      case "com.livecode.file"
      case "com.livecode.list"
      case "com.livecode.logic"
      case "com.livecode.mathfoundation"
      case "com.livecode.math"
      case "com.livecode.sort"
      case "com.livecode.stream"
      case "com.livecode.string"
      case "com.livecode.system"
      case "com.livecode.type"
      case "com.livecode.typeconvert"
      case "com.livecode.extensions.libbrowser"
      case "com.livecode.java"
      case "com.livecode.objc"
      case "com.livecode.commercial.license"
         return true
      default
         return false
   end switch
end __extensionIsBuiltin

private on __addToDependencies pDependee, pDependent, @xDependencies
   # AL-2015-04-13: [[ Bug 15216 ]] Use keys of array to remove duplicates
   put true into xDependencies[pDependee][pDependent]
end __addToDependencies

private on __addToList pNode, @xList
   if xList is empty then
      put pNode into xList
   else
      put return & pNode after xList
   end if
end __addToList

private on __removeFromList pNode, @xList
   get lineOffset(pNode, xList)
   if it is not 0 then
      delete line it of xList
   end if
end __removeFromList

private on __visitNode pDependencies, pNode, @xUnmarked, @xMarked, @xTemporaryMarked, @xOrder
   if pNode is among the lines of xTemporaryMarked then
      return "Error"
   end if
   if pNode is among the lines of xMarked then
      # AL-2015-04-13: [[ Bug 15216 ]] Remove from unmarked if this was already marked
      __removeFromList pNode, xUnmarked
      return ""
   end if
   __addToList pNode, xTemporaryMarked
   repeat for each key tNode in pDependencies[pNode]
      __visitNode pDependencies, tNode, xUnmarked, xMarked, xTemporaryMarked, xOrder
      if the result is not empty then
         return "Error"
      end if
   end repeat
   __addToList pNode, xMarked
   __removeFromList pNode, xUnmarked
   __removeFromList pNode, xTemporaryMarked
   __addToList pNode, xOrder
end __visitNode

private function __dependencyOrder pDependencies, pList
   local tUnmarked, tTemporaryMarked, tMarked, tOrder, tToVisit
   put pList into tUnmarked
   repeat while tUnmarked is not empty
      put any line of tUnmarked into tToVisit
      __visitNode pDependencies, tToVisit, tUnmarked, tMarked, tTemporaryMarked, tOrder
      if the result is not empty then
         throw "Circularity in dependencies starting from" && tToVisit
         return empty
      end if
   end repeat
   return tOrder
end __dependencyOrder

function revIDEExtensionsOrderByDependency pExtensions
   # Accumulate an array of dependencies
   local tDependencies, tRequirements
   repeat for each line tExtension in pExtensions
      put revIDEExtensionProperty(tExtension, "requires") into tRequirements
      repeat for each element tDependent in tRequirements
         if __extensionIsBuiltin(tDependent) then
            next repeat
         end if
         __addToDependencies tExtension, tDependent, tDependencies
      end repeat
   end repeat
   
   # Order them
   return __dependencyOrder(tDependencies, pExtensions)
end revIDEExtensionsOrderByDependency

command revIDEExtensionFetchSourceFromFolder pFolder, @rSource, @rType
   local tFiles
   put files(pFolder) into tFiles
   
   local tExtFile, tType
   filter tFiles with "*.lcb" into tExtFile
   if there is a file (pFolder & slash & "module.lcm") \
         or tExtFile is not empty then
      put "lcb" into tType
   end if
   if tType is empty then
      filter tFiles with regex pattern ".*\.livecode(script)?$" into tExtFile
      if tExtFile is not empty then
         put "lcs" into tType
      end if
   end if
   
   if tType is empty then
      put "none" into tType
   end if 
   
   put tExtFile into rSource
   put tType into rType
end revIDEExtensionFetchSourceFromFolder

private command __FindExtensionsInFolderRecursive pFolder, pIsUserFolder, @xDataA
   local tExtSource, tArray, tFiles, tExtFile, tType
   revIDEExtensionFetchSourceFromFolder pFolder, tExtFile, tType
   
   local tNumExtensions
   put the number of lines in tExtFile into tNumExtensions
   if tNumExtensions > 1 then
      get __revIDEError("Invalid extension folder" && pFolder & ": require exactly one extension per folder")
      exit __FindExtensionsInFolderRecursive
   end if
   
   -- If we found no extensions, recurse
   if tType is "none" then
      repeat for each line tSubFolder in folders(pFolder)
         if tSubFolder begins with "." then next repeat
         __FindExtensionsInFolderRecursive pFolder & slash & tSubFolder, \
               pIsUserFolder, xDataA
      end repeat
      exit __FindExtensionsInFolderRecursive
   end if
   
   if tType is "lcb" then
      put __fetchModuleData(pFolder, tExtFile) into tArray
   else
      put __fetchScriptLibraryData(pFolder, tExtFile) into tArray
   end if
   
   put tExtFile into tArray["source_file"]
   put tType into tArray["source_type"]
   put not pIsUserFolder into tArray["ide"]
   
   local tTypeID
   if tArray["name"] is empty then
      put pFolder into tTypeID
   else
      put tArray["name"] into tTypeID
   end if
   put tArray into xDataA[tTypeID][pFolder]
end __FindExtensionsInFolderRecursive

private function isUserExtension pData
   if pData["ide"] then 
      return 1
   end if
   return 0
end isUserExtension

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
         __FindExtensionsInFolderRecursive tExtFolder, tKey is "user", tDataA
      end repeat
   end repeat
   
   # Now loop through, checking the status of them
   local tExtensionsList, tExtensionsA, tExtensionCount, tExtensionCopyCount, tExtensionDataA
   put the keys of tDataA into tExtensionsList
   sort tExtensionsList
   
   local tToLoadA, tDependencies
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
      # Accumulate an array of dependencies
      repeat for each element tDependent in tExtensionDataA["copies"][1]["requires"]
         if __extensionIsBuiltin(tDependent) then
            next repeat
         end if
         __addToDependencies tTypeID, tDependent, tDependencies
      end repeat
      put empty into tExtensionDataA
   end repeat
   
   # Perform topological sort on list of dependencies so that they are loaded in the correct order
   local tLoadOrder
   put __dependencyOrder(tDependencies, the keys of tToLoadA) into tLoadOrder
   repeat for each line tLine in tLoadOrder
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
            end if
         end repeat
      end if
   else
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
            filter tCodeFolders with "*-win*"
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
   end if
end __MapCodeLibraryForIDE

private command __LoadExtension pCacheIndex, pSourceType, pSourceFile, pFolder, pStatus, @xError
   if xError is empty then
      if pSourceType is "lcb" then
         local tResources, tModule, tCode
         put pFolder & slash & "resources" into tResources
         put pFolder & slash & "module.lcm" into tModule
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
      end if
      if the result is not empty then
         put toUpper(char 1 of the result) & \
               char 2 to -1 of the result into xError
         put "error" into pStatus
      else
         put "installed" into pStatus
      end if
   end if
   
   __extensionPropertySet pCacheIndex, "status", pStatus
   __extensionPropertySet pCacheIndex, "error", xError
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
   
   local tLoadOnStartup
   if pError is empty then
      put revIDEExtensionGetLoadOnStartup(pID) into tLoadOnStartup
   end if
   if not pIsStartup or tLoadOnStartup is not false then
      __LoadExtension tCacheIndex, "lcb", pSourceFile, pFolder, pStatus, pError
      -- If we have an error loading, try to recompile the extension
      if pError is not empty then
         if not pIsIDEExtension and pSourceFile is not empty then
            revIDEExtensionCompile pFolder & slash & pSourceFile, pFolder
            if the result is empty then
               local tNewError
               __LoadExtension tCacheIndex, "lcb", pSourceFile, pFolder, pStatus, tNewError
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
   
   # Update name, status, error, and whether the extension comes with the IDE
   local tId
   try
      put the short name of stack (pFolder & slash & pSourceFile) into tId
   catch pError
   end try
   
   local tLoadOnStartup
   if pError is empty then
      put revIDEExtensionGetLoadOnStartup(tID) into tLoadOnStartup
   end if
   if not pIsStartup or tLoadOnStartup is not false then
      __LoadExtension tCacheIndex, "lcs", pSourceFile, pFolder, pStatus, pError
   else
      __extensionPropertySet tCacheIndex, "status", "unloaded" 
   end if
   
   if pAdditionalInfoA is empty then
      put __fetchScriptLibraryData(pFolder, pSourceFile) into pAdditionalInfoA
   end if
   
   __extensionPropertySet tCacheIndex, "name", tId
   __extensionPropertySet tCacheIndex, "type_id", tId  & "." & pVersion 
   
   __extensionPropertySet tCacheIndex, "author", pAdditionalInfoA["author"]
   __extensionPropertySet tCacheIndex, "title", pAdditionalInfoA["display name"]
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
   __extensionPropertySet tCacheIndex, "type", "library"
   __extensionPropertySet tCacheIndex, "uservisible", true
   
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
   __LoadExtension tCacheIndex, tDataA["source_type"], \
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

private function __extensionManifestValueFromTree pTreeID, pProperty
   local tValue
   switch pProperty
      case "requires"
         # Fetch extension dependencies
         local tRequires, tCount
         put 0 into tCount
         put revXMLChildNames(pTreeID,"package",return,"requires",true) into tRequires
         if tRequires begins with "xmlerr" then
            put tRequires into tValue
            break
         end if
         repeat for each line tDependency in tRequires
            add 1 to tCount
            local tName
            put revXMLAttribute(pTreeID,"package" & "/" & tDependency,"name") into tName
            if tName begins with "xmlerr" then
               put tName into tValue
               break
            end if
            put tName into tValue[tCount]
         end repeat
      default
         put revXMLNodeContents(pTreeID,"/package/" & pProperty) into tValue
         break
   end switch
   
   if tValue begins with "xmlerr" then
      return tValue for error
   end if
   return tValue for value
end __extensionManifestValueFromTree

private function __extensionManifestData pCacheIndex
   # Get the path to the package file
   local tExtensionPackageFile
   put __extensionPropertyGet(pCacheIndex, "download_package_path") into tExtensionPackageFile
   
   if not there is a file tExtensionPackageFile then return __extensionError(pCacheIndex,"Could not extract manifest because package was not found in downloads folder")
   
   # A zip can come compressed with a base folder or without. So work out what the 
   # root folder is before trying to extract files
   revZipOpenArchive tExtensionPackageFile, "read"
   
   local tZipItems, tZipRoot
   put revZipEnumerateItems(tExtensionPackageFile) into tZipItems
   
   if the last char of line 1 of tZipItems is "/" then
      put line 1 of tZipItems into tZipRoot
   else
      put empty into tZipRoot
   end if
   
   # Extract the package manfiest to a variable to read key data
   local tManifestData, tManifestXMLTree, tValue
   revZipExtractItemToVariable tExtensionPackageFile, (tZipRoot & "manifest.xml"), "tManifestData"
   
   revZipCloseArchive tExtensionPackageFile
   return tManifestData
end __extensionManifestData

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

private function __revIDEExtensionResourcePath
   if revEnvironmentIsInstalled() is false then
      return revEnvironmentBinariesPath()
   else
      return revIDESpecialFolderPath("Toolchain")
   end if
end __revIDEExtensionResourcePath

private function __revIDEExtensionCompilerPath
   # The actual compile command
   if the platform is "win32" then
      return __revIDEExtensionResourcePath() & slash & "lc-compile.exe"
   else
      return __revIDEExtensionResourcePath() & slash & "lc-compile"
   end if
end __revIDEExtensionCompilerPath

private function shellFormat pArg, pSwitch
   local tOutput
   
   if pSwitch is not empty then
      put "--" & pSwitch & " " into tOutput
   end if
   
   return tOutput & quote & pArg & quote & " "
end shellFormat

command revIDEExtensionCompile pFile, pTargetFolder
   # The manifest is currently always generated from the source
   if there is a file (pTargetFolder & slash & "manifest.xml") then
      delete file (pTargetFolder & slash & "manifest.xml")
   end if
   
   # Build the shell command
   local tShellCommand
   put shellFormat(__revIDEExtensionCompilerPath()) into tShellCommand
   
   # The folder to put the .lci file
   put shellFormat(pTargetFolder, "modulepath") after tShellCommand
   
   # The built-in module path
   put shellFormat(__revIDEExtensionResourcePath() & slash & "modules/lci", "modulepath") after tShellCommand
   
   # Installed module path
   put shellFormat(revIDESpecialFolderPath("user extensions") & slash & "interface", "modulepath") after tShellCommand
   
   # The manifest target
   put shellFormat(pTargetFolder & slash & "manifest.xml", "manifest") after tShellCommand
   
   # The output
   put shellFormat(pTargetFolder & slash & "module.lcm", "output") after tShellCommand
   
   # The target .lcb file
   put shellFormat(pFile) after tShellCommand
   
   # AL-2015-06-15: [[ Bug 15001 ]] Don't show console window when executing shell command
   local tHideConsoleWindows
   put the hideConsoleWindows into tHideConsoleWindows
   set the hideConsoleWindows to true
   
   local tShellOutput, tShellResult
   put shell(tShellCommand) into tShellOutput
   put the result into tShellResult
   set the hideConsoleWindows to tHideConsoleWindows
   if tShellResult is 0 then
      return tShellOutput for value
   end if
   return tShellOutput for error
end revIDEExtensionCompile

command revIDEExtensionMetadata pFolder, pFile, pType, @rDataA
   local tDataA, tResult
   if pType is "lcb" then
      revIDEExtensionFetchMetadata pFolder & slash & "manifest.xml", tDataA
      put the result into tResult
   else
      put __fetchScriptLibraryData(pFolder, pFile) into tDataA
   end if
   put tDataA into rDataA
   return tResult
end revIDEExtensionMetadata

private command __SetMetadata pKey, pValue, @xArray
   split pKey by "."
   put pValue into xArray[pKey]
end __SetMetadata

private command revIDEExtensionFetchMetadata pManifestPath, @rDataA
   local tDataA
   
   local tManifestContents, tTreeID
   put url ("file:" & pManifestPath) into tManifestContents
   put revXMLCreateTree(tManifestContents,true,true,false) into tTreeID
   
   if tTreeID begins with "xmlerr" then
      return "Error: invalid xml in manifest"
   end if
   
   local tTargetType
   put textDecode(revXMLNodeContents(tTreeID, "/package/type"), "utf-8") into tTargetType
   
   if tTargetType begins with "xmlerr" then
      return "Error: no type found in manifest"
   end if
   put tTargetType into tDataA["type"]
   
   local tTargetName
   put textDecode(revXMLNodeContents(tTreeID, "/package/name"), "utf-8") into tTargetName
   if tTargetName begins with "xmlerr" then
      return "Error: couldn't retrieve extension name from manifest"
   end if
   put tTargetName into tDataA["name"]
   
   local tTargetTitle
   put textDecode(revXMLNodeContents(tTreeID, "/package/title"), "utf-8") into tTargetTitle
   
   if tTargetTitle is empty or tTargetTitle begins with "xmlerr" then
      put empty into tTargetTitle
   end if
   put tTargetTitle into tDataA["title"]
   
   local tTargetVersion
   put textDecode(revXMLNodeContents(tTreeID, "/package/version"), "utf-8") into tTargetVersion
   
   if tTargetVersion is empty or tTargetVersion begins with "xmlerr" then
      put empty into tTargetVersion
   end if
   put tTargetVersion into tDataA["version"]
   
   local tTargetAuthor
   put textDecode(revXMLNodeContents(tTreeID, "/package/author"), "utf-8") into tTargetAuthor
   if tTargetAuthor is empty or tTargetAuthor begins with "xmlerr" then
      put empty into tTargetAuthor
   end if
   put tTargetAuthor into tDataA["author"]
   
   # Fetch property metadata
   local tMetadataValue, tMetadataKey
   local tMetadataNodes, tMetadataA, tKeys, tValue
   put revXMLChildNames(tTreeID, "package",return,"metadata",true) into tMetadataNodes
   repeat for each line tMetadata in tMetadataNodes
      put revXMLAttribute(tTreeID,"package" & "/" & tMetadata,"key") into tMetadataKey
      put revXMLNodeContents(tTreeID,"package" & "/" & tMetadata) into tMetadataValue
      if tMetadataValue is empty or tMetadataValue begins with "xmlerr" then
         put empty into tMetadataValue
      end if
      __SetMetadata tMetadataKey, tMetadataValue, tDataA
   end repeat
   
   # Fetch extension dependencies
   local tRequires, tCount
   put 0 into tCount
   put revXMLChildNames(tTreeID,"package",return,"requires",true) into tRequires
   repeat for each line tDependency in tRequires
      add 1 to tCount
      local tName
      put revXMLAttribute(tTreeID,"package" & "/" & tDependency,"name") into tName
      put tName into tDataA["requires"][tCount]
   end repeat
   
   # Fetch library handlers
   if tTargetType is "library" then
      local tHandlerList, tHandlerNodes
      put revXMLChildNames(tTreeID, "package",return,"handler",true) into tHandlerNodes
      repeat for each line tHandler in tHandlerNodes
         local tHandlerName
         put revXMLAttribute(tTreeID,"package" & "/" & tHandler,"name") into tHandlerName
         
         if tHandlerName is empty or tHandlerName begins with "xmlerr" then
            next repeat
         end if
         
         if tHandlerList is empty then
            put tHandlerName into tHandlerList
         else
            put return & tHandlerName after tHandlerList
         end if
      end repeat
      put tHandlerList into tDataA["handlers"]
   end if
   
   # User visible should default to true
   if tDataA["uservisible"] is empty then
      put true into tDataA["uservisible"]
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
   
   local tSourceType, tFolder, tSourceFile
   put __extensionPropertyGet(tCacheIndex, "install_path") into tFolder
   put __extensionPropertyGet(tCacheIndex, "source_type") into tSourceType
   put __extensionPropertyGet(tCacheIndex, "source_file") into tSourceFile
   
   local tDataA
   put tSourceType into tDataA["type"]
   if tSourceType is "lcb" then
      put tFolder & slash & "module.lcm" into tDataA["file"]
   else
      put tFolder & slash & tSourceFile into tDataA["file"]
   end if
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

private command addXML @xXML, pDepth, pTag, pContent, pAttributesA
   repeat pDepth
      put space after xXML
   end repeat
   put "<" & pTag after xXML
   repeat for each key tKey in pAttributesA
      put " " & tKey & "=" & quote & pAttributesA[tKey] & quote \
            after xXML
   end repeat
   if pContent is empty then
      put " />" after xXML
   else
      put ">" & pContent & "</" & pTag & ">" after xXML
   end if
   put return after xXML
end addXML

command revIDEExtensionGenerateManifestForLCSExtension pId, pFolder
   local tCacheIndex
   put __extensionCacheID("name", pId) into tCacheIndex
   
   local tPackageXML, tAttrA
   addXML tPackageXML, 1, "name", pId
   
   repeat for each item tTag in "title,author,version,type"
      addXML tPackageXML, 1, tTag, __extensionPropertyGet(tCacheIndex, tTag)
   end repeat
   
   repeat for each line tRequirement in revSBGetExtensionDependenciesForExtension(pId)
      put tRequirement into tAttrA["name"]
      addXML tPackageXML, 1, "requires", "", tAttrA
      put empty into tAttrA
   end repeat
   
   repeat for each item tMetadata in "svgicon"
      local tValue
      put __extensionPropertyGet(tCacheIndex, tMetadata) into tValue
      if tValue is empty then
         next repeat
      end if
      put tMetadata into tAttrA["key"]
      addXML tPackageXML, 1, "metadata", tValue, tAttrA
      put empty into tAttrA
   end repeat
   
   local tXML
   put "0.0" into tAttrA["version"]
   addXML tXML, 0, "package", return & tPackageXML, tAttrA
   put textEncode(tXML, "utf-8") into url("binfile:" & pFolder & slash & "manifest.xml")
end revIDEExtensionGenerateManifestForLCSExtension
