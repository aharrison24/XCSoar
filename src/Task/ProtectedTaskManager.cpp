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

#include "ProtectedTaskManager.hpp"
#include "Util/Serialiser.hpp"
#include "Util/Deserialiser.hpp"
#include "Util/DataNodeXML.hpp"
#include "Task/TaskFile.hpp"
#include "LocalPath.hpp"
#include "Task/RoutePlannerGlue.hpp"

#include <windef.h> // for MAX_PATH

ProtectedTaskManager::ProtectedTaskManager(TaskManager &_task_manager,
                                           const TaskBehaviour &tb)
  :Guard<TaskManager>(_task_manager),
   task_behaviour(tb)
{
  _task_manager.SetTaskBehaviour(task_behaviour);
}

ProtectedTaskManager::~ProtectedTaskManager() {
  ExclusiveLease lease(*this);
  lease->SetIntersectionTest(NULL); // de-register
}

void 
ProtectedTaskManager::SetGlidePolar(const GlidePolar &glide_polar)
{
  ExclusiveLease lease(*this);
  lease->SetGlidePolar(glide_polar);
}

TaskManager::TaskMode 
ProtectedTaskManager::GetMode() const
{
  Lease lease(*this);
  return lease->GetMode();
}

const OrderedTaskBehaviour 
ProtectedTaskManager::GetOrderedTaskBehaviour() const
{
  Lease lease(*this);
  return lease->GetOrderedTaskBehaviour();
}

const Waypoint* 
ProtectedTaskManager::GetActiveWaypoint() const
{
  Lease lease(*this);
  const TaskWaypoint *tp = lease->GetActiveTaskPoint();
  if (tp)
    return &tp->GetWaypoint();

  return NULL;
}

bool
ProtectedTaskManager::IsInSector (const unsigned index,
                                  const AircraftState &ref) const
{
  Lease lease(*this);
  return lease->IsInSector(index, ref);
}

bool
ProtectedTaskManager::SetTarget(const unsigned index, const fixed range,
   const fixed radial)
{
  ExclusiveLease lease(*this);
  return lease->SetTarget(index, range, radial);
}

bool
ProtectedTaskManager::TargetLock(const unsigned index, bool do_lock)
{
  ExclusiveLease lease(*this);
  return lease->TargetLock(index, do_lock);
}

void 
ProtectedTaskManager::IncrementActiveTaskPoint(int offset)
{
  ExclusiveLease lease(*this);
  lease->IncrementActiveTaskPoint(offset);
}

void 
ProtectedTaskManager::IncrementActiveTaskPointArm(int offset)
{
  ExclusiveLease lease(*this);

  switch (lease->GetTaskAdvance().get_advance_state()) {
  case TaskAdvance::MANUAL:
  case TaskAdvance::AUTO:
    lease->IncrementActiveTaskPoint(offset);
    break;
  case TaskAdvance::START_DISARMED:
  case TaskAdvance::TURN_DISARMED:
    if (offset>0) {
      lease->GetTaskAdvance().set_armed(true);
    } else {
      lease->IncrementActiveTaskPoint(offset);
    }
    break;
  case TaskAdvance::START_ARMED:
  case TaskAdvance::TURN_ARMED:
    if (offset>0) {
      lease->IncrementActiveTaskPoint(offset);
    } else {
      lease->GetTaskAdvance().set_armed(false);
    }
    break;
  }
}

bool 
ProtectedTaskManager::DoGoto(const Waypoint &wp)
{
  ExclusiveLease lease(*this);
  return lease->DoGoto(wp);
}

AircraftState 
ProtectedTaskManager::GetStartState() const
{
  Lease lease(*this);
  return lease->GetStartState();
}

fixed 
ProtectedTaskManager::GetFinishHeight() const
{
  Lease lease(*this);
  return lease->GetFinishHeight();
}

OrderedTask*
ProtectedTaskManager::TaskClone() const
{
  Lease lease(*this);
  return lease->Clone(task_behaviour);
}

bool
ProtectedTaskManager::TaskCommit(const OrderedTask& that)
{
  ExclusiveLease lease(*this);
  return lease->Commit(that);
}

bool 
ProtectedTaskManager::TaskSave(const TCHAR* path, const OrderedTask& task)
{
  DataNodeXML root(DataNodeXML::CreateRoot(_T("Task")));
  Serialiser tser(root);
  tser.Serialise(task);

  return root.Save(path);
}

bool 
ProtectedTaskManager::TaskSave(const TCHAR* path)
{
  OrderedTask* task = TaskClone();
  bool retval = TaskSave(path, *task);
  delete task;
  return retval;
}

const TCHAR ProtectedTaskManager::default_task_path[] = _T("Default.tsk");


OrderedTask*
ProtectedTaskManager::TaskCreateDefault(const Waypoints *waypoints,
                                          TaskFactoryType factoryfail)
{
  TCHAR path[MAX_PATH];
  LocalPath(path, default_task_path);
  OrderedTask *task = TaskFile::GetTask(path, task_behaviour, waypoints, 0);
  if (!task) {
    task = new OrderedTask(task_behaviour);
    assert(task);
    task->SetFactory(factoryfail);
  }
  return task;
}

bool 
ProtectedTaskManager::TaskSaveDefault()
{
  TCHAR path[MAX_PATH];
  LocalPath(path, default_task_path);
  return TaskSave(path);
}

void 
ProtectedTaskManager::Reset()
{
  ExclusiveLease lease(*this);
  lease->Reset();
}

void
ProtectedTaskManager::SetRoutePlanner(const RoutePlannerGlue *_route) {
  intersection_test.SetRoute(_route);

  ExclusiveLease lease(*this);
  lease->SetIntersectionTest(&intersection_test);
}

bool
ReachIntersectionTest::Intersects(const AGeoPoint& destination)
{
  if (!route)
    return false;
  RoughAltitude h, h_dummy;
  route->FindPositiveArrival(destination, h, h_dummy);
  // we use find_positive_arrival here instead of is_inside, because may use
  // arrival height for sorting later
  return (h< destination.altitude);
}
