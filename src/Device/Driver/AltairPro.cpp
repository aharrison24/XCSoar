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

#include "Device/Driver/AltairPro.hpp"
#include "Device/Driver.hpp"
#include "Device/Internal.hpp"
#include "Device/Port/Port.hpp"
#include "NMEA/Checksum.hpp"
#include "NMEA/Info.hpp"
#include "NMEA/InputLine.hpp"
#include "Units/System.hpp"
#include "Waypoint/Waypoint.hpp"
#include "Util/StringUtil.hpp"
#include "Util/Macros.hpp"
#include "TimeoutClock.hpp"

#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <tchar.h>
#ifdef _UNICODE
#include <windows.h>
#endif

#define DECELWPNAMESIZE   24                        // max size of taskpoint name
#define DECELWPSIZE       DECELWPNAMESIZE + 25      // max size of WP declaration

class AltairProDevice : public AbstractDevice {
private:
  Port &port;

  bool DeclareInternal(const struct Declaration &declaration,
                       OperationEnvironment &env);
  void PutTurnPoint(const TCHAR *name, const Waypoint *waypoint,
                    OperationEnvironment &env);
  bool PropertySetGet(char *Buffer, size_t size, OperationEnvironment &env);
#ifdef _UNICODE
  bool PropertySetGet(TCHAR *Buffer, size_t size, OperationEnvironment &env);
#endif

public:
  AltairProDevice(Port &_port):port(_port){}

public:
  virtual bool ParseNMEA(const char *line, struct NMEAInfo &info);
  virtual bool Declare(const struct Declaration &declaration,
                       const Waypoint *home,
                       OperationEnvironment &env);
};

static bool
ReadAltitude(NMEAInputLine &line, fixed &value_r)
{
  fixed value;
  bool available = line.read_checked(value);
  char unit = line.read_first_char();
  if (!available)
    return false;

  if (unit == _T('f') || unit == _T('F'))
    value = Units::ToSysUnit(value, Unit::FEET);

  value_r = value;
  return true;
}

bool
AltairProDevice::ParseNMEA(const char *String, NMEAInfo &info)
{
  if (!VerifyNMEAChecksum(String))
    return false;

  NMEAInputLine line(String);
  char type[16];
  line.read(type, 16);

  // no propriatary sentence

  if (StringIsEqual(type, "$PGRMZ")) {
    fixed value;
    if (ReadAltitude(line, value))
      info.ProvidePressureAltitude(value);

    return true;
  }

  return false;
}

bool
AltairProDevice::Declare(const struct Declaration &declaration,
                         gcc_unused const Waypoint *home,
                         OperationEnvironment &env)
{
  port.StopRxThread();

  bool result = DeclareInternal(declaration, env);

  return result;
}

bool
AltairProDevice::DeclareInternal(const struct Declaration &declaration,
                                 OperationEnvironment &env)
{
  TCHAR Buffer[256];

  _stprintf(Buffer, _T("PDVSC,S,Pilot,%s"), declaration.pilot_name.c_str());
  if (!PropertySetGet(Buffer, ARRAY_SIZE(Buffer), env))
    return false;

  _stprintf(Buffer, _T("PDVSC,S,GliderID,%s"), declaration.aircraft_registration.c_str());
  if (!PropertySetGet(Buffer, ARRAY_SIZE(Buffer), env))
    return false;

  _stprintf(Buffer, _T("PDVSC,S,GliderType,%s"), declaration.aircraft_type.c_str());
  if (!PropertySetGet(Buffer, ARRAY_SIZE(Buffer), env))
    return false;

  /* TODO currently not supported by XCSOAR
   * Pilot2
   * CompetitionID
   * CompetitionClass
   * ObserverID
   * DeclDescription
   * DeclFlightDate
   */

  if (declaration.Size() > 1) {
    PutTurnPoint(_T("DeclTakeoff"), NULL, env);
    PutTurnPoint(_T("DeclLanding"), NULL, env);

    PutTurnPoint(_T("DeclStart"), &declaration.GetFirstWaypoint(), env);
    PutTurnPoint(_T("DeclFinish"), &declaration.GetLastWaypoint(), env);

    for (unsigned int index=1; index <= 10; index++){
      TCHAR TurnPointPropertyName[32];
      _stprintf(TurnPointPropertyName, _T("DeclTurnPoint%d"), index);

      if (index < declaration.Size() - 1) {
        PutTurnPoint(TurnPointPropertyName, &declaration.GetWaypoint(index),
                     env);
      } else {
        PutTurnPoint(TurnPointPropertyName, NULL, env);
      }
    }
  }

  _stprintf(Buffer, _T("PDVSC,S,DeclAction,DECLARE"));
  if (!PropertySetGet(Buffer, ARRAY_SIZE(Buffer), env))
    return false;

  if (_tcscmp(&Buffer[9], _T("LOCKED")) == 0)
    // FAILED! try to declare a task on a airborn recorder
    return false;

  // Buffer holds the declaration ticket.
  // but no one is intresting in that
  // eg "2010-11-21 13:01:43 (1)"

  return true;
}



bool
AltairProDevice::PropertySetGet(char *Buffer, size_t size,
                                OperationEnvironment &env)
{
  assert(Buffer != NULL);

  port.Flush();

  TimeoutClock timeout(5000);

  // eg $PDVSC,S,FOO,BAR*<cr>\r\n
  if (!PortWriteNMEA(port, Buffer, env))
    return false;

  Buffer[6] = _T('A');
  char *comma = strchr(&Buffer[8], ',');

  if (comma == NULL)
    return false;

  comma[1] = '\0';

  // expect eg $PDVSC,A,FOO,
  if (!port.ExpectString(Buffer, env, timeout.GetRemainingOrZero()))
    return false;

  // read value eg bar
  while (size > 0) {
    int remaining = timeout.GetRemainingSigned();
    if (remaining < 0)
      return false;

    if (port.WaitRead(env, remaining) != Port::WaitResult::READY)
      return false;

    int nbytes = port.Read(Buffer, size);
    if (nbytes < 0)
      return false;

    char *asterisk = (char *)memchr(Buffer, '*', nbytes);
    if (asterisk != NULL) {
      *asterisk = 0;
      return true;
    }

    size -= nbytes;
  }

  return false;
}

#ifdef _UNICODE
bool
AltairProDevice::PropertySetGet(TCHAR *s, size_t size,
                                OperationEnvironment &env)
{
  assert(s != NULL);

  char buffer[_tcslen(s) * 4 + 1];
  if (::WideCharToMultiByte(CP_ACP, 0, s, -1, buffer, sizeof(buffer),
                               NULL, NULL) <= 0)
    return false;

  if (!PropertySetGet(buffer, _tcslen(s) * 4 + 1, env))
    return false;

  if (::MultiByteToWideChar(CP_ACP, 0, buffer, -1, s, size) <= 0)
    return false;

  return true;

}
#endif

void
AltairProDevice::PutTurnPoint(const TCHAR *propertyName,
                              const Waypoint *waypoint,
                              OperationEnvironment &env)
{

  TCHAR Name[DECELWPNAMESIZE];
  TCHAR Buffer[DECELWPSIZE*2];

  int DegLat, DegLon;
  double tmp, MinLat, MinLon;
  char NoS, EoW;

  if (waypoint != NULL){

    CopyString(Name, waypoint->name.c_str(), ARRAY_SIZE(Name));

    tmp = (double)waypoint->location.latitude.Degrees();

    if(tmp < 0){
      NoS = 'S';
      tmp *= -1;
    } else NoS = 'N';

    DegLat = (int)tmp;
    MinLat = tmp - DegLat;
    MinLat *= 60;
    MinLat *= 1000;

    tmp = (double)waypoint->location.longitude.Degrees();

    if (tmp < 0){
      EoW = 'W';
      tmp *= -1;
    } else EoW = 'E';

    DegLon = (int)tmp;
    MinLon = tmp  - DegLon;
    MinLon *= 60;
    MinLon *= 1000;

  } else {

    Name[0] = '\0';
    DegLat = 0;
    MinLat = 0;
    DegLon = 0;
    MinLon = 0;
    NoS = 'N';
    EoW = 'E';
  }

  _stprintf(Buffer, _T("PDVSC,S,%s,%02d%05.0f%c%03d%05.0f%c%s"),
            propertyName,
            DegLat, MinLat, NoS, DegLon, MinLon, EoW, Name
  );

  PropertySetGet(Buffer, ARRAY_SIZE(Buffer), env);

}

static Device *
AltairProCreateOnPort(const DeviceConfig &config, Port &com_port)
{
  return new AltairProDevice(com_port);
}

const struct DeviceRegister atrDevice = {
  _T("Altair RU"),
  _T("Altair Recording Unit"),
  DeviceRegister::DECLARE,
  AltairProCreateOnPort,
};
