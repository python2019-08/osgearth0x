#ifndef OsgDebugMsgHandler_H_INCLUDED
#define OsgDebugMsgHandler_H_INCLUDED

#include <android/log.h>

#include <osg/Notify>

#include <string>

class OSG_EXPORT OsgDebugMsgHandler : public osg::NotifyHandler
{
private:
    std::string _tag;
public:
    void setTag(std::string tag);
    void notify(osg::NotifySeverity severity, const char *message);
};

#endif /* OsgDebugMsgHandler_H_INCLUDED */
