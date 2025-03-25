import Foundation

/// Handles loading and parsing data from files
class DataLoader {
    /// Shared instance for singleton access
    static let shared = DataLoader()
    
    /// Load data from a CSV file
    /// - Parameter fileName: Name of the CSV file without extension
    /// - Returns: String contents of the file, or nil if the file couldn't be loaded
    func loadCSV(fileName: String) -> String? {
        // First try to load from the app bundle
        if let path = Bundle.main.path(forResource: fileName, ofType: "csv") {
            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                print("Successfully loaded \(fileName).csv from bundle")
                return content
            } catch {
                print("Failed to load \(fileName).csv from bundle: \(error)")
            }
        } else {
            print("Could not find path for \(fileName).csv in bundle")
            // Debug: List all resources in bundle
            if fileName == "default" {
                let resources = Bundle.main.paths(forResourcesOfType: "csv", inDirectory: nil)
                print("CSV files in bundle: \(resources)")
                
                let allResources = Bundle.main.paths(forResourcesOfType: nil, inDirectory: nil)
                print("All resources in bundle (first 10): \(Array(allResources.prefix(10)))")
            }
        }
        
        // Fallback to Documents directory
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent("\(fileName).csv")
        
        do {
            let content = try String(contentsOf: destinationUrl, encoding: .utf8)
            print("Successfully loaded \(fileName).csv from Documents directory")
            return content
        } catch {
            print("Failed to load \(fileName).csv from Documents directory: \(error)")
            
            // If it's the default file, provide basic empty structure and save it
            if fileName == "default" {
                let defaultContent = "latitude,longitude,name,date_visited\n34.0522,-118.2437,Los Angeles,2023-01-01\n"
                
                // Try to save the default content to Documents directory
                do {
                    try defaultContent.write(to: destinationUrl, atomically: true, encoding: .utf8)
                    print("Created new default.csv in Documents directory")
                    return defaultContent
                } catch {
                    print("Failed to create default.csv in Documents directory: \(error)")
                }
                
                return defaultContent
            }
            
            return nil
        }
    }
    
    /// Parse CSV data into an array of dictionaries
    /// - Parameter data: CSV string data
    /// - Returns: Array of dictionaries with column headers as keys
    func parseCSV(data: String) -> [[String: String]] {
        var result: [[String: String]] = []
        
        let rows = data.components(separatedBy: "\n")
        guard !rows.isEmpty else { return [] }
        
        // Get headers from first row
        let headers = rows[0].components(separatedBy: ",")
        guard !headers.isEmpty else { return [] }
        
        // Process data rows
        for i in 1..<rows.count {
            let row = rows[i]
            if row.isEmpty { continue }
            
            let columns = row.components(separatedBy: ",")
            var rowDict: [String: String] = [:]
            
            for (index, header) in headers.enumerated() {
                if index < columns.count {
                    // Convert value to string explicitly
                    let value = columns[index]
                    // Ensure we're working with a string, not any other type
                    rowDict[header] = value.isEmpty ? "" : "\(value)"
                }
            }
            
            if !rowDict.isEmpty {
                result.append(rowDict)
            }
        }
        
        return result
    }
} 