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

#include "ConfiguredPort.hpp"
#include "NullPort.hpp"
#include "TCPPort.hpp"
#include "K6BtPort.hpp"
#include "Profile/DeviceConfig.hpp"
#include "LogFile.hpp"

#ifdef _WIN32_WCE
#include "Config/Registry.hpp"
#endif

#ifdef ANDROID
#include "AndroidBluetoothPort.hpp"
#ifdef IOIOLIB
#include "AndroidIOIOUartPort.hpp"
#endif
#endif

#if defined(HAVE_POSIX)
#include "TTYPort.hpp"
#else
#include "SerialPort.hpp"
#endif

#ifndef NDEBUG
#include "DumpPort.hpp"
#endif

#if defined(HAVE_POSIX) && !defined(ANDROID)
#include <unistd.h>
#include <errno.h>
#endif

#include <windef.h> /* for MAX_PATH */

/**
 * Attempt to detect the GPS device.
 *
 * See http://msdn.microsoft.com/en-us/library/bb202042.aspx
 */
static bool
detect_gps(TCHAR *path, size_t path_max_size)
{
#ifdef _WIN32_WCE
  static const TCHAR *const gps_idm_key =
    _T("System\\CurrentControlSet\\GPS Intermediate Driver\\Multiplexer");
  static const TCHAR *const gps_idm_value = _T("DriverInterface");

  RegistryKey key(HKEY_LOCAL_MACHINE, gps_idm_key, true);
  return !key.error() &&
    key.get_value(gps_idm_value, path, path_max_size);
#else
  return false;
#endif
}

static Port *
WrapPort(const DeviceConfig &config, Port::Handler &handler, Port *port)
{
  if (config.k6bt && config.MaybeBluetooth())
    port = new K6BtPort(port, config.baud_rate, handler);

#ifndef NDEBUG
  if (config.dump_port)
    port = new DumpPort(port);
#endif

  return port;
}

static Port *
OpenPortInternal(const DeviceConfig &config, Port::Handler &handler)
{
  const TCHAR *path = NULL;
  TCHAR buffer[MAX_PATH];

  switch (config.port_type) {
  case DeviceConfig::PortType::DISABLED:
    return NULL;

  case DeviceConfig::PortType::SERIAL:
    if (config.path.empty())
      return NULL;

    path = config.path.c_str();
    break;

  case DeviceConfig::PortType::RFCOMM:
#ifdef ANDROID
    if (config.bluetooth_mac.empty()) {
      LogStartUp(_T("No Bluetooth MAC configured"));
      return NULL;
    }

    return OpenAndroidBluetoothPort(config.bluetooth_mac, handler);
#else
    LogStartUp(_T("Bluetooth not available on this platform"));
    return NULL;
#endif

  case DeviceConfig::PortType::IOIOUART:
#if defined(ANDROID) && defined(IOIOLIB)
    if (config.ioio_uart_id >= AndroidIOIOUartPort::getNumberUarts()) {
      LogStartUp(_T("No IOIOUart configured in profile"));
      return NULL;
    }

    return OpenAndroidIOIOUartPort(config.ioio_uart_id, config.baud_rate,
                                   handler);
#else
    LogStartUp(_T("IOIO Uart not available on this platform or version"));
    return NULL;
#endif

  case DeviceConfig::PortType::AUTO:
    if (!detect_gps(buffer, sizeof(buffer))) {
      LogStartUp(_T("no GPS detected"));
      return NULL;
    }

    LogStartUp(_T("GPS detected: %s"), buffer);

    path = buffer;
    break;

  case DeviceConfig::PortType::INTERNAL:
    break;

  case DeviceConfig::PortType::TCP_LISTENER: {
    TCPPort *port = new TCPPort(handler);
    if (!port->Open(config.tcp_port)) {
      delete port;
      return NULL;
    }

    return port;
  }

  case DeviceConfig::PortType::PTY: {
#if defined(HAVE_POSIX) && !defined(ANDROID)
    if (config.path.empty())
      return NULL;

    if (unlink(config.path.c_str()) < 0 && errno != ENOENT)
      return NULL;

    TTYPort *port = new TTYPort(handler);
    const char *slave_path = port->OpenPseudo();
    if (slave_path == NULL) {
      delete port;
      return NULL;
    }

    if (symlink(slave_path, config.path.c_str()) < 0) {
      delete port;
      return NULL;
    }

    return port;
#else
    return NULL;
#endif
  }
  }

  if (path == NULL)
    return NULL;

#ifdef HAVE_POSIX
  TTYPort *port = new TTYPort(handler);
#else
  SerialPort *port = new SerialPort(handler);
#endif
  if (!port->Open(path, config.baud_rate)) {
    delete port;
    return NULL;
  }

  return port;
}

Port *
OpenPort(const DeviceConfig &config, Port::Handler &handler)
{
  Port *port = OpenPortInternal(config, handler);
  if (port != NULL)
    port = WrapPort(config, handler, port);
  return port;
}
