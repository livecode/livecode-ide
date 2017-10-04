script "revStandaloneSettingsIosBehavior"
local sProfiles

on preOpenCard
   initialize
   pass preOpenCard
end preOpenCard

on initialize
   local tSettings
   put getSettings() into tSettings
   set the hilite of button "Build for iOS" to tSettings["ios"] is true
   
   // SN-2015-05-01: [[ Refactor iOS SDK versions ]] Use deploylibraryIos function
   local tMinimumVersions
   repeat for each item tVersion in revIDEDeployIOSGetMinimumVersions()
      put tVersion && "or later" & LF after tMinimumVersions
   end repeat
   delete last char of tMinimumVersions
   set the text of button "Minimum iOS Version" to tMinimumVersions
   
   if the platform is "macos" then
      set the enabled of button "Build for iOS" to true
      updateProfiles
      updateSettings
   else
      set the enabled of button "Build for iOS" to false
      set the enabled of group "iOS Settings" to false
   end if
   
   updateIosSettingState
   
   local tTipLastShown, tShowTip
   
   put the cIDE_SAIOSTipShow of stack "revPreferences" into tShowTip
   put the cIDE_SAIOSTipLastShown of stack "revPreferences" into tTipLastShown
   
   if revLicenseType() is not "community" then
      put false into tShowTip
      set the cIDE_SAGeneralTipShow of stack "revPreferences" to false
   end if
   
   if tShowTip is false then
      if  revLicenseType() is "community" then
         if the seconds > (tTipLastShown + 2419200) then
            put true into tShowTip
         end if
      end if
   end if   
   if tShowTip is empty then put true into tShowTip
   
   set the visible of group "iOSCommercialTip" to tShowTip
   tipPreferenceSet tShowTip
   tipDisplayUpdate
end initialize

on updateProfiles
   put getIosProvisioningProfiles() into sProfiles
end updateProfiles

on updateSettings
   local tSettings
   put getSettings() into tSettings
   
   put computeDefault(tSettings["ios,display name"], tSettings["name"]) into field "Display Name"
   put computeDefault(tSettings["ios,bundle id"], "com.yourcompany.yourapp") into field "Bundle Id"
   put computeDefault(tSettings["ios,bundle version"], "1.0.0") into field "Bundle Version"
   
   -- SN-2015-03-30: [[ Bug 14794 ]] Initialise the value for 32-bit only build
   if tSettings["ios,32-bit only"] then
      set the hilite of button "32bit_only" to true
   else
      set the hilite of button "32bit_only" to false
   end if
   
   if tSettings["ios,beta version"] is not empty and tSettings["ios,beta version"] then
      set the hilite of button "beta_version" to true
   else
      set the hilite of button "beta_version" to false
   end if 
   
   -- MM-2011-09-28: Attempt to port previous icon and splash settings and then remove.
   --
   if tSettings["ios,icon"] is not empty then
      local tIcon
      put stripSuffix(tSettings["ios,icon"], ".png,-114.png,-72.png") into tIcon    
      if not (tIcon begins with slash) then
         put utilityTargetStackPath() & slash before tIcon
      end if      
      
      get tIcon & ".png"
      if there is a file  it and getImageDimensions(it) is "57,57" then
         put it into tSettings["ios,iphone icon"]
         storeSetting("iphone icon", utilityMakePathRelative(it, utilityTargetStackPath()))
      end if
      get tIcon & "-114.png"
      if there is a file  it and getImageDimensions(it) is "114,114" then
         put it into tSettings["ios,retina icon"]
         storeSetting("retina icon", utilityMakePathRelative(it, utilityTargetStackPath()))
      end if 
      get tIcon & "-72.png"
      if there is a file  it and getImageDimensions(it) is "72,72" then
         put it into tSettings["ios,ipad icon"]
         storeSetting("ipad icon", utilityMakePathRelative(it, utilityTargetStackPath()))
      end if      
      
      storeSetting "icon", empty
   end if
   
   if tSettings["ios,splash"] is not empty then
      local tSplash
      put stripSuffix(tSettings["ios,splash"], ".png,-@2x.png,-Landscape.png,-Portrait") into tSplash    
      if not (tSplash begins with slash) then
         put utilityTargetStackPath() & slash before tSplash
      end if
      
      get tSplash & ".png"
      if there is a file it and getImageDimensions(it) is "320,480" then
         put it into tSettings["ios,iphone splash"]
         storeSetting("iphone splash", utilityMakePathRelative(it, utilityTargetStackPath()))
      end if
      get tSplash & "@2x.png"
      if there is a file it and getImageDimensions(it) is "640,960" then
         put it into tSettings["ios,retina splash"]
         storeSetting("retina splash", utilityMakePathRelative(it, utilityTargetStackPath()))
      end if
      get tSplash & "-Portrait.png"
      if there is a file it and getImageDimensions(it) is "768,1024" then
         put it into tSettings["ios,ipad landscape splash"]
         storeSetting("ipad landscape splash", utilityMakePathRelative(it, utilityTargetStackPath()))
      end if
      get tSplash & "-Landscape.png"
      if there is a file it and getImageDimensions(it) is "1024,768" then
         put it into tSettings["ios,ipad portrait splash"]
         storeSetting("ipad portrait splash", utilityMakePathRelative(it, utilityTargetStackPath()))
      end if    
      
      storeSetting "splash", empty
   end if
   
   -- MM-2011-09-28: Sepearate out the icons and splash screens so the user can specify the values per device.
   --
   put computeDefault(tSettings["ios,iphone icon"], empty) into field "iPhone Icon"
   put computeDefault(tSettings["ios,retina icon"], empty) into field "Retina Icon"
   put computeDefault(tSettings["ios,iOS 7 retina icon"], empty) into field "iOS 7 Retina Icon"
   put computeDefault(tSettings["ios,iPhone 6 Plus icon"], empty) into field "iPhone 6 Plus Icon" 
   put computeDefault(tSettings["ios,ipad icon"], empty) into field "iPad Icon"
   put computeDefault(tSettings["ios,ipad retina icon"], empty) into field "iPad Retina Icon"
   put computeDefault(tSettings["ios,iOS 7 ipad icon"], empty) into field "iOS 7 iPad Icon"
   put computeDefault(tSettings["ios,iOS 7 ipad retina icon"], empty) into field "iOS 7 iPad Retina Icon"
   put computeDefault(tSettings["ios,iPad Pro 12.9 icon"], empty) into field "iPad Pro 12.9 Icon"
   put computeDefault(tSettings["ios,iphone splash"], empty) into field "iPhone Splash"
   put computeDefault(tSettings["ios,retina splash"], empty) into field "Retina Splash"
   put computeDefault(tSettings["ios,iphone 4inch splash"], empty) into field "iPhone 4Inch Splash"
   put computeDefault(tSettings["ios,iPhone 6 splash"], empty) into field "iPhone 6 Splash"   
   put computeDefault(tSettings["ios,iPhone 6 Plus Portrait splash"], empty) into field "iPhone 6 Plus Portrait Splash"   
   put computeDefault(tSettings["ios,iPhone 6 Plus Landscape splash"], empty) into field "iPhone 6 Plus Landscape Splash"
   put computeDefault(tSettings["ios,ipad portrait splash"], empty) into field "iPad Portrait Splash"
   put computeDefault(tSettings["ios,ipad landscape splash"], empty) into field "iPad Landscape Splash"
   put computeDefault(tSettings["ios,ipad retina portrait splash"], empty) into field "iPad Retina Portrait Splash"
   put computeDefault(tSettings["ios,ipad retina landscape splash"], empty) into field "iPad Retina Landscape Splash"   
   put computeDefault(tSettings["ios,ipad pro 12.9 portrait splash"], empty) into field "iPad Pro 12.9 Portrait Splash"
   put computeDefault(tSettings["ios,ipad pro 12.9 landscape splash"], empty) into field "iPad Pro 12.9 Landscape Splash"  
   
   local tProfiles, tProfileIndex
   put empty into tProfileIndex
   get the keys of sProfiles
   sort it numeric by sProfiles[each]["index"]
   repeat for each line tLine in it
      put sProfiles[tLine]["name"] & return after tProfiles
      if tLine is tSettings["ios,profile"] then
         put sProfiles[tLine]["index"] into tProfileIndex
      end if
   end repeat
   set the text of button "Profile" to tProfiles
   if tProfileIndex is empty then
      set the label of button "Profile" to "(none)"
   else
      set the menuHistory of button "Profile" to tProfileIndex
   end if
   
   get computeDefault(tSettings["ios,status bar hidden"], "false")
   set the hilite of button it of group "Status Bar" to true
   
   -- MM-2013-09-23: Added iPad status bar visibility.
   --
   get computeDefault(tSettings["ios,ipad status bar hidden"], false)
   set the hilite of button it of group "iPad Status Bar" to true
   
   local tStatusBarStyle
   put computeDefault(tSettings["ios,status bar style"], "default") into tStatusBarStyle
   repeat for each line tLine in the text of button "Status Bar Style"
      get tLine
      replace space with empty in it
      if tStatusBarStyle is it then
         set the label of button "Status Bar Style" to tLine
         exit repeat
      end if
   end repeat
   
   get computeDefault(tSettings["ios,device family"], "1")
   enableDeviceSpecificSettings it
   if it is "1" then
      get "iPod and iPhone"
   else if it is "2" then
      get "iPad"
   else if it is "1,2" then
      get "iPod, iPhone and iPad"
   end if
   set the label of button "Supported Devices" to it
   
   -- We only support iOS 6.0 and later
   --
   if tSettings["ios,minimum version"] is not empty and tSettings["ios,minimum version"] < "6.0" then
      put empty into tSettings["ios,minimum version"]
   end if   
   
   set the label of button "Minimum iOS Version" to computeDefault(tSettings["ios,minimum version"], "6.0") && "or later"
   set the hilite of button "Persistent WiFi" to computeDefault(tSettings["ios,persistent wifi"], "false")
   set the hilite of button "Background Audio" to computeDefault(tSettings["ios,background audio"], "false")
   set the hilite of button "Exits on Suspend" to computeDefault(tSettings["ios,exits on suspend"], "true")
   set the hilite of button "File Sharing" to computeDefault(tSettings["ios,file sharing"], "false")
   set the hilite of button "Prerendered Icon" to computeDefault(tSettings["ios,prerendered icon"], "false")
   set the hilite of button "Disable ATS" to computeDefault(tSettings["ios,disable ATS"], "false")
   set the label of button "Build Type" to computeDefault(tSettings["ios,build type"], "Universal")
   
   repeat with i = 1 to 18
      get tSettings["ios,device capabilities"][the short name of group i of group "Device Capabilities"]
      if it is "true" then
         get 1
      else if it is "false" then
         get 2
      else
         get 3
      end if
      set the hilite of button it of group i of group "Device Capabilities" to true
   end repeat
   
   -- MM-2012-02-12: Added support for push notificaitons and custom URL schemes
   --
   put computeDefault(tSettings["ios,url name"], empty) into field "URL Name"   
   set the hilite of button "Push Notifications" to computeDefault(tSettings["ios,push notifications"], "false")
   -- PM-2015-04-01: [[ Bug 15131 ]] Make sure Local Notifications checkbox is refreshing properly
   set the hilite of button "Local Notifications" to computeDefault(tSettings["ios,local notifications"], "false")
   
   -- SN-2015-03-16: [[ Bug 14410 ]] Added font mapping setting
   put computeDefault(tSettings["ios,fontmappings"],empty) into field "FontMap"
   
   -- PM-2014-10-20: [[ Bug 13590]] Store the location authorization type
   -- PM-2014-10-20: [[ Bugs 13764 and 14290]] Location Auth type should be visible even if n/a is selected ifor GPS/Location Services
   get computeDefault(tSettings["ios,location auth type"], "always")
   set the hilite of button it of group "Location Auth Type" to true
   set the enabled of group  "location auth" to (tSettings["ios,device capabilities"]["GPS"] is not false or tSettings["ios,device capabilities"]["location-services"] is not false)
   
   updateOrientationSettings
end updateSettings

command updateOrientationSettings
   local tSettings
   put getSettings() into tSettings
   
   -- MM-2011-08-28: Attempt to port accross previous orientation settings.
   --
   if tSettings["ios,initial orientation"] is not empty then
      if tSettings["ios,iphone initial orientation"] is empty and tSettings["ios,initial orientation"] is among the items of "Portrait,PortraitUpsideDown" then
         put tSettings["ios,initial orientation"] into tSettings["ios,iphone initial orientation"]
         storeSetting "iphone initial orientation", tSettings["ios,iphone initial orientation"]
      end if
      storeSetting "initial orientation", empty
   end if
   if tSettings["ios,interface orientations"] is not empty then
      if tSettings["ios,ipad initial orientations"] is empty then
         put tSettings["ios,interface orientations"] into tSettings["ios,ipad intial orientations"]
         storeSetting "ipad intial orientations", tSettings["ios,ipad intial orientations"]
      end if
      storeSetting "interface orientations", empty
   end if
   
   -- MM-2011-08-28: Oreintation settings have been rejigged.  The initial oreintaion drop-down
   -- has been replaced by the iphone intial oreintation.
   --
   local tInitialOrientation
   put computeDefault(tSettings["ios,iphone initial orientation"], "Portrait") into tInitialOrientation
   repeat for each line tLine in the text of button "iPhone Intial Orientation"
      get tLine
      replace space with empty in it
      replace "-" with empty in it
      if it is tInitialOrientation then
         set the label of button "iPhone Intial Orientation" to tLine
         exit repeat
      end if
   end repeat
   
   -- MM-2011-08-28: Oreintation settings have been rejigged.  The allowed oreintations
   -- has been replaced by the ipad intial oreintations.  This is now indepdant from the iPhone
   -- intial oreintation.
   --
   local tSupportedOrientations
   put computeDefault(tSettings["ios,ipad intial orientations"], empty) into tSupportedOrientations
   if "ios,ipad intial orientations" is not among the keys of tSettings then
      put "Portrait" into tSupportedOrientations
      storeSetting "ipad intial orientations", tSupportedOrientations
   end if
   repeat with i = 1 to 4
      get the short name of button i of group "iPad Initial Orientations"
      set the hilite of button i of group "iPad Initial Orientations" to \
            it is among the items of tSupportedOrientations
   end repeat
   
   -- Set the enabled of the iPad splash screens selectors based on the orientations set.
   -- Possibly turn this off, might be quite annoying.
   --
   if the enabled of group "iPad Initial Orientations" then
      set the enabled of group "iPad Portrait Splash" to (tSupportedOrientations contains "portrait")
      set the enabled of group "iPad Landscape Splash" to (tSupportedOrientations contains "landscape")
      set the enabled of group "iPad Retina Portrait Splash" to (tSupportedOrientations contains "portrait")
      set the enabled of group "iPad Retina Landscape Splash" to (tSupportedOrientations contains "landscape")
      set the enabled of group "iPad Pro 12.9 Portrait Splash" to (tSupportedOrientations contains "portrait")
      set the enabled of group "iPad Pro 12.9 Landscape Splash" to (tSupportedOrientations contains "landscape")
   end if
   
   if the enabled of button "iPhone Intial Orientation" then
      set the enabled of group "iPhone 6 Plus Portrait Splash" to tInitialOrientation contains "portrait"
      set the enabled of group "iPhone 6 Plus Landscape Splash" to tInitialOrientation contains "landscape"
   end if
end updateOrientationSettings

-- MM-2011-09-28: Enable/disable setting device specif settings based on the currently selected device list.
-- MM-2012-03-23: Added iPad retina icons and launch images.
-- MM-2013-09-23: Added new iOS 7 icons.
-- MM-2013-09-23: Added iPad status bar visibility.
--
command enableDeviceSpecificSettings pDevices
   set the enabled of group "iPhone Icon" to (1 is among the items of pDevices)
   set the enabled of group "Retina Icon" to (1 is among the items of pDevices)
   set the enabled of group "iOS 7 Retina Icon" to (1 is among the items of pDevices)
   set the enabled of group "iPhone 6 Plus Icon" to (1 is among the items of pDevices)
   set the enabled of group "iPad Icon" to (2 is among the items of pDevices)
   set the enabled of group "iPad Retina Icon" to (2 is among the items of pDevices)
   set the enabled of group "iOS 7 iPad Icon" to (2 is among the items of pDevices)
   set the enabled of group "iOS 7 iPad Retina Icon" to (2 is among the items of pDevices)
   set the enabled of group "iPad Pro 12.9 Icon" to (2 is among the items of pDevices)
   set the enabled of group "iPhone Splash" to (1 is among the items of pDevices)
   set the enabled of group "Retina Splash" to (1 is among the items of pDevices)
   set the enabled of group "iPhone 4Inch Splash" to (1 is among the items of pDevices)
   set the enabled of group "iPhone 6 Splash" to (1 is among the items of pDevices)
   set the enabled of group "iPhone 6 Plus Portrait Splash" to (1 is among the items of pDevices)
   set the enabled of group "iPhone 6 Plus Landscape Splash" to (1 is among the items of pDevices)
   set the enabled of group "iPad Portrait Splash" to (2 is among the items of pDevices)
   set the enabled of group "iPad Landscape Splash" to (2 is among the items of pDevices)
   set the enabled of group "iPad Retina Portrait Splash" to (2 is among the items of pDevices)
   set the enabled of group "iPad Retina Landscape Splash" to (2 is among the items of pDevices)
   set the enabled of group "iPad Pro 12.9 Portrait Splash" to (2 is among the items of pDevices)
   set the enabled of group "iPad Pro 12.9 Landscape Splash" to (2 is among the items of pDevices)
   set the enabled of button "iPhone Intial Orientation" to (1 is among the items of pDevices)  
   set the enabled of group "iPad Initial Orientations" to (2 is among the items of pDevices)
   
   set the enabled of group "Status Bar" to (1 is among the items of pDevices)
   set the enabled of group "iPad Status Bar" to (2 is among the items of pDevices)   
end enableDeviceSpecificSettings

on storeSetting pName, pValue
   checkSettingsCompatible pName, pValue
   setSetting "ios," & pName, pValue
end storeSetting

on checkSettingsCompatible pName, pValue
   if pName is "minimum version" and pValue > 10.3 then
      if getSetting("ios,32-bit only") is true then 
         answer error "32-bit only apps are not supported on iOS 11.0 and above"
      end if
   end if
   
   if pName is "32-bit only" and pValue is true then
      if getSetting("ios,minimum version") > 10.3 then 
         answer error "32-bit only apps are not supported on iOS 11.0 and above"
      end if
   end if
end checkSettingsCompatible

function fetchSetting pName
   return getSetting("ios," & pName)
end fetchSetting

command clearSetting pName
   storeSetting pName, empty
   updateSettings
end clearSetting

function getProfiles
   return sProfiles
end getProfiles

on updateIosSettingState
   set the enabled of group "iOS Settings" of me to (the hilite of button "Build for iOS" of me)
   set the visible of button "iOSChecked" to (the hilite of button "Build for iOS" of me)
   set the opaque of button "iOSChecked" to false
   -- SN-2015-03-30: [[ Bug 14794 ]] Add a checkbox for disable the 64-bit slice
   --  which is only valid for 5.1.1 built (for iPad 1).
   set the enabled of button "32bit_only" to (the hilite of button "Build for iOS")
end updateIosSettingState

on chooseImageFile pType
   local tRelativeFile
   put selectImageFile() into tRelativeFile
   
   if tRelativeFile is not empty then
      storeSetting pType, tRelativeFile
      updateSettings
   end if
end chooseImageFile

on chooseFontMapFile
   local tRelativeFile
   put selectFontMapFile() into tRelativeFile
   
   if tRelativeFile is not empty then
      storeSetting "fontmappings", tRelativeFile
      updateSettings
   end if
end chooseFontMapFile

on chooseImageFileWithDimension pType, pDimensions
   local tRelativeFile
   put selectImageFile(pDimensions) into tRelativeFile
   
   if tRelativeFile is not empty then
      storeSetting pType, tRelativeFile
      updateSettings
   end if
end chooseImageFileWithDimension

on tipDisplayUpdate
   if the visible of group "iOSCommercialTip" then
      set the topLeft of group "iosBuild" to 12,136
      set the topLeft of group "iOS Settings" to -1,136
      set the cSize of this card to 1024,726
   else 
      set the topLeft of group "iOS Settings" to -1,67
      set the topLeft of group "iosBuild" to 12,68
      set the cSize of this card to 1024,676
   end if
   updateCardSize
end tipDisplayUpdate

on tipPreferenceSet pValue
   set the cIDE_SAIOSTipShow of stack "revPreferences" to pValue
   set the cIDE_SAIOSTipLastShown of stack "revPreferences" to the seconds
end tipPreferenceSet

function getIosProvisioningProfiles
   local tOldFolder
   put the folder into tOldFolder
   
   set the folder to "~/Library/MobileDevice/Provisioning Profiles"
   if the result is not empty then
      return empty
   end if
   
   local tProfileFiles
   put the files into tProfileFiles
   filter tProfileFiles with "*.mobileprovision"
   
   local tProfiles
   repeat for each line tProfile in tProfileFiles
      local tContents, tAppId, tIsDist, tName, tId
      put url ("file:" & tProfile) into tContents
      
      set the itemDelimiter to "."
      put item 1 of tProfile into tId
      set the itemDelimiter to comma
      
      get lineOffset("<key>DeveloperCertificates</key>", tContents)
      if it is 0 then
         next repeat
      end if
      get line it + 3 to it + (lineOffset("</data>", tContents, it) - 1) of tContents
      put the base64Decode of it contains "Distribution" into tIsDist
      
      get lineOffset("<key>ApplicationIdentifierPrefix</key>", tContents)
      if it is 0 then
         next repeat
      end if
      get word 1 to -1 of line it + 2 of tContents
      get char 9 to -10 of it
      put it into tAppId
      
      get lineOffset("<key>Name</key>", tContents)
      if it is 0 then
         next repeat
      end if
      get word 1 to -1 of line it + 1 of tContents
      put char 9 to -10 of it into tName
      
      put tId into tProfiles[tId]["id"]
      put tName into tProfiles[tId]["name"]
      put tAppId into tProfiles[tId]["appid"]
      put tIsDist into tProfiles[tId]["store"]
   end repeat
   
   local tIndex
   get the keys of tProfiles
   sort it by tProfiles[each]["name"]
   repeat for each line tLine in it
      add 1 to tIndex
      put tIndex into tProfiles[tLine]["index"]
   end repeat
   
   set the folder to tOldFolder
   
   return tProfiles
end getIosProvisioningProfiles
