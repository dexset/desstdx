module des.stdx.pformat;

import std.traits;
import std.array;
import std.range;
import std.math;
import std.algorithm;
import std.exception;

import std.stdio;

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

    assertEq( floatToStrSci( 3.141592, 12, 5, PlusSig.SPACE ), " 3.14159e+00" );
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
    return fmtWidthStr( ret, width, fill_char );
}

private string fmtWidthStr( string str, int width, char fill_char ) pure nothrow
{
    auto spaces = width - cast(int)str.length;
    if( spaces <= 0 ) return str;
    else return array( fill_char.repeat().take( spaces ) ).idup ~ str;
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

class PFormatException : Exception
{
    this( string msg, string file=__FILE__, size_t line=__LINE__ ) pure @safe nothrow
    { super( msg, file, line ); }
}

struct PFormatArg
{
    long index=0;

    int width=0;
    int after_point=6;
    PlusSig plus_sig=PlusSig.NONE;
    char fill_char=' ';

    enum Type
    {
        ERR, /// error type
        ORI, /// original (part of format string)
        UNI, /// universal %s
        BIN, /// integer by base 2 %b
        OCT, /// integer by base 8 %o
        DEC, /// integer by base 10 %d
        HEX, /// integer by base 16 %x
        FLO, /// floating %f
        SCI  /// scientific floating %e
    }

    Type type=Type.ERR;

    string fmt;
    string result;
}

private PFormatArg[] parseFormatString( string fmt ) pure
{
    PFormatArg[] ret;

    int arg_index = 1;

    while( !fmt.empty )
    {
        if( isStartFormatChar( fmt.front ) )
            ret ~= parseFormatPart( fmt, arg_index );
        else
            ret ~= parseStringPart( fmt );
    }

    return ret;
}

private auto getAndPopFront(R)( ref R r ) @property if( isInputRange!R )
{
    auto ret = r.front;
    r.popFront();
    return ret;
}

private PFormatArg parseStringPart( ref string fmt ) pure
{
    PFormatArg arg;
    arg.index = 0;
    arg.type = PFormatArg.Type.ORI;

    while( !( fmt.empty || isStartFormatChar( fmt.front ) ) )
        arg.fmt ~= fmt.getAndPopFront();

    arg.result = arg.fmt;
    return arg;
}

private PFormatArg parseFormatPart( ref string fmt, ref int serial_index ) pure
in{ assert( fmt.front == '%' ); } body
{
    PFormatArg arg;
    arg.index = 0;

    auto fmtGPFCE( string place )
    {
        scope(exit) if( fmt.empty ) throw new PFormatException( "format not complite: '" ~ arg.fmt ~ "' on " ~ place );
        return fmt.getAndPopFront;
    }

    int parseNumber()
    {
        int n = 1;
        int val = 0;
        while( isNumericChar( fmt.front ) )
        {
            val = val * n + charToInt( fmt.front );
            n *= 10;
            arg.fmt ~= fmtGPFCE( "parse number" );
        }
        return val;
    }

    arg.fmt ~= fmtGPFCE( "get first format char" ); // first % symbol

    // double % processing (%%)
    if( isStartFormatChar( fmt.front ) )
    {
        arg.fmt ~= fmt.getAndPopFront;
        arg.type = PFormatArg.Type.ORI;
        arg.result = arg.fmt;
        return arg;
    }

    // if option index is finded it will be reseted
    if( isPlusSigChar( fmt.front ) )
    {
        arg.plus_sig = getPlusSig( fmt.front );
        arg.fmt ~= fmtGPFCE( "first check sig char" );
    }

    int width = 0, after_point = -1, option_index;

    if( isNumericChar( fmt.front ) ) width = parseNumber();

    if( isOptionIndexChar( fmt.front ) )
    {
        option_index = width;
        width = 0;
        arg.fmt ~= fmtGPFCE( "option index char" );
        arg.plus_sig = PlusSig.NONE;
    }

    // was reseted if option index
    if( isPlusSigChar( fmt.front ) )
    {
        arg.plus_sig = getPlusSig( fmt.front );
        arg.fmt ~= fmtGPFCE( "second check sig char" );
    }

    if( isNumericChar( fmt.front ) ) width = parseNumber();

    if( fmt.front == '.' )
    {
        // after point number parse, expect only floating point format
        arg.fmt ~= fmtGPFCE( "check dot char" );
        if( isNumericChar( fmt.front ) ) after_point = parseNumber();
        else throw new PFormatException( "after dot must be numbers" );
    }

    auto ftype = getFormatType( fmt.front );

    if( ftype == PFormatArg.Type.ERR ) throw new PFormatException( "bad format" );

    arg.fmt ~= fmt.getAndPopFront();

    if( after_point != -1 && !( ftype == PFormatArg.Type.FLO || ftype == PFormatArg.Type.SCI ) )
        throw new PFormatException( "dot in format specify only to floating point formating" );

    arg.type = ftype;
    arg.width = width;

    if( after_point != -1 ) arg.after_point = after_point;

    if( option_index != 0 )
        arg.index = option_index;
    else
    {
        arg.index = serial_index;
        serial_index++;
    }

    return arg;
}

private
{
    bool isStartFormatChar( dchar ch ) pure { return ch == '%'; }
    bool isOptionIndexChar( dchar ch ) pure { return ch == '$'; }

    PFormatArg.Type getFormatType( dchar ch ) pure
    {
        switch( ch )
        {
            case 's': return PFormatArg.Type.UNI;
            case 'b': return PFormatArg.Type.BIN;
            case 'o': return PFormatArg.Type.OCT;
            case 'd': return PFormatArg.Type.DEC;
            case 'x': return PFormatArg.Type.HEX;
            case 'f': return PFormatArg.Type.FLO;
            case 'e': return PFormatArg.Type.SCI;
            default:  return PFormatArg.Type.ERR;
        }
    }

    bool isPlusSigChar( dchar ch ) pure { return ch == ' ' || ch == '+'; }

    PlusSig getPlusSig( dchar ch ) pure
    {
        if( ch == ' ' ) return PlusSig.SPACE;
        if( ch == '+' ) return PlusSig.PLUS;
        assert( 0, "char isn't plus sig char" );
    }

    bool isNumericChar( dchar ch ) pure
    { return '0' <= ch && ch <= '9'; }

    int charToInt( dchar ch ) pure
    out(n) { assert( 0 <= n && n <= 9 ); } body
    { return ch - '0'; }
}

///
string pFormat(Args...)( string fmt, Args args ) pure
{
    auto fmt_args = parseFormatString( fmt );
    fillArgsResult!0( fmt_args, args );
    return fmt_args.map!(a=>a.result).join();
}

///
unittest
{
    assertEq( pFormat( "%4d", 10 ), "  10" );

    assertEq( pFormat( "hello %6.4f world %3d ok", 3.141592, 12 ), "hello 3.1415 world  12 ok" );
    assertEq( pFormat( "hello % 6.3f world %d ok",  3.141592, 12 ), "hello  3.141 world 12 ok" );
    assertEq( pFormat( "hello % 6.3f world % d ok", -3.141592, 12 ), "hello -3.141 world  12 ok" );
    assertEq( pFormat( "hello % 6.3f world % 4d ok", -3.141592, 12 ), "hello -3.141 world   12 ok" );
    assertEq( pFormat( "hello % 6.3f world % d ok", -3.141592, -12 ), "hello -3.141 world -12 ok" );
    assertEq( pFormat( "hello %+6.3f world %+d ok",  3.141592, 12 ), "hello +3.141 world +12 ok" );

    assertEq( pFormat( "hello %+13.5e world 0b%b ok", 3.141592, 8 ), "hello  +3.14159e+00 world 0b1000 ok" );
    assertEq( pFormat( "%10s %s", "hello", "world" ), "     hello world" );

    assertEq( pFormat( "%2$10s %1$s", "hello", "world" ), "     world hello" );
    assertEq( pFormat( "%1$10s %1$s", "hello" ), "     hello hello" );
    assertEq( pFormat( "%1$10s %1$s %3$ 6.3f %2$d", "hello", 14, 2.718281828 ), "     hello hello  2.718 14" );

    // fmt args without option index starts with first from any place
    assertEq( pFormat( "%1$10s %1$s %3$ 6.3f %s %d", "hello", 14, 2.718281828 ), "     hello hello  2.718 hello 14" );
}

private void fillArgsResult(int index,TT...)( PFormatArg[] pfalist, TT arglist ) if( TT.length > 0 )
{
    static if( TT.length > 1 )
    {
        fillArgsResult!index( pfalist, arglist[0] );
        fillArgsResult!(index+1)( pfalist, arglist[1..$] );
    }
    else
    {
        auto fl = find!"(a.index-1)==b"( pfalist, index );

        if( fl.empty ) throw new PFormatException( "no fmt in str for arg #" ~ intToStr(index) );

        do
        {
            fl.front.result = procArg( arglist[0], fl.front );
            fl.popFront();
            fl = find!"(a.index-1)==b"( fl, index );
        }
        while( !fl.empty );
    }
}

private string procArg(T)( T arg, in PFormatArg e )
{
    static string i2s( T val, in PFormatArg pfa, int base )
    {
        static if( !isIntegral!T ) throw new PFormatException( "bad call i2s with type " ~ T.stringof );
        else return intToStr( val, pfa.width, pfa.plus_sig, base, pfa.fill_char );
    }

    static string f2s( T val, in PFormatArg pfa )
    {
        static if( !isNumeric!T ) throw new PFormatException( "bad call f2s with type " ~ T.stringof );
        else return floatToStr( val, pfa.width, pfa.after_point, true, pfa.plus_sig, pfa.fill_char );
    }

    static string f2ss( T val, in PFormatArg pfa )
    {
        static if( !isNumeric!T ) throw new PFormatException( "bad call f2s with type " ~ T.stringof );
        else return floatToStrSci( val, pfa.width, pfa.after_point, pfa.plus_sig, pfa.fill_char );
    }

    static string any2s( T val, in PFormatArg pfa )
    {
        static if( !is( T == string ) )
        {
            /+ TODO
             + TODO
             + TODO
             +/
            assert( 0, "no implement for type '" ~ T.stringof ~ "'" );
        }
        else return fmtWidthStr( val, pfa.width, pfa.fill_char );
    }

    final switch( e.type )
    {
        case PFormatArg.Type.ORI: return e.result;
        case PFormatArg.Type.BIN: return i2s( arg, e, 2 );
        case PFormatArg.Type.OCT: return i2s( arg, e, 8 );
        case PFormatArg.Type.DEC: return i2s( arg, e, 10 );
        case PFormatArg.Type.HEX: return i2s( arg, e, 16 );
        case PFormatArg.Type.FLO: return f2s( arg, e );
        case PFormatArg.Type.SCI: return f2ss( arg, e );
        case PFormatArg.Type.UNI: return any2s( arg, e );

        case PFormatArg.Type.ERR: assert( 0, "error type" );
    }
}
