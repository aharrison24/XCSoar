name-to-bin = $(patsubst %,$(TARGET_BIN_DIR)/%$(TARGET_EXEEXT),$(1))

TESTFAST = \
	test_normalise \
	test_fixed \
	test_waypoints \
	test_pressure \
	test_mc \
	test_task \
	test_modes \
	test_automc \
	test_acfilter \
	test_trees \
	test_vopt

TESTSLOW = \
	test_bestcruisetrack \
	test_airspace \
	test_effectivemc \
	test_cruiseefficiency \
	test_highterrain \
	test_randomtask \
	test_flight \
	test_olc \
	test_aat \
	test_replay_olc

HARNESS_PROGRAMS = $(TESTFAST) $(TESTSLOW)

build-harness: $(call name-to-bin,$(HARNESS_PROGRAMS))

testslow: $(call name-to-bin,$(TESTSLOW))
	$(Q)perl $(TEST_SRC_DIR)/testall.pl $(TESTSLOW)

testfast: $(call name-to-bin,$(TESTFAST))
	$(Q)perl $(TEST_SRC_DIR)/testall.pl $(TESTFAST)

TEST1_LDADD = $(HARNESS_LIBS) \
	$(ENGINE_CORE_LIBS) \
	$(IO_LIBS) \
	$(ZZIP_LDADD) \
	$(MATH_LIBS) \
	$(UTIL_LIBS)
TEST1_LDLIBS = \
	$(ZZIP_LDLIBS)

define link-harness-program
$(1)_SOURCES = \
	$(SRC)/NMEA/FlyingState.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(SRC)/Formatter/AirspaceFormatter.cpp \
	$(TEST_SRC_DIR)/FakeTerrain.cpp \
	$(TEST_SRC_DIR)/$(1).cpp
$(1)_LDADD = $(TEST1_LDADD)
$(1)_LDLIBS = $(TEST1_LDLIBS)
$(call link-program,$(1),$(1))
endef

$(foreach name,$(HARNESS_PROGRAMS),$(eval $(call link-harness-program,$(name))))

TEST_NAMES = \
	test_fixed \
	test_normalise \
	test_waypoints \
	test_pressure \
	test_task \
	TestOverwritingRingBuffer \
	TestDateTime \
	TestMathTables \
	TestAngle TestUnits TestEarth TestSunEphemeris \
	TestValidity TestUTM TestProfile \
	TestRadixTree TestGeoBounds TestGeoClip \
	TestLogger TestDriver TestClimbAvCalc \
	TestWaypointReader TestThermalBase \
	test_load_task TestFlarmNet \
	TestColorRamp TestGeoPoint TestDiffFilter \
	TestFileUtil TestPolars TestCSVLine TestGlidePolar \
	test_replay_task TestProjection TestFlatPoint TestFlatLine TestFlatGeoPoint \
	TestMacCready TestOrderedTask \
	TestPlanes \
	TestTaskPoint \
	TestTaskWaypoint \
	TestZeroFinder \
	TestAirspaceParser \
	TestMETARParser \
	TestIGCParser \
	TestByteOrder \
	TestByteOrder2 \
	TestStrings \
	TestUnitsFormatter \
	TestGeoPointFormatter \
	TestHexColorFormatter \
	TestByteSizeFormatter \
	TestTimeFormatter \
	TestIGCFilenameFormatter \
	TestLXNToIGC

TESTS = $(call name-to-bin,$(TEST_NAMES))

TEST_OVERWRITING_RING_BUFFER_SOURCES = \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestOverwritingRingBuffer.cpp
TEST_OVERWRITING_RING_BUFFER_DEPENDS = MATH
$(eval $(call link-program,TestOverwritingRingBuffer,TEST_OVERWRITING_RING_BUFFER))

TEST_IGC_PARSER_SOURCES = \
	$(SRC)/IGC/IGCParser.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestIGCParser.cpp
TEST_IGC_PARSER_DEPENDS = MATH
$(eval $(call link-program,TestIGCParser,TEST_IGC_PARSER))

TEST_BYTE_ORDER_SOURCES = \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestByteOrder.cpp
$(eval $(call link-program,TestByteOrder,TEST_BYTE_ORDER))

TEST_BYTE_ORDER2_SOURCES = \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestByteOrder2.cpp
$(eval $(call link-program,TestByteOrder2,TEST_BYTE_ORDER2))

TEST_METAR_PARSER_SOURCES = \
	$(SRC)/Weather/METARParser.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestMETARParser.cpp
TEST_METAR_PARSER_DEPENDS = MATH
$(eval $(call link-program,TestMETARParser,TEST_METAR_PARSER))

TEST_AIRSPACE_PARSER_SOURCES = \
	$(SRC)/Airspace/AirspaceParser.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(TEST_SRC_DIR)/FakeDialogs.cpp \
	$(TEST_SRC_DIR)/FakeTerrain.cpp \
	$(TEST_SRC_DIR)/FakeLanguage.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestAirspaceParser.cpp
TEST_AIRSPACE_PARSER_LDADD = $(FAKE_LIBS)
TEST_AIRSPACE_PARSER_DEPENDS = ENGINE IO ZZIP MATH UTIL
$(eval $(call link-program,TestAirspaceParser,TEST_AIRSPACE_PARSER))

TEST_DATE_TIME_SOURCES = \
	$(SRC)/DateTime.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestDateTime.cpp
TEST_DATE_TIME_DEPENDS = MATH
$(eval $(call link-program,TestDateTime,TEST_DATE_TIME))

TEST_PROFILE_SOURCES = \
	$(SRC)/LocalPath.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Util/UTF8.cpp \
	$(SRC)/Profile/Profile.cpp \
	$(SRC)/Profile/ProfileMap.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/TestProfile.cpp
TEST_PROFILE_DEPENDS = MATH IO
$(eval $(call link-program,TestProfile,TEST_PROFILE))

TEST_MAC_CREADY_SOURCES = \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestMacCready.cpp
TEST_MAC_CREADY_OBJS = $(call SRC_TO_OBJ,$(TEST_MAC_CREADY_SOURCES))
TEST_MAC_CREADY_DEPENDS = ENGINE MATH UTIL
$(eval $(call link-program,TestMacCready,TEST_MAC_CREADY))

TEST_ORDERED_TASK_SOURCES = \
	$(SRC)/NMEA/FlyingState.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestOrderedTask.cpp
TEST_ORDERED_TASK_OBJS = $(call SRC_TO_OBJ,$(TEST_ORDERED_TASK_SOURCES))
TEST_ORDERED_TASK_DEPENDS = ENGINE MATH UTIL
$(eval $(call link-program,TestOrderedTask,TEST_ORDERED_TASK))

TEST_PLANES_SOURCES = \
	$(SRC)/Plane/PlaneFileGlue.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Util/UTF8.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestPlanes.cpp
TEST_PLANES_DEPENDS = MATH IO
$(eval $(call link-program,TestPlanes,TEST_PLANES))

TEST_ZEROFINDER_SOURCES = \
	$(ENGINE_SRC_DIR)/Util/ZeroFinder.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestZeroFinder.cpp
TEST_ZEROFINDER_DEPENDS = MATH IO
$(eval $(call link-program,TestZeroFinder,TEST_ZEROFINDER))

TEST_TASKPOINT_SOURCES = \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(ENGINE_SRC_DIR)/Navigation/GeoPoint.cpp \
	$(ENGINE_SRC_DIR)/Navigation/Geometry/GeoVector.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestTaskPoint.cpp
TEST_TASKPOINT_DEPENDS = MATH IO
$(eval $(call link-program,TestTaskPoint,TEST_TASKPOINT))

TEST_TASKWAYPOINT_SOURCES = \
	$(SRC)/Util/UTF8.cpp \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(ENGINE_SRC_DIR)/Navigation/GeoPoint.cpp \
	$(ENGINE_SRC_DIR)/Navigation/Geometry/GeoVector.cpp \
	$(ENGINE_SRC_DIR)/Navigation/TaskProjection.cpp \
	$(ENGINE_SRC_DIR)/Waypoint/Waypoint.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestTaskWaypoint.cpp
TEST_TASKWAYPOINT_DEPENDS = MATH IO
$(eval $(call link-program,TestTaskWaypoint,TEST_TASKWAYPOINT))

TEST_TROUTE_SOURCES = \
	$(SRC)/XML/Node.cpp \
	$(SRC)/Terrain/RasterTile.cpp \
	$(SRC)/Terrain/RasterTileCache.cpp \
	$(SRC)/Terrain/RasterMap.cpp \
	$(SRC)/Terrain/RasterBuffer.cpp \
	$(SRC)/Terrain/RasterProjection.cpp \
	$(SRC)/Geo/GeoClip.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(TEST_SRC_DIR)/test_troute.cpp
TEST_TROUTE_DEPENDS = TEST1 JASPER
$(eval $(call link-program,test_troute,TEST_TROUTE))

TEST_REACH_SOURCES = \
	$(SRC)/XML/Node.cpp \
	$(SRC)/Terrain/RasterTile.cpp \
	$(SRC)/Terrain/RasterTileCache.cpp \
	$(SRC)/Terrain/RasterMap.cpp \
	$(SRC)/Terrain/RasterBuffer.cpp \
	$(SRC)/Terrain/RasterProjection.cpp \
	$(SRC)/Geo/GeoClip.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(TEST_SRC_DIR)/test_reach.cpp
TEST_REACH_DEPENDS = TEST1 JASPER
$(eval $(call link-program,test_reach,TEST_REACH))

TEST_ROUTE_SOURCES = \
	$(SRC)/NMEA/FlyingState.cpp \
	$(SRC)/XML/Node.cpp \
	$(SRC)/Terrain/RasterTile.cpp \
	$(SRC)/Terrain/RasterTileCache.cpp \
	$(SRC)/Terrain/RasterMap.cpp \
	$(SRC)/Terrain/RasterBuffer.cpp \
	$(SRC)/Terrain/RasterProjection.cpp \
	$(SRC)/Formatter/AirspaceFormatter.cpp \
	$(SRC)/Geo/GeoClip.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(TEST_SRC_DIR)/test_route.cpp
TEST_ROUTE_DEPENDS = TEST1 JASPER
$(eval $(call link-program,test_route,TEST_ROUTE))

TEST_REPLAY_TASK_SOURCES = \
	$(SRC)/NMEA/FlyingState.cpp \
	$(SRC)/XML/Node.cpp \
	$(SRC)/XML/Parser.cpp \
	$(SRC)/XML/Writer.cpp \
	$(SRC)/Formatter/AirspaceFormatter.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(TEST_SRC_DIR)/test_replay_task.cpp
TEST_REPLAY_TASK_DEPENDS = TEST1
$(eval $(call link-program,test_replay_task,TEST_REPLAY_TASK))

TEST_MATH_TABLES_SOURCES = \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestMathTables.cpp
TEST_MATH_TABLES_DEPENDS = MATH
$(eval $(call link-program,TestMathTables,TEST_MATH_TABLES))

TEST_LOAD_TASK_SOURCES = \
	$(SRC)/XML/Node.cpp \
	$(SRC)/XML/Parser.cpp \
	$(SRC)/XML/Writer.cpp \
	$(SRC)/Formatter/AirspaceFormatter.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(TEST_SRC_DIR)/test_load_task.cpp
TEST_LOAD_TASK_DEPENDS = TEST1
$(eval $(call link-program,test_load_task,TEST_LOAD_TASK))

TEST_ANGLE_SOURCES = \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestAngle.cpp
TEST_ANGLE_DEPENDS = MATH
$(eval $(call link-program,TestAngle,TEST_ANGLE))

TEST_CSV_LINE_SOURCES = \
	$(SRC)/IO/CSVLine.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestCSVLine.cpp
TEST_CSV_LINE_DEPENDS = MATH
$(eval $(call link-program,TestCSVLine,TEST_CSV_LINE))

TEST_GEO_BOUNDS_SOURCES = \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestGeoBounds.cpp
TEST_GEO_BOUNDS_DEPENDS = MATH
$(eval $(call link-program,TestGeoBounds,TEST_GEO_BOUNDS))

TEST_FLARM_NET_SOURCES = \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Util/UTF8.cpp \
	$(SRC)/FLARM/FlarmNet.cpp \
	$(SRC)/FLARM/FlarmNetReader.cpp \
	$(SRC)/FLARM/FlarmId.cpp \
	$(SRC)/FLARM/Record.cpp \
	$(SRC)/FLARM/Database.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestFlarmNet.cpp
TEST_FLARM_NET_DEPENDS = MATH IO
$(eval $(call link-program,TestFlarmNet,TEST_FLARM_NET))

TEST_GEO_CLIP_SOURCES = \
	$(SRC)/Geo/GeoClip.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestGeoClip.cpp
TEST_GEO_CLIP_DEPENDS = MATH
$(eval $(call link-program,TestGeoClip,TEST_GEO_CLIP))

TEST_CLIMB_AV_CALC_SOURCES = \
	$(SRC)/ClimbAverageCalculator.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestClimbAvCalc.cpp
TEST_CLIMB_AV_CALC_DEPENDS = MATH
$(eval $(call link-program,TestClimbAvCalc,TEST_CLIMB_AV_CALC))

TEST_PROJECTION_SOURCES = \
	$(SRC)/Projection/Projection.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestProjection.cpp
TEST_PROJECTION_DEPENDS = MATH
TEST_PROJECTION_CPPFLAGS = $(SCREEN_CPPFLAGS)
$(eval $(call link-program,TestProjection,TEST_PROJECTION))

TEST_UNITS_SOURCES = \
	$(SRC)/Units/Units.cpp \
	$(SRC)/Units/Settings.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestUnits.cpp
TEST_UNITS_DEPENDS = MATH
$(eval $(call link-program,TestUnits,TEST_UNITS))

TEST_UNITS_FORMATTER_SOURCES = \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Formatter/Units.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestUnitsFormatter.cpp
TEST_UNITS_FORMATTER_DEPENDS = MATH
$(eval $(call link-program,TestUnitsFormatter,TEST_UNITS_FORMATTER))

TEST_GEO_POINT_FORMATTER_SOURCES = \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Formatter/GeoPointFormatter.cpp \
	$(SRC)/Geo/UTM.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestGeoPointFormatter.cpp
TEST_GEO_POINT_FORMATTER_DEPENDS = MATH
$(eval $(call link-program,TestGeoPointFormatter,TEST_GEO_POINT_FORMATTER))

TEST_HEX_COLOR_FORMATTER_SOURCES = \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Formatter/HexColor.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestHexColorFormatter.cpp
TEST_HEX_COLOR_FORMATTER_DEPENDS = MATH SCREEN
$(eval $(call link-program,TestHexColorFormatter,TEST_HEX_COLOR_FORMATTER))

TEST_BYTE_SIZE_FORMATTER_SOURCES = \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Formatter/ByteSizeFormatter.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestByteSizeFormatter.cpp
TEST_BYTE_SIZE_FORMATTER_DEPENDS = MATH
$(eval $(call link-program,TestByteSizeFormatter,TEST_BYTE_SIZE_FORMATTER))

TEST_TIME_FORMATTER_SOURCES = \
	$(SRC)/DateTime.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Formatter/TimeFormatter.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestTimeFormatter.cpp
TEST_TIME_FORMATTER_DEPENDS = MATH
$(eval $(call link-program,TestTimeFormatter,TEST_TIME_FORMATTER))

TEST_IGC_FILENAME_FORMATTER_SOURCES = \
	$(SRC)/DateTime.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Formatter/IGCFilenameFormatter.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestIGCFilenameFormatter.cpp
TEST_IGC_FILENAME_FORMATTER_DEPENDS = MATH
$(eval $(call link-program,TestIGCFilenameFormatter,TEST_IGC_FILENAME_FORMATTER))

TEST_STRINGS_SOURCES = \
	$(SRC)/Util/StringUtil.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestStrings.cpp
$(eval $(call link-program,TestStrings,TEST_STRINGS))

TEST_POLARS_SOURCES = \
	$(SRC)/Util/UTF8.cpp \
	$(SRC)/Profile/ProfileKeys.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Polar/Polar.cpp \
	$(ENGINE_SRC_DIR)/GlideSolvers/PolarCoefficients.cpp \
	$(ENGINE_SRC_DIR)/GlideSolvers/GlidePolar.cpp \
	$(ENGINE_SRC_DIR)/GlideSolvers/GlideResult.cpp \
	$(ENGINE_SRC_DIR)/Util/ZeroFinder.cpp \
	$(SRC)/Polar/PolarFileGlue.cpp \
	$(SRC)/Polar/PolarStore.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestPolars.cpp
TEST_POLARS_DEPENDS = MATH IO
$(eval $(call link-program,TestPolars,TEST_POLARS))

TEST_GLIDE_POLAR_SOURCES = \
	$(ENGINE_SRC_DIR)/GlideSolvers/GlidePolar.cpp \
	$(ENGINE_SRC_DIR)/GlideSolvers/PolarCoefficients.cpp \
	$(ENGINE_SRC_DIR)/GlideSolvers/GlideResult.cpp \
	$(ENGINE_SRC_DIR)/GlideSolvers/GlideState.cpp \
	$(ENGINE_SRC_DIR)/GlideSolvers/MacCready.cpp \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(ENGINE_SRC_DIR)/Navigation/GeoPoint.cpp \
	$(ENGINE_SRC_DIR)/Navigation/Geometry/GeoVector.cpp \
	$(ENGINE_SRC_DIR)/Util/ZeroFinder.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestGlidePolar.cpp
TEST_GLIDE_POLAR_DEPENDS = MATH IO
$(eval $(call link-program,TestGlidePolar,TEST_GLIDE_POLAR))

TEST_FILE_UTIL_SOURCES = \
	$(SRC)/OS/FileUtil.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestFileUtil.cpp
$(eval $(call link-program,TestFileUtil,TEST_FILE_UTIL))

TEST_GEO_POINT_SOURCES = \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(ENGINE_SRC_DIR)/Navigation/GeoPoint.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestGeoPoint.cpp
TEST_GEO_POINT_DEPENDS = MATH
$(eval $(call link-program,TestGeoPoint,TEST_GEO_POINT))

TEST_DIFF_FILTER_SOURCES = \
	$(ENGINE_SRC_DIR)/Util/DiffFilter.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestDiffFilter.cpp
TEST_DIFF_FILTER_DEPENDS = MATH
$(eval $(call link-program,TestDiffFilter,TEST_DIFF_FILTER))

TEST_FLAT_POINT_SOURCES = \
	$(ENGINE_SRC_DIR)/Navigation/Flat/FlatPoint.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestFlatPoint.cpp
TEST_FLAT_POINT_DEPENDS = MATH
$(eval $(call link-program,TestFlatPoint,TEST_FLAT_POINT))

TEST_FLAT_GEO_POINT_SOURCES = \
	$(ENGINE_SRC_DIR)/Navigation/Flat/FlatGeoPoint.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestFlatGeoPoint.cpp
TEST_FLAT_GEO_POINT_DEPENDS = MATH
$(eval $(call link-program,TestFlatGeoPoint,TEST_FLAT_GEO_POINT))

TEST_FLAT_LINE_SOURCES = \
	$(ENGINE_SRC_DIR)/Navigation/Flat/FlatPoint.cpp \
	$(ENGINE_SRC_DIR)/Navigation/Flat/FlatLine.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestFlatLine.cpp
TEST_FLAT_LINE_DEPENDS = MATH
$(eval $(call link-program,TestFlatLine,TEST_FLAT_LINE))

TEST_THERMALBASE_SOURCES = \
	$(SRC)/Computer/ThermalBase.cpp \
	$(SRC)/Poco/RWLock.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestThermalBase.cpp \
	$(TEST_SRC_DIR)/FakeTerrain.cpp
TEST_THERMALBASE_DEPENDS = MATH
$(eval $(call link-program,TestThermalBase,TEST_THERMALBASE))

TEST_EARTH_SOURCES = \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestEarth.cpp
TEST_EARTH_DEPENDS = MATH
$(eval $(call link-program,TestEarth,TEST_EARTH))

TEST_COLOR_RAMP_SOURCES = \
	$(SRC)/Screen/Ramp.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestColorRamp.cpp
TEST_COLOR_RAMP_CPPFLAGS = $(SCREEN_CPPFLAGS)
$(eval $(call link-program,TestColorRamp,TEST_COLOR_RAMP))

TEST_SUN_EPHEMERIS_SOURCES = \
	$(SRC)/Math/SunEphemeris.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestSunEphemeris.cpp
TEST_SUN_EPHEMERIS_DEPENDS = MATH
$(eval $(call link-program,TestSunEphemeris,TEST_SUN_EPHEMERIS))

TEST_UTM_SOURCES = \
	$(SRC)/Geo/UTM.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestUTM.cpp
TEST_UTM_DEPENDS = MATH
$(eval $(call link-program,TestUTM,TEST_UTM))

TEST_VALIDITY_SOURCES = \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestValidity.cpp
$(eval $(call link-program,TestValidity,TEST_VALIDITY))

TEST_RADIX_TREE_SOURCES = \
	$(SRC)/Util/StringUtil.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestRadixTree.cpp
$(eval $(call link-program,TestRadixTree,TEST_RADIX_TREE))

TEST_LOGGER_SOURCES = \
	$(SRC)/IGC/IGCWriter.cpp \
	$(SRC)/Logger/LoggerFRecord.cpp \
	$(SRC)/Logger/LoggerGRecord.cpp \
	$(SRC)/Logger/LoggerEPE.cpp \
	$(SRC)/Logger/MD5.cpp \
	$(SRC)/Version.cpp \
	$(SRC)/Util/UTF8.cpp \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(ENGINE_SRC_DIR)/Navigation/GeoPoint.cpp \
	$(ENGINE_SRC_DIR)/Navigation/Geometry/GeoVector.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestLogger.cpp
TEST_LOGGER_DEPENDS = IO MATH
$(eval $(call link-program,TestLogger,TEST_LOGGER))

TEST_DRIVER_SOURCES = \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Device/Port/NullPort.cpp \
	$(SRC)/Device/Parser.cpp \
	$(SRC)/Device/Internal.cpp \
	$(SRC)/Device/Declaration.cpp \
	$(SRC)/Device/Driver.cpp \
	$(SRC)/FLARM/Traffic.cpp \
	$(SRC)/FLARM/FlarmId.cpp \
	$(SRC)/FLARM/FlarmCalculations.cpp \
	$(SRC)/NMEA/Info.cpp \
	$(SRC)/NMEA/Attitude.cpp \
	$(SRC)/NMEA/Acceleration.cpp \
	$(SRC)/NMEA/ExternalSettings.cpp \
	$(SRC)/NMEA/InputLine.cpp \
	$(SRC)/NMEA/Checksum.cpp \
	$(SRC)/FLARM/State.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/IGC/IGCParser.cpp \
	$(SRC)/ClimbAverageCalculator.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ProxyOperationEnvironment.cpp \
	$(SRC)/Operation/NoCancelOperationEnvironment.cpp \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(ENGINE_SRC_DIR)/Navigation/GeoPoint.cpp \
	$(ENGINE_SRC_DIR)/Navigation/Geometry/GeoVector.cpp \
	$(ENGINE_SRC_DIR)/Navigation/TaskProjection.cpp \
	$(ENGINE_SRC_DIR)/Waypoint/Waypoint.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/FakeMessage.cpp \
	$(TEST_SRC_DIR)/FakeGeoid.cpp \
	$(TEST_SRC_DIR)/FakeVega.cpp \
	$(TEST_SRC_DIR)/TestDriver.cpp
TEST_DRIVER_DEPENDS = DRIVER MATH IO
$(eval $(call link-program,TestDriver,TEST_DRIVER))

TEST_WAY_POINT_FILE_SOURCES = \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Poco/RWLock.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Geo/UTM.cpp \
	$(SRC)/Waypoint/WaypointReaderBase.cpp \
	$(SRC)/Waypoint/WaypointReader.cpp \
	$(SRC)/Waypoint/WaypointReaderWinPilot.cpp \
	$(SRC)/Waypoint/WaypointReaderSeeYou.cpp \
	$(SRC)/Waypoint/WaypointReaderZander.cpp \
	$(SRC)/Waypoint/WaypointReaderFS.cpp \
	$(SRC)/Waypoint/WaypointReaderOzi.cpp \
	$(SRC)/Waypoint/WaypointReaderCompeGPS.cpp \
	$(SRC)/Waypoint/WaypointWriter.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/RadioFrequency.cpp \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(ENGINE_SRC_DIR)/Navigation/GeoPoint.cpp \
	$(ENGINE_SRC_DIR)/Navigation/TaskProjection.cpp \
	$(ENGINE_SRC_DIR)/Navigation/Flat/FlatGeoPoint.cpp \
	$(ENGINE_SRC_DIR)/Waypoint/Waypoint.cpp \
	$(ENGINE_SRC_DIR)/Waypoint/Waypoints.cpp \
	$(TEST_SRC_DIR)/FakeTerrain.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestWaypointReader.cpp
TEST_WAY_POINT_FILE_DEPENDS = MATH IO UTIL ZZIP
$(eval $(call link-program,TestWaypointReader,TEST_WAY_POINT_FILE))

TEST_TRACE_SOURCES = \
	$(TEST_SRC_DIR)/tap.c \
	$(SRC)/IGC/IGCParser.cpp \
	$(TEST_SRC_DIR)/FakeTerrain.cpp \
	$(TEST_SRC_DIR)/Printing.cpp \
	$(TEST_SRC_DIR)/TestTrace.cpp 
TEST_TRACE_DEPENDS = IO ENGINE MATH UTIL
$(eval $(call link-program,TestTrace,TEST_TRACE))

FLIGHT_TABLE_SOURCES = \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/IGC/IGCParser.cpp \
	$(ENGINE_SRC_DIR)/Navigation/GeoPoint.cpp \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(TEST_SRC_DIR)/FlightTable.cpp
FLIGHT_TABLE_DEPENDS = MATH IO UTIL
$(eval $(call link-program,FlightTable,FLIGHT_TABLE))

build-check: $(TESTS)

check: $(TESTS) | $(OUT)/test/dirstamp
	@$(NQ)echo "  TEST    $(notdir $(patsubst %$(TARGET_EXEEXT),%,$^))"
	$(Q)$(PERL) $(TEST_SRC_DIR)/testall.pl $(TESTS)

DEBUG_PROGRAM_NAMES = \
	test_reach \
	test_route \
	test_troute \
	TestTrace \
	FlightTable \
	RunTrace \
	RunOLCAnalysis \
	BenchmarkProjection \
	DumpTextFile DumpTextZip WriteTextFile RunTextWriter \
	DumpHexColor \
	RunXMLParser \
	ReadMO \
	ReadProfileString ReadProfileInt \
	WriteProfileString WriteProfileInt \
	RunMD5 \
	ReadGRecord VerifyGRecord AppendGRecord \
	AddChecksum \
	KeyCodeDumper \
	LoadTopography LoadTerrain \
	RunHeightMatrix \
	RunInputParser \
	RunWaypointParser RunAirspaceParser \
	ReadPort RunPortHandler \
	RunDeviceDriver RunDeclare RunFlightList RunDownloadFlight \
	CAI302Tool \
	lxn2igc \
	RunIGCWriter \
	RunFlightLogger \
	RunCirclingWind RunWindZigZag RunWindEKF \
	RunCanvas RunMapWindow \
	RunDialog RunListControl \
	RunTerminal \
	RunRenderOZ \
	RunWindArrowRenderer \
	RunHorizonRenderer \
	RunFinalGlideBarRenderer \
	RunProgressWindow \
	RunJobDialog \
	RunAnalysis \
	RunAirspaceWarningDialog \
	TestNotify \
	FeedNMEA \
	FeedVega EmulateDevice \
	DebugDisplay \
	RunVegaSettings \
	RunFlarmUtils \
	RunTCPListener \
	TaskInfo DumpTaskFile \
	IGC2NMEA

ifeq ($(TARGET),UNIX)
DEBUG_PROGRAM_NAMES += \
	FeedTCP \
	FeedFlyNetData
endif

ifeq ($(TARGET),PC)
DEBUG_PROGRAM_NAMES += FeedTCP \
  FeedFlyNetData
endif

ifeq ($(HAVE_NET),y)
DEBUG_PROGRAM_NAMES += DownloadFile RunDownloadToFile RunNOAADownloader RunLiveTrack24
endif

ifeq ($(HAVE_CE)$(findstring $(TARGET),ALTAIR),y)
DEBUG_PROGRAM_NAMES += TodayInstall
endif

DEBUG_PROGRAMS = $(call name-to-bin,$(DEBUG_PROGRAM_NAMES))

DEBUG_REPLAY_SOURCES = \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Device/Port/Port.cpp \
	$(SRC)/Device/Port/NullPort.cpp \
	$(SRC)/Device/Driver.cpp \
	$(SRC)/Device/Register.cpp \
	$(SRC)/Device/Parser.cpp \
	$(SRC)/Device/Internal.cpp \
	$(SRC)/IGC/IGCParser.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/ComputerSettings.cpp \
	$(SRC)/TeamCodeSettings.cpp \
	$(SRC)/Logger/Settings.cpp \
	$(SRC)/Tracking/TrackingSettings.cpp \
	$(ENGINE_SRC_DIR)/GlideSolvers/GlideSettings.cpp \
	$(ENGINE_SRC_DIR)/Airspace/AirspaceWarningConfig.cpp \
	$(SRC)/Airspace/AirspaceComputerSettings.cpp \
	$(SRC)/NMEA/InputLine.cpp \
	$(SRC)/NMEA/Info.cpp \
	$(SRC)/NMEA/MoreData.cpp \
	$(SRC)/NMEA/Attitude.cpp \
	$(SRC)/NMEA/Acceleration.cpp \
	$(SRC)/NMEA/ExternalSettings.cpp \
	$(SRC)/NMEA/Checksum.cpp \
	$(SRC)/NMEA/Derived.cpp \
	$(SRC)/NMEA/VarioInfo.cpp \
	$(SRC)/NMEA/ClimbInfo.cpp \
	$(SRC)/NMEA/ClimbHistory.cpp \
	$(SRC)/NMEA/CirclingInfo.cpp \
	$(SRC)/NMEA/ThermalBand.cpp \
	$(SRC)/NMEA/ThermalLocator.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ProxyOperationEnvironment.cpp \
	$(SRC)/Operation/NoCancelOperationEnvironment.cpp \
	$(SRC)/Engine/Navigation/TraceHistory.cpp \
	$(SRC)/FLARM/State.cpp \
	$(SRC)/FLARM/FlarmId.cpp \
	$(SRC)/FLARM/Traffic.cpp \
	$(SRC)/Computer/BasicComputer.cpp \
	$(SRC)/Computer/FlyingComputer.cpp \
	$(SRC)/Engine/Util/Filter.cpp \
	$(SRC)/Engine/Util/DiffFilter.cpp \
	$(SRC)/Engine/Util/ZeroFinder.cpp \
	$(SRC)/Engine/Math/Earth.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(SRC)/Engine/Navigation/Aircraft.cpp \
	$(SRC)/Engine/Navigation/GeoPoint.cpp \
	$(SRC)/Engine/Navigation/Geometry/GeoVector.cpp \
	$(SRC)/Engine/GlideSolvers/GlidePolar.cpp \
	$(SRC)/Engine/GlideSolvers/PolarCoefficients.cpp \
	$(SRC)/Engine/GlideSolvers/GlideResult.cpp \
	$(SRC)/Engine/Route/Config.cpp \
	$(SRC)/Engine/Task/TaskBehaviour.cpp \
	$(SRC)/Engine/Task/OrderedTaskBehaviour.cpp \
	$(SRC)/Engine/Task/TaskStats/TaskStats.cpp \
	$(SRC)/Engine/Task/TaskStats/CommonStats.cpp \
	$(SRC)/Engine/Task/TaskStats/ElementStat.cpp \
	$(SRC)/Engine/Task/TaskStats/DistanceStat.cpp \
	$(SRC)/Engine/Task/TaskStats/TaskVario.cpp \
	$(TEST_SRC_DIR)/FakeMessage.cpp \
	$(TEST_SRC_DIR)/FakeGeoid.cpp \
	$(TEST_SRC_DIR)/FakeVega.cpp \
	$(TEST_SRC_DIR)/DebugReplay.cpp
DEBUG_REPLAY_LDADD = \
	$(DRIVER_LDADD) \
	$(IO_LIBS)

BENCHMARK_PROJECTION_SOURCES = \
	$(SRC)/Projection/Projection.cpp \
	$(TEST_SRC_DIR)/BenchmarkProjection.cpp
BENCHMARK_PROJECTION_DEPENDS = MATH
BENCHMARK_PROJECTION_CPPFLAGS = $(SCREEN_CPPFLAGS)
$(eval $(call link-program,BenchmarkProjection,BENCHMARK_PROJECTION))

DUMP_TEXT_FILE_SOURCES = \
	$(SRC)/Util/UTF8.cpp \
	$(TEST_SRC_DIR)/DumpTextFile.cpp
DUMP_TEXT_FILE_DEPENDS = IO ZZIP
$(eval $(call link-program,DumpTextFile,DUMP_TEXT_FILE))

DUMP_TEXT_ZIP_SOURCES = \
	$(SRC)/Util/UTF8.cpp \
	$(TEST_SRC_DIR)/DumpTextZip.cpp
DUMP_TEXT_ZIP_DEPENDS = IO ZZIP
$(eval $(call link-program,DumpTextZip,DUMP_TEXT_ZIP))

DUMP_HEX_COLOR_SOURCES = \
	$(SRC)/Formatter/HexColor.cpp \
	$(TEST_SRC_DIR)/DumpHexColor.cpp
DUMP_HEX_COLOR_DEPENDS = SCREEN
$(eval $(call link-program,DumpHexColor,DUMP_HEX_COLOR))

DEBUG_DISPLAY_SOURCES = \
	$(SRC)/Hardware/Display.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/DebugDisplay.cpp
DEBUG_DISPLAY_DEPENDS = IO
$(eval $(call link-program,DebugDisplay,DEBUG_DISPLAY))

WRITE_TEXT_FILE_SOURCES = \
	$(TEST_SRC_DIR)/WriteTextFile.cpp
WRITE_TEXT_FILE_DEPENDS = IO ZZIP
$(eval $(call link-program,WriteTextFile,WRITE_TEXT_FILE))

RUN_TEXT_WRITER_SOURCES = \
	$(TEST_SRC_DIR)/RunTextWriter.cpp
RUN_TEXT_WRITER_DEPENDS = IO ZZIP
$(eval $(call link-program,RunTextWriter,RUN_TEXT_WRITER))

DOWNLOAD_FILE_SOURCES = \
	$(SRC)/Version.cpp \
	$(TEST_SRC_DIR)/DownloadFile.cpp
DOWNLOAD_FILE_DEPENDS = IO LIBNET
$(eval $(call link-program,DownloadFile,DOWNLOAD_FILE))

RUN_DOWNLOAD_TO_FILE_SOURCES = \
	$(SRC)/Version.cpp \
	$(SRC)/Net/ToFile.cpp \
	$(SRC)/Logger/MD5.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(TEST_SRC_DIR)/RunDownloadToFile.cpp
RUN_DOWNLOAD_TO_FILE_DEPENDS = LIBNET
$(eval $(call link-program,RunDownloadToFile,RUN_DOWNLOAD_TO_FILE))

RUN_NOAA_DOWNLOADER_SOURCES = \
	$(SRC)/Version.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Weather/NOAADownloader.cpp \
	$(SRC)/Weather/NOAAStore.cpp \
	$(SRC)/Weather/METARParser.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(SRC)/Formatter/GeoPointFormatter.cpp \
	$(SRC)/Formatter/Units.cpp \
	$(SRC)/Formatter/UserUnits.cpp \
	$(SRC)/Units/Units.cpp \
	$(SRC)/Units/Settings.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/DateTime.cpp \
	$(SRC)/Geo/UTM.cpp \
	$(SRC)/Net/ToBuffer.cpp \
	$(TEST_SRC_DIR)/ConsoleJobRunner.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(TEST_SRC_DIR)/RunNOAADownloader.cpp
RUN_NOAA_DOWNLOADER_DEPENDS = IO MATH LIBNET
$(eval $(call link-program,RunNOAADownloader,RUN_NOAA_DOWNLOADER))

RUN_LIVETRACK24_SOURCES = \
	$(DEBUG_REPLAY_SOURCES) \
	$(SRC)/Tracking/LiveTrack24.cpp \
	$(SRC)/Version.cpp \
	$(SRC)/DateTime.cpp \
	$(SRC)/Net/ToBuffer.cpp \
	$(SRC)/Units/Units.cpp \
	$(SRC)/Units/Settings.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(TEST_SRC_DIR)/RunLiveTrack24.cpp
RUN_LIVETRACK24_LDADD = $(DEBUG_REPLAY_LDADD)
RUN_LIVETRACK24_DEPENDS = LIBNET MATH UTIL
$(eval $(call link-program,RunLiveTrack24,RUN_LIVETRACK24))

RUN_XML_PARSER_SOURCES = \
	$(SRC)/Util/UTF8.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/XML/Node.cpp \
	$(SRC)/XML/Parser.cpp \
	$(SRC)/XML/Writer.cpp \
	$(TEST_SRC_DIR)/RunXMLParser.cpp
RUN_XML_PARSER_DEPENDS = IO
$(eval $(call link-program,RunXMLParser,RUN_XML_PARSER))

READ_MO_SOURCES = \
	$(SRC)/Language/MOFile.cpp \
	$(SRC)/OS/FileMapping.cpp \
	$(TEST_SRC_DIR)/ReadMO.cpp
$(eval $(call link-program,ReadMO,READ_MO))

READ_PROFILE_STRING_SOURCES = \
	$(SRC)/LocalPath.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Profile/Profile.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/ReadProfileString.cpp
READ_PROFILE_STRING_DEPENDS = PROFILE IO UTIL
$(eval $(call link-program,ReadProfileString,READ_PROFILE_STRING))

READ_PROFILE_INT_SOURCES = \
	$(SRC)/LocalPath.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Profile/Profile.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/ReadProfileInt.cpp
READ_PROFILE_INT_DEPENDS = PROFILE IO UTIL
$(eval $(call link-program,ReadProfileInt,READ_PROFILE_INT))

WRITE_PROFILE_STRING_SOURCES = \
	$(SRC)/LocalPath.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Profile/Profile.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/WriteProfileString.cpp
WRITE_PROFILE_STRING_DEPENDS = PROFILE IO UTIL
$(eval $(call link-program,WriteProfileString,WRITE_PROFILE_STRING))

WRITE_PROFILE_INT_SOURCES = \
	$(SRC)/LocalPath.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Profile/Profile.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/WriteProfileInt.cpp
WRITE_PROFILE_INT_DEPENDS = PROFILE IO UTIL
$(eval $(call link-program,WriteProfileInt,WRITE_PROFILE_INT))

RUN_MD5_SOURCES = \
	$(SRC)/Logger/MD5.cpp \
	$(TEST_SRC_DIR)/RunMD5.cpp
$(eval $(call link-program,RunMD5,RUN_MD5))

READ_GRECORD_SOURCES = \
	$(SRC)/Logger/LoggerGRecord.cpp \
	$(SRC)/Logger/MD5.cpp \
	$(SRC)/Util/UTF8.cpp \
	$(TEST_SRC_DIR)/ReadGRecord.cpp
READ_GRECORD_DEPENDS = IO
$(eval $(call link-program,ReadGRecord,READ_GRECORD))

VERIFY_GRECORD_SOURCES = \
	$(SRC)/Logger/LoggerGRecord.cpp \
	$(SRC)/Logger/MD5.cpp \
	$(SRC)/Util/UTF8.cpp \
	$(TEST_SRC_DIR)/VerifyGRecord.cpp
VERIFY_GRECORD_DEPENDS = IO
$(eval $(call link-program,VerifyGRecord,VERIFY_GRECORD))

APPEND_GRECORD_SOURCES = \
	$(SRC)/Logger/LoggerGRecord.cpp \
	$(SRC)/Logger/MD5.cpp \
	$(SRC)/Util/UTF8.cpp \
	$(TEST_SRC_DIR)/AppendGRecord.cpp
APPEND_GRECORD_DEPENDS = IO
$(eval $(call link-program,AppendGRecord,APPEND_GRECORD))

ADD_CHECKSUM_SOURCES = \
	$(TEST_SRC_DIR)/AddChecksum.cpp
ADD_CHECKSUM_DEPENDS = IO
$(eval $(call link-program,AddChecksum,ADD_CHECKSUM))

KEY_CODE_DUMPER_SOURCES = \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Compatibility/fmode.c \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/KeyCodeDumper.cpp
KEY_CODE_DUMPER_LDADD = $(FAKE_LIBS)
KEY_CODE_DUMPER_DEPENDS = SCREEN MATH
$(eval $(call link-program,KeyCodeDumper,KEY_CODE_DUMPER))

LOAD_TOPOGRAPHY_SOURCES = \
	$(SRC)/Topography/TopographyStore.cpp \
	$(SRC)/Topography/TopographyFile.cpp \
	$(SRC)/Topography/XShape.cpp \
	$(SRC)/Projection/Projection.cpp \
	$(SRC)/Projection/WindowProjection.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(TEST_SRC_DIR)/LoadTopography.cpp
LOAD_TOPOGRAPHY_DEPENDS = MATH IO UTIL SHAPELIB ZZIP
LOAD_TOPOGRAPHY_CPPFLAGS = $(SCREEN_CPPFLAGS)
$(eval $(call link-program,LoadTopography,LOAD_TOPOGRAPHY))

LOAD_TERRAIN_SOURCES = \
	$(SRC)/Terrain/RasterTile.cpp \
	$(SRC)/Terrain/RasterTileCache.cpp \
	$(SRC)/Terrain/RasterBuffer.cpp \
	$(SRC)/Terrain/RasterProjection.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Engine/Math/Earth.cpp \
	$(SRC)/Engine/Navigation/GeoPoint.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Util/UTF8.cpp \
	$(TEST_SRC_DIR)/LoadTerrain.cpp
LOAD_TERRAIN_CPPFLAGS = $(SCREEN_CPPFLAGS)
LOAD_TERRAIN_DEPENDS = MATH IO JASPER ZZIP
$(eval $(call link-program,LoadTerrain,LOAD_TERRAIN))

RUN_HEIGHT_MATRIX_SOURCES = \
	$(SRC)/Terrain/RasterTile.cpp \
	$(SRC)/Terrain/RasterTileCache.cpp \
	$(SRC)/Terrain/RasterBuffer.cpp \
	$(SRC)/Terrain/RasterProjection.cpp \
	$(SRC)/Terrain/RasterMap.cpp \
	$(SRC)/Terrain/HeightMatrix.cpp \
	$(SRC)/Geo/GeoClip.cpp \
	$(SRC)/Projection/Projection.cpp \
	$(SRC)/Projection/WindowProjection.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Engine/Math/Earth.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Util/UTF8.cpp \
	$(ENGINE_SRC_DIR)/Navigation/GeoPoint.cpp \
	$(TEST_SRC_DIR)/RunHeightMatrix.cpp
RUN_HEIGHT_MATRIX_CPPFLAGS = $(SCREEN_CPPFLAGS)
RUN_HEIGHT_MATRIX_DEPENDS = MATH IO JASPER ZZIP
$(eval $(call link-program,RunHeightMatrix,RUN_HEIGHT_MATRIX))

RUN_INPUT_PARSER_SOURCES = \
	$(SRC)/Input/InputKeys.cpp \
	$(SRC)/Input/InputConfig.cpp \
	$(SRC)/Input/InputParser.cpp \
	$(SRC)/Menu/MenuData.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/RunInputParser.cpp
RUN_INPUT_PARSER_DEPENDS = IO UTIL
$(eval $(call link-program,RunInputParser,RUN_INPUT_PARSER))

RUN_WAY_POINT_PARSER_SOURCES = \
	$(SRC)/Geo/UTM.cpp \
	$(SRC)/Waypoint/WaypointReaderBase.cpp \
	$(SRC)/Waypoint/WaypointReader.cpp \
	$(SRC)/Waypoint/WaypointReaderWinPilot.cpp \
	$(SRC)/Waypoint/WaypointReaderFS.cpp \
	$(SRC)/Waypoint/WaypointReaderOzi.cpp \
	$(SRC)/Waypoint/WaypointReaderSeeYou.cpp \
	$(SRC)/Waypoint/WaypointReaderZander.cpp \
	$(SRC)/Waypoint/WaypointReaderCompeGPS.cpp \
	$(SRC)/Waypoint/WaypointWriter.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Poco/RWLock.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Compatibility/fmode.c \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/RadioFrequency.cpp \
	$(TEST_SRC_DIR)/FakeTerrain.cpp \
	$(TEST_SRC_DIR)/RunWaypointParser.cpp
RUN_WAY_POINT_PARSER_LDADD = $(FAKE_LIBS)
RUN_WAY_POINT_PARSER_DEPENDS = ENGINE IO ZZIP MATH UTIL
$(eval $(call link-program,RunWaypointParser,RUN_WAY_POINT_PARSER))

RUN_AIRSPACE_PARSER_SOURCES = \
	$(SRC)/Airspace/AirspaceParser.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(TEST_SRC_DIR)/FakeDialogs.cpp \
	$(TEST_SRC_DIR)/FakeTerrain.cpp \
	$(TEST_SRC_DIR)/FakeLanguage.cpp \
	$(TEST_SRC_DIR)/RunAirspaceParser.cpp
RUN_AIRSPACE_PARSER_LDADD = $(FAKE_LIBS)
RUN_AIRSPACE_PARSER_DEPENDS = ENGINE IO ZZIP MATH UTIL
$(eval $(call link-program,RunAirspaceParser,RUN_AIRSPACE_PARSER))

READ_PORT_SOURCES = \
	$(SRC)/Device/Port/ConfiguredPort.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/OS/LogError.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/DebugPort.cpp \
	$(TEST_SRC_DIR)/ReadPort.cpp
READ_PORT_DEPENDS = PORT UTIL
$(eval $(call link-program,ReadPort,READ_PORT))

RUN_PORT_HANDLER_SOURCES = \
	$(SRC)/Device/Port/ConfiguredPort.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/OS/LogError.cpp \
	$(SRC)/OS/Clock.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/DebugPort.cpp \
	$(TEST_SRC_DIR)/RunPortHandler.cpp
RUN_PORT_HANDLER_DEPENDS = PORT UTIL
$(eval $(call link-program,RunPortHandler,RUN_PORT_HANDLER))

RUN_TCP_LISTENER_SOURCES = \
	$(SRC)/Device/Port/Port.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Device/Port/TCPPort.cpp \
	$(TEST_SRC_DIR)/RunTCPListener.cpp

ifeq ($(HAVE_POSIX),n)
ifeq ($(HAVE_CE),y)
RUN_TCP_LISTENER_LDLIBS += -lwinsock
else
RUN_TCP_LISTENER_LDLIBS += -lws2_32
endif
endif

$(eval $(call link-program,RunTCPListener,RUN_TCP_LISTENER))

RUN_DEVICE_DRIVER_SOURCES = \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/FLARM/FlarmId.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Device/Port/Port.cpp \
	$(SRC)/Device/Port/NullPort.cpp \
	$(SRC)/Device/Driver.cpp \
	$(SRC)/Device/Register.cpp \
	$(SRC)/Device/Parser.cpp \
	$(SRC)/Device/Internal.cpp \
	$(SRC)/FLARM/State.cpp \
	$(SRC)/FLARM/Traffic.cpp \
	$(SRC)/NMEA/Info.cpp \
	$(SRC)/NMEA/Acceleration.cpp \
	$(SRC)/NMEA/Attitude.cpp \
	$(SRC)/NMEA/ExternalSettings.cpp \
	$(SRC)/NMEA/InputLine.cpp \
	$(SRC)/NMEA/Checksum.cpp \
	$(SRC)/IGC/IGCParser.cpp \
	$(SRC)/FLARM/FlarmCalculations.cpp \
	$(SRC)/ClimbAverageCalculator.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ProxyOperationEnvironment.cpp \
	$(SRC)/Operation/NoCancelOperationEnvironment.cpp \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(TEST_SRC_DIR)/FakeMessage.cpp \
	$(TEST_SRC_DIR)/FakeGeoid.cpp \
	$(TEST_SRC_DIR)/FakeVega.cpp \
	$(TEST_SRC_DIR)/RunDeviceDriver.cpp
RUN_DEVICE_DRIVER_DEPENDS = DRIVER MATH UTIL IO
$(eval $(call link-program,RunDeviceDriver,RUN_DEVICE_DRIVER))

RUN_DECLARE_SOURCES = \
	$(SRC)/Device/Port/ConfiguredPort.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Device/Driver.cpp \
	$(SRC)/Device/Register.cpp \
	$(SRC)/Device/Internal.cpp \
	$(SRC)/Device/Declaration.cpp \
	$(SRC)/NMEA/InputLine.cpp \
	$(SRC)/NMEA/Checksum.cpp \
	$(SRC)/NMEA/ExternalSettings.cpp \
	$(SRC)/IGC/IGCParser.cpp \
	$(SRC)/OS/LogError.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ProxyOperationEnvironment.cpp \
	$(SRC)/Operation/NoCancelOperationEnvironment.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(TEST_SRC_DIR)/FakeLanguage.cpp \
	$(TEST_SRC_DIR)/FakeGeoid.cpp \
	$(TEST_SRC_DIR)/FakeMessage.cpp \
	$(TEST_SRC_DIR)/FakeDialogs.cpp \
	$(TEST_SRC_DIR)/FakeVega.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/DebugPort.cpp \
	$(TEST_SRC_DIR)/RunDeclare.cpp
RUN_DECLARE_DEPENDS = DRIVER PORT ENGINE MATH UTIL IO
$(eval $(call link-program,RunDeclare,RUN_DECLARE))

RUN_VEGA_SETTINGS_SOURCES = \
	$(VEGA_SOURCES) \
	$(SRC)/Device/Driver.cpp \
	$(SRC)/Device/Internal.cpp \
	$(SRC)/Device/Port/ConfiguredPort.cpp \
	$(SRC)/NMEA/InputLine.cpp \
	$(SRC)/NMEA/ExternalSettings.cpp \
	$(SRC)/OS/LogError.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(TEST_SRC_DIR)/FakeVega.cpp \
	$(TEST_SRC_DIR)/FakeMessage.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/DebugPort.cpp \
	$(TEST_SRC_DIR)/RunVegaSettings.cpp
RUN_VEGA_SETTINGS_DEPENDS = PORT MATH UTIL IO
$(eval $(call link-program,RunVegaSettings,RUN_VEGA_SETTINGS))

RUN_FLARM_UTILS_SOURCES = \
	$(SRC)/Device/Port/ConfiguredPort.cpp \
	$(SRC)/Device/Driver.cpp \
	$(SRC)/Device/Internal.cpp \
	$(SRC)/Device/Declaration.cpp \
	$(SRC)/OS/LogError.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(SRC)/NMEA/InputLine.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/DebugPort.cpp \
	$(TEST_SRC_DIR)/RunFlarmUtils.cpp
RUN_FLARM_UTILS_DEPENDS = DRIVER PORT ENGINE MATH UTIL IO
$(eval $(call link-program,RunFlarmUtils,RUN_FLARM_UTILS))

RUN_FLIGHT_LIST_SOURCES = \
	$(SRC)/Device/Port/ConfiguredPort.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Device/Driver.cpp \
	$(SRC)/Device/Register.cpp \
	$(SRC)/Device/Internal.cpp \
	$(SRC)/Device/Declaration.cpp \
	$(SRC)/NMEA/InputLine.cpp \
	$(SRC)/NMEA/Checksum.cpp \
	$(SRC)/NMEA/ExternalSettings.cpp \
	$(SRC)/IGC/IGCParser.cpp \
	$(SRC)/OS/LogError.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ProxyOperationEnvironment.cpp \
	$(SRC)/Operation/NoCancelOperationEnvironment.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(TEST_SRC_DIR)/FakeLanguage.cpp \
	$(TEST_SRC_DIR)/FakeMessage.cpp \
	$(TEST_SRC_DIR)/FakeDialogs.cpp \
	$(TEST_SRC_DIR)/FakeVega.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/DebugPort.cpp \
	$(TEST_SRC_DIR)/RunFlightList.cpp
RUN_FLIGHT_LIST_DEPENDS = DRIVER PORT ENGINE MATH UTIL IO
$(eval $(call link-program,RunFlightList,RUN_FLIGHT_LIST))

RUN_DOWNLOAD_FLIGHT_SOURCES = \
	$(SRC)/Device/Port/ConfiguredPort.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Device/Driver.cpp \
	$(SRC)/Device/Register.cpp \
	$(SRC)/Device/Internal.cpp \
	$(SRC)/Device/Declaration.cpp \
	$(SRC)/NMEA/InputLine.cpp \
	$(SRC)/NMEA/Checksum.cpp \
	$(SRC)/NMEA/ExternalSettings.cpp \
	$(SRC)/IGC/IGCParser.cpp \
	$(SRC)/OS/LogError.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ProxyOperationEnvironment.cpp \
	$(SRC)/Operation/NoCancelOperationEnvironment.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(TEST_SRC_DIR)/FakeLanguage.cpp \
	$(TEST_SRC_DIR)/FakeMessage.cpp \
	$(TEST_SRC_DIR)/FakeDialogs.cpp \
	$(TEST_SRC_DIR)/FakeVega.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/DebugPort.cpp \
	$(TEST_SRC_DIR)/RunDownloadFlight.cpp
RUN_DOWNLOAD_FLIGHT_DEPENDS = DRIVER PORT ENGINE MATH UTIL IO
$(eval $(call link-program,RunDownloadFlight,RUN_DOWNLOAD_FLIGHT))

CAI302_TOOL_SOURCES = \
	$(SRC)/Device/Port/ConfiguredPort.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/NMEA/InputLine.cpp \
	$(SRC)/NMEA/Checksum.cpp \
	$(SRC)/NMEA/ExternalSettings.cpp \
	$(SRC)/Device/Driver.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ProxyOperationEnvironment.cpp \
	$(SRC)/Operation/NoCancelOperationEnvironment.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/OS/LogError.cpp \
	$(SRC)/OS/Clock.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/DebugPort.cpp \
	$(TEST_SRC_DIR)/CAI302Tool.cpp
CAI302_TOOL_DEPENDS = CAI302 PORT MATH IO UTIL
$(eval $(call link-program,CAI302Tool,CAI302_TOOL))

TEST_LXN_TO_IGC_SOURCES = \
	$(SRC)/Device/Driver/LX/Convert.cpp \
	$(SRC)/Device/Driver/LX/LXN.cpp \
	$(TEST_SRC_DIR)/tap.c \
	$(TEST_SRC_DIR)/TestLXNToIGC.cpp
TEST_LXN_TO_IGC_DEPENDS =
$(eval $(call link-program,TestLXNToIGC,TEST_LXN_TO_IGC))

LXN2IGC_SOURCES = \
	$(SRC)/Device/Driver/LX/Convert.cpp \
	$(SRC)/Device/Driver/LX/LXN.cpp \
	$(TEST_SRC_DIR)/lxn2igc.cpp
$(eval $(call link-program,lxn2igc,LXN2IGC))

RUN_IGC_WRITER_SOURCES = \
	$(DEBUG_REPLAY_SOURCES) \
	$(SRC)/Version.cpp \
	$(SRC)/FLARM/FlarmCalculations.cpp \
	$(SRC)/ClimbAverageCalculator.cpp \
	$(SRC)/IGC/IGCWriter.cpp \
	$(SRC)/Logger/LoggerFRecord.cpp \
	$(SRC)/Logger/LoggerGRecord.cpp \
	$(SRC)/Logger/LoggerEPE.cpp \
	$(SRC)/Logger/MD5.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(TEST_SRC_DIR)/RunIGCWriter.cpp
RUN_IGC_WRITER_LDADD = $(DEBUG_REPLAY_LDADD)
RUN_IGC_WRITER_DEPENDS = MATH UTIL
$(eval $(call link-program,RunIGCWriter,RUN_IGC_WRITER))

RUN_FLIGHT_LOGGER_SOURCES = \
	$(DEBUG_REPLAY_SOURCES) \
	$(SRC)/Computer/CirclingComputer.cpp \
	$(SRC)/Logger/FlightLogger.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(TEST_SRC_DIR)/RunFlightLogger.cpp
RUN_FLIGHT_LOGGER_LDADD = $(DEBUG_REPLAY_LDADD)
RUN_FLIGHT_LOGGER_DEPENDS = MATH UTIL
$(eval $(call link-program,RunFlightLogger,RUN_FLIGHT_LOGGER))

RUN_CIRCLING_WIND_SOURCES = \
	$(DEBUG_REPLAY_SOURCES) \
	$(SRC)/Computer/CirclingComputer.cpp \
	$(SRC)/Wind/CirclingWind.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(TEST_SRC_DIR)/RunCirclingWind.cpp
RUN_CIRCLING_WIND_LDADD = $(DEBUG_REPLAY_LDADD)
RUN_CIRCLING_WIND_DEPENDS = MATH UTIL
$(eval $(call link-program,RunCirclingWind,RUN_CIRCLING_WIND))

RUN_WIND_ZIG_ZAG_SOURCES = \
	$(DEBUG_REPLAY_SOURCES) \
	$(SRC)/Wind/WindZigZag.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(TEST_SRC_DIR)/RunWindZigZag.cpp
RUN_WIND_ZIG_ZAG_LDADD = $(DEBUG_REPLAY_LDADD)
RUN_WIND_ZIG_ZAG_DEPENDS = MATH UTIL
$(eval $(call link-program,RunWindZigZag,RUN_WIND_ZIG_ZAG))

RUN_WIND_EKF_SOURCES = \
	$(DEBUG_REPLAY_SOURCES) \
	$(SRC)/Wind/WindEKF.cpp \
	$(SRC)/Wind/WindEKFGlue.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(TEST_SRC_DIR)/RunWindEKF.cpp
RUN_WIND_EKF_LDADD = $(DEBUG_REPLAY_LDADD)
RUN_WIND_EKF_DEPENDS = MATH UTIL
$(eval $(call link-program,RunWindEKF,RUN_WIND_EKF))

RUN_TRACE_SOURCES = \
	$(DEBUG_REPLAY_SOURCES) \
	$(SRC)/IGC/IGCParser.cpp \
	$(SRC)/NMEA/Aircraft.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(ENGINE_SRC_DIR)/GlideSolvers/GlideSettings.cpp \
	$(ENGINE_SRC_DIR)/Trace/Point.cpp \
	$(ENGINE_SRC_DIR)/Trace/Trace.cpp \
	$(ENGINE_SRC_DIR)/Navigation/Flat/FlatGeoPoint.cpp \
	$(ENGINE_SRC_DIR)/Navigation/TaskProjection.cpp \
	$(ENGINE_SRC_DIR)/Navigation/SearchPoint.cpp \
	$(TEST_SRC_DIR)/Printing.cpp \
	$(TEST_SRC_DIR)/RunTrace.cpp
RUN_TRACE_LDADD = $(DEBUG_REPLAY_LDADD)
RUN_TRACE_DEPENDS = UTIL MATH
$(eval $(call link-program,RunTrace,RUN_TRACE))

RUN_OLC_SOURCES = \
	$(DEBUG_REPLAY_SOURCES) \
	$(SRC)/IGC/IGCParser.cpp \
	$(SRC)/NMEA/Aircraft.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(ENGINE_SRC_DIR)/Navigation/SearchPoint.cpp \
	$(ENGINE_SRC_DIR)/Navigation/SearchPointVector.cpp \
	$(ENGINE_SRC_DIR)/Navigation/Flat/FlatGeoPoint.cpp \
	$(ENGINE_SRC_DIR)/Navigation/Flat/FlatRay.cpp \
	$(ENGINE_SRC_DIR)/Navigation/TaskProjection.cpp \
	$(ENGINE_SRC_DIR)/Navigation/ConvexHull/GrahamScan.cpp \
	$(ENGINE_SRC_DIR)/Navigation/ConvexHull/PolygonInterior.cpp \
	$(ENGINE_SRC_DIR)/Trace/Point.cpp \
	$(ENGINE_SRC_DIR)/Trace/Trace.cpp \
	$(ENGINE_SRC_DIR)/Contest/ContestManager.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/Contests.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/AbstractContest.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/ContestDijkstra.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/OLCLeague.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/OLCSprint.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/OLCClassic.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/OLCTriangle.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/OLCFAI.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/OLCPlus.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/XContestFree.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/XContestTriangle.cpp \
	$(ENGINE_SRC_DIR)/Contest/Solvers/OLCSISAT.cpp \
	$(TEST_SRC_DIR)/FakeTerrain.cpp \
	$(TEST_SRC_DIR)/Printing.cpp \
	$(TEST_SRC_DIR)/ContestPrinting.cpp \
	$(TEST_SRC_DIR)/RunOLCAnalysis.cpp
RUN_OLC_LDADD = $(DEBUG_REPLAY_LDADD)
RUN_OLC_DEPENDS = UTIL MATH
$(eval $(call link-program,RunOLCAnalysis,RUN_OLC))

RUN_CANVAS_SOURCES = \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Compatibility/fmode.c \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/RunCanvas.cpp
RUN_CANVAS_LDADD = $(FAKE_LIBS)
RUN_CANVAS_DEPENDS = SCREEN MATH
$(eval $(call link-program,RunCanvas,RUN_CANVAS))

RUN_MAP_WINDOW_SOURCES = \
	$(IO_SRC_DIR)/DataFile.cpp \
	$(IO_SRC_DIR)/ConfiguredFile.cpp \
	$(SRC)/DateTime.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Poco/RWLock.cpp \
	$(SRC)/NMEA/Info.cpp \
	$(SRC)/NMEA/MoreData.cpp \
	$(SRC)/NMEA/Acceleration.cpp \
	$(SRC)/NMEA/Attitude.cpp \
	$(SRC)/NMEA/ExternalSettings.cpp \
	$(SRC)/NMEA/ThermalLocator.cpp \
	$(SRC)/NMEA/Aircraft.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(SRC)/NMEA/Derived.cpp \
	$(SRC)/NMEA/VarioInfo.cpp \
	$(SRC)/NMEA/ClimbInfo.cpp \
	$(SRC)/NMEA/ClimbHistory.cpp \
	$(SRC)/NMEA/CirclingInfo.cpp \
	$(SRC)/NMEA/ThermalBand.cpp \
	$(SRC)/Engine/Navigation/TraceHistory.cpp \
	$(SRC)/FLARM/State.cpp \
	$(SRC)/Airspace/ProtectedAirspaceWarningManager.cpp \
	$(SRC)/Airspace/AirspaceParser.cpp \
	$(SRC)/Airspace/AirspaceVisibility.cpp \
	$(SRC)/Airspace/AirspaceComputerSettings.cpp \
	$(SRC)/Renderer/AirspaceRendererSettings.cpp \
	$(SRC)/Renderer/BackgroundRenderer.cpp \
	$(SRC)/LocalPath.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/Projection/Projection.cpp \
	$(SRC)/Projection/WindowProjection.cpp \
	$(SRC)/Projection/CompareProjection.cpp \
	$(SRC)/Geo/GeoClip.cpp \
	$(SRC)/MapWindow/MapWindow.cpp \
	$(SRC)/MapWindow/MapWindowBlackboard.cpp \
	$(SRC)/MapWindow/MapWindowEvents.cpp \
	$(SRC)/MapWindow/MapWindowGlideRange.cpp \
	$(SRC)/MapWindow/MapWindowLabels.cpp \
	$(SRC)/Projection/MapWindowProjection.cpp \
	$(SRC)/MapWindow/MapWindowRender.cpp \
	$(SRC)/MapWindow/MapWindowSymbols.cpp \
	$(SRC)/MapWindow/MapWindowTask.cpp \
	$(SRC)/MapWindow/MapWindowThermal.cpp \
	$(SRC)/MapWindow/MapWindowTimer.cpp \
	$(SRC)/MapWindow/MapWindowTraffic.cpp \
	$(SRC)/MapWindow/MapWindowTrail.cpp \
	$(SRC)/MapWindow/MapWindowWaypoints.cpp \
	$(SRC)/MapWindow/MapCanvas.cpp \
	$(SRC)/MapWindow/MapDrawHelper.cpp \
	$(SRC)/Renderer/OZRenderer.cpp \
	$(SRC)/Renderer/TaskRenderer.cpp \
	$(SRC)/Renderer/TaskPointRenderer.cpp \
	$(SRC)/Renderer/AircraftRenderer.cpp \
	$(SRC)/Renderer/AirspaceRenderer.cpp \
	$(SRC)/Renderer/BestCruiseArrowRenderer.cpp \
	$(SRC)/Renderer/CompassRenderer.cpp \
	$(SRC)/Renderer/FinalGlideBarRenderer.cpp \
	$(SRC)/Renderer/TrackLineRenderer.cpp \
	$(SRC)/Renderer/TrafficRenderer.cpp \
	$(SRC)/Renderer/TrailRenderer.cpp \
	$(SRC)/Renderer/WaypointIconRenderer.cpp \
	$(SRC)/Renderer/WaypointRenderer.cpp \
	$(SRC)/Renderer/WaypointRendererSettings.cpp \
	$(SRC)/Renderer/WindArrowRenderer.cpp \
	$(SRC)/Markers/Markers.cpp \
	$(SRC)/Markers/ProtectedMarkers.cpp \
	$(SRC)/Math/Screen.cpp \
	$(SRC)/Terrain/RasterBuffer.cpp \
	$(SRC)/Terrain/RasterProjection.cpp \
	$(SRC)/Terrain/RasterTile.cpp \
	$(SRC)/Terrain/RasterTileCache.cpp \
	$(SRC)/Terrain/RasterMap.cpp \
	$(SRC)/Terrain/RasterTerrain.cpp \
	$(SRC)/Terrain/RasterWeather.cpp \
	$(SRC)/Terrain/HeightMatrix.cpp \
	$(SRC)/Terrain/RasterRenderer.cpp \
	$(SRC)/Terrain/TerrainRenderer.cpp \
	$(SRC)/Terrain/TerrainSettings.cpp \
	$(SRC)/Terrain/WeatherTerrainRenderer.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/LabelBlock.cpp \
	$(SRC)/Screen/Fonts.cpp \
	$(SRC)/Screen/TextInBox.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Screen/Ramp.cpp \
	$(SRC)/Screen/UnitSymbol.cpp \
	$(SRC)/Look/MapLook.cpp \
	$(SRC)/Look/WindArrowLook.cpp \
	$(SRC)/Look/WaypointLook.cpp \
	$(SRC)/Look/AirspaceLook.cpp \
	$(SRC)/Look/TrailLook.cpp \
	$(SRC)/Look/TaskLook.cpp \
	$(SRC)/Look/AircraftLook.cpp \
	$(SRC)/Look/TrafficLook.cpp \
	$(SRC)/Look/MarkerLook.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/MapSettings.cpp \
	$(SRC)/ComputerSettings.cpp \
	$(SRC)/TeamCodeSettings.cpp \
	$(SRC)/Logger/Settings.cpp \
	$(SRC)/Tracking/TrackingSettings.cpp \
	$(SRC)/Computer/TraceComputer.cpp \
	$(SRC)/Task/TaskFile.cpp \
	$(SRC)/Task/TaskFileXCSoar.cpp \
	$(SRC)/Task/TaskFileSeeYou.cpp \
	$(SRC)/Task/ProtectedTaskManager.cpp \
	$(SRC)/Task/ProtectedRoutePlanner.cpp \
	$(SRC)/Task/RoutePlannerGlue.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Topography/TopographyFile.cpp \
	$(SRC)/Topography/TopographyStore.cpp \
	$(SRC)/Topography/TopographyFileRenderer.cpp \
	$(SRC)/Topography/TopographyRenderer.cpp \
	$(SRC)/Topography/TopographyGlue.cpp \
	$(SRC)/Topography/XShape.cpp \
	$(SRC)/Units/Units.cpp \
	$(SRC)/Units/Settings.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Formatter/Units.cpp \
	$(SRC)/Formatter/UserUnits.cpp \
	$(SRC)/Formatter/HexColor.cpp \
	$(SRC)/Profile/Profile.cpp \
	$(SRC)/Profile/ProfileKeys.cpp \
	$(SRC)/Profile/Earth.cpp \
	$(SRC)/Profile/ComputerProfile.cpp \
	$(SRC)/Profile/TaskProfile.cpp \
	$(SRC)/Profile/RouteProfile.cpp \
	$(SRC)/Profile/AirspaceConfig.cpp \
	$(SRC)/Profile/TrackingProfile.cpp \
	$(SRC)/Profile/MapProfile.cpp \
	$(SRC)/Profile/TerrainConfig.cpp \
	$(SRC)/Profile/Screen.cpp \
	$(SRC)/Geo/UTM.cpp \
	$(SRC)/Waypoint/HomeGlue.cpp \
	$(SRC)/Waypoint/WaypointGlue.cpp \
	$(SRC)/Waypoint/WaypointReader.cpp \
	$(SRC)/Waypoint/WaypointReaderBase.cpp \
	$(SRC)/Waypoint/WaypointReaderOzi.cpp \
	$(SRC)/Waypoint/WaypointReaderFS.cpp \
	$(SRC)/Waypoint/WaypointReaderWinPilot.cpp \
	$(SRC)/Waypoint/WaypointReaderSeeYou.cpp \
	$(SRC)/Waypoint/WaypointReaderZander.cpp \
	$(SRC)/Waypoint/WaypointReaderCompeGPS.cpp \
	$(SRC)/Waypoint/WaypointWriter.cpp \
	$(SRC)/Compatibility/fmode.c \
	$(SRC)/XML/Node.cpp \
	$(SRC)/XML/Parser.cpp \
	$(SRC)/XML/Writer.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/RadioFrequency.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/FakeDialogs.cpp \
	$(TEST_SRC_DIR)/FakeLanguage.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/FakeProfileGlue.cpp \
	$(TEST_SRC_DIR)/RunMapWindow.cpp
RUN_MAP_WINDOW_LDADD = $(RESOURCE_BINARY)
RUN_MAP_WINDOW_DEPENDS = PROFILE SCREEN SHAPELIB ENGINE JASPER IO ZZIP UTIL MATH
$(eval $(call link-program,RunMapWindow,RUN_MAP_WINDOW))

RUN_DIALOG_SOURCES = \
	$(SRC)/Look/DialogLook.cpp \
	$(SRC)/Look/ButtonLook.cpp \
	$(SRC)/XML/Node.cpp \
	$(SRC)/XML/Parser.cpp \
	$(SRC)/Dialogs/XML.cpp \
	$(SRC)/Dialogs/Inflate.cpp \
	$(SRC)/Dialogs/ListPicker.cpp \
	$(SRC)/Dialogs/ComboPicker.cpp \
	$(SRC)/Dialogs/DialogSettings.cpp \
	$(SRC)/Formatter/TimeFormatter.cpp \
	$(SRC)/DateTime.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Screen/Fonts.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Util/UTF8.cpp \
	$(SRC)/Dialogs/dlgHelp.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/Clock.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/FakeDialogs.cpp \
	$(TEST_SRC_DIR)/FakeLanguage.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/RunDialog.cpp \
	$(SRC)/Compatibility/fmode.c
RUN_DIALOG_LDADD = \
	$(RESOURCE_BINARY) \
	$(FAKE_LIBS)
RUN_DIALOG_DEPENDS = IO DATA_FIELD FORM SCREEN MATH ZZIP
$(eval $(call link-program,RunDialog,RUN_DIALOG))

RUN_LIST_CONTROL_SOURCES = \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/Look/DialogLook.cpp \
	$(SRC)/Look/ButtonLook.cpp \
	$(SRC)/KineticManager.cpp \
	$(SRC)/Form/SubForm.cpp \
	$(SRC)/Form/Form.cpp \
	$(SRC)/Form/List.cpp \
	$(SRC)/Form/ScrollBar.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(TEST_SRC_DIR)/Fonts.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/RunListControl.cpp
RUN_LIST_CONTROL_DEPENDS = SCREEN MATH
$(eval $(call link-program,RunListControl,RUN_LIST_CONTROL))

RUN_TERMINAL_SOURCES = \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Screen/Fonts.cpp \
	$(SRC)/Screen/TerminalWindow.cpp \
	$(SRC)/Look/TerminalLook.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/RunTerminal.cpp
RUN_TERMINAL_DEPENDS = SCREEN MATH
$(eval $(call link-program,RunTerminal,RUN_TERMINAL))

RUN_RENDER_OZ_SOURCES = \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Renderer/OZRenderer.cpp \
	$(SRC)/Look/DialogLook.cpp \
	$(SRC)/Look/ButtonLook.cpp \
	$(SRC)/Look/AirspaceLook.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Look/TaskLook.cpp \
	$(SRC)/Projection/Projection.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/Renderer/AirspaceRendererSettings.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/Fonts.cpp \
	$(TEST_SRC_DIR)/RunRenderOZ.cpp
RUN_RENDER_OZ_LDADD = $(RESOURCE_BINARY)
RUN_RENDER_OZ_DEPENDS = ENGINE_CORE FORM SCREEN MATH
$(eval $(call link-program,RunRenderOZ,RUN_RENDER_OZ))

RUN_WIND_ARROW_RENDERER_SOURCES = \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Math/Screen.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Screen/Fonts.cpp \
	$(SRC)/Screen/LabelBlock.cpp \
	$(SRC)/Screen/TextInBox.cpp \
	$(SRC)/Look/WindArrowLook.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Units/Units.cpp \
	$(SRC)/Units/Settings.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Renderer/WindArrowRenderer.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/RunWindArrowRenderer.cpp
RUN_WIND_ARROW_RENDERER_LDADD = $(RESOURCE_BINARY)
RUN_WIND_ARROW_RENDERER_DEPENDS = ENGINE_CORE FORM SCREEN MATH
$(eval $(call link-program,RunWindArrowRenderer,RUN_WIND_ARROW_RENDERER))

RUN_HORIZON_RENDERER_SOURCES = \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Math/Screen.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Screen/Fonts.cpp \
	$(SRC)/Screen/LabelBlock.cpp \
	$(SRC)/Screen/TextInBox.cpp \
	$(SRC)/Look/HorizonLook.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Units/Units.cpp \
	$(SRC)/Units/Settings.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Renderer/HorizonRenderer.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/RunHorizonRenderer.cpp
RUN_HORIZON_RENDERER_LDADD = $(RESOURCE_BINARY)
RUN_HORIZON_RENDERER_DEPENDS = ENGINE_CORE FORM SCREEN MATH
$(eval $(call link-program,RunHorizonRenderer,RUN_HORIZON_RENDERER))

RUN_FINAL_GLIDE_BAR_RENDERER_SOURCES = \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Math/Screen.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Screen/Fonts.cpp \
	$(SRC)/Screen/LabelBlock.cpp \
	$(SRC)/Screen/TextInBox.cpp \
	$(SRC)/Look/FinalGlideBarLook.cpp \
	$(SRC)/Look/TaskLook.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Units/Units.cpp \
	$(SRC)/Units/Settings.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Formatter/Units.cpp \
	$(SRC)/Formatter/UserUnits.cpp \
	$(SRC)/Renderer/FinalGlideBarRenderer.cpp \
	$(SRC)/NMEA/Derived.cpp \
	$(SRC)/NMEA/VarioInfo.cpp \
	$(SRC)/NMEA/CirclingInfo.cpp \
	$(SRC)/NMEA/ClimbHistory.cpp \
	$(SRC)/NMEA/ThermalBand.cpp \
	$(SRC)/NMEA/ClimbInfo.cpp \
	$(SRC)/NMEA/ThermalLocator.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(SRC)/Engine/Navigation/TraceHistory.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/RunFinalGlideBarRenderer.cpp
RUN_FINAL_GLIDE_BAR_RENDERER_LDADD = $(RESOURCE_BINARY)
RUN_FINAL_GLIDE_BAR_RENDERER_DEPENDS = ENGINE_CORE FORM SCREEN MATH
$(eval $(call link-program,RunFinalGlideBarRenderer,RUN_FINAL_GLIDE_BAR_RENDERER))

RUN_PROGRESS_WINDOW_SOURCES = \
	$(SRC)/Version.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/ProgressWindow.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Gauge/LogoView.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/RunProgressWindow.cpp
RUN_PROGRESS_WINDOW_LDADD = $(RESOURCE_BINARY)
RUN_PROGRESS_WINDOW_DEPENDS = SCREEN MATH
$(eval $(call link-program,RunProgressWindow,RUN_PROGRESS_WINDOW))

RUN_JOB_DIALOG_SOURCES = \
	$(SRC)/Version.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ThreadedOperationEnvironment.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/Job/Thread.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/ProgressWindow.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Look/DialogLook.cpp \
	$(SRC)/Look/ButtonLook.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(SRC)/Gauge/LogoView.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/Dialogs/JobDialog.cpp \
	$(SRC)/Form/SubForm.cpp \
	$(SRC)/Form/Form.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/FakeLanguage.cpp \
	$(TEST_SRC_DIR)/Fonts.cpp \
	$(TEST_SRC_DIR)/RunJobDialog.cpp
RUN_JOB_DIALOG_LDADD = $(RESOURCE_BINARY)
RUN_JOB_DIALOG_DEPENDS = SCREEN MATH
$(eval $(call link-program,RunJobDialog,RUN_JOB_DIALOG))

RUN_ANALYSIS_SOURCES = \
	$(SRC)/DateTime.cpp \
	$(SRC)/NMEA/Info.cpp \
	$(SRC)/NMEA/MoreData.cpp \
	$(SRC)/NMEA/Attitude.cpp \
	$(SRC)/NMEA/Acceleration.cpp \
	$(SRC)/NMEA/ExternalSettings.cpp \
	$(SRC)/NMEA/Derived.cpp \
	$(SRC)/NMEA/VarioInfo.cpp \
	$(SRC)/NMEA/ClimbInfo.cpp \
	$(SRC)/NMEA/CirclingInfo.cpp \
	$(SRC)/NMEA/ThermalBand.cpp \
	$(SRC)/NMEA/ThermalLocator.cpp \
	$(SRC)/NMEA/Aircraft.cpp \
	$(SRC)/NMEA/ClimbHistory.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(SRC)/FLARM/State.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/GestureManager.cpp \
	$(SRC)/Task/ProtectedTaskManager.cpp \
	$(SRC)/Task/ProtectedRoutePlanner.cpp \
	$(SRC)/Task/RoutePlannerGlue.cpp \
	$(SRC)/Math/Screen.cpp \
	$(SRC)/Atmosphere/CuSonde.cpp \
	$(SRC)/Wind/CirclingWind.cpp \
	$(SRC)/Wind/WindStore.cpp \
	$(SRC)/Wind/WindMeasurementList.cpp \
	$(SRC)/Wind/WindEKF.cpp \
	$(SRC)/Wind/WindEKFGlue.cpp \
	$(SRC)/Projection/Projection.cpp \
	$(SRC)/Projection/WindowProjection.cpp \
	$(SRC)/Projection/MapWindowProjection.cpp \
	$(SRC)/Projection/ChartProjection.cpp \
	$(SRC)/Renderer/ChartRenderer.cpp \
	$(SRC)/Renderer/TaskRenderer.cpp \
	$(SRC)/Renderer/TaskPointRenderer.cpp \
	$(SRC)/Renderer/OZRenderer.cpp \
	$(SRC)/Renderer/AircraftRenderer.cpp \
	$(SRC)/Renderer/TrailRenderer.cpp \
	$(SRC)/Geo/GeoClip.cpp \
	$(SRC)/MapWindow/MapCanvas.cpp \
	$(SRC)/Units/Units.cpp \
	$(SRC)/Units/Settings.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Formatter/Units.cpp \
	$(SRC)/Formatter/UserUnits.cpp \
	$(SRC)/Formatter/TimeFormatter.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/LocalPath.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Screen/Fonts.cpp \
	$(SRC)/Screen/Ramp.cpp \
	$(SRC)/Screen/UnitSymbol.cpp \
	$(SRC)/Look/Look.cpp \
	$(SRC)/Look/UnitsLook.cpp \
	$(SRC)/Look/IconLook.cpp \
	$(SRC)/Look/MapLook.cpp \
	$(SRC)/Look/WindArrowLook.cpp \
	$(SRC)/Look/VarioLook.cpp \
	$(SRC)/Look/ChartLook.cpp \
	$(SRC)/Look/ThermalBandLook.cpp \
	$(SRC)/Look/TraceHistoryLook.cpp \
	$(SRC)/Look/CrossSectionLook.cpp \
	$(SRC)/Look/HorizonLook.cpp \
	$(SRC)/Look/WaypointLook.cpp \
	$(SRC)/Look/AirspaceLook.cpp \
	$(SRC)/Look/TaskLook.cpp \
	$(SRC)/Look/AircraftLook.cpp \
	$(SRC)/Look/TrafficLook.cpp \
	$(SRC)/Look/GestureLook.cpp \
	$(SRC)/Look/InfoBoxLook.cpp \
	$(SRC)/Look/MarkerLook.cpp \
	$(SRC)/Look/TerminalLook.cpp \
	$(SRC)/Look/TrailLook.cpp \
	$(SRC)/Look/FinalGlideBarLook.cpp \
	$(SRC)/Gauge/FlarmTrafficLook.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Poco/RWLock.cpp \
	$(SRC)/Profile/Profile.cpp \
	$(SRC)/Profile/ProfileKeys.cpp \
	$(SRC)/Profile/FontConfig.cpp \
	$(SRC)/Terrain/RasterBuffer.cpp \
	$(SRC)/Terrain/RasterProjection.cpp \
	$(SRC)/Terrain/RasterTile.cpp \
	$(SRC)/Terrain/RasterTileCache.cpp \
	$(SRC)/Terrain/RasterMap.cpp \
	$(SRC)/Terrain/RasterTerrain.cpp \
	$(SRC)/Terrain/TerrainSettings.cpp \
	$(SRC)/XML/Node.cpp \
	$(SRC)/XML/Parser.cpp \
	$(SRC)/XML/Writer.cpp \
	$(SRC)/Dialogs/XML.cpp \
	$(SRC)/Dialogs/Inflate.cpp \
	$(SRC)/Dialogs/dlgAnalysis.cpp \
	$(SRC)/Dialogs/dlgHelp.cpp \
	$(SRC)/Dialogs/ComboPicker.cpp \
	$(SRC)/Dialogs/ListPicker.cpp \
	$(SRC)/Dialogs/DialogSettings.cpp \
	$(SRC)/Look/DialogLook.cpp \
	$(SRC)/Look/ButtonLook.cpp \
	$(SRC)/CrossSection/AirspaceXSRenderer.cpp \
	$(SRC)/CrossSection/TerrainXSRenderer.cpp \
	$(SRC)/CrossSection/CrossSectionRenderer.cpp \
	$(SRC)/CrossSection/CrossSectionWindow.cpp \
	$(SRC)/FlightStatistics.cpp \
	$(SRC)/Renderer/FlightStatisticsRenderer.cpp \
	$(SRC)/Renderer/BarographRenderer.cpp \
	$(SRC)/Renderer/ClimbChartRenderer.cpp \
	$(SRC)/Renderer/GlidePolarRenderer.cpp \
	$(SRC)/Renderer/ThermalBandRenderer.cpp \
	$(SRC)/Renderer/WindChartRenderer.cpp \
	$(SRC)/Renderer/CuRenderer.cpp \
	$(SRC)/Computer/ThermalLocator.cpp \
	$(SRC)/Computer/ThermalBase.cpp \
	$(SRC)/Computer/ThermalBandComputer.cpp \
	$(SRC)/Computer/GlideRatioCalculator.cpp \
	$(SRC)/Computer/AutoQNH.cpp \
	$(SRC)/Computer/BasicComputer.cpp \
	$(SRC)/Computer/FlyingComputer.cpp \
	$(SRC)/Computer/CirclingComputer.cpp \
	$(SRC)/Computer/WindComputer.cpp \
	$(SRC)/Computer/ContestComputer.cpp \
	$(SRC)/Computer/TraceComputer.cpp \
	$(SRC)/Computer/WarningComputer.cpp \
	$(SRC)/Computer/GlideComputer.cpp \
	$(SRC)/Computer/GlideComputerBlackboard.cpp \
	$(SRC)/Computer/GlideComputerTask.cpp \
	$(SRC)/Computer/GlideComputerRoute.cpp \
	$(SRC)/Computer/GlideComputerAirData.cpp \
	$(SRC)/Computer/GlideComputerStats.cpp \
	$(SRC)/Computer/GlideComputerInterface.cpp \
	$(SRC)/Computer/CuComputer.cpp \
	$(SRC)/UISettings.cpp \
	$(SRC)/DisplaySettings.cpp \
	$(SRC)/PageSettings.cpp \
	$(SRC)/InfoBoxes/InfoBoxSettings.cpp \
	$(SRC)/Gauge/VarioSettings.cpp \
	$(SRC)/Gauge/TrafficSettings.cpp \
	$(SRC)/ComputerSettings.cpp \
	$(SRC)/TeamCodeSettings.cpp \
	$(SRC)/Logger/Settings.cpp \
	$(SRC)/Tracking/TrackingSettings.cpp \
	$(SRC)/IGC/IGCParser.cpp \
	$(SRC)/MapSettings.cpp \
	$(SRC)/Blackboard/InterfaceBlackboard.cpp \
	$(SRC)/Audio/VegaVoice.cpp \
	$(SRC)/TeamCode.cpp \
	$(SRC)/Engine/Navigation/TraceHistory.cpp \
	$(SRC)/Airspace/ProtectedAirspaceWarningManager.cpp \
	$(SRC)/Airspace/AirspaceParser.cpp \
	$(SRC)/Airspace/AirspaceGlue.cpp \
	$(SRC)/Airspace/AirspaceVisibility.cpp \
	$(SRC)/Airspace/AirspaceComputerSettings.cpp \
	$(SRC)/Renderer/AirspaceRendererSettings.cpp \
	$(SRC)/Math/SunEphemeris.cpp \
	$(SRC)/IO/ConfiguredFile.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ProxyOperationEnvironment.cpp \
	$(SRC)/Operation/NoCancelOperationEnvironment.cpp \
	$(SRC)/Device/Port/Port.cpp \
	$(SRC)/Device/Port/NullPort.cpp \
	$(SRC)/Device/Register.cpp \
	$(SRC)/Device/Driver.cpp \
	$(SRC)/Device/Internal.cpp \
	$(SRC)/Device/Parser.cpp \
	$(SRC)/NMEA/InputLine.cpp \
	$(SRC)/NMEA/Checksum.cpp \
	$(SRC)/FLARM/FlarmId.cpp \
	$(SRC)/FLARM/Traffic.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/FakeDialogs.cpp \
	$(TEST_SRC_DIR)/FakeLanguage.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/FakeMessage.cpp \
	$(TEST_SRC_DIR)/FakeGeoid.cpp \
	$(TEST_SRC_DIR)/DebugReplay.cpp \
	$(TEST_SRC_DIR)/RunAnalysis.cpp
RUN_ANALYSIS_LDADD = \
	$(RESOURCE_BINARY)
RUN_ANALYSIS_DEPENDS = DRIVER PROFILE FORM SCREEN DATA_FIELD ENGINE JASPER IO ZZIP UTIL MATH
$(eval $(call link-program,RunAnalysis,RUN_ANALYSIS))

RUN_AIRSPACE_WARNING_DIALOG_SOURCES = \
	$(SRC)/Poco/RWLock.cpp \
	$(SRC)/NMEA/FlyingState.cpp \
	$(SRC)/XML/Node.cpp \
	$(SRC)/XML/Parser.cpp \
	$(SRC)/Airspace/ProtectedAirspaceWarningManager.cpp \
	$(SRC)/DateTime.cpp \
	$(SRC)/Units/Units.cpp \
	$(SRC)/Units/Settings.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Formatter/Units.cpp \
	$(SRC)/Formatter/UserUnits.cpp \
	$(SRC)/Formatter/TimeFormatter.cpp \
	$(SRC)/Formatter/AirspaceFormatter.cpp \
	$(SRC)/Formatter/AirspaceUserUnitsFormatter.cpp \
	$(SRC)/Look/DialogLook.cpp \
	$(SRC)/Look/ButtonLook.cpp \
	$(SRC)/Dialogs/XML.cpp \
	$(SRC)/Dialogs/Inflate.cpp \
	$(SRC)/Dialogs/ListPicker.cpp \
	$(SRC)/Dialogs/ComboPicker.cpp \
	$(SRC)/Dialogs/dlgHelp.cpp \
	$(SRC)/Dialogs/dlgAirspaceWarnings.cpp \
	$(SRC)/Dialogs/DialogSettings.cpp \
	$(SRC)/Airspace/AirspaceParser.cpp \
	$(SRC)/Audio/Sound.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Screen/Fonts.cpp \
	$(SRC)/Screen/CustomFonts.cpp \
	$(SRC)/ResourceLoader.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/LocalPath.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Profile/ProfileKeys.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Atmosphere/Pressure.cpp \
	$(IO_SRC_DIR)/ConfiguredFile.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/FakeDialogs.cpp \
	$(TEST_SRC_DIR)/FakeLanguage.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/FakeProfile.cpp \
	$(TEST_SRC_DIR)/FakeProfileGlue.cpp \
	$(TEST_SRC_DIR)/FakeTerrain.cpp \
	$(TEST_SRC_DIR)/RunAirspaceWarningDialog.cpp
RUN_AIRSPACE_WARNING_DIALOG_LDADD = \
	$(FAKE_LIBS) \
	$(RESOURCE_BINARY)
RUN_AIRSPACE_WARNING_DIALOG_DEPENDS = DATA_FIELD FORM SCREEN ENGINE IO ZZIP UTIL MATH
$(eval $(call link-program,RunAirspaceWarningDialog,RUN_AIRSPACE_WARNING_DIALOG))

RUN_TASK_EDITOR_DIALOG_SOURCES = \
	$(SRC)/Poco/RWLock.cpp \
	$(SRC)/XML/Node.cpp \
	$(SRC)/Airspace/ProtectedAirspaceWarningManager.cpp \
	$(SRC)/Dialogs/XML.cpp \
	$(SRC)/Dialogs/Inflate.cpp \
	$(SRC)/Dialogs/ComboPicker.cpp \
	$(SRC)/Dialogs/dlgHelp.cpp \
	$(SRC)/Dialogs/dlgTaskOverview.cpp \
	$(SRC)/Dialogs/dlgWaypointSelect.cpp \
	$(SRC)/Dialogs/dlgWaypointDetails.cpp \
	$(SRC)/Dialogs/dlgTaskWaypoint.cpp \
	$(SRC)/Math/SunEphemeris.cpp \
	$(SRC)/LocalTime.cpp \
	$(SRC)/Airspace/AirspaceParser.cpp \
	$(SRC)/Hardware/Display.cpp \
	$(SRC)/Screen/Layout.cpp \
	$(SRC)/Screen/Fonts.cpp \
	$(SRC)/Task/TaskFile.cpp \
	$(SRC)/Task/TaskFileXCSoar.cpp \
	$(SRC)/Task/TaskFileSeeYou.cpp \
	$(SRC)/Task/ProtectedTaskManager.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/LocalPath.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/UtilsFont.cpp \
	$(SRC)/Units/Units.cpp \
	$(SRC)/Units/Settings.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Formatter/Units.cpp \
	$(SRC)/Geo/UTM.cpp \
	$(SRC)/Waypoint/WaypointGlue.cpp \
	$(SRC)/Waypoint/WaypointReaderBase.cpp \
	$(SRC)/Waypoint/WaypointReader.cpp \
	$(SRC)/Waypoint/WaypointReaderOzi.cpp \
	$(SRC)/Waypoint/WaypointReaderFS.cpp \
	$(SRC)/Waypoint/WaypointReaderWinPilot.cpp \
	$(SRC)/Waypoint/WaypointReaderSeeYou.cpp \
	$(SRC)/Waypoint/WaypointReaderZander.cpp \
	$(SRC)/Waypoint/WaypointReaderCompeGPS.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/FakeDialogs.cpp \
	$(TEST_SRC_DIR)/FakeLanguage.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/FakeProfile.cpp \
	$(TEST_SRC_DIR)/FakeTerrain.cpp \
	$(TEST_SRC_DIR)/RunTaskEditorDialog.cpp
RUN_TASK_EDITOR_DIALOG_LDADD = \
	$(FAKE_LIBS) \
	$(RESOURCE_BINARY)
RUN_TASK_EDITOR_DIALOG_DEPENDS = DATA_FIELD FORM SCREEN ENGINE IO ZZIP UTIL
$(eval $(call link-program,RunTaskEditorDialog,RUN_TASK_EDITOR_DIALOG))

TEST_NOTIFY_SOURCES = \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/Thread/Notify.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Debug.cpp \
	$(TEST_SRC_DIR)/FakeAsset.cpp \
	$(TEST_SRC_DIR)/FakeBlank.cpp \
	$(TEST_SRC_DIR)/TestNotify.cpp
TEST_NOTIFY_DEPENDS = SCREEN TEST1
$(eval $(call link-program,TestNotify,TEST_NOTIFY))

FEED_NMEA_SOURCES = \
	$(SRC)/Device/Port/ConfiguredPort.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/OS/LogError.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/DebugPort.cpp \
	$(TEST_SRC_DIR)/FeedNMEA.cpp
FEED_NMEA_DEPENDS = PORT UTIL
$(eval $(call link-program,FeedNMEA,FEED_NMEA))

FEED_VEGA_SOURCES = \
	$(SRC)/Device/Port/ConfiguredPort.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/OS/LogError.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/DebugPort.cpp \
	$(TEST_SRC_DIR)/FeedVega.cpp
FEED_VEGA_DEPENDS = PORT UTIL
$(eval $(call link-program,FeedVega,FEED_VEGA))

EMULATE_DEVICE_SOURCES = \
	$(SRC)/Device/Port/ConfiguredPort.cpp \
	$(SRC)/Device/Port/LineHandler.cpp \
	$(SRC)/Device/Internal.cpp \
	$(SRC)/Device/Driver/FLARM/BinaryProtocol.cpp \
	$(SRC)/Device/Driver/FLARM/CRC16.cpp \
	$(SRC)/NMEA/Checksum.cpp \
	$(SRC)/NMEA/InputLine.cpp \
	$(SRC)/IO/CSVLine.cpp \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Thread/Thread.cpp \
	$(SRC)/OS/LogError.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/Operation/ConsoleOperationEnvironment.cpp \
	$(TEST_SRC_DIR)/FakeLogFile.cpp \
	$(TEST_SRC_DIR)/DebugPort.cpp \
	$(TEST_SRC_DIR)/EmulateDevice.cpp
EMULATE_DEVICE_DEPENDS = PORT UTIL
$(eval $(call link-program,EmulateDevice,EMULATE_DEVICE))

FEED_TCP_SOURCES = \
	$(TEST_SRC_DIR)/FeedTCP.cpp

ifeq ($(HAVE_POSIX),n)
ifeq ($(HAVE_CE),y)
FEED_TCP_LDLIBS += -lwinsock
else
FEED_TCP_LDLIBS += -lws2_32
endif
endif

$(eval $(call link-program,FeedTCP,FEED_TCP))

FEED_FLYNET_DATA_SOURCES = \
	$(SRC)/Math/fixed.cpp \
	$(SRC)/OS/Clock.cpp \
	$(SRC)/Util/StringUtil.cpp \
	$(TEST_SRC_DIR)/FeedFlyNetData.cpp

ifeq ($(HAVE_POSIX),n)
ifeq ($(HAVE_CE),y)
FEED_FLYNET_DATA_LDLIBS += -lwinsock
else
FEED_FLYNET_DATA_LDLIBS += -lws2_32
endif
endif

$(eval $(call link-program,FeedFlyNetData,FEED_FLYNET_DATA))

TASK_INFO_SOURCES = \
	$(SRC)/XML/Node.cpp \
	$(SRC)/XML/Parser.cpp \
	$(SRC)/XML/Writer.cpp \
	$(TEST_SRC_DIR)/TaskInfo.cpp
TASK_INFO_DEPENDS = ENGINE IO MATH UTIL
$(eval $(call link-program,TaskInfo,TASK_INFO))

DUMP_TASK_FILE_SOURCES = \
	$(SRC)/Thread/Mutex.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/OS/FileUtil.cpp \
	$(SRC)/OS/PathName.cpp \
	$(SRC)/XML/Node.cpp \
	$(SRC)/XML/Parser.cpp \
	$(SRC)/XML/Writer.cpp \
	$(SRC)/Task/TaskFile.cpp \
	$(SRC)/Task/TaskFileXCSoar.cpp \
	$(SRC)/Task/TaskFileSeeYou.cpp \
	$(SRC)/Waypoint/WaypointReaderBase.cpp \
	$(SRC)/Waypoint/WaypointReaderSeeYou.cpp \
	$(SRC)/Operation/Operation.cpp \
	$(SRC)/RadioFrequency.cpp \
	$(TEST_SRC_DIR)/FakeTerrain.cpp \
	$(TEST_SRC_DIR)/DumpTaskFile.cpp
DUMP_TASK_FILE_DEPENDS = ENGINE IO ZZIP MATH UTIL
$(eval $(call link-program,DumpTaskFile,DUMP_TASK_FILE))

IGC2NMEA_SOURCES = \
	$(SRC)/Replay/IgcReplay.cpp \
	$(SRC)/IGC/IGCParser.cpp \
	$(SRC)/NMEA/Checksum.cpp \
	$(SRC)/Units/System.cpp \
	$(SRC)/Units/Descriptor.cpp \
	$(ENGINE_SRC_DIR)/Math/Earth.cpp \
	$(ENGINE_SRC_DIR)/Navigation/GeoPoint.cpp \
	$(TEST_SRC_DIR)/IGC2NMEA.cpp

IGC2NMEA_DEPENDS = MATH UTIL
IGC2NMEA_LDADD = $(DEBUG_REPLAY_LDADD)

$(eval $(call link-program,IGC2NMEA,IGC2NMEA))

TODAY_INSTALL_SOURCES = \
	$(TEST_SRC_DIR)/TodayInstall.cpp
$(eval $(call link-program,TodayInstall,TODAY_INSTALL))

debug: $(DEBUG_PROGRAMS)
