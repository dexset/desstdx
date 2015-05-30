module des.stdx.bitflags;

import std.algorithm : reduce;
import std.traits : isIntegral;

import des.ts;

/// pack array of values to bit value
auto packFlags(T)( in T[] list... )
    if( isIntegral!T )
{ return reduce!((a,b)=>a|=b)(T(0),list); }

///
unittest
{
    assertEq( packFlags!uint(), 0 );
    auto a = 0b01;
    assertEq( packFlags(a), a );
    auto b = 0b10;
    auto c = 0b11;
    assertEq( packFlags(a,b), c );
}

/// remove flags from bit value
auto removeFlags(T)( in T bit_value, in T[] list... )
    if( isIntegral!T )
{ return reduce!((a,b)=>(a^=a&b))( bit_value, list ); }

///
unittest
{
    auto a = 0b01;
    auto b = 0b10;
    auto c = 0b11;
    assertEq( removeFlags(c,a), b );
    assertEq( removeFlags(c,b), a );
    assertEq( removeFlags(c,a,b), 0 );
}

/// checks flag in bit value
bool hasFlag(T)( in T bit_value, in T flag )
    if( isIntegral!T )
{ return ( bit_value & flag ) == flag; }

///
unittest
{
    auto a = 0b01;
    auto b = 0b10;
    auto c = 0b11;
    assert( hasFlag(c,a) );
    assert( hasFlag(c,b) );
    assert( hasFlag(c,0) );
}

/// checks flags in bit value
bool hasFlags(T)( in T bit_value, in T[] list... )
    if( isIntegral!T )
{ return hasFlag( bit_value, packFlags( list ) ); }

///
unittest
{
    auto a = 0b001;
    auto b = 0b010;
    auto c = 0b100;
    auto d = 0b111;
    assert( hasFlags(d,a,b,c) );
}
