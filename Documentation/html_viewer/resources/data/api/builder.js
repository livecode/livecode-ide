{
		"display name":"LiveCode Builder",
		"name":"livecode_builder",
		"author":"LiveCode",
		"doc":[{
			"id":"1",
			"name":"lowercasestring",
			"display name":"LowercaseString",
			"type":"operator",
			"syntax":[
				"the lower of <Source>"
			],
			"display syntax":[
				"the lower of <i>Source</i>"
			],
			"associations":["com.livecode.string"],
			"summary":"Lowercases <Source>.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"<Source> with each of its chars lowercased."
			}],
			"description":"Uppercase letters, including special characters with diacritical marks, are converted to the lowercase equivalents. All other characters, including lowercase letters, numbers, punctuation, and special characters with no upper or lower case, are left unchanged.",
			"tags":["Strings"]
		},{
			"id":"2",
			"name":"concatenatestrings",
			"display name":"ConcatenateStrings",
			"type":"operator",
			"syntax":[
				"<Left> & <Right>"
			],
			"display syntax":[
				"<i>Left</i> & <i>Right</i>"
			],
			"associations":["com.livecode.string"],
			"summary":"Concatenates <Left> and <Right>.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"car\" & \"pet\" into tVar -- tVar contains \"carpet\""
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The result of concatenating <Left> and <Right>."
			}],
			"description":"The result consists of the chars of <Left> followed by those of <Right>.",
			"tags":["Strings"]
		},{
			"id":"3",
			"name":"putstringbefore",
			"display name":"PutStringBefore",
			"type":"statement",
			"syntax":[
				"put <Source> before <Target>"
			],
			"display syntax":[
				"put <i>Source</i> before <i>Target</i>"
			],
			"associations":["com.livecode.string"],
			"summary":"Prepends <Source> to <Target>.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string container."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"\" into tVar\nput \"abc\" before tVar -- tVar contains \"abc\"\nput \"lpha\" before char 2 of tVar\nput \"eti\" before char -1 of tVar -- tVar contains \"alphabetic\""
			}],
			"description":"Use to insert a string without replacement. Can be used either with a chunk expression to insert at a specified location, or without to prepend to the target string."
		},{
			"id":"4",
			"name":"stringisstring",
			"display name":"StringIsString",
			"type":"operator",
			"syntax":[
				"<Left> is <Right>"
			],
			"display syntax":[
				"<i>Left</i> is <i>Right</i>"
			],
			"associations":["com.livecode.string"],
			"summary":"Determines whether <Left> and <Right> are equal or not.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Left> is identical to <Right>."
			}],
			"description":"The ```is``` operator is case sensitive.",
			"tags":["Strings"]
		},{
			"id":"5",
			"name":"emptystring",
			"display name":"EmptyString",
			"type":"expression",
			"syntax":[
				"the empty string"
			],
			"display syntax":[
				"the empty string"
			],
			"associations":["com.livecode.string"],
			"summary":"Designates the string of length zero.",
			"examples":[{
				"script":"variable tVar as String\nvariable tCount as Number\nput the empty string into tVar\nput the number of chars in tVar into tCount -- tCount is 0"
			}],
			"description":"Use ```the empty string``` to initialise a string variable. The empty string is synonymous with the string literal \"\"",
			"tags":["Strings"]
		},{
			"id":"6",
			"name":"stringisgreaterthanstring",
			"display name":"StringIsGreaterThanString",
			"type":"operator",
			"syntax":[
				"<Left> &gt; <Right>"
			],
			"display syntax":[
				"<i>Left</i> &gt; <i>Right</i>"
			],
			"associations":["com.livecode.string"],
			"summary":"Determines whether <Left> is greater than <Right> under a char by char comparison",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Left> is greater than <Right>."
			}],
			"description":"<Left> is greater than <Right> if and only if <Left> and <Right> are not equal, and the unicode codepoint of the first char in <Left> that is not equal to the corresponding char in <Right> is of greater value.",
			"tags":["Strings"]
		},{
			"id":"7",
			"name":"uppercasestring",
			"display name":"UppercaseString",
			"type":"operator",
			"syntax":[
				"the upper of <Source>"
			],
			"display syntax":[
				"the upper of <i>Source</i>"
			],
			"associations":["com.livecode.string"],
			"summary":"Uppercases <Source>.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"<Source> with each of its chars uppercased."
			}],
			"description":"Lowercase letters, including special characters with diacritical marks, are converted to the uppercase equivalents. All other characters, including uppercase letters, numbers, punctuation, and special characters with no upper or lower case, are left unchanged.",
			"tags":["Strings"]
		},{
			"id":"8",
			"name":"putstringafter",
			"display name":"PutStringAfter",
			"type":"statement",
			"syntax":[
				"put <Source> after <Target>"
			],
			"display syntax":[
				"put <i>Source</i> after <i>Target</i>"
			],
			"associations":["com.livecode.string"],
			"summary":"Appends <Source> to <Target>.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string container."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"\" into tVar\nput \"rent\" after tVar -- tVar contains \"rent\"\nput \"placeme\" after char 2 of tVar -- tVar contains \"replacement\""
			}],
			"description":"Use to insert a string without replacement. Can be used either with a chunk expression to insert at a specified location, or without to append to the target string.",
			"tags":["Strings"]
		},{
			"id":"9",
			"name":"stringislessthanstring",
			"display name":"StringIsLessThanString",
			"type":"operator",
			"syntax":[
				"<Left> &lt; <Right>"
			],
			"display syntax":[
				"<i>Left</i> &lt; <i>Right</i>"
			],
			"associations":["com.livecode.string"],
			"summary":"Determines whether <Left> is less than <Right> under a char by char comparison",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Left> is less than <Right>"
			}],
			"description":"<Left> is greater than <Right> if and only if <Left> and <Right> are not equal, and the unicode codepoint of the first char in <Left> that is not equal to the corresponding char in <Right> is of greater value.",
			"tags":["Strings"]
		},{
			"id":"10",
			"name":"replacestring",
			"display name":"ReplaceString",
			"type":"statement",
			"syntax":[
				"replace <Pattern> with <Replacement> in <Target>"
			],
			"display syntax":[
				"replace <i>Pattern</i> with <i>Replacement</i> in <i>Target</i>"
			],
			"associations":["com.livecode.string"],
			"summary":"Replaces occurrences of <Pattern> within <Target> in <Replacement>\nSource:An expression which evaluates to a string.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string container."
			},{
				"name":"Replacement",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tString as String\nput \"purple\" into tString\nreplace \"p\" with \"t\" in tString -- tString is \"turtle\""
			}],
			"description":"Replaces each occurrence of the string <Pattern> in <Target> with <Replacement>.",
			"tags":["Strings"]
		},{
			"id":"11",
			"name":"stringisnotstring",
			"display name":"StringIsNotString",
			"type":"operator",
			"syntax":[
				"<Left> is not <Right>"
			],
			"display syntax":[
				"<i>Left</i> is not <i>Right</i>"
			],
			"associations":["com.livecode.string"],
			"summary":"Determines whether <Left> and <Right> are equal or not.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Left> is not identical to <Right>."
			}],
			"description":"The ```is not``` operator is case sensitive.",
			"tags":["Strings"]
		},{
			"id":"12",
			"name":"concatenatestringswithspace",
			"display name":"ConcatenateStringsWithSpace",
			"type":"operator",
			"syntax":[
				"<Left> && <Right>"
			],
			"display syntax":[
				"<i>Left</i> && <i>Right</i>"
			],
			"associations":["com.livecode.string"],
			"summary":"Concatenates <Left> and <Right> with a space between.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"This\" && \"is\" && \"a\" && \"sentence.\" into tVar -- tVar contains \"This is a sentence.\""
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The result of concatenating <Left> and <Right> with a space between."
			}],
			"description":"The result consists of the chars of <Left> followed by a space, and then the chars of <Right>.",
			"tags":["Strings"]
		},{
			"id":"13",
			"name":"com.livecode.string",
			"display name":"com.livecode.string",
			"type":"library",
			"display syntax":[
				"com.livecode.string"
			],
			"description":"This library consists of the operations on strings included in the standard library of LiveCode Builder."
		},{
			"id":"14",
			"name":"writetostream",
			"display name":"WriteToStream",
			"type":"statement",
			"syntax":[
				"write <Buffer> to <Destination>"
			],
			"display syntax":[
				"write <i>Buffer</i> to <i>Destination</i>"
			],
			"associations":["com.livecode.stream"],
			"summary":"Write data to a stream.\nStream:An expression that evaluates to a stream.",
			"parameters":[{
				"name":"Buffer",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to binary data."
			}],
			"description":"Write some data to a stream.  If not all of the data can be written,\nfails with an error.\n\n>*Warning:* If the stream is able to accept only part of the data,\n>some streams will write that part of the data and discard the rest.\n>This may cause loss of data.",
			"tags":["IO"]
		},{
			"id":"15",
			"name":"defaulterrorstream",
			"display name":"DefaultErrorStream",
			"type":"expression",
			"syntax":[
				"the error stream"
			],
			"display syntax":[
				"the error stream"
			],
			"associations":["com.livecode.stream"],
			"summary":"Default error stream.",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The default error stream."
			}],
			"description":"The default error stream for diagnostic information.\n\nIn command-line programs, this is usually used to display error\nmessages.  In server programs, data output through this stream may be\nstored in the system log, depending on the server configuration.",
			"tags":["IO"]
		},{
			"id":"16",
			"name":"defaultoutputstream",
			"display name":"DefaultOutputStream",
			"type":"expression",
			"syntax":[
				"the output stream"
			],
			"display syntax":[
				"the output stream"
			],
			"associations":["com.livecode.stream"],
			"summary":"Default output stream.",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The default output stream."
			}],
			"description":"The default output stream for output from the program.\n\nIn command-line programs, this is usually used to output the results\nof running the program.  In CGI programs running on servers, this is\nusually used to output the data to be sent to the client."
		},{
			"id":"17",
			"name":"com.livecode.stream",
			"display name":"com.livecode.stream",
			"type":"library",
			"display syntax":[
				"com.livecode.stream"
			],
			"description":"This module specifies the syntax definitions and bindings for\nstream input and output operations in modular LiveCode."
		},{
			"id":"18",
			"name":"firstcharof",
			"display name":"FirstCharOf",
			"type":"operator",
			"syntax":[
				"the first char of <Target>"
			],
			"display syntax":[
				"the first char of <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Designates the first char in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"char\" into tVar\n\nvariable tFirst as String\nput the last char of tVar into tFirst -- tFirst contains \"c\""
			}],
			"description":"Either locates the first char for use as the target container of another operation, or evaluates the first char as the source of another operation.\n\n>*Note:* It is an error if <Target> is empty.",
			"tags":["Strings"]
		},{
			"id":"19",
			"name":"deletesingletoncharof",
			"display name":"DeleteSingletonCharOf",
			"type":"statement",
			"syntax":[
				"delete char <Index> of <Target>"
			],
			"display syntax":[
				"delete char <i>Index</i> of <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Deletes the char at index <Index> in <Target>.",
			"parameters":[{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A string container."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"thorough\" into tVar\ndelete char 3 of tVar -- tVar contains \"through\""
			}],
			"description":"Replaces the char at the given index with the empty string.\n\n>*Note:* It is an error if <Index> is out of range.",
			"tags":["Strings"]
		},{
			"id":"20",
			"name":"deletelastcharof",
			"display name":"DeleteLastCharOf",
			"type":"statement",
			"syntax":[
				"delete the last char of <Target>"
			],
			"display syntax":[
				"delete the last char of <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Deletes the last char in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A string container."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"deadliness\" into tVar\ndelete the last char of tVar -- tVar contains \"deadlines\""
			}],
			"description":"Replaces the last char in <Target> with the empty string.\n\n>*Note:* It is an error if <Target> is the empty string.",
			"tags":["Strings"]
		},{
			"id":"21",
			"name":"charoffsetafter",
			"display name":"CharOffsetAfter",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of <Needle> after <After> in <Target>"
			],
			"display syntax":[
				"the ( first | last ) offset of <i>Needle</i> after <i>After</i> in <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Finds the first or last occurrence of <Needle> after a specified index in <Target>",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"After",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of Target."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput the offset of \"nse\" after 4 in \"nonsense\" into tVar -- tVar contains 2"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the offset of <Needle> after <After> in <Target>."
			}],
			"description":"The first (respectively last) offset of <Needle> in <Target> is number of chars between the first char of the substring of <Target> beginning at char <After> + 1, and the first (respectively last) occurrence of <Needle> in the substring. If neither first or last is specified, then the first offset is found. If <Needle> does not occur in the given substring of <Target>, then the output is 0.",
			"tags":["Strings"]
		},{
			"id":"22",
			"name":"charoffset",
			"display name":"CharOffset",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of <Needle> in <Target>"
			],
			"display syntax":[
				"the ( first | last ) offset of <i>Needle</i> in <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Finds the first or last occurrence of <Needle> within <Target>",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput the first offset of \"art\" in \"cartoon\" into tVar -- tVar contains 2"
			},{
				"script":"variable tVar as Number\nvariable tFilePath as String\nput \"/Users/user/Documents/file.txt\" into tFilePath\nput the last offset of \"/\" in tFilePath into tVar\n\nvariable tFileName as String\nput char 1 to tVar of tFilePath into tFileName -- tVar contains \"file.txt\""
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the offset of <Needle> in <Target>."
			}],
			"description":"The first (respectively last) offset of <Needle> in <Target> is number of chars between the first char of <Target> and the first (respectively last) occurrence of <Needle>. If neither first or last is specified, then the first offset is found. If <Needle> does not occur in <Target>, then the output is 0.",
			"tags":["Strings"]
		},{
			"id":"23",
			"name":"com.livecode.char",
			"display name":"com.livecode.char",
			"type":"library",
			"display syntax":[
				"com.livecode.char"
			],
			"description":"This library consists of the operations on chars included in the standard library of LiveCode Builder."
		},{
			"id":"24",
			"name":"newlinecharacter",
			"display name":"NewLineCharacter",
			"type":"expression",
			"syntax":[
				"newline"
			],
			"display syntax":[
				"newline"
			],
			"associations":["com.livecode.char"],
			"summary":"The new line character",
			"examples":[{
				"script":"variable tList as List\npush \"line 1\" onto tList\npush \"line 2\" onto tList\npush \"line 3\" onto tList\n\nvariable tLines as String\ncombine tList with newline into tLines -- tLines has 3 lines"
			}],
			"description":"Use the <newline> constant to add new lines to a string variable.",
			"tags":["Strings"]
		},{
			"id":"25",
			"name":"deleterangecharof",
			"display name":"DeleteRangeCharOf",
			"type":"statement",
			"syntax":[
				"delete char <Start> to <Finish> of <Target>"
			],
			"display syntax":[
				"delete char <i>Start</i> to <i>Finish</i> of <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Deletes the chars between indices <Start> and <Finish> in <Target>.",
			"parameters":[{
				"name":"Start",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Finish",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A string container."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"surround\" into tVar\ndelete char 2 to 4 of tVar -- tVar contains \"sound\""
			}],
			"description":"Replaces the chars between the given indices with the empty string.\n\n>*Note:* It is an error if either <Start> or <Finish> are out of range.",
			"tags":["Strings"]
		},{
			"id":"26",
			"name":"rangecharof",
			"display name":"RangeCharOf",
			"type":"operator",
			"syntax":[
				"char <Start> to <Finish> of <Target>"
			],
			"display syntax":[
				"char <i>Start</i> to <i>Finish</i> of <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Designates the chars between indices <Start> and <Finish> in <Target>.",
			"parameters":[{
				"name":"Start",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Finish",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"put tChars into char 5 to 10 of tString // Locates chars 5 to 10 of tString and replace them with tChars"
			},{
				"script":"get char 5 to 10 of tString // Evaluates chars 5 to 10"
			}],
			"description":"Either locates the chars between the given indices for use as the target container of another operation, or evaluates the chars at the given indices as the source of another operation.\n\n>*Note:* It is an error if either <Start> or <Finish> are out of range.",
			"tags":["Strings"]
		},{
			"id":"27",
			"name":"stringbeginswithstring",
			"display name":"StringBeginsWithString",
			"type":"operator",
			"syntax":[
				"<Source> begins with <Prefix>"
			],
			"display syntax":[
				"<i>Source</i> begins with <i>Prefix</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Determines whether <Source> begins with <Prefix>",
			"parameters":[{
				"name":"Prefix",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as String\nvariable tResult as String\nput \"abcde\" into tVar\nif tVar begins with \"abc\" then\n\tput \"success\" into tResult\nend if\t"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Source> begins with <Prefix>."
			}],
			"description":"<Source> begins with <Prefix> if and only if the chars of <Prefix> occur as an initial subsequence of the chars of <Source>.\n\n>*Note:* Since \"\" is an initial substring of every string, every string begins with the empty string."
		},{
			"id":"28",
			"name":"countcharsof",
			"display name":"CountCharsOf",
			"type":"operator",
			"syntax":[
				"the number of chars in <Target>"
			],
			"display syntax":[
				"the number of chars in <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Counts the number of chars in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as Number\nvariable tSource as String\nput \"hello\" into tString\nput the number of chars in tString into tVar\n\nvariable tString as String\nput the empty string into tString\t\nrepeat tVar times\n\tput \"a\" after tString\nend repeat\n\n// tString contains \"aaaaa\""
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The number of chars in <Target>."
			}],
			"description":">*Note:* The number of chars returns the number of codeunits of the target string. It does not perform any grapheme boundary analysis.",
			"tags":["Strings"]
		},{
			"id":"29",
			"name":"deletefirstcharof",
			"display name":"DeleteFirstCharOf",
			"type":"statement",
			"syntax":[
				"delete the first char of <Target>"
			],
			"display syntax":[
				"delete the first char of <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Deletes the first char in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A string container."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"seven\" into tVar\ndelete the first char of tVar -- tVar contains \"even\""
			}],
			"description":"Replaces the first char in <Target> with the empty string.\n\n>*Note:* It is an error if <Target> is the empty string.",
			"tags":["Strings"]
		},{
			"id":"30",
			"name":"lastcharof",
			"display name":"LastCharOf",
			"type":"operator",
			"syntax":[
				"the last char of <Target>"
			],
			"display syntax":[
				"the last char of <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Designates the last char in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"char\" into tVar\n\nvariable tLast as String\nput the last char of tVar into tLast -- tLast contains \"r\""
			}],
			"description":"Either locates the last char for use as the target container of another operation, or evaluates the last char as the source of another operation.\n\n>*Note:* It is an error if <Target> is empty.",
			"tags":["Strings"]
		},{
			"id":"31",
			"name":"charoffsetbefore",
			"display name":"CharOffsetBefore",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of <Needle> before <Before> in <Target>"
			],
			"display syntax":[
				"the ( first | last ) offset of <i>Needle</i> before <i>Before</i> in <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Finds the first or last occurrence of <Needle> before a specified index in <Target>.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Before",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of Target."
			}],
			"examples":[{
				"script":"variable tVar as Number\nvariable tLastDot as Number\nvariable tAddress as String\nvariable tTLD as String\nput \"http://www.livecode.com/index.html\" into tAddress\nput the last offset of \".\" in tAddress into tLastDot\nput the offset of \".\" before tLastDot in tAddress into tVar\nput char tVar + 1 to tVar + 3 of tAddress into tTLD -- tTLD contains \"com\""
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the offset of <Needle> before <Before> in <Target>."
			}],
			"description":"The first (respectively last) offset of <Needle> in <Target> is number of chars between the first char of <Target>, and the first (respectively last) occurrence of <Needle> in the substring of <Target> ending at char <Before> - 1. If neither first or last is specified, then the last offset is found. If <Needle> does not occur in the given substring of <Target>, then the output is 0.",
			"tags":["Strings"]
		},{
			"id":"32",
			"name":"stringendswithstring",
			"display name":"StringEndsWithString",
			"type":"operator",
			"syntax":[
				"<Source> ends with <Suffix>"
			],
			"display syntax":[
				"<i>Source</i> ends with <i>Suffix</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Determines whether <Source> ends with <Suffix>",
			"parameters":[{
				"name":"Suffix",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as String\nvariable tResult as String\nput \"abcde\" into tVar\nif tVar ends with \"cde\" then\n\tput \"success\" into tResult\nend if\t"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Source> ends with <Suffix>."
			}],
			"description":"<Source> ends with <Suffix> if and only if the chars of <Suffix> occur as a final subsequence of the chars of <Source>.\n\n>*Note:* Since \"\" is a final substring of every string, every string ends with the empty string.",
			"tags":["Strings"]
		},{
			"id":"33",
			"name":"codeofchar",
			"display name":"CodeOfChar",
			"type":"operator",
			"syntax":[
				"the code of <Target>"
			],
			"display syntax":[
				"the code of <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Get the numeric value of a single char",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A string containing one character"
			}],
			"description":"Returns the Unicode codepoint index of a single character.",
			"tags":["Strings"]
		},{
			"id":"34",
			"name":"charisinstring",
			"display name":"CharIsInString",
			"type":"operator",
			"syntax":[
				"<Needle> is in <Source>"
			],
			"display syntax":[
				"<i>Needle</i> is in <i>Source</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Determines whether <Needle> is in <Target>.\nTarget:An expression which evaluates to a string.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a char."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Needle> is among the chars of <Target>, and false otherwise."
			}],
			"description":">*Note:* It is an error if <Needle> evaluates to a string consisting of more than one char.",
			"tags":["Strings"]
		},{
			"id":"35",
			"name":"singletoncharof",
			"display name":"SingletonCharOf",
			"type":"operator",
			"syntax":[
				"char <Index> of <Target>"
			],
			"display syntax":[
				"char <i>Index</i> of <i>Target</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Designates the char at index <Index> in <Target>.",
			"parameters":[{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"put the empty string into char 5 of tString // Locates char 5 and removes it from tString"
			},{
				"script":"get char 5 of tString // Evaluates char 5"
			}],
			"description":"Either locates the char at the given index for use as the target container of another operation, or evaluates the char at the given index as the source of another operation.\n\n>*Note:* It is an error if <Index> is out of range.",
			"tags":["Strings"]
		},{
			"id":"36",
			"name":"repeatforeachchar",
			"display name":"RepeatForEachChar",
			"type":"iterator",
			"syntax":[
				"char <Iterand>"
			],
			"display syntax":[
				"char <i>Iterand</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Repeat over the chars of a string",
			"parameters":[{
				"name":"Iterand",
				"type":"",
				"refparam":"false",
				"description":"A string container."
			}],
			"examples":[{
				"script":"variable tString as String\nput \"stressed\" into tString\n\nvariable tReversed as String\nvariable tChar as String\nput \"\" into tReversed\nrepeat for each char tChar in tString\n\tput tChar before tReversed\nend repeat\n\n    // tReversed is \"desserts\""
			}],
			"description":"Use repeat for each to perform an operation on each char of a string. On each iteration, the <Iterand> will contain the next char of the string being iterated over.",
			"tags":["Strings","Control structures"]
		},{
			"id":"37",
			"name":"containschars",
			"display name":"ContainsChars",
			"type":"operator",
			"syntax":[
				"<Source> contains <Needle>"
			],
			"display syntax":[
				"<i>Source</i> contains <i>Needle</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Determines whether <Source> contains <Needle>.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Source> contains <Needle>."
			}],
			"description":"<Source> contains <Needle> if and only if the chars of <Needle> occur as a subsequence of the chars of <Source>.\n\n>*Note:* Since \"\" is a substring of every string, every string contains the empty string.",
			"tags":["Strings"]
		},{
			"id":"38",
			"name":"charwithcode",
			"display name":"CharWithCode",
			"type":"operator",
			"syntax":[
				"the char with code <Index>"
			],
			"display syntax":[
				"the char with code <i>Index</i>"
			],
			"associations":["com.livecode.char"],
			"summary":"Create a 1-char string from a number",
			"parameters":[{
				"name":"Value",
				"type":"",
				"refparam":"false",
				"description":"A Unicode codepoint index"
			}],
			"description":"Returns a string containing one Unicode character created using the\ngiven value.",
			"tags":["Strings"]
		},{
			"id":"39",
			"name":"combinelistwith",
			"display name":"CombineListWith",
			"type":"statement",
			"syntax":[
				"combine <Target> with <Delimiter>"
			],
			"display syntax":[
				"combine <i>Target</i> with <i>Delimiter</i>"
			],
			"associations":["com.livecode.typeconvert"],
			"summary":"Combines the list of strings in <Target>, using <Delimiter>\n                as the delimiter. ",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a list container."
			},{
				"name":"Delimiter",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a string."
			}],
			"examples":[{
				"script":"variable tDigits as List\nput [1,2,3,4,5,6,7,8,9] into tDigits\n\nvariable tString as String\n    combine tDigits with \"|\" \n    put the result into tString // tString contains \"1|2|3|4|5|6|7|8|9\""
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"The combined string."
			}],
			"description":"Use the combine command to convert a list into a string representation of the list.\n\n>*Note:* The list *must* consist entirely of string elements, otherwise the combine command will throw an error."
		},{
			"id":"40",
			"name":"com.livecode.typeconvert",
			"display name":"com.livecode.typeconvert",
			"type":"library",
			"display syntax":[
				"com.livecode.typeconvert"
			],
			"description":"This library consists of the operations for performing complex type conversion in LiveCode Builder."
		},{
			"id":"41",
			"name":"stringsplitby",
			"display name":"StringSplitBy",
			"type":"statement",
			"syntax":[
				"split <Target> by <Delimiter>"
			],
			"display syntax":[
				"split <i>Target</i> by <i>Delimiter</i>"
			],
			"associations":["com.livecode.typeconvert"],
			"summary":"Splits the string in <Target> into a list of strings, using <Delimiter>\n                as the delimiter.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a string container."
			},{
				"name":"Delimiter",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as String\n    put \"first,second,third,fourth,fifth\" into tVar\n    variable tSplit as List\n    split tVar by \",\"\n    put the result into tSplit\n    put element 1 of tSplit into tFirstElement // tFirstElement contains \"first\""
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"The list of strings."
			}],
			"description":"Use the split command to convert a string representation of a list into a genuine (ordered) list.",
			"tags":["Type conversion"]
		},{
			"id":"42",
			"name":"localdate",
			"display name":"LocalDate",
			"type":"expression",
			"syntax":[
				"the local date"
			],
			"display syntax":[
				"the local date"
			],
			"associations":["com.livecode.date"],
			"summary":"The local gregorian date",
			"examples":[{
				"script":"variable tDateTime as List\nput the local date into tDateTime\n\nvariable tDayOfMonth as Number\nput tDateTime[3] into tDayOfMonth"
			}],
			"description":"Returns the local date as a list of six numeric components.  The\nelements of the list are:\n\n* The year\n* The month (1-12)\n* The day of the month (1-31, depending on the month)\n* The hour (0-23)\n* The minute (0-59)\n* The second (0-59)"
		},{
			"id":"43",
			"name":"com.livecode.date",
			"display name":"com.livecode.date",
			"type":"library",
			"display syntax":[
				"com.livecode.date"
			],
			"description":"This library provides low-level system functionality for modular\nLiveCode programs."
		},{
			"id":"44",
			"name":"universaltime",
			"display name":"UniversalTime",
			"type":"expression",
			"syntax":[
				"the universal time"
			],
			"display syntax":[
				"the universal time"
			],
			"associations":["com.livecode.date"],
			"summary":"The seconds",
			"examples":[{
				"script":"variable tTime as real\nput the universal time into tTime"
			}],
			"description":"Returns the current universal time relative to the start of the UNIX epoch - 1st\nJanuary 1970 in seconds.",
			"tags":["Date and time"]
		},{
			"id":"45",
			"name":"endswithbytes",
			"display name":"EndsWithBytes",
			"type":"operator",
			"syntax":[
				"<Target> ends with <Needle>"
			],
			"display syntax":[
				"<i>Target</i> ends with <i>Needle</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Determines whether <Target> ends with <Needle>.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if the bytes of <Needle> occur as a final subsequence of the bytes of <Target>, and false otherwise."
			}],
			"description":">*Note:* Since the empty data is a final subsequence of every sequence of bytes, every sequence of bytes ends with the empty data.",
			"tags":["Binary"]
		},{
			"id":"46",
			"name":"byteoffset",
			"display name":"ByteOffset",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of <Needle> in <Target>"
			],
			"display syntax":[
				"the ( first | last ) offset of <i>Needle</i> in <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Finds the first or last occurrence of <Needle> within <Target>",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the offset of <Needle> in <Target>."
			}],
			"description":"The first (respectively last) offset of <Needle> in <Target> is number of bytes between the first byte of <Target> and the first (respectively last) occurrence of <Needle>. If neither first or last is specified, then the first offset is found. If <Needle> does not occur in <Target>, then the output is 0.",
			"tags":["Binary"]
		},{
			"id":"47",
			"name":"singletonbyteof",
			"display name":"SingletonByteOf",
			"type":"operator",
			"syntax":[
				"byte <Index> of <Target>"
			],
			"display syntax":[
				"byte <i>Index</i> of <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Designates the byte of data at index <Index> in <Target>.",
			"parameters":[{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"description":"Either locates the byte at the given index for use as the target container of another operation, or evaluates the byte at the given index as the source of another operation.\n\n>*Note:* It is an error if <Index> is out of range.",
			"tags":["Binary"]
		},{
			"id":"48",
			"name":"bytewithcode",
			"display name":"ByteWithCode",
			"type":"operator",
			"syntax":[
				"the byte with code <Value>"
			],
			"display syntax":[
				"the byte with code <i>Value</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Create a 1-byte data value from a number",
			"parameters":[{
				"name":"Value",
				"type":"",
				"refparam":"false",
				"description":"The value for the new data value"
			}],
			"description":"Returns a byte of binary data, created using the given value.  The\n<Value> must be between 0 and 255 (inclusive).",
			"tags":["Binary"]
		},{
			"id":"49",
			"name":"deletesingletonbyteof",
			"display name":"DeleteSingletonByteOf",
			"type":"statement",
			"syntax":[
				"delete byte <Index> of <Target>"
			],
			"display syntax":[
				"delete byte <i>Index</i> of <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Deletes the byte of data at index <Index> in <Target>.",
			"parameters":[{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A container of binary data."
			}],
			"description":"Replaces the byte at the given index with the empty data.\n\n>*Note:* It is an error if <Index> is out of range.",
			"tags":["Binary"]
		},{
			"id":"50",
			"name":"com.livecode.byte",
			"display name":"com.livecode.byte",
			"type":"library",
			"display syntax":[
				"com.livecode.byte"
			],
			"description":"This library consists of the operations on bytes included in the standard library of LiveCode Builder."
		},{
			"id":"51",
			"name":"repeatforeachbyte",
			"display name":"RepeatForEachByte",
			"type":"iterator",
			"syntax":[
				"byte <Iterand>"
			],
			"display syntax":[
				"byte <i>Iterand</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Repeat over the bytes of some data",
			"parameters":[{
				"name":"Iterand",
				"type":"",
				"refparam":"false",
				"description":"A container of binary data."
			}],
			"description":"Use repeat for each to perform an operation on each byte of some data. On each iteration, the <Iterand> will contain the next char of the string being iterated over.",
			"tags":["Binary","Control structures"]
		},{
			"id":"52",
			"name":"deleterangebyteof",
			"display name":"DeleteRangeByteOf",
			"type":"statement",
			"syntax":[
				"delete byte <Start> to <Finish> of <Target>"
			],
			"display syntax":[
				"delete byte <i>Start</i> to <i>Finish</i> of <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Deletes the bytes of data between indices <Start> and <Finish> in <Target>.",
			"parameters":[{
				"name":"Start",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Finish",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A container of binary data."
			}],
			"description":"Replaces the bytes between the given indices with the empty data.\n\n>*Note:* It is an error if either <Start> or <Finish> are out of range.",
			"tags":["Binary"]
		},{
			"id":"53",
			"name":"byteoffsetafter",
			"display name":"ByteOffsetAfter",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of <Needle> after <After> in <Target>"
			],
			"display syntax":[
				"the ( first | last ) offset of <i>Needle</i> after <i>After</i> in <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Finds the first or last occurrence of <Needle> after a specified index in <Target>",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"After",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of Target."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the offset of <Needle> after index <After> in <Target>."
			}],
			"description":"The first (respectively last) offset of <Needle> in <Target> is number of bytes between byte <After> of <Target> and the first (respectively last) occurrence of <Needle> after <After>. If neither first or last is specified, then the first offset is found. If <Needle> does not occur after <After> in <Target>, then the output is 0.",
			"tags":["Binary"]
		},{
			"id":"54",
			"name":"randombytes",
			"display name":"RandomBytes",
			"type":"operator",
			"syntax":[
				"<Count> random bytes"
			],
			"display syntax":[
				"<i>Count</i> random bytes"
			],
			"associations":["com.livecode.byte"],
			"summary":"Generate random data",
			"parameters":[{
				"name":"Count",
				"type":"",
				"refparam":"false",
				"description":"Expression evaluating to the number of bytes to generate"
			}],
			"description":"Generates the requested number of bytes of cryptographic-quality\nrandom data."
		},{
			"id":"55",
			"name":"countbytesof",
			"display name":"CountBytesOf",
			"type":"operator",
			"syntax":[
				"the number of bytes in <Target>"
			],
			"display syntax":[
				"the number of bytes in <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Counts the number of bytes in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The number of bytes in <Target>"
			}],
			"tags":["Binary"]
		},{
			"id":"56",
			"name":"rangebyteof",
			"display name":"RangeByteOf",
			"type":"operator",
			"syntax":[
				"byte <Start> to <Finish> of <Target>"
			],
			"display syntax":[
				"byte <i>Start</i> to <i>Finish</i> of <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Designates the bytes of data between indices <Start> and <Finish> in <Target>.",
			"parameters":[{
				"name":"Start",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Finish",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"description":"Either locates the bytes between the given indices for use as the target container of another operation, or evaluates the bytes at the given indices as the source of another operation.\n\n>*Note:* It is an error if either <Start> or <Finish> are out of range.",
			"tags":["Binary"]
		},{
			"id":"57",
			"name":"beginswithbytes",
			"display name":"BeginsWithBytes",
			"type":"operator",
			"syntax":[
				"<Target> begins with <Needle>"
			],
			"display syntax":[
				"<i>Target</i> begins with <i>Needle</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Determines whether <Target> begins with <Needle>.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if the bytes of <Needle> occur as an initial subsequence of the bytes of <Target>, and false otherwise."
			}],
			"description":">*Note:* Since the empty data is an initial subsequence of every sequence of bytes, every sequence of bytes begins with the empty data.",
			"tags":["Binary"]
		},{
			"id":"58",
			"name":"containsbytes",
			"display name":"ContainsBytes",
			"type":"operator",
			"syntax":[
				"<Target> contains <Needle>"
			],
			"display syntax":[
				"<i>Target</i> contains <i>Needle</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Determines whether <Needle> contains <Target>.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if the bytes of <Needle> occur as a subsequence of the bytes of <Target>, and false otherwise."
			}],
			"description":">*Note:* Since the empty data is a subsequence of every sequence of bytes, every sequence of bytes contains the empty data.",
			"tags":["Binary"]
		},{
			"id":"59",
			"name":"lastbyteof",
			"display name":"LastByteOf",
			"type":"operator",
			"syntax":[
				"the last byte of <Target>"
			],
			"display syntax":[
				"the last byte of <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Designates the first byte of data in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"description":"Either locates the first byte for use as the target container of another operation, or evaluates the first byte as the source of another operation.\n\n>*Note:* It is an error if <Target> is empty.",
			"tags":["Binary"]
		},{
			"id":"60",
			"name":"byteoffsetbefore",
			"display name":"ByteOffsetBefore",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of <Needle> before <Before> in <Target>"
			],
			"display syntax":[
				"the ( first | last ) offset of <i>Needle</i> before <i>Before</i> in <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Finds the first or last occurrence of <Needle> before a specified index in <Target>.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Before",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of Target."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the offset of <Needle> before index <Before> in <Target>."
			}],
			"description":"The first (respectively last) offset of <Needle> in <Target> is number of bytes between the first byte of <Target> and the first (respectively last) occurrence of <Needle> before <Before>. If neither first or last is specified, then the last offset is found. If <Needle> does not occur before <Before> in <Target>, then the output is 0.",
			"tags":["Binary"]
		},{
			"id":"61",
			"name":"deletelastbyteof",
			"display name":"DeleteLastByteOf",
			"type":"statement",
			"syntax":[
				"delete the last byte of <Target>"
			],
			"display syntax":[
				"delete the last byte of <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Deletes the last byte in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A binary data container."
			}],
			"description":"Replaces the last byte in <Target> with the empty data.\n\n>*Note:* It is an error if <Target> is the empty data.",
			"tags":["Binary"]
		},{
			"id":"62",
			"name":"firstbyteof",
			"display name":"FirstByteOf",
			"type":"operator",
			"syntax":[
				"the first byte of <Target>"
			],
			"display syntax":[
				"the first byte of <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Designates the first byte of data in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"description":"Either locates the first byte for use as the target container of another operation, or evaluates the first byte as the source of another operation.\n\n>*Note:* It is an error if <Target> is empty.",
			"tags":["Binary"]
		},{
			"id":"63",
			"name":"deletefirstbyteof",
			"display name":"DeleteFirstByteOf",
			"type":"statement",
			"syntax":[
				"delete the first byte of <Target>"
			],
			"display syntax":[
				"delete the first byte of <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Deletes the first byte in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A binary data container."
			}],
			"description":"Replaces the first byte in <Target> with the empty data.\n\n>*Note:* It is an error if <Target> is the empty data.",
			"tags":["Binary"]
		},{
			"id":"64",
			"name":"codeofbyte",
			"display name":"CodeOfByte",
			"type":"operator",
			"syntax":[
				"the code of <Target>"
			],
			"display syntax":[
				"the code of <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Get the numeric value of a single byte.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A 1-byte binary data value."
			}],
			"description":"Returns the numeric representation of a single byte of binary data.",
			"tags":["Binary"]
		},{
			"id":"65",
			"name":"byteisindata",
			"display name":"ByteIsInData",
			"type":"operator",
			"syntax":[
				"<Needle> is in <Target>"
			],
			"display syntax":[
				"<i>Needle</i> is in <i>Target</i>"
			],
			"associations":["com.livecode.byte"],
			"summary":"Determines whether <Needle> is in <Target>.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a single byte of binary data."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Needle> is among the bytes of <Target>, and false otherwise."
			}],
			"description":">*Note:* It is an error if <Needle> evaluates to data consisting of more than one byte.",
			"tags":["Binary"]
		},{
			"id":"66",
			"name":"com.livecode.logic",
			"display name":"com.livecode.logic",
			"type":"library",
			"display syntax":[
				"com.livecode.logic"
			],
			"description":"This library consists of the logical operations included in the standard library of LiveCode Builder."
		},{
			"id":"67",
			"name":"booleanisequaltoboolean",
			"display name":"BooleanIsEqualToBoolean",
			"type":"operator",
			"syntax":[
				"<Left> is <Right>"
			],
			"display syntax":[
				"<i>Left</i> is <i>Right</i>"
			],
			"associations":["com.livecode.logic"],
			"summary":"Determines whether <Left> and <Right> are equal or not.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a boolean value."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a boolean value."
			}],
			"examples":[{
				"script":"variable tBool is bool\nput true is true into tBool -- tBool is true"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Left> evaluates to the same value as <Right>."
			}],
			"tags":["Logic"]
		},{
			"id":"68",
			"name":"booleanformattedasstring",
			"display name":"BooleanFormattedAsString",
			"type":"operator",
			"syntax":[
				"<Operand> formatted as string"
			],
			"display syntax":[
				"<i>Operand</i> formatted as string"
			],
			"associations":["com.livecode.logic"],
			"summary":"Formats a boolean value as a string",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a boolean value."
			}],
			"examples":[{
				"script":"variable tString as String\nvariable tBool as Boolean\nput (false is not not true) is false into tBool\nput tBool formatted as string into tString -- tString contains \"true\""
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"\"true\" or \"false\""
			}],
			"description":"Use <BooleanFormattedAsString> when you want to manipulate a boolean value as text."
		},{
			"id":"69",
			"name":"logicnot",
			"display name":"LogicNot",
			"type":"operator",
			"syntax":[
				"not <Operand>"
			],
			"display syntax":[
				"not <i>Operand</i>"
			],
			"associations":["com.livecode.logic"],
			"summary":"Returns the boolean-logical value of the expression 'not <Operand>'",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a boolean value"
			}],
			"examples":[{
				"script":"variable tBool is bool\nput not not not not true into tBool is true"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"If the operand expression evaluates to true, the value of the expression is false.\n            Otherwise, the value of the expression is true."
			}],
			"tags":["Logic"]
		},{
			"id":"70",
			"name":"booleanisnotequaltoboolean",
			"display name":"BooleanIsNotEqualToBoolean",
			"type":"operator",
			"syntax":[
				"<Left> is not <Right>"
			],
			"display syntax":[
				"<i>Left</i> is not <i>Right</i>"
			],
			"associations":["com.livecode.logic"],
			"summary":"Determines whether <Left> and <Right> are equal or not.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a boolean value."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a boolean value."
			}],
			"examples":[{
				"script":"variable tBool is bool\nput true is not false into tBool -- tBool is true"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Left> evaluates to the opposite boolean value as <Right>."
			}],
			"tags":["Logic"]
		},{
			"id":"71",
			"name":"formatbooleanasstring",
			"display name":"FormatBooleanAsString",
			"type":"statement",
			"syntax":[
				"format <Operand> as string"
			],
			"display syntax":[
				"format <i>Operand</i> as string"
			],
			"associations":["com.livecode.logic"],
			"summary":"Formats a boolean value as a string",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a boolean value."
			}],
			"examples":[{
				"script":"variable tVar as String\nparse 1 = 0 as String\nput the result into tVar\nput \"e\" into char 3 of tVar -- tVar is \"tree\""
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"\"true\" or \"false\""
			}],
			"description":"Use <FormatBooleanAsString> when you want to manipulate a boolean value as text."
		},{
			"id":"72",
			"name":"stringparsedasboolean",
			"display name":"StringParsedAsBoolean",
			"type":"operator",
			"syntax":[
				"<Operand> parsed as boolean"
			],
			"display syntax":[
				"<i>Operand</i> parsed as boolean"
			],
			"associations":["com.livecode.logic"],
			"summary":"Parses a string as a boolean value",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a string."
			}],
			"examples":[{
				"script":"variable tString as String\nvariable tBool as optional Boolean\nput \"false\" into tString\nput tString parsed as boolean into tBool -- tBool contains false"
			},{
				"script":"variable tBool as optional Boolean\nput \"flase\" parsed as boolean into tBool -- tBool is nothing"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"true or false"
			}],
			"description":"Use <StringParsedAsBoolean> when you want to determine if a string contains \"true\" or \"false\"\n\n>*Note:* Only the strings \"true\" and \"false\" will parse to give a boolean value. Any other input will cause an error to be thrown."
		},{
			"id":"73",
			"name":"parsestringasboolean",
			"display name":"ParseStringAsBoolean",
			"type":"statement",
			"syntax":[
				"parse <Operand> as boolean"
			],
			"display syntax":[
				"parse <i>Operand</i> as boolean"
			],
			"associations":["com.livecode.logic"],
			"summary":"Parses a string as a boolean value",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a string."
			}],
			"examples":[{
				"script":"variable tString as String\nvariable tBool as optional Boolean\ncombine [\"f\", \"a\", \"l\", \"s\" \"e\"] with \"\" into tString\nput tString parsed as boolean into tBool -- tBool contains false"
			},{
				"script":"variable tResult as String\nparse \"sdfsdf\" as Boolean\nif the result is nothing then\n\tput \"not a valid boolean\" into tResult\nend if"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"true or false"
			}]
		},{
			"id":"74",
			"name":"isnotundefined",
			"display name":"IsNotUndefined",
			"type":"operator",
			"syntax":[
				"deprecate with message Use 'is not nothing' instead"
			],
			"display syntax":[
				"deprecate with message Use 'is not nothing' instead"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is defined or not.\nTarget:Any expression",
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if the given expression <Target> is defined, and false otherwise."
			}],
			"description":">*Note:* The <IsNotUndefined> operator is deprecated. Please use <IsNotNothing|is not nothing> instead.",
			"references":{
				"operator":["IsNotNothing"]
			}
		},{
			"id":"75",
			"name":"isastring",
			"display name":"IsAString",
			"type":"operator",
			"syntax":[
				"<Target> is a string"
			],
			"display syntax":[
				"<i>Target</i> is a string"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is a string or not.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"Any expression"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if the given expression <Target> is a string, and false if not."
			}]
		},{
			"id":"76",
			"name":"isnotnothing",
			"display name":"IsNotNothing",
			"type":"operator",
			"syntax":[
				"<Target> is not nothing"
			],
			"display syntax":[
				"<i>Target</i> is not nothing"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is nothing or not.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"Any expression"
			}],
			"examples":[{
				"script":"public handler CanBeNumber(in pString as String) returns Boolean\n    variable tNum as optional Number\n    put pString parsed as number into tNum\n    return tNum is not nothing\nend handler"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns false if the given expression <Target> is nothing, and true otherwise."
			}],
			"description":"Use the <IsNotNothing> operator to test if operators or handlers have returned anything."
		},{
			"id":"77",
			"name":"isadata",
			"display name":"IsAData",
			"type":"operator",
			"syntax":[
				"<Target> is a data"
			],
			"display syntax":[
				"<i>Target</i> is a data"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is data or not.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"Any expression"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if the given expression <Target> is data, and false if not."
			}]
		},{
			"id":"78",
			"name":"isaboolean",
			"display name":"IsABoolean",
			"type":"operator",
			"syntax":[
				"<Target> is a boolean"
			],
			"display syntax":[
				"<i>Target</i> is a boolean"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is a boolean or not.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"Any expression"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if the given expression <Target> is a boolean, and false if not."
			}]
		},{
			"id":"79",
			"name":"com.livecode.type",
			"display name":"com.livecode.type",
			"type":"library",
			"display syntax":[
				"com.livecode.type"
			],
			"description":"This library consists of the general operations on types provided by the standard library of LiveCode Builder."
		},{
			"id":"80",
			"name":"isundefined",
			"display name":"IsUndefined",
			"type":"operator",
			"syntax":[
				"deprecate with message Use 'is nothing' instead"
			],
			"display syntax":[
				"deprecate with message Use 'is nothing' instead"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is defined or not.\nTarget:Any expression",
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns false if the given expression <Target> is defined, and true otherwise"
			}],
			"description":">*Note:* The <IsUndefined> operator is deprecated. Please use <IsNothing|is nothing> instead.",
			"references":{
				"operator":["IsNothing"]
			}
		},{
			"id":"81",
			"name":"isalist",
			"display name":"IsAList",
			"type":"operator",
			"syntax":[
				"<Target> is a list"
			],
			"display syntax":[
				"<i>Target</i> is a list"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is a list or not.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"Any expression"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if the given expression <Target> is a list, and false if not."
			}]
		},{
			"id":"82",
			"name":"isanarray",
			"display name":"IsAnArray",
			"type":"operator",
			"syntax":[
				"<Target> is an array"
			],
			"display syntax":[
				"<i>Target</i> is an array"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is an array or not.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"Any expression"
			}]
		},{
			"id":"83",
			"name":"isempty",
			"display name":"IsEmpty",
			"type":"operator",
			"syntax":[
				"<Target> is empty"
			],
			"display syntax":[
				"<i>Target</i> is empty"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is empty or not.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"Any expression"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if the given expression <Target> evaluates to the empty value of that type, and false otherwise."
			}]
		},{
			"id":"84",
			"name":"isdefined",
			"display name":"IsDefined",
			"type":"operator",
			"syntax":[
				"deprecate with message Use 'is not nothing' instead"
			],
			"display syntax":[
				"deprecate with message Use 'is not nothing' instead"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is defined or not.\nTarget:Any expression",
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if the given expression <Target> is defined, and false if not."
			}],
			"description":">*Note:* The <IsDefined> operator is deprecated. Please use <IsNotNothing|is not nothing> instead.",
			"references":{
				"operator":["IsNotNothing"]
			}
		},{
			"id":"85",
			"name":"isnotempty",
			"display name":"IsNotEmpty",
			"type":"operator",
			"syntax":[
				"<Target> is not empty"
			],
			"display syntax":[
				"<i>Target</i> is not empty"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is empty or not.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"Any expression"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns false if the given expression <Target> evaluates to the empty value of that type, and true otherwise."
			}]
		},{
			"id":"86",
			"name":"isnothing",
			"display name":"IsNothing",
			"type":"operator",
			"syntax":[
				"<Target> is nothing"
			],
			"display syntax":[
				"<i>Target</i> is nothing"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is nothing or not.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"Any expression"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if the given expression <Target> is nothing, and false otherwise."
			}],
			"description":"Use the <IsNothing> operator to test if operators or handlers have returned anything."
		},{
			"id":"87",
			"name":"isnotdefined",
			"display name":"IsNotDefined",
			"type":"operator",
			"syntax":[
				"deprecate with message Use 'is nothing' instead"
			],
			"display syntax":[
				"deprecate with message Use 'is nothing' instead"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is defined or not.\nTarget:Any expression",
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns false if the given expression <Target> is defined, and true if not."
			}],
			"description":">*Note:* The <IsNotDefined> operator is deprecated. Please use <IsNothing|is nothing> instead.",
			"references":{
				"operator":["IsNothing"]
			}
		},{
			"id":"88",
			"name":"isanumber",
			"display name":"IsANumber",
			"type":"operator",
			"syntax":[
				"<Target> is a number"
			],
			"display syntax":[
				"<i>Target</i> is a number"
			],
			"associations":["com.livecode.type"],
			"summary":"Determines whether <Target> is a number or not.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"Any expression"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if the given expression <Target> is a number, and false if not."
			}]
		},{
			"id":"89",
			"name":"listofstringparsedaslistofnumber",
			"display name":"ListOfStringParsedAsListOfNumber",
			"type":"operator",
			"syntax":[
				"<Operand> parsed as list of number"
			],
			"display syntax":[
				"<i>Operand</i> parsed as list of number"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Parses a list of strings as a list of numbers",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a list of strings."
			}],
			"examples":[{
				"script":"variable tListOfString as List\nvariable tListOfNum as List\nsplit \"1,2,3,4\" by \",\" into tListOfString\nput tListOfString parsed as list of number into tNum -- tListOfNum contains [ 1, 2, 3, 4 ]"
			},{
				"script":"variable tList as List\nput [\"1\", \"b\", \"3\"] parsed as list of number into tList\n\nvariable tElt as Number\nrepeat with tElt from 1 up to the number of elements in tList\n\tif tList[tElt] is nothing then\n\t\tput 0 into element tElt of tList\n\tend if\nend repeat\n\n// tList contains [ 1, 0, 3 ]"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"<Operand> parsed as a list of numbers."
			}]
		},{
			"id":"90",
			"name":"plusunaryoperator",
			"display name":"PlusUnaryOperator",
			"type":"operator",
			"syntax":[
				"+ <Operand>"
			],
			"display syntax":[
				"+ <i>Operand</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Unary plus operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput +5 into tVar -- tVar contains 5"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The result of evaluating <Operand>."
			}],
			"description":"The unary plus operator is a no-op on the predefined numeric types.",
			"tags":["Math"]
		},{
			"id":"91",
			"name":"numberformattedasstring",
			"display name":"NumberFormattedAsString",
			"type":"operator",
			"syntax":[
				"<Operand> formatted as string"
			],
			"display syntax":[
				"<i>Operand</i> formatted as string"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Formats a numeric value as a string",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tString as String\nvariable tNum as Number\nput 5 into tNum\nput tNum formatted as string into tString -- tString contains \"5\""
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"<Operand> formatted as a string."
			}],
			"description":"Use <NumberFormattedAsString> when you want to manipulate a numeric value as text."
		},{
			"id":"92",
			"name":"plusoperator",
			"display name":"PlusOperator",
			"type":"operator",
			"syntax":[
				"<Left> + <Right>"
			],
			"display syntax":[
				"<i>Left</i> + <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Binary plus operator.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput 5 + 4 + 3 into tVar -- tVar contains 12"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The result of adding the numbers <Left> and <Right>."
			}],
			"tags":["Math"]
		},{
			"id":"93",
			"name":"minusunaryoperator",
			"display name":"MinusUnaryOperator",
			"type":"operator",
			"syntax":[
				"- <Operand>"
			],
			"display syntax":[
				"- <i>Operand</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Unary minus operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput -(5 + 4) into tVar -- tVar contains -9"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The negated result of evaluating <Operand>."
			}],
			"tags":["Math"]
		},{
			"id":"94",
			"name":"com.livecode.arithmetic",
			"display name":"com.livecode.arithmetic",
			"type":"library",
			"display syntax":[
				"com.livecode.arithmetic"
			],
			"description":"This library consists of the basic arithmetic operations of standard library of LiveCode Builder."
		},{
			"id":"95",
			"name":"addnumberto",
			"display name":"AddNumberTo",
			"type":"statement",
			"syntax":[
				"add <Value> to <Target>"
			],
			"display syntax":[
				"add <i>Value</i> to <i>Target</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Adds <Value> to <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a numeric container."
			},{
				"name":"Value",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"    variable tVar as Number\n    put 2 into tVar\n    add 10 to tVar -- tVar contains 12"
			}],
			"description":"Adds the number <Value> to <Target>.\n\n>*Note:* It is a syntax error if <Target> does not evaluate to a variable.",
			"tags":["Math"]
		},{
			"id":"96",
			"name":"subtractnumberfrom",
			"display name":"SubtractNumberFrom",
			"type":"statement",
			"syntax":[
				"subtract <Value> from <Target>"
			],
			"display syntax":[
				"subtract <i>Value</i> from <i>Target</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Subtracts <Value> from <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a numeric variable."
			},{
				"name":"Value",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as real\nput 10 into tVar\nsubtract 2.5 from tVar -- tVar contains 7.5"
			}],
			"description":"Subtracts the number <Value> from <Target>.\n\n>*Note:* It is a syntax error if <Target> does not evaluate to a variable.",
			"tags":["Math"]
		},{
			"id":"97",
			"name":"numberislessthannumber",
			"display name":"NumberIsLessThanNumber",
			"type":"operator",
			"syntax":[
				"<Left> &lt; <Right>"
			],
			"display syntax":[
				"<i>Left</i> &lt; <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Less than relation.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Left> is less than <Right>, and false otherwise."
			}],
			"tags":["Math"]
		},{
			"id":"98",
			"name":"numberisequaltonumber",
			"display name":"NumberIsEqualToNumber",
			"type":"operator",
			"syntax":[
				"<Left> = <Right>"
			],
			"display syntax":[
				"<i>Left</i> = <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Equal to relation.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Left> is equal to <Right>, and false otherwise."
			}],
			"tags":["Math"]
		},{
			"id":"99",
			"name":"dividenumberby",
			"display name":"DivideNumberBy",
			"type":"statement",
			"syntax":[
				"divide <Target> by <Value>"
			],
			"display syntax":[
				"divide <i>Target</i> by <i>Value</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Divides <Target> by <Value>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a numeric variable."
			},{
				"name":"Value",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar\nput 3 into tVar\ndivide tVar by 2 -- tVar contains 1.5"
			}],
			"description":"Divides the number <Target> by <Value>.\n\n>*Note:* It is a syntax error if <Target> does not evaluate to a variable.",
			"tags":["Math"]
		},{
			"id":"100",
			"name":"numberisgreaterthanorequaltonumber",
			"display name":"NumberIsGreaterThanOrEqualToNumber",
			"type":"operator",
			"syntax":[
				"<Left> &gt;= <Right>"
			],
			"display syntax":[
				"<i>Left</i> &gt;= <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Greater than or equal to relation.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Left> is greater than or equal to <Right>, and false otherwise."
			}]
		},{
			"id":"101",
			"name":"numberislessthanorequaltonumber",
			"display name":"NumberIsLessThanOrEqualToNumber",
			"type":"operator",
			"syntax":[
				"<Left> &lt;= <Right>"
			],
			"display syntax":[
				"<i>Left</i> &lt;= <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Less than or equal to relation.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Left> is less than or equal to <Right>, and false otherwise."
			}],
			"tags":["Math"]
		},{
			"id":"102",
			"name":"overoperator",
			"display name":"OverOperator",
			"type":"operator",
			"syntax":[
				"<Left> / <Right>"
			],
			"display syntax":[
				"<i>Left</i> / <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Binary division operator.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput 3 / 5 into tVar -- tVar contains 0.6"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The result of dividing the number <Left> by <Right>."
			}],
			"tags":["Math"]
		},{
			"id":"103",
			"name":"numberisnotnumber",
			"display name":"NumberIsNotNumber",
			"type":"operator",
			"syntax":[
				"<Left> is not <Right>"
			],
			"display syntax":[
				"<i>Left</i> is not <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Determines if <Left> is not <Right>.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Left> is not equal to <Right>, and false otherwise."
			}],
			"description":"Returns the opposite of the <NumberIsNumber> operator.",
			"references":{
				"operator":["NumberIsNumber"]
			},
			"tags":["Math"]
		},{
			"id":"104",
			"name":"modoperator",
			"display name":"ModOperator",
			"type":"operator",
			"syntax":[
				"<Left> mod <Right>"
			],
			"display syntax":[
				"<i>Left</i> mod <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Mod operator.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput 4^((7 - 1)/2) mod 7 into tVar -- tVar contains 1"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"<Left> mod <Right>."
			}],
			"description":"Returns the remainder on dividing <Left> by <Right>"
		},{
			"id":"105",
			"name":"parsestringasnumber",
			"display name":"ParseStringAsNumber",
			"type":"statement",
			"syntax":[
				"parse <Operand> as number"
			],
			"display syntax":[
				"parse <i>Operand</i> as number"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Parses a string as an number",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a string."
			}],
			"examples":[{
				"script":"variable tString as String\nput \"5.6\" into tString\nparse tString as Number -- the result is 5.6"
			},{
				"script":"variable tResult as String\nvariable tNum as optional Number\nparse \"aaaa\" as Number\n\nif the result is nothing then\n\tput \"unable to parse string\" into tResult\nend if"
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"<Operand> parsed as a number, or nothing."
			}],
			"description":"Use <ParseStringAsNumber> when you want to interpret text numerically. The result is nothing if parsing was not possible."
		},{
			"id":"106",
			"name":"parselistofstringaslistofnumber",
			"display name":"ParseListOfStringAsListOfNumber",
			"type":"statement",
			"syntax":[
				"parse <Operand> as list of number"
			],
			"display syntax":[
				"parse <i>Operand</i> as list of number"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Parses a list of strings as a list of numbers",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a list of strings."
			}],
			"examples":[{
				"script":"variable tListOfString as List\nvariable tListOfNum as List\nsplit \"1,2,3,4\" by \",\" into tListOfString\nparse tListOfString as list of number -- the result contains [ 1, 2, 3, 4 ]"
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"<Operand> parsed as a list of numbers."
			}],
			"description":"Use <ParseListOfStringAsListOfNumber> when you want to interpret pieces of text numerically. If the input list contains elements which cannot be parsed as numbers, the corresponding element will be nothing.\n\n*Note:* It is an error if any element of <Operand> is not a string."
		},{
			"id":"107",
			"name":"minusoperator",
			"display name":"MinusOperator",
			"type":"operator",
			"syntax":[
				"<Left> - <Right>"
			],
			"display syntax":[
				"<i>Left</i> - <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Binary minus operator.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput 5 - 3 - 1 into tVar -- tVar contains 1"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The result of subtracting the number <Right> from <Left>."
			}],
			"tags":["Math"]
		},{
			"id":"108",
			"name":"wrapoperator",
			"display name":"WrapOperator",
			"type":"operator",
			"syntax":[
				"<Left> wrap <Right>"
			],
			"display syntax":[
				"<i>Left</i> wrap <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Wrap operator.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput 5 wrap 3 into tVar -- tVar contains 2"
			},{
				"script":"variable tVar as Number\nput -3 wrap 3 into tVar -- tVar contains -3"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"If x >= 0, then x wrap y returns ((x-1) mod abs(y)) + 1.\n\t\t\tIf x < 0, then x wrap y returns -((x-1) mod abs(y)) + 1."
			}],
			"description":"Use wrap to ensure the value of a variable stays within a specified range. For x,y > 0, \nsuccessive values of x wrap y cycle through the sequence 1, 2, ..., y."
		},{
			"id":"109",
			"name":"numberisnumber",
			"display name":"NumberIsNumber",
			"type":"operator",
			"syntax":[
				"<Left> is <Right>"
			],
			"display syntax":[
				"<i>Left</i> is <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Determines if <Left> is <Right>.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Left> is equal to <Right>, and false otherwise."
			}],
			"description":"Identical to the <NumberIsEqualToNumber> operator.",
			"references":{
				"operator":["NumberIsEqualToNumber"]
			},
			"tags":["Math"]
		},{
			"id":"110",
			"name":"formatnumberasstring",
			"display name":"FormatNumberAsString",
			"type":"statement",
			"syntax":[
				"format <Operand> as string"
			],
			"display syntax":[
				"format <i>Operand</i> as string"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Formats a numeric value as a string",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tNum as Number\nput 5 into tNum\nformat tNum as string -- the result contains \"5\""
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"<Operand> formatted as a string."
			}],
			"description":"Use <FormatNumberAsString> when you want to manipulate a numeric value as text."
		},{
			"id":"111",
			"name":"timesoperator",
			"display name":"TimesOperator",
			"type":"operator",
			"syntax":[
				"<Left> * <Right>"
			],
			"display syntax":[
				"<i>Left</i> * <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Binary multiplication operator.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput 3 * 5 into tVar -- tVar contains 15"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The result of multiplying the numbers <Left> and <Right>."
			}],
			"tags":["Math"]
		},{
			"id":"112",
			"name":"stringparsedasnumber",
			"display name":"StringParsedAsNumber",
			"type":"operator",
			"syntax":[
				"<Operand> parsed as number"
			],
			"display syntax":[
				"<i>Operand</i> parsed as number"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Parses a string as an number",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a string."
			}],
			"examples":[{
				"script":"variable tString as String\nvariable tNum as optional Number\nput \"5.6\" into tString\nput tString parsed as number into tNum -- tNum contains 5.6"
			},{
				"script":"variable tNum as optional Number\nput \"aaaa\" parsed as number into tNum\n\nif tNum is nothing then\n\tput 0 into tNum\nend if\n\n// tNum contains 0"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"<Operand> parsed as a number, or nothing."
			}],
			"description":"Use <StringParsedAsNumber> when you want to interpret text numerically. nothing is returned if parsing was not possible."
		},{
			"id":"113",
			"name":"numberisgreaterthannumber",
			"display name":"NumberIsGreaterThanNumber",
			"type":"operator",
			"syntax":[
				"<Left> &gt; <Right>"
			],
			"display syntax":[
				"<i>Left</i> &gt; <i>Right</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Greater than relation.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Left> is greater than <Right>, and false otherwise."
			}]
		},{
			"id":"114",
			"name":"multiplynumberby",
			"display name":"MultiplyNumberBy",
			"type":"statement",
			"syntax":[
				"multiply <Target> by <Value>"
			],
			"display syntax":[
				"multiply <i>Target</i> by <i>Value</i>"
			],
			"associations":["com.livecode.arithmetic"],
			"summary":"Multiplies <Target> by <Value>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a numeric variable."
			},{
				"name":"Value",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput 2 into tVar\nmultiply tVar by 2 -- tVar contains 4"
			}],
			"description":"Multiplies the number <Target> by <Value>.\n\n>*Note:* It is a syntax error if <Target> does not evaluate to a variable.",
			"tags":["Math"]
		},{
			"id":"115",
			"name":"roundtonearest",
			"display name":"RoundToNearest",
			"type":"statement",
			"syntax":[
				"round <Target>"
			],
			"display syntax":[
				"round <i>Target</i>"
			],
			"associations":["com.livecode.mathfoundation"],
			"summary":"Rounds <Target> to the nearest integer.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a numeric container."
			}],
			"examples":[{
				"script":"variable tNum as Number\nput -5.5 into tNum\nround tNum -- tNum contains -6"
			}],
			"description":"Replaces <Target> with the greatest integer less than or equal to <Target>, or the least integer greater than or equal to <Target> depending on which is closest. If <Target> is exactly halfway between two integers, rounds to the one with greatest absolute value, i.e. away from 0."
		},{
			"id":"116",
			"name":"com.livecode.mathfoundation",
			"display name":"com.livecode.mathfoundation",
			"type":"library",
			"display syntax":[
				"com.livecode.mathfoundation"
			],
			"description":"This library consists of the foundational mathematical operations included in the standard library of LiveCode Builder."
		},{
			"id":"117",
			"name":"ceiloperator",
			"display name":"CeilOperator",
			"type":"operator",
			"syntax":[
				"the ceiling of <Target>"
			],
			"display syntax":[
				"the ceiling of <i>Target</i>"
			],
			"associations":["com.livecode.mathfoundation"],
			"summary":"Returns the ceiling of <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tNum as Number\nvariable tCeiling as Number\nput -5.5 into tNum\nput the ceiling of tNum into tCeiling -- tCeiling contains -5"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The ceiling of <Target>"
			}],
			"description":"The ceiling of <Target> is the least integer greater than or equal to <Target>.",
			"tags":["Math"]
		},{
			"id":"118",
			"name":"flooroperator",
			"display name":"FloorOperator",
			"type":"operator",
			"syntax":[
				"the floor of <Target>"
			],
			"display syntax":[
				"the floor of <i>Target</i>"
			],
			"associations":["com.livecode.mathfoundation"],
			"summary":"Returns the floor of <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tNum as Number\nvariable tFloor as Number\nput -5.5 into tNum\nput the floor of tNum into tFloor -- tFloor contains -6"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The floor of <Target>"
			}],
			"description":"The floor of <Target> is the greatest integer less than or equal to <Target>.",
			"tags":["Math"]
		},{
			"id":"119",
			"name":"roundedtonearest",
			"display name":"RoundedToNearest",
			"type":"operator",
			"syntax":[
				"the rounded of <Target>"
			],
			"display syntax":[
				"the rounded of <i>Target</i>"
			],
			"associations":["com.livecode.mathfoundation"],
			"summary":"Rounds <Target> to the nearest integer.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tNum as Number\nvariable tRounded as Number\nput -5.5 into tNum\nput the rounded of tNum into tRounded -- tRounded contains -6"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The rounded value of <Target>"
			}],
			"description":"Return the greatest integer less than or equal to <Target>, or the least integer greater than or equal to <Target> depending on which is closest. If <Target> is exactly halfway between two integers, returns the one with greatest absolute value, i.e. away from 0.",
			"tags":["Math"]
		},{
			"id":"120",
			"name":"piconstant",
			"display name":"PiConstant",
			"type":"expression",
			"syntax":[
				"pi"
			],
			"display syntax":[
				"pi"
			],
			"associations":["com.livecode.mathfoundation"],
			"summary":"The constant pi",
			"examples":[{
				"script":"variable tVar as Number\nput the cos of pi into tVar -- tVar contains -1"
			}],
			"description":"The ratio of a circle's circumference to its diameter.",
			"tags":["Math"]
		},{
			"id":"121",
			"name":"com.livecode.system",
			"display name":"com.livecode.system",
			"type":"library",
			"display syntax":[
				"com.livecode.system"
			],
			"description":"This library provides low-level system functionality for modular\nLiveCode programs."
		},{
			"id":"122",
			"name":"operatingsystem",
			"display name":"OperatingSystem",
			"type":"expression",
			"syntax":[
				"the operating system"
			],
			"display syntax":[
				"the operating system"
			],
			"associations":["com.livecode.system"],
			"summary":"The operating system",
			"examples":[{
				"script":"if the operating system is \"linux\" then\n\t- Platform specific-code\nend if"
			}],
			"description":"Returns a string describing the operating system that LiveCode is\nrunning on.  The possible values are:\n\n* \"windows\" - 32-bit and 64-bit Windows\n* \"mac\" - Desktop OS X\n* \"ios\" - iOS (iPhone and iPad)\n* \"android\" - Android Linux devices\n* \"linux\" - All other Linux platforms",
			"tags":["System"]
		},{
			"id":"123",
			"name":"commandarguments",
			"display name":"CommandArguments",
			"type":"expression",
			"syntax":[
				"the command arguments"
			],
			"display syntax":[
				"the command arguments"
			],
			"associations":["com.livecode.system"],
			"summary":"The command arguments",
			"examples":[{
				"script":"-- Program that only succeeds if it's run as the \"true\"\n-- command.\nvariable tCommand as String\nput the command name into tCommand\nif tCommand ends with \"true\" then\n\tquit with status 0\nelse\n\tquit with status 1\nend if"
			}],
			"description":"Evaluates to a list of command-line arguments passed to the program.\nSome arguments may not be passed in if they are \"used up\" by the\nLiveCode run-time environment (for example, the LiveCode IDE will\ndetect and \"use\" the `-mmap` argument).\n\n> **Note:** No filename conversion is performed on command line\n> arguments, so some processing may be required before using a command\n> line argument with any of the file handling syntax provided by the\n> `com.livecode.file` module."
		},{
			"id":"124",
			"name":"quitwithstatus",
			"display name":"QuitWithStatus",
			"type":"statement",
			"syntax":[
				"quit [ with status <Status> ]"
			],
			"display syntax":[
				"quit [ with status <i>Status</i> ]"
			],
			"associations":["com.livecode.system"],
			"summary":"Quit the application",
			"examples":[{
				"script":"-- Quit, indicating that the application ran successfully (code 0)\nquit\n\n-- Quit, with a specific error code\nquit with status 42"
			}],
			"description":"Exit the program immediately and unconditionally, returning a status\nnumber to the operating system.  If no status is provided, the default\nvalue of 0 is used.",
			"tags":["System"]
		},{
			"id":"125",
			"name":"commandname",
			"display name":"CommandName",
			"type":"expression",
			"syntax":[
				"the command name"
			],
			"display syntax":[
				"the command name"
			],
			"associations":["com.livecode.system"],
			"summary":"The command name",
			"examples":[{
				"script":"-- Program that only succeeds if it's run as the \"true\"\n-- command.\nvariable tCommand as String\nput the command name into tCommand\nif tCommand ends with \"true\" then\n\tquit with status 0\nelse\n\tquit with status 1\nend if"
			}]
		},{
			"id":"126",
			"name":"elementsofarray",
			"display name":"ElementsOfArray",
			"type":"operator",
			"syntax":[
				"the elements of <Target>"
			],
			"display syntax":[
				"the elements of <i>Target</i>"
			],
			"associations":["com.livecode.array"],
			"summary":"Returns the elements of an array.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an array."
			}],
			"examples":[{
				"script":"variable tArray as Array\nput the empty array into tArray\nput 1 into tArray[\"key1\"]\nput 2 into tArray[\"key2\"]\nput 3 into tArray[\"key3\"]\n\nvariable tElements as List\nput the elements of tArray into tElements\nsort tElements in ascending numeric order\n\n// tElements is [1, 2, 3]"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A list whose elements are the elements of <Target>."
			}],
			"description":">*Note:* The resulting list is not necessarily ordered in any way. Use the <com.livecode.sort> library to sort the elements.",
			"references":{
				"library":["com.livecode.sort"]
			},
			"tags":["Arrays"]
		},{
			"id":"127",
			"name":"emptyarray",
			"display name":"EmptyArray",
			"type":"expression",
			"syntax":[
				"the empty array"
			],
			"display syntax":[
				"the empty array"
			],
			"associations":["com.livecode.array"],
			"summary":"Designates the array with no elements.",
			"examples":[{
				"script":"variable tVar as Array\nvariable tCount as Number\nput the empty array into tVar\nput the number of elements in tVar into tCount -- tCount is 0"
			}],
			"description":"Use ```the empty array``` to initialise an array variable.",
			"tags":["Arrays"]
		},{
			"id":"128",
			"name":"repeatforeachelementinarray",
			"display name":"RepeatForEachElementInArray",
			"type":"iterator",
			"syntax":[
				"element <Iterand>"
			],
			"display syntax":[
				"element <i>Iterand</i>"
			],
			"associations":["com.livecode.array"],
			"summary":"Repeat over the elements of an array.",
			"parameters":[{
				"name":"Iterand",
				"type":"",
				"refparam":"false",
				"description":"Any variable of appropriate type."
			}],
			"examples":[{
				"script":"    variable tArray as Array\n    put the empty array into tArray\n    put 1 into tArray[\"key1\"]\n    put 2 into tArray[\"key2\"]\n    put 3 into tArray[\"key3\"]\n\n\tvariable tSum as Number\n\tput 0 into tSum\n\n    variable tElement\n    repeat for each element tElement in tArray\n        add tElement to tSum\n    end repeat\n\n    // tSum is 6"
			}],
			"description":"Use repeat for each element to iterate over the elements of an array in no particular order. On each iteration, the <Iterand> will contain the next element of the array being iterated over.\n\n>*Note:* If <Iterand> is typed, then an error will be thrown if the array being iterated over contains any elements of a different type.",
			"tags":["Arrays"]
		},{
			"id":"129",
			"name":"singletonelementofarray",
			"display name":"SingletonElementOfArray",
			"type":"operator",
			"syntax":[
				"<Target> [ <Key> ]"
			],
			"display syntax":[
				"<i>Target</i> [ <i>Key</i> ]"
			],
			"associations":["com.livecode.array"],
			"summary":"Designates the element with key <Key> in <Target>.\nIndex:An expression which evaluates to a string.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an array."
			}],
			"examples":[{
				"script":"variable tArray as Array\nput the empty array into tArray\nput \"value\" into tArray[\"key\"]\n\nvariable tVar as String\nput tArray[\"key\"] into tVar -- tVar contains \"value\""
			}],
			"description":"Either locates the element container with the given key for use as the target container of another operation, or evaluates the element with the given key as the source of another operation.",
			"tags":["Arrays"]
		},{
			"id":"130",
			"name":"deleteelementofarray",
			"display name":"DeleteElementOfArray",
			"type":"statement",
			"syntax":[
				"delete <Target> [ <Key> ]"
			],
			"display syntax":[
				"delete <i>Target</i> [ <i>Key</i> ]"
			],
			"associations":["com.livecode.array"],
			"summary":"Deletes the element with key <Key> in <Target>.\nIndex:An expression which evaluates to a string.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an array."
			}],
			"examples":[{
				"script":"variable tArray as Array\nput the empty array into tArray\nput \"value\" into tArray[\"key\"]\n\ndelete tArray[\"key\"] -- tArray is the empty array"
			}],
			"description":"Either locates the element container with the given key for use as the target container of another operation, or evaluates the element with the given key as the source of another operation.",
			"tags":["Arrays"]
		},{
			"id":"131",
			"name":"amongkeysofarray",
			"display name":"AmongKeysOfArray",
			"type":"operator",
			"syntax":[
				"<Needle> ( is not | is ) among the keys of <Target>"
			],
			"display syntax":[
				"<i>Needle</i> ( is not | is ) among the keys of <i>Target</i>"
			],
			"associations":["com.livecode.array"],
			"summary":"Determines if an array has a given key",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer, string, or list of integers."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an array."
			}],
			"examples":[{
				"script":"variable tArray as Array\nput \"value\" into tArray[\"key\"]\n\nvariable tIsAmong as Boolean\nput \"key\" is among the keys of tArray into tIsAmong -- tIsAmong is true"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Needle> can be found among the keys of <Target>."
			}],
			"description":"The keys of an array are case insensitive. Thus\n``` tVar is among the keys of tArray``` \nis not equivalent to \n``` tVar is in (the keys of tArray) ```\nas the latter <IsInList> operation *is* case sensitive.",
			"references":{
				"operator":["IsInList"]
			},
			"tags":["Arrays"]
		},{
			"id":"132",
			"name":"keysofarray",
			"display name":"KeysOfArray",
			"type":"operator",
			"syntax":[
				"the keys of <Target>"
			],
			"display syntax":[
				"the keys of <i>Target</i>"
			],
			"associations":["com.livecode.array"],
			"summary":"Returns the keys of an array.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an array."
			}],
			"examples":[{
				"script":"variable tArray as Array\nput the empty array into tArray\nput \"value1\" into tArray[\"key1\"]\nput \"value2\" into tArray[\"key2\"]\nput \"value3\" into tArray[\"key3\"]\n\nvariable tKeys as List\nput the keys of tArray into tKeys\nsort tKeys in ascending order\n\nvariable tKeysString as String\ncombine tKeys with \",\" into tKeysString \n// tKeysString is \"key1,key2,key3\""
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A list whose elements are the keys of <Target>."
			}],
			"description":">*Note:* The resulting list is not necessarily ordered in any way. Use the <com.livecode.sort> library to sort the keys.",
			"references":{
				"library":["com.livecode.sort"]
			},
			"tags":["Arrays"]
		},{
			"id":"133",
			"name":"countelementsofarray",
			"display name":"CountElementsOfArray",
			"type":"operator",
			"syntax":[
				"the number of elements in <Target>"
			],
			"display syntax":[
				"the number of elements in <i>Target</i>"
			],
			"associations":["com.livecode.array"],
			"summary":"Returns the number of elements in <Target>",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an array."
			}],
			"examples":[{
				"script":"variable tArray as Array\nput the empty array into tArray\nput 1 into tArray[\"key1\"]\nput 2 into tArray[\"key2\"]\nput 3 into tArray[\"key3\"]\n\nvariable tVar as Number\nput the number of elements in tArray into tVar -- tVar contains 3"
			}],
			"description":"The number of elements in tArray returns the number of key-value pairs stored in the array.",
			"tags":["Arrays"]
		},{
			"id":"134",
			"name":"amongelementsofarray",
			"display name":"AmongElementsOfArray",
			"type":"operator",
			"syntax":[
				"<Needle> ( is not | is ) among the elements of <Target>"
			],
			"display syntax":[
				"<i>Needle</i> ( is not | is ) among the elements of <i>Target</i>"
			],
			"associations":["com.livecode.array"],
			"summary":"Determines if an array contains a given element",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"Any expression."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an array."
			}],
			"examples":[{
				"script":"variable tArray as Array\nput \"value\" into tArray[\"key\"]\n\nvariable tIsAmong as Boolean\nput \"value\" is among the elements of tArray into tIsAmong -- tIsAmong is true"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Needle> can be found among the elements of <Target>."
			}],
			"description":"Elements are compared using the default comparison for that type. Thus for a string, ```tString```, \n```tString is among the elements of tArray``` \nis a case sensitive search.",
			"tags":["Arrays"]
		},{
			"id":"135",
			"name":"repeatforeachkey",
			"display name":"RepeatForEachKey",
			"type":"iterator",
			"syntax":[
				"key <Iterand>"
			],
			"display syntax":[
				"key <i>Iterand</i>"
			],
			"associations":["com.livecode.array"],
			"summary":"Repeat over the keys of an array.",
			"parameters":[{
				"name":"Iterand",
				"type":"",
				"refparam":"false",
				"description":"A string container."
			}],
			"examples":[{
				"script":"    variable tArray as Array\n    put the empty array into tArray\n    put 1 into tArray[\"abc\"]\n    put 2 into tArray[\"def\"]\n    put 3 into tArray[\"ghi\"]\n\n\tvariable tString as String\n\tput \"\" into tString\n\n    variable tKey as String\n    repeat for each key tKey in tArray\n        put tKey after tString\n    end repeat\n\n    variable tBool as Boolean\n    put tString contains \"abc\" into tBool -- tBool is true"
			}],
			"description":"Use repeat for each key to iterate over the keys of an array in no particular order. On each iteration, the <Iterand> will contain the next key of the array being iterated over."
		},{
			"id":"136",
			"name":"com.livecode.array",
			"display name":"com.livecode.array",
			"type":"library",
			"display syntax":[
				"com.livecode.array"
			],
			"description":"This library consists of the operations on arrays included in the standard library of LiveCode Builder."
		},{
			"id":"137",
			"name":"absoperator",
			"display name":"AbsOperator",
			"type":"operator",
			"syntax":[
				"the abs of <Operand>"
			],
			"display syntax":[
				"the abs of <i>Operand</i>"
			],
			"associations":["com.livecode.math"],
			"summary":"Absolute value operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput the trunc of 3.9 into tVar -- tVar contains 3"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The absolute value of <Operand>."
			}],
			"description":"The absolute value of <Operand> is the value of <Operand> if it is greater than or equal to 0, or the negation of the value of <Operand> if it is less than zero.",
			"tags":["Math"]
		},{
			"id":"138",
			"name":"baseelogoperator",
			"display name":"BaseELogOperator",
			"type":"operator",
			"syntax":[
				"ln(<Operand>)"
			],
			"display syntax":[
				"ln(<i>Operand</i>)"
			],
			"associations":["com.livecode.math"],
			"summary":"Natural log operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput ln(exp(3)) into tVar -- tVar contains approximately 3"
			}],
			"tags":["Math"]
		},{
			"id":"139",
			"name":"maxlistoperator",
			"display name":"MaxListOperator",
			"type":"operator",
			"syntax":[
				"the maximum value of <ValueList>"
			],
			"display syntax":[
				"the maximum value of <i>ValueList</i>"
			],
			"associations":["com.livecode.math"],
			"summary":"Max operator.\nList:An expression that evaluates to a list.",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The maximum value attained by the elements of <List>."
			}],
			"description":">*Note:* It is an error if any element of <List> is non-numeric.",
			"tags":["Math"]
		},{
			"id":"140",
			"name":"com.livecode.math",
			"display name":"com.livecode.math",
			"type":"library",
			"display syntax":[
				"com.livecode.math"
			],
			"description":"This library consists of the mathematical operations included in the standard library of LiveCode Builder."
		},{
			"id":"141",
			"name":"minlistoperator",
			"display name":"MinListOperator",
			"type":"operator",
			"syntax":[
				"the minimum value of <ValueList>"
			],
			"display syntax":[
				"the minimum value of <i>ValueList</i>"
			],
			"associations":["com.livecode.math"],
			"summary":"Min operator.\nList:An expression that evaluates to a list.",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The minimal value attained by the elements of <List>."
			}],
			"description":">*Note:* It is an error if any element of <List> is non-numeric.",
			"tags":["Math"]
		},{
			"id":"142",
			"name":"baseconvert",
			"display name":"BaseConvert",
			"type":"operator",
			"syntax":[
				"<Operand> converted from base <Source> to base <Target>"
			],
			"display syntax":[
				"<i>Operand</i> converted from base <i>Source</i> to base <i>Target</i>"
			],
			"associations":["com.livecode.math"],
			"summary":"Converts the base of <Operand>",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a string."
			},{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to an integer."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to an integer."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A string representation <Operand> interpreted as a number in base <From>, converted to base <To>."
			}],
			"description":"Interprets a string in the desired source base and converts it to the desired target base, and returns a string representation.\n\n>*Note:* The source and destination bases must be integers between 2 and 32."
		},{
			"id":"143",
			"name":"baseconvertto",
			"display name":"BaseConvertTo",
			"type":"operator",
			"syntax":[
				"<Operand> converted to base <Target>"
			],
			"display syntax":[
				"<i>Operand</i> converted to base <i>Target</i>"
			],
			"associations":["com.livecode.math"],
			"summary":"Converts the base of <Operand>",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to an integer."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to an integer."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A string representation of <Operand> in base <Target>."
			}],
			"description":"Converts a decimal into the desired base, and returns a string representation.\n\n>*Note:* The destination base must be an integer between 2 and 32.",
			"tags":["Math"]
		},{
			"id":"144",
			"name":"base10logoperator",
			"display name":"Base10LogOperator",
			"type":"operator",
			"syntax":[
				"log(<Operand>)"
			],
			"display syntax":[
				"log(<i>Operand</i>)"
			],
			"associations":["com.livecode.math"],
			"summary":"Base 10 log operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput the log of 10000 into tVar -- tVar contains 5"
			}],
			"tags":["Math"]
		},{
			"id":"145",
			"name":"arcsinoperator",
			"display name":"ArcsinOperator",
			"type":"operator",
			"syntax":[
				"asin(<Operand>)"
			],
			"display syntax":[
				"asin(<i>Operand</i>)"
			],
			"associations":["com.livecode.math"],
			"summary":"Arcsin operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput the asin(-1) into tVar -- tVar contains -pi/2"
			},{
				"script":"variable tVar as Number\nput the arcsine of 1 into tVar -- tVar contains pi/2"
			}],
			"description":"The inverse of the sin operator.",
			"tags":["Math"]
		},{
			"id":"146",
			"name":"expoperator",
			"display name":"ExpOperator",
			"type":"operator",
			"syntax":[
				"exp(<Operand>)"
			],
			"display syntax":[
				"exp(<i>Operand</i>)"
			],
			"associations":["com.livecode.math"],
			"summary":"Exponentiation operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput the exp(ln(100)) into tVar -- tVar contains approximately 100"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"e to the power of <Operand>"
			}],
			"tags":["Math"]
		},{
			"id":"147",
			"name":"binaryarctanoperator",
			"display name":"BinaryArctanOperator",
			"type":"operator",
			"syntax":[
				"atan2(<yCoord>,<xCoord>)"
			],
			"display syntax":[
				"atan2(<i>yCoord</i>,<i>xCoord</i>)"
			],
			"associations":["com.livecode.math"],
			"summary":"Binary arctan operator.",
			"parameters":[{
				"name":"yCoord",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"xCoord",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"    variable tVar as Number\n    put atan2(-1,-1) into tVar --tVar contains â3Ï/4."
			},{
				"script":"    variable tVar as Number\n    put the binary arctangent of -1 and -1 into tVar --tVar contains â3Ï/4."
			}],
			"description":"The binary arctan operator returns the angle in radians between the x-axis and the line from the origin to the point (xCoord, yCoord).\nThe angle returned has absolute value less than pi: âÏ < arctan2(y, x) â¤ Ï.",
			"tags":["Math"]
		},{
			"id":"148",
			"name":"truncoperator",
			"display name":"TruncOperator",
			"type":"operator",
			"syntax":[
				"the trunc of <Operand>"
			],
			"display syntax":[
				"the trunc of <i>Operand</i>"
			],
			"associations":["com.livecode.math"],
			"summary":"Truncation operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput the trunc of 3.9 into tVar -- tVar contains 3"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"<Operand> truncated."
			}],
			"description":"The trunc of <Operand> is the integer part of the decimal representation of <Operand>.",
			"tags":["Math"]
		},{
			"id":"149",
			"name":"sinoperator",
			"display name":"SinOperator",
			"type":"operator",
			"syntax":[
				"sin(<Operand>)"
			],
			"display syntax":[
				"sin(<i>Operand</i>)"
			],
			"associations":["com.livecode.math"],
			"summary":"Sin operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput sin(pi / 2) into tVar -- tVar contains 1"
			},{
				"script":"variable tVar as Number\nput the sine of pi into tVar -- tVar contains 0"
			}],
			"tags":["Math"]
		},{
			"id":"150",
			"name":"arctanoperator",
			"display name":"ArctanOperator",
			"type":"operator",
			"syntax":[
				"atan(<Operand>)"
			],
			"display syntax":[
				"atan(<i>Operand</i>)"
			],
			"associations":["com.livecode.math"],
			"summary":"Arctan operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput atan(-1) into tVar -- tVar contains -pi / 4"
			},{
				"script":"variable tVar as Number\nput the arctangent of 1 into tVar -- tVar contains pi / 4"
			}],
			"description":"The inverse of the tan operator.",
			"tags":["Math"]
		},{
			"id":"151",
			"name":"cosoperator",
			"display name":"CosOperator",
			"type":"operator",
			"syntax":[
				"cos(<Operand>)"
			],
			"display syntax":[
				"cos(<i>Operand</i>)"
			],
			"associations":["com.livecode.math"],
			"summary":"Cos operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput cos(pi) into tVar -- tVar contains -1"
			}],
			"tags":["Math"]
		},{
			"id":"152",
			"name":"maxoperator",
			"display name":"MaxOperator",
			"type":"operator",
			"syntax":[
				"the maximum of <Left> and <Right>"
			],
			"display syntax":[
				"the maximum of <i>Left</i> and <i>Right</i>"
			],
			"associations":["com.livecode.math"],
			"summary":"Max operator.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The value of <Left>, if it is greater than the value of <Right>, and the value of <Right> otherwise."
			}],
			"tags":["Math"]
		},{
			"id":"153",
			"name":"arccosoperator",
			"display name":"ArccosOperator",
			"type":"operator",
			"syntax":[
				"acos(<Operand>)"
			],
			"display syntax":[
				"acos(<i>Operand</i>)"
			],
			"associations":["com.livecode.math"],
			"summary":"Arccos operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput acos(0) into tVar -- tVar contains pi/2"
			},{
				"script":"variable tVar as Number\nput the arccosine of -1 into tVar -- tVar contains pi"
			}],
			"description":"The inverse of the cos operator.",
			"tags":["Math"]
		},{
			"id":"154",
			"name":"minoperator",
			"display name":"MinOperator",
			"type":"operator",
			"syntax":[
				"the minimum of <Left> and <Right>"
			],
			"display syntax":[
				"the minimum of <i>Left</i> and <i>Right</i>"
			],
			"associations":["com.livecode.math"],
			"summary":"Min operator.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The value of <Left>, if it is less than the value of <Right>, and the value of <Right> otherwise."
			}],
			"tags":["Math"]
		},{
			"id":"155",
			"name":"randomnumber",
			"display name":"RandomNumber",
			"type":"expression",
			"syntax":[
				"any number"
			],
			"display syntax":[
				"any number"
			],
			"associations":["com.livecode.math"],
			"summary":"Generates a pseudo-random number.",
			"examples":[{
				"script":"variable tVar as Number\nput any number into tVar -- 0 <= tVar <= 1"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A real between 0.0 and 1.0."
			}],
			"tags":["Math"]
		},{
			"id":"156",
			"name":"baseconvertfrom",
			"display name":"BaseConvertFrom",
			"type":"operator",
			"syntax":[
				"<Operand> converted from base <Source>"
			],
			"display syntax":[
				"<i>Operand</i> converted from base <i>Source</i>"
			],
			"associations":["com.livecode.math"],
			"summary":"Converts the base of <Operand>",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a string."
			},{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to an integer."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"<Operand> converted to base 10."
			}],
			"description":"Interprets a string in the desired base and converts it to decimal.\n\n>*Note:* The source base must be an integer between 2 and 32.",
			"tags":["Math"]
		},{
			"id":"157",
			"name":"powoperator",
			"display name":"PowOperator",
			"type":"operator",
			"syntax":[
				"<Left> ^ <Right>"
			],
			"display syntax":[
				"<i>Left</i> ^ <i>Right</i>"
			],
			"associations":["com.livecode.math"],
			"summary":"Binary exponentiation operation.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput 5^2 into tVar -- tVar contains 25"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The result of raising <Left> to the power <Right>."
			}],
			"tags":["Math"]
		},{
			"id":"158",
			"name":"tanoperator",
			"display name":"TanOperator",
			"type":"operator",
			"syntax":[
				"tan(<Operand>)"
			],
			"display syntax":[
				"tan(<i>Operand</i>)"
			],
			"associations":["com.livecode.math"],
			"summary":"Tan operator.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a number."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput the tan(pi) into tVar -- tVar contains 0"
			},{
				"script":"variable tVar as Number\nput the tangent of pi /4 into tVar -- tVar contains approximately 1"
			}],
			"tags":["Math"]
		},{
			"id":"159",
			"name":"sortlistdescending",
			"display name":"SortListDescending",
			"type":"statement",
			"syntax":[
				"sort <Target> in descending order"
			],
			"display syntax":[
				"sort <i>Target</i> in descending order"
			],
			"associations":["com.livecode.sort"],
			"summary":"Sorts <Target> in descending text order.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a list of strings."
			}],
			"examples":[{
				"script":"   \tvariable tTestList as List\n\tput [\"a\", \"b\", \"c\"] into tTestList\n\n    sort tTestList in descending order -- tTestList is [\"c\", \"b\", \"a\"]"
			}],
			"description":"Generic sort is performed by comparing the elements of a homogeneous list according to the default comparison function associated to the type of its elements.\n>*Note:* It is an error if <Target> is not homogeneous, i.e. if it contains any elements of differing type.",
			"tags":["Sorting"]
		},{
			"id":"160",
			"name":"sortlistascendingbinary",
			"display name":"SortListAscendingBinary",
			"type":"statement",
			"syntax":[
				"sort <Target> in ascending byte order"
			],
			"display syntax":[
				"sort <i>Target</i> in ascending byte order"
			],
			"associations":["com.livecode.sort"],
			"summary":"Sorts <Target> in ascending binary order.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a list of binary data."
			}],
			"description":"Binary sort is performed by comparing data elements on a byte by byte basis.\n>*Note:* It is an error if <Target> contains any elements of non-data type."
		},{
			"id":"161",
			"name":"sortlistdescendingtext",
			"display name":"SortListDescendingText",
			"type":"statement",
			"syntax":[
				"sort <Target> in descending text order"
			],
			"display syntax":[
				"sort <i>Target</i> in descending text order"
			],
			"associations":["com.livecode.sort"],
			"summary":"Sorts <Target> in descending text order.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a list of strings."
			}],
			"examples":[{
				"script":"    variable tTestList as List\n    put the empty list into tTestList\n\n    push \"abcd\" onto tTestList\n    push \"xyz\" onto tTestList\n\n    sort tTestList in descending text order -- tTestList is [\"xyz\", \"abcd\"]"
			}],
			"description":"Text sort is performed by comparing string elements on a codepoint by codepoint basis.\n>*Note:* It is an error if <Target> contains any elements of non-string type.",
			"tags":["Sorting"]
		},{
			"id":"162",
			"name":"sortlistascendingtext",
			"display name":"SortListAscendingText",
			"type":"statement",
			"syntax":[
				"sort <Target> in ascending text order"
			],
			"display syntax":[
				"sort <i>Target</i> in ascending text order"
			],
			"associations":["com.livecode.sort"],
			"summary":"Sorts <Target> in ascending text order.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a list of strings."
			}],
			"examples":[{
				"script":"    variable tTestList as List\n\n\tvariable tChar\n\trepeat for each char tChar in \"spoilage\"\n\t\tpush tChar onto tTestList\n\tend repeat\n\n    sort tTestList in ascending text order\n    variable tString as String\n    combine tTestList with \"\" into tString -- tString is \"aegilops\""
			}],
			"description":"Text sort is performed by comparing string elements on a codepoint by codepoint basis.\n>*Note:* It is an error if <Target> contains any elements of non-string type.",
			"tags":["Sorting"]
		},{
			"id":"163",
			"name":"sortlistascendingnumeric",
			"display name":"SortListAscendingNumeric",
			"type":"statement",
			"syntax":[
				"sort <Target> in ascending numeric order"
			],
			"display syntax":[
				"sort <i>Target</i> in ascending numeric order"
			],
			"associations":["com.livecode.sort"],
			"summary":"Sorts <Target> in ascending numeric order.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a list of numbers."
			}],
			"examples":[{
				"script":"    variable tTestList as List\n    put [3,4,5,1,2] into tTestList\n\n    sort tTestList in ascending numeric order -- tTestList is [1,2,3,4,5]"
			}],
			"description":"Numeric sort is performed by comparing numeric elements by cardinality.\n>*Note:* It is an error if <Target> contains any elements of non-numeric type.",
			"tags":["Sorting"]
		},{
			"id":"164",
			"name":"sortlistdescendingbinary",
			"display name":"SortListDescendingBinary",
			"type":"statement",
			"syntax":[
				"sort <Target> in descending byte order"
			],
			"display syntax":[
				"sort <i>Target</i> in descending byte order"
			],
			"associations":["com.livecode.sort"],
			"summary":"Sorts <Target> in descending binary order.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a list of binary data."
			}],
			"description":"Binary sort is performed by comparing data elements on a byte by byte basis.\n>*Note:* It is an error if <Target> contains any elements of non-data type.",
			"tags":["Sorting"]
		},{
			"id":"165",
			"name":"",
			"display name":"",
			"type":"handler",
			"syntax":[
				"SortCompare(<pLeft>,<pRight>)"
			],
			"display syntax":[
				"SortCompare(<i>pLeft</i>,<i>pRight</i>)"
			],
			"associations":["com.livecode.sort"],
			"summary":"A handler type that can be used in the <SortListUsingHandler> command.",
			"parameters":[{
				"name":"pLeft",
				"type":"",
				"refparam":"false",
				"description":"The left hand value to compare."
			},{
				"name":"pRight",
				"type":"",
				"refparam":"false",
				"description":"The right hand value to compare."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"An integer less than 0 if pLeft is less than pRight with respect to the intended ordering,\nan integer greater than 0 if pLeft is greater than pRight with respect to the intended ordering,\nor 0 if pLeft is equal to pRight."
			}],
			"description":"Any handler of type <SortCompare> can be passed to <SortListUsingHandler> to sort a list. \nIt takes two arguments, and returns an integer based on the comparison.",
			"tags":["Sorting"]
		},{
			"id":"166",
			"name":"sortlistascending",
			"display name":"SortListAscending",
			"type":"statement",
			"syntax":[
				"sort <Target> [in ascending order]"
			],
			"display syntax":[
				"sort <i>Target</i> [in ascending order]"
			],
			"associations":["com.livecode.sort"],
			"summary":"Sorts <Target> in ascending order.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a list."
			}],
			"examples":[{
				"script":"    variable tTestList as List\n\tput [4,3,1,5,2] into tTestList\n\n    sort tTestList -- tTestList is [1,2,3,4,5]"
			}],
			"description":"Generic sort is performed by comparing the elements of a homogeneous list according to the default comparison function associated to the type of its elements.\n>*Note:* It is an error if <Target> is not homogeneous, i.e. if it contains any elements of differing type.",
			"tags":["Sorting"]
		},{
			"id":"167",
			"name":"sortlistdescendingnumeric",
			"display name":"SortListDescendingNumeric",
			"type":"statement",
			"syntax":[
				"sort <Target> in descending numeric order"
			],
			"display syntax":[
				"sort <i>Target</i> in descending numeric order"
			],
			"associations":["com.livecode.sort"],
			"summary":"Sorts <Target> in descending numeric order.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a list of numbers."
			}],
			"examples":[{
				"script":"    variable tTestList as List\n    put [3,4,5,1,2] into tTestList\n\n    sort tTestList in descending numeric order -- tTestList is [5,4,3,2,1]"
			}],
			"description":"Numeric sort is performed by comparing numeric elements by cardinality.\n>*Note:* It is an error if <Target> contains any elements of non-numeric type.",
			"tags":["Sorting"]
		},{
			"id":"168",
			"name":"com.livecode.sort",
			"display name":"com.livecode.sort",
			"type":"library",
			"display syntax":[
				"com.livecode.sort"
			],
			"description":"This library consists of the sorting operations provided by the standard library of LiveCode Builder."
		},{
			"id":"169",
			"name":"putbytesafter",
			"display name":"PutBytesAfter",
			"type":"statement",
			"syntax":[
				"put <Source> after <Target>"
			],
			"display syntax":[
				"put <i>Source</i> after <i>Target</i>"
			],
			"associations":["com.livecode.binary"],
			"summary":"Appends <Source> bytes to <Target> bytes.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a binary container."
			}],
			"description":"Use to insert bytes into data without replacement. Can be used either with a chunk expression to insert at a specified location, or without to append to the target data."
		},{
			"id":"170",
			"name":"com.livecode.binary",
			"display name":"com.livecode.binary",
			"type":"library",
			"display syntax":[
				"com.livecode.binary"
			],
			"description":"This library consists of the operations on binary strings provided by the standard library of LiveCode Builder."
		},{
			"id":"171",
			"name":"putbytesbefore",
			"display name":"PutBytesBefore",
			"type":"statement",
			"syntax":[
				"put <Source> before <Target>"
			],
			"display syntax":[
				"put <i>Source</i> before <i>Target</i>"
			],
			"associations":["com.livecode.binary"],
			"summary":"Prepends <Source> bytes to <Target> bytes.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a binary container."
			}],
			"description":"Use to insert bytes into data without replacement. Can be used either with a chunk expression to insert at a specified location, or without to prepend to the target data.",
			"tags":["Binary"]
		},{
			"id":"172",
			"name":"emptydata",
			"display name":"EmptyData",
			"type":"expression",
			"syntax":[
				"the empty data"
			],
			"display syntax":[
				"the empty data"
			],
			"associations":["com.livecode.binary"],
			"summary":"Designates data of length 0.",
			"examples":[{
				"script":"variable tVar as Data\nvariable tCount as Number\nput the empty data into tVar\nput the number of bytes in tVar into tCount -- tCount is 0"
			}],
			"description":"Use ```the empty data``` to initialise a data variable.",
			"tags":["Binary"]
		},{
			"id":"173",
			"name":"dataislessthandata",
			"display name":"DataIsLessThanData",
			"type":"operator",
			"syntax":[
				"<Left> &lt; <Right>"
			],
			"display syntax":[
				"<i>Left</i> &lt; <i>Right</i>"
			],
			"associations":["com.livecode.binary"],
			"summary":"Determines whether <Left> is less than <Right> under a byte by byte comparison",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Left> is less than <Right>, and false otherwise."
			}],
			"description":"<Left> is less than <Right> if they are not equal, and the first byte in <Right> that is not equal to the corresponding byte in <Left> is of greater value.",
			"tags":["Binary"]
		},{
			"id":"174",
			"name":"concatenatebytes",
			"display name":"ConcatenateBytes",
			"type":"operator",
			"syntax":[
				"<Left> & <Right>"
			],
			"display syntax":[
				"<i>Left</i> & <i>Right</i>"
			],
			"associations":["com.livecode.binary"],
			"summary":"Concatenates <Left> and <Right>.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Binary data consisting of the value of the left hand expression with the value of the right hand expression appended to the end."
			}],
			"description":"The result consists of the bytes of <Left> followed by those of <Right>.",
			"tags":["Binary"]
		},{
			"id":"175",
			"name":"dataisnotdata",
			"display name":"DataIsNotData",
			"type":"operator",
			"syntax":[
				"<Left> is not <Right>"
			],
			"display syntax":[
				"<i>Left</i> is not <i>Right</i>"
			],
			"associations":["com.livecode.binary"],
			"summary":"Determines whether <Left> and <Right> are equal or not.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns false if the result of evaluating <Left> is the same as that of <Right>, and true otherwise."
			}],
			"description":"Performs a byte by byte comparison of <Left> and <Right>, returning true if there is any difference.",
			"tags":["Binary"]
		},{
			"id":"176",
			"name":"dataisdata",
			"display name":"DataIsData",
			"type":"operator",
			"syntax":[
				"<Left> is <Right>"
			],
			"display syntax":[
				"<i>Left</i> is <i>Right</i>"
			],
			"associations":["com.livecode.binary"],
			"summary":"Determines whether <Left> and <Right> are equal or not.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if the result of evaluating <Left> is the same as that of <Right>, and false otherwise."
			}],
			"description":"Performs a byte by byte comparison of <Left> and <Right>, returning false if there is any difference.",
			"tags":["Binary"]
		},{
			"id":"177",
			"name":"dataisgreaterthandata",
			"display name":"DataIsGreaterThanData",
			"type":"operator",
			"syntax":[
				"<Left> &gt; <Right>"
			],
			"display syntax":[
				"<i>Left</i> &gt; <i>Right</i>"
			],
			"associations":["com.livecode.binary"],
			"summary":"Determines whether <Left> is greater than <Right> under a byte by byte comparison",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Left> is greater than <Right>, and false otherwise."
			}],
			"description":"<Left> is greater than <Right> if they are not equal, and the first byte in <Left> that is not equal to the corresponding byte in <Right> is of greater value.",
			"tags":["Binary"]
		},{
			"id":"178",
			"name":"bitwiseshiftleft",
			"display name":"BitwiseShiftLeft",
			"type":"operator",
			"syntax":[
				"<Operand> shifted left by <Shift> bitwise"
			],
			"display syntax":[
				"<i>Operand</i> shifted left by <i>Shift</i> bitwise"
			],
			"associations":["com.livecode.bitwise"],
			"summary":"Shifts the bits of <Operand> left.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			},{
				"name":"Shift",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			}],
			"examples":[{
				"script":"variable tVar\nput 7 shifted left by 2 bitwise into tVar -- tVar contains 28"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The result of bit-shifting <Operand> left by <Shift> places."
			}],
			"description":"Shifts the bits of <Operand> left. Shifting the bits of <Operand> left\nby x is equivalent to multiplying by 2^x."
		},{
			"id":"179",
			"name":"bitwiseor",
			"display name":"BitwiseOr",
			"type":"operator",
			"syntax":[
				"<Left> bitwise or <Right>"
			],
			"display syntax":[
				"<i>Left</i> bitwise or <i>Right</i>"
			],
			"associations":["com.livecode.bitwise"],
			"summary":"Performs a bitwise OR operation on the binary representations of <Left> and <Right>.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput 3 bitwise or 6 into tVar -- tVar contains 7"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The integer whose binary representation is the result of the bitwise OR operation."
			}],
			"description":"Each bit of <Left> bitwise or <Right> is 0 if and only if both the corresponding bit of the binary representation of <Left> and that of <Right> is 0. Otherwise it is 1.",
			"tags":["Bitwise operations"]
		},{
			"id":"180",
			"name":"bitwisexor",
			"display name":"BitwiseXor",
			"type":"operator",
			"syntax":[
				"<Left> bitwise xor <Right>"
			],
			"display syntax":[
				"<i>Left</i> bitwise xor <i>Right</i>"
			],
			"associations":["com.livecode.bitwise"],
			"summary":"Performs a bitwise XOR operation on the binary representations of <Left> and <Right>.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput 3 bitwise xor 6 into tVar -- tVar contains 5"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The integer whose binary representation is the result of the bitwise XOR operation."
			}],
			"description":"Each bit of <Left> bitwise xor <Right> is 1 if and only if exactly one of the corresponding bits of the binary representation of <Left> and that of <Right> is 1. Otherwise it is 0.",
			"tags":["Bitwise operations"]
		},{
			"id":"181",
			"name":"bitwisenot",
			"display name":"BitwiseNot",
			"type":"operator",
			"syntax":[
				"bitwise not <Operand>"
			],
			"display syntax":[
				"bitwise not <i>Operand</i>"
			],
			"associations":["com.livecode.bitwise"],
			"summary":"Performs a bitwise NOT operation on the binary representation of <Operand>.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput bitwise not -5 into tVar -- tVar contains 4"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The integer whose binary representation is the result of the bitwise NOT operation."
			}],
			"description":"Bitwise not returns the complement of <Operand> as a signed two's\ncomplement integer, i.e. equivalent to -(x + 1).",
			"tags":["Bitwise operations"]
		},{
			"id":"182",
			"name":"bitwiseshiftright",
			"display name":"BitwiseShiftRight",
			"type":"operator",
			"syntax":[
				"<Operand> shifted right by <Shift> bitwise"
			],
			"display syntax":[
				"<i>Operand</i> shifted right by <i>Shift</i> bitwise"
			],
			"associations":["com.livecode.bitwise"],
			"summary":"Shifts the bits of <Operand> right.",
			"parameters":[{
				"name":"Operand",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			},{
				"name":"Shift",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			}],
			"examples":[{
				"script":"variable tVar\nput 7 shifted right by 2 bitwise into tVar -- tVar contains 1"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The result of bit-shifting <Operand> right by <Shift> places."
			}],
			"description":"Shifts the bits of <Operand> right. Shifting the bits of <Operand>\nright by x is equivalent to dividing by 2^x (rounding down)",
			"tags":["Bitwise operations"]
		},{
			"id":"183",
			"name":"bitwiseand",
			"display name":"BitwiseAnd",
			"type":"operator",
			"syntax":[
				"<Left> bitwise and <Right>"
			],
			"display syntax":[
				"<i>Left</i> bitwise and <i>Right</i>"
			],
			"associations":["com.livecode.bitwise"],
			"summary":"Performs a bitwise AND operation on the binary representations of <Left> and <Right>.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput 3 bitwise and 6 into tVar -- tVar contains 2"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The integer whose binary representation is the result of the bitwise AND operation."
			}],
			"description":"Each bit of <Left> bitwise and <Right> is 1 if and only if both the corresponding bit of the binary representation of <Left> and that of <Right> is 1. Otherwise it is 0.",
			"tags":["Bitwise operations"]
		},{
			"id":"184",
			"name":"com.livecode.bitwise",
			"display name":"com.livecode.bitwise",
			"type":"library",
			"display syntax":[
				"com.livecode.bitwise"
			],
			"description":"This module specifies the bitwise operations on integers included in the standard library of LiveCode Builder."
		},{
			"id":"185",
			"name":"com.livecode.unittest",
			"display name":"com.livecode.unittest",
			"type":"library",
			"display syntax":[
				"com.livecode.unittest"
			],
			"examples":[{
				"script":"public handler TestSelf()\n\tplan 10 tests\n\n\ttest diagnostic \"Normal tests\"\n\ttest 2 > 1\n\ttest \"Basic test\" when true\n\n\ttest diagnostic \"Skipped tests\"\n\tskip test\n\tskip test \"Skipped 2\"\n\tskip test because \"Not implemented\"\n\tskip test \"Skipped 4\" because \"Not supported on this platform\"\n\n\ttest diagnostic \"Tests which are expected to fail\"\n\tbroken test false\n\tbroken test \"Failed 2\" when false\n\tbroken test false because \"broken\"\n\tbroken test \"Failed 4\" when false because \"really broken\"\nend handler\n\nThe test results are output on standard output in TAP (Test Anything\nProtocol) format.\n"
			}],
			"description":"This library provides syntax for unit testing LiveCode Builder\nprograms.  It is used by the LiveCode Builder standard library's\ntestsuite.\n\nTo use this library, write your tests in a Builder source code file.\nEach group of tests should be a public handler with a name beginning\nwith \"Test\".  If possible, use one test per handler.  Otherwise, add a\n\"plan N tests\" statement at the start of the handler."
		},{
			"id":"186",
			"name":"listindex",
			"display name":"ListIndex",
			"type":"operator",
			"syntax":[
				"the ( first | last ) index of <Needle> in <Haystack>"
			],
			"display syntax":[
				"the ( first | last ) index of <i>Needle</i> in <i>Haystack</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Find the first or last occurrence of <Needle> within <Haystack>\nTarget:An expression which evaluates to a list.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to any value."
			}],
			"examples":[{
				"script":"variable tVar as List\nvariable tOffset as Number\nput [\"a\", \"b\", \"c\", \"d\", \"b\"]\nput the index of \"b\" in tVar into tOffset\n-- tOffset contains 2\n\nput the last index of \"b\" in tVar into tOffset\n-- tOffset contains 5"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the index from the start of <Haystack>."
			}],
			"description":"Use `the index of` to find where particular elements occur within a\nlist.  <Haystack> is scanned for an element that is equal to <Needle>,\nand the position of the element found is returned.  If neither the\n\"first index\" nor \"last index\" are specified, the index of the first\nelement found is returned.  If no element of <Haystack> is equal to\n<Needle>, the return value is 0.",
			"tags":["Lists"]
		},{
			"id":"187",
			"name":"repeatforeachelementinlist",
			"display name":"RepeatForEachElementInList",
			"type":"iterator",
			"syntax":[
				"element <Iterand>"
			],
			"display syntax":[
				"element <i>Iterand</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Repeat over the elements of a list",
			"parameters":[{
				"name":"Iterand",
				"type":"",
				"refparam":"false",
				"description":"Any variable of appropriate type."
			}],
			"examples":[{
				"script":"    variable tList as List\n    put [1, 1, 2, 3, 5, 8, 13] into tList\n\n    variable tRelist as List\n    variable tElement as any\n    put the empty list into tRelist\n\n    repeat for each element tElement in tList\n        push tElement onto tRelist\n    end repeat\n\n    // tRelist is the same as tList"
			}],
			"description":"Use repeat for each to perform an operation on each element of a list. On each iteration, the Iterand will contain the next element of the list being iterated over.\n>*Note:* If <Iterand> is typed, then an error will be thrown if the list being iterated over contains any elements of a different type.",
			"tags":["Lists","Control structures"]
		},{
			"id":"188",
			"name":"singletonelementoflist",
			"display name":"SingletonElementOfList",
			"type":"operator",
			"syntax":[
				"element <Index> of <Target>"
			],
			"display syntax":[
				"element <i>Index</i> of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Designates the element at index <Index> in <Target>.",
			"parameters":[{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput [1,2,3] into tVar\nput \"A\" into element 1 of tVar -- tVar is [\"A\",2,3]\n\nvariable tNum as Number\nput element 2 of tVar into tNum -- tNum is 2"
			}],
			"description":"Either locates the element container at the given index for use as the target container of another operation, or evaluates the element at the given index as the source of another operation.\n\n>*Note:* It is an error if <Index> is out of range.",
			"tags":["Lists"]
		},{
			"id":"189",
			"name":"deletelastelementof",
			"display name":"DeleteLastElementOf",
			"type":"statement",
			"syntax":[
				"delete the last element of <Target>"
			],
			"display syntax":[
				"delete the last element of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Deletes the last element of <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A list container."
			}],
			"description":"Removes the last element of <Target>.\n\n>*Note:* It is an error if <Target> is the empty list.",
			"tags":["Lists"]
		},{
			"id":"190",
			"name":"indexedelementoflist",
			"display name":"IndexedElementOfList",
			"type":"operator",
			"syntax":[
				"<Target> [ <Index> ]"
			],
			"display syntax":[
				"<i>Target</i> [ <i>Index</i> ]"
			],
			"associations":["com.livecode.list"],
			"summary":"Designates the element at index <Index> in <Target>.\nSynonym:SingletonElementOf",
			"parameters":[{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput [1,2,3] into tVar\nput \"A\" into tVar[1] -- tVar is [\"A\",2,3]\n\nvariable tNum as Number\nput tVar[2] into tNum -- tNum is 2"
			}],
			"description":"Either locates the element container at the given index for use as the target container of another operation, or evaluates the element at the given index as the source of another operation.\n\n>*Note:* It is an error if <Index> is out of range.",
			"tags":["Lists"]
		},{
			"id":"191",
			"name":"listoffset",
			"display name":"ListOffset",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of <Needle> in <Haystack>"
			],
			"display syntax":[
				"the ( first | last ) offset of <i>Needle</i> in <i>Haystack</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Find the first or last occurrence of <Needle> within <Haystack>\nTarget:An expression which evaluates to a list.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nvariable tOffset as Number\nput [\"a\", \"b\", \"c\", \"d\", \"b\", \"c\"]\nput the offset of [\"b\",\"c\"] in tVar into tOffset\n-- tOffset contains 2\n\nput the last offset of [\"b\", \"c\"] in tVar into tOffset\n-- tOffset contains 5"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the index from the start of <Haystack>."
			}],
			"description":"Use `the offset of` to find where a particular sub-list occurs within\na list.  <Haystack> is scanned for a sequence of elements that are\nequal to the elements of <Needle>, and the position of the start of\nthe sequence found is returned.  If neither the \"first offset\" nor\n\"last offset\" are specified, the index of the first matching sub-list\nfound is returned.  If no sub-list of <Haystack> is equal to <Needle>,\nthe return value is 0.",
			"tags":["Lists"]
		},{
			"id":"192",
			"name":"tailoflist",
			"display name":"TailOfList",
			"type":"operator",
			"syntax":[
				"the tail of <Target>"
			],
			"display syntax":[
				"the tail of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Returns the last element of <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput the empty list into tVar\npush \"first element\" onto tVar\npush \"last element\" onto tVar\n\nvariable tResult as String\nif the tail of tVar is \"last element\" then\n\tput \"success\" into tResult\nend if"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The last element of <Target>"
			}],
			"description":"Returns the first element of the list <Target> without modifying <Target>.\n```\tthe tail of tVar```\nis equivalent to using the <IndexedElementOfList> operator with index -1\n```\ttVar[-1]```",
			"references":{
				"operator":["IndexedElementOfList"]
			},
			"tags":["Lists"]
		},{
			"id":"193",
			"name":"splicebeforeelementoflist",
			"display name":"SpliceBeforeElementOfList",
			"type":"statement",
			"syntax":[
				"splice <Source> before element <Index> of <Target>"
			],
			"display syntax":[
				"splice <i>Source</i> before element <i>Index</i> of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Inserts each of the elements of <Source> into <Target> before element at index <Index>.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			},{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput the empty list into tVar\n\nvariable tCount as Number\nput 2 into tCount\nrepeat 3 times\n\tpush tCount onto tVar\nend repeat\n\nvariable tVar2 as List\npush 1 onto tVar2\npush 5 onto tVar2\n\nsplice tVar before element 2 of tVar2 -- tVar2 contains the list [1,2,3,4,5]"
			}],
			"description":"Use the splice syntax to insert the elements of one list into another list. \n\n>*Note:* ```put tList before element 2 of tList2``` results in the insertion of tList **as an element**, i.e. tList2 becomes the list [element 1 of tList2,tList,element 2 of tList2, element 3 of tList2 ...]\n\n>*Note:* It is an error if <Index> is out of range.",
			"tags":["Lists"]
		},{
			"id":"194",
			"name":"listindexafter",
			"display name":"ListIndexAfter",
			"type":"operator",
			"syntax":[
				"the ( first | last ) index of <Needle> after <After> in <Haystack>"
			],
			"display syntax":[
				"the ( first | last ) index of <i>Needle</i> after <i>After</i> in <i>Haystack</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Find the first or last occurrence of <Needle> within the tail of <Haystack>\nTarget:An expression which evaluates to a list.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to any value."
			},{
				"name":"After",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid index in Target."
			}],
			"examples":[{
				"script":"variable tVar as List\nvariable tOffset as Number\nput [\"a\", \"b\", \"c\", \"d\", \"b\"]\nput the index of \"b\" after 1 in tVar into tOffset\n--tOffset contains 2\n\nput the last index of \"b\" after 2 in tVar into tOffset\n--tOffset contains 5"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the index in <Haystack> relative to <After>."
			}],
			"description":"Use `the index ofâ¦ after` to find where particular elements occur\nwithin a list.  Starting from but not including the position <After>,\n<Haystack> is scanned for an element that is equal to <Needle>, and\nthe position of the element found is returned.  If no element of\n<Haystack> is equal to <Needle>, the return value is 0.",
			"tags":["Lists"]
		},{
			"id":"195",
			"name":"listendswithlist",
			"display name":"ListEndsWithList",
			"type":"operator",
			"syntax":[
				"<Source> ends with <Suffix>"
			],
			"display syntax":[
				"<i>Source</i> ends with <i>Suffix</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Determines whether <Source> ends with <Suffix>\nPrefix:An expression which evaluates to a list.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput [1, 2, 3, 4, 5] into tVar\n\nvariable tEnds as Boolean\n// put tList ends with tList[5] into tEnds -- error: tList[5] is not a list \n\nput tList ends with element 1 to 5 of tList into tEnds -- tEnds is true"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Source> ends with <Suffix>."
			}],
			"description":"<Source> ends with <Suffix> if and only if the elements of <Suffix> occur as a final subsequence of the elements of <Source>.\n\n>*Note:* Since the empty list is a final subsequence of every list, every list ends with the empty list.",
			"tags":["Lists"]
		},{
			"id":"196",
			"name":"deletefirstelementof",
			"display name":"DeleteFirstElementOf",
			"type":"statement",
			"syntax":[
				"delete the first element of <Target>"
			],
			"display syntax":[
				"delete the first element of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Deletes the first element of <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A list container."
			}],
			"description":"Removes the first element of <Target>.\n\n>*Note:* It is an error if <Target> is the empty list.",
			"tags":["Lists"]
		},{
			"id":"197",
			"name":"countelementsoflist",
			"display name":"CountElementsOfList",
			"type":"operator",
			"syntax":[
				"the number of elements in <Target>"
			],
			"display syntax":[
				"the number of elements in <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Returns the number of elements in <Target>",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput [1,2,3,4,5] into tVar\nvariable tNum as Number\nput the number of elements in tVar into tNum -- tNum is 5"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The number of elements in the list <Target>."
			}],
			"description":"Returns the number of elements in the list.",
			"tags":["Lists"]
		},{
			"id":"198",
			"name":"listcontainselements",
			"display name":"ListContainsElements",
			"type":"operator",
			"syntax":[
				"<Target> contains <Needle>"
			],
			"display syntax":[
				"<i>Target</i> contains <i>Needle</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Determines if <Target> contains <Needle> as a subsequence.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"Any expression which evaluates to a list."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tList as List\nput [ \"a\", \"b\", \"c\", \"d\" ] into tList\n\nvariable tContains as Boolean\n\n// put tList contains tList[1] into tContains -- error: tList[1] is not a list \n\nput tList contains element 1 to 2 of tList into tContains -- tContains is true"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Target> contains <Needle>."
			}],
			"description":"<Target> contains <Needle> if and only if the elements of <Needle> occur as a subsequence of the elements of <Target>.\n\n>*Note:* Since \"\" is a subsequence of elements of every list, every list contains the empty list.",
			"tags":["Lists"]
		},{
			"id":"199",
			"name":"deletesingletonelementof",
			"display name":"DeleteSingletonElementOf",
			"type":"statement",
			"syntax":[
				"delete element <Index> of <Target>"
			],
			"display syntax":[
				"delete element <i>Index</i> of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Deletes the element at index <Index> in <Target>.",
			"parameters":[{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A list container."
			}],
			"description":"Removes the element at the given index from the list.\n\n>*Note:* It is an error if either <Index> is out of range.",
			"tags":["Lists"]
		},{
			"id":"200",
			"name":"pushontolist",
			"display name":"PushOntoList",
			"type":"statement",
			"syntax":[
				"push <Value> onto ( front of | back of ) <Target>"
			],
			"display syntax":[
				"push <i>Value</i> onto ( front of | back of ) <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Pushes <Value> onto <Target>.",
			"parameters":[{
				"name":"Value",
				"type":"",
				"refparam":"false",
				"description":"Any expression."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput the empty list into tVar\npush \"something\" onto tVar\npush \"something else\" onto front of tVar\n\nvariable tResult as String\nif tVar[1] is \"something else\" then\n\tput \"success\" into tResult\nend if"
			}],
			"description":"When <Value> is pushed onto <Target>, <Value> (by default) becomes the tail of the list, with an index one greater than the previous tail.\nUse the 'front of' variant to push onto the front of a list instead.",
			"tags":["Lists"]
		},{
			"id":"201",
			"name":"headoflist",
			"display name":"HeadOfList",
			"type":"operator",
			"syntax":[
				"the head of <Target>"
			],
			"display syntax":[
				"the head of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Returns the first element of <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput the empty list into tVar\npush \"first element\" onto tVar\n\nvariable tResult as Boolean\nif the head of tVar is \"first element\" then\n\tput \"success\" into tResult\nend if"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The first element of <Target>"
			}],
			"description":"Returns the first element of the list <Target> without modifying <Target>.\n```\tthe head of tVar```\nis equivalent to using the <IndexedElementOfList> operator with index 1\n```\ttVar[1]```",
			"references":{
				"operator":["IndexedElementOfList"]
			},
			"tags":["Lists"]
		},{
			"id":"202",
			"name":"listindexbefore",
			"display name":"ListIndexBefore",
			"type":"operator",
			"syntax":[
				"the ( first | last ) index of <Needle> before <Before> in <Haystack>"
			],
			"display syntax":[
				"the ( first | last ) index of <i>Needle</i> before <i>Before</i> in <i>Haystack</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Find the first or last occurrence of <Needle> within the head of <Haystack>\nTarget:An expression which evaluates to a list.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to any value."
			},{
				"name":"Before",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid index in Target."
			}],
			"examples":[{
				"script":"variable tVar as List\nvariable tOffset as Number\nput [\"a\", \"b\", \"c\", \"d\", \"b\"]\nput the index of \"b\" before 2 in tVar into tOffset\n--tOffset contains 0\n\nput the first index of \"b\" before 5 in tVar into tOffset\n--tOffset contains 2"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the index in <Haystack>."
			}],
			"description":"Use `the index ofâ¦ before` to find where particular elements occur\nwithin a list.  <Haystack> is scanned for an element that is equal to\n<Needle>, stopping before the position <Before>, and the position of\nthe element found is returned.  If no element of <Haystack> is equal\nto <Needle>, the return value is 0.  If neither \"first\" nor \"last\" is\nspecified, the last matching element is found.",
			"tags":["Lists"]
		},{
			"id":"203",
			"name":"firstelementof",
			"display name":"FirstElementOf",
			"type":"operator",
			"syntax":[
				"the first element of <Target>"
			],
			"display syntax":[
				"the first element of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Designates the first element in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"description":"Either locates the first element for use as the target container of another operation, or evaluates the first element as the source of another operation.\n\n>*Note:* It is an error if <Target> is empty."
		},{
			"id":"204",
			"name":"emptylist",
			"display name":"EmptyList",
			"type":"expression",
			"syntax":[
				"the empty list"
			],
			"display syntax":[
				"the empty list"
			],
			"associations":["com.livecode.list"],
			"summary":"Designates the list of length zero.",
			"examples":[{
				"script":"variable tVar as List\nvariable tCount as Number\nput the empty list into tVar\nput the number of elements in tVar into tCount -- tCount is 0"
			}],
			"description":"Use ```the empty list``` to initialise a list variable.",
			"tags":["Lists"]
		},{
			"id":"205",
			"name":"spliceintoelementoflist",
			"display name":"SpliceIntoElementOfList",
			"type":"statement",
			"syntax":[
				"splice <Source> into element <Index> of <Target>"
			],
			"display syntax":[
				"splice <i>Source</i> into element <i>Index</i> of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Removes the element of <Target> at <Index> and inserts each of the elements of <Source> into\n                    <Target> at <Index>.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			},{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput the empty list into tVar\n\nvariable tCount as Number\nput 1 into tCount\nrepeat 3 times\n\tpush tCount onto tVar\nend repeat\n\nvariable tVar2 as List\npush \"this is unwanted\" onto tVar2\npush 4 onto tVar2\n\nsplice tVar into element 1 of tVar2 -- tVar2 contains the list [1,2,3,4]"
			}],
			"description":"Use the splice syntax to insert the elements of one list into another list. \n\n>*Note:* ```put tList into element 1 of tList2``` results in the removal of element 1 of tList2 and the insertion of tList **as an element**, i.e. tList2 becomes the list [tList,element 2 of tList2, element 3 of tList2 ...]\n\n>*Note:* It is an error if <Index> is out of range.",
			"tags":["Lists"]
		},{
			"id":"206",
			"name":"listislist",
			"display name":"ListIsList",
			"type":"operator",
			"syntax":[
				"<Left> is <Right>"
			],
			"display syntax":[
				"<i>Left</i> is <i>Right</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Determines whether <Left> and <Right> are equal or not.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tList as List\nput [\"a\", \"b\", \"c\"] into tList\nvariable tIs as Boolean\n\nput tList is [\"A\", \"b\", \"c\"] into tIs -- tIs is false\nput tList is element 1 to -1 of tList into tIs -- tIs is true"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Left> is identical to <Right>."
			}],
			"description":"Two lists are equal if each corresponding element is of comparable type, and if the default equality of that type holds between the elements.\nIn particular, this means that comparison between string elements is case sensitive.",
			"tags":["Lists"]
		},{
			"id":"207",
			"name":"lastelementof",
			"display name":"LastElementOf",
			"type":"operator",
			"syntax":[
				"the last element of <Target>"
			],
			"display syntax":[
				"the last element of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Designates the last element in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"description":"Either locates the first element for use as the target container of another operation, or evaluates the first element as the source of another operation.\n\n>*Note:* It is an error if <Target> is empty.",
			"tags":["Lists"]
		},{
			"id":"208",
			"name":"listoffsetbefore",
			"display name":"ListOffsetBefore",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of <Needle> before <Before> in <Haystack>"
			],
			"display syntax":[
				"the ( first | last ) offset of <i>Needle</i> before <i>Before</i> in <i>Haystack</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Find the first or last occurrence of <Needle> within the head of <Haystack>\nTarget:An expression which evaluates to a List.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to List."
			},{
				"name":"Before",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid index in Target."
			}],
			"examples":[{
				"script":"variable tVar as List\nvariable tOffset as Number\nput [\"a\", \"b\", \"c\", \"d\", \"b\",\"c\"]\nput the offset of [\"b\",\"c\"] before 5 in tVar into tOffset\n--tOffset contains 2\n\nput the first offset of [\"b\",\"c\"] before 6 in tVar into tOffset\n--tOffset contains 2"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the index in <Haystack>."
			}],
			"description":"Use `the offset ofâ¦ before` to find where a particular sub-list occurs\nwithin a list.  <Haystack> is scanned for a sequence of elements that\nare equal to the elements of <Needle>, stopping before the position\n<Before>, and the position of the start of the sequence found is\nreturned.  If no sub-list of <Haystack> before the position <Before>\nis equal to <Needle>, the return value is 0.  If neither \"first\" nor\n\"last\" is specified, the last matching subsequence is found.",
			"tags":["Lists"]
		},{
			"id":"209",
			"name":"spliceintorangeoflist",
			"display name":"SpliceIntoRangeOfList",
			"type":"statement",
			"syntax":[
				"splice <Source> into element <Start> to <Finish> of <Target>"
			],
			"display syntax":[
				"splice <i>Source</i> into element <i>Start</i> to <i>Finish</i> of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Removes the elements of <Target> from <Start > to <Finish> and inserts each of the elements of\n                    <Source> into <Target> at <Start>.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			},{
				"name":"Start",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Finish",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput the empty list into tVar\n\nvariable tCount as Number\nput 1 into tCount\nrepeat 3 times\n\tpush tCount onto tVar\nend repeat\n\nvariable tVar2 as List\npush \"these\" onto tVar2\npush \"are\" onto tVar2\npush \"unwanted\" onto tVar2\npush 4 onto tVar2\n\nsplice tVar into element 1 to 3 of tVar2 -- tVar2 contains the list [1,2,3,4]"
			}],
			"description":"Use the splice syntax to insert the elements of one list into another list. \n\n>*Note:* ```put tList into element 1 to 3 of tList2``` results in the removal of elements 1 to 3 of tList2 and the insertion of tList **as an element**, i.e. tList2 becomes the list [tList,element 4 of tList2, element 5 of tList2 ...]\n\n>*Note:* It is an error if either <Start> or <Finish> is out of range.",
			"tags":["Lists"]
		},{
			"id":"210",
			"name":"listoffsetafter",
			"display name":"ListOffsetAfter",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of <Needle> after <After> in <Haystack>"
			],
			"display syntax":[
				"the ( first | last ) offset of <i>Needle</i> after <i>After</i> in <i>Haystack</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Find the first or last occurrence of <Needle> within the tail of <Haystack>\nTarget:An expression which evaluates to a list.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to any list."
			},{
				"name":"After",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid index in Target."
			}],
			"examples":[{
				"script":"variable tVar as List\nvariable tOffset as Number\nput [\"a\", \"b\", \"c\", \"d\", \"b\", \"c\"]\nput the offset of [\"b\",\"c\"] after 1 in tVar into tOffset\n--tOffset contains 2\n\nput the last offset of [\"b\",\"c\"] after 1 in tVar into tOffset\n--tOffset contains 5"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the index in <Haystack> relative to <After>."
			}],
			"description":"Use `the offset ofâ¦ after` to find where a particular sub-list occurs\nwithin a list.  Starting from but not including the position <After>,\n<Haystack> is scanned for an sequence of elements that are equal to\nthe elements of <Needle>, and the position of the start of the\nsequence found is returned.  If neither the \"first offset\" nor \"last\noffset\" are specified, the position of the first matching sub-list\nfound is returned.  If no sub-list of <Haystack> starting after the\nposition <After> is equal to <Needle>, the return value is 0.",
			"tags":["Lists"]
		},{
			"id":"211",
			"name":"com.livecode.list",
			"display name":"com.livecode.list",
			"type":"library",
			"display syntax":[
				"com.livecode.list"
			],
			"description":"This library consists of the operations on lists included in the standard library of LiveCode Builder."
		},{
			"id":"212",
			"name":"rangeelementsoflist",
			"display name":"RangeElementsOfList",
			"type":"operator",
			"syntax":[
				"element <Start> to <Finish> of <Target>"
			],
			"display syntax":[
				"element <i>Start</i> to <i>Finish</i> of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Designates the elements between indices <Start> and <Finish> in <Target>.",
			"parameters":[{
				"name":"Start",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Finish",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tList as List\nput [1,2,3] into tList\n\nput tList into element 1 to 2 of tList -- tList is [[1,2,3],3]"
			}],
			"description":"Either locates the element containers between the given indices for use as a list container for the target of another operation, or evaluates the elements between the given indices as a list.\n\n>*Note:* It is an error if either <Start> or <Finish> are out of range.\n\n>*Note:* If a list is the source of ``put tList into element 1 to 3 of tOtherList```, then tList is *not* inserted element-wise. The entire list is inserted as an element, so that element 1 of tOtherList is tList.",
			"tags":["Lists"]
		},{
			"id":"213",
			"name":"deleterangeelementof",
			"display name":"DeleteRangeElementOf",
			"type":"statement",
			"syntax":[
				"delete element <Start> to <Finish> of <Target>"
			],
			"display syntax":[
				"delete element <i>Start</i> to <i>Finish</i> of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Deletes the elements between indices <Start> and <Finish> in <Target>.",
			"parameters":[{
				"name":"Start",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Finish",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A list container."
			}],
			"description":"Removes the elements between the given indices from the list.\n\n>*Note:* It is an error if either <Start> or <Finish> are out of range.",
			"tags":["Lists"]
		},{
			"id":"214",
			"name":"spliceafterelementoflist",
			"display name":"SpliceAfterElementOfList",
			"type":"statement",
			"syntax":[
				"splice <Source> after element <Index> of <Target>"
			],
			"display syntax":[
				"splice <i>Source</i> after element <i>Index</i> of <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Inserts each of the elements of <Source> into <Target> after element at index <Index>.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			},{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput the empty list into tVar\n\nvariable tCount as Number\nput 2 into tCount\nrepeat 3 times\n\tpush tCount onto tVar\nend repeat\n\nvariable tVar2 as List\npush 1 onto tVar2\npush 5 onto tVar2\n\nsplice tVar after element 1 of tVar2 -- tVar2 contains the list [1,2,3,4,5]"
			}],
			"description":"Use the splice syntax to insert the elements of one list into another list. \n\n>*Note:* ```put tList after element 1 of tList2``` results in the insertion of tList **as an element**, i.e. tList2 becomes the list [element 1 of tList2,tList,element 2 of tList2, element 3 of tList2 ...]\n\n>*Note:* It is an error if <Index> is out of range.",
			"tags":["Lists"]
		},{
			"id":"215",
			"name":"listbeginswithlist",
			"display name":"ListBeginsWithList",
			"type":"operator",
			"syntax":[
				"<Source> begins with <Prefix>"
			],
			"display syntax":[
				"<i>Source</i> begins with <i>Prefix</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Determines whether <Source> begins with <Prefix>",
			"parameters":[{
				"name":"Prefix",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			},{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput [1, 2, 3, 4, 5] into tVar\n\nvariable tBegins as Boolean\n// put tList begins with tList[1] into tBegins -- error: tList[1] is not a list \n\nput tList begins with [1, 2] into tBegins -- tBegins is true"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Source> begins with <Prefix>."
			}],
			"description":"<Source> begins with <Prefix> if and only if the elements of <Prefix> occur as an initial subsequence of the elements of <Source>.\n\n>*Note:* Since the empty list is an initial subsequence of every list, every list begins with the empty list.",
			"tags":["Lists"]
		},{
			"id":"216",
			"name":"elementisinlist",
			"display name":"ElementIsInList",
			"type":"operator",
			"syntax":[
				"<Needle> is in <Target>"
			],
			"display syntax":[
				"<i>Needle</i> is in <i>Target</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Determines if a given element is in <Target>",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"Any expression."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tList as List\nput [ \"a\", \"b\", \"c\", \"d\" ] into tList\n\nvariable tIsIn as Boolean\nput \"a\" is in tList into tIsIn -- tIsIn contains true"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Needle> can be found among the elements of <Target>."
			}],
			"description":"<Needle> must be an element of <Target> rather than a sublist, or contained within a list element of <Target>.",
			"tags":["Lists"]
		},{
			"id":"217",
			"name":"poplist",
			"display name":"PopList",
			"type":"statement",
			"syntax":[
				"pop ( front of | back of ) <Source>"
			],
			"display syntax":[
				"pop ( front of | back of ) <i>Source</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Pops the last element from <Source> into <Target>\nTarget:An expression which evaluates to a container.",
			"parameters":[{
				"name":"Source",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tVar as List\nput the empty list into tVar\npush \"something\" onto tVar\npush \"something else\" onto tVar\n\nvariable tPopped as String\npop tVar into tPopped -- tPopped contains \"something else\""
			},{
				"script":"variable tList as List\nput [1,2,3] into tList\nvariable tNum as Number\npop front of tList into tNum -- tNum is 1, tList is [2,3]"
			}],
			"description":"When <Source> is popped into <Target>, the last element of the list <Source> is removed and put into the container <Target>.\nUse the 'front of' variant to pop from the front of a list instead.",
			"tags":["Lists"]
		},{
			"id":"218",
			"name":"listisnotlist",
			"display name":"ListIsNotList",
			"type":"operator",
			"syntax":[
				"<Left> is not <Right>"
			],
			"display syntax":[
				"<i>Left</i> is not <i>Right</i>"
			],
			"associations":["com.livecode.list"],
			"summary":"Determines whether <Left> and <Right> are equal or not.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list."
			}],
			"examples":[{
				"script":"variable tList as List\nput [\"a\", \"b\", \"c\"] into tList\nvariable tIsNot as Boolean\n\nput tList is not [\"A\", \"b\", \"c\"] into tIsNot -- tIs is true"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns true if <Left> is not identical to <Right>."
			}],
			"description":"Two lists are not equal if any corresponding elements are of non-comparable types, or if the default equality of that type does not holds between the elements.\nIn particular, this means that comparison between string elements is case sensitive.",
			"tags":["Lists"]
		},{
			"id":"219",
			"name":"pathpropertysubpath",
			"display name":"PathPropertySubpath",
			"type":"operator",
			"syntax":[
				"subpath <mStart> [ to <mEnd> ] of <mPath>"
			],
			"display syntax":[
				"subpath <i>mStart</i> [ to <i>mEnd</i> ] of <i>mPath</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The subpaths of a path.",
			"parameters":[{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			},{
				"name":"mStart",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mEnd",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			}],
			"examples":[{
				"script":"// Create a path with multiple subpaths\nvariable tPath as Path\nput path \"M50,50 L100,50 M100,100 L150,100 M150,150 L200,150\"\n\n// Split out the first subpath of a path\nvariable tSubPath as Path\nput subpath 1 of tPath into tSubPath\n\n// Store the remaining subpaths in the original path\nput subpath 2 to -1 of tPath into tPath"
			}],
			"description":"The subpaths of <mPath> in the range <mStart> to <mEnd>. Each subpath or range of subpaths is itself a path.",
			"tags":["Canvas"]
		},{
			"id":"220",
			"name":"transformpropertyskew",
			"display name":"TransformPropertySkew",
			"type":"operator",
			"syntax":[
				"the skew of <mTransform>"
			],
			"display syntax":[
				"the skew of <i>mTransform</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The skew component of a transform.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			}],
			"examples":[{
				"script":"variable tTransform\nput transform with matrix [0, 2, -2, 0, 50, 100] into tTransform\n\n// Store the old skew component\nvariable tSkew\nput the skew of tTransform into tSkew\n\n// Remove the skew\nset the skew of tTransform to [0,0]"
			}],
			"description":"The skew of <mTransform> as a list of 2 numbers (the x and y skew values).",
			"tags":["Canvas"]
		},{
			"id":"221",
			"name":"canvaspropertydashphase",
			"display name":"CanvasPropertyDashPhase",
			"type":"operator",
			"syntax":[
				"the dash phase of <mCanvas>"
			],
			"display syntax":[
				"the dash phase of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current dash phase of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Draw a rectangle with short, widely spaced dashes, offset to begin from the middle of the dash pattern\nset the dashes of this canvas to [10, 40]\nset the dash phase of this canvas to 25\nstroke rectangle path of rectangle [50, 50, 200, 200] on this canvas"
			}],
			"description":"The offset into the dashes at which to begin applying the dash pattern.",
			"tags":["Canvas"]
		},{
			"id":"222",
			"name":"canvasoperationlineto",
			"display name":"CanvasOperationLineTo",
			"type":"statement",
			"syntax":[
				"line to <mPoint> on <mCanvas>"
			],
			"display syntax":[
				"line to <i>mPoint</i> on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Add a line to a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			},{
				"name":"mPoint",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			}],
			"examples":[{
				"script":"// move to a point on the canvas\nmove to point [0,50] on this canvas\n\n// add a line to the canvas path\nline to point [50,50] on this canvas\n\n// stroke the canvas path\nstroke this canvas"
			}],
			"description":"Adds a line to <mPoint> on the current path of <mCanvas>",
			"tags":["Canvas"]
		},{
			"id":"223",
			"name":"canvasoperationtranslate",
			"display name":"CanvasOperationTranslate",
			"type":"statement",
			"syntax":[
				"translate <mCanvas> by <mTranslation>"
			],
			"display syntax":[
				"translate <i>mCanvas</i> by <i>mTranslation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a translation to a canvas.",
			"parameters":[{
				"name":"mTranslation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			},{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Translate the canvas\ntranslate this canvas by [50,100]"
			}],
			"description":"Translates the transform of <mCanvas> by <mTranslation>.",
			"tags":["Canvas"]
		},{
			"id":"224",
			"name":"pathoperationtranslate",
			"display name":"PathOperationTranslate",
			"type":"statement",
			"syntax":[
				"translate <mPath> by <mTranslation>"
			],
			"display syntax":[
				"translate <i>mPath</i> by <i>mTranslation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a translation to a path.",
			"parameters":[{
				"name":"mTranslation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			},{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Create a rectangle path\nvariable tPath as Path\nput rectangle path of rectangle [10,10,210,60] into tPath\n\n// Translate the path\ntranslate tPath by [50,100]"
			}],
			"description":"Translates <mPath> by <mTranslation>.",
			"tags":["Canvas"]
		},{
			"id":"225",
			"name":"canvasoperationmoveto",
			"display name":"CanvasOperationMoveTo",
			"type":"statement",
			"syntax":[
				"move to <mPoint> on <mCanvas>"
			],
			"display syntax":[
				"move to <i>mPoint</i> on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Move to a point on a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			},{
				"name":"mPoint",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			}],
			"examples":[{
				"script":"// move to a point on the canvas\nmove to point [0,50] on this canvas\n\n// add a line to the canvas path\nline to point [50,50] on this canvas\n\n// stroke the canvas path\nstroke this canvas"
			}],
			"description":"Moves to <mPoint> on the current path of <mCanvas>",
			"tags":["Canvas"]
		},{
			"id":"226",
			"name":"pathmakewithcircle",
			"display name":"PathMakeWithCircle",
			"type":"operator",
			"syntax":[
				"circle path centered at <mCenter> with radius <mRadius>"
			],
			"display syntax":[
				"circle path centered at <i>mCenter</i> with radius <i>mRadius</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new path.",
			"parameters":[{
				"name":"mCenter",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mRadius",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			}],
			"examples":[{
				"script":"// Create a circle path\nvariable tPath as Path\nput circle path centered at point [100,100] with radius 50 into tPath"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new circle path."
			}],
			"tags":["Canvas"]
		},{
			"id":"227",
			"name":"transformoperationmultiply",
			"display name":"TransformOperationMultiply",
			"type":"operator",
			"syntax":[
				"<Left> * <Right>"
			],
			"display syntax":[
				"<i>Left</i> * <i>Right</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Multiply two transforms together.",
			"parameters":[{
				"name":"Left",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			},{
				"name":"Right",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			}],
			"examples":[{
				"script":"// Create a rotation transform\nvariable tRotate\nput transform with rotation by 45 into tRotate\n\n// Create a scale transform\nvariable tScale\nput transform with scale [2,3] into tScale\n\n// Create a translation transform\nvariable tTranslate\nput transform with translation [50,100] into tTranslate\n\n// Combine transforms by multiplying them together\nvariable tTransform\nput tTranslate * tRotate * tScale into tTransform"
			}],
			"description":"Returns the transform created by concatentating <Left> with <Right>\nNote:The order of the arguments is important when multiplying transforms. <Left> * <Right> can result in a different transform from <Right> * <Left> (in mathematical terms, transform multiplication is non-commutative).",
			"tags":["Canvas"]
		},{
			"id":"228",
			"name":"transformoperationskew",
			"display name":"TransformOperationSkew",
			"type":"statement",
			"syntax":[
				"skew <mTransform> by <mSkew>"
			],
			"display syntax":[
				"skew <i>mTransform</i> by <i>mSkew</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a skew to a transform.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			},{
				"name":"mSkew",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of 2 numbers, the x-axis skew and y-axis skew."
			}],
			"examples":[{
				"script":"variable tTransform\n// Create a new transform\nput the identity transform into tTransform\n// Apply a skew to the transform\nskew tTransform by [1, 0]"
			}],
			"description":"Apply the given skew to <mTransform>",
			"tags":["Canvas"]
		},{
			"id":"229",
			"name":"canvaspropertyfont",
			"display name":"CanvasPropertyFont",
			"type":"operator",
			"syntax":[
				"the font of <mCanvas>"
			],
			"display syntax":[
				"the font of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current font of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Use 20pt Arial for text drawing on canvas\nset the font of this canvas to font \"Arial\" at size 20"
			}],
			"description":"The font used when drawing text on <mCanvas> as a font.",
			"tags":["Canvas"]
		},{
			"id":"230",
			"name":"pathoperationcurvethrough",
			"display name":"PathOperationCurveThrough",
			"type":"statement",
			"syntax":[
				"curve through <mThroughA> [ then <mThroughB> ] to <mTo> on <mPath>"
			],
			"display syntax":[
				"curve through <i>mThroughA</i> [ then <i>mThroughB</i> ] to <i>mTo</i> on <i>mPath</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Adds a curve to a path.",
			"parameters":[{
				"name":"mThroughA",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mThroughB",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mTo",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Create a new empty path\nvariable tPath as Path\nput the empty path into tPath\n\n// Begin a new subpath of tPath\nmove to point [25, 50] on tPath\n\n// Continue path with a curve through 25,100 to 50,100\ncurve through [25,100] to [50,100] on tPath\n\n// Continue path with a curve through 50,75 then 50,50 to 50,100\ncurve through [50,75] then [50,50] to [25,50] on tPath"
			}],
			"description":"Adds a curve from the previous point through one or two control points to <mTo> on <mPath>.",
			"tags":["Canvas"]
		},{
			"id":"231",
			"name":"canvaspropertystippled",
			"display name":"CanvasPropertyStippled",
			"type":"operator",
			"syntax":[
				"the stippled of <mCanvas>"
			],
			"display syntax":[
				"the stippled of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current stippled setting of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Draw with stippled red paint on canvas\nset the paint of this canvas to solid paint with color [1,0,0]\nset the stippled of this canvas to true"
			}],
			"description":"A boolean value that determines whether or not stippling will be used when drawing with a solid color paint on <mCanvas>.",
			"tags":["Canvas"]
		},{
			"id":"232",
			"name":"canvasoperationfilltextaligned",
			"display name":"CanvasOperationFillTextAligned",
			"type":"statement",
			"syntax":[
				"fill text <mText> at <mAlignment> of <mRect> on <mCanvas>"
			],
			"display syntax":[
				"fill text <i>mText</i> at <i>mAlignment</i> of <i>mRect</i> on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Render filled text on a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			},{
				"name":"mText",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"mRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			}],
			"examples":[{
				"script":"// Set the canvas font\nset the font of this canvas to font \"Helvetica\"\n\n// Draw the text in the top-left corner of the target rectangle\nfill text \"Widget Label\" at top left of rectangle [50, 100, 250, 200] on this canvas"
			}],
			"description":"Renders <mText> aligned to the specified sides of <mRect> on <mCanvas> using the current font setting.",
			"tags":["Canvas"]
		},{
			"id":"233",
			"name":"canvaspropertyfillrule",
			"display name":"CanvasPropertyFillRule",
			"type":"operator",
			"syntax":[
				"the fill rule of <mCanvas>"
			],
			"display syntax":[
				"the fill rule of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current fill rule of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Set canvas fill rule to non-zero.\nset the fill rule of this canvas to \"non-zero\""
			}],
			"description":"The rule used to determine when to fill enclosed regions of a path. Can be \"even odd\" or \"non-zero\".",
			"tags":["Canvas"]
		},{
			"id":"234",
			"name":"transformoperationscale",
			"display name":"TransformOperationScale",
			"type":"statement",
			"syntax":[
				"scale <mTransform> by <mScale>"
			],
			"display syntax":[
				"scale <i>mTransform</i> by <i>mScale</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a scale to a transform.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			},{
				"name":"mScale",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of 1 or 2 numbers, the x-axis scale and y-axis scale, or the uniform scale when only a single value is given."
			}],
			"examples":[{
				"script":"// Create a new transform\nvariable tTransform\nput the identity transform into tTransform\n\n// Apply a uniform scale to the transform\nscale tTransform by [0.5]\n\n// Apply a non-uniform scale to the transform\nscale tTransform by [2.2, 3]"
			}],
			"description":"Apply the given scale to <mTransform>. This is equivalent to concatenating <mTransform> with a new scale transform.",
			"tags":["Canvas"]
		},{
			"id":"235",
			"name":"canvaspropertyimageresizequality",
			"display name":"CanvasPropertyImageResizeQuality",
			"type":"operator",
			"syntax":[
				"the image resize quality of <mCanvas>"
			],
			"display syntax":[
				"the image resize quality of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current image resize quality of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Use low (but faster) image resize algorithm to draw scaled images\nset the image resize quality of this canvas to \"low\""
			}],
			"description":"The image resize quality used when drawing scaled images and patterns on <mCanvas> as a string. Can be one of \"none\", \"low\", \"medium\", \"high\".",
			"tags":["Canvas"]
		},{
			"id":"236",
			"name":"canvasoperationscale",
			"display name":"CanvasOperationScale",
			"type":"statement",
			"syntax":[
				"scale <mCanvas> by <mScale>"
			],
			"display syntax":[
				"scale <i>mCanvas</i> by <i>mScale</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a scale to a canvas.",
			"parameters":[{
				"name":"mScale",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			},{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Scale the canvas\nscale this canvas by [2,2]"
			}],
			"description":"Scales the transform of <mCanvas> by <mScale>.",
			"tags":["Canvas"]
		},{
			"id":"237",
			"name":"transformpropertyinverse",
			"display name":"TransformPropertyInverse",
			"type":"operator",
			"syntax":[
				"the inverse of <mTransform>"
			],
			"display syntax":[
				"the inverse of <i>mTransform</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The inverse of a transform.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			}],
			"examples":[{
				"script":"variable tTransform\nput transform with matrix [0,2,-2,0,50,100] into tTransform\n\n// Get the inverse of the current transform\nvariable tInverse\nput the inverse of tTransform into tInverse\n\n// Combine the transform with its inverse to produce the identity transform\nconcat tTransform with tInverse"
			}],
			"description":"The inverse of <mTransform>\n\n>*Note:* The inverse of a transform matrix is the transform that reverses the effect of the original. Combining a transform with its inverse will produce the identity transform.",
			"tags":["Canvas"]
		},{
			"id":"238",
			"name":"transformmakewithmatrixaslist",
			"display name":"TransformMakeWithMatrixAsList",
			"type":"operator",
			"syntax":[
				"transform with matrix <mMatrix>"
			],
			"display syntax":[
				"transform with matrix <i>mMatrix</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new transform.\nmTranslation:An expression which evaluates to a list of 6 numbers, the a, b, c, d, tx and ty values of the transform matrix.",
			"examples":[{
				"script":"// Create combined rotate, scale, and translate transform\nvariable tTransform\nput transform with matrix [0, 2, -2, 0, 50, 100] into tTransform"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new translation transform."
			}],
			"tags":["Canvas"]
		},{
			"id":"239",
			"name":"colorpropertygreen",
			"display name":"ColorPropertyGreen",
			"type":"operator",
			"syntax":[
				"the green of <mColor>"
			],
			"display syntax":[
				"the green of <i>mColor</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The green component of a color value.",
			"parameters":[{
				"name":"mColor",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a color."
			}],
			"examples":[{
				"script":"variable tColor\nput color [0.75, 1.0, 0.5] into tColor\n\n// Store the old green value\nvariable tGreen\nput the green of tColor into tGreen\n\n// Remove any green component from the color\nset the green of tColor to 0"
			}],
			"description":"The green component of <mColor>\n\n>*Note:* The component value denotes the intensity of that component, expressed as a real number between 0 and 1.",
			"tags":["Canvas"]
		},{
			"id":"240",
			"name":"transformpropertymatrixaslist",
			"display name":"TransformPropertyMatrixAsList",
			"type":"operator",
			"syntax":[
				"the matrix of <mTransform>"
			],
			"display syntax":[
				"the matrix of <i>mTransform</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The matrix values of a transform.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			}],
			"examples":[{
				"script":"variable tTransform\nput transform with translation [20,50] into tTransform\n\n// Get the current transform matrix\nvariable tMatrix\nput the matrix of tTransform into tMatrix\n\n// Directly set the components\nput 2.5 into element 1 of tMatrix\nput 0 into element 2 of tMatrix\nput 0 into element 3 of tMatrix\nput 2.5 into element 4 of tMatrix\n\n// Update the transform with the new values\nset the matrix of tTransform to tMatrix"
			}],
			"description":"The matrix values of <mTransform> as a list of 6 numbers.",
			"tags":["Canvas"]
		},{
			"id":"241",
			"name":"patternmaketransformed",
			"display name":"PatternMakeTransformed",
			"type":"operator",
			"syntax":[
				"pattern with <mImage> transformed by <mTransform>"
			],
			"display syntax":[
				"pattern with <i>mImage</i> transformed by <i>mTransform</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new transformed pattern paint.",
			"parameters":[{
				"name":"mImage",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an image."
			},{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			}],
			"examples":[{
				"script":"// Load the pattern image.\nvariable tImage\nput image from file \"images/backgroundpattern.png\" into tImage\n\n// Set up the pattern transform\nvariable tTransform\nput transform from matrix [0,2,-2,0,0,0] into tTransform\n\n// Create a new pattern paint, applying a transform to the image\nvariable tPaint\nput pattern with tImage transformed by tTransform into tPaint"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new pattern paint based on <mImage> with the specified transform applied."
			}],
			"tags":["Canvas"]
		},{
			"id":"242",
			"name":"transformpropertyscale",
			"display name":"TransformPropertyScale",
			"type":"operator",
			"syntax":[
				"the scale of <mTransform>"
			],
			"display syntax":[
				"the scale of <i>mTransform</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The scale component of a transform.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			}],
			"examples":[{
				"script":"variable tTransform\nput transform with matrix [0, 2, -2, 0, 50, 100] into tTransform\n\n// Store the old scale component\nvariable tScale\nput the scale of tTransform into tScale\n\n// Modify the scale by adding 1 to the x scale value\nset the scale of tTransform to [element 1 of tScale + 1, element 2 of tScale]"
			}],
			"description":"The scale of <mTransform> as a list of 2 numbers (the x and y scales)",
			"tags":["Canvas"]
		},{
			"id":"243",
			"name":"fontoperationtextimagebounds",
			"display name":"FontOperationTextImageBounds",
			"type":"operator",
			"syntax":[
				"the image bounds of text <mText> with <mFont>"
			],
			"display syntax":[
				"the image bounds of text <i>mText</i> with <i>mFont</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Measure text precisely when drawn with a font.",
			"parameters":[{
				"name":"mText",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"mFont",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a font."
			}],
			"examples":[{
				"script":"// Set up tFont as size 18 Arial\nvariable tFont as Font\nput font \"Arail\" at size 18 into tFont\n\n// Measure text with tFont\nvariable tBounds as Rectangle\nput the image bounds of text \"Sample text\" with tFont into tBounds"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The bounding box of <mText> when drawn at point 0,0 with font <mFont>. Returns the bounds as a rectangle."
			}],
			"description":"The exact bounds of the text, which will fully enclose each character.\n\n>*Note:* This can be more time-consuming to compute than the layout bounds.",
			"tags":["Canvas"]
		},{
			"id":"244",
			"name":"fontmakewithstyle",
			"display name":"FontMakeWithStyle",
			"type":"expression",
			"syntax":[
				"font <mName> with ( bold  | italic  | bold italic  ) style"
			],
			"display syntax":[
				"font <i>mName</i> with ( bold  | italic  | bold italic  ) style"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new instance of the named font.",
			"parameters":[{
				"name":"mName",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"// Create italic Arial font\nvariable tFont as Font\nput font \"Arial\" with italic style into tFont"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new instance of the named font with style bold, italic, or bold italic, and the default size of 12pts."
			}],
			"tags":["Canvas"]
		},{
			"id":"245",
			"name":"rectanglepropertyright",
			"display name":"RectanglePropertyRight",
			"type":"operator",
			"syntax":[
				"the right of <mRect>"
			],
			"display syntax":[
				"the right of <i>mRect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The right edge of a rectangle value.",
			"parameters":[{
				"name":"mRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			}],
			"examples":[{
				"script":"variable tRect\nput rectangle [50,100,150,200] into tRect\n\n// Store the right edge of the rectangle in a variable\nvariable tRight\nput the right of tRect into tRight\n\n// Move the rectangle horizontally to a new position.\nset the right of tRect to (tRight + 10)"
			}],
			"description":"The location along the x-axis of the right edge of the rectangle.\n\n>*Note:* Setting the right of a rectangle will reposition it without altering the width or height.",
			"tags":["Canvas"]
		},{
			"id":"246",
			"name":"canvasoperationdrawimage",
			"display name":"CanvasOperationDrawImage",
			"type":"statement",
			"syntax":[
				"draw [ from <mSrcRect> of ] <mImage> into <mDestRect> of <mCanvas>"
			],
			"display syntax":[
				"draw [ from <i>mSrcRect</i> of ] <i>mImage</i> into <i>mDestRect</i> of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Draw an image on a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			},{
				"name":"mImage",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an image."
			},{
				"name":"mSrcRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			},{
				"name":"mDestRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			}],
			"examples":[{
				"script":"// Load an image from a file\nvariable tImage as Image\nput image from file \"images/logo.png\" into tImage\n\n// Draw the image on the canvas\ndraw tImage into rectangle [0,0,the width of tImage,the height of tImage] of this canvas"
			},{
				"script":"// Load an image from a file\nvariable tImage as Image\nput image from file \"images/logo.png\" into tImage\n\n// Draw a section of the image\ndraw from rectangle[0,0,16,16] of tImage into rectangle [0,0,16,16] of this canvas"
			}],
			"description":"Renders from <mSrcRect> (or the bounds, if not specified) of <mImage> into <mDestRect> of <mCanvas>. The canvas image resize quality determines how the image is scaled if necessary.",
			"tags":["Canvas"]
		},{
			"id":"247",
			"name":"gradientoperationscale",
			"display name":"GradientOperationScale",
			"type":"statement",
			"syntax":[
				"scale <mGradient> by <mScale>"
			],
			"display syntax":[
				"scale <i>mGradient</i> by <i>mScale</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a scale to a gradient paint.",
			"parameters":[{
				"name":"mScale",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			},{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\n// Scale the gradient\nscale tGradient by [2,2]"
			}],
			"description":"Scales the transform of <mGradient> by <mScale>.",
			"tags":["Canvas"]
		},{
			"id":"248",
			"name":"colorpropertyalpha",
			"display name":"ColorPropertyAlpha",
			"type":"operator",
			"syntax":[
				"the alpha of <mColor>"
			],
			"display syntax":[
				"the alpha of <i>mColor</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The alpha component of a color value.",
			"parameters":[{
				"name":"mColor",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a color."
			}],
			"examples":[{
				"script":"variable tColor\nput color [0.75, 1.0, 0.5] into tColor\n\n// Store the old alpha value\nvariable tAlpha\nput the alpha of tColor into tAlpha\n\n// Make the color semi-transparent\nset the alpha of tColor to 0.5"
			}],
			"description":"The alpha component of <mColor>\n\n>*Note:* The alpha value represents the opacity of the color, expressed as a real number between 0 (fully transparent) and 1 (fully opaque).",
			"tags":["Canvas"]
		},{
			"id":"249",
			"name":"pathoperationtransform",
			"display name":"PathOperationTransform",
			"type":"statement",
			"syntax":[
				"transform <mPath> by <mTransform>"
			],
			"display syntax":[
				"transform <i>mPath</i> by <i>mTransform</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a transform to a path.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			},{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Create a rectangle path\nvariable tPath as Path\nput rectangle path of rectangle [10,10,210,60] into tPath\n\n// Scale the path with a transform\ntransform tPath by transform with scale [2,2]"
			}],
			"description":"Transforms the points of <mPath> with <mTransform>.",
			"tags":["Canvas"]
		},{
			"id":"250",
			"name":"pathoperationclosepath",
			"display name":"PathOperationClosePath",
			"type":"statement",
			"syntax":[
				"close path on <mPath>"
			],
			"display syntax":[
				"close path on <i>mPath</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Closes the current subpath of a path.",
			"parameters":[{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Create a new empty path\nvariable tPath as Path\nput the empty path into tPath\n\n// Begin a new subpath of tPath\nmove to point [25, 50] on tPath\n\n// Continue path with a curve through 25,100 to 50,100\ncurve through [25,100] to [50,100] on tPath\n\n// Close the path\nclose path on tPath"
			}],
			"description":"Adds a line from the previous point to the start of current subpath, signaling the end of the subpath.",
			"tags":["Canvas"]
		},{
			"id":"251",
			"name":"gradientpropertyto",
			"display name":"GradientPropertyTo",
			"type":"operator",
			"syntax":[
				"the to of <mGradient>"
			],
			"display syntax":[
				"the to of <i>mGradient</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The to point of a gradient paint.",
			"parameters":[{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\nvariable tRect\nput rectangle [ 20, 10, 120, 60 ] into tRect\n\n// Set the end point of the gradient to the right of tRect\nset the from of tGradient to point [the right of tRect, (the top of tRect + the bottom of tRect) / 2]"
			}],
			"description":"The to point of <mGradient> as a point. Defines the end point when drawing the gradient.",
			"tags":["Canvas"]
		},{
			"id":"252",
			"name":"effectpropertytype",
			"display name":"EffectPropertyType",
			"type":"operator",
			"syntax":[
				"the type of <mEffect>"
			],
			"display syntax":[
				"the type of <i>mEffect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The type of an effect.",
			"parameters":[{
				"name":"mEffect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an effect."
			}],
			"examples":[{
				"script":"// Create an outer shadow effect\nvariable tEffect as Effect\nput outer shadow effect into tEffect\n\n// Get the type of the effect, in this case it will be \"outer shadow\"\nvariable tType as String\nput the type of tEffect into tType"
			}],
			"description":"The type of <mEffect> as a string. Can be one of \"color overlay\", \"inner shadow\", \"outer shadow\", \"inner glow\", \"outer glow\".",
			"tags":["Canvas"]
		},{
			"id":"253",
			"name":"transformmakerotation",
			"display name":"TransformMakeRotation",
			"type":"operator",
			"syntax":[
				"transform with rotation by <mRotation>"
			],
			"display syntax":[
				"transform with rotation by <i>mRotation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new rotation transform value.",
			"parameters":[{
				"name":"mRotation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number, the number of degrees of the rotation."
			}],
			"examples":[{
				"script":"// Create 30 degree rotation transform\nvariable tTransform\nput transform with rotation by 30 into tTransform"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new rotation transform."
			}],
			"tags":["Canvas"]
		},{
			"id":"254",
			"name":"rectanglepropertybottom",
			"display name":"RectanglePropertyBottom",
			"type":"operator",
			"syntax":[
				"the bottom of <mRect>"
			],
			"display syntax":[
				"the bottom of <i>mRect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The bottom edge of a rectangle value.",
			"parameters":[{
				"name":"mRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			}],
			"examples":[{
				"script":"variable tRect\nput rectangle [50,100,150,200] into tRect\n\n// Store the bottom edge of the rectangle in a variable\nvariable tBottom\nput the bottom of tRect into tBottom\n\n// Move the rectangle vertically to a new position.\nset the bottom of tRect to (tBottom + 10)"
			}],
			"description":"The location along the y-axis of the bottom edge of the rectangle.\n\n>*Note:* Setting the bottom of a rectangle will reposition it without altering the width or height.",
			"tags":["Canvas"]
		},{
			"id":"255",
			"name":"canvasoperationfilltext",
			"display name":"CanvasOperationFillText",
			"type":"statement",
			"syntax":[
				"fill text <mText> at <mPoint> on <mCanvas>"
			],
			"display syntax":[
				"fill text <i>mText</i> at <i>mPoint</i> on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Render filled text on a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			},{
				"name":"mText",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"mPoint",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			}],
			"examples":[{
				"script":"// Set the canvas font\nset the font of this canvas to font \"Helvetica\"\n\n// Draw the text\nfill text \"Widget Label\" at point [50,50] on this canvas"
			}],
			"description":"Renders <mText> at <mPoint> on <mCanvas> using the current font setting.",
			"tags":["Canvas"]
		},{
			"id":"256",
			"name":"canvasoperationbeginlayer",
			"display name":"CanvasOperationBeginLayer",
			"type":"statement",
			"syntax":[
				"begin layer [ with <mEffect> ] on <mCanvas>"
			],
			"display syntax":[
				"begin layer [ with <i>mEffect</i> ] on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Begin a new drawing layer on a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			},{
				"name":"mEffect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an effect."
			}],
			"examples":[{
				"script":"// Draw two overlapping rectangles grouped with half transparency\nset the opacity of this canvas to 0.5\nbegin layer on this canvas\nfill rectangle path of rectangle path [50,50,100,100] on this canvas\nfill rectangle path of rectangle path [75,75,125,125] on this canvas\nend layer on this canvas"
			},{
				"script":"// Create an effect for the new layer\nvariable tEffect as Effect\nput outer shadow effect into tEffect\n\n// Draw rectangle with an effect applied\nbegin layer with tEffect on this canvas\nfill rectangle path of rectangle [50,50,100,100] on this canvas\nend layer on this canvas"
			}],
			"description":"Begins a new layer on <mCanvas> to group drawing operations for which the opacity, blend mode, and optional effect are to be applied to as a whole rather than individually.",
			"tags":["Canvas"]
		},{
			"id":"257",
			"name":"canvasoperationsavestate",
			"display name":"CanvasOperationSaveState",
			"type":"statement",
			"syntax":[
				"save state of <mCanvas>"
			],
			"display syntax":[
				"save state of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Save the current state of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Save the current canvas properties\nsave state of this canvas\n\n// Change various properties of the canvas\nset the paint of this canvas to solid paint with color [1,1,0,0.5]\nset the blend mode of this canvas to \"color dodge\"\nrotate this canvas by 30\nset the font of this canvas to font \"Helvetica\" with size 15\n\n// Restore the previous canvas properties\nrestore state of this canvas"
			}],
			"description":"Saves the current properties of <mCanvas> to the top of a stack so that they can be restored later.",
			"tags":["Canvas"]
		},{
			"id":"258",
			"name":"canvasoperationcurvethrough",
			"display name":"CanvasOperationCurveThrough",
			"type":"statement",
			"syntax":[
				"curve through <mThroughA> [ then <mThroughB> ] to <mPoint> on <mCanvas>"
			],
			"display syntax":[
				"curve through <i>mThroughA</i> [ then <i>mThroughB</i> ] to <i>mPoint</i> on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Add a curve to a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			},{
				"name":"mThroughA",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mThroughA",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			}],
			"examples":[{
				"script":"// Begin a new subpath on the canvas\nmove to point [25, 50] on this canvas\n\n// Continue path with a curve through 25,100 to 50,100\ncurve through [25,100] to [50,100] on this canvas\n\n// Continue path with a curve through 50,75 then 50,50 to 50,100\ncurve through [50,75] then [50,50] to [25,50] on this canvas\n\n// stroke the canvas path\nstroke this canvas"
			}],
			"description":"Adds a curve through 1 or 2 points to <mPoint> on the current path of <mCanvas>",
			"tags":["Canvas"]
		},{
			"id":"259",
			"name":"canvasoperationrotate",
			"display name":"CanvasOperationRotate",
			"type":"statement",
			"syntax":[
				"rotate <mCanvas> by <mRotation>"
			],
			"display syntax":[
				"rotate <i>mCanvas</i> by <i>mRotation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a rotation to a canvas.",
			"parameters":[{
				"name":"mRotation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Rotate the canvas\nrotate this canvas by 45"
			}],
			"description":"Rotates the transform of <mCanvas> by <mRotation> degrees.",
			"tags":["Canvas"]
		},{
			"id":"260",
			"name":"pointpropertyy",
			"display name":"PointPropertyY",
			"type":"operator",
			"syntax":[
				"the y of <mPoint>"
			],
			"display syntax":[
				"the y of <i>mPoint</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The y coordinate of a point value.",
			"parameters":[{
				"name":"mPoint",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			}],
			"examples":[{
				"script":"variable tPoint\nput point [50, 100] into tPoint\n\n// Store the y-coordinate of the point in a variable\nvariable tY\nput the y of tPoint into tY\n\n// Move the point 10 units downward.\nset the y of tPoint to (tY + 10)"
			}],
			"description":"The y coordinate of <mPoint>.",
			"tags":["Canvas"]
		},{
			"id":"261",
			"name":"fontmakewithstyleandsize",
			"display name":"FontMakeWithStyleAndSize",
			"type":"operator",
			"syntax":[
				"font <mName> with ( bold  | italic  | bold italic  ) style at size <mSize>"
			],
			"display syntax":[
				"font <i>mName</i> with ( bold  | italic  | bold italic  ) style at size <i>mSize</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new instance of the named font.",
			"parameters":[{
				"name":"mName",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"mSize",
				"type":"",
				"refparam":"false",
				"description":"An Expression which evaluates to a number."
			}],
			"examples":[{
				"script":"// Create 20pt bold Arial font\nvariable tFont as Font\nput font \"Arial\" with bold style at size 20 into tFont"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new instance of the named font with style bold, italic, or bold italic, at size <mSize> points."
			}],
			"tags":["Canvas"]
		},{
			"id":"262",
			"name":"thiscanvas",
			"display name":"ThisCanvas",
			"type":"expression",
			"syntax":[
				"this canvas"
			],
			"display syntax":[
				"this canvas"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The canvas used when drawing a widget.",
			"examples":[{
				"script":"// Draw the label centered on the rect of the widget\nset the paint of this canvas to solid paint with color [1,1,1]\nfill text \"Start\" at center of my rectangle on this canvas"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The target canvas for widget drawing operations."
			}],
			"tags":["Canvas"]
		},{
			"id":"263",
			"name":"pointmake",
			"display name":"PointMake",
			"type":"operator",
			"syntax":[
				"point <mPoint>"
			],
			"display syntax":[
				"point <i>mPoint</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new point value.",
			"parameters":[{
				"name":"mPoint",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of 2 numbers, the x and y coordinates of the point."
			}],
			"examples":[{
				"script":"variable tPoint\nput point [50, 100] into tPoint"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new point with the given coordinates"
			}],
			"tags":["Canvas"]
		},{
			"id":"264",
			"name":"effectpropertyopacity",
			"display name":"EffectPropertyOpacity",
			"type":"operator",
			"syntax":[
				"the opacity of <mEffect>"
			],
			"display syntax":[
				"the opacity of <i>mEffect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The opacity of an effect.",
			"parameters":[{
				"name":"mEffect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an effect."
			}],
			"examples":[{
				"script":"// Create an effect with opacity = 191 (75%)\nvariable tProps as Array\nput the empty array into tProps\n\nput 191 into tProps[\"opacity\"]\n\nvariable tEffect as Effect\nput outer shadow effect with properties tProps into tEffect\n\n// Use half-transparency for effect\nset the opacity of tEffect to 127"
			}],
			"description":"The opacity of <mEffect> as a number between 0 and 255.",
			"tags":["Canvas"]
		},{
			"id":"265",
			"name":"gradientmakewithramp",
			"display name":"GradientMakeWithRamp",
			"type":"operator",
			"syntax":[
				"<mType> gradient with ramp <mRamp>"
			],
			"display syntax":[
				"<i>mType</i> gradient with ramp <i>mRamp</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new gradient paint.",
			"parameters":[{
				"name":"mRamp",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of gradient stops."
			}],
			"examples":[{
				"script":"// List to hold gradient stops\nvariable tRamp\nput the empty list into tRamp\n\n// Set up gradient stops\npush gradient stop at 0 with color [1,0,0] onto tRamp\npush gradient stop at 0.5 with color [0,1,0,0.5] onto tRamp\npush gradient stop at 1 with color [0,0,1] onto tRamp\n\n// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp tRamp into tGradient"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new gradient paint."
			}],
			"tags":["Canvas"]
		},{
			"id":"266",
			"name":"patternoperationrotate",
			"display name":"PatternOperationRotate",
			"type":"statement",
			"syntax":[
				"rotate <mPattern> by <mRotation>"
			],
			"display syntax":[
				"rotate <i>mPattern</i> by <i>mRotation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a rotation to a pattern.",
			"parameters":[{
				"name":"mPattern",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a pattern."
			},{
				"name":"mRotation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number of degrees."
			}],
			"examples":[{
				"script":"// Create a new pattern paint from an image file\nvariable tPattern\nput pattern with image from file \"images/pattern.png\" into tPattern\n\n// Rotate the pattern through 30 degrees\nrotate tPattern by 30"
			}],
			"description":"Rotates the transform of <mPattern> by <mRotation>",
			"tags":["Canvas"]
		},{
			"id":"267",
			"name":"canvasoperationclip",
			"display name":"CanvasOperationClip",
			"type":"statement",
			"syntax":[
				"clip to <mRect> on <mCanvas>"
			],
			"display syntax":[
				"clip to <i>mRect</i> on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Clip to a rectangle on a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			},{
				"name":"mRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			}],
			"examples":[{
				"script":"// Set the canvas clip\nclip to rectangle [50,50,100,100] on this canvas\n\n// Fill rectangle path on canvas. only the region of the rectangle that falls within the canvas clip will be rendered.\nfill rectangle path of rectangle [25, 25, 75, 75] on this canvas"
			}],
			"description":"Modifies the clip of <mCanvas> by intersecting with <mRect>. Drawing operations on <mCanvas> will be confined to the clip region.",
			"tags":["Canvas"]
		},{
			"id":"268",
			"name":"transformmakeidentity",
			"display name":"TransformMakeIdentity",
			"type":"expression",
			"syntax":[
				"the identity transform"
			],
			"display syntax":[
				"the identity transform"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The identity transform.",
			"examples":[{
				"script":"variable tTransform\nput the identity transform into tTransform"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new identity transform."
			}],
			"description":"The identity transform represents a coordinate transformation where the set of coordinates remain the same after it is applied. This can be useful when specifying that coordinates should not be altered, or as a starting point when combining transforms to produce a more complex one.",
			"tags":["Canvas"]
		},{
			"id":"269",
			"name":"pathmakewitharc",
			"display name":"PathMakeWithArc",
			"type":"operator",
			"syntax":[
				"arc path centered at <mCenter> with [ radius <mRadius> | radii <mRadii> ] from <mStartAngle> to <mEndAngle>"
			],
			"display syntax":[
				"arc path centered at <i>mCenter</i> with [ radius <i>mRadius</i> | radii <i>mRadii</i> ] from <i>mStartAngle</i> to <i>mEndAngle</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new path.",
			"parameters":[{
				"name":"mCenter",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mRadius",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mRadii",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			},{
				"name":"mStartAngle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mEndAngle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			}],
			"examples":[{
				"script":"// Create an elliptical arc path\nvariable tPath as Path\nput arc path centered at point [100,100] with radii [100,75] from 0 to 270 into tPath"
			},{
				"script":"// Create a circular arc path\nvariable tPath as Path\nput arc path centered at point [100,100] with radius 100 from 0 to 270 into tPath"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new arc path."
			}],
			"tags":["Canvas"]
		},{
			"id":"270",
			"name":"pathoperationscale",
			"display name":"PathOperationScale",
			"type":"statement",
			"syntax":[
				"scale <mPath> by <mScale>"
			],
			"display syntax":[
				"scale <i>mPath</i> by <i>mScale</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a scale to a path.",
			"parameters":[{
				"name":"mScale",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			},{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Create a rectangle path\nvariable tPath as Path\nput rectangle path of rectangle [10,10,210,60] into tPath\n\n// Scale the path\nscale tPath by [2,2]"
			}],
			"description":"Scales <mPath> by <mScale>.",
			"tags":["Canvas"]
		},{
			"id":"271",
			"name":"pathpropertyboundingbox",
			"display name":"PathPropertyBoundingBox",
			"type":"operator",
			"syntax":[
				"the bounding box of <mPath>"
			],
			"display syntax":[
				"the bounding box of <i>mPath</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The bounding box of a path.",
			"parameters":[{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Create a circle path\nvariable tPath as Path\nput circle path centered at point [100,100] with radius 50 into tPath\n\n// Get the bounds of the path\nvariable tBounds as Rectangle\nput the bounding box of tPath into tBounds"
			}],
			"description":"The smallest rectangle that competely encloses <mPath>.",
			"tags":["Canvas"]
		},{
			"id":"272",
			"name":"pointpropertyx",
			"display name":"PointPropertyX",
			"type":"operator",
			"syntax":[
				"the x of <mPoint>"
			],
			"display syntax":[
				"the x of <i>mPoint</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The x coordinate of a point value.",
			"parameters":[{
				"name":"mPoint",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			}],
			"examples":[{
				"script":"variable tPoint\nput point [50, 100] into tPoint\n\n// Store the x-coordinate of the point in a variable\nvariable tX\nput the x of tPoint into tX\n\n// Move the point 10 units to the right\nset the x of tPoint to (tX + 10)"
			}],
			"description":"The x coordinate of <mPoint>.",
			"tags":["Canvas"]
		},{
			"id":"273",
			"name":"gradientpropertywrap",
			"display name":"GradientPropertyWrap",
			"type":"operator",
			"syntax":[
				"the wrap of <mGradient>"
			],
			"display syntax":[
				"the wrap of <i>mGradient</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The wrap of a gradient paint.",
			"parameters":[{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\n// Toggle the wrapping of a gradient\nvariable tWrap\nput the wrap of tGradient into tWrap\nset the wrap of tGradient to not tWrap"
			}],
			"description":"The wrap of <mGradient> as a boolean. If wrap is true then the gradient ramp will be repeated continually outside the defined extent of the gradient.",
			"tags":["Canvas"]
		},{
			"id":"274",
			"name":"canvasoperationmeasuretext",
			"display name":"CanvasOperationMeasureText",
			"type":"statement",
			"syntax":[
				"measure <mText> on <mCanvas>"
			],
			"display syntax":[
				"measure <i>mText</i> on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Measure text when drawn to a canvas.",
			"parameters":[{
				"name":"mText",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Measure text drawn on the canvas\nvariable tBounds as Rectangle\nmeasure \"Sample text\" on this canvas\nput the result into tBounds"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The bounding box of <mText> when drawn at point 0,0 with the current font of <mCanvas>. Returns the bounds as a rectangle in the result."
			}],
			"tags":["Canvas"]
		},{
			"id":"275",
			"name":"effectmake",
			"display name":"EffectMake",
			"type":"expression",
			"syntax":[
				"<mType> effect"
			],
			"display syntax":[
				"<i>mType</i> effect"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new effect.",
			"parameters":[{
				"name":"mType",
				"type":"",
				"refparam":"false",
				"description":"One of color overlay, inner shadow, outer shadow, inner glow, outer glow."
			}],
			"examples":[{
				"script":"// Create an effect with default properties\nvariable tEffect as Effect\nput outer shadow effect into tEffect"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new effect of type <mType> with default property values."
			}],
			"tags":["Canvas"]
		},{
			"id":"276",
			"name":"gradientpropertytype",
			"display name":"GradientPropertyType",
			"type":"operator",
			"syntax":[
				"the type of <mGradient>"
			],
			"display syntax":[
				"the type of <i>mGradient</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The type of a gradient paint.",
			"parameters":[{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\n// Store the old gradient type\nvariable tType\nput the type of tGradient into tType\n\n// Change the gradient type to radial\nset the type of tGradient to \"radial\""
			}],
			"description":"The type of <mGradient> as a string. This can be one of \"linear\", \"radial\", \"conical\", \"diamond\", \"spiral\", \"xy\", \"sqrtxy\".",
			"tags":["Canvas"]
		},{
			"id":"277",
			"name":"rectanglepropertytop",
			"display name":"RectanglePropertyTop",
			"type":"operator",
			"syntax":[
				"the top of <mRect>"
			],
			"display syntax":[
				"the top of <i>mRect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The top edge of a rectangle value.",
			"parameters":[{
				"name":"mRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			}],
			"examples":[{
				"script":"variable tRect\nput rectangle [50,100,150,200] into tRect\n\n// Store the top edge of the rectangle in a variable\nvariable tTop\nput the top of tRect into tTop\n\n// Move the rectangle vertically to a new position.\nset the top of tRect to 120"
			}],
			"description":"The location along the y-axis of the top edge of the rectangle.\n\n>*Note:* Setting the top of a rectangle will reposition it without altering the width or height.",
			"tags":["Canvas"]
		},{
			"id":"278",
			"name":"colormake",
			"display name":"ColorMake",
			"type":"operator",
			"syntax":[
				"color <mColor>"
			],
			"display syntax":[
				"color <i>mColor</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new color value.",
			"parameters":[{
				"name":"mColor",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of 3 or 4 numbers, the red, green, blue, and (optional) alpha components of the color."
			}],
			"examples":[{
				"script":"variable tColor\n// Set tColor to opaque red\nput color [1.0, 0.0, 0.0] into tColor\n\n// Set tColor to partially transparent cyan\nput color [0.0, 1.0, 1.0, 0.75] into tColor"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new color with the given RGBA values."
			}],
			"description":">*Note:* The component value denotes the intensity of that component, expressed as a real number between 0 and 1. The alpha component represents the opacity of the color. If the alpha component is not specified then it is assumed to be 1 (fully opaque).",
			"tags":["Canvas"]
		},{
			"id":"279",
			"name":"canvasoperationstroke",
			"display name":"CanvasOperationStroke",
			"type":"statement",
			"syntax":[
				"stroke [ <mPath> on ] <mCanvas>"
			],
			"display syntax":[
				"stroke [ <i>mPath</i> on ] <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Stroke a path on a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			},{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Draw a circle path on the canvas\nstroke circle path centered at point [100,100] with radius 50 on this canvas"
			},{
				"script":"// Add a path to the canvas\nmove to point [50,50] on this canvas\nline to point [50,100] on this canvas\nline to point [100,100] on this canvas\n\n// Stroke the current canvas path\nstroke this canvas"
			}],
			"description":"Strokes <mPath> with the current canvas paint and stroke settings. If mPath is not specified then the current canvas path will be stroked, then emptied from the canvas.",
			"tags":["Canvas"]
		},{
			"id":"280",
			"name":"pathoperationlineto",
			"display name":"PathOperationLineTo",
			"type":"statement",
			"syntax":[
				"line to <mPoint> on <mPath>"
			],
			"display syntax":[
				"line to <i>mPoint</i> on <i>mPath</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Adds a line to a path.",
			"parameters":[{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			},{
				"name":"mPoint",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			}],
			"examples":[{
				"script":"// Create a new empty path\nvariable tPath as Path\nput the empty path into tPath\n\n// Begin a new subpath of tPath\nmove to point [25, 50] on tPath\n\n// Continue path with a line to 50,100\nline to [50,100] on tPath"
			}],
			"description":"Adds a line from the previous point to <mPoint> on <mPath>.",
			"tags":["Canvas"]
		},{
			"id":"281",
			"name":"transformmaketranslation",
			"display name":"TransformMakeTranslation",
			"type":"operator",
			"syntax":[
				"transform with translation <mTranslation>"
			],
			"display syntax":[
				"transform with translation <i>mTranslation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new translation transform.",
			"parameters":[{
				"name":"mTranslation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of 2 numbers, the x and y offsets of the translation."
			}],
			"examples":[{
				"script":"// Create translation transform to offset coordinates by 50,100\nvariable tTransform\nput transform with translation [50,100] into tTransform"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new translation transform."
			}],
			"tags":["Canvas"]
		},{
			"id":"282",
			"name":"gradientpropertymirror",
			"display name":"GradientPropertyMirror",
			"type":"operator",
			"syntax":[
				"the mirror of <mGradient>"
			],
			"display syntax":[
				"the mirror of <i>mGradient</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The mirror of a gradient paint.",
			"parameters":[{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\n// Toggle the mirroring of a gradient\nvariable tMirror\nput the mirror of tGradient into tMirror\nset the mirror of tGradient to not tMirror"
			}],
			"description":"The mirror of <mGradient> as a boolean. If mirror is true then the ramp will be reversed on each repeat.",
			"tags":["Canvas"]
		},{
			"id":"283",
			"name":"imagepropertywidth",
			"display name":"ImagePropertyWidth",
			"type":"operator",
			"syntax":[
				"the width of <mImage>"
			],
			"display syntax":[
				"the width of <i>mImage</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The width of an image.",
			"parameters":[{
				"name":"mImage",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an image."
			}],
			"examples":[{
				"script":"// Load an image from a file\nvariable tImage as Image\nput image from file \"images/logo.png\" into tImage\n\n// Get the image width\nvariable tWidth as Integer\nput the width of tImage into tWidth"
			}],
			"description":"The width of the image in pixels.",
			"tags":["Canvas"]
		},{
			"id":"284",
			"name":"patternoperationscale",
			"display name":"PatternOperationScale",
			"type":"statement",
			"syntax":[
				"scale <mPattern> by <mScale>"
			],
			"display syntax":[
				"scale <i>mPattern</i> by <i>mScale</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a scale to a pattern.",
			"parameters":[{
				"name":"mPattern",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a pattern."
			},{
				"name":"mScale",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of 1 or 2 numbers, the x-axis scale and y-axis scale, or the uniform scale when only a single value is given."
			}],
			"examples":[{
				"script":"// Create a new pattern paint from an image file\nvariable tPattern\nput pattern with image from file \"images/pattern.png\" into tPattern\n\n// Scale the pattern to twice the current width\nscale tPattern by [2,1]"
			}],
			"description":"Scales the transform of <mPattern> by <mScale>",
			"tags":["Canvas"]
		},{
			"id":"285",
			"name":"transformoperationconcat",
			"display name":"TransformOperationConcat",
			"type":"statement",
			"syntax":[
				"concat <mTransformA> with <mTransformB>"
			],
			"display syntax":[
				"concat <i>mTransformA</i> with <i>mTransformB</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Concatenate transform a with transform b.",
			"parameters":[{
				"name":"mTransformA",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			},{
				"name":"mTransformB",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			}],
			"examples":[{
				"script":"// Create a new scaling transform\nvariable tScale\nput transform with scale [5,10] into tScale\n\n// Create a new rotation transform\nvariable tRotation\nput transform with rotation by 30 into tRotation\n\nvariable tTransform\n\n// Create a transform representing a rotation followed by a scale\nput tScale into tTransform\nconcat tTransform with tRotation\n\n// Create a transform representing a scale followed by a rotation\nput tRotation into tTransform\nconcat tTransform with tScale"
			}],
			"description":"Concatenating transforms modifies the original transform to produce a single transform that is the equivalent of applying the new transform followed by the original. Changing the order of concatenation will result in a transform with different effects.",
			"tags":["Canvas"]
		},{
			"id":"286",
			"name":"colorpropertyred",
			"display name":"ColorPropertyRed",
			"type":"operator",
			"syntax":[
				"the red of <mColor>"
			],
			"display syntax":[
				"the red of <i>mColor</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The red component of a color value.",
			"parameters":[{
				"name":"mColor",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a color."
			}],
			"examples":[{
				"script":"variable tColor\nput color [0.75, 1.0, 0.5] into tColor\n\n// Store the old red value\nvariable tRed\nput the red of tColor into tRed\n\n// Invert the intensity of the red color component\nset the red of tColor to 1.0 - tRed"
			}],
			"description":"The red component of <mColor>\n\n>*Note:* The component value denotes the intensity of that component, expressed as a real number between 0 and 1.",
			"tags":["Canvas"]
		},{
			"id":"287",
			"name":"canvasoperationendlayer",
			"display name":"CanvasOperationEndLayer",
			"type":"statement",
			"syntax":[
				"end layer on <mCanvas>"
			],
			"display syntax":[
				"end layer on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"End the current drawing layer on a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Draw two overlapping rectangles grouped with half transparency\nset the opacity of this canvas to 0.5\nbegin layer on this canvas\nfill rectangle path of rectangle path [50,50,100,100] on this canvas\nfill rectangle path of rectangle path [75,75,125,125] on this canvas\nend layer on this canvas"
			},{
				"script":"// Create an effect for the new layer\nvariable tEffect as Effect\nput outer shadow effect into tEffect\n\n// Draw rectangle with an effect applied\nbegin layer with tEffect on this canvas\nfill rectangle path of rectangle [50,50,100,100] on this canvas\nend layer on this canvas"
			}],
			"description":"Ends the layer on <mCanvas>, rendering to the previous layer with the opacity, blend mode, and effect properties set when the layer began.",
			"tags":["Canvas"]
		},{
			"id":"288",
			"name":"imagepropertyheight",
			"display name":"ImagePropertyHeight",
			"type":"operator",
			"syntax":[
				"the height of <mImage>"
			],
			"display syntax":[
				"the height of <i>mImage</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The height of an image.",
			"parameters":[{
				"name":"mImage",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an image."
			}],
			"examples":[{
				"script":"// Load an image from a file\nvariable tImage as Image\nput image from file \"images/logo.png\" into tImage\n\n// Get the image height\nvariable tHeight as Integer\nput the height of tImage into tHeight"
			}],
			"description":"The height of the image in pixels.",
			"tags":["Canvas"]
		},{
			"id":"289",
			"name":"fontpropertyname",
			"display name":"FontPropertyName",
			"type":"operator",
			"syntax":[
				"the name of <mFont>"
			],
			"display syntax":[
				"the name of <i>mFont</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The name of a font.",
			"parameters":[{
				"name":"mFont",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a font."
			}],
			"examples":[{
				"script":"// Create a font\nvariable tFont as Font\nput font \"Arial\" at size 20 into tFont\n\n// Get the old font name\nvariable tFontName as String\nput the name of tFont into tName\n\n// Set the font to helvetica\nset the name of tFont to \"Helvetica\""
			}],
			"description":"The name of <mFont>.",
			"tags":["Canvas"]
		},{
			"id":"290",
			"name":"effectpropertyangle",
			"display name":"EffectPropertyAngle",
			"type":"operator",
			"syntax":[
				"the angle of <mEffect>"
			],
			"display syntax":[
				"the angle of <i>mEffect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The angle of an effect.",
			"parameters":[{
				"name":"mEffect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an effect."
			}],
			"examples":[{
				"script":"// Create an effect with angle 60\nvariable tProps as Array\nput the empty array into tProps\n\nput 60 into tProps[\"angle\"]\n\nvariable tEffect as Effect\nput outer shadow effect with properties tProps into tEffect\n\n// Set the effect angle\nset the angle of tEffect to 30"
			}],
			"description":"The angle of <mEffect> as a number of degrees. Angle applies to inner shadow, and outer shadow effect types",
			"tags":["Canvas"]
		},{
			"id":"291",
			"name":"patternoperationtransform",
			"display name":"PatternOperationTransform",
			"type":"statement",
			"syntax":[
				"transform <mPattern> by <mTransform>"
			],
			"display syntax":[
				"transform <i>mPattern</i> by <i>mTransform</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a transform to a pattern.",
			"parameters":[{
				"name":"mPattern",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a pattern."
			},{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			}],
			"examples":[{
				"script":"// Create a new pattern paint from an image file\nvariable tPattern\nput pattern with image from file \"images/pattern.png\" into tPattern\n\n// Apply transform to the pattern.\ntransform tPattern by transform with matrix [0,2,-2,0,5,10]"
			}],
			"description":"Modifies the transform of <mPattern> by concatentation with <mTransform>",
			"tags":["Canvas"]
		},{
			"id":"292",
			"name":"rectanglepropertywidth",
			"display name":"RectanglePropertyWidth",
			"type":"operator",
			"syntax":[
				"the width of <mRect>"
			],
			"display syntax":[
				"the width of <i>mRect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The width of a rectangle value.",
			"parameters":[{
				"name":"mRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			}],
			"examples":[{
				"script":"variable tRect\nput rectangle [50,100,150,200] into tRect\n\n// Store the width of the rectangle in a variable\nvariable tWidth\nput the width of tRect into tWidth\n\n// Increase the width of the rectangle\nset the width of tRect to (tWidth + 10)"
			}],
			"description":"The width of the rectangle.\n\n>*Note:* Setting the width of a rectangle will resize it without moving the left edge, expanding or contracting from the right.",
			"tags":["Canvas"]
		},{
			"id":"293",
			"name":"pathmakewithsegment",
			"display name":"PathMakeWithSegment",
			"type":"operator",
			"syntax":[
				"segment path centered at <mCenter> with [ radius <mRadius> | radii <mRadii> ] from <mStartAngle> to <mEndAngle>"
			],
			"display syntax":[
				"segment path centered at <i>mCenter</i> with [ radius <i>mRadius</i> | radii <i>mRadii</i> ] from <i>mStartAngle</i> to <i>mEndAngle</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new path.",
			"parameters":[{
				"name":"mCenter",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mRadius",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mRadii",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			},{
				"name":"mStartAngle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mEndAngle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			}],
			"examples":[{
				"script":"// Create an elliptical segment path\nvariable tPath as Path\nput segment path centered at point [100,100] with radii [100,75] from 0 to 270 into tPath"
			},{
				"script":"// Create a circular segment path\nvariable tPath as Path\nput segment path centered at point [100,100] with radius 100 from 0 to 270 into tPath"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new segment path."
			}],
			"tags":["Canvas"]
		},{
			"id":"294",
			"name":"patternmake",
			"display name":"PatternMake",
			"type":"operator",
			"syntax":[
				"pattern with <mImage>"
			],
			"display syntax":[
				"pattern with <i>mImage</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new pattern paint.",
			"parameters":[{
				"name":"mImage",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an image."
			}],
			"examples":[{
				"script":"// Load the pattern image.\nvariable tImage\nput image from file \"images/backgroundpattern.png\" into tImage\n\n// Create a new pattern based on the image\nvariable tPaint\nput pattern with tImage into tPaint"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new pattern paint based on <mImage>."
			}],
			"tags":["Canvas"]
		},{
			"id":"295",
			"name":"gradientoperationaddstop",
			"display name":"GradientOperationAddStop",
			"type":"statement",
			"syntax":[
				"add <mStop> to <mGradient>"
			],
			"display syntax":[
				"add <i>mStop</i> to <i>mGradient</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Add a new stop to the ramp of a gradient paint.",
			"parameters":[{
				"name":"mStop",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient stop"
			},{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint with empty ramp\nvariable tGradient\nput linear gradient with ramp [] into tGradient\n\n// Add stops to the gradient\nadd gradient stop at 0 with color [0,0,0] to tGradient\nadd gradient stop at 1 with color [1,1,1] to tGradient"
			}],
			"description":"Appends the stop to the ramp of <mGradient>. The offset of the new gradient should not be before the offset of the last stop.",
			"tags":["Canvas"]
		},{
			"id":"296",
			"name":"gradientoperationtranslate",
			"display name":"GradientOperationTranslate",
			"type":"statement",
			"syntax":[
				"translate <mGradient> by <mTranslation>"
			],
			"display syntax":[
				"translate <i>mGradient</i> by <i>mTranslation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a translation to a gradient paint.",
			"parameters":[{
				"name":"mTranslation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			},{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\n// Translate the gradient\ntranslate tGradient by [50,100]"
			}],
			"description":"Translates the transform of <mGradient> by <mTranslation>.",
			"tags":["Canvas"]
		},{
			"id":"297",
			"name":"gradientpropertytransform",
			"display name":"GradientPropertyTransform",
			"type":"operator",
			"syntax":[
				"the transform of <mGradient>"
			],
			"display syntax":[
				"the transform of <i>mGradient</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The transform of a gradient paint.",
			"parameters":[{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput radial gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\nvariable tRect\nput rectangle [ 20, 10, 120, 60 ] into tRect\n\n// Use the transform property to make the radial gradient spread out from the center of tRect\nvariable tTransform\nput the identity transform into tTransform\n\n// Offset transform to the center of tRect\ntranslate tTransform by [(the left of tRect + the right of tRect) / 2, (the top of tRect + the bottom of tRect) / 2]\n\n// Scale out to the right & bottom of tRect\nscale tTransform by [the width of tRect / 2, the height of tRect / 2]\n\n// Set the gradient transform\nset the transform of tGradient to tTransform"
			}],
			"description":"The transform of <mGradient> as a transform. This can be used to scale, position, and skew the gradient instead of setting the from, to, and via points.",
			"tags":["Canvas"]
		},{
			"id":"298",
			"name":"pathoperationmoveto",
			"display name":"PathOperationMoveTo",
			"type":"statement",
			"syntax":[
				"move to <mPoint> on <mPath>"
			],
			"display syntax":[
				"move to <i>mPoint</i> on <i>mPath</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Move to a new point on a path.",
			"parameters":[{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			},{
				"name":"mPoint",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			}],
			"examples":[{
				"script":"// Create a new empty path\nvariable tPath as Path\nput the empty path into tPath\n\n// Begin a new subpath of tPath\nmove to point [50, 50] on tPath\n\n// Add a line to tPath\nline to point [100, 50] on tPath\n\n// Begin a new subpath of tPath\nmove to point [50, 100] on tPath\n\n// Add a line to tPath\nline to point [100, 100] on tPath"
			}],
			"description":"Ends the current subpath and sets the starting point for new components of <mPath> to <mPoint>.",
			"tags":["Canvas"]
		},{
			"id":"299",
			"name":"canvasoperationclosepath",
			"display name":"CanvasOperationClosePath",
			"type":"statement",
			"syntax":[
				"close path on <mCanvas>"
			],
			"display syntax":[
				"close path on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Closes the current subpath of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Begin a new subpath on the canvas\nmove to point [25, 50] on this canvas\n\n// Continue path with a curve through 25,100 to 50,100\ncurve through point [25,100] to point [50,100] on this canvas\n\n// Close the path\nclose path on this canvas\n\n// stroke the canvas path\nstroke this canvas"
			}],
			"description":"Adds a line from the previous point to the start of current subpath, signaling the end of the subpath.",
			"tags":["Canvas"]
		},{
			"id":"300",
			"name":"gradientstopmake",
			"display name":"GradientStopMake",
			"type":"operator",
			"syntax":[
				"gradient stop at <mOffset> with <mColor>"
			],
			"display syntax":[
				"gradient stop at <i>mOffset</i> with <i>mColor</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new gradient stop.",
			"parameters":[{
				"name":"mOffset",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mColor",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a color."
			}],
			"examples":[{
				"script":"// List to hold gradient stops\nvariable tRamp\nput the empty list into tRamp\n\n// First gradient stop is red at position 0\npush gradient stop at 0 with color [1,0,0] onto tRamp\n\n// Second stop is half-transparent green at position 0.5\npush gradient stop at 0.5 with color [0,1,0,0.5] onto tRamp\n\n// Third stop is blue at position 1\npush gradient stop at 1 with color [0,0,1] onto tRamp"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new gradient stop."
			}],
			"tags":["Canvas"]
		},{
			"id":"301",
			"name":"imagepropertypixels",
			"display name":"ImagePropertyPixels",
			"type":"operator",
			"syntax":[
				"the pixels of <mImage>"
			],
			"display syntax":[
				"the pixels of <i>mImage</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The pixel data of an image.",
			"parameters":[{
				"name":"mImage",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an image."
			}],
			"examples":[{
				"script":"// Load an image from a file\nvariable tImage as Image\nput image from file \"images/logo.png\" into tImage\n\n// Get the pixels of the image\nvariable tPixelData as Data\nput the pixels of tImage into tPixelData"
			}],
			"description":"The raw ARGB pixel data of the image.",
			"tags":["Canvas"]
		},{
			"id":"302",
			"name":"canvaspropertyblendmode",
			"display name":"CanvasPropertyBlendMode",
			"type":"operator",
			"syntax":[
				"the blend mode of <mCanvas>"
			],
			"display syntax":[
				"the blend mode of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current blend mode of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Use color dodge mode to draw on canvas\nset the blend mode of this canvas to \"color dodge\""
			}],
			"description":"The blend mode used for drawing operations on <mCanvas> as a string.",
			"tags":["Canvas"]
		},{
			"id":"303",
			"name":"fontmakewithsize",
			"display name":"FontMakeWithSize",
			"type":"operator",
			"syntax":[
				"font <mName>  at size <mSize>"
			],
			"display syntax":[
				"font <i>mName</i>  at size <i>mSize</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new instance of the named font.",
			"parameters":[{
				"name":"mName",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"mSize",
				"type":"",
				"refparam":"false",
				"description":"An Expression which evaluates to a number."
			}],
			"examples":[{
				"script":"// Create 20pt Arial font\nvariable tFont as Font\nput font \"Arial\" at size 20 into tFont"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new instance of the named font at size <mSize> points."
			}],
			"tags":["Canvas"]
		},{
			"id":"304",
			"name":"gradientpropertyvia",
			"display name":"GradientPropertyVia",
			"type":"operator",
			"syntax":[
				"the via of <mGradient>"
			],
			"display syntax":[
				"the via of <i>mGradient</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The via point of a gradient paint.",
			"parameters":[{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\nvariable tRect\nput rectangle [ 20, 10, 120, 60 ] into tRect\n\n// Set the via of the gradient to the bottom of tRect\nset the via of tGradient to point [(the left of tRect + the right of tRect) / 2, the bottom of tRect]"
			}],
			"description":"The via point of <mGradient> as a point. This is used to skew and scale the gradient when drawing.",
			"tags":["Canvas"]
		},{
			"id":"305",
			"name":"fontpropertysize",
			"display name":"FontPropertySize",
			"type":"operator",
			"syntax":[
				"the size of <mFont>"
			],
			"display syntax":[
				"the size of <i>mFont</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The size of a font.",
			"parameters":[{
				"name":"mFont",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a font."
			}],
			"examples":[{
				"script":"// Create a font\nvariable tFont as Font\nput font \"Arial\" at size 20 into tFont\n\n// Set the font size to 30pt\nset the size of tFont to 30"
			}],
			"description":"The size of <mFont> as a number of points.",
			"tags":["Canvas"]
		},{
			"id":"306",
			"name":"pathmakeempty",
			"display name":"PathMakeEmpty",
			"type":"expression",
			"syntax":[
				"the empty path"
			],
			"display syntax":[
				"the empty path"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new empty path.",
			"examples":[{
				"script":"// Initialize the path to empty\nvariable tPath as Path\nput the empty path into tPath\n\n// add a line to the path\nmove to point [0,50] on tPath\nline to point [100,50] on tPath"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"An empty path."
			}],
			"tags":["Canvas"]
		},{
			"id":"307",
			"name":"canvaspropertyantialias",
			"display name":"CanvasPropertyAntialias",
			"type":"operator",
			"syntax":[
				"the antialias of <mCanvas>"
			],
			"display syntax":[
				"the antialias of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current antialias setting of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Disable antialiasing on the canvas\nset the antialias of this canvas to false"
			}],
			"description":"A boolean value which determines whether or not antialiasing will be used when rendering paths on <mCanvas>.",
			"tags":["Canvas"]
		},{
			"id":"308",
			"name":"effectpropertydistance",
			"display name":"EffectPropertyDistance",
			"type":"operator",
			"syntax":[
				"the distance of <mEffect>"
			],
			"display syntax":[
				"the distance of <i>mEffect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The distance of an effect.",
			"parameters":[{
				"name":"mEffect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an effect."
			}],
			"examples":[{
				"script":"// Create an effect with distance 5\nvariable tProps as Array\nput the empty array into tProps\n\nput 5 into tProps[\"distance\"]\n\nvariable tEffect as Effect\nput outer shadow effect with properties tProps into tEffect\n\n// Set the effect distance\nset the distance of tEffect to 50"
			}],
			"description":"The distance of <mEffect> as a number. Distance applies to inner shadow, and outer shadow effect types",
			"tags":["Canvas"]
		},{
			"id":"309",
			"name":"gradientstoppropertyoffset",
			"display name":"GradientStopPropertyOffset",
			"type":"operator",
			"syntax":[
				"the offset of <mStop>"
			],
			"display syntax":[
				"the offset of <i>mStop</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The offset of a gradient stop value.",
			"parameters":[{
				"name":"mStop",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient stop."
			}],
			"examples":[{
				"script":"variable tStop\nput gradient stop at 0 with color [1,1,1] into tStop\n\n// Get the offset of a stop\nvariable tOffset\nput the offset of tStop into tOffset\n\n// Move the stop to a new offset\nset the offset of tStop to 0.75"
			}],
			"description":"The offset of <mStop>.",
			"tags":["Canvas"]
		},{
			"id":"310",
			"name":"canvasoperationrestorestate",
			"display name":"CanvasOperationRestoreState",
			"type":"statement",
			"syntax":[
				"restore state of <mCanvas>"
			],
			"display syntax":[
				"restore state of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Restore the previously saved state of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Save the current canvas properties\nsave state of this canvas\n\n// Change various properties of the canvas\nset the paint of this canvas to solid paint with color [1,1,0,0.5]\nset the blend mode of this canvas to \"color dodge\"\nrotate this canvas by 30\nset the font of this canvas to font \"Helvetica\" with size 15\n\n// Restore the previous canvas properties\nrestore state of this canvas"
			}],
			"description":"Restores the properties of <mCanvas> from the top of the saved property stack.",
			"tags":["Canvas"]
		},{
			"id":"311",
			"name":"effectpropertyblendmode",
			"display name":"EffectPropertyBlendMode",
			"type":"operator",
			"syntax":[
				"the blend mode of <mEffect>"
			],
			"display syntax":[
				"the blend mode of <i>mEffect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The blend mode of an effect.",
			"parameters":[{
				"name":"mEffect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an effect."
			}],
			"examples":[{
				"script":"// Create an effect with blend mode \"source over\"\nvariable tProps as Array\nput the empty array into tProps\n\nput \"source over\" into tProps[\"blend mode\"]\n\nvariable tEffect as Effect\nput outer shadow effect with properties tProps into tEffect\n\n// Use color dodge mode for effect\nset the blend mode of tEffect to \"color dodge\""
			}],
			"description":"The blend mode of <mEffect> as a string. Can be any one of the standard canvas blend modes.",
			"references":{
				"operator":["CanvasPropertyBlendMode"]
			},
			"tags":["Canvas"]
		},{
			"id":"312",
			"name":"patternpropertytransform",
			"display name":"PatternPropertyTransform",
			"type":"operator",
			"syntax":[
				"the transform of <mPattern>"
			],
			"display syntax":[
				"the transform of <i>mPattern</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The transform of a pattern value.",
			"parameters":[{
				"name":"mPattern",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a pattern."
			}],
			"examples":[{
				"script":"// Create a new pattern paint from a scaled-down image file\nvariable tPattern\nput pattern with image from file \"images/pattern.png\" scaled by [0.5] into tPattern\n\n// Get the current transform\nvariable tTransform\nput the transform of tPattern into tTransform\n\n// Modify the transform by rotation\nrotate tTransform by tDegrees\n\n// Set the pattern to the modified transform\nset the transform of tPattern to tTransform"
			}],
			"description":"The transform of <mPattern>.",
			"tags":["Canvas"]
		},{
			"id":"313",
			"name":"canvaspropertydashes",
			"display name":"CanvasPropertyDashes",
			"type":"operator",
			"syntax":[
				"the dashes of <mCanvas>"
			],
			"display syntax":[
				"the dashes of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current dashes of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Draw a rectangle with short, widely spaced dashes\nset the dashes of this canvas to [10, 40]\nstroke rectangle path of rectangle [50, 50, 200, 200] on this canvas"
			}],
			"description":"The dashes as a list of numbers. The dashes specifies a sequence of lengths that alternately represent space and dash lengths when stroking a path.",
			"tags":["Canvas"]
		},{
			"id":"314",
			"name":"fontpropertybold",
			"display name":"FontPropertyBold",
			"type":"operator",
			"syntax":[
				"the bold of <mFont>"
			],
			"display syntax":[
				"the bold of <i>mFont</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The bold setting of a font.",
			"parameters":[{
				"name":"mFont",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a font."
			}],
			"examples":[{
				"script":"// Create a font\nvariable tFont as Font\nput font \"Arial\" at size 20 into tFont\n\n// Set the font to bold\nset the bold of tFont to true"
			}],
			"description":"The bold flag of <mFont> as a boolean. If true, then <mFont> is bold.",
			"tags":["Canvas"]
		},{
			"id":"315",
			"name":"transformpropertytranslation",
			"display name":"TransformPropertyTranslation",
			"type":"operator",
			"syntax":[
				"the translation of <mTransform>"
			],
			"display syntax":[
				"the translation of <i>mTransform</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The translation component of a transform.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			}],
			"examples":[{
				"script":"variable tTransform\nput transform with matrix [0, 2, -2, 0, 50, 100] into tTransform\n\n// Store the old translation component\nvariable tTranslation\nput the translation of tTransform into tTranslation\n\n// Adjust the offset of the transformation\nset the translation of tTransform to [element 1 of tTranslation + 5, element 2 of tTranslation + 5]"
			}],
			"description":"The translation of <mTransform> as a list of 2 numbers (the x and y offset values).",
			"tags":["Canvas"]
		},{
			"id":"316",
			"name":"imagemakefromfile",
			"display name":"ImageMakeFromFile",
			"type":"operator",
			"syntax":[
				"image from file <mPath>"
			],
			"display syntax":[
				"image from file <i>mPath</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new image.",
			"parameters":[{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"// Load image from a file path\nvariable tImage\nput image from file \"images/logo.png\" into tImage"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new image loaded from the file path provided."
			}],
			"tags":["Canvas"]
		},{
			"id":"317",
			"name":"patternmakescaledby",
			"display name":"PatternMakeScaledBy",
			"type":"operator",
			"syntax":[
				"pattern with <mImage> scaled by <mScale>"
			],
			"display syntax":[
				"pattern with <i>mImage</i> scaled by <i>mScale</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new scaled pattern paint.",
			"parameters":[{
				"name":"mImage",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an image."
			},{
				"name":"mScale",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of 1 or 2 numbers, the x-axis scale and y-axis scale, or the uniform scale when only a single value is given."
			}],
			"examples":[{
				"script":"// Load the pattern image.\nvariable tImage\nput image from file \"images/backgroundpattern.png\" into tImage\n\n// Create a new pattern paint, scaling the image to half size\nvariable tPaint\nput pattern with tImage scaled by [0.5] into tPaint"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new pattern paint based on <mImage> with the specified scale applied."
			}],
			"tags":["Canvas"]
		},{
			"id":"318",
			"name":"effectpropertyspread",
			"display name":"EffectPropertySpread",
			"type":"operator",
			"syntax":[
				"the spread of <mEffect>"
			],
			"display syntax":[
				"the spread of <i>mEffect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The spread of an effect.",
			"parameters":[{
				"name":"mEffect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an effect."
			}],
			"examples":[{
				"script":"// Create an effect with spread 0\nvariable tProps as Array\nput the empty array into tProps\n\nput 0 into tProps[\"spread\"]\n\nvariable tEffect as Effect\nput outer shadow effect with properties tProps into tEffect\n\n// Set the effect spread\nset the spread of tEffect to 10"
			}],
			"description":"The spread of <mEffect> as a number. Spread applies to inner shadow, outer shadow, inner glow, and outer glow effect types",
			"tags":["Canvas"]
		},{
			"id":"319",
			"name":"transformmakescale",
			"display name":"TransformMakeScale",
			"type":"operator",
			"syntax":[
				"transform with scale <mScale>"
			],
			"display syntax":[
				"transform with scale <i>mScale</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new scaling transform value.",
			"parameters":[{
				"name":"mScale",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of 1 or 2 numbers, the x-axis scale and y-axis scale, or the uniform scale when only a single value is given."
			}],
			"examples":[{
				"script":"// Create x2 uniformly scaling transform\nvariable tTransform\nput transform with scale [2] into tTransform\n\n// Create transform which only scales in the direction of the x axis\nput transform with scale [ 2, 1 ] into tTransform"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new scale transform."
			}],
			"tags":["Canvas"]
		},{
			"id":"320",
			"name":"gradientpropertyrepeat",
			"display name":"GradientPropertyRepeat",
			"type":"operator",
			"syntax":[
				"the repeat of <mGradient>"
			],
			"display syntax":[
				"the repeat of <i>mGradient</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The repeat count of a gradient paint.",
			"parameters":[{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\n// Store the old gradient repeat count\nvariable tRepeat\nput the repeat of tGradient into tRepeat\n\n// Make the gradient repeat 3 times\nset the repeat of tGradient to 3"
			}],
			"description":"The repeat count of <mGradient> as a number. This determines how many times the ramp is repeated over the length of the gradient.",
			"tags":["Canvas"]
		},{
			"id":"321",
			"name":"transformoperationrotate",
			"display name":"TransformOperationRotate",
			"type":"statement",
			"syntax":[
				"rotate <mTransform> by <mRotation>"
			],
			"display syntax":[
				"rotate <i>mTransform</i> by <i>mRotation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a rotation to a transform.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			},{
				"name":"mRotation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number of degrees."
			}],
			"examples":[{
				"script":"// Create a new transform\nvariable tTransform\nput the identity transform into tTransform\n\n// Rotate the transform by 90 degrees\nrotate tTransform by 90"
			}],
			"description":"Apply a rotation by <mRotation> degrees to <mTransform>. This is equivalent to concatenating <mTransform> with a new rotation transform.",
			"tags":["Canvas"]
		},{
			"id":"322",
			"name":"pathmakewithrectangle",
			"display name":"PathMakeWithRectangle",
			"type":"operator",
			"syntax":[
				"rectangle path of <mRect>"
			],
			"display syntax":[
				"rectangle path of <i>mRect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new path.",
			"parameters":[{
				"name":"mRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			}],
			"examples":[{
				"script":"// Create a rectangle path\nvariable tPath as Path\nput rectangle path of rectangle [10,10,210,60] into tPath"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new rectangle path."
			}],
			"tags":["Canvas"]
		},{
			"id":"323",
			"name":"pathoperationarcto",
			"display name":"PathOperationArcTo",
			"type":"statement",
			"syntax":[
				"arc through <mThrough> to <mTo> with radius <mRadius> on <mPath>"
			],
			"display syntax":[
				"arc through <i>mThrough</i> to <i>mTo</i> with radius <i>mRadius</i> on <i>mPath</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Adds an arc to a path.",
			"parameters":[{
				"name":"mThrough",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mTo",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mRadius",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Construct a path tracing out a rectangle with rounded bottom corners.\nvariable tPath\nput the empty path into tPath\n\n// Begin a new subpath\nmove to point [0, 0] on tPath\n\n// Continue path with an arc to the bottom edge\narc through point [0, my height] to point [25, my height] with radius 25 on tPath\n\n// Continue path with an arc to the right edge\narc through point [my width, my height] to point [my width, 0] with radius 25 on tPath\n\n// Close the path with a line back to the starting point\nclose path on tPath"
			}],
			"description":"Adds an arc between the points of a circle with radius <mRadius> tangent to the lines from the current point to <mThrough>, and from <mThrough> to <mTo>.",
			"tags":["Canvas"]
		},{
			"id":"324",
			"name":"pathmake",
			"display name":"PathMake",
			"type":"operator",
			"syntax":[
				"path <mInstructions>"
			],
			"display syntax":[
				"path <i>mInstructions</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new path.",
			"parameters":[{
				"name":"mInstructions",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"// Create a closed path with a line and some curves\nvariable tPath as Path\nput path \"M10,10 L50,100 Q100,100 100,50 C75,50 50,25 50,10z\" into tPath"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new path created from the instructions provided. The format of the path instructions is the same as that used for SVG path data as defined here - http://www.w3.org/TR/SVG/paths.html#PathData"
			}],
			"tags":["Canvas"]
		},{
			"id":"325",
			"name":"transformoperationtranslate",
			"display name":"TransformOperationTranslate",
			"type":"statement",
			"syntax":[
				"translate <mTransform> by <mTranslation>"
			],
			"display syntax":[
				"translate <i>mTransform</i> by <i>mTranslation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a translation to a transform.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			},{
				"name":"mTranslation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of 2 numbers, the x and y offsets of the translation."
			}],
			"examples":[{
				"script":"// Create a new transform\nvariable tTransform\nput the identity transform into tTransform\n\nvariable tRect\nput rectangle [10, 20, 110, 170] into tRect\n\n// Translate the transform to the top-left of tRect\ntranslate tTransform by [the left of tRect, the top of tRect]"
			}],
			"description":"Apply a translation to <mTransform>. This is equivalent to concatenating <mTransform> with a new translation transform.",
			"tags":["Canvas"]
		},{
			"id":"326",
			"name":"patternmakerotatedby",
			"display name":"PatternMakeRotatedBy",
			"type":"operator",
			"syntax":[
				"pattern with <mImage> rotated by <mRotation>"
			],
			"display syntax":[
				"pattern with <i>mImage</i> rotated by <i>mRotation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new rotated pattern paint.",
			"parameters":[{
				"name":"mImage",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an image."
			},{
				"name":"mRotation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number of degrees."
			}],
			"examples":[{
				"script":"// Load the pattern image.\nvariable tImage\nput image from file \"images/backgroundpattern.png\" into tImage\n\n// Create a new pattern paint, rotating the image through 90 degrees\nvariable tPaint\nput pattern with tImage rotated by 90 into tPaint"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new pattern paint based on <mImage> with the specified rotation applied."
			}],
			"tags":["Canvas"]
		},{
			"id":"327",
			"name":"pathoperationrotate",
			"display name":"PathOperationRotate",
			"type":"statement",
			"syntax":[
				"rotate <mPath> by <mRotation>"
			],
			"display syntax":[
				"rotate <i>mPath</i> by <i>mRotation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a rotation to a path.",
			"parameters":[{
				"name":"mRotation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Create a rectangle path\nvariable tPath as Path\nput rectangle path of rectangle [10,10,210,60] into tPath\n\n// Rotate the path\nrotate tPath by 45"
			}],
			"description":"Rotates <mPath> by <mRotation> degrees.",
			"tags":["Canvas"]
		},{
			"id":"328",
			"name":"canvaspropertycapstyle",
			"display name":"CanvasPropertyCapStyle",
			"type":"operator",
			"syntax":[
				"the cap style of <mCanvas>"
			],
			"display syntax":[
				"the cap style of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current cap style of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Draw a line with rounded ends.\nset the cap style of this canvas to \"round\"\nstroke line path from point [50,100] to point [100,50] on this canvas"
			}],
			"description":"Determines how to draw the end points of a path when stroking. Can be one of \"butt\", \"square\", or \"round\".",
			"tags":["Canvas"]
		},{
			"id":"329",
			"name":"gradientoperationrotate",
			"display name":"GradientOperationRotate",
			"type":"statement",
			"syntax":[
				"rotate <mGradient> by <mRotation>"
			],
			"display syntax":[
				"rotate <i>mGradient</i> by <i>mRotation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a rotation to a gradient paint.",
			"parameters":[{
				"name":"mRotation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\n// Rotate the gradient\nrotate tGradient by 45"
			}],
			"description":"Rotates the transform of <mGradient> by <mRotation> degrees.",
			"tags":["Canvas"]
		},{
			"id":"330",
			"name":"pathoperationaddpath",
			"display name":"PathOperationAddPath",
			"type":"statement",
			"syntax":[
				"add <mSource> to <mDest>"
			],
			"display syntax":[
				"add <i>mSource</i> to <i>mDest</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Extend a path by adding another path.",
			"parameters":[{
				"name":"mSource",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			},{
				"name":"mDest",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Create a rectangle path\nvariable tPath as Path\nput rectangle path of rectangle [10,10,210,60] into tPath\n\n// Add another rectangle subpath to tPath\nadd rectangle path of rectangle [110,10,310,60] to tPath"
			}],
			"description":"Adds the path defined by <mSource> to <mDest>.",
			"tags":["Canvas"]
		},{
			"id":"331",
			"name":"canvaspropertymiterlimit",
			"display name":"CanvasPropertyMiterLimit",
			"type":"operator",
			"syntax":[
				"the miter limit of <mCanvas>"
			],
			"display syntax":[
				"the miter limit of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current miter limit of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Draw a right-angled triangle, setting the miter limit so only the right-angle corner is mitered.\nset the miter limit of this canvas to 1.5\nstroke polygon path with points [point [50,50], point [50,100], point [100,50]] on this canvas"
			}],
			"description":"The limit of miter joins as a number. Specifies how far miter joins can extend from the meeting point of two lines before a bevel join is used instead.",
			"tags":["Canvas"]
		},{
			"id":"332",
			"name":"solidpaintmake",
			"display name":"SolidPaintMake",
			"type":"operator",
			"syntax":[
				"solid paint with <mColor>"
			],
			"display syntax":[
				"solid paint with <i>mColor</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new solid color paint.",
			"parameters":[{
				"name":"mColor",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a color."
			}],
			"examples":[{
				"script":"// Create a new green paint\nvariable tPaint\nput solid paint with color [0,1,0] into tPaint"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new paint using <mColor>."
			}],
			"tags":["Canvas"]
		},{
			"id":"333",
			"name":"pathmakewithpoints",
			"display name":"PathMakeWithPoints",
			"type":"operator",
			"syntax":[
				"( polygon | polyline ) path with points <mPoints>"
			],
			"display syntax":[
				"( polygon | polyline ) path with points <i>mPoints</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new path.",
			"parameters":[{
				"name":"mPoints",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of points."
			}],
			"examples":[{
				"script":"// Create a polyline path\nvariable tPath as Path\nput polyline path with points [point [0,0], point [25,50], point [75,50], point [50,0]] into tPath"
			},{
				"script":"// Create a closed polygon path (rhombus)\nvariable tPath as Path\nput polygon path with points [point [0,0], point [25,50], point [75,50], point [50,0]] into tPath"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new polyline or polygon path. A polygon path will be closed with an additional line from the last point to the first."
			}],
			"tags":["Canvas"]
		},{
			"id":"334",
			"name":"canvaspropertyjoinstyle",
			"display name":"CanvasPropertyJoinStyle",
			"type":"operator",
			"syntax":[
				"the join style of <mCanvas>"
			],
			"display syntax":[
				"the join style of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current join style of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Draw a square with beveled corners.\nset the join style of this canvas to \"bevel\"\nstroke rectangle path of rectangle [25, 25, 75, 75] on this canvas"
			}],
			"description":"Determines how to draw the join between the lines of a path when stroking. Can be one of \"bevel\", \"round\", or \"miter\".",
			"tags":["Canvas"]
		},{
			"id":"335",
			"name":"fontoperationtextimageboundsoncanvas",
			"display name":"FontOperationTextImageBoundsOnCanvas",
			"type":"operator",
			"syntax":[
				"the image bounds of text <mText> on <mCanvas>"
			],
			"display syntax":[
				"the image bounds of text <i>mText</i> on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Measure text precisely when drawn to a canvas.",
			"parameters":[{
				"name":"mText",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Set the canvas font\nset the font of this canvas to font \"Arial\" at size 18\n\nvariable tBounds as Rectangle\nput the image bounds of text \"Sample text\" on this canvas into tBounds"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The bounding box of <mText> when drawn at point 0,0 with the current font of <mCanvas>. Returns the bounds as a rectangle."
			}],
			"description":"The exact bounds of the text, which will fully enclose each character.\n\n>*Note:* This can be more time-consuming to compute than the layout bounds.",
			"tags":["Canvas"]
		},{
			"id":"336",
			"name":"fontpropertyitalic",
			"display name":"FontPropertyItalic",
			"type":"operator",
			"syntax":[
				"the italic of <mFont>"
			],
			"display syntax":[
				"the italic of <i>mFont</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The italic setting of a font.",
			"parameters":[{
				"name":"mFont",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a font."
			}],
			"examples":[{
				"script":"// Create a font\nvariable tFont as Font\nput font \"Arial\" at size 20 into tFont\n\n// Set the font to italic\nset the italic of tFont to true"
			}],
			"description":"The italic flag of <mFont> as a boolean. If true, then <mFont> is italic.",
			"tags":["Canvas"]
		},{
			"id":"337",
			"name":"fontoperationtextlayoutboundsoncanvas",
			"display name":"FontOperationTextLayoutBoundsOnCanvas",
			"type":"operator",
			"syntax":[
				"the [ layout ] bounds of text <mText> on <mCanvas>"
			],
			"display syntax":[
				"the [ layout ] bounds of text <i>mText</i> on <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Measure text when drawn to a canvas.",
			"parameters":[{
				"name":"mText",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Set the canvas font\nset the font of this canvas to font \"Arial\" at size 18\n\nvariable tBounds as Rectangle\nput the bounds of text \"Sample text\" on this canvas into tBounds"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The bounding box of <mText> when drawn at point 0,0 with the current font of <mCanvas>. Returns the bounds as a rectangle."
			}],
			"description":"The layout bounds of the text, constructed from the ascent and descent values of the font, and the width of the text string.\n\n>*Note:* The layout bounds is used to position blocks of text relative to each other, so the text may overlap these bounds.",
			"tags":["Canvas"]
		},{
			"id":"338",
			"name":"fontmake",
			"display name":"FontMake",
			"type":"operator",
			"syntax":[
				"font <mName>"
			],
			"display syntax":[
				"font <i>mName</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new instance of the named font.",
			"parameters":[{
				"name":"mName",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"// Create Arial font\nvariable tFont as Font\nput font \"Arial\" into tFont"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new instance of the named font with the default size of 12pts."
			}],
			"tags":["Canvas"]
		},{
			"id":"339",
			"name":"effectpropertycolor",
			"display name":"EffectPropertyColor",
			"type":"operator",
			"syntax":[
				"the color of <mEffect>"
			],
			"display syntax":[
				"the color of <i>mEffect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The color of an effect.",
			"parameters":[{
				"name":"mEffect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an effect."
			}],
			"examples":[{
				"script":"// Create an effect with color \"black\"\nvariable tProps as Array\nput the empty array into tProps\n\nput color [0,0,0] into tProps[\"color\"]\n\nvariable tEffect as Effect\nput outer shadow effect with properties tProps into tEffect\n\n// Change effect color to green.\nset the color of tEffect to color [0,1,0]"
			}],
			"description":"The color of <mEffect> as a color.",
			"tags":["Canvas"]
		},{
			"id":"340",
			"name":"gradientpropertyfrom",
			"display name":"GradientPropertyFrom",
			"type":"operator",
			"syntax":[
				"the from of <mGradient>"
			],
			"display syntax":[
				"the from of <i>mGradient</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The from point of a gradient paint.",
			"parameters":[{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\nvariable tRect\nput rectangle [ 20, 10, 120, 60 ] into tRect\n\n// Set the start point of the gradient to the center of tRect\nset the from of tGradient to point [(the left of tRect + the right of tRect) / 2, (the top of tRect + the bottom of tRect) / 2]"
			}],
			"description":"The from point of <mGradient> as a point. Defines the starting point from which to begin drawing the gradient.",
			"tags":["Canvas"]
		},{
			"id":"341",
			"name":"imagemakefromresourcefile",
			"display name":"ImageMakeFromResourceFile",
			"type":"operator",
			"syntax":[
				"image from resource file <mResource>"
			],
			"display syntax":[
				"image from resource file <i>mResource</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new image.",
			"parameters":[{
				"name":"mResource",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"// Load image from a bundled resource file\nvariable tImage\nput image from resource file \"images/logo.png\" into tImage"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new image decoded from the named module resource file."
			}],
			"tags":["Canvas"]
		},{
			"id":"342",
			"name":"fontoperationtextlayoutbounds",
			"display name":"FontOperationTextLayoutBounds",
			"type":"operator",
			"syntax":[
				"the [ layout ] bounds of text <mText> with <mFont>"
			],
			"display syntax":[
				"the [ layout ] bounds of text <i>mText</i> with <i>mFont</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Measure text when drawn with a font.",
			"parameters":[{
				"name":"mText",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"mFont",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a font."
			}],
			"examples":[{
				"script":"// Set up tFont as size 18 Arial\nvariable tFont as Font\nput font \"Arial\" at size 18 into tFont\n\n// Measure text with tFont\nvariable tBounds as Rectangle\nput the bounds of text \"Sample text\" with tFont into tBounds"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The bounding box of <mText> when drawn at point 0,0 with font <mFont>. Returns the bounds as a rectangle."
			}],
			"description":"The layout bounds of the text, constructed from the ascent and descent values of the font, and the width of the text string.\n\n>*Note:* The layout bounds is used to position blocks of text relative to each other, so the text may overlap these bounds.",
			"tags":["Canvas"]
		},{
			"id":"343",
			"name":"patternoperationtranslate",
			"display name":"PatternOperationTranslate",
			"type":"statement",
			"syntax":[
				"translate <mPattern> by <mTranslation>"
			],
			"display syntax":[
				"translate <i>mPattern</i> by <i>mTranslation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a translation to a pattern.",
			"parameters":[{
				"name":"mPattern",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a pattern."
			},{
				"name":"mTranslation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of 2 numbers, the x and y offsets of the translation."
			}],
			"examples":[{
				"script":"// Create a new pattern paint from an image file\nvariable tPattern\nput pattern with image from file \"images/pattern.png\" into tPattern\n\n// Translate the pattern 20 units to the left.\ntranslate tPattern by [-20,0]"
			}],
			"description":"translates the transform of <mPattern> by <mTranslation>",
			"tags":["Canvas"]
		},{
			"id":"344",
			"name":"patternpropertyimage",
			"display name":"PatternPropertyImage",
			"type":"operator",
			"syntax":[
				"the image of <mPattern>"
			],
			"display syntax":[
				"the image of <i>mPattern</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The image of a pattern value.",
			"parameters":[{
				"name":"mPattern",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a pattern."
			}],
			"examples":[{
				"script":"// Create a new pattern based on an image file\nvariable tPattern\nput pattern with image from file \"images/patternframe1.png\" into tPattern\n\n// Store the old image of tPattern\nvariable tImage\nput the image of tPattern into tImage\n\n// Set the pattern to draw the next image\nset the image of tPattern to image from file \"images/patternframe2.png\""
			}],
			"description":"The image of <mPattern>.",
			"tags":["Canvas"]
		},{
			"id":"345",
			"name":"com.livecode.canvas",
			"display name":"com.livecode.canvas",
			"type":"library",
			"display syntax":[
				"com.livecode.canvas"
			],
			"description":"This module specifies the syntax definitions and bindings for canvas drawing operations in modular LiveCode."
		},{
			"id":"346",
			"name":"effectpropertysize",
			"display name":"EffectPropertySize",
			"type":"operator",
			"syntax":[
				"the size of <mEffect>"
			],
			"display syntax":[
				"the size of <i>mEffect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The size of an effect.",
			"parameters":[{
				"name":"mEffect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an effect."
			}],
			"examples":[{
				"script":"// Create an effect with size 5\nvariable tProps as Array\nput the empty array into tProps\n\nput 5 into tProps[\"size\"]\n\nvariable tEffect as Effect\nput outer shadow effect with properties tProps into tEffect\n\n// Set the effect size\nset the size of tEffect to 15"
			}],
			"description":"The size of <mEffect> as a number. Size applies to inner shadow, outer shadow, inner glow, and outer glow effect types",
			"tags":["Canvas"]
		},{
			"id":"347",
			"name":"rectanglepropertyleft",
			"display name":"RectanglePropertyLeft",
			"type":"operator",
			"syntax":[
				"the left of <mRect>"
			],
			"display syntax":[
				"the left of <i>mRect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The left edge of a rectangle value.",
			"parameters":[{
				"name":"mRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			}],
			"examples":[{
				"script":"variable tRect\nput rectangle [50,100,150,200] into tRect\n\n// Store the left edge of the rectangle in a variable\nvariable tLeft\nput the left of tRect into tLeft\n\n// Move the rectangle horizontally to a new position.\nset the left of tRect to 20"
			}],
			"description":"The location along the x-axis of the left edge of the rectangle.\n\n>*Note:* Setting the left of a rectangle will reposition it without altering the width or height.",
			"tags":["Canvas"]
		},{
			"id":"348",
			"name":"pathpropertyinstructions",
			"display name":"PathPropertyInstructions",
			"type":"operator",
			"syntax":[
				"the instructions of <mPath>"
			],
			"display syntax":[
				"the instructions of <i>mPath</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The instructions of a path.",
			"parameters":[{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Create a rounded rectangle path\nvariable tPath as Path\nput rounded rectangle path of rectangle [10,10,210,60] with radius 15 into tPath\n\n// Get the instructions of the path\nvariable tPathData as String\nput the instructions of tPath into tPathData"
			}],
			"description":"A string containing the series of instructions and point arguments used to construct <mPath>.\n>*Note:* The format of the path instructions is the same as that used for SVG path data as defined here - http://www.w3.org/TR/SVG/paths.html#PathData",
			"tags":["Canvas"]
		},{
			"id":"349",
			"name":"transformpropertyrotation",
			"display name":"TransformPropertyRotation",
			"type":"operator",
			"syntax":[
				"the rotation of <mTransform>"
			],
			"display syntax":[
				"the rotation of <i>mTransform</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The rotation component of a transform.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			}],
			"examples":[{
				"script":"variable tTransform\nput transform with matrix [0, 2, -2, 0, 50, 100] into tTransform\n\n// Store the old rotation component\nvariable tRotation\nput the rotation of tTransform into tRotation\n\n// Double the rotation\nset the rotation of tTransform to tRotation * 2"
			}],
			"description":"The rotation of <mTransform> as a number of degrees.",
			"tags":["Canvas"]
		},{
			"id":"350",
			"name":"patternmaketranslatedby",
			"display name":"PatternMakeTranslatedBy",
			"type":"operator",
			"syntax":[
				"pattern with <mImage> translated by <mTranslation>"
			],
			"display syntax":[
				"pattern with <i>mImage</i> translated by <i>mTranslation</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new translated pattern paint.",
			"parameters":[{
				"name":"mImage",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an image."
			},{
				"name":"mTranslation",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of 2 numbers, the x and y offsets of the translation."
			}],
			"examples":[{
				"script":"// Load the pattern image.\nvariable tImage\nput image from file \"images/backgroundpattern.png\" into tImage\n\n// Create a new pattern paint, offsetting the image to the top-left of tRect\nvariable tPaint\nvariable tRect\nput rectangle [20, 50, 120, 100] into tRect\nput pattern with tImage translated by [the left of tRect, the top of tRect] into tPaint"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new pattern paint based on <mImage> with the specified translation applied."
			}],
			"tags":["Canvas"]
		},{
			"id":"351",
			"name":"canvasoperationfill",
			"display name":"CanvasOperationFill",
			"type":"statement",
			"syntax":[
				"fill [ <mPath> on ] <mCanvas>"
			],
			"display syntax":[
				"fill [ <i>mPath</i> on ] <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Fill a path on a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			},{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Fill a circle path on the canvas\nfill circle path centered at point [100,100] with radius 50 on this canvas"
			},{
				"script":"// Add a path to the canvas\nmove to point [50,50] on this canvas\nline to point [50,100] on this canvas\nline to point [100,100] on this canvas\n\n// Fill the current canvas path\nfill this canvas"
			}],
			"description":"Fills the region bound by <mPath> with the current canvas paint. If mPath is not specified then the current canvas path will be closed and filled, then emptied from the canvas.",
			"tags":["Canvas"]
		},{
			"id":"352",
			"name":"canvasoperationaddpath",
			"display name":"CanvasOperationAddPath",
			"type":"statement",
			"syntax":[
				"add <mPath> to <mCanvas>"
			],
			"display syntax":[
				"add <i>mPath</i> to <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Add a path to a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			},{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Add a path to the canvas\nadd rectangle path of rectangle [0,0,50,100] to this canvas\n\n// Fill the canvas path\nfill this canvas"
			}],
			"description":"Adds <mPath> to the current path of <mCanvas>",
			"tags":["Canvas"]
		},{
			"id":"353",
			"name":"imagemakewithpixels",
			"display name":"ImageMakeWithPixels",
			"type":"operator",
			"syntax":[
				"image of size <mSize> with pixels <mPixels>"
			],
			"display syntax":[
				"image of size <i>mSize</i> with pixels <i>mPixels</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new image using raw pixel data.",
			"parameters":[{
				"name":"mSize",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of integers."
			},{
				"name":"mPixels",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data"
			}],
			"examples":[{
				"script":"// Read pixel data from file\nvariable tPixelData as Data\nput the contents of file \"image_argb_320x480.bin\" into tPixelData\n\n// Create image from pixel data\nvariable tImage as Image\nput image of size [320, 480] with pixels tPixelData into tImage"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new image of the given size, using the provided ARGB pixel data."
			}],
			"tags":["Canvas"]
		},{
			"id":"354",
			"name":"canvaspropertypaint",
			"display name":"CanvasPropertyPaint",
			"type":"operator",
			"syntax":[
				"the paint of <mCanvas>"
			],
			"display syntax":[
				"the paint of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current paint of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Set canvas to paint with solid blue\nset the paint of this canvas to solid paint with color [0,0,1]"
			}],
			"description":"The paint used for fill / stroke operations on <mCanvas>.",
			"tags":["Canvas"]
		},{
			"id":"355",
			"name":"transformmakeskew",
			"display name":"TransformMakeSkew",
			"type":"operator",
			"syntax":[
				"transform with skew <mSkew>"
			],
			"display syntax":[
				"transform with skew <i>mSkew</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new skewing transform value.\nmScale:An expression which evaluates to a list of 2 numbers, the x-axis skew and y-axis skew.",
			"examples":[{
				"script":"// Create skew transform\nvariable tTransform\nput transform with skew [1,0] into tTransform"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new skew transform."
			}],
			"tags":["Canvas"]
		},{
			"id":"356",
			"name":"pathoperationellipticarcto",
			"display name":"PathOperationEllipticArcTo",
			"type":"statement",
			"syntax":[
				"arc to <mEnd> with radii <mRadii> rotated by <mAngle> on <mPath>"
			],
			"display syntax":[
				"arc to <i>mEnd</i> with radii <i>mRadii</i> rotated by <i>mAngle</i> on <i>mPath</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Adds an arc to a path.",
			"parameters":[{
				"name":"mEnd",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mRadii",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			},{
				"name":"mAngle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"// Construct a path tracing out a rectangle with rounded bottom corners.\nvariable tPath\nput the empty path into tPath\n\n// Begin a new subpath\nmove to point [0, 0] on tPath\n\n// Trace the left edge\nline to point [0, my height - 25] on tPath\n\n// Continue path with an arc to the bottom edge\narc to point [my height, 25] with radii [25, 25] rotated by 0 on tPath\n\n// Trace the bottom edge\nline to point [my width - 25, my height] on tPath\n\n// Continue path with an arc to the right edge\narc to point [my width, my height - 25] with radii [25, 25] rotated by 0 on tPath\n\n// Trace the right edge\nline to point [my width, 0] on tPath\n\n// Close the path with a line back to the starting point\nclose path on tPath"
			}],
			"description":"Adds an arc from the previous point to <mEnd> on <mPath>, following a section of an ellipse with the given radii & angle.\nAs there can be two different ellipses that match the parameters, and two potential arcs for each ellipse, this variation of \"arc to ...\" will select the arc that most closely matches the direction from the last point to the current position on <mPath>.",
			"tags":["Canvas"]
		},{
			"id":"357",
			"name":"canvaspropertystrokewidth",
			"display name":"CanvasPropertyStrokeWidth",
			"type":"operator",
			"syntax":[
				"the stroke width of <mCanvas>"
			],
			"display syntax":[
				"the stroke width of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current stroke width of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Draw paths with line width 20\nset the stroke width of this canvas to 20"
			}],
			"description":"The width of lines used when stroking a path on <mCanvas> as a number.",
			"tags":["Canvas"]
		},{
			"id":"358",
			"name":"canvasoperationtransform",
			"display name":"CanvasOperationTransform",
			"type":"statement",
			"syntax":[
				"transform <mCanvas> by <mTransform>"
			],
			"display syntax":[
				"transform <i>mCanvas</i> by <i>mTransform</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a transform to a canvas.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			},{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// Scale the canvas with a transform\ntransform this canvas by transform with scale [2,2]"
			}],
			"description":"Concatenates the transform of <mCanvas> with <mTransform>.",
			"tags":["Canvas"]
		},{
			"id":"359",
			"name":"pathmakewithellipse",
			"display name":"PathMakeWithEllipse",
			"type":"operator",
			"syntax":[
				"ellipse path centered at <mPoint> with radii <mRadii>"
			],
			"display syntax":[
				"ellipse path centered at <i>mPoint</i> with radii <i>mRadii</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new path.\nmCenter:An expression which evaluates to a point.",
			"parameters":[{
				"name":"mRadii",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			}],
			"examples":[{
				"script":"// Create an ellipse path\nvariable tPath as Path\nput ellipse path centered at point [100,100] with radii [100,75] into tPath"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new ellipse path."
			}]
		},{
			"id":"360",
			"name":"imagemakefromdata",
			"display name":"ImageMakeFromData",
			"type":"operator",
			"syntax":[
				"image from data <mData>"
			],
			"display syntax":[
				"image from data <i>mData</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new image.",
			"parameters":[{
				"name":"mData",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to binary data"
			}],
			"examples":[{
				"script":"// Load image from a block of data\nvariable tData\nput the contents of file \"images/logo.png\" into tData\n\nvariable tImage\nput image from data tData into tImage"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new image decoded from the data provided."
			}],
			"tags":["Canvas"]
		},{
			"id":"361",
			"name":"rectanglepropertyheight",
			"display name":"RectanglePropertyHeight",
			"type":"operator",
			"syntax":[
				"the height of <mRect>"
			],
			"display syntax":[
				"the height of <i>mRect</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The height of a rectangle value.",
			"parameters":[{
				"name":"mRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			}],
			"examples":[{
				"script":"variable tRect\nput rectangle [50,100,150,200] into tRect\n\n// Store the height of the rectangle in a variable\nvariable tHeight\nput the height of tRect into tHeight\n\n// Increase the height of the rectangle\nset the height of tRect to (tHeight + 10)"
			}],
			"description":"The height of the rectangle.\n\n>*Note:* Setting the height of a rectangle will resize it without moving the top edge, expanding or contracting from the bottom.",
			"tags":["Canvas"]
		},{
			"id":"362",
			"name":"pathmakewithroundedrectanglewithradius",
			"display name":"PathMakeWithRoundedRectangleWithRadius",
			"type":"operator",
			"syntax":[
				"rounded rectangle path of <mRect> with radius <mRadius>"
			],
			"display syntax":[
				"rounded rectangle path of <i>mRect</i> with radius <i>mRadius</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new path.\nmRadii:An expression which evaluates to a list of numbers.",
			"parameters":[{
				"name":"mRect",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a rectangle."
			},{
				"name":"mRadius",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			}],
			"examples":[{
				"script":"// Create a rounded rectangle path\nvariable tPath as Path\nput rounded rectangle path of rectangle [10,10,210,60] with radius 15 into tPath"
			},{
				"script":"// Create a rounded rectangle path with different horizontal & vertical radii\nvariable tPath as Path\nput rounded rectangle path of rectangle [10,10,210,60] with radii [10,5] into tPath"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new rounded rectangle path."
			}],
			"tags":["Canvas"]
		},{
			"id":"363",
			"name":"pathmakewithline",
			"display name":"PathMakeWithLine",
			"type":"operator",
			"syntax":[
				"line path from <mFrom> to <mTo>"
			],
			"display syntax":[
				"line path from <i>mFrom</i> to <i>mTo</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new path.",
			"parameters":[{
				"name":"mFrom",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mTo",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			}],
			"examples":[{
				"script":"// Create a line path\nvariable tPath as Path\nput line path from point [50,100] to point [100,50] into tPath"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new line path."
			}],
			"tags":["Canvas"]
		},{
			"id":"364",
			"name":"colorpropertyblue",
			"display name":"ColorPropertyBlue",
			"type":"operator",
			"syntax":[
				"the blue of <mColor>"
			],
			"display syntax":[
				"the blue of <i>mColor</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The blue component of a color value.",
			"parameters":[{
				"name":"mColor",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a color."
			}],
			"examples":[{
				"script":"variable tColor\nput color [0.75, 1.0, 0.5] into tColor\n\n// Store the old blue value\nvariable tBlue\nput the blue of tColor into tBlue\n\n// Set the blue component of the color to full intensity\nset the blue of tColor to 1"
			}],
			"description":"The blue component of <mColor>\n\n>*Note:* The component value denotes the intensity of that component, expressed as a real number between 0 and 1.",
			"tags":["Canvas"]
		},{
			"id":"365",
			"name":"gradientstoppropertycolor",
			"display name":"GradientStopPropertyColor",
			"type":"operator",
			"syntax":[
				"the color of <mStop>"
			],
			"display syntax":[
				"the color of <i>mStop</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The color of a gradient stop value.",
			"parameters":[{
				"name":"mStop",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient stop."
			}],
			"examples":[{
				"script":"variable tStop\nput gradient stop at 0 with color [1,1,1] into tStop\n\n// Get the color of a stop\nvariable tColor\nput the color of tStop into tColor\n\n// Set the stop color to red\nset the color of tStop to color [1,0,0]"
			}],
			"description":"The color of <mStop>.",
			"tags":["Canvas"]
		},{
			"id":"366",
			"name":"solidpaintpropertycolor",
			"display name":"SolidPaintPropertyColor",
			"type":"operator",
			"syntax":[
				"the color of <mSolid>"
			],
			"display syntax":[
				"the color of <i>mSolid</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The color of a solid paint value.\nmPaint:An expression which evaluates to a solid paint.",
			"examples":[{
				"script":"// Create a new green paint\nvariable tPaint\nput solid paint with color [0,1,0] into tPaint\n\n// Store the old color of tPaint\nvariable tColor\nput the color of tPaint into tColor\n\n// Set the color of tPaint to blue\nset the color of tPaint to color [0,0,1]"
			}],
			"description":"The color of <mPaint>.",
			"tags":["Canvas"]
		},{
			"id":"367",
			"name":"effectmakewithproperties",
			"display name":"EffectMakeWithProperties",
			"type":"operator",
			"syntax":[
				"<mType> effect with properties <mProperties>"
			],
			"display syntax":[
				"<i>mType</i> effect with properties <i>mProperties</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new effect.",
			"parameters":[{
				"name":"mType",
				"type":"",
				"refparam":"false",
				"description":"One of color overlay, inner shadow, outer shadow, inner glow, outer glow."
			},{
				"name":"mProperties",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to an array."
			}],
			"examples":[{
				"script":"// Create an effect from an array of properties\nvariable tProps as Array\nput the empty array into tProps\n\nput color [0,0,0] into tProps[\"color\"]\nput \"source over\" into tProps[\"blend mode\"]\nput 191 into tProps[\"opacity\"]\nput 0 into tProps[\"spread\"]\nput 5 into tProps[\"size\"]\nput 5 into tProps[\"distance\"]\nput 60 into tProps[\"angle\"]\n\nvariable tEffect as Effect\nput outer shadow effect with properties tProps into tEffect"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new effect of type <mType> with properties read from <mProperties>."
			}],
			"tags":["Canvas"]
		},{
			"id":"368",
			"name":"gradientoperationtransform",
			"display name":"GradientOperationTransform",
			"type":"statement",
			"syntax":[
				"transform <mGradient> by <mTransform>"
			],
			"display syntax":[
				"transform <i>mGradient</i> by <i>mTransform</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Apply a transform to a gradient paint.",
			"parameters":[{
				"name":"mTransform",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a transform."
			},{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\n// Scale the gradient with a transform\ntransform tGradient by transform with scale [2,2]"
			}],
			"description":"Concatenates the transform of <mGradient> with <mTransform>.",
			"tags":["Canvas"]
		},{
			"id":"369",
			"name":"gradientpropertyramp",
			"display name":"GradientPropertyRamp",
			"type":"operator",
			"syntax":[
				"the ramp of <mGradient>"
			],
			"display syntax":[
				"the ramp of <i>mGradient</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The ramp of a gradient paint.",
			"parameters":[{
				"name":"mGradient",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a gradient."
			}],
			"examples":[{
				"script":"// Create new gradient paint\nvariable tGradient\nput linear gradient with ramp [gradient stop at 0 with color [0,0,0], gradient stop at 1 with color [1,1,1]] into tGradient\n\n// Get the gradient ramp\nvariable tRamp\nput the ramp of tGradient into tRamp\n\n// Change the color of the first stop\nset the color of element 1 of tRamp to color [1,0,0]\n\n// Set the new gradient ramp\nset the ramp of tGradient to tRamp"
			}],
			"description":"The ramp of <mGradient>. The ramp is a list of gradient stops that describes the color transitions along the length of the gradient",
			"tags":["Canvas"]
		},{
			"id":"370",
			"name":"pathmakewithsector",
			"display name":"PathMakeWithSector",
			"type":"operator",
			"syntax":[
				"sector path centered at <mCenter> with [ radius <mRadius> | radii <mRadii> ] from <mStartAngle> to <mEndAngle>"
			],
			"display syntax":[
				"sector path centered at <i>mCenter</i> with [ radius <i>mRadius</i> | radii <i>mRadii</i> ] from <i>mStartAngle</i> to <i>mEndAngle</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Creates a new path.",
			"parameters":[{
				"name":"mCenter",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mRadius",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mRadii",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			},{
				"name":"mStartAngle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mEndAngle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			}],
			"examples":[{
				"script":"// Create an elliptical sector path\nvariable tPath as Path\nput sector path centered at point [100,100] with radii [100,75] from 0 to 270 into tPath"
			},{
				"script":"// Create a circular sector path\nvariable tPath as Path\nput sector path centered at point [100,100] with radius 100 from 0 to 270 into tPath"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A new sector path."
			}],
			"tags":["Canvas"]
		},{
			"id":"371",
			"name":"pathoperationellipticarctowithflags",
			"display name":"PathOperationEllipticArcToWithFlags",
			"type":"statement",
			"syntax":[
				"arc to <mEnd> with radii <mRadii> rotated by <mAngle> taking ( largest | smallest ) ( clockwise | anticlockwise ) route on <mPath>"
			],
			"display syntax":[
				"arc to <i>mEnd</i> with radii <i>mRadii</i> rotated by <i>mAngle</i> taking ( largest | smallest ) ( clockwise | anticlockwise ) route on <i>mPath</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"Adds an arc to a path.",
			"parameters":[{
				"name":"mEnd",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a point."
			},{
				"name":"mRadii",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a list of numbers."
			},{
				"name":"mAngle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			},{
				"name":"mPath",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a path."
			}],
			"examples":[{
				"script":"variable tPath\nput the empty path into tPath\n\n// Begin a new subpath\nmove to point [25, 50] on tPath\n\n// Continue path with an arc to 50,25\narc to point [50, 25] with radii [25, 25] rotated by 0 taking smallest clockwise route on tPath\n\n// Begin a new subpath\nmove to point [75, 50] on tPath\n// Continue path with a large arc to 50,75\narc to point [50, 75] with radii [25, 25] rotated by 0 taking largest clockwise route on tPath"
			}],
			"description":"Adds an arc from the previous point to <mEnd> on <mPath>, following a section of an ellipse with the given radii & angle.\n  As there can be two different ellipses that match the parameters, and two potential arcs for each ellipse, the *largest*, *smallest*, *clockwise*, and *anticlockwise* options allow one arc to specified from the four potential arcs.",
			"tags":["Canvas"]
		},{
			"id":"372",
			"name":"canvaspropertyopacity",
			"display name":"CanvasPropertyOpacity",
			"type":"operator",
			"syntax":[
				"the opacity of <mCanvas>"
			],
			"display syntax":[
				"the opacity of <i>mCanvas</i>"
			],
			"associations":["com.livecode.canvas"],
			"summary":"The current opacity setting of a canvas.",
			"parameters":[{
				"name":"mCanvas",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a canvas."
			}],
			"examples":[{
				"script":"// make subsequent drawing operations render with half transparency\nset the opacity of this canvas to 0.5"
			}],
			"description":"The opacity of drawing operations on <mCanvas>, as a number between 0 and 1.",
			"tags":["Canvas"]
		},{
			"id":"373",
			"name":"onlayerchanged",
			"display name":"OnLayerChanged",
			"type":"message",
			"syntax":[
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnLayerChanged"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget layer is changed.",
			"tags":["Widget"]
		},{
			"id":"374",
			"name":"placewidget",
			"display name":"PlaceWidget",
			"type":"statement",
			"syntax":[
				"place <mWidget>"
			],
			"display syntax":[
				"place <i>mWidget</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Add a child widget to the parent.",
			"parameters":[{
				"name":"mWidget",
				"type":"",
				"refparam":"false",
				"description":"The child widget object."
			}],
			"examples":[{
				"script":"variable tNavbar as Widget\nput a new widget \"com.livecode.widget.navbar\" into tNavbar\nplace tNavbar"
			}],
			"description":"Adds a the specified child object to the widget in which the place statement is used.\n<mWidget> will reside on the layer above all previously placed widgets.",
			"tags":["Widget"]
		},{
			"id":"375",
			"name":"ispointnotwithinrect",
			"display name":"IsPointNotWithinRect",
			"type":"operator",
			"syntax":[
				"<Point> is not within <Rect>"
			],
			"display syntax":[
				"<i>Point</i> is not within <i>Rect</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Determines whether a point is within a rectangle.",
			"parameters":[{
				"name":"Point",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a Point."
			},{
				"name":"Rect",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a Rectangle."
			}],
			"examples":[{
				"script":"variable tClick as Point\nput the click position into tClick\n\nvariable tRect as Rectangle\nput my bounds into tRect\n\nif tClick is not within tRect then\n\t// click was outside of widget bounds\nend if"
			}],
			"tags":["Widget"]
		},{
			"id":"376",
			"name":"ondetach",
			"display name":"OnDetach",
			"type":"message",
			"syntax":[
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnDetach"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget is detached.",
			"tags":["Widget"]
		},{
			"id":"377",
			"name":"onload",
			"display name":"OnLoad",
			"type":"message",
			"syntax":[
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnLoad"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget is loaded.",
			"description":"Handler the <OnLoade> message to execute code when a stack containing the widget is loaded, for example setting default values of instance variables.\n>*Note:* Access to most script object operations is not allowed whilst an <OnLoad>\nhandler is running.",
			"tags":["Widget"]
		},{
			"id":"378",
			"name":"ondragleave",
			"display name":"OnDragLeave",
			"type":"message",
			"syntax":[
				"OnDragLeave",
				"OnDragEnter",
				"OnActionKeyPress <keyText>",
				"OnModifiersChanged",
				"OnKeyPress <keyText>",
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnDragLeave"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when an object is dragged outside of the widget rect.",
			"tags":["Widget"]
		},{
			"id":"379",
			"name":"ondragstart",
			"display name":"OnDragStart",
			"type":"message",
			"syntax":[
				"OnDragStart",
				"OnDragDrop",
				"OnDragMove",
				"OnDragLeave",
				"OnDragEnter",
				"OnActionKeyPress <keyText>",
				"OnModifiersChanged",
				"OnKeyPress <keyText>",
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnDragStart"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget begins to be dragged",
			"tags":["Widget"]
		},{
			"id":"380",
			"name":"themouselocation",
			"display name":"TheMouseLocation",
			"type":"expression",
			"syntax":[
				"the ( current ) mouse position"
			],
			"display syntax":[
				"the ( current ) mouse position"
			],
			"associations":["com.livecode.widget"],
			"summary":"Determines the location of the mouse pointer.",
			"examples":[{
				"script":"variable tClick as Point\nput the click position into tClick\n\nvariable tRect as Rectangle\nput my bounds into tRect\n\nif tClick is within tRect then\n\t// click was within widget bounds\nend if"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The location of the mouse pointer."
			}],
			"description":"Use the 'current' form to obtain the asynchronous mouse position.",
			"tags":["Widget"]
		},{
			"id":"381",
			"name":"ontimer",
			"display name":"OnTimer",
			"type":"message",
			"syntax":[
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnTimer"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when a timer message has been scheduled.",
			"examples":[{
				"script":"// Create a timer loop\npublic handler OnTimer()\n\t...\n\tschedule timer in 1 second\nend handler"
			}],
			"description":"Handle the <OnTimer> message to perform an action at a scheduled time.\n>*Note:* OnTimer messages are only sent whilst in browse tool mode. If a timer is\ndelivered whilst in pointer tool mode it will be deferred until browser tool mode is\nre-entered.",
			"references":{
				"statement":["ScheduleTimerIn"]
			},
			"tags":["Widget"]
		},{
			"id":"382",
			"name":"",
			"display name":"",
			"type":"handler\n:",
			"syntax":[
				"MCWidgetEvalIsPointWithinRect(<pPoint>,<pRect>,<rWithin>)"
			],
			"display syntax":[
				"MCWidgetEvalIsPointWithinRect(<i>pPoint</i>,<i>pRect</i>,<i>rWithin</i>)"
			],
			"associations":["com.livecode.widget"],
			"tags":["Widget"]
		},{
			"id":"383",
			"name":"placewidgetat",
			"display name":"PlaceWidgetAt",
			"type":"statement",
			"syntax":[
				"place <mWidget> at ( bottom | top )"
			],
			"display syntax":[
				"place <i>mWidget</i> at ( bottom | top )"
			],
			"associations":["com.livecode.widget"],
			"summary":"Add a child widget to the parent on the top or bottom layer",
			"parameters":[{
				"name":"mWidget",
				"type":"",
				"refparam":"false",
				"description":"The child widget object."
			}],
			"examples":[{
				"script":"variable tNavbar as Widget\nput a new widget \"com.livecode.widget.navbar\" into tNavbar\nplace tNavbar at top"
			}],
			"description":"Adds a the specified child object to the widget in which the place statement is used.\nUsing the \"top\" (resp. \"bottom\") variant will cause <mWidget> to be placed on the layer above (resp. below) all previously placed widgets.",
			"tags":["Widget"]
		},{
			"id":"384",
			"name":"onstopediting",
			"display name":"OnStopEditing",
			"type":"message",
			"syntax":[
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnStopEditing"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the browse tool is selected.",
			"description":"Handle the <OnStopEditing> message to perform an action when the browse tool is selected.",
			"tags":["Widget"]
		},{
			"id":"385",
			"name":"onmousehover",
			"display name":"OnMouseHover",
			"type":"message",
			"syntax":[
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnMouseHover"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the mouse pointer hovers over the widget's rect.",
			"tags":["Widget"]
		},{
			"id":"386",
			"name":"mydisabled",
			"display name":"MyDisabled",
			"type":"expression",
			"syntax":[
				"my disabled"
			],
			"display syntax":[
				"my disabled"
			],
			"associations":["com.livecode.widget"],
			"summary":"Returns the disabled state of the widget.",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The disabled state of the widget."
			}],
			"tags":["Widget"]
		},{
			"id":"387",
			"name":"send",
			"display name":"Send",
			"type":"statement",
			"syntax":[
				"send ( function | command ) <Message> [ with <Arguments> ]"
			],
			"display syntax":[
				"send ( function | command ) <i>Message</i> [ with <i>Arguments</i> ]"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sends a message to the widget script object.",
			"tags":["Widget"]
		},{
			"id":"388",
			"name":"widgetheightproperty",
			"display name":"WidgetHeightProperty",
			"type":"operator",
			"syntax":[
				"the height of <mWidget>"
			],
			"display syntax":[
				"the height of <i>mWidget</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Manipulates the height property of a child widget",
			"parameters":[{
				"name":"mWidget",
				"type":"",
				"refparam":"false",
				"description":"The child widget object"
			}],
			"examples":[{
				"script":"private variable mChild as Widget\n\npublic handler OnCreate() returns nothing\n    put a new widget \"com.livecode.widget.button\" into mChild\n    place mChild\nend handler\n\npublic handler OnGeometryChanged() returns nothing\n    -- ensure child widget remains same height as parent\n    set the height of mChild to my height\nend handler"
			}],
			"description":"Use the height property to set the height of a child widget.",
			"tags":["Widget"]
		},{
			"id":"389",
			"name":"onclose",
			"display name":"OnClose",
			"type":"message",
			"syntax":[
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnClose"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when card containing the widget is navigated away from.",
			"examples":[{
				"script":"public handler OnClose()\n  \t\t-- Schedule a timer to perform an action every 5 seconds\n \t\t cancel timer\nend handler"
			}],
			"description":"Handle the <OnClose> message to have the widget perform an action when the card containing the widget is navigated away from.",
			"tags":["Widget"]
		},{
			"id":"390",
			"name":"redrawall",
			"display name":"RedrawAll",
			"type":"statement",
			"syntax":[
				"redraw all"
			],
			"display syntax":[
				"redraw all"
			],
			"associations":["com.livecode.widget"],
			"summary":"Redraws the widget.",
			"examples":[{
				"script":"private variable mColor as Color\n\npublic handler OnClick()\n\tput color [ any number, any number, any number ] into mColor\n\tredraw all\nend handler\n\npublic handler OnPaint()\n\t...\n\tset the paint of this canvas to solid paint with color mColor\n\t...\nend handler"
			}],
			"description":"Use redraw all to redraw the widget, for example after setting a property which should trigger a change in appearance.",
			"references":{
				"message":["OnPaint"]
			},
			"tags":["Widget"]
		},{
			"id":"391",
			"name":"iseditmode",
			"display name":"IsEditMode",
			"type":"expression",
			"syntax":[
				"in edit mode"
			],
			"display syntax":[
				"in edit mode"
			],
			"associations":["com.livecode.widget"],
			"summary":"Determines whether the IDE is in edit mode.",
			"tags":["Widget"]
		},{
			"id":"392",
			"name":"com.livecode.widget",
			"display name":"com.livecode.widget",
			"type":"library",
			"display syntax":[
				"com.livecode.widget"
			],
			"description":"This library consists of the operations on widgets provided by LiveCode Builder."
		},{
			"id":"393",
			"name":"onmousemove",
			"display name":"OnMouseMove",
			"type":"message",
			"syntax":[
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnMouseMove"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the mouse pointer moves within the widget's rect.",
			"tags":["Widget"]
		},{
			"id":"394",
			"name":"mywidth",
			"display name":"MyWidth",
			"type":"expression",
			"syntax":[
				"my width"
			],
			"display syntax":[
				"my width"
			],
			"associations":["com.livecode.widget"],
			"summary":"Returns the height of the widget.",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The height of the widget."
			}],
			"tags":["Widget"]
		},{
			"id":"395",
			"name":"widgetenabledproperty",
			"display name":"WidgetEnabledProperty",
			"type":"operator",
			"syntax":[
				"the enabled of <mWidget>"
			],
			"display syntax":[
				"the enabled of <i>mWidget</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Manipulates the enabled property of a child widget",
			"parameters":[{
				"name":"mWidget",
				"type":"",
				"refparam":"false",
				"description":"The child widget object"
			}],
			"examples":[{
				"script":"private variable mChild as Widget\n\npublic handler OnCreate() returns nothing\n    put a new widget \"com.livecode.widget.button\" into mChild\n    place mChild\n    -- mChild is initially disabled\n    set the enabled of mChild to false\nend handler"
			}],
			"description":"Use the enabled property to control the disabled/enabled state of child widgets.\nThe child widget can change its appearance and behavior based on the result of the '<MyEnabled|my enabled>' expression.",
			"references":{
				"expression":["MyDisabled"]
			},
			"tags":["Widget"]
		},{
			"id":"396",
			"name":"onmousestilldown",
			"display name":"OnMouseStillDown",
			"type":"message",
			"syntax":[
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnMouseStillDown"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the mouse button is held down within the widget's rect.",
			"tags":["Widget"]
		},{
			"id":"397",
			"name":"mybounds",
			"display name":"MyBounds",
			"type":"expression",
			"syntax":[
				"my bounds"
			],
			"display syntax":[
				"my bounds"
			],
			"associations":["com.livecode.widget"],
			"summary":"Returns the bounds of the widget.",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The bounds of the widget."
			}],
			"tags":["Widget"]
		},{
			"id":"398",
			"name":"onmodifierschanged",
			"display name":"OnModifiersChanged",
			"type":"message",
			"syntax":[
				"OnModifiersChanged",
				"OnKeyPress <keyText>",
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnModifiersChanged"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the keyboard modifiers are changed.",
			"tags":["Widget"]
		},{
			"id":"399",
			"name":"onvisibilitychanged",
			"display name":"OnVisibilityChanged",
			"type":"message",
			"syntax":[
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnVisibilityChanged <i>isVisible</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget visibility changed.",
			"parameters":[{
				"name":"isVisible",
				"type":"bool",
				"refparam":"false",
				"description":"Whether the widget is now visible or not."
			}],
			"examples":[{
				"script":"private variable mAnimate as Boolean\n\npublic handler OnVisibilityChanged(in pVisible as Boolean)\n\tput pVisible into mAnimate\nend handler"
			}],
			"description":"Handle the <OnVisibilityChanged> message to execute code when the widget becomes visible or invisible.",
			"tags":["Widget"]
		},{
			"id":"400",
			"name":"canceltimer",
			"display name":"CancelTimer",
			"type":"statement",
			"syntax":[
				"cancel timer"
			],
			"display syntax":[
				"cancel timer"
			],
			"associations":["com.livecode.widget"],
			"summary":"Cancels a timer.",
			"examples":[{
				"script":"// Cancel the timer when the widget is no longer on the current card.\npublic handler OnClose()\n\tcancel timer\nend handler"
			}],
			"description":"Use to cancel a timer scheduled by the <ScheduleTimerIn|schedule> statement.",
			"references":{
				"statement":["ScheduleTimerIn"],
				"message":["OnTimer"]
			},
			"tags":["Widget"]
		},{
			"id":"401",
			"name":"propertyofwidget",
			"display name":"PropertyOfWidget",
			"type":"operator",
			"syntax":[
				"property <mName> of <mWidget>"
			],
			"display syntax":[
				"property <i>mName</i> of <i>mWidget</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Manipulates a property implemented by a child widget.",
			"parameters":[{
				"name":"mName",
				"type":"",
				"refparam":"false",
				"description":"The name of a property declared by <mWidget>"
			},{
				"name":"mWidget",
				"type":"",
				"refparam":"false",
				"description":"The child widget object"
			}],
			"examples":[{
				"script":"variable tChild as Widget\nput a new widget \"com.livecode.widget.navbar\" into tChild\nplace tChild\n-- Initialise selected element of nav bar to 1\nset property \"selectedItem\" of tChild to 1"
			}],
			"description":"Use the <PropertyOfWidget> operator to get or set properties of a child widget that are not and of the built-in\nwidget properties.",
			"tags":["Widget"]
		},{
			"id":"402",
			"name":"ondragfinish",
			"display name":"OnDragFinish",
			"type":"message",
			"syntax":[
				"OnDragFinish",
				"OnDragStart",
				"OnDragDrop",
				"OnDragMove",
				"OnDragLeave",
				"OnDragEnter",
				"OnActionKeyPress <keyText>",
				"OnModifiersChanged",
				"OnKeyPress <keyText>",
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnDragFinish"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget finishes being dragged",
			"tags":["Widget"]
		},{
			"id":"403",
			"name":"onsave",
			"display name":"OnSave",
			"type":"message",
			"syntax":[
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnSave"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget is saved.",
			"description":"Handler the <OnSave> message to execute code when a stack containing the widget is saved.\n>*Note:* Access to most script object operations is not allowed whilst an <OnSave>\nhandler is running.",
			"tags":["Widget"]
		},{
			"id":"404",
			"name":"onmouseenter",
			"display name":"OnMouseEnter",
			"type":"message",
			"syntax":[
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnMouseEnter"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the mouse pointer enters the widget's rect.",
			"tags":["Widget"]
		},{
			"id":"405",
			"name":"theclickbutton",
			"display name":"TheClickButton",
			"type":"expression",
			"syntax":[
				"the ( current ) click button"
			],
			"display syntax":[
				"the ( current ) click button"
			],
			"associations":["com.livecode.widget"],
			"summary":"Determines the mouse button which started the mouse click.",
			"examples":[{
				"script":"    variable tButton as integer\n    put the click button into tButton\n\n    if tButton is 1 then\n        // do primary button action\n    else\n        // do secondary button action\n    end if"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The index of the mouse button which started the mouse click."
			}],
			"tags":["Widget"]
		},{
			"id":"406",
			"name":"onactionkeypress",
			"display name":"OnActionKeyPress",
			"type":"message",
			"syntax":[
				"OnActionKeyPress <keyText>",
				"OnModifiersChanged",
				"OnKeyPress <keyText>",
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnActionKeyPress <i>keyText</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when an action key is pressed while the widget has focus.",
			"parameters":[{
				"name":"keyText",
				"type":"string",
				"refparam":"false",
				"description":"The key pressed"
			}],
			"tags":["Widget"]
		},{
			"id":"407",
			"name":"onfocusenter",
			"display name":"OnFocusEnter",
			"type":"message",
			"syntax":[
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnFocusEnter"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget gains focus.",
			"tags":["Widget"]
		},{
			"id":"408",
			"name":"placewidgetrelative",
			"display name":"PlaceWidgetRelative",
			"type":"statement",
			"syntax":[
				"place <mWidget> ( below | above ) <mOtherWidget>"
			],
			"display syntax":[
				"place <i>mWidget</i> ( below | above ) <i>mOtherWidget</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Add a child widget to the parent on a layer relative to that of a previously placed child.",
			"parameters":[{
				"name":"mWidget",
				"type":"",
				"refparam":"false",
				"description":"The child widget object."
			},{
				"name":"mOtherWidget",
				"type":"",
				"refparam":"false",
				"description":"The child to place <mWidget> relative to."
			}],
			"examples":[{
				"script":"variable tNavbar as Widget\nput a new widget \"com.livecode.widget.navbar\" into tNavbar\nplace tNavbar\n\nvariable tTreeView as Widget\nput a new widget \"com.livecode.widget.treeView\" into tTreeView\nplace tTreeView below tNavbar"
			}],
			"description":"Adds a the specified child object to the widget in which the place statement is used. <mWidget> is placed either below or above\nthe layer on which <mOtherWidget> is placed, depending on which variant is used.",
			"tags":["Widget"]
		},{
			"id":"409",
			"name":"ispoppedup",
			"display name":"IsPoppedUp",
			"type":"expression",
			"syntax":[
				"currently popped up"
			],
			"display syntax":[
				"currently popped up"
			],
			"associations":["com.livecode.widget"],
			"summary":"Tests if the current widget is in a popup window.\nResturns:True if the current widget is in a popup window, False otherwise.",
			"examples":[{
				"script":"variable mSelected\n\npublic handler OnClick()\n\tvariable tOption\n\tput getOptionAtPosition(the click position) into tOption\n\tif tOption is not empty then\n\t\tput tOption into mSelected\n\n\t\t// If this widget is being used as a popup then we close the popup and return a value to the caller\n\t\tif currently popped up then\n\t\t\tif mSelected is \"Cancel\" then\n\t\t\t\t// Dismiss the popup without returning a value - the result will be nothing\n\t\t\t\tclose popup\n\t\t\telse\n\t\t\t\t// Dismiss the popup - the result will be the value of mSelected\n\t\t\t\tclose popup returning mSelected\n\t\t\tend if\n\t\tend if\n\tend if\nend handler\n\nprivate handler getOptionAtPosition(in pPosition as Point) returns String\n\t// Return the name of the option at the given point\n\t...\nend handler"
			}],
			"description":"Use to determine if this widget is being displayed within a popup window.",
			"tags":["Widget"]
		},{
			"id":"410",
			"name":"anewwidget",
			"display name":"ANewWidget",
			"type":"operator",
			"syntax":[
				"a new widget <mKind>"
			],
			"display syntax":[
				"a new widget <i>mKind</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Create a widget object of the specified kind",
			"examples":[{
				"script":"variable tNavbar as Widget\nput a new widget \"com.livecode.widget.navbar\" into tNavbar"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A widget object."
			}],
			"description":"Create a new widget object of the specified kind. The widget can then be placed with the <PlaceWidget|place> statement.",
			"references":{
				"statement":["PlaceWidget"]
			},
			"tags":["Widget"]
		},{
			"id":"411",
			"name":"scheduletimerin",
			"display name":"ScheduleTimerIn",
			"type":"statement",
			"syntax":[
				"schedule timer in <Time> seconds"
			],
			"display syntax":[
				"schedule timer in <i>Time</i> seconds"
			],
			"associations":["com.livecode.widget"],
			"summary":"Schedules a timer.",
			"parameters":[{
				"name":"Time",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a number."
			}],
			"examples":[{
				"script":"// Create a timer loop\npublic handler OnTimer()\n\t...\n\tschedule timer in 1 second\nend handler"
			}],
			"description":"Scheduling a timer causes an <OnTimer> message to be sent to the widget in <Time> seconds.",
			"references":{
				"message":["OnTimer"]
			},
			"tags":["Widget"]
		},{
			"id":"412",
			"name":"ondragmove",
			"display name":"OnDragMove",
			"type":"message",
			"syntax":[
				"OnDragMove",
				"OnDragLeave",
				"OnDragEnter",
				"OnActionKeyPress <keyText>",
				"OnModifiersChanged",
				"OnKeyPress <keyText>",
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnDragMove"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when a dragged object is moved within the widget rect.",
			"tags":["Widget"]
		},{
			"id":"413",
			"name":"onmousescroll",
			"display name":"OnMouseScroll",
			"type":"message",
			"syntax":[
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnMouseScroll"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the mouse wheel is scrolled within the widget's rect.",
			"tags":["Widget"]
		},{
			"id":"414",
			"name":"ongeometrychanged",
			"display name":"OnGeometryChanged",
			"type":"message",
			"syntax":[
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnGeometryChanged"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget geometry changed.",
			"examples":[{
				"script":"private variable mLabel as String\n\npublic handler OnGeometryChanged()\n\tif my width is not my height then\n\t\tput \"Rectangle\" into mLabel\n\telse\n\t\tput \"Square\" into mLabel\n\tend if\n\tredraw all\t\nend handler"
			}],
			"description":"Handle the <OnGeometryChanged> message to perform specific actions that depend on the geometry of the widget, for example the locations on the canvas where parts of the widget are drawn.",
			"tags":["Widget"]
		},{
			"id":"415",
			"name":"popupmenu",
			"display name":"PopupMenu",
			"type":"statement",
			"syntax":[
				"popup menu <mMenu> at <mAt>"
			],
			"display syntax":[
				"popup menu <i>mMenu</i> at <i>mAt</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Displays a popup menu.\nMenu:An expression that evaluates to a string, which describes the menu items.\nLocation:An expression that evaluates to a <Point> relative to the current widget. The topleft corner of the popup window will be placed here.",
			"examples":[{
				"script":"private variable mFont as Font\n\npublic handler OnMouseDown()\n\tpopup menu \"Helvetica\\nTimes New Roman\\nArial\" at the mouse position\n\tif the result is not nothing then\n\t\tput font (the result) at size 20 into mFont\n\t\tredraw all\n\tend if\nend handler\n\npublic handler OnPaint()\n\t...\n\tset the font of this canvas to mFont\n\t...\nend handler"
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"The selected menu item. If the menu is dismissed (by clicking outside the bounds of the menu) this value will be nothing."
			}],
			"description":"Use to popup a menu at the specified location.",
			"tags":["Widget"]
		},{
			"id":"416",
			"name":"myrectangle",
			"display name":"MyRectangle",
			"type":"expression",
			"syntax":[
				"my rectangle"
			],
			"display syntax":[
				"my rectangle"
			],
			"associations":["com.livecode.widget"],
			"summary":"Returns the rectangle of the widget in the parent",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The rectangle of the widget in the parent"
			}],
			"tags":["Widget"]
		},{
			"id":"417",
			"name":"myenabled",
			"display name":"MyEnabled",
			"type":"expression",
			"syntax":[
				"my enabled"
			],
			"display syntax":[
				"my enabled"
			],
			"associations":["com.livecode.widget"],
			"summary":"Returns the enabled state of the widget.",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The enabled state of the widget."
			}],
			"tags":["Widget"]
		},{
			"id":"418",
			"name":"oncreate",
			"display name":"OnCreate",
			"type":"message",
			"syntax":[
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnCreate"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget is created.",
			"examples":[{
				"script":"private variable mPrimaryColor as Color\nprivate variable mSecondaryColor as Color\n\npublic handler OnCreate()\n\tput color [ 0.5, 0.5, 1.0 ] into mPrimaryColor\n\tput color [ 0.0, 0.0, 1.0 ] into mSecondaryColor\nend handler"
			}],
			"description":"Handle the <OnCreate> message to have the widget perform an action when it is created, for example setting default values of instance variables.\n>*Note:* Access to most script object operations is not allowed whilst an <OnCreate>\nhandler is running.",
			"tags":["Widget"]
		},{
			"id":"419",
			"name":"closepopupwithresult",
			"display name":"ClosePopupWithResult",
			"type":"statement",
			"syntax":[
				"close popup [ returning <Result> ]"
			],
			"display syntax":[
				"close popup [ returning <i>Result</i> ]"
			],
			"associations":["com.livecode.widget"],
			"summary":"Closes the current widget popup.",
			"parameters":[{
				"name":"Result",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to any type. The result of popping up this widget."
			}],
			"examples":[{
				"script":"variable mSelected\n\npublic handler OnClick()\n\tvariable tOption\n\tput getOptionAtPosition(the click position) into tOption\n\tif tOption is not empty then\n\t\tput tOption into mSelected\n\n\t\t// If this widget is being used as a popup then we close the popup and return a value to the caller\n\t\tif currently popped up then\n\t\t\tif mSelected is \"Cancel\" then\n\t\t\t\t// Dismiss the popup without returning a value - the result will be nothing\n\t\t\t\tclose popup\n\t\t\telse\n\t\t\t\t// Dismiss the popup - the result will be the value of mSelected\n\t\t\t\tclose popup returning mSelected\n\t\t\tend if\n\t\tend if\n\tend if\nend handler\n\nprivate handler getOptionAtPosition(in pPosition as Point) returns String\n\t// Return the name of the option at the given point\n\t...\nend handler"
			}],
			"description":"Use to close the current popup, and optionally set a return value for the <PopupWidget> statement that launched it.",
			"references":{
				"statement":["PopupWidget"],
				"expression":["IsPoppedUp"]
			},
			"tags":["Widget"]
		},{
			"id":"420",
			"name":"myheight",
			"display name":"MyHeight",
			"type":"expression",
			"syntax":[
				"my height"
			],
			"display syntax":[
				"my height"
			],
			"associations":["com.livecode.widget"],
			"summary":"Returns the height of the widget.",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The height of the widget."
			}],
			"tags":["Widget"]
		},{
			"id":"421",
			"name":"onopen",
			"display name":"OnOpen",
			"type":"message",
			"syntax":[
				"OnOpen"
			],
			"display syntax":[
				"OnOpen"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the card containing the widget becomes the current card.",
			"examples":[{
				"script":"public handler OnOpen()\n  \t\t-- Schedule a timer to perform an action every 5 seconds\n \t\t schedule timer in 5 seconds\nend handler"
			}],
			"description":"Handle the <OnOpen> message to have the widget perform an action when the card containing the widget becomes the current card, for example setting default values of instance variables.",
			"tags":["Widget"]
		},{
			"id":"422",
			"name":"onfocusleave",
			"display name":"OnFocusLeave",
			"type":"message",
			"syntax":[
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnFocusLeave"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget loses focus.",
			"tags":["Widget"]
		},{
			"id":"423",
			"name":"ontouchstart",
			"display name":"OnTouchStart",
			"type":"message",
			"syntax":[
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnTouchStart"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when a touch event begins within the widget's rect.",
			"tags":["Widget"]
		},{
			"id":"424",
			"name":"unplacewidget",
			"display name":"UnplaceWidget",
			"type":"statement",
			"syntax":[
				"unplace <mWidget>"
			],
			"display syntax":[
				"unplace <i>mWidget</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Remove a child widget from the parent.",
			"parameters":[{
				"name":"mWidget",
				"type":"",
				"refparam":"false",
				"description":"The child widget object."
			}],
			"examples":[{
				"script":"-- Remove any child widgets that are clicked on\npublic handler OnMouseUp() returns nothing\n    if the target is not nothing then\n        unplace the target\n    end if\nend handler"
			}],
			"description":"Unplaces the child widget from the widget in which the unplace statement is used.\nThe widget is no longer drawn.",
			"tags":["Widget"]
		},{
			"id":"425",
			"name":"popupwidget",
			"display name":"PopupWidget",
			"type":"statement",
			"syntax":[
				"popup widget <Kind> at <Location> [ with properties <Properties> ]"
			],
			"display syntax":[
				"popup widget <i>Kind</i> at <i>Location</i> [ with properties <i>Properties</i> ]"
			],
			"associations":["com.livecode.widget"],
			"summary":"Opens a widget within a popup window.",
			"parameters":[{
				"name":"Kind",
				"type":"",
				"refparam":"false",
				"description":"The unique identifier of the widget to use for the popup."
			},{
				"name":"Location",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a <Point> relative to the current widget. The topleft corner of the popup window will be placed here."
			},{
				"name":"Properties",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to an <array>. For each key of the array, the popup widget will be initialized by setting that property to the value for that key."
			}],
			"examples":[{
				"script":"private variable mColor as Color\n\npublic handler OnClick()\n\tvariable tProperties as Array\n\tput the empty array into tProperties\n\tput mColor into tProperties[\"currentColor\"]\n\n\tpopup widget \"com.livecode.widget.ColorPicker\" at the mouse position with properties tProperties\n\tif the result is not nothing then\n\t\tput the result into mColor\n\t\tredraw all\n\tend if\nend handler\n\npublic handler OnPaint()\n\t...\n\tset the paint of this canvas to solid paint with color mColor\n\t...\nend handler"
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"The result returned by the popup. If the popup is dismissed (by clicking outside the bounds of the popup) this value will be nothing."
			}],
			"description":"Use to display a widget within a popup window, for example as a tooltip or picker dialog.",
			"references":{
				"expression":["IsPoppedUp"],
				"statement":["ClosePopupWithResult"],
				"operator":["IsDefined"]
			},
			"tags":["Widget"]
		},{
			"id":"426",
			"name":"ispointwithinrect",
			"display name":"IsPointWithinRect",
			"type":"operator",
			"syntax":[
				"<Point> is within <Rect>"
			],
			"display syntax":[
				"<i>Point</i> is within <i>Rect</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Determines whether a point is within a rectangle.",
			"parameters":[{
				"name":"Point",
				"type":"Point",
				"refparam":"false",
				"description":"An expression that evaluates to a Point."
			},{
				"name":"Rect",
				"type":"Rectangle",
				"refparam":"false",
				"description":"An expression that evaluates to a Rectangle."
			}],
			"examples":[{
				"script":"variable tClick as Point\nput the click position into tClick\n\nvariable tRect as Rectangle\nput my bounds into tRect\n\nif tClick is within tRect then\n\t// click was within widget bounds\nend if"
			}],
			"tags":["Widget"]
		},{
			"id":"427",
			"name":"onmousecancelhover",
			"display name":"OnMouseCancelHover",
			"type":"message",
			"syntax":[
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnMouseCancelHover"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the mouse pointer continues to hover outside of the widget's rect.",
			"tags":["Widget"]
		},{
			"id":"428",
			"name":"annotationofwidget",
			"display name":"AnnotationOfWidget",
			"type":"operator",
			"syntax":[
				"annotation <mName> of <mWidget>"
			],
			"display syntax":[
				"annotation <i>mName</i> of <i>mWidget</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Manipulates an annotation of a child widget",
			"examples":[{
				"script":"-- variable storing the last child widget the mouse was over\nvariable mLastChild as String\n\npublic handler OnCreate() returns nothing\n    variable tChildWidget as Widget\n    variable tCount as Number\n    repeat with tCount from 1 up to 10\n        put a new widget \"com.livecode.widget.button\" into tChildWidget\n        set annotation \"Name\" of tChildWidget to (\"Child\" && tCount formatted as string)\n    end repeat\nend handler\n\npublic handler OnMouseEnter() returns nothing\n    if the target is not nothing then\n        put annotation \"Name\" of the target into mLastChild\n    end if\nend handler"
			}],
			"description":"An annotation is a named value assigned to a widget. They do not affect any intrinsic properties of the widget are are intended\nto be used to disambiguate widget objects returned from operators such as <TheTarget> or <MyChildren>.",
			"references":{
				"operator":["TheTarget","MyChildren"]
			},
			"tags":["Widget"]
		},{
			"id":"429",
			"name":"ondragdrop",
			"display name":"OnDragDrop",
			"type":"message",
			"syntax":[
				"OnDragDrop",
				"OnDragMove",
				"OnDragLeave",
				"OnDragEnter",
				"OnActionKeyPress <keyText>",
				"OnModifiersChanged",
				"OnKeyPress <keyText>",
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnDragDrop"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when a dragged object is released within the widget rect.",
			"tags":["Widget"]
		},{
			"id":"430",
			"name":"onmouseup",
			"display name":"OnMouseUp",
			"type":"message",
			"syntax":[
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnMouseUp"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the mouse button is released regardless of whether the pointer\nis within the widget's rect or not.",
			"tags":["Widget"]
		},{
			"id":"431",
			"name":"widgetrectangleproperty",
			"display name":"WidgetRectangleProperty",
			"type":"operator",
			"syntax":[
				"the rectangle of <mWidget>"
			],
			"display syntax":[
				"the rectangle of <i>mWidget</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Manipulates the rectangle property of a child widget",
			"parameters":[{
				"name":"mWidget",
				"type":"",
				"refparam":"false",
				"description":"The child widget object"
			}],
			"examples":[{
				"script":"private variable mChild as Widget\n\npublic handler OnCreate() returns nothing\n    put a new widget \"com.livecode.widget.button\" into mChild\n    place mChild\nend handler\n\npublic handler OnGeometryChanged() returns nothing\n    -- ensure child widget rect is that of the parent\n    set the rectangle of mChild to my bounds\nend handler"
			}],
			"description":"Use the rectangle property to set the rectangle of a child widget.",
			"tags":["Widget"]
		},{
			"id":"432",
			"name":"theclicklocation",
			"display name":"TheClickLocation",
			"type":"expression",
			"syntax":[
				"the ( current ) click position"
			],
			"display syntax":[
				"the ( current ) click position"
			],
			"associations":["com.livecode.widget"],
			"summary":"Determines the location of a mouse click.",
			"examples":[{
				"script":"variable tClick as Point\nput the click position into tClick\n\nvariable tRect as Rectangle\nput my bounds into tRect\n\nif tClick is within tRect then\n\t// click was within widget bounds\nend if"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The location of the mouse pointer when it was clicked."
			}],
			"description":"Use the mouse location to obtain the location of the mouse pointer when it was last clicked. Use the 'current' form to obtain the asynchronous click position.",
			"tags":["Widget"]
		},{
			"id":"433",
			"name":"widgetwidthproperty",
			"display name":"WidgetWidthProperty",
			"type":"operator",
			"syntax":[
				"the width of <mWidget>"
			],
			"display syntax":[
				"the width of <i>mWidget</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Manipulates the height property of a child widget",
			"parameters":[{
				"name":"mWidget",
				"type":"",
				"refparam":"false",
				"description":"The child widget object"
			}],
			"examples":[{
				"script":"private variable mChild as Widget\n\npublic handler OnCreate() returns nothing\n    put a new widget \"com.livecode.widget.button\" into mChild\n    place mChild\nend handler\n\npublic handler OnGeometryChanged() returns nothing\n    -- ensure child widget remains half the width of the parent\n    set the width of mChild to my width / 2\nend handler"
			}],
			"description":"Use the width property to set the width of a child widget.",
			"tags":["Widget"]
		},{
			"id":"434",
			"name":"ondestroy",
			"display name":"OnDestroy",
			"type":"message",
			"syntax":[
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnDestroy"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget is deleted.",
			"description":"Handle the OnDestroy message to have the widget perform an action when it is deleted.",
			"tags":["Widget"]
		},{
			"id":"435",
			"name":"onkeypress",
			"display name":"OnKeyPress",
			"type":"message",
			"syntax":[
				"OnKeyPress <keyText>",
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnKeyPress <i>keyText</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when a key is pressed while the widget has focus.",
			"parameters":[{
				"name":"keyText",
				"type":"string",
				"refparam":"false",
				"description":"The key pressed"
			}],
			"tags":["Widget"]
		},{
			"id":"436",
			"name":"ondoubleclick",
			"display name":"OnDoubleClick",
			"type":"message",
			"syntax":[
				"OnDoubleClick",
				"OnClick",
				"OnDragFinish",
				"OnDragStart",
				"OnDragDrop",
				"OnDragMove",
				"OnDragLeave",
				"OnDragEnter",
				"OnActionKeyPress <keyText>",
				"OnModifiersChanged",
				"OnKeyPress <keyText>",
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnDoubleClick"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget is double-clicked.",
			"tags":["Widget"]
		},{
			"id":"437",
			"name":"thetarget",
			"display name":"TheTarget",
			"type":"expression",
			"syntax":[
				"the target"
			],
			"display syntax":[
				"the target"
			],
			"associations":["com.livecode.widget"],
			"summary":"The child widget that started the current execution.",
			"examples":[{
				"script":"-- In the child widget\npublic handler OnMouseUp() returns nothing\n    -- handled in the parent\nend handler\n\n-- in the parent\npublic handler OnMouseUp() returns nothing\n    variable tComponent as optional Widget\n    put the target into tComponent\n    if tComponent is not nothing then\n        variable tName as String\n        put annotation \"Name\" of tComponent into tName\n        -- notify the parent or the script object which component was clicked\n        post \"componentClicked\" with [tName]\n    else\n        -- the mouseUp was not over a child widget\n    end if\nend handler"
			},{
				"script":"-- In the child widget\npublic handler OnClick() returns nothing\n    post \"componentClicked\"\nend handler\n\n-- In the parent widget\npublic handler OnComponentClicked() returns nothing\n    variable tComponent as optional Widget\n    put the target into tComponent\n    if tComponent is not nothing then\n        variable tName as String\n        put annotation \"Name\" of tComponent into tName\n        -- notify the parent or the script object which component was clicked\n        post \"componentClicked\" with [tName]\n    end if\nend handler"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A widget object."
			}],
			"description":"The target evaluates to either the first widget object in a chain of event handlers (eg <OnMouseUp>)\nor the widget from which a message was <Post|posted>.",
			"tags":["Widget"]
		},{
			"id":"438",
			"name":"onstartediting",
			"display name":"OnStartEditing",
			"type":"message",
			"syntax":[
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnStartEditing"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the pointer tool is selected.",
			"description":"Handle the <OnStartEditing> message to perform an action when the edit tool is selected.",
			"tags":["Widget"]
		},{
			"id":"439",
			"name":"post",
			"display name":"Post",
			"type":"statement",
			"syntax":[
				"post <Message> [ with <Arguments> ]"
			],
			"display syntax":[
				"post <i>Message</i> [ with <i>Arguments</i> ]"
			],
			"associations":["com.livecode.widget"],
			"summary":"Posts a message to the widget script object.",
			"tags":["Widget"]
		},{
			"id":"440",
			"name":"onmousestillhover",
			"display name":"OnMouseStillHover",
			"type":"message",
			"syntax":[
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnMouseStillHover"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the mouse pointer continues to hover over the widget's rect.",
			"tags":["Widget"]
		},{
			"id":"441",
			"name":"onpaint",
			"display name":"OnPaint",
			"type":"message",
			"syntax":[
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnPaint"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget is to be drawn.",
			"examples":[{
				"script":"public handler OnPaint()\n\tvariable tCirclePath as Path\n   \t\tput circle path centered at point [the width of my bounds/2,the height of my bounds/2] with radius (the width of my bounds/2) into tFacePath\n\tset the paint of this canvas to solid paint with color [1, 0, 1]\n\tfill tFacePath on this canvas\nend handler"
			}],
			"description":"Handle the <OnPaint> message to draw the widget when it needs to be updated.\n>*Note:* Access to most script object operations is not allowed whilst an OnPaint\nhandler is running.",
			"references":{
				"statement":["RedrawAll"]
			},
			"tags":["Widget"]
		},{
			"id":"442",
			"name":"ondragenter",
			"display name":"OnDragEnter",
			"type":"message",
			"syntax":[
				"OnDragEnter",
				"OnActionKeyPress <keyText>",
				"OnModifiersChanged",
				"OnKeyPress <keyText>",
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnDragEnter"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when an object is dragged onto the widget rect.",
			"tags":["Widget"]
		},{
			"id":"443",
			"name":"theclickcount",
			"display name":"TheClickCount",
			"type":"expression",
			"syntax":[
				"the ( current ) click count"
			],
			"display syntax":[
				"the ( current ) click count"
			],
			"associations":["com.livecode.widget"],
			"summary":"Determines the number of successive clicks within the click distance.",
			"examples":[{
				"script":"    variable tClickCount as integer\n    put the click count into tClickCount\n\n    if tClickCount is 1 then\n        // do single click action\n    else if tClickCount is 2 then\n        // do double click action\n    end if"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The number of clicks which have occured since the initial click within the standard 'click distance' from the original point."
			}],
			"tags":["Widget"]
		},{
			"id":"444",
			"name":"onmousedown",
			"display name":"OnMouseDown",
			"type":"message",
			"syntax":[
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnMouseDown"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the mouse button is pushed within the widget's rect.",
			"tags":["Widget"]
		},{
			"id":"445",
			"name":"widgetlocationproperty",
			"display name":"WidgetLocationProperty",
			"type":"operator",
			"syntax":[
				"the location of <mWidget>"
			],
			"display syntax":[
				"the location of <i>mWidget</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Manipulates the location property of a child widget",
			"parameters":[{
				"name":"mWidget",
				"type":"",
				"refparam":"false",
				"description":"The child widget object"
			}],
			"examples":[{
				"script":"private variable mChild as Widget\n\npublic handler OnCreate() returns nothing\n    -- place the child widget at the center of this widget\n    variable tLoc as Point\n    put point [my width / 2, my height / 2] into tLoc\n    put a new widget \"com.livecode.widget.button\" into mChild\n    place mChild\n    set the location of mChild to tLoc\nend handler"
			}],
			"description":"Use the location property to set the location of a child widget relative to the top left of the parent.\nThe location property is of type com.livecode.canvas.Point.",
			"tags":["Widget"]
		},{
			"id":"446",
			"name":"mychildren",
			"display name":"MyChildren",
			"type":"expression",
			"syntax":[
				"my children"
			],
			"display syntax":[
				"my children"
			],
			"associations":["com.livecode.widget"],
			"summary":"The currently placed child widgets of this widget.",
			"examples":[{
				"script":"public handler OnCreate() returns nothing\n    repeat 10 times\n        place a new widget \"com.livecode.widget.button\"\n    end repeat\nend handler\n\npublic handler OnGeometryChanged() returns nothing\n    variable tChildren as List\n    put my children into tChildren\n\n    variable tChild as Widget\n    variable tLeft as Number\n    put 0 into tLeft\n    -- arrange children from left to right\n    repeat for each element tChild in tChildren\n        set the rectangle of tChild to [tLeft, 0, tLeft + 50, my height]\n        add 50 to tLeft\n    end repeat\nend handler"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"A list of the child widgets of this widget."
			}],
			"description":"The list of widget objects returned by <MyChildren|my children> is in placement (i.e. layer) order.",
			"tags":["Widget"]
		},{
			"id":"447",
			"name":"themodifierkeys",
			"display name":"TheModifierKeys",
			"type":"expression\n:",
			"syntax":[
				"the ( current ) modifier keys"
			],
			"display syntax":[
				"the ( current ) modifier keys"
			],
			"associations":["com.livecode.widget"],
			"tags":["Widget"]
		},{
			"id":"448",
			"name":"onparentpropertychanged",
			"display name":"OnParentPropertyChanged",
			"type":"message",
			"syntax":[
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnParentPropertyChanged"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when a property of the widget parent is changed.",
			"description":"Handle the <OnParentPropertyChanged> message when a widget property depends on the properties of a parent object.",
			"tags":["Widget"]
		},{
			"id":"449",
			"name":"myscriptobject",
			"display name":"MyScriptObject",
			"type":"expression",
			"syntax":[
				"my script object"
			],
			"display syntax":[
				"my script object"
			],
			"associations":["com.livecode.widget"],
			"summary":"Returns the widget script object.",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The widget script object."
			}],
			"tags":["Widget"]
		},{
			"id":"450",
			"name":"onmousecancel",
			"display name":"OnMouseCancel",
			"type":"message",
			"syntax":[
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnMouseCancel"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when something happens which should cause the previous mouse down\naction to be considered cancelled. For example, opening a popup during OnMouseDown.",
			"tags":["Widget"]
		},{
			"id":"451",
			"name":"onattach",
			"display name":"OnAttach",
			"type":"message",
			"syntax":[
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnAttach"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget is attached.",
			"tags":["Widget"]
		},{
			"id":"452",
			"name":"widgetdisabledproperty",
			"display name":"WidgetDisabledProperty",
			"type":"operator",
			"syntax":[
				"the disabled of <mWidget>"
			],
			"display syntax":[
				"the disabled of <i>mWidget</i>"
			],
			"associations":["com.livecode.widget"],
			"summary":"Manipulates the disabled property of a child widget",
			"parameters":[{
				"name":"mWidget",
				"type":"",
				"refparam":"false",
				"description":"The child widget object"
			}],
			"examples":[{
				"script":"private variable mChild as Widget\n\npublic handler OnCreate() returns nothing\n    put a new widget \"com.livecode.widget.button\" into mChild\n    place mChild\n    -- mChild is initially disabled\n    set the disabled of mChild to true\nend handler"
			}],
			"description":"Use the disabled property to control the disabled/enabled state of child widgets.\nThe child widget can change its appearance and behavior based on the result of the '<MyDiabled|my disabled>' expression.",
			"references":{
				"expression":["MyDisabled"]
			},
			"tags":["Widget"]
		},{
			"id":"453",
			"name":"onclick",
			"display name":"OnClick",
			"type":"message",
			"syntax":[
				"OnClick",
				"OnDragFinish",
				"OnDragStart",
				"OnDragDrop",
				"OnDragMove",
				"OnDragLeave",
				"OnDragEnter",
				"OnActionKeyPress <keyText>",
				"OnModifiersChanged",
				"OnKeyPress <keyText>",
				"OnFocusLeave",
				"OnFocusEnter",
				"OnTouchStart",
				"OnMouseCancelHover",
				"OnMouseStillHover",
				"OnMouseHover",
				"OnMouseStillDown",
				"OnMouseScroll",
				"OnMouseUp",
				"OnMouseDown",
				"OnMouseCancel",
				"OnMouseMove",
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnClick"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the widget is clicked.",
			"tags":["Widget"]
		},{
			"id":"454",
			"name":"myfont",
			"display name":"MyFont",
			"type":"expression",
			"syntax":[
				"my font"
			],
			"display syntax":[
				"my font"
			],
			"associations":["com.livecode.widget"],
			"summary":"Returns the font of the widget.",
			"value":[{
				"name":"return",
				"type":"",
				"description":"The font of the widget"
			}],
			"description":"Use to return a font which reflects the current (effective) settings of the\nwidget's textFont, textSize and textStyle properties.",
			"tags":["Widget"]
		},{
			"id":"455",
			"name":"onmouseleave",
			"display name":"OnMouseLeave",
			"type":"message",
			"syntax":[
				"OnMouseLeave",
				"OnMouseEnter",
				"OnTimer",
				"OnLayerChanged",
				"OnStartEditing",
				"OnStopEditing",
				"OnParentPropertyChanged",
				"OnDestroy",
				"OnCreate",
				"OnLoad",
				"OnSave",
				"OnVisibilityChanged <isVisible>",
				"OnGeometryChanged",
				"OnPaint",
				"OnDetach",
				"OnAttach",
				"OnClose",
				"OnOpen"
			],
			"display syntax":[
				"OnMouseLeave"
			],
			"associations":["com.livecode.widget"],
			"summary":"Sent when the mouse pointer leaves the widget's rect.",
			"tags":["Widget"]
		},{
			"id":"456",
			"name":"countcodeunitsof",
			"display name":"CountCodeunitsOf",
			"type":"operator",
			"syntax":[
				"the number of codeunits in <Target>"
			],
			"display syntax":[
				"the number of codeunits in <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Counts the number of codeunits in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as Number\nvariable tSource as String\nput \"hello\" into tString\nput the number of codeunits in tString into tVar\n\nvariable tString as String\nput the empty string into tString\t\nrepeat tVar times\n\tput \"a\" after tString\nend repeat\n\n// tString contains \"aaaaa\""
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"The number of codeunits in <Target>."
			}],
			"description":">*Note:* The number of codeunits returns the number of codeunits of the target string. It does not perform any grapheme boundary analysis.",
			"tags":["Strings"]
		},{
			"id":"457",
			"name":"deletelastcodeunitof",
			"display name":"DeleteLastCodeunitOf",
			"type":"statement",
			"syntax":[
				"delete the last codeunit of <Target>"
			],
			"display syntax":[
				"delete the last codeunit of <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Deletes the last codeunit in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A string container."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"deadliness\" into tVar\ndelete the last codeunit of tVar -- tVar contains \"deadlines\""
			}],
			"description":"Replaces the last codeunit in <Target> with the empty string.\n\n>*Note:* It is an error if <Target> is the empty string.",
			"tags":["Strings"]
		},{
			"id":"458",
			"name":"codeunitisinstring",
			"display name":"CodeunitIsInString",
			"type":"operator",
			"syntax":[
				"<Needle> is in <Source>"
			],
			"display syntax":[
				"<i>Needle</i> is in <i>Source</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Determines whether <Needle> is in <Target>.\nTarget:An expression which evaluates to a string.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a codeunit."
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"True if <Needle> is among the codeunits of <Target>, and false otherwise."
			}],
			"description":">*Note:* It is an error if <Needle> evaluates to a string consisting of more than one codeunit.",
			"tags":["Strings"]
		},{
			"id":"459",
			"name":"deletesingletoncodeunitof",
			"display name":"DeleteSingletonCodeunitOf",
			"type":"statement",
			"syntax":[
				"delete codeunit <Index> of <Target>"
			],
			"display syntax":[
				"delete codeunit <i>Index</i> of <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Deletes the codeunit at index <Index> in <Target>.",
			"parameters":[{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A string container."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"thorough\" into tVar\ndelete codeunit 3 of tVar -- tVar contains \"through\""
			}],
			"description":"Replaces the codeunit at the given index with the empty string.\n\n>*Note:* It is an error if <Index> is out of range.",
			"tags":["Strings"]
		},{
			"id":"460",
			"name":"codeunitoffset",
			"display name":"CodeunitOffset",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of codeunits <Needle> in <Target>"
			],
			"display syntax":[
				"the ( first | last ) offset of codeunits <i>Needle</i> in <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Finds the first or last occurrence of <Needle> within <Target>",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput the first offset of codeunits \"art\" in \"cartoon\" into tVar -- tVar contains 2"
			},{
				"script":"variable tVar as Number\nvariable tFilePath as String\nput \"/Users/user/Documents/file.txt\" into tFilePath\nput the last offset of \"/\" in tFilePath into tVar\n\nvariable tFileName as String\nput codeunit 1 to tVar of tFilePath into tFileName -- tVar contains \"file.txt\""
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the offset of <Needle> in <Target>."
			}],
			"description":"The first (respectively last) offset of <Needle> in <Target> is number of codeunits between the first codeunit of <Target> and the first (respectively last) occurrence of <Needle>. If neither first or last is specified, then the first offset is found. If <Needle> does not occur in <Target>, then the output is 0.",
			"tags":["Strings"]
		},{
			"id":"461",
			"name":"com.livecode.codeunit",
			"display name":"com.livecode.codeunit",
			"type":"library",
			"display syntax":[
				"com.livecode.codeunit"
			],
			"description":"This library consists of the operations on codeunits included in the standard library of LiveCode Builder."
		},{
			"id":"462",
			"name":"singletoncodeunitof",
			"display name":"SingletonCodeunitOf",
			"type":"operator",
			"syntax":[
				"codeunit <Index> of <Target>"
			],
			"display syntax":[
				"codeunit <i>Index</i> of <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Designates the codeunit at index <Index> in <Target>.",
			"parameters":[{
				"name":"Index",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"put the empty string into codeunit 5 of tString // Locates codeunit 5 and removes it from tString"
			},{
				"script":"get codeunit 5 of tString // Evaluates codeunit 5"
			}],
			"description":"Either locates the codeunit at the given index for use as the target container of another operation, or evaluates the codeunit at the given index as the source of another operation.\n\n>*Note:* It is an error if <Index> is out of range.",
			"tags":["Strings"]
		},{
			"id":"463",
			"name":"codeunitoffsetafter",
			"display name":"CodeunitOffsetAfter",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of codeunits <Needle> after <After> in <Target>"
			],
			"display syntax":[
				"the ( first | last ) offset of codeunits <i>Needle</i> after <i>After</i> in <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Finds the first or last occurrence of <Needle> after a specified index in <Target>",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"After",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of Target."
			}],
			"examples":[{
				"script":"variable tVar as Number\nput the offset of codeunits \"nse\" after 4 in \"nonsense\" into tVar -- tVar contains 2"
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the offset of <Needle> after <After> in <Target>."
			}],
			"description":"The first (respectively last) offset of <Needle> in <Target> is number of codeunits between the first codeunit of the substring of <Target> beginning at codeunit <After> + 1, and the first (respectively last) occurrence of <Needle> in the substring. If neither first or last is specified, then the first offset is found. If <Needle> does not occur in the given substring of <Target>, then the output is 0.",
			"tags":["Strings"]
		},{
			"id":"464",
			"name":"firstcodeunitof",
			"display name":"FirstCodeunitOf",
			"type":"operator",
			"syntax":[
				"the first codeunit of <Target>"
			],
			"display syntax":[
				"the first codeunit of <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Designates the first codeunit in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"codeunit\" into tVar\n\nvariable tFirst as String\nput the last codeunit of tVar into tFirst -- tFirst contains \"c\""
			}],
			"description":"Either locates the first codeunit for use as the target container of another operation, or evaluates the first codeunit as the source of another operation.\n\n>*Note:* It is an error if <Target> is empty."
		},{
			"id":"465",
			"name":"lastcodeunitof",
			"display name":"LastCodeunitOf",
			"type":"operator",
			"syntax":[
				"the last codeunit of <Target>"
			],
			"display syntax":[
				"the last codeunit of <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Designates the last codeunit in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"codeunit\" into tVar\n\nvariable tLast as String\nput the last codeunit of tVar into tLast -- tLast contains \"r\""
			}],
			"description":"Either locates the last codeunit for use as the target container of another operation, or evaluates the last codeunit as the source of another operation.\n\n>*Note:* It is an error if <Target> is empty.",
			"tags":["Strings"]
		},{
			"id":"466",
			"name":"deletefirstcodeunitof",
			"display name":"DeleteFirstCodeunitOf",
			"type":"statement",
			"syntax":[
				"delete the first codeunit of <Target>"
			],
			"display syntax":[
				"delete the first codeunit of <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Deletes the first codeunit in <Target>.",
			"parameters":[{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A string container."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"seven\" into tVar\ndelete the first codeunit of tVar -- tVar contains \"even\""
			}],
			"description":"Replaces the first codeunit in <Target> with the empty string.\n\n>*Note:* It is an error if <Target> is the empty string.",
			"tags":["Strings"]
		},{
			"id":"467",
			"name":"codeunitoffsetbefore",
			"display name":"CodeunitOffsetBefore",
			"type":"operator",
			"syntax":[
				"the ( first | last ) offset of codeunits <Needle> before <Before> in <Target>"
			],
			"display syntax":[
				"the ( first | last ) offset of codeunits <i>Needle</i> before <i>Before</i> in <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Finds the first or last occurrence of <Needle> before a specified index in <Target>.",
			"parameters":[{
				"name":"Needle",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			},{
				"name":"Before",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of Target."
			}],
			"examples":[{
				"script":"variable tVar as Number\nvariable tLastDot as Number\nvariable tAddress as String\nvariable tTLD as String\nput \"http://www.livecode.com/index.html\" into tAddress\nput the last offset of \".\" in tAddress into tLastDot\nput the offset of \".\" before tLastDot in tAddress into tVar\nput codeunit tVar + 1 to tVar + 3 of tAddress into tTLD -- tTLD contains \"com\""
			}],
			"value":[{
				"name":"return",
				"type":"",
				"description":"Returns the offset of <Needle> before <Before> in <Target>."
			}],
			"description":"The first (respectively last) offset of <Needle> in <Target> is number of codeunits between the first codeunit of <Target>, and the first (respectively last) occurrence of <Needle> in the substring of <Target> ending at codeunit <Before> - 1. If neither first or last is specified, then the last offset is found. If <Needle> does not occur in the given substring of <Target>, then the output is 0.",
			"tags":["Strings"]
		},{
			"id":"468",
			"name":"rangecodeunitof",
			"display name":"RangeCodeunitOf",
			"type":"operator",
			"syntax":[
				"codeunit <Start> to <Finish> of <Target>"
			],
			"display syntax":[
				"codeunit <i>Start</i> to <i>Finish</i> of <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Designates the codeunits between indices <Start> and <Finish> in <Target>.",
			"parameters":[{
				"name":"Start",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Finish",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a string."
			}],
			"examples":[{
				"script":"put tCodeunits into codeunit 5 to 10 of tString // Locates codeunits 5 to 10 of tString and replace them with tCodeunits"
			},{
				"script":"get codeunit 5 to 10 of tString // Evaluates codeunits 5 to 10"
			}],
			"description":"Either locates the codeunits between the given indices for use as the target container of another operation, or evaluates the codeunits at the given indices as the source of another operation.\n\n>*Note:* It is an error if either <Start> or <Finish> are out of range.",
			"tags":["Strings"]
		},{
			"id":"469",
			"name":"deleterangecodeunitof",
			"display name":"DeleteRangeCodeunitOf",
			"type":"statement",
			"syntax":[
				"delete codeunit <Start> to <Finish> of <Target>"
			],
			"display syntax":[
				"delete codeunit <i>Start</i> to <i>Finish</i> of <i>Target</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Deletes the codeunits between indices <Start> and <Finish> in <Target>.",
			"parameters":[{
				"name":"Start",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Finish",
				"type":"",
				"refparam":"false",
				"description":"An expression which evaluates to a valid integer index of <Target>."
			},{
				"name":"Target",
				"type":"",
				"refparam":"false",
				"description":"A string container."
			}],
			"examples":[{
				"script":"variable tVar as String\nput \"surround\" into tVar\ndelete codeunit 2 to 4 of tVar -- tVar contains \"sound\""
			}],
			"description":"Replaces the codeunits between the given indices with the empty string.\n\n>*Note:* It is an error if either <Start> or <Finish> are out of range.",
			"tags":["Strings"]
		},{
			"id":"470",
			"name":"repeatforeachcodeunit",
			"display name":"RepeatForEachCodeunit",
			"type":"iterator",
			"syntax":[
				"codeunit <Iterand>"
			],
			"display syntax":[
				"codeunit <i>Iterand</i>"
			],
			"associations":["com.livecode.codeunit"],
			"summary":"Repeat over the codeunits of a string",
			"parameters":[{
				"name":"Iterand",
				"type":"",
				"refparam":"false",
				"description":"A string container."
			}],
			"examples":[{
				"script":"variable tString as String\nput \"stressed\" into tString\n\nvariable tReversed as String\nvariable tCodeunit as String\nput \"\" into tReversed\nrepeat for each codeunit tCodeunit in tString\n\tput tCodeunit before tReversed\nend repeat\n\n    // tReversed is \"desserts\""
			}],
			"description":"Use repeat for each to perform an operation on each codeunit of a string. On each iteration, the <Iterand> will contain the next codeunit of the string being iterated over.",
			"tags":["Strings","Control structures"]
		},{
			"id":"471",
			"name":"sendtoscriptobject",
			"display name":"SendToScriptObject",
			"type":"statement",
			"syntax":[
				"send ( function | command ) <Message> to <Object> [ with <Arguments> ]"
			],
			"display syntax":[
				"send ( function | command ) <i>Message</i> to <i>Object</i> [ with <i>Arguments</i> ]"
			],
			"associations":["com.livecode.engine"],
			"summary":"Send a message to a script object.",
			"parameters":[{
				"name":"Message",
				"type":"",
				"refparam":"false",
				"description":"The message to dispatch."
			},{
				"name":"Object",
				"type":"",
				"refparam":"false",
				"description":"The script object to dispatch the message to."
			},{
				"name":"Arguments",
				"type":"",
				"refparam":"false",
				"description":"A list of arguments for the message."
			}],
			"examples":[{
				"script":"public handler OnMouseUp() returns nothing\n\t// Send a message to the script so it can handle it.\n\tsend \"buttonClicked\" to my script object\nend handler"
			},{
				"script":"// myScriptFunction takes three arguments and performs some kind of calculation\n\nvariable tObject as ScriptObject\nresolve script object \"this stack\"\nput the result into tObject\nsend function \"myScriptFunction\" to tObject with [ 2, 3, 4 ]\n\n// the result contains the return value of 'myScriptFunction'"
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"The result of the message dispatch"
			}],
			"description":"Sends a message to the given script object and waits for it to finish so that it\ncan return a value.\n\nAfter a send, 'the message was handled' predicate can be used to determine if the\nmessage passed through the message path untouched.\n\n>*Note:* An error is thrown if this syntax is used in a context where access\nto script objects is not allowed.",
			"tags":["Engine"]
		},{
			"id":"472",
			"name":"scriptobject",
			"display name":"ScriptObject",
			"type":"type",
			"syntax":[
				"ScriptObject"
			],
			"display syntax":[
				"ScriptObject"
			],
			"associations":["com.livecode.engine"],
			"summary":"An opaque type corresponding to a LiveCode script object.",
			"description":"Use the <ResolveScriptObject|resolve script object>, or <MyScriptObject|my script object> to obtain an object of type <ScriptObject>",
			"references":{
				"statement":["ResolveScriptObject"],
				"expression":["MyScriptObject"]
			},
			"tags":["Engine"]
		},{
			"id":"473",
			"name":"childrenofscriptobject",
			"display name":"ChildrenOfScriptObject",
			"type":"operator",
			"syntax":[
				"the children of <Object>"
			],
			"display syntax":[
				"the children of <i>Object</i>"
			],
			"associations":["com.livecode.engine"],
			"summary":"Get the child objects of a script object.",
			"parameters":[{
				"name":"Object",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a <ScriptObject>"
			}],
			"examples":[{
				"script":"public handler GetSiblings(in pObject as ScriptObject) returns List\n\t// Return the sibling objects of an object\n\treturn the children of the owner of pObject\nend handler"
			},{
				"script":"// Unset the highlight of all the controls in a group\nresolve script object \"group \\qcheckboxes\\q of this card\"\nvariable tObject\nrepeat for each element tObject in the children of the result\n\tset property \"hilite\" of tObject to false\nend repeat"
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"A list of <ScriptObject>s that are contained within <Object>."
			}],
			"description":"Use to get the script objects contained within a script object.\n\n>*Note:* An error is thrown if the script object does not exist.",
			"tags":["Engine"]
		},{
			"id":"474",
			"name":"propertyofscriptobject",
			"display name":"PropertyOfScriptObject",
			"type":"operator",
			"syntax":[
				"property <Property> of <Object>"
			],
			"display syntax":[
				"property <i>Property</i> of <i>Object</i>"
			],
			"associations":["com.livecode.engine"],
			"summary":"The property of a script object.",
			"parameters":[{
				"name":"Property",
				"type":"",
				"refparam":"false",
				"description":"The name of the property to manipulate"
			},{
				"name":"Object",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a <ScriptObject>."
			}],
			"examples":[{
				"script":"public handler OnMouseUp() returns nothing\n\tset property \"name\" of my script object to \"Clicked Widget\"\nend handler"
			},{
				"script":"resolve script object \"this stack\"\nset property \"invisible\" of the result to true\n    get property \"script\" of my script object"
			}],
			"description":"Use to manipulate properties of a script object.\n\n>*Note:* An error is thrown if the script object does not exist.\n\n>*Note:* An error is thrown if this syntax is used in a context where access\nto script objects is not allowed.",
			"tags":["Engine"]
		},{
			"id":"475",
			"name":"posttoscriptobject",
			"display name":"PostToScriptObject",
			"type":"statement",
			"syntax":[
				"post <Message> to <Object> [ with <Arguments> ]"
			],
			"display syntax":[
				"post <i>Message</i> to <i>Object</i> [ with <i>Arguments</i> ]"
			],
			"associations":["com.livecode.engine"],
			"summary":"Post a message to a script object.",
			"parameters":[{
				"name":"Message",
				"type":"",
				"refparam":"false",
				"description":"The message to dispatch."
			},{
				"name":"Object",
				"type":"",
				"refparam":"false",
				"description":"The script object to dispatch the message to."
			},{
				"name":"Arguments",
				"type":"",
				"refparam":"false",
				"description":"A list of arguments for the message."
			}],
			"examples":[{
				"script":"public handler OnMouseUp() returns nothing\n\t// Send a message to the script so it can handle it.\n\tpost \"buttonClicked\" to my script object\nend handler"
			}],
			"description":"Post a message to the given script object and returns immediately. Posting a message\nwill cause the message to be sent at the next wait point (usually when the current\nevent has finished being handled).",
			"tags":["Engine"]
		},{
			"id":"476",
			"name":"scriptobjectexists",
			"display name":"ScriptObjectExists",
			"type":"operator",
			"syntax":[
				"<Object> exists"
			],
			"display syntax":[
				"<i>Object</i> exists"
			],
			"associations":["com.livecode.engine"],
			"summary":"Tests the existence of a script object.",
			"parameters":[{
				"name":"Object",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a <ScriptObject>."
			}],
			"examples":[{
				"script":"variable tObject as ScriptObject\nresolve script object \"card 5 of this stack\"\nput the result into tObject\nif tObject exists then\n\tset property \"name\" of tObject to \"Card5\"\nelse\n\tlog \"No such card\"\nend if\t"
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"True if the object <Object> exists, and false otherwise."
			}],
			"description":"Use to test the existence or otherwise of a script object, for example after attempting to resolve the object from a string using <ResolveScriptObject | resolve script object>",
			"references":{
				"statement":["ResolveScriptObject"]
			},
			"tags":["Engine"]
		},{
			"id":"477",
			"name":"ownerofscriptobject",
			"display name":"OwnerOfScriptObject",
			"type":"operator",
			"syntax":[
				"the owner of <Object>"
			],
			"display syntax":[
				"the owner of <i>Object</i>"
			],
			"associations":["com.livecode.engine"],
			"summary":"Get the parent object of a script object.",
			"parameters":[{
				"name":"Object",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a <ScriptObject>."
			}],
			"examples":[{
				"script":"public handler MyName() returns String\n\tget property \"short name\" of my script object\n\treturn the result\nend handler\n\npublic handler OnMouseUp() returns nothing\n\t// Send a message to the widget's parent so it can handle the click\n\tdispatch \"widgetClicked\" to the owner of my script object with [ MyName() ]\nend handler"
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"The <ScriptObject> that is the owner of <Object>."
			}],
			"description":"Use to get the script object that contains a script object.\n\n>*Note:* An error is thrown if the script object does not exist.",
			"tags":["Engine"]
		},{
			"id":"478",
			"name":"com.livecode.engine",
			"display name":"com.livecode.engine",
			"type":"library",
			"display syntax":[
				"com.livecode.engine"
			],
			"description":"This library provides operations for interacting with LiveCode Script from LiveCode Builder."
		},{
			"id":"479",
			"name":"scriptobjectdoesnotexist",
			"display name":"ScriptObjectDoesNotExist",
			"type":"operator",
			"syntax":[
				"<Object> does not exist"
			],
			"display syntax":[
				"<i>Object</i> does not exist"
			],
			"associations":["com.livecode.engine"],
			"summary":"Tests the existence of a script object.",
			"parameters":[{
				"name":"Object",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a <ScriptObject>."
			}],
			"examples":[{
				"script":"variable tObject as ScriptObject\nresolve script object \"card 5 of this stack\"\nput the result into tObject\nif tObject does not exist then\n\tlog \"No such card\"\nend if\t"
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"True if the object <Object> exists, and false otherwise."
			}],
			"description":"Use to test the non-existence or otherwise of a script object, for example after attempting to resolve the object from a string using <ResolveScriptObject|resolve script object>",
			"references":{
				"statement":["ResolveScriptObject"]
			},
			"tags":["Engine"]
		},{
			"id":"480",
			"name":"messagewashandled",
			"display name":"MessageWasHandled",
			"type":"expression",
			"syntax":[
				"the message was handled"
			],
			"display syntax":[
				"the message was handled"
			],
			"associations":["com.livecode.engine"],
			"summary":"Determines whether a message was handled",
			"examples":[{
				"script":"public handler OnMouseUp() returns nothing\n\tdispatch \"buttonClicked\" to my script object\n\tif the message was handled then\n\t\treturn\n\tend if\t\n\tlog \"The message was not handled\"\nend handler"
			}],
			"description":"Determines if a dispatched message was handled by any script objects in the message path.",
			"tags":["Engine"]
		},{
			"id":"481",
			"name":"executescript",
			"display name":"ExecuteScript",
			"type":"statement",
			"syntax":[
				"execute script <Script>"
			],
			"display syntax":[
				"execute script <i>Script</i>"
			],
			"associations":["com.livecode.engine"],
			"summary":"Executes some LiveCode script.",
			"parameters":[{
				"name":"Script",
				"type":"",
				"refparam":"false",
				"description":"The script to execute."
			}],
			"examples":[{
				"script":"public handler SnapshotMe() returns nothing\n\tvariable tVar as String\n\tget property \"number\" of my script object\n\tput the result formatted as string into tVar\n\n\t// Create a snapshot from the rect of the widget\n\texecute script \"import snapshot from rect (the rect of widget \" & tVar & \") of widget \" & tVar\nend handler"
			}],
			"description":"Executes the given piece of LiveCode script in the context of the current script\nobject.\n>*Note:* An error is thrown if this syntax is used in a context where access\nto script objects is not allowed.",
			"tags":["Engine"]
		},{
			"id":"482",
			"name":"log",
			"display name":"Log",
			"type":"statement",
			"syntax":[
				"log <Message> [ with <Arguments> ]"
			],
			"display syntax":[
				"log <i>Message</i> [ with <i>Arguments</i> ]"
			],
			"associations":["com.livecode.engine"],
			"summary":"Logs a string.\nString:The string to log.",
			"parameters":[{
				"name":"Arguments",
				"type":"",
				"refparam":"false",
				"description":"A list of arguments."
			}],
			"examples":[{
				"script":"variable tList as List\nget property \"name\" of my script object\npush the result onto tList\n\nget property \"id\" of my script object\npush the result onto tList\n\nlog \"Widget %@ has id %@\" with tList"
			}],
			"description":"The log command triggers a logChanged message with the accumulated log messages since the logChanged message was last handled.\nThis can be handled in LiveCode Script, for example:\n```\non logChanged pLog\n\twrite pLog to stdout\nend logChanged\n```",
			"tags":["Engine"]
		},{
			"id":"483",
			"name":"messagewasnothandled",
			"display name":"MessageWasNotHandled",
			"type":"expression",
			"syntax":[
				"the message was not handled"
			],
			"display syntax":[
				"the message was not handled"
			],
			"associations":["com.livecode.engine"],
			"summary":"Determines whether a message was handled",
			"examples":[{
				"script":"public handler OnMouseUp() returns nothing\n\tdispatch \"buttonClicked\" to my script object\n\tif the message was not handled then\n\t\tlog \"The message was not handled\"\n\tend if\t\nend handler"
			}],
			"description":"Determines if a dispatched message was handled by any script objects in the message path.",
			"tags":["Engine"]
		},{
			"id":"484",
			"name":"resolvescriptobject",
			"display name":"ResolveScriptObject",
			"type":"statement",
			"syntax":[
				"resolve script object <Object>"
			],
			"display syntax":[
				"resolve script object <i>Object</i>"
			],
			"associations":["com.livecode.engine"],
			"summary":"Resolves a string to a script object.",
			"parameters":[{
				"name":"Object",
				"type":"",
				"refparam":"false",
				"description":"The string describing the script object."
			}],
			"examples":[{
				"script":"variable tObject as ScriptObject\nresolve script object \"button 1 of card 1 of this stack\"\nput the result into tObject\nif tObject exists then\n\tget property \"name\" of tObject\n\tlog the result\nelse\n\tlog \"No such button\"\nend if\t"
			}],
			"value":[{
				"name":"the result",
				"type":"",
				"description":"The resolved script object."
			}],
			"tags":["Engine"]
		},{
			"id":"485",
			"name":"repeatwhile",
			"display name":"RepeatWhile",
			"type":"control structure",
			"syntax":[
				"repeat while <Condition>\n\t<StatementList>\nend repeat"
			],
			"display syntax":[
				"repeat while <i>Condition</i>"
			],
			"associations":["com.livecode.language"],
			"summary":"Executes a list of statements while a condition continues to be true.",
			"parameters":[{
				"name":"Condition",
				"type":"bool",
				"refparam":"false",
				"description":"An expression which evaluates to a boolean."
			},{
				"name":"StatementList",
				"type":"",
				"refparam":"false",
				"description":"A set of statements."
			}],
			"description":"Use the repeat while <Condition> structure to execute a set of statements repeatedly, while the <Condition> continues to evaluate to true."
		},{
			"id":"486",
			"name":"if",
			"display name":"If",
			"type":"control structure",
			"syntax":[
				"if <IfCondition> then \n\t<IfStatementList> \n[else if <ElseCondition> then \n\t<ElseIfStatementList>] \n[else \n\t<ElseStatementList>]\nend if"
			],
			"display syntax":[
				"if <i>IfCondition</i> then "
			],
			"associations":["com.livecode.language"],
			"summary":"Executes a list of statements depending on the value of a condition.",
			"parameters":[{
				"name":"IfCondition",
				"type":"bool",
				"refparam":"false",
				"description":"An expression which evaluates to a boolean."
			},{
				"name":"IfStatementList",
				"type":"",
				"refparam":"false",
				"description":"A set of statements."
			},{
				"name":"ElseCondition",
				"type":"bool",
				"refparam":"false",
				"description":"An expression which evaluates to a boolean."
			},{
				"name":"ElseIfStatementList",
				"type":"",
				"refparam":"false",
				"description":"A set of statements."
			},{
				"name":"ElseStatementList",
				"type":"",
				"refparam":"false",
				"description":"A set of statements."
			}],
			"description":"Use the if control structure to execute a statement (or list of statements) only under certain circumstances. If <IfCondition> evaluates to true, the statements in <IfStatementList> are executed. For each condition <ElseCondition> such that none of the previous conditions evaluates to true, the condition is evaluated and the corresponding statements in <ElseIfStatementList> are executed. If none of the conditions evaluate to true, the statements in <ElseStatementList> are executed."
		},{
			"id":"487",
			"name":"putinto",
			"display name":"PutInto",
			"type":"statement",
			"syntax":[
				"put <sourceValue> into <targetContainer>"
			],
			"display syntax":[
				"put <i>sourceValue</i> into <i>targetContainer</i>"
			],
			"associations":["com.livecode.language"],
			"summary":"Put a value into a container.",
			"parameters":[{
				"name":"sourceValue",
				"type":"any",
				"refparam":"false",
				"description":"The value to put into the <targetContainer>"
			},{
				"name":"targetContainer",
				"type":"any",
				"refparam":"false",
				"description":"A valid target for <sourceValue>"
			}],
			"description":"Assigns the result of evaluating <sourceValue> to <targetContainer>.\n>*Note:* It is a checked runtime error for the source value's type to not be compatible with the target expression's type."
		},{
			"id":"488",
			"name":"throwerror",
			"display name":"ThrowError",
			"type":"statement",
			"syntax":[
				"throw <errorString>"
			],
			"display syntax":[
				"throw <i>errorString</i>"
			],
			"associations":["com.livecode.language"],
			"summary":"Causes an error to be raised.",
			"parameters":[{
				"name":"errorString",
				"type":"string",
				"refparam":"false",
				"description":"The error to throw."
			}],
			"examples":[{
				"script":"\tvariable tVar as optional number\n\tput \"Z\" parsed as string into tVar\n\tif tVar is not defined then\n\t\tthrow tVar && \"is not a number\n\tend if"
			}],
			"description":"The throw statement causes an error to be raised. This causes execution to terminate, and the error is passed back to environment.\n\nThe Error expression must be an expression that evaluates to a string.\nNote:There is currently no try / catch mechanism in LiveCode Builder, so throwing an error will cause the error to be raised in LiveCode Script in the appropriate context."
		},{
			"id":"489",
			"name":"nextrepeat",
			"display name":"NextRepeat",
			"type":"control structure",
			"syntax":[
				"next repeat"
			],
			"display syntax":[
				"next repeat"
			],
			"associations":["com.livecode.language"],
			"summary":"Begin the next iteration of a repeat loop.",
			"examples":[{
				"script":"\tvariable tList as list\n\tvariable tElement\n\tput [1, 2, 3, \"a\", 4, \"b\", 5] into tList\n\n\tvariable tSum as number\n\tput 0 into tSum\n\trepeat for each element tElement in tList\n\t\tif tElement is not a number then\n\t\t\tnext repeat\n\t\tend if\n\n\t\tadd tElement to tSum\n\tend repeat"
			}],
			"description":"Use <NextRepeat|next repeat> to skip to the next iteration of a repeat loop. This is particularly useful when operations are only to be performed on iterands which satisfy certain criteria."
		},{
			"id":"490",
			"name":"theresult",
			"display name":"TheResult",
			"type":"expression",
			"syntax":[
				"the result"
			],
			"display syntax":[
				"the result"
			],
			"associations":["com.livecode.language"],
			"summary":"The result of the previous statement.",
			"examples":[{
				"script":"\tresolve script object \"this stack\"\n\tget property \"name\" of the result\n\tlog the result"
			},{
				"script":"\tget 20\n\tsubtract 1 from the result\n\tdivide the result by 2\n\tround the result\n\t-- the result is 10"
			}]
		},{
			"id":"491",
			"name":"return",
			"display name":"Return",
			"type":"statement",
			"syntax":[
				"return [<returnValue>]"
			],
			"display syntax":[
				"return [<i>returnValue</i>]"
			],
			"associations":["com.livecode.language"],
			"summary":"Causes execution of the current handler to end, and control return to the caller.",
			"parameters":[{
				"name":"returnValue",
				"type":"any",
				"refparam":"false",
				"description":"The value to return"
			}],
			"description":"Use the return control structure to halt execution of the current handler, to return control to the caller, and optionally to return a value.\nNote:It is a checked runtime error for a value returned from a handler to not match the return type of the handler it is in."
		},{
			"id":"492",
			"name":"exitrepeat",
			"display name":"ExitRepeat",
			"type":"control structure",
			"syntax":[
				"exit repeat"
			],
			"display syntax":[
				"exit repeat"
			],
			"associations":["com.livecode.language"],
			"summary":"Exit a repeat loop.",
			"examples":[{
				"script":"\tpublic handler ListUpToSentinel(in pList as list, in pSentinel as string) as list\n\n\t\tvariable tElement\n\t\tvariable tNewList as list\n\t\tput the empty list into tNewList\n\n\t\trepeat for each element tElement in pList\n\t\t\tif tElement is a string and tElement is pSentinel then\n\t\t\t\texit repeat\n\t\t\tend if\n\t\t\tpush tElement onto tNewList\n\t\tend repeat\n\n\t\treturn tNewList\n\tend handler"
			}],
			"description":"Use <ExitRepeat|exit repeat> to exit a repeat loop, for example when a certain condition is met."
		},{
			"id":"493",
			"name":"get",
			"display name":"Get",
			"type":"statement",
			"syntax":[
				"get <expression>"
			],
			"display syntax":[
				"get <i>expression</i>"
			],
			"associations":["com.livecode.language"],
			"summary":"Evaluate an expression and put it into the result.",
			"parameters":[{
				"name":"expression",
				"type":"",
				"refparam":"false",
				"description":"Any expression."
			}],
			"description":"The get statement evaluates the Value expression and returns it as the result of the statement. The value is subsequently available by using <TheResult|the result> expression.",
			"references":{
				"expression":["TheResult"]
			}
		},{
			"id":"494",
			"name":"repeatforeach",
			"display name":"RepeatForEach",
			"type":"control structure",
			"syntax":[
				"repeat for each <Iterator> in <Container>\n\t<StatementList>\nend repeat"
			],
			"display syntax":[
				"repeat for each <i>Iterator</i> in <i>Container</i>"
			],
			"associations":["com.livecode.language"],
			"summary":"Executes a list of statements until the <Iterator> is exhausted.",
			"parameters":[{
				"name":"Iterator",
				"type":"",
				"refparam":"false",
				"description":"Any iterator expression."
			},{
				"name":"Container",
				"type":"",
				"refparam":"false",
				"description":"The container over which to iterate."
			},{
				"name":"StatementList",
				"type":"",
				"refparam":"false",
				"description":"A set of statements."
			}],
			"examples":[{
				"script":"\tvariable tElement\n\tvariable tNumbers as list\n\tput the empty list into tNumbers\n\n\trepeat for each element tElement in [\"a\", 1, 2, 3, \"b\", \"c\", 4]\n\t\tif tElement is a number then\n\t\t\tpush tElement onto tNumbers\n\t\tend if\n\tend repeat\n\n\t// tNumbers contains [1, 2, 3, 4]"
			}],
			"description":"Use the repeat for each control structure to iterate though the chars of a string, bytes of data, elements of a list or array, or keys of an array.\n>*Note:* The variable which contains the iterand must be declared prior to being used in the repeat loop.",
			"references":{
				"iterator":["RepeatForEachChar","RepeatForEachByte","RepeatForEachKey","RepeatForEachElementInList","RepeatForEachElementInArray"]
			}
		},{
			"id":"495",
			"name":"repeatuntil",
			"display name":"RepeatUntil",
			"type":"control structure",
			"syntax":[
				"repeat until <Condition>\n\t<StatementList>\nend repeat"
			],
			"display syntax":[
				"repeat until <i>Condition</i>"
			],
			"associations":["com.livecode.language"],
			"summary":"Executes a list of statements until a condition becomes true.",
			"parameters":[{
				"name":"Condition",
				"type":"bool",
				"refparam":"false",
				"description":"An expression which evaluates to a boolean."
			},{
				"name":"StatementList",
				"type":"",
				"refparam":"false",
				"description":"A set of statements."
			}],
			"description":"Use the repeat until <Condition> structure to execute a set of statements repeatedly, until the <Condition> evaluates to true."
		},{
			"id":"496",
			"name":"com.livecode.language",
			"display name":"com.livecode.language",
			"type":"",
			"display syntax":[
				"com.livecode.language"
			]
		},{
			"id":"497",
			"name":"repeatforever",
			"display name":"RepeatForever",
			"type":"control structure",
			"syntax":[
				"repeat forever\n\t<StatementList>\nend repeat"
			],
			"display syntax":[
				"repeat forever"
			],
			"associations":["com.livecode.language"],
			"summary":"Executes a list of statements continually.",
			"parameters":[{
				"name":"StatementList",
				"type":"",
				"refparam":"false",
				"description":"A set of statements."
			}],
			"examples":[{
				"script":"\tvariable tCount as number\n\tvariable tList as list\n\tput [ 1, 2, 3, 4, 5, 6, 7, 8, \"A\", 9, 10 ] into tList\n\tput 0 into tCount\n\trepeat forever\n\t\tif tList[tCount] is not a number then\n\t\t\texit repeat\n\t\tend if\n\t\tadd 1 to tCount\n\tend repeat\n\n\t// tCount is 8"
			}],
			"description":"Use the repeat forever structure to execute a set of statements until either an error is thrown, or exit repeat is executed."
		},{
			"id":"498",
			"name":"repeatwith",
			"display name":"RepeatWith",
			"type":"control structure",
			"syntax":[
				"repeat with <Counter> from <Start> ( up | down ) to <Finish> [ by <Step> ]\n\t<StatementList>\nend repeat"
			],
			"display syntax":[
				"repeat with <i>Counter</i> from <i>Start</i> ( up | down ) to <i>Finish</i> [ by <i>Step</i> ]"
			],
			"associations":["com.livecode.language"],
			"summary":"Executes a list of statements",
			"parameters":[{
				"name":"Counter",
				"type":"",
				"refparam":"false",
				"description":"A numeric variable."
			},{
				"name":"Start",
				"type":"number",
				"refparam":"false",
				"description":"The initial value of <Counter>"
			},{
				"name":"Finish",
				"type":"number",
				"refparam":"false",
				"description":"The boundary value of <Counter>"
			},{
				"name":"Step",
				"type":"number",
				"refparam":"false",
				"description":"The value by which to increase or decrease the <Counter>"
			},{
				"name":"StatementList",
				"type":"",
				"refparam":"false",
				"description":"A set of statements."
			}],
			"examples":[{
				"script":"\tpublic handler Factorial(in pOperand as integer) as number\n\t\tif pOperand < 1 then\n\t\t\treturn 0\n\t\tend if\n\n\t\tvariable tTotal as number\n\t\tput 1 into tTotal\n\n\t\tvariable tCounter as integer\n\t\trepeat with tCounter from 1 up to pOperand \n\t\t\tmultiply tTotal by tCounter\n\t\tend repeat\n\n\t\treturn tCounter\n\tend handler"
			}],
			"description":"Use the repeat with <Counter> structure to execute a set of statements until the value of <Counter> reaches or crosses (depending on iteration direction) the value of <Finish>. The counter is increased (or decreased) by <Step> on each iteration of the loop."
		},{
			"id":"499",
			"name":"repeattimes",
			"display name":"RepeatTimes",
			"type":"control structure",
			"syntax":[
				"repeat <Count> times\n\t<StatementList>\nend repeat"
			],
			"display syntax":[
				"repeat <i>Count</i> times"
			],
			"associations":["com.livecode.language"],
			"summary":"Executes a list of statements a given number of times.",
			"parameters":[{
				"name":"Count",
				"type":"integer",
				"refparam":"false",
				"description":"An expression which evaluates to an integer."
			},{
				"name":"StatementList",
				"type":"",
				"refparam":"false",
				"description":"A set of statements."
			}],
			"examples":[{
				"script":"public handler TwoToThePower(in pOperand as integer) as number\n\n\tif pOperand is 0 then\n\t\treturn 1\n\tend if\t\n\n\tvariable tCount as number\n\tput the abs of pOperand into tCount\n\n\tvariable tResult as number\n\tput 1 into tResult\n\trepeat tCount times\n\t\tmultiply tResult by 2\n\tend repeat\n\n\tif pOperand < 0 then \n\t\treturn 1 / tResult\n\tend if\n\n\treturn tResult\nend handler"
			}],
			"description":"Use the repeat <Count> times structure to execute a set of statements a given number of times, when the statements executed do not rely on knowing which iteration the repeat loop is on."
		},{
			"id":"500",
			"name":"setto",
			"display name":"SetTo",
			"type":"statement",
			"syntax":[
				"set <targetContainer> to <sourceValue>"
			],
			"display syntax":[
				"set <i>targetContainer</i> to <i>sourceValue</i>"
			],
			"associations":["com.livecode.language"],
			"summary":"Put a value into a container.",
			"parameters":[{
				"name":"targetContainer",
				"type":"any",
				"refparam":"false",
				"description":"A valid target for <sourceValue>"
			},{
				"name":"sourceValue",
				"type":"any",
				"refparam":"false",
				"description":"The value to put into the <targetContainer>"
			}],
			"description":"Assigns the result of evaluating <sourceValue> to <targetContainer>.\n>*Note:* It is a checked runtime error for the source value's type to not be compatible with the target expression's type."
		},{
			"id":"501",
			"name":"deletedirectory",
			"display name":"DeleteDirectory",
			"type":"statement",
			"syntax":[
				"delete directory <Directory>"
			],
			"display syntax":[
				"delete directory <i>Directory</i>"
			],
			"associations":["com.livecode.file"],
			"summary":"Delete a directory.",
			"parameters":[{
				"name":"Directory",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a filename."
			}],
			"description":"Deletes a directory.  The directory must be empty."
		},{
			"id":"502",
			"name":"com.livecode.file",
			"display name":"com.livecode.file",
			"type":"library",
			"display syntax":[
				"com.livecode.file"
			],
			"description":"This module specifies the syntax definitions and bindings for file i/o operations in modular LiveCode."
		},{
			"id":"503",
			"name":"getdirectoryentries",
			"display name":"GetDirectoryEntries",
			"type":"operator",
			"syntax":[
				"the entries of directory <Directory>"
			],
			"display syntax":[
				"the entries of directory <i>Directory</i>"
			],
			"associations":["com.livecode.file"],
			"summary":"List the contents of a directory.",
			"parameters":[{
				"name":"Directory",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a filename."
			}],
			"description":"Creates a new, empty directory.",
			"tags":["IO","Filesystem"]
		},{
			"id":"504",
			"name":"deletefile",
			"display name":"DeleteFile",
			"type":"statement",
			"syntax":[
				"delete file <File>"
			],
			"display syntax":[
				"delete file <i>File</i>"
			],
			"associations":["com.livecode.file"],
			"summary":"Delete a file from the filesystem.",
			"parameters":[{
				"name":"File",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a filename."
			}],
			"description":"Deletes the specified file.",
			"tags":["IO","Filesystem"]
		},{
			"id":"505",
			"name":"createdirectory",
			"display name":"CreateDirectory",
			"type":"statement",
			"syntax":[
				"create directory <Directory>"
			],
			"display syntax":[
				"create directory <i>Directory</i>"
			],
			"associations":["com.livecode.file"],
			"summary":"Create a named directory.",
			"parameters":[{
				"name":"Directory",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a filename."
			}],
			"description":"Creates a new, empty directory.",
			"tags":["IO","Filesystem"]
		},{
			"id":"506",
			"name":"filecontents",
			"display name":"FileContents",
			"type":"operator",
			"syntax":[
				"the contents of file <File>"
			],
			"display syntax":[
				"the contents of file <i>File</i>"
			],
			"associations":["com.livecode.file"],
			"summary":"The data stored in a file.",
			"parameters":[{
				"name":"File",
				"type":"",
				"refparam":"false",
				"description":"An expression that evaluates to a filename."
			}],
			"description":"The raw data stored in a file.\n\n>*Note:* Setting the contents of a file will replace the file with a\n>newly-created file with the new contents.",
			"tags":["IO","Filesystem"]
		},{
			"id":"507",
			"name":"com.livecode.foreign",
			"display name":"com.livecode.foreign",
			"type":"library",
			"display syntax":[
				"com.livecode.foreign"
			],
			"description":" Copyright (C) 2003-2013 Runtime Revolution Ltd.\n\n This file is part of LiveCode.\n\n LiveCode is free software; you can redistribute it and/or modify it under\n the terms of the GNU General Public License v3 as published by the Free\n Software Foundation.\n\n LiveCode is distributed in the hope that it will be useful, but WITHOUT ANY\n WARRANTY; without even the implied warranty of MERCHANTABILITY or\n FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License\n for more details.\n\n You should have received a copy of the GNU General Public License\n along with LiveCode.  If not see <http://www.gnu.org/licenses/>.  \n"
		}]
	}