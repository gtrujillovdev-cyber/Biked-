# Technical Documentation: Biked

This document details the internal architecture, data flow, and development processes of the **Biked** application.

## 🏗 Architecture (MVVM)

The app follows a strict **Model-View-ViewModel** architecture to ensure separation of concerns and testability.

### 1. Model (`Biked/Models/`)
- **Bike.swift**: Defines the `Bike` and `Geometry` structs. It handles the mapping from the JSON data source using the `Codable` protocol.
- **Geometry**: Stores specific stack, reach, and angle values for various frame sizes.

### 2. View (`Biked/Views/`)
- **SearchView**: The main entry point for the user. It features a collapsible search form that hides once results are found to maximize screen space.
- **ExploreView**: A visual gallery of all available brands and models.
- **BikeDetailView**: A comprehensive view showing the bike's image, description, official link, and a detailed geometry table.
- **MainTabView**: Manages navigation between Search, Explore, and Favorites.

### 3. ViewModel (`Biked/ViewModels/`)
- **SearchViewModel**: Orchestrates the search logic. It filters the bike list based on brand and calculates the "best fit" size by comparing user measurements with the geometry data.

---

## 🔄 Data Flow

1. **Initialization**: On app launch, `bikes.json` is decoded into an array of `Bike` objects.
2. **User Interaction**: The user enters their height/reach in `SearchView`.
3. **Processing**: `SearchViewModel` filters the database and identifies matching bikes.
4. **Display**: The UI reacts to state changes in the ViewModel, updating the result cards and highlighting recommended sizes in the detail tables.

---

## 🤖 Image Automation (`Biked/Data/download_images.py`)

To maintain a high-quality visual library without manual effort, we developed a specialized Python automation tool.

### Features:
- **Multi-Source Scraping**: Uses Bing Images and DuckDuckGo as primary search engines to avoid IP rate-limiting.
- **Transparency Detection**: Prioritizes PNG and WebP formats to find "cut-out" images that look premium in the UI.
- **Intelligent Fallback**: If search engines fail, the script scrapes OpenGraph metadata (`og:image`) directly from the `official_url` provided in the JSON.
- **Manual Overrides**: Includes a dictionary for direct URL access to stubborn models (e.g., Canyon Aeroad, Pinarello Dogma).

---

## 🛠 Asset Management

Images are stored in `Biked/Resources/BikeImages/`.  
**Note for Developers**: In Xcode, this directory must be added as a **Folder Reference** (blue folder) rather than a group to ensure dynamic path resolution works correctly within the app using the `resolveImageURL` helper.

---

## 📝 Future Roadmap

- **API Integration**: Transition from a local JSON to a cloud-based BaaS (like Supabase or Firebase).
- **Pro Team Filters**: Search bikes used by specific WorldTour teams.
- **3D Viewer**: Integrate USDZ models for a 360-degree view of selected bikes.
