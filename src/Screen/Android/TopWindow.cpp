/*
Copyright_License {

  XCSoar Glide Computer - http://www.xcsoar.org/
  Copyright (C) 2000-2012 The XCSoar Project
  A detailed list of copyright holders can be found in the file "AUTHORS".

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}
*/

#include "Screen/TopWindow.hpp"
#include "Screen/OpenGL/Cache.hpp"
#include "Screen/OpenGL/Surface.hpp"
#include "Screen/OpenGL/Shapes.hpp"
#include "Screen/Android/Event.hpp"
#include "Android/Main.hpp"
#include "Android/NativeView.hpp"
#include "PeriodClock.hpp"

void
TopWindow::AnnounceResize(UPixelScalar width, UPixelScalar height)
{
  ScopeLock protect(paused_mutex);
  resized = true;
  new_width = width;
  new_height = height;
}

bool
TopWindow::ResumeSurface()
{
  /* Try to reinitialize OpenGL.  This often fails on the first
     attempt (IllegalArgumentException "Make sure the SurfaceView or
     associated SurfaceHolder has a valid Surface"), therefore we're
     trying again until we're successful. */

  assert(paused);

  if (!native_view->initSurface())
    /* failed - retry later */
    return false;

  paused = false;
  resumed = false;

  screen.Resume();

  ::SurfaceCreated();

  RefreshSize();

  return true;
}

bool
TopWindow::CheckResumeSurface()
{
  return (!resumed || ResumeSurface()) && !paused && surface_valid;
}

void
TopWindow::RefreshSize()
{
  UPixelScalar width, height;

  {
    ScopeLock protect(paused_mutex);
    if (!resized)
      return;

    resized = false;
    width = new_width;
    height = new_height;
  }

  Resize(width, height);
}

void
TopWindow::OnResize(UPixelScalar width, UPixelScalar height)
{
  if (native_view != NULL) {
    native_view->SetSize(width, height);
    screen.OnResize(width, height);
  }

  ContainerWindow::OnResize(width, height);
}

void
TopWindow::on_pause()
{
  if (paused)
    return;

  TextCache::Flush();
  OpenGL::DeinitShapes();

  SurfaceDestroyed();

  native_view->deinitSurface();

  paused_mutex.Lock();
  paused = true;
  resumed = false;
  paused_cond.Signal();
  paused_mutex.Unlock();
}

void
TopWindow::on_resume()
{
  if (!paused)
    return;

  /* tell TopWindow::Expose() to reinitialize OpenGL */
  resumed = true;

  /* schedule a redraw */
  Invalidate();
}

static bool
match_pause_and_resume(const Event &event, void *ctx)
{
  return event.type == Event::PAUSE || event.type == Event::RESUME;
}

void
TopWindow::pause()
{
  event_queue->Purge(match_pause_and_resume, NULL);
  event_queue->Push(Event::PAUSE);

  paused_mutex.Lock();
  while (!paused)
    paused_cond.Wait(paused_mutex);
  paused_mutex.Unlock();
}

void
TopWindow::resume()
{
  event_queue->Purge(match_pause_and_resume, NULL);
  event_queue->Push(Event::RESUME);
}

bool
TopWindow::OnEvent(const Event &event)
{
  switch (event.type) {
    Window *w;

  case Event::NOP:
  case Event::QUIT:
  case Event::TIMER:
  case Event::USER:
  case Event::NOTIFY:
  case Event::CALLBACK:
    break;

  case Event::KEY_DOWN:
    w = GetFocusedWindow();
    if (w == NULL)
      w = this;

    return w->OnKeyDown(event.param);

  case Event::KEY_UP:
    w = GetFocusedWindow();
    if (w == NULL)
      w = this;

    return w->OnKeyUp(event.param);

  case Event::MOUSE_MOTION:
    // XXX keys
    return OnMouseMove(event.x, event.y, 0);

  case Event::MOUSE_DOWN:
    static PeriodClock double_click;
    return double_click.CheckAlwaysUpdate(300)
      ? OnMouseDown(event.x, event.y)
      : OnMouseDouble(event.x, event.y);

  case Event::MOUSE_UP:
    return OnMouseUp(event.x, event.y);

  case Event::POINTER_DOWN:
    return OnMultiTouchDown();

  case Event::POINTER_UP:
    return OnMultiTouchUp();

  case Event::RESIZE:
    if (!surface_valid)
      /* postpone the resize if we're paused; the real resize will be
         handled by TopWindow::refresh() as soon as XCSoar is
         resumed */
      return true;

    if ((unsigned)event.x == GetWidth() && (unsigned)event.y == GetHeight())
      /* no-op */
      return true;

    /* it seems the first page flip after a display orientation change
       is ignored on Android (tested on a Dell Streak / Android
       2.2.2); let's do one dummy call before we really draw
       something */
    screen.Flip();

    Resize(event.x, event.y);
    return true;

  case Event::PAUSE:
    on_pause();
    return true;

  case Event::RESUME:
    on_resume();
    return true;
  }

  return false;
}

int
TopWindow::event_loop()
{
  refresh();

  EventLoop loop(*event_queue, *this);
  Event event;
  while (IsDefined() && loop.Get(event))
    loop.Dispatch(event);

  return 0;
}

void
TopWindow::post_quit()
{
  event_queue->Push(Event::QUIT);
}
