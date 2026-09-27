import QtQuick
import qs.theme

// 24 h of battery level: a soft area under a round-joined line. Charging
// stretches are drawn in secondary. Redraws only when the data changes.
Canvas {
    id: root

    property var points: []            // [{ t, v, charging }], oldest first
    readonly property real span: 86400000

    onPointsChanged: requestPaint()
    onWidthChanged: requestPaint()
    Connections {
        target: Colors
        function onRolesChanged() { root.requestPaint() }
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width, h = height - 20, now = Date.now();
        const X = t => Math.max(0, (t - (now - span)) / span) * w;
        const Y = v => 6 + (1 - v / 100) * (h - 12);

        // Grid: 0, 50, 100.
        ctx.strokeStyle = Colors.m3outlineVariant;
        ctx.lineWidth = 1;
        ctx.setLineDash([3, 5]);
        for (const v of [0, 50, 100]) {
            ctx.beginPath();
            ctx.moveTo(0, Y(v));
            ctx.lineTo(w, Y(v));
            ctx.stroke();
        }
        ctx.setLineDash([]);

        const pts = points.filter(p => p.t >= now - span);
        if (pts.length < 2)
            return;

        // Area.
        ctx.beginPath();
        ctx.moveTo(X(pts[0].t), h);
        for (const p of pts) ctx.lineTo(X(p.t), Y(p.v));
        ctx.lineTo(X(pts[pts.length - 1].t), h);
        ctx.closePath();
        const grad = ctx.createLinearGradient(0, 0, 0, h);
        grad.addColorStop(0, Qt.alpha(Colors.m3primary, 0.35));
        grad.addColorStop(1, Qt.alpha(Colors.m3primary, 0.02));
        ctx.fillStyle = grad;
        ctx.fill();

        // Line, segment by segment so charging can change color.
        ctx.lineWidth = 3;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        for (let i = 1; i < pts.length; i++) {
            ctx.strokeStyle = pts[i].charging ? Colors.m3secondary : Colors.m3primary;
            ctx.beginPath();
            ctx.moveTo(X(pts[i - 1].t), Y(pts[i - 1].v));
            ctx.lineTo(X(pts[i].t), Y(pts[i].v));
            ctx.stroke();
        }

        // Now: a dot on the last value.
        const last = pts[pts.length - 1];
        ctx.fillStyle = Colors.m3primary;
        ctx.beginPath();
        ctx.arc(X(last.t), Y(last.v), 5, 0, Math.PI * 2);
        ctx.fill();

        // Hour labels.
        ctx.fillStyle = Colors.m3onSurfaceVariant;
        ctx.font = "500 11px '" + Type.family + "'";
        ctx.textAlign = "center";
        for (const back of [24, 18, 12, 6]) {
            const t = now - back * 3600000;
            ctx.fillText(Qt.formatTime(new Date(t), "HH:00"), Math.min(w - 18, Math.max(18, X(t))), height - 2);
        }
        ctx.textAlign = "right";
        ctx.fillText("сейчас", w, height - 2);
    }
}
