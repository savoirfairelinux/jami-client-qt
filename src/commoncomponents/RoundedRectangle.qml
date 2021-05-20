/*
 * Copyright (C) 2021 by Savoir-faire Linux
 * Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.14

// based on https://stackoverflow.com/a/3368118
// Note: this is quite slow and should be replaced with a shader
// or a group of clipped rectangles or a shape ASAP
Canvas {
    id: root

    property var radius
    property string fillColor: "transparent"
    property real borderWidth: 0.0
    property string borderColor: "black"

    onRadiusChanged: requestPaint()
    onFillColorChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");

        var lw = borderWidth
        if (typeof lw === 'undefined')
            lw = 0
        var r = {}

        Object.assign(r, radius)
        if (typeof r === 'undefined')
            r = 0
        if (typeof r === 'number')
            r = {tl: r, tr: r, br: r, bl: r}
        else {
            var defaultRadius = {tl: 0, tr: 0, br: 0, bl: 0}
            for (var side in defaultRadius)
                r[side] = r[side] || defaultRadius[side]
        }

        // Adjust for line width.
        var hlw = lw * 0.5
        for (side in r)
            if (r[side] > hlw)
                r[side] -= hlw
        var x0 = hlw
        var y0 = x0
        var x1 = width - hlw
        var y1 = height - hlw

        ctx.reset() // clear the old canvas.
        ctx.beginPath()
        ctx.moveTo(x0 + r.tl, y0)
        ctx.lineTo(x1 - r.tr, y0)
        ctx.quadraticCurveTo(x1, y0, x1, y0 + r.tr)
        ctx.lineTo(x1 , y1 - r.br)
        ctx.quadraticCurveTo(x1, y1, x1 - r.br, y1)
        ctx.lineTo(x0 + r.bl, y1)
        ctx.quadraticCurveTo(x0, y1, x0, y1 - r.bl)
        ctx.lineTo(x0 , y0 + r.tl)
        ctx.quadraticCurveTo(x0, y0, x0 + r.tl, y0)
        ctx.closePath()

        ctx.fillStyle = fillColor
        ctx.fill()

        if (lw > 0) {
            ctx.lineWidth = lw
            ctx.strokeStyle = borderColor
            ctx.stroke()
        }
    }
}
