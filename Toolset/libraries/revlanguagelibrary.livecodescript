script "revlanguagelibrary"
global gLanguage

on revLoadLibrary
answer "EE"
   if the target is me then
      initLanguage
   end if
end revLoadLibrary

on revUnloadLibrary

end revUnloadLibrary

on initLanguage pForce
   put the effective filename of this stack into tStackPath
   set the itemDel to slash
   put item 1 to -3 of tStackPath&"/resources" into tResourceFolder

   put the cLanguage_lang of stack "revpreferences" into tDefaultLang
   if tDefaultLang = empty then put "en" into tDefaultLang
   if(pForce = true or gLanguage[default_lang] <> tDefaultLang) then
      put tResourceFolder&"/langs/"&tDefaultLang&".json" into tLangsFilePath
      if(there is no file tLangsFilePath) then throw "No Language File"

      put jsonImport(textDecode(URL("file:"&tLangsFilePath),"UTF-8")) into gLanguage
      if(gLanguage is an array) then put tDefaultLang into gLanguage["default_lang"]
   end if
end initLanguage
