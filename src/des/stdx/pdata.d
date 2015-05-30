module des.stdx.pdata;

import std.traits;
import std.string;

import des.ts;

/// isn't array and has no unshared aliasings
template isPureData(T) { enum isPureData = !hasUnsharedAliasing!T && !isArray!T; }

///
unittest
{
    static assert(  isPureData!int );
    static assert(  isPureData!float );
    static assert(  isPureData!creal );

    static struct Vec { float x,y,z; }
    static assert(  isPureData!Vec );

    static struct Arr { int[3] data; }
    static assert(  isPureData!Arr );

    static struct Some { float f; Vec v; Arr a; }
    static assert(  isPureData!Some );

    static assert( !isPureData!string );

    static struct Bad { int[] data; }
    static assert( !isPureData!Bad );
}

/// if `T` is array returns `isPureType!(ForeachType!T)`, if `T` isn't array returns `isPureData!T`
template isPureType(T)
{
    static if( isArray!T )
        enum isPureType = isPureType!(ForeachType!T);
    else
        enum isPureType = isPureData!T;
}

///
unittest
{
    static assert(  isPureType!int );
    static assert(  isPureType!(int[]) );
    static assert(  isPureType!float );
    static assert(  isPureType!(float[]) );

    static struct Vec { float x,y,z; }
    static assert(  isPureType!Vec );

    static struct Arr { int[3] data; }
    static assert(  isPureType!Arr );

    static struct Some { float f; Vec v; Arr a; }
    static assert(  isPureType!Some );

    static assert(  isPureType!string );

    static assert(  isPureType!(const(string)) );
    static assert(  isPureType!(string[]) );

    static struct Bad { int[] data; }
    static assert( !isPureType!Bad );
}

/// is a `PData`
template isPData(T) { enum isPData = is( typeof( (( PData a ){})( T.init ) ) ); }

///
struct PData
{
    ///
    immutable(void)[] data;
    ///
    alias data this;

pure:

    ///
    this( in Unqual!(typeof(this)) pd ) { data = pd.data; }

    ///
    this(T)( in T val ) if( isPureData!T ) { data = pureDump(val); }
    ///
    this(T)( in T[] val ) if( isPureType!T ) { data = pureDump(val); }

    ///
    auto opAssign(T)( in T val ) if( isPureData!T ) { data = pureDump(val); return val; }
    ///
    auto opAssign(T)( in T[] val ) if( isPureType!T ) { data = pureDump(val); return val; }

    @property
    {
        ///
        auto as(T)() const { return pureConv!T(data); }
        ///
        auto as(T)() shared const { return pureConv!T(data); }
        ///
        auto as(T)() immutable { return pureConv!T(data); }
    }
}

unittest
{
    static assert( isPData!PData );
    static assert( isPData!(const(PData)) );
    static assert( isPData!(immutable(PData)) );
    static assert( isPData!(shared(PData)) );
    static assert( isPData!(shared const(PData)) );
    static assert( isPureData!PData );
    static assert( isPureType!PData );
}

unittest
{
    creationTest( "hello" );
    creationTest( 12.5 );
    creationTest( 12 );
    creationTest( [1,2,3] );
    creationTest( [.1,.2,.3] );

    static struct Vec { float x,y,z; }
    creationTest( Vec(1,2,3) );

    static struct Arr { int[3] data; }
    creationTest( Arr([1,2,3]) );

    static struct Some
    { float f=8; Vec v=Vec(3,4,5); Arr a=Arr([4,3,2]); }
    creationTest( Some.init );
}

unittest
{
    static struct Msg { string data; }
    auto msg = Msg("ok");

    auto a = shared PData( PData( msg ) );
    assertEq( a.as!Msg, msg );

    auto b = immutable PData( PData( [msg] ) );
    assertEq( b.as!(Msg[]), [msg] );
}

unittest
{
    static struct Bad { int[] data; }
    static assert( !__traits(compiles, PData( Bad([1,2]) ) ) );
    static assert( !__traits(compiles, PData( [Bad([1,2])] ) ) );
}

///
unittest
{
    auto a = PData( [.1,.2,.3] );
    assertEq( a.as!(double[]), [.1,.2,.3] );
    a = "hello";
    assertEq( a.as!string, "hello" );
}

unittest // Known problems
{
    static struct Msg { string data; }
    // shared or immutable PData can't create from structs or arrays with strings
    enum arr = ["a","b","c"];
    enum msg = Msg("abc");

    static assert(  __traits(compiles, PData( arr ) ) );
    static assert(  __traits(compiles, PData( msg ) ) );
    static assert(  __traits(compiles, PData( [arr] ) ) );
    static assert(  __traits(compiles, PData( [msg] ) ) );
    static assert(  __traits(compiles, const PData( arr ) ) );
    static assert(  __traits(compiles, const PData( msg ) ) );

    static assert( !__traits(compiles, shared PData( arr ) ) );
    static assert( !__traits(compiles, shared PData( msg ) ) );
    static assert( !__traits(compiles, shared PData( [arr] ) ) );
    static assert( !__traits(compiles, shared PData( [msg] ) ) );
    static assert(  __traits(compiles, shared PData( PData( arr ) ) ) );
    static assert(  __traits(compiles, shared PData( PData( msg ) ) ) );

    static assert( !__traits(compiles, shared const PData( arr ) ) );
    static assert( !__traits(compiles, shared const PData( msg ) ) );
    static assert( !__traits(compiles, shared const PData( [arr] ) ) );
    static assert( !__traits(compiles, shared const PData( [msg] ) ) );
    static assert(  __traits(compiles, shared const PData( PData( arr ) ) ) );
    static assert(  __traits(compiles, shared const PData( PData( msg ) ) ) );

    static assert( !__traits(compiles, immutable PData( arr ) ) );
    static assert( !__traits(compiles, immutable PData( msg ) ) );
    static assert( !__traits(compiles, immutable PData( [arr] ) ) );
    static assert( !__traits(compiles, immutable PData( [msg] ) ) );
    static assert(  __traits(compiles, immutable PData( PData( arr ) ) ) );
    static assert(  __traits(compiles, immutable PData( PData( msg ) ) ) );
}

private version(unittest)
{
    void asTest(A,B)( in A val, in B orig )
    {
        if( isPData!B ) return;

        assertEq( (PData(val)).as!B,              orig );
        assertEq( (const PData(val)).as!B,        orig );
        assertEq( (immutable PData(val)).as!B,    orig );
        assertEq( (shared PData(val)).as!B,       orig );
        assertEq( (shared const PData(val)).as!B, orig );
    }

    void creationTest(T)( in T val )
    {
        asTest( val, val );

        auto a = PData( val );
        auto ac = const PData( val );
        auto ai = immutable PData( val );
        auto as = shared PData( val );
        auto asc = shared const PData( val );

        asTest( a, val );
        asTest( ac, val );
        asTest( ai, val );
        asTest( as, val );
        asTest( asc, val );
    }
}

auto pureConv(T)( in immutable(void)[] data ) pure
{
    static if( isPureData!T )
        return (cast(T[])(data.dup))[0];
    else static if( isPureType!T )
        return cast(T)(data.dup);
    else static assert( 0, format( "unsuported type %s", T.stringof ) );
}

immutable(void)[] pureDump(T)( in T val ) pure
{
    static assert( !is( T == void[] ) );
    static if( isArray!T ) return (cast(void[])val).idup;
    else return (cast(void[])[val]).idup;
}
