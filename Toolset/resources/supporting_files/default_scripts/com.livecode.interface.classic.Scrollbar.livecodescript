script "com.livecode.interface.classic.Scrollbar"
local sStartValue
on mouseDown 
   --save the initial value
   put the thumbPos of me into sStartValue
end mouseDown

on scrollbarDrag newValue 
-- newValue contains the current thumbpos value 

end scrollbarDrag