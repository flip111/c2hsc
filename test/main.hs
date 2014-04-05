{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Main where

import Control.Exception
import Control.Logging
import Data.C2Hsc
import Data.Char
import Data.Monoid
import Data.String.Here
import Data.Text (Text, pack)
import Prelude hiding (log)
import Test.Hspec

tryAny :: IO a -> IO (Either SomeException a)
tryAny = try

main :: IO ()
main = withStdoutLogging $ hspec $ do
    describe "sanity check" $
        it "maps a typedef" $
            matches [here|
typedef int an_int;
|] [here|
{- typedef int an_int; -}
#synonym_t an_int , CInt
|]

    describe "issues" $ do
        it "#12" $
            matches [here|
struct st {
  int i;
};

enum e {
  CONST
};

union u {
  char c;
};
|] [here|
{- struct st {
    int i;
}; -}
#starttype struct st
#field i , CInt
#stoptype
{- enum e {
    CONST
}; -}
#integral_t enum e
#num CONST
{- union u {
    char c;
}; -}
#starttype union u
#field c , CChar
#stoptype
|]
        it "#15" $
            matches [here|
struct MyTypeImpl;
typedef struct MyTypeImpl* MyType;

typedef struct MyStruct {
  int x;
} MyStructType;

typedef struct MyStructEmpty MyStructEmptyType;
|] [here|
{- struct MyTypeImpl; -}
#opaque_t struct MyTypeImpl
{- typedef struct MyTypeImpl * MyType; -}
#synonym_t MyType , <struct MyTypeImpl>
{- typedef struct MyStruct {
            int x;
        } MyStructType; -}
#starttype struct MyStruct
#field x , CInt
#stoptype
#synonym_t MyStructType , <struct MyStruct>
{- typedef struct MyStructEmpty MyStructEmptyType; -}
#opaque_t struct MyStructEmpty
#synonym_t MyStructEmptyType , <struct MyStructEmpty>
|]

    describe "primitive types" $ do
        it "float" $
            matches [here|
float ordinary_float;
|] [here|
#globalvar ordinary_float , CFloat
|]
        it "double" $
            matches [here|
double ordinary_double;
|] [here|
#globalvar ordinary_double , CDouble
|]
        -- test disabled until https://ghc.haskell.org/trac/ghc/ticket/3353 is
        -- resolved.
        --
        -- it "long double" $
        --     matches [here|
        -- long double ordinary_long_double;
        -- |] [here|
        -- #globalvar ordinary_long_double , CLongDouble
        -- |]

        it "char" $
            matches [here|
char ordinary_signed_char;
|] [here|
#globalvar ordinary_signed_char , CChar
|]
        it "unsigned char" $
            matches [here|
unsigned char unsigned_char;
|] [here|
#globalvar unsigned_char , CUChar
|]
        it "short" $
            matches [here|
short ordinary_signed_short;
|] [here|
#globalvar ordinary_signed_short , CShort
|]
        it "signed short" $
            matches [here|
signed short explicit_signed_short;
|] [here|
#globalvar explicit_signed_short , CShort
|]
        it "unsigned short" $
            matches [here|
unsigned short unsigned_short;
|] [here|
#globalvar unsigned_short , CUShort
|]
        it "int" $
            matches [here|
int ordinary_signed_int;
|] [here|
#globalvar ordinary_signed_int , CInt
|]
        it "signed int" $
            matches [here|
signed int explicit_signed_int;
|] [here|
#globalvar explicit_signed_int , CInt
|]
        it "unsigned int" $
            matches [here|
unsigned int unsigned_int;
|] [here|
#globalvar unsigned_int , CUInt
|]
        it "long" $
            matches [here|
long ordinary_signed_long;
|] [here|
#globalvar ordinary_signed_long , CLong
|]
        it "signed long" $
            matches [here|
signed long explicit_signed_long;
|] [here|
#globalvar explicit_signed_long , CLong
|]
        it "unsigned long" $
            matches [here|
unsigned long unsigned_long;
|] [here|
#globalvar unsigned_long , CULong
|]

-- jww (2014-04-05): language-c does not yet support "long long" types,
-- although GHC's FFI does.
--         it "long long" $ do
--             matches [here|
-- long long ordinary_signed_long_long;
-- |] [here|
-- #globalvar ordinary_signed_long_long , CLLong
-- |]
--         it "signed long long" $ do
--             matches [here|
-- signed long long explicit_signed_long_long;
-- |] [here|
-- #globalvar explicit_signed_long_long , CLLong
-- |]
--         it "unsigned long long" $ do
--             matches [here|
-- unsigned long long unsigned_long_long;
-- |] [here|
-- #globalvar unsigned_long_long , CULLong
-- |]

    describe "pointers" $ do
        describe "primitive types which cannot be signed" $ do
            it "ordinary_void_pointer" $
                -- jww (2014-04-05): This is wrong!
                matches [here|
        void* ordinary_void_pointer;
|] [here|
#globalvar ordinary_void_pointer , 
|]
            it "ordinary_float_pointer" $
                matches [here|
        float* ordinary_float_pointer;
|] [here|
#globalvar ordinary_float_pointer , CFloat
|]
            it "ordinary_double_pointer" $
                matches [here|
        double* ordinary_double_pointer;
|] [here|
#globalvar ordinary_double_pointer , CDouble
|]
--             it "ordinary_long_double_pointer" $
--                 matches [here|
--         long double* ordinary_long_double_pointer;
-- |] [here|
-- |]
        describe "types which can be signed" $ do
            describe "char" $ do
                it "ordinary_signed_char_pointer" $
                    matches [here|
          char *ordinary_signed_char_pointer;
|] [here|
#globalvar ordinary_signed_char_pointer , CChar
|]
                it "explicit_signed_char_pointer" $
                    matches [here|
          signed char *explicit_signed_char_pointer;
|] [here|
#globalvar explicit_signed_char_pointer , CSChar
|]
                it "unsigned_char_pointer" $
                    matches [here|
          unsigned char *unsigned_char_pointer;
|] [here|
#globalvar unsigned_char_pointer , CUChar
|]
            describe "short" $ do
                it "ordinary_signed_short_pointer" $
                    matches [here|
          short *ordinary_signed_short_pointer;
|] [here|
#globalvar ordinary_signed_short_pointer , CShort
|]
                it "explicit_signed_short_pointer" $
                    matches [here|
          signed short *explicit_signed_short_pointer;
|] [here|
#globalvar explicit_signed_short_pointer , CShort
|]
                it "unsigned_short_pointer" $
                    matches [here|
          unsigned short *unsigned_short_pointer;
|] [here|
#globalvar unsigned_short_pointer , CUShort
|]
            describe "int" $ do
                it "ordinary_signed_int_pointer" $
                    matches [here|
          int* ordinary_signed_int_pointer;
|] [here|
#globalvar ordinary_signed_int_pointer , CInt
|]
                it "explicit_signed_int_pointer" $
                    matches [here|
          signed int* explicit_signed_int_pointer;
|] [here|
#globalvar explicit_signed_int_pointer , CInt
|]
                it "unsigned_int_pointer" $
                    matches [here|
          unsigned int* unsigned_int_pointer;
|] [here|
#globalvar unsigned_int_pointer , CUInt
|]
            describe "long" $ do
                it "ordinary_signed_long_pointer" $
                    matches [here|
          long *ordinary_signed_long_pointer;
|] [here|
#globalvar ordinary_signed_long_pointer , CLong
|]
                it "explicit_signed_long_pointer" $
                    matches [here|
          signed long *explicit_signed_long_pointer;
|] [here|
#globalvar explicit_signed_long_pointer , CLong
|]
                it "unsigned_long_pointer" $
                    matches [here|
          unsigned long *unsigned_long_pointer;
|] [here|
#globalvar unsigned_long_pointer , CULong
|]
            describe "long long" $ do
                it "ordinary_signed_long_long_pointer" $
                    matches [here|
          long long* ordinary_signed_long_long_pointer;
|] [here|
#globalvar ordinary_signed_long_long_pointer , CLong
|]
                it "explicit_signed_long_long_pointer" $
                    matches [here|
          signed long long* explicit_signed_long_long_pointer;
|] [here|
#globalvar explicit_signed_long_long_pointer , CLong
|]
                it "unsigned_long_long_pointer" $
                    matches [here|
          unsigned long long* unsigned_long_long_pointer;
|] [here|
#globalvar unsigned_long_long_pointer , CULong
|]

    describe "arrays" $ do
        describe "primitive types which cannot be signed" $ do
            it "ordinary_float_array" $
                matches [here|
        float ordinary_float_array[10];
|] [here|
#globalvar ordinary_float_array , CFloat
|]
            it "ordinary_double_array" $
                matches [here|
        double ordinary_double_array[10];
|] [here|
#globalvar ordinary_double_array , CDouble
|]
            it "ordinary_long_double_array" $
                matches [here|
        long double ordinary_long_double_array[10];
|] [here|
#globalvar ordinary_long_double_array , CLong
|]
        describe "types which can be signed" $ do
            describe "char" $ do
                it "ordinary_signed_char_array" $
                    matches [here|
          char ordinary_signed_char_array[10];
|] [here|
#globalvar ordinary_signed_char_array , CChar
|]
                it "explicit_signed_char_array" $
                    matches [here|
          signed char explicit_signed_char_array[10];
|] [here|
#globalvar explicit_signed_char_array , CSChar
|]
                it "unsigned_char_array" $
                    matches [here|
          unsigned char unsigned_char_array[10];
|] [here|
#globalvar unsigned_char_array , CUChar
|]
            describe "short" $ do
                it "ordinary_signed_short_array" $
                    matches [here|
          short ordinary_signed_short_array[10];
|] [here|
#globalvar ordinary_signed_short_array , CShort
|]
                it "explicit_signed_short_array" $
                    matches [here|
          signed short explicit_signed_short_array[10];
|] [here|
#globalvar explicit_signed_short_array , CShort
|]
                it "unsigned_short_array" $
                    matches [here|
          unsigned short unsigned_short_array[10];
|] [here|
#globalvar unsigned_short_array , CUShort
|]
            describe "int" $ do
                it "ordinary_signed_int_array" $
                    matches [here|
          int ordinary_signed_int_array[10];
|] [here|
#globalvar ordinary_signed_int_array , CInt
|]
                it "explicit_signed_int_array" $
                    matches [here|
          signed int explicit_signed_int_array[10];
|] [here|
#globalvar explicit_signed_int_array , CInt
|]
                it "unsigned_int_array" $
                    matches [here|
          unsigned int unsigned_int_array[10];
|] [here|
#globalvar unsigned_int_array , CUInt
|]
            describe "long" $ do
                it "ordinary_signed_long_array" $
                    matches [here|
          long ordinary_signed_long_array[10];
|] [here|
#globalvar ordinary_signed_long_array , CLong
|]
                it "explicit_signed_long_array" $
                    matches [here|
          signed long explicit_signed_long_array[10];
|] [here|
#globalvar explicit_signed_long_array , CLong
|]
                it "unsigned_long_array" $
                    matches [here|
          unsigned long unsigned_long_array[10];
|] [here|
#globalvar unsigned_long_array , CULong
|]
            describe "long long" $ do
                it "ordinary_signed_long_long_array" $
                    matches [here|
          long long ordinary_signed_long_long_array[10];
|] [here|
#globalvar ordinary_signed_long_long_array , CLong
|]
                it "explicit_signed_long_long_array" $
                    matches [here|
          signed long long explicit_signed_long_long_array[10];
|] [here|
#globalvar explicit_signed_long_long_array , CLong
|]
                it "unsigned_long_long_array" $
                    matches [here|
          unsigned long long unsigned_long_long_array[10];
|] [here|
#globalvar unsigned_long_long_array , CULong
|]
        describe "pointers" $ do
            describe "primitive types which cannot be signed" $ do
                it "ordinary_void_pointer_array" $
                    matches [here|
          void* ordinary_void_pointer_array[10];
|] [here|
#globalvar ordinary_void_pointer_array ,
|]
                it "ordinary_float_pointer_array" $
                    matches [here|
          float* ordinary_float_pointer_array[10];
|] [here|
#globalvar ordinary_float_pointer_array , CFloat
|]
                it "ordinary_double_pointer_array" $
                    matches [here|
          double* ordinary_double_pointer_array[10];
|] [here|
#globalvar ordinary_double_pointer_array , CDouble
|]
                it "ordinary_long_double_pointer_array" $
                    matches [here|
          long double* ordinary_long_double_pointer_array[10];
|] [here|
#globalvar ordinary_long_double_pointer_array , CLong
|]
            describe "types which can be signed" $ do
                describe "char" $ do
                    it "ordinary_signed_char_pointer_array" $
                        matches [here|
            char *ordinary_signed_char_pointer_array[10];
|] [here|
#globalvar ordinary_signed_char_pointer_array , CChar
|]
                    it "explicit_signed_char_pointer_array" $
                        matches [here|
            signed char *explicit_signed_char_pointer_array[10];
|] [here|
#globalvar explicit_signed_char_pointer_array , CSChar
|]
                    it "unsigned_char_pointer_array" $
                        matches [here|
            unsigned char *unsigned_char_pointer_array[10];
|] [here|
#globalvar unsigned_char_pointer_array , CUChar
|]
                describe "short" $ do
                    it "ordinary_signed_short_pointer_array" $
                        matches [here|
            short *ordinary_signed_short_pointer_array[10];
|] [here|
#globalvar ordinary_signed_short_pointer_array , CShort
|]
                    it "explicit_signed_short_pointer_array" $
                        matches [here|
            signed short *explicit_signed_short_pointer_array[10];
|] [here|
#globalvar explicit_signed_short_pointer_array , CShort
|]
                    it "unsigned_short_pointer_array" $
                        matches [here|
            unsigned short *unsigned_short_pointer_array[10];
|] [here|
#globalvar unsigned_short_pointer_array , CUShort
|]
                describe "int" $ do
                    it "ordinary_signed_int_pointer_array" $
                        matches [here|
            int* ordinary_signed_int_pointer_array[10];
|] [here|
#globalvar ordinary_signed_int_pointer_array , CInt
|]
                    it "explicit_signed_int_pointer_array" $
                        matches [here|
            signed int* explicit_signed_int_pointer_array[10];
|] [here|
#globalvar explicit_signed_int_pointer_array , CInt
|]
                    it "unsigned_int_pointer_array" $
                        matches [here|
            unsigned int* unsigned_int_pointer_array[10];
|] [here|
#globalvar unsigned_int_pointer_array , CUInt
|]
                describe "long" $ do
                    it "ordinary_signed_long_pointer_array" $
                        matches [here|
            long *ordinary_signed_long_pointer_array[10];
|] [here|
#globalvar ordinary_signed_long_pointer_array , CLong
|]
                    it "explicit_signed_long_pointer_array" $
                        matches [here|
            signed long *explicit_signed_long_pointer_array[10];
|] [here|
#globalvar explicit_signed_long_pointer_array , CLong
|]
                    it "unsigned_long_pointer_array" $
                        matches [here|
            unsigned long *unsigned_long_pointer_array[10];
|] [here|
#globalvar unsigned_long_pointer_array , CULong
|]
                describe "long long" $ do
                    it "ordinary_signed_long_long_pointer_array" $
                        matches [here|
            long long* ordinary_signed_long_long_pointer_array[10];
|] [here|
#globalvar ordinary_signed_long_long_pointer_array , CLong
|]
                    it "explicit_signed_long_long_pointer_array" $
                        matches [here|
            signed long long* explicit_signed_long_long_pointer_array[10];
|] [here|
#globalvar explicit_signed_long_long_pointer_array , CLong
|]
                    it "unsigned_long_long_pointer_array" $
                        matches [here|
            unsigned long long* unsigned_long_long_pointer_array[10];
|] [here|
#globalvar unsigned_long_long_pointer_array , CULong
|]

    describe "structs" $ do
        describe "primitive types which cannot be signed" $ do
            it "ordinary_float_struct" $
                matches [here|
        struct ordinary_float_struct {float ordinary_float_member;};
|] [here|
{- struct ordinary_float_struct {
    float ordinary_float_member;
}; -}
#starttype struct ordinary_float_struct
#field ordinary_float_member , CFloat
#stoptype
|]
            it "ordinary_double_struct" $
                matches [here|
        struct ordinary_double_struct {double ordinary_double_member;};
|] [here|
{- struct ordinary_double_struct {
    double ordinary_double_member;
}; -}
#starttype struct ordinary_double_struct
#field ordinary_double_member , CDouble
#stoptype
|]
            it "ordinary_long_double_struct" $
                matches [here|
        struct ordinary_long_double_struct {long double ordinary_long_double_member;};
|] [here|
{- struct ordinary_long_double_struct {
    long double ordinary_long_double_member;
}; -}
#starttype struct ordinary_long_double_struct
#field ordinary_long_double_member , CLong
#stoptype
|]
        describe "types which can be signed" $ do
            describe "char" $ do
                it "ordinary_signed_char_struct" $
                    matches [here|
          struct ordinary_signed_char_struct {char ordinary_signed_char_member;};
|] [here|
{- struct ordinary_signed_char_struct {
    char ordinary_signed_char_member;
}; -}
#starttype struct ordinary_signed_char_struct
#field ordinary_signed_char_member , CChar
#stoptype
|]
                it "explicit_signed_char_struct" $
                    matches [here|
          struct explicit_signed_char_struct {signed char explicit_signed_char_member;};
|] [here|
{- struct explicit_signed_char_struct {
    signed char explicit_signed_char_member;
}; -}
#starttype struct explicit_signed_char_struct
#field explicit_signed_char_member , CSChar
#stoptype
|]
                it "unsigned_char_struct" $
                    matches [here|
          struct unsigned_char_struct {unsigned char unsigned_char_member;};
|] [here|
{- struct unsigned_char_struct {
    unsigned char unsigned_char_member;
}; -}
#starttype struct unsigned_char_struct
#field unsigned_char_member , CUChar
#stoptype
|]
            describe "short" $ do
                it "ordinary_signed_short_struct" $
                    matches [here|
          struct ordinary_signed_short_struct {short ordinary_signed_short_member;};
|] [here|
{- struct ordinary_signed_short_struct {
    short ordinary_signed_short_member;
}; -}
#starttype struct ordinary_signed_short_struct
#field ordinary_signed_short_member , CShort
#stoptype
|]
                it "explicit_signed_short_struct" $
                    matches [here|
          struct explicit_signed_short_struct {signed short explicit_signed_short_member;};
|] [here|
{- struct explicit_signed_short_struct {
    signed short explicit_signed_short_member;
}; -}
#starttype struct explicit_signed_short_struct
#field explicit_signed_short_member , CShort
#stoptype
|]
                it "unsigned_short_struct" $
                    matches [here|
          struct unsigned_short_struct {unsigned short unsigned_short_member;};
|] [here|
{- struct unsigned_short_struct {
    unsigned short unsigned_short_member;
}; -}
#starttype struct unsigned_short_struct
#field unsigned_short_member , CUShort
#stoptype
|]
            describe "int" $ do
                it "ordinary_signed_int_struct" $
                    matches [here|
          struct ordinary_signed_int_struct {int ordinary_signed_int_member;};
|] [here|
{- struct ordinary_signed_int_struct {
    int ordinary_signed_int_member;
}; -}
#starttype struct ordinary_signed_int_struct
#field ordinary_signed_int_member , CInt
#stoptype
|]
                it "explicit_signed_int_struct" $
                    matches [here|
          struct explicit_signed_int_struct {signed int explicit_signed_int_member;};
|] [here|
{- struct explicit_signed_int_struct {
    signed int explicit_signed_int_member;
}; -}
#starttype struct explicit_signed_int_struct
#field explicit_signed_int_member , CInt
#stoptype
|]
                it "unsigned_int_struct" $
                    matches [here|
          struct unsigned_int_struct {unsigned int unsigned_int_member;};
|] [here|
{- struct unsigned_int_struct {
    unsigned int unsigned_int_member;
}; -}
#starttype struct unsigned_int_struct
#field unsigned_int_member , CUInt
#stoptype
|]
            describe "long" $ do
                it "ordinary_signed_long_struct" $
                    matches [here|
          struct ordinary_signed_long_struct {long ordinary_signed_long_member;};
|] [here|
{- struct ordinary_signed_long_struct {
    long ordinary_signed_long_member;
}; -}
#starttype struct ordinary_signed_long_struct
#field ordinary_signed_long_member , CLong
#stoptype
|]
                it "explicit_signed_long_struct" $
                    matches [here|
          struct explicit_signed_long_struct {signed long explicit_signed_long_member;};
|] [here|
{- struct explicit_signed_long_struct {
    signed long explicit_signed_long_member;
}; -}
#starttype struct explicit_signed_long_struct
#field explicit_signed_long_member , CLong
#stoptype
|]
                it "unsigned_long_struct" $
                    matches [here|
          struct unsigned_long_struct {unsigned long unsigned_long_member;};
|] [here|
{- struct unsigned_long_struct {
    unsigned long unsigned_long_member;
}; -}
#starttype struct unsigned_long_struct
#field unsigned_long_member , CULong
#stoptype
|]
            describe "long long" $ do
                it "ordinary_signed_long_long_struct" $
                    matches [here|
          struct ordinary_signed_long_long_struct {long long ordinary_signed_long_long_member;};
|] [here|
{- struct ordinary_signed_long_long_struct {
    long long ordinary_signed_long_long_member;
}; -}
#starttype struct ordinary_signed_long_long_struct
#field ordinary_signed_long_long_member , CLong
#stoptype
|]
                it "explicit_signed_long_long_struct" $
                    matches [here|
          struct explicit_signed_long_long_struct {signed long long explicit_signed_long_long_member;};
|] [here|
{- struct explicit_signed_long_long_struct {
    signed long long explicit_signed_long_long_member;
}; -}
#starttype struct explicit_signed_long_long_struct
#field explicit_signed_long_long_member , CLong
#stoptype
|]
                it "unsigned_long_long_struct" $
                    matches [here|
          struct unsigned_long_long_struct {unsigned long long unsigned_long_long_member;};
|] [here|
{- struct unsigned_long_long_struct {
    unsigned long long unsigned_long_long_member;
}; -}
#starttype struct unsigned_long_long_struct
#field unsigned_long_long_member , CULong
#stoptype
|]
        describe "pointers" $ do
            describe "primitive types which cannot be signed" $ do
                it "ordinary_void_pointer_struct" $
                    matches [here|
          struct ordinary_void_pointer_struct {void* ordinary_void_pointer_member;};
|] [here|
{- struct ordinary_void_pointer_struct {
    void * ordinary_void_pointer_member;
}; -}
#starttype struct ordinary_void_pointer_struct
#field ordinary_void_pointer_member , Ptr ()
#stoptype
|]
                it "ordinary_float_pointer_struct" $
                    matches [here|
          struct ordinary_float_pointer_struct {float* ordinary_float_pointer_member;};
|] [here|
{- struct ordinary_float_pointer_struct {
    float * ordinary_float_pointer_member;
}; -}
#starttype struct ordinary_float_pointer_struct
#field ordinary_float_pointer_member , Ptr CFloat
#stoptype
|]
                it "ordinary_double_pointer_struct" $
                    matches [here|
          struct ordinary_double_pointer_struct {double* ordinary_double_pointer_member;};
|] [here|
{- struct ordinary_double_pointer_struct {
    double * ordinary_double_pointer_member;
}; -}
#starttype struct ordinary_double_pointer_struct
#field ordinary_double_pointer_member , Ptr CDouble
#stoptype
|]
                it "ordinary_long_double_pointer_struct" $
                    matches [here|
          struct ordinary_long_double_pointer_struct {long double* ordinary_long_double_pointer_member;};
|] [here|
{- struct ordinary_long_double_pointer_struct {
    long double * ordinary_long_double_pointer_member;
}; -}
#starttype struct ordinary_long_double_pointer_struct
#field ordinary_long_double_pointer_member , Ptr CLong
#stoptype
|]
            describe "types which can be signed" $ do
                describe "char" $ do
                    it "ordinary_signed_char_pointer_struct" $
                        matches [here|
            struct ordinary_signed_char_pointer_struct {char *ordinary_signed_char_pointer_member;};
|] [here|
{- struct ordinary_signed_char_pointer_struct {
    char * ordinary_signed_char_pointer_member;
}; -}
#starttype struct ordinary_signed_char_pointer_struct
#field ordinary_signed_char_pointer_member , CString
#stoptype
|]
                    it "explicit_signed_char_pointer_struct" $
                        matches [here|
            struct explicit_signed_char_pointer_struct {signed char *explicit_signed_char_pointer_member;};
|] [here|
{- struct explicit_signed_char_pointer_struct {
    signed char * explicit_signed_char_pointer_member;
}; -}
#starttype struct explicit_signed_char_pointer_struct
#field explicit_signed_char_pointer_member , Ptr CSChar
#stoptype
|]
                    it "unsigned_char_pointer_struct" $
                        matches [here|
            struct unsigned_char_pointer_struct {unsigned char *unsigned_char_pointer_member;};
|] [here|
{- struct unsigned_char_pointer_struct {
    unsigned char * unsigned_char_pointer_member;
}; -}
#starttype struct unsigned_char_pointer_struct
#field unsigned_char_pointer_member , Ptr CUChar
#stoptype
|]
                describe "short" $ do
                    it "ordinary_signed_short_pointer_struct" $
                        matches [here|
            struct ordinary_signed_short_pointer_struct {short *ordinary_signed_short_pointer_member;};
|] [here|
{- struct ordinary_signed_short_pointer_struct {
    short * ordinary_signed_short_pointer_member;
}; -}
#starttype struct ordinary_signed_short_pointer_struct
#field ordinary_signed_short_pointer_member , Ptr CShort
#stoptype
|]
                    it "explicit_signed_short_pointer_struct" $
                        matches [here|
            struct explicit_signed_short_pointer_struct {signed short *explicit_signed_short_pointer_member;};
|] [here|
{- struct explicit_signed_short_pointer_struct {
    signed short * explicit_signed_short_pointer_member;
}; -}
#starttype struct explicit_signed_short_pointer_struct
#field explicit_signed_short_pointer_member , Ptr CShort
#stoptype
|]
                    it "unsigned_short_pointer_struct" $
                        matches [here|
            struct unsigned_short_pointer_struct {unsigned short *unsigned_short_pointer_member;};
|] [here|
{- struct unsigned_short_pointer_struct {
    unsigned short * unsigned_short_pointer_member;
}; -}
#starttype struct unsigned_short_pointer_struct
#field unsigned_short_pointer_member , Ptr CUShort
#stoptype
|]
                describe "int" $ do
                    it "ordinary_signed_int_pointer_struct" $
                        matches [here|
            struct ordinary_signed_int_pointer_struct {int* ordinary_signed_int_pointer_member;};
|] [here|
{- struct ordinary_signed_int_pointer_struct {
    int * ordinary_signed_int_pointer_member;
}; -}
#starttype struct ordinary_signed_int_pointer_struct
#field ordinary_signed_int_pointer_member , Ptr CInt
#stoptype
|]
                    it "explicit_signed_int_pointer_struct" $
                        matches [here|
            struct explicit_signed_int_pointer_struct {signed int* explicit_signed_int_pointer_member;};
|] [here|
{- struct explicit_signed_int_pointer_struct {
    signed int * explicit_signed_int_pointer_member;
}; -}
#starttype struct explicit_signed_int_pointer_struct
#field explicit_signed_int_pointer_member , Ptr CInt
#stoptype
|]
                    it "unsigned_int_pointer_struct" $
                        matches [here|
            struct unsigned_int_pointer_struct {unsigned int* unsigned_int_pointer_member;};
|] [here|
{- struct unsigned_int_pointer_struct {
    unsigned int * unsigned_int_pointer_member;
}; -}
#starttype struct unsigned_int_pointer_struct
#field unsigned_int_pointer_member , Ptr CUInt
#stoptype
|]
                describe "long" $ do
                    it "ordinary_signed_long_pointer_struct" $
                        matches [here|
            struct ordinary_signed_long_pointer_struct {long *ordinary_signed_long_pointer_member;};
|] [here|
{- struct ordinary_signed_long_pointer_struct {
    long * ordinary_signed_long_pointer_member;
}; -}
#starttype struct ordinary_signed_long_pointer_struct
#field ordinary_signed_long_pointer_member , Ptr CLong
#stoptype
|]
                    it "explicit_signed_long_pointer_struct" $
                        matches [here|
            struct explicit_signed_long_pointer_struct {signed long *explicit_signed_long_pointer_member;};
|] [here|
{- struct explicit_signed_long_pointer_struct {
    signed long * explicit_signed_long_pointer_member;
}; -}
#starttype struct explicit_signed_long_pointer_struct
#field explicit_signed_long_pointer_member , Ptr CLong
#stoptype
|]
                    it "unsigned_long_pointer_struct" $
                        matches [here|
            struct unsigned_long_pointer_struct {unsigned long *unsigned_long_pointer_member;};
|] [here|
{- struct unsigned_long_pointer_struct {
    unsigned long * unsigned_long_pointer_member;
}; -}
#starttype struct unsigned_long_pointer_struct
#field unsigned_long_pointer_member , Ptr CULong
#stoptype
|]
                describe "long long" $ do
                    it "ordinary_signed_long_long_pointer_struct" $
                        matches [here|
            struct ordinary_signed_long_long_pointer_struct {long long* ordinary_signed_long_long_pointer_member;};
|] [here|
{- struct ordinary_signed_long_long_pointer_struct {
    long long * ordinary_signed_long_long_pointer_member;
}; -}
#starttype struct ordinary_signed_long_long_pointer_struct
#field ordinary_signed_long_long_pointer_member , Ptr CLong
#stoptype
|]
                    it "explicit_signed_long_long_pointer_struct" $
                        matches [here|
            struct explicit_signed_long_long_pointer_struct {signed long long* explicit_signed_long_long_pointer_member;};
|] [here|
{- struct explicit_signed_long_long_pointer_struct {
    signed long long * explicit_signed_long_long_pointer_member;
}; -}
#starttype struct explicit_signed_long_long_pointer_struct
#field explicit_signed_long_long_pointer_member , Ptr CLong
#stoptype
|]
                    it "unsigned_long_long_pointer_struct" $
                        matches [here|
            struct unsigned_long_long_pointer_struct {unsigned long long* unsigned_long_long_pointer_member;};
|] [here|
{- struct unsigned_long_long_pointer_struct {
    unsigned long long * unsigned_long_long_pointer_member;
}; -}
#starttype struct unsigned_long_long_pointer_struct
#field unsigned_long_long_pointer_member , Ptr CULong
#stoptype
|]
            describe "arrays" $ do
                describe "primitive types which cannot be signed" $ do
                    it "ordinary_float_array_struct" $
                        matches [here|
          struct ordinary_float_array_struct {float ordinary_float_array_member[10];};
|] [here|
{- struct ordinary_float_array_struct {
    float ordinary_float_array_member[10];
}; -}
#starttype struct ordinary_float_array_struct
#array_field ordinary_float_array_member , CFloat
#stoptype
|]
                    it "ordinary_double_array_struct" $
                        matches [here|
          struct ordinary_double_array_struct {double ordinary_double_array_member[10];};
|] [here|
{- struct ordinary_double_array_struct {
    double ordinary_double_array_member[10];
}; -}
#starttype struct ordinary_double_array_struct
#array_field ordinary_double_array_member , CDouble
#stoptype
|]
                    it "ordinary_long_double_array_struct" $
                        matches [here|
          struct ordinary_long_double_array_struct {long double ordinary_long_double_array_member[10];};
|] [here|
{- struct ordinary_long_double_array_struct {
    long double ordinary_long_double_array_member[10];
}; -}
#starttype struct ordinary_long_double_array_struct
#array_field ordinary_long_double_array_member , CLong
#stoptype
|]
            describe "types which can be signed" $ do
                describe "char" $ do
                    it "ordinary_signed_char_array_struct" $
                        matches [here|
            struct ordinary_signed_char_array_struct {char ordinary_signed_char_array_member[10];};
|] [here|
{- struct ordinary_signed_char_array_struct {
    char ordinary_signed_char_array_member[10];
}; -}
#starttype struct ordinary_signed_char_array_struct
#array_field ordinary_signed_char_array_member , CChar
#stoptype
|]
                    it "explicit_signed_char_array_struct" $
                        matches [here|
            struct explicit_signed_char_array_struct {signed char explicit_signed_char_array_member[10];};
|] [here|
{- struct explicit_signed_char_array_struct {
    signed char explicit_signed_char_array_member[10];
}; -}
#starttype struct explicit_signed_char_array_struct
#array_field explicit_signed_char_array_member , CSChar
#stoptype
|]
                    it "unsigned_char_array_struct" $
                        matches [here|
            struct unsigned_char_array_struct {unsigned char unsigned_char_array_member[10];};
|] [here|
{- struct unsigned_char_array_struct {
    unsigned char unsigned_char_array_member[10];
}; -}
#starttype struct unsigned_char_array_struct
#array_field unsigned_char_array_member , CUChar
#stoptype
|]
                describe "short" $ do
                    it "ordinary_signed_short_array_struct" $
                        matches [here|
            struct ordinary_signed_short_array_struct {short ordinary_signed_short_array_member[10];};
|] [here|
{- struct ordinary_signed_short_array_struct {
    short ordinary_signed_short_array_member[10];
}; -}
#starttype struct ordinary_signed_short_array_struct
#array_field ordinary_signed_short_array_member , CShort
#stoptype
|]
                    it "explicit_signed_short_array_struct" $
                        matches [here|
            struct explicit_signed_short_array_struct {signed short explicit_signed_short_array_member[10];};
|] [here|
{- struct explicit_signed_short_array_struct {
    signed short explicit_signed_short_array_member[10];
}; -}
#starttype struct explicit_signed_short_array_struct
#array_field explicit_signed_short_array_member , CShort
#stoptype
|]
                    it "unsigned_short_array_struct" $
                        matches [here|
            struct unsigned_short_array_struct {unsigned short unsigned_short_array_member[10];};
|] [here|
{- struct unsigned_short_array_struct {
    unsigned short unsigned_short_array_member[10];
}; -}
#starttype struct unsigned_short_array_struct
#array_field unsigned_short_array_member , CUShort
#stoptype
|]
                describe "int" $ do
                    it "ordinary_signed_int_array_struct" $
                        matches [here|
            struct ordinary_signed_int_array_struct {int ordinary_signed_int_array_member[10];};
|] [here|
{- struct ordinary_signed_int_array_struct {
    int ordinary_signed_int_array_member[10];
}; -}
#starttype struct ordinary_signed_int_array_struct
#array_field ordinary_signed_int_array_member , CInt
#stoptype
|]
                    it "explicit_signed_int_array_struct" $
                        matches [here|
            struct explicit_signed_int_array_struct {signed int explicit_signed_int_array_member[10];};
|] [here|
{- struct explicit_signed_int_array_struct {
    signed int explicit_signed_int_array_member[10];
}; -}
#starttype struct explicit_signed_int_array_struct
#array_field explicit_signed_int_array_member , CInt
#stoptype
|]
                    it "unsigned_int_array_struct" $
                        matches [here|
            struct unsigned_int_array_struct {unsigned int unsigned_int_array_member[10];};
|] [here|
{- struct unsigned_int_array_struct {
    unsigned int unsigned_int_array_member[10];
}; -}
#starttype struct unsigned_int_array_struct
#array_field unsigned_int_array_member , CUInt
#stoptype
|]
                describe "long" $ do
                    it "ordinary_signed_long_array_struct" $
                        matches [here|
            struct ordinary_signed_long_array_struct {long ordinary_signed_long_array_member[10];};
|] [here|
{- struct ordinary_signed_long_array_struct {
    long ordinary_signed_long_array_member[10];
}; -}
#starttype struct ordinary_signed_long_array_struct
#array_field ordinary_signed_long_array_member , CLong
#stoptype
|]
                    it "explicit_signed_long_array_struct" $
                        matches [here|
            struct explicit_signed_long_array_struct {signed long explicit_signed_long_array_member[10];};
|] [here|
{- struct explicit_signed_long_array_struct {
    signed long explicit_signed_long_array_member[10];
}; -}
#starttype struct explicit_signed_long_array_struct
#array_field explicit_signed_long_array_member , CLong
#stoptype
|]
                    it "unsigned_long_array_struct" $
                        matches [here|
            struct unsigned_long_array_struct {unsigned long unsigned_long_array_member[10];};
|] [here|
{- struct unsigned_long_array_struct {
    unsigned long unsigned_long_array_member[10];
}; -}
#starttype struct unsigned_long_array_struct
#array_field unsigned_long_array_member , CULong
#stoptype
|]
                describe "long long" $ do
                    it "ordinary_signed_long_long_array_struct" $
                        matches [here|
            struct ordinary_signed_long_long_array_struct {long long ordinary_signed_long_long_array_member[10];};
|] [here|
{- struct ordinary_signed_long_long_array_struct {
    long long ordinary_signed_long_long_array_member[10];
}; -}
#starttype struct ordinary_signed_long_long_array_struct
#array_field ordinary_signed_long_long_array_member , CLong
#stoptype
|]
                    it "explicit_signed_long_long_array_struct" $
                        matches [here|
            struct explicit_signed_long_long_array_struct {signed long long explicit_signed_long_long_array_member[10];};
|] [here|
{- struct explicit_signed_long_long_array_struct {
    signed long long explicit_signed_long_long_array_member[10];
}; -}
#starttype struct explicit_signed_long_long_array_struct
#array_field explicit_signed_long_long_array_member , CLong
#stoptype
|]
                    it "unsigned_long_long_array_struct" $
                        matches [here|
            struct unsigned_long_long_array_struct {unsigned long long unsigned_long_long_array_member[10];};
|] [here|
{- struct unsigned_long_long_array_struct {
    unsigned long long unsigned_long_long_array_member[10];
}; -}
#starttype struct unsigned_long_long_array_struct
#array_field unsigned_long_long_array_member , CULong
#stoptype
|]
            describe "pointers" $ do
                describe "primitive types which cannot be signed" $ do
                    it "ordinary_void_pointer_array_struct" $
                        matches [here|
            struct ordinary_void_pointer_array_struct {void* ordinary_void_pointer_array_member[10];};
|] [here|
{- struct ordinary_void_pointer_array_struct {
    void * ordinary_void_pointer_array_member[10];
}; -}
#starttype struct ordinary_void_pointer_array_struct
#array_field ordinary_void_pointer_array_member , Ptr ()
#stoptype
|]
                    it "ordinary_float_pointer_array_struct" $
                        matches [here|
            struct ordinary_float_pointer_array_struct {float* ordinary_float_pointer_array_member[10];};
|] [here|
{- struct ordinary_float_pointer_array_struct {
    float * ordinary_float_pointer_array_member[10];
}; -}
#starttype struct ordinary_float_pointer_array_struct
#array_field ordinary_float_pointer_array_member , Ptr CFloat
#stoptype
|]
                    it "ordinary_double_pointer_array_struct" $
                        matches [here|
            struct ordinary_double_pointer_array_struct {double* ordinary_double_pointer_array_member[10];};
|] [here|
{- struct ordinary_double_pointer_array_struct {
    double * ordinary_double_pointer_array_member[10];
}; -}
#starttype struct ordinary_double_pointer_array_struct
#array_field ordinary_double_pointer_array_member , Ptr CDouble
#stoptype
|]
                    it "ordinary_long_double_pointer_array_struct" $
                        matches [here|
            struct ordinary_long_double_pointer_array_struct {long double* ordinary_long_double_pointer_array_member[10];};
|] [here|
{- struct ordinary_long_double_pointer_array_struct {
    long double * ordinary_long_double_pointer_array_member[10];
}; -}
#starttype struct ordinary_long_double_pointer_array_struct
#array_field ordinary_long_double_pointer_array_member , Ptr CLong
#stoptype
|]
                describe "types which can be signed" $ do
                    describe "char" $ do
                        it "ordinary_signed_char_pointer_array_struct" $
                            matches [here|
              struct ordinary_signed_char_pointer_array_struct {char *ordinary_signed_char_pointer_array_member[10];};
|] [here|
{- struct ordinary_signed_char_pointer_array_struct {
    char * ordinary_signed_char_pointer_array_member[10];
}; -}
#starttype struct ordinary_signed_char_pointer_array_struct
#array_field ordinary_signed_char_pointer_array_member , CString
#stoptype
|]
                        it "explicit_signed_char_pointer_array_struct" $
                            matches [here|
              struct explicit_signed_char_pointer_array_struct {signed char *explicit_signed_char_pointer_array_member[10];};
|] [here|
{- struct explicit_signed_char_pointer_array_struct {
    signed char * explicit_signed_char_pointer_array_member[10];
}; -}
#starttype struct explicit_signed_char_pointer_array_struct
#array_field explicit_signed_char_pointer_array_member , Ptr CSChar
#stoptype
|]
                        it "unsigned_char_pointer_array_struct" $
                            matches [here|
              struct unsigned_char_pointer_array_struct {unsigned char *unsigned_char_pointer_array_member[10];};
|] [here|
{- struct unsigned_char_pointer_array_struct {
    unsigned char * unsigned_char_pointer_array_member[10];
}; -}
#starttype struct unsigned_char_pointer_array_struct
#array_field unsigned_char_pointer_array_member , Ptr CUChar
#stoptype
|]
                    describe "short" $ do
                        it "ordinary_signed_short_pointer_array_struct" $
                            matches [here|
              struct ordinary_signed_short_pointer_array_struct {short *ordinary_signed_short_pointer_array_member[10];};
|] [here|
{- struct ordinary_signed_short_pointer_array_struct {
    short * ordinary_signed_short_pointer_array_member[10];
}; -}
#starttype struct ordinary_signed_short_pointer_array_struct
#array_field ordinary_signed_short_pointer_array_member , Ptr CShort
#stoptype
|]
                        it "explicit_signed_short_pointer_array_struct" $
                            matches [here|
              struct explicit_signed_short_pointer_array_struct {signed short *explicit_signed_short_pointer_array_member[10];};
|] [here|
{- struct explicit_signed_short_pointer_array_struct {
    signed short * explicit_signed_short_pointer_array_member[10];
}; -}
#starttype struct explicit_signed_short_pointer_array_struct
#array_field explicit_signed_short_pointer_array_member , Ptr CShort
#stoptype
|]
                        it "unsigned_short_pointer_array_struct" $
                            matches [here|
              struct unsigned_short_pointer_array_struct {unsigned short *unsigned_short_pointer_array_member[10];};
|] [here|
{- struct unsigned_short_pointer_array_struct {
    unsigned short * unsigned_short_pointer_array_member[10];
}; -}
#starttype struct unsigned_short_pointer_array_struct
#array_field unsigned_short_pointer_array_member , Ptr CUShort
#stoptype
|]
                    describe "int" $ do
                        it "ordinary_signed_int_pointer_array_struct" $
                            matches [here|
              struct ordinary_signed_int_pointer_array_struct {int* ordinary_signed_int_pointer_array_member[10];};
|] [here|
{- struct ordinary_signed_int_pointer_array_struct {
    int * ordinary_signed_int_pointer_array_member[10];
}; -}
#starttype struct ordinary_signed_int_pointer_array_struct
#array_field ordinary_signed_int_pointer_array_member , Ptr CInt
#stoptype
|]
                        it "explicit_signed_int_pointer_array_struct" $
                            matches [here|
              struct explicit_signed_int_pointer_array_struct {signed int* explicit_signed_int_pointer_array_member[10];};
|] [here|
{- struct explicit_signed_int_pointer_array_struct {
    signed int * explicit_signed_int_pointer_array_member[10];
}; -}
#starttype struct explicit_signed_int_pointer_array_struct
#array_field explicit_signed_int_pointer_array_member , Ptr CInt
#stoptype
|]
                        it "unsigned_int_pointer_array_struct" $
                            matches [here|
              struct unsigned_int_pointer_array_struct {unsigned int* unsigned_int_pointer_array_member[10];};
|] [here|
{- struct unsigned_int_pointer_array_struct {
    unsigned int * unsigned_int_pointer_array_member[10];
}; -}
#starttype struct unsigned_int_pointer_array_struct
#array_field unsigned_int_pointer_array_member , Ptr CUInt
#stoptype
|]
                    describe "long" $ do
                        it "ordinary_signed_long_pointer_array_struct" $
                            matches [here|
              struct ordinary_signed_long_pointer_array_struct {long *ordinary_signed_long_pointer_array_member[10];};
|] [here|
{- struct ordinary_signed_long_pointer_array_struct {
    long * ordinary_signed_long_pointer_array_member[10];
}; -}
#starttype struct ordinary_signed_long_pointer_array_struct
#array_field ordinary_signed_long_pointer_array_member , Ptr CLong
#stoptype
|]
                        it "explicit_signed_long_pointer_array_struct" $
                            matches [here|
              struct explicit_signed_long_pointer_array_struct {signed long *explicit_signed_long_pointer_array_member[10];};
|] [here|
{- struct explicit_signed_long_pointer_array_struct {
    signed long * explicit_signed_long_pointer_array_member[10];
}; -}
#starttype struct explicit_signed_long_pointer_array_struct
#array_field explicit_signed_long_pointer_array_member , Ptr CLong
#stoptype
|]
                        it "unsigned_long_pointer_array_struct" $
                            matches [here|
              struct unsigned_long_pointer_array_struct {unsigned long *unsigned_long_pointer_array_member[10];};
|] [here|
{- struct unsigned_long_pointer_array_struct {
    unsigned long * unsigned_long_pointer_array_member[10];
}; -}
#starttype struct unsigned_long_pointer_array_struct
#array_field unsigned_long_pointer_array_member , Ptr CULong
#stoptype
|]
                    describe "long long" $ do
                        it "ordinary_signed_long_long_pointer_array_struct" $
                            matches [here|
              struct ordinary_signed_long_long_pointer_array_struct {long long* ordinary_signed_long_long_pointer_array_member[10];};
|] [here|
{- struct ordinary_signed_long_long_pointer_array_struct {
    long long * ordinary_signed_long_long_pointer_array_member[10];
}; -}
#starttype struct ordinary_signed_long_long_pointer_array_struct
#array_field ordinary_signed_long_long_pointer_array_member , Ptr CLong
#stoptype
|]
                        it "explicit_signed_long_long_pointer_array_struct" $
                            matches [here|
              struct explicit_signed_long_long_pointer_array_struct {signed long long* explicit_signed_long_long_pointer_array_member[10];};
|] [here|
{- struct explicit_signed_long_long_pointer_array_struct {
    signed long long * explicit_signed_long_long_pointer_array_member[10];
}; -}
#starttype struct explicit_signed_long_long_pointer_array_struct
#array_field explicit_signed_long_long_pointer_array_member , Ptr CLong
#stoptype
|]
                        it "unsigned_long_long_pointer_array_struct" $
                            matches [here|
              struct unsigned_long_long_pointer_array_struct {unsigned long long* unsigned_long_long_pointer_array_member[10];};
|] [here|
{- struct unsigned_long_long_pointer_array_struct {
    unsigned long long * unsigned_long_long_pointer_array_member[10];
}; -}
#starttype struct unsigned_long_long_pointer_array_struct
#array_field unsigned_long_long_pointer_array_member , Ptr CULong
#stoptype
|]

matches :: String -> String -> IO ()
matches input output = do
    res <- processString input
    trim res `shouldBe` output

tshow :: String -> Text
tshow = pack . show

trim :: String -> String
trim = trimTail . dropWhile isSpace

trimTail :: String -> String
trimTail "" = ""
trimTail s = take (lastNonBlank s) s
  where lastNonBlank = (+1) . fst . foldl acc (0, 0)
        acc (l, n) c | isSpace c = (l, n + 1)
                     | otherwise = (n, n + 1)