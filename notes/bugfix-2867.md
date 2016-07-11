# Ignore moveStack and resizeStack execution errors in script debug mode

Previously when in script debug mode an execution error in the context
of a moveStack or resizeStack handler would cause the IDE hang and 
occasionally crash. 
