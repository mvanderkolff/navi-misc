/*
 * view.c - A generic 3D view with multiple rendering passes
 *
 * BZEdit
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

#include "view.h"

static void view_class_init  (ViewClass *klass);
static void view_init        (View *view);
static void init_lighting    (View *view);
static void reset_lighting   (View *view);
static void default_lighting (View *view);

GType
view_get_type (void)
{
  static GType view_type = 0;
  if (!view_type)
  {
    static const GTypeInfo view_info =
    {
	sizeof (ViewClass),
	NULL,               /* base init */
	NULL,               /* base finalize */
	(GClassInitFunc)    view_class_init,
	NULL,               /* class finalize */
	NULL,               /* class data */
	sizeof (View),
	0,                  /* n preallocs */
	(GInstanceInitFunc) view_init,
    };

    view_type = g_type_register_static (G_TYPE_OBJECT, "View", &view_info, 0);
  }

  return view_type;
}

static void
view_class_init (ViewClass *klass)
{
}

static void
view_init (View *view)
{
  view->lights = NULL;
  view->camera = camera_new ();
}

View*
view_new (Scene *scene)
{
  View *view = VIEW (g_object_new (view_get_type (), NULL));

  if (scene == NULL)
    scene = scene_new ();

  view->scene = scene;
  init_lighting (view);
  return view;
}

void
view_render (View *view)
{
  RenderState *rstate = render_state_new ();
  gint i;

  camera_load (view->camera);
  for (i = 0; i < view->nlights; i++)
    light_set (view->lights[i]);
  scene_render (view->scene, rstate);
}

SceneObject*
view_pick (View *view, guint pos[2])
{
  RenderState *rstate = render_state_new ();
  camera_load (view->camera);
  return scene_pick (view->scene, rstate, pos);
}

static void
init_lighting (View *view)
{
  gint i;

  glGetIntegerv (GL_MAX_LIGHTS, &view->nlights);
  view->lights = g_new (Light*, view->nlights);
  for (i = 0; i < view->nlights; i++)
  {
    view->lights[i] = light_new (GL_LIGHT0 + i);
  }
  default_lighting (view);
}

static void
reset_lighting (View *view)
{
  gint i;
  static float ambient[] = {0.0f, 0.0f, 0.0f, 1.0f};

  for (i = 0; i < view->nlights; i++)
    light_reset (view->lights[i]);
  glLightModelfv (GL_LIGHT_MODEL_AMBIENT, ambient);
}

static void
default_lighting (View *view)
{
  reset_lighting (view);

  view->lights[0]->enabled = TRUE;

  view->lights[0]->ambient[0] = 0.25f;
  view->lights[0]->ambient[1] = 0.25f;
  view->lights[0]->ambient[2] = 0.25f;
  view->lights[0]->ambient[3] = 1.0f;

  view->lights[0]->diffuse[0] = 0.65f;
  view->lights[0]->diffuse[1] = 0.65f;
  view->lights[0]->diffuse[2] = 0.65f;
  view->lights[0]->diffuse[3] = 1.0f;

  view->lights[0]->position[0] = 300.0f;
  view->lights[0]->position[1] = 400.0f;
  view->lights[0]->position[2] = 400.0f;
  view->lights[0]->position[3] = 1.0f;

  view->lights[1]->enabled = TRUE;

  view->lights[1]->ambient[0] = 0.05f;
  view->lights[1]->ambient[1] = 0.05f;
  view->lights[1]->ambient[2] = 0.05f;
  view->lights[1]->ambient[3] = 1.0f;

  view->lights[1]->diffuse[0] = 0.85f;
  view->lights[1]->diffuse[1] = 0.85f;
  view->lights[1]->diffuse[2] = 0.85f;
  view->lights[1]->diffuse[3] = 1.0f;

  view->lights[1]->position[0] = 0.0f;
  view->lights[1]->position[1] = 0.0f;
  view->lights[1]->position[2] = 400.0f;
  view->lights[1]->position[3] = 1.0f;
}
