// ImageEntry.swift
// VybeAI
//
// Created by JM Mahoro on 2025-03-28.
//

import SwiftUI

// Model for storing generated image entries in history
struct ImageEntry: Identifiable, Equatable {
    let id: UUID
    let image: UIImage?
    let prompt: String
    let date: Date
    let sourceImage: UIImage?
    
    init(id: UUID = UUID(), image: UIImage?, prompt: String, date: Date = Date(), sourceImage: UIImage? = nil) {
        self.id = id
        self.image = image
        self.prompt = prompt
        self.date = date
        self.sourceImage = sourceImage
    }
    
    // Equatable implementation
    static func == (lhs: ImageEntry, rhs: ImageEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// ImageHistoryManager for persisting and retrieving image history
class ImageHistoryManager {
    private let userDefaults = UserDefaults.standard
    private let historyKey = "imageHistory"
    private let maxEntries = 50
    
    private struct ImageHistoryData: Codable {
        let id: String
        let prompt: String
        let date: Date
        let imageFilename: String
        let sourceImageFilename: String?
    }
    
    func saveImageToHistory(_ entry: ImageEntry) async {
        // Load current history data
        var historyData = loadHistoryData()
        
        // Generate filenames
        let imageFilename = "\(entry.id.uuidString)_image.jpg"
        let sourceImageFilename = entry.sourceImage != nil ? "\(entry.id.uuidString)_source.jpg" : nil
        
        // Save images to disk
        if let image = entry.image {
            await saveImageToDisk(image, filename: imageFilename)
        }
        
        if let sourceImage = entry.sourceImage {
            await saveImageToDisk(sourceImage, filename: sourceImageFilename!)
        }
        
        // Create entry data
        let entryData = ImageHistoryData(
            id: entry.id.uuidString,
            prompt: entry.prompt,
            date: entry.date,
            imageFilename: imageFilename,
            sourceImageFilename: sourceImageFilename
        )
        
        // Add to history and maintain max entries limit
        historyData.insert(entryData, at: 0)
        if historyData.count > maxEntries {
            // Remove and delete old entries beyond the limit
            let removedEntries = historyData.suffix(from: maxEntries)
            historyData = Array(historyData.prefix(maxEntries))
            
            // Delete files for removed entries
            for removedEntry in removedEntries {
                await deleteImageFromDisk(filename: removedEntry.imageFilename)
                if let sourceFilename = removedEntry.sourceImageFilename {
                    await deleteImageFromDisk(filename: sourceFilename)
                }
            }
        }
        
        // Save updated history data
        saveHistoryData(historyData)
    }
    
    func removeImageFromHistory(_ entry: ImageEntry) async {
        var historyData = loadHistoryData()
        
        // Find the entry to remove
        historyData = historyData.filter { $0.id != entry.id.uuidString }
        
        // Delete image files
        let imageFilename = "\(entry.id.uuidString)_image.jpg"
        await deleteImageFromDisk(filename: imageFilename)
        
        if entry.sourceImage != nil {
            let sourceImageFilename = "\(entry.id.uuidString)_source.jpg"
            await deleteImageFromDisk(filename: sourceImageFilename)
        }
        
        // Save updated history data
        saveHistoryData(historyData)
    }
    
    func getImageEntries() async -> [ImageEntry] {
        let historyData = loadHistoryData()
        var entries: [ImageEntry] = []
        
        for data in historyData {
            let image = await loadImageFromDisk(filename: data.imageFilename)
            var sourceImage: UIImage? = nil
            
            if let sourceFilename = data.sourceImageFilename {
                sourceImage = await loadImageFromDisk(filename: sourceFilename)
            }
            
            if let uuid = UUID(uuidString: data.id) {
                let entry = ImageEntry(
                    id: uuid,
                    image: image,
                    prompt: data.prompt,
                    date: data.date,
                    sourceImage: sourceImage
                )
                entries.append(entry)
            }
        }
        
        return entries
    }
    
    func clearHistory() async {
        let historyData = loadHistoryData()
        
        // Delete all image files
        for data in historyData {
            await deleteImageFromDisk(filename: data.imageFilename)
            if let sourceFilename = data.sourceImageFilename {
                await deleteImageFromDisk(filename: sourceFilename)
            }
        }
        
        // Clear history data
        saveHistoryData([])
    }
    
    // MARK: - Private Helper Methods
    
    private func loadHistoryData() -> [ImageHistoryData] {
        guard let data = userDefaults.data(forKey: historyKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let historyData = try decoder.decode([ImageHistoryData].self, from: data)
            return historyData
        } catch {
            print("Error loading history data: \(error)")
            return []
        }
    }
    
    private func saveHistoryData(_ data: [ImageHistoryData]) {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(data)
            userDefaults.set(encodedData, forKey: historyKey)
        } catch {
            print("Error saving history data: \(error)")
        }
    }
    
    private func saveImageToDisk(_ image: UIImage, filename: String) async {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: fileURL)
            } catch {
                print("Error saving image to disk: \(error)")
            }
        }
    }
    
    private func loadImageFromDisk(filename: String) async -> UIImage? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image from disk: \(error)")
            return nil
        }
    }
    
    private func deleteImageFromDisk(filename: String) async {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Error deleting image from disk: \(error)")
        }
    }
} 