/* Copyright_License {

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

#ifndef XCSOAR_TASK_ACCESSOR_HPP
#define XCSOAR_TASK_ACCESSOR_HPP

#include "Engine/Task/TaskManager.hpp"
#include "Engine/Task/Tasks/BaseTask/OrderedTaskPoint.hpp"

class TaskAccessor {
  TaskManager &task_manager;
  const fixed floor_alt;

public:
  TaskAccessor(TaskManager &_task_manager, fixed _floor_alt)
    :task_manager(_task_manager), floor_alt(_floor_alt) {}

  gcc_pure
  bool is_ordered() const {
    const TaskInterface *task = task_manager.GetActiveTask();
    return task != NULL && task->GetType() == TaskInterface::ORDERED;
  }

  gcc_pure
  virtual bool is_empty() const {
    const TaskInterface *task = task_manager.GetActiveTask();
    return task == NULL || task->TaskSize() == 0;
  }

  gcc_pure
  bool is_finished() const {
    return task_manager.GetCommonStats().task_finished;
  }

  gcc_pure
  bool is_started() const {
    return task_manager.GetCommonStats().task_started;
  }

  gcc_pure
  GeoPoint random_oz_point(unsigned index, const fixed noise) const {
    return task_manager.RandomPointInTask(index, noise);
  }

  gcc_pure
  unsigned size() const {
    return task_manager.TaskSize();
  }

  gcc_pure
  GeoPoint getActiveTaskPointLocation() const {
    return task_manager.GetActiveTaskPoint()->GetLocation();
  }

  gcc_pure
  bool has_entered(unsigned index) const {
    const TaskInterface *task = task_manager.GetActiveTask();
    if (task == NULL || task->GetType() != TaskInterface::ORDERED)
      return true;

    const OrderedTask &o_task = *(const OrderedTask *)task;
    return o_task.IsValidIndex(index) &&
      o_task.GetTaskPoint(index).HasEntered();
  }

  gcc_pure
  const ElementStat leg_stats() const {
    return task_manager.GetStats().current_leg;
  }

  gcc_pure
  fixed target_height() const {
    if (task_manager.GetActiveTaskPoint()) {
      return max(floor_alt, task_manager.GetActiveTaskPoint()->GetElevation());
    } else {
      return floor_alt;
    }
  }

  gcc_pure
  fixed remaining_alt_difference() const {
    return task_manager.GetStats().total.solution_remaining.altitude_difference;
  }

  gcc_pure
  GlidePolar get_glide_polar() const {
    return task_manager.GetGlidePolar();
  }

  gcc_pure
  void setActiveTaskPoint(unsigned index) {
    task_manager.SetActiveTaskPoint(index);
  }

  gcc_pure
  unsigned getActiveTaskPointIndex() const {
    return task_manager.GetActiveTaskPointIndex();
  }
};

#endif
