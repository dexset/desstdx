module des.stdx.range;

public import std.range;

import std.conv;
import std.algorithm;

import des.stdx.traits;
import des.ts;

/++ fill output range with flat values
 +/
void fillFlat(T,R,V,E...)( ref R output, V val, E tail ) pure
    if( isOutputRange!(R,T) )
{
    static if( E.length > 0 )
    {
        fillFlat!T( output, val );
        fillFlat!T( output, tail );
    }
    else
    {
        static if( isInputRange!V )
            foreach( l; val ) fillFlat!T( output, l );
        else static if( canUseAsArray!V )
            foreach( i; 0 .. val.length )
                fillFlat!T( output, val[i] );
        else
            output.put( to!T(val) );
    }
}

///
unittest
{
    static struct Vec { float[3] data; alias data this; }
    static assert( canUseAsArray!Vec );

    import std.array;

    auto app = appender!(int[])();
    fillFlat!int( app, [1,2], 3,
                       [[4,5],[6]],
                       iota(7,9),
                       [[[9],[10,11]],[[12]]],
                       Vec([13.3,666,105]) );
    assertEq( app.data, [1,2,3,4,5,6,7,8,9,10,11,12,13,666,105] );
}

/++ get flat length of values
 +/
size_t getFlatLength(V,E...)( V val, E tail ) pure nothrow @nogc
{
    static if( E.length > 0 )
        return getFlatLength( val ) + getFlatLength( tail );
    else
    {
        static if( isInfinite!V )
            static assert( 0, "not support infinite range" );
        else static if( isForwardRange!V )
            return val.save().map!(a=>getFlatLength(a)).sum;
        else static if( canUseAsArray!V )
        {
            size_t s = 0;
            foreach( i; 0 .. val.length )
                s += getFlatLength( val[i] );
            return s;
        }
        else static if( is( ElementType!V == void ) )
            return 1;
        else static assert( 0, "unsupported type" );
    }
}

///
unittest
{
    static struct Vec { float[3] data; alias data this; }

    assertEq( getFlatLength( 1,2,3 ), 3 );
    assertEq( getFlatLength( [1,2,3] ), 3 );
    assertEq( getFlatLength( Vec([1,2,3]) ), 3 );
    assertEq( getFlatLength( [1,2], 3, [[[4],[5,6]],[[7,8,9]]], Vec([1,2,3]) ), 12 );
    assertEq( getFlatLength( 1, 2, iota(4) ), 6 );
    assertEq( getFlatLength( 1, 2, iota(4) ), 6 );
}

/// return output range with reference to array
auto arrayOutputRange(A)( ref A arr )
    if( isArray!A || isStaticArray!A )
{
    alias T = ElementType!A;

    static struct Result
    {
        T* end, cur;

        this( T* start, T* end )
        {
            this.cur = start;
            this.end = end;
        }

        void put( T val )
        {
            assert( cur != end );
            *(cur++) = val;
        }
    }

    return Result( arr.ptr, arr.ptr + arr.length );
}

///
unittest
{
    int[13] arr1;
    auto rng1 = arrayOutputRange( arr1 );
    fillFlat!int( rng1, [1,2], 3, [[4,5],[6]], iota(7,9), [[[9],[10,11]],[[12]]] );
    assertEq( arr1, [1,2,3,4,5,6,7,8,9,10,11,12,0] );

    int[] arr2 = new int[]( 13 ) ;
    auto rng2 = arrayOutputRange( arr2 );
    fillFlat!int( rng2, [1,2], 3, [[4,5],[6]], iota(7,9), [[[9],[10,11]],[[12]]] );
    assertEq( arr2, [1,2,3,4,5,6,7,8,9,10,11,12,0] );
}

/// create flat copy of vals
auto flatData(T,E...)( in E vals ) pure
if( E.length > 0 )
{
    auto ret = appender!(T[])();
    fillFlat!T( ret, vals );
    return ret.data;
}

///
unittest
{
    assertEq( flatData!float([1.0,2],[[3,4]],5,[6,7]), [1,2,3,4,5,6,7] );
}
