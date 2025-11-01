//
//  DemoScene.cpp
//  osgearthDemos
//

#include "OsgDemoScene.h"
#include "OsgDebugMsgHandler.h"
#include "OeLayerFactory.h"
#include "OsgDebugMsgHandler.h"


#include <osgEarth/Capabilities>
#include <osgEarth/Registry>
#include <osgEarth/MapNode>
#include <osgEarth/Sky>
#include <osgEarth/EarthManipulator>
#include <osg/PositionAttitudeTransform>

#include <osg/Material>
#include <osgDB/ReadFile>
#include <osgDB/FileUtils>
#include <osgGA/MultiTouchTrackballManipulator>
#include <osgEarthDrivers/sky_simple/SimpleSkyOptions>//for the sky

using namespace osgEarth;
using namespace osgEarth::Util;


DemoScene::DemoScene()
    :osg::Referenced()
{
    
}

DemoScene::~DemoScene()
{
    
}

void DemoScene::init(const std::string& aFile, osg::Vec2 aViewSize, UIView* view)
{
	// Set up a handler to pass debug info to the java code
	OsgDebugMsgHandler *notify = new OsgDebugMsgHandler();
	notify->setTag("AndroiOearth01");
	osg::setNotifyHandler(notify);

    osg::setNotifyLevel(osg::DEBUG_FP);
    osgEarth::setNotifyLevel(osg::DEBUG_FP);

	OSG_ALWAYS << "Initializing scene graph" << std::endl;

    //osgEarth::Registry::instance()->setCapabilities(   );
    
	_viewer = new osgViewer::Viewer();
    _viewer->setUpViewerAsEmbeddedInWindow(0, 0, aViewSize.x(), aViewSize.y());
    _viewer->getCamera()->setViewport(new osg::Viewport(0, 0, aViewSize.x(), aViewSize.y()));
    _viewer->getCamera()->setClearMask(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    _viewer->getCamera()->setClearColor(osg::Vec4(0.0f,0.0f,0.0f,1.0f));
    _viewer->getCamera()->setProjectionMatrixAsPerspective(45.0f,(float)aViewSize.x()/aViewSize.y(), 0.1, 1000.0);
    _viewer->getCamera()->setNearFarRatio(0.00002);
    _viewer->setThreadingModel(osgViewer::ViewerBase::SingleThreaded);
    _viewer->getDatabasePager()->setIncrementalCompileOperation(new osgUtil::IncrementalCompileOperation());
    _viewer->getDatabasePager()->setDoPreCompile( true );
    _viewer->getDatabasePager()->setTargetMaximumNumberOfPageLOD(0);
    _viewer->getDatabasePager()->setUnrefImageDataAfterApplyPolicy(true,true);

    this->initDemo(aFile);
}




void DemoScene::initDemo(const std::string &aEarthPath)
{
#if 0	
	osgEarth::Map* map = new osgEarth::Map();
	osgEarth::TMSImageLayer* imgLayer = OeLayerFactory::createTMSImageLayer( );
	map->addLayer( imgLayer );  	
	_mapNode = new osgEarth::MapNode(map); 
#else	 
	std::string tokenKey="0d1f2112fff847dc55c16376841c62c8";
	osgEarth::XYZImageLayer* xyzImgLayer = OeLayerFactory::CreateTdtTileLayer(tokenKey, false);

	osgEarth::Map * map = new osgEarth::Map();
	map->addLayer( xyzImgLayer ); 
	_mapNode = new osgEarth::MapNode(map); 	
#endif

	// --------------------------------------------
    _viewer->setCameraManipulator(new osgEarth::Util::EarthManipulator());
	osgEarth::Util::EarthManipulator* manip = dynamic_cast<osgEarth::Util::EarthManipulator*>(
		_viewer->getCameraManipulator() );
	osgEarth::Util::EarthManipulator::ActionOptions options;
	manip->getSettings()->setMouseSensitivity(0.30);
	manip->getSettings()->setThrowingEnabled(true);
	manip->getSettings()->setThrowDecayRate(0.1);
	manip->getSettings()->setLockAzimuthWhilePanning(true);
	manip->getSettings()->setArcViewpointTransitions(false);
	manip->getSettings()->bindTwist(osgEarth::Util::EarthManipulator::ACTION_NULL, options);
	manip->getSettings()->bindMultiDrag(osgEarth::Util::EarthManipulator::ACTION_NULL, options);
	manip->getSettings()->setMinMaxPitch(-90.0, -90.0);

	#if 0
	// osgEarth::SkyOptions sOptions;
	// sOptions.ambient() = 1.0;
	// osgEarth::SkyNode* sky = osgEarth::SkyNode::create(sOptions);
	// sky->attach(_viewer, 0);
	// sky->addChild(_mapNode);
	#else
    //----sky
    //SkyOptions options;
    osgEarth::SimpleSky::SimpleSkyOptions skyOptions;
    skyOptions.quality() = osgEarth::SkyOptions::QUALITY_DEFAULT;
    skyOptions.ambient() = 0.01;//控制环境光强度
    skyOptions.exposure() = 10.f;//控制白天的亮度
    skyOptions.atmosphereVisible() = true;//大气层厚度是否可见
    skyOptions.atmosphericLighting() = true;//大气散射光是否可见
    skyOptions.sunVisible() = true;
    skyOptions.moonVisible() = true;
    skyOptions.starsVisible() = true;
	skyOptions.starSize() = 42.0;
    skyOptions.usePBR() = true;
    //添加天空模型
    auto extSky=osgEarth::Extension::create("sky_simple", skyOptions);
    _mapNode->addExtension(extSky);//这里不能使用addChild, Extension是一种更复杂的对象
	#endif

    osg::Group* root = new osg::Group();
    root->addChild(_mapNode);// root->addChild(sky);

    // // Set up our material and lighting properties
    // osg::Material* material = new osg::Material();
    // material->setAmbient(osg::Material::FRONT, osg::Vec4(0.4,0.4,0.4,1.0));
    // material->setDiffuse(osg::Material::FRONT, osg::Vec4(0.9,0.9,0.9,1.0));
    // material->setSpecular(osg::Material::FRONT, osg::Vec4(0.4,0.4,0.4,1.0));
    // root->getOrCreateStateSet()->setAttribute(material);
	// root->getOrCreateStateSet()->setMode(GL_LIGHTING, osg::StateAttribute::OFF | osg::StateAttribute::OVERRIDE);
	// root->getOrCreateStateSet()->setAttribute(_viewer->getLight());

	_viewer->setSceneData(root);

    _viewer->realize();
}


void DemoScene::frame()
{
	_viewer->frame();
}

void DemoScene::setDataPath(std::string dataPath, std::string packagePath)
{
	_dataPath = dataPath;
	_packagePath = packagePath;
}

