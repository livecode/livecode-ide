script "revStandaloneSettingsEmscriptenBehavior"
on preOpenCard
   initialize
   pass preOpenCard
end preOpenCard

on initialize
   local tEnableButton
   put the long id of button "Emscripten" of group "platforms" into tEnableButton
   
   -- Check whether HTML5 deployment is requested for the target stack
   local tStandaloneSettingsA
   put getSettings() into tStandaloneSettingsA
   
   set the visible of tEnableButton to revEngineCheck("Emscripten")
   set the hilite of tEnableButton to (tStandaloneSettingsA["Emscripten"] is true)
   
   -- Decide whether user is permitted to do HTML5 deployment
   local tHaveLicense
   if revLicenseType() is "community" then
      put true into tHaveLicense
   else if ("HTML5" is among the items of line 5 of the revLicenseInfo) then
      put true into tHaveLicense
   else
      put false into tHaveLicense
   end if
   
   -- Disable the checkbox if no license is available
   set the enabled of tEnableButton to tHaveLicense
   
   -- Hide the license prompt if a license is available
   set the visible of group "emscriptenLicenseTip" to not tHaveLicense
   
   tipDisplayUpdate
end initialize

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
