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

#include "AirspaceRenderer.hpp"
#include "ComputerSettings.hpp"
#include "MapSettings.hpp"
#include "Projection/WindowProjection.hpp"
#include "Screen/Canvas.hpp"
#include "MapWindow/MapCanvas.hpp"
#include "Look/AirspaceLook.hpp"
#include "Airspace/Airspaces.hpp"
#include "Airspace/AirspacePolygon.hpp"
#include "Airspace/AirspaceCircle.hpp"
#include "Airspace/AirspaceVisitor.hpp"
#include "Airspace/AirspaceVisibility.hpp"
#include "Airspace/AirspaceWarning.hpp"
#include "Airspace/ProtectedAirspaceWarningManager.hpp"
#include "Engine/Airspace/AirspaceWarningManager.hpp"
#include "MapWindow/MapDrawHelper.hpp"
#include "Screen/Layout.hpp"
#include "NMEA/Aircraft.hpp"

#ifdef ENABLE_OPENGL
#include "Screen/OpenGL/Scope.hpp"
#endif

class AirspaceWarningCopy
{
private:
  StaticArray<const AbstractAirspace *,64> ids_inside, ids_warning, ids_acked;
  StaticArray<GeoPoint,32> locations;

public:
  void Visit(const AirspaceWarning& as) {
    if (as.GetWarningState() == AirspaceWarning::WARNING_INSIDE) {
      ids_inside.checked_append(&as.GetAirspace());
    } else if (as.GetWarningState() > AirspaceWarning::WARNING_CLEAR) {
      ids_warning.checked_append(&as.GetAirspace());
      locations.checked_append(as.GetSolution().location);
    }

    if (!as.IsAckExpired())
      ids_acked.checked_append(&as.GetAirspace());
  }

  void Visit(const AirspaceWarningManager &awm) {
    for (auto i = awm.begin(), end = awm.end(); i != end; ++i)
      Visit(*i);
  }

  void Visit(const ProtectedAirspaceWarningManager &awm) {
    const ProtectedAirspaceWarningManager::Lease lease(awm);
    Visit(lease);
  }

  const StaticArray<GeoPoint,32> &GetLocations() const {
    return locations;
  }

  bool HasWarning(const AbstractAirspace &as) const {
    return as.IsActive() && Find(as, ids_warning);
  }

  bool IsAcked(const AbstractAirspace &as) const {
    return (!as.IsActive()) || Find(as, ids_acked);
  }

  bool IsInside(const AbstractAirspace &as) const {
    return as.IsActive() && Find(as, ids_inside);
  }

  void VisitWarnings(AirspaceVisitor &visitor) const {
    for (auto it = ids_warning.begin(), end = ids_warning.end(); it != end; ++it)
      if (!IsAcked(**it))
        visitor.Visit(**it);
  }

  void VisitInside(AirspaceVisitor &visitor) const {
    for (auto it = ids_inside.begin(), end = ids_inside.end(); it != end; ++it)
      if (!IsAcked(**it))
        visitor.Visit(**it);
  }

private:
  bool Find(const AbstractAirspace& as,
            const StaticArray<const AbstractAirspace *,64> &list) const {
    return list.contains(&as);
  }
};


class AirspaceMapVisible: public AirspaceVisiblePredicate
{
private:
  const AirspaceWarningCopy &warnings;

public:
  AirspaceMapVisible(const AirspaceComputerSettings &_computer_settings,
                     const AirspaceRendererSettings &_renderer_settings,
                     const AircraftState& _state,
                     const AirspaceWarningCopy& _warnings)
    :AirspaceVisiblePredicate(_computer_settings, _renderer_settings, _state),
     warnings(_warnings) {}

  bool operator()(const AbstractAirspace& airspace) const {
    return AirspaceVisiblePredicate::operator()(airspace) ||
           warnings.IsInside(airspace) ||
           warnings.HasWarning(airspace);
  }
};

#ifdef ENABLE_OPENGL

class AirspaceVisitorRenderer : public AirspaceVisitor, protected MapCanvas
{
  const AirspaceLook &look;
  const AirspaceWarningCopy &warning_manager;
  const AirspaceRendererSettings &settings;

public:
  AirspaceVisitorRenderer(Canvas &_canvas, const WindowProjection &_projection,
                          const AirspaceLook &_look,
                          const AirspaceWarningCopy &_warnings,
                          const AirspaceRendererSettings &_settings)
    :MapCanvas(_canvas, _projection,
               _projection.GetScreenBounds().Scale(fixed(1.1))),
     look(_look), warning_manager(_warnings), settings(_settings)
  {
    glStencilMask(0xff);
    glClear(GL_STENCIL_BUFFER_BIT);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  }

  ~AirspaceVisitorRenderer() {
    glStencilMask(0xff);
  }

public:
  void Visit(const AirspaceCircle &airspace) {
    RasterPoint screen_center = projection.GeoToScreen(airspace.GetCenter());
    unsigned screen_radius = projection.GeoToScreenDistance(airspace.GetRadius());
    GLEnable stencil(GL_STENCIL_TEST);

    if (!warning_manager.IsAcked(airspace)) {
      GLEnable blend(GL_BLEND);
      SetupInterior(airspace);
      if (warning_manager.HasWarning(airspace) ||
          warning_manager.IsInside(airspace) ||
          look.thick_pen.GetWidth() >= 2 * screen_radius) {
        // fill whole circle
        canvas.DrawCircle(screen_center.x, screen_center.y, screen_radius);
      } else {
        // draw a ring inside the circle
        Color color = settings.classes[airspace.GetType()].color;
        Pen pen_donut(look.thick_pen.GetWidth() / 2, color.WithAlpha(90));
        canvas.SelectHollowBrush();
        canvas.Select(pen_donut);
        canvas.DrawCircle(screen_center.x, screen_center.y,
                      screen_radius - look.thick_pen.GetWidth() / 4);
      }
    }

    // draw outline
    SetupOutline(airspace);
    canvas.DrawCircle(screen_center.x, screen_center.y, screen_radius);
  }

  void Visit(const AirspacePolygon &airspace) {
    if (!PreparePolygon(airspace.GetPoints()))
      return;

    bool fill_airspace = warning_manager.HasWarning(airspace) ||
                         warning_manager.IsInside(airspace);
    GLEnable stencil(GL_STENCIL_TEST);

    if (!warning_manager.IsAcked(airspace)) {
      if (!fill_airspace) {
        // set stencil for filling (bit 0)
        SetFillStencil();
        DrawPrepared();
      }

      // fill interior without overpainting any previous outlines
      {
        SetupInterior(airspace, !fill_airspace);
        GLEnable blend(GL_BLEND);
        DrawPrepared();
      }

      if (!fill_airspace) {
        // clear fill stencil (bit 0)
        ClearFillStencil();
        DrawPrepared();
      }
    }

    // draw outline
    SetupOutline(airspace);
    DrawPrepared();
  }

private:
  void SetupOutline(const AbstractAirspace &airspace) {
    // set bit 1 in stencil buffer, where an outline is drawn
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glStencilFunc(GL_ALWAYS, 3, 3);
    glStencilMask(2);
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);

    if (settings.black_outline)
      canvas.SelectBlackPen();
    else
      canvas.Select(look.pens[airspace.GetType()]);
    canvas.SelectHollowBrush();
  }

  void SetupInterior(const AbstractAirspace &airspace,
                      bool check_fillstencil = false) {
    // restrict drawing area and don't paint over previously drawn outlines
    if (check_fillstencil)
      glStencilFunc(GL_EQUAL, 1, 3);
    else
      glStencilFunc(GL_EQUAL, 0, 2);
    glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);

    Color color = settings.classes[airspace.GetType()].color;
    canvas.Select(Brush(color.WithAlpha(90)));
    canvas.SelectNullPen();
  }

  void SetFillStencil() {
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
    glStencilFunc(GL_ALWAYS, 3, 3);
    glStencilMask(1);
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE);

    canvas.SelectHollowBrush();
    canvas.Select(look.thick_pen);
  }

  void ClearFillStencil() {
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
    glStencilFunc(GL_ALWAYS, 3, 3);
    glStencilMask(1);
    glStencilOp(GL_KEEP, GL_KEEP, GL_ZERO);

    canvas.SelectHollowBrush();
    canvas.Select(look.thick_pen);
  }
};

class AirspaceFillRenderer : public AirspaceVisitor, protected MapCanvas
{
  const AirspaceLook &look;
  const AirspaceWarningCopy &warning_manager;
  const AirspaceRendererSettings &settings;

public:
  AirspaceFillRenderer(Canvas &_canvas, const WindowProjection &_projection,
                       const AirspaceLook &_look,
                       const AirspaceWarningCopy &_warnings,
                       const AirspaceRendererSettings &_settings)
    :MapCanvas(_canvas, _projection,
               _projection.GetScreenBounds().Scale(fixed(1.1))),
     look(_look), warning_manager(_warnings), settings(_settings)
  {
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  }

public:
  void Visit(const AirspaceCircle &airspace) {
    RasterPoint screen_center = projection.GeoToScreen(airspace.GetCenter());
    unsigned screen_radius = projection.GeoToScreenDistance(airspace.GetRadius());

    {
      GLEnable blend(GL_BLEND);
      SetupInterior(airspace);
      canvas.DrawCircle(screen_center.x, screen_center.y, screen_radius);
    }

    // draw outline
    SetupOutline(airspace);
    canvas.DrawCircle(screen_center.x, screen_center.y, screen_radius);
  }

  void Visit(const AirspacePolygon &airspace) {
    if (!PreparePolygon(airspace.GetPoints()))
      return;

    if (!warning_manager.IsAcked(airspace)) {
      // fill interior without overpainting any previous outlines
      {
        SetupInterior(airspace);
        GLEnable blend(GL_BLEND);
        DrawPrepared();
      }
    }

    // draw outline
    SetupOutline(airspace);
    DrawPrepared();
  }

private:
  void SetupOutline(const AbstractAirspace &airspace) {
    if (settings.black_outline)
      canvas.SelectBlackPen();
    else
      canvas.Select(look.pens[airspace.GetType()]);
    canvas.SelectHollowBrush();
  }

  void SetupInterior(const AbstractAirspace &airspace) {
    Color color = settings.classes[airspace.GetType()].color;
    canvas.Select(Brush(color.WithAlpha(48)));
    canvas.SelectNullPen();
  }
};

#else // !ENABLE_OPENGL

/**
 * Class to render airspaces onto map in two passes,
 * one for border, one for area.
 * This is a bit slow because projections are performed twice.
 * The old way of doing it was possibly faster but required a lot
 * of code overhead.
 */
class AirspaceVisitorMap: 
  public AirspaceVisitor,
  public MapDrawHelper
{
  const AirspaceLook &look;
  const AirspaceWarningCopy &warnings;

public:
  AirspaceVisitorMap(MapDrawHelper &_helper,
                     const AirspaceWarningCopy &_warnings,
                     const AirspaceRendererSettings &_settings,
                     const AirspaceLook &_airspace_look)
    :MapDrawHelper(_helper),
     look(_airspace_look), warnings(_warnings)
  {
    switch (settings.fill_mode) {
    case AirspaceRendererSettings::FillMode::DEFAULT:
    case AirspaceRendererSettings::FillMode::PADDING:
      use_stencil = !IsAncientHardware();
      break;

    case AirspaceRendererSettings::FillMode::ALL:
      use_stencil = false;
      break;
    }
  }

  void Visit(const AirspaceCircle &airspace) {
    if (warnings.IsAcked(airspace))
      return;

    BufferRenderStart();
    SetBufferPens(airspace);

    RasterPoint center = proj.GeoToScreen(airspace.GetCenter());
    unsigned radius = proj.GeoToScreenDistance(airspace.GetRadius());
    DrawCircle(center, radius);
  }

  void Visit(const AirspacePolygon &airspace) {
    if (warnings.IsAcked(airspace))
      return;

    BufferRenderStart();
    SetBufferPens(airspace);
    DrawSearchPointVector(airspace.GetPoints());
  }

  void DrawIntercepts() {
    BufferRenderFinish();
  }

private:
  void SetBufferPens(const AbstractAirspace &airspace) {
    AirspaceClass airspace_class = airspace.GetType();

#ifndef HAVE_HATCHED_BRUSH
    buffer.Select(look.solid_brushes[airspace_class]);
#else /* HAVE_HATCHED_BRUSH */

#ifdef HAVE_ALPHA_BLEND
    if (settings.transparency && AlphaBlendAvailable()) {
      buffer.Select(look.solid_brushes[airspace_class]);
    } else {
#endif
      // this color is used as the black bit
      buffer.SetTextColor(LightColor(settings.classes[airspace_class].color));

      // get brush, can be solid or a 1bpp bitmap
      buffer.Select(look.brushes[settings.classes[airspace_class].brush]);

      buffer.SetBackgroundOpaque();
      buffer.SetBackgroundColor(COLOR_WHITE);
#ifdef HAVE_ALPHA_BLEND
    }
#endif

    buffer.SelectNullPen();

    if (use_stencil) {
      if (warnings.HasWarning(airspace) || warnings.IsInside(airspace)) {
        stencil.SelectBlackBrush();
        stencil.SelectNullPen();
      } else {
        stencil.Select(look.thick_pen);
        stencil.SelectHollowBrush();
      }
    }

#endif /* HAVE_HATCHED_BRUSH */
  }
};

class AirspaceOutlineRenderer
  :public AirspaceVisitor,
   protected MapCanvas
{
  const AirspaceLook &look;
  bool black;

public:
  AirspaceOutlineRenderer(Canvas &_canvas, const WindowProjection &_projection,
                          const AirspaceLook &_look, bool _black)
    :MapCanvas(_canvas, _projection,
               _projection.GetScreenBounds().Scale(fixed(1.1))),
     look(_look), black(_black)
  {
    if (black)
      canvas.SelectBlackPen();
    canvas.SelectHollowBrush();
  }

protected:
  void SetupCanvas(const AbstractAirspace &airspace) {
    if (!black)
      canvas.Select(look.pens[airspace.GetType()]);
  }

public:
  void Visit(const AirspaceCircle &airspace) {
    SetupCanvas(airspace);
    DrawCircle(airspace.GetCenter(), airspace.GetRadius());
  }

  void Visit(const AirspacePolygon &airspace) {
    SetupCanvas(airspace);
    DrawPolygon(airspace.GetPoints());
  }
};

#endif // !ENABLE_OPENGL

void
AirspaceRenderer::DrawIntersections(Canvas &canvas,
                                    const WindowProjection &projection) const
{
  for (unsigned i = intersections.size(); i--;) {
    RasterPoint sc;
    if (projection.GeoToScreenIfVisible(intersections[i], sc))
      look.intercept_icon.Draw(canvas, sc.x, sc.y);
  }
}

void
AirspaceRenderer::Draw(Canvas &canvas,
#ifndef ENABLE_OPENGL
                       Canvas &buffer_canvas, Canvas &stencil_canvas,
#endif
                       const WindowProjection &projection,
                       const AirspaceRendererSettings &settings,
                       const AirspaceWarningCopy &awc,
                       const AirspacePredicate &visible)
{
  if (airspaces == NULL)
    return;

#ifdef ENABLE_OPENGL
  if (settings.fill_mode == AirspaceRendererSettings::FillMode::ALL) {
    AirspaceFillRenderer renderer(canvas, projection, look, awc,
                                  settings);
    airspaces->VisitWithinRange(projection.GetGeoScreenCenter(),
                                          projection.GetScreenDistanceMeters(),
                                          renderer, visible);
  } else {
    AirspaceVisitorRenderer renderer(canvas, projection, look, awc,
                                     settings);
    airspaces->VisitWithinRange(projection.GetGeoScreenCenter(),
                                          projection.GetScreenDistanceMeters(),
                                          renderer, visible);
  }
#else
  MapDrawHelper helper(canvas, buffer_canvas, stencil_canvas, projection,
                       settings);
  AirspaceVisitorMap v(helper, awc, settings,
                       look);

  // JMW TODO wasteful to draw twice, can't it be drawn once?
  // we are using two draws so borders go on top of everything

  airspaces->VisitWithinRange(projection.GetGeoScreenCenter(),
                                        projection.GetScreenDistanceMeters(),
                                        v, visible);

  awc.VisitWarnings(v);
  awc.VisitInside(v);

  v.DrawIntercepts();

  AirspaceOutlineRenderer outline_renderer(canvas, projection,
                                           look,
                                           settings.black_outline);
  airspaces->VisitWithinRange(projection.GetGeoScreenCenter(),
                                        projection.GetScreenDistanceMeters(),
                                        outline_renderer, visible);
  awc.VisitWarnings(outline_renderer);
  awc.VisitInside(outline_renderer);
#endif

  intersections = awc.GetLocations();
}

void
AirspaceRenderer::Draw(Canvas &canvas,
#ifndef ENABLE_OPENGL
                       Canvas &buffer_canvas, Canvas &stencil_canvas,
#endif
                       const WindowProjection &projection,
                       const AirspaceRendererSettings &settings)
{
  if (airspaces == NULL)
    return;

  AirspaceWarningCopy awc;
  if (warning_manager != NULL)
    awc.Visit(*warning_manager);

  Draw(canvas,
#ifndef ENABLE_OPENGL
       buffer_canvas, stencil_canvas,
#endif
       projection, settings, awc, AirspacePredicateTrue());
}

void
AirspaceRenderer::Draw(Canvas &canvas,
#ifndef ENABLE_OPENGL
                       Canvas &buffer_canvas, Canvas &stencil_canvas,
#endif
                       const WindowProjection &projection,
                       const MoreData &basic,
                       const DerivedInfo &calculated,
                       const AirspaceComputerSettings &computer_settings,
                       const AirspaceRendererSettings &settings)
{
  if (airspaces == NULL)
    return;

  AirspaceWarningCopy awc;
  if (warning_manager != NULL)
    awc.Visit(*warning_manager);

  const AirspaceMapVisible visible(computer_settings, settings,
                                   ToAircraftState(basic, calculated), awc);
  Draw(canvas,
#ifndef ENABLE_OPENGL
       buffer_canvas, stencil_canvas,
#endif
       projection, settings, awc, visible);
}
