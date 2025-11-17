# 1.crash-callstacks 01

```sh
#0  ___pthread_mutex_lock (mutex=0x2c8) at ./nptl/pthread_mutex_lock.c:80
#1  0x0000638af9318e1b in __gthread_mutex_lock (__mutex=0x2c8) at /usr/include/x86_64-linux-gnu/c++/13/bits/gthr-default.h:749
#2  0x0000638af9319c04 in std::mutex::lock (this=0x2c8) at /usr/include/c++/13/bits/std_mutex.h:113
#3  0x0000638af931b242 in std::lock_guard<std::mutex>::lock_guard (this=0x7bc2ddff8730, __m=...) at /usr/include/c++/13/bits/std_mutex.h:249
#4  0x0000638af94d8dbc in osgEarth::Registry::isBlacklisted (this=0x0, filename="https://readymap.org/readymap/tiles/1.0.0/116/2/2/2.tif")
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/Registry.cpp:546
#5  0x0000638af960b065 in (anonymous namespace)::doRead<(anonymous namespace)::ReadImage> (inputURI=..., dbOptions=0x638b3715eba0, progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/URI.cpp:529
#6  0x0000638af9607f1b in osgEarth::URI::readImage (this=0x7bc2ddff8df0, dbOptions=0x638b3715eba0, progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/URI.cpp:726
#7  0x0000638af95f03a8 in osgEarth::TMS::Driver::read (this=0x638b3732bd98, uri=..., key=..., invertY=false, progress=0x7bc2cc037490, readOptions=0x638b3715eba0)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TMS.cpp:947
#8  0x0000638af95f210c in osgEarth::TMSImageLayer::createImageImplementation (this=0x638b37310a40, key=..., progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TMS.cpp:1241
#9  0x0000638af95f40d1 in osgEarth::TMSElevationLayer::createHeightFieldImplementation (this=0x638b371ad420, key=..., progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TMS.cpp:1448
#10 0x0000638af93135a4 in osgEarth::ElevationLayer::createHeightFieldInKeyProfile (this=0x638b371ad420, key=..., progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/ElevationLayer.cpp:477
#11 0x0000638af9312bbd in osgEarth::ElevationLayer::createHeightField (this=0x638b371ad420, key=..., progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/ElevationLayer.cpp:360
#12 0x0000638af9314aaf in osgEarth::ElevationLayerVector::populateHeightField (this=0x638b37061858, hf=0x7bc2cc15cad0, resolutions=0x7bc2ddff9eb0, key=..., haeProfile=0x638b36e1ba30, 
    interpolation=osgEarth::INTERP_BILINEAR, progress=0x7bc2cc037490) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/ElevationLayer.cpp:810
#13 0x0000638af970f30a in osgEarth::ElevationPool::getOrCreateRaster (this=0x638b370616c0, key=..., map=0x638b36e40670, acceptLowerRes=true, ws=0x638b37665118, progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/ElevationPool.cpp:333
#14 0x0000638af9710d4b in osgEarth::ElevationPool::sampleMapCoords (this=0x638b370616c0, begin=..., end=..., ws=0x638b37665118, progress=0x7bc2cc037490, failValue=-3.40282347e+38)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/ElevationPool.cpp:661
#15 0x0000638af970b056 in osgEarth::NormalMapGenerator::createNormalMap (this=0x7bc2ddffa5bf, key=..., map=0x638b36e40670, ws=0x638b37665118, ruggedness=0x0, progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/Elevation.cpp:326
#16 0x0000638af970a66d in osgEarth::ElevationTile::generateNormalMap (this=0x7bc2cc073720, map=0x638b36e40670, workingSet=0x638b37665118, progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/Elevation.cpp:229
#17 0x0000638af958f50d in osgEarth::TerrainTileModelFactory::addElevation (this=0x638b37664e40, model=0x7bc2cc071a80, map=0x638b36e40670, key=..., manifest=..., border=0, progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:458
#18 0x0000638af958dbea in osgEarth::TerrainTileModelFactory::createTileModel (this=0x638b37664e40, map=0x638b36e40670, key=..., manifest=..., require=..., progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainTileModelFactory.cpp:153
#19 0x0000638af95788e9 in osgEarth::TerrainEngineNode::createTileModel (this=0x638b379b8ca0, map=0x638b36e40670, key=..., manifest=..., progress=0x7bc2cc037490)
    at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/TerrainEngineNode.cpp:223
#20 0x0000638af9fc94f6 in operator() (__closure=0x7bc2e02d5160, progress=...) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarthDrivers/engine_rex/LoadTileData.cpp:84
#21 0x0000638af9fca1b2 in operator() (__closure=0x7bc2e02d5160) at /home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/src/osgEarth/weejobs.h:814
--Type <RET> for more, q to quit, c to continue without paging--
#22 0x0000638af9fcacd2 in std::__invoke_impl<bool, jobs::dispatch<osgEarth::REX::LoadTileDat
```