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

#ifndef XCSOAR_NMEA_DERIVED_H
#define XCSOAR_NMEA_DERIVED_H

#include "Math/fixed.hpp"
#include "Navigation/GeoPoint.hpp"
#include "Navigation/SpeedVector.hpp"
#include "Task/TaskStats/TaskStats.hpp"
#include "Task/TaskStats/CommonStats.hpp"
#include "Contest/ContestStatistics.hpp"
#include "FlyingState.hpp"
#include "NMEA/VarioInfo.hpp"
#include "NMEA/ClimbInfo.hpp"
#include "NMEA/CirclingInfo.hpp"
#include "NMEA/ThermalBand.hpp"
#include "NMEA/ThermalLocator.hpp"
#include "NMEA/Validity.hpp"
#include "NMEA/ClimbHistory.hpp"
#include "TeamCode.hpp"
#include "Engine/Navigation/TraceHistory.hpp"
#include "DateTime.hpp"
#include "Engine/GlideSolvers/GlidePolar.hpp"
#include "Atmosphere/Pressure.hpp"
#include "Engine/Route/Route.hpp"
#include "Util/TypeTraits.hpp"

/** Derived terrain altitude information, including glide range */
struct TerrainInfo
{
  /** True if terrain is valid, False otherwise */
  bool terrain_valid;

  /** Does the attribute #TerrainBase have a valid value? */
  bool terrain_base_valid;

  /** Does the attribute #AltitudeAGL have a valid value? */
  bool altitude_agl_valid;

  bool terrain_warning;

  /** Terrain altitude */
  fixed terrain_altitude;

  /** Lowest height within glide range */
  fixed terrain_base;

  /** Altitude over terrain */
  fixed altitude_agl;

  GeoPoint terrain_warning_location;

  void Clear();

  /**
   * Returns the terrain base, and falls back for terrain altitude if
   * the base is not known.
   */
  fixed GetTerrainBaseFallback() const {
    return terrain_base_valid
      ? terrain_base
      : terrain_altitude;
  }
};

static_assert(is_trivial<TerrainInfo>::value, "type is not trivial");

/** Derived team code information */
struct TeamInfo
{
  /** Are #teammate_vector and #TeammateLocation available? */
  bool teammate_available;

  /** Is #flarm_teammate_code available? */
  bool flarm_teammate_code_available;

  /** is #flarm_teammate_code current or did we lose him? */
  bool flarm_teammate_code_current;

  /** Team code */
  TeamCode own_teammate_code;

  /** Vector to the chosen team mate */
  GeoVector teammate_vector;

  /** Position of the chosen team mate */
  GeoPoint teammate_location;

  /** The team code of the FLARM teammate. */
  TeamCode flarm_teammate_code;

  void Clear();
};

static_assert(is_trivial<TeamInfo>::value, "type is not trivial");

struct AirspaceWarningsInfo {
  /**
   * The time stamp of the most recent airspace warning.  Check if
   * this value gets increased to see if there's a new warning.
   */
  Validity latest;

  void Clear();
};

static_assert(is_trivial<AirspaceWarningsInfo>::value, "type is not trivial");

/**
 * A struct that holds all the calculated values derived from the data in the
 * NMEA_INFO struct
 */
struct DerivedInfo: 
  public VarioInfo,
  public ClimbInfo,
  public CirclingInfo,
  public TerrainInfo,
  public TeamInfo
{
  /** GPS date and time (local) */
  BrokenDateTime date_time_local;

  /** Speed to fly block/dolphin (m/s) */
  fixed V_stf;

  /** Bearing including wind factor */
  Angle heading;

  /** Auto QNH calculation result. */
  AtmosphericPressure pressure;
  Validity pressure_available;

  ClimbHistory climb_history;

  /** Does #estimated_wind have a meaningful value? */
  Validity estimated_wind_available;

  /** Wind speed, direction */
  SpeedVector estimated_wind;

  /** Is the wind available? */
  Validity wind_available;

  /**
   * The effective wind vector; depending on the settings, this is
   * either ExternalWind, calculated wind or manual wind.
   */
  SpeedVector wind;

  Validity head_wind_available;
  fixed head_wind;

  /** Distance to zoom to for autozoom */
  fixed auto_zoom_distance;

  Validity sun_data_available;
  /** Sun's azimuth at the current location and time */
  Angle sun_azimuth;

  /** Copy of task statistics data for active task */
  TaskStats task_stats;
  /** Copy of common task statistics data */
  CommonStats common_stats;
  /** Copy of contest statistics data */
  ContestStatistics contest_stats;

  FlyingState flight;

  ThermalBandInfo thermal_band;

  ThermalLocatorInfo thermal_locator;

  /** Store of short term history of variables */
  TraceHistory trace_history;

  Validity auto_mac_cready_available;
  fixed auto_mac_cready;

  /** Glide polar used for safety calculations */
  GlidePolar glide_polar_safety;

  AirspaceWarningsInfo airspace_warnings;

  /** Route plan for current leg avoiding airspace */
  StaticRoute planned_route;

  /**
   * @todo Reset to cleared state
   */
  void Reset();

  void Expire(fixed Time);

  /**
   * Return the current wind vector, or the null vector if no wind is
   * available.
   */
  gcc_pure
  SpeedVector GetWindOrZero() const {
    return wind_available
      ? wind
      : SpeedVector::Zero();
  }

  void ProvideAutoMacCready(fixed clock, fixed mc) {
    if (auto_mac_cready_available &&
        fabs(auto_mac_cready - mc) < fixed(0.05))
      /* change is too small, ignore the new value to limit the rate */
      return;

    auto_mac_cready = mc;
    auto_mac_cready_available.Update(clock);
  }
};

static_assert(is_trivial_ndebug<DerivedInfo>::value, "type is not trivial");

#endif

