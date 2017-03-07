/* -*- Mode: C; c-basic-offset:4 ; indent-tabs-mode:nil -*- */
/*
 * Copyright (c) 2007-2015 Los Alamos National Security, LLC. All rights
 *                         reserved.
 * Copyright (c) 2004-2008 The Trustees of Indiana University.
 *                         All rights reserved.
 * Copyright (c) 2016      Intel, Inc.  All rights reserved.
 * $COPYRIGHT$
 *
 * Additional copyrights may follow
 *
 * $HEADER$
 */

#include <src/include/scon_config.h>
#include <scon_common.h>

#include "src/mca/mca.h"
#include "src/mca/base/base.h"

#include "collectives_default.h"

static scon_collectives_module_t* default_get_module(void);

/**
 * component definition
 */
SCON_EXPORT scon_collectives_base_component_t scon_collectives_default_component = {
    /* First, the mca_base_component_t struct containing meta
       information about the component itself */
    .base_version =
        {
            SCON_COLLECTIVES_BASE_VERSION_1_0_0,
            .scon_mca_component_name = "default",
            /* Component name and version */
            SCON_MCA_BASE_MAKE_VERSION(component, SCON_MAJOR_VERSION,
            SCON_MINOR_VERSION,
            SCON_RELEASE_VERSION),
        },
        .get_module = default_get_module
};

static scon_collectives_module_t* default_get_module()
{
    return &scon_collectives_default_module ;
}
