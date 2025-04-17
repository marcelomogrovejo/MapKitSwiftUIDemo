//
//  ContentView.swift
//  MapDemo.iOS17
//
//  Created by Marcelo Mogrovejo on 16/04/2025.
//

// Source: https://www.youtube.com/watch?v=98rQZbwxMFI

import SwiftUI
import MapKit

struct ContentView: View {
    // To request permision to use the user location
    let locationManager = CLLocationManager()

    @State private var cameraPosition: MapCameraPosition = .region(.init(center: .home,
                                                                         latitudinalMeters: 1300,
                                                                         longitudinalMeters: 1300))
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isShowingLookAround = false
    @State private var route: MKRoute?

    var body: some View {
        Map(position: $cameraPosition) {
//            Marker("Apple Visitor Center", systemImage: "laptopcomputer", coordinate: .appleVisitorCenter)
//            Marker("Panama Park", systemImage: "tree.fill", coordinate: .panamaPark)
//                .tint(.green)
            
            // Refactor in separated and reusable view
            Annotation("Home", coordinate: .home, anchor: .bottom) {
                Image(systemName: "house.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .padding(7)
                    .background(.black.gradient, in: .circle)
                    .contextMenu {
                        Button("Open Look Arounnd", systemImage: "binoculars") {
                            Task {
                                lookAroundScene = await getLookAroundScene(from: .home)
                                guard lookAroundScene != nil else { return }
                                isShowingLookAround = true
                            }
                        }
                        Button("Get Directions", systemImage: "arrow.turn.down.right") {
                            getDirections(to: .home)
                        }
                    }
            }
            Annotation("Ferry Elizabeth Quay", coordinate: .ferryElizabethQuaid, anchor: .bottom) {
                Image(systemName: "ferry.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .padding(7)
                    .background(.pink.gradient, in: .circle)
                    .contextMenu {
                        Button("Open Look Arounnd", systemImage: "binoculars") {
                            Task {
                                lookAroundScene = await getLookAroundScene(from: .ferryElizabethQuaid)
                                guard lookAroundScene != nil else { return }
                                isShowingLookAround = true
                            }
                        }
                        Button("Get Directions", systemImage: "arrow.turn.down.right") {
                            getDirections(to: .ferryElizabethQuaid)
                        }
                    }
            }
            Annotation("King Park & Botanical Garden", coordinate: .kingParkBotanicalGarden, anchor: .bottom) {
                Image(systemName: "tree.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .padding(7)
                    .background(.green.gradient, in: .circle)
                    .contextMenu {
                        Button("Open Look Arounnd", systemImage: "binoculars") {
                            Task {
                                lookAroundScene = await getLookAroundScene(from: .kingParkBotanicalGarden)
                                guard lookAroundScene != nil else { return }
                                isShowingLookAround = true
                            }
                        }
                        Button("Get Directions", systemImage: "arrow.turn.down.right") {
                            getDirections(to: .kingParkBotanicalGarden)
                        }
                    }
            }

            Annotation("My job", coordinate: .work, anchor: .bottom) {
                Image(systemName: "building.2.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .padding(7)
                    .background(.yellow.gradient, in: .circle)
                    .contextMenu {
                        Button("Open Look Arounnd", systemImage: "binoculars") {
                            Task {
                                lookAroundScene = await getLookAroundScene(from: .work)
                                guard lookAroundScene != nil else { return }
                                isShowingLookAround = true
                            }
                        }
                        Button("Get Directions", systemImage: "arrow.turn.down.right") {
                            getDirections(to: .work)
                        }
                    }
            }

            UserAnnotation()

            if let route {
                MapPolyline(route)
                    .stroke(Color.pink, lineWidth: 4)
            }
        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapPitchToggle()
            MapScaleView()
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .lookAroundViewer(isPresented: $isShowingLookAround, scene: $lookAroundScene)
    }

    /// Gets a look around scene for a coordinates
    /// - Parameter coordinate:
    /// - Returns: look around scene
    func getLookAroundScene(from coordinate: CLLocationCoordinate2D) async -> MKLookAroundScene? {
        do {
            return try await MKLookAroundSceneRequest(coordinate: coordinate).scene
        } catch {
            print("Cannot retrieve look around scene: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Gets the user currenct location
    /// - Returns: coordinates
    func getUserLocation() async -> CLLocationCoordinate2D? {
        let updates = CLLocationUpdate.liveUpdates()
        do {
            let update = try await updates.first { $0.location?.coordinate != nil }
            return update?.location?.coordinate
        } catch {
            print("Cannot get user location: \(error.localizedDescription)")
            return nil
        }
    }

    /// Get a walking direction path from the user current location to the given destination
    /// - Parameter destination: destination coordinates
    func getDirections(to destination: CLLocationCoordinate2D) {
        Task {
            guard let userLocation = await getUserLocation() else { return }

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: userLocation))
            request.destination = MKMapItem(placemark: .init(coordinate: destination))
            request.transportType = .walking

            do {
                let directions = try await MKDirections(request: request).calculate()
                route = directions.routes.first
                calculateRegionToFit(coordinates: [userLocation, destination])
            } catch {
                print("Error getting directions: \(error.localizedDescription)")
            }
        }
    }
    
    /// <#Description#>
    /// - Parameter coordinates: <#coordinates description#>
    func calculateRegionToFit(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }

        // Find the minimum and maximum latitude and longitude values of the search
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        // Calculate the region based on the search values
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let padding: Double = 0.005
        let span = MKCoordinateSpan(
            latitudeDelta: maxLat - minLat + padding,
            longitudeDelta: maxLon - minLon + padding
        )
        let region = MKCoordinateRegion(center: center, span: span)
        let newCameraPosition: MapCameraPosition = .region(region)
        cameraPosition = newCameraPosition
    }
}

#Preview {
    ContentView()
}

extension CLLocationCoordinate2D {
    static let ferryElizabethQuaid = CLLocationCoordinate2D(latitude: -31.956956148146187, longitude: 115.85598567416766)
    static let optusStadium = CLLocationCoordinate2D(latitude: -31.950895396290967, longitude: 115.88824353965249)
    static let kingParkBotanicalGarden = CLLocationCoordinate2D(latitude: -31.960772289516896, longitude: 115.8327472610476)
    static let perth = CLLocationCoordinate2D(latitude: -31.950934450673, longitude: 115.85996564582562)
    static let home = CLLocationCoordinate2D(latitude: -31.970838701817076, longitude: 115.81733669987415)
    static let work = CLLocationCoordinate2D(latitude: -31.872630919113636, longitude: 115.92597050781775)
}
