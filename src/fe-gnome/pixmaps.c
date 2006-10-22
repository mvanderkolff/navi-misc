/*
 * pixmaps.c - helper functions for pixmaps
 *
 * Copyright (C) 2004-2006 xchat-gnome team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

#include <config.h>
#include <glib/gi18n.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include "pixmaps.h"
#include "util.h"

GdkPixbuf *pix_purple;
GdkPixbuf *pix_red;
GdkPixbuf *pix_op;
GdkPixbuf *pix_hop;
GdkPixbuf *pix_voice;

GdkPixbuf *pix_newdata;
GdkPixbuf *pix_nicksaid;
GdkPixbuf *pix_msgsaid;

static GdkPixbuf *
pixbuf_new_from_file (const gchar *file_name)
{
	GdkPixbuf *pixbuf;
	gchar *path;

	path = locate_data_file (file_name);
	pixbuf = gdk_pixbuf_new_from_file (path, NULL);
	g_free (path);

	return pixbuf;
}

void
pixmaps_init (void)
{
	pix_purple   = pixbuf_new_from_file ("purple.png");
	pix_red      = pixbuf_new_from_file ("red.png");
	pix_op       = pixbuf_new_from_file ("op.png");
	pix_hop      = pixbuf_new_from_file ("hop.png");
	pix_voice    = pixbuf_new_from_file ("voice.png");

	pix_newdata  = pixbuf_new_from_file ("newdata.png");
	pix_nicksaid = pixbuf_new_from_file ("nicksaid.png");
	pix_msgsaid  = pixbuf_new_from_file ("global-message.png");
}