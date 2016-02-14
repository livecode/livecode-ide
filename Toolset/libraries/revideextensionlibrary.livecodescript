script "revideextensionlibrary"
local sExtensions, sExtensionProperties

on revLoadLibrary
   insert script of me into back 
end revLoadLibrary

on revUnloadLibrary
   remove script of me from back
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
      local tIndex
      put __extensionCacheID("package_url",pExtensionPath) into tIndex
      
      if tIndex is empty then
         put __extensionCacheID("download_package_path",pExtensionPath) into tIndex
      end if
      
      # If the extension cache ID couldn't be found, generate a new one
      if tIndex is empty then 
         put the number of elements of sExtensions + 1 into tIndex
      end if
      
      # Add callback data to cache
      __extensionPropertySet tIndex, "callback_target", pCallbackObject
      __extensionPropertySet tIndex, "callback_handler", pCallbackMessage
      __extensionPropertySet tIndex, "name", "New Extension Installing"
      
      # AL-2015-03-06: [[ Bug 14820 ]] Set the type so that the icon is correct while downloading
      __extensionPropertySet tIndex, "type", pType
      
      if pExtensionPath begins with "http" then 
         # Download the package and install
         __extensionPropertySet tIndex, "package_url", pExtensionPath
         __extensionInstallDownload tIndex
      else
         # Package already downloaded - begin installation
         __extensionPropertySet tIndex, "download_package_path", pExtensionPath
         __extensionInstallVerify tIndex
      end if
   else
      # pExtensionPath is not a URL or file on disk
      return __extensionError(tIndex,"Could not install extension. The extension must be a URL to a valid package or a path to a extension package on disk:" && pExtensionPath)
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
   local tExtensions
   repeat for each line tExtensionKey in the keys of sExtensions
      if sExtensions[tExtensionKey]["name"] is empty then 
         delete variable sExtensions[tExtensionKey]
         next repeat
      end if
      if pType is not empty and sExtensions[tExtensionKey]["type"] is not pType then next repeat
      if pStatus is "installed" then
         if sExtensions[tExtensionKey]["status"] is "uninstalled" then
            next repeat
         end if
      else if pStatus is not empty then
         if sExtensions[tExtensionKey]["status"] is not pStatus then 
            next repeat
         end if
      end if
      
      if pWithoutInvisible and sExtensions[tExtensionKey]["uservisible"] is not true then
         next repeat
      end if
      
      local tIconPath
      if there is not a file sExtensions[tExtensionKey]["icon"] then 
         put revIDEDefaultExtensionIcon(pType) into sExtensions[tExtensionKey]["icon"]
      end if
      
      put sExtensions[tExtensionKey] into tExtensions[sExtensions[tExtensionKey]["name"]]
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
   
   return __extensionPropertyGet(tExtensionID, pProperty)
end revIDEExtensionProperty

##############################
# PRIVATE INSTALLATION PROCESS
##############################

# Download the extension
on __extensionInstallDownload pExtensionID
   # Check the file extension is correct
   local tURL
   put __extensionPropertyGet(pExtensionID,"package_url") into tURL
   
   set the itemdel to "."
   if the last item of tURL is not "lce" then return __extensionError(pExtensionID,"Could not download extension. The package must have the file extension 'lce':" && tURL)
   
   local tPackageFilePath
   set the itemdel to "/"
   put the last item of tURL into tPackageFilePath
   
   __extensionPropertySet pExtensionID, "download_package_path", revIDESpecialFolderPath("downloading extensions") & slash & tPackageFilePath
   __extensionPropertySet pExtensionID, "status", "downloading"
   __extensionPropertySet pExtensionID, "progress_message", "Downloading"
   __extensionPropertySet pExtensionID, "progress", 0
   __extensionPropertySet pExtensionID, "label", tPackageFilePath
   
   # Put is a first stab at the name
   set the itemdel to "."
   local tName
   put tPackageFilePath into tName
   delete the last item of tName
   repeat while the last item of tName is a number
      delete the last item of tName
   end repeat
   __extensionPropertySet pExtensionID, "name", tName
   
   # Send update to refresh UI with new package installation
   __extensionsChanged
   
   # Update progress
   __extensionSendProgressUpdate pExtensionID, "Downloading", 0
   
   # Download the extension to a file
   libURLDownloadToFile tURL, __extensionPropertyGet(pExtensionID,"download_package_path"), "__extensionInstallDownloadComplete"
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
on __extensionInstallVerify pExtensionID
   # Update progress
   __extensionSendProgressUpdate pExtensionID, "Verifying extension", 0
   
   # Get the path to the extension
   local tExtensionPath
   put __extensionPropertyGet(pExtensionID, "download_package_path") into tExtensionPath
   
   # Check the package exists
   if there is not a file tExtensionPath then return __extensionError(pExtensionID,"Could not install extension. Package does not exists: " && tExtensionPath)
   
   # Check the file extension is valid
   set the itemdel to "."
   if the last item of tExtensionPath is not "lce" then return __extensionError(pExtensionID,"Could not install extension. The package extension '"&the last item of tExtensionPath&"' Is not valid. Must be 'lce'.")
   
   # Check the manifest contains a name
   local tExtensionName
   put __extensionManifestValue(pExtensionID, "name") into tExtensionName
   if tExtensionName is "error" then return __extensionError(pExtensionID,"Could not install extension. The package manifest must contain a valid name (com.livecode.extensions.<developer_ID>.<extension_name>)")
   __extensionPropertySet pExtensionID, "name", tExtensionName
   
   # Check the manifest contains a version
   local tExtensionVersion
   put __extensionManifestValue(pExtensionID, "version") into tExtensionVersion
   if tExtensionVersion is "error" then return __extensionError(pExtensionID,"Could not install extension. The package manifest must contain a valid version number (1.2.3 - major,minor,maintenance)")
   __extensionPropertySet pExtensionID, "version", tExtensionVersion
   
   # Check the manifest contains an author
   local tExtensionAuthor
   put __extensionManifestValue(pExtensionID, "author") into tExtensionAuthor
   if tExtensionAuthor is "error" then return __extensionError(pExtensionID,"Could not install extension. The package manifest must contain an author")
   __extensionPropertySet pExtensionID, "author", tExtensionAuthor
   
   # Check the manifest contains an type
   local tExtensionType
   put __extensionManifestValue(pExtensionID, "type") into tExtensionType
   if tExtensionType is "error" then return __extensionError(pExtensionID,"Could not install extension. The package manifest must contain a type")
   __extensionPropertySet pExtensionID, "type", tExtensionType
   
   # Check the manifest contains an title
   local tExtensionTitle
   put __extensionManifestValue(pExtensionID, "title") into tExtensionTitle
   if tExtensionTitle is "error" then return __extensionError(pExtensionID,"Could not install extension. The package manifest must contain a title")
   __extensionPropertySet pExtensionID, "title", tExtensionTitle
   
   # Build the type ID from the name and version
   __extensionPropertySet pExtensionID, "type_id", tExtensionName & "." & tExtensionVersion
   
   # Next step
   send "__extensionInstallRemoveOlderVersions" && pExtensionID to me in 0 milliseconds
end __extensionInstallVerify

on __extensionInstallRemoveOlderVersions pExtensionID
   __extensionSendProgressUpdate pExtensionID, "Removing older versions", 7
   
   local tName
   put __extensionPropertyGet(pExtensionID, "name") into tName
   
   repeat for each line tIndex in the keys of sExtensions
      if tIndex is pExtensionID then next repeat
      if sExtensions[tIndex]["name"] is tName then
         revIDEUninstallExtension tIndex
      end if
   end repeat
   
   # Next step
   send "__extensionInstallExtract" && pExtensionID to me in 0 milliseconds
end __extensionInstallRemoveOlderVersions

# Extract the extension files
on __extensionInstallExtract pExtensionID
   # Update progress
   __extensionSendProgressUpdate pExtensionID, "Extracting extension", 15
   
   # Get the path to the package file
   local tExtensionPackageFile
   put __extensionPropertyGet(pExtensionID, "download_package_path") into tExtensionPackageFile
   
   # Create directory to extract into
   local tExtensionDirectory
   put revIDESpecialFolderPath("temp extensions") & slash & __extensionPropertyGet(pExtensionID, "type_id") into tExtensionDirectory
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
   __extensionPropertySet pExtensionID, "icon", revIDESpecialFolderPath("user extensions") & slash & __extensionPropertyGet(pExtensionID,"type_id") & "/support/icon.png"
   
   revZipCloseArchive tExtensionPackageFile
   
   # Next step
   send "__extensionInstallGuide" && pExtensionID to me in 0 milliseconds
end __extensionInstallExtract

# Install the guide into the IDE
on __extensionInstallGuide pExtensionID
   # Update progress
   __extensionSendProgressUpdate pExtensionID, "Adding user guide to documentation", 30
   
   # Path to user guide
   local tUserGuideFolder
   put revIDESpecialFolderPath("temp extensions") & slash & __extensionPropertyGet(pExtensionID, "type_id") & slash & "docs/guide" into tUserGuideFolder
   
   # Get the name and author required by user guide install function
   local tExtensionName, tExtensionAuthor
   put __extensionPropertyGet(pExtensionID, "name") into tExtensionName
   put __extensionPropertyGet(pExtensionID, "author") into tExtensionAuthor
   
   # Install user guide into the IDE
   revIDEInstallUserGuide tUserGuideFolder, tExtensionName, tExtensionAuthor
   
   send "__extensionInstallAPI" && pExtensionID to me in 500 milliseconds
end __extensionInstallGuide

# Install the extension API into the IDE
on __extensionInstallAPI pExtensionID
   # Update progress
   __extensionSendProgressUpdate pExtensionID, "Adding API to documentation", 45
   
   # Path to user guide
   local tUserAPIFolder
   put revIDESpecialFolderPath("temp extensions") & slash & __extensionPropertyGet(pExtensionID, "type_id") & slash & "docs/api" into tUserAPIFolder
   
   # Get the name and author required by API install function
   local tExtensionName, tExtensionAuthor
   put __extensionPropertyGet(pExtensionID, "name") into tExtensionName
   put __extensionPropertyGet(pExtensionID, "author") into tExtensionAuthor
   
   # Install API into the IDE
   // revIDEInstallAPI tUserAPIFolder, tExtensionName, tExtensionAuthor
   revIDEInstallAPI tUserAPIFolder, tExtensionName, tExtensionAuthor
   
   # Next step
   send "__extensionInstallMakeLive" && pExtensionID to me in 0 milliseconds
end __extensionInstallAPI

on __updateExtensionPropertiesFromManifest pManifestPath, pID
   get __extensionPropertiesFromManifest(pManifestPath)
   if it is not empty then
      put it into sExtensionProperties[pID]
   end if
end __updateExtensionPropertiesFromManifest

# Moves to temp extracted files into their final live location
on __extensionInstallMakeLive pExtensionID
   # Update progress
   __extensionSendProgressUpdate pExtensionID, "Copying extension into install location", 60
   
   # Get path the directories
   local tTempInstallPath, tFinalPath
   put revIDESpecialFolderPath("temp extensions") & slash & __extensionPropertyGet(pExtensionID, "type_id") into tTempInstallPath
   put revIDESpecialFolderPath("user extensions") into tFinalPath
   __extensionPropertySet pExtensionID, "install_path", tFinalPath & slash & __extensionPropertyGet(pExtensionID, "type_id")
   
   # Copy folder from temp directory into live directory
   revCopyFolder tTempInstallPath,tFinalPath
   
   # AL-2015-03-15: [[ Bug 15008 ]] Move interface file to interface folder
   local tInterfaceFile
   put __extensionPropertyGet(pExtensionID, "name") & ".lci" into tInterfaceFile
   if there is a file (tFinalPath & slash &__extensionPropertyGet(pExtensionID, "type_id") & slash & tInterfaceFile) then
      revIDEEnsurePath(tFinalPath & slash & "interface")
      revCopyFile tFinalPath & slash &__extensionPropertyGet(pExtensionID, "type_id") & slash & tInterfaceFile, tFinalPath & slash & "interface" & slash & tInterfaceFile
   end if
   
   # Next step
   send "__extensionInstallLoad" && pExtensionID to me in 0 milliseconds
end __extensionInstallMakeLive

on __extensionInstallLoad pExtensionID
   # Update progress
   __extensionSendProgressUpdate pExtensionID, "Loading extension", 75
   
   # Path to module file
   local tModuleFile
   put revIDESpecialFolderPath("temp extensions") & slash & __extensionPropertyGet(pExtensionID, "type_id") & slash & "module.lcm" into tModuleFile
   
   local tID
   put  __extensionPropertyGet(pExtensionID, "name") into tID
   put __extensionProperties(tID) into sExtensionProperties[tID]
   
   # Load module file into the engine
   local tDataA
   put sExtensions[pExtensionID] into tDataA["copies"][1]
   
   local tExisting
   repeat for each key tExtensionID in sExtensions
      if tExtensionID is pExtensionID then next repeat
      if sExtensions[tExtensionID]["name"] is tID then
         put sExtensions[tExtensionID]["copies"] into tExisting
      end if
   end repeat
   
   repeat for each key tKey in tExisting
      put tExisting[tKey] into tDataA["copies"][tKey + 1]
   end repeat
   
   __extensionLoad tID, tDataA
   
   # Next step
   send "__extensionInstallFinalise" && pExtensionID to me in 0 milliseconds
end __extensionInstallLoad

# Delete installation files and original package
on __extensionInstallFinalise pExtensionID
   # Update progress
   __extensionSendProgressUpdate  pExtensionID, "Removing temp files", 90
   
   # Delete temp install folder
   local tTempInstallPath
   put revIDESpecialFolderPath("temp extensions") & slash & __extensionPropertyGet(pExtensionID, "type_id") into tTempInstallPath
   if there is a folder tTempInstallPath then
      revDeleteFolder tTempInstallPath
   end if
   
   # Delete temp package file
   local tTempInstallPackage
   put revIDESpecialFolderPath("downloading extensions") & slash & __extensionPropertyGet(pExtensionID, "type_id") & ".lce" into tTempInstallPackage
   if there is a file tTempInstallPackage then
      revDeleteFolder tTempInstallPackage
   end if
   
   # Update the cache
   __extensionSendProgressUpdate  pExtensionID, "Complete", 100
   __extensionPropertySet pExtensionID, "status", "installed"
   
   # Notify palettes
   __extensionsChanged
end __extensionInstallFinalise

##############################
# PRIVATE UNINSTALL
##############################

# Check if the widget to be uninstalled is in use
on __extensionUninstallCheckInUse pExtensionID
   # Update progress
   if pExtensionID is not a number then return __extensionError(pExtensionID, "Could not remove extension '" & pExtensionID & "' because it is not a valid index")
   
   __extensionSendProgressUpdate pExtensionID, "Checking if extension is in use", 20
   
   # Next step
   send "__extensionUninstallUnload" && pExtensionID to me in 0 milliseconds
end __extensionUninstallCheckInUse

# Unload the extension
on __extensionUninstallUnload pExtensionID
   # Update progress
   __extensionSendProgressUpdate pExtensionID, "Unloading extension", 40
   
   # Get the extension name
   local tName
   put __extensionPropertyGet(pExtensionID, "name") into tName
   
   # Check if it's loaded
   if tName is among the lines of the loadedExtensions then
      unload extension tName
   end if
   
   # Next step
   send "__extensionUninstallDeleteFiles" && pExtensionID to me in 0 milliseconds
end __extensionUninstallUnload

# Delete the files associated to the extension
on __extensionUninstallDeleteFiles pExtensionID
   # Update progress
   __extensionSendProgressUpdate pExtensionID, "Deleting extension files", 60
   
   # Get the extension isntall path
   local tPath
   put __extensionPropertyGet(pExtensionID, "install_path") into tPath
   
   # Make sure the path contains the folder extension as a check before deleting a folder
   if tPath contains "extension" then
      revDeleteFolder tPath
   end if
   
   # AL-2015-03-15: [[ Bug 15008 ]] Delete interface file from interface folder
   local tInterfaceFile
   put __extensionPropertyGet(pExtensionID, "name") & ".lci" into tInterfaceFile
   if there is a file (specialFolderPath("user extensions") & slash & "interface" & slash & tInterfaceFile) then
      revDeleteFile specialFolderPath("user extensions") & slash & "interface" & slash & tInterfaceFile
   end if
   
   # Next step
   send "__extensionUninstallUpdateCache" && pExtensionID to me in 0 milliseconds
end __extensionUninstallDeleteFiles

# remove from cache
on __extensionUninstallUpdateCache pExtensionID
   # Update progress
   __extensionSendProgressUpdate pExtensionID, "Removing extension data", 80
   
   local tCopies
   put __extensionPropertyGet(pExtensionID, "copies") into tCopies
   if the number of elements in tCopies is 1 then
      delete variable sExtensions[pExtensionID]
   else
      __extensionPropertySet pExtensionID, "status", "uninstalled"
   end if
   
   send "__extensionUninstallDocs" && pExtensionID to me in 0 milliseconds
end __extensionUninstallUpdateCache

# Remove the guide from the IDE
on __extensionUninstallDocs pExtensionID
   # Update progress
   __extensionSendProgressUpdate pExtensionID, "Removing API and user guide from documentation", 90
   
   revIDERegenerateBuiltDictionaryData
   
   send "__extensionUninstallComplete" && pExtensionID to me in 0 milliseconds
end __extensionUninstallDocs

on __extensionUninstallComplete pExtensionID
   # Notify IDE uninstallation complete
   __extensionSendProgressUpdate pExtensionID, "Complete", 100
   
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

function __extensionPropertiesFromManifest pManifestPath
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
   local tOrder
   repeat for each line tProperty in tProperties
      add 1 to tOrder
      local tName, tLabel, tSection
      put revXMLAttribute(tXMLTree,"package" & "/" & tProperty,"name") into tName
      put tMetadataA[tName] into tExtensionData[tName]
      
      if tExtensionData[tName]["section"] is empty then
         put "Basic" into tExtensionData[tName]["section"]
      end if
      
      if tExtensionData[tName]["label"] is empty then
         put tName into tExtensionData[tName]["label"]
      end if
      
      local tType
      put revXMLAttribute(tXMLTree,"package" & "/" & tProperty,"get") into tType
      
      if tExtensionData[tName]["editor"] is empty then 
         if tType is "Integer" or tType is "Real" then
            put "com.livecode.pi.number" into tExtensionData[tName]["editor"]
         else
            put "com.livecode.pi." & tolower(tType) into tExtensionData[tName]["editor"]
         end if
      end if
      
      # Process value options and defaul
      replace comma with return in tExtensionData[tName]["options"]
      replace "\n" with return in tExtensionData[tName]["default"]
      
      local tReadOnly
      get revXMLAttribute(tXMLTree,"package" & "/" & tProperty,"set")
      if it is empty or it begins with "xmlerr" then
         put true into tReadOnly
      else
         put false into tReadOnly
      end if
      put tReadOnly into tExtensionData[tName]["read_only"]
      
      # Keep track of the order the properties were specified and tag the property as a widget
      # property, so we can order them correctly after the built-in props for the given section
      put tOrder into tExtensionData[tName]["order"]
      put true into tExtensionData[tName]["widget_prop"]
      
      
      if tExtensionData[tName]["user_visible"] is empty then
         put true into tExtensionData[tName]["user_visible"]
      end if
   end repeat
   
   revXMLDeleteTree tXMLTree
   return tExtensionData
end __extensionPropertiesFromManifest

function __extensionProperties pTypeID
   set the itemdelimiter to slash
   
   # Get the internal cache ID
   local tIndex
   put __extensionCacheID("name", pTypeID) into tIndex
   
   # Now get the path to the manifest file
   local tManifestPath
   put __extensionPropertyGet(tIndex, "install_path") into tManifestPath
   if tManifestPath is empty then
      put item 1 to -2 of __extensionPropertyGet(tIndex, "download_package_path") into tManifestPath
   end if
   
   if tManifestPath is empty then return empty
   
   put slash & "manifest.xml" after tManifestPath
   if not there is a file tManifestPath then return empty
   
   return __extensionPropertiesFromManifest(tManifestPath)
end __extensionProperties

function __extensionError pExtensionID, pErrorMessage
   __extensionSendProgressUpdate pExtensionID, "Error:" && pErrorMessage, 100
   --put "Error:" && pErrorMessage, 100
   --revIDEUninstallExtension pExtensionID
   return empty
end __extensionError

# Send notication that widget has been added/removed
on __extensionsChanged
   ideMessageSend "ideExtensionsChanged"
end __extensionsChanged

# Sent progress update on installation of widget
on __extensionSendProgressUpdate pExtensionID, pMessage, pProgress
   # Get progress information for extension
   __extensionPropertySet pExtensionID, "progress_message", pMessage
   __extensionPropertySet pExtensionID, "progress", pProgress
   
   local tName
   //revputarray sExtensions
   put __extensionPropertyGet(pExtensionID, "name") into tName
   ideMessageSend "ideExtensionStatusChanged", (tName & comma & pMessage & comma & pProgress)
   
   //local tCallbackTarget, tCallBackHandler
   //put __extensionPropertyGet(pExtensionID, "callback_target") into tCallbackTarget
   //put __extensionPropertyGet(pExtensionID, "callback_handler") into tCallBackHandler
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

on __extensionsLoad
   local tDataA
   revIDEPushDefaultFolder
   
   # Fetch all the available data about extensions in the search paths
   local tFoldersA, tExtensionFolder, tPath
   put revIDEExtensionFolders() into tFoldersA
   set the itemdel to "."
   repeat for each key tKey in tFoldersA
      put tFoldersA[tKey] into tExtensionFolder
      set the defaultfolder to tExtensionFolder
      repeat for each line tFolder in the folders
         if tFolder begins with "." then next repeat
         if tFolder is among the items of "downloading,temp,uninstalled" then next repeat
         
         local tExtensionModulePath, tArray
         put  tExtensionFolder & slash & tFolder & slash & "module.lcm" into tPath
         if there is a file tPath then
            put __fetchModuleData(tPath) into tArray
            if tKey is "ide" then
               put true into tArray["builtin"]
            else
               put false into tArray["builtin"]
            end if
            local tID
            if tArray["name"] is empty then
               put tFolder into tID
            else
               put tArray["name"] into tID
            end if
            put tArray into tDataA[tID][tExtensionFolder][tFolder]
         end if
      end repeat
   end repeat
   
   # Now loop through, checking the status of them
   local tExtensionsList, tExtensionsA, tExtensionCount, tExtensionCopyCount, tExtensionDataA
   put the keys of tDataA into tExtensionsList
   sort tExtensionsList
   
   local tToLoadA, tDependencies
   set the itemdel to ","
   put 1 into tExtensionCount
   repeat for each line tID in tExtensionsList
      put 1 into tExtensionCopyCount
      repeat for each item tItem in "user,ide"
         repeat for each key tFolder in tDataA[tID][tFoldersA[tItem]]
            put tDataA[tID][tFoldersA[tItem]][tFolder] into tExtensionDataA["copies"][tExtensionCopyCount]
            put tFoldersA[tItem] & slash & tFolder into tExtensionDataA["copies"][tExtensionCopyCount]["install_path"]
            add 1 to tExtensionCopyCount
         end repeat
      end repeat
      put tExtensionDataA into tToLoadA[tID]
      # Accumulate an array of dependencies
      repeat for each element tDependent in tExtensionDataA["copies"][1]["requires"]
         if __extensionIsBuiltin(tDependent) then
            next repeat
         end if
         __addToDependencies tId, tDependent, tDependencies
      end repeat
      put empty into tExtensionDataA
   end repeat
   
   # Perform topological sort on list of dependencies so that they are loaded in the correct order
   repeat for each line tLine in __dependencyOrder(tDependencies, the keys of tToLoadA)
      __extensionLoad tLine, tToLoadA[tLine]
   end repeat
   
   revIDEPopDefaultFolder
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
   repeat for each line tExtensionID in the keys of sExtensions
      if sExtensions[tExtensionID][pPropertyToSearch] is pValue then
         return tExtensionID
      end if
   end repeat
end __extensionCacheID

# Gets a property from the internal extension cache
function __extensionPropertyGet pExtensionID, pProperty
   return sExtensions[pExtensionID][pProperty]
end __extensionPropertyGet

# Sets a property in the internal extension cache
on __extensionPropertySet pExtensionID, pProperty, pValue
   put pValue into sExtensions[pExtensionID][pProperty]
end __extensionPropertySet

# Loads an extension
on __extensionLoad pID, pExtensionDataA
   local tLoadedDataA, tToLoadA
   # Only try to load the first copy in the load order
   put pExtensionDataA["copies"][1] into tToLoadA
   
   local tStatus, tError
   if tToLoadA["status"] is not "error" then
      # If we have a resources folder then load with resource path
      if there is a folder (tToLoadA["install_path"] & slash & "resources") then
         load extension from file (tToLoadA["install_path"] & slash & "module.lcm") with resource path (tToLoadA["install_path"] & slash & "resources")
      else
         load extension from file (tToLoadA["install_path"] & slash & "module.lcm")
      end if
      if the result is not empty then
         put toUpper(char 1 of the result) & char 2 to -1 of the result into tError
         put "error" into tStatus
      else
         put "installed" into tStatus
      end if
   else
      put tToLoadA["status"] into tStatus
      put tToLoadA["error"] into tError
   end if
   
   # Find entry in the cache if it exists
   local tIndex
   put __extensionCacheID("install_path", tToLoadA["install_path"]) into tIndex
   
   # If no extry is in the cache, create one
   if tIndex is not a number then
      put the number of elements of sExtensions + 1 into tIndex
   end if
   
   # Pull key into out of manifest etc into extensions cache
   repeat for each key tKey in tToLoadA
      __extensionPropertySet tIndex, tKey, tToLoadA[tKey]
   end repeat
   __extensionPropertySet tIndex, "type_id", pID  & "." & tToLoadA["version"] 
   __extensionPropertySet tIndex, "status", tStatus
   __extensionPropertySet tIndex, "error", tError
   
   put __extensionProperties(pID) into sExtensionProperties[pID]
   
   # Deal with the various icon possibilities
   if sExtensionProperties[pID]["svgIconPath"] is empty and there is a file (tToLoadA["install_path"] & "/support/icon.png") then
      __extensionPropertySet tIndex, "icon", tToLoadA["install_path"] & "/support/icon.png"
   end if
   
   # Load the default script if there is one
   local tDefaultScript
   put revIDEExtensionFetchDefaultScript(tToLoadA["install_path"] , pID, true) into tDefaultScript
   __extensionPropertySet tIndex, "defaultScript", tDefaultScript
   
   # Generate extension API from source if there is not one present in the folder
   # Don't do in an installed IDE as we might not be able to generate the files in the appropriate location
   if not revEnvironmentIsInstalled() and not there is a file (tToLoadA["install_path"] & slash & "api.lcdoc") then
      revIDEExtensionUpdateAPI tToLoadA["install_path"]
   end if
   
end __extensionLoad

function revIDEExtensionFetchDefaultScript pFolder, pExtensionID, pValidate
   if there is a stack (pExtensionID& ".__DefaultScript") then
      return the script of stack (pExtensionID& ".__DefaultScript")
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
         if there is a stack (pExtensionID& ".__DefaultScript") then
            put the script of stack (pExtensionID & ".__DefaultScript") into tScript
         end if
      else
         put the script of stack tDefaultScriptPath into tScript
      end if
      delete stack tDefaultScriptPath
   end if
   unlock messages
   
   return tScript
end revIDEExtensionFetchDefaultScript

function __extensionManifestValue pExtensionID, pProperty
   # Get the path to the package file
   local tExtensionPackageFile
   put __extensionPropertyGet(pExtensionID, "download_package_path") into tExtensionPackageFile
   
   if not there is a file tExtensionPackageFile then return __extensionError(pExtensionID,"Could not extract manifest because package was not found in downloads folder")
   
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

function __extensionManifestValueFromFile pExtensionID, pProperty
   # Get the path to the manifest file
   local tExtensionInstallPath, tManifestFilepath
   put __extensionPropertyGet(pExtensionID, "install_path") into tExtensionInstallPath
   put tExtensionInstallPath & slash & "manifest.xml" into tManifestFilepath
   
   if not there is a file tManifestFilepath then return __extensionError(pExtensionID,"Could not get extension manifest information because extension folder does not contain a manifest file")
   
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
//private on __extensionManifestValue pExtensionID, pManifestKey
//end __extensionManifestValue


##############################
# CALLBACKS
##############################

on extensionUpdateDataReceived
end extensionUpdateDataReceived

function revIDEExtensionDocsData
   local tDataA, tCount
   repeat for each key tExtensionID in sExtensions
      add 1 to tCount
      put __extensionPropertyGet(tExtensionID, "install_path") into tDataA[tCount]["folder"]
      put __extensionPropertyGet(tExtensionID, "title") into tDataA[tCount]["title"]
      put __extensionPropertyGet(tExtensionID, "author") into tDataA[tCount]["author"]
   end repeat
   return tDataA
end revIDEExtensionDocsData

on revIDEExtensionUpdateAPI pFolder, pExtensionSource
   if pExtensionSource is empty then
      local tFiles
      revIDEPushDefaultFolder pFolder
      put the files into tFiles
      filter tFiles with "*.lcb"
      if tFiles is empty then exit revIDEExtensionUpdateAPI
      put line 1 of tFiles into pExtensionSource
      revIDEPopDefaultFolder
   end if
   
   # Check timestamps to see if API  is out of date.
   local tLastGenerated, tLastModified
   put revIDELastModifiedTimeOfFile(pFolder, "api.lcdoc") into tLastGenerated
   put revIDELastModifiedTimeOfFile(pFolder, pExtensionSource) into tLastModified
   
   if tLastGenerated is empty or tLastModified > tLastGenerated then
      local tAPI
      dispatch function "revDocsGenerateDocsFileFromModularFile" to stack "revDocsParser" with (pFolder & slash & pExtensionSource) 
      put the result into tAPI 
      put textEncode(tAPI, "utf-8") into url ("binfile:" & pFolder & slash & "api.lcdoc")
      return "updated"
   end if
end revIDEExtensionUpdateAPI

private on revIDEExtensionFetchMetadata pManifestPath, @rDataA
   local tDataA
   
   local tManifestContents, tId
   put url ("file:" & pManifestPath) into tManifestContents
   put revXMLCreateTree(tManifestContents,true,true,false) into tId
   
   if tId begins with "xmlerr" then
      return "Error: invalid xml in manifest"
   end if
   
   local tTargetType
   put textDecode(revXMLNodeContents(tId, "/package/type"), "utf-8") into tTargetType
   
   if tTargetType begins with "xmlerr" then
      return "Error: no type found in manifest"
   end if
   put tTargetType into tDataA["type"]
   
   local tTargetName
   put textDecode(revXMLNodeContents(tId, "/package/name"), "utf-8") into tTargetName
   if tTargetName begins with "xmlerr" then
      return "Error: couldn't retrieve extension name from manifest"
   end if
   put tTargetName into tDataA["name"]
   
   local tTargetTitle
   put textDecode(revXMLNodeContents(tId, "/package/title"), "utf-8") into tTargetTitle
   
   if tTargetTitle is empty or tTargetTitle begins with "xmlerr" then
      put empty into tTargetTitle
   end if
   put tTargetTitle into tDataA["title"]
   
   local tTargetVersion
   put textDecode(revXMLNodeContents(tId, "/package/version"), "utf-8") into tTargetVersion
   
   if tTargetVersion is empty or tTargetVersion begins with "xmlerr" then
      put empty into tTargetVersion
   end if
   put tTargetVersion into tDataA["version"]
   
   local tTargetAuthor
   put textDecode(revXMLNodeContents(tId, "/package/author"), "utf-8") into tTargetAuthor
   if tTargetAuthor is empty or tTargetAuthor begins with "xmlerr" then
      put empty into tTargetAuthor
   end if
   put tTargetAuthor into tDataA["author"]
   
   local tMetadataValue, tMetadataKey
   local tMetadataNodes, tMetadataA, tKeys, tValue
   put revXMLChildNames(tID, "package",return,"metadata",true) into tMetadataNodes
   repeat for each line tMetadata in tMetadataNodes
      put revXMLAttribute(tID,"package" & "/" & tMetadata,"key") into tMetadataKey
      put revXMLNodeContents(tID,"package" & "/" & tMetadata) into tMetadataValue
      if tMetadataValue is empty or tMetadataValue begins with "xmlerr" then
         put empty into tMetadataValue
      end if
      put tMetadataValue into tDataA[tMetadataKey]
   end repeat
   local tRequires, tCount
   put 0 into tCount
   put revXMLChildNames(tId,"package",return,"requires",true) into tRequires
   repeat for each line tDependency in tRequires
      add 1 to tCount
      local tName
      put revXMLAttribute(tId,"package" & "/" & tDependency,"name") into tName
      put tName into tDataA["requires"][tCount]
   end repeat
   
   # User visible should default to true
   if tDataA["uservisible"] is empty then
      put true into tDataA["uservisible"]
   end if
   
   put tDataA into rDataA
   return empty
end revIDEExtensionFetchMetadata

function revIDEExtensionModuleFile pKind
   # Get the internal cache ID
   local tIndex
   put __extensionCacheID("name", pKind) into tIndex
   
   return __extensionPropertyGet(tIndex, "install_path") & slash & "module.lcm"
end revIDEExtensionModuleFile
