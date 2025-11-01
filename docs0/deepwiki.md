# 1.Core Components

## Relevant source files

The Core Components of osgEarth provide the fundamental architecture and building blocks upon which the entire SDK is built. This document outlines the key elements that form the foundation of the osgEarth system, including the data model, scene graph integration, spatial reference system, and other essential services and utilities.
【】osgEarth的核心组件提供了构建整个SDK的基础架构和构建块。本文档概述了构成osgEarth系统基础的关键要素，包括数据模型、场景图集成、空间参考系统以及其他基本服务和实用程序。
For information about specific rendering engines, see Terrain Rendering. For details on the layer system, see Layer System.
有关特定渲染引擎的信息，请参见地形渲染。有关层系统的详细信息，请参阅层系统。

## Core Architecture Overview核心架构概述

Global Services
Spatial Reference
Scene Graph
Data Model
Map
Profile
Layer Collection
ImageLayer
ElevationLayer
ModelLayer
FeatureLayer
Registry
ElevationPool
MapNode
TerrainEngine
Terrain
OverlayDecorator
DrapingTechnique
ClampingTechnique
SpatialReference
Ellipsoid
VerticalDatum
GeoPoint
GeoExtent
Cache
Capabilities
ShaderFactory
URI
HTTPClient

Sources:
src/osgEarth/Map.cpp
src/osgEarth/MapNode.cpp
src/osgEarth/Registry.cpp

src/osgEarth/SpatialReference.cpp

The diagram above illustrates the primary components of the osgEarth system and their relationships. Each subsystem plays a critical role in the overall architecture.
上图说明了osgEarth系统的主要组成部分及其关系。每个子系统在整体架构中都起着至关重要的作用。

## Map and MapNode

The core design pattern in osgEarth separates the data model (Map) from its visual representation (MapNode), following the Model-View pattern.

View Component

Data Model
Map
Layers
ElevationPool
Profile
MapCallbacks
CacheSettings
MapNode
TerrainGroup
TerrainEngine
LayerNodeGroup
OverlayDecorator
DrapingTechnique
ClampingTechnique

Sources:
src/osgEarth/Map.cpp90-313
src/osgEarth/MapNode.cpp216-459

src/osgEarth/Map.h20-35

## Map

The Map is the central data model in osgEarth. It maintains a collection of Layer objects, each providing different types of data to the map (imagery, elevation, features, etc.). The Map also manages the profile (tiling scheme), elevation data access, and various other settings.
地图是osgEarth的核心数据模型。它维护一组图层对象，每个对象都为地图提供不同类型的数据（图像、高程、地物等）。地图还管理纵断面（平铺方案）、高程数据访问和各种其他设置。

### Key responsibilities of the Map class:

    Managing the collection of layers
    Maintaining the map profile which defines the spatial reference system and tiling structure
    Providing access to elevation data via the ElevationPool
    Managing cache policy and settings
    Notifying observers of changes through the MapCallback mechanism
```cpp
// Creating a basic Map
Map* map = new Map();
map->addLayer(new ImageLayer("imagery", imageLayerOptions));
map->addLayer(new ElevationLayer("elevation", elevationLayerOptions));
```

Sources:
src/osgEarth/Map.cpp90-197

src/osgEarth/Map.h29-49

## MapNode

The MapNode is an OSG Node that renders a Map. It creates the necessary scene graph structure to visualize the data in the Map, including:

    A terrain engine that renders the surface of the earth
    A node graph for model layers and other content
    Support for various techniques like draping and clamping
```cpp
// Creating a MapNode from a Map
MapNode* mapNode = new MapNode(map);

// Adding the MapNode to a scene graph
root->addChild(mapNode);
```
The MapNode serves as the bridge between osgEarth's data model and OSG's scene graph system. When the map changes (e.g., layers added or removed), the MapNode updates the scene graph accordingly.

Sources:
src/osgEarth/MapNode.cpp216-289
src/osgEarth/MapNode.cpp564-620

src/osgEarth/MapNode.h43-89

## Spatial Reference System

The spatial reference system components provide coordinate system management, transformations, and geospatial primitives for working with geographic data.

Sources:
src/osgEarth/SpatialReference.cpp96-289
src/osgEarth/Profile.cpp110-293

src/osgEarth/GeoData.cpp20-639

## SpatialReference

The SpatialReference (SRS) class encapsulates a coordinate reference system. It manages:

    Horizontal reference system (geographic or projected coordinates)
    Vertical reference system (height/elevation datum)
    Coordinate transformations between different systems
    Earth ellipsoid parameters
```cpp
// Creating a WGS84 geographic SRS
SpatialReference* srs = SpatialReference::create("wgs84");

// Creating a Spherical Mercator SRS
SpatialReference* mercatorSRS = SpatialReference::create("spherical-mercator");

// Creating an SRS with a vertical datum
SpatialReference* srsWithVertical = SpatialReference::create("wgs84", "egm96");
```

SpatialReference objects are typically created through the Registry's SRS cache to ensure efficient reuse of common coordinate systems.

Sources:
src/osgEarth/SpatialReference.cpp117-230

src/osgEarth/SpatialReference.h32-53
## Profile

The Profile class defines the tiling scheme for a map. It includes:

    The spatial reference system
    The extent (geographic coverage) of the map
    The tiling structure (number and arrangement of tiles at each level of detail)
```cpp
// Creating a global geodetic profile
Profile* profile = Profile::create(Profile::GLOBAL_GEODETIC);

// Creating a global mercator profile
Profile* mercatorProfile = Profile::create(Profile::SPHERICAL_MERCATOR);
```
The Profile is used by the terrain engine to generate terrain tiles and by layer implementations to request appropriate data for those tiles.

Sources:
src/osgEarth/Profile.cpp 110-293
src/osgEarth/Profile.h 14-54

## GeoPoint and GeoExtent

These classes represent geospatial primitives used throughout osgEarth:

    GeoPoint: A point with x, y, z coordinates in a specific spatial reference system
    GeoExtent: A rectangular extent in a specific spatial reference system
```cpp
// Creating a GeoPoint
GeoPoint point(srs, longitude, latitude, elevation, ALTMODE_ABSOLUTE);

// Creating a GeoExtent
GeoExtent extent(srs, west, south, east, north);
```

These classes provide methods for transforming between different coordinate systems, converting between geodetic and world coordinates, and other geospatial operations.

Sources:
src/osgEarth/GeoData.cpp20-639

src/osgEarth/GeoData35-225

## Registry and Global Services

The Registry provides a centralized access point for global services, caches, and shared resources.

Registry

Capabilities

SRS Cache

ShaderFactory

ShaderGenerator

StateSetCache

ObjectIndex

Default Cache

URI ReadCallback

Font Cache

Blacklisted Filenames

Sources:
src/osgEarth/Registry.cpp80-307

src/osgEarth/Registry.h38-222

## Registry

The Registry is a singleton that provides application-wide services and resources. It manages:

    Hardware capabilities detection
    Spatial reference system cache
    Default cache implementation
    Shader management
    URI resolution and reading
    Shared resource pools
```cpp
// Accessing the Registry
Registry* registry = Registry::instance();

// Getting cached SRS
SpatialReference* srs = registry->getOrCreateSRS(srsKey);

// Accessing the default cache
Cache* cache = registry->getDefaultCache();
```

The Registry is typically initialized at application startup and remains available throughout the application's lifetime.

Sources:
src/osgEarth/Registry.cpp80-148
src/osgEarth/Registry.cpp282-307

src/osgEarth/Registry.h38-99

## Capabilities

The Capabilities class provides information about hardware and graphics system capabilities. It detects:

    GPU features and limitations
    Available OpenGL extensions
    Maximum texture sizes
    Shader support
    Driver information
```cpp
// Getting capabilities
const Capabilities& caps = Registry::instance()->getCapabilities();

// Checking for specific capabilities
if (caps.supportsGLSL())
{
    // Use GLSL shaders
}
```

Capabilities are automatically detected when the Registry is initialized, providing a centralized place to query system capabilities.

Sources:
src/osgEarth/Capabilities.cpp30-145

src/osgEarth/Capabilities.h21-90

## Supporting Utilities

Besides the main architectural components, osgEarth provides several supporting utilities that are essential to the core functionality.
URIs and Resource Loading

osgEarth includes a robust system for resource loading via URIs:

URI

HTTPClient

CacheSettings

ReadResult

ProxySettings

UserAgent

Cache

CachePolicy

The URI class handles resolution and loading of resources, supporting various protocols (file, http, etc.) and integrating with the caching system.

Sources:
src/osgEarth/Registry.cpp169-183

src/osgEarth/Registry.cpp490-529

## Image Utilities

The ImageUtils namespace provides functions for image manipulation, essential for handling imagery layers:

    Image resizing and resampling
    Format conversion
    Mipmap generation
    Texture compression
    Pixel reading and writing
```cpp
// Resizing an image
osg::ref_ptr<osg::Image> resized;
ImageUtils::resizeImage(sourceImage, 256, 256, resized);

// Converting image formats
osg::Image* converted = ImageUtils::convertToRGBA8(sourceImage);
```

These utilities are used extensively by the terrain engine and layer implementations to process and prepare image data for rendering.

Sources:
src/osgEarth/ImageUtils.cpp33-290

src/osgEarth/ImageUtils.h38-99

## Initialization and Startup

osgEarth requires proper initialization at application startup:
```cpp
// Initialize osgEarth
osgEarth::initialize();

// Or with arguments
osgEarth::initialize(arguments);

// Create a Map and MapNode
Map* map = new Map();
MapNode* mapNode = new MapNode(map);
```

The initialization process sets up the Registry, configures GDAL/OGR, and prepares the environment for osgEarth operations.

Sources:
src/osgEarth/Registry.cpp27-49

src/osgEarth/Registry.cpp80-183

## Key Relationships and Data Flow

The following diagram illustrates the key relationships and data flow between core components:

"Registry"

"TerrainEngine"

"MapNode"

"Layer"

"Map"

"Application"

"Registry"

"TerrainEngine"

"MapNode"

"Layer"

"Map"

"Application"

create

create

addLayer(Layer)

setReadOptions

open()

getCapabilities

create(Map)

create

setMap(Map)

getLayers()

return layers

createTile(TileKey)

getCache()

return Cache

Sources:
src/osgEarth/Map.cpp405-465
src/osgEarth/MapNode.cpp242-459

src/osgEarth/Registry.cpp282-307

## Extension Points

osgEarth provides several extension points in its core components:

    Map Callbacks: Register callbacks to be notified of map changes
    Layer Creation: Create custom layer types by extending the Layer base class
    Extensions: Register extensions with MapNode to add functionality
    URI Callbacks: Customize resource loading behavior
    Shader Composition: Add custom shaders to the rendering pipeline
```cpp
// Example of extending with a custom extension
class MyExtension : public Extension
{
public:
    // Implementation
};

MapNode* mapNode = MapNode::get(root);
mapNode->addExtension(new MyExtension());
```
Sources:
src/osgEarth/MapNode.cpp633-688

src/osgEarth/MapNode.h153-169

## Summary

The core components of osgEarth provide a solid foundation for geospatial visualization:
Component	Purpose
Map	Central data model that manages layers and settings
MapNode	Scene graph representation that visualizes a Map
SpatialReference	Manages coordinate systems and transformations
Profile	Defines the tiling scheme for a map
Registry	Provides global services and resource management
GeoPoint/GeoExtent	Geospatial primitives for location data

Understanding these core components is essential for effectively working with osgEarth, as they provide the foundation upon which more specialized functionality is built.

Sources:
src/osgEarth/Map.cpp
src/osgEarth/MapNode.cpp
src/osgEarth/SpatialReference.cpp
src/osgEarth/Profile.cpp
src/osgEarth/Registry.cpp
src/osgEarth/GeoData.cpp

================================================