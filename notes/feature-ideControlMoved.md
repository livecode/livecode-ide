# ideControlMoved message

`ideControlMoved` has been added to the set of IDE messages to which other
objects can subscribe. `ideControlMoved pTarget` is dispatched to all
subscribers after the control `pTarget` is moved with the pointer tool
(i.e. in edit mode) in the IDE.