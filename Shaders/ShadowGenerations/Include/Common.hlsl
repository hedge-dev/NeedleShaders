#ifndef COMMON_INCLUDED
#define COMMON_INCLUDED

#define DefineFeature(feature_name) static const uint FEATURE_##feature_name
#define FeatureCheck(feature_name) !defined(feature_name) && !defined(no_##feature_name)

#endif