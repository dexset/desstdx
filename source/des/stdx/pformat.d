module des.stdx.pformat;

import std.traits;
import std.array;
import std.range;
import std.math;

import des.ts;

///
enum PlusSig
{
    NONE, ///
    SPACE, ///
    PLUS ///
}

///
string intToStr(T)( in T val,
                    int width=0,
                    PlusSig plus_sig=PlusSig.NONE,
                    int base=10,
                    char fill_char=' ' ) pure nothrow
if( isIntegral!T )
in {
    assert( val != T.min );
    assert( base > 0, "base must be > 0" );
    assert( base <= 16, "base must be <= 16" );
}
body {
    enum tbl = [  0:'0',  1:'1',  2:'2',  3:'3',
                  4:'4',  5:'5',  6:'6',  7:'7',
                  8:'8',  9:'9', 10:'A', 11:'B',
                 12:'C', 13:'D', 14:'E', 15:'F' ];

    auto positive = val >= 0;
    T value = positive ? val : -val;

    string ret;
    do
    {
        ret = tbl[value%base] ~ ret;
        value /= base;
    }
    while( value > 0 );

    return fmtNumericStr( ret, positive, width, plus_sig, fill_char );
}

///
unittest
{
    assertEq( intToStr(0), "0" );
    assertEq( intToStr(123), "123" );
    assertEq( intToStr(-16), "-16" );
    assertEq( intToStr(-16, 5), "  -16" );

    assertEq( intToStr(16, 5, PlusSig.NONE),  "   16" );
    assertEq( intToStr(16, 5, PlusSig.SPACE), "   16" );
    assertEq( intToStr(16, 5, PlusSig.PLUS),  "  +16" );

    assertEq( intToStr(16, 0, PlusSig.NONE),  "16" );
    assertEq( intToStr(16, 0, PlusSig.SPACE), " 16" );
    assertEq( intToStr(16, 0, PlusSig.PLUS),  "+16" );

    assertEq( intToStr(1234567, 5), "1234567" );
    assertEq( intToStr(1234567, 5, PlusSig.PLUS), "+1234567" );
    assertEq( intToStr(1234567, -5, PlusSig.PLUS), "+1234567" );
    assertEq( intToStr(1234567, -5, PlusSig.SPACE), " 1234567" );

    assertEq( intToStr(16, 5, PlusSig.NONE, 10, 'x'), "xxx16" );
    assertEq( intToStr(0, 10, PlusSig.NONE, 10, '0'), "0000000000" );

    assertEq( intToStr(3, 4, PlusSig.NONE, 2, '0'), "0011" );
    assertEq( intToStr(3, 4, PlusSig.NONE, 8, '0'), "0003" );
    assertEq( intToStr(9, 4, PlusSig.NONE, 8, '0'), "0011" );

    assertEq( intToStr(255, 3, PlusSig.NONE, 16 ), " FF" );
    assertEq( intToStr(256, 3, PlusSig.NONE, 16 ), "100" );
}

///
string floatToStr(T)( in T val,
                      int width=0,
                      int after_point=6,
                      bool remove_trailing_zeros=true,
                      PlusSig plus_sig=PlusSig.NONE,
                      char fill_char=' ' ) pure nothrow
if( isNumeric!T )
in{ assert( after_point >= 0 ); } body
{
    string ret = testFinite( val );
    auto positive = isPositive( val );

    if( ret.length == 0 )
    {
        auto apk = 10 ^^ after_point;
        auto int_value = cast(long)( (positive ? val : -val) * apk );
        ret = intToStr( int_value, after_point, PlusSig.NONE, 10, '0' );

        ret = ret[0..($-after_point)] ~ '.' ~ ret[($-after_point)..$];

        if( remove_trailing_zeros )
            while( ret[$-1] == '0' )
            {
                if( ret[$-2] == '.' ) break;
                ret = ret[0..$-1];
            }
    }

    return fmtNumericStr( ret, positive, width, plus_sig, fill_char );
}

///
unittest
{
    assertEq( floatToStr(0), ".0" );
    assertEq( floatToStr( 3.1415 ), "3.1415" );
    assertEq( floatToStr( -3.1415 ), "-3.1415" );
    assertEq( floatToStr( -3.1415, 6, 2 ), " -3.14" );
    assertEq( floatToStr( 3.1415, 6, 2 ), "  3.14" );
    assertEq( floatToStr( 3.1415, 6, 2, true, PlusSig.PLUS ), " +3.14" );
    assertEq( floatToStr( 128, 6, 2, true, PlusSig.PLUS ), "+128.0" );
    assertEq( floatToStr( 1286, 6, 2, true, PlusSig.PLUS ), "+1286.0" );
    assertEq( floatToStr( 1286, 6, 0 ), " 1286." );
    assertEq( floatToStr( 3.1415, 12, 8, false ),  "  3.14150000" );
    assertEq( floatToStr( -3.1415, 12, 8, false ), " -3.14150000" );
    assertEq( floatToStr(float.nan), "nan" );
    assertEq( floatToStr(-float.nan), "-nan" );
    assertEq( floatToStr(float.infinity), "inf" );
    assertEq( floatToStr(-float.infinity), "-inf" );

    assertEq( floatToStr( 3.1415, 0, 2, true, PlusSig.NONE ), "3.14" );
    assertEq( floatToStr( 3.1415, 0, 3, true, PlusSig.SPACE ), " 3.141" );
    assertEq( floatToStr( 3.1415, 0, 2, true, PlusSig.PLUS ),  "+3.14" );
}

unittest
{
    assertEq( floatToStr(double.nan), "nan" );
    assertEq( floatToStr(-double.nan), "-nan" );
    assertEq( floatToStr(double.infinity), "inf" );
    assertEq( floatToStr(-double.infinity), "-inf" );
    assertEq( floatToStr(real.nan), "nan" );
    assertEq( floatToStr(-real.nan), "-nan" );
    assertEq( floatToStr(real.infinity), "inf" );
    assertEq( floatToStr(-real.infinity), "-inf" );
}

///
string floatToStrSci(T)( in T val,
                         int width=0,
                         int after_point=6,
                         PlusSig plus_sig=PlusSig.NONE,
                         char fill_char=' ' )
if( isNumeric!T )
in{ assert( after_point >= 0 ); } body
{
    string ret = testFinite( val );
    auto positive = isPositive( val );

    if( ret.length == 0 )
    {
        auto positive_val = positive ? val : -val;

        int exponent = val != 0 ? cast(int)(floor(log10(positive_val))) : 0;

        auto exp_positive = exponent >= 0;

        auto apk = 10 ^^ after_point / pow( 10.0, exponent );

        auto int_value = cast(long)( positive_val * apk );
        ret = intToStr( int_value, after_point+1, PlusSig.NONE, 10, '0' );
        auto exp_str = intToStr( abs(exponent), 2, PlusSig.NONE, 10, '0' );

        ret = ret[0..1] ~ '.' ~ ret[1..$] ~
              "e" ~ ( exp_positive ? "+" : "-" ) ~ exp_str;
    }

    return fmtNumericStr( ret, positive, width, plus_sig, fill_char );
}

///
unittest
{
    assertEq( floatToStrSci( 0 ), "0.000000e+00" );
    assertEq( floatToStrSci( 3.1415 ), "3.141500e+00" );
    assertEq( floatToStrSci( 314.15 ), "3.141500e+02" );
    assertEq( floatToStrSci( 0.0314 ), "3.139999e-02" );
    assertEq( floatToStrSci( 3.14159e-8 ), "3.141590e-08" );
    assertEq( floatToStrSci( 3.1415e11 ), "3.141500e+11" );
    assertEq( floatToStrSci( 3.1415e11, 10, 3, PlusSig.PLUS ), "+3.141e+11" );

    import std.string : format;

    foreach( i; 0 .. 1000 )
    {
        auto v = .001 * i;
        assertEqApprox( to!double( floatToStrSci(v) ), v, .001,
                format( "%%s != %%s with i: %s", i ) );
    }
}

private string getPlusStr( PlusSig ps ) pure nothrow
{
    final switch( ps )
    {
        case PlusSig.NONE: return "";
        case PlusSig.SPACE: return " ";
        case PlusSig.PLUS: return "+";
    }
}

private string fmtNumericStr( string str,
                              bool positive,
                              int width,
                              PlusSig plus_sig,
                              char fill_char ) pure nothrow
{
    auto ret = ( positive ? getPlusStr( plus_sig ) : "-" ) ~ str;
    auto spaces = width - cast(int)ret.length;
    if( spaces <= 0 ) return ret;
    else return array( fill_char.repeat().take( spaces ) ).idup ~ ret;
}

private string testFinite(T)( in T val ) pure nothrow
if( isNumeric!T )
{
    static if( isFloatingPoint!T )
    {
        if( fabs(val) is T.nan ) return "nan";
        if( fabs(val) is T.infinity ) return "inf";
    }
    return "";
}

private bool isPositive(T)( in T val ) pure nothrow
if( isNumeric!T )
{
    static if( isFloatingPoint!T )
        return signbit(val) == 0;
    else return val >= 0;
}
