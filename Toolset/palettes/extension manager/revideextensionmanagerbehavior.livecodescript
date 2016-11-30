script "revIDEExtensionManagerBehavior"
local sDisplayArray, sSection

on preOpenStack   
   lock screen
   dispatch "setAsBehavior" to revIDEFrameBehavior() with the long id of this me
   
   set the behavior of card "search" of me to the long id of stack "revIDEExtensionManagerStoreBehavior"
   set the behavior of card "list" of me to the long id of stack "revIDEExtensionManagerListBehavior"
   set the zoomBox of this stack to false
   
   clearFrameData
   
   # Navigation
   addFrameItem "widget","header", "navigation", "Widgets", "f013", "f013","showList", the long id of me,"widget"
   addFrameItem "library","header", "navigation", "Libraries", "f02e", "f02e","showList", the long id of me,"library"
   addFrameItem "install", "header", "action", "Install extension", "plus", "","installNew", the long id of me
   
   set the hilitedTabColor of me to "255,255,255"
   set the navigationDisplayStyle of me to "names"
   
   revIDESubscribe "ideExtensionsChanged"
   revIDESubscribe "ideExtensionStatusChanged"
   revIDESubscribe "idePreferenceChanged:ideExtensionManager_showInactiveExtensions"
   revIDESubscribe "ideFindMoreWidgets"
   
   setUpExtensionList   
   unlock screen
end preOpenStack

on openStack
   lock screen
   go card 1
   hiliteFrameItem "widget"
   unlock screen
end openStack

on showList pSection
   lock screen
   go to card "list" of this stack
   hiliteFrameItem pSection
   refreshExtensionList pSection
   unlock screen
end showList

on preferenceChanged pPreference, pValue
   revIDESetPreference pPreference, pValue
   refreshExtensionList sSection
end preferenceChanged

on idePreferenceChanged pPreference, pValue
   local tValue
   
   put revIDEGetPreference(pPreference) into tValue   
   switch pPreference
      case "ideExtensionManager_showInactiveExtensions"
         refreshExtensionList sSection
         break
   end switch
end idePreferenceChanged

on ideExtensionsChanged
   refreshExtensionList sSection
end ideExtensionsChanged

on setUpExtensionList
   local theStylesA
   
   set the behavior of group "extensionList" of card "list" of this stack to revIDEDataViewBehavior()
   send "ResetView" to group "extensionList" of card "list" of this stack
   
   put the long id of group "extensionRow" of card "templates" of this stack into theStylesA["extension"]
   
   set the viewProp["row style templates"] of group "extensionList" of card "list" of this stack to theStylesA
   set the viewProp["hilite color"] of group "extensionList" of card "list" of this stack to ideColorGet("pb_line_selected")
   set the viewProp["background color"] of group "extensionList" of card "list" of this stack to empty
   
   set the viewProp["row color"] of group "extensionList" of card "list" of this stack to revIDEColor("dataView_rowColor")
   set the viewProp["alternate row color"] of group "extensionList" of card "list" of this stack to revIDEColor("dataView_rowAlternateColor")        
   
   set the viewProp["fixed row height"] of group "extensionList" of card "list" of this stack to "true"
   set the viewProp["row height"] of group "extensionList" of card "list" of this stack to 41
   set the viewProp["cache"] of group "extensionList" of card "list" of this stack to "none"
end setUpExtensionList

function NumberOfRows
   # return the number of rows in the data view
   -- return the number of lines in the keys of sDisplayArray
   return the number of items in sDisplayArray["visible object keys"]
end NumberOfRows

command DataForRow pRow, @pDataA, @pTemplateStyle
   local theID
   # Fill in pDataA with the values for this pRow and specify the row style.
   put item pRow of sDisplayArray["visible object keys"] into theId
   put sDisplayArray["objects"][theId] into pDataA
   put "extension" into pTemplateStyle
end DataForRow

function CacheKeyForRow pRow 
   # [OPTIONAL unless data is a tree] Specify a unique key for pRow. 
   # Only define if you will be reordering rows in the dataview 
   # By default the row number is used to cache the control for a row. 
   # If you will be reordering rows in your dataview then you need to provide 
   # a unique value for the cache key by defining this function and returning a value. 
   # A database id can work nicely. 
   local theID
   put item pRow of sDisplayArray["visible object keys"] into theId 
   return sDisplayArray["objects"][theId]["name"]
end CacheKeyForRow

on refreshExtensionList pType
   local tExtensionArray, tVisibleRows, tShowInactive
   local tIndex, tFilteredArray
   
   ## Check preference for showing inactive
   put revIDEGetPreference("ideExtensionManager_showInactiveExtensions") into tShowInactive
   if tShowInactive is empty or tShowInactive is not among the items of "true,false" then 
      put "true" into tShowInactive
      revIDESetPreference "ideExtensionManager_showInactiveExtensions",true
   end if   
   
   if pType is empty then put sSection into pType
   if pType is empty then put "widget" into pType
   
   # AL-2015-03-20: [[ Bug 15048 ]] Pass type to revIDEExtensions
   put revIDEExtensions(pType) into tExtensionArray 
   
   # AL-2015-05-26: [[ Bug 14561 ]] Order extensions alphabetically
   local tExtensionList
   put the keys of tExtensionArray into tExtensionList
   sort tExtensionList by tExtensionArray[each]["title"]
   
   //revputarray  tExtensionArray
   //if the number of lines of the keys of tExtensionArray > 0 then breakpoint
   ## Filter the list
   repeat for each line tExtension in tExtensionList
      if tExtensionArray[tExtension]["type"] = pType then
         //if tExtension["status"] = "active" OR tShowInactive then
         add 1 to tIndex
         put tExtensionArray[tExtension] into tFilteredArray[tIndex]
         //end if
      end if
   end repeat
   
   put the keys of tFilteredArray into tVisibleRows
   replace return with comma in tVisibleRows
   sort items of tVisibleRows ascending numeric
   
   ## Filter based on type
   put tFilteredArray into sDisplayArray["objects"]
   put tVisibleRows into sDisplayArray["visible object keys"]
   
   send "renderView" to group "extensionList" of card 1 of this stack
end refreshExtensionList

on refreshExtensionListStatus   
   send "renderView" to group "extensionList" of card 1 of this stack
end refreshExtensionListStatus

on activateExtension pExtensionIdentifier
   revIDEActivateExtension pExtensionIdentifier
end activateExtension

on deactivateExtension pExtensionIdentifier
   revIDEDeactivateExtension pExtensionIdentifier
end deactivateExtension

on uninstallExtension pExtensionIdentifier
   revIDEUninstallExtension pExtensionIdentifier
end uninstallExtension

on updateExtension pExtensionIdentifier, pLatestVersion
   ## Don't do anything for now becuase renaming a zip doesn't work
   ## manifest/enumerated files don't get updated when you do this
   revIDEUpdateExtension pExtensionIdentifier, pLatestVersion
end updateExtension

on installNew
   answer file "Choose an extension to install:" with type "LiveCode Extension|lce|"
   if it is not empty then
      installExtension it, "widget"
   end if
end installNew

on installExtension pExtensionURL, pType
   lock screen   
   revIDEInstallExtension pExtensionURL, pType
   refreshExtensionList pType
   unlock screen
end installExtension

on cancelExtensionInstall pExtensionIdentifier
   revIDECancelInstallExtension pExtensionIdentifier
end cancelExtensionInstall

on ideExtensionStatusChanged pStatus
   local tElement, tRow, tIdentifier, tStatus, tProgress
   put item 1 of pStatus into tIdentifier
   put item 2 of pStatus into tStatus
   put item 3 of pStatus into tProgress
   
   dispatch function "TreeFindElement" to group "extensionList" of card 1 of this stack with sDisplayArray,"name",tIdentifier
   put the result into tElement
   
   put tElement["row"] into tRow
   put tStatus into sDisplayArray["objects"][tRow]["status"]
   put tProgress into sDisplayArray["objects"][tRow]["progress"]
   refreshExtensionListStatus
end ideExtensionStatusChanged
