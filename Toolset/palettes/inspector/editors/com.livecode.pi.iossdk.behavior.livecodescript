script "com.livecode.pi.iossdk.behavior.livecodescript"
on editorInitialize
   set the editorMinWidth of me to 400
   set the editorMaxWidth of me to 0
   
   if the platform is not "macos" or revIDEDeployIOSSanitizeSystemVersion() < 100700  then
      set the editorEnabled of me to false
   else
      set the editorEnabled of me to true      
   end if
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   put tValue into field "SDKs" of me
   set the enabled of field "SDKs" of me to tEnabled
   if not tEnabled then
      set the backgroundColor of graphic "SDK Status" of me to "gray"
      set the tooltip of graphic "SDK Status" of me to empty
   end if
   updateSimulators
   updateSDKs
   unlock messages
   unlock screen
end editorUpdate

constant kControlGap = 5
on editorResize
   lock screen
   lock messages
   set the width of field "ios instructions" of me to \
         the width of me
   set the height of field "ios instructions" of me \
         to the formattedheight of field "ios instructions" of me
   set the topleft of field "ios instructions" of me to \
         the topleft of me
   
   set the top of button "Add entry" of me to \
         the bottom of field "ios instructions" of me + kControlGap
   set the right of button "Add entry" of me to \
         the right of me
   
   set the top of button "Remove entry" of me to \
         the bottom of button "Add entry" of me + kControlGap
   set the right of button "Remove entry" of me to \
         the right of me
   
   set the width of field "SDKs" of me to \
         the width of me - kControlGap - \
         the width of button "Add entry" of me
   set the height of field "SDKs" of me to \
         the formattedheight of field "SDKs" of me
   set the top of field "SDKs" of me to \
         the bottom of field "ios instructions" of me + kControlGap
   set the left of field "SDKs" of me to \
         the left of me
   
   set the top of field "SDK List" of me to \
         the bottom of field "SDKs" of me + kControlGap
   set the left of field "SDK List" of me to \
         the left of me
   
   set the top of field "Simulator List" of me to \
         the bottom of field "SDK List" of me + kControlGap
   set the left of field "Simulator List" of me to \
         the left of me
   
   set the bottom of graphic "SDK Status" of me to \
         the bottom of field "Simulator List" of me
   set the right of graphic "SDK Status" of me to \
         the right of me
   
   unlock messages
   unlock screen
end editorResize

on addEntry pEntry
   put "/Contents/Developer" after pEntry
   if revIDEDeployIOSIsValidSDK(pEntry) then
      addIOSSdk pEntry
   else
      local tValidSDKs
      put revIDEDeployIOSUsableSDKs() into tValidSDKs
      replace comma with LF & TAB in tValidSDKs
      answer error "The chosen folder is not a valid iOS SDK." & LF & \
            "Selected Xcode must have an iOS SDK among:" & LF & TAB & tValidSDKs
   end if
end addEntry

command addIOSSdk pSDK
   local tValue
   put the editorValue of me into tValue
   if tValue is empty then
      put pSDK into tValue
   else
      put return & pSDK after tValue
   end if
   set the editorValue of me to tValue
   updateProperty
end addIOSSdk

command removeSelectedEntries
   local tSDKs, tLineNum
   repeat for each line tLine in field "SDKs"
      add 1 to tLineNum
      if tLineNum is among the items of the hilitedLine of field "SDKs" then
         next repeat
      end if
      if tSDKs is empty then
         put tLine into tSDKs
      else
         put return & tLine after tSDKs
      end if
   end repeat
   set the editorValue of me to tSDKs
   updateProperty
end removeSelectedEntries

on mouseUp
   local tTarget
   put the short name of the target into tTarget
   if tTarget is "Add entry" then
      -- PM-2015-04-02: No need to ask if the version of Xcode is 4.2 or earlier, since we no longer support iOS version < 5.1
      answer file "Select your XCode app bundle" with filter "APPL"
      if it is not empty then
         addEntry it
      end if
   else if tTarget is "Remove entry" then
      removeSelectedEntries
   else if tTarget is "SDKs" then
      if the hilitedLines of field "SDKs" of me is not empty then
         enable button "Remove entry" of me
      else
         disable button "Remove entry" of me
      end if
   end if
end mouseUp

command updateSimulators
   get revIDEDeployIOSGetSimulatorVersions()
   if it is empty then
      get "(none)"
   else
      replace return with comma & space in it
   end if
   put "Available simulators: " & it into field "Simulator List" of me
end updateSimulators

command updateSDKs
   local tTooltip, tAvailableSDKs, tValid
   
   dispatch function "deployCheckLatestSDKIsInstalled" to stack "revDeployLibraryIOS" with tTooltip, tAvailableSDKs
   
   put the result into tValid
   if tValid then
      set the backgroundColor of graphic "SDK Status" of me to "green"
   else
      set the backgroundColor of graphic "SDK Status" of me to "red"
   end if
   
   set the tooltip of graphic "SDK Status" of me to tTooltip   
   put "Available device SDKs: " & tAvailableSDKs into field "SDK List" of me
end updateSDKs
