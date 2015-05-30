module des.stdx.algorithm;

public
{
    import std.array;
    import std.algorithm;
    import std.range;
    import std.traits;
}

import des.ts;

/// map and get result as array
template amap(fun...) if ( fun.length >= 1 )
{
    auto amap(Range)(Range r)
        if (isInputRange!(Unqual!Range))
    { return array( map!(fun)(r) ); }
}

///
unittest
{
    int[] res = [ 1, 2, 3 ];
    void func( int[] arr ) { res ~= arr; }
    func( amap!(a=>a^^2)(res) );
    assertEq( res, [ 1, 2, 3, 1, 4, 9 ] );
}

///
bool oneOf(E,T)( T val )
    if( is( E == enum ) )
{
    foreach( pv; [EnumMembers!E] )
        if( pv == val ) return true;
    return false;
}

///
unittest
{
    enum TestEnum
    {
        ONE = 1,
        TWO = 2,
        FOUR = 4
    }

    assert( !oneOf!TestEnum(0) );
    assert(  oneOf!TestEnum(1) );
    assert(  oneOf!TestEnum(2) );
    assert( !oneOf!TestEnum(3) );
    assert(  oneOf!TestEnum(4) );
    assert( !oneOf!TestEnum(5) );
}
