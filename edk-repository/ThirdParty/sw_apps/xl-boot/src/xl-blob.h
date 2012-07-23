/*
 * (C) Copyright 2010-2012 Li-Pro.Net
 * Stephan Linz <linz@li-pro.net>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#ifndef _XLB_BLOB_H
#define _XLB_BLOB_H

#ifdef __cplusplus
extern "C" {
#endif

#include <xenv_standalone.h>
#include <xlb_config.h>

/* payload header */
struct plheader
{
	u16	version;	/* version  of  payload  header */
	u16	type;		/* type of payload data */
	u32	user;		/* reserved for user data */
	char	name[32];	/* name string */
	char	date[32];	/* builddate string */
	u32	addr;		/* linked address of data */
	u32	size;		/* size of data */
};

#define XLB_PLH_VERS_100	0x0100
#define XLB_PLH_VERS_100_STR	"V1"

#define XLB_PLH_TYPE_100	0x0100
#define XLB_PLH_TYPE_100_STR	"Standalone"

#define XLB_PLH_TYPE_200	0x0200
#define XLB_PLH_TYPE_200_STR	"Xilkernel"

#define XLB_PLH_TYPE_300	0x0300
#define XLB_PLH_TYPE_300_STR	"eCos"

#define XLB_PLH_TYPE_400	0x0400
#define XLB_PLH_TYPE_400_STR	"FreeRTOS"

#define XLB_PLH_TYPE_500	0x0500
#define XLB_PLH_TYPE_500_STR	"U-Boot"

#define XLB_PLH_TYPE_600	0x0600
#define XLB_PLH_TYPE_600_STR	"Linux"

/* locater blob */
struct locblob
{
	u32	key;		/* magic image key */
	u32	nop;		/* reserved for NOP (for RISC machines) */
	u32	code[22];	/* PIC executable bootstub code */
	struct plheader	header;	/* payload header */
	/* payload data is placed immediately after the header */
};

/*
 * image key is the first fixed assmebly mnemonic of the image locator blob:
 *	brlid r5, locator	--> 0xb8b40008
 */
#define XLB_LOCBLOB_KEY		0xb8b40008

/* locator blob entry */
typedef void (*locblobfp)(void);

extern int locblob_probe(struct locblob * const locblob);

#ifdef __cplusplus
}
#endif

#endif /* _XLB_BLOB_H */
