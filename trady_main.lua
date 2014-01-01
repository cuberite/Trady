-- Global variables
PLUGIN = {}	-- Reference to own plugin object
HANDY = {}	-- here, HANDY candy!
COINY = {}		-- stay COINY, maaaaaan!
CHEST_WIDTH = 9
eSaveMode_Paranoid = -1
eSaveMode_Timed = 0
eSaveMode_Relaxed = 1
eSaveMode_Dont = 100500
-- LOGICS
ShopsData = {}
TradersData = {}
SaveTicksCounter = 0
-- SETTINGS
SaveMode = eSaveMode_Timed
SaveEveryNthTick = 2000
FRACTIONAL_TRADE = true
BARTER = false
BarterItem = E_ITEM_GOLD_NUGGET
HALT_SELF_TRADE = false
USING_NON_OWNER_PROTECTION = true
BREAKING_NON_OWNER_PROTECTION = true
-- MESSAGES
MESSAGES = {}
MESSAGES.success = "Success!"
MESSAGES.partial_transfer = "Operation wasn't performed completely, but we did our best to please you!"

MESSAGES.aborted_partial_transfer = "Fractional operations are disallowed server-wise"
MESSAGES.banned_partial_transfer = "Fractional operations are disallowed by merchant"

MESSAGES.player_no_money = "You can't afford it"
MESSAGES.player_no_space = "You don't have SPAAAAAACE!"
MESSAGES.no_items_in_shop = "Out of stock"
MESSAGES.no_items_in_player = "You don't have any to sell"
MESSAGES.not_enough_items = "Sorry, not enough stuff"
MESSAGES.not_enough_space = "Not enough space in shop"

MESSAGES.merchant_no_money = "Merchant can't afford it"
MESSAGES.merchant_no_space = "Merchant can't take your coins :("
MESSAGES.to_merchant_no_money = "Your shop needs MONEY (in order to buy things from strangers)"
MESSAGES.to_merchant_no_space = "Hey, you, free your cash machine a bit, uh? Someone can't shut you up and give his money!"
MESSAGES.to_merchant_not_enough_space = "Pssst, buddy! One of your shops is overloaded. Take care of it"


FAIL_REASON = {}
FAIL_REASON.aborted_partial_transfer = 0	-- aborted due to server-wise setting
FAIL_REASON.banned_partial_transfer = 1		-- means it was banned by merchant
FAIL_REASON.merchant_no_money = 2			-- overloaded cash machine
FAIL_REASON.merchant_no_space = 3			-- overloaded cash machine
FAIL_REASON.player_no_money = 4
FAIL_REASON.player_no_space = 5
FAIL_REASON.no_items_in_shop = 6
FAIL_REASON.no_items_in_player = 7
FAIL_REASON.not_enough_items = 8
FAIL_REASON.not_enough_space = 9

OPERATION_STATE = {}
OPERATION_STATE.performed = false
OPERATION_STATE.success = true
OPERATION_STATE.fail_reason = FAIL_REASON.player_no_money
OPERATION_STATE.partial = false
OPERATION_STATE.ammount = 0
OPERATION_STATE.money_ammount = 0
OPERATION_STATE.itemID = 0
OPERATION_STATE.merchantname = ""
--[[
TODO:
- too much to write, lol
- actually, not:
0. Save/load CHECK if shop/cashmachine was broken!
1. DELETE shop/cashmachine if owner breaks a sign or chest!
2. FIX: no chest, correct sign, reports "fill the chest"
3. WEB panel to set shit up
]]
function Initialize( Plugin )
	PLUGIN = Plugin
	PLUGIN:SetName( "Trady" )
	PLUGIN:SetVersion( 1 )
	
	PluginManager = cRoot:Get():GetPluginManager()
	cPluginManager.AddHook( cPluginManager.HOOK_PLAYER_LEFT_CLICK, OnPlayerLeftClick )
	cPluginManager.AddHook( cPluginManager.HOOK_PLAYER_RIGHT_CLICK, OnPlayerRightClick )
	cPluginManager.AddHook( cPluginManager.HOOK_PLAYER_BREAKING_BLOCK, OnPlayerBreakingBlock )
	cPluginManager.AddHook( cPluginManager.HOOK_UPDATING_SIGN, OnUpdatingSign )
	cPluginManager.AddHook( cPluginManager.HOOK_TICK, OnTick )
	HANDY = PluginManager:GetPlugin( "Handy" )
	COINY = PluginManager:GetPlugin( "Coiny" )
	
	--Plugin:AddWebTab( "Trady", HandleRequest_ChestShop )
	LoadSettings()
	LoadData()
	LOG( "Initialized "..PLUGIN:GetName().." v"..PLUGIN:GetVersion() )
	return true
end

function OnDisable()
	SaveSettings()
	if( SaveMode ~= eSaveMode_Dont ) then
		SaveData()
	end
	LOG( PLUGIN:GetName().." v"..PLUGIN:GetVersion().." is shutting down..." )
end

function OnTick()
	if( SaveMode == eSaveMode_Timed ) then
		SaveTicksCounter = SaveTicksCounter + 1
		if( SaveTicksCounter == SaveEveryNthTick ) then
			SaveTicksCounter = 0
			SaveData()
		end
	end
end
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
function OnUpdatingSign( IN_world, IN_x, IN_y, IN_z, Line1, Line2, Line3, Line4, IN_player )
	local _ownername = IN_player:GetName()
	LOG( "Trady: updating sign! Lines: "..Line1..", "..Line2..", "..Line3..", "..Line4 )
	if( Line4 == "" ) then
		local _split = LineSplit( Line1, ":" )
		if( #_split == 2 ) then
			local _from_chest_price = tonumber( _split[1] )	-- IN_player buys something from chest
			local _to_chest_price = tonumber( _split[2] )		-- IN_player sells something to chest
			local _ammount_override = -1
			if( Line2 ~= "" ) then	_ammount_override = tonumber( Line2 )	end
			local _fractional_trade = not HANDY:Call( "StringToBool", Line3 )
			
			Line1 = ""
			Line2 = ""
			Line3 = ""
			Line4 = ""
			
			local _check = CheckShopChest( IN_player:GetWorld(), IN_x, IN_y - 1, IN_z )
			if( _check.foundStuff ) then
				if( _check.clashingItems ) then
					IN_player:SendMessage( "Shop wasn't created due to mixed items in chest" )
				else
					if( _ammount_override > 0 ) then _check.count = _ammount_override	end
					Line1 = ItemTypeToString( _check.type )
					Line2 = _check.count.." pieces"
					Line3 = "/\\ ".._split[1].." : ".._split[2].." \\/"
					if( _split[1] == "-" ) then
						_from_chest_price = -1
					end
					if( _split[2] == "-" ) then
						_to_chest_price = -1
					end
					Line4 = IN_player:GetName()
					
					RegisterShop( IN_player:GetWorld(), IN_player:GetName(), IN_x, IN_y, IN_z, _check.type, _check.count, _to_chest_price, _from_chest_price, _fractional_trade )
					LOG( PLUGIN:GetName().." reporting: created a shop at( "..IN_x..":"..IN_y..":"..IN_z.." ) by ".._ownername.." ["..Line1.."]" )
					if( SaveMode == eSaveMode_Paranoid ) then
						SaveData()
					end
				end
			else
				IN_player:SendMessage( "Fill chest with items you want to sell first" )
			end
		end
	end
	-- now we got to check for cash machine!
	if( BARTER == true ) then
		if( Line2 == ""
		and Line3 == ""
		and Line4 == "" ) then
			if( Line1 == "cash" ) then
				Line1 = ""
				Line2 = ""
				Line3 = ""
				Line4 = ""
				
				if( CheckCashMachineChest( IN_player:GetWorld(), IN_x, IN_y - 1, IN_z ) == 1 ) then
					-- OK, there's a chest and we got a sign, let's turn it into motherfucking CASH MACHINE!
					Line1 = "Cash Machine"
					Line3 = "belong to"
					Line4 = _ownername
					RegisterCashMachine( IN_player:GetWorld(), IN_player:GetName(), IN_x, IN_y, IN_z )
					LOG( PLUGIN:GetName().." reporting: created a cash machine at( "..IN_x..":"..IN_y..":"..IN_z.." ) by ".._ownername )
					if( SaveMode == eSaveMode_Paranoid ) then
						SaveData()
					end
				else
					IN_player:SendMessage( "There's no fucking chest, how are you supposed to keep your piles of... whatever?!" )
				end
			end
		end
	end
    --return false, "_l1", "_l2", "_l3", "_l4"
	return false, Line1, Line2, Line3, Line4
	--return true, Line1, Line2, Line3, Line4
end
-- LEFTCLICK!
function OnPlayerLeftClick( IN_player, IN_x, IN_y, IN_z, BlockFace, Status, OldBlock, OldMeta )
	if( IN_x ~= -1 and IN_y ~= 255 and IN_z ~= -1 ) then
		if( BREAKING_NON_OWNER_PROTECTION == true ) then
			if( CheckShopThere( IN_player:GetWorld(), IN_x, IN_y +1, IN_z ) == true ) then	-- we know we're clicking on a chest with shop!
				local _adress = GetAdress( IN_player:GetWorld(), IN_x, IN_y +1, IN_z )
				if( ShopsData[_adress].ownername ~= IN_player:GetName() ) then	--											<<< DOOMSDAY DEVICE
					return true
				end
			end
			local _ownername, _cashmachine = GetCashMachineThere( IN_player:GetWorld(), IN_x, IN_y +1, IN_z )
			if( _cashmachine ~= nil ) then	-- we know we're clicking on a cash machine!
				if( _ownername ~= IN_player:GetName() ) then	--															<<< DOOMSDAY DEVICE
					return true
				end
			end
			_ownername = nil
			_cashmachine = nil
			_ownername, _cashmachine = GetCashMachineThere( IN_player:GetWorld(), IN_x, IN_y, IN_z )
			if( _cashmachine ~= nil ) then
				if( _ownername ~= IN_player:GetName() ) then	--															<<< DOOMSDAY DEVICE
					return true
				end
			end
		end
		
		_items_traded = SellToShop( IN_player:GetWorld(), IN_player, IN_x, IN_y, IN_z )
		if( _items_traded > 0 ) then
			if( OPERATION_STATE.partial == true ) then
				IN_player:SendMessage( MESSAGES.partial_transfer )
			end
			local _itemname = HANDY:Call( "PluralItemName", OPERATION_STATE.itemID, OPERATION_STATE.ammount )
			local _price = OPERATION_STATE.money_ammount
			if( BARTER == false ) then
				_price = _price.." "..HANDY:Call( "PluralString", OPERATION_STATE.money_ammount, " coin", " coins" )
			else
				_price = _price.." "..HANDY:Call( "PluralItemName", BarterItem, OPERATION_STATE.money_ammount )
			end
			IN_player:SendMessage( "Sold "..OPERATION_STATE.ammount.." ".._itemname.." for ".._price..", to "..OPERATION_STATE.merchantname )
			if( SaveMode == eSaveMode_Paranoid ) then
				SaveData()
			end
			return true
		elseif( _items_traded == 0 ) then
			if( OPERATION_STATE.performed == true ) then
				OPERATION_STATE.performed = false
				if( OPERATION_STATE.success == false ) then
					if( OPERATION_STATE.fail_reason 					== FAIL_REASON.merchant_no_money )		then
						IN_player:SendMessage( MESSAGES.merchant_no_money )
						HANDY:Call( "GetPlayerByName", OPERATION_STATE.merchantname ):SendMessage( MESSAGES.to_merchant_no_money )
					elseif( OPERATION_STATE.fail_reason 				== FAIL_REASON.player_no_space )			then
						IN_player:SendMessage( MESSAGES.player_no_space )
					elseif( OPERATION_STATE.fail_reason 				== FAIL_REASON.not_enough_space )		then
						IN_player:SendMessage( MESSAGES.not_enough_space )
						local _merchant_message = MESSAGES.to_merchant_not_enough_space..": "..GetShopDescription( IN_player:GetWorld(), IN_x, IN_y, IN_z )
						HANDY:Call( "GetPlayerByName", OPERATION_STATE.merchantname ):SendMessage( _merchant_message )
					elseif( OPERATION_STATE.fail_reason 				== FAIL_REASON.not_enough_items )		then
						IN_player:SendMessage( MESSAGES.not_enough_items )
					end
				else
					-- means that there were no obstacles other than no items in IN_player at all
					IN_player:SendMessage( MESSAGES.no_items_in_player )
				end
				return true
			end
		end
	end
	return false
end

-- RIGHTCLICK!
function OnPlayerRightClick( IN_player, IN_x, IN_y, IN_z, BlockFace, HeldItem )
	if( IN_x ~= -1 and IN_y ~= 255 and IN_z ~= -1 ) then
		if( USING_NON_OWNER_PROTECTION == true ) then
			if( CheckShopThere( IN_player:GetWorld(), IN_x, IN_y +1, IN_z ) == true ) then	-- we know we're clicking on a chest with shop!
				local _adress = GetAdress( IN_player:GetWorld(), IN_x, IN_y +1, IN_z )
				if( ShopsData[_adress].ownername ~= IN_player:GetName() ) then	--											<<< DOOMSDAY DEVICE
					return true
				end
			end
			local _ownername, _cashmachine = GetCashMachineThere( IN_player:GetWorld(), IN_x, IN_y +1, IN_z )
			if( _cashmachine ~= nil ) then	-- we know we're clicking on a cash machine!
				if( _ownername ~= IN_player:GetName() ) then	--															<<< DOOMSDAY DEVICE
					return true
				end
			end
		end
		
		_items_traded = GetFromShop( IN_player:GetWorld(), IN_player, IN_x, IN_y, IN_z )
		if( _items_traded > 0 ) then
			if( OPERATION_STATE.partial == true ) then
				IN_player:SendMessage( MESSAGES.partial_transfer )
			end
			local _itemname = HANDY:Call( "PluralItemName", OPERATION_STATE.itemID, OPERATION_STATE.ammount )
			local _price = OPERATION_STATE.money_ammount
			if( BARTER == false ) then
				_price = _price.." "..HANDY:Call( "PluralString", OPERATION_STATE.money_ammount, " coin", " coins" )
			else
				_price = _price.." "..HANDY:Call( "PluralItemName", BarterItem, OPERATION_STATE.money_ammount )
			end
			IN_player:SendMessage( "Bought "..OPERATION_STATE.ammount.." ".._itemname.." for ".._price..", from "..OPERATION_STATE.merchantname )
			if( SaveMode == eSaveMode_Paranoid ) then
				SaveData()
			end
			return true
		elseif( _items_traded == 0 ) then
			if( OPERATION_STATE.performed == true ) then
				OPERATION_STATE.performed = false
				if( OPERATION_STATE.success == false ) then
					if( OPERATION_STATE.fail_reason 				== FAIL_REASON.merchant_no_space )			then
						IN_player:SendMessage( MESSAGES.merchant_no_space )
						HANDY:Call( "GetPlayerByName", OPERATION_STATE.merchantname ):SendMessage( MESSAGES.to_merchant_no_space )
					elseif( OPERATION_STATE.fail_reason 				== FAIL_REASON.player_no_money )				then
						IN_player:SendMessage( MESSAGES.player_no_money )
					elseif( OPERATION_STATE.fail_reason 				== FAIL_REASON.player_no_space )				then
						IN_player:SendMessage( MESSAGES.player_no_space )
					elseif( OPERATION_STATE.fail_reason 				== FAIL_REASON.not_enough_items )				then
						IN_player:SendMessage( MESSAGES.not_enough_items )
					end
				else
					-- means that there were no obstacles other than no items in chest at all
					IN_player:SendMessage( MESSAGES.no_items_in_shop )
				end
				return true
			end
		end
	end
	return false
end
-- - - - - -
function OnPlayerBreakingBlock( IN_player, IN_x, IN_y, IN_z, IN_blockface, IN_blocktype, IN_blockmeta )
	-- TODO: implement breaking protection here
end