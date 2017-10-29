script "revPreferencesInspector"
on preOpenStack
   # Set the inspector behaviour
   dispatch "setAsBehavior" to revIDEInspectorBehavior() with the long id of me
   set the navigationDisplayStyle of me to "Names"
end preOpenStack

on openStack
   set the inspectorData of me to revIDEPreferencesInfo()
   revIDESubscribe "idePreferenceChanged"
end openStack

on closeStack
   revIDEUnsubscribeAll
end closeStack

# Sent by an editor when a property value is being changed
on editorValueChanged pProperty, pValue, pLockUpdates
   revIDESetPreference pProperty, pValue
end editorValueChanged

getProp displayData
   return revIDEPreferencesOfSection(inspectorSectionGetName())
end displayData

getProp viewColumns [pSection]
   return 1
end viewColumns

getProp showSubSections [pSection]
   return false
end showSubSections

function inspectorSectionIcon pSection
   switch pSection
      case "general"
         return "home"
      case "appearance"
         return "picture"
      case "files & memory"
         return "files alt"
      case "updates"
         return "download alt"
      case "script editor"
         return "lc-edit-script"
      case "object sizes"
         return "cube"
      case "project browser"
         return "sitemap"
      case "mobile support"
         return "mobile phone"
      default
         return "remove"
         break
   end switch
end inspectorSectionIcon

# Add to header actions/preferences
on inspectorAddActions
   addFrameItem "preferencesReset", "header", "action", "Reset preferences...", "undo", "undo", "preferencesResetMenuDisplay", the long id of me 
end inspectorAddActions

getProp showMultiPropLabels
   return true
end showMultiPropLabels

function inspectorForObjects
   return false
end inspectorForObjects

local sPendingPrefChanged
command prefChanged
   put empty into sPendingPrefChanged
   inspectorFill
end prefChanged

on idePreferenceChanged pPreference
   if sPendingPrefChanged is not empty then
      cancel sPendingPrefChanged
   end if
   send "prefChanged" to me in 5 millisecs
   put the result into sPendingPrefChanged
end idePreferenceChanged

command preferencesResetMenuDisplay
   local tDefaultStack
   put the defaultStack into tDefaultStack
   
   # Create the button that we're going to popup on this stack
   set the defaultstack to me
   lock messages
   if there is a button "resetPreferences" of me then delete button "resetPreferences" of me
   create button "resetPreferences"
   set the style of button "resetPreferences" of me to "menu"
   set the menumode of button "resetPreferences" of me to "popup"
   set the visible of button "resetPreferences" of me to false
   set the script of button "resetPreferences" of me to "on menuPick pItem;send" && quote & "menuPick pItem" & quote && "to this stack; end menuPick"
   unlock messages
   
   local tMenu
   put "Reset section..." & return into tMenu
   repeat for each item tSection in revIDEPreferencesSections()
      put tab & tSection &return after tMenu
   end repeat
   put "-" & return & "Reset all" after tMenu
   
   set the text of button "resetPreferences" of this stack to tMenu
   popup button "resetPreferences" of this stack at the mouseloc
   
   set the defaultStack to tDefaultStack
end preferencesResetMenuDisplay

on menuPick pWhich
   set the itemDel to "|"
   switch item 1 of pWhich
      case "Reset section..."
         revIDEPreferencesResetSection item 2 of pWhich
         break
      case "Reset all"
         revIDEPreferencesResetAll
         break
   end switch
end menuPick
