/*
 * Copyright (c) 2015 Cisco Systems, Inc.  All rights reserved.
 * Copyright (c) 2017      Intel, Inc.  All rights reserved.
 * $COPYRIGHT$
 *
 * Additional copyrights may follow
 *
 * $HEADER$
 */

#ifndef SCON_SDL_LIBLTDL
#define SCON_SDL_LIBLTDL

#include "scon_config.h"

#include "scon/mca/sdl/sdl.h"

#include <ltdl.h>


SCON_DECLSPEC extern scon_sdl_base_module_t scon_sdl_slibltsdl_module;

/*
 * Dynamic library handles generated by this component.
 *
 * If we're debugging, keep a copy of the name of the file we've opened.
 */
struct scon_sdl_handle_t {
    lt_dlhandle ltsdl_handle;
#if SCON_ENABLE_DEBUG
    char *filename;
#endif
};

typedef struct {
    scon_sdl_base_component_t base;

#if SCON_DL_LIBLTDL_HAVE_LT_DLADVISE
    /* If the version of slibltdl that we are compiling against has
       lt_dladvise, use it to support opening DSOs in a variety of
       modes. */
    lt_dladvise advise_private_noext;
    lt_dladvise advise_private_ext;
    lt_dladvise advise_public_noext;
    lt_dladvise advise_public_ext;
#endif
} scon_sdl_slibltsdl_component_t;

SCON_DECLSPEC extern scon_sdl_slibltsdl_component_t mca_sdl_slibltsdl_component;

#endif /* SCON_DL_LIBLTDL */
