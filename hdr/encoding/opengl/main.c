/*
 * main.c - SDL frontend for the HDR encoding test
 *
 * Copyright (C) 2004 Micah Dowty <micah@navi.cx>
 *
 */

#include "hdr_test.h"

SDL_Surface *screen;
GLhandleARB program;

void scene_init() {
  float diffuse[] = {0.5, 0.5, 0.52, 0};
  float specular[] = {1.0, 1.0, 0.8, 0};
  float position[] = {1, 1, -1, 1};
  float m_ambient[]  = {0, 0, 0, 0};
  float m_diffuse[]  = {1, 1, 1, 0};
  float m_specular[] = {0.8, 0.8, 0.8, 0};

  program = shader_link_program(shader_compile_from_files(GL_VERTEX_SHADER_ARB,
							  DATADIR "/test.vert",
							  NULL),
				shader_compile_from_files(GL_FRAGMENT_SHADER_ARB,
							  DATADIR "/test.frag",
							  NULL),
				0);

  glViewport(0, 0, screen->w, screen->h);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(30.0, ((float)screen->w) / screen->h, 0.1, 100.0);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  glClearDepth(1);
  glDepthFunc(GL_LESS);
  glShadeModel(GL_SMOOTH);
  glFrontFace(GL_CCW);
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_CULL_FACE);
  glClearColor(0, 0, 0, 1);

  glEnable(GL_LIGHTING);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, diffuse);
  glLightfv(GL_LIGHT0, GL_SPECULAR, specular);
  glLightfv(GL_LIGHT0, GL_POSITION, position);
  glEnable(GL_LIGHT0);

  glMaterialfv(GL_FRONT, GL_AMBIENT, m_ambient);
  glMaterialfv(GL_FRONT, GL_DIFFUSE, m_diffuse);
  glMaterialfv(GL_FRONT, GL_SPECULAR, m_specular);
  glMaterialf(GL_FRONT, GL_SHININESS, 30);
}

void scene_draw(float dt) {
  static float angle = 0;

  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  glLoadIdentity();
  glTranslatef(0, 0, -9);

  angle += 40 * dt;
  glRotatef(angle, 0, 1, 0);

  glRotatef(-90, 1, 0, 0);
  model_draw();

  SDL_GL_SwapBuffers();
}

void fps_report(Uint32 now) {
  /* Measure and report the number of frames per second. Called every frame. */
  static Uint32 start_time = 0;
  const Uint32 interval = 1000;
  static int n_frames = 0;
  float fps;

  n_frames++;
  if (now > start_time + interval) {
    fps = n_frames * 1000.0 / (now - start_time);
    printf("\r%8.02f FPS ", fps);
    fflush(stdout);

    n_frames = 0;
    start_time = now;
  }
}

int main() {
  int done = 0;
  SDL_Event event;
  Uint32 now = 0, then = 0;

  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    printf("Error initializing SDL: %s\n", SDL_GetError());
    return 1;
  }

  screen = SDL_SetVideoMode(640, 480, 0, SDL_OPENGL);
  if (!screen) {
    printf("Error setting video mode: %s\n", SDL_GetError());
    SDL_Quit();
    return 1;
  }

  SDL_WM_SetCaption("Hardware HDR encoding test", "hdrtest");

  scene_init();

  while (!done) {
    while (SDL_PollEvent(&event)) {
      switch (event.type) {

      case SDL_QUIT:
	done = 1;
	break;

      case SDL_KEYDOWN:
	if (event.key.keysym.sym == SDLK_SPACE)
	  model_switch();
	break;

      }
    }

    then = now;
    now = SDL_GetTicks();
    scene_draw((now - then) / 1000.0);
    fps_report(now);
  }

  SDL_Quit();
  return 0;
}

/* The End */
