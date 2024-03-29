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

#include "Dialogs/dlgAnalysis.hpp"
#include "Dialogs/CallBackTable.hpp"
#include "Dialogs/Dialogs.h"
#include "Dialogs/Internal.hpp"
#include "Dialogs/AirspaceWarningDialog.hpp"
#include "Dialogs/Task.hpp"
#include "CrossSection/CrossSectionWindow.hpp"
#include "Task/ProtectedTaskManager.hpp"
#include "ComputerSettings.hpp"
#include "Math/FastMath.h"
#include "Math/Earth.hpp"
#include "Screen/Layout.hpp"
#include "Screen/Key.h"
#include "Look/Look.hpp"
#include "Computer/GlideComputer.hpp"
#include "Protection.hpp"
#include "Util/StringUtil.hpp"
#include "Compiler.h"
#include "Formatter/Units.hpp"
#include "Renderer/FlightStatisticsRenderer.hpp"
#include "Renderer/GlidePolarRenderer.hpp"
#include "Renderer/BarographRenderer.hpp"
#include "Renderer/ClimbChartRenderer.hpp"
#include "Renderer/ThermalBandRenderer.hpp"
#include "Renderer/WindChartRenderer.hpp"
#include "Renderer/CuRenderer.hpp"
#include "GestureManager.hpp"

#ifdef ENABLE_OPENGL
#include "Screen/OpenGL/Scissor.hpp"
#endif

#include <stdio.h>

enum class AnalysisPage: uint8_t {
  BAROGRAPH,
  CLIMB,
  THERMAL_BAND,
  TASK_SPEED,
  WIND,
  POLAR,
  TEMPTRACE,
  TASK,
  OLC,
  AIRSPACE,
  COUNT
};

class ChartControl;

static const Look *look;
static const FullBlackboard *blackboard;
static GlideComputer *glide_computer;
static const ProtectedTaskManager *protected_task_manager;
static const Airspaces *airspaces;
static const RasterTerrain *terrain;

static AnalysisPage page = AnalysisPage::BAROGRAPH;
static WndForm *wf = NULL;
static ChartControl *wGrid = NULL;
static WndFrame *wInfo;
static WndButton *wCalc = NULL;
static CrossSectionWindow *csw = NULL;
static GestureManager gestures;

class CrossSectionControl: public CrossSectionWindow
{
public:
  CrossSectionControl(const CrossSectionLook &look,
                      const AirspaceLook &airspace_look,
                      const ChartLook &chart_look)
    :CrossSectionWindow(look, airspace_look, chart_look) {}

protected:
  virtual bool OnMouseMove(PixelScalar x, PixelScalar y, unsigned keys);
  virtual bool OnMouseDown(PixelScalar x, PixelScalar y);
  virtual bool OnMouseUp(PixelScalar x, PixelScalar y);
};

class ChartControl: public PaintWindow
{
  const ChartLook &chart_look;
  const AirspaceLook &airspace_look;
  const AircraftLook &aircraft_look;
  const TaskLook &task_look;
  const ThermalBandLook &thermal_band_look;

public:
  ChartControl(ContainerWindow &parent,
               PixelScalar x, PixelScalar y,
               UPixelScalar Width, UPixelScalar Height,
               const WindowStyle style,
               const ChartLook &chart_look,
               const AirspaceLook &airspace_look,
               const AircraftLook &aircraft_look,
               const TaskLook &task_look,
               const ThermalBandLook &thermal_band_look);

protected:
  virtual bool OnMouseMove(PixelScalar x, PixelScalar y, unsigned keys);
  virtual bool OnMouseDown(PixelScalar x, PixelScalar y);
  virtual bool OnMouseUp(PixelScalar x, PixelScalar y);

  virtual void OnPaint(Canvas &canvas);
};

ChartControl::ChartControl(ContainerWindow &parent,
                           PixelScalar X, PixelScalar Y,
                           UPixelScalar Width, UPixelScalar Height,
                           const WindowStyle style,
                           const ChartLook &_chart_look,
                           const AirspaceLook &_airspace_look,
                           const AircraftLook &_aircraft_look,
                           const TaskLook &_task_look,
                           const ThermalBandLook &_thermal_band_look)
  :chart_look(_chart_look), airspace_look(_airspace_look),
   aircraft_look(_aircraft_look),
   task_look(_task_look),
   thermal_band_look(_thermal_band_look)
{
  set(parent, X, Y, Width, Height, style);
}

static void
SetCalcVisibility(const bool visible)
{
  assert(wCalc != NULL);
  wCalc->SetVisible(visible);
}

static void
SetCalcCaption(const TCHAR* caption)
{
  assert(wCalc != NULL);
  wCalc->SetCaption(caption);
  SetCalcVisibility(!StringIsEmpty(caption));
}

void
ChartControl::OnPaint(Canvas &canvas)
{
  assert(glide_computer != NULL);

  const ComputerSettings &settings_computer = blackboard->GetComputerSettings();
  const MapSettings &settings_map = blackboard->GetMapSettings();
  const MoreData &basic = blackboard->Basic();
  const DerivedInfo &calculated = blackboard->Calculated();

#ifdef ENABLE_OPENGL
  /* enable clipping */
  GLCanvasScissor scissor(canvas);
#endif

  canvas.Clear(COLOR_WHITE);
  canvas.SetTextColor(COLOR_BLACK);

  PixelRect rcgfx = GetClientRect();

  // background is painted in the base-class

  switch (page) {
  case AnalysisPage::BAROGRAPH:
    RenderBarograph(canvas, rcgfx, chart_look, look->cross_section,
                    glide_computer->GetFlightStats(),
                    basic, calculated, protected_task_manager);
    break;
  case AnalysisPage::CLIMB:
    RenderClimbChart(canvas, rcgfx, chart_look,
                     glide_computer->GetFlightStats(),
                     settings_computer.polar.glide_polar_task);
    break;
  case AnalysisPage::THERMAL_BAND:
  {
    OrderedTaskBehaviour otb;
    if (protected_task_manager != NULL) {
      otb = protected_task_manager->GetOrderedTaskBehaviour();
    }

    ThermalBandRenderer renderer(thermal_band_look, chart_look);
    renderer.DrawThermalBand(basic,
                             calculated,
                             settings_computer,
                             canvas, rcgfx,
                             settings_computer.task,
                             false,
                             &otb);
  }
    break;
  case AnalysisPage::WIND:
    RenderWindChart(canvas, rcgfx, chart_look,
                    glide_computer->GetFlightStats(),
                    basic, glide_computer->GetWindStore());
    break;
  case AnalysisPage::POLAR:
    RenderGlidePolar(canvas, rcgfx, look->chart,
                     calculated.climb_history,
                     settings_computer,
                     settings_computer.polar.glide_polar_task);
    break;
  case AnalysisPage::TEMPTRACE:
    RenderTemperatureChart(canvas, rcgfx, chart_look,
                           glide_computer->GetCuSonde());
    break;
  case AnalysisPage::TASK:
    if (protected_task_manager != NULL) {
      const TraceComputer *trace_computer = glide_computer != NULL
        ? &glide_computer->GetTraceComputer()
        : NULL;
      const FlightStatisticsRenderer fs(glide_computer->GetFlightStats(),
                                        chart_look, look->map);
      fs.RenderTask(canvas, rcgfx, basic, calculated,
                    settings_computer, settings_map,
                    *protected_task_manager,
                    trace_computer);
    }
    break;
  case AnalysisPage::OLC:
    if (glide_computer != NULL) {
      const FlightStatisticsRenderer fs(glide_computer->GetFlightStats(),
                                        chart_look, look->map);
      fs.RenderOLC(canvas, rcgfx, basic, calculated,
                   settings_computer, settings_map,
                   calculated.contest_stats,
                   glide_computer->GetTraceComputer());
    }
    break;
  case AnalysisPage::TASK_SPEED:
    if (protected_task_manager != NULL) {
      ProtectedTaskManager::Lease task(*protected_task_manager);
      RenderSpeed(canvas, rcgfx, chart_look,
                  glide_computer->GetFlightStats(),
                  basic, calculated, task);
    }
    break;
  default:
    // should never get here!
    break;
  }
}

static void
UpdateCrossSection()
{
  const MoreData &basic = blackboard->Basic();
  const DerivedInfo &calculated = blackboard->Calculated();

  assert(csw != NULL);
  csw->ReadBlackboard(basic, calculated, blackboard->GetMapSettings().airspace);

  if (basic.location_available && basic.track_available) {
    csw->SetDirection(basic.track);
    csw->SetStart(basic.location);
  } else
    csw->SetInvalid();
}

static void
Update()
{
  TCHAR sTmp[1000];

  assert(wf != NULL);
  assert(wInfo != NULL);
  assert(wGrid != NULL);
  assert(csw != NULL);
  assert(glide_computer != NULL);

  const ComputerSettings &settings_computer = blackboard->GetComputerSettings();
  const DerivedInfo &calculated = blackboard->Calculated();

  switch (page) {
  case AnalysisPage::BAROGRAPH:
    _stprintf(sTmp, _T("%s: %s"), _("Analysis"),
              _("Barograph"));
    wf->SetCaption(sTmp);
    BarographCaption(sTmp, glide_computer->GetFlightStats());
    wInfo->SetCaption(sTmp);
    SetCalcCaption(_("Settings"));
    break;

  case AnalysisPage::CLIMB:
    _stprintf(sTmp, _T("%s: %s"), _("Analysis"),
              _("Climb"));
    wf->SetCaption(sTmp);
    ClimbChartCaption(sTmp, glide_computer->GetFlightStats());
    wInfo->SetCaption(sTmp);
    SetCalcCaption(_("Task Calc"));
    break;

  case AnalysisPage::THERMAL_BAND:
    _stprintf(sTmp, _T("%s: %s"), _("Analysis"),
              _("Thermal Band"));
    wf->SetCaption(sTmp);
    ClimbChartCaption(sTmp, glide_computer->GetFlightStats());
    wInfo->SetCaption(sTmp);
    SetCalcCaption(_T(""));
    break;

  case AnalysisPage::WIND:
    _stprintf(sTmp, _T("%s: %s"), _("Analysis"),
              _("Wind At Altitude"));
    wf->SetCaption(sTmp);
    wInfo->SetCaption(_T(""));
    SetCalcCaption(_("Set Wind"));
    break;

  case AnalysisPage::POLAR:
    _stprintf(sTmp, _T("%s: %s (%s %d kg)"), _("Analysis"),
              _("Glide Polar"), _("Mass"),
              (int)settings_computer.polar.glide_polar_task.GetTotalMass());
    wf->SetCaption(sTmp);
    GlidePolarCaption(sTmp, settings_computer.polar.glide_polar_task);
    wInfo->SetCaption(sTmp);
    SetCalcCaption(_("Settings"));
   break;

  case AnalysisPage::TEMPTRACE:
    _stprintf(sTmp, _T("%s: %s"), _("Analysis"),
              _("Temp Trace"));
    wf->SetCaption(sTmp);
    TemperatureChartCaption(sTmp, glide_computer->GetCuSonde());
    wInfo->SetCaption(sTmp);
    SetCalcCaption(_("Settings"));
    break;

  case AnalysisPage::TASK_SPEED:
    _stprintf(sTmp, _T("%s: %s"), _("Analysis"),
              _("Task Speed"));
    wf->SetCaption(sTmp);
    wInfo->SetCaption(_T(""));
    SetCalcCaption(_("Task Calc"));
    break;

  case AnalysisPage::TASK:
    _stprintf(sTmp, _T("%s: %s"), _("Analysis"),
              _("Task"));
    wf->SetCaption(sTmp);
    FlightStatisticsRenderer::CaptionTask(sTmp, calculated);
    wInfo->SetCaption(sTmp);
    SetCalcCaption(_("Task calc"));
    break;

  case AnalysisPage::OLC:
    _stprintf(sTmp, _T("%s: %s"), _("Analysis"),
              ContestToString(settings_computer.task.contest));
    wf->SetCaption(sTmp);
    SetCalcCaption(_T(""));
    FlightStatisticsRenderer::CaptionOLC(sTmp, settings_computer.task, calculated);
    wInfo->SetCaption(sTmp);
    break;

  case AnalysisPage::AIRSPACE:
    _stprintf(sTmp, _T("%s: %s"), _("Analysis"),
              _("Airspace"));
    wf->SetCaption(sTmp);
    wInfo->SetCaption(_T(""));
    SetCalcCaption(_("Warnings"));
    break;

  case AnalysisPage::COUNT:
    assert(false);
    break;
  }

  switch (page) {
  case AnalysisPage::AIRSPACE:
    UpdateCrossSection();
    csw->Invalidate();
    csw->Show();
    wGrid->Hide();
    break;

  default:
    csw->Hide();
    wGrid->Show();
    wGrid->Invalidate();
    break;
  }
}

static void
NextPage(int Step)
{
  int new_page = (int)page + Step;

  if (new_page >= (int)AnalysisPage::COUNT)
    new_page = 0;
  if (new_page < 0)
    new_page = (int)AnalysisPage::COUNT - 1;
  page = (AnalysisPage)new_page;

  Update();
}

static void
OnGesture(const TCHAR* gesture)
{
  if (_tcscmp(gesture, _T("L")) == 0)
    NextPage(-1);
  else if (_tcscmp(gesture, _T("R")) == 0)
    NextPage(+1);
}

bool
ChartControl::OnMouseDown(PixelScalar x, PixelScalar y)
{
  gestures.Start(x, y, Layout::Scale(20));
  return true;
}

bool
ChartControl::OnMouseMove(PixelScalar x, PixelScalar y, unsigned keys)
{
  gestures.Update(x, y);
  return true;
}

bool
ChartControl::OnMouseUp(PixelScalar x, PixelScalar y)
{
  const TCHAR* gesture = gestures.Finish();
  if (gesture != NULL)
    OnGesture(gesture);

  return true;
}

bool
CrossSectionControl::OnMouseDown(PixelScalar x, PixelScalar y)
{
  gestures.Start(x, y, Layout::Scale(20));
  return true;
}

bool
CrossSectionControl::OnMouseMove(PixelScalar x, PixelScalar y, unsigned keys)
{
  gestures.Update(x, y);
  return true;
}

bool
CrossSectionControl::OnMouseUp(PixelScalar x, PixelScalar y)
{
  const TCHAR* gesture = gestures.Finish();
  if (gesture != NULL)
    OnGesture(gesture);

  return true;
}

static void
OnNextClicked(gcc_unused WndButton &Sender)
{
  NextPage(+1);
}

static void
OnPrevClicked(gcc_unused WndButton &Sender)
{
  NextPage(-1);
}

static void
OnCloseClicked(gcc_unused WndButton &button)
{
  wf->SetModalResult(mrOK);
}

static bool
FormKeyDown(gcc_unused WndForm &Sender, unsigned key_code)
{
  assert(wf != NULL);

  switch (key_code) {
  case VK_LEFT:
#ifdef GNAV
  case '6':
#endif
    ((WndButton *)wf->FindByName(_T("cmdPrev")))->SetFocus();
    NextPage(-1);
    return true;

  case VK_RIGHT:
#ifdef GNAV
  case '7':
#endif
    ((WndButton *)wf->FindByName(_T("cmdNext")))->SetFocus();
    NextPage(+1);
    return true;

  default:
    return false;
  }
}

static void
OnCalcClicked(gcc_unused WndButton &Sender)
{
  assert(wf != NULL);

  if (page == AnalysisPage::BAROGRAPH)
    dlgBasicSettingsShowModal();

  if (page == AnalysisPage::CLIMB) {
    wf->Hide();
    dlgTaskManagerShowModal(*(SingleWindow *)wf->GetRootOwner());
    wf->Show();
  }

  if (page == AnalysisPage::WIND)
    dlgWindSettingsShowModal();

  if (page == AnalysisPage::POLAR)
    dlgBasicSettingsShowModal();

  if (page == AnalysisPage::TEMPTRACE)
    dlgBasicSettingsShowModal();

  if ((page == AnalysisPage::TASK) || (page == AnalysisPage::TASK_SPEED)) {
    wf->Hide();
    dlgTaskManagerShowModal(*(SingleWindow *)wf->GetRootOwner());
    wf->Show();
  }

  if (page == AnalysisPage::AIRSPACE)
    dlgAirspaceWarningsShowModal(wf->GetMainWindow(),
                                 glide_computer->GetAirspaceWarnings());

  Update();
}

static Window *
OnCreateCrossSectionControl(ContainerWindow &parent,
                            PixelScalar left, PixelScalar top,
                            UPixelScalar width, UPixelScalar height,
                            const WindowStyle style)
{
  csw = new CrossSectionControl(look->cross_section, look->map.airspace,
                                look->chart);
  csw->set(parent, left, top, width, height, style);
  csw->SetAirspaces(airspaces);
  csw->SetTerrain(terrain);
  UpdateCrossSection();
  return csw;
}

static Window *
OnCreateChartControl(ContainerWindow &parent,
                     PixelScalar left, PixelScalar top,
                     UPixelScalar width, UPixelScalar height,
                     const WindowStyle style)
{
  return new ChartControl(parent, left, top, width, height, style,
                          look->chart, look->map.airspace, look->map.aircraft,
                          look->map.task,
                          look->thermal_band);
}

static void
OnTimer(WndForm &Sender)
{
  Update();
}

static gcc_constexpr_data CallBackTableEntry CallBackTable[] = {
  DeclareCallBackEntry(OnCreateCrossSectionControl),
  DeclareCallBackEntry(OnCreateChartControl),
  DeclareCallBackEntry(OnNextClicked),
  DeclareCallBackEntry(OnPrevClicked),
  DeclareCallBackEntry(OnCalcClicked),
  DeclareCallBackEntry(OnCloseClicked),
  DeclareCallBackEntry(NULL)
};

void
dlgAnalysisShowModal(SingleWindow &parent, const Look &_look,
                     const FullBlackboard &_blackboard,
                     GlideComputer &_glide_computer,
                     const ProtectedTaskManager *_protected_task_manager,
                     const Airspaces *_airspaces,
                     const RasterTerrain *_terrain,
                     int _page)
{
  look = &_look;
  blackboard = &_blackboard;
  glide_computer = &_glide_computer;
  protected_task_manager = _protected_task_manager;
  airspaces = _airspaces;
  terrain = _terrain;

  wf = LoadDialog(CallBackTable, parent,
                  Layout::landscape ? _T("IDR_XML_ANALYSIS_L") :
                                      _T("IDR_XML_ANALYSIS"));
  assert(wf != NULL);

  wf->SetKeyDownNotify(FormKeyDown);

  wGrid = (ChartControl*)wf->FindByName(_T("frmGrid"));
  wInfo = (WndFrame *)wf->FindByName(_T("frmInfo"));
  wCalc = (WndButton *)wf->FindByName(_T("cmdCalc"));

  if (_page >= 0)
    page = (AnalysisPage)_page;

  Update();

  wf->SetTimerNotify(OnTimer, 2500);
  wf->ShowModal();

  delete wf;
}
