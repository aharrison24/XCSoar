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

#ifndef ABSTRACT_TASK_FACTORY_HPP
#define ABSTRACT_TASK_FACTORY_HPP

#include "Util/NonCopyable.hpp"
#include "Util/ConstArray.hpp"
#include "Compiler.h"
#include "Math/fixed.hpp"

#include <vector>
#include <stdint.h>

class AATPoint;
class StartPoint;
class IntermediateTaskPoint;
class ASTPoint;
class FinishPoint;
class OrderedTask;
struct TaskBehaviour;
struct OrderedTaskBehaviour;
class OrderedTaskPoint;
class ObservationZonePoint;
struct Waypoint;

/**
 * AbstractTaskFactory is a class used as a sort of wizard
 * to assist clients to create valid tasks of particular types.
 *
 * This serves to constrain the TaskPoint types to valid ones
 * and also contains a method to validate a constructed or partially
 * constructed task according to rules.
 *
 * \todo 
 * - add descriptor field so validate() methods can return feedback about
 *   validity of task etc.  This can also be added to saved files.
 * - check TaskBehaviour.task_scored and ask if changes are ok if task/flight is started
 */
class AbstractTaskFactory: private NonCopyable
{
public:
  /** Legal types based on position */
  enum LegalAbstractPointType: uint8_t {
    POINT_START,
    POINT_AAT,
    POINT_AST,
    POINT_FINISH
  };

  /** Vector of legal abstract point types (non-OZ specific) */
  typedef std::vector<LegalAbstractPointType> LegalAbstractVector;

  /** Legal types of points with observation zones */
  enum LegalPointType: uint8_t {
    START_SECTOR = 0,
    START_LINE,
    START_CYLINDER,
    FAI_SECTOR,
    KEYHOLE_SECTOR,
    BGAFIXEDCOURSE_SECTOR,
    BGAENHANCEDOPTION_SECTOR,
    AST_CYLINDER,
    AAT_CYLINDER,
    AAT_SEGMENT,
    FINISH_SECTOR,
    FINISH_LINE,
    FINISH_CYLINDER,
    START_BGA,
    AAT_ANNULAR_SECTOR,
  };

  /** Vector of legal point types */
  typedef std::vector<LegalPointType> LegalPointVector;

  typedef ConstArray<LegalPointType> LegalPointConstArray;

  /** Task Validation Error Types */
  enum TaskValidationErrorType: uint8_t {
    NO_VALID_START,
    NO_VALID_FINISH,
    TASK_NOT_CLOSED,
    TASK_NOT_HOMOGENEOUS,
    INCORRECT_NUMBER_TURNPOINTS,
    EXCEEDS_MAX_TURNPOINTS,
    UNDER_MIN_TURNPOINTS,
    TURNPOINTS_NOT_UNIQUE,
    INVALID_FAI_TRIANGLE_GEOMETRY,
    EMPTY_TASK,
    NON_FAI_OZS
  };

  /** Vector of errors returned by validation routine */
  typedef std::vector<TaskValidationErrorType> TaskValidationErrorVector;

protected:
  /** task managed by this factory */
  OrderedTask &m_task;
  /** behaviour (settings) */
  const TaskBehaviour &m_behaviour;

  /** list of valid start types, for specialisation */
  LegalPointConstArray m_start_types;
  /** list of valid intermediate types, for specialisation */
  LegalPointConstArray m_intermediate_types;
  /** list of valid finish types, for specialisation */
  LegalPointConstArray m_finish_types;

  /** list of errors returned by task validation */
  TaskValidationErrorVector m_validation_errors;

protected:
  /**
   * Constructor
   *
   * @param task Ordered task to be managed by this factory
   * @param behaviour Behaviour (options)
   */
  AbstractTaskFactory(OrderedTask& task, const TaskBehaviour &behaviour,
                      const LegalPointConstArray _start_types,
                      const LegalPointConstArray _intermediate_types,
                      const LegalPointConstArray _finish_types)
    :m_task(task), m_behaviour(behaviour),
     m_start_types(_start_types),
     m_intermediate_types(_intermediate_types),
     m_finish_types(_finish_types) {}

public:
  virtual ~AbstractTaskFactory() {}

  /// @todo should be abstract
  virtual void UpdateOrderedTaskBehaviour(OrderedTaskBehaviour& to); 

  /**
   * Replace taskpoint in ordered task.
   * May fail if the candidate is the wrong type.
   * Does nothing (but returns true) if replacement is equivalent
   * Ownership is transferred to this object.
   *
   * @param tp Taskpoint to become replacement
   * @param position Index in task sequence of task point to replace
   * @param auto_mutate Modify task point types automatically to retain validity
   *
   * @return True on success
   */
  bool Replace(const OrderedTaskPoint &tp, const unsigned position,
               const bool auto_mutate = true);

  /**
   * Add taskpoint to ordered task.  It is the
   * user's responsibility to ensure the task is
   * valid (has a start/intermediate/finish).
   *
   * @param new_tp New taskpoint to add
   * @param auto_mutate Modify task point types automatically to retain validity
   *
   * @return True if operation successful
   */
  bool Append(const OrderedTaskPoint &new_tp, const bool auto_mutate = true);

  /**
   * Add optional start point to ordered task.
   * Copies current start point's shape or uses defaults
   * if no start exists.
   *
   * @param wp location of new point
   *
   * @return True if operation successful
   */
  bool AppendOptionalStart(const Waypoint& wp);

  /**
   * Add optional start point to ordered task.  It is the
   * user's responsibility to ensure the point is
   * valid.  Used by deserialise_point()
   * @param new_tp New taskpoint to add
   * @param auto_mutate Modify task point types automatically to retain validity
   *
   * @return True if operation successful
   */
  bool AppendOptionalStart(const OrderedTaskPoint &new_tp,
                           const bool auto_mutate = true);

  /**
   * Insert taskpoint to ordered task.  It is the
   * user's responsibility to ensure the task is
   * valid (has a start/intermediate/finish).
   *
   * @param new_tp New taskpoint to insert
   * @param position Sequence before which to insert new task point
   * @param auto_mutate Modify task point types automatically to retain validity
   *
   * @return True if operation successful
   */
  bool Insert(const OrderedTaskPoint &new_tp, const unsigned position,
              const bool auto_mutate = true);

  /**
   * Remove taskpoint from ordered task.  It is the
   * user's responsibility to ensure the task is
   * valid (has a start/intermediate/finish).
   *
   * @param position Sequence number of taskpoint to remove
   * @param auto_mutate Modify task point types automatically to retain validity
   *
   * @return True if operation successful
   */
  bool Remove(const unsigned position, const bool auto_mutate = true);

  /**
   * Swap taskpoint and its successor in ordered task.
   * May fail if the candidate is the wrong type.
   * Does nothing (but returns true) if replacement is equivalent
   * Ownership is transferred to this object.
   *
   * @param position Index in task sequence of task point to replace
   * @param auto_mutate Modify task point types automatically to retain validity
   *
   * @return True on success
   */
  bool Swap(const unsigned position, const bool auto_mutate = true);

  /**
   * Relocate a task point to a new location
   *
   * @param position Index in task sequence of task point to replace
   * @param waypoint Waypoint of replacement
   *
   * @return New taskpoint (or old one if failed)
   */
  const OrderedTaskPoint &Relocate(const unsigned position,
                                   const Waypoint& waypoint);

  /**
   * Provide list of start types valid for later passing to createStart()
   *
   * @return list of valid start types
   */
  const LegalPointConstArray &GetStartTypes() const {
    return m_start_types;
  }

  /**
   * Provide list of intermediate types valid for later passing to createIntermediate()
   *
   * @return list of valid intermediate types
   */
  const LegalPointConstArray &GetIntermediateTypes() const {
    return m_intermediate_types;
  }

  /**
   * Provide list of finish types valid for later passing to createFinish()
   *
   * @return list of valid finish types
   */
  const LegalPointConstArray &GetFinishTypes() const {
    return m_finish_types;
  }

  /**
   * @param start_radius: either fixed_minus_one or a valid value
   * @param turnpoint_radius: either fixed_minus_one or a valid value
   * @param finish_radius: either fixed_minus_one or a valid value
   *
   * sets radiuses to the correct default for that task type or general defaults
   */
  gcc_pure
  virtual void
  GetPointDefaultSizes(const LegalPointType type, fixed &start_radius,
                       fixed &turnpoint_radius, fixed &finish_radius) const;

  /** 
   * Create a point of supplied type using default sector sizes
   * 
   * @param type Type of point to be created
   * @param wp Waypoint reference
   * 
   * @return Initialised object.  Transfers ownership to client.
   */
  gcc_pure gcc_malloc
  OrderedTaskPoint* CreatePoint(const LegalPointType type,
                                const Waypoint &wp) const;

  /**
   * Create a point of supplied type
   * Optionally overrides the default sector sizes
   *
   * @param type Type of point to be created
   * @param wp Waypoint reference
   * @param start_radius.  if < 0 then use default, else use for new point
   * @param turnpoint_radius.  if < 0 then use default, else use for new point
   * @param finish_radius.  if < 0 then use default, else use for new point
   * @return Initialised object.  Transfers ownership to client.
   */
  gcc_pure gcc_malloc
  OrderedTaskPoint* CreatePoint(const LegalPointType type,
                                const Waypoint &wp,
                                const fixed start_radius,
                                const fixed turnpoint_radius,
                                const fixed finish_radius) const;

  /**
   * Create start point of specified type
   *
   * @param type Type of start point
   * @param wp Waypoint reference
   *
   * @return Initialised StartPoint if valid, otherwise NULL
   */
  gcc_pure gcc_malloc
  StartPoint* CreateStart(const LegalPointType type, const Waypoint &wp) const;

  /**
   * Create intermediate point of specified type
   *
   * @param type Type of intermediate point
   * @param wp Waypoint reference
   *
   * @return Initialised IntermediateTaskPoint if valid, otherwise NULL
   */
  gcc_pure gcc_malloc
  IntermediateTaskPoint* CreateIntermediate(const LegalPointType type,
                                            const Waypoint &wp) const;

  /**
   * Create finish point of specified type
   *
   * @param type Type of finish point
   * @param wp Waypoint reference
   *
   * @return Initialised FinishPoint if valid, otherwise NULL
   */
  gcc_pure gcc_malloc
  FinishPoint* CreateFinish(const LegalPointType type,
                            const Waypoint &wp) const;

  /**
   * Create start point of default type
   *
   * @param wp Waypoint reference
   *
   * @return Initialised StartPoint if valid, otherwise NULL
   */
  gcc_pure gcc_malloc
  StartPoint* CreateStart(const Waypoint &wp) const;

  /**
   * Create intermediate point of default type
   *
   * @param wp Waypoint reference
   *
   * @return Initialised IntermediateTaskPoint if valid, otherwise NULL
   */
  gcc_pure gcc_malloc
  IntermediateTaskPoint* CreateIntermediate(const Waypoint &wp) const;

  /**
   * Create finish point of default type
   *
   * @param wp Waypoint reference
   *
   * @return Initialised FinishPoint if valid, otherwise NULL
   */
  gcc_pure gcc_malloc
  FinishPoint* CreateFinish(const Waypoint &wp) const;

  /**
   * Create start point given an OZ
   *
   * @param pt OZ to be used
   * @param wp Waypoint reference
   *
   * @return Initialised object.  Ownership is transferred to client.
   */
  gcc_pure gcc_malloc
  StartPoint* CreateStart(ObservationZonePoint* pt, const Waypoint &wp) const;

  /**
   * Creates new OrderedTaskPoint of a different type with the
   * same radius.
   * Does not validate the new type against the current task type.
   * @param tp
   * @return pointer to the point
   */
  gcc_pure gcc_malloc
  OrderedTaskPoint* CreateMutatedPoint(const OrderedTaskPoint &tp,
                                       const LegalPointType newtype) const;

  /**
  * Returns "suggested/best" type for the current factory based on the type
  * of point that was created by a different factory.  Used when task type
  * changes, e.g. if task type from Racing to AAT, will return AAT_CYLINDER
  * for a AST_CYLINDER
  * Return type is compatible type with original type
  *   (Start/Intermediate/Finish)
  * Does not consider position of point in task
  *
  * @param tp The tp that exists (from task built using different factory)
  * @return The suggested mutated type for the current factory
  */
  virtual gcc_pure
  LegalPointType GetMutatedPointType(const OrderedTaskPoint &tp) const;


  /**
   * Create an AST point given an OZ
   *
   * @param pt OZ to be used
   * @param wp Waypoint reference
   *
   * @return Initialised object.  Ownership is transferred to client.
   */
  gcc_pure gcc_malloc
  ASTPoint* CreateASTPoint(ObservationZonePoint* pt, const Waypoint &wp) const;

  /**
   * Create an AAT point given an OZ
   *
   * @param pt OZ to be used
   * @param wp Waypoint reference
   *
   * @return Initialised object.  Ownership is transferred to client.
   */
  gcc_pure gcc_malloc
  AATPoint* CreateAATPoint(ObservationZonePoint* pt, const Waypoint &wp) const;

  /**
   * Create a finish point given an OZ
   *
   * @param pt OZ to be used
   * @param wp Waypoint reference
   *
   * @return Initialised object.  Ownership is transferred to client.
   */
  gcc_pure gcc_malloc
  FinishPoint* CreateFinish(ObservationZonePoint* pt, const Waypoint &wp) const;

  /**
   * Check whether task is complete and valid according to factory rules
   * Adds error types to m_validation_errors
   *
   * @return True if task is valid according to factory rules
   */
  virtual bool Validate();

  /**
   * Checks whether shapes of all OZs, start, finish are valid
   * for an FAI badge or record
   * Appends warning message to m_validation_errors
   * This is used independently of check_task() validation
   *
   * @return True if all OZs are valid for a FAI badge or record
   */
  bool ValidateFAIOZs();

  gcc_pure
  const OrderedTaskBehaviour &GetOrderedTaskBehaviour() const;

  /**
   * Check whether an abstract type is valid in a specified position
   *
   * @param type Type to check
   * @param position Index position in task
   *
   * @return True if type is valid
   */
  gcc_pure
  virtual bool ValidAbstractType(LegalAbstractPointType type,
                                 const unsigned position) const;

  /**
   * List valid intermediate types for a given position
   *
   * @param position Index position in task
   *
   * @return Vector of valid types in position
   */
  gcc_pure
  LegalPointVector GetValidIntermediateTypes(unsigned position) const;

  /**
   * List all valid start types for the task type
   *
   * @return Vector of valid types in position
   */
  gcc_pure
  LegalPointVector GetValidStartTypes() const;

  /**
   * Checks for a finish point.
   * If task has at least two points, then converts
   * last point to finish if is not already a finish.
   * @return True if converted last point to a finish
   *         False if did not convert (or did not have 2+ pts)
   */
  bool CheckAddFinish();

  /** List all valid intermediate types for the task type
   *
   * @return Vector of valid types in position
   */
  gcc_pure
  LegalPointVector GetValidIntermediateTypes() const;

  /**
   * List all valid finish types for the task type
   *
   * @return Vector of valid types in position
   */
  gcc_pure
  LegalPointVector GetValidFinishTypes() const;

  /**
   * List valid types for a given position
   *
   * @param position Index position in task
   *
   * @return Vector of valid types in position
   */
  gcc_pure
  LegalPointVector GetValidTypes(unsigned position) const;

  /**
   * Inspect the type of a point
   *
   * @param point Point to check
   *
   * @return Type of supplied point
   */
  gcc_pure
  LegalPointType GetType(const OrderedTaskPoint &point) const;

  /**
   * Determines whether task is closed (finish same as start)
   * @return true if task is closed
   */
  gcc_pure
  bool IsClosed() const;

  /**
   * Determines whether task is unique 
   * (other than start/finish, no points used more than once)
   * @return true if task is unique
   */
  gcc_pure
  bool IsUnique() const;

  /**
   * Determines whether a task's intermediate points are homogeneous
   *
   * @return true if points are homogeneous
  */
  gcc_pure
  bool IsHomogeneous() const;

  /**
   * Determine if a type is valid for a FinishPoint
   *
   * @param type Type to check
   *
   * @return True if type is valid
   */
  gcc_pure
  bool IsValidFinishType(LegalPointType type) const;

  /**
   * Determine if a type is valid for a StartPoint
   *
   * @param type Type to check
   *
   * @return True if type is valid
   */
  gcc_pure
  bool IsValidStartType(LegalPointType type) const;

  /**
   * Determine if a type is valid for an IntermediateTaskPoint
   *
   * @param type Type to check
   *
   * @return True if type is valid
   */
  gcc_pure
  bool IsValidIntermediateType(LegalPointType type) const;

  /**
   * removes excess turnpoints from end of task if the
   * max number of tps in the task type is less
   *
   * @return True if task is changed
   */
  bool RemoveExcessTPsPerTaskType();

  /**
   * Sets / verifies all tps for the task type.
   * The resultant task is invalid if there are not enough
   * or too many tps for the task type
   * Also checks is_closed property if has Finish
   *
   * Does not ensure tps are unique
   *
   * * @return True if task is changed
   */
  bool MutateTPsToTaskType();

  /**
   * Call to validate() populates this vector
   * @return returns vector of errors for current task
   */
  gcc_pure
  TaskValidationErrorVector GetValidationErrors();

protected:
  /**
   * Test whether a candidate object is of correct type to be added/replaced/etc
   * in the task.
   *
   * @param new_tp Candidate object
   * @param position Desired task sequence index of candidate
   *
   * @return True if candidate is valid at the position
   */
  gcc_pure
  virtual bool IsValidType(const OrderedTaskPoint &new_tp,
                           unsigned position) const;

  /** 
   * Check whether the supplied position can be a StartPoint
   * 
   * @param position index to test
   * 
   * @return True if possible
   */
  bool IsPositionStart(const unsigned position) const {
    return position == 0;
  }

  /** 
   * Check whether the supplied position can be an IntermediateTaskPoint
   * 
   * @param position index to test
   * 
   * @return True if possible
   */
  gcc_pure
  bool IsPositionIntermediate(const unsigned position) const;

  /** 
   * Check whether the supplied position can be a FinishPoint
   * 
   * @param position index to test
   * 
   * @return True if possible
   */
  gcc_pure
  bool IsPositionFinish(const unsigned position) const;

  /**
   * Inserts the validation error type into the vector of validation errors
   *
   * @param e The validation error type to be added
   */
  void AddValidationError(TaskValidationErrorType e);

private:
  /**
   * Verifies and sets the finish waypoint per the is_closed
   * property of task type.
   *
   * If a finish point exists and the is_closed property
   * is set, sets the finish point waypoint to the waypoint of Start
   *
   * @return True if task is changed
   */
  bool MutateClosedFinishPerTaskType();

  /**
   * Clears the vector of validation errors for the current task
   */
  void ClearValidationErrors();
};

#endif
