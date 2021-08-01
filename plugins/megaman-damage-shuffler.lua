--[[ HOW TO ADD YOUR OWN ROM VERSION:

1) find the appropriate tag for your game from the list in the gamedata or romhashes tables.
    e.g., if you are trying to add a version of MMX5, find the area with the hashes for mmx5psx

2) determine the hash for your version. the easiest way to do this is to run the hash.lua script
    in the shuffler-src/ folder. it will give you both the hash and the game name

3) add an entry to the romhashes table to map the hash value to the game tag. you can copy an
    existing entry to get the formatting right if you are unfamiliar with Lua syntax
--]]

local plugin = {}

plugin.name = "Megaman Damage Shuffler"
plugin.author = "authorblues"
plugin.settings =
{
	-- enable this feature to have health and lives synchronized across games
	--{ name='healthsync', type='boolean', label='Synchronize Health/Lives' },
}

plugin.description =
[[
	Automatically swaps games any time Megaman takes damage. Checks hashes of different rom versions, so if you use a version of the rom that isn't recognized, nothing special will happen in that game (no swap on hit).

	Supports:
	- Mega Man 1-6 NES
	- Mega Man 7 SNES
	- Mega Man 8 PSX
	- Mega Man X 1-3 SNES
	- Mega Man X3 PSX (PAL & NTSC-J)
	- Mega Man X 4-6 PSX
	- Mega Man Xtreme 1 & 2 GBC
	- Rockman & Forte SNES
	- Mega Man I-V GB
	- Mega Man Wily Wars GEN
]]

local prevdata = {}

local shouldSwap = function() return false end

local function generic_swap(gamemeta)
	return function(data)
		local currhp = gamemeta.gethp()
		local currlc = gamemeta.getlc()

		local maxhp = gamemeta.maxhp()
		local minhp = gamemeta.minhp or 0

		-- health must be within an acceptable range to count
		-- ON ACCOUNT OF ALL THE GARBAGE VALUES BEING STORED IN THESE ADDRESSES
		if currhp < minhp or currhp > maxhp then
			return false
		end

		-- retrieve previous health and lives before backup
		local prevhp = data.prevhp
		local prevlc = data.prevlc

		data.prevhp = currhp
		data.prevlc = currlc

		-- this delay ensures that when the game ticks away health for the end of a level,
		-- we can catch its purpose and hopefully not swap, since this isnt damage related
		if data.hpcountdown ~= nil and data.hpcountdown > 0 then
			data.hpcountdown = data.hpcountdown - 1
			if data.hpcountdown == 0 and currhp > minhp then
				return true
			end
		end

		-- if the health goes to 0, we will rely on the life count to tell us whether to swap
		if prevhp ~= nil and currhp < prevhp then
			data.hpcountdown = gamemeta.delay or 3
		end

		-- check to see if the life count went down
		if prevlc ~= nil and currlc < prevlc then
			return true
		end

		return false
	end
end

local gamedata = {
	['mm1nes']={ -- Mega Man NES
		gethp=function() return mainmemory.read_u8(0x006A) end,
		getlc=function() return mainmemory.read_u8(0x00A6) end,
		maxhp=function() return 28 end,
	},
	['mm2nes']={ -- Mega Man 2 NES
		gethp=function() return mainmemory.read_u8(0x06C0) end,
		getlc=function() return mainmemory.read_u8(0x00A8) end,
		maxhp=function() return 28 end,
	},
	['mm3nes']={ -- Mega Man 3 NES
		gethp=function() return bit.band(mainmemory.read_u8(0x00A2), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x00AE) end,
		maxhp=function() return 28 end,
	},
	['mm4nes']={ -- Mega Man 4 NES
		gethp=function() return bit.band(mainmemory.read_u8(0x00B0), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x00A1) end,
		maxhp=function() return 28 end,
	},
	['mm5nes']={ -- Mega Man 5 NES
		gethp=function() return bit.band(mainmemory.read_u8(0x00B0), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x00BF) end,
		maxhp=function() return 28 end,
	},
	['mm6nes']={ -- Mega Man 6 NES
		gethp=function() return mainmemory.read_u8(0x03E5) end,
		getlc=function() return mainmemory.read_u8(0x00A9) end,
		maxhp=function() return 27 end,
	},
	['mm7snes']={ -- Mega Man 7 SNES
		gethp=function() return mainmemory.read_u8(0x0C2E) end,
		getlc=function() return mainmemory.read_s8(0x0B81) end,
		maxhp=function() return 28 end,
	},
	['mm8psx']={ -- Mega Man 8 PSX
		gethp=function() return mainmemory.read_u8(0x15E283) end,
		getlc=function() return mainmemory.read_u8(0x1C3370) end,
		maxhp=function() return 40 end,
	},
	['mmwwgen']={ -- Mega Man Wily Wars GEN
		gethp=function() return mainmemory.read_u8(0xA3FE) end,
		getlc=function() return mainmemory.read_u8(0xCB39) end,
		maxhp=function() return 28 end,
	},
	['rm&f']={ -- Rockman & Forte SNES
		gethp=function() return mainmemory.read_u8(0x0C2F) end,
		getlc=function() return mainmemory.read_s8(0x0B7E) end,
		maxhp=function() return 28 end,
	},
	['mmx1']={ -- Mega Man X SNES
		gethp=function() return bit.band(mainmemory.read_u8(0x0BCF), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x1F80) end,
		maxhp=function() return mainmemory.read_u8(0x1F9A) end,
	},
	['mmx2']={ -- Mega Man X2 SNES
		gethp=function() return bit.band(mainmemory.read_u8(0x09FF), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x1FB3) end,
		maxhp=function() return mainmemory.read_u8(0x1FD1) end,
	},
	['mmx3']={ -- Mega Man X3 SNES
		gethp=function() return mainmemory.read_u8(0x09FF) end,
		getlc=function() return mainmemory.read_u8(0x1FB4) end,
		maxhp=function() return mainmemory.read_u8(0x1FD2) end,
	},
	['mmx3psx-eu']={ -- Mega Man X3 PSX PAL
		gethp=function() return mainmemory.read_u8(0x0D8528) end,
		getlc=function() return mainmemory.read_u8(0x0D8743) end,
		maxhp=function() return mainmemory.read_u8(0x0D8761) end,
	},
	['mmx3psx-jp']={ -- Mega Man X3 PSX NTSC-J
		gethp=function() return mainmemory.read_u8(0x0D7EDC) end,
		getlc=function() return mainmemory.read_u8(0x0D80F7) end,
		maxhp=function() return mainmemory.read_u8(0x0D8115) end,
	},
	['mmx4psx-us']={ -- Mega Man X4 PSX
		gethp=function() return bit.band(mainmemory.read_u8(0x141924), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x172204) end,
		maxhp=function() return mainmemory.read_u8(0x172206) end,
	},
	['mmx5psx-us']={ -- Mega Man X5 PSX
		gethp=function() return bit.band(mainmemory.read_u8(0x09A0FC), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x0D1C45) end,
		maxhp=function() return mainmemory.read_u8(0x0D1C47) end,
	},
	['mmx6psx-us']={ -- Mega Man X6 PSX NTSC-U
		gethp=function() return bit.band(mainmemory.read_u8(0x0970FC), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x0CCF09) end,
		maxhp=function() return mainmemory.read_u8(0x0CCF2B) end,
	},
	['mmx6psx-jp']={ -- Mega Man X6 PSX NTSC-J
		gethp=function() return bit.band(mainmemory.read_u8(0x0987BC), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x0CE5C9) end,
		maxhp=function() return mainmemory.read_u8(0x0CE5EB) end,
	},
	['mm1gb']={ -- Mega Man I GB
		gethp=function() return mainmemory.read_u8(0x1FA3) end,
		getlc=function() return mainmemory.read_s8(0x0108) end,
		maxhp=function() return 152 end,
	},
	['mm2gb']={ -- Mega Man II GB
		gethp=function() return mainmemory.read_u8(0x0FD0) end,
		getlc=function() return mainmemory.read_s8(0x0FE8) end,
		maxhp=function() return 152 end,
	},
	['mm3gb']={ -- Mega Man III GB
		gethp=function() return mainmemory.read_u8(0x1E9C) end,
		getlc=function() return mainmemory.read_s8(0x1D08) end,
		maxhp=function() return 152 end,
	},
	['mm4gb']={ -- Mega Man IV GB
		gethp=function() return mainmemory.read_u8(0x1EAE) end,
		getlc=function() return mainmemory.read_s8(0x1F34) end,
		maxhp=function() return 152 end,
	},
	['mm5gb']={ -- Mega Man V GB
		gethp=function() return mainmemory.read_u8(0x1E9E) end,
		getlc=function() return mainmemory.read_s8(0x1F34) end,
		maxhp=function() return 152 end,
	},
	['mmx1gbc']={ -- Mega Man Xtreme GBC
		gethp=function() return bit.band(mainmemory.read_u8(0x0ADC), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x1365) end,
		maxhp=function() return mainmemory.read_u8(0x1384) end,
	},
	['mmx2gbc']={ -- Mega Man Xtreme 2 GBC
		gethp=function() return bit.band(mainmemory.read_u8(0x0121), 0x7F) end,
		getlc=function() return mainmemory.read_u8(0x0065) end,
		maxhp=function() return mainmemory.read_u8(0x0084) end,
	},
}

-- same RAM maps across versions?
local romhashes = {
	-- Mega Man NES rom hashes
	['0FE255649359ECE8CB64B6F24ACAF09F17AF746C'] = 'mm1nes', -- Mega Man (E) [!].nes
	['17730D3A6E4A618CF1AA106024C8FB4EE2E18907'] = 'mm1nes', -- Mega Man (E) [T+Dut1.0_Ok Impala!].nes
	['6F6C21598A417CC3AD6D06D32CAB7372F12C1C7C'] = 'mm1nes', -- Mega Man (E) [T+Ita][b1].nes
	['8F4E5FCF4E8F000F47A24E8027983CE43025CD19'] = 'mm1nes', -- Mega Man (U) [b1].nes
	['434BB2FE2D0C304FF61B6443092DF80F1D9851BF'] = 'mm1nes', -- Mega Man (U) [b1][o1].nes
	['EC670DF183987A6F8E7C79818C6F09F7A5DFE7D8'] = 'mm1nes', -- Mega Man (U) [b2].nes
	['11E6F4F20056EC4D793927ECBA12C674DE88A28E'] = 'mm1nes', -- Mega Man (U) [b2][o1].nes
	['4BF1D3206AB23CE4CA4B34ACC75306DF4C0D624F'] = 'mm1nes', -- Mega Man (U) [b3].nes
	['8E631414EDE6EDD08A80A498DCEFAB74721202F5'] = 'mm1nes', -- Mega Man (U) [b4].nes
	['D4BD832BBA92B3A4E6185C9873E750432F7252A4'] = 'mm1nes', -- Mega Man (U) [h1].nes
	['CC81DF2E05333C4E5E9C12B34B3119332CB99F4D'] = 'mm1nes', -- Mega Man (U) [o1].nes
	['4C7C9BFABB2C3917DF1AC0E4412D69C0CC1FEE5B'] = 'mm1nes', -- Mega Man (U) [o2].nes
	['5580D11FE8D219CB6FECF6A33D16BF7C71319FE3'] = 'mm1nes', -- Mega Man (U) [T+Dut].nes
	['74D23553FC084C3213A44AE9A010922A39DA9CB4'] = 'mm1nes', -- Mega Man (U) [T+FreBeta(w-BossNames)_Generation IX].nes
	['B8FBE2442D662837F4CDA27426915628A51B67C5'] = 'mm1nes', -- Mega Man (U) [T+FreBeta_Generation IX].nes
	['2439681F1E7109DC8FD48F67B909293FD28F6A7F'] = 'mm1nes', -- Mega Man (U) [T+Fre_Terminus].nes
	['6702B493B63D7973EF2AE0D54B03AB20DD233B21'] = 'mm1nes', -- Mega Man (U) [T+Ger.90].nes
	['258D5BD4174EAD09635B540710987B1E61A03358'] = 'mm1nes', -- Mega Man (U) [T+Ita1.1NC_Clomax Dominion].nes
	['8E0FEC0875F99036975B877A45CD37E8EC762783'] = 'mm1nes', -- Mega Man (U) [T+Ita1.1_Clomax Dominion].nes
	['9FE9B4DB70AD1FAE13CEA4F7C8AA4DE2B0D916E4'] = 'mm1nes', -- Mega Man (U) [T+Nor0.90_Just4fun].nes
	['79BEA544EA2E9DC16504248B629378BCDECA9582'] = 'mm1nes', -- Mega Man (U) [T+Spa100%_Tanero].nes
	['FCCD92578A53C191B91AEAF9D3C09AB3F606B351'] = 'mm1nes', -- Mega Man (U) [T+Spa_PaladinKnights].nes
	['714F069E1847BA30F525AF4B8E10A8EEEBEBDA70'] = 'mm1nes', -- Mega Man (U) [T-Ita1.00_Clomax_Dominion].nes
	['F0CC04FBEBB2552687309DA9AF94750F7161D722'] = 'mm1nes', -- Mega Man (U).nes
	['2F88381557339A14C20428455F6991C1EB902C99'] = 'mm1nes', -- Mega Man (USA) No-Intro: Nintendo Entertainment System (v. 20180803-121122)
	['216B87986FF4B8A87D4501702C73DA29ED688B81'] = 'mm1nes', -- Rockman (J) [b1].nes
	['C76C565B814938DF4985E6BAAC1FE0D6CF5EE282'] = 'mm1nes', -- Rockman (J) [b2].nes
	['324A6D98BA416D1827679ABF0D241D684E0191F7'] = 'mm1nes', -- Rockman (J) [b3].nes
	['3C7674C08122F15F26EEC595922CFF8C31A8127D'] = 'mm1nes', -- Rockman (J) [b4].nes
	['81A321025700417878B8DFAA2DA97ADA1F05E57F'] = 'mm1nes', -- Rockman (J) [b5].nes
	['F6908E935FFF9768F356D9C0C8824F17CBDA622C'] = 'mm1nes', -- Rockman (J) [o1].nes
	['7B2C88D141C50B43B2A56440C6D5B35AD0B0DD5B'] = 'mm1nes', -- Rockman (J) [p1].nes
	['B105577C3E9B1DA9A41C9E0570EEC19756491F23'] = 'mm1nes', -- Rockman (J) [T+Spa_PaladinKnights].nes
	['5914D409EA027A96C2BB58F5136C5E7E9B2E8300'] = 'mm1nes', -- Rockman (J).nes
	-- Mega Man 2 NES rom hashes
	['A9DAFF94A800625A5D10345C3A3C8952FB57CF87'] = 'mm2nes', -- Mega Man 2 (E) [!].nes
	['5211852176C0EFA90705A46553A4D8AFFD1E7FEE'] = 'mm2nes', -- Mega Man 2 (U) [h1].nes
	['BA1A9D0CDD96FF0AB3BBF4873D45372F15A8D6CA'] = 'mm2nes', -- Mega Man 2 (U) [o1].nes
	['9CC6FDB1714997A9EB108E00D18E849AD6B84B13'] = 'mm2nes', -- Mega Man 2 (U) [o1][T-Ger][a1].nes
	['DD47E1B29161BC37B5AC144335C2FD9C71C72B8D'] = 'mm2nes', -- Mega Man 2 (U) [o2].nes
	['4581C42B18715C46459D5AF7B8714B1C0A186F37'] = 'mm2nes', -- Mega Man 2 (U) [T+Fre1.0].nes
	['F58025EA53D969B32910D80988232B7AB45B9BF3'] = 'mm2nes', -- Mega Man 2 (U) [T+FreBeta(w-BossNames)_Generation IX].nes
	['99E03963EDA39ECDA1B22FD358F508C39DAE8DD8'] = 'mm2nes', -- Mega Man 2 (U) [T+FreBeta_Generation IX].nes
	['9C516B275BAE5258B628A28E0EBC145188290CEB'] = 'mm2nes', -- Mega Man 2 (U) [T+Ger1.01].nes
	['5C366EF09F0B6DA755BDDBD4EEAA86C5CEDF1F62'] = 'mm2nes', -- Mega Man 2 (U) [T+Ita1.0_NukeTeam].nes
	['A0620C6656EB37D26E3D94867551CB47B59A9F72'] = 'mm2nes', -- Mega Man 2 (U) [T+Ita1.2_Clomax Dominion].nes
	['8124EE7D96ED590455C3D9FC057148B66A3F4F84'] = 'mm2nes', -- Mega Man 2 (U) [T+Nor.99_Just4fun].nes
	['C55766178B220B1B7359EBBA076F7082550D2FE1'] = 'mm2nes', -- Mega Man 2 (U) [T+Por].nes
	['9C3215806B15D95D72A43D5F48FBA3C56C02C5F1'] = 'mm2nes', -- Mega Man 2 (U) [T+Spa100%_PaladinKnights].nes
	['4B92B3143D96C643247201EC45F3D09D5520EB45'] = 'mm2nes', -- Mega Man 2 (U) [T+Spa100%_Tanero].nes
	['E3F5A07FD589F2CFBEAF448C3918529C6FAAF76C'] = 'mm2nes', -- Mega Man 2 (U) [T+Swe1.0_TheTranslator].nes
	['E73AF24C9217BD0859763607435090EDE8FBD74D'] = 'mm2nes', -- Mega Man 2 (U) [T-Ger].nes
	['6B33095E264C96DBFB23A01CDB4A097BAF12C73F'] = 'mm2nes', -- Mega Man 2 (U) [T-Ger][a1].nes
	['F5A1DE05C0C705D927C5D82608837B0BA9D377AD'] = 'mm2nes', -- Mega Man 2 (U) [T-Ger][a2].nes
	['5AA5C379DB872EE8652DA03287CDE1026D4DD646'] = 'mm2nes', -- Mega Man 2 (U) [T-Ger][b1].nes
	['98D5DB1CD22E1C06F574B099BA9C5E10DF09EE69'] = 'mm2nes', -- Mega Man 2 (U) [T-Ser0.60_SeeGot].nes
	['6B5B9235C3F630486ED8F07A133B044EAA2E22B2'] = 'mm2nes', -- Mega Man 2 (U).nes
	['2290D8D839A303219E9327EA1451C5EEA430F53D'] = 'mm2nes', -- Mega Man 2 (USA) (No-Intro version 20130731-235630)
	['A2A7B4F177CC2DEA0D846B1190008AAD3CDD45EA'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [b1].nes
	['EEA7BB60E139C96569F7CE6DBB7EB9C4ED7A655C'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [b2].nes
	['0422AB933D32C6FE39649C67B64AAE50E32ACFAF'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [o1].nes
	['7728A67FA7A8E6746E82C3591E56A3F971182275'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [o1][T+Eng1.0_AGTP].nes
	['E3B33700FE0B69F0F5D0B827AAC9EC0F9391BD66'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [p1].nes
	['E7E6C7976E54F1A91B504BE40DA915132D72130A'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [T+Chi].nes
	['3BA422AB145BE22F72836DF76BCA3844ACB6422B'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [T+Eng1.0_AGTP].nes
	['CAFCC9228DDB3C087DC393D01C8341DCC2F01588'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J) [T-Eng.9_AGTP].nes
	['108118F41E4CD9E375249D3A3B37A7360024FE64'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (J).nes
	['FB51875D1FF4B0DEEE97E967E6434FF514F3C2F2'] = 'mm2nes', -- Rockman 2 - Dr. Wily no Nazo (Japan).nes - NOINTRO
	-- Mega Man 3 NES rom hashes
	['4B672D13BC9B5C4267830E2B24A4CD2ACB116FAA'] = 'mm3nes', -- Mega Man 3 (Europe) (Rev A).nes
	['4651BEC411550C237DC38950A649A22430ECB169'] = 'mm3nes', -- Mega Man 3 (PC10) [!].nes
	['70B2A67921BF2133051ED987BAD98E427970F165'] = 'mm3nes', -- Mega Man 3 (U) (Prototype) [!].nes
	['53197445E137E47A73FD4876B87E288ED0FED5C6'] = 'mm3nes', -- Mega Man 3 (U) [!].nes
	['0728DB6B8AABF7E525D930A05929CAA1891588D0'] = 'mm3nes', -- ??
	['B670B3236BB60C454E3C8712B15A08DB1E31CAA3'] = 'mm3nes', -- Mega Man 3 (U) [b1].nes
	['BB8570022A40778C1410C10167203F5E9786799D'] = 'mm3nes', -- Mega Man 3 (U) [b2].nes
	['39B25C7E907C27E0801FB7AEEF193244979FD9AF'] = 'mm3nes', -- Mega Man 3 (U) [b3].nes
	['CDF9BFAFCF77CA78936D736CED8B2E54372D8F86'] = 'mm3nes', -- Mega Man 3 (U) [o1].nes
	['5AAD27B4ADA65C4189065072A24F1FE06A4B68BB'] = 'mm3nes', -- Mega Man 3 (U) [T+FreBeta(w-BossNames)_Generation IX].nes
	['0BC52C6AA273519FF04E8BFA10CF3BD02DA24F40'] = 'mm3nes', -- Mega Man 3 (U) [T+FreBeta_Generation IX].nes
	['7E9AD0FF44209E05FBC4059C00E3355D20701AE6'] = 'mm3nes', -- Mega Man 3 (U) [T+Fre_Sstrad].nes
	['07517C8C3014A73050E304B306F0995A2D1934C3'] = 'mm3nes', -- Mega Man 3 (U) [T+Ita1.0_Vecna].nes
	['80CEC685078E746D9577930391FC345B83D88DC2'] = 'mm3nes', -- Mega Man 3 (U) [T+Por].nes
	['8D39A8643187220656F01AFA3FF698C3CB176C83'] = 'mm3nes', -- Mega Man 3 (U) [T+Spa90%_PaladinKnights].nes
	['231B5E514C254B222EC6F74D7C74F4959A4D431E'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [b1].nes
	['030874B201B8A06BA215141093CFAC1C9B9E880D'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [h1].nes
	['6E42C75706A331D961A57F270DE0D14AC45CC29C'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [hFFE][b1].nes
	['104D7C8BAE79670A0C05DF9994D3FC6E52086114'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [o1].nes
	['CF11E88D6DA9F6EAC660F8858A7F5F4B28E442CB'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [p1].nes
	['36B501FFE32934BB83E23E6860C1B6C71E40A8E1'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [p1][b1].nes
	['ECDCABB538AF31E01E8362E3FA7FA3436A3D1B94'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [p1][b2].nes
	['C359DA8F3753B635FBE7550327DA7D15CA17BE17'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [p1][b3].nes
	['F72B44B4648E62C7DE13F9FD5AB41B03AFFBA109'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [p1][b4].nes
	['9B8A6E2E234DEB0697A8172C83AC90DEB3B209EA'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J).nes
	['E82C532DE36C6A5DEAF08C6248AEA434C4D8A85A'] = 'mm3nes', -- Rockman 3 - Dr. Wily no Saigo! (J) [!].nes - GOODNES 3.14
	-- Mega Man 4 NES rom hashes
	['BD607BE30AF655A2F171A45E1588B5EEC45E2FAE'] = 'mm4nes', -- Mega Man 4 (E).nes
	['2AE9A049DAFC8C7577584B4B9256F7EF8932B29C'] = 'mm4nes', -- Mega Man 4 (U) [!].nes
	['F4E919FF86C82E55532F203F93047965D0602857'] = 'mm4nes', -- Mega Man 4 (U) [b1].nes
	['C68061875BBC5FD2E39E897612BDD5B0C0D0DDF0'] = 'mm4nes', -- Mega Man 4 (U) [b2].nes
	['140CBE9BBBE5CE075142BA58E85F21F59077B503'] = 'mm4nes', -- Mega Man 4 (U) [b3].nes
	['D544224ECE14A33EFB93C9C0C79C5653650653C9'] = 'mm4nes', -- Mega Man 4 (U) [b4].nes
	['9B5FC2A0195DAF6D0F495F385D21A7779B396533'] = 'mm4nes', -- Mega Man 4 (U) [o1].nes
	['BB97CB32E9731B3A67DA10C7ED33CB7540068A79'] = 'mm4nes', -- Mega Man 4 (U) [T+FreBetaBossNames_Generation IX].nes
	['01FE30810C29E288EEB2DAECB93DA35DC715683B'] = 'mm4nes', -- Mega Man 4 (U) [T+Fre_Shock].nes
	['34E31E728EB01A42EA7C45A757E06A7DB5E3F339'] = 'mm4nes', -- Mega Man 4 (U) [T+Ita1.0_Vecna].nes
	['A03405EC28D97B71445B5F9FDC8E0068973DC7C3'] = 'mm4nes', -- Mega Man 4 (U) [T+Spa100%_Chilensis].nes
	['B8C3EE6D7BE7F0807644D10CACA3C8BC54519CEB'] = 'mm4nes', -- Mega Man 4 (U) [T+Spa_Djt].nes
	['3B76DD7FCF1C7C2DBB475680B778C4136DAB7230'] = 'mm4nes', -- Mega Man 4 (U) [T-FreBeta_Generation IX].nes
	['B098BF509E2E6A4144FB592DFDEAD9E2DA6DE487'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [a1].nes
	['2D3FC452815B41D6781EC908E0A8FDF2437ED866'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [b1].nes
	['AB35FEBEF989E89BFC9F7E014F8FC674E08D1726'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [b2].nes
	['CAA7CAB393B87990EA7475047F6652509992529E'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [b3].nes
	['781EF34750A870D1539C0FA9F37F7069FB5FF39B'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [b4].nes
	['A1CB0F958EAFA1FD4C38974EEBDA122A0E28E025'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J) [o1].nes
	['C33C6FA5B0A5B010AF6B38CBD22252A595500A5A'] = 'mm4nes', -- Rockman 4 - Aratanaru Yabou!! (J).nes
	-- Mega Man 5 NES rom hashes
	['705BE5641C02B040FEF9F724F61D3DD2F0EF7C98'] = 'mm5nes', -- Mega Man 5 (Europe).nes
	['0A28FE72A02D8C3D71775F4D97C649E247E2A24B'] = 'mm5nes', -- Mega Man 5 (U) [b1].nes
	['42588659DF28C72B25E654A7A599FC4F9DFE5DDE'] = 'mm5nes', -- Mega Man 5 (U) [b2].nes
	['6476C9404ACA29BF011F5419CF3672070D70D342'] = 'mm5nes', -- Mega Man 5 (U) [b3].nes
	['17F81D350B4FD657102F78827B1B10D499F6E600'] = 'mm5nes', -- Mega Man 5 (U) [b4].nes
	['19EAC3E489660EB1EA3AA8BE4FEEB5C53364E94D'] = 'mm5nes', -- Mega Man 5 (U) [b5].nes
	['2B1B4ED94EBC32314930D646F576CBD708C4FAB8'] = 'mm5nes', -- Mega Man 5 (U) [b6].nes
	['7C5802E3ED945064E0132F539E243241688D9ABB'] = 'mm5nes', -- Mega Man 5 (U) [b7].nes
	['338C5A871DA81A302EB84319D5416BFFC08FAA7B'] = 'mm5nes', -- Mega Man 5 (U) [h1].nes
	['3CF7F6329FF510DC42CD6AC07060A0B185BFB9F7'] = 'mm5nes', -- Mega Man 5 (U) [o1].nes
	['3E1E5AB6A3A447F5D2C3455B008D53DB85F24C97'] = 'mm5nes', -- Mega Man 5 (U) [T+FreBetaBossNames_Generation IX].nes
	['E43A356C6166550CF0C2E66AAA9F235DA69D6E6A'] = 'mm5nes', -- Mega Man 5 (U) [T+Fre_Nanard].nes
	['A2B370AA820B06A5CA37070A78E49F1EA82B4055'] = 'mm5nes', -- Mega Man 5 (U) [T+Ita1.0_Vecna].nes
	['6C281843BE12690F97E88D89A1DC426CAD01798F'] = 'mm5nes', -- Mega Man 5 (U) [T+Nor0.90a_Just4fun].nes
	['B715974F7462B8C34C17EDEB83FBA8307273B183'] = 'mm5nes', -- Mega Man 5 (U) [T+Spa_Chilensis].nes
	['94A29041A587CADD80A5117B7F420333F02B8003'] = 'mm5nes', -- Mega Man 5 (U) [T-FreBeta_Generation IX].nes
	['1748E9B6ECFF0C01DD14ECC7A48575E74F88B778'] = 'mm5nes', -- Mega Man 5 (U).nes
	['EB9CF42546D82DEC4786B9008032E9019085E7DF'] = 'mm5nes', -- Rockman 5 - Blues no Wana! (J) [b1].nes
	['E9A22F737235857B01BE6DB3C10259565AFDDF49'] = 'mm5nes', -- Rockman 5 - Blues no Wana! (J) [o1].nes
	['0FC06CE52BBB65F6019E2FA3553A9C1FC60CC201'] = 'mm5nes', -- Rockman 5 - Blues no Wana! (J).nes
	-- Mega Man 6 NES rom hashes
	['1992CB26421BD13B5770244767F4F49F1E85410D'] = 'mm6nes', -- Mega Man 6 (U) [b1].nes
	['A4BF996782528C3D810966CA7F390EFBC30D909B'] = 'mm6nes', -- Mega Man 6 (U) [b1][T+Swe1.0_TheTranslator].nes
	['E9DF03297E1D43986F568BF6617B2C1B32F4336D'] = 'mm6nes', -- Mega Man 6 (U) [b2].nes
	['D9347FFAE8E1C6921FAB27BFE48D640990C6AC24'] = 'mm6nes', -- Mega Man 6 (U) [b3].nes
	['0C9BB9EDF8BE980A862CD9DCE3F89BC5724F0AE0'] = 'mm6nes', -- Mega Man 6 (U) [b4].nes
	['DF6878829444F0B9BACB5C84866B9BB16E737B77'] = 'mm6nes', -- Mega Man 6 (U) [b5].nes
	['0FB233A2262028F6F6460932989BC6BFBC7EE51E'] = 'mm6nes', -- Mega Man 6 (U) [b6].nes
	['0B3ECE5187DE5EDD45D7D0BA814CE5F046D13EBD'] = 'mm6nes', -- Mega Man 6 (U) [b7].nes
	['B4462E4A741047A85E30E97DF86CE7E8CCCAAA6A'] = 'mm6nes', -- Mega Man 6 (U) [b8].nes
	['9B26586C1F562DF2FD91FD5D8D6743D6D8F07CCB'] = 'mm6nes', -- Mega Man 6 (U) [h1].nes
	['B6A4E916815C91E95B7474467D487861CC2693B9'] = 'mm6nes', -- Mega Man 6 (U) [o1].nes
	['A17F720294AC3CA0945BC034B9127A7F2936BD04'] = 'mm6nes', -- Mega Man 6 (U) [T+FreBeta2BossNames_Generation IX].nes
	['733BB196D5DC2E68EFA1D26001D36A53233101B2'] = 'mm6nes', -- Mega Man 6 (U) [T+Fre].nes
	['4EE2F554F2DFBB6E5496E3AE32997C1D75F95B1A'] = 'mm6nes', -- Mega Man 6 (U) [T+Fre_Nanard].nes
	['F786DD6097E068B3B3F3AF28E84BE607415BBAAD'] = 'mm6nes', -- Mega Man 6 (U) [T+Ger1.01].nes
	['376A2AD0B744542585FDAF7CE67FE45458931124'] = 'mm6nes', -- Mega Man 6 (U) [T+Ita1.0_Vecna].nes
	['E1B002B786B8AFAE2A4AC2C6AAF926F92574D51A'] = 'mm6nes', -- Mega Man 6 (U) [T+Nor1.00_Just4Fun].nes
	['E63BF1959C13E514D701C7E77342743C528D8797'] = 'mm6nes', -- Mega Man 6 (U) [T+Por].nes
	['B99ED19876B89004135D4207C098FC3BD9698E4F'] = 'mm6nes', -- Mega Man 6 (U) [T+Spa_Djt].nes
	['DFF827693E1BEF6D78026F6D1C3DC87EDA4FEBC7'] = 'mm6nes', -- Mega Man 6 (U) [T+Swe1.0_TheTranslator].nes
	['EE4B84CDEA7FAFE3E17FEF540DC6DC398D4FBEE5'] = 'mm6nes', -- Mega Man 6 (U) [T-FreBeta2_Generation IX].nes
	['3CD17C90A4577D426DCA7DDFA4A9AF4980D6EAE0'] = 'mm6nes', -- Mega Man 6 (U) [T-FreBetaBossNames_Generation IX].nes
	['0EFFE2E3E2B09BA3AD5E4225ACB6988B9BF829EF'] = 'mm6nes', -- Mega Man 6 (U) [T-FreBeta_Generation IX].nes
	['32774F6A0982534272679AC424C4191F1BE5F689'] = 'mm6nes', -- Mega Man 6 (U).nes
	['6E0C56F13188E967427B656D5DCAFE4884C6D518'] = 'mm6nes', -- Rockman 6 - Shijou Saidai no Tatakai!! (J) [o1].nes
	['DB303209E934BD1111C3FB1CF253F43F4DE0AB73'] = 'mm6nes', -- Rockman 6 - Shijou Saidai no Tatakai!! (J) [o1][T+Chi].nes
	['17CE145137DD6D3FFEAE3FBBC3E47E4D3D69E6B2'] = 'mm6nes', -- Rockman 6 - Shijou Saidai no Tatakai!! (J) [T+Chi].nes
	['DD95FAF3FC64BFAF8B8FE2160F2721E1900E1361'] = 'mm6nes', -- Rockman 6 - Shijou Saidai no Tatakai!! (J).nes
	-- Mega Man 7 SNES rom hashes
	['D11E3793F46F2B1BD00150438D394E4B13489A14'] = 'mm7snes', -- Mega Man VII (E).smc
	['DFF515C3634807B09DD3D53AC86BD3D2A6F87521'] = 'mm7snes', -- Mega Man VII (U) [T+Fre_Genius].smc
	['21680D62F6D078DDDC4374FD5DEA33CAC5417CA8'] = 'mm7snes', -- Mega Man VII (U) [T+Ger198_Reaper].smc
	['E8F566917E952CF66B7072F82196541356298BFE'] = 'mm7snes', -- Mega Man VII (U) [T+Ita].smc
	['5E7B0D08E080CDD66D783954DA49EEEEA5BAB641'] = 'mm7snes', -- Mega Man VII (U) [T+Por].smc
	['88707FC246345FBFCAB7212652B711DC075F4C8D'] = 'mm7snes', -- Mega Man VII (U) [T+Spa100_Sayans].smc
	['7B66FF57560EF016103CCE5629AF7DF8914956F7'] = 'mm7snes', -- Mega Man VII (U) [T+Spa100_Sinister].smc
	['E5391AE50982E07C68AAF105C490A585944273A6'] = 'mm7snes', -- Mega Man VII (U) [T+Spa100_Tanero].smc
	['5F49B65345604DA0EA07B6F9E243F75B3BF65D5B'] = 'mm7snes', -- Mega Man VII (U) [t1].smc
	['10B017FF2E9BF241ED23F1C302E11F023AC60775'] = 'mm7snes', -- Mega Man VII (U) [t2].smc
	['DAE01650C00491A5FB767206D0BB5FC0C163FD51'] = 'mm7snes', -- Mega Man VII (U) [t3].smc
	['6E7C9C9DD397F771303EE4AEC29D106B9F86C832'] = 'mm7snes', -- Mega Man VII (U).smc
	['195A40598CCC79ED99BC6B266CF955701461AD2B'] = 'mm7snes', -- Rockman 7 - Shukumei no Taiketsu! (J) [f1].smc
	['77CDF229DBADDF996F37F0399473C248ECDA730D'] = 'mm7snes', -- Rockman 7 - Shukumei no Taiketsu! (J) [f2].smc
	['30C00AEBA9F3607F593995A789742F6569E5289F'] = 'mm7snes', -- Rockman 7 - Shukumei no Taiketsu! (J) [f3].smc
	['91DA21BE9CFE16391ACA87C35597BB3BA401F101'] = 'mm7snes', -- Rockman 7 - Shukumei no Taiketsu! (J) [f4].smc
	['72226D8A50C6EEEFD9EEB7F93AE11E085465754A'] = 'mm7snes', -- Rockman 7 - Shukumei no Taiketsu! (J) [t1].smc
	['CA1610103BFD310A64AA436B9636B721288C0FB6'] = 'mm7snes', -- Rockman 7 - Shukumei no Taiketsu! (J) [t2].smc
	['84B58F0B3C525767114227BDC1C9D3FB48856596'] = 'mm7snes', -- Rockman 7 - Shukumei no Taiketsu! (J) [t3].smc
	['A907F7ECE8A8D89126C466079712282D675486EF'] = 'mm7snes', -- Rockman 7 - Shukumei no Taiketsu! (J).smc
	-- Mega Man 8 PSX rom hashes
	['CA2E63F7'] = 'mm8psx',
	-- Mega Man X SNES rom hashes
	['8A32570FAD3BFC92C0508C88022FB20412DD7BED'] = 'mmx1', -- Mega Man X (E).smc
	['449A00631208FBCC8D58209E66D0D488674B7FB1'] = 'mmx1', -- Mega Man X (U) (V1.0) [!].smc
	['E8921E243394B03382C03A6A08054F490C8F3DC8'] = 'mmx1', -- Mega Man X (U) (V1.0) [f1].smc
	['13D3730F56E5F1365869C9D933F956592DBAE2CC'] = 'mmx1', -- Mega Man X (U) (V1.0) [f1][T+Por].smc
	['BD00A9799A5B50782334F8165BAD28C215C64FCE'] = 'mmx1', -- Mega Man X (U) (V1.0) [f2].smc
	['241E79805B679907004F2023A100DADECB9EC2CC'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Catalan].smc
	['0A66ACAE238D3CD5D237AD0F2614F253558D2B0B'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Fre.1_BessaB].smc
	['4AA221EB70DF6E0140506DE3FB4EAE72CA762248'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Fre].smc
	['1E1E55CC3B2A012F97ABB3FEA42F5E5766B1C42E'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Ger100%_TranX].smc
	['EA77D11BAFBB73B72CE7789910DD7BA70952A585'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Ita1.10_Clomax].smc
	['7CC9BB9FBC3AC9CDA039D18FF3E05D8E15AB764B'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Por].smc
	['F219D1EF0CBE49780B0D6C332A99B4AA66924AA0'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Spa099_Ereza].smc
	['EFEA5FBE9B161219175CCBFF4B41BCED5E470B5F'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Spa100_Tanero].smc
	['ADBBC837DB8A98071C4AE1867B2CB878A2BA8EC0'] = 'mmx1', -- Mega Man X (U) (V1.0) [T+Spa100_Windfish].smc
	['CA578B24C7E4E37637F6093905F861643D234CB5'] = 'mmx1', -- Mega Man X (U) (V1.0) [T-Ita].smc
	['56A26EDC7234E93921AF3D8A04EABE5916008DED'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Catalan].smc
	['E223EC424D5936F3B884265D7BC865D43DE58A7F'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Ger.99_g-trans(sephiroth)].smc
	['16A0246A5B769DB68B07F8FE7244ACBA18938917'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Ita1.10_Clomax].smc
	['A521187ADB03B37B5B5FC57BE0D65AED9FE7840D'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Spa099_Ereza].smc
	['17B58BAC499ECBC8A92B8A346C6C12DDB8A4DABE'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Spa100%_Windfish].smc
	['7433124B6BDE8B002FA6493F29C56C01AC382D7A'] = 'mmx1', -- Mega Man X (U) (V1.1) [T+Spa100_Tanero].smc
	['C65216760BA99178100A10D98457CF11496C2097'] = 'mmx1', -- Mega Man X (U) (V1.1).smc
	['86C18BA1FC762B6D0BCDEE7314A29B5C97CAC082'] = 'mmx1', -- Rockman X (J) (V1.0) [!].smc
	['870F1FADBB8D2BEC1C2B73B9635473BC58C6415E'] = 'mmx1', -- Rockman X (J) (V1.0) [h1].smc
	['03F8F99D27874465F8D3E5EC9628927AC5BE6FAE'] = 'mmx1', -- Rockman X (J) (V1.1).smc
	-- Mega Man X2 SNES rom hashes
	['5C767285DA713DE2BC883A6291D32ADC9B2D13FA'] = 'mmx2', -- Mega Man X 2 (E) [!].smc
	['E5893F23A7C04036EF3D54E09B98FD1C983362BA'] = 'mmx2', -- Mega Man X 2 (E) [b1].smc
	['FD3BFBEF32DBB01DA2BA11CD59AD773D29A04960'] = 'mmx2', -- Mega Man X 2 (U) [b1].smc
	['E3160744BE80529152247379FB1BDBAA83569C38'] = 'mmx2', -- Mega Man X 2 (U) [o1].smc
	['BDB22B8DCB1D05BD0AE0637E90C0761F213D3631'] = 'mmx2', -- Mega Man X 2 (U) [o1][T+Ger100%_alemanic].smc
	['FB09794E161425A6D614CE1ECA84247AC895CFBD'] = 'mmx2', -- Mega Man X 2 (U) [o1][T+Ger100%_TranX].smc
	['36A332D0FB8759B4E1D98EFDB9757E22036ABB67'] = 'mmx2', -- Mega Man X 2 (U) [T+Ger100%_alemanic].smc
	['84ED9FFD6ADE34715B48D56B163889BF527923A6'] = 'mmx2', -- Mega Man X 2 (U) [T+Ita091_Clomax].smc
	['CD3E544C46CBDE55FD93684F7ABD5CCE9BDD9667'] = 'mmx2', -- Mega Man X 2 (U) [T+Por].smc
	['6E21A0A090C40C5E952F083D703A80F69BD97BF8'] = 'mmx2', -- Mega Man X 2 (U) [T+Spa050_Pkt].smc
	['A974F8940088B1D49E85EC42129C32B420AD688E'] = 'mmx2', -- Mega Man X 2 (U) [T+Spa101_Ereza].smc
	['637079014421563283CDED6AEAA0604597B2E33C'] = 'mmx2', -- Mega Man X 2 (U).smc
	['1A0529685D1AF13F5AF209A8A297832AE433DBCD'] = 'mmx2', -- Rockman X 2 (J) [o1].smc
	['34DC37C8A1905EC5631FA666EBA84BB78F9C5BDF'] = 'mmx2', -- Rockman X 2 (J).smc
	-- Mega Man X3 SNES rom hashes
	['69A11324AEB57D005800771D6147603D5479B282'] = 'mmx3', -- Mega Man X 3 (E) [!].smc
	['F320F4C9FC9E5CC866D899FED8B300111E41D2D7'] = 'mmx3', -- Mega Man X 3 (E) [b1].smc
	['E73BED2D65297F3685F1B74287FCA4D42602BF3B'] = 'mmx3', -- Mega Man X 3 (U) [T+Fre].smc
	['0A4438B210EE705F8803CF466A382827A43CD84E'] = 'mmx3', -- Mega Man X 3 (U) [T+Ger100%_TranX].smc
	['C058FF30989B8BB8B475BEEDB797DD7841F72ECC'] = 'mmx3', -- Mega Man X 3 (U) [T+Ita].smc
	['A35EE942D8F7B5893E0BCF2426E439836A4AD27D'] = 'mmx3', -- Mega Man X 3 (U) [T+Por].smc
	['7DCD0FD1EF2CBED1EBF56C3999B37B8C5DF0C69F'] = 'mmx3', -- Mega Man X 3 (U) [T+Spa100_Tanero].smc
	['BF8CE9F1EF4756AE4091D938AC6657DD3EFFB769'] = 'mmx3', -- Mega Man X 3 (U) [T+Swe1.0_GCT].smc
	['B226F7EC59283B05C1E276E2F433893F45027CAC'] = 'mmx3', -- Mega Man X 3 (U).smc
	['8E0156FC7D6AF6F36B08A5E399C0284C6C5D81B8'] = 'mmx3', -- Rockman X 3 (J).smc
	-- Mega Man X3 PSX rom hashes
	['30776FC9'] = 'mmx3psx-eu', -- Mega Man X3 (Europe)
	['470B67F2'] = 'mmx3psx-jp', -- Rockman X3 (Japan)
	-- Mega Man X4 PSX rom hashes
	['314E06A8'] = 'mmx4psx-us',
	-- Mega Man X5 PSX rom hashes
	['1C64D6EA'] = 'mmx5psx-us',
	['614E644C'] = 'mmx5psx-us', -- Mega Man X5 (USA) [Improvement Project Addendum v1.5].xdelta
	-- Mega Man X6 PSX rom hashes
	['24454CEE'] = 'mmx6psx-us', -- Mega Man X6 (USA) (v1.0)
	['F063F536'] = 'mmx6psx-us', -- Mega Man X6 (USA) (v1.1)
	['A4F84BEC'] = 'mmx6psx-jp', -- Rockman X6 (Japan)
	-- Mega Man 1 GB rom hashes
	['2CFAEE20EA657F57CDCF0C7159B88D1339C9651D'] = 'mm1gb', -- Megaman (U) [T+Fre_terminus].gb
	['5D598A14A2A35AF64FBB08828EB1D425472624F3'] = 'mm1gb', -- Megaman (U) [T+Por_Emuboarding].gb
	['8C3A12B2E42EB5549917F8B1474DA51E5DAC6E67'] = 'mm1gb', -- Megaman (U) [T+Por_TraduROM].gb
	['11255A24344E9FED53B8F1F6F894D21E161A0D5E'] = 'mm1gb', -- Megaman - Dr. Wily's Revenge (E) [!].gb
	['277EDB3C844E812BA4B3EB9A96C9C30414541858'] = 'mm1gb', -- Megaman - Dr. Wily's Revenge (U) [!].gb
	['4C9A556856CA771BE4AD05A99A16022B44CE6D8F'] = 'mm1gb', -- Megaman - Dr. Wily's Revenge (U) [b1].gb
	['8C62103D62A55B7DE6292CA1032ABF89AEAEE32A'] = 'mm1gb', -- Megaman - Dr. Wily's Revenge (U) [b2].gb
	['0A22699AED2537F7F53E85C7745ADF1AF197A38D'] = 'mm1gb', -- Megaman - Dr. Wily's Revenge (U) [T+Fre1.0_Sstrad Translations].gb
	['37ECB7D40282E1BC463C8FA24310397D5D571823'] = 'mm1gb', -- Megaman - Dr. Wily's Revenge (U) [T+Ger1.00_Reaper].gb
	['91318509322FBCD1E1E05B98243227377D8F31D5'] = 'mm1gb', -- Rockman World (J) [!].gb
	['09705EA1D1831CCD6192F92D3807D5FC45856CB7'] = 'mm1gb', -- Rockman World (J) [t1].gb
	-- Mega Man 2 GB rom hashes
	['D19993A4630E7F9450FF6469115F4095F6F29667'] = 'mm2gb', -- Megaman II (E) [!].gb
	['A90AE33F72AABF30F16E0BEC3B180F6A02BC9A96'] = 'mm2gb', -- Megaman II (E) [b1].gb
	['D466EA7B48A93A14FAE536A515638F87FBDDCCBA'] = 'mm2gb', -- Megaman II (E) [b2].gb
	['2E6819CAA7252D3314CE984F9AB1350EA7D2BE81'] = 'mm2gb', -- Megaman II (E) [o1].gb
	['8A0C9E7A6D67D6071EDE4A6A02EE35CD73E73DF7'] = 'mm2gb', -- Megaman II (E) [T+Ger1.00_Reaper].gb
	['CD6DBA35EB10503E42BF22D5905657A7DBEE76DE'] = 'mm2gb', -- Megaman II (U) (Dr. Wily Fix) [f1].gb
	['334F1A93346D55E1BE2967F0AF952E37AA52FCA7'] = 'mm2gb', -- Megaman II (U) [!].gb
	['4E86A8C39D2FD181E69D6887064A6BE054D962C6'] = 'mm2gb', -- Megaman II (U) [T+Fre_terminus].gb
	['A3269A85F56A8B5182D4EEE6FBF7287CC836ACCD'] = 'mm2gb', -- Rockman World 2 (J) [t1].gb
	['5D35BAA2FADD07796ED8B441F82ED5B136A999C7'] = 'mm2gb', -- Rockman World 2 (J).gb
	-- Mega Man 3 GB rom hashes
	['ECADBC9E273E4D99CCD87F98BBBD912AEC43C077'] = 'mm3gb', -- Megaman III (E) [!].gb
	['01E08F19C4AA0B84EAD6FA3DF057ED0065DE6F65'] = 'mm3gb', -- Megaman III (E) [T+Ger1.00_Reaper].gb
	['B0F219276AF34460D47AE7563C684C8BE86FA7A9'] = 'mm3gb', -- Megaman III (E) [t1].gb
	['57347305AB297DAA4332564623C4A098E6DBB1A3'] = 'mm3gb', -- Megaman III (U) [!].gb
	['1364DBA60F8A6391598F8CA4AE852CA0E286DBEF'] = 'mm3gb', -- Megaman III (U) [b1].gb
	['8931B418B48921F80DA0B5A73C162A60BC9C816F'] = 'mm3gb', -- Megaman III (U) [b2].gb
	['5A3154BACE23F41BD998F3795E2F691D9B7BAEA0'] = 'mm3gb', -- Megaman III (U) [b3].gb
	['6D233AFEBC1E82E6D72B675FCA8EB3BC8FB1D2CA'] = 'mm3gb', -- Megaman III (U) [T+Fre_terminus].gb
	['A1FF192436BCBFC73CB58E494976B0EA6CD45D16'] = 'mm3gb', -- Megaman III (U) [t1].gb
	['3C63FEE91F397CD83EEBB9BFFB414182635A6AF6'] = 'mm3gb', -- Megaman III (U) [t2].gb
	['41808B9518F912DCF7B482036BBA1495E4023A76'] = 'mm3gb', -- Rockman World 3 (J) [t1].gb
	['201ABC73CF669F71A477A431D387518F4B488C1F'] = 'mm3gb', -- Rockman World 3 (J).gb
	-- Mega Man 4 GB rom hashes
	['A15A05593BF9BDDDB5826B148E25182E7B90F268'] = 'mm4gb', -- Megaman IV (E) [b1].gb
	['D77B4904F958C9AE7010B49A5AB3AB2088F5B95F'] = 'mm4gb', -- Megaman IV (E) [b2].gb
	['EBCE56D23A1F19C85E09FD2E31AC3A165C685C96'] = 'mm4gb', -- Megaman IV (E) [T+Ger1.00_Reaper].gb
	['6B68BBC1ECD411D7DF4A3868D3C656193ED85B6B'] = 'mm4gb', -- Megaman IV (E) [T+Spa1.0_Lukas].gb
	['F4F7BAAAEC4BFDE95003AC52FDFE95ECCDAB569C'] = 'mm4gb', -- Megaman IV (E).gb
	['6F0901DB2B5DCAACE0215C0ABDC21A914FA21B65'] = 'mm4gb', -- Megaman IV (U) [!].gb
	['00F654965AA14A6D291CA4929C694CC0CA728F63'] = 'mm4gb', -- Megaman IV (U) [T+Fre_terminus].gb
	['ACD209AB4B420FBBA984A47DC115D40A1320D310'] = 'mm4gb', -- Rockman World 4 (J) [b1].gb
	['D004ACCED082ADB0DD18AC318F80EE6FEB75333E'] = 'mm4gb', -- Rockman World 4 (J) [b2].gb
	['DD9F33DD2C88108A5B8879BF1550F11926A50A59'] = 'mm4gb', -- Rockman World 4 (J) [t1].gb
	['DD33E9E4B8F389C0336F27CA4CFE489A1FB1968E'] = 'mm4gb', -- Rockman World 4 (J) [t2].gb
	['D0835A9C5DC7FCA4DA4D62A9BC244525ECD76EE7'] = 'mm4gb', -- Rockman World 4 (J).gb
	-- Mega Man 5 GB rom hashes
	['1A377BB0571BBE48A58B5006CCB02046EC64B076'] = 'mm5gb', -- Megaman V (E) [S].gb
	['75FAD1CB1B6E27E0438095069537412466F43457'] = 'mm5gb', -- Megaman V (E) [S][b1].gb
	['278B8594884231AB80376646CD7D8A3817E396E7'] = 'mm5gb', -- Megaman V (E) [S][T+Spa_lukas].gb
	['9A7DA0E4D3F49E4A0B94E85CD64E28A687D81260'] = 'mm5gb', -- Megaman V (U) [S][!].gb
	['901D05B172395E04799CD10EFBB1214647863D9C'] = 'mm5gb', -- Megaman V (U) [S][T+Fre_lukas].gb
	['A969781B2097BB8A22938EB8E6832EE924C3096F'] = 'mm5gb', -- Megaman V (U) [S][T+Spa1.0_Lukas].gb
	['F3904D2069A888E45CA44878461324E4C2A8B03D'] = 'mm5gb', -- Rockman World 5 (J) [S].gb
	['9EE67E66412F1FF6C7E71D9DEBE5AC62978CE3C7'] = 'mm5gb', -- Rockman World 5 (J) [S][T+Eng].gb
	['94B19DE4425D1F5D0B74CE41348B4246E7A41E85'] = 'mm5gb', -- Rockman World 5 (J) [S][T-Eng].gb
	['EE7AD85273983A63BC32B011617D13E1EA879463'] = 'mm5gb', -- Rockman World 5 (J) [S][t1].gb
	-- Mega Man Xtreme GBC rom hashes
	['C877449BA0889FDCACF23C49B0611D0CA57283C5'] = 'mmx1gbc', -- Mega Man Xtreme (U) [C][!].gbc
	['CB1811AC8969F6B683DF954B57138DD28EBB40FF'] = 'mmx2gbc', -- Mega Man Xtreme 2 (U) [C][!].gbc
	-- Rockman & Forte SNES rom hashes
	['111C3514C483F59C00B3AED4E23CE72D44A1EC2F'] = 'rm&f', -- Rockman & Forte (J) [h1].smc
	['5172400A5B1D0787F4F4CE76609598147BF8ABBD'] = 'rm&f', -- Rockman & Forte (J) [T+Eng1.00-MMB_AGTP].smc
	['20332C7EEAE8D4D740EEDEFCB2671455C1CC4850'] = 'rm&f', -- Rockman & Forte (J) [T+Eng1.00-RMF_AGTP].smc
	['CB28F9A32C10EFBD1EDAA9AAC0CC704456539DAF'] = 'rm&f', -- Rockman & Forte (J) [T+Por].smc
	['49ACC34CE955EBA27ABAD588E28DDD804E6F2C4D'] = 'rm&f', -- Rockman & Forte (J) [T-Eng99%].smc
	['E98789CCC644A737724F3000F8EB4161E1F59731'] = 'rm&f', -- Rockman & Forte (J) [T-Por].smc
	['5C6B0679C1A6A040F969A5D08987AA4ECDDF14A1'] = 'rm&f', -- Rockman & Forte (J).smc
	['BCD2FC38B4E4BF6B811B00301F349E85CA48FE1A'] = 'rm&f', -- Rockman & Forte (Japan).sfc
	-- Mega Man Wily Wars GEN rom hashes
	['3A69E358628E49B6744C9D2C07F874D6'] = 'mmwwgen', -- Mega Man - The Wily Wars (E) [f1].bin
	['B47C78AF48D843C9D52FF9DEE1CBE98C'] = 'mmwwgen', -- Mega Man - The Wily Wars (E) [f2].bin
	['BB891AEC8A7DFE6164033F57AF2025BD'] = 'mmwwgen', -- Mega Man - The Wily Wars (E).bin
	['520D081A450B5E9F127369E6EC1BE43E'] = 'mmwwgen', -- Rockman Megaworld (J) [!].bin
	['7A25E5249C0A406F20F76BEF45DC3202'] = 'mmwwgen', -- Rockman Megaworld (J) [a1][!].bin
	['9501EAB8C7BB3FB097EE1699B8132BC3'] = 'mmwwgen', -- Rockman Megaworld (J) [b1].bin
	['04130F704DC564F7BFDF3A12992B5FD2'] = 'mmwwgen', -- Rockman Megaworld (J) [b2].bin
	['4C26D10F82D5B5B9E6526BE1E8C5446B'] = 'mmwwgen', -- Rockman Megaworld (J) [b3].bin
	['6C2A6A01CB0F46186AB93766DD430A50'] = 'mmwwgen', -- Rockman Megaworld (J) [f1].bin
	['7FE51160D8055E813245ADD4B1E3DA42'] = 'mmwwgen', -- Rockman Megaworld (J) [h1C].bin
}

local romnames = {
	['Mega Man X4'] = 'mmx4psx-us',
	['Rockman X4'] = 'mmx4psx-jp',
	['Mega Man X5'] = 'mmx5psx-us',
	['Rockman X5'] = 'mmx5psx-jp',
	['Mega Man X6'] = 'mmx6psx-us',
	['Rockman X6'] = 'mmx6psx-jp',
}

function get_game_data()
	local hash = gameinfo.getromhash()
	local name = gameinfo.getromname()

	-- try to just match the rom hash first
	local tag = romhashes[hash]
	if tag ~= nil and gamedata[tag] ~= nil then return gamedata[tag] end

	-- check to see if any of the rom name samples match
	for x,tag in pairs(romnames) do
		if string.find(name, x) and gamedata[tag] ~= nil then
			return gamedata[tag]
		end
	end

	return nil
end

function plugin.on_game_load(data, settings)
	local gamemeta = get_game_data()
	if gamemeta ~= nil then
		local func = gamemeta.func or generic_swap
		shouldSwap = func(gamemeta)
	end
end

function plugin.on_frame(data, settings)
	-- run the check method for each individual game
	if shouldSwap(prevdata) and frames_since_restart > 10 then
		print('swap time ' .. gameinfo.getromname())
		swap_game_delay(3)
	end
end

return plugin
