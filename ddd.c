#define USE_OSGEARTH_LAYER(NAME) extern "C" void osgdb_osgearth_ ## NAME(void); static osgDB::PluginFunctionProxy proxy_osgearth_layer_ ## NAME(OE_STRINGIFY(osgdb_osgearth_ ## NAME));
扩展到:

extern "C" void osgdb_osgearth_tmselevation(void); static osgDB::PluginFunctionProxy proxy_osgearth_layer_tmselevation("osgdb_osgearth_tmselevation");