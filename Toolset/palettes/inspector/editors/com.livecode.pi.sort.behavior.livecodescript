script "com.livecode.pi.sort.behavior"
constant kEffectiveTextColor = "100,100,100"
global gRevLanguageNames

on editorInitialize
   set the editorMinWidth of me to 40
   set the editorMaxWidth of me to 0
   
   local tText, tOptions, tProcessedOptions
   put the editorOptions of me into tOptions
   set the itemdelimiter to "|"
   repeat for each line tLine in tOptions
      if gRevLanguageNames then
         delete item (the number of items of tLine - 1) of tLine
      else
         delete item 2 of tLine
      end if
      if tProcessedOptions is empty then
         put tLine into tProcessedOptions
      else
         put return & tLine after tProcessedOptions
      end if
   end repeat
   set the text of button "sortType" of me to tProcessedOptions
end editorInitialize

on editorUpdate
   lock screen
   local tSortType, tSortOrder, tEffective, tEnabled, tValue
   put the editorValue of me into tValue
   put word 1 of tValue into tSortType
   put word -1 of tValue into tSortOrder
   put the editorEnabled of me into tEnabled
   put the editorEffective of me into tEffective
   
   local tOptions
   put the editorOptions of me into tOptions
   
   lock messages
   local tLabel
   
   if gRevLanguageNames then
      put tSortType into tLabel
   else
      set the wholematches to false
      set the itemdelimiter to "|"
      
      repeat for each line tLine in tOptions
         if the number of items of tLine is 2 and \
               tSortType is item 2 of tLine then
            put item 1 of tLine into tLabel
            exit repeat
         else if tSortType is tLine then
            put tLine into tLabel
            exit repeat
         end if
      end repeat
   end if
   
   if tLabel is not empty then
      set the label of button "sortType" of me to tLabel
   else
      set the label of button "sortType" of me to tSortType
   end if
   
   set the label of button "sortOrder" of me to tSortOrder
   
   set the enabled of me to tEnabled
   if tEffective is true then
      set the textcolor of button "sortType" of me to kEffectiveTextColor
      set the textstyle["italic"] of button "sortType" of me to true
   else
      set the textcolor of button "sortType" of me to empty
      set the textstyle of button "sortType" of me to empty
   end if
   unlock messages
   unlock screen
end editorUpdate

constant kEditorPadding = 5
on editorResize
   lock screen
   lock messages
   local tRect
   put the rect of me into tRect
   local tWidth
   put the width of me / 2 into tWidth
   subtract kEditorPadding from tWidth
   local tButtonRect
   put tRect into tButtonRect
   put item 1 of tButtonRect + tWidth into item 3 of tButtonRect
   set the rect of button "sortType" of me to tButtonRect
   put tRect into tButtonRect
   put item 3 of tButtonRect - tWidth into item 1 of tButtonRect
   set the rect of button "sortOrder" of me to tButtonRect
   unlock messages
   unlock screen
end editorResize

on valueChanged
   local tOptions
   put the editorOptions of me into tOptions
   set the wholematches to false
   set the itemdelimiter to "|"
   repeat for each line tLine in tOptions
      if item 1 of tLine is the label of button "sortType" of me then
         set the editorValue of me to the last item of tLine \
               && the label of button "sortOrder" of me
         exit repeat
      end if
   end repeat
   updateProperty
end valueChanged
