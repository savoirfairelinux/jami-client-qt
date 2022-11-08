/*
 * Copyright (C) 2022 Savoir-faire Linux Inc.
 * Author: Nicolas Vengeon <nicolas.vengeon@savoirfairelinux.com>
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

const {Map, View} = ol
const TileLayer = ol.layer.Tile
const ImageLayer = ol.layer.Image
const {OSM, ImageStatic} = ol.source

var basemap = new TileLayer({ source: new OSM() })
basemap.layer_type = "map"

var dict = []

const map = new Map({
  target: 'map',
  layers: [basemap],
  view: new View({
    center: ol.proj.fromLonLat([2.1734, 41.3851]),
    zoom: 2
  })
})

function setMapView(coordos, zoom) {
    map.getView().setCenter(ol.proj.fromLonLat(coordos))
    map.getView().setZoom(zoom)
}

function dynamicZoom(longMin, latMin, longMax, latMax) {
    var coordMin = ol.proj.fromLonLat([longMin,latMin])
    var coordMax = ol.proj.fromLonLat([longMax,latMax])
    var extent = [coordMin[0],coordMin[1],coordMax[0],coordMax[1]]
    map.getView().fit(extent, {size: map.getSize(), maxZoom: 16, duration:500,
                          padding: [80 ,80 ,80 ,80]})
}

var extent = [0,0,50,50]  // image size is 128x128 px
var projection = new ol.proj.Projection({
    code: 'local_image',
    units: 'pixels',
    extent: extent
})

var proj = new ol.proj.Projection({
    code: 'static-image',
    units: 'pixels',
    extent: extent
})

function setSource (coordos, authorI,imageI) {
    var coord = ol.proj.fromLonLat(coordos)
    var pointFeature = new ol.Feature({
       geometry: new ol.geom.Point(coord),
       weight: 20
    })

    var preStyle = new ol.style.Icon({
                src: "data:image/png;base64," +  imageI })

    //resize the image to 40 px
    var image = preStyle.getImage()
    if (!image.width) {
      image.addEventListener('load', function () {
        preStyle.setScale([40 / image.width, 40 / image.height])
      })
    } else {
      preStyle.setScale([40 / image.width, 40 / image.height])
    }

    //creation of the style with our image
    var  iconStyle = new ol.style.Style({
      image: preStyle
    })

    //creation of the source
    pointFeature.setStyle(iconStyle);
    var vectorSource = new ol.source.Vector({
      features: [pointFeature],
    })

    return vectorSource
}

function newPosition (coordos, authorI, image) {
    vectorSource = setSource(coordos,authorI,image)
    var iconLayer = new ol.layer.Vector({source: vectorSource})
    iconLayer.layer_type = authorI
    map.addLayer(iconLayer)
}

function updatePosition (coordos, authorI) {
    var coord = ol.proj.fromLonLat(coordos);
    var layerArray = map.getLayers().getArray();
    for (var i = 0; i < layerArray.length; i++ ){
        if(layerArray[i].layer_type === authorI) {
            layerArray[i].getSource().getFeatures()[0].getGeometry().setCoordinates(coord)
            return
        }
    }
}

function zoomTolayersExtent() {
    var ext = ol.extent.createEmpty();
    var layerArray = map.getLayers().getArray();
    for (var i = 0; i < layerArray.length; i++ ){
        if(layerArray[i].layer_type !== "map") {
            ext = ol.extent.extend(ext, layerArray[i].getSource().getExtent());
        }
     }
    map.getView().fit(ext, {size: map.getSize(), maxZoom: 16, duration:500,
                             padding: [80 ,80 ,80 ,80]})
}

function removePosition (authorI) {
    var layerArray = map.getLayers().getArray();
    for (var i = 0; i < layerArray.length; i++ ){
        if(layerArray[i].layer_type === authorI) {
            map.removeLayer(layerArray[i])
            return
        }
    }
}
