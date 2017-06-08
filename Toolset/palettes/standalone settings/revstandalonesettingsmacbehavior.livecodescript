script "revStandaloneSettingsMacBehavior"
on preOpenCard   
   local tStandaloneSettingsA
   put getSettings() into tStandaloneSettingsA
   
   -- MM-2014-03-21: [[ PPC Support Dropped ]] Remove any references to Universal or PPC builds in standalone settings
   --   and replace with Intel.
   if tStandaloneSettingsA["MacOSX"] then
      delete variable tStandaloneSettingsA["MacOSX"]
      put true into tStandaloneSettingsA["MacOSX x86-64"]
   end if
   
   if tStandaloneSettingsA["MacOSX PowerPC-32"] then
      delete variable tStandaloneSettingsA["MacOSX PowerPC-32"]
      put true into tStandaloneSettingsA["MacOSX x86-64"]
   end if
   
   setSettings tStandaloneSettingsA
   
   set the enabled of group "OSX" to false
   
   local tHiliteArch
   repeat with x = 1 to the number of buttons of group "Flavors"
      local tTag
      put the cSettingTag of button x of group "Flavors" into tTag
      // PM-2016-04-01: Using a stack created with LC < 8 has empty cSettingTag for button MacOSX x86_64
      put computeDefault(tStandaloneSettingsA[tTag], false) into tHiliteArch
      set the hilite of button x of group "Flavors" to tHiliteArch
      if the hilite of button x of group "Flavors" is true then
         set the enabled of group "OSX" to true
      end if
   end repeat
   
   put tStandaloneSettingsA["OSX,appicon"] into fld "appicon"
   put tStandaloneSettingsA["OSX,smallappicon"] into fld "smallappicon"
   put tStandaloneSettingsA["OSX,signature"] into fld "signature"
   put tStandaloneSettingsA["OSX,identifier"] into fld "identifier"
   put tStandaloneSettingsA["OSX,documentType"] into fld "documentType"
   put tStandaloneSettingsA["OSX,iconFile"] into fld "iconFile"
   put tStandaloneSettingsA["OSX,documenticonFile"] into fld "documenticonFile"
   put tStandaloneSettingsA["OSX,name"] into fld "name"
   put tStandaloneSettingsA["OSX,documentExtension"] into fld "documentExtension"
   put tStandaloneSettingsA["OSX,shortVersion"] into fld "shortVersion"
   put tStandaloneSettingsA["OSX,info"] into fld "info"
   put tStandaloneSettingsA["OSX,longVersion"] into fld "longVersion"
   put tStandaloneSettingsA["OSX,copyright"] into fld "copyright"
   put tStandaloneSettingsA["OSX,plist"] into fld "plist"
   
   local tSize
   put the cSize of this cd into tSize
   if tStandaloneSettingsA["OSX,plist"] = "" then
      hide group "choose"
      show group "enter"
      set the hilitedButtonName of group "plist" to "enter"
      #MJVH ~ 1208/22/05/2006
      put the cSize of group "enter" into item 2 of tSize
   else
      show group "choose"
      hide group "enter"
      set the hilitedButtonName of group "plist" to "choose"
      put the cSize of group "choose" into item 2 of tSize
   end if
   set the cSize of this cd to tSize
   pass preOpenCard
end preOpenCard
