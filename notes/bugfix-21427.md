# Allow nesting of Data Grid Behaviors

A data grid group has a behavior of
`button id 1005 of stack "revDataGridLibrary"`

If a developer needed to insert handlers to override any of the
default DG behavior, they were unable to do so using another behavior.
Updated the initialization code to be able to handle one or more nested
behaviors between the group and the DG library.
