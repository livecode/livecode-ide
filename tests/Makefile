# This Makefile takes advantage of the fact that the engine's
# "tests/Makefile" already does pretty much everything required for
# running the IDE's test suite.  Rather than duplicating it, it can
# just be included with a few tweaks to its configuration.

# Only do livecodescript-based checks
ide-check: lcs-check
.DEFAULT: ide-check

# Override the default value of top_srcdir so that it points to the
# top of the engine repository.
top_srcdir ?= ../..

# Override the test runner
LCS_TESTRUNNER ?= ../tests/_testrunner.livecodescript

LCS_TESTENGINE ?= development

# Things have now been setup enough that the engine's test Makefile
# can perform the tests without any further configuration.
include $(top_srcdir)/tests/Makefile
