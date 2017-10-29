script "com.livecode.pi.androidsdk.behavior"
on editorInitialize
   set the editorExpandVertical of me to false
   set the editorMinWidth of me to 400
   set the editorMaxWidth of me to 0
end editorInitialize

on editorUpdate
   lock screen
   local tValue, tEffective, tEnabled
   put the editorValue of me into tValue
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   lock messages
   put tValue into field "Android SDK" of me
   set the enabled of field "Android SDK" of me to tEnabled
   if not tEnabled then
      set the enabled of button "ChooseAndroid" of me to false   
   end if
   unlock messages
   unlock screen
end editorUpdate

constant kControlGap = 5
on editorResize
   lock screen
   lock messages
   set the width of field "instructions" of me to \
         the width of me
   set the height of field "instructions" of me \
         to the formattedheight of field "instructions" of me
   set the topleft of field "instructions" of me to \
         the topleft of me
   
   set the top of field "Location Label" of me to \
         the bottom of field "instructions" of me + kControlGap
   set the left of field "Location Label" of me to \
         the left of me
   
   set the right of button "ChooseAndroid" of me to \
         the right of me
   set the top of button "ChooseAndroid" of me to \
         the bottom of field "Location Label" of me + kControlGap 
   
   set the width of field "Android SDK" of me to \
         the width of me - kControlGap - \
         the width of button "ChooseAndroid" of me
   set the left of field "Android SDK" of me to \
         the left of me
   set the top of field "Android SDK" of me to \
         the bottom of field "Location Label" of me + kControlGap
   
   set the top of button "Clear Android SDK" of me to \
         the top of field "Android SDK" of me + 2
   set the right of button "Clear Android SDK" of me to \
         the right of field "Android SDK" of me
   unlock messages
   unlock screen
end editorResize

on mouseUp
   local tTarget
   put the short name of the target into tTarget
   if tTarget is "ChooseAndroid" then
      answer folder "Please choose the location of your Android development SDK"
      if it is not empty then
         if revIDEDeployAndroidIsValidSDK(it) then
            set the editorValue of me to it
            updateProperty
         else
            answer error "The chosen folder is not a valid Android SDK. Please ensure you have installed it correctly, and enabled support for" && revIDEDeployAndroidRequiredSDK()
         end if
      end if
   else if tTarget is "Clear Android SDK" then
      set the editorValue of me to empty
      updateProperty
   end if
end mouseUp
