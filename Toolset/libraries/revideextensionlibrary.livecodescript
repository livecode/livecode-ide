script "revideextensionlibrary"
local sExtensions, sExtensionProperties

on revLoadLibrary
   if the target is me then
      insert script of me into back 
   end if
end revLoadLibrary

on revUnloadLibrary
   if the target is me then
      remove script of me from back
   end if
end revUnloadLibrary

# Called at startup. Loads all the extensions ready for use
on revIDEInitialiseExtensions
   # Install extensions that haven't yet been installed
   repeat for each line tExtensionPackage in __extensionPackagePaths()
      revIDEInstallExtension tExtensionPackage
   end repeat
   
   # Load all the extensions ready for use
   __extensionsLoad
end revIDEInitialiseExtensions

# Intalls the extension
on revIDEInstallExtension pExtensionPath, pType, pCallbackObject, pCallbackMessage
   if pExtensionPath begins with "http" or there is a file pExtensionPath then 
      
      # Get the ID of the extension in the cache
      local tCacheIndex
      put __extensionCacheID("package_url",pExtensionPath) into tCacheIndex
      
      if tCacheIndex is empty then
         put __extensionCacheID("download_package_path",pExtensionPath) into tCacheIndex
      end if
      
      # If the extension cache ID couldn't be found, generate a new one
      if tCacheIndex is empty then 
         put the number of elements of sExtensions + 1 into tCacheIndex
      end if
      
      # Add callback data to cache
      __extensionPropertySet tCacheIndex, "callback_target", pCallbackObject
      __extensionPropertySet tCacheIndex, "callback_handler", pCallbackMessage
      __extensionPropertySet tCacheIndex, "name", "New Extension Installing"
      
      # AL-2015-03-06: [[ Bug 14820 ]] Set the type so that the icon is correct while downloading
      __extensionPropertySet tCacheIndex, "type", pType
      
      if pExtensionPath begins with "http" then 
         # Download the package and install
         __extensionPropertySet tCacheIndex, "package_url", pExtensionPath
         __extensionInstallDownload tCacheIndex
      else
         # Package already downloaded - begin installation
         __extensionPropertySet tCacheIndex, "download_package_path", pExtensionPath
         __extensionInstallVerify tCacheIndex
      end if
   else
      # pExtensionPath is not a URL or file on disk
      return __extensionError(tCacheIndex,"Could not install extension. The extension must be a URL to a valid package or a path to a extension package on disk:" && pExtensionPath)
   end if
end revIDEInstallExtension

# Uninstalls the extension
on revIDEUninstallExtension pExtensionTypeID 
   # Start the uninstall process
   if pExtensionTypeID is not a number then
      put __extensionCacheID("name", pExtensionTypeID) into pExtensionTypeID
   end if
   
   __extensionUninstallCheckInUse pExtensionTypeID
end revIDEUninstallExtension

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
      if pType is not empty and tExtension["type"] is not pType then next repeat
      if pStatus is "installed" then
         if tExtension["status"] is "uninstalled" then
            next repeat
         end if
      else if pStatus is not empty then
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

function revIDEExtensionPropertiesInfo pTypeId, pOrganise
   local tPropsA, tExtensionPropsInfoA
   put revIDEExtensionProperties(pTypeId) into tPropsA
   
   if pOrganise then
      # If pOrganise is true, organise the property info into the structure that the property 
      #  inspector expects, namely [<section>]["grouplist"][<group>]["proplist"][<prop>]
      repeat for each key tProp in tPropsA
         local tSection, tGroup, tOrder, tPropInfoA
         put tPropsA[tProp] into tPropInfoA
         put tPropsA[tProp]["order"] into tOrder
         put tPropsA[tProp]["label"] into tGroup
         put tPropsA[tProp]["section"] into tSection
         put tPropInfoA into tExtensionPropsInfoA[tSection]["grouplist"][tGroup]["proplist"][tProp]
         
         put true into tExtensionPropsInfoA[tSection]["grouplist"][tGroup]["widget_prop"]
         put tOrder into tExtensionPropsInfoA[tSection]["grouplist"][tGroup]["order"]
      end repeat
   else
      put tPropsA into tExtensionPropsInfoA
   end if
   return tExtensionPropsInfoA
end revIDEExtensionPropertiesInfo

function revIDEExtensionProperty pKind, pProperty
   local tExtensionID
   put __extensionCacheID("name", pKind) into tExtensionID
   
   if pProperty is "api" then
      return __TypeToAPI(__extensionPropertyGet(tExtensionID, "type"))
   end if
   
   return __extensionPropertyGet(tExtensionID, pProperty)
end revIDEExtensionProperty

##############################
# PRIVATE INSTALLATION PROCESS
##############################

# Download the extension
on __extensionInstallDownload pCacheIndex
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
   libURLDownloadToFile tURL, __extensionPropertyGet(pCacheIndex,"download_package_path"), "__extensionInstallDownloadComplete"
end __extensionInstallDownload

# Dowload complete
on __extensionInstallDownloadComplete pURL, pDownloadStatus
   # Get the index of the extension
   local tExtensionID
   
   put __extensionCacheID("package_url", pURL) into tExtensionID
   
   # Update progress
   __extensionSendProgressUpdate tExtensionID, "Download Complete", 100
   
   # Start installing by verifying package
   send "__extensionInstallVerify" && tExtensionID to me in 0 milliseconds
end __extensionInstallDownloadComplete

# Verify extension package is valid
on __extensionInstallVerify pCacheIndex
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
   
   # Check the manifest contains a name
   local tExtensionName
   put __extensionManifestValue(pCacheIndex, "name") into tExtensionName
   if tExtensionName is "error" then return __extensionError(pCacheIndex,"Could not install extension. The package manifest must contain a valid name (com.livecode.extensions.<developer_ID>.<extension_name>)")
   __extensionPropertySet pCacheIndex, "name", tExtensionName
   
   # Check the manifest contains a version
   local tExtensionVersion
   put __extensionManifestValue(pCacheIndex, "version") into tExtensionVersion
   if tExtensionVersion is "error" then return __extensionError(pCacheIndex,"Could not install extension. The package manifest must contain a valid version number (1.2.3 - major,minor,maintenance)")
   __extensionPropertySet pCacheIndex, "version", tExtensionVersion
   
   # Check the manifest contains an author
   local tExtensionAuthor
   put __extensionManifestValue(pCacheIndex, "author") into tExtensionAuthor
   if tExtensionAuthor is "error" then return __extensionError(pCacheIndex,"Could not install extension. The package manifest must contain an author")
   __extensionPropertySet pCacheIndex, "author", tExtensionAuthor
   
   # Check the manifest contains an type
   local tExtensionType
   put __extensionManifestValue(pCacheIndex, "type") into tExtensionType
   if tExtensionType is "error" then return __extensionError(pCacheIndex,"Could not install extension. The package manifest must contain a type")
   __extensionPropertySet pCacheIndex, "type", tExtensionType
   
   # Check the manifest contains an title
   local tExtensionTitle
   put __extensionManifestValue(pCacheIndex, "title") into tExtensionTitle
   if tExtensionTitle is "error" then return __extensionError(pCacheIndex,"Could not install extension. The package manifest must contain a title")
   __extensionPropertySet pCacheIndex, "title", tExtensionTitle
   
   # Build the type ID from the name and version
   __extensionPropertySet pCacheIndex, "type_id", tExtensionName & "." & tExtensionVersion
   
   # Next step
   send "__extensionInstallRemoveOlderVersions" && pCacheIndex to me in 0 milliseconds
end __extensionInstallVerify

on __extensionInstallRemoveOlderVersions pCacheIndex
   __extensionSendProgressUpdate pCacheIndex, "Removing older versions", 7
   
   local tName
   put __extensionPropertyGet(pCacheIndex, "name") into tName
   
   repeat for each key tCacheIndex in sExtensions
      if tCacheIndex is pCacheIndex then next repeat
      if sExtensions[tCacheIndex]["name"] is tName then
         revIDEUninstallExtension tCacheIndex
      end if
   end repeat
   
   # Next step
   send "__extensionInstallExtract" && pCacheIndex to me in 0 milliseconds
end __extensionInstallRemoveOlderVersions

# Extract the extension files
on __extensionInstallExtract pCacheIndex
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Extracting extension", 15
   
   # Get the path to the package file
   local tExtensionPackageFile
   put __extensionPropertyGet(pCacheIndex, "download_package_path") into tExtensionPackageFile
   
   # Create directory to extract into
   local tExtensionDirectory
   put revIDESpecialFolderPath("temp extensions") & slash & __extensionPropertyGet(pCacheIndex, "type_id") into tExtensionDirectory
   revIDEEnsurePath(tExtensionDirectory)
   
   # Extract the icon,docs and executable module into the folder
   revZipOpenArchive tExtensionPackageFile, "read"
   
   # Work out the root of the zip
   local tZipItems, tZipRoot
   put revZipEnumerateItems(tExtensionPackageFile) into tZipItems
   if the last char of line 1 of tZipItems is "/" then
      put line 1 of tZipItems into tZipRoot
   else
      put empty into tZipRoot
   end if
   
   # Extract all the files
   local tDirectory
   set the itemdel to slash
   repeat for each line tFile in tZipItems
      put tExtensionDirectory & slash & item 1 to -2 of tFile into tDirectory
      revIDEEnsurePath(tDirectory)
      revZipExtractItemToFile tExtensionPackageFile, tFile, tExtensionDirectory & slash & tFile
   end repeat 
   
   # add path to icon file to the data array
   __extensionPropertySet pCacheIndex, "icon", revIDESpecialFolderPath("user extensions") & slash & __extensionPropertyGet(pCacheIndex,"type_id") & "/support/icon.png"
   
   revZipCloseArchive tExtensionPackageFile
   
   # Next step
   send "__extensionInstallGuide" && pCacheIndex to me in 0 milliseconds
end __extensionInstallExtract

# Install the guide into the IDE
on __extensionInstallGuide pCacheIndex
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Adding user guide to documentation", 30
   
   # Path to user guide
   local tUserGuideFolder
   put revIDESpecialFolderPath("temp extensions") & slash & __extensionPropertyGet(pCacheIndex, "type_id") & slash & "docs/guide" into tUserGuideFolder
   
   # Get the name and author required by user guide install function
   local tExtensionName, tExtensionAuthor
   put __extensionPropertyGet(pCacheIndex, "name") into tExtensionName
   put __extensionPropertyGet(pCacheIndex, "author") into tExtensionAuthor
   
   # Install user guide into the IDE
   revIDEInstallUserGuide tUserGuideFolder, tExtensionName, tExtensionAuthor
   
   send "__extensionInstallAPI" && pCacheIndex to me in 500 milliseconds
end __extensionInstallGuide

# Install the extension API into the IDE
on __extensionInstallAPI pCacheIndex
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Adding API to documentation", 45
   
   # Path to user guide
   local tUserAPIFolder
   put revIDESpecialFolderPath("temp extensions") & slash & __extensionPropertyGet(pCacheIndex, "type_id") & slash & "docs/api" into tUserAPIFolder
   
   # Get the name and author required by API install function
   local tExtensionName, tExtensionAuthor
   put __extensionPropertyGet(pCacheIndex, "name") into tExtensionName
   put __extensionPropertyGet(pCacheIndex, "author") into tExtensionAuthor
   
   # Install API into the IDE
   // revIDEInstallAPI tUserAPIFolder, tExtensionName, tExtensionAuthor
   revIDEInstallAPI tUserAPIFolder, tExtensionName, tExtensionAuthor
   
   # Next step
   send "__extensionInstallMakeLive" && pCacheIndex to me in 0 milliseconds
end __extensionInstallAPI

# Moves to temp extracted files into their final live location
on __extensionInstallMakeLive pCacheIndex
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Copying extension into install location", 60
   
   # Get path the directories
   local tTempInstallPath, tFinalPath
   put revIDESpecialFolderPath("temp extensions") & slash & __extensionPropertyGet(pCacheIndex, "type_id") into tTempInstallPath
   put revIDESpecialFolderPath("user extensions") into tFinalPath
   __extensionPropertySet pCacheIndex, "install_path", tFinalPath & slash & __extensionPropertyGet(pCacheIndex, "type_id")
   
   # Copy folder from temp directory into live directory
   revCopyFolder tTempInstallPath,tFinalPath
   
   # AL-2015-03-15: [[ Bug 15008 ]] Move interface file to interface folder
   local tInterfaceFile, tInterfacePath
   put __extensionPropertyGet(pCacheIndex, "name") & ".lci" into tInterfaceFile
   put tFinalPath & slash &__extensionPropertyGet(pCacheIndex, "type_id") \ 
         & slash & tInterfaceFile into tInterfacePath
   
   if there is a file tInterfacePath then
      local tTargetFolder
      put tFinalPath & slash & "interface" into tTargetFolder
      revIDEEnsurePath tTargetFolder
      revCopyFile tInterfacePath, tTargetFolder & slash & tInterfaceFile
   end if
   
   # Next step
   send "__extensionInstallLoad" && pCacheIndex to me in 0 milliseconds
end __extensionInstallMakeLive

on __extensionInstallLoad pCacheIndex
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Loading extension", 75
   
   # Path to module file
   local tModuleFile
   put revIDESpecialFolderPath("temp extensions") \ 
         & slash & __extensionPropertyGet(pCacheIndex, "type_id") \
         & slash & "module.lcm" into tModuleFile
   
   # Store the extension's property metadata
   local tTypeID
   put  __extensionPropertyGet(pCacheIndex, "name") into tTypeID
   revIDEExtensionSetInfo(tTypeID)
   
   # Load module file into the engine
   local tDataA
   put sExtensions[pCacheIndex] into tDataA["copies"][1]
   
   local tExisting
   repeat for each key tExtensionID in sExtensions
      if tExtensionID is pCacheIndex then next repeat
      if sExtensions[tExtensionID]["name"] is tTypeID then
         put sExtensions[tExtensionID]["copies"] into tExisting
      end if
   end repeat
   
   repeat for each key tKey in tExisting
      put tExisting[tKey] into tDataA["copies"][tKey + 1]
   end repeat
   
   __extensionLoad tTypeID, tDataA
   
   # Next step
   send "__extensionInstallFinalise" && pCacheIndex to me in 0 milliseconds
end __extensionInstallLoad

# Delete installation files and original package
on __extensionInstallFinalise pCacheIndex
   # Update progress
   __extensionSendProgressUpdate  pCacheIndex, "Removing temp files", 90
   
   # Delete temp install folder
   local tTempInstallPath
   put revIDESpecialFolderPath("temp extensions") & slash & __extensionPropertyGet(pCacheIndex, "type_id") into tTempInstallPath
   if there is a folder tTempInstallPath then
      revDeleteFolder tTempInstallPath
   end if
   
   # Delete temp package file
   local tTempInstallPackage
   put revIDESpecialFolderPath("downloading extensions") & slash & __extensionPropertyGet(pCacheIndex, "type_id") & ".lce" into tTempInstallPackage
   if there is a file tTempInstallPackage then
      revDeleteFolder tTempInstallPackage
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
on __extensionUninstallCheckInUse pCacheIndex
   # Update progress
   if pCacheIndex is not a number then return __extensionError(pCacheIndex, "Could not remove extension '" & pCacheIndex & "' because it is not a valid index")
   
   __extensionSendProgressUpdate pCacheIndex, "Checking if extension is in use", 20
   
   # Next step
   __extensionUninstallDeleteFiles pCacheIndex
end __extensionUninstallCheckInUse

# Delete the files associated to the extension
on __extensionUninstallDeleteFiles pCacheIndex
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Deleting extension files", 40
   
   # Get the extension isntall path
   local tPath
   put __extensionPropertyGet(pCacheIndex, "install_path") into tPath
   
   # Make sure the path contains the folder extension as a check before deleting a folder
   if tPath begins with revIDESpecialFolderPath("user extensions") then
      revDeleteFolder tPath
   end if
   
   # AL-2015-03-15: [[ Bug 15008 ]] Delete interface file from interface folder
   local tInterfaceFile
   put __extensionPropertyGet(pCacheIndex, "name") & ".lci" into tInterfaceFile
   if there is a file (revIDESpecialFolderPath("user extensions") & slash & "interface" & slash & tInterfaceFile) then
      revDeleteFile revIDESpecialFolderPath("user extensions") & slash & "interface" & slash & tInterfaceFile
   end if
   
   # Next step
   __extensionUninstallUnload pCacheIndex
end __extensionUninstallDeleteFiles

# Unload the extension
on __extensionUninstallUnload pCacheIndex
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Unloading extension", 60
   
   # Unload the extension by name
   local tName
   put __extensionPropertyGet(pCacheIndex, "name") into tName
   revIDEExtensionUnload tName
   
   # Next step
   __extensionUninstallDocs pCacheIndex
end __extensionUninstallUnload

# Remove the guide from the IDE
on __extensionUninstallDocs pCacheIndex
   # Update progress
   __extensionSendProgressUpdate pCacheIndex, "Removing API and user guide from documentation", 80
   
   revIDERegenerateBuiltDictionaryData
   
   __extensionUninstallComplete pCacheIndex
end __extensionUninstallDocs

on __extensionUninstallComplete pCacheIndex
   # Notify IDE uninstallation complete
   __extensionSendProgressUpdate pCacheIndex, "Complete", 100
   
   # Update the IDE
   __extensionsChanged
end __extensionUninstallComplete

##############################
# PRIVATE SHARED
##############################

function __extensionFetchPropertyMetadata pXMLTree, pProperty, pElement
   local tNode
   put revXMLMatchingNode(pXMLTree, "package", "metadata", "key", pProperty &"." & pElement, 1) into tNode
   if tNode is not empty then
      return revXMLNodeContents(pXMLTree, tNode)
   end if
   
   return empty
end __extensionFetchPropertyMetadata

function __extensionPropertyInfoFromManifest pManifestPath
   if not there is a file pManifestPath then return empty
   # Create the XML tree
   local tXMLTree, tProperties, tExtensionData
   put revXMLCreateTreeFromFile(pManifestPath,true,true,false) into tXMLTree
   
   # Process the general property metadata into an array
   local tMetadataNodes, tMetadataA, tKeys, tValue
   put revXMLChildNames(tXMLTree, "package",return,"metadata",true) into tMetadataNodes
   set the itemdelimiter to "."
   repeat for each line tMetadata in tMetadataNodes
      put revXMLAttribute(tXMLTree,"package" & "/" & tMetadata,"key") into tKeys
      put revXMLNodeContents(tXMLTree,"package" & "/" & tMetadata) into tValue
      repeat with x = the number of items in tKeys down to 1
         get tValue
         put empty into tValue
         put it into tValue[item x of tKeys]
      end repeat
      union tMetadataA with tValue recursively
   end repeat
   
   put revXMLChildNames(tXMLTree,"package",return,"property",true) into tProperties
   local tOrder, tPropertyDataA
   
   local tMetadataKeys
   put the keys of tMetadataA into tMetadataKeys
   sort tMetadataKeys
   sort tMetadataKeys by tMetadataA[each]["order"]
   repeat for each line tKey in tMetadataKeys
      local tPropertyInfo
      put revIDEPropertyInfo(tKey) into tPropertyInfo
      if tPropertyInfo is empty then
         next repeat
      end if
      add 1 to tOrder
      union tMetadataA[tKey] with tPropertyInfo
      put tMetadataA[tKey] into tPropertyDataA[tKey]
      put tOrder into tPropertyDataA[tKey]["order"]
   end repeat
   
   repeat for each line tProperty in tProperties
      add 1 to tOrder
      local tName
      put revXMLAttribute(tXMLTree,"package" & "/" & tProperty,"name") into tName
      
      put tMetadataA[tName] into tPropertyDataA[tName]
      
      local tReadOnly
      get revXMLAttribute(tXMLTree,"package" & "/" & tProperty,"set")
      if it is empty or it begins with "xmlerr" then
         put true into tReadOnly
      else
         put false into tReadOnly
      end if
      put tReadOnly into tPropertyDataA[tName]["read_only"]
      
      if tPropertyDataA[tName]["editor"] is empty then
         local tType
         put revXMLAttribute(tXMLTree,"package" & "/" & tProperty,"get") into tType
         if tType is "Integer" or tType is "Real" then
            put "com.livecode.pi.number" into tPropertyDataA[tName]["editor"]
         else
            put "com.livecode.pi." & tolower(tType) into tPropertyDataA[tName]["editor"]
         end if
      end if
      put tOrder into tPropertyDataA[tName]["order"]
   end repeat
   
   repeat for each key tName in tPropertyDataA
      local tLabel, tSection
      
      if tPropertyDataA[tName]["section"] is empty then
         put "Basic" into tPropertyDataA[tName]["section"]
      end if
      
      if tPropertyDataA[tName]["label"] is empty then
         put tName into tPropertyDataA[tName]["label"]
      end if
      
      # Process value options, default and delimiter
      replace comma with return in tPropertyDataA[tName]["options"]
      replace "\n" with return in tPropertyDataA[tName]["delimiter"]
      if tPropertyDataA[tName]["default"] is not empty then
         replace "\n" with return in tPropertyDataA[tName]["default"]
      end if
      
      # Tag the property as a widget property, so we can order them 
      # correctly after the built-in props for the given section
      put true into tPropertyDataA[tName]["widget_prop"]
      
      if tPropertyDataA[tName]["user_visible"] is empty then
         put true into tPropertyDataA[tName]["user_visible"]
      end if
   end repeat
   
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

command __extensionSetPropertyInfoFromManifest pID, pManifest
   local tPropertyInfo
   put __extensionPropertyInfoFromManifest(pManifest) into tPropertyInfo
   put tPropertyInfo into sExtensionProperties[pID]
end __extensionSetPropertyInfoFromManifest

function __extensionError pCacheIndex, pErrorMessage
   __extensionSendProgressUpdate pCacheIndex, "Error:" && pErrorMessage, 100
   --put "Error:" && pErrorMessage, 100
   --revIDEUninstallExtension pCacheIndex
   return empty
end __extensionError

# Send notication that widget has been added/removed
on __extensionsChanged
   ideMessageSend "ideExtensionsChanged"
end __extensionsChanged

# Sent progress update on installation of widget
on __extensionSendProgressUpdate pCacheIndex, pMessage, pProgress
   # Get progress information for extension
   __extensionPropertySet pCacheIndex, "progress_message", pMessage
   __extensionPropertySet pCacheIndex, "progress", pProgress
   
   local tName
   //revputarray sExtensions
   put __extensionPropertyGet(pCacheIndex, "name") into tName
   ideMessageSend "ideExtensionStatusChanged", (tName & comma & pMessage & comma & pProgress)
   
   //local tCallbackTarget, tCallBackHandler
   //put __extensionPropertyGet(pCacheIndex, "callback_target") into tCallbackTarget
   //put __extensionPropertyGet(pCacheIndex, "callback_handler") into tCallBackHandler
   //if exists(tCallbackTarget) then
   //dispatch tCallBackHandler to tCallbackTarget with pMessage,pProgress
   //end if
   // Send message to registered targets
end __extensionSendProgressUpdate

private function __fetchModuleData pExtensionFile
   local tDataA, tFolder
   set the itemdelimiter to slash
   put item 1 to -2 of pExtensionFile into tFolder
   revIDEExtensionFetchMetadata tFolder & slash & "manifest.xml", tDataA
   # If we couldn't fetch a type id, or there was no manifest then the result will not be empty
   if the result is not empty then
      put "Invalid manifest" into tDataA["error"]
      put "error" into tDataA["status"]
   end if
   return tDataA
end __fetchModuleData

private function __fetchScriptLibraryData pExtensionFile
   local tDataA, tFolder, tFile
   set the itemdelimiter to slash
   put item 1 to -2 of pExtensionFile into tFolder
   put item -1 of pExtensionFile into tFile
   # Generate extension API from source if there is not one present in the folder
   # Don't do in an installed IDE as we might not be able to generate the files in the appropriate location
   if not revEnvironmentIsInstalled() or \
         not tFolder begins with revEnvironmentExtensionsPath() then
      revIDEExtensionUpdateAPI tFolder, tFile
   end if
   
   # Get library metadata from the docs, in lieu of a manifest
   local tDocA
   dispatch function "revDocsParseDocFileToLibraryArray" to stack "revDocsParser" \
         with (tFolder & slash & "api.lcdoc")
   put the result into tDocA 
   
   set the itemdelimiter to comma
   repeat for each item tKey in "title,author,version,name,display name,requires,uses,svgicon"
      put tDocA[tKey] into tDataA[tKey]
   end repeat

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
   put "lcb" into tType
   if tExtFile is empty then
      put "lcs" into tType
      filter tFiles with regex pattern ".*\.livecode(script)?$" into tExtFile
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
   if tNumExtensions is 0 then
      repeat for each line tSubFolder in folders(pFolder)
         if tSubFolder begins with "." then next repeat
         __FindExtensionsInFolderRecursive pFolder & slash & tSubFolder, pIsUserFolder, xDataA
      end repeat
      exit __FindExtensionsInFolderRecursive
   end if
   
   put pFolder & slash & tExtFile into tExtSource
   if tType is "lcb" then
      put __fetchModuleData(tExtSource) into tArray
   else
      put __fetchScriptLibraryData(tExtSource) into tArray
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

# Returns: List of the packages that are in the directory but not installed
function __extensionPackagePaths
   local tPaths
   return tPaths
end __extensionPackagePaths

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
   
   local tFolder, tVersion, tStatus, tError, tIDEExtension, tSourceFile
   put tToLoadA["install_path"] into tFolder
   put tToLoadA["version"] into tVersion
   put tToLoadA["status"] into tStatus
   put tToLoadA["error"] into tError
   put tToLoadA["ide"] into tIDEExtension
   put tToLoadA["source_file"] into tSourceFile
   revIDEExtensionLoad pID, tFolder, tVersion, tStatus, tError, tIDEExtension, tSourceFile, tToLoadA
end __extensionLoad

private command __revIDELCBExtensionLoad pID, pFolder, pVersion, pStatus, pError, pIsIDEExtension, pSourceFile, pAdditionalInfoA
   local tStatus, tError
   if pError is empty then
      local tResources, tModule
      put pFolder & slash & "resources" into tResources
      put pFolder & slash & "module.lcm" into tModule
      # If we have a resources folder then load with resource path
      if there is a folder tResources then
         load extension from file tModule with resource path tResources
      else
         load extension from file tModule
      end if
      if the result is not empty then
         put toUpper(char 1 of the result) & char 2 to -1 of the result into tError
         put "error" into tStatus
      else
         put "installed" into tStatus
      end if
   else
      put pStatus into tStatus
      put pError into tError
   end if
   
   # Find entry in the cache if it exists
   local tCacheIndex
   put __extensionCacheID("install_path", pFolder) into tCacheIndex
   
   # If no extry is in the cache, create one
   if tCacheIndex is not a number then
      put the number of elements of sExtensions + 1 into tCacheIndex
      __extensionPropertySet tCacheIndex, "install_path", pFolder
   end if
   
   # Update name, status, error, and whether the extension comes with the IDE
   __extensionPropertySet tCacheIndex, "name", pID
   __extensionPropertySet tCacheIndex, "type_id", pID  & "." & pVersion 
   __extensionPropertySet tCacheIndex, "status", tStatus
   __extensionPropertySet tCacheIndex, "error", tError
   __extensionPropertySet tCacheIndex, "ide", pIsIDEExtension
   __extensionPropertySet tCacheIndex, "source_file", pSourceFile
   __extensionPropertySet tCacheIndex, "source_type", "lcb"
   
   # Store the extension's property metadata
   revIDEExtensionSetInfo pID
   
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
   
   return tError
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

private command __revIDELCSExtensionLoad pID, pFolder, pVersion, pStatus, pError, pIsIDEExtension, pSourceFile, pAdditionalInfoA
   local tStatus, tError
   set the itemdelimiter to "."
   if pError is empty then
      revInternal__LoadLibrary item 1 of pSourceFile, pFolder & slash & pSourceFile
      if the result is not empty then
         put toUpper(char 1 of the result) & char 2 to -1 of the result into tError
         put "error" into tStatus
      else
         put "installed" into tStatus
      end if
   else
      put pStatus into tStatus
      put pError into tError
   end if
   
   # Find entry in the cache if it exists
   local tCacheIndex
   put __extensionCacheID("install_path", pFolder) into tCacheIndex
   
   # If no entry is in the cache, create one
   if tCacheIndex is not a number then
      put the number of elements of sExtensions + 1 into tCacheIndex
      __extensionPropertySet tCacheIndex, "install_path", pFolder
   end if
   
   if pAdditionalInfoA is empty then
      put __fetchScriptLibraryData(pFolder & slash & pSourceFile) into pAdditionalInfoA
   end if
   
   # Update name, status, error, and whether the extension comes with the IDE
   __extensionPropertySet tCacheIndex, "name", pID
   __extensionPropertySet tCacheIndex, "type_id", pID  & "." & pVersion 
   
   __extensionPropertySet tCacheIndex, "author", pAdditionalInfoA["author"]
   __extensionPropertySet tCacheIndex, "title", pAdditionalInfoA["display name"]
   __extensionPropertySet tCacheIndex, "svgicon", pAdditionalInfoA["svgicon"]
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
   __extensionPropertySet tCacheIndex, "status", tStatus
   __extensionPropertySet tCacheIndex, "error", tError
   __extensionPropertySet tCacheIndex, "ide", pIsIDEExtension
   __extensionPropertySet tCacheIndex, "source_type", "lcs"
   __extensionPropertySet tCacheIndex, "type", "library"
   __extensionPropertySet tCacheIndex, "uservisible", true
   
   # Store the extension's property metadata
   --  revIDEExtensionSetInfo pID
   
   # Deal with the various icon possibilities
   if sExtensionProperties[pID]["svgicon"] is empty then
      local tIconPath
      put pFolder & "/support/icon.png" into tIconPath
      if there is a file tIconPath then
         __extensionPropertySet tCacheIndex, "icon", tIconPath
      end if
   end if
   
   return tError
end __revIDELCSExtensionLoad

command revIDEExtensionLoad pID, pFolder, pVersion, pStatus, pError, pIDEExtension, pSourceFile, pAdditionalInfoA
   set the itemdel to "."
   if item -1 of pSourceFile  is "lcb" then
      __revIDELCBExtensionLoad pID, pFolder, pVersion, pStatus, pError, pIDEExtension, pSourceFile, pAdditionalInfoA
   else if item -1 of pSourceFile begins with "livecode" then
      __revIDELCSExtensionLoad pID, pFolder, pVersion, pStatus, pError, pIDEExtension, pSourceFile, pAdditionalInfoA
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

function __extensionManifestValue pCacheIndex, pProperty
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
   
   put revXMLCreateTree(tManifestData,true,true,false) into tManifestXMLTree
   put revXMLNodeContents(tManifestXMLTree,"/package/" & pProperty) into tValue
   if tValue begins with "xmlerr" then
      return empty
   else
      return tValue
   end if
end __extensionManifestValue

function __extensionManifestValueFromFile pCacheIndex, pProperty
   # Get the path to the manifest file
   local tExtensionInstallPath, tManifestFilepath
   put __extensionPropertyGet(pCacheIndex, "install_path") into tExtensionInstallPath
   put tExtensionInstallPath & slash & "manifest.xml" into tManifestFilepath
   
   if not there is a file tManifestFilepath then 
      local tError
      put "Could not get extension manifest information: " into tError
      put "extension folder does not contain a manifest file" after tError
      return __extensionError(pCacheIndex,tError)
   end if
   
   # Extract the package manfiest to a variable to read key data
   local tManifestXMLTree, tValue
   
   put revXMLCreateTreeFromFile(tManifestFilepath,true,true,false) into tManifestXMLTree
   put revXMLNodeContents(tManifestXMLTree,"/package/" & pProperty) into tValue
   if tValue begins with "xmlerr" then
      return empty
   else
      return tValue
   end if
end __extensionManifestValueFromFile

# Returns a value from the manifest
//private on __extensionManifestValue pCacheIndex, pManifestKey
//end __extensionManifestValue


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

private on revIDEExtensionFetchMetadata pManifestPath, @rDataA
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
      put tMetadataValue into tDataA[tMetadataKey]
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

command revIDEExtensionUnload pKind
   local tCacheIndex
   put __extensionCacheID("name", pKind) into tCacheIndex
   
   local tCopies
   put __extensionPropertyGet(tCacheIndex, "copies") into tCopies
   if the number of elements in tCopies <= 1 then
      delete variable sExtensions[tCacheIndex]
   else
      __extensionPropertySet tCacheIndex, "status", "uninstalled"
   end if
   
   # Check if it's loaded
   if pKind is among the lines of the loadedExtensions then
      unload extension pKind
   end if
   
   return the result
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
