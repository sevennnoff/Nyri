import QtQuick
import qs.theme
import "../lib/shapes/material-shapes.js" as Shapes
import "../lib/shapes/shapes/morph.js" as Morph

// One of the 35 M3 Expressive shapes. Changing `shape` morphs to the new one
// on the fast spatial curve, overshoot included.
Canvas {
    id: root

    property string shape: "circle"    // cookie9Sided, sunny, clover4Leaf, ...
    property color color: Colors.m3primary
    property real progress: 1

    property var current: polygon(shape)
    property var morph: new Morph.Morph(current, current)

    function polygon(name) {
        const make = Shapes["get" + name.charAt(0).toUpperCase() + name.slice(1)];
        if (!make)
            console.warn("MaterialShape: unknown shape", name);
        return make ? make() : Shapes.getCircle();
    }

    onShapeChanged: {
        const next = polygon(shape);
        morph = new Morph.Morph(current, next);
        current = next;
        morphAnim.restart();
    }

    SpatialAnim {
        id: morphAnim
        target: root
        property: "progress"
        from: 0
        to: 1
        speed: "fast"
    }

    Behavior on color { ColorAnim {} }

    onProgressChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const cubics = morph.asCubics(progress);
        if (!cubics.length)
            return;
        const size = Math.min(width, height);
        ctx.translate((width - size) / 2, (height - size) / 2);
        ctx.scale(size, size);
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.moveTo(cubics[0].anchor0X, cubics[0].anchor0Y);
        for (const c of cubics)
            ctx.bezierCurveTo(c.control0X, c.control0Y, c.control1X, c.control1Y, c.anchor1X, c.anchor1Y);
        ctx.closePath();
        ctx.fill();
    }
}
