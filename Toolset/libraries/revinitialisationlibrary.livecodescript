script "revinitialisationlibrary"
// A array that stores whether a library is loaded
// sLoadedLibraries["library name"] = true
local sLoadedLibraries

constant kLCLibraryPrefix = "com.livecode.script-library"

command revInternal__LoadLibrary pLibrary, pFullPath
   // Create the path to the library file. Assumption is made that the directory, file and stack name are all the same.
   //set the itemdel to "/"
   
   -- SN-2015-02-20: Linux uses case-sensitive filenames, so we
   --  follow the lower-case naming of the library names
   put toLower(pLibrary) into pLibrary
   
   if sLoadedLibraries[pLibrary] is not empty then
      return "Library" && pLibrary && "already loaded as" && sLoadedLibraries[pLibrary]
   end if
   
   local tStackName
   try
      if there is a stack pLibrary then
         put pLibrary into tStackName
      else if there is a stack (kLCLibraryPrefix & "." & pLibrary) then
         put kLCLibraryPrefix & "." & pLibrary into tStackName
      else if the environment begins with "development" then
         if there is not a stack pFullPath then
            throw "no file for library" && pLibrary
         end if
         
         put the name of stack pFullPath into tStackName
      end if
   catch tError
      write ("Error" && tError && "while loading stack:" && pLibrary) & return to stderr
      return "Error loading" && pLibrary
   end try
   
   send "revLoadLibrary" to stack tStackName   
   put tStackName into sLoadedLibraries[pLibrary]
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

command revInternal_SetCLASSPATH
   local tJarFiles, tFolder, tClasspath
   put specialFolderPath("resources") & "/Externals/JVM" into tFolder
   
   put files(tFolder) into tJarFiles
   filter tJarFiles with "*.jar"
   
   repeat for each line tJar in tJarFiles
      put tFolder & slash before tJar
      if tClasspath is empty then
         put tJar into tClasspath
      else
         put ":" & tJar after tClasspath
      end if
   end repeat
   
   put tClasspath into $CLASSPATH
end revInternal_SetCLASSPATH
