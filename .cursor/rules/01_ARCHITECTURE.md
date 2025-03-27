# Architecture Guidelines - Shock-Style Content Generator

## Overview
This document outlines the architectural decisions and patterns for the Shock-Style Content Generator iOS app.

## Core Architecture

### MVVM Pattern Implementation
```swift
// Example View Model Structure
class ImageGenerationViewModel: ObservableObject {
    @Published private(set) var generatedImage: UIImage?
    @Published private(set) var isProcessing = false
    private let imageService: ImageGenerationServiceProtocol
    
    func generateImage(from source: UIImage) async throws { ... }
}

// Example View Structure
struct ImageGenerationView: View {
    @StateObject private var viewModel: ImageGenerationViewModel
    
    var body: some View {
        // UI implementation
    }
}
```

### Module Dependencies
```
App
├── Features
│   ├── Onboarding -> Core, UI
│   ├── ImageCapture -> Core, UI
│   ├── ImageGeneration -> Core, UI, OpenAI
│   ├── Subscription -> Core, UI, RevenueCat
│   └── Settings -> Core, UI
└── Core
    ├── OpenAI -> Foundation
    ├── RevenueCat -> Foundation
    └── UI -> SwiftUI, Foundation
```

## Feature Modules

### Image Processing Module
- Capture/selection interface
- Processing queue management
- Memory optimization
- Cache management
- Error handling

### OpenAI Integration Module
- API client implementation
- Request/response handling
- Rate limiting
- Error recovery
- Response caching

### Subscription Module
- RevenueCat integration
- Purchase flow
- Receipt validation
- Subscription state management
- Restore purchases

## Data Flow

### State Management
```swift
// Example State Flow
class AppState: ObservableObject {
    @Published var userSubscription: SubscriptionStatus
    @Published var generatedImages: [GeneratedImage]
    @Published var processingQueue: ProcessingQueue
}
```

### Dependency Injection
```swift
// Example Container
class DependencyContainer {
    let imageService: ImageGenerationServiceProtocol
    let subscriptionService: SubscriptionServiceProtocol
    let storageService: StorageServiceProtocol
    
    static let shared = DependencyContainer()
}
```

## Error Handling

### Domain-Specific Errors
```swift
enum ImageGenerationError: Error {
    case invalidInput
    case processingFailed
    case apiError(OpenAIError)
    case quotaExceeded
    case subscriptionRequired
}
```

## Testing Architecture

### Test Hierarchy
```
Tests/
├── Unit/
│   ├── ViewModels/
│   ├── Services/
│   └── Utilities/
└── UI/
    ├── Flows/
    └── Components/
```

## Performance Considerations

### Memory Management
- Image downsampling before processing
- Cache size limits
- Background task handling
- Resource cleanup

### Network Optimization
- Request debouncing
- Response caching
- Retry strategies
- Connection monitoring 