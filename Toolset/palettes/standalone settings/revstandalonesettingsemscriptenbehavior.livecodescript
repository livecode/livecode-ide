script "revStandaloneSettingsEmscriptenBehavior"
on preOpenCard
   initialize
   pass preOpenCard
end preOpenCard

on initialize
   local tSettings
   put getSettings() into tSettings
   local tEnabled = false
   
   -- Decide whether user is permitted to do HTML5 deployment
   local tHaveLicense
   if revLicenseType() is "community" then
      put true into tHaveLicense
   else if ("HTML5" is among the items of line 5 of the revLicenseInfo) then
      put true into tHaveLicense
   else
      put false into tHaveLicense
   end if
   
   repeat for each item tItem in revSBPlatformArchitectures("Emscripten")
      set the hilite of button ("Emscripten" && tItem) of group "platforms" of me to tSettings["Emscripten",tItem] is true
      set the visible of button ("Emscripten" && tItem) of group "platforms" of me to revEngineCheck("Emscripten" && tItem)
      if tSettings["Emscripten",tItem] then
         put true into tEnabled
      end if
      
      -- Disable the checkbox if no license is available
      set the enabled of button ("Emscripten" && tItem) of group "platforms" of me to tHaveLicense
   end repeat
   
   if not tEnabled and tSettings["Emscripten"] is true then
      set the hilite of button "Emscripten js" of group "platforms" of me to true
      put true into tSettings["Emscripten,js"]
      setSettings tSettings
   end if
   
   
   -- Hide the license prompt if a license is available
   set the visible of group "emscriptenLicenseTip" to not tHaveLicense
   
   tipDisplayUpdate
end initialize

on updateEmscriptenChecked pChecked
   set the visible of button "Emscriptenchecked" to pChecked
   set the opaque of button "Emscriptenchecked" to false
end updateEmscriptenChecked

on updateEmscriptenArch pArch, pBuild
   local tSettingsA
   put getSettings() into tSettingsA
   
   put pBuild into tSettingsA["Emscripten",pArch]
   
   local tEnabled = false
   repeat for each item tItem in revSBPlatformArchitectures("Emscripten")
      if tSettingsA["Emscripten",tItem] then
         put true into tEnabled
         exit repeat
      end if
   end repeat
   put tEnabled into tSettingsA["Emscripten"]
   setSettings tSettingsA
   
   if tEnabled then
      buildForEnabled "emscripten"
   end if
   
   revSetEdit
   updateEmscriptenChecked tEnabled
end updateEmscriptenArch

on tipDisplayUpdate
   set the backColor of graphic "emscriptenNoLicenseBackground" to ideCoreEditionColour()
   
   if the visible of group "emscriptenLicenseTip" then
      set the topLeft of group "emscriptenSettings" to 12,136
      set the cSize of this card to 567,371
   else 
      set the topLeft of group "emscriptenSettings" to -1,67
      set the cSize of this card to 567,371
   end if
   
   updateCardSize
   
end tipDisplayUpdate

on emscriptenBuyNow
   launch url "https://livecode.com/products/livecode-platform/html5-purchase-info"
end emscriptenBuyNow
