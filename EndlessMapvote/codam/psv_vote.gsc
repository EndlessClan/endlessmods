  //	EndlessMapvote v1.0   //
 //		AUTHOR: Indy		 //
//////////////////////////////

RunMapVote()
{
	// Fallback check
	if (getCvar("psv_mapvote_time") == "" || getCvarInt("psv_mapvote_time") == 0)
		return;

	maps = getMaps();
	// No mapvote if there are only one option
	if (maps.size <= 1)
		return;
		
	wait ( 2 );
	game["state"] = "intermission";
	players = getentarray("player", "classname");
	
	for (i=0; i<players.size; i++)
	{
		player = players[i];
		player.startedvoting = true;	
	}
	
	thread lockplayers();
	wait ( 1 );
	
	game["menu_team"] = "";	

	for (i=0; i<players.size; i++)
	{
		player = players[i];
		player thread mapVote(maps);
	}
	
	thread printWinningMap(players, maps);

	//level.clock destroy();
	clock = newHudElem();
	clock.x = 640-70;
	clock.y = 100;
	clock.horzAlign = "left";
	clock.vertAlign = "top";
	clock setClock(level.VoteTime, level.VoteTime, "hudStopwatch", 48+12, 48+12);

	wait level.VoteTime;
	level notify("voteend");

	map = getWinningMap(players, maps);

	iprintlnbold("^7"+map.nicename+" wins^1!^7");
	
	//Take a breath for players to restart with the map
	wait 1;	
	
	level.votestatus = "started";
	level.mapended = true;	
	level.votestatus = "done";	
	
	gametype = getcvar("g_gametype");
	tmp = "gametype "+map.gametype+" map "+map.name;
	setcvar("sv_mapRotationCurrent", tmp);

	wait ( 3 );
	setcvar("serverstate", "pub");			
	
	codam\psv_main::RebuildWelcome();
	[[ level.gtd_call ]]( "saveAllPlayers" );
	[[ level.gtd_call ]]( "exitLevel", false );
}

PlayerVoteControl( a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
				b0, b1,	b2, b2,	b4, b5,	b6, b7,	b8, b9 )
{	

	return;
}


//Overrides the player vote's - Incompatible with endless mapvote
_cmd_forcevote(args, adminId)
{
	
	return;
}


lockplayers()
{
	level endon("voteend");
	for(;;)
	{
		players = getentarray("player", "classname");
		for (i=0; i<players.size; i++)
		{
			player = players[i];
			player.sessionstate = "spectator";
			player.spectatorclient = -1;
			if (!isDefined(player.startedvoting))
			{
				player.startedvoting = false;
				player.printvoting = false;
			}
			if (player.startedvoting != true && player.printvoting != true)
			{
				player iprintln("You can not vote at this time!");
				player.printvoting = true;
			}
		}
		wait .05 ;
	}
}

addRandomMaps()
{
	x = GetMapRotation(true, false, undefined);
	for(i = 0; i < x.maps.size; i++)
	{
		exactmap = x.maps[i]["map"];
		exactgametype = x.maps[i]["gametype"];
		levelshot = "levelshots/" + exactmap + ".dds";
		nicemapname = switchMapName(exactmap);
		nicename = switchMapName(exactmap) + ", " + switchGametypeName(exactgametype);
		hudstring = localizeMapString(exactmap);
		hudgtstring = localizeGametypeString(exactgametype);
		addMap(exactmap, exactgametype, levelshot, hudstring, nicename, hudgtstring);
	}
}


addMap(name, gametype, loadscreen, hudstring, nicename, hudgtstring)
{
	if ( ! isDefined(level.maps))
		level.maps = [];
	i = level.maps.size;
	level.maps[i] = spawnstruct();
	level.maps[i].name = name;
	level.maps[i].gametype = gametype;
	level.maps[i].loadscreen = loadscreen;
	level.maps[i].hudstring = hudstring;
	level.maps[i].nicename = nicename;
	level.maps[i].hudgtstring= hudgtstring;
}

getMaps()
{
	return level.maps;
}

precache() 
{
	addRandomMaps();
	maps = getMaps();
	for (i=0; i<maps.size; i++)
	{
		currmap = maps[i];
		precacheShader(currmap.loadscreen);
		precacheString(currmap.hudstring);
		precacheString(currmap.hudgtstring);
	}

	precacheShader("objpoint_star");

	precacheShader("white");

	level.noMap = &"-no map voted-";
	level.noGt = &"-no gametype voted-";
	level.votedFor = &"Voted for:";
	level.votedGt = &"Voted gametype:";
	level.justWinning = &"Winning:";
	level.nextMap = &"^7Next Map: ^5[Attack]^7";
	level.prevMap = &"^7Previous Map: ^5[{+melee}]^7";

	precacheShader("hudStopwatch");
	precacheShader("hudStopwatchneedle");

	precacheString(level.noGt);
	precacheString(level.noMap);
	precacheString(level.votedFor);
	precacheString(level.votedGt);
	precacheString(level.justWinning);
	precacheString(level.nextMap);
	precacheString(level.prevMap);

	level.mapvote = spawnstruct();
	level.mapvote.maps = [];
	level.mapvote.timeleft = &"Time left: ^6";
	precacheString(level.mapvote.timeleft);
}

mapVote(maps)
{
	level endon("voteend");
	player = self;

	player setClientCvar("ui_allow_joinallies", "0");
	player setClientCvar("ui_allow_joinaxis", "0");
	player setClientCvar("ui_allow_joinauto", "0");
	player setClientCvar("ui_allow_weaponchange", "0");

	//iprintln("maps=" + maps.size);
	atMap = 0;
	mapsEachSide = 3;

	// no default map, to prevent "afk"-votes of the first map
	player.clickId = -1;

	background = newClientHudElem(player);
	background.archived = false;
	background.horzAlign = "fullscreen";
	background.vertAlign = "fullscreen";
	background.alignX = "left";
	background.alignY = "top";
	background.alpha = 0.5;
	background.sort = 103;
	background.color = (0.05, 0.05, 0.05);
	background.x = 0;
	background.y = 280/*-40*/-70;
	background setShader("white", 640, 430-280+40);

	//Header for player vote
	votedFor = newClientHudElem(player);
	votedFor.archived = false;
	votedFor.horzAlign = "fullscreen";
	votedFor.vertAlign = "fullscreen";
	votedFor.alignX = "left";
	votedFor.alignY = "top";
	votedFor.sort = 105;
	votedFor.color = (0.95, 0.05, 0.05);
	votedFor.x = 200;
	votedFor.y = 220;
	votedFor setText(level.votedFor);
	
	votedGt = newClientHudElem(player);
	votedGt.archived = false;
	votedGt.horzAlign = "fullscreen";
	votedGt.vertAlign = "fullscreen";
	votedGt.alignX = "left";
	votedGt.alignY = "top";
	votedGt.sort = 105;
	votedGt.color = (1, 1, 1);
	votedGt.x = 400;
	votedGt.y = 220;
	votedGt setText(level.noGt);
	
	currentMap = newClientHudElem(player);
	currentMap.archived = false;
	currentMap.horzAlign = "fullscreen";
	currentMap.vertAlign = "fullscreen";
	currentMap.alignX = "left";
	currentMap.alignY = "top";
	currentMap.sort = 105;
	currentMap.color = (1, 1, 1);
	currentMap.x = 300;
	currentMap.y = 220;
	currentMap setText(level.noMap);

	
	//Guidelines for player to vote
	prevMap = newClientHudElem(player);
	prevMap.archived = false;
	prevMap.horzAlign = "fullscreen";
	prevMap.vertAlign = "fullscreen";
	prevMap.alignX = "left";
	prevMap.alignY = "top";
	prevMap.sort = 105;
	prevMap.color = (1, 1, 1);
	prevMap.x = 10;
	prevMap.y = 225;
	prevMap setText(level.prevMap);

	nextMap = newClientHudElem(player);
	nextMap.archived = false;
	nextMap.horzAlign = "fullscreen";
	nextMap.vertAlign = "fullscreen";
	nextMap.alignX = "left";
	nextMap.alignY = "top";
	nextMap.sort = 105;
	nextMap.color = (1, 1, 1);
	nextMap.x = 640-120;
	nextMap.y = 225;
	nextMap setText(level.nextMap);
	
	indexes = circulateIndex(/*at=*/atMap, /*eachSide=*/mapsEachSide, /*maxNumber=*/maps.size);

	huds = [];
	for (i=0; i<indexes.size; i++)
	{
		huds[i] = newClientHudElem(player);
		huds[i].alpha = 0.20; // first maps arent showed
		huds[i].archived = false;
		huds[i].horzAlign = "fullscreen";
		huds[i].vertAlign = "fullscreen";
		huds[i].alignX = "left";
		huds[i].alignY = "top";
		huds[i].sort = 104;
		huds[i].color = (0.50, 0.50, 0.50);
		
		mapIndex = indexes[i];
		shader = maps[mapIndex].loadscreen;
		huds[i] setShader(shader, int((640/7)*indexScale(i)), int((480/7)*indexScale(i)));
		huds[i].x = absoluteX(i, indexes.size);
		huds[i].y = absoluteY(i);
		//huds[i] fadeOverTime(1);
	}

	while (isDefined(player))
	{
		direction = 0;
		if (player attackButtonPressed())
			direction = 1;
		if (player meleeButtonPressed())
			direction = -1;
		if (direction == 0)
		{
			wait 0.05;
			continue;
		}

		player playLocalSound("hq_score");
		//Make sure player is spectating
		player.sessionstate = "spectator";
		player.spectatorclient = -1;
		
		// should be abstracted somehow
		while (atMap < 0)
			atMap += maps.size;
		atMap %= maps.size;

		indexes = circulateIndex(/*at=*/atMap, /*eachSide=*/mapsEachSide, /*maxNumber=*/maps.size);

		output = "indexes (at="+ (atMap+direction) +"): ";
		for (i=0; i<indexes.size; i++)
			output += indexes[i] + " ";
		//iprintln(output);

		player.clickId = atMap+direction;

		if (player.clickId == -1)
			player.clickId = maps.size-1;
		if (player.clickId == maps.size)
			player.clickId = 0;
		
		//iprintln("clickId="+player.clickId);
		currentMap setText(maps[player.clickId].hudstring);
		votedGt setText(maps[player.clickId].hudgtstring);

		// or prevent first moving with firstTime...
		for (i=0; i<indexes.size; i++)
		{
			mapIndex = indexes[i];
			shader = maps[mapIndex].loadscreen;
			huds[i].color = (1, 1, 1); // make visible
			huds[i] setShader(shader, int((640/7)*indexScale(i)), int((480/7)*indexScale(i)));
			huds[i].x = absoluteX(i, indexes.size);
			huds[i].y = absoluteY(i);
			huds[i].alpha = 1;
			huds[i] moveOverTime(0.40);
			if (i-direction < 0 || i-direction > 6)
				continue;
			huds[i].x = absoluteX(i-direction, indexes.size);
			huds[i].y = absoluteY(i-direction);
			huds[i] scaleOverTime(0.40, int((640/7)*indexScale(i-direction)), int((480/7)*indexScale(i-direction)));
		}
		

		wait 0.50;

		atMap += direction;
	}
}

getWinningMap(players, maps)
{
	votesForId = [];

	for (i=0; i<maps.size; i++)
		votesForId[i] = 0;

	for (i=0; i<players.size; i++)
	{
		player = players[i];
		if (!isDefined(player))
			continue;
		if (!isDefined(player.clickId))
			continue;
		if (player.clickId == -1)
			continue;

		votesForId[player.clickId]++;
	}

	// search the map-id with the most votes
	votesMost = 0; // the map id 0 is winning by default
	for (i=1; i<votesForId.size; i++) // search id better then default
		if (votesForId[i] > votesForId[votesMost])
			votesMost = i;

	output = "votesMost="+votesMost + " votes=";
	for (i=0; i<votesForId.size; i++)
		output += votesForId[i] + ",";
	//iprintln(output);

	return maps[votesMost];
}

printWinningMap(players, maps)
{
	justWinning = newHudElem();
	justWinning.archived = false;
	justWinning.horzAlign = "fullscreen";
	justWinning.vertAlign = "fullscreen";
	justWinning.alignX = "left";
	justWinning.alignY = "top";
	justWinning.sort = 105;
	justWinning.color = (0.95, 0.05, 0.05);
	justWinning.x = 200;
	justWinning.y = 170+30+40;
	justWinning setText(level.justWinning);
	
	winningMap = newHudElem();
	winningMap.archived = false;
	winningMap.horzAlign = "fullscreen";
	winningMap.vertAlign = "fullscreen";
	winningMap.alignX = "left";
	winningMap.alignY = "top";
	winningMap.sort = 105;
	winningMap.color = (1, 1, 1);
	winningMap.x = 200+100;
	winningMap.y = 170+30+40;
	winningMap setText(level.noMap);
	
	winningGametype = newHudElem();
	winningGametype.archived = false;
	winningGametype.horzAlign = "fullscreen";
	winningGametype.vertAlign = "fullscreen";
	winningGametype.alignX = "left";
	winningGametype.alignY = "top";
	winningGametype.sort = 105;
	winningGametype.color = (1, 1, 1);
	winningGametype.x = 200+200;
	winningGametype.y = 170+30+40;
	winningGametype setText(level.noGt);

	while (1)
	{
		map = getWinningMap(players, maps);
		winningMap setText(map.hudstring);
		winningGametype setText(map.hudgtstring);
		wait 0.25;
	}
}

///**** Functions ****///

int(val)
{
	return (int)val;
}
arrayAdd(array, element)
{
	array[array.size] = element;
	return array;
}

// return 1+2*eachSide indexes
circulateIndex(at, eachSide, maxNumber)
{
	indexes = [];

	while (at < 0)
		at += maxNumber;
	at %= maxNumber;

	// left side
	for (i=eachSide; i; i--) // 2, 1
	{
		tmp = at - i;
		if (tmp < 0)
			tmp = maxNumber + tmp;
		indexes = arrayAdd(indexes, tmp);
	}
	indexes = arrayAdd(indexes, at);
	// right side
	for (i=1; i<=eachSide; i++) // 1, 2
	{
		tmp = at + i;
		if (tmp >= maxNumber)
			tmp -= maxNumber;
		indexes = arrayAdd(indexes, tmp);
	}
	return indexes;
}

indexScale(i)
{
	// no scale, its somehow ugly
	if (1<2)
		return 1;

	switch (i)
	{
		case 0:
			return 0.5;
		case 1:
			return 0.7;
		case 2:
			return 0.9;
		case 3:
			return 1.2;
		case 4:
			return 0.9;
		case 5:
			return 0.7;
		case 6:
			return 0.5;
	}
	return 1;
}

absoluteX(index, max)
{
	number = 0;
	// have to think about it...
	if (index <= -1)
		number = -1000;
	if (index >= 7)
		number = -1000;

	switch (index)
	{
		case 0:
			number = -106;
			break;
		case 1:
			number = 30;
			break;
		case 2:
			number = 155;
			break;
		case 3:
			number = 274;
			break;
		case 4:
			number = 395;
			break;
		case 5:
			number = 515;
			break;
		case 6:
			number = 655;
			break;
	}
	return number;
}

absoluteY(index)
{
	number = 0;
	// have to think about it...
	if (index <= -1)
		number = -1000;
	if (index >= 7)
		number = -1000;

	switch (index)
	{
		case 0:
			number = 270+15;
			break;
		case 1:
			number = 295;
			break;
		case 2:
			number = 323;
			break;
		case 3:
			number = 345;
			break;
		case 4:
			number = 324;
			break;
		case 5:
			number = 296;
			break;
		case 6:
			number = 271+15;
			break;
	}
	return number - 40;
}

GetMapRotation(random, current, number)
{
	maprot = "";

	if(!isdefined(number))
		number = 0;

	// Get current maprotation
	if(current)
		maprot = strip(getcvar("sv_maprotationcurrent"));	

	// Get maprotation if current empty or not the one we want
	if(maprot == "")
		maprot = strip(getcvar("sv_maprotation"));	

	// No map rotation setup!
	if(maprot == "")
		return undefined;
	
	// Explode entries into an array
//	temparr2 = explode(maprot," ");
	j=0;
	temparr2[j] = "";	
	for(i=0;i<maprot.size;i++)
	{
		if(maprot[i]==" ")
		{
			j++;
			temparr2[j] = "";
		}
		else
			temparr2[j] += maprot[i];
	}

	// Remove empty elements (double spaces)
	temparr = [];
	for(i=0;i<temparr2.size;i++)
	{
		element = strip(temparr2[i]);
		if(element != "")
		{
			temparr[temparr.size] = element;
		}
	}

	// Spawn entity to hold the array
	x = spawn("script_origin",(0,0,0));

	x.maps = [];
	lastexec = undefined;
	lastjeep = undefined;
	lasttank = undefined;
	lastgt = level.awe_gametype;
	for(i=0;i<temparr.size;)
	{
		switch(temparr[i])
		{
			case "allow_jeeps":
				if(isdefined(temparr[i+1]))
					lastjeep = temparr[i+1];
				i += 2;
				break;

			case "allow_tanks":
				if(isdefined(temparr[i+1]))
					lasttank = temparr[i+1];
				i += 2;
				break;
	
			case "exec":
				if(isdefined(temparr[i+1]))
					lastexec = temparr[i+1];
				i += 2;
				break;

			case "gametype":
				if(isdefined(temparr[i+1]))
					lastgt = temparr[i+1];
				i += 2;
				break;

			case "map":
				if(isdefined(temparr[i+1]))
				{
					x.maps[x.maps.size]["exec"]		= lastexec;
					x.maps[x.maps.size-1]["jeep"]	= lastjeep;
					x.maps[x.maps.size-1]["tank"]	= lasttank;
					x.maps[x.maps.size-1]["gametype"]	= lastgt;
					x.maps[x.maps.size-1]["map"]	= temparr[i+1];
				}
				// Only need to save this for random rotations
				if(!random)
				{
					lastexec = undefined;
					lastjeep = undefined;
					lasttank = undefined;
					lastgt = undefined;
				}

				i += 2;
				break;

			// If code get here, then the maprotation is corrupt so we have to fix it
			default:
				iprintlnbold("ERROR IN MAPROTATION!!! Will try to fix.");
	
				if(isGametype(temparr[i]))
					lastgt = temparr[i];
				else if(isConfig(temparr[i]))
					lastexec = temparr[i];
				else
				{
					x.maps[x.maps.size]["exec"]		= lastexec;
					x.maps[x.maps.size-1]["jeep"]	= lastjeep;
					x.maps[x.maps.size-1]["tank"]	= lasttank;
					x.maps[x.maps.size-1]["gametype"]	= lastgt;
					x.maps[x.maps.size-1]["map"]	= temparr[i];
	
					// Only need to save this for random rotations
					if(!random)
					{
						lastexec = undefined;
						lastjeep = undefined;
						lasttank = undefined;
						lastgt = undefined;
					}
				}
					

				i += 1;
				break;
		}
		if(number && x.maps.size >= number)
			break;
	}

	if(random)
	{
		// Shuffle the array 20 times
		for(k = 0; k < 20; k++)
		{
			for(i = 0; i < x.maps.size; i++)
			{
				j = randomInt(x.maps.size);
				element = x.maps[i];
				x.maps[i] = x.maps[j];
				x.maps[j] = element;
			}
		}
	}

	return x;
}

strip(s)
{
	if(s=="")
		return "";

	s2="";
	s3="";

	i=0;
	while(i<s.size && s[i]==" ")
		i++;

	// String is just blanks?
	if(i==s.size)
		return "";
	
	for(;i<s.size;i++)
	{
		s2 += s[i];
	}

	i=s2.size-1;
	while(s2[i]==" " && i>0)
		i--;

	for(j=0;j<=i;j++)
	{
		s3 += s2[j];
	}
		
	return s3;
}


isGametype(gt)
{
	switch(gt)
	{
		case "dm":
		case "tdm":
		case "sd":
		case "re":
		case "hq":
		case "bel":
		case "bas":
		case "dom":
		case "kc":
		case "ctf":
		case "ter":
		case "actf":
		case "lts":
		case "cnq":
		case "rsd":
		case "tdom":
		case "ad":
		case "htf":
		case "asn":
		case "gungame":
		case "oitc":
		case "shrp":

		case "mc_dm":
		case "mc_tdm":
		case "mc_sd":
		case "mc_re":
		case "mc_hq":
		case "mc_bel":
		case "mc_bas":
		case "mc_dom":
		case "mc_ctf":
		case "mc_ter":
		case "mc_actf":
		case "mc_lts":
		case "mc_cnq":
		case "mc_rsd":
		case "mc_tdom":
		case "mc_ad":
		case "mc_htf":
		case "mc_asn":

			return true;

		default:
			return false;
	} 
}

explode(s,delimiter)
{
	j=0;
	temparr[j] = "";	

	for(i=0;i<s.size;i++)
	{
		if(s[i]==delimiter)
		{
			j++;
			temparr[j] = "";
		}
		else
			temparr[j] += s[i];
	}
	return temparr;
}

isConfig(cfg)
{
	temparr = explode(cfg,".");
	if(temparr.size == 2 && temparr[1] == "cfg")
		return true;
	else
		return false;
}

switchMapName(map)
{
	switch(map)
	{
		case "mp_bocage":
			mapname = "Bocage";
			break;
		
		case "mp_brecourt":
			mapname = "Brecourt";
			break;

		case "mp_carentan":
			mapname = "Carentan";
			break;
		
		case "mp_chateau":
			mapname = "Chateau";
			break;
		
		case "mp_dawnville":
			mapname = "Dawnville";
			break;
		
		case "mp_depot":
			mapname = "Depot";
			break;
		
		case "mp_harbor":
			mapname = "Harbor";
			break;
		
		case "mp_hurtgen":
			mapname = "Hurtgen";
			break;
		
		case "mp_neuville":
			mapname = "Neuville";
			break;
		
		case "mp_pavlov":
			mapname = "Pavlov";
			break;
		
		case "mp_powcamp":
			mapname = "P.O.W Camp";
			break;
		
		case "mp_railyard":
			mapname = "Railyard";
			break;

		case "mp_rocket":
			mapname = "Rocket";
			break;
		
		case "mp_ship":
			mapname = "Ship";
			break;
		
		case "mp_stalingrad":
			mapname = "Stalingrad";
			break;
		
		case "mp_stanjel":
		case "mc_stanjel":
			mapname = "Stanjel";
			break;

		case "mp_bazolles":
		case "mc_bazolles":
			mapname = "Bazolles";
			break;

		case "mp_townville":
		case "mc_townville":
			mapname = "Town ville";
			break;

		case "mp_german_town":
		case "mc_german_town":
			mapname = "German Town";
			break;
		
		default:
			mapname = map;
			break;
	}

	return mapname;

}

switchGametypeName(gt)
{
	switch(gt)
	{
		case "dm":
		case "mc_dm":
			gtname = "Deathmatch";
			break;
		
		case "tdm":
		case "mc_tdm":
			gtname = "Team Deathmatch";
			break;

		case "sd":
		case "mc_sd":
			gtname = "Search & Destroy";
			break;

		case "rsd":
		case "mc_rsd":
			gtname = "Reinforced Search & Destroy";
			break;

		case "re":
		case "mc_re":
			gtname = "Retrieval";
			break;

		case "hq":
		case "mc_hq":
			gtname = "Headquarters";
			break;

		case "bel":
		case "mc_bel":
			gtname = "Behind Enemy Lines";
			break;
		
		case "dem":
		case "mc_dem":
			gtname = "Demolition";
			break;

		case "cnq":
		case "mc_cnq":
			gtname = "Conquest TDM";
			break;

		case "lts":
		case "mc_lts":
			gtname = "Last Team Standing";
			break;

		case "ctf":
		case "mc_ctf":
			gtname = "Capture The Flag";
			break;

		case "mc_tdom":
			gtname = "Team Domination";
			break;
			
		case "kc":
			gtname = "Kill Confirmed";
			break;
		default:
			gtname = gt;
			break;
	}

	return gtname;
}

localizeGametypeString(gt)
{
	switch(gt)
	{
		case "dm":
		case "mc_dm":
			gtname = &"^7Deathmatch";
			break;
		
		case "tdm":
		case "mc_tdm":
			gtname = &"^7Team Deathmatch";
			break;

		case "sd":
		case "mc_sd":
			gtname = &"^7Search & Destroy";
			break;

		case "rsd":
		case "mc_rsd":
			gtname = &"^7Reinforced Search & Destroy";
			break;

		case "re":
		case "mc_re":
			gtname = &"^7Retrieval";
			break;

		case "hq":
		case "mc_hq":
			gtname = &"^7Headquarters";
			break;

		case "bel":
		case "mc_bel":
			gtname = &"^7Behind Enemy Lines";
			break;
		
		case "dem":
		case "mc_dem":
			gtname = &"^7Demolition";
			break;

		case "cnq":
		case "mc_cnq":
			gtname = &"^7Conquest TDM";
			break;

		case "lts":
		case "mc_lts":
			gtname = &"^7Last Team Standing";
			break;

		case "ctf":
		case "mc_ctf":
			gtname = &"^7Capture The Flag";
			break;

		case "mc_tdom":
			gtname = &"^7Team Domination";
			break;
		case "kc":
		case "akc":
			gtname = &"^7Kill Confirmed";
			break;
		case "oic":
			gtname = &"^7One in the Chamber";
			break;
		case "shrp":
			gtname = &"^7Sharpshooter";
			break;
		case "gungame":
			gtname = &"^7Gungame";
			break;
		case "jump":
			gtname = &"^7Jump";
		
		default:
			gtname = &"^7Unknown";
			break;
	}
	return gtname;
	
}

localizeMapString(map)
{
	switch(map)
	{
		case "mp_bocage":
			mapname = &"Bocage";
			break;
		
		case "mp_brecourt":
			mapname = &"Brecourt";
			break;

		case "mp_carentan":
			mapname = &"Carentan";
			break;
		
		case "mp_chateau":
			mapname = &"Chateau";
			break;
		
		case "mp_dawnville":
			mapname = &"Dawnville";
			break;
		
		case "mp_depot":
			mapname = &"Depot";
			break;
		
		case "mp_harbor":
			mapname = &"Harbor";
			break;
		
		case "mp_hurtgen":
			mapname = &"Hurtgen";
			break;
		
		case "mp_neuville":
			mapname = &"Neuville";
			break;
		
		case "mp_pavlov":
			mapname = &"Pavlov";
			break;
		
		case "mp_powcamp":
			mapname = &"P.O.W Camp";
			break;
		
		case "mp_railyard":
			mapname = &"Railyard";
			break;

		case "mp_rocket":
			mapname = &"Rocket";
			break;
		
		case "mp_ship":
			mapname = &"Ship";
			break;
		
		case "mp_stalingrad":
			mapname = &"Stalingrad";
			break;
		
		case "mp_stanjel":
		case "mc_stanjel":
			mapname = &"Stanjel";
			break;

		case "mp_bazolles":
		case "mc_bazolles":
			mapname = &"Bazolles";
			break;

		case "mp_townville":
		case "mc_townville":
			mapname = &"Town ville";
			break;

		case "mp_german_town":
		case "mc_german_town":
			mapname = &"German Town";
			break;
		
		default:
			mapname = &"Unknown";
			break;
	}

	return mapname;
}
