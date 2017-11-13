script "revIDEExtensionManagerRowBehavior"
on FillInData pDataA, pRow
   # Map pDataA values to physical controls...
   local tVersion
   
   set the cTypeID of me to pDataA["name"]
   
   local tLabel, tAuthor
   if pDataA["title"] is not empty then put pDataA["title"] into tLabel
   else if pDataA["label"] is not empty then put pDataA["label"] into tLabel
   else if pDataA["display name"] is not empty then put pDataA["display name"] into tLabel
   else put pDataA["name"] into tLabel
   
   if pDataA["author"] is not empty then put pDataA["author"] into tAuthor
   if tAuthor is empty then put "Unknown Author" into tAuthor
   
   put tLabel & return & tAuthor  into field "description" of me
   
   local tShowSVGIcon, tSVGIcon, tDefaultName
   put true into tShowSVGIcon
   revIDEExtensionIconFromType pDataA["type"], pDataA["name"], tDefaultName, tSVGIcon
   if tSVGIcon is not empty then
      set the iconPath of widget "svgicon" of me to pDataA["svgicon"]
   else if pDataA["icon"] is not empty then
      put false into tShowSVGIcon
      set the filename of image "icon" of me to pDataA["icon"] 
   else
      set the iconPresetName of widget "svgicon" of me to tDefaultName
   end if
   
   if tShowSVGIcon then
      show widget "svgicon" of me
      hide image "icon" of me
   else
      hide widget "svgicon" of me
      show image "icon" of me
   end if
   
   ## Is an update available
   put char -5 to -1 of pDataA["identifier"] into tVersion
   if pDataA["latest"] is not tVersion then
      set the cLatestVersion of me to pDataA["latest"]
      hide button "uninstall" of me
      show button "update" of me
   else
      show button "uninstall" of me
      hide button "update" of me
   end if
   
   set the cIDE of me to (pDataA["ide"] is true)
   if pDataA["ide"] is true then
      hide button "uninstall" of me
   else
      show button "uninstall" of me
   end if
   
   switch pDataA["status"]
      case "installed"
         hide button "cancel" of me
         hide group "installProgress" of me
         hide image "Error" of me
         hide field "Error Message" of me
         break
      case "error"
         hide button "cancel" of me
         hide group "installProgress" of me
         show image "Error" of me
         put pDataA["error"] into field "Error Message" of me
         show field "Error Message" of me
         break
      case "uninstalled"         
         hide button "uninstall" of me
         hide button "cancel" of me
         hide group "installProgress" of me
         hide image "Error" of me
         put "Restart required" into field "Error Message" of me
         show field "Error Message" of me
         break
      default
         hide button "uninstall" of me
         show group "installProgress" of me
         put pDataA["status"] into field "installProgressStatus" of me
         set the thumbposition of scrollbar "installProgressBar" of me to  pDataA["progress"]
         hide image "Error" of me
         hide field "Error Message" of me
         break         
   end switch   
end FillInData

on LayoutControl pControlRect
   
   local tMargin, tPadding, tIconLoc
   
   # Resize controls/row
   put the paletteMargin of me into tMargin
   put the palettePadding of me into tPadding
   
   set the rect of graphic "background" of me to pControlRect
   set the width of graphic "border" of me to (item 3 of pControlRect - item 1 of pControlRect)
   set the bottomLeft of graphic "border" of me to item 1 of pControlRect, item 4 of pControlRect
   put the loc of me into tIconLoc
   set the loc of widget "svgicon" of me to tIconLoc
   set the left of widget "svgicon" of me to item 1 of pControlRect + tMargin
   set the loc of image "icon" of me to the loc of widget "svgicon" of me  
   --set the width of field "description" of me to (item 3  of pControlRect - item 1 of pControlRect) - the width of image "icon" of me - the width of button "uninstall" of me
   set the width of field "description" of me to the formattedWidth of field "description" of me
   set the height of field "description" of me to the formattedHeight of field "description" of me
   set the loc of field "description" of me to the loc of me
   set the left of field "description" of me to the right of widget "svgicon" of me + tPadding
   
   set the textColor of line 1 of field "description" of me to revIDEColor("text_1")
   set the textColor of line 2 of field "description" of me to revIDEColor("text_2")
   
   set the loc of button "uninstall" of me to the loc of me
   set the right of button "uninstall" of me to item 3 of pControlRect - tMargin
   set the rect of button "update" of me to the rect of button "uninstall" of me
   set the rect of button "cancel" of me to the rect of button "uninstall" of me
   
   ## Progress Bar
   set the width of group "installProgress" of me to (item 3 of pControlRect - the right of field "description" of me - the width of button "uninstall" of me) - (tMargin)
   set the loc of group "installProgress" of me to the loc of me
   set the right of group "installProgress" of me to the right of me - tPadding
   
   hide button "cancel" of me
   
   ## Error data
   set the loc of image "Error" of me to the loc of me
   set the right of image "Error" of me to the left of button "Uninstall" of me - tPadding
   set the width of field "Error Message" of me to the formattedWidth of field "Error Message" of me
   set the loc of field "Error Message" of me to the loc of me
   
   if the visible of image "Error" of me then
      set the right of field "Error Message" of me to the left of image "Error" of me
   else
      set the right of field "Error Message" of me to item 3 of pControlRect - tMargin
   end if
   
   -- Don't allow the error field to overspill the description
   -- or go past a third of the width
   local tLeft
   put max(the right of field "description" of me + tPadding, \
         the width of me / 3) into tLeft
   if the left of field "Error Message" of me < tLeft then
      set the dontWrap of field "Error Message" of me to false
      local tWidth
      put the right of field "Error Message" of me into tWidth
      subtract tLeft from tWidth
      set the width of field "Error Message" of me to tWidth
      set the height of field "Error Message" of me to the formattedHeight of field "Error Message" of me
      set the loc of field "Error Message" of me to the loc of me
      set the left of field "Error Message" of me to tLeft
   end if
end LayoutControl

on mouseUp
   switch the short name of the target
      case "activate"
         answer "Are you sure you want to activate extension" && the cTypeID of me & "?" with "Cancel" and "Yes"
         if it is "Yes" then
            activateExtension the cTypeID of me
         end if
         break
      case "deactivate"
         answer "Are you sure you want to deactivate extension" && the cTypeID of me & "?" with "Cancel" and "Yes"
         if it is "Yes" then
            deactivateExtension the cTypeID of me
         end if
         break
      case "uninstall"
         answer "Are you sure you want to uninstall extension" && the cTypeID of me & "?" with "Cancel" and "Yes"
         if it is "Yes" then
            uninstallExtension the cTypeID of me
         end if
         break
      case "update"
         answer "Are you sure you want to update extension" && the cTypeID of me & "?" with "Cancel" and "Yes"
         if it is "Yes" then
            updateExtension the cTypeID of me,  the cLatestVersion of me
         end if
         break
      case "cancel"
         answer "Are you sure you want to cancel the installation of extension" && the cTypeID of me & "?" with "Cancel" and "Yes"
         if it is "Yes" then
            cancelExtensionInstall the cTypeID of me
         end if
         break
   end switch
end mouseUp

on mouseDoubleUp
   if not the cIDE of me then
      dispatch "browserGoToExtensionPage" to card 2 of this stack with the cTypeID of me
   end if
end mouseDoubleUp

getProp dvRowControl
   return the long id of me
end dvRowControl

setProp dvHilite[pHiliteColor] pBoolean
   # Override basic hilite feature...
end dvHilite
