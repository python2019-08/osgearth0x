//
#include "osgPlugins.h"

#include <osgViewer/Viewer>
#include <osgEarth/Notify>
#include <osgEarth/EarthManipulator>
#include <osgEarth/MapNode>
#include <osgEarth/Threading>
#include <osgEarth/ShaderGenerator>
#include <osgDB/ReadFile>
#include <osgGA/TrackballManipulator>
#include <osgUtil/Optimizer>
#include <iostream>
#include <osgEarth/Metrics>
#include <osgEarth/GDAL>
#include <osgEarth/TMS>
#include <osgEarth/GLUtils>
#include <osgEarthDrivers/sky_simple/SimpleSkyOptions>//for the sky

using namespace osgEarth;
using namespace osgEarth::Util;
#include <iostream> 


int main()
{
    osgEarth::initialize();

    //create a viewer
    osgViewer::Viewer viewer;
    viewer.setUpViewInWindow(0, 100, 800, 600);
    viewer.setReleaseContextAtEndOfFrameHint(false);

    //set camera manipulator
    viewer.setCameraManipulator(new EarthManipulator);
    osgEarth::Map* map = new osgEarth::Map();

    // dataBasePath
    std::string dataBasePath="/home/abner/abner2/zdev/nv/osgearth0x/3rd/osgearth/data";

    //layer
    osgEarth::GDALImageLayer* layer1 = new osgEarth::GDALImageLayer();
    std::string  tifPath_world = dataBasePath+"/world.tif";
    layer1->setURL( osgEarth::URI(tifPath_world) );
    map->addLayer(layer1);

    //elevation
    osgEarth::TMSElevationLayer* elev2 = new osgEarth::TMSElevationLayer();
    elev2->setURL(osgEarth::URI("http://readymap.org/readymap/tiles/1.0.0/116/"));
    elev2->setVerticalDatum("egm96");
    map->addLayer(elev2);

    osg::ref_ptr<osgEarth::MapNode> mapNode = new osgEarth::MapNode(map);

#if  1
    //----------ok，sky and stars displayed.
    //sky
    //SkyOptions options;
    osgEarth::SimpleSky::SimpleSkyOptions options;
    options.quality() = osgEarth::SkyOptions::QUALITY_DEFAULT;
    options.ambient() = 0.001;//控制环境光强度
    options.exposure() = 10.f;//控制白天的亮度
    options.atmosphereVisible() = true;//大气层厚度是否可见
    options.atmosphericLighting() = true;//大气散射光是否可见
    options.sunVisible() = true;
    options.moonVisible() = true;
    options.starsVisible() = true;
    options.usePBR() = true;
    //添加天空模型
    auto extSky=osgEarth::Extension::create("sky_simple", options);
    mapNode->addExtension(extSky);//这里不能使用addChild, Extension是一种更复杂的对象
#else 
	osgEarth::SkyOptions sOptions;
	sOptions.ambient() = 0.7;
	osgEarth::SkyNode* sky = osgEarth::SkyNode::create(sOptions);
	sky->attach(&viewer, 0);
	sky->addChild(mapNode);    
#endif

    //set black background color
    viewer.getCamera()->setClearColor(osg::Vec4(0, 0, 0, 1));//设置宇宙背景颜色为黑色
    viewer.setSceneData(mapNode);
    return osgEarth::Metrics::run(viewer);
}