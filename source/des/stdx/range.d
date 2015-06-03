module des.stdx.range;

public import std.range;

import std.conv;
import std.algorithm;

import des.stdx.traits;
import des.ts;

private version(unittest)
{
    struct VecN(size_t N){ float[N] data; alias data this; }
    alias Vec=VecN!3;
    static assert( canUseAsArray!Vec );
}

/++ fill output range with result of fn() called per elements
 +/
void mapFlat(alias fn,R,V,E...)( ref R output, V val, E tail )
    if( is( typeof( output.put( fn( (ElementTypeRec!V).init ) ) ) ) )
{
    static if( E.length > 0 )
    {
        mapFlat!fn( output, val );
        mapFlat!fn( output, tail );
    }
    else
    {
        static if( isInputRange!V )
            foreach( l; val ) mapFlat!fn( output, l );
        else static if( canUseAsArray!V )
            foreach( i; 0 .. val.length )
                mapFlat!fn( output, val[i] );
        else static if( is( ElementTypeRec!V == V ) )
            output.put( fn( val ) );
        else static assert( 0, "V has elements, " ~
                "but isn't input range, or not have length" );
    }
}

///
unittest
{
    import std.array;

    auto app = appender!(int[])();
    mapFlat!(a=>to!int(a)*2)( app, [1,2], 3,
                       [[4,5],[6]],
                       iota(7,9),
                       [[[9],[10,11]],[[12]]],
                       Vec([13.3,666,105]) );
    assertEq( app.data, [2,4,6,8,10,12,14,16,18,20,22,24,26,1332,210] );
}

///
template ElementTypeRec(T)
{
    static if( is( ElementType!T == void ) ) // is not range or array
        alias ElementTypeRec = T;
    else // if is range or array
        alias ElementTypeRec = ElementTypeRec!(ElementType!T);
}

///
unittest
{
    static assert( is( ElementTypeRec!int == int ) );
    static assert( is( ElementTypeRec!(int[]) == int ) );
    static assert( is( ElementTypeRec!(int[2]) == int ) );
    static assert( is( ElementTypeRec!(int[][]) == int ) );
    static assert( is( ElementTypeRec!(int[3][2]) == int ) );
    static assert( is( ElementTypeRec!(typeof(iota(7))) == int ) );
    static assert( is( ElementTypeRec!(VecN!10) == float ) );
}

/++ fill output range with flat values
 +/
void fillFlat(T,R,V,E...)( ref R output, V val, E tail )
    if( isOutputRange!(R,T) )
{ mapFlat!(a=>to!T(a))( output, val, tail ); }

///
unittest
{
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
size_t getFlatLength(V,E...)( V val, E tail ) @nogc
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
auto flatData(T,E...)( in E vals )
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

    assertEq( flatData!double( VecN!3([1,2,3]) ), [1,2,3] );
    assertEq( flatData!double( VecN!1([2]) ), [2] );
}
