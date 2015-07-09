script "revidelibrary"

on revLoadLibrary
   insert the script of me into back
   revIDEInitialiseIDELibrary
end revLoadLibrary

on revUnloadLibrary
   remove the script of me from back
end revUnloadLibrary

#############
# Internal functions
#############
# Reads all the of the extension files into an internal array which is then used by all revIDEExtension and revIDEWidget
# type functions

local sExtensionData
local sExtensionDataForDisplay

private on __loadExtensions
   local tInactiveExtensionFolder, tExtensionData

   put empty into sExtensionData
   put empty into sExtensionDataForDisplay

   revIDEStoreDefaultFolder

   ## Load installed extensions
   set the folder to revIDESpecialFolderPath("extensions")
   repeat for each line tFile in the files
      if char 1 of tFile is "." then next repeat
      __loadExtension tFile
   end repeat

   revIDERestoreDefaultFolder
   dispatch "ideExtensionsChanged"
end __loadExtensions

private command __loadExtension pExtensionFile
   local tExtensionID, tExtensionPackageData, tIndex, tKeys
   local tExtractedExtensionFolder

   put char 1 to -5 of pExtensionFile into tExtensionID
   put revIDESpecialFolderPath("extensions") into tExtractedExtensionFolder

   ## Check if already extracted
   if there is not a folder (tExtractedExtensionFolder & "/" & pExtensionFile) then
      __extractExtension(revIDESpecialFolderPath("extensions") & "/" & pExtensionFile)
   end if

   # Try to load the extension
   local tExecutableModuleFile
   put revIDESpecialFolderPath("extensions") & slash & tExtensionID & slash & "module.lcm" into tExecutableModuleFile
   if there is a file tExecutableModuleFile then
      load extension from file tExecutableModuleFile
      if the result is not empty then
         __revIDEError("loading extension failed: " && the result)
         return empty
      end if
   end if

   ## Check if already loaded
   if tExtensionID is not among the lines of the keys of sExtensionData then
      put the keys of sExtensionDataForDisplay into tKeys
      replace return with comma in tKeys
      put max(tKeys) + 1 into tIndex

      ## Extract the extension
      --put __extractExtension(revIDESpecialFolderPath("extensions") & "/" & pExtensionFile) into tExtensionPackageData
      put __extensionData(tExtensionID) into tExtensionPackageData

      local tExtenstionTypeID
      put tExtensionPackageData["name"] into tExtenstionTypeID
      put tExtensionPackageData into sExtensionData[tExtenstionTypeID]
      put tExtensionPackageData into sExtensionDataForDisplay[tIndex]
      put "active" into sExtensionData[tExtenstionTypeID]["status"]
      put "active" into sExtensionDataForDisplay[tIndex]["status"]
   end if
end __loadExtension

private function __extensionData pExtensionID
   local tExtractedExtensionFolder, tExtensionFolder, tManifest, tXMLTree, tExtensionData
   local tIsWidget, tIsLibrary, tRequiredNodes

   put revIDESpecialFolderPath("extensions") into tExtractedExtensionFolder
   put tExtractedExtensionFolder & "/" & pExtensionID into tExtensionFolder

   if there is not a folder tExtensionFolder then return empty

   ## Manifest
   put url ("file:" & tExtensionFolder & "/manifest.xml") into tManifest
   if tManifest is empty then return empty

   put revXMLCreateTree(tManifest,true,true,false) into tXMLTree
   put revXMLNodeContents(tXMLTree,"/package/name") into tExtensionData["name"]
   put revXMLNodeContents(tXMLTree,"/package/title") into tExtensionData["label"]
   put revXMLNodeContents(tXMLTree,"/package/description") into tExtensionData["description"]
   put revXMLNodeContents(tXMLTree,"/package/author") into tExtensionData["author"]
   put revXMLNodeContents(tXMLTree,"/package/version") into tExtensionData["version"]
   put revXMLNodeContents(tXMLTree,"/package/license") into tExtensionData["license"]

   if item 1 of tExtensionData["author"] is "xmlerr" then
      put empty into tExtensionData["author"]
   end if

   ## Type
   put revXMLChildNames(tXMLTree,"package",return,"widget",false) into tIsWidget
   put revXMLChildNames(tXMLTree,"package",return,"library",false) into tIsLibrary

   if tIsWidget is "widget" then put "widget" into tExtensionData["type"]
   else if tIsLibrary is "library" then put "library" into tExtensionData["type"]
   else put "widget" into tExtensionData["type"]

   ## Requirements
   put revXMLChildNames(tXMLTree,"package",return,"requires",true) into tRequiredNodes
   repeat with x = 1 to the number of lines in tRequiredNodes
      put revXMLAttribute(tXMLTree,"package" & "/" & line x of tRequiredNodes,"name") into tExtensionData["requires"][x]["name"]
      put revXMLAttribute(tXMLTree,"package" & "/" & line x of tRequiredNodes,"version") into tExtensionData["requires"][x]["version"]
   end repeat

   revXMLDeleteTree tXMLTree

   put (tExtensionFolder & "/manifest.xml") into tExtensionData["manifest_path"]

   ## Icons
   if there is a file (tExtensionFolder & "/icon.png") then put (tExtensionFolder & "/icon.png") into tExtensionData["icon"]

   ## Guide
   if there is a file (tExtensionFolder & "/guide.md") then put (tExtensionFolder & "/guide.md") into tExtensionData["guide"]

   ## API
   if there is a file (tExtensionFolder & "/api.lcdoc") then put (tExtensionFolder & "/api.lcdoc") into tExtensionData["api"]
   return tExtensionData
end __extensionData

private command __extractExtension pFilename
   local tManifest, tExtensionData, tIcon, tFileRoot, tIdentifier, tXMLTree, tRequiredNodes, tType
   local tIsWidget, tIsLibrary, tItems

   if char -3 to -1 of pFilename is not "lce" then return __revIDEError("The file" && pFilename && "is not a valid LiveCode Extension file.")

   local tNewFolderName
   set the itemDel to "/"
   put char 1 to -5 of item -1 of pFilename into tNewFolderName
   revZipOpenArchive pFilename, "read"

   local tZipItems
   put revZipEnumerateItems(pFilename) into tZipItems
   if the last char of line 1 of tZipItems is "/" then
      put line 1 of tZipItems into tFileRoot
   else
      put empty into tFileRoot
   end if

   ## Extract Extension files
   local tExtensionsFolder, tUnzippedExtensionFolder, tIconFile, tLargeIconFile
   put revIDESpecialFolderPath("extensions") into tExtensionsFolder
   put tExtensionsFolder & "/" & tNewFolderName into tUnzippedExtensionFolder

   if there is not a folder tUnzippedExtensionFolder then
      revIDEEnsurePath tUnzippedExtensionFolder
   end if

   ## Manifest
   local tManifestPath
   put tUnzippedExtensionFolder & "/manifest.xml" into tManifestPath
   revZipExtractItemToFile pFilename, (tFileRoot & "manifest.xml"), tManifestPath

   ## Icon files
   put tUnzippedExtensionFolder & "/icon.png" into tIconFile
   revZipExtractItemToFile pFilename, (tFileRoot & "support/icon.png"), tIconFile

   ## Extract any other icon files
   local tUnzippedIconFile
   put revZipEnumerateItems(pFilename) into tItems
   filter tItems with "*icon*"
   repeat for each line tIcon in tItems
      put tUnzippedExtensionFolder & "/" & item -1 tIcon into tUnzippedIconFile
      revZipExtractItemToFile pFilename, tIcon, tUnzippedIconFile
   end repeat

   ## Documentaion

   ## Guide
   local tGuidePath
   put tUnzippedExtensionFolder & "/guide.md" into tGuidePath
   revZipExtractItemToFile pFilename, (tFileRoot & "docs/guide/guide.md"), tGuidePath
   ##-- Rebuild user guide JSON

   ## API
   local tAPIPath
   put tUnzippedExtensionFolder & "/api.lcdoc" into tAPIPath
   revZipExtractItemToFile pFilename, (tFileRoot & "docs/api/api.lcdoc"), tAPIPath
   --   put tAPIPath into tExtensionData["api"]

   ## Executable Module File
   revZipExtractItemToFile pFilename, (tFileRoot & "module.lcm"), tUnzippedExtensionFolder & "/module.lcm"

   revZipCloseArchive pFilename
end __extractExtension

private function __trimZippedData pString
   if codepointToNum(the last char of pString) < 32 then
      delete the last char of pString
   end if
   return pString
end __trimZippedData

# Reads in all the tool data
local sToolDefinition
private on __toolDefinitionsRead
   revIDEStoreDefaultFolder

   put empty into sToolDefinition

   # Set to folder to the path where the object definition files for classic controls are stored
   local tToolDefinitionPath
   put revIDESpecialFolderPath("Tool Definitions") into tToolDefinitionPath
   set the defaultfolder to tToolDefinitionPath

   # Read in each file and build an array
   local tDefinitionData, tToolSection
   repeat for each line tFile in the files
      if char 1 of tFile is "." then next repeat
      set the itemdel to "."
      put item 1 of tFile into tToolSection
      put URL ("file:" & tToolDefinitionPath & slash & tFile) into tDefinitionData

      local tToolID, tCount
      put 1 into tCount
      set the itemdel to ","
      repeat for each line tToolDescription in tDefinitionData
         put item 1 of tToolDescription into tToolID
         put item 2 of tToolDescription into sToolDefinition[tToolSection][tCount]["label"]
         put item 3 of tToolDescription into sToolDefinition[tToolSection][tCount]["icon"]

         local tCount2, tPropertyName, tPropertyValue
         put 1 into tCount2
         repeat for each item tProperty in item 4 of tToolDescription
            set the itemdel to ":"
            put item 1 of tProperty into tPropertyName
            put item 2 of tProperty into tPropertyValue
            put tPropertyValue into sToolDefinition[tToolSection][tCount]["properties"][tCount2][tPropertyName]
            add 1 to tCount2
         end repeat

         add 1 to tCount
      end repeat
   end repeat

   revIDERestoreDefaultFolder
end __toolDefinitionsRead

private function __propertyDataFromInfoFile pFileName
   local tPropertyInfo
   put URL ("file:" & pFileName) into tPropertyInfo

   local tDataStart, tDataA, tPropName
   put false into tDataStart

   local tCountsA, tGroupCountsA
   set the itemdelimiter to tab
   repeat for each line tLine in tPropertyInfo
      if tLine begins with "-----" then
         put true into tDataStart
         next repeat
      end if

      if not tDataStart then
         next repeat
      end if

      if token 1 of tLine is empty then
         next repeat
      end if

      put item 1 of tLine into tPropName
      put item 2 of tLine into tDataA[tPropName]["label"]

      local tSection
      put item 3 of tLine into tSection
      put tSection into tDataA[tPropName]["section"]

      put item 4 of tLine into tDataA[tPropName]["editor"]
      put item 5 of tLine into tDataA[tPropName]["user_visible"]
      put item 6 of tLine into tDataA[tPropName]["read_only"]

      local tGroupName
      put item 7 of tLine into tGroupName
      if tGroupName is empty then
         put tDataA[tPropName]["label"] into tGroupName
      end if
      if tGroupName is empty then
         put tPropName into tGroupName
      end if
      put tGroupName into tDataA[tPropName]["group"]

      if tGroupCountsA[tSection][tGroupName] is empty then
         add 1 to tCountsA[tSection]["count"]
         put tCountsA[tSection]["count"] into tGroupCountsA[tSection][tGroupName]
      end if
      put tGroupCountsA[tSection][tGroupName] into tDataA[tPropName]["group_order"]

      add 1 to tCountsA[tSection][tGroupName]["count"]
      put tCountsA[tSection][tGroupName]["count"] into tDataA[tPropName]["order"]

      put __unescapeString(item 8 of tLine) into tDataA[tPropName]["default"]

      local tOptions
      put item 9 of tLine into tOptions
      replace comma with return in tOptions
      put tOptions into tDataA[tPropName]["options"]

      put item 10 of tLine into tDataA[tPropName]["subsection"]
      
      put item 11 of tLine into tDataA[tPropName]["min"]
      put item 12 of tLine into tDataA[tPropName]["max"]
      put item 13 of tLine into tDataA[tPropName]["step"]
      
      
   end repeat
   return tDataA
end __propertyDataFromInfoFile

private function __organisePropertyInfo pInfoA
   local tOrganisedA
   repeat for each key tKey in pInfoA
      local tSection
      put pInfoA[tKey]["section"] into tSection

      local tGroupLabel
      put pInfoA[tKey]["group"] into tGroupLabel

      # The groups are ordered by their appearance in the spec file
      put pInfoA[tKey]["group_order"] into tOrganisedA[tSection]["grouplist"][tGroupLabel]["order"]
      put pInfoA[tKey]["subsection"] into tOrganisedA[tSection]["grouplist"][tGroupLabel]["subsection"]

      # Carry over the generic prop information into the object prop info array
      put pInfoA[tKey] into tOrganisedA[tSection]["grouplist"][tGroupLabel]["proplist"][tKey]
   end repeat
   return tOrganisedA
end __organisePropertyInfo

local sClassicObjectProperties, sClassicObjectPropertiesInfo, sClassicPropertiesInfo
private on  __setPropertyDataOfObjectFromFile pObjectType, pFile, pPropInfoA
   local tObjectData
   
   # Get the data from the file
   put URL ("file:" & pFile) into tObjectData
   
   # Parse the file into a structure array
   local tObjectPropertiesA, tPropertyName, tCountsA, tGroupCountsA, tSection
   set the itemdel to tab
   
   local tDataStart, tDataA
   put false into tDataStart
   repeat for each line tLine in tObjectData
      if tLine is empty then next repeat
      
      put item 1 of tLine into tPropertyName
      
      if tPropertyName is "type" then
         put item 2 of tLine into sClassicObjectProperties[pObjectType]["type"]
         next repeat
         # Allow 'display title' of classic controls to be specified in property definition file
      else if tPropertyName is "title" and not tDataStart then
         put item 2 of tLine into sClassicObjectProperties[pObjectType]["title"]
      else if tPropertyName begins with "-----" then
         put true into tDataStart
         next repeat
      else if tDataStart is false then
         next repeat
      else
         local tGroupLabel
         put item 4 of tLine into tGroupLabel
         if tGroupLabel is empty then
            put pPropInfoA[tPropertyName]["group"] into tGroupLabel
         else
            # If group label is not empty, it overrides the target group from the property spec file
            put tGroupLabel into pPropInfoA[tPropertyName]["group"]
         end if
         
         put pPropInfoA[tPropertyName] into sClassicObjectProperties[pObjectType]["properties"][tPropertyName]
         put pPropInfoA[tPropertyName]["section"] into tSection
         
         # The groups are ordered by their appearance in the spec file
         if tGroupCountsA[tSection][tGroupLabel] is empty then
            add 1 to tCountsA[tSection]["count"]
            put tCountsA[tSection]["count"] into tGroupCountsA[tSection][tGroupLabel]
         end if
         put tGroupCountsA[tSection][tGroupLabel] into pPropInfoA[tPropertyName]["group_order"]
         
         add 1 to tCountsA[tSection][tGroupLabel]["count"]
         put tCountsA[tSection][tGroupLabel]["count"] into pPropInfoA[tPropertyName]["order"]
         
         # Get the per-object default value of this property
         local tDefault
         put __unescapeString(item 2 of tLine) into tDefault
         if tDefault is not empty then
            if tDefault is "empty" then
               put empty into tDefault
            end if
            put tDefault into pPropInfoA[tPropertyName]["default"]
         end if
         put pPropInfoA[tPropertyName]["default"] into sClassicObjectProperties[pObjectType]["properties"][tPropertyName]["default"]
         
         # If this is an enum property, there are per-object options
         local tOptions
         put item 3 of tLine into tOptions
         if tOptions is not empty then
            replace comma with return in tOptions
            put tOptions into pPropInfoA[tPropertyName]["options"]
         end if
         
         # Read any per-object 'read-only' data
         local tReadOnly
         put item 5 of tLine into tReadOnly
         if tReadOnly is not empty then
            put tReadOnly into pPropInfoA[tPropertyName]["read_only"]
         end if
         
         put pPropInfoA[tPropertyName] into tObjectPropertiesA[tPropertyName]
      end if
   end repeat
   
   put __organisePropertyInfo(tObjectPropertiesA) into sClassicObjectPropertiesInfo[pObjectType]
end __setPropertyDataOfObjectFromFile

private function __propertyInfoFilename
   return "propertyInfo.txt"
end __propertyInfoFilename

# Reads in the basic property data for classic controls
on __objectPropertiesRead
   --put "reading object properties" after msg
   revIDEStoreDefaultFolder

   put empty into sClassicObjectProperties
   put empty into sClassicObjectPropertiesInfo
   put empty into sClassicPropertiesInfo

   # Set to folder to the path where the object definition files for classic controls are stored
   local tObjectDefinitionsPath
   put revIDESpecialFolderPath("Object Property Definitions") into tObjectDefinitionsPath

   local tPropertiesInfo
   put __propertyDataFromInfoFile(tObjectDefinitionsPath & slash & __propertyInfoFilename()) into tPropertiesInfo
   set the defaultfolder to tObjectDefinitionsPath

   # Read in each file and build an array
   local tObjectType

   repeat for each line tFile in the files
      if tFile is __propertyInfoFilename() then next repeat
      if char 1 of tFile is "." then next repeat

      put tFile into tObjectType
      # Get the name of the object
      set the itemdel to "."
      if the last item of tObjectType is "txt" then delete the last item of tObjectType
      if tObjectType is empty then next repeat

      __setPropertyDataOfObjectFromFile tObjectType, tObjectDefinitionsPath & slash & tFile, tPropertiesInfo
   end repeat

   put tPropertiesInfo into sClassicPropertiesInfo

   revIDERestoreDefaultFolder
end __objectPropertiesRead

private function __orderPropSubArray pSectionA, pIsGroupList
   local tSubKey
   if pIsGroupList then
      put "grouplist" into tSubKey
   else
      put "proplist" into tSubKey
   end if
   
   local tPropKeys, tWidgetPropKeys
   repeat for each key tKey in pSectionA[tSubKey]
      if pSectionA[tSubKey][tKey]["widget_prop"] then
         if tWidgetPropKeys is empty then
            put tKey into tWidgetPropKeys
         else
            put return & tKey after tWidgetPropKeys
         end if
      else
         if tPropKeys is empty then
            put tKey into tPropKeys
         else
            put return & tKey after tPropKeys
         end if
      end if
   end repeat
   
   sort lines of tPropKeys ascending numeric by pSectionA[tSubKey][each]["order"]
   sort lines of tWidgetPropKeys ascending numeric by pSectionA[tSubKey][each]["order"]
   
   local tKeys, tCount
   put 1 into tCount
   put tPropKeys into tKeys
   if tWidgetPropKeys is not empty then
      if tKeys is empty then
         put tWidgetPropKeys into tKeys
      else
         put return & tWidgetPropKeys after tKeys
      end if
   end if
   local tOrderedA
   repeat for each line tProp in tKeys
      if pIsGroupList then
         put tProp into tOrderedA[tCount]["label"]
         put pSectionA[tSubKey][tProp]["subsection"] into tOrderedA[tCount]["subsection"]
         put __orderPropSubArray(pSectionA[tSubKey][tProp], false) into tOrderedA[tCount]["proplist"]
      else
         put pSectionA[tSubKey][tProp] into tOrderedA[tCount]
         put tProp into tOrderedA[tCount]["property_name"]
      end if
      add 1 to tCount
   end repeat
   
   return tOrderedA
end __orderPropSubArray

private function __orderPropArray pPropsA, pSections
   local tOrderedPropsA,x

   local tCount
   put 1 into tCount
   repeat for each item tSection in pSections
      if pPropsA[tSection] is empty then next repeat
      put __orderPropSubArray(pPropsA[tSection], true) into tOrderedPropsA[tCount]["grouplist"]
      put tSection into tOrderedPropsA[tCount]["label"]
      add 1 to tCount
   end repeat
   return tOrderedPropsA
end __orderPropArray

private function __objectPropertiesShared pObjectTypeList, pOptionalSection
   local tPropertiesArray,tPropertiesArray2, tPropertiesArray3,x, tSectionProps
   put 1 into x
   repeat for each line tObjectType in pObjectTypeList
      if tObjectType begins with "com.livecode.interface.classic" then
         # Classic control
         if x is 1 then
            put sClassicObjectPropertiesInfo[tObjectType] into tPropertiesArray
            # Restrict to group, if present
            if pOptionalSection is not empty then
               put tPropertiesArray[pOptionalSection] into tSectionProps[pOptionalSection]
               put tSectionProps into tPropertiesArray
            end if

         else
            put sClassicObjectPropertiesInfo[tObjectType] into tPropertiesArray2

            intersect tPropertiesArray with tPropertiesArray2 recursively
         end if
      else
         # Widget
         if x is 1 then
            put revIDEExtensionPropertiesInfo(tObjectType) into tPropertiesArray
            put sClassicObjectPropertiesInfo["com.livecode.interface.classic.widget"] into tPropertiesArray2

            union tPropertiesArray with tPropertiesArray2 recursively

            # Restrict to group, if present
            if pOptionalSection is not empty then
               put tPropertiesArray[pOptionalSection] into tSectionProps[pOptionalSection]
               put tSectionProps into tPropertiesArray
            end if
         else
            put revIDEExtensionPropertiesInfo(tObjectType) into tPropertiesArray2
            put sClassicObjectPropertiesInfo["com.livecode.interface.classic.widget"] into tPropertiesArray3
            union tPropertiesArray2 with tPropertiesArray3 recursively

            intersect tPropertiesArray with tPropertiesArray2 recursively
         end if
      end if
      add 1 to x
   end repeat
   if pOptionalSection is not empty then
      return tPropertiesArray[pOptionalSection]
   else
      return tPropertiesArray
   end if
end __objectPropertiesShared

function revIDEPropertyInfo pPropName
   return sClassicPropertiesInfo[pPropName]
end revIDEPropertyInfo

function revIDEObjectPropertyInfo pObjectType, pPropName
   return sClassicObjectPropertiesInfo[pObjectType][pPropName]
end revIDEObjectPropertyInfo

private function __objectTypes pObjectIDs
   local tObjectTypeList, tObjectType
   repeat for each line tObjectID in pObjectIDs
      put __objectType(tObjectID) into tObjectType
      if tObjectType is not among the lines of tObjectTypeList then
         put tObjectType & return after tObjectTypeList
      end if
   end repeat
   delete the last char of tObjectTypeList
   return tObjectTypeList
end __objectTypes

private function __objectType pObjectID
   switch word 1 of the name of pObjectID
      case "stack"
         return "com.livecode.interface.classic.Stack"
      case "card"
         return "com.livecode.interface.classic.Card"
      case "group"
         if the dgProps["control type"] of pObjectID is "Data Grid" then
            return "com.livecode.interface.classic.DataGrid"
         else
            return "com.livecode.interface.classic.Group"
         end if
         break
      case "field"
         if the tabStops of pObjectID is not empty then
            return "com.livecode.interface.classic.TableField"
         else if the listbehavior of pObjectID is true then
            return "com.livecode.interface.classic.ListField"
         else if the vscrollbar of pObjectID is true then
            return "com.livecode.interface.classic.TextArea"
         else
            return "com.livecode.interface.classic.Field"
         end if
         break
      case "button"
         if the menumode of pObjectID is "combobox" then return "com.livecode.interface.classic.ComboBox"

         switch the style of pObjectID
            case "radiobutton"
               return "com.livecode.interface.classic.RadioButton"
               break
            case "checkbox"
               return "com.livecode.interface.classic.Checkbox"
               break
            case "menu"
               switch the menumode of pObjectID
                  case "combobox"
                     return "com.livecode.interface.classic.ComboBox"
                     break
                  case "option"
                     return "com.livecode.interface.classic.OptionMenu"
                     break
                  case "pulldown"
                     return "com.livecode.interface.classic.PulldownMenu"
                     break
                  case "popup"
                     return "com.livecode.interface.classic.PopupMenu"
                     break
                  default
                     return "com.livecode.interface.classic.TabPanel"
                     break
               end switch
            case "rectangle"
               return "com.livecode.interface.classic.RectangleButton"
               break
            default
               if the default of pObjectID is true then
                  return "com.livecode.interface.classic.DefaultButton"
               else
                  return "com.livecode.interface.classic.Button"
               end if
               break
         end switch
      case "scrollbar"
         switch the style of pObjectID
            case "scale"
               return "com.livecode.interface.classic.Slider"
               break
            case "progress"
               return "com.livecode.interface.classic.ProgressBar"
               break
            case "scrollbar"
               if the height of pObjectID > the width of pObjectID and the height of pObjectID < 54 then
                  return "com.livecode.interface.classic.LittleArrows"
               else
                  return "com.livecode.interface.classic.Scrollbar"
               end if
               break
         end switch
         break
      case "image"
         return "com.livecode.interface.classic.Image"
         break
      case "player"
         return "com.livecode.interface.classic.Player"
      case "widget"
         return the kind of pObjectID
         break
      case "graphic"
         switch the style of pObjectID
            case "rectangle"
               return "com.livecode.interface.classic.RectangleGraphic"
               break
            case "roundrect"
               return "com.livecode.interface.classic.RoundRectGraphic"
               break
            case "line"
               return "com.livecode.interface.classic.LineGraphic"
               break
            case "oval"
               return "com.livecode.interface.classic.OvalGraphic"
               break
            case "curve"
               return "com.livecode.interface.classic.CurveGraphic"
               break
            case "polygon"
               return "com.livecode.interface.classic.PolygonGraphic"
               break
            case "regular"
               return "com.livecode.interface.classic.RegularGraphic"
               break
         end switch
         break
   end switch
end __objectType

private function __dumpArrayRecurse pArray, pLevel, @pCounter, @pList
   local tOrderedKeys
   put the keys of pArray into tOrderedKeys
   sort lines of tOrderedKeys numeric
   repeat for each line tKey in tOrderedKeys

      add 1 to pCounter

      repeat for pLevel
         put tab after line pCounter of pList
      end repeat
      put (tKey && "= ") after line pCounter of pList

      if (the keys of pArray[tKey]) is empty then
         put line 1 of pArray[tKey] after line pCounter of pList
      else
         put __dumpArrayRecurse(pArray[tKey], (pLevel + 1), pCounter, pList) into pList
      end if

   end repeat

   return pList
end __dumpArrayRecurse

function __revIDEError pMessage
   local tErrorContext, tErrorText, tLockedMessages
   put line -2 of the executioncontexts into tErrorContext

   # Unlock messages to ensure the errors get through to the message box
   put the lockmessages into  tLockedMessages
   unlock messages

   put "ERROR:" && pMessage & return & "line:" && item 3 of tErrorContext & return & "handler:" && item 2 of tErrorContext & return & "script object:" && item 1 of tErrorContext into tErrorText
   put return & tErrorText after msg

   # if the messages were locked, lock them again
   if tLockedMessages is true then
      lock messages
   end if

   return tErrorText
end __revIDEError


local sControlPropertiesToRead, sCardPropertiesToRead, sStackPropertiesToRead

function __readStructureOfStackForDataView @pData, pParent, pLevel, pIndex
   local tStackIndex
   # 1) Get desired properties for the current stack
   dispatch function "__readPropertiesOfControlForDataView" to the target with sStackPropertiesToRead, pData,pParent, pLevel, pIndex
   put the result into tStackIndex

   --   # 2) Process any cards
   --   local tChildCardIDs
   --   put empty into tChildCardIDs
   --   repeat with x = 1 to the number of cards of the target
   --      # a) Get basic properties for the card
   --      dispatch function "__readPropertiesOfControlForDataView" to card x of the target with sCardPropertiesToRead, pData, tStackIndex, pLevel + 1
   --      local tCardIndex
   --      put the result into tCardIndex

   --      if tChildCardIDs is empty then
   --         put tCardIndex into tChildCardIDs
   --      else
   --         put comma & tCardIndex after tChildCardIDs
   --      end if

   --      # b) Process the card container for all its controls

   --      dispatch function "__readStructureOfContainerForDataView" to card x of the target with pData, tCardIndex, pLevel + 1
   --      put the result into pData[tCardIndex]["children"]
   --      put false into pData[tCardIndex]["expanded"]
   --      put "container" into pData[tCardIndex]["style"]
   --      put "card" into pData[tCardIndex]["type"]
   --   end repeat

   --   # 3) Process any subsctacks
   --   repeat for each line tSubstack in the substacks of the target
   --      if tChildCardIDs is empty then
   --         put the number of elements of pData + 1 into tChildCardIDs
   --      else
   --         put comma & the number of elements of pData + 1 after tChildCardIDs
   --      end if
   --      dispatch function "__readStructureOfStackForDataView" to stack tSubstack with pData,tStackIndex, pLevel + 1
   --   end repeat

   --   put tChildCardIDs into pData[tStackIndex]["children"]

   --put the number of cards of the target into pData[tStackIndex]["childCount"]
   put the number of cards of the target & the number of lines in the substacks of the target into pData[tStackIndex]["childCount"]
   put false into pData[tStackIndex]["expanded"]
   put "container" into pData[tStackIndex]["style"]
   put "stack" into pData[tStackIndex]["type"]
end __readStructureOfStackForDataView


--function __readStructureOfStackForDataView @pData, pParent, pLevel
--   # 1) Get desired properties for the current stack
--   dispatch function "__readPropertiesOfControlForDataView" to the target with sStackPropertiesToRead, pData,pParent, pLevel
--   local tStackIndex
--   put the result into tStackIndex

--   # 2) Process any cards
--   local tChildCardIDs
--   put empty into tChildCardIDs
--   repeat with x = 1 to the number of cards of the target
--      # a) Get basic properties for the card
--      dispatch function "__readPropertiesOfControlForDataView" to card x of the target with sCardPropertiesToRead, pData, tStackIndex, pLevel + 1
--      local tCardIndex
--      put the result into tCardIndex

--      if tChildCardIDs is empty then
--         put tCardIndex into tChildCardIDs
--      else
--         put comma & tCardIndex after tChildCardIDs
--      end if

--      # b) Process the card container for all its controls

--      dispatch function "__readStructureOfContainerForDataView" to card x of the target with pData, tCardIndex, pLevel + 1
--      put the result into pData[tCardIndex]["children"]
--      put false into pData[tCardIndex]["expanded"]
--      put "container" into pData[tCardIndex]["style"]
--      put "card" into pData[tCardIndex]["type"]
--   end repeat

--   # 3) Process any subsctacks
--   repeat for each line tSubstack in the substacks of the target
--      if tChildCardIDs is empty then
--         put the number of elements of pData + 1 into tChildCardIDs
--      else
--         put comma & the number of elements of pData + 1 after tChildCardIDs
--      end if
--      dispatch function "__readStructureOfStackForDataView" to stack tSubstack with pData,tStackIndex, pLevel + 1
--   end repeat

--   put tChildCardIDs into pData[tStackIndex]["children"]
--   put false into pData[tStackIndex]["expanded"]
--   put "container" into pData[tStackIndex]["style"]
--   put "stack" into pData[tStackIndex]["type"]
--end __readStructureOfStackForDataView

function __readStructureOfContainerForDataView @pData, pParentIndex, pLevel
   # 1) Repeat for each control in the container
   local tChildIDs, tChildCount

   //repeat with x = 1 to the number of controls of the target
   --repeat for each line tControlId in the childcontrolIDs of the target
   put the number of lines in the childcontrolIDs of the target into tChildCount
   repeat with x = 1 to the number of lines in the childcontrolIDs of the target
      local tControlId
      if revIDEGetPreference("ideProjectBrowser_sortOrder") is "bottom to top" then
         put line x of the childcontrolIDs of the target into tControlId
      else
         put line (tChildCount -x) + 1 of the childcontrolIDs of the target into tControlId
      end if

      # read the properties of the control
      local tIndex
      dispatch function "__readPropertiesOfControlForDataView" to control ID tControlID of the target with sControlPropertiesToRead, pData, pParentIndex, pLevel + 1
      put the result into tIndex
      if tChildIDs is empty then
         put tIndex into tChildIDs
      else
         put comma & tIndex after tChildIDs
      end if

      #  if the control is a group
      if the name of control ID tControlID of the target begins with "group" then
         local tIndexStart
         put the number of elements of pData into tIndexStart

         dispatch function "__readStructureOfContainerForDataView" to control ID tControlID of the target with pData, tIndex, pLevel + 1

         put the result into pData[tIndex]["children"]
         --add the number of elements of pData - tIndexStart to x
         put false into pData[tIndex]["expanded"]
         put "group" into pData[tIndex]["style"]
      else
         put "control" into pData[tIndex]["style"]
      end if
   end repeat
   return tChildIDs
end __readStructureOfContainerForDataView

# Used internall but not private. This function is dispatched to the object and reads the properties
# In the list. Sending it to the object allows the use of the target which reduces the lookup time
# for each of the properties
function __readPropertiesOfControlForDataView pList, @pData, pParentIndex, pLevel,pIndex
   local tIndex
   put pIndex + the number of elements of pData + 1 into tIndex

   put pParentIndex into pData[tIndex]["parent"]
   --put empty into pList
   repeat for each line tProp in pList
      try
         switch tProp
            case "short name"
               put the short name of the target into pData[tIndex][tProp]
               break
            case "scriptlines"
               put the number of lines of the script of the target into pData[tIndex][tProp]
               break
            case "behavior scriptlines"
               put the number of lines of the script of the behavior of the target into pData[tIndex][tProp]
               break
            case "long id"
               put the long id of the target into pData[tIndex][tProp]
               break
            case "owner"
               put the long id of the owner of the target into pData[tIndex][tProp]
               break
            case "type"
               put word 1 of the name of the target into pData[tIndex]["type"]
               break
            default
               put the tProp of the Target into pData[tIndex][tProp]
               break
         end switch
         put the short name of the target into pData[tIndex]["name"]
         put false into pData[tIndex]["expanded"]
         put pLevel into pData[tIndex]["level"]
      end try
   end repeat
   return tIndex
end __readPropertiesOfControlForDataView

function __readStructureOfStack @pData
   # 1) Get desired properties for the current stack
   dispatch function "__readPropertiesOfControl" to the target with sStackPropertiesToRead, pData

   # 2) Process any cards
   repeat with x = 1 to the number of cards of the target
      # a) Get basic properties for the card
      dispatch function "__readPropertiesOfControl" to card x of the target with sCardPropertiesToRead, pData["cards"][x]

      # b) Process the card container for all its controls
      dispatch function "__readStructureOfContainer" to card x of the target with pData["cards"][x]["controls"]
   end repeat

   # 3) Process any subsctacks
   repeat for each line tSubstack in the substacks of the target
      dispatch function "__readStructureOfStack" to stack tSubstack with pData["substacks"][x]
   end repeat
end __readStructureOfStack

function __readStructureOfContainer @pData
   local tControlsProcessedInContainer

   # 1) Repeat for each control in the container
   repeat with x = 1 to the number of controls of the target
      # read the properties of the control
      dispatch function "__readPropertiesOfControl" to control x of the target with sControlPropertiesToRead, pData[x]

      --local tName
      --put the name of control x of the target into tName

      #  if the control is a group
      if the name of control x of the target begins with "group" then

         dispatch function "__readStructureOfContainer" to control x of the target with pData[x]["controls"]
         put the result into tControlsProcessedInContainer
         add the number of elements of pData[x]["controls"] to tControlsProcessedInContainer
         add tControlsProcessedInContainer to x
      end if
   end repeat

   return tControlsProcessedInContainer
end __readStructureOfContainer

function __readGroupedPropertiesOfControl pGroupsA, @pDataA
   local tPropMappingA, tProp
   repeat for each key tGroup in pGroupsA
      repeat for each key tProp in pGroupsA[tGroup]["proplist"]
         put tGroup into tPropMappingA[tProp]
      end repeat
   end repeat

   local tDataA
   repeat for each key tKey in tPropMappingA
      __fetchPropertyOfControl tKey, tDataA
   end repeat

   local tValue, tEffective
   set the itemdelimiter to ":"
   repeat for each key tKey in tDataA
      if tKey begins with "effective" then next repeat
      put false into tEffective
      put tDataA[tKey] into tValue
      put tPropMappingA[tKey] into tGroup
      if tValue is empty and tDataA["effective" && tKey] is not empty then
         put tDataA["effective" && tKey] into tValue
         put true into tEffective
      end if
      put pGroupsA[tGroup]["proplist"][tKey] into pDataA[tGroup][tKey]
      put tValue into pDataA[tGroup][tKey]["value"]
      put tEffective into pDataA[tGroup][tKey]["effective"]
   end repeat
end __readGroupedPropertiesOfControl

private on __fetchPropertyOfControl pProp, @pData
   local tError
   put empty into tError
   try
      switch pProp
         case "short name"
            put the short name of the target into pData[pProp]
            break
         case "scriptlines"
            put the number of lines of the script of the target into pData[pProp]
            break
         case "behavior scriptlines"
            put the number of lines of the script of the behavior of the target into pData[pProp]
            break
         case "long id"
            put the long id of the target into pData[pProp]
            break
         case "owner"
            put the long id of the owner of the target into pData[pProp]
            break
         case "type"
            put word 1 of the name of the target into pData["type"]
            break
         case "customProperties"
            put __customPropertyData(the long id of the target) into pData["customProperties"]
            break
         case "dropShadow"
         case "innerShadow"
         case "outerGlow"
         case "innerGlow"
         case "colorOverlay"
            put the pProp of the Target into pData[pProp]
            if pData[pProp] is empty then
               put empty into pData[pProp]["color"]
               put empty into pData[pProp]["blendMode"]
               put empty into pData[pProp]["opacity"]
               put empty into pData[pProp]["filter"]
               put empty into pData[pProp]["spread"]
               put empty into pData[pProp]["size"]
               put empty into pData[pProp]["distance"]
               put empty into pData[pProp]["angle"]
            end if
            break
         default
            put the pProp of the Target into pData[pProp]
            break
      end switch
      put the short name of the target into pData["name"]
   catch tError
   end try

   if tError is not empty then
      try
         do ("put" && pProp && "of" && the target && "into pData[pProp]")
      catch tError
      end try
   end if

   if pData[pProp] is empty then
      try
         local tEffective
         do ("put effective" && pProp && "of" && the target && "into tEffective")
         if tEffective is not empty then
            put tEffective into pData["effective" && pProp]
         end if
      catch tError
      end try
   end if
end __fetchPropertyOfControl

# Used internall but not private. This function is dispatched to the object and reads the properties
# In the list. Sending it to the object allows the use of the target which reduces the lookup time
# for each of the properties
function __readPropertiesOfControl pList, @pData
   local tError
   repeat for each line tProp in pList
      __fetchPropertyOfControl tProp, pData
   end repeat
end __readPropertiesOfControl

private function __readControlPropertiesForDataView pList
   local tData
   repeat for each line tProp in pList
      try
         switch tProp
            case "short name"
               put the short name of the target into tData[tProp]
               break
            case "scriptlines"
               put the number of lines of the script of the target into tData[tProp]
               break
            case "behavior scriptlines"
               put the number of lines of the script of the behavior of the target into tData[tProp]
               break
            case "long id"
               put the long id of the target into tData[tProp]
               break
            case "owner"
               put the long owner of the target into tData[tProp]
               break
            case "type"
               put word 1 of the name of the target into tData["type"]
               break
            default
               put the tProp of the Target into tData[tProp]
               break
         end switch
      end try
   end repeat
   put the short name of the target into tData["name"]
   return tData
end __readControlPropertiesForDataView

function __customPropertyData pLongID
   local tArray, tSets, tProps

   put the customPropertySets of pLongID into tSets
   if tSets is empty then
      put the customProperties of pLongID into tArray[""]--["customKeys"]
   else
      set the customPropertySet of pLongID to empty
      get the customProperties of pLongID
      put it into tArray[""]--["customKeys"]
      repeat for each line tSet in tSets
         set the customPropertySet of pLongID to tSet
         get the customProperties of pLongID
         put it into tArray[tSet]--["customKeys"]
      end repeat
      set the customPropertySet of pLongID to empty
   end if
   local tDataArray
   put revIDEPropertyInfo("customProperties") into tDataArray["Custom properties"]["customProperties"]
   put tArray into tDataArray["Custom properties"]["customProperties"]["value"]
   return tDataArray
end __customPropertyData

function __unescapeString pString
   --if pString contains "\n" then breakpoint
   replace "\n" with return in pString
   return pString
end __unescapeString

on revIDEOpenPropertyInspectorControllerStacks
   lock screen
   revIDEStoreDefaultFolder

   local tControllersFolder
   put revIDESpecialFolderPath("Toolset") & slash & "propertyInspectorControllers" into tControllersFolder
   set the defaultfolder to tControllersFolder

   repeat for each line tControllerStackFile in the files
      if char 1 of tControllerStackFile is "." then next repeat
      --      //put (tControllersFolder & slash & tControllerStackFile) & return after msg
      --      if there is a stack (char 1 to -5 of tControllerStack) then next repeat
      if there is a file (tControllersFolder & slash & tControllerStackFile) then
         lock messages
         go invisible stack (tControllersFolder & slash & tControllerStackFile)
         unlock messages
      end if
   end repeat

   revIDERestoreDefaultFolder
   unlock screen
end revIDEOpenPropertyInspectorControllerStacks

on revIDEInitialiseIDELibrary
   # Load fonts
   start using font file (revIDESpecialFolderPath("fonts") & slash & "lcideicons.ttf")
   start using font file (revIDESpecialFolderPath("fonts") & slash & "fontawesome.ttf")

   # Setup the default lists of properties to read from objects when reading the structure of a stack
   put "name" & return & "visible" & return & "cantselect" & return & "layer" & return & "long id" & return & "label" & return & "behavior" & return & "scriptlines" & return & "short name" & return & "owner" & return & "behavior" & return & "behavior scriptlines" & return & "type" into sControlPropertiesToRead
   put "scriptlines" & return & "short name" & return & "owner" & return & "behavior" & return & "behavior scriptlines" & return & "long id" into sCardPropertiesToRead
   put "scriptlines" & return & "short name" & return & "behavior" & return & "behavior scriptlines" & return & "long id" into sStackPropertiesToRead

   ## Load property inspector controller stacks
   --revIDEOpenPropertyInspectorControllerStacks

   ## Load Extensions
   revIDEInitialiseExtensions

   ## Regenerate dictionary data
   revIDERegenerateBuiltDictionaryData

   ## Initialise property library
   revIDEPropertyLibraryInitialise

end revIDEInitialiseIDELibrary

#############
# Subscription
#############
# Stores subscriptions in the following format
# sSubscriptions[message][callback targets] = List of object ID's
local sSubscriptions
/*
Subscribes the calling object to receive the specified IDE message

pMessage (enum): The message to subscribe to:
- ideSelectedObjectsChanged: Sent when the selected object(s) changes. When a user clicks and drags to select objects, this message is NOT sent. Instead, it waits until the drag action ends.
- ideObjectSelectionStarted: Sent when a user starts to selected items in edit mode using a click and drag.

pOptional (string): If subscribing to a message that takes a parameter, specifiy the parameter as a string. For example, when subscribing for idePreferenceChanged, pass the name of the preference you wish to know about

Example:
on preOpenStack
   revIDESubscribe "ideSelectedObjectsChanged"
end preOpenStack

on ideSelectedObjectsChanged
   # Handle the notification
end ideSelectedObjectsChanged
*/
on __revIDEAddSubscription pMessage, pCallingObject
   if sSubscriptions[pMessage]["callback targets"] is empty then
      put pCallingObject into sSubscriptions[pMessage]["callback targets"]
   else if pCallingObject is not among the lines of sSubscriptions[pMessage]["callback targets"] then
      put return & pCallingObject after sSubscriptions[pMessage]["callback targets"]
   else
      return "Already subscribed"
   end if
end __revIDEAddSubscription

on revIDESubscribe pMessage, pObjectList
   # Validate input
   if not revIDEMessageIsValid(pMessage) then
      return __revIDEError("The message ("&pMessage&") that you are trying to subscribe to is not valid. Please check the documentation for which messages you can subscribe to.")
   end if

   # Get the log ID of the calling object
   local tCallingObjectID
   put the long ID of the target into tCallingObjectID

   # Special case propertyChanged where we have to register for listeners for obejcts
   if pMessage is "idePropertyChanged" then
      repeat for each line tObject in pObjectList
         revIDEPropertyRegisterListenerForObject tObject
         __revIDEAddSubscription pMessage & "," & tObject, tCallingObjectID
      end repeat
   else if pMessage is "ideMoveStack" then
      repeat for each line tObject in pObjectList
         __revIDEAddSubscription pMessage & "," & tObject, tCallingObjectID
      end repeat
   else
      __revIDEAddSubscription pMessage, tCallingObjectID
   end if

   if the result is not empty then
      return the result
   end if
end revIDESubscribe

/*
Unsubscribes the calling object from the given message

pMessage (enum): The message to unsubscribe from. Must be a valid message as described in [revIDESubscribe].
pObject (String): The long ID of the object you wish to unsubscribe from the message. This is an optional parameter, if not specified, the calling object will be used.
*/
on revIDEUnsubscribe pMessage, pObject, pObjectList
   # If not object is specified, get the long ID of the calling object
   if pObject is empty then
      put the long ID of the target into pObject
   end if

   # Special case propertyChanged where we have to register for listeners for obejcts
   if pMessage is "idePropertyChanged" then
      repeat for each line tObject in pObjectList
         delete line lineoffset(pObject, sSubscriptions[pMessage & "," & tObject]["callback targets"]) of sSubscriptions[pMessage & "," & tObject]["callback targets"]
         # If the object is no longer needed, unlisten.
         if sSubscriptions[pMessage & "," & tObject]["callback targets"] is empty then
            revIDEPropertyDeregisterListenerForObject tObject
         end if
      end repeat
   else if pMessage is "ideMoveStack" then
      repeat for each line tObject in pObjectList
         delete line lineoffset(pObject, sSubscriptions[pMessage & "," & tObject]["callback targets"]) of sSubscriptions[pMessage & "," & tObject]["callback targets"]
      end repeat
   else
      # Delete the calling object from the message: sSubscriptions[pMessage]["callback targets"]
      if lineoffset(pObject, sSubscriptions[pMessage]["callback targets"]) > 0 then
         delete line lineoffset(pObject, sSubscriptions[pMessage]["callback targets"]) of sSubscriptions[pMessage]["callback targets"]
      end if
   end if
end revIDEUnsubscribe

/*
Unsubscribes the object from all messages

pObject (String): The long ID of the object you wish to unsubscribe from all message. This is an optional parameter, if not specified, the calling object will be used.
*/
on revIDEUnsubscribeAll pObject
   # If not object is specified, get the long ID of the calling object
   if pObject is empty then
      put the long ID of the target into pObject
   end if

   # Loop through messages and unsubscribe
   repeat for each key tMessage in sSubscriptions
      revIDEUnsubscribe tMessage, pObject
   end repeat
end revIDEUnsubscribeAll

/*
Use to find out which messages the calling object is subscribed to.

returns (string): Return delimited list of messages, 1 per line.
*/
function revIDESubscriptions
   # Get the log ID of the calling object
   local tCallingObjectID
   put the long ID of the target into tCallingObjectID

   # Build a list of all the message names the calling object is subscribed to
   local tSubscriptions
   repeat for each key tMessage in sSubscriptions
      if tCallingObjectID is among the lines of sSubscriptions[tMessage]["callback targets"] then
         put tMessage & return after tSubscriptions
      end if
   end repeat
   delete the last char of tSubscriptions

   return tSubscriptions
end revIDESubscriptions

/*
Use to find out which objects are subscribed to a given message

pMessage (String): The name of the message.

returns (string): Return delimited list of object ID's, 1 per line.
*/
function revIDESubscribedObjects pMessage
   # Validate input
   if not revIDEMessageIsValid(pMessage) then
      return __revIDEError("The message ("&pMessage&") you are enquiring about is not valid. Please check the documentation for which messages you can subscribe to.")
   end if

   return sSubscriptions[pMessage]["callback targets"]
end revIDESubscribedObjects

/*
Use to get a list of all the messages that the IDE allows subscriptions for

related: revIDESubscribedObjects, revIDESubscriptions, revIDEUnsubscribe, revIDESubscribe

returns (string): Return delimited list of message names, 1 per line.
*/
function revIDEMessages
   return ( \
         "ideAnswerDialogClosed,ideControlDeleted,ideCardDeleted,ideEditScript,ideExtensionLog,ideExtensionsChanged,ideExtensionStatusChanged,ideFindMoreWidgets," \
         & "ideInspectedObjectsChanged,ideLibraryStack,ideNewCard,ideNewStack,ideNewControl,revIDENameChanged,ideObjectSelectionStarted,ideOpenStack," \
         & "idePluginsChanged,idePreferenceChanged,idePropertyChanged,ideReleaseStack,ideResumeStack,ideSelectedObjectChanged,ideStackDeleted,ideToolChanged," \
         & "ideTutorialProgressChanged,ideWindowsChanged" \
         )
end revIDEMessages

function revIDEMessageIsValid pMessage
   return true
   return (pMessage is among the items of revIDEMessages() \
         or pMessage begins with "idePreferenceChanged" \
         or pMessage begins with "ideInspectObjects" \
         or pMessage begins with "ideToggleChanged")
end revIDEMessageIsValid

# System function telling the IDE to send
on revIDEMessageSend pMessage, pEffectedTarget
   lock screen
   --put the milliseconds & pMessage, pEffectedTarget & return & line 1 to 50 of msg into msg

   # Validate input
   if not revIDEMessageIsValid(pMessage) then
      return __revIDEError("The message ("&pMessage&") you have requested to be sent is not a valid IDE message. Please check the documentation for which messages you can subscribe to.")
   end if

   # If in run mode don't send any updates
   //if the tool is not "pointer tool" then exit revIDEMessageSend

   local tSubscriptionList
   if pMessage is "idePropertyChanged" or pMessage is "ideMoveStack" then
      local tTargetsA, tSubscription
      repeat for each line tLine in pEffectedTarget
         put pMessage & "," & tLine into tSubscription
         repeat for each line tTarget in sSubscriptions[tSubscription]["callback targets"]
            put true into tTargetsA[tTarget]
         end repeat
      end repeat
      put the keys of tTargetsA into tSubscriptionList
   else
      put sSubscriptions[pMessage]["callback targets"] into tSubscriptionList
   end if

   repeat for each line tObjectID in tSubscriptionList
      # if the callback object doesn't exist, don't send message
      if not exists(tObjectID) then
         revIDEUnsubscribeAll tObjectID
         next repeat
      end if
      
      local tStackID
      set the itemdel to "stack"
      put tObjectID into tStackID
      delete item 1 of tStackID
      if tStackID begins with "tack" then delete char 1 to 4 of tStackID
      put "stack" before tStackID
      # If the stack isn't visible on screen, don't send a message
      # Unless it is the menubar, which should always be able to receive messages
      if the mode of tStackID is 0 or (tStackID is not the long name of stack revIDEPaletteToStackName("menubar") and the visible of tStackID is false) then 
         next repeat
      end if
      
      # Send the message!
      set the itemdel to ":"
      local tMessage
      put item 1 of pMessage into tMessage

      switch tMessage
         case "idePreferenceChanged"
         case "ideToggleChanged"
            dispatch tMessage to tObjectID with item 2 of pMessage
            break
         case "ideFindMoreWidgets"
            dispatch pMessage to tObjectID with pEffectedTarget
            break
         case "ideNewStack"
            try
               send pMessage && pEffectedTarget to tObjectID in 10 milliseconds
            catch tError
            end try
            break
         case "idePropertyChanged"
         case "ideMoveStack"
            dispatch pMessage to tObjectID with pEffectedTarget
            break
         default
            dispatch pMessage to tObjectID with pEffectedTarget
            break
      end switch

      --put "SENT" && the milliseconds && pMessage && "sent to" && tObjectID & return & line 1 to 20 of msg into msg
   end repeat
   unlock screen
end revIDEMessageSend

#############
# Data
#############
function revIDEGraphics
   if sClassicObjectProperties is empty then __objectPropertiesRead

   local tReturnData
   repeat for each key tIndex in sClassicObjectProperties
      if sClassicObjectProperties[tIndex]["type"] is "graphic" and sClassicObjectProperties[tIndex]["properties"]["tool"]["label"] is empty then
         put sClassicObjectProperties[tIndex] into tReturnData[tIndex]
      end if
   end repeat
   return tReturnData
end revIDEGraphics

function revIDEGraphicTools
   if sClassicObjectProperties is empty then __objectPropertiesRead

   local tReturnData
   repeat for each key tIndex in sClassicObjectProperties
      if sClassicObjectProperties[tIndex]["type"] is "graphic" and sClassicObjectProperties[tIndex]["properties"]["tool"]["label"] is not empty then
         put sClassicObjectProperties[tIndex] into tReturnData[tIndex]
      end if
   end repeat
   return tReturnData
end revIDEGraphicTools

function revIDEPaintTools
   local tReturnData
   put "tool" into tReturnData["com.livecode.tool.Select"]["type"]
   put "select tool" into tReturnData["com.livecode.tool.Select"]["tool"]
   put "Select Tool - Select a rectangle area of an image" into tReturnData["com.livecode.tool.Select"]["tooltip"]
   put 7 into tReturnData["com.livecode.tool.Select"]["order"]

   put "tool" into tReturnData["com.livecode.tool.Bucket"]["type"]
   put "bucket tool" into tReturnData["com.livecode.tool.Bucket"]["tool"]
   put "Bucket Tool - Fills on outline in an image" into tReturnData["com.livecode.tool.Bucket"]["tooltip"]
   put 3 into tReturnData["com.livecode.tool.Bucket"]["order"]

   put "tool" into tReturnData["com.livecode.tool.SprayCan"]["type"]
   put "spray tool" into tReturnData["com.livecode.tool.SprayCan"]["tool"]
   put "Spray Can Tool - Draws airbrush strokes on an image" into tReturnData["com.livecode.tool.SprayCan"]["tooltip"]
   put 4 into tReturnData["com.livecode.tool.SprayCan"]["order"]

   put "tool" into tReturnData["com.livecode.tool.Eraser"]["type"]
   put "eraser tool" into tReturnData["com.livecode.tool.Eraser"]["tool"]
   put "Eraser Tool - Erases an area in an image" into tReturnData["com.livecode.tool.Eraser"]["tooltip"]
   put 8 into tReturnData["com.livecode.tool.Eraser"]["order"]

   put "tool" into tReturnData["com.livecode.tool.Polygon"]["type"]
   put "polygon tool" into tReturnData["com.livecode.tool.Polygon"]["tool"]
   put "Polygon Tool - Click to set each point on the polygon, double click to close the polygon" into tReturnData["com.livecode.tool.Polygon"]["tooltip"]
   put 5 into tReturnData["com.livecode.tool.Polygon"]["order"]

   put "tool" into tReturnData["com.livecode.tool.Curve"]["type"]
   put "curve tool" into tReturnData["com.livecode.tool.Curve"]["tool"]
   put "Curve Tool - Draws a curved line on an image" into tReturnData["com.livecode.tool.Curve"]["tooltip"]
   put 6 into tReturnData["com.livecode.tool.Curve"]["order"]

   put "tool" into tReturnData["com.livecode.tool.Pencil"]["type"]
   put "pencil tool" into tReturnData["com.livecode.tool.Pencil"]["tool"]
   put "Pencil Tool - Draws a freehand line on an image" into tReturnData["com.livecode.tool.Pencil"]["tooltip"]
   put 1 into tReturnData["com.livecode.tool.Pencil"]["order"]

   put "tool" into tReturnData["com.livecode.tool.Brush"]["type"]
   put "brush tool" into tReturnData["com.livecode.tool.Brush"]["tool"]
   put "Brush Tool - Draws freehand brush strokes on an image" into tReturnData["com.livecode.tool.Brush"]["tooltip"]
   put 2 into tReturnData["com.livecode.tool.Brush"]["order"]

   return tReturnData
end revIDEPaintTools

function revIDEPaintToolControllers
   local tReturnData
   put "property" into tReturnData["com.livecode.globalproperty.brush"]["type"]
   put "brush" into tReturnData["com.livecode.globalproperty.brush"]["property_name"]
   put "Set the brush size to change the effect of the brush or eraser" into tReturnData["com.livecode.globalproperty.brush"]["tooltip"]
   put "1" & return & "2" & return & "3" & return & "4" into tReturnData["com.livecode.globalproperty.brush"]["options"]
   return tReturnData
end revIDEPaintToolControllers

function revIDERunEditTools
   local tReturnData
   put "tool" into tReturnData["com.livecode.tool.Browse"]["type"]
   put "browse tool" into tReturnData["com.livecode.tool.Browse"]["tool"]
   put "Browse Tool - Your stack is running and can be interacted with" into tReturnData["com.livecode.tool.Browse"]["tooltip"]
   put 1 into tReturnData["com.livecode.tool.Browse"]["order"]

   put "tool" into tReturnData["com.livecode.tool.Pointer"]["type"]
   put "pointer tool" into tReturnData["com.livecode.tool.Pointer"]["tool"]
   put "Pointer Tool - Select and edit objects" into tReturnData["com.livecode.tool.Pointer"]["tooltip"]
   put 2 into tReturnData["com.livecode.tool.Pointer"]["order"]

   return tReturnData
end revIDERunEditTools

function revIDEClassicControls
   if sClassicObjectProperties is empty then __objectPropertiesRead

   local tReturnData
   repeat for each key tIndex in sClassicObjectProperties
      if tIndex is "com.livecode.interface.classic.widget" then next repeat
      if sClassicObjectProperties[tIndex]["type"] is not among the items of "graphic,stack,card,group" then
         put sClassicObjectProperties[tIndex] into tReturnData[tIndex]
      end if
   end repeat
   return tReturnData
end revIDEClassicControls

/*
For a given list of object, returns a structured array of properties, values and other meta data.
pObjects (string list): A list of ID's of the objects you wish the properties for.
related: alksdfklasdf
example: revIDEGetPropertiesOfObjects button 1
pObjects (String List): A list of object ID's you wish the common properties for.
Return (Array): An array keyed by the names of the properties
Description:
# jkldsafgjlkasd
This is a new section
## This is a subsection
*/
function revIDEGetPropertiesOfObjects pObjects
   # Validation that all the objects in the list exist
   repeat for each line tObject in pObjects
      if not exists(tObject) then return __revIDEError("Not all objects in the list provided exist")
   end repeat

   # Work out the type of the selected objects
   local tObjectTypeList
   put __objectTypes(pObjects) into  tObjectTypeList

   # Get this list of all the properties to read for the given type list
   local tSharedProperties
   put __objectPropertiesShared(tObjectTypeList) into tSharedProperties

   # Generate a list of the properties we want to retreive
   local tPropertyValues
   repeat for each line tObject in pObjects
      dispatch function "__readPropertiesOfControl" to tObject with the keys of tSharedProperties, tPropertyValues

      repeat for each key tPropertyName in tPropertyValues
         if tPropertyName begins with "effective" then next repeat
         if tPropertyValues["effective" && tPropertyName] is not empty then
            put tPropertyValues["effective" && tPropertyName] into tSharedProperties[tPropertyName]["effective value"][tObject]
         end if
         put tPropertyValues[tPropertyName] into tSharedProperties[tPropertyName]["value"][tObject]
      end repeat
   end repeat

   //put the executioncontexts & return & the milliseconds & return & return & return after msg

   return tSharedProperties
end revIDEGetPropertiesOfObjects

function revIDEGetPropertyOfObject pObject, pProperty
   return the pProperty of pObject
end revIDEGetPropertyOfObject

/*
Use to get a complete list of all editable stacks in the IDE.

returns (String): A return delimited list of stack names
*/
function revIDEEditableStacks
   local tEditableStacks
   repeat for each line tStack in the openstacks
      if the mode of stack tStack < 2 then
         if tEditableStacks is empty then
            put tStack into tEditableStacks
         else
            put return & tStack after tEditableStacks
         end if
      end if
   end repeat
   return tEditableStacks
end revIDEEditableStacks

/*
Use to get a list of of all the global variables.

returns (list): A comma delimited list of global variable names
*/
function revIDEGlobalVariables
   if revIDEGetPreference("cShowRevolutionStacks") is true then return the globals

   local tGlobalList
   repeat for each item tGlobalName in the globals
      if tGlobalName begins with "gREV" then next repeat
      if tGlobalList is empty then
         put tGlobalName into tGlobalList
      else
         put comma & tGlobalName after tGlobalList
      end if
   end repeat
   sort items of tGlobalList

   return tGlobalList
end revIDEGlobalVariables

function revIDEGlobalProperties
   set the defaultfolder to revIDESpecialFolderPath("IDE")
   return URL("file:globalProperties.txt")
end revIDEGlobalProperties

local sRangeArray
function revIDEGlobalPropertyRange pProperty
   if sRangeArray is empty then
      local tRangeArray, tLine

      set the defaultfolder to revIDESpecialFolderPath("IDE")
      put URL("file:rangeArray.txt") into tRangeArray
      set the itemdel to tab

      repeat for each line tLine in tRangeArray
         replace comma with return in item 2 of tLine
         put item 2 of tLine into sRangeArray[item 1 of tLine]
      end repeat
   end if
   return sRangeArray[pProperty]
end revIDEGlobalPropertyRange

local sContinuousRangeArray
function revIDEGlobalPropertyContinuousRange pProperty
   if sContinuousRangeArray is empty then
      local tContinuousArray, tLine

      set the defaultfolder to revIDESpecialFolderPath("IDE")
      put URL("file:continuousArray.txt") into tContinuousArray
      set the itemdel to tab

      repeat for each line tLine in tContinuousArray
         replace comma with return in item 2 of tLine
         put item 2 of tLine into sContinuousRangeArray[item 1 of tLine]
      end repeat
   end if
   return sContinuousRangeArray[pProperty]
end revIDEGlobalPropertyContinuousRange

/*
Gets a list of the mainstacks, taking into account the Show IDE Stacks preference.

returns : An list of main stacks, one per line
*/
function revIDEMainStacks
   local tShowIDEStacks
   put revIDEGetPreference("cShowRevolutionStacks") into tShowIDEStacks

   # Get list of stacks to display
   local tMainStacks
   if tShowIDEStacks then
      put the mainstacks into tMainStacks
   else
      repeat for each line tMainStack in the mainstacks
         --if tMainStack begins with "rev" or the mode of stack tMainStack is not 1 then next repeat
         if revIDEStackIsRevStack(the long id of stack tMainStack) or the mode of stack tMainStack is not 1 then next repeat
         if tMainStacks is empty then
            put tMainStack into tMainStacks
         else
            put return & tMainStack after tMainStacks
         end if
      end repeat
   end if
   return tMainStacks
end revIDEMainStacks

function revIDEStacksForDataView pIndex
   --pExpandedStructure
   # Are IDE stacks required
   local tShowIDEStacks
   put revIDEGetPreference("cShowRevolutionStacks") into tShowIDEStacks

   # Get list of stacks to display
   local tMainStacks
   if tShowIDEStacks then
      put the mainstacks into tMainStacks
   else
      repeat for each line tMainStack in the mainstacks
         --if tMainStack begins with "rev" or the mode of stack tMainStack is not 1 then next repeat
         if revIDEStackIsRevStack(the long id of stack tMainStack) or the mode of stack tMainStack is not 1 then next repeat
         if tMainStacks is empty then
            put tMainStack into tMainStacks
         else
            put return & tMainStack after tMainStacks
         end if
      end repeat
   end if

   # Recurse through the stacks to get their data
   local tStacksData, tCount
   repeat for each line tStack in tMainStacks
      dispatch function "__readStructureOfStackForDataView" to stack tStack with tStacksData,, 1,pIndex
   end repeat
   return tStacksData
end revIDEStacksForDataView

/*
Gets the data associated with a stack. It recurses through the cards, containers and objects getting the property data associated with each.

returns (array): An array representing a tree structure of controls and their properties.
*/
function revIDEStacks pExpandedStackList
   # Are IDE stacks required
   local tShowIDEStacks
   put revIDEGetPreference("cShowRevolutionStacks") into tShowIDEStacks

   # Get list of stacks to display
   local tMainStacks
   if tShowIDEStacks then
      put the mainstacks into tMainStacks
   else
      repeat for each line tMainStack in the mainstacks
         if tMainStack begins with "rev" or the mode of stack tMainStack is not 1 then next repeat

         if tMainStacks is empty then
            put tMainStack into tMainStacks
         else
            put return & tMainStack after tMainStacks
         end if
      end repeat
   end if

   # Recurse through the stacks to get their data
   local tStacksData, tCount
   put 1 into tCount
   repeat for each line tStack in tMainStacks
      put empty into tStacksData[tCount]
      --if tStack is among the lines of pExpandedStackList then
      dispatch function "__readStructureOfStack" to stack tStack with tStacksData[tCount]
      --else
      --dispatch function "__readPropertiesOfControl" to stack tStack with sStackPropertiesToRead, tStacksData[tCount]
      --end if
      add 1 to tCount
   end repeat
   return tStacksData
end revIDEStacks

/*
Gets the data associated with all the frontscripts.

returns (array): A numerically keyed (for ordering) array with property:value pairs for each key.
*/
function revIDEFrontScripts
   # Get the list of frontscripts
   local tFrontScripts
   put the frontscripts into tFrontScripts

   # If ID elements are on not showing, filter the list for rev stacks
   local tShowIDEStacks
   put revIDEGetPreference("cShowRevolutionStacks") into tShowIDEStacks
   if tShowIDEStacks is not true then
      filter tFrontScripts without "*/rev*"
   end if

   # Create the list of properties to retrieve
   local tProperties
   put "short name" & return & "scriptlines" & return & "long id" into tProperties

   # Loop through the frontscripts getting the required properties
   # and build the return array
   local tCount, tData
   put 1 into tCount
   repeat for each line tFrontScriptObject in tFrontScripts
      dispatch function "__readPropertiesOfControl" to tFrontScriptObject with tProperties, tData[tCount]
      add 1 to tCount
   end repeat

   return tData
end revIDEFrontScripts

/*
Gets the data associated with all backscrips.

returns (array): A numerically keyed (for ordering) array with property:value pairs for each key.
*/
function revIDEBackScripts
   # Get the list of frontscripts
   local tBackScripts
   put the backscripts into tBackScripts

   # If ID elements are on not showing, filter the list for rev stacks
   local tShowIDEStacks
   put revIDEGetPreference("cShowRevolutionStacks") into tShowIDEStacks
   if tShowIDEStacks is not true then
      filter tBackScripts without "*/rev*"
   end if

   # Create the list of properties to retrieve
   local tProperties
   put "short name" & return & "scriptlines" & return & "long id" into tProperties

   # Loop through the frontscripts getting the required properties
   # and build the return array
   local tCount, tData
   put 1 into tCount
   repeat for each line tBackScriptObject in tBackScripts
      dispatch function "__readPropertiesOfControl" to tBackScriptObject with tProperties, tData[tCount]
      add 1 to tCount
   end repeat

   return tData
end revIDEBackScripts

/*
Gets the data associated with all the stacks in use.

returns (array): A numerically keyed (for ordering) array with property:value pairs for each key.
*/
function revIDEStacksInUse
   # Get the list of frontscripts
   local tStacksInUse
   put the stacksinuse into tStacksInUse

   # Create the list of properties to retrieve
   local tProperties
   put "short name" & return & "scriptlines" into tProperties

   # Loop through the stacks in use getting the required properties
   # and build the return array
   local tCount, tData
   put 1 into tCount
   repeat for each line tStack in tStacksInUse
      dispatch function "__readPropertiesOfControl" to stack tStack with tProperties, tData[tCount]
      put "stack" && quote & tStack & quote into tData[tCount]["long id"]
      add 1 to tCount
   end repeat

   return tData
end revIDEStacksInUse

function revIDEAPIFilters
end revIDEAPIFilters

function revIDEAPIFilter pFilters
end revIDEAPIFilter

function revIDEAPI pType, pName
end revIDEAPI

function revIDELocalisedString
end revIDELocalisedString

/*
Sets a preference.

pPreferenceName (String): The name of the preference to set
pValue (Any): The value to set the preference to
tags: preferences
Example: set revIDEGetPreference("text size") to 12
Returns (Any): The value of the preference
*/
on revIDESetPreference pPreferenceName, pValue
   set the pPreferenceName of stack "revpreferences" to pValue
   save stack "revpreferences"
   revIDEMessageSend "idePreferenceChanged:" & pPreferenceName
end revIDESetPreference

/*
Gets a preference.

pPreferenceName (String): The name of the preference
tags: preferences
Example: set the textsize of field 1 to revIDEGetPreference("text size")
Returns (Any): The value of the preference
*/
function revIDEGetPreference pPreferenceName
   return the pPreferenceName of stack "revpreferences"
end revIDEGetPreference

function revIDEPreferences
   return the customproperties of stack "revpreferences"
end revIDEPreferences

function revIDEPreferenceNames
   local tPreferenceNames
   repeat for each line tKey in the keys of (the customproperties of stack "revpreferences")
      if tPreferenceNames is empty then
         put tKey into tPreferenceNames
      else
         put return & tKey after tPreferenceNames
      end if
   end repeat
   return tPreferenceNames
end revIDEPreferenceNames

/*
The IDE has a repository of icon images which are used for ui elements in the IDE. The revIDEIconID function converts a "name-size" tag into a LiveCode ID suitable for direct use.

pIcon (String): The "name-size" tag for the given icon. The name is the name of the icon. The size is the size of the icon and should be one of 16, 24, 32, 64, 128
tags:icons
Example: set the icon of button 1 to revIDEIconID("help-32")
Returns (integer): The id of the image object on the revIconsNew stack.
*/
function revIDEIconID pIcon
   if not exists(image pIcon of card 1 of stack "reviconsnew") then return pIcon && " does not exist"
   return the ID of image pIcon of card 1 of stack "reviconsnew"
end revIDEIconID

function revIDEThemePath
   # Get the platform and system version
   local tPlatformName, tSystemVersion
   put revIDEPlatform() into tPlatformName
   put revIDEPlatformVersion() into tSystemVersion

   # Find nearest theme version for the given platform
   revIDEStoreDefaultFolder
   set the defaultfolder to revIDESpecialFolderPath("themes")

   local tClosestThemeNumber, tHighestThemeNumber
   repeat for each line tThemeFolder in the folders
      if char 1 of tThemeFolder is "." then next repeat

      local tThemeFolderStart
      put "com.livecode.theme." & tPlatformName into tThemeFolderStart

      if tThemeFolder begins with tThemeFolderStart then
         delete char 1 to the number of chars of tThemeFolderStart + 1 of tThemeFolder

         if highestVersionNumber(tSystemVersion,tThemeFolder) < 2 and highestVersionNumber(tClosestThemeNumber,tThemeFolder) is 2 then
            --if tThemeFolder <= tSystemVersion and tThemeFolder > tClosestThemeNumber then
            put tThemeFolder into tClosestThemeNumber
         end if

         # keep track of the highest number
         if highestVersionNumber(tHighestThemeNumber,tThemeFolder) is 2 then
            put tThemeFolder into tHighestThemeNumber
         end if
      end if
   end repeat

   # Build the path to the theme
   local tThemeName
   if tClosestThemeNumber is empty then
      if tHighestThemeNumber is not empty then
         put "com.livecode.theme." & tPlatformName & "." & tHighestThemeNumber into tThemeName
      else
         put "com.livecode.theme." & tPlatformName into tThemeName
      end if
   else
      put "com.livecode.theme." & tPlatformName & "." & tClosestThemeNumber into tThemeName
   end if

   revIDERestoreDefaultFolder

   return revIDESpecialFolderPath("themes") & slash & tThemeName
end revIDEThemePath

function highestVersionNumber pVersionNumber1, pVersionNumber2
   set the itemdel to "."
   local tCount
   put max(the number of items of pVersionNumber1,the number of items of pVersionNumber2) into tCount
   repeat with x = 1 to tCount
      if item x of pVersionNumber1 > item x of pVersionNumber2 then return 1
      else if item x of pVersionNumber1 < item x of pVersionNumber2 then return 2
   end repeat
   return 0
end highestVersionNumber

function revIDEPlatform
   if the platform begins with "mac" then return "mac"
   else if the platform begins with "win" then return "win"
   else if the platform begins with "linux" then return "linux"
   else if the platform begins with "iphone" then return "ios"
   else if the platform begins with "android" then return "android"
   return __revIDEError("Unknown Platform")
end revIDEPlatform

function revIDEPlatformVersion
   local tSystemVersion
   put the systemVersion into tSystemVersion

   if tSystemVersion begins with "Windows" or tSystemVersion begins with "NT"   then return the last word of tSystemVersion
   return tSystemVersion
end revIDEPlatformVersion

function revIDEColor pTag
   if pTag is "edition_color" then return ideCoreEditionColour()

   switch pTag
      case "text_1"
         return "0,0,0"
         break
      case "text_2"
         return "125,125,125"
         break
      case "text_3"
         return "255,255,255"
         break
      case "dataView_rowColor"
         return "255,255,255"
         break
      case "dataView_rowAlternateColor"
         return "238,238,238"
         break
      case "dataView_hiliteColor"
         return "48,160,209"
         break
      case "dataView_alternateHiliteColor"
         return "34,154,206"
         break
      case "dataView_TextHiliteColor"
         return "255,255,255"
         break
      case "dataView_scriptBackgroundColor"
         return "34,154,206"
         break
      case "palette_background"
         if the platform is "Win32" then
            return "240,240,240"
         else
            return the effective backgroundColor of this stack
         end if
         break
      case "propertyInspector_multiValueBackground"
         return "200,206,215"
         break
   end switch

   return ideColorGet(pTag)
end revIDEColor

function revIDETextSize
   return 12
end revIDETextSize

function revIDECardOfObject pLongID
   local tOffset
   repeat for each word tWord in pLongID
      if tWord is "card" then
         add 1 to tOffset
         exit repeat
      else
         add 1 to tOffset
      end if
   end repeat
   return word tOffset to -1 of pLongID
end revIDECardOfObject

function revIDEStackOfObject pLongID
   local tOffset
   repeat for each word tWord in pLongID
      if tWord is "stack" then
         add 1 to tOffset
         exit repeat
      else
         add 1 to tOffset
      end if
   end repeat
   return word tOffset to -1 of pLongID
end revIDEStackOfObject

on revIDEMoveControl pControl, pNewCard, pLayerNumber
   local tNewControl
   lock messages
   copy pControl to pNewCard
   put the long id of it into tNewControl

   delete pControl

   try
      --revIDESetPropertyOfObject tNewControl, "layer", pLayerNumber
   catch pError
   end try
   unlock messages
   return tNewControl
end revIDEMoveControl

function revIDEStackProperties pStackID, pLevel
   if not exists(pStackID) then return __revIDEError("You must specify an object to read from." &&  quote & pStackID & quote && "is not an object")

   local tStackArray

   dispatch function "__readPropertiesOfControl" to pStackID with sStackPropertiesToRead, tStackArray
   --put the result into tStackArray
   put "stack" into tStackArray["type"]
   put "container" into tStackArray["style"]
   put pLevel into tStackArray["level"]
   put the number of lines in the cardIDs of pStackID into tStackArray["childCount"]
   if tStackArray["childCount"] is 0 then put 1 into tStackArray["childCount"]
   return tStackArray
end revIDEStackProperties

function revIDECardPropertiesOfStack pStackID, pLevel
   local tCardIDs, tCardArray, tIndex
   local tSubStackIDs, tSubstack

   put the cardIDs of pStackID into tCardIDs
   repeat for each line tCard in tCardIDs
      add 1 to tIndex
      dispatch function "__readPropertiesOfControl" to card id tCard of pStackID with sCardPropertiesToRead, tCardArray[tIndex]
      put "card" into tCardArray[tIndex]["type"]
      put "container" into tCardArray[tIndex]["style"]
      put pLevel+1 into tCardArray[tIndex]["level"]
      put the number of lines in the childControlIDs of card id tCard of pStackID into tCardArray[tIndex]["childCount"]
   end repeat

   ## Substacks
   put the substacks of pStackID into tSubStackIDs
   repeat for each line tStackID in tSubStackIDs
      add 1 to tIndex

      dispatch function "__readPropertiesOfControl" to stack tStackID with sStackPropertiesToRead, tCardArray[tIndex]
      put "substack" into  tCardArray[tIndex]["type"]
      put "container" into  tCardArray[tIndex]["style"]
      put pLevel+1 into  tCardArray[tIndex]["level"]
      put the number of lines in the cardIDs of stack tStackID of pStackID into  tCardArray[tIndex]["childCount"]
      if  tCardArray[tIndex]["childCount"] is 0 then put 1 into  tCardArray[tIndex]["childCount"]
   end repeat

   return tCardArray
end revIDECardPropertiesOfStack

function revIDEControlPropertiesOfCard pCardID, pLevel
   local tChildControls, tControlArray, tIndex, tFullArray, tChildCount

   --repeat for each line tControlId in the childcontrolIDs of pCardID
   put  the childcontrolIDs of pCardID into tChildControls
   put the number of lines in tChildControls into tChildCount

   repeat with x = 1 to the number of lines in tChildControls
      local tControlId
      if revIDEGetPreference("ideProjectBrowser_sortOrder") is "bottom to top" then
         put line x of tChildControls into tControlId
      else
         put line (tChildCount -x) + 1 of tChildControls into tControlId
      end if

      add 1 to tIndex
      put empty into tControlArray
      dispatch function "__readPropertiesOfControl" to control id tControlID of pCardID with sControlPropertiesToRead, tControlArray

      if tControlArray["type"] is "group" then
         put "group" into tControlArray["style"]
         put the number of controls of control id tControlID of pCardID into tControlArray["childCount"]
      else
         put "control" into tControlArray["style"]
      end if
      put pLevel+1 into tControlArray["level"]
      put tControlArray into tFullArray[tIndex]
   end repeat
   return tFullArray
end revIDEControlPropertiesOfCard

function revIDEControlPropertiesOfGroup pGroupID, pLevel
   local tControlArray, tIndex

   repeat for each line tControlId in the childcontrolIDs of pGroupID
      add 1 to tIndex
      dispatch function "__readPropertiesOfControl" to control id tControlID of pGroupID with sControlPropertiesToRead, tControlArray[tIndex]

      if tControlArray[tIndex]["type"] is "group" then
         put "group" into tControlArray[tIndex]["style"]
         put the number of controls of control id tControlID of pGroupID into tControlArray[tIndex]["childCount"]
      else
         put "control" into tControlArray[tIndex]["style"]
      end if
      put pLevel+1 into tControlArray[tIndex]["level"]
   end repeat
   return tControlArray
end revIDEControlPropertiesOfGroup

function revIDEControlProperties pControl, pLevel
   local tData
   dispatch function "__readPropertiesOfControl" to pControl with sControlPropertiesToRead, tData
   put pLevel into tData["level"]
   put "control" into tData["style"]
   return tData
end revIDEControlProperties

function revIDEGroupProperties pControl, pLevel
   local tData
   dispatch function "__readPropertiesOfControl" to pControl with sControlPropertiesToRead, tData
   put pLevel into tData["level"]
   put "group" into tData["style"]
   return tData
end revIDEGroupProperties

function revIDECardProperties pCard, pLevel
   local tData
   dispatch function "__readPropertiesOfControl" to pCard with sCardPropertiesToRead, tData

   put pLevel into tData["level"]
   put "container" into tData["style"]
   put "card" into tData["type"]
   return tData
end revIDECardProperties

function revIDEStackAudioClips pStack
   local tAudioClipCount, tAudioClipArray, tScriptLines, tBehavior, tBehaviorScriptLines

   -- MM-2013-09-16: [[ Bug 11280 ]] as a result of the fix for bug 11068, the engine is more strict in the way it processes references.
   -- Removed unecessary "stack" keywords.
   put the num of Audioclips in pStack into tAudioClipCount
   repeat with tClip = 1 to tAudioClipCount
      put "audioclip" into tAudioClipArray[tClip]["type"]
      put the short name of Audioclip tClip of pStack into tAudioClipArray[tClip]["name"]
      put the long id of Audioclip tClip of pStack into tAudioClipArray[tClip]["long id"]
      put 3 into tAudioClipArray[tClip]["level"]

      // Script
      try
         put the number of lines in  the script of Audioclip tClip of pStack into tScriptLines
      catch tError
         put "pwd" into tScriptLines
      end try
      put tScriptLines into tAudioClipArray[tClip]["scriptlines"]

      // Behavior
      if the behavior of Audioclip tClip of pStack is not empty then
         if there is a (the behavior of Audioclip tClip of pStack) then
            try
               put the behavior of Audioclip tClip of pStack into tBehavior
            catch pError
               put "pwd" into tBehavior
            end try

            if tBehavior is not "pwd" then
               put the number of lines in the script of tBehavior into tBehaviorScriptLines
            else
               put "pwd" into tBehaviorScriptLines
            end if
         end if
         put tBehavior into tAudioClipArray[tClip]["behavior"]
         put tBehaviorScriptLines into tAudioClipArray[tClip]["behavior scriptlines"]
      else
         put empty into tAudioClipArray[tClip]["behavior scriptlines"]
      end if
   end repeat
   return tAudioClipArray
end revIDEStackAudioClips

function revIDEStackVideoClips pStack
   local tVideoClipCount, tVideoClipArray, tScriptLines, tBehavior, tBehaviorScriptLines, tAudioClipArray

   -- MM-2013-09-16: [[ Bug 11280 ]] as a result of the fix for bug 11068, the engine is more strict in the way it processes references.
   -- Removed unecessary "stack" keywords.
   put the num of videoclips in pStack into tVideoClipCount
   repeat with tClip = 1 to tVideoClipCount
      put "videoclip" into tVideoClipArray[tClip]["type"]
      put the short name of videoclip tClip of pStack into tVideoClipArray[tClip]["name"]
      put the number of lines in  the script of videoclip tClip of pStack into tAudioClipArray[tClip]["scriptlines"]
      put the long id of videoclip tClip of pStack into tVideoClipArray[tClip]["long id"]
      put 3 into tVideoClipArray[tClip]["level"]

      // Script
      try
         put the number of lines in  the script of videoclip tClip of pStack into tScriptLines
      catch tError
         put "pwd" into tScriptLines
      end try
      put tScriptLines into tVideoClipArray[tClip]["scriptlines"]

      // Behavior
      if the behavior of videoclip tClip of pStack is not empty then
         if there is a (the behavior of videoclip tClip of pStack) then
            try
               put the behavior of videoclip tClip of pStack into tBehavior
            catch pError
               put "pwd" into tBehavior
            end try

            if tBehavior is not "pwd" then
               put the number of lines in the script of tBehavior into tBehaviorScriptLines
            else
               put "pwd" into tBehaviorScriptLines
            end if
         end if
         put tBehavior into tVideoClipArray[tClip]["behavior"]
         put tBehaviorScriptLines into tVideoClipArray[tClip]["behavior scriptlines"]
      else
         put empty into tVideoClipArray[tClip]["behavior scriptlines"]
      end if
   end repeat
   return tVideoClipArray
end revIDEStackVideoClips

function revIDERelativeStackPath pStack, pPath
   local tMainStackPath
   set the itemDel to "/"
   put item 1 to -2 of the effective filename of pStack & "/" into tMainStackPath
   local tCharCount
   put the number of chars of tMainStackPath into tCharCount
   if char 1 to tCharCount of pPath is tMainStackPath then
      delete char 1 to tCharCount of pPath
   end if
   return pPath
end revIDERelativeStackPath

/*
Returns A return sepearetd list of the long ids of the selected objects
*/
function revIDESelectedObjects
   return revPaletteObjects()
end revIDESelectedObjects

#############
# Actions
#############
local sDownloadData, sDownloadStatus, sDownloadQueue
on revIDEDownloadFile pURL, pTargetDirectory, pCallbackTarget, pProgressMessageName, pCompleteMessageName
   if char 1 to 3 of pURL is not among the items of "htt,ftp" then return __revIDEError("Cannot download file" && quote & pURL & quote & ". It is not a valid URL.")
   if there is not a folder pTargetDirectory then return __revIDEError("Cannot download file. Target directory" && quote & pTargetDirectory & quote && "does not exist")
   if pURL is among the lines of sDownloadQueue then return "File already in download queue"

   # Store data in download queue
   set the itemdel to "/"
   put pTargetDirectory & slash & the last item of pURL into sDownloadData[pURL]["file"]
   put pCallbackTarget into sDownloadData[pURL]["callback_target"]
   put pProgressMessageName into sDownloadData[pURL]["callback_progress_message"]
   put pCompleteMessageName into sDownloadData[pURL]["callback_complete_message"]

   if sDownloadQueue is empty then
      put pURL into sDownloadQueue
   else
      put return & pURL after sDownloadQueue
   end if

   send "__downloadNextFile" to me in 0 milliseconds
end revIDEDownloadFile

on __downloadNextFile
   if sDownloadQueue is empty then exit __downloadNextFile

   # First update the data based on status of current download if any
   local tFirstURL
   put line 1 of sDownloadQueue into tFirstURL
   put URLStatus(tFirstURL)
   switch item 1 of URLStatus(tFirstURL)
      case "queued"
      case "contacted"
      case "requested"
      case "loading"
      case "uploading"
         # First URL download in progress
         exit __downloadNextFile
         break
      case "downloaded"
      case "uploaded"
      case "cached"
         put URL tFirstURL into URL ("binfile:" & sDownloadData[tFirstURL]["file"])
         put the result
         # First URL download complete
         if exists(sDownloadData[tFirstURL]["callback_target"]) and sDownloadData[tFirstURL]["callback_complete_message"] is not empty then
            dispatch sDownloadData[tFirstURL]["callback_complete_message"] to sDownloadData[tFirstURL]["callback_target"] with tFirstURL
         end if
         __downloadRemove tFirstURL
         break
      case "error"
      case "timeout"
         # First URL download error
         add 1 to sDownloadData[tFirstURL]["error"]
         if sDownloadData[tFirstURL]["error"] > 2 then
            __downloadRemove tFirstURL
         end if
         break
   end switch

   # First item might have been removed so check is not empty and fetch the first URL to act on
   if sDownloadQueue is empty then exit __downloadNextFile
   put line 1 of sDownloadQueue into tFirstURL

   //load url tFirstURL with message "revIDEDownloadProgressUpdate"
   libURLDownloadToFile tFirstURL, sDownloadData[tFirstURL]["file"], "revIDEDownloadFinished"
   libURLSetStatusCallback "revIDEDownloadProgressUpdate", the long ID of me
end __downloadNextFile

private on __downloadRemove pURL
   # Remove URL from queue and wipe data in sDownloadData
   repeat with x = 1 to the number of lines of sDownloadQueue
      if line x of sDownloadQueue is pURL then
         delete line x of sDownloadQueue
         delete variable sDownloadData[pURL]
      end if
   end repeat
end __downloadRemove

function revIDEQueuedDownloads
   return sDownloadQueue
end revIDEQueuedDownloads

on revIDEDownloadProgressUpdate pURL, pStatus
   # Send callback if requests
   if exists(sDownloadData[pURL]["callback_target"]) and sDownloadData[pURL]["callback_progress_message"] is not empty then
      dispatch sDownloadData[pURL]["callback_progress_message"] to sDownloadData[pURL]["callback_target"] with pURL, pStatus
   end if
end revIDEDownloadProgressUpdate

on revIDEDownloadFinished pURL
   __downloadNextFile
end revIDEDownloadFinished

on revIDEFindMoreWidgets
   lock screen
   revIDEOpenPalette "extension manager"
   revIDEMessageSend "ideFindMoreWidgets"
   unlock screen
end revIDEFindMoreWidgets

on revIDEActionCreateObject pObjectTypeID
   revIDECreateObject pObjectTypeID, the topStack, the loc of this card of the topStack
end revIDEActionCreateObject

on revIDECreateObject pObjectTypeID, pTarget, pLoc
   if not exists(pTarget) then return __revIDEError("Cannot create object. Target does not exist: " && pTarget)
   if sClassicObjectProperties is empty then __objectPropertiesRead
   if not pObjectTypeID begins with "com.livecode" then __revIDEError("There us notobject type ID: " && pTarget)
   # Set the default stack to the target we're creating the object on
   set the defaultstack to revIDEStackOfObject(pTarget)

   # Create the object
   lock screen
   lock messages

   # Get the engine control type
   if pObjectTypeID begins with "com.livecode.interface.classic" then
      local tCreatedControlID
      # Create data grid
      if pObjectTypeID is "com.livecode.interface.classic.DataGrid" then
         -- data grid library expects a rect rather than a loc
         local tCreateRect
         put round(the cTabButtonWidth of stack "revPreferences" / 2), round(the cTabButtonHeight of stack "revPreferences" / 2) into tCreateRect
         put item 1 of tCreateRect + the cTabButtonWidth of stack "revPreferences" into item 3 of tCreateRect
         put item 2 of tCreateRect + the cTabButtonHeight of stack "revPreferences" into item 4 of tCreateRect

         local lDataGrid
         put true into lDataGrid -- select data grid at end not single control

         unlock messages
         # tObjectId is passed by reference and will have the data grid group id placed into it
         addDataGridToStack the short name of this stack, tCreateRect, empty, empty, tCreatedControlID
         local tCount
         put 0 into tCount
         repeat with i = 1 to the number of groups
            if the dgProps["control type"] of group i is "Data Grid" then
               add 1 to tCount
            end if
         end repeat
         set the name of tCreatedControlID to (the short name of tCreatedControlID && tCount)
         lock messages
      else
         local tObjectType
         put sClassicObjectProperties[pObjectTypeID]["type"] into tObjectType

         if tObjectType is empty then return __revIDEError("Invalid classic control type ID: " && pTarget)

         # A classic control
         do "create" && tObjectType
         put the long ID of the last control into tCreatedControlID
      end if

      local tPropInfoA
      # Set all the properties to their default
      repeat for each key tProperty in sClassicObjectProperties[pObjectTypeID]["properties"]
         put sClassicObjectProperties[pObjectTypeID]["properties"][tProperty] into tPropInfoA
         if tPropInfoA["default"] is "no_default" then next repeat
         if tPropInfoA["read_only"] is true then next repeat
         revIDESetPropertyOfObject tCreatedControlID, tProperty, tPropInfoA["default"]
      end repeat
   else
      # Not a classic control
      try
         create widget as pObjectTypeID
         put the long id of the last control into tCreatedControlID
         local tSize
         put revIDEExtensionWidgetPreferredSize(pObjectTypeID) into tSize
         if tSize is not empty then
            set the width of tCreatedControlID to item 1 of tSize
            set the height of tCreatedControlID to item 2 of tSize
         end if
      catch tError
         return false
      end try
   end if

   set the loc of tCreatedControlID to pLoc

   unlock messages
   unlock screen

   ## Prevent passing of ideNewControl message for objects created on IDE stacks
   if revIDEStackIsRevStack(tCreatedControlID) is false then
      global gRevStackStatus
      // AL-2015-04-08: [[ Bug 14822 ]] Ensure 'edited' status of stack is set
      put "edited" into gREVStackStatus[the short name of this stack]
      revIDEMessageSend "ideNewControl", tCreatedControlID
   end if

   return tCreatedControlID
end revIDECreateObject

on revIDECloneObject pLongID
   local tTarget, tLoc, tControlType
   local tCreatedControlID

   put the loc of pLongID into tLoc
   add 20 to item 1 of tLoc
   add 20 to item 2 of tLoc

   put revIDECardOfObject(pLongID) into tTarget
   if not exists(tTarget) then return __revIDEError("Cannot create object. Target does not exist:" && tTarget)

   --   # Set the default stack to the target we're creating the object on
   --   set the defaultstack to the owner of tTarget

   --   # Create the object
   --   lock screen
   -- lock messages
   --do "clone" && pLongID
   clone pLongID
   put the long ID of the last control into tCreatedControlID
   set the loc of tCreatedControlID to tLoc

   --   unlock messages
   --   unlock screen
   --   return tCreatedControlID
end revIDECloneObject

on revIDECloneObjectWithDefaults pLongID
   local tTarget, tLoc, tControlType

   put the loc of pLongID into tLoc
   add 20 to item 1 of tLoc
   add 20 to item 2 of tLoc

   put revIDECardOfObject(pLongID) into tTarget
   if not exists(tTarget) then return __revIDEError("Cannot create object. Target does not exist:" && tTarget)

   local tOriginalObjectType
   put __objectType(pLongID) into  tOriginalObjectType
   # Get the engine control type
   local tObjectType
   put sClassicObjectProperties[tOriginalObjectType]["type"] into tObjectType
   if tObjectType is empty then return __revIDEError("Cannot create object. The engine type of classic control" && pLongID && "could not be determined. Please check the object definition file and ensure that a type has been defined.")

   # Set the default stack to the target we're creating the object on
   set the defaultstack to the owner of tTarget

   # Create the object
   lock screen
   --lock messages

   local tCreatedControlID
   do "create" && tObjectType
   put the long ID of the last control into tCreatedControlID

   # Set all the properties to their default
   repeat for each line tProperty in the keys of sClassicObjectProperties[tOriginalObjectType]["properties"]
      if sClassicObjectProperties[tOriginalObjectType]["properties"][tProperty]["default"] is "no_default" then next repeat
      if sClassicObjectProperties[tOriginalObjectType]["properties"][tProperty]["read_only"] is true then next repeat
      revIDESetPropertyOfObject tCreatedControlID, tProperty, sClassicObjectProperties[tOriginalObjectType]["properties"][tProperty]["default"]
   end repeat
   set the loc of tCreatedControlID to tLoc

   --unlock messages
   unlock screen
end revIDECloneObjectWithDefaults

on revIDEDeleteObjects pObjectIDs
   lock screen
   local tGroupID
   repeat for each line tControlID in pObjectIDs
      delete tControlID
   end repeat
   unlock screen
end revIDEDeleteObjects

on revIDEActionGroupObjects
   revIDEGroupObjects the selobj
   
   local tNewGroup
   put the result into tNewGroup
   if exists(tNewGroup) then
      select tNewGroup
   end if
end revIDEActionGroupObjects

on revIDEGroupObjects pObjectIDs
   local tName, tLayer, tGroupID,tList
   put the long name of (line 1 of pObjectIDs) into tName
   put 1000000 into tLayer

   lock screen

   repeat for each line tControl in pObjectIDs
      if the layer of tControl < tLayer then put the layer of tControl into tLayer
      put tControl & " and " after tList
   end repeat

   delete char -5 to -1 of tList
   put "group " before tList

   do tList

   put the long id of the owner of (tName)  into tGroupID
   set the layer of tGroupID to tLayer
   return tGroupID
end revIDEGroupObjects

on revIDEActionUngroup
   revIDEUngroup the selobj
end revIDEActionUngroup

on revIDEUngroup pGroup
   if word 1 of pGroup is not "group" then
      exit revIDEUngroup
   end if
   revIDESelectObjects pGroup
   ungroup
end revIDEUngroup

/*
Sets the tool.

pTool (enum): One of the following
pointer - Sets the tool to "pointer" mode causing the application to run as if a standalone
browse - Sets the tool to "browse" mode allowing you to select object
*/
on revIDESetTool pTool
   do "choose" && pTool
   revIDEMessageSend "ideToolChanged"
end revIDESetTool

/*
Sets the property of an object to the value specified

pObject (String): The long ID of the target object
pProperty (String): The name of the property to set
pValue (Any): The value to set the property to

Example: revIDESetPropertyOfObject the long ID of button 1, "label", "Go Next Card"
*/
on revIDESetPropertyOfObject pObjects, pProperty, pValue
   if pProperty is empty then return __revIDEError("You must specify a property name")

   lock screen
   repeat for each line tObject in pObjects
      if not exists(tObject) then return __revIDEError("Cannot set property '"&tObject&"' because object does not exist")

      try
         if pProperty contains "[" then
            ## An array property
            do ("set" && pProperty && "of" && tObject && "to" && pValue)
         else
            set pProperty of tObject to pValue
         end if
      catch tError
         if the number of elements of pValue > 0 then put revFormatArrayForDisplay(pValue) into pValue
         return __revIDEError(tError & return & "Property:" & pProperty & return & "Value:" & pValue & return & "Object:" & tObject)
      end try
   end repeat
   unlock screen
end revIDESetPropertyOfObject

/*
local sInspectedObjects
on revIDESetInspectedObjects pObjectList
   if pObjectList is not sInspectedObjects then
      put pObjectList into sInspectedObjects
      revIDEMessageSend "ideInspectedObjectsChanged", pObjectList
   end if
end revIDESetInspectedObjects

function revIDEGetInspectedObjects
   return sInspectedObjects
end revIDEGetInspectedObjects
*/
local sInspectingObjects
command revIDEInspectObjects pObjects
   put pObjects into sInspectingObjects
   revIDESelectObjects pObjects
   send "revIDEMessageSend ideInspectObjects","pObjects" to stack "revIDELibrary" in 0 milliseconds
end revIDEInspectObjects

on revIDEStopInspecting
   put empty into sInspectingObjects
end revIDEStopInspecting

function revIDEInspectedObjects
   return sInspectingObjects
end revIDEInspectedObjects

local sScriptEditingObjects
on revIDEStartEditingScript pObject
   put true into sScriptEditingObjects[the long id of pObject]
end revIDEStartEditingScript

on revIDEStopEditingScriptOfObjects pObjects
   repeat for each line tObject in pObjects
      delete variable sScriptEditingObjects[the long id of tObject]
   end repeat
end revIDEStopEditingScriptOfObjects

function revIDEScriptEditingObjects
   return the keys of sScriptEditingObjects
end revIDEScriptEditingObjects

on revIDEEditScriptOfObjects pObjectList
   repeat for each line tObject in pObjectList
      revIDEEditScriptOfObject tObject
   end repeat
end revIDEEditScriptOfObjects

on revIDEEditScriptOfObject pObject
   # First obtain a correct object reference. The reason for this is edit group mode
   local tObject
   put revRuggedId(pObject) into tObject

   # Send the ideEditScript message
   send "revIDEMessageSend ideEditScript","tObject" to stack "revIDELibrary" in 0 milliseconds

   # Update the currently editing objects
   revIDEStartEditingScript pObject

   # OK-2008-08-19 : Bug 6957
   # Dispatch the "revEditScript" message to any plugins that require it.
   global gREVMessageDispatch
   repeat for each line tPlugin in gREVMessageDispatch["revEditScript"]
      try
         send "revEditScript tObject" to this card of stack tPlugin
      end try
   end repeat

   # Search for existing editor first.
   local tExistingEditor
   put revScriptEditor(tObject) into tExistingEditor
   if tExistingEditor is not empty then
      revGoScriptEditor the long id of stack tExistingEditor
      send "revSESetCurrentObject tObject" to stack tExistingEditor
      exit revIDEEditScriptOfObject
   end if

   # MW-2012-02-21: If we are editing the "Template Stack" behavior then we create a new
   #   window in 'special' mode.
   if revRuggedId(the long id of stack revIDEScriptEditorBehavior("stack")) is tObject then
      revEditScriptInNewWindow pObject, true
      exit revIDEEditScriptOfObject
   end if

   # If the preference is to use tabs, then we find the topmost script editor
   # and add the specified object as a tab to it.
   local tUseTabs

   local tUseTabsString
   put "useTabs" into tUseTabsString

   send "revSEGetPreference tUseTabsString" to revScriptEditorMain()
   put the result into tUseTabs

   if tUseTabs then
      local tEditor
      put revTopMostScriptEditor() into tEditor

      # Do not allow a script editor to edit its own objects, force a new window
      # this makes debugging the script editor easier.
      local tStack
      put revTargetStack(tObject) into tStack
      if tEditor is empty then
         revEditScriptInNewWindow pObject
      else if tStack is the short name of tEditor then
         revEditScriptInNewWindow pObject
      else
         # OK-2008-07-24 : Use call instead of send here to prevent problems with the defaultStack changing.
         # Specifically this fixes an issue when debugging, if the user steps into a handler located in a script that
         # is not being edited, the script gets added to the editor, which causes the the defaultStack to change
         # and potentially breaks the debug being run in the debugger.
         call "revSEAddTargetObject tObject" to tEditor
         call "revSESetCurrentObject tObject" to tEditor
         revGoScriptEditor tEditor
      end if
   else
      # If the preference is not to use tabs, then we create a new script editor for the object.
      revEditScriptInNewWindow tObject
   end if
end revIDEEditScriptOfObject

/*
Generates API documentation for a giver object and launched it in the system browser.

Example: revIDELoadAPIForScript the long id of button 1
*/
on revIDELoadAPIForScript pObjectID
   revDocsPreviewObjectScriptInDocsViewer pObjectID
end revIDELoadAPIForScript

--on revIDERelayerControl pControl, pLayerNumber
--   revIDESetPropertyOfObject pControl, "layer", pLayerNumber
--end revIDERelayerControl

on revIDERelayerControl pControl, pLayerNumber, pCard
   local tObjectID, tName
   --put pControl && "of" && pCard into tObjectID
   put pControl into tObjectID
   put the name of tObjectID && "of" && pCard into tName
   if not exists(tObjectID) then return __revIDEError(tObjectID && "is not a control")

   revIDESetPropertyOfObject pControl, "layer", pLayerNumber
   return the long id of tName
end revIDERelayerControl

on revIDEMoveControl pControl, pNewCard, pLayerNumber
   local tNewControl
   lock messages
   copy pControl to pNewCard
   put the long id of it into tNewControl

   delete pControl

   revIDESetPropertyOfObject tNewControl, "layer", pLayerNumber
   unlock messages
end revIDEMoveControl

on revIDEMoveCard pCard, pNewStack
   local tNewCard
   lock messages
   copy pCard to pNewStack
   put the long id of it into tNewCard

   delete pCard
   unlock messages
   return tNewCard
end revIDEMoveCard

on revIDEMoveSubstack pSubstack, pNewStack
   local tNewSubstack
   lock messages
   set the mainstack of pSubstack to pNewStack
   unlock messages
end revIDEMoveSubstack

on  revIDERenumberCard pCardID,pNewNumber
   revIDESetPropertyOfObject pCardID, "number", pNewNumber
end revIDERenumberCard

command revIDESelectObjects pObjects
   try
      replace return with " AND " in pObjects
      do "select" && pObjects
   catch tError

   end try
end revIDESelectObjects

command revIDERefreshProjectBrowser
   dispatch "updateProjectView" to stack "revIDEProjectBrowser"
end revIDERefreshProjectBrowser

on revIDEAlignControls pControls, pPosition
   local tInitialControl, tInitialValue
   
   put line 1 of pControls into tInitialControl
   
   if pPosition is "left" then
      put the left of tInitialControl into tInitialValue
   else if pPosition is "top" then
      put the top of tInitialControl into tInitialValue
   else if pPosition is "right" then
      put the right of tInitialControl into tInitialValue
   else if pPosition is "bottom" then
      put the bottom of tInitialControl into tInitialValue
   else if pPosition is "height" then
      put the height of tInitialControl into tInitialValue
   else if pPosition is "width" then
      put the width of tInitialControl into tInitialValue
   end if
   
   repeat with x = 2 to the number of lines in pControls
      revIDESetPropertyOfObject line x of pControls, pPosition, tInitialValue
   end repeat
end revIDEAlignControls

on revIDECenterControls pControls, pPosition
   local tInitialControl,tInitialLoc, tPositionValue, tNewLoc, tObject, tObjectLoc

   put line 1 of pControls into tInitialControl
   put value("the loc of me", tInitialControl) into tInitialLoc

   if pPosition is "vertical" then
      put item 1 of tInitialLoc into tPositionValue

      repeat with x = 2 to the number of lines in pControls
         put line x of pControls into tObject
         put value("the loc of me", tObject) into tObjectLoc
         put tPositionValue, item 2 of tObjectLoc into tNewLoc
         revIDESetPropertyOfObject tObject, "location", tNewLoc
      end repeat

   else if pPosition is "horizontal" then
      put item 2 of tInitialLoc into tPositionValue

      repeat with x = 2 to the number of lines in pControls
         put line x of pControls into tObject
         put value("the loc of me", tObject) into tObjectLoc
         put item 1 of tObjectLoc, tPositionValue into tNewLoc
         revIDESetPropertyOfObject tObject , "location", tNewLoc
      end repeat
   end if
end revIDECenterControls

on revIDEEqualizeControls pControls, pPosition
   local tInitialControl, tInitialValue, tObject
   local tInitialWidth, tInitialHeight

   put line 1 of pControls into tInitialControl

   if pPosition is "width" then
      put the width of tInitialControl into tInitialValue
      repeat with x = 2 to the number of lines in pControls
         put line x of pControls into tObject
         revIDESetPropertyOfObject tObject, "width", tInitialValue
      end repeat
   else if pPosition is "height" then
      put the height of tInitialControl into tInitialValue
      repeat with x = 2 to the number of lines in pControls
         put line x of pControls into tObject
         revIDESetPropertyOfObject tObject, "height", tInitialValue
      end repeat

   else if pPosition is "rect" then
      put the width of tInitialControl into tInitialWidth
      put the height of tInitialControl into tInitialHeight
      repeat with x = 2 to the number of lines in pControls
         put line x of pControls into tObject
         revIDESetPropertyOfObject tObject, "width", tInitialWidth
         revIDESetPropertyOfObject tObject, "height", tInitialHeight
      end repeat
   end if
end revIDEEqualizeControls

command revIDEDistributeControls pControls, pPosition, pDistribution
   local tStack, tLeft, tRight, tTop,tBottom, tTotalWidth, tTotalHeight, tSpacing
   local tAvailableWidth, tAvailableHeight
   local tOrderedObjectList

   put word -2 to -1 of line 1 of pControls into tStack
   put the width of tStack into tLeft
   put the height of tStack into tTop
   put 0 into tRight
   put 0 into tBottom
   repeat with x = 1 to the number of lines in pControls
      get line x of pControls
      if the left of it < tLeft then put the left of it into tLeft
      if the top of it < tTop then put the top of it into tTop
      if the right of it > tRight then put the right of it into tRight
      if the bottom of it > tBottom then put the bottom of it into tBottom
      add the width of it to tTotalWidth
      add the height of it to tTotalHeight

      put it & comma & the left of it & comma & the top of it & return after tOrderedObjectList
   end repeat

   if pControls is "horizontal" then
      put "Across Card" into pDistribution
      switch pDistribution
         case "First To Last selected"
            sort lines of tOrderedObjectList by item 2 of each
            put tRight-tLeft into tAvailableWidth
            put ((tAvailableWidth-tTotalWidth)/(the number of lines in pControls)) div 1 into tSpacing
            break
         case "Edge To Edge"
            sort lines of tOrderedObjectList by item 2 of each
            put 0 into tSpacing
            break
         case "Across Card"
            sort lines of tOrderedObjectList by item 2 of each
            put the width of tStack into tAvailableWidth
            put ((tAvailableWidth-tTotalWidth)/(the number of lines in pControls+1)) div 1 into tSpacing
            put tSpacing into tLeft
            break
      end switch
      repeat with x = 1 to the number of lines in tOrderedObjectList
         get item 1 of line x of pControls
         revIDESetPropertyOfObject item 1 of line x of pControls, "left", tLeft
         --set the left of it to tLeft
         add the width of it + tSpacing to tLeft
      end repeat
   else if pControls is "vertical" then
      switch pDistribution
         put "Across Card" into pDistribution
      case "First To Last selected"
         sort lines of tOrderedObjectList by item 3 of each
         put tBottom-tTop into tAvailableHeight
         put ((tAvailableHeight-tTotalHeight)/number of lines in tOrderedObjectList) div 1 into tSpacing
         break
      case "Edge To Edge"
         sort lines of tOrderedObjectList by item 3 of each
         put 0 into tSpacing
         break
      case "Across Card"
         sort lines of tOrderedObjectList by item 3 of each
         put the height of tStack into tAvailableHeight
         put ((tAvailableHeight-tTotalHeight)/(the number of lines in tOrderedObjectList+1)) div 1 into tSpacing
         put tSpacing into tTop
         break
   end switch
   repeat with x = 1 to the number of lines in tOrderedObjectList
      get item 1 of line x of tOrderedObjectList
      revIDESetPropertyOfObject item 1 of line x of tOrderedObjectList, "top", tTop
      --set the top of it to tTop
      add the height of it + tSpacing to tTop
   end repeat
end if
end revIDEDistributeControls

#############
# Utility
#############
/*
Similar in functionality to specialFolderPath, it returns paths the folders with the IDE structure.

pKey (enum): The key for the folder you wish the retrieve.
- IDE: Returns the path the base IDE folder
- Object Property Definitions: Returns the path to the folder containing the object property definition files

returns (string): the folder on the local file system where the IDE is stored.

Example:
local tIDEFolder
put revIDESpecialFolderPath("IDE") into tIDEFolder
*/
function revIDESpecialFolderPath pKey
   local tPath
   set the itemdel to "/"
   switch pKey
      case "IDE"
         return item 1 to -3 of the filename of stack "home"
         break
      case "Toolset"
         return item 1 to -3 of the filename of stack "home" & "/Toolset"
         break
      case "Toolchain"
         return item 1 to -3 of the filename of stack "home" & "/Toolchain"
         break
      case "Object Property Definitions"
         return item 1 to -3 of the filename of stack "home" & "/Toolset/resources/supporting_files/property_definitions"
         break
      case "Standalone Settings Definitions"
         return item 1 to -3 of the filename of stack "home" & "/Toolset/resources/supporting_files/standalone_settings"
         break
      case "Tool Definitions"
         return item 1 to -3 of the filename of stack "home" & "/Toolset/resources/supporting_files/tool_definitions"
         break
      case "fonts"
         return item 1 to -3 of the filename of stack "home" & "/Toolset/resources/supporting_files/fonts"
         break
      case "themes"
         return item 1 to -3 of the filename of stack "home" & "/Toolset/resources/supporting_files/themes"
         break
      case "images"
         return item 1 to -3 of the filename of stack "home" & "/Toolset/resources/supporting_files/images"
         break
      case "extensions"
         put  item 1 to -3 of the filename of stack "home" & "/extensions" into tPath
         revIDEEnsurePath(tPath)
         return tPath
         break
      case "user extensions"
         put revEnvironmentCustomizationPath() & "/extensions" into tPath
         revIDEEnsurePath(tPath)
         return tPath
         break
      case "temp extensions"
         put revEnvironmentCustomizationPath() & "/extensions/temp" into tPath
         revIDEEnsurePath(tPath)
         return tPath
         break
      case "downloading extensions"
         put revEnvironmentCustomizationPath() & "/extensions/downloading" into tPath
         revIDEEnsurePath(tPath)
         return tPath
         break
      case "uninstalled extensions"
         put revEnvironmentCustomizationPath() & "/extensions/uninstalled" into tPath
         revIDEEnsurePath(tPath)
         return tPath
         break
      case "documentation"
         put item 1 to -3 of the filename of stack "home" & "/Documentation" into tPath
         revIDEEnsurePath(tPath)
         return tPath
         break
      case "documentation cache"
         put revEnvironmentCustomizationPath() & "/Documentation" into tPath
         revIDEEnsurePath(tPath)
         return tPath
         break
      case "api"
         return item 1 to -3 of the filename of stack "home" & "/Documentation/html_viewer/resources/data/api"
         break
      case "guide"
         return item 1 to -3 of the filename of stack "home" & "/Documentation/html_viewer/resources/data/guide"
         break
      case "examples"
         put  item 1 to -3 of the filename of stack "home" & "/examples" into tPath
         revIDEEnsurePath(tPath)
         return tPath
         break
      case "tutorial"
         return item 1 to -3 of the filename of stack "home" & "/Toolset/palettes/tutorial"
         break
   end switch
end revIDESpecialFolderPath

on revIDEEnsurePath pPath
   if there is a folder pPath then exit revIDEEnsurePath

   local tPath
   set the itemdel to "/"
   repeat for each item tFolder in pPath

      if tFolder contains ":" then
         put tFolder after tPath
      else
         put slash & tFolder after tPath
      end if

      if tPath is empty then next repeat
      if there is a folder (quote & tPath & quote) then next repeat

      create folder tPath
   end repeat
end revIDEEnsurePath

/*
Returns the URL to a web page

pKey (enum): The key for the page you wish the retrieve.

returns (string): an http url to a wb page

Example:
local tExtensionSearchPage
put revIDEWebPageURL("extensionsSearch") into tExtensionSearchPage
*/
function revIDEWebPageURL pKey
   switch pKey
      case "extensions"
         return "http://www.livecode.com/products/extensions/"
         break
   end switch
end revIDEWebPageURL

function revIDEFrameBehavior
   return the long ID of stack "revPaletteBehavior"
end revIDEFrameBehavior

function revIDEInspectorBehavior
   return the long ID of stack "revInspectorBehavior"
end revIDEInspectorBehavior

function revIDEDataViewBehavior
   return the long ID of button "DataView Behavior" of stack "DataViewControl" of stack "revCore"
end revIDEDataViewBehavior

local sMilliseconds
on revIDEStartTiming
   put the milliseconds into sMilliseconds
end revIDEStartTiming

on revIDEEndTiming
   return the milliseconds - sMilliseconds
end revIDEEndTiming

on revIDESetCursor pCursor
   lock cursor
   if pCursor is among the items of "busy,watch,array,cross,hand,ibeam,plus,help" then
      do "set the cursor to" && pCursor
   end if

   lock messages
   local tDefaultStack
   put the defaultstack into tDefaultStack
   set the defaultstack to "revidelibrary"

   # Load the image for the cursor if it doesn't exists
   if there is not an image pCursor of me then
      local tImagePath
      put revIDEThemePath() & slash & pCursor & ".png" into tImagePath

      if there is not a file tImagePath then exit revIDESetCursor
      set the filename of the templateimage to tImagePath
      set the visible of the templateimage to false
      create image pCursor
      reset the templateimage
   end if

   if there is an image pCursor then
      set the cursor to the ID of image pCursor
   end if

   set the defaultstack to tDefaultStack
   unlock messages
end revIDESetCursor

on revIDEResetCursor
   unlock cursor
end revIDEResetCursor

/*
Use to tell the IDE that an action being performed is running slowly. The IDE will change the cursor and display the message as appropriate.
pMessage (String): A optional message that will be displayed when slow tasks are running
tag:affordances
*/
on revIDEShowLoading pMessage
   lock cursor
   set the cursor to watch
end revIDEShowLoading

/*
Use along with [revIDEShowLoading] to instruct the IDE when a task is running slowly. Once the task is complete, call revIDEHideLoading to reset the IDE to its normal mode
tag:affordances
*/
on revIDEHideLoading
   unlock cursor
end revIDEHideLoading

local sDefaultFolder
/*
Stores the current default folder.

Related: on revIDERestoreDefaultFolder

Example:
on myHandler
   revIDEStoreDefaultFolder
   set the defaultfolder to "/"
   repeat for each line tLine in the files
      # Do something to the files
   end repeat
   revIDERestoreDefaultFolder
end myHandler
*/
on revIDEStoreDefaultFolder
   put the defaultfolder into sDefaultFolder
end revIDEStoreDefaultFolder

/*
Restores the default folder to the last saved path.

Related: on revIDEStoreDefaultFolder

Example:
on myHandler
   revIDEStoreDefaultFolder
   set the defaultfolder to "/"
   repeat for each line tLine in the files
      # Do something to the files
   end repeat
   revIDERestoreDefaultFolder
end myHandler
*/
on revIDERestoreDefaultFolder
   set the defaultfolder to sDefaultFolder
end revIDERestoreDefaultFolder

/*
summary: Outputs a flat version of an array to the messagebox.
pArray (Array): The array you which to convert
returns (String): A text representation of the array with indented with the tab character for readability
*/
on revPutArray pArray
   if the number of elements of pArray is 0 then
      put "not an array"
      exit revPutArray
   end if
   put revFormatArrayForDisplay(pArray)
end revPutArray

/*
summary: Converts an array into a human readable format that can be output to the message box when debugging.
pArray (Array): The array you which to convert
returns (String): A text representation of the array with indented with the tab character for readability
*/
function revFormatArrayForDisplay pArray
   if (the keys of pArray) is empty then
      put "not an array"
      exit revFormatArrayForDisplay
   end if

   local pLevel, pCounter, pList

   put 0 into pLevel
   put 0 into pCounter
   put empty into pList

   put __dumpArrayRecurse(pArray, pLevel, pCounter, pList) into pList

   return pList
end revFormatArrayForDisplay

on revIDEResizeImageInBounds tImageID, tDesiredWidth,tDesiredHeight
   if not exists(tImageID) then exit revIDEResizeImageInBounds
   if the width of tImageID < tDesiredWidth and the height of tImageID < tDesiredHeight then exit revIDEResizeImageInBounds

   local tCurrentWidth, tCurrentHeight
   put the width of tImageID into tCurrentWidth
   put the height of tImageID into tCurrentHeight

   local tscaleFactor
   put min(tDesiredWidth/tCurrentWidth,tDesiredHeight/tCurrentHeight) into tscaleFactor

   lock screen
   lock messages
   set the lockloc of tImageID to true
   set the width of tImageID to the width of tImageID * tscaleFactor
   set the height of tImageID to the height of tImageID * tscaleFactor
   unlock messages
   unlock screen
end revIDEResizeImageInBounds

/*
Returns a list of all the display names of stacks recognised by the IDE as a palette.
*/
function revIDEAvailablePalettes
   return "Menubar,Tools,Inspector,Message Box,Project Browser,Extension Manager,Extension Builder,Start Center,Welcome,Menu Builder,Message Watcher,Plugin Preferences," \
   & "Standalone Settings,About,Dictionary,Resource Center,Create It Welcome,Preferences"	
end revIDEAvailablePalettes

function revIDEPaletteToStackName pPalette
   # This abstraction is here because other aspects of the IDE need to know the avaiable palettes.
   # For example, the view menu listing all the available palettes and their state. Leaving this check 
   # in, rather than having a default in the switch forces developers to add any new palettes to revIDEAvailablePalettes()
   if pPalette is not among the items of revIDEAvailablePalettes() then
      return __revIDEError("No available palette with name" && pPalette)
   end if
   
   switch pPalette
      case "menubar"
         return "revMenuBar"
      case "tools"
         return "revTools"
      case "inspector"
         return "revInspector"
      case "message box"
         return "Message Box"
      case "project browser"
         return "revIDEProjectBrowser"
      case "extension manager"
         return "revIDEExtensionManager"
      case "start center"
         return "revStartCenter"
      case "welcome"
         return "revWelcome"
      case "search"
         return "revSearch"
      case "preferences"
         return "revPreferencesGUI"
      case "menu builder"
         return "revMenuManager"
      case "extension builder"
         return "revExtensionBuilder"
      case "standalone settings"
         return "revStandaloneSettings"
      case "message watcher"
         return  "revMessageWatcher"
      case "plugin preferences"
         return "revPlugInEditor"
      case "about"
         return "revAbout"
      case "dictionary"
         return "revDictionary"
      case "resource center"
         return "revResourceCenter"
      case "create it welcome"
         return "createitwelcome"
   end switch
end revIDEPaletteToStackName

/*
Positions the palette.

If the user has set a previous moved a palette, the palette is returned to that position. 
If the palette is being opened for the first time, it is placed in a predetermined position
*/
on revIDEPositionPalette pStackName
   if there is not a stack pStackName then exit revIDEPositionPalette
   
   local tRect
   //put revIDEGetPreference("palette_rect_" & pStackName) into tRect
   
   if __isRect(tRect) then
      # A previous stored rect was found for the stack. Restore is position if possible.
      switch pStackName
         case "revMenuBar"
         case "revTools"
            set the topleft of stack pStackName to item 1 of tRect, item 2 of tRect
            break
         case "message box"
            set the rect of stack pStackName to tRect
            break
         default 
            # If no sizing information can be found position the stack in the center of the 
            # default screen
            set the loc of stack pStackName to the screenloc
            break
      end switch
   else
      # No previous rect was found for stack to calculate the appropriate position for the stack
      local tScreenHeight, tScreenWidth
      put item 4 of the screenrect - item 2 of the screenrect into tScreenHeight
      put item 3 of the screenrect - item 1 of the screenrect into tScreenWidth
      
      switch pStackName
         case "revMenuBar"
            set the topleft of stack pStackName to 0,0
            break
         case "revTools"
            set the topleft of stack pStackName to 0,the bottom of stack revIDEPaletteToStackName("menubar") + revIDEPaletteBarHeight(the long ID of stack pStackName)
            break
         case "message box"
            set rect of stack pStackName to 0,tScreenHeight * 0.75, tScreenWidth * 0.3, tScreenHeight
            break
         case "revInspector"
            if revIDEStackIsRevStack(the long ID of the topstack) then
               set the topleft of stack pStackName to tScreenWidth*0.3,the bottom of stack revIDEPaletteToStackName("menubar") + revIDEPaletteBarHeight(the long ID of stack pStackName)
            else
               set the topleft of stack pStackName to the right of the topstack + 10,the top of the topstack
            end if
            break
         default 
            # If no sizing information can be found position the stack in the center of the 
            # default screen
            set the loc of stack pStackName to the screenloc
            break
      end switch
   end if
end revIDEPositionPalette

function __isRect pRect
   # Check it has 4 items
   if the number of items of pRect is not 4 then return false
   
   # Check all the items are numbers
   repeat for each item tNumber in pRect
      if tNumber is not a number then
         return false
      end if
   end repeat
   
   # Check the rect has width
   if item 3 of pRect - item 1 of pRect < 0 then return false
   
   # Check the rect has height
   if item 4 of pRect - item 2 of pRect < 0 then return false
   
   # Passed all the tests
   return true
end __isRect

on revIDEStorePaletteRect pStackName
   revIDESetPreference ("palette_rect_" & pStackName), the rect of stack pStackName
end revIDEStorePaletteRect

on revIDEClearPaletteRects
   local tPreferenceNames
   put revIDEPreferenceNames() into tPreferenceNames
   repeat for each line tPreference in tPreferenceNames
      if tPreference begins with "palette_rect_" then
         revIDESetPreference tPreference, "0" 
      end if
   end repeat
end revIDEClearPaletteRects

private function revIDEPaletteBarHeight pStackID
   return the effective height of pStackID - the height of pStackID
end revIDEPaletteBarHeight

/*
Opens an IDE stack as a palette, any additional intelligence related to the palette is managed here, for example management of multiple Property Inspectors.

pPaletteName (String):The readable name of the palette to be opened
example: revIDEOpenPalette "inspector"
*/
command revIDEOpenPalette pPaletteName
   local tExistingPalette, tPalette, tPaletteID
   
   local tStackName
   put revIDEPaletteToStackName(pPaletteName) into tStackName
   
   if there is not a stack tStackName then return __revIDEError("No such palette:" && pPaletteName)
   
   hide stack tStackName
   switch pPaletteName
      case "Start Center"
         set the cMode of stack tStackName to "run"
         modeless stack tStackName
         break
      case "Welcome"
         local tStartCenter
         put revIDEPaletteToStackName("start center") into tStartCenter
         if the visible of stack tStartCenter is true then
            close stack tStartCenter
         end if
         modeless stack tStackName
         break
      case "inspector"
      case "message box"
      case "standalone settings"
      case "message watcher"
      case "tools"
         palette stack tStackName
         break
      case "Create It Welcome"
      case "search"
      case "preferences"
      case "project browser"
      case "extension manager"
      case "menu builder"
      case "extension builder"
      case "plugin preferences"
      case "about"
      case "resource center"
         modeless stack tStackName
         break
      case "dictionary"
         toplevel stack tStackName
         break
      default
         return __revIDEError("No such palette:" && pPaletteName)
   end switch
   show stack tStackName
end revIDEOpenPalette

function revIDEPaletteIsVisible pPaletteName
   local tStackName
   put revIDEPaletteToStackName(pPaletteName) into tStackName
   return the mode of stack tStackName is not 0 and the visible of stack tStackName
end revIDEPaletteIsVisible

on revIDEOpenInspectorForObjects pObjects
   lock screen
   revIDEOpenPalette("inspector")
   revIDEInspectObjects pObjects
   unlock screen
end revIDEOpenInspectorForObjects

/*
Returns a list of all the open Property Inspectors
*/
function revIDEOpenPalettes pType
   local tStackList
   put the mainStacks into tStackList
   switch pType
      case "inspector"
         filter tStackList with "revIDEPropertyInspector_*"
         return tStackList
         break
   end switch

   return __revIDEError("Not a valid palette type")
end revIDEOpenPalettes

/*
Returns the next numeic ID for a property inspector
*/
function revIDENextPropertyInspectorID
   local tPIList
   put revIDEOpenPalettes("inspector") into tPIList

   if tPIList is empty then
      return 1
   else
      set the itemDel to "_"
      sort lines of tPIList descending numeric by item 2 of each
      return item 2 of line 1 of tPIList + 1
   end if
end revIDENextPropertyInspectorID

/*
Returns the name of the first unlocked Property Inspector
*/
function revIDEPropertyInspector
   local tPIList
   put revIDEOpenPalettes("inspector") into tPIList

   if tPIList is empty then
      return empty
   else
      set the itemDel to "_"
      sort lines of tPIList ascending numeric by item 2 of each

      repeat for each line tInspector in tPIList
         if the cLocked of stack tInspector is not true then
            return tInspector
         end if
      end repeat
      return empty
   end if
end revIDEPropertyInspector

function revIDEStackIsRevStack pLongID
   if not exists(pLongID) then return false
   local tStackID
   put revIDEStackOfObject(pLongID) into tStackID

   ## Special cases of IDE stacks that don't begin with rev
   if the short name of tStackID is among the items of "message box" then
      return true
   else if the short name of tStackID begins with "com.runrev" then
      return true
   else
      return (the short name of tStackID begins with "rev")
   end if
end revIDEStackIsRevStack


function revIDEItemiseArray pArray
   if (the keys of pArray) is empty then
      put "not an array"
      exit revIDEItemiseArray
   end if

   local pLevel, pCounter, pList, pParent

   put 0 into pLevel
   put 0 into pCounter
   put empty into pParent
   put empty into pList

   put arrayRecurse(pArray, pLevel, pCounter, pList, pParent) into pList

   ## Add in all the parentLastSibling stuff into the array
   ## Was the parent a last sibling
   local tChildren
   repeat for each line tKey in the keys of pList
      put pList[tKey]["children"] into tChildren
      if tChildren is not empty then
         repeat for each item tChild in tChildren
            if pList[tKey]["lastSibling"] is true then
               put true into pList[tChild]["parentLastSibling"]
            end if
         end repeat
      end if
   end repeat

   return pList
end revIDEItemiseArray

function arrayRecurse pArray, pLevel, @pCounter, @pList, pParent
   local tKeys, tOrderedKeys, tChildren, tSingleKeys, tArrayKeys
   local tNewKey, tNewSet

   put the keys of pArray into tKeys
   --sort lines of tKeys numeric
   sort lines of tKeys

   ## Put single elements first
   repeat for each line tKey in tKeys
      if pArray[tKey] is an array then
         --if tKey is "new set" then
         --put true into tNewSet
         --else
         put tKey & return after tArrayKeys
         --end if
      else
         if tKey is "new key" then
            put true into tNewKey
         else if tKey is "new set" then
            put true into tNewSet
         else
            put tKey & return after tSingleKeys
         end if
      end if
   end repeat

   if the last char of tArrayKeys is return then delete the last char of tArrayKeys
   if the last char of tSingleKeys is return then delete the last char of tSingleKeys

   if tNewKey then
      if tSingleKeys is empty then put "new key" into tSingleKeys
      else put return & "new key" after tSingleKeys
   end if

   if tNewSet then
      if tArrayKeys is empty then put "new set" into tArrayKeys
      else put return & "new set" after tArrayKeys
   end if

   --if tNewSet then put return & "new set" after tArrayKeys

   ## Move "newKey" to the end
   put tSingleKeys & return & tArrayKeys into tOrderedKeys

   repeat for each line tKey in tOrderedKeys
      add 1 to pCounter
      put pCounter & comma after tChildren
      put pParent into pList[pCounter]["parent"]
      put pLevel + 1 into pList[pCounter]["level"]
      put tKey into pList[pCounter]["key"]

      if (the keys of pArray[tKey]) is empty then
         put "false" into pList[pCounter]["expanded"]
         put "element" into pList[pCounter]["type"]
         put pArray[tKey] into pList[pCounter]["value"]
      else
         put "false" into pList[pCounter]["expanded"]
         put "array" into pList[pCounter]["type"]
         put arrayRecurse(pArray[tKey], (pLevel + 1), pCounter, pList, pCounter) into pList
      end if
   end repeat
   delete the last char of tChildren
   put "true" into pList[the last item of tChildren]["lastSibling"]

   if pParent is not empty then
      put tChildren into pList[pParent]["children"]
   end if
   return pList
end arrayRecurse

private function __escapeStringAndConvertLineEndings pString
   replace "\" with "\\" in pString
   replace quote with ("\" & quote) in pString
   replace (numToChar(13) & CR) with (CR & numToChar(13)) in pString
   replace (CR & numToChar(13)) with CR in pString
   replace CR with "\n" in pString
   return (quote & pString & quote)
end __escapeStringAndConvertLineEndings

/*
Install the given extension's user guide
*/
on revIDEInstallUserGuide pGuideFolder, pExtensionName, pAuthor

   local tGuideFile
   put pGuideFolder & slash & "guide.md" into tGuideFile

   # Convert the user guide to a JSON array to append to user guide data
   local tGuide
   put url ("binfile:" & tGuideFile) into tGuide
   if tGuide is empty then
      return "no user guide data"
   end if

   put textDecode(tGuide, "utf-8") into tGuide

   local tGuideJSON
   put "{" & CR after tGuideJSON
   put tab & quote & "guide" & quote & ":" && quote & pExtensionName & quote & comma & CR after tGuideJSON
   put quote & "data" & quote & ":" & __escapeStringAndConvertLineEndings(tGuide) & CR after tGuideJSON
   put "}" after tGuideJSON

   put textEncode(tGuideJSON, "utf-8") into url ("binfile:" & pGuideFolder & slash & "guide.js")

   # Now regenerate the built guides
   revDocsAddGuideAndRegenerate tGuideJSON
end revIDEInstallUserGuide

/*
Install the given extension's API
*/
on revIDEInstallAPI pAPIFolder, pExtensionName, pAuthor

   local tAPIFile
   put pAPIFolder & slash & "api.lcdoc" into tAPIFile

   # Convert the new API to a JSON array to append to API data
   local tAPIJSON
   put revDocsFormatAPIAsJSON(pExtensionName, pAuthor, tAPIFile) into tAPIJSON
   if tAPIJSON is empty then
      return "no documentation found"
   end if

   put textEncode(tAPIJSON, "utf-8") into url ("binfile:" & pAPIFolder & slash & "api.js")

   # Now regenerate the built APIs
   revDocsAddAPIAndRegenerate tAPIJSON
end revIDEInstallAPI

#############
# Properties API
#############

local sLockUpdates
on revIDEPropertyLibraryInitialise
   put false into sLockUpdates
end revIDEPropertyLibraryInitialise

## Register new listeners for objects
on revIDEPropertyRegisterListenerForObject pObject
   if exists(pObject) then
      _internal listen to pObject
   end if
end revIDEPropertyRegisterListenerForObject

## Deregister listeners for objects
on revIDEPropertyDeregisterListenerForObject pObject
   if exists(pObject) then
      _internal cancel listener for pObject
   end if
end revIDEPropertyDeregisterListenerForObject

## Cancel all object listeners
on revIDEPropertyCancelAllListeners
   local tOldListeners
   put the revObjectListeners into tOldListeners
   repeat for each line tTarget in tOldListeners
      _internal cancel listener for tTarget
   end repeat
end revIDEPropertyCancelAllListeners

on revIDEPropertyChanged pObject
   if sLockUpdates is true then
      exit revIDEPropertyChanged
   end if

   revIDEMessageSend "idePropertyChanged", pObject
end revIDEPropertyChanged

on revIDEHideProperty pProperty

end revIDEHideProperty

on revIDEShowProperty pProperty

end revIDEShowProperty

function revIDEPropertiesInfo pObjectList
   return revIDEPropertiesInfoOfSection(pObjectList)
end revIDEPropertiesInfo

function __revIDEPropertiesInfoOfSection pObjectList, pSection
   repeat for each line tObject in pObjectList
      if not exists(tObject) then return __revIDEError("Not all objects in the list provided exist")
   end repeat

   # Work out the type of the selected objects
   local tObjectTypeList
   put __objectTypes(pObjectList) into  tObjectTypeList

   # Return this list of all the properties to read for the given type list
   return __objectPropertiesShared(tObjectTypeList, pSection)
end __revIDEPropertiesInfoOfSection

function revIDEPropertiesInfoOfSection pObjectList, pSection
   if pSection is "Custom" then
      return revIDECustomPropertiesInfo(pObjectList)
   end if

   local tSharedPropertiesA
   put __revIDEPropertiesInfoOfSection(pObjectList, pSection) into tSharedPropertiesA

   # Return ordered list
   if pSection is empty then
      return __orderPropArray(tSharedPropertiesA, revIDEPropertySections())
   else
      return __orderPropSection(tSharedPropertiesA["grouplist"])
   end if
end revIDEPropertiesInfoOfSection

on revIDEPropertySet pObjectList, pProperty, pValue, pLockUpdates
   local tThrottlePropertyChanged
   put false into tThrottlePropertyChanged
   if the number of lines in pObjectList > 1 then
      put true into tThrottlePropertyChanged
   end if

   if tThrottlePropertyChanged or pLockUpdates then
      put true into sLockUpdates
   end if

   repeat for each line tObject in pObjectList
      if pProperty is "customProperties" then
         put true into sLockUpdates
         revIDECustomPropertySet pObjectList, pValue
      else if pProperty contains "dgProps" then
         repeat for each key tKey in pValue
            set the dgProps[tKey] of tObject to pValue[tKey]
         end repeat
      else
         set the pProperty of tObject to pValue
      end if
   end repeat

   if sLockUpdates then
      revIDEMessageSend "idePropertyChanged", pObjectList
      put false into sLockUpdates
   end if

end revIDEPropertySet

local sStoredPropsA
on revIDEPropertyStore pObjectList, pProperty
   put revIDEProperty(pObjectList, pProperty) into sStoredPropsA[pObjectList]
end revIDEPropertyStore

on revIDEPropertyRestore pObjectList, pProperty
   if sStoredPropsA[pObjectList] is not empty then
      revIDEPropertySet pObjectList, pProperty, sStoredPropsA[pObjectList], false
   end if
end revIDEPropertyRestore

private function __customPropInfo pObject
   local tInfoA
   put revIDEPropertyInfo("customProperties") into tInfoA[1]["grouplist"][1]["proplist"][1]
   put "Custom Properties" into tInfoA[1]["grouplist"][1]["Label"]
end __customPropInfo

function revIDECustomPropertiesInfo pObjectList
   local tFirst, tCustomPropsA, tObjectList
   put true into tFirst
   repeat for each line tObject in tObjectList
      if tFirst then
         put __customPropInfo(tObject) into tCustomPropsA
         put false into tFirst
         next repeat
      end if

      union tCustomPropsA with __customPropInfo(tObject) recursively
   end repeat

   return tCustomPropsA
end revIDECustomPropertiesInfo

on revIDECustomPropertySet pObjectList, pValue
   repeat for each line tObject in pObjectList
      set the custompropertysets of tObject to empty
      if pValue is not empty then
         repeat for each key tKey in pValue
            set the custompropertyset of tObject to tKey
            set the customKeys of tObject to the keys of pValue[tKey]
            repeat for each key tProp in pValue[tKey]
               set the tProp of tObject to pValue[tKey][tProp]
            end repeat
         end repeat
      else
         set the custompropertyset of tObject to empty
         set the customKeys of tObject to empty
      end if
   end repeat
end revIDECustomPropertySet

function revIDECustomProperty pObjectList, pSet, pProperty
   return the pSet[pProperty] of line 1 of pObjectList
end revIDECustomProperty

function revIDECustomProperties pObjectList
   local tFirst, tCustomPropsA
   put true into tFirst
   repeat for each line tObject in pObjectList
      if tFirst then
         put __customPropertyData(tObject) into tCustomPropsA
         put false into tFirst
         next repeat
      end if

      union tCustomPropsA with __customPropInfo(tObject) recursively
   end repeat

   return tCustomPropsA
end revIDECustomProperties

private on __populatePropertyArray pObject, pPropertyValues, @xPropertiesA
   repeat for each line tPropertyName in the keys of pPropertyValues
      if tPropertyName begins with "effective" then next repeat
      if pPropertyValues["effective" && tPropertyName] is not empty then
         put pPropertyValues["effective" && tPropertyName] into xPropertiesA[tPropertyName]["effective value"][pObject]
      end if
      put pPropertyValues[tPropertyName] into xPropertiesA[tPropertyName]["value"][pObject]
   end repeat
end __populatePropertyArray

private function __revIDEPropertiesOfObjectsWithList pObjectList, pPropertiesList, pSharedProperties
   # Generate a list of the properties we want to retreive
   local tResultA, tNewList
   repeat for each line tLine in pPropertiesList
      if pSharedProperties[tLine] is not empty then
         put tLine & CR after tNewList
      end if
   end repeat
   delete the last char of tNewList

   local tPropertyValues
   repeat for each line tObject in pObjectList
      dispatch function "__readPropertiesOfControl" to tObject with tNewList, tPropertyValues
   end repeat

   return tPropertyValues
end __revIDEPropertiesOfObjectsWithList

private function __revIDEPropertiesOfObjectsInSection pObjectList, pSectionInfoA
   # Generate a list of the properties we want to retreive
   local tPropertyValuesA
   repeat for each line tObject in pObjectList
      dispatch function "__readGroupedPropertiesOfControl" to tObject with pSectionInfoA, tPropertyValuesA
   end repeat
   return tPropertyValuesA
end __revIDEPropertiesOfObjectsInSection

function revIDEPropertiesOfObjects pObjectList, pPropertyList
   local tSharedProperties
   put revIDEPropertiesInfo(pObjectList) into tSharedProperties
   # Error if we didn't get an array back
   if tSharedProperties is not an array then
      return tSharedProperties
   end if

   return __revIDEPropertiesOfObjectsWithList(pObjectList, pPropertyList, tSharedProperties)
end revIDEPropertiesOfObjects

function revIDEPropertiesOfSection pObjectList, pSection
   if pSection is "Custom" then
      return revIDECustomProperties(pObjectList)
   end if

   local tSharedProperties
   put __revIDEPropertiesInfoOfSection(pObjectList, pSection) into tSharedProperties
   # Error if we didn't get an array back
   if tSharedProperties is not an array then
      return tSharedProperties
   end if

   return __revIDEPropertiesOfObjectsInSection(pObjectList, tSharedProperties["grouplist"])
end revIDEPropertiesOfSection

function revIDEProperty pObjectList, pProperty
   return revIDEPropertiesOfObjectsWithList(pObjectList, pProperty)
end revIDEProperty

on revIDEPropertyReset pObjectList, pProperty
end revIDEPropertyReset

function revIDEPropertySections
	// AL-2015-03-03: [[ Bug 14769 ]] Add 'Table' section to the property inspector
   return "Basic,Data Grid,Custom,Table,Colors,Effects,Icons,Position,Text,Advanced"
end revIDEPropertySections

function revIDEPropertySectionNameToIconName pName
   switch pName
      case "basic"
         return "home"
         break
      case "color"
      case "colour"
      case "colors"
      case "colours"
         return "pencil"
         break
      case "image"
      case "icons"
         return "picture"
         break
      case "font"
      case "text"
         return "font"
         break
      case "position"
         return "move"
         break
      case "effects"
      case "effect"
         return "magic"
         break
      case "custom"
         return "database"
         break
	  // AL-2015-03-03: [[ Bug 14769 ]] Add 'Table' section icon for the property inspector
      case "table"
         return "table"
         break
      case "data grid"
         return "list alt"
         break
      case "advanced"
         return "cogs"
         break
      default
         return "remove"
         break
   end switch
end revIDEPropertySectionNameToIconName

function revIDEPaletteResourcePath pFilename
   local tPalettePath
   set the itemdel to slash
   put item 1 to -2 of the filename of revIDEStackOfObject(the long id of the target) into tPalettePath
   if there is not a file tPalettePath & slash  & pFilename then
      return "file not found"
   end if

   return  tPalettePath & slash  & pFilename
end revIDEPaletteResourcePath

on logChanged pLog
   revIDEMessageSend "ideExtensionLog", pLog
end logChanged

function revIDELastModifiedTimeOfFile pFolder, pFile
   local tDetailedFiles
   set the defaultFolder to pFolder
   put the detailed files into tDetailedFiles
   return item 5 of line lineOffset(pFile, tDetailedFiles) of tDetailedFiles
end revIDELastModifiedTimeOfFile

function revIDEExtensionFolders
   local tFoldersA
   put revIDESpecialFolderPath("user extensions") into tFoldersA["user"]
   if not revEnvironmentIsInstalled() then
      put revEnvironmentBinariesPath() & slash & "packaged_extensions" into tFoldersA["ide"]
   else
      put revIDESpecialFolderPath("extensions") into tFoldersA["ide"]
   end if
   return tFoldersA
end revIDEExtensionFolders

function revIDEDefaultExtensionIcon pType, pRetina
   switch pType
      case "library"
         if pRetina is true then
            return revIDESpecialFolderPath("images") & slash & "extension-library@extra-high.png"
         else
            return revIDESpecialFolderPath("images") & slash & "extension-library.png"
         end if
      case "widget"
      default
         if pRetina is true then
            return revIDESpecialFolderPath("images") & slash & "extension-widget@extra-high.png"
         else
            return revIDESpecialFolderPath("images") & slash & "extension-widget.png"
         end if
   end switch
end revIDEDefaultExtensionIcon

function revIDEScriptEditorBehavior pWhich
   local tPathToBehaviors
   put revIDESpecialFolderPath("Toolset") & slash & "palettes" & slash & "script editor" & slash & "behaviors" into tPathToBehaviors
   switch pWhich
      case "editor"
         return tPathToBehaviors & slash & "revseeditorbehavior.livecodescript"
      case "handlerlist"
         return tPathToBehaviors & slash & "revsehandlerlistbehavior.livecodescript"
      case "menubar"
         return tPathToBehaviors & slash & "revsemenubarbehavior.livecodescript"
      case "scripttabs"
         return tPathToBehaviors & slash & "revsescripttabsbehavior.livecodescript"
      case "toolbar"
         return tPathToBehaviors & slash & "revsetoolbarbehavior.livecodescript"
      case "stack"
      default
         return tPathToBehaviors & slash & "revsestackbehavior.livecodescript"
   end switch
end revIDEScriptEditorBehavior

on revIDEAnswerDialogClosed
   local tPopupSource
   put item 1 of line 1 of the executionContexts into tPopupSource
   revIDEMessageSend "ideAnswerDialogClosed", tPopupSource
end revIDEAnswerDialogClosed

local sTutorialName
on revIDEStartTutorial pName
   dispatch "revTutorialStart" to stack "revTutorial" with pName
   put pName into sTutorialName
   revIDEMessageSend "ideTutorialProgressChanged"
end revIDEStartTutorial

on revIDEStopTutorial
   if revIDETutorialInProgress() is not empty then
      revFinaliseTutorial
   end if
   put empty into sTutorialName
   revIDEMessageSend "ideTutorialProgressChanged"
   wait 0 millisecs with messages
   delete stack "revTutorial"
   revIDEOpenPalette "Create It Welcome"
end revIDEStopTutorial

function revIDETutorialInProgress
   return sTutorialName
end revIDETutorialInProgress

function revIDETutorialResourcePath pTutorial
   local tTutorialPath
   put revIDESpecialFolderPath("tutorial") & "/tutorials/" & pTutorial &  "/resources" into tTutorialPath
   if there is a folder tTutorialPath then
      return tTutorialPath
   end if
   return __revIDEError("Tutorial resource path not found") 
end revIDETutorialResourcePath

function revIDEPaletteToStackName pPalette
   switch pPalette
      case "menubar"
         return "revMenubarUI"
      case "tools"
         return "revTools"
      case "inspector"
         return "revInspector"
      default
         break
   end switch
   return empty
end revIDEPaletteToStackName

function revIDEAbsoluteRectOfObject pPalette, pObjectData
   if pPalette is "script editor" then
      dispatch function "absoluteRectOfObject" to stack revScriptEditor(pObjectData["object"]) with pObjectData["item"]
   else
      dispatch function "absoluteRectOfObject" to stack revIDEPaletteToStackName(pPalette) with pObjectData
   end if
   return the result
end revIDEAbsoluteRectOfObject

function revIDERelativeRectToAbsolute pRect, pStack
   
   if the short name of pStack begins with revIDEScriptEditorPrefix() and the platform is "macos" then
      put item 1 of pRect + the effective left of pStack into item 1 of pRect
      put item 3 of pRect + the effective left of pStack into item 3 of pRect
      
      put item 2 of pRect + the effective top of pStack into item 2 of pRect
      put item 4 of pRect + the effective top of pStack into item 4 of pRect
   else
      put item 1 of pRect + the left of pStack into item 1 of pRect
      put item 3 of pRect + the left of pStack into item 3 of pRect
      
      put item 2 of pRect + the top of pStack into item 2 of pRect
      put item 4 of pRect + the top of pStack into item 4 of pRect
   end if
   return pRect
end revIDERelativeRectToAbsolute

on revIDEHighlightObject pPalette, pObjectData
   if pPalette is "script editor" then
      dispatch "highlightObject" to stack revScriptEditor(pObjectData["object"]) with pObjectData["item"]
   else
      dispatch "highlightObject" to stack revIDEPaletteToStackName(pPalette) with pObjectData
   end if
end revIDEHighlightObject

#############
# Data grid
#############

constant kResourceStack = "revDataGridLibrary"
constant kTemplateStack = "Data Grid Templates"
constant kDefaultRect = "0,0,300,500"

## pDataGridControl is long id of data grid control (default is "DataGrid" in revDataGridLibrary stack to copy to pStack (short name).
## pTemplateGroupSource is optional.
command AddDataGridToStack pStack, pRect, pDataGridControl, pTemplateGroupSource, @rGroupId
   if there is not a stack pStack then put the short name of the topstack into pStack
   if pRect is not a rect then put kDefaultRect into pRect
   if there is not a pDataGridControl then put the long id of group "DataGrid" of group "Templates" of stack kResourceStack into pDataGridControl

   local theError
   ConfirmPresenceOfTemplateStack pStack
   put the result into theError

   if theError is empty then
      local theDataGridGroup
      copy pDataGridControl to stack pStack
      put it into theDataGridGroup
      set the rect of theDataGridGroup to pRect

      if pTemplateGroupSource is empty and pStack is not "revDragControl" then
         CreateTemplateForControl pStack
         put the result into pTemplateGroupSource
      end if

      set the visible of theDataGridGroup to true
      ## behaviors are already set in templates
      -- set the parentscript of theDataGridGroup to the long id of button id 1005 of stack kResourceStack
      -- set the parentscript of button "TrackDragDrop" of theDataGridGroup to the long id of button id 1006 of stack kResourceStack

      set the dgProps["record template"] of theDataGridGroup to pTemplateGroupSource
      send "ResetControl" to theDataGridGroup
   end if

   put theDataGridGroup into rGroupId
   return theError
end AddDataGridToStack

## Assumes resource stack already exists
command ConfirmPresenceOfTemplateStack pStack
   -----
   local theLineNo
   local theSubstack, tStackName
   local tUnique
   -----

   local theMainStack
   put the mainstack of stack pStack into theMainStack

   local i
   repeat for each line theSubstack in the substacks of stack theMainStack
      add 1 to i
      if theSubstack begins with kTemplateStack then
         put i into theLineNo
         exit repeat
      end if
   end repeat

   -- put the executioncontexts
   -- answer pStack & cr & theLineNo

   local msgsAreLocked
   put the lockmessages into msgsAreLocked
   lock messages

   if theLineNo < 1 then
      lock screen

      put the milliseconds into tUnique
      put kTemplateStack && tUnique into tStackName
      set the topleft of the templatestack to -1000,-1000
      create stack tStackName
      close stack tStackName
      set the mainstack of stack tStackName to the mainstack of stack pStack

      set the width of stack tStackName to 600
      set the height of stack tStackName to 400
      set the topleft of stack tStackName to 180,180

      unlock screen

   else
      put line theLineNo of the substacks of stack theMainStack into tStackName
   end if

   local theRestoreStack
   put the defaultstack into theRestoreStack
   set the defaultstack to tStackName

   ## Make sure we have an instructions background
   if there is not a background "_DataGridTemplateInstructions_" of stack tStackName then
      copy group "_DataGridTemplateInstructions_" of stack kResourceStack to card 1 of stack tStackName
      -- MW-2011-03-16: Make sure the instructions is actually a background.
      set the backgroundBehavior of group "_DataGridTemplateInstructions_" of card 1 of stack tStackName to true
   end if

   ## Make sure it appears on every card
   repeat with i = 1 to the number of cards of stack tStackName
      if there is not a group "_DataGridTemplateInstructions_" of card i of stack tStackName then
         place background "_DataGridTemplateInstructions_" onto card i
         set the bottomleft of group "_DataGridTemplateInstructions_" of card i to 0, the height of card i
      end if
   end repeat

   set the defaultstack to theRestoreStack

   set the lockmessages to msgsAreLocked

   return empty
end ConfirmPresenceOfTemplateStack


## Assumes presence of template stack in memory
command CreateTemplateForControl pStack
   -----
   local theLineNo
   local theSubstack, tStackName
   local theTemplateGroup
   local tRestore
   -----
   put the defaultstack into tRestore
   lock screen

   local msgsAreLocked
   put the lockmessages into msgsAreLocked
   lock messages

   local theMainStack
   put the mainstack of stack pStack into theMainStack

   local i
   repeat for each line theSubstack in the substacks of stack theMainStack
      add 1 to i
      if theSubstack begins with kTemplateStack then
         put i into theLineNo
         exit repeat
      end if
   end repeat
   put line theLineNo of (the substacks of stack theMainStack) into tStackName

   set the topleft of stack tStackname to -1000,-1000
   hide stack tStackName
   toplevel stack tStackName
   set the defaultstack to tStackName
   if the number of controls on this card > 0 then
      create card
   end if

   copy group "Default Row Template" of group "Templates" of stack kResourceStack to the current card of the defaultstack
   put it into theTemplateGroup
   set the name of theTemplateGroup to "Row Template"
   set the topleft of theTemplateGroup to 0,0

   create button "Behavior Script"
   set the visible of it to false

   set the script of it to the uDefaultScript of button "Default Script" of stack kResourceStack

   set the parentscript of theTemplateGroup to it

   ## Provide instructions
   set the bottomleft of group "_DataGridTemplateInstructions_" of card 1 to the bottomleft of the current card of the defaultstack

   close stack tStackName
   show stack tStackName
   set the topleft of stack tStackName to 180,180

   set the defaultstack to tRestore

   set the lockmessages to msgsAreLocked
   unlock screen

   return theTemplateGroup
end CreateTemplateForControl

#############
# Standalone Settings
#############

private function __standaloneSettingsInfoFilename
   return "standaloneSettings.txt"
end __standaloneSettingsInfoFilename

function revIDEStandaloneSettings pStack, pSection
   local tInfo
   put revIDEStandaloneSettingsInfoOfSection(pSection) into tInfo

   local tPropsA, tPropName
   repeat for each element tGroup in tInfo
      repeat for each element tProp in tGroup["proplist"]
         put tProp["property_name"] into tPropName
         put tProp into tPropsA[tGroup["label"]][tPropName]
         put the cRevStandaloneSettings[tPropName] of pStack into tPropsA[tGroup["label"]][tPropName]["value"]
      end repeat
   end repeat
   return tPropsA
end revIDEStandaloneSettings

function revIDEStandaloneSettingsInfoOfSection pSection
   local tStandaloneDefinitionsPath
   put revIDESpecialFolderPath("Standalone Settings Definitions") into tStandaloneDefinitionsPath

   local tInfoA
   put __propertyDataFromInfoFile(tStandaloneDefinitionsPath & slash & __standaloneSettingsInfoFilename()) into tInfoA

   local tOrganisedA
   put __organisePropertyInfo(tInfoA) into tOrganisedA

   return __orderPropSubArray(tOrganisedA[pSection], true)
end revIDEStandaloneSettingsInfoOfSection

function revIDEStandaloneSettingsInfo
   local tStandaloneDefinitionsPath
   put revIDESpecialFolderPath("Standalone Settings Definitions") into tStandaloneDefinitionsPath

   local tInfoA
   put __propertyDataFromInfoFile(tStandaloneDefinitionsPath & slash & __standaloneSettingsInfoFilename()) into tInfoA

   return __orderPropArray(__organisePropertyInfo(tInfoA), revIDEStandaloneSections())
end revIDEStandaloneSettingsInfo

on revIDEStandaloneSettingsSet pStack, pProperty, pValue
   set the cRevStandaloneSettings[pProperty] of pStack to pValue
end revIDEStandaloneSettingsSet

function revIDEStandaloneSections
	// AL-2015-03-03: [[ Bug 14769 ]] Add 'Table' section to the property inspector
   return "General,Stacks,Copy Files,Mac,Windows,Linux,iOS,Android,Bug Reports"
end revIDEStandaloneSections

function revIDEStandaloneSectionNameToIconName pName
   switch pName
      default
         return "remove"
         break
   end switch
end revIDEStandaloneSectionNameToIconName

on revIDEOpenStack pFilePath
   local tError
   put empty into tError
   set the cursor to watch
   go stack pFilePath
   if the result is not empty then
      put the result into tError
   end if
   if tError is not empty then
      answer error "There was a problem opening stack:" && pFilePath & cr & tError
      set the cursor to 1
   else
      revIDEAddRecentStack pFilePath
   end if
end revIDEOpenStack

on revIDEActionOpenRecent pStackName
   # Plan is to refactor this like the plugin menu
end revIDEActionOpenRecent

on revIDEHelpKeyPressed
   --send "menuPick" && quote & "Help Contents" & quote to btn "Help" of stack "revMenuBar"
end revIDEHelpKeyPressed

on revIDETogglePaletteView
   global gRevPalettes
   local tOpenStacks
   put the openStacks into tOpenStacks
   lock screen
   if gREVPalettes is empty then
      repeat for each line tStack in tOpenStacks
         if tStack is revIDEPaletteToStackName("menubar") or char 1 to 3 of tStack is not "rev" and tStack is not "Message box" then next repeat
         if the mode of stack tStack is 4 and the visible of stack tStack then
            hide stack tStack
            put tStack & comma & lineOffset(tStack, tOpenStacks) & return after gREVPalettes
         end if
      end repeat
      delete last char of gREVPalettes
      --unhilite menuItem 10 of me
      set the icon of button "toggle palettes" to 201316
      set the rect of button "Palettes Inverted" to the rect of button "Toggle Palettes"
   else
      sort lines of gREVPalettes descending by item 2 of each
      lock messages
      repeat for each line tPaletteName in gREVPalettes
         local tPalette
         put item 1 of tPaletteName into tPalette
         if the mode of stack tPalette is 4 and not the visible of stack tPalette then
            show stack tPalette
         else if the platform is not in "MacOS,Win32" and the mode of stack tPalette is 0 then
            show stack tPalette
            palette tPalette
            lock messages
         end if
      end repeat
      --hilite menuItem 10 of me
      put empty into gREVPalettes
      set the icon of button "toggle palettes" to 200874
      set the loc of button "Palettes Inverted" to -100,-100
   end if
   unlock screen
end revIDETogglePaletteView

on revIDEPopupContextualMenu pTargets
   dispatch "revMenubarPopupContextualMenu" to stack revIDEPaletteToStackName("menubar") with pTargets
end revIDEPopupContextualMenu

local sPluginsA
on revIDEUpdatePlugins
   global gREVStartupList, gREVShutdownlist, gREVDontLoadMenus
   
   local tUserPlugins
   put revAbsoluteFolderListing(revEnvironmentUserPluginsPath()) into tUserPlugins
   
   local tEnvironmentPlugins
   put revAbsoluteFolderListing(revEnvironmentPluginsPath()) into tEnvironmentPlugins
   
   local tFinal
   put revCombineFilePaths(tUserPlugins,tEnvironmentPlugins) into tFinal
   
   put empty into gREVStartupList
   put empty into gREVShutdownList
   
   local tPluginsA, tName
   lock messages
   repeat for each line tStack in tFinal
      if there is a stack tStack then
         put the short name of stack tStack into tName
         put tStack into tPluginsA[tName]["path"]
         if the cREVLoadInfo["load"] of stack tStack is "chosen" or the cREVLoadInfo["load"] of stack tStack is empty or the cREVLoadInfo["inMenu"] of stack tStack is true then
            put true into tPluginsA[tName]["menu"] -- appears in menu
         end if
         if the cREVLoadInfo["load"] of stack tStack is "startup" then
            put tStack into line (the number of lines in gREVStartupList + 1) of gREVStartupList
         else if the cREVLoadInfo["load"] of stack tStack is "shutdown" then
            put tStack into line (the number of lines in gREVShutdownList + 1) of gREVShutDownList
         end if
         # See bug 2031
         # The closeStack handler in the plugin settings dialog calls this handler
         # So only those stacks which weren't already open should be removed from memory
         if the mode of stack tStack is 0 then
            # See bug 10710
            # cantDelete has been changed and was causing an error
            set the cantDelete of stack tStack to false
            delete stack tStack
         end if
      end if
   end repeat
   
   unlock messages
   
   # Only send the plugins changed message when the details of the plugins change
   local tPluginsChanged
   put false into tPluginsChanged
   if sPluginsA is empty or tPluginsA is not sPluginsA then
      put true into tPluginsChanged
   end if
   
   put tPluginsA into sPluginsA
   
   if tPluginsChanged then
      revIDEMessageSend "idePluginsChanged"
   end if
end revIDEUpdatePlugins

function revIDEPlugins
   return sPluginsA
end revIDEPlugins

on revIDEOpenPlugin pName
   local tStackPath
   put sPluginsA[pName]["path"] into tStackPath
   
   if there is not a stack tStackPath then
      delete variable sPluginsA[pName]
      exit revIDEOpenPlugin
   end if
   
   local tMode
   if the cREVLoadInfo["mode"] of stack tStackPath is not empty then 
      put the cREVLoadInfo["mode"] of stack tStackPath into tMode
   else 
      put "palette" into tMode
   end if
   
   if tMode is "invisible" then
      go invisible stack tStackPath
   else 
      do "go stack" && quote &  tStackPath & quote && "as" && tMode
   end if
end revIDEOpenPlugin

function revIDELocalise pString, pSubstitutions
   repeat for each key tKey in pSubstitutions
      replace ("%" & tKey) with pSubstitutions[tKey] in pString
   end repeat
   return pString && "(Localised String)"
end revIDELocalise

########################
# Standard IDE Library actions
########################

/*
Creates a new mainstack in the default location

Associations: stack

pWidth (optional number): The width of the newly created stack. If left empty, 400 is used
pHeight (optional number): The height of the newly created stack. If left empty, 400 is used

Example:
revIDENewMainstack

revIDENewMainstack 100,100

Tags: ide
*/
on revIDENewMainstack pWidth, pHeight
   # Set the width and height of the template stack

   # Generate a unique name for the stack
   local tNumber
   put 1 into tNumber
   repeat
      if there is a stack ("Untitled" && tNumber) then  add 1 to tNumber
      else exit repeat
   end repeat

   # Setup the template stack
   set the name of the templateStack to "Untitled" && tNumber
   set the visible of the templateStack to false
   if pWidth > 100 then
      set the width of the templateStack to pWidth
   else
      set the width of the templateStack to 400
   end if
   if pHeight > 100 then
      set the height of the templateStack to pHeight
   else
      set the height of the templateStack to 400
   end if
   if revIDEGetPreference("cDestroyStack") then
      set the destroyStack of the templateStack to true
      set the destroyWindow of the templateStack to true
   end if

   local tLeft
   if the right of stack "revTools" < (item 3 of the screenRect / 2) then put the right of stack "revTools" + 20 into tLeft
   else put item 1 of the windowBoundingRect + 20 into tLeft
   set the topLeft of the templateStack to tLeft,(the bottom of stack revIDEPaletteToStackName("menubar") + 40)

   # Create the new stack
   lock messages
   create stack
   show stack it
   unlock messages

   # Final items
   reset the templateStack
   
   # Send the 'ideNewStack' message
   revIDEMessageSend "ideNewStack", it
end revIDENewMainstack

on revIDEActionNewMainstack pStackType
   if  pStackType is "default" then
      revIDENewMainstack
   else if pStackType is "script only" then
      revIDEActionNewScriptOnlyStack
   else
      # Parse the tag to look for size
      set the itemdel to "("
      delete item 1 of pStackType
      delete the last char of pStackType
      set the itemdel to "x"

      # Check that the width and height are valid numbers
      if item 1 of pStackType is a number and item 2 of pStackType is a number then
         revIDENewMainstack item 1 of pStackType, item 2 of pStackType
      else
         revIDENewMainstack
      end if
   end if
end revIDEActionNewMainstack

on revIDEActionNewCard
   global gRevStackStatus
   local tFilterStack
   put the short name of the topStack into tFilterStack
   if revFilterStacksList(tFilterStack) is empty then 
      revIDEActionNewMainstack "default"
   end if
   set the defaultStack to the topStack 
   local tCardID
   create card
   put the long id of it into tCardID
   put "edited" into gREVStackStatus[the short name of this stack]
   revIDEMessageSend "ideNewCard tCardID"
end revIDEActionNewCard

on revIDEActionDeleteCard
   global gRevStackStatus
   set the defaultStack to the topStack
   answer error "Are you sure you want to delete this card?" with "Yes" or "No"
   if it is not "yes" then exit revIDEActionDeleteCard
   delete this card
   put "edited" into gREVStackStatus[the short name of this stack] 
end revIDEActionDeleteCard

/*
Creates a new script only stack in memory.

Associations: stack

pName (String): The name of the script only stack.

Example:
revIDENewScriptOnlyStack "MyNewScriptOnlyStack"

Tags: ide
*/
on revIDENewScriptOnlyStack pName
   if pName is empty then return __revIDEError("Script only stacks cannot be created without a name")
   if there is a stack pName then return "A stack with that name already exists"

   create script only stack pName
   edit the script of stack pName
end revIDENewScriptOnlyStack

on revIDEActionNewScriptOnlyStack
   # Get the name of the stack
   ask revIDELocalise("Please enter a name for the script only stack")
   if the result is "cancel" then exit revIDEActionNewScriptOnlyStack
   if it is empty then exit revIDEActionNewScriptOnlyStack

   # Create script only
   revIDENewScriptOnlyStack it

   # If an error occured, tell the use
   if the result is not empty then
      answer the result
   end if
end revIDEActionNewScriptOnlyStack

/*
Creates a new substack.

Associations: stack

pParentStackID (String): The long ID of the stack to attach the substack to.

Example:
revIDENewSubstack the long ID of the topstack

Tags: ide
*/
on revIDENewSubstack
   # Get the current stack
   local tCurrentStack
   put the short name of the topStack into tCurrentStack
   if the mainStack of stack tCurrentStack is not tCurrentStack then put the mainStack of stack tCurrentStack into tCurrentStack

   # Create a new stack
   revIDENewMainstack

   # Make the new stack a substack of the current stack
   set the mainStack of the topStack to tCurrentStack
end revIDENewSubstack

/*
Opens a stack from file.

Associations: stack

pFilePath (String): The path to a stack on disk

Example:
revIDEOpenStack "/Users/xxxx/Desktop/stack.livecode"

Tags: ide
*/
on revIDEOpenStack pFilePath
   if there is not a file pFilePath then return __revIDEError("Specified file does not exist")
   if revIDEIsLiveCodeStack(pFilePath) is not true then return __revIDEError("File is not a LiveCode stack")

   go stack pFilePath
end revIDEOpenStack

function revIDEIsLiveCodeStack pFilePath
   set the itemdel to "."

   # Check the file extension
   if the last item of pFilePath is among the items of revIDELiveCodeFileExtensions() then
      return true
   else
      return false
   end if
end revIDEIsLiveCodeStack

function revIDEStackIsScriptOnly pStackFile
   if there is a stack pStackFile then
      local tStackFile
      put url ("file:" & pStackFile) into tStackFile
      if char 1 to 6 of tStackFile is "script" then
         return true
      end if
   end if
   
   return false
end revIDEStackIsScriptOnly

on revIDEActionOpenStack
   # Popup a file choose
   revIDEAnswerFile "stack"
   
   # Get the path of to the file
   local tStackFilePath
   put the result into tStackFilePath
   
   # Check the stack exists
   if there is not a file tStackFilePath then exit revIDEActionOpenStack
   
   # Open the stack
   revIDEOpenStack tStackFilePath
   
   # AL-2015-06-09: [[ Bug 14831 ]] If stack is script only, open in script editor
   if revIDEStackIsScriptOnly(tStackFilePath) then
      revIDEEditScriptOfObject the long id of stack tStackFilePath
   end if
end revIDEActionOpenStack

/*
Closes an stack.

Associations: stack

pStackID (String): The long ID of the stack to close
pDestroy (Optional Boolean): True if the stack should be deleted from memory

Example:
# Close the stack be keep in memory
revIDECloseStack the long ID of the topstack

# Close the stack completely removing it from memory
revIDECloseStack the long ID of the topstack, true

Tags: ide
*/
on revIDECloseStack pStackID, pDestroy
   if not exists(pStackID) then return revIDELocalise("Cannot close stack, it doesn't exist")

   if revSaveCheck(pStackID) is not false then
      if pStackID is true then
         delete stack pStackID
      else
         close stack pStackID
      end if
   end if
end revIDECloseStack

on revIDEActionCloseStack
   # Can't close revMenuBar
   if the short name of the topStack is "revMenuBar" then exit revIDEActionCloseStack

   # Validate the stack you are closing
   if the mode of the topStack is not among the items of "1,2,3" then
      exit revIDEActionCloseStack
   end if

   local tStackList
   put the windows into tStackList
   repeat for each line tStack in tStackList
      if tStack is "revMenuBar" then next repeat
      if the mode of stack tStack is among the items of "1,2,3" then
         exit repeat
      end if
   end repeat
   set the defaultStack to tStack
   if word 1 of the short name of this stack is "revScriptEditor" then
      send "revCheckScriptSaved" to this cd
      close this stack
      exit revIDEActionCloseStack
   end if

   revIDECloseStack the long ID of stack tStack, false
end revIDEActionCloseStack

/*
Returns a list of the recently opened stacks.

Associations: stack

Returns: A return and | (pipe) delimited list of stack title and filename


Example:
local tRecentStacks
put revIDERecentFiles() into tRecentStacks

# put tRecentStacks
# stack title|file path
# stack title|file path
# stack title|file path
# ...

Tags: ide
*/
function revIDERecentFiles
  # return list
end revIDERecentFiles

/*
Returns a list control types that can be imported by LiveCode.

Associations: controls

Returns: A return delimeted list of control types that can be imported

Example:
local tImportableControls
put revIDEImportableControls() into tImportableControls

# put revIDEImportableControls
# image
# video
# audio

Tags: ide
*/
function revIDEImportableControls
   return "image,video,audio,text"
end revIDEImportableControls

function revIDELiveCodeFileExtensions
   return revIDEAcceptedTypes("livecode")
end revIDELiveCodeFileExtensions

function revIDEAcceptedTypes pType
   switch pType
      case "image"
         return "jpg,jpeg,gif,png,bitmap"
         break
      case "video"
         return "mp4,mpeg,mov"
         break
      case "audio"
         return "mp3,wav,aiff"
         break
      case "livecode"
         return "livecode,rev,lc,livecodescript"
      case "text"
         return "txt"
         break
   end switch
end revIDEAcceptedTypes

on revIDEActionImportControl pType, pReferenced
   if pType is not among the items of revIDEImportableControls() then exit revIDEActionImportControl
   
   # Ask the user to pick a file of the given type
   revIDEAnswerFile pType
   
   # User has not chosen a file
   if the result is "cancel" then exit revIDEActionImportControl
   
   # Check the file exists
   local tFilePath
   put the result into tFilePath
   if there is not a file tFilePath then exit revIDEActionImportControl
   
   # Import the control
   if pReferenced is true then
      revIDEImportControl pType, tFilePath, true
   else
      revIDEImportControl pType, tFilePath
   end if
end revIDEActionImportControl

on revIDEActionImportControlFromFolder pType, pReference
   answer folder revIDELocalise("Please select a folder to import from")
   
   if the result is "cancel" then exit revIDEActionImportControlFromFolder
   local tFolderPath
   put it into tFolderPath
   
   # Store the current default folder
   local tDefaultFolder, tAcceptedTypes
   put the defaultfolder into tDefaultFolder
   put revIDEAcceptedTypes(pType) into tAcceptedTypes
   replace "," with "." in tAcceptedTypes
   
   set the defaultfolder to tFolderPath
   set the itemdel to "."
   lock screen
   lock messages
   repeat for each line tFile in the files
      if char 1 of tFile is "." then next repeat
      if the last item of tFile is not among the items of tAcceptedTypes then next repeat
      
      revIDEImportControl pType, tFolderPath & slash & tFile, pReference
   end repeat
   unlock messages
   unlock screen
   
   # Restore the previous defaul folder 
   set the defaultfolder to tDefaultFolder
end revIDEActionImportControlFromFolder

on revIDEImportControl pType, pFileName, pReferenced
   if pType is not among the items of revIDEImportableControls() then return __revIDEError("Cannot import that type of control")
   if there is not a file pFileName then exit revIDEImportControl
   
   local tTargetStack, tCreatedControlLocation
   put the long ID of the topstack into tTargetStack
   put the loc of card 1 of the topstack into tCreatedControlLocation
   
   lock screen
   lock messages
   set the defaultStack to tTargetStack
   switch pType
      case "image"
         revIDECreateObject "com.livecode.interface.classic.image", tTargetStack, tCreatedControlLocation
         if pReferenced is true then
            set the filename of the last control to pFileName
         else
            set the text of the last image to URL ("binfile:" & pFileName)
         end if
         set the borderWidth of the last image to 0
         select the last control
         break
      case "audio"
         import AudioClip from file pFileName
         break
      case "video"
         if pReferenced is true then
            revIDECreateObject "com.livecode.interface.classic.player", tTargetStack, tCreatedControlLocation
            set the filename of the last control to pFileName
         else
            import videoclip from file pFileName
         end if
         break
      case "text"
         revIDECreateObject "com.livecode.interface.classic.field", tTargetStack, tCreatedControlLocation
         put URL ("file:" & pFileName) into the last field
         select the last control
         break
   end switch
   
   unlock messages
   unlock screen
end revIDEImportControl

on revIDEImportSnapshot pScope, pObjectID
   if pScope is not among the items of "screen,object" then put "screen" into pScope
   
   set the defaultstack to the topstack
   switch pScope
      case "screen"
         import snapshot
         break
      case "object"
         if pObjectID is empty then exit revIDEImportSnapshot
         
         if word 1 of pObjectID is "stack" then 
            import snapshot from rect (the rect of pObjectID)
         else
            import snapshot from the selObj
         end if
         select the last image
         break
   end switch 
end revIDEImportSnapshot

/*
Launches the standard ask dialog and returns the users selection.

pType (String): The type of file the be selected. If pType is not empty and not among the options below, it is assumed to be a custom filter in the form required by the ask command.
- image: Launches an ask dialog filtering for the following image file types: JPEG, GIF, PNG.
- stack: Launches an ask dialog filtering for the following stack file  types: lc, livecodescript, livecode.
- audio: Launches an ask dialog filtering for the following audio file types: mp3, aiif, wav.
- video: Launches an ask dialog filtering for the following audio file types: mov, mp4.
 pBasePath (Optional String): The default path that the ask dialog should point to when opened. If pBasePath is not specified, the "defaultFolder" is used.
 pInstructions (Optional String): The instructions to place in the title of the ask dialog. If not instructions are defined, default messages for each type are displayed.

 References:ask,defaultfolder

 Returns: The path to the selected file.

 The result: Sets the result to "cancel" if the user cancels the ask dialog.

Example:
revIDEAsk "image"

revIDEAsk "image", "/Users/xxx/Desktop/"

revIDEAsk "image", "/Users/xxx/Desktop/", "Please choose the video you would like to load"

revIDEAsk "image", "", "Please choose the video you would like to load"

Tags: ide
*/
function revIDEAsk pType, pBasePath, pInstructions
   # validate pType, pBasePath, pInstructions
   # pop up ask dialog
   # validate response
   # return response
end revIDEAsk

/*
Launches the standard ask dialog and returns the users selection.

pType (String): The type of file the be selected. If pType is not empty and not among the options below, it is assumed to be a custom filter in the form required by the ask command.
- image: Launches an ask dialog filtering for the following image file types: JPEG, GIF, PNG.
- stack: Launches an ask dialog filtering for the following stack file  types: lc, livecodescript, livecode.
- audio: Launches an ask dialog filtering for the following audio file types: mp3, aiif, wav.
- video: Launches an ask dialog filtering for the following audio file types: mov, mp4.
 pBasePath (Optional String): The default path that the ask dialog should point to when opened. If pBasePath is not specified, the "defaultFolder" is used.
 pInstructions (Optional String): The instructions to place in the title of the ask dialog. If not instructions are defined, default messages for each type are displayed.

 References:ask,defaultfolder

 Returns: The path to the selected file.

 The result: Sets the result to "cancel" if the user cancels the ask dialog.

Example:
revIDEAsk "image"

revIDEAsk "image", "/Users/xxx/Desktop/"

revIDEAsk "image", "/Users/xxx/Desktop/", "Please choose the video you would like to load"

revIDEAsk "image", "", "Please choose the video you would like to load"

Tags: ide
*/
on revIDEAskFile pType, pInstructions, pBasePath
   # validate pType, pBasePath, pInstructions
   # pop up ask dialog
   # validate response
   # return response
end revIDEAskFile

on revIDEAnswerFile pType, pInstructions, pBasePath, pTypesA
   local tTypesA
   put pTypesA into tTypesA
   
   local tInstructions
   put pInstructions into tInstructions
   switch pType
      case "stack"
         if tInstructions is empty then put revIDELocalise("Please select a LiveCode stack to open") into tInstructions
         put "LiveCode Stacks|" & revIDEAcceptedTypes("livecode") into tTypesA[1]
         put "All Files|" into tTypesA[2]
         break
      case "image"
         if tInstructions is empty then put revIDELocalise("Please select an image") into tInstructions
         put "Images|" & revIDEAcceptedTypes(pType) into tTypesA[1]
         break
      case "video"
         if tInstructions is empty then put revIDELocalise("Please select a video") into tInstructions
         put "Videos|" & revIDEAcceptedTypes(pType) into tTypesA[1]
         break
      case "text"
         if tInstructions is empty then put revIDELocalise("Please select the file containing the text to import") into tInstructions
         put "Text Files|" & revIDEAcceptedTypes(pType) into tTypesA[1]
         break
      case "audio"
         if tInstructions is empty then put revIDELocalise("Please select an audio file") into tInstructions
         put "Audio Files|" & revIDEAcceptedTypes(pType) into tTypesA[1]
         break
   end switch
   
   # Build the answer string from the various components
   local tAnswerString
   put "answer file pInstructions" into tAnswerString
   
   # If there is a tutorial in progress, open dialog browsing tutorial resource folder
   local tTutorial
   put revIDETutorialInProgress() into tTutorial
   if tTutorial is not empty then
      put " with" && quote & revIDETutorialResourcePath(tTutorial) & quote after tAnswerString
   end if
   
   # Add any types defined in the type array
   local tTypeString
   repeat with x  = 1 to the number of elements of tTypesA
      if tTypeString is empty then
         put " with type" && quote & tTypesA[x] & quote into tTypeString
      else
         put " or type" && quote & tTypesA[x] & quote after tTypeString
      end if
   end repeat
   put tTypeString after tAnswerString
   
   # Do the answer file
   do tAnswerString
   
   if the result is "cancel" then
      return "cancel"
   else
      return it
   end if
end revIDEAnswerFile

function revIDESnapshotScreenImageData
   # Take a snapshot of the screen
   # Return the image data
end revIDESnapshotScreenImageData

on revIDESnapshopScreen
   # get screen image data
   # create image
   # set data of image
end revIDESnapshopScreen

function revIDESnapshotSelectedObjectsImageData
   # Take a snapshot of the selected objects
   # Return the image data
end revIDESnapshotSelectedObjectsImageData

on revIDESnapshotSelectedObjects
   # get image data for selected objects
   # create image
   # set data of image
end revIDESnapshotSelectedObjects

function revIDEStackFileVersion pStackFile
      open file pStackFile for binary read
      read from file pStackFile for 8
      close file pStackFile
      if it begins with "REVO" then
         return (byte 5 of it & "." & byte 6 of it)
      else
         return "2.4"
      end if
end revIDEStackFileVersion

on revIDESaveStack pStackID
   local tDefaultStack
   put the defaultStack into tDefaultStack
   
   local tStackName
   put the short name of pStackID into tStackName
   
   # Old style message handling. Queue of stacks to save are being notified to save
   global gREVMessageDispatch
   repeat for each line tStack in gREVMessageDispatch["revSaveStackRequest"]
      send "revSaveStackRequest" to this card of stack tStack
   end repeat
   
   # Check if the stack has a filename. IF not, redirect to save as
   if the filename of stack tStackName is empty then
      revIDEActionSaveStackAs the long ID of stack tStackName
      exit revIDESaveStack
   end if
   
   set the defaultStack to "revSaving"
   
   local tMainStack
   put the mainStack of stack tStackName into tMainStack
   
   local tSubStacks
   put the substacks of stack tMainStack into tSubStacks
   
   local tSubTabbed
   repeat for each line tStack in tSubStacks
      put tab & tStack & return after tSubTabbed
   end repeat
   delete last char of tSubTabbed
   put tSubTabbed into tSubStacks
   
   local tStacksList
   local tFinal
   put tStackName into tFinal
   put the mainstack of stack tStackName into tStacksList
   
   local tResultLog
   
   set the visible of stack "revSaving" to false
   palette "revSaving"
   set the cSavingStack of card 1 of stack "revSaving" to tStackName
   show stack "revSaving"
   
   local tSelectedList
   put (the selObj) into tSelectedList
   select empty
   compact stack tStackName
   
   -- Dispatch the pre-save hook, just before we lock messages and do the save.
   dispatch "revHookPreSaveStack" to me with pStackID
   
   lock messages
   
   local tOldStackFileVersion
   put the stackFileVersion into tOldStackFileVersion
   
   if the cPreserveStackVersion of stack "revPreferences" is true and the cREVGeneral["stackfileversion"] of stack tStackName is not empty then
      try
         set the stackFileVersion to the cREVGeneral["stackfileversion"] of stack tStackName
      catch tError
         --
      end try
   end if
   
   if the scaleFactor of stack tStackName is a number then
      set the cREVGeneral["scalefactor"] of stack tStackName to the scalefactor of stack tStackName
   end if
   
   local tOldStackFileType
   put the stackFileType into tOldStackFileType
   if the cPreserveStackCreator of stack "revPreferences" is true then
      local tOldFolder
      put the folder into tOldFolder
      
      local tStackFilename
      put the filename of stack tStackName into tStackFilename
      if there is a file tStackFilename then
         set the itemDelimiter to "/"
         set the folder to item 1 to -2 of tStackFilename
         
         local tStackFileDetails
         put the detailed files into tStackFileDetails
         
         local tStackFileLeaf
         put the urlEncode of the last item of tStackFilename into tStackFileLeaf
         set the itemDelimiter to comma
         get item 11 of line lineOffset(tStackFileLeaf, tStackFileDetails) of tStackFileDetails
         if char 1 to 4 of it is not "????" then
            set the stackFileType to char 1 to 4 of it & "RSTK"
         end if
      end if
      
      set the folder to tOldFolder
   end if
   
   local tSaveResult
   
   # TH - 27/11/07 : Bug 5569, savestack request not sent to the users stack because messages are locked at this point
   try
      # OK-2008-03-14 : Bug 5890. When saving a stack with suppress messages turned on
      # execution of the revSave command terminates after the sending of saveStackRequest
      # to the target stack. This is because revFrontScript handles the message and passes
      # to metaCard, which prevents further execution. This bug is worked round with a nasty
      # hack involving a global...
      global gREVAllowSaveStackRequest
      put true into gREVAllowSaveStackRequest
      
      set the defaultStack to tStackName
      send "saveStackRequest" to this card of stack tStackName
      set the defaultStack to tDefaultStack
   end try
   
   save stack tStackName
   put the result into tSaveResult
   
   
   ## MJ - 17/07/2006 : Bug 3722, it appears these two lines here override the result...
   ## Hence the introduction of the above variable.
   set the stackFileType to tOldStackFileType
   set the stackFileVersion to tOldStackFileVersion
   
   unlock messages
   
   local tResult
   if tSaveResult is not empty then
      put tSaveResult & return after tResultLog
      if "backup" is in tSaveResult then put tSaveResult & return & "Check the file path, and make sure you have sufficient permissions." into tResult
      else put tSaveResult into tResult
      answer "Can't save stack" && tStackName && "due to an error:" & return & tResult
      close stack "revSaving"
   else
      -- Dispatch the post-save hook, straight after the save, but only if it succeeded.
      dispatch "revHookPostSaveStack" to me with pStackID
      
      global gRevStackStatus
      put empty into gREVStackStatus[tStackName]
      
      local tMainStackList
      put the mainStack of stack tStackName into tMainStackList
      put return & the substacks of stack tStackName after tMainStackList
      repeat for each line tStack in tMainStackList
         if tStack is empty then next repeat
         put empty into gREVStackStatus[tStack]
      end repeat
      revUpdateRecentFiles tStackName
   end if
   
   repeat for each line tSelectedObject in tSelectedList
      set the selected of tSelectedObject to true
   end repeat
   
   delete last char of tResultLog
   put revIDELocalise("Save complete - click to continue") into line -1 of field 1 of stack "revSaving"
   
   -- MW-2012-09-17: [[ Bug 10388 ]] Flush events to stop bunching.
   get flushEvents("all")
   
   -- improve speed KM oct 07 4932
   local tTime
   put the milliseconds into tTime
   repeat
      if the milliseconds - tTime > 400 then exit repeat
      if the mouseClick then exit repeat
   end repeat
   
   close stack "revSaving"
   set the defaultStack to tStackName
   
   return tResultLog
end revIDESaveStack

on revIDERevertToSavedStack pStackID
   set the defaultStack to pStackID
   
   local tLocalData
   put the topStack into tLocalData[1]
   answer warning revIDELocalise("Are you sure you want to revert to the last version saved?  All changes to stack %1 will be lost.", tLocalData)  with revIdeLocalise("No") or revIdeLocalise("Yes")
   if it is revIdeLocalise("Yes") then
      revert
   end if
end revIDERevertToSavedStack

on revIDEActionSaveStack pStackID
   if there is a file the filename of pStackID then
      revIDESaveStack pStackID
   else
      revIDEActionSaveStackAs pStackID
   end if
end revIDEActionSaveStack

on revIDESaveStackAs pStackID, pFileName
   if not exists (pStackID) then return __revIDEError("Target stack does not exist")
   if pFileName is empty then return __revIDEError("No path provided to save to")
   
   save pStackID as pFileName
   
   local tShortName
   put the short name of stack pStackID
   if the result is not empty then
      local tLocaliseSubstitutions
      put tShortName into tLocaliseSubstitutions[1]
      answer revIDELocalise("Can't save stack %1 with error:", tLocaliseSubstitutions) & return & the result
      close stack "revSaving"
   else
      global gRevStackStatus
      put empty into gREVStackStatus[tShortName]
      
      local tMainStackList
      put the mainStack of pStackID into tMainStackList
      put return & the substacks of pStackID after tMainStackList
      repeat for each line tStack in tMainStackList
         if tStack is empty then next repeat
         put empty into gREVStackStatus[tStack]
      end repeat
      revUpdateRecentFiles the short name of pStackID
   end if
end revIDESaveStackAs

on revIDEActionSaveStackAs pStackID, pSubstackOnly
   if not exists(pStackID) then __revIDEError("Target stack does not exist")

   local tMakeMainStack, tMainStackName, tStackName, tShortName
   put the short name of pStackID into tShortName

   global gREVMessageDispatch
   repeat for each line tStack in gREVMessageDispatch["revSaveStackRequest"]
      send "revSaveStackRequest" to this cd of stack tStack
   end repeat

   local tDefaultStackBackup
   put the defaultStack into tDefaultStackBackup

   # Saving if a substack
   put true into tMakeMainStack
   put the mainStack of stack tShortName into tMainStackName
   if tMainStackName is not tShortName and tMainStackName is not "Home" then
      if not pSubStackOnly then
         put false into tMakeMainStack
         put tMainStackName into tShortName
      end if
   end if

   put revFixPath(tShortName) into tStackName

   // MM-2012-03-09: Added new 5.5 stack file format to drop down.
   local tType

   local tStackFileType
   if there is a file the filename of stack tShortName then put revStackFileVersion(the filename of stack tShortName) into tStackFileType

   # Prepare substitutions for localisation
   local tSubstitutions
   put tShortName into tSubstitutions[1]

   switch tStackFileType
      case 5.5
         ask file revIDELocalise("Save stack %1 as:", tSubstitutions) with tStackName with type (revIDELocalise("Legacy LiveCode Stack (5.5)") & "|livecode,rev|RSTK") or type (revIDELocalise("LiveCode Stack") & "|livecode,rev|RSTK") or  type (revIDELocalise("Legacy LiveCode Stack (2.7)") & "|livecode,rev|RSTK") or type (revIDELocalise("Legacy LiveCode Stack (2.4)") & "|livecode,rev|RSTK")
         break
      case 2.7
         ask file revIDELocalise("Save stack %1 as:", tSubstitutions) with tStackName with type (revIDELocalise("Legacy LiveCode Stack (2.7)") & "|livecode,rev|RSTK") or type (revIDELocalise("LiveCode Stack") & "|livecode,rev|RSTK") or type (revIDELocalise("Legacy LiveCode Stack (5.5)") & "|livecode,rev|RSTK") or type (revIDELocalise("Legacy LiveCode Stack (2.4)") & "|livecode,rev|RSTK")
         break
      case 2.4
         ask file revIDELocalise("Save stack %1 as:", tSubstitutions) with tStackName with type (revIDELocalise("Legacy LiveCode Stack (2.4)") & "|livecode,rev|RSTK") or type (revIDELocalise("LiveCode Stack") & "|livecode,rev|RSTK") or type (revIDELocalise("Legacy LiveCode Stack (5.5)") & "|livecode,rev|RSTK") or type (revIDELocalise("Legacy LiveCode Stack (2.7)") & "|livecode,rev|RSTK")
         break
      default
         ask file revIDELocalise("Save stack %1 as:", tSubstitutions) with tStackName with type (revIDELocalise("LiveCode Stack") & "|livecode,rev|RSTK") or type (revIDELocalise("Legacy LiveCode Stack (5.5)") & "|livecode,rev|RSTK") or type (revIDELocalise("Legacy LiveCode Stack (2.7)") & "|livecode,rev|RSTK") or type (revIDELocalise("Legacy LiveCode Stack (2.4)") & "|livecode,rev|RSTK")
         break
   end switch

   put the result into tType

   switch tType
      case "Legacy LiveCode Stack (5.5)"
         put 5.5 into tType
         break
      case "Legacy LiveCode Stack (2.7)"
         put 2.7 into tType
         break
      case "Legacy LiveCode Stack (2.4)"
         put 2.4 into tType
         break
      default
         put 7.0 into tType
         break
   end switch

   global gRevStackStatus
   # User cancelled the the ask dialog
   if it is empty then
      put "edited" into gREVStackStatus[tShortName]
      return "Cancelled"
   end if

   # MacOS Auotmatically appends the filetype to the filename
   local tFilePath
   if the platform is not "MacOS" and not (it ends with ".rev" or it ends with ".livecode") then
      put ".livecode" after it
   end if
   put it into tFilePath

   # Display warning if user has not selected the latest file format
   if tType < 7 then
      answer revIDELocalise("Saving in legacy format may result in loss of data if you are using recent LiveCode features. Are you sure you wish to continue?") with revIDELocalise("No") and revIDELocalise("Yes")
      if it is not revIDELocalise("Yes") then
         put "edited" into gREVStackStatus[tShortName]
         return "Cancelled"
      end if
   end if

   # Window and Mac automatically present overwrite dialog
   if the platform is not in "Win32,MacOS" and there is a file tFilePath then
      answer warning revIDELocalise("File exists. Overwrite?") with revIDELocalise("Cancel") or revIDELocalise("OK")
      if it is revIDELocalise("Cancel") then
         return "Cancelled"
      else
         delete file tFilePath
      end if
   end if

   # When making a substack a mainstack, it must clone default colors set on mainstack to substack
   # so that inherited values are preserved.
   local tStackColors, tHomeColors
   if tMakeMainStack and tShortName is not tMainStackName then
      put the colors of stack tShortName into tStackColors
      put the colors of stack "Home" into tHomeColors
      repeat with i = 1 to 8
         if line i of tStackColors is empty
         then put line i of tHomeColors into line i of tStackColors
      end repeat
      set the colors of stack tShortName to tStackColors
      set mainStack stack tShortName to tShortName
      set the cursor to watch
      -- remove revOnline fingerprint
      revRemoveRevOnlineKey "fingerprint",tMainStackName
      save stack tMainStackName
   end if


   set the cursor to watch
   lock messages

   # RevOnline fingerprint enables the revOnline uploader automatically overwrite the stack if already uploaded.
   # Because you're saving as a new stack, this fingerprint should be removed.
   revRemoveRevOnlineKey "fingerprint",tShortName

   # Store the current stack file version before setting it to the value for this save
   # It will be reset after the save was made
   local tOldStackFileVersion
   put the stackFileVersion into tOldStackFileVersion
   set the stackFileVersion to tType

   # TH-2007-11-27: Bug 5569, savestack request not sent to the users stack because messages are locked at this point
   try
      # OK-2008-03-14 : Bug 5890. When saving a stack with suppress messages turned on
      # execution of the revSave command terminates after the sending of saveStackRequest
      # to the target stack. This is because revFrontScript handles the message and passes
      # to metaCard, which prevents further execution. This bug is worked round with a nasty
      # hack involving a global...
      global gREVAllowSaveStackRequest
      put true into gREVAllowSaveStackRequest

      set the defaultStack to tShortName
      send "saveStackRequest" to this card of stack tShortName
      set the defaultStack to tDefaultStackBackup
   end try

   revIDESaveStackAs the long id of stack tShortName, tFilePath

   set the stackFileVersion to tOldStackFileVersion
   unlock messages

   return empty
end revIDEActionSaveStackAs

on revIDEMoveSubstackToFile pStackID
   # Validate stack exists
   # Validate stack has a parent
   # Ask for the file to move it for
   # Set filename of stack / remove parent link
end revIDEMoveSubstackToFile

on revIDESaveAsStandalone
   # Don't want the build process to be interruptable.
   set the allowInterrupts to false
   //ideMessagesSupressSet "true" - This was in the old message library. In 8.0 messages can't be supressed. Might want to add this in revIDEMessageSend
   try
      revSaveAsStandalone
      finally
      # Bug 5111: Standalone has been built, process should now be interruptable.
      set the allowInterrupts to true
      //ideMessagesSupressSet "false"
   end try
end revIDESaveAsStandalone

on revIDEPrintPageSetup
   answer page setup
end revIDEPrintPageSetup

on revIDEPrintCurrentCard
   local tResult
   set the defaultStack to the topstack
   answer printer
   put the result into tResult
   if tResult is not "cancel" then
      open printing
      print this card
      close printing
   end if
end revIDEPrintCurrentCard

on revIDEPrintField pFieldID
   if not exists(pFieldID) then exit revIDEPrintField
   local tStackName, tLabel
   put revIDEStackOfObject(pFieldID) into tStackName
   put the label of stack tStackName into tLabel
   if tLabel is not empty then
      set the printTitle to tLabel
   else
      set the printTitle to tStackName
   end if
   
   revShowPrintDialog false,true
   revPrintField line 1 of pFieldID
end revIDEPrintField

on revIDEUndo
   # Check the IDE undo list (cached object rects)
   global gRevUndoList
   if gREVUndoList is not empty then
      # If it is not empty, restore all the objects' rects
      if line -1 of gREVUndoList is "width" then
         delete last line of gREVUndoList

         local tObject
         repeat for each line tLine in gREVUndoList
            put item 1 to -2 of tLine into tObject
            if there is a tObject then
               set the width of tObject to item -1 of tLine
            end if
            send "revCacheGeometry true" to tObject
         end repeat
      else if line -1 of gREVUndoList is "height" then
         delete last line of gREVUndoList
         repeat for each line l in gREVUndoList
            put item 1 to -2 of l into tObject
            if there is a tObject then set the height of tObject to item -1 of l
            send "revCacheGeometry true" to tObject
         end repeat
      else if line -1 of gREVUndoList is "rect" then
         delete last line of gREVUndoList
         repeat for each line l in gREVUndoList
            put item 1 to -5 of l into tObject
            if there is a tObject then set the rect of tObject to item -4 to -1 of l
            send "revCacheGeometry true" to tObject
         end repeat
      end if
      put empty into gREVUndoList
   else
      # Otherwise just use engine undo, and cache all the selected object rects
      undo
      repeat for each line l in the selObj
         send "revCacheGeometry true" to l
      end repeat
   end if

   # The selected object may change after undo
   revIDEMessageSend "ideSelectedObjectChanged"
end revIDEUndo

on revIDECut
   # Don't try and cut from a field with lockText true
   if the selectedField is not empty and the lockText of the selectedField then
      exit revIDECut
   end if
   
   lock screen
   lock messages
   if the selectedImage is not empty then
      # If the there is a selection in an image using the image selection tool
      # Then make sure no text is selected before doing the cut
      if the selectedText is not empty then select empty
      set the defaultStack to revTargetStack(the long id of the selectedImage)
      cut
      exit revIDECut
   end if
   
   # Ensure the user is aware of the consequences of the cut wrt groups
   if revCheckGroupDelete() then
      cut
   end if
   unlock messages
   unlock screen
   
   revIDEMessageSend "ideSelectedObjectChanged"
end revIDECut

on revIDECutText pTextChunk
   select pTextChunk
   revIDECut
end revIDECutText

on revIDECutObjects pObjectList
   revIDESelectObjects pObjectList
   revIDECut
end revIDECutObjects

on revIDECopy
   # If the there is a selection in an image using the image selection tool
   # Then make sure no text is selected before doing the copy
   if the selectedImage is not empty then
      if the selectedText is not empty then
         select empty
      end if
      set the defaultStack to revTargetStack(the long id of the selectedImage)
   end if
   copy
end revIDECopy

on revIDECopyText pTextChunk
   select pTextChunk
   revIDECopy
end revIDECopyText

on revIDECopyObjects pObjectList
   revIDESelectObjects pObjectList
   revIDECopy
end revIDECopyObjects

on revIDEPaste
   lock messages
   set the defaultStack to the topStack
   # Can't paste onto an IDE stack or a stack with cantModify set to true
   if the clipBoard is not text and (the mode of the topStack is not 1 or the cantModify of the topStack) then
      beep
      exit revIDEPaste
   end if
   
   
   # If we have image data in the clipboard but there is no image selection
   # the create a new image object and set the imageData
   if the clipBoard is "image" and the selectedImage is empty then
      lock messages
      lock screen
      create image
      put the clipBoardData["image"] into last image
      unlock messages
      unlock screen
      local tObjects
      put true into tObjects
      choose pointer tool
      select last image
   else
      -- MW-2012-02-10: [[ Bug ]] Make sure the IDE doesn't interfere with the textChanged
      --   message.
      unlock messages
      lock screen
      paste
      unlock screen
      lock messages
   end if
   
   # If objects have been pasted, assign them IDs for geometry caching
   if the clipBoard is "objects" or tObjects then
      local tMilliseconds
      put the milliseconds into tMilliseconds
      repeat for each line l in the selObj
         set the cREVGeneral["revUniqueID"] of l to tMilliseconds
         add 1 to tMilliseconds
      end repeat
   end if
   unlock messages
   
   # Pasting an object will cause the selection to change
   if the clipboard is "objects" or tObjects then
      revIDEMessageSend "ideSelectedObjectChanged"
   end if
end revIDEPaste

on revIDEPasteOntoStack pStack
   if not pStack begins with "stack" then
      exit revIDEPasteOntoStack
   end if
   
   lock screen
   lock messages
   set the defaultStack to pStack
   paste
   unlock messages
   unlock screen
end revIDEPasteOntoStack

on revIDEActionPasteUnformatted
   put the clipBoardData["text"] into the selection
end revIDEActionPasteUnformatted

on revIDEActionClearObjects pObjects
   revIDESelectObjects pObjects
   revIDEActionClear
end revIDEActionClearObjects

function revIDECheckClear pObjectList
   local tNames, tWarning
   put empty into tNames
   repeat for each line tControl in pObjectList
      if word 1 of tControl is "group" and the number of lines in the cardNames of tControl > 1 then
         answer warning "This group is placed on multiple cards," & cr & "really delete it?" with "Yes" or "No"
         if it is "No" then return false
      end if
      if word 1 of tControl is "group" and the dgProps["control type"] of tControl is "Data Grid" then
         answer warning "Would you like to delete the record template associated with this data grid? This action cannot be undone." with "Yes" or "No"
         if it is "Yes" then 
            local tTemplate
            put the dgProps["row template"] of tControl into tTemplate
            
            local tCardWord
            put wordoffset("card",tTemplate) into tCardWord
            
            local tTemplateCard
            put word tCardWord to -1 of tTemplate into tTemplateCard
            
            local tStackWord
            put wordoffset("stack",tTemplate) into tStackWord
            
            local tTemplateStack
            put word tStackWord to -1 of tTemplate into tTemplateStack
            if the number of cards in stack tTemplateStack is 2 then delete stack tTemplateStack
            else 
               delete tTemplateCard
            end if
         end if
      end if
      
      put the name of tControl & cr after tNames
   end repeat
   delete last char of tNames
   put "Are you sure you want to delete the following controls?" & cr & cr & tNames into tWarning
   answer warning tWarning with "No" or "Yes"
   return the result is "Yes"
end revIDECheckClear

on revIDEActionClear
   lock screen
   lock messages
   # Clear the selection in image selection context
   if the selectedImage is not empty then
      set the defaultStack to revTargetStack(the long id of the selectedImage)
      delete
      exit revIDEActionClear
   end if
   
   # Can't clear locked text
   if the selectedField is not empty and the lockText of the selectedField then
      exit revIDEActionClear
   end if
   
   # Otherwise delete objects or text
   set the defaultStack to the topStack
   delete
   
   unlock messages
   revIDEMessageSend "ideSelectedObjectChanged"
   unlock screen
end revIDEActionClear

on revIDEActionDuplicate
   lock screen
   if the selObj is not empty then
      set the defaultStack to revIDEStackOfObject(line 1 of (the selobj))

      # OK-2007-07-31 : Bug 4917. Instead of assuming that the duplicated controls will have the highest layer
      # numbers, we make certain that we select the correct objects by saving a list of each newly created control
      local tCreatedObjects, tID
      put the milliseconds into tID
      repeat for each line tObject in the selObj
         clone tObject
         put the long id of it & return after tCreatedObjects

         if the right of last control > the right of this cd or the bottom of last control > the bottom of this cd then
            set the topLeft of the last control to 10, 10
         end if
         if word 1 of the name of tObject is not "group" then
            set the cREVGeneral["revUniqueID"] of last control to tID
            add 1 to tID
         else
            set the cREVGeneral["revUniqueID"] of last control to tID
            add 1 to tID

            repeat with tGroupedControl = 1 to the number of controls of the last group
               set the cREVGeneral["revUniqueID"] of control tGroupedControl of the last group to tID
               add 1 to tID
            end repeat
         end if
      end repeat
      select empty

      repeat for each line tCreatedObject in tCreatedObjects
         set the selected of tCreatedObject to true
      end repeat

      revIDEMessageSend "ideSelectedObjectChanged"
   end if
   unlock screen
end revIDEActionDuplicate

on revIDEDuplicateCard
   clone this card
end revIDEDuplicateCard

on revIDESelectAll
   # Can't select all objects on IDE stacks, but can in theory select text
   if the mode of the topStack is not 1 and the selectedField is empty then
      beep
      exit revIDESelectAll
   end if

   # In image selection context, select all creates a selection around the entire rect of the image
   if the selectedImage is not empty then
      lock screen
      set the defaultStack to revTargetStack(the long id of the selectedImage)
      local tRect
      put the rect of the selectedImage into tRect
      choose select tool
      drag from item 1 to 2 of tRect to item 3 to 4 of tRect
      unlock screen
      exit revIDESelectAll
   end if

   # In text selection context, ensure the target field is the focused one
   if the selectedField is not empty \
         and revTargetStack(the focusedObject) is revTargetStack(the long id of the selectedField) then
      if the lockText of the selectedField then exit to top
      select text of the selectedField
   else
      if the cantModify of the topStack then
         answer "This stack can't be modified"
         exit to top
      end if
      if the tool is not "pointer tool" then
         beep
         exit revIDESelectAll
      end if

      # Select all objects that can be selected
      lock screen
      lock messages
      set the defaultStack to the topStack
      repeat with i = 1 to the number of layers
         if the visible of control i or the showInvisibles then
            if not the cantSelect of control i then
               if the selectGroupedControls and (word 1 of the name of control i is "group" and the selectGroupedControls of control i is true) then
                  if word 1 of the name of control i is not "group" then
                     set the selected of control i to true
                  end if
               else
                  set the selected of control i to true
                  add the number of layers in control i to i
               end if
            else
               add the number of layers in control i to i
            end if
         end if
      end repeat
      unlock screen
      unlock messages
      revIDEMessageSend "ideSelectedObjectChanged"
   end if
end revIDESelectAll

on revIDEDeselectAll
   select empty
   revIDEMessageSend "ideSelectedObjectChanged"
end revIDEDeselectAll

on revIDEInvertObjectSelection
   # Can't select objects on IDE stacks
   if the mode of the topStack is not 1 then
      beep
      exit reviDEInvertObjectSelection
   end if
   lock screen
   lock messages
   set the defaultStack to the topStack
   repeat with i = 1 to the number of controls
      if (the visible of control i or the showInvisibles) and (not the selectGroupedControls or (the selectGroupedControls and word 1 of the name of control i is not "group")) then
         set the selected of control i to not the selected of control i
      end if
      if not the selectGroupedControls then add the number of layers in control i to i
   end repeat
   unlock screen
   unlock messages
   revIDEMessageSend "ideSelectedObjectChanged"
end revIDEInvertObjectSelection

on revIDEChooseBrowseTool
   revIDESetTool "browse"
end revIDEChooseBrowseTool

on revIDEChoosePointerTool
   revIDESetTool "pointer"
end revIDEChoosePointerTool

on revIDEStyleText pWhich, pValue
   local tSelectedObject, tSelectedChunk, tTarget, tTargetStack, tFieldVScrollPosition, tFieldHScrollPosition,

   if the selectedChunk is empty and the selectedObject is empty then
      exit revIDEStyleText
   end if

   if the selectedfield is not empty then
      put the long ID of the selectedField into tSelectedObject
      put the vScroll of the selectedfield into tFieldVScrollPosition
      put the hScroll of the selectedfield into tFieldHScrollPosition
      if the selectedChunk is not empty then
         put the selectedChunk into tSelectedChunk
         put word 1 to 4 of tSelectedChunk & " " & tSelectedObject into tTarget
      end if
   else
      put the long ID of the selectedObject into tSelectedObject
      put tSelectedObject into tTarget
   end if
   put revIDEStackOfObject(tSelectedObject) into tTargetStack
   // We need to ignore actions that are performed on LiveCode palettes unless specifically allowed
   if revOKTarget(tTargetStack) then
      // Add IDE Exception here that are allowed to have their text manipulated
      if the short name of tSelectedObject is not among the words of "htmltext" then
         exit revIDEStyleText
      end if
   end if

   switch pWhich
      case "plain"
         set the textStyle of tTarget to empty
         break
      case "bold"
      case "italic"
      case "underline"
      case "strikeout"
      case "box"
      case "link"
      case "condensed"
      case "expanded"
      case "threeDbox"
         if the textStyle[pWhich] of tTarget is true then
            set the textStyle[pWhich] of tTarget to false
         else
            set the textStyle[pWhich] of tTarget to true
         end if
         break

      case "subscript"
      case "superscript"
         local tTextShiftAmount

         if pWhich is "superscript" then put -4 into tTextShiftAmount
         else put 4 into tTextShiftAmount
         if the textShift of tTarget is a number then put 0 into tTextShiftAmount

         set the textShift of tTarget to tTextShiftAmount
         break
      case "font"
         if pValue is "Use Owner's Font" then set the textFont of tTarget to empty
         else set the textFont of tTarget to pValue
         break
      case "size"
         if pValue is "Use Owner's Size" then
            set the textSize of tTarget to empty
         else if pValue is a number then
            set textSize of tTarget to pValue
         else if pValue is "Other..." then
            ask "Choose the text size"
            if it is empty then
               exit revIDEStyleText
            else
               set textSize of tTarget to it
            end if
         end if
         break
      case "color"
         if pValue is "Use Owner's Color" then set the textColor of tTarget to empty
         else if pValue is "Pen Color" then set textColor of tTarget to the penColor
         else set textColor of tTarget to pValue
         break
      case "align"
         // If there is a selection we want to sent the alignment of the paragraph(s) in question
         if the selectedChunk is not empty then
            local tStartChar, tEndChar, tStartPara, tEndPara, tParaFirstChar, tParaLastChar
            put word 2 of the selectedChunk into tStartChar
            put word 4 of the selectedChunk into tEndChar
            put return & "Start / End: " & tStartChar && tEndChar after msg

            put tStartChar && tEndChar
            put the lineIndex of char tStartChar of tTarget into tStartPara
            put the lineIndex of char tEndChar of tTarget into tEndPara
            put return & "Paras: " & tStartPara & " to " & tEndPara after msg

            repeat with x = tStartPara to tEndPara
               put the charindex of line x of tTarget into tParaFirstChar
               put the charindex of line x of tTarget + the length of line x of tTarget - 1 into tParaLastChar
               set the textAlign of char tParaFirstChar to tParaLastChar of tTarget to pValue
               put return & "Para "&x&": char " & tParaFirstChar & " to " & tParaLastChar after msg
            end repeat

         else
            set textAlign of tTarget to pValue
         end if
         break
   end switch

   if the selectedfield is not empty then
      set the vScroll of the selectedfield to tFieldVScrollPosition
      set the hScroll of the selectedfield to tFieldHScrollPosition
   end if
end revIDEStyleText

on revIDEStyleTextPlain
   revIDEStyleText "plain"
end revIDEStyleTextPlain

on revIDEStyleTextBold
      revIDEStyleText "bold"
end revIDEStyleTextBold

on revIDEStyleTextItalic
      revIDEStyleText "italic"
end revIDEStyleTextItalic

on revIDEStyleTextUnderline
      revIDEStyleText "underline"
end revIDEStyleTextUnderline

on revIDEStyleTextStrikeOut
      revIDEStyleText "strikeout"
end revIDEStyleTextStrikeOut

on revIDEStyleTextBox
      revIDEStyleText "box"
end revIDEStyleTextBox

on revIDEStyleText3DBox
      revIDEStyleText "threedbox"
end revIDEStyleText3DBox

on revIDEStyleTextLink
      revIDEStyleText "link"
end revIDEStyleTextLink

on revIDEStyleTextSubscript
      revIDEStyleText "subscript"
end revIDEStyleTextSubscript

on revIDEStyleTextSuperscript
      revIDEStyleText "superscript"
end revIDEStyleTextSuperscript

on revIDESetTextFont pFont
      revIDEStyleText "font", pFont
end revIDESetTextFont

on revIDESetTextSize pSize
      revIDEStyleText "size", pSize
end revIDESetTextSize

on revIDESetTextColor pColor
      revIDEStyleText "color", pColor
end revIDESetTextColor

on revIDESetTextAlign pAlign
      revIDEStyleText "align", pAlign
end revIDESetTextAlign

on revIDEActionClearAllBreakpoints
   answer warning "Really clear all breakpoints from all open stacks?  This operation cannot be undone." with "Don't Clear" or "Clear"
   if it is "Clear" then 
      revDebuggerClearAllBreakpoints
   end if
end revIDEActionClearAllBreakpoints

function revIDETestTargets
   return revIDEDeployListTargets()
end revIDETestTargets

function revIDETestTarget
   return revIDEDeployGetTarget()
end revIDETestTarget

function revIDETestCanDeployToTarget pTarget
   return revIDEDeployIsPossible(pTarget)
end revIDETestCanDeployToTarget

on revIDESetTestTarget pTarget

end revIDESetTestTarget

on revIDEDeployStack pStackID

end revIDEDeployStack
   revIDEDeploySetTarget pTarget
end revIDESetTestTarget

on revIDEActionTest
   revIDEDeployAction
end revIDEActionTest

local sRestoreState
on revIDEToggle pProperty
   local tToggleMessage
   switch pProperty
      case "Suppress Messages"
         global gRevSuppressMessages
         put "suppressMessages" into tToggleMessage
         if not gREVSuppressMessages then
            put true into gREVSuppressMessages
            # Send the suppress messages toggle message before actually suppressing messages
            revIDEMessageSend "ideToggleChanged:" & tToggleMessage
            set the lockCursor to false
            repeat for each line l in the pendingMessages
               if char 1 to 3 of item 2 of l is not "rev" then cancel (item 1 of l)
            end repeat
            repeat for each line l in the frontScripts
               if char 1 to 3 of the short name of l is not "rev" then
                  put l & cr after sRestoreState["front"]
                  remove script of l from front
               end if
            end repeat
            repeat for each line l in the backScripts
               if char 1 to 3 of the short name of l is not "rev" then
                  put l & cr after sRestoreState["back"]
                  remove script of l from back
               end if
            end repeat
            repeat for each line l in the stacksInUse
               if char 1 to 3 of l is not "rev" then
                  put l & cr after sRestoreState["inUse"]
                  stop using stack l
               end if
            end repeat
            revInternal__LoadLibrary "revNoMessagesLibrary"
            exit revIDEToggle
         else
            revInternal__UnloadLibrary "revNoMessagesLibrary"
            put false into gREVSuppressMessages
            repeat for each line l in sRestoreState["front"]
               insert script of l into front
            end repeat
            repeat for each line l in sRestoreState["back"]
               insert script of l into back
            end repeat
            repeat for each line l in sRestoreState["inUse"]
               start using stack l
            end repeat
            delete variable sRestoreState
         end if
         break
      case "Suppress Errors"
         global gRevSuppressErrors
         if not gREVSuppressErrors or gREVSuppressErrors is empty then
            put true into gREVSuppressErrors
         else
            put false into gREVSuppressErrors
         end if
         put "suppressErrors" into tToggleMessage
         break
      case "Select Grouped Controls"
         set the selectGroupedControls to not (the selectGroupedControls)
         if the selectGroupedControls and word 1 of (the selObj) is "group" then
            select empty
            revIDEMessageSend "ideSelectedObjectChanged"
         end if
         put "selectGrouped" into tToggleMessage
         break
      case "Intersected Selections"
         if the selectionMode is "intersect" then
            set the selectionMode to "surround"
         else
            set the selectionMode to "intersect"
         end if
         put "selectionMode" into tToggleMessage
         break
      case "Script Debug Mode"
         if revDebuggerEnabled() then
            revDebuggerDisable
         else
            revDebuggerEnable
         end if
         
         # OK-2010-01-18: Update any open script editors so that the breakpoints are shown correctly,
         # they should all be grey when script debug mode is off, otherwise their color depends on their
         # exact circumstances.
         local tPrefsChanged
         put false into tPrefsChanged
         send "revSEUpdateEditors tPrefsChanged" to revScriptEditorMain()
         
         put "scriptDebugMode" into tToggleMessage
         break
      case "Show IDE Stacks In Lists"
         put "ideStacksInLists" into tToggleMessage
         revIDEToggleShowIDEStacksInLists
         break
      case "Show Invisible Objects"
         put "showInvisibles" into tToggleMessage
         set the showInvisibles to not (the showInvisibles)
         break
      case "Rulers"
         put "rulers" into tToggleMessage
         if the mode of stack "revRulersH" is not 0 then
            revInternal__UnloadLibrary "revRulersScript"
            lock messages
            close stack "revRulersH"
            close stack "revRulersV"
            unlock messages
         else
            lock messages
            revCalculateRulers
            if the mode of the topStack is 1 then
               palette "revRulersH"
               palette "revRulersV"
            end if
            unlock messages
         end if
         break
      case "Backdrop"
         if the backDrop is "none" then
            if revIDGetPreference("cBackDropColor") is empty then 
               revIDESetPreference "cBackDropColor", "black"
            end if
            set the backDrop to revIDGetPreference("cBackDropColor")
            revIDESetPreference "cBackDrop", the backDrop
         else
            set the backDrop to "none"
            revIDESetPreference "cBackDrop", "none"
         end if
         # No need to send toggle message as idePreferenceChanged will be sent
         exit revIDEToggle
      case "Grid"
         if the grid is false then
            set the grid to true
            revIDESetPreference "cGrid", true
         else
            set the grid to false
            revIDESetPreference "cGrid", false
         end if
         # No need to send toggle message as idePreferenceChanged will be sent
         exit revIDEToggle
   end switch
   # Invisible objects
   # Ruler
   revIDEMessageSend "ideToggleChanged:" & tToggleMessage
end revIDEToggle

on revIDEToggleToolbar pWhich
   local tCurrentPref
   if pWhich is "Toolbar Text" then
      put revIDEGetPreference("cToolbarText") is true into tCurrentPref
      revIDESetPreference "cToolbarText", not tCurrentPref
   else if pWhich is "Toolbar Icons" then
      put revIDEGetPreference("cToolbarIcons") is true into tCurrentPref
      revIDESetPreference "cToolbarIcons", not tCurrentPref
   end if
end revIDEToggleToolbar

on revIDEToggleShowIDEStacksInLists
   global gREvShowStacks
   lock screen
   set the hilite of button "show revolution stacks" of card "general" of stack "revPreferencesGUI" to not gREVShowStacks
   
   local tOpenStacks
   put the openStacks into tOpenStacks
   
   local tFrontStack
   put empty into tFrontStack
   repeat for each line tStack in tOpenStacks
      if tStack is not "revMenubar" and the mode of stack tStack is among the items of "1,2,3" then
         put tStack into tFrontStack
         exit repeat
      end if
   end repeat
   if tFrontStack is not empty then
      set the wholeMatches to true
      local tBringToFront
      if lineOffset(tFrontStack, tOpenStacks) < lineOffset("revApplicationOverview", tOpenStacks) then
         put true into tBringToFront
      end if
   end if
   send "revToggleShowStacks" to button "show revolution stacks" of card "general" of stack "revPreferencesGUI"
   unlock screen
   
   if tBringToFront then
      lock messages
      switch the mode of stack tFrontStack
         case 1
         case 2
            toplevel tFrontStack
            break
         case 3
            modeless tFrontStack
            break
      end switch
      unlock messages 
   end if
end revIDEToggleShowIDEStacksInLists

on revIDETogglePalette pPaletteName
   local tStackName
   put revIDEPaletteToStackName(pPaletteName) into tStackName

   if the mode of stack tStackName is 0 then
      revIDEOpenPalette pPaletteName
   else
      close stack tStackName
   end if
end revIDETogglePalette

on revIDETogglePaintAndDrawTools
   local tToolsOnShow
   put revIDEGetPreference("revTools_show") into tToolsOnShow
   if "paint" is among the items of tToolsOnShow then
      delete item itemoffset("paint", tToolsOnShow) of tToolsOnShow
   else
      if tToolsOnShow is empty then
         put "paint" into tToolsOnShow
      else
         put comma & "paint" after tToolsOnShow
      end if
   end if
   revIDESetPreference "revTools_show", tToolsOnShow
end revIDETogglePaintAndDrawTools

function revIDEAvailablePaletteState
   # return palette name & visibility
   local tState
   repeat for each item tPalette in revIDEAvailablePalettes()
      if tState is empty then
         put tPalette & comma & revIDEPaletteIsVisible(tPalette) into tState
      else
         put return & tPalette & comma & revIDEPaletteIsVisible(tPalette) after tState
      end if
   end repeat
   return tState
end revIDEAvailablePaletteState

function revIDEOpenWindows

end revIDEOpenWindows

on revIDESendWindowToBack

end revIDESendWindowToBack

on revIDEDocumentationLoad pSection, pItem, pExtra
   # For now, just open the dictionary
   revIDEOpenPalette "dictionary"
end revIDEDocumentationLoad

on revIDELaunchResource pName
   switch pName
      case "Buy"
         launch url "http://www.runrev.com/links/livecode/tools-buy"
         break
      case "Support"
         launch url "http://www.runrev.com/links/livecode/tools-help"
         break
      case "License Agreement"
         launch document (revEnvironmentToolsPath() & slash & "License Agreement.txt")
         break
      case "Release Notes"
         launch document (revEnvironmentToolsPath() & slash & "Release Notes.pdf")
         break
      case "User Guide"
         launch document revEnvironmentDocumentationPath() & "/pdf/LiveCode User Guide.pdf"
         break
      case "Sample Stacks"
         launch url "http://livecode.com/links/livecode/revonline"
         break
      case "Sample Scripts"
         launch url "http://lessons.runrev.com/m/2592"
         break
      case "Beginners Guide"
         launch url "http://livecode.com/links/livecode/beginners-course"
         break
      case "Tutorials"
         launch url "http://livecode.com/links/livecode/tutorials"
         break
      case "All Guides"
         launch url "http://livecode.com/links/livecode/guides"
         break
      case "Forums"
         launch url "http://livecode.com/links/livecode/forum"
         break
      case "Technical Questions"
         launch url "http://livecode.com/links/stackoverflow"
         break
      case "Use List"
         launch url "http://livecode.com/links/lists"
         break
      case "Newsletters"
         launch url "http://livecode.com/links/livecode/newsletters"
         break
      case "Resources"
         launch document revEnvironmentToolsPath() & slash & "Resources"
         break
   end switch
end revIDELaunchResource

on revIDEActionRelicense
   answer question "Are you sure you want to re-license? Clicking " & quote & "Ok" & quote & " will restart LiveCode and you will be asked re-activate." with "Cancel" or "OK"
   if it is "OK" then
      revIDERelicense
   end if
end revIDEActionRelicense

on revIDERelicense
   revReLicense
end revIDERelicense

on revIDEQuit
   quit
end revIDEQuit

on revIDEErrorDialog pExecutionError, pScriptError
   set the executionError of stack "revErrorDisplay" to pExecutionError
   set the scriptError of stack "revErrorDisplay" to pScriptError
   local tObject
   put empty into tObject
   repeat for each line l in pExecutionError
      if item 1 of l is 353 then
         put item -1 of l into tObject
         exit repeat
      end if
   end repeat
   if tObject is empty then
      put the long id of the target into tObject
   end if
   set the errorObject of stack "revErrorDisplay" to tObject
   if the mode of stack "revErrorDisplay" is not 0 then
      send "openStack" to stack "revErrorDisplay"
      send "preOpenCard" to stack "revErrorDisplay"
      send "opencard" to stack "revErrorDisplay"
   else
      modeless "revErrorDisplay"
   end if
end revIDEErrorDialog

on revIDEToggleLockLocationOfObjects pObjects
   repeat for each line tObject in pObjects
      set the lockLoc of tObject to not (the lockLoc of tObject)
   end repeat
end revIDEToggleLockLocationOfObjects

on revIDEActionEditGroup
   revIDEEditGroup the selobj
end revIDEActionEditGroup

on revIDEEditGroup pGroup
   if word 1 of pGroup is "group" then
      if revMenuManagerGroup(pGroup) then
         answer error "Can't edit group that is in use by the Menu Manager.  To edit this group close the Menu Manager."
         exit revIDEEditGroup
      end if
      start editing pGroup
   else if the editBg then
      set the editBg to false
   end if
end revIDEEditGroup

on revIDEStopEditingGroup
   stop editing
end revIDEStopEditingGroup

on revIDEPasteIntoGroup pGroup
   lock screen
   start editing pGroup
   choose pointer tool
   set the defaultStack to the topStack
   paste
   stop editing
   unlock screen
end revIDEPasteIntoGroup

on revIDEEditImage pImages
   # Make sure we have an image
   if word 1 of pImages is not "image" then
      exit revIDEEditImage
   end if
   local tImageEditor
   put revIDEGetPreference("cEditorPath") into tImageEditor
   
   local tAppExists
   put false into tAppExists
   if there is a file tImageEditor then
      put true into tAppExists
   else if the platform is "macos" and there is a folder tImageEditor then
      put true into tAppExists
   end if
   
   if tImageEditor is empty or not tAppExists then
      answer warning "You haven't selected an external image editor application, or I couldn't find the editor selected.  Would you like to select one?  (Note the editor you select must be able to handle PNG format images.)" with "Cancel" or "Select now"
      if it is "Cancel" then exit revIDEEditImage
      if it is "select now" then
         if the platform is "MacOS"
         then answer file "Select an image editor:" with filter "APPL"
         else answer file "Select an image editor:"
         if it is empty then exit revIDEEditImage
         put it into tImageEditor
         revIDESetPreference "cEditorPath", tImageEditor
      end if
   end if
   
   set the defaultStack to the topStack	

   local tNumber, tImagePath
   repeat for each line tImage in pImages
      put the number of tImage into tNumber
      if the fileName of image tNumber is not empty then
         put the fileName of image tNumber into tImagePath
         local tEditFileName
         put true into tEditFileName
      else
         local tReturn 
         put the fileType into tReturn
         set the fileType to "PNGf????"
         try
            export image tNumber to file "temp" & tNumber & ".png" as png
         catch tError
            answer error line (item 1 of line 1 of tError) of the cErrorsList \
                  of cd 1 of stack "revErrorDisplay"
            exit revIDEEditImage
         end try
         set the fileType to tReturn
         put the directory & "/" & ("temp" & tNumber & ".png") into tImagePath
      end if
      
      if tImageEditor is among the lines of the openProcesses then 
         kill process tImageEditor
      end if
      launch tImagePath with tImageEditor
      if the result is not empty then
         answer error "There was a problem launching the editor." & cr & the result with "Cancel"
         exit revIDEEditImage
      end if
   end repeat
   
   if tEditFileName then  
      answer "Now launching image editor.  Use the editor to make changes to the image, then save the image and close the editor."
      else 
         answer "Now launching image editor.  Use the editor to make changes to the image, then save the image and close the editor.  Then click Update to update the image." with "Cancel" or "Update"
      end if
      
      if it is "OK" then
         repeat for each line tImage in pImages
            put the number of tImage into tNumber
            
            local tFileName
            put the fileName of image tNumber into tFileName
            set the fileName of image tNumber to empty
            set the fileName of image tNumber to tFileName
         end repeat
         exit revIDEEditImage
      end if
      if it is "cancel" then
         repeat for each line tImage in pImages
            put the number of tImage into tNumber
            delete file ("temp" & tNumber & ".png")
         end repeat
      else
         repeat for each line tImage in pImages
            put the number of tImage into tNumber
            put URL ("binfile:" & ("temp" & tNumber & ".png")) into image tNumber
            delete file ("temp" & tNumber & ".png")
         end repeat
      end if
end revIDEEditImage

on revIDEToggleMagnifyOfImage pImage
   # Make sure we have an image
   if word 1 of pImage is not "image" then
      exit revIDEToggleMagnifyOfImage
   end if
   
   set the magnify of pImage to not (the magnify of pImage)
   if the magnify of pImage then
      if the tool is "pointer tool" or the tool is "browse tool" then 
         revIDESetTool "select tool"
      end if
   end if
end revIDEToggleMagnifyOfImage

on revIDEMakeImageOriginalSize pImage
   # Make sure we have an image
   if word 1 of pImage is not "image" then
      exit revIDEMakeImageOriginalSize
   end if
   
   set the width of pImage to the formattedWidth of pImage
   set the height of pImage to the formattedHeight of pImage
end revIDEMakeImageOriginalSize

on revIDEActionPasteTextIntoField pField
   # Make sure we have an field
   if word 1 of pField is not "field" then
      exit revIDEActionPasteTextIntoField
   end if
   lock screen
   lock messages
   local tLockText, tTraversalOn
   put the lockText of pField into tLockText
   put the traversalOn of pField into tTraversalOn
   set the lockText of pField to false
   set the traversalOn of pField to true
   if the selection is not empty and the long id of the selectedField is pField then
      paste
   else
      select after text of pField
      paste
   end if
   set the lockText of pField to tLockText
   set the traversalOn of pField to tTraversalOn
   unlock messages
   unlock screen
end revIDEActionPasteTextIntoField

on revIDEToggleTraversalOnOfField pField
   # Make sure we have an field
   if word 1 of pField is not "field" then
      exit revIDEToggleTraversalOnOfField
   end if
   
   set the traversalOn of pField to not (the traversalOn of pField)
end revIDEToggleTraversalOnOfField

on revIDEStartPlayingPlayer pPlayer
   # Make sure we have an player
   if word 1 of pPlayer is not "player" then
      exit revIDEStartPlayingPlayer
   end if
   
   start playing pPlayer 
end revIDEStartPlayingPlayer

on revIDEStopPlayingPlayer pPlayer
   # Make sure we have an player
   if word 1 of pPlayer is not "player" then
      exit revIDEStopPlayingPlayer
   end if
   
   stop playing pPlayer 
end revIDEStopPlayingPlayer

on revIDETogglePausedOfPlayer pPlayer
   # Make sure we have an player
   if word 1 of pPlayer is not "player" then
      exit revIDETogglePausedOfPlayer
   end if

   set the paused of pPlayer to not the paused of pPlayer
end revIDETogglePausedOfPlayer

on revIDESendMessageToObject pMessage, pTarget
   # Make sure message is not handled by a frontscript
   local tScriptsList
   put the frontScripts into tScriptsList
   
   local tRemoveFrontList
   repeat for each line tScript in tScriptsList
      if char 1 to 3 of the short name of tScript is "rev" and the short name of tScript is not "revDebugger" then
         if tRemoveFrontList is empty then
            put tScript into tRemoveFrontList
         else
            put return & tScript after tRemoveFrontList
         end if
         remove script of tScript from front
      end if
   end repeat

   send pMessage to pTarget 
   
   # Restore frontscripts
   repeat for each line tScript in tRemoveFrontList
      insert script of tScript into front
   end repeat
end revIDESendMessageToObject

on revIDEActionInspectCard
   revIDEOpenInspectorForObjects the long id of this card of the topStack
end revIDEActionInspectCard

on revIDEActionInspectStack
   revIDEOpenInspectorForObjects the topStack
end revIDEActionInspectStack

on revIDEActionEditScriptOfObjects
   revIDEEditScriptOfObjects the selobj
end revIDEActionEditScriptOfObjects

on revIDEActionEditScriptOfCard
   revIDEEditscriptOfObject the long ID of this card of the topstack
end revIDEActionEditScriptOfCard

on revIDEActionEditScriptOfStack
   revIDEEditScriptOfObject the topStack
end revIDEActionEditScriptOfStack

/*
Returns an array with keys the object types and values the corresponding 'kinds'
*/
function revIDEAvailableControls
   local tObjectsA, tType, tTitle
   repeat for each key tTypeID in sClassicObjectProperties
      put sClassicObjectProperties[tTypeID]["type"] into tType
      if tType is "card" or tType is "stack" or tType is "group" then
         next repeat
      end if
      put sClassicObjectProperties[tTypeID]["title"] into tTitle
      if tTitle is empty then
         next repeat
      end if
      put tTypeID into tObjectsA[tTitle]["kind"]
      put tType into tObjectsA[tTitle]["type"]
   end repeat
   return tObjectsA
end revIDEAvailableControls

function revIDEAvailableWidgets
   local tWidgetsA, tType, tTitle, tDataA
   put revIDEExtensions("widget", "installed") into tDataA
   repeat for each key tTypeID in tDataA
      put tDataA[tTypeID]["title"] into tTitle
      if tTitle is empty then
         next repeat
      end if
      put tTypeID into tWidgetsA[tTitle]["kind"]
   end repeat 
   return tWidgetsA
end revIDEAvailableWidgets

on revIDEToggleReshapeGraphic
   if "revReshapeLibrary" is not among the lines of revInternal__ListLoadedLibraries() then
      choose pointer tool
      revInternal__LoadLibrary "revReshapeLibrary"
      revSetMarkers
   else
      revSetMarkers true
      revInternal__UnloadLibrary "revReshapeLibrary"
   end if
end revIDEToggleReshapeGraphic

on revIDEPlaceGroupOnCard pGroup
   # OK-2009-10-02 : Code was breaking with groups named "Background", and seemed to be overcomplicated.
   set the defaultStack to the topStack
   if pGroup is not empty then
      place background id pGroup onto this card
      if the tool is "pointer tool" then
         do ("select background id" & quote & pGroup & quote)
      end if
   end if
end revIDEPlaceGroupOnCard

on revIDEActionRemoveGroupFromCard
   set the defaultStack to the topStack
   
   if the editBg of this stack then
      answer error "This group is nested and cannot be removed separately from its owner group."
      exit revIDEActionRemoveGroupFromCard
   end if
   
   repeat for each line tObject in (the selobj)
      if word 1 of the owner of tObject is among the items of "background,group" then
         answer error "This group is nested and cannot be removed separately from its owner group."
         exit revIDEActionRemoveGroupFromCard
      end if
   end repeat
   
   repeat for each line tObject in (the selobj)
      if word 1 of tObject is "group" then
         remove tObject from this cd
      end if
   end repeat
end revIDEActionRemoveGroupFromCard

on revIDEActionAlign pAlignment
   revIDEAlignControls the selobj, pAlignment
end revIDEActionAlign

on revIDERelayerObjects pObjectList, pMode
   #maintain the layer order of the target objects
   local tObjectArray
   repeat for each line tObject in pObjectList
      put tObject into tObjectArray[the layer of tObject]    
   end repeat
   
   local tLayers
   put keys(tObjectArray) into tLayers
   
   local tRelayerGrouped
   put the relayerGroupedControls into tRelayerGrouped
   
   set the relayerGroupedControls to true
   switch pMode
      case "send to back"
         sort lines of tLayers numeric descending
         repeat for each line tLayer in tLayers
            set the layer of tObjectArray[tLayer] to bottom
         end repeat
         break
      case "bring to front"
         sort lines of tLayers numeric ascending
         repeat for each line tLayer in tLayers
            set the layer of tObjectArray[tLayer] to top
         end repeat
         break
      case "move forward"
         sort lines of tLayers numeric descending
         repeat for each line tLayer in tLayers
            set the layer of tObjectArray[tLayer] to tLayer +1 
         end repeat
         break
      case "move backward"
         sort lines of tLayers numeric ascending
         repeat for each line tLayer in tLayers
            set the layer of tObjectArray[tLayer] to tLayer -1 
         end repeat
         break
   end switch
   set the relayerGroupedControls to tRelayerGrouped
end revIDERelayerObjects

on revIDEActionSendToBack
   revIDESendToBack the selobj
end revIDEActionSendToBack

on revIDESendToBack pObjectList
   revIDERelayerObjects pObjectList, "send to back"
end revIDESendToBack

on revIDEActionBringToFront
   revIDEBringToFront the selobj
end revIDEActionBringToFront

on revIDEBringToFront pObjectList
   revIDERelayerObjects pObjectList, "bring to front"
end revIDEBringToFront

on revIDEActionMoveBackward
   revIDEMoveBackward the selobj
end revIDEActionMoveBackward

on revIDEMoveBackward pObjectList
   revIDERelayerObjects pObjectList, "move backward"
end revIDEMoveBackward

on revIDEActionMoveForward
   revIDEMoveForward the selobj
end revIDEActionMoveForward

on revIDEMoveForward pObjectList
   revIDERelayerObjects pObjectList, "move forward"
end revIDEMoveForward

on revIDEActionFlipImage pOrientation
   revIDEFlipImages the selobj, pOrientation
end revIDEActionFlipImage

on revIDEActionFlipGraphic pOrientation
   revIDEFlipGraphics the selobj, pOrientation
end revIDEActionFlipGraphic

on revIDEFlipGraphics pGraphics, pOrientation
   # Make sure targets are all graphics
   if not revIDEEnsureControlsOfType(pGraphics, "graphic") then
      exit revIDEFlipGraphics
   end if
   
   repeat for each line tGraphic in pGraphics
      local tPoints, tNewPoints
      put the points of tGraphic into tPoints
      
      if pOrientation is "Horizontal" then
         ## 2014-08-20 EJB [[Bug 13191]]
         --flip graphic horizontally
         local tLeft, tRight
         put the left of tGraphic into tLeft
         put the right of tGraphic into tRight
         
         repeat for each line tPoint in tPoints
            -- added BN in case a line is empty
            if tPoint is empty then
               put cr after tNewPoints
               next repeat
            end if
            
            put tLeft + tRight - item 1 of tPoint, item 2 of tPoint & cr after tNewPoints
         end repeat
      else
         --flip graphic vertically
         local tTop, tBottom
         put the top of tGraphic into tTop
         put the bottom of tGraphic into tBottom
         repeat for each line tPoint in tPoints
            -- added BN in case a line is empty
            if tPoint is empty then
               put cr after tNewPoints
               next repeat
            end if
            
            put item 1 of tPoint, tTop + tBottom - item 2 of tPoint & cr after tNewPoints
         end repeat
      end if
      set the points of tGraphic to tNewPoints
   end repeat
end revIDEFlipGraphics

on revIDEFlipImages pImages, pOrientation
   # Make sure targets are all images
   if not revIDEEnsureControlsOfType(pImages, "image") then
      exit revIDEFlipImages
   end if
   
   lock screen
   repeat for each line tImage in pImages
      if pOrientation is "Horizontal" then
         flip image id (the id of tImage) horizontal
      else
         flip image id (the id of tImage) vertical
      end if
   end repeat
   unlock screen
end revIDEFlipImages

on revIDEActionRotateImageBy
   modal "revRotate"
   if the cRotateImage of stack "revRotate" is empty then exit revIDEActionRotateImageBy
   
   local tRotateImage
   put the cRotateImage of stack "revRotate" into tRotateImage
   
   revIDEActionRotateImage tRotateImage
end revIDEActionRotateImageBy

on revIDEActionRotateImage pAngle
   revIDERotateImages the selobj, pAngle
end revIDEActionRotateImage

on revIDERotateImages pImages, pAngle
   # Make sure targets are all images
   if not revIDEEnsureControlsOfType(pImages, "image") then
      exit revIDERotateImages
   end if
   
   lock screen
   local tPreviousImageQualitySetting
   repeat for each line tImage in pImages
      put the resizeQuality of image id (the id of tImage) into tPreviousImageQualitySetting
      set the resizeQuality of image id (the id of tImage) to "best"
      rotate image id (the id of tImage) by pAngle
      set the resizeQuality of image id (the id of tImage) to tPreviousImageQualitySetting
   end repeat
   revIDESetTool "pointer"
   unlock screen
end revIDERotateImages

on revIDEActionRotateGraphicBy
   modal "revRotate"
   if the cRotateGraphic of stack "revRotate" is empty then exit revIDEActionRotateGraphicBy
   
   local tRotateGraphic
   put the cRotateGraphic of stack "revRotate" into tRotateGraphic
   
   revIDEActionRotateGraphic tRotateGraphic
end revIDEActionRotateGraphicBy

on revIDEActionRotateGraphic pAngle
   revIDERotateGraphics the selobj, pAngle
end revIDEActionRotateGraphic

on revIDERotateGraphics pGraphics, pAngle
   # Make sure targets are all graphics
   if not revIDEEnsureControlsOfType(pGraphics, "graphic") then
      exit revIDERotateGraphics
   end if
   
   lock screen
   repeat for each line tLine in pGraphics
      revRotatePoly tLine, pAngle
   end repeat
   revIDESetTool "pointer"
   unlock screen
end revIDERotateGraphics

function revIDEEnsureControlsOfType pControls, pType
   repeat for each line tControl in pControls
      if word 1 of tControl is not pType then
         return false
      end if
   end repeat
   return true
end revIDEEnsureControlsOfType

////////////////////////////////////////////////////////////////////////////////

# Parameters
#   pModeNumber : the value of the "mode" property of an open stack
# Returns
#   What style that mode corresponds to.
private function stackModeName pModeNumber
   switch pModeNumber
      case 1
      case 2
         return "toplevel"
         break
      case 3
         return "modeless"
         break
      case 4
         return "palette"
         break
      case 5
         return "modal"
         break
   end switch
end stackModeName

-- Suspend Development Tools
--   Removes all IDE related backscripts and stacks so that an application can
--   run as if almost built as a standalone.
--   This affects:
--     - the frontscripts
--     - the backscripts
--     - the openstacks
--     - the current tool
--     - the windowBoundingRect
--     - the script debug mode
--
--  Note at present, holding down shift will cause *all* back and front
--  scripts to be removed including library scripts such as Table, PrintBack etc.
--
command revIDESuspendDevelopmentTools
   global gREVRestore
   
   -- Store the old setting of scriptdebugmode and disable it
   put the cREVScriptDebugMode of stack "revPreferences" into gREVRestore["scriptdebugmode"]
   
   -- As cREVScriptDebugMode is a virtual custom property handler present in the revBackScript
   -- we need to do this before removing the backscripts!
   revIDESetScriptDebugMode false
   
   # OK-2008-05-23 : Suspend any script editors.
   send "revSESuspendEditors" to revScriptEditorMain()
   
   -- Remove front and back scripts that pertain to the IDE
   -- If the shift-key is down, we remove *all* 'rev' front and back scripts, including
   -- the library scripts.
   local tScriptsList, tRemoveFrontList, tRemoveBackList
   select empty
   if the shiftKey is down then
      put the frontScripts into tScriptsList
      repeat for each line l in tScriptsList
         if char 1 to 3 of the short name of l is "rev" then
            put l & cr after tRemoveFrontList
            remove script of l from front
         end if
      end repeat
      put the backScripts into tScriptsList
      repeat for each line l in tScriptsList
         if char 1 to 3 of the short name of l is "rev" then
            put l & cr after tRemoveBackList
            remove script of l from back
         end if
      end repeat
   else
      put the frontScripts into tScriptsList
      repeat for each line l in tScriptsList
         if the short name of l is among the items of "revFrontScriptLibrary,revDebugger,revShortCutsLibrary" then
            put l & cr after tRemoveFrontList
            remove script of l from front
         end if
      end repeat
      put the backScripts into tScriptsList
      repeat for each line l in tScriptsList
         if the short name of l is "revBackScriptLibrary,revShortCutsLibrary" then
            put l & cr after tRemoveBackList
            remove script of l from back
         end if
      end repeat
   end if
   delete last char of tRemoveBackList
   delete last char of tRemoveFrontList
   
   -- Close all Revolution IDE stacks
   local tList, tMode, tClosedStacksList
   put the openStacks into tList
   lock messages
   repeat for each line tStack in tList
      if char 1 to 3 of the short name of stack tStack is "rev" or the short name of stack tStack is among the items of "Message Box,Home,answer dialog,ask dialog" then
         # OK-2008-05-23 : Compare the stack's mode to its style. If they are equal then we don't need to store the mode, as opening the 
         # stack will result in the default mode being that which matches its style.
         local tModeName
         put stackModeName(the mode of stack tStack) into tModeName
         if tModeName is the style of stack tStack then
            put empty into tMode
         else
            put tModeName into tMode
         end if
         close stack tStack
         put tStack,tMode & return after tClosedStacksList
      end if
   end repeat
   delete last char of tClosedStacksList
   
   -- Switch to browser tool
   put the tool into gREVRestore["tool"]
   choose browse tool
   
   put tRemoveBackList into gREVRestore["backscripts"]
   put tRemoveFrontList into gREVRestore["frontScripts"]
   put tClosedStacksList into gREVRestore["stacks"]
   
   -- Reset the windowBoundingRect
   put the windowBoundingRect into gREVRestore["windowBoundingRect"]
   set the windowBoundingRect to 0,0,item 3 to 4 of the windowBoundingRect
   
   -- Show the restore dialog
   lock recent
   palette "revRestore"
   unlock recent
   
   -- Setup the default menubar to one specific to this mode
   set the defaultMenuBar to the long id of group "Restore Development Tools" of stack "revRestore"
   
   unlock messages
end revIDESuspendDevelopmentTools

-- Restore Development Tools
--
-- Reverts the IDE to the state it was before 'Suspend Development Tools' was called.
--
command revIDERestoreDevelopmentTools
   global gREVRestore, gREVDontLoadMenus, gREVDontError
   lock messages
   repeat for each line l in gREVRestore["backscripts"]
      insert script of l into back
   end repeat
   repeat for each line l in gREVRestore["frontScripts"]
      insert script of l into front
   end repeat
   put true into gREVDontLoadMenus
   put true into gREVDontError
   
   local tMode, tStackName
   repeat for each line tStack in gREVRestore["stacks"]
      put item 2 of tStack into tMode
      put item 1 of tStack into tStackName
      
      --      put item tMode of "toplevel,toplevel,modeless,palette,modal" into tMode
      --    do "go stack" && quote & (item 1 of l) & quote && "as" && tMode
      
      # OK-2008-08-25 : Bug 7022 - If plugins throw errors when opened, this wil fail, so we catch
      # the errors with a try here, and disregard them.
      try
         
         # OK-2008-05-23 : If tMode is empty, it means that the stack's mode matched its style at the time of closing
         # and this means that no mode change is required.
         lock messages
         switch tMode
            case "toplevel"
               go stack tStackName as toplevel
               break
            case "modeless"
               go stack tStackName as modeless
               break
            case "palette"
               go stack tStackName as palette
               break
            case "modal"
               go stack tStackName as modal
               break
            default
               go stack tStackName
         end switch
         
      end try
   end repeat
   close stack "revRestore"
   set the defaultMenuBar to the long id of group "revMenuBar" of stack revIDEPaletteToStackName("menubar")
   set the width of stack "revMenuBar" to the width of stack "revMenuBar" + 1 -- bug 1806
   set the width of stack "revMenuBar" to the width of stack "revMenuBar" - 1
   set the windowBoundingRect to gREVRestore["windowBoundingRect"]
   choose gREVRestore["tool"]
   
   -- Restore the script debug mode
   revIDESetScriptDebugMode gREVRestore["scriptdebugmode"]
   
   # OK-2008-05-23 : Restore any script editors.
   send "revSERestoreEditors" to revScriptEditorMain()
   
   unlock messages
end revIDERestoreDevelopmentTools

command revIDECheckForUpdates
   if line 3 of revLicenseInfo is not "evaluation" then
      local tCommand
      set the itemdelimiter to "/"
      switch the platform
         case "MacOS"
            put item 1 to -5 of the filename of stack "home" & "/LiveCode Setup.app/Contents/MacOS/installer" into tCommand
            put quote & tCommand & quote && "install -foregroundupdate" into tCommand
            break
         case "Win32"
            put item 1 to -3 of the filename of stack "home" & "/.setup.exe" into tCommand
            put quote & tCommand & quote && "install -foregroundupdate" into tCommand
            break
         case "Linux"
            put item 1 to -3 of the filename of stack "home" & "/.setup.x86" into tCommand
            put tCommand && "install -foregroundupdate" into tCommand
            break
      end switch
      set the itemDel to comma
      open process tCommand for neither
   end if   
end revIDECheckForUpdates

# OK-2009-10-07 : Noticed that View -> Go Prev wasn't working, decided to rewrite code
# as it depended on the state that the menubar was saved in, and was duplicated.
local sMoveBuffers
constant kMoveBufferSize = 20

# OK-2009-10-07 : This command does "go pMoveSpecifier" with a buffering effect to prevent it
# getting carried out more frequently than every kMoveBufferSize milliseconds
on revIDEGoCard pMoveSpecifier
   if the milliseconds - sMoveBuffers[pMoveSpecifier] < kMoveBufferSize then
      exit revIDEGoCard
   end if
   
   set the defaultStack to the topStack
   local tCommand
   put "go " & pMoveSpecifier into tCommand
   do tCommand
   put the milliseconds into sMoveBuffers[pMoveSpecifier]
end revIDEGoCard

function revIDEScriptEditorPrefix
   return "revNewScriptEditor "
end revIDEScriptEditorPrefix

/*
User stacks, script editors, the dictionary and resource center are considered windows 
from the point of view of the menubar
*/
function revIDEStackIsWindow pStackName
   if pStackName begins with revIDEScriptEditorPrefix() or pStackName is "revDictionary" or pStackName is "revResourceCenter" then
      return true
   else if char 1 to 3 of pStackName is not "rev" and pStackName is not among the items of "Message Box,Home,answer dialog,ask dialog,script debugger,file selector" then
      return true
   end if
   
   return false
end revIDEStackIsWindow

local sWindowList
on revIDEUpdateWindowList
   local tOpenstacks
   put the openStacks into tOpenstacks
   
   local tStacks, tName
   repeat for each line tStackName in tOpenstacks
      if revIDEStackIsWindow(tStackName) then
         put the name of stack tStackName into tName
         if tStacks is empty then 
            put tName into tStacks
         else
            put return & tName after tStacks
         end if
      end if
   end repeat
   
   if tStacks is not empty then
      local tTopMostStack
      put line 1 of tStacks into tTopMostStack
      
      local tOtherstacks
      put line 2 to -1 of tStacks into tOtherstacks
      sort tOtherstacks
      
      put tTopMostStack & return & tOtherstacks into tStacks
   end if
   
   if tStacks is not sWindowList then
      revIDEMessageSend "ideWindowsChanged"
   end if
   put tStacks into sWindowList
end revIDEUpdateWindowList

# Returns the list of the open stack names which should be included in a window menu. 
function revIDEWindowList
   return sWindowList
end revIDEWindowList

/*
Sends the current top window to the back
*/
on revIDESendCurrentWindowToBack
   lock messages
   
   local tWindowsList
   put the windows into tWindowsList
   
   local tWindows, tWindows2
   repeat for each line l in tWindowsList
      if the mode of stack l is among the items of "1,2" then
         put l & return after tWindows
      else if the mode of stack l is "3" then
         put l & return after tWindows2
      end if
   end repeat
   if char -1 of tWindows2 is return then delete char -1 of tWindows2
   if char -1 of tWindows is return then delete char -1 of tWindows
   
   local tCurrentStackName
   put char 3 to -1 of line (lineOffset("!c",the text of me)) of the text of me into tCurrentStackName
   delete line lineOffset(tCurrentStackName,tWindows) of tWindows
   
   if the num of lines in tWindows2 is not 0 
   then put tWindows2 & return & tWindows into tWindows
   
   repeat for each line l in tWindows
      -- delete char 1 to 2 of l
      if the mode of stack l is 1 or the mode of stack l is 2 then toplevel l
      else if the mode of stack l is 3 then modeless l
      show stack l
   end repeat
   unlock messages
end revIDESendCurrentWindowToBack

/*
Brings the specified window to the front
*/
on revIDESendWindowToFront pStackID
   go pStackID
   show pStackID
end revIDESendWindowToFront

/*
Returns an array labels and filepaths to recently opened stack
*/
function revIDERecentStacks
   # Get recent paths from preferences
   local tRecentPaths
   put revIDEGetPreference("cRecentStackPaths") into tRecentPaths
   
   # If users have preference to sort recent list alphabetic, sort.
   if revIDEGetPreference("cRecentSort") is "alphabetically" then
      set the itemdel to "/"
      sort lines of tRecentPaths by last item of each 
   end if
   
   # Split list into array
   local tRecentPathData
   put tRecentPaths into tRecentPathData
   split tRecentPathData by return
   
   # Generate labels for the stacks. The label is the filename without the file extension
   # If two stacks have the same filename, the minimum path is added to the label to
   # distinguish the entries
   repeat with x = 1 to the number of lines of the keys of tRecentPathData
      put tRecentPathData[x] into tRecentPathData[x]["filename"]
      put revIDEFilepathUniqueLabel(tRecentPaths,tRecentPathData[x]["filename"]) into tRecentPathData[x]["label"] 
      
   end repeat
   
   return tRecentPathData
end revIDERecentStacks

/*
Adds an entry to the recent file paths
*/
on revIDEAddRecentStack pFilePath
   # Validate parameters
   if there is not a file pFilePath then exit revIDEAddRecentStack
   
   # Get recent paths preferences 
   local tRecentPaths
   put revIDEGetPreference("cRecentStackPaths") into tRecentPaths
   
   if tRecentPaths is empty then 
      put pFilePath into tRecentPaths
   else
      put pFilePath & return & tRecentPaths into tRecentPaths
      put revIDECleanRecentStackList(tRecentPaths) into tRecentPaths
   end if
   
   # Ensure the list isn't longer than 15 entries
   if the number of lines of tRecentPaths > 15 then
      put line 1 to 15 of tRecentPaths into tRecentPaths
   end if
   
   #Set the preference
   revIDESetPreference "cRecentStackPaths", tRecentPaths
   
   # Notify registered stack of the change by sending an ideRecentStacksChanged message
   -- BB needs to be implemented? Question. The general message sending in the IDE does not have "lock ide messages" option
   -- So calling revIDEAddRecentStack is quick succession.. lets say in an "openAllStacks" handler is going to cause this message 
   -- fire multiple times in quick succession. lock ide messages could prevent the sending of messages and stack/replace them 
   -- and flush the queue on unlock ide messages.. resulting in just one version of the message being sent. 
   revIDEMessageSend "ideRecentFilesChanged"
end revIDEAddRecentStack

/*
Given a list of filenames and a filename from the list, a unique minimal lable is returned. For example:

/Desktop/test1/ben.livecode
/Desktop/test2/ben.livecode
/Desktop/test3/myProject.livecode

Calling this function for each of these inputs in turn would return

test1/ben.livecode
test2/ben.livecode
myProject.livecode
*/
private function revIDEFilepathUniqueLabel pFilepaths, pFilepath
   set the itemdel to "/"
   local tItemIsUnique, tLabel
   
   # Repeat backward through the items of the filepath we're generating the label for
   repeat with x = 1 to the number of items of pFilepath
      put true into tItemIsUnique
      
      # Repeat through the list of filepaths looking for items that match
      repeat for each line tPathInList in pFilepaths
         # Ignore the exact filename in the list
         if tPathInList is pFilepath then next repeat
         if the number of items of tPathInList < x then next repeat
         
         if item -x of tPathInList is item -x of pFilepath then
            put false into tItemIsUnique
         end if
      end repeat
      
      # If unique, add to the label and exit seach
      if tLabel is empty then
         put item -x of pFilepath into tLabel
      else
         put item -x of pFilepath & slash before tLabel
      end if
      
      if tItemIsUnique is true then
         exit repeat
      end if
   end repeat
   
   return tLabel
end revIDEFilepathUniqueLabel

/*
Cleans the list of recent file paths. Removes broken links (Stacks that have been subsequently removed), 
removed duplicates and resolves the label when two stack have the same name but stored in different paths.
*/
function revIDECleanRecentStackList pRecentStackList
   local tCleanList
   
   repeat for each line tRecentStack in pRecentStackList
      # Ignore broken links
      if there is not a file tRecentStack then next repeat
      # Ignore duplicates
      if tRecentStack is among the lines of tCleanList then next repeat
      
      # Add to clean list
      if tCleanList is empty then
         put tRecentStack into tCleanList
      else
         put return & tRecentStack after tCleanList
      end if
   end repeat
   
   return tCleanList
end revIDECleanRecentStackList

// Keep track of the current transient text field
local sTransientTextField

/*
Adds a text field (usually to the property inspector) at a specified rect pRect, which, when its text is changed, dispatches 
a callback pCallback to the specified target and deletes the text field. pCallbackParams is sent to the callback target as a parameter
*/
on revIDECreateTransientTextField pRect, pCallback, pCallbackParams, pCurrentText
   if sTransientTextField is not empty then
      revIDERemoveTransientTextField
   end if
   
   lock screen
   lock messages
   local tLongID
   create field
   put the long id of it into tLongID
   put tLongID into sTransientTextField["id"]
   put pCallbackParams into sTransientTextField["callback_params"]
   put pCallback into sTransientTextField["callback"]
   set the rect of tLongID to pRect
   local tScript
   put "on closeField;revIDETransientTextChanged;end closeField" into tScript
   put ";on returnInField; revIDETransientTextChanged;end returnInField" after tScript
   put ";on exitField;revIDETransientTextChanged;end exitField" after tScript
   set the script of tLongID to tScript
   set the text of tLongID to pCurrentText
   local tTargetLongID
   put the long id of the target into tTargetLongID
   put tTargetLongID into sTransientTextField["callback_target"]
   get the textAlign of tTargetLongID 
   if it is not empty then
      set the textAlign of tLongID to it
   end if
   focus on tLongID
   unlock messages
   unlock screen
end revIDECreateTransientTextField

/*
Deletes the transient text field
*/
on revIDERemoveTransientTextField pTarget
   lock screen
   lock messages
   if pTarget is empty then
      exit revIDERemoveTransientTextField
   end if
   delete pTarget
   unlock messages
   unlock screen
end revIDERemoveTransientTextField

/*
Sends the callback with params as specified by prior call to revIDEAddTransientTextField
Called by transient text fields on closeField, returnInField or exitField
*/
on revIDETransientTextChanged
   lock screen
   lock messages
   if sTransientTextField is empty then
      exit revIDETransientTextChanged
   end if
   local tCallbackInfo, tValue, tField
   put sTransientTextField["id"] into tField
   put the text of tField into tValue
   put sTransientTextField into tCallbackInfo
   put empty into sTransientTextField
   unlock messages
   send "revIDERemoveTransientTextField tField" to me in 0 millisecs
   dispatch tCallbackInfo["callback"] to tCallbackInfo["callback_target"] with tValue, tCallbackInfo["callback_params"]
   unlock screen
end revIDETransientTextChanged

/*
Simply delete the transient text field without sending the text changed callback.
*/
on revIDEDismissTransient
   lock screen
   lock messages
   if sTransientTextField is empty then
      exit revIDEDismissTransient
   end if
   local tCallbackInfo, tValue, tField
   put sTransientTextField["id"] into tField
   put empty into sTransientTextField
   unlock messages
   send "revIDERemoveTransientTextField tField" to me in 0 millisecs
   unlock screen
end revIDEDismissTransient

##################################################
#
#          IDE DOCS FUNCTIONS
#
##################################################

private function escape pString, pConvertLineEndings
   replace "\" with "\\" in pString
   replace quote with ("\" & quote) in pString
   
   if pConvertLineEndings is true then
      replace (numToChar(13) & CR) with (CR & numToChar(13)) in pString
      replace (CR & numToChar(13)) with CR in pString
   end if
   replace CR with "\n" in pString
   //replace "<" with "&lt;" in pString
   //replace ">" with "&gt;" in pString
   replace tab with "\t" in pString
   return (quote & pString & quote)
end escape

private function revIDEGetDocsAPIData
   local tData
   
   local tAPIPath
   put revIDESpecialFolderPath("API") into tAPIPath
   put url ("binfile:" & tAPIPath & slash & "distributed_API.js") into tData
   
   local tExtensionDocsDataA
   put revIDEExtensionDocsData() into tExtensionDocsDataA
   
   local tFolder
   repeat for each element tExtensionData in tExtensionDocsDataA
      local tExtensionAPI
      put tExtensionData["folder"] into tFolder
      if there is a not file (tFolder & slash & "api.lcdoc")  then next repeat
      
      # Check if the .js is out of date
      local tLastModified, tLastGenerated
      put revIDELastModifiedTimeOfFile(tFolder, "api.lcdoc") into tLastModified
      put revIDELastModifiedTimeOfFile(tFolder, "api.js") into tLastGenerated
      if tLastModified < tLastGenerated then
         put url ("binfile:" & tFolder & slash & "api.js") into tExtensionAPI
      else
         local tLcdoc
         dispatch function "revDocsFormatDocFileAsJSON" to stack "revDocsParser" with (tFolder & slash & "api.lcdoc"), tExtensionData["title"], tExtensionData["author"]
         put the result into tExtensionAPI
         put tExtensionAPI into url ("binfile:" & tFolder & slash & "api.js") 
      end if
      
      if tExtensionAPI is not empty then
         put comma & tExtensionAPI after tData
      end if
   end repeat
   
   return tData
end revIDEGetDocsAPIData

private function revIDEGetDocsGuideData
   local tData
   
   local tGuidePath
   put revIDESpecialFolderPath("guide") into tGuidePath
   put url ("binfile:" & tGuidePath & slash & "distributed_guide.js") into tData
   
   local tExtensionDocsDataA
   put revIDEExtensionDocsData() into tExtensionDocsDataA
   
   local tFolder
   repeat for each element tExtensionData in tExtensionDocsDataA
      local tExtensionGuide
      put empty into tExtensionGuide
      put tExtensionData["folder"] into tFolder
      if there is a not file (tFolder & slash & "guide.md")  then next repeat
      
      # Check if the .js is out of date
      local tLastModified, tLastGenerated
      put revIDELastModifiedTimeOfFile(tFolder, "guide.md") into tLastModified
      put revIDELastModifiedTimeOfFile(tFolder, "guide.js") into tLastGenerated
      if tLastModified < tLastGenerated then
         put url ("binfile:" & tFolder & slash & "guide.js") into tExtensionGuide
      else
         local tGuide
         put url ("binfile:" & tFolder & slash & "guide.md") into tGuide
         put textDecode(tGuide, "utf-8") into tGuide
         
         if tGuide is not empty then
            put "{" & CR after tExtensionGuide
            put tab & quote & "guide" & quote & ":" && quote & tFolder & quote & comma & CR after tExtensionGuide
            put quote & "data" & quote & ":" & escape(tGuide, true) & CR after tExtensionGuide
            put "}" after tExtensionGuide
            
            put textEncode(tExtensionGuide, "utf-8") into url ("binfile:" & tFolder & slash & "guide.js")
         end if
      end if
      
      if tExtensionGuide is not empty then
         put comma & tExtensionGuide after tData
      end if
   end repeat
   
   return tData
end revIDEGetDocsGuideData

on revIDEAddGuideAndRegenerate pGuide
   local tData
   
   # Get the location of the distributed guide
   local tGuidePath
   put revIDESpecialFolderPath("guide") into tGuidePath
   
   put "var tUserGuideData =" & CR & "{" & CR & tab & quote & "guides" & quote & ":[" into tData
   
   put revIDEGetDocsGuideData() after tData
   
   if pGuide is not empty then
      put comma & pGuide after tData
   end if
   
   put CR & tab & "]" & CR & "}" after tData
   
   put tData into URL ("binfile:" & tGuidePath & slash & "built_guide.js")
end revIDEAddGuideAndRegenerate

on revIDEAddAPIAndRegenerate pAPI
   local tData
   
   # Get the location of the distributed API
   local tAPIPath
   put revIDESpecialFolderPath("API") into tAPIPath
   
   put "var dictionary_data =" & CR & "{" & CR & tab & quote & "docs" & quote & ":[" after tData
   
   put revIDEGetDocsAPIData() after tData
   
   if pAPI is not empty then
      put comma & pAPI after tData
   end if
   
   put CR & tab & "]" & CR & "}" after tData
   put tData into URL ("binfile:" & tAPIPath & slash & "built_api.js")
end revIDEAddAPIAndRegenerate

on revIDERegenerateBuiltAPIs
   revIDEAddAPIAndRegenerate
end revIDERegenerateBuiltAPIs

on revIDERegenerateBuiltGuides
   revIDEAddGuideAndRegenerate
end revIDERegenerateBuiltGuides

on revIDERegenerateBuiltDictionaryData
   revIDERegenerateBuiltAPIs
   revIDERegenerateBuiltGuides
end revIDERegenerateBuiltDictionaryData
