#!/usr/bin/env lua

addonData = { ["Version"] = "1.0",
}

require "wowTest"

test.outFileName = "testOut.xml"

-- Figure out how to parse the XML here, until then....
SendMailNameEditBox = CreateFontString("SendMailNameEditBox")

-- require the file to test
package.path = "../src/?.lua;'" .. package.path
require "BadPuppy"

-- addon setup

function test.before()
end
function test.after()
end
function test.test_1()
end

test.run()
