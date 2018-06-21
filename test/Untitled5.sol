pragma solidity ^0.4.19;

contract AnalystRegistry {

    // reward types
    uint8 constant REWARD_REFERRAL = 1;

    uint8 constant REWARD_ROUND_TOKENS_WINNER = 2;
    uint8 constant REWARD_ROUND_TOKENS_LOSER = 3;
    uint8 constant REWARD_ROUND_TOKENS_JURY_TOP = 4;
    uint8 constant REWARD_ROUND_TOKENS_JURY_MIDDLE = 5;
    uint8 constant REWARD_ROUND_TOKENS_JURY_BOTTOM = 6;
    uint8 constant REWARD_REFERRAL_TOKENS = 7;

    uint8 constant REWARD_ROUND_POINTS_WINNER = 8;
    uint8 constant REWARD_ROUND_POINTS_LOSER = 9;
    uint8 constant REWARD_ROUND_POINTS_JURY_TOP = 10;
    uint8 constant REWARD_ROUND_POINTS_JURY_MIDDLE = 11;
    uint8 constant REWARD_ROUND_POINTS_JURY_BOTTOM = 12;
    uint8 constant REWARD_ROUND_POINTS_NEGATIVE = 13;

    uint8 constant REWARD_BONUS = 19;
    uint8 constant REWARD_PROMOTION = 20;

    uint8 constant REFERRALS_DEFAULT = 5;
    
    // payoffs
    uint8 constant WINNER_PCT = 40;
    uint8 constant LOSER_PCT = 10;
    uint8 constant TOP_JURISTS_X10 = 34;   // percentages * 10   ... level:0
    uint8 constant MIDDLE_JURISTS_X10 = 17;   // level:1
    uint8 constant BOTTOM_JURISTS_X10 = 0;    // level:2
    int8 constant WINNER_POINTS = 50;
    int8 constant LOSER_POINTS = 10;
    int8 constant NEGATIVE_RATING = -100;
    int8 constant TOP_JURISTS_POINTS = 10;
    int8 constant MIDDLE_JURISTS_POINTS = 4;
    int8 constant BOTTOM_JURISTS_POINTS = 0;

    uint8 constant REFERRAL_POINTS = 0; 
    
    uint32 constant LEAD_LEVEL = 2;
    uint16[2][] public levels;

    struct RewardEvent {
        uint8 reward_type;
        uint256 timestamp;
        int32 value;
        uint32 ref; // may be round, cycle, analyst, depends on event
    }
    
    struct Referral {
        uint256 timestamp;
        uint256 reg_timestamp;
        bytes32 email;
        uint32 analyst;
        address identity;
        bytes32 regcode;
    }

    struct Analyst {
        //string firstname;
        bytes32 name;
        bytes32 password;
        bytes32 email;
        uint32 auth_status;  // user authentication status
        uint32 referred_by; // analyst that referred me
        address user_addr;
        address identity;   // generated identity based on ethereumjs-wallet
        bool is_lead;
        int32 points;
        //uint32 points;
        uint32 token_balance;
        uint8 referral_balance;
        
        //uint16 num_rounds_scheduled;
        uint16 num_rounds_active;
        uint16 num_rounds_finished;
        uint16 num_reward_events;
        uint16 num_referrals;

        //mapping ( uint16 => uint16 ) rounds_confirmed;
        mapping ( uint16 => uint16 ) rounds_active;
        mapping ( uint16 => uint16 ) rounds_finished;
        mapping ( uint16 => RewardEvent ) reward_events;
        mapping ( uint16 => Referral ) referrals;
    }
    mapping ( uint32 => Analyst ) analysts;
    mapping ( address => uint32 ) address_lookup;
    mapping ( bytes32 => address ) identity_lookup; // gives identity based on regcode
    mapping ( address => uint32 ) referrals;    // gives referring analyst based on identity
    mapping ( bytes32 => uint32 ) name_lookup;
    
    uint32 public num_analysts;

    mapping (uint32 => uint32) leads;
    uint32 public num_leads;

    uint256 timenow;
    function update(uint256 _timenow) public { timenow = _timenow; }

    constructor() public {
        levels.push( [  0, 2] );
        levels.push( [ 10, 4] );
        levels.push( [ 50, 6] ); // LEAD_LEVEL
        levels.push( [100,10] );
        levels.push( [200,20] );
        levels.push( [500,30] );
        bootstrap(14,4);
    }

    function activateRound( uint32 _analyst, uint16 _round ) public {
        Analyst storage a = analysts[ _analyst ];
        a.rounds_active[ a.num_rounds_active++ ] = _round;
    }

    function activeRound( uint32 _analyst, uint8 _roundRef ) public view returns ( uint16 ) {
        return analysts[ _analyst ].rounds_active[ _roundRef ];
    }
    
    function analystInfo( uint32 _analyst ) public view returns (
        uint32, bytes32, uint32, uint32,
        int32, bool, uint32, uint8,
        uint16, uint16, 
        uint16, uint16
    ) {
        Analyst storage a = analysts[ _analyst ];
        return (
            _analyst, a.email, a.auth_status, a.referred_by,
            a.points, a.is_lead, a.token_balance, a.referral_balance, 
            a.num_rounds_active, a.num_rounds_finished,
            a.num_reward_events,a.num_referrals
        );
    }

    function findLevel( int32 _points ) public view returns (uint8) {
        for (uint8 i = 1; i < levels.length; i++ ) {
            if ( levels[i-1][0] <= _points && levels[i][0] > _points ) return i-1;
        }        
        return ( uint8( levels.length - 1 ) );
    }
    
    function finishRound( uint32 _analyst, uint16 _round ) public {
        Analyst storage a = analysts[ _analyst ];
        for( uint16 i = 0; i < a.num_rounds_active; i++ ) {
            if (a.rounds_active[ i ] == _round ){
                a.rounds_finished[ a.num_rounds_finished++ ] = _round;
                while ( i++ < a.num_rounds_active - 1 ){
                    a.rounds_active[ i - 1 ] = a.rounds_active[ i ];
                }
                a.num_rounds_active--;
                return;
            }
        }
        require(false); // error, called without active round
    }
    
    function finishedRound( uint32 _analyst, uint8 _roundRef ) public view returns ( uint16 ) {
        return analysts[ _analyst ].rounds_finished[ _roundRef ];
    }
    
    function getAnalyst( address _user ) public constant returns (uint32 id) {
        id = address_lookup[_user];
    }

    function getAddress( uint32 _analystid ) public constant returns (address) { // sequential ids
        return analysts[_analystid].user_addr;
    }

    function getAnalystEvent( uint32 _analyst, uint16 _event ) public view returns ( uint8, uint256, int32, uint32 ) {
        RewardEvent storage e = analysts[ _analyst ].reward_events[ _event ];
        return ( e.reward_type, e.timestamp, e.value, e.ref );
    }

    function isLead( uint32 _analyst ) public view returns (bool){
        return( analysts[ _analyst ].points >= levels[LEAD_LEVEL][0] );
    }

    function login(bytes32 _email, bytes32 _pw) public view returns ( uint32, bytes32, int32, uint32 ) {
        uint32 id = name_lookup[ _email ];
        Analyst storage analyst = analysts[ id ];
        require( analyst.password == _pw );
        return ( id, analyst.email, analyst.points, analyst.token_balance );
    }

    function loginByAddress(bytes32 _password, address force) public view returns ( uint32 id ) { // force is for testing, so can login with another address
        id = address_lookup[ force == 0 ? msg.sender : force ];
        require(analysts[id].password == _password);
    }

    function referralInfo( uint32 _analyst, uint16 _referral ) public view returns ( 
        uint256, uint256, bytes32, uint32 
    ) {
        Referral storage r = analysts[ _analyst ].referrals[_referral];
        return ( r.timestamp, r.reg_timestamp, r.email, r.analyst ); 
    }
    
    function referralInfoByRegCode( bytes32 _regcode ) public view returns (
        uint256, uint256, bytes32, uint32     
    ) {
        address identity = identity_lookup[ _regcode ];
        require( identity != 0 );
        uint32 referring_analyst = referrals[ identity ];
        Analyst storage a = analysts[ referring_analyst ];
        for( uint16 i = 0; i < a.num_referrals; i++ ){
            if ( a.referrals[ i ].identity == identity ) return referralInfo( referring_analyst, i );
        }
        require( false );
    }

    function referralSubmit( uint32 _analyst, bytes32 _email, address _identity, bytes32 _regcode ) public {
        Analyst storage a = analysts[ _analyst ]; 
        require( a.referral_balance-- > 0 );
        Referral storage r = a.referrals[ a.num_referrals++ ];
        r.timestamp = timenow;
        r.email = _email;
        r.identity = _identity;
        r.regcode = _regcode;
        identity_lookup[ _regcode ] = _identity;
        referrals[ _identity ] = _analyst;
    }
    
    function referredBy( uint32 _analyst ) public view returns ( uint32 ) {
        return analysts[ _analyst ].referred_by;
    }
 
    event Register( uint32 id, bytes32 email, bytes32 regcode, address identity );
    function register( bytes32 _email, bytes32 _pw, bytes32 _regcode ) public {
        Analyst storage a = analysts[ num_analysts ];
        a.password = _pw;
        a.email = _email;
        //a.referred_by = _referral;
        a.user_addr = msg.sender;
        a.is_lead = false;
        a.referral_balance = REFERRALS_DEFAULT;

        
        if ( _regcode > 0 ){
            a.identity = identity_lookup[ _regcode ];
            require( a.identity != 0 );
            Analyst storage referred_by = analysts[ referrals[ a.identity ] ];
            require( referred_by.num_referrals > 0 );
            for (uint8 i = 0; i < referred_by.num_referrals; i++ ) {
                if (referred_by.referrals[ i ].email == _email) {
                    referred_by.points += REFERRAL_POINTS;
                    referred_by.reward_events[ referred_by.num_reward_events++ ] =
                        RewardEvent( REWARD_REFERRAL, timenow, REFERRAL_POINTS, num_analysts );
                    break;
                }
            }
            require( i != referred_by.num_referrals ); // referral not found, invalid
        }
        address_lookup[ msg.sender ] = num_analysts;
        name_lookup[ _email ] = num_analysts;

        emit Register( num_analysts++, _email, _regcode, a.identity );
    }

    // move these two to agency contract
    function rewardJurist( uint32 _analyst, uint16 _round, uint32 _roundValue, uint8 _level ) public {
        if (_level == 0) {
            rewardToken( _analyst, REWARD_ROUND_TOKENS_JURY_TOP, _roundValue * TOP_JURISTS_X10 / 1000, _round );
            rewardPoints( _analyst, REWARD_ROUND_POINTS_JURY_TOP, TOP_JURISTS_POINTS, _round );
        } else if ( _level == 1 ) {
            rewardToken( _analyst, REWARD_ROUND_TOKENS_JURY_MIDDLE, _roundValue * MIDDLE_JURISTS_X10 / 1000, _round );
            rewardPoints( _analyst, REWARD_ROUND_POINTS_JURY_MIDDLE, MIDDLE_JURISTS_POINTS, _round );
        } else {
            rewardToken( _analyst, REWARD_ROUND_TOKENS_JURY_BOTTOM, _roundValue * BOTTOM_JURISTS_X10 / 1000, _round );
            rewardPoints( _analyst, REWARD_ROUND_POINTS_JURY_BOTTOM, BOTTOM_JURISTS_POINTS, _round );
        }
    }

    function rewardLead( uint32 _analyst, uint16 _round, uint32 _roundValue, int8 _win ) public {
        if ( _win == 1 ) {
            rewardToken( _analyst, REWARD_ROUND_TOKENS_WINNER, _roundValue * WINNER_PCT / 100, _round);
            rewardPoints( _analyst, REWARD_ROUND_POINTS_WINNER, WINNER_POINTS, _round );
        } else if ( _win == 0 ) {
            rewardToken( _analyst, REWARD_ROUND_TOKENS_LOSER, _roundValue * LOSER_PCT / 100, _round );
            rewardPoints( _analyst, REWARD_ROUND_POINTS_LOSER, LOSER_POINTS, _round );
        } else { // Complaints about analyst, punishment
            rewardPoints( _analyst, REWARD_ROUND_POINTS_NEGATIVE, NEGATIVE_RATING, _round );
        }
    }



    function rewardPoints(  uint32 _analyst, uint8 _rewardType, int32 _value, uint32 _ref ) public {
        Analyst storage a = analysts[ _analyst ];
        uint8 old_level = findLevel( a.points );
        a.points += _value;
        uint8 new_level = findLevel( a.points );
        a.reward_events[ a.num_reward_events++ ] =
            RewardEvent( _rewardType, timenow, _value, _ref );
        if ( old_level != new_level ) {
            if ( !a.is_lead && new_level >= LEAD_LEVEL ) {
                a.is_lead = true;
                leads[ num_leads++ ] = _analyst;
            }
            a.reward_events[ a.num_reward_events++ ] =
                RewardEvent( REWARD_PROMOTION, timenow, 0, new_level );
            a.referral_balance += uint8( levels[new_level][1] - a.num_referrals );
        }
    }
    
    function rewardToken( uint32 _analyst, uint8 _rewardType, uint32 _value, uint32 _ref ) public {
        Analyst storage a = analysts[ _analyst ];
        a.reward_events[ a.num_reward_events++ ] =
            RewardEvent( _rewardType, timenow, int32(_value), _ref );
        a.token_balance += _value;
        if (a.referred_by != 0) {
            // Pay referrees
            rewardToken( a.referred_by, REWARD_REFERRAL_TOKENS, _value / 5, _ref );
        }        
    }

    /* utilities */
    function bytesOntoBytes32( bytes32 b32, byte[32] b, uint8 start, uint8 length ) private pure returns ( bytes32 out ) {
        out = b32;
        for (uint8 i = 0; i < length; i++)
            out |= bytes32(b[ i ]) >> ( (i+start) * 8);
    }
    /*
    function bytesToBytes32(bytes b) private pure returns (bytes32 out) {
        for (uint i = 0; i < 32; i++)
            out |= bytes32(b[ i ] & 0xFF) >> (i * 8);
    }
    */
    
    /* testing */ 

    /* create some analysts */
    function bootstrap(uint16 _numanalysts, uint16 _numleads) public {
        uint16 new_analysts = _numanalysts == 0 ? 12 : _numanalysts;
        uint16 new_leads = _numleads == 0 ? 2 : _numleads;
        uint16 start = uint16( num_analysts );
        uint16 finish = start + new_analysts;
        bytes32 b32 = 'veva\0\0@veva.one';
        byte[32] memory b;
        for(uint16 i = start; i < finish; i++) {
            b[0] = byte( i / 10 + 0x30 );
            b[1] = byte( i % 10 + 0x30 );
            bytes32 email = bytesOntoBytes32( b32, b, 4, 2 );
            register( email, 'veva', 0); // make up phony name based on id
            if ( new_leads > 0 ) {
                rewardPoints( i, REWARD_BONUS, levels[LEAD_LEVEL][0], LEAD_LEVEL);
                new_leads--;
            }
        }
    }


}