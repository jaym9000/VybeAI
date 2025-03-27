# Shock-Style Content Generator

A premium iOS application that transforms ordinary photos into viral-style, AI-generated images using OpenAI's 4o Image Generation API.

## Features

- **Image Capture & Selection**: Capture photos with your device camera or select images from your photo library
- **AI Image Generation**: Transform your photos into stunning, viral-style images with OpenAI's 4o model
- **Easy Saving & Sharing**: Download and share your generated images directly from the app
- **Sleek, Intuitive UI**: Modern interface with smooth animations and adherence to Apple's Human Interface Guidelines
- **Theme Support**: Full compatibility with Light Mode, Dark Mode, and System Appearance settings

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- Active OpenAI API key with access to the 4o Image Generation model

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/shock-style.git
cd shock-style
```

2. Open the Xcode project:
```bash
open VybeAI.xcodeproj
```

3. Create a secure file to store your OpenAI API key (not included in source control):
```swift
// VybeAI/Core/Services/APIKeys.swift
// VybeAI - Shock-Style Content Generator
//
// Created by YourName on CurrentDate.
//

import Foundation

enum APIKeys {
    static let openAI = "your_openai_api_key_here"
}
```

4. Build and run the project in Xcode.

## Setting Up OpenAI API

To use this app, you need an API key from OpenAI with access to the 4o Image Generation model:

1. Sign up for an OpenAI account at [https://openai.com](https://openai.com)
2. Create an API key in your account settings
3. Add your API key to the `APIKeys.swift` file as shown in the installation instructions
4. (Optional) For production use, implement a more secure method of API key storage

## Subscription Integration with RevenueCat

The app is configured to work with RevenueCat for subscription management:

1. Sign up for a RevenueCat account at [https://revenuecat.com](https://revenuecat.com)
2. Create products for subscriptions (monthly, yearly, lifetime)
3. Add your RevenueCat public SDK key to your project
4. Uncomment the relevant RevenueCat code in `SubscriptionManager.swift`

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern with these components:

- **Models**: Data structures and business logic
- **Views**: SwiftUI user interface components
- **ViewModels**: State management and business logic connection
- **Services**: API integration and system services

## Project Structure

```
ShockStyle/
├── App/
│   └── MainView.swift
├── Features/
│   ├── Onboarding/
│   ├── ImageCapture/
│   ├── ImageGeneration/
│   ├── Subscription/
│   └── Settings/
├── Core/
│   ├── Models/
│   ├── Services/
│   └── Utilities/
├── UI/
│   ├── Components/
│   ├── Styles/
│   └── Resources/
```

## Security Considerations

- API keys are stored securely and not committed to source control
- User data, including photos, is handled with privacy in mind
- Images are processed locally when possible
- For production use, consider implementing certificate pinning for API communication

## License

[Include your license information here]

## Credits

- OpenAI for the 4o Image Generation API
- RevenueCat for subscription management
- [Any other credits you want to include] 