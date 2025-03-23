# WhereIBeen

An iOS app that shows a map with a fog overlay that tracks where you've been.

## Project Structure

This project follows the MVVM (Model-View-ViewModel) architecture:

### Models

- `MapArea.swift` - Data model for storing map state and exploration data

### Views

- `ContentView.swift` - Main view that composes the UI
- `MapView.swift` - SwiftUI wrapper for MKMapView with custom overlay rendering
- Component Views: `ExplorationPercentageView`, `ResetButton`

### ViewModels

- `MapViewModel.swift` - Business logic for map interaction and state management

### Services

- `MapOverlayService.swift` - Service for managing map overlays and calculations

## Features

- Interactive map with custom fog overlay
- Track percentage of world explored
- Reset exploration progress

## Getting Started

1. Clone the repository
2. Open `WhereIBeen.xcodeproj` in Xcode
3. Build and run on an iOS device or simulator
