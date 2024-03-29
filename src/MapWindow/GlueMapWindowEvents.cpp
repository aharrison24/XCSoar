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

#include "GlueMapWindow.hpp"
#include "Message.hpp"
#include "Input/InputEvents.hpp"
#include "Screen/Key.h"
#include "Screen/Layout.hpp"
#include "Simulator.hpp"
#include "Task/ProtectedTaskManager.hpp"
#include "Blackboard/DeviceBlackboard.hpp"
#include "Components.hpp"
#include "Protection.hpp"
#include "Dialogs/Waypoint.hpp"
#include "Dialogs/Task.hpp"
#include "Math/FastMath.h"
#include "Compiler.h"
#include "Interface.hpp"
#include "Screen/Fonts.hpp"

#include <algorithm>

using std::min;
using std::max;

bool
GlueMapWindow::OnMouseDouble(PixelScalar x, PixelScalar y)
{
  map_item_timer.Cancel();

  mouse_down_clock.Update();

  if (IsPanning())
    return true;

  InputEvents::ShowMenu();
  ignore_single_click = true;
  return true;
}

bool
GlueMapWindow::OnMouseMove(PixelScalar x, PixelScalar y, unsigned keys)
{
  /* allow a bigger threshold on touch screens */
  const int threshold = IsEmbedded() ? 50 : 10;
  if (drag_mode != DRAG_NONE && arm_mapitem_list &&
      (abs(drag_start.x - x) + abs(drag_start.y - y)) > Layout::Scale(threshold))
    arm_mapitem_list = false;

  switch (drag_mode) {
  case DRAG_NONE:
    break;

#ifdef HAVE_MULTI_TOUCH
  case DRAG_MULTI_TOUCH_PAN:
#endif
  case DRAG_PAN:
    visible_projection.SetGeoLocation(drag_projection.GetGeoLocation()
                                      + drag_start_geopoint
                                      - drag_projection.ScreenToGeo(x, y));
    QuickRedraw();
    return true;

  case DRAG_GESTURE:
    gestures.Update(x, y);
    Invalidate();
    return true;

  case DRAG_SIMULATOR:
    return true;
  }

  return MapWindow::OnMouseMove(x, y, keys);
}

bool
GlueMapWindow::OnMouseDown(PixelScalar x, PixelScalar y)
{
  map_item_timer.Cancel();

  // Ignore single click event if double click detected
  if (ignore_single_click || drag_mode != DRAG_NONE)
    return true;

  mouse_down_clock.Update();
  arm_mapitem_list = HasFocus();

  SetFocus();

  drag_start.x = x;
  drag_start.y = y;
  drag_start_geopoint = visible_projection.ScreenToGeo(x, y);
  drag_last = drag_start;

  switch (follow_mode) {
  case FOLLOW_SELF:
    break;

  case FOLLOW_PAN:
    drag_mode = DRAG_PAN;
    drag_projection = visible_projection;
    break;
  }

  if (Basic().gps.simulator && drag_mode == DRAG_NONE)
    if (compare_squared(visible_projection.GetScreenOrigin().x - x,
                        visible_projection.GetScreenOrigin().y - y,
                        Layout::Scale(30)) != 1)
        drag_mode = DRAG_SIMULATOR;
  if (drag_mode == DRAG_NONE ) {
    gestures.Start(x, y, Layout::Scale(20));
    drag_mode = DRAG_GESTURE;
  }

  if (drag_mode != DRAG_NONE)
    SetCapture();

  return true;
}

bool
GlueMapWindow::OnMouseUp(PixelScalar x, PixelScalar y)
{
  if (drag_mode != DRAG_NONE)
    ReleaseCapture();

  // Ignore single click event if double click detected
  if (ignore_single_click) {
    ignore_single_click = false;
    return true;
  }

  int click_time = mouse_down_clock.Elapsed();
  mouse_down_clock.Reset();

  DragMode old_drag_mode = drag_mode;
  drag_mode = DRAG_NONE;

  switch (old_drag_mode) {
  case DRAG_NONE:
    break;

#ifdef HAVE_MULTI_TOUCH
  case DRAG_MULTI_TOUCH_PAN:
    follow_mode = FOLLOW_SELF;
    InputEvents::SetPan(true);
    arm_mapitem_list = false;
    break;
#endif

  case DRAG_PAN:
#ifndef ENABLE_OPENGL
    /* allow the use of the stretched last buffer for the next two
       redraws */
    scale_buffer = 2;
#endif
    break;

  case DRAG_SIMULATOR:
    if (click_time > 50 &&
        compare_squared(drag_start.x - x, drag_start.y - y,
                        Layout::Scale(36)) == 1) {
      GeoPoint location = visible_projection.ScreenToGeo(x, y);

      double distance = hypot(drag_start.x - x, drag_start.y - y);

      // This drag moves the aircraft (changes speed and direction)
      const Angle old_bearing = Basic().track;
      const fixed min_speed = fixed(1.1) *
        CommonInterface::GetComputerSettings().polar.glide_polar_task.GetVMin();
      const Angle new_bearing = drag_start_geopoint.Bearing(location);
      if (((new_bearing - old_bearing).AsDelta().AbsoluteDegrees() < fixed(30)) ||
          (Basic().ground_speed < min_speed))
        device_blackboard->SetSpeed(
            min(fixed(100.0), max(min_speed, fixed(distance / (Layout::FastScale(3))))));

      device_blackboard->SetTrack(new_bearing);
      // change bearing without changing speed if direction change > 30
      // 20080815 JMW prevent dragging to stop glider

      return true;
    }

    break;

  case DRAG_GESTURE:
    const TCHAR* gesture = gestures.Finish();
    if (gesture && OnMouseGesture(gesture))
      return true;

    break;
  }

  if (arm_mapitem_list) {
    map_item_timer.Schedule(200);
    return true;
  }

  return false;
}

bool
GlueMapWindow::OnMouseWheel(PixelScalar x, PixelScalar y, int delta)
{
  map_item_timer.Cancel();

  if (drag_mode != DRAG_NONE)
    return true;

  if (delta > 0)
    // zoom in
    InputEvents::sub_ScaleZoom(1);
  else if (delta < 0)
    // zoom out
    InputEvents::sub_ScaleZoom(-1);

  return true;
}

#ifdef HAVE_MULTI_TOUCH

bool
GlueMapWindow::OnMultiTouchDown()
{
  if (drag_mode != DRAG_GESTURE || follow_mode != FOLLOW_SELF)
    return false;

  /* start panning on MultiTouch event */

  drag_mode = DRAG_MULTI_TOUCH_PAN;
  drag_projection = visible_projection;
  follow_mode = FOLLOW_PAN;
  return true;
}

#endif /* HAVE_MULTI_TOUCH */

bool
GlueMapWindow::OnMouseGesture(const TCHAR* gesture)
{
  return InputEvents::processGesture(gesture);
}

bool
GlueMapWindow::OnKeyDown(unsigned key_code)
{
  map_item_timer.Cancel();

  if (InputEvents::processKey(key_code)) {
    return true; // don't go to default handler
  }

  return false;
}

bool
GlueMapWindow::OnCancelMode()
{
  MapWindow::OnCancelMode();

  if (drag_mode != DRAG_NONE) {
#ifdef HAVE_MULTI_TOUCH
    if (drag_mode == DRAG_MULTI_TOUCH_PAN)
      follow_mode = FOLLOW_SELF;
#endif

    ReleaseCapture();
    drag_mode = DRAG_NONE;
  }

  return false;
}

void
GlueMapWindow::OnPaint(Canvas &canvas)
{
#ifdef ENABLE_OPENGL
  ExchangeBlackboard();

  /* update terrain, topography, ... */
  Idle();
#endif

  MapWindow::OnPaint(canvas);

  // Draw center screen cross hair in pan mode
  if (IsPanning())
    DrawCrossHairs(canvas);

  DrawGesture(canvas);
}

void
GlueMapWindow::OnPaintBuffer(Canvas &canvas)
{
  MapWindow::OnPaintBuffer(canvas);

  DrawMapScale(canvas, GetClientRect(), render_projection);
  if (IsPanning())
    DrawPanInfo(canvas);
}

bool
GlueMapWindow::OnTimer(WindowTimer &timer)
{
  if (timer == map_item_timer) {
    map_item_timer.Cancel();
    ShowMapItems(drag_start_geopoint, false);
    return true;
  } else
    return MapWindow::OnTimer(timer);
}

void
GlueMapWindow::Render(Canvas &canvas, const PixelRect &rc)
{
  MapWindow::Render(canvas, rc);

  if (IsNearSelf()) {
    draw_sw.Mark(_T("DrawGlueMisc"));
    if (GetMapSettings().show_thermal_profile)
      DrawThermalBand(canvas, rc);
    DrawStallRatio(canvas, rc);
    DrawFlightMode(canvas, rc);
    DrawFinalGlide(canvas, rc);
    DrawGPSStatus(canvas, rc, Basic());
  }
}
