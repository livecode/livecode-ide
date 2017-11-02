on foo
   switch tFoo
      case "foo"
         -- code
         break
      default
         -- code
         break
   end switch
   -- comment
end foo

on foo
   switch
      case tFoo begins with "foo"
         -- code
         break
      default
         -- code
         break
   end switch
   -- comment
end foo
