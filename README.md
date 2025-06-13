# 📔 Journal Memory Editor - CE.SDK iOS Demo

A SwiftUI journaling app demonstrating IMG.LY's CE.SDK integration for persistent image editing.

## 🎯 Project Overview

This demo app showcases how CE.SDK can power a journaling application where users can:
- Pick images from their photo library
- Edit them with professional tools (crop, filters, text, stickers)
- Save both the final image and editable scene data
- Re-open and continue editing saved memories

Built for IMG.LY's Solutions Engineer interview assignment.

## ✨ Features

### Core CE.SDK Integration
- **Photo Selection**: Native iOS PhotosPicker integration
- **Professional Editing**: CE.SDK PhotoEditor with filters, text, and stickers
- **Square Cropping**: Automatic 1080x1080 format for social media
- **Scene Persistence**: Save/load editable scenes for continued editing
- **Asset Management**: Proper asset source configuration for all editing tools

### Journal App Features
- **Memory Gallery**: Grid layout showing saved edited images
- **Tap to Re-edit**: Seamless continuation of editing sessions
- **Local Storage**: Images and scenes saved to device storage
- **Clean UI**: SwiftUI-based interface optimized for the editing workflow

## 📱 Screenshots

### Main Journal Interface
![Main Interface](CESDKDemo/Images/01-main-interface.png)
*Clean, focused interface with "Add New Memory" button*

### CE.SDK Photo Editor
![Photo Editor](Images/02-photo-editor.png)
*Professional editing tools with filters, text, and stickers*

### Memory Gallery
![Memory Gallery](Images/03-memory-gallery.png)
*Grid layout showing saved memories with tap-to-edit*

### Re-editing Experience
![Re-editing](Images/04-re-editing.png)
*Seamless continuation of editing sessions*

## 🏗️ Architecture

### Data Flow
1. **Image Selection** → PhotosPicker loads image to temp storage
2. **Scene Creation** → CE.SDK creates editable scene from image
3. **Editing Session** → User applies filters, text, stickers
4. **Dual Save** → App saves both final image + scene data
5. **Gallery Display** → AsyncImage loads saved memories
6. **Re-editing** → Scene data restores exact editing state

### Key Components
- **ContentView**: Main journal interface and CE.SDK integration
- **JournalEntry**: Data model for saved memories
- **JournalEntryView**: Reusable card component for gallery
- **Scene Management**: Save/load functionality for persistent editing

## 🔧 Technical Implementation

### CE.SDK Configuration
```swift
// Engine setup with proper asset sources
try await engine.addDefaultAssetSources(baseURL: Engine.assetBaseURL)
try await engine.addDemoAssetSources(sceneMode: engine.scene.getMode(), withUploadAssetSources: true)
try await engine.asset.addSource(TextAssetSource(engine: engine))
