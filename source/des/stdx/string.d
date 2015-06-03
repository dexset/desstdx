module des.stdx.string;

public import std.string;

import std.array;
import std.algorithm;
import std.traits;
import std.range;

import des.ts;
import des.stdx.type : getTypedArray;

public import des.stdx.pformat;

///
string toSnakeCase( in string str, bool ignore_first=true ) @property pure @trusted
{
    string[] buf;
    buf ~= "";
    foreach( i, ch; str )
    {
        if( [ch].toUpper == [ch] ) buf ~= "";
        buf[$-1] ~= [ch].toLower;
    }
    if( buf[0].length == 0 && ignore_first )
        buf = buf[1..$];
    return buf.join("_");
}

///
unittest
{
    assertEq( "SomeVar".toSnakeCase, "some_var" );
    assertEq( "SomeVar".toSnakeCase(false), "_some_var" );

    assertEq( "someVar".toSnakeCase, "some_var" );
    assertEq( "someVar".toSnakeCase(false), "some_var" );

    assertEq( "ARB".toSnakeCase, "a_r_b" );
    assertEq( "ARB".toSnakeCase(false), "_a_r_b" );

    // not alphabetic chars in upper case looks like lower, func separate by them
    assertEq( "A.B.r.A".toSnakeCase, "a_._b_.r_._a" );
    assertEq( "A_B_r_A".toSnakeCase, "a___b__r___a" );
}

///
string toCamelCaseBySep( in string str, string sep="_", bool first_capitalize=true ) pure @trusted
{
    auto arr = array( filter!"a.length > 0"( str.split(sep) ) );
    string[] ret;
    foreach( i, v; arr )
    {
        auto bb = v.capitalize;
        if( i == 0 && !first_capitalize )
            bb = v.toLower;
        ret ~= bb;
    }
    return ret.join("");
}

///
unittest
{
    assertEq( toCamelCaseBySep( "single-precision-constant", "-", false ), "singlePrecisionConstant" );
    assertEq( toCamelCaseBySep( "one.two.three", ".", true ), "OneTwoThree" );
    assertEq( toCamelCaseBySep( "one..three", ".", true ), "OneThree" );
    assertEq( toCamelCaseBySep( "one/three", "/" ), "OneThree" );
    assertEq( toCamelCaseBySep( "one_.three", ".", false ), "one_Three" );

    // `_` in upper case looks equals as lower case
    assertEq( toCamelCaseBySep( "one._three", ".", true ), "One_three" );
}

///
string toCamelCase( in string str, bool first_capitalize=true ) @property pure @trusted
{ return toCamelCaseBySep( str, "_", first_capitalize ); }

///
unittest
{
    assertEq( "some_class".toCamelCase, "SomeClass" );
    assertEq( "_some_class".toCamelCase, "SomeClass" );
    assertEq( "some_func".toCamelCase(false), "someFunc" );
    assertEq( "_some_func".toCamelCase(false), "someFunc" );
    assertEq( "a_r_b".toCamelCase, "ARB" );
    assertEq( toCamelCase( "program_build" ), "ProgramBuild" );
    assertEq( toCamelCase( "program__build" ), "ProgramBuild" );

    assertEq( toCamelCase( "program__build", false ), toCamelCaseBySep( "program__build", "_", false ) );
}

/// copy chars to string
string toDString( const(char*) c_str ) nothrow pure @trusted
{
    if( c_str is null ) return "";
    char *ch = cast(char*)c_str;
    size_t n;
    while( *ch++ != '\0' ) n++;
    return getTypedArray!char( n, c_str ).idup;
}

///
unittest
{
    auto c = [ 'a', 'b', 'c', '\0', 'd', 'e' ];
    assertEq( toDString( c.ptr ), "abc" );
}

/// ditto
string toDStringFix(size_t S)( const(char[S]) c_buf ) nothrow pure @trusted
{
    size_t n;
    foreach( c; c_buf )
    {
        if( c == '\0' ) break;
        n++;
    }
    return getTypedArray!char( n, c_buf.ptr ).idup;
}

///
unittest
{
    char[6] c = [ 'a', 'b', 'c', '\0', 'd', 'e' ];
    assertEq( toDStringFix(c), "abc" );
}
