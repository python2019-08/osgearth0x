//
// Created by abner on 2025/10/25.
//

#ifndef ANDROIOEARTH01_OELAYERFACTORY_H
#define ANDROIOEARTH01_OELAYERFACTORY_H

#include <osgEarth/XYZ>
#include <osgEarth/TMS>
#include <osgEarth/Map>

class OeLayerFactory {
public:
    static osgEarth::XYZImageLayer* CreateTdtTileLayer(std::string key, bool isVector);

    static osgEarth::XYZImageLayer* CreateTdtRemarkTileLayer(std::string key, bool isVector);

    static osgEarth::TMSImageLayer* createTMSImageLayer( );
};


#endif //ANDROIOEARTH01_OELAYERFACTORY_H
