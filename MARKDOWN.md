Claude 3.7 Swift/SwiftUI Project Build Prompt:

You are an expert Swift and SwiftUI developer tasked with creating a premium iOS application named Shock-Style Content Generator. This app enables users to capture or select photos and transform them into ultra-realistic, viral images using OpenAI's 4o Image Generation API. The user interface must be exceptionally modern, sleek, and intuitive, adhering to Apple's Human Interface Guidelines and supporting Light Mode, Dark Mode, and System Appearance settings. The app should be simple and focused, ensuring users can effortlessly generate and download images.​

Project Requirements:
Technical Stack & Environment:
Swift / SwiftUI (latest stable version)

Xcode project configured with Swift Package Manager (SPM)

OpenAI's 4o Image Generation API integration with secure placeholders for API keys

Secure Storage for user data and API keys

.gitignore configured to exclude sensitive information

Core Features:
Image Capture & Selection:

Allow users to capture a photo using the device's camera or select an existing image from the photo library.​

Image Generation:

Integrate OpenAI's 4o Image Generation API to transform the user's photo into a high-quality, stylized image.​

Ensure API keys are securely stored using environment variables or a secure storage mechanism.​

Image Download:

Provide a straightforward option for users to download the generated image directly to their device.​

User Interface & Experience:
Simplicity: Design a clean, uncluttered interface focusing on the core functionality of capturing/selecting images, generating new images, and downloading them.​

Visual Appeal: Implement a modern, high-end design with smooth animations and transitions to enhance user engagement.​

Theme Support: Ensure the UI adapts seamlessly to Light Mode, Dark Mode, and System Appearance settings.​

Development Guidelines:
Code Architecture: Follow the MVVM (Model-View-ViewModel) pattern for maintainability and scalability.​

Error Handling: Implement robust error handling, especially for API interactions and image processing.​

Testing: Conduct thorough testing to ensure the app functions flawlessly across different devices and iOS versions.​

Security & Best Practices:
API Key Management: Store API keys securely using environment variables or a secure storage mechanism.​

Data Privacy: Ensure that user data, including photos, are handled securely and not stored or transmitted without consent.​

.gitignore Configuration: Properly configure .gitignore to exclude sensitive information and API keys.​

Monetization Strategy:
Initial Free Use: Allow users to generate and download one image for free to experience the app's core functionality.​

Paywall Implementation: After the initial free use, implement a hard paywall requiring users to subscribe or make a one-time purchase to continue using the image generation feature.​

Subscription Management: Utilize RevenueCat SDK or a similar service to manage subscriptions and in-app purchases.​

Git & Version Control:
Repository Setup: Initialize a Git repository with a clear structure for easy collaboration.​

Initial Commit: Push an initial commit labeled "Initial Setup: Swift/SwiftUI Project with OpenAI 4o Image Generation Integration."​

Instructions for Claude 3.7:

Please generate fully functional Swift/SwiftUI code that adheres to the above requirements. Ensure that the code is well-documented with inline comments explaining key components and decisions. After generating the code, initiate a build-and-run process in Xcode to identify and fix any compilation or runtime errors, ensuring the app functions as intended. Provide clear instructions for integrating the OpenAI 4o Image Generation API, including where to insert the API keys securely.​

By following this prompt, Claude 3.7 should generate a robust, sleek, and fully tested Swift/SwiftUI application that meets your specifications for the Shock-Style Content Generator App.