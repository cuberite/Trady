--[[
TODO:
- too much to write, lol
- actually, not:
3. WEB panel to set shit up
4. Check/revive "barter"
]]

-- Global variables
PLUGIN = {}	-- Reference to own plugin object
HANDY = {}	-- here, HANDY candy!
COINY = {}		-- stay COINY, maaaaaan!
HandyRequiredVersion = 2

-- Logics
ShopsData = {}
TradersData = {}
SaveTicksCounter = 0

-- Save modes
eSaveMode_Paranoid = -1
eSaveMode_Timed = 0
eSaveMode_Relaxed = 1
eSaveMode_Dont = 100500

-- Settings
Settings = {}
Settings.SaveMode = eSaveMode_Paranoid
Settings.SaveEveryNthTick = 2000
Settings.FractionalTrade = true
Settings.Barter = false
Settings.BarterItem = E_ITEM_GOLD_NUGGET
Settings.HaltSelfTrade = false
Settings.UsingProtection = true
Settings.BreakingProtection = true
-- Messages
Messages = {}
Messages.success = "Success!"
Messages.partial_transfer = "Operation wasn't performed completely, but we did our best to please you!"

Messages.aborted_partial_transfer = "Fractional operations are disallowed server-wise"
Messages.banned_partial_transfer = "Fractional operations are disallowed by merchant"

Messages.player_no_money = "You can't afford it"
Messages.player_no_space = "You don't have SPAAAAAACE!"
Messages.no_items_in_shop = "Out of stock"
Messages.no_items_in_player = "You don't have any to sell"
Messages.not_enough_items = "Sorry, not enough stuff"
Messages.not_enough_space = "Not enough space in shop"

Messages.merchant_no_money = "Merchant can't afford it"
Messages.merchant_no_space = "Merchant can't take your coins :("
Messages.to_merchant_no_money = "Your shop needs MONEY (in order to buy things from strangers)"
Messages.to_merchant_no_space = "Hey, you, free your cash machine a bit, uh? Someone can't shut you up and give his money!"
Messages.to_merchant_not_enough_space = "Pssst, buddy! One of your shops is overloaded. Take care of it"


FailReason = {}
FailReason.aborted_partial_transfer = 0	-- aborted due to server-wise setting
FailReason.banned_partial_transfer = 1		-- means it was banned by merchant
FailReason.merchant_no_money = 2			-- overloaded cash machine
FailReason.merchant_no_space = 3			-- overloaded cash machine
FailReason.player_no_money = 4
FailReason.player_no_space = 5
FailReason.no_items_in_shop = 6
FailReason.no_items_in_player = 7
FailReason.not_enough_items = 8
FailReason.not_enough_space = 9

OperationState = {}
OperationState.performed = false
OperationState.success = true
OperationState.fail_reason = FailReason.player_no_money
OperationState.partial = false
OperationState.amount = 0
OperationState.money_amount = 0
OperationState.itemID = 0
OperationState.merchantname = ""

function Initialize( Plugin )
	PLUGIN = Plugin
	PLUGIN:SetName( "Trady" )
	PLUGIN:SetVersion( 2 )
	
	PluginManager = cRoot:Get():GetPluginManager()
	COINY = PluginManager:GetPlugin( "Coiny" )
	HANDY = cRoot:Get():GetPluginManager():GetPlugin( "Handy" )
	local properHandy = HANDY:Call( "CheckForRequiedVersion", HandyRequiredVersion )
	if( not properHandy ) then
		LOGERROR( PLUGIN:GetName().." v"..PLUGIN:GetVersion().." needs Handy v"..HandyRequiredVersion..", shutting down" )
		return false
	end
	
	PluginManager:BindCommand( "/td", "core.help", HandleDebugCommand, "- Trady debug" )
	
	cPluginManager.AddHook( cPluginManager.HOOK_PLAYER_LEFT_CLICK, OnPlayerLeftClick )
	cPluginManager.AddHook( cPluginManager.HOOK_PLAYER_RIGHT_CLICK, OnPlayerRightClick )
	cPluginManager.AddHook( cPluginManager.HOOK_PLAYER_BREAKING_BLOCK, OnPlayerBreakingBlock )
	cPluginManager.AddHook( cPluginManager.HOOK_UPDATING_SIGN, OnUpdatingSign )
	cPluginManager.AddHook( cPluginManager.HOOK_TICK, OnTick )
	
	--Plugin:AddWebTab( "Trady", HandleRequest_ChestShop )
	LoadSettings()
	LoadData()
	LOG( "Initialized "..PLUGIN:GetName().." v"..PLUGIN:GetVersion() )
	return true
end

function OnDisable()
	SaveSettings()
	if( Settings.SaveMode ~= eSaveMode_Dont ) then
		SaveData()
	end
	LOG( PLUGIN:GetName().." v"..PLUGIN:GetVersion().." is shutting down..." )
end

function OnTick()
	if( Settings.SaveMode == eSaveMode_Timed ) then
		SaveTicksCounter = SaveTicksCounter + 1
		if( SaveTicksCounter == Settings.SaveEveryNthTick ) then
			SaveTicksCounter = 0
			SaveData()
		end
	end
end
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
function OnUpdatingSign( inWorld, inX, inY, inZ, Line1, Line2, Line3, Line4, inPlayer )
	local _ownername = inPlayer:GetName()
	if( Line4 == "" ) then
		local _split = LineSplit( Line1, ":" )
		if( #_split == 2 ) then
			local _from_chest_price = tonumber( _split[1] )	-- inPlayer buys something from chest
			local _to_chest_price = tonumber( _split[2] )		-- inPlayer sells something to chest
			local _amount_override = -1
			if( Line2 ~= "" ) then	_amount_override = tonumber( Line2 )	end
			local _fractional_trade = not HANDY:Call( "StringToBool", Line3 )
			
			Line1 = ""
			Line2 = ""
			Line3 = ""
			Line4 = ""
			
			local _check = CheckShopChest( inPlayer:GetWorld(), inX, inY - 1, inZ )
			if( _check.foundStuff ) then
				if( _check.clashingItems ) then
					inPlayer:SendMessage( "Shop wasn't created due to mixed items in chest" )
				else
					if( _amount_override > 0 ) then _check.count = _amount_override	end
					Line1 = ItemTypeToString( _check.type )
					Line2 = _check.count.." pieces"
					Line3 = "/\\ ".._split[1].." : ".._split[2].." \\/"
					if( _split[1] == "-" ) then
						_from_chest_price = -1
					end
					if( _split[2] == "-" ) then
						_to_chest_price = -1
					end
					Line4 = inPlayer:GetName()
					
					RegisterShop( inPlayer:GetWorld(), inPlayer:GetName(), inX, inY, inZ, _check.type, _check.count, _to_chest_price, _from_chest_price, _fractional_trade )
					local countString = HANDY:Call( "PluralString", _check.count, " piece", " pieces" )
					inPlayer:SendMessage( "Created "..Line1.." shop (".._check.count..countString.." for "..Line3..")" )
					LOG( PLUGIN:GetName().." reporting: created a shop at( "..inX..":"..inY..":"..inZ.." ) by ".._ownername.." ["..Line1.."]" )
					if( Settings.SaveMode == eSaveMode_Paranoid ) then
						SaveData()
					end
				end
			else
				inPlayer:SendMessage( "Fill chest with items you want to sell first" )
			end
		end
	end
	-- now we got to check for cash machine!
	if( Settings.Barter == true ) then
		if( Line2 == ""
		and Line3 == ""
		and Line4 == "" ) then
			if( Line1 == "cash" ) then
				Line1 = ""
				Line2 = ""
				Line3 = ""
				Line4 = ""
				
				if( CheckCashMachineChest( inPlayer:GetWorld(), inX, inY - 1, inZ ) == 1 ) then
					-- OK, there's a chest and we got a sign, let's turn it into motherfucking CASH MACHINE!
					Line1 = "Cash Machine"
					Line3 = "belong to"
					Line4 = _ownername
					RegisterCashMachine( inPlayer:GetWorld(), inPlayer:GetName(), inX, inY, inZ )
					LOG( PLUGIN:GetName().." reporting: created a cash machine at( "..inX..":"..inY..":"..inZ.." ) by ".._ownername )
					if( SaveMode == eSaveMode_Paranoid ) then
						SaveData()
					end
				else
					inPlayer:SendMessage( "There's no fucking chest, how are you supposed to keep your piles of... whatever?!" )
				end
			end
		end
	end
    --return false, "_l1", "_l2", "_l3", "_l4"
	return false, Line1, Line2, Line3, Line4
	--return true, Line1, Line2, Line3, Line4
end
-- LEFTCLICK!
function OnPlayerLeftClick( inPlayer, inX, inY, inZ, inFace, inAction )
	if( inX ~= -1 and inY ~= 255 and inZ ~= -1 ) then
		local shouldReturn, returnValue = SafetyChecks( inPlayer, inX, inY, inZ, true )
		if( shouldReturn ) then
			return returnValue
		end
		
		-- Operating
		_items_traded = SellToShop( inPlayer:GetWorld(), inPlayer, inX, inY, inZ )
		if( _items_traded > 0 ) then
			if( OperationState.partial == true ) then
				inPlayer:SendMessage( Messages.partial_transfer )
			end
			local _itemname = HANDY:Call( "PluralItemName", OperationState.itemID, OperationState.amount )
			local _price = OperationState.money_amount
			if( Settings.Barter == false ) then
				_price = _price.." "..HANDY:Call( "PluralString", OperationState.money_amount, " coin", " coins" )
			else
				_price = _price.." "..HANDY:Call( "PluralItemName", Settings.BarterItem, OperationState.money_amount )
			end
			inPlayer:SendMessage( "Sold "..OperationState.amount.." ".._itemname.." for ".._price..", to "..OperationState.merchantname )
			if( SaveMode == eSaveMode_Paranoid ) then
				SaveData()
			end
			return true
		elseif( _items_traded == 0 ) then
			if( OperationState.performed == true ) then
				OperationState.performed = false
				if( OperationState.success == false ) then
					if( OperationState.fail_reason 					== FailReason.merchant_no_money )		then
						inPlayer:SendMessage( Messages.merchant_no_money )
						HANDY:Call( "GetPlayerByName", OperationState.merchantname ):SendMessage( Messages.to_merchant_no_money )
					elseif( OperationState.fail_reason 				== FailReason.player_no_space )			then
						inPlayer:SendMessage( Messages.player_no_space )
					elseif( OperationState.fail_reason 				== FailReason.not_enough_space )		then
						inPlayer:SendMessage( Messages.not_enough_space )
						local _merchant_message = Messages.to_merchant_not_enough_space..": "..GetShopDescription( inPlayer:GetWorld(), inX, inY, inZ )
						HANDY:Call( "GetPlayerByName", OperationState.merchantname ):SendMessage( _merchant_message )
					elseif( OperationState.fail_reason 				== FailReason.not_enough_items )		then
						inPlayer:SendMessage( Messages.not_enough_items )
					end
				else
					-- means that there were no obstacles other than no items in inPlayer at all
					inPlayer:SendMessage( Messages.no_items_in_player )
				end
				return true
			end
		end
	end
	return false
end
-- RIGHTCLICK!
function OnPlayerRightClick( inPlayer, inX, inY, inZ, inFace, inCursorX, inCursorY, inCursorZ )
	if( inX ~= -1 and inY ~= 255 and inZ ~= -1 ) then
		local shouldReturn, returnValue = SafetyChecks( inPlayer, inX, inY, inZ, false )
		if( shouldReturn ) then
			return returnValue
		end
		
		_items_traded = BuyFromShop( inPlayer:GetWorld(), inPlayer, inX, inY, inZ )
		if( _items_traded > 0 ) then
			if( OperationState.partial == true ) then
				inPlayer:SendMessage( Messages.partial_transfer )
			end
			local _itemname = HANDY:Call( "PluralItemName", OperationState.itemID, OperationState.amount )
			local _price = OperationState.money_amount
			if( Settings.Barter == false ) then
				_price = _price.." "..HANDY:Call( "PluralString", OperationState.money_amount, " coin", " coins" )
			else
				_price = _price.." "..HANDY:Call( "PluralItemName", Settings.BarterItem, OperationState.money_amount )
			end
			inPlayer:SendMessage( "Bought "..OperationState.amount.." ".._itemname.." for ".._price..", from "..OperationState.merchantname )
			if( Settings.SaveMode == eSaveMode_Paranoid ) then
				SaveData()
			end
			return true
		elseif( _items_traded == 0 ) then
			if( OperationState.performed == true ) then
				OperationState.performed = false
				if( OperationState.success == false ) then
					if( OperationState.fail_reason 				== FailReason.merchant_no_space )			then
						inPlayer:SendMessage( Messages.merchant_no_space )
						HANDY:Call( "GetPlayerByName", OperationState.merchantname ):SendMessage( Messages.to_merchant_no_space )
					elseif( OperationState.fail_reason 				== FailReason.player_no_money )				then
						inPlayer:SendMessage( Messages.player_no_money )
					elseif( OperationState.fail_reason 				== FailReason.player_no_space )				then
						inPlayer:SendMessage( Messages.player_no_space )
					elseif( OperationState.fail_reason 				== FailReason.not_enough_items )				then
						inPlayer:SendMessage( Messages.not_enough_items )
					end
				else
					-- means that there were no obstacles other than no items in chest at all
					inPlayer:SendMessage( Messages.no_items_in_shop )
				end
				return true
			end
		end
	end
	return false
end
-- DESTROY!
function OnPlayerBreakingBlock( inPlayer, inX, inY, inZ, inFace, inType, inMeta )
	if( inX ~= -1 and inY ~= 255 and inZ ~= -1 ) then
		CheckDestroyThings( inPlayer, inX, inY, inZ )
		CheckDestroyThings( inPlayer, inX, inY + 1, inZ )
	end
	return false
end

















