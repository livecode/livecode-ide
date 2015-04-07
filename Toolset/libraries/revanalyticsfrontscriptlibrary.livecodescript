script "revanaliticsfontscriptlibrary"
--------Analytics Library--------
# Traps various messages sending analytics calls

on openStack
   revAnalyticsScreenChanged the long ID of the target
   pass openStack
end openStack

on openCard
   revAnalyticsScreenChanged the long ID of the target
   pass openCard
end openCard

on resumeStack
   revAnalyticsScreenChanged the long ID of the target
   pass resumeStack
end resumeStack
