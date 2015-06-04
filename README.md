## D Extended Set (DES) Standart Lib Extend
[![Build Status](https://travis-ci.org/dexset/desstdx.svg?branch=master)](https://travis-ci.org/dexset/desstdx)
[![Join the chat at https://gitter.im/dexset/discussion](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/dexset/discussion)

#### algorithm
minimal wraps around `std.algorithm`

#### pformat
simple `pure nothow` converting integer and floating numbers to string

##### WIP `string pFormat(Args...)( string fmt, Args args ) pure` 
```d
assertEq( pFormat( "%4d", 10 ), "  10" );
assertEq( pFormat( "hello % 6.3f world %d ok",  3.141592, 12 ),
                   "hello  3.141 world 12 ok" );
assertEq( pFormat( "%2$10s %1$s", "hello", "world" ), "     world hello" );
assertEq( pFormat( "%1$10s %1$s", "hello" ), "     hello hello" );

// fmt args without option index starts with first from any place
assertEq( pFormat( "%1$10s %1$s %3$ 6.3f %s %d", "hello", 14, 2.718281828 ),
                   "     hello hello  2.718 hello 14" );
```
##### use with caution: can be bugged, only numbers and strings are implemented

#### bitflags
manipulate bit flags

#### path
minimal wraps around `buildNormalizedPath`

#### pdata
struct `PData` (for storing information for passing to other thread for example)

#### string
`toCamelCase`, `toSnakeCase`, `toDString` functions

#### traits

#### type
enum of most using numeric types and works with it

To build doc use [harbored-mod](https://github.com/kiith-sa/harbored-mod)
