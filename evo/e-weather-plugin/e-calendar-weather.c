/*
 * 
 *
 * Copyright (C) 2004 David Trowbridge
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

#include <gtk/gtklabel.h>
#include <gtk/gtktable.h>
#include <gtk/gtkscrolledwindow.h>
#include <gtk/gtktreeview.h>
#include <gtk/gtkvbox.h>
#include <e-util/e-config.h>
#include <calendar/ec-config.h>
#include <libedataserver/e-source.h>
#include <libedataserver/e-url.h>
#include <libgnome/gnome-i18n.h>

GtkWidget *
e_calendar_weather_location (EPlugin *epl, EConfigHookItemFactoryData *data)
{
	GtkWidget *label, *swin, *treeview, *vbox, *parent;
	int row;
	ECConfigTargetSource *t = (ECConfigTargetSource *) data->target;
	ESource *source = t->source;
	EUri *uri;
	static GtkWidget *hidden = NULL;

	if (!hidden)
		hidden = gtk_label_new ("");

	uri = e_uri_new (e_source_get_uri (source));
	if (strcmp (uri->protocol, "weather"))
		return hidden;

	if (data->old)
		return data->old;

	parent = data->parent;

	row = ((GtkTable*)parent)->nrows;

	vbox = gtk_vbox_new (FALSE, 6);
	gtk_widget_show (vbox);

	label = gtk_label_new (_("Select a location:"));
	gtk_misc_set_alignment (GTK_MISC (label), 0.0, 0.5);
	gtk_widget_show (label);
	gtk_box_pack_start (GTK_BOX (vbox), label, FALSE, TRUE, 0);

	swin = gtk_scrolled_window_new (NULL, NULL);
	gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW (swin), GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
	gtk_widget_show (swin);
	gtk_box_pack_end (GTK_BOX (vbox), swin, TRUE, TRUE, 0);

	treeview = gtk_tree_view_new ();
	gtk_widget_show (treeview);
	gtk_scrolled_window_add_with_viewport (GTK_SCROLLED_WINDOW (swin), treeview);

	gtk_table_attach (GTK_TABLE (parent), vbox, 0, 2, row, row+1, GTK_EXPAND | GTK_FILL, 0, 0, 0);

	return treeview;
}
