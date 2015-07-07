  //	EndlessMapvote v1.0   //
 //		AUTHOR: Indy		 //
//////////////////////////////

main( phase, register )
{
	codam\utils::debug( 0, "======== endless_mapvote/main:: |", phase, "|", register, "|" );

	if ( getCvar("psv_mapvote_time") == "" || getCvarInt("psv_mapvote_time") == 0 )
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
	codam\utils::debug( 0, "======== endless_mapvote/_init:: |", register, "|" );
	
	codam\psv_vote::precache();
	
	return;
}

_load()
{
	codam\utils::debug( 0, "======== endless_mapvote/_load" );

	return;
}

_start()
{
	codam\utils::debug( 0, "======== endless_mapvote/_start" );

	return;
}

//
///////////////////////////////////////////////////////////////////////////////
