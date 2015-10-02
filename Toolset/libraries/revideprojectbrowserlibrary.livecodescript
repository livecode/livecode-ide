script "revIDEProjectBrowserLibrary"
/*
This library has been added as a stopgap in order to prevent errors which occur because
of interactions between the old project browser and binary stacks which otherwise could
only be fixed by forking the binary stack for the 8.0 IDE.
*/

function ideProjectBrowserSortOptions
   return ("Top to bottom" & return & "Bottom to top")
end ideProjectBrowserSortOptions

function ideProjectBrowserOrderGet
   return revIDEGetPreference ("ideProjectBrowser_sortOrder")
end ideProjectBrowserOrderGet

on ideProjectBrowserOrderSet pOrder
   revIDESetPreference "ideProjectBrowser_sortOrder", pOrder
end ideProjectBrowserOrderSet

function ideProjectBrowserShowThumbnailsGet
   return false
end ideProjectBrowserShowThumbnailsGet

on ideProjectBrowserShowThumbnailsSet

end ideProjectBrowserShowThumbnailsSet

function ideProjectBrowserShowGroupThumbnailsGet
      return false
end ideProjectBrowserShowGroupThumbnailsGet

on ideProjectBrowserShowGroupThumbnailsSet

end ideProjectBrowserShowGroupThumbnailsSet
