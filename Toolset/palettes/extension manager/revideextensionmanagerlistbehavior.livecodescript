script "revIDEExtensionManagerListBehavior"
local sSection, sDisplayArray
command setSection pSection
   if pSection is empty then
      if sSection is empty then
         put "widget" into sSection
      end if
   else
      put pSection into sSection
   end if
end setSection

on showList pSection
   if the short name of this card of this stack is not "list" then
      go card "list"
   end if
   setSection pSection
   refreshList
end showList

on resizeStack
   set the rect of group "extensionList" of me to the contentRect of this stack of me
   pass resizeStack
end resizeStack

on preOpenCard
   revIDESubscribe "ideExtensionsChanged"
   revIDESubscribe "ideExtensionStatusChanged"
   revIDESubscribe "idePreferenceChanged:ideExtensionManager_showInactiveExtensions"
   
   lock screen
   setSection	
   setUpExtensionList   
   set the rect of group "extensionList" of me to the contentRect of this stack of me
   send "resetView" to group "extensionList" of me
   unlock screen
end preOpenCard

on openCard
   lock screen
   refreshList
   unlock screen
end openCard

on refreshList
   hiliteFrameItem sSection
   refreshExtensionList sSection
end refreshList

on idePreferenceChanged pPreference, pValue
   local tValue
   
   put revIDEGetPreference(pPreference) into tValue   
   switch pPreference
      case "ideExtensionManager_showInactiveExtensions"
         refreshExtensionList
         break
   end switch
end idePreferenceChanged

on ideExtensionsChanged
   refreshExtensionList
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

on refreshExtensionList
   local tExtensionArray, tVisibleRows, tShowInactive
   local tIndex, tFilteredArray
   
   ## Check preference for showing inactive
   put revIDEGetPreference("ideExtensionManager_showInactiveExtensions") into tShowInactive
   if tShowInactive is empty or tShowInactive is not among the items of "true,false" then 
      put "true" into tShowInactive
      revIDESetPreference "ideExtensionManager_showInactiveExtensions",true
   end if   

   if sSection is empty then
      setSection
   end if

   # AL-2015-03-20: [[ Bug 15048 ]] Pass type to revIDEExtensions
   put revIDEExtensions(sSection) into tExtensionArray 
   
   # AL-2015-05-26: [[ Bug 14561 ]] Order extensions alphabetically
   local tExtensionList
   put the keys of tExtensionArray into tExtensionList
   sort tExtensionList by tExtensionArray[each]["title"]
   
   ## Filter the list
   repeat for each line tExtension in tExtensionList
      if tExtensionArray[tExtension]["type"] = sSection then
         add 1 to tIndex
         put tExtensionArray[tExtension] into tFilteredArray[tIndex]
      end if
   end repeat
   
   put the keys of tFilteredArray into tVisibleRows
   replace return with comma in tVisibleRows
   sort items of tVisibleRows ascending numeric
   
   ## Filter based on type
   put tFilteredArray into sDisplayArray["objects"]
   put tVisibleRows into sDisplayArray["visible object keys"]
   
   send "renderView" to group "extensionList" of me
end refreshExtensionList

on refreshExtensionListStatus   
   send "renderView" to group "extensionList" of me
end refreshExtensionListStatus

command uninstallExtension pTypeID
   revIDEExtensionUninstall pTypeID
end uninstallExtension

command unloadExtension pTypeID
   revIDEExtensionUnload pTypeID
end unloadExtension

command loadExtension pTypeID
   revIDEExtensionReload pTypeID
end loadExtension

command toggleUserVisibility pTypeID
   revIDEExtensionToggleUserVisibility pTypeID
   refreshList
end toggleUserVisibility

command toggleLoadOnStartup pTypeID
   revIDEExtensionToggleLoadOnStartup pTypeID
   refreshList
end toggleLoadOnStartup

on updateExtension pExtensionIdentifier, pLatestVersion
   ## Don't do anything for now becuase renaming a zip doesn't work
   ## manifest/enumerated files don't get updated when you do this
   revIDEUpdateExtension pExtensionIdentifier, pLatestVersion
end updateExtension

on cancelExtensionInstall pExtensionIdentifier
   revIDECancelInstallExtension pExtensionIdentifier
end cancelExtensionInstall

on launchExtensionSampleStack pExtensionId
   local tSourceFolder, tSourceFile
   put revIDEExtensionProperty(pExtensionId, "install_path") into tSourceFolder
   put revIDEExtensionProperty(pExtensionId, "source_file") into tSourceFile
   revIDEExtensionLaunchSampleStack tSourceFolder & slash & tSourceFile
end launchExtensionSampleStack

on showExtensionSnippet pExtensionId
   local tSourceFolder, tSourceFile
   put revIDEExtensionProperty(pExtensionId, "install_path") into tSourceFolder
   put revIDEExtensionProperty(pExtensionId, "source_file") into tSourceFile
   revIDEExtensionShowSnippet tSourceFolder & slash & tSourceFile
end showExtensionSnippet

on ideExtensionStatusChanged pStatus
   local tElement, tRow, tIdentifier, tStatus, tProgress
   put item 1 of pStatus into tIdentifier
   put item 2 of pStatus into tStatus
   put item 3 of pStatus into tProgress
   
   dispatch function "TreeFindElement" to group "extensionList" of me with sDisplayArray,"name",tIdentifier
   put the result into tElement
   
   put tElement["row"] into tRow
   put tStatus into sDisplayArray["objects"][tRow]["status"]
   put tProgress into sDisplayArray["objects"][tRow]["progress"]
   refreshExtensionListStatus
end ideExtensionStatusChanged
