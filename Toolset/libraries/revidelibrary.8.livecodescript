script "revidelibrary"
/**
Main IDE library providing functionality for palettes and other IDE add-ons.

Name: ideNewControl
Type: message
Syntax: on ideNewControl
Summary: Sent when a control is created in the IDE

Description:
Handle the <ideNewControl> message to respond to the creation of controls using one of the
IDE palettes, or the create command.

>*Note:* The <ideNewControl> message is only sent to objects which have subscribed to it.
See the <revIDESubscribe> command for more details.

References: revIDESubscribe (command)
**/

/**
Called when loading the IDE library
**/
on extensionInitialize
   if the target is not me then
      pass extensionInitialize
   end if
   
   insert the script of me into back
   revIDEInitialiseIDELibrary
end extensionInitialize

on extensionFinalize
   if the target is not me then
      pass extensionFinalize
   end if
    
   remove the script of me from back
   revIDEFinaliseIDELibrary
end extensionFinalize

#############
# Internal functions
#############

# Reads in all the tool data
local sToolDefinition
private on __toolDefinitionsRead
   put empty into sToolDefinition
   
   # Set to folder to the path where the object definition files for classic controls are stored
   local tToolDefinitionPath
   put revIDESpecialFolderPath("Tool Definitions") into tToolDefinitionPath
   revIDEPushDefaultFolder tToolDefinitionPath
   
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
   
   revIDEPopDefaultFolder
end __toolDefinitionsRead

private on __resolvePopupData @xInfo, pData
   if not xInfo["options"] begins with "popup:" then
      exit __resolvePopupData
   end if
   local tOptions
   set the itemdel to ":"
   put item 2 to -1 of xInfo["options"] into tOptions
   set the itemdel to ","
   local tCount, tProp
   repeat for each item tPopup in tOptions
      add 1 to tCount
      put pData[tPopup] into tProp
      __resolvePopupData tProp, pData
      put tProp into xInfo["popup"][tPopup]
      put tCount into xInfo["popup"][tPopup]["group_order"]
      put empty into xInfo["options"]
   end repeat
end __resolvePopupData

private function __propertyDataMapping
   local tMapping 
   put "name:1,label:2,section:3,editor:4,user_visible:5,read_only:6,group:7,default:8,options:9,subsection:10,min:11,max:12,step:13" into tMapping
   split tMapping by comma and ":"
   return tMapping
end __propertyDataMapping

# Processes the data
private function __propertyDataProcessLine pLine
   local tLineDataA, tMappingA
   put __propertyDataMapping() into tMappingA
   
   repeat for each key tDataName in tMappingA
      local tItemNumber, tPreProcessed
      put tMappingA[tDataName] into tItemNumber
      set the itemdelimiter to tab
      put item tItemNumber of pLine into tPreProcessed
      set the itemdelimiter to comma
      
      switch tDataName
         case "name"
            # Properties can use custom getters and setters.
            # Default getter is revIDEPropertyOfObject
            # Default setter is revIDESetPropertyOfObject
            set the itemdelimiter to ":"
            put item 1 of tPreProcessed into tLineDataA["name"]
            put item 2 of tPreProcessed into tLineDataA["getter"]
            put item 3 of tPreProcessed into tLineDataA["setter"]
            set the itemdelimiter to comma
            break
         case "default"
            set the itemdelimiter to ":"
            if item 1 of tPreProcessed is "execute" then
               do item 2 of tPreProcessed
               put it into tPreProcessed
            end if
            set the itemdelimiter to comma
            put __unescapeString(tPreProcessed) into tLineDataA["default"]
            break
         case "options"
            # Get any popup info
            set the itemdelimiter to ":" 
            if tPreProcessed begins with "popup:" then
               put true into tLineDataA["popup"]
            else
               replace comma with return in tPreProcessed
            end if
            set the itemdelimiter to comma
            put tPreProcessed into tLineDataA["options"]
            break
         default
            put tPreProcessed into tLineDataA[tDataName]
            break
      end switch
   end repeat
   return tLineDataA
end __propertyDataProcessLine

private function __propertyDataFromInfoFile pFileName
   local tPropertyInfo
   put URL ("file:" & pFileName) into tPropertyInfo
   
   local tDataStart, tDataA, tPropName
   put false into tDataStart
   
   local tCountsA, tGroupCountsA, tPopupsToResolve
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
      
      local tLineDataA
      put __propertyDataProcessLine(tLine) into tLineDataA
      
      put tLineDataA["name"] into tPropName
      put tLineDataA into tDataA[tPropName]
      
      local tGroupName
      put tLineDataA["group"] into tGroupName
      if tGroupName is empty then
         put tDataA[tPropName]["label"] into tGroupName
      end if
      if tGroupName is empty then
         put tPropName into tGroupName
      end if
      put tGroupName into tDataA[tPropName]["group"]
      
      local tSection
      put tLineDataA["section"] into tSection
      if tGroupCountsA[tSection][tGroupName] is empty then
         add 1 to tCountsA[tSection]["count"]
         put tCountsA[tSection]["count"] into tGroupCountsA[tSection][tGroupName]
      end if
      put tGroupCountsA[tSection][tGroupName] into tDataA[tPropName]["group_order"]
      
      add 1 to tCountsA[tSection][tGroupName]["count"]
      put tCountsA[tSection][tGroupName]["count"] into tDataA[tPropName]["order"]
      
      if tLineDataA["popup"] is true then
         put true into tPopupsToResolve[tPropName]
      end if
   end repeat
   
   repeat for each key tKey in tPopupsToResolve 
      local tPropData
      put tDataA[tKey] into tPropData
      __resolvePopupData tPropData, tDataA
      put tPropData into tDataA[tKey]
   end repeat
   
   return tDataA
end __propertyDataFromInfoFile

private function __organisePropertyInfo pInfoA, pPopup
   local tOrganisedA
   repeat for each key tKey in pInfoA
      local tSection
      put pInfoA[tKey]["section"] into tSection
      
      local tGroupLabel
      put pInfoA[tKey]["group"] into tGroupLabel
      
      local tGroupData
      put empty into tGroupData
      
      # The groups are ordered by their appearance in the spec file
      put pInfoA[tKey]["group_order"] into tGroupData["order"]
      put pInfoA[tKey]["subsection"] into tGroupData["subsection"]
      
      # Carry over the generic prop information into the object prop info array
      put pInfoA[tKey] into tGroupData["proplist"][tKey]
      
      # Organise the popup data if there is any
      local tPopupData
      if pInfoA[tKey]["popup"] is not empty then
         put __organisePropertyInfo(pInfoA[tKey]["popup"], true) into tGroupData["proplist"][tKey]["popup"] 
      end if 
      if pPopup then
         union tOrganisedA["grouplist"][tGroupLabel] with tGroupData recursively
      else
         union tOrganisedA[tSection]["grouplist"][tGroupLabel] with tGroupData recursively
      end if
   end repeat
   return tOrganisedA
end __organisePropertyInfo

local sClassicObjectProperties, sClassicObjectPropertiesInfo, sClassicPropertiesInfo
-- Use this accessor instead of the array directly to ensure inherited props
-- are also included, eg control level defined props.
private function __classicObjectProperties pObjID
   local tType
   put ideObjectTypeFromObject(pObjID) into tType
   
   return __classicObjectPropertiesFromType(tType)
end __classicObjectProperties

private function __classicObjectPropertiesFromType pType
   set the itemdel to "."
   switch the last item of pType
      case "Card"
      case "Stack"
      case "Substack"
         return sClassicObjectProperties[pType]
      default
         if not (pType begins with "com.livecode.interface.classic") then
            put "com.livecode.interface.classic.widget" into pType
         end if
         local tPropsA
         put sClassicObjectProperties[pType] into tPropsA
         union tPropsA with sClassicObjectProperties["com.livecode.interface.Control"] recursively
         return tPropsA
   end switch
end __classicObjectPropertiesFromType

private on  __setPropertyDataOfObjectFromFile pObjectType, pFile, pPropInfoA
   local tObjectData
   
   # Get the data from the file
   put URL ("file:" & pFile) into tObjectData
   
   # Parse the file into a structure array
   local tObjectPropertiesA, tCountsA, tGroupCountsA
   set the itemdel to tab
   
   local tDataStart, tDataA
   put false into tDataStart
   repeat for each line tLine in tObjectData
      if tLine is empty then next repeat
      
      if tLine begins with "-----" then
         put true into tDataStart
         next repeat
      end if
      
      local tLineDataA
      put __propertyDataProcessLine(tLine) into tLineDataA
      
      if tLineDataA["name"] is "type" then
         put tLineDataA["label"] into sClassicObjectProperties[pObjectType]["type"]
         next repeat
      end if
      # Allow 'display title' of classic controls to be specified in property definition file
      if tLineDataA["name"] is "title" and not tDataStart then
         put tLineDataA["label"] into sClassicObjectProperties[pObjectType]["title"]
         next repeat
      end if
      
      if tDataStart is false then
         next repeat
      end if
      
      local tPropertyName
      put tLineDataA["name"] into tPropertyName
      
      repeat for each key tOverride in tLineDataA
         if tLineDataA[tOverride] is not empty then
            put tLineDataA[tOverride] into pPropInfoA[tPropertyName][tOverride]
         end if
      end repeat
      
      # Default can override to empty if it is the string "empty"
      if tLineDataA["default"] is not empty then
         if tLineDataA["default"] is "empty" then
            put empty into tLineDataA["default"]
         end if
         put tLineDataA["default"] into pPropInfoA[tPropertyName]["default"]
      end if
      
      local tGroupLabel
      put pPropInfoA[tPropertyName]["group"] into tGroupLabel
      if tGroupLabel is empty then
         put pPropInfoA[tPropertyName]["label"] into tGroupLabel
      end if
      if tGroupLabel is empty then
         put tPropertyName into tGroupLabel
      end if
      put tGroupLabel into pPropInfoA[tPropertyName]["group"]
      
      local tSection
      put pPropInfoA[tPropertyName]["section"] into tSection
      
      # The groups are ordered by their appearance in the spec file
      if tGroupCountsA[tSection][tGroupLabel] is empty then
         add 1 to tCountsA[tSection]["count"]
         put tCountsA[tSection]["count"] into tGroupCountsA[tSection][tGroupLabel]
      end if
      put tGroupCountsA[tSection][tGroupLabel] into pPropInfoA[tPropertyName]["group_order"]
      
      add 1 to tCountsA[tSection][tGroupLabel]["count"]
      put tCountsA[tSection][tGroupLabel]["count"] into pPropInfoA[tPropertyName]["order"]
      -- Put 'control properties' last
      -- TODO: there should be a more transparent way of ordering these
      if pObjectType is "com.livecode.interface.Control" then
         add 1000 to pPropInfoA[tPropertyName]["group_order"]
      end if
      
      put pPropInfoA[tPropertyName] into sClassicObjectProperties[pObjectType]["properties"][tPropertyName]
      put pPropInfoA[tPropertyName] into tObjectPropertiesA[tPropertyName]
   end repeat
   
   put __organisePropertyInfo(tObjectPropertiesA) into sClassicObjectPropertiesInfo[pObjectType]
end __setPropertyDataOfObjectFromFile

private function __propertyInfoFilename
   return "propertyInfo.tsv"
end __propertyInfoFilename

private function __classicToolsOrderFilename
   return "classicToolsOrder.tsv"
end __classicToolsOrderFilename 

private on __orderClassicTools
   local tToolsOrderFile
   put revIDESpecialFolderPath("Object Property Definitions") & slash & __classicToolsOrderFilename() into tToolsOrderFile
   
   local tOrder
   repeat for each line tTool in url ("file:" & tToolsOrderFile)
      add 1 to tOrder
      put tOrder into sClassicObjectProperties[tTool]["order"]
   end repeat
end __orderClassicTools

# Reads in the basic property data for classic controls
private on __objectPropertiesRead
   put empty into sClassicObjectProperties
   put empty into sClassicObjectPropertiesInfo
   put empty into sClassicPropertiesInfo
   
   # Set to folder to the path where the object definition files for classic controls are stored
   local tObjectDefinitionsPath
   put revIDESpecialFolderPath("Object Property Definitions") into tObjectDefinitionsPath
   
   local tPropertiesInfo
   put __propertyDataFromInfoFile(tObjectDefinitionsPath & slash & __propertyInfoFilename()) into tPropertiesInfo
   revIDEPushDefaultFolder tObjectDefinitionsPath
   
   # Read in each file and build an array
   local tObjectType
   
   repeat for each line tFile in the files
      if not (tFile begins with "com.livecode.interface") then next repeat
      if char 1 of tFile is "." then next repeat
      
      put tFile into tObjectType
      # Get the name of the object
      set the itemdel to "."
      if the last item of tObjectType is "tsv" then delete the last item of tObjectType
      if tObjectType is empty then next repeat
      
      __setPropertyDataOfObjectFromFile tObjectType, tObjectDefinitionsPath & slash & tFile, tPropertiesInfo
   end repeat
   
   __orderClassicTools
   
   put tPropertiesInfo into sClassicPropertiesInfo
   
   revIDEPopDefaultFolder
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
         # Inherit the prop label if there is only one
         if the number of elements in tOrderedA[tCount]["proplist"] is 1 then
            put tOrderedA[tCount]["proplist"][1]["label"] into tOrderedA[tCount]["label"]
         end if
      else
         if pSectionA[tSubKey][tProp]["popup"] is not empty then
            put __orderPropSubArray(pSectionA[tSubKey][tProp]["popup"], true) into pSectionA[tSubKey][tProp]["popup"]
         end if
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

private function __objectPropertiesInfo pObjectType, pOrganiseInSections, pOptionalSection
   local tPropertiesArray, tClassicObjectType
   if not (pObjectType begins with "com.livecode.interface.classic") then
      # This is not a classic object, so fetch the 'extension' properties.
      put revIDEExtensionPropertiesInfo(pObjectType, pOrganiseInSections) into tPropertiesArray
      # Currently this must be a widget, so get the universal widget property info 
      # that has been parsed from the definitions file
      put "com.livecode.interface.classic.widget" into tClassicObjectType
   else
      put pObjectType into tClassicObjectType
   end if
   
   if pOrganiseInSections then
      # Add the object properties for this object type
      union tPropertiesArray with sClassicObjectPropertiesInfo[tClassicObjectType] recursively
      # Restrict to group, if present
      if pOptionalSection is not empty then
         local tSectionProps
         put tPropertiesArray[pOptionalSection] into tSectionProps[pOptionalSection]
         put tSectionProps into tPropertiesArray
      end if
   else
      union tPropertiesArray with sClassicObjectProperties[tClassicObjectType] recursively
   end if
   return tPropertiesArray
end __objectPropertiesInfo

private function __objectPropertiesShared pObjectTypeList, pOrganiseInSections, pOptionalSection
   local tPropertiesArray,tPropertiesArray2, tPropertiesArray3,x, tSectionProps, tAllControls
   put pObjectTypeList is not empty into tAllControls
   
   repeat for each line tObjectType in pObjectTypeList
      if not __objectTypeIsControl(tObjectType) then
         put false into tAllControls  
      end if
      if tPropertiesArray is empty then
         put __objectPropertiesInfo(tObjectType, pOrganiseInSections, pOptionalSection) into tPropertiesArray
      else
         intersect tPropertiesArray with __objectPropertiesInfo(tObjectType, pOrganiseInSections, pOptionalSection) recursively
      end if
   end repeat
   
   if tAllControls then
      union tPropertiesArray with sClassicObjectPropertiesInfo["com.livecode.interface.Control"] recursively
   end if
   
   if pOptionalSection is not empty then
      return tPropertiesArray[pOptionalSection]
   else
      return tPropertiesArray
   end if
end __objectPropertiesShared

/**
Information pertaining to the property <pPropName>.

Parameters:
pPropName (string): One of the IDE canonical object property names.

Returns (array): An array of information pertaining to the given property.

Description:
This function returns the information pertaining to the object property <pPropName>,
parsed from the file Toolset/resources/supporting_files/property_definitions.

Information about synonyms is not returned by this function. For a list of the canonical
property names which are valid inputs to this function, see the <idePropertyNames>
function.

References: idePropertyNames (function)

**/
function revIDEPropertyInfo pPropName
   if sClassicPropertiesInfo is empty then
      __objectPropertiesRead
   end if
   return sClassicPropertiesInfo[pPropName]
end revIDEPropertyInfo

/**
A list of the object property names considered canonical by the IDE

Parameters:
pObjectType (optional string): One of the IDE's object type IDs

Returns (string): A list of the object property names, one per line.

Description:
This function returns a list of the object property names considered canonical by
the IDE, as parsed from the file Toolset/resources/supporting_files/property_definitions.txt.

If the <pObjectType> parameter is used, this returns a list of the properties specific to
that object type, as parsed from the files in Toolset/resources/supporting_files/.

For a list of the object type IDs which are valid inputs to this function, see the <ideObjectTypes>
function.

References: ideObjectTypes (function)
**/
function idePropertyNames pObjectType
   if sClassicPropertiesInfo is empty or sClassicObjectPropertiesInfo is empty then
      __objectPropertiesRead
   end if
   
   local tProps
   if pObjectType is empty then
      put the keys of sClassicPropertiesInfo into tProps
   else
      put the keys of sClassicObjectPropertiesInfo[pObjectType] into tProps
   end if
   sort tProps
   return tProps
end idePropertyNames

/**
A list of the object types, in 'type ID' form

Returns (string): A list of the object types, one per line.

Description:
This function returns a list of the object types in the form used by the IDE.
**/
function ideObjectTypes
   if sClassicObjectPropertiesInfo is empty then
      __objectPropertiesRead
   end if
   
   local tTypes
   put the keys of sClassicObjectPropertiesInfo into tTypes
   sort tTypes
   return tTypes
end ideObjectTypes

/**
Information pertaining to the property <pPropName> in the context of <pObjectType>.

Parameters:
pPropName (string): One of the IDE canonical object property names.
pObjectType (string): One of the IDE's object types.

Returns (array): An array of information pertaining to the given property.

Description:
This function returns the information pertaining to the object property <pPropName>,
parsed from the files in Toolset/resources/supporting_files/. In some cases an individual
property's data can be overridden for a particular object type.

For a list of the canonical property names which are valid inputs to this function, see the
<idePropertyNames> function. For a list of the object type IDs which are valid inputs
to this function, see the <ideObjectTypes> function.

References: idePropertyNames (function), ideObjectTypes (function)

**/
function revIDEObjectPropertyInfo pObjectType, pPropName
   if sClassicObjectPropertiesInfo is empty then
      __objectPropertiesRead
   end if
   return sClassicObjectPropertiesInfo[pObjectType][pPropName]
end revIDEObjectPropertyInfo

/**
A list of the IDE object types corresponding to the list of objects given

Parameters:
pObjectIDs: A list, one per line, of object IDs

Returns: A list, one per line, of the IDE object types associated with
the objects in <pObjectIDs>
**/
function ideObjectTypesFromObjectList pObjectIDs
   local tObjectTypeList, tObjectType
   repeat for each line tObjectID in pObjectIDs
      put ideObjectTypeFromObject(tObjectID) into tObjectType
      if tObjectType is not among the lines of tObjectTypeList then
         put tObjectType & return after tObjectTypeList
      end if
   end repeat
   delete the last char of tObjectTypeList
   return tObjectTypeList
end ideObjectTypesFromObjectList

/**
The IDE object type corresponding to the given object

Parameters:
pObjectID: An object ID

Returns: The IDE object type associated with the objects <pObjectID>

Example:
create field
put ideObjectTypeFromObject(it)  -- outputs com.livecode.interface.classic.Field
set the listBehavior of it to true
put ideObjectTypeFromObject(it)  -- outputs com.livecode.interface.classic.ListField

Description:
>*Note:* The type returned by <ideObjectTypeFromObject> can depend
on the values of the object's properties.
   **/
function ideObjectTypeFromObject pObjectID
   switch word 1 of the name of pObjectID
      case "stack"
         if word 4 of pObjectID is "stack" then
            return "com.livecode.interface.classic.Substack"
         else
            return "com.livecode.interface.classic.Stack"
         end if
      case "card"
         return "com.livecode.interface.classic.Card"
      case "group"
         if the dgProps["control type"] of pObjectID is "Data Grid" then
            if the dgProps["style"] of pObjectID is "Table" then
               return "com.livecode.interface.classic.DataGrid"
            else
               return "com.livecode.interface.classic.DataGridForm"
            end if
         else
            return "com.livecode.interface.classic.Group"
         end if
         break
      case "field"
         if revIDEGetTableProperty(pObjectID, "basicTableObject") then
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
                  case "tabbed"
                     return "com.livecode.interface.classic.TabPanel"
                     break
                  case "popup"
                  case "cascade"
                  default
                     return "com.livecode.interface.classic.PopupMenu"
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
            case "text"
            case "rectangle"
               return "com.livecode.interface.classic.RectangleGraphic"
               break
            case "roundrect"
               return "com.livecode.interface.classic.RoundRectGraphic"
               break
            case "line"
               return "com.livecode.interface.classic.LineGraphic"
               break
            case "arc"
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
end ideObjectTypeFromObject

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
   global gRevDevelopment
   
   local tErrorContext, tErrorText, tLockedMessages
   put line -2 of the executioncontexts into tErrorContext
   
   # Unlock messages to ensure the errors get through to the message box
   put the lockmessages into  tLockedMessages
   unlock messages
   
   put "ERROR:" && pMessage & return & "line:" && item 3 of tErrorContext & return & "handler:" && item 2 of tErrorContext & return & "script object:" && item 1 of tErrorContext into tErrorText
   
   # If in IDE development mode output the error to the Message Box
   if gRevDevelopment is true then
      put return & tErrorText after msg
   end if
   
   # if the messages were locked, lock them again
   if tLockedMessages is true then
      lock messages
   end if
   
   return tErrorText
end __revIDEError

on ideThrow pMessage, pResult
   throw __revIDEError(pMessage & return & pResult)
end ideThrow

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
            case "scriptstatus"
               put the scriptstatus of the target into pData[tIndex][tProp]
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

on __readGroupedPropertiesOfControl pGroupsA, @pDataA
   local tPropMappingA, tProp
   repeat for each key tGroup in pGroupsA
      repeat for each key tProp in pGroupsA[tGroup]["proplist"]
         put tGroup into tPropMappingA[tProp]["group"]
      end repeat
   end repeat
   
   local tDataA
   set the itemdelimiter to ";"
   repeat for each key tKey in tPropMappingA
      if the number of items in tKey > 1 then
         repeat for each item tRealProp in tKey
            __fetchPropertyOfControl tRealProp, tDataA[tKey]
         end repeat
      else
         __fetchPropertyOfControl tKey, tDataA
      end if
   end repeat
   
   local tValue, tEffective
   set the itemdelimiter to ":"
   repeat for each key tKey in tDataA
      if tKey begins with "effective" then next repeat
      put false into tEffective
      put tDataA[tKey] into tValue
      put tPropMappingA[tKey]["group"] into tGroup
      if tValue is empty and tDataA["effective" && tKey] is not empty then
         put tDataA["effective" && tKey] into tValue
         put true into tEffective
      end if
      if pDataA[tGroup][tKey] is empty then
         put pGroupsA[tGroup]["proplist"][tKey] into pDataA[tGroup][tKey]
      end if
      put tValue into pDataA[tGroup][tKey]["value"][the long id of the target]
      put tEffective into pDataA[tGroup][tKey]["effective"][the long id of the target]
   end repeat
end __readGroupedPropertiesOfControl

private command __fetchPropertyCustomGetter pGetter, pObject, pProperty, @xPropArray
   local tEffective, tValue
   dispatch function pGetter with pObject, pProperty, tEffective
   put the result into tValue
   if tEffective then
      put tValue into xPropArray["effective" && pProperty]
      put empty into xPropArray[pProperty]
   else
      put tValue into xPropArray[pProperty]
   end if
end __fetchPropertyCustomGetter

private on __fetchPropertyOfControl pProp, @xData
   local tError
   put empty into tError
   
   local tObjID
   put the long id of the target into tObjID
   
   local tProperties
   put __classicObjectProperties(tObjID) into tProperties
   
   if tProperties["properties"][pProp]["getter"] is not empty then
      __fetchPropertyCustomGetter tProperties["properties"][pProp]["getter"], \
            tObjId, pProp, xData
      exit __fetchPropertyOfControl
   end if
   
   try
      switch pProp
         case "short name"
            put the short name of the target into xData[pProp]
            break
         case "scriptlines"
            put the number of lines of the script of the target into xData[pProp]
            break
         case "scriptstatus"
            put the scriptStatus of the target into xData[pProp]
            break
         case "behavior scriptlines"
            put the number of lines of the script of the behavior of the target into xData[pProp]
            break
         case "long id"
            put the long id of the target into xData[pProp]
            break
         case "owner"
            put the long id of the owner of the target into xData[pProp]
            break
         case "type"
            put word 1 of the name of the target into xData["type"]
            break
         case "custom control"
            if the the cIDEProperties["cCustomControl"] of the Target is "true" then
               put "true" into xData["custom control"]
            else if the dgProp["control type"] of the target is "Data Grid" then
               put "true" into xData["custom control"]            
            else
               put "false" into xData["custom control"]
            end if
            break
         default
            put the pProp of the Target into xData[pProp]
            break
      end switch
      put the short name of the target into xData["name"]
   catch tError
   end try
   
   # AL-2015-07-15: Remove 'do' construction, as evaluating the target as a string
   #  causes incorrect object references when obejcts have the same name
   if xData[pProp] is empty then
      try
         local tEffective
         put the effective pProp of the target into tEffective
         if tEffective is not empty then
            put tEffective into xData["effective" && pProp]
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
   set the itemdelimiter to ";"
   repeat for each line tProp in pList
      -- If this pseudo-property is actually multiple properties,
      -- the value is an array with keys the real property names
      if the number of items in tProp > 1 then
         repeat for each item tRealProp in tProp
            __fetchPropertyOfControl tRealProp, pData[tRealProp]
         end repeat
      else
         __fetchPropertyOfControl tProp, pData
      end if
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
            case "scriptstatus"
               put the scriptStatus of the target into tData[tProp]
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

function __customPropertyValue pLongID
   local tArray, tSets, tProps, tOldPropertySet
   put the customPropertySet of pLongID into tOldPropertySet
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
   set the customPropertySet of pLongID to tOldPropertySet
   return tArray
end __customPropertyValue

function __unescapeString pString
   --if pString contains "\n" then breakpoint
   replace "\n" with return in pString
   return pString
end __unescapeString

on revIDEFinaliseIDELibrary
   revIDEUnsubscribeAll
end revIDEFinaliseIDELibrary

on revIDEInitialiseIDELibrary
   # Load fonts
   local tFonts
   put files(revIDESpecialFolderPath("fonts")) into tFonts
   filter lines of tFonts with "*.ttf"
   repeat for each line tFont in tFonts
      start using font file (revIDESpecialFolderPath("fonts") & slash & tFont)
   end repeat
   
   # Setup the default lists of properties to read from objects when reading the structure of a stack
   put "name" & return & "visible" & return & "cantselect" & return & "layer" & return & "long id" & return & "label" & return & "behavior" & return & "scriptlines" & return & "scriptstatus" & return & "short name" & return & "owner" & return & "behavior" & return & "behavior scriptlines" & return & "type" & return & "custom control" into sControlPropertiesToRead
   put "scriptlines" & return & "scriptstatus" & return & "short name" & return & "owner" & return & "behavior" & return & "behavior scriptlines" & return & "long id" into sCardPropertiesToRead
   put "scriptlines" & return & "scriptstatus" & return & "short name" & return & "behavior" & return & "behavior scriptlines" & return & "long id" into sStackPropertiesToRead
   
   ## Load Extensions
   revInternal__LoadLibrary "revideextensionlibrary"
   
   ## Regenerate dictionary data
   revInternal__LoadLibrary "revDatabaseLibrary"
   revIDERegenerateBuiltDictionaryData
   
   ## Initialise property library
   revIDEPropertyLibraryInitialise
   
   ideSubscribe "ideExtensionsChanged"
   ideSubscribe "ideDesktopChanged"
end revIDEInitialiseIDELibrary

on ideExtensionsChanged
   revIDERegenerateBuiltDictionaryData
end ideExtensionsChanged

#############
# Subscription
#############
# Stores subscriptions in the following format
# sSubscriptions[message][callback targets] = List of object ID's
local sSubscriptions

private on __ideAddSubscription pMessage, pCallingObject
   if sSubscriptions[pMessage]["callback targets"] is empty then
      put pCallingObject into sSubscriptions[pMessage]["callback targets"]
   else if pCallingObject is not among the lines of sSubscriptions[pMessage]["callback targets"] then
      put return & pCallingObject after sSubscriptions[pMessage]["callback targets"]
   else
      return "Already subscribed"
   end if
end __ideAddSubscription

/**
Subscribes the calling object to receive the specified IDE message

pMessage (string): The message to subscribe to.

pObjectList (optional string): 
A list of objects, one per line, determining which calling objects the message should be restricted to.

Example:
on preOpenStack
   ideSubscribe "ideSelectedObjectsChanged"
end preOpenStack

on ideSelectedObjectsChanged
   # Handle the notification
end ideSelectedObjectsChanged

Example:
-- When the selection changes, subscribe to the idePropertyChanged message for the newly selected objects
on ideSelectedObjectsChanged
   ideSubscribe "idePropertyChanged", revIDESelectedObjects()
end ideSelectedObjectsChanged

Description:
Subscribe to messages to have a notification sent for particular IDE actions.

**/
on ideSubscribe pMessage, pObjectList
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
         __ideAddSubscription pMessage & "," & tObject, tCallingObjectID
      end repeat
   else if pObjectList is not empty then
      repeat for each line tObject in pObjectList
         __ideAddSubscription pMessage & "," & tObject, tCallingObjectID
      end repeat
   else
      __ideAddSubscription pMessage, tCallingObjectID
   end if
   
   if the result is not empty then
      return the result
   end if
   
   return empty
end ideSubscribe

on revIDESubscribe pMessage, pObjectList
   ideSubscribe pMessage, pObjectList
end revIDESubscribe

/**
Unsubscribes the calling object from the given message

pMessage (enum): The message to unsubscribe from. 
pObject (String): The long ID of the object you wish to unsubscribe from the message. This is an optional parameter, if not specified, the calling object will be used.
pObjectList (optional string): A list of objects, one per line.
**/
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

/**
Unsubscribes the object from all messages

pObject (String): The long ID of the object you wish to unsubscribe from all message. This is an optional parameter, if not specified, the calling object will be used.
**/
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

/**
Use to find out which messages the calling object is subscribed to.

returns (string): Return delimited list of messages, 1 per line.
**/
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

/**
Use to find out which objects are subscribed to a given message

pMessage (String): The name of the message.

returns (string): Return delimited list of object ID's, 1 per line.
**/
function revIDESubscribedObjects pMessage
   # Validate input
   if not revIDEMessageIsValid(pMessage) then
      return __revIDEError("The message ("&pMessage&") you are enquiring about is not valid. Please check the documentation for which messages you can subscribe to.")
   end if
   
   return sSubscriptions[pMessage]["callback targets"]
end revIDESubscribedObjects

/**
Use to get a list of all the messages that the IDE allows subscriptions for

returns (string): Return delimited list of message names, 1 per line.

references: revIDESubscribedObjects (function), revIDESubscriptions (function), revIDEUnsubscribe (command), revIDESubscribe (command)
**/
function revIDEMessages
   return ( \
         "ideAnswerDialogClosed,ideControlDeleted,ideCardDeleted,ideEditScript,ideExtensionLog,ideExtensionsChanged,ideExtensionStatusChanged,ideFindMoreWidgets," \
         & "ideInspectedObjectsChanged,ideLibraryStack,ideNewCard,ideNewStack,ideNewControl,revIDENameChanged,ideObjectSelectionStarted,ideOpenStack," \
         & "idePluginsChanged,idePreferenceChanged,idePropertyChanged,ideReleaseStack,ideResumeStack,ideSelectedObjectChanged,ideStackDeleted,ideToolChanged," \
         & "ideTutorialProgressChanged,ideWindowsChanged,ideMouseMove,ideDesktopChanged" \
         )
end revIDEMessages

private function revIDEMessageIsValid pMessage
   return true
   return (pMessage is among the items of revIDEMessages() \
         or pMessage begins with "idePreferenceChanged" \
         or pMessage begins with "ideInspectObjects" \
         or pMessage begins with "ideToggleChanged")
end revIDEMessageIsValid

/**
Sends the given message to all subscribed objects.

Parameters:
pMessage (string): The message to send

pTriggeringObjects (optional string):
A list, one per line, of the long ids of the objects triggering the message.
This is used for example with the <idePropertyChanged> message to
convey which objects had properties changed.

pParamsArray (array): 
A numerically keyed aray (starting at 1) of the parameters to pass along with the message.

Description:
Sends <pMessage> to all objects which have subscribed to it using
<revIDESubscribe>.

References: ideSubscribe (command), idePropertyChanged (message)
**/
on ideMessageSendWithParameters pMessage, pTriggeringObjects, pParamsArray
   lock screen
   
   # Validate input
   if not revIDEMessageIsValid(pMessage) then
      return __revIDEError("The message ("&pMessage&") you have requested to be sent is not a valid IDE message. Please check the documentation for which messages you can subscribe to.")
   end if
   
   # If in run mode don't send any updates
   //if the tool is not "pointer tool" then exit ideMessageSendWithParameters
   
   local tSubscriptionList, tTargetsA, tSubscription
   # Add all universal subscribers to the subscription list
   put sSubscriptions[pMessage]["callback targets"] into tSubscriptionList
   
   # Add any per-object subscriptions
   repeat for each line tLine in pTriggeringObjects
      put pMessage & "," & tLine into tSubscription
      repeat for each line tTarget in sSubscriptions[tSubscription]["callback targets"]
         if tSubscriptionList is empty then
            put tTarget into tSubscriptionList
         else
            put return & tTarget after tSubscriptionList
         end if
      end repeat
   end repeat
   
   # Send the message!
   set the itemdel to ":"
   local tMessage
   put item 1 of pMessage into tMessage
   
   # Construct a dispatch command with all the desired parameters
   local tDoString, tParams, tErrors
   put "dispatch tMessage to tObjectID" into tDoString
   
   # If this is a parameterised message, add the parameter as the first arg
   if the number of items of pMessage > 1 then
      put " with item 2 of pMessage" into tParams
   end if
   
   repeat with tParam = 1 to the number of elements in pParamsArray
      if tParams is empty then
         put " with pParamsArray[" & tParam & "]" into tParams
      else
         put ", pParamsArray[" & tParam & "]" after tParams
      end if
   end repeat
   put tParams after tDoString
   
   repeat for each line tObjectID in tSubscriptionList
      # if the callback object doesn't exist, don't send message
      if not exists(tObjectID) then
         revIDEUnsubscribeAll tObjectID
         next repeat
      end if
      
      # Ensure any error doesn't prevent subsequent subscribers from receiving messages
      try
         do tDoString
      catch tError
         if tErrors is empty then
            put tError into tErrors
         else
            put return & tError after tErrors
         end if
      end try
   end repeat
   unlock screen
   
   if tErrors is not empty then
      return __revIDEError("Error when sending message" && pMessage & ":" & return & tErrors)
   end if
   
   return empty
end ideMessageSendWithParameters

-- 0 or 1 param special case
on ideMessageSend pMessage, pParam
   local tParam
   if pParam is not empty then
      put pParam into tParam[1]
   end if
   ideMessageSendWithParameters pMessage, the long id of the target, tParam
end ideMessageSend

on ideMessageSendWithTrigger pMessage, pTriggeringObjects, pParam
   local tParam
   if pParam is not empty then
      put pParam into tParam[1]
   end if
   ideMessageSendWithParameters pMessage, pTriggeringObjects, tParam
end ideMessageSendWithTrigger

on revIDEMessageSend pMessage, pTriggeringObjects
   local tParamsArray
   put pTriggeringObjects into tParamsArray[1]
   ideMessageSendWithParameters pMessage, pTriggeringObjects, tParamsArray
end revIDEMessageSend

#############
# Data
#############

/**
Returns information about the predefined graphic objects.

Returns: an array, keyed by the predefined graphic object types that
appear in the Tools palette, of properties associated with each of those
graphic objects.

**/
function revIDEGraphics
   if sClassicObjectProperties is empty then __objectPropertiesRead
   
   local tReturnData
   repeat for each key tIndex in sClassicObjectProperties
      if sClassicObjectProperties[tIndex]["type"] is "graphic" then
         put sClassicObjectProperties[tIndex] into tReturnData[tIndex]
      end if
   end repeat
   return tReturnData
end revIDEGraphics

/**
Returns information about the graphic creation tools.

Returns: an array, keyed by the graphic creation tool types that appear
in the Tools palette, of properties associated with the objects created
by each of those graphic creation tools.

**/
function revIDEGraphicTools
   if sClassicObjectProperties is empty then __objectPropertiesRead
   
   local tReturnData
   repeat for each key tIndex in sClassicObjectProperties
      if sClassicObjectProperties[tIndex]["type"] is "graphic tool" then
         put sClassicObjectProperties[tIndex] into tReturnData[tIndex]
      end if
   end repeat
   return tReturnData
end revIDEGraphicTools

function revIDEGraphicToolControllers
   local tTooltip, tName, tCount, tReturnData
   add 1 to tCount
   put "com.livecode.tool.FillColor" into tName
   put "Set graphic fill color" into tTooltip
   updateOptionArray tName, "graphic fill color tool", tTooltip, tCount, tReturnData
   
   add 1 to tCount
   put "com.livecode.tool.LineColor" into tName
   put "Set graphic line color" into tTooltip
   updateOptionArray tName, "graphic line color tool", tTooltip, tCount, tReturnData
   
   add 1 to tCount
   put "com.livecode.tool.LineSize" into tName
   put "Set graphic line size" into tTooltip
   updateOptionArray tName, "graphic line size tool", tTooltip, tCount, tReturnData
   
   return tReturnData
end revIDEGraphicToolControllers

private command updatePaintToolArray pName, pTool, pTooltip, pOrder, @xArray
   put "paint tool" into xArray[pName]["type"]
   put pTool into xArray[pName]["tool"]
   put pTooltip into xArray[pName]["tooltip"]
   put pOrder into xArray[pName]["order"]
end updatePaintToolArray

private command updateOptionArray pName, pTool, pTooltip, pOrder, @xArray
   put "option" into xArray[pName]["type"]
   put pTool into xArray[pName]["tool"]
   put pTooltip into xArray[pName]["tooltip"]
   put pOrder into xArray[pName]["order"]
end updateOptionArray

/**
Returns information about the paint tools.

Returns: an array, keyed by the paint tool types that appear
in the Tools palette, of properties associated with each of
those paint tools.

**/
function revIDEPaintTools
   local tDataA
   
   local tTooltip, tName, tCount
   
   add 1 to tCount
   put "com.livecode.tool.Pencil" into tName
   put "Pencil Tool - Draw a freehand line on an image" into tTooltip
   updatePaintToolArray tName, "pencil tool", tTooltip, tCount, tDataA
   
   add 1 to tCount
   put "com.livecode.tool.Brush" into tName
   put "Brush Tool - Draw freehand brush strokes on an image" into tTooltip
   updatePaintToolArray tName, "brush tool", tTooltip, tCount, tDataA
   
   add 1 to tCount
   put "com.livecode.tool.Bucket" into tName
   put "Bucket Tool - Fill on outline in an image" into tTooltip
   updatePaintToolArray tName, "bucket tool", tTooltip, tCount, tDataA
   
   add 1 to tCount
   put "com.livecode.tool.SprayCan" into tName
   put "Spray Can Tool - Draw airbrush strokes on an image" into tTooltip
   updatePaintToolArray tName, "spray tool", tTooltip, tCount, tDataA
   
   add 1 to tCount
   put "com.livecode.tool.Polygon" into tName
   put "Polygon Tool - Click to set each point on the polygon, double click to close the polygon" into tTooltip
   updateOptionArray tName, "paint polygon shape tool", tTooltip, tCount, tDataA
   
   add 1 to tCount
   put "com.livecode.tool.Curve" into tName
   put "Curve Tool - Draws a curved line on an image" into tTooltip
   updatePaintToolArray tName, "curve tool", tTooltip, tCount, tDataA
   
   add 1 to tCount
   put "com.livecode.tool.Select" into tName
   put "Select Tool - Select a rectangle area of an image" into tTooltip
   updatePaintToolArray tName, "select tool", tTooltip, tCount, tDataA
   
   add 1 to tCount
   put "com.livecode.tool.Eraser" into tName
   put "Eraser Tool - Erase an area in an image" into tTooltip
   updatePaintToolArray tName, "eraser tool", tTooltip, tCount, tDataA
   
   return tDataA
end revIDEPaintTools

function revIDEPaintToolControllers
   local tDataA
   
   local tTooltip, tName, tCount
   add 1 to tCount
   put "com.livecode.tool.FillColor" into tName
   put "Set paint fill color" into tTooltip
   updateOptionArray tName, "paint fill color tool", tTooltip, tCount, tDataA
   
   add 1 to tCount
   put "com.livecode.tool.LineColor" into tName
   put "Set paint line color" into tTooltip
   updateOptionArray tName, "paint line color tool", tTooltip, tCount, tDataA
   
   add 1 to tCount
   put "com.livecode.tool.LineSize" into tName
   put "Set paint line size" into tTooltip
   updateOptionArray tName, "paint line size tool", tTooltip, tCount, tDataA
   
   add 1 to tCount
   put "com.livecode.tool.BrushPattern" into tName
   put "Set paint brush pattern" into tTooltip
   updateOptionArray tName, "paint brush pattern tool", tTooltip, tCount, tDataA
   
   add 1 to tCount
   put "com.livecode.tool.PolygonSides" into tName
   put "Set number of paint polygon sides" into tTooltip
   updateOptionArray tName, "paint polygon sides tool", tTooltip, tCount, tDataA
   
   return tDataA
end revIDEPaintToolControllers

/**
Returns information about the run and edit tools.

Returns: an array, keyed by the run and edit tool type IDs, 
of properties associated with each of those tools.

**/
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

/**
Returns information about the classic control tools.

Returns: an array, keyed by the classic control tool types that appear
in the Tools palette, of properties associated with each of those classic 
control tools.

**/
function revIDEClassicControls
   if sClassicObjectProperties is empty then __objectPropertiesRead
   
   local tReturnData
   repeat for each key tIndex in sClassicObjectProperties
      if tIndex is "com.livecode.interface.classic.widget" then next repeat
      if sClassicObjectProperties[tIndex]["type"] is among the items of "button,field,scrollbar,player,image,data grid" then
         put sClassicObjectProperties[tIndex] into tReturnData[tIndex]
      end if
   end repeat
   return tReturnData
end revIDEClassicControls

function revIDEWidgets
   return revIDEExtensions("widget","installed", true)
end revIDEWidgets

/**
For a given list of objects, returns a structured array of properties, values and other meta data.

pObjects (string list): A list of IDs of the objects to obtain the properties for.

Return (Array): An array of data about the objects' properties.

Example:
local tPropsArray
create button
put revIDEGetPropertiesOfObjects(it) into tPropsArray

# Get a list of the sections needed to display this object's property inspector
local tSections
put the keys of tPropsArray into tSections

Description:
<revIDEGetPropertiesOfObjects> returns an array of data about the given objects'
shared properties, in a form used by the property inspector. The array has a sub-array
for each section of the inspector in which one of the shared properties falls. Each of
these sub-arrays has a sub-array for each group within the section in which one of the
shared properties falls, each of which in turn has a sub-array for each property,
containing the values and metadata associated with it.
**/
function revIDEGetPropertiesOfObjects pObjects
   # Validation that all the objects in the list exist
   repeat for each line tObject in pObjects
      if not exists(tObject) then return __revIDEError("Not all objects in the list provided exist")
   end repeat
   
   # Work out the type of the selected objects
   local tObjectTypeList
   put ideObjectTypesFromObjectList(pObjects) into  tObjectTypeList
   
   # Get this list of all the properties to read for the given type list
   local tSharedProperties
   put __objectPropertiesShared(tObjectTypeList, true) into tSharedProperties
   
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

/**
Use to get a complete list of all editable stacks in the IDE.

returns (String): A return delimited list of stack names
**/
function revIDEEditableStacks
   local tEditableStacks
   repeat for each line tStack in the openstacks
      if the mode of stack tStack is 1 and \
            the visible of stack tStack is true then
         if tEditableStacks is empty then
            put tStack into tEditableStacks
         else
            put return & tStack after tEditableStacks
         end if
      end if
   end repeat
   return tEditableStacks
end revIDEEditableStacks

/**
Use to get a list of of all the global variables.

returns (list): A comma delimited list of global variable names
**/
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
   return URL("file:" & revIDESpecialFolderPath("globals") & slash & "globalProperties.txt")
end revIDEGlobalProperties

local sRangeArray
function revIDEGlobalPropertyRange pProperty
   if sRangeArray is empty then
      local tRangeArray, tLine
      put URL("file:" & revIDESpecialFolderPath("globals") & slash & "rangeArray.txt") into tRangeArray
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
      put URL("file:" & revIDESpecialFolderPath("globals") & slash & "continuousArray.txt") into tContinuousArray
      set the itemdel to tab
      
      repeat for each line tLine in tContinuousArray
         replace comma with return in item 2 of tLine
         put item 2 of tLine into sContinuousRangeArray[item 1 of tLine]
      end repeat
   end if
   return sContinuousRangeArray[pProperty]
end revIDEGlobalPropertyContinuousRange

/**
Used by the PI to make a substack into a mainstack
**/
command revIDEMakeSubstackMainstack pObj
   set the mainstack of pObj to the short name of pObj
end revIDEMakeSubstackMainstack

/**
A list of the current mainstacks

Returns: A list of the names of the mainstacks currently in memory, one per line

Description:
Use the <ideMainStacks> function to retrieve a list of the names of the mainstacks
in memory, taking into account the Show IDE Stacks preference.
**/
function ideMainStacks
   local tShowIDEStacks
   put revIDEGetPreference("cShowRevolutionStacks") into tShowIDEStacks
   
   if tShowIDEStacks then
      return the mainstacks
   else
      return ideUserMainStacks()
   end if
end ideMainStacks

/**
A list of the current user mainstacks

Returns: A list of the names of the user mainstacks currently in memory, one per line

Description:
Use the <ideUserMainStacks> function to retrieve a list of the names of the mainstacks
in memory, excluding those which are part of the IDE.

See the <revIDEStackNameIsIDEStack> function for details of when a stack is considered
part of the IDE.

References: revIDEStackNameIsIDEStack (function)
**/
function ideUserMainStacks
   return __ideRemoveIDEStackNamesFromList(the mainstacks)
end ideUserMainStacks

private function __ideRemoveIDEStackNamesFromList pStackNames
   local tFiltered
   repeat for each line tName in pStackNames
      if revIDEStackNameIsIDEStack(tName) then next repeat
      if tFiltered is empty then
         put tName into tFiltered
      else
         put return & tName after tFiltered
      end if
   end repeat
   return tFiltered
end __ideRemoveIDEStackNamesFromList

private function __ideFilterStackNameListWithPreference pStackNames
   # Are IDE stacks required
   local tShowIDEStacks
   put revIDEGetPreference("cShowRevolutionStacks") into tShowIDEStacks
   
   if tShowIDEStacks then
      return pStackNames
   end if
   
   return __ideRemoveIDEStackNamesFromList(pStackNames)
end __ideFilterStackNameListWithPreference

private function __ideRemoveIDEObjectIDsFromList pObjectList
   local tFiltered
   repeat for each line tID in pObjectList
      if revIDEObjectIsOnIDEStack(tID) then next repeat
      if tFiltered is empty then
         put tID into tFiltered
      else
         put return & tID after tFiltered
      end if
   end repeat
   return tFiltered
end __ideRemoveIDEObjectIDsFromList

private function __ideFilterObjectIDListWithPreference pObjectList
   # Are IDE stacks required
   local tShowIDEStacks
   put revIDEGetPreference("cShowRevolutionStacks") into tShowIDEStacks
   
   if tShowIDEStacks then
      return pObjectList
   end if
   
   return __ideRemoveIDEObjectIDsFromList(pObjectList)
end __ideFilterObjectIDListWithPreference

function revIDEStacksForDataView pIndex
   local tSortType, tSortOrder
   revIDEGetPBSortPreferences "pb_stackSort", tSortType, tSortOrder
   
   # Get list of stacks to display
   local tMainStacks, tInvertedMainStacks
   
   put ideMainStacks() into tMainStacks
   if tSortType is "name" then
      if tSortOrder is "ascending" then
         sort lines of tMainStacks ascending
      else
         sort lines of tMainStacks descending
      end if
   else
      if tSortOrder is "ascending" then
         ## No nothing this is the correct order
      else 
         repeat with x = the number of lines in tMainStacks down to 1
            put line x of tMainStacks & return after tInvertedMainStacks
         end repeat
         delete the last line of tMainStacks
         put tInvertedMainStacks into tMainStacks
      end if
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
   # Get list of stacks to display
   local tMainStacks
   put __ideFilterStackNameListWithPreference(the mainstacks) into tMainStacks
   
   # Recurse through the stacks to get their data
   local tStacksData, tCount
   put 1 into tCount
   repeat for each line tStack in tMainStacks
      put empty into tStacksData[tCount]
      dispatch function "__readStructureOfStack" to stack tStack with tStacksData[tCount]
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
   # If IDE elements are on not showing, filter the list for rev stacks
   local tFrontScripts
   put __ideFilterObjectIDListWithPreference(the frontscripts) into tFrontScripts
   
   # Create the list of properties to retrieve
   local tProperties
   put "short name" & return & "scriptlines" & return & "scriptstatus" & return & "long id" into tProperties
   
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
   # Get the list of backscripts
   # If IDE elements are on not showing, filter the list for rev stacks
   local tBackScripts
   put __ideFilterObjectIDListWithPreference(the backscripts) into tBackScripts
   
   # Create the list of properties to retrieve
   local tProperties
   put "short name" & return & "scriptlines" & return & "scriptstatus" & return & "long id" into tProperties
   
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
   put __ideFilterStackNameListWithPreference(the stacksInUse) into tStacksInUse
   
   # Create the list of properties to retrieve
   local tProperties
   put "short name" & return & "scriptstatus" & return & "scriptlines" into tProperties
   
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

function revIDEStackIsIDEWindow pStackName
   if pStackName begins with revIDEScriptEditorPrefix() or pStackName is "revDictionary" \
         or pStackName is "revResourceCenter" or pStackName is "revOnline" then
      return true
   end if
   
   return false
end revIDEStackIsIDEWindow

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
   if the pPreferenceName of stack "revpreferences" is not pValue then
      set the pPreferenceName of stack "revpreferences" to pValue
      revInternal__SavePreferences
      ideMessageSend "idePreferenceChanged:" & pPreferenceName,pValue
   end if
end revIDESetPreference

command revIDESetPreferenceOfSet pSetName, pPreferenceName, pValue
   local tProps
   put the customproperties[pSetName] of stack "revpreferences" into tProps
   put pValue into tProps[pPreferenceName]
   set the customproperties[pSetName] of stack "revpreferences" to tProps
   revInternal__SavePreferences
   local tParams
   put pSetName into tParams[1]
   put pPreferenceName into tParams[2]
   put pValue into tParams[3]
   ideMessageSendWithParameters "idePreferenceOfSetChanged", "", tParams
end revIDESetPreferenceOfSet

command revIDEDeletePreferenceSet pSetName
   local tSets, tLineOffset
   put the custompropertysets of stack "revpreferences" into tSets
   put lineOffset(pSetName, tSets) into tLineOffset
   if tLineOffset is not 0 then
      delete line tLineOffset of tSets
      set the customPropertySets of stack "revpreferences" to tSets
      revInternal__SavePreferences
   end if
end revIDEDeletePreferenceSet

/*
Gets a preference.

pPreferenceName (String): The name of the preference
tags: preferences
Example: set the textsize of field 1 to revIDEGetPreference("text size")
Returns (Any): The value of the preference
*/
function revIDEGetPreference pPreferenceName
   local tValue
   
   __DevPreference pPreferenceName, tValue
   
   if tValue is empty and there is a stack "revPreferences" then
      put the pPreferenceName of stack "revPreferences" into tValue
   end if
   
   if pPreferenceName is "cScriptEditor,editor,font" and \
         tValue is empty and \
         "Source Code Pro" is among the lines of the fontNames then
      return "Source Code Pro"
   end if
   
   return tValue
end revIDEGetPreference

function revIDEGetPreferenceOfSet pSetName, pPreferenceName
   local tProps
   put the customproperties[pSetName] of stack "revpreferences" into tProps
   return tProps[pPreferenceName]
end revIDEGetPreferenceOfSet

command __DevPreference pPreferenceName, @rValue
   if not revEnvironmentIsInstalled() then
      switch pPreferenceName
         case "cScriptEditor,explicitVariables"
         case "cScriptEditor,preserveVariables"
            put true into rValue
            break
         case "cScriptEditor,editor,commentchar"
            put "--" into rValue
            break
         case "cScriptEditor,editor,tabdepth"
            put 3 into rValue
            break
      end switch
      
   end if
end __DevPreference

function revIDEPreferences
   return the customproperties of stack "revpreferences"
end revIDEPreferences

function revIDEPreferenceNames
   local tPreferenceNames
   repeat for each key tKey in (the customproperties of stack "revpreferences")
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

/*
The IDE uses a number of referenced images as icons, to ensure these images do not clash with user images IDs in the reserved range are assigned. The reserved range is 101000 to 103000

Returns (integer): The next available ID in the reserved range.
*/

constant kFirstReservedIconID = 101000

function revIDENewIconID
   local tNextIconID, tIDList
   
   put the ID stack "revTools" & comma into tIDList
   put the ID of stack "revMenubar" & comma after tIDList
   put the ID of stack "revIDELibrary" & comma after tIDList
   put kFirstReservedIconID after tIDList
   
   put max(tIDList) + 1 into tNextIconID
   return tNextIconID
end revIDENewIconID

function revIDEThemePath
   # Get the platform and system version
   local tPlatformName, tSystemVersion
   put revIDEPlatform() into tPlatformName
   put revIDEPlatformVersion() into tSystemVersion
   
   # Find nearest theme version for the given platform
   revIDEPushDefaultFolder revIDESpecialFolderPath("themes")
   
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
   
   revIDEPopDefaultFolder
   
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
   if pTag is "edition_color" then
      return revEnvironmentEditionProperty("color")
   end if
   
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
      case "dataView_scriptErrorBackgroundColor"
         return "255,0,0"
         break
      case "dataView_disclosureIconColor"
         return "99,99,99"
         break         
      case "dataView_disclosureIconHiliteColor"
         return "216,216,216"
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

/**
The parent stack of an object

pLongID: The long id of an object
Returns: the long id of the parent stack of <pLongID>

Description:
Returns the long id of the (immediate) parent stack of the object with long id <pLongID>.
To retrieve the mainstack of an object, use the <ideMainStackOfObject> function.

References: ideMainStackOfObject (function)
**/
function ideStackOfObject pLongID
   local tOffset
   put wordOffset("stack",pLongID) into tOffset
   return word tOffset to -1 of pLongID
end ideStackOfObject

/**
The mainstack containing an object

pLongID: The long id of an object
Returns: the long id of the mainstack containing <pLongID>

Description:
Returns the long id of the mainstack of the object with long id <pLongID>.
To retrieve the immediate parent stack of an object which may be a substack, 
use the <ideStackOfObject> function.

References: ideStackOfObject (function)
**/
function ideMainStackOfObject pLongID
   local tStack
   put ideStackOfObject(pLongID) into tStack
   if word 4 of tStack is "stack" then
      put ideMainStackOfObject(word 4 to -1 of tStack) into tStack
   end if
   return tStack
end ideMainStackOfObject

function revIDEStackOfObject pLongID
   return ideStackOfObject(pLongID)
end revIDEStackOfObject

on revIDEMoveControl pControl, pNewCard, pLayerNumber
   local tNewControl
   lock messages
   copy pControl to pNewCard
   put the long id of it into tNewControl
   
   delete pControl
   
   try
      revIDESetPropertyOfObject tNewControl, "layer", pLayerNumber
   catch pError
   end try
   unlock messages
   return tNewControl
end revIDEMoveControl

command revIDEUpdatePBPreferences
   ## Map pre LC8 preferences to LC8 preferences
   if revIDEGetPreference("pb_indicator") is empty then
      revIDESetPreference "pb_indicator","icon"
   end if
   
   if revIDEGetPreference("pb_sections") is empty then
      revIDESetPreference "pb_sections","Stacks"
   end if
   
   local tOldSortType,tOldSortOrder
   put revIDEGetPreference("ideProjectBrowser_sort") into tOldSortType
   put revIDEGetPreference("ideProjectBrowser_sortOrder") into tOldSortOrder
   if tOldSortOrder is empty then put "bottom to top" into tOldSortOrder
   
   local tSortOrder
   if tOldSortOrder is "bottom to top" then
      put "Ascending" into tSortOrder
   else
      put "Descending" into tSortOrder
   end if
   
   local tSortType
   if tOldSortType is empty then
      put "Name" into tSortType
   else
      put tOldSortType into tSortType
   end if
   
   if revIDEGetPreference("pb_stackSort") is empty then
      ## We can assume none of the new Project Browser prefs are set      
      revIDESetPBSortPreferences "pb_stackSort", tSortType, tSortOrder
   end if
   
   -- Layer should be default for cards and controls
   if tOldSortType is empty then
      put "Layer" into tSortType
   end if
   
   if revIDEGetPreference("pb_cardSort") is empty then
      ## We can assume none of the new Project Browser prefs are set      
      revIDESetPBSortPreferences "pb_cardSort", tSortType, tSortOrder
   end if
   
   if revIDEGetPreference("pb_controlSort") is empty then
      ## We can assume none of the new Project Browser prefs are set      
      revIDESetPBSortPreferences "pb_controlSort", tSortType, tSortOrder
   end if
   
   if revIDEGetPreference("pb_textSize") is empty then
      revIDESetPreference "pb_textSize", "default"
   end if
end revIDEUpdatePBPreferences

command revIDEGetPBSortPreferences pPref, @rSortType, @rSortOrder
   local tPreference
   put revIDEGetPreference(pPref) into tPreference
   if tPreference is empty then
      revIDEUpdatePBPreferences
      put revIDEGetPreference(pPref) into tPreference
   end if
   
   put word 1 of tPreference into rSortType
   put word -1 of tPreference into rSortOrder
end revIDEGetPBSortPreferences

command revIDESetPBSortPreferences pPref, pSortType, pSortOrder
   revIDESetPreference pPref, pSortType && "-" && pSortOrder
end revIDESetPBSortPreferences

function revIDEStackProperties pStackID, pLevel
   if not exists(pStackID) then return __revIDEError("You must specify an object to read from." &&  quote & pStackID & quote && "is not an object")
   
   local tStackArray
   
   dispatch function "__readPropertiesOfControl" to pStackID with sStackPropertiesToRead, tStackArray
   --put the result into tStackArray
   if word 3 of pStackID is "of" then
      put "substack" into tStackArray["type"]
   else
      put "stack" into tStackArray["type"]
   end if
   put "container" into tStackArray["style"]
   put pLevel into tStackArray["level"]
   put the number of lines in the cardIDs of pStackID into tStackArray["childCount"]
   if tStackArray["childCount"] is 0 then put 1 into tStackArray["childCount"]
   return tStackArray
end revIDEStackProperties

function revIDECardPropertiesOfStack pStackID, pLevel
   local tCardID, tCardArray, tIndex,tCardIDs
   local tSubStackIDs, tSubstack, tSortedChildControlListIndexA
   local tSortType, tSortOrder
   
   revIDEGetPBSortPreferences "pb_cardSort", tSortType, tSortOrder
   
   put the cardIDs of stack pStackID into tCardIDs
   
   put  __createSortedControlsArray (pStackID, tCardIDs, tSortType, tSortOrder) into tSortedChildControlListIndexA
   
   repeat with x = 1 to the number of elements of tSortedChildControlListIndexA
      put tSortedChildControlListIndexA[x]["controlID"] into tCardID
      add 1 to tIndex
      dispatch function "__readPropertiesOfControl" to card id tCardID of pStackID with sCardPropertiesToRead, tCardArray[tIndex]
      put "card" into tCardArray[tIndex]["type"]
      put "container" into tCardArray[tIndex]["style"]
      put pLevel+1 into tCardArray[tIndex]["level"]
      put the number of lines in the childControlIDs of card id tCardID of pStackID into tCardArray[tIndex]["childCount"]
   end repeat
   
   ## Substacks
   local tSubStacks, tSubstacksList, tStackName
   
   ## Sort the substacks as per preferences
   revIDEGetPBSortPreferences "pb_stackSort", tSortType, tSortOrder
   
   set the itemDel to tab
   put the substacks of stack pStackID into tSubStacks
   repeat with x = 1 to the number of lines in tSubStacks
      put x & tab & line x of tSubStacks & return after tSubStacksList
   end repeat
   delete the last character of tSubStacks
   
   if tSortType is "name" then
      if tSortOrder is "ascending" then
         sort lines of tSubStacksList ascending by item 2 of each
      else
         sort lines of tSubStacksList descending by item 2 of each
      end if
   else
      if tSortOrder is "ascending" then
         sort lines of tSubStacksList ascending numeric by item 1 of each
      else
         sort lines of tSubStacksList descending numeric by item 1 of each
      end if
   end if
   
   repeat for each line tSubStack in tSubStacksList
      add 1 to tIndex
      put item 2 of tSubStack into tStackName
      
      dispatch function "__readPropertiesOfControl" to stack tStackName of pStackID with sStackPropertiesToRead, tCardArray[tIndex]
      put "substack" into  tCardArray[tIndex]["type"]
      put "container" into  tCardArray[tIndex]["style"]
      put pLevel+1 into  tCardArray[tIndex]["level"]
      put the number of lines in the cardIDs of stack tStackName of pStackID into  tCardArray[tIndex]["childCount"]
      if  tCardArray[tIndex]["childCount"] is 0 then put 1 into  tCardArray[tIndex]["childCount"]
   end repeat
   
   return tCardArray
end revIDECardPropertiesOfStack

function __createSortedControlsArray pParentObject, pChildControls, pSortType, pSortOrder
   local tChildCount, tChildControlListA, tChildControlListIndexA, tNextIndex, tSortedChildControlListIndexA
   -- create the array
   put 1 into tChildCount
   
   if pParentObject begins with "stack" then
      repeat with x = 1 to the number of cards of stack pParentObject
         put x into tChildControlListA["layer"]
         put the short name of card x of stack pParentObject into tChildControlListA["short name"]
         put the id of card x of stack pParentObject into tChildControlListA["controlID"]
         put tChildControlListA into tChildControlListIndexA[tChildCount]
         add 1 to tChildCount
      end repeat
   else -- parent is a card or a group
      repeat for each line tControlID in pChildControls
         put the layer of control id tControlID of pParentObject into tChildControlListA["layer"]
         put the short name of control id tControlID of pParentObject into tChildControlListA["short name"]
         put tControlID into tChildControlListA["controlID"]
         put tChildControlListA into tChildControlListIndexA[tChildCount]
         add 1 to tChildCount
      end repeat
   end if
   
   -- sort the array
   get the keys of tChildControlListIndexA
   if pSortType is "name" then
      if pSortOrder is "ascending" then
         sort lines of it ascending by tChildControlListIndexA[each]["short name"]
      else
         sort lines of it descending by tChildControlListIndexA[each]["short name"]
      end if
   else --tSortType is "layer"
      if pSortOrder is "ascending" then
         sort lines of it ascending numeric by tChildControlListIndexA[each]["layer"]
      else
         sort lines of it descending numeric by tChildControlListIndexA[each]["layer"]
      end if
   end if
   split it by return
   put 1 into tNextIndex
   repeat for each element tIndex in it
      put tChildControlListIndexA[tIndex] into tSortedChildControlListIndexA[tNextIndex]
      add 1 to tNextIndex
   end repeat
   
   return tSortedChildControlListIndexA
end __createSortedControlsArray

function revIDEControlPropertiesOfCard pCardID, pLevel
   local tChildControls, tControlArray, tIndex, tFullArray
   local tSortedChildControlListIndexA, tControlID
   local tSortType,tSortOrder
   
   ## Sort controls as per preferences
   revIDEGetPBSortPreferences "pb_controlSort", tSortType, tSortOrder
   
   -- If controls are sorted by name, present them as a flat list
   if tSortType is name then
      put the controlIDs of pCardID into tChildControls
   else
      put the childcontrolIDs of pCardID into tChildControls
   end if
   
   put  __createSortedControlsArray (pCardID, tChildControls, tSortType, tSortOrder) into tSortedChildControlListIndexA
   
   repeat with x = 1 to the number of elements of tSortedChildControlListIndexA
      put tSortedChildControlListIndexA[x]["controlID"] into tControlID
      
      add 1 to tIndex
      put empty into tControlArray
      dispatch function "__readPropertiesOfControl" to control id tControlID of pCardID with sControlPropertiesToRead, tControlArray
      
      put tControlArray["type"] && "id" && tControlID && "of" && pCardID into tControlArray["long id"]
      
      if tControlArray["type"] is "group" then
         if tControlArray["custom control"] is true then
            put "control" into tControlArray["style"]
            put "Custom control" into tControlArray["type"]
         else
            if tSortType is "name" then
               put 0 into tControlArray["childCount"]
               put "control" into tControlArray["style"]
            else
               put "group" into tControlArray["style"]
               put the number of controls of control id tControlID of pCardID into tControlArray["childCount"]
            end if
         end if
      else
         put "control" into tControlArray["style"]
      end if
      
      put pLevel+1 into tControlArray["level"]
      put tControlArray into tFullArray[tIndex]
   end repeat
   return tFullArray
end revIDEControlPropertiesOfCard

function revIDEControlPropertiesOfGroup pGroupID, pLevel
   local tControlArray, tIndex, tControlID
   local tChildControls, tSortedChildControlListIndexA
   local tSortType,tSortOrder
  
  ## Sort controls as per preferences
   revIDEGetPBSortPreferences "pb_controlSort", tSortType, tSortOrder
   
   put  the childcontrolIDs of pGroupID into tChildControls
   
   put  __createSortedControlsArray (pGroupID, tChildControls, tSortType, tSortOrder) into tSortedChildControlListIndexA
  
   repeat with x = 1 to the number of elements of tSortedChildControlListIndexA
      put tSortedChildControlListIndexA[x]["controlID"] into tControlID
      add 1 to tIndex
      dispatch function "__readPropertiesOfControl" to control id tControlID of pGroupID with sControlPropertiesToRead, tControlArray[tIndex]
      
      if tControlArray[tIndex]["type"] is "group" then
         put "group" into tControlArray[tIndex]["style"]
         put the number of controls of control id tControlID of pGroupID into tControlArray[tIndex]["childCount"]
      else
         put "control" into tControlArray[tIndex]["style"]
      end if
      
      put tControlArray[tIndex]["type"] && "id" && tControlID && "of" && pGroupID into tControlArray[tIndex]["long id"]
      
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
      put the scriptStatus of Audioclip tClip of pStack into tAudioClipArray[tClip]["scriptstatus"] 

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
      put the number of lines in  the script of videoclip tClip of pStack into tVideoClipArray[tClip]["scriptlines"]
      put the scriptStatus of videoclip tClip of pStack into tVideoClipArray[tClip]["scriptstatus"]
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
   local tSelobj
   put the selobj into tSelobj
   switch
      case the cREVLinked of this stack is not empty
         return the cREVLinked of this stack
         break
      case tSelobj is empty
         if the mode of the topStack is 1
         then return the long name of the topStack
         else return empty
         break
      default
         return tSelobj
         break
   end switch
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

on revIDEActionCreateObject pObjectTypeID
   revIDECreateObject pObjectTypeID, the topStack, the loc of this card of the topStack
end revIDEActionCreateObject

private command __setPropertiesToDefaults pObjectID, pPropsInfoA
   # Set all the properties to their default
   if pPropsInfoA["style"]["default"] is not empty and pPropsInfoA["style"]["default"] is not "no_default" then
      revIDESetPropertyOfObject pObjectID, "style", pPropsInfoA["style"]["default"] 
   end if
   
   local tPropInfoA
   repeat for each key tProperty in pPropsInfoA
      put pPropsInfoA[tProperty] into tPropInfoA
      if "default" is not among the keys of tPropInfoA then next repeat
      if tPropInfoA["default"] is "no_default" then next repeat
      if tPropInfoA["read_only"] is true then next repeat
      __setPropertyOfObject pObjectID, tProperty, tPropInfoA["default"]
   end repeat
end __setPropertiesToDefaults

private command  __setSizeToPreference pObjectID, pObjectType  
   local tWidthPref, tHeightPref
   switch pObjectType 
      case "com.livecode.interface.classic.Button"
      case "com.livecode.interface.classic.DefaultButton"
      case "com.livecode.interface.classic.RectangleButton"
         put "cButtonWidth" into tWidthPref
         put "cButtonHeight" into tHeightPref
         break
      case "com.livecode.interface.classic.TabPanel"
         put "cTabButtonWidth" into tWidthPref
         put "cTabButtonHeight" into tHeightPref
         break
      case "com.livecode.interface.classic.TableField"
      case "com.livecode.interface.classic.ListField"
      case "com.livecode.interface.classic.TextArea"
         put "cFieldWidth" into tWidthPref
         put "cFieldHeight" into tHeightPref
         break
      case "com.livecode.interface.classic.Field"
      case "com.livecode.interface.classic.LabelField"
         put "cLabelFieldWidth" into tWidthPref
         put "cLabelFieldHeight" into tHeightPref
         break
      case "com.livecode.interface.classic.OptionMenu"
      case "com.livecode.interface.classic.PulldownMenu"
      case "com.livecode.interface.classic.ComboBox"
      case "com.livecode.interface.classic.PopupMenu"
         put "cMenuWidth" into tWidthPref
         put "cMenuHeight" into tHeightPref
         break
      case "com.livecode.interface.classic.RegularGraphic"
      case "com.livecode.interface.classic.OvalGraphic"
      case "com.livecode.interface.classic.RoundRectGraphic"
      case "com.livecode.interface.classic.RectangleGraphic"
         put "cREVGraphicWidth" into tWidthPref
         put "cREVGraphicHeight" into tHeightPref
         break
      case "com.livecode.interface.classic.Image"
         put "cREVImageWidth" into tWidthPref
         put "cREVImageHeight" into tHeightPref
         break
      case "com.livecode.interface.classic.Player"
         put "cREVPlayerWidth" into tWidthPref
         put "cREVPlayerHeight" into tHeightPref
         break
      case "com.livecode.interface.classic.Progressbar"
         if the platform is "MacOS" then         
            put "cScrollbarWidth" into tWidthPref
            put "cMacOSProgressScrollbarHeight" into tHeightPref
         else
            put "cScrollbarWidth" into tWidthPref
            put "cScrollbarHeight" into tHeightPref
         end if
         break
      case "com.livecode.interface.classic.Slider"
         put "cScrollbarWidth" into tWidthPref
         put "cScrollbarHeight" into tHeightPref
         break
      case "com.livecode.interface.classic.Scrollbar"
         if the platform is "MacOS" then
            put "cScrollbarWidth" into tWidthPref
            put "cMacOSScrollbarHeight" into tHeightPref
         else
            put "cScrollbarWidth" into tWidthPref
            put "cScrollbarHeight" into tHeightPref
         end if
         break
      default
         ## For any other controls the defaults are used
         break
   end switch
   
   local tHeight, tWidth
   if tWidthPref is not empty then
      put revIDEGetPreference(tWidthPref) into tWidth
   end if
   if tHeightPref is not empty then
      put revIDEGetPreference(tHeightPref) into tHeight
   end if
   
   if tWidth is a number then
      set the width of pObjectID to tWidth
   end if
   if tHeight is a number then
      set the height of pObjectID to tHeight
   end if
end __setSizeToPreference

private function __objectTypeIsControl pObjectTypeID
   switch pObjectTypeID
      case "com.livecode.interface.classic.Stack"
      case "com.livecode.interface.classic.Substack"
      case "com.livecode.interface.classic.Card"
         return false
      default
         return true
   end switch
end __objectTypeIsControl

on revIDECreateObject pObjectTypeID, pTarget, pLoc
   if not __objectTypeIsControl(pObjectTypeID) then
      return __revIDEError("Object must be a control")
   end if
   
   if not exists(pTarget) then return __revIDEError("Cannot create object. Target does not exist: " && pTarget)
   if not pObjectTypeID begins with "com.livecode" then return __revIDEError("No such object type ID: " && pTarget)
   
   if sClassicObjectProperties is empty then __objectPropertiesRead
   # Set the default stack to the target we're creating the object on
   set the defaultstack to revIDEStackOfObject(pTarget)
   
   if pLoc is empty then
      put the loc of this card of the defaultStack into pLoc
   end if
   
   # Create the object
   lock screen
   lock messages
   
   local tPropInfoA, tObjPropsA
   # Get the engine control type
   if pObjectTypeID begins with "com.livecode.interface.classic" then
      local tCreatedControlID
      # Create data grid
      if pObjectTypeID begins with "com.livecode.interface.classic.DataGrid" then
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
      
      put sClassicObjectProperties[pObjectTypeID]["properties"] into tObjPropsA
   else
      # Not a classic control
      try
         if pObjectTypeID is "com.livecode.widget.native.map" and the platform is "MacOS" and (revIDEPlatformVersion() begins with "10.9" or revIDEPlatformVersion() begins with "10.10") then
            local tMessage
            put "The Mac MapKit API is supported from OS X 10.9 onwards, but Apple restricts use of the API on 10.9 and 10.10 to apps which are distributed from the Mac AppStore with an appropriate entitlement. " & \
                  "Due to this, general use of the Map widget only supports OS X 10.11 onwards. " & CR & CR & \  
                  "However, you can still create a standalone with the Map widget on OSX 10.9 or 10.10 (of course you will see an empty grid rather than the actual map), " & \
                  " BUT this standalone will run as expected on OSX 10.11 and above." into tMessage
            
            answer warning revIDELocalise(tMessage) with "Cancel" and "Continue"
            if it is "Cancel" then exit revIDECreateObject
         end if
         
         create widget as pObjectTypeID
         put the long id of the last control into tCreatedControlID
         
         put revIDEExtensionProperties(pObjectTypeID, false) into tObjPropsA
         union tObjPropsA with sClassicObjectProperties["com.livecode.interface.classic.widget"]["properties"]
         
         local tSize
         put revIDEExtensionProperty(pObjectTypeID, "preferredsize") into tSize
         if tSize is not empty then
            put item 1 of tSize into tObjPropsA["width"]["default"]
            put item 2 of tSize into tObjPropsA["height"]["default"]
         end if
      catch tError
         return false
      end try
   end if
   
   __setPropertiesToDefaults tCreatedControlID, tObjPropsA
   
   ## Set the size of the object to the size set in the Preferences
   __setSizeToPreference tCreatedControlID, pObjectTypeID
   
   set the loc of tCreatedControlID to pLoc
   
   unlock messages
   unlock screen
   
   ## Prevent passing of ideNewControl message for objects created on IDE stacks
   if revIDEObjectIsOnIDEStack(tCreatedControlID) is false then
      // AL-2015-04-08: [[ Bug 14822 ]] Ensure 'edited' status of stack is set
      revIDESetEdited the short name of this stack
      ideMessageSend "ideNewControl", tCreatedControlID
   end if
   
   return tCreatedControlID
end revIDECreateObject

on revIDECloneObject pLongID
   if not exists(pLongID) then return __revIDEError("Cannot create object. Target does not exist:" && pLongID)
   
   if word 1 of pLongID is "card" or word 1 of pLongID is "stack" then
      clone pLongID
   else
      local tTarget, tLoc, tControlType
      local tCreatedControlID
      
      put the loc of pLongID into tLoc
      add 20 to item 1 of tLoc
      add 20 to item 2 of tLoc
            
      clone pLongID
      put it into tCreatedControlID
      set the loc of tCreatedControlID to tLoc
   end if
end revIDECloneObject

on revIDECloneObjectWithDefaults pLongID
   local tTarget, tLoc, tControlType

   put the loc of pLongID into tLoc
   add 20 to item 1 of tLoc
   add 20 to item 2 of tLoc

   put revIDECardOfObject(pLongID) into tTarget
   if not exists(tTarget) then return __revIDEError("Cannot create object. Target does not exist:" && tTarget)

   local tOriginalObjectType
   put ideObjectTypeFromObject(pLongID) into  tOriginalObjectType
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
   repeat for each key tProperty in sClassicObjectProperties[tOriginalObjectType]["properties"]
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
   local tSelobj
   put the selobj into tSelobj
   
   if tSelobj is empty then
      exit revIDEActionGroupObjects
   end if
   
   revIDEGroupObjects tSelobj
   
   if the result is empty and exists(it) then
      select it
   else
      beep
   end if
end revIDEActionGroupObjects

/**

Name: revIDEGroupObjects

Type: command

Syntax: revIDEGroupObjects <objectList>

Summary: Group a list of objects in their layer order

Description:
Group a list of objects in the order they are layered in

Parameters:
objectList (string): A return delimited list of long object IDs

The result:
An error string

It:
The new group long ID or empty in the case the group could not be created

**/
on revIDEGroupObjects pObjectIDs
   filter lines of pObjectIDs without empty
   
   if pObjectIDs is empty then
      return "No objects" for error
   end if
   
   local tObject
   repeat for each line tObject in pObjectIDs
      if not exists(tObject) then
         return "Object does not exist" for error
      end if
   end repeat
   
   sort lines of pObjectIDs numeric by the layer of each
   
   lock screen
   
   replace return with " and " in pObjectIDs
   
   local tError
   try
      do "group " & pObjectIDs
   catch tError
      return "Could not group objects" for error
   end try
   
   unlock screen
   
   return it for value
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
end revIDESetTool

/*
Sets the property of each object in the list to the value specified

pObjects (String): A list, one per line, of the long IDs of the target objects
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

command revIDEInspectObjects pObjects
   lock screen
   
   revIDEOpenPalette "inspector"

   ideMessageSend "ideInspectObjects", pObjects
   unlock screen
end revIDEInspectObjects

function revIDEInspectorForObject pObjectId
   local tInspectorName
   dispatch function "inspectorForObject" to stack revIDEPaletteToStackName("inspector") with pObjectID
   put the result into tInspectorName
   if there is a stack tInspectorName then
      return the long id of stack tInspectorName
   end if
   return empty
end revIDEInspectorForObject

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
   # Don't try and edit the script of non-existent objects 
   if not exists(pObject) then
      exit revIDEEditScriptOfObject
   end if
   
   # Send the ideEditScript message
   send "ideMessageSend ideEditScript","pObject" to stack "revIDELibrary" in 0 milliseconds

   # First obtain a correct object reference. The reason for this is edit group mode
   local tObject
   put revRuggedId(pObject) into tObject
   
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
      send "revSESetCurrentObject tObject" to stack tExistingEditor
      toplevel stack tExistingEditor
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

on revIDEShowInProjectBrowser pObjects
   lock screen
   if the mode of stack revIDEPaletteToStackName("project browser") is 0 then
      revIDEOpenPalette("project browser")
   end if
   revIDEMessageSend "ideShowInProjectBrowser", pObjects
   unlock screen
end revIDEShowInProjectBrowser

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
   local tOldLockMessages
   put the lockMessages into tOldLockMessages
   lock messages
   try
      replace return with " AND " in pObjects
      do "select" && pObjects
   catch tError
      
   end try
   set the lockMessages to tOldLockMessages
   
   send "ideMessageSend" && "ideSelectedObjectChanged" to me in 0 milliseconds
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

on revIDEAlignControlsFromPI pObjects, pProperty, pValue
   switch pProperty
      case "equalize"
         revIDEEqualizeControls pObjects, pValue
         break
      case "align"
         revIDEAlignControls pObjects, pValue
         break
      case "alignCenter"
         revIDECenterControls pObjects, pValue
         break
      case "distribute"
         revIDEDistributeControls pObjects, pValue["isHorizontal"], pValue["type"]
         break
      case "nudge"
         revIDENudgeControls pObjects, pValue["direction"], pValue["increment"]
         break
      case "relayer"
         revIDERelayerControls pObjects, pValue
         break
   end switch
end revIDEAlignControlsFromPI

on revIDEDistributeControls pObjects, pHorizontally, pType
   local tNumberOfObjects
   put the number of lines in pObjects into tNumberOfObjects
   
   local tSize
   put 0 into tSize
   
   local tPerSpace, tOffset
   switch pType
      case "First to last selected"
         if tNumberOfObjects < 3 then exit to top
         repeat with i = 2 to tNumberOfObjects -1
            get line i of pObjects 
            if pHorizontally then
               add the width of it to tSize
            else
               add the height of it to tSize
            end if
         end repeat
         local tFirstObj, tLastObj
         put line 1 of pObjects into tFirstObj
         put line tNumberOfObjects of pObjects into tLastObj
         
         local tStartCoord, tEndCoord
         if pHorizontally then
            put the right of tFirstObj into tStartCoord
            put the left of tLastObj into tEndCoord
         else
            put the bottom of tFirstObj into tStartCoord
            put the top of tLastObj into tEndCoord
         end if 
         put (tEndCoord - tStartCoord - tSize) / (tNumberOfObjects -1) into tPerSpace
         put tStartCoord + tPerSpace into tOffset
         repeat with i = 2 to tNumberOfObjects -1
            get line i of pObjects
            if pHorizontally then
               set the left of it to round(tOffset)
               add the width of it + tPerSpace to tOffset
            else 
               set the top of it to round(tOffset)
               add the height of it + tPerSpace to tOffset
            end if
            send "revCacheGeometry true" to it
         end repeat
         break
      case "Across card"
         if tNumberOfObjects < 1 then exit to top
         repeat with i = 1 to tNumberOfObjects
            get line i of pObjects
            if pHorizontally then
               add the width of it to tSize
            else
               add the height of it to tSize
            end if
         end repeat
         get line 1 of pObjects
         local tCardName, tCardSize
         put word 5 to (the number of words in it) of it into tCardName
         if pHorizontally then
            put the width of tCardName into tCardSize
         else
            put the height of tCardName into tCardSize
         end if
         put (tCardSize - tSize) / (tNumberOfObjects + 1) into tPerSpace
         put tPerSpace into tOffset
         repeat with i = 1 to tNumberOfObjects
            get line i of pObjects
            if pHorizontally then
               set the left of it to round(tOffset)
               add the width of it + tPerSpace to tOffset
            else 
               set the top of it to round(tOffset)
               add the height of it + tPerSpace to tOffset
            end if
            send "revCacheGeometry true" to it
         end repeat
         break
      case "Edge to edge"
         if tNumberOfObjects < 2 then exit to top
         local tPrevObj, tNextObj
         repeat with i = 2 to tNumberOfObjects
            put line i of pObjects into tNextObj
            put line (i - 1) of pObjects into tPrevObj
            if pHorizontally then
               set the left of tNextObj to the right of tPrevObj
            else             
               set the top of tNextObj to the bottom of tPrevObj
            end if
            send "revCacheGeometry true" to tNextObj
         end repeat
         break
   end switch
end revIDEDistributeControls

on revIDEActionDistributeControls pHorizontally, pType
   revIDEDistributeControls the selobj, pHorizontally, pType
end revIDEActionDistributeControls

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

on revIDENudgeControls pObjectList, pDirection, pAmount
   local tObj, tLoc
   repeat for each line tObj in pObjectList
      put the loc of tObj into tLoc
      switch pDirection
         case "up"
            put item 2 of tLoc - pAmount into item 2 of tLoc
            break
         case "down"
            put item 2 of tLoc + pAmount into item 2 of tLoc
            break
         case "left"
            put item 1 of tLoc - pAmount into item 1 of tLoc
            break
         case "right"
            put item 1 of tLoc + pAmount into item 1 of tLoc
            break
      end switch
      set the loc of tObj to tLoc
   end repeat
end revIDENudgeControls

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
function revIDESpecialFolderPath pKey, pParam
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
         if revEnvironmentIsInstalled() then
            return item 1 to -3 of the filename of stack "home" & "/Toolchain"
         else
            return revEnvironmentBinariesPath()
         end if
         break
      case "Object Property Definitions"
         return item 1 to -3 of the filename of stack "home" & "/Toolset/resources/supporting_files/property_definitions"
         break
      case "Object Default Scripts"
         return item 1 to -3 of the filename of stack "home" & "/Toolset/resources/supporting_files/default_scripts"
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
         put  revEnvironmentExtensionsPath() into tPath
         revIDEEnsurePath tPath
         return tPath
         break
      case "user extensions"
         put revEnvironmentUserExtensionsPath() into tPath
         revIDEEnsurePath tPath
         return tPath
         break
      case "temp extensions"
         put revEnvironmentUserExtensionsPath() & "/temp" into tPath
         revIDEEnsurePath tPath
         return tPath    
         break
      case "downloading extensions"
         put revEnvironmentUserExtensionsPath() & "/downloading" into tPath
         revIDEEnsurePath tPath
         return tPath
         break
      case "uninstalled extensions"
         put revEnvironmentUserExtensionsPath() & "/uninstalled" into tPath
         revIDEEnsurePath tPath
         return tPath
         break
      case "documentation"
         put item 1 to -3 of the filename of stack "home" & "/Documentation" into tPath
         return tPath
         break
      case "documentation cache"
         put revEnvironmentUserDocsPath() & slash & "IDE" into tPath
         revIDEEnsurePath tPath
         return tPath
         break
      case "api"
      case "guide"
         if pParam is not empty then
            put "_" & pParam after pKey
         end if
         put item 1 to -3 of the filename of stack "home" & "/Documentation/html_viewer/resources/data/" & tolower(pKey) into tPath
         if not revEnvironmentIsInstalled() then
            revIDEEnsurePath tPath
         end if
         return tPath
         break
      case "examples"
         put  item 1 to -3 of the filename of stack "home" & "/Examples" into tPath
         return tPath
         break
      case "tutorial"
         return item 1 to -3 of the filename of stack "home" & "/Toolset/palettes/tutorial"
         break
      case "user tutorial"
         return revEnvironmentCustomizationPath() & "/Interactive Tutorials"
         break
      case "globals"
         return item 1 to -3 of the filename of stack "home" & "/Toolset/resources/supporting_files/global_properties"
         break
      case "ide guides"
         return item 1 to -3 of the filename of stack "home" & "/Documentation/guides" into tPath
         break
      case "repo guides"
         return revEnvironmentRepositoryPath() & "/docs/guides" into tPath
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
   return the long ID of button "DataView Behavior" of stack "revDataViewControl" of stack "revCore"
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
      set the id of it to revIDENewIconID()
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

local sDefaultFolderList
/**
Stores the current default folder.

Parameters:
pFolder (optional string): The new defaultFolder

Related: revIDEPopDefaultFolder

Example:
on myHandler
   revIDEPushDefaultFolder "/"
   repeat for each line tLine in the files
      # Do something to the files
   end repeat
   revIDEPopDefaultFolder
end myHandler

Description:
Pushes the current defaultFolder onto a list of defaultFolders.
If <pFolder> is specified, then the defaultFolder is set to <pFolder>.
revIDEPopDefaultFolder then pops the list and sets the 
default folder to the popped value.
**/
on revIDEPushDefaultFolder pFolder
   put the defaultfolder into sDefaultFolderList[the number of elements in sDefaultFolderList + 1]
   
   local tError
   if pFolder is not empty then
      set the defaultFolder to pFolder
      
      if the result is not empty then
         put __revIDEError("Invalid default folder:" && pFolder) into tError
      end if
   end if
   
   return tError
end revIDEPushDefaultFolder

/**
Restores the default folder to the last saved path.

Related: revIDEPushDefaultFolder

Example:
on myHandler
   revIDEPushDefaultFolder
   set the defaultfolder to "/"
   repeat for each line tLine in the files
      # Do something to the files
   end repeat
   revIDEPopDefaultFolder
end myHandler

Description:
Pops the last stored defaultFolder and sets the 
default folder to the popped value.
   **/
on revIDEPopDefaultFolder
   local tToPop
   put the number of elements in sDefaultFolderList into tToPop
   if tToPop is 0 then return __revIDEError("Mismatched default folder store / restore")
   
   set the defaultfolder to sDefaultFolderList[tToPop]
   local tError
   if the result is not empty then
      put __revIDEError("Folder to restore no longer exists") into tError
   end if
   delete variable sDefaultFolderList[tToPop]
   return tError  
end revIDEPopDefaultFolder

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
   & "Standalone Settings,About,Dictionary,Guide,Resource Center,Preferences,Search,Snippet Viewer"
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
      case "guide"
         return "revDictionary"
      case "resource center"
         return "revResourceCenter"
      case "snippet viewer"
         return "revIDESnippetViewer"
   end switch
end revIDEPaletteToStackName

on revIDEEnsureOnscreen pStackName
   # Ensure the stack exists
   if there is not a stack pStackName then return __revIDEError("No such stack:" && pStackName)
   
   local tScreenRect
   put line (the screen of stack pStackName) of the working screenrects into tScreenRect
   
   local tScreenHeight, tScreenWidth
   put item 4 of tScreenRect - item 2 of tScreenRect into tScreenHeight
   put item 3 of tScreenRect - item 1 of tScreenRect into tScreenWidth
   
   if the left of stack pStackName < item 1 of tScreenRect then
      set the left of stack pStackName to item 1 of tScreenRect
   else if the right of stack pStackName > item 3 of tScreenRect and the width of stack pStackName < tScreenWidth then
      set the right of stack pStackName to item 3 of tScreenRect
   end if
   
   if the effective top of stack pStackName < item 2 of tScreenRect then
      set the top of stack pStackName to (item 2 of tScreenRect + abs(the top of stack pStackName - the effective top of stack pStackName))
   else if the bottom of stack pStackName > item 4 of tScreenRect and the height of stack pStackName < tScreenHeight then
      set the bottom of stack pStackName to item 4 of tScreenRect
   end if
   
   revIDESetPaletteRectPreference pStackName
end revIDEEnsureOnscreen

/*
Positions the palette.

If the user has set a previous moved a palette, the palette is returned to that position. 
If the palette is being opened for the first time, it is placed in a predetermined position
*/
on revIDEPositionPalette pStackName
   if there is not a stack pStackName then exit revIDEPositionPalette
   
   local tRect
   put revIDEGetPaletteRectPreference(pStackName) into tRect
   
   if __isRect(tRect) then
      # A previous stored rect was found for the stack. Restore is position if possible.
      switch pStackName
         case "revMenuBar"
         case "revTools"
            set the topleft of stack pStackName to item 1 of tRect, item 2 of tRect
            break
         case "message box"
         case "revDictionary"
         default
            set the rect of stack pStackName to tRect
            break
      end switch
   else
      # If no sizing information can be found then position the stack in the 
      # default location. Only do this for specified stacks.
      switch pStackName
         case "revMenuBar"
         case "message box"
         case "revDictionary"
            revIDEPositionPaletteDefault pStackName
            break
         case "revTools"
            local tOldPref
            put revIDEGetPreference("cToolsTopLeft") into tOldPref
            if tOldPref is not empty then
               set the topleft of stack pStackName to tOldPref
            else
               revIDEPositionPaletteDefault pStackName
            end if
         default
            if pStackName begins with revIDEScriptEditorPrefix() then
               revIDEPositionPaletteDefault pStackName
            end if
            break
      end switch
   end if
   
   # AL-2015-09-15: [[ Bug 15745 ]] Ensure palettes don't get placed off screen
   revIDEEnsureOnscreen pStackName
   
end revIDEPositionPalette

constant kToolsMenubarGap = 25
on revIDEPositionPaletteDefault pStackName
   # No previous rect was found for stack to calculate the appropriate position for the stack
   local tScreenHeight, tScreenWidth, tScreenRect
   put revIDEStackScreenRect(pStackName, true) into tScreenRect
   put item 4 of tScreenRect - item 2 of tScreenRect into tScreenHeight
   put item 3 of tScreenRect - item 1 of tScreenRect into tScreenWidth
   
   switch pStackName
      case "revMenuBar"
         set the topleft of stack pStackName to item 1 to 2 of tScreenRect
         break
      case "revTools"
         local tMenuBar
         put revIDEPaletteToStackName("menubar") into tMenuBar
         local tTop
         put the bottom of stack tMenuBar into tTop
         add kToolsMenubarGap to tTop
         set the topleft of stack pStackName to the left of stack tMenuBar,tTop
         break
      case "message box"
         set rect of stack pStackName to item 1 of tScreenRect,item 2 of tScreenRect+tScreenHeight * 0.75, item 1 of tScreenRect+tScreenWidth * 0.3,item 2 of tScreenRect+ tScreenHeight
         break
      case "revDictionary"
         set the rect of stack pStackName to item 1 of tScreenRect+tScreenWidth * 0.5, item 2 of tScreenRect+100, item 1 of tScreenRect+tScreenWidth * 0.9, item 2 of tScreenRect+tScreenHeight * 0.9
         break
      default 
         # If no sizing information can be found position the stack in the center of the 
         # default screen
         
         ## If the stack is a Script Editor ensure it will fit on screen
         if pStackName begins with revIDEScriptEditorPrefix() then 
            set the rect of stack pStackName to item 1 of tScreenRect+ tScreenWidth * 0.3,  item 2 of tScreenRect+tScreenHeight * 0.2,item 1 of tScreenRect+ tScreenWidth * 0.7,  item 2 of tScreenRect+tScreenHeight * 0.8
         else
            set the loc of stack pStackName to item 1 of tScreenRect+ tScreenWidth * 0.5, item 2 of tScreenRect+tScreenHeight * 0.5
         end if
         break
   end switch
   
end revIDEPositionPaletteDefault

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

on revIDESetPaletteRectPreference pStackName
   # If the stack is iconic its topleft is -32000,-32000, so don't store the rect
   if the iconic of stack pStackName then
      exit revIDESetPaletteRectPreference
   end if
   
   local tRect
   put the rect of stack pStackName into tRect
   replace " " with "_" in pStackName
   revIDESetPreference "palette_rect_" & pStackName, tRect
end revIDESetPaletteRectPreference

function revIDEGetPaletteRectPreference pStackName
   local tRect
   replace " " with "_" in pStackName
   put revIDEGetPreference("palette_rect_" & pStackName) into tRect
   # If the palette rect was stored when it was iconic, return empty
   if item 1 to 2 of tRect is "-32000,-32000" then
      return empty
   end if
   
   return tRect
end revIDEGetPaletteRectPreference

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

function revIDEBrowserWidgetUnavailable
   return (the platform is "Linux") and ($LIVECODE_USE_CEF is 0)
end revIDEBrowserWidgetUnavailable

/*
Opens an IDE stack as a palette. In the future this should be changed so that
palettes can decide what mode they ought to be opened in, i.e. this logic should
be removed from the IDE library and be specific to the stack rather than the 
palette name.

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
      case "message box"
         -- The message box needs to be brought to the front as it takes keyboard focus
         palette stack tStackName
         go stack tStackName
         break
      case "standalone settings"
      case "message watcher"
      case "tools"
      case "snippet viewer"
         palette stack tStackName
         break
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
      case "guide"
         if revIDEBrowserWidgetUnavailable() then
            local tWhich
            if pPaletteName is "dictionary" then
               put "api" into tWhich
            else
               put "guide" into tWhich
            end if
            
            revIDEGenerateDictionaryHTML tWhich
            launch url ("file:" & revIDEGetDictionaryUrl(tWhich))
         else
            toplevel stack tStackName
         end if
         break
      case "inspector"
         # The inspector stack is now a manager for property inspectors, 
         # and does not need to be visible.
         go invisible stack tStackName as palette
         return empty
      default
         return __revIDEError("No such palette:" && pPaletteName)
   end switch
   show stack tStackName
   revIDEMessageSend "ideOpenPalette", pPaletteName
end revIDEOpenPalette

function revIDEPaletteIsVisible pPaletteName
   local tStackName
   put revIDEPaletteToStackName(pPaletteName) into tStackName
   return the mode of stack tStackName is not 0 and the visible of stack tStackName
end revIDEPaletteIsVisible

on revIDEOpenInspectorForObjects pObjects
   lock screen
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

/**
Determines whether an object is considered part of the IDE

pLongID: The long id of the object.
Returns (boolean):

Description:
Use the <revIDEObjectIsOnIDEStack> function to determine whether an object is
considered part of the IDE, that is if it is on a stack whose mainstack is part
of the IDE, according to the <revIDEStackIsIDEStack> function.

References: revIDEStackIsIDEStack (function)
**/
function revIDEObjectIsOnIDEStack pLongID
   if not exists(pLongID) then return false
   
   local tMainStack
   put ideMainStackOfObject(pLongID) into tMainStack
   
   return revIDEStackIsIDEStack(tMainStack)
end revIDEObjectIsOnIDEStack

/**
Determines whether a stack is considered part of the IDE

pLongID: The long id of the stack.
Returns (boolean):

Description:
Use the <revIDEStackIsIDEStack> function to determine whether a stack is
considered part of the IDE.

A stack is considered part of the IDE if it exists, and
* Its name begins with "rev"
* Its name begins with "com.livecode."
* Its name is "message box, answer dialog, ask dialog, or home"

>*Note:* If the name of the stack is already available, it is more efficient to
use the <revIDEStackNameIsIDEStack> function.

References: revIDEStackNameIsIDEStack (function)
**/
function revIDEStackIsIDEStack pLongID
   if not exists(pLongID) then return false
   return revIDEStackNameIsIDEStack(the short name of pLongID)
end revIDEStackIsIDEStack

/**
Determines whether a stack is considered part of the IDE

pStackName: The short name of the stack
Returns (boolean):

Description:
Use the <revIDEStackNameIsIDEStack> function to determine whether a stack is
considered part of the IDE, according to the name of the stack.

A stack is considered part of the IDE if any of the following are satisfied:
* Its name begins with "rev"
* It was loaded by the initialisation library
* Its name begins with "com.livecode."
* Its name is "message box, answer dialog, ask dialog, or home"
* Its _ideoverride property is true
**/
function revIDEStackNameIsIDEStack pStackName
   -- call revStackNameIsIDEStack in revcommonlibrary
   return revStackNameIsIDEStack(pStackName)
end revIDEStackNameIsIDEStack

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
   repeat for each key tKey in pList
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
   replace CRLF with "\n" in pString
   replace numToCodepoint(13) with "\n" in pString
   replace LF with "\n" in pString
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
   put revIDEUTF8FileContents(tGuideFile) into tGuide
   if tGuide is empty then
      return "no user guide data"
   end if
   
   local tGuideJSON
   put "{" & CR after tGuideJSON
   put tab & quote & "guide" & quote & ":" && quote & pExtensionName & quote & comma & CR after tGuideJSON
   put quote & "data" & quote & ":" & __escapeStringAndConvertLineEndings(tGuide) & CR after tGuideJSON
   put "}" after tGuideJSON
   
   revIDESetUTF8FileContents pGuideFolder & slash & "guide.js", tGuideJSON
   
   # Now regenerate the built guides
   revIDERegenerateBuiltGuides
end revIDEInstallUserGuide

/*
Install the given extension's API
*/
on revIDEInstallAPI pAPIFolder, pExtensionName, pAuthor
   
   local tAPIFile
   put pAPIFolder & slash & "api.lcdoc" into tAPIFile
   
   # Convert the new API to a JSON array to append to API data
   local tAPIJSON
   dispatch function "revDocsFormatAPIAsJSON" to stack "revDocsParser" with pExtensionName, pAuthor, tAPIFile
   put the result into tAPIJSON
   if tAPIJSON is empty then
      return "no documentation found"
   end if
   
  revIDESetUTF8FileContents pAPIFolder & slash & "api.js", tAPIJSON
   
   # Now regenerate the built APIs
   revIDERegenerateBuiltAPIs
end revIDEInstallAPI

on revIDEGoToLCSDictionaryEntry pTag, pType
   revIDEGoToDictionaryEntry "livecode_script", pTag, pType
end revIDEGoToLCSDictionaryEntry

on revIDEGoToDictionaryEntry pLibrary, pTag, pType
   if revIDEBrowserWidgetUnavailable() then
      revIDEGenerateDictionaryHTML "api", pLibrary, pTag, pType
      launch url ("file:" & revIDEGetDictionaryUrl("api"))
   else
      send "goToEntry pLibrary, pTag, pType" to stack revIDEPaletteToStackName("dictionary") 
   end if
   revIDEMessageSend "ideOpenPalette", "dictionary"
end revIDEGoToDictionaryEntry

command revIDEGoToExtensionAPI pKind
   local tType
   put revIDEExtensionProperty(pKind, "type") into tType
   __GoToExtensionAPI pKind, tType
end revIDEGoToExtensionAPI

private command __GoToExtensionAPI pKind, pType
   local tName, tLibrary
   put revIDEExtensionProperty(pKind, "title") into tName
   put tolower(pKind) into tLibrary
   revIDEGoToDictionaryEntry tLibrary, tName, pType
end __GoToExtensionAPI

command revIDEGoToWidgetAPI pKind
   __GoToExtensionAPI pKind, "widget"
end revIDEGoToWidgetAPI

on revIDEGoToObjectAPI pObjectID
   local tType
   put word 1 of pObjectID into tType
   if tType is "widget" then
      revIDEGoToWidgetAPI the kind of pObjectID
   else
      revIDEGoToDictionaryEntry "livecode_script", tType, "object"
   end if
end revIDEGoToObjectAPI

#############
# Properties API
#############

local sLockUpdates, sThrottleTime
private command __LockPropertyUpdates pThrottleTime
   if pThrottleTime is empty then
      put 10 into pThrottleTime
   end if
   put true into sLockUpdates
   put pThrottleTime into sThrottleTime
end __LockPropertyUpdates

private command __UnlockPropertyUpdates
   put false into sLockUpdates
end __UnlockPropertyUpdates

on revIDEPropertyLibraryInitialise
   __UnlockPropertyUpdates
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

local sObjListA
on revIDEUnlockPropertyUpdates
   __UnlockPropertyUpdates
   revIDESendPropertyChanged the keys of sObjListA
   put empty into sObjListA
end revIDEUnlockPropertyUpdates

on revIDESendPropertyChanged pObjectList
   repeat for each line tObject in pObjectList
      ideMessageSendWithTrigger "idePropertyChanged", tObject, tObject
   end repeat
end revIDESendPropertyChanged

local sPropertyChangedMsgID
on revIDEPropertyChanged pObjectList
   if sLockUpdates is true then
      -- Accumulate a list of objects whose property changes were locked
      -- from triggering an ide message.
      repeat for each line tObj in pObjectList
         put true into sObjListA[tObj]
      end repeat  
      
      if "revIDEUnlockPropertyUpdates" is in the pendingMessages then
         cancel sPropertyChangedMsgID
      end if
      
      -- Postpone update until sThrottleTime millisecs has passed
      send "revIDEUnlockPropertyUpdates" to me in sThrottleTime millisecs
      put the result into sPropertyChangedMsgID
      exit revIDEPropertyChanged
   end if
   
   revIDESendPropertyChanged pObjectList
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
   put ideObjectTypesFromObjectList(pObjectList) into tObjectTypeList

   # Return this list of all the properties to read for the given type list
   local tProperties
   put __objectPropertiesShared(tObjectTypeList, true, pSection) into tProperties
   
   # Include multiple object properties if required
   if the number of lines in pObjectList > 1 then
      if pSection is empty then
         union tProperties with sClassicObjectPropertiesInfo["com.livecode.interface.MultipleObjects"] recursively
      else
         union tProperties with sClassicObjectPropertiesInfo["com.livecode.interface.MultipleObjects"][pSection] recursively
      end if
   end if
   return tProperties
end __revIDEPropertiesInfoOfSection

function revIDEPropertiesInfoOfSection pObjectList, pSection
   local tSharedPropertiesA
   put __revIDEPropertiesInfoOfSection(pObjectList, pSection) into tSharedPropertiesA

   # Return ordered list
   if pSection is empty then
      return __orderPropArray(tSharedPropertiesA, revIDEPropertySections())
   else
      return __orderPropSection(tSharedPropertiesA["grouplist"])
   end if
end revIDEPropertiesInfoOfSection

private on __setPropertyOfObject pObject, pProperty, pValue
   if pProperty is "customProperties" then
      put true into sLockUpdates
   end if
   
   local tProperties
   put __classicObjectProperties(pObject) into tProperties
   
   if tProperties["properties"][pProperty]["setter"] is not empty then
      dispatch tProperties["properties"][pProperty]["setter"] with pObject, pProperty, pValue
   else
      set the pProperty of pObject to pValue
   end if
   
end __setPropertyOfObject

function ideCheckStackName pName
   if char 1 to 3 of pName is "rev" then
      answer warning revIDELocalise("Using rev in the first three characters of a stack name is reserved for use by the LiveCode development environment and advanced users creating Plug-ins. If you use these characters, your stack may not behave as expected.") with revIDELocalise("OK") and revIDELocalise("Cancel")
      if it is revIDELocalise("Cancel") then
         return false
      end if
   end if
   if pName is a number then
      beep
      answer error revIDELocalise("You cannot set the name of a stack to a number.")
      return false
   end if
   if pName contains quote then 
      beep
      answer error revIDELocalise("The name of the stack cannot contain quotes")
      return false
   end if 
   
   return true
end ideCheckStackName

on revIDEPropertySet pObjectList, pProperty, pValue, pLockUpdates
   local tThrottlePropertyChanged
   put false into tThrottlePropertyChanged
   if the number of lines in pObjectList > 1 then
      put true into tThrottlePropertyChanged
   end if
   
   if tThrottlePropertyChanged or pLockUpdates then
      __LockPropertyUpdates 10
   end if
   
   lock screen
   # Set stack edited before property change
   local tStacksListA, tStackShortNamesListA, tStack, tStackName
   repeat for each line tObject in pObjectList
      put revIDEStackOfObject(tObject) into tStack
      if not tStacksListA[tStack] then
         put true into tStacksListA[tStack]
         
         # If stack name is changed, use new name when setting edited
         if tStack is tObject and pProperty is "name" then
            
            if not ideCheckStackName(pValue) then
               local tOldName
               put the short name of tStack into tOldName
               set the name of tStack to tOldName
               exit revIDEPropertySet
            end if
            
            put pValue into tStackName
         else
            put the short name of tStack into tStackName
         end if
         put true into tStackShortNamesListA[tStackName]
      end if
   end repeat
   
   repeat for each key tStackName in tStackShortNamesListA
      revIDESetEdited tStackName
   end repeat
   
   # Multi-object properties require the object list to be passed
   local tMultiObjectSetter
   put sClassicObjectProperties["com.livecode.interface.MultipleObjects"]["properties"][pProperty]["setter"] into tMultiObjectSetter
   if tMultiObjectSetter is not empty then
      dispatch tMultiObjectSetter with pObjectList, pProperty, pValue
   else
      repeat for each line tObject in pObjectList
         __setPropertyOfObject tObject, pProperty, pValue
      end repeat
   end if
   
   unlock screen
end revIDEPropertySet

local sStoredPropsA
on revIDEPropertyStore pObjectList, pProperty, pValue
   put pValue into sStoredPropsA[pObjectList][pProperty]
end revIDEPropertyStore

function revIDEPropertyRetrieveStored pObjectList, pProperty
   return sStoredPropsA[pObjectList][pProperty]
end revIDEPropertyRetrieveStored

function revIDECustomPropertiesGet pObjectID, pProperty
   return __customPropertyValue(pObjectID)
end revIDECustomPropertiesGet

on revIDECustomPropertiesSet pObject, pProperty, pValue
   local tOldPropertySet
   put the custompropertyset of pObject into tOldPropertySet
   set the custompropertysets of pObject to empty
   if pValue is not empty then
      repeat for each key tKey in pValue
         set the custompropertyset of pObject to tKey
         set the customKeys of pObject to the keys of pValue[tKey]
         set the customProperties of pObject to pValue[tKey]
      end repeat
   else
      set the custompropertyset of pObject to empty
      set the customKeys of pObject to empty
   end if
   set the custompropertyset of pObject to tOldPropertySet
end revIDECustomPropertiesSet

private on __populatePropertyArray pObject, pPropertyValues, @xPropertiesA
   repeat for each key tPropertyName in pPropertyValues
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
      dispatch "__readGroupedPropertiesOfControl" to tObject with pSectionInfoA, tPropertyValuesA
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
   return "Basic,Stack Files,Data Grid,Contents,Columns,Custom,Table,Colors,Effects,Icons,Position,Text,Advanced,Geometry Manager,Align Controls"
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
      case "columns"
         return "columns"
         break
      case "advanced"
         return "cogs"
         break
      case "align controls"
         return "object align left"
      case "geometry manager"
         return "object justify both"
      case "stack files"
         return "files alt"
      case "contents"
         return "list"
      default
         return "remove"
         break
   end switch
end revIDEPropertySectionNameToIconName

function revIDEPaletteResourcePath pFilename, pTarget
   if pTarget is empty then put the long ID of the target into pTarget
   local tPalettePath
   set the itemdel to slash
   put item 1 to -2 of the filename of revIDEStackOfObject(pTarget) into tPalettePath
   if there is not a file tPalettePath & slash  & pFilename then
      return "file not found"
   end if

   return  tPalettePath & slash  & pFilename
end revIDEPaletteResourcePath

function revIDELastModifiedTimeOfFile pFolder, pFile
   local tDetailedFiles
   revIDEPushDefaultFolder pFolder
   put the detailed files into tDetailedFiles
   revIDEPopDefaultFolder
   return item 5 of line lineOffset(urlEncode(pFile), tDetailedFiles) of tDetailedFiles
end revIDELastModifiedTimeOfFile

function revIDELastModifiedTimeOfFilesInFolder pFolder, pRecursive
   local tDetailedFiles, tMax
   revIDEPushDefaultFolder pFolder
   put the detailed files into tDetailedFiles
   sort tDetailedFiles descending numeric by item 5 of each
   put item 5 of line 1 of tDetailedFiles into tMax
   if tMax is not a number then put 0 into tMax
   if pRecursive then
      repeat for each line tFolder in the folders
         if tFolder is ".." then next repeat
         put max(revIDELastModifiedTimeOfFilesInFolder(pFolder & slash & tFolder, pRecursive), tMax) into tMax
      end repeat
   end if
   revIDEPopDefaultFolder
   return tMax
end revIDELastModifiedTimeOfFilesInFolder

function revIDEExtensionFolders
   local tFoldersA
   put revIDESpecialFolderPath("user extensions") into tFoldersA["user"]
   
   local tCount = 0
   repeat for each line tFolder in revEnvironmentExtensionsPaths()
      add 1 to tCount
      put tFolder into tFoldersA["ide" && tCount]
   end repeat
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

function revIDEDefaultScript pObject, pHandler
   local tDefaultScript, tType
   put ideObjectTypeFromObject(pObject) into tType
   if word 1 of the name of pObject is "widget" then
      put revIDEWidgetDefaultScript(tType) into tDefaultScript
   else
      put revIDEClassicObjectDefaultScript(tType) into tDefaultScript
   end if
   
   lock screen
   lock messages
   create invisible stack "revDefaultScriptHolder"
   try
      set the script of it to tDefaultScript
   catch tError
   end try
   local tHandlers
   put the revAvailableHandlers of it into tHandlers
   delete stack "revDefaultScriptHolder"
   local tHandlerStart, tHandlerEnd, tHandlerInfo, tHandlerInfoLine
   set the wholematches to false
   -- Ensure we don't accidentally match a substring by putting
   -- spaces around the handler name
   put lineOffset(" " & pHandler & " ", tHandlers) into tHandlerInfoLine
   put line tHandlerInfoLine of tHandlers into tHandlerInfo
   -- We want to include any comments before the handler declaration
   -- so find the previous handler 
   put word 3 of tHandlerInfo into tHandlerStart
   put word 4 of tHandlerInfo into tHandlerEnd
   repeat while word 1 of line tHandlerStart of tDefaultScript is not empty
      subtract 1 from tHandlerStart
   end repeat
   unlock messages
   unlock screen
   return line tHandlerStart to tHandlerEnd of tDefaultScript
end revIDEDefaultScript

function revIDEClassicObjectDefaultScript pType
   local tFolder
   put revIDESpecialFolderPath("Object Default Scripts") into tFolder
   if there is a stack (tFolder & slash & pType & ".livecodescript") then
      return the script of stack (tFolder & slash & pType & ".livecodescript")
   end if
   return empty
end revIDEClassicObjectDefaultScript

function revIDEWidgetDefaultScript pKind
   return revIDEExtensionProperty(pKind, "defaultScript")
end revIDEWidgetDefaultScript

function revIDEScriptEditorBehavior pWhich
   local tPathToBehaviors
   put revIDESpecialFolderPath("Toolset") & slash & "palettes" & slash & "script editor" & slash & "behaviors" into tPathToBehaviors
   switch pWhich
      case "common editor"
         return tPathToBehaviors & slash & "revsecommoneditorbehavior.livecodescript"
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
      case "leftbar"
         return tPathToBehaviors & slash & "revseleftbarbehavior.livecodescript"
      case "variablespane"
         return tPathToBehaviors & slash & "revsevariablespanebehavior.livecodescript"
      case "documentationpane"
         return tPathToBehaviors & slash & "revsedocumentationpanebehavior.livecodescript"
      case "breakpointpane"
         return tPathToBehaviors & slash & "revsebreakpointpanebehavior.livecodescript"
      case "errorspane"
         return tPathToBehaviors & slash & "revseerrorspanebehavior.livecodescript"	
      case "filterfield"
         return tPathToBehaviors & slash & "revsefilterfieldbehavior.livecodescript"
      case "variablescheckbox"
         return tPathToBehaviors & slash & "revsevariablescheckboxbehavior.livecodescript"
      case "stack"
         return tPathToBehaviors & slash & "revsestackbehavior.livecodescript"
      case "utilities"
         return tPathToBehaviors & slash & "revseutilities.livecodescript"
      case "gutter"
         return tPathToBehaviors & slash & "revsegutterbehavior.livecodescript"
      case "interactive find"
         return tPathToBehaviors & slash & "revseinteractivefindbehavior.livecodescript"
      case "variable visualizer"
         return tPathToBehaviors & slash & "revsevariablevisualizerstackbehavior.livecodescript"
      case "edit breakpoint"
         return tPathToBehaviors & slash & "revseeditbreakpointstackbehavior.livecodescript"
      case "error template"
         return tPathToBehaviors & slash & "revseerrortemplatebehavior.livecodescript"
      case "find main card"
         return tPathToBehaviors & slash & "revsefindmaincardbehavior.livecodescript"
      default
         return empty
   end switch
end revIDEScriptEditorBehavior

function revIDEMessageBoxBehavior pWhich
   local tPathToBehaviors
   put revIDESpecialFolderPath("Toolset") & slash & "palettes" & slash & "message box" & slash & "behaviors" into tPathToBehaviors
   switch pWhich
      case "single line message"
         return tPathToBehaviors & slash & "revmessageboxsinglelinemessagebehavior.livecodescript"
      case "single line card"
         return tPathToBehaviors & slash & "revmessageboxsinglelinecardbehavior.livecodescript"
      case "multiple lines message"
         return tPathToBehaviors & slash & "revmessageboxmultiplelinesmessagebehavior.livecodescript"
      case "multiple lines card"
         return tPathToBehaviors & slash & "revmessageboxmultiplelinescardbehavior.livecodescript"
      default
         return empty  
   end switch
end revIDEMessageBoxBehavior

on revIDEAnswerDialogClosed
   local tPopupSource
   put item 1 of line 1 of the executionContexts into tPopupSource
   ideMessageSend "ideAnswerDialogClosed", tPopupSource
end revIDEAnswerDialogClosed

function revIDEAbsoluteRectOfPaletteObject pPaletteName, pObjectData
   local tPaletteID
   put the long id of stack revIDEPaletteToStackName(pPaletteName) into tPaletteID
   return revIDEAbsoluteRectOfObject(tPaletteID, pObjectData)
end revIDEAbsoluteRectOfPaletteObject

function revIDEAbsoluteRectOfObject pStackID, pObjectData
   dispatch function "absoluteRectOfObject" to stack pStackID with pObjectData
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

on revIDEHighlightPaletteObject pPaletteName, pObjectData
   local tPaletteID
   put the long id of stack revIDEPaletteToStackName(pPaletteName) into tPaletteID
   revIDEHighlightObject tPaletteID, pObjectData
end revIDEHighlightPaletteObject

on revIDEHighlightObject pStackID, pObjectData
   dispatch "highlightObject" to pStackID with pObjectData
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
      reset the templatestack
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

on revIDEDataGridAction pObj, pProperty
   switch pProperty 
      case "row template"
         local tTemplate
         put the dgProps["row template"] of pObj into tTemplate
         set the itemdel to "card"
         local tCard
         put "card" && item 2 to -1 of tTemplate into tCard
         if exists(tCard) then
            go tCard
         end if
         break
      case "refresh"
         dispatch "ResetList" to pObj
         break
   end switch
end revIDEDataGridAction

local sFirstRowHeaders
on revIDESetDataGridProperty pObj, pProperty, pValue
   switch pProperty 
      case "text"
         if sFirstRowHeaders[pObj] then
            set the dgText[true] of pObj to pValue
         else
            set the dgText of pObj to pValue
         end if
         break
      case "first row header"
         local tText
         if sFirstRowHeaders[pObj] then
            put the dgText[true] of pObj into tText
         else
            put the dgText of pObj into tText
         end if
         put pValue into sFirstRowHeaders[pObj]
         revIDESetDataGridProperty pObj, "text", tText
         break
      default
         set the dgProps[pProperty] of pObj to pValue
         break
   end switch
end revIDESetDataGridProperty

private function __DataGridTextProperty pObject, pProperty, @rEffective
   local tRealProperty
   switch pProperty
      case "text font"
      case "header text font"
         put "textFont" into tRealProperty
         break
      case "text size"
      case "header text size"
         put "textSize" into tRealProperty
         break
      case "text style"
      case "header text style"
         put "textStyle" into tRealProperty
         break
   end switch
   local tValue
   put the dgProps[pProperty] of pObject into tValue
   if tValue is empty then
      put the effective tRealProperty of pObject into tValue
      put true into rEffective
   end if
   return tValue
end __DataGridTextProperty

function revIDEGetDataGridProperty pObject, pProperty, @rEffective
   switch pProperty 
      case "row behavior"
         local tTemplate
         put the dgProps["row template"] of pObject into tTemplate
         set the itemdel to "card"
         return "button" && quote & "Behavior Script" & quote && "card" && item 2 to -1 of tTemplate
         break
      case "text"
         if sFirstRowHeaders[pObject] then
            return the dgText[true] of pObject
         else
            return the dgText of pObject
         end if
         break
      case "first row header"
         return sFirstRowHeaders[pObject] is true
         break
      case "text font"
      case "text size"
      case "text style"
      case "header text font"
      case "header text size"
      case "header text style"
         return __DataGridTextProperty(pObject, pProperty, rEffective)
      case "header background color"
      case "header background hilite color"
         -- Special case these as their default values are two-color gradients
         local tColor
         put the dgProps[pProperty] of pObject into tColor
         if the number of lines in tColor is 2 then
            put true into rEffective
            return line 1 of tColor
         end if
         return tColor
      default
         return the dgProps[pProperty] of pObject
         break
   end switch
end revIDEGetDataGridProperty

local sCurrentColumn
on revIDESetDataGridColumns pObject, pProperty, pValue
   local tColumns, tCurrentColumn
   repeat with x = 1 to the number of elements in pValue
      if tColumns is empty then
         put pValue[x]["name"] into tColumns
      else
         put return & pValue[x]["name"] after tColumns
      end if
      
      if pValue[x]["current"] then
         put pValue[x]["name"] into tCurrentColumn
      end if
   end repeat
   if tCurrentColumn is empty then
      put pValue[1]["name"] into tCurrentColumn
   end if
   put tCurrentColumn into sCurrentColumn
   
   set the dgProps["columns"] of pObject to tColumns
end revIDESetDataGridColumns

function revIDEGetDataGridColumns pObject, pProperty
   local tArray, tColumns, tCount
   put the dgProps["columns"] of pObject into tColumns
   repeat for each line tColumn in tColumns
      add 1 to tCount
      if tColumn is sCurrentColumn then
         put true into tArray[tCount]["current"]
      end if
      put tColumn into tArray[tCount]["name"]
   end repeat
   return tArray
end revIDEGetDataGridColumns

on revIDESetDataGridColumnProperty pObject, pProperty, pValue
   if sCurrentColumn is empty then
      exit revIDESetDataGridColumnProperty
   end if
   
   switch pProperty
      case "column name"
         set the dgColumnName[sCurrentColumn] of pObject to pValue
         break
      case "column label"
         set the dgColumnLabel[sCurrentColumn] of pObject to pValue
         break
      case "column visible"
         set the dgColumnIsVisible[sCurrentColumn] of pObject to pValue
         break
      case "column width"
         set the dgColumnWidth[sCurrentColumn] of pObject to pValue
         break
      case "column min width"
         set the dgColumnMinWidth[sCurrentColumn] of pObject to pValue
         break
      case "column max width"
         set the dgColumnMaxWidth[sCurrentColumn] of pObject to pValue
         break
      case "column align"
         set the dgColumnAlignment[sCurrentColumn] of pObject to pValue
         break
      case "sort by column"
         if pValue then
            set the dgProps["sort by column"] of pObject to sCurrentColumn
         else if the dgProps["sort by column"] of pObject is sCurrentColumn then
            set the dgProps["sort by column"] of pObject to empty
         end if
         break
      case "column drag to resize"
         set the dgColumnIsResizable[sCurrentColumn] of pObject to pValue
         break
      case "column sort direction"
         set the dgColumnSortDirection[sCurrentColumn] of pObject to pValue
         break
      case "column sort type"
         set the dgColumnSortType[sCurrentColumn] of pObject to pValue
         break
      case "column case sensitive"
         set the dgColumnSortIsCaseSensitive[sCurrentColumn] of pObject to pValue
         break
      case "column behavior"
         revIDENewDataGridColumnBehavior pObject
         break
   end switch
   revIDEPropertyChanged pObject
end revIDESetDataGridColumnProperty

function revIDEGetDataGridColumnProperty pObject, pProperty
   switch pProperty
      case "column name"
         return sCurrentColumn
         break
      case "column label"
         return the dgColumnLabel[sCurrentColumn] of pObject
         break
      case "column visible"
         return the dgColumnIsVisible[sCurrentColumn] of pObject is not false
         break
      case "column width"
         return the dgColumnWidth[sCurrentColumn] of pObject
         break
      case "column min width"
         return the dgColumnMinWidth[sCurrentColumn] of pObject
         break
      case "column max width"
         return the dgColumnMaxWidth[sCurrentColumn] of pObject
         break
      case "column align"
         local tAlign
         put the dgColumnAlignment[sCurrentColumn] of pObject into tAlign
         if tAlign is empty then
            put "left" into tAlign
         end if
         return tAlign
         break
      case "sort by column"
         return the dgProps["sort by column"] of pObject is sCurrentColumn
         break
      case "column drag to resize"
         return the dgColumnIsResizable[sCurrentColumn] of pObject is not false
         break
      case "column case sensitive"
         return the dgColumnSortIsCaseSensitive[sCurrentColumn] of pObject is true
         break
      case "column sort direction"
         local tSortDir
         put the dgColumnSortDirection[sCurrentColumn] of pObject into tSortDir
         if tSortDir is empty then
            put "ascending" into tSortDir
         end if
         return tSortDir
         break
      case "column sort type"
         local tSortType
         put the dgColumnSortType[sCurrentColumn] of pObject into tSortType
         if tSortType is empty then
            put "text" into tSortType
         end if
         return tSortType
         break
      case "column behavior"
         return the dgColumnTemplate[sCurrentColumn] of pObject
         break
   end switch
end revIDEGetDataGridColumnProperty

command revIDENewDataGridColumnBehavior pObject
   local tDefault
   put the defaultStack into tDefault
   
   local tTemplate, tTemplateCard, tStackWord
   put the dgProps["row template"] of pObject into tTemplate
   put wordoffset("card",tTemplate) into tStackWord
   put word tStackWord to -1 of tTemplate into tTemplateCard
   reset the templateButton
   set the visible of the templateButton to false
   set the width of the templateButton to 140
   
   local tTopLeft
   put the topLeft of last group of tTemplateCard into tTopLeft
   add 100 to item 1 of tTopLeft
   
   local tGroupRef
   copy group "default column template" of stack "revdatagridlibrary" to tTemplate
   put it into tGroupRef
   set the name of tGroupRef to sCurrentColumn
   set the topLeft of tGroupRef to tTopLeft
   put sCurrentColumn into field 1 of tGroupRef
   
   local tStack
   put the long id of the owner of tTemplate into tStack
   set the name of the templateButton to sCurrentColumn && "Behavior"
   go inv stack tTemplateCard
   put wordoffset("stack",tTemplate) into tStackWord
   put word tStackWord to -1 of tTemplate into tTemplate
   set the title of stack tTemplate to "Editing template"
   set the defaultStack to tTemplate
   local tOpen
   put the mode of stack tTemplate is not 0 into tOpen
   lock messages
   local tButton
   put the number of card buttons into tButton
   if tButton is 0 then
      put 4,200 into tTopLeft
   else
      put the topLeft of btn tButton of this card into tTopLeft
      add 40 to item 2 of tTopLeft
   end if
   set the topLeft of the templateButton to tTopLeft
   local tButtonRef
   create button
   put it into tButtonRef
   set the script of tButtonRef to the uDefaultScript of button "Default Column Script" of stack "revDataGridLibrary"
   set the parentScript of tGroupRef to it
   reset the templateGroup
   reset the templateButton
   if not tOpen then close stack tTemplate
   show stack tTemplate
   set the defaultStack to tDefault
   unlock messages
   
   send "resetList" to pObject
end revIDENewDataGridColumnBehavior

on revIDESetTableProperty pObject, pProperty, pValue
   local tWasTableObject
   put the cREVGeneral["table"] of pObject into tWasTableObject
   switch pProperty
      case "celledit"
         set the cRevTable[pProperty] of pObject to pValue
         if tWasTableObject then
         set the locktext of pObject to pValue
         end if
         break
      case "basicTableObject"
         set the cREVGeneral["table"] of pObject to pValue
         if pValue then
            local tReturned
            put the cREVDatabase["returnedview"] of pObject into tReturned
            if tReturned is not empty then
               set the cREVTable["currentview"] of pObject to tReturned
            else
               set the cREVTable["currentview"] of pObject to the text of pObject
            end if
         end if
         
         # Only change the contents if this was a table or is becoming one
         if pValue or tWasTableObject then
         revDisplayFormattedData pObject
         end if
         
         if pValue then
            set the vScrollbar of pObject to true
         end if
         break
      case "cellformat"
      case "maxColumnCount"
         set the cRevTable[pProperty] of pObject to pValue
         break
   end switch
end revIDESetTableProperty

function revIDEGetTableProperty pObject, pProperty
   switch pProperty
      case "basicTableObject"
         return the cREVGeneral["table"] of pObject
         break
      case "cellformat"
      case "celledit"
      case "maxColumnCount"
         return the cRevTable[pProperty] of pObject
         break
   end switch
end revIDEGetTableProperty


constant kGradientSetOrder = "type,ramp,quality,repeat,mirror,wrap"
on revIDESetGradientProperty pObject, pProperty, pValue
   local tOldValue
   put the pProperty of pObject into tOldValue
   
   if tOldValue is empty or pValue is empty then
      set the pProperty of pObject to pValue
      exit revIDESetGradientProperty
   end if
   
   # Find out which keys have changed
   local tChanged
   repeat for each item tKey in kGradientSetOrder
      if pValue[tKey] is empty then
         next repeat
      end if
      if pValue[tKey] is not tOldValue[tKey] then
         if tChanged is empty then
            put tKey into tChanged
         else
            put return & tKey after tChanged
         end if
      end if
   end repeat
   
   # Avoid overwriting primary and secondary gradient props
   # by setting array prop values one by one
   local tLast
   put line -1 of tChanged into tLast
   lock messages
   repeat for each line tKey in tChanged
      if tKey is tLast then
         unlock messages
      end if
      switch pProperty
         case "fillGradient"
            set the fillgradient[tKey] of pObject to pValue[tKey]
            break
         case "strokeGradient"
            set the strokeGradient[tKey] of pObject to pValue[tKey]
            break
      end switch
   end repeat
end revIDESetGradientProperty

private function __resolveStackFilePath pBasePath, pOtherPath
   set the itemdelimiter to "/"
   put __resolveRelativeFilenameReference(pOtherPath, item 1 to -2 of pBasePath) into pOtherPath
   
   -- At this point pOtherPath should be absolute, so if its
   -- (component-wise) prefix is pBasePath we relativize again.
   local tBasePathFolder
   put item 1 to -2 of pBasePath into tBasePathFolder
   put __makePathRelative(pOtherPath, tBasePathFolder) into pOtherPath
   
   return pOtherPath
end __resolveStackFilePath

private function __resolveRelativeFilenameReference pFilename, pRootFolder
   local tNewFilename
   
   set the itemdelimiter to "/"
   
   if not (pFilename begins with "../") then
      if pFilename begins with "/" or item 1 of pFilename contains ":" then
         return pFilename
      else
         return pRootFolder & "/" & pFilename
      end if
   end if
   
   put pFilename into tNewFilename
   
   repeat while tNewFilename begins with "../"
      if pRootFolder is empty then
         return "out of bounds" for error
      else
         delete the last item of pRootFolder
         delete char 1 to 3 of tNewFilename
      end if
   end repeat
   
   if tNewFilename is empty then
      return pRootFolder for value
   else
      return pRootFolder & "/" & tNewFilename for value
   end if
end __resolveRelativeFilenameReference

private function __makePathRelative pFilename, pRootFolder
   local tIndex
   local tMatchCount = 0
   local tNonMatchCount =0

   # Normalize
   if char 1 of pFilename is slash then delete char 1 of pFilename
   if char 1 of pRootFolder is slash then delete char 1 of pRootFolder
   if the last char of pFilename is slash then delete the last char of pFilename
   if the last char of pRootFolder is slash then delete the last char of pRootFolder
   set the itemdelimiter to slash

   if pFilename is empty then return empty
   if pRootFolder is empty then return pFilename

   # Is pFilename a child directory of pRootFolder?
   if pRootFolder is item 1 to (the number of items of pRootFolder) of pFilename then
      delete char 1 to length(pRootFolder) + 1 of pFilename
   else if pFilename is char 1 to length(pFilename) of pRootFolder then
      delete char 1 to length(pFilename) + 1 of pRootFolder
      put empty into pFilename
      repeat with tIndex = 1 to the number of items of pRootFolder
         put "../" after pFilename
      end repeat
   else
      # determine where paths diverge
      repeat with tIndex = 1 to the number of items of pFilename
         if item tIndex of pFilename is not item tIndex of pRootFolder then
            put tIndex - 1 into tMatchCount
            put the number of items of pRootFolder - tIndex + 1 into tNonMatchCount
            exit repeat
         end if
      end repeat

      if tMatchCount > 0 then
         delete item 1 to tMatchCount of pFilename
      end if

      repeat with tIndex = 1 to tNonMatchCount
         put "../" before pFilename
      end repeat
   end if

   return pFilename
end __makePathRelative

command revIDESetStackFilesProperty pObject, pProperty, pValue
   local tProcessedValue
   put empty into tProcessedValue
   
   -- If the stack in question has a filename then we process.
   local tBaseFilename
   put the effective filename of pObject into tBaseFilename
   if tBaseFilename is not empty then
      repeat for each line tEntry in pValue
         local tStackName, tStackPath
         put item 1 of tEntry into tStackName
         put item 2 to -1 of tEntry into tStackPath
         
         -- Attempt to resolve the referenced stack's path relative to
         -- the base path. This will have no effect if the stack path cannot
         -- be resolved.
         local tResolvedStackPath
         put __resolveStackFilePath(tBaseFilename, tStackPath) into tStackPath
         
         put tStackName & comma & tStackPath & return after tProcessedValue
      end repeat
      delete the last char of tProcessedValue
   else
      put pValue into tProcessedValue
   end if
   
   -- Set the stackFile property to the processed stackFile list
   set the stackFiles of pObject to tProcessedValue
end revIDESetStackFilesProperty

local sResizeA
command revIDESetRectProperty pObject, pProperty, pValue
   switch pProperty
      case "width"
         if pValue is "fit" then
            set the width of pObject to the formattedwidth of pObject
         else if pValue is a number then
            set the width of pObject to pValue
         end if
         break
      case "height"
         if pValue is "fit" then
            set the height of pObject to the formattedheight of pObject
         else if pValue is a number then
            set the height of pObject to pValue
         end if
         break
      case "resize"
         put pValue into sResizeA[pObject]
         break
      case "left"
         if sResizeA[pObject] then
            set the width of pObject to (the width of pObject + the left of pObject - pValue)
         end if
         set the left of pObject to pValue
         break
      case "right"
         if sResizeA[pObject] then
            set the width of pObject to (the width of pObject + pValue - the right of pObject)
         end if
         set the right of pObject to pValue
         break
      case "top"
         if sResizeA[pObject] then
            set the height of pObject to (the height of pObject + the top of pObject - pValue)
         end if
         set the top of pObject to pValue
         break
      case "bottom"
         if sResizeA[pObject] then
            set the height of pObject to (the height of pObject + pValue - the bottom of pObject)
         end if
         set the bottom of pObject to pValue
         break
   end switch
end revIDESetRectProperty

function revIDEGetRectProperty pObject, pProperty
   switch pProperty
      case "resize"
         return sResizeA[pObject]
   end switch
end revIDEGetRectProperty

command revIDESetImageFilename pObjectID, pProperty, pFilename
   if revIDEGetPreference("cImageFileRelative") is not false then
      local tStackPath, tFilePath
      set the itemDelimiter to "/"
      put item 1 to -2 of the filename of stack revTargetStack(pObjectID) into tStackPath
      if tStackPath is not empty then
         put revCalculateRelativePath(tStackPath, pFilename) into tFilePath
         if tFilePath begins with "./" then delete char 1 to 2 of tFilePath
         if tFilePath ends with pFilename then
            --full path contained in relative path, likely a different volume
            --in any case, need to return absolute path
         else if there is a file (tStackPath & slash & tFilePath) then
            put tFilePath into pFilename
         end if
      end if
   end if
   set the filename of pObjectID to pFilename
end revIDESetImageFilename

#############
# Standalone Settings
#############

on revIDEStandaloneSettingsForStack pStackID
   send "revStandaloneSettings" && quote & the short name of pStackID & quote to stack "revStandaloneSettings"
end revIDEStandaloneSettingsForStack

private function __standaloneSettingsInfoFilename
   return "standaloneSettings.tsv"
end __standaloneSettingsInfoFilename

function revIDEStandaloneSettings pStack, pSection
   local tInfo
   put revIDEStandaloneSettingsInfoOfSection(pSection) into tInfo
   
   return __revIDEStandaloneSettingsOfStackForExtension(pStack, tInfo)
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

function revIDEStandaloneSettingsInfoOfExtension pKind
   local tInfoA
   put revIDEExtensionStandaloneSettingsInfo(pKind, true) into tInfoA
   
   local tSectionList
   -- At the moment all per-extension standalone settings are in
   -- the 'basic' section
   put __orderPropArray(tInfoA, "Basic") into tSectionList
   return tSectionList[1]["grouplist"]
end revIDEStandaloneSettingsInfoOfExtension

function revIDEStandaloneSettingsOfExtension pStack, pKind
   local tInfoA
   put revIDEStandaloneSettingsInfoOfExtension(pKind) into tInfoA
   
   return __revIDEStandaloneSettingsOfStackForExtension(pStack, tInfoA, pKind)
end revIDEStandaloneSettingsOfExtension

private function __revIDEStandaloneSettingsOfStackForExtension pStack, pInfoA, pExtension
   local tSettings
   if pExtension is not empty then
      put the cRevStandaloneSettings[pExtension] of pStack into tSettings
   else
      put the customProperties["cRevStandaloneSettings"] of pStack into tSettings
   end if
   
   local tPropsA, tPropName
   set the itemdelimiter to ";"
   repeat for each element tGroup in pInfoA
      repeat for each element tProp in tGroup["proplist"]
         put tProp["property_name"] into tPropName
         put tProp into tPropsA[tGroup["label"]][tPropName]
         if the number of items in tPropName > 1 then
            repeat for each item tRealProp in tPropName
               put tSettings[tRealProp] into \
                     tPropsA[tGroup["label"]][tPropName]["value"][pStack][tRealProp]
            end repeat
         else
            put tSettings[tPropName] into \
                  tPropsA[tGroup["label"]][tPropName]["value"][pStack]
         end if
      end repeat
   end repeat
   return tPropsA
end __revIDEStandaloneSettingsOfStackForExtension

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
   local tError, tStackName
   
   if there is not a file pFilePath then return __revIDEError("Specified file does not exist")

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
      
      # AL-2015-06-09: [[ Bug 14831 ]] If stack is script only, open in script editor
      if the scriptOnly of stack pFilePath then
         revIDEEditScriptOfObject the long id of stack pFilePath
      end if
   end if
end revIDEOpenStack

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
         if tStack is revIDEPaletteToStackName("menubar") or not revIDEStackNameIsIDEStack(tStack) then next repeat
         if the mode of stack tStack is 4 and the visible of stack tStack then
            hide stack tStack
            put tStack & comma & lineOffset(tStack, tOpenStacks) & return after gREVPalettes
         end if
      end repeat
      delete last char of gREVPalettes
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
      put empty into gREVPalettes
   end if
   unlock screen
end revIDETogglePaletteView

function revIDEGetAllPlugins
   local tUserPlugins
   put revAbsoluteFolderListing(revEnvironmentUserPluginsPath()) into tUserPlugins
   
   local tEnvironmentPlugins
   put revAbsoluteFolderListing(revEnvironmentPluginsPath()) into tEnvironmentPlugins
   
   local tFinal
   put revCombineFilePaths(tUserPlugins,tEnvironmentPlugins) into tFinal
   
   local tDevelopmentPlugins
   put revAbsoluteFolderListing(revEnvironmentDevelopmentPluginsPath()) into tDevelopmentPlugins
   
   if tDevelopmentPlugins is not empty then
      put revCombineFilePaths(tFinal,tDevelopmentPlugins) into tFinal
   end if
   return tFinal
end revIDEGetAllPlugins
   
on revIDEPopupContextualMenu pTargets
   dispatch "revMenubarPopupContextualMenu" to stack revIDEPaletteToStackName("menubar") with pTargets
end revIDEPopupContextualMenu

local sPluginsA
on revIDEUpdatePlugins
   global gREVStartupList, gREVShutdownlist, gREVDontLoadMenus
   
   local tFinal
   put revIDEGetAllPlugins() into tFinal
   
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
            put true into tPluginsA[tName]["startup"]
         else if the cREVLoadInfo["load"] of stack tStack is "shutdown" then
            put true into tPluginsA[tName]["shutdown"]
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
      ideMessageSend "idePluginsChanged"
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
   --return pString && "(Localised String)"
   return pString
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

   local tToolsRight
   put the right of stack revIDEPaletteToStackName("tools") into tToolsRight
   
   local tLeft, tScreenRect
   put revIDEStackScreenRect(revIDEPaletteToStackName("tools"), true) into tScreenRect
   if tToolsRight < (item 3 of tScreenRect / 2) then put tToolsRight + 20 into tLeft
   else put item 1 of tScreenRect + 20 into tLeft
   set the topLeft of the templateStack to tLeft,(the bottom of stack revIDEPaletteToStackName("menubar") + 40)

   # Create the new stack
   lock messages
   create stack
   show stack it
   unlock messages

   # Final items
   reset the templateStack
   
   # Send the 'ideNewStack' message
   ideMessageSend "ideNewStack", it
   
    # Update the active stacks
   ideMessageSend "ideActiveStacksChanged"
   
   # Return the created stack long id
   return it
end revIDENewMainstack

/*
Summary: Get the screenLoc for a stack based on the screen the stack is on

Parameters:
pStackName (string): The name of a stack
pWorking (boolean): If true return the loc relative to OS screen furniture rather than the full screen

Returns: The screenLoc of the screen the stack is on
*/
function revIDEStackScreenLoc pStackName, pWorking
   local tScreenRect
   put revIDEStackScreenRect(pStackName, pWorking) into tScreenRect
   
   local tScreenWidth
   put item 3 of tScreenRect - item 1 of tScreenRect into tScreenWidth
   
   local tScreenHeight
   put item 4 of tScreenRect - item 2 of tScreenRect into tScreenHeight
   
   return item 1 of tScreenRect + (tScreenWidth div 2),item 2 of tScreenRect + (tScreenHeight div 2)
end revIDEStackScreenLoc

/*
Summary: Get the screenRect for a stack based on the screen the stack is on

Parameters:
pStackName (string): The name of a stack
pWorking (boolean): If true return the loc relative to OS screen furniture rather than the full screen

Returns: The screenRect of the screen the stack is on
*/
function revIDEStackScreenRect pStackName, pWorking
   local tRect
   if pWorking then
      put line (the screen of stack pStackName) of the working screenRects into tRect
   else
      put line (the screen of stack pStackName) of the screenRects into tRect
   end if
   if tRect is empty then
      return 0,0,0,0
   end if
   
   return tRect
end revIDEStackScreenRect

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
   
   # Return the created stack long id
   return the result
end revIDEActionNewMainstack

on revIDEActionNewCard
   local tFilterStack
   put the short name of the topStack into tFilterStack
   if revFilterStacksList(tFilterStack) is empty then 
      revIDEActionNewMainstack "default"
   end if
   set the defaultStack to the topStack 
   local tCardID
   create card
   put the long id of it into tCardID
   revIDESetEdited the short name of this stack
   ideMessageSend "ideNewCard tCardID"
   
   # Return the card id
   return tCardID
end revIDEActionNewCard

on revIDEActionDeleteCard
   revIDEDeleteCard the long id of this card of the topStack
end revIDEActionDeleteCard

on revIDEDeleteCard pLongID
   answer error "Are you sure you want to delete" && the long name of pLongID & "?" with "Yes" or "No"
   if it is not "yes" then exit revIDEDeleteCard
   delete pLongID
   
  revIDESetEdited the short name of ideStackOfObject(pLongID)
end revIDEDeleteCard

/*
Creates a new script only stack in memory.

Associations: stack

pName (String): The name of the script only stack.

Example:
revIDENewScriptOnlyStack "MyNewScriptOnlyStack"

Tags: ide
*/
on revIDENewScriptOnlyStack pName
   revIDENewScriptOnlyStackWithScript pName
   if the result is empty then
      return it for value
   else
      return the result for error
   end if
end revIDENewScriptOnlyStack

/*
Creates a new script only stack in memory with a given script.

Associations: stack

pName (String): The name of the script only stack.
pScript (String): The script of the stack.

Example:
revIDENewScriptOnlyStack "MyNewScriptOnlyStack"

The result:
An error string if the stack could not be created

It:
The long id of the newly created stack

Tags: ide
*/
on revIDENewScriptOnlyStackWithScript pName, pScript
   if pName is empty then return __revIDEError("Script only stacks cannot be created without a name") for error
   if there is a stack pName then return "A stack with that name already exists" for error
   
   local tLongID
   create script only stack pName
   put it into tLongID
   
   set the script of tLongID to pScript
   
   edit the script of tLongID
   return tLongID for value
end revIDENewScriptOnlyStackWithScript

on revIDEActionNewScriptOnlyStack
   # Get the name of the stack
   ask revIDELocalise("Please enter a name for the script only stack")
   if the result is "cancel" then exit revIDEActionNewScriptOnlyStack
   if it is empty then exit revIDEActionNewScriptOnlyStack

   # Create script only
   revIDENewScriptOnlyStack it

   # If an error occurred, tell the user
   if the result is not empty then
      answer the result
   end if
end revIDEActionNewScriptOnlyStack

on revIDENewSubstack
   # Get the current stack
   local tCurrentStack
   put the short name of the topStack into tCurrentStack
   revIDENewSubstackOfStack tCurrentStack
end revIDENewSubstack

/*
Creates a new substack.

Associations: stack

pStack (String): The long ID of the stack to attach the substack to.

Example:
revIDENewSubstackOfStack the long ID of the topstack

Tags: ide
*/
on revIDENewSubstackOfStack pStack
   lock screen
   if the mainStack of stack pStack is not pStack then put the mainStack of stack pStack into pStack
   
   # Create a new stack
   revIDENewMainstack
   
   # Make the new stack a substack of the current stack
   set the mainStack of the topStack to pStack
   unlock screen
end revIDENewSubstackOfStack

on revIDEActionOpenStack
   # Popup a file choose
   revIDEAnswerFileWithTypes "stack,all"
   
   # Get the path of to the file
   local tStackFilePaths
   put the result into tStackFilePaths
   
   repeat for each line tStackFilePath in tStackFilePaths
      # Check the stack exists
      if there is not a file tStackFilePath then exit revIDEActionOpenStack
      
      # Open the stack
      revIDEOpenStack tStackFilePath
   end repeat
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
      if pDestroy is true then
         revIDERemoveFromMemory pStackID
      else
         close stack pStackID
      end if
   end if
end revIDECloseStack

private on __ideRemoveFromMemory pStackID
   # OK-2008-08-18: Bug 6932 - Update the script editor here as messages is locked when deleting the stack
   revIDEHandleObjectDeleted pStackID
   
   local tSubstacks
   put the subStacks of stack pStackID into tSubstacks
   
   lock messages -- prevent user stack saving during the close, erasing substacks
   repeat for each line tSubStack in tSubstacks
      close stack tSubStack
   end repeat
   delete stack pStackID
   unlock messages
end __ideRemoveFromMemory

on revIDERemoveFromMemory pStackID
   local tMainstack
   put the mainStack of stack pStackID into tMainstack
   
   local tSubstacks
   put the subStacks of stack pStackID into tSubstacks
   
   local tStacks 
   put tMainStack & cr & tSubstacks into tStacks
   answer warning "Really remove the stack file" && pStackID && "from memory?" & cr & "Any changes made since saving will be lost from the following stacks:" & cr & cr & tStacks with "Cancel" or "OK" as sheet
   if it is "Cancel" then 
      exit revIDERemoveFromMemory
   end if
   
   __ideRemoveFromMemory the long id of stack tMainstack
   
   # Send the 'ideDestroyStack' message
   ideMessageSend "ideDestroyStack", pStackID
end revIDERemoveFromMemory

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
      close this stack
      exit revIDEActionCloseStack
   end if

   revIDECloseStack the long ID of stack tStack, false
end revIDEActionCloseStack

on revIDEDeleteSubstack pSubstackID
   if the mainstack of pSubstackID is the short name of pSubstackID then
      # Not a substack
      exit revIDEDeleteSubstack
   end if
   
   if revSaveCheck(pSubstackID) is not false then
      answer warning "Really remove the stack file" && pSubstackID && "from memory?" & cr & "Any changes made since saving will be lost" with "Cancel" or "OK" as sheet
      if it is "Cancel" then 
         exit revIDEDeleteSubstack
      end if
      
      # Detach from mainstack
      local tStackName
      lock messages
      put the short name of pSubstackID into tStackName
      set the mainstack of pSubstackID to tStackName
      unlock messages
      # Close and remove from memory
      __ideRemoveFromMemory the long id of stack tStackName
      
      # Send the 'ideDestroyStack' message
      ideMessageSend "ideDestroyStack", pSubstackID
   end if
end revIDEDeleteSubstack

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
   return "image,video,audio,text,graph"
end revIDEImportableControls

function revIDELiveCodeFileExtensions
   return revIDEAcceptedTypes("stack")
end revIDELiveCodeFileExtensions

function revIDEFileHasStackfileExtension pFile
   local tExtensions
   put revIDELiveCodeFileExtensions() into tExtensions
   set the linedelimiter to "."
   return line -1 of pFile is among the items of tExtensions
end revIDEFileHasStackfileExtension

function revIDEAcceptedTypes pType
   local tTypes
   switch pType
      case "image"
         return "jpg,jpeg,jfif,gif,png,bitmap,bmp,dib,vga,pict,pict2,pic,svg"
      case "video"
         put "mp4,mpg,mpeg,mov" into tTypes 
         if the platform is "win32" then
            put ",wmv,avi" after tTypes
         end if 
         return tTypes
      case "audio"
         put "au,aiff,aifc,aif,wav,mp3,aac,m4a" into tTypes
         if the platform is "win32" then
            put ",wma" after tTypes
         end if
         return tTypes
      case "media"
         return revIDEAcceptedTypes("audio") & comma & revIDEAcceptedTypes("video")
      case "stack"
         return "livecode,rev,lc,livecodescript,mc"
      case "text"
         return "txt"
      case "graph"
         return "csv"
      case "all"
      default
         return ""
   end switch
end revIDEAcceptedTypes

on revIDEActionImportControl pType, pReferenced
   if pType is not among the items of revIDEImportableControls() then exit revIDEActionImportControl
   
   # Ask the user to pick a file of the given type
   revIDEAnswerFile pType
   
   # User has not chosen a file
   if the result is "cancel" then exit revIDEActionImportControl
   
   local tFiles
   put the result into tFiles
   lock screen
   lock messages
   repeat for each line tFile in tFiles
      if there is not a file tFile then next repeat
      # Import the control
      if pReferenced is true then
         revIDEImportControl pType, tFile, true
      else
         revIDEImportControl pType, tFile
      end if
   end repeat
   unlock messages
   unlock screen
end revIDEActionImportControl

on revIDEActionImportControlFromFolder pType, pReference
   answer folder revIDELocalise("Please select a folder to import from")
   
   if the result is "cancel" then exit revIDEActionImportControlFromFolder
   local tFolderPath
   put it into tFolderPath
   
   local tAcceptedTypes
   put revIDEAcceptedTypes(pType) into tAcceptedTypes
   replace "," with "." in tAcceptedTypes
   
   # Store the current default folder
   revIDEPushDefaultFolder tFolderPath
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
   revIDEPopDefaultFolder
end revIDEActionImportControlFromFolder

on revIDEImportControl pType, pFileName, pReferenced
   if pType is not among the items of revIDEImportableControls() then return __revIDEError("Cannot import that type of control")
   if there is not a file pFileName then exit revIDEImportControl
   
   local tTargetStack, tCreatedControlLocation
   put the long ID of the topstack into tTargetStack
   put the loc of card 1 of the topstack into tCreatedControlLocation
   
   local tCreatedControlID, tFileContents
   lock screen
   lock messages
   set the defaultStack to tTargetStack
   switch pType
      case "image"
         if pFileName ends with ".svg" then
            -- SVG files can't be referenced
            revIDECreateObject "com.livecode.interface.classic.image", tTargetStack, tCreatedControlLocation
            put the long id of the last control into tCreatedControlID
            set the text of tCreatedControlID to drawingSvgCompileFile(pFileName)
         else if pReferenced is true then
            ## Create a classic image control with default properties
            ## Set the filename of the new image control to the referenced image
            revIDECreateObject "com.livecode.interface.classic.image", tTargetStack, tCreatedControlLocation
            put the long id of the last control into tCreatedControlID
            set the filename of tCreatedControlID to pFileName
         else
            ## Create an image control by importing the image file onto the stack
            ## Importing a paint file preserves the image file properties
            ## In particualar the repeatCount property is set to -1 for animated gifs and 0 for other images
            import paint from file pFileName
            put the long id of the last image into tCreatedControlID
         end if
         set the borderWidth of tCreatedControlID to 0
         select tCreatedControlID
         break
      case "audio"
         import AudioClip from file pFileName
         put the long id of the last audioclip into tCreatedControlID
         break
      case "video"
         if pReferenced is true then
            revIDECreateObject "com.livecode.interface.classic.player", tTargetStack, tCreatedControlLocation
            put the result into tCreatedControlID
            set the filename of tCreatedControlID to pFileName
         else
            import videoclip from file pFileName
            put the long id of the last videoclip into tCreatedControlID
         end if
         break
      case "text"
         revIDECreateObject "com.livecode.interface.classic.field", tTargetStack, tCreatedControlLocation
         put the result into tCreatedControlID
         put revIDEUTF8FileContents(pFileName) into tFileContents
         set the text of tCreatedControlID to tFileContents
         select tCreatedControlID
         break
      case "graph"
         revIDECreateObject "com.livecode.widget.lineGraph", tTargetStack, tCreatedControlLocation
         put the result into tCreatedControlID
         put revIDEUTF8FileContents(pFileName) into tFileContents
         set the graphData of tCreatedControlID to tFileContents
         select tCreatedControlID
         break
   end switch
   
   set the itemdel to slash
   set the name of tCreatedControlID to the last item of pFileName
   unlock messages
   unlock screen
   return tCreatedControlID
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

/*
A version of revIDEAnswerFile with a higher level notion of 'type'.

pTypes: a comma delimited list of types, which can be any of the following:
- "stack": select a stackfile
- "image": select an image file
- "video": select a video file
- "audio": select an audio file
- "media": select an audio or video file
- "text": select a text file
- "all": select any file

pInstructions (optional string): the text to use as the file selection prompt.
pBasePath (optional string): the default path to open the dialog at.
pSingleFile (optional boolean): whether to restrict the selection to a single file or not 
*/
on revIDEAnswerFileWithTypes pTypes, pInstructions, pBasePath, pSingleFile
   local tTypesA
   repeat with x = 1 to the number of items in pTypes
      put __answerGetTypeString(item x of pTypes) into tTypesA[x]
   end repeat
   if pInstructions is empty then
      put __answerGetDefaultInstructions(item 1 of pTypes) into pInstructions
   end if
   revIDEAnswerFile "", pInstructions, pBasePath, tTypesA, pSingleFile
end revIDEAnswerFileWithTypes
   
private function __answerGetTypeString pType
   local tTagString
   switch pType
      case "stack"
         put revIDELocalise("LiveCode Stacks") into tTagString
         break
      case "image"
         put revIDELocalise("Images") into tTagString
         break
      case "video"
         put revIDELocalise("Videos") into tTagString
         break
      case "text"
         put revIDELocalise("Text Files") into tTagString
         break
      case "audio"
         put revIDELocalise("Audio Files") into tTagString
         break
      case "media"
         put revIDELocalise("All Media Files") into tTagString
         break
      case "graph"
         put revIDELocalise("All CSV Files") into tTagString
         break
      case "all"
      default
         put revIDELocalise("All Files") into tTagString
         break
   end switch
   
   return tTagString & "|" & revIDEAcceptedTypes(pType) & "|"
end __answerGetTypeString

private function __answerGetDefaultInstructions pType
   switch pType
      case "stack"
         return revIDELocalise("Please select a LiveCode stack") 
      case "image"
         return revIDELocalise("Please select an image") 
      case "video"
         return revIDELocalise("Please select a video")
      case "text"
         return revIDELocalise("Please select the file containing the text to import")
      case "audio"
         return revIDELocalise("Please select an audio file")
      case "media"
         return revIDELocalise("Please select a media file")
      case "graph"
         return revIDELocalise("Please select a csv file")
      case "all"
      default
         return revIDELocalise("Please select a file")
   end switch
end __answerGetDefaultInstructions

on revIDEAnswerFile pType, pInstructions, pBasePath, pTypesA, pSingleFile
   local tInstructions
   if pInstructions is empty then
      put __answerGetDefaultInstructions(pType) into pInstructions
   else
      put pInstructions into tInstructions
   end if
   
   local tTypesA
   if pTypesA is empty then
      put __answerGetTypeString(pType) into tTypesA[1]
   else
      put pTypesA into tTypesA
   end if
   
   # Build the answer string from the various components
   local tAnswerString
   put "answer file" into tAnswerString
   if not pSingleFile then
      put "s" after tAnswerString
   end if
   put " pInstructions" after tAnswerString
   
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
      delete byte 1 to 4 of it
      
      if it mod 100 is 0 then
         return it div 1000 & "." & it mod 1000 div 100
      else
         -- just in case
         return it div 1000 & "." & it mod 1000 div 100 & "." & it mod 100 div 10
      end if
   else
      return "2.4"
   end if
end revIDEStackFileVersion

function revIDEStackFileIsScriptOnly pStackFile
   open file pStackFile for text read
   read from file pStackFile for 1 line
   close file pStackFile
   return matchText(it, "script \".*\"")
end revIDEStackFileIsScriptOnly

-- The revIDESaveStack and revIDESaveStackAs handlers use the "save"
-- command with messages locked, which prevents the "saveStackRequest"
-- message from being sent to the stack being operated on.  However,
-- stacks may want to do work in "saveStackRequest", or even try block
-- saving entirely by handling the message rather than passing it.
--
-- This function synthesizes a "saveStackRequest" message to the stack
-- <tStackName>.  If the message was handled by the stack, but not
-- passed, it returns "handled"; otherwise, it returns "passed" or
-- "unhandled".
--
-- In order to prevent "saveStackRequest" from being intercepted by
-- revfrontscriptlibrary, this function sets the magical global
-- variable gREVAllowSaveStackRequest.
--
-- See bug 5569, bug 5890 and bug 16992
private function ideDispatchSaveStackRequest pStackName
   local tDispatchStatus, tDefaultStack
   global gREVAllowSaveStackRequest

   put true into gREVAllowSaveStackRequest
   put the defaultStack into tDefaultStack
   put "unhandled" into tDispatchStatus

   try
      set the defaultStack to pStackName
      dispatch "saveStackRequest" to this card of stack pStackName
      put it into tDispatchStatus
   end try

   put false into gREVAllowSaveStackRequest
   set the defaultStack to tDefaultStack

   return tDispatchStatus
end ideDispatchSaveStackRequest

local sStackEdited
command revIDESetEdited pStackName
   # Don't set edited on a transient IDE stack (i.e. SE or PI generated)
   if there is a stack pStackName and  \
         the cIDETransient of stack pStackName then
      exit revIDESetEdited
   end if
   
   # Don't set edited on a stack if it is currently saving
   if pStackName is "revSaving" or the mode of stack "revSaving" is 0 then 
      put true into sStackEdited[pStackName]
   end if
end revIDESetEdited

command revIDESetUnedited pStackName
   put false into sStackEdited[pStackName]
end revIDESetUnedited

function revIDEStackIsEdited pStackName
   if revIDEStackNameIsIDEStack(pStackName) then
      global gRevDevelopment
      # Ignore status of IDE stacks if gRevDevelopment is false
      if not gRevDevelopment then
         return false
      end if
      
      # Ignore status of IDE stacks that are not toplevel
      if the mode of stack pStackName is not 1 then
         return false
      end if
   end if
   
   return sStackEdited[pStackName] is true
end revIDEStackIsEdited

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
   if the effective filename of stack tStackName is empty then
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
   
   local tStackFilename
   put the effective filename of stack tStackName into tStackFilename
   
   local tStackFileVersion
   
   if revIDEGetPreference("cPreserveStackVersion") is true and the scriptOnly of stack tMainStack is false then
      put revIDEStackFileVersion(tStackFilename) into tStackFileVersion
      
      local tFileVersions
      put tStackFileVersion into tFileVersions[1]
      put the minStackFileVersion of stack tStackName into tFileVersions[2]
      if highestVersionNumber(tStackFileVersion, tFileVersions[2]) is 2 then
         answer revIDELocalise("The preference to preserve stack file formats is set," && \
               "however, saving this stack file as version %1 will result in data loss." && \
               "The minimum stack file version for this stack is %2.", tFileVersions) \
               with revIDELocalise("Save as %1", tFileVersions) and  revIDELocalise("Save as %2", tFileVersions) and revIDELocalise("Cancel")
         if it is revIDELocalise("Cancel") then
            revIDESetEdited tStackName
            close stack "revSaving"
            return "Cancelled"
         else if it is revIDELocalise("Save as %2", tFileVersions) then
            put tFileVersions[2] into tStackFileVersion
         end if
      end if
   end if
   
   local tStackFileIsScriptOnly
   put revIDEStackFileIsScriptOnly(tStackFilename) into tStackFileIsScriptOnly
   
   if the scriptOnly of stack tMainStack and not tStackFileIsScriptOnly then
      answer revIDELocalise("Saving in script only format will result in loss of data as only the script will be saved." && \
            "Are you sure you wish to continue?") with revIDELocalise("No") and revIDELocalise("Yes")
      if it is not revIDELocalise("Yes") then
         revIDESetEdited tStackName
         close stack "revSaving"
         return "Cancelled"
      end if
   end if
   
   if the scaleFactor of stack tStackName is a number then
      set the cREVGeneral["scalefactor"] of stack tStackName to the scalefactor of stack tStackName
   end if
   
   local tOldStackFileType
   put the stackFileType into tOldStackFileType
   if the cPreserveStackCreator of stack "revPreferences" is true then
      local tOldFolder
      put the folder into tOldFolder
      
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
   
   -- Synthesize a "saveStackRequest" message
   if ideDispatchSaveStackRequest(tStackName) is "handled" then
      put empty into tSaveResult
      
   else
      if tStackFileVersion is not empty then
         save stack tStackName with format tStackFileVersion
      else
         save stack tStackName with newest format
      end if
      put the result into tSaveResult
   end if
   
   ## MJ - 17/07/2006 : Bug 3722, it appears these two lines here override the result...
   ## Hence the introduction of the above variable.
   set the stackFileType to tOldStackFileType
   
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
      
      revIDESetUnedited tStackName
      
      local tMainStackList
      put the mainStack of stack tStackName into tMainStackList
      put return & the substacks of stack tStackName after tMainStackList
      repeat for each line tStack in tMainStackList
         if tStack is empty then next repeat
         revIDESetUnedited tStack
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

on revIDESaveStackAs pStackID, pFileName, pVersion
   if not exists (pStackID) then return __revIDEError("Target stack does not exist")
   if pFileName is empty then return __revIDEError("No path provided to save to")

   if pVersion is not empty then
      save pStackID as pFileName with format pVersion
   else
      save pStackID as pFileName with newest format
   end if
   
   local tShortName, tResult
   put the short name of pStackID into tShortName
   put the result into tResult
   if tResult is not empty then
      local tLocaliseSubstitutions
      put tShortName into tLocaliseSubstitutions[1]
      answer revIDELocalise("Can't save stack %1 with error:", tLocaliseSubstitutions) & return & tResult
      close stack "revSaving"
   else
      revIDESetUnedited tShortName
      
      local tMainStackList
      put the mainStack of pStackID into tMainStackList
      put return & the substacks of pStackID after tMainStackList
      repeat for each line tStack in tMainStackList
         if tStack is empty then next repeat
         revIDESetUnedited tStack
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
   local tStackFileType
   local tStackFileIsScriptOnly = true
   
   if there is a file the filename of stack tShortName then 
      put revStackFileVersion(the filename of stack tShortName) into tStackFileType
      put revIDEStackFileIsScriptOnly(the filename of stack tShortName) into tStackFileIsScriptOnly
   end if
   
   # Prepare substitutions for localisation
   local tSubstitutions
   put tShortName into tSubstitutions[1]

   local tStackFilter, tStack24Filter, tStack27Filter, tStack55Filter, tStack70Filter, tStack80Filter
   put (revIDELocalise("LiveCode Stack") & "|livecode,rev|RSTK") into tStackFilter
   put (revIDELocalise("Legacy LiveCode Stack (2.4)") & "|livecode,rev|RSTK") into tStack24Filter
   put (revIDELocalise("Legacy LiveCode Stack (2.7)") & "|livecode,rev|RSTK") into tStack27Filter
   put (revIDELocalise("Legacy LiveCode Stack (5.5)") & "|livecode,rev|RSTK") into tStack55Filter
   put (revIDELocalise("Legacy LiveCode Stack (7.0)") & "|livecode,rev|RSTK") into tStack70Filter
   put (revIDELocalise("Legacy LiveCode Stack (8.0)") & "|livecode,rev|RSTK") into tStack80Filter
   
   local tVersion
   switch 
      case the scriptOnly of stack tShortName
         put "script" after tStackName
         ask file revIDELocalise("Save script only stack %1 as:", tSubstitutions) with tStackName with type (revIDELocalise("LiveCode Script Only Stack") & "|livecodescript|RSTK")
         break
	  case tStackFileType is 8.0
	     ask file revIDELocalise("Save stack %1 as:", tSubstitutions) with tStackName with type tStack80Filter or type tStackFilter or type tStack70Filter or type tStack55Filter or type tStack27Filter or type tStack24Filter
		 break
	  case tStackFileType is 7.0
	     ask file revIDELocalise("Save stack %1 as:", tSubstitutions) with tStackName with type tStack70Filter or type tStackFilter or type tStack80Filter or type tStack55Filter or type tStack27Filter or type tStack24Filter
		 break
      case tStackFileType is 5.5
         ask file revIDELocalise("Save stack %1 as:", tSubstitutions) with tStackName with type tStack55Filter or type tStackFilter or type tStack80Filter or type tStack70Filter or type tStack27Filter or type tStack24Filter
         break
      case tStackFileType is 2.7
         ask file revIDELocalise("Save stack %1 as:", tSubstitutions) with tStackName with type tStack27Filter or type tStackFilter or type tStack80Filter or type tStack70Filter or type tStack55Filter or type tStack24Filter
         break
      case tStackFileType is 2.4
         ask file revIDELocalise("Save stack %1 as:", tSubstitutions) with tStackName with type tStack24Filter or type tStackFilter or type tStack80Filter or type tStack70Filter or type tStack55Filter or type tStack27Filter
         break
      default
         ask file revIDELocalise("Save stack %1 as:", tSubstitutions) with tStackName with type tStackFilter or type tStack80Filter or type tStack70Filter or type tStack55Filter or type tStack27Filter or type tStack24Filter
         break
   end switch
   put the result into tVersion
   
   switch tVersion
      case revIDELocalise("Legacy LiveCode Stack (8.0)")
         put 8.0 into tVersion
         break
      case revIDELocalise("Legacy LiveCode Stack (7.0)")
         put 7.0 into tVersion
         break
      case revIDELocalise("Legacy LiveCode Stack (5.5)")
         put 5.5 into tVersion
         break
      case revIDELocalise("Legacy LiveCode Stack (2.7)")
         put 2.7 into tVersion
         break
      case revIDELocalise("Legacy LiveCode Stack (2.4)")
         put 2.4 into tVersion
         break
      default
         put empty into tVersion
         break
   end switch
   
   # User cancelled the the ask dialog
   if it is empty then
      revIDESetEdited tShortName
      return "Cancelled"
   end if
   
   # MacOS Auotmatically appends the filetype to the filename
   local tFilePath
   if the platform is not "MacOS" and not (it ends with ".rev" or it ends with ".livecode" or it ends with ".livecodescript") then
      put ".livecode" after it
      if the scriptOnly of stack tShortName then
         put "script" after it
      end if
   end if
   put it into tFilePath
   
   local tFileVersions
   put tVersion into tFileVersions[1]
   put the minStackFileVersion of stack tShortName into tFileVersions[2]
   if tVersion is not empty and highestVersionNumber(tVersion, tFileVersions[2]) is 2 then
      answer revIDELocalise("Saving this stack file as version %1 will result in data loss." && \
            "The minimum stack file version for this stack is %2.", tFileVersions) \
            with revIDELocalise("Save as %1", tFileVersions) and  revIDELocalise("Save as %2", tFileVersions) and revIDELocalise("Cancel")
      if it is revIDELocalise("Cancel") then
         revIDESetEdited tShortName
         return "Cancelled"
      else if it is revIDELocalise("Save as %2", tFileVersions) then
         put tFileVersions[2] into tVersion
      end if
   end if
   
   # Display warning if user has not selected the latest file format
   if the scriptOnly of stack tShortName and not tStackFileIsScriptOnly then
      answer revIDELocalise("Saving in script only format will result in loss of data as only" & \
            " the script will be saved. Are you sure you wish to continue?") with revIDELocalise("No") and revIDELocalise("Yes")
      if it is not revIDELocalise("Yes") then
        revIDESetEdited tShortName
         return "Cancelled"
      end if
   end if
   
   # Window and Mac automatically present overwrite dialog
   if the platform is not in "Win32,MacOS" and there is a file tFilePath then
      answer warning revIDELocalise("File exists. Overwrite?") with revIDELocalise("Cancel") or revIDELocalise("OK")
      if it is revIDELocalise("Cancel") then
         return "Cancelled"
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
      revIDESaveStack tMainStackName
   end if


   set the cursor to watch
   lock messages

   # RevOnline fingerprint enables the revOnline uploader automatically overwrite the stack if already uploaded.
   # Because you're saving as a new stack, this fingerprint should be removed.
   revRemoveRevOnlineKey "fingerprint",tShortName

   -- Synthesize a "saveStackRequest" message
   if ideDispatchSaveStackRequest(tShortName) is not "handled" then
      revIDESaveStackAs the long id of stack tShortName, tFilePath, tVersion
   end if

   unlock messages

   return empty
end revIDEActionSaveStackAs

on revIDEMoveSubstackToFile pStackID
   # Validate stack exists
   # Validate stack has a parent
   # Ask for the file to move it for
   # Set filename of stack / remove parent link
end revIDEMoveSubstackToFile

on revIDESaveAsStandalone pTarget
   local tStack
   if exists(pTarget) then
      put the short name of pTarget into tStack
   end if
   # Don't want the build process to be interruptable.
   set the allowInterrupts to false
   //ideMessagesSupressSet "true" - This was in the old message library. In 8.0 messages can't be supressed. Might want to add this in ideMessageSend
   try
      revSaveAsStandalone tStack
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
   ideMessageSend "ideSelectedObjectChanged"
end revIDEUndo

on revIDECut
   # Don't try and cut from a field with lockText true
   if the selectedField is not empty and the lockText of the selectedField then
      exit revIDECut
   end if
   
   lock screen
   
   if the selectedImage is not empty then
      # If the there is a selection in an image using the image selection tool
      # Then make sure no text is selected before doing the cut
      if the selectedText is not empty then 
         lock messages
         select empty
         unlock messages
      end if
      set the defaultStack to revTargetStack(the long id of the selectedImage)
      cut
      unlock screen
      exit revIDECut
   end if
   
   # Ensure the user is aware of the consequences of the cut wrt groups
   if revCheckGroupDelete() then
      cut
   end if
   
   unlock screen
   
   ideMessageSend "ideSelectedObjectChanged"
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
      ideMessageSend "ideSelectedObjectChanged"
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
   
   local tSelObj
   put the selobj into tSelObj
   
   local tMessage
   if tSelObj is empty then
      put the long id of this card into tSelObj
      put "ideNewCard" into tMessage
   else
      put "ideNewControl" into tMessage
   end if
   unlock messages
   unlock screen
   
   repeat for each line tObj in tSelObj
      revIDEMessageSend tMessage, tObj
   end repeat
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
   local tSelObj
   put the selobj into tSelObj
   
   delete
   
   unlock messages
   repeat for each line tObj in tSelObj
      revIDEMessageSend "ideControlDeleted", tObj
   end repeat
   
   ideMessageSend "ideSelectedObjectChanged"
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
         if tCreatedObjects is empty then
            put the long id of it into tCreatedObjects
         else
            put return & the long id of it after tCreatedObjects
         end if
         
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

      ideMessageSend "ideSelectedObjectChanged"
   end if
   unlock screen
   return tCreatedObjects
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
      ideMessageSend "ideSelectedObjectChanged"
   end if
end revIDESelectAll

on revIDEDeselectAll
   select empty
   ideMessageSend "ideSelectedObjectChanged"
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
   ideMessageSend "ideSelectedObjectChanged"
end revIDEInvertObjectSelection

on revIDEChooseBrowseTool
   revIDESetTool "browse"
end revIDEChooseBrowseTool

on revIDEChoosePointerTool
   revIDESetTool "pointer"
end revIDEChoosePointerTool

private function ideUserCanStyleText pObject
   if the owner of pObject is not empty then
      if the short name of the owner of pObject is "styledText" then
         return true
      end if
   end if
   
   return false
end ideUserCanStyleText

on ideActionStyleText pWhich, pValue
   local tSelectedObjects, tSelectedChunk, tIsField
   if the selectedField is not empty then
      put the long id of the selectedField into tSelectedObjects
      put true into tIsField
   else if the selectedObject is not empty then
      put revIDESelectedObjects() into tSelectedObjects
   end if
   
   put the selectedChunk into tSelectedChunk
   
   local tTargetStack, tIDEStack
   put revIDEStackOfObject(line 1 of tSelectedObjects) into tTargetStack
   put revIDEStackIsIDEStack(tTargetStack) into tIDEStack
   repeat for each line tSelectedObject in tSelectedObjects
      if tIDEStack then
         // Allow IDE stacks to handle whether user text style actions are valid on the target
         dispatch "ideStyleTextRequest" to tTargetStack with pWhich, pValue, tSelectedChunk, tSelectedObject
      else
         ideStyleText tSelectedChunk, tSelectedObject, tIsField, pWhich, pValue
      end if
   end repeat
end ideActionStyleText

on ideStyleText pSelectedChunk, pSelectedObject, pIsField, pWhich, pValue
   local tSelectedObject, tSelectedChunk, tTarget, tTargetStack, tFieldVScrollPosition, tFieldHScrollPosition,
   
   if pSelectedChunk is empty and pSelectedObject is empty then
      exit ideStyleText
   end if
   
   if pIsField then
      put the vScroll of pSelectedObject into tFieldVScrollPosition
      put the hScroll of pSelectedObject into tFieldHScrollPosition
      if pSelectedChunk is not empty then
         put pSelectedChunk into tSelectedChunk
         put word 1 to 4 of tSelectedChunk & " " & pSelectedObject into tTarget
      end if
   else
      put the long ID of pSelectedObject into tSelectedObject
      put tSelectedObject into tTarget
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
         if the textShift of tTarget is a number AND the textShift of tTarget is not 0 then 
            put 0 into tTextShiftAmount
         end if

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
               exit ideStyleText
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
         if pSelectedChunk is not empty then
            local tStartChar, tEndChar, tStartPara, tEndPara, tParaFirstChar, tParaLastChar
            put word 2 of pSelectedChunk into tStartChar
            put word 4 of pSelectedChunk into tEndChar
            
            put the lineIndex of char tStartChar of tTarget into tStartPara
            put the lineIndex of char tEndChar of tTarget into tEndPara
            
            repeat with x = tStartPara to tEndPara
               put the charindex of line x of tTarget into tParaFirstChar
               put the charindex of line x of tTarget + the length of line x of tTarget - 1 into tParaLastChar
               set the textAlign of char tParaFirstChar to tParaLastChar of tTarget to pValue
            end repeat
            
         else
            set textAlign of tTarget to pValue
         end if
         break
   end switch
   
   if pIsField then
      set the vScroll of pSelectedObject to tFieldVScrollPosition
      set the hScroll of pSelectedObject to tFieldHScrollPosition
   end if
end ideStyleText

on revIDEStyleTextPlain
   ideActionStyleText "plain"
end revIDEStyleTextPlain

on revIDEStyleTextBold
      ideActionStyleText "bold"
end revIDEStyleTextBold

on revIDEStyleTextItalic
      ideActionStyleText "italic"
end revIDEStyleTextItalic

on revIDEStyleTextUnderline
      ideActionStyleText "underline"
end revIDEStyleTextUnderline

on revIDEStyleTextStrikeOut
      ideActionStyleText "strikeout"
end revIDEStyleTextStrikeOut

on revIDEStyleTextBox
      ideActionStyleText "box"
end revIDEStyleTextBox

on revIDEStyleText3DBox
      ideActionStyleText "threedbox"
end revIDEStyleText3DBox

on revIDEStyleTextLink
      ideActionStyleText "link"
end revIDEStyleTextLink

on revIDEStyleTextSubscript
      ideActionStyleText "subscript"
end revIDEStyleTextSubscript

on revIDEStyleTextSuperscript
      ideActionStyleText "superscript"
end revIDEStyleTextSuperscript

on revIDESetTextFont pFont
      ideActionStyleText "font", pFont
end revIDESetTextFont

on revIDESetTextSize pSize
      ideActionStyleText "size", pSize
end revIDESetTextSize

on revIDESetTextColor pColor
      ideActionStyleText "color", pColor
end revIDESetTextColor

on revIDESetTextAlign pAlign
      ideActionStyleText "align", pAlign
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
         
         local tLine
         if not gREVSuppressMessages then
            put true into gREVSuppressMessages
            # Send the suppress messages toggle message before actually suppressing messages
            ideMessageSend "ideToggleChanged:" & tToggleMessage
            set the lockCursor to false
            repeat for each line tLine in the pendingMessages
               if not revIDEObjectIsOnIDEStack(item 4 to -1 of tLine) then
                  cancel (item 1 of tLine)
               end if
            end repeat
            repeat for each line tLine in the frontScripts
               if not revIDEObjectIsOnIDEStack(tLine) then
                  put tLine & cr after sRestoreState["front"]
                  remove script of tLine from front
               end if
            end repeat
            repeat for each line tLine in the backScripts
               if not revIDEObjectIsOnIDEStack(tLine) then
                  put tLine & cr after sRestoreState["back"]
                  remove script of tLine from back
               end if
            end repeat
            repeat for each line tLine in the stacksInUse
               if not revIDEObjectIsOnIDEStack(tLine) then
                  put tLine & cr after sRestoreState["inUse"]
                  stop using stack tLine
               end if
            end repeat
            revInternal__LoadLibrary "revNoMessagesLibrary"
            exit revIDEToggle
         else
            revInternal__UnloadLibrary "revNoMessagesLibrary"
            put false into gREVSuppressMessages
            repeat for each line tLine in sRestoreState["front"]
               insert script of tLine into front
            end repeat
            repeat for each line tLine in sRestoreState["back"]
               insert script of tLine into back
            end repeat
            repeat for each line tLine in sRestoreState["inUse"]
               start using stack tLine
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
            ideMessageSend "ideSelectedObjectChanged"
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
         revIDESetPreference "cREVScriptDebugMode", not revIDEGetPreference("cREVScriptDebugMode")
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
            revInternal__UnloadLibrary "revRulersScriptLibrary"
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
            set the backDrop to revIDEGetPreference("cBackDropColor")
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
   ideMessageSend "ideToggleChanged:" & tToggleMessage
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

   if the mode of stack tStackName is 0 or the visible of stack tStackName is false then
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

on revIDEDocumentationLoad pSection, pItem, pExtra
   # For now, just open the dictionary
   revIDEOpenPalette "dictionary"
end revIDEDocumentationLoad

on revIDELaunchResource pName
   switch pName
      case "Buy"
         launch url "https://livecode.com/products/livecode-platform/pricing/"
         break
      case "Support"
         launch url "https://livecode.com/resources/support/"
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
         set the _ideoverride of stack "revonline" to true
         go stack "revOnline"
         break
      case "Sample Scripts"
         launch url "http://lessons.runrev.com/m/2592"
         break
      case "Beginners Guide"
         launch url "https://livecode.com/resources/guides/beginners-guide/"
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
      case "Discussion List"
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
   set the defaultStack to the topStack
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
   # TS-2015-09-02: [[ Bug 15854 ]] Set the defaultStack before executing the "stop editing" command.
   set the defaultStack to the topStack
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

on revIDEToggleLockTextOfField pField
   # Make sure we have an field
   if word 1 of pField is not "field" then
      exit revIDEToggleLockTextOfField
   end if
   
   set the lockText of pField to not (the lockText of pField)
end revIDEToggleLockTextOfField

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
      # AL-2015-07-28: [[ Bug 14971 ]] Don't remove the debugger from the frontscripts when sending message
      if char 1 to 3 of the short name of tScript is "rev" and the short name of tScript is not "revDebuggerLibrary" then
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

on revIDEActionInspectObjects
   revIDEOpenInspectorForObjects the selobj
end revIDEActionInspectObjects

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
   put revIDEExtensions("widget", "installed", true) into tDataA
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
      revSetMarkers "true"

      revInternal__UnloadLibrary "revReshapeLibrary"
   end if
end revIDEToggleReshapeGraphic

on revIDEPlaceGroupOnCard pGroupID
   # OK-2009-10-02 : Code was breaking with groups named "Background", and seemed to be overcomplicated.
   set the defaultStack to the topStack
   if pGroupID is not empty then
      place background id pGroupID onto this card
      if the tool is "pointer tool" then
         do ("select background id" & quote & pGroupID & quote)
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

on revIDERelayerControls pObjectList, pMode
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
            relayer tObjectArray[tLayer] to back of owner
         end repeat
         break
      case "bring to front"
         sort lines of tLayers numeric ascending
         repeat for each line tLayer in tLayers
            relayer tObjectArray[tLayer] to front of owner
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
end revIDERelayerControls

on revIDEActionSendToBack
   revIDESendToBack the selobj
end revIDEActionSendToBack

on revIDESendToBack pObjectList
   revIDERelayerControls pObjectList, "send to back"
end revIDESendToBack

on revIDEActionBringToFront
   revIDEBringToFront the selobj
end revIDEActionBringToFront

on revIDEBringToFront pObjectList
   revIDERelayerControls pObjectList, "bring to front"
end revIDEBringToFront

on revIDEActionMoveBackward
   revIDEMoveBackward the selobj
end revIDEActionMoveBackward

on revIDEMoveBackward pObjectList
   revIDERelayerControls pObjectList, "move backward"
end revIDEMoveBackward

on revIDEActionMoveForward
   revIDEMoveForward the selobj
end revIDEActionMoveForward

on revIDEMoveForward pObjectList
   revIDERelayerControls pObjectList, "move forward"
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
      # Flip command can parse arbitrary image chunk expressions as of 6.7.8
      local tImageLongID
      put the long id of tImage into tImageLongID
      if pOrientation is "Horizontal" then
         flip tImageLongID horizontal
      else
         flip tImageLongID vertical
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

private command rotateImageByLongID pLongID, pAngle
   # Force the image reference to begin with the explicit token 'image'
   local tStack
   put revIDEStackOfObject(pLongID) into tStack
   
   local tImageID
   put the id of pLongID into tImageID
   rotate image id tImageID of stack tStack by pAngle
end rotateImageByLongID

on revIDERotateImages pImages, pAngle
   # Make sure targets are all images
   if not revIDEEnsureControlsOfType(pImages, "image") then
      exit revIDERotateImages
   end if
   
   lock screen
   local tPreviousImageQualitySetting
   repeat for each line tImage in pImages
      local tImageLongID
      put the long id of tImage into tImageLongID
      put the resizeQuality of tImageLongID into tPreviousImageQualitySetting
      set the resizeQuality of tImageLongID to "best"
      # Arbitrary chunk expressions do not work with rotate command
      rotateImageByLongID tImageLongID, pAngle
      set the resizeQuality of tImageLongID to tPreviousImageQualitySetting
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

on revIDESetModeOfStack pStack, pMode
   switch pMode
      case "modeless"
         modeless pStack
         break
      case "palette"
         palette pStack
         break
      case "toplevel"
         toplevel pStack
         break
      case "modal"
         modal pStack
         break
   end switch
end revIDESetModeOfStack

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
   put revIDEGetPreference("cREVScriptDebugMode") into gREVRestore["scriptdebugmode"]
   
   revIDESetPreference "cREVScriptDebugMode",false
   
   # OK-2008-05-23 : Suspend any script editors.
   send "revSESuspendEditors" to revScriptEditorMain()
   
   -- Remove front and back scripts that pertain to the IDE
   -- If the shift-key is down, we remove *all* 'rev' front and back scripts, including
   -- the library scripts.
   local tScriptsList, tRemoveFrontList, tRemoveBackList, tLine
   select empty
   if the shiftKey is down then
      put the frontScripts into tScriptsList
      repeat for each line tLine in tScriptsList
         if revIDEObjectIsOnIDEStack(tLine) then
            put tLine & cr after tRemoveFrontList
            remove script of tLine from front
         end if
      end repeat
      put the backScripts into tScriptsList
      repeat for each line tLine in tScriptsList
         if revIDEObjectIsOnIDEStack(tLine) then
            put tLine & cr after tRemoveBackList
            remove script of tLine from back
         end if
      end repeat
   else
      put the frontScripts into tScriptsList
      repeat for each line tLine in tScriptsList
         if the short name of tLine is among the items of "revFrontScriptLibrary,revDebuggerLibrary,revShortCutsLibrary" then
            put tLine & cr after tRemoveFrontList
            remove script of tLine from front
         end if
      end repeat
      put the backScripts into tScriptsList
      repeat for each line tLine in tScriptsList
         if the short name of tLine is "revBackScriptLibrary,revShortCutsLibrary" then
            put tLine & cr after tRemoveBackList
            remove script of tLine from back
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
      if revIDEStackNameIsIDEStack(tStack) then
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
   local tWindowRect
   put revIDEStackScreenRect(the short name of the topStack, true) into tWindowRect
   set the windowBoundingRect to tWindowRect
   
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
   ideSetWindowBoundingRect
   choose gREVRestore["tool"]
   
   -- Restore the script debug mode
   revIDESetPreference "cREVScriptDebugMode", gREVRestore["scriptdebugmode"]
   
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
            put item 1 to -5 of the filename of stack "home" & "/Contents/MacOS/autoupdater" into tCommand
            put quote & tCommand & quote && "install -foregroundupdate" into tCommand
            break
         case "Win32"
            put item 1 to -3 of the filename of stack "home" & "/.setup.exe" into tCommand
            put quote & tCommand & quote && "install -foregroundupdate" into tCommand
            break
         case "Linux"
            -- MDW-2015-12-19 [[fix_installer]] LC8-style setup filename
            if the processor is "x86_64" then
               	put item 1 to -4 of the filename of me & "/setup.x86_64" into tCommand
            else
               	put item 1 to -4 of the filename of me & "/setup.x86" into tCommand
            end if
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
   if revIDEStackIsIDEWindow(pStackName) then
      return true
   end if
   
   return not revIDEStackNameIsIDEStack(pStackName)
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
      put tStacks into sWindowList
   end if
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
   put char 3 to -1 of line (lineOffset("!c",the text of menu "Window")) of the text of menu "Window" into tCurrentStackName
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
Returns an array describing the recently opened stacks.

Returns: A numerically keyed array of recent stack labels and filename

Example:
local tRecentStacks, tRecentList
put revIDERecentFiles() into tRecentStacks
local tStackInfo
repeat with x = 1 to the number of elements in tRecentStacks
   put tRecentStacks[x] into tStackInfo
   put tStackInfo["label"] & "|" tStackInfo["filename"] & return after tRecentList
end repeat
delete the last char of tRecentList
put tRecentList
# stack title|file path
# stack title|file path
# stack title|file path
# ...

Tags: ide
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
   
   # ensure preferences take effect immediately
   __trimRecentStacks tRecentPaths
   
   # Split list into array
   local tRecentPathData
   put tRecentPaths into tRecentPathData
   split tRecentPathData by return
   
   # Generate labels for the stacks. The label is the filename without the file extension
   # If two stacks have the same filename, the minimum path is added to the label to
   # distinguish the entries
   repeat with x = 1 to the number of elements in tRecentPathData
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
   
   __trimRecentStacks tRecentPaths
   
   #Set the preference
   revIDESetPreference "cRecentStackPaths", tRecentPaths
   
   # Notify registered stack of the change by sending an ideRecentStacksChanged message
   -- BB needs to be implemented? Question. The general message sending in the IDE does not have "lock ide messages" option
   -- So calling revIDEAddRecentStack is quick succession.. lets say in an "openAllStacks" handler is going to cause this message 
   -- fire multiple times in quick succession. lock ide messages could prevent the sending of messages and stack/replace them 
   -- and flush the queue on unlock ide messages.. resulting in just one version of the message being sent. 
   ideMessageSend "ideRecentFilesChanged"
end revIDEAddRecentStack

/*
Trims the recent files to the user's preferred number
*/
private command __trimRecentStacks @xStackFiles
   local tNumRecent
   put revIDEGetPreference("cNumRecent") into tNumRecent
   
   if tNumRecent is not an integer then
      revIDESetPreference "cNumRecent",15
      put 15 into tNumRecent
   end if
   
   delete line tNumRecent+1 to -1 of xStackFiles
end __trimRecentStacks

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
   
   -- Preserve the requested left and vertical centering of the field
   local tLoc, tLeft
   put the loc of tLongID into tLoc
   put the left of tLongID into tLeft
   
   local tScript
   put "on closeField;revIDETransientTextChanged;end closeField" into tScript
   put ";on returnInField; revIDETransientTextChanged;end returnInField" after tScript
   put ";on exitField;revIDETransientTextChanged;end exitField" after tScript
   set the script of tLongID to tScript
   set the text of tLongID to pCurrentText
   
   -- Ensure the text fits
   if the formattedWidth of tLongID > the width of tLongID then
      set the width of tLongID to the formattedWidth of tLongID
   end if
   set the height of tLongID to the formattedHeight of tLongID
   set the loc of tLongID to tLoc
   set the left of tLongID to tLeft
   
   local tTargetLongID
   put the long id of the target into tTargetLongID
   put tTargetLongID into sTransientTextField["callback_target"]
   get the textAlign of tTargetLongID 
   if it is not empty then
      set the textAlign of tLongID to it
   end if
   focus on tLongID
   select char 1 to -1 of tLongID
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

function revIDEFolderListing pFolder, pListFiles
   if there is not a folder pFolder then
      return empty
   end if
   
   revIDEPushDefaultFolder pFolder
   
   local tList
   if pListFiles then
      put the files into tList
   else
      put the folders into tList
   end if
   
   filter tList without ".*"
   revIDEPopDefaultFolder
   return tList
end revIDEFolderListing

#############
# Tutorial support
#############

local sTutorialInfo
on revIDETutorialInfoSet pCourse, pTutorial, pLesson, pLocation
   put pLesson into sTutorialInfo["lesson"]
   put pTutorial into sTutorialInfo["tutorial"]
   put pCourse into sTutorialInfo["course"]
   if pLocation is empty then
      put revIDESpecialFolderPath("tutorial") into pLocation
   end if
   put pLocation into sTutorialInfo["location"]
end revIDETutorialInfoSet

on revIDETutorialInfoSetEmpty
   put empty into sTutorialInfo
end revIDETutorialInfoSetEmpty

private function __tutorialLocations
   return (revIDESpecialFolderPath("tutorial") & return & \
         revIDESpecialFolderPath("user tutorial"))
end __tutorialLocations

private function __findTutorialLocation pCourse, pTutorial, pLesson
   local tLocation 
   repeat for each line tLocation in __tutorialLocations()
      local tLessonPath
      put revIDETutorialLessonPath(pCourse, pTutorial, pLesson, tLocation) into tLessonPath
      if there is a file tLessonPath then
         return tLocation
      end if
   end repeat
   
   return __revIDEError("tutorial not found" && pCourse && "-" && pTutorial && "-" && pLesson) for error
end __findTutorialLocation

on revIDEStartTutorial pCourse, pTutorial, pLesson
   local tLocation
   put __findTutorialLocation(pCourse, pTutorial, pLesson) into tLocation
   if tLocation is empty then
      exit revIDEStartTutorial
   end if
   
   revIDETutorialInfoSet pCourse, pTutorial, pLesson, tLocation
   dispatch "revTutorialStart" to stack "revTutorial"
   revIDETutorialProgressChanged
end revIDEStartTutorial

on revIDEStopTutorial   
   dispatch "revTutorialStop" to stack "revTutorial"
   revIDETutorialProgressChanged
   close stack "revTutorial"
end revIDEStopTutorial

function revIDETutorialInProgress
   return sTutorialInfo
end revIDETutorialInProgress

function revIDETutorialResourcePath pTutorialInfo
   local tTutorialPath
   put revIDETutorialPath(pTutorialInfo["course"], pTutorialInfo["tutorial"], \
         pTutorialInfo["location"]) & "/resources" into tTutorialPath
   if there is a folder tTutorialPath then
      return tTutorialPath
   end if
   return __revIDEError("Tutorial resource path not found") 
end revIDETutorialResourcePath

function revIDETutorialInternalResource pRelativePath
   -- first check to see if there is a platform-specific version
   local tPlatformFolder
   switch the platform
      case "win32"
         put "windows" into tPlatformFolder
         break
      case "macos"
         put "mac" into tPlatformFolder
         break
      case "linux"
         put "linux" into tPlatformFolder
         break
      default
         break
   end switch
   
   local tInternalResourceBase
   put revIDETutorialPath(sTutorialInfo["course"], sTutorialInfo["tutorial"], \ 
         sTutorialInfo["location"]) & "/_resources/" into tInternalResourceBase
   
   local tCandidateFile
   if tPlatformFolder is not empty then
      put tInternalResourceBase & slash & tPlatformFolder & slash & pRelativePath into tCandidateFile
      if there is a file tCandidateFile then
         return tCandidateFile
      end if
   end if
   
   put tInternalResourceBase & slash & pRelativePath into tCandidateFile
   if there is a file tCandidateFile then
      return tCandidateFile
   end if
   
   return empty
end revIDETutorialInternalResource

function revIDETutorialUserStackPath pStackTag
   return (revIDESpecialFolderPath("user tutorial") & slash & "Tutorial Data" & slash & sTutorialInfo["course"] & slash & sTutorialInfo["tutorial"] & slash & sTutorialInfo["lesson"] & "-" & pStackTag &".livecode")
end revIDETutorialUserStackPath

on revIDETutorialSave pTaggedObjects, pStepName
   if sTutorialInfo is empty then
      return __revIDEError("No tutorial in progress")
   end if
   
   lock messages
   # Store all the tags for tagged objects as custom properties
   repeat for each element tTagged in pTaggedObjects
      repeat for each key tTag in tTagged
         if exists(tTagged[tTag]) then
            set the cTutorialTag of tTagged[tTag] to tTag
         end if
      end repeat
   end repeat
   
   # Ensure there is a suitable folder to save the stacks
   if pTaggedObjects["stack"] is not empty then
      set the itemdelimiter to slash
      local tUserTutorialFolder
      put item 1 to -2 of revIDETutorialUserStackPath() into tUserTutorialFolder
      revIDEEnsurePath tUserTutorialFolder
   end if
   
   # Save a copy of the current tagged stacks to the user data folder
   local tOldFilename, tFilename, tMainstack, tStackTags
   repeat for each key tStackTag in pTaggedObjects["stack"]
      put pTaggedObjects["stack"][tStackTag] into tMainstack
      put the filename of tMainstack into tOldFilename
      put revIDETutorialUserStackPath(tStackTag) into tFilename
      save stack tMainstack as tFilename with newest format
      set the filename of tMainstack to tOldFilename
      
      if tStackTags is empty then
         put tStackTag into tStackTags
      else
         put return & tStackTag after tStackTags
      end if
   end repeat
   unlock messages
   
   # Update the stored course data
   local tCourseDataA
   put revIDETutorialSavedCourseProgress(sTutorialInfo["course"]) into tCourseDataA
   
   local tLessonDataA
   put tCourseDataA[sTutorialInfo["tutorial"]][sTutorialInfo["lesson"]] into tLessonDataA
   
   put revIDETutorialDonePercentage() into tLessonDataA["progress"]
   put pStepName into tLessonDataA["step"]
   put tStackTags into tLessonDataA["stacks"]
   
   put tLessonDataA into tCourseDataA[sTutorialInfo["tutorial"]][sTutorialInfo["lesson"]]
   
   revIDETutorialSaveCourseProgress sTutorialInfo["course"], tCourseDataA
end revIDETutorialSave

private function __fetchAndRemoveTags pStack
   local tTags
   put the name of pStack into tTags["stack"][the cTutorialTag of pStack]
   
   local tCardLongID
   repeat for each line tLine in the cardIDs of pStack
      put the long id of card id tLine of pStack into tCardLongID
      get the cTutorialTag of tCardLongID
      if it is not empty then
         put tCardLongID into tTags["card"][it]
      end if
      union tTags with __fetchAndRemoveControlTags(tCardLongID)
   end repeat
   return tTags
end __fetchAndRemoveTags

private function __fetchAndRemoveControlTags pCard
   local tControlLongID, tTags
   repeat for each line tLine in the controlIDs of pCard
      put the long id of control id tLine of pCard into tControlLongID
      get the cTutorialTag of tControlLongID
      if it is not empty then
         put tControlLongID into tTags[word 1 of tControlLongID][it]
      end if
   end repeat
   return tTags
end __fetchAndRemoveControlTags

command revIDETutorialUpdateAndRemoveTags pStackName, @xTags
      union xTags with __fetchAndRemoveTags(pStackName)
end revIDETutorialUpdateAndRemoveTags

on revIDETutorialLoad pCourse, pTutorial, pLesson
   local tLocation
   put __findTutorialLocation(pCourse, pTutorial, pLesson) into tLocation
   
   if tLocation is empty then
      exit revIDETutorialLoad
   end if

   revIDETutorialInfoSet pCourse, pTutorial, pLesson, tLocation
   
   local tCourseProgressA, tLessonDataA
   put revIDETutorialSavedCourseProgress(pCourse) into tCourseProgressA
   put tCourseProgressA[pTutorial][pLesson] into tLessonDataA
   
   # Get all the tagged mainstacks and all object tags
   local tStackList, tTags, tStackName
   repeat for each line tStackTag in tLessonDataA["stacks"]
      put the name of stack revIDETutorialUserStackPath(tStackTag) into tStackName
      go invisible stack revIDETutorialUserStackPath(tStackTag)
      set the filename of stack tStackName to empty
      if tStackList is empty then
         put tStackName into tStackList
      else
         put return & tStackName after tStackList
      end if
      
      revIDETutorialUpdateAndRemoveTags tStackName, tTags
   end repeat
   
   dispatch "revTutorialResume" to stack "revTutorial" with tStackList, tTags, tLessonDataA["step"]
end revIDETutorialLoad

/* 
Returns the preference name corresponding to the given course
*/
function revIDETutorialCoursePreferenceName pName
   replace " " with "_" in pName
   return "c" & pName & "Info"
end revIDETutorialCoursePreferenceName

/*
Returns the course progress data stored in the preferences for the given course
*/
function revIDETutorialSavedCourseProgress pName
   return revIDEGetPreference(revIDETutorialCoursePreferenceName(pName))
end revIDETutorialSavedCourseProgress

/*
Stores the course progress data for the given course in the preferences
*/
on revIDETutorialSaveCourseProgress pCourse, pData
   revIDESetPreference revIDETutorialCoursePreferenceName(pCourse), pData
end revIDETutorialSaveCourseProgress

/*
Returns the percentage of the currently open tutorial lesson that is finished
*/
function revIDETutorialDonePercentage
   if sTutorialInfo is empty then
      return 0
   end if
   
   dispatch function "revTutorialDonePercentage" to stack "revTutorial"
   return the result
end revIDETutorialDonePercentage

/*
Lists the courses in the IDE tutorial folder
*/
function revIDETutorialListCourses
   return revIDEFolderListing(revIDESpecialFolderPath("tutorial") & "/courses", false)
end revIDETutorialListCourses

/*
Returns the path to the folder containing the given course
*/
function revIDETutorialCoursePath pCourse, pLocation
   return pLocation & "/courses/" & pCourse
end revIDETutorialCoursePath

/*
Returns the description of the given course
*/
function revIDETutorialCourseDescription pCourse, pLocation
   return revIDEUTF8FileContents(revIDETutorialCoursePath(pCourse, pLocation) \ 
         & slash & "description.txt")
end revIDETutorialCourseDescription

/*
Lists the tutorials in the folder for the given course
*/
function revIDETutorialListTutorials pCourse
   return revIDEFolderListing(revIDETutorialCoursePath(pCourse, \ 
         revIDESpecialFolderPath("tutorial")) & slash & "tutorials", false)
end revIDETutorialListTutorials

/*
Returns the path to the folder containing the given tutorial
*/
function revIDETutorialPath pCourse, pTutorial, pLocation
   return revIDETutorialCoursePath(pCourse, pLocation) & "/tutorials/" & pTutorial
end revIDETutorialPath

/*
Returns the description of the given tutorial
*/
function revIDETutorialDescription pCourse, pTutorial, pLocation
   return revIDEUTF8FileContents(revIDETutorialPath(pCourse, pTutorial, pLocation) \ 
         & slash & "description.txt")
end revIDETutorialDescription

/*
Lists the lessons in the folder for the given tutorial of the given course
*/
function revIDETutorialListLessons pCourse, pTutorial, pLocation
   local tFiles
   put revIDEFolderListing(revIDETutorialPath(pCourse, pTutorial, pLocation) \ 
         & slash & "lessons", true) into tFiles
   replace ".txt" with empty in tFiles
   return tFiles
end revIDETutorialListLessons

/*
Returns the path to the specified lesson
*/
function revIDETutorialLessonPath pCourse, pTutorial, pLesson, pLocation
   return revIDETutorialPath(pCourse, pTutorial, pLocation) \ 
         & slash &"lessons" & slash & pLesson & ".txt"
end revIDETutorialLessonPath

/*
Returns the content of the specified lesson
*/
function revIDETutorialLessonContent pCourse, pTutorial, pLesson, pLocation
   return revIDEUTF8FileContents(revIDETutorialLessonPath(pCourse, pTutorial, pLesson, pLocation))
end revIDETutorialLessonContent

/*
Lists the courses that are always present in the order they should display
*/
function revIDETutorialFixedCourses
   return "Welcome,Getting Started,General Tutorials"
end revIDETutorialFixedCourses

/*
Returns a structured array representing the info of all of the currently available courses
*/
function revIDETutorialCourseInfo
   local tCourseList
   put revIDETutorialListCourses() into tCourseList
   
   local tFixedCourses
   put revIDETutorialFixedCourses() into tFixedCourses
   repeat for each item tItem in tFixedCourses
      delete line lineoffset(tItem, tCourseList) of tCourseList
   end repeat
   
   replace comma with return in tFixedCourses
   if tCourseList is empty then
      put tFixedCourses into tCourseList
   else
      put tFixedCourses & return before tCourseList
   end if
   
   local tCourseDataA, tCount, tCourseProgress, tPercentage
   repeat for each line tCourse in tCourseList
      add 1 to tCount
      put revIDETutorialInfo(tCourse) into tCourseDataA[tCount]["tutorials"]
      put tCourse into tCourseDataA[tCount]["name"]
      put revIDETutorialCourseDescription(tCourse) into tCourseDataA[tCount]["description"]
      put 0 into tPercentage
      repeat for each element tTutorial in tCourseDataA[tCount]["tutorials"]
         add tTutorial["progress"] to tPercentage
      end repeat
      divide tPercentage by the number of elements in tCourseDataA[tCount]["tutorials"]
      put tPercentage into tCourseDataA[tCount]["progress"]
   end repeat
   
   return tCourseDataA
end revIDETutorialCourseInfo

/*
Returns a structured array representing the info of all of the currently available tutorials in the given course
*/
function revIDETutorialInfo pCourse
   local tTutorialList
   put revIDETutorialListTutorials(pCourse) into tTutorialList
   
   sort tTutorialList ascending numeric
   
   local tTutorialDataA, tCount, tPercentage
   repeat for each line tTutorial in tTutorialList
      add 1 to tCount
      put revIDETutorialLessonInfo(pCourse, tTutorial) into tTutorialDataA[tCount]["lessons"]
      put tTutorial into tTutorialDataA[tCount]["name"]
      put revIDETutorialDescription(pCourse, tTutorial) into tTutorialDataA[tCount]["description"]
      put 0 into tPercentage
      
      if tTutorialDataA[tCount]["lessons"] is not empty then
         repeat for each element tLesson in tTutorialDataA[tCount]["lessons"]
            add tLesson["progress"] to tPercentage
         end repeat
         divide tPercentage by the number of elements in tTutorialDataA[tCount]["lessons"]
      end if
      put tPercentage into tTutorialDataA[tCount]["progress"]
   end repeat
   
   return tTutorialDataA
end revIDETutorialInfo

/*
Returns a structured array representing the info of all of the currently available lessons in the given tutorial of the given course
*/
function revIDETutorialLessonInfo pCourse, pTutorial
   local tLessonList
   put revIDETutorialListLessons(pCourse, pTutorial) into tLessonList
   
   local tProgressInfoA
   put revIDETutorialSavedCourseProgress(pCourse) into tProgressInfoA
   
   local tLessonDataA, tCount
   repeat for each line tLesson in tLessonList
      add 1 to tCount     
      put tProgressInfoA[pTutorial][tLesson]["progress"] + 0 into tLessonDataA[tCount]["progress"]      
      put tLesson into tLessonDataA[tCount]["name"]
   end repeat
   
   return tLessonDataA
end revIDETutorialLessonInfo

/*
Called when the tutorial starts a new step
*/
on revIDETutorialProgressChanged
   # Save the current progress
   if sTutorialInfo is not empty then
       dispatch "revTutorialSaveProgress" to stack "revTutorial"
   end if
   
   # Notify any subscribed objects
   ideMessageSend "ideTutorialProgressChanged"
end revIDETutorialProgressChanged

on revIDETutorialSkipToNextSkipPoint
   dispatch "revTutorialSkip" to stack "revTutorial"
end revIDETutorialSkipToNextSkipPoint

##################################################
#
#          IDE DOCS FUNCTIONS
#
##################################################

private function escape pString, pConvertLineEndings
   replace "\" with "\\" in pString
   replace quote with ("\" & quote) in pString
   
   if pConvertLineEndings is true then
      replace CRLF with "\n" in pString
      replace numToCodepoint(13) with "\n" in pString
   end if
   replace LF with "\n" in pString
   replace numToCodepoint(13) with "\r" in pString
   //replace "<" with "&lt;" in pString
   //replace ">" with "&gt;" in pString
   replace tab with "\t" in pString
   return (quote & pString & quote)
end escape

private function __getLCBSourceFile pFolder
   revIDEPushDefaultFolder pFolder
   # Isolate the source file
   local tSource
   put the files into tSource
   filter tSource with "*.lcb"
   revIDEPopDefaultFolder
   return tSource
end __getLCBSourceFile

private function revIDEGetBaseDocsData pWhich
   local tData
   
   local tAPIPath, tLibs
   put revIDESpecialFolderPath("api", pWhich) into tAPIPath
   put files(tAPIPath) into tLibs
   filter tLibs with "*.js"
   local tDoc
   repeat for each line tLibraryJS in tLibs
      put revIDEUTF8FileContents(tAPIPath & slash & tLibraryJS) into tDoc
      if tData is empty then
         put tDoc into tData
      else
         put comma & tDoc after tData
      end if
   end repeat
   
   return tData
end revIDEGetBaseDocsData 

private function revIDEGetExtensionDocsData pAPI
   local tExtensionDocsDataA
   put revIDEExtensionDocsData(pAPI) into tExtensionDocsDataA
   
   local tFolder, tCachedDataFolder
   set the itemdelimiter to slash
   
   local tData
   repeat for each element tExtensionData in tExtensionDocsDataA
      local tExtensionAPI
      put tExtensionData["folder"] into tFolder
      
      local tSource
      put tExtensionData["source_file"] into tSource
      
      # Check if the lcdoc file is out of date
      put revEnvironmentUserDocsPath() & slash & tExtensionData["name"] into tCachedDataFolder
      revIDEEnsurePath tCachedDataFolder
      
      local tInputs
      put empty into tInputs
      if tSource is not empty then
         put tFolder & slash & tSource into tInputs[1]
      end if
      
      # If we are running from source, also add the docs parser as an input 
      # dependency of the docs files
      if not revEnvironmentIsInstalled() then
         put the effective filename of stack "revDocsParser" into \
               tInputs[the number of elements in tInputs + 1]
      end if
      
      local tNeedUpdate, tError, tAPIDoc
      put tCachedDataFolder & slash & "api.lcdoc" into tAPIDoc
      put revIDEIsFilesetStale(tInputs, tAPIDoc, false, tError) \
            into tNeedUpdate
      
      # If there is an up-to-date api.lcdoc in the source folder, just copy that across
      local tSourceAPI
      put tFolder & slash & "api.lcdoc" into tSourceAPI
      if there is a file tSourceAPI then
         if tSource is empty then
            put false into tNeedUpdate
            if there is no file tAPIDoc then
               revIDESetUTF8FileContents tAPIDoc, revIDEUTF8FileContents(tSourceAPI)
            end if
         else if tNeedUpdate then
            if revIDEIsFilesetStale(tInputs, tSourceAPI, false, tError) \
                  is false then 
               
               revIDESetUTF8FileContents tAPIDoc, revIDEUTF8FileContents(tSourceAPI)
               put false into tNeedUpdate
            end if 
         end if
      end if
      # Regenerate the lcdoc file if required
      if tNeedUpdate is true then
         # Generate the docs text in lcdoc format 
         local tDoc
         if tExtensionData["source_type"] is "lcb" then
            dispatch function "revDocsGenerateDocsFileFromModularFile" to stack "revDocsParser" with \
                  tFolder & slash & tSource
            put the result into tDoc
         else if tExtensionData["source_type"] is "lcs" then
            local tStack, tPassword
            try
               put the long id of stack (tFolder & slash & tSource) into tStack
               put the password of tStack into tPassword
            end try
            if tStack is not empty and tPassword is empty then
               dispatch function "revDocsGenerateDocsFileFromText" \
                  to stack "revDocsParser" with \
                  the script of tStack, tStack
               put the result into tDoc
            end if
         end if
         if tDoc is not empty then
            # Output the lcdoc file
		    revIDESetUTF8FileContents tAPIDoc, tDoc
         end if
      end if
      
      local tAPIJS
      put tCachedDataFolder & "/api.js" into tAPIJS
      # Check if the .js is out of date
      if tNeedUpdate is not true then
         put tAPIDoc into tInputs[1]
         put revIDEIsFilesetStale(tInputs, tAPIJS , false, tError) \
               into tNeedUpdate
      end if
      
      if tNeedUpdate is false then
         put revIDEUTF8FileContents(tAPIJS) into tExtensionAPI
      else if tNeedUpdate is true then
         local tLibraryArray, Lcdoc
         dispatch function "revDocsParseDocFileToLibraryArray" to stack "revDocsParser" \ 
               with tAPIDoc, tExtensionData["title"], \ 
               tExtensionData["author"]
         put the result into tLibraryArray
         
         dispatch function "revDocsFormatLibraryDocArrayAsJSON" to stack "revDocsParser" \
               with tLibraryArray
         put the result into tExtensionAPI
         
         # Update the dictionary database
         ideDocsUpdateDatabase pAPI, tLibraryArray, false
         
         revIDESetUTF8FileContents tAPIJS, tExtensionAPI
      end if
      
      if tExtensionAPI is not empty then
         if tData is not empty then
            put comma & tExtensionAPI after tData
         else
            put tExtensionAPI into tData
         end if
      end if
   end repeat
   return tData
end revIDEGetExtensionDocsData

private function revIDEGetDocsAPIData pWhich
   local tData, tExtensions
   put revIDEGetBaseDocsData(pWhich) into tData
   put revIDEGetExtensionDocsData(pWhich) into tExtensions
   if tExtensions is not empty then
      put comma & tExtensions after tData
   end if
   return tData
end revIDEGetDocsAPIData 

private function revIDEGetDocsGuideData
   local tData
   
   local tGuidePath
   put revIDESpecialFolderPath("guide") into tGuidePath
   put revIDEUTF8FileContents(tGuidePath & slash & "distributed_guide.js") into tData
   
   local tExtensionDocsDataA
   put revIDEExtensionDocsData() into tExtensionDocsDataA
   
   local tFolder, tCachedDataFolder
   set the itemdelimiter to slash
   repeat for each element tExtensionData in tExtensionDocsDataA
      local tExtensionGuide, tGuideFile
      put empty into tExtensionGuide
      put tExtensionData["folder"] into tFolder
      put revEnvironmentUserDocsPath() & slash & \ 
            tExtensionData["name"] into tCachedDataFolder
      put tFolder & slash & "guide.md" into tGuideFile
      if there is not a file tGuideFile then
         -- User widgets have the guide.md in docs/guide/
         put "/docs/guide" after tFolder
         put tFolder & slash & "guide.md" into tGuideFile
      end if
      if there is not a file tGuideFile then next repeat
      revIDEEnsurePath tCachedDataFolder
      
      # Check if the .js is out of date
      local tNeedUpdate, tError, tGuideJS
      put tCachedDataFolder & "/guide.js" into tGuideJS
      put revIDEIsFilesetStale(tGuideFile, tGuideJS, false, tError) \
            into tNeedUpdate
      
      if tNeedUpdate is false then
         put revIDEUTF8FileContents(tGuideJS) into tExtensionGuide
      else if tNeedUpdate is true then
         local tGuide
         put revIDEUTF8FileContents(tGuideFile) into tGuide
         
         if tGuide is not empty then
            put "{" & CR after tExtensionGuide
            put tab & quote & "name" & quote & ":" && quote & tExtensionData["name"] & quote & comma & CR after tExtensionGuide
            put tab & quote & "display name" & quote & ":" && quote & tExtensionData["title"] & quote & comma & CR after tExtensionGuide
            put tab & quote & "group" & quote & ":" && quote & "Extensions" & quote & comma & CR after tExtensionGuide
            put tab & quote & "location" & quote & ":" && quote & tFolder & quote & comma & CR after tExtensionGuide
            put quote & "data" & quote & ":" & escape(tGuide, true) & CR after tExtensionGuide
            put "}" after tExtensionGuide
            
            revIDESetUTF8FileContents tGuideJS, tExtensionGuide
         end if
      else
         -- FIXME There is some inconsistency in the guide's files that we
         -- can't cope with
      end if
      
      if tExtensionGuide is not empty then
         put comma & tExtensionGuide after tData
      end if
   end repeat
   
   return tData
end revIDEGetDocsGuideData

on revIDERegenerateBuiltGuides
   local tData
   
   # Get the location of the distributed guide
   local tGuidePath
   put revIDESpecialFolderPath("guide") into tGuidePath
   
   put "var tUserGuideData =" & CR & "{" & CR & tab & quote & "guides" & quote & ":[" into tData
   
   put revIDEGetDocsGuideData() after tData
   
   put CR & tab & "]" & CR & "}" after tData
   
   local tDocsCache
   put revIDESpecialFolderPath("documentation cache") into tDocsCache
   revIDESetUTF8FileContents tDocsCache & slash & "built_guide.js", tData
end revIDERegenerateBuiltGuides

constant kAPIs = "LiveCode Script,livecode_script|LiveCode Builder,livecode_builder|LiveCode IDE,livecode_ide"
on revIDERegenerateBuiltAPIs
   local tData, tAPIData
   set the lineDelimiter to "|"
   repeat for each line tAPI in kAPIs
      -- For now, the IDE API is BFS only
      if item 2 of tAPI is "livecode_ide" and revEnvironmentIsInstalled() then
         next repeat
      end if
      
      put revIDEGetDocsAPIData(item 2 of tAPI) into tAPIData
      dispatch function "revDocsCreateAPIJSON" to stack "revDocsParser" \
            with item 1 of tAPI, item 2 of tAPI, "", tAPIData
      if tData is empty then
         put the result into tData
      else
         put comma & the result after tData
      end if
   end repeat
   
   local tDictionaryData
   put "var dictionary_data =" & return & "{" & return & \
         tab & quote & "docs" & quote & ":[" & \
         tData & return & tab & "]" & return & "}" \
         into tDictionaryData
   
   local tDocsCache
   put revIDESpecialFolderPath("documentation cache") into tDocsCache
   revIDESetUTF8FileContents tDocsCache & slash & "built_api.js", tDictionaryData
end revIDERegenerateBuiltAPIs

on revIDERegenerateBuiltDictionaryData
   revIDERegenerateBuiltAPIs
   revIDERegenerateBuiltGuides
end revIDERegenerateBuiltDictionaryData

on revIDEGenerateDistributedDocs
   start using stack (revEnvironmentRepositoryPath() & slash & "ide-support" & slash & "revdocsparser.livecodescript")
   revIDEGenerateDistributedGuide
   revIDEGenerateDistributedAPI
   revIDERegenerateBuiltDictionaryData
end revIDEGenerateDistributedDocs

private on revIDEGenerateDistributedGuide
   # Set the default folder to where the guide markdown files are stored in the IDE
   local tGuideFoldersWithLocationA
   put revIDESpecialFolderPath("ide guides") into tGuideFoldersWithLocationA[1]["folder"]
   put "ide" into tGuideFoldersWithLocationA[1]["location"]
   
   if not revEnvironmentIsInstalled() then
      put revIDESpecialFolderPath("repo guides") into tGuideFoldersWithLocationA[2]["folder"]
      put "repo" into tGuideFoldersWithLocationA[2]["location"]
   end if
   
   local tGuideJSONFile
   put revIDESpecialFolderPath("guide") & slash & "distributed_guide.js" \
         into tGuideJSONFile

   # Check if the distributed guide is out of date
   local tKey, tInputFiles, tNeedUpdate, tError
   repeat for each key tKey in tGuideFoldersWithLocationA
      put tGuideFoldersWithLocationA[tKey]["folder"] into tInputFiles[tKey]
   end repeat
   put revIDEIsFilesetStale(tInputFiles, tGuideJSONFile, true, tError) \
         into tNeedUpdate

   # If we don't need to regenerate, exit
   if tNeedUpdate is not true then
      exit revIDEGenerateDistributedGuide
   end if
   
   local tOrderedGuidesA, tOrderFolder
   put revIDESpecialFolderPath("ide guides") into tOrderFolder
   put revDocsOrderedGuideData(tGuideFoldersWithLocationA, tOrderFolder) into tOrderedGuidesA
   
   local tGuideData
   repeat for each element tGuideA in tOrderedGuidesA
      put tab & "{" after tGuideData
      put return & revDocsFormatGuideDataAsJSON(tGuideA) after tGuideData
      put return & tab & "}," after tGuideData
   end repeat
   delete the last char of tGuideData
   
   # Write out to apropriate location
   revIDESetUTF8FileContents tGuideJSONFile, tGuideData
end revIDEGenerateDistributedGuide

private command revIDEGenerateDistributedAPI
   local tRepoPath
   put revEnvironmentRepositoryPath() into tRepoPath
   
   local tDocsFolder
   put tRepoPath & slash & "docs" into tDocsFolder
   if there is not a folder tDocsFolder then
      answer "No dictionary data found at" && tDocsFolder
   end if
   
   # Check to see if we need to regenerate the script dictionary
   local tNeedUpdate, tInputs, tError, tOutput
   put the effective filename of stack "revDocsParser" into tInputs[0]
   put tDocsFolder & slash & "dictionary" into tInputs[1]
   put tDocsFolder & slash & "glossary" into tInputs[2]
   put revIDESpecialFolderPath("api", "livecode_script") & slash & "script.js" into tOutput
   
   put revIDEIsFilesetStale(tInputs, tOutput, true, tError) into tNeedUpdate
   
   # Regenerate dictionary if necessary
   if tNeedUpdate then
      local tScriptA
      put "LiveCode Script" into tScriptA["display name"]
      put revDocsModifyForUrl(tScriptA["display name"]) into tScriptA["name"]
      put "LiveCode" into tScriptA["author"]
      put "dictionary" into tScriptA["type"]
      # Parse the dictionary files into a structured array
      put revDocsParseDictionaryToLibraryArray(tDocsFolder) into tScriptA["doc"]
      
      # Update the database
      ideDocsUpdateDatabase "livecode_script", tScriptA, true
      
      local tJSON
      put revDocsFormatLibraryDocArrayAsJSON(tScriptA) into tJSON
      revIDESetUTF8FileContents revIDESpecialFolderPath("api", "livecode_script") & slash & "script.js", \
            tJSON
   end if
   
   # Check to see if we need to regenerate the builder dictionary
   local tModuleList
   put revDocsGetBuiltinModuleList(revEnvironmentBinariesPath() & slash & "modules" & slash & "lci", tRepoPath) into tModuleList
   
   set the itemdelimiter to slash
   put empty into tInputs
   put revIDESpecialFolderPath("api", "livecode_builder") & slash & "builder.js" into tOutput
   put the effective filename of stack "revDocsParser" into tInputs[0]
   local tCount
   put 1 into tCount
   repeat for each line tLine in tModuleList
      put tLine into tInputs[tCount]
      add 1 to tCount
   end repeat
   
   put revIDEIsFilesetStale(tInputs, tOutput, false, tError) into tNeedUpdate
   
   # Regenerate dictionary if necessary
   if tNeedUpdate then
      local tModularA, tModularCount, tBlocksA, tParsedA
      put 1 into tModularCount
      set the itemdelimiter to "."
      repeat for each line tLine in tModuleList
         if item -1 of tLine is "lcdoc" then
            get url("file:" & tLine)
         else
            get revDocsGenerateDocsFileFromModularFile(tLine)
         end if
         if it is not empty then
            put it into tModularA[tModularCount]
            add 1 to tModularCount
         end if
      end repeat
      
      local tBuilderA
      put 1 into tModularCount
      repeat for each element tElement in tModularA
         put revDocsParseDocText(tElement) into tParsedA
         repeat for each key tEntry in tParsedA["doc"]
            put tParsedA["doc"][tEntry] into tBuilderA["doc"][tModularCount]
            add 1 to tModularCount
         end repeat
         put empty into tParsedA
      end repeat
      put "LiveCode Builder" into tBuilderA["display name"]
      put revDocsModifyForUrl(tBuilderA["display name"]) into tBuilderA["name"]
      put "LiveCode" into tBuilderA["author"]
      put "dictionary" into tBuilderA["type"]
      
      # Update the database
      ideDocsUpdateDatabase "livecode_builder", tBuilderA, true
      
      put revDocsFormatLibraryDocArrayAsJSON(tBuilderA) into tJSON
      revIDESetUTF8FileContents revIDESpecialFolderPath("api", "livecode_builder") & slash & "builder.js", \
            tJSON
   end if
   
   # Check to see if we need to regenerate the datagrid docs
   put empty into tInputs
   put revIDESpecialFolderPath("api", "livecode_script") & slash & "dg.js" into tOutput
   put the effective filename of stack "revDocsParser" into tInputs[0]
   local tDatagridDoc, tFolder
   put revIDESpecialFolderPath("Documentation") &"/dictionary" into tFolder
   put tFolder & slash & "datagrid.lcdoc" into tInputs[1]
   put revIDEIsFilesetStale(tInputs, tOutput, false, tError) into tNeedUpdate
   # Regenerate if necessary   
   if tNeedUpdate then
      local tLibA
      put revDocsParseDocFileToLibraryArray(tFolder & slash & "datagrid.lcdoc", "DataGrid", "LiveCode") into tLibA

      # Update the database
      ideDocsUpdateDatabase "livecode_script", tLibA, true
      put revDocsFormatLibraryDocArrayAsJSON(tLibA) into tJSON
      revIDESetUTF8FileContents revIDESpecialFolderPath("api", "livecode_script") & slash & "dg.js", \
            tJSON
   end if
   
   local tIDELibsFolder, tIdeSupportFolder
   put tRepoPath & "/ide-support" into tIdeSupportFolder
   put tRepoPath & "/ide/Toolset/libraries" into tIDELibsFolder
   
   # Check to see if we need to regenerate the ide dictionary
   put empty into tInputs
   put the effective filename of stack "revDocsParser" into tInputs[0]
   put tIdeSupportFolder into tInputs[1]
   put tIDELibsFolder into tInputs[2]
   put revIDESpecialFolderPath("api", "livecode_ide") & slash & "ide.js" into tOutput
   
   put revIDEIsFilesetStale(tInputs, tOutput, true, tError) into tNeedUpdate
   # Regenerate dictionary if necessary
   if tNeedUpdate then
      local tIDELibs, tIDEA, tIDECount, tIDEParsedA
      put 1 into tIDECount
      put the stackfiles of stack "home" into tIDELibs
      split tIDELibs by return and comma
      repeat for each key tStackName in tIDELibs
         local tStack, tPassword, tDoc
         try
            put the long id of stack tStackName into tStack
            put the password of tStack into tPassword
         end try
         if tStack is not empty and tPassword is empty then
            put revDocsGenerateDocsFileFromText(the script of tStack, \ 
               tStack) into tDoc
         end if
         if tDoc is not empty then
            put tDoc into tIDEA[tIDECount]
            add 1 to tIDECount
         end if
      end repeat
      
      local tIDELibraryA
      put 1 into tIDECount
      repeat for each element tElement in tIDEA
         put revDocsParseDocText(tElement) into tIDEParsedA
         repeat for each key tEntry in tIDEParsedA["doc"]
            put tIDEParsedA["doc"][tEntry] into tIDELibraryA["doc"][tIDECount]
            add 1 to tIDECount
         end repeat
         put empty into tIDEParsedA
      end repeat
      put "LiveCode IDE" into tIDELibraryA["display name"]
      put revDocsModifyForUrl(tIDELibraryA["display name"]) into tIDELibraryA["name"]
      put "LiveCode" into tIDELibraryA["author"]
      put "dictionary" into tIDELibraryA["type"]
      
      # Update the database
      ideDocsUpdateDatabase "livecode_ide", tIDELibraryA, true
      
      put revDocsFormatLibraryDocArrayAsJSON(tIDELibraryA) into tJSON
      revIDESetUTF8FileContents revIDESpecialFolderPath("api", "livecode_ide") & slash & "ide.js", \
            tJSON
   end if
   
   local tExtractedDocsFolder
   put revEnvironmentBinariesPath() & slash & "extracted_docs" into tExtractedDocsFolder
   
   local tFiles
   put files(tExtractedDocsFolder) into tFiles
   filter tFiles with "*.lcdoc"
   
   set the itemDelimiter to "."
   local tFile
   repeat for each line tFile in tFiles
      # Check to see if we need to regenerate the docs
      put empty into tInputs
      put revIDESpecialFolderPath("api", "livecode_script") & slash & toLower(item 1 to -2 of tFile) & ".js" into tOutput
      put the effective filename of stack "revDocsParser" into tInputs[0]
      put tExtractedDocsFolder & slash & tFile into tInputs[1]
      put revIDEIsFilesetStale(tInputs, tOutput, false, tError) into tNeedUpdate
      # Regenerate if necessary
      if tNeedUpdate then
         put revDocsParseDocFileToLibraryArray(tExtractedDocsFolder & slash & tFile, item -2 of tFile, "LiveCode") into tLibA
         # Update the database
         ideDocsUpdateDatabase "livecode_script", tLibA, true
         put revDocsFormatLibraryDocArrayAsJSON(tLibA) into tJSON
         revIDESetUTF8FileContents tOutput, tJSON
      end if
   end repeat
end revIDEGenerateDistributedAPI

on revIDEEnsureDictionaryUrl pWhich
   local tInput, tOutput
   put revIDEGetDictionaryHTMLTemplate(pWhich) into tInput
   put revIDEGetDictionaryUrl(pWhich) into tOutput

   local tNeedUpdate, tError
   put revIDEIsFilesetStale(revIDEGetDictionaryHTMLTemplate(pWhich), \
         revIDEGetDictionaryUrl(pWhich), false, tError) into tNeedUpdate

   if tNeedUpdate is true then
      revIDEGenerateDictionaryHTML pWhich
   end if
end revIDEEnsureDictionaryUrl

function revIDEGetDictionaryUrl pWhich
   return revEnvironmentUserDocsPath() & slash & pWhich & ".html"
end revIDEGetDictionaryUrl

function revIDEGetDictionaryHTMLTemplate pWhich
   return revIDESpecialFolderPath("documentation") & slash & "html_viewer" & slash & pWhich & ".html.template"
end revIDEGetDictionaryHTMLTemplate

on revIDEGenerateDictionaryHTML pWhich, pInitialLibrary, pInitialEntryName, pInitialEntryType
   local tGeneratedHTMLFile
   put revIDEGetDictionaryUrl(pWhich) into tGeneratedHTMLFile
   
   local tLibraryName, tEntryName, tEntryType
   put pInitialLibrary into tLibraryName
   put pInitialEntryName into tEntryName
   put pInitialEntryType into tEntryType
   
   local tDocsBase
   put revIDESpecialFolderPath("documentation") & slash & "html_viewer" into tDocsBase
   
   local tDocsCSSFolder, tDocsJSFolder, tDataPath
   put tDocsBase & slash & "css" into tDocsCSSFolder
   put tDocsBase & slash & "js" into tDocsJSFolder
   put revIDESpecialFolderPath("documentation cache") & slash & "built_" & pWhich & ".js" into tDataPath
   
   local tIDEGuidesFolder, tRepoGuidesFolder
   put revIDESpecialFolderPath("ide guides") into tIDEGuidesFolder
   put revIDESpecialFolderPath("repo guides") into tRepoGuidesFolder
   
   local tTemplate
   put revIDEUTF8FileContents(revIDEGetDictionaryHTMLTemplate(pWhich)) into tTemplate
   put merge(tTemplate) into tTemplate
   revIDESetUTF8FileContents tGeneratedHTMLFile, tTemplate
end revIDEGenerateDictionaryHTML

##################################################
#
#          COLORS
#
##################################################

local sNamesToColorsA, sColorsToNamesA

private on __fetchNamesToColors
   local tColorRGB
   
   repeat for each line tColorName in the colorNames
   	  set the colorOverlay["color"] of the templateGraphic to tColorName
   	  put the colorOverlay["color"] of the templateGraphic into tColorRGB
  		put tColorRGB into sNamesToColorsA[tColorName]
   end repeat
end __fetchNamesToColors

private on __fetchColorsToNames
    repeat for each line tColor in the colorNames
  	   put tColor into sColorsToNamesA[revIDENamedColorToRGB(tColor)]
	end repeat
end __fetchColorsToNames

function revIDENamedColorToRGB pName
   if sNamesToColorsA is empty then
      __fetchNamesToColors
   end if
   
   return sNamesToColorsA[pName]
end revIDENamedColorToRGB

function revIDERGBToNamedColor pColor
   if sColorsToNamesA is empty then
      __fetchColorsToNames
   end if
   
   return sColorsToNamesA[pColor]
end revIDERGBToNamedColor

on ideCorePropertyInspectorRefreshPropertyLabels
   revIDESetPreference "idePropertyInspector_labels", the cLanguageNames of cd 1 of stack "revPreferences"
end ideCorePropertyInspectorRefreshPropertyLabels

##################################################
#
#          GEOMETRY
#
##################################################

on revIDESetGeometry pObject, pProperty, pGeometryArray
   revSetGeometryObject pObject
   repeat for each key tKey in pGeometryArray["geometry"]
      revSetGeometry tKey, pGeometryArray["geometry"][tKey]
   end repeat
   revClearExtraGeometrySettings
end revIDESetGeometry

function revIDEGetGeometry pObject, pProperty
   local tValue

   revSetGeometryObject pObject
   put pObject into tValue["object"]
   put revGetGeometry() into tValue["geometry"]
   return tValue
end revIDEGetGeometry

##################################################
#
#          Message box utilities
#
##################################################

private function __publicScriptHandlers pObject
   local tScript, tHandlers
   repeat while pObject is not empty
   try
         put the script of pObject & return after tScript
         put the owner of pObject into pObject
   catch tError
         exit repeat
   end try
   end repeat
   
   if tScript is empty then
      return empty
   end if
   
   repeat for each line tLine in tScript
      if token 1 of tLine is among the items of "on,command" then
         put "M" && token 2 of tLine & return after tHandlers
      else if token 1 of tLine is "function" then
         put "F" && token 2 of tLine & return after tHandlers
      end if
   end repeat
   delete the last char of tHandlers
   return tHandlers
end __publicScriptHandlers

private command __TryToAutocompleteScript pObject, pScript, @rNewScript
   if pObject is empty then
      return empty
   end if
   
   local tHandlerList
   if the environment is "development" then
      put the effective revAvailableHandlers of pObject into tHandlerList
   else
      -- implementation for testing purposes
      put __publicScriptHandlers(pObject) into tHandlerList
   end if
   -- revAvailableHandlers returns a list of handlers in the form
   -- <handlerType>  <handlerName> <startLine> <endLine>
   -- Check to see if any handler in the message path matches the executed script
   
   local tTargetHandler, tIsPutOrGet
   put token 1 of pScript into tTargetHandler
   put false into tIsPutOrGet
   if tTargetHandler is among the items of "put,get" then
      put true into tIsPutOrGet
      if token 2 of pScript is "the" then
         put token 3 of pScript into tTargetHandler
      else
         put token 2 of pScript into tTargetHandler
      end if
   end if
   
   local tDoScript, tFound
   put false into tFound
   put pScript into tDoScript
   repeat for each line tLine in tHandlerList
      local tHandlerName, tHandlerType
      put segment 1 of tLine into tHandlerType
      put segment 2 of tLine into tHandlerName
      if tHandlerName is not tTargetHandler then
         next repeat
      end if
      
      local tParams
      if not tIsPutOrGet and tHandlerType is "M" then
         -- If this is a command that matches, just send the message
         put pScript into tDoScript
         put true into tFound
         exit repeat
      else if tHandlerType is "F" then
         -- otherwise this is a function that matches
         if tIsPutOrGet then
            put pScript into tDoScript
         else
            -- autocomplete the 'put' if necessary
            put "put" && pScript into tDoScript
         end if
         put true into tFound
         exit repeat
      end if
   end repeat

   put tDoScript into rNewScript
   return tFound
end __TryToAutocompleteScript

command ideExecuteScript pScript, pObject, pDebugMode, @rValidScript
   local tDefaultStack
   put the defaultStack into tDefaultStack
   
   if pScript is empty then exit ideExecuteScript
   
   if pObject is empty then
      put the long id of this card of the defaultStack into pObject
   else 
      set the defaultStack to the short name of ideStackOfObject(pObject)
   end if
   
   -- Need to target 'this card' if a stack is selected
   if word 1 of pObject is "stack" then
      put the long id of this card of pObject into pObject
   end if
   
   -- check if word 1 of pScript is a handler in the intelligence object's script or the default stack's script
   local tScript, tValidScript, tCompileError, tOriginalCompileError
   ideCompileCheck pScript
   put the result into tOriginalCompileError
   
   __TryToAutocompleteScript pObject, pScript, tScript
   -- If we found a handler already, just execute the script
   if the result is true then
      ideCompileCheck tScript
      put the result into tCompileError
      if tCompileError is empty then
         put tScript into tValidScript
      end if
   end if
   
   # Try executing as a command
   if tValidScript is empty and \ 
         word 1 of tScript is among the lines of the commandNames then
      ideCompileCheck tScript
      put the result into tCompileError
      if tCompileError is empty then
         put tScript into tValidScript
      end if
   end if
   
   --deals with the put command, if the put command cannot be executed as is then:
   --the message box will attempt to auto complete the typing of a name of an object property and the contents of that property into the results area
   --where the intelligence object has been set in the preferences (currently selected object or the object directly underneath the mouse) ;s
   lock screen
   
   if tValidScript is empty and not (token 1 of tScript is "get") then
      # Try executing as a function or property
      local tTryProperty
      
      # Build the string so that it starts with "put the"
      if not (token 1 of tScript is "the") then
         put "the" && tScript into tTryProperty 
      else
         put tScript into tTryProperty
      end if
      if not (token 1 of tTryProperty is "put ") then
         put "put " before tTryProperty 
      end if
      
      set the wholeMatches to true
      local tIsProperty, tToken
      put word 3 of tTryProperty into tToken
      put tToken is among the lines of the propertyNames into tIsProperty
      
      # Try as a function or global property
      if tIsProperty or tToken is among the lines of the functionNames then
         ideCompileCheck tTryProperty
         put the result into tCompileError
         if tCompileError is empty then
            put tTryProperty into tValidScript
         end if
      end if
      
      # If it wasn't valid as an object property of the intelligence object
      # then try as an object property of the intelligence object
      if tValidScript is empty and tIsProperty and pObject is not empty then
         ideCompileCheck tTryProperty && "of" && pObject
         put the result into tCompileError
         if tCompileError is empty then
            local tName
            # pIntelligence object may be a bad reference or no longer exist
            try
               put the name of pObject into tName
            catch tError
            end try
            if tError is empty then
               put tTryProperty && "of" && tName into tValidScript
            end if
         end if
      end if
      
      ## If not a function, global property or object property then
      ## try as a boolean expression
      if tValidScript is empty then     
      local tBooleanExpression
      # Build the string so that it starts with "put"
         put "put" && tScript into tBooleanExpression 
         ideCompileCheck tBooleanExpression
         put the result into tCompileError
         if tCompileError is empty then
            put tBooleanExpression into tValidScript
         end if
      end if
   end if
   
   if tValidScript is empty then
      if tOriginalCompileError is not empty then
         return tOriginalCompileError for error
      else
         put pScript into tValidScript
      end if
   end if
   unlock screen
   
   local tResult
   put tValidScript into rValidScript
   ideDoMessage tValidScript, pDebugMode, pObject
   put the result into tResult
   set the defaultStack to tDefaultStack
   return tResult for value
end ideExecuteScript

/** 
Attempts to compile the target script

The result: If the compilation fails, the result is set to the description of the compile error
**/
on ideCompileCheck pScript
   local tCompileTest, tCompileResult
   --checks to see if the message compiles
   lock messages
   create script only stack "ideCompilationTest"
   put "on compileTest" & cr & pScript & cr & "end compileTest" into tCompileTest
   set the script of stack "ideCompilationTest" to tCompileTest
   put the result into tCompileResult
   delete stack "ideCompilationTest"
   unlock messages
   repeat for each line tError in tCompileResult
      if item 2 of tError is not 0 then
         return tError
      end if
   end repeat

   return empty
end ideCompileCheck

function ideIsDebugging
   return revTopMostScriptEditor("debug") is not empty
end ideIsDebugging

private command __removeMessageBoxFromDebugContexts @xContexts
   local tTarget
   put the long id of the target into tTarget
   local tFirst, tLast, tCount, tObject
   put 1 into tFirst
   put 0 into tLast
   repeat for each line tLine in xContexts
      add 1 to tCount
      put item 2 of tLine into tObject
      if tObject is not empty then
         put the long id of tObject into tObject
      end if
      -- Message box execution always begins with 'returnInField' from the target
      if item 3 of tLine is "returnInField" and \ 
            tObject is tTarget then
         put tCount into tLast
      end if
   end repeat
   
   delete line tFirst to tLast of xContexts
end __removeMessageBoxFromDebugContexts

function ideDeclaredGlobalVariables
   -- Return globals without 'each' or any of the env vars
   local tGlobals
   put the globals into tGlobals
   replace comma with return in tGlobals
   filter tGlobals without "$*"
   filter tGlobals without "each"
   return tGlobals
end ideDeclaredGlobalVariables

command ideDoMessage pScript, pDebugMode, pObject
   local tScriptError, tGlobals
   put ideDeclaredGlobalVariables() into tGlobals
   replace return with comma in tGlobals
   put "global" && tGlobals & return before pScript
   
   try
      if pDebugMode then
         local tContext, tScriptEditor
         put revTopMostScriptEditor("debug") into tScriptEditor
         -- Ensure a user-selected debug context in the script editor is the first
         -- option for execution context in the message box
         if tScriptEditor is not empty then
            dispatch function "seGetSelectedDebugContext" to tScriptEditor
            put the result into tContext
         end if
         -- Otherwise, remove the chain of message box execution contexts
         -- from the list, and take the next one.
         if tContext is empty then
            local tContexts
            put revDebuggerContexts() into tContexts
            __removeMessageBoxFromDebugContexts tContexts
            put line 1 of tContexts into tContext
         end if
         local tResult
         revDebuggerDo pScript, tContext
         put the result into tResult
         put line 2 to -1 of tResult into tScriptError
         put line 1 of tResult into tResult
         
      else
         if pObject is empty then
            put the long id of this card of this stack into pObject
         end if
         send script pScript to pObject
      end if
   catch tScriptError
   end try
   
   return tScriptError
end ideDoMessage

private function menuitemEscape pItem, pFirst
   -- MW-2011-04-08: [[ Bug 9496 ]] Make sure we escape '!!' properly.
   replace "!" with "!!" in pItem
   replace "&" with "&&" in pItem
   replace "(" with "((" in pItem
   return pItem
end menuitemEscape

private function shouldShow pType, pFilter
   if pFilter is empty then return true
   return pType is among the items of pFilter
end shouldShow

function revIDEObjectSelectionMenu pTargetObjects, pTypeFilter
   local tStack, tDefaultStack
   local tStacks,tCards,tControls,tStackList
   local tNumControls, tNumCards
   local tCheck, tControlsArray
   local tList,tControlsList
   
   if pTargetObjects is not empty then
      put ideStackOfObject(line 1 of pTargetObjects) into tStack
   else
      put the long id of the topStack into tStack
   end if
   put the defaultStack into tDefaultStack
   
   # Generate the inspect 
   set the defaultStack to tStack
   put the num of controls into tNumControls
   if tNumControls > 1000 then 
      put tab & "(Too many controls to display" && "[" & tNumControls & "]" after tControls
   else
      repeat with i = 1 to tNumControls
         local tLongID, tType
         put the long id control i into tLongID
         put word 1 of tLongID into tType
         if not shouldShow(tType, pTypeFilter) then
            next repeat
         end if
         if tLongID is among the lines of pTargetObjects 
         then put "!c" into tCheck
         else put "!n" into tCheck
         put tCheck & tab & menuitemEscape(the name of control i, false) && "[" & i & "]" & "/|" & tLongID & cr after tControls
      end repeat
      delete last char of tControls
      set the itemDel to tab
      sort lines of tControls numeric by item 2 of each
      if the number of lines in tControls > 20 then
         repeat for each line l in tControls -- sort into individual object types
            put tab & tab & l & cr after tControlsArray[word 2 of l]
         end repeat
         put keys(tControlsArray) into tList
         sort lines of tList
         repeat for each line l in tList
            delete last char of tControlsArray[l] -- trailing return in each element
            put tab & l & "s" & cr & tControlsArray[l] & cr after tControlsList
         end repeat
      end if
   end if
   
   if shouldShow("card", pTypeFilter) then
      put empty into tCards
      put the num of cards in this stack into tNumCards
      repeat with i = 1 to tNumCards
         put the long id of cd i into tLongID
         if tLongID is among the lines of pTargetObjects
         then put "!c" into tCheck
         else put "!n" into tCheck
         put tCheck & tab & tab & menuitemEscape(the short name of card i, false) && "[" & i & "]" & "/|" & tLongID & cr after tCards
      end repeat
      delete last char of tCards
      sort lines of tCards by item 2 of each
      
      put tab & "Card" & cr before tCards
   end if
   set the defaultStack to tDefaultStack
   
   if shouldShow("stack", pTypeFilter) then
      local tMainstack
      repeat for each line tMainStack in the mainstacks
         local tSubstacks
         put the substacks of stack tMainstack into tSubstacks
         if tStackList is not empty then
            put return after tStackList
         end if
         put tMainstack after tStackList
         if tSubstacks is not empty then
            put return & tSubstacks after tStackList
         end if
      end repeat
      
      global gRevShowStacks
      if not gREVShowStacks then 
         put revFilterStacksList(tStackList) into tStackList
      end if
      put empty into tStacks
      repeat for each line l in tStackList
         put the long id of stack l into tLongID
         if tLongID is among the lines of pTargetObjects
         then put "!c" into tCheck
         else put "!n" into tCheck
         put tCheck & tab & tab & menuitemEscape(l, false) & "/|" & tLongID & cr after tStacks
      end repeat
      delete last char of tStacks
      sort lines of tStacks by item 2 of each
      if tStacks is empty then put "(" & tab & "Stack" into tStacks
      else put tab & "Stack" & cr before tStacks
   end if
   
   local tMenu
   if the number of lines in tControls > 20 then 
      replace cr with cr & tab & tab in tCards
      replace cr with cr & tab & tab in tStacks
      put tControlsList into tMenu
   else if tControls is not empty then
      put tControls & cr into tMenu  
   end if
   
   if tCards is not empty then
      put tab & "-" & cr & tCards & cr after tMenu
   end if
   
   if tStacks is not empty then
      put tab & "-" & cr & tStacks & cr after tMenu
   end if
   
   delete the last char of tMenu
   return tMenu
end revIDEObjectSelectionMenu

# OK-2007-07-06 : Reworked recent paths system
command revUpdateRecentFiles pStack
   if there is no stack pStack then
      exit revUpdateRecentFiles
   end if

   if revIDEStackNameIsIDEStack(pStack) then
      exit revUpdateRecentFiles
   end if

   if the effective filename of stack pStack is empty then
      exit revUpdateRecentFiles
   end if

   revIDEAddRecentStack the effective filename of stack pStack
end revUpdateRecentFiles

/*
Share the stack to revOnline/LiveCode Share
*/
command revIDEShareStack pStackID
   local tStackPath
   # Upload stack to RevOnline
   revOnlinePrefLoad
   put the effective filename of the topStack into tStackPath
   if tStackPath is empty then
      # Stack must be saved to be uploaded to revonline
      revSaveAs the short name of the topStack,false
   end if
   put the effective filename of the topStack into tStackPath
   if tStackPath is not empty then
      # Check remember username and password prefs
      if revOnlineSession() is empty then
         # No session so need to login
         revOnlineShowLoginDialog
      end if
      # If login was successful
      if revOnlineSession() is not empty then
         revGoOnline
         send "rvoShareThisStack tStackPath" to stack "revonline"
      end if
   end if
   break
end revIDEShareStack

/*
Returns the number of lines in the script of an object
If  the object is on a password protected stack "pwd" is returned
*/
function revIDEObjectScriptLines pObject
   local tScriptLines
   try
      put the number of lines in the script of pObject into tScriptLines      
   catch pError
      put "pwd" into tScriptLines
   end try
   return tScriptLines
end revIDEObjectScriptLines

/* 
Returns true if the object is currently open, i.e. determines
- if the object is a stack, whether the mode is not 0
- if the object is a card, whether it is the current card of an open stack
- if the object is a control, whether it is on the current card of an open stack
*/
function revIDEObjectIsOpen pLongID
   local tStack
   put revIDEStackOfObject(pLongID) into tStack
   
   if the mode of tStack is 0 then
      return false
   end if
   
   if word 1 of pLongID is "stack" then
      return true
   end if
   
   local tCard
   put revIDECardOfObject(pLongID) into tCard
   
   if tCard is not the long id of this card of tStack then
      return false
   end if
   
   if word 1 of pLongID is "card" then
      return true
   end if
   
   return exists(pLongID)
end revIDEObjectIsOpen

constant kExtensionErrorCode = 863
constant kExternalHandlerErrorCode = 634
/**
Returns the error description associated with the given 
error code.

pType : either "compilation", "execution" or "warning"
pCode : the id of the error as returned by the engine.
Returns : The description of the specified error. 

>*Note:* if <pType> is "warning", this function will currently return 
empty.
*/
function revIDELookupError pType, pError
   local tCode
   put item 1 of line 1 of pError into tCode
   if pType is "compilation" then
      return line tCode of the scriptParsingErrors
   else if pType is "execution" then
      if tCode is kExtensionErrorCode then
         local tLine, tFile, tDesc
         put item 4 to -1 of line 2 of pError into tDesc
         put item 4 to -1 of line 3 of pError into tFile
         put item 4 to -1 of line 4 of pError into tLine
         return merge("LCB Error in file [[tFile]] at line [[tLine]]: [[tDesc]]")
      else if tCode is kExternalHandlerErrorCode then
         return "External handler execution error:" && item 4 to -1 of line 1 of pError
      end if
      
      if tCode is an integer then
         get line tCode of the scriptExecutionErrors
         if it is not empty then
            return it
         end if
      end if
      return tCode
   else if pType is "warning" then
      return empty
   end if
end revIDELookupError

function revIDEExternalsMapping
   dispatch function "revSBExternalsMapping" to stack "revSBLibrary"
   return the result
end revIDEExternalsMapping

function revIDEDatabaseDriversMapping
   dispatch function "revSBDatabaseDriversMapping" to stack "revSBLibrary"
   return the result
end revIDEDatabaseDriversMapping

----------------------------------------------------------------
-- Dependency management functions
----------------------------------------------------------------

/**
Summary: Compute whether derived files are up-to-date

Syntax: revIDEIsFilesetStale(pInputs, pOutputs, pRecursive, rError)

Parameters:
pInputs: A numerically-keyed array of filenames, or a filename
pOutputs: A numerically-keyed array of filenames, or a filename
pRecursive: True if folders should be checked recursively
rError: Set to a string describing an error, if necessary.

Description:
Checks whether the <pOutputs> are up-to-date relative to the
<pInputs>, by checking the modification times on the files.  Returns
true if any of the <pInputs> are newer than any of the <pOutputs>, or
if any of the <pOutputs> are missing.  Returns false if all of the
<pOutputs> are up-to-date.

If an error occurs, returns empty and sets <rError> to a descriptive
string.

The <pInputs> and the <pOutputs> are file sets, and can either be a
single filename as a string, or a numerically-keyed array of filenames.
It is an error for either file set is an array with non-numeric keys, or
for any filename to be the empty string.

If either file set is empty, the return value is true.  It is an error
for any of the input filenames to be missing.

If <pRecursive> is true, any filename in the <pInputs> or <pOutputs>
that is a directory is scanned recursively and its files are added to
the fileset.  If <pRecursive> is false, it is an error for either file
set to contain directories.
*/
function revIDEIsFilesetStale pInputs, pOutputs, pRecursive, @rError
   local tError
   try
      if pRecursive is empty then
         put false into pRecursive
      end if
   
      -- Make sure both filesets are non-empty arrays
      local tInputs, tOutputs
      put __CheckFileset(pInputs) into tInputs
      put __CheckFileset(pOutputs) into tOutputs
      if (tInputs is false) or (tOutputs is false) then
         return false -- consider everything to be up-to-date
      end if
   
      -- Gather dates from each fileset
      local tInputTimes, tOutputTimes
      put __ScanFilesetMTimes(tOutputs, pRecursive, true) into tOutputTimes
      if (tOutputTimes is false) then
         return true -- an output file is missing, so update is required
      end if
   
      put __ScanFilesetMTimes(tInputs, pRecursive, false) into tInputTimes
   
      if (tInputTimes is not an array or tOutputTimes is not an array) then
         throw "This should never happen"
      end if
      
      if tOutputTimes["min"] is empty then
         return false
      end if
      
      return tInputTimes["max"] > tOutputTimes["min"]
   catch tError
      put tError into rError
      return empty
   end try
end revIDEIsFilesetStale

-- Converts pFileset to an array of at least one element and returns it.
-- Return false if pFileset is an empty array or the empty string.
function __CheckFileset pFileset
   if pFileset is an array then
      if the number of elements in pFileset is 0 then
         return false
      else
         return pFileset
      end if
   end if

   local tFileset
   if pFileset is empty then
      return false
   else
      put pFileset into tFileset[1]
      return tFileset
   end if
end __CheckFileset

-- Scan pFileset, returning the minimum and maximum modification
-- times found as an array with "min" and "max" keys.
--
-- If pRecursive is true, scan directories in pFileset for the
-- modification times of each file they contain; otherwise,
-- encountering a directory is an error.
--
-- If pAllowMissing is true, return false on encountering a missing
-- file; otherwise, it is an error for pFileset to contain a
-- missing file.
private function __ScanFilesetMTimes pFileset, pRecursive, pAllowMissing
   local tResult
   put empty into tResult["min"]
   put 0 into tResult["max"]

   if pFileset is not an array then
      throw "Fileset is not an array"
   end if

   local tFilename
   repeat for each element tFilename in pFileset
      if not __ScanFileMTime(tFilename, pRecursive, pAllowMissing, \
            tResult["min"], tResult["max"]) then
         return false
      end if
   end repeat
   
   return tResult
end __ScanFilesetMTimes

private function __ScanFileMTime pFilename, pRecursive, pAllowMissing, \
      @xMin, @xMax
   
   local tDirname, tBasename
   
   set the itemdelimiter to slash
   put item 1 to -2 of pFilename into tDirname
   put item -1 of pFilename into tBasename
   if tDirname is empty then
      put "." into tDirname
   end if
   
   if tBasename is empty then
      throw "Failed to check modification time: invalid filename" && pFilename
   end if
   
   -- Regular file
   local tMTime
   if there is a file pFilename then
      put revIDELastModifiedTimeOfFile(tDirname, tBasename) into tMTime
      if tMTime is empty then
         throw "Failed to check modification time for file" && pFilename
      end if
      if xMin is empty or tMTime < xMin then
         put tMTime into xMin
      end if
      if tMTime > xMax then
         put tMTime into xMax
      end if
      return true
   end if
   
   -- Directory
   local tContents, tInnerFilename
   if there is a folder pFilename then
      if pRecursive then
         
         -- List directory contents
         revIDEPushDefaultFolder pFilename
         if the result is not empty then
            throw "Failed to set default folder" && pFilename
         end if
         
         put files() & return & folders() into tContents
         filter tContents without ".."
         filter tContents without empty
         
         revIDEPopDefaultFolder pFilename
         if the result is not empty then
            throw "Failed to set default folder" && pFilename
         end if
         
         if tContents is empty then
            return true
         end if
         
         -- Recursively scan files & folders
         repeat for each line tInnerFilename in tContents
            put pFilename & slash before tInnerFilename
            if not __ScanFileMTime(tInnerFilename, pRecursive, pAllowMissing, xMin, xMax) then
               return false
            end if
         end repeat
         
         return true
      else
         throw "Failed to check modification time: unexpected folder" && pFilename
      end if
   end if
   
   -- Missing
   if pAllowMissing then
      return false
   else
      throw "Failed to check modification time: missing file" && pFilename
   end if
end __ScanFileMTime

private command __removeByteOrderMark @xData
   if byte 1 of xData is numToByte(0xef) and \
         byte 2 of xData is numToByte(0xbb) and \
         byte 3 of xData is numToByte(0xbf) then
      delete byte 1 to 3 of xData
   end if
end __removeByteOrderMark

function revIDEUTF8FileContents pFile
   local tContents
   put url("binfile:" & pFile) into tContents
   
   -- Remove byte-order mark if there is one
   __removeByteOrderMark tContents
   
   return textDecode(tContents, "utf-8")
end revIDEUTF8FileContents

command revIDESetUTF8FileContents pFile, pContents
   put textEncode(pContents, "utf-8") into url("binfile:" & pFile)
end revIDESetUTF8FileContents

/**

Determine if a list of objects are selectable using
the select command

Parameters:
pObjects (String): A return delimited list of object references

Description:
Returns true if all objects exist, are on an editable open stack and
have the same owner.

Returns: True if the objects can be selected

*/

function revIDEObjectsAreSelectable pObjects
   local tOwner, tObject
   split pObjects by return
   
   if there is a pObjects[1] then
      put the long owner of pObjects[1] into tOwner
   else
      return false
   end if
   
   if word 1 of tOwner is among the words of "group bkgnd background" then
      if not the selectGroupedControls or not the selectGroupedControls of tOwner then
         return false
      end if
   end if
   
   repeat for each element tObject in pObjects
      
      if there is not a tObject then
         return false
      end if
      
      local tStack
      put revIDEStackOfObject(tObject) into tStack
      if the mode of tStack is not 1 then
         return false
      end if
      
      if the long owner of tObject is not tOwner then
         return false
      end if
      
      if word 1 of tObject is not among the words of "card stack" then
         if revIDECardOfObject(tObject) is not the long id of this card of tStack then
            return false
         end if
      end if
   end repeat
   
   return true
end revIDEObjectsAreSelectable

on revIDEFindMoreWidgets
   lock screen
   revIDEOpenPalette "extension manager"
   send "showExtensionStore" to \ 
         stack revIDEPaletteToStackName("extension manager")
   unlock screen
end revIDEFindMoreWidgets

command ideShowUpgradeOptions
   if ideCanShowUpgradeOptions() then
      lock screen
      if the mode of stack revIDEPaletteToStackName("start center") is 0 then
         revIDEOpenPalette "start center"
      end if
      dispatch "ideAction" to stack revIDEPaletteToStackName("start center") with "launchAdWithUrl"
      unlock screen
   else if ideShouldShowUpgradeOptions() then
      local tUpgradeEdition
      put revEnvironmentEditionProperty("upgrade_edition") into tUpgradeEdition
      launch url revEnvironmentEditionProperty("edition_external_url", tUpgradeEdition)
   end if
end ideShowUpgradeOptions

function ideCanShowUpgradeOptions
   return ideShouldShowUpgradeOptions() \
         and hasConnection() \
         and not revIDEBrowserWidgetUnavailable()
end ideCanShowUpgradeOptions

function ideShouldShowUpgradeOptions
   return \
         revEnvironmentEditionProperty("upgrade_mini_url") is not empty \
         and revEnvironmentEditionProperty("upgrade_edition") is not empty
end ideShouldShowUpgradeOptions

private function hasConnection
   return url("http://google.com/") is not empty
end hasConnection

on ideDesktopChanged
   ideSetWindowBoundingRect
end ideDesktopChanged

/**

Update the window bounding rect for the current IDE palette layout

*/

command ideSetWindowBoundingRect
   local tMenuBar
   put revIDEPaletteToStackName("menubar") into tMenuBar
   
   local tTools
   put revIDEPaletteToStackName("tools") into tTools
   
   local tToolsSlop
   put the width of stack tTools + 50 into tToolsSlop
   
   local tWindowRect
   put revIDEStackScreenRect(tMenuBar, true) into tWindowRect
   if tWindowRect is not empty then
      if the screen of stack tTools is the screen of stack tMenubar then
         if the right of stack tTools < (item 1 of tWindowRect + tToolsSlop) then 
            put the right of stack tTools + 5 into item 1 of tWindowRect
         else if the left of stack tTools > (item 3 of tWindowRect - tToolsSlop) then
            put the left of stack tTools - 5 into item 3 of tWindowRect
         end if
      end if
      
      -- revMenubar may not be visible on macOS with text and icons off
      if the visible of stack tMenubar then
         put the bottom of stack tMenuBar + 5 into item 2 of tWindowRect
      end if
      set the windowBoundingRect to tWindowRect
   end if
end ideSetWindowBoundingRect
