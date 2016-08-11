# Improve script only stack opening

Script only stacks will now be checked to determine if they are visible
after opening before editing their script in the script editor after
opening via the file menu and when opened via the system. This allows
script only stacks that generate their own user interface via script
in `preOpenStack` or `openStack` to not open into the script editor
by setting the visible of the stack to true in `openStack`.
