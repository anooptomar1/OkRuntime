//
//  MapActions.swift
//  OkRuntime
//
//  Created by Gagandeep Singh on 12/15/16.
//  Copyright © 2016 Gagandeep Singh. All rights reserved.
//

import Foundation
import ArcGIS

public protocol MapActionsDelegate : NSObjectProtocol {
    func finishedPerformingAction()
    func show(popupViewController: AGSPopupsViewController)
}

class MapActions: NSObject {
    
    weak var mapView:AGSMapView?
    weak var housesFeatureLayer:AGSFeatureLayer?
    weak var schoolsFeatureLayer:AGSFeatureLayer?
    public var delegate: MapActionsDelegate?
    var popupsViewController: AGSPopupsViewController?
    
    public init(mapView: AGSMapView?, housesFeatureLayer: AGSFeatureLayer?, schoolsFeatureLayer: AGSFeatureLayer?) {
        super.init()
        self.mapView = mapView
        self.housesFeatureLayer = housesFeatureLayer
        self.schoolsFeatureLayer = schoolsFeatureLayer
    }
    
    func performActionForEnum(action:actions) {
        switch action {
        case .whereAm:
            self.startLocationDisplay()
        case .housesForSale:
            self.showHousesForSale()
        case .houseBedroomFilter:
            self.bedroomsQuery()
        case .showSchools:
            self.showSchools()
        case .schoolFilter:
            self.specificSchool()
        case .houseSchoolFilter:
            self.housesNearSchool()
        case .houseStreetFilter:
            self.specificHouse()
            break
        case .wrongQuery:
            break
        default:
            //TODO: Siri to speak WHAT?
            break
        }
    }
    
    
    func startLocationDisplay() {
        if let mapView = mapView {
            mapView.locationDisplay.autoPanMode = .recenter
            mapView.locationDisplay.start(completion: { [weak self] (error) in
                if (error == nil) {
                    self?.callDelegate()
                }
            })
        }
    }
    
    func showHousesForSale() {
        self.housesFeatureLayer?.isVisible = true
        let center = AGSPoint(x: -13037418.581550, y: 4030051.109528, spatialReference: AGSSpatialReference(wkid: 3857))
        self.mapView?.setViewpointCenter(center, scale: 82678.451713792907, completion: nil)
        self.callDelegate()
    }
    
    func bedroomsQuery() {
        self.housesFeatureLayer?.definitionExpression = "BedRooms > 4"
        let center = AGSPoint(x: -13037418.581550, y: 4030051.109528, spatialReference: AGSSpatialReference(wkid: 3857))
        self.mapView?.setViewpointCenter(center, scale: 82678.451713792907, completion: nil)
        self.callDelegate()
    }
    
    func showSchools() {
        self.schoolsFeatureLayer?.isVisible = true
        let center = AGSPoint(x: -13043774.486030, y: 4035083.466798, spatialReference: AGSSpatialReference(wkid: 3857))
        self.mapView?.setViewpointCenter(center, scale: 53614.08479392287, completion: nil)
        self.callDelegate()
    }
    
    func specificSchool() {
        self.schoolsFeatureLayer?.definitionExpression = "School='McKinley Elementary'"
        let center = AGSPoint(x: -13045289.562800001, y: 4035484.596500002, spatialReference: AGSSpatialReference(wkid: 3857))
        self.mapView?.setViewpointCenter(center, scale: 1370, completion: nil)
        self.callDelegate()
    }
    
    func housesNearSchool() {
        //self.housesFeatureLayer?.definitionExpression = "BedRooms > 4 && "
        let center = AGSPoint(x: -13045289.562800001, y: 4035484.596500002, spatialReference: AGSSpatialReference(wkid: 3857))
        self.mapView?.setViewpointCenter(center, scale: 8445, completion: nil)
        self.callDelegate()
    }
    
    func specificHouse() {
        let query = AGSQueryParameters()
        query.objectIDs = [118]
        self.housesFeatureLayer?.selectFeatures(withQuery: query, mode: .new, completion: { [weak self] (queryResult, error) in
            if (queryResult?.featureEnumerator().allObjects.count)! > 0 {
                let feature = queryResult?.featureEnumerator().allObjects[0]
                self?.housesFeatureLayer?.select(feature!)
                let popup = AGSPopup(geoElement: feature!, popupDefinition: self?.housesFeatureLayer?.popupDefinition)
                self?.popupsViewController = AGSPopupsViewController(popups: [popup])
                let point = feature?.geometry as! AGSPoint
                self?.mapView?.setViewpointCenter(point, scale: 4000, completion: { (finished) in
                    if finished {
                        if (self?.delegate != nil) {
                            let screen = self?.mapView?.location(toScreen: point)
                            let popoverRect = CGRect(x: (screen?.x)!, y: (screen?.y)!, width: 1, height: 1)
                            self?.popupsViewController?.modalPresentationStyle = .popover
                            self?.popupsViewController?.popoverPresentationController?.sourceRect = popoverRect
                            self?.delegate?.show(popupViewController: (self?.popupsViewController)!)
                        }
                    }
                })
            }
        })
    }
    
    func callDelegate() {
        if (self.delegate != nil) {
            self.delegate?.finishedPerformingAction()
        }
    }
}
