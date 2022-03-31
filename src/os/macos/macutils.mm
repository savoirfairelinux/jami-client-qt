#include "macutils.h"

#include <MetalKit/MetalKit.h>

bool macutils::isMetalSupported() {
    return ([[MTLCopyAllDevices() autorelease] count] > 0);
}
