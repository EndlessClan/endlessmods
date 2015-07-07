  //	EndlessWepMenu v1.0   //
 //		AUTHOR: Indy		 //
//////////////////////////////

main( phase, register )
{
	codam\utils::debug( 0, "======== menu/main:: |", phase, "|",
								register, "|" );

	switch ( phase )
	{
	  case "init":		_init( register );	break;
	  case "load":		_load();		break;
	  //case "start":	  	_start();		break;
	}

	return;
}

//
_init( register )
{
	codam\utils::debug( 0, "======== menu/_init:: |", register, "|" );

	[[ register ]](  "menuHandler", ::handler );
	[[ register ]]( "isWeaponMenu", ::isWeapMenu );
	[[ register ]](    "blockMenu", ::blockMenu );

	if ( level.ham_shortversion == "1.1" )
		level.ui_weapontab = "scr_showweapontab";
	else
		level.ui_weapontab = "ui_weapontab";
	return;
}

//
_load()
{
	codam\utils::debug( 0, "======== menu/_load" );

	if ( !isdefined( game[ "gamestarted" ] ) )
	{
		game[ "menu_team" ] = "team_" + game[ "allies" ] +
								game[ "axis" ];


		game[ "menu_viewmap" ] = "viewmap";
		game[ "menu_callvote" ] = "callvote";
		game[ "menu_quickcommands" ] = "quickcommands";
		game[ "menu_quickstatements" ] = "quickstatements";
		game[ "menu_quickresponses" ] = "quickresponses";
		
		// EDIT //
		if ( !codam\utils::getVar( "endless", "wepmenu", "bool", 1|2, false ) ) {
			game[ "menu_weapon_allies" ] = "weapon_" + game[ "allies" ];
			game[ "menu_weapon_axis" ] = "weapon_" + game[ "axis" ];
		} else {
			game[ "menu_weapon_allies" ] = "weapon_" + game[ "allies" ] + game[ "axis" ];
			game[ "menu_weapon_axis" ] = "weapon_" + game[ "allies" ] + game[ "axis" ]	;
		}
		// END EDIT //
		
		precacheMenu( game[ "menu_weapon_allies" ] );
		precacheMenu( game[ "menu_weapon_axis" ] );
		precacheMenu( game[ "menu_team" ] );
		precacheMenu( game[ "menu_viewmap" ] );
		precacheMenu( game[ "menu_callvote" ] );
		precacheMenu( game[ "menu_quickcommands" ] );
		precacheMenu( game[ "menu_quickstatements" ] );
		precacheMenu( game[ "menu_quickresponses" ] );
	}

	return;
}

//
_start()
{
	codam\utils::debug( 0, "======== menu/_start" );

	return;
}

///////////////////////////////////////////////////////////////////////////////
//

//
///////////////////////////////////////////////////////////////////////////////
blockMenu( a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
			b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 )
{
	if ( !isPlayer( self ) )
		return;

	self.menuBlock = true;
	return;
}

//
///////////////////////////////////////////////////////////////////////////////
handler( menu, a1, a2, a3, a4, a5, a6, a7, a8, a9,
			b0, b1, b2, b3, b4, b5, b6, b7, b8, b9 )
{
	codam\utils::debug( 90, "menu/handler:: |", self.name, "|", menu, "|" );

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
		if ( [[ level.gtd_call ]]( "isWeaponMenu", menu ) )
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
	if ( isdefined( menu ) &&
	     ( ( menu == game[ "menu_weapon_allies" ] ) ||
	       ( menu == game[ "menu_weapon_axis" ] ) ) )
		return ( true );

	return ( false );
}

//
///////////////////////////////////////////////////////////////////////////////
