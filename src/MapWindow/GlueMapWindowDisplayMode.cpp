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
#include "Interface.hpp"
#include "Profile/Profile.hpp"
#include "Screen/Layout.hpp"

void
OffsetHistory::Reset()
{
  offsets.fill(RasterPoint{0, 0});
}

void
OffsetHistory::Add(RasterPoint p)
{
  offsets[pos] = p;
  pos = (pos + 1) % offsets.size();
}

RasterPoint
OffsetHistory::GetAverage() const
{
  int x = 0;
  int y = 0;

  for (auto i = offsets.begin(), end = offsets.end(); i != end; ++i) {
    x += i->x;
    y += i->y;
  }

  RasterPoint avg;
  avg.x = x / (int) offsets.size();
  avg.y = y / (int) offsets.size();

  return avg;
}

void
GlueMapWindow::SetPan(bool enable)
{
  switch (follow_mode) {
  case FOLLOW_SELF:
    if (!enable)
      return;

    follow_mode = FOLLOW_PAN;
    break;

  case FOLLOW_PAN:
    if (enable)
      return;

    follow_mode = FOLLOW_SELF;
    break;
  }

  UpdateProjection();
  FullRedraw();
}

void
GlueMapWindow::TogglePan()
{
  switch (follow_mode) {
  case FOLLOW_SELF:
    follow_mode = FOLLOW_PAN;
    break;

  case FOLLOW_PAN:
    follow_mode = FOLLOW_SELF;
    break;
  }

  UpdateProjection();
  FullRedraw();
}

void
GlueMapWindow::PanTo(const GeoPoint &location)
{
  follow_mode = FOLLOW_PAN;
  visible_projection.SetGeoLocation(location);

  UpdateProjection();
  FullRedraw();
}

void
GlueMapWindow::SetMapScale(fixed scale)
{
  MapWindow::SetMapScale(scale);

  MapSettings &settings = CommonInterface::SetMapSettings();

  if (InCirclingMode() && settings.circle_zoom_enabled)
    // save cruise scale
    settings.circling_scale = visible_projection.GetScale();
  else
    settings.cruise_scale = visible_projection.GetScale();

  SaveDisplayModeScales();
}

void
GlueMapWindow::SaveDisplayModeScales()
{
  const MapSettings &settings = CommonInterface::GetMapSettings();

  Profile::Set(szProfileClimbMapScale, (int)(settings.circling_scale * 10000));
  Profile::Set(szProfileCruiseMapScale, (int)(settings.cruise_scale * 10000));
}

void
GlueMapWindow::SwitchZoomClimb()
{
  const MapSettings &settings = CommonInterface::GetMapSettings();

  if (!settings.circle_zoom_enabled)
    return;

  if (InCirclingMode())
    visible_projection.SetScale(settings.circling_scale);
  else
    visible_projection.SetScale(settings.cruise_scale);
}

void
GlueMapWindow::UpdateDisplayMode()
{
  /* not using MapWindowBlackboard here because these methods are
     called by the main thread */
  enum DisplayMode new_mode =
    GetNewDisplayMode(CommonInterface::GetUIState(),
                      CommonInterface::Calculated());

  bool was_circling = (display_mode == DM_CIRCLING);
  bool is_circling = (new_mode == DM_CIRCLING);

  if (!was_circling && is_circling)
    offset_history.Reset();

  display_mode = new_mode;

  if (is_circling != was_circling)
    SwitchZoomClimb();
}

void
GlueMapWindow::UpdateScreenAngle()
{
  /* not using MapWindowBlackboard here because these methods are
     called by the main thread */
  const NMEAInfo &basic = CommonInterface::Basic();
  const DerivedInfo &calculated = CommonInterface::Calculated();
  const MapSettings &settings = CommonInterface::GetMapSettings();

  DisplayOrientation orientation =
      InCirclingMode() ?
          settings.circling_orientation : settings.cruise_orientation;

  if (orientation == TARGETUP &&
      calculated.task_stats.current_leg.vector_remaining.IsValid())
    visible_projection.SetScreenAngle(calculated.task_stats.current_leg.
                                      vector_remaining.bearing);
  else if (orientation == NORTHUP || !basic.track_available)
    visible_projection.SetScreenAngle(Angle::Zero());
  else
    // normal, glider forward
    visible_projection.SetScreenAngle(basic.track);

  compass_visible = orientation != NORTHUP;
}

void
GlueMapWindow::UpdateMapScale()
{
  /* not using MapWindowBlackboard here because these methods are
     called by the main thread */
  const DerivedInfo &calculated = CommonInterface::Calculated();
  const MapSettings &settings = CommonInterface::GetMapSettings();

  if (InCirclingMode() && settings.circle_zoom_enabled)
    return;

  if (!IsNearSelf())
    return;

  fixed distance = calculated.auto_zoom_distance;
  if (settings.auto_zoom_enabled && positive(distance)) {
    // Calculate distance percentage between plane symbol and map edge
    // 50: centered  100: at edge of map
    int auto_zoom_factor = InCirclingMode() ?
                           50 : 100 - settings.glider_screen_position;
    // Leave 5% of full distance for target display
    auto_zoom_factor -= 5;
    // Adjust to account for map scale units
    auto_zoom_factor *= 8;

    distance /= fixed(auto_zoom_factor) / 100;

    // Clip map auto zoom range to reasonable values
    distance = max(fixed_int_constant(525),
                   min(settings.max_auto_zoom_distance / 10, distance));

    visible_projection.SetFreeMapScale(distance);
  }
}

void
GlueMapWindow::SetLocationLazy(const GeoPoint location)
{
  const fixed distance_meters =
    visible_projection.GetGeoLocation().Distance(location);
  const fixed distance_pixels =
    visible_projection.DistanceMetersToPixels(distance_meters);
  if (distance_pixels > fixed_half)
    SetLocation(location);
}

void
GlueMapWindow::UpdateProjection()
{
  const PixelRect rc = GetClientRect();

  /* not using MapWindowBlackboard here because these methods are
     called by the main thread */
  const NMEAInfo &basic = CommonInterface::Basic();
  const DerivedInfo &calculated = CommonInterface::Calculated();
  const MapSettings &settings_map = CommonInterface::GetMapSettings();

  RasterPoint center;
  center.x = (rc.left + rc.right) / 2;
  center.y = (rc.top + rc.bottom) / 2;

  if (InCirclingMode() || !IsNearSelf())
    visible_projection.SetScreenOrigin(center.x, center.y);
  else if (settings_map.cruise_orientation == NORTHUP) {
    RasterPoint offset{0, 0};
    if (settings_map.glider_screen_position != 50 &&
        settings_map.map_shift_bias != MAP_SHIFT_BIAS_NONE) {
      fixed x = fixed_zero;
      fixed y = fixed_zero;
      if (settings_map.map_shift_bias == MAP_SHIFT_BIAS_TRACK) {
        if (basic.track_available &&
            basic.ground_speed_available &&
             /* 8 m/s ~ 30 km/h */
            basic.ground_speed > fixed_int_constant(8)) {
          const auto sc = basic.track.Reciprocal().SinCos();
          x = sc.first;
          y = sc.second;
        }
      } else if (settings_map.map_shift_bias == MAP_SHIFT_BIAS_TARGET) {
        if (calculated.task_stats.current_leg.solution_remaining.IsDefined()) {
          const auto sc =calculated.task_stats.current_leg.solution_remaining
            .vector.bearing.Reciprocal().SinCos();
          x = sc.first;
          y = sc.second;
        }
      }
      fixed position_factor = fixed(50 - settings_map.glider_screen_position) / 100;
      offset.x = PixelScalar(x * (rc.right - rc.left) * position_factor);
      offset.y = PixelScalar(y * (rc.top - rc.bottom) * position_factor);
      offset_history.Add(offset);
      offset = offset_history.GetAverage();
    }
    visible_projection.SetScreenOrigin(center.x + offset.x, center.y + offset.y);
  } else
    visible_projection.SetScreenOrigin(center.x,
        ((rc.top - rc.bottom) * settings_map.glider_screen_position / 100) + rc.bottom);

  if (!IsNearSelf()) {
    /* no-op - the Projection's location is updated manually */
  } else if (InCirclingMode() && calculated.thermal_locator.estimate_valid) {
    const fixed d_t = calculated.thermal_locator.estimate_location.Distance(basic.location);
    if (!positive(d_t)) {
      SetLocationLazy(basic.location);
    } else {
      const fixed d_max = Double(visible_projection.GetMapScale());
      const fixed t = std::min(d_t, d_max)/d_t;
      SetLocation(basic.location.Interpolate(calculated.thermal_locator.estimate_location,
                                               t));
    }
  } else if (basic.location_available)
    // Pan is off
    SetLocationLazy(basic.location);

  visible_projection.UpdateScreenBounds();
}
