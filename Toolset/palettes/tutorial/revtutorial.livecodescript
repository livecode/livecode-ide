script "revTutorial"
local sStep, sStepNumber, sUserStack, sObjCount
on revInitialiseTutorial
   insert the script of stack "revTutorial" into front
   lock screen
   lock messages
   create button "Exit"
   set the topleft of it to 0,0
   set the script of it to "on mouseUp;endTutorial;end mouseUp"
   
   create invisible image "Shape"
   set the filename of it to revIDEPaletteResourcePath("images/quote_shape.png")
   set the windowshape of stack "revTutorial" to the id of it
   set the width of me to 485
   set the height of me to 285
   
   create field "Message"
   set the width of it to the width of me - 40   
   set the height of it to the height of me - 70
   set the left of it to 20
   set the top of it to 60
   
   unlock messages
   setRegions
   revIDESubscribe "ideNewControl"
   revIDESubscribe "ideSelectedObjectChanged"
   palette me
   show me
   set the currentStep of me to "message1"      
   unlock screen
end revInitialiseTutorial

setProp userStack pStack
   put pStack into sUserStack
end userStack

setProp currentStep pStep
   if pStep is "exit" then
      endTutorial
      exit currentStep
   end if
   
   if pStep is "button1props" and "revInspector" is in the openstacks then
      put "button1label" into pStep
   end if
   
   put pStep into sStep
   
   if pStep begins with "message" then
      local tNextStep
      switch pStep
         case "message1"
            put "stack" into tNextStep
            break
         case "message2"
            put "button1scriptopen" into tNextStep
            break
         case "message3"
            put "edittool3" into tNextStep
            break
         case "message4"
            if "revNewScriptEditor" is in the openstacks then
               put "button1script3" into tNextStep
            else
               put "button1script3open" into tNextStep
            end if
            break
         case "message5"
            put "exit" into tNextStep
            break
      end switch
      answer textForStep()
      send "setStep tNextStep" to me in 10 millisecs
   else
      disableMenuBar
      disableToolsPalette
      hideRegions
      buildMenus
      put textForStep() into field "Message"
      setLocForStep
      add 1 to sStepNumber
      setEnvironmentForStep
   end if
end currentStep

on setStep pStep
   if "Answer Dialog" is in the openstacks then
      send "setStep pStep" to me in 100 millisecs
   else
      set the currentStep of me to pStep
   end if
end setStep

on hideRegions
   if sUserStack is not empty and there is a group "guides" of sUserStack then
      repeat for each line tID in the childcontrolids of group "guides" of sUserStack
         hide control id tID of group "guides" of sUserStack
      end repeat
   end if
end hideRegions

on setEnvironmentForStep
   switch sStep
      case "stackrect"
         break
      case "graphic1"
         dispatch "isolateTool" to stack "revTools" with "com.livecode.interface.classic.RectangleGraphic"
         break
      case "field1"
         dispatch "isolateTool" to stack "revTools" with "com.livecode.interface.classic.Field"
         break
      case "button1"
         dispatch "isolateTool" to stack "revTools" with "com.livecode.interface.classic.Button"
         break
      case "graphic1rect"
         show graphic "graphic1guide" of sUserStack
         break
      case "graphic2"
         enable menu "Edit"
         break
      case "graphic2rect"
         show graphic "graphic2guide" of sUserStack
         break
      case "field1rect"
         show graphic "field1guide" of sUserStack
         break
      case "button1rect"
         show graphic "button1guide" of sUserStack
         break
      case "button1scriptopen"
         enable button "standard" of this card of stack "revMenuBar"
         break
      case "edittool1"
      case "edittool2"
      case "edittool3"
         dispatch "toolEnable" to stack "revTools" with "com.livecode.tool.Pointer"
         break
      case "runtool1"
      case "runtool2"
      case "runtool3"
         dispatch "toolEnable" to stack "revTools" with "com.livecode.tool.Browse"
         break
      case "image1rect"
         show graphic "image1guide" of sUserStack
         break
      case "field2"
         dispatch "isolateTool" to stack "revTools" with "com.livecode.interface.classic.LabelField"
         break
      case "field2rect"
         show graphic "field2guide" of sUserStack
         break
      default 
         break
   end switch
   
   if the tool is "pointer tool" then
      dispatch "toolEnable" to stack "revTools" with "com.livecode.tool.Pointer"
   else
      dispatch "toolEnable" to stack "revTools" with "com.livecode.tool.Browse"
   end if
   
end setEnvironmentForStep

on setLocForStep
   lock screen
   local tTopLeft
   local tLeft,tTop
   local tUserStackRel
   put true into tUserStackRel
   switch sStep
      case "stack"
      case "image1"
         put 160 into tLeft
         put 27 into tTop
         put false into tUserStackRel
         break
      case "graphic2"
         put 190 into tLeft
         put 27 into tTop
         put false into tUserStackRel
         break
      case "stackrect"
         put the left of sUserStack + 362 into tLeft
         put the top of sUserStack +582 into tTop
         put false into tUserStackRel
         break
      case "graphic1"
         put the right of  button "com.livecode.interface.classic.RectangleGraphic" of stack "revTools" + the left of stack "revTools" into tLeft         
         put the bottom of button "com.livecode.interface.classic.RectangleGraphic" of stack "revTools" + the top of stack "revTools" into tTop
         put false into tUserStackRel
         break
      case "field1"
         put the right of button "com.livecode.interface.classic.Field" of stack "revTools" + the left of stack "revTools" into tLeft         
         put the bottom of button "com.livecode.interface.classic.Field" of stack "revTools" + the top of stack "revTools" into tTop
         put false into tUserStackRel
         break
      case "button1"
         put the right of  button "com.livecode.interface.classic.Button" of stack "revTools" + the left of stack "revTools" into tLeft         
         put the bottom of button "com.livecode.interface.classic.Button" of stack "revTools" + the top of stack "revTools" into tTop
         put false into tUserStackRel
         break
      case "runtool1"
      case "runtool2"
      case "runtool3"
         put the right of button "com.livecode.tool.Browse" of stack "revTools" + the left of stack "revTools" into tLeft     
         put the bottom of button "com.livecode.tool.Browse" of stack "revTools" + the top of stack "revTools" into tTop    
         put false into tUserStackRel
         break
      case "edittool1"
      case "edittool2"
      case "edittool3"
         put the right of button "com.livecode.tool.Pointer" of stack "revTools" + the left of stack "revTools" into tLeft     
         put the bottom of button "com.livecode.tool.Pointer" of stack "revTools" + the top of stack "revTools" into tTop    
         put false into tUserStackRel
         break
      case "field2"
         put the right of button "com.livecode.interface.classic.LabelField" of stack "revTools" + the left of stack "revTools" into tLeft         
         put the bottom of button "com.livecode.interface.classic.LabelField" of stack "revTools" + the top of stack "revTools" into tTop
         put false into tUserStackRel
         break
      case "graphic1noline"
      case "graphic1select"
      case "button1label"
      case "button1style"
      case "button1textsize"
      case "field1name"
      case "field2name"
      case "field2dontwrap"
      case "field2color"
      case "field2align"
         put the right of stack "revInspector" into tLeft
         put the bottom of stack "revInspector" into tTop
         put false into tUserStackRel
         break
      case "graphic1rect"
         put the right of graphic "graphic1guide" of sUserStack into tLeft
         put the bottom of graphic "graphic1guide" of sUserStack into tTop
         break
      case "graphic2rect"
         put the right of graphic "graphic2guide" of sUserStack into tLeft
         put the bottom of graphic "graphic2guide" of sUserStack into tTop
         break
      case "button1rect"
         put the right of graphic "button1guide" of sUserStack into tLeft
         put the bottom of graphic "button1guide" of sUserStack into tTop
         break
      case "image1rect"
         put the right of graphic "image1guide" of sUserStack into tLeft
         put the bottom of graphic "image1guide" of sUserStack into tTop
         break
      case "field1rect"
         put the right of graphic "field1guide" of sUserStack into tLeft
         put the bottom of graphic "field1guide" of sUserStack into tTop
         break
      case "field2rect"
         put the right of graphic "field2guide" of sUserStack into tLeft
         put the bottom of graphic "field2guide" of sUserStack into tTop
         break
      case "graphic1props"
         put the right of graphic 1 of sUserStack into tLeft
         put the bottom of graphic 1 of sUserStack into tTop
         break
      case "button1props"
      case "button1script"
      case "button1script2"
      case "button1script3"
      case "button1scriptopen"
      case "button1script2open"
      case "button1script3open"
      case "check1click"
      case "field1contents"
      case "field1contents2"
         put the right of button 1 of sUserStack into tLeft
         put the bottom of button 1 of sUserStack into tTop
         break
      case "field1props"
      case "field1enter"
         put the right of field 1 of sUserStack into tLeft
         put the bottom of field 1 of sUserStack into tTop
         break
      case "field2props"
         put the right of field  2 of sUserStack into tLeft
         put the bottom of field 2 of sUserStack into tTop
         break
      default
         put the right of sUserStack into tLeft
         put the bottom of sUserStack into tTop
         break
   end switch
   if tUserStackRel then
      add the left of sUserStack to tLeft
      add the top of sUserStack to tTop
   end if
   put tLeft,tTop into tTopLeft
   
   local tAdjusted
   put (item 1 of tTopLeft - 85), (item 2 of tTopLeft) into tAdjusted
   set the topLeft of me to tAdjusted
   unlock screen
end setLocForStep

function textForStep
   local tText
   switch sStep
      case "message1"
         put "The first step in creating an App is the User Interface. You can design an app just like you would draw a picture." into tText
         put return & "Each part of your app is going to be an object you drag out from the tools palette." after tText
         break
      case "stack"
         put "Click on the File menu, and select New Mainstack..." into tText
         break
      case "stackrect"
         put "Start by resizing your stack. You can drag the edges to change the width and height." into tText
         put return & "Make this stack approximately the shape of a mobile device, as shown." after tText
         break
      case "graphic1"
         put "Drag a rectangle graphic from the Tools palette onto your stack" into tText
         break
      case "edittool1"
         put "Select the edit tool from the Tools palette to change the state of your graphic" into tText
         break
      case "graphic1rect"
         put "Resize the graphic, and position it at the top of the stack" into tText
         break
      case "graphic1props"
         put "Double click on the graphic to open up the property inspector" into tText
         break
      case "graphic1noline"
         put "Remove the outline of the graphic by setting the line thickness to 0" into tText
         break
      case "graphic1select"
         put "Click on the graphic to select it" into tText
         break
      case "graphic2"
         put "Click on the Edit menu, and duplicate the graphic" into tText
         break
      case "graphic2rect"
         put "Position the second graphic at the bottom of the stack" into tText
         break
      case "field1"
         put "Drag out a field to create a text entry control" into tText
         break
      case "field1rect"
         put "Resize the field and position it at the bottom of the stack" into tText
         break
      case "button1"
         put "Drag out a button to use for the message send action" into tText
         break
      case "button1rect"
         put "Resize and position the button at the bottom of the stack" into tText
         break
      case "button1props"
         put "Double click on the button to open up its property inspector." into tText
         break
      case "button1label"
         put "We're going to set the properties of the button to make it similar to the messages app." into tText
         put return & " First set the label of the button to 'Send'" after tText
         break
      case "button1style"
         put "Set the button style to transparent by selecting 'Trasparent Button' from the style dropdown menu. This will clear everything except the text from the button." into tText
         break
      case "button1textsize"
         put "We want the font of the button to be a little larger, so select the Text tab of the property inspector (the last tab), and set the size of the button text to 18." into tText
         break
      case "message2"
         put "Now that we have the User Interface set up, it's time to add some code." into tText
         break
      case "button1scriptopen"
         put "Right click on the button and select 'Edit Script' from the menu to open the script editor." into tText
         break
      case "button1script"
         put "Type" & return & tab & "answer" && quote & "Hello World" & quote into tText
         put return & "and click 'Apply'" after tText
         break
      case "runtool1"
         put "Now test the code you have written. First, switch to run mode by clicking on the run mode tool in the Tools palette." into tText
         break
      case "check1click"
         put "Click on the 'Send' button to see the result" into tText
         break
      case "edittool2"
         put "Now switch back to edit mode to make some more changes to the app." into tText
         break
      case "field1props"
         put "Double click on the field to open up its property inspector." into tText
         break
      case "field1name"
         put "We're going to set the name of the text field so its contents can be referenced by the button script. Go to the first tab and change the name to newMessage" into tText
         break
      case "button1script2open"
         put "Right click on the button and select 'Edit Script' from the menu to open the script editor again." into tText
         break
      case "button1script2"
         put "Code allows your app to be flexible and interactive. Change the second line of the button script to read" into tText
         put return & "answer field" && quote & "newMessage" & quote after tText
         put return & "and click 'Apply'." after tText
         break
      case "runtool2"
         put "Now test this new code. First, switch to run mode by clicking on the run mode tool in the Tools palette." into tText
         break
      case "field1enter"
         put "Click on the field to enter text into it." into tText
         put return & "Notice that in edit mode, clicking on the field selects it and allows you to drag it around and change the size, whereas in run mode you can enter text." after tText
         break
      case "field1contents"
         put "Type a message into the field, and click the 'Send' button" into tText
         break
      case "message3"
         put "Understanding what happened: " into tText
         put return & "When you clicked the mouse, LiveCode sent the mouseUp message when you lifted your finger." after tText
         put return & "The command 'answer' tells LiveCode to pop up a message dialog." after tText
         put return & "First it showed the text 'Hello World'." after tText
         put return & "You changed it to show whatever text is in the field named 'newMessage'." after tText
         break
      case "edittool3"
         put "The iPhone app puts the message you send in a bubble. It's easier than you would think." into tText
         put return & "We just need to add a couple more controls to the stack. Switch back to edit mode to make some more changes to the app." after tText
         break
      case "image1"
         put "We're going to import the bubble image. Click on the file menu, and select Import As Control > Image File..." into tText
         put return & "Find the blue-bubble.png file in the code resources folder and click open." after tText
         break
      case "image1rect"
         put "Position the image as shown." into tText
         break
      case "field2"
         put "Drag out a label field from the tools palette" into tText
         break
      case "field2rect"
         put "Resize and position the label field over the image as shown" into tText
         break
      case "field2props"
         put "Double click on the label field to open up its property inspector" into tText
         break
      case "field2name"
         put "Set the name of the label field to messageLabel so it can be referenced by the button script." into tText
         break
      case "field2dontwrap"
         put "Uncheck the 'Don't wrap' option so that our message will display on multiple lines in the bubble." into tText
         break
      case "field2color"
         put "Select the color tab and set the foreground fill color to white. This corresponds to the text color of the label." into tText
         break
      case "field2align"
         put "Select the text formatting tab and set the text align of the label to left aligned." into tText
         break
      case "message4"
         put "Now we'll connect the label field with the message via the send button." into tText
         break
      case "button1script3open"
         put "Right click on the button and select 'Edit Script' from the menu to open the script editor again." into tText
         break
      case "button1script3"
         put "Change the second line of the button script to read" into tText
         put return & "set the text of field" && quote & "messageLabel" & quote && "to the text of field" && quote & "newMessage" & quote after tText
         put return & "and click 'Apply'." after tText
         break
      case "runtool3"
         put "Switch to run mode again to test your code." into tText
         break
      case "field1contents2"
         put "Type a message into the field, and click the 'Send' button" into tText
         break
      case "message5"
         put "Congratulations, you have just made your first app!" into tText
         break
   end switch
   return tText
end textForStep

on disableMenuBar
   disableStack "revMenuBar"
   enable menu "File"
end disableMenuBar

on disableToolsPalette
   dispatch "disableTools" to stack "revTools"
end disableToolsPalette

on enableToolsPalette
   dispatch "enableTools" to stack "revTools"
end enableToolsPalette

local sDisabled
on disableStack pStack
   repeat for each line tControl in the childControlIDs of this card of stack pStack
      if the enabled of control id tControl of this card of stack pStack then
         put true into sDisabled[pStack][tControl]
      end if
      disable control id tControl of this card of stack pStack
   end repeat
end disableStack

on enableStack pStack
   repeat for each key tControl in sDisabled[pStack]
      if sDisabled[pStack][tControl] is true then
         enable control id tControl of this card of stack pStack
      end if
      put false into sDisabled[pStack][tControl]
   end repeat
end enableStack

on endTutorial
   send "doEndTutorial" to me in 0 millisecs
end endTutorial

on doEndTutorial
   lock screen
   if there is a field "Message" then
      delete field "Message"
   end if
   if there is a button "Exit" then
      delete button "Exit"
   end if
   remove script of stack "revTutorial" from front
   enableToolsPalette
   enableStack "revMenuBar"
   
   put empty into sStep
   put empty into sStepNumber
   put empty into sUserStack
   put empty into sObjCount
   
   unlock screen
   close me
end doEndTutorial

on buildMenus
   buildFileMenu
   buildEditMenu
end buildMenus

command buildFileMenu
   local tFile
   put "(&New Mainstack" & return after tFile
   
   if sStep is not "stack" then
      put "(&New Substack of" && char 1 to 20 of the mainStack of the topStack & "/|New Substack" & return after tFile
   else
      put "(&New Substack" & return after tFile
   end if
   put "(&Open Stack.../O" & return after tFile
   put "(Open Recent File" & return after tFile
   put revIDEGetRecentPathsAsMenu() & return after tFile
   put "(&Close/W" & return after tFile
   put "(Close and Remove From Memor&y" & return after tFile
   put "-" & return after tFile
   
   put "(Import As Control" & return after tFile
   put tab & "Image File.../>" & return after tFile
   put tab & "Audio File..." & return after tFile
   put tab & "Video File..." & return after tFile
   put tab & "Text File..." & return after tFile
   put tab & "Snapshot of Screen" & return after tFile
   put tab & "Snapshot of Selected Object" & return after tFile
   put tab & "-" & return after tFile
   put tab & "All Images in Folder..." & return after tFile
   put tab & "All Audio Files in Folder..." & return after tFile
   
   put "(New Referenced Control" & return after tFile
   put tab & "Image File..." & return after tFile
   put tab & "Quicktime-Supported File..." & return after tFile
   put tab & "-" & return after tFile
   put tab & "All Images in Folder..." & return after tFile
   put "-" & return after tFile
   
   put "(&Save/S" & return after tFile
   put "(Save &As..." & return after tFile
   put "(Move S&ubstack to File..." & return after tFile
   put "(&Revert to Saved..." & return after tFile
   put "-" & return after tFile
   
   put "(Share This Stack..." & return after tFile
   put "-" & return after tFile
   
   put"(Standalone Application Settings..." & return after tFile
   put "(Save as Standalone Application..." & return after tFile
   put "-" & return after tFile
   
   put "(P&age Setup..." & return after tFile
   put "(&Print Card.../P" & return after tFile
   put "(Print Field..." & return after tFile
   put "-" & return after tFile
   
   ## EJB 2014-08-26
   ## [[Bug 12880]]
   if the platform is "Linux" then
      put "&Quit" & return after tFile
   else
      put "E&xit" & return after tFile
   end if
   
   set the text of menu "File" to tFile
   
   set the wholeMatches to false
   switch sStep
      case "stack"
         enable line lineOffset("New Mainstack", menu "File") of menu "File"
         break
      case "image1"
         enable line lineOffset("Import As Control", menu "File")  of menu "File"
         break
      default
         break
   end switch
   
end buildFileMenu

command buildEditMenu
   local tEdit
   
   local tObjectsLabel
   if word 1 of the selObj is "card" then
      put "Card" into tObjectsLabel
   else if word 1 of the selobj is not "stack" then
      put "Objects" into tObjectsLabel
   else
      put empty into tObjectsLabel
   end if
   
   local tSelectionLabel
   if the selectedImage is not empty then
      put "Image Selection" into tSelectionLabel
   else if false then
      put "Text" into tSelectionLabel
   else if true then
      put tObjectsLabel into tSelectionLabel
   else
      put empty into tSelectionLabel
   end if
   
   local tClipboardLabel
   switch the clipboard
      case "empty"
         put empty into tClipboardLabel
         break
         -- MW-2012-09-19: [[ Bug 9600 ]] Treat 'files' as 'text' clipboard type.
      case "text"
      case "files"
         if the selectedField is empty then
            put empty into tClipboardLabel
         else
            put "Text" into tClipboardLabel
         end if
         break
      case "objects"
         put "Objects" into tClipboardLabel
         break
      case "image"
         put "Image" into tClipboardLabel
         break
   end switch
   
   put "(&Undo/Z" & return after tEdit
   put "-" & return after tEdit
   put "(Cu&t" && tSelectionLabel & "/X|cut" & return after tEdit
   put "(&Copy" && tSelectionLabel & "/C|copy" & return after tEdit
   put "(&Paste"&& tClipboardLabel & "/V|paste" & return after tEdit
   put "(Paste &Unformatted/Cmd Shift Opt V" & return after tEdit
   put "(Clea&r" && tSelectionLabel & return after tEdit
   put "-" & return after tEdit
   put "(&Duplicate" && tObjectsLabel &"/D" & return after tEdit
   put "(&Replicate..." & return after tEdit
   put "-" & return after tEdit
   put "(Select All/A" & return after tEdit
   put "(Deselect All" & return after tEdit
   put "(In&vert Selection" & return after tEdit
   put "(Select Grouped Controls" & return after tEdit
   put "(Intersected Selections" & return after tEdit
   put "-" & return after tEdit
   put "(Find and Replace.../F" & return after tEdit
   put "-" & return after tEdit
   put "(Pre&ferences" after tEdit
   
   set the text of button "Edit" of stack "revMenuBar" to tEdit
   set the wholematches to false
   switch sStep
      case "graphic2"
         enable line lineOffset("Duplicate", menu "Edit") of menu "Edit"
         break
      default
         break
   end switch
end buildEditMenu

on closeStack
   if the short name of the target is "revTutorial" then
      set the destroyStack of stack "revTutorial" to true
      endTutorial
   end if
end closeStack

on idePropertyChanged pObject
   switch sStep
      case "stackrect"
         if pObject is sUserStack then
            if revTutorialRectIsApproximatelyRight("stack") then
               set the currentStep of me to "graphic1"
            end if
         end if
         break
      case "graphic1noline"
         if the lineSize of graphic 1 of sUserStack is 0 then
            if the selobj is not empty then
               set the currentStep of me to "graphic2"
            else
               set the currentStep of me to "graphic1select"
            end if
         end if
         break
      case "button1label"
         if the label of button 1 of sUserStack is "Send" then
            set the currentStep of me to "button1style"
         end if
         break
      case "button1style"
         if the style of button 1 of sUserStack is "transparent" then
            set the currentStep of me to "button1textsize"
         end if
         break
      case "button1textsize"
         if the textsize of button 1 of sUserStack is 18 then
            set the currentStep of me to "message2"
         end if
         break
      case "button1script"
         if revTutorialScriptIsApproximatelyRight("button1script") then
            set the currentStep of me to "runtool1"
         end if
         break
      case "field1name"
         if the short name of field 1 of sUserStack is "newMessage" then
            if "revNewScriptEditor" is in the openstacks then
               set the currentStep of me to "button1script2"
            else
               set the currentStep of me to "button1script2open"
            end if
         end if
         break
      case "button1script2"
         if revTutorialScriptIsApproximatelyRight("button1script2") then
            set the currentStep of me to "runtool2"
         end if
         break
      case "field2name"
         if the short name of field 2 of sUserStack is "messageLabel" then
            set the currentStep of me to "field2dontwrap"
         end if
         break
      case "field2dontwrap"
         if the dontwrap of field 2 of sUserStack is false then
            set the currentStep of me to "field2color"
         end if         
         break
      case "field2color"
         if revTutorialColorIsApproximatelyRight("field2color") then 
            set the currentStep of me to "field2align"
         end if         
         break
      case "field2align"
         if the textAlign of field 2 of sUserStack is "left" then
            set the currentStep of me to "message4"
         end if         
         break
      case "button1script3"
         if revTutorialScriptIsApproximatelyRight("button1script3") then
            set the currentStep of me to "runtool3"
         end if
         break
   end switch
   pass idePropertyChanged
end idePropertyChanged

on mouseUp pWhich
   local tObject
   put the long id of the target into tObject
   if tObject ends with sUserStack then
      
      switch sStep
         case "graphic1rect"
            if tObject begins with "graphic" and the number of tObject is 1 then
               if revTutorialRectIsApproximatelyRight("graphic1") then
                  set the currentStep of me to "graphic1props"
               end if
            end if
            break
         case "graphic2rect"
            if tObject begins with "graphic" and the number of tObject is 2 then
               if revTutorialRectIsApproximatelyRight("graphic2") then
                  set the currentStep of me to "field1"
               end if
            end if
            break
         case "field1rect"
            if tObject begins with "field" and the number of tObject is 1 then
               if revTutorialRectIsApproximatelyRight("field1") then
                  set the currentStep of me to "button1"
               end if
            end if
            break
         case "button1rect"
            if tObject begins with "button" and the number of tObject is 1 then
               if revTutorialRectIsApproximatelyRight("button1") then
                  set the currentStep of me to "button1props"
               end if
            end if
            break
         case "image1rect"
            if tObject begins with "image" and the number of tObject is 1 then
               if revTutorialRectIsApproximatelyRight("image1") then
                  set the currentStep of me to "field2"
               end if
            end if
            break
         case "check1click"
            if tObject begins with "button" and the number of tObject is 1 and pWhich is 1 then
               send "setStep edittool2" to me in 1 second
            end if
            break
         case "field1contents"
            if tObject begins with "button" and the number of tObject is 1 and pWhich is 1 then
               send "setStep message3" to me in 1 second
            end if
            break
         case "field2rect"
            if tObject begins with "field" and the number of tObject is 2 then
               if revTutorialRectIsApproximatelyRight("field2") then
                  set the currentStep of me to "field2props"
               end if
            end if
            break
         case "field1contents2"
            if tObject begins with "button" and the number of tObject is 1 and pWhich is 1 then
               send "setStep message5" to me in 1 second
            end if
            break
      end switch
   end if
   pass mouseUp
end mouseUp

on openField
   local tObject
   put the long id of the target into tObject
   switch sStep
      case "field1enter"
         if tObject begins with "field" and the number of tObject is 1 then
            set the currentStep of me to "field1contents"
         end if
         break
   end switch
   pass openField
end openField

on menuPick pWhich
   local tObject
   put the long id of the target into tObject
   
   if pWhich is "Edit Script" and tObject is the long id of button "standard" of stack "revMenuBar" then
      if sStep is "button1scriptopen" then
         send "setStep button1script" to me in 10 millisecs 
      else if sStep is "button1script2open" then
         send "setStep button1script2" to me in 10 millisecs 
      else if sStep is "button1script3open" then
         send "setStep button1script3" to me in 10 millisecs 
      end if
   end if
   pass menuPick
end menuPick

on mouseDoubleUp
   switch sStep
      case "graphic1props"
         if the long id of the target begins with "graphic" and the number of the target is 1 then
            set the currentStep of me to "graphic1noline"
            pass mouseDoubleUp
         end if
         break
      case "field1props"
         if the long id of the target begins with "field" and the number of the target is 1 then
            set the currentStep of me to "field1name"
            pass mouseDoubleUp
         end if
         break
      case "field2props"
         if the long id of the target begins with "field" and the number of the target is 2 then
            set the currentStep of me to "field2name"
            pass mouseDoubleUp
         end if
         break
   end switch
end mouseDoubleUp

on newStack
   if the short name of the target is "revTutorial" then
   else
      if sStep is "stack" then
         put the target into sUserStack
         revIDESubscribe "idePropertyChanged", sUserStack
         set the currentStep of me to "stackrect"
      end if
   end if
end newStack

on openCard
   if the long id of the owner of the target is sUserStack then
      copy group "guides" of me to the target
      set the topleft of it to "178,126"
      show group "guides" of sUserStack
      show graphic "stackguide" of sUserStack
   end if
   pass openCard
end openCard

on ideSelectedObjectChanged 
   local tSelObj
   put the selobj into tSelObj
   if sStep is "graphic1select" then
      if word 1 of tSelObj is "graphic" and the number of tSelObj is 1 then
         set the currentStep of me to "graphic2"
      end if
   end if
   pass ideSelectedObjectChanged
end ideSelectedObjectChanged

on ideNewControl pObject
   if the long id of pObject ends with sUserStack then
      revIDESubscribe "idePropertyChanged", pObject
      add 1 to sObjCount
      switch sStep
         case "graphic1"
            set the currentStep of me to "graphic1rect"
            break
         case "graphic2"
            set the currentStep of me to "graphic2rect"
            break
         case "button1"
            set the currentStep of me to "button1rect"
            break
         case "field1"
            set the currentStep of me to "field1rect"
            break
         case "image1"
            set the currentStep of me to "image1rect"
            break
         case "field2"
            set the currentStep of me to "field2rect"
            break
      end switch
      set the layer of pObject to sObjCount
   end if
   pass ideNewControl
end ideNewControl

on setRegions
   lock messages
   create invisible group "guides"
   set the dashes of the templateGraphic to "8,3"
   set the visible of the templateGraphic to false
   set the lockloc of the templateGraphic to true
   set the cantSelect of the templateGraphic to true
   create graphic "stackguide" in group "guides"
   set the rect of it to "1,1,361,581"
   
   create graphic "graphic1guide" in group "guides"
   set the rect of it to "1,1,361,48"
   
   create graphic "graphic2guide" in group "guides"
   set the rect of it to "0,546,361,581"
   
   create graphic "field1guide" in group "guides"
   set the rect of it to "18,552,286,576"
   
   create graphic "button1guide" in group "guides"
   set the rect of it to "294,550,356,576"
   
   create graphic "image1guide" in group "guides"
   set the rect of it to "177,62,347,126"
   
   create graphic "field2guide" in group "guides"
   set the rect of it to "186,70,324,120"
   
   reset the templateGraphic
   set the topleft of group "guides" to 0,0
   unlock messages
end setRegions

on newTool pTool
   if pTool is "browse" then
      if sStep is "runtool1" then
         set the currentStep of me to "check1click"
      else if sStep is "runtool2" then
         set the currentStep of me to "field1enter"
      else if sStep is "runtool3" then
         set the currentStep of me to "field1contents2"
      end if
   else if pTool is "pointer" then
      if sStep is "edittool1" then
         set the currentStep of me to "graphic1rect"
      else if sStep is "edittool2" then
         set the currentStep of me to "field1props"
      else if sStep is "edittool3" then
         set the currentStep of me to "image1"
      end if
   end if
end newTool

function revTutorialScriptIsApproximatelyRight pWhich
   local tScript
   switch pWhich
      case "button1script"
         put the script of button 1 of sUserStack into tScript
         if word 1 to -1 of line 1 of tScript is "on mouseUp" and word 1 to -1 of line 3 of tScript is "end mouseUp" then
            if word 1 of line 2 of tScript is "answer" then
               return true
            end if
         end if
         break
      case "button1script2"
         put the script of button 1 of sUserStack into tScript
         if word 1 to -1 of line 1 of tScript is "on mouseUp" and word 1 to -1 of line 3 of tScript is "end mouseUp" then
            if word 1 to -1 of line 2 of tScript is "answer field" && quote & "newMessage" & quote then
               return true
            end if
         end if
         break
      case "button1script3"
         put the script of button 1 of sUserStack into tScript
         if word 1 to -1 of line 1 of tScript is "on mouseUp" and word 1 to -1 of line 3 of tScript is "end mouseUp" then
            if word 1 to -1 of line 2 of tScript is ("set the text of field" && quote & "messageLabel" & quote && "to the text of field" && quote & "newMessage" & quote) then
               return true
            end if
         end if
         break
   end switch
   return false
end revTutorialScriptIsApproximatelyRight

function revTutorialColorIsApproximatelyRight pWhich
   switch pWhich
      case "field2color"
         if the foreColor of field 2 of sUserStack is "white" then
            return true
         end if
         repeat for each item tItem in the foreColor of field 2 of sUserStack
            if tItem is not a number or tItem < 240 then
               return false
            end if
         end repeat
         return true
         break
   end switch
end revTutorialColorIsApproximatelyRight


function revTutorialRectIsApproximatelyRight pWhich
   switch pWhich
      case "graphic1"
         return revTutorialRectsAreApproximatelyEqual(3, the rect of graphic 1 of sUserStack, the rect of graphic "graphic1guide" of sUserStack, true,true,true,false)
      case "graphic2"
         return revTutorialRectsAreApproximatelyEqual(3, the rect of graphic 2 of sUserStack, the rect of graphic "graphic2guide" of sUserStack, true,false,true,true)
      case "field1"
         return revTutorialRectsAreApproximatelyEqual(5, the rect of field 1 of sUserStack, the rect of graphic "field1guide" of sUserStack, false,false,false,false)
      case "button1"
         return revTutorialRectsAreApproximatelyEqual(5, the rect of button 1 of sUserStack, the rect of graphic "button1guide" of sUserStack, false,false,false,false)
      case "image1"
         return revTutorialRectsAreApproximatelyEqual(3, the rect of image 1 of sUserStack, the rect of graphic "image1guide" of sUserStack, false,false,false,false)
      case "field2"
         return revTutorialRectsAreApproximatelyEqual(3, the rect of field 2 of sUserStack, the rect of graphic "field2guide" of sUserStack, false,false,false,false)
      case "stack"
         local tStackRect
         put "0,0," & the width of sUserStack & "," & the height of sUserStack into tStackRect
         return revTutorialRectsAreApproximatelyEqual(3, tStackRect, the rect of graphic "stackguide" of sUserStack)
   end switch
   return false
end revTutorialRectIsApproximatelyRight

function revTutorialRectsAreApproximatelyEqual pTolerance, pRect, pTarget, pLeftOver, pTopOver, pRightOver, pBottomOver
   local tItemNo
   repeat with tItemNo = 1 to 4
      
      if tItemNo is 1 and pLeftOver is true and item 1 of pRect < 0 then
         next repeat
      else if tItemNo is 2 and pTopOver is true and item 2 of pRect < 0 then
         next repeat
      else if tItemNo is 3 and pRightOver is true and item 3 of pRect > the width of sUserStack then
         next repeat
      else if tItemNo is 4 and pBottomOver is true and item 4 of pRect > the height of sUserStack then
         next repeat
      end if
      
      if abs(item tItemNo of pRect - item tItemNo of pTarget) > pTolerance then
         return false
      end if
   end repeat
   return true
end revTutorialRectsAreApproximatelyEqual

