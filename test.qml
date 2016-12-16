
// Copyright 2016 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the Sample code usage restrictions document for further information.
//

import QtQuick 2.6
import QtQuick.Controls 1.4
import Esri.ArcGISRuntime 100.0

ApplicationWindow {
    id: appWindow
    width: 800
    height: 600
    title: "Quick"

    property var featureTableHouses: null
    property var featureTableSchools: null
    property var schoolGeometry: null

    onFeatureTableHousesChanged: {
        if (featureTableHouses === null)
            return;

        featureTableHouses.queryFeaturesStatusChanged.connect(function() {
            if (featureTableHouses.queryFeaturesStatus === Enums.TaskStatusCompleted) {
                if (!featureTableHouses.queryFeaturesResult.iterator.hasNext) {
                    errorMsgDialog.visible = true;
                    return;
                }

                // clear any previous selection
                map.operationalLayers.get(0).layers[0].clearSelection();

                var features = []
                // get the features
                while (featureTableHouses.queryFeaturesResult.iterator.hasNext) {
                    features.push(featureTableHouses.queryFeaturesResult.iterator.next());
                }

                map.operationalLayers.get(0).layers[0].selectionWidth = 15;
                console.log("Query returned", features.length, "results")
                map.operationalLayers.get(0).layers[0].selectFeatures(features);
            }
        });
    }

    onFeatureTableSchoolsChanged: {
        if (featureTableSchools === null)
            return;

        featureTableSchools.queryFeaturesStatusChanged.connect(function() {
            if (featureTableSchools.queryFeaturesStatus === Enums.TaskStatusCompleted) {
                if (!featureTableSchools.queryFeaturesResult.iterator.hasNext) {
                    errorMsgDialog.visible = true;
                    return;
                }

                // clear any previous selection
                map.operationalLayers.get(1).layers[0].clearSelection();

                var features = []
                // get the features
                while (featureTableSchools.queryFeaturesResult.iterator.hasNext) {
                    var feature = featureTableSchools.queryFeaturesResult.iterator.next();
                    features.push(feature);
                    schoolGeometry = feature.geometry;
                }

                map.operationalLayers.get(1).layers[0].selectionWidth = 15;
                console.log("Query returned", features.length, "results")
                map.operationalLayers.get(1).layers[0].selectFeatures(features);
            }
        });
    }

    // add a mapView component
    MapView {
        anchors.fill: parent

        // add a map to the mapview
        Map {
            id: map

            initUrl: "http://www.arcgis.com/home/item.html?id=a95963333bf84055b7115dc60d10443e"

            onLoadStatusChanged: {
                if (loadStatus !== Enums.LoadStatusLoaded)
                    return;

                // this one is not loaded wwhen the map is loaded, not sure why
                var l = operationalLayers.get(0);
                l.loadStatusChanged.connect(function() {
                    if (l.loadStatus === Enums.LoadStatusLoaded) {
                        featureTableHouses = l.layers[0].featureTable;
                    }
                });

                featureTableSchools = operationalLayers.get(1).layers[0].featureTable;
            }
        }

        Button {
            id: b1
            text: "Bedrooms"
            onClicked: {
                featureTableHouses.queryFeatures(params);
            }
        }

        Button {
            id: b2
            anchors.left: b1.right
            text: "Find School"
            onClicked: {
                featureTableSchools.queryFeatures(schoolQuery);
            }
        }

        Button {
            id: b3
            anchors.left: b2.right
            text: "Find houses within radius"
            onClicked: {
                featureTableHouses.queryFeatures(schoolSpatialQuery);
            }
        }
    }

    QueryParameters {
        id: params
        whereClause: "BedRooms > 3"
    }

    QueryParameters {
        id: schoolQuery
        whereClause: "School='McKinley Elementary'"
    }

    QueryParameters {
        id: schoolSpatialQuery
        whereClause: "BedRooms > 3"
        geometry: schoolGeometry ? GeometryEngine.buffer(schoolGeometry, 2000) : null
    }

}
