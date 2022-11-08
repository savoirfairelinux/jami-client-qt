
const {Map, View} = ol;
const TileLayer = ol.layer.Tile;
const ImageLayer = ol.layer.Image;
const {OSM, ImageStatic} = ol.source;

var basemap = new TileLayer({ source: new OSM() })

var dict = []

const map = new Map({
  target: 'map',
  layers: [basemap],
  view: new View({
    center: ol.proj.fromLonLat([2.1734, 41.3851]),
    zoom: 2
  })
});

function setMapView(coordos, zoom) {
    map.getView().setCenter(ol.proj.fromLonLat(coordos));
    map.getView().setZoom(zoom);
}

function dynamicZoom(longMin, latMin, longMax, latMax) {
    var coordMin = ol.proj.fromLonLat([longMin,latMin]);
    var coordMax = ol.proj.fromLonLat([longMax,latMax]);
    var extent = [coordMin[0],coordMin[1],coordMax[0],coordMax[1]];
    map.getView().fit(extent, {size: map.getSize(), maxZoom: 16, duration:500,
                          padding: [80 ,80 ,80 ,80]});
}

var extent = [0,0,50,50]  // image size is 128x128 px
var projection = new ol.proj.Projection({
    code: 'local_image',
    units: 'pixels',
    extent: extent
});

var proj = new ol.proj.Projection({
    code: 'static-image',
    units: 'pixels',
    extent: extent
});

function getImage (author) {
    for (var i = 0; i < dict.length; i ++) {
        curDict = dict[i];
        if(curDict["author"] === author ) {
            return curDict["image"]
        }
    }
    console.error("error, no avatar defined fot this author")
    return "nothing"
}

function setPosition (coordos, authorI) {

    var coord = ol.proj.fromLonLat(coordos);
    var pointFeature = new ol.Feature({
       geometry: new ol.geom.Point(coord),
       weight: 20 // e.g. temperature
    });

    var preStyle = new ol.style.Icon({
                src: "data:image/png;base64," +  getImage(authorI) })

    //resize the image to 40 px
    var image = preStyle.getImage();
    if (!image.width) {
      image.addEventListener('load', function () {
        preStyle.setScale([40 / image.width, 40 / image.height]);
      });
    } else {
      preStyle.setScale([40 / image.width, 40 / image.height]);
    }

    //creation of the style with our image
    var  iconStyle = new ol.style.Style({
      image: preStyle
    });

    //creation of the source
    pointFeature.setStyle(iconStyle);
    var vectorSource = new ol.source.Vector({
      features: [pointFeature],
    });

    var layerArray = map.getLayers().getArray();
    for (var i = 0; i < layerArray.length; i++ ){
        if(layerArray[i].layer_type === authorI) {
            layerArray[i].setSource(vectorSource);
            return
        }
    }
    //creation of our vector with our source
    var iconLayer = new ol.layer.Vector({source: vectorSource,});
    iconLayer.layer_type = authorI;
    //add the icon to the layer
    map.addLayer(iconLayer);

}

function setAvatarList (peerId, image) {
    curDict = {}
    curDict["author"] = peerId;
    curDict["image"] = image;
    dict.push(curDict);
}
