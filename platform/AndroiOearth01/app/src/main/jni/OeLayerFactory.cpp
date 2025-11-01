//
// Created by abner on 2025/10/25.
//

#include "OeLayerFactory.h"



// Initialize satellite and OSM image layers
osgEarth::TMSImageLayer* OeLayerFactory::createTMSImageLayer( )
{
    auto imagery = new osgEarth::TMSImageLayer();
	imagery->setName("ReadyMap");
    imagery->setURL("http://readymap.org/readymap/tiles/1.0.0/7/");
	// osgEarth::Map *map=...;
    // map->addLayer( imagery );  
	return imagery;
}

// wmts	0d1f2112fff847dc55c16376841c62c8  浏览器端
// 
//  https://blog.csdn.net/weixin_41012454/article/details/134085979
/// <summary>
/// 创建天地图图层
/// </summary>
/// <param name="key">天地图key</param>
/// <param name="isVector">是否是矢量图层</param>
/// <returns>天地图瓦片图层</returns>
osgEarth::XYZImageLayer* OeLayerFactory::CreateTdtTileLayer(std::string key, bool isVector)
{
 
	osgEarth::URIContext context;
	context.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/"
		"*;q=0.8,application/signed-exchange;v=b3;q=0.9");
	context.addHeader("Accept-Encoding", "gzip, deflate");
	context.addHeader("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6");
	context.addHeader("Cache-Control", "max-age=0");
	context.addHeader("Connection", "keep-alive");
	context.addHeader("Upgrade-Insecure-Requests", "1");
	context.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) "
		"Chrome/99.0.4844.51 Safari/537.36 Edg/99.0.1150.39");
 
	std::string lySourceName = isVector ? "vec_w" : "img_w";
 
	// std::string lyName = isVector ? "天地图矢量" : "天地图影像";
	std::string lyName = isVector ? "tianditu-vector" : "tianditu-image";
	
	std::string urlLocation ="http://t[01234567].tianditu.com/DataServer?T=" + lySourceName 
							+"&tk=" + key 
							+"&l={z}&x={x}&y={y}";
	osgEarth::URI imgUri(urlLocation, context);
 
	osgEarth::XYZImageLayer* imgLy = new osgEarth::XYZImageLayer();
 
	imgLy->setURL(imgUri);
 
	imgLy->setProfile(osgEarth::Profile::create("spherical-mercator"));
 
	imgLy->setName(lyName);
 
	imgLy->setOpacity(1);
 
	return imgLy; 
}
 
 
/// <summary>
/// 创建天地图注记瓦片图层
/// </summary>
/// <param name="key">天地图key</param>
/// <param name="isVector">是否是矢量图层</param>
/// <returns></returns>
osgEarth::XYZImageLayer* OeLayerFactory::CreateTdtRemarkTileLayer(std::string key, bool isVector)
{
	osgEarth::URIContext context;
	context.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/"
		"*;q=0.8,application/signed-exchange;v=b3;q=0.9");
	context.addHeader("Accept-Encoding", "gzip, deflate");
	context.addHeader("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6");
	context.addHeader("Cache-Control", "max-age=0");
	context.addHeader("Connection", "keep-alive");
	context.addHeader("Upgrade-Insecure-Requests", "1");
	context.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) "
		"Chrome/99.0.4844.51 Safari/537.36 Edg/99.0.1150.39");
 
	std::string lySourceName = isVector ? "cva_w" : "cia_w"; 
	std::string lyName = isVector ? "天地图矢量注记" : "天地图影像注记";
	std::string urlLocation = "http://t[01234567].tianditu.com/DataServer?T=" + lySourceName 
						+ "&tk=" + key 
						+ "&l={z}&x={x}&y={y}";
	osgEarth::URI imgUri(urlLocation, context);
 
	osgEarth::XYZImageLayer* imgLy = new osgEarth::XYZImageLayer();
 
	imgLy->setURL(imgUri);
 
	imgLy->setName(lyName);
 
	imgLy->setOpacity(1);
 
	imgLy->setProfile(osgEarth::Profile::create("spherical-mercator"));
 
	return imgLy; 
} 

// osg::ref_ptr<osgEarth::TiledFeatureModelLayer> mvtLayer = new osgEarth::TiledFeatureModelLayer();	
// 
// osg::ref_ptr<osgEarth::StyleSheet> styleSheet = new osgEarth::StyleSheet();
// styleSheet->addStyle(parsed);
// mvtLayer->setStyleSheet(styleSheet.get());
// osgEarth::StyleSheet  这个可以设置点线面符号

					
// 为球形地球添加 Horizon 剔除（加上这个可以剔除球背面的瓦片数据）
// osg::ref_ptr<HorizonCullCallback> horizonCuller = new HorizonCullCallback();
// horizonCuller->setEllipsoid(srs->getEllipsoid());
// group->addCullCallback(horizonCuller);   