#using scripts\codescripts\struct;
#using scripts\shared\array_shared;
#using scripts\shared\system_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_zm_utility;



/*
    Please Credit if you use this: 
    Coolyer


    Add this to your zone
    fx,explosions/fx_exp_grenade_default
    fx,dlc5/sumpf/fx_perk_lottery_end
    fx,dlc5/sumpf/fx_perk_lottery_front
    fx,dlc5/sumpf/fx_perk_lottery_flash
    scriptparsetree,scripts/zm/zm_perk_rain.gsc
*/

#define PERK_RAIN_HEIGHT           2500
#define PERK_RAIN_SLAM_TIME        0.9
#define PERK_RAIN_STAGGER          0.35
#define PERK_RAIN_SOUND_SLAM       "evt_nuke_flash" // change this to your custom perk slam sound if you have one
#define PERK_BOTTLE_HIT_SOUND      "bottles_multiple" // change this to your custom perk bottle hit sound if you have one

#define PERK_RAIN_WOBBLE_HEIGHT    40
#define PERK_RAIN_WOBBLE_TIME      1.0
#define PERK_RAIN_WOBBLE_ACCEL     0.3
#define PERK_RAIN_WOBBLE_DECEL     0.2 // change this to your custom wobble accel and decel
#define PERK_RAIN_VIBRATE_INTENSITY 1.2 // change this to your custom vibrate intensity
#define PERK_RAIN_VIBRATE_FREQ     0.8 // change this to your custom  vibrate frequency
#define PERK_RAIN_VIBRATE_TIME     1.0

// 0 = every round all slam together & will shuffle depending on min and max || 1 = one perk per min and max rounds until all placed
#define PERK_RAIN_MODE             0
#define PERK_RAIN_INTERVAL_MIN     1
#define PERK_RAIN_INTERVAL_MAX     2

#define PERK_RAIN_LOTTERY_FX_FRONT  "dlc5/sumpf/fx_perk_lottery_front"
#define PERK_RAIN_LOTTERY_FX_END    "dlc5/sumpf/fx_perk_lottery_end"
#define PERK_RAIN_LOTTERY_FX_FLASH  "dlc5/sumpf/fx_perk_lottery_flash"
#define PERK_RAIN_LOTTERY_FX_GRENADE "explosions/fx_exp_grenade_default"
#precache( "fx", PERK_RAIN_LOTTERY_FX_FRONT );
#precache( "fx", PERK_RAIN_LOTTERY_FX_END );
#precache( "fx", PERK_RAIN_LOTTERY_FX_FLASH );
#precache( "fx", PERK_RAIN_LOTTERY_FX_GRENADE );

function autoexec __init__sytem__()
{
    system::register( "zm_perk_rain", &__init__, undefined, undefined );
}

function __init__()
{
    level thread perk_rain_init();
}
function perk_rain_get_lottery_fx( perk_str )
{
    perk_low = ToLower( perk_str );
    // if you wish to add custom perk fx remove the comment block below 
    // and add your perk name and fx path dont forget to precache the fx at the top of this file
    // and in the zone.
    /* <- remove this comment to enable custom perk fx
    
    if ( IsSubStr( perk_low, "specialty_quickrevive" ) )
        return "dlc5/sumpf/fx_perk_lottery_front_blue";
    if ( IsSubStr( perk_low, "specialty_doubletap2" ) )
        return "dlc5/sumpf/fx_perk_lottery_front_orange";
    if ( IsSubStr( perk_low, "specialty_armorvest" ) )
        return "dlc5/sumpf/fx_perk_lottery_front_red";
    if ( IsSubStr( perk_low, "specialty_fastreload" ) )
        return "dlc5/sumpf/fx_perk_lottery_front_green";
    */ 
    // default perk fx can change
    return PERK_RAIN_LOTTERY_FX_FRONT;
}
// ---------------------------------------------------------------------------
// Init
// ---------------------------------------------------------------------------
function perk_rain_init()
{
    level waittill( "initial_blackscreen_passed" );

    perk_locs = struct::get_array( "zm_perk_machine", "targetname" );
    if ( perk_locs.size > 0 )
    {
        valid_locs = [];
        perk_names = [];
        foreach ( loc in perk_locs )
        {
            if ( !isdefined( loc.script_noteworthy ) )
                continue;
            valid_locs[ valid_locs.size ] = loc;
            perk_names[ perk_names.size ] = loc.script_noteworthy;
        }
        if ( perk_names.size > 0 )
        {
            shuffled = array::randomize( perk_names );
            for ( i = 0; i < valid_locs.size; i++ )
                valid_locs[ i ].script_noteworthy = shuffled[ i % shuffled.size ];
        }
        machines = [];
        foreach ( loc in valid_locs )
        {
            trig = GetEnt( loc.script_noteworthy, "script_noteworthy" );
            if ( isdefined( trig ) && isdefined( trig.machine ) )
                machines[ machines.size ] = trig.machine;
            else if ( isdefined( trig ) )
                machines[ machines.size ] = trig;
        }
        if ( machines.size == 0 )
            machines = GetEntArray( "perk_machine", "targetname" );
    }

    if ( machines.size == 0 )
    {
        IPrintLnBold( "^1Perk Rain: no perk machines found" );
        return;
    }

    spots = struct::get_array( "perk_spot", "targetname" );
    if ( spots.size == 0 )
    {
        spots = [];
        foreach ( m in machines )
        {
            s = spawnstruct();
            s.origin = m.origin;
            s.angles = m.angles;
            spots[ spots.size ] = s;
        }
    }

    foreach ( m in machines )
    {
        m EnableLinkTo();
        trig = undefined;
        if ( isdefined( m.target ) )
            trig = GetEnt( m.target, "targetname" );
        if ( !isdefined( trig ) )
        {
            trigs = GetEntArray( "zombie_vending", "targetname" );
            closest = undefined;
            best = 999999;
            foreach ( t in trigs )
            {
                d = DistanceSquared( t.origin, m.origin );
                if ( d < best )
                {
                    best = d;
                    closest = t;
                }
            }
            trig = closest;
        }
        if ( isdefined( trig ) )
        {
            trig EnableLinkTo();
            trig LinkTo( m );
            m.perk_rain_trig = trig;
        }
    }

    if ( PERK_RAIN_MODE == 1 )
    {
        level.perk_rain_placed = 0;
        level.perk_rain_total = machines.size;
        foreach ( m in machines )
        {
            if ( !isdefined( m ) )
                continue;
            perk_rain_wobble_up( m, m.origin );
            wait 0.1;
        }
    }
    else
    {
        foreach ( m in machines )
        {
            if ( !isdefined( m ) )
                continue;
            perk_rain_trig_enable( m, 0 );
        }
    }

    wait 2;
    level thread perk_rain_initial_slam( machines, spots );
    level thread perk_rain_loop( machines, spots );
}

// ---------------------------------------------------------------------------
// Initial slam
// ---------------------------------------------------------------------------
function perk_rain_initial_slam( machines, spots )
{
    shuffled_spots = array::randomize( spots );
    shuffled_machines = array::randomize( machines );

    if ( PERK_RAIN_MODE == 1 )
    {
        level.perk_rain_order = shuffled_machines;
        level.perk_rain_spot_order = shuffled_spots;
        m = shuffled_machines[ 0 ];
        dest = shuffled_spots[ 0 ].origin + ( 0, 0, 2 );
        if ( isdefined( m ) )
            perk_rain_slam_down( m, dest );
        level.perk_rain_placed = 1;
        return;
    }

    dests = [];
    angs = [];
    for ( i = 0; i < shuffled_machines.size; i++ )
    {
        spot = shuffled_spots[ i % shuffled_spots.size ];
        dests[ dests.size ] = spot.origin + ( 0, 0, 2 );
        angs[ angs.size ] = spot.angles;
    }

        for ( i = 0; i < shuffled_machines.size; i++ )
        {
            m = shuffled_machines[ i ];
            if ( !isdefined( m ) )
                continue;
            perk_rain_wobble_up( m, dests[ i ], angs[ i ] );
            wait 0.25;
        }

        wait 0.5;

        for ( i = 0; i < shuffled_machines.size; i++ )
        {
            m = shuffled_machines[ i ];
            if ( !isdefined( m ) )
                continue;
            perk_rain_slam_down( m, dests[ i ] );
            wait PERK_RAIN_STAGGER;
        }
    }

// ---------------------------------------------------------------------------
// Bottle burst
// ---------------------------------------------------------------------------
function perk_rain_bottle_burst( origin, machine )
{
    if ( !isdefined( level._custom_perks ) )
        return;
    perk_for_machine = perk_rain_get_perk_str( machine );
    perks = GetArrayKeys( level._custom_perks );
    if ( perks.size == 0 )
        return;
    for ( b = 0; b < 4; b++ )
    {
        perk = perk_for_machine;
        if ( !isdefined( perk ) || !isdefined( level._custom_perks[ perk ] ) )
            perk = perks[ RandomInt( perks.size ) ];
        bottle_weapon = level._custom_perks[ perk ].perk_bottle_weapon;
        if ( !isdefined( bottle_weapon ) )
            continue;
        model_name = undefined;
        if ( isdefined( bottle_weapon.worldModel ) )
            model_name = bottle_weapon.worldModel;
        else if ( isdefined( bottle_weapon.model ) )
            model_name = bottle_weapon.model;
        if ( !isdefined( model_name ) )
            continue;
        bottle = spawn( "script_model", origin + ( 0, 0, 15 ) );
        if ( !isdefined( bottle ) )
            continue;
        bottle setModel( model_name );
        bottle.angles = ( 0, RandomInt( 360 ), 0 );
        bottle thread perk_rain_bottle_fade();
        dir = ( RandomIntRange( -80, 80 ), RandomIntRange( -80, 80 ), RandomIntRange( 50, 80 ) );
        bottle MoveTo( origin + dir, 0.25, 0.05, 0.05 );
        bottle RotateVelocity( ( RandomIntRange( -720, 720 ), RandomIntRange( -720, 720 ), RandomIntRange( -720, 720 ) ), 0.6 );
        wait 0.05;
    }
}

function perk_rain_bottle_fade()
{
    wait 0.3;
    if ( !isdefined( self ) )
        return;
    trace = GroundTrace( self.origin + ( 0, 0, 20 ), self.origin + ( 0, 0, -200 ), false, undefined, false );
    ground = self.origin;
    if ( isdefined( trace ) && trace[ "fraction" ] < 1 )
        ground = trace[ "position" ];
    self MoveTo( ground + ( 0, 0, 2 ), 0.35, 0.1, 0.05 );
    wait 0.35;
    wait 2.0;
    if ( isdefined( self ) )
        self Delete();
}

// ---------------------------------------------------------------------------
// Main loop
// ---------------------------------------------------------------------------
function perk_rain_loop( machines, spots )
{
    level endon( "game_ended" );
    next_shuffle = level.round_number + RandomIntRange( PERK_RAIN_INTERVAL_MIN, PERK_RAIN_INTERVAL_MAX );

    while ( 1 )
    {
        level waittill( "between_round_over" );

        if ( PERK_RAIN_MODE == 1 )
        {
            if ( level.perk_rain_placed >= level.perk_rain_total )
                return;
            if ( level.round_number < next_shuffle )
                continue;
            next_shuffle = level.round_number + RandomIntRange( PERK_RAIN_INTERVAL_MIN, PERK_RAIN_INTERVAL_MAX );
            wait 1.5;

            idx = level.perk_rain_placed;
            m = level.perk_rain_order[ idx ];
            spot = level.perk_rain_spot_order[ idx % level.perk_rain_spot_order.size ];
            dest = spot.origin + ( 0, 0, 2 );

            if ( !isdefined( m ) )
            {
                level.perk_rain_placed++;
                continue;
            }

            perk_rain_wobble_up( m, dest, spot.angles );
            wait 0.5;
            perk_rain_slam_down( m, dest );
            level.perk_rain_placed++;
            continue;
        }

        if ( level.round_number < next_shuffle )
            continue;
        next_shuffle = level.round_number + RandomIntRange( PERK_RAIN_INTERVAL_MIN, PERK_RAIN_INTERVAL_MAX );
        wait 1.5;

        shuffled_spots = array::randomize( spots );
        shuffled_machines = array::randomize( machines );
        dests = [];
        angs = [];
        for ( i = 0; i < shuffled_machines.size; i++ )
        {
            dests[ dests.size ] = shuffled_spots[ i % shuffled_spots.size ].origin + ( 0, 0, 2 );
            angs[ angs.size ] = shuffled_spots[ i % shuffled_spots.size ].angles;
        }

        for ( i = 0; i < shuffled_machines.size; i++ )
        {
            m = shuffled_machines[ i ];
            if ( !isdefined( m ) )
                continue;
            perk_rain_wobble_up( m, dests[ i ], angs[ i ] );
            wait 0.25;
        }

        wait 0.5;

        for ( i = 0; i < shuffled_machines.size; i++ )
        {
            m = shuffled_machines[ i ];
            if ( !isdefined( m ) )
                continue;
            perk_rain_slam_down( m, dests[ i ] );
            wait PERK_RAIN_STAGGER;
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers / Code reducers
// ---------------------------------------------------------------------------
function perk_rain_get_live_machine( m )
{
    if ( !isdefined( m ) )
        return undefined;
    if ( isdefined( m ) && isdefined( m.targetname ) )
    {
        all = GetEntArray( m.targetname, "targetname" );
        if ( all.size > 0 )
            return all[0];
    }
    perk_str = perk_rain_get_perk_str( m );
    if ( perk_str != "" && isdefined( level._custom_perks[ perk_str ] ) && isdefined( level._custom_perks[ perk_str ].radiant_machine_name ) )
    {
        all = GetEntArray( level._custom_perks[ perk_str ].radiant_machine_name, "targetname" );
        if ( all.size > 0 )
            return all[0];
    }
    return m;
}

function perk_rain_wobble_up( m, dest, angles )
{
    m = perk_rain_get_live_machine( m );
    if ( !isdefined( m ) )
        return;
    perk_rain_stop_anim( m );
    m MoveTo( m.origin + ( 0, 0, PERK_RAIN_WOBBLE_HEIGHT ), PERK_RAIN_WOBBLE_TIME, PERK_RAIN_WOBBLE_ACCEL, PERK_RAIN_WOBBLE_DECEL );
    m Vibrate( m.angles, PERK_RAIN_VIBRATE_INTENSITY, PERK_RAIN_VIBRATE_FREQ, PERK_RAIN_VIBRATE_TIME );
    perk_rain_play_lottery_fx( m );
    PlaySoundAtPosition( "zmb_start_perk_machine", m.origin );
    perk_rain_trig_enable( m, 0 );
    wait 0.7;
    PlayFX( PERK_RAIN_LOTTERY_FX_FLASH, m.origin );
    wait 0.3;
    perk_rain_hide( m );
    m.origin = dest + ( 0, 0, PERK_RAIN_HEIGHT );
    if ( isdefined( angles ) )
        m.angles = angles;
}

function perk_rain_slam_down( m, dest )
{
    m = perk_rain_get_live_machine( m );
    if ( !isdefined( m ) )
        return;
    perk_rain_show( m );
    m Vibrate( dest, 0.2, 0.3, PERK_RAIN_SLAM_TIME );
    m MoveTo( dest, PERK_RAIN_SLAM_TIME, 0.2, 0.05 );
    wait PERK_RAIN_SLAM_TIME;
    perk_rain_slam_impact( dest, m );
    perk_rain_trig_enable( m, 1 );
}

function perk_rain_trig_enable( m, enable )
{
    if ( isdefined( m.perk_rain_trig ) )
        m.perk_rain_trig TriggerEnable( enable );
}



function perk_rain_get_perk_str( m )
{
    if ( !isdefined( m ) )
        return "";
    if ( isdefined( m.script_noteworthy ) )
        return m.script_noteworthy;
    if ( isdefined( m.perk_rain_trig ) && isdefined( m.perk_rain_trig.script_noteworthy ) )
        return m.perk_rain_trig.script_noteworthy;
    return "";
}

function perk_rain_play_lottery_fx( m )
{
    fx = perk_rain_get_lottery_fx( perk_rain_get_perk_str( m ) );
    PlayFXOnTag( fx, m, "tag_origin" );
}

function perk_rain_show( m )
{
    m Show();
    if ( isdefined( m.perk_rain_trig ) )
    {
        if ( isdefined( m.perk_rain_trig.bump ) ) m.perk_rain_trig.bump Show();
        if ( isdefined( m.perk_rain_trig.clip ) ) m.perk_rain_trig.clip Show();
    }
}

function perk_rain_hide( m )
{
    m Hide();
    if ( isdefined( m.perk_rain_trig ) )
    {
        if ( isdefined( m.perk_rain_trig.bump ) ) m.perk_rain_trig.bump Hide();
        if ( isdefined( m.perk_rain_trig.clip ) ) m.perk_rain_trig.clip Hide();
    }
}

function perk_rain_stop_anim( m )
{
    if ( !isdefined( m ) )
        return;
    if ( isdefined( m ) )
        m Notify( "stopMachineFXAnim" );
    if ( isdefined( m ) && m IsPlayingAnimScripted() )
        m StopAnimScripted( 0, true );
}

function perk_rain_slam_impact( dest, machine )
{
    PlayFX( PERK_RAIN_LOTTERY_FX_GRENADE, dest + ( 0, 0, 5 ) );
    PlayFX( PERK_RAIN_LOTTERY_FX_END, dest + ( 0, 0, 10 ) );
    PlaySoundAtPosition( PERK_RAIN_SOUND_SLAM, dest );
    PlaySoundAtPosition( PERK_BOTTLE_HIT_SOUND, dest + ( 0, 0, 2 ) );
    PlaySoundAtPosition( "wpn_grenade_explode", dest );
    Earthquake( 0.85, 1.2, dest, 400 );
    level thread perk_rain_bottle_burst( dest, machine );
}
