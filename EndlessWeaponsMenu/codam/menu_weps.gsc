  //	EndlessWepMenu v1.0   //
 //		AUTHOR: Indy		 //
//////////////////////////////

main( phase, register )
{
	codam\utils::debug( 0, "======== menu_weps/main:: |", phase, "|", register, "|" );

	if ( !codam\utils::getVar( "endless", "wepmenu", "bool", 1|2, false ) )
		return;
		
	switch ( phase )
	{
	  case "init":		_init( register );	break;
	  case "load":		_load();		break;
	  case "start":	  	_start();		break;
	}

	return;
}

_init( register )
{
	codam\utils::debug( 0, "======== menu_weps/_init:: |", register, "|" );
	

	switch ( level.ham_g_gametype )
	{
		case "sd":
		case "re":
			[[ register ]]( "gt_menuHandler", ::SDmenuHandler, "takeover" );
			break;
		case "dm":
		case "tdm":
			[[ register ]]( "gt_menuHandler", ::TDMmenuHandler, "takeover" );
			break;
		default:
			return;
	}
	
	//setCvar("menu_init", "yep");

	[[ register ]]( "def_PlayerConnect", ::PlayerConnect, "takeover" );
	[[ register ]](  "menuHandler", ::handler, "takeover" );
	[[ register ]]( "isWeaponMenu", ::isWeapMenu);
	
	return;
}

_load()
{
	codam\utils::debug( 0, "======== menu_weps/_load" );

	game[ "menu_weapon_all" ] = "weapon_" + game[ "allies" ] + game[ "axis" ];
	precacheMenu( game[ "menu_weapon_all" ] );
	
	return;
}

_start()
{
	codam\utils::debug( 0, "======== menu_weps/_start" );

	return;
}

///////////////////////////////////////////////////////////////////////////////
// START MENU HANDLER - DONT FREAKING EDIT BELOW THIS POINT
///////////////////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////////////////
TDMmenuHandler( menu, a1, a2, a3, a4, a5, a6, a7, a8, a9,
			b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 )
{
	self endon( "end_player" );

	for (;;)
	{
		resp = self [[ level.gtd_call ]]( "menuHandler", menu );

		if ( !isdefined( resp ) || ( resp.size < 2 ) ||
		     !isdefined( resp[ 0 ] ) || !isdefined( resp[ 1 ] ) )
		{
			// Shouldn't happen ... but just in case
			wait( 1 );
			continue;
		}

		val = resp[ 1 ];
		switch ( resp[ 0 ] )
		{
		  case "team":
		  	switch ( val )
		  	{
		  	  case "spectator":
				if ( self.pers[ "team" ] != "spectator" )
					self [[ level.gtd_call ]](
								"goSpectate" );

				menu = undefined;
				break;
		  	  default:
		  	  	if ( ( val == "" ) ||
		  	  	     ![[ level.gtd_call ]]( "isTeam", val ) )
				{
					// Team not playing, try again!
					break;
				}

				if ( isdefined( self.pers[ "team" ] ) &&
				     ( val == self.pers[ "team" ] ) )
				{
					// Same team selected!
					menu = undefined;
					break;
				}

				// Still alive ... changing teams?
				if ( self.sessionstate == "playing" )
					self [[ level.gtd_call ]]( "suicide" );

				// Okay, selected new team ...
				self notify( "end_respawn" );

				self.pers[ "team" ] = val;
				self.pers[ "weapon" ] = undefined;
				self.pers[ "savedmodel" ] = undefined;

				menu = game[ "menu_weapon_all" ];
				self setClientCvar( "g_scriptMainMenu", menu );
				self setClientCvar( level.ui_weapontab, "1" );
				break;
		  	}
		  	break;
		  case "weapon":
			if ( ![[ level.gtd_call ]]( "isTeam",
							self.pers[ "team" ] ) )
			{
				// No team selected yet?
				menu = game[ "menu_team" ];
				break;
			}

			if ( !self [[ level.gtd_call ]]( "isWeaponAllowed",
									val ) )
			{
				self iprintln(
					"^3*** Weapon has been disabled." );
				break;
			}

			weapon = val;

			if ( isdefined( self.pers[ "weapon" ] ) &&
			     ( self.pers[ "weapon" ] == weapon ) )
			{
				menu = undefined;
				break;	// Same weapon selected!
			}
/*
			// Is the weapon available?
			weapon = self [[ level.gtd_call ]]( "assignWeapon",
									weapon );
*/
			if ( !isdefined( weapon ) )
			{
				self iprintln( "^3*** Weapon is unavailable." );
				break;
			}

			menu = undefined;

			if ( !isdefined( self.pers[ "weapon" ] ) )
			{
				// First selected weapon ...
				self.pers[ "weapon" ] = weapon;
				switch ( level.ham_g_gametype )
				{
				  case "hq":
					self thread [[ level.gtd_call ]](
								"gt_respawn" );
					break;
				  default:
					self [[ level.gtd_call ]](
							"gt_spawnPlayer" );
					break;
				}

				self thread [[ level.gtd_call ]](
							"printJoinedTeam",
							 self.pers[ "team" ] );
			}
			else
			{
				// Already have a weapon, wait 'til next spawn
				self.pers[ "weapon" ] = weapon;

				// End of map will take care of storing player's
				// new weapon.  Need this in case a map_restart
				// is done.
				self [[ level.gtd_call ]]( "savePlayer" );

				if ( maps\mp\gametypes\_teams::useAn( weapon ) )
					text = &"MPSCRIPT_YOU_WILL_RESPAWN_WITH_AN";
				else
					text = &"MPSCRIPT_YOU_WILL_RESPAWN_WITH_A";

				weaponname = maps\mp\gametypes\_teams::getWeaponName( weapon );
				self iprintln( text, weaponname );
			}
		  	break;
		  case "menu":
			if ( ( val == "weapon" ) &&
		  	     isdefined( self.pers[ "team" ] ) )
			  	menu = game[ "menu_weapon_all" ];
		  	break;
		  default:
		  	menu = undefined;
		  	break;
		}
	}
}

SDmenuHandler( menu, a1, a2, a3, a4, a5, a6, a7, a8, a9,
			b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 )
{
	self endon( "end_player" );

	//setCvar("menu_handler", "yep");
	for (;;)
	{
		resp = self [[ level.gtd_call ]]( "menuHandler", menu );
		if ( !isdefined( resp ) || ( resp.size < 2 ) ||
		     !isdefined( resp[ 0 ] ) || !isdefined( resp[ 1 ] ) )
		{
			// Shouldn't happen ... but just in case
			wait( 1 );
			continue;
		}

		val = resp[ 1 ];
		switch ( resp[ 0 ] )
		{
		  case "team":
		  	switch ( val )
		  	{
		  	  case "spectator":
				if ( self.pers[ "team" ] != "spectator" )
					self [[ level.gtd_call ]]( "goSpectate" );
				menu = undefined;
				break;
				
		  	  default:
		  	  	if ( ( val == "" ) || ![[ level.gtd_call ]]( "isTeam", val ) )
				{
					// Team not playing, try again!
					break;
				}

				if ( isdefined( self.pers[ "team" ] ) && ( val == self.pers[ "team" ] ) )
				{
					// Same team selected!
					menu = undefined;
					break;
				}

				// Still alive ... changing teams?
				if ( self.sessionstate == "playing" )
					self [[ level.gtd_call ]]( "suicide" );

				// Okay, selected new team ...
				self notify( "end_respawn" );

				// Okay, selected new team ...
				self.pers[ "team" ] = val;
				self.pers[ "weapon" ] = undefined;
				self.pers[ "weapon1" ] = undefined;
				self.pers[ "weapon2" ] = undefined;
				self.pers[ "savedmodel" ] = undefined;
				self.pers[ "spawnweapon" ] = undefined;

				menu = game[ "menu_weapon_all" ];
				self setClientCvar( "g_scriptMainMenu", menu );
				self setClientCvar( level.ui_weapontab, "1" );

				break;
		  	}

		  	break;
		  case "weapon":
		  	_team = self.pers[ "team" ];
			if ( ![[ level.gtd_call ]]( "isTeam", _team ) )
			{
				// No team selected yet?
				menu = game[ "menu_team" ];
				break;
			}

			if ( !self [[ level.gtd_call ]]( "isWeaponAllowed", val ) )
			{
				self iprintln(
					"^3*** Weapon has been disabled." );
				break;
			}

			weapon = val;

			_savemenu = menu;
			menu = undefined;
			if ( isdefined( self.pers[ "weapon" ] ) &&
			     ( self.pers[ "weapon" ] == weapon ) &&
			     !isdefined( self.pers[ "weapon1" ] ) )
				break;
/*
			// Is the weapon available?
			weapon = self [[ level.gtd_call ]]( "assignWeapon",
								weapon ); 
*/
			if ( !isdefined( weapon ) )
			{
				self iprintln( "^3*** Weapon is unavailable." );
				menu = _savemenu;
				break;
			}

			_spawnPlayer = false;
			if ( isdefined( self.teamForced ) &&
			     ( self.teamForced == "playing" ) )
		 	{
		 		// Forced to a team when alive!
		 		self.teamForced = undefined;
				self.spawned = undefined;
				_spawnPlayer = true;
			}

			if ( !game[ "matchstarted" ] )
			{
			 	if ( isdefined( self.pers[ "weapon" ] ) )
			 	{
			 		// Replace existing weapon
					self [[ level.gtd_call ]](
							"assignWeaponSlot",
							"primary", weapon );
					self switchToWeapon( weapon );

					self [[ level.gtd_call ]](
								"givePistol" );
					self [[ level.gtd_call ]](
								"giveGrenade",
								weapon );
				}
			 	else
			 	{
					self.spawned = undefined;
					_spawnPlayer = true;
				}

				self.pers[ "weapon" ] = weapon;
			}
			else
			if ( !level.roundstarted )
			{
			 	if ( isdefined( self.pers[ "weapon" ] ) )
			 	{
			 		// Replace existing weapon
					self [[ level.gtd_call ]](
							"assignWeaponSlot",
							"primary", weapon );
					self switchToWeapon( weapon );
				}
			 	else
			 	{
			 		if ( !level.exist[ _team ] )
						self.spawned = undefined;
					_spawnPlayer = true;
				}

		 		self.pers[ "weapon" ] = weapon;
			}
			else
			{
				// Grace-period expired!
				if ( isdefined( self.pers[ "weapon" ] ) )
					self.oldweapon = self.pers[ "weapon" ];

				self.pers[ "weapon" ] = weapon;
				self.sessionteam = _team;

				if ( self.sessionstate != "playing" )
					self.statusicon =
						"gfx/hud/hud@status_dead.tga";

				if ( _team == "allies" )
					_otherteam = "axis";
				else if ( _team == "axis" )
					_otherteam = "allies";

				if ( !level.didexist[ _otherteam ] &&
				     !level.roundended )
				{
					// No opponents
					self.spawned = undefined;
					_spawnPlayer = true;
				}
				else
				if ( !level.didexist[ _team ] &&
				     !level.roundended )
				{
					// First on team
					self.spawned = undefined;
					_spawnPlayer = true;
				}
				else
				{
					self [[ level.gtd_call ]]( "savePlayer" );

					weaponname = maps\mp\gametypes\_teams::getWeaponName( weapon );

					text = undefined;
					if ( _team == "allies" )
					{
						if ( maps\mp\gametypes\_teams::useAn( weapon ) )
							text = &"MPSCRIPT_YOU_WILL_SPAWN_ALLIED_WITH_AN_NEXT_ROUND";
						else
							text = &"MPSCRIPT_YOU_WILL_SPAWN_ALLIED_WITH_A_NEXT_ROUND";
					}
					else
					if ( _team == "axis" )
					{
						if ( maps\mp\gametypes\_teams::useAn( weapon ) )
							text = &"MPSCRIPT_YOU_WILL_SPAWN_AXIS_WITH_AN_NEXT_ROUND";
						else
							text = &"MPSCRIPT_YOU_WILL_SPAWN_AXIS_WITH_A_NEXT_ROUND";
					}

					if ( isdefined( text ) )
						self iprintln( text,
								weaponname );

					if ( self.sessionstate != "playing" )
						self thread [[ level.gtd_call ]](
							"manageSpectate",
							"round" );
				}
			}

			if ( _spawnPlayer )
			{
				self [[ level.gtd_call ]]( "gt_spawnPlayer" );
				self thread [[ level.gtd_call ]](
						"printJoinedTeam", _team );
			}
		  	break;
		  case "menu":
			if ( ( val == "weapon" ) &&
		  	     isdefined( self.pers[ "team" ] ) )
			  	menu = game[ "menu_weapon_all" ];
		  	break;
		  default:
		  	menu = undefined;
		  	break;
		}
	}
}
// END MENU HANDLER
//
///////////////////////////////////////////////////////////////////////////////
PlayerConnect( a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
				b0, b1,	b2, b2,	b4, b5,	b6, b7,	b8, b9 )
{
	//setCvar("menu_connect", "yep");
	self.statusicon	= "gfx/hud/hud@status_connecting.tga";

	self.connecting = true;
	level.connectingPlayers++;

	if ( !isdefined( self.pers[ "dumbbot" ] ) )
		self waittill( "begin" );

	self.connecting = undefined;
	level.connectingPlayers--;

	self.statusicon = self [[ level.gtd_call ]]( "connect_statusicon" );
	self.hudelem = [];
	self.objs_held = 0;

	menu = undefined;

	if ( self [[ level.gtd_call ]]( "isLockedPlayer" ) )
	{
		level endon( "intermission" );

		self lockPlayer( "being kicked" );
		/*NOTREACHED*/
	}

	if ( !isdefined( self.pers[ "connected" ] ) )
	{
		if ( !codam\utils::getVar( "scr", "noserverinfo", "bool", 0,
									false ) )
			menu = game[ "menu_serverinfo" ];
		self.pers[ "connected" ] = true;
		iprintln( &"MPSCRIPT_CONNECTED", self );
	}

	[[ level.gtd_call ]]( "logPrint", "connect", self );

	if ( game[ "state" ] ==	"intermission" )
	{
		self [[	level.gtd_call ]]( "gt_spawnIntermission" );
		return;
	}

	level endon( "intermission" );

	team =	self.pers[ "team" ];
	if ( level.ham_g_gametype == "bel" )
	{
		self.god = false;
		self.respawnwait = false;
		self codam\GameTypes\_bel::removeBlackScreen();
	}
	else
	if ( !isdefined( team ) )
	{
		//menu = undefined;

		// Determine if	it's a returning player	after a	map rotation ...
		_playerInfo = self [[ level.gtd_call ]]( "isSavedPlayer" );
		if ( isdefined( _playerInfo ) &&
		     isdefined( _playerInfo[ "name" ] )	&&
		     ( _playerInfo[ "name" ] ==
				self [[	level.gtd_call ]]( "monotoneName" ) ) )
		{
			codam\utils::debug( 0, "FOUND PREVIOUS PLAYER: ",
								self.name );

			if ( isdefined( _playerInfo[ "bot" ] ) )
				self.pers[ "dumbbot" ] = true;

			if ( isdefined( _playerInfo[ "locked" ] ) )
			{
				self lockPlayer( "previously kicked" );
				/*NOTREACHED*/
			}
			else
			if ( [[ level.gtd_call ]]( "isTeam",
							_playerInfo[ "team" ] )	)
			{
				// Keep on same team
				team = _playerInfo[ "team" ];
				self.pers[ "team" ] = team;

				// Determine correct (equivalent) weapon
				// type	for this team (nationality)
				self.pers[ "weapon" ] =
					self [[ level.gtd_call ]](
						"assignWeapon",
						_playerInfo[ "weapon" ], true );
			}
			else
			{
				// Stale player	or on different	team
				team =	undefined;
				self.pers[ "team" ] = undefined;
				self.pers[ "weapon" ] = undefined;
			}
		}
	}
	else
		level [[ level.gtd_call ]]( "resetPlayer", self );

	if ( isdefined( team ) && ( team != "spectator" ) )
	{
		// edit
		if ( level.ham_g_gametype == "bel" || level.ham_g_gametype == "sd")
			self setClientCvar( "g_scriptMainMenu",
						game[ "menu_weapon_all" ] );
		else
			self setClientCvar( "g_scriptMainMenu",
					game[ "menu_weapon_" + team  ]	);
		self setClientCvar( level.ui_weapontab, "1" );

		if ( isdefined( self.pers[ "weapon" ] )	)
			self [[ level.gtd_call ]]( "gt_spawnPlayer" );
		else
		{
			if ( level.ham_g_gametype == "bel" )
				menu = game[ "menu_weapon_" +
					self.pers[ "team" ] + "_only" ];
			else if ( level.ham_g_gametype == "sd" )
				menu = game[ "menu_weapon_all" ];
			else
				menu = game[ "menu_weapon_" + team ];
			self [[ level.gtd_call ]]( "gt_spawnSpectator" );
		}
	}
	else
	{
		if ( !isdefined( menu ) )
			menu = game[ "menu_team" ];

		self [[ level.gtd_call ]]( "goSpectate"	);
	}

	if ( isdefined( self.pers[ "dumbbot" ] ) )
		self thread [[ level.gtd_call ]]( "randomBotMove" );

	self thread [[ level.gtd_call ]]( "gt_menuHandler", menu );

	self waittill( "end_player", reason );

	codam\utils::debug( 0, "exiting from player connect with reason = |",
								reason,	"|" );
	self lockPlayer( reason );
	/*NOTREACHED*/
}
//
lockPlayer( reason )
{
	wait( 0.05 );	// Delay before forcing spectator
	self [[	level.gtd_call ]]( "goSpectate"	); // For now, just force spec.

	self [[ level.gtd_call ]]( "blockMenu" );  // Disable menu operation
	self setClientCvar( "g_scriptMainMenu",	"main" ); // Only see main menu
	self closeMenu();

	self thread [[ level.gtd_call ]]( "manageSpectate", "kick" );

	iprintln( self.name + "^3 was locked for ^2" + reason );

	self [[ level.gtd_call ]]( "lockPlayer" );
	wait( 9999 );
}
//
///////////////////////////////////////////////////////////////////////////////
handler( menu, a1, a2, a3, a4, a5, a6, a7, a8, a9,
			b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 )
{
	codam\utils::debug( 90, "menu/handler:: |", self.name, "|", menu, "|" );

	//setCvar("menu_parser", "yep");
	if ( isdefined( self.menuBlock ) )
		menu = undefined;

	keepGoing = true;
	while ( keepGoing )
	{
		if ( isdefined( menu ) && ( menu != "" ) )
			self openMenu( menu );

		self waittill( "menuresponse", menu, response, force );

		codam\utils::debug( 91, "menuresponse =", "|", menu, "|",
							response, "|", force );

		if ( isdefined( self.menuBlock ) )
		{
			codam\utils::debug( 91, "menu/handler = |", menu,
								"|blocked|" );
			menu = undefined;
			continue;
		}

		if ( isdefined( game[ "menu_serverinfo" ] ) &&
		     ( menu == game[ "menu_serverinfo" ] ) &&
		     isdefined( response ) && ( response == "close" ) )
		{
			if ( self.sessionstate == "playing" )
				menu = undefined;
			else
				menu = game[ "menu_team" ];
			continue;
		}

		if ( !isdefined( response ) ||
		     ( response == "open" ) || ( response == "close" ) )
		{
			codam\utils::debug( 91, "menu/handler = |", menu, "|",
								response, "|" );
			menu = undefined;
			continue;
		}

		_resp[ 0 ] = "menu";
		_resp[ 1 ] = menu;
		_resp[ 2 ] = menu;

		if ( menu == game[ "menu_team" ] )
		{
			switch ( response )
			{
			  case "weapon":
			  case "viewmap":
			  case "callvote":
				_resp[ 1 ] = response;
				break;
			  case "0":
			  	response = "10";
			  	/*FALLTHROUGH*/
			  case "1": case "2": case "3": case "4": case "5":
			  case "6": case "7": case "8": case "9": case "10":
			  	response = [[ level.gtd_call ]](
			  				"teamFromIndex",
			  				(int) response - 1 );
			  	if ( !isdefined( response ) )
			  		response = "";
			  	/*FALLTHROUGH*/
			  case "allies":
			  case "axis":
			  	teamSel = response;
			  	/*FALLTHROUGH*/
			  case "autoassign":
			  	// Want to always auto-assign?
			  	if ( !isdefined( force ) && level.autoassign )
			  		response = "autoassign";
			  	else
			  	if ( isdefined( force ) && !force )
			  		response = "autoassign";
			  	else
			  		teamSel = undefined;

			  	if ( response == "autoassign" )
				{
			  		response = self [[ level.gtd_call ]](
			  				"autoTeam", teamSel,
			  				self.pers[ "team" ] );
			  	}
			  	/*FALLTHROUGH*/
			  case "spectator":
				_resp[ 0 ] = "team";
				_resp[ 1 ] = response;

				keepGoing = false;
				break;
			  default:
			  	menu = undefined;
			  	break;
			}
		}
		else
		if ( menu == game[ "menu_viewmap" ] )
		{
			switch ( response )
			{
			  case "team":
			  case "weapon":
			  case "callvote":
				_resp[ 1 ] = response;
				break;
			}
		}
		else
		if ( menu == game[ "menu_callvote" ] )
		{
			switch ( response )
			{
			  case "team":
			  case "weapon":
			  case "viewmap":
				_resp[ 1 ] = response;
				break;
			}
		}
		else
		if ( menu == game[ "menu_quickcommands" ] )
		{
			self [[ level.gtd_call ]]( "quickmenu", "command",
								response );
			_resp[ 0 ] = "done";
		}
		else
		if ( menu == game[ "menu_quickstatements" ] )
		{
			self [[ level.gtd_call ]]( "quickmenu", "statement",
								response );
			_resp[ 0 ] = "done";
		}
		else
		if(  menu == game[ "menu_quickresponses" ] )
		{
			self [[ level.gtd_call ]]( "quickmenu", "response",
								response );
			_resp[ 0 ] = "done";
		}
		else
		if ( [[ level.gtd_call ]]( "isWeaponMenu", menu ) || menu == game[ "menu_weapon_all"  ])
		{
			switch ( response )
			{
			  case "team":
			  case "viewmap":
			  case "callvote":
				_resp[ 1 ] = response;
				break;
			  default:
				_resp[ 0 ] = "weapon";
				_resp[ 1 ] = response;

				keepGoing = false;
				break;
			}
		}
		else
			_resp[ 0 ] = "unknown";

		// Take care of some common menu actions ...
		switch ( _resp[ 0 ] )
		{
		  case "menu":
			switch ( _resp[ 1 ] )
			{
		  	  case "team":
		  	  	menu = game[ "menu_team" ];
		  	  	break;
		  	  case "viewmap":
		  	  	menu = game[ "menu_viewmap" ];
		  	  	break;
		  	  case "callvote":
				if ( level.allowvote )
		 			menu = game[ "menu_callvote" ];
		 		else
		  			menu = undefined;
		  	  	break;
			  case "weapon":
		  	  	keepGoing = false;
		  	  	break;
			}
			break;
		  case "done":
		  	menu = undefined;
		  	break;
		}
	}

	codam\utils::dumparray( 91, "menu/handler", _resp );

	return ( _resp );
}

//
///////////////////////////////////////////////////////////////////////////////
isWeapMenu( menu, a1, a2, a3, a4, a5, a6, a7, a8, a9,
			b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 )
{
	//setCvar("menu_weapmenu", "yep");
	if ( isdefined( menu ) &&
	     ( ( menu == game[ "menu_weapon_allies" ] ) ||
	       ( menu == game[ "menu_weapon_axis" ]   ) || 
		   ( menu == game[ "menu_weapon_all"  ] ) ) )
		return ( true );

	return ( false );
}

//
///////////////////////////////////////////////////////////////////////////////
