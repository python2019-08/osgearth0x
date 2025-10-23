#include "OsgMainApp.hpp"

#include <osgEarth/MapNode>
#include <osgEarth/TerrainEngineNode>
#include <osgEarth/Sky>
#include <osgEarth/EarthManipulator>

#include <osg/GLExtensions>
#include <osg/PolygonMode>
#include <osg/Geometry>

#include "osgPlugins.h"

// #define  RUN_testDrawTriangle  1
// #define DEBUG_WITH_Wireframe 1
//------------------------
osg::ref_ptr<osg::Geometry> createWireframeGeometry(osg::Geometry* geom) {
    osg::ref_ptr<osg::Geometry> wireframe = new osg::Geometry;
    wireframe->setVertexArray(geom->getVertexArray());
    wireframe->setColorArray(geom->getColorArray());
    wireframe->setNormalArray(geom->getNormalArray());

    osg::ref_ptr<osg::DrawElementsUInt> lines = new osg::DrawElementsUInt(GL_LINES);
    
    for (unsigned int i = 0; i < geom->getNumPrimitiveSets(); ++i) {
        osg::PrimitiveSet* ps = geom->getPrimitiveSet(i);
        
        // 处理 DrawElementsUInt（最常见）
        if (ps->getType() == osg::PrimitiveSet::DrawElementsUIntPrimitiveType) {
            osg::DrawElementsUInt* deui = static_cast<osg::DrawElementsUInt*>(ps);
            for (unsigned int j = 0; j < deui->size(); j += 3) {
                // 添加三角形的三条边
                lines->push_back((*deui)[j]);
                lines->push_back((*deui)[j+1]);
                
                lines->push_back((*deui)[j+1]);
                lines->push_back((*deui)[j+2]);
                
                lines->push_back((*deui)[j+2]);
                lines->push_back((*deui)[j]);
            }
        }
        // 处理 DrawArrays（需生成索引）
        else if (ps->getType() == osg::PrimitiveSet::DrawArraysPrimitiveType) {
            osg::DrawArrays* da = static_cast<osg::DrawArrays*>(ps);
            int first = da->getFirst();
            int count = da->getCount();
            for (int j = first; j < first + count - 2; j += 3) {
                lines->push_back(j);
                lines->push_back(j+1);
                
                lines->push_back(j+1);
                lines->push_back(j+2);
                
                lines->push_back(j+2);
                lines->push_back(j);
            }
        }
        // 其他类型（如 DrawElementsUShort）
        else if (ps->getType() == osg::PrimitiveSet::DrawElementsUShortPrimitiveType) {
            osg::DrawElementsUShort* deus = static_cast<osg::DrawElementsUShort*>(ps);
            for (unsigned int j = 0; j < deus->size(); j += 3) {
                lines->push_back((*deus)[j]);
                lines->push_back((*deus)[j+1]);
                
                lines->push_back((*deus)[j+1]);
                lines->push_back((*deus)[j+2]);
                
                lines->push_back((*deus)[j+2]);
                lines->push_back((*deus)[j]);
            }
        }
    }
    
    wireframe->addPrimitiveSet(lines);
    return wireframe;
}


class WireframeVisitor : public osg::NodeVisitor {
public:
    WireframeVisitor() : osg::NodeVisitor(TRAVERSE_ALL_CHILDREN) {}
    void apply(osg::Geometry& geom) override {
        osg::ref_ptr<osg::Geometry> wireframe = createWireframeGeometry(&geom);
        geom.getParent(0)->replaceChild(&geom, wireframe);
    }
};
//------------------------
OsgMainApp::OsgMainApp()
{
    _initialized = false;

}
OsgMainApp::~OsgMainApp()
{

}

void OsgMainApp::testDrawTriangle()
{
    _viewer->getCamera()->setViewMatrixAsLookAt( // 设置相机位置（看向三角形中心）
            osg::Vec3(0, 0, 25),  // 相机位置（Z轴正向）
            osg::Vec3(0, 0, 0),  // 目标点
            osg::Vec3(0, 1, 0)   // 上方向
    );

	osg::ref_ptr<osg::Geometry> geom = new osg::Geometry;
	osg::ref_ptr<osg::Vec3Array> vertices = new osg::Vec3Array;
	vertices->push_back(osg::Vec3(0,0,0));  // 顶点1
	vertices->push_back(osg::Vec3(1,0,0));  // 顶点2
	vertices->push_back(osg::Vec3(0,1,0)); // 顶点3
	geom->setVertexArray(vertices);

	// 创建颜色数组（RGBA格式）
	osg::ref_ptr<osg::Vec4Array> colors = new osg::Vec4Array;
	colors->push_back(osg::Vec4(1.0, 0.0, 0.0, 1.0)); // 红色 (顶点1)
	colors->push_back(osg::Vec4(0.0, 1.0, 0.0, 1.0)); // 绿色 (顶点2)
	colors->push_back(osg::Vec4(0.0, 0.0, 1.0, 1.0)); // 蓝色 (顶点3)

	// 将颜色数组绑定到几何体
	geom->setColorArray(colors.get());
	geom->setColorBinding(osg::Geometry::BIND_PER_VERTEX); // 每个顶点绑定一个颜色

	geom->addPrimitiveSet(new osg::DrawArrays(GL_TRIANGLES, 0, 3));
	_viewer->setSceneData(geom);
	_viewer->realize();
}

//Initialization function
void OsgMainApp::initOsgWindow(int x,int y,int width,int height, const std::string& aEarthPath)
{
    __android_log_write(ANDROID_LOG_ERROR, "OSGANDROID",
            "Initializing geometry");
    
	float glesVersion = osg::getGLVersionNumber();
	OSG_ALWAYS << "glesVersion ="<<glesVersion << std::endl;

    //Pending
    OsgAndroidNotifyHandler* _notifyHandler = new OsgAndroidNotifyHandler();
    _notifyHandler->setTag("Osg Viewer");
    osg::setNotifyHandler(_notifyHandler);
	
    osg::notify(osg::ALWAYS)<<"Testing"<<std::endl;
	osg::setNotifyLevel(osg::DEBUG_FP);
	
    _viewer = new osgViewer::Viewer();

    _viewer->setUpViewerAsEmbeddedInWindow(0, 0, width, height);
	_viewer->getCamera()->setViewport(new osg::Viewport(0, 0, width, height));
	_viewer->getCamera()->setClearMask(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	_viewer->getCamera()->setClearColor(osg::Vec4(0.0f, 0.0f, 0.5f, 1.0f));
	_viewer->getCamera()->setProjectionMatrixAsPerspective(45.0f, (float)(width / height), 0.1f, 1000.0f);
	_viewer->getEventQueue()->getCurrentEventState()->setMouseYOrientation(osgGA::GUIEventAdapter::Y_INCREASING_UPWARDS);
	_viewer->getCamera()->setNearFarRatio(0.00002f);
	_viewer->setThreadingModel(osgViewer::ViewerBase::SingleThreaded);
	_viewer->getCamera()->setLODScale(_viewer->getCamera()->getLODScale() * 1.5f);
	_viewer->getDatabasePager()->setIncrementalCompileOperation(new osgUtil::IncrementalCompileOperation());
	_viewer->getDatabasePager()->setDoPreCompile(true);
	_viewer->getDatabasePager()->setTargetMaximumNumberOfPageLOD(0);
	_viewer->getDatabasePager()->setUnrefImageDataAfterApplyPolicy(true, true);
#ifndef RUN_testDrawTriangle
	_viewer->setCameraManipulator(new osgEarth::Util::EarthManipulator());
#endif
	// _viewer->setRunFrameScheme( osgViewer::ViewerBase::ON_DEMAND );

	// --------------------------
#ifdef RUN_testDrawTriangle
	// test draw triangle
	testDrawTriangle();
	return ;
#endif
	// --------------------------

	std::string filepath = aEarthPath;//"/sdcard/Download/readymap.earth";
	std::ifstream testFile(filepath.c_str());
	if (!testFile.good()) {
		OSG_ALWAYS << "File aEarthPath does not exist or is inaccessible: " << filepath << std::endl;
	} else {
		OSG_ALWAYS << "File aEarthPath exists and is readable." << std::endl;
	}	


	osg::Node* node = osgDB::readNodeFile(filepath);
	if(!node) {
		OSG_ALWAYS << "Unable to load an earth file from the command line." << std::endl;
		return;
	}else {
    	OSG_ALWAYS << "Successfully loaded node from: " << filepath << std::endl;
	}


	osg::ref_ptr<osgEarth::Util::MapNode> mapNode = osgEarth::Util::MapNode::findMapNode(node);
	if(!mapNode.valid()) {
		OSG_ALWAYS << "Loaded scene graph does not contain a MapNode - aborting" << std::endl;
		return;
	}else {
    	OSG_ALWAYS << "Valid MapNode found." << std::endl;
	}

	// -------------------------
	// 方法 1：全局设置线框模式（适用于所有模型）---only be used for PC-GL,Cannot be used for GLES 
	// // 获取根节点的状态集
	// osg::ref_ptr<osg::StateSet> stateset = mapNode->getOrCreateStateSet();
	// // 创建多边形模式对象并设置为线框 
	// osg::ref_ptr<osg::PolygonMode> pm = new osg::PolygonMode;
	// pm->setMode(osg::PolygonMode::FRONT_AND_BACK, osg::PolygonMode::LINE);
	// stateset->setAttributeAndModes(pm, osg::StateAttribute::ON);  
	// -------------------------
	// 方案 2：用 GL_LINES重新绘制几何体
	// 将原始模型转换为线框几何体（适用于 GLES 2.0+）： 
#ifdef  DEBUG_WITH_Wireframe
    WireframeVisitor visitor;
    mapNode->accept(visitor);
#endif    
	// -------------------------

	_viewer->setSceneData(mapNode.get());

    _viewer->realize();

    _initialized = true;
}

//Draw
void OsgMainApp::draw()
{
    _viewer->frame();
}

//Events
void OsgMainApp::mouseButtonPressEvent(float x,float y,int button)
{
    _viewer->getEventQueue()->mouseButtonPress(x, y, button);
}
void OsgMainApp::mouseButtonReleaseEvent(float x,float y,int button)
{
    _viewer->getEventQueue()->mouseButtonRelease(x, y, button);
}
void OsgMainApp::mouseMoveEvent(float x,float y)
{
    _viewer->getEventQueue()->mouseMotion(x, y);
}
void OsgMainApp::keyboardDown(int key)
{
    _viewer->getEventQueue()->keyPress(key);
}
void OsgMainApp::keyboardUp(int key)
{
    _viewer->getEventQueue()->keyRelease(key);
}
