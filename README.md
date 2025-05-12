# LiDAR Scanner App

A Flutter application that leverages iOS LiDAR technology to create 3D scans of rooms and environments.

## Technical Overview

### Architecture

The LiDAR Scanner app follows a feature-first architecture with clear separation of concerns:

- **Platform Integration**: Native Swift code for iOS LiDAR functionality with Flutter Method Channel integration
- **State Management**: Flutter BLoC pattern using Cubit for reactive UI updates
- **Dependency Injection**: Get_it and Injectable for service locator pattern
- **Modular Design**: Split into feature modules (scanner, model_viewer, saved_scans)

### iOS Native Implementation

The iOS implementation uses ARKit for LiDAR scanning with a modular architecture:

- **ScannerView.swift**: Main class managing ARKit session and Flutter platform integration
- **ScannerConfiguration.swift**: Configuration settings for different scan qualities
- **MeshProcessor.swift**: Processing and visualization of 3D mesh data
- **ModelExporter.swift**: Exporting scanned models to OBJ format
- **ARExtensions.swift**: Helper extensions for ARKit functionality

### Flutter Implementation

The Flutter side uses BLoC pattern with Cubit for state management:

- **scanner_cubit.dart**: Manages scanning state and communicates with native code
- **scanner_service.dart**: Service layer for platform channel communication
- **scanner_view.dart**: UI for scanning controls and visualization

## Features

- **Room Scanning**: High-quality 3D scanning of rooms and environments
- **Quality Settings**: Configurable scan quality (high/low) with appropriate parameters
- **Real-time Feedback**: Visual feedback during scanning process
- **Model Export**: Export scanned models in OBJ format
- **Progress Tracking**: Track scanning progress and identify missing areas

## Technical Requirements

- **iOS**: iPhone/iPad with LiDAR sensor (iPhone 12 Pro/Pro Max or newer, iPad Pro 2020 or newer)
- **iOS Version**: iOS 13.4 or later
- **Flutter**: Flutter 3.2.3 or later

## Implementation Details

### Native Swift Components

#### ScannerView
- Manages ARKit session and scene view
- Delegates to specialized components for configuration, mesh processing, and export
- Implements ARSessionDelegate and ARSCNViewDelegate for AR updates

#### ScannerConfiguration
- Configures ARKit session based on scan quality
- Sets up lighting, scene reconstruction, and environment texturing
- Handles room scan mode configuration

#### MeshProcessor
- Processes ARMeshAnchor objects from ARKit
- Creates and updates SCNNode objects for visualization
- Applies quality settings to mesh processing

#### ModelExporter
- Exports scanned 3D models to OBJ format
- Handles file saving and path management

### Flutter Components

#### ScannerCubit
- Manages application state for scanning process
- Communicates with native code via ScannerService
- Provides reactive state updates to UI

#### ScannerService
- Handles method channel communication with native code
- Provides typed API for scanner operations
- Handles error cases and data conversion

#### ScannerView
- Provides UI for scanning controls
- Displays native ARKit view via platform view
- Shows scanning progress and export options

## Usage

1. Launch the app and grant necessary permissions
2. Position device to scan the room
3. Select scan quality (high/low) using the quality toggle
4. Start scanning by tapping the play button
5. Move the device around to capture the entire room
6. Stop scanning when complete
7. Export the model by tapping the save button and entering a filename

## Recent Changes

- Simplified the application by removing objectScan feature to focus solely on roomScan
- Modularized the ScannerView.swift into specialized components for better maintainability
- Fixed string literal usage in Swift code (using double quotes instead of single quotes)
- Resolved extension conflicts by moving helper extensions to ARExtensions.swift
- Updated visibility modifiers for better component interaction

## Development Notes

- ARKit scene reconstruction requires LiDAR sensor
- Scanning quality significantly impacts performance and detail level
- Export process may take time for high-quality scans
- Real-time mesh processing is computationally intensive
