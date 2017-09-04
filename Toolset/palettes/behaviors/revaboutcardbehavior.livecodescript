script "revAboutCardBehavior"
on preOpenStack
   local tEdition, tPath
   
   lock screen
   
   put revEnvironmentEditionProperty("name") && "Edition" into field "Edition"
   
   put the version && "| Build" && the buildNumber into field "version"
   set the blendLevel of field "version" to 40
   
   set the htmlText of field "Copyright" of me to "<p>&copy; 2000-" & word -1 of the long date && "LiveCode Ltd.</p>"
   revFontApplySystemStyle the long id of field "Copyright" of me, empty, empty
   
   set the textColor of char 1 to -1 of field "displayData" of me to empty
   set the textColor of char 1 to 5 of field "displayData" of me to aboutHiliteColor()
   loadText "about"
   
   set the title of this stack to "About LiveCode" && line 4 of the revLicenseInfo
   
   if char 1 of the version < 7 then
      put ideCoreFolderPath("skin", "about-background_legacy.png") into tPath
      set the textColor of field "version" of me to "white"
      set the textColor of field "edition" of me to "white"
   else
      put ideCoreFolderPath("skin", "about-background.png") into tPath
      set the textColor of field "version" of me to empty
      set the textColor of field "edition" of me to empty
   end if
   
   setBackgroundImage tPath
   set the windowShape of this stack to 102250
   set the loc of this stack to the screenLoc
   unlock screen
end preOpenStack

on preOpenCard
   if the editionType is "commercial" and revLicenseInfo["com.livecode.norevenuelimit"] is empty then
      set the visible of field "License" to true
   else
      set the visible of field "License" to false
   end if
end preOpenCard

on openCard
  send "revStartScroll" to field "Credits"
end openCard

on mouseUp
  close this stack
end mouseUp

on setBackgroundImage pImagePath
   set the filename of image id 102250 to pImagePath
   set the topLeft of image id 102250 to 0,0
   set the rect of this stack to the rect of image id 102250
   set the windowShape of this stack to 102250   
end setBackgroundImage

on loadText pType
   local tFilePath
   set the itemDel to "/"
   switch pType
      case "about"
         put item 1 to -3 of the filename of stack "home" & "/about.txt" into tFilePath
         break
      case "legal"
         put item 1 to -3 of the filename of stack "home" & "/Open Source Licenses.txt" into tFilePath
         break
   end switch
   put textDecode(url ("binfile:" & tFilePath), "utf-8") into field "credits" of me
end loadText

function aboutHiliteColor
   return revEnvironmentEditionProperty("revabout_hilite_color")
end aboutHiliteColor
