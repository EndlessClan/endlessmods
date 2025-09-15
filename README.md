# endlessmods

Call of Duty 1 mods

#### Endless CodEvolved

```
set endless_killstreaks 1
set g_awBoost 1
set g_boost_speed 210
set g_boost_power 85
set scr_map_vote 1
```

#### Endless party, use these custom cvars for best experience
Gametype Names: "Cranked", "FreezeTag", "MeatSpin", "Prophunt" (use these names for map rotation or g_gametype cvars)

```
set enable_weather "1"
set scr_nade_ammo "1"
set scr_pissi_ammo "1"
set skipstats "1"
set scr_hns_scorelimit 5
set mspin_speed 5
```

#### Avalanche
Gametype: "avalanche" by indy
Map: "watchout" by zilch

#### AWE 1.3
Read the ReadMe.txt provided, includes the extra cfgs required. Add exec awe.cfg in your main server.cfg

#### Endless Jump
Gametype Name: "jump" (use this name for sv_mapRotation or g_gametype cvars)

### Misc. mods setup

Example `codam/modlist.gsc`:

```
	[[ register ]]( "Hammer's Goodies", codam\HamGoodies::main );
    [[ register ]]( "CoDCommands", codam\coco::main);
	[[ register ]]( "PowerServer",codam\psv_main::main);
    [[ register ]]( "Endless Weapons Menu", codam\menu_weps::main);
    [[ register ]]( "FixW32", codam\FixW32::main );
    [[ register ]]( "FBMod", codam\fbmod::main );
    [[ register ]]( "Sprint", codam\_sprint::main );
    [[ register ]]( "Anti FF", codam\_anti_ff::main );
    [[ register ]]( "CoDaM Server Messages", codam\servermessages::main );
	[[ register ]]( "CoDaM Cvar Limiter", codam\cvarlimit::main );
    [[ register ]]( "CoDaM XP Mod by Indy", codam\_mod_xp::main );
```

~ Indy & Monkey
