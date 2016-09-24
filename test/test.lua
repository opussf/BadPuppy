#!/usr/bin/env lua

addonData = { ["Version"] = "1.0",
}

require "wowTest"

test.outFileName = "testOut.xml"

-- Figure out how to parse the XML here, until then....
INEED_SplashFrame = { ["Show"] = function() end,
		["AddMessage"] = function(msg) print( "SPLASHFRAME:", (msg or "")) end,
}
INEED_Frame = CreateFrame()
SendMailNameEditBox = CreateFontString("SendMailNameEditBox")
INEEDUIListFrame = CreateFrame()

-- require the file to test
package.path = "../src/?.lua;'" .. package.path
require "BadPuppy"

-- addon setup

function test.before()
	myInventory = { ["7073"] = 52, ["9799"] = 52, ["9999"] = 52, }
	myCurrencies = { ["703"] = 5, }  -- Fictional currency?
	INEED.OnLoad()
end
function test.after()
	INEED_data = {}
	INEED_account = {}
	INEED_currency = {}
	INEED.othersNeed = nil  -- this is for global tracking
end
function test.testParseCmdItemStr_GetsItemInfo()
	assertEquals( "item:9999", INEED.parseCmd( "item:9999 2" ) )
end
function test.testParseCmdItemStr_GetsQuantity()
	assertEquals( "2", select(2, INEED.parseCmd( "item:9999 2" ) ) )
end
function test.testParseCmdItemLink_GetsItemLink()
	assertEquals( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r",
			INEED.parseCmd( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r" ) )
end
function test.testParseCmdEnchantStr_GetsEnchantInfo()
	assertEquals( "enchant:44157", INEED.parseCmd( "enchant:44157 2" ) )
end
function test.testParseCmdEnchantStr_GetsQuantity()
	assertEquals( "2", select(2, INEED.parseCmd( "enchant:44157 2" ) ) )
end
function test.testParseCmdEnchantLink_GetsEnchantLink()
	assertEquals( "|cffffffff|Henchant:44157|h[Engineering: Turbo-Charged Flying Machine]|h|r",
			INEED.parseCmd( "|cffffffff|Henchant:44157|h[Engineering: Turbo-Charged Flying Machine]|h|r" ) )
end
function test.testParseCmdList()
	assertEquals( "list", INEED.parseCmd( "list" ) )
end
function test.testParseCmdAccount()
	assertEquals( "account", INEED.parseCmd( "account" ) )
end
function test.testGetItemIdFromLink_withLink()
	assertEquals( "7073",
			INEED.getItemIdFromLink( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r" ))
end
function test.testGetItemIdFromLink_withItemNum()
	assertEquals( "9999", INEED.getItemIdFromLink( "item:9999" ) )
end
function test.testGetEnchantIdFromLink_withLink()
	assertEquals( "44157",
			INEED.getEnchantIdFromLink( "|cffffffff|Henchant:44157|h[Engineering: Turbo-Charged Flying Machine]|h|r" ) )
end
function test.testGetEnchantIdFromLink_withEnchantNum()
	assertEquals( "44157", INEED.getEnchantIdFromLink( "enchant:44157" ) )
end
function test.testAddItem_ItemStr()
	INEED.addItem( "item:9798" )
	assertEquals( 1, INEED_data["9798"]["testRealm"]["testName"].needed )
end
function test.testAddItem_ItemLink_NeededIsSet()
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 55 )
	assertEquals( 55, INEED_data["7073"]["testRealm"]["testName"].needed )
end
function test.testAddItem_ItemLink_TotalIsSet()
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 55 )
	assertEquals( 52, INEED_data["7073"]["testRealm"]["testName"].total )
end
function test.testAddItem_TimeStampSet()
	INEED.command( "item:9799 55")
	local now = os.time()
	assertEquals( now, INEED_data["9799"]["testRealm"]["testName"].added )
end
function test.testAddItem_SetsUpdated()
	INEED.command( "item:9799 55")
	local now = os.time()
	assertEquals( now, INEED_data["9799"]["testRealm"]["testName"].updated )
end
function test.testAddItem_AlreadyHaveOverTheAmountNeeded()
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 10 )
	assertIsNil( INEED_data["7073"] )
end
function test.testAddItem_SetsFaction()
	INEED.command( "item:74661" )
	assertEquals( "Alliance", INEED_data["74661"]["testRealm"]["testName"].faction )
end
function test.testRemoveItem_UseZero()
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 10 )
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 0 )
	assertIsNil( INEED_data["7073"] )
end
function test.testItemFulfilled_AlreadyHadItem()
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 10 )
	INEED.UNIT_INVENTORY_CHANGED()  -- this should actually clear the item
	assertIsNil( INEED_data["7073"] )
end
function test.testItemFulfilled_ObtainItem_Fulfilled()
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 60 )
	INEED.UNIT_INVENTORY_CHANGED()
	myInventory["7073"] = 60
	INEED.UNIT_INVENTORY_CHANGED()  -- this should actually clear the item
	assertIsNil( INEED_data["7073"] )
end
function test.testItemFulfilled_ObtainItem_NotFulfilled()
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 60 )
	INEED.UNIT_INVENTORY_CHANGED()
	myInventory["7073"] = 59
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 59, INEED_data["7073"]["testRealm"]["testName"].total )
end
function test.testItemUpdated_SetsTimeStamp()
	INEED.command( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r 60" )
	INEED.UNIT_INVENTORY_CHANGED()
	myInventory["7073"] = 59
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( time(), INEED_data["7073"]["testRealm"]["testName"].updated )
end
function test.testCommand_Blank()
	-- These are here basicly to assure that the command does not error
	INEED.command( "" )
end
function test.testCommand_Help()
	-- These are here basicly to assure that the command does not error
	INEED.command( "help" )
end
function test.testCommand_Options()
	-- These are here basicly to assure that the command does not error
	INEED.command( "options" )
end
function test.testAccountInfo_NoParameter_WithNoValue()
	-- These are here basicly to assure that the command does not error
	-- Does not change account info
	INEED.command( "account" )
	assertIsNil( INEED_account.balance )
end
function test.testAccountInfo_NoParameter_WithValue()
	INEED_account.balance = 100000
	INEED.command( "account" )
	assertEquals( 100000, INEED_account.balance )
end
function test.testAccountInfo_SetToZero()
	INEED_account.balance = 100000
	INEED.command( "account 0")
	assertIsNil( INEED_account.balance )
end
function test.testAccountInfo_SetCopperValue()
	INEED.accountInfo( 100000 )  -- sets 10 gold
	assertEquals( 100000, INEED_account.balance )
end
function test.testAccountInfo_SetCopperValue_Reset()
	INEED.accountInfo( 100000 )  -- sets 10 gold
	INEED.accountInfo( 10000 ) -- set to 1 gold
	assertEquals( 10000, INEED_account.balance )
end
function test.testAccountInfo_SetStringValue_Gold()
	INEED.command( "account 20G" )
	assertEquals( 200000, INEED_account.balance )
end
function test.testAccountInfo_SetStringValue_Silver()
	INEED.command( "account 20S" )
	assertEquals( 2000, INEED_account.balance )
end
function test.testAccountInfo_SetStringValue_Copper()
	INEED.command( "account 20C" )
	assertEquals( 20, INEED_account.balance )
end
function test.testAccountInfo_SetStringValue_MixedValues01()
	INEED.command( "account 20G 20C" )
	assertEquals( 200020, INEED_account.balance )
end
function test.testAccountInfo_SetStringValue_MixedValues02()
	INEED.command( "account 20G20C" )
	assertEquals( 200020, INEED_account.balance )
end
function test.testAccountInfo_SetStringValue_MixedValues03()
	INEED.command( "account 20G20C15S" )
	assertEquals( 201520, INEED_account.balance )
end
function test.testAccountInfo_SetStringValue_MixedValues_UnexpectedRage()
	INEED.command( "account 20G20C100S" )
	assertEquals( 210020, INEED_account.balance )
end
function test.testAccountInfo_SetStringValue_MixedValues_inAllLower()
	INEED.command( "account 20g99s43c" )
	assertEquals( 209943, INEED_account.balance )
end
function test.testAccountInfo_AdditiveValue_Copper()
	INEED_account.balance = 10
	INEED.command( "account +20" )
	assertEquals( 30, INEED_account.balance )
end
function test.testAccountInfo_AdditiveString_Copper()
	INEED_account.balance = 10
	INEED.command( "account +20c" )
	assertEquals( 30, INEED_account.balance )
end
function test.testAccountInfo_AdditiveString_Silver()
	INEED_account.balance = 10
	INEED.command( "account +20s" )
	assertEquals( 2010, INEED_account.balance )
end
function test.testAccountInfo_AdditiveString_Gold()
	INEED_account.balance = 10
	INEED.command( "account +20g" )
	assertEquals( 200010, INEED_account.balance )
end
function test.testAccountInfo_AdditiveString_MixedValues01()
	INEED_account.balance = 10
	INEED.command( "account +15s16C20g" )
	assertEquals( 201526, INEED_account.balance )
end
function test.testAccountInfo_SubtractValue_Copper()
	INEED_account.balance = 30
	INEED.command( "account -20" )
	assertEquals( 10, INEED_account.balance )
end
function test.testAccountInfo_SubtractValue_Copper_SubZero()
	INEED_account.balance = 30
	INEED.command( "account -90" )
	assertIsNil( INEED_account.balance )
end
function test.testMerchantShow_NoBalance()
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 100 ) -- the merchant sells these!
	INEED.MERCHANT_SHOW()
end
function test.testMerchantShow_AutoPurchaseDecrementsBalance()
	INEED.accountInfo( 1000000 )  -- sets 100 gold
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 100 ) -- the merchant sells these!
	INEED.MERCHANT_SHOW()
	assertEquals( 760000, INEED_account.balance )
end
function test.testMerchantShow_AutoPurchaseAbidesByAccountBalance_SingleItem()
	-- 7073 is sold at 50s each, we have 52, need 54 (extra 2)
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 54 )
	INEED.accountInfo( 6000 ) -- 60s
	INEED.MERCHANT_SHOW()
	assertEquals( 1000, INEED_account.balance )
end
function test.testMerchantShow_AutoPurchaseAbidesByAccountBalance_TwoItems()
	-- 7073 is sold at 50s each, we have 52, need 54 (purchase 2)
	INEED.addItem( "|cff9d9d9d|Hitem:7073:0:0:0:0:0:0:0:80:0:0|h[Broken Fang]|h|r", 54 )
	-- 6742 is sold at 1g each, we have 0, need 3 (purchase 3)
	INEED.addItem( "item:6742", 3 ) -- merchant also sells, we need 3, we have 0, UnBroken Fang
	-- would need 4g to auto purchase all items
	INEED.accountInfo( 21000 ) -- 2g 10s
	INEED.MERCHANT_SHOW()      -- trigger purchase
	INEED.UNIT_INVENTORY_CHANGED() -- trigger update
	INEED.showList()
	local balance = INEED_account.balance -- 10s
	local haveNum = INEED_data["6742"]["testRealm"]["testName"].total -- 1

	assertEquals( 1000, balance )
	assertEquals( 1, haveNum )
end
function test.testMerchantShow_DoNotPurchaseAltertiveCurrencyItem()
	INEED.addItem( "item:74661 1" )  -- Black Pepper needs Irompaw Token
	INEED.accountInfo( 21000 ) -- 2g 10s
	INEED.MERCHANT_SHOW()      -- trigger purchase
	INEED.UNIT_INVENTORY_CHANGED() -- trigger update

	assertEquals( 1, INEED_data["74661"]["testRealm"]["testName"].needed )
end
function test.testMerchantShow_DoNotPurchaseUnusableItem()
	INEED.addItem( "item:85216 1")
	INEED.accountInfo( 10000 ) -- 1g
	INEED.MERCHANT_SHOW()
	INEED.UNIT_INVENTORY_CHANGED() -- trigger update
	assertEquals( 10000, INEED_account.balance )  -- purchase should have failed
end
function test.testShowFulfillList_ReturnsExpectedValue()
	INEED_data["7073"] = { ["testRealm"]={ ["otherTestName"] = { ['needed'] = 10,['faction']='Alliance'} } }
	INEED_data["7073"]["testRealm"]["otherTestName"].total = 0
	assertEquals( 52, INEED.showFulfillList() )
end
function test.testShowFulfillList_ReturnsNil()
	--print( "fulfillList returns: "..(INEED.showFulfillList() or "NIL") )
	assertIsNil( INEED.showFulfillList() )
end
function test.testShowFulfillList_NoCrossFaction()
	INEED_data["7073"]={["testRealm"]={["otherTestName"]={['needed']=10,['faction']='Horde',['total']=0,}}}
	assertIsNil( INEED.showFulfillList() )
end
function test.testShowFulfillList_filtersSoulboundItems()
	-- Someone else needs an item that is soulbound (or bound on pickup)
	-- ITEM_SOULBOUND="Soulbound"
	-- ITEM_BIND_ON_PICKUP="Binds when picked up"
	-- You need some of that item too.
	-- assert that a soul bound item on the same realm and faction is not listed
	assertIsNil( INEED.showFulfillList() )
end
function test.testShowFulfillList_filersBindOnPickup()
	-- Someone else needs an item that is soulbound (or bound on pickup)
	-- ITEM_SOULBOUND="Soulbound"
	-- ITEM_BIND_ON_PICKUP="Binds when picked up"
	-- You need some of that item too.
	-- assert that a BoP item on the same realm and faction is not listed
	assertIsNil( INEED.showFulfillList() )
end
function test.testRemoveChar_NoName()
	INEED_data["7073"] = { ["testRealm"]={ ["otherTestName"]={ ['needed']=10 } } }
	INEED.command( "remove" )
	assertEquals( 10, INEED_data["7073"]["testRealm"]["otherTestName"].needed )
end
function test.testRemoveChar_OtherRealm()
	INEED_data["7073"] = {
			["testRealm"]={ ["otherTestName"]={ ['needed']=10 } },
			["otherTestRealm"]={ ["otherTestName"]={ ['needed']=10 }, -- del
								 ["otherTestName2"]={ ['needed']=10 } },
	}
	INEED.command( "remove otherTestName-otherTestRealm" )
	assertIsNil( INEED_data["7073"]["otherTestRealm"]["otherTestName"] )
	assertEquals( 10, INEED_data["7073"]["testRealm"]["otherTestName"].needed )
	assertEquals( 10, INEED_data["7073"]["otherTestRealm"]["otherTestName2"].needed )
end
function test.testTradeSkill_Link()
	INEED.command( "|cffffffff|Henchant:44157|h[Engineering: Turbo-Charged Flying Machine]|h|r" )
	assertEquals( 1, INEED_data["34061"]["testRealm"]["testName"].needed ) -- item to make
	--assertIsNil( INEED_data["34061"]["testRealm"]["testName"].needed )
	assertEquals( 8, INEED_data["23786"]["testRealm"]["testName"].needed )
end

function test.testTradeSkill_EnchantId()
	INEED.command( "enchant:44157" )
	assertEquals( 1, INEED_data["34061"]["testRealm"]["testName"].needed ) -- item to make
	--assertIsNil( INEED_data["34061"]["testRealm"]["testName"].needed )
	assertEquals( 8, INEED_data["23786"]["testRealm"]["testName"].needed )
end
-- Tests for currency
function test.testGetCurrencyIdFromLink_withLink()
	assertEquals( "402",
		INEED.getCurrencyIdFromLink( "|cffffffff|Hcurrency:402|h[Ironpaw Token]|h|r" ) )
end
function test.testGetCurrencyIdFromLink_withItemNum()
	assertEquals( "9999", INEED.getCurrencyIdFromLink( "currency:9999" ) )
end
function test.testAddCurrency_CurrencyLink()
	INEED.command( "|cffffffff|Hcurrency:402|h[Ironpaw Token]|h|r" )
	assertEquals( 1, INEED_currency["402"].needed )
end
function test.testAddCurrency_CurrencyLink_WithQuantity()
	INEED.command( "|cffffffff|Hcurrency:402|h[Ironpaw Token]|h|r 10000" )
	assertEquals( 10000, INEED_currency["402"].needed )
end
function test.testAddCurrency_CurrencyString()
	INEED.command( "currency:402" )
	assertEquals( 1, INEED_currency["402"].needed )
end
function test.testAddCurrency_CurrencyString_WithQuantity()
	INEED.command( "currency:402 10000" )
	assertEquals( 10000, INEED_currency["402"].needed )
end
function test.testAddCurrency_setsUpdated()
	INEED.command( "currency:402 10000")
	local now = os.time()
	assertEquals( now, INEED_currency["402"].updated )
end
function test.testAddCurrency_CurrencyLink_UseZero()
	INEED.command( "|cffffffff|Hcurrency:402|h[Ironpaw Token]|h|r 10000" )
	INEED.command( "|cffffffff|Hcurrency:402|h[Ironpaw Token]|h|r 0" )
	assertIsNil( INEED_currency["402"] )
end
function test.testAddCurrency_CurrencyString_UseZero()
	INEED.command( "currency:402 10000" )
	INEED.command( "currency:402 0" )
	assertIsNil( INEED_currency["402"] )
end
function test.testAddCurrency_CurrencyLink_AlreadyHaveAmount()
	myCurrencies = { ["703"] = 5, }  -- Fictional currency?
	INEED.command( "|cffffffff|Hcurrency:703|h[Fictional Currency]|h|r 1" )
	assertIsNil( INEED_currency["703"] )
end
function test.testAddCurrency_OverMaxReducedToMax()
	INEED.command( "|cffffffff|Hcurrency:703|h[Fictional Currency]|h|r 10000" )
	assertEquals( 4000, INEED_currency["703"].needed )
end
function test.testAddCurrency_StoreName()
	INEED.command( "|cffffffff|Hcurrency:703|h[Fictional Currency]|h|r 100" )
	assertEquals( "Fictional Currency", INEED_currency["703"].name )
end
function test.testCurrencyFulfilled_ObtainItem_IsFulfilled()
	INEED.command( "|cffffffff|Hcurrency:703|h[Fictional Currency]|h|r 10" )
	myCurrencies["703"] = 10
	INEED.CURRENCY_DISPLAY_UPDATE()
	assertIsNil( INEED_currency["703"] )
end
function test.testCurrencyFulfilled_ObtainItem_IsNotFulfilled()
	INEED.command( "|cffffffff|Hcurrency:703|h[Fictional Currency]|h|r 20" )
	myCurrencies["703"] = 10
	INEED.CURRENCY_DISPLAY_UPDATE()
	assertEquals( 10, INEED_currency["703"].total )
end
function test.testSendMail_MAIL_CLOSED_setsNil()
	INEED.mailInfo = {}
	INEED.MAIL_CLOSED()
	assertIsNil( INEED.mailInfo )
end
function test.testSendMail_MAIL_SEND_INFO_UPDATE_setsMailTo()
	SendMailNameEditBox:SetText( "test-realm" )
	INEED.MAIL_SEND_INFO_UPDATE()
	assertEquals( "test-realm", INEED.mailInfo.mailTo )
end
function test.testSendMail_MAIL_SEND_INFO_UPDATE_itemSet()
	SendMailNameEditBox:SetText( "test-realm" )

end
-------
-- Tests for doing global goals
-------
function test.testGlobal_filterMyTrackingInfoFromOthersNeed()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" },
						["testName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" } },
		["otherTestRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" }, -- del
							 ["otherTestName2"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" } },
	}
	INEED.makeOthersNeed()
	assertEquals( 10, INEED.othersNeed["7073"]["testRealm"]["Alliance"].needed )
end
function test.testGlobal_newItem_nooneTrackingIt()
	-- this really should not do anything extra.
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertIsNil( INEED_data["7073"] )
end
function test.testGlobal_newItem_oneTrackingIt_sameRealm_sameFaction_setsNeeded()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 10, INEED.othersNeed["7073"]["testRealm"]["Alliance"].needed )
end
function test.testGlobal_newItem_oneTrackingIt_sameRealm_sameFaction_setsTotal()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 1, INEED.othersNeed["7073"]["testRealm"]["Alliance"].total )
end
function test.testGlobal_newItem_oneTrackingIt_sameRealm_diffFaction_setsNeeded()
	-- This is done as a reminder, or if the item is 'account bound' and can be sent across factions
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Horde" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 10, INEED.othersNeed["7073"]["testRealm"]["Horde"].needed )
end
function test.testGlobal_newItem_oneTrackingIt_sameRealm_diffFaction_setsTotal()
	-- This is done as a reminder, or if the item is 'account bound' and can be sent across factions
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=1, ['faction']="Horde" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 1, INEED.othersNeed["7073"]["testRealm"]["Horde"].total )
end
function test.testGlobal_newItem_oneTrackingIt_diffRealm_sameFaction_setsNeeded()
	-- This is done as a reminder, or if the item is 'account bound' and can be sent across realms
	INEED_data["7073"] = {
		["testRealm2"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 10, INEED.othersNeed["7073"]["testRealm2"]["Alliance"].needed )
end
function test.testGlobal_newItem_oneTrackingIt_diffRealm_sameFaction_setsTotal()
	-- This is done as a reminder, or if the item is 'account bound' and can be sent across realms
	INEED_data["7073"] = {
		["testRealm2"]={ ["otherTestName"]={ ['needed']=10, ['total']=2, ['faction']="Alliance" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 2, INEED.othersNeed["7073"]["testRealm2"]["Alliance"].total )
end
function test.testGlobal_newItem_oneTrackingIt_diffRealm_diffFaction_setsNeeded()
	-- This is done as a reminder, or if the item is 'account bound' and can be sent across realms and factions
	INEED_data["7073"] = {
		["testRealm2"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Horde" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 10, INEED.othersNeed["7073"]["testRealm2"]["Horde"].needed )
end
function test.testGlobal_newItem_oneTrackingIt_diffRealm_diffFaction_setsTotal()
	-- This is done as a reminder, or if the item is 'account bound' and can be sent across realms and factions
	INEED_data["7073"] = {
		["testRealm2"]={ ["otherTestName"]={ ['needed']=10, ['total']=1, ['faction']="Horde" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 1, INEED.othersNeed["7073"]["testRealm2"]["Horde"].total )
end
function test.testGlobal_newItem_twoTrackingItSingleFaction_setsNeeded()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" },
						["yetAnotherName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 20, INEED.othersNeed["7073"]["testRealm"]["Alliance"].needed )
end
function test.testGlobal_newItem_twoTrackingItSingleFaction_setsTotal()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" },
						["yetAnotherName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 1, INEED.othersNeed["7073"]["testRealm"]["Alliance"].total )
end
function test.testGlobal_newItem_twoTrackingItTwoFaction_setsNeeded()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" },
						["yetAnotherName"]={ ['needed']=10, ['total']=0, ['faction']="Horde" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 10, INEED.othersNeed["7073"]["testRealm"]["Alliance"].needed )
	assertEquals( 10, INEED.othersNeed["7073"]["testRealm"]["Horde"].needed )
end
function test.testGlobal_newItem_twoTrackingItTwoFaction_setsTotal()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" },
						["yetAnotherName"]={ ['needed']=10, ['total']=2, ['faction']="Horde" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 1, INEED.othersNeed["7073"]["testRealm"]["Alliance"].total )
	assertEquals( 2, INEED.othersNeed["7073"]["testRealm"]["Horde"].total )
end
function test.testGlobal_newItem_manyTrackingItSingleFaction_setsNeeded()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" },
						["yetAnotherName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" },
						["third"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" }, }
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 30, INEED.othersNeed["7073"]["testRealm"]["Alliance"].needed )
end
function test.testGlobal_newItem_manyTrackingItSingleFaction_setsTotal()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" },
						["yetAnotherName"]={ ['needed']=10, ['total']=2, ['faction']="Alliance" },
						["third"]={ ['needed']=10, ['total']=4, ['faction']="Alliance" }, }
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 7, INEED.othersNeed["7073"]["testRealm"]["Alliance"].total )
end
function test.testGlobal_newItem_IAndOthersTracking()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" },
						["testName"]={ ['needed']=10, ['total']=2, ['faction']="Alliance" } },
		["otherTestRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=4, ['faction']="Alliance" }, -- del
							 ["otherTestName2"]={ ['needed']=10, ['total']=8, ['faction']="Alliance" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 1, INEED.othersNeed['7073']['testRealm']['Alliance'].total )
	assertEquals( 12, INEED.othersNeed['7073']['otherTestRealm']['Alliance'].total )

end
function test.testGlobal_newItem_setsMine()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" },
						["testName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" } },
		["otherTestRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" }, -- del
							 ["otherTestName2"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 52, INEED.othersNeed["7073"]["testRealm"]["Alliance"].mine )
end
function test.testGlobal_previousItem_manyTrackingItSingleFaction_setsTotal()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" },
						["yetAnotherName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" },
						["third"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" }, }
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 3, INEED.othersNeed["7073"]["testRealm"]["Alliance"].total )
end
function test.testGlobal_previousItem_manyTrackingItSingleFaction_setsTotal_withInMail()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance", ['inMail']=1 },
						["yetAnotherName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" },
						["third"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" }, }
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 4, INEED.othersNeed["7073"]["testRealm"]["Alliance"].total )
end
function test.testGlobal_missingFactionInData()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance", ['inMail']=1 },
						["yetAnotherName"]={ ['needed']=10, ['total']=1, ['faction']="Alliance" },
						["third"]={ ['needed']=10, ['total']=1 }, }
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertEquals( 3, INEED.othersNeed["7073"]["testRealm"]["Alliance"].total )
end
function test.testGlobal_dontTrackInGlobalWhatINeed()
	INEED_data["7073"] = {
		["testRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" },
						["testName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" } },
		["otherTestRealm"]={ ["otherTestName"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" }, -- del
							 ["otherTestName2"]={ ['needed']=10, ['total']=0, ['faction']="Alliance" } },
	}
	INEED.makeOthersNeed()
	myInventory["7073"] = 1
	INEED.UNIT_INVENTORY_CHANGED()
	assertIsNil( INEED.othersNeed["7073"]["testRealm"]["testName"] )
end
function test.testAddSpecialCurrency_CurrencyNotCurrentlyNeeded()
	-- If a needed item can be purchased, but needs special currency, auto add the currency if not already needed
	INEED.addItem( "item:74661 1" )  -- Black Pepper needs Irompaw Token (currency:402 x 1)
	INEED.accountInfo( 21000 ) -- 2g 10s
	INEED.MERCHANT_SHOW()      -- trigger purchase
	INEED.UNIT_INVENTORY_CHANGED() -- trigger update

	assertEquals( 1, INEED_currency["402"].needed )
end
function test.testAddSpecialCurrency_CurrencyCurrentlyNeeded()
	-- If a needed item can be purchased, but needs special currency, Not 100% what I want it to do here.
	INEED.command( "currency:402 8" )
	INEED.addItem( "item:74661 1" )  -- Black Pepper needs Irompaw Token (currency:402 x 1)
	INEED.accountInfo( 21000 ) -- 2g 10s
	INEED.MERCHANT_SHOW()      -- trigger purchase
	INEED.UNIT_INVENTORY_CHANGED() -- trigger update

	assertEquals( 8, INEED_currency["402"].needed )
end
function test.testAddSpecialCurrencyItem_CurrencyItemNotCurrentlyNeeded()
	-- If a needed item can be purchased, but needs special currency, auto add the currency if not already needed
	INEED.addItem( "item:49927 1" )  -- Love Token is purchased with Lovely Charm Bracelet
	INEED.accountInfo( 21000 ) -- 2g 10s
	INEED.MERCHANT_SHOW()      -- trigger purchase
	INEED.UNIT_INVENTORY_CHANGED() -- trigger update

	assertEquals( 1, INEED_data["49927"]["testRealm"]["testName"].needed )
end
function test.testAddSpecialCurrencyItem_CurrencyItemCurrentlyNeeded()
	-- If a needed item can be purchased, but needs special currency, Not 100% what I want it to do here.
	INEED.command( "item:49916 8" )
	INEED.addItem( "item:49927 1" )  -- Love Token is purchased with Lovely Charm Bracelet
	INEED.accountInfo( 21000 ) -- 2g 10s
	INEED.MERCHANT_SHOW()      -- trigger purchase
	INEED.UNIT_INVENTORY_CHANGED() -- trigger update

	assertEquals( 8, INEED_data["49916"]["testRealm"]["testName"].needed )
end
function test.testAddSpecialCurrency_AlreadyHaveMoreThanNeeded()
	-- Needing an item that can be purchased with a special currency (not gold)
	-- Already have more than what is needed
	myCurrencies = { ["402"] = 5, }
	INEED.addItem( "item:74661 1" )  -- Black Pepper needs Irompaw Token (currency:402 x 1)
	INEED.accountInfo( 21000 ) -- 2g 10s
	INEED.MERCHANT_SHOW()      -- trigger purchase
	INEED.UNIT_INVENTORY_CHANGED() -- trigger update

	assertIsNil( INEED_currency["402"] )
end
function test.testAddSpecialCurrencyItem_AlreadyHaveMoreThanNeeded()
	myInventory["49916"] = 10
	INEED.addItem( "item:49927 1" )  -- Love Token is purchased with Lovely Charm Bracelet
	INEED.accountInfo( 21000 ) -- 2g 10s
	INEED.MERCHANT_SHOW()      -- trigger purchase
	INEED.UNIT_INVENTORY_CHANGED() -- trigger update

	assertIsNil( INEED_data["49916"] )
	myInventory["49916"] = nil
end

function test.testAddSpecialCurrencyItem_CurrencyItemCurrentlyNeeded_HaveMoreThanNeeded()
	-- The needed item costs a special currency (>1)
end

--------------
-- UI Tests --
--------------
--[[
function test.testUI_INEEDBars_ReturnsNumberOfBars_EmptyBarTable_ReturnValue()
	-- Test the function that assures bars are created.
	INEED.UIList_bars = {}
	assertEquals( 1, INEED.UIListAssureBars( INEEDUIListFrame, 1 ) )
end
function test.testUI_INEEDBars_ReturnsNumberOfBars_HasBarsAlready_ReturnValue()
	-- Frame has the number of bars already
	INEED.UIList_bars = {}  -- figure out what this should look like (to have 2 bars already)
	assertEquals( 2, INEED.UIListAssureBars( INEEDUIListFrame, 1 ) )
end
function test.testUI_INEEDBars_CreatesBars()
end
]]




test.run()
