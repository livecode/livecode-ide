script "revStandaloneSettingsBehavior"
on preOpenStack
   local tLicenseType
   
   start using stack "revSaveAsStandalone"
  
   if getTargetStackName() is not among the lines of the mainStacks then
      revStandaloneSettings the mainStack of the topStack
   end if

   repeat with X=1 to the number of buttons of group "flavors" of card "Unix"
      set the enabled of button X of group "flavors" of card "Unix" to true
   end repeat
   
   updateCardSize
   
   navigateToCard "General"
   repeat with X=1 to the number of btns of group "cards"
      set the style of button X of group "cards" to "rectangle"
      set the showBorder of button X of group "cards" to false
   end repeat
   helpButtons
end preOpenStack

constant kButtonList = "General,Stacks,Copy Files,Inclusions,OS X,Windows,Unix,iOS,Android,Emscripten,Bug Reports"
private command updateTabButtons pSettings
   local tEnableMacTick
   put false into tEnableMacTick
   repeat for each item tItem in "MacOSX,MacOSX PowerPC-32,MacOSX x86-32,MacOSX x86-64"
      put tEnableMacTick or pSettings[tItem] into tEnableMacTick
   end repeat
   set the visible of button "OSXchecked" of group "checks" of me to tEnableMacTick
   
   set the visible of button "Windowschecked" of group "checks" of me to pSettings["Windows"] = true or \
         pSettings["Windows x86-64"] = true
   // SN-2015-01-13: [[ Bug 14373 ]] Check also if Linux 64 or Linux ARM are checked
   set the visible of button "UnixChecked" of group "checks" of me to pSettings["Linux"] = true \
         or pSettings["Linux x64"] = true \
         or pSettings["Linux ARMv6-HF"] = true
   set the visible of button "IosChecked" of group "checks" of me to pSettings["ios"] = true
   set the visible of button "AndroidChecked" of group "checks" of me to pSettings["android"] = true
   set the visible of button "BugsChecked" of group "checks" of me to pSettings["errorDialog"] = true
   set the visible of button "EmscriptenChecked" of group "checks" of me to pSettings["Emscripten"] = true
   
   repeat for each item tItem in "SolIntel,SolSparc,Iris,Odt,rs6000,Linux,Bsd,Hp9k700,SPARC"
      if pSettings[tItem] then
         set the visible of button "Unixchecked" of group "checks" of me to true
      end if 
   end repeat
   
   show button "Windows" of group "cards" of me
   show button "OS X" of group "cards" of me
   show button "Bug Reports" of group "cards" of me
   show button "Copy Files" of group "cards" of me
   show button "Unix" of group "cards" of me
   show button "iOS" of group "cards" of me
   show button "Emscripten" of group "cards" of me
   
   local tLeft
   put 0 into tLeft
   
   local tV
   put item 2 of the loc of button "OS X" of group "cards" of me -10 into tV
   repeat for each item tItem in kButtonList
      if the visible of button tItem of group "cards" of me then
         set the left of button tItem of group "cards" of me to tLeft
         put the right of button tItem of group "cards" of me into tLeft
      end if
      
      local tCheck
      put replaceText(tItem," ","")&"checked" into tCheck
      if there is a button tCheck of group "checks" of me then
         local tTopLeft
         put (item 1 of the loc of button tItem of group "cards" of me),tV into tTopLeft
         set the topLeft of button tCheck of group "checks" of me to tTopLeft
      end if
   end repeat
   
   set the wholeMatches to true
   set the enabled of button "OS X" of group "cards" of me to ("Mac OS X" is among the items of line 5 of the revLicenseInfo)
   set the enabled of button "Windows" of group "cards" of me to ("Windows" is among the items of line 5 of the revLicenseInfo)
   set the enabled of button "Unix" of group "cards" of me to ("Linux" is among the items of line 5 of the revLicenseInfo)
   set the enabled of button "iOS" of group "cards" of me to ("iOS" is among the items of line 5 of the revLicenseInfo)
   set the enabled of button "Android" of group "cards" of me to ("Android" is among the items of line 5 of the revLicenseInfo)
   set the enabled of button "Emscripten" of group "cards" of me to true
end updateTabButtons

on buildForEnabled pPlatform
   local tSettings
   put getSettings() into tSettings
   updateTabButtons tSettings
end buildForEnabled

on helpButtons
  local tShowBorder,tIcon,tHiliteIcon,tShowName
  if the platform is "MacOS" then
    put true into tShowBorder
    put 0 into tIcon
    put 0 into tHiliteIcon
    put true into tShowName
  else
    put false into tShowBorder
    put 202009 into tIcon
    put 202010 into tHiliteIcon
    put false into tShowName
  end if
  repeat with tCard =1 to the number of cards
    repeat with tBtn = 1 to the number of buttons of card tCard
      if the short name of button tBtn of card tCard = "help" then
        set the margins of button tBtn of cd tCard to 4
        set the hiliteBorder of button tBtn of card tCard to false
        set the showBorder of button tBtn of card tCard to tShowBorder
        set the icon of button tBtn of card tCard to tIcon
        set the hilitedIcon of button tBtn of card tCard to tHiliteIcon
        set the showName of button tBtn of card tCard to tShowName
        set the textFont of button tBtn of card tCard to ""
        set the textSize of button tBtn of card tCard to 14
        set the textStyle of button tBtn of card tCard to "bold"
      end if
    end repeat
  end repeat
end helpButtons

on revStandaloneSettings pStack
   lock screen
   if pStack = "" then 
      put the short name of the topStack into pStack
   end if
   put the mainStack of stack pStack into pStack
   set the defaultStack to pStack
   if the fileName of stack pStack is "" then
      revSaveAs pStack
      if the fileName of stack pStack is "" then exit revStandaloneSettings
   end if
   set the cRevTargetStack of stack "revStandaloneSettings" to pStack
   
   local tSettings
   put getSettings() into tSettings
   revSBDefaultStandaloneSettings pStack, tSettings
   setSettings tSettings
   modeless "revStandaloneSettings"
   send "preOpenCard" to this card of stack "revStandaloneSettings"
   updateTabButtons tSettings
   unlock screen
end revStandaloneSettings

on revSetEdit pStack
   if pStack = "" then 
      put getTargetStackName() into pStack
   end if
   revIDESetEdited pStack
end revSetEdit

constant kButtonWidth = 66
constant kMargin = 4
function minCardWidth
   return the number of buttons of group "Cards" of me * kButtonWidth + kMargin + 24
end minCardWidth

on preOpenCard
   lock screen
   updateCardSize
   updateLabel the short name of this card of me
   unlock screen
end preOpenCard

command updateCardSize
   if the cSize of this card of me is not empty then
      local tWidth,tHeight
      put max(item 1 of the cSize of this card of me, minCardWidth()) into tWidth
      put item 2 of the cSize of this card of me into tHeight
      
      revChangeWindowSize tWidth, tHeight, "snap", ,250
   end if
   dispatch "resizeStack" to this card of me
end updateCardSize

on resumeStack
   if the short name of this stack is "revStandaloneSettings" then
      local tMainstack
      put the mainStack of the topStack into tMainstack
      if tMainstack is getTargetStack() then
         send "preOpenCard" to this card of me in 0 millisecs
      end if
   end if
end resumeStack

# Parameters
#   <none>
# Description
#   Returns the folder containing the current target stack
function utilityTargetStackPath
  set the itemDelimiter to slash
  return item 1 to -2 of the filename of stack (the cRevTargetStack of me) & slash
end utilityTargetStackPath

command layoutCardsGroup
   local tX
   put 2 into tX
   
   local tNumButtons
   put the number of buttons of group "cards" into tNumButtons  
   repeat with i = 1 to tNumButtons
      local tWidth
      put kButtonWidth into tWidth
      if i = tNumButtons then
         add kMargin to tWidth
      end if
      set the width of button i of group "cards" to it
      set the left of button i to tX
      add kButtonWidth to tX
   end repeat
end layoutCardsGroup

function getImageDimensions pImageFile
   local tDims
   create invisible image
   set the filename of it to pImageFile
   put (the effective width of it, the effective height of it) into tDims
   delete it
   return tDims
end getImageDimensions

function validateIdentifier pIdentifier
   return matchText(pIdentifier, "(?i)^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$")
end validateIdentifier

on revUpdateStandaloneProgress pMessage
   lock screen
   put pMessage into field 1 of stack "revStandaloneProgress"
   if the mode of stack "revStandaloneProgress" is 0 then 
      lock messages
      modeless "revStandaloneProgress"
      set the loc of stack "revStandaloneProgress" to the screenLoc
      unlock messages
   end if
   unlock screen
   wait 0 ticks with messages -- allow for progress update
end revUpdateStandaloneProgress

command revConfirmInclusion pName, @rInclude, @rSilenceWarning
   set the cInclusion of stack "revStandaloneInclusionWarning" to pName
   modal stack "revStandaloneInclusionWarning"
   put the cInclude of stack "revStandaloneInclusionWarning" into rInclude
   put the cSilenceWarning of stack "revStandaloneInclusionWarning" into rSilenceWarning
end revConfirmInclusion

function selectImageFile pDimensions
   local tFile
   answer file "Please choose a png image" with type "PNG Images|png" or type "All files"
   put it into tFile
   if tFile is empty then
      return empty
   end if
   
   if pDimensions is not empty then
      if getImageDimensions(tFile) is not pDimensions then
         answer warning "Image is not of the required dimensions (" & pDimensions & ")"
         --exit chooseImageFileWithDimension
      end if
   end if
   
   return utilityMakePathRelative(tFile, utilityTargetStackPath())
end selectImageFile

function selectFontMapFile
   local tFile
   answer file "Please choose a font mapping file"
   put it into tFile
   if tFile is empty then
      return empty
   end if
   
   return utilityMakePathRelative(tFile, utilityTargetStackPath())
end selectFontMapFile

function selectKeyStoreFile
   local tFile
   answer file "Please choose a keystore" with type "Java keystores|keystore" or type "All files"
   put it into tFile
   if tFile is empty then
      return empty
   end if
   
   return utilityMakePathRelative(tFile, utilityTargetStackPath())
end selectKeyStoreFile

function stripSuffix pText, pSuffix
   repeat for each item tSuffix in pSuffix
      if pText ends with tSuffix then
         delete char -(the number of chars of tSuffix) to -1 of pText
         return pText
      end if
   end repeat
   return pText
end stripSuffix

function computeDefault pValue, pDefault
   if pValue is empty then
      return pDefault
   end if
   return pValue
end computeDefault

function getTargetStack
   return the long id of stack getTargetStackName()
end getTargetStack

function getTargetStackName
   return the cRevTargetStack of me
end getTargetStackName

function getSettings
   return the customProperties["cRevStandaloneSettings"] of getTargetStack()
end getSettings

function getSetting pKey
   get getSettings()
   return it[pKey]
end getSetting

command setSettings pSettings
   set the customProperties["cRevStandaloneSettings"] of getTargetStack() to pSettings
   revSetEdit
end setSettings

command setSetting pKey, pValue
   set the cRevStandaloneSettings[pKey] of getTargetStack() to pValue 
   revSetEdit
end setSetting

function updateIncludeStackFilesList pIncludeList, pPrev
   local tInclude, tMainStack, tChars, tPath
   put line 1 of pPrev into tMainStack
   set the itemDel to "/"
   put item 1 to -2 of tMainStack & "/" into tMainStack
   put the number of chars of tMainStack into tChars
   set the itemDel to ","
   repeat for each line tInclude in pIncludeList
      if there is a stack tInclude then
         if the fileName of stack tInclude is among the lines of pPrev then
            answer error ("<p>"&tInclude&"<p>is already included.") with "OK"
         else
            if char 1 to tChars of the fileName of stack tInclude = tMainStack then 
               put char tChars+1 to -1 of the fileName of stack tInclude into tPath
            else
               put the fileName of stack tInclude into tPath
            end if
            set the stackFiles of getTargetStack() to \
                  the short name of stack tInclude,tPath&cr&the stackfiles of getTargetStack()
         end if
      else
         answer error "File "&tInclude&" is not a stack!"
      end if
   end repeat
   
   local tStackFiles
   revSBRelativeStackFilesList getTargetStackName(), tStackFiles
   return tStackFiles
end updateIncludeStackFilesList

on revRecursiveRemoveStackFiles pStack,pRemoveList, @xStackFileList
  local tNewStackFiles,tRef,tStack,tOldStackFiles
  put the stackFiles of stack pStack into tOldStackFiles
  repeat for each line tRef in the stackFiles of stack pStack
    if there is a stack item 1 of tRef then
      if the effective fileName of stack item 1 of tRef is not among the lines of pRemoveList then
        put tRef&cr after tNewStackFiles
        if the effective fileName of stack item 1 of tRef is not among the lines of xStackFileList then
          put the effective fileName of stack item 1 of tRef & cr after xStackFileList
          revRecursiveRemoveStackFiles the effective fileName of stack item 1 of tRef,pRemoveList,xStackFileList
        end if
      end if
    end if
  end repeat
  delete char -1 of tNewStackFiles
  if tNewStackFiles <> tOldStackFiles then
    set the stackFiles of stack pStack to tNewStackFiles
    revSetEdit the short name of stack pStack
  end if
  put "" into tNewStackFiles
  repeat for each line tStack in the substacks of stack pStack
    put the stackFiles of stack pStack into tOldStackFiles
    repeat for each line tRef in the stackFiles of stack tStack of stack pStack
      if there is a stack item 1 of tRef then
        if the effective fileName of stack item 1 of tRef is not among the lines of pRemoveList then
          put tRef&cr after tNewStackFiles
          if the effective fileName of stack item 1 of tRef is not among the lines of xStackFileList then
            put the effective fileName of stack item 1 of tRef & cr after xStackFileList
            revRecursiveRemoveStackFiles the effective fileName of stack item 1 of tRef,pRemoveList,xStackFileList
          end if
        end if
      end if
    end repeat
    delete char -1 of tNewStackFiles
    if tNewStackFiles <> tOldStackFiles then
      set the stackFiles of stack tStack of stack pStack to tNewStackFiles
      revSetEdit the mainstack of stack tStack
    end if
    put "" into tNewStackFiles
  end repeat
end revRecursiveRemoveStackFiles

on navigateToCard pCardName
   if the short name of this card is "Android" then
      if not androidIdentifierValid() then
         exit navigateToCard
      end if
   end if
   
   lock screen
   go cd pCardName
   
   repeat with X=1 to the number of btns of group "cards" of me
      if the short name of btn X of group "cards" of me <> pCardName then 
         set the textStyle of btn X of group "cards" of me to "plain"
         set the textFont of btn X of group "cards" of me to ""
         set the textSize of btn X of group "cards" of me to ""
      else
         set the textStyle of btn X of group "cards" of me to "bold"
      end if
   end repeat
   unlock screen
end navigateToCard

on updateLabel pCardName
   local tCardName
   put the effective label of button pCardName of group "cards" of me \
         into tCardName
   local tLabel
   put "Standalone Application Settings for " & getTargetStackName() & \
         " - " & tCardName into tLabel
   set the title of me to tLabel
end updateLabel

function androidIdentifierValid
   // Check identifier
   local tIdentifier
   put field "identifier" of card "Android" into tIdentifier
   
   if not validateIdentifier(tIdentifier) then
      local tError
      put "Invalid Android identifier. The identifier can contain any number" & \
            " of items separated by a '.' character. Each item must only contain" & \
            " letters 'a-z', numbers '0-9' and the following special characters '_'." & \
            " No item can be numerical only. For example com.runrev.app_1 is" & \ 
            " valid while com.runrev.app.1 is invalid." into tError
      answer error tError
      send "selectIdentifier" to card "Android" in 0 milliseconds
      return false
   end if
   
   return true
end androidIdentifierValid

private command addToListIfNotEmpty pValue, @xList
   if pValue is not empty then
      put pValue & return after xList
   end if
end addToListIfNotEmpty

private command addProfilesToList pTarget, @xList
   addToListIfNotEmpty the cREVGeneral["profileList"] of pTarget, xList
   addToListIfNotEmpty the cREVGeneral["masterName"] of pTarget, xList
end addProfilesToList

function revGetPropertyProfilesList
   local tLine,tStackNames,tStack,tCard,tControl,tFinalList,tProfilesList
   
    local tStackFiles
   revSBStackFilesList getTargetStackName(), tStackFiles
  
   repeat for each line tLine in tStackFiles
      put the mainStack of stack tLine into tStackNames
      put cr & the subStacks of stack tStackNames after tStackNames
      lock messages
      repeat for each line tStack in tStackNames
         --stack properties here
         addProfilesToList the long id of stack tStack, tProfilesList
         repeat with tCard = 1 to the number of cds in stack tStack
            --card properties here
            addProfilesToList the long id of card tCard of stack tStack
            repeat with tControl = 1 to the number of controls on cd tCard of stack tStack
               addProfilesToList the long id of control tControl of cd tCard of stack tStack
            end repeat
         end repeat
      end repeat
   end repeat
   unlock messages
   repeat for each line tLine in tProfilesList
      if tLine is empty then next repeat
      if tLine is not among the lines of tFinalList then 
         put tLine into line (the number of lines in tFinalList)+1 of tFinalList
      end if
   end repeat
   return tFinalList
end revGetPropertyProfilesList

function selectStandaloneBuildFolder
   local tFolder
   answer folder "Please choose default folder to build standalone in"
   put it into tFolder
   if there is no folder tFolder then
      return empty
   end if
   setSetting "defaultBuildFolder", tFolder
   return tFolder
end selectStandaloneBuildFolder

command setStandaloneName pName
   set the itemDel to "."
   if item -1 of pName is among the items of "exe.app" then
      put item 1 to -2 of pName into pName
   end if
   
   if revFolderNameIsIllegal(pName) then
      put revFolderNameMakeLegal(pName) into pName
   end if
   
   setSetting "name", pName
end setStandaloneName

function revRelativePath pPath
   local tMainstackPath,tChars
   set the itemDel to "/"
   put item 1 to -2 of the effective filename of getTargetStack() & "/" into tMainStackPath
   put the number of chars of tMainStackPath into tChars
   if char 1 to tChars of pPath = tMainStackPath then 
      delete char 1 to tChars of pPath
   end if
   return pPath
end revRelativePath

function canIncludeStackFiles
   local tCan
   put true into tCan
   repeat for each item tPlatform in "ios,android,emscripten"
      if getSetting(tPlatform) then
         put false into tCan
      end if
   end repeat
   return tCan
end canIncludeStackFiles
