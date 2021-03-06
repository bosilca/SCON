/*
 * Copyright (c) 2010      Cisco Systems, Inc.  All rights reserved.
 * Copyright (c) 2010      Oracle and/or its affiliates.  All rights reserved.
 * Copyright (c) 2017      Intel, Inc. All rights reserved.
 * $COPYRIGHT$
 *
 * Additional copyrights may follow
 *
 * $HEADER$
 */

#include "scon_config.h"

#include <string.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <errno.h>
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
#ifdef HAVE_SYS_SOCKIO_H
#include <sys/sockio.h>
#endif
#ifdef HAVE_SYS_IOCTL_H
#include <sys/ioctl.h>
#endif
#ifdef HAVE_NETINET_IN_H
#include <netinet/in.h>
#endif
#ifdef HAVE_ARPA_INET_H
#include <arpa/inet.h>
#endif
#ifdef HAVE_NET_IF_H
#if defined(__APPLE__) && defined(_LP64)
/* Apple engineering suggested using options align=power as a
   workaround for a bug in OS X 10.4 (Tiger) that prevented ioctl(...,
   SIOCGIFCONF, ...) from working properly in 64 bit mode on Power PC.
   It turns out that the underlying issue is the size of struct
   ifconf, which the kernel expects to be 12 and natural 64 bit
   alignment would make 16.  The same bug appears in 64 bit mode on
   Intel macs, but align=power is a no-op there, so instead, use the
   pack pragma to instruct the compiler to pack on 4 byte words, which
   has the same effect as align=power for our needs and works on both
   Intel and Power PC Macs. */
#pragma pack(push,4)
#endif
#include <net/if.h>
#if defined(__APPLE__) && defined(_LP64)
#pragma pack(pop)
#endif
#endif
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif
#ifdef HAVE_IFADDRS_H
#include <ifaddrs.h>
#endif

#include "src/util/error.h"
#include "src/util/if.h"
#include "src/util/output.h"
#include "src/mca/if/if.h"
#include "src/mca/if/base/base.h"

static int if_linux_ipv6_open(void);

/* Discovers Linux IPv6 interfaces */
scon_if_base_component_t mca_if_linux_ipv6_component = {
    /* First, the mca_component_t struct containing meta information
       about the component itself */
    {
        SCON_IF_BASE_VERSION_1_0_0,

        /* Component name and version */
        "linux_ipv6",
        SCON_MAJOR_VERSION,
        SCON_MINOR_VERSION,
        SCON_RELEASE_VERSION,

        /* Component open and close functions */
        if_linux_ipv6_open,
        NULL
    },
    {
        /* This component is checkpointable */
        SCON_MCA_BASE_METADATA_PARAM_CHECKPOINT
    },
};

/* configure using getifaddrs(3) */
static int if_linux_ipv6_open(void)
{
#if SCON_ENABLE_IPV6
    FILE *f;
    if ((f = fopen("/proc/net/if_inet6", "r"))) {
        char ifname[IF_NAMESIZE];
        unsigned int idx, pfxlen, scope, dadstat;
        struct in6_addr a6;
        int iter;
        uint32_t flag;
        unsigned int addrbyte[16];

        while (fscanf(f, "%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x %x %x %x %x %20s\n",
                      &addrbyte[0], &addrbyte[1], &addrbyte[2], &addrbyte[3],
                      &addrbyte[4], &addrbyte[5], &addrbyte[6], &addrbyte[7],
                      &addrbyte[8], &addrbyte[9], &addrbyte[10], &addrbyte[11],
                      &addrbyte[12], &addrbyte[13], &addrbyte[14], &addrbyte[15],
                      &idx, &pfxlen, &scope, &dadstat, ifname) != EOF) {
            scon_if_t *intf;

            scon_output_verbose(1, scon_if_base_framework.framework_output,
                                "found interface %2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x scope %x\n",
                                addrbyte[0], addrbyte[1], addrbyte[2], addrbyte[3],
                                addrbyte[4], addrbyte[5], addrbyte[6], addrbyte[7],
                                addrbyte[8], addrbyte[9], addrbyte[10], addrbyte[11],
                                addrbyte[12], addrbyte[13], addrbyte[14], addrbyte[15], scope);

            /* we don't want any other scope less than link-local */
            if (scope < 0x20) {
                scon_output_verbose(1, scon_if_base_framework.framework_output,
                                    "skipping interface %2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x scope %x\n",
                                    addrbyte[0], addrbyte[1], addrbyte[2], addrbyte[3],
                                    addrbyte[4], addrbyte[5], addrbyte[6], addrbyte[7],
                                    addrbyte[8], addrbyte[9], addrbyte[10], addrbyte[11],
                                    addrbyte[12], addrbyte[13], addrbyte[14], addrbyte[15], scope);
                continue;
            }

            intf = SCON_NEW(scon_if_t);
            if (NULL == intf) {
                scon_output(0, "scon_ifinit: unable to allocate %lu bytes\n",
                            (unsigned long)sizeof(scon_if_t));
                fclose(f);
                return SCON_ERR_OUT_OF_RESOURCE;
            }
            intf->af_family = AF_INET6;

            for (iter = 0; iter < 16; iter++) {
                a6.s6_addr[iter] = addrbyte[iter];
            }

            /* now construct the scon_if_t */
            strncpy(intf->if_name, ifname, IF_NAMESIZE);
            intf->if_index = scon_list_get_size(&scon_if_list)+1;
            intf->if_kernel_index = (uint16_t) idx;
            ((struct sockaddr_in6*) &intf->if_addr)->sin6_addr = a6;
            ((struct sockaddr_in6*) &intf->if_addr)->sin6_family = AF_INET6;
            ((struct sockaddr_in6*) &intf->if_addr)->sin6_scope_id = scope;
            intf->if_mask = pfxlen;
            if (SCON_SUCCESS == scon_ifindextoflags(scon_ifnametoindex (ifname), &flag)) {
                intf->if_flags = flag;
            } else {
                intf->if_flags = IFF_UP;
            }

            /* copy new interface information to heap and append
               to list */
            scon_list_append(&scon_if_list, &(intf->super));
            scon_output_verbose(1, scon_if_base_framework.framework_output,
                                "added interface %2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x:%2x%2x\n",
                                addrbyte[0], addrbyte[1], addrbyte[2], addrbyte[3],
                                addrbyte[4], addrbyte[5], addrbyte[6], addrbyte[7],
                                addrbyte[8], addrbyte[9], addrbyte[10], addrbyte[11],
                                addrbyte[12], addrbyte[13], addrbyte[14], addrbyte[15]);
        } /* of while */
        fclose(f);
    }
#endif  /* SCON_ENABLE_IPV6 */

    return SCON_SUCCESS;
}


