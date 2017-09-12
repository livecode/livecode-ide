repeat \
      forever
   -- code
end repeat

switch \
      tVar
   case "foo"
      -- code
      break
   case \
         "foo"
      -- code
      break
   default
      -- code
      break
end switch

try
   -- code
catch \
      tError
   -- code
end try

if something \
      then
   -- code
end if

put "foo" &\
      "bar"
