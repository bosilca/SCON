# -*- shell-script -*-
# SCON copyrights:
# Copyright (c) 2013      Intel, Inc. All rights reserved
#
#########################
#
# Copyright (c) 2004-2007 The Trustees of Indiana University and Indiana
#                         University Research and Technology
#                         Corporation.  All rights reserved.
# Copyright (c) 2004-2005 The University of Tennessee and The University
#                         of Tennessee Research Foundation.  All rights
#                         reserved.
# Copyright (c) 2004-2010 High Performance Computing Center Stuttgart,
#                         University of Stuttgart.  All rights reserved.
# Copyright (c) 2004-2005 The Regents of the University of California.
#                         All rights reserved.
# Copyright (c) 2009      Oak Ridge National Labs.  All rights reserved.
# Copyright (c) 2010-2015 Cisco Systems, Inc.  All rights reserved.
# Copyright (c) 2013      Mellanox Technologies, Inc.
#                         All rights reserved.
# Copyright (c) 2017      Intel, Inc. All rights reserved.
#########################
# $COPYRIGHT$
#
# Additional copyrights may follow
#
# $HEADER$
#

#
# Search the generated warnings for
# keywords regarding skipping or ignoring certain attributes
#   Intel: ignore
#   Sun C++: skip
#
AC_DEFUN([_SCON_ATTRIBUTE_FAIL_SEARCH],[
    AC_REQUIRE([AC_PROG_GREP])
    if test -s conftest.err ; then
        # icc uses 'invalid attribute' and 'attribute "__XXX__"  ignored'
        # Sun 12.1 emits 'warning: attribute parameter "__printf__" is undefined'
        for i in invalid ignore skip undefined ; do
            $GREP -iq $i conftest.err
            if test "$?" = "0" ; then
                scon_cv___attribute__[$1]=0
                break;
            fi
        done
    fi
])

#
# Check for one specific attribute by compiling with C
#
# The last argument is for specific CFLAGS, that need to be set
# for the compiler to generate a warning on the cross-check.
# This may need adaption for future compilers / CFLAG-settings.
#
AC_DEFUN([_SCON_CHECK_SPECIFIC_ATTRIBUTE], [
    AC_MSG_CHECKING([for __attribute__([$1])])
    AC_CACHE_VAL(scon_cv___attribute__[$1], [
        #
        # Try to compile using the C compiler
        #
        AC_TRY_COMPILE([$2],[],
                       [
                        #
                        # In case we did succeed: Fine, but was this due to the
                        # attribute being ignored/skipped? Grep for IgNoRe/skip in conftest.err
                        # and if found, reset the scon_cv__attribute__var=0
                        #
                        scon_cv___attribute__[$1]=1
                        _SCON_ATTRIBUTE_FAIL_SEARCH([$1])
                       ],
                       [scon_cv___attribute__[$1]=0])
    ])

    if test "$scon_cv___attribute__[$1]" = "1" ; then
        AC_MSG_RESULT([yes])
    else
        AC_MSG_RESULT([no])
    fi
])


#
# Test the availability of __attribute__ and with the help
# of _SCON_CHECK_SPECIFIC_ATTRIBUTE for the support of
# particular attributes. Compilers, that do not support an
# attribute most often fail with a warning (when the warning
# level is set).
# The compilers output is parsed in _SCON_ATTRIBUTE_FAIL_SEARCH
#
# To add a new attributes __NAME__ add the
#   scon_cv___attribute__NAME
# add a new check with _SCON_CHECK_SPECIFIC_ATTRIBUTE (possibly with a cross-check)
#   _SCON_CHECK_SPECIFIC_ATTRIBUTE([name], [int foo (int arg) __attribute__ ((__name__));], [], [])
# and define the corresponding
#   AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_NAME, [$scon_cv___attribute__NAME],
#                      [Whether your compiler has __attribute__ NAME or not])
# and decide on a correct macro (in scon/include/scon_config_bottom.h):
#  #  define __scon_attribute_NAME(x)  __attribute__(__NAME__)
#
# Please use the "__"-notation of the attribute in order not to
# clash with predefined names or macros (e.g. const, which some compilers
# do not like..)
#


AC_DEFUN([SCON_CHECK_ATTRIBUTES], [
  AC_LANG(C)
  AC_MSG_CHECKING(for __attribute__)

  AC_CACHE_VAL(scon_cv___attribute__, [
    AC_TRY_COMPILE(
      [#include <stdlib.h>
       /* Check for the longest available __attribute__ (since gcc-2.3) */
       struct foo {
           char a;
           int x[2] __attribute__ ((__packed__));
        };
      ],
      [],
      [scon_cv___attribute__=1],
      [scon_cv___attribute__=0],
    )

    if test "$scon_cv___attribute__" = "1" ; then
        AC_TRY_COMPILE(
          [#include <stdlib.h>
           /* Check for the longest available __attribute__ (since gcc-2.3) */
           struct foo {
               char a;
               int x[2] __attribute__ ((__packed__));
            };
          ],
          [],
          [scon_cv___attribute__=1],
          [scon_cv___attribute__=0],
        )
    fi
    ])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE, [$scon_cv___attribute__],
                     [Whether your compiler has __attribute__ or not])

#
# Now that we know the compiler support __attribute__ let's check which kind of
# attributed are supported.
#
  if test "$scon_cv___attribute__" = "0" ; then
    AC_MSG_RESULT([no])
    scon_cv___attribute__aligned=0
    scon_cv___attribute__always_inline=0
    scon_cv___attribute__cold=0
    scon_cv___attribute__const=0
    scon_cv___attribute__deprecated=0
    scon_cv___attribute__deprecated_argument=0
    scon_cv___attribute__format=0
    scon_cv___attribute__format_funcptr=0
    scon_cv___attribute__hot=0
    scon_cv___attribute__malloc=0
    scon_cv___attribute__may_alias=0
    scon_cv___attribute__no_instrument_function=0
    scon_cv___attribute__nonnull=0
    scon_cv___attribute__noreturn=0
    scon_cv___attribute__noreturn_funcptr=0
    scon_cv___attribute__packed=0
    scon_cv___attribute__pure=0
    scon_cv___attribute__sentinel=0
    scon_cv___attribute__unused=0
    scon_cv___attribute__visibility=0
    scon_cv___attribute__warn_unused_result=0
    scon_cv___attribute__destructor=0
  else
    AC_MSG_RESULT([yes])

    _SCON_CHECK_SPECIFIC_ATTRIBUTE([aligned],
        [struct foo { char text[4]; }  __attribute__ ((__aligned__(8)));],
        [],
        [])

    #
    # Ignored by PGI-6.2.5; -- recognized by output-parser
    #
    _SCON_CHECK_SPECIFIC_ATTRIBUTE([always_inline],
        [int foo (int arg) __attribute__ ((__always_inline__));],
        [],
        [])

    _SCON_CHECK_SPECIFIC_ATTRIBUTE([cold],
        [
         int foo(int arg1, int arg2) __attribute__ ((__cold__));
         int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }
        ],
        [],
        [])

    _SCON_CHECK_SPECIFIC_ATTRIBUTE([const],
        [
         int foo(int arg1, int arg2) __attribute__ ((__const__));
         int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }
        ],
        [],
        [])

    _SCON_CHECK_SPECIFIC_ATTRIBUTE([deprecated],
        [
         int foo(int arg1, int arg2) __attribute__ ((__deprecated__));
         int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }
        ],
        [],
        [])

    _SCON_CHECK_SPECIFIC_ATTRIBUTE([deprecated_argument],
        [
         int foo(int arg1, int arg2) __attribute__ ((__deprecated__("compiler allows argument")));
         int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }
        ],
        [],
        [])

    ATTRIBUTE_CFLAGS=
    case "$scon_c_vendor" in
        gnu)
            ATTRIBUTE_CFLAGS="-Wall"
            ;;
        intel)
            # we want specifically the warning on format string conversion
            ATTRIBUTE_CFLAGS="-we181"
            ;;
    esac
    _SCON_CHECK_SPECIFIC_ATTRIBUTE([format],
        [
         int this_printf (void *my_object, const char *my_format, ...) __attribute__ ((__format__ (__printf__, 2, 3)));
        ],
        [
         static int usage (int * argument);
         extern int this_printf (int arg1, const char *my_format, ...) __attribute__ ((__format__ (__printf__, 2, 3)));

         static int usage (int * argument) {
             return this_printf (*argument, "%d", argument); /* This should produce a format warning */
         }
         /* The autoconf-generated main-function is int main(), which produces a warning by itself */
         int main(void);
        ],
        [$ATTRIBUTE_CFLAGS])

    ATTRIBUTE_CFLAGS=
    case "$scon_c_vendor" in
        gnu)
            ATTRIBUTE_CFLAGS="-Wall"
            ;;
        intel)
            # we want specifically the warning on format string conversion
            ATTRIBUTE_CFLAGS="-we181"
            ;;
    esac
    _SCON_CHECK_SPECIFIC_ATTRIBUTE([format_funcptr],
        [
         int (*this_printf)(void *my_object, const char *my_format, ...) __attribute__ ((__format__ (__printf__, 2, 3)));
        ],
        [
         static int usage (int * argument);
         extern int (*this_printf) (int arg1, const char *my_format, ...) __attribute__ ((__format__ (__printf__, 2, 3)));

         static int usage (int * argument) {
             return (*this_printf) (*argument, "%d", argument); /* This should produce a format warning */
         }
         /* The autoconf-generated main-function is int main(), which produces a warning by itself */
         int main(void);
        ],
        [$ATTRIBUTE_CFLAGS])

    _SCON_CHECK_SPECIFIC_ATTRIBUTE([hot],
        [
         int foo(int arg1, int arg2) __attribute__ ((__hot__));
         int foo(int arg1, int arg2) { return arg1 * arg2 + arg1; }
        ],
        [],
        [])

    _SCON_CHECK_SPECIFIC_ATTRIBUTE([malloc],
        [
#ifdef HAVE_STDLIB_H
#  include <stdlib.h>
#endif
         int * foo(int arg1) __attribute__ ((__malloc__));
         int * foo(int arg1) { return (int*) malloc(arg1); }
        ],
        [],
        [])


    #
    # Attribute may_alias: No suitable cross-check available, that works for non-supporting compilers
    # Ignored by intel-9.1.045 -- turn off with -wd1292
    # Ignored by PGI-6.2.5; ignore not detected due to missing cross-check
    #
    _SCON_CHECK_SPECIFIC_ATTRIBUTE([may_alias],
        [int * p_value __attribute__ ((__may_alias__));],
        [],
        [])


    _SCON_CHECK_SPECIFIC_ATTRIBUTE([no_instrument_function],
        [int * foo(int arg1) __attribute__ ((__no_instrument_function__));],
        [],
        [])


    #
    # Attribute nonnull:
    # Ignored by intel-compiler 9.1.045 -- recognized by cross-check
    # Ignored by PGI-6.2.5 (pgCC) -- recognized by cross-check
    #
    ATTRIBUTE_CFLAGS=
    case "$scon_c_vendor" in
        gnu)
            ATTRIBUTE_CFLAGS="-Wall"
            ;;
        intel)
            # we do not want to get ignored attributes warnings, but rather real warnings
            ATTRIBUTE_CFLAGS="-wd1292"
            ;;
    esac
    _SCON_CHECK_SPECIFIC_ATTRIBUTE([nonnull],
        [
         int square(int *arg) __attribute__ ((__nonnull__));
         int square(int *arg) { return *arg; }
        ],
        [
         static int usage(int * argument);
         int square(int * argument) __attribute__ ((__nonnull__));
         int square(int * argument) { return (*argument) * (*argument); }

         static int usage(int * argument) {
             return square( ((void*)0) );    /* This should produce an argument must be nonnull warning */
         }
         /* The autoconf-generated main-function is int main(), which produces a warning by itself */
         int main(void);
        ],
        [$ATTRIBUTE_CFLAGS])


    _SCON_CHECK_SPECIFIC_ATTRIBUTE([noreturn],
        [
#ifdef HAVE_UNISTD_H
#  include <unistd.h>
#endif
#ifdef HAVE_STDLIB_H
#  include <stdlib.h>
#endif
         void fatal(int arg1) __attribute__ ((__noreturn__));
         void fatal(int arg1) { exit(arg1); }
        ],
        [],
        [])


    _SCON_CHECK_SPECIFIC_ATTRIBUTE([noreturn_funcptr],
        [
#ifdef HAVE_UNISTD_H
#  include <unistd.h>
#endif
#ifdef HAVE_STDLIB_H
#  include <stdlib.h>
#endif
         extern void (*fatal_exit)(int arg1) __attribute__ ((__noreturn__));
         void fatal(int arg1) { fatal_exit (arg1); }
        ],
        [],
        [$ATTRIBUTE_CFLAGS])


    _SCON_CHECK_SPECIFIC_ATTRIBUTE([packed],
        [
         struct foo {
             char a;
             int x[2] __attribute__ ((__packed__));
         };
        ],
        [],
        [])

    _SCON_CHECK_SPECIFIC_ATTRIBUTE([pure],
        [
         int square(int arg) __attribute__ ((__pure__));
         int square(int arg) { return arg * arg; }
        ],
        [],
        [])

    #
    # Attribute sentinel:
    # Ignored by the intel-9.1.045 -- recognized by cross-check
    #                intel-10.0beta works fine
    # Ignored by PGI-6.2.5 (pgCC) -- recognized by output-parser and cross-check
    # Ignored by pathcc-2.2.1 -- recognized by cross-check (through grep ignore)
    #
    ATTRIBUTE_CFLAGS=
    case "$scon_c_vendor" in
        gnu)
            ATTRIBUTE_CFLAGS="-Wall"
            ;;
        intel)
            # we do not want to get ignored attributes warnings
            ATTRIBUTE_CFLAGS="-wd1292"
            ;;
    esac
    _SCON_CHECK_SPECIFIC_ATTRIBUTE([sentinel],
        [
         int my_execlp(const char * file, const char *arg, ...) __attribute__ ((__sentinel__));
        ],
        [
         static int usage(int * argument);
         int my_execlp(const char * file, const char *arg, ...) __attribute__ ((__sentinel__));

         static int usage(int * argument) {
             void * last_arg_should_be_null = argument;
             return my_execlp ("lala", "/home/there", last_arg_should_be_null);   /* This should produce a warning */
         }
         /* The autoconf-generated main-function is int main(), which produces a warning by itself */
         int main(void);
        ],
        [$ATTRIBUTE_CFLAGS])

    _SCON_CHECK_SPECIFIC_ATTRIBUTE([unused],
        [
         int square(int arg1 __attribute__ ((__unused__)), int arg2);
         int square(int arg1, int arg2) { return arg2; }
        ],
        [],
        [])


    #
    # Ignored by PGI-6.2.5 (pgCC) -- recognized by the output-parser
    #
    _SCON_CHECK_SPECIFIC_ATTRIBUTE([visibility],
        [
         int square(int arg1) __attribute__ ((__visibility__("hidden")));
        ],
        [],
        [])


    #
    # Attribute warn_unused_result:
    # Ignored by the intel-compiler 9.1.045 -- recognized by cross-check
    # Ignored by pathcc-2.2.1 -- recognized by cross-check (through grep ignore)
    #
    ATTRIBUTE_CFLAGS=
    case "$scon_c_vendor" in
        gnu)
            ATTRIBUTE_CFLAGS="-Wall"
            ;;
        intel)
            # we do not want to get ignored attributes warnings
            ATTRIBUTE_CFLAGS="-wd1292"
            ;;
    esac
    _SCON_CHECK_SPECIFIC_ATTRIBUTE([warn_unused_result],
        [
         int foo(int arg) __attribute__ ((__warn_unused_result__));
         int foo(int arg) { return arg + 3; }
        ],
        [
         static int usage(int * argument);
         int foo(int arg) __attribute__ ((__warn_unused_result__));

         int foo(int arg) { return arg + 3; }
         static int usage(int * argument) {
           foo (*argument);        /* Should produce an unused result warning */
           return 0;
         }

         /* The autoconf-generated main-function is int main(), which produces a warning by itself */
         int main(void);
        ],
        [$ATTRIBUTE_CFLAGS])


    _SCON_CHECK_SPECIFIC_ATTRIBUTE([destructor],
        [
        void foo(void) __attribute__ ((__destructor__));
        void foo(void) { return ; }
        ],
        [],
        [])
  fi

  # Now that all the values are set, define them

  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_ALIGNED, [$scon_cv___attribute__aligned],
                     [Whether your compiler has __attribute__ aligned or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_ALWAYS_INLINE, [$scon_cv___attribute__always_inline],
                     [Whether your compiler has __attribute__ always_inline or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_COLD, [$scon_cv___attribute__cold],
                     [Whether your compiler has __attribute__ cold or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_CONST, [$scon_cv___attribute__const],
                     [Whether your compiler has __attribute__ const or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_DEPRECATED, [$scon_cv___attribute__deprecated],
                     [Whether your compiler has __attribute__ deprecated or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_DEPRECATED_ARGUMENT, [$scon_cv___attribute__deprecated_argument],
                     [Whether your compiler has __attribute__ deprecated with optional argument])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_FORMAT, [$scon_cv___attribute__format],
                     [Whether your compiler has __attribute__ format or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_FORMAT_FUNCPTR, [$scon_cv___attribute__format_funcptr],
                     [Whether your compiler has __attribute__ format and it works on function pointers])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_HOT, [$scon_cv___attribute__hot],
                     [Whether your compiler has __attribute__ hot or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_MALLOC, [$scon_cv___attribute__malloc],
                     [Whether your compiler has __attribute__ malloc or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_MAY_ALIAS, [$scon_cv___attribute__may_alias],
                     [Whether your compiler has __attribute__ may_alias or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_NO_INSTRUMENT_FUNCTION, [$scon_cv___attribute__no_instrument_function],
                     [Whether your compiler has __attribute__ no_instrument_function or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_NONNULL, [$scon_cv___attribute__nonnull],
                     [Whether your compiler has __attribute__ nonnull or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_NORETURN, [$scon_cv___attribute__noreturn],
                     [Whether your compiler has __attribute__ noreturn or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_NORETURN_FUNCPTR, [$scon_cv___attribute__noreturn_funcptr],
                     [Whether your compiler has __attribute__ noreturn and it works on function pointers])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_PACKED, [$scon_cv___attribute__packed],
                     [Whether your compiler has __attribute__ packed or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_PURE, [$scon_cv___attribute__pure],
                     [Whether your compiler has __attribute__ pure or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_SENTINEL, [$scon_cv___attribute__sentinel],
                     [Whether your compiler has __attribute__ sentinel or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_UNUSED, [$scon_cv___attribute__unused],
                     [Whether your compiler has __attribute__ unused or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_VISIBILITY, [$scon_cv___attribute__visibility],
                     [Whether your compiler has __attribute__ visibility or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_WARN_UNUSED_RESULT, [$scon_cv___attribute__warn_unused_result],
                     [Whether your compiler has __attribute__ warn unused result or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_WEAK_ALIAS, [$scon_cv___attribute__weak_alias],
                     [Whether your compiler has __attribute__ weak alias or not])
  AC_DEFINE_UNQUOTED(SCON_HAVE_ATTRIBUTE_DESTRUCTOR, [$scon_cv___attribute__destructor],
                     [Whether your compiler has __attribute__ destructor or not])
])
