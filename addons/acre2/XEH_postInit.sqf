#include "\x\tmf\addons\acre2\script_component.hpp"

//TODO: Enforce better table cleanup (On ADD) in the GUI control
//  - For un-used networks...
//  - When adding from the tree... so that unit/group attrs are correct. Or switch condition to check side/faction/group/unit exhuastively?

GVAR(languagesTable) = [];
//Parse Babel

if (getMissionConfigValue ['TMF_AcreBabelEnabled',false]) then {
    TMF_BabelArray = getMissionConfigValue ["TMF_AcreBabelSettings",[]];
    if (TMF_BabelArray isEqualType "") then { TMF_BabelArray = call compile TMF_BabelArray; };
    {
        _x params ["_langName"];
        private _langId = format["tw_lang%1", _forEachIndex];
        private _entry = [_langId, _langName];
        GVAR(languagesTable) pushBack _entry;
        _entry call acre_api_fnc_babelAddLanguageType;
    } forEach (TMF_BabelArray);
};

// ACRE 2 API functions.

// TODO Allow again
/*if (getMissionConfigValue ['TMF_AcreTerrainLoss',1] != 1) then {
    [(getMissionConfigValue ['TMF_AcreTerrainLoss',1])] call acre_api_fnc_setLossModelScale;
};*/

// OVERRIDE 1TAC
[0.5] call acre_api_fnc_setLossModelScale;
[true] call acre_api_fnc_ignoreAntennaDirection;

if (getMissionConfigValue ['TMF_AcreFullDuplex',false]) then {
    [true] call acre_api_fnc_setFullDuplex;
};
if (!(getMissionConfigValue ['TMF_AcreInterference',true])) then {
    [(getMissionConfigValue ['TMF_AcreInterference',false])] call acre_api_fnc_setInterference;
};
if (getMissionConfigValue ['TMF_AcreAIReveal',true]) then {
    [false] call acre_api_fnc_setRevealToAI;
};



//getMissionConfigValue

/// Parse Radios

if (getMissionConfigValue ['TMF_AcreNetworkEnabled',false]) then {
	if (isNil QGVAR(radioCoreSettings)) then {
		GVAR(radioCoreSettings) = [
			// Array of Radio names, min freq, max freq, freq step, freq spacing between channels (for channel alloication
			[["ACRE_PRC343"],2400,2420,0.01,0.1,"default2"],
			[["ACRE_PRC148","ACRE_PRC152","ACRE_PRC117F"],60,360,0.00625,1,"default"],
            [["ACRE_PRC77"],30,75,0.05,1,"default"]
        ];
	};


	GVAR(radioAddActions) = getMissionConfigValue ['TMF_AcreAddRadioActions', []];
	if (GVAR(radioAddActions) isEqualType "") then { GVAR(radioAddActions) = call compile GVAR(radioAddActions)};
	GVAR(networksWithRadioChannels) = getMissionConfigValue ['TMF_AcreSettings', []];
	if (GVAR(networksWithRadioChannels) isEqualType "") then { GVAR(networksWithRadioChannels) = call compile GVAR(networksWithRadioChannels)};
	if (isServer) then {
		GVAR(channelFrequencyOffsets) = [];
		
		if (!isNil QGVAR(networksWithRadioChannels)) then { 
			private _sharedRadioChannelListing = [];
			{   
				GVAR(channelFrequencyOffsets) pushBack (random 1);
				
				//Loop through the channels and find the shared channels so they also have randomized freqs.
				_x params ["", "_channels"];
				{
					_x params ["_shortName", "", "_radio", "", "_shared"];
					if (_shared) then { // is special channel
						private _coreRadioIdx = -1;
						{
							if (_radio in (_x select 0)) exitWith {
								_coreRadioIdx = _forEachIndex;
							};
						} forEach GVAR(radioCoreSettings);
					
						private _sharedEntry = [_coreRadioIdx, _shortName]; //Radio core ID + Short Channel Name.
						//TODO ensure this works.
						private _sharedIdx = _sharedRadioChannelListing find _sharedEntry;
						if (_sharedIdx == -1) then {
							GVAR(channelFrequencyOffsets) pushBack (random 1); // add default channel split
							_sharedIdx = _sharedRadioChannelListing pushBack _sharedEntry;
						};
					}
				} forEach _channels;
			} forEach GVAR(networksWithRadioChannels);
		};

		publicVariable QGVAR(channelFrequencyOffsets);
	};

	GVAR(giveMissingRadios) = true;

	[{
		if (isNil QGVAR(channelFrequencyOffsets)) exitWith {};
		
		[] call FUNC(createPresets);
		[_this select 1] call CBA_fnc_removePerFrameHandler;
		
	}, 0] call CBA_fnc_addPerFrameHandler;

};


if (hasInterface) then {
	[{
		if (isNull player) exitWith {};
		if (isNil "tmf_acre2_networksCreated") exitWith {}; //Ensure presets are created
		
		[] call FUNC(clientInit);
		[_this select 1] call CBA_fnc_removePerFrameHandler;
	}, 1] call CBA_fnc_addPerFrameHandler;
};