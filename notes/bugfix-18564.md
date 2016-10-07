# Remote debugger

The debugger library has been enhanced to allow remote debugging of
standalone applications. Include the Debugger inclusion in your
standalone and launch the standalone while the IDE is running. A dialog
will be presented asking if you wish to begin a remote debugger session.

Any breakpoints and watched variables present when building the
standalone will be initialised. When the debugger opens it is
possible to add more breakpoints by clicking in the gutter.

When the script being debugged has completed the debugger will close
those script tabs as it is not possible to remotely edit. The stacks
that were included in the standalone are not required to be open while
debugging remotely.
