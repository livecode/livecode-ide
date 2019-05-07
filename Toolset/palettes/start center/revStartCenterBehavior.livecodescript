script "revStartCenterBehavior"
constant kAllSocialMedia = "facebook,twitter,github,linkedin,youtube,stackoverflow"
constant kSocialMedia = "github,stackoverflow,youtube,facebook,twitter,linkedin"

on openStack
   revIDESubscribe "ideDesktopChanged"
   
   ## Set up the Start Center UI   
   initialiseInterface
   
   ## Logo
   logoInitialise
   
   ## Social Media
   socialMediaInitialise
   socialMediaSet
   
   ## Recent Files
   recentFilesInitialise
   recentFilesSet
   set the dgHilitedLine of group "recentFiles" to 1
   
   ## Tiles
   tilesInitialise
   
   ## First Run Controls
   set the backgroundColor of button "startTour" to uiColor("edition")
   set the filename of image "firstRunImage" of group "firstRun" to resourcesPath("images/firstRunImage.PNG")
   set the itemdelimiter to "."
   get item 1 to 2 of the version
   put merge("Welcome to LiveCode [[it]]!") into field "firstRunTitle" of me
   
   ## Set folder icon
   set the foregroundColor of widget "openIcon" to uiColor("dark grey")
   set the iconPresetName of widget "openIcon" to "folder open alt"
   
   ## Show the banner
   --bannerInitialise
   
   ## Show at startup preference
   set the foregroundColor of widget "startupCheckbox" to uiColor("dark grey")
   if revIDEGetPreference("cStartPageShow") is true then
      set the iconPresetName of widget "startupCheckbox" to "lc-checkbox-checked"
   else
      set the iconPresetName of widget "startupCheckbox" to "lc-checkbox-unchecked"
   end if
end openStack

command initialiseInterface
   hide group "Upgrade" of me
   
   ## First run
   if revIDEGetPreference("StartCenterClassic") is true then
      ## Not first run
      hide group "firstRun"
      show group "topPanel"
      --show group "tiles"
      set the top of group "recentFiles" to 0
      
      showUpgradeMini
   else
      ## First run
      hide group "banner"
      hide group "topPanel"
      --hide group "tiles"
      
      set the top of group "recentFiles" to 0
      
      set the layer of group "firstRun" to top
      show group "firstRun"
      hide group "UpgradeMini" of me
      if there is a widget "UpgradeMini" of me then
         hide widget "UpgradeMini" of me
      end if
   end if
end initialiseInterface

on firstRunVisible pVisible
   revIDESetPreference "StartCenterClassic", not pVisible
   initialiseInterface
end firstRunVisible

on ideDesktopChanged
   set the loc of me to revIDEStackScreenLoc(the short name of me)
end ideDesktopChanged

on ideNewStack
   startCenterClose
end ideNewStack

on ideOpenStack pTarget
   if not exists(pTarget) then
      exit ideOpenStack
   end if
   
   local tTargetStack
   put the short name of ideStackOfObject(pTarget) into tTargetStack
   
   if the filename of stack (the mainstack of stack tTargetStack) is among the lines of revIDEGetAllPlugins() then
      exit ideOpenStack
   end if
   
   if tTargetStack is not the short name of me then
      startCenterClose
   end if
end ideOpenStack

command startCenterClose
   close me
end startCenterClose

command logoInitialise
   ## Set the logo to the correct logo for the version
   set the iconPresetName of widget "logo" of me to "lc-logo"
   set the foregroundColor of widget "logo" of me to uiColor("logo")
   
   ## Set the title to contain the correct version string
   local tMajorVersion
   set the itemDelimiter to "."
   put item 1 to 2 of the version into tMajorVersion
   put merge("Welcome to LiveCode [[tMajorVersion]]") into field "title" of me
end logoInitialise

command socialMediaInitialise   
   ## Set the images
   local tWidget
   repeat for each item tMedia in kAllSocialMedia
      put the long id of widget tMedia of group "socialMedia" into tWidget
      hide tWidget
      set the iconPresetName of tWidget to ("lc-" & tMedia)
      set the foregroundColor of tWidget to uiColor(tMedia)
      set the fillrule of tWidget to "even odd"
      set the blendLevel of tWidget to 50
      set the behavior of tWidget to the long id of button "socialBehavior" of me
   end repeat
end socialMediaInitialise

command socialMediaSet
   local tCenterLoc, tMediaCount, tPadding, tWidth, tTotalWidth, tLeft
   
   ## Show the chosen social media
   put item 1 of the loc of group "socialMedia" into tCenterLoc
   put the number of items in kSocialMedia into tMediaCount
   put 20 into tPadding
   put 20 into tWidth
   
   put (tWidth * tMediaCount) + (tMediaCount - 1) * tPadding into tTotalWidth
   put tCenterLoc - round(tTotalWidth / 2) into tLeft
   
   repeat with x = 1 to tMediaCount
      show widget (item x of kSocialMedia)
      set the left of widget (item x of kSocialMedia) to tLeft
      add tWidth + tPadding to tLeft
   end repeat
end socialMediaSet

command socialMediaHilite pName, pValue
   if pValue is true then
      set the blendLevel of widget pName of group "socialMedia" to 0
   else
      set the blendLevel of widget pName of group "socialMedia" to 50
   end if
end socialMediaHilite

command socialMediaUnhiliteAll
   repeat with x = 1 to the number of widgets of group "socialMedia"
       set the blendLevel of widget x of group "socialMedia" to 50
   end repeat
end socialMediaUnhiliteAll

command recentFilesInitialise
   set the dgProps["hilite color"] of group "recentFiles" to uiColor("edition")
   set the linkColor of this stack to uiColor("edition")
   set the underlineLinks of this stack to false
end recentFilesInitialise

command recentFilesSet
   local tRecentStacks
   put revIDERecentStacks() into tRecentStacks
   set the dgData of group "recentFiles" to tRecentStacks
end recentFilesSet

command recentFileOpen
   local tLine, tFileData
   put the dgHilitedLine of group "recentFiles" into tLine
   put the dgDataOfLine[tLine] of group "recentFiles" into tFileData
   revIDEOpenStack tFileData["filename"]
end recentFileOpen

command tilesInitialise
   local tArray, tSourceColor, tColorStep, tTileNumber
   
   ## Set the colors of the tiles
   put uiColor("edition") into tSourceColor
   put revEnvironmentEditionProperty("start_center_tile_color_step") into tColorStep
   
   repeat with tTileNumber = 1 to 8
      add 1 to tColorStep      
      set the bgColor of widget ("tile" & tTileNumber) to tileColor(tSourceColor,tColorStep)
      set the bgHoverColor of widget ("tile" & tTileNumber) to uiColor("tileBGHover")
      
      set the fgColor of widget ("tile" & tTileNumber) to uiColor("tileFG")
      set the fgHoverColor of widget ("tile" & tTileNumber) to uiColor("tileFGHover")
      
      set the hoverState of widget ("tile" & tTileNumber) to false
      set the behavior of widget ("tile" & tTileNumber) to the long id of button "tileBehavior"
   end repeat
   
   ## Breadcrumb
   put empty into field "breadcrumb"
   set the textStyle of word 1 of field "breadcrumb" to empty
   
   put tilesArray("home") into tArray
   repeat with x = 1 to 8
      show widget ("tile" & x)
   end repeat
   tilesSet tArray
end tilesInitialise

command tilesSet pArray
   local tArray
   put pArray into tArray
   
   repeat with x = 1 to 8
      if tArray[x]["tag"] is not empty then
         set the tileLabel of widget ("tile" & x) of me to tArray[x]["label"]
         set the iconName of widget ("tile" & x) of me to tArray[x]["icon"]
         set the hoverIconName of widget ("tile" & x) of me to tArray[x]["hoverIcon"]
         set the cTag of widget ("tile" & x) of me to tArray[x]["tag"]
         set the hoverState of widget ("tile" & x) of me to false
      else
         set the tileLabel of widget ("tile" & x) of me to empty
         set the tileIcon of widget ("tile" & x) of me to empty
         set the cTag of widget ("tile" & x) of me to empty
      end if
   end repeat
end tilesSet

function resourcesPath pFileName
   return revIDEPaletteResourcePath(pFileName)
end resourcesPath

function tilesArray pState
   local tArray
   
   switch pState
      case "home"
         put "Interactive Welcome" into tArray[1]["label"]
         put "interactive_welcome" into tArray[1]["tag"]
         put "lc-location" into tArray[1]["icon"]
         put "lc-location-filled" into tArray[1]["hoverIcon"]
         put "New" into tArray[2]["label"]
         put "new" into tArray[2]["tag"]
         put "lc-add" into tArray[2]["icon"]
         put "lc-add-filled" into tArray[2]["hoverIcon"]
         put "Sample Projects" into tArray[3]["label"]
         put "samples" into tArray[3]["tag"]   
         put "lc-window" into tArray[3]["icon"]
         put "lc-window-filled" into tArray[3]["hoverIcon"]
         put "Tutorials" into tArray[4]["label"]
         put "tutorials" into tArray[4]["tag"]
         put "lc-book" into tArray[4]["icon"]
         put "lc-book-filled" into tArray[4]["hoverIcon"]
         put "In Depth Guides" into tArray[5]["label"]
         put "guides" into tArray[5]["tag"]
         put "lc-learner" into tArray[5]["icon"]
         put "lc-learner-filled" into tArray[5]["hoverIcon"]
         put "Forums" into tArray[6]["label"]
         put "forum" into tArray[6]["tag"]
         put "lc-talk" into tArray[6]["icon"]
         put "lc-talk-filled" into tArray[6]["hoverIcon"]
         put "Blog" into tArray[7]["label"]
         put "blog" into tArray[7]["tag"]
         put "lc-microphone" into tArray[7]["icon"]
         put "lc-microphone-filled" into tArray[7]["hoverIcon"]
         put "Account" into tArray[8]["label"]
         put "account" into tArray[8]["tag"]
         put "lc-person" into tArray[8]["icon"]
         put "lc-person-filled" into tArray[8]["hoverIcon"]
         break
      case "interactive_welcome"         
         put "1. User Interface" into tArray[1]["label"]
         put "tutorial_list_ui" into tArray[1]["tag"]
         put "tablet" into tArray[1]["icon"]
         put "tablet" into tArray[1]["hoverIcon"]
         put "2. Coding" into tArray[2]["label"]
         put "tutorial_list_coding" into tArray[2]["tag"]
         put "terminal" into tArray[2]["icon"]
         put "terminal" into tArray[2]["hoverIcon"]
         break
      case "tutorial_list_ui"
         put "1. Hello World" into tArray[1]["label"]
         put "tutorial_hello_world" into tArray[1]["tag"]
         put "lc-hello-world" into tArray[1]["icon"]
         put "lc-hello-world-filled" into tArray[1]["hoverIcon"]
         put "2. To Do List" into tArray[2]["label"]
         put "tutorial_todo_list" into tArray[2]["tag"]
         put "lc-todo-list" into tArray[2]["icon"]
         put "lc-todo-list-filled" into tArray[2]["hoverIcon"]
         put "3. BMI Calculator" into tArray[3]["label"]
         put "tutorial_bmi_calculator" into tArray[3]["tag"]   
         put "lc-bmi-calculator" into tArray[3]["icon"]
         put "lc-bmi-calculator-filled" into tArray[3]["hoverIcon"]
         put "1. Hello World" into tArray[1]["label"]
         put "tutorial_hello_world" into tArray[1]["tag"]
         put "lc-hello-world" into tArray[1]["icon"]
         put "lc-hello-world-filled" into tArray[1]["hoverIcon"]
         put "2. To Do List" into tArray[2]["label"]
         put "tutorial_todo_list" into tArray[2]["tag"]
         put "lc-todo-list" into tArray[2]["icon"]
         put "lc-todo-list-filled" into tArray[2]["hoverIcon"]
         break
      case "tutorial_list_coding"
         put "1. Combining Text" into tArray[1]["label"]
         put "tutorial_combining_text" into tArray[1]["tag"]
         put "font" into tArray[1]["icon"]
         put "font" into tArray[1]["hoverIcon"]
         put "2. Timers" into tArray[2]["label"]
         put "tutorial_timers" into tArray[2]["tag"]
         put "hourglass" into tArray[2]["icon"]
         put "hourglass" into tArray[2]["hoverIcon"]
         break
      case "new"
         put "New Stack" into tArray[1]["label"]
         put "newStackDefault" into tArray[1]["tag"]
         put "lc-window" into tArray[1]["icon"]
         put "lc-window-filled" into tArray[1]["hoverIcon"]
         
         put "Script Only Stack" into tArray[2]["label"]
         put "newScriptOnlyStack" into tArray[2]["tag"]
         put "lc-filetype-lcs" into tArray[2]["icon"]
         put "lc-filetype-lcs-filled" into tArray[2]["hoverIcon"]
         
         put "Tablet Portrait" into tArray[3]["label"]
         put "newTabletPortrait" into tArray[3]["tag"]
         put "lc-ipad-portrait" into tArray[3]["icon"]
         put "lc-ipad-portrait-filled" into tArray[3]["hoverIcon"]
         
         put "Tablet Landscape" into tArray[4]["label"]
         put "newTabletLandscape" into tArray[4]["tag"]
         put "lc-ipad-landscape" into tArray[4]["icon"]
         put "lc-ipad-landscape-filled" into tArray[4]["hoverIcon"]
         
         put "iPhone 6" into tArray[5]["label"]
         put "newIphone6" into tArray[5]["tag"]
         put "lc-iphone" into tArray[5]["icon"]
         put "lc-iphone-filled" into tArray[5]["hoverIcon"]
         
         put "iPhone 5" into tArray[6]["label"]
         put "newIphone5" into tArray[6]["tag"]
         put "lc-iphone" into tArray[6]["icon"]
         put "lc-iphone-filled" into tArray[6]["hoverIcon"]
         
         put "iPhone 4" into tArray[7]["label"]
         put "newIphone4" into tArray[7]["tag"]
         put "lc-iphone" into tArray[7]["icon"]
         put "lc-iphone-filled" into tArray[7]["hoverIcon"]
         
         break
   end switch
   return tArray
end tilesArray

command startCenterSetState pStateID, pArray
   switch pStateID
      case 1
         hide widget "tile8"
         break
      case 2
         hide widget "tile7"
         break
      case 3
         hide widget "tile6"
         break
      case 4
         hide widget "tile5"
         break
      case 5
         hide widget "tile4"
         break
      case 6
         hide widget "tile3"
         break
      case 7
         hide widget "tile2"
         break
      case 8
         hide widget "tile1"
         break
      case 9
         tilesSet pArray
         break
      case 10
         if 1 is among the keys of pArray then
            show widget "tile1"
         end if
         break
      case 11
         if 2 is among the keys of pArray then
            show widget "tile2"
         end if
         break
      case 12
         if 3 is among the keys of pArray then
            show widget "tile3"
         end if
         break
      case 13
         if 4 is among the keys of pArray then
            show widget "tile4"
         end if
         break
      case 14
         if 5 is among the keys of pArray then
            show widget "tile5"
         end if
         break
      case 15
         if 6 is among the keys of pArray then
            show widget "tile6"
         end if
         break
      case 16
         if 7 is among the keys of pArray then
            show widget "tile7"
         end if
         break
      case 17
         if 8 is among the keys of pArray then
            show widget "tile8"
         end if
         break
   end switch
   if pStateID < 17 then
      send "startCenterSetState pStateID+1, pArray" to me in 25 milliseconds
   end if
end startCenterSetState

command tilesUpdate pArray
   send "startCenterSetState 1, pArray" to me in 0 milliseconds
end tilesUpdate

on breadcrumbLinkClicked pLink
   if pLink is "home" then
      setState "home"
   else if pLink is "Interactive Welcome" then
      setState "interactive_welcome"      
   end if
end breadcrumbLinkClicked

on startCenterAction pAction
   local tStackName, tArray
   switch pAction
      case "interactive_welcome" 
         --tourStart
         put "Home / Interactive Welcome" into field "breadcrumb"
         set the textStyle of word 1 of field "breadcrumb" to "link"
         put tilesArray(pAction) into tArray
         tilesUpdate tArray
         hideUpgradeBrowser
         break
      case "tutorial_list_ui"
         put "Home / Interactive Welcome / User Interface" into field "breadcrumb"
         set the textStyle of word 1 of field "breadcrumb" to "link"
         set the textStyle of word 3 to 4 of field "breadcrumb" to "link"
         put tilesArray(pAction) into tArray
         tilesUpdate tArray
         hideUpgradeBrowser
         break
      case "tutorial_list_coding"
         put "Home / Interactive Welcome / Coding" into field "breadcrumb"
         set the textStyle of word 1 of field "breadcrumb" to "link"
         set the textStyle of word 3 to 4 of field "breadcrumb" to "link"
         put tilesArray(pAction) into tArray
         tilesUpdate tArray
         hideUpgradeBrowser
         break
      case "tutorial_hello_world"
         tutorialStart "Hello World"
         break
      case "tutorial_todo_list"
         tutorialStart "To Do List"
         break
      case "tutorial_bmi_calculator"
         tutorialStart "BMI Calculator"
         break
      case "tutorial_combining_text"
         tutorialStart "Combining Text"
         break
      case "tutorial_timers"
         tutorialStart "Timers"
         break
      case "new"
         put "Home / New" into field "breadcrumb"
         set the textStyle of word 1 of field "breadcrumb" to "link"
         put tilesArray(pAction) into tArray
         tilesUpdate tArray
         break
      case "samples"
         revIDELaunchResource "sample stacks"
         break
      case "guides"
         revIDEDocumentationLoad "API", "LiveCode Script"
         break
      case "tutorials"
         launch url "http://livecode.com/links/livecode/tutorials"
         break
      case "forum"
         launch url "http://livecode.com/links/livecode/forum"
         break
      case "dictionary"
         revIDEDocumentationLoad "API", "Guide"
         break
      case "blog"
         launch url "http://livecode.com/links/livecode/blog"
         break
      case "upgrade"
         --launch url "https://livecode.com/about/contact/"
         break
      case "account"
         launch url "http://livecode.com/links/livecode/account"
         break
      case "contact"
         --launch url "https://livecode.com/about/contact/"
         break
      case "website"
         launch url "http://livecode.com"
         break
      case "facebook"
         launch url "http://livecode.com/links/livecode/facebook"
         break
      case "twitter"
         launch url "http://livecode.com/links/livecode/twitter"
         break
      case "github"
         launch url "http://livecode.com/links/livecode/github"
         break
      case "linkedin"
         launch url "http://livecode.com/links/livecode/linkedin"
         break
      case "youtube"
         launch url "http://livecode.com/links/livecode/youtube"
         break
      case "stackoverflow"
         launch url "http://livecode.com/links/livecode/stackoverflow"
         break
      case "newStackDefault"
         revIDEActionNewMainstack "default"
         break
      case "newScriptOnlyStack"
         revIDEActionNewScriptOnlyStack
         break
      case "newTabletPortrait"
         revIDEActionNewMainstack "iPad/Tablet Portrait (768x1024)"
         break
      case "newTabletLandscape"
         revIDEActionNewMainstack "iPad/Tablet Lanscape (1024x768)"
         break
      case "newIphone6"
         revIDEActionNewMainstack "iPhone 6 (375x667)"
         break
      case "newIphone5"
         revIDEActionNewMainstack "iPhone 5 (320x568)"
         break
      case "newIphone4"
         revIDEActionNewMainstack "iPhone 4 (320x480)"
         break
   end switch
end startCenterAction

command setState pState
   local tArray
   
   put tilesArray(pState) into tArray
   
   put empty into field "breadcrumb"
   
   if pState is "home" then
      set the textStyle of word 1 of field "breadcrumb" to empty
      showUpgradeMini
   else if pState is "interactive_welcome" then
      hideUpgradeBrowser
      put "Home / Interactive Welcome" into field "breadcrumb"
      set the textStyle of word 1 of field "breadcrumb" to "link"
   end if
   tilesUpdate tArray
end setState

command tourStart
   lock screen
   tutorialStart "Hello World", "App Lesson"
   unlock screen
end tourStart

command tutorialStart pTutorial
   lock screen
   set the cTutorialOverride of me to true
   revIDEStartTutorial "First Run", pTutorial, "App Lesson"
   revIDESetPreference "StartCenterClassic", "true"
   revIDESubscribe "ideTutorialProgressChanged"
   startCenterClose
   unlock screen
end tutorialStart

on ideTutorialProgressChanged
   if revIDETutorialInProgress() is empty then
      revIDEUnsubscribe "ideTutorialProgressChanged"
      lock screen
      revIDEOpenPalette "start center"
      startCenterAction "interactive_welcome"
      unlock screen
   end if
end ideTutorialProgressChanged

## Banner 
command bannerInitialise
   set the top of group "recentFiles" to 0 
   hide group "banner"
   --load url "http://elanorb.on-rev.com/startcenter/banner2.txt" with message "bannerComplete"
end bannerInitialise

## Social Media 


command startupPreferenceSet
   if the iconPresetName of widget "startupCheckbox" is "lc-checkbox-unchecked" then
      set the iconPresetName of widget "startupCheckbox" to "lc-checkbox-checked"
      revIDESetPreference "cStartPageShow", true
   else
      set the iconPresetName of widget "startupCheckbox" to "lc-checkbox-unchecked"
      revIDESetPreference "cStartPageShow", false
   end if
end startupPreferenceSet

function uiColor pColor
   local tEdition
   put revLicenseType() into tEdition
   
   switch pColor
      case "edition"
         return revIDEColor("edition_color")
         --return 82,82,82
         break
      case "dark grey"
         return 128,128,128
         break
      case "mid grey"
         return "150,150,150"
         break
      case "logo"
         return revIDEColor("edition_color")
         break
      case "facebook"
         return "58,88,155"
         break
      case "twitter"
         return "0,122,185"
         break
      case "linkedin"
         return "0,122,185"
         break
      case "youtube"
         return "207,52,39"sa
         break
      case "stackoverflow"
         return "206,111,45"
         break
      case "github"
         return "0,0,0"
         break
      case "folder"
         return "128,128,128"
         break
      case "recentFilesBackground"
         return "247,247,247"
         break
      case "recentFilesHover"
         return "222,222,222"
         break
      case "tileBGHover"
         return "255,255,255"
         break
      case "tileFG"
         return "255,255,255"
         break
      case "tileFGHover"
         local tColorStep
         put revEnvironmentEditionProperty("start_center_tile_color_step") into tColorStep
         return tileColor(revIDEColor("edition_color"), tColorStep)
         break
   end switch   
end uiColor

function tileColor pSourceColor, pTileNumber
   local tRed, tGreen, tBlue, tColor
   
   put item 1 of pSourceColor into tRed
   put item 2 of pSourceColor into tGreen
   put item 3 of pSourceColor into tBlue
   
   put tRed + (pTileNumber*5), tGreen+(pTileNumber*5), tBlue+(pTileNumber*5) into tColor
   return tColor
end tileColor

function textProperty pType, pStyle
   switch pType
      case "title"
         if pStyle is "font" then
            
         else if pStyle is "size" then 
            
         end if
         break
      case "tile"
         if pStyle is "font" then
            
         else if pStyle is "size" then 
            
         end if
         break
      case "stackLabel"
         if pStyle is "font" then
            
         else if pStyle is "size" then 
            
         end if
         break
      case "stackPath"
         
         break
      case "option"
         
         break
   end switch
   
end textProperty

-- Actions triggered by the browser widgets related to upgrade
on ideAction pAction, pUrl
   switch pAction
      case "launchAdWithUrl"
         launchUpgradeBrowserWithUrl revEnvironmentEditionProperty("upgrade_url")
         break
      case "closeBrowser"
         hide widget "Upgrade" of me
         hide group "Upgrade" of me
         showBrowser "UpgradeMini", \
               revEnvironmentEditionProperty("upgrade_mini_url")
         break
      case "launchExternalUrl"
         launch url pUrl
         break
   end switch
end ideAction

private command showUpgradeMini
   if ideCanShowUpgradeOptions() and \ 
         the cTutorialOverride of me is not true then
      showBrowser "UpgradeMini", \
            revEnvironmentEditionProperty("upgrade_mini_url")
   else
      set the cTutorialOverride of me to false
      hide group "UpgradeMini" of me
      if there is a widget "UpgradeMini" of me then
         hide widget "UpgradeMini" of me
      end if
   end if
end showUpgradeMini

command showBrowser pBrowserName, pUrl
   local tBrowser
   if there is no widget pBrowserName then
      create invisible widget pBrowserName as "com.livecode.widget.browser"
   end if
   put the long id of widget pBrowserName of me into tBrowser
   if the url of tBrowser is empty then
      -- show the browser's loading placeholder
      show group pBrowserName of me
      hide tBrowser
      if pBrowserName is "UpgradeMini" then
         set the rect of tBrowser to "-1,-1,504,320"
      else
         set the rect of tBrowser to "-1,0,800,572"
      end if
      set the javascripthandlers of tBrowser to "ideAction"
      set the cLoading of tBrowser to true
      set the url of tBrowser to pUrl
   else
      show tBrowser
   end if
end showBrowser

command launchUpgradeBrowserWithUrl pUrl
   hideUpgradeBrowser
   showBrowser "Upgrade", pUrl
end launchUpgradeBrowserWithUrl

on browserNavigateComplete
   if the cLoading of the target is true then
      show the target
      set the cLoading of the target to false
   end if
end browserNavigateComplete

on browserLoadFailed
   set the cLoading of the target to false
   hide group "Upgrade" of me
   hide group "UpgradeMini" of me
end browserLoadFailed

private command hideUpgradeBrowser
   -- Don't auto-show the mini upgrade browser when the 
   -- upgrade browser is launched from elsewhere
   hide widget "UpgradeMini" of me
   hide group "UpgradeMini" of me
   set the cLoading of widget "UpgradeMini" of me to false
end hideUpgradeBrowser
