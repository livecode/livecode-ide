script "revProjectBrowserBehavior"
on preOpenStack   
   dispatch "setAsBehavior" to revIDEFrameBehavior() with the long id of this me
   set the zoomBox of this stack to false
   clearFrameData
   
   # Navigation
   
   # Footer Actions
   addFrameItem "alignLeft","footer", "action", "Align left", "object align left", "","alignControls", the long id of me, "left"
   addFrameItem "alignTop","footer", "action", "Align top", "object align top", "","alignControls", the long id of me, "top"
   addFrameItem "alignRight","footer", "action", "Align right", "object align right", "","alignControls", the long id of me, "right"
   addFrameItem "alignBottom","footer", "action", "Align bottom", "object align bottom", "","alignControls", the long id of me, "bottom"
   
   addFrameItem "centerX","footer", "action", "Center vertically", "object align horizontal center", "","centerControls", the long id of me, "horizontal"
   addFrameItem "centerY","footer", "action", "Center horizontally", "object align vertical center", "","centerControls", the long id of me, "vertical"
   
   addFrameItem "equalizeWidth","footer", "action", "Equalize width", "object justify horizontal", "","equalizeControls", the long id of me, "width"
   addFrameItem "equalizeHeight","footer", "action", "Equalize height", "object justify vertical", "","equalizeControls", the long id of me, "height"
   addFrameItem "equalizeRect","footer", "action", "Equalize rect", "object justify both", "","equalizeControls", the long id of me, "rect"
   
   addFrameItem "distributeVertically","footer", "action", "Layout vertically", "resize vertical", "","distributeControls", the long id of me, "vertical"
   addFrameItem "distributeHorizontally","footer", "action", "Layout horizontally", "resize horizontal", "","distributeControls", the long id of me, "horizontal"
   
   addFrameItem "newControl","footer", "action", "New control", "file alt", "","newControls", the long id of me
   addFrameItem "groupControl","footer", "action", "Group controls", "folder open alt", "","groupControls", the long id of me
   addFrameItem "cloneControl","footer", "action", "Clone control", "files alt", "","cloneControls", the long id of me
   addFrameItem "deleteControl","footer", "action", "Delete control", "trash", "","deleteControls", the long id of me
   
   
   # Preferences
   addFrameItem "ideProjectBrowser_objectType", "header", "preference", "Object type indicator", "enum","Text,Icon", "preferenceChanged", the long id of me
   addFrameItem "ideProjectBrowser_show", "header", "preference", "Show Sections", "set","Front Scripts,Stacks,Back Scripts,Stacks in use", "displayPreferenceSelected", the long id of me
   addFrameItem "ideProjectBrowser_order","header","preference","Order by","enum","Name,Number","preferenceChanged",the long id of me
   addFrameItem "ideProjectBrowser_style","header","preference","Display style","enum","All,Card and Object","preferenceChanged",the long id of me
   
   revIDESubscribe "idePreferenceChanged:cShowRevolutionStacks"
   revIDESubscribe "idePreferenceChanged:ideProjectBrowser_sortOrder"
   revIDESubscribe "idePreferenceChanged:ideProjectBrowser_thumbnails"
   revIDESubscribe "idePreferenceChanged:ideProjectBrowser_groupThumbnails" 
   revIDESubscribe "idePreferenceChanged:ideProjectBrowser_objectType"
   revIDESubscribe "idePreferenceChanged:ideProjectBrowser_order"
   revIDESubscribe "idePreferenceChanged:ideProjectBrowser_show"
   revIDESubscribe "idePreferenceChanged:ideProjectBrowser_style"
   goPreferredCard
end preOpenStack

on goPreferredCard
   local tCardPreference
   put revIDEGetPreference("ideProjectBrowser_style") into tCardPreference
   if tCardPreference is "Card and Object" then
      go card "card view"
   else
      go card "list"
   end if
end goPreferredCard

on preferenceChanged pPreference, pValue
   local tOldValue
   
   switch pPreference
      case "ideProjectBrowser_thumbnails"
      case "ideProjectBrowser_groupThumbnails"
         put revIDEGetPreference(pPreference) into tOldValue
         revIDESetPreference pPreference, not(tOldValue)
         break
      case "ideProjectBrowser_sortOrder"
      case "ideProjectBrowser_style"
      case "ideProjectBrowser_objectType"
      case "ideProjectBrowser_order"
         revIDESetPreference pPreference, pValue
         break
   end switch
end preferenceChanged

on idePreferenceChanged pPreference, pValue
   lock screen
   switch pPreference
      case "ideProjectBrowser_style"
         goPreferredCard
         break
      case "ideProjectBrowser_show"
      case "ideProjectBrowser_thumbnails"
      case "ideProjectBrowser_groupThumbnails" 
      case "ideProjectBrowser_sortOrder"
      case "ideProjectBrowser_objectType"
      case "ideProjectBrowser_order"
      default
         dispatch "rebuildView" to this card of me
   end switch
   unlock screen
end idePreferenceChanged

on displayPreferenceSelected pPreference, pValue
   lock screen
   if pPreference is "ideProjectBrowser_show" then
      local tCurrentPreferenceValue, tPreferencePosition
      put revIDEGetPreference("ideProjectBrowser_show") into tCurrentPreferenceValue
      
      put itemoffset(pValue, tCurrentPreferenceValue) into tPreferencePosition
      if tPreferencePosition > 0 then
         delete item tPreferencePosition of tCurrentPreferenceValue
      else
         put "," & pValue after tCurrentPreferenceValue
      end if
      revIDESetPreference "ideProjectBrowser_show", tCurrentPreferenceValue
   end if
   unlock screen
end displayPreferenceSelected
