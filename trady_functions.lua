--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function CheckShopChest( IN_world, IN_x, IN_y, IN_z )			-- RETURNS WHAT IS IN THE CHEST AND IN WHICH AMMOUNT
	local ReadChest = function( inChest )
		-- stalk through chest slots...
		local slotItem
		local chestGrid = inChest:GetContents()
		local slotsCount = chestGrid:GetNumSlots()
		for index = 0, (slotsCount - 1) do
			slotItem = chestGrid:GetSlot( index )
			if( slotItem:IsEmpty() == false ) then
				if( _result.foundStuff ) then
					if( slotItem.m_ItemType == _result.type ) then
						_result.count = _result.count + slotItem.m_ItemCount
					else
						_result.clashingItems = true
						break
					end
				else
					_result.type = slotItem.m_ItemType
					_result.count = slotItem.m_ItemCount
					_result.foundStuff = true
				end
			end
		end
	end
	_result = {}
	_result.type = -1
	_result.count = 0
	_result.foundStuff = false
	_result.clashingItems = false
	IN_world:DoWithChestAt( IN_x, IN_y, IN_z, ReadChest )
	return _result
end

function CheckIntegrity( IN_world, IN_x, IN_y, IN_z )			-- check on SIGN placement
	_result = -1
	local ReadChest = function( Chest )
		if( Chest ~= nil ) then
			_result = _result + 1
		end
	end
	IN_world:DoWithChestAt( IN_x, IN_y - 1, IN_z, ReadChest )
	_sign = IN_world:GetSignLines( IN_x, IN_y, IN_z, _line1, _line2, _line3, _line4 )
	if( _sign ~= false ) then
		_result = _result + 1
	end
	return _result
end

function CheckCashMachineChest( IN_world, IN_x, IN_y, IN_z )	-- we just want to know if some chest is even there :D
	local ReadChest = function( Chest )
		_result = 1
	end
	_result = 0
	IN_world:DoWithChestAt( IN_x, IN_y, IN_z, ReadChest )
	return _result
end

function CheckShopThere( IN_world, IN_x, IN_y, IN_z )		-- is there any shop at all?
	local _adress = GetAdress( IN_world, IN_x, IN_y, IN_z )
	if( ShopsData[_adress] ~= nil ) then
		return true
	end
	return false
end

function CheckCashMachineThere( IN_world, IN_x, IN_y, IN_z )
	local _result = false
	for k,v in pairs( TradersData ) do
		if( v.cashmachine.world == IN_world
		and v.cashmachine.x == IN_x
		and v.cashmachine.y == IN_y
		and v.cashmachine.z == IN_z ) then
			_result = true
		end
	end
	return _result
end

function GetCashMachineThere( IN_world, IN_x, IN_y, IN_z )
	for k,v in pairs( TradersData ) do
		if( v.cashmachine ~= nil ) then
			if( v.cashmachine.world == IN_world
			and v.cashmachine.x == IN_x
			and v.cashmachine.y == IN_y
			and v.cashmachine.z == IN_z ) then
				return k, v
			end
		end
	end
	return nil, nil
end

function RegisterShop( IN_world, IN_ownername, IN_x, IN_y, IN_z, IN_itemID, IN_ammount, IN_tochest, IN_fromchest, IN_fractional_trade )
	LOG( "Getting adress" )
	local _adress = GetAdress( IN_world, IN_x, IN_y, IN_z )
	LOG( "Got adress" )
	if( ShopsData[_adress] == nil )				then ShopsData[_adress] = {} end
	ShopsData[_adress].ownername = IN_ownername
	ShopsData[_adress].world = IN_world	-- NOT A NAME!
	
	ShopsData[_adress].x = IN_x
	ShopsData[_adress].y = IN_y
	ShopsData[_adress].z = IN_z
	
	ShopsData[_adress].item = IN_itemID
	ShopsData[_adress].ammount = IN_ammount
	ShopsData[_adress].tochest = IN_tochest
	ShopsData[_adress].fromchest = IN_fromchest
	ShopsData[_adress].fractional = IN_fractional_trade
	
	if( TradersData[IN_ownername] == nil ) then
		TradersData[IN_ownername] = {}
	end
end

function RegisterCashMachine( IN_world, IN_ownername, IN_x, IN_y, IN_z )
	if( TradersData[IN_ownername] == nil ) then
		TradersData[IN_ownername] = {}
	end
	if( TradersData[IN_ownername].cashmachine == nil ) then
		TradersData[IN_ownername].cashmachine = {}
	else
		-- TODO: warn merchant that he's replacing his cashmachine!
	end
	TradersData[IN_ownername].cashmachine.x = IN_x
	TradersData[IN_ownername].cashmachine.y = IN_y
	TradersData[IN_ownername].cashmachine.z = IN_z
	TradersData[IN_ownername].cashmachine.world = IN_world
end
-- * * * * *
function GetShopDescription( IN_world, IN_x, IN_y, IN_z )
	local _adress = GetAdress( IN_world, IN_x, IN_y, IN_z )
	if( ShopsData[_adress] ~= nil ) then
		return HANDY:Call( "PluralItemName", ShopsData[_adress].item, 10 ).." @["..IN_x.."; "..IN_y.."; "..IN_z.."] in "..ShopsData[_adress].world:GetName()
	end
	return "no shop found"
end
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--/ / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
function GetFromShop( IN_world, Player, IN_x, IN_y, IN_z )
	local OperateChest = function( Chest )
		local _c_balance, _c_free_space = HANDY:Call( "ReadChestForItem", Chest, ShopsData[_adress].item )
		_trade_count = math.min( _trade_count, _c_balance )
		if( _trade_count < ShopsData[_adress].ammount ) then
			if( _fractional_trade == false
			or _trade_count <= 0 )	then	--																		<<< miniDOOMSDAY DEVICE
				return 0
			end
		end
		HANDY:Call( "TakeItemsFromChest", Chest, ShopsData[_adress].item, _trade_count )
	end
	_adress = GetAdress( IN_world, IN_x, IN_y, IN_z )
	local _result = 0	-- will contain ammount of traded items
	OPERATION_STATE.success = false
	OPERATION_STATE.partial = false
	
	if( ShopsData[_adress] ~= nil ) then
		if( ShopsData[_adress].fromchest ~= -1 ) then
			if( HALT_SELF_TRADE == true
			and ShopsData[_adress].ownername == Player:GetName() ) then	--											<<< DOOMSDAY DEVICE
				return -1
			end
			--/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
			_trade_count = 1
			local _transfer_item = cItem( ShopsData[_adress].item, _trade_count )
			_fractional_trade =( ShopsData[_adress].fractional and FRACTIONAL_TRADE )
			OPERATION_STATE.itemID = ShopsData[_adress].item
			OPERATION_STATE.merchantname = ShopsData[_adress].ownername
			OPERATION_STATE.performed = true
			
			-- 1. Check, how much items player could afford; how much items merchant could sell( cash machine storage has limits! )
			local _unit_price =( ShopsData[_adress].fromchest/ShopsData[_adress].ammount )
			local _p_balance, _p_free_space = GetPlayerTradeData( Player:GetName() )
			local _m_balance, _m_free_space = GetMerchantTradeData( ShopsData[_adress].ownername )
			local _player_can_buy = math.floor( _p_balance/_unit_price )
			local _merchant_can_sell = math.floor( _m_free_space/_unit_price )
			if( _m_free_space == -1 )	then	_merchant_can_sell = ShopsData[_adress].ammount	end
			_trade_count = math.min( _player_can_buy, _merchant_can_sell )
			if( _player_can_buy < ShopsData[_adress].ammount ) then
				OPERATION_STATE.partial = true
				OPERATION_STATE.fail_reason = FAIL_REASON.player_no_money
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			if( _merchant_can_sell < ShopsData[_adress].ammount ) then
				OPERATION_STATE.partial = true
				OPERATION_STATE.fail_reason = FAIL_REASON.merchant_no_space
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			-- 1.1 Also check how much items player could hold!
			_p_balance, _p_free_space = HANDY:Call( "ReadPlayerForItem", Player, ShopsData[_adress].item )
			_trade_count = math.min( _p_free_space, _trade_count )
			if( _trade_count < ShopsData[_adress].ammount ) then
				OPERATION_STATE.partial = true
				OPERATION_STATE.fail_reason = FAIL_REASON.player_no_space
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			_trade_count = math.min( ShopsData[_adress].ammount, _trade_count )
			
			-- 2. Remove as much items from chest, as possible.
			IN_world:DoWithChestAt( IN_x, IN_y - 1, IN_z, OperateChest )
			-- _trade_count now contain ammount of traded items
			if( _trade_count < ShopsData[_adress].ammount ) then
				OPERATION_STATE.partial = true
				OPERATION_STATE.fail_reason = FAIL_REASON.not_enough_items
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			
			-- 3. Charge player.
			MakeTransaction( Player:GetName(), ShopsData[_adress].ownername, _trade_count*_unit_price, true )
			
			-- 4. Add items to player.
			_result = _trade_count
			HANDY:Call( "GiveItemsToPlayer", Player, ShopsData[_adress].item, _trade_count )
			OPERATION_STATE.success = true
			OPERATION_STATE.ammount = _result
			OPERATION_STATE.money_ammount = _result*_unit_price
		end
	else
		_result = -1
	end
	return _result
end
function SellToShop( IN_world, Player, IN_x, IN_y, IN_z )
	local OperateChest = function( Chest )
		local _c_balance, _c_free_space = HANDY:Call( "ReadChestForItem", Chest, ShopsData[_adress].item )
		_trade_count = math.min( _trade_count, _c_free_space )
		LOGWARN( "Free space: ".._c_free_space )
		if( _trade_count < ShopsData[_adress].ammount ) then
			if( _fractional_trade == false
			or _trade_count <= 0 )	then	--																		<<< miniDOOMSDAY DEVICE
				return 0
			end
		end
		HANDY:Call( "PutItemsToChest", Chest, ShopsData[_adress].item, _trade_count )
	end
	_adress = GetAdress( IN_world, IN_x, IN_y, IN_z )
	local _result = 0	-- will contain ammount of traded items
	OPERATION_STATE.success = false
	OPERATION_STATE.partial = false
	
	if( ShopsData[_adress] ~= nil ) then
		if( ShopsData[_adress].tochest ~= -1 ) then
			if( HALT_SELF_TRADE == true
			and ShopsData[_adress].ownername == Player:GetName() ) then	--												<<< DOOMSDAY DEVICE
				return -1
			end
			--/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/-/
			_trade_count = 1
			local _transfer_item = cItem( ShopsData[_adress].item, _trade_count )
			_fractional_trade =( ShopsData[_adress].fractional and FRACTIONAL_TRADE )
			OPERATION_STATE.itemID = ShopsData[_adress].item
			OPERATION_STATE.merchantname = ShopsData[_adress].ownername
			OPERATION_STATE.performed = true
			
			-- 1. Check, how much coins player could take; how much items merchant could buy( cash machine has limits! )
			local _unit_price =( ShopsData[_adress].tochest/ShopsData[_adress].ammount )
			local _p_balance, _p_free_space = GetPlayerTradeData( Player:GetName() )
			local _m_balance, _m_free_space = GetMerchantTradeData( ShopsData[_adress].ownername )
			local _player_can_sell = math.floor( _p_free_space/_unit_price )
			local _merchant_can_buy = math.floor( _m_balance/_unit_price )
			if( _p_free_space == -1 )	then	_player_can_sell = ShopsData[_adress].ammount	end
			_trade_count = math.min( _player_can_sell, _merchant_can_buy )
			if( _player_can_sell < ShopsData[_adress].ammount ) then
				OPERATION_STATE.partial = true
				OPERATION_STATE.fail_reason = FAIL_REASON.player_no_space
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			if( _merchant_can_buy < ShopsData[_adress].ammount ) then
				OPERATION_STATE.partial = true
				OPERATION_STATE.fail_reason = FAIL_REASON.merchant_no_money
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			-- 1.1 Also check how much items player could sell!
			_p_balance, _p_free_space = HANDY:Call( "ReadPlayerForItem", Player, ShopsData[_adress].item )
			_trade_count = math.min( _p_balance, _trade_count )
			if( _trade_count < ShopsData[_adress].ammount ) then
				OPERATION_STATE.partial = true
				OPERATION_STATE.fail_reason = FAIL_REASON.not_enough_items
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			_trade_count = math.min( ShopsData[_adress].ammount, _trade_count )
			
			-- 2. Put as much items into chest, as possible.
			IN_world:DoWithChestAt( IN_x, IN_y - 1, IN_z, OperateChest )
			-- _trade_count now contain ammount of traded items
			if( _trade_count < ShopsData[_adress].ammount ) then
				LOGWARN( "Sooo... Trade count: ".._trade_count )
				OPERATION_STATE.partial = true
				OPERATION_STATE.fail_reason = FAIL_REASON.not_enough_space
				if( _fractional_trade == false
				or _trade_count <= 0 )	then	--																		<<< DOOMSDAY DEVICE
					return 0
				end
			end
			
			-- 3. Charge player.
			MakeTransaction( Player:GetName(), ShopsData[_adress].ownername, _trade_count*_unit_price, false )
			
			-- 4. Remove items from player.
			_result = _trade_count
			HANDY:Call( "TakeItemsFromPlayer", Player, ShopsData[_adress].item, _trade_count )
			OPERATION_STATE.success = true
			OPERATION_STATE.ammount = _result
			OPERATION_STATE.money_ammount = _result*_unit_price
		end
	else
		_result = -1
	end
	return _result
end
--\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function GetMerchantTradeData( IN_merchantname )
	local CheckCashMachine = function( Chest )
		_balance, _free_space = HANDY:Call( "ReadChestForItem", Chest, BarterItem )
	end
	_balance = 0
	_free_space = 0
	
	if( BARTER == false ) then
		_balance = COINY:Call( "GetMoney", IN_merchantname )
		_free_space = -1	-- makes no sense, but still...
	else
		if( TradersData[IN_merchantname] ~= nil ) then
			if( TradersData[IN_merchantname].cashmachine ~= nil ) then
				local _x = TradersData[IN_merchantname].cashmachine.x
				local _y = TradersData[IN_merchantname].cashmachine.y -1
				local _z = TradersData[IN_merchantname].cashmachine.z
				TradersData[IN_merchantname].cashmachine.world:DoWithChestAt( _x, _y, _z, CheckCashMachine )
			end
		end
	end
	return _balance, _free_space
end

function GetPlayerTradeData( IN_playername )
	_balance = 0
	_free_space = 0
	local _player = HANDY:Call( "GetPlayerByName", IN_playername )
	if( BARTER == false ) then
		_balance = COINY:Call( "GetMoney", IN_playername )
		_free_space = -1	-- makes no sense, but still...
	else
		_balance, _free_space = HANDY:Call( "ReadPlayerForItem", _player, BarterItem )
	end
	return _balance, _free_space
end

function MakeTransaction( IN_playername, IN_merchantname, IN_ammount, IN_operation_fromchest )	-- UNSAFE, CHECK FIRST
	if( BARTER == false ) then
		COINY:Call( "TransferMoney", IN_playername, IN_merchantname, tonumber( IN_ammount ) )
	else
		-- coins, coins everywhere!
		local OperateCashMachine = function( Chest )
			if( IN_operation_fromchest == true ) then
				HANDY:Call( "PutItemsToChest", Chest, BarterItem, IN_ammount )
			else
				HANDY:Call( "TakeItemsFromChest", Chest, BarterItem, IN_ammount )
			end
		end
		local _player = HANDY:Call( "GetPlayerByName", IN_playername )
		local _merchant = HANDY:Call( "GetPlayerByName", IN_merchantname )
		
		-- 1. Make operations with cash machine
		local _x = TradersData[IN_merchantname].cashmachine.x
		local _y = TradersData[IN_merchantname].cashmachine.y -1
		local _z = TradersData[IN_merchantname].cashmachine.z
		TradersData[IN_merchantname].cashmachine.world:DoWithChestAt( _x, _y, _z, OperateCashMachine )
		
		-- 2. Make operations with pockets
		if( IN_operation_fromchest == true ) then
			HANDY:Call( "TakeItemsFromPlayer", _player, BarterItem, IN_ammount )
		else
			HANDY:Call( "GiveItemsToPlayer", _player, BarterItem, IN_ammount )
		end
	end
end
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
function LoadData()
--	local _split = ""
--	file = io.open( PLUGIN:GetLocalDirectory().."/trady_shops.dat", "r" )
--	if( file == nil ) then		return 1	end
--	for line in file:lines() do
--		_split = LineSplit( line, ":" )
--		-- _split validation!!!
--		if( #_split == 10 ) then
--			local _adress = GetAdress( cRoot:Get():GetWorld( _split[2] ), _split[3], _split[4], _split[5] )
--			if( CheckIntegrity( cRoot:Get():GetWorld( _split[2] ), _split[3], _split[4], _split[5] ) == 2 ) then
--				if( ShopsData[_adress] == nil ) then
--					ShopsData[_adress] = {}	-- create shop's page
--				end
--				ShopsData[_adress].ownername = _split[1]
--				ShopsData[_adress].world = cRoot:Get():GetWorld( _split[2] )
--				ShopsData[_adress].x = _split[3]
--				ShopsData[_adress].y = _split[4]
--				ShopsData[_adress].z = _split[5]
--				ShopsData[_adress].item = _split[6]
--				ShopsData[_adress].ammount = _split[7]
--				ShopsData[_adress].tochest = _split[8]
--				ShopsData[_adress].fromchest = _split[9]
--				ShopsData[_adress].fractional = HANDY:Call( "StringToBool", _split[10] )
--			else
--				LOGINFO( "Got an invalid note! ".._adress )
--			end
--		end
--	end
--	file:close()
--	-- / / / / / / / / / / / /
--	file = io.open( PLUGIN:GetLocalDirectory().."/trady_merchants.dat", "r" )
--	if( file == nil ) then		return 1	end
--	for line in file:lines() do
--		_split = LineSplit( line, ":" )
--		-- _split validation!!!
--		if( #_split == 5 ) then
--			if( CheckIntegrity( cRoot:Get():GetWorld( _split[2] ), _split[3], _split[4], _split[5] ) == 2 ) then
--				if( TradersData[_split[1]] == nil ) then
--					TradersData[_split[1]] = {}	-- create merchant's page
--				end
--				if( TradersData[_split[1]].cashmachine == nil ) then
--					TradersData[_split[1]].cashmachine = {}	-- and don't forget his cash machine too!
--				end
--				TradersData[_split[1]].cashmachine.world = cRoot:Get():GetWorld( _split[2] )
--				TradersData[_split[1]].cashmachine.x = _split[3]
--				TradersData[_split[1]].cashmachine.y = _split[4]
--				TradersData[_split[1]].cashmachine.z = _split[5]
--			end
--		end
--	end
--	file:close()
end
function SaveData()
	local line = ""
	file = io.open( PLUGIN:GetLocalDirectory().."/trady_shops.dat", "w" )
	for k,v in pairs( ShopsData ) do
		line = ""..v.ownername
		line = line..":"..v.world:GetName()
		line = line..":"..v.x..":"..v.y..":"..v.z
		line = line..":"..v.item
		line = line..":"..v.ammount
		line = line..":"..v.tochest
		line = line..":"..v.fromchest
		line = line..":"..HANDY:Call( "BoolToString", v.fractional )
		file:write( line.."\n" )
	end
	file:close()
	-- / / / / / / / / / / / /
	file = io.open( PLUGIN:GetLocalDirectory().."/trady_merchants.dat", "w" )
	for k,v in pairs( TradersData ) do
		if( v.cashmachine ~= nil ) then
			line = ""..k
			line = line..":"..v.cashmachine.world:GetName()
			line = line..":"..v.cashmachine.x..":"..v.cashmachine.y..":"..v.cashmachine.z
			--file:write( line.."\n" )
		end
	end
	file:close()
	LOG( PLUGIN:GetName().." v"..PLUGIN:GetVersion()..": Data was saved" )
end
-- * * * * *
function LoadSettings()
	_ini_file = cIniFile()
	_ini_file:ReadFile( PLUGIN:GetLocalDirectory().."/trady_settings.ini" )
	local _save_mode = _ini_file:GetValueSet( "Settings", "SaveMode", "Timed" )
	local _barter_item = _ini_file:GetValueSet( "Settings", "BarterItem", ItemTypeToString( E_ITEM_GOLD_NUGGET ) )
	if( _save_mode == "Timed" )		then SaveMode = eSaveMode_Timed		end
	if( _save_mode == "Paranoid" )	then SaveMode = eSaveMode_Paranoid	end
	if( _save_mode == "Relaxed" )	then SaveMode = eSaveMode_Relaxed	end
	if( _save_mode == "Dont" )		then SaveMode = eSaveMode_Dont		end
	SaveEveryNthTick = 				_ini_file:GetValueSetI( "Settings", "TicksPerSave", 		10000 )
	FRACTIONAL_TRADE = 				_ini_file:GetValueSetB( "Settings", "AllowFractionalTrade", true )
	BARTER = 						_ini_file:GetValueSetB( "Settings", "Barter", 				false )
	BarterItem	= 					BlockStringToType( _barter_item )
	HALT_SELF_TRADE = 				_ini_file:GetValueSetB( "Settings", "HaltSelfTrade", 			true )
	USING_NON_OWNER_PROTECTION = 	_ini_file:GetValueSetB( "Settings", "AllowUsingProtection", 	true )
	BREAKING_NON_OWNER_PROTECTION = _ini_file:GetValueSetB( "Settings", "AllowBreakingProtection", 	true )
	_ini_file:WriteFile( PLUGIN:GetLocalDirectory().."/trady_settings.ini" )
end
function SaveSettings()
	_ini_file = cIniFile()
	_ini_file:ReadFile( PLUGIN:GetLocalDirectory().."/trady_settings.ini" )
	local _save_mode = _ini_file:GetValueSet( "Settings", "SaveMode", "Timed" )
	local _barter_item = _ini_file:GetValueSet( "Settings", "BarterItem", ItemTypeToString( E_ITEM_GOLD_NUGGET ) )
	if( SaveMode == eSaveMode_Timed )	then	_save_mode = "Timed"	end
	if( SaveMode == eSaveMode_Paranoid )then	_save_mode = "Paranoid"	end
	if( SaveMode == eSaveMode_Relaxed )	then	_save_mode = "Relaxed"	end
	if( SaveMode == eSaveMode_Dont )	then	_save_mode = "Dont"		end
	_ini_file:SetValueI( "Settings", "TicksPerSave", 			SaveEveryNthTick, 				false )
	_ini_file:SetValue( "Settings", "SaveMode", 				_save_mode, 					false )
	_ini_file:SetValueB( "Settings", "AllowFractionalTrade", 	FRACTIONAL_TRADE, 				false )
	_ini_file:SetValueB( "Settings", "Barter", 					BARTER, 						false )
	_ini_file:SetValue( "Settings", "BarterItem", 				ItemTypeToString( BarterItem ),	false )
	_ini_file:SetValueB( "Settings", "HaltSelfTrade", 			HALT_SELF_TRADE, 				false )
	_ini_file:SetValueB( "Settings", "AllowUsingProtection", 	USING_NON_OWNER_PROTECTION, 	false )
	_ini_file:SetValueB( "Settings", "AllowBreakingProtection", BREAKING_NON_OWNER_PROTECTION, 	false )
	_ini_file:WriteFile( PLUGIN:GetLocalDirectory().."/trady_settings.ini" )
end
--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
-- splits line by any desired symbol
function LineSplit( pString, pPattern )		-- THANK YOU, stackoverflow!
	local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pPattern
	local last_end = 1
	local s, e, cap = pString:find( fpat, 1 )
	while s do
		if( s ~= 1 or cap ~= "" ) then
			table.insert( Table,cap )
		end
		last_end = e + 1
		s, e, cap = pString:find( fpat, last_end )
	end
	if( last_end <= #pString ) then
		cap = pString:sub( last_end )
		table.insert( Table, cap )
	end
	return Table
end

function GetAdress( IN_world, IN_x, IN_y, IN_z )
	return IN_world:GetName().." x:"..tostring( IN_x ).." y:"..tostring( IN_y ).." z:"..tostring( IN_z )
end

function GetAdressWorldname( IN_worldname, IN_x, IN_y, IN_z )	-- PROBABLY USELESS
	return IN_worldname.." x:"..tostring( IN_x ).." y:"..tostring( IN_y ).." z:"..tostring( IN_z )
end