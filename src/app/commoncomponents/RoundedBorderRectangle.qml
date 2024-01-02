/*
 * Copyright (C) 2024 Savoir-faire Linux Inc.
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import net.jami.Models 1.1
import net.jami.Adapters 1.1
import net.jami.Constants 1.1

Canvas {

    property var radius
    property string fillColor: Style.colorBGPrimary

    onRadiusChanged: requestPaint()
    onFillColorChanged: requestPaint()

    //Draw rounded rectangle.
    onPaint: {
        var ctx = getContext("2d");
        var r = {};
        Object.assign(r, radius);
        if (typeof r === 'undefined')
            r = 0;
        if (typeof r === 'number')
            r = {
                "tl": r,
                "tr": r,
                "br": r,
                "bl": r
            };
        else {
            var defaultRadius = {
                "tl": 0,
                "tr": 0,
                "br": 0,
                "bl": 0
            };
            for (var side in defaultRadius)
                r[side] = r[side] || defaultRadius[side];
        }
        var x0 = 0;
        var y0 = x0;
        var x1 = width;
        var y1 = height;
        ctx.reset();
        ctx.beginPath();
        ctx.moveTo(x0 + r.tl, y0);
        ctx.lineTo(x1 - r.tr, y0);
        ctx.quadraticCurveTo(x1, y0, x1, y0 + r.tr);
        ctx.lineTo(x1, y1 - r.br);
        ctx.quadraticCurveTo(x1, y1, x1 - r.br, y1);
        ctx.lineTo(x0 + r.bl, y1);
        ctx.quadraticCurveTo(x0, y1, x0, y1 - r.bl);
        ctx.lineTo(x0, y0 + r.tl);
        ctx.quadraticCurveTo(x0, y0, x0 + r.tl, y0);
        ctx.closePath();
        ctx.fillStyle = fillColor;
        ctx.fill();
    }
}
