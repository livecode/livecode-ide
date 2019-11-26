script "revIDEExtensionManagerBehavior"
on preOpenStack
   lock screen
   dispatch "setAsBehavior" to revIDEFrameBehavior() with the long id of this me
   
   set the behavior of card "search" of me to the long id of stack "revIDEExtensionManagerStoreBehavior"
   set the behavior of card "list" of me to the long id of stack "revIDEExtensionManagerListBehavior"
   set the zoomBox of this stack to false
   
   clearFrameData
   
   # Navigation
   addFrameItem "widget","header", "navigation", "Widgets", "", "","showList", the long id of me,"widget"
   addFrameItem "library","header", "navigation", "Libraries", "", "","showList", the long id of me,"library"
   addFrameItem "sample","header", "navigation", "Sample Stacks", "", "","showList", the long id of me,"sample"
   addFrameItem "snippet","header", "navigation", "Snippets", "", "","showList", the long id of me,"snippet"
   addFrameItem "store","header", "navigation", "Store", "", "","showExtensionStore", the long id of me,"store"
   addFrameItem "install", "header", "action", "Install extension", "plus", "","installNew", the long id of me
   
   set the hilitedTabColor of me to "255,255,255"
   set the navigationDisplayStyle of me to "names"
   unlock screen
end preOpenStack

on showList pSection
   lock screen
   send "showList pSection" to card "list" of this stack
   unlock screen
end showList

command refreshList
   lock screen
   send "refreshList" to card "list" of this stack
   unlock screen
end refreshList
   
on showExtensionStore
   lock screen
   go to card "search" of this stack
   unlock screen
end showExtensionStore

on preferenceChanged pPreference, pValue
   revIDESetPreference pPreference, pValue
end preferenceChanged

on installNew
   answer file "Choose an extension to install:" with type "LiveCode Extension|lce|"
   if it is not empty then
      installExtension it, "", "widget"
   end if
end installNew

on installExtension pExtensionURL, pTypeID, pType
   lock screen  
   showList pType
   if pExtensionURL begins with "http" then
      // get from extensions store
      revIDEExtensionDownloadAndInstall pExtensionURL
   else
      // get from local .lce file
      revIDEExtensionInstall pExtensionURL, pType
   end if
   unlock screen
end installExtension