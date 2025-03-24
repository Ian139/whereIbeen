# WhereIBeen

A social travel exploration app that gamifies your world adventures by revealing the map as you explore, while connecting you with fellow travelers and their journeys.

## 🌟 Core Features

### Personal Exploration

- Interactive world map with fog overlay that reveals where you've been
- Track and visualize your global exploration percentage
- Create and manage individual trips with detailed tracking
- Add comments, stories, and memories to your travels

### Social Features

- Share your trips and explorations with the community
- View other travelers' journeys and exploration maps
- Interactive feed showing latest trips and adventures
- Follow favorite travelers and their journeys
- Comment and interact with others' travel stories

### Trip Management

- Create and organize trips with start/end dates
- Real-time tracking during active trips
- Add descriptions, highlights, and travel tips
- Tag locations and points of interest
- View trip-specific exploration maps

### Travel Planning

- Browse other travelers' trips for inspiration
- Save interesting trips for future reference
- (Coming Soon) AI-powered itinerary generation based on saved trips
- (Coming Soon) Photo integration with location tagging
- (Coming Soon) Trip recommendations based on your interests

## Project Structure

### Models

- `MapArea` - Core data model for map state and exploration data
- `Trip` - Data model for individual trips and their metadata
- `User` - User profile and social connection management
- `Post` - Social feed content and interaction model

### Views

- `MainTabView` - Tab-based navigation for main app sections
- `MapView` - Interactive map with fog overlay and trip visualization
- `FeedView` - Social feed showing trips and updates
- `ProfileView` - User profile and personal stats
- `TripDetailView` - Detailed view of individual trips

### ViewModels

- `MapViewModel` - Map interaction and state management
- `TripViewModel` - Trip creation and management logic
- `FeedViewModel` - Social feed data management
- `ProfileViewModel` - User data and settings management

### Services

- `MapOverlayService` - Map overlay and calculations
- `LocationService` - Location tracking and trip recording
- `SocialService` - Social interactions and feed management
- `TripService` - Trip data management and sharing

## Technical Stack

- SwiftUI for modern iOS UI
- MapKit for map functionality
- Core Location for tracking
- CloudKit for backend storage and social features
- Core Data for local data persistence

## Getting Started

1. Clone the repository
2. Open `WhereIBeen.xcodeproj` in Xcode
3. Configure your Apple Developer account and signing
4. Build and run on an iOS device or simulator

## Contributing

We welcome contributions! Please see our contributing guidelines for more details.

## Privacy & Security

WhereIBeen takes user privacy seriously. Location data is only collected when actively tracking a trip, and users have full control over what they share with the community.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
