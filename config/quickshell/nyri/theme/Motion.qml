pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    readonly property real speed: Config.o.motion.speed
    function t(token) { return { duration: Math.round(token.duration / speed), curve: token.curve }; }

    readonly property var fastSpatialBase: ({ duration: 367, curve: [0.0223, -0.0, 0.0447, 0.0787, 0.067, 0.1795, 0.0996, 0.3269, 0.1323, 0.5168, 0.1649, 0.6654, 0.2031, 0.8391, 0.2413, 0.9596, 0.2794, 1.0232, 0.3216, 1.0936, 0.3639, 1.1013, 0.4061, 1.0913, 0.4517, 1.0805, 0.4972, 1.0516, 0.5428, 1.0319, 0.5912, 1.011, 0.6396, 0.9986, 0.688, 0.994, 0.7389, 0.9891, 0.7898, 0.9911, 0.8406, 0.9934, 0.8938, 0.9957, 0.9469, 1.0, 1.0, 1.0] })
    readonly property var defaultSpatialBase: ({ duration: 466, curve: [0.0223, -0.0, 0.0447, 0.066, 0.067, 0.1502, 0.0996, 0.2733, 0.1323, 0.4324, 0.1649, 0.5632, 0.2031, 0.7161, 0.2413, 0.8333, 0.2794, 0.9078, 0.3216, 0.9902, 0.3639, 1.0245, 0.4061, 1.0381, 0.4517, 1.0528, 0.4972, 1.0449, 0.5428, 1.0363, 0.5912, 1.0272, 0.6396, 1.0166, 0.688, 1.0101, 0.7389, 1.0032, 0.7898, 1.0001, 0.8406, 0.9988, 0.8938, 0.9974, 0.9469, 1.0, 1.0, 1.0] })
    readonly property var slowSpatialBase: ({ duration: 504, curve: [0.0223, -0.0, 0.0447, 0.0445, 0.067, 0.1057, 0.0996, 0.1952, 0.1323, 0.3189, 0.1649, 0.4322, 0.2031, 0.5646, 0.2413, 0.6838, 0.2794, 0.7729, 0.3216, 0.8715, 0.3639, 0.9354, 0.4061, 0.9746, 0.4517, 1.0168, 0.4972, 1.0318, 0.5428, 1.0366, 0.5912, 1.0417, 0.6396, 1.0357, 0.688, 1.0294, 0.7389, 1.0228, 0.7898, 1.0155, 0.8406, 1.0105, 0.8938, 1.0052, 0.9469, 1.0, 1.0, 1.0] })
    readonly property var effectsBase: ({ duration: 231, curve: [0.0223, -0.0, 0.0447, 0.0594, 0.067, 0.1282, 0.0996, 0.2287, 0.1323, 0.35, 0.1649, 0.4502, 0.2031, 0.5672, 0.2413, 0.6602, 0.2794, 0.7291, 0.3216, 0.8053, 0.3639, 0.8542, 0.4061, 0.8885, 0.4517, 0.9256, 0.4972, 0.9461, 0.5428, 0.9601, 0.5912, 0.975, 0.6396, 0.9823, 0.688, 0.9872, 0.7389, 0.9924, 0.7898, 0.9947, 0.8406, 0.9963, 0.8938, 0.9979, 0.9469, 1.0, 1.0, 1.0] })

    readonly property var fastSpatial: t(fastSpatialBase)
    readonly property var defaultSpatial: t(defaultSpatialBase)
    readonly property var slowSpatial: t(slowSpatialBase)
    readonly property var effects: t(effectsBase)

    readonly property var emphasizedDecel: ({ duration: 400, curve: [0.05, 0.7, 0.1, 1, 1, 1] })
    readonly property var emphasizedAccel: ({ duration: 200, curve: [0.3, 0, 0.8, 0.15, 1, 1] })
}
