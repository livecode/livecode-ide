script "revinitialisationlibrary"
// A array that stores whether a library is loaded
// sLoadedLibraries["library name"] = true
local sLoadedLibraries

command revInternal__LoadLibrary pLibrary
   // Create the path to the library file. Assumption is made that the directory, file and stack name are all the same.
   //set the itemdel to "/"
   
   -- SN-2015-02-20: Linux uses case-sensitive filenames, so we
   --  follow the lower-case naming of the library names
   put toLower(pLibrary) into pLibrary
   
   if sLoadedLibraries[pLibrary] is not empty then
     return empty
   end if
   
   // AL-2015-02-20: [[ IDE Restructure ]] Look for libraries in the correct locations.
   if the environment begins with "development" then
      local tPaths
      
      local tToolsetPath
      put revEnvironmentToolsetPath() into tToolsetPath
      
      local tLibSuffix
      set the itemDelimiter to "."
      put the last item of pLibrary into tLibSuffix
      
      put merge("[[tToolsetPath]]/libraries/[[pLibrary]]") into tPaths[1]
      put merge("[[tToolsetPath]]/libraries/[[tLibSuffix]]/[[tLibSuffix]]") into tPaths[2]
      
      if not revEnvironmentIsInstalled() then
         local tRepoPath
         put revEnvironmentRepositoryPath() into tRepoPath
         
         put merge("[[tRepoPath]]/ide-support/[[pLibrary]]") into tPaths[3]
         put merge("[[tRepoPath]]/extensions/script-libraries/[[tLibSuffix]]/[[tLibSuffix]]") into tPaths[4]
         set the itemDelimiter to slash
         delete the last item of tRepoPath
         put merge("[[tRepoPath]]/extensions/script-libraries/[[tLibSuffix]]/[[tLibSuffix]]") into tPaths[5]
         put merge("[[tRepoPath]]/ide/libraries/[[tLibSuffix]]") into tPaths[6]
      end if
      
      local tLibraryPath
      local tIndex
      repeat with tIndex = 1 to the number of elements in tPaths
         local tExtension
         repeat for each word tExtension in "livecodescript livecode"
            if there is a file (tPaths[tIndex]& "." & tExtension) then
               put tPaths[tIndex]& "." & tExtension into tLibraryPath
               exit repeat
            end if
         end repeat
      end repeat
      
      set the itemDelimiter to comma
      
      if tLibraryPath is empty then
         return "no file for library" && pLibrary
      end if
      
      try
         // Get its name
         local tStackName
         put the name of stack tLibraryPath into tStackName
         send "revLoadLibrary" to stack tStackName
         put tStackName into sLoadedLibraries[pLibrary]
      catch tError
         return "Error while loading stack:" && tLibraryPath & return & tError
      end try
      
   else
      try
         send "revLoadLibrary" to stack pLibrary
      catch tError
         put "Error" && tError && "while loading stack:" && pLibrary into tError
         write tError to stderr
         return tError
      end try
   end if
   return empty
end revInternal__LoadLibrary

command revInternal__LoadIfLibrary pLibrary
   try
      if the revAvailableHandlers of stack pLibrary contains "revLoadLibrary" then
         send "revLoadLibrary" to stack pLibrary
         local tStackName
         put the name of stack pLibrary into tStackName
         put tStackName into sLoadedLibraries[pLibrary]
         return true
      end if
   end try
   delete stack pLibrary
   return false
end revInternal__LoadIfLibrary

command revInternal__UnloadLibrary pLibraryName
   // Check if the library is loaded
   if sLoadedLibraries[pLibraryName] is empty then
      return "Library not loaded"
   end if
   
   local tStackName
   put sLoadedLibraries[pLibraryName] into tStackName
   if there is not a stack tStackName then return "library not loaded"
   
   try
      // Request the library shuts down
      send "revUnloadLibrary" to stack tStackName
      
      delete variable sLoadedLibraries[pLibraryName]
      
      return true
   catch tError
      return "Error while unloading library. Library" && pLibraryName && "did not complete the reVUnloadLibrary request"
   end try
end revInternal__UnloadLibrary

function revInternal__ListLoadedLibraries
   local tLibs
   put the keys of sLoadedLibraries into tLibs
   sort tLibs
   return tLibs
end revInternal__ListLoadedLibraries

function revInternal__LoadedLibraryStackName pLibName
   return sLoadedLibraries[pLibName]
end revInternal__LoadedLibraryStackName

command revInternal__SetAppIcon pAppIcon
   global gRevAppIcon
   set the paintCompression to "png" -- match the engine
   put pAppIcon into gRevAppIcon
end revInternal__SetAppIcon

command revInternal__SetSmallAppIcon pSmallAppIcon
   global gRevSmallAppIcon
   set the paintCompression to "png" -- match the engine
   put pSmallAppIcon into gRevSmallAppIcon
end revInternal__SetSmallAppIcon

command revInternal_SetJAVA_HOME
   if $JAVA_HOME is empty then
      local tPath
      switch the platform
         case "MacOS"
            put word 1 to -1 of shell("/usr/libexec/java_home") into tPath
            break
         case "Linux"
            local tJAVAC
            put "/bin/javac" into tJAVAC
            put word 1 to -1 of shell("/usr/bin/env readlink -f /usr" & tJAVAC) into tPath
            if there is a file tPath and tPath ends with tJAVAC then
               set the itemDelimiter to slash
               delete item -2 to -1 of tPath
            end if
            break
      end switch
      if there is a folder tPath then
         put tPath into $JAVA_HOME
      end if
   end if
end revInternal_SetJAVA_HOME
